#ifndef MACRO_G4OUTPUTMANAGER_C
#define MACRO_G4OUTPUTMANAGER_C

#include <GlobalVariables.C>

#include <G4_Production.C>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>

#include <format>
#include <set>
#include <string>

namespace OUTPUTMANAGER
{
  std::set<std::string> outfiles;
}

void AddCommonNodes(Fun4AllOutputManager *out);

void CreateDstOutput(int runnumber, int segment, const std::string &jettrigger, const std::string &fmrange, const std::string &pileup)
{
  auto *se = Fun4AllServer::instance();
  std::string suffix = std::format("_pythia8_{}_sHijing_OO_{}_{}_bkg_0_15fm-{:010d}-{:06d}.root", jettrigger, fmrange, pileup, runnumber,segment);
  std::string FullOutFile = "DST_BBC_G4HIT" + suffix;
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("BBCOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("G4HIT_BBC");
  out->AddNode("G4HIT_EPD");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_TRKR_G4HIT" + suffix;
  out = new Fun4AllDstOutputManager("TRKROUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("G4HIT_MVTX");
  out->AddNode("G4HIT_INTT");
  out->AddNode("G4HIT_TPC");
  out->AddNode("G4HIT_MICROMEGAS");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_CALO_G4HIT" + suffix;
  out = new Fun4AllDstOutputManager("CALOOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("G4HIT_CEMC");
  out->AddNode("G4HIT_HCALIN");
  out->AddNode("G4HIT_HCALOUT");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_TRUTH_G4HIT" + suffix;
  out = new Fun4AllDstOutputManager("TRUTHOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("G4TruthInfo");
  out->AddNode("G4HIT_BH_1");
  out->AddNode("PHHepMCGenEventMap");
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
