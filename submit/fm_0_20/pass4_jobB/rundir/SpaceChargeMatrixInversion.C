#include <tpccalib/TpcSpaceChargeMatrixInversion.h>

#include <cstdio>
#include <sstream>

R__LOAD_LIBRARY(libtpccalib.so)

//_______________________________________________
// get list of files matching selection
std::vector<std::string> list_files( const std::string& selection )
{
  std::vector<std::string> out;
  
  std::cout << "list_files - selection: " << selection << std::endl;
  if( selection.empty() ) return out;

  const std::string command = std::string("ls -1 ") + selection;
  auto tmp = popen( command.c_str(), "r" );
  char line[512];
  while( fgets( line, 512, tmp ) )
  {

    std::istringstream istr( line );
    std::string filename;
    istr >> filename;

    if( filename.empty() ) continue;
    if( access( filename.c_str(), R_OK ) ) continue;
    
    out.push_back( filename );
  }
  pclose( tmp );
  return out;
}

//_______________________________________________
TString SpaceChargeMatrixInversion()
{
 
  // input files  
  const TString tag = "_realistic_micromegas";
  TString subtag = "_acts_full_notpc_nodistortion";
  const TString inputFile = Form( "DST/CONDOR%s/dst_reco%s/TpcSpaceChargeMatrices_*.root", tag.Data(), subtag.Data() );

  // output file
  const TString outputFile = Form( "Rootfiles/Distortions_full%s_mm%s.root", tag.Data(), subtag.Data() );
  std::cout << "SpaceChargeMatrixInversion - outputFile: " << outputFile << std::endl;
  
  // perform matrix inversion
  TpcSpaceChargeMatrixInversion spaceChargeMatrixInversion;
  spaceChargeMatrixInversion.Verbosity(1);
  spaceChargeMatrixInversion.set_outputfile( outputFile.Data() );
  spaceChargeMatrixInversion.Verbosity(1);

  auto filenames = list_files( inputFile.Data() );
  std::cout << "SpaceChargeMatrixInversion - loaded " << filenames.size() << " files" << std::endl;

  for( const auto& file:filenames )
  { 
    // std::cout << "SpaceChargeMatrixInversion - adding: " << file << std::endl;
    spaceChargeMatrixInversion.add_from_file( file ); 
  }
  
  spaceChargeMatrixInversion.calculate_distortions();

  return outputFile;
  
}
