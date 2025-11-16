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

#my $cmd = sprintf("cat %s/*.log | grep 'Memory (MB)          :' | awk '{print \$4}' | sort -n > memory",$logdir);


if (! defined $runremlist)
{
    $runremlist = "memory.list";
    my $cmd;
    if (defined $filetype)
    {
	$cmd = sprintf("find %s/ -name '*%s*.log' |",$logdir,$filetype);
    }
    else
    {
	$cmd = sprintf("find %s/ -name '*.condor' |",$logdir);
    }

    if (-f $runremlist)
    {
	unlink $runremlist;
    }
    print "command: $cmd\n";
    my $cnt = 0;
    open(F2,">$runremlist");
    open(F,"$cmd");
    while (my $file = <F>)
    {
	print "file: $file";
	chomp $file;
	my $fcmd = sprintf("cat %s | grep 'Memory (MB)' | awk '{print \$4}' | ",$file);
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


my $cmd = sprintf("root.exe plotmem.C\\(\\\"%s\\\"\\)",$runremlist);

print "$cmd\n";

system($cmd);
