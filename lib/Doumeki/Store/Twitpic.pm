package Doumeki::Store::Twitpic;
use Any::Moose;

use Carp;
use LWP::UserAgent;
use HTTP::Request::Common;

with qw(Doumeki::Store::Base);

has username => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has password => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'ua' => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    builder => '_build_ua',
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_ua {
    my ($self) = @_;
    LWP::UserAgent->new;
}

sub login {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    # implement me if you need
    my $res = $self->ua->request(
        POST 'http://twitpic.com/api/uploadAndPost',
        Content_Type => 'multipart/form-data',
        Content => [
            username => $self->username,
            password => $self->password,
            media => [ $tempname ],
            message => '#eyefi',
        ]
    );
    if ($res->is_success) {
        my ($url) = ($res->content =~ m{<mediaurl>(.+)</mediaurl>});
        Doumeki::Log->log(info => 'uploaded: '.$url);
    } else {
        Doumeki::Log->log(error => $res->content);
    }
    return 1;
}

sub new_album {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    # implement me if you need
    return 1;
}

1;
__END__

=head1 NAME

Doumeki::Store::Skeleton - skeleton class for your new Store

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