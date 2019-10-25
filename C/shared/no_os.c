
#include "plasma.h"

#define MemoryRead(A)     (*(volatile unsigned int*)(A))
#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)

int putchar(int value)
{
   while((MemoryRead(IRQ_STATUS) & IRQ_UART_WRITE_AVAILABLE) == 0)
      ;
   MemoryWrite(UART_WRITE, value);
   return 0;
}

int puts(const char *string)
{
   while(*string)
   {
      if(*string == '\n')
         putchar('\r');
      putchar(*string++);
   }
   return 0;
}

void print_hex(unsigned long num)
{
   long i;
   unsigned long j;
   for(i = 28; i >= 0; i -= 4) 
   {
      j = (num >> i) & 0xf;
      if(j < 10) 
         putchar('0' + j);
      else 
         putchar('a' - 10 + j);
   }
}

int buffer[16];

void itoa3(int n, int digits)
{
	int i;
	for(i=0; i<digits; i++){
		buffer[i] = '0' + (n%10);
		n   /= 10;
	}
	buffer[digits] = 0;
}

#define abs(a) ((a<0)?-a:a)

void print(long num, long digits)
{
    int i;
    if( num < 0 ) puts("-");
    itoa3(abs(num), digits);
	for(i=0; i<digits; i++){
		putchar(buffer[digits-i-1]);
	}
}              


void print_int(int _num)
{
	int copy = abs(_num);
	int size = 0;
	while( copy != 0 ){
		size += 1;
		copy /= 10;
	}
	size = (size != 0)?size:1;
	
	int sign = 0;
	print(_num, sign + size);
}
