package Doumeki::Store::Flickr;
use Any::Moose;

use Carp;
use Flickr::Upload;

with qw(Doumeki::Store::Base);

has 'key' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'secret' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'auth_token' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'tags' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    default  => sub { [] },
   );

has 'is_public' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
   );

has 'is_friend' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
   );

has 'is_family' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
   );

has 'ua' => (
    is      => 'ro',
    isa     => 'Flickr::Upload',
    lazy    => 1,
    builder => '_build_ua',
   );

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_ua {
    my($self) = @_;
    my $ua = Flickr::Upload->new({
        key    => $self->key,
        secret => $self->secret
       });
    return $ua;
}


sub login {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    $self->ua->upload(
        photo      => $tempname,
        auth_token => $self->auth_token,
        tags       => join(' ', @{$self->tags}),
        is_public  => $self->is_public,
        is_friend  => $self->is_friend,
        is_family  => $self->is_family,
       ) or carp "failed to upload image to flickr: $!";

    return 1;
}

sub new_album {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

1;
__END__

=head1 NAME

Doumeki::Store::Flickr - upload into Flickr

=head1 SYNOPSIS

  store:
    Flickr:
      key:        XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      secret:     XXXXXXXXXXXXXXXX
      auth_token: XXXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXX
      tags:
        - doumeki
        - eye-fi
      is_public: 0
      is_friend: 0
      is_family: 1

=head1 ATTRIBUTES

=over 4

=item key: Str

=item secret: Str

Your API key and secret.
see L<http://www.flickr.com/services/api/keys/>

=item auth_token: Str

Your authentication token.

You can get token by flickr_upload command.
L<http://search.cpan.org/dist/Flickr-Upload/flickr_upload#EXAMPLES>

=item tags: ArrayRef[Str]

automatically add these tags to photo.

=item is_public: Bool

=item is_friend: Bool

=item is_family: Bool

access permission. default is all off (= only you can see photo).

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<Doumeki>

L<http://www.flickr.com/services/api/keys/>

L<http://shokai.org/blog/archives/1060>

=cut

