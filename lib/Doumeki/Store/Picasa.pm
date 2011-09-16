package Doumeki::Store::Picasa;
use Any::Moose;

use Carp;

use LWP::UserAgent;
use XML::LibXML;

with qw(Doumeki::Store::Base);

has 'email' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'password' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

# http://code.google.com/intl/en/apis/accounts/docs/AuthForInstalledApps.html
has 'clientlogin_uri' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'https://www.google.com/accounts/ClientLogin',
    required => 1,
   );

has 'auth_token' => (
    is       => 'rw',
    isa      => 'HashRef[Str]',
    default  => sub { +{} },
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
    my($slef) = @_;
    # fixme
    # my $client = Atompub::Client->new;
    # return $client;
    return {};
}


sub login {
    my($self) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    my $res = $self->ua->post($self->clientlogin_uri,
                     {
                         Email       => $self->email,
                         Passwd      => $self->password,
                         accountType => 'GOOGLE',
                         source      => 'Google-Picasa-Upload',
                         service     => 'lh2',
                     }
                    );
    if ($res->code ne '200') {
        Doumeki::Log->log(error => 'failed to ClientLogin for ' . $self->email);
        return;
    }

    for (split /[\n\r]+/, $res->content) {
        my($k,$v) = split /=/, $_, 2;
        $self->auth_token->{lc($k)} = $v;
    }

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
        $upload_uri = 'http://picasaweb.google.com/data/feed/api/user/default';
    }
    Doumeki::Log->log(debug => "upload_uri: $upload_uri");

    open my $img_fh, '<', $tempname or die "$!: $tempname";
    binmode $img_fh;
    my $img_data = do { local $/; <$img_fh> };
    close $img_fh;

    my $res = $self->ua->post($upload_uri,
                              'GData-Version' => '2',
                              'Content-Type'  => 'image/jpg',
                              'Slug'          => $filename,
                              'Authorization' => "googlelogin auth=".$self->auth_token->{'auth'},
                              'Content'       => $img_data,
                             );

    $res->code eq '200' or carp "$!: ".$res->code.' '.$res->content;

    return 1;
}

sub new_album {
    my($self, $receiver, $albumname) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    my $upload_uri = $self->album_list->{$albumname} || "";
    Doumeki::Log->log(debug => "upload_uri in cache: $upload_uri");

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
                 'Authorization' => "googlelogin auth=".$self->auth_token->{'auth'},
                 'Content'       => sprintf($request_body,
                                            $albumname,
                                            $self->album_access,
                                           ),
                );

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

Doumeki::Store::Picasa - skeleton class for your new Store

=head1 SYNOPSIS

  store:
    Local:
      foo: blah

=head1 ATTRIBUTES

=over 4

=item foo: Str

...

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<Doumeki>

=cut
