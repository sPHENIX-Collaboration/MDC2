#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Env;

my $notest;
my $all;
my $lfn;
GetOptions("lfn:s" => \$lfn, "notest"=>\$notest, "all"=>\$all);

if ($#ARGV < 0)
{
    print "usage: update_fcat_md5sum.pl <lustre dir>\n";
    print "parameters:\n";
    print "--all : check all files\n";
    print "--notest: run for real\n";
    exit(1);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here

my $getfiles;
if (defined $all)
{
    $getfiles = $dbh->prepare("select lfn,full_file_path from files where md5 is null or md5='0'"); 
}
else
{
    my $dcachedir = $ARGV[0];
    if (! -d $dcachedir)
    {
	print "could not find directory $dcachedir\n";
	exit(1);
    }
    if ($dcachedir !~ /lustre/ && $dcachedir !~ /data/)
    {
	print "only lustre dirs allowed\n";
	exit(1);
    }
    if (defined $lfn)
    {
	$getfiles = $dbh->prepare("select lfn,full_file_path from files where lfn like '$lfn%' and (md5 is null or md5 = '0')");

    }
    else
    {
	$getfiles = $dbh->prepare("select lfn,full_file_path from files where (md5 is null or md5 = '0' or md5 = 'ffffffffffffffffffffffffffffffff') and full_file_path like '$dcachedir/%'");
    }
}

my $updatemd5 = $dbh->prepare("update files set md5=? where lfn=?");
$getfiles->execute()|| die $DBI::errstr;
while (my @res = $getfiles->fetchrow_array())
{
    my $lfn =  $res[0];
    my $fullfile = $res[1];
    if ($fullfile !~ /lustre/ && $fullfile !~ /data/)
    {
	print "$fullfile not in lustre\n";
	next;
    }
    if (-f $fullfile)
    {
	if (! defined $notest)
	{
	    print "would handle $fullfile\n";
	}
	else
	{
	    print "handling $fullfile\n";
	    my $localfile = $fullfile;
#	print "handling $localfile\n";
	    open FILE, "$localfile";
	    my $ctx = Digest::MD5->new;
	    $ctx->addfile (*FILE);
	    my $hash = $ctx->hexdigest;
	    close (FILE);
	    printf("md5_hex:%s\n",$hash);
	    $updatemd5->execute($hash,$lfn);
	}
    }
}
$getfiles->finish();
$dbh->disconnect;
