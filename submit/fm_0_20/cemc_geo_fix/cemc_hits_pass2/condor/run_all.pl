#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber = 6;
my $test;
my $incremental;
my $verbosity;
GetOptions("test"=>\$test, "increment"=>\$incremental, "verbose"=>\$verbosity);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--test : dryrun - create jobfiles\n";
    print "--verbose : turn on blabbering\n";
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
$outdir = sprintf("%s/run%04d",$outdir,$runnumber);
mkpath($outdir);

my %bbchash = ();
my %calohash = ();
my %trkrhash = ();
my %truthhash = ();
my %vtxhash = ();

my %outfiletype = ();
$outfiletype{"DST_BBC_G4HIT"} = 1;
$outfiletype{"DST_CALO_G4HIT"} = 1;
$outfiletype{"DST_TRKR_G4HIT"} = 1;
$outfiletype{"DST_TRUTH_G4HIT"} = 1;
$outfiletype{"DST_VERTEX"} = 1;

my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log",$localdir);
mkpath($logdir);

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here

my $getbbcfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DSTOLD_BBC_G4HIT' and filename like '%sHijing_0_20fm%' and runnumber = $runnumber order by segment") || die $DBI::errstr;

my $getcalofiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DSTOLD_CALO_G4HIT' and filename like '%sHijing_0_20fm%' and runnumber = $runnumber order by segment") || die $DBI::errstr;

my $gettrkrfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DSTOLD_TRKR_G4HIT' and filename like '%sHijing_0_20fm%' and runnumber = $runnumber order by segment") || die $DBI::errstr;

my $gettruthfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DSTOLD_TRUTH_G4HIT' and filename like '%sHijing_0_20fm%' and runnumber = $runnumber order by segment") || die $DBI::errstr;

my $getvtxfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DSTOLD_VERTEX' and filename like '%sHijing_0_20fm%' and runnumber = $runnumber order by segment") || die $DBI::errstr;

my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $nsubmit = 0;

$getbbcfiles->execute() || die $DBI::errstr;
while (my @res = $getbbcfiles->fetchrow_array())
{
    if ($res[1] < 100000)
    {
	$bbchash{sprintf("%05d",$res[1])} = $res[0];
    }
    else
    {
	$bbchash{sprintf("%06d",$res[1])} = $res[0];
    }
}
$getbbcfiles->finish();

$getcalofiles->execute() || die $DBI::errstr;
while (my @res = $getcalofiles->fetchrow_array())
{
    if ($res[1] < 100000)
    {
	$calohash{sprintf("%05d",$res[1])} = $res[0];
    }
    else
    {
	$calohash{sprintf("%06d",$res[1])} = $res[0];
    }
}
$getcalofiles->finish();

$gettrkrfiles->execute() || die $DBI::errstr;
while (my @res = $gettrkrfiles->fetchrow_array())
{
    if ($res[1] < 100000)
    {
	$trkrhash{sprintf("%05d",$res[1])} = $res[0];
    }
    else
    {
	$trkrhash{sprintf("%06d",$res[1])} = $res[0];
    }
}
$gettrkrfiles->finish();

$gettruthfiles->execute() || die $DBI::errstr;
while (my @res = $gettruthfiles->fetchrow_array())
{
    if ($res[1] < 100000)
    {
	$truthhash{sprintf("%05d",$res[1])} = $res[0];
    }
    else
    {
	$truthhash{sprintf("%06d",$res[1])} = $res[0];
    }
}
$gettruthfiles->finish();

$getvtxfiles->execute() || die $DBI::errstr;
while (my @res = $getvtxfiles->fetchrow_array())
{
    if ($res[1] < 100000)
    {
	$vtxhash{sprintf("%05d",$res[1])} = $res[0];
    }
    else
    {
	$vtxhash{sprintf("%06d",$res[1])} = $res[0];
    }
}
$getvtxfiles->finish();

foreach my $segment (sort { $a <=> $b } keys %bbchash)
{
    if (! exists $calohash{$segment})
    {
	next;
    }
    if (! exists $trkrhash{$segment})
    {
	next;
    }
    if (! exists $truthhash{$segment})
    {
	next;
    }
    if (! exists $vtxhash{$segment})
    {
	next;
    }
    my $lfn = $bbchash{$segment};
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
        my $prefix=$1;
	my $runnumber = int($2);
	my $segment = int($3);
	my $foundall = 1;
	foreach my $type (sort keys %outfiletype)
	{
            my $outfile =  sprintf("%s_sHijing_0_20fm_50kHz_bkg_0_20fm-%010d-%06d.root",$type,$runnumber,$segment);
	    if ($segment < 100000)
	    {
		$outfile =  sprintf("%s_sHijing_0_20fm_50kHz_bkg_0_20fm-%010d-%05d.root",$type,$runnumber,$segment);
	    }
	    $chkfile->execute($outfile);
	    if ($chkfile->rows > 0)
	    {
		next;
	    }
	    else
	    {
		my $newoutfile = $outfiletype{$type};
		if ($newoutfile ne "1")
		{
		    $outfile =~ s/$type/$outfiletype{$type}/;
		    $chkfile->execute($outfile);
		    if ($chkfile->rows > 0)
		    {
			next;
		    }
		}
		$foundall = 0;
		last;
	    }
	}
	if ($foundall == 1)
	{
	    next;
	}
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %d %d %s", $outevents, $lfn, $calohash{sprintf("%05d",$segment)}, $trkrhash{sprintf("%05d",$segment)}, $truthhash{sprintf("%05d",$segment)}, $vtxhash{sprintf("%05d",$segment)}, $outdir, $runnumber, $segment, $tstflag);
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
