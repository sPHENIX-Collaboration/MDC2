#!/usr/bin/perl

use strict;
use File::Basename;
use File::stat;
use DBI;
use Getopt::Long;

my $mdc = "mdc2";
my $test;
GetOptions("test"=>\$test);

if ($#ARGV < 0)
{
    print "usage: add_fcat <lustredir>\n";
    print "parameters:\n";
    print "--test: run in test mode\n";
    exit(1);
}

my $dcachedir = $ARGV[0];
if (! -d $dcachedir)
{
    print "could not find directory $dcachedir\n";
    exit(1);
}
if ($dcachedir !~ /lustre/)
{
    print "only lustre dirs allowed\n";
    exit(1);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc");
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select size,full_file_path from files where lfn=?"); 
my $insertfile = $dbh->prepare("insert into files (lfn,full_host_name,full_file_path,time,size) values (?,'lustre',?,'now',?)");
my $updatesize = $dbh->prepare("update files set size=?,md5=NULL where lfn = ? and full_file_path = ?");

print "checking $dcachedir for new files\n";
#open(F,"find $dcachedir -maxdepth 1 -type f -name '*.root' -cmin +30 | sort |");
open(F,"find $dcachedir -maxdepth 1 -type f -name '*.root' -mmin +30 |");
while (my $file = <F>)
{
    chomp $file;
    my $fsize = stat($file)->size;
    if ($fsize == 0) # file being copied is zero size
    {
	next;
    }
    my $lfn = basename($file);
    my $needinsert = 1;
#    print "checking $lfn\n";
    $chkfile->execute($lfn);
    if ($chkfile->rows == 0)
    {
	if (! defined $test)
	{
	    print "inserting $lfn\n";
            $insertfile->execute($lfn, $file, $fsize);
	}
	else
	{
	    print "would insert $lfn, dcache, $file, now, $fsize \n";
	}
    }
    else
    {
	while(my @res = $chkfile->fetchrow_array)
	{
#	print "$res[1], $file\n";
	    if ($res[1] eq  $file)
	    {
#	    print "size $fsize, $res[0]\n";
		if ($fsize == $res[0])
		{
		    $needinsert = 0;
		    next;
		}
		else
		{
		    if (! defined $test)
		    {
			print "updating size for $lfn from $res[0] to $fsize\n";
		        $updatesize->execute($fsize,$lfn,$file);
			$needinsert = 0;
			next;
		    }
		    else
		    {
			print "would update size for $lfn from $res[0] to $fsize\n";
		    }
		}
	    }
	}
    }
}
close(F);
