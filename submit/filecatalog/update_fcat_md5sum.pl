#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Env;

my $test;
my $all;
GetOptions("test"=>\$test, "all"=>\$all);

if ($#ARGV < 0)
{
    print "usage: update_fcat_md5sum.pl <dcache dir>\n";
    print "parameters:\n";
    print "--all : check all files\n";
    print "--test: run in test mode - no changes\n";
    exit(1);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here

my $getfiles;
if (defined $all)
{
    $getfiles = $dbh->prepare("select lfn,full_file_path from files where md5 is null"); 
}
else
{
    my $dcachedir = $ARGV[0];
    if (! -d $dcachedir)
    {
	print "could not find directory $dcachedir\n";
	exit(1);
    }
    if ($dcachedir !~ /pnfs/)
    {
	print "only pnfs (dcache) dirs allowed\n";
	exit(1);
    }
    $getfiles = $dbh->prepare("select lfn,full_file_path from files where md5 is null and full_file_path like '$dcachedir/%'");
}

my $updatemd5 = $dbh->prepare("update files set md5=? where lfn=?");
$getfiles->execute()|| die $DBI::errstr;
while (my @res = $getfiles->fetchrow_array())
{
    my $lfn =  $res[0];
    my $fullfile = $res[1];
    if ($fullfile!~ /pnfs/)
    {
	print "$fullfile not in dcache\n";
	next;
    }
    if (-f $fullfile)
    {
	print "handling $fullfile\n";
	my $copycmd = sprintf("env LD_LIBRARY_PATH==/cvmfs/sdcc.bnl.gov/software/x8664_sl7/xrootd:%s /cvmfs/sdcc.bnl.gov/software/x8664_sl7/xrootd/xrdcp --nopbar --retry 3 root://dcsphdoor02.rcf.bnl.gov:1095%s /tmp", $LD_LIBRARY_PATH, $fullfile);
	system($copycmd);
	my $localfile = sprintf("/tmp/%s",$lfn);
#	print "handling $localfile\n";
	open FILE, "$localfile";
	my $ctx = Digest::MD5->new;
	$ctx->addfile (*FILE);
	my $hash = $ctx->hexdigest;
	close (FILE);
	printf("md5_hex:%s\n",$hash);
	$updatemd5->execute($hash,$lfn);
        unlink $localfile;
    }
}
$getfiles->finish();
$dbh->disconnect;
