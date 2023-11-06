#ifndef MACRO_FUN4ALLG4PASS3TRK_C
#define MACRO_FUN4ALLG4PASS3TRK_C

#include <GlobalVariables.C>

#include <G4_Input.C>
#include <G4_OutputManager_Pass3Trk.C>
#include <G4_Production.C>
#include <G4_TrkrSimulation.C>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/CDBInterface.h>

#include <fun4allutils/TimerStats.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllUtils.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4allutils.so)

int Fun4All_G4_Pass3Trk(
    const int nEvents = 1,
    const string &particle = "gamma",
    const int ptmin = 10000,
    const int ptmax = 10000,
    const string &inputFile0 = "DST_TRKR_G4HIT_single_gamma_10000_10000MeV_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000007-00000.root",
    const string &inputFile1 = "DST_TRUTH_G4HIT_single_gamma_10000_10000MeV_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000007-00000.root",
    const string &outdir = ".",
    const string &outputFile = "dummy.root")
{
  string filetype = "single_" + particle + "_" + to_string(ptmin) + "_" + to_string(ptmax) + "MeV";  
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);

  //Opt to print all random seed used for debugging reproducibility. Comment out to reduce stdout prints.
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
  Enable::CDB = true;
  // tag
  rc->set_StringFlag("CDB_GLOBALTAG", CDB::global_tag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP",CDB::timestamp);

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
  Input::READHITS = true;
  INPUTREADHITS::filename[0] = inputFile0;
  INPUTREADHITS::filename[1] = inputFile1;

  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  // This creates the input generator(s)
  InputInit();

  // register all input generators with Fun4All
  InputRegister();

  // set up production relatedstuff
  Enable::PRODUCTION = true;


  //======================
  // Write the DST
  //======================

  Enable::DSTOUT = true;
  Enable::DSTOUT_COMPRESS = false;
  DstOut::OutputFile = outputFile;
  DstOut::OutputDir = outdir;

  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(inputFile0);
  int runnumber = runseg.first;
  int segment = abs(runseg.second);
  if (Enable::PRODUCTION)
  {
    PRODUCTION::SaveOutputDir = DstOut::OutputDir;
//    Production_CreateOutputDir();
  }


  //======================
  // What to run
  //======================

  // Global options (enabled for all enables subsystems - if implemented)
  //  Enable::VERBOSITY = 1;

  // Magnetic field until this is sorted out
  G4MAGNET::magfield = std::string(getenv("CALIBRATIONROOT")) + std::string("/Field/Map/sphenix3dtrackingmapxyz.root");

  // central tracking
  Enable::MVTX = true;
  Enable::MVTX_CELL = Enable::MVTX && true;

  Enable::INTT = true;
  Enable::INTT_CELL = Enable::INTT && true;

  Enable::TPC = true;
  Enable::TPC_CELL = Enable::TPC && true;

  Enable::MICROMEGAS = true;
  Enable::MICROMEGAS_CELL = Enable::MICROMEGAS && true;


  //------------------
  // New Flag Handling
  //------------------
  FlagHandler *flg = new FlagHandler();
  se->registerSubsystem(flg);

  //------------------
  // Detector Division
  //------------------

  if (Enable::MVTX_CELL) Mvtx_Cells();
  if (Enable::INTT_CELL) Intt_Cells();
  if (Enable::TPC_CELL) TPC_Cells();
  if (Enable::MICROMEGAS_CELL) Micromegas_Cells();

  TimerStats *ts = new TimerStats();
  ts->OutFileName("jobtime.root");
  se->registerSubsystem(ts);

  //--------------
  // Set up Input Managers
  //--------------

  InputManagers();

  if (Enable::PRODUCTION)
  {
    CreateDstOutput(runnumber, segment, filetype);
//    Production_CreateOutputDir();
  }

  // if we use a negative number of events we go back to the command line here
  if (nEvents < 0)
  {
    return 0;
  }

  se->run(nEvents);

  //-----
  // Exit
  //-----

  CDBInterface::instance()->Print(); // print used DB files
  se->End();
  se->PrintTimer();
  std::cout << "All done" << std::endl;
  if (Enable::PRODUCTION)
  {
    DstOutput_move();
  }

  delete se;
  gSystem->Exit(0);
  return 0;
}
#endif
