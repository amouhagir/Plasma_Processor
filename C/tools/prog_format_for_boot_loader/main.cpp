#include <stdio.h>
#include <stdbool.h>
#include <cstdlib>
#include <cstdint>
#include <cassert>

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <paths.h>
#include <termios.h>
#include <sysexits.h>
#include <sys/param.h>
#include <sys/select.h>
#include <sys/time.h>	
#include <time.h>
#include <cassert>

#define BUF_SIZE 1000000
#define EXIT_SUCCESS 0

int error = 1;
void send_char(unsigned char c, int fileDescriptor, bool wait = false)
{
	int rBytes, wBytes;
	wBytes = write(fileDescriptor, &c, 1);
	unsigned char buf = 14;	
}

int main(int argc, char ** argv) {

	char *filename = argv[1];
	char *serial = argv[2];
	FILE *infile   = fopen(filename , "rb");
	if(infile == NULL)
	{
		printf("Cannot open file: %s\n", filename);
		exit (EXIT_SUCCESS);
	}
	
	// ON CREE LE TABLEAU TEMPORAIRE UTILISE POUR LA LECTURE DU PROGRAMME
	uint8_t *buf = new unsigned char[BUF_SIZE];
	int size   = (int)fread(buf, 1, BUF_SIZE, infile);
	fclose(infile);
	int fileDescriptor;

	if (argc < 3 || filename == NULL || serial == NULL)
		return 1;

	fileDescriptor = open(serial, O_RDWR | O_NOCTTY );
	if(fileDescriptor == -1)
	{
		printf("Cannot open serial port : %s\n", serial);
            exit( 0 );
        }
      	struct termios t;
		  tcgetattr(fileDescriptor, &t); // recupÃ¨re les attributs
		  cfmakeraw(&t); // Reset les attributs
		  t.c_cflag     = CREAD | CLOCAL;     // turn on READ
		  t.c_cflag    |= CS8;
		  t.c_cc[VMIN]  = 0;
		  t.c_cc[VTIME] = 50;     // 5 sec timeout
		  cfsetispeed(&t, B115200);
		  cfsetospeed(&t, B115200);
		  tcsetattr(fileDescriptor, TCSAFLUSH, &t); // envoie le tout au driver

	unsigned int *prog = (unsigned int *)buf;
	unsigned char clef[4] = {0x33, 0x32, 0x31, 0x30};
	int wBytes;
	printf("Sending the key to Plasma\n");
	send_char(clef[3], fileDescriptor);
	usleep( 10000 );
	send_char(clef[2], fileDescriptor);
	usleep( 10000 );
	send_char(clef[1], fileDescriptor);
	usleep( 10000 );
	send_char(clef[0], fileDescriptor);
	printf("Key sent to Plasma\n");

	unsigned char *p_size = (unsigned char*)&size;
    	send_char(p_size[0], fileDescriptor);
    	send_char(p_size[1], fileDescriptor);
    	send_char(p_size[2], fileDescriptor);
    	send_char(p_size[3], fileDescriptor);

	puts("Sending program to Plasma via UART\n");

	for(int k=0; k< size; k++){
	    send_char(buf[k], fileDescriptor);
	}

    puts("Program has been sent via UART\n");

}
