#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;
use File::Basename;

my $memory = sprintf("12200MB");
my $overwrite;
my $test;
GetOptions("memory:s"=>\$memory, "test"=>\$test, "overwrite"=> \$overwrite);
if ($#ARGV < 8)
{
    print "usage: run_condor.pl <events> <jettrigger> <trk infile> <truth infile> <outdir> <build> <runnumber> <sequence> <fm range>\n";
    print "options:\n";
    print "--memory: memory requirement\n";
    print "--overwrite : overwrite exiting jobfiles\n";
    print "-test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 54;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass3trk_embed_nopileup_js.sh",$rundir);
my $nevents = $ARGV[0];
my $jettrigger = $ARGV[1];
my $infile0 = $ARGV[2];
my $infile1 = $ARGV[3];
my $dstoutdir = $ARGV[4];
my $build = $ARGV[5];
my $runnumber = $ARGV[6];
my $sequence = $ARGV[7];
my $fm = $ARGV[8];
if ($sequence < 100)
{
    $baseprio = 90;
}
my $batchname = sprintf("%s %s",basename($executable),$jettrigger);
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("%s-%010d-%06d",$jettrigger,$runnumber,$sequence);
my $logdir = sprintf("%s/log/%s/run%d/%s",$localdir,$fm,$runnumber,$jettrigger);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/JS_pp200_signal/pass3trk_embed/%s/run%d/%s",$fm,$runnumber,$jettrigger);
if (! -d $condorlogdir)
{
  mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor_%s.job",$logdir,$suffix);
if (-f $jobfile)
{
    if (defined $overwrite)
    {
	print "jobfile $jobfile exists, overwriting it\n";
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
print F "Arguments       = \"$nevents $infile0 $infile1 $dstoutdir $jettrigger $build $runnumber $sequence $fm\"\n";
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
print F "$executable, $nevents, $infile0, $infile1, $dstoutdir, $jettrigger, $build, $runnumber, $sequence, $fm, $outfile, $errfile, $condorlogfile, $rundir, $baseprio, $memory, $batchname\n";
close(F);
