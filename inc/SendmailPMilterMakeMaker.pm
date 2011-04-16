package inc::SendmailPMilterMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my ($self) = @_;
    my $template = super();

    my $question = <<'QUESTION';
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

QUESTION

my $pm = <<'PM_WHATEVER';
my %PM = (
        'lib/Sendmail/PMilter.pm'           =>  '$(INST_LIBDIR)/PMilter.pm',
        'lib/Sendmail/PMilter/Context.pm'   =>  '$(INST_LIBDIR)/PMilter/Context.pm'
);
$PM{'lib/Sendmail/Milter.pm'} = '$(INST_LIBDIR)/Milter.pm' if $install;
$WriteMakefileArgs{PP} = \%PM;
PM_WHATEVER

    $template =~ s/(^my \{\{ \$WriteMakefileArgs \}\})/$question$1$pm/m;

    return $template;
};

__PACKAGE__->meta->make_immutable;
