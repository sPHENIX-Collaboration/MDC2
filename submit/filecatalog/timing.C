#include <fstream>

void fittime(const std::string &module = "PHSimpleKFProp");
string indir;
string histofile;

void plottracks()
{
  indir = "/sphenix/user/zpinkenburg/Tracking2";
  histofile = "tracks.root";
  vector<string> mod; 
mod.push_back("CDBInterface");
mod.push_back("FlagHandler");
mod.push_back("MakeActsGeometry");
mod.push_back("PHActsSiliconSeeding");
mod.push_back("PHCASeeding");
mod.push_back("PHMicromegasTpcTrackMatching");
mod.push_back("PHSiliconSeedMerger");
mod.push_back("PHSiliconTpcTrackMatching");
mod.push_back("PHSimpleKFProp");
  for (int i=0; i<mod.size(); i++)
  {
    cout << "calling " << mod[i] << endl; 
    fittime(mod[i]);
  }
}

void plotglobal()
{
  indir = "/sphenix/user/zpinkenburg/Global";
  histofile = "global.root";
  vector<string> mod; 
mod.push_back("BbcDigitization");
mod.push_back("BbcReconstruction");
mod.push_back("EPDTileBuilder");
mod.push_back("FlagHandler");
  for (int i=0; i<mod.size(); i++)
  {
    cout << "calling " << mod[i] << endl; 
    fittime(mod[i]);
  }
}

void plotcal()
{
  indir = "/sphenix/user/zpinkenburg/Calorimeter_new";
  histofile = "calos.root";
  vector<string> mod; 
mod.push_back("CDBInterface");
mod.push_back("CEMCCYLCELLRECO");
mod.push_back("EmcRawClusterBuilderTemplate");
mod.push_back("EmcRawTowerBuilder");
mod.push_back("EmcRawTowerCalibration");
mod.push_back("EmcRawTowerDigitizer");
mod.push_back("FlagHandler");
mod.push_back("HCALIN_CELLRECO");
mod.push_back("HCALOUT_CELLRECO");
mod.push_back("HcalInRawClusterBuilderTemplate");
mod.push_back("HcalInRawTowerBuilder");
mod.push_back("HcalInRawTowerCalibration");
mod.push_back("HcalInRawTowerDigitizer");
mod.push_back("HcalOutRawClusterBuilderTemplate");
mod.push_back("HcalOutRawTowerBuilder");
mod.push_back("HcalOutRawTowerCalibration");
mod.push_back("HcalOutRawTowerDigitizer");
mod.push_back("RawClusterPositionCorrection_CEMC");
  for (int i=0; i<mod.size(); i++)
  {
    cout << "calling " << mod[i] << endl; 
    fittime(mod[i]);
  }
}

void fittime(const std::string &module = "PHSimpleKFProp")
{ 
  string fname = indir + "/" + module + ".timing";
  gStyle->SetOptFit();
  float memoryuse;
  float maxmem = 0;
  vector<float> fmem;
  std::ifstream indata;
  indata.open(fname.c_str());
  if (! indata)
  {
    cout << "could not open " << fname << endl;
    return;
  }
  indata >> memoryuse;
  while (! indata.eof())
  {
    float tmp =  memoryuse;
    if (tmp > maxmem)
    {
      maxmem = tmp;
    }
    //    if (tmp > 50)
    {
      fmem.push_back(tmp);
    }
    indata >> memoryuse;
  }
  TFile *f = TFile::Open(histofile.c_str(),"UPDATE");

  TH1 *h1 = new TH1F(module.c_str(),"",300,0.,maxmem+maxmem/10.);
  for (auto iter = fmem.begin(); iter != fmem.end(); ++iter)
  {
    //std::cout << "filling with " << *iter << std::endl;
    h1->Fill(*iter);
  }
  Double_t mean = h1->GetMean();
  Double_t sd = h1->GetStdDev();
  delete h1;
  h1 = new TH1F(module.c_str(),"",300,0.,mean+5*sd);
  for (auto iter = fmem.begin(); iter != fmem.end(); ++iter)
  {
    //std::cout << "filling with " << *iter << std::endl;
    h1->Fill(*iter);
  }
  

  h1->Fit("gaus");
  h1->SetTitle(module.c_str());
  //  h1->CenterTitle(true);
  h1->GetXaxis()->SetTitle("Time (ms)");
  h1->GetXaxis()->CenterTitle(true);
  h1->GetYaxis()->SetTitle("Count");
  h1->GetYaxis()->CenterTitle(true);
//  h1->Draw();

  f->WriteObject(h1,module.c_str());
  f->Close();
}
