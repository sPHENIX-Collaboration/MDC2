#include <GlobalVariables.C>

#include <G4Setup_sPHENIX.C>
#include <G4_Bbc.C>
#include <G4_Global.C>
#include <G4_Production.C>
#include <G4_Tracking.C>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/XploadInterface.h>

#include <fun4all/SubsysReco.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>


R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4all.so)

//________________________________________________________________________________________________
int Fun4All_G4_sPHENIX_job0(
  const int nEvents = 0,
  const int nSkipEvents = 0,
  const std::string &inputFile = "DST_TRKR_HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000062-00000.root",
  const std::string &outputFile = "DST_TRKR_CLUSTER_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000062-00000.root",
    const string &outdir = ".")
{

  // print inputs
  std::cout << "Fun4All_G4_sPHENIX_job0 - nEvents: " << nEvents << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_job0 - nSkipEvents: " << nSkipEvents << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_job0 - inputFile: " << inputFile << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_job0 - outputFile: " << outputFile << std::endl;
  
  recoConsts *rc = recoConsts::instance();

  //===============
  // conditions DB flags
  //===============
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
  
  // server
  auto se = Fun4AllServer::instance();
  se->Verbosity(1);

  // make sure to printout random seeds for reproducibility
  PHRandomSeed::Verbosity(1);

  FlagHandler *flg = new FlagHandler();
  se->registerSubsystem(flg);

  // needed for makeActsGeometry, used in clustering
  TrackingInit();

  // clustering
  Mvtx_Clustering();
  Intt_Clustering();
  TPC_Clustering();
  Micromegas_Clustering();


  
  // input manager
  auto in = new Fun4AllDstInputManager("DSTin");
  in->fileopen(inputFile);
  se->registerInputManager(in);

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }

  // output manager
  /* all the nodes from DST and RUN are saved to the output */
    string FullOutFile = DstOut::OutputFile;
  auto out = new Fun4AllDstOutputManager("DSTOUT", FullOutFile);
  out->AddNode("Sync");
  out->AddNode("EventHeader");
  out->AddNode("TRKR_CLUSTER"); 
  out->AddNode("TRKR_CLUSTERHITASSOC");
  out->AddNode("TRKR_CLUSTERCROSSINGASSOC");
  se->registerOutputManager(out);

  // skip events if any specified
  if( nSkipEvents > 0 )
  { se->skip( nSkipEvents ); }

  // process events
  se->run(nEvents);

  // terminate
  XploadInterface::instance()->Print(); // print used DB files
  se->End();
  se->PrintTimer();
  std::cout << "All done" << std::endl;
  delete se;
  if (Enable::PRODUCTION)
  {
    Production_MoveOutput();
  }
  gSystem->Exit(0);
  return 0;
}
