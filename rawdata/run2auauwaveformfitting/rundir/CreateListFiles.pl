#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use DBI;
use Data::Dumper;

if ($#ARGV < 1)
{
    print "usage: CreateFileLists.pl <runnumber> <segment>\n";
    exit(0);
}

my $runnumber = $ARGV[0];
my $segment = $ARGV[1];

my $dbh;
my $attempts = 0;

CONNECTAGAIN:
if ($attempts > 0)
{
    sleep(int(rand(21) + 10)); # sleep 10-30 seconds before retrying
}
$attempts++;
if ($attempts > 200)
{
    print "giving up connecting to DB after $attempts attempts\n";
    exit(1);
}
$dbh = DBI->connect("dbi:ODBC:FileCatalog_read") || goto CONNECTAGAIN;
if ($attempts > 0)
{
    print "connections succeded after $attempts attempts\n";
}
$dbh->{LongReadLen}=2000; # full file paths need to fit in here

my $getfiles = $dbh->prepare("select filename from datasets where runnumber = $runnumber and segment = $segment order by filename");

$getfiles->execute();

#my $inlist = sprintf("filelist_%d_%05d.list",$runnumber,$segment);
my $inlist = sprintf("files.list");
open(F,">$inlist");
while (my @res = $getfiles->fetchrow_array())
{
    if ($res[0] =~ /DST_TRIGGERED_EVENT/ && $res[0] =~ /run2auau_new_nocdbtag_v007/)
    {
	print F "$res[0]\n";
    }
}
close(F);
$getfiles->finish();
$dbh->disconnect;
