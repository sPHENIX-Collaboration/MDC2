#include <GlobalVariables.C>

#include <G4_Magnet.C>
#include <G4_Production.C>
#include <Trkr_RecoInit.C>
#include <Trkr_Reco.C>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/CDBInterface.h>

#include <fun4allutils/TimerStats.h>

#include <fun4all/SubsysReco.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>


R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libfun4allutils.so)

//________________________________________________________________________________________________
int Fun4All_G4_sPHENIX_jobC(
  const int nEvents = 0,
  const int nSkipEvents = 0,
  const std::string &inputFile1 = "DST_TRACKSEEDS_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000019-00000.root",
  const std::string &inputFile2 = "DST_CALO_CLUSTER_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000019-00000.root",
  const std::string &outputFile = "DST_TRACKS_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000019-00000.root",
  const std::string &outdir = ".",
  const string &cdbtag = "MDC2_ana.412")
{

  // print inputs
  std::cout << "Fun4All_G4_sPHENIX_jobC - nEvents: " << nEvents << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_jobC - nSkipEvents: " << nSkipEvents << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_jobC - seed inputFile: " << inputFile1 << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_jobC - cluster inputFile: " << inputFile2 << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_jobC - outputFile: " << outputFile << std::endl;

  recoConsts *rc = recoConsts::instance();

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  // tag
  rc->set_StringFlag("CDB_GLOBALTAG",cdbtag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP",CDB::timestamp);

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
  G4TPC::ENABLE_STATIC_DISTORTIONS = false;
  G4TPC::ENABLE_TIME_ORDERED_DISTORTIONS = false;

  /* distortion corrections */
  G4TPC::ENABLE_STATIC_CORRECTIONS = false;
  G4TPC::ENABLE_AVERAGE_CORRECTIONS = false;
  G4TPC::static_correction_filename = string(getenv("CALIBRATIONROOT")) + "/distortion_maps/distortion_corrections_empty.root";
  G4TPC::average_correction_filename = string(getenv("CALIBRATIONROOT")) + "/distortion_maps/distortion_corrections_empty.root";
  // tracking configuration
  G4TRACKING::use_full_truth_track_seeding = false;

  // server
  auto se = Fun4AllServer::instance();
  se->Verbosity(1);

  // make sure to printout random seeds for reproducibility
  PHRandomSeed::Verbosity(1);

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  MagnetFieldInit();
  TrackingInit();
  
  // tracking
  /* we only run the track fit, starting with seed from JobA */
  Tracking_Reco_TrackFit();
  
  //--------------
  // Timing module is last to register
  //--------------
  TimerStats *ts = new TimerStats();
  ts->OutFileName("jobtime.root");
  se->registerSubsystem(ts);

  // input manager
  auto in = new Fun4AllDstInputManager("DSTin1");
  in->fileopen(inputFile1);
  se->registerInputManager(in);
  in = new Fun4AllDstInputManager("DSTin2");
  in->fileopen(inputFile2);
  se->registerInputManager(in);

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }
  // output manager
  auto out = new Fun4AllDstOutputManager("DSTOUT", outputFile);
  /* 
   * in principle one would not need to store the clusters and cluster crossing node, as they are already in the output from Job0
   */
  out->AddNode("Sync");
  out->AddNode("EventHeader");
  // out->AddNode("TRKR_CLUSTER");
  // out->AddNode("TRKR_CLUSTERCROSSINGASSOC");
  out->AddNode("SvtxTrackMap");
  out->AddNode("SvtxVertexMap");
  se->registerOutputManager(out);

  // skip events if any specified
  if( nSkipEvents > 0 )
  { se->skip( nSkipEvents ); }

  // process events
  se->run(nEvents);

  // terminate
  CDBInterface::instance()->Print(); // print used DB files
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
