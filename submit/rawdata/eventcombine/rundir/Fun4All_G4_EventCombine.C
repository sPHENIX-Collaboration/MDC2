#include <ffarawmodules/EventCombiner.h>
#include <fun4all/Fun4AllInputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4allraw/Fun4AllEventOutputManager.h>
#include <fun4allraw/Fun4AllPrdfInputManager.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libfun4allraw.so)
R__LOAD_LIBRARY(libffarawmodules.so)

void Fun4All_G4_EventCombine(int nEvents = 10, const int irun = 329, const int sequence = 1, const std::string &topdir = "/sphenix/lustre01/sphnxpro/mdc2/rawdata/stripe5", int nrepeat = 0)
{
  int nfiles = 0;
  Fun4AllServer *se = Fun4AllServer::instance();
  //  se->Verbosity(1); // produces enormous logs
  Fun4AllInputManager *in = nullptr;
  int n = 0;
  EventCombiner *evtcomb = new EventCombiner();
  evtcomb->Verbosity(1);
  for (int i = 0; i < 40; i++)
  {
    char ebdcfilename[200];
    sprintf(ebdcfilename,"%s/ebdc%02d_junk-%08d-%04d.evt",topdir.c_str(),i,irun,sequence);
    string ebdc = "ebdc" + to_string(i);
    string prdfnode = "PRDF" + to_string(n);
    FILE *f = fopen(ebdcfilename, "r");
    if (!f)
    {
//        cout << "file does not exist: " << ebdcfilename << endl;
      continue;
    }
    fclose(f);
    string listfilename = ebdc + ".list";
    std::ofstream out(listfilename);
    for (int i=0; i<=nrepeat; i++)
    {
      out << ebdcfilename << endl;
    }
    out.close();
    nfiles++;
    in = new Fun4AllPrdfInputManager(ebdc, prdfnode);
    in->AddListFile(listfilename);
    // in->Verbosity(4);
    evtcomb->AddPrdfInputNodeFromManager(in);
    se->registerInputManager(in);
    n++;
    char sebfilename[200];
    sprintf(sebfilename,"%s/seb%02d_junk-%08d-%04d.evt",topdir.c_str(),i,irun,sequence);
    string seb = "seb" + to_string(i);
    prdfnode = "PRDF" + to_string(n);
    f = fopen(sebfilename, "r");
    if (!f)
    {
//        cout << "file does not exist: " << sebfilename << endl;
      continue;
    }
    fclose(f);
    listfilename = seb + ".list";
    std::ofstream out2(listfilename);
    for (int i=0; i<=nrepeat; i++)
    {
      out2 << sebfilename << endl;
    }
    out2.close();
    cout << "opening file: " << sebfilename << endl;
    nfiles++;
    in = new Fun4AllPrdfInputManager(seb, prdfnode);
    in->AddListFile(listfilename);
    // in->Verbosity(4);
    evtcomb->AddPrdfInputNodeFromManager(in);
    se->registerInputManager(in);
    n++;
  }
  if (nfiles == 0)
  {
    cout << "no files for run " << irun << ", segment " << sequence << endl;
    gSystem->Exit(0);
  }
  se->registerSubsystem(evtcomb);
  //  Fun4AllEventOutputManager *out = new Fun4AllEventOutputManager("EvtOut","out-%08d-%04d.prdf",20000);
  //  out->DropPacket(21102);
  //  se->registerOutputManager(out);

  se->run(nEvents);

  se->End();
  delete se;
  cout << "all done" << endl;
  gSystem->Exit(0);
}
