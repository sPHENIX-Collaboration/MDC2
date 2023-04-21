#!usr/bin/perl

use strict;
use File::Path;
use Getopt::Long;

my $submit;
GetOptions("submit"=>\$submit);
if ($#ARGV < 1)
{
    print "usage: run_hijing.pl <number of new files> <fm range>\n";
    print "parameters:\n";
    print "-submit : submit condor jobs\n";
    exit(1);
}
my $add_files = $ARGV[0];
my $fm_range = $ARGV[1];
my $runnumber = 6;
my $evt_per_file = 100000;
my $condorlogdir = "/tmp/mdc2/generators";
my $condoroutdir = sprintf("/sphenix/sim/sim01/sphnxpro/mdc2/sHijing_HepMC/log/pAu_%s",$fm_range);
my $outputdir = sprintf("/sphenix/sim/sim01/sphnxpro/mdc2/sHijing_HepMC/pAu_%s",$fm_range);
mkpath($condorlogdir);
mkpath($condoroutdir);
mkpath($outputdir);
my $maxnum=hex('0xFFFFFFFF');
my %used_seeds = ();

#open old logs and extract and store the seeds so we do not reuse them
open(F,"find /sphenix/sim/sim01/sphnxpro/mdc2/logs/sHijing_HepMC/log/pAu_$fm_range -name 'pAu_$fm_range-*.out' |");
while (my $outfile = <F>)
{
    chomp $outfile;
    my $seed = `cat $outfile | grep seed | grep arg`;
    chomp $seed;
    my @sp1 = split(/ /,$seed);
    $used_seeds{$#sp1} = $outfile;
}
my $segment = 0;
for (my $i = 0; $i < $add_files; $i++)
{
    my $datfile;
    my $fulldatfile;
    my $condorlog;
    my $condorout;
    my $condorerr;
    do
    {
	$datfile = sprintf("pAu_%s-%010d-%05d.dat",$fm_range,$runnumber, $segment);
	$condorlog = sprintf("%s/pAu_%s-%010d-%05d.log", $condorlogdir,$fm_range,$runnumber,$segment);
	$condorout = sprintf("%s/pAu_%s-%010d-%05d.out",$condoroutdir,$fm_range,$runnumber,$segment);
	$condorerr = sprintf("%s/pAu_%s-%010d-%05d.err",$condoroutdir,$fm_range,$runnumber,$segment);
	$fulldatfile = sprintf("%s/%s",$outputdir,$datfile);
	$segment++;
    }
    while (-f $fulldatfile);
    my $seed;
    do
    {
	$seed = int(rand($maxnum));
    }
    while (exists $used_seeds{$seed});
    $used_seeds{$seed} = $condorout;
    my $condorcmd = sprintf("condor_submit condor.job -a \"output = %s\" -a \"error = %s\"  -a \"Log = %s\" -a \"Arguments = %d %d %s %s\"",$condorout, $condorerr, $condorlog,$evt_per_file, $seed, $datfile, $outputdir);
    if (! defined $submit)
    {
	print "would issue $condorcmd\n";
    }
    else
    {
	print "$condorcmd\n";
	system($condorcmd);
    }
}
