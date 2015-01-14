use inc::Module::Install;

name     'Doumeki';
license  'perl';
all_from 'lib/Doumeki.pm';

requires 'Any::Moose', '0.05';
requires 'HTTP::Engine', '0.02001';
requires 'HTTP::Engine::Middleware', '0.14';
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
requires 'Image::ExifTool';

feature 'Store::Flickr',
    -default => 0,
    'Flickr::Upload';

feature 'Store::Email',
    -default => 0,
    'Email::MIME',
    'Email::MIME::Creator',
    'Email::Send';

feature 'Store::S3',
    -default => 0,
    'Net::Amazon::S3';

feature 'Store::SmugMug',
    -default => 0,
    'WWW::SmugMug::API';

feature 'Notify::XMPP',
    -default => 0,
    'XML::Stream', '1.23',
    'Net::DNS',
    'Net::XMPP';

requires_any_moose 'X::AttributeHelpers';

tests 't/*.t';
author_tests('xt');

build_requires 'Test::More';
use_test_base;
auto_include;
auto_install;
WriteAll;
