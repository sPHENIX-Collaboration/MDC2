#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $build;
my $incremental;
my $memory;
my $outevents = 0;
my $runnumber;
my $shared;
my $test;
my $verbosity = 0;
GetOptions("build:s" => \$build, "increment"=>\$incremental, "memory:s"=>\$memory, "run:i" =>\$runnumber, "shared" => \$shared, "test"=>\$test, "verbosity:i" => \$verbosity);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\">, <\"Jet15\">, <\"Jet30\">, <\"Jet40\">, <\"Jet50\">, \"PhotonJet\">, \"PhotonJet5\">, \"PhotonJet10\">, \"PhotonJet20\">, \"Detroit\">  production>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--increment : submit jobs while processing running\n";
    print "--memory : memory requirement with unit (MB)\n";
    print "--run: <runnumber>\n";
    print "--shared : submit jobs to shared pool\n";
    print "--test : dryrun - create jobfiles\n";
    print "--verbosity : <level>\n";
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

my $maxsubmit = $ARGV[0];
my $jettrigger = $ARGV[1];
if ($jettrigger  ne "Jet10" &&
    $jettrigger  ne "Jet15" &&
    $jettrigger  ne "Jet20" &&
    $jettrigger  ne "Jet30" &&
    $jettrigger  ne "Jet40" &&
    $jettrigger  ne "Jet50" &&
    $jettrigger  ne "PhotonJet" &&
    $jettrigger  ne "PhotonJet5" &&
    $jettrigger  ne "PhotonJet10" &&
    $jettrigger  ne "PhotonJet20" &&
    $jettrigger  ne "Detroit")
{
    print "second argument has to be Jet10, Jet15, Jet20, Jet30, Jet40, Jet50, PhotonJet, PhotonJet5, PhotonJet10, PhotonJet20 or Detroit\n";
     exit(1);
}

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

my $jettriggerWithDash = sprintf("%s-",$jettrigger);

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'G4Hits' and filename like '%pythia8_$jettriggerWithDash%' and runnumber = $runnumber order by segment") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
while (my @res = $getfiles->fetchrow_array())
{
    my $lfn = $res[0];
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
        my $runnumber = int($2);
        my $segment = int($3);
        my $outfilename = sprintf("DST_TRUTH_JET_pythia8_%s-%010d-%06d.root",$jettrigger,$runnumber,$segment);
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
        my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %d %d %s", $outevents, $jettrigger, $lfn, $outfilename, $outdir, $build, $runnumber, $segment, $tstflag);
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
            print "maximum number of submissions $nsubmit reached, submitting\n";
            last;
        }
    }
}
$getfiles->finish();
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
