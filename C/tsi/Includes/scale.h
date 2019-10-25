#ifndef __SCALE_H__
#define __SCALE_H__

#include "../../shared/plasmaCoprocessors.h"

void scale_no_opt(unsigned char* data, int pixel_nb){
	int i;
	unsigned char min, max;
	unsigned short beta;
	max = 0;
	min = 255;

	// Calcul MIN/MAX
	for(i=0;i<pixel_nb;i++){
		if(data[i] > max) max = data[i];
		if(data[i] < min) min = data[i];
	}

	// Calcul du Beta
	beta = 255 << 8; // 255 au format U(8,8)
	beta = beta / (max-min); // U(8,8)/U(8,0) => U(8,8) 
	
	// Mise à l'echelle
	for(i=0;i<pixel_nb;i++){
		data[i] = (beta * (data[i] - min)) >> 8;
	}	
}

void scale_opt1(unsigned char* data, int pixel_nb){
	int i;
	unsigned char min, max;
	unsigned short beta;
	unsigned int beta_mini;
	max = 0;
	min = 255;
	
	// Calcul MIN/MAX avec instructions custom pour le calcul du min et max
	for(i=0;i<pixel_nb;i++){
		max = isa_custom_1(data[i],max);
		min = isa_custom_2(data[i],min);
	}

	// Calcul du Beta
	beta = 255 << 8; // 255 au format (8,8)
	beta = beta / (max-min); // (8,8)/(8,0) => (8,8) 
	
	// concatenation de beta et min dans un unsigned int
	beta_mini = beta << 16 | min;
	
	 // Mise à l'echelle
	for(i=0;i<pixel_nb;i++){
		data[i] = isa_custom_3(data[i], beta_mini);
	}
}

void scale_opt2(unsigned char* data, int pixel_nb){
	int i;
	unsigned char min, max;
	unsigned short beta;
	unsigned int beta_mini;
	
  // packing min and max into a single int
	max = 0;
	min = 255;
	unsigned int min_max;
	min_max = min << 8 | max;
	
	// pointer casting: p points to blocks of 4 bytes (= int)
	int* p = (int*)data;
	
	for(i=0;i<pixel_nb;i+=4){
		// packing 4 bytes into a single int
		// update the min and max value using a single instruction
		// SIMD with P=4 bytes processed in parallel
		min_max = isa_custom_4(*p, min_max);	
		p += 1;
	}
	
   // retrieves min and max from the output of the instruction
	min = min_max >> 8;
	max = min_max & 0x000000FF;
	
	// Calcul du Beta
	beta = 255 << 8; // 255 au format (8,8)
	beta = beta / (max-min); // (8,8)/(8,0) => (8,8) 
	
	// Mise à l'echelle
	// packing beta et mini dans une seule variable
	beta_mini = beta << 16 | min;
	
	p = (int*)data;
	
	for(i=0;i<pixel_nb/4;i++){
		*p = isa_custom_5(*p, beta_mini);
		p +=1;
	}
}

void scale_opt3(unsigned char* data, int pixel_nb){
	
  // Calcul MIN/MAX
	int i;
	unsigned char min, max;
	unsigned short beta;
	unsigned int beta_mini;
	unsigned int min_max;
	
	// pointer casting: p points to blocks of 4 bytes (= int)
	int* p;
	p = (int*)data;
	
	coproc_reset(COPROC_1_RST);
	for(i=0;i<pixel_nb;i+=4){
		// push 4 bytes in the COPROC_1
		coproc_write(COPROC_1_RW, *p);
		p += 1;
	}  

   // On recupere le min et le max
	min_max = coproc_read(COPROC_1_RW);
	


/*int i;
	unsigned char min, max;
	unsigned short beta;
	unsigned int beta_mini;
	
  // packing min and max into a single int
	max = 0;
	min = 255;
	unsigned int min_max;
	min_max = min << 8 | max;
	
	// pointer casting: p points to blocks of 4 bytes (= int)
	int* p = (int*)data;
	
	for(i=0;i<pixel_nb;i+=4){
		// packing 4 bytes into a single int
		// update the min and max value using a single instruction
		// SIMD with P=4 bytes processed in parallel
		min_max = isa_custom_4(*p, min_max);	
		p += 1;
	}*/



	/*min = min_max >> 8;
	max = min_max & 0x000000FF;

	my_printf("min:",min);
	my_printf("max:",max);

	// Calcul du Beta
	beta = 255 << 8; // 255 au format (8,8)
	beta = beta / (max-min); // (8,8)/(8,0) => (8,8) 
	
	// Mise à l'echelle
	// packing beta et mini dans une seule variable
	beta_mini = beta << 16 | min;
	
	p = (int*)data;
	
	for(i=0;i<pixel_nb/4;i++){
		*p = isa_custom_5(*p, beta_mini);
		p +=1;
	}*/



	// on repositionne le pointeur au debut du tableau de donnees
	p = (int*)data;
	
	coproc_reset(COPROC_2_RST);
	// on envoie le minmax au coproc pour qu'il calcule le beta et le stocke ainsi que le min
	coproc_write(COPROC_2_RW, min_max);
	
	for(i=0;i<pixel_nb;i+=4){
		// push 4 bytes in the COPROC_2
		coproc_write(COPROC_2_RW, *p);
		// pull and store the result
		*p = coproc_read(COPROC_2_RW);
		// move to the next data in the array
		p += 1;
	}
}

#endif