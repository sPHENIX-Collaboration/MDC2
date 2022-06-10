#ifndef MACRO_G4PRODUCTION_C
#define MACRO_G4PRODUCTION_C

#include <GlobalVariables.C>

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
    mkdircmd = "mkdir -p " + DstOut::OutputDir;
  }
  else
  {
    DstOut::OutputDir.replace(DstOut::OutputDir.begin(),DstOut::OutputDir.begin()+toreplace.size(),"sphenixS3");
    mkdircmd = "mcs3 mb " + DstOut::OutputDir;
  }
  gSystem->Exec(mkdircmd.c_str());
}

void Production_MoveOutput()
{
  if (Enable::DSTOUT)
  {
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
