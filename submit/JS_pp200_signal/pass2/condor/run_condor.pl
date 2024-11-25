#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;
use File::Basename;

my $test;
my $memory = sprintf("8192MB");
my $overwrite;

GetOptions("memory:s" => \$memory, "overwrite"=>\$overwrite, "test"=>\$test);
if ($#ARGV < 8)
{
    print "usage: run_condor.pl <inevents> <jettrigger> <infile> <bkglist> <outdir> <build> <pileup> <runnumber> <sequence>\n";
    print "options:\n";
    print "-memory: memory requirement\n";
    print "--overwrite : overwrite existing jobfiles\n";
    print "-test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 42;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass2_js.sh",$rundir);
my $nevents = $ARGV[0];
my $jettrigger = $ARGV[1];
my $infile = $ARGV[2];
my $backgroundlist = $ARGV[3];
my $dstoutdir = $ARGV[4];
my $build = $ARGV[5];
my $pileup = $ARGV[6];
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
my $batchname = sprintf("%s %s",basename($executable),$jettrigger);
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("%s-%010d-%06d",$jettrigger,$runnumber,$sequence);
my $logdir = sprintf("%s/log/run%d/%s",$localdir,$runnumber,$jettrigger);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/JS_pp200_signal/pass2/run%d/%s",$runnumber,$jettrigger);
if (! -d $condorlogdir)
{
  mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor_%s.job",$logdir,$suffix);
if (-f $jobfile && ! defined $overwrite)
{
    print "jobfile $jobfile exists, possible overlapping names\n";
    exit(1);
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
print F "Arguments       = \"$nevents $infile $backgroundlist $dstoutdir $jettrigger $build $pileuprate $runnumber $sequence\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
#print F "accounting_group = group_sphenix.prod\n";
print F "accounting_group = group_sphenix.mdc2\n";
print F "accounting_group_user = sphnxpro\n";
print F "Requirements = (CPU_Type == \"mdc2\")\n";
#print F "Requirements = (CPU_Type == \"mdc2_minio\")\n";
print F "request_memory = $memory\n";
print F "batch_name = \"$batchname\"\n";
print F "Priority = $baseprio\n";
#print F "concurrency_limits = PHENIX_1000\n";
print F "job_lease_duration = 3600\n";
print F "Queue 1\n";
close(F);
if (defined $test)
{
    print "would submit $jobfile\n";
}
#else
#{
#    system("condor_submit $jobfile");
#}

open(F,">>$condorlistfile");
print F "$executable, $nevents, $infile, $backgroundlist, $dstoutdir, $jettrigger, $build, $pileuprate, $runnumber, $sequence, $outfile, $errfile, $condorlogfile, $rundir, $baseprio, $memory $batchname\n";
close(F);
