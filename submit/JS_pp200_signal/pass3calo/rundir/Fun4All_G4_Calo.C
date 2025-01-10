// these include guards are not really needed, but if we ever include this
// file somewhere they would be missed and we will have to refurbish all macros
#ifndef MACRO_FUN4ALLG4CALO_C
#define MACRO_FUN4ALLG4CALO_C

#include <GlobalVariables.C>

#include <G4_CEmc_Spacal.C>
#include <G4_HcalIn_ref.C>
#include <G4_HcalOut_ref.C>
#include <G4_Input.C>
#include <G4_Production.C>

#include <caloreco/CaloGeomMapping.h>
#include <caloreco/CaloTowerBuilder.h>
#include <caloreco/CaloTowerCalib.h>
#include <caloreco/CaloTowerStatus.h>
#include <caloreco/CaloWaveformProcessing.h>

#include <calowaveformsim/CaloWaveformSim.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllRunNodeInputManager.h>
#include <fun4all/Fun4AllServer.h>

#include <ffamodules/CDBInterface.h>
#include <ffamodules/FlagHandler.h>

#include <fun4allutils/TimerStats.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libg4centrality.so)
R__LOAD_LIBRARY(libCaloWaveformSim.so)
R__LOAD_LIBRARY(libcalo_reco.so)
R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4allutils.so)

void Fun4All_G4_Calo(
    const int nEvents = 1,
    const string &inputFile0 = "DST_CALO_G4HIT_pythia8_Jet10_300kHz-0000000022-000000.root",
    const string &outputFile = "DST_CALO_CLUSTER_pythia8_Jet10_300kHz-0000000022-000000.root",
    const string &outdir = ".",
    const string &cdbtag = "MDC2")

{
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);  // set it to 1 if you want event printouts

  recoConsts *rc = recoConsts::instance();

  // Opt to print all random seed used for debugging reproducibility. Comment out to reduce stdout prints.
  PHRandomSeed::Verbosity(1);
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
  // the only reason that we are including the calo_cluster node is we want to use the CEMC geom node from it,
  // but we have calib node name confliting(it has a towerinfov1 calib node with the same name we want to usebut we want to make it v2) if we do that...
  // so I will call the cemc tower reco here just to have the geom node.
  // by doing this it also remove the dependncy for running the calo_cluster before this pass so we can process it independently from G4Hits ;) and all of our output node name is exactly same with real data
  CEMC_Cells();

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
  ca2->set_builder_type(CaloTowerDefs::kWaveformTowerSimv1);
  // 30 ADC SZS
  ca2->set_softwarezerosuppression(true, 30);
  se->registerSubsystem(ca2);

  ca2 = new CaloTowerBuilder();
  ca2->set_detector_type(CaloTowerDefs::HCALIN);
  ca2->set_nsamples(12);
  ca2->set_dataflag(false);
  ca2->set_processing_type(CaloWaveformProcessing::TEMPLATE);
  ca2->set_builder_type(CaloTowerDefs::kWaveformTowerSimv1);
  ca2->set_softwarezerosuppression(true, 30);
  se->registerSubsystem(ca2);

  ca2 = new CaloTowerBuilder();
  ca2->set_detector_type(CaloTowerDefs::CEMC);
  ca2->set_nsamples(12);
  ca2->set_dataflag(false);
  ca2->set_processing_type(CaloWaveformProcessing::TEMPLATE);
  ca2->set_builder_type(CaloTowerDefs::kWaveformTowerSimv1);
  // a large uniform ZS threshold for CEMC, 60 ADC now
  ca2->set_softwarezerosuppression(true, 60);
  se->registerSubsystem(ca2);

  Fun4AllInputManager *intrue2 = new Fun4AllRunNodeInputManager("DST_GEO");
  std::string geoLocation = CDBInterface::instance()->getUrl("calo_geo");
  intrue2->AddFile(geoLocation);
  se->registerInputManager(intrue2);

  /////////////////////////////////////////////////////
  // Set status of towers, Calibrate towers,  Cluster
  /////////////////////////////////////////////////////
  std::cout << "status setters" << std::endl;
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
  std::cout << "Calibrating EMCal" << std::endl;
  CaloTowerCalib *calibEMC = new CaloTowerCalib("CEMCCALIB");
  calibEMC->set_detector_type(CaloTowerDefs::CEMC);
  calibEMC->set_outputNodePrefix("TOWERINFO_CALIB_");
  se->registerSubsystem(calibEMC);

  std::cout << "Calibrating OHcal" << std::endl;
  CaloTowerCalib *calibOHCal = new CaloTowerCalib("HCALOUTCALIB");
  calibOHCal->set_detector_type(CaloTowerDefs::HCALOUT);
  calibOHCal->set_outputNodePrefix("TOWERINFO_CALIB_");
  se->registerSubsystem(calibOHCal);

  std::cout << "Calibrating IHcal" << std::endl;
  CaloTowerCalib *calibIHCal = new CaloTowerCalib("HCALINCALIB");
  calibIHCal->set_detector_type(CaloTowerDefs::HCALIN);
  calibIHCal->set_outputNodePrefix("TOWERINFO_CALIB_");
  se->registerSubsystem(calibIHCal);

  ////////////////
  // MC Calibration
  std::string MC_Calib = CDBInterface::instance()->getUrl("CEMC_MC_RECALIB");
  if (MC_Calib.empty())
  {
    std::cout << "No MC calibration found :( )" << std::endl;
    gSystem->Exit(0);
  }
  CaloTowerCalib *calibEMC_MC = new CaloTowerCalib("CEMCCALIB_MC");
  calibEMC_MC->set_detector_type(CaloTowerDefs::CEMC);
  calibEMC_MC->set_inputNodePrefix("TOWERINFO_CALIB_");
  calibEMC_MC->set_outputNodePrefix("TOWERINFO_CALIB_");
  calibEMC_MC->set_directURL(MC_Calib);
  calibEMC_MC->set_doZScrosscalib(false);

  //////////////////
  // Clusters
  std::cout << "Building clusters" << std::endl;
  RawClusterBuilderTemplate *ClusterBuilder = new RawClusterBuilderTemplate("EmcRawClusterBuilderTemplate");
  ClusterBuilder->Detector("CEMC");
  ClusterBuilder->set_threshold_energy(0.070);  // for when using basic calibration
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
  TRandom3 randGen;
  // get seed
  unsigned int seed = PHRandomSeed();
  randGen.SetSeed(seed);
  // a int from 0 to 3259
  int sequence = randGen.Integer(3260);
  // pad the name
  std::ostringstream opedname;
  opedname << "pedestal-54256-0" << std::setw(4) << std::setfill('0') << sequence << ".root";

  std::string pedestalname = opedname.str();

  Fun4AllInputManager *hitsin = new Fun4AllNoSyncDstInputManager("DST2");
  hitsin->AddFile(pedestalname);
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
    // this is what production macto gives us
    out->AddNode("CLUSTERINFO_HCALIN");
    out->AddNode("TOWERINFO_CALIB_HCALIN");
    out->AddNode("WAVEFORM_HCALIN");
    out->AddNode("TOWERS_HCALIN");

    // Outer Hcal
    out->AddNode("CLUSTERINFO_HCALOUT");
    out->AddNode("TOWERINFO_CALIB_HCALOUT");
    out->AddNode("WAVEFORM_HCALOUT");
    out->AddNode("TOWERS_HCALOUT");

    // CEmc
    out->AddNode("CLUSTERINFO_CEMC");
    out->AddNode("CLUSTER_POS_COR_CEMC");
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
}

#endif  // MACRO_FUN4ALLG4CALO_C
