#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber = 10;
my $test;
my $incremental;
my $shared;
my $overwrite;
GetOptions("test"=>\$test, "increment"=>\$incremental, "overwrite" => \$overwrite, "shared" => \$shared);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Jet10\", \"Jet20\", \"Jet30\", \"Jet40\",\"PhotonJet\" production>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--overwrite : overwrite existing job files\n";
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
    $jettrigger  ne "Jet20" &&
    $jettrigger  ne "Jet30" &&
    $jettrigger  ne "Jet40" &&
    $jettrigger  ne "PhotonJet")
{
    print "second argument has to be Jet10, Jet30 or PhotonJet";
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
my @outdir = ();
open(F,"outdir.txt");
while (my $line = <F>)
{
    chomp $line;
    $line = sprintf("%s/run%04d/%s",$line,$runnumber,lc $jettrigger);
    if (! -d $line)
    {
	mkpath($line);
    }
    push(@outdir,$line);
}
close(F);
my $jettriggerWithUnderScore = sprintf("%s-",$jettrigger);


my %outfiletype = ();
$outfiletype{"DST_CALO_CLUSTER"} = $outdir[0];
$outfiletype{"DST_MBD_EPD"} = $outdir[1];
$outfiletype{"DST_TRKR_HIT"} = $outdir[2];
$outfiletype{"DST_TRUTH"} = $outdir[2];
foreach my $type (sort keys %outfiletype)
{
    print "type $type, dir: $outfiletype{$type}\n";
} 
#die;
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename from datasets where dsttype = 'G4Hits' and filename like 'G4Hits_pythia8_$jettriggerWithUnderScore%' and runnumber = $runnumber order by filename") || die $DBI::errstr;
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
            my $lfn =  sprintf("%s_pythia8_%s-%010d-%05d.root",$type,$jettrigger,$runnumber,$segment);
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
	if (defined $overwrite)
	{
	    $tstflag= sprintf("%s --overwrite", $tstflag)
	}

	my $calooutfilename = sprintf("DST_CALO_CLUSTER_pythia8_%s-%010d-%05d.root",$jettrigger,$runnumber,$segment);
	my $globaloutfilename = sprintf("DST_MBD_EPD_pythia8_%s-%010d-%05d.root",$jettrigger,$runnumber,$segment);
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %s %d %d %s", $outevents, $jettrigger, $lfn, $calooutfilename, $outdir[0], $globaloutfilename, $outdir[1], $outdir[2], $runnumber, $segment, $tstflag);
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
	if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit >= 20000 )
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
