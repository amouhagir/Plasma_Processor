#ifndef __ISA_CUSTOM_H__
#define __ISA_CUSTOM_H__

inline int isa_custom_1(int a, int b){
	int res; __asm volatile ( "custom.alu1  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_2(int a, int b){
	int res; __asm volatile ( "custom.alu2  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_3(int a, int b){
	int res; __asm volatile ( "custom.alu3  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_4(int a, int b){
	int res; __asm volatile ( "custom.alu4  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_5(int a, int b){
	int res; __asm volatile ( "custom.alu5  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_6(int a, int b){
	int res; __asm volatile ( "custom.alu6  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_7(int a, int b){
	int res; __asm volatile ( "custom.alu7  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_8(int a, int b){
	int res; __asm volatile ( "custom.alu8  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_9(int a, int b){
	int res; __asm volatile ( "custom.alu9  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_10(int a, int b){
	int res; __asm volatile ( "custom.alu10  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_11(int a, int b){
	int res; __asm volatile ( "custom.alu11  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_12(int a, int b){
	int res; __asm volatile ( "custom.alu12  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_13(int a, int b){
	int res; __asm volatile ( "custom.alu13  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_14(int a, int b){
	int res; __asm volatile ( "custom.alu14  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_15(int a, int b){
	int res; __asm volatile ( "custom.alu15  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_16(int a, int b){
	int res; __asm volatile ( "custom.alu16  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_17(int a, int b){
	int res; __asm volatile ( "custom.alu17  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_18(int a, int b){
	int res; __asm volatile ( "custom.alu18  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

inline int isa_custom_19(int a, int b){
	int res; __asm volatile ( "custom.alu19  %0, %1, %2 \n\t" : "=r" (res) : "r" (a), "r" (b) ); return res;
}

#endif