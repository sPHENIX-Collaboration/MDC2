#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;
use DBI;
# first physics run in run2pp: 47289
# last physics run (from prod): 53880
my $outdir = sprintf("/sphenix/lustre01/sphnxpro/production2/run2pp/physics/caloy2calib/new_newcdbtag_v007");
my $qaoutdir = sprintf("/sphenix/data/data02/sphnxpro/production2/run2pp/physics/caloy2calib/new_newcdbtag_v007");
my $events = 0;
my $incremental;
my $killexist;
my $overwrite;
my $shared;
my $test;
my $verbosity = 0;
GetOptions("increment"=>\$incremental, "killexist" => \$killexist, "overwrite" => \$overwrite, "shared" => \$shared, "test"=>\$test, "verbosity:i" => \$verbosity);
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
my $getruns = $dbh->prepare("select runnumber,segment,filename from datasets where runnumber >= $min_runnumber and runnumber <= $max_runnumber and filename like 'DST_CALOFITTING_run2pp_new_newcdbtag_v007-%' order by runnumber,segment");
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $nsubmit = 0;
$getruns->execute();
while (my @runs = $getruns->fetchrow_array())
{
    my $runnumber=$runs[0];
    my $segment = $runs[1];
    my $lfn = $runs[2];
    my $outfilename = sprintf("DST_CALO_run2pp_new_newcdbtag_v007-%08d-%05d.root",$runnumber,$segment);
    my $qaoutfilename = sprintf("HIST_CALOQA_run2pp_new_newcdbtag_v007-%08d-%05d.root",$runnumber,$segment);
    $chkfile->execute($outfilename);
    if ($chkfile->rows > 0)
    {
	if ($verbosity > 0)
	{
	    print "$outfilename exists\n";
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

    my $subcmd = sprintf("perl run_condor.pl %d %d %d %s %s %s %s %s %s",$events, $runnumber, $segment, $lfn, $outfilename, $outdir, $qaoutfilename, $qaoutdir, $tstflag);
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
