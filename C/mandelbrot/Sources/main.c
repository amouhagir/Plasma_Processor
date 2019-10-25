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

//#define COLOR

#define Nf 18
#define Nr 12

#define RIGHT_BUTTON  0x00000010
#define LEFT_BUTTON   0x00000008
#define DOWN_BUTTON   0x00000004
#define UP_BUTTON     0x00000002
#define CENTER_BUTTON 0x00000001

//#define OLED_RW       0x400000A4
//#define OLED_RST      0x400000A0

void printPixel(char row, char col, int color)
{
	int buff = 0x00000000;

	buff = color;
	buff = (buff << 8) | row;
	buff = (buff << 8) | col;

	MemoryWrite(OLED_BITMAP_RW, buff);
}

void printPixelVGA(char row, char col, int color)
{
	int buff = 0x00000000;

	buff = color;
	//buff = (buff << 8) | row;
	//buff = (buff << 8) | col;

	MemoryWrite(COPROC_4_RW, buff);
}


int Convergence(int x_C, int y_C, int Imax) {

	long long int x = 0;
	long long int y = 0;
	int x2 = (x*x) >> Nf;
	int y2 = (y*y) >> Nf;
	int iter = 0;
	int x_new;
	int quatre = 4<<Nf;

	while( ((x2 + y2) <= quatre) && ( iter < Imax) )
	{
		x_new = x2 - y2 + x_C;
		y = 2*((x*y)>>Nf) + y_C;
		x = x_new;
		x2 = (x*x)>>Nf;
		y2 = (y*y)>>Nf;
		iter++;
	}

	return iter;
}

int Convergence_opt(int x_C, int y_C, int Imax) {

	long long int x = 0;
	long long int y = 0;
	int x2 = (x * x) >> Nf;
	int y2 = (y * y) >> Nf;
	int iter = 0;
	int x_new;
	int quatre = 4 << Nf;
	int mod2 = x2 + y2;

	while( (mod2 <= quatre) && ( iter < Imax) )
	{
		x_new = isa_custom_7(x, y) + x_C;
		y = isa_custom_6(x,y) + y_C;
		x = x_new;
		mod2 = isa_custom_8(x,y);
		iter++;
	}

	return iter;
}



void generate_mandelbrot_VGA(int H, int W, int Imax, int FS, int x_A, int y_A, int x_B, int y_B)
{

	int x_C;
	int y_C;

	int dx = (x_B - x_A); // A(Ni+1,Nf)
	int dy = (y_B - y_A); // U(Ni+1,Nf)
	int dx64 = dx;
	int dy64 = dy;

	dx64 = ((dx64<<Nr) / W) >> Nr; // A(Ni+1,Nf+12)
	dy64 = ((dy64<<Nr) / H) >> Nr; // A(Ni+1,Nf+12)
	dx = dx64;
	dy = dy64;

	int buff, pixel, i;
	int sw = MemoryRead(CTRL_SL_RW);


	int * vga = (int *)0x50000000;

	for(int py = 0; py < H; py++)
	{
		for(int px = 0; px < W; px ++){
			vga[py*W+px] =  0x0F00; // red screen
		}
	}

	for(int py = 0; py < H; py++)
	{
		y_C = y_A + dy*py;
		for(int px = 0; px < W; px ++){
			x_C = x_A + dx*px;
			i = Convergence(x_C, y_C, Imax);
			pixel = i;
			vga[py*W+px] = pixel;
		}
	}
}

void generate_mandelbrot(int H, int W, int Imax, int FS, int x_A, int y_A, int x_B, int y_B)
{

	int x_C;
	int y_C;

	int dx = (x_B - x_A); // A(Ni+1,Nf)
	int dy = (y_B - y_A); // U(Ni+1,Nf)
	int dx64 = dx;
	int dy64 = dy;

	dx64 = ((dx64<<Nr) / W) >> Nr; // A(Ni+1,Nf+12)
	dy64 = ((dy64<<Nr) / H) >> Nr; // A(Ni+1,Nf+12)
	dx = dx64;
	dy = dy64;

	int buff, pixel, i;

	//coproc_reset(COPROC_1_RST);
	
	int sw = MemoryRead(CTRL_SL_RW);

	for(int py = 0; py < H; py++)
	{
		for(int px = 0; px < W; px ++){
			printPixel(py, px, 0x0F00); // red screen
		}
	}

	for(int py = 0; py < H; py++)
	{
		y_C = y_A + dy*py;

		for(int px = 0; px < W; px ++){

			x_C = x_A + dx*px;
			i = Convergence(x_C, y_C, Imax);

/*		if((sw&(1<<15)) != 0)
		{
			i = Convergence(x_C, y_C, Imax);
		}
		else if((sw&(1<<14)) != 0)
		{
			//i = Convergence_opt(x_C, y_C, Imax);
			i = Convergence(x_C, y_C, Imax);
		}
		else
		{
			//coproc_write(COPROC_1_RW, x_C);
			//coproc_write(COPROC_1_RW, y_C);	
			//int clk = r_timer();

			//while(r_timer() - clk < 300)
			//{
			//}

			//i = coproc_read(COPROC_1_RW);
			i = Convergence(x_C, y_C, Imax);
		}
*/
		pixel = i;

		//buff = px;
		//buff = (buff << 6) | py;
		//buff = (buff << 16) | pixel;
		//MemoryWrite(OLED_RW, buff);		
		printPixel(py, px,pixel);
	}
}

}

