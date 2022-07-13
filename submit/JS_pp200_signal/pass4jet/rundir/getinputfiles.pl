#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Path;
use File::stat;
use Getopt::Long;
use DBI;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Env;

sub getmd5;
sub islustremounted;

Env::import();
my $test;
my $filelist;
my $use_dcache;
my $use_xrdcp;
my $use_mcs3;
my $use_dd;

GetOptions("dcache" => \$use_dcache, "dd" => \$use_dd, "filelist" => \$filelist, "mcs3" => \$use_mcs3, "test"=>\$test, "xrdcp"=>\$use_xrdcp);

if ($#ARGV < 0)
{
    print "usage: getinputfiles.pl <file>\n";
    print "parameters:\n";
    print "--dcache: use dccp\n";
    print "--dd: use dd instead of cp for lustre\n";
    print "--filelist: argument is an ascii file with a list\n";
    print "--mcs3: use mcs3 for lustre\n";
    print "--test: do nothing, just test what we would do\n";
    print "--xrdcp: (with --dcache) use xrdcp\n";
    exit(1);
}

my %inputfiles = ();

if (defined $filelist)
{
    open(F,"$ARGV[0]");
    while (my $lfn = <F>)
    {
	chomp $lfn;
	$inputfiles{$lfn} = 1;
    }
    close(F);
}
else
{
    $inputfiles{$ARGV[0]} = 1;
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $filelocation = $dbh->prepare("select full_file_path,md5,size,full_host_name from files where lfn = ?") || die $DBI::error;
my $updatemd5 = $dbh->prepare("update files set md5=? where full_file_path = ?");
my %filemd5 = ();
my %filesizes = ();
foreach my $file (keys %inputfiles)
{
    $filelocation->execute($file);
    if ($filelocation->rows == 0)
    {
	print "could not retrieve $file from filecatalog\n";
	exit(-1);
    }
    my @res = $filelocation->fetchrow_array();
    $filemd5{$res[0]} = $res[1];
    $filesizes{$res[0]} = $res[2];
    print "will copy $file from $res[3]\n";
}
$filelocation->finish();
$updatemd5->finish();
$dbh->disconnect;
my $lustremount;
my $iret = &islustremounted();
if ($iret == 0)
{
    $lustremount = 1;
}
foreach my $file (keys %filemd5)
{
#    $filelocation->execute($file);

#    my @res = $filelocation->fetchrow_array();
#    print "full: $res[0]\n";
    if (! defined $filemd5{$file})
    {
	print "md5 needs recalc\n";
    }
#    else
#    {
#	print "md5: $res[1]\n";
#    }
#    print "size: $res[2]\n";

#    my $copycmd = sprintf("rsync -av %s .",$file);
    my $copycmd = sprintf("cp %s .",$file);
    if ($file =~ /lustre/)
    {
	if ($lustremount)
	{
	    $use_mcs3 = 1;
	}
	else
	{
	    if (defined $use_dd)
	    {
		$copycmd = sprintf("dd if=%s of=%s bs=4M iflag=direct",$file,basename($file));
	    }
	    else
	    {
		$copycmd = sprintf("cp %s .",$file);
	    }
	}
    }
    if (defined $use_mcs3)
    {
	if ($file =~ /\/sphenix\/lustre01\/sphnxpro/)
	{
	    my $mcs3file = $file;
	    $mcs3file =~ s/\/sphenix\/lustre01\/sphnxpro/sphenixS3/;
	    $copycmd = sprintf("mcs3 cp %s .",$mcs3file);
	}
    }
    if ($file =~ /pnfs/)
    {
	if (defined $use_xrdcp)
	{
	    $copycmd = sprintf("env LD_LIBRARY_PATH=/cvmfs/sdcc.bnl.gov/software/x8664_sl7/xrootd:%s /cvmfs/sdcc.bnl.gov/software/x8664_sl7/xrootd/xrdcp --nopbar --retry 3 -DICPChunkSize 1048576 root://dcsphdoor02.rcf.bnl.gov:1095%s .", $LD_LIBRARY_PATH, $file);
	}
	else
	{
	    $copycmd = sprintf("dccp %s .",$file);
	}
    }
    print "executing $copycmd\n";
    system($copycmd);
    my $exit_value  = $? >> 8;
    my $thisdate = `date`;
    chomp $thisdate;
    print "$thisdate: copy return code: $exit_value\n";

    my $lfn = basename($file);
    if (-f $lfn)
    {
        my $fsize =  stat($lfn)->size;
	if ($fsize != $filesizes{$file})
	{
	    print "size mismatch for $lfn, db: $filesizes{$file}, on disk: $fsize\n";
	    die;
	}
	else
	{
	    print "size for $lfn matches $fsize\n";
	}
	my $recalcmd5 = &getmd5($lfn);
	if (defined $filemd5{$file})
	{
	    if ($filemd5{$file} ne $recalcmd5)
	    {
		print "md5 mismatch for $file, orig $filemd5{$file}, recalc $recalcmd5\n";
		die;
	    }
	    else
	    {
		print "md5 for $file matches: $recalcmd5\n";
	    }
	}
	else
	{
	    $updatemd5->execute($recalcmd5,$file);
	}
    }
    else
    {
	print "local copy of $file failed\n";
    }
}

sub getmd5
{
    my $fullfile = $_[0];
    my $hash;
    if (-f $fullfile)
    {
	open FILE, "$fullfile";
	my $ctx = Digest::MD5->new;
	$ctx->addfile (*FILE);
	$hash = $ctx->hexdigest;
	close (FILE);
#	printf("md5_hex:%s\n",$hash);
    }
    return $hash;
}

sub islustremounted
{
    if (-f "/etc/auto.direct")
    {
	my $mountcmd = sprintf("cat /etc/auto.direct | grep lustre | grep sphenix");
	system($mountcmd);
	my $exit_value  = $? >> 8;
	if ($exit_value == 0)
	{
	    return 1;
	}
    }
    else
    {
	print "could not locate /etc/auto.direct\n";
    }
    return 0;
}
