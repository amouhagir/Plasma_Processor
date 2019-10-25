#include "../../shared/plasmaSoPCDesign.h"
#include "../../shared/plasma.h"

#define MemoryRead(A)     (*(volatile unsigned int*)(A))
#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)

void sleep( unsigned int ms ) // fonction qui impose un delay en millisecondes 
{	// la fréquence d'horloge vaut 50 MHz
	unsigned int t0 = MemoryRead( TIMER_ADR  );
	while ( MemoryRead( TIMER_ADR  ) - t0 < 50000*ms ) // On compte 50000 périodes pour 1 ms
		;
}

int main(int argc, char ** argv) {
	MemoryWrite(SEVEN_SEGMENT_RST, 1); // reset the 7 segment controler
	MemoryWrite(CTRL_SL_RST, 1); // reset the sw/led controler

	puts("Test des afficheurs sept segments :\n");

	unsigned int i, sw;

	for (i = 0; i < 32; i++)
	{
		MemoryWrite(SEVEN_SEGMENT_REG, i << 16 | i);
		puts("going :\n");
		sleep(250); // 250ms
	}

	puts("Utilisez les switchs pour definir la valeur à écrire sur les afficheurs.\n");

	while(1) {
		sw = MemoryRead(CTRL_SL_RW); // lecture sur les switch (16 bits de donnée)
		MemoryWrite(SEVEN_SEGMENT_REG, sw << 16 | sw); // répétition de sw sur les 16 bits de poid fort
		sleep(250); // 250ms
	}

}
