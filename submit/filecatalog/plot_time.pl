#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $count;
my $runremlist;
my $filetype;
GetOptions("cnt:i"=>\$count,"f:s"=>\$runremlist, "type:s"=>\$filetype);

if ($#ARGV < 0 && !defined $runremlist)
{
    print "usage: plot_memory.pl <condor logdir>\n";
    print "-cnt : max number of condor logs to analyze\n";
    print "-f : analyze previous listfile\n";
    print "-type: part of filename to grep for (default all logs in condor dir\n";
    exit(1);
}

my $logdir = $ARGV[0]; 

if (defined $logdir && ! -d $logdir)
{
    print "$logdir does not exist\n";
    exit(2);
}

#my $cmd = sprintf("cat %s/condor-0000000001-19*.log | grep 'Run Remote Usage' | awk '{print \$3}' | awk -F, '{print \$1}' > time",$logdir);
#my $cmd = sprintf("find %s/ -name '*.log' |",$logdir);

if (! defined $runremlist)
{
    $runremlist = "time.list";

    my $cmd;
    if (defined $filetype)
    {
	$cmd = sprintf("find %s/ -name '*%s*.log' |",$logdir,$filetype);
    }
    else
    {
	$cmd = sprintf("find %s/ -name '*.log' |",$logdir);
    }

    if (-f $runremlist)
    {
	unlink $runremlist;
    }

    my $cnt = 0;
    open(F,"$cmd");
    open(F2,">$runremlist");
    while (my $file = <F>)
    {
	print "file: $file";
	chomp $file;
	my $fcmd = sprintf("cat %s | grep 'Run Remote Usage' | ",$file);
	open(F1,$fcmd);
	while (my $remline = <F1>)
	{
	    $cnt++;
	    print F2 "$remline";
	}
	close(F1);
	if (defined $count &&  $cnt >= $count)
	{
	    last;
	}
    }
    close(F);
    close(F2);
}

open(F,"$runremlist");
open(F1,">seconds.list");
while (my $line = <F>)
{
    chomp $line;
    $line =~ s/,//g;
    $line =~ s/\s+/ /g;
    $line =~ s/^\s+//;
    my @sp = split(/ /,$line);
    my $day = $sp[1]*24*3600;
    my @sp1 = split(/:/,$sp[2]);
    my $hour = $sp1[0]*3600;
    my $min = $sp1[1]*60;
    my $sec = $sp1[2];
    my $total = $day+$hour+$min+$sec;
#    print "$line is day: $sp[1], hours: $sp1[0], min: $sp1[1], sec: $sp1[2]\n"; 
    print F1 "$total\n";
}
close(F);
close(F1);

my $cmd = sprintf("root.exe plottime.C\\(\\\"seconds.list\\\"\\)");

print "$cmd\n";

system($cmd);


