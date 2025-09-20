#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $build;
my $incremental;
my $fm = "0_20fm";
my $outevents = 0;
my $overwrite;
my $runnumber;
my $startsegment = 0;
my $test;
GetOptions("build:s" => \$build, "fm:s" =>\$fm, "increment"=>\$incremental, "overwrite"=> \$overwrite, "run:i" =>\$runnumber, "startsegment:i" => \$startsegment, "test"=>\$test);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\">, <\"Jet15\">, <\"Jet20\">, <\"Jet30\">, <\"Jet40\">, <\"Jet50\">, <\"PhotonJet\">, <\"PhotonJet5\">, <\"PhotonJet10\">, <\"PhotonJet20\">, <\"Detroit\"> production>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--fm : fermi range for embedding\n";
    print "--increment : submit jobs while processing running\n";
    print "--overwrite : overwrite exiting jobfiles\n";
    print "--run: <runnumber>\n";
    print "--startsegment: starting segment\n";
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

my $embedfilelike = sprintf("sHijing_%s",$fm);
my $outfilelike = sprintf("pythia8_%s_%s",$jettrigger,$embedfilelike);

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

my %outfiletype = ();
$outfiletype{"DST_BBC_G4HIT"} = 1;
$outfiletype{"DST_CALO_G4HIT"} = 1;
$outfiletype{"DST_TRKR_G4HIT"} = 1;
$outfiletype{"DST_TRUTH_G4HIT"} = 1;

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $nsubmit = 0;

my %trkhash = ();
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'G4Hits' and filename like 'G4Hits_$embedfilelike%' and runnumber = $runnumber and segment >= $startsegment order by segment") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
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
        my $foundall = 1;
	foreach my $type (sort keys %outfiletype)
	{
            my $lfn =  sprintf("%s_%s-%010d-%06d.root",$type,$outfilelike,$runnumber,$segment);
	    $chkfile->execute($lfn);
	    if ($chkfile->rows > 0)
	    {
		next;
	    }
	    else
	    {
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
        elsif (defined $overwrite)
	{
	    $tstflag="--overwrite";
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %d %d %s %s", $outevents, $jettrigger, $lfn, $outdir, $build, $runnumber, $segment, $fm, $tstflag);
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
