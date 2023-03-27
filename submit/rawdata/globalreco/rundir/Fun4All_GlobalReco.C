#ifndef MACRO_FUN4ALLGLOBALRECO_C
#define MACRO_FUN4ALLGLOBALRECO_C

#include <GlobalVariables.C>

#include <G4_EPD.C>
#include <G4_Production.C>

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

int Fun4All_GlobalReco(
  const int nEvents = 1,
  const string &outputFile = "DST_MDC2_GLOBAL_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000006-00000.root",
  const string &outdir = ".",
  const string &globallist = "globallist.list",
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
  Fun4AllInputManager *indst = new Fun4AllDstInputManager("DSTinGlobal");
  indst->AddListFile(globallist,1);
  se->registerInputManager(indst);
  indst = new Fun4AllDstInputManager("DSTinVtx");
  indst->AddListFile(vtxlist,1);
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
    in->Repeat();
    // in->Verbosity(4);
    evtcomb->AddPrdfInputNodeFromManager(in);
    syncprdf->registerInputManager(in);
    n++;
    if (nfiles > 1)
    {
      break;
    }
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

  EPD_Tiles();

  if (Enable::DSTOUT)
  {
    string FullOutFile = DstOut::OutputFile;
    Fun4AllDstOutputManager *out = new Fun4AllDstOutputManager("DSTOUT", FullOutFile);
    out->AddNode("Sync");
    out->AddNode("EventHeader");
    out->AddNode("TOWERINFO_CALIB_EPD");
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
