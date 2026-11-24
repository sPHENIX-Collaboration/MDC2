#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;
use File::Basename;

my $memory = sprintf("2000MB");
my $overwrite;
my $test;
GetOptions("memory:s" => \$memory, "overwrite"=>\$overwrite, "test"=>\$test);
if ($#ARGV < 8)
{
    print "usage: run_condor.pl <nevents> <infile> <bkglist> <outdir> <build> <pileup> <runnumber> <sequence>\n";
    print "options:\n";
    print "--memory: memory requirement\n";
    print "--overwrite : overwrite existing jobfiles\n";
    print "--test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 52;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass2_epos.sh",$rundir);
my $nevents = $ARGV[0];
my $infile = $ARGV[1];
my $backgroundlist = $ARGV[2];
my $dstoutdir = $ARGV[3];
my $build = $ARGV[4];
my $pileup = $ARGV[5];
my $system = $ARGV[6];
my $runnumber = $ARGV[7];
my $sequence = $ARGV[8];
if ($sequence < 100)
{
    $baseprio = 90;
}
my $pileuprate = $pileup;
if ($pileuprate =~ /kHz/)
{
    my @sp1 = split(/kHz/,$pileuprate);
    $pileuprate = $sp1[0]*1000;
}
elsif ($pileuprate =~ /MHz/)
{
    my @sp1 = split(/MHz/,$pileuprate);
    $pileuprate = $sp1[0]*1000000;
}
else
{
    print "bad pileup: $pileuprate\n";
    exit(-1);
}
my $batchname = sprintf("%s %s",basename($executable),$pileup);
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("%010d-%06d",$runnumber,$sequence);
my $logdir = sprintf("%s/log/%s/run%d/%s",$localdir,$system,$runnumber,$pileup);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/epos/pass2/%s/run%d/%s",$system,$runnumber,$pileup);
if (! -d $condorlogdir)
{
  mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor-%s.job",$logdir,$suffix);
if (-f $jobfile)
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
print F "Arguments       = \"$nevents $infile $backgroundlist $dstoutdir $build $pileuprate $pileup $system $runnumber $sequence\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1 && !(ON_EVICT_CHECK_RequestMemory_REQUIREMENTS))\n";
print F "request_memory = $memory\n";
print F "retry_request_memory_increase = RequestMemory + 2000\n";
print F "retry_request_memory_max = 10000MB\n";
print F "batch_name = \"$batchname\"\n";
print F "Priority = $baseprio\n";
#print F "concurrency_limits = PHENIX_1000\n";
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
print F "$executable, $nevents, $infile, $backgroundlist, $dstoutdir, $build, $pileuprate, $pileup, $system, $runnumber, $sequence, $outfile, $errfile, $condorlogfile, $rundir, $baseprio, $memory $batchname\n";
close(F);
