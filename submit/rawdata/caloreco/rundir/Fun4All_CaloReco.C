#ifndef MACRO_FUN4ALLCALORECO_C
#define MACRO_FUN4ALLCALORECO_C

#include <GlobalVariables.C>

#include <G4_CEmc_Spacal.C>
#include <G4_HcalIn_ref.C>
#include <G4_HcalOut_ref.C>
#include <G4_Production.C>
#include <G4_TopoClusterReco.C>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/XploadInterface.h>

#include <ffarawmodules/EventCombiner.h>

#include <fun4all/Fun4AllInputManager.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllSyncManager.h>
#include <fun4all/Fun4AllServer.h>

#include <fun4allraw/Fun4AllEventOutputManager.h>
#include <fun4allraw/Fun4AllPrdfInputManager.h>

#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libfun4allraw.so)
R__LOAD_LIBRARY(libffarawmodules.so)

int Fun4All_CaloReco(
  const int nEvents = 1,
  const string &outputFile = "DST_CALO_CLUSTER_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000062-00000.root",
  const string &outdir = ".",
  const string &calolist = "calolist.list",
  const string &vtxlist = "vtxlist.list",
  const int irun = 251,
  const int sequence = 1,
  const std::string &topdir = "/sphenix/lustre01/sphnxpro/mdc2/rawdata/pool_stripe5")
{
  gSystem->Load("libg4dst.so");
  int nfiles = 0;
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);
  recoConsts *rc = recoConsts::instance();
  Fun4AllInputManager *indst = new Fun4AllDstInputManager("DSTinCalo");
  indst->AddListFile(calolist);
  se->registerInputManager(indst);
  indst = new Fun4AllDstInputManager("DSTinVtx");
  indst->AddListFile(vtxlist);
  se->registerInputManager(indst);
  Fun4AllInputManager *in = nullptr;
  int n = 0;
  Fun4AllSyncManager *syncprdf = new Fun4AllSyncManager("SYNCPRDF");
  syncprdf->MixRunsOk(true);
  se->registerSyncManager(syncprdf);
  EventCombiner *evtcomb = new EventCombiner();
  evtcomb->Verbosity(1);

  for (int i = 0; i < 10; i++)
  {
    char sebfilename[200];
    sprintf(sebfilename,"%s/seb%02d_junk-%08d-%04d.evt",topdir.c_str(),i,irun,sequence);
    string seb = "seb" + to_string(i);
    string prdfnode = "PRDF" + to_string(n);
    FILE *f = fopen(sebfilename, "r");
    if (!f)
    {
//        cout << "file does not exist: " << sebfilename << endl;
      continue;
    }
    fclose(f);
    string listfilename = seb + ".list";
    std::ofstream out(listfilename);
    out << sebfilename << endl;
    out.close();
    nfiles++;
    in = new Fun4AllPrdfInputManager(seb, prdfnode);
    in->AddListFile(listfilename);
    // in->Verbosity(4);
    evtcomb->AddPrdfInputNodeFromManager(in);
    syncprdf->registerInputManager(in);
    n++;
  }
  if (nfiles == 0)
  {
    cout << "no files for run " << irun << ", segment " << sequence << endl;
    gSystem->Exit(0);
  }
  se->registerSubsystem(evtcomb);

  Enable::XPLOAD = true;
  rc->set_StringFlag("XPLOAD_TAG",XPLOAD::tag);
  rc->set_StringFlag("XPLOAD_CONFIG",XPLOAD::config);
  rc->set_uint64Flag("TIMESTAMP",XPLOAD::timestamp);

  // set up production relatedstuff
  Enable::PRODUCTION = true;
  Enable::DSTOUT = true;
  DstOut::OutputDir = outdir;
  DstOut::OutputFile = outputFile;

// register the flag handling
  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }
// cell reconstruction (G4Hit --> Cells)
  CEMC_Cells();
  HCALInner_Cells();
  HCALOuter_Cells();

// tower reco
  CEMC_Towers();
  HCALInner_Towers();
  HCALOuter_Towers();

// clustering
  CEMC_Clusters();
  HCALInner_Clusters();
  HCALOuter_Clusters();

// not working yet TopoClusterReco();

  if (Enable::DSTOUT)
  {
    string FullOutFile = DstOut::OutputFile;
    Fun4AllDstOutputManager *out = new Fun4AllDstOutputManager("DSTOUT", FullOutFile);
    out->AddNode("Sync");
    out->AddNode("EventHeader");
// Inner Hcal
    out->AddNode("TOWERINFO_RAW_HCALIN");
    out->AddNode("TOWERINFO_CALIB_HCALIN");
    out->AddNode("CLUSTER_HCALIN");

// Outer Hcal
    out->AddNode("TOWERINFO_RAW_HCALOUT");
    out->AddNode("TOWERINFO_CALIB_HCALOUT");
    out->AddNode("CLUSTER_HCALOUT");

// CEmc
    out->AddNode("TOWERINFO_RAW_CEMC");
    out->AddNode("TOWERINFO_CALIB_CEMC");
    out->AddNode("CLUSTER_CEMC");
    out->AddNode("CLUSTER_POS_COR_CEMC");

// leave the topo cluster here in case we run this during pass3
    out->AddNode("TOPOCLUSTER_ALLCALO");
    out->AddNode("TOPOCLUSTER_EMCAL");
    out->AddNode("TOPOCLUSTER_HCAL");
    out->AddNode("GlobalVertexMap");
    se->registerOutputManager(out);
  }
  // if we use a negative number of events we go back to the command line here
  if (nEvents < 0)
  {
    return 0;
  }
  se->run(nEvents);

  //-----
  // Exit
  //-----

  XploadInterface::instance()->Print(); // print used DB files
  se->End();
  se->PrintTimer();
  delete se;
  if (Enable::PRODUCTION)
  {
    Production_MoveOutput();
  }

  std::cout << "All done" << std::endl;
  gSystem->Exit(0);
  return 0;
}
#endif
