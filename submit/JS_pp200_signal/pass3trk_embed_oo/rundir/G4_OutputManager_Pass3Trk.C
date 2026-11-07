#ifndef MACRO_G4OUTPUTMANAGER_C
#define MACRO_G4OUTPUTMANAGER_C

#include <GlobalVariables.C>

#include <G4_Production.C>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>

#include <string>
#include <format>

namespace OUTPUTMANAGER
{
  set<string> outfiles;
}

void AddCommonNodes(Fun4AllOutputManager *out);

void CreateDstOutput(int runnumber, int segment, const string &jettrigger,
                     const string &fmrange, const string &pileup)
{
  auto se = Fun4AllServer::instance();

  // string embedinto = "_sHijing_" + fmrange + "_50kHz_bkg_0_20fm";
  // char segrun[100];
  // snprintf(segrun, 100, "%s-%010d-%06d", embedinto.c_str(), runnumber, segment);
  std::string suffix = std::format("_pythia8_{}_sHijing_OO_{}_{}_bkg_0_15fm-{:010d}-{:06d}.root",
				   jettrigger,fmrange,pileup,runnumber, segment);
  string FullOutFile = "DST_TRUTH" + suffix;
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("TRUTHOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("PHHepMCGenEventMap");
  out->AddNode("G4HIT_BH_1");
  out->AddNode("G4TruthInfo");
  out->AddNode("TRKR_HITTRUTHASSOC");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_TRKR_HIT" + suffix;
  out = new Fun4AllDstOutputManager("TRKROUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("TRKR_HITSET");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);
}

void AddCommonNodes(Fun4AllOutputManager *out)
{
  out->AddNode("Sync");
  out->AddNode("EventHeader");
  return;
}

void DstOutput_move()
{
  if (Enable::DSTOUT)
  {
    if (PRODUCTION::SaveOutputDir == ".")
    {
      std::cout << "not copying files to themselves" << std::endl;
      return;
    }
    std::string copyscript = "copyscript.pl";
    std::ifstream f(copyscript);
    bool scriptexists = f.good();
    f.close();
    std::ofstream flist("copyscript.sh");
    bool copyscriptexists = flist.good();
    for (const auto &outfile : OUTPUTMANAGER::outfiles)
    {
      std::string mvcmd;
      if (scriptexists)
      {
        mvcmd = std::format("perl {}  -outdir {} {}", copyscript, PRODUCTION::SaveOutputDir, outfile);
      }
      else
      {
	mvcmd = std::format("cp {} {}", outfile, PRODUCTION::SaveOutputDir);
      }
      if (copyscriptexists)
      {
	flist << mvcmd << std::endl;
      }
      else
      {
        gSystem->Exec(mvcmd.c_str());
      }
    }
    flist.close();
  }
}

#endif
