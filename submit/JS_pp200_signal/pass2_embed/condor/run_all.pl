#!/usr/bin/perl

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
my $test;
GetOptions("build:s" => \$build, "fm:s" =>\$fm, "increment"=>\$incremental, "overwrite"=> \$overwrite, "run:i" =>\$runnumber, "test"=>\$test);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\">, <\"Jet15\">, <\"Jet20\">, <\"Jet30\">, <\"Jet40\">, <\"Jet50\">, <\"PhotonJet\">, <\"PhotonJet5\">, <\"PhotonJet10\">, <\"PhotonJet20\">, <\"Detroit\"> production>\n";
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

my $embedfilelike = sprintf("sHijing_%s_50kHz_bkg_0_20fm",$fm);
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
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRKR_G4HIT' and filename like 'DST_TRKR_G4HIT_$embedfilelike%' and runnumber = $runnumber order by segment") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
$getfiles->execute() || die $DBI::errstr;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    $trkhash{sprintf("%06d",$res[1])} = $res[0];
}
$getfiles->finish();

my %truthhash = ();
my $gettruthfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRUTH_G4HIT' and filename like 'DST_TRUTH_G4HIT_$embedfilelike%' and runnumber = $runnumber");
$gettruthfiles->execute() || die $DBI::errstr;
my $ntruth = $gettruthfiles->rows;
while (my @res = $gettruthfiles->fetchrow_array())
{
    $truthhash{sprintf("%06d",$res[1])} = $res[0];
}
$gettruthfiles->finish();

my %bbchash = ();
my $getbbcfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_BBC_G4HIT' and filename like 'DST_BBC_G4HIT_$embedfilelike%' and runnumber = $runnumber");
$getbbcfiles->execute() || die $DBI::errstr;
my $nbbc = $getbbcfiles->rows;
while (my @res = $getbbcfiles->fetchrow_array())
{
    $bbchash{sprintf("%06d",$res[1])} = $res[0];
}
$getbbcfiles->finish();

my %calohash = ();
my $getcalofiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_G4HIT' and filename like 'DST_CALO_G4HIT_$embedfilelike%' and runnumber = $runnumber");
$getcalofiles->execute() || die $DBI::errstr;
my $ncalo = $getcalofiles->rows;
while (my @res = $getcalofiles->fetchrow_array())
{
    $calohash{sprintf("%06d",$res[1])} = $res[0];
}
$getcalofiles->finish();

#print "input files: $ncal, truth: $ntruth\n";
foreach my $segment (sort { $a <=> $b } keys %trkhash)
{
    if (! exists $bbchash{$segment})
    {
	next;
    }
    if (! exists $calohash{$segment})
    {
	next;
    }
    if (! exists $truthhash{$segment})
    {
	next;
    }

    my $lfn = $trkhash{$segment};
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %s %d %d %s %s", $outevents, $jettrigger, $lfn, $bbchash{sprintf("%06d",$segment)}, $calohash{sprintf("%06d",$segment)}, $truthhash{sprintf("%06d",$segment)}, $outdir, $build, $runnumber, $segment, $fm, $tstflag);
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
