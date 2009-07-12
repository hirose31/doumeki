package Doumeki::Server;
use Any::Moose;


use HTTP::Engine;
use HTTP::Engine::Middleware;
use FindBin;
use Time::HiRes qw(tv_interval gettimeofday);
use Data::Dumper;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deparse  = 1;

use Doumeki::Log;
use Doumeki::Receiver;

has 'conf'  => (
    is => 'rw',
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub bootstrap {
    my($class, $conf) = @_;

    my $self = $class->new(conf => $conf);

    my $exit = sub { CORE::die('caught signal') };
    eval {
        local $SIG{INT}  = $exit if !$ENV{DOUMEKI_DEBUG};
        local $SIG{QUIT} = $exit;
        local $SIG{TERM} = $exit;
        $self->run;
    };
    Doumeki::Log->log(error => "Exiting feed... $@");
}

sub BUILD {
    my $self = shift;

    my $conf = $self->conf;
    local $ENV{DOUMEKI_ACCESS_LOG} =
        $ENV{DOUMEKI_ACCESS_LOG} || $conf->{access_log} || "";
    local $ENV{DOUMEKI_ERROR_LOG} =
        $ENV{DOUMEKI_ERROR_LOG}  || $conf->{error_log}  || "";
    local $ENV{DOUMEKI_DEBUG} =
        $ENV{DOUMEKI_DEBUG}      || $conf->{debug}      || "";

    Doumeki::Log->init();

    return $self;
}

sub run {
    my $self = shift;

    Doumeki::Log->log(debug => "Initializing with HTTP::Engine version $HTTP::Engine::VERSION");

    my $mw = HTTP::Engine::Middleware->new({
        method_class => 'HTTP::Engine::Request',
    });

    $mw->install(
        'HTTP::Engine::Middleware::HTTPSession' => {
            store => {
                class => 'File',
                args  => {
                    dir => $FindBin::Bin.'/sess/',
                },
            },
            state => {
                class => 'Cookie',
                args  => {
                    name    => 'GALLERYSID',
                    expires => '+1h',
                },
            },
        },
       );

    $mw->install(
        'HTTP::Engine::Middleware::UploadTemp' => {
            keepalive => 0,
            cleanup   => 1,
            tmpdir    => 1,
            base_dir  => exists $self->conf->{engine}{tmp_dir}
                           ? $self->conf->{engine}{tmp_dir}
                           : '/var/tmp/doumeki',
            template  => 'up_XXXXXX',
            lazy      => 1,
        });

    my $receiver = Doumeki::Receiver->new('GR2', %{$self->conf->{receiver}{GR2}});

    Doumeki::Log->log(debug => "build_engine, self->conf: ".Dumper($self->conf));

    for my $type (qw(notify store)) {
        my $Type = ucfirst $type;

        for my $klass (keys %{ $self->conf->{$type} }) {
            my $module = "Doumeki::${Type}::${klass}";
            $module->require;
            my $type = $module->new(%{$self->conf->{$type}{$klass}});
            for my $hook (qw(login add_item new_album)) {
                $receiver->add_trigger(
                    name      => $hook,
                    callback  => sub {
                        my $t0 = [gettimeofday];
                        my $r = $type->$hook(@_);
                        Doumeki::Log->log(notice => sprintf "[%-9s] ${Type}::%-10s ... %8.6f [sec]", $hook, $klass, tv_interval($t0));
                        return $r;
                    },
                    abortable => 1,
                   );
            }
        }
    }

    my $engine= HTTP::Engine->new(
        interface => {
            module => 'ServerSimple',
            args   => $self->conf,
            request_handler => $mw->handler( sub {$receiver->handle_request(@_) } ),
        },
    );
    $engine->run;
}

1;

