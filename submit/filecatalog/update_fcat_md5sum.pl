#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Env;

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here

my $getfiles = $dbh->prepare("select lfn,full_file_path from files where md5 is null"); 

my $updatemd5 = $dbh->prepare("update files set md5=? where lfn=?");
$getfiles->execute()|| die $DBI::error;
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
	print "handling $lfn\n";
	my $copycmd = sprintf("env LD_LIBRARY_PATH=/usr/lib64:%s xrdcp --nopbar --retry 3 root://dcsphdoor02.rcf.bnl.gov:1095%s /tmp", $LD_LIBRARY_PATH, $fullfile);
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
