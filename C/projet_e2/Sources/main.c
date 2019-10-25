#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <time.h>
#include <math.h>

#include "../../shared/plasmaCoprocessors.h"
#include "../../shared/plasmaIsaCustom.h"
#include "../../shared/plasmaMisc.h"
#include "../../shared/plasmaSoPCDesign.h"
#include "../../shared/plasmaMyPrint.h"
#include "../../shared/plasma.h"


#define RIGHT_BUTTON  0x00000010
#define LEFT_BUTTON   0x00000008
#define DOWN_BUTTON   0x00000004
#define UP_BUTTON     0x00000002
#define CENTER_BUTTON 0x00000001

#define LONGUEUR 38422

#define H 63
#define W 96

#define MemoryRead(A)     (*(volatile unsigned int*)(A))
#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)



unsigned char wait_data()
{
	while( !(MemoryRead(IRQ_STATUS) & IRQ_UART_READ_AVAILABLE) );
	unsigned char cc =MemoryRead(UART_READ);
	return cc;
}

void sleep( unsigned int ms ) // fonction qui impose un delay en millisecondes 
{	// la fréquence d'horloge vaut 50 MHz
	unsigned int t0 = MemoryRead( TIMER_ADR  );
	while ( MemoryRead( TIMER_ADR  ) - t0 < 50000*ms ) // On compte 50000 périodes pour 1 ms
		;
}

int bufferLength(const char* buffer)
{
    int lenght = 0;
    char caracterPointed = 0;

    do
    {
        caracterPointed = buffer[lenght];
        lenght++;
    }
    while(caracterPointed != '\0');

    lenght--; // -1 because of \0

    return lenght;
}


void rgb_oled_terminal(void)
{
	char buffer[7] =  "SALAM!";                  
	int i;

	MemoryWrite(OLED_MUX, OLED_MUX_TERMINAL);
	MemoryWrite(OLED_TERMINAL_RST, 1); // reset the oled_rgb

	// Screen Clear (Black Background by defaulf)
	while(!MemoryRead(OLED_TERMINAL_RW)) {}
		MemoryWrite(OLED_TERMINAL_RW, 0x01000000);

	for (i = 0; i < bufferLength(buffer); i++) {
		while(!MemoryRead(OLED_TERMINAL_RW)) {}
	   		MemoryWrite(OLED_TERMINAL_RW, buffer[i]);
	}
}

void printPixel(char row, char col, int color)
{
	int buff = 0x00000000;

	buff = color;
	buff = (buff << 8) | row;
	buff = (buff << 8) | col;

	MemoryWrite(OLED_BITMAP_RW, buff);
}

//int8_t c[LONGUEUR];
char buffer[15]="SALAM!";
int main(int argc, char ** argv)
{

    int volume=1;
    
    int state;

    //int vol=0;
    int cmpt=0;
    int etat=10; //10=A(hexa) pour Arret/Init
    int8_t val;
    int seven_val,cmpt_uni,cmpt_diz,cmpt_cent=0;
    
    MemoryWrite(CTRL_PWM_RST, 1); //Reset the PWM
    MemoryWrite(SEVEN_SEGMENT_RST, 1); //Reset the 7_segment controller

	puts("Please send your music from MATLAB !\n");
    for (int i = 0; i < LONGUEUR; ++i)
    {
    	val= wait_data();
    	MemoryWrite(CTRL_PWM_RW, val);
    }

    puts("Music uploded! Enjoy it :) \n");

    MemoryWrite(CTRL_RW, 1);

    
    while(1){

	    int buttons = MemoryRead(BUTTONS_VALUES);
    //Machine d'états
	    switch(etat)
	    {
	    	case(10): //Arret
	    		if (buttons==CENTER_BUTTON)
	    		{
	    			etat=15;	
	    		}
	    		cmpt=0;	

	    	break;

	    	case(15): //Forward
	    		
	    		if (buttons==CENTER_BUTTON)
	    		{
	    			etat=12;	
	    		}

	    		if (cmpt<599)
	    		{
	    			cmpt++;
	    		}else{
	    			cmpt=0;
	    		}
	    		
	    	break;
	    	
	    	case(11): //Backward
	    		if (buttons==CENTER_BUTTON)
	    		{
	    			etat=12;	
	    		}	    	

	    		if (cmpt>0)
	    		{
	    			cmpt--;
	    		}else{
	    			cmpt=599;
	    		}
	    	break;

	    	case(12): //PAUSE
	    		if (buttons==RIGHT_BUTTON)
	    		{
	    			etat=15;	
	    		}
	 			if (buttons==LEFT_BUTTON)
	    		{
	    				etat=11;
	    		}
	 			if (buttons==CENTER_BUTTON)
	    		{
	    				etat=10;
	    		}	 	

	    	break;
	    		    		
	    }
		
		switch(buttons)
		{
			case(UP_BUTTON):
				if(volume < 7){volume++;}

			break;
			case(DOWN_BUTTON):
				if(volume > 1){volume--;}

			break;
		}

	    cmpt_uni= cmpt%10;
		cmpt_diz= (cmpt/10)%10;
		cmpt_cent= cmpt/100;	 
		seven_val= (etat << 16)| (cmpt_cent << 12) | (cmpt_diz << 8) |(cmpt_uni << 4) | volume;
		MemoryWrite(SEVEN_SEGMENT_REG, seven_val); 

		state = etat << 4 | volume;
		MemoryWrite(CTRL_ETAT, state);
		sleep(100); 
	 	
	}	
}
