#ifndef MACRO_G4OUTPUTMANAGER_C
#define MACRO_G4OUTPUTMANAGER_C

#include <GlobalVariables.C>

#include <G4_Production.C>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>

namespace OUTPUTMANAGER
{
  set<string> outfiles;
}

void AddCommonNodes(Fun4AllOutputManager *out);

void CreateDstOutput(int runnumber, int segment)
{
  auto se = Fun4AllServer::instance();

  char segrun[100];
  snprintf(segrun, 100, "-%010d-%06d", runnumber, segment);
  string FullOutFile = "DST_TRUTH_sHijing_OO_0_15fm" + string(segrun) + ".root";
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("TRUTHOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("PHHepMCGenEventMap");
  out->AddNode("G4HIT_BH_1");
  out->AddNode("G4TruthInfo");
  out->AddNode("TRKR_HITTRUTHASSOC");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_TRKR_HIT_sHijing_OO_0_15fm" + string(segrun) + ".root";
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
    string copyscript = "copyscript.pl";
    ifstream f(copyscript);
    bool scriptexists = f.good();
    f.close();
    std::ofstream flist("copyscript.sh");
    bool copyscriptexists = flist.good();
    std::string fulloutfile = DstOut::OutputFile;
    std::string mvcmd;
    for (auto iter = OUTPUTMANAGER::outfiles.begin(); iter != OUTPUTMANAGER::outfiles.end(); ++iter)
    {
      //   string mvcmd = "mv " + *iter + " " + PRODUCTION::SaveOutputDir;
      string mvcmd;
      if (scriptexists)
      {
        //        mvcmd = copyscript + " -outdir " + PRODUCTION::SaveOutputDir + " " + *iter + " --test";
        mvcmd = "perl " + copyscript + " -outdir " + PRODUCTION::SaveOutputDir + " " + *iter;
      }
      else
      {
        mvcmd = "mv " + *iter + " " + PRODUCTION::SaveOutputDir;
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
