// these include guards are not really needed, but if we ever include this
// file somewhere they would be missed and we will have to refurbish all macros
#ifndef MACRO_FUN4ALLJETS_C
#define MACRO_FUN4ALLJETS_C

#include <GlobalVariables.C>

#include <G4_HIJetReco.C>
#include <G4_Jets.C>
#include <G4_Production.C>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/CDBInterface.h>

#include <fun4all/Fun4AllInputManager.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>

#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libfun4all.so)

void Fun4All_G4_Jets(
  const int nEvents = 10,
  const string &inputFile = "DST_TRUTH_pythia8_pp_mb-0000000006-00000.root",
  const string &outputFile = "DST_TRUTH_JETS_pythia8_pp_mb-0000000006-00000.root",
  const string &outdir = ".",
  const string &cdbtag = "MDC2_ana.427")
{
// this convenience library knows all our i/o objects so you don't
// have to figure out what is in each dst type 
  gSystem->Load("libg4dst.so");
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1); // set it to 1 if you want event printouts

  recoConsts *rc = recoConsts::instance();

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  rc->set_StringFlag("CDB_GLOBALTAG",cdbtag);
  rc->set_uint64Flag("TIMESTAMP",CDB::timestamp);

  Fun4AllInputManager *in = new Fun4AllDstInputManager("DSTTRUTH");
  in->fileopen(inputFile);
  se->registerInputManager(in);

// register the flag handling
  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  JetReco *truthjetreco = new JetReco("TRUTHJETRECO");
  TruthJetInput *tji = new TruthJetInput(Jet::PARTICLE);
  tji->add_embedding_flag(1);  // (1) for pythia simulations, (2) for pythia embedding into hijing
  truthjetreco->add_input(tji);
  truthjetreco->add_algo(new FastJetAlgo(Jet::ANTIKT, 0.2), "AntiKt_Truth_r02");
  truthjetreco->add_algo(new FastJetAlgo(Jet::ANTIKT, 0.3), "AntiKt_Truth_r03");
  truthjetreco->add_algo(new FastJetAlgo(Jet::ANTIKT, 0.4), "AntiKt_Truth_r04");
  truthjetreco->add_algo(new FastJetAlgo(Jet::ANTIKT, 0.5), "AntiKt_Truth_r05");
  truthjetreco->add_algo(new FastJetAlgo(Jet::ANTIKT, 0.6), "AntiKt_Truth_r06");
  truthjetreco->add_algo(new FastJetAlgo(Jet::ANTIKT, 0.7), "AntiKt_Truth_r07");
  truthjetreco->add_algo(new FastJetAlgo(Jet::ANTIKT, 0.8), "AntiKt_Truth_r08");
  truthjetreco->set_algo_node("ANTIKT");
  truthjetreco->set_input_node("TRUTH");
  truthjetreco->Verbosity(0);
  se->registerSubsystem(truthjetreco);
  // set up production relatedstuff
  Enable::PRODUCTION = true;

  //======================
  // Write the DST
  //======================
  Enable::DSTOUT = true;
  DstOut::OutputDir = outdir;
  DstOut::OutputFile = outputFile;

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
    out->AddNode("AntiKt_Truth_r02");
    out->AddNode("AntiKt_Truth_r03");
    out->AddNode("AntiKt_Truth_r04");
    out->AddNode("AntiKt_Truth_r05");
    out->AddNode("AntiKt_Truth_r06");
    out->AddNode("AntiKt_Truth_r07");
    out->AddNode("AntiKt_Truth_r08");

    se->registerOutputManager(out);
  }

  se->run(nEvents);

  // terminate
  CDBInterface::instance()->Print(); // print used DB files
  se->End();
  std::cout << "All done" << std::endl;
  delete se;
  if (Enable::PRODUCTION)
  {
    Production_MoveOutput();
  }
  gSystem->Exit(0);
}

#endif //MACRO_FUN4ALLJETS_C
