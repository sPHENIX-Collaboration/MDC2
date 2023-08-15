#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber = 6;
my $nparticle=10;
my $test;
my $incremental;
GetOptions("test"=>\$test, "increment"=>\$incremental, "nparticle"=>\$nparticle);
if ($#ARGV < 3)
{
    print "usage: run_all.pl <number of jobs> <particle> <ptmin> <ptmax>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--nparticle : number of particles per event (default = 10)\n";
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
my $particle = lc $ARGV[1];
my $ptmin = $ARGV[2];
my $ptmax = $ARGV[3];

my $embedfilelike = sprintf("sHijing_0_20fm");
my $outfilelike = sprintf("single_%s_p_%d_%dMeV_%s",$particle,$ptmin,$ptmax,$embedfilelike);

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
$outdir = sprintf("%s/run%04d/%s",$outdir,$runnumber, lc $particle);
mkpath($outdir);

my %outfiletype = ();
$outfiletype{"DST_BBC_G4HIT"} = 1;
$outfiletype{"DST_CALO_G4HIT"} = 1;
$outfiletype{"DST_TRKR_G4HIT"} = 1;
$outfiletype{"DST_TRUTH_G4HIT"} = 1;

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $nsubmit = 0;

my %trkhash = ();
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'G4Hits' and filename like 'G4Hits_$embedfilelike%' and runnumber = $runnumber order by filename") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
$getfiles->execute() || die $DBI::errstr;
my $ncal = $getfiles->rows;
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
            my $lfn =  sprintf("%s_%s-%010d-%05d.root",$type,$outfilelike,$runnumber,$segment);
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %d %d %d %s %s %d %d %s", $outevents, $particle, $ptmin, $ptmax, $nparticle, $lfn, $outdir, $runnumber, $segment, $tstflag);
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

$chkfile->finish();
$getfiles->finish();
$dbh->disconnect;

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
