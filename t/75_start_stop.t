use Test::More; # qw/no_plan/;
use strict;

use lib qw(t);
use TestPCS;

use POE qw/Component::SNMP::Session/;

my $CONF = do "config.cache";

if ( $CONF->{skip_all_tests} or not keys %$CONF ) {
    $poe_kernel->run(); # quiets POE::Kernel warning
    plan skip_all => 'No SNMP data specified.';
} else {
    if (1) {
        plan tests => 7;
    } else {
        $poe_kernel->run(); # quiets POE::Kernel warning
        plan skip_all => 'not done yet';
    }
}

my %system = ( sysUptime   => '.1.3.6.1.2.1.1.3.0',
               sysName     => '.1.3.6.1.2.1.1.5.0',
               sysLocation => '.1.3.6.1.2.1.1.6.0',
             );

my @oids = map { [ $_] } values %system;
my $base_oid = '.1.3.6.1.2.1.1'; # system.*

POE::Session->create( inline_states =>
                        { _start       => \&_start,
                          snmp_handler => \&snmp_handler,
			  _stop        => \&stop_session,
                        }
                      );

my $done = 0;

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    POE::Component::SNMP::Session->create(
                                 alias     => 'snmp',
                                 hostname  => $CONF->{'hostname'},
                                 community => $CONF->{'community'},
				 version   => 'snmpv2c',
                                 debug     => $CONF->{debug},

                                 # timeout   => 5,

                                );

    ok $kernel->alias_resolve( 'snmp' ), "1st session created";

    $kernel->post( snmp => get   => snmp_handler => \@oids );
}

sub snmp_handler {
    my ($kernel, $heap, $request, $response) = @_[KERNEL, HEAP, ARG0, ARG1];
    my ($alias, $host, $session, $cmd, @args) = @$request;
    # my $session = shift @$response;
    my ($results, @callback_args)   = @$response;
    ok get_seen($heap);

    if (ref $results) {
	    ok ref $results eq 'SNMP::VarList', ref $results; # no error
    } else {
	print STDERR "$host SNMP error ($cmd => @args):\n$results\n";
    }

    $kernel->post( snmp => 'finish' );

    # $kernel->delay('_start', 1) unless $done++;
    $kernel->yield('_start', 1) unless $done++;
}

sub stop_session {
    my $r = $_[HEAP]->{results};
    ok 1; # got here!
}

$poe_kernel->run();

