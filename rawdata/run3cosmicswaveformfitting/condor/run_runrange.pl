#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;
use DBI;
# first cosmics run in run3cosmics: 64693
# last cosmics run (from prod): ongoing
my $outdir = sprintf("/sphenix/lustre01/sphnxpro/production2/run3cosmics/cosmics/calofitting/ana502_2025p004_v001");
my $qaoutdir = sprintf("/sphenix/data/data02/sphnxpro/production2/run3cosmics/cosmics/calofitting/ana502_2025p004_v001");
my $test;
my $incremental;
my $killexist;
my $overwrite;
my $shared;
my $events = 0;
my $verbosity = 0;
GetOptions("increment"=>\$incremental, "killexist" => \$killexist, "overwrite" => \$overwrite, "shared" => \$shared, "test"=>\$test, "verbosity:i" => \$verbosity);
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
if (! -d $outdir)
{
  mkpath($outdir);
}
if (! -d $qaoutdir)
{
    mkpath($qaoutdir);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
my $getruns = $dbh->prepare("select runnumber,segment from datasets where runnumber >= $min_runnumber and runnumber <= $max_runnumber and filename like 'DST_TRIGGERED_EVENT_seb16_run3cosmics_ana502_nocdbtag_v001-%'  order by runnumber,segment");
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $checkallsegs = $dbh->prepare("select filename from datasets where runnumber=? and segment=? and (filename like 'DST_TRIGGERED_EVENT_seb16_run3cosmics_ana502_nocdbtag_v001%' or filename like 'DST_TRIGGERED_EVENT_seb17_run3cosmics_ana502_nocdbtag_v001%')");
my $nsubmit = 0;
$getruns->execute();
while (my @runs = $getruns->fetchrow_array())
{
    my $runnumber=$runs[0];
    my $segment = $runs[1];
    my $typelike = sprintf("DST_TRIGGERED_EVENT_\%%_run3cosmics_ana502_nocdbtag_v001-\%%");
    $checkallsegs->execute($runnumber,$segment);
    my $nfiles = $checkallsegs->rows;
    if ($nfiles != 2)
    {
	print "found only $nfiles for run $runnumber, segment $segment, ignoring\n";
	next;
    }
    my $outfilename = sprintf("DST_CALOFITTING_run3cosmics_ana502_2025p004_v001-%08d-%05d.root",$runnumber,$segment);
    my $qaoutfilename1 = sprintf("HIST_COSMIC_HCALOUT_run3cosmics_ana502_2025p004_v001-%08d-%05d.root",$runnumber,$segment);
    my $qaoutfilename2 = sprintf("HIST_COSMIC_HCALIN_run3cosmics_ana502_2025p004_v001-%08d-%05d.root",$runnumber,$segment);
    $chkfile->execute($qaoutfilename1);
    if ($chkfile->rows > 0)
    {
	if ($verbosity > 0)
	{
	    print "$qaoutfilename1 exists\n";
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
	$tstflag=sprintf("%s --overwrite",$tstflag);
    }
    #    print "executing perl run_condor.pl $events $runnumber $jobno $indir $tstflag\n";

    my $subcmd = sprintf("perl run_condor.pl %d %d %d %s %s %s %s %s %s",$events, $runnumber, $segment, $outfilename, $outdir, $qaoutfilename1, $qaoutfilename2, $qaoutdir, $tstflag);
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
$getruns->finish();
$chkfile->finish();
$checkallsegs->finish();
$dbh->disconnect;

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
