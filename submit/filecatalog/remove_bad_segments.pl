#!/usr/bin/perl

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
my $runnumber = 6;
my $nopileup;
my $verbose;
my $embed;
my $ptmin;
my $ptmax;
my $particle;
GetOptions("dsttype:s"=>\$dsttype, "embed"=>\$embed, "kill"=>\$kill, "nopileup"=>\$nopileup, "runnumber:i" => \$runnumber, "type:i"=>\$system, "verbose" => \$verbose);

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::errstr;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select full_file_path from files where lfn = ?");
my $deldataset = $dbh->prepare("delete from datasets where filename = ?");
my $delfcat = $dbh->prepare("delete from files where full_file_path = ?");
my %daughters = (
    "G4Hits" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_VERTEX" ],
    "DST_BBC_G4HIT" => [ "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_VERTEX", "DST_GLOBAL" ],
    "DST_CALO_G4HIT" => [ "DST_BBC_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_VERTEX", "DST_CALO_CLUSTER" ],
    "DST_TRKR_G4HIT" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRUTH_G4HIT", "DST_VERTEX", "DST_TRKR_HIT", "DST_TRUTH_RECO"],
    "DST_TRUTH_G4HIT" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_VERTEX", "DST_TRUTH" ],
    "DST_VERTEX" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_CALO_CLUSTER" ],
    "DST_TRKR_CLUSTER" => [ "DST_TRACKSEEDS", "DST_TRUTH_RECO"],
    "DST_TRACKSEEDS" => [ "DST_TRACKS"],
    "DST_TRKR_HIT" => [ "DST_TRUTH", "DST_TRKR_CLUSTER" ],
    "DST_TRUTH" => [ "DST_TRKR_HIT", "DST_TRUTH_JET", "DST_TRUTH_RECO" ],
#    "DST_TRKR_HIT" => [ "DST_TRUTH" ],
#    "DST_TRUTH" => [ "DST_TRKR_HIT" ],
    "DST_GLOBAL" => [ "" ],
    "DST_TRUTH_JET" => [ "" ],
    "DST_TRUTH_RECO" => [ "" ],
    "DST_TRKR_HIT_DISTORT" => [ "DST_TRUTH_DISTORT", "DST_TRACKS_DISTORT" ],
    "DST_TRUTH_DISTORT" => [ "DST_TRKR_HIT_DISTORT", "DST_TRACKS_DISTORT" ],
    "DST_TRACKS" => [ "DST_TRUTH_RECO" ],
    "DST_TRACKS_DISTORT" => [ "" ],
    "DST_CALO_CLUSTER" => [ "" ],
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
    push(@$ref,("DST_CALO_CLUSTER", "DST_GLOBAL"));
    @$ref = grep($_,@$ref); # removes empty strings from array
    $ref = $daughters{"DST_CALO_CLUSTER"};
    push(@$ref,("DST_TRKR_HIT","DST_GLOBAL","DST_TRUTH"));
    @$ref = grep($_,@$ref); # removes empty strings from array
    $ref = $daughters{"DST_GLOBAL"};
    push(@$ref,("DST_CALO_CLUSTER", "DST_TRKR_HIT","DST_TRUTH"));
    @$ref = grep($_,@$ref); # removes empty strings from array
    $ref = $daughters{"DST_TRUTH"};
    push(@$ref,("DST_CALO_CLUSTER","DST_GLOBAL"));
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
if ($system < 1 || $system > 19)
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
    exit(0);
}

my $systemstring;
my %specialsystemstring = ();
my $pileupdir;
my $condorfileadd;
my $pileupstring;
my %specialcondorfileadd = ();
my %productionsubdir = (
    "DST_BBC_G4HIT" => "pass2",
    "DST_CALO_CLUSTER" => "pass3calo",
    "DST_CALO_G4HIT"=> "pass2",
    "DST_GLOBAL"=> "pass3global",
    "DST_JETS"=> "pass5jetreco",
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
    "DST_TRUTH_RECO" => "pass5truthreco",
    "DST_TRUTH_DISTORT" => "pass3distort",
    "DST_VERTEX" => "pass2",
    "G4Hits" => "pass1"
    );
