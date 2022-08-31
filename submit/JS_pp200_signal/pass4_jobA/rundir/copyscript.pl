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
sub getentries;
sub islustremounted;

Env::import();

#only created if initial copy fails (only for sphnxpro account)
my $backupdir = sprintf("/sphenix/sim/sim01/sphnxpro/MDC2/backup");

my $outdir = ".";
my $test;
my $use_xrdcp;
my $use_rsync;
my $use_mcs3;
my $use_dd;
GetOptions("dd" => \$use_dd, "mcs3" => \$use_mcs3, "outdir:s"=>\$outdir, "rsync"=>\$use_rsync, "test"=>\$test, "xrdcp"=>\$use_xrdcp);


my $file = $ARGV[0];
if (! -f $file)
{
    print "$file not found\n";
    die;
}
# get the username so othere users cannot mess with the production DBs
my $username = getpwuid( $< );

my $lfn = basename($file);


my $size = stat($file)->size;

my $copycmd;
my $outfile = sprintf("%s/%s",$outdir,$file);
if ($outdir =~ /lustre/)
{
    my $iret = &islustremounted();
    if ($iret == 0)
    {
        print "lustre not mounted, use mcs3\n";
	$use_mcs3 = 1;
    }
    else
    {
        print "lustre mounted, use direct access\n";
    }
}

# set up minio output locations, only used when we deal with lustre
my $mcs3outdir = $outdir;
my $mcs3outfile = $outfile;
if (defined $use_mcs3)
{
    $mcs3outdir =~ s/\/sphenix\/lustre01\/sphnxpro/sphenixS3/;
    $mcs3outfile = sprintf("%s/%s",$mcs3outdir,$file);
    my $statcmd = sprintf("mcs3 stat %s", $mcs3outfile);
    system($statcmd);
    my $exit_value  = $? >> 8;
    if ($exit_value == 0)
    {
	my $delcmd = sprintf("mcs3 rm  %s", $mcs3outfile);
	system($delcmd);
    }
}
else
{
    if (-f $outfile)
    {
	if (! defined $test)
	{
	    unlink $outfile;
	}
    }
}
my $outhost;
if ($outdir =~ /pnfs/)
{ 
    if ($username ne "sphnxpro")
    {
	print "no copying to dCache for $username, only sphnxpro can do that\n";
	exit 0;
    }
    if (defined $use_xrdcp)
    {
	$copycmd = sprintf("env LD_LIBRARY_PATH=/cvmfs/sdcc.bnl.gov/software/x8664_sl7/xrootd:%s /cvmfs/sdcc.bnl.gov/software/x8664_sl7/xrootd/xrdcp --nopbar --retry 3  -DICPChunkSize 1048576 %s root://dcsphdoor02.rcf.bnl.gov:1095%s",$LD_LIBRARY_PATH,$file,$outfile);
    }
    else
    {
	$copycmd = sprintf("dccp %s %s",$file,$outfile);
    }
    $outhost = 'dcache';
}
else
{
    $copycmd = sprintf("cp %s %s",$file,$outfile);
    if (defined $use_rsync)
    {
	$copycmd = sprintf("rsync -av %s %s",$file,$outfile);
    }
    $outhost = 'gpfs';
    if ($outdir =~ /lustre/)
    {
	$outhost = 'lustre';
	if (defined $use_dd)
	{
	    $copycmd = sprintf("dd if=%s of=%s bs=4M oflag=direct",$file,$outfile);
	}
	else
	{
	    $copycmd = sprintf("cp %s %s",$file,$outfile);
	}
	if (defined $use_mcs3)
	{
	    $copycmd = sprintf("mcs3 cp %s %s",$file,$mcs3outfile);
	}
    }
}

# create output dir if it does not exist and if it is not a test
# user check for dCache is handled before so we do
# not have to protect here against users trying to create a dir in dCache
if (defined $use_mcs3)
{
    my $statcmd = sprintf("mcs3 stat %s", $mcs3outdir);
    system($statcmd);
    my $exit_value  = $? >> 8;
    if ($exit_value != 0)
    {
	my $createcmd = sprintf("mcs3  mb %s", $mcs3outdir);
	system($createcmd);
    }

}
else
{
    if (! -d $outdir)
    {
	if (! defined $test)
	{
	    mkpath($outdir);
	}
    }
}

if (defined $test)
{
    print "cmd: $copycmd\n";
}
else
{
    my $thisdate = `date +%s`;
    chomp $thisdate;
    print "unixtime begin: $thisdate cmd: $copycmd\n";
    system($copycmd);
    my $exit_value  = $? >> 8;
    print "copy return code: $exit_value\n";
    $thisdate = `date +%s`;
    chomp $thisdate;
    print "unixtime end: $thisdate cmd: $copycmd\n";
}

# down here only things for the production account
# 1) on failed copy - copy to backup dir
# 2) get md5sum and number of entries and update file catalog
if ($username ne "sphnxpro")
{
    print "no DB modifications for $username\n";
    exit 0;
}
my $outfileexists = 0;

if (defined $use_mcs3)
{
    my $statcmd = sprintf("mcs3 stat %s", $mcs3outfile);
    system($statcmd);
    my $exit_value  = $? >> 8;
    if ($exit_value == 0)
    {
	$outfileexists = 1;
    }
}
else
{
    if (-f $outfile)
    {
	$outfileexists = 1;
    }
}
if ($outfileexists == 0)
{
    if (! -d $backupdir)
    {
	mkpath($backupdir);
    }

    $outfile = sprintf("%s/%s",$backupdir,$lfn);
    $copycmd = sprintf("rsync -av %s %s",$file,$outfile);
    $outhost = 'gpfs';
    system($copycmd);
}

