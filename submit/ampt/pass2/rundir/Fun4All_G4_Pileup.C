#ifndef MACRO_FUN4ALLG4PILEUP_C
#define MACRO_FUN4ALLG4PILEUP_C

#include <GlobalVariables.C>

#include <G4_OutputManager_Pileup.C>
#include <G4_Production.C>

#include <g4main/Fun4AllDstPileupInputManager.h>
#include <g4main/PHG4VertexSelection.h>

#include <ffamodules/CDBInterface.h>
#include <ffamodules/FlagHandler.h>

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
int Fun4All_G4_Pileup(
    const int nEvents = 0,
    const string &inputFile = "G4Hits_ampt_0_20fm-0000000014-000000.root",
    const string &backgroundList = "pileupbkg.list",
    const string &outdir = ".",
    const string &cdbtag = "MDC2_ana.416")
{
  gSystem->Load("libg4dst.so");
  // server
  auto se = Fun4AllServer::instance();
  se->Verbosity(1);

  auto rc = recoConsts::instance();

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  // global tag
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP", CDB::timestamp);

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  // set up production relatedstuff
  Enable::PRODUCTION = true;
  Enable::DSTOUT = true;
  DstOut::OutputDir = outdir;
  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(inputFile);
  int runnumber = runseg.first;
  int segment = abs(runseg.second);
  if (Enable::PRODUCTION)
  {
    PRODUCTION::SaveOutputDir = DstOut::OutputDir;
//    Production_CreateOutputDir();
  }

  //--------------
  // Timing module is last to register
  //--------------
  TimerStats *ts = new TimerStats();
  ts->OutFileName("jobtime.root");
  se->registerSubsystem(ts);

  // signal input manager
  auto in = new Fun4AllDstInputManager("DST_signal");
  in->registerSubsystem(new PHG4VertexSelection);

  // open file
  in->fileopen(inputFile);
  se->registerInputManager(in);

  // background input manager
  auto inpile = new Fun4AllDstPileupInputManager("DST_background");
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
  /* all the nodes from DST and RUN are saved to the output */
  //  auto out = new Fun4AllDstOutputManager("DSTOUT", outputFile);
  //  se->registerOutputManager(out);
  if (Enable::PRODUCTION)
  {
    CreateDstOutput(runnumber, segment);
  }

  // process events
  se->run(nEvents);

  // terminate
  CDBInterface::instance()->Print();  // print used DB files
  se->End();
  if (Enable::PRODUCTION)
  {
    DstOutput_move();
  }
  se->PrintTimer();
  std::cout << "All done" << std::endl;
  delete se;
  gSystem->Exit(0);
  return 0;
}

#endif