if (defined $nopileup)
{
    $productionsubdir{"DST_TRKR_HIT"} = "pass2_nopileup";
    $productionsubdir{"DST_CALO_CLUSTER"} = "pass2_nopileup";
    $productionsubdir{"DST_GLOBAL"} = "pass2_nopileup";
    $productionsubdir{"DST_TRKR_CLUSTER"} = "pass3_job0_nopileup";
    $productionsubdir{"DST_TRUTH"} = "pass2_nopileup";
    $productionsubdir{"DST_TRACKS"} = "pass3_jobC_nopileup";
    $productionsubdir{"DST_TRACKSEEDS"} = "pass3_jobA_nopileup";
    $productionsubdir{"DST_TRUTH_JET" } = "pass3jet_nopileup",
}
if (defined $embed)
{
    $productionsubdir{"DST_BBC_G4HIT"} = "pass2_embed";
    $productionsubdir{"DST_CALO_CLUSTER"} = "pass3calo_embed";
    $productionsubdir{"DST_CALO_G4HIT"} = "pass2_embed";
    $productionsubdir{"DST_TRUTH"} = "pass3trk_embed";
    $productionsubdir{"DST_TRUTH_G4HIT"} = "pass2_embed";
    $productionsubdir{"DST_TRACKS"} = "pass4_jobC_embed";
    $productionsubdir{"DST_TRACKSEEDS"} = "pass4_jobA_embed";
    $productionsubdir{"DST_TRKR_CLUSTER"} = "pass4_job0_embed";
    $productionsubdir{"DST_TRKR_HIT"} = "pass3trk_embed";
    $productionsubdir{"DST_TRKR_G4HIT"} = "pass2_embed";
    $productionsubdir{"DST_TRUTH_JET" } = "pass4jet_embed",
    $productionsubdir{"DST_VERTEX"} = "pass2_embed";
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
    $pileupstring = "_3MHz";
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
}
elsif ($system == 7)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Charm-";
    $systemstring = "pythia8_Charm-";
    $topdir = sprintf("%s/HF_pp200_signal",$topdir);
    $condorfileadd = sprintf("Charm_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Charm");
        $systemstring = "pythia8_Charm";
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
        $pileupstring = "_sHijing_0_20fm_50kHz_bkg_0_20fm";
    }
    $specialcondorfileadd{"G4Hits"} = "Jet30";
}
elsif ($system == 12)
{
    $specialsystemstring{"G4Hits"} = "pythia8_Jet10-";
    $systemstring = "pythia8_Jet10_";
    $topdir = sprintf("%s/JS_pp200_signal",$topdir);
    $condorfileadd = sprintf("Jet10_3MHz");
    if (defined $nopileup)
    {
	$condorfileadd = sprintf("Jet10");
        $systemstring = "pythia8_Jet10";
    }
    if (defined $embed)
    {
	$condorfileadd = sprintf("Jet10");
        $systemstring = "pythia8_Jet10";
        $pileupstring = "_sHijing_0_20fm_50kHz_bkg_0_20fm";
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
        $pileupstring = "_sHijing_0_20fm_50kHz_bkg_0_20fm";
    }
    $specialcondorfileadd{"G4Hits"} = "PhotonJet";
}
elsif ($system == 14)
{
    if ($#ARGV == 3)
    {
        $particle = $ARGV[1];
	$ptmin = $ARGV[2];
	$ptmax = $ARGV[3];
    }
    else
    {
	print "needs arguments segment particle ptmin ptmax\n";
        exit(1)
    }
    my $snglstring = sprintf("single_%s_%d_%dMeV",$particle,$ptmin,$ptmax);
    $specialsystemstring{"G4Hits"} = sprintf("%s-",$snglstring);
    $systemstring = sprintf("%s_",$snglstring);
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
        $pileupstring = "_sHijing_0_20fm_50kHz_bkg_0_20fm";
    }
    $specialcondorfileadd{"G4Hits"} = "Jet40";
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
if (defined $pileupdir)
{
    $productionsubdir{"DST_BBC_G4HIT"} = sprintf("%s_%s",$productionsubdir{"DST_BBC_G4HIT"},$pileupdir);
    $productionsubdir{"DST_CALO_CLUSTER"} = sprintf("%s_%s",$productionsubdir{"DST_CALO_CLUSTER"},$pileupdir);
    $productionsubdir{"DST_CALO_G4HIT"} = sprintf("%s_%s",$productionsubdir{"DST_CALO_G4HIT"},$pileupdir);
    $productionsubdir{"DST_TRACKS"} = sprintf("%s_%s",$productionsubdir{"DST_TRACKS"},$pileupdir);
    $productionsubdir{"DST_TRKR_CLUSTER"} = sprintf("%s_%s",$productionsubdir{"DST_TRKR_CLUSTER"},$pileupdir);
    $productionsubdir{"DST_TRKR_G4HIT"} = sprintf("%s_%s",$productionsubdir{"DST_TRKR_G4HIT"},$pileupdir);
    $productionsubdir{"DST_TRUTH_G4HIT"} = sprintf("%s_%s",$productionsubdir{"DST_TRUTH_G4HIT"},$pileupdir);
    $productionsubdir{"DST_VERTEX"} = sprintf("%s_%s",$productionsubdir{"DST_VERTEX"},$pileupdir);
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
	    $loopsystemstring = sprintf("%s3MHz-",$loopsystemstring);
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
	$condor_subdir = sprintf("%s/%s/condor/log",$condor_subdir,$productionsubdir{$rem});
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
	print "no entry for $rem\n";
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
