#include "../../shared/plasmaSoPCDesign.h"
#include "../../shared/plasma.h"
#include "../../shared/plasmaMyPrint.h"

#define MemoryRead(A)     (*(volatile unsigned int*)(A))
#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)

/*int main(int argc, char ** argv)
{
	int a = 40;
	int b = 24;
	int pgcd;

	int diff = 1;
	while(diff != 0)
	{
		diff = a - b;
		if(diff < 0)
			b = -diff;
		else
			a = diff;
	}
	pgcd = b;
}*/

/*int main(int argc, char ** argv)
{
	int a = 40;
	int b = 24;

	puts("Calcul du PGCD\n");

	my_printf("a = ", a);
	my_printf("b = ", b);

	int diff = 1;
	while(diff != 0)
	{
		diff = a - b;
		if(diff < 0)
			b = -diff;
		else
			a = diff;
	}

	my_printf("pgcd = ", b);
}*/


int main(int argc, char ** argv)
{
	int a = 40;
	int b = 24;

	MemoryWrite(CTRL_SL_RST, 1); // reset the sw/led controler

	int sw;

	puts("Calcul du PGCD\n");

	while(1)
	{
		puts("Choisissez a et b sur les switchs\n");
		while (MemoryRead(BUTTONS_CHANGE) == 0) {
			sw = MemoryRead(CTRL_SL_RW);
			a = (sw >> 8); // a = MSBs
			b = sw & 0x00FF; // b = LSBs
		}

		my_printf("a =", a);
		my_printf("b =", b);

		int diff = 1;
		while(diff != 0)
		{
			diff = a - b;
			if(diff < 0)
				b = -diff;
			else
				a = diff;
		}

		my_printf("pgcd = ", b);
	}

}
