package System::Daemon;

use strict;
use warnings;

use POSIX;
use Carp;
use Fcntl ':flock';
use System::Daemon::Utils;

our $VERSION = 0.13;
our $AUTHOR = 'justnoxx';
our $ABSTRACT = "Swiss-knife for daemonization";

our $DEBUG = 0;

our $LOCK;

sub new {
    my ($class, %params) = @_;

    my $self = {};
    $self->{daemon_data}->{daemonize} = 1;

    if ($params{user}) {
        $self->{daemon_data}->{user} = $params{user};
    }

    if ($params{group}) {
        $self->{daemon_data}->{group} = $params{group};
    }
    
    if ($params{pidfile}) {
        $self->{daemon_data}->{pidfile} = $params{pidfile};
    }

    if ($params{mkdir}) {
        $self->{daemon_data}->{mkdir} = 1;
    }

    if ($params{procname}) {
        $self->{daemon_data}->{procname} = $params{procname};
    }
    
    if (exists $params{daemonize}) {
        $self->{daemon_data}->{daemonize} = $params{daemonize};
    }
    
    if ($params{cleanup_on_destroy}) {
        $self->{daemon_data}->{cleanup_on_destroy} = 1;
    }

    bless $self, $class;
    return $self;
}


sub daemonize {
    my $self = shift;

    unless ($self->{daemon_data}->{daemonize}) {
        carp "Daemonization disabled";
        return 1;
    }
    
    my $dd = $self->{daemon_data};

    my $process_object = System::Daemon::Utils::process_object();

    # wrapper context
    System::Daemon::Utils::daemon();
    
    # let's validate user and group
    if ($dd->{user} || $dd->{group}) {
        System::Daemon::Utils::validate_user_and_group(
            user    =>  $dd->{user},
            group   =>  $dd->{group},
        ) or do {
            croak "Bad user or group";
        };
    }

    if ($dd->{pidfile}) {
        System::Daemon::Utils::validate_pid_path($dd->{pidfile}, $dd->{mkdir});
    }
    System::Daemon::Utils::make_sandbox($dd) if $dd->{mkdir};
    # daemon context
    if ($dd->{pidfile}) {
        croak "Can't overwrite pid file of my alive instance" unless $self->ok_pid();
        if ($dd->{pidfile}) {
            open $LOCK, $dd->{pidfile};
            my $got_lock = flock($LOCK, LOCK_EX | LOCK_NB);
            unless ($got_lock) {
                warn "Can't get lock\n";
                exit 1;
            }
        }

        System::Daemon::Utils::write_pid($dd->{pidfile}, undef,
            user    =>  $dd->{user},
            group   =>  $dd->{group}
        );
    }
    
    if ($dd->{user} || $dd->{group}) {
        System::Daemon::Utils::apply_rights(
            user    =>  $dd->{user},
            group   =>  $dd->{group}
        );
    }

    if ($dd->{procname}) {
        $0 = $dd->{procname};
    }

    if ($dd->{cleanup_on_destroy}) {
        *{System::Daemon::DESTROY} = sub {
            my $obj = shift;
            $obj->cleanup();
        };
    }

    System::Daemon::Utils::suppress();
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

    return 1 unless $pidfile;

    unless (System::Daemon::Utils::pid_init($self->{daemon_data}->{pidfile})) {
        croak "Can't init pidfile";
    }

    my $pid;
    unless ($pid = System::Daemon::Utils::read_pid($pidfile)) {
        return 1;
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

=head1 NAME

System::Daemon - Swiss-knife for daemonization

=head1 DESCRIPTION

Swiss-knife for daemonization

=head1 SYNOPSIS

See little example:

    use System::Daemon;
    
    $0 = 'my_daemon_process_name';

    my $daemon = System::Daemon->new(
        user            =>  'username',
        group           =>  'groupname',
        pidfile         =>  'path/to/pidfile',
        daemonize       =>  0,
    );
    $daemon->daemonize();

    your_cool_code();

    $daemon->exit(0);

=head1 METHODS

=over

=item new(%params)

Constructor, returns System::Daemon object. Available parameters:

    user            =>  desired_username,
    group           =>  desired_groupname,
    pidfile         =>  '/path/to/pidfile',
    procname        =>  process name for ps output,
    mkdir           =>  tries to create directory for pid files,
    daemonize       =>  if not true, will not daemonize, for debug reasons,
    procname        =>  after daemonize $0 will be updated to desired name,


=item daemonize

Call it to become a daemon.

=item exit($exit_code)

An exit wrapper, also, it performing cleanup before exit.

=item finish

Performing cleanup. At now cleanup is just pid file removing.

=item cleanup

Same as finish.


=item process_object

Returns System::Process object of daemon instance.

=back

=cut

