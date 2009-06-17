package Doumeki::Store::Local;
use Any::Moose;

use Carp;
use File::Copy;
use Path::Class ();

with qw(Doumeki::Store::Base);

has 'base_dir' => (
    is      => 'rw',
    isa     => 'Path::Class::Dir',
    default => '/var/tmp',
    coerce  => 1,
   );

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub login {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

sub add_item {
    my($self, $receiver, $tempname, $filename) = @_;
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);

    my $tempfile = Path::Class::File->new($tempname);
    my $newfile  = $self->base_dir->file($filename);
    $newfile->dir->mkpath;
    Doumeki::Log->log(info => "newfile: ".$newfile);

    File::Copy::copy($tempname, $newfile) or carp $!;
}

sub new_album {
    Doumeki::Log->log(debug => '>>'.(caller(0))[3]);
    return 1;
}

1;
__END__

=head1 NAME

Doumeki::Store::Local - save photos into local disk.

=head1 SYNOPSIS

  store:
    Local:
      base_dir: /storage/photos

=head1 ATTRIBUTES

=over 4

=item base_dir: Str

base directory for saving photo data.
actually saved into: "base_dir/YYYY-MM-DD/XXXXX.JPG".

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<Doumeki>

=cut
