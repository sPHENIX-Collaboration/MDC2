#ifndef MACRO_FUN4ALLG4PASS0HERWIG_C
#define MACRO_FUN4ALLG4PASS0HERWIG_C

#include <GlobalVariables.C>

#include <G4Setup_sPHENIX.C>
#include <G4_Herwig7_Setup.C>
#include <G4_Input.C>
#include <G4_Mbd.C>
#include <G4_Production.C>
#include <G4_RunSettings.C>
#include <G4_TrkrSimulation.C>
#include <SaveGitTags.C>

#include <phherwig7/PHHerwig7ParticleTrigger.h>

#include <ffamodules/CDBInterface.h>
#include <ffamodules/FlagHandler.h>
#include <ffamodules/HeadReco.h>
#include <ffamodules/SyncReco.h>

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

int Fun4All_G4_Pass0_herwig(
    const int nEvents = 1,
    const std::string &outputFile = "DST_HEPMC_herwig_mb-0000000028-000000.root",
    const std::string &outdir = ".",
    const std::string &jettrigger = "PhotonJet5Frag",
    const std::string &cdbtag = "MDC2",
    const std::string &gitcommit = "none")
{
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(0);

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
  if (gitcommit != "none")
  {
    SaveGitTags(gitcommit);
  }
  else
  {
    SaveGitTags();
  }

  // this extracts the runnumber and segment from the output filename
  // and sets this so the server can pick it up
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
  Input::VERBOSITY = 1;  // so we get prinouts of the event number
  Input::HERWIG7 = true;
  Input::EmbedId = 1;

  // Event pile up simulation with collision rate in Hz MB collisions.
  // Enable this is emulating the nominal pp/pA/AA collision vertex distribution

  RunSettings(runnumber);

  Herwig7_Generator_Setup(jettrigger);
  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  // This creates the input generator(s)
  InputInit();

  //--------------
  // Set Input Manager specific options
  //--------------
  // can only be set after InputInit() is called

  Herwig7_Trigger_Setup(jettrigger);

  if (Input::HEPMC)
  {
    //! apply sPHENIX beam parameters with 2mrad crossing as defined in sPH-TRG-2020-001
    Input::ApplysPHENIXBeamParameter(INPUTMANAGER::HepMCInputManager);
  }
  // register all input generators with Fun4All
  InputRegister();

  SyncReco *sync = new SyncReco();
  se->registerSubsystem(sync);

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  HeadReco *head = new HeadReco();
  se->registerSubsystem(head);

  // set up production relatedstuff
  Enable::PRODUCTION = true;

  //======================
  // Write the DST
  //======================

  Enable::DSTOUT = true;

  DstOut::OutputDir = outdir;
  DstOut::OutputFile = outputFile;

  //======================
  // What to run
  //======================
  // Global options (enabled for all enables subsystems - if implemented)
  //  Enable::ABSORBER = true;
  //  Enable::OVERLAPCHECK = true;
  //  Enable::VERBOSITY = 1;

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
    if (Enable::DSTOUT_COMPRESS) DstCompress(out);
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
#endif
