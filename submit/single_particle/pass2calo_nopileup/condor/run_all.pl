#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $build;
my $events = 1000;
my $incremental;
my $killexist;
my $memory;
my $mom;
my $overwrite;
my $runnumber;
my $shared;
my $test;
GetOptions("build:s" => \$build, "increment"=>\$incremental, "killexist" => \$killexist, "memory:s"=>\$memory, "mom:s" => \$mom, "overwrite"=>\$overwrite, "run:i" =>\$runnumber, "shared" => \$shared, "test"=>\$test);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs> <particle> <pmin> <pmax>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--increment : submit jobs while processing running\n";
    print "--killexist : delete output file if it already exists (but no jobfile)\n";
    print "-memory: <mem in MB>\n";
    print "--mom <p or pt> : use p or pt for momentum\n";
    print "--overwrite: overwrite output\n";
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

my $outdir = `cat outdir.txt`;
chomp $outdir;
print "outdir: $outdir\n";
$outdir = sprintf("%s/run%04d/%s",$outdir,$runnumber,$partprop);
if (! -d $outdir)
{
  mkpath($outdir);
}
print "outdir spr: $outdir\n";

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'G4Hits' and filename like '%$filetype%' and runnumber = $runnumber order by segment") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
my $ncal = $getfiles->rows;

while (my @res = $getfiles->fetchrow_array())
{
    my $lfn = $res[0];
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_CALO_CLUSTER_%s-%010d-%06d.root",$filetype,$runnumber,$segment);
	$chkfile->execute($outfilename);
	if ($chkfile->rows > 0)
	{
	    next;
	}
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	if (defined $memory)
	{
	    $tstflag = sprintf("%s --memory %s",$tstflag, $memory)
	}
        if (defined $overwrite)
	{
	    $tstflag= sprintf("%s --overwrite",$tstflag);
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %d %d %s", $events, $filetype, $partprop, $lfn, $outfilename, $outdir,  $build, $runnumber, $segment, $tstflag);
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
	if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit >=20000)
	{
	    print "maximum number of submissions $nsubmit reached, exiting\n";
	    last;
	}
    }
}
$getfiles->finish();
$chkfile->finish();
$dbh->disconnect;

my $jobfile = sprintf("condor.job");
if (defined $shared)
{
 $jobfile = sprintf("condor.job.shared");
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
