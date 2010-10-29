package Doumeki::Store::Null;
use Any::Moose;

with qw(Doumeki::Store::Base);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub login {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

sub new_album {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

1;
__END__

=head1 NAME

Doumeki::Store::Null - no store

=head1 SYNOPSIS

  store:
    Null:

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<Doumeki>

=cut
