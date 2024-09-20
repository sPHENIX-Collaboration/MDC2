#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $inrunnumber=15;
my $outrunnumber=$inrunnumber;
my $test;
my $incremental;
my $shared;
my $overwrite;
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
$outdir = sprintf("%s/run%04d",$outdir,$outrunnumber);
mkpath($outdir);

my $outfilelike = sprintf("pythia8_pp_mb-");

my %trkhash = ();
my %mbdepdhash = ();


my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRACKS' and filename like '%$outfilelike%' and runnumber = $inrunnumber order by segment") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $getmbdepdfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_MBD_EPD' and filename like '%$outfilelike%' and runnumber = $inrunnumber");

my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
while (my @res = $getfiles->fetchrow_array())
{
    $trkhash{sprintf("%06d",$res[1])} = $res[0];
}
$getfiles->finish();
$getmbdepdfiles->execute() || die $DBI::errstr;
my $nmbdepd = $getmbdepdfiles->rows;
while (my @res = $getmbdepdfiles->fetchrow_array())
{
    $mbdepdhash{sprintf("%06d",$res[1])} = $res[0];
}
$getmbdepdfiles->finish();
foreach my $segment (sort keys %trkhash)
{
    if (! exists $mbdepdhash{$segment})
    {
	next;
    }

    my $lfn = $trkhash{$segment};
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_GLOBAL_%s%010d-%06d.root",$outfilelike,$outrunnumber,$segment);
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %d %d %s", $outevents, $lfn, $mbdepdhash{sprintf("%06d",$segment)}, $outfilename, $outdir, $outrunnumber, $segment, $tstflag);
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
	if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit>= 20000)
	{
	    print "maximum number of submissions reached, exiting\n";
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
