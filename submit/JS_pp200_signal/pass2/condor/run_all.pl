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
my $outevents = 0;
my $overwrite;
my $runnumber;
my $outrunnumber;
my $shared;
my $test;
my $pileup;
my $verbosity = 0;
GetOptions("build:s" => \$build, "increment"=>\$incremental, "memory:s"=>\$memory, "outrunnumber"=>\$outrunnumber, "overwrite"=> \$overwrite, "pileup:s" => \$pileup, "run:i" =>\$runnumber, "shared" => \$shared, "test"=>\$test, "verbosity:i" => \$verbosity);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\", \"Jet30\", \"Jet40\", \"PhotonJet\", \"PhotonJet5\", \"PhotonJet10\", \"PhotonJet20\", \"Detroit\" production>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--increment : submit jobs while processing running\n";
    print "--overwrite : overwrite exiting jobfiles\n";
    print "--pileup : collision rate (with unit, kHz, MHz)\n";
    print "--run: <runnumber>\n";
    print "--shared : submit jobs to shared pool\n";
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
if (! defined $pileup)
{
    print "need pileup with --pileup <rate with unit> (kHz, MHz)\n";
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

my $outdir = `cat outdir.txt`;
chomp $outdir;
my $jettriggerWithUnderScore = sprintf("%s-",$jettrigger);
$jettrigger = sprintf("%s_%s",$jettrigger,$pileup);
$outdir = sprintf("%s/run%04d/%s",$outdir,$runnumber,lc $jettrigger);
if (! -d $outdir)
{
  mkpath($outdir);
}

my %outfiletype = ();
$outfiletype{"DST_BBC_G4HIT"} = 1;
$outfiletype{"DST_CALO_G4HIT"} = 1;
$outfiletype{"DST_TRKR_G4HIT"} = 1;
$outfiletype{"DST_TRUTH_G4HIT"} = "DST_TRUTH";

my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log/run%d/%s",$localdir,$runnumber,$jettrigger);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename from datasets where dsttype = 'G4Hits' and filename like 'G4Hits_pythia8_$jettriggerWithUnderScore%' and runnumber = $runnumber order by segment") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $getbkglastsegment = $dbh->prepare("select max(segment) from datasets where dsttype = 'G4Hits' and filename like 'G4Hits_pythia8_Detroit-%' and runnumber = $runnumber");
$getbkglastsegment->execute();
my @res1 = $getbkglastsegment->fetchrow_array();
my $lastsegment = $res1[0];
$getbkglastsegment->finish();

my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
while (my @res = $getfiles->fetchrow_array())
{
    my $lfn = $res[0];
    if ($verbosity > 1)
    {
	print "found $lfn\n";
    }
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
        my $prefix=$1;
	my $runnumber = int($2);
	my $segment = int($3);
	my $foundall = 1;
	if (! defined $outrunnumber)
	{
	    $outrunnumber = $runnumber;
	}
	foreach my $type (sort keys %outfiletype)
	{
	    my $outfilename = sprintf("%s/%s_pythia8_%s-%010d-%06d.root",$outdir,$type,$jettrigger,$outrunnumber,$segment);
#	    print "checking for $outfilename\n";
	    if (! -f  $outfilename)
	    {
		my $outlfn = basename($outfilename);
		$chkfile->execute($outlfn);
		if ($chkfile->rows > 0)
		{
		    if ($verbosity > 1)
		    {
			print "found $outfilename\n";
		    }
		    next;
		}
		else
		{
		    my $newlfn = $outfiletype{$type};
		    if ($newlfn ne "1")
		    {
			$lfn =~ s/$type/$outfiletype{$type}/;
			$chkfile->execute($lfn);
			if ($chkfile->rows > 0)
			{
			    next;
			}
		    }
		    $foundall = 0;
		    last;
		}
	    }
	}
	if ($foundall == 1)
	{
#	    print "foundall is 1\n";
	    next;
	}
# output file does not exist yet, check for 100 MB background files (n+1 to n+100)
	$foundall = 1;
	my @bkgfiles = ();
	my $bkgsegments = 0;
# if Detroit is embedded in itself, don't start with the same segment for the background
# for others it doesn't matter
	my $currsegment = $segment;
# the number of files can be large - there is no overhead, 
# we only open new files when the old file is exhausted
	while ($bkgsegments <= 99)
	{
	    $currsegment++;
	    if ($currsegment > $lastsegment)
	    {
		$currsegment = 0;
	    }
	    my $prefix_mb = sprintf("G4Hits_pythia8_Detroit");
	    my $bckfile = sprintf("%s-%010d-%06d.root",$prefix_mb,$runnumber,$currsegment);
	    $chkfile->execute($bckfile);
	    if ($chkfile->rows == 0)
	    {
		if ($verbosity > 0)
		{
		    print "missing bkg $bckfile\n";
		}
		$foundall = 0;
		last;
	    }
	    else
	    {
		$bkgsegments++;
		push(@bkgfiles,$bckfile);
	    }
	}
	if ($foundall == 0) # background file is missing
	{
#	    print "foundall is 1\n";
	    next;
	}
	my $bkglistfile = sprintf("%s/condor_%s-%010d-%06d.bkglist",$logdir,$jettrigger,$runnumber,$segment);
	open(F1,">$bkglistfile");
	foreach my $bf (@bkgfiles)
	{
	    print F1 "$bf\n";
	}
	close(F1);
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %d %d %s", $outevents, $jettrigger, $lfn, $bkglistfile, $outdir, $build, $pileup, $runnumber, $segment, $tstflag);
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
	    print "maximum number of submissions reached, exiting\n";
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
if (! -f $jobfile)
{
    print "could not find $jobfile\n";
    exit(1);
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
