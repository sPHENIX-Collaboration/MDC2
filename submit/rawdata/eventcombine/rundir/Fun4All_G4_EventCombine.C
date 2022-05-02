#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllInputManager.h>
#include <fun4allraw/Fun4AllPrdfInputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4allraw/Fun4AllEventOutputManager.h>
#include <ffarawmodules/EventCombiner.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libfun4allraw.so)
R__LOAD_LIBRARY(libffarawmodules.so)

void Fun4All_G4_EventCombine(int nEvents = 10, const int irun = 10349, const int sequence = 0, const std::string &topdir = "/sphenix/lustre01/sphnxpro/mdc2/rawdata")
{
  Fun4AllServer *se = Fun4AllServer::instance();
  Fun4AllInputManager *in = nullptr;
  int n = 0;
  EventCombiner *evtcomb = new EventCombiner();
  evtcomb->Verbosity(1);
  for (int i=0; i<8; i++)
  {
    for (int j = 0; j < 3; j++)
    {

      string ebdcfilename = topdir + "/section" + to_string(j) + "/section" + to_string(j) + "_ebdc0" + to_string(i) + "_data-000" + to_string(irun) + "-0000.evt";
      string ebdc = "section" + to_string(j) + "ebdc0" + to_string(i);
      cout << "file: " << ebdcfilename << endl;
      string prdfnode = "PRDF" + to_string(n);
      in = new Fun4AllPrdfInputManager(ebdc,prdfnode);
      in->fileopen(ebdcfilename);
      //in->Verbosity(4);
      evtcomb->AddPrdfInputNodeFromManager(in);
      se->registerInputManager(in);
      n++;
      if (i == 4)
      {
	continue;
      }
      string seb = "section" + to_string(j) + "seb0" + to_string(i);
      string sebfilename = topdir + "/section" + to_string(j) + "/section" + to_string(j) + "_seb0" + to_string(i) + "_data-000" + to_string(irun) + "-0000.evt";
      prdfnode = "PRDF" + to_string(n);
      in = new Fun4AllPrdfInputManager(seb,prdfnode);
      in->fileopen(sebfilename);
      //in->Verbosity(4);
      evtcomb->AddPrdfInputNodeFromManager(in);
      se->registerInputManager(in);
      n++;
    }
  }
  se->registerSubsystem(evtcomb);
//  Fun4AllEventOutputManager *out = new Fun4AllEventOutputManager("EvtOut","out-%08d-%04d.prdf",20000);
//  out->DropPacket(21102);
//  se->registerOutputManager(out);

  se->run(nEvents);

  se->End();
  delete se;
  gSystem->Exit(0);
}
