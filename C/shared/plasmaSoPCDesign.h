#ifndef __SOPC_DESIGN_H__
#define __SOPC_DESIGN_H__

#define FIFO_IN_EMPTY            0x30000000 // =1 si la FIFO d'entrée est vide, 0 sinon
#define FIFO_OUT_EMPTY           0x30000010 // =1 si la FIFO de sortie est vide, 0 sinon
#define FIFO_IN_FULL             0x30000020 // =1 si la FIFO d'entrée est pleine, 0 sinon
#define FIFO_OUT_FULL            0x30000030 // =1 si la FIFO de sortie est pleine, 0 sinon
#define FIFO_IN_VALID            0x30000040
#define FIFO_OUT_VALID           0x30000050
#define FIFO_IN_COUNTER          0x30000060
#define FIFO_OUT_COUNTER         0x30000070
#define FIFO_IN_DATA_READ        0x30000080 // adresse de lecture de la FIFO d'entrée
#define FIFO_OUT_DATA_WRITE      0x30000090 // adresse d'écriture de la FIFO de sortie
#define TIMER_ADR                0x20000060 // adresse du timer


/*********** Interrupt bits **************/
#define IRQ_UART_READ_AVAILABLE  0x01
#define IRQ_UART_WRITE_AVAILABLE 0x02
#define IRQ_COUNTER18_NOT        0x04
#define IRQ_COUNTER18            0x08
#define IRQ_ETHERNET_RECEIVE     0x10
#define IRQ_ETHERNET_TRANSMIT    0x20
#define IRQ_GPIO31_NOT           0x40
#define IRQ_GPIO31               0x80

#define UART_WRITE        0x20000000
#define UART_READ         0x20000000
#define IRQ_MASK          0x20000010
#define IRQ_STATUS        0x20000020

#define MemoryRead(A)   (*(volatile unsigned int*)(A))
#define MemoryWrite(A,V) *(volatile unsigned int*)(A)=(V)

#define i_empty()         MemoryRead( FIFO_IN_EMPTY     )
#define o_empty()         MemoryRead( FIFO_OUT_EMPTY    )
#define i_full()          MemoryRead( FIFO_IN_FULL      )
#define o_full()          MemoryRead( FIFO_OUT_FULL     )
#define i_valid()         MemoryRead( FIFO_IN_VALID     )
#define o_valid()         MemoryRead( FIFO_OUT_VALID    )
#define i_counter()       MemoryRead( FIFO_IN_COUNTER   )
#define o_counter()       MemoryRead( FIFO_OUT_COUNTER  )
#define i_read()          MemoryRead( FIFO_IN_DATA_READ )
#define o_write(value)    MemoryWrite(FIFO_OUT_DATA_WRITE, value)
#define r_timer()         MemoryRead( TIMER_ADR         )
#define WAIT_PCIe_IN_DATA {while(i_empty());}

extern int puts(const char*);
extern void print_int(int);
extern void print_hex(int);

/*void print_timer(void)
{
  puts("TIMER VALUE = "); print_int( r_timer() ); puts("\n");
}*/

#endif