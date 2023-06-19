#include <GlobalVariables.C>

#include <g4calo/g4hitshift.h>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/CDBInterface.h>

#include <fun4all/SubsysReco.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllInputManager.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllRunNodeInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>

#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libg4calo.so)

void Fun4All_G4_FixCemcGeo(
  const int nEvents = 0,
  const string &g4hitfile = "G4HitsOld_sHijing_0_20fm-0000000006-00000.root",
  const string &outfilename = "G4Hits_sHijing_0_20fm-0000000006-00000.root",
  const string &outdir = "."
  )
{

  gSystem->Load("libg4dst.so");
  const string &filefixedgeo = "updated_geo.root",

  Fun4AllServer *se = Fun4AllServer::instance();

  se->Verbosity(1);
  recoConsts *rc = recoConsts::instance();

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  // tag
  rc->set_StringFlag("CDB_GLOBALTAG",CDB::global_tag);
  rc->set_uint64Flag("TIMESTAMP",CDB::timestamp);

 
  // set up production relatedstuff
  Enable::PRODUCTION = true;
  Enable::DSTOUT = true;
  DstOut::OutputDir = outdir;
  DstOut::OutputFile = outputFile;

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  g4hitshift *hitshift = new g4hitshift();
  se->registerSubsystem(hitshift); 
  
  Fun4AllInputManager *intrue = new Fun4AllDstInputManager("G4HITIN");
  intrue->AddFile(g4hitfile);
  se->registerInputManager(intrue);

  Fun4AllRunNodeInputManager *intrue2 = new Fun4AllRunNodeInputManager("CEMCGEO");
  intrue2->AddFile(filefixedgeo);
  se->registerInputManager(intrue2);

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }


  Fun4AllDstOutputManager *out = new Fun4AllDstOutputManager("DSTOUT", outfilename);
  se->registerOutputManager(out);

  se->run(nEvents);
  // terminate
  CDBInterface::instance()->Print();

  se->End();
  se->PrintTimer();
  cout << "all done" << endl;
  delete se;
  if (Enable::PRODUCTION)
  {
    Production_MoveOutput();
  }
  gSystem->Exit(0);
  return 0;

}
