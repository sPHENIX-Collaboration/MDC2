#!/usr/bin/env perl

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
my $verbosity;
my $use_rsync;
my $use_mv;
GetOptions("mv" => \$use_mv, "outdir:s"=>\$outdir, "test"=>\$test, "verbosity" => \$verbosity);


my $file = $ARGV[0];
if (! -f $file)
{
    print "$file not found\n";
    die;
}
my $lfn = basename($file);
my $runnumber = 0;
my $segment = -1;
if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/)
{
    $runnumber = int($2);
    $segment = int($3);
}
my $lower = $runnumber - $runnumber%100;
my $upper = $lower + 100;
my $runpath = sprintf("run_%08d_%08d",$lower,$upper);

$outdir = sprintf("%s/%s",$outdir,$runpath);
# get the username so othere users cannot mess with the production DBs
my $username = getpwuid( $< );


my $size = stat($file)->size;

my $md5sum = &getmd5($file);
my $entries = &getentries($file);

my $copycmd;
my $outfile = sprintf("%s/%s",$outdir,$lfn);

my $outhost;
$copycmd = sprintf("cp %s %s",$file,$outfile);
if (defined $use_rsync)
{
    $copycmd = sprintf("rsync -av %s %s",$file,$outfile);
}
$outhost = 'gpfs';
if ($outdir =~ /lustre/)
{
    $outhost = 'lustre';
}

if (defined $verbosity)
{
    print "copy command: $copycmd\n";
}

# create output dir if it does not exist and if it is not a test
# user check for dCache is handled before so we do
# not have to protect here against users trying to create a dir in dCache
if (! -d $outdir)
{
    if (! defined $test)
    {
	mkpath($outdir);
    }
}

if (defined $test)
{
    print "cmd: $copycmd\n";
}
else
{
    my $ncopytry = 0;
    while($ncopytry < 100)
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
	if ($exit_value == 0)
	{
	    last;
	}
	else
	{
	    print "copy failed - retrying\n";
	    sleep(int(rand(21) + 10)); # sleep 10-30 seconds before retrying
	    $ncopytry++;
	}
    }
    if (defined $use_mv)
    {
	unlink $file;
    }
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

if (-f $outfile)
{
    $outfileexists = 1;
}

my $outsize = 0;
my $imax = 100;
if (! defined $test)
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
if ($outsize != $size)
{
    print STDERR "filesize mismatch between origin $file ($size) and copy $outfile ($outsize)\n";
    die;
}
my $dbh;
my $attempts = 0;

 CONNECTAGAIN:
    if ($attempts > 0)
{
    sleep(int(rand(21) + 10)); # sleep 10-30 seconds before retrying
}
$attempts++;
if ($attempts > 100)
{
    print "giving up connecting to DB after $attempts attempts\n";
    exit(1);
}
$dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || goto CONNECTAGAIN;
if ($attempts > 0)
{
    print "connections succeded after $attempts attempts\n";
}
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $insertfile = $dbh->prepare("insert into files (lfn,full_host_name,full_file_path,time,size,md5) values (?,?,?,'now',?,?) on conflict (lfn,full_host_name,full_file_path) do update set time = EXCLUDED.time, size = EXCLUDED.size, md5 = EXCLUDED.md5");
my $insertdataset = $dbh->prepare("insert into datasets (filename,runnumber,segment,size,dataset,dsttype,events,tag) values (?,?,?,?,'run3auau',?,?,?) on conflict (filename,dataset) do update set runnumber = EXCLUDED.runnumber, segment = EXCLUDED.segment, size = EXCLUDED.size, dsttype = EXCLUDED.dsttype, events = EXCLUDED.events");

# first files table
$insertfile->execute($lfn,$outhost,$outfile,$size,$md5sum);

my $splitstring = "_run3auau_new_newcdbtag_v006";
my @sp1 = split(/$splitstring/,$lfn);
if (! defined $test)
{
#    $insertdataset->execute($lfn,$runnumber,$segment,$size,$sp1[0],$entries,"new_newcdbtag_v006");
    $insertdataset->execute($lfn,$runnumber,$segment,$size,$sp1[0],$entries,'new_newcdbtag_v006');
}
else
{
    print "db cmd: insertdataset->execute($lfn,$runnumber,$segment,$size,$sp1[0])\n";
}

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
    return 1; # lustre is mounted
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
