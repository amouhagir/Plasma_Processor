//convert.c by Steve Rhoads 4/26/01
//Now uses the ELF format (get gccmips_elf.zip)
//set $gp and zero .sbss and .bss
//Reads test.axf and creates code.txt
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUF_SIZE (128*1024) 

typedef unsigned int   uint32;
typedef unsigned short uint16;
typedef unsigned char  uint8;

void permuttation(char *data)
{
	unsigned char t1 = (*data) & 0xF0;
	unsigned char t2 = (*data) & 0x0F;
	(*data) = ((t1 >> 4) & 0x0F) | (t2 << 4);
}

void perm(char *data)
{
	permuttation(&data[0]);
	permuttation(&data[1]);
	permuttation(&data[2]);
	permuttation(&data[3]);
}


int main(int argc, char *argv[])
{
	printf("BINARY FILE FORMAT CONVERSION (test.bin) => (test.exec)\n");
   FILE *infile = fopen("test.bin", "rb");
   if(infile == NULL)
   {
      printf("Can't open test.axf");
      return 0;
   }

   uint8 *buf = (uint8*)malloc(BUF_SIZE);
   int size   = (int)fread(buf, 1, BUF_SIZE, infile);
   fclose(infile);

	printf(" FILE SIZE BEFORE = %d octets (0x%8.8X)\n", size, size);

   FILE *outfile = fopen("test.exec", "wb");
	unsigned int Header = 0xFFFFFFFF;

	int rSize = size;

	//size = 0x01020304;
	//printf(" -- SIZE BEFORE = 0x%8.8X\n", size);
	//perm( (char*)&size );
	//printf(" -- SIZE AFTER  = 0x%8.8X\n", size);


   fwrite(&Header, 1,     4, outfile);
   fwrite(&size,   1,     4, outfile);
   fwrite(buf,     1, rSize, outfile);
   fclose(outfile);
	printf(" FILE SIZE AFTER  = %d octets (0x%8.8X)\n", (rSize+8), (rSize+8));

   return 0;
}

