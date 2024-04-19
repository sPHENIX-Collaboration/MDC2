#!/usr/bin/perl

use strict;
use warnings;
use Cwd;

sub ncondorjobs;
sub condorcheck;

my $submittopdir = "/sphenix/u/sphnxpro/MDC2/submit";

my $tagfile = sprintf("%s/autopilot_phnxsub03.run",$submittopdir);
if (-f $tagfile)
{
    exit 0;
}
my $tagfiletouch = sprintf("touch %s",$tagfile);
system($tagfiletouch);
my $nsubmit = 10000;
my $nsafejobs = 41000;

my %submitdir = (
     "cosmic/pass2_nopileup/condor" => ("on"),
     "cosmic/pass2calo_nopileup_nozero/condor" => ("on"),
     "cosmic/pass3calo_waveform_nopileup/condor" => ("on"),

#    "fm_0_20/pass2/condor" => (""),
#    "fm_0_20/pass3trk/condor" => (""),
#    "fm_0_20/pass3calo/condor" => (""),
#    "fm_0_20/pass3_mbdepd/condor" => (""),
#    "fm_0_20/pass4_job0/condor" => (""),
#    "fm_0_20/pass4_jobA/condor" => (""),
#    "fm_0_20/pass4_jobC/condor" => (""),
#    "fm_0_20/pass5_global/condor" => (""),
#    "fm_0_20/pass5_truthreco/condor" => (""),

#    "fm_0_20/pass2_nopileup/condor" => (""),
#    "fm_0_20/pass2calo_nopileup_nozero/condor" => (""),
#    "fm_0_20/pass3_job0_nopileup/condor" => (""),
#    "fm_0_20/pass3_jobA_nopileup/condor" => (""),
#    "fm_0_20/pass3_jobC_nopileup/condor" => (""),
#    "fm_0_20/pass4_global_nopileup/condor" => (""),
#    "fm_0_20/pass4_truthreco_nopileup/condor" => (""),

#     "fm_0_488/pass2/condor" => (""),
#     "fm_0_488/pass3trk/condor" => (""),
#     "fm_0_488/pass3calo/condor" => (""),
#     "fm_0_488/pass3_mbdepd/condor" => (""),
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
#    "pAu_0_10fm/pass3_bbcepd/condor" => (""),
#    "pAu_0_10fm/pass3trk/condor" => (""),
#    "pAu_0_10fm/pass3calo/condor" => (""),
#    "pAu_0_10fm/pass4_job0/condor" => (""),
#    "pAu_0_10fm/pass4_jobA/condor" => (""),
#    "pAu_0_10fm/pass4_jobC/condor" => (""),
#    "pAu_0_10fm/pass5_global/condor" => (""),
#    "pAu_0_10fm/pass5_truthreco/condor" => (""),

#    "pAu_0_10fm/pass2_nopileup/condor" => (""),
#    "pAu_0_10fm/pass3_job0_nopileup/condor" => (""),
#    "pAu_0_10fm/pass3_jobA_nopileup/condor" => (""),
#    "pAu_0_10fm/pass3_jobC_nopileup/condor" => (""),
#    "pAu_0_10fm/pass4_global_nopileup/condor" => (""),
#    "pAu_0_10fm/pass4_truthreco_nopileup/condor" => (""),

#    "ampt/pass2_nopileup/condor" => (""),
#    "ampt/pass2calo_nopileup_nozero/condor" => (""),
#    "ampt/pass3_job0_nopileup/condor" => (""),
#    "ampt/pass3_jobA_nopileup/condor" => (""),
#    "ampt/pass3_jobC_nopileup/condor" => (""),
#    "ampt/pass4_global_nopileup/condor" => (""),
#    "ampt/pass4_truthreco_nopileup/condor" => (""),

#    "ampt/pass2/condor" => (""),
#    "ampt/pass3trk/condor" => (""),
#    "ampt/pass3calo/condor" => (""),
#    "ampt/pass3_mbdepd/condor" => (""),
#    "ampt/pass4_job0/condor" => (""),
#    "ampt/pass4_jobA/condor" => (""),
#    "ampt/pass4_jobC/condor" => (""),
#    "ampt/pass5_global/condor" => (""),
#    "ampt/pass5_truthreco/condor" => (""),

#    "epos/pass2_nopileup/condor" => (""),
#    "epos/pass2calo_nopileup_nozero/condor" => (""),
#    "epos/pass3_job0_nopileup/condor" => (""),
#    "epos/pass3_jobA_nopileup/condor" => (""),
#    "epos/pass3_jobC_nopileup/condor" => (""),
#    "epos/pass4_global_nopileup/condor" => (""),
#    "epos/pass4_truthreco_nopileup/condor" => (""),

#    "epos/pass2/condor" => (""),
#    "epos/pass3trk/condor" => (""),
#    "epos/pass3calo/condor" => (""),
#    "epos/pass3_mbdepd/condor" => (""),
#    "epos/pass4_job0/condor" => (""),
#    "epos/pass4_jobA/condor" => (""),
#    "epos/pass4_jobC/condor" => (""),
#    "epos/pass5_global/condor" => (""),
#    "epos/pass5_truthreco/condor" => (""),

#    "pythia8_pp_mb/pass2/condor" => (""),
#    "pythia8_pp_mb/pass3trk/condor" => (""),
#    "pythia8_pp_mb/pass3calo/condor" => (""),
#    "pythia8_pp_mb/pass3_mbdepd/condor" => (""),
#    "pythia8_pp_mb/pass4jet/condor" => (""),
#    "pythia8_pp_mb/pass4_job0/condor" => (""),
#    "pythia8_pp_mb/pass4_jobA/condor" => (""),
#    "pythia8_pp_mb/pass4_jobC/condor" => (""),
#    "pythia8_pp_mb/pass5_global/condor" => (""),
#    "pythia8_pp_mb/pass5_truthreco/condor" => (""),

#    "pythia8_pp_mb/pass2_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass3_job0_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass3_jobA_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass3_jobC_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass3jet_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass4_global_nopileup/condor" => (""),
#    "pythia8_pp_mb/pass4_truthreco_nopileup/condor" => (""),

#    "HF_pp200_signal/pass2/condor" => (""),
#    "HF_pp200_signal/pass3_mbdepd/condor" => (""),
#    "HF_pp200_signal/pass3calo/condor" => (""),
#    "HF_pp200_signal/pass3trk/condor" => (""),
#    "HF_pp200_signal/pass4_job0/condor" => (""),
#    "HF_pp200_signal/pass4_jobA/condor" => (""),
#    "HF_pp200_signal/pass4_jobC/condor" => (""),
#    "HF_pp200_signal/pass5_global/condor" => (""),
#    "HF_pp200_signal/pass5_truthreco/condor" => (""),

#    "HF_pp200_signal/pass2_nopileup/condor" => (""),
#    "HF_pp200_signal/pass3_job0_nopileup/condor" => (""),
#    "HF_pp200_signal/pass3_jobA_nopileup/condor" => (""),
#    "HF_pp200_signal/pass3_jobC_nopileup/condor" => (""),
#    "HF_pp200_signal/pass4_global_nopileup/condor" => (""),
#    "HF_pp200_signal/pass4_truthreco_nopileup/condor" => (""),

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


#    "JS_pp200_signal/cemc_geo_fix/cemc_hits_pass2/condor" => (""),
#    "JS_pp200_signal/cemc_geo_fix/cemc_hits_pass3trk/condor" => (""),
#    "JS_pp200_signal/pass2/condor" => (""),
#    "JS_pp200_signal/pass3calo/condor" => (""),
#    "JS_pp200_signal/pass3trk/condor" => (""),
#    "JS_pp200_signal/pass3_mbdepd/condor" => (""),
#    "JS_pp200_signal/pass4jet/condor" => (""),
#    "JS_pp200_signal/pass4_job0/condor" => (""),
#    "JS_pp200_signal/pass4_jobA/condor" => (""),
#    "JS_pp200_signal/pass4_jobC/condor" => (""),
#    "JS_pp200_signal/pass5_global/condor" => (""),
#    "JS_pp200_signal/pass5_truthreco/condor" => (""),


#    "JS_pp200_signal/pass2_nopileup/condor" => (""),
#    "JS_pp200_signal/pass3jet_nopileup/condor" => (""),
#    "JS_pp200_signal/pass3_job0_nopileup/condor" => (""),
#    "JS_pp200_signal/pass3_jobA_nopileup/condor" => (""),
#    "JS_pp200_signal/pass3_jobC_nopileup/condor" => (""),
#    "JS_pp200_signal/pass4_global_nopileup/condor" => (""),
#    "JS_pp200_signal/pass4_truthreco_nopileup/condor" => (""),


 #   "JS_pp200_signal/pass2_embed/condor" => (""),
#    "JS_pp200_signal/pass3calo_embed/condor" => (""),
#    "JS_pp200_signal/pass3_mbdepd_embed/condor" => (""),
#    "JS_pp200_signal/pass3trk_embed/condor" => (""),
#    "JS_pp200_signal/pass3calo_nozero_embed/condor" => (""),
#    "JS_pp200_signal/pass4jet_embed/condor" => (""),
#    "JS_pp200_signal/pass4_job0_embed/condor" => (""),
#    "JS_pp200_signal/pass4_jobA_embed/condor" => (""),
#    "JS_pp200_signal/pass4_jobC_embed/condor" => (""),
#    "JS_pp200_signal/pass5_global_embed/condor" => (""),
#    "JS_pp200_signal/pass5_truthreco_embed/condor" => (""),

# either run the above (_embed without flag) or this, 
# they run from the same directory and will wipe out each others lists
 #   "JS_pp200_signal/pass2_embed/condor" => ("--fm 0_488fm"),
 #   "JS_pp200_signal/pass3calo_embed/condor" => ("--fm 0_488fm"),
 #   "JS_pp200_signal/pass3_mbdepd_embed/condor" => ("--fm 0_488fm"),
 #   "JS_pp200_signal/pass3trk_embed/condor" => ("--fm 0_488fm"),
 #   "JS_pp200_signal/pass3calo_nozero_embed/condor" => ("--fm 0_488fm"),
 #   "JS_pp200_signal/pass4jet_embed/condor" => ("--fm 0_488fm"),
 #   "JS_pp200_signal/pass4_job0_embed/condor" => ("--fm 0_488fm"),
 #   "JS_pp200_signal/pass4_jobA_embed/condor" => ("--fm 0_488fm"),
 #   "JS_pp200_signal/pass4_jobC_embed/condor" => ("--fm 0_488fm"),
 #   "JS_pp200_signal/pass5_global_embed/condor" => ("--fm 0_488fm"),
 #   "JS_pp200_signal/pass5_truthreco_embed/condor" => ("--fm 0_488fm"),

#     "JS_pp200_signal/pass2_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass3calo_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass3_bbcepd_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass3trk_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass4jet_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass4_job0_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass4_jobA_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass4_jobC_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass5_global_embed_pau/condor" => (""),
#     "JS_pp200_signal/pass5_truthreco_embed_pau/condor" => (""),

#    "single_particle/pass3calo_embed/condor" => (""),
#    "single_particle/pass3trk_embed/condor" => (""),
#    "single_particle/pass4_job0_embed/condor" => (""),
#    "single_particle/pass4_jobA_embed/condor" => (""),
#    "single_particle/pass4_jobC_embed/condor" => (""),
    "last" => ("") # just so I don't have to watch removing the comma in the last entry
    );

#my @quarkfilters = ("Charm", "Bottom", "JetD0");
#my @quarkfilters = ("Charm", "CharmD0piKJet5", "CharmD0piKJet12");
#my @quarkfilters = ("CharmD0piKJet5", "CharmD0piKJet12");
my @quarkfilters = ("Charm");
my @jettriggers_pau = ("Jet10", "Jet20");
#my @jettriggers2 = ("Jet10", "Jet30", "Jet40", "PhotonJet");
#my @jettriggers2 = ("Jet10");
my @jettriggers2 = ("Jet10", "Jet30");
#my @jettriggers = ("Jet10", "Jet30");
#my @singleparticles = {"gamma 10000 10000"};

foreach my $subdir ( sort keys %submitdir)
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
	    foreach my $qf (@jettriggers_pau)
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
unlink $tagfile;
print "all done\n";

sub ncondorjobs()
{
    my $njobads = `condor_status -schedd -statistics schedd -l -direct \`hostname\` | egrep -i '^TotalJob(Ads)'`;
    if (! defined $njobads)
    {
	return $nsafejobs;
    }
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
        unlink $tagfile;
	print "all done\n";
	exit(0);
    }
}
