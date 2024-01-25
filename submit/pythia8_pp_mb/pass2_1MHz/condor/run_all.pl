#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber = 111;
my $test;
my $incremental;
my $shared;
GetOptions("test"=>\$test, "increment"=>\$incremental, "shared" => \$shared);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--shared : submit jobs to shared pool\n";
    print "--test : dryrun - create jobfiles\n";
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
$outdir = sprintf("%s/run%04d",$outdir,$runnumber);
mkpath($outdir);

my %outfiletype = ();
$outfiletype{"DST_BBC_G4HIT"} = 1;
$outfiletype{"DST_CALO_G4HIT"} = 1;
$outfiletype{"DST_TRKR_G4HIT"} = 1;
$outfiletype{"DST_TRUTH_G4HIT"} = "DST_TRUTH";

my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log/run%d",$localdir,$runnumber);
if (! -d $logdir)
{
  mkpath($logdir);
}
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename from datasets where dsttype = 'G4Hits' and filename like '%pythia8_pp_mb%' and runnumber = $runnumber order by segment") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $getbkglastsegment = $dbh->prepare("select max(segment) from datasets where dsttype = 'G4Hits' and filename like '%pythia8_pp_mb%' and runnumber = $runnumber");
$getbkglastsegment->execute();
my @res1 = $getbkglastsegment->fetchrow_array();
my $lastsegment = $res1[0];
$getbkglastsegment->finish();

my $nsubmit = 0;
$getfiles->execute() || die $DBI::errstr;
while (my @res = $getfiles->fetchrow_array())
{
    my $lfn = $res[0];
#    print "found $lfn\n";
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
        my $prefix=$1;
	my $runnumber = int($2);
	my $segment = int($3);
	my $foundall = 1;
	foreach my $type (sort keys %outfiletype)
	{
	    my $lfn = sprintf("%s_pythia8_pp_mb_1MHz-%010d-%05d.root",$type,$runnumber,$segment);
		$chkfile->execute($lfn);
		if ($chkfile->rows > 0)
		{
		    next;
		}
		else
		{
		my $newlfn = $outfiletype{$type};
		if ($newlfn ne "1")
		{
		    $lfn =~ s/$type/$outfiletype{$type}/;
		    $chkfile->execute($lfn);
		    if ($chkfile->rows > 0)
		    {
			next;
		    }
		}
		$foundall = 0;
		last;
	    }
	}
	if ($foundall == 1)
	{
	    next;
	}
# output file does not exist yet, check for 2 MB background files (n to n+1)
	$foundall = 1;
	my @bkgfiles = ();
	my $bkgsegments = 0;
	my $currsegment = $segment;
	while ($bkgsegments <= 999)
	{
	    $currsegment++;
	    if ($currsegment > $lastsegment)
	    {
		$currsegment = 0;
	    }
	    my $bckfile = sprintf("%s-%010d-%05d.root",$prefix,$runnumber,$currsegment);
	    $chkfile->execute($bckfile);
	    if ($chkfile->rows == 0)
	    {
		print "missing bkg $bckfile\n";
		$foundall = 0;
	    }
	    else
	    {
		$bkgsegments++;
		push(@bkgfiles,$bckfile);
	    }
	}
	if ($foundall == 0)
	{
	    next;
	}
	my $bkglistfile = sprintf("%s/condor_1MHz-%010d-%05d.bkglist",$logdir,$runnumber,$segment);
	open(F1,">$bkglistfile");
	foreach my $bf (@bkgfiles)
	{
	    print F1 "$bf\n";
	}
	close(F1);
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %d %d %s", $outevents, $lfn, $bkglistfile, $outdir, $runnumber, $segment, $tstflag);
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
	if (($maxsubmit != 0 && $nsubmit >= $maxsubmit) || $nsubmit > 20000)
	{
	    print "maximum number of submissions reached, exiting\n";
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
