#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


my $outevents = 0;
my $runnumber = 13;
my $test;
my $incremental;
my $shared;
my $mom;
GetOptions("test"=>\$test, "increment"=>\$incremental,  "mom:s" => \$mom, "shared" => \$shared);
if ($#ARGV < 3)
{
    print "usage: run_all.pl <number of jobs> <particle> <pmin> <pmax>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--mom <p or pt> : use p or pt for momentum\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}
if (! defined $mom || ($mom ne "pt" and $mom ne "p"))
{
    print "need to give p or pt for -mom\n";
    exit(1);
}

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxsub/)
{
    print "submit only from phnxsub01, phnxsub02, phnxsub03 or phnxsub04\n";
    exit(1);
}
my $maxsubmit = $ARGV[0];
my $particle = lc $ARGV[1];
my $pmin = $ARGV[2];
my $pmax = $ARGV[3];
my $filetype="single";
my $partprop = sprintf("%s_%s_%d_%d",$particle,$mom,$pmin,$pmax);
$filetype=sprintf("%s_%sMeV",$filetype,$partprop);

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
    $line = sprintf("%s/run%04d/%s",$line,$runnumber,$partprop);
    if (! -d $line)
    {
	mkpath($line);
    }
    push(@outdir,$line);
}
close(F);


my %outfiletype = ();
$outfiletype{"DST_CALO_CLUSTER"} = $outdir[0];
$outfiletype{"DST_TRKR_HIT"} = $outdir[1];
$outfiletype{"DST_TRUTH"} = $outdir[1];
foreach my $type (sort keys %outfiletype)
{
    print "type $type, dir: $outfiletype{$type}\n";
} 
#die;
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename from datasets where dsttype = 'G4Hits' and filename like '%$filetype%' and runnumber = $runnumber order by filename") || die $DBI::errstr;
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
            my $lfn =  sprintf("%s_%s-%010d-%05d.root",$type,$filetype,$runnumber,$segment);
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
	my $calooutfilename = sprintf("DST_CALO_CLUSTER_%s-%010d-%05d.root",$filetype,$runnumber,$segment);
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %s %s %d %d %s", $outevents, $filetype, $partprop, $lfn, $calooutfilename, $outdir[0], $outdir[1],$runnumber, $segment, $tstflag);
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
	if ($maxsubmit != 0 && $nsubmit >= $maxsubmit)
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
