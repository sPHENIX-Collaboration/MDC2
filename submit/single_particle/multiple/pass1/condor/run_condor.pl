#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;

my $test;
GetOptions("test"=>\$test);
if ($#ARGV < 8)
{
    print "usage: run_condor.pl <events> <particle> <pmin> <pmax> <nparticles> <outdir> <outfile> <skip> <runnumber> <sequence>\n";
    print "options:\n";
    print "-test: testmode - no condor submission\n";
    exit(-2);
}
else
{
    print "running condor\n";
}
my $localdir=`pwd`;
chomp $localdir;
my $baseprio = 80;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_pass1_multiple.sh",$rundir);
my $nevents = $ARGV[0];
my $particle = $ARGV[1];
my $pmin = $ARGV[2];
my $pmax = $ARGV[3];
my $nparticles = $ARGV[4];
my $dstoutdir = $ARGV[5];
my $dstoutfile = $ARGV[6];
my $runnumber = $ARGV[7];
my $sequence = $ARGV[8];

if ($sequence < 100)
{
    $baseprio = 90;
}
my $condorlistfile = sprintf("condor.list");
my $suffix = sprintf("%010d-%05d",$runnumber,$sequence);
my $logdir = sprintf("%s/log",$localdir);
mkpath($logdir);
my $condorlogdir = sprintf("/tmp/single_particle/multiple/pass1");
mkpath($condorlogdir);
my $partprop = sprintf("%s_%d_%d",$particle,$pmin,$pmax);
my $jobfile = sprintf("%s/condor_%s-%s.job",$logdir,$partprop,$suffix);
if (-f $jobfile)
{
    print "jobfile $jobfile exists, possible overlapping names\n";
    exit(1);
}
my $condorlogfile = sprintf("%s/condor_%s-%s.log",$condorlogdir,$partprop,$suffix);
if (-f $condorlogfile)
{
    unlink $condorlogfile;
}
my $errfile = sprintf("%s/condor_%s-%s.err",$logdir,$partprop,$suffix);
my $outfile = sprintf("%s/condor_%s-%s.out",$logdir,$partprop,$suffix);
print "job: $jobfile\n";
open(F,">$jobfile");
print F "Universe 	= vanilla\n";
print F "Executable 	= $executable\n";
print F "Arguments       = \"$nevents $particle $pmin $pmax $nparticles $dstoutfile $dstoutdir $runnumber $sequence\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
#print F "accounting_group = group_sphenix.prod\n";
print F "accounting_group = group_sphenix.mdc2\n";
print F "accounting_group_user = sphnxpro\n";
print F "Requirements = (CPU_Type == \"mdc2\")\n";
print F "request_memory = 4096MB\n";
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
print F "$executable, $nevents, $particle, $pmin, $pmax, $nparticles, $dstoutfile, $dstoutdir, $runnumber, $sequence, $outfile, $errfile, $condorlogfile, $rundir, $baseprio\n";
close(F);
