#ifndef MACRO_FUN4ALLG4EMBED_C
#define MACRO_FUN4ALLG4EMBED_C

#include <GlobalVariables.C>

#include <G4Setup_sPHENIX.C>
#include <G4_Bbc.C>
#include <G4_Input.C>
#include <G4_OutputManager_Embed.C>
#include <G4_Production.C>

#include <calib_emc_pi0/CaloCalibEmc_Pi0.h>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/CDBInterface.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllSyncManager.h>
#include <fun4all/Fun4AllUtils.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>


R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libcalibCaloEmc_pi0.so)

int Fun4All_G4_Eta_Embed(
    const int nEvents = 1,
    const string &embed_input_file0 = "DST_BBC_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000007-00000.root",
    const string &embed_input_file1 = "DST_CALO_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000007-00000.root",
    const string &embed_input_file2 = "DST_TRKR_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000007-00000.root",
    const string &embed_input_file3 = "DST_TRUTH_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000007-00000.root",
    const int skip = 0,
    const string &outdir = ".",
    const string &particle = "eta",
    const string &ntupfile = "CALIB_EMC_single_eta_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000007-00000.root")
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

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  // tag
  rc->set_StringFlag("CDB_GLOBALTAG", CDB::global_tag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP",CDB::timestamp);

  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(embed_input_file0);
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
  //INPUTEMBED::listfile[0] = embed_input_file;

   Input::SIMPLE = true;
  // Input::SIMPLE_NUMBER = 2; // if you need 2 of them
  // Input::SIMPLE_VERBOSITY = 1;

  //  Input::PYTHIA6 = true;

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

  Input::HEPMC = false;
  // INPUTHEPMC::filename = inputFile;

  // Event pile up simulation with collision rate in Hz MB collisions.
  //Input::PILEUPRATE = 100e3;

  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  InputInit();

  //--------------
  // Set generator specific options
  //--------------
  // can only be set after InputInit() is called

  // Simple Input generator:
  // if you run more than one of these Input::SIMPLE_NUMBER > 1
  // add the settings for other with [1], next with [2]...
  if (Input::SIMPLE)
  {
    INPUTGENERATOR::SimpleEventGenerator[0]->add_particles("eta",10);     
    if (Input::HEPMC || Input::EMBED)
    {
			//INPUTGENERATOR::SimpleEventGenerator[0]->set_reuse_global_vertex(true);
      INPUTGENERATOR::SimpleEventGenerator[0]->set_reuse_existing_vertex(true);
      INPUTGENERATOR::SimpleEventGenerator[0]->set_existing_vertex_offset_vector(0.0, 0.0, 0.0);
    }
    else
    {
      INPUTGENERATOR::SimpleEventGenerator[0]->set_vertex_distribution_function(PHG4SimpleEventGenerator::Gaus,
                                                                                PHG4SimpleEventGenerator::Gaus,
                                                                                PHG4SimpleEventGenerator::Gaus);
      INPUTGENERATOR::SimpleEventGenerator[0]->set_vertex_distribution_mean(0., 0., 0.);
      INPUTGENERATOR::SimpleEventGenerator[0]->set_vertex_distribution_width(0.01, 0.01, 5.);
    }
    INPUTGENERATOR::SimpleEventGenerator[0]->set_eta_range(-1.15, 1.15);
    INPUTGENERATOR::SimpleEventGenerator[0]->set_phi_range(-M_PI, M_PI);
    INPUTGENERATOR::SimpleEventGenerator[0]->set_pt_range(0.5, 20.0);
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

  Enable::BBC = true;
  // Enable::BBC_SUPPORT = true; // save hist in bbc support structure
  //Enable::BBCFAKE = true;  // Smeared vtx and t0, use if you don't want real BBC in simulation

  Enable::PIPE = true;

  // central tracking
  Enable::MVTX = true;

  Enable::INTT = true;

  Enable::TPC = true;

  Enable::MICROMEGAS = true;
  //  cemc electronics + thin layer of W-epoxy to get albedo from cemc
  //  into the tracking, cannot run together with CEMC
  //  Enable::CEMCALBEDO = true;

  Enable::CEMC = true;
  Enable::CEMC_CELL = Enable::CEMC && true;
  Enable::CEMC_TOWER = Enable::CEMC_CELL && true;
  Enable::CEMC_CLUSTER = Enable::CEMC_TOWER && true;

  Enable::HCALIN = true;

  Enable::MAGNET = true;

  Enable::HCALOUT = true;

  Enable::EPD = true;

//  Enable::BEAMLINE = true;
//  Enable::BEAMLINE_ABSORBER = true;  // makes the beam line magnets sensitive volumes
//  Enable::BEAMLINE_BLACKHOLE = true; // turns the beamline magnets into black holes
//  Enable::ZDC = true;

  //! forward flux return plug door. Out of acceptance and off by default.
  //Enable::PLUGDOOR = true;
  Enable::PLUGDOOR_ABSORBER = true;

  // new settings using Enable namespace in GlobalVariables.C
  Enable::BLACKHOLE = true;
  Enable::BLACKHOLE_FORWARD_SAVEHITS = false; // disable forward/backward hits
  //Enable::BLACKHOLE_SAVEHITS = false; // turn off saving of bh hits
  //BlackHoleGeometry::visible = true;

  //---------------
  // World Settings
  //---------------
  //  G4WORLD::PhysicsList = "FTFP_BERT"; //FTFP_BERT_HP best for calo
  //  G4WORLD::WorldMaterial = "G4_AIR"; // set to G4_GALACTIC for material scans

  //---------------
  // Magnet Settings
  //---------------

  //  G4MAGNET::magfield =  string(getenv("CALIBRATIONROOT"))+ string("/Field/Map/sphenix3dbigmapxyz.root");  // default map from the calibration database
  //  G4MAGNET::magfield = "1.5"; // alternatively to specify a constant magnetic field, give a float number, which will be translated to solenoidal field in T, if string use as fieldmap name (including path)
//  G4MAGNET::magfield_rescale = 1.;  // make consistent with expected Babar field strength of 1.4T

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

  if (Enable::CEMC_CELL) CEMC_Cells();
  //-----------------------------
  // CEMC towering and clustering
  //-----------------------------

  if (Enable::CEMC_TOWER) CEMC_Towers();
  if (Enable::CEMC_CLUSTER) CEMC_Clusters();

  //--------------
  // Set up Input Managers
  //--------------

  InputManagers();

  if (Enable::PRODUCTION)
  {
    std::string fullparticle = "single_" + particle;
    PRODUCTION::SaveOutputDir = DstOut::OutputDir;
    CreateDstOutput(runnumber, segment, fullparticle);
    OUTPUTMANAGER::outfiles.insert(ntupfile);
  }

  CaloCalibEmc_Pi0 *eval_eta2 = new CaloCalibEmc_Pi0("ETACALIB", ntupfile);
                                                // this call is needed for embedding
  eval_eta2->set_centrality_nclusters_cut(350);  // which uses more central events
                                                // than we will for data to enhance Bkg
                                                // to match the enhanced signal from embed
  se->registerSubsystem(eval_eta2);
  cout << "successful registration of eta " << endl;

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

  se->skip(skip);
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
    DstOutput_move();
  }

  gSystem->Exit(0);
  return 0;
}
#endif
