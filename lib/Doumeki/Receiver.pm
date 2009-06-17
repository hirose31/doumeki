package Doumeki::Receiver;
use Any::Moose;
use UNIVERSAL::require;

sub new {
    my($class, $impl, @args) = @_;

    my $module = "Doumeki::Receiver::$impl";
    $module->require or die $@;

    return $module->new(@args);
}

1;
