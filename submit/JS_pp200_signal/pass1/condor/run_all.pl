#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;

my $build;
my $incremental;
my $killexist;
my $runnumber;
my $events = 100;
my $test;
my $photonjet = 0;
GetOptions("build:s" => \$build, "increment"=>\$incremental, "killexist" => \$killexist, "run:i" =>\$runnumber, "test"=>\$test);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\", \"Jet15\", \"Jet20\", \"Jet30\", \"Jet40\", \"Jet50\", \"PhotonJet\", \"PhotonJet5\", \"PhotonJet10\", \"PhotonJet20\", \"Detroit\" production>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--increment : submit jobs while processing running\n";
    print "--killexist : delete output file if it already exists (but no jobfile)\n";
    print "--run: <runnumber>\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}

my $isbad = 0;

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

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /sphnxprod/)
{
    print "submit only from sphnxprod nodes\n";
    exit(1);
}

my $maxsubmit = $ARGV[0];
my $jettrigger = $ARGV[1];
my $filetype="pythia8";
if ($jettrigger  ne "Jet10" &&
    $jettrigger  ne "Jet20" &&
    $jettrigger  ne "Jet15" &&
    $jettrigger  ne "Jet30" &&
    $jettrigger  ne "Jet40" &&
    $jettrigger  ne "Jet50" &&
    $jettrigger  ne "PhotonJet" &&
    $jettrigger  ne "PhotonJet5" &&
    $jettrigger  ne "PhotonJet10" &&
    $jettrigger  ne "PhotonJet20" &&
    $jettrigger  ne "Detroit")
{
    print "second argument has to be Jet10, Jet30, Jet40, PhotonJet, PhotonJet5, PhotonJet10, PhotonJet20 or Detroit\n";
    exit(1);
}
# set the photonjet variable for photon jet configs
#if ($jettrigger  eq "PhotonJet5" ||
#    $jettrigger  eq "PhotonJet10" ||
#    $jettrigger  eq "PhotonJet20")
#{
#    $photonjet = 1;
#}


$filetype=sprintf("%s_%s",$filetype,$jettrigger);
my $condorlistfile =  sprintf("condor.list");
if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

my $outdir = `cat outdir.txt`;
chomp $outdir;
$outdir = sprintf("%s/run%04d/%s",$outdir,$runnumber,lc $jettrigger);
if (! -d $outdir)
{
  mkpath($outdir);
}

my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log/run%d/%s",$localdir,$runnumber,$jettrigger);
my $nsubmit = 0;
my $njob = 0;
OUTER: for (my $isub = 0; $isub < $maxsubmit; $isub++)
{
    my $jobfile = sprintf("%s/condor_%s-%010d-%06d.job",$logdir,$jettrigger,$runnumber,$njob);
    while (-f $jobfile)
    {
	$njob++;
	$jobfile = sprintf("%s/condor_%s-%010d-%06d.job",$logdir,$jettrigger,$runnumber,$njob);
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %d %d %d %s",$events, $jettrigger, $outdir, $outfile, $build, $photonjet, $runnumber, $njob, $tstflag);
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
	if (($nsubmit >= $maxsubmit) || $nsubmit >= 20000)
	{
	    print "maximum number of submissions $nsubmit reached, exiting\n";
	    last OUTER;
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
