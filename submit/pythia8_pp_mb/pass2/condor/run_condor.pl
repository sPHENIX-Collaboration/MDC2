#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;

my $test;
GetOptions("test"=>\$test);
if ($#ARGV < 7)
{
    print "usage: run_condor.pl <inevents> <outevents> <infile> <outdir> <build> <pileup> <runnumber> <sequence>\n";
    print "options:\n";
    print "-test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 62;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pileup_pythia8_pp_mb.sh",$rundir);
my $nevents = $ARGV[0];
my $infile = $ARGV[1];
my $backgroundlist = $ARGV[2];
my $dstoutdir = $ARGV[3];
my $build = $ARGV[4];
my $pileup = $ARGV[5];
my $runnumber = $ARGV[6];
my $sequence = $ARGV[7];
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
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("%s-%010d-%06d",$pileup,$runnumber,$sequence);
my $logdir = sprintf("%s/log/run%d",$localdir,$runnumber);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/pythia8_pp_mb/pass2/run%d",$runnumber);
if (! -d $condorlogdir)
{
  mkpath($condorlogdir);
}
my $jobfile = sprintf("%s/condor_%s.job",$logdir,$suffix);
if (-f $jobfile)
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
print F "Arguments       = \"$nevents $infile $backgroundlist $dstoutdir $build $pileuprate $runnumber $sequence\"\n";
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
print F "request_memory = 2048MB\n";
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
print F "$executable, $nevents, $infile, $backgroundlist, $dstoutdir, $build, $pileuprate, $runnumber, $sequence, $outfile, $errfile, $condorlogfile, $rundir, $baseprio\n";
close(F);
