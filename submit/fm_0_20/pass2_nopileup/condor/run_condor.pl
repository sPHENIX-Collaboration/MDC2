#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;
use File::Basename;

my $test;
my $memory = sprintf("10000MB");
GetOptions("test"=>\$test);
if ($#ARGV < 12)
{
    print "usage: run_condor.pl <events> <infile> <calo outfile>  <calo outdir> <global outfile> <global outdir> <trk outdir> <build> <runnumber> <sequence> <enable_calo> <enable_mbd> <enable_trk>\n";
    print "options:\n";
    print "-memory: memory requirement\n";
    print "-test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 52;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass2_nopileup_fm_0_20.sh",$rundir);
my $nevents = $ARGV[0];
my $infile = $ARGV[1];
my $calooutfile = $ARGV[2];
my $calodstoutdir = $ARGV[3];
my $globaloutfile = $ARGV[4];
my $globaldstoutdir = $ARGV[5];
my $trkdstoutdir = $ARGV[6];
my $build = $ARGV[7];
my $runnumber = $ARGV[8];
my $sequence = $ARGV[9];
my $enable_calo = $ARGV[10];
my $enable_mbd = $ARGV[11];
my $enable_trk = $ARGV[12];
if ($sequence < 100)
{
    $baseprio = 90;
}
my $batchname = sprintf("%s",basename($executable));
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("-%010d-%06d",$runnumber,$sequence);
# treatment if not all of them are enabled
if ($enable_calo < 1 || $enable_mbd < 1 ||  $enable_trk< 1)
{
    my $enable_prefix = "";
    if ($enable_calo == 1)
    {
	$enable_prefix = sprintf("%s_calo", $enable_prefix);
    }
    if ($enable_mbd == 1)
    {
	$enable_prefix = sprintf("%s_mbd", $enable_prefix);
    }
    if ($enable_trk == 1)
    {
	$enable_prefix = sprintf("%s_trk", $enable_prefix);
    }
    $suffix = sprintf("_%s-%010d-%06d",$enable_prefix,$runnumber,$sequence);
}
my $logdir = sprintf("%s/log/run%d",$localdir,$runnumber);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/fm_0_20/pass2_nopileup/run%d",$runnumber);
if (! -d $condorlogdir)
{
  mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor%s.job",$logdir,$suffix);
if (-f $jobfile)
{
    print "jobfile $jobfile exists, possible overlapping names\n";
    exit(1);
}
my $condorlogfile = sprintf("%s/condor%s.log",$condorlogdir,$suffix);
if (-f $condorlogfile)
{
    unlink $condorlogfile;
}
my $errfile = sprintf("%s/condor%s.err",$logdir,$suffix);
my $outfile = sprintf("%s/condor%s.out",$logdir,$suffix);
print "job: $jobfile\n";
open(F,">$jobfile");
print F "Universe 	= vanilla\n";
print F "Executable 	= $executable\n";
print F "Arguments       = \"$nevents $infile $calooutfile $calodstoutdir $globaloutfile $globaldstoutdir $trkdstoutdir $build $runnumber $sequence $enable_calo $enable_mbd $enable_trk\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
#print F "accounting_group = group_sphenix.prod\n";
print F "accounting_group = group_sphenix.mdc2\n";
print F "accounting_group_user = sphnxpro\n";
print F "Requirements = (CPU_Type == \"mdc2\")\n";
print F "request_memory = $memory\n";
print F "batch_name = \"$batchname\"\n";
print F "Priority = $baseprio\n";
print F "job_lease_duration = 3600\n";
print F "Queue 1\n";
close(F);
#if (defined $test)
#{
#    print "would submit $jobfile\n";
#}
#else
#{
#    system("condor_submit $jobfile");
#}

open(F,">>$condorlistfile");
print F "$executable, $nevents, $infile, $calooutfile $calodstoutdir $globaloutfile $globaldstoutdir $trkdstoutdir, $build, $runnumber, $sequence, $enable_calo, $enable_mbd, $enable_trk, $outfile, $errfile, $condorlogfile, $rundir, $baseprio, $memory, $batchname\n";
close(F);
