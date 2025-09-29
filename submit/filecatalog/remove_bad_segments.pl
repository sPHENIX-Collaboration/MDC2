#!/usr/bin/env perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

sub looparray;

my $topdir = "/sphenix/u/sphnxpro/MDC2/submit";

my $kill;
my $system = 0;
my $dsttype = "none";
my $runnumber = 7;
my $fm = "0_20fm";
my $nopileup;
my $verbose;
my $embed;
my $mom;
my $nobkgpileup;
my $ptmin;
my $ptmax;
my $particle;
my $pileup;
my $magnet;
GetOptions("dsttype:s"=>\$dsttype, "embed:s"=>\$embed, "fm:s" =>\$fm, "kill"=>\$kill, "magnet:s" => \$magnet, "nobkgpileup" => \$nobkgpileup, "nopileup"=>\$nopileup, "pileup:s" => \$pileup, "runnumber:i" => \$runnumber, "type:i"=>\$system, "verbose" => \$verbose);

#if (! defined $pileup)
#{
#   $pileup = "3MHz";
#}

my $AuAu_bkgpileup = sprintf("_50kHz_bkg_0_20fm");
my $pAu_bkgpileup = sprintf("_500kHz_bkg_0_10fm");
if (defined $nobkgpileup)
{
    $pAu_bkgpileup = sprintf("");
    $AuAu_bkgpileup = sprintf("");
}

#my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
my $attempts = 0;
CONNECTAGAIN:
if ($attempts > 0)
{
    print "connection attempt failed, sleeping and trying again\n";
    sleep(int(rand(21) + 10)); # sleep 10-30 seconds before retrying
}
$attempts++;
if ($attempts > 100)
{
    print "giving up connecting to DB after $attempts attempts\n";
    exit(1);
}
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || goto CONNECTAGAIN;
if ($attempts > 1)
{
    print "connections succeded after $attempts attempts\n";
}
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select full_file_path from files where lfn = ?");
my $deldataset = $dbh->prepare("delete from datasets where filename = ?");
my $delfcat = $dbh->prepare("delete from files where full_file_path = ?");
my %daughters = (
    "G4Hits" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT"],
#    "DST_BBC_G4HIT" => [ "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_MBD_EPD", "DSTOLD_BBC_G4HIT" ],
#    "DST_CALO_G4HIT" => [ "DST_BBC_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_CALO_CLUSTER", "DSTOLD_CALO_G4HIT" ],
#    "DST_TRKR_G4HIT" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRUTH_G4HIT", "DST_TRKR_HIT", "DST_TRUTH_RECO", "DSTOLD_TRKR_G4HIT"],
#    "DST_TRUTH_G4HIT" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH", "DSTOLD_TRUTH_G4HIT" ],
#    "DST_TRKR_HIT" => [ "DST_TRUTH", "DST_TRKR_CLUSTER", "DSTOLD_TRKR_HIT" ],
#    "DST_TRUTH" => [ "DST_TRKR_HIT", "DST_TRUTH_JET", "DST_TRUTH_RECO", "DSTOLD_TRUTH"],
    "DST_BBC_G4HIT" => [ "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_MBD_EPD" ],
    "DST_CALO_G4HIT" => [ "DST_BBC_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_CALO_CLUSTER", "DST_CALO_NOZERO" ],
    "DST_TRKR_G4HIT" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRUTH_G4HIT", "DST_TRKR_HIT", "DST_TRUTH_RECO" ],
    "DST_TRUTH_G4HIT" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH" ],
    "DST_TRKR_CLUSTER" => [ "DST_TRACKSEEDS", "DST_TRUTH_RECO" ],
    "DST_TRACKSEEDS" => [ "DST_TRACKS" ],
    "DST_TRKR_HIT" => [ "DST_TRUTH", "DST_TRKR_CLUSTER" ],
    "DST_TRUTH" => [ "DST_TRKR_HIT", "DST_TRUTH_JET", "DST_TRUTH_RECO" ],
#    "DST_TRKR_HIT" => [ "DST_TRUTH" ],
#    "DST_TRUTH" => [ "DST_TRKR_HIT" ],
    "DST_BBC_EPD" => [ "DST_GLOBAL" ],
    "DST_MBD_EPD" => [ "DST_GLOBAL" ],
    "DST_GLOBAL" => [ "" ],
    "DST_TRUTH_JET" => [ "" ],
    "DST_TRUTH_RECO" => [ "" ],
    "DST_TRKR_HIT_DISTORT" => [ "DST_TRUTH_DISTORT", "DST_TRACKS_DISTORT" ],
    "DST_TRUTH_DISTORT" => [ "DST_TRKR_HIT_DISTORT", "DST_TRACKS_DISTORT" ],
    "DST_TRACKS" => [ "DST_GLOBAL", "DST_TRUTH_RECO" ],
    "DST_TRACKS_DISTORT" => [ "" ],
#    "DST_CALO_CLUSTER" => [ "DST_TRACKS" ],
    "DST_CALO_CLUSTER" => [ "" ],
    "DST_CALO_NOZERO" => [ "DST_CALO_WAVEFORM" ],
    "DST_CALO_WAVEFORM" => [ "" ],
    "DSTOLD_BBC_G4HIT" => [ "" ],
    "DSTOLD_CALO_G4HIT" => [ "" ],
    "DSTOLD_TRKR_G4HIT" => [ "DSTOLD_TRKR_HIT" ],
    "DSTOLD_TRKR_HIT" => [ "DSTOLD_TRUTH" ],
    "DSTOLD_TRUTH_G4HIT" => [ "DSTOLD_TRUTH" ],
    "DSTOLD_TRUTH" => [ "DSTOLD_TRKR_HIT" ],
#    "DSTOLD_VERTEX" => [ "" ],
    "DST_JETS" => [ "" ],
    "DST_HF_CHARM" => [ "JET_EVAL_DST_HF_CHARM", "QA_DST_HF_CHARM"],
    "JET_EVAL_DST_HF_CHARM" => [ "DST_HF_CHARM", "QA_DST_HF_CHARM"],
    "QA_DST_HF_CHARM" => [ "DST_HF_CHARM", "JET_EVAL_DST_HF_CHARM"],
    "DST_HF_BOTTOM" => [ "JET_EVAL_DST_HF_BOTTOM", "QA_DST_HF_BOTTOM"],
    "JET_EVAL_DST_HF_BOTTOM" => [ "DST_HF_BOTTOM", "QA_DST_HF_BOTTOM"],
    "QA_DST_HF_BOTTOM" => [ "DST_HF_BOTTOM", "JET_EVAL_DST_HF_BOTTOM"]
    );

