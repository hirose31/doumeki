package Doumeki::CLI::Server;
use Any::Moose;
use Any::Moose 'X::Types::Path::Class' => [qw(File Dir)];

with any_moose('X::Getopt'),
     any_moose('X::ConfigFromFile');

use Pod::Usage;
use YAML::XS;

use Doumeki::Log;
use Doumeki::Server;

has '+configfile' => (
    default => "config.yaml",
    cmd_aliases => 'f',
);

has 'receiver' => (
    is          => 'rw',
    isa         => 'HashRef',
);

has 'store' => (
    is          => 'rw',
    isa         => 'HashRef',
);

has 'engine' => (
    is          => 'rw',
    isa         => 'HashRef',
);

has 'host' => (
    traits      => [ 'Getopt' ],
    cmd_aliases => 'h',
    is          => 'rw',
    isa         => 'Str',
    default     => "0.0.0.0",
);

has 'port' => (
    traits      => [ 'Getopt' ],
    cmd_aliases => 'p',
    is          => 'rw',
    isa         => 'Int',
    default     => 10808,
    required    => 1,
);

has 'debug' => (
    traits      => [ 'Getopt' ],
    cmd_aliases => 'd',
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
);

has 'help' => (
    traits      => [ 'Getopt' ],
#    cmd_aliases => 'h',
    is          => 'rw',
    isa         => 'Bool',
    default     => 0
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub get_config_from_file {
    my ($class, $file) = @_;

    if (-f $file) {
        my $conf = YAML::XS::LoadFile($file);
        $conf = { %{ delete $conf->{server} }, %{ $conf } } if exists $conf->{server};
        return $conf;
    } else {
        Doumeki::Log->log(warning => "no such file: $file") if $file;
        return {};
    }
}

sub run {
    my $self = shift;
    if ($self->help) {
        pod2usage(
            -input => (caller(0))[1],
            -exitval => 1,
           );
    }

    Doumeki::Server->bootstrap({
        host     => $self->host,
        port     => $self->port,
        debug    => $self->debug,
        engine   => $self->engine,
        store    => $self->store,
        receiver => $self->receiver,
    });
}

1;

