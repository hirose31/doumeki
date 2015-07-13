package Doumeki::Store::Picasa;
use Any::Moose;

use Carp;

use LWP::UserAgent;
use XML::LibXML;
use Net::Google::DataAPI::Auth::OAuth2;

with qw(Doumeki::Store::Base);

has 'client_id' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'client_secret' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'refresh_token' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'access_token' => (
    is       => 'rw',
    isa      => 'Str',
    default  => '',
   );

has 'ua' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    builder => '_build_ua',
);

# all, private, public, visible, protected
# http://code.google.com/intl/ja/apis/picasaweb/docs/2.0/reference.html#Visibility
has 'album_access' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'protected',
    required => 1,
   );

has 'album_list' => (
    is       => 'rw',
    isa      => 'HashRef[Str]',
    lazy     => 1,
    builder  => '_build_album_list',
   );

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_ua {
    my($self) = @_;
    return LWP::UserAgent->new;
}

sub _build_album_list {
    my($self) = @_;

    my $album_list = {};

    my $res = $self->ua->get('https://picasaweb.google.com/data/feed/api/user/default',
                             'Authorization' => "OAuth ".$self->access_token
                    );
    $res->code eq '200' or croak "failed to get album list: $!: ".$res->code.' '.$res->content;

    my $dom = XML::LibXML->load_xml(string => $res->content);
    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs('atom','http://www.w3.org/2005/Atom');

    my $nodes = $xpc->findnodes('//atom:entry');
    Doumeki::Log->log(debug => "nodes: ".$nodes->size);
    for my $node ($nodes->get_nodelist) {
        my $title_node = $node->getElementsByTagName('title')->get_node(1);
        my $albumname = $title_node->textContent;
        utf8::encode($albumname);
        Doumeki::Log->log(debug => "album name: $albumname");

        my @links = $node->getElementsByTagName('link')->get_nodelist;
        for my $link (@links) {
            if ($link->getAttribute('rel') eq 'http://schemas.google.com/g/2005#feed') {
                Doumeki::Log->log(debug => "found: " . $link->getAttribute('href'));
                $album_list->{ $albumname } = $link->getAttribute('href');
                last;
            }
        }
    }

    return $album_list;
}


sub login {
    my($self) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    my $oauth2 = Net::Google::DataAPI::Auth::OAuth2->new(
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        scope         => ['https://picasaweb.google.com/data/', 'https://www.googleapis.com/auth/drive'],
    );
    my $ow = $oauth2->oauth2_webserver;
    my $token = Net::OAuth2::AccessToken->new(
        profile       => $ow,
        auto_refresh  => 1,
        refresh_token => $self->refresh_token,
    );
    $ow->update_access_token($token);
    $token->refresh;
    $oauth2->access_token($token);
    $self->access_token($token->access_token);

    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    my $albumname = "";
    ($albumname, $filename) = split m{/}, $filename, 2 if $filename =~ m{/};

    my $upload_uri;
    if ($albumname) {
        $upload_uri = $self->new_album(undef, $albumname);
        Doumeki::Log->log(warn => "failed to get album URL for $albumname") unless $upload_uri;
    }
    if (! $upload_uri) {
        $upload_uri = 'https://picasaweb.google.com/data/feed/api/user/default';
    }
    Doumeki::Log->log(debug => "upload_uri: $upload_uri");

    open my $img_fh, '<', $tempname or croak "$!: $tempname";
    binmode $img_fh;
    my $img_data = do { local $/; <$img_fh> };
    close $img_fh;

    my $res = $self->ua->post($upload_uri,
                              'GData-Version' => '2',
                              'Content-Type'  => 'image/jpg',
                              'Slug'          => $filename,
                              'Authorization' => "OAuth ".$self->access_token,
                              'Content'       => $img_data,
                             );

    $res->code eq '201' or croak "failed to upload photo: $!: ".$res->code.' '.$res->content;

    return 1;
}

sub new_album {
    my($self, $receiver, $albumname) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    my $upload_uri = $self->album_list->{$albumname} || "";
    Doumeki::Log->log(debug => "upload_uri for $albumname: $upload_uri");

    if (! $upload_uri) {
        my $request_body = q{<entry xmlns='http://www.w3.org/2005/Atom'
    xmlns:media='http://search.yahoo.com/mrss/'
    xmlns:gphoto='http://schemas.google.com/photos/2007'>
  <title type='text'>%s</title>
  <gphoto:access>%s</gphoto:access>
  <category scheme='http://schemas.google.com/g/2005#kind'
    term='http://schemas.google.com/photos/2007#album'></category>
</entry>
};
        my $uri = 'https://picasaweb.google.com/data/feed/api/user/default';
        my $res = $self->ua->post($uri,
                 'Content-Type'  => 'application/atom+xml',
                 'Authorization' => "OAuth ".$self->access_token,
                 'Content'       => sprintf($request_body,
                                            $albumname,
                                            $self->album_access,
                                           ),
                );
        $res->code eq '201' or croak "failed to create album: $!: ".$res->code.' '.$res->content;

        my $dom = XML::LibXML->load_xml(string => $res->content);
        my @links = $dom->getElementsByTagName('link');
        for my $link (@links) {
            if ($link->getAttribute('rel') eq 'http://schemas.google.com/g/2005#feed') {
                $upload_uri = $link->getAttribute('href');
                last;
            }
        }

        if ($upload_uri) {
            $self->album_list->{$albumname} = $upload_uri;
        }
    }

    return $upload_uri;
}

1;
__END__

=head1 NAME

Doumeki::Store::Picasa - upload into Picasa

=head1 SYNOPSIS

  store:
    Picasa:
      client_id: XXXXXXXX.apps.googleusercontent.com
      client_secret: XXXXXXXX
      refresh_token: XXXXXXXX

=head1 ATTRIBUTES

=over 4

=item client_id: Str



=item client_secret: Str



=item refresh_token: Str



=item access_token: Str



=item album_access: Str

One of: all, private, public, visible, protected

default is "protected" (only you can see photo).

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<Doumeki>

L<http://code.google.com/intl/en/apis/picasaweb/docs/2.0/developers_guide_protocol.html>

L<http://code.google.com/intl/en/apis/picasaweb/docs/2.0/reference.html>

=cut
