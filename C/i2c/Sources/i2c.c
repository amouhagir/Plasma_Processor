// I2C module -- i2c.c
// Author : Henri
// Description : Management of i2c protocol between PLASMA and Pmod devices

#include "../Includes/i2c.h"

void wait_busy()
{
  while ((MemoryRead (I2C_STATUS) & I2C_STATUS_BUSY) != 0) ;
}

// in order to select one of the two i2c plugged PMOD
void select_mode(unsigned int select)
{
  unsigned long ctrl;

  ctrl = MemoryRead(I2C_CONTROL);

  if (select)
    ctrl |= I2C_CONTROL_SELECT;
  else
    ctrl &= ~I2C_CONTROL_SELECT;

  MemoryWrite(I2C_CONTROL, ctrl);
}

int start()
{
  unsigned long ctrl;

  ctrl = MemoryRead(I2C_CONTROL);
  ctrl |= I2C_CONTROL_START;
  MemoryWrite(I2C_CONTROL, ctrl); 

  wait_busy();

  if ((MemoryRead(I2C_STATUS) & I2C_STATUS_ACK) != 0)
    return -1;

  return 0;
}

void stop()
{
  unsigned long ctrl;
  ctrl = MemoryRead(I2C_CONTROL);
  ctrl |= I2C_CONTROL_STOP;
  MemoryWrite(I2C_CONTROL, ctrl);

  wait_busy();
}

void address_set(unsigned int addr, unsigned int r_w)
{
  MemoryWrite(I2C_ADDR, (addr << 1) | r_w); // address  
}

/*
    Sending data
*/

int send_data(unsigned int data)
{
  unsigned int ctrl = 0;

  ctrl = MemoryRead(I2C_CONTROL);
  ctrl |= I2C_CONTROL_DATA_WRITE;

  MemoryWrite (I2C_DATA, data); // data
  MemoryWrite (I2C_CONTROL, ctrl); // writing start

  wait_busy();

  if ((MemoryRead(I2C_STATUS) & I2C_STATUS_ACK) != 0) // check ACK
    return -1;

  return 0;
}


/*
    Receiving data
*/

void receive_data(unsigned int *buf, unsigned int buf_len)
{
  unsigned int ctrl;
  int i;

  wait_busy();

  for (i = 0; i < buf_len; i++) {
    ctrl = MemoryRead(I2C_CONTROL);
    ctrl |= I2C_CONTROL_DATA_READ;

    if (i == buf_len - 1)
      ctrl |= (I2C_CONTROL_NACK); // last element nack = 1
    else
      ctrl &= ~(I2C_CONTROL_NACK); // else nack = 0

    MemoryWrite(I2C_CONTROL, ctrl);

    wait_busy();

    buf[i] = MemoryRead(I2C_DATA);
  }
}
