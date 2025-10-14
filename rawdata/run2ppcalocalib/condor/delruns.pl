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
my $tmpgpfspath = sprintf("/sphenix/data/data02/sphnxpro/production2/tmp");
if (! -d $tmpgpfspath)
{
  mkpath($tmpgpfspath);
}
open(F,"$ARGV[0]");
while (my $run = <F>)
{
    chomp $run;
    my $runsql=sprintf("%08d",$run);
    my $delrun = $dbh->prepare("delete from files where lfn like 'DST_CALO_run2pp_ana509_2024p022_v001-$runsql%.root'");
    my $delset =  $dbh->prepare("delete from datasets where runnumber = $run and filename like 'DST_CALO_run2pp_ana509_2024p022_v001-$runsql%.root'");
    my $getdir = $dbh->prepare("select full_file_path from files where lfn like 'DST_CALO_run2pp_ana509_2024p022_v001-$runsql%.root' limit 1");

    $getdir->execute();
    my $nres = $getdir->rows;
    my $mvcmd;
    if ($nres > 0)
    {
	print "deleting files from run $run from datasets table\n";
	$delset->execute();
	print "deleting files from run $run from files table\n";
	$delrun->execute();
	my @res = $getdir->fetchrow_array();
	my $dn = dirname($res[0]);
	print "handle dir $dn for run $run, moving files\n";
	$mvcmd = sprintf("mv %s/*%08d* $tmppath",$dn,$run);
	system($mvcmd);
    }
    #    unlink glob "$dn/*$run*";
    $getdir->finish();
    $delrun->finish();
    $delset->finish();

    my $delrun_hist = $dbh->prepare("delete from files where lfn like 'HIST_CALOQA_run2pp_ana509_2024p022_v001-$runsql%.root'");
    my $delset_hist =  $dbh->prepare("delete from datasets where runnumber = $run and filename like 'HIST_CALOQA_run2pp_ana509_2024p022_v001-$runsql%.root'");
    my $getdir_hist = $dbh->prepare("select full_file_path from files where lfn like 'HIST_CALOQA_run2pp_ana509_2024p022_v001-$runsql%.root' limit 1");

    $getdir_hist->execute();
    $nres = $getdir_hist->rows;
    if ($nres > 0)
    {
	#    unlink glob "$dn/*$run*";
	print "deleting histo files from run $run from datasets table\n";
	$delset_hist->execute();
	print "deleting histo files from run $run from files table\n";
	$delrun_hist->execute();
	my @res = $getdir_hist->fetchrow_array();
	my $dn = dirname($res[0]);
	print "moving files from $dn for run $run\n";
	$mvcmd = sprintf("mv %s/*%08d* $tmpgpfspath",$dn,$run);
	system($mvcmd);
    }
    $getdir_hist->finish();
    $delrun_hist->finish();
    $delset_hist->finish();
    print "moving logs\n";
    $mvcmd = sprintf("mv log/*%08d* log/tmp",$run);
    system($mvcmd);
#    die;
}
close(F);
