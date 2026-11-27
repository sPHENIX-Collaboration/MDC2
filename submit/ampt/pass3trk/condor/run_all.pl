#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

my $build;
my $incremental;
my $outevents = 0;
my $pileup;
my $system;
my $runnumber;
my $test;
GetOptions("build:s" => \$build, "events:i"=>\$outevents, "increment"=>\$incremental, "pileup:s" => \$pileup, "run:i" =>\$runnumber, "system:s"=>\$system, "test"=>\$test);
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
$outdir =~ s/trkrhit/$system\/trkrhit/;
$outdir = sprintf("%s/run%04d/%s",$outdir,$runnumber,lc $pileup);
if (! -d $outdir)
{
  mkpath($outdir);
}

my %outfiletype = ();
$outfiletype{"DST_TRKR_HIT"} = 1;
$outfiletype{"DST_TRUTH"} = 1;

my %trkhash = ();
my %truthhash = ();

my $outfilelike = sprintf("AMPT_%s_200GeV_%s_bkg_AMPT_%s_200GeV-",$system,$pileup,$system);

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRKR_G4HIT' and filename like '%$outfilelike%' and runnumber = $runnumber") || die $DBI::errstr;
#print "select filename,segment from datasets where dsttype = 'DST_TRKR_G4HIT' and filename like '%$outfilelike%' and runnumber = $runnumber\n";
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $gettruthfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRUTH_G4HIT' and filename like '%$outfilelike%' and runnumber = $runnumber");
my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
	$trkhash{sprintf("%06d",$res[1])} = $res[0];
}
$getfiles->finish();
$gettruthfiles->execute() || die $DBI::errstr;
my $ntruth = $gettruthfiles->rows;
while (my @res = $gettruthfiles->fetchrow_array())
{
	$truthhash{sprintf("%06d",$res[1])} = $res[0];
}
$gettruthfiles->finish();
#print "input files: $ncal, truth: $ntruth\n";
foreach my $segment (sort { $a <=> $b } keys %trkhash)
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
            my $lfn =  sprintf("%s_%s%010d-%06d.root",$type,$outfilelike,$runnumber,$segment);
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
	my $truthfile = $truthhash{sprintf("%06d",$segment)};
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %d %d %s", $outevents, $lfn, $truthfile, $outdir, $build, $pileup, $system, $runnumber, $segment, $tstflag);
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
