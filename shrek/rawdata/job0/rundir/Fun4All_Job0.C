#include <GlobalVariables.C>

#include <G4_Bbc.C>
#include <G4_Global.C>
#include <G4_Production.C>
#include <G4_Tracking.C>

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

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libfun4allraw.so)
R__LOAD_LIBRARY(libffarawmodules.so)

void Fun4All_Job0(
  int nEvents = 10,
  const std::string &outputFile = "DST_TRKR_CLUSTER_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000006-00000.root",
  const std::string &dstlist = "dst_trkr_hit.list",
  const std::string &outdir = ".",
  const int irun = 251,
  const int sequence = 1,
  const std::string &topdir = "/sphenix/lustre01/sphnxpro/mdc2/rawdata/pool_stripe5")
{
  gSystem->Load("libg4dst.so");
  int nfiles = 0;
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1); // produces enormous logs
  recoConsts *rc = recoConsts::instance();
  Fun4AllInputManager *indst = new Fun4AllDstInputManager("DSTin");
  indst->AddListFile(dstlist);
  se->registerInputManager(indst);
  Fun4AllInputManager *in = nullptr;
  int n = 0;
  Fun4AllSyncManager *syncprdf = new Fun4AllSyncManager("SYNCPRDF");
  syncprdf->MixRunsOk(true);
  se->registerSyncManager(syncprdf);
  EventCombiner *evtcomb = new EventCombiner();
  evtcomb->Verbosity(1);

  for (int i = 0; i < 40; i++)
  {
    char ebdcfilename[200];
    sprintf(ebdcfilename,"%s/ebdc%02d_junk-%08d-%04d.evt",topdir.c_str(),i,irun,sequence);
    string ebdc = "ebdc" + to_string(i);
    string prdfnode = "PRDF" + to_string(n);
    FILE *f = fopen(ebdcfilename, "r");
    if (!f)
    {
//        cout << "file does not exist: " << ebdcfilename << endl;
      continue;
    }
    fclose(f);
    string listfilename = ebdc + ".list";
    std::ofstream out(listfilename);
    out << ebdcfilename << endl;
    out.close();
    nfiles++;
    in = new Fun4AllPrdfInputManager(ebdc, prdfnode);
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
  //  Fun4AllEventOutputManager *out = new Fun4AllEventOutputManager("EvtOut","out-%08d-%04d.prdf",20000);
  //  out->DropPacket(21102);
  //  se->registerOutputManager(out);

  Enable::XPLOAD = true;
  // tag
  rc->set_StringFlag("XPLOAD_TAG",XPLOAD::tag);
  // database config
  rc->set_StringFlag("XPLOAD_CONFIG",XPLOAD::config);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP",XPLOAD::timestamp);

  // set up production relatedstuff
  Enable::PRODUCTION = true;
  Enable::DSTOUT = true;
  DstOut::OutputDir = outdir;
  DstOut::OutputFile = outputFile;

  // central tracking
  Enable::MVTX = true;
  Enable::INTT = true;
  Enable::TPC = true;
  Enable::MICROMEGAS = true;

  // TPC
  G4TPC::ENABLE_STATIC_DISTORTIONS = false;
  G4TPC::ENABLE_TIME_ORDERED_DISTORTIONS = false;
  G4TPC::ENABLE_CORRECTIONS = false;
  G4TPC::DO_HIT_ASSOCIATION = false;

  // tracking configuration
  G4TRACKING::use_full_truth_track_seeding = false;

  // do not initialize magnetic field in ACTS
  G4TRACKING::init_acts_magfield = false;

  FlagHandler *flg = new FlagHandler();
  se->registerSubsystem(flg);

  // needed for makeActsGeometry, used in clustering
  TrackingInit();

  // clustering
  Mvtx_Clustering();
  Intt_Clustering();
  TPC_Clustering();
  Micromegas_Clustering();

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }

    string FullOutFile = DstOut::OutputFile;
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("DSTOUT",FullOutFile);
  out->AddNode("Sync");
  out->AddNode("EventHeader");
  out->AddNode("TRKR_CLUSTER"); 
  out->AddNode("TRKR_CLUSTERHITASSOC");
  out->AddNode("TRKR_CLUSTERCROSSINGASSOC");
  se->registerOutputManager(out);

  se->run(nEvents);

  se->End();
  delete se;
  if (Enable::PRODUCTION)
  {
    Production_MoveOutput();
  }
  cout << "all done" << endl;
  gSystem->Exit(0);
}
