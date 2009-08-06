package Doumeki::Store::Email;
use Any::Moose;

use Carp;
use Email::MIME;
use Email::MIME::Creator;
use Email::Send;
use Path::Class;

with qw(Doumeki::Store::Base);

has 'mail_from' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'mail_to' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    default  => sub {[]},
   );

has 'mail_bcc' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
    default  => sub {[]},
   );

has 'filename_in' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'body',
    required => 1,
   );

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub login {
    my($self) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    my $albumname;
    ($albumname, $filename) = split m{/}, $filename, 2 if $filename =~ m{/};

    my $mail = Email::MIME->create(
        header => [
            From    => $self->mail_from,
            To      => join(', ', @{ $self->mail_to  }),
            Bcc     => join(', ', @{ $self->mail_bcc }),
            Subject => lc($self->filename_in) eq "subject" ? $filename : "",
           ],
        parts => [
            lc($self->filename_in) eq "body"
                ? Email::MIME->create(
                    body => $filename,
                   )
                : (),
            Email::MIME->create(
                attributes => {
                    filename     => $filename,
                    content_type => "image/jpeg",
                    disposition  => "attachment",
                    encoding     => "base64",
                },
                body => scalar file($tempname)->slurp,
               ),
           ],
       );
    my $sender = Email::Send->new({mailer => 'Sendmail'});
    $sender->send($mail);

    return 1;
}

sub new_album {
    my($self) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

1;
__END__

=head1 NAME

Doumeki::Store::Email - upload photos into some where by email

=head1 SYNOPSIS

  store:
    Email:
      mail_from: hirose31@example.com
      mail_to:
        - XXXXXXXX@f.hatena.ne.jp
      mail_bcc:
        - upload-SECRETKEY@example.org
        - upload-SECRETKEY@example.net
      filename_in: body

=head1 ATTRIBUTES

=over 4

=item mail_from: Str

From address of uploader email. required.

=item mail_to: ArrayRef[Str]

To addresses of uploader email.

=item mail_bcc: ArrayRef[Str]

Bcc addresses of uploader email.

=item filename_in: Str

Where write filename in. "body" or "subject". default is "body".

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<Doumeki>

=cut
