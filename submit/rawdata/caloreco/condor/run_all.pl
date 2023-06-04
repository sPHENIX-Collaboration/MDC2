#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $inrunnumber=6;
#my $outrunnumber=40;
my $numsegs_to_process = 1000;
my $outrunnumber=$inrunnumber;
my $test;
my $incremental;
my $overwrite;
my $shared;
my $rawdatadir = sprintf("/sphenix/lustre01/sphnxpro/mdc2/rawdata/stripe5");
my $startrun = 250;
GetOptions("test"=>\$test, "increment"=>\$incremental, "overwrite"=>\$overwrite, "shared" => \$shared);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--overwrite : overwrite existing jobfiles and restart\n";
    print "--shared : submit jobs to shared pool\n";
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
$outdir = sprintf("%s/run%04d",$outdir,$inrunnumber);
mkpath($outdir);

my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log",$localdir);
mkpath($logdir);

my %calohash = ();
my %vtxhash = ();

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_G4HIT' and filename like 'DST_CALO_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm%' and runnumber = $inrunnumber order by filename") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $getvtxfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_VERTEX' and filename like 'DST_VERTEX_sHijing_0_20fm_50kHz_bkg_0_20fm%' and runnumber = $inrunnumber");
my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    $calohash{sprintf("%05d",$res[1])} = $res[0];
}
$getfiles->finish();
$getvtxfiles->execute() || die $DBI::errstr;
my $nvtx = $getvtxfiles->rows;
while (my @res = $getvtxfiles->fetchrow_array())
{
    $vtxhash{sprintf("%05d",$res[1])} = $res[0];
}
$getvtxfiles->finish();

my @vtxfiles = ();
my @calofiles = ();
my $icnt = 0;
my $outseg = 0;
my $nrun = $startrun;
my $nseg = -1;
#print "input files: $ncal, vtx: $nvtx\n";
foreach my $segment (sort keys %calohash)
{
    if (! exists $vtxhash{$segment})
    {
	next;
    }

    my $lfn = $calohash{$segment};
    push(@calofiles,$lfn);
    push(@vtxfiles,$vtxhash{$segment});
    $icnt++;
    if ($icnt < $numsegs_to_process)
    {
	next;
    }
    $icnt = 0;

    my $outfilename = sprintf("DST_RECO_CLUSTER_sHijing_0_20fm_50kHz_bkg_0_20fm-%010d-%05d.root",$outrunnumber,$outseg);
    my $vtxlistfile = sprintf("%s/condor-%010d-%05d.vtxlist",$logdir,$outrunnumber,$outseg);
    my $calolistfile = sprintf("%s/condor-%010d-%05d.calolist",$logdir,$outrunnumber,$outseg);
    open(F1,">$vtxlistfile");
    foreach my $bf (@vtxfiles)
    {
	print F1 "$bf\n";
    }
    close(F1);
    open(F1,">$calolistfile");
    foreach my $bf (@calofiles)
    {
	print F1 "$bf\n";
    }
    close(F1);
    @vtxfiles = ();
    @calofiles = ();
    my $outsegused = $outseg;
    $outseg++;

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
# create run and segment number to pass down
    my $rawfilename;
    do
    {
	$nseg++;
	if ($nseg > 16)
	{
	    $nseg = 0;
	    $nrun++;
	}
	if ($nrun > 299)
	{
	    $nrun = $startrun;
	}
	$rawfilename = sprintf("%s/seb02_junk-%08d-%04d.evt",$rawdatadir,$nrun,$nseg);
    } until (-f $rawfilename);
    my $subcmd = sprintf("perl run_condor.pl %d %d %d %s %s %s %s %d %d %s %s", $outevents, $outrunnumber, $outsegused, $outfilename, $outdir, $calolistfile, $vtxlistfile, $nrun, $nseg, $rawdatadir, $tstflag);

#	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %d %d %s", $outevents, $lfn, $vtxhash{sprintf("%05d",$segment)}, $outfilename, $outdir, $outrunnumber, $segment, $tstflag);
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
