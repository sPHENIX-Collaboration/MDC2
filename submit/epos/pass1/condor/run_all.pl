#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;
use DBI;

sub getlastsegment;

my $build;
my $events = 1000;
my $incremental;
my $memory;
my $runnumber;
my $system;
my $test;
GetOptions("build:s" => \$build, "events:i"=>\$events, "increment"=>\$incremental, "memory:s"=>\$memory, "run:i" =>\$runnumber, "system:s"=>\$system, "test"=>\$test);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--events: <number of event>\n";
    print "--increment : submit jobs while processing running\n";
    print "--memory: <memory in MB like 8000MB>\n";
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

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $maxsubmit = $ARGV[0];
my $epos4_runnumber = 1;
my $epos4_dir = sprintf("/sphenix/lustre01/sphnxpro/mdc2/EPOS4/%s",$system);
if (! -d $epos4_dir)
{
    print "could not locate $epos4_dir\n";
    exit(1);
}

my $evtsperfile = 10000;
if ($system eq "OO")
{
    $evtsperfile = 1000;
}

my $nmax = $evtsperfile;

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
$outdir = sprintf("%s/%s/run%04d",$outdir,$system,$runnumber);
if (! -d $outdir)
{
    mkpath($outdir);
}

my $nsubmit = 0;
my $lastsegment=getlastsegment();
OUTER: for (my $segment=0; $segment<=$lastsegment; $segment++)
{
    my $epos4datfile = sprintf("%s/EPOS4_%s_200GeV-%010d-%06d.hepmc",$epos4_dir,$system,$epos4_runnumber, $segment);
    if (! -f $epos4datfile)
    {
	my $uncomp = $epos4datfile;
	$epos4datfile = sprintf("%s.gz",$epos4datfile);
	if (! -f $epos4datfile)
	{
	    print "could not locate $uncomp or $epos4datfile\n";
	    next;
	}
    }
#    print "epos4: $epos4datfile, nmax: $nmax, events $events\n";
    my $sequence = $segment*$evtsperfile/$events;
    for (my $n=0; $n<$nmax; $n+=$events)
    {
	my $outfile = sprintf("G4Hits_EPOS4_%s_200GeV-%010d-%06d.root",$system,$runnumber,$sequence);
	$chkfile->execute($outfile);
	if ($chkfile->rows == 0)
	{
	    my $tstflag="";
	    if (defined $test)
	    {
		$tstflag="--test";
	    }
	    if (defined $memory)
	    {
		$tstflag = sprintf("%s --memory %s",$tstflag,$memory)
	    }
	    my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %d %s %d %d %s %s", $events, $epos4datfile, $outdir, $outfile, $n, $build, $runnumber, $sequence, $system, $tstflag);
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
    opendir(DH,$epos4_dir);
    my @tmpfiles = sort(readdir(DH));
    closedir(DH);
    my @files = ();
    my $compstr = sprintf("EPOS4_%s",$system);
    foreach my $f (@tmpfiles)
    {
	if ($f =~ /$compstr/)
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
