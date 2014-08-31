use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my %make_params = (
    NAME             => 'System::Daemon',
    AUTHOR           => 'Shamatrin Dmitriy',
    VERSION_FROM     => 'lib/System/Daemon.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },  
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    "test" => {
        "TESTS" => "t/*.t"
    }
);

# if so, ExtUtils::MakeMaker supports META_MERGE tag
if ($ExtUtils::MakeMaker::VERSION >= 6.46) {
    $make_params{META_MERGE} = {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type    => 'git',
                url     => 'https://github.com/justnoxx/system-daemon',
                web     => 'https://github.com/justnoxx/system-daemon.git',
            },
        },
    };
}
WriteMakefile(%make_params);
