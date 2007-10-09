use strict;
use warnings;
use ExtUtils::MakeMaker;

my $CONFIG_MODE = 0600;
my $CONFIG_FILE = "config.cache";

WriteMakefile(
              NAME                => 'POE::Component::SNMP::Session',
              AUTHOR              => 'Rob Bloodgood <rdb@cpan.org>',
              VERSION_FROM        => 'lib/POE/Component/SNMP/Session.pm',
              ABSTRACT_FROM       => 'lib/POE/Component/SNMP/Session.pm',
              PL_FILES            => {},
              PREREQ_PM           => {
                                      'SNMP'       => 3.1,
                                      'POE'        => 0.38,
                                      'Test::More' => 0,
                                     },
              dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean               => { FILES => 'POE-Component-SNMP-Session-*' },
             );


my $DEBUG_FLAG = 0x00; # none

print "The test suite requires access to an SNMP agent.\n";
my $hostname = prompt("enter a hostname [leave empty to skip all tests]");

if ($hostname) {
    my $rcomm    = prompt("enter read community string", 'public');
    my $wcomm    = prompt("enter write community string [leave empty to skip write tests]");

    print "creating $CONFIG_FILE\n";
    open TESTCONF, "> $CONFIG_FILE" or die "can't create $CONFIG_FILE: $!\n";
    print TESTCONF <<CONFIGURATION;
 \$CONF = {
    hostname   => '$hostname',
    community  => '$rcomm',
    wcommunity => '$wcomm',
    debug      => $DEBUG_FLAG,
 };
CONFIGURATION
    close TESTCONF or die "can't close $CONFIG_FILE: $!\n";
} else {
    print "creating $CONFIG_FILE\n";
    open TESTCONF, "> $CONFIG_FILE" or die "can't create $CONFIG_FILE: $!\n";
    print TESTCONF "\$TEST_CONF = { skip_all_tests => 1 };\n";
    close TESTCONF or die "can't close $CONFIG_FILE: $!\n";
}

chmod $CONFIG_MODE, $CONFIG_FILE;

exit 0;

# extra targets for realclean to delete the config file
package MY;
sub macro { "CONFIG_FILE = $CONFIG_FILE" }
sub realclean {
    shift->SUPER::realclean(@_) .
      qq[\t- \$(RM_F) \$(CONFIG_FILE)] # don't forget \t here!
}
