#!/usr/bin/env perl

use strict;
use warnings;
use Cwd;

sub ncondorjobs;
sub condorcheck;

my $submittopdir = "/sphenix/u/sphnxpro/MDC2/submit";

my $hostname = `hostname -s`;
chomp $hostname;
my $tagfile = sprintf("%s/autopilot_%s.run",$submittopdir,$hostname);
if (-f $tagfile)
{
    exit 0;
}
my $tagfiletouch = sprintf("touch %s",$tagfile);
system($tagfiletouch);
my $nsubmit = 20000;
my $nsafejobs = 200000;

my %submitdir = (
#     "cosmic/pass2_nopileup/condor" => (""),
#    "fm_0_20/pass2/condor" => (""),
#    "fm_0_20/pass3trk/condor" => (""),
#    "fm_0_20/pass3calo/condor" => (""),
#    "fm_0_20/pass3_bbcepd/condor" => (""),
#    "fm_0_20/pass4_job0/condor" => (""),
#    "fm_0_20/pass4_jobA/condor" => (""),
#    "fm_0_20/pass4_jobC/condor" => (""),
#    "fm_0_20/pass5_global/condor" => (""),
#    "fm_0_20/pass5_truthreco/condor" => (""),
#

    "fm_0_20/pass3_global_nopileup/condor" => ("--run 36 --build ana.539"),
    "fm_0_20/pass2_nopileup/condor" => ("--run 36 --build ana.539 --disable_trk"),
#    "fm_0_20/pass3_job0_nopileup/condor" => (""),
#    "fm_0_20/pass3_jobA_nopileup/condor" => (""),
#    "fm_0_20/pass3_jobC_nopileup/condor" => (""),
#    "fm_0_20/pass4_global_nopileup/condor" => (""),
#    "fm_0_20/pass4_truthreco_nopileup/condor" => (""),
#     "fm_0_488/pass2/condor" => (""),
#     "fm_0_488/pass3trk/condor" => (""),
#     "fm_0_488/pass3calo/condor" => (""),
#     "fm_0_488/pass3_bbcepd/condor" => (""),
#     "fm_0_488/pass4_job0/condor" => (""),
#     "fm_0_488/pass4_jobA/condor" => (""),
#     "fm_0_488/pass4_jobC/condor" => (""),
#     "fm_0_488/pass5_global/condor" => (""),
#     "fm_0_488/pass5_truthreco/condor" => (""),

#     "fm_0_488/pass2_nopileup/condor" => (""),
#     "fm_0_488/pass3_job0_nopileup/condor" => (""),
#     "fm_0_488/pass3_jobA_nopileup/condor" => (""),
#     "fm_0_488/pass3_jobC_nopileup/condor" => (""),
#     "fm_0_488/pass4_global_nopileup/condor" => (""),
#     "fm_0_488/pass4_truthreco_nopileup/condor" => (""),
#    "pAu_0_10fm/pass2/condor" => (""),
#    "pAu_0_10fm/pass3global/condor" => (""),
#    "pAu_0_10fm/pass3trk/condor" => (""),
#    "pAu_0_10fm/pass3calo/condor" => (""),
#    "pAu_0_10fm/pass4_job0/condor" => (""),
#    "pAu_0_10fm/pass4_jobA/condor" => (""),
#    "pAu_0_10fm/pass4_jobC/condor" => (""),
#    "pAu_0_10fm/pass5_truthreco/condor" => (""),
#    "pythia8_pp_mb/pass2/condor" => (""),
#    "pythia8_pp_mb/pass3trk/condor" => (""),
#    "pythia8_pp_mb/pass3calo/condor" => (""),
#    "pythia8_pp_mb/pass3_bbcepd/condor" => (""),
#    "pythia8_pp_mb/pass4_job0/condor" => (""),
#    "pythia8_pp_mb/pass4_jobA/condor" => (""),
#    "pythia8_pp_mb/pass4_jobC/condor" => (""),
#    "pythia8_pp_mb/pass4jet/condor" => (""),
#    "pythia8_pp_mb/pass5_global/condor" => (""),
#    "pythia8_pp_mb/pass5_truthreco/condor" => (""),
#    "pythia8_pp_mb/pass2_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass3_job0_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass3_jobA_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass3_jobC_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass3jet_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass4_global_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass4_truthreco_nopileup/condor" => (""),

#    "Herwig/pass4_truthreco_nopileup/condor" => ("--build ana.455 allruns"),
#    "Herwig/pass4_global_nopileup/condor" => ("--build ana.455 allruns"),
#    "Herwig/pass3jet_nopileup/condor" => ("--build ana.455 allruns"),
#    "Herwig/pass3_jobC_nopileup/condor" => ("--build ana.455 allruns"),
#    "Herwig/pass3_jobA_nopileup/condor" => ("--build ana.455 allruns"),
#    "Herwig/pass3_job0_nopileup/condor" => ("--build ana.455 allruns"),
    "Herwig/pass3_global_nopileup/condor" => ("--build ana.536 --run 28"),
    "Herwig/pass2jet_nopileup/condor" => ("--build ana.536 --run 28"),
    "Herwig/pass2_nopileup/condor" => ("--build ana.536 --disable_trk --run 28"),

#     "HF_pp200_signal/pass2/condor" => (""),
#     "HF_pp200_signal/pass3trk/condor" => (""),
#     "HF_pp200_signal/pass3calo/condor" => (""),
#     "HF_pp200_signal/pass3_bbcepd/condor" => (""),
#     "HF_pp200_signal/pass4_job0/condor" => (""),
#     "HF_pp200_signal/pass4_jobA/condor" => (""),
#     "HF_pp200_signal/pass4_jobC/condor" => (""),
#     "HF_pp200_signal/pass5_global/condor" => (""),
#     "HF_pp200_signal/pass5_truthreco/condor" => (""),

#     "HF_pp200_signal/pass2_embed/condor" => (""),
#     "HF_pp200_signal/pass3trk_embed/condor" => (""),
#     "HF_pp200_signal/pass3calo_embed/condor" => (""),
#     "HF_pp200_signal/pass3_bbcepd_embed/condor" => (""),
#     "HF_pp200_signal/pass4_job0_embed/condor" => (""),
#     "HF_pp200_signal/pass4_jobA_embed/condor" => (""),
#     "HF_pp200_signal/pass4_jobC_embed/condor" => (""),
#     "HF_pp200_signal/pass5_global_embed/condor" => (""),
#     "HF_pp200_signal/pass5_truthreco_embed/condor" => (""),

#     "HF_pp200_signal/pass2_embed/condor" => ("--fm 0_488fm"),
#     "HF_pp200_signal/pass3trk_embed/condor" => ("--fm 0_488fm"),
#     "HF_pp200_signal/pass3calo_embed/condor" => ("--fm 0_488fm"),
#     "HF_pp200_signal/pass3_bbcepd_embed/condor" => ("--fm 0_488fm"),
#     "HF_pp200_signal/pass4_job0_embed/condor" => ("--fm 0_488fm"),
#     "HF_pp200_signal/pass4_jobA_embed/condor" => ("--fm 0_488fm"),
#     "HF_pp200_signal/pass4_jobC_embed/condor" => ("--fm 0_488fm"),
#     "HF_pp200_signal/pass5_global_embed/condor" => ("--fm 0_488fm"),
#     "HF_pp200_signal/pass5_truthreco_embed/condor" => ("--fm 0_488fm"),

#     "HF_pp200_signal/pass2_nopileup/condor" => (""),
#     "HF_pp200_signal/pass3_job0_nopileup/condor" => (""),
#     "HF_pp200_signal/pass3_jobA_nopileup/condor" => (""),
#     "HF_pp200_signal/pass3_jobC_nopileup/condor" => (""),
#     "HF_pp200_signal/pass4_global_nopileup/condor" => (""),
#     "HF_pp200_signal/pass4_truthreco_nopileup/condor" => (""),

#    "JS_pp200_signal/pass2/condor" => ("pileup --run 29 --build ana.522"),
#    "JS_pp200_signal/pass3calo/condor" => ("pileup --run 29 --build ana.522"),
#    "JS_pp200_signal/pass3trk/condor" => ("pileup --run 29 --build ana.522"),
#    "JS_pp200_signal/pass3_mbdepd/condor" => ("pileup --run 29 --build ana.522"),
#    "JS_pp200_signal/pass4jet/condor" => ("pileup --run 29 --build ana.522"),
#    "JS_pp200_signal/pass4_job0/condor" => ("pileup --run 29 --build ana.522"),
#    "JS_pp200_signal/pass4_jobA/condor" => ("pileup --run 29 --build ana.522"),
#    "JS_pp200_signal/pass4_jobC/condor" => ("pileup --run 29 --build ana.522"),
#    "JS_pp200_signal/pass5_global/condor" => ("pileup --run 29 --build ana.522"),
#    "JS_pp200_signal/pass5_truthreco/condor" => ("pileup --run 29 --build ana.522"),


# JS no pileup:
#    "JS_pp200_signal/pass3_job0_nopileup/condor" => ("--build ana.536 --run 29"),
#    "JS_pp200_signal/pass3_jobA_nopileup/condor" => ("--build ana.536 --run 29"),
#    "JS_pp200_signal/pass3_jobC_nopileup/condor" => ("--build ana.536 --run 29"),
#    "JS_pp200_signal/pass4_global_nopileup/condor" => ("--build ana.536 --run 29"),
#    "JS_pp200_signal/pass4_truthreco_nopileup/condor" => ("--build ana.536 --run 29"),
#    "JS_pp200_signal/pass3_global_nopileup/condor" => ("--build ana.536 --run 28"),
#    "JS_pp200_signal/pass2jet_nopileup/condor" => ("--build ana.536 --run 28"),
#    "JS_pp200_signal/pass2_nopileup/condor" => ("--build ana.536 --run 28 --disable_trk"),
#    "JS_pp200_signal/pass2_nopileup/condor" => ("--build ana.536 --run 29"),

# dual collisions
    "JS_pp200_signal/pass2_dual_nopileup/condor" => ("--build ana.541 --run 28 --disable_trk"),
    "JS_pp200_signal/pass2jet_dual_nopileup/condor" => ("--build ana.541 --run 28"),
    "JS_pp200_signal/pass3_global_dual_nopileup/condor" => ("--build ana.541 --run 28"),

#    "JS_pp200_signal/pass5_global_embed_nopileup/condor" => ("--build ana.515 --run 30"),
#    "JS_pp200_signal/pass4_jobC_embed_nopileup/condor" => ("--build ana.515 --run 30"),
#    "JS_pp200_signal/pass4_jobA_embed_nopileup/condor" => ("--build ana.515 --run 30"),
#    "JS_pp200_signal/pass4_job0_embed_nopileup/condor" => ("--build ana.515 --run 30"),
#    "JS_pp200_signal/pass3trk_embed_nopileup/condor" => ("--build ana.515 --run 30"),

#    "JS_pp200_signal/pass2_embed/condor" => (""),
#    "JS_pp200_signal/pass3calo_embed/condor" => (""),
#    "JS_pp200_signal/pass3calo_nozero_embed/condor" => ("--fm 0_488fm"),
#    "JS_pp200_signal/pass3_bbcepd_embed/condor" => (""),
#    "JS_pp200_signal/pass3trk_embed/condor" => (""),
#    "JS_pp200_signal/pass4jet_embed/condor" => (""),
#    "JS_pp200_signal/pass4_job0_embed/condor" => (""),
#    "JS_pp200_signal/pass4_jobA_embed/condor" => (""),
#    "JS_pp200_signal/pass4_jobC_embed/condor" => (""),
#    "JS_pp200_signal/pass5_global_embed/condor" => (""),
#    "JS_pp200_signal/pass5_truthreco_embed/condor" => ("")

#     "JS_pp200_signal/pass2_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass3calo_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass3_bbcepd_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass3trk_embed_pau/condor" => (""),
#    "JS_pp200_signal/pass4jet_embed_pau/condor" => (""),
#    "JS_pp200_signal/pass4_job0_embed_pau/condor" => (""),
#    "JS_pp200_signal/pass4_jobA_embed_pau/condor" => (""),
#    "JS_pp200_signal/pass4_jobC_embed_pau/condor" => (""),

    # OO without pileup
#    "OO_0_15fm/pass3_global_nopileup/condor" => ("-build ana.513 --run 33"),
    "OO_0_15fm/pass2_nopileup/condor" => ("--run 37 --build ana.541"),
#    "OO_0_15fm/pass3_job0_nopileup/condor" => ("--run 37 --build ana.541"),
#    "OO_0_15fm/pass3_jobA_nopileup/condor" => (""),
#    "OO_0_15fm/pass3_jobC_nopileup/condor" => (""),
#    "OO_0_15fm/pass4_global_nopileup/condor" => (""),
#    "OO_0_15fm/pass4_truthreco_nopileup/condor" => (""),

    # OO with pileup
#    "OO_0_15fm/pass2/condor" => ("--build ana.533 --run 34 0 --pileup 220kHz"),
#    "OO_0_15fm/pass3trk/condor" => ("--build ana.533 --run 34 0 --pileup 220kHz"),
#    "OO_0_15fm/pass3calo/condor" => ("--build ana.533 --run 34 0 --pileup 220kHz"),
#    "OO_0_15fm/pass3_mbdepd/condor" => ("--build ana.533 --run 34 0 --pileup 220kHz"),
#    "OO_0_15fm/pass4_job0/condor" => ("--build ana.533 --run 34 0 --pileup 220kHz"),
#    "OO_0_15fm/pass4_jobA/condor" => ("--build ana.533 --run 34 0 --pileup 220kHz"),
#    "OO_0_15fm/pass4_jobC/condor" => ("--build ana.533 --run 34 0 --pileup 220kHz"),
#    "OO_0_15fm/pass5_global/condor" => ("--build ana.533 --run 34 0 --pileup 220kHz"),
#    "OO_0_15fm/pass5_truthreco/condor" => ("--build ana.533 --run 34 0 --pileup 220kHz"),

#    "single_particle/pass3calo_embed/condor" => (""),
#    "single_particle/pass3trk_embed/condor" => (""),
#    "single_particle/pass4_job0_embed/condor" => (""),
#    "single_particle/pass4_jobA_embed/condor" => (""),
#    "single_particle/pass4_jobC_embed/condor" => (""),
    "last" => ("") # just so I don't have to watch removing the comma in the last entry
    );

