#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber = 10;
my $test;
my $incremental;
my $fm = "0_20fm";
GetOptions("test"=>\$test, "fm:s" =>\$fm, "increment"=>\$incremental);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\", \"Jet30\", \"Jet40\", \"PhotonJet\" production>\n";
    print "parameters:\n";
    print "--fm : fermi range for embedding\n";
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

if (! -f "outdir.txt")
{
    print "could not find outdir.txt\n";
    exit(1);
}
my $outdir = `cat outdir.txt`;
chomp $outdir;
$outdir = sprintf("%s/%s/run%04d/%s",$outdir,$fm,$runnumber,lc $jettrigger);
if (! -d $outdir)
{
  mkpath($outdir);
}


my %outfiletype = ();
$outfiletype{"DST_TRKR_HIT"} = 1;
$outfiletype{"DST_TRUTH"} = 1;

my %trkhash = ();
my %truthhash = ();

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRKR_G4HIT' and filename like '%$outfilelike%' and runnumber = $runnumber order by filename") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $gettruthfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRUTH_G4HIT' and filename like '%$outfilelike%'and runnumber = $runnumber");
my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    $trkhash{sprintf("%05d",$res[1])} = $res[0];
}
$getfiles->finish();
$gettruthfiles->execute() || die $DBI::errstr;
my $ntruth = $gettruthfiles->rows;
while (my @res = $gettruthfiles->fetchrow_array())
{
    $truthhash{sprintf("%05d",$res[1])} = $res[0];
}
$gettruthfiles->finish();
#print "input files: $ncal, truth: $ntruth\n";
foreach my $segment (sort keys %trkhash)
{
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
            my $lfn =  sprintf("%s_%s-%010d-%05d.root",$type,$outfilelike,$runnumber,$segment);
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %d %d %s %s", $outevents, $jettrigger, $lfn, $truthhash{sprintf("%05d",$segment)}, $outdir, $runnumber, $segment, $fm, $tstflag);
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
	if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit > 20000)
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
