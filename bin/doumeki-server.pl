#!/usr/bin/env perl
use strict;
use warnings;
use FindBin::libs;
use FindBin::libs qw( base=extlib );
use Doumeki::CLI::Server;

Doumeki::CLI::Server->new_with_options->run();

__END__

=head1 NAME

doumeki-server - Doumeki web server

=head1 SYNOPSIS

  doumeki-server.pl --host=HOST --port=PORT [--configfile CONFIG.yaml] [--debug]

  --host HOST
  -h HOST
    specifies the host address it binds to (e.g. 127.0.0.1). Default to any address.

  --port PORT
  -p PORT
    specifies the port number it listens to. Default: 10808

  --configfile CONFIG.yaml
  -c CONFIG.yaml
    specifies configuration file. see also "example/config.yaml".

  --debug
  -d
    set log level to debug.

=head1 EXAMPLE

  env DOUMEKI_ACCESS_LOG=/var/log/doumeki/doumeki.acc \
      doumeki-server --configfile /path/to/config.yaml --debug

=head1 ENVIRONMENTAL VARIABLES

=over 4

=item DOUMEKI_DEBUG

set log level to debug if this variable defined. same as --debug option.

=item DOUMEKI_ACCESS_LOG

specifies filename of access log.
output to STDOUT if you don't specified this variable.

=item DOUMEKI_ERROR_LOG

specifies filename of error log.
output to STDOUT if you don't specified this variable.

=back

=head1 AUTHOR

HIROSE Masaaki E<lt>hirose31 _at_ gmail.comE<gt>

=head1 REPOSITORY

L<http://github.com/hirose31/doumeki/tree/master>

  git clone git://github.com/hirose31/doumeki.git

patches and collaborators are welcome.

=cut

