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

void CreateDstOutput(int runnumber, int segment, const string &quarkfilter)
{
  auto se = Fun4AllServer::instance();

  char segrun[100];
  snprintf(segrun,100,"%s-%010d-%05d",quarkfilter.c_str(),runnumber,segment);
  string FullOutFile = "DST_TRUTH_cosmic_" + string(segrun) + ".root";;
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("TRUTHOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("PHHepMCGenEventMap");
  out->AddNode("G4HIT_BH_1");
  out->AddNode("G4TruthInfo");
  out->AddNode("TRKR_HITTRUTHASSOC");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_TRKR_HIT_cosmic_" + string(segrun) + ".root";;
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
  string copyscript = "copyscript.pl";
  ifstream f(copyscript);
  bool scriptexists = f.good();
  f.close();
  if (Enable::DSTOUT)
  {
    // if run locally it will try to copy output file to itself wiping it out
    if (PRODUCTION::SaveOutputDir == ".")
    {
      return;
    }
    for (auto iter = OUTPUTMANAGER::outfiles.begin(); iter != OUTPUTMANAGER::outfiles.end(); ++iter)
    {
//   string mvcmd = "mv " + *iter + " " + PRODUCTION::SaveOutputDir;
      string mvcmd;
      if (scriptexists)
      {
//        mvcmd = copyscript + " -outdir " + PRODUCTION::SaveOutputDir + " " + *iter + " --test";
        mvcmd = copyscript + " -outdir " + PRODUCTION::SaveOutputDir + " " + *iter;
      }
      else
      {
	mvcmd = "cp " + *iter + " " + PRODUCTION::SaveOutputDir;
      }
      gSystem->Exec(mvcmd.c_str());
    }
  }
}

#endif
