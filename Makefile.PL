use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
# use File::ShareDir::Install;

# install_share dist => 'share';

WriteMakefile(
    NAME             => 'System::Daemon',
    AUTHOR           => 'Shamatrin Dmitriy',
    VERSION_FROM     => 'lib/System/Daemon.pm',
    # ABSTRACT_FROM    => 'lib/System/InitD.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    # EXE_FILES        => ['script/geninit'],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },  
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },  
    # PREREQ_PM => {
    #     #'ABC'              => 1.6,
    #     #'Foo::Bar::Module' => 5.0401,
    # },
    # dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    # clean => { FILES => 'Data-Dir-*' },
    "test" => {
        "TESTS" => "t/*.t"
    }
);

# package MY;
# use File::ShareDir::Install 'postamble';