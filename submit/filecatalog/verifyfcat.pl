#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use File::stat;
use Getopt::Long;
use DBI;

my $kill;
GetOptions("kill"=>\$kill);

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here

my $getfiles = $dbh->prepare("select filename from datasets") || die $DBI::error;

my $getfullfile = $dbh->prepare("select lfn,full_file_path from files");
#my $delfile = $dbh->prepare("delete from files where full_file_path = ?");
my %fcatfiles = ();
$getfullfile->execute();
while (my @res = $getfullfile->fetchrow_array())
{
    $fcatfiles{$res[0]} = $res[1];
}


$getfiles->execute();
my $nfiles = $getfiles->rows;
print "checking $nfiles files\n";
my $nchk = 0;
my $ntot = 0;
my $nfail = 0;
my %failfiles = ();
while (my @res = $getfiles->fetchrow_array())
{
    $nchk++;
    $ntot++;
    if (! exists $fcatfiles{$res[0]})
    {
	print "cannot find $res[0] in fcat\n";
        $nfail++;
	$failfiles{$res[0]} = 1;
    }
    if ($nchk >= 1000)
    {
	print "checked $ntot files out of $nfiles\n";
	$nchk = 0;
    }
}
print "number of failures: $nfail\n";
open(F1,">dataset_remove_missing.sql");
if ($nfail > 0)
{
    print "missing files:\n";
    foreach my $i (sort keys %failfiles)
    {
	print "$i\n";
        print F1 "psql -h sphnxdbmaster FileCatalog -c \"delete from datasets where filename = \'$i\'\"\n";
    }
}
close(F1);
$getfiles->finish();
$getfullfile->finish();
$dbh->disconnect;
