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
my $type = "MB";
GetOptions("build:s" => \$build, "increment"=>\$incremental, "run:i" =>\$runnumber, "test"=>\$test);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\", \"Jet30\", \"MB\" production>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--increment : submit jobs while processing running\n";
    print "--run: <runnumber>\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}
my $isbad = 0;

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxsub/)
{
    print "submit only from phnxsub hosts\n";
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
my $filetype="Herwig";
if ($jettrigger  ne "Jet10" &&
    $jettrigger  ne "Jet30" &&
    $jettrigger  ne "MB")
{
    print "second argument has to be Jet10, Jet30 or MB\n";
    exit(1);
}
#if ($maxsubmit > 50000)
#{
#    print "beware of gpfs overload, you sure you want to run $maxsubmit jobs?\n";
#    exit(0);
#}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $herwig_runnumber = 1;
my $herwig_dir = sprintf("/sphenix/sim/sim01/sphnxpro/mdc2/herwig");
my $events = 1000; # for running with plugdoor
#$events = 200;
#$events = 100; # for ftfp_bert_hp
my $evtsperfile = 1000;
my $nmax = $evtsperfile;

$filetype=sprintf("%s_%s",$filetype,$jettrigger);
my $condorlistfile =  sprintf("condor.list");
if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

my $outdir = `cat outdir.txt`;
chomp $outdir;
$outdir = sprintf("%s/run%04d/%s",$outdir,$runnumber,lc $jettrigger);
if (! -d $outdir)
{
    mkpath($outdir);
}
my $nsubmit = 0;
my $lastsegment=getlastsegment();
OUTER: for (my $segment=0; $segment<=$lastsegment; $segment++)
{
    my $herwigdatfile = sprintf("%s/%s/%s_filtered-%06d.hepmc",$herwig_dir,$filetype,$filetype,$segment);
    if (! -f $herwigdatfile)
    {
	print "could not locate $herwigdatfile\n";
	next;
    }
#    print "herwig: $herwigdatfile\n";
    my $sequence = $segment*$evtsperfile/$events;
    for (my $n=0; $n<$nmax; $n+=$events)
    {
	my $outfile = sprintf("G4Hits_%s-%010d-%06d.root",$filetype,$runnumber,$sequence);
	$chkfile->execute($outfile);
	if ($chkfile->rows == 0)
	{
	    my $tstflag="";
	    if (defined $test)
	    {
		$tstflag="--test";
	    }
            my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %d %s %s %d %d %s", $events, $herwigdatfile, $outdir, $outfile, $n, $build, $jettrigger, $runnumber, $sequence, $tstflag);
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
    my $herwigsubdir = sprintf("%s/%s",$herwig_dir,$filetype);
    opendir(DH,$herwigsubdir);
    my @tmpfiles = sort(readdir(DH));
    closedir(DH);
    my @files = ();
    foreach my $f (@tmpfiles)
    {
	if ($f =~ /$jettrigger/)
	{
	    push(@files,$f);
	}
    }
    my $last_segment = -1;
    if ($files[$#files] =~ /(\S+)-(\d+).*\..*/ )
    {
	$last_segment = int($2);
    }
    else
    {
	print "cannot parse $files[$#files] for segment number\n";
	exit(1);
    }
    return $last_segment;
}
