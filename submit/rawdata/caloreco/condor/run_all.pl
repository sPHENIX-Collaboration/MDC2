#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $test;
my $incremental;
my $overwrite;
my $shared;
my $rawdatadir = sprintf("/sphenix/lustre01/sphnxpro/commissioning/aligned_2Gprdf");
my $outsubdir = sprintf("DST_ana.387_2023p003");
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
$outdir = sprintf("%s/%s",$outdir,$outsubdir);
mkpath($outdir);

my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log",$localdir);
mkpath($logdir);

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment,runnumber from datasets where dsttype = 'beam' and filename like 'beam-%' order by runnumber,segment") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
my $icnt = 0;
my $nseg = -1;
#print "input files: $ncal, vtx: $nvtx\n";
foreach (my @res = $getfiles->fetchrow_array())
{
    my $lfn = $res[0];
    my $segment = $res[1];
    my $runnumber = $res[2];
    $icnt++;
    my $outfilename = sprintf("DST_CALOR-%08d-%04d.root",$runnumber,$segment);

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
    my $subcmd = sprintf("perl run_condor.pl %d %d %d %s %s %s %s %s", $outevents, $runnumber, $segment, $lfn, $rawdatadir, $outfilename, $outdir, $tstflag);

#	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %d %d %s", $outevents, $lfn, $vtxhash{sprintf("%05d",$segment)}, $outfilename, $outdir, $outrunnumber, $segment, $tstflag);
    print "cmd: $subcmd\n";
#    system($subcmd);
    system("true");
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
$getfiles->finish();
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
