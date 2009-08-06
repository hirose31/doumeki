use inc::Module::Install;

name     'Doumeki';
license  'perl';
all_from 'lib/Doumeki.pm';

requires 'Any::Moose', 0.05;
requires 'HTTP::Engine', 0.1.8;
requires 'HTTP::Engine::Middleware', 0.14;
requires 'Class::Trigger';
requires 'FindBin::libs';
requires 'Log::Dispatch';
requires 'Log::Dispatch::File';
requires 'Log::Dispatch::Screen::Color';
requires 'Path::Class';
requires 'Readonly';
requires 'UNIVERSAL::require';
requires 'YAML::XS';
requires 'Time::HiRes';

requires 'Flickr::Upload';

requires 'Email::MIME';
requires 'Email::MIME::Creator';
requires 'Email::Send';

requires 'Net::Amazon::S3';

requires 'WWW::SmugMug::API';

requires_any_moose 'X::AttributeHelpers';

tests 't/*.t';
author_tests('xt');

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
