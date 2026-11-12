#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;
use DBI;

sub getlastsegment;

my $build;
my $events = 1000;
my $incremental;
my $memory;
my $overwrite;
my $runnumber;
my $startsegment = -1;
my $test;
GetOptions("build:s" => \$build, "events:i"=> \$events, "increment"=>\$incremental, "overwrite"=>\$overwrite, "run:i" =>\$runnumber, "startsegment:i" => \$startsegment, "test"=>\$test);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> \"PhotonJet5\", \"PhotonJet5Frag\", \"PhotonJet10\", \"PhotonJet10Frag\", \"PhotonJet20\", \"PhotonJet20Frag\" production>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--events: number of events\n";
    print "--increment : submit jobs while processing running\n";
    print "--memory: <mem in MB>\n";
    print "--overwrite : overwrite existing jobfiles and restart\n";
    print "--run: <runnumber>\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}
my $isbad = 0;

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /sphnxprod/)
{
    print "submit only from sphnxprod hosts\n";
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
my $jettrigger = $ARGV[1];
my $filetype="Herwig";
if (
    $jettrigger  ne "PhotonJet5" &&
    $jettrigger  ne "PhotonJet5Frag" &&
    $jettrigger  ne "PhotonJet10" &&
    $jettrigger  ne "PhotonJet10Frag" &&
    $jettrigger  ne "PhotonJet20" &&
    $jettrigger  ne "PhotonJet20Frag")
{
    print "second argument has to be PhotonJet5, PhotonJet5Frag, PhotonJet10, PhotonJet10Frag, PhotonJet20 or PhotonJet20Frag\n";
    exit(1);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $herwig_dir = sprintf("/sphenix/lustre01/sphnxpro/mdc2/HerwigHepMC");

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
    while (-f $jobfile || $njob<=$startsegment)
    {
#	print "found jobfile $jobfile, njob: $njob, startsegment: $startsegment\n";
	$njob++;
	$jobfile = sprintf("%s/condor_%s-%010d-%06d.job",$logdir,$jettrigger,$runnumber,$njob);
    }
    print "using jobfile $jobfile\n";
    my $outfile = sprintf("DST_HEPMC_%s-%010d-%06d.root",$filetype, $runnumber,$njob);
    my $fulloutfile = sprintf("%s/%s",$outdir,$outfile);
    print "out: $fulloutfile\n";
    if (defined $overwrite)
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

sub getlastsegment()
{
    my $herwigsubdir = sprintf("%s/%s",$herwig_dir,$filetype);
    opendir(DH,$herwigsubdir);
    my @tmpfiles = sort(readdir(DH));
    closedir(DH);
    my @files = ();
    foreach my $f (@tmpfiles)
    {
	if ($f =~ /$jettrigger/)
	{
	    push(@files,$f);
	}
    }
    if ($#files <= 0)
    {
	print "no hepmc files found in $herwigsubdir\n";
	exit(1);
    }
    my $last_segment = -1;
    if ($files[$#files] =~ /(\S+)-(\d+).*\..*/ )
    {
	$last_segment = int($2);
    }
    else
    {
	print "cannot parse $files[$#files] for segment number\n";
	exit(1);
    }
    return $last_segment;
}
