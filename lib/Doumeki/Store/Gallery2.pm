package Doumeki::Store::Gallery2;
use Any::Moose;

use Carp;
use Gallery::Remote;

with qw(Doumeki::Store::Base);

has 'url' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

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

has 'ignore_upload_photo_fail' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    required => 1,
   );

has 'gr2' => (
    is       => 'ro',
    isa      => 'Gallery::Remote2::Tiny',
    lazy     => 1,
    builder  => '_build_gr2',
   );


__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_gr2 {
    my($self) = @_;
    my $gr2 = Gallery::Remote2::Tiny->new(
        url      => $self->url,
        username => $self->username,
        password => $self->password,
        ignore_upload_photo_fail => $self->ignore_upload_photo_fail,
       );
    return $gr2;
}

sub login {
    my($self) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    $self->gr2->login or carp "failed to login Gallery2: $!";

    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    $self->gr2->add_item(
        album    => "",
        filepath => $tempname,
        filename => $filename,
        caption  => "",
       ) or carp "failed to upload image to Gallery2: $!";

    return 1;
}

sub new_album {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

package Gallery::Remote2::Tiny;

use strict;
use warnings;
use Carp;

use LWP::UserAgent;
use HTTP::Request::Common;
$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deparse = 1;
sub p(@) {
    print STDERR Dumper(\@_);
}

our $VERSION = '0.01_01';

my $PROTOCOL_VERSION = 2.13;

my $GR_STAT_SUCCESS            = 0;
my $PROTO_MAJ_VER_INVAL        = 101;
my $PROTO_MIN_VER_INVAL        = 102;
my $PROTO_VER_FMT_INVAL        = 103;
my $PROTO_VER_MISSING          = 104;
my $PASSWD_WRONG               = 201;
my $LOGIN_MISSING              = 202;
my $UNKNOWN_CMD                = 301;
my $NO_ADD_PERMISSION          = 401;
my $NO_FILENAME                = 402;
my $UPLOAD_PHOTO_FAIL          = 403;
my $NO_WRITE_PERMISSION        = 404;
my $NO_VIEW_PERMISSION         = 405;
my $NO_CREATE_ALBUM_PERMISSION = 501;
my $CREATE_ALBUM_FAILED        = 502;
my $MOVE_ALBUM_FAILED          = 503;
my $ROTATE_IMAGE_FAILED        = 504;

sub new {
    my($class, %arg) = @_;

    my %prop;
    for (qw(url username password ignore_upload_photo_fail)) {
        $prop{$_} = delete $arg{$_} || "";
    }
    # add "/main.php" to tail of URL
    if ($prop{url} !~ /main\.php$/) {
        $prop{url} =~ s/\/$//;
        $prop{url} .= "/main.php";
    }

    my $self = bless {
        %prop,
        _ua    => LWP::UserAgent->new,
        _login => undef,
       }, $class;

    $self->{_ua}->agent(__PACKAGE__.'/'.$VERSION);
    $self->{_ua}->cookie_jar({});


    return $self;
}

sub login {
    my($self) = @_;

    $self->{_login} = 0;
    my $res = $self->{_ua}->request(
        POST $self->{url},
        Content_Type => 'form-data',
        Content => [
            'g2_controller'             => 'remote:GalleryRemote',
            'g2_form[protocol_version]' => $PROTOCOL_VERSION,
            'g2_form[cmd]'              => "login",
            'g2_form[uname]'            => $self->{username},
            'g2_form[password]'         => $self->{password},
           ],
       );

    my($code, $gr2_res) = $self->_parse_response($res);

    if ($code != 200) {
        return 0;
    } else {
        if ($gr2_res->{status} == $GR_STAT_SUCCESS) {
            $self->{_login} = 1;
            return 1;
        } else {
            return 0;
        }
    }
}

sub fetch_albums       { croak 'still not implemented: ',(caller(0))[3]; }
sub fetch_albums_prune { croak 'still not implemented: ',(caller(0))[3]; }

sub add_item {
    my($self, %arg) = @_;

    if (! defined $self->{_login}) {
        $self->login or return 0;
    }

    for (qw(filepath album)) {
        if (! exists $arg{$_}) {
            carp "missing arg: $_";
            return 0;
        }
    }
    if (! exists $arg{filename}) {
        $arg{filename} = substr($arg{filepath},rindex($arg{filepath},"/")+1);
    }

    my $res = $self->{_ua}->request(
        POST $self->{url},
        Content_Type => 'form-data',
        Content => [
            'g2_controller'             => 'remote:GalleryRemote',
            'g2_form[protocol_version]' => $PROTOCOL_VERSION,
            'g2_form[cmd]'              => "add-item",
            'g2_form[set_albumName]'    => $arg{album},
            'g2_form[caption]'          => $arg{caption} || "",
            'g2_userfile'               => [ $arg{filepath} ],
            'g2_userfile_name'          => $arg{filename},
            'g2_authToken'              => "",
           ],
       );

    my($code, $gr2_res) = $self->_parse_response($res);

    if ($code != 200) {
        carp $gr2_res->{error};
        return 0;
    } else {
        if ($gr2_res->{status} == $GR_STAT_SUCCESS) {
            return 1;
        } elsif ($gr2_res->{status} == $UPLOAD_PHOTO_FAIL
                && $self->{ignore_upload_photo_fail}) {
            warn "ignore UPLOAD_PHOTO_FAIL";
            return 1;
        } else {
            carp Dumper($gr2_res); # fixme
            return 0;
        }
    }

}

sub album_properties     { croak 'still not implemented: ',(caller(0))[3]; }
sub new_album            { croak 'still not implemented: ',(caller(0))[3]; }
sub fetch_album_images   { croak 'still not implemented: ',(caller(0))[3]; }
sub move_album           { croak 'still not implemented: ',(caller(0))[3]; }
sub increment_view_count { croak 'still not implemented: ',(caller(0))[3]; }
sub image_properties     { croak 'still not implemented: ',(caller(0))[3]; }
sub no_op                { croak 'still not implemented: ',(caller(0))[3]; }

sub _parse_response {
    my($self, $res) = @_;
    my($code, $gr2_res);

    $code = $res->code;
    if ($res->is_error) {
        $gr2_res->{error} = $res->error_as_HTML;
    } else {
        my $content = $res->content;
        $content =~ s/^.*#__GR2PROTO__[\r\n]+//s;
        for (split /[\r\n]+/, $content) {
            my($k,$v) = split /=/, $_, 2;
            $gr2_res->{$k} = $v;
        }
    }

    return ($code, $gr2_res);
}

1;
__END__

=head1 NAME

Doumeki::Store::Gallery2 - upload by Gallery Remote 2 protocol

=head1 SYNOPSIS

  store:
    Gallery2:
      url:      http://example.com/gr2/main.php
      username: scott
      password: tiger
      ignore_upload_photo_fail: 1

=head1 ATTRIBUTES

=over 4

=item url: Str

=item username: Str

=item password: Str

=item ignore_upload_photo_fail: Bool

ignore UPLOAD_PHOTO_FAIL response.

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<Doumeki>

L<Gallery::Remote>

L<http://codex.gallery2.org/Gallery_Remote:Protocol>

=cut
