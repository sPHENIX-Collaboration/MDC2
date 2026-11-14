#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

sub submitjob;

my $build;
my $incremental;
my $memory;
my $nsegs;
my $outevents = 0;
my $runnumber;
my $test;
my $verbosity = 0;
GetOptions("build:s" => \$build, "increment"=>\$incremental, "memory:s"=>\$memory, "run:i" =>\$runnumber, "segments:i" => \$nsegs, "test"=>\$test, "verbosity:i" => \$verbosity);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> \"PhotonJet5\", \"PhotonJet5Frag\", \"PhotonJet10\", \"PhotonJet10Frag\", \"PhotonJet20\", \"PhotonJet20Frag\" production>\n";
    print "parameters:\n";
    print "--build: <ana build>\n";
    print "--increment : submit jobs while processing running\n";
    print "--memory : memory requirement with unit (MB)\n";
    print "--segments: <number of input segments>\n";
    print "--run: <runnumber>\n";
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
if (! defined $nsegs)
{
    print "need number of input segments with --segments <number of input segments>\n";
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
if (
    $jettrigger  ne "PhotonJet5" &&
    $jettrigger  ne "PhotonJet5Frag" &&
    $jettrigger  ne "PhotonJet10" &&
    $jettrigger  ne "PhotonJet10Frag" &&
    $jettrigger  ne "PhotonJet20" &&
    $jettrigger  ne "PhotonJet20Frag")
{
    print "second argument has to be PhotonJet5, PhotonJet5Frag, PhotonJet10, PhotonJet10Frag, PhotonJet20 or PhotonJet20Frag\n";
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

my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log/run%d/%s",$localdir,$runnumber,$jettrigger);
if (! -d $logdir)
{
    mkpath($logdir);
}

my $filetype="Herwig";
$filetype=sprintf("%s_%s",$filetype,$jettrigger);

my $jettriggerWithDash = sprintf("%s-",$jettrigger);

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where runnumber = $runnumber and dsttype = 'G4Hits' and filename like 'G4Hits_$filetype%' order by segment") || die $DBI::errstr;
my $gethepmcfiles = $dbh->prepare("select filename,segment from datasets where runnumber = $runnumber and dsttype = 'DST_HEPMC' and filename like 'DST_HEPMC_$filetype-%' order by segment") || die $DBI::errstr;

if ($verbosity > 0)
{
    print "select filename,segment from datasets where runnumber = $runnumber and dsttype = 'G4Hits' and filename like 'G4Hits_$filetype%' order by segment\n";
}
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
my $nsubmit = 0;
my %hepmcfiles =();
$gethepmcfiles->execute();
while (my @res = $gethepmcfiles->fetchrow_array())
{
    $hepmcfiles{$res[1]} = $res[0];
}
my $max_seg = (sort { $b <=> $a } keys %hepmcfiles)[0];
print "max segment: $max_seg\n";
my $nincrement = $nsegs;
my $g4hit_seg = 0;
my $allsegs_exist = 1;
my %hepmcsave = ();
for (my $iseg=0; $iseg<=$max_seg; $iseg++)
{
    if (! exists $hepmcfiles{$iseg})
    {
	print "could not find segment $iseg in hepmc input files\n";
	$allsegs_exist = 0;
    }
    else
    {
	$hepmcsave{$iseg} =  $hepmcfiles{$iseg};
#	print "adding $hepmcsave{$iseg} to files\n";
    }
    if ($iseg == $nsegs-1)
    {
	if ($allsegs_exist > 0)
	{
	    my $listfile = sprintf("%s/condor_%s-%010d-%06d.inputlist",$logdir,$jettrigger,$runnumber,$g4hit_seg);
	    print "would submit job for segment $g4hit_seg\n";
	    open(F,">$listfile");
	    foreach my $index (sort keys %hepmcsave)
	    {
		print F "$hepmcsave{$index}\n";
		print "file $hepmcsave{$index}\n";
	    }
	    close(F);
	    my $outfilename = sprintf("G4Hits_%s-%010d-%06d.root",$filetype,$runnumber,$g4hit_seg);
	    $chkfile->execute($outfilename);
	    if ($chkfile->rows == 0)
	    {
		my $tstflag="";
		if (defined $test)
		{
		    $tstflag="--test";
		}
		if (defined $memory)
		{
		    $tstflag=sprintf("%s --memory %s",$memory);
		}
		my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %d %d %s", $outevents, $jettrigger, $listfile, $outfilename, $outdir, $build, $runnumber, $g4hit_seg, $tstflag);
		print "cmd: $subcmd\n";
		die;
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
	%hepmcsave = ();
	$allsegs_exist = 1;
	$nsegs += $nincrement;
	$g4hit_seg++;
    }
}
$getfiles->finish();
$chkfile->finish();
$dbh->disconnect;
my $jobfile = sprintf("condor.job");
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
