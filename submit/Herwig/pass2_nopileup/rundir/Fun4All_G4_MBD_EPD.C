#ifndef MACRO_FUN4ALLG4MBDEPD_C
#define MACRO_FUN4ALLG4MBDEPD_C

#include <GlobalVariables.C>

#include <G4_EPD.C>
#include <G4_Input.C>
#include <G4_Mbd.C>
#include <G4_Production.C>
#include <G4_RunSettings.C>
#include <SaveGitTags.C>

#include <ffamodules/CDBInterface.h>
#include <ffamodules/FlagHandler.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllUtils.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4all.so)

void Fun4All_G4_MBD_EPD(
    const int nEvents = 1,
    const string &inputFile = "G4Hits_Herwig_MB-0000000022-000000.root",
    const string &outputFile = "DST_MBD_EPD_Herwig_MB-0000000022-000000.root",
    const string &outdir = ".",
    const string &cdbtag = "MDC2")
{
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);

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

  SaveGitTags(); // save the git tags from rebuild.info as rc string flags

  //===============
  // conditions DB flags
  //===============

  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(outputFile);
  int runnumber = runseg.first;

  Enable::CDB = true;
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  rc->set_uint64Flag("TIMESTAMP", runnumber);
  CDBInterface::instance()->Verbosity(1);

  RunSettings(runnumber);

  //===============
  // Input options
  //===============
  // verbosity setting (applies to all input managers)
  Input::VERBOSITY = 1;
  // First enable the input generators
  // Either:
  // read previously generated g4-hits files, in this case it opens a DST and skips
  // the simulations step completely. The G4Setup macro is only loaded to get information
  // about the number of layers used for the cell reco code
  Input::READHITS = true;
  INPUTREADHITS::filename[0] = inputFile;

  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  // This creates the input generator(s)
  InputInit();

  // register all input generators with Fun4All
  InputRegister();

  // register the flag handling
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
  DstOut::OutputFile = outputFile;

  //======================
  // What to run
  //======================
  // Global options (enabled for all enables subsystems - if implemented)
  //  Enable::ABSORBER = true;
  //  Enable::OVERLAPCHECK = true;
  //  Enable::VERBOSITY = 1;

  Enable::MBDRECO = true;  // needed in Mbd_Reco()

  Mbd_Reco();

  EPD_Tiles();

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
    string FullOutFile = DstOut::OutputFile;
    Fun4AllDstOutputManager *out = new Fun4AllDstOutputManager("DSTOUT", FullOutFile);
    out->AddNode("Sync");
    out->AddNode("EventHeader");
    out->AddNode("MbdPmtContainer");
    out->AddNode("MbdOut");
    out->AddNode("MbdVertexMap");
    out->AddNode("TOWERINFO_SIM_EPD");
    out->AddNode("TOWERINFO_CALIB_EPD");
    se->registerOutputManager(out);
  }

  // if we use a negative number of events we go back to the command line here
  if (nEvents < 0)
  {
    return;
  }
  // if we run the particle generator and use 0 it'll run forever
  if (nEvents == 0 && !Input::HEPMC && !Input::READHITS)
  {
    cout << "using 0 for number of events is a bad idea when using particle generators" << endl;
    cout << "it will run forever, so I just return without running anything" << endl;
    return;
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
}
#endif
