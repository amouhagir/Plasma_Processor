#include "MIPSExecuableCode.h"

# include  <stdio.h>  
# include  <stdlib.h>     

MIPSExecuableCode::MIPSExecuableCode( char *filename  ){
	FILE *infile   = fopen(filename, "rb");
	if(infile == NULL)
	{
		printf("Can't open : %s\n", filename);
		exit (EXIT_SUCCESS); 
	}

		// ON CREE LE TABLEAU TEMPORAIRE UTILISE POUR LA LECTURE DU PROGRAMME
	uint8 *buf = new unsigned char[BUF_SIZE];
	int size   = (int)fread(buf, 1, BUF_SIZE, infile);
	fclose(infile);

	_nb_data  = 0;
	int rSize = (size-1)/4;
	uint32 *p = (uint32*)buf;
	p++;     // ON SAUTE LE HEADER DE L'UART

	// ON ALLOUE L'ESPACE MEMOIRE NECESSAIRE AU PROGRAMME
	prog = new unsigned int[BUF_SIZE];

	prog[_nb_data++] = 0xFF00EE11;
	prog[_nb_data++] = (*p)/4;
	p++;			// ON TRANSMET LA TAILLE DU PROGRAMME
	rSize--;		// ON DECOMPTE UNE DATA
	prog[_nb_data++] = 0xFF00EE11;

// OPTIMIZATION	int sum  = 0;
	while( rSize-- )
	{
// OPTIMIZATION		int q = ((*p) << 24) & 0xFF000000;
// OPTIMIZATION		q    |= ((*p) <<  8) & 0x00FF00FF;
// OPTIMIZATION		q    |= ((*p) >>  8) & 0x0000FF00;
// OPTIMIZATION		q    |= ((*p) >> 24) & 0x000000FF;
// OPTIMIZATION		prog[_nb_data++] = q;
		prog[_nb_data++] = __bswap_32 ( *p );
// OPTIMIZATION		sum += (q);
		p += 1;
	}
	free( buf );
}

MIPSExecuableCode::~MIPSExecuableCode(){
	free( prog );
}

int MIPSExecuableCode::nb_data(){
	return _nb_data;
}

int* MIPSExecuableCode::pointer(){
	return (int*)prog;
}
