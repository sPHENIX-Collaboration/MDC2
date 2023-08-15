void eventhist(){
  auto c = new TCanvas("c","c", 800, 700);
TFile *f = TFile::Open("calos.root", "READ");
 TH1 *hist [16]{};
 
 gStyle->SetOptStat(1111);
 gStyle->SetStatW(0.4);                
 gStyle->SetStatH(0.3);  
 
 f->GetObject("CDBInterface",hist[0]);
 f->GetObject("CEMCCYLCELLRECO",hist[1]);
 f->GetObject("EmcRawClusterBuilderTemplate",hist[2]);
 f->GetObject("EmcRawTowerBuilder",hist[3]);
 f->GetObject("EmcRawTowerCalibration",hist[4]);
 f->GetObject("EmcRawTowerDigitizer",hist[5]);
 f->GetObject("FlagHandler",hist[6]);
 f->GetObject("HCALIN_CELLRECO",hist[7]);
 f->GetObject("HcalInRawClusterBuilderTemplate",hist[8]);
 f->GetObject("HcalInRawTowerBuilder",hist[9]);
 f->GetObject("HcalInRawTowerCalibration",hist[10]);
 f->GetObject("HcalInRawTowerDigitizer",hist[11]);
 f->GetObject("HCALOUT_CELLRECO",hist[12]);
 f->GetObject("HcalOutRawClusterBuilderTemplate",hist[13]);
 f->GetObject("HcalOutRawTowerBuilder",hist[14]);
 f->GetObject("HcalOutRawTowerCalibration",hist[15]);
 //f->GetObject("HcalOutRawTowerDigitizer",hist[16]);
 //f->GetObject("RawClusterPositionCorrection_CEMC",hist[17]);
 c->Divide(4, 4, 0.0001,0.01,0); 
 int n = 1;
 int q = 0;
 while (q < 16)
 {
   c->cd(n);
   if (hist[q] != nullptr)
     {
       //hist[q]->SetStats(0);
   hist[q]->Draw();
     }
   else
     {
       cout << "histogram " << q << " is null" << endl;
     }
   n++;
   q++;
 }
}
