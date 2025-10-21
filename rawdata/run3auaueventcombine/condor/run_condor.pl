#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;
use File::Basename;


my $test;
my $overwrite;
GetOptions("overwrite" => \$overwrite, "test"=>\$test);
if ($#ARGV < 3)
{
    print "usage: run_condor.pl <events> <runnumber> <daqhost> <outdir>\n";
    print "options:\n";
    print "--overwrite: overwrite existing job files\n";
    print "--test: testmode - no condor submission\n";
    exit(-2);
}
else
{
    print "running condor\n";
}
my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 91;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run3auau_eventcombine.sh",$rundir);
my $nevents = $ARGV[0];
my $runnumber = $ARGV[1];
my $daqhost = $ARGV[2];
my $outdir = $ARGV[3];
my $batchname = sprintf("%s",basename($executable));
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("%s_%010d",$daqhost,$runnumber);
my $logdir = sprintf("%s/log",$localdir);
if (! -d $logdir)
{
    mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/rawdata/run3auaueventcombine");
if (! -d $condorlogdir)
{
    mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor-%s.job",$logdir,$suffix);
if (-f $jobfile && !defined $overwrite)
{
    print "jobfile $jobfile exists, possible overlapping names\n";
    exit(1);
}
my $condorlogfile = sprintf("%s/condor-%s.log",$condorlogdir,$suffix);
if (-f $condorlogfile)
{
    unlink $condorlogfile;
}
my $errfile = sprintf("%s/condor-%s.err",$logdir,$suffix);
my $outfile = sprintf("%s/condor-%s.out",$logdir,$suffix);
print "job: $jobfile\n";
open(F,">$jobfile");
print F "Universe 	= vanilla\n";
print F "Executable 	= $executable\n";
print F "Arguments       = \"$nevents $runnumber $daqhost $outdir\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
print F "request_memory = 2048MB\n";
print F "Priority = $baseprio\n";
print F "Rank = -SlotID\n";
print F "batch_name = \"$batchname\"\n";
print F "request_xferslots = 1\n";
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
print F "$executable, $nevents, $runnumber, $daqhost, $outdir, $errfile, $outfile, $condorlogfile, $rundir, $baseprio, $batchname\n";
close(F);
