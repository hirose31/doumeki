package Doumeki::Notify::XMPP;
use Any::Moose;

use Carp;
use Net::XMPP;

with qw(Doumeki::Notify::Base);

has 'jid' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'password' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
   );

has 'to' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    default  => sub { [] },
   );

has 'server_host' => (
    is       => 'ro',
    isa      => 'Str',
    builder  => '_build_server_host',
    lazy     => 1,
    required => 1,
   );

has 'server_port' => (
    is       => 'ro',
    isa      => 'Int',
    default  => 5222,
    required => 1,
   );

has 'tls' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
   );

has 'connected' => (
    is       => 'rw',
    isa      => 'Bool',
    default  => 0,
   );

has 'client' => (
    is       => 'ro',
    isa      => 'Net::XMPP::Client',
    builder  => '_build_client',
    lazy     => 1,
   );

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_server_host {
    my($self) = @_;
    return (split /@/, $self->jid)[1]; # = $componentname
}

sub _build_client {
    my($self) = @_;
    return Net::XMPP::Client->new(debuglevel=>0);
}

sub login {
    my($self) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    $self->_initialize;

    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    my $messge = sprintf "[Doumeki] uploaded: %s", $filename;

    $self->_notify($messge);
    $self->_finalize;

    return 1;
}

sub new_album {
    my($self) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    # implement me if you need
    return 1;
}

# borrow from Plagger::Plugin::Notify::XMPP::Direct
sub _initialize {
    my($self) = @_;

    my $connectattempts = 3;
    my $connectsleep    = 1;

    my $jid = $self->jid || do {
        Doumeki::Log->log(error => "missing: jid");
        return;
    };
    unless (index($jid, '@') >= 1) {
        Doumeki::Log->log(error => "missing: jid");
        return;
    }
    my ($username, $componentname) = split /@/, $jid;
    my $password    = $self->password || do {
        Doumeki::Log->log(error => "missing: password");
        return;
    };

    my $hostname = $self->server_host;
    my $port     = $self->server_port;
    my $tls      = $self->tls || 0;
    unless ($self->to) {
        Doumeki::Log->log(warning => "missing: to");
        return;
    }

    Doumeki::Log->log(debug => "hostname=$hostname port=$port tls=$tls componentname=$componentname");

    my ($status, $error);
    while (--$connectattempts >= 0) {
        $status = $self->client->Connect(
            hostname      => $hostname,
            port          => $port,
            tls           => $tls,
            componentname => $componentname,
           );
        last if defined $status;
        Doumeki::Log->log(warning => "retry[$connectattempts]");
        sleep $connectsleep;
    }
    unless (defined $status) {
        Doumeki::Log->log(error => "connection failure");
        return;
    }

    if ($XML::Stream::VERSION <= 1.22) {
        # quick hack to connect Google Talk
        # override XML::Stream-1.22
        no warnings 'redefine';
        *XML::Stream::SASLClient = sub {
            my $self = shift;
            my $sid = shift;
            my $username = shift;
            my $password = shift;

            my $mechanisms = $self->GetStreamFeature($sid,"xmpp-sasl");

            return unless defined($mechanisms);

            my $sasl = new Authen::SASL(mechanism=>join(" ",@{$mechanisms}),
                                        callback=>{
                                            authname => $username."@".($self->{SIDS}->{$sid}->{to} or $self->{SIDS}->{$sid}->{hostname}),
                                            user     => $username,
                                            pass     => $password
                                           }
                                       );

            $self->{SIDS}->{$sid}->{sasl}->{client} = $sasl->client_new();
            $self->{SIDS}->{$sid}->{sasl}->{username} = $username;
            $self->{SIDS}->{$sid}->{sasl}->{password} = $password;
            $self->{SIDS}->{$sid}->{sasl}->{authed} = 0;
            $self->{SIDS}->{$sid}->{sasl}->{done} = 0;

            $self->SASLAuth($sid);
        };
    }

    ($status,$error) = $self->client->AuthSend(
        username => $username,
        password => $password,
        resource => 'Plagger',
       );
    unless ($status and $status eq 'ok') {
        Doumeki::Log->log(error => "authentication failure");
        return;
    }

    $self->connected(1);
}

sub _notify {
    my($self, $body) = @_;
    return unless $self->connected;
    Doumeki::Log->log(debug => ">>notify");

    foreach my $a_to (@{$self->to}) {
        Doumeki::Log->log(notice => "Notifying to $a_to");
        $self->client->MessageSend(
            to   => $a_to,
            body => $body,
           );
    }
}

sub _finalize {
    my($self) = @_;
    return unless $self->connected;
    Doumeki::Log->log(debug => ">>finalize");
    $self->client->Disconnect();
}

1;
__END__

=head1 NAME

Doumeki::Notify::XMPP - notify by XMPP (jabber, Google Talk)

=head1 SYNOPSIS

jabber.org

  notify:
    XMPP:
      jid: your_notifier@jabber.org
      password: XXXXXXXX
      to:
        - your_account@gmail.com
        - your_account2@jabber.org

Google Talk

  notify:
    XMPP:
      jid: your_notifier@gmail.com
      password: XXXXXXXX
      server_host: talk.google.com
      tls: 1
      to:
        - your_account@gmail.com
        - your_account2@jabber.org

=head1 ATTRIBUTES

=over 4

=item jid: Str (required)

=item password: Str (required)

=item server_host: Str

default: domain part of jid.

=item server_port: Int

defalt: 5222

=item tls: Bool

default: 0

=item to: ArrayRef[Str] (required)

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<Doumeki>

=cut
