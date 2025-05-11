#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;
use File::Basename;

my $test;
my $overwrite;
my $memory = sprintf("2000MB");
GetOptions("overwrite" => \$overwrite, "test"=>\$test);
if ($#ARGV < 13)
{
    print "usage: run_condor.pl <events> <jettrigger> <infile> <calo outfile>  <calo outdir> <global outfile> <global outdir>  <trk outdir> <build> <runnumber> <sequence> <enable_calo> <enable_mbd> <enable_trk>\n";
    print "options:\n";
    print "--memory: memory requirement\n";
    print "--overwrite: overwrite existing job files\n";
    print "--test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 52;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass2_nopileup_js.sh",$rundir);
my $nevents = $ARGV[0];
my $jettrigger = $ARGV[1];
my $infile = $ARGV[2];
my $calooutfile = $ARGV[3];
my $calodstoutdir = $ARGV[4];
my $globaloutfile = $ARGV[5];
my $globaldstoutdir = $ARGV[6];
my $trkdstoutdir = $ARGV[7];
my $build = $ARGV[8];
my $runnumber = $ARGV[9];
my $sequence = $ARGV[10];
my $enable_calo = $ARGV[11];
my $enable_mbd = $ARGV[12];
my $enable_trk = $ARGV[13];
if ($sequence < 100)
{
    $baseprio = 90;
}
my $batchname = sprintf("%s %s",basename($executable),$jettrigger);
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("%s-%010d-%06d",$jettrigger,$runnumber,$sequence);
# treatment if not all of them are enabled
if ($enable_calo < 1 || $enable_mbd < 1 ||  $enable_trk< 1)
{
    my $enable_prefix = $jettrigger;
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
    $suffix = sprintf("%s-%010d-%06d",$enable_prefix,$runnumber,$sequence);
}
my $logdir = sprintf("%s/log/run%d/%s",$localdir,$runnumber,$jettrigger);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/JS_pp200_signal/pass2_nopileup/run%d/%s",$runnumber,$jettrigger);
if (! -d $condorlogdir)
{
  mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor_%s.job",$logdir,$suffix);
if (-f $jobfile)
{
    if (defined $overwrite)
    {
	print "rerunning  $jobfile\n";
    }
    else
    {
	print "jobfile $jobfile exists, possible overlapping names\n";
	exit(1);
    }
}
my $condorlogfile = sprintf("%s/condor_%s.log",$condorlogdir,$suffix);
if (-f $condorlogfile)
{
    unlink $condorlogfile;
}
my $errfile = sprintf("%s/condor_%s.err",$logdir,$suffix);
my $outfile = sprintf("%s/condor_%s.out",$logdir,$suffix);
print "job: $jobfile\n";
open(F,">$jobfile");
print F "Universe 	= vanilla\n";
print F "Executable 	= $executable\n";
print F "Arguments       = \"$nevents $infile $calooutfile $calodstoutdir $globaloutfile $globaldstoutdir $trkdstoutdir $jettrigger $build $runnumber $sequence $enable_calo $enable_mbd $enable_trk\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
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
print F "$executable, $nevents, $infile, $calooutfile, $calodstoutdir, $globaloutfile, $globaldstoutdir, $trkdstoutdir, $jettrigger, $build, $runnumber $sequence, $enable_calo, $enable_mbd, $enable_trk, $outfile, $errfile, $condorlogfile, $rundir, $baseprio, $memory, $batchname\n";
close(F);
