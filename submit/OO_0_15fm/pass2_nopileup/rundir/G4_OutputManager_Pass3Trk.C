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

void CreateDstOutput(int runnumber, int segment)
{
  auto *se = Fun4AllServer::instance();

  std::string segrun = std::format("-{:010}-{:06}",runnumber, segment);
  std::string FullOutFile = "DST_TRUTH_sHijing_OO_0_15fm" + segrun + ".root";
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("TRUTHOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("PHHepMCGenEventMap");
  out->AddNode("G4HIT_BH_1");
  out->AddNode("G4TruthInfo");
  out->AddNode("TRKR_HITTRUTHASSOC");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_TRKR_HIT_sHijing_OO_0_15fm" + std::string(segrun) + ".root";
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
    // if run locally it will try to copy output file to itself wiping it out
    if (PRODUCTION::SaveOutputDir == ".")
    {
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
      //   string mvcmd = "mv " + *iter + " " + PRODUCTION::SaveOutputDir;
      if (scriptexists)
      {
        //        mvcmd = copyscript + " -outdir " + PRODUCTION::SaveOutputDir + " " + *iter + " --test";
        mvcmd = std::format("perl {} -dd -outdir {} {}",copyscript, PRODUCTION::SaveOutputDir, outfile);
      }
      else
      {
	mvcmd = std::format("mv {} {}", outfile, PRODUCTION::SaveOutputDir);
      }
      std::cout << "mvcmd: " << mvcmd << std::endl;
      if (copyscriptexists)
      {
	flist << mvcmd << std::endl;
      }
      else
      {
	gSystem->Exec(mvcmd.c_str());
      }
      flist.close();
    }
  }
}

#endif
