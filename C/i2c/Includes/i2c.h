#include "../../shared/plasmaSoPCDesign.h"
#include "../../shared/plasma.h"

#define MemoryRead(A)     (*(volatile unsigned int*)(A))
#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)

#define I2C_ADDR      0x40000300  // adress shift left by one, RW first bit
#define I2C_STATUS    0x40000304
#define I2C_CONTROL   0x40000308
#define I2C_DATA      0x4000030c

#define I2C_ADDR_RW             (1 << 0)

#define I2C_STATUS_BUSY         (1 << 0)
#define I2C_STATUS_ACK          (1 << 1)

#define I2C_CONTROL_START       (1 << 0)
#define I2C_CONTROL_STOP        (1 << 1)
#define I2C_CONTROL_DATA_READ   (1 << 2)
#define I2C_CONTROL_DATA_WRITE  (1 << 3)
#define I2C_CONTROL_NACK        (1 << 4)
#define I2C_CONTROL_SELECT      (1 << 5)

#define SLAVE_ADDR_TMP3       0x4B
#define SLAVE_ADDRESS_CMPS    0x1E
#define SLAVE_ADDRESS_GYRO    0x69

#define SELECT_PMOD	0x01
#define SELECT_TMP	0x00

#define READ      1 //
#define WRITE     0 // used in adress_send() function to chose reading or writing

void wait_busy();
void select_mode(unsigned int select);
int start();
void stop();
void address_set(unsigned int addr, unsigned int r_w);
int send_data(unsigned int data);
void receive_data(unsigned int *buf, unsigned int buf_len);
