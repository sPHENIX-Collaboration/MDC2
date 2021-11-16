#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber=2;
my $test;
my $incremental;
GetOptions("test"=>\$test, "increment"=>\$incremental);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Charm\", \"CharmD0\", \"Bottom\", \"BottomD0\" or \"MinBias\" production>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
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
if ($quarkfilter  ne "Charm" &&
    $quarkfilter  ne "CharmD0" &&
    $quarkfilter  ne "Bottom" &&
    $quarkfilter  ne "BottomD0" &&
    $quarkfilter  ne "MinBias")
{
    print "second argument has to be either Charm, CharmD0, Bottom, BottomD0 or MinBias\n";
    exit(1);
}
if (! -f "outdir.txt")
{
    print "could not find outdir.txt\n";
    exit(1);
}
my $outdir = `cat outdir.txt`;
chomp $outdir;
$outdir = sprintf("%s/%s",$outdir,$quarkfilter);
mkpath($outdir);

$quarkfilter = sprintf("%s_3MHz",$quarkfilter);

my %calohash = ();
my %vtxhash = ();

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_G4HIT' and filename like '%pythia8_$quarkfilter%' and runnumber = $runnumber order by filename") || die $DBI::error;
#print "select filename,segment from datasets where dsttype = 'DST_CALO_G4HIT' and filename like '%pythia8_$quarkfilter%' and runnumber = $runnumber order by filename\n";

my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::error;
my $getvtxfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_VERTEX' and filename like '%pythia8_$quarkfilter%' and runnumber = $runnumber");
my $nsubmit = 0;
$getfiles->execute() || die $DBI::error;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    $calohash{sprintf("%05d",$res[1])} = $res[0];
}
$getfiles->finish();
$getvtxfiles->execute() || die $DBI::error;
my $nvtx = $getvtxfiles->rows;
while (my @res = $getvtxfiles->fetchrow_array())
{
    $vtxhash{sprintf("%05d",$res[1])} = $res[0];
}
$getvtxfiles->finish();
print "input files: $ncal, vtx: $nvtx\n";
foreach my $segment (sort keys %calohash)
{
    if (! exists $vtxhash{$segment})
    {
	next;
    }

    my $lfn = $calohash{$segment};
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_CALO_CLUSTER_pythia8_%s-%010d-%05d.root",$quarkfilter,$runnumber,$segment);
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %d %d %s", $outevents, $quarkfilter, $lfn, $vtxhash{sprintf("%05d",$segment)}, $outfilename, $outdir, $runnumber, $segment, $tstflag);
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
	    exit(0);
	}
    }
}
$chkfile->finish();
$dbh->disconnect;
