package Doumeki::Receiver::Base;
use Any::Moose qw(::Role);
use Any::Moose 'X::AttributeHelpers';
use Class::Trigger;

requires qw(handle_request login add_item new_album);

1;
