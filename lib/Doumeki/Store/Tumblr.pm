package Doumeki::Store::Tumblr;
use Any::Moose;
use Carp;
use WWW::Mechanize;
use Web::Scraper;
use HTTP::Request::Common ();

with 'Doumeki::Store::Base';

has email => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has password => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has channel_id => (
    is => 'ro',
    isa => 'Str',
);

has ua => (
    is => 'ro',
    isa => 'WWW::Mechanize',
    required => 1,
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;

sub _build_ua {
    my $self = shift;
    my $mech = WWW::Mechanize->new;
    $mech->post(
        'http://www.tumblr.com/login',
        {
            email => $self->email,
            password => $self->password,
        }
    );
    if ($mech->uri ne 'http://www.tumblr.com/dashboard') {
        carp 'login failed';
    }
    return $mech;
}

sub login {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

sub add_item {
    my ($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    my $mech = $self->ua;
    $mech->get('http://www.tumblr.com/new/photo');
    $mech->form_id('edit_post');
    $mech->select('channel_id' => $self->channel_id) if $self->channel_id;
    $mech->current_form->find_input('images[o1]')->file($tempname);
    $mech->click_button(number => 1);
    if (
        my $error = scraper {
            process '#errors', 'error', 'TEXT';
            result 'error';
        }->scrape(\($mech->response->decoded_content))
    ) {
        Doumeki::Log->log(error => $error);
    }
    1;
}

sub new_album {1}

1;
