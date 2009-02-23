#!/usr/local/bin/perl -I../lib
# $Id: protocol-dump-compat.pl,v 1.2 2004/08/02 17:55:56 tvierling Exp $
#
# Similar to protocol_dump.pl, but uses the Sendmail::Milter compatibility
# interface instead.
#

use strict;
use Carp qw(verbose);
use Sendmail::Milter 0.18 qw(:all);

# milter name should be the one used in sendmail.mc/sendmail.cf
my $miltername = shift @ARGV || die "usage: $0 miltername\n";

my %cbs;
for my $cb (qw(close connect helo abort envfrom envrcpt header eoh eom)) {
	$cbs{$cb} = sub {
		my $ctx = shift;

		print "$$: $cb: @_\n";
		SMFIS_CONTINUE;
	}
}

Sendmail::Milter::auto_setconn($miltername);
Sendmail::Milter::register($miltername, \%cbs, SMFI_CURR_ACTS);
Sendmail::Milter::main();
