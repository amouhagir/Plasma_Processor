#include "../../shared/plasmaSoPCDesign.h"
#include "../../shared/plasma.h"
#include "../../shared/plasmaCoprocessors.h"
#include "../../shared/plasmaMyPrint.h"

#define MemoryRead(A)     (*(volatile unsigned int*)(A))
#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)

void sleep( unsigned int ms ) // fonction qui impose un delay en millisecondes 
{	// la fréquence d'horloge vaut 50 MHz
	unsigned int t0 = MemoryRead( TIMER_ADR  );
	while ( MemoryRead( TIMER_ADR  ) - t0 < 50000*ms ) // On compte 50000 périodes pour 1 ms
		;
}

int main(int argc, char ** argv) {

	int sw, value;

	MemoryWrite(CTRL_SL_RST, 1); // reset the sw/led controler

	while (1) {
		sw = MemoryRead(CTRL_SL_RW); // read the state of the switches
		value =  (sw<<16) | sw ; // MSByte drives the 2 RBG Led (6 bit), LSByte drives the led
		my_printf("value = ", value); // display the value on the UART
		MemoryWrite(CTRL_SL_RW, value); // drive the LEDs with value

		sleep(100); // wait 100 ms
	}
}
