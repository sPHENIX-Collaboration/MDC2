#!/usr/bin/perl

use strict;
use File::Basename;
use File::stat;
use DBI;
use Getopt::Long;

my $mdc = "mdc2";
my $test;
GetOptions("test"=>\$test);

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

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc");
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
#my $getfiles = $dbh->prepare("select lfn,size,full_file_path from files where lfn = 'DST_TRUTH_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000002-02278.root'");
my $getfiles = $dbh->prepare("select lfn,size,full_file_path from files where full_file_path like '$dcachedir/%'"); 
my $chkfile = $dbh->prepare("select size from datasets where filename = ?");
my $insertdataset = $dbh->prepare("insert into datasets (filename,runnumber,segment,size,dataset,dsttype,events) values (?,?,?,?,'mdc2',?,?)");
#my $updatesize = $dbh->prepare("update files set size=? where lfn = ? and full_file_path = ?");

$getfiles->execute();
while (my @res = $getfiles->fetchrow_array)
{
    my $lfn = $res[0];
    my $fsize =  $res[1];
    my $fullfile = $res[2];
    $chkfile->execute($lfn);
    if ($chkfile->rows > 0)
    {
	my @ds = $chkfile->fetchrow_array;
	if ($ds[0] != $fsize)
	{
	    print "filesize mismatch, dataset: $ds[0], fcat: $fsize\n";
	    die;
	}
	next;
    }
#extract DST Type
    my $splitstring = "_sHijing";
    if ($lfn =~ /pythia8/)
    {
	$splitstring = "_pythia8";
    }
    my $runnumber = 0;
    my $segment = -1;
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/)
    {
	$runnumber = int($2);
	$segment = int($3);
    }
    my $entries = &getentries($lfn);
    my @sp1 = split(/$splitstring/,$lfn);
    if (! defined $test)
    {
	print "running: insertdataset->execute($lfn,$runnumber,$segment,$fsize,$sp1[0]),$entries\n";
	$insertdataset->execute($lfn,$runnumber,$segment,$fsize,$sp1[0],$entries);
    }
    else
    {
	print "would run insertdataset->execute($lfn,$runnumber,$segment,$fsize,$sp1[0]),$entries\n";
    }
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
