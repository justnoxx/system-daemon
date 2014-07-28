#!/usr/bin/env perl
use strict;
use warnings;

use System::Daemon;

my $d = System::Daemon->new(
    user    =>  'noxx',
    group   =>  'staff',
    pidfile =>  '/Users/noxx/git/system-daemon/eg/daemon.pid',
    name_pattern =>  'perl',
);

$d->daemonize();

sleep 5;

$d->exit(0);

1;
