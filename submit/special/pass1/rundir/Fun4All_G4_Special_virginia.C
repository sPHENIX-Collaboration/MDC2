#ifndef MACRO_FUN4ALLG4SPECIAL_C
#define MACRO_FUN4ALLG4SPECIAL_C

#include <GlobalVariables.C>

#include <DisplayOn.C>
#include <G4Setup_sPHENIX.C>
#include <G4_Bbc.C>
#include <G4_CaloTrigger.C>
#include <G4_DSTReader.C>
#include <G4_Global.C>
#include <G4_HIJetReco.C>
#include <G4_Input.C>
#include <G4_Jets.C>
#include <G4_KFParticle.C>
#include <G4_ParticleFlow.C>
#include <G4_Production.C>
#include <G4_TopoClusterReco.C>
#include <G4_Tracking.C>
#include <G4_User.C>
#include <QA.C>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/HeadReco.h>
#include <ffamodules/SyncReco.h>
#include <ffamodules/XploadInterface.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllSyncManager.h>
#include <fun4all/Fun4AllUtils.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libffamodules.so)

int Fun4All_G4_Special_virginia(
  const int nEvents = 1,
  const string &outputFile = "G4Hits_special_virginia-0000000040-00000.root",
  const string &outdir = ".")
{
  int skip = 0;
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
  Enable::XPLOAD = true;
  // tag
  rc->set_StringFlag("XPLOAD_TAG",XPLOAD::tag);
  // database config
  rc->set_StringFlag("XPLOAD_CONFIG",XPLOAD::config);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP",XPLOAD::timestamp);

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
  // First enable the input generators
  // Either:
  // read previously generated g4-hits files, in this case it opens a DST and skips
  // the simulations step completely. The G4Setup macro is only loaded to get information
  // about the number of layers used for the cell reco code
  //  Input::READHITS = true;
  // INPUTREADHITS::filename[0] = inputFile;

  // Or:
  // Use particle generator
  // And
  // Further choose to embed newly simulated events to a previous simulation. Not compatible with `readhits = true`
  // In case embedding into a production output, please double check your G4Setup_sPHENIX.C and G4_*.C consistent with those in the production macro folder
  // E.g. /sphenix/sim//sim01/production/2016-07-21/single_particle/spacal2d/
  //Input::EMBED = true;
  //INPUTEMBED::filename[0] = embed_input_file;

  Input::SIMPLE = true;
  // Input::SIMPLE_NUMBER = 2; // if you need 2 of them
  // Input::SIMPLE_VERBOSITY = 1;

  //  Input::PYTHIA6 = true;

//  Input::PYTHIA8 = true;

  //  Input::GUN = true;
  //  Input::GUN_NUMBER = 3; // if you need 3 of them
  // Input::GUN_VERBOSITY = 1;

  //D0 generator
  //Input::DZERO = false;
  //Input::DZERO_VERBOSITY = 0;
  //Lambda_c generator //Not ready yet
  //Input::LAMBDAC = false;
  //Input::LAMBDAC_VERBOSITY = 0;
  // Upsilon generator
  //Input::UPSILON = true;
  //Input::UPSILON_NUMBER = 3; // if you need 3 of them
  //Input::UPSILON_VERBOSITY = 0;

  //  Input::HEPMC = true;
  // INPUTHEPMC::filename = inputFile;

  // Event pile up simulation with collision rate in Hz MB collisions.
  //Input::PILEUPRATE = 100e3;

  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  // This creates the input generator(s)

  InputInit();

  //--------------
  // Set generator specific options
  //--------------
  // can only be set after InputInit() is called

  if (Input::PYTHIA8)
  {
    Input::ApplysPHENIXBeamParameter(INPUTGENERATOR::Pythia8);
  }

  // Simple Input generator:
  // if you run more than one of these Input::SIMPLE_NUMBER > 1
  // add the settings for other with [1], next with [2]...
  if (Input::SIMPLE)
  {
    INPUTGENERATOR::SimpleEventGenerator[0]->add_particles("pi-", 1);
    if (Input::HEPMC || Input::EMBED)
    {
      INPUTGENERATOR::SimpleEventGenerator[0]->set_reuse_existing_vertex(true);
      INPUTGENERATOR::SimpleEventGenerator[0]->set_existing_vertex_offset_vector(0.0, 0.0, 0.0);
    }
    else
    {
      INPUTGENERATOR::SimpleEventGenerator[0]->set_vertex_distribution_function(PHG4SimpleEventGenerator::Uniform,
                                                                                PHG4SimpleEventGenerator::Uniform,
                                                                                PHG4SimpleEventGenerator::Uniform);
      INPUTGENERATOR::SimpleEventGenerator[0]->set_vertex_distribution_mean(0., 0., 0.);
      INPUTGENERATOR::SimpleEventGenerator[0]->set_vertex_distribution_width(0., 0., 0.);
    }
    INPUTGENERATOR::SimpleEventGenerator[0]->set_eta_range(-0.2, 0.2);
    INPUTGENERATOR::SimpleEventGenerator[0]->set_phi_range(-M_PI, M_PI);
    INPUTGENERATOR::SimpleEventGenerator[0]->set_pt_range(1., 20.);
  }
  // Upsilons
  // if you run more than one of these Input::UPSILON_NUMBER > 1
  // add the settings for other with [1], next with [2]...
  if (Input::UPSILON)
  {
    INPUTGENERATOR::VectorMesonGenerator[0]->add_decay_particles("e", 0);
    INPUTGENERATOR::VectorMesonGenerator[0]->set_rapidity_range(-1, 1);
    INPUTGENERATOR::VectorMesonGenerator[0]->set_pt_range(0., 10.);
    // Y species - select only one, last one wins
    INPUTGENERATOR::VectorMesonGenerator[0]->set_upsilon_1s();
  }
  // particle gun
  // if you run more than one of these Input::GUN_NUMBER > 1
  // add the settings for other with [1], next with [2]...
  if (Input::GUN)
  {
    INPUTGENERATOR::Gun[0]->AddParticle("pi-", 0, 1, 0);
    INPUTGENERATOR::Gun[0]->set_vtx(0, 0, 0);
  }

  //--------------
  // Set Input Manager specific options
  //--------------
  // can only be set after InputInit() is called
  if (Input::HEPMC)
  {
    INPUTMANAGER::HepMCInputManager->set_vertex_distribution_width(100e-4, 100e-4, 8, 0);  //optional collision smear in space, time
    // INPUTMANAGER::HepMCInputManager->set_vertex_distribution_mean(0,0,0,0);//optional collision central position shift in space, time
    // //optional choice of vertex distribution function in space, time
    INPUTMANAGER::HepMCInputManager->set_vertex_distribution_function(PHHepMCGenHelper::Gaus, PHHepMCGenHelper::Gaus, PHHepMCGenHelper::Gaus, PHHepMCGenHelper::Gaus);
    //! embedding ID for the event
    //! positive ID is the embedded event of interest, e.g. jetty event from pythia
    //! negative IDs are backgrounds, .e.g out of time pile up collisions
    //! Usually, ID = 0 means the primary Au+Au collision background
    //INPUTMANAGER::HepMCInputManager->set_embedding_id(Input::EmbedID);
    if (Input::PILEUPRATE > 0)
    {
      // Copy vertex settings from foreground hepmc input
      INPUTMANAGER::HepMCPileupInputManager->CopyHelperSettings(INPUTMANAGER::HepMCInputManager);
      // and then modify the ones you want to be different
      // INPUTMANAGER::HepMCPileupInputManager->set_vertex_distribution_width(100e-4,100e-4,8,0);
    }
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

  //Option to convert DST to human command readable TTree for quick poke around the outputs
  //  Enable::DSTREADER = true;

  // turn the display on (default off)
  Enable::DISPLAY = false;

  //======================
  // What to run
  //======================

  // QA, main switch
//  Enable::QA = true;

  // Global options (enabled for all enables subsystems - if implemented)
  //  Enable::ABSORBER = true;
  //  Enable::OVERLAPCHECK = true;
  //  Enable::VERBOSITY = 1;

  Enable::BBC = true;
//  Enable::BBCFAKE = true;  // Smeared vtx and t0, use if you don't want real BBC in simulation

  Enable::PIPE = true;
//  Enable::PIPE_ABSORBER = true;

  // central tracking
  Enable::MVTX = true;
//  Enable::MVTX_CELL = Enable::MVTX && true;
  Enable::MVTX_CLUSTER = Enable::MVTX_CELL && true;
  Enable::MVTX_QA = Enable::MVTX_CLUSTER && Enable::QA && true;

  Enable::INTT = true;
//  Enable::INTT_CELL = Enable::INTT && true;
  Enable::INTT_CLUSTER = Enable::INTT_CELL && true;
  Enable::INTT_QA = Enable::INTT_CLUSTER && Enable::QA && true;

  Enable::TPC = true;
//  Enable::TPC_ABSORBER = false;
//  Enable::TPC_CELL = Enable::TPC && true;
  Enable::TPC_CLUSTER = Enable::TPC_CELL && true;
  Enable::TPC_QA = Enable::TPC_CLUSTER && Enable::QA && true;

  Enable::MICROMEGAS = true;
//  Enable::MICROMEGAS_CELL = Enable::MICROMEGAS && true;
  Enable::MICROMEGAS_CLUSTER = Enable::MICROMEGAS_CELL && true;

//  Enable::TRACKING_TRACK = true;
  Enable::TRACKING_EVAL = Enable::TRACKING_TRACK && false;
  Enable::TRACKING_QA = Enable::TRACKING_TRACK && Enable::QA && true;

  //  cemc electronics + thin layer of W-epoxy to get albedo from cemc
  //  into the tracking, cannot run together with CEMC
  //  Enable::CEMCALBEDO = true;

  Enable::CEMC = true;
//  Enable::CEMC_ABSORBER = false;
//  Enable::CEMC_CELL = Enable::CEMC && true;
  Enable::CEMC_TOWER = Enable::CEMC_CELL && true;
  Enable::CEMC_CLUSTER = Enable::CEMC_TOWER && true;
  Enable::CEMC_EVAL = Enable::CEMC_CLUSTER && false;
  Enable::CEMC_QA = Enable::CEMC_CLUSTER && Enable::QA && false;

  Enable::HCALIN = true;
//  Enable::HCALIN_ABSORBER = false;
//  Enable::HCALIN_CELL = Enable::HCALIN && true;
  Enable::HCALIN_TOWER = Enable::HCALIN_CELL && true;
  Enable::HCALIN_CLUSTER = Enable::HCALIN_TOWER && true;
  Enable::HCALIN_EVAL = Enable::HCALIN_CLUSTER && false;
  Enable::HCALIN_QA = Enable::HCALIN_CLUSTER && Enable::QA && false;

  Enable::MAGNET = true;
//  Enable::MAGNET_ABSORBER = false;

  Enable::HCALOUT = true;
//  Enable::HCALOUT_ABSORBER = false;
//  Enable::HCALOUT_CELL = Enable::HCALOUT && true;
  Enable::HCALOUT_TOWER = Enable::HCALOUT_CELL && true;
  Enable::HCALOUT_CLUSTER = Enable::HCALOUT_TOWER && true;
  Enable::HCALOUT_EVAL = Enable::HCALOUT_CLUSTER && false;
  Enable::HCALOUT_QA = Enable::HCALOUT_CLUSTER && Enable::QA && false;

  Enable::EPD = true;

  //! forward flux return plug door. Out of acceptance and off by default.
//  Enable::PLUGDOOR = true;
  Enable::PLUGDOOR_BLACKHOLE = true;
//  Enable::PLUGDOOR_ABSORBER = true;

//  Enable::BEAMLINE = true;
  G4BEAMLINE::skin_thickness = 0.5;
//  Enable::BEAMLINE_ABSORBER = true;  // makes the beam line magnets sensitive volumes
//  Enable::BEAMLINE_BLACKHOLE = true; // turns the beamline magnets into black holes
//  Enable::ZDC = true;
//  Enable::ZDC_ABSORBER = true;
//  Enable::ZDC_SUPPORT = true;
//  Enable::ZDC_TOWER = Enable::ZDC && true;
  Enable::ZDC_EVAL = Enable::ZDC_TOWER && true;
//  Enable::GLOBAL_RECO = true;
  //Enable::GLOBAL_FASTSIM = true;
  
//  Enable::KFPARTICLE = true;
  //Enable::KFPARTICLE_VERBOSITY = 1;
  //Enable::KFPARTICLE_TRUTH_MATCH = true;
  //Enable::KFPARTICLE_SAVE_NTUPLE = true;
  KFParticleBaseCut::maxTrackchi2nDoF = 10;
  KFParticleBaseCut::minTrackIPchi2 = 0;

  Enable::CALOTRIGGER = Enable::CEMC_TOWER && Enable::HCALIN_TOWER && Enable::HCALOUT_TOWER && false;

//  Enable::JETS = true;
  Enable::JETS_EVAL = Enable::JETS && true;
  Enable::JETS_QA = Enable::JETS && Enable::QA && true;

  // HI Jet Reco for p+Au / Au+Au collisions (default is false for
  // single particle / p+p-only simulations, or for p+Au / Au+Au
  // simulations which don't particularly care about jets)
  Enable::HIJETS = false && Enable::JETS && Enable::CEMC_TOWER && Enable::HCALIN_TOWER && Enable::HCALOUT_TOWER;

  // 3-D topoCluster reconstruction, potentially in all calorimeter layers
  Enable::TOPOCLUSTER = true && Enable::CEMC_TOWER && Enable::HCALIN_TOWER && Enable::HCALOUT_TOWER;
  // particle flow jet reconstruction - needs topoClusters!
  Enable::PARTICLEFLOW = true && Enable::TOPOCLUSTER;

  // new settings using Enable namespace in GlobalVariables.C
  Enable::BLACKHOLE = true;
  Enable::BLACKHOLE_FORWARD_SAVEHITS = false; // disable forward/backward hits
  //Enable::BLACKHOLE_SAVEHITS = false; // turn off saving of bh hits
  //BlackHoleGeometry::visible = true;

  // run user provided code (from local G4_User.C)
  //Enable::USER = true;

  //---------------
  // World Settings
  //---------------
  //  G4WORLD::PhysicsList = "QGSP_BERT"; //FTFP_BERT_HP best for calo
  //  G4WORLD::WorldMaterial = "G4_AIR"; // set to G4_GALACTIC for material scans

  //---------------
  // Magnet Settings
  //---------------

G4MAGNET::magfield = "0"; // alternatively to specify a constant magnetic field, give a float number, which will be translated to solenoidal field in T, if string use as fieldmap name (including path)
  //  G4MAGNET::magfield = string(getenv("CALIBRATIONROOT")) + string("/Field/Map/sPHENIX.2d.root");  // default map from the calibration database
//  G4MAGNET::magfield_rescale = -1.4 / 1.5;  // make consistent with expected Babar field strength of 1.4T

  //---------------
  // Pythia Decayer
  //---------------
  // list of decay types in
  // $OFFLINE_MAIN/include/g4decayer/EDecayType.hh
  // default is All:
  // G4P6DECAYER::decayType = EDecayType::kAll;

  // Initialize the selected subsystems
  G4Init();

  //---------------------
  // GEANT4 Detector description
  //---------------------
  if (!Input::READHITS)
  {
    G4Setup();
  }

  //------------------
  // Detector Division
  //------------------

  if (Enable::BBC || Enable::BBCFAKE) Bbc_Reco();

  if (Enable::MVTX_CELL) Mvtx_Cells();
  if (Enable::INTT_CELL) Intt_Cells();
  if (Enable::TPC_CELL) TPC_Cells();
  if (Enable::MICROMEGAS_CELL) Micromegas_Cells();

  if (Enable::CEMC_CELL) CEMC_Cells();

  if (Enable::HCALIN_CELL) HCALInner_Cells();

  if (Enable::HCALOUT_CELL) HCALOuter_Cells();

  //-----------------------------
  // CEMC towering and clustering
  //-----------------------------

  if (Enable::CEMC_TOWER) CEMC_Towers();
  if (Enable::CEMC_CLUSTER) CEMC_Clusters();

  //-----------------------------
  // HCAL towering and clustering
  //-----------------------------

  if (Enable::HCALIN_TOWER) HCALInner_Towers();
  if (Enable::HCALIN_CLUSTER) HCALInner_Clusters();

  if (Enable::HCALOUT_TOWER) HCALOuter_Towers();
  if (Enable::HCALOUT_CLUSTER) HCALOuter_Clusters();

  // if enabled, do topoClustering early, upstream of any possible jet reconstruction
  if (Enable::TOPOCLUSTER) TopoClusterReco();

  //--------------
  // SVTX tracking
  //--------------
  if (Enable::MVTX_CLUSTER) Mvtx_Clustering();
  if (Enable::INTT_CLUSTER) Intt_Clustering();
  if (Enable::TPC_CLUSTER) TPC_Clustering();
  if (Enable::MICROMEGAS_CLUSTER) Micromegas_Clustering();

  if (Enable::TRACKING_TRACK)
  {
    TrackingInit();
    Tracking_Reco();
  }
  //-----------------
  // Global Vertexing
  //-----------------

  if (Enable::GLOBAL_RECO && Enable::GLOBAL_FASTSIM)
  {
    cout << "You can only enable Enable::GLOBAL_RECO or Enable::GLOBAL_FASTSIM, not both" << endl;
    gSystem->Exit(1);
  }
  if (Enable::GLOBAL_RECO)
  {
    Global_Reco();
  }
  else if (Enable::GLOBAL_FASTSIM)
  {
    Global_FastSim();
  }

  //-----------------
  // Calo Trigger Simulation
  //-----------------

  if (Enable::CALOTRIGGER)
  {
    CaloTrigger_Sim();
  }

  //---------
  // Jet reco
  //---------

  if (Enable::JETS) Jet_Reco();
  if (Enable::HIJETS) HIJetReco();

  if (Enable::PARTICLEFLOW) ParticleFlow();

  //----------------------
  // Simulation evaluation
  //----------------------

  string outputroot = outputFile;
  string remove_this = ".root";
  size_t pos = outputroot.find(remove_this);
  if (pos != string::npos)
  {
    outputroot.erase(pos, remove_this.length());
  }

  if (Enable::TRACKING_EVAL) Tracking_Eval(outputroot + "_g4svtx_eval.root");

  if (Enable::CEMC_EVAL) CEMC_Eval(outputroot + "_g4cemc_eval.root");

  if (Enable::HCALIN_EVAL) HCALInner_Eval(outputroot + "_g4hcalin_eval.root");

  if (Enable::HCALOUT_EVAL) HCALOuter_Eval(outputroot + "_g4hcalout_eval.root");

  if (Enable::JETS_EVAL) Jet_Eval(outputroot + "_jet_eval.root");

  if (Enable::DSTREADER) G4DSTreader(outputroot + "_DSTReader.root");

  if (Enable::USER) UserAnalysisInit();

  //======================
  // Run KFParticle on evt
  //======================
  if (Enable::KFPARTICLE) KFParticle_D0_Reco();
  if (Enable::KFPARTICLE) KFParticle_Lambdac_Reco();
     
  //----------------------
  // Standard QAs
  //----------------------

  if (Enable::CEMC_QA) CEMC_QA();
  if (Enable::HCALIN_QA) HCALInner_QA();
  if (Enable::HCALOUT_QA) HCALOuter_QA();

  if (Enable::JETS_QA) Jet_QA();

  if (Enable::MVTX_QA) Mvtx_QA();
  if (Enable::INTT_QA) Intt_QA();
  if (Enable::TPC_QA) TPC_QA();
  if (Enable::TRACKING_QA) Tracking_QA();

  if (Enable::TRACKING_QA && Enable::CEMC_QA && Enable::HCALIN_QA && Enable::HCALOUT_QA) QA_G4CaloTracking();

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
  if (Enable::DISPLAY)
  {
    DisplayOn();

    gROOT->ProcessLine("Fun4AllServer *se = Fun4AllServer::instance();");
    gROOT->ProcessLine("PHG4Reco *g4 = (PHG4Reco *) se->getSubsysReco(\"PHG4RECO\");");

    cout << "-------------------------------------------------" << endl;
    cout << "You are in event display mode. Run one event with" << endl;
    cout << "se->run(1)" << endl;
    cout << "Run Geant4 command with following examples" << endl;
    gROOT->ProcessLine("displaycmd()");

    return 0;
  }

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
  // QA output
  //-----

  if (Enable::QA) QA_Output("QA_" + outputroot + ".root");

  //-----
  // Exit
  //-----

  XploadInterface::instance()->Print(); // print used DB files
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
