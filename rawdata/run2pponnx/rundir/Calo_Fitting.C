#ifndef CALO_FITTING_H
#define CALO_FITTING_H

#include <caloreco/CaloTowerBuilder.h>
#include <caloreco/CaloWaveformProcessing.h>

#include <fun4all/Fun4AllServer.h>

R__LOAD_LIBRARY(libcalo_reco.so)

void Process_Calo_Fitting()
{
  Fun4AllServer *se = Fun4AllServer::instance();

//   CaloTowerDefs::BuilderType buildertype = CaloTowerDefs::kWaveformTowerv2;
   CaloTowerDefs::BuilderType buildertype = CaloTowerDefs::kPRDFTowerv4;

  /////////////////
  // build towers
  CaloTowerBuilder *caZDC = new CaloTowerBuilder("ZDCBUILDER");
  caZDC->set_detector_type(CaloTowerDefs::ZDC);
  caZDC->set_builder_type(buildertype);
  caZDC->set_processing_type(CaloWaveformProcessing::FAST);
  caZDC->set_nsamples(16);
  caZDC->set_offlineflag();
  se->registerSubsystem(caZDC);

  CaloTowerBuilder *ctbEMCal = new CaloTowerBuilder("EMCalBUILDER");
  ctbEMCal->set_detector_type(CaloTowerDefs::CEMC);
  ctbEMCal->set_processing_type(CaloWaveformProcessing::ONNX);
  CaloWaveformProcessing *onnxproc = ctbEMCal->get_WaveformProcessing();
  if (onnxproc)
  {
onnxproc->set_model_file("model_1.onnx");
onnxproc->set_onnx_factor(0,134.198);
    onnxproc->set_onnx_factor(1,1.731);
    onnxproc->set_onnx_factor(2,591.512);
    onnxproc->set_onnx_offset(0,116.752 );
    onnxproc->set_onnx_offset(1,6.035);
    onnxproc->set_onnx_offset(2,1588.896);
  }
  ctbEMCal->set_builder_type(buildertype);
  ctbEMCal->set_offlineflag(true);
  ctbEMCal->set_nsamples(12);
  ctbEMCal->set_bitFlipRecovery(true);
  //60 ADC SZS
  ctbEMCal->set_softwarezerosuppression(true, 60);
  se->registerSubsystem(ctbEMCal);

  CaloTowerBuilder *ctbIHCal = new CaloTowerBuilder("HCALINBUILDER");
  ctbIHCal->set_detector_type(CaloTowerDefs::HCALIN);
  ctbIHCal->set_processing_type(CaloWaveformProcessing::TEMPLATE);
  ctbIHCal->set_builder_type(buildertype);
  ctbIHCal->set_offlineflag();
  ctbIHCal->set_nsamples(12);
  ctbIHCal->set_bitFlipRecovery(true);
  //30 ADC SZS
  ctbIHCal->set_softwarezerosuppression(true, 30);
  se->registerSubsystem(ctbIHCal);

  CaloTowerBuilder *ctbOHCal = new CaloTowerBuilder("HCALOUTBUILDER");
  ctbOHCal->set_detector_type(CaloTowerDefs::HCALOUT);
  ctbOHCal->set_processing_type(CaloWaveformProcessing::TEMPLATE);
  ctbOHCal->set_builder_type(buildertype);
  ctbOHCal->set_offlineflag();
  ctbOHCal->set_nsamples(12);
  ctbOHCal->set_bitFlipRecovery(true);
  //30 ADC SZS
  ctbOHCal->set_softwarezerosuppression(true, 30);
  se->registerSubsystem(ctbOHCal);

  CaloTowerBuilder *caEPD = new CaloTowerBuilder("SEPDBUILDER");
  caEPD->set_detector_type(CaloTowerDefs::SEPD);
  caEPD->set_builder_type(buildertype);
  caEPD->set_processing_type(CaloWaveformProcessing::FAST);
  caEPD->set_nsamples(12);
  caEPD->set_offlineflag();
  se->registerSubsystem(caEPD);
}

#endif
