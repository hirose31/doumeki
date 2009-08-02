package Doumeki::Store::SmugMug;
use Any::Moose;
use WWW::SmugMug::API;
use Carp;
use Data::Dumper;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deparse  = 1;

with qw(Doumeki::Store::Base);

has 'api_key' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'secure' => (
    is       => 'rw',
    isa      => 'Int',
    default => 0,
);

has 'email' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'password' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'album' => (
    is => 'rw',
    isa => 'Str',
);

has 'keywords' => (
    is => 'rw',
    isa      => 'ArrayRef[Str]',
    default  => sub { [] },
);

has 'api' => (
    is => 'ro',
    isa => 'WWW::SmugMug::API',
    lazy => 1,
    builder => '_build_api',
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_api {
    my $self = shift;
    WWW::SmugMug::API->new({
        sm_api_key => $self->api_key,
        secure => $self->secure,
        agent => ref($self),
    });
}

sub login {
    my $self = shift;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    my $res = $self->api->login_withPassword({
        EmailAddress => $self->email,
        Password => $self->password,
    });
    Doumeki::Log->log(debug => "WWW::SmugMug::API::login_withPassword ".Dumper($res));
    $res->{stat} eq 'ok';
}

sub get_album_id {
    my( $self, $title ) = @_;
    my $res = $self->api->albums_get;
    if ( $res->{stat} eq 'ok' ) {
        my @albums = @{$res->{Albums}};
        for my $album(@albums) {
            if ($album->{Title} eq $title) {
                return $album->{id};
            }
        }
    }
    my $res2 = $self->api->albums_create({
        Title => $title,
        CategoryID => 'DEFAULT', # XXX
    });
    if ($res2->{stat} eq 'ok') {
        return $res2->{Album}->{id};
    }
    return 0;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    my $album = $self->album ? $self->album : (split(/\//, $filename, 2))[0];
    my $album_id = $self->get_album_id( $album );
    Doumeki::Log->log(debug => "SmugMug AlbumID: ". $album. '/'. $album_id);
    open my $fh, $tempname or croak "$!: $tempname";
    my $data = join '', <$fh>;
    close $fh;

    my $res = $self->api->images_upload({
        FileName => $filename,
        ImageData => $data,
        AlbumID => $album_id,
    });
    Doumeki::Log->log(debug => "WWW::SmugMug::API::image_upload ".Dumper($res));
    $res->{stat} eq 'ok';
}

sub new_album {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    # implement me if you need
    return 1;
}

1;
__END__

=head1 NAME

Doumeki::Store::SmugMug - upload into SmugMug

=head1 SYNOPSIS

  store:
    SmugMug:
      api_key: foo
      email: foo@example.com
      password: foo
      album: EyeFi
      secure: 1

=head1 ATTRIBUTES

=over 4

=item api_key

SmugMug API Key. see http://www.smugmug.com/hack/apikeys

=item email

SmugMug login email addres.

=item password

SmugMug login password

=item secure

use secure connection (SSL) or not.

=item album

SmugMug album-name which your photos are uploaded.
if omit this attribute, Eye-Fi card settings will be used.

=back

=head1 AUTHOR

Tomohiro Ikebe E<lt>ikebe _at_ shebang.jpE<gt>

=head1 SEE ALSO

L<Doumeki>

=cut
