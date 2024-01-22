#ifndef MACRO_FUN4ALLG4SPHENIX_C
#define MACRO_FUN4ALLG4SPHENIX_C

#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllInputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>

R__LOAD_LIBRARY(libfun4all.so)

void Fun4All_G4_StripTruth(
    const int nEvents = 1,
    const string &inputFile =
        "DST_TRKR_G4HIT_sHijing_0_20fm_50kHz_bkg_0_20fm-0000000002-00003.root",
    const string &outputFile = "G4sPHENIX.root")
{
  gSystem->Load("libg4dst.so");
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);
  Fun4AllInputManager *in = new Fun4AllDstInputManager("DSTin");
  in->fileopen(inputFile);
  se->registerInputManager(in);
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("DSTout", outputFile);
  out->StripNode("TRKR_HITTRUTHASSOC");
  out->StripRunNode("CYLINDERCELLGEOM_SVTX");
  out->StripRunNode("CYLINDERGEOM_MICROMEGAS_FULL");
  out->StripRunNode("DEADMAP_INTT");
  out->StripRunNode("G4CELLPARAM_INTT");
  out->StripRunNode("G4CELLPARAM_TPC");
  out->StripRunNode("G4TPCPADPLANE");
  se->registerOutputManager(out);
  se->run(nEvents);
  se->End();
  delete se;
  gSystem->Exit(0);
}

#endif
