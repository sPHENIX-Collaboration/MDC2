#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $build;
my $fm = "0_20fm";
my $incremental;
my $outevents = 0;
my $overwrite;
my $runnumber;
my $shared;
my $test;
GetOptions("build:s" => \$build, "fm:s" =>\$fm, "increment"=>\$incremental, "overwrite"=> \$overwrite, "run:i" =>\$runnumber, "shared" => \$shared, "test"=>\$test);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\", \"Jet30\", \"Jet40\", \"PhotonJet\" production>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--fm : fermi range for embedding\n";
    print "--increment : submit jobs while processing running\n";
    print "--overwrite : overwrite exiting jobfiles\n";
    print "--run: <runnumber>\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}

my $isbad = 0;

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
my $jettrigger = $ARGV[1];
if ($jettrigger  ne "Jet10" &&
    $jettrigger  ne "Jet30" &&
    $jettrigger  ne "Jet40" &&
    $jettrigger  ne "PhotonJet")
{
    print "second argument has to be Jet10, Jet30 or PhotonJet\n";
    exit(1);
}

my $outfilelike = sprintf("pythia8_%s_sHijing_%s_50kHz_bkg_0_20fm",$jettrigger,$fm);

my $condorlistfile =  sprintf("condor.list");
if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

my $outdir = `cat outdir.txt`;
chomp $outdir;
$outdir = sprintf("%s/%s/run%04d/%s",$outdir,$fm,$runnumber,lc $jettrigger);
if (! -d $outdir)
{
  mkpath($outdir);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here

my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRKR_G4HIT' and filename like 'DST_TRKR_G4HIT_$outfilelike%' and runnumber = $runnumber") || die $DBI::errstr;
my $getclusterfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRKR_CLUSTER' and filename like 'DST_TRKR_CLUSTER_$outfilelike%' and runnumber = $runnumber") || die $DBI::errstr;
my $gettrackfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRACKS' and filename like 'DST_TRACKS_$outfilelike%' and runnumber = $runnumber") || die $DBI::errstr;
my $gettruthfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRUTH' and filename like 'DST_TRUTH_$outfilelike%' and runnumber = $runnumber") || die $DBI::errstr;

my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;


my %g4hithash = ();
$getfiles->execute() || die $DBI::errstr;
my $ng4hit = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    $g4hithash{sprintf("%06d",$res[1])} = $res[0];
}
$getfiles->finish();

my %clusterhash = ();
$getclusterfiles->execute() || die $DBI::errstr;
my $ncluster = $getclusterfiles->rows;
while (my @res = $getclusterfiles->fetchrow_array())
{
    $clusterhash{sprintf("%06d",$res[1])} = $res[0];
}
$getclusterfiles->finish();

my %trackhash = ();
$gettrackfiles->execute() || die $DBI::errstr;
my $ntrack = $gettrackfiles->rows;
while (my @res = $gettrackfiles->fetchrow_array())
{
    $trackhash{sprintf("%06d",$res[1])} = $res[0];
}
$gettrackfiles->finish();

my %truthhash = ();
$gettruthfiles->execute() || die $DBI::errstr;
my $ntruth = $gettruthfiles->rows;
while (my @res = $gettruthfiles->fetchrow_array())
{
    $truthhash{sprintf("%06d",$res[1])} = $res[0];
}
$gettruthfiles->finish();


print "input files g4hit: $ng4hit, cluster: $ncluster, track: $ntrack, truth: $ntruth\n";

my $nsubmit = 0;

foreach my $segment (sort keys %trackhash)
{
    if (! exists $g4hithash{$segment})
    {
	next;
    }
    if (! exists $clusterhash{$segment})
    {
	next;
    }
    if (! exists $truthhash{$segment})
    {
	next;
    }

    my $lfn = $trackhash{$segment};
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
        my $outfilename =  sprintf("DST_TRUTH_RECO_%s-%010d-%06d.root",$outfilelike,$runnumber,$segment);
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
        elsif (defined $overwrite)
	{
	    $tstflag="--overwrite";
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %s %s %d %d %s %s", $outevents, $jettrigger, $g4hithash{sprintf("%06d",$segment)}, $clusterhash{sprintf("%06d",$segment)}, $trackhash{sprintf("%06d",$segment)}, $truthhash{sprintf("%06d",$segment)}, $outfilename, $outdir, $build, $runnumber, $segment, $fm, $tstflag);
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
