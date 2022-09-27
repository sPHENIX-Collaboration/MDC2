#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use File::stat;
use Getopt::Long;
use DBI;

my $kill;
my $verbosity;
GetOptions("kill"=>\$kill, "verbosity"=>\$verbosity);
if ($#ARGV < 0)
{
    print "usage find_orphans.pl <topdir>\n";
    exit(0);
}

my $topdir = $ARGV[0];

if (! -d $topdir)
{
    print "$topdir does not exist\n";
    exit(1);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $checkfcat = $dbh->prepare("select full_file_path from files where lfn = ?");

my %orphans = ();
open(F,"find $topdir -type f -name '*.root' -mmin 60 |");
while (my $fullfile = <F>)
{
    chomp $fullfile;
    my $lfn = basename($fullfile);
#    print "$fullfile, lfn: $lfn\n";
    $checkfcat->execute($lfn);
    my $found = 0;
    while (my @res = $checkfcat->fetchrow_array())
    {
	if ($fullfile eq $res[0])
	{
#	    print "found $fullfile in fcat\n";
	    $found = 1;
	}
	else
	{
#	    print "$res[0] does not match $fullfile\n";
	}
    }
    if ($found == 0)
    {
	$orphans{$fullfile} = $lfn;
    }
}
close(F);
open(F,"> remove.sh");
foreach my $file (sort keys %orphans)
{
    print "$file is orphaned\n";
    print F "rm $file\n";
}
close(F);
