#ifndef MACRO_FUN4ALLG4CALO_C
#define MACRO_FUN4ALLG4CALO_C

#include <GlobalVariables.C>

#include <G4_CEmc_Spacal.C>
#include <G4_HcalIn_ref.C>
#include <G4_HcalOut_ref.C>
#include <G4_Input.C>
#include <G4_Production.C>
#include <G4_TopoClusterReco.C>

#include <ffamodules/CDBInterface.h>
#include <ffamodules/FlagHandler.h>

#include <fun4allutils/TimerStats.h>

#include <caloreco/CaloGeomMapping.h>
#include <caloreco/CaloTowerBuilder.h>
#include <caloreco/CaloTowerCalib.h>
#include <caloreco/CaloWaveformProcessing.h>
#include <caloreco/CaloTowerStatus.h>

#include <calowaveformsim/CaloWaveformSim.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libfun4allutils.so)
R__LOAD_LIBRARY(libCaloWaveformSim.so)
R__LOAD_LIBRARY(libcalo_reco.so)

int Fun4All_G4_Calo(
    const int nEvents = 1,
    const string &inputFile0 = "G4Hits_pythia8_Jet30-0000000019-000000.root",
    const string &inputFile1 = "pedestal-00046796.root",
    const string &outputFile = "DST_CALO_CLUSTER_pythia8_Jet30-0000000019-000000.root",
    const string &outdir = ".",
    const string &cdbtag = "MDC2_ana.438")
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
  Enable::CDB = true;
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  rc->set_uint64Flag("TIMESTAMP", CDB::timestamp);
  CDBInterface::instance()->Verbosity(1);
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
  //  Enable::VERBOSITY = 1;

  Enable::CEMC = true;
  Enable::CEMC_CELL = Enable::CEMC && true;
  Enable::CEMC_TOWER = Enable::CEMC_CELL && true;
  Enable::CEMC_CLUSTER = Enable::CEMC_TOWER && true;

  Enable::HCALIN = true;
  Enable::HCALIN_CELL = Enable::HCALIN && true;
  Enable::HCALIN_TOWER = Enable::HCALIN_CELL && true;
  Enable::HCALIN_CLUSTER = Enable::HCALIN_TOWER && true;
  G4HCALIN::tower_emin = 0.;

  Enable::HCALOUT = true;
  Enable::HCALOUT_CELL = Enable::HCALOUT && true;
  Enable::HCALOUT_TOWER = Enable::HCALOUT_CELL && true;
  Enable::HCALOUT_CLUSTER = Enable::HCALOUT_TOWER && true;
  G4HCALOUT::tower_emin = 0.;

  //------------------
  // Detector Reconstruction
  //------------------

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

  // put waveform stuff here
    CaloWaveformSim *caloWaveformSim = new CaloWaveformSim();
    caloWaveformSim->set_detector_type(CaloTowerDefs::HCALOUT);
    caloWaveformSim->set_detector("HCALOUT");
    caloWaveformSim->set_nsamples(12);
    caloWaveformSim->set_pedestalsamples(12);
    caloWaveformSim->set_timewidth(0.2);
    caloWaveformSim->set_peakpos(6);
    // caloWaveformSim->Verbosity(2);
    // caloWaveformSim->set_noise_type(CaloWaveformSim::NOISE_NONE);
    se->registerSubsystem(caloWaveformSim);

    caloWaveformSim = new CaloWaveformSim();
    caloWaveformSim->set_detector_type(CaloTowerDefs::HCALIN);
    caloWaveformSim->set_detector("HCALIN");
    caloWaveformSim->set_nsamples(12);
    caloWaveformSim->set_pedestalsamples(12);
    caloWaveformSim->set_timewidth(0.2);
    caloWaveformSim->set_peakpos(6);
    //  caloWaveformSim->set_noise_type(CaloWaveformSim::NOISE_NONE);
    se->registerSubsystem(caloWaveformSim);

    caloWaveformSim = new CaloWaveformSim();
    caloWaveformSim->set_detector_type(CaloTowerDefs::CEMC);
    caloWaveformSim->set_detector("CEMC");
    caloWaveformSim->set_nsamples(12);
    caloWaveformSim->set_pedestalsamples(12);
    caloWaveformSim->set_timewidth(0.2);
    caloWaveformSim->set_peakpos(6);
    caloWaveformSim->set_calibName("cemc_pi0_twrSlope_v1_default");

    //  caloWaveformSim->set_noise_type(CaloWaveformSim::NOISE_NONE);
    /*
    caloWaveformSim->get_light_collection_model().load_data_file(
        string(getenv("CALIBRATIONROOT")) +
            string("/CEMC/LightCollection/Prototype3Module.xml"),
        "data_grid_light_guide_efficiency", "data_grid_fiber_trans");
    */
    se->registerSubsystem(caloWaveformSim);

    CaloTowerBuilder *ca2 = new CaloTowerBuilder();
    ca2->set_detector_type(CaloTowerDefs::HCALOUT);
    ca2->set_nsamples(12);
    ca2->set_dataflag(false);
    ca2->set_processing_type(CaloWaveformProcessing::TEMPLATE);
    ca2->set_builder_type(CaloTowerDefs::kWaveformTowerv2);
    // match our current ZS threshold ~7ADC for hcal
    ca2->set_softwarezerosuppression(true, 7);
    se->registerSubsystem(ca2);

    ca2 = new CaloTowerBuilder();
    ca2->set_detector_type(CaloTowerDefs::HCALIN);
    ca2->set_nsamples(12);
    ca2->set_dataflag(false);
    ca2->set_processing_type(CaloWaveformProcessing::TEMPLATE);
    ca2->set_builder_type(CaloTowerDefs::kWaveformTowerv2);
    ca2->set_softwarezerosuppression(true, 7);
    se->registerSubsystem(ca2);

    ca2 = new CaloTowerBuilder();
    ca2->set_detector_type(CaloTowerDefs::CEMC);
    ca2->set_nsamples(12);
    ca2->set_dataflag(false);
    ca2->set_processing_type(CaloWaveformProcessing::TEMPLATE);
    ca2->set_builder_type(CaloTowerDefs::kWaveformTowerv2);
    // match our current ZS threshold ~14ADC for emcal
    ca2->set_softwarezerosuppression(true, 14);
    se->registerSubsystem(ca2);

    /////////////////////////////////////////////////////
    // Set status of towers, Calibrate towers,  Cluster
    /////////////////////////////////////////////////////
    CaloTowerStatus *statusEMC = new CaloTowerStatus("CEMCSTATUS");
    statusEMC->set_detector_type(CaloTowerDefs::CEMC);
    statusEMC->set_time_cut(1);
    se->registerSubsystem(statusEMC);

    CaloTowerStatus *statusHCalIn = new CaloTowerStatus("HCALINSTATUS");
    statusHCalIn->set_detector_type(CaloTowerDefs::HCALIN);
    statusHCalIn->set_time_cut(2);
    se->registerSubsystem(statusHCalIn);

    CaloTowerStatus *statusHCALOUT = new CaloTowerStatus("HCALOUTSTATUS");
    statusHCALOUT->set_detector_type(CaloTowerDefs::HCALOUT);
    statusHCALOUT->set_time_cut(2);
    se->registerSubsystem(statusHCALOUT);

    ////////////////////
    // Calibrate towers
    CaloTowerCalib *calibEMC = new CaloTowerCalib("CEMCCALIB");
    calibEMC->set_detector_type(CaloTowerDefs::CEMC);
    calibEMC->set_outputNodePrefix("TOWERINFO_CALIB_");
    se->registerSubsystem(calibEMC);

    CaloTowerCalib *calibOHCal = new CaloTowerCalib("HCALOUTCALIB");
    calibOHCal->set_detector_type(CaloTowerDefs::HCALOUT);
    calibOHCal->set_outputNodePrefix("TOWERINFO_CALIB_");
    se->registerSubsystem(calibOHCal);

    CaloTowerCalib *calibIHCal = new CaloTowerCalib("HCALINCALIB");
    calibIHCal->set_detector_type(CaloTowerDefs::HCALIN);
    calibIHCal->set_outputNodePrefix("TOWERINFO_CALIB_");
    se->registerSubsystem(calibIHCal);
    //////////////////
    // Clusters
    RawClusterBuilderTemplate *ClusterBuilder = new RawClusterBuilderTemplate("EmcRawClusterBuilderTemplate");
    ClusterBuilder->Detector("CEMC");
    ClusterBuilder->set_threshold_energy(0.030);  // for when using basic calibration
    std::string emc_prof = getenv("CALIBRATIONROOT");
    emc_prof += "/EmcProfile/CEMCprof_Thresh30MeV.root";
    ClusterBuilder->LoadProfile(emc_prof);
    ClusterBuilder->set_UseTowerInfo(1);  // to use towerinfo objects rather than old RawTower
    se->registerSubsystem(ClusterBuilder);
  

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
  hitsin->AddFile(inputFile1);
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
    out->AddNode("TOWER_SIM_NZ_HCALIN");
    out->AddNode("TOWER_RAW_NZ_HCALIN");
    out->AddNode("TOWER_CALIB_NZ_HCALIN");
    out->AddNode("TOWERINFO_RAW_NZ_HCALIN");
    out->AddNode("TOWERINFO_SIM_NZ_HCALIN");
    out->AddNode("TOWERINFO_CALIB_NZ_HCALIN");
    out->AddNode("CLUSTER_HCALIN");
    out->AddNode("CLUSTERINFO_HCALIN");
    out->AddNode("TOWERINFO_CALIB_HCALIN");
    out->AddNode("WAVEFORM_HCALIN");
    out->AddNode("TOWERS_HCALIN");

    // Outer Hcal
    out->AddNode("TOWER_SIM_NZ_HCALOUT");
    out->AddNode("TOWER_RAW_NZ_HCALOUT");
    out->AddNode("TOWER_CALIB_NZ_HCALOUT");
    out->AddNode("TOWERINFO_RAW_NZ_HCALOUT");
    out->AddNode("TOWERINFO_SIM_NZ_HCALOUT");
    out->AddNode("TOWERINFO_CALIB_NZ_HCALOUT");
    out->AddNode("CLUSTER_HCALOUT");
    out->AddNode("CLUSTERINFO_HCALOUT");
    out->AddNode("TOWERINFO_CALIB_HCALOUT");
    out->AddNode("WAVEFORM_HCALOUT");
    out->AddNode("TOWERS_HCALOUT");

    // CEmc
    out->AddNode("TOWER_SIM_NZ_CEMC");
    out->AddNode("TOWER_RAW_NZ_CEMC");
    out->AddNode("TOWER_CALIB_NZ_CEMC");
    out->AddNode("TOWERINFO_RAW_NZ_CEMC");
    out->AddNode("TOWERINFO_SIM_NZ_CEMC");
    out->AddNode("TOWERINFO_CALIB_NZ_CEMC");
    out->AddNode("CLUSTER_CEMC");
    out->AddNode("CLUSTERINFO_CEMC");
    out->AddNode("TOWERINFO_CALIB_CEMC");
    out->AddNode("WAVEFORM_CEMC");
    out->AddNode("TOWERS_CEMC");

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
  return 0;
}
#endif
