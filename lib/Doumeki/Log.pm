package Doumeki::Log;
use strict;
use warnings;
use Log::Dispatch;
use Log::Dispatch::File;
use Log::Dispatch::Screen::Color;

my($logger, $access_logger);

my %alias = (warn => 'warning');

sub init {
    $Log::Dispatch::Screen::Color::DEFAULT_COLOR->{debug} = { text => 'red'  };
    $Log::Dispatch::Screen::Color::DEFAULT_COLOR->{info}  = { text => 'cyan' };

    unless ($logger) {
        $logger = Log::Dispatch->new;
        if ($ENV{DOUMEKI_ERROR_LOG}) {
            $logger->add( Log::Dispatch::File->new(
                name => 'error_log',
                min_level => $ENV{DOUMEKI_DEBUG} ? 'debug' : 'notice',
                filename  => $ENV{DOUMEKI_ERROR_LOG} . "",
                mode => 'append',
            ));
        } else {
            $logger->add( Log::Dispatch::Screen::Color->new(
                name => 'error_log',
                min_level => $ENV{DOUMEKI_DEBUG} ? 'debug' : 'notice',
            ));
        }

        $access_logger = Log::Dispatch->new;
        if ($ENV{DOUMEKI_ACCESS_LOG}) {
            $access_logger->add( Log::Dispatch::File->new(
                name => 'access_log',
                min_level => 'info',
                filename  => $ENV{DOUMEKI_ACCESS_LOG} . "",
                mode => 'append',
            ));
        } else {
            $access_logger->add( Log::Dispatch::Screen::Color->new(
                name => 'access_log',
                min_level => 'info',
            ));
        }
    }
}

sub log {
    my($class, $level, @msg) = @_;

    my $msg = join(" ", @msg);
    chomp $msg;

    if ($logger) {
        $logger->log( level => $alias{$level} || $level, message => "$msg\n" );
    } else {
        Carp::carp($msg);
    }
}

sub log_request {
    my($class, $req, $res) = @_;

    $access_logger->log(
        level => 'info',
        message => sprintf qq(%s - %s [%s] "%s %s cmd=%s %s" %s %s "%s" "%s"\n),
            $req->address, ($req->user || '-'), scalar localtime, $req->method,
            $req->uri->path_query,
            $req->param("g2_form[cmd]") || "-",
            $req->protocol, $res->status, ($res->body ? bytes::length($res->body) : "-"),
            ($req->referer || '-'), ($req->user_agent || '-'),
    );
}

for my $level ( qw(debug info notice warn warning error critical alert emergency) ) {
    no strict 'refs';
    *$level = sub {
        my $class = shift;
        $class->log( $level => @_ );
    };
}

1;
