#ifndef MACRO_FUN4ALLG4EMBED_C
#define MACRO_FUN4ALLG4EMBED_C

#include <GlobalVariables.C>

#include <G4Setup_sPHENIX.C>
#include <G4_Input.C>
#include <G4_Mbd.C>
#include <G4_OutputManager_Embed.C>
#include <G4_Production.C>
#include <G4_Pythia8_Setup.C>
#include <G4_RunSettings.C>
#include <SaveGitTags.C>

#include <ffamodules/CDBInterface.h>
#include <ffamodules/FlagHandler.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllSyncManager.h>
#include <fun4all/Fun4AllUtils.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libffamodules.so)

int Fun4All_G4_Embed(
    const int nEvents = 1,
    const std::string &embed_input_file0 = "DST_BBC_G4HIT_sHijing_OO_0_15fm_220kHz_bkg_0_15fm-0000000035-000000.root",
    const std::string &embed_input_file1 = "DST_CALO_G4HIT_sHijing_OO_0_15fm_220kHz_bkg_0_15fm-0000000035-000000.root",
    const std::string &embed_input_file2 = "DST_TRKR_G4HIT_sHijing_OO_0_15fm_220kHz_bkg_0_15fm-0000000035-000000.root",
    const std::string &embed_input_file3 = "DST_TRUTH_G4HIT_sHijing_OO_0_15fm_220kHz_bkg_0_15fm-0000000035-000000.root",
    const std::string &outdir = ".",
    const std::string &jettrigger = "Jet30",
    const std::string &fmrange = "0_15fm",
    const std::string &pileup = "220kHz",
    const std::string &cdbtag = "MDC2",
    const std::string &gitcommit = "none")
{
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);

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
  if (gitcommit != "none")
  {
    SaveGitTags(gitcommit);
  }
  else
  {
    SaveGitTags();
  }

 
  //===============
  // conditions DB flags
  //===============
  std::pair<int, int> runseg = Fun4AllUtils::GetRunSegment(embed_input_file0);
  int runnumber = runseg.first;
  int segment = runseg.second;
  RunSettings(runnumber);

  Enable::CDB = true;
  // tag
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP", runnumber);

  if (runnumber != 0)
  {
    rc->set_IntFlag("RUNNUMBER", runnumber);
    Fun4AllSyncManager *syncman = se->getSyncManager();
    syncman->SegmentNumber(segment);
  }

  //===============
  // Input options
  //===============
  // verbosity setting (applies to all input managers)
  Input::VERBOSITY = 0;
  // First enable the input generators
  // Either:
  // read previously generated g4-hits files, in this case it opens a DST and skips
  // the simulations step completely. The G4Setup macro is only loaded to get information
  // about the number of layers used for the cell reco code
  //  Input::READHITS = true;
  // INPUTREADHITS::filename[0] = inputFile;
  // if you use a filelist
  // INPUTREADHITS::listfile[0] = inputFile;
  // Or:
  // Use particle generator
  // And
  // Further choose to embed newly simulated events to a previous simulation. Not compatible with `readhits = true`
  // In case embedding into a production output, please double check your G4Setup_sPHENIX.C and G4_*.C consistent with those in the production macro folder
  // E.g. /sphenix/sim//sim01/production/2016-07-21/single_particle/spacal2d/
  Input::EMBED = true;
  INPUTEMBED::filename[0] = embed_input_file0;
  INPUTEMBED::filename[1] = embed_input_file1;
  INPUTEMBED::filename[2] = embed_input_file2;
  INPUTEMBED::filename[3] = embed_input_file3;
  // no repeating of embedding background, stop processing when end of file reached
  INPUTEMBED::REPEAT = false;

  // if you use a filelist
  // INPUTEMBED::listfile[0] = embed_input_file;

  // Input::SIMPLE = true;
  // Input::SIMPLE_NUMBER = 2; // if you need 2 of them
  // Input::SIMPLE_VERBOSITY = 1;

  //  Input::PYTHIA6 = true;

  Input::PYTHIA8 = true;

  Pythia8_Generator_Setup(jettrigger);

  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  InputInit();

  //--------------
  // Set generator specific options
  //--------------
  // can only be set after InputInit() is called
  Pythia8_Trigger_Setup(jettrigger);

  //--------------
  // Set Input Manager specific options
  //--------------
  // can only be set after InputInit() is called

  // register all input generators with Fun4All
  InputRegister();

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  // set up production relatedstuff
  Enable::PRODUCTION = true;

  //======================
  // Write the DST
  //======================

  Enable::DSTOUT = true;
  Enable::DSTOUT_COMPRESS = false;
  DstOut::OutputDir = outdir;

  if (Enable::PRODUCTION)
  {
    PRODUCTION::SaveOutputDir = DstOut::OutputDir;
    //    Production_CreateOutputDir();
  }

  //======================
  // What to run
  //======================

  // Global options (enabled for all enables subsystems - if implemented)
  //  Enable::ABSORBER = true;
  //  Enable::OVERLAPCHECK = true;
  //  Enable::VERBOSITY = 1;

  Enable::MBD = true;

  Enable::PIPE = true;

  // central tracking
  Enable::MVTX = true;

  Enable::INTT = true;

  Enable::TPC = true;

  Enable::MICROMEGAS = true;

  Enable::CEMC = true;

  Enable::HCALIN = true;
  //  Enable::HCALIN_OLD = true;

  Enable::MAGNET = true;

  Enable::HCALOUT = true;
  //  Enable::HCALOUT_OLD = true;

  Enable::EPD = true;

  //! forward flux return plug door.
  Enable::PLUGDOOR = true;

  // new settings using Enable namespace in GlobalVariables.C
  Enable::BLACKHOLE = true;
  Enable::BLACKHOLE_FORWARD_SAVEHITS = false;  // disable forward/backward hits
  // Enable::BLACKHOLE_SAVEHITS = false; // turn off saving of bh hits
  // BlackHoleGeometry::visible = true;

  // Initialize the selected subsystems
  G4Init();

  //---------------------
  // GEANT4 Detector description
  //---------------------
  if (!Input::READHITS)
  {
    G4Setup();
  }

  //--------------
  // Set up Input Managers
  //--------------

  InputManagers();

  if (Enable::PRODUCTION)
  {
    PRODUCTION::SaveOutputDir = DstOut::OutputDir;
    CreateDstOutput(runnumber, segment, jettrigger, fmrange, pileup);
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
  if (nEvents == 0 && !Input::HEPMC && !Input::READHITS && INPUTEMBED::REPEAT)
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
    DstOutput_move();
  }

  gSystem->Exit(0);
  return 0;
}
#endif
