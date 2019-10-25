// I2C module -- main.c
// Author : Henri
// Description : Example program which handles I2C communication with the PMOD compass

#include "../Includes/i2c.h"

// PMOD Compass
#define SLAVE_ADDRESS_CMPS    0x1E


void sleep( unsigned int ms ) // fonction qui impose un delay en millisecondes 
{	// la fréquence d'horloge vaut 50 MHz
	unsigned int t0 = MemoryRead( TIMER_ADR  );
	while ( MemoryRead( TIMER_ADR  ) - t0 < 50000*ms ) // On compte 50000 périodes pour 1 ms
		;
}

void cmps_measure(int count)
{
  unsigned int buf[6];

  short x, y, z;

  select_mode(SELECT_PMOD);
  
  puts("Compass sensor, continuous mode\n");

  address_set(SLAVE_ADDRESS_CMPS, WRITE);
  start();
  send_data(0x00); // CRA register pointer
  send_data(0x70); // set values
  stop();

  address_set(SLAVE_ADDRESS_CMPS, WRITE);
  start();
  send_data(0x01); // CRB register pointer
  send_data(0xA0); // set values
  stop();

  address_set(SLAVE_ADDRESS_CMPS, WRITE);
  start();
  send_data(0x02); // Mode register pointer
  send_data(0x00); // set values
  stop();

  sleep(10); // 10ms

  while (count--) {
    address_set(SLAVE_ADDRESS_CMPS, READ);
    start();
    receive_data((unsigned int *) &buf, 6); // Six readings
    stop();

    x = (short) (buf[0] << 8) + buf[1];
    y = (short) (buf[2] << 8) + buf[3];
    z = (short) (buf[4] << 8) + buf[5];

    address_set(SLAVE_ADDRESS_CMPS, WRITE);
    start();
    send_data(0x03); // First data register pointer
    stop();

    puts("x: ");
    print_int(x);

    puts(" y: ");
    print_int(y);

    puts(" z: ");
    print_int(z);
    puts("\n");

    sleep(500); // 500ms
  }
}

void tmp_measure(int count)
{
  unsigned int buf[2];
  unsigned int value;

  select_mode(SELECT_TMP);

  puts("Temperature sensor\n");

  while (count--) {
    address_set(SLAVE_ADDR_TMP3, READ);
    start();
    receive_data((unsigned int *) &buf, 2);
    stop();

    value = (short) (buf[0] << 8) + buf[1];
    value = (value >> 3) * 625 / 10; // m degC

    puts("tmp: ");
    print_int(value);
    puts("\n");

    sleep(500); // 500ms
  }
}

void gyro_measure(int count)
{
  unsigned int buf[6];

  short x, y, z;
  int i;

  select_mode(SELECT_PMOD);

  puts("Gyro sensor\n");

  address_set(SLAVE_ADDRESS_GYRO, WRITE);
  start();
  send_data(0x20); // Select control register1
  send_data(0x0F); // Normal mode, X, Y, Z-Axis enabled
  stop();

  address_set(SLAVE_ADDRESS_GYRO, WRITE);
  start();
  send_data(0x23); // Select control register4
  send_data(0x30); // Continous update, FSR = 2000dps
  stop();
  
  sleep(10); // 10ms

  while (count--) {
    for (i = 0; i < 6; i++) {
      address_set(SLAVE_ADDRESS_GYRO, WRITE);
      start();
      send_data(40 + i); // data register
      stop();   

      address_set(SLAVE_ADDRESS_GYRO, READ);
      start();
      receive_data((unsigned int *) &buf[i], 1);
      stop();   
    }

    x = (short) (buf[1] << 8) + buf[0];
    y = (short) (buf[3] << 8) + buf[2];
    z = (short) (buf[5] << 8) + buf[4];
    
    puts("x: ");
    print_int(x);

    puts(" y: ");
    print_int(y);

    puts(" z: ");
    print_int(z);
    puts("\n");

    sleep(500); // 500ms
  }
}

int main(int argc, char const *argv[])
{
  puts("I2C Module Start\n");

  while (1) {
    cmps_measure(10);
    tmp_measure(10);
    gyro_measure(10);
  }

  return 0;
}
