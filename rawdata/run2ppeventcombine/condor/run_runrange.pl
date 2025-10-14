#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;
use DBI;
# first physics run in run2pp: 47289
# last physics run (from prod): 53880
my $outdir = sprintf("/sphenix/lustre01/sphnxpro/production2/run2pp/physics/ana502_nocdbtag_v001");
my $test;
my $incremental;
my $killexist;
my $shared;
my $events = 0;
GetOptions("increment"=>\$incremental, "killexist" => \$killexist, "shared" => \$shared, "test"=>\$test);
if ($#ARGV < 1)
{
    print "usage: run_runrange.pl <min runnumber> <max runnumber>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--killexist : delete output file if it already exists (but no jobfile)\n";
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
my $getruns = $dbh->prepare("select runnumber from run where runnumber>= $min_runnumber and runnumber <= $max_runnumber and runtype='physics' and eventsinrun >= 100000 and EXTRACT(EPOCH FROM (ertimestamp-brtimestamp)) > 300 order by runnumber");
my $gethosts = $dbh->prepare("select hostname from hostinfo where runnumber = ? and hostname like 'seb%'");
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
    $gethosts->execute($runnumber);
    while (my @res = $gethosts->fetchrow_array())
    {
	my $daqhost = $res[0];
	# seb19 is the ll1, that needs special packet handling which we dont have yet
	if ($daqhost =~ /seb19/)
	{
	    next;
	}
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
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
