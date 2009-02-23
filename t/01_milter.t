#   $Header: /cvsroot/pmilter/pmilter/t/01_milter.t,v 1.1 2004/02/22 08:43:23 rob_au Exp $

#   Copyright (c) 2002-2004 Todd Vierling <tv@duh.org> <tv@pobox.com>
#   Copyright (c) 2004 Robert Casey <rob.casey@bluebottle.com>
#
#   This file is covered by the terms in the file COPYRIGHT supplied with this
#   software distribution.


BEGIN {

    use Test::More 'tests' => 30;

    use_ok('Sendmail::Milter');
}


#   Perform some basic tests of the module constructor and available methods

can_ok(
        'Sendmail::Milter',
                'auto_getconn',
                'auto_setconn',
                'get_milter',
                'main',
                'register',
                'setconn'
);


#   Perform some tests on namespace symbols which should be defined within the 
#   Sendmail::Milter namespace.  Not tested yet is the export of these symbols 
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
    my $symbol = "Sendmail::Milter::$constant"->();
    ok( defined $symbol, "Sendmail::Milter::$constant" );
    SKIP: {

        skip("- Sendmail::PMilter::$constant not defined", 1) unless defined $symbol;
        is( $symbol, $CONSTANTS{$constant} );
    }
}


#   Tests for the Sendmail::Milter interface functions should be repeated for 
#   completeness, despite the fact that these are merely exported from the 
#   Sendmail::PMilter module - TODO.


1;


__END__
