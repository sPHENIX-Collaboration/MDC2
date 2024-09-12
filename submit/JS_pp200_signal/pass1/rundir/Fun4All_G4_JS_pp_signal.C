#ifndef MACRO_FUN4ALLG4JSPPSIGNAL_C
#define MACRO_FUN4ALLG4JSPPSIGNAL_C

#include <GlobalVariables.C>

#include <G4Setup_sPHENIX.C>
#include <G4_Global.C>
#include <G4_Input.C>
#include <G4_Mbd.C>
#include <G4_Production.C>
#include <G4_TrkrSimulation.C>

#include <phpythia8/PHPy8JetTrigger.h>
#include <phpythia8/PHPy8ParticleTrigger.h>

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

#include <stdlib.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4allutils.so)

int Fun4All_G4_JS_pp_signal(
    const int nEvents = 1,
    const string &jettrigger = "Jet10",  // or "PhotonJet"
    const string &outputFile = "G4Hits_pythia8_Jet10-0000150-000000.root",
    const string &embed_input_file = "https://www.phenix.bnl.gov/WWW/publish/phnxbld/sPHENIX/files/sPHENIX_G4Hits_sHijing_9-11fm_00000_00010.root",
    const int skip = 0,
    const string &outdir = ".",
    const string &cdbtag = "MDC2_ana.433")
{
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);

  // Opt to print all random seed used for debugging reproducibility. Comment out to reduce stdout prints.
  PHRandomSeed::Verbosity(1);

  CDBInterface::instance()->Verbosity(1);
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

  TRACKING::pp_mode = true;
  TRACKING::pp_extended_readout_time = 90000;

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  // global tag
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP", CDB::timestamp);

  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(outputFile);
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

  // Enable this is emulating the nominal pp/pA/AA collision vertex distribution
  //  Input::BEAM_CONFIGURATION = Input::AA_COLLISION; // for 2023 sims we want the AA geometry for no pileup sims
  switch (runnumber)
  {
  case 7:
  case 10:
  case 19:
    Input::BEAM_CONFIGURATION = Input::AA_COLLISION;  // for 2023 sims we want the AA geometry for no pileup sims
    cout << "using Input::AA_COLLISION" << endl;
    break;
  case 8:
  case 11:
  case 15:
  case 20:
  case 150:
    Input::BEAM_CONFIGURATION = Input::pp_COLLISION;  // pp collisions
    cout << "using Input::pp_COLLISION" << endl;
    break;
  case 9:
  case 12:
    Input::BEAM_CONFIGURATION = Input::pA_COLLISION;  // for 2023 sims we want the AA geometry for no pileup sims
    cout << "using Input::pA_COLLISION" << endl;
    break;
  default:
    cout << "runnnumber " << runnumber << " not implemented" << endl;
    gSystem->Exit(1);
    break;
  }
  Input::PYTHIA8 = true;

  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  // This creates the input generator(s)
  string pythia8_config_file = string(getenv("CALIBRATIONROOT")) + "/Generators/JetStructure_TG/";
  if (jettrigger == "PhotonJet")
  {
    pythia8_config_file += "phpythia8_JS_GJ_MDC2.cfg";
  }
  else if (jettrigger == "PhotonJet5")
  {
    pythia8_config_file += "phpythia8_JS_GJ_ptHat5_MDC2.cfg";
  }
  else if (jettrigger == "PhotonJet10")
  {
    pythia8_config_file += "phpythia8_JS_GJ_ptHat10_MDC2.cfg";
  }
  else if (jettrigger == "PhotonJet20")
  {
    pythia8_config_file += "phpythia8_JS_GJ_ptHat20_MDC2.cfg";
  }
  else if (jettrigger == "Jet10")
  {
    pythia8_config_file += "phpythia8_15GeV_JS_MDC2.cfg";
  }
  else if (jettrigger == "Jet20")
  {
    pythia8_config_file += "phpythia8_20GeV_JS_MDC2.cfg";
  }
  else if (jettrigger == "Jet30")
  {
    pythia8_config_file += "phpythia8_30GeV_JS_MDC2.cfg";
  }
  else if (jettrigger == "Detroit")
  {
    pythia8_config_file =  string(getenv("CALIBRATIONROOT")) + "/Generators/phpythia8_detroitUE.cfg";
  }
  else
  {
    std::cout << "Invalid jet trigger " << jettrigger << std::endl;
    gSystem->Exit(1);
  }
  PYTHIA8::config_file = pythia8_config_file;

  InputInit();

  //--------------
  // Set generator specific options
  //--------------
  // can only be set after InputInit() is called

  if (Input::PYTHIA8)
  {
    if (jettrigger.find("PhotonJet") != string::npos)
    {
      PHPy8ParticleTrigger *p8_photon_jet_trigger = new PHPy8ParticleTrigger();
      p8_photon_jet_trigger->SetStableParticleOnly(false); // process unstable particles that include quarks
      p8_photon_jet_trigger->AddParticles(22);
      p8_photon_jet_trigger->SetEtaHighLow(1.5, -1.5); // sample a rapidity range higher than the sPHENIX tracking pseudorapidity
      std::vector<int> partentsId{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,-22,-21,-20,-19,-18,-17,-16,-15,-14,-13,-12,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1};
      p8_photon_jet_trigger->AddParents(partentsId);
      if (jettrigger == "PhotonJet5")
      {
	p8_photon_jet_trigger->SetPtLow(5);
      }
      else if (jettrigger == "PhotonJet10")
      {
	p8_photon_jet_trigger->SetPtLow(10);
      }
      else if (jettrigger == "PhotonJet20")
      {
	p8_photon_jet_trigger->SetPtLow(20);
      }
      else
      {
	cout << "invalid jettrigger: " << jettrigger << endl;
	gSystem->Exit(1);
      }
      INPUTGENERATOR::Pythia8->register_trigger(p8_photon_jet_trigger);
      INPUTGENERATOR::Pythia8->set_trigger_OR();
    }
    else if (jettrigger.find("Jet") != string::npos)
    {
      PHPy8JetTrigger *p8_js_signal_trigger = new PHPy8JetTrigger();
      p8_js_signal_trigger->SetEtaHighLow(1.5, -1.5);  // Set eta acceptance for particles into the jet between +/- 1.5
      p8_js_signal_trigger->SetJetR(0.4);              // Set the radius for the trigger jet
      if (jettrigger == "Jet10")
      {
	p8_js_signal_trigger->SetMinJetPt(10);  // require a 10 GeV minimum pT jet in the event
      }
      else if (jettrigger == "Jet20")
      {
	p8_js_signal_trigger->SetMinJetPt(20);  // require a 20 GeV minimum pT jet in the event
      }
      else if (jettrigger == "Jet30")
      {
	p8_js_signal_trigger->SetMinJetPt(30);  // require a 30 GeV minimum pT jet in the event
      }
      else if (jettrigger == "Jet40")
      {
	p8_js_signal_trigger->SetMinJetPt(40);  // require a 30 GeV minimum pT jet in the event
      }
      else
      {
	cout << "invalid jettrigger: " << jettrigger << endl;
	gSystem->Exit(1);
      }
      INPUTGENERATOR::Pythia8->register_trigger(p8_js_signal_trigger);
      INPUTGENERATOR::Pythia8->set_trigger_AND();
    }
    else if (jettrigger == "Detroit")
    {
      cout << "using detroit - no cuts" << std::endl;
    }
    else
    {
      cout << "Invalid jettrigger for cuts " << jettrigger << endl;
      gSystem->Exit(1);
    }
    Input::ApplysPHENIXBeamParameter(INPUTGENERATOR::Pythia8);
  }

  // register all input generators with Fun4All
  InputRegister();

  SyncReco *sync = new SyncReco();
  se->registerSubsystem(sync);

  HeadReco *head = new HeadReco();
  se->registerSubsystem(head);

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

  // Option to convert DST to human command readable TTree for quick poke around the outputs
  //   Enable::DSTREADER = true;

  //======================
  // What to run
  //======================

  // Global options (enabled for all enables subsystems - if implemented)
  //  Enable::ABSORBER = true;
  //  Enable::OVERLAPCHECK = true;
  //  Enable::VERBOSITY = 1;

  Enable::MBD = true;
  //  Enable::MBDFAKE = true;  // Smeared vtx and t0, use if you don't want real MBD in simulation

  Enable::PIPE = true;
  //  Enable::PIPE_ABSORBER = true;

  // central tracking
  Enable::MVTX = true;

  Enable::INTT = true;

  Enable::TPC = true;

  Enable::MICROMEGAS = true;

  //  cemc electronics + thin layer of W-epoxy to get albedo from cemc
  //  into the tracking, cannot run together with CEMC
  //  Enable::CEMCALBEDO = true;

  Enable::CEMC = true;

  Enable::HCALIN = true;

  Enable::MAGNET = true;
  //  Enable::MAGNET_ABSORBER = false;

  Enable::HCALOUT = true;

  Enable::EPD = true;

  //! forward flux return plug door. Out of acceptance and off by default.
  Enable::PLUGDOOR = true;
  //Enable::PLUGDOOR_BLACKHOLE = true;

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
    string FullOutFile = DstOut::OutputFile;
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
    cout << "using 0 for number of events is a bad idea when using particle generators" << endl;
    cout << "it will run forever, so I just return without running anything" << endl;
    return 0;
  }

  se->skip(skip);
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
