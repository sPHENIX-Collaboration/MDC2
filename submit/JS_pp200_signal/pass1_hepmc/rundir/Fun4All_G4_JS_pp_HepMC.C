#ifndef MACRO_FUN4ALLG4JSPPSIGNAL_C
#define MACRO_FUN4ALLG4JSPPSIGNAL_C

#include <GlobalVariables.C>

#include <G4Setup_sPHENIX.C>

#include <G4_Global.C>
#include <G4_Input.C>
#include <G4_Mbd.C>
#include <G4_Production.C>
#include <G4_RunSettings.C>
#include <G4_TrkrSimulation.C>
#include <SaveGitTags.C>

#include <phpythia8/PHPy8JetTrigger.h>

#include <ffamodules/CDBInterface.h>
#include <ffamodules/FlagHandler.h>
#include <ffamodules/HeadReco.h>
#include <ffamodules/SyncReco.h>

#include <g4main/PHG4InEventToTruthInfo.h>

#include <fun4allutils/TimerStats.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllSyncManager.h>
#include <fun4all/Fun4AllUtils.h>


#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4allutils.so)

int Fun4All_G4_JS_pp_HepMC(
    const int nEvents = 1,
    const std::string &jettrigger = "Detroit",  // or "PhotonJet"
    const std::string &outputFile = "HepMC_pythia8_Detroit-0000029-000000.root",
    const std::string &outdir = ".",
    const std::string &cdbtag = "MDC2",
    const std::string &gitcommit = "none")
{
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);
  se->VerbosityDownscale(1000);

  CDBInterface::instance()->Verbosity(1);

  // Opt to print all random seed used for debugging reproducibility. Comment out to reduce stdout prints.
  PHRandomSeed::Verbosity(1);

  // just if we set some flags somewhere in this macro
  recoConsts *rc = recoConsts::instance();
  // By default every random number generator uses
  // PHRandomSeed() which reads /dev/urandom to get its seed
  // if the RANDOMSEED flag is set its value is taken as seed
  // You can either set this to a random value using PHRandomSeed()
  // which will make all seeds identical (not sure what the point of
  // this would be:
  //  rc->set_IntFlag("RANDOMSEED",PHRandomSeed());
  // or set it to a fixed value so you can debug your code
  //  rc->set_IntFlag("RANDOMSEED", 12345);
  // int seedValue = 491258969;
  // rc->set_IntFlag("RANDOMSEED", seedValue);
  if (gitcommit != "none")
  {
    SaveGitTags(gitcommit);
  }
  else
  {
    SaveGitTags();
  }
  rc->set_FloatFlag("WorldSizex", 1000.);
  rc->set_FloatFlag("WorldSizey", 1000.);
  rc->set_FloatFlag("WorldSizez", 1000.);
  rc->set_StringFlag("WorldShape","G4Tubs");
  std::pair<int, int> runseg = Fun4AllUtils::GetRunSegment(outputFile);
  int runnumber = runseg.first;
  int segment = runseg.second;
  if (runnumber != 0)
  {
    rc->set_IntFlag("RUNNUMBER", runnumber);
    Fun4AllSyncManager *syncman = se->getSyncManager();
    syncman->SegmentNumber(segment);
  }

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  // global tag
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP", runnumber);

  //===============
  // Input options
  //===============
  // verbosity setting (applies to all input managers)
  Input::VERBOSITY = 0;

  RunSettings(runnumber);

  Input::PYTHIA8 = true;

  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  // This creates the input generator(s)
  std::string pythia8_config_file = std::string(getenv("CALIBRATIONROOT")) + "/Generators/HeavyFlavor_TG/phpythia8_detroit_k0_decay.cfg";
  PYTHIA8::config_file[0] = pythia8_config_file;

  InputInit();

  //--------------
  // Set generator specific options
  //--------------
  // can only be set after InputInit() is called

  // register all input generators with Fun4All
  InputRegister();

  SyncReco *sync = new SyncReco();
  se->registerSubsystem(sync);

  HeadReco *head = new HeadReco();
  se->registerSubsystem(head);

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  PHG4InEventToTruthInfo *ti = new PHG4InEventToTruthInfo();
  se->registerSubsystem(ti);

  // set up production relatedstuff
  Enable::PRODUCTION = true;

  //======================
  // Write the DST
  //======================

  Enable::DSTOUT = true;
  Enable::DSTOUT_COMPRESS = false;
  DstOut::OutputDir = outdir;
  DstOut::OutputFile = outputFile;

  //--------------
  // Timing module is last to register
  //--------------
  TimerStats *ts = new TimerStats();
  ts->OutFileName("jobtime.root");
  se->registerSubsystem(ts);

  //--------------
  // Set up Input Managers
  //--------------

  InputManagers();

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }
  if (Enable::DSTOUT)
  {
    std::string FullOutFile = DstOut::OutputFile;
    Fun4AllDstOutputManager *out = new Fun4AllDstOutputManager("DSTOUT", FullOutFile);
    se->registerOutputManager(out);
  }
  //-----------------
  // Event processing
  //-----------------
  // if we use a negative number of events we go back to the command line here
  if (nEvents < 0)
  {
    return 0;
  }
  // if we run the particle generator and use 0 it'll run forever
  if (nEvents == 0 && !Input::HEPMC && !Input::READHITS)
  {
    std::cout << "using 0 for number of events is a bad idea when using particle generators" << std::endl;
    std::cout << "it will run forever, so I just return without running anything" << std::endl;
    return 0;
  }

  se->run(nEvents);

  //-----
  // Exit
  //-----

  CDBInterface::instance()->Print();  // print used DB files
  se->End();
  std::cout << "All done" << std::endl;
  delete se;
  if (Enable::PRODUCTION)
  {
    Production_MoveOutput();
  }

  gSystem->Exit(0);
  return 0;
}
#endif
