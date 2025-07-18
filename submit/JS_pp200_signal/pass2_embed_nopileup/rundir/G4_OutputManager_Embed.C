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

void CreateDstOutput(int runnumber, int segment, const string &jettrigger, const string &fmrange)
{
  auto se = Fun4AllServer::instance();
  string embedinto = "_sHijing_" + fmrange;
  char segrun[100];
  snprintf(segrun,100,"%s-%010d-%06d",embedinto.c_str(),runnumber,segment);
  string FullOutFile = "DST_BBC_G4HIT_pythia8_" + jettrigger + string(segrun) + ".root";;
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("BBCOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("G4HIT_BBC");
  out->AddNode("G4HIT_EPD");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_TRKR_G4HIT_pythia8_" + jettrigger + string(segrun) + ".root";;
  out = new Fun4AllDstOutputManager("TRKROUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("G4HIT_MVTX");
  out->AddNode("G4HIT_INTT");
  out->AddNode("G4HIT_TPC");
  out->AddNode("G4HIT_MICROMEGAS");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_CALO_G4HIT_pythia8_" + jettrigger + string(segrun) + ".root";;
  out = new Fun4AllDstOutputManager("CALOOUT", FullOutFile);
  AddCommonNodes(out);
  out->AddNode("G4HIT_CEMC");
  out->AddNode("G4HIT_HCALIN");
  out->AddNode("G4HIT_HCALOUT");
  se->registerOutputManager(out);
  OUTPUTMANAGER::outfiles.insert(FullOutFile);

  FullOutFile = "DST_TRUTH_G4HIT_pythia8_" + jettrigger + string(segrun) + ".root";;
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
  if (PRODUCTION::SaveOutputDir == ".")
  {
    cout << "not copying files to themselves" << endl;
    return;
  }
  string copyscript = "copyscript.pl";
  ifstream f(copyscript);
  bool scriptexists = f.good();
  f.close();
  if (Enable::DSTOUT)
  {
    for (auto iter = OUTPUTMANAGER::outfiles.begin(); iter != OUTPUTMANAGER::outfiles.end(); ++iter)
    {
      string mvcmd;
      if (scriptexists)
      {
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
