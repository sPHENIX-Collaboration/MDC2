#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $build;
my $disable_calo;
my $disable_mbd;
my $disable_trk;
my $incremental;
my $memory;
my $overwrite;
my $runnumber;
my $shared;
my $test;
GetOptions("build:s" => \$build, "disable_calo" => \$disable_calo, "disable_mbd" => \$disable_mbd, "disable_trk" => \$disable_trk, "increment"=>\$incremental, "memory:s"=>\$memory, "overwrite"=>\$overwrite, "run:i" =>\$runnumber, "shared" => \$shared, "test"=>\$test);
if ($#ARGV < 0 || ! defined $runnumber || ! defined $build)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--disable_calo: disable cal reconstruction\n";
    print "--disable_mbd: disable mbd reconstruction\n";
    print "--disable_trk: disable trk reconstruction\n";
    print "--increment : submit jobs while processing running\n";
    print "--memory : memory requirement with unit (MB)\n";
    print "--run: <runnumber>\n";
    print "--shared : submit jobs to shared pool\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}

my $enable_calo = 0;
my $enable_mbd = 0;
my $enable_trk = 0;

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

my $condorlistfile =  sprintf("condor.list");
if (-f $condorlistfile)
{
    unlink $condorlistfile;
}

my @outdir = ();
open(F,"outdir.txt");
while (my $line = <F>)
{
    chomp $line;
    $line = sprintf("%s/run%04d",$line,$runnumber);
    if (! -d $line)
    {
      mkpath($line);
    }
    push(@outdir,$line);
}
close(F);


my %outfiletype = ();
if (! defined $disable_calo)
{
    $enable_calo = 1;
    $outfiletype{"DST_CALO_CLUSTER"} = $outdir[0];
}
if (! defined $disable_mbd)
{
    $enable_mbd = 1;
    $outfiletype{"DST_MBD_EPD"} = $outdir[1];
}
if (! defined $disable_trk)
{
    $enable_trk = 1;
    $outfiletype{"DST_TRKR_HIT"} = $outdir[2];
    $outfiletype{"DST_TRUTH"} = $outdir[2];
}

foreach my $type (sort keys %outfiletype)
{
    print "type $type, dir: $outfiletype{$type}\n";
} 
#die;
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename from datasets where dsttype = 'G4Hits' and filename like '%ampt_0_20fm%' and runnumber = $runnumber order by segment") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
while (my @res = $getfiles->fetchrow_array())
{
    my $lfn = $res[0];
#    print "found $lfn\n";
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
        my $foundall = 1;
	foreach my $type (sort keys %outfiletype)
	{
            my $lfn =  sprintf("%s_ampt_0_20fm-%010d-%06d.root",$type,$runnumber,$segment);
#            print "checking for $lfn\n";
	    $chkfile->execute($lfn);
	    if ($chkfile->rows > 0)
	    {
		next;
	    }
	    else
	    {
		$foundall = 0;
		last;
	    }
	}
	if ($foundall == 1)
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
        if (defined $memory)
        {
            $tstflag = sprintf("%s %s",$tstflag,$memory);
        }
	my $calooutfilename = sprintf("DST_CALO_CLUSTER_ampt_0_20fm-%010d-%06d.root",$runnumber,$segment);
	my $globaloutfilename = sprintf("DST_MBD_EPD_ampt_0_20fm-%010d-%06d.root",$runnumber,$segment);
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %s %d %d %d %d %d %s", $outevents, $lfn, $calooutfilename, $outdir[0], $globaloutfilename, $outdir[1], $outdir[2], $build, $runnumber, $segment, $enable_calo, $enable_mbd, $enable_trk, $tstflag);
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
	    print "maximum number of submissions $nsubmit reached, exiting\n";
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
