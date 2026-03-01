#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;
use File::Basename;

my $memory = sprintf("1200MB");
my $overwrite;
my $test;

GetOptions("memory:s"=>\$memory, "overwrite"=>\$overwrite, "test"=>\$test);

if ($#ARGV < 9)
{
    print "usage: run_condor.pl <events> <trkr g4hit file> <trkr cluster file> <tracks file> <truth file> <outfile> <outdir> <build> <runnumber> <sequence>\n";
    print "options:\n";
    print "--memory: memory requirement\n";
    print "--overwrite : overwrite existing jobfiles\n";
    print "--test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 57;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass4_truthreco_nopileup_oo_0_15fm.sh",$rundir);
my $nevents = $ARGV[0];
my $infile0 = $ARGV[1];
my $infile1 = $ARGV[2];
my $infile2 = $ARGV[3];
my $infile3 = $ARGV[4];
my $outfilename = $ARGV[5];
my $dstoutdir = $ARGV[6];
my $build = $ARGV[7];
my $runnumber = $ARGV[8];
my $sequence = $ARGV[9];
if ($sequence < 100)
{
    $baseprio = 90;
}
my $batchname = sprintf("%s",basename($executable));
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("-%010d-%06d",$runnumber,$sequence);
my $logdir = sprintf("%s/log/run%d",$localdir,$runnumber);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/OO_0_15fm/pass4_truthreco_nopileup/run%d",$runnumber);
if (! -d $condorlogdir)
{
  mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor%s.job",$logdir,$suffix);
if (-f $jobfile && ! defined $overwrite)
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
print F "Arguments       = \"$nevents $infile0 $infile1 $infile2 $infile3 $outfilename $dstoutdir $build $runnumber $sequence\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold    = (NumJobStarts>=1 && JobStatus == 1 && !(ON_EVICT_CHECK_RequestMemory_REQUIREMENTS))\n";
print F "request_memory = $memory\n";
print F "retry_request_memory_increase = RequestMemory + 1000\n";
print F "retry_request_memory_max = 10000MB\n";
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
print F "$executable, $nevents, $infile0,  $infile1, $infile2, $infile3, $outfilename, $dstoutdir, $build, $runnumber, $sequence, $outfile, $errfile, $condorlogfile, $rundir, $baseprio, $memory, $batchname\n";
close(F);
