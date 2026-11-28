#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

my $build;
my $incremental;
my $memory;
my $overwrite;
my $outevents = 0;
my $pileup;
my $system;
my $runnumber;
my $test;
GetOptions("build:s" => \$build, "events:i"=>\$outevents, "increment"=>\$incremental, "memory:s"=>\$memory, "overwrite"=>\$overwrite, "pileup:s" => \$pileup, "run:i" =>\$runnumber, "system:s"=>\$system, "test"=>\$test);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--events: <events to process, default 0=all>\n";
    print "--increment : submit jobs while processing running\n";
    print "--pileup : collision rate (with unit kHz)\n";
    print "--run: <runnumber>\n";
    print "--system: <AuAu or OO>\n";
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
if (! defined $system)
{
    print "need system with --system <OO or AuAu>\n";
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
$outdir =~ s/calocluster/$system\/calocluster/;
$outdir = sprintf("%s/run%04d/%s",$outdir,$runnumber,lc $pileup);
if (! -d $outdir)
{
  mkpath($outdir);
}
my %mbdhash = ();
my %truthhash = ();

my $outfilelike = sprintf("EPOS4_%s_200GeV_%s_bkg_EPOS4_%s_200GeV-",$system,$pileup,$system);

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_G4HIT' and filename like '%$outfilelike%' and runnumber = $runnumber order by segment") || die $DBI::errstr;
#print "select filename,segment from datasets where dsttype = 'DST_TRKR_G4HIT' and filename like '%$outfilelike%' and runnumber = $runnumber\n";
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    my $lfn = $res[0];
#    print "found $lfn\n";
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_CALO_CLUSTER_%s%010d-%06d.root",$outfilelike,$runnumber,$segment);
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
	    $tstflag = sprintf("%s --memory %s",$tstflag,$memory)
	}
	if (defined $overwrite)
	{
	    $tstflag = sprintf("%s --overwrite",$tstflag);
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %d %d %s", $outevents, $lfn, $outfilename, $outdir, $build, $pileup, $system, $runnumber, $segment, $tstflag);
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
	if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit >= 20000)
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
