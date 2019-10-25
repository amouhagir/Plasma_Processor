//convert.c by Steve Rhoads 4/26/01
//Now uses the ELF format (get gccmips_elf.zip)
//set $gp and zero .sbss and .bss
//Reads test.axf and creates code.txt
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef __APPLE__
	#include <byteswap.h>
#else
	#include <machine/byte_order.h>
	#define __bswap_32(a) OSSwapInt32(a)
#endif

#define BUF_SIZE (128*1024)

typedef unsigned int   uint32;
typedef unsigned short uint16;
typedef unsigned char  uint8;

class MIPSExecuableCode{
private:
	uint32 *prog;
	uint32 _nb_data;

public:
	MIPSExecuableCode( char *filename  );
	~MIPSExecuableCode();

	int  nb_data();
	int* pointer();
};

/*
class ASIP_CONFIGURATION{
	
void ConfigureLdpcProcessorOnBoard(string filename, int BETA_FIXE, int DECISION_MODE)
{
	//
	// ON TRANSFERT LES INFORMATIONS DE CONFIGURATION AU DECODEUR
	//
	cout << "(II) ConfigureLdpcProcessorOnBoard( )" << endl;
	cout << "(DD) - Openning PCI Express driver" << endl;
	PCIE_OPEN();
	cout << "(DD) - Sending configuration information" << endl;

	string line;
  	ifstream myfile( filename.c_str() ); // ("pcie_full_configuration.txt");

  	if ( !myfile.is_open() )
  	{
		cout << "Unable to open file"; 
		exit(0);
	}


  	int numLine = 0;
	PCIE_WRITE_DATA( BETA_FIXE     );
	PCIE_WRITE_DATA( DECISION_MODE );
  	
   	while ( myfile.good() )
   	{
   		getline (myfile,line);
   		numLine += 1;
		if( line.length() != 32 ){
			cout << "(WW) skipping line num=" << numLine << "[" << line << "]" << endl;
			continue;
		}
   		int value = ConvertToInteger(&line);
   		PCIE_WRITE_DATA( value );
   	}
   	myfile.close();

	PCIE_WRITE_DATA( 0xFF11EE22 );
	cout << "(II) Finished (" << numLine << " lignes)..." << endl;
}

};
*/




