#ifndef MACRO_FUN4ALLG4EMBED_C
#define MACRO_FUN4ALLG4EMBED_C

#include <GlobalVariables.C>

#include <G4Setup_sPHENIX.C>
#include <G4_Input.C>
#include <G4_Mbd.C>
#include <G4_OutputManager_Embed.C>
#include <G4_Production.C>

#include <phpythia8/PHPy8JetTrigger.h>

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

// For HepMC Hijing
// try inputFile = /sphenix/sim/sim01/sphnxpro/sHijing_HepMC/sHijing_0-12fm.dat

int Fun4All_G4_Embed(
    const int nEvents = 1,
    const string &embed_input_file0 = "DST_BBC_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000040-00000.root",
    const string &embed_input_file1 = "DST_CALO_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000040-00000.root",
    const string &embed_input_file2 = "DST_TRKR_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000040-00000.root",
    const string &embed_input_file3 = "DST_TRUTH_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000040-00000.root",
    const string &outdir = ".",
    const string &jettrigger = "Jet30",
    const string &fmrange = "0_20fm",
    const string &cdbtag = "MDC2_ana.398")
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

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  // tag
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP", CDB::timestamp);

  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(embed_input_file0);
  int runnumber = runseg.first;
  int segment = runseg.second;
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
  // Enable this is emulating the nominal pp/pA/AA collision vertex distribution
  Input::BEAM_CONFIGURATION = Input::AA_COLLISION;  // for 2023 sims we want the AA geometry for no pileup sims

  Input::PYTHIA8 = true;
  if (Input::PYTHIA8)
  {
    string pythia8_config_file = string(getenv("CALIBRATIONROOT")) + "/Generators/JetStructure_TG/";
    if (jettrigger == "Jet10")
    {
      pythia8_config_file += "phpythia8_15GeV_JS_MDC2.cfg";
    }
    else if (jettrigger == "Jet30")
    {
      pythia8_config_file += "phpythia8_30GeV_JS_MDC2.cfg";
    }
    else if (jettrigger == "Jet40")
    {
      pythia8_config_file += "phpythia8_40GeV_JS_MDC2.cfg";
    }
    else if (jettrigger == "PhotonJet")
    {
      pythia8_config_file += "phpythia8_JS_GJ_MDC2.cfg";
    }
    else
    {
      cout << "invalid jettrigger: " << jettrigger << endl;
      gSystem->Exit(1);
    }
    PYTHIA8::config_file = pythia8_config_file;
  }

  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  InputInit();

  //--------------
  // Set generator specific options
  //--------------
  // can only be set after InputInit() is called

  if (Input::PYTHIA8)
  {
    //! apply sPHENIX nominal beam parameter with 2mrad crossing as defined in sPH-TRG-2020-001
    PHPy8JetTrigger *p8_js_signal_trigger = new PHPy8JetTrigger();
    p8_js_signal_trigger->SetEtaHighLow(1.5, -1.5);  // Set eta acceptance for particles into the jet between +/- 1.5
    p8_js_signal_trigger->SetJetR(0.4);              // Set the radius for the trigger jet
    if (jettrigger == "Jet10")
    {
      p8_js_signal_trigger->SetMinJetPt(10);  // require a 10 GeV minimum pT jet in the event
    }
    else if (jettrigger == "Jet30")
    {
      p8_js_signal_trigger->SetMinJetPt(30);  // require a 30 GeV minimum pT jet in the event
    }
    else if (jettrigger == "Jet40")
    {
      p8_js_signal_trigger->SetMinJetPt(30);  // require a 30 GeV minimum pT jet in the event
    }
    else if (jettrigger == "PhotonJet")
    {
      delete p8_js_signal_trigger;
      p8_js_signal_trigger = nullptr;
      cout << "no cut for PhotonJet" << endl;
    }
    else
    {
      cout << "invalid jettrigger: " << jettrigger << endl;
      gSystem->Exit(1);
    }
    if (p8_js_signal_trigger)
    {
      INPUTGENERATOR::Pythia8->register_trigger(p8_js_signal_trigger);
      INPUTGENERATOR::Pythia8->set_trigger_AND();
    }
    Input::ApplysPHENIXBeamParameter(INPUTGENERATOR::Pythia8);
  }

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
    CreateDstOutput(runnumber, segment, jettrigger, fmrange);
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
    cout << "using 0 for number of events is a bad idea when using particle generators" << endl;
    cout << "it will run forever, so I just return without running anything" << endl;
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