my $outsize = 0;
my $imax = 100;
if (! defined $test && ! defined $use_mcs3)
{
    $outsize = stat($outfile)->size;
    my $icnt = 0;
    while($outsize == 0 || $outsize != $size)
    {
        $icnt++;
	if ($icnt > $imax)
	{
	    print "number of tries exceeded, quitting\n";
	    die;
	}
	print "sleeping $icnt times for $outfile\n";
	sleep(10);
	$outsize = stat($outfile)->size;
    }
}
else
{
    $outsize = $size;
}
my $md5sum = &getmd5($file);
my $entries = &getentries($file);
if ($outsize != $size)
{
    print STDERR "filesize mismatch between origin $file ($size) and copy $outfile ($outsize)\n";
    die;
}
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select size,full_file_path from files where full_file_path = ?") || die $DBI::error;
my $insertfile = $dbh->prepare("insert into files (lfn,full_host_name,full_file_path,time,size,md5) values (?,?,?,'now',?,?)");
my $insertdataset = $dbh->prepare("insert into datasets (filename,runnumber,segment,size,dataset,dsttype,events) values (?,?,?,?,'mdc2',?,?)");
my $chkdataset = $dbh->prepare("select size from datasets where filename=? and dataset='mdc2'");
my $delfile = $dbh->prepare("delete from files where full_file_path = ?");
my $delcat = $dbh->prepare("delete from datasets where filename = ?");

# first files table
$chkfile->execute($outfile);
if ($chkfile->rows > 0)
{
    $delfile->execute($outfile);
}
$insertfile->execute($lfn,$outhost,$outfile,$size,$md5sum);

$chkdataset->execute($lfn);
if ($chkdataset->rows > 0)
{
    $delcat->execute($lfn);
}
my $runnumber = 0;
my $segment = -1;
if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/)
{
    $runnumber = int($2);
    $segment = int($3);
}
my $splitstring = "_sHijing";
if ($lfn =~ /pythia8/)
{
    $splitstring = "_pythia8";
}
if ($lfn =~ /single/)
{
    $splitstring = "_single";
}
my @sp1 = split(/$splitstring/,$lfn);
if (! defined $test)
{
    $insertdataset->execute($lfn,$runnumber,$segment,$size,$sp1[0],$entries);
}
else
{
    print "db cmd: insertdataset->execute($lfn,$runnumber,$segment,$size,$sp1[0])\n";
}
$chkdataset->finish();
$chkfile->finish();
$delcat->finish();
$delfile->finish();
$insertfile->finish();
$insertdataset->finish();
$dbh->disconnect;

sub getmd5
{
    my $fullfile = $_[0];
    my $hash;
    if (-f $fullfile)
    {
	print "handling $fullfile\n";
	open FILE, "$fullfile";
	my $ctx = Digest::MD5->new;
	$ctx->addfile (*FILE);
	$hash = $ctx->hexdigest;
	close (FILE);
	printf("md5_hex:%s\n",$hash);
    }
    return $hash;
}

sub getentries
{
#write stupid macro to get events
    if (! -f "GetEntries.C")
    {
	open(F,">GetEntries.C");
	print F "#ifndef MACRO_GETENTRIES_C\n";
	print F "#define MACRO_GETENTRIES_C\n";
	print F "#include <frog/FROG.h>\n";
	print F "R__LOAD_LIBRARY(libFROG.so)\n";
	print F "void GetEntries(const std::string &file)\n";
	print F "{\n";
	print F "  gSystem->Load(\"libFROG.so\");\n";
	print F "  gSystem->Load(\"libg4dst.so\");\n";
	print F "  // prevent root to start gdb-backtrace.sh\n";
	print F "  // in case of crashes, it hangs the condor job\n";
	print F "  for (int i = 0; i < kMAXSIGNALS; i++)\n";
	print F "  {\n";
	print F "     gSystem->IgnoreSignal((ESignals)i);\n";
	print F "  }\n";
	print F "  FROG *fr = new FROG();\n";
	print F "  TFile *f = TFile::Open(fr->location(file));\n";
	print F "  cout << \"Getting events for \" << file << endl;\n";
	print F "  TTree *T = (TTree *) f->Get(\"T\");\n";
	print F "  cout << \"Number of Entries: \" <<  T->GetEntries() << endl;\n";
	print F "}\n";
	print F "#endif\n";
	close(F);
    }
    my $file = $_[0];
    open(F2,"root.exe -q -b GetEntries.C\\(\\\"$file\\\"\\) 2>&1 |");
    my $checknow = 0;
    my $entries = -2;
    while(my $entr = <F2>)
    {
	chomp $entr;
#	print "$entr\n";
	if ($entr =~ /$file/)
	{
	    $checknow = 1;
	    next;
	}
	if ($checknow == 1)
	{
	    if ($entr =~ /Number of Entries/)
	    {
		my @sp1 = split(/:/,$entr);
		$entries = $sp1[$#sp1];
		$entries =~ s/ //g; #just to be safe, strip empty spaces 
		last;
	    }
	}
    }
    close(F2);
    print "file $file, entries: $entries\n";
    return $entries;
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

#print "script is called\n";
