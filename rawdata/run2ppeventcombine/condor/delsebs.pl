#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

if($#ARGV < 0)
{
    print "usage delsebs.pl <runlist>\n";
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
while (my $line = <F>)
{
    chomp $line;
    my @sp1 = split(/ /,$line);
    my $run = sprintf("%08d",$sp1[0]);
    my $seb = $sp1[1] . "_";
    my $delrun = $dbh->prepare("delete from files where lfn like 'DST_TRIGGERED_EVENT_$seb%$run%.root'");
    my $delset =  $dbh->prepare("delete from datasets where runnumber = $run and filename like 'DST_TRIGGERED_EVENT_$seb%$run%.root'");
    my $getdir = $dbh->prepare("select full_file_path from files where lfn like 'DST_TRIGGERED_EVENT_$seb%$run%.root' limit 1");
    print "run $run, seb $seb\n";
    print "delete from datasets where runnumber = $run and filename like 'DST_TRIGGERED_EVENT_$seb%$run%.root'\n";
    print "select full_file_path from files where lfn like 'DST_TRIGGERED_EVENT_$seb%$run%.root' limit 1\n";
    print "delete from files where lfn like 'DST_TRIGGERED_EVENT_$seb%$run%.root'\n";
    $getdir->execute();
    my $nres = $getdir->rows;
    if ($nres == 0)
    {
	$getdir->finish();
	$delrun->finish();
	$delset->finish();
	print "no results for run $run\n";
	next;
    }
    my @res = $getdir->fetchrow_array();
    my $dn = dirname($res[0]);
    print "handle dir $dn for run $run\n";
    my $mvcmd = sprintf("mv %s/*%s*%08d* $tmppath",$dn,$seb,$run);
    system($mvcmd);
    #    unlink glob "$dn/*$run*";
    $delrun->execute();
    $delset->execute();
    $getdir->finish();
    $delrun->finish();
    $delset->finish();
    $mvcmd = sprintf("mv log/condor-%s%010d* log/tmp",$seb,$run);
    system($mvcmd);
}
close(F);
