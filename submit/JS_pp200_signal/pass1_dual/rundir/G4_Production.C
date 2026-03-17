#ifndef MACRO_G4PRODUCTION_C
#define MACRO_G4PRODUCTION_C

#include <GlobalVariables.C>

#include <TSystem.h>

// for directory check
#include <dirent.h>
#include <fstream>
#include <iostream>
#include <sys/types.h>

namespace Enable
{
  bool PRODUCTION = false;
}

namespace PRODUCTION
{
  std::string SaveOutputDir = "./";
}

void Production_CreateOutputDir()
{
  PRODUCTION::SaveOutputDir = DstOut::OutputDir;
// check if directory already exists, mkdirs can hang up the system if we have gazillions of them
  DIR *dr;
  dr = opendir(DstOut::OutputDir.c_str());
  if (dr)
  {
    closedir(dr);  // output directory exists - close it and do nothing
    return;
  }
  std::string mkdircmd = "mkdir -p " + DstOut::OutputDir;
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
    std::string copyscript = "copyscript.pl";
    std::ifstream f(copyscript);
    bool scriptexists = f.good();
    f.close();
    std::string fulloutfile = DstOut::OutputFile;
    std::string mvcmd;
    if (scriptexists)
    {
      mvcmd = "perl " + copyscript + " -outdir " + PRODUCTION::SaveOutputDir + " " + fulloutfile;
    }
    else
    {
      mvcmd = "mv " + fulloutfile + " " + PRODUCTION::SaveOutputDir;
    }
    std::cout << "mvcmd: " << mvcmd << std::endl;
    gSystem->Exec(mvcmd.c_str());
  }
}
#endif
