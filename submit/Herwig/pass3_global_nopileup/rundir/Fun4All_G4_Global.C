#include <GlobalVariables.C>

#include <G4_Global.C>
#include <G4_Production.C>
#include <SaveGitTags.C>

#include <ffamodules/CDBInterface.h>
#include <ffamodules/FlagHandler.h>

#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllUtils.h>
#include <fun4all/SubsysReco.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4all.so)

//________________________________________________________________________________________________
int Fun4All_G4_Global(
    const int nEvents = 0,
    const std::string &inputFile = "DST_MBD_EPD_Herwig_Jet30-0000000011-00001.root",
    const std::string &outputFile = "DST_GLOBAL_Herwig_Jet30-0000000011-00001.root",
    const std::string &outdir = ".",
    const string &cdbtag = "MDC2",
    const std::string &gitcommit = "none")
{
  gSystem->Load("libg4dst.so");
  recoConsts *rc = recoConsts::instance();
// save all git tags from build
  SaveGitTags();
  rc->set_StringFlag("MDC2_GITID", gitcommit);
  //===============
  // conditions DB flags
  //===============
  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(outputFile);
  int runnumber = runseg.first;
  Enable::CDB = true;
  // tag
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP", runnumber);
  CDBInterface::instance()->Verbosity(1);

  // set up production relatedstuff
  Enable::PRODUCTION = true;
  Enable::DSTOUT = true;
  DstOut::OutputDir = outdir;
  DstOut::OutputFile = outputFile;

  // central tracking
  Enable::GLOBAL_RECO = true;

  // server
  auto se = Fun4AllServer::instance();
  se->Verbosity(1);

  // make sure to printout random seeds for reproducibility
  PHRandomSeed::Verbosity(1);

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  Global_Reco();

  // input manager
  auto in = new Fun4AllDstInputManager("DSTin2");
  in->fileopen(inputFile);
  se->registerInputManager(in);

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }
  // output manager
  auto out = new Fun4AllDstOutputManager("DSTOUT", outputFile);
  out->AddNode("Sync");
  out->AddNode("EventHeader");
  out->AddNode("MbdPmtContainer");
  out->AddNode("TOWERINFO_SIM_EPD");
  out->AddNode("TOWERINFO_CALIB_EPD");
  out->AddNode("GlobalVertexMap");
  se->registerOutputManager(out);

  // process events
  se->run(nEvents);

  // terminate
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
