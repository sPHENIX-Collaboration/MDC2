#ifndef MACRO_FUN4ALLG4PILEUP_C
#define MACRO_FUN4ALLG4PILEUP_C

#include <GlobalVariables.C>

#include <G4_Production.C>
#include <G4_RunSettings.C>
#include <SaveGitTags.C>

#include <g4main/Fun4AllDstPileupInputManager.h>
#include <g4main/PHG4VertexSelection.h>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/CDBInterface.h>

#include <fun4allutils/TimerStats.h>

#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllUtils.h>
#include <fun4all/SubsysReco.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libg4testbench.so)
R__LOAD_LIBRARY(libfun4allutils.so)

//________________________________________________________________________________________________
  void Fun4All_G4_Pileup_HepMC(
    const int nEvents = 0,
    const std::string &inputFile = "HepMC_pythia8_Detroit-0000000029-000000.root",
    const std::string &backgroundList = "pileupbkgppmb.list",
    const std::string &outputFile = "DST_TRUTH_HepMC_pythia8_Detroit-0000000029-000000.root",
    const std::string &outdir = ".",
    const std::string &jettrigger = "Detroit",
    const int pileup = 200000,
    const std::string &cdbtag = "MDC2",
    const std::string &gitcommit = "none")
{
  gSystem->Load("libg4dst.so");
  // server
  auto *se = Fun4AllServer::instance();
  se->Verbosity(1);
  se->VerbosityDownscale(1000);

  auto *rc = recoConsts::instance();
//rc->set_IntFlag("RANDOMSEED", 12345);
  if (gitcommit != "none")
  {
    SaveGitTags(gitcommit);
  }
  else
  {
    SaveGitTags();
  }

  std::pair<int, int> runseg = Fun4AllUtils::GetRunSegment(inputFile);
  int runnumber = runseg.first;
  int segment = runseg.second;
  RunSettings(runnumber);
  Enable::CDB = true;
  // tag
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP",runnumber);

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  // set up production relatedstuff
  Enable::PRODUCTION = true;
  Enable::DSTOUT = true;
  DstOut::OutputDir = outdir;
  DstOut::OutputFile = outputFile;

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }

  // signal input manager
  auto *in = new Fun4AllDstInputManager("DST_signal");
//  in->registerSubsystem(new PHG4VertexSelection);

  //--------------
  // Timing module is last to register
  //--------------
  TimerStats *ts = new TimerStats();
  ts->OutFileName("jobtime.root");
  se->registerSubsystem(ts);

  // open file
  in->fileopen(inputFile);
  se->registerInputManager(in);

  // background input manager
  auto *inpile = new Fun4AllDstPileupInputManager("DST_background");
  inpile->setCollisionRate(pileup);
  double low_time_window = -105.5 / (8.0 / 1000.0); // tpc integration window start
  double high_time_window = -low_time_window + 50000; // 50us
  inpile->setPileupTimeWindow(low_time_window, high_time_window);
  inpile->setDetectorActiveCrossings("BBC",1);
  inpile->setDetectorActiveCrossings("HCALIN",1);
  inpile->setDetectorActiveCrossings("HCALOUT",1);
  inpile->setDetectorActiveCrossings("EPD",1);
  inpile->setDetectorActiveCrossings("CEMC",1);
  inpile->setDetectorActiveCrossings("BH_1",1);
  // open file
  inpile->AddListFile(backgroundList);
  se->registerInputManager(inpile);

  // output manager
  if (Enable::DSTOUT)
  {
    std::string FullOutFile = DstOut::OutputFile;
    Fun4AllDstOutputManager *out = new Fun4AllDstOutputManager("DSTOUT", FullOutFile);
    se->registerOutputManager(out);
  }

  // process events
  // if we use a negative number of events we go back to the command line here
  if (nEvents < 0)
  {
    return;
  }
  se->run(nEvents);

  // terminate
  CDBInterface::instance()->Print();
  se->End();
  if (Enable::PRODUCTION)
  {
    Production_MoveOutput();
  }
  se->PrintTimer();
  std::cout << "All done" << std::endl;
  delete se;
  gSystem->Exit(0);
}

#endif
