package Doumeki::Store::S3;
use Any::Moose;
use Net::Amazon::S3;
use Carp;

with qw(Doumeki::Store::Base);

has 'aws_access_key' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'aws_secret' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'bucket' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'acl' => (
    is => 'rw',
    isa => 'Str',
    default => 'private',
);

has 'prefix' => (
    is => 'rw',
    isa => 'Str',
);

has 's3' => (
    is => 'ro',
    isa => 'Net::Amazon::S3',
    lazy => 1,
    builder => '_build_s3',
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _build_s3 {
    my $self = shift;
    Net::Amazon::S3->new({
        aws_access_key_id => $self->aws_access_key,
        aws_secret_access_key => $self->aws_secret,
    });
}

sub login {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    # implement me if you need
    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    my $s3 = $self->s3;
    my $bucket = $s3->bucket( $self->bucket );
    if ( my $prefix = $self->prefix ) {
        $filename = join '/', $prefix, $filename;
    }
    $bucket->add_key_filename( $filename, $tempname, {
        acl_short => $self->acl,
    } ) or carp $s3->errstr;
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

Doumeki::Store::S3 - uplaod into Amason S3

=head1 SYNOPSIS

  store:
    S3:
      aws_access_key: foo
      aws_secret: bar
      bucket: your-photo
      acl: private

=head1 ATTRIBUTES

=over 4

=item aws_access_key: Str

AWS access key

=item aws_secret: Str

AWS secret

=item bucket: Str

S3 bucket name

=item prefix 

prefix of S3 key-name.

=item acl

shorthand notation of ACL. 
private, public-read, public-read-write, authenticated-read

=back

=head1 AUTHOR

Tomohiro Ikebe E<lt>ikebe _at_ shebang.jpE<gt>

=head1 SEE ALSO

L<Doumeki>

=cut
