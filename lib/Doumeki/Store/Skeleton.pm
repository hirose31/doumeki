package Doumeki::Store::Skeleton;
use Any::Moose;

use Carp;

with qw(Doumeki::Store::Base);

has 'foo' => (
    is       => 'rw',
    isa      => 'Str',
    default  => 'blah',
   );

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub login {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    # implement me if you need
    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    # implement me if you need
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
