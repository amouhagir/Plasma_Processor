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


void send_char(unsigned char c, int fileDescriptor)
{

	int rBytes, wBytes;
	wBytes = write(fileDescriptor, &c, 1);
	assert( wBytes == 1 );
	unsigned char buf;
	rBytes = read (fileDescriptor, &buf, 1);
	assert( rBytes == 1 );
	//printf("s=%d\n", (int)c);
	//printf("r=%d\n",(int)buf);
	usleep(1);
	assert(c == buf);
	
}

int main(int argc, char ** argv) {

	char *filename = argv[1];
	FILE *infile   = fopen(filename , "rb");
	if(infile == NULL)
	{
		printf("Can't open : %s\n", filename);
		exit (EXIT_SUCCESS);
	}
	// ON CREE LE TABLEAU TEMPORAIRE UTILISE POUR LA LECTURE DU PROGRAMME
	uint8_t *buf = new unsigned char[BUF_SIZE];
	int size   = (int)fread(buf, 1, BUF_SIZE, infile);
	fclose(infile);


    int fileDescriptor;
	fileDescriptor = open("/dev/ttyUSB1", O_RDWR | O_NOCTTY );
       if(fileDescriptor == -1)
       {
        	printf("Impossible d'ouvrir ttyUSB1 !\n");
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

	puts("loading image...\n");

	for(int k=0; k< size; k++){
	    send_char(buf[k], fileDescriptor);
	}

    puts("image loaded\n");
    

}