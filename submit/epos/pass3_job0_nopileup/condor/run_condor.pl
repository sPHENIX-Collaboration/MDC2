#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;

my $test;
my $memory = sprintf("4000MB");
GetOptions("memory:s"=>\$memory,"test"=>\$test);
if ($#ARGV < 6)
{
    print "usage: run_condor.pl <events> <trk clusters> <outfile> <outdir> <build> <runnumber> <sequence>\n";
    print "options:\n";
    print "--memory: memory requirement\n";
    print "--test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 53;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass3_job0_nopileup_epos.sh",$rundir);
my $nevents = $ARGV[0];
my $infile = $ARGV[1];
my $dstoutfile = $ARGV[2];
my $dstoutdir = $ARGV[3];
my $build = $ARGV[4];
my $runnumber = $ARGV[5];
my $sequence = $ARGV[6];
if ($sequence < 100)
{
    $baseprio = 90;
}
my $batchname = sprintf("%s run %d",basename($executable),$runnumber);
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("-%010d-%06d",$runnumber,$sequence);
my $logdir = sprintf("%s/log/run%d",$localdir,$runnumber);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $condorlogdir = sprintf("/tmp/epos/pass3_job0_nopileup/run%d",$runnumber);
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
print F "Arguments       = \"$nevents $infile $dstoutfile $dstoutdir $build $runnumber $sequence\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
print F "accounting_group = group_sphenix.mdc2\n";
print F "accounting_group_user = sphnxpro\n";
print F "Requirements = (CPU_Type == \"mdc2\")\n";
#print F "Requirements = (CPU_Type == \"mdc2\")&& (TARGET.Machine != \"spool1011.sdcc.bnl.gov\")\n";
#print F "Requirements = (CPU_Type == \"mdc2\")\n";
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
print F "$executable, $nevents, $infile, $dstoutfile, $dstoutdir, $build, $runnumber, $sequence, $outfile, $errfile, $condorlogfile, $rundir, $baseprio, $memory, $batchname\n";
close(F);