if (defined $nopileup)
{
    my $ref = $daughters{"DST_TRKR_HIT"};
    push(@$ref,("DST_CALO_CLUSTER", "DST_MBD_EPD"));
    @$ref = grep($_,@$ref); # removes empty strings from array

    $ref = $daughters{"DST_CALO_CLUSTER"};
    push(@$ref,("DST_TRKR_HIT","DST_MBD_EPD","DST_TRUTH"));
    @$ref = grep($_,@$ref); # removes empty strings from array

    $ref = $daughters{"DST_MBD_EPD"};
    push(@$ref,("DST_CALO_CLUSTER", "DST_TRKR_HIT","DST_TRUTH"));
    @$ref = grep($_,@$ref); # removes empty strings from array

    $ref = $daughters{"DST_TRUTH"};
    push(@$ref,("DST_CALO_CLUSTER","DST_MBD_EPD"));
    @$ref = grep($_,@$ref); # removes empty strings from array
}
if (defined $verbose)
{
    foreach my $ky (keys %daughters)
    {
	my @types = @{$daughters{$ky}};
	if ($#types > 0)
	{
	    print "$ky has @types\n";
	}
	else
	{
	    print "$ky has no entries\n";
	}
    }
}

if ($#ARGV < 0)
{
    print "usage: remove_bad_segments.pl -dsttype <type> <segment>\n";
    print "parameters:\n";
    print "-kill : remove files for real\n";
    print "-nopileup : HF datasets without pileup\n";
    print "-type : production type\n";
    print "    1 : hijing (0-12fm) pileup 0-12fm\n";
    print "    2 : hijing (0-4.88fm) pileup 0-12fm\n";
    print "    3 : pythia8 pp MB\n";
    print "    4 : hijing (0-20fm) pileup 0-20fm\n";
    print "    5 : hijing (0-12fm) pileup 0-20fm\n";
    print "    6 : hijing (0-4.88fm) pileup 0-20fm\n";
    print "    7 : HF pythia8 Charm\n";
    print "    8 : HF pythia8 Bottom\n";
    print "    9 : HF pythia8 CharmD0\n";
    print "   10 : HF pythia8 BottomD0\n";
    print "   11 : JS pythia8 Jet > 30GeV\n";
    print "   12 : JS pythia8 Jet > 10GeV\n";
    print "   13 : JS pythia8 Photon Jet\n";
    print "   14 : Single Particle\n";
    print "   16 : HF D0 Jet\n";
    print "   17 : HF pythia8 D0 pi-k Jets ptmin = 5GeV\n";
    print "   18 : HF pythia8 D0 pi-k Jets ptmin = 12GeV\n";
    print "   19 : JS pythia8 Jet > 30GeV\n";
    print "   20 : hijing pAu (0-10fm) pileup 0-10fm\n";
    print "   21 : JS pythia8 Jet >20GeV\n";
    print "   22 : AMPT\n";
    print "   23 : EPOS\n";
    print "   24 : Cosmics\n";
    print "   25 : JS pythia8 Detroit\n";
    print "   26 : JS pythia8 PhotonJet > 5GeV\n";
    print "   27 : JS pythia8 PhotonJet > 10GeV\n";
    print "   28 : JS pythia8 PhotonJet > 20GeV\n";
    print "   29 : Herwig MB\n";
    print "   30 : Herwig Jet ptmin = 10 GeV\n";
    print "   31 : Herwig Jet ptmin = 30 GeV\n";
    print "   32 : JS pythia8 Jet >15GeV\n";
    print "   33 : JS pythia8 Jet >50GeV\n";
    print "   34 : JS pythia8 Jet >70GeV\n";
    print "   35 : JS pythia8 Jet >5GeV\n";
    print "-dsttype:\n";
    foreach my $tp (sort keys %daughters)
    {
	print "$tp\n";
    }
    exit(0);
}

my $segment = $ARGV[0];

if( ! exists $daughters{$dsttype})
{
    print "bad dsttype $dsttype, existing types:\n";
    foreach my $tp (sort keys %daughters)
    {
	print "$tp\n";
    }
    exit(0);
}
if ($system < 1 || $system > 35)
{
    print "use -type, valid values:\n";
    print "-type : production type\n";
    print "    1 : hijing (0-12fm) pileup 0-12fm\n";
    print "    2 : hijing (0-4.88fm) pileup 0-12fm\n";
    print "    3 : pythia8 pp MB\n";
    print "    4 : hijing (0-20fm) pileup 0-20fm\n";
    print "    5 : hijing (0-12fm) pileup 0-20fm\n";
    print "    6 : hijing (0-4.88fm) pileup 0-20fm\n";
    print "    7 : HF pythia8 Charm\n";
    print "    8 : HF pythia8 Bottom\n";
    print "    9 : HF pythia8 CharmD0\n";
    print "   10 : HF pythia8 BottomD0\n";
    print "   11 : JS pythia8 Jet >30GeV\n";
    print "   12 : JS pythia8 Jet >10GeV\n";
    print "   13 : JS pythia8 Jet Photon Jet\n";
    print "   14 : Single Particle\n";
    print "   16 : HF D0 Jet\n";
    print "   17 : HF pythia8 D0 pi-k Jets ptmin = 5GeV\n";
    print "   18 : HF pythia8 D0 pi-k Jets ptmin = 12GeV\n";
    print "   19 : JS pythia8 Jet >40GeV\n";
    print "   20 : hijing pAu (0-10fm) pileup 0-10fm\n";
    print "   21 : JS pythia8 Jet >20GeV\n";
    print "   22 : AMPT\n";
    print "   23 : EPOS\n";
    print "   24 : Cosmics\n";
    print "   25 : JS pythia8 Detroit\n";
    print "   26 : JS pythia8 PhotonJet > 5GeV\n";
    print "   27 : JS pythia8 PhotonJet > 10GeV\n";
    print "   28 : JS pythia8 PhotonJet > 20GeV\n";
    print "   29 : Herwig MB\n";
    print "   30 : Herwig Jet ptmin = 10 GeV\n";
    print "   31 : Herwig Jet ptmin = 30 GeV\n";
    print "   32 : JS pythia8 Jet >15GeV\n";
    print "   33 : JS pythia8 Jet >50GeV\n";
    print "   34 : JS pythia8 Jet >70GeV\n";
    print "   35 : JS pythia8 Jet >5GeV\n";
    exit(0);
}

my $systemstring;
my %specialsystemstring = ();
my $pileupdir;
my $condorfileadd;
my $pileupstring;
my %specialcondorfileadd = ();
my %productionsubdir = (
    "DST_BBC_EPD"=> "pass3_bbcepd",
    "DST_BBC_G4HIT" => "pass2",
    "DST_CALO_NOZERO" => "pass3calo_nozero",
    "DST_CALO_CLUSTER" => "pass3calo",
    "DST_CALO_G4HIT"=> "pass2",
    "DST_GLOBAL"=> "pass5_global",
    "DST_JETS"=> "pass5jetreco",
    "DST_MBD_EPD"=> "pass3_mbdepd",
    "DST_TRACKS" => "pass4_jobC",
    "DST_TRACKSEEDS" => "pass4_jobA",
    "DST_TRACKS_DISTORT" => "pass4distort",
    "DST_TRKR_HIT" => "pass3trk",
    "DST_TRKR_HIT_DISTORT" => "pass3distort",
    "DST_TRKR_CLUSTER" => "pass4_job0",
    "DST_TRKR_G4HIT" => "pass2",
    "DST_TRUTH_G4HIT" => "pass2",
    "DST_TRUTH" => "pass3trk",
    "DST_TRUTH_JET" => "pass4jet",
    "DST_TRUTH_RECO" => "pass5_truthreco",
    "DST_TRUTH_DISTORT" => "pass3distort",
    "G4Hits" => "pass1"
    );
if (defined $nopileup && !defined $nobkgpileup)
{
    $productionsubdir{"DST_TRKR_HIT"} = "pass2_nopileup";
    $productionsubdir{"DST_CALO_CLUSTER"} = "pass2_nopileup";
    $productionsubdir{"DST_CALO_NOZERO"} = "pass2calo_nopileup_nozero";
    $productionsubdir{"DST_CALO_WAVEFORM"} = "pass2calo_waveform_nopileup";
    $productionsubdir{"DST_BBC_EPD"} = "pass2_nopileup";
    $productionsubdir{"DST_MBD_EPD"} = "pass2_nopileup";
    $productionsubdir{"DST_GLOBAL"} = "pass3_global_nopileup";
    $productionsubdir{"DST_TRKR_CLUSTER"} = "pass3_job0_nopileup";
    $productionsubdir{"DST_TRUTH"} = "pass2_nopileup";
    $productionsubdir{"DST_TRACKS"} = "pass3_jobC_nopileup";
    $productionsubdir{"DST_TRACKSEEDS"} = "pass3_jobA_nopileup";
    $productionsubdir{"DST_TRUTH_JET" } = "pass3jet_nopileup",
    $productionsubdir{"DST_TRUTH_RECO"} = "pass4_truthreco_nopileup"
}
if (defined $nobkgpileup)
{
    $productionsubdir{"DST_BBC_G4HIT"} = "pass2_embed_nopileup";
    $productionsubdir{"DST_CALO_CLUSTER"} = "pass3calo_embed_nopileup";
    $productionsubdir{"DST_CALO_G4HIT"} = "pass2_embed_nopileup";
    $productionsubdir{"DST_TRKR_G4HIT"} = "pass2_embed_nopileup";
    $productionsubdir{"DST_TRUTH_G4HIT"} = "pass2_embed_nopileup";
    $productionsubdir{"DST_BBC_EPD"} = "pass3_mbdepd_embed_nopileup";
    $productionsubdir{"DST_MBD_EPD"} = "pass3_mbdepd_embed_nopileup";
    $productionsubdir{"DST_GLOBAL"} = "pass4_global_embed_nopileup";
    $productionsubdir{"DST_TRUTH_JET" } = "pass3jet_embed_nopileup",
}

if (defined $pileup)
{
    if ($pileup ne "3MHz")
    {
#	$productionsubdir{"DST_BBC_G4HIT"} = sprintf("pass2_%s",$pileup);
#	$productionsubdir{"DST_CALO_G4HIT"} = sprintf("pass2_%s",$pileup);
#	$productionsubdir{"DST_TRKR_G4HIT"} = sprintf("pass2_%s",$pileup);
#	$productionsubdir{"DST_TRUTH_G4HIT"} = sprintf("pass2_%s",$pileup);
#	$productionsubdir{"DST_TRKR_HIT"} = sprintf("pass3trk_%s",$pileup);
#	$productionsubdir{"DST_TRUTH"} = sprintf("pass3trk_%s",$pileup);
    }
}

if (defined $embed)
{
    my $embedpostfix = "_embed";
    if ($embed eq "pau")
    {
	$embedpostfix = sprintf("%s_%s",$embedpostfix,$embed);
    }
    $productionsubdir{"DST_BBC_G4HIT"} = sprintf("pass2%s",$embedpostfix);
    $productionsubdir{"DST_CALO_CLUSTER"} = sprintf("pass3calo%s",$embedpostfix);
    $productionsubdir{"DST_CALO_NOZERO"} = "pass3calo_nozero_embed";
    $productionsubdir{"DST_CALO_G4HIT"} = sprintf("pass2%s",$embedpostfix);
    $productionsubdir{"DST_BBC_EPD"} = sprintf("pass3_bbcepd%s",$embedpostfix);
    $productionsubdir{"DST_TRUTH"} = sprintf("pass3trk%s",$embedpostfix);
    $productionsubdir{"DST_TRUTH_G4HIT"} = sprintf("pass2%s",$embedpostfix);
    $productionsubdir{"DST_TRACKS"} = sprintf("pass4_jobC%s",$embedpostfix);
    $productionsubdir{"DST_TRACKSEEDS"} = sprintf("pass4_jobA%s",$embedpostfix);
    $productionsubdir{"DST_TRKR_CLUSTER"} = sprintf("pass4_job0%s",$embedpostfix);
    $productionsubdir{"DST_GLOBAL"} = sprintf("pass5_global%s",$embedpostfix);
    $productionsubdir{"DST_TRUTH_RECO"} = sprintf("pass5_truthreco%s",$embedpostfix);

    $productionsubdir{"DST_TRKR_HIT"} = sprintf("pass3trk%s",$embedpostfix);
    $productionsubdir{"DST_TRKR_G4HIT"} = sprintf("pass2%s",$embedpostfix);
    $productionsubdir{"DST_TRUTH_JET" } = sprintf("pass4jet%s",$embedpostfix),
}
else
{
}

my %notlike = ();
if ($system == 1)
{
    $systemstring = "sHijing_0_12fm_50kHz_bkg_0_12fm";
    $topdir = sprintf("%s/fm_0_12",$topdir);
}
elsif ($system == 2)
{
    $systemstring = "sHijing_0_488fm_50kHz_bkg_0_12fm";
    $topdir = sprintf("%s/fm_0_488",$topdir);
}
elsif ($system == 3)
{
    $systemstring = "pythia8_pp_mb";
    $specialsystemstring{"G4Hits"} = "pythia8_pp_mb-";
    $pileupstring = sprintf("_%s",$pileup);
#    $systemstring = "pythia8_pp_mb_";
    $topdir = sprintf("%s/pythia8_pp_mb",$topdir);
}
elsif ($system == 4)
{
    $systemstring = "sHijing_0_20fm";
    if ($dsttype =~ /NEW/)
    {
	$topdir = sprintf("%s/FixDST/fm_0_20",$topdir);
    }
    else
    {
	$topdir = sprintf("%s/fm_0_20",$topdir);
    }
    $pileupstring = "_50kHz_bkg_0_20fm";
    $notlike{$systemstring} = ["pythia8" ,"single", "special"];
}
elsif ($system == 5)
{
    $systemstring = "sHijing_0_12fm_50kHz_bkg_0_20fm";
    $topdir = sprintf("%s/fm_0_12",$topdir);
    $pileupdir = "_50kHz_0_20fm";
}
elsif ($system == 6)
{
    $systemstring = "sHijing_0_488fm";
    $topdir = sprintf("%s/fm_0_488",$topdir);
#    $pileupdir = "50kHz_0_20fm";
    $pileupstring = "_50kHz_bkg_0_20fm";
    $notlike{$systemstring} = ["pythia8" ,"single", "special"];
}
elsif ($system == 7)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Charm-";
    $systemstring = "pythia8_Charm_";
    $topdir = sprintf("%s/HF_pp200_signal",$topdir);
    $condorfileadd = sprintf("Charm_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Charm");
        $systemstring = "pythia8_Charm";
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Charm");
        $systemstring = "pythia8_Charm";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s_50kHz_bkg_0_20fm",$fm);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Charm";
}
elsif ($system == 8)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Bottom-";
    $systemstring = "pythia8_Bottom_";
    $topdir = sprintf("%s/HF_pp200_signal",$topdir);
    $condorfileadd = sprintf("Bottom_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Bottom");
        $systemstring = "pythia8_Bottom";
    }
    $specialcondorfileadd{"G4Hits"} = "Bottom";
}
elsif ($system == 9)
{
    $specialsystemstring{"G4Hits"} = "pythia8_CharmD0-";
    $systemstring = "pythia8_CharmD0_";
    $topdir = sprintf("%s/HF_pp200_signal",$topdir);
    $condorfileadd = sprintf("CharmD0_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("CharmD0");
        $systemstring = "pythia8_CharmD0";
    }
    $specialcondorfileadd{"G4Hits"} = "CharmD0";
}
elsif ($system == 10)
{
    $specialsystemstring{"G4Hits"} = "pythia8_BottomD0-";
    $systemstring = "pythia8_BottomD0_";
    $topdir = sprintf("%s/HF_pp200_signal",$topdir);
    $condorfileadd = sprintf("BottomD0_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("BottomD0");
        $systemstring = "pythia8_BottomD0";
    }
    $specialcondorfileadd{"G4Hits"} = "BottomD0";
}
elsif ($system == 11)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Jet30-";
    $systemstring = "pythia8_Jet30_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    $condorfileadd = sprintf("Jet30_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Jet30");
        $systemstring = "pythia8_Jet30";
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Jet30");
        $systemstring = "pythia8_Jet30";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Jet30";
}
elsif ($system == 12)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Jet10-";
    $systemstring = "pythia8_Jet10_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Jet10");
        $systemstring = "pythia8_Jet10";
    }
    else
    {
      $condorfileadd = sprintf("Jet10_%s",$pileup);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Jet10");
        $systemstring = "pythia8_Jet10";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Jet10";
}
elsif ($system == 13)
{
    $specialsystemstring{"G4Hits"} = "pythia8_PhotonJet-";
    $systemstring = "pythia8_PhotonJet_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    $condorfileadd = sprintf("PhotonJet_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("PhotonJet");
        $systemstring = "pythia8_PhotonJet";
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("PhotonJet");
        $systemstring = "pythia8_PhotonJet";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "PhotonJet";
}
elsif ($system == 14)
{
    if ($#ARGV == 4)
    {
        $particle = $ARGV[1];
        $mom = $ARGV[2];
	$ptmin = $ARGV[3];
	$ptmax = $ARGV[4];
    }
    else
    {
	print "needs arguments segment particle [p or pt] ptmin ptmax\n";
        exit(1)
    }
    my $snglstring = sprintf("single_%s_%s_%d_%dMeV",$particle,$mom,$ptmin,$ptmax);
    $specialsystemstring{"G4Hits"} = sprintf("%s-",$snglstring);
    $systemstring = sprintf("%s_",$snglstring);
#    $topdir = sprintf("%s/multiple_particle",$topdir);
    $topdir = sprintf("%s/single_particle",$topdir);
    $condorfileadd = sprintf("%s",$snglstring);
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("%s",$snglstring);
        $systemstring = sprintf("single_%s",$snglstring);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("%s",$snglstring);
        $systemstring = sprintf("%s",$snglstring);
        $pileupstring = "_sHijing_0_20fm_50kHz_bkg_0_20fm";
    }
    $specialcondorfileadd{"G4Hits"} = "$snglstring";
}
elsif ($system == 16)
{
    $specialsystemstring{"G4Hits"} = "pythia8_JetD0-";
    $systemstring = "pythia8_JetD0_";
    $topdir = sprintf("%s/HF_pp200_signal",$topdir);
    $condorfileadd = sprintf("JetD0_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("JetD0");
        $systemstring = "pythia8_JetD0";
    }
    $specialcondorfileadd{"G4Hits"} = "JetD0";
}
elsif ($system == 17)
{
    $specialsystemstring{"G4Hits"} = "pythia8_CharmD0piKJet5-";
    $systemstring = "pythia8_CharmD0piKJet5_";
    $topdir = sprintf("%s/HF_pp200_signal",$topdir);
    $condorfileadd = sprintf("CharmD0piKJet5_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("CharmD0piKJet5");
        $systemstring = "pythia8_CharmD0piKJet5";
    }
    $specialcondorfileadd{"G4Hits"} = "CharmD0piKJet5";
}
elsif ($system == 18)
{
    $specialsystemstring{"G4Hits"} = "pythia8_CharmD0piKJet12-";
    $systemstring = "pythia8_CharmD0piKJet12_";
    $topdir = sprintf("%s/HF_pp200_signal",$topdir);
    $condorfileadd = sprintf("CharmD0piKJet12_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("CharmD0piKJet12");
        $systemstring = "pythia8_CharmD0piKJet12";
    }
    $specialcondorfileadd{"G4Hits"} = "CharmD0piKJet12";
}
elsif ($system == 19)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Jet40-";
    $systemstring = "pythia8_Jet40_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    $condorfileadd = sprintf("Jet40_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Jet40");
        $systemstring = "pythia8_Jet40";
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Jet40");
        $systemstring = "pythia8_Jet40";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Jet40";
}
elsif ($system == 20)
{
    $systemstring = "sHijing_pAu_0_10fm";
    $topdir = sprintf("%s/pAu_0_10fm",$topdir);
    $pileupstring = "_500kHz_bkg_0_10fm";
    $notlike{$systemstring} = ["pythia8" ,"single", "special"];
}
elsif ($system == 21)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Jet20-";
    $systemstring = "pythia8_Jet20_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    $condorfileadd = sprintf("Jet20_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Jet20");
        $systemstring = "pythia8_Jet20";
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Jet20");
        $systemstring = "pythia8_Jet20";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = "_sHijing_0_20fm_50kHz_bkg_0_20fm";
	}

    }
    $specialcondorfileadd{"G4Hits"} = "Jet20";
}
elsif ($system == 22)
{
    $systemstring = "ampt_0_20fm";
    $topdir = sprintf("%s/ampt",$topdir);
    $pileupstring = "_50kHz_bkg_0_20fm";
    $notlike{$systemstring} = ["pythia8" ,"single", "special"];
}
elsif ($system == 23)
{
    $systemstring = "epos_0_153fm";
    $topdir = sprintf("%s/epos",$topdir);
    $pileupstring = "_50kHz_bkg_0_153fm";
    $notlike{$systemstring} = ["pythia8" ,"single", "special"];
}
elsif ($system == 24)
{
    if (! defined $magnet)
    {
	print "need to add --magnet <on> or <off>\n";
	exit 1;
    }
    if ($magnet ne "on" && $magnet ne "off")
    {
	print "--magnet only <on> or <off>, not $magnet\n";
	exit 1;
    }
    $systemstring = sprintf("cosmic_magnet_%s",$magnet);
    $topdir = sprintf("%s/cosmic",$topdir);
    $pileupstring = "";
    $notlike{$systemstring} = ["pythia8" ,"single", "special"];
}
elsif ($system == 25)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Detroit-";
    $systemstring = "pythia8_Detroit_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Detroit");
        $systemstring = "pythia8_Detroit";
    }
    else
    {
        $condorfileadd = sprintf("Detroit_%s",$pileup);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Detroit");
        $systemstring = "pythia8_Detroit";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Detroit";
}
elsif ($system == 26)
{
    $specialsystemstring{"G4Hits"} = "pythia8_PhotonJet5-";
    $systemstring = "pythia8_PhotonJet5_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    $condorfileadd = sprintf("PhotonJet5_%s",$pileup);
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("PhotonJet5");
        $systemstring = "pythia8_PhotonJet5";
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("PhotonJet5");
        $systemstring = "pythia8_PhotonJet5";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "PhotonJet5";
}
elsif ($system == 27)
{
    $specialsystemstring{"G4Hits"} = "pythia8_PhotonJet10-";
    $systemstring = "pythia8_PhotonJet10_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("PhotonJet10");
        $systemstring = "pythia8_PhotonJet10";
    }
    else
    {
      $condorfileadd = sprintf("PhotonJet10_%s",$pileup);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("PhotonJet10");
        $systemstring = "pythia8_PhotonJet10";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "PhotonJet10";
}
elsif ($system == 28)
{
    $specialsystemstring{"G4Hits"} = "pythia8_PhotonJet20-";
    $systemstring = "pythia8_PhotonJet20_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("PhotonJet20");
        $systemstring = "pythia8_PhotonJet20";
    }
    else
    {
      $condorfileadd = sprintf("PhotonJet20_%s",$pileup);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("PhotonJet20");
        $systemstring = "pythia8_PhotonJet20";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "PhotonJet20";
}
elsif ($system == 29)
{
    $specialsystemstring{"G4Hits"} = "Herwig_MB-";
    $systemstring = "Herwig_MB_";
    $topdir = sprintf("%s/Herwig",$topdir);
    if (defined $nopileup)
    {
#	$condorfileadd = sprintf("MB");
        $systemstring = "Herwig_MB";
    }
    else
    {
      $condorfileadd = sprintf("MB_%s",$pileup);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Herwig");
        $systemstring = "Herwig_MB";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "MB";
}
elsif ($system == 30)
{
    $specialsystemstring{"G4Hits"} = "Herwig_Jet10-";
    $systemstring = "Herwig_Jet10_";
    $topdir = sprintf("%s/Herwig",$topdir);
    if (defined $nopileup)
    {
#	$condorfileadd = sprintf("Jet10");
        $systemstring = "Herwig_Jet10";
    }
    else
    {
      $condorfileadd = sprintf("Jet10_%s",$pileup);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Herwig");
        $systemstring = "Herwig_Jet10";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Jet10";
}
elsif ($system == 31)
{
    $specialsystemstring{"G4Hits"} = "Herwig_Jet30-";
    $systemstring = "Herwig_Jet30_";
    $topdir = sprintf("%s/Herwig",$topdir);
    if (defined $nopileup)
    {
#	$condorfileadd = sprintf("Jet30");
        $systemstring = "Herwig_Jet30";
    }
    else
    {
      $condorfileadd = sprintf("Jet30_%s",$pileup);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Herwig");
        $systemstring = "Herwig_Jet30";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Jet30";
}
elsif ($system == 32)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Jet15-";
    $systemstring = "pythia8_Jet15_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Jet15");
        $systemstring = "pythia8_Jet15";
    }
    else
    {
	$condorfileadd = sprintf("Jet15_%s",$pileup);
    }	
    if (defined $embed)
    {
	$condorfileadd = sprintf("Jet15");
        $systemstring = "pythia8_Jet15";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Jet15";
}
elsif ($system == 33)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Jet50-";
    $systemstring = "pythia8_Jet50_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Jet50");
        $systemstring = "pythia8_Jet50";
    }
    else
    {
      $condorfileadd = sprintf("Jet50_%s",$pileup);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Jet50");
        $systemstring = "pythia8_Jet50";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Jet50";
}
elsif ($system == 34)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Jet70-";
    $systemstring = "pythia8_Jet70_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Jet70");
        $systemstring = "pythia8_Jet70";
    }
    else
    {
      $condorfileadd = sprintf("Jet70_%s",$pileup);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Jet70");
        $systemstring = "pythia8_Jet70";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Jet70";
}
elsif ($system == 35)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Jet5-";
    $systemstring = "pythia8_Jet5_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Jet5");
        $systemstring = "pythia8_Jet5";
    }
    else
    {
      $condorfileadd = sprintf("Jet5_%s",$pileup);
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Jet5");
        $systemstring = "pythia8_Jet5";
	if ($embed eq "pau")
	{
	    $pileupstring = "_sHijing_pAu_0_10fm_500kHz_bkg_0_10fm";
	}
	else
	{
	    $pileupstring = sprintf("_sHijing_%s%s",$fm,$AuAu_bkgpileup);
	}
    }
    $specialcondorfileadd{"G4Hits"} = "Jet5";
}
else
{
    die "bad type $system\n";
}
my $conds = sprintf("dsttype = ? and filename like ? and segment = ? and runnumber = ?");
if (exists $notlike{$systemstring})
{
    my $ref = $notlike{$systemstring};
    foreach my $item  (@$ref)
    {
	$conds = sprintf("%s and filename not like  \'\%%%s%\%\'",$conds,$item);
    }
}
my $sqlcmd = sprintf("select filename from datasets where %s  order by filename",$conds);
#my $getfilename = $dbh->prepare("select filename from datasets where dsttype = ? and filename like ? and segment = ? and runnumber = ? order by filename") || die $DBI::errstr;
my $getfilename = $dbh->prepare($sqlcmd) || die $DBI::errstr;
#print "sqlcmd: $sqlcmd\n";
if (defined $pileupdir)
{
    $productionsubdir{"DST_BBC_G4HIT"} = sprintf("%s_%s",$productionsubdir{"DST_BBC_G4HIT"},$pileupdir);
    $productionsubdir{"DST_CALO_CLUSTER"} = sprintf("%s_%s",$productionsubdir{"DST_CALO_CLUSTER"},$pileupdir);
    $productionsubdir{"DST_CALO_G4HIT"} = sprintf("%s_%s",$productionsubdir{"DST_CALO_G4HIT"},$pileupdir);
    $productionsubdir{"DST_TRACKS"} = sprintf("%s_%s",$productionsubdir{"DST_TRACKS"},$pileupdir);
    $productionsubdir{"DST_TRKR_CLUSTER"} = sprintf("%s_%s",$productionsubdir{"DST_TRKR_CLUSTER"},$pileupdir);
    $productionsubdir{"DST_TRKR_G4HIT"} = sprintf("%s_%s",$productionsubdir{"DST_TRKR_G4HIT"},$pileupdir);
    $productionsubdir{"DST_TRUTH_G4HIT"} = sprintf("%s_%s",$productionsubdir{"DST_TRUTH_G4HIT"},$pileupdir);
}


