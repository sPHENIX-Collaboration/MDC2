#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;
use DBI;

my $build;
my $events = 200000;
my $incremental;
my $killexist;
my $overwrite;
my $runnumber;
my $startsegment = -1;
my $test;

GetOptions("build:s" => \$build, "events:i"=> \$events, "increment"=>\$incremental, "killexist" => \$killexist, "overwrite" => \$overwrite, "run:i" =>\$runnumber, "startsegment:i" => \$startsegment, "test"=>\$test);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Detroit\" production>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--increment : submit jobs while processing running\n";
    print "--killexist : delete output file if it already exists (but no jobfile)\n";
    print "--overwrite: overwrite job files\n";
    print "--run: <runnumber>\n";
    print "--startsegment: starting segment\n";
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
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select filename from datasets where filename = ?");

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
if ($jettrigger  ne "Detroit")
{
    print "second argument has to be Detroit\n";
    exit(1);
}

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
    my $outfile_missing = 0;
    while (-f $jobfile || $njob<=$startsegment)
    {
	if ($njob<=$startsegment)
	{
	    $njob++;
	    next;
	}
	my $outfile_chk = sprintf("DST_HEPMC_%s-%010d-%06d.root",$filetype, $runnumber,$njob);
	$chkfile->execute($outfile_chk);
	my $rows = $chkfile->rows;
	if ($rows == 0)
	{
	    print "could not find $outfile_chk in DB\n";
	    $outfile_missing = 1;
	    last;
	}
	#	print "found jobfile $jobfile, njob: $njob, startsegment: $startsegment\n";
	$njob++;
	$jobfile = sprintf("%s/condor_%s-%010d-%06d.job",$logdir,$jettrigger,$runnumber,$njob);
    }
    my $outfile = sprintf("DST_HEPMC_%s-%010d-%06d.root",$filetype, $runnumber,$njob);
    my $fulloutfile = sprintf("%s/%s",$outdir,$outfile);
#    print "using jobfile $jobfile\n";
#    print "out: $fulloutfile\n";
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
	if (defined $overwrite)
	{
	    $tstflag= sprintf("%s --overwrite",$tstflag);
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %d %d %s",$events, $jettrigger, $outdir, $outfile, $build, $runnumber, $njob, $tstflag);
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
	if ($outfile_missing == 1)
	{
	    $njob++;
	}
    }
    else
    {
	print "output file already exists\n";
	$njob++;
    }
}

$chkfile->finish();
$dbh->disconnect;

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
