#!/usr/bin/perl

use strict;
use warnings;
use Cwd;

sub ncondorjobs;
sub condorcheck;

my $nsubmit = 15000;
my $nsafejobs = 5000;

my $submittopdir = "/sphenix/u/sphnxpro/MDC2/submit";
my %submitdir = (
    "fm_0_20/cemc_geo_fix/cemc_hits/condor" => (""),
    "fm_0_20/cemc_geo_fix/cemc_hits_pass2/condor" => (""),
    "fm_0_20/cemc_geo_fix/cemc_hits_pass3trk/condor" => (""),
    "pythia8_pp_mb/cemc_geo_fix/cemc_hits/condor" => (""),
    "JS_pp200_signal/cemc_geo_fix/cemc_hits_pass2/condor" => ("")
    );

#my @quarkfilters = ("Charm", "Bottom", "JetD0");
my @quarkfilters = ("Charm", "CharmD0piKJet5", "CharmD0piKJet12");
my @jettriggers1 = ("Jet10", "Jet20");
my @jettriggers2 = ("Jet10", "Jet30", "Jet40", "PhotonJet");
#my @jettriggers = ("Jet10", "Jet30");
#my @singleparticles = {"gamma 10000 10000"};

foreach my $subdir (sort keys %submitdir)
{
    my $submitargs = $submitdir{$subdir};
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
	    my $submitcmd = sprintf("perl run_all.pl %d %s -inc %s",$nsubmit,$qf,$submitargs);
            condorcheck();
	    print "executing $submitcmd in $newdir\n";
	    system($submitcmd);
	}
    }
    elsif ($newdir =~ /JS_pp200_signal/)
    {
	if ($newdir =~ /pau/)
	{
	    foreach my $qf (@jettriggers1)
	    {
		my $submitcmd = sprintf("perl run_all.pl %d %s -inc %s",$nsubmit,$qf,$submitargs);
		condorcheck();
		print "executing $submitcmd in $newdir\n";
		system($submitcmd);
	    }
	}
	else
	{
	    foreach my $qf (@jettriggers2)
	    {
		my $submitcmd = sprintf("perl run_all.pl %d %s -inc %s",$nsubmit,$qf,$submitargs);
		condorcheck();
		print "executing $submitcmd in $newdir\n";
		system($submitcmd);
	    }
	}

    }
    elsif ($newdir =~ /single_particle/)
    {
	    my $submitcmd = sprintf("perl run_all.pl %d gamma 10000 10000 -inc %s",$nsubmit,$submitargs);
            condorcheck();
	    print "executing $submitcmd in $newdir\n";
	    system($submitcmd);
    }
    else
    {
	my $submitcmd = sprintf("perl run_all.pl %d -inc %s",$nsubmit,$submitargs);
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