my %removecondorfiles = ();
my %removethese = ();
$removethese{$dsttype} = 1;
&looparray($dsttype);
foreach my $rem (keys %removethese)
{
    my $loopsystemstring = $systemstring;
    #only pp runs samples without pileup
    if (! defined $nopileup)
    {
	if (! defined $pileupstring)
	{
	    $loopsystemstring = sprintf("%s%s-",$loopsystemstring,$pileup);
	}
	else
	{
	    $loopsystemstring = sprintf("%s%s-",$loopsystemstring,$pileupstring);
	}

    }
    else
    {
	$loopsystemstring = sprintf("%s-",$loopsystemstring);
    }

    if (exists $specialsystemstring{$rem})
    {
	$loopsystemstring = $specialsystemstring{$rem};
    }
    my $condor_subdir = sprintf("%s",$topdir);
    if (exists $productionsubdir{$rem})
    {
	if (defined $embed)
	{
	    $condor_subdir = sprintf("%s/%s/condor/log/%s/run%d",$condor_subdir,$productionsubdir{$rem},$fm,$runnumber);
	}
	else
	{
	    $condor_subdir = sprintf("%s/%s/condor/log/run%d",$condor_subdir,$productionsubdir{$rem},$runnumber);
	}
	if (defined $condorfileadd)
	{
	    my $condorsubdir = sprintf("%s/%s",$condor_subdir,$condorfileadd);
	    if (-d $condorsubdir)
	    {
		$condor_subdir = sprintf("%s",$condorsubdir);
	    }
	}
	if (exists $specialcondorfileadd{$rem})
	{
	    my $condorsubdir = sprintf("%s/%s",$condor_subdir,$specialcondorfileadd{$rem});
	    if (-d $condorsubdir)
	    {
		$condor_subdir = sprintf("%s",$condorsubdir);
	    }
	}

    }
    else
    {
	#print "productionsubdir for $rem\n";
	$condor_subdir = sprintf("%s/condor/log",$condor_subdir);
    }
    my $condornameprefix = sprintf("condor");
    if ($system == 3)
    {
	if ( $rem ne "G4Hits" && !defined $nopileup)
	{
	    $condornameprefix = sprintf("condor%s",$pileupstring);
	}
	else
	{
	    $condornameprefix = sprintf("condor");
	}
    }
if (defined $magnet)
 {
    $condor_subdir = sprintf("%s/magnet_%s",$condor_subdir,$magnet);
}
    if (defined $verbose)
    {
	print "condor_subdir: $condor_subdir\n";
    }
    if (defined $condorfileadd)
    {
	if (exists $specialcondorfileadd{$rem})
	{
	    $condornameprefix = sprintf("%s_%s",$condornameprefix,$specialcondorfileadd{$rem});
	}
	else
	{
	    $condornameprefix = sprintf("%s_%s",$condornameprefix,$condorfileadd);
	}
    }
    $removecondorfiles{sprintf("%s/%s-%010d-%05d.job",$condor_subdir,$condornameprefix,$runnumber,$segment)} = 1;
    $removecondorfiles{sprintf("%s/%s-%010d-%05d.out",$condor_subdir,$condornameprefix,$runnumber,$segment)} = 1;
    $removecondorfiles{sprintf("%s/%s-%010d-%05d.err",$condor_subdir,$condornameprefix,$runnumber,$segment)} = 1;
    $removecondorfiles{sprintf("%s/%s-%010d-%05d.log",$condor_subdir,$condornameprefix,$runnumber,$segment)} = 1;
    $removecondorfiles{sprintf("%s/%s-%010d-%06d.job",$condor_subdir,$condornameprefix,$runnumber,$segment)} = 1;
    $removecondorfiles{sprintf("%s/%s-%010d-%06d.out",$condor_subdir,$condornameprefix,$runnumber,$segment)} = 1;
    $removecondorfiles{sprintf("%s/%s-%010d-%06d.err",$condor_subdir,$condornameprefix,$runnumber,$segment)} = 1;
    $removecondorfiles{sprintf("%s/%s-%010d-%06d.log",$condor_subdir,$condornameprefix,$runnumber,$segment)} = 1;
    if ($condor_subdir =~ /pass2/)
    {
	$removecondorfiles{sprintf("%s/%s-%010d-%05d.bkglist",$condor_subdir,$condornameprefix,$runnumber,$segment)} = 1;
	$removecondorfiles{sprintf("%s/%s-%010d-%06d.bkglist",$condor_subdir,$condornameprefix,$runnumber,$segment)} = 1;
    }
    my $lfn = sprintf("%s_%s-%010d-%05d.root",$rem,$loopsystemstring,$runnumber,$segment);
    if (defined $verbose && $rem ne 'G4Hits')
    {
	print "getfilename->execute($rem,'%'.$loopsystemstring.'%',$segment,$runnumber)\n";
    }
    if ($rem eq 'G4Hits')
    {
	$getfilename->execute($rem,'%'.$systemstring.'%',$segment,$runnumber);
	if (defined $verbose)
	{
	    print "getfilename->execute($rem,'%'.$systemstring.'%',$segment,$runnumber)\n";
	}
    }
    else
    {
	$getfilename->execute($rem,'%'.$loopsystemstring.'%',$segment,$runnumber);
    }
    if ($getfilename->rows == 1)
    {
	my @res = $getfilename->fetchrow_array();
	$getfiles->execute($res[0]);
	while (my @res2 = $getfiles->fetchrow_array())
	{
	    if (! defined $nopileup && $res2[0] =~ /nopileup/)
	    {
		print "getfiles ($res[0]): trying to remove $res2[0]\n";
#		die;
	    }
	    if (defined $nopileup && $res2[0] !~ /nopileup/)
	    {
		print "nopileup getfiles ($res[0]): trying to remove $res2[0]\n";
#		die;
	    }
	    if (defined $kill)
	    {
		print "rm $res2[0], deleting from fcat\n";
		unlink $res2[0];
		$delfcat->execute($res2[0]);
	    }
	    else
	    {
		print "would rm $res2[0]\n";
	    }
	}
	if (defined $kill)
	{
	    print "removing $res[0] from datasets\n";
	    $deldataset->execute($res[0]);
	}
	else
	{
	    print "would remove $res[0] from datasets\n";
	}

    }
}
foreach my $condorfile (keys %removecondorfiles)
{
    if (defined $verbose)
    {
	print "condorfile: $condorfile\n";
    }
    if (-f $condorfile)
    {
	if (defined $kill)
	{
	    print "removing $condorfile\n";
	    unlink $condorfile;
	}
	else
	{
	    print "would remove $condorfile\n";
	}
    }
    else
    {
#    print "cannot locate $condorfile\n";
    }
}


sub looparray
{
    my $thistype = $_[0];
    if (! exists $daughters{$thistype})
    {
	print "no entry for $thistype in daughter hash:\n";
	foreach my $dghter (sort keys %daughters)
	{
	    print "$dghter\n";
	}
	die;
    }
    my @types = @{$daughters{$thistype}};
    foreach my $entry (@types)
    {
	if (exists $removethese{$entry})
	{
	    next;
	}
	if ($entry eq "")
	{
	    return;
	}
	$removethese{$entry} = 1;
 	&looparray($entry);
    }
}
