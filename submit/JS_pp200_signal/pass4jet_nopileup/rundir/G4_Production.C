#ifndef MACRO_G4PRODUCTION_C
#define MACRO_G4PRODUCTION_C

#include <GlobalVariables.C>

// for directory check
#include <dirent.h>
#include <sys/types.h>

namespace Enable
{
  bool PRODUCTION = false;
}

namespace PRODUCTION
{
  string SaveOutputDir = "./";
}

void Production_CreateOutputDir()
{
  PRODUCTION::SaveOutputDir = DstOut::OutputDir;
  string toreplace("/sphenix/lustre01/sphnxpro");
  string mkdircmd;
  size_t strpos = DstOut::OutputDir.find(toreplace);
  if (strpos == string::npos)
  {
// check if directory already exists, mkdirs can hang up the system if we have gazillions of them
    DIR *dr;
    struct dirent *en;
    dr = opendir(DstOut::OutputDir.c_str());
    if (dr)
    {
      closedir(dr);  // output directory exists - close it and do nothing
      return;
    }
    mkdircmd = "mkdir -p " + DstOut::OutputDir;
  }
  else
  {
    DstOut::OutputDir.replace(DstOut::OutputDir.begin(),
                              DstOut::OutputDir.begin() + toreplace.size(),
                              "sphenixS3");
// for mcs3 we add the check in an if statement.
// TSystem->Exec() returns always -1 when this macro is called from a macro, see
// https://root.cern/root/html530/src/TSystem.cxx.html#xRCiVD
    mkdircmd = "if [[ ! `mcs3 stat " + DstOut::OutputDir + "` ]]; then mcs3 mb " + DstOut::OutputDir + "; fi";
  }
  gSystem->Exec(mkdircmd.c_str());
}

void Production_MoveOutput()
{
  if (Enable::DSTOUT)
  {
    // if run locally it will try to copy output file to itself wiping it out
    if (PRODUCTION::SaveOutputDir == ".")
    {
      return;
    }
    string copyscript = "copyscript.pl";
    ifstream f(copyscript);
    bool scriptexists = f.good();
    f.close();
    string fulloutfile = DstOut::OutputFile;
    string mvcmd;
    if (scriptexists)
    {
      mvcmd = copyscript + " -outdir " + PRODUCTION::SaveOutputDir + " " + fulloutfile;
    }
    else
    {
      mvcmd = "mv " + fulloutfile + " " + PRODUCTION::SaveOutputDir;
    }
    cout << "mvcmd: " << mvcmd << endl;
    gSystem->Exec(mvcmd.c_str());
  }
}
#endif
