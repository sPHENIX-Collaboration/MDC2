#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

if($#ARGV < 0)
{
    print "usage delrun.pl <runlist>\n";
    exit(1);
}
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || goto CONNECTAGAIN;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $tmppath = sprintf("/sphenix/lustre01/sphnxpro/tmp");
if (! -d $tmppath)
{
mkpath($tmppath);
}
open(F,"$ARGV[0]");
while (my $run = <F>)
{
    chomp $run;
    my $delrun = $dbh->prepare("delete from files where lfn like 'DST_TRIGGERED_EVENT_%$run%.root'");
    my $delset =  $dbh->prepare("delete from datasets where runnumber = $run and filename like 'DST_TRIGGERED_EVENT_%$run%.root'");
    my $getdir = $dbh->prepare("select full_file_path from files where lfn like 'DST_TRIGGERED_EVENT_%$run%.root' limit 1");
    $getdir->execute();
    my $nres = $getdir->rows;
    my $mvcmd;
    if ($nres > 0)
    {
    my @res = $getdir->fetchrow_array();
    my $dn = dirname($res[0]);
    print "handle dir $dn for run $run\n";
    $mvcmd = sprintf("mv %s/*%08d* $tmppath",$dn,$run);
    system($mvcmd);
    #    unlink glob "$dn/*$run*";
    $delrun->execute();
    $delset->execute();
	print "no results for run $run\n";
#	next;
    }
    else
    {
	print "no DB entries for run $run\n";
    }
    $getdir->finish();
    $delrun->finish();
    $delset->finish();
    $mvcmd = sprintf("mv log/condor-*_*%08d* log/tmp",$run);
    system($mvcmd);
}
close(F);
