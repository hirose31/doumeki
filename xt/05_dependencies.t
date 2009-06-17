# -*- mode: cperl; -*-
use Test::Dependencies
    exclude => [qw(Test::Dependencies Test::Base Test::Perl::Critic
                   Doumeki
                   MooseX::AttributeHelpers
                 )],
    style   => 'heavy';
ok_dependencies();
