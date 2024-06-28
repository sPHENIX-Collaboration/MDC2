// these include guards are not really needed, but if we ever include this
// file somewhere they would be missed and we will have to refurbish all macros
#ifndef MACRO_FUN4ALLG4WAVEFORM_C
#define MACRO_FUN4ALLG4WAVEFORM_C

#include <GlobalVariables.C>

#include <G4_CEmc_Spacal.C>
#include <G4_HcalIn_ref.C>
#include <G4_HcalOut_ref.C>
#include <G4_Input.C>
#include <G4_Production.C>

#include <caloreco/CaloGeomMapping.h>
#include <caloreco/CaloTowerBuilder.h>
#include <caloreco/CaloTowerCalib.h>
#include <caloreco/CaloWaveformProcessing.h>

#include <calowaveformsim/CaloWaveformSim.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>

#include <ffamodules/CDBInterface.h>
#include <ffamodules/FlagHandler.h>

#include <fun4allutils/TimerStats.h>

#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libg4centrality.so)
R__LOAD_LIBRARY(libCaloWaveformSim.so)
R__LOAD_LIBRARY(libcalo_reco.so)
R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4allutils.so)

void Fun4All_G4_Waveform(
    const int nEvents = 1,
    const string &inputFile0 = "DST_CALO_G4HIT_pythia8_PhotonJet20_2MHz-0000000015-000000.root",
    const string &inputFile1 = "DST_CALO_CLUSTER_pythia8_PhotonJet20_2MHz-0000000015-000000.root",
    const string &inputFile2 = "pedestal.root",
    
    const string &outputFile = "DST_CALO_WAVEFORM_pythia8_PhotonJet20_2MHz-0000000015-000000.root",
    const string &outdir = ".",
    const string &cdbtag = "MDC2_ana.418")

{
  
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1); // set it to 1 if you want event printouts

  recoConsts *rc = recoConsts::instance();

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  rc->set_uint64Flag("TIMESTAMP", CDB::timestamp);
  CDBInterface::instance()->Verbosity(1);

  // you only need a list that have all G4hits and primary truth to run the
  // correction it is safe to just have the g4hit list
  //-----------------------------
  
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

  INPUTREADHITS::filename[0] = inputFile0;
  INPUTREADHITS::filename[1] = inputFile1;
  



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

  

  CaloWaveformSim *caloWaveformSim = new CaloWaveformSim();
  caloWaveformSim->set_detector_type(CaloTowerDefs::HCALOUT);
  caloWaveformSim->set_detector("HCALOUT");
  caloWaveformSim->set_nsamples(12);
  //caloWaveformSim->Verbosity(2);
  //caloWaveformSim->set_noise_type(CaloWaveformSim::NOISE_NONE);
  se->registerSubsystem(caloWaveformSim);
  

  caloWaveformSim = new CaloWaveformSim();
  caloWaveformSim->set_detector_type(CaloTowerDefs::HCALIN);
  caloWaveformSim->set_detector("HCALIN");
  caloWaveformSim->set_nsamples(12);
  //  caloWaveformSim->set_noise_type(CaloWaveformSim::NOISE_NONE);
  se->registerSubsystem(caloWaveformSim);


 

  caloWaveformSim = new CaloWaveformSim();
  caloWaveformSim->set_detector_type(CaloTowerDefs::CEMC);
  caloWaveformSim->set_detector("CEMC");
  caloWaveformSim->set_nsamples(12);
  caloWaveformSim->set_calibName("cemc_pi0_twrSlope_v1_default");
  
  //  caloWaveformSim->set_noise_type(CaloWaveformSim::NOISE_NONE);
  
  caloWaveformSim->get_light_collection_model().load_data_file(
  string(getenv("CALIBRATIONROOT")) +
  string("/CEMC/LightCollection/Prototype3Module.xml"),
  "data_grid_light_guide_efficiency", "data_grid_fiber_trans");
  
  se->registerSubsystem(caloWaveformSim);

  CaloTowerBuilder *ca2 = new CaloTowerBuilder();
  ca2->set_detector_type(CaloTowerDefs::HCALOUT);
  ca2->set_nsamples(12);
  ca2->set_dataflag(false);
  ca2->set_processing_type(CaloWaveformProcessing::TEMPLATE);
  ca2->set_builder_type(CaloTowerDefs::kWaveformTowerv2);
  se->registerSubsystem(ca2);

  ca2 = new CaloTowerBuilder();
  ca2->set_detector_type(CaloTowerDefs::HCALIN);
  ca2->set_nsamples(12);
  ca2->set_dataflag(false);
  ca2->set_processing_type(CaloWaveformProcessing::TEMPLATE);
  ca2->set_builder_type(CaloTowerDefs::kWaveformTowerv2);
  se->registerSubsystem(ca2);

  ca2 = new CaloTowerBuilder();
  ca2->set_detector_type(CaloTowerDefs::CEMC);
  ca2->set_nsamples(12);
  ca2->set_dataflag(false);
  ca2->set_processing_type(CaloWaveformProcessing::TEMPLATE);
  ca2->set_builder_type(CaloTowerDefs::kWaveformTowerv2);
  se->registerSubsystem(ca2);

  // tower calib

  CaloTowerCalib *calib = new CaloTowerCalib();
  calib->set_detector_type(CaloTowerDefs::HCALOUT);
  calib->set_outputNodePrefix("TOWERSWAVEFORM_CALIB_");
  se->registerSubsystem(calib);

  calib = new CaloTowerCalib();
  calib->set_detector_type(CaloTowerDefs::HCALIN);
  calib->set_outputNodePrefix("TOWERSWAVEFORM_CALIB_");
  se->registerSubsystem(calib);

  calib = new CaloTowerCalib();
  calib->set_detector_type(CaloTowerDefs::CEMC);
  calib->set_outputNodePrefix("TOWERSWAVEFORM_CALIB_");
  se->registerSubsystem(calib);

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
  
  Fun4AllInputManager *hitsin = new Fun4AllNoSyncDstInputManager("DST2");
  hitsin->AddFile(inputFile2);
  hitsin->Repeat();
  se->registerInputManager(hitsin);

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
// Inner Hcal
    out->AddNode("CLUSTER_HCALIN");
    out->AddNode("TOWER_SIM_HCALIN");
    out->AddNode("TOWER_RAW_HCALIN");
    out->AddNode("TOWER_CALIB_HCALIN");
    out->AddNode("TOWERINFO_RAW_HCALIN");
    out->AddNode("TOWERINFO_SIM_HCALIN");
    out->AddNode("TOWERINFO_CALIB_HCALIN");
    out->AddNode("WAVEFORM_HCALIN");
    out->AddNode("TOWERS_HCALIN");
    out->AddNode("TOWERSWAVEFORM_CALIB_HCALIN");

