#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;

my $test;
my $overwrite;
GetOptions("test"=>\$test, "overwrite"=>\$overwrite);
if ($#ARGV < 3)
{
    print "usage: run_condor.pl <events> <jettrigger> <trkr g4hit file> <trkr cluster file> <tracks file> <truth file> <outfile> <outdir> <runnumber> <sequence>\n";
    print "options:\n";
    print "--overwrite : overwrite existing jobfiles\n";
    print "--test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 47;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass5_truthreco_embed_js.sh",$rundir);
my $nevents = $ARGV[0];
my $jettrigger = $ARGV[1];
my $infile0 = $ARGV[2];
my $infile1 = $ARGV[3];
my $infile2 = $ARGV[4];
my $infile3 = $ARGV[5];
my $outfilename = $ARGV[6];
my $dstoutdir = $ARGV[7];
my $runnumber = $ARGV[8];
my $sequence = $ARGV[9];
my $fm = $ARGV[10];
if ($sequence < 100)
{
    $baseprio = 90;
}
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("%s-%010d-%05d",$jettrigger,$runnumber,$sequence);
my $logdir = sprintf("%s/log/%s/run%d/%s",$localdir,$fm,$runnumber,$jettrigger);
mkpath($logdir);
my $condorlogdir = sprintf("/tmp/JS_pp200_signal/pass5_truthreco_embed/%s/run%d/%s",$fm,$runnumber,$jettrigger);
mkpath($condorlogdir);
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
print F "Arguments       = \"$nevents $infile0 $infile1 $infile2 $infile3 $outfilename $dstoutdir $runnumber $sequence $jettrigger\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
#print F "accounting_group = group_sphenix.prod\n";
print F "accounting_group = group_sphenix.mdc2\n";
print F "accounting_group_user = sphnxpro\n";
print F "Requirements = (CPU_Type == \"mdc2\")\n";
print F "request_memory = 12288MB\n";
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
print F "$executable, $nevents, $infile0,  $infile1, $infile2, $infile3, $outfilename, $dstoutdir, $runnumber, $sequence, $jettrigger, $outfile, $errfile, $condorlogfile, $rundir, $baseprio\n";
close(F);
