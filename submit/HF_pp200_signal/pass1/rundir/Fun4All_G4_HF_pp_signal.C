#ifndef MACRO_FUN4ALLG4SPHENIX_C
#define MACRO_FUN4ALLG4SPHENIX_C

#include <GlobalVariables.C>

#include <G4Setup_sPHENIX.C>
#include <G4_Bbc.C>
#include <G4_Global.C>
#include <G4_Input.C>
#include <G4_Production.C>
#include <G4_TrkrSimulation.C>

#include <phpythia8/PHPy8JetTrigger.h>
#include <phpythia8/PHPy8ParticleTrigger.h>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/HeadReco.h>
#include <ffamodules/SyncReco.h>
#include <ffamodules/CDBInterface.h>

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

int Fun4All_G4_HF_pp_signal(
    const int nEvents = 1,
    // "Charm" or "Bottom"  or "CharmD0"  or "BottomD0" or "MB" or "CharmD0piKJet5" or "CharmD0piKJet12"
    const string &HF_Q_filter = "Charm",
    const string &outputFile = "G4Hits_pythia8_CharmD0piKJet5-0000007-00000.root",
    const string &outdir = ".")
{
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
  //int seedValue = 491258969;
  //rc->set_IntFlag("RANDOMSEED", seedValue);

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  // global tag
  rc->set_StringFlag("CDB_GLOBALTAG",CDB::global_tag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP",CDB::timestamp);

  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(outputFile);
  int runnumber=runseg.first;
  int segment=runseg.second;
  if (runnumber != 0)
  {
    rc->set_IntFlag("RUNNUMBER",runnumber);
    Fun4AllSyncManager *syncman = se->getSyncManager();
    syncman->SegmentNumber(segment);
  }

  //===============
  // Input options
  //===============
  // verbosity setting (applies to all input managers)
  Input::VERBOSITY = 0;

  // Enable this is emulating the nominal pp/pA/AA collision vertex distribution
  Input::BEAM_CONFIGURATION = Input::AA_COLLISION; // for 2023 sims we want the AA geometry for no pileup sims

  Input::PYTHIA8 = true;


  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  // This creates the input generator(s)
  string pythia8_config_file = string(getenv("CALIBRATIONROOT")) + "/Generators/HeavyFlavor_TG/";
  if (HF_Q_filter == "CharmD0" || HF_Q_filter == "BottomD0") pythia8_config_file += "phpythia8_d02kpi_MDC2.cfg";
  else if (HF_Q_filter == "CharmD+" || HF_Q_filter == "BottomD+") pythia8_config_file += "phpythia8_dplus2kkpi_MDC2.cfg";
  else if (HF_Q_filter == "CharmLc" || HF_Q_filter == "BottomLc") pythia8_config_file += "phpythia8_lambdac2pkpi_MDC2.cfg";
  else if (HF_Q_filter == "Charmonia") pythia8_config_file += "phpythia8_charmonium2ll_MDC2.cfg";
  else if (HF_Q_filter == "b2JpsiX") pythia8_config_file += "phpythia8_b2JpsiX_MDC2.cfg";
  else if (HF_Q_filter == "b2DX") pythia8_config_file += "phpythia8_b2DX_MDC2.cfg";
  else if (HF_Q_filter == "JetD0") pythia8_config_file += "phpythia8_jets_d02kpi_MDC2.cfg";
  else if (HF_Q_filter == "CharmD0piKJet5") pythia8_config_file += "phpythia8_CharmJet_pTHatMin2_MDC2.cfg";
  else if (HF_Q_filter == "CharmD0piKJet12") pythia8_config_file += "phpythia8_CharmJet_pTHatMin6_MDC2.cfg";
  else if (HF_Q_filter == "Charm" || HF_Q_filter == "Bottom") pythia8_config_file += "phpythia8_minBias_MDC2.cfg";
  else
  {
    std::cerr << "This macro is not to be used for generating min-bias samples, exiting now!" << std::endl;
    exit(1);
  } 
  PYTHIA8::config_file = pythia8_config_file;

  InputInit();

  //--------------
  // Set generator specific options
  //--------------
  // can only be set after InputInit() is called

  if (Input::PYTHIA8)
  {
    PHPy8ParticleTrigger * p8_hf_signal_trigger = new PHPy8ParticleTrigger();

    if (HF_Q_filter == "JetD0" || HF_Q_filter == "CharmD0" || HF_Q_filter == "CharmD+" || HF_Q_filter == "CharmLc" || HF_Q_filter == "Charm")
    {
      p8_hf_signal_trigger->AddParticles(4);
      p8_hf_signal_trigger->AddParticles(-4);
    }
    else if (HF_Q_filter == "CharmD0piKJet5" || HF_Q_filter == "CharmD0piKJet12" )
    {
      // has a D0 in HepMC Event
      p8_hf_signal_trigger->AddParticles(421);
      p8_hf_signal_trigger->AddParticles(-421);

      // force D0 decay to piK using standard decay file at https://github.com/sPHENIX-Collaboration/calibrations/tree/master/EvtGen
      EVTGENDECAYER::DecayFile = "D0.KPi.DEC";
    }
    else if (HF_Q_filter == "BottomD0"  || HF_Q_filter == "BottomD+" || HF_Q_filter == "BottomLc" || HF_Q_filter == "b2JpsiX" || HF_Q_filter == "b2DX" || HF_Q_filter == "Bottom")
    {
      p8_hf_signal_trigger->AddParticles(5);
      p8_hf_signal_trigger->AddParticles(-5);
    }
    else if (HF_Q_filter == "Charmonia" || HF_Q_filter == "MB")
    {
      // no triggering
    }
    else
    {
      cout <<"Fatal error on HF_Q_filter configuration = "<<HF_Q_filter<<endl;
      exit(1);
    }
    p8_hf_signal_trigger->SetYHighLow(1.5, -1.5); // sample a rapidity range higher than the sPHENIX tracking pseudorapidity
    p8_hf_signal_trigger->SetStableParticleOnly(false); // process unstable particles that include quarks
    p8_hf_signal_trigger->PrintConfig();
    //p8_hf_signal_trigger->Verbosity(10);

    if (HF_Q_filter == "JetD0")
    {
      PHPy8JetTrigger *p8_jet_signal_trigger = new PHPy8JetTrigger();
      p8_jet_signal_trigger->SetEtaHighLow(1.1, -1.1);
      p8_jet_signal_trigger->SetMinJetPt(10.);
      p8_jet_signal_trigger->PrintConfig();
      INPUTGENERATOR::Pythia8->register_trigger(p8_jet_signal_trigger);
    }
    else if (HF_Q_filter == "CharmD0piKJet5")
    {
      PHPy8JetTrigger *p8_jet_signal_trigger = new PHPy8JetTrigger();
      p8_jet_signal_trigger->SetEtaHighLow(1.1, -1.1);
      p8_jet_signal_trigger->SetMinJetPt(5);
      p8_jet_signal_trigger->PrintConfig();
      INPUTGENERATOR::Pythia8->register_trigger(p8_jet_signal_trigger);
    }
    else if (HF_Q_filter == "CharmD0piKJet12")
    {
      PHPy8JetTrigger *p8_jet_signal_trigger = new PHPy8JetTrigger();
      p8_jet_signal_trigger->SetEtaHighLow(1.1, -1.1);
      p8_jet_signal_trigger->SetMinJetPt(12);
      p8_jet_signal_trigger->PrintConfig();
      INPUTGENERATOR::Pythia8->register_trigger(p8_jet_signal_trigger);
    }

    INPUTGENERATOR::Pythia8->register_trigger(p8_hf_signal_trigger);
    INPUTGENERATOR::Pythia8->set_trigger_AND();
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


  //======================
  // What to run
  //======================

  // Global options (enabled for all enables subsystems - if implemented)
  //  Enable::ABSORBER = true;
  //  Enable::OVERLAPCHECK = true;
  //  Enable::VERBOSITY = 1;

  Enable::BBC = true;

  Enable::PIPE = true;

  // central tracking
  Enable::MVTX = true;

  Enable::INTT = true;

  Enable::TPC = true;

  Enable::MICROMEGAS = true;

  Enable::CEMC = true;

  Enable::HCALIN = true;

  Enable::MAGNET = true;

  Enable::HCALOUT = true;

  Enable::EPD = true;

  //! forward flux return plug door. Out of acceptance and off by default.
//  Enable::PLUGDOOR = true;
  Enable::PLUGDOOR_BLACKHOLE = true;
//  Enable::PLUGDOOR_ABSORBER = true;


  // new settings using Enable namespace in GlobalVariables.C
  Enable::BLACKHOLE = true;
  Enable::BLACKHOLE_FORWARD_SAVEHITS = false; // disable forward/backward hits
  //Enable::BLACKHOLE_SAVEHITS = false; // turn off saving of bh hits
  //BlackHoleGeometry::visible = true;


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
    Production_CreateOutputDir();
  }

  if (Enable::DSTOUT)
  {
    string FullOutFile = DstOut::OutputFile;
    Fun4AllDstOutputManager *out = new Fun4AllDstOutputManager("DSTOUT", FullOutFile);
    if (Enable::DSTOUT_COMPRESS)
      {
        ShowerCompress();
        DstCompress(out);
      }
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

  se->run(nEvents);


  CDBInterface::instance()->Print(); // print used DB files

  //-----
  // Exit
  //-----

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
