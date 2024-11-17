#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;

my $test;
my $build;
my $incremental;
my $killexist;
my $memory;
my $runnumber;
my $events = 1000;
my $mom;
GetOptions("build:s" => \$build, "increment"=>\$incremental, "killexist" => \$killexist, "memory:s"=>\$memory, "mom:s" => \$mom, "run:i" =>\$runnumber, "test"=>\$test);
if ($#ARGV < 3)
{
    print "usage: run_all.pl <number of jobs> <particle> <pmin> <pmax> <--mom>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--increment : submit jobs while processing running\n";
    print "--killexist : delete output file if it already exists (but no jobfile)\n";
    print "--mom <p or pt> : use p or pt for momentum\n";
    print "--run: <runnumber>\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}
my $isbad = 0;

if (! defined $mom || ($mom ne "pt" and $mom ne "p"))
{
    print "need to give p or pt for -mom\n";
    $isbad = 1;
}

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxsub/)
{
    print "submit only from phnxsub hosts\n";
    $isbad = 1;
}

if (! defined $runnumber)
{
    print "need runnumber with --run <runnumber>\n";
    $isbad = 1;
}

if (! defined $build)
{
    print "need build with --build <ana build>\n";
    $isbad = 1;
}
if (! -f "outdir.txt")
{
    print "could not find outdir.txt\n";
    $isbad = 1;
}

if ($isbad > 0)
{
    exit(1);
}


my $maxsubmit = $ARGV[0];
my $particle = lc $ARGV[1];
my $pmin = $ARGV[2];
my $pmax = $ARGV[3];
my $filetype="single";
my $partprop = sprintf("%s_%s_%d_%d",$particle,$mom,$pmin,$pmax);
$filetype=sprintf("%s_%sMeV",$filetype,$partprop);

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
$outdir = sprintf("%s/run%04d/%s",$outdir,$runnumber,$partprop);
if (! -d $outdir)
{
  mkpath($outdir);
}

my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log/run%d/%s",$localdir,$runnumber,$particle);
my $nsubmit = 0;
my $njob = 0;
for (my $isub = 0; $isub < $maxsubmit; $isub++)
{
    my $jobfile = sprintf("%s/condor_%s-%010d-%06d.job",$logdir,$partprop,$runnumber,$njob);
    while (-f $jobfile)
    {
	$njob++;
	$jobfile = sprintf("%s/condor_%s-%010d-%06d.job",$logdir,$partprop,$runnumber,$njob);
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
	if (defined $memory)
	{
	    $tstflag = sprintf("%s --memory %s",$tstflag, $memory)
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %d %d %s %s %s %s %d %d %s", $events, $particle, $pmin, $pmax, $mom, $outdir, $outfile, $build, $runnumber, $njob, $tstflag);
	print "cmd: $subcmd\n";
	system($subcmd);
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
	    last;
	}
    }
    else
    {
	print "output file already exists\n";
	$njob++;
    }
}

if (-f $condorlistfile)
{
    if (defined $test)
    {
	print "would submit condor.job\n";
    }
    else
    {
	system("condor_submit condor.job");
    }
}
