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

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here

my $getfiles = $dbh->prepare("select lfn,full_file_path from files where time < now() - interval '2 hours'") || die $DBI::errstr;

my $getdatasets = $dbh->prepare("select filename from datasets");

my %datasetsfiles = ();
$getdatasets->execute();
while (my @res = $getdatasets->fetchrow_array())
{
    $datasetsfiles{$res[0]} = 1;
}
$getdatasets->finish();
#my $delfile = $dbh->prepare("delete from files where full_file_path = ?");

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
    if (! exists $datasetsfiles{$res[0]})
    {
	print "cannot find $res[0] in datasets\n";
        $nfail++;
	$failfiles{$res[1]} = $res[0];
    }
    if ($nchk >= 1000)
    {
	print "checked $ntot files out of $nfiles\n";
	$nchk = 0;
    }
}
print "number of failures: $nfail\n";
open(F,">dataset_missing.sh");
open(F1,">dataset_missing.sql");
if ($nfail > 0)
{
    print "missing files:\n";
    foreach my $i (sort keys %failfiles)
    {
	print "$i\n";
        print F "rm $i\n";
        print F1 "psql -h sphnxdbmaster FileCatalog -c \"delete from files where lfn = \'$failfiles{$i}\' and full_file_path = \'$i\'\"\n";
    }
}

close(F);
close(F1);

$getfiles->finish();
$dbh->disconnect;
