#!/usr/bin/perl

use strict;
use warnings;

sub dir_is_empty;

my $submitdir = "/sphenix/u/sphnxpro/MDC2/submit";
my %condorlogs = ();
my @fmrange = ();
push(@fmrange,"ampt");
push(@fmrange,"epos");
push(@fmrange,"cosmic");
push(@fmrange,"fm_0_488");
push(@fmrange,"fm_0_20");
push(@fmrange,"HF_pp200_signal");
push(@fmrange,"JS_pp200_signal");
push(@fmrange,"pAu_0_10fm");
push(@fmrange,"pythia8_pp_mb");
push(@fmrange,"rawdata");
push(@fmrange,"single_particle/geantino");

my @passes = ();
push(@passes,"caloreco");
push(@passes,"cemc_geo_fix/cemc_hits");
push(@passes,"cemc_geo_fix/cemc_hits_pass2");
push(@passes,"cemc_geo_fix/cemc_hits_pass3trk");
push(@passes,"eventcombine");
push(@passes,"job0");
push(@passes,"pass1");
push(@passes,"pass2");
push(@passes,"pass2_1MHz");
push(@passes,"pass2_10kHz");
push(@passes,"pass2_25kHz");
push(@passes,"pass2_50kHz_0_20fm");
push(@passes,"pass2_embed");
push(@passes,"pass2_embed_pau");
push(@passes,"pass2_pi0_embed");
push(@passes,"pass2_nopileup");
push(@passes,"pass2calo_nopileup_nozero");
push(@passes,"pass3_nopileup");
push(@passes,"pass3_bbcepd");
push(@passes,"pass3_bbcepd_embed");
push(@passes,"pass3calo");
push(@passes,"pass3calo_waveform_nopileup");
push(@passes,"pass3calo_50kHz_0_20fm");
push(@passes,"pass3calo_embed");
push(@passes,"pass3calo_embed_pau");
push(@passes,"pass3distort");
push(@passes,"pass3global");
push(@passes,"pass3global_embed");
push(@passes,"pass3global_embed_pau");
push(@passes,"pass3jet_nopileup");
push(@passes,"pass3_job0_nopileup");
push(@passes,"pass3_jobA_nopileup");
push(@passes,"pass3_jobC_nopileup");
push(@passes,"pass3trk");
push(@passes,"pass3trk_test");
push(@passes,"pass3trk_embed");
push(@passes,"pass3trk_embed_pau");
push(@passes,"pass3trk_1MHz");
push(@passes,"pass3trk_10kHz");
push(@passes,"pass3trk_25kHz");
push(@passes,"pass3trk_50kHz_0_20fm");
push(@passes,"pass4_global_nopileup");
push(@passes,"pass4_job0");
push(@passes,"pass4_jobA");
push(@passes,"pass4_job0_embed");
push(@passes,"pass4_job0_embed_pau");
push(@passes,"pass4_jobA_embed");
push(@passes,"pass4_jobA_embed_pau");
push(@passes,"pass4_jobC_embed");
push(@passes,"pass4_jobC_embed_pau");
push(@passes,"pass4_jobC");
push(@passes,"pass4jet");
push(@passes,"pass4jet_embed");
push(@passes,"pass4jet_embed_pau");
push(@passes,"pass4jet_nopileup");
push(@passes,"pass4trk");
push(@passes,"pass4trk_10kHz");
push(@passes,"pass4trk_25kHz");
push(@passes,"pass4trk_50kHz_0_20fm");
push(@passes,"pass4trk_embed");
push(@passes,"pass4_truthreco_nopileup");
push(@passes,"pass5_global");
push(@passes,"pass5_global_embed");
push(@passes,"pass5_truthreco");
push(@passes,"pass5_truthreco_embed");
push(@passes,"newtracking");
push(@passes,"pass5compress");
push(@passes,"pass5trk");
push(@passes,"striptruth");

foreach my $fm (sort @fmrange)
{
    foreach my $pass (sort @passes)
    {
	$condorlogs{sprintf("/tmp/%s/%s",$fm,$pass)} = sprintf("%s/%s/%s/condor/log",$submitdir,$fm,$pass);
    }
}

foreach my $condorlogdir (sort keys %condorlogs)
{
    print "checking $condorlogdir and $condorlogs{$condorlogdir}\n";
    if (-d $condorlogdir && -d $condorlogs{$condorlogdir})
    {
	if (&dir_is_empty($condorlogdir) == 1)
	{
	    my $rsynccmd = sprintf("rsync -av %s/ %s",$condorlogdir, $condorlogs{$condorlogdir});
	    print "cmd: $rsynccmd\n";
	    system($rsynccmd);
	}
	else
	{
	    print "$condorlogdir is empty\n";
	}
    }
}
print "all done\n";

sub dir_is_empty
{
    my $dirname = $_[0];
    my $iret = 0;
    opendir my $dir, $dirname or die $!;
    if( grep ! /^\.\.?$/, readdir $dir )
    {
	$iret = 1;
    }
    closedir($dir);
    return $iret;
}
