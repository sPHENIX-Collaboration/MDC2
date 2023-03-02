#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;

my $test;
my $incremental;
my $killexist;
my $events = 0;
GetOptions("test"=>\$test, "increment"=>\$incremental, "killexist" => \$killexist);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--killexist : delete output file if it already exists (but no jobfile)\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxsub/)
{
    print "submit only from phnxsub01 or phnxsub02\n";
    exit(1);
}

my $maxsubmit = $ARGV[0];
my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log",$localdir);
my $nsubmit = 0;
my $njob = 0;
my $jobno = 0;
for (my $isub = 0; $isub < $maxsubmit; $isub++)
{
    my $indir = sprintf("/sphenix/lustre01/sphnxpro/mdc2/rawdata");
    my $sequence = 0;
    my $runnumber = 10000 + $njob;
    $njob++;
    if ($runnumber > 10399)
    {
	$njob=0;
    }
    my $jobfile = sprintf("%s/condor-%010d-%05d.job",$logdir,$runnumber,$jobno);
    while (-f $jobfile)
    {
	$jobno++;
	$jobfile = sprintf("%s/condor-%010d-%05d.job",$logdir,$runnumber,$jobno);
    }
    print "using jobfile $jobfile\n";
    my $tstflag="";
    if (defined $test)
    {
	$tstflag="--test";
    }
#    print "executing perl run_condor.pl $events $runnumber $jobno $indir $tstflag\n";
    system("perl run_condor.pl $events $runnumber $jobno $indir $tstflag");
    my $exit_value  = $? >> 8;
    if ($exit_value != 0)
    {
	if (! defined $incremental)
	{
	    print "error from run_condor.pl\n";
	    exit($exit_value);
	}
    }
    else
    {
	$nsubmit++;
    }
    if ($nsubmit >= $maxsubmit)
    {
	print "maximum number of submissions reached, exiting\n";
	exit(0);
    }
}
