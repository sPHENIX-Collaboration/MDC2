#include <GlobalVariables.C>

#include <G4_Magnet.C>
#include <G4_Micromegas.C>
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
int Fun4All_G4_sPHENIX_jobA(
  const int nEvents = 0,
  const int nSkipEvents = 0,
  const string &inputFile = "DST_TRKR_CLUSTER_pythia8_Jet30_3MHz-0000000040-00000.root",
  const string &outputFile = "DST_TRACKSEEDS_pythia8_Jet30_3MHz-0000000040-00000.root",
  const string &outdir = "."
  )
{

  // print inputs
  std::cout << "Fun4All_G4_sPHENIX_jobA - nEvents: " << nEvents << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_jobA - nSkipEvents: " << nSkipEvents << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_jobA - inputFile: " << inputFile << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_jobA - outputFile: " << outputFile << std::endl;

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
  Enable::TPC_ABSORBER = true;
  Enable::MICROMEGAS = true;
 
  // TPC configuration
  /* distortions - irrelevant, only matter when running from G4Hits */
  G4TPC::ENABLE_STATIC_DISTORTIONS = false;
  G4TPC::ENABLE_TIME_ORDERED_DISTORTIONS = false;

  /* distortion corrections */
  G4TPC::ENABLE_CORRECTIONS = false;
  G4TPC::correction_filename = string(getenv("CALIBRATIONROOT")) + "/distortion_maps/distortion_corrections_empty.root";
  
  // tracking
  /* turn on special fit with silicium and TPOT alone */
  G4TRACKING::SC_CALIBMODE = true;
  
  // server
  auto se = Fun4AllServer::instance();
  se->Verbosity(1);

  // make sure to printout random seeds for reproducibility
  PHRandomSeed::Verbosity(1);

  //------------------
  // New Flag Handling
  //------------------
  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  MagnetFieldInit();
  TrackingInit();
  
  // tracking
  Tracking_Reco_TrackSeed();

  // input manager
  auto in = new Fun4AllDstInputManager("DSTin");
  in->fileopen(inputFile);
  se->registerInputManager(in);

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }

  // output manager
  /* only save clusters, tracks and vertices */
  auto out = new Fun4AllDstOutputManager("DSTOUT", outputFile);

  /* 
   * in principle one would not need to store the clusters and cluster crossing node, as they are already in the output from Job0
   * for JobC it should be enough to read the cluster file in sync with the track file 
   */
  out->AddNode("Sync");
  out->AddNode("EventHeader");
  out->AddNode("TRKR_CLUSTER");
  out->AddNode("TRKR_CLUSTERCROSSINGASSOC");
  out->AddNode("SiliconTrackSeedContainer");
  out->AddNode("TpcTrackSeedContainer");
  out->AddNode("SvtxTrackSeedContainer");
  out->AddNode("SvtxTrackMap");
  out->AddNode("SvtxSiliconTrackMap");
  out->AddNode("TpcSeedTrackMap");
  out->AddNode("SvtxSiliconMMTrackMap");
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
