#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;

my $test;
my $incremental;
my $killexist;
my $shared;
my $events = 0;
GetOptions("increment"=>\$incremental, "killexist" => \$killexist, "shared" => \$shared, "test"=>\$test);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--killexist : delete output file if it already exists (but no jobfile)\n";
    print "--shared : submit jobs to shared pool\n";
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

my $condorlistfile =  sprintf("condor.list");
if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

my $nsubmit = 0;
my $njob = 0;
my $jobno = 0;
my $sequence = 0;
for (my $isub = 0; $isub < $maxsubmit; $isub++)
{
    my $indir = sprintf("/sphenix/lustre01/sphnxpro/mdc2/rawdata/stripe5");
    my $runnumber = 250 + $njob;
    $njob++;
    if ($runnumber == 265)
    {
	next;
    }
#    if ($runnumber > 10399)
    if ($runnumber > 299)
    {
	$njob=0;
	$sequence++;
        $jobno++;
    }
    if ($sequence > 18)
    {
      $sequence = 0;
    }
    my $tstflag="";
    if (defined $test)
    {
	$tstflag="--test";
    }
#    print "executing perl run_condor.pl $events $runnumber $jobno $indir $tstflag\n";
    system("perl run_condor.pl $events $runnumber $sequence $jobno $indir $tstflag");
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
    if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit >= 20000)
    {
	print "maximum number of submissions reached $nsubmit, submitting\n";
	last;
    }
}

my $jobfile = sprintf("condor.job");
if (defined $shared)
{
 $jobfile = sprintf("condor.job.shared");
}
if (! -f $jobfile)
{
    print "could not find $jobfile\n";
    exit(1);
}

if (-f $condorlistfile)
{
    if (defined $test)
    {
	print "would submit $jobfile\n";
    }
    else
    {
	system("condor_submit $jobfile");
    }
}
