#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <time.h>

#include "../../shared/plasmaCoprocessors.h"
#include "../../shared/plasmaIsaCustom.h"
#include "../../shared/plasmaMisc.h"
#include "../../shared/plasmaSoPCDesign.h"
#include "../../shared/plasmaMyPrint.h"
#include "../../shared/plasma.h"

#include "../Includes/scale.h"

int send_char(int value)
{
   while((MemoryRead(IRQ_STATUS) & IRQ_UART_WRITE_AVAILABLE) == 0)
      ;
   MemoryWrite(UART_WRITE, value);
   return 0;
}

unsigned char wait_data()
{
	while( !(MemoryRead(IRQ_STATUS) & IRQ_UART_READ_AVAILABLE) );
	unsigned char cc = MemoryRead(UART_READ);
	return cc;
}

inline void printPixel(char row, char col, int color)
{
	int buff = 0x00000000;

	buff = color;
	buff = (buff << 8) | row;
	buff = (buff << 8) | col;

	MemoryWrite(OLED_BITMAP_RW, buff);
}

unsigned char image[63][96];
//unsigned char small_image[16] = {15, 16, 65, 124, 210, 64, 98, 14, 67, 81, 94, 165, 154, 64, 84, 34};

int main(int argc, char **argv) {

	int H = 63;
	int W = 96;
	int r, g, b, pixel;
	unsigned int start_c, stop_c;
	

	/**********/
	// Reset the RGB OLED screen and display a white screen
	/**********/

	MemoryWrite(OLED_MUX, OLED_MUX_BITMAP); // Select the RGB OLED Bitmap controler
	MemoryWrite(OLED_BITMAP_RST, 1); // Reset the oled_rgb PMOD
	MemoryWrite(SEVEN_SEGMENT_RST, 1); // reset the 7 segment controler
	MemoryWrite(CTRL_SL_RST, 1); // reset the sw/led controler

	
	for(int py = 0; py < H; py++)
	{
		for(int px = 0; px < W; px ++){
			
			printPixel(py, px, 0x0000); // clear the RGB OLED screen
		}
	}

	/**********/
	// Read values coming from the UART
	/**********/

	puts("Please, send image from Matlab !\n");

	int i = 0;
	for(int py = 0; py < H; py++)
	{
		for(int px = 0; px < W; px ++){
			r = wait_data();
			g = wait_data();
			b = wait_data();
			pixel = (r+g+b) / 3;

			image[py][px] = pixel;
			//pixel = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3);
			pixel = ((pixel >> 3) << 11) | ((pixel >> 2) << 5) | (pixel >> 3);
			printPixel(py, px, pixel);
		}
	}

	/**********/
	// Processing
	/**********/
	
	// Read the timer value before the processing starts
	start_c = r_timer();

	// processing the loaded image
	//scale_no_opt(image, H*W);
	//scale_opt1(image, H*W);
	//scale_opt2(image, H*W);
	scale_opt3(image, H*W);


	// Read the timer value after the processing is over
	stop_c = r_timer();
	MemoryWrite(SEVEN_SEGMENT_REG, (stop_c - start_c));

	/**********/
	// Display the resulting image
	/**********/

	MemoryWrite(OLED_BITMAP_RST, 1); // Reset the oled_rgb PMOD

	for(int py = 0; py < H; py++)
	{
		for(int px = 0; px < W; px ++){
			pixel = image[py][px];
			pixel = ((pixel >> 3) << 11) | ((pixel >> 2) << 5) | (pixel >> 3);
			printPixel(py, px, pixel);
			send_char(image[py][px]);
		}
	}

	/**********/
	// Affichage du nombre de cycles nécessaires au traitement
	/**********/
	
	//MemoryWrite(CTRL_SL_RW, (stop_c - start_c));
	
	return(0);
	
}