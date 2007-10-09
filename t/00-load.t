#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'POE::Component::SNMP::Session' );
}

use POE; $poe_kernel->run;

diag( "Testing POE::Component::SNMP::Session $SNMP::Session::POE::VERSION, Perl $], $^X" );

ok (POE::Component::SNMP::Session->can('create'), 'POE constructor exists');

