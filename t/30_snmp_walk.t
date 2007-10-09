
use Test::More;

BEGIN { use_ok('POE::Component::SNMP::Session') };

use POE;
use POE::Component::SNMP::Session;

use lib qw(t);
use TestPCS;

my $CONF = do "config.cache";

if ( $CONF->{skip_all_tests} ) {
    $poe_kernel->run(); # quiets POE::Kernel warning
    plan skip_all => 'No SNMP data specified.';
} else {
    plan tests => 13;
}


POE::Session->create
( inline_states =>
  {
    _start      => \&snmp_get_tests,
    _stop       => \&stop_session,
    snmp_get_cb => \&snmp_get_cb,
  },
);

$poe_kernel->run;

ok 1; # clean exit
exit 0;


sub snmp_get_tests {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    POE::Component::SNMP::Session->create(
                                          alias     => 'snmp',
                                          hostname  => $CONF->{'hostname'},
                                          Community => $CONF->{'community'},
                                          debug     => $CONF->{debug},
                                          # timeout => 5,
                                          Version => 2,
                                          # UseNumeric => 1
                                         );

    my $vars = new SNMP::VarList ( # ['sysUpTime'],
                                  ['ifNumber'], # NON-repeaters
                                  # ['ifSpeed'],
                                  ['ifDescr'],
                                   # ['.1.3.6.1.2.1.1'], # system.*
                                   # ['.1.3.6.1.2.1.1.9'], # system.sysORUpTime
                                   # [ 'sysORUpTime' ],

                                 ); # Repeated variables.

    # $vars = new SNMP::VarList ( ['sysUpTime'], ['ifNumber'], # NON-repeaters
    #                                ['system']); # Repeated variables.

    $kernel->post(
        snmp => 'bulkwalk',
        'snmp_get_cb',
                  # 2, 3,
                  1, 8,
                  $vars

                  # '.1.3.6.1.2.1.1',
    );

    get_sent($heap);
}

# store results for future processing
sub snmp_get_cb {
    my ($kernel, $heap, $aref) = @_[KERNEL, HEAP, ARG1];
    ok get_seen($heap), 'ced axo'; # received request

    ok ref $aref eq 'ARRAY', ref $aref;

    # use YAML; print Dump { axl => $_[ARG0], axo => $_[ARG1]};

    # my $session = shift @$aref;

    my $href = $aref->[0];

    ok ref $href, ref $href;

    ok ref $href eq 'ARRAY', 'data type e sane'; # no error

    # foreach my $k (keys %$href) {
    foreach my $varlist (@$href) {
	ok ref $varlist eq 'SNMP::VarList', ref ($varlist) . ' e SNMP::VarList';
        # if ref $varlist = 'SNMP::VarList'
        for my $var ( @$varlist ) {
            # ok ref $var eq 'SNMP::Varbind', ref ($var) . ' e SNMP::Varbind';
            # varbinds are just array refs

            push @{$heap->{results}{$var->[0]}}, $var->[2]; # got a result
        }
    }

    if (check_done($heap)) {
	$kernel->post( snmp => 'finish' );
	ok check_done($heap);
    }
}

sub stop_session {
   my $r = $_[HEAP]->{results};

   # use YAML; print Dump($r);

   ok 1, "stopped cleanly"; # got here!

   ok exists $r->{ifNumber};
   ok exists $r->{ifDescr};
   ok ref $r->{ifNumber} eq 'ARRAY' and   $r->{ifNumber}[0]  >   0;
   ok ref $r->{ifDescr}  eq 'ARRAY' and @{$r->{ifDescr}}     ==  $r->{ifNumber}[0];

}
