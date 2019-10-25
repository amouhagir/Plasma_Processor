#ifndef __MISC_H__
#define __MISC_H__
inline void stop(){
	__asm volatile ( "break 1\n\t" : : );
}

inline void nop(){
	__asm volatile ( "nop\n\t" : : );
}

#endif