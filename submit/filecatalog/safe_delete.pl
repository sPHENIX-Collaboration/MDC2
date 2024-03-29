#!/usr/bin/perl

use File::Basename;
use File::stat;
use strict;
use DBI;

use Getopt::Long;

sub checkdownstream;

my $dokill;
GetOptions('kill'=>\$dokill);
if ( $#ARGV < 1 )
{

    print "usage: safe_delete.pl <directory> <number of files, 0 = all>\n";
    print "flags:\n";
    print "-kill   remove file for real\n";
    exit(-1);
}

my $indir = $ARGV[0];
if (! -d $indir)
{
    print "directory $indir does not exist\n";
    exit(1);
}

my $ndel = $ARGV[1];
my $delfiles = 0;

my %downfiles = ();

if (! defined $dokill)
{
    print "TestMode, use -kill to delete files for real\n";
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getinfo = $dbh->prepare("select lfn,size,full_file_path,full_host_name,md5 from files where lfn = ? and ((full_host_name = 'dcache' and full_file_path like '/pnfs/%') or (full_host_name = 'lustre' and full_file_path like '%lustre%')) and md5 is not null");
my $getdataset = $dbh->prepare("select runnumber,segment from datasets where filename=?");
my $checkdataset = $dbh->prepare("select filename from datasets where runnumber=? and segment = ? and dsttype=?");
my $delfcat = $dbh->prepare("delete from files where lfn=? and full_file_path=?");

open(F,"find $indir -maxdepth 1 -type f -name '*.root' | sort|");
while (my $file = <F>)
{
    chomp $file;
#    print "checking $file\n";
    my $origsize = stat($file)->size;
    my $lfn = basename($file);
    $getinfo->execute($lfn);
    if ($getinfo->rows == 0)
    {
	next;
    }
    elsif ($getinfo->rows > 1)
    {
	print "more than two rows for $lfn check it\n";
	die;
    }
    my @res = $getinfo->fetchrow_array();
    if ($res[1] != $origsize)
    {
	print "size mismatch gpfs-dcache for $lfn:  $origsize, $res[1]\n";
	next;
    }
    my $dcachefile = $res[2];
    if (! -f $dcachefile)
    {
	print "dcache file $dcachefile does not exist\n";
	next;
    }
    my $dcsize = stat($dcachefile)->size;
    if ($dcsize != $origsize)
    {
	print "dcache size for $lfn: $dcsize not from file catalog: $res[1]\n";
	next;
    }
    my $isokay = checkdownstream($lfn);
    if ($isokay == 0)
    {
	next;
    }
    if (defined $dokill)
    {
	print "delete $file\n";
	$delfcat->execute($lfn, $file);
	unlink $file;
    }
    else
    {
	print "would delete $file\n";
    }
    $delfiles++;
    if ($ndel > 0 && $delfiles >= $ndel)
    {
	if (defined $dokill)
	{
	    print "deleted $delfiles files, quitting\n";
	}
	else
	{
	    print "would have deleted $delfiles files, quitting\n";
	}
	exit(0);
    }
}
close(F);

$getinfo->finish();
$getdataset->finish();
$checkdataset->finish();
$delfcat->finish();
$dbh->disconnect;

sub checkdownstream
{
    my $infile = basename($_[0]);
    return 1;
    $getdataset->execute($infile);
    my @res = $getdataset->fetchrow_array();
    foreach my $downfiletype (keys %downfiles)
    {
	$checkdataset->execute($res[0],$res[1],$downfiletype);
	if ($checkdataset->rows == 0)
	{
	    return 0;
	}
    }
    return 1;
}

