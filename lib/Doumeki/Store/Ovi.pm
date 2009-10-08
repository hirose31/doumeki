package Doumeki::Store::Ovi;
use Any::Moose;

use Carp;

use XML::Atom;
use XML::Atom::Service;
use Atompub::Client;
use Atompub::Util;

with qw(Doumeki::Store::Base);

has 'username' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'password' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'service_uri' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'http://share.ovi.com/api/atom/1.0/',
    required => 1,
   );

has 'collection_uri' => (
    is       => 'rw',
    isa      => 'Str',
   );

has 'client' => (
    is       => 'ro',
    isa      => 'Atompub::Client',
    lazy     => 1,
    builder  => '_build_client',
   );

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_client {
    my($slef) = @_;
    my $client = Atompub::Client->new;
    return $client;
}

sub login {
    my($self) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    # ad-hoc hack: Ovi provides old style AtomPP.
    $XML::Atom::DefaultVersion = '0.3';
    $XML::Atom::Service::DefaultNamespace = 'http://purl.org/atom/app#';

    $self->client->username($self->username);
    $self->client->password($self->password);

    my $service;
    {
        # Ovi returns Content-Type, which is not "application/atomsvc+xml" but old style "application/atomserv+xml". so ignore warning.
        local $SIG{__WARN__} = sub {
            return if $_[0] =~ /^Bad Content-Type:/;
            Doumeki::Log->log(warn => $_) for @_;
        };
        $service = $self->client->getService($self->service_uri) or croak $!;
    };

    my @workspaces  = $service->workspaces or croak $!;

    # http://share.ovi.com/api/atom/1.0/USERNAME.mymedia
    my @collections = $workspaces[0]->collections or croak $!;

    $self->collection_uri($collections[0]->href);

    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    my $albumname = "";
    ($albumname, $filename) = split m{/}, $filename, 2 if $filename =~ m{/};

    # ad-hoc hack: Ovi provides old style AtomPP.
    local *Atompub::Client::is_acceptable_media_type_orig = \&Atompub::Client::is_acceptable_media_type;
    local *Atompub::Client::is_acceptable_media_type = sub {
        my($coll, $content_type) = @_;
        if ($content_type =~ m{^image/}) {
            return 1;
        }
        Atompub::Client::is_acceptable_media_type_orig($coll, $content_type);
    };

    $self->client->createMedia($self->collection_uri,
                               $tempname,
                               'image/jpeg',
                               $filename,
                              ) or croak $self->client->errstr;

    return 1;
}

sub new_album {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

1;
__END__

=head1 NAME

Doumeki::Store::Ovi - upload into Ovi

=head1 SYNOPSIS

  store:
    Ovi:
      username: XXXXXXXX
      password: XXXXXXXX

=head1 ATTRIBUTES

=over 4

=item username: Str

Your username.

=item password: Str

Your password.

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<Doumeki>

L<http://share.ovi.com/>

=cut
