#!/usr/bin/env perl

use strict;
use File::Basename;
use File::stat;
use DBI;
use Getopt::Long;

my $mdc = "cosmics";
my $test;
my $lfncomp;
GetOptions("lfn:s" => \$lfncomp, "test"=>\$test);

my $dcachedir = $ARGV[0];
if (! -d $dcachedir)
{
    print "could not find directory $dcachedir\n";
    exit(1);
}
if ($dcachedir !~ /lustre/ && $dcachedir !~ /data/)
{
    print "only pnfs (dcache) dirs allowed\n";
    exit(1);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc");
#my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc",{ RaiseError => 1, AutoCommit => 0 });
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
#my $getfiles = $dbh->prepare("select lfn,size,full_file_path from files where lfn = 'DST_TRUTH_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000002-02278.root'");
#my $getfiles = $dbh->prepare("select lfn,size,full_file_path from files where full_file_path like '$dcachedir/%'"); 
#my $getfiles = $dbh->prepare("select lfn,size,full_file_path from files where lfn like '%run2pp_ana441_2024p007-000%' and not exists (select * from datasets where files.lfn = datasets.filename)");
my $getfiles = $dbh->prepare("select lfn,size,full_file_path from files where lfn like '%ana.386_2023p003-000%' and not exists (select * from datasets where files.lfn = datasets.filename)");
#my $getfiles = $dbh->prepare("select lfn,size,full_file_path from files where lfn like '%ana399_2023p008-000%' and not exists (select * from datasets where files.lfn = datasets.filename)"); 
#my $getfiles = $dbh->prepare("select lfn,size,full_file_path from files where lfn = 'G4Hits_sHijing_0_20fm-0000000006-18875.root'");
#my $chkfile = $dbh->prepare("select size from datasets where filename = ?");
#my $insertdataset = $dbh->prepare("insert into datasets (filename,runnumber,segment,size,dataset,dsttype,events) values (?,?,?,?,'$mdc',?,?)");
my $insertdataset = $dbh->prepare("insert into datasets (filename,runnumber,segment,size,dataset,dsttype,events) values (?,?,?,?,?,?,?)");
#my $updatesize = $dbh->prepare("update files set size=? where lfn = ? and full_file_path = ?");
#$dbh->do("SET AUTOCOMMIT OFF");
$getfiles->execute();
my $count = 0;
while (my @res = $getfiles->fetchrow_array)
{
    my $lfn = $res[0];
    if (defined $lfncomp)
{
    my $startstring = substr($lfn,0,length($lfncomp));
    if ($startstring !~ /$lfncomp/)
    {
	print "not inserting $lfn, startstring: $startstring, lfn: $lfncomp\n";
	next;
    }
}
my $fsize =  $res[1];
my $fullfile = $res[2];
#    $chkfile->execute($lfn);
#    if ($chkfile->rows > 0)
#    {
#	my @ds = $chkfile->fetchrow_array;
#	if ($ds[0] != $fsize)
#	{
#	    print "filesize mismatch for $lfn, dataset: $ds[0], fcat: $fsize\n";
#	    die;
#	}
#	next;
#   }
#extract DST Type
my $splitstring = "_sHijing";
if ($lfn =~ /pythia8/)
{
    $splitstring = "_pythia8";
}
if ($lfn =~ /run2pp/)
{
    $splitstring = "_run2pp";
}
if ($lfn =~ /run2auau/)
{
    $splitstring = "_run2auau";
}
my $runnumber = 0;
my $segment = -1;
if ($lfn =~ /(\S+)-(\d+)-(\d+)-(\d+)-(\d+).*\..*/)
{
    $runnumber = int($2);
    $segment = int($4);
}
elsif ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/)
{
    $runnumber = int($2);
    $segment = int($3);
}
my $entries = -1;
my $substring = substr($lfn,0,4);
#if ($substring =~ /DST/)
if ($substring =~ /notrsis/)
{
  $entries = &getentries($lfn);
}

my @sp1 = split(/$splitstring/,$lfn);
if (! defined $test)
{
    print "running: insertdataset->execute($lfn,$runnumber,$segment,$fsize,$mdc, $sp1[0],$entries)\n";
    $insertdataset->execute($lfn,$runnumber,$segment,$fsize,$mdc,$sp1[0],$entries);
}
else
{
    print "would run insertdataset->execute($lfn,$runnumber,$segment,$fsize,$mdc,$sp1[0],$entries)\n";
}
}
$getfiles->finish();

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
	print F "  if (! T)\n";
	print F "  {\n";
	print F "    cout << \"Number of Entries: -1\" << endl;\n";
	print F "  }\n";
	print F "  else\n";
	print F "  {\n";
	print F "    cout << \"Number of Entries: \" <<  T->GetEntries() << endl;\n";
	print F "  }\n";
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
