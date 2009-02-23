#!/usr/local/bin/perl -w
# $Id: crm114-milter.pl,v 1.1 2004/03/08 17:57:05 tvierling Exp $
#
# Date: Sun, 7 Mar 2004 00:11:13 -0500 (EST)
# From: Bob Tribit <btribit@newportal.com>
# To: Todd Vierling <tv@duh.org>
#
# [...]
# The milter is a little rough around the edges. I recommend for
# first time operation to remove/comment out the fork && exit; and run
# it in verbose mode to see what it is doing.
#

use strict;
use Carp qw(verbose);
use Getopt::Long;
use Sendmail::Milter 0.18 qw(:all);
use IPC::Open2;

my %cbs;
my @header;
my @email;
my $miltername = "crm114";
my $verbose = 0;
my $help = 0;
my $fileprefix="/etc/mail/crm114/";
my $secret = "g00b3r";
my $training = 0;
my $traininguser = "toe";
my $train_nospam = 0;
my $train_spam = 0;
my $usage = 0;



$cbs{header} = sub {
	my $ctx = shift;
	my @args = @_;
	for(my $ctr=0;$ctr<=$#args;$ctr++) {
		my $line .= $args[$ctr++];
		$line .= ": ".$args[$ctr]."\n";
		if($line =~ m/To\: /g) {
			my($subject, $value) = split /\: /, $line, 2;
			my($username, $domain) = split /\@/, $value, 2;
			$username =~ s/\<//g;
			if($username =~ m/$traininguser/g) {
				if($verbose) {print "TRAINING: It's alive!\n";}
				$training = 1;
			}
		}
		if(($line =~ m/Subject\: /g) && $training) {
			my($subject, $value) = split /\: /, $line, 2;
			if($value =~ m/$secret/g) {
				if($verbose) {print "TRAINING: Incoming training, secret verified\n";}
				if(($value =~ m/nospam/i) || ($value =~ m/nonspam/i)) {
					if($verbose) {print "TRAINING: Training for non spam.\n";}
					$train_nospam = 1;
				} else {
					if($verbose) {print "TRAINING: Training for spam.\n";}
					$train_spam = 1;
				}
			}
		}
		push @header, $line;
	}
	SMFIS_CONTINUE;
};

$cbs{body} = sub {
	my $ctx = shift;
	my @lines = @_;

	my $body;
	foreach my $line (@lines) {
		push @email, $line;
	}


	SMFIS_CONTINUE;
};

$cbs{eom} = sub {
	my $ctx = shift;

	if($training) {
		if($train_nospam) {
			open2 \*CRMR, \*CRMW, "/etc/mail/crm114/mailfilter.crm --fileprefix=$fileprefix --learnnonspam";
			foreach my $line (@email) {
				print CRMW $line;
			}
			close CRMW;
			close CRMR;
		} elsif($train_spam) {
			open2 \*CRMR, \*CRMW, "/etc/mail/crm114/mailfilter.crm --fileprefix=$fileprefix --learnspam";
			foreach my $line (@email) {
				print CRMW $line;
			}
			close CRMW;
			close CRMR;
		}
	} else {
		open2 \*CRMR, \*CRMW, "/etc/mail/crm114/mailfilter.crm --fileprefix=$fileprefix";
		foreach my $line (@header) {
			print CRMW $line;
		}
		foreach my $line (@email) {
			print CRMW $line;
		}
		close CRMW;

		while(<CRMR>) {
			my $line = $_;
			if($line =~ m/X-CRM114-Status/g) {
				chop $line;
				my ($header, $value) = split /\: /, $line, 2;
				$ctx->addheader("X-CRM114-Status", $value);
				if($verbose) {print $line;}
			} else {
				if($verbose) {print $line;}
			}
		}
		close CRMR;
	}

	SMFIS_CONTINUE;
};

#qw(close connect helo abort envfrom envrcpt header body eoh eom

