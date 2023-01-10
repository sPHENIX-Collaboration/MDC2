#!/usr/bin/perl

use strict;
use warnings;
use Cwd;

sub ncondorjobs;
sub condorcheck;

my $nsubmit = 0;
my $nsafejobs = 60000;

my $submittopdir = "/sphenix/u/sphnxpro/MDC2/submit";
my @submitdir = (
    "fm_0_20/pass2/condor",
    "fm_0_20/pass2_nopileup/condor",
    "fm_0_20/pass3trk/condor",
    "fm_0_20/pass3calo/condor",
    "fm_0_20/pass3_job0_nopileup/condor",
    "fm_0_20/pass3_jobA_nopileup/condor",
    "fm_0_20/pass3_jobC_nopileup/condor",
    "fm_0_20/pass4_job0/condor",
    "fm_0_20/pass4_jobA/condor",
    "fm_0_20/pass4_jobC/condor",
#"fm_0_488/pass2/condor",
#"fm_0_488/pass3trk/condor",
#"fm_0_488/pass3calo/condor",
#"fm_0_488/pass4_job0/condor",
#"fm_0_488/pass4_jobA/condor",
#"fm_0_488/pass4_jobC/condor",
    "pythia8_pp_mb/pass2/condor",
    "pythia8_pp_mb/pass2_nopileup/condor",
    "pythia8_pp_mb/pass3trk/condor",
    "pythia8_pp_mb/pass3calo/condor",
    "pythia8_pp_mb/pass3_job0_nopileup/condor",
    "pythia8_pp_mb/pass3_jobA_nopileup/condor",
    "pythia8_pp_mb/pass3_jobC_nopileup/condor",
    "pythia8_pp_mb/pass3jet_nopileup/condor",
    "pythia8_pp_mb/pass4_job0/condor",
    "pythia8_pp_mb/pass4_jobA/condor",
    "pythia8_pp_mb/pass4_jobC/condor",
    "pythia8_pp_mb/pass4jet/condor",
#"HF_pp200_signal/pass2/condor",
#"HF_pp200_signal/pass3trk/condor",
#"HF_pp200_signal/pass3calo/condor",
#"HF_pp200_signal/pass4_job0/condor",
#"HF_pp200_signal/pass4_jobA/condor",
#"HF_pp200_signal/pass4_jobC/condor",
#"HF_pp200_signal/pass5truthreco/condor",
#"JS_pp200_signal/pass2/condor",
    "JS_pp200_signal/pass2_embed/condor",
    "JS_pp200_signal/pass2_nopileup/condor",
#"JS_pp200_signal/pass3calo/condor",
    "JS_pp200_signal/pass3calo_embed/condor",
    "JS_pp200_signal/pass3jet_nopileup/condor",
    "JS_pp200_signal/pass3_job0_nopileup/condor",
    "JS_pp200_signal/pass3_jobA_nopileup/condor",
    "JS_pp200_signal/pass3_jobC_nopileup/condor",
#"JS_pp200_signal/pass3trk/condor",
    "JS_pp200_signal/pass3trk_embed/condor",
#"JS_pp200_signal/pass4jet/condor",
    "JS_pp200_signal/pass4jet_embed/condor",
#"JS_pp200_signal/pass4_job0/condor",
    "JS_pp200_signal/pass4_job0_embed/condor",
#"JS_pp200_signal/pass4_jobA/condor",
    "JS_pp200_signal/pass4_jobA_embed/condor",
#"JS_pp200_signal/pass4_jobC/condor",
    "JS_pp200_signal/pass4_jobC_embed/condor"
    );

my @quarkfilters = ("Charm", "Bottom", "JetD0");
#my @jettriggers = ("Jet10", "Jet30", "PhotonJet");
my @jettriggers = ("Jet10", "Jet30");

foreach my $subdir (@submitdir)
{
    my $newdir = sprintf("%s/%s",$submittopdir,$subdir);
    if (! -d $newdir)
    {
	print "dir $newdir does not exist\n";
	next;
    }
    chdir $newdir;
    if (! -f "run_all.pl")
    {
	print "run_all.pl does not exist in $newdir\n";
	next;
    }
    if ($newdir =~ /HF_pp200_signal/)
    {
	foreach my $qf (@quarkfilters)
	{
	    my $submitcmd = sprintf("perl run_all.pl %d %s -inc -shared",$nsubmit,$qf);
            condorcheck();
	    print "executing $submitcmd in $newdir\n";
	    system($submitcmd);
	}
    }
    elsif ($newdir =~ /JS_pp200_signal/)
    {
	foreach my $qf (@jettriggers)
	{
	    my $submitcmd = sprintf("perl run_all.pl %d %s -inc",$nsubmit,$qf);
            condorcheck();
	    print "executing $submitcmd in $newdir\n";
	    system($submitcmd);
	}
    }
    else
    {
	my $submitcmd = sprintf("perl run_all.pl %d -inc",$nsubmit);
        condorcheck();
	print "executing $submitcmd in $newdir\n";
	system($submitcmd);
    }
}

print "all done\n";

sub ncondorjobs()
{
    my $njobads = `condor_status -schedd -statistics schedd -l -direct \`hostname\` | egrep -i '^TotalJob(Ads)'`;
    chomp $njobads;
    my @sp1 = split(/ /,$njobads);
    my $njobs = $sp1[$#sp1];
    return $njobs;
}

sub condorcheck()
{
    my $numjobs = ncondorjobs();
    if ($numjobs >= $nsafejobs)
    {
	print "Number of condor jobs $numjobs exceeds safe limit of $nsafejobs\n";
	print "all done\n";
	exit(0);
    }
}
