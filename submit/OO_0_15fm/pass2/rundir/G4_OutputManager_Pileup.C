#ifndef MACRO_G4OUTPUTMANAGER_C
#define MACRO_G4OUTPUTMANAGER_C

#include <GlobalVariables.C>

#include <G4_Production.C>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>

#include <format>
#include <fstream>

namespace OUTPUTMANAGER
{
  std::set<std::string> outfiles;
}

void AddCommonNodes(Fun4AllOutputManager *out);

void CreateDstOutput(int runnumber, int segment, const std::string &pileupstring)
{
  auto *se = Fun4AllServer::instance();

  std::string segrun = std::format("{}-{:010}-{:06}",pileupstring,runnumber,segment);
  std::string FullOutFile = "DST_BBC_G4HIT_sHijing_OO_0_15fm_" + segrun + ".root";
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("BBCOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("G4HIT_BBC");
  out->AddNode("G4HIT_EPD");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_TRKR_G4HIT_sHijing_OO_0_15fm_" + segrun + ".root";
  out = new Fun4AllDstOutputManager("TRKROUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("G4HIT_MVTX");
  out->AddNode("G4HIT_INTT");
  out->AddNode("G4HIT_TPC");
  out->AddNode("G4HIT_MICROMEGAS");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_CALO_G4HIT_sHijing_OO_0_15fm_" + segrun + ".root";
  out = new Fun4AllDstOutputManager("CALOOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("G4HIT_CEMC");
  out->AddNode("G4HIT_HCALIN");
  out->AddNode("G4HIT_HCALOUT");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_TRUTH_G4HIT_sHijing_OO_0_15fm_" + segrun + ".root";
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
  out->StripCompositeNode("RECO_TRACKING_GEOMETRY");
  out->AddNode("Sync");
  out->AddNode("EventHeader");
  return;
}

void DstOutput_move()
{
  std::string copyscript = "copyscript.pl";
  std::ifstream f(copyscript);
  bool scriptexists = f.good();
  f.close();
  if (Enable::DSTOUT)
  {
    // if run locally it will try to copy output file to itself wiping it out
    if (PRODUCTION::SaveOutputDir == ".")
    {
      return;
    }
    for (const auto &outfile : OUTPUTMANAGER::outfiles)
    {
//   std::string mvcmd = "mv " + *iter + " " + PRODUCTION::SaveOutputDir;
      std::string mvcmd;
      if (scriptexists)
      {
//        mvcmd = copyscript + " -outdir " + PRODUCTION::SaveOutputDir + " " + *iter + " --test";
        mvcmd = std::format("perl {} -dd -outdir {} {}",copyscript, PRODUCTION::SaveOutputDir, outfile);
      }
      else
      {
	mvcmd = std::format("cp {} {}", outfile, PRODUCTION::SaveOutputDir);
      }
      std::cout << "move command: " << mvcmd << std::endl;
      gSystem->Exec(mvcmd.c_str());
    }
  }
}

#endif
