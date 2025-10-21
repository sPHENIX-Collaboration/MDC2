#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;
use DBI;
# first physics run in run3auau: 53881
# last physics run (from prod): 56000
my $outdir = sprintf("/sphenix/lustre01/sphnxpro/production2/run3auau/physics/ana516_nocdbtag_v001");
my $test;
my $incremental;
my $killexist;
my $overwrite;
my $shared;
my $events = 0;
GetOptions("increment"=>\$incremental, "killexist" => \$killexist, "overwrite" => \$overwrite, "shared" => \$shared, "test"=>\$test);
if ($#ARGV < 1)
{
    print "usage: run_runrange.pl <min runnumber> <max runnumber>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--killexist : delete output file if it already exists (but no jobfile)\n";
    print "--overwrite : overwrite existing job files\n";
    print "--shared : submit jobs to shared pool\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}
open(F,"donotprocess.runs");
my %donotprocess = ();
while (my $brline = <F>)
{
    chomp $brline;
    my @sp1 = split(/ /,$brline);
	$donotprocess{$sp1[0]} = 1;
}
my $maxsubmit = 0;
my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxprod/)
{
    print "submit only from phnxprod hosts\n";
    exit(1);
}

my $min_runnumber = $ARGV[0];
my $max_runnumber = $ARGV[1];
my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log",$localdir);

my $condorlistfile =  sprintf("condor.list");
if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

my $dbh = DBI->connect("dbi:ODBC:daq","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $dbh2 = DBI->connect("dbi:ODBC:RawDataCatalog_read","phnxrc") || die $DBI::errstr;
$dbh2->{LongReadLen}=2000; # full file paths need to fit in here

my $getruns = $dbh->prepare("select runnumber from run where runnumber>= $min_runnumber and runnumber <= $max_runnumber and runtype='physics' and eventsinrun >= 100000 and EXTRACT(EPOCH FROM (ertimestamp-brtimestamp)) >= 300 order by runnumber");
my $gethosts = $dbh->prepare("select hostname from hostinfo where runnumber = ? and hostname like 'seb%'");
my $fullrun = $dbh->prepare("select distinct(transferred_to_sdcc) from filelist where runnumber = ? and sequence > 0 and hostname like 'seb%'");
my $getdaqsegs = $dbh->prepare("select count(*),hostname from filelist where runnumber = ? group by hostname");
my $getrawsegs = $dbh2->prepare("select count(*),daqhost from datasets where runnumber = ? and status > 0 group by daqhost");
my $getrawsegsfirst = $dbh2->prepare("select daqhost from datasets where runnumber = ? and segment=0 and status > 0");
my $nsubmit = 0;
$getruns->execute();
while (my @runs = $getruns->fetchrow_array())
{
    my $runnumber=$runs[0];
    if (exists $donotprocess{$runnumber})
    {
	print "ignoring run $runnumber from donotprocess.runs\n";
	next;
    }
    my %goodtogo = ();
    my $fullruntransferred = 0;
    $fullrun->execute($runnumber);
    my $ntfstat =  $fullrun->rows;
    if ($ntfstat > 1) # find t and f for segment > 0 -->  transfer ongoing
    {
	print "run $runnumber is still being transferred\n";
	next; # transfer not done yet, since we need all segments anyway for the event combining
    }
    elsif ($ntfstat == 0)
    {
	print "run $runnumber has only 0th segment\n";
	    $getrawsegsfirst->execute($runnumber);
	    while (my @res = $getrawsegsfirst->fetchrow_array())
	    {
		$goodtogo{$res[0]} = 1;
	    }
    }
    else
    {
        my @tstat = $fullrun->fetchrow_array();
	if ($tstat[0] == 0)
	{
	    print "single file transfer for run $runnumber\n";
	    $getrawsegsfirst->execute($runnumber);
	    while (my @res = $getrawsegsfirst->fetchrow_array())
	    {
		$goodtogo{$res[0]} = 1;
	    }
	}
	else
	{
	    print "all files transferred for run $runnumber\n";
	    my %daqfiles = ();
	    $getdaqsegs->execute($runnumber);
	    while (my @res = $getdaqsegs->fetchrow_array())
	    {
		$daqfiles{$res[1]} = $res[0];
	    }
	    $getrawsegs->execute($runnumber);
	    while (my @res = $getrawsegs->fetchrow_array())
	    {
		if ($daqfiles{$res[1]} == $res[0])
		{
		    $goodtogo{$res[1]} = 1;
		}
	    }
	}
	if (! exists $goodtogo{"gl1daq"})
	{
	    print "not all GL1 files for $runnumber on disk\n";
	    next;
	}
    }
    $gethosts->execute($runnumber);
    while (my @res = $gethosts->fetchrow_array())
    {
	my $daqhost = $res[0];
	# seb19 is the ll1, that needs special packet handling which we dont have yet
	if ($daqhost =~ /seb19/)
	{
	    next;
	}
	if (! exists $goodtogo{$res[0]})
	{
	    if ($ntfstat == 0)
	    {
		print "not zeroth segment for run $runnumber from $res[0] on disk yet\n";
	    }
	    else
	    {
	    print "not all files for run $runnumber from $res[0] on disk yet\n";
	    }
	    next;
	}
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	if (defined $overwrite)
	{
	    $tstflag= sprintf("%s --overwrite", $tstflag)
	}
	#    print "executing perl run_condor.pl $events $runnumber $jobno $indir $tstflag\n";

	my $subcmd = sprintf("perl run_condor.pl %d %d %s %s %s",$events, $runnumber, $daqhost, $outdir, $tstflag);
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
	    print "maximum number of submissions reached $nsubmit, submitting\n";
	    last;
	}
    }
}

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
