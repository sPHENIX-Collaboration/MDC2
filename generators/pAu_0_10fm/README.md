# Hijing
Area for the sHijing pAu 0-10fm production
  * condor.job : jobfile
  * run_hijing.pl : perl script to submit hijing production. 100k events per file, modify for adjustments
  * to generate perl run_hijing.pl <number new files> 0_10fm
  * run_hijing.sh : shell script to run the sHijing binary with parameters
The script checks the old logs and makes sure it does not reuse any seed
