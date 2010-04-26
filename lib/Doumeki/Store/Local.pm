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

has 'prefix_shootdate' => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
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
    if ($self->prefix_shootdate) {
        eval "require Image::ExifTool";
        if ($@) {
            Doumeki::Log->log(error => "failed to require Image::ExifTool: $@");
        } else {
            my $exif = Image::ExifTool->new;
            my $info = $exif->ImageInfo($tempname);
            if (exists $info->{DateTimeOriginal} && $info->{DateTimeOriginal}) {
                my $prefix = join('', split(/[:\/-]/, (split(/\s+/, $info->{DateTimeOriginal}))[0]));
                if ($prefix) {
                    $newfile = $newfile->parent->file($prefix."_".$newfile->basename);
                }
            }
        }
    }

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
      prefix_shootdate: 1

=head1 ATTRIBUTES

=over 4

=item base_dir: Str

base directory for saving photo data.
actually saved into: "base_dir/YYYY-MM-DD/XXXXX.JPG".

=item prefix_shootdate: Bool

prefix shoot date (YYYYMMDD_) to the filename.

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 SEE ALSO

L<Doumeki>

=cut
