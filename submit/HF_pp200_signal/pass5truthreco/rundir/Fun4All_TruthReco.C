#ifndef MACRO_FUN4ALLTRUTHRECO_C
#define MACRO_FUN4ALLTRUTHRECO_C

#include <GlobalVariables.C>

#include <G4_Production.C>
#include <G4_Tracking.C>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/XploadInterface.h>

#include <fun4all/SubsysReco.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4all.so)

void Fun4All_TruthReco(
  const int nEvents = 0,
  const std::string &dst_trkr_g4hit = "DST_TRKR_G4HIT_pythia8_Charm_3MHz-0000000040-00000.root",
  const std::string &dst_trkr_cluster = "DST_TRKR_CLUSTER_pythia8_Charm_3MHz-0000000040-00000.root",
  const std::string &dst_tracks = "DST_TRACKS_pythia8_Charm_3MHz-0000000040-00000.root",
  const std::string &dst_truth = "DST_TRUTH_pythia8_Charm_3MHz-0000000040-00000.root",
  const std::string &outputFile = "DST_TRUTH_RECO_pythia8_Charm_3MHz-0000000040-00000.root",
  const std::string &outdir = "."
)
{
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);

  // make sure to printout random seeds for reproducibility
  PHRandomSeed::Verbosity(1);

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

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  build_truthreco_tables();

  auto in = new Fun4AllDstInputManager("DSTin");
  in->fileopen(dst_truth);
  se->registerInputManager(in);
  in = new Fun4AllDstInputManager("DSTinHit1");
  in->fileopen(dst_trkr_g4hit);
  se->registerInputManager(in);
  in = new Fun4AllDstInputManager("DSTin2");
  in->fileopen(dst_tracks);
  se->registerInputManager(in);
  in = new Fun4AllDstInputManager("DSTin3");
  in->fileopen(dst_trkr_cluster);
  se->registerInputManager(in);

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }

  auto out = new Fun4AllDstOutputManager("DSTOUT", outputFile);
  out->AddNode("Sync");
  out->AddNode("EventHeader");
out->AddNode("PHG4ParticleSvtxMap");
out->AddNode("SvtxPHG4ParticleMap");
  se->registerOutputManager(out);

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
}

#endif
