#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $inrunnumber=15;
#my $outrunnumber=40;
my $outrunnumber=$inrunnumber;
my $test;
my $incremental;
my $shared;
my $MHz = 3;
GetOptions("test"=>\$test, "increment"=>\$incremental, "MHz:i" => \$MHz, "shared" => \$shared);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\", \"Jet30\", \"Jet40\", \"PhotonJet\", \"PhotonJet5\", \"PhotonJet10\", \"PhotonJet20\", \"Detroit\" production>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--MHz : MHz collision rate\n";
    print "--shared : submit jobs to shared pool\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxsub/)
{
    print "submit only from phnxsub01/02/03/04\n";
    exit(1);
}

my $maxsubmit = $ARGV[0];
my $jettrigger = $ARGV[1];
if ($jettrigger  ne "Jet10" &&
    $jettrigger  ne "Jet30" &&
    $jettrigger  ne "Jet40" &&
    $jettrigger  ne "PhotonJet" &&
    $jettrigger  ne "PhotonJet5" &&
    $jettrigger  ne "PhotonJet10" &&
    $jettrigger  ne "PhotonJet20" &&
    $jettrigger  ne "Detroit")
{
    print "second argument has to be Jet10, Jet30, Jet40, PhotonJet, PhotonJet5, PhotonJet10, PhotonJet20 or Detroit\n";
    exit(1);
}

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
$jettrigger = sprintf("%s_%sMHz",$jettrigger,$MHz);
$outdir = sprintf("%s/run%04d/%s",$outdir,$outrunnumber,lc $jettrigger);
if (! -d $outdir)
{
  mkpath($outdir);
}

my %g4hithash = ();
my %calohash = ();

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_G4HIT' and filename like 'DST_CALO_G4HIT_pythia8_$jettrigger-%' and runnumber = $inrunnumber order by segment") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $getcalofiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_NOZERO' and filename like 'DST_CALO_NOZERO_pythia8_$jettrigger-%' and runnumber = $inrunnumber");

my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
my $ncal = $getfiles->rows;

while (my @res = $getfiles->fetchrow_array())
{
    $g4hithash{sprintf("%06d",$res[1])} = $res[0];
}
$getfiles->finish();

$getcalofiles->execute() || die $DBI::errstr;
my $ncalo = $getcalofiles->rows;
while (my @res = $getcalofiles->fetchrow_array())
{
    $calohash{sprintf("%06d",$res[1])} = $res[0];
}
$getcalofiles->finish();

foreach my $segment (sort keys %g4hithash)
{
    if (! exists $calohash{$segment})
    {
	next;
    }
    my $lfn = $g4hithash{$segment};
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_CALO_WAVEFORM_pythia8_%s-%010d-%06d.root",$jettrigger,$outrunnumber,$segment);
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %d %d %s", $outevents, $jettrigger, $lfn, $calohash{sprintf("%06d",$segment)}, $outfilename, $outdir, $outrunnumber, $segment, $tstflag);
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
