#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber = 6;
my $test;
my $incremental;
my $particle = "pi";
my $filetype = "single";
GetOptions("test"=>\$test, "increment"=>\$incremental);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs> <pmin> <pmax>\n";
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
my $maxsubmit = $ARGV[0];
my $pmin = $ARGV[1];
my $pmax = $ARGV[2];
my $partprop = sprintf("%s_%s_%d_%dMeV",$filetype,$particle,$pmin,$pmax);

my $embedfilelike = sprintf("sHijing_0_20fm_50kHz_bkg_0_20fm");
my $outfilelike = sprintf("%s_%s",$partprop,$embedfilelike);

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
$outdir = sprintf("%s/%s",$outdir,lc $particle);
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


my %outfiletype = ();
$outfiletype{"DST_BBC_G4HIT"} = 1;
$outfiletype{"DST_CALO_G4HIT"} = 1;
$outfiletype{"DST_TRKR_G4HIT"} = 1;
$outfiletype{"DST_TRUTH_G4HIT"} = 1;
$outfiletype{"DST_VERTEX"} = 1;

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $nsubmit = 0;

my %trkhash = ();
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRKR_G4HIT' and filename like 'DST_TRKR_G4HIT_$embedfilelike%' and runnumber = $runnumber order by filename") || die $DBI::errstr;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::errstr;
$getfiles->execute() || die $DBI::errstr;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    $trkhash{sprintf("%05d",$res[1])} = $res[0];
}
$getfiles->finish();

my %truthhash = ();
my $gettruthfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_TRUTH_G4HIT' and filename like 'DST_TRUTH_G4HIT_$embedfilelike%' and runnumber = $runnumber");
$gettruthfiles->execute() || die $DBI::errstr;
my $ntruth = $gettruthfiles->rows;
while (my @res = $gettruthfiles->fetchrow_array())
{
    $truthhash{sprintf("%05d",$res[1])} = $res[0];
}
$gettruthfiles->finish();

my %bbchash = ();
my $getbbcfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_BBC_G4HIT' and filename like 'DST_BBC_G4HIT_$embedfilelike%' and runnumber = $runnumber");
$getbbcfiles->execute() || die $DBI::errstr;
my $nbbc = $getbbcfiles->rows;
while (my @res = $getbbcfiles->fetchrow_array())
{
    $bbchash{sprintf("%05d",$res[1])} = $res[0];
}
$getbbcfiles->finish();

my %calohash = ();
my $getcalofiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_G4HIT' and filename like 'DST_CALO_G4HIT_$embedfilelike%' and runnumber = $runnumber");
$getcalofiles->execute() || die $DBI::errstr;
my $ncalo = $getcalofiles->rows;
while (my @res = $getcalofiles->fetchrow_array())
{
    $calohash{sprintf("%05d",$res[1])} = $res[0];
}
$getcalofiles->finish();

my %vertexhash = ();
my $getvertexfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_VERTEX' and filename like 'DST_VERTEX_$embedfilelike%' and runnumber = $runnumber");
$getvertexfiles->execute() || die $DBI::errstr;
my $nvertex = $getvertexfiles->rows;
while (my @res = $getvertexfiles->fetchrow_array())
{
    $vertexhash{sprintf("%05d",$res[1])} = $res[0];
}
$getvertexfiles->finish();


#print "input files: $ncal, truth: $ntruth\n";
foreach my $segment (sort keys %trkhash)
{
    if (! exists $bbchash{$segment})
    {
	next;
    }
    if (! exists $calohash{$segment})
    {
	next;
    }
    if (! exists $truthhash{$segment})
    {
	next;
    }
    if (! exists $vertexhash{$segment})
    {
	next;
    }

    my $lfn = $trkhash{$segment};
#    print "found $lfn\n";
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
        my $foundall = 1;
        my $ntupoutfile =  sprintf("CALIB_EMC_%s-%010d-%05d.root",$outfilelike,$runnumber,$segment);
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
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %d %d %d %d %s", $outevents, $lfn, $bbchash{sprintf("%05d",$segment)}, $calohash{sprintf("%05d",$segment)}, $truthhash{sprintf("%05d",$segment)}, $vertexhash{sprintf("%05d",$segment)}, $outdir, $pmin, $pmax, $runnumber, $segment, $tstflag);
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
