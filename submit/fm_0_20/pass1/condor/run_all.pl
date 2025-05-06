#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;
use DBI;

sub getlastsegment;

my $build;
my $incremental;
my $runnumber;
my $test;
GetOptions("build:s" => \$build, "increment"=>\$incremental, "run:i" =>\$runnumber, "test"=>\$test);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--increment : submit jobs while processing running\n";
    print "--run: <runnumber>\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}
my $isbad = 0;
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

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /sphnxprod/)
{
    print "submit only from sphnxprod nodes\n";
    exit(1);
}

my $maxsubmit = $ARGV[0];
if ($maxsubmit > 500)
{
    print "beware of gpfs overload, you sure you want to run $maxsubmit jobs?\n";
#    exit(0);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $hijing_runnumber = 1;
my $hijing_dir = sprintf("/sphenix/lustre01/sphnxpro/mdc2/sHijing_HepMC/data");
my $events = 200; # for running with plugdoor
#$events = 200;
#$events = 100; # for ftfp_bert_hp
my $evtsperfile = 10000;
my $nmax = $evtsperfile;

my $condorlistfile =  sprintf("condor.list");
if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

my $outdir = `cat outdir.txt`;
chomp $outdir;
$outdir = sprintf("%s/run%04d",$outdir,$runnumber);
if (! -d $outdir)
{
  mkpath($outdir);
}

my $nsubmit = 0;
my $lastsegment=getlastsegment();
OUTER: for (my $segment=0; $segment<=$lastsegment; $segment++)
{
    my $hijingdatfile = sprintf("%s/sHijing_0_20fm-%010d-%05d.dat",$hijing_dir,$hijing_runnumber, $segment);
    if (! -f $hijingdatfile)
    {
	print "could not locate $hijingdatfile\n";
	next;
    }
#    print "hijing: $hijingdatfile\n";
    my $sequence = $segment*$evtsperfile/$events;
    for (my $n=0; $n<$nmax; $n+=$events)
    {
	my $outfile = sprintf("G4Hits_sHijing_0_20fm-%010d-%06d.root",$runnumber,$sequence);
	$chkfile->execute($outfile);
	if ($chkfile->rows == 0)
	{
	    my $tstflag="";
	    if (defined $test)
	    {
		$tstflag="--test";
	    }
            my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %d %s %d %d %s", $events, $hijingdatfile, $outdir, $outfile, $n, $build, $runnumber, $sequence, $tstflag);
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
	    if ($nsubmit >= $maxsubmit || $nsubmit >= 20000)
	    {
		print "maximum number of submissions reached, exiting\n";
		last OUTER;
	    }
	}
#	else
#	{
#	    print "$outfile exists\n";
#	}
        $sequence++;
    }
}

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

sub getlastsegment()
{
    opendir(DH,$hijing_dir);
    my @tmpfiles = sort(readdir(DH));
    closedir(DH);
    my @files = ();
    foreach my $f (@tmpfiles)
    {
	if ($f =~ /0_20fm/)
	{
	    push(@files,$f);
	}
    }
    my $last_segment = -1;
    if ($files[$#files] =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	$last_segment = int($3);
    }
    else
    {
	print "cannot parse $files[$#files] for segment number\n";
	exit(1);
    }
    return $last_segment;
}
