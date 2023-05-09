#ifndef MACRO_FUN4ALLG4MULTIPLE_C
#define MACRO_FUN4ALLG4MULTIPLE_C

#include <GlobalVariables.C>

#include <G4Setup_sPHENIX.C>
#include <G4_Input.C>
#include <G4_Production.C>

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

#include <cstdlib>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libffamodules.so)

int Fun4All_G4_Multiple(
  const int nEvents = 1,
  const string &particle = "pi0", 
  const int pmin = 5000, 
  const int pmax = 40000, 
  const int nparticle = 10,
  const string &outputFile = "G4Hits_single_pi-_p_10000_10000MeV-0000000006-00000.root",
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
  Enable::CDB = true;
  // tag
  rc->set_StringFlag("CDB_GLOBALTAG", CDB::global_tag);
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
    INPUTGENERATOR::SimpleEventGenerator[0]->add_particles(particle, nparticle);
    if (Input::HEPMC || Input::EMBED)
    {
      INPUTGENERATOR::SimpleEventGenerator[0]->set_reuse_existing_vertex(true);
      INPUTGENERATOR::SimpleEventGenerator[0]->set_existing_vertex_offset_vector(0.0, 0.0, 0.0);
    }
    else
    {
      INPUTGENERATOR::SimpleEventGenerator[0]->set_vertex_distribution_function(PHG4SimpleEventGenerator::Gaus,
                                                                                PHG4SimpleEventGenerator::Gaus,
                                                                                PHG4SimpleEventGenerator::Gaus);
      INPUTGENERATOR::SimpleEventGenerator[0]->set_vertex_distribution_mean(0., 0., 0.);
      INPUTGENERATOR::SimpleEventGenerator[0]->set_vertex_distribution_width(100e-4, 100e-4, 6.);
    }
    INPUTGENERATOR::SimpleEventGenerator[0]->set_eta_range(-1.1, 1.1);
    INPUTGENERATOR::SimpleEventGenerator[0]->set_phi_range(-M_PI, M_PI);
    INPUTGENERATOR::SimpleEventGenerator[0]->set_p_range(pmin/1000., pmax/1000.);
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

  //  const string magfield = "1.5"; // alternatively to specify a constant magnetic field, give a float number, which will be translated to solenoidal field in T, if string use as fieldmap name (including path)
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

  //-----
  // Exit
  //-----

  CDBInterface::instance()->Print(); // print used DB files
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
