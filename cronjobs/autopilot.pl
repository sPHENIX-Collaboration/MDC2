#!/usr/bin/perl

use strict;
use warnings;
use Cwd;

my $submittopdir = "/sphenix/u/sphnxpro/MDC2/submit";
my @submitdir = ("HF_pp200_signal/pass2/condor",
"HF_pp200_signal/pass3trk/condor",
"HF_pp200_signal/pass3calo/condor",
"HF_pp200_signal/pass4trk/condor"
);

my @quarkfilters = ("Charm");

foreach my $subdir (@submitdir)
{
    my $newdir = sprintf("%s/%s",$submittopdir,$subdir);
    if (! -d $newdir)
    {
	print "dir $newdir does not exist\n";
	next;
    }
    chdir $newdir;
    if (! -f "run_all.pl")
    {
	print "run_all.pl does not exist in $newdir\n";
	next;
    }
    if ($newdir =~ /HF_pp200_signal/)
    {
	foreach my $qf (@quarkfilters)
	{
	    my $submitcmd = sprintf("perl run_all.pl 2000 %s -inc",$qf);
	    print "executing $submitcmd in $newdir\n";
	    system($submitcmd);
	}
    }
    else
    {
	my $submitcmd = sprintf("perl run_all.pl 2000 -inc");
	print "executing $submitcmd in $newdir\n";
	system($submitcmd);
    }
}