my $result = GetOptions('verbose' => \$verbose,
			'fileprefix=s' => \$fileprefix,
			'traininguser=s' => \$traininguser,
			'miltername=s' => \$miltername,
			'help' => \$help);			

if($help) {
	print <<EOT;
usage: $0 --verbose --help --traininguser=<user>
	--fileprefix=<path> --miltername=<miltername>
EOT
}

fork && exit;

Sendmail::Milter::auto_setconn($miltername);
Sendmail::Milter::register($miltername, \%cbs, SMFI_CURR_ACTS);
Sendmail::Milter::main();


__END__

=head1 NAME

crm114-milter - CRM114 Sendmail Milter

=head1 SYNOPSIS

B<crm114-milter> S<[ B<--verbose> ]> S<[ B<--fileprefix=>I<'path'> ]>
S<[ B<--traininguser=>I<'user'> ]>
S<[ B<--miltername=>I<'milter'> ]>
S<[ B<--help> ]>


=head1 DESCRIPTION

This is an example Sendmail::PMilter for the CRM114 program. This milter
performs 2 basic functions. The classifying of spam by CRM114, and the
training of CRM114 for spam and non spam emails. The crm114-milter
currently only adds the header X-CRM114-Status to the email. The status
will be either "SPAM" or "Good".

CRM114 comes with a CRM script called mailfilter.crm. This script is used to
classify emails and train the CRM114 css files. To learn how to setup CRM114
follow steps 1, 2, 3, 4, & (optionally) 7. Perform these tasks in a directory
of your choosing. For this example, we use /etc/mail/crm114:

	mkdir /etc/mail/crm114
	cp mailfilter.cf /etc/mail/crm114
	cp mailfilter.crm /etc/mail/crm114
	cp *.mfp /etc/mail/crm114
	cssutil -b -r spam.css
	cssutil -b -r nonspam.css
	cp spam.css /etc/mail/crm114
	cp nonspam.css /etc/mail/crm114

=head1 SENDMAIL CONFIGURATION

Configuration is simple, add this line to your sendmail.mc file. The default
behaviour of crm114-milter will like this.

 INPUT_MAIL_FILTER(`crm114', `S=local:/var/run/spammilter/crm114.sock, F=, T=C:15m;S:4m;R:4m;E:10m')dnl

A user to send training emails is helpful in this type of environment. Set it up
for a group of admins to train the CRM114 css files. The default user is "toe", as
reminder to "train on errors". Setting up an alias in /etc/aliases, isn't a bad
idea either...

 toe:	root

Don't forget to run newaliases.

=head1 TRAINING

In order to train, you will need to modify the crm114-milter file and change the
secret to something appropriate for your site.

For spam or nonspam, forward the incorrectly identified email to the training user.
crm114-milter will key off of that user being sent email and train accordingly. If the
email was classified as SPAM, and was not, forward incorrectly classified email
to the training user, with the Subject: nonspam <your secret here>. If the email was SPAM,
and was classified as Good, again forward the email to the training user, but with the
Subject: <your secret here>.

=head1 SPAMASSASSIN

If you wish to integrate the crm114-milter with spamassassin, make sure you put the
crm114-milter before spamassassin in the InputFilter order. Then you can create simple
rules such as:

 header CRM114_SPAM      X-CRM114-Status =~ /SPAM/
 describe CRM114_SPAM    CRM114 Spam: CRM114 classifies this as spam
 score CRM114_SPAM       2.0

 header CRM114_GOOD      X-CRM114-Status =~ /Good/
 describe CRM114_GOOD    CRM114 Good: CRM114 classifies this as good
 score CRM114_GOOD       -2.0

=head1 BUGS

Yeah, probably. Send me what you find.

=head1 SEE ALSO

perl(1), Sendmail::PMilter

=head1 AUTHORS

Bob Tribit <btribit@newportal.com>
