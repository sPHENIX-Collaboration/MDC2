#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;

my $test;
my $incremental;
my $killexist;
my $runnumber = 15;
my $events = 1000;
my $shared;
GetOptions("test"=>\$test, "increment"=>\$incremental, "killexist" => \$killexist, "shared" => \$shared);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Charm\", \"CharmD0\", \"CharmD0piKJet5\", \"CharmD0piKJet12\", \"Bottom\", \"BottomD0\", \"JetD0\" production>\n";
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
my $quarkfilter = $ARGV[1];
my $filetype="pythia8";
if ($quarkfilter  ne "Charm" &&
    $quarkfilter  ne "CharmD0" &&
    $quarkfilter  ne "CharmD0piKJet5" &&
    $quarkfilter  ne "CharmD0piKJet12" &&
    $quarkfilter  ne "Bottom" &&
    $quarkfilter  ne "BottomD0" &&
    $quarkfilter  ne "JetD0")
{
    print "second argument has to be either Charm, CharmD0, CharmD0piKJet5, CharmD0piKJet12, Bottom, BottomD0, JetD0\n";
    exit(1);
}
$filetype=sprintf("%s_%s",$filetype,$quarkfilter);

my $condorlistfile =  sprintf("condor.list");
if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

if (! -f "outdir.txt")
{
    print "could not find outdir.txt\n";
    exit(1);
}
my $outdir = `cat outdir.txt`;
chomp $outdir;
$outdir = sprintf("%s/run%04d/%s",$outdir,$runnumber,lc $quarkfilter);
mkpath($outdir);

my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log/run%d/%s",$localdir,$runnumber,$quarkfilter);
my $nsubmit = 0;
my $njob = 0;
OUTER: for (my $isub = 0; $isub < $maxsubmit; $isub++)
{
    my $jobfile = sprintf("%s/condor_%s-%010d-%06d.job",$logdir,$quarkfilter,$runnumber,$njob);
    while (-f $jobfile)
    {
	$njob++;
	$jobfile = sprintf("%s/condor_%s-%010d-%06d.job",$logdir,$quarkfilter,$runnumber,$njob);
    }
    print "using jobfile $jobfile\n";
    my $outfile = sprintf("G4Hits_%s-%010d-%06d.root",$filetype, $runnumber,$njob);
    my $fulloutfile = sprintf("%s/%s",$outdir,$outfile);
    print "out: $fulloutfile\n";
    if (defined $killexist)
    {
	if (-f $fulloutfile)
	{
	    unlink  $fulloutfile;
	}
    }
    if (! -f $fulloutfile)
    {
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	system("perl run_condor.pl $events $quarkfilter $outdir $outfile $runnumber $njob $tstflag");
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
	    last OUTER;
	}
    }
    else
    {
	print "output file already exists\n";
	$njob++;
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
