#!/usr/local/bin/perl -I../lib
# $Id: protocol-dump.pl,v 1.5 2004/08/02 17:55:36 tvierling Exp $

use strict;
use Carp qw(verbose);
use Sendmail::PMilter qw(:all);

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

my $milter = new Sendmail::PMilter;

$milter->auto_setconn($miltername);
$milter->register($miltername, \%cbs, SMFI_CURR_ACTS);

my $dispatcher = Sendmail::PMilter::prefork_dispatcher(
	max_children => 10,
	max_requests_per_child => 100,
);

$milter->set_dispatcher($dispatcher);
$milter->main();
