##################################################################
# TITLE: Boot Up Code
# AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
# DATE CREATED: 1/12/02
# FILENAME: boot.asm
# PROJECT: Plasma CPU core
# COPYRIGHT: Software placed into the public domain by the author.
#    Software 'as is' without warranty.  Author liable for nothing.
# DESCRIPTION:
#    Initializes the stack pointer and jumps to main().
##################################################################
   #Reserve 512 bytes for stack
   # BLG 4ko de STACK
   #.comm InitStack, 128
   .comm InitStack, 2048

   .text
   .align 2
   .global entry
   .ent	entry
entry:
   .set noreorder

   #These four instructions should be the first instructions.
   #convert.exe previously initialized $gp, .sbss_start, .bss_end, $sp
   la    $gp, _gp             #initialize global pointer
   la    $5, __bss_start      #$5 = .sbss_start
   la    $4, _end             #$2 = .bss_end
   #la    $sp, InitStack+80   #initialize stack pointer
   la    $sp, InitStack+(2048-24) #initialize stack pointer

$BSS_CLEAR:
   sw    $0, 0($5)
   slt   $3, $5, $4
   bnez  $3, $BSS_CLEAR
   addiu $5, $5, 4

   jal   main
   nop
$L1:
   j $L1

   .end entry
