#include <G4_Magnet.C>
#include <G4_Micromegas.C>
#include <G4_Production.C>
#include <G4_Tracking.C>

#include <ffamodules/FlagHandler.h>

#include <fun4all/SubsysReco.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>


R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4all.so)

//________________________________________________________________________________________________
int Fun4All_G4_sPHENIX_jobC(
  const int nEvents = 0,
  const int nSkipEvents = 0,
  const std::string &inputFile = "DST_TRACKSEEDS_pythia8_PhotonJet_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000040-00000.root",
  const std::string &outputFile = "DST_TRACKS_pythia8_PhotonJet_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000040-00000.root",
  const std::string &outdir = "."
  )
{

  // print inputs
  std::cout << "Fun4All_G4_sPHENIX_jobC - nEvents: " << nEvents << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_jobC - nSkipEvents: " << nSkipEvents << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_jobC - inputFile: " << inputFile << std::endl;
  std::cout << "Fun4All_G4_sPHENIX_jobC - outputFile: " << outputFile << std::endl;

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
  G4TPC::ENABLE_CORRECTIONS = true;
  G4TPC::correction_filename = string(getenv("CALIBRATIONROOT")) + "/distortion_maps/distortion_corrections_empty.root";
  
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
  
  // input manager
  auto in = new Fun4AllDstInputManager("DSTin");
  in->fileopen(inputFile);
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
  out->AddNode("TRKR_CLUSTER");
  out->AddNode("TRKR_CLUSTERCROSSINGASSOC");
  out->AddNode("SvtxTrackMap");
  out->AddNode("SvtxVertexMap");
  se->registerOutputManager(out);

  // skip events if any specified
  if( nSkipEvents > 0 )
  { se->skip( nSkipEvents ); }

  // process events
  se->run(nEvents);

  // terminate
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
