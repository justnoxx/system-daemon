package System::Daemon;

use strict;
use warnings;

use POSIX;
use Carp;

use System::Daemon::Utils;

our $VERSION = 0.02;
our $AUTHOR = 'justnoxx';
our $ABSTRACT = "Swiss-knife for daemonization";

our $DEBUG = 0;

sub new {
    my ($class, %params) = @_;

    my $self = {};

    if ($params{user}) {
        $self->{daemon_data}->{user} = $params{user};
    }

    if ($params{group}) {
        $self->{daemon_data}->{group} = $params{group};
    }

    if ($params{pidfile}) {
        $self->{daemon_data}->{pidfile} = $params{pidfile};
    }

    if ($params{name_pattern}) {
        $self->{daemon_data}->{name_pattern} = $params{name_pattern};
    }
    $self->{daemon_data}->{rdy} = 1;
    bless $self, $class;
    return $self;
}

sub daemonize {
    my $self = shift;

    croak "Not ready" unless $self->{daemon_data}->{rdy};

    my $dd = $self->{daemon_data};

    my $process_object = System::Daemon::Utils::process_object();

    if ($dd->{user} || $dd->{group}) {
        System::Daemon::Utils::apply_rights(
            user    =>  $dd->{user},
            group   =>  $dd->{group}
        );
    }

    # wrapper context
    System::Daemon::Utils::daemon();

    # daemon context
    if ($dd->{pidfile}) {
        croak "Can't overwrite pid file of my alive instance" unless $self->ok_pid();
        System::Daemon::Utils::write_pid($dd->{pidfile});
    }

    return 1;
}


sub exit {
    my ($self, $code) = @_;

    $self->finish();

    $code ||= 0;
    exit $code;
}


sub ok_pid {
    my ($self, $pidfile) = @_;

    $pidfile ||= $self->{daemon_data}->{pidfile};

    # нет pid как параметра, а значит, что проверка
    # смысла не имеет

    return 1 unless $pidfile;

    unless (System::Daemon::Utils::pid_init($self->{daemon_data}->{pidfile})) {
        croak "Can't init pidfile";
    }

    my $pid;
    unless ($pid = System::Daemon::Utils::read_pid($pidfile)) {
        return 1;
    }

    if (System::Daemon::Utils::is_alive($pid, $self->{daemon_data}->{name_pattern})) {
        return 0;
    }

    return 1;
}


sub cleanup {
    my ($self) = @_;

    return $self->finish();
}


sub finish {
    my ($self) = @_;

    my $dd = $self->{daemon_data};

    if ($dd->{pidfile}) {
        System::Daemon::Utils::delete_pidfile($dd->{pidfile});
    }
}

sub process_object {
    my ($self) = @_;

    return System::Daemon::Utils::process_object();
}
1;

__END__