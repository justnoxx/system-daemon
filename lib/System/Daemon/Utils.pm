package System::Daemon::Utils;

use strict;
use warnings;

use Carp;
use POSIX;
use Data::Dumper;

use System::Process;

our $DEBUG = 0;

sub apply_rights {
    my %params = @_;

    if ($params{group}) {
        my $gid = getgrnam($params{group});
        unless ($gid) {
            croak "Group $params{group} does not exists.";
        }
        unless (setgid($gid)) {
            croak "Can't setgid $gid: $!";
        }
    }

    if ($params{user}) {
        my $uid = getpwnam($params{user});
        unless ($uid) {
            croak "User $params{user} does not exists.";
        }
        unless (setuid($uid)) {
            croak "Can't setuid $uid: $!";
        }
    }
    return 1;
}

sub validate_user_and_group {
    my %params = @_;
    
    my $err = 0;

    if (!$params{user} && !$params{group}) {
        croak "Missing user and group param, can't validate.";
    }
    my ($user, $group) = ($params{user}, $params{group});
    if ($user) {
        my $uid = validate_user($user);
        unless ($uid) {
            carp "Wrong username";
            $err++;
        }
    }

    if ($group) {
        my $gid = validate_group($group);
        unless ($gid) {
            carp "Wrong groupname";
            $err++;
        }
    }

    if ($err) {
        return 0;
    }

    return 1;
}

sub validate_group {
    my $group = shift;
    
    my $gid = getgrnam($group);
    unless ($gid) {
        return -1;
    }
    return $gid;
}


sub validate_user {
    my $user = shift;
    
    my $uid = getgrnam($user);
    unless ($uid) {
        return -1;
    }
    return $uid;
}


sub daemon {
    fork and exit;
    POSIX::setsid();
    fork and exit;
    umask 0;
    chdir '/';
    return 1;
}


sub pid_init {
    my $pid = shift;

    croak "Can't init nothing" unless $pid;

    if (!-e $pid) {
        # файла нет
        # пробуем его создать
        open PID, '>', $pid or do {
            carp "Can't create pid $pid: $!";
            return 0;
        };
        return 1;
    }

    # проверять нечего, оно ок
    return 1;
}


sub write_pid {
    my ($pidfile, $pid) = @_;

    $pid ||= $$;

    croak "No pidfile" unless $pidfile;

    open PID, '>', $pidfile;
    print PID $pid;
    close PID;
}


sub read_pid {
    my ($pidfile) = @_;

    croak "No pidfile param" unless $pidfile;

    return 0 unless -e $pidfile;

    open PID, $pidfile;
    my $pid = <PID>;

    return 0 unless $pid;

    close PID;

    chomp $pid;

    my $res = validate_pid($pid);
    return 0 unless $res;

    return $pid;
}


sub is_alive {
    my ($pid, $pattern) = @_;

    $pid ||= $$;

    my $sp = System::Process::pidinfo(
        pid  =>  $pid,
    );
    return 0 unless $sp;
    return 0 unless $sp->cankill();

    # раз мы можем попробовать убить процесс, с большой вероятностью
    # он существует
    if ($pattern) {
        my $command = $sp->command();
        if ($command =~ m/$pattern/s) {
            return 1;
        }
        return 0;
    }
    return 1;
}


sub delete_pidfile {
    my $pidfile = shift;
    
    unlink $pidfile or do {carp "$!"} and return 0;

    return 1;
}


sub process_object {
    my ($pid) = @_;

    $pid ||= $$;
    return System::Process::pidinfo pid => $pid;
}


sub validate_pid {
    my ($pid) = @_;

    return 0 unless $pid;
    if ($pid =~ m/^\d*$/s) {
        return 1;
    }
    return 0;
}


sub suppress {
    open STDIN , '<', '/dev/null';
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
}
1;

__END__
