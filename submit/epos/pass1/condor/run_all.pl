#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;
use DBI;

sub getlastsegment;

my $test;
my $incremental;
GetOptions("test"=>\$test, "increment"=>\$incremental);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
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

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;

my $maxsubmit = $ARGV[0];
my $epos_runnumber = 1;
my $epos_dir = sprintf("/sphenix/sim/sim01/sphnxpro/mdc2/EPOS/AuAu");
my $runnumber = 10;
my $events = 400;
#$events = 100; # for ftfp_bert_hp
my $evtsperfile = 400;
my $nmax = $evtsperfile;

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

my $nsubmit = 0;
my $lastsegment=getlastsegment();
OUTER: for (my $segment=0; $segment<=$lastsegment; $segment++)
{
    my $eposdatfile = sprintf("%s/EPOS_AuAu-%010d-%05d.dat",$epos_dir,$epos_runnumber, $segment);
    if (! -f $eposdatfile)
    {
	print "could not locate $eposdatfile\n";
	next;
    }
#    print "epos: $eposdatfile, nmax: $nmax, events $events\n";
    my $sequence = $segment*$evtsperfile/$events;
    for (my $n=0; $n<$nmax; $n+=$events)
    {
	my $outfile = sprintf("G4Hits_EPOS-%010d-%06d.root",$runnumber,$sequence);
	$chkfile->execute($outfile);
	if ($chkfile->rows == 0)
	{
	    my $tstflag="";
	    if (defined $test)
	    {
		$tstflag="--test";
	    }
	    system("perl run_condor.pl $events $eposdatfile $outdir $outfile $n $runnumber $sequence $tstflag");
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
	    if ($nsubmit >= $maxsubmit || $nsubmit >= 20000)
	    {
		print "maximum number of submissions reached, exiting\n";
		last OUTER;
	    }
	}
#	else
#	{
#	    print "$outfile exists\n";
#	}
        $sequence++;
    }
}

if (-f $condorlistfile)
{
    if (defined $test)
    {
	print "would submit condor.job\n";
    }
    else
    {
	system("condor_submit condor.job");
    }
}

sub getlastsegment()
{
    opendir(DH,$epos_dir);
    my @tmpfiles = sort(readdir(DH));
    closedir(DH);
    my @files = ();
    foreach my $f (@tmpfiles)
    {
	if ($f =~ /EPOS_AuAu/)
	{
	    push(@files,$f);
	}
    }
    my $last_segment = -1;
    if ($files[$#files] =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	$last_segment = int($3);
    }
    else
    {
	print "cannot parse $files[$#files] for segment number\n";
	exit(1);
    }
    return $last_segment;
}