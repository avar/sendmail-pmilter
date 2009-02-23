# $Id: Makefile.PL,v 1.11 2004/08/10 21:10:36 tvierling Exp $

use 5.006;
use ExtUtils::MakeMaker;

my $install = ( ExtUtils::MakeMaker::prompt(<<EOT . 'Do you wish to install the Sendmail::Milter interface?' => 'yes' ) =~ /^\s*(y)/i );

The Sendmail::PMilter distribution includes a module that supplies a 
compatibility interface emulating the standard Sendmail::Milter API,
rather than using the native libmilter (which is not compatible
with modern Perl threads).

Choose "no" below ONLY IF the standard Sendmail::Milter package is
installed or will be installed.  Otherwise, the compatibility
interface MUST be installed, as it is needed for Sendmail::PMilter
to function properly.

EOT

my %PM = (
        'lib/Sendmail/PMilter.pm'           =>  '$(INST_LIBDIR)/PMilter.pm',
        'lib/Sendmail/PMilter/Context.pm'   =>  '$(INST_LIBDIR)/PMilter/Context.pm'
);
$PM{'lib/Sendmail/Milter.pm'} = '$(INST_LIBDIR)/Milter.pm' if $install;

WriteMakefile(
    ABSTRACT_FROM	=> 'lib/Sendmail/PMilter.pm',
    AUTHOR		=> 'Todd Vierling <tv@duh.org>',
    PM			=>  \%PM,
    NAME		=> 'Sendmail::PMilter',
    VERSION_FROM	=> 'lib/Sendmail/PMilter.pm',
);