int main(int argc, char **argv) {

	int x_A = ~(3 << Nf - 2) + 1; // -1.75 au format A(31-Nf,Nf)
    	int y_A = ~(3 << Nf - 2) + 1; // -1.5 au format A(31-Nf,Nf)
	int x_B = (3 <<  Nf - 2); // 0.75 au format A(31-Nf,Nf)
    	int y_B = (3 <<  Nf - 2); // 1.5 au format A(31-Nf,Nf)

	/*my_printf("x_A=",x_A);
	my_printf("y_A=",y_A);
	my_printf("x_B=",x_B);
	my_printf("y_B=",y_B);*/

	int H;
	int W;

	bool vga_display = false;
	
	int Imax = 255;

	if(vga_display == false ){ // RGB OLED display
		H = 64;
		W = 96;
		MemoryWrite(OLED_MUX, OLED_MUX_BITMAP);
		MemoryWrite(OLED_BITMAP_RST, 1); // Reset the oled_rgb PMOD	
		generate_mandelbrot(H, W, Imax, 255, x_A, y_A, x_B, y_B);		
	}
	else{
		H = 480;
		W = 640;
		generate_mandelbrot_VGA(H, W, Imax, 255, x_A, y_A, x_B, y_B);
	}

	while(1)
	{

		int sw;
		int DX, DY;

		puts("\nReady, push a button to move/zoom\n");
		while(MemoryRead(BUTTONS_CHANGE) == 0){}
			int buttons = MemoryRead(BUTTONS_VALUES);
		while(MemoryRead(BUTTONS_CHANGE) == 0){}

			sw = MemoryRead(CTRL_SL_RW);

		switch(buttons)
		{
			case(CENTER_BUTTON):
			if((sw&1) == 1)
			{
				printf("zoom in\n");
				DX = x_B - x_A;
				DY = y_B - y_A;
				x_A = x_A + (DX >> 2);
				y_A = y_A + (DY >> 2);
				x_B = x_B - (DX >> 2);
				y_B = y_B - (DY >> 2);
					//printf("x_A,=%d, y_A=%d, x_B=%f, y_B=%f\n",x_A,y_A,x_B,y_B);

			}
			else if((sw&1) == 0)
			{
				printf("zoom out\n");
				DX = x_B - x_A;
				DY = y_B - y_A;
				x_A = x_A - (DX >> 1);
				y_A = y_A - (DY >> 1);
				x_B = x_B + (DX >> 1);
				y_B = y_B + (DY >> 1);
					//printf("x_A,=%f, y_A=%f, x_B=%f, y_B=%f",x_A,y_A,x_B,y_B);
			}
			else
			{
				break;
			}
			break;
			case(RIGHT_BUTTON):
			printf("move right\n");
			DX = x_B - x_A;
			x_A = x_A + (DX >> 3);
			x_B = x_B + (DX >> 3);
				//printf("x_A,=%f, y_A=%f, x_B=%f, y_B=%f",x_A,y_A,x_B,y_B);
			break;
			case(DOWN_BUTTON):
			printf("move down\n");
			DY = y_B - y_A;
			y_A = y_A + (DY >> 3);
			y_B = y_B + (DY >> 3);
				//printf("x_A,=%f, y_A=%f, x_B=%f, y_B=%f",x_A,y_A,x_B,y_B);
			break;
			case(UP_BUTTON):
			printf("move up\n");
			DY = y_B - y_A;
			y_A = y_A - (DY >> 3);
			y_B = y_B - (DY >> 3);
				//printf("x_A,=%f, y_A=%f, x_B=%f, y_B=%f",x_A,y_A,x_B,y_B);				
			break;
			case(LEFT_BUTTON):
			printf("move left\n");
			DX = x_B - x_A;
			x_A = x_A - (DX >> 3);
			x_B = x_B - (DX >> 3);
				//printf("x_A,=%f, y_A=%f, x_B=%f, y_B=%f",x_A,y_A,x_B,y_B);
			break;
			default:
			printf("no zoom/move\n");
			my_printf("buttons=",buttons);
			break;
			
		}

		if(vga_display == false ){ // RGB OLED display
			generate_mandelbrot(H, W, Imax, 255, x_A, y_A, x_B, y_B);
		}
		else{
			generate_mandelbrot_VGA(H, W, Imax, 255, x_A, y_A, x_B, y_B);
		}

	}

	printf("terminating program");
	return(0);
}