// Outer Hcal
    out->AddNode("CLUSTER_HCALOUT");
    out->AddNode("TOWER_SIM_HCALOUT");
    out->AddNode("TOWER_RAW_HCALOUT");
    out->AddNode("TOWER_CALIB_HCALOUT");
    out->AddNode("TOWERINFO_RAW_HCALOUT");
    out->AddNode("TOWERINFO_SIM_HCALOUT");
    out->AddNode("TOWERINFO_CALIB_HCALOUT");
    out->AddNode("WAVEFORM_HCALOUT");
    out->AddNode("TOWERS_HCALOUT");
    out->AddNode("TOWERSWAVEFORM_CALIB_HCALOUT");

// CEmc
    out->AddNode("CLUSTER_CEMC");
    out->AddNode("CLUSTER_POS_COR_CEMC");
    out->AddNode("TOWER_SIM_CEMC");
    out->AddNode("TOWER_RAW_CEMC");
    out->AddNode("TOWER_CALIB_CEMC");
    out->AddNode("TOWERINFO_RAW_CEMC");
    out->AddNode("TOWERINFO_SIM_CEMC");
    out->AddNode("TOWERINFO_CALIB_CEMC");
    out->AddNode("WAVEFORM_CEMC");
    out->AddNode("TOWERS_CEMC");
    out->AddNode("TOWERSWAVEFORM_CALIB_CEMC");

// leave the topo cluster here in case we run this during pass3
    out->AddNode("TOPOCLUSTER_ALLCALO");
    out->AddNode("TOPOCLUSTER_EMCAL");
    out->AddNode("TOPOCLUSTER_HCAL");
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
  se->run(nEvents);

  //-----
  // Exit
  //-----

  CDBInterface::instance()->Print(); // print used DB files
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

#endif // MACRO_FUN4ALLG4WAVEFORM_C
