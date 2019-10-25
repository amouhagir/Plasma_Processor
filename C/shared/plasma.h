/*--------------------------------------------------------------------
 * TITLE: Plasma Hardware Defines
 * AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
 * DATE CREATED: 12/17/05
 * FILENAME: plasma.h
 * PROJECT: Plasma CPU core
 * COPYRIGHT: Software placed into the public domain by the author.
 *    Software 'as is' without warranty.  Author liable for nothing.
 * DESCRIPTION:
 *    Plasma Hardware Defines
 *--------------------------------------------------------------------*/
#ifndef __PLASMA_H__
#define __PLASMA_H__

/*********** Hardware addesses ***********/
#define RAM_INTERNAL_BASE 0x00000000 //8KB
#define RAM_EXTERNAL_BASE 0x10000000 //1MB
#define RAM_EXTERNAL_SIZE 0x00010000
#define MISC_BASE         0x20000000
#define UART_WRITE        0x20000000
#define UART_READ         0x20000000
#define VGA_READ          0x20000120
#define VGA_WRITE         0x20000120
#define IRQ_MASK          0x20000010
#define IRQ_STATUS        0x20000020
#define GPIO0_OUT         0x20000030
#define GPIO0_CLEAR       0x20000040
#define GPIOA_IN          0x20000050
#define COUNTER_REG       0x20000060
#define ETHERNET_REG      0x20000070
#define FLASH_BASE        0x30000000
#define CTRL_SL_RST       0x400000C0
#define CTRL_SL_RW        0x400000C4
#define BUTTONS_VALUES    0x40000100
#define BUTTONS_CHANGE    0x40000104
#define SEVEN_SEGMENT_REG 0x40000200
#define SEVEN_SEGMENT_RST 0x40000204
#define OLED_MUX          0x40000400
#define OLED_CHARMAP_RST  0x400004A0
#define OLED_TERMINAL_RST 0x400004A4
#define OLED_CHARMAP_RW   0x400004A8
#define OLED_TERMINAL_RW  0x400004AC
#define OLED_BITMAP_RST   0x400004B0
#define OLED_NIBBLE_RST   0x400004B4
#define OLED_BITMAP_RW    0x400004B8
#define OLED_NIBBLE_RW    0x400004BC
#define OLED_SIGPLOT_RST  0x400004D0
#define OLED_SIGPLOT_RW   0x400004D8

#define OLED_MUX_CHARMAP  0x01
#define OLED_MUX_BITMAP   0x02
#define OLED_MUX_TERMINAL 0x03
#define OLED_MUX_NIBBLE   0x04
#define OLED_MUX_SIGPLOT  0x05

/*********** GPIO out bits ***************/
#define ETHERNET_MDIO     0x00200000
#define ETHERNET_MDIO_WE  0x00400000
#define ETHERENT_MDC      0x00800000
#define ETHERNET_ENABLE   0x01000000

/*********** Interrupt bits **************/
#define IRQ_UART_READ_AVAILABLE  0x01
#define IRQ_UART_WRITE_AVAILABLE 0x02
#define IRQ_COUNTER18_NOT        0x04
#define IRQ_COUNTER18            0x08
#define IRQ_ETHERNET_RECEIVE     0x10
#define IRQ_ETHERNET_TRANSMIT    0x20
#define IRQ_GPIO31_NOT           0x40
#define IRQ_GPIO31               0x80

/*********** Ethernet buffers ************/
#define ETHERNET_RECEIVE  0x13ff0000
#define ETHERNET_TRANSMIT 0x13fe0000

/***********      PWM      ***************/
#define CTRL_PWM_RST       0x400004D4
#define CTRL_PWM_RW        0x400004DC
#define CTRL_RW            0x400004E0
#define CTRL_ETAT          0x400004E4

#endif //__PLASMA_H__
