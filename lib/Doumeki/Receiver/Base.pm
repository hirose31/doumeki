package Doumeki::Receiver::Base;
use Any::Moose qw(::Role);
use Any::Moose 'X::AttributeHelpers';
use Class::Trigger;

requires qw(handle_request login add_item new_album);

has 'stores' => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef[Doumeki::Store::Base]',
    default   => sub { [] },
    provides  => {
        'push' => 'add_store',
       },
   );

1;
