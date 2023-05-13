#ifndef MACRO_FUN4ALLG4SPHENIX_C
#define MACRO_FUN4ALLG4SPHENIX_C

#include <GlobalVariables.C>

#include <G4_Input.C>
#include <G4_OutputManager_Pass3Trk.C>
#include <G4_Production.C>
#include <G4_Tracking.C>
#include <G4_User.C>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/XploadInterface.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllUtils.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libffamodules.so)

int Fun4All_G4_Pass3Trk(
    const int nEvents = 1,
    const string &inputFile0 = "DST_TRKR_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000006-00000.root",
    const string &inputFile1 = "DST_TRUTH_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000006-00000.root",
    const string &outputFile = "G4sPHENIX.root",
    const string &embed_input_file = "https://www.phenix.bnl.gov/WWW/publish/phnxbld/sPHENIX/files/sPHENIX_G4Hits_sHijing_9-11fm_00000_00010.root",
    const int skip = 0,
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
  Enable::XPLOAD = true;
  rc->set_StringFlag("XPLOAD_TAG",XPLOAD::tag);
  rc->set_StringFlag("XPLOAD_CONFIG",XPLOAD::config);
  rc->set_uint64Flag("TIMESTAMP",XPLOAD::timestamp);

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
  // if you use a filelist
  // INPUTREADHITS::listfile[0] = inputFile;
  // Or:
  // Use particle generator
  // And
  // Further choose to embed newly simulated events to a previous simulation. Not compatible with `readhits = true`
  // In case embedding into a production output, please double check your G4Setup_sPHENIX.C and G4_*.C consistent with those in the production macro folder
  // E.g. /sphenix/sim//sim01/production/2016-07-21/single_particle/spacal2d/
  //  Input::EMBED = true;
  INPUTEMBED::filename[0] = embed_input_file;
  // if you use a filelist
  //INPUTEMBED::listfile[0] = embed_input_file;

  //Input::SIMPLE = true;
  // Input::SIMPLE_NUMBER = 2; // if you need 2 of them
  // Input::SIMPLE_VERBOSITY = 1;

  //  Input::PYTHIA6 = true;

  // Input::PYTHIA8 = true;

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
  //INPUTHEPMC::filename = inputFile;

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

  // Simple Input generator:
  // if you run more than one of these Input::SIMPLE_NUMBER > 1
  // add the settings for other with [1], next with [2]...
  if (Input::SIMPLE)
  {
    INPUTGENERATOR::SimpleEventGenerator[0]->add_particles("pi-", 5);
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
      INPUTGENERATOR::SimpleEventGenerator[0]->set_vertex_distribution_width(0., 0., 5.);
    }
    INPUTGENERATOR::SimpleEventGenerator[0]->set_eta_range(-1, 1);
    INPUTGENERATOR::SimpleEventGenerator[0]->set_phi_range(-M_PI, M_PI);
    INPUTGENERATOR::SimpleEventGenerator[0]->set_pt_range(0.1, 20.);
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
    if (Input::HEPMC || Input::EMBED)
    {
      INPUTGENERATOR::VectorMesonGenerator[0]->set_reuse_existing_vertex(true);
      INPUTGENERATOR::VectorMesonGenerator[0]->set_existing_vertex_offset_vector(0.0, 0.0, 0.0);
    }
  }
  // particle gun
  // if you run more than one of these Input::GUN_NUMBER > 1
  // add the settings for other with [1], next with [2]...
  if (Input::GUN)
  {
    INPUTGENERATOR::Gun[0]->AddParticle("pi-", 0, 1, 0);
    INPUTGENERATOR::Gun[0]->set_vtx(0, 0, 0);
  }

  // pythia6
  if (Input::PYTHIA6)
  {
    //! apply sPHENIX nominal beam parameter with 2mrad crossing as defined in sPH-TRG-2020-001
    Input::ApplysPHENIXBeamParameter(INPUTGENERATOR::Pythia6);
  }
  // pythia8
  if (Input::PYTHIA8)
  {
    //! apply sPHENIX nominal beam parameter with 2mrad crossing as defined in sPH-TRG-2020-001
    Input::ApplysPHENIXBeamParameter(INPUTGENERATOR::Pythia8);
  }

  //--------------
  // Set Input Manager specific options
  //--------------
  // can only be set after InputInit() is called

  if (Input::HEPMC)
  {
    //! apply sPHENIX nominal beam parameter with 2mrad crossing as defined in sPH-TRG-2020-001
    Input::ApplysPHENIXBeamParameter(INPUTMANAGER::HepMCInputManager);

    // optional overriding beam parameters
    //INPUTMANAGER::HepMCInputManager->set_vertex_distribution_width(100e-4, 100e-4, 8, 0);  //optional collision smear in space, time
    //    INPUTMANAGER::HepMCInputManager->set_vertex_distribution_mean(0,0,0,0);//optional collision central position shift in space, time
    // //optional choice of vertex distribution function in space, time
    //INPUTMANAGER::HepMCInputManager->set_vertex_distribution_function(PHHepMCGenHelper::Gaus, PHHepMCGenHelper::Gaus, PHHepMCGenHelper::Gaus, PHHepMCGenHelper::Gaus);
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
  if (Input::PILEUPRATE > 0)
  {
    //! apply sPHENIX nominal beam parameter with 2mrad crossing as defined in sPH-TRG-2020-001
    Input::ApplysPHENIXBeamParameter(INPUTMANAGER::HepMCPileupInputManager);
  }
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



  if (Enable::MVTX_CLUSTER) Mvtx_Clustering();
  if (Enable::INTT_CLUSTER) Intt_Clustering();
  if (Enable::TPC_CLUSTER) TPC_Clustering();
  if (Enable::MICROMEGAS_CLUSTER) Micromegas_Clustering();

  //--------------
  // Set up Input Managers
  //--------------

  InputManagers();

  if (Enable::PRODUCTION)
  {
    CreateDstOutput(runnumber, segment);
//    Production_CreateOutputDir();
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
  // Exit
  //-----

  XploadInterface::instance()->Print(); // print used DB files
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