my @cosmics = ("on", "off");
#my @quarkfilters = ("Charm", "Bottom", "JetD0");
#my @quarkfilters = ("Charm", "CharmD0piKJet5", "CharmD0piKJet12");
#my @quarkfilters = ("CharmD0piKJet5", "CharmD0piKJet12");
my @quarkfilters = ("Charm");
my @jettriggerspau = ("Jet10", "Jet20");
my @herwigtriggers = ("MB", "Jet5", "Jet20", "Jet30", "Jet40");
#my @herwigtriggers = ("MB", "Jet5", "Jet12", "Jet20", "Jet30",  "Jet40", "Jet50");
#my @jettriggers2 = ("Jet10", "Jet30", "Jet40", "PhotonJet");
#my @jettriggers2 = ("Jet10", "Jet30", "PhotonJet");
my @jettriggers = ("Jet12", "PhotonJet10");
#my @jettriggers = ("Jet5", "Jet10", "Jet12", "Jet15", "Jet20", "Jet30", "Jet40", "Jet50", "Jet60", "Detroit", "PhotonJet5", "PhotonJet10", "PhotonJet20");
#my @singleparticles = {"gamma 10000 10000"};
my @pileups = ("1000kHz");
my @runs = ("28", "30");
my @hijingruns = ("31", "32", "33");
foreach my $subdir ( keys %submitdir)
{
    if ($subdir eq "last")
    {
	next;
    }
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
    if ($newdir =~ /cosmic/)
    {
	foreach my $qf (@cosmics)
	{
	    my $submitcmd = sprintf("perl run_all.pl %d %s -inc %s",$nsubmit,$qf,$submitargs);
            condorcheck();
	    print "executing $submitcmd in $newdir\n";
	    system($submitcmd);
	}
    }
    elsif ($newdir =~ /Herwig/)
    {
	foreach my $qf (@herwigtriggers)
	{
	    my $newsubmitargs = $submitargs;
	    if ($submitargs =~ /allruns/)
	    {
		$newsubmitargs =~ s/allruns//;
		foreach my $thisrun (@runs)
		{
		    my $submitcmd = sprintf("perl run_all.pl %d %s -inc %s --run %s",$nsubmit,$qf,$newsubmitargs,$thisrun);
		    condorcheck();
		    print "executing $submitcmd in $newdir\n";
		    system($submitcmd);
		}
	    }
	    else
	    {
		my $submitcmd = sprintf("perl run_all.pl %d %s -inc %s",$nsubmit,$qf,$submitargs);
		condorcheck();
		print "executing $submitcmd in $newdir\n";
		system($submitcmd);
	    }

	}
    }
    elsif ($newdir =~ /HF_pp200_signal/)
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
	    foreach my $qf (@jettriggerspau)
	    {
		my $submitcmd = sprintf("perl run_all.pl %d %s -inc %s",$nsubmit,$qf,$submitargs);
		condorcheck();
		print "executing $submitcmd in $newdir\n";
		system($submitcmd);
	    }
	}
	else
	{
	    foreach my $qf (@jettriggers)
	    {
		my $newsubmitargs = $submitargs;
		if ($submitargs =~ /allruns/)
		{
		    $newsubmitargs =~ s/allruns//;
		    foreach my $thisrun (@runs)
		    {
			my $submitcmd = sprintf("perl run_all.pl %d %s -inc %s --run %s",$nsubmit,$qf,$newsubmitargs,$thisrun);
			condorcheck();
			print "executing $submitcmd in $newdir\n";
			system($submitcmd);
		    }
		}
		else
		{
		    if ($submitargs =~ /pileup/)
		    {
			my $newsubmitargs = $submitargs;
			$newsubmitargs =~ s/pileup//;
			foreach my $pup (@pileups)
			{
			    my $submitcmd = sprintf("perl run_all.pl %d %s -inc %s --pileup %s",$nsubmit,$qf,$newsubmitargs,$pup);
			    condorcheck();
			    print "executing $submitcmd in $newdir\n";
			    system($submitcmd);
			}
		    }
		    else
		    {
			my $submitcmd = sprintf("perl run_all.pl %d %s -inc %s",$nsubmit,$qf,$submitargs);
			condorcheck();
			print "executing $submitcmd in $newdir\n";
			system($submitcmd);
		    }
		}
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
    elsif ($newdir =~ /OO_0_15fm/)
    {
	my $submitcmd = sprintf("perl run_all.pl %d -inc %s",$nsubmit,$submitargs);
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
unlink $tagfile;
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
    return;
    my $numjobs = ncondorjobs();
    if ($numjobs >= $nsafejobs)
    {
	print "Number of condor jobs $numjobs exceeds safe limit of $nsafejobs\n";
        unlink $tagfile;
	print "all done\n";
	exit(0);
    }
}
