#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;
use File::Basename;

my $test;
my $memory = sprintf("5500MB");

GetOptions("memory:s" => \$memory, "test"=>\$test);
if ($#ARGV < 6)
{
    print "num args: $#ARGV\n";
    print "usage: run_condor.pl <events> <jettrigger> <outdir> <outfile> <build>  <runnumber> <sequence>\n";
    print "options:\n";
    print "-memory: memory requirement\n";
    print "-test: testmode - no condor submission\n";
    exit(-2);
}
else
{
    print "running condor\n";
}
my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 51;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass1_js.sh",$rundir);
my $nevents = $ARGV[0];
my $jettrigger = $ARGV[1];
my $dstoutdir = $ARGV[2];
my $dstoutfile = $ARGV[3];
my $build = $ARGV[4];
my $photonjet = $ARGV[5];
my $runnumber = $ARGV[6];
my $sequence = $ARGV[7];
if ($sequence < 100)
{
    $baseprio = 90;
}
my $batchname = sprintf("%s %s",basename($executable),$jettrigger);
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("%010d-%06d",$runnumber,$sequence);
my $logdir = sprintf("%s/log/run%d/%s",$localdir,$runnumber,$jettrigger);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/JS_pp200_signal/pass1/run%d/%s",$runnumber,$jettrigger);
if (! -d $condorlogdir)
{
  mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor_%s-%s.job",$logdir,$jettrigger,$suffix);
if (-f $jobfile)
{
    print "jobfile $jobfile exists, possible overlapping names\n";
    exit(1);
}
my $condorlogfile = sprintf("%s/condor_%s-%s.log",$condorlogdir,$jettrigger,$suffix);
if (-f $condorlogfile)
{
    unlink $condorlogfile;
}
my $errfile = sprintf("%s/condor_%s-%s.err",$logdir,$jettrigger,$suffix);
my $outfile = sprintf("%s/condor_%s-%s.out",$logdir,$jettrigger,$suffix);
print "job: $jobfile\n";
open(F,">$jobfile");
print F "Universe 	= vanilla\n";
print F "Executable 	= $executable\n";
print F "Arguments       = \"$nevents $jettrigger $dstoutfile $dstoutdir $build $photonjet $runnumber $sequence\"\n";
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
print F "Priority = $baseprio\n";
print F "batch_name = \"$batchname\"\n";
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
print F "$executable, $nevents, $jettrigger, $dstoutfile, $dstoutdir, $build, $photonjet, $runnumber, $sequence, $outfile, $errfile, $condorlogfile, $rundir, $baseprio, $memory, $batchname\n";
close(F);
