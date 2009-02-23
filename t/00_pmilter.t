#   $Header: /cvsroot/pmilter/pmilter/t/00_pmilter.t,v 1.4 2004/02/26 22:28:58 tvierling Exp $

#   Copyright (c) 2002-2004 Todd Vierling <tv@duh.org> <tv@pobox.com>
#   Copyright (c) 2004 Robert Casey <rob.casey@bluebottle.com>
#
#   This file is covered by the terms in the file COPYRIGHT supplied with this
#   software distribution.


BEGIN {

    use Test::More 'tests' => 55;

    use_ok('Sendmail::PMilter');
}


#   Perform some basic tests of the module constructor and available methods

can_ok(
        'Sendmail::PMilter',
                'auto_getconn',
                'auto_setconn',
                'get_max_interpreters',
                'get_max_requests',
                'get_sendmail_cf',
                'get_sendmail_class',
                'main',
                'new',
                'register',
                'setconn',
                'set_dispatcher',
                'set_listen',
                'set_sendmail_cf',
                'set_socket'
);

ok( my $milter = Sendmail::PMilter->new );
isa_ok( $milter, 'Sendmail::PMilter' );


#   Perform some tests on namespace symbols which should be defined within the 
#   Sendmail::PMilter namespace.  Not tested yet is the export of these symbols 
#   into the caller's namespace - TODO.

my %CONSTANTS = (

        'SMFIS_CONTINUE'    =>  100,
        'SMFIS_REJECT'      =>  101,
        'SMFIS_DISCARD'     =>  102,
        'SMFIS_ACCEPT'      =>  103,
        'SMFIS_TEMPFAIL'    =>  104,

        'SMFIF_ADDHDRS'     =>  0x01,
        'SMFIF_CHGBODY'     =>  0x02,
        'SMFIF_ADDRCPT'     =>  0x04,
        'SMFIF_DELRCPT'     =>  0x08,
        'SMFIF_CHGHDRS'     =>  0x10,
        'SMFIF_MODBODY'     =>  0x02,

        'SMFI_V1_ACTS'      =>  0x0F,
        'SMFI_V2_ACTS'      =>  0x1F,
        'SMFI_CURR_ACTS'    =>  0x1F
);

foreach my $constant (keys %CONSTANTS) {

    no strict 'refs';
    my $symbol = "Sendmail::PMilter::$constant"->();
    ok( defined $symbol, "Sendmail::PMilter::$constant" );
    SKIP: {

        skip("- Sendmail::PMilter::$constant not defined", 1) unless defined $symbol;
        is( $symbol, $CONSTANTS{$constant} );
    }
}


#   Of the module methods, the get_sendmail_cf function is tested first given 
#   the number of other methods dependent upon this method.  By default, this 
#   method should return the Sendmail configuration file as - 
#   '/etc/mail/sendmail.cf'.

ok( my $cf = $milter->get_sendmail_cf );
ok( defined $cf );
is( $cf, '/etc/mail/sendmail.cf' );


#   Test the corresponding set_sendmail_cf function by setting a new value for 
#   this parameter and then testing the return value from get_sendmail_cf

ok( $milter->set_sendmail_cf('t/files/sendmail.cf') );
is( $milter->get_sendmail_cf, 't/files/sendmail.cf' );
ok( $milter->set_sendmail_cf() );
is( $milter->get_sendmail_cf, '/etc/mail/sendmail.cf' );


#   Test the auto_getconn function using our own set of test sendmail 
#   configuration files - The first test should fail as a result of the name 
#   parameter not having been defined.

eval { $milter->auto_getconn() };
ok( defined $@ );

my @sockets = (
        'local:/var/run/milter.sock',
        'unix:/var/run/milter.sock',
        'inet:3333@localhost',
        'inet6:3333@localhost'
);
foreach my $index (0 .. 4) {

    my $cf = sprintf('t/files/sendmail%d.cf', $index);
    SKIP: {

        skip("- Missing file $cf", 3) unless -e $cf;
        ok( $milter->set_sendmail_cf($cf), $cf );
        my $socket = shift @sockets;
        ok( 
                ( ! defined $socket ) or 
                ( my $milter_socket = $milter->auto_getconn('test-milter') ) 
        );
        is( $milter_socket, $socket, defined $socket ? $socket : '(undef)' );


        #   Test the creation of the milter connection socket with the setconn function 
        #   for each of the test sendmail configuration files parsed.

    }
}


1;


__END__
