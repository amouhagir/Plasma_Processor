# Memory Map

## Misc

`0x20000000` : UART  
`0x20000010` : IRQ Mask  
`0x20000030` : GPIO0 Out Set bits  
`0x20000040` : GPIO0 Out Clear bits  
`0x20000050` : GPIOA In  
`0x20000060` : Counter  
`0x20000070` : Ethernet transmit count  

##  FIFO

`0x30000000` : FIFO IN EMPTY  
`0x30000010` : FIFO OUT EMPTY  
`0x30000020` : FIFO IN VALID  
`0x30000030` : FIFO OUT VALID  
`0x30000040` : FIFO IN FULL  
`0x30000050` : FIFO IN FULL  
`0x30000060` : FIFO IN COUNTER  
`0x30000070` : FIFO OUT COUNTER  
`0x30000080` : FIFO IN READ DATA  
`0x30000090` : FIFO OUT WRITE DATA  

## Coprocessor

`0x40000000` : COPROCESSOR 1 reset  
`0x40000004` : COPROCESSOR 1 input/output  
`0x40000030` : COPROCESSOR 2 reset  
`0x40000034` : COPROCESSOR 2 input/output  
`0x40000060` : COPROCESSOR 3 reset  
`0x40000064` : COPROCESSOR 3 input/output  
`0x40000090` : COPROCESSOR 4 reset  
`0x40000094` : COPROCESSOR 4 input/output  

## Controllers

`0x400000C0` : Switch/LED reset  
`0x400000C4` : Switch/LED data  

`0x40000100` : Buttons values  
`0x40000104` : Buttons change  

`0x40000200` : Seven segment display input  
`0x40000204` : Seven segment display reset  

`0x40000300` : I2C_ADDR  
`0x40000304` : I2C_STATUS  
`0x40000308` : I2C_CONTROL  
`0x4000030C` : I2C_DATA  

`0x40000400` : OLED mux  
`0x400004A0` : OLED charmap reset  
`0x400004A4` : OLED terminal reset  
`0x400004A8` : OLED charmap data  
`0x400004AC` : OLED terminal data  
`0x400004B0` : OLED bitmap reset  
`0x400004B4` : OLED nibblemap reset  
`0x400004B8` : OLED bitmap data  
`0x400004BC` : OLED nibblemap data  
`0x400004D0` : OLED sigplot reset  
`0x400004D8` : OLED sigplot data  
