#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber=40;
my $test;
my $incremental;
my $overwrite;
my $shared;
GetOptions("test"=>\$test, "increment"=>\$incremental, "overwrite"=>\$overwrite, "shared" => \$shared);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\", \"Jet30\", \"PhotonJet\" production>\n";
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
my $jettrigger = $ARGV[1];
if ($jettrigger  ne "Jet10" &&
    $jettrigger  ne "Jet30" &&
    $jettrigger  ne "PhotonJet")
{
    print "second argument has to be Jet10, Jet30 or PhotonJet\n";
    exit(1);
}

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
$outdir = sprintf("%s/%s",$outdir,lc $jettrigger);
if ($outdir =~ /lustre/)
{
    my $storedir = $outdir;
    $storedir =~ s/\/sphenix\/lustre01\/sphnxpro/sphenixS3/;
    my $makedircmd = sprintf("mcs3 mb %s",$storedir);
    system($makedircmd);
}
else
{
  mkpath($outdir);
}

$jettrigger = sprintf("%s_3MHz",$jettrigger);

my %calohash = ();
my %trackhash = ();

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_CLUSTER' and filename like '%pythia8_$jettrigger%' and runnumber = $runnumber order by filename") || die $DBI::error;
#print "select filename,segment from datasets where dsttype = 'DST_CALO_CLUSTER' and filename like '%pythia8_$jettrigger%' and runnumber = $runnumber order by filename\n";

my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::error;
my $gettrackfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRACKS' and filename like '%pythia8_$jettrigger%' and runnumber = $runnumber");
my $nsubmit = 0;
$getfiles->execute() || die $DBI::error;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    $calohash{sprintf("%05d",$res[1])} = $res[0];
}
$getfiles->finish();
$gettrackfiles->execute() || die $DBI::error;
my $ntrack = $gettrackfiles->rows;
while (my @res = $gettrackfiles->fetchrow_array())
{
    $trackhash{sprintf("%05d",$res[1])} = $res[0];
}
$gettrackfiles->finish();
print "input files: $ncal, track: $ntrack\n";
foreach my $segment (sort keys %calohash)
{
    if (! exists $trackhash{$segment})
    {
	next;
    }

    my $lfn = $calohash{$segment};
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_JETS_pythia8_%s-%010d-%05d.root",$jettrigger,$runnumber,$segment);
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %d %d %s", $outevents, $jettrigger, $lfn, $trackhash{sprintf("%05d",$segment)}, $outfilename, $outdir, $runnumber, $segment, $tstflag);
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
	if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit >20000)
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
