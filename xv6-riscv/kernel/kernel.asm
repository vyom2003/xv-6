
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b8013103          	ld	sp,-1152(sp) # 80008b80 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	b8e70713          	addi	a4,a4,-1138 # 80008be0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	7cc78793          	addi	a5,a5,1996 # 80006830 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbb197>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	f8078793          	addi	a5,a5,-128 # 8000102e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	8de080e7          	jalr	-1826(ra) # 80002a0a <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	b9450513          	addi	a0,a0,-1132 # 80010d20 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	bf0080e7          	jalr	-1040(ra) # 80000d84 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	b8448493          	addi	s1,s1,-1148 # 80010d20 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	c1290913          	addi	s2,s2,-1006 # 80010db8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	9de080e7          	jalr	-1570(ra) # 80001ba2 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	688080e7          	jalr	1672(ra) # 80002854 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	248080e7          	jalr	584(ra) # 80002422 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	79e080e7          	jalr	1950(ra) # 800029b4 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	af650513          	addi	a0,a0,-1290 # 80010d20 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	c06080e7          	jalr	-1018(ra) # 80000e38 <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	ae050513          	addi	a0,a0,-1312 # 80010d20 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	bf0080e7          	jalr	-1040(ra) # 80000e38 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	b4f72023          	sw	a5,-1216(a4) # 80010db8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	a4e50513          	addi	a0,a0,-1458 # 80010d20 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	aaa080e7          	jalr	-1366(ra) # 80000d84 <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	768080e7          	jalr	1896(ra) # 80002a60 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	a2050513          	addi	a0,a0,-1504 # 80010d20 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	b30080e7          	jalr	-1232(ra) # 80000e38 <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00011717          	auipc	a4,0x11
    80000328:	9fc70713          	addi	a4,a4,-1540 # 80010d20 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	9d278793          	addi	a5,a5,-1582 # 80010d20 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	a3c7a783          	lw	a5,-1476(a5) # 80010db8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	99070713          	addi	a4,a4,-1648 # 80010d20 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	98048493          	addi	s1,s1,-1664 # 80010d20 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	94470713          	addi	a4,a4,-1724 # 80010d20 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	9cf72723          	sw	a5,-1586(a4) # 80010dc0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	90878793          	addi	a5,a5,-1784 # 80010d20 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	98c7a023          	sw	a2,-1664(a5) # 80010dbc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	97450513          	addi	a0,a0,-1676 # 80010db8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	180080e7          	jalr	384(ra) # 800025cc <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00011517          	auipc	a0,0x11
    8000046a:	8ba50513          	addi	a0,a0,-1862 # 80010d20 <cons>
    8000046e:	00001097          	auipc	ra,0x1
    80000472:	886080e7          	jalr	-1914(ra) # 80000cf4 <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00242797          	auipc	a5,0x242
    80000482:	05278793          	addi	a5,a5,82 # 802424d0 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00011797          	auipc	a5,0x11
    80000554:	8807a823          	sw	zero,-1904(a5) # 80010de0 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b7650513          	addi	a0,a0,-1162 # 800080e8 <digits+0xa8>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	60f72e23          	sw	a5,1564(a4) # 80008ba0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00011d97          	auipc	s11,0x11
    800005c4:	820dad83          	lw	s11,-2016(s11) # 80010de0 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	7ca50513          	addi	a0,a0,1994 # 80010dc8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	77e080e7          	jalr	1918(ra) # 80000d84 <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	66650513          	addi	a0,a0,1638 # 80010dc8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	6ce080e7          	jalr	1742(ra) # 80000e38 <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	64a48493          	addi	s1,s1,1610 # 80010dc8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	564080e7          	jalr	1380(ra) # 80000cf4 <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	60a50513          	addi	a0,a0,1546 # 80010de8 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	50e080e7          	jalr	1294(ra) # 80000cf4 <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	536080e7          	jalr	1334(ra) # 80000d38 <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	3967a783          	lw	a5,918(a5) # 80008ba0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	5a4080e7          	jalr	1444(ra) # 80000dd8 <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	36273703          	ld	a4,866(a4) # 80008ba8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	3627b783          	ld	a5,866(a5) # 80008bb0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	578a0a13          	addi	s4,s4,1400 # 80010de8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	33048493          	addi	s1,s1,816 # 80008ba8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	33098993          	addi	s3,s3,816 # 80008bb0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	d26080e7          	jalr	-730(ra) # 800025cc <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	50650513          	addi	a0,a0,1286 # 80010de8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	49a080e7          	jalr	1178(ra) # 80000d84 <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2ae7a783          	lw	a5,686(a5) # 80008ba0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	2b47b783          	ld	a5,692(a5) # 80008bb0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	2a473703          	ld	a4,676(a4) # 80008ba8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	4d8a0a13          	addi	s4,s4,1240 # 80010de8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	29048493          	addi	s1,s1,656 # 80008ba8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	29090913          	addi	s2,s2,656 # 80008bb0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	af2080e7          	jalr	-1294(ra) # 80002422 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	4a248493          	addi	s1,s1,1186 # 80010de8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	24f73b23          	sd	a5,598(a4) # 80008bb0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	4cc080e7          	jalr	1228(ra) # 80000e38 <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	41848493          	addi	s1,s1,1048 # 80010de8 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	3aa080e7          	jalr	938(ra) # 80000d84 <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	44c080e7          	jalr	1100(ra) # 80000e38 <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <init>:
  struct spinlock lock;
  struct run *freelist;
} kmem;
struct spinlock lock;
int ref[PGROUNDUP(PHYSTOP)/4096];
void init(){
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	1000                	addi	s0,sp,32
  initlock(&lock, "init_fault");
    80000a08:	00010497          	auipc	s1,0x10
    80000a0c:	41848493          	addi	s1,s1,1048 # 80010e20 <lock>
    80000a10:	00007597          	auipc	a1,0x7
    80000a14:	65058593          	addi	a1,a1,1616 # 80008060 <digits+0x20>
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	2da080e7          	jalr	730(ra) # 80000cf4 <initlock>
  acquire(&lock);
    80000a22:	8526                	mv	a0,s1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	360080e7          	jalr	864(ra) # 80000d84 <acquire>
  for(int i=0;i<(PGROUNDUP(PHYSTOP)/4096);++i)
    80000a2c:	00010797          	auipc	a5,0x10
    80000a30:	42c78793          	addi	a5,a5,1068 # 80010e58 <ref>
    80000a34:	00230717          	auipc	a4,0x230
    80000a38:	42470713          	addi	a4,a4,1060 # 80230e58 <pid_lock>
    ref[i]=0;
    80000a3c:	0007a023          	sw	zero,0(a5)
  for(int i=0;i<(PGROUNDUP(PHYSTOP)/4096);++i)
    80000a40:	0791                	addi	a5,a5,4
    80000a42:	fee79de3          	bne	a5,a4,80000a3c <init+0x3e>
  release(&lock);
    80000a46:	00010517          	auipc	a0,0x10
    80000a4a:	3da50513          	addi	a0,a0,986 # 80010e20 <lock>
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	3ea080e7          	jalr	1002(ra) # 80000e38 <release>
}
    80000a56:	60e2                	ld	ra,24(sp)
    80000a58:	6442                	ld	s0,16(sp)
    80000a5a:	64a2                	ld	s1,8(sp)
    80000a5c:	6105                	addi	sp,sp,32
    80000a5e:	8082                	ret

0000000080000a60 <sub>:
void sub(void*pa){
    80000a60:	1101                	addi	sp,sp,-32
    80000a62:	ec06                	sd	ra,24(sp)
    80000a64:	e822                	sd	s0,16(sp)
    80000a66:	e426                	sd	s1,8(sp)
    80000a68:	1000                	addi	s0,sp,32
    80000a6a:	84aa                	mv	s1,a0
  acquire(&lock);
    80000a6c:	00010517          	auipc	a0,0x10
    80000a70:	3b450513          	addi	a0,a0,948 # 80010e20 <lock>
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	310080e7          	jalr	784(ra) # 80000d84 <acquire>
  if(ref[(uint64)pa/4096]<=0){
    80000a7c:	00c4d513          	srli	a0,s1,0xc
    80000a80:	00251713          	slli	a4,a0,0x2
    80000a84:	00010797          	auipc	a5,0x10
    80000a88:	3d478793          	addi	a5,a5,980 # 80010e58 <ref>
    80000a8c:	97ba                	add	a5,a5,a4
    80000a8e:	439c                	lw	a5,0(a5)
    80000a90:	02f05763          	blez	a5,80000abe <sub+0x5e>
    panic("sub");
  }
  ref[(uint64)pa/4096]-=1;
    80000a94:	050a                	slli	a0,a0,0x2
    80000a96:	00010717          	auipc	a4,0x10
    80000a9a:	3c270713          	addi	a4,a4,962 # 80010e58 <ref>
    80000a9e:	953a                	add	a0,a0,a4
    80000aa0:	37fd                	addiw	a5,a5,-1
    80000aa2:	c11c                	sw	a5,0(a0)
  release(&lock);
    80000aa4:	00010517          	auipc	a0,0x10
    80000aa8:	37c50513          	addi	a0,a0,892 # 80010e20 <lock>
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	38c080e7          	jalr	908(ra) # 80000e38 <release>
}
    80000ab4:	60e2                	ld	ra,24(sp)
    80000ab6:	6442                	ld	s0,16(sp)
    80000ab8:	64a2                	ld	s1,8(sp)
    80000aba:	6105                	addi	sp,sp,32
    80000abc:	8082                	ret
    panic("sub");
    80000abe:	00007517          	auipc	a0,0x7
    80000ac2:	5b250513          	addi	a0,a0,1458 # 80008070 <digits+0x30>
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	a7e080e7          	jalr	-1410(ra) # 80000544 <panic>

0000000080000ace <add>:
void add(void*pa){
    80000ace:	1101                	addi	sp,sp,-32
    80000ad0:	ec06                	sd	ra,24(sp)
    80000ad2:	e822                	sd	s0,16(sp)
    80000ad4:	e426                	sd	s1,8(sp)
    80000ad6:	1000                	addi	s0,sp,32
    80000ad8:	84aa                	mv	s1,a0
  acquire(&lock);
    80000ada:	00010517          	auipc	a0,0x10
    80000ade:	34650513          	addi	a0,a0,838 # 80010e20 <lock>
    80000ae2:	00000097          	auipc	ra,0x0
    80000ae6:	2a2080e7          	jalr	674(ra) # 80000d84 <acquire>
  if(ref[(uint64)pa/4096]<0){
    80000aea:	00c4d513          	srli	a0,s1,0xc
    80000aee:	00251713          	slli	a4,a0,0x2
    80000af2:	00010797          	auipc	a5,0x10
    80000af6:	36678793          	addi	a5,a5,870 # 80010e58 <ref>
    80000afa:	97ba                	add	a5,a5,a4
    80000afc:	439c                	lw	a5,0(a5)
    80000afe:	0207c763          	bltz	a5,80000b2c <add+0x5e>
    panic("add");
  }
  ref[(uint64)pa/4096]+=1;
    80000b02:	050a                	slli	a0,a0,0x2
    80000b04:	00010717          	auipc	a4,0x10
    80000b08:	35470713          	addi	a4,a4,852 # 80010e58 <ref>
    80000b0c:	953a                	add	a0,a0,a4
    80000b0e:	2785                	addiw	a5,a5,1
    80000b10:	c11c                	sw	a5,0(a0)
  release(&lock);
    80000b12:	00010517          	auipc	a0,0x10
    80000b16:	30e50513          	addi	a0,a0,782 # 80010e20 <lock>
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	31e080e7          	jalr	798(ra) # 80000e38 <release>
}
    80000b22:	60e2                	ld	ra,24(sp)
    80000b24:	6442                	ld	s0,16(sp)
    80000b26:	64a2                	ld	s1,8(sp)
    80000b28:	6105                	addi	sp,sp,32
    80000b2a:	8082                	ret
    panic("add");
    80000b2c:	00007517          	auipc	a0,0x7
    80000b30:	54c50513          	addi	a0,a0,1356 # 80008078 <digits+0x38>
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	a10080e7          	jalr	-1520(ra) # 80000544 <panic>

0000000080000b3c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000b3c:	7179                	addi	sp,sp,-48
    80000b3e:	f406                	sd	ra,40(sp)
    80000b40:	f022                	sd	s0,32(sp)
    80000b42:	ec26                	sd	s1,24(sp)
    80000b44:	e84a                	sd	s2,16(sp)
    80000b46:	e44e                	sd	s3,8(sp)
    80000b48:	1800                	addi	s0,sp,48
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000b4a:	03451793          	slli	a5,a0,0x34
    80000b4e:	e3b9                	bnez	a5,80000b94 <kfree+0x58>
    80000b50:	84aa                	mv	s1,a0
    80000b52:	00243797          	auipc	a5,0x243
    80000b56:	b1678793          	addi	a5,a5,-1258 # 80243668 <end>
    80000b5a:	02f56d63          	bltu	a0,a5,80000b94 <kfree+0x58>
    80000b5e:	47c5                	li	a5,17
    80000b60:	07ee                	slli	a5,a5,0x1b
    80000b62:	02f57963          	bgeu	a0,a5,80000b94 <kfree+0x58>
    panic("kfree");
  sub(pa);
    80000b66:	00000097          	auipc	ra,0x0
    80000b6a:	efa080e7          	jalr	-262(ra) # 80000a60 <sub>
  if(ref[(uint64)pa/4096]>0) return;
    80000b6e:	00c4d793          	srli	a5,s1,0xc
    80000b72:	00279713          	slli	a4,a5,0x2
    80000b76:	00010797          	auipc	a5,0x10
    80000b7a:	2e278793          	addi	a5,a5,738 # 80010e58 <ref>
    80000b7e:	97ba                	add	a5,a5,a4
    80000b80:	439c                	lw	a5,0(a5)
    80000b82:	02f05163          	blez	a5,80000ba4 <kfree+0x68>

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}
    80000b86:	70a2                	ld	ra,40(sp)
    80000b88:	7402                	ld	s0,32(sp)
    80000b8a:	64e2                	ld	s1,24(sp)
    80000b8c:	6942                	ld	s2,16(sp)
    80000b8e:	69a2                	ld	s3,8(sp)
    80000b90:	6145                	addi	sp,sp,48
    80000b92:	8082                	ret
    panic("kfree");
    80000b94:	00007517          	auipc	a0,0x7
    80000b98:	4ec50513          	addi	a0,a0,1260 # 80008080 <digits+0x40>
    80000b9c:	00000097          	auipc	ra,0x0
    80000ba0:	9a8080e7          	jalr	-1624(ra) # 80000544 <panic>
  memset(pa, 1, PGSIZE);
    80000ba4:	6605                	lui	a2,0x1
    80000ba6:	4585                	li	a1,1
    80000ba8:	8526                	mv	a0,s1
    80000baa:	00000097          	auipc	ra,0x0
    80000bae:	2d6080e7          	jalr	726(ra) # 80000e80 <memset>
  acquire(&kmem.lock);
    80000bb2:	00010997          	auipc	s3,0x10
    80000bb6:	26e98993          	addi	s3,s3,622 # 80010e20 <lock>
    80000bba:	00010917          	auipc	s2,0x10
    80000bbe:	27e90913          	addi	s2,s2,638 # 80010e38 <kmem>
    80000bc2:	854a                	mv	a0,s2
    80000bc4:	00000097          	auipc	ra,0x0
    80000bc8:	1c0080e7          	jalr	448(ra) # 80000d84 <acquire>
  r->next = kmem.freelist;
    80000bcc:	0309b783          	ld	a5,48(s3)
    80000bd0:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000bd2:	0299b823          	sd	s1,48(s3)
  release(&kmem.lock);
    80000bd6:	854a                	mv	a0,s2
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	260080e7          	jalr	608(ra) # 80000e38 <release>
    80000be0:	b75d                	j	80000b86 <kfree+0x4a>

0000000080000be2 <freerange>:
{
    80000be2:	7139                	addi	sp,sp,-64
    80000be4:	fc06                	sd	ra,56(sp)
    80000be6:	f822                	sd	s0,48(sp)
    80000be8:	f426                	sd	s1,40(sp)
    80000bea:	f04a                	sd	s2,32(sp)
    80000bec:	ec4e                	sd	s3,24(sp)
    80000bee:	e852                	sd	s4,16(sp)
    80000bf0:	e456                	sd	s5,8(sp)
    80000bf2:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000bf4:	6785                	lui	a5,0x1
    80000bf6:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000bfa:	94aa                	add	s1,s1,a0
    80000bfc:	757d                	lui	a0,0xfffff
    80000bfe:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000c00:	94be                	add	s1,s1,a5
    80000c02:	0295e463          	bltu	a1,s1,80000c2a <freerange+0x48>
    80000c06:	89ae                	mv	s3,a1
    80000c08:	7afd                	lui	s5,0xfffff
    80000c0a:	6a05                	lui	s4,0x1
    80000c0c:	01548933          	add	s2,s1,s5
    add(p);
    80000c10:	854a                	mv	a0,s2
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	ebc080e7          	jalr	-324(ra) # 80000ace <add>
     kfree(p);
    80000c1a:	854a                	mv	a0,s2
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	f20080e7          	jalr	-224(ra) # 80000b3c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000c24:	94d2                	add	s1,s1,s4
    80000c26:	fe99f3e3          	bgeu	s3,s1,80000c0c <freerange+0x2a>
}
    80000c2a:	70e2                	ld	ra,56(sp)
    80000c2c:	7442                	ld	s0,48(sp)
    80000c2e:	74a2                	ld	s1,40(sp)
    80000c30:	7902                	ld	s2,32(sp)
    80000c32:	69e2                	ld	s3,24(sp)
    80000c34:	6a42                	ld	s4,16(sp)
    80000c36:	6aa2                	ld	s5,8(sp)
    80000c38:	6121                	addi	sp,sp,64
    80000c3a:	8082                	ret

0000000080000c3c <kinit>:
{
    80000c3c:	1141                	addi	sp,sp,-16
    80000c3e:	e406                	sd	ra,8(sp)
    80000c40:	e022                	sd	s0,0(sp)
    80000c42:	0800                	addi	s0,sp,16
  init();
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	dba080e7          	jalr	-582(ra) # 800009fe <init>
  initlock(&kmem.lock, "kmem");
    80000c4c:	00007597          	auipc	a1,0x7
    80000c50:	43c58593          	addi	a1,a1,1084 # 80008088 <digits+0x48>
    80000c54:	00010517          	auipc	a0,0x10
    80000c58:	1e450513          	addi	a0,a0,484 # 80010e38 <kmem>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	098080e7          	jalr	152(ra) # 80000cf4 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000c64:	45c5                	li	a1,17
    80000c66:	05ee                	slli	a1,a1,0x1b
    80000c68:	00243517          	auipc	a0,0x243
    80000c6c:	a0050513          	addi	a0,a0,-1536 # 80243668 <end>
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	f72080e7          	jalr	-142(ra) # 80000be2 <freerange>
}
    80000c78:	60a2                	ld	ra,8(sp)
    80000c7a:	6402                	ld	s0,0(sp)
    80000c7c:	0141                	addi	sp,sp,16
    80000c7e:	8082                	ret

0000000080000c80 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c80:	1101                	addi	sp,sp,-32
    80000c82:	ec06                	sd	ra,24(sp)
    80000c84:	e822                	sd	s0,16(sp)
    80000c86:	e426                	sd	s1,8(sp)
    80000c88:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000c8a:	00010517          	auipc	a0,0x10
    80000c8e:	1ae50513          	addi	a0,a0,430 # 80010e38 <kmem>
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	0f2080e7          	jalr	242(ra) # 80000d84 <acquire>
  r = kmem.freelist;
    80000c9a:	00010497          	auipc	s1,0x10
    80000c9e:	1b64b483          	ld	s1,438(s1) # 80010e50 <kmem+0x18>
  if(r)
    80000ca2:	c0a1                	beqz	s1,80000ce2 <kalloc+0x62>
    kmem.freelist = r->next;
    80000ca4:	609c                	ld	a5,0(s1)
    80000ca6:	00010717          	auipc	a4,0x10
    80000caa:	1af73523          	sd	a5,426(a4) # 80010e50 <kmem+0x18>
  release(&kmem.lock);
    80000cae:	00010517          	auipc	a0,0x10
    80000cb2:	18a50513          	addi	a0,a0,394 # 80010e38 <kmem>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	182080e7          	jalr	386(ra) # 80000e38 <release>

  if(r){
     memset((char*)r, 5, PGSIZE); // fill with junk
    80000cbe:	6605                	lui	a2,0x1
    80000cc0:	4595                	li	a1,5
    80000cc2:	8526                	mv	a0,s1
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	1bc080e7          	jalr	444(ra) # 80000e80 <memset>
    add((void*)r);
    80000ccc:	8526                	mv	a0,s1
    80000cce:	00000097          	auipc	ra,0x0
    80000cd2:	e00080e7          	jalr	-512(ra) # 80000ace <add>
  } // fill with junk
  return (void*)r;
}
    80000cd6:	8526                	mv	a0,s1
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret
  release(&kmem.lock);
    80000ce2:	00010517          	auipc	a0,0x10
    80000ce6:	15650513          	addi	a0,a0,342 # 80010e38 <kmem>
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	14e080e7          	jalr	334(ra) # 80000e38 <release>
  if(r){
    80000cf2:	b7d5                	j	80000cd6 <kalloc+0x56>

0000000080000cf4 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cfa:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cfc:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000d00:	00053823          	sd	zero,16(a0)
}
    80000d04:	6422                	ld	s0,8(sp)
    80000d06:	0141                	addi	sp,sp,16
    80000d08:	8082                	ret

0000000080000d0a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d0a:	411c                	lw	a5,0(a0)
    80000d0c:	e399                	bnez	a5,80000d12 <holding+0x8>
    80000d0e:	4501                	li	a0,0
  return r;
}
    80000d10:	8082                	ret
{
    80000d12:	1101                	addi	sp,sp,-32
    80000d14:	ec06                	sd	ra,24(sp)
    80000d16:	e822                	sd	s0,16(sp)
    80000d18:	e426                	sd	s1,8(sp)
    80000d1a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d1c:	6904                	ld	s1,16(a0)
    80000d1e:	00001097          	auipc	ra,0x1
    80000d22:	e68080e7          	jalr	-408(ra) # 80001b86 <mycpu>
    80000d26:	40a48533          	sub	a0,s1,a0
    80000d2a:	00153513          	seqz	a0,a0
}
    80000d2e:	60e2                	ld	ra,24(sp)
    80000d30:	6442                	ld	s0,16(sp)
    80000d32:	64a2                	ld	s1,8(sp)
    80000d34:	6105                	addi	sp,sp,32
    80000d36:	8082                	ret

0000000080000d38 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d38:	1101                	addi	sp,sp,-32
    80000d3a:	ec06                	sd	ra,24(sp)
    80000d3c:	e822                	sd	s0,16(sp)
    80000d3e:	e426                	sd	s1,8(sp)
    80000d40:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d42:	100024f3          	csrr	s1,sstatus
    80000d46:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d4a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d4c:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d50:	00001097          	auipc	ra,0x1
    80000d54:	e36080e7          	jalr	-458(ra) # 80001b86 <mycpu>
    80000d58:	5d3c                	lw	a5,120(a0)
    80000d5a:	cf89                	beqz	a5,80000d74 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d5c:	00001097          	auipc	ra,0x1
    80000d60:	e2a080e7          	jalr	-470(ra) # 80001b86 <mycpu>
    80000d64:	5d3c                	lw	a5,120(a0)
    80000d66:	2785                	addiw	a5,a5,1
    80000d68:	dd3c                	sw	a5,120(a0)
}
    80000d6a:	60e2                	ld	ra,24(sp)
    80000d6c:	6442                	ld	s0,16(sp)
    80000d6e:	64a2                	ld	s1,8(sp)
    80000d70:	6105                	addi	sp,sp,32
    80000d72:	8082                	ret
    mycpu()->intena = old;
    80000d74:	00001097          	auipc	ra,0x1
    80000d78:	e12080e7          	jalr	-494(ra) # 80001b86 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d7c:	8085                	srli	s1,s1,0x1
    80000d7e:	8885                	andi	s1,s1,1
    80000d80:	dd64                	sw	s1,124(a0)
    80000d82:	bfe9                	j	80000d5c <push_off+0x24>

0000000080000d84 <acquire>:
{
    80000d84:	1101                	addi	sp,sp,-32
    80000d86:	ec06                	sd	ra,24(sp)
    80000d88:	e822                	sd	s0,16(sp)
    80000d8a:	e426                	sd	s1,8(sp)
    80000d8c:	1000                	addi	s0,sp,32
    80000d8e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d90:	00000097          	auipc	ra,0x0
    80000d94:	fa8080e7          	jalr	-88(ra) # 80000d38 <push_off>
  if(holding(lk))
    80000d98:	8526                	mv	a0,s1
    80000d9a:	00000097          	auipc	ra,0x0
    80000d9e:	f70080e7          	jalr	-144(ra) # 80000d0a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000da2:	4705                	li	a4,1
  if(holding(lk))
    80000da4:	e115                	bnez	a0,80000dc8 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000da6:	87ba                	mv	a5,a4
    80000da8:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000dac:	2781                	sext.w	a5,a5
    80000dae:	ffe5                	bnez	a5,80000da6 <acquire+0x22>
  __sync_synchronize();
    80000db0:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000db4:	00001097          	auipc	ra,0x1
    80000db8:	dd2080e7          	jalr	-558(ra) # 80001b86 <mycpu>
    80000dbc:	e888                	sd	a0,16(s1)
}
    80000dbe:	60e2                	ld	ra,24(sp)
    80000dc0:	6442                	ld	s0,16(sp)
    80000dc2:	64a2                	ld	s1,8(sp)
    80000dc4:	6105                	addi	sp,sp,32
    80000dc6:	8082                	ret
    panic("acquire");
    80000dc8:	00007517          	auipc	a0,0x7
    80000dcc:	2c850513          	addi	a0,a0,712 # 80008090 <digits+0x50>
    80000dd0:	fffff097          	auipc	ra,0xfffff
    80000dd4:	774080e7          	jalr	1908(ra) # 80000544 <panic>

0000000080000dd8 <pop_off>:

void
pop_off(void)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e406                	sd	ra,8(sp)
    80000ddc:	e022                	sd	s0,0(sp)
    80000dde:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000de0:	00001097          	auipc	ra,0x1
    80000de4:	da6080e7          	jalr	-602(ra) # 80001b86 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000de8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000dec:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000dee:	e78d                	bnez	a5,80000e18 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000df0:	5d3c                	lw	a5,120(a0)
    80000df2:	02f05b63          	blez	a5,80000e28 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000df6:	37fd                	addiw	a5,a5,-1
    80000df8:	0007871b          	sext.w	a4,a5
    80000dfc:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000dfe:	eb09                	bnez	a4,80000e10 <pop_off+0x38>
    80000e00:	5d7c                	lw	a5,124(a0)
    80000e02:	c799                	beqz	a5,80000e10 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e0c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e10:	60a2                	ld	ra,8(sp)
    80000e12:	6402                	ld	s0,0(sp)
    80000e14:	0141                	addi	sp,sp,16
    80000e16:	8082                	ret
    panic("pop_off - interruptible");
    80000e18:	00007517          	auipc	a0,0x7
    80000e1c:	28050513          	addi	a0,a0,640 # 80008098 <digits+0x58>
    80000e20:	fffff097          	auipc	ra,0xfffff
    80000e24:	724080e7          	jalr	1828(ra) # 80000544 <panic>
    panic("pop_off");
    80000e28:	00007517          	auipc	a0,0x7
    80000e2c:	28850513          	addi	a0,a0,648 # 800080b0 <digits+0x70>
    80000e30:	fffff097          	auipc	ra,0xfffff
    80000e34:	714080e7          	jalr	1812(ra) # 80000544 <panic>

0000000080000e38 <release>:
{
    80000e38:	1101                	addi	sp,sp,-32
    80000e3a:	ec06                	sd	ra,24(sp)
    80000e3c:	e822                	sd	s0,16(sp)
    80000e3e:	e426                	sd	s1,8(sp)
    80000e40:	1000                	addi	s0,sp,32
    80000e42:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e44:	00000097          	auipc	ra,0x0
    80000e48:	ec6080e7          	jalr	-314(ra) # 80000d0a <holding>
    80000e4c:	c115                	beqz	a0,80000e70 <release+0x38>
  lk->cpu = 0;
    80000e4e:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e52:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e56:	0f50000f          	fence	iorw,ow
    80000e5a:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e5e:	00000097          	auipc	ra,0x0
    80000e62:	f7a080e7          	jalr	-134(ra) # 80000dd8 <pop_off>
}
    80000e66:	60e2                	ld	ra,24(sp)
    80000e68:	6442                	ld	s0,16(sp)
    80000e6a:	64a2                	ld	s1,8(sp)
    80000e6c:	6105                	addi	sp,sp,32
    80000e6e:	8082                	ret
    panic("release");
    80000e70:	00007517          	auipc	a0,0x7
    80000e74:	24850513          	addi	a0,a0,584 # 800080b8 <digits+0x78>
    80000e78:	fffff097          	auipc	ra,0xfffff
    80000e7c:	6cc080e7          	jalr	1740(ra) # 80000544 <panic>

0000000080000e80 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e80:	1141                	addi	sp,sp,-16
    80000e82:	e422                	sd	s0,8(sp)
    80000e84:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e86:	ce09                	beqz	a2,80000ea0 <memset+0x20>
    80000e88:	87aa                	mv	a5,a0
    80000e8a:	fff6071b          	addiw	a4,a2,-1
    80000e8e:	1702                	slli	a4,a4,0x20
    80000e90:	9301                	srli	a4,a4,0x20
    80000e92:	0705                	addi	a4,a4,1
    80000e94:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000e96:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e9a:	0785                	addi	a5,a5,1
    80000e9c:	fee79de3          	bne	a5,a4,80000e96 <memset+0x16>
  }
  return dst;
}
    80000ea0:	6422                	ld	s0,8(sp)
    80000ea2:	0141                	addi	sp,sp,16
    80000ea4:	8082                	ret

0000000080000ea6 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ea6:	1141                	addi	sp,sp,-16
    80000ea8:	e422                	sd	s0,8(sp)
    80000eaa:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000eac:	ca05                	beqz	a2,80000edc <memcmp+0x36>
    80000eae:	fff6069b          	addiw	a3,a2,-1
    80000eb2:	1682                	slli	a3,a3,0x20
    80000eb4:	9281                	srli	a3,a3,0x20
    80000eb6:	0685                	addi	a3,a3,1
    80000eb8:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000eba:	00054783          	lbu	a5,0(a0)
    80000ebe:	0005c703          	lbu	a4,0(a1)
    80000ec2:	00e79863          	bne	a5,a4,80000ed2 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ec6:	0505                	addi	a0,a0,1
    80000ec8:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000eca:	fed518e3          	bne	a0,a3,80000eba <memcmp+0x14>
  }

  return 0;
    80000ece:	4501                	li	a0,0
    80000ed0:	a019                	j	80000ed6 <memcmp+0x30>
      return *s1 - *s2;
    80000ed2:	40e7853b          	subw	a0,a5,a4
}
    80000ed6:	6422                	ld	s0,8(sp)
    80000ed8:	0141                	addi	sp,sp,16
    80000eda:	8082                	ret
  return 0;
    80000edc:	4501                	li	a0,0
    80000ede:	bfe5                	j	80000ed6 <memcmp+0x30>

0000000080000ee0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000ee0:	1141                	addi	sp,sp,-16
    80000ee2:	e422                	sd	s0,8(sp)
    80000ee4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000ee6:	ca0d                	beqz	a2,80000f18 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ee8:	00a5f963          	bgeu	a1,a0,80000efa <memmove+0x1a>
    80000eec:	02061693          	slli	a3,a2,0x20
    80000ef0:	9281                	srli	a3,a3,0x20
    80000ef2:	00d58733          	add	a4,a1,a3
    80000ef6:	02e56463          	bltu	a0,a4,80000f1e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000efa:	fff6079b          	addiw	a5,a2,-1
    80000efe:	1782                	slli	a5,a5,0x20
    80000f00:	9381                	srli	a5,a5,0x20
    80000f02:	0785                	addi	a5,a5,1
    80000f04:	97ae                	add	a5,a5,a1
    80000f06:	872a                	mv	a4,a0
      *d++ = *s++;
    80000f08:	0585                	addi	a1,a1,1
    80000f0a:	0705                	addi	a4,a4,1
    80000f0c:	fff5c683          	lbu	a3,-1(a1)
    80000f10:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000f14:	fef59ae3          	bne	a1,a5,80000f08 <memmove+0x28>

  return dst;
}
    80000f18:	6422                	ld	s0,8(sp)
    80000f1a:	0141                	addi	sp,sp,16
    80000f1c:	8082                	ret
    d += n;
    80000f1e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000f20:	fff6079b          	addiw	a5,a2,-1
    80000f24:	1782                	slli	a5,a5,0x20
    80000f26:	9381                	srli	a5,a5,0x20
    80000f28:	fff7c793          	not	a5,a5
    80000f2c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f2e:	177d                	addi	a4,a4,-1
    80000f30:	16fd                	addi	a3,a3,-1
    80000f32:	00074603          	lbu	a2,0(a4)
    80000f36:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f3a:	fef71ae3          	bne	a4,a5,80000f2e <memmove+0x4e>
    80000f3e:	bfe9                	j	80000f18 <memmove+0x38>

0000000080000f40 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f40:	1141                	addi	sp,sp,-16
    80000f42:	e406                	sd	ra,8(sp)
    80000f44:	e022                	sd	s0,0(sp)
    80000f46:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f48:	00000097          	auipc	ra,0x0
    80000f4c:	f98080e7          	jalr	-104(ra) # 80000ee0 <memmove>
}
    80000f50:	60a2                	ld	ra,8(sp)
    80000f52:	6402                	ld	s0,0(sp)
    80000f54:	0141                	addi	sp,sp,16
    80000f56:	8082                	ret

0000000080000f58 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f58:	1141                	addi	sp,sp,-16
    80000f5a:	e422                	sd	s0,8(sp)
    80000f5c:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f5e:	ce11                	beqz	a2,80000f7a <strncmp+0x22>
    80000f60:	00054783          	lbu	a5,0(a0)
    80000f64:	cf89                	beqz	a5,80000f7e <strncmp+0x26>
    80000f66:	0005c703          	lbu	a4,0(a1)
    80000f6a:	00f71a63          	bne	a4,a5,80000f7e <strncmp+0x26>
    n--, p++, q++;
    80000f6e:	367d                	addiw	a2,a2,-1
    80000f70:	0505                	addi	a0,a0,1
    80000f72:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f74:	f675                	bnez	a2,80000f60 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f76:	4501                	li	a0,0
    80000f78:	a809                	j	80000f8a <strncmp+0x32>
    80000f7a:	4501                	li	a0,0
    80000f7c:	a039                	j	80000f8a <strncmp+0x32>
  if(n == 0)
    80000f7e:	ca09                	beqz	a2,80000f90 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f80:	00054503          	lbu	a0,0(a0)
    80000f84:	0005c783          	lbu	a5,0(a1)
    80000f88:	9d1d                	subw	a0,a0,a5
}
    80000f8a:	6422                	ld	s0,8(sp)
    80000f8c:	0141                	addi	sp,sp,16
    80000f8e:	8082                	ret
    return 0;
    80000f90:	4501                	li	a0,0
    80000f92:	bfe5                	j	80000f8a <strncmp+0x32>

0000000080000f94 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f94:	1141                	addi	sp,sp,-16
    80000f96:	e422                	sd	s0,8(sp)
    80000f98:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f9a:	872a                	mv	a4,a0
    80000f9c:	8832                	mv	a6,a2
    80000f9e:	367d                	addiw	a2,a2,-1
    80000fa0:	01005963          	blez	a6,80000fb2 <strncpy+0x1e>
    80000fa4:	0705                	addi	a4,a4,1
    80000fa6:	0005c783          	lbu	a5,0(a1)
    80000faa:	fef70fa3          	sb	a5,-1(a4)
    80000fae:	0585                	addi	a1,a1,1
    80000fb0:	f7f5                	bnez	a5,80000f9c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000fb2:	00c05d63          	blez	a2,80000fcc <strncpy+0x38>
    80000fb6:	86ba                	mv	a3,a4
    *s++ = 0;
    80000fb8:	0685                	addi	a3,a3,1
    80000fba:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000fbe:	fff6c793          	not	a5,a3
    80000fc2:	9fb9                	addw	a5,a5,a4
    80000fc4:	010787bb          	addw	a5,a5,a6
    80000fc8:	fef048e3          	bgtz	a5,80000fb8 <strncpy+0x24>
  return os;
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fd2:	1141                	addi	sp,sp,-16
    80000fd4:	e422                	sd	s0,8(sp)
    80000fd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fd8:	02c05363          	blez	a2,80000ffe <safestrcpy+0x2c>
    80000fdc:	fff6069b          	addiw	a3,a2,-1
    80000fe0:	1682                	slli	a3,a3,0x20
    80000fe2:	9281                	srli	a3,a3,0x20
    80000fe4:	96ae                	add	a3,a3,a1
    80000fe6:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fe8:	00d58963          	beq	a1,a3,80000ffa <safestrcpy+0x28>
    80000fec:	0585                	addi	a1,a1,1
    80000fee:	0785                	addi	a5,a5,1
    80000ff0:	fff5c703          	lbu	a4,-1(a1)
    80000ff4:	fee78fa3          	sb	a4,-1(a5)
    80000ff8:	fb65                	bnez	a4,80000fe8 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ffa:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ffe:	6422                	ld	s0,8(sp)
    80001000:	0141                	addi	sp,sp,16
    80001002:	8082                	ret

0000000080001004 <strlen>:

int
strlen(const char *s)
{
    80001004:	1141                	addi	sp,sp,-16
    80001006:	e422                	sd	s0,8(sp)
    80001008:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000100a:	00054783          	lbu	a5,0(a0)
    8000100e:	cf91                	beqz	a5,8000102a <strlen+0x26>
    80001010:	0505                	addi	a0,a0,1
    80001012:	87aa                	mv	a5,a0
    80001014:	4685                	li	a3,1
    80001016:	9e89                	subw	a3,a3,a0
    80001018:	00f6853b          	addw	a0,a3,a5
    8000101c:	0785                	addi	a5,a5,1
    8000101e:	fff7c703          	lbu	a4,-1(a5)
    80001022:	fb7d                	bnez	a4,80001018 <strlen+0x14>
    ;
  return n;
}
    80001024:	6422                	ld	s0,8(sp)
    80001026:	0141                	addi	sp,sp,16
    80001028:	8082                	ret
  for(n = 0; s[n]; n++)
    8000102a:	4501                	li	a0,0
    8000102c:	bfe5                	j	80001024 <strlen+0x20>

000000008000102e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    8000102e:	1141                	addi	sp,sp,-16
    80001030:	e406                	sd	ra,8(sp)
    80001032:	e022                	sd	s0,0(sp)
    80001034:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001036:	00001097          	auipc	ra,0x1
    8000103a:	b40080e7          	jalr	-1216(ra) # 80001b76 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    8000103e:	00008717          	auipc	a4,0x8
    80001042:	b7a70713          	addi	a4,a4,-1158 # 80008bb8 <started>
  if(cpuid() == 0){
    80001046:	c139                	beqz	a0,8000108c <main+0x5e>
    while(started == 0)
    80001048:	431c                	lw	a5,0(a4)
    8000104a:	2781                	sext.w	a5,a5
    8000104c:	dff5                	beqz	a5,80001048 <main+0x1a>
      ;
    __sync_synchronize();
    8000104e:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001052:	00001097          	auipc	ra,0x1
    80001056:	b24080e7          	jalr	-1244(ra) # 80001b76 <cpuid>
    8000105a:	85aa                	mv	a1,a0
    8000105c:	00007517          	auipc	a0,0x7
    80001060:	07c50513          	addi	a0,a0,124 # 800080d8 <digits+0x98>
    80001064:	fffff097          	auipc	ra,0xfffff
    80001068:	52a080e7          	jalr	1322(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	0d8080e7          	jalr	216(ra) # 80001144 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001074:	00002097          	auipc	ra,0x2
    80001078:	b2c080e7          	jalr	-1236(ra) # 80002ba0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000107c:	00005097          	auipc	ra,0x5
    80001080:	7f4080e7          	jalr	2036(ra) # 80006870 <plicinithart>
  }

  scheduler();        
    80001084:	00001097          	auipc	ra,0x1
    80001088:	174080e7          	jalr	372(ra) # 800021f8 <scheduler>
    consoleinit();
    8000108c:	fffff097          	auipc	ra,0xfffff
    80001090:	3ca080e7          	jalr	970(ra) # 80000456 <consoleinit>
    printfinit();
    80001094:	fffff097          	auipc	ra,0xfffff
    80001098:	6e0080e7          	jalr	1760(ra) # 80000774 <printfinit>
    printf("\n");
    8000109c:	00007517          	auipc	a0,0x7
    800010a0:	04c50513          	addi	a0,a0,76 # 800080e8 <digits+0xa8>
    800010a4:	fffff097          	auipc	ra,0xfffff
    800010a8:	4ea080e7          	jalr	1258(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    800010ac:	00007517          	auipc	a0,0x7
    800010b0:	01450513          	addi	a0,a0,20 # 800080c0 <digits+0x80>
    800010b4:	fffff097          	auipc	ra,0xfffff
    800010b8:	4da080e7          	jalr	1242(ra) # 8000058e <printf>
    printf("\n");
    800010bc:	00007517          	auipc	a0,0x7
    800010c0:	02c50513          	addi	a0,a0,44 # 800080e8 <digits+0xa8>
    800010c4:	fffff097          	auipc	ra,0xfffff
    800010c8:	4ca080e7          	jalr	1226(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    800010cc:	00000097          	auipc	ra,0x0
    800010d0:	b70080e7          	jalr	-1168(ra) # 80000c3c <kinit>
    kvminit();       // create kernel page table
    800010d4:	00000097          	auipc	ra,0x0
    800010d8:	326080e7          	jalr	806(ra) # 800013fa <kvminit>
    kvminithart();   // turn on paging
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	068080e7          	jalr	104(ra) # 80001144 <kvminithart>
    procinit();      // process table
    800010e4:	00001097          	auipc	ra,0x1
    800010e8:	9de080e7          	jalr	-1570(ra) # 80001ac2 <procinit>
    trapinit();      // trap vectors
    800010ec:	00002097          	auipc	ra,0x2
    800010f0:	a8c080e7          	jalr	-1396(ra) # 80002b78 <trapinit>
    trapinithart();  // install kernel trap vector
    800010f4:	00002097          	auipc	ra,0x2
    800010f8:	aac080e7          	jalr	-1364(ra) # 80002ba0 <trapinithart>
    plicinit();      // set up interrupt controller
    800010fc:	00005097          	auipc	ra,0x5
    80001100:	75e080e7          	jalr	1886(ra) # 8000685a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001104:	00005097          	auipc	ra,0x5
    80001108:	76c080e7          	jalr	1900(ra) # 80006870 <plicinithart>
    binit();         // buffer cache
    8000110c:	00003097          	auipc	ra,0x3
    80001110:	91e080e7          	jalr	-1762(ra) # 80003a2a <binit>
    iinit();         // inode table
    80001114:	00003097          	auipc	ra,0x3
    80001118:	fc2080e7          	jalr	-62(ra) # 800040d6 <iinit>
    fileinit();      // file table
    8000111c:	00004097          	auipc	ra,0x4
    80001120:	f60080e7          	jalr	-160(ra) # 8000507c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001124:	00006097          	auipc	ra,0x6
    80001128:	854080e7          	jalr	-1964(ra) # 80006978 <virtio_disk_init>
    userinit();      // first user process
    8000112c:	00001097          	auipc	ra,0x1
    80001130:	de6080e7          	jalr	-538(ra) # 80001f12 <userinit>
    __sync_synchronize();
    80001134:	0ff0000f          	fence
    started = 1;
    80001138:	4785                	li	a5,1
    8000113a:	00008717          	auipc	a4,0x8
    8000113e:	a6f72f23          	sw	a5,-1410(a4) # 80008bb8 <started>
    80001142:	b789                	j	80001084 <main+0x56>

0000000080001144 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001144:	1141                	addi	sp,sp,-16
    80001146:	e422                	sd	s0,8(sp)
    80001148:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000114a:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000114e:	00008797          	auipc	a5,0x8
    80001152:	a727b783          	ld	a5,-1422(a5) # 80008bc0 <kernel_pagetable>
    80001156:	83b1                	srli	a5,a5,0xc
    80001158:	577d                	li	a4,-1
    8000115a:	177e                	slli	a4,a4,0x3f
    8000115c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000115e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001162:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001166:	6422                	ld	s0,8(sp)
    80001168:	0141                	addi	sp,sp,16
    8000116a:	8082                	ret

000000008000116c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000116c:	7139                	addi	sp,sp,-64
    8000116e:	fc06                	sd	ra,56(sp)
    80001170:	f822                	sd	s0,48(sp)
    80001172:	f426                	sd	s1,40(sp)
    80001174:	f04a                	sd	s2,32(sp)
    80001176:	ec4e                	sd	s3,24(sp)
    80001178:	e852                	sd	s4,16(sp)
    8000117a:	e456                	sd	s5,8(sp)
    8000117c:	e05a                	sd	s6,0(sp)
    8000117e:	0080                	addi	s0,sp,64
    80001180:	84aa                	mv	s1,a0
    80001182:	89ae                	mv	s3,a1
    80001184:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001186:	57fd                	li	a5,-1
    80001188:	83e9                	srli	a5,a5,0x1a
    8000118a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000118c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000118e:	04b7f263          	bgeu	a5,a1,800011d2 <walk+0x66>
    panic("walk");
    80001192:	00007517          	auipc	a0,0x7
    80001196:	f5e50513          	addi	a0,a0,-162 # 800080f0 <digits+0xb0>
    8000119a:	fffff097          	auipc	ra,0xfffff
    8000119e:	3aa080e7          	jalr	938(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800011a2:	060a8663          	beqz	s5,8000120e <walk+0xa2>
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	ada080e7          	jalr	-1318(ra) # 80000c80 <kalloc>
    800011ae:	84aa                	mv	s1,a0
    800011b0:	c529                	beqz	a0,800011fa <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011b2:	6605                	lui	a2,0x1
    800011b4:	4581                	li	a1,0
    800011b6:	00000097          	auipc	ra,0x0
    800011ba:	cca080e7          	jalr	-822(ra) # 80000e80 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011be:	00c4d793          	srli	a5,s1,0xc
    800011c2:	07aa                	slli	a5,a5,0xa
    800011c4:	0017e793          	ori	a5,a5,1
    800011c8:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800011cc:	3a5d                	addiw	s4,s4,-9
    800011ce:	036a0063          	beq	s4,s6,800011ee <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011d2:	0149d933          	srl	s2,s3,s4
    800011d6:	1ff97913          	andi	s2,s2,511
    800011da:	090e                	slli	s2,s2,0x3
    800011dc:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011de:	00093483          	ld	s1,0(s2)
    800011e2:	0014f793          	andi	a5,s1,1
    800011e6:	dfd5                	beqz	a5,800011a2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011e8:	80a9                	srli	s1,s1,0xa
    800011ea:	04b2                	slli	s1,s1,0xc
    800011ec:	b7c5                	j	800011cc <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011ee:	00c9d513          	srli	a0,s3,0xc
    800011f2:	1ff57513          	andi	a0,a0,511
    800011f6:	050e                	slli	a0,a0,0x3
    800011f8:	9526                	add	a0,a0,s1
}
    800011fa:	70e2                	ld	ra,56(sp)
    800011fc:	7442                	ld	s0,48(sp)
    800011fe:	74a2                	ld	s1,40(sp)
    80001200:	7902                	ld	s2,32(sp)
    80001202:	69e2                	ld	s3,24(sp)
    80001204:	6a42                	ld	s4,16(sp)
    80001206:	6aa2                	ld	s5,8(sp)
    80001208:	6b02                	ld	s6,0(sp)
    8000120a:	6121                	addi	sp,sp,64
    8000120c:	8082                	ret
        return 0;
    8000120e:	4501                	li	a0,0
    80001210:	b7ed                	j	800011fa <walk+0x8e>

0000000080001212 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001212:	57fd                	li	a5,-1
    80001214:	83e9                	srli	a5,a5,0x1a
    80001216:	00b7f463          	bgeu	a5,a1,8000121e <walkaddr+0xc>
    return 0;
    8000121a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000121c:	8082                	ret
{
    8000121e:	1141                	addi	sp,sp,-16
    80001220:	e406                	sd	ra,8(sp)
    80001222:	e022                	sd	s0,0(sp)
    80001224:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001226:	4601                	li	a2,0
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	f44080e7          	jalr	-188(ra) # 8000116c <walk>
  if(pte == 0)
    80001230:	c105                	beqz	a0,80001250 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001232:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001234:	0117f693          	andi	a3,a5,17
    80001238:	4745                	li	a4,17
    return 0;
    8000123a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000123c:	00e68663          	beq	a3,a4,80001248 <walkaddr+0x36>
}
    80001240:	60a2                	ld	ra,8(sp)
    80001242:	6402                	ld	s0,0(sp)
    80001244:	0141                	addi	sp,sp,16
    80001246:	8082                	ret
  pa = PTE2PA(*pte);
    80001248:	00a7d513          	srli	a0,a5,0xa
    8000124c:	0532                	slli	a0,a0,0xc
  return pa;
    8000124e:	bfcd                	j	80001240 <walkaddr+0x2e>
    return 0;
    80001250:	4501                	li	a0,0
    80001252:	b7fd                	j	80001240 <walkaddr+0x2e>

0000000080001254 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001254:	715d                	addi	sp,sp,-80
    80001256:	e486                	sd	ra,72(sp)
    80001258:	e0a2                	sd	s0,64(sp)
    8000125a:	fc26                	sd	s1,56(sp)
    8000125c:	f84a                	sd	s2,48(sp)
    8000125e:	f44e                	sd	s3,40(sp)
    80001260:	f052                	sd	s4,32(sp)
    80001262:	ec56                	sd	s5,24(sp)
    80001264:	e85a                	sd	s6,16(sp)
    80001266:	e45e                	sd	s7,8(sp)
    80001268:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000126a:	c205                	beqz	a2,8000128a <mappages+0x36>
    8000126c:	8aaa                	mv	s5,a0
    8000126e:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001270:	77fd                	lui	a5,0xfffff
    80001272:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001276:	15fd                	addi	a1,a1,-1
    80001278:	00c589b3          	add	s3,a1,a2
    8000127c:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001280:	8952                	mv	s2,s4
    80001282:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001286:	6b85                	lui	s7,0x1
    80001288:	a015                	j	800012ac <mappages+0x58>
    panic("mappages: size");
    8000128a:	00007517          	auipc	a0,0x7
    8000128e:	e6e50513          	addi	a0,a0,-402 # 800080f8 <digits+0xb8>
    80001292:	fffff097          	auipc	ra,0xfffff
    80001296:	2b2080e7          	jalr	690(ra) # 80000544 <panic>
      panic("mappages: remap");
    8000129a:	00007517          	auipc	a0,0x7
    8000129e:	e6e50513          	addi	a0,a0,-402 # 80008108 <digits+0xc8>
    800012a2:	fffff097          	auipc	ra,0xfffff
    800012a6:	2a2080e7          	jalr	674(ra) # 80000544 <panic>
    a += PGSIZE;
    800012aa:	995e                	add	s2,s2,s7
  for(;;){
    800012ac:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012b0:	4605                	li	a2,1
    800012b2:	85ca                	mv	a1,s2
    800012b4:	8556                	mv	a0,s5
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	eb6080e7          	jalr	-330(ra) # 8000116c <walk>
    800012be:	cd19                	beqz	a0,800012dc <mappages+0x88>
    if(*pte & PTE_V)
    800012c0:	611c                	ld	a5,0(a0)
    800012c2:	8b85                	andi	a5,a5,1
    800012c4:	fbf9                	bnez	a5,8000129a <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012c6:	80b1                	srli	s1,s1,0xc
    800012c8:	04aa                	slli	s1,s1,0xa
    800012ca:	0164e4b3          	or	s1,s1,s6
    800012ce:	0014e493          	ori	s1,s1,1
    800012d2:	e104                	sd	s1,0(a0)
    if(a == last)
    800012d4:	fd391be3          	bne	s2,s3,800012aa <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    800012d8:	4501                	li	a0,0
    800012da:	a011                	j	800012de <mappages+0x8a>
      return -1;
    800012dc:	557d                	li	a0,-1
}
    800012de:	60a6                	ld	ra,72(sp)
    800012e0:	6406                	ld	s0,64(sp)
    800012e2:	74e2                	ld	s1,56(sp)
    800012e4:	7942                	ld	s2,48(sp)
    800012e6:	79a2                	ld	s3,40(sp)
    800012e8:	7a02                	ld	s4,32(sp)
    800012ea:	6ae2                	ld	s5,24(sp)
    800012ec:	6b42                	ld	s6,16(sp)
    800012ee:	6ba2                	ld	s7,8(sp)
    800012f0:	6161                	addi	sp,sp,80
    800012f2:	8082                	ret

00000000800012f4 <kvmmap>:
{
    800012f4:	1141                	addi	sp,sp,-16
    800012f6:	e406                	sd	ra,8(sp)
    800012f8:	e022                	sd	s0,0(sp)
    800012fa:	0800                	addi	s0,sp,16
    800012fc:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012fe:	86b2                	mv	a3,a2
    80001300:	863e                	mv	a2,a5
    80001302:	00000097          	auipc	ra,0x0
    80001306:	f52080e7          	jalr	-174(ra) # 80001254 <mappages>
    8000130a:	e509                	bnez	a0,80001314 <kvmmap+0x20>
}
    8000130c:	60a2                	ld	ra,8(sp)
    8000130e:	6402                	ld	s0,0(sp)
    80001310:	0141                	addi	sp,sp,16
    80001312:	8082                	ret
    panic("kvmmap");
    80001314:	00007517          	auipc	a0,0x7
    80001318:	e0450513          	addi	a0,a0,-508 # 80008118 <digits+0xd8>
    8000131c:	fffff097          	auipc	ra,0xfffff
    80001320:	228080e7          	jalr	552(ra) # 80000544 <panic>

0000000080001324 <kvmmake>:
{
    80001324:	1101                	addi	sp,sp,-32
    80001326:	ec06                	sd	ra,24(sp)
    80001328:	e822                	sd	s0,16(sp)
    8000132a:	e426                	sd	s1,8(sp)
    8000132c:	e04a                	sd	s2,0(sp)
    8000132e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001330:	00000097          	auipc	ra,0x0
    80001334:	950080e7          	jalr	-1712(ra) # 80000c80 <kalloc>
    80001338:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000133a:	6605                	lui	a2,0x1
    8000133c:	4581                	li	a1,0
    8000133e:	00000097          	auipc	ra,0x0
    80001342:	b42080e7          	jalr	-1214(ra) # 80000e80 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001346:	4719                	li	a4,6
    80001348:	6685                	lui	a3,0x1
    8000134a:	10000637          	lui	a2,0x10000
    8000134e:	100005b7          	lui	a1,0x10000
    80001352:	8526                	mv	a0,s1
    80001354:	00000097          	auipc	ra,0x0
    80001358:	fa0080e7          	jalr	-96(ra) # 800012f4 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000135c:	4719                	li	a4,6
    8000135e:	6685                	lui	a3,0x1
    80001360:	10001637          	lui	a2,0x10001
    80001364:	100015b7          	lui	a1,0x10001
    80001368:	8526                	mv	a0,s1
    8000136a:	00000097          	auipc	ra,0x0
    8000136e:	f8a080e7          	jalr	-118(ra) # 800012f4 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001372:	4719                	li	a4,6
    80001374:	004006b7          	lui	a3,0x400
    80001378:	0c000637          	lui	a2,0xc000
    8000137c:	0c0005b7          	lui	a1,0xc000
    80001380:	8526                	mv	a0,s1
    80001382:	00000097          	auipc	ra,0x0
    80001386:	f72080e7          	jalr	-142(ra) # 800012f4 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000138a:	00007917          	auipc	s2,0x7
    8000138e:	c7690913          	addi	s2,s2,-906 # 80008000 <etext>
    80001392:	4729                	li	a4,10
    80001394:	80007697          	auipc	a3,0x80007
    80001398:	c6c68693          	addi	a3,a3,-916 # 8000 <_entry-0x7fff8000>
    8000139c:	4605                	li	a2,1
    8000139e:	067e                	slli	a2,a2,0x1f
    800013a0:	85b2                	mv	a1,a2
    800013a2:	8526                	mv	a0,s1
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	f50080e7          	jalr	-176(ra) # 800012f4 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013ac:	4719                	li	a4,6
    800013ae:	46c5                	li	a3,17
    800013b0:	06ee                	slli	a3,a3,0x1b
    800013b2:	412686b3          	sub	a3,a3,s2
    800013b6:	864a                	mv	a2,s2
    800013b8:	85ca                	mv	a1,s2
    800013ba:	8526                	mv	a0,s1
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	f38080e7          	jalr	-200(ra) # 800012f4 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013c4:	4729                	li	a4,10
    800013c6:	6685                	lui	a3,0x1
    800013c8:	00006617          	auipc	a2,0x6
    800013cc:	c3860613          	addi	a2,a2,-968 # 80007000 <_trampoline>
    800013d0:	040005b7          	lui	a1,0x4000
    800013d4:	15fd                	addi	a1,a1,-1
    800013d6:	05b2                	slli	a1,a1,0xc
    800013d8:	8526                	mv	a0,s1
    800013da:	00000097          	auipc	ra,0x0
    800013de:	f1a080e7          	jalr	-230(ra) # 800012f4 <kvmmap>
  proc_mapstacks(kpgtbl);
    800013e2:	8526                	mv	a0,s1
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	648080e7          	jalr	1608(ra) # 80001a2c <proc_mapstacks>
}
    800013ec:	8526                	mv	a0,s1
    800013ee:	60e2                	ld	ra,24(sp)
    800013f0:	6442                	ld	s0,16(sp)
    800013f2:	64a2                	ld	s1,8(sp)
    800013f4:	6902                	ld	s2,0(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret

00000000800013fa <kvminit>:
{
    800013fa:	1141                	addi	sp,sp,-16
    800013fc:	e406                	sd	ra,8(sp)
    800013fe:	e022                	sd	s0,0(sp)
    80001400:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001402:	00000097          	auipc	ra,0x0
    80001406:	f22080e7          	jalr	-222(ra) # 80001324 <kvmmake>
    8000140a:	00007797          	auipc	a5,0x7
    8000140e:	7aa7bb23          	sd	a0,1974(a5) # 80008bc0 <kernel_pagetable>
}
    80001412:	60a2                	ld	ra,8(sp)
    80001414:	6402                	ld	s0,0(sp)
    80001416:	0141                	addi	sp,sp,16
    80001418:	8082                	ret

000000008000141a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000141a:	715d                	addi	sp,sp,-80
    8000141c:	e486                	sd	ra,72(sp)
    8000141e:	e0a2                	sd	s0,64(sp)
    80001420:	fc26                	sd	s1,56(sp)
    80001422:	f84a                	sd	s2,48(sp)
    80001424:	f44e                	sd	s3,40(sp)
    80001426:	f052                	sd	s4,32(sp)
    80001428:	ec56                	sd	s5,24(sp)
    8000142a:	e85a                	sd	s6,16(sp)
    8000142c:	e45e                	sd	s7,8(sp)
    8000142e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001430:	03459793          	slli	a5,a1,0x34
    80001434:	e795                	bnez	a5,80001460 <uvmunmap+0x46>
    80001436:	8a2a                	mv	s4,a0
    80001438:	892e                	mv	s2,a1
    8000143a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000143c:	0632                	slli	a2,a2,0xc
    8000143e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001442:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001444:	6b05                	lui	s6,0x1
    80001446:	0735e863          	bltu	a1,s3,800014b6 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000144a:	60a6                	ld	ra,72(sp)
    8000144c:	6406                	ld	s0,64(sp)
    8000144e:	74e2                	ld	s1,56(sp)
    80001450:	7942                	ld	s2,48(sp)
    80001452:	79a2                	ld	s3,40(sp)
    80001454:	7a02                	ld	s4,32(sp)
    80001456:	6ae2                	ld	s5,24(sp)
    80001458:	6b42                	ld	s6,16(sp)
    8000145a:	6ba2                	ld	s7,8(sp)
    8000145c:	6161                	addi	sp,sp,80
    8000145e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001460:	00007517          	auipc	a0,0x7
    80001464:	cc050513          	addi	a0,a0,-832 # 80008120 <digits+0xe0>
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	0dc080e7          	jalr	220(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    80001470:	00007517          	auipc	a0,0x7
    80001474:	cc850513          	addi	a0,a0,-824 # 80008138 <digits+0xf8>
    80001478:	fffff097          	auipc	ra,0xfffff
    8000147c:	0cc080e7          	jalr	204(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    80001480:	00007517          	auipc	a0,0x7
    80001484:	cc850513          	addi	a0,a0,-824 # 80008148 <digits+0x108>
    80001488:	fffff097          	auipc	ra,0xfffff
    8000148c:	0bc080e7          	jalr	188(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    80001490:	00007517          	auipc	a0,0x7
    80001494:	cd050513          	addi	a0,a0,-816 # 80008160 <digits+0x120>
    80001498:	fffff097          	auipc	ra,0xfffff
    8000149c:	0ac080e7          	jalr	172(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    800014a0:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014a2:	0532                	slli	a0,a0,0xc
    800014a4:	fffff097          	auipc	ra,0xfffff
    800014a8:	698080e7          	jalr	1688(ra) # 80000b3c <kfree>
    *pte = 0;
    800014ac:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014b0:	995a                	add	s2,s2,s6
    800014b2:	f9397ce3          	bgeu	s2,s3,8000144a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014b6:	4601                	li	a2,0
    800014b8:	85ca                	mv	a1,s2
    800014ba:	8552                	mv	a0,s4
    800014bc:	00000097          	auipc	ra,0x0
    800014c0:	cb0080e7          	jalr	-848(ra) # 8000116c <walk>
    800014c4:	84aa                	mv	s1,a0
    800014c6:	d54d                	beqz	a0,80001470 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014c8:	6108                	ld	a0,0(a0)
    800014ca:	00157793          	andi	a5,a0,1
    800014ce:	dbcd                	beqz	a5,80001480 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014d0:	3ff57793          	andi	a5,a0,1023
    800014d4:	fb778ee3          	beq	a5,s7,80001490 <uvmunmap+0x76>
    if(do_free){
    800014d8:	fc0a8ae3          	beqz	s5,800014ac <uvmunmap+0x92>
    800014dc:	b7d1                	j	800014a0 <uvmunmap+0x86>

00000000800014de <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014de:	1101                	addi	sp,sp,-32
    800014e0:	ec06                	sd	ra,24(sp)
    800014e2:	e822                	sd	s0,16(sp)
    800014e4:	e426                	sd	s1,8(sp)
    800014e6:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014e8:	fffff097          	auipc	ra,0xfffff
    800014ec:	798080e7          	jalr	1944(ra) # 80000c80 <kalloc>
    800014f0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014f2:	c519                	beqz	a0,80001500 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014f4:	6605                	lui	a2,0x1
    800014f6:	4581                	li	a1,0
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	988080e7          	jalr	-1656(ra) # 80000e80 <memset>
  return pagetable;
}
    80001500:	8526                	mv	a0,s1
    80001502:	60e2                	ld	ra,24(sp)
    80001504:	6442                	ld	s0,16(sp)
    80001506:	64a2                	ld	s1,8(sp)
    80001508:	6105                	addi	sp,sp,32
    8000150a:	8082                	ret

000000008000150c <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    8000150c:	7179                	addi	sp,sp,-48
    8000150e:	f406                	sd	ra,40(sp)
    80001510:	f022                	sd	s0,32(sp)
    80001512:	ec26                	sd	s1,24(sp)
    80001514:	e84a                	sd	s2,16(sp)
    80001516:	e44e                	sd	s3,8(sp)
    80001518:	e052                	sd	s4,0(sp)
    8000151a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000151c:	6785                	lui	a5,0x1
    8000151e:	04f67863          	bgeu	a2,a5,8000156e <uvmfirst+0x62>
    80001522:	8a2a                	mv	s4,a0
    80001524:	89ae                	mv	s3,a1
    80001526:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001528:	fffff097          	auipc	ra,0xfffff
    8000152c:	758080e7          	jalr	1880(ra) # 80000c80 <kalloc>
    80001530:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001532:	6605                	lui	a2,0x1
    80001534:	4581                	li	a1,0
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	94a080e7          	jalr	-1718(ra) # 80000e80 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000153e:	4779                	li	a4,30
    80001540:	86ca                	mv	a3,s2
    80001542:	6605                	lui	a2,0x1
    80001544:	4581                	li	a1,0
    80001546:	8552                	mv	a0,s4
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	d0c080e7          	jalr	-756(ra) # 80001254 <mappages>
  memmove(mem, src, sz);
    80001550:	8626                	mv	a2,s1
    80001552:	85ce                	mv	a1,s3
    80001554:	854a                	mv	a0,s2
    80001556:	00000097          	auipc	ra,0x0
    8000155a:	98a080e7          	jalr	-1654(ra) # 80000ee0 <memmove>
}
    8000155e:	70a2                	ld	ra,40(sp)
    80001560:	7402                	ld	s0,32(sp)
    80001562:	64e2                	ld	s1,24(sp)
    80001564:	6942                	ld	s2,16(sp)
    80001566:	69a2                	ld	s3,8(sp)
    80001568:	6a02                	ld	s4,0(sp)
    8000156a:	6145                	addi	sp,sp,48
    8000156c:	8082                	ret
    panic("uvmfirst: more than a page");
    8000156e:	00007517          	auipc	a0,0x7
    80001572:	c0a50513          	addi	a0,a0,-1014 # 80008178 <digits+0x138>
    80001576:	fffff097          	auipc	ra,0xfffff
    8000157a:	fce080e7          	jalr	-50(ra) # 80000544 <panic>

000000008000157e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000157e:	1101                	addi	sp,sp,-32
    80001580:	ec06                	sd	ra,24(sp)
    80001582:	e822                	sd	s0,16(sp)
    80001584:	e426                	sd	s1,8(sp)
    80001586:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001588:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000158a:	00b67d63          	bgeu	a2,a1,800015a4 <uvmdealloc+0x26>
    8000158e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001590:	6785                	lui	a5,0x1
    80001592:	17fd                	addi	a5,a5,-1
    80001594:	00f60733          	add	a4,a2,a5
    80001598:	767d                	lui	a2,0xfffff
    8000159a:	8f71                	and	a4,a4,a2
    8000159c:	97ae                	add	a5,a5,a1
    8000159e:	8ff1                	and	a5,a5,a2
    800015a0:	00f76863          	bltu	a4,a5,800015b0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800015a4:	8526                	mv	a0,s1
    800015a6:	60e2                	ld	ra,24(sp)
    800015a8:	6442                	ld	s0,16(sp)
    800015aa:	64a2                	ld	s1,8(sp)
    800015ac:	6105                	addi	sp,sp,32
    800015ae:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015b0:	8f99                	sub	a5,a5,a4
    800015b2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015b4:	4685                	li	a3,1
    800015b6:	0007861b          	sext.w	a2,a5
    800015ba:	85ba                	mv	a1,a4
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	e5e080e7          	jalr	-418(ra) # 8000141a <uvmunmap>
    800015c4:	b7c5                	j	800015a4 <uvmdealloc+0x26>

00000000800015c6 <uvmalloc>:
  if(newsz < oldsz)
    800015c6:	0ab66563          	bltu	a2,a1,80001670 <uvmalloc+0xaa>
{
    800015ca:	7139                	addi	sp,sp,-64
    800015cc:	fc06                	sd	ra,56(sp)
    800015ce:	f822                	sd	s0,48(sp)
    800015d0:	f426                	sd	s1,40(sp)
    800015d2:	f04a                	sd	s2,32(sp)
    800015d4:	ec4e                	sd	s3,24(sp)
    800015d6:	e852                	sd	s4,16(sp)
    800015d8:	e456                	sd	s5,8(sp)
    800015da:	e05a                	sd	s6,0(sp)
    800015dc:	0080                	addi	s0,sp,64
    800015de:	8aaa                	mv	s5,a0
    800015e0:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015e2:	6985                	lui	s3,0x1
    800015e4:	19fd                	addi	s3,s3,-1
    800015e6:	95ce                	add	a1,a1,s3
    800015e8:	79fd                	lui	s3,0xfffff
    800015ea:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015ee:	08c9f363          	bgeu	s3,a2,80001674 <uvmalloc+0xae>
    800015f2:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015f4:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	688080e7          	jalr	1672(ra) # 80000c80 <kalloc>
    80001600:	84aa                	mv	s1,a0
    if(mem == 0){
    80001602:	c51d                	beqz	a0,80001630 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001604:	6605                	lui	a2,0x1
    80001606:	4581                	li	a1,0
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	878080e7          	jalr	-1928(ra) # 80000e80 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001610:	875a                	mv	a4,s6
    80001612:	86a6                	mv	a3,s1
    80001614:	6605                	lui	a2,0x1
    80001616:	85ca                	mv	a1,s2
    80001618:	8556                	mv	a0,s5
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	c3a080e7          	jalr	-966(ra) # 80001254 <mappages>
    80001622:	e90d                	bnez	a0,80001654 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001624:	6785                	lui	a5,0x1
    80001626:	993e                	add	s2,s2,a5
    80001628:	fd4968e3          	bltu	s2,s4,800015f8 <uvmalloc+0x32>
  return newsz;
    8000162c:	8552                	mv	a0,s4
    8000162e:	a809                	j	80001640 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001630:	864e                	mv	a2,s3
    80001632:	85ca                	mv	a1,s2
    80001634:	8556                	mv	a0,s5
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	f48080e7          	jalr	-184(ra) # 8000157e <uvmdealloc>
      return 0;
    8000163e:	4501                	li	a0,0
}
    80001640:	70e2                	ld	ra,56(sp)
    80001642:	7442                	ld	s0,48(sp)
    80001644:	74a2                	ld	s1,40(sp)
    80001646:	7902                	ld	s2,32(sp)
    80001648:	69e2                	ld	s3,24(sp)
    8000164a:	6a42                	ld	s4,16(sp)
    8000164c:	6aa2                	ld	s5,8(sp)
    8000164e:	6b02                	ld	s6,0(sp)
    80001650:	6121                	addi	sp,sp,64
    80001652:	8082                	ret
      kfree(mem);
    80001654:	8526                	mv	a0,s1
    80001656:	fffff097          	auipc	ra,0xfffff
    8000165a:	4e6080e7          	jalr	1254(ra) # 80000b3c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000165e:	864e                	mv	a2,s3
    80001660:	85ca                	mv	a1,s2
    80001662:	8556                	mv	a0,s5
    80001664:	00000097          	auipc	ra,0x0
    80001668:	f1a080e7          	jalr	-230(ra) # 8000157e <uvmdealloc>
      return 0;
    8000166c:	4501                	li	a0,0
    8000166e:	bfc9                	j	80001640 <uvmalloc+0x7a>
    return oldsz;
    80001670:	852e                	mv	a0,a1
}
    80001672:	8082                	ret
  return newsz;
    80001674:	8532                	mv	a0,a2
    80001676:	b7e9                	j	80001640 <uvmalloc+0x7a>

0000000080001678 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001678:	7179                	addi	sp,sp,-48
    8000167a:	f406                	sd	ra,40(sp)
    8000167c:	f022                	sd	s0,32(sp)
    8000167e:	ec26                	sd	s1,24(sp)
    80001680:	e84a                	sd	s2,16(sp)
    80001682:	e44e                	sd	s3,8(sp)
    80001684:	e052                	sd	s4,0(sp)
    80001686:	1800                	addi	s0,sp,48
    80001688:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000168a:	84aa                	mv	s1,a0
    8000168c:	6905                	lui	s2,0x1
    8000168e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001690:	4985                	li	s3,1
    80001692:	a821                	j	800016aa <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001694:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001696:	0532                	slli	a0,a0,0xc
    80001698:	00000097          	auipc	ra,0x0
    8000169c:	fe0080e7          	jalr	-32(ra) # 80001678 <freewalk>
      pagetable[i] = 0;
    800016a0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016a4:	04a1                	addi	s1,s1,8
    800016a6:	03248163          	beq	s1,s2,800016c8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800016aa:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016ac:	00f57793          	andi	a5,a0,15
    800016b0:	ff3782e3          	beq	a5,s3,80001694 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016b4:	8905                	andi	a0,a0,1
    800016b6:	d57d                	beqz	a0,800016a4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800016b8:	00007517          	auipc	a0,0x7
    800016bc:	ae050513          	addi	a0,a0,-1312 # 80008198 <digits+0x158>
    800016c0:	fffff097          	auipc	ra,0xfffff
    800016c4:	e84080e7          	jalr	-380(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    800016c8:	8552                	mv	a0,s4
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	472080e7          	jalr	1138(ra) # 80000b3c <kfree>
}
    800016d2:	70a2                	ld	ra,40(sp)
    800016d4:	7402                	ld	s0,32(sp)
    800016d6:	64e2                	ld	s1,24(sp)
    800016d8:	6942                	ld	s2,16(sp)
    800016da:	69a2                	ld	s3,8(sp)
    800016dc:	6a02                	ld	s4,0(sp)
    800016de:	6145                	addi	sp,sp,48
    800016e0:	8082                	ret

00000000800016e2 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016e2:	1101                	addi	sp,sp,-32
    800016e4:	ec06                	sd	ra,24(sp)
    800016e6:	e822                	sd	s0,16(sp)
    800016e8:	e426                	sd	s1,8(sp)
    800016ea:	1000                	addi	s0,sp,32
    800016ec:	84aa                	mv	s1,a0
  if(sz > 0)
    800016ee:	e999                	bnez	a1,80001704 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016f0:	8526                	mv	a0,s1
    800016f2:	00000097          	auipc	ra,0x0
    800016f6:	f86080e7          	jalr	-122(ra) # 80001678 <freewalk>
}
    800016fa:	60e2                	ld	ra,24(sp)
    800016fc:	6442                	ld	s0,16(sp)
    800016fe:	64a2                	ld	s1,8(sp)
    80001700:	6105                	addi	sp,sp,32
    80001702:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001704:	6605                	lui	a2,0x1
    80001706:	167d                	addi	a2,a2,-1
    80001708:	962e                	add	a2,a2,a1
    8000170a:	4685                	li	a3,1
    8000170c:	8231                	srli	a2,a2,0xc
    8000170e:	4581                	li	a1,0
    80001710:	00000097          	auipc	ra,0x0
    80001714:	d0a080e7          	jalr	-758(ra) # 8000141a <uvmunmap>
    80001718:	bfe1                	j	800016f0 <uvmfree+0xe>

000000008000171a <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    8000171a:	715d                	addi	sp,sp,-80
    8000171c:	e486                	sd	ra,72(sp)
    8000171e:	e0a2                	sd	s0,64(sp)
    80001720:	fc26                	sd	s1,56(sp)
    80001722:	f84a                	sd	s2,48(sp)
    80001724:	f44e                	sd	s3,40(sp)
    80001726:	f052                	sd	s4,32(sp)
    80001728:	ec56                	sd	s5,24(sp)
    8000172a:	e85a                	sd	s6,16(sp)
    8000172c:	e45e                	sd	s7,8(sp)
    8000172e:	0880                	addi	s0,sp,80
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    80001730:	c269                	beqz	a2,800017f2 <uvmcopy+0xd8>
    80001732:	8a2a                	mv	s4,a0
    80001734:	89ae                	mv	s3,a1
    80001736:	8932                	mv	s2,a2
    80001738:	4481                	li	s1,0
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if(flags&PTE_W){
      flags &= (~PTE_W);
      flags|=PTE_C;
      *pte = PA2PTE(pa)|flags;
    8000173a:	7afd                	lui	s5,0xfffff
    8000173c:	002ada93          	srli	s5,s5,0x2
    80001740:	a8a1                	j	80001798 <uvmcopy+0x7e>
      panic("uvmcopy: pte should exist");
    80001742:	00007517          	auipc	a0,0x7
    80001746:	a6650513          	addi	a0,a0,-1434 # 800081a8 <digits+0x168>
    8000174a:	fffff097          	auipc	ra,0xfffff
    8000174e:	dfa080e7          	jalr	-518(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    80001752:	00007517          	auipc	a0,0x7
    80001756:	a7650513          	addi	a0,a0,-1418 # 800081c8 <digits+0x188>
    8000175a:	fffff097          	auipc	ra,0xfffff
    8000175e:	dea080e7          	jalr	-534(ra) # 80000544 <panic>
      flags &= (~PTE_W);
    80001762:	3fb77693          	andi	a3,a4,1019
      flags|=PTE_C;
    80001766:	0206e713          	ori	a4,a3,32
      *pte = PA2PTE(pa)|flags;
    8000176a:	0157f7b3          	and	a5,a5,s5
    8000176e:	8fd9                	or	a5,a5,a4
    80001770:	e11c                	sd	a5,0(a0)
    }
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    80001772:	86da                	mv	a3,s6
    80001774:	6605                	lui	a2,0x1
    80001776:	85a6                	mv	a1,s1
    80001778:	854e                	mv	a0,s3
    8000177a:	00000097          	auipc	ra,0x0
    8000177e:	ada080e7          	jalr	-1318(ra) # 80001254 <mappages>
    80001782:	8baa                	mv	s7,a0
    80001784:	e129                	bnez	a0,800017c6 <uvmcopy+0xac>
       goto err;
     }
    add((void*)pa);
    80001786:	855a                	mv	a0,s6
    80001788:	fffff097          	auipc	ra,0xfffff
    8000178c:	346080e7          	jalr	838(ra) # 80000ace <add>
  for(i = 0; i < sz; i += PGSIZE){
    80001790:	6785                	lui	a5,0x1
    80001792:	94be                	add	s1,s1,a5
    80001794:	0524f363          	bgeu	s1,s2,800017da <uvmcopy+0xc0>
    if((pte = walk(old, i, 0)) == 0)
    80001798:	4601                	li	a2,0
    8000179a:	85a6                	mv	a1,s1
    8000179c:	8552                	mv	a0,s4
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	9ce080e7          	jalr	-1586(ra) # 8000116c <walk>
    800017a6:	dd51                	beqz	a0,80001742 <uvmcopy+0x28>
    if((*pte & PTE_V) == 0)
    800017a8:	611c                	ld	a5,0(a0)
    800017aa:	0017f713          	andi	a4,a5,1
    800017ae:	d355                	beqz	a4,80001752 <uvmcopy+0x38>
    pa = PTE2PA(*pte);
    800017b0:	00a7db13          	srli	s6,a5,0xa
    800017b4:	0b32                	slli	s6,s6,0xc
    flags = PTE_FLAGS(*pte);
    800017b6:	0007871b          	sext.w	a4,a5
    if(flags&PTE_W){
    800017ba:	00477693          	andi	a3,a4,4
    800017be:	f2d5                	bnez	a3,80001762 <uvmcopy+0x48>
    flags = PTE_FLAGS(*pte);
    800017c0:	3ff77713          	andi	a4,a4,1023
    800017c4:	b77d                	j	80001772 <uvmcopy+0x58>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017c6:	4685                	li	a3,1
    800017c8:	00c4d613          	srli	a2,s1,0xc
    800017cc:	4581                	li	a1,0
    800017ce:	854e                	mv	a0,s3
    800017d0:	00000097          	auipc	ra,0x0
    800017d4:	c4a080e7          	jalr	-950(ra) # 8000141a <uvmunmap>
  return -1;
    800017d8:	5bfd                	li	s7,-1
}
    800017da:	855e                	mv	a0,s7
    800017dc:	60a6                	ld	ra,72(sp)
    800017de:	6406                	ld	s0,64(sp)
    800017e0:	74e2                	ld	s1,56(sp)
    800017e2:	7942                	ld	s2,48(sp)
    800017e4:	79a2                	ld	s3,40(sp)
    800017e6:	7a02                	ld	s4,32(sp)
    800017e8:	6ae2                	ld	s5,24(sp)
    800017ea:	6b42                	ld	s6,16(sp)
    800017ec:	6ba2                	ld	s7,8(sp)
    800017ee:	6161                	addi	sp,sp,80
    800017f0:	8082                	ret
  return 0;
    800017f2:	4b81                	li	s7,0
    800017f4:	b7dd                	j	800017da <uvmcopy+0xc0>

00000000800017f6 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017f6:	1141                	addi	sp,sp,-16
    800017f8:	e406                	sd	ra,8(sp)
    800017fa:	e022                	sd	s0,0(sp)
    800017fc:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017fe:	4601                	li	a2,0
    80001800:	00000097          	auipc	ra,0x0
    80001804:	96c080e7          	jalr	-1684(ra) # 8000116c <walk>
  if(pte == 0)
    80001808:	c901                	beqz	a0,80001818 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000180a:	611c                	ld	a5,0(a0)
    8000180c:	9bbd                	andi	a5,a5,-17
    8000180e:	e11c                	sd	a5,0(a0)
}
    80001810:	60a2                	ld	ra,8(sp)
    80001812:	6402                	ld	s0,0(sp)
    80001814:	0141                	addi	sp,sp,16
    80001816:	8082                	ret
    panic("uvmclear");
    80001818:	00007517          	auipc	a0,0x7
    8000181c:	9d050513          	addi	a0,a0,-1584 # 800081e8 <digits+0x1a8>
    80001820:	fffff097          	auipc	ra,0xfffff
    80001824:	d24080e7          	jalr	-732(ra) # 80000544 <panic>

0000000080001828 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0,flags;
  pte_t *pte;
   while(len > 0){
    80001828:	c2d5                	beqz	a3,800018cc <copyout+0xa4>
{
    8000182a:	711d                	addi	sp,sp,-96
    8000182c:	ec86                	sd	ra,88(sp)
    8000182e:	e8a2                	sd	s0,80(sp)
    80001830:	e4a6                	sd	s1,72(sp)
    80001832:	e0ca                	sd	s2,64(sp)
    80001834:	fc4e                	sd	s3,56(sp)
    80001836:	f852                	sd	s4,48(sp)
    80001838:	f456                	sd	s5,40(sp)
    8000183a:	f05a                	sd	s6,32(sp)
    8000183c:	ec5e                	sd	s7,24(sp)
    8000183e:	e862                	sd	s8,16(sp)
    80001840:	e466                	sd	s9,8(sp)
    80001842:	1080                	addi	s0,sp,96
    80001844:	8baa                	mv	s7,a0
    80001846:	89ae                	mv	s3,a1
    80001848:	8b32                	mv	s6,a2
    8000184a:	8ab6                	mv	s5,a3
     va0 = PGROUNDDOWN(dstva);
    8000184c:	7cfd                	lui	s9,0xfffff
    flags=PTE_FLAGS(*pte);
    if(flags&PTE_C){
      write_trap((void*)va0,pagetable);
      pa0 = walkaddr(pagetable,va0);
    }
    n = PGSIZE - (dstva - va0);
    8000184e:	6c05                	lui	s8,0x1
    80001850:	a081                	j	80001890 <copyout+0x68>
      write_trap((void*)va0,pagetable);
    80001852:	85de                	mv	a1,s7
    80001854:	854a                	mv	a0,s2
    80001856:	00001097          	auipc	ra,0x1
    8000185a:	362080e7          	jalr	866(ra) # 80002bb8 <write_trap>
      pa0 = walkaddr(pagetable,va0);
    8000185e:	85ca                	mv	a1,s2
    80001860:	855e                	mv	a0,s7
    80001862:	00000097          	auipc	ra,0x0
    80001866:	9b0080e7          	jalr	-1616(ra) # 80001212 <walkaddr>
    8000186a:	8a2a                	mv	s4,a0
    8000186c:	a0b9                	j	800018ba <copyout+0x92>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000186e:	41298533          	sub	a0,s3,s2
    80001872:	0004861b          	sext.w	a2,s1
    80001876:	85da                	mv	a1,s6
    80001878:	9552                	add	a0,a0,s4
    8000187a:	fffff097          	auipc	ra,0xfffff
    8000187e:	666080e7          	jalr	1638(ra) # 80000ee0 <memmove>

    len -= n;
    80001882:	409a8ab3          	sub	s5,s5,s1
    src += n;
    80001886:	9b26                	add	s6,s6,s1
    dstva = va0 + PGSIZE;
    80001888:	018909b3          	add	s3,s2,s8
   while(len > 0){
    8000188c:	020a8e63          	beqz	s5,800018c8 <copyout+0xa0>
     va0 = PGROUNDDOWN(dstva);
    80001890:	0199f933          	and	s2,s3,s9
     pa0 = walkaddr(pagetable, va0);
    80001894:	85ca                	mv	a1,s2
    80001896:	855e                	mv	a0,s7
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	97a080e7          	jalr	-1670(ra) # 80001212 <walkaddr>
    800018a0:	8a2a                	mv	s4,a0
     if(pa0 == 0)
    800018a2:	c51d                	beqz	a0,800018d0 <copyout+0xa8>
    pte = walk(pagetable,va0,0);
    800018a4:	4601                	li	a2,0
    800018a6:	85ca                	mv	a1,s2
    800018a8:	855e                	mv	a0,s7
    800018aa:	00000097          	auipc	ra,0x0
    800018ae:	8c2080e7          	jalr	-1854(ra) # 8000116c <walk>
    if(flags&PTE_C){
    800018b2:	611c                	ld	a5,0(a0)
    800018b4:	0207f793          	andi	a5,a5,32
    800018b8:	ffc9                	bnez	a5,80001852 <copyout+0x2a>
    n = PGSIZE - (dstva - va0);
    800018ba:	413904b3          	sub	s1,s2,s3
    800018be:	94e2                	add	s1,s1,s8
    if(n > len)
    800018c0:	fa9af7e3          	bgeu	s5,s1,8000186e <copyout+0x46>
    800018c4:	84d6                	mv	s1,s5
    800018c6:	b765                	j	8000186e <copyout+0x46>
  }
  return 0;
    800018c8:	4501                	li	a0,0
    800018ca:	a021                	j	800018d2 <copyout+0xaa>
    800018cc:	4501                	li	a0,0
}
    800018ce:	8082                	ret
       return -1;
    800018d0:	557d                	li	a0,-1
}
    800018d2:	60e6                	ld	ra,88(sp)
    800018d4:	6446                	ld	s0,80(sp)
    800018d6:	64a6                	ld	s1,72(sp)
    800018d8:	6906                	ld	s2,64(sp)
    800018da:	79e2                	ld	s3,56(sp)
    800018dc:	7a42                	ld	s4,48(sp)
    800018de:	7aa2                	ld	s5,40(sp)
    800018e0:	7b02                	ld	s6,32(sp)
    800018e2:	6be2                	ld	s7,24(sp)
    800018e4:	6c42                	ld	s8,16(sp)
    800018e6:	6ca2                	ld	s9,8(sp)
    800018e8:	6125                	addi	sp,sp,96
    800018ea:	8082                	ret

00000000800018ec <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018ec:	c6bd                	beqz	a3,8000195a <copyin+0x6e>
{
    800018ee:	715d                	addi	sp,sp,-80
    800018f0:	e486                	sd	ra,72(sp)
    800018f2:	e0a2                	sd	s0,64(sp)
    800018f4:	fc26                	sd	s1,56(sp)
    800018f6:	f84a                	sd	s2,48(sp)
    800018f8:	f44e                	sd	s3,40(sp)
    800018fa:	f052                	sd	s4,32(sp)
    800018fc:	ec56                	sd	s5,24(sp)
    800018fe:	e85a                	sd	s6,16(sp)
    80001900:	e45e                	sd	s7,8(sp)
    80001902:	e062                	sd	s8,0(sp)
    80001904:	0880                	addi	s0,sp,80
    80001906:	8b2a                	mv	s6,a0
    80001908:	8a2e                	mv	s4,a1
    8000190a:	8c32                	mv	s8,a2
    8000190c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000190e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001910:	6a85                	lui	s5,0x1
    80001912:	a015                	j	80001936 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001914:	9562                	add	a0,a0,s8
    80001916:	0004861b          	sext.w	a2,s1
    8000191a:	412505b3          	sub	a1,a0,s2
    8000191e:	8552                	mv	a0,s4
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	5c0080e7          	jalr	1472(ra) # 80000ee0 <memmove>

    len -= n;
    80001928:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000192c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000192e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001932:	02098263          	beqz	s3,80001956 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001936:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000193a:	85ca                	mv	a1,s2
    8000193c:	855a                	mv	a0,s6
    8000193e:	00000097          	auipc	ra,0x0
    80001942:	8d4080e7          	jalr	-1836(ra) # 80001212 <walkaddr>
    if(pa0 == 0)
    80001946:	cd01                	beqz	a0,8000195e <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001948:	418904b3          	sub	s1,s2,s8
    8000194c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000194e:	fc99f3e3          	bgeu	s3,s1,80001914 <copyin+0x28>
    80001952:	84ce                	mv	s1,s3
    80001954:	b7c1                	j	80001914 <copyin+0x28>
  }
  return 0;
    80001956:	4501                	li	a0,0
    80001958:	a021                	j	80001960 <copyin+0x74>
    8000195a:	4501                	li	a0,0
}
    8000195c:	8082                	ret
      return -1;
    8000195e:	557d                	li	a0,-1
}
    80001960:	60a6                	ld	ra,72(sp)
    80001962:	6406                	ld	s0,64(sp)
    80001964:	74e2                	ld	s1,56(sp)
    80001966:	7942                	ld	s2,48(sp)
    80001968:	79a2                	ld	s3,40(sp)
    8000196a:	7a02                	ld	s4,32(sp)
    8000196c:	6ae2                	ld	s5,24(sp)
    8000196e:	6b42                	ld	s6,16(sp)
    80001970:	6ba2                	ld	s7,8(sp)
    80001972:	6c02                	ld	s8,0(sp)
    80001974:	6161                	addi	sp,sp,80
    80001976:	8082                	ret

0000000080001978 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001978:	c6c5                	beqz	a3,80001a20 <copyinstr+0xa8>
{
    8000197a:	715d                	addi	sp,sp,-80
    8000197c:	e486                	sd	ra,72(sp)
    8000197e:	e0a2                	sd	s0,64(sp)
    80001980:	fc26                	sd	s1,56(sp)
    80001982:	f84a                	sd	s2,48(sp)
    80001984:	f44e                	sd	s3,40(sp)
    80001986:	f052                	sd	s4,32(sp)
    80001988:	ec56                	sd	s5,24(sp)
    8000198a:	e85a                	sd	s6,16(sp)
    8000198c:	e45e                	sd	s7,8(sp)
    8000198e:	0880                	addi	s0,sp,80
    80001990:	8a2a                	mv	s4,a0
    80001992:	8b2e                	mv	s6,a1
    80001994:	8bb2                	mv	s7,a2
    80001996:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001998:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000199a:	6985                	lui	s3,0x1
    8000199c:	a035                	j	800019c8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000199e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800019a2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800019a4:	0017b793          	seqz	a5,a5
    800019a8:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800019ac:	60a6                	ld	ra,72(sp)
    800019ae:	6406                	ld	s0,64(sp)
    800019b0:	74e2                	ld	s1,56(sp)
    800019b2:	7942                	ld	s2,48(sp)
    800019b4:	79a2                	ld	s3,40(sp)
    800019b6:	7a02                	ld	s4,32(sp)
    800019b8:	6ae2                	ld	s5,24(sp)
    800019ba:	6b42                	ld	s6,16(sp)
    800019bc:	6ba2                	ld	s7,8(sp)
    800019be:	6161                	addi	sp,sp,80
    800019c0:	8082                	ret
    srcva = va0 + PGSIZE;
    800019c2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800019c6:	c8a9                	beqz	s1,80001a18 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800019c8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019cc:	85ca                	mv	a1,s2
    800019ce:	8552                	mv	a0,s4
    800019d0:	00000097          	auipc	ra,0x0
    800019d4:	842080e7          	jalr	-1982(ra) # 80001212 <walkaddr>
    if(pa0 == 0)
    800019d8:	c131                	beqz	a0,80001a1c <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800019da:	41790833          	sub	a6,s2,s7
    800019de:	984e                	add	a6,a6,s3
    if(n > max)
    800019e0:	0104f363          	bgeu	s1,a6,800019e6 <copyinstr+0x6e>
    800019e4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019e6:	955e                	add	a0,a0,s7
    800019e8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019ec:	fc080be3          	beqz	a6,800019c2 <copyinstr+0x4a>
    800019f0:	985a                	add	a6,a6,s6
    800019f2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019f4:	41650633          	sub	a2,a0,s6
    800019f8:	14fd                	addi	s1,s1,-1
    800019fa:	9b26                	add	s6,s6,s1
    800019fc:	00f60733          	add	a4,a2,a5
    80001a00:	00074703          	lbu	a4,0(a4)
    80001a04:	df49                	beqz	a4,8000199e <copyinstr+0x26>
        *dst = *p;
    80001a06:	00e78023          	sb	a4,0(a5)
      --max;
    80001a0a:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001a0e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a10:	ff0796e3          	bne	a5,a6,800019fc <copyinstr+0x84>
      dst++;
    80001a14:	8b42                	mv	s6,a6
    80001a16:	b775                	j	800019c2 <copyinstr+0x4a>
    80001a18:	4781                	li	a5,0
    80001a1a:	b769                	j	800019a4 <copyinstr+0x2c>
      return -1;
    80001a1c:	557d                	li	a0,-1
    80001a1e:	b779                	j	800019ac <copyinstr+0x34>
  int got_null = 0;
    80001a20:	4781                	li	a5,0
  if(got_null){
    80001a22:	0017b793          	seqz	a5,a5
    80001a26:	40f00533          	neg	a0,a5
}
    80001a2a:	8082                	ret

0000000080001a2c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a2c:	7139                	addi	sp,sp,-64
    80001a2e:	fc06                	sd	ra,56(sp)
    80001a30:	f822                	sd	s0,48(sp)
    80001a32:	f426                	sd	s1,40(sp)
    80001a34:	f04a                	sd	s2,32(sp)
    80001a36:	ec4e                	sd	s3,24(sp)
    80001a38:	e852                	sd	s4,16(sp)
    80001a3a:	e456                	sd	s5,8(sp)
    80001a3c:	e05a                	sd	s6,0(sp)
    80001a3e:	0080                	addi	s0,sp,64
    80001a40:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001a42:	00230497          	auipc	s1,0x230
    80001a46:	84648493          	addi	s1,s1,-1978 # 80231288 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001a4a:	8b26                	mv	s6,s1
    80001a4c:	00006a97          	auipc	s5,0x6
    80001a50:	5b4a8a93          	addi	s5,s5,1460 # 80008000 <etext>
    80001a54:	04000937          	lui	s2,0x4000
    80001a58:	197d                	addi	s2,s2,-1
    80001a5a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a5c:	00237a17          	auipc	s4,0x237
    80001a60:	82ca0a13          	addi	s4,s4,-2004 # 80238288 <tickslock>
    char *pa = kalloc();
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	21c080e7          	jalr	540(ra) # 80000c80 <kalloc>
    80001a6c:	862a                	mv	a2,a0
    if (pa == 0)
    80001a6e:	c131                	beqz	a0,80001ab2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001a70:	416485b3          	sub	a1,s1,s6
    80001a74:	8599                	srai	a1,a1,0x6
    80001a76:	000ab783          	ld	a5,0(s5)
    80001a7a:	02f585b3          	mul	a1,a1,a5
    80001a7e:	2585                	addiw	a1,a1,1
    80001a80:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a84:	4719                	li	a4,6
    80001a86:	6685                	lui	a3,0x1
    80001a88:	40b905b3          	sub	a1,s2,a1
    80001a8c:	854e                	mv	a0,s3
    80001a8e:	00000097          	auipc	ra,0x0
    80001a92:	866080e7          	jalr	-1946(ra) # 800012f4 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a96:	1c048493          	addi	s1,s1,448
    80001a9a:	fd4495e3          	bne	s1,s4,80001a64 <proc_mapstacks+0x38>
  }
}
    80001a9e:	70e2                	ld	ra,56(sp)
    80001aa0:	7442                	ld	s0,48(sp)
    80001aa2:	74a2                	ld	s1,40(sp)
    80001aa4:	7902                	ld	s2,32(sp)
    80001aa6:	69e2                	ld	s3,24(sp)
    80001aa8:	6a42                	ld	s4,16(sp)
    80001aaa:	6aa2                	ld	s5,8(sp)
    80001aac:	6b02                	ld	s6,0(sp)
    80001aae:	6121                	addi	sp,sp,64
    80001ab0:	8082                	ret
      panic("kalloc");
    80001ab2:	00006517          	auipc	a0,0x6
    80001ab6:	74650513          	addi	a0,a0,1862 # 800081f8 <digits+0x1b8>
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	a8a080e7          	jalr	-1398(ra) # 80000544 <panic>

0000000080001ac2 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001ac2:	7139                	addi	sp,sp,-64
    80001ac4:	fc06                	sd	ra,56(sp)
    80001ac6:	f822                	sd	s0,48(sp)
    80001ac8:	f426                	sd	s1,40(sp)
    80001aca:	f04a                	sd	s2,32(sp)
    80001acc:	ec4e                	sd	s3,24(sp)
    80001ace:	e852                	sd	s4,16(sp)
    80001ad0:	e456                	sd	s5,8(sp)
    80001ad2:	e05a                	sd	s6,0(sp)
    80001ad4:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001ad6:	00006597          	auipc	a1,0x6
    80001ada:	72a58593          	addi	a1,a1,1834 # 80008200 <digits+0x1c0>
    80001ade:	0022f517          	auipc	a0,0x22f
    80001ae2:	37a50513          	addi	a0,a0,890 # 80230e58 <pid_lock>
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	20e080e7          	jalr	526(ra) # 80000cf4 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001aee:	00006597          	auipc	a1,0x6
    80001af2:	71a58593          	addi	a1,a1,1818 # 80008208 <digits+0x1c8>
    80001af6:	0022f517          	auipc	a0,0x22f
    80001afa:	37a50513          	addi	a0,a0,890 # 80230e70 <wait_lock>
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	1f6080e7          	jalr	502(ra) # 80000cf4 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001b06:	0022f497          	auipc	s1,0x22f
    80001b0a:	78248493          	addi	s1,s1,1922 # 80231288 <proc>
  {
    initlock(&p->lock, "proc");
    80001b0e:	00006b17          	auipc	s6,0x6
    80001b12:	70ab0b13          	addi	s6,s6,1802 # 80008218 <digits+0x1d8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001b16:	8aa6                	mv	s5,s1
    80001b18:	00006a17          	auipc	s4,0x6
    80001b1c:	4e8a0a13          	addi	s4,s4,1256 # 80008000 <etext>
    80001b20:	04000937          	lui	s2,0x4000
    80001b24:	197d                	addi	s2,s2,-1
    80001b26:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001b28:	00236997          	auipc	s3,0x236
    80001b2c:	76098993          	addi	s3,s3,1888 # 80238288 <tickslock>
    initlock(&p->lock, "proc");
    80001b30:	85da                	mv	a1,s6
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	1c0080e7          	jalr	448(ra) # 80000cf4 <initlock>
    p->state = UNUSED;
    80001b3c:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001b40:	415487b3          	sub	a5,s1,s5
    80001b44:	8799                	srai	a5,a5,0x6
    80001b46:	000a3703          	ld	a4,0(s4)
    80001b4a:	02e787b3          	mul	a5,a5,a4
    80001b4e:	2785                	addiw	a5,a5,1
    80001b50:	00d7979b          	slliw	a5,a5,0xd
    80001b54:	40f907b3          	sub	a5,s2,a5
    80001b58:	fcbc                	sd	a5,120(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001b5a:	1c048493          	addi	s1,s1,448
    80001b5e:	fd3499e3          	bne	s1,s3,80001b30 <procinit+0x6e>
  }
}
    80001b62:	70e2                	ld	ra,56(sp)
    80001b64:	7442                	ld	s0,48(sp)
    80001b66:	74a2                	ld	s1,40(sp)
    80001b68:	7902                	ld	s2,32(sp)
    80001b6a:	69e2                	ld	s3,24(sp)
    80001b6c:	6a42                	ld	s4,16(sp)
    80001b6e:	6aa2                	ld	s5,8(sp)
    80001b70:	6b02                	ld	s6,0(sp)
    80001b72:	6121                	addi	sp,sp,64
    80001b74:	8082                	ret

0000000080001b76 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b76:	1141                	addi	sp,sp,-16
    80001b78:	e422                	sd	s0,8(sp)
    80001b7a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b7c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b7e:	2501                	sext.w	a0,a0
    80001b80:	6422                	ld	s0,8(sp)
    80001b82:	0141                	addi	sp,sp,16
    80001b84:	8082                	ret

0000000080001b86 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b86:	1141                	addi	sp,sp,-16
    80001b88:	e422                	sd	s0,8(sp)
    80001b8a:	0800                	addi	s0,sp,16
    80001b8c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b8e:	2781                	sext.w	a5,a5
    80001b90:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b92:	0022f517          	auipc	a0,0x22f
    80001b96:	2f650513          	addi	a0,a0,758 # 80230e88 <cpus>
    80001b9a:	953e                	add	a0,a0,a5
    80001b9c:	6422                	ld	s0,8(sp)
    80001b9e:	0141                	addi	sp,sp,16
    80001ba0:	8082                	ret

0000000080001ba2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001ba2:	1101                	addi	sp,sp,-32
    80001ba4:	ec06                	sd	ra,24(sp)
    80001ba6:	e822                	sd	s0,16(sp)
    80001ba8:	e426                	sd	s1,8(sp)
    80001baa:	1000                	addi	s0,sp,32
  push_off();
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	18c080e7          	jalr	396(ra) # 80000d38 <push_off>
    80001bb4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001bb6:	2781                	sext.w	a5,a5
    80001bb8:	079e                	slli	a5,a5,0x7
    80001bba:	0022f717          	auipc	a4,0x22f
    80001bbe:	29e70713          	addi	a4,a4,670 # 80230e58 <pid_lock>
    80001bc2:	97ba                	add	a5,a5,a4
    80001bc4:	7b84                	ld	s1,48(a5)
  pop_off();
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	212080e7          	jalr	530(ra) # 80000dd8 <pop_off>
  return p;
}
    80001bce:	8526                	mv	a0,s1
    80001bd0:	60e2                	ld	ra,24(sp)
    80001bd2:	6442                	ld	s0,16(sp)
    80001bd4:	64a2                	ld	s1,8(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bda:	1141                	addi	sp,sp,-16
    80001bdc:	e406                	sd	ra,8(sp)
    80001bde:	e022                	sd	s0,0(sp)
    80001be0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	fc0080e7          	jalr	-64(ra) # 80001ba2 <myproc>
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	24e080e7          	jalr	590(ra) # 80000e38 <release>

  if (first)
    80001bf2:	00007797          	auipc	a5,0x7
    80001bf6:	dde7a783          	lw	a5,-546(a5) # 800089d0 <first.1739>
    80001bfa:	eb89                	bnez	a5,80001c0c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001bfc:	00001097          	auipc	ra,0x1
    80001c00:	07a080e7          	jalr	122(ra) # 80002c76 <usertrapret>
}
    80001c04:	60a2                	ld	ra,8(sp)
    80001c06:	6402                	ld	s0,0(sp)
    80001c08:	0141                	addi	sp,sp,16
    80001c0a:	8082                	ret
    first = 0;
    80001c0c:	00007797          	auipc	a5,0x7
    80001c10:	dc07a223          	sw	zero,-572(a5) # 800089d0 <first.1739>
    fsinit(ROOTDEV);
    80001c14:	4505                	li	a0,1
    80001c16:	00002097          	auipc	ra,0x2
    80001c1a:	440080e7          	jalr	1088(ra) # 80004056 <fsinit>
    80001c1e:	bff9                	j	80001bfc <forkret+0x22>

0000000080001c20 <allocpid>:
{
    80001c20:	1101                	addi	sp,sp,-32
    80001c22:	ec06                	sd	ra,24(sp)
    80001c24:	e822                	sd	s0,16(sp)
    80001c26:	e426                	sd	s1,8(sp)
    80001c28:	e04a                	sd	s2,0(sp)
    80001c2a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c2c:	0022f917          	auipc	s2,0x22f
    80001c30:	22c90913          	addi	s2,s2,556 # 80230e58 <pid_lock>
    80001c34:	854a                	mv	a0,s2
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	14e080e7          	jalr	334(ra) # 80000d84 <acquire>
  pid = nextpid;
    80001c3e:	00007797          	auipc	a5,0x7
    80001c42:	da278793          	addi	a5,a5,-606 # 800089e0 <nextpid>
    80001c46:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c48:	0014871b          	addiw	a4,s1,1
    80001c4c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c4e:	854a                	mv	a0,s2
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	1e8080e7          	jalr	488(ra) # 80000e38 <release>
}
    80001c58:	8526                	mv	a0,s1
    80001c5a:	60e2                	ld	ra,24(sp)
    80001c5c:	6442                	ld	s0,16(sp)
    80001c5e:	64a2                	ld	s1,8(sp)
    80001c60:	6902                	ld	s2,0(sp)
    80001c62:	6105                	addi	sp,sp,32
    80001c64:	8082                	ret

0000000080001c66 <proc_pagetable>:
{
    80001c66:	1101                	addi	sp,sp,-32
    80001c68:	ec06                	sd	ra,24(sp)
    80001c6a:	e822                	sd	s0,16(sp)
    80001c6c:	e426                	sd	s1,8(sp)
    80001c6e:	e04a                	sd	s2,0(sp)
    80001c70:	1000                	addi	s0,sp,32
    80001c72:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	86a080e7          	jalr	-1942(ra) # 800014de <uvmcreate>
    80001c7c:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001c7e:	c121                	beqz	a0,80001cbe <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c80:	4729                	li	a4,10
    80001c82:	00005697          	auipc	a3,0x5
    80001c86:	37e68693          	addi	a3,a3,894 # 80007000 <_trampoline>
    80001c8a:	6605                	lui	a2,0x1
    80001c8c:	040005b7          	lui	a1,0x4000
    80001c90:	15fd                	addi	a1,a1,-1
    80001c92:	05b2                	slli	a1,a1,0xc
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	5c0080e7          	jalr	1472(ra) # 80001254 <mappages>
    80001c9c:	02054863          	bltz	a0,80001ccc <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ca0:	4719                	li	a4,6
    80001ca2:	09093683          	ld	a3,144(s2)
    80001ca6:	6605                	lui	a2,0x1
    80001ca8:	020005b7          	lui	a1,0x2000
    80001cac:	15fd                	addi	a1,a1,-1
    80001cae:	05b6                	slli	a1,a1,0xd
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	5a2080e7          	jalr	1442(ra) # 80001254 <mappages>
    80001cba:	02054163          	bltz	a0,80001cdc <proc_pagetable+0x76>
}
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	60e2                	ld	ra,24(sp)
    80001cc2:	6442                	ld	s0,16(sp)
    80001cc4:	64a2                	ld	s1,8(sp)
    80001cc6:	6902                	ld	s2,0(sp)
    80001cc8:	6105                	addi	sp,sp,32
    80001cca:	8082                	ret
    uvmfree(pagetable, 0);
    80001ccc:	4581                	li	a1,0
    80001cce:	8526                	mv	a0,s1
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	a12080e7          	jalr	-1518(ra) # 800016e2 <uvmfree>
    return 0;
    80001cd8:	4481                	li	s1,0
    80001cda:	b7d5                	j	80001cbe <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cdc:	4681                	li	a3,0
    80001cde:	4605                	li	a2,1
    80001ce0:	040005b7          	lui	a1,0x4000
    80001ce4:	15fd                	addi	a1,a1,-1
    80001ce6:	05b2                	slli	a1,a1,0xc
    80001ce8:	8526                	mv	a0,s1
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	730080e7          	jalr	1840(ra) # 8000141a <uvmunmap>
    uvmfree(pagetable, 0);
    80001cf2:	4581                	li	a1,0
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	9ec080e7          	jalr	-1556(ra) # 800016e2 <uvmfree>
    return 0;
    80001cfe:	4481                	li	s1,0
    80001d00:	bf7d                	j	80001cbe <proc_pagetable+0x58>

0000000080001d02 <proc_freepagetable>:
{
    80001d02:	1101                	addi	sp,sp,-32
    80001d04:	ec06                	sd	ra,24(sp)
    80001d06:	e822                	sd	s0,16(sp)
    80001d08:	e426                	sd	s1,8(sp)
    80001d0a:	e04a                	sd	s2,0(sp)
    80001d0c:	1000                	addi	s0,sp,32
    80001d0e:	84aa                	mv	s1,a0
    80001d10:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d12:	4681                	li	a3,0
    80001d14:	4605                	li	a2,1
    80001d16:	040005b7          	lui	a1,0x4000
    80001d1a:	15fd                	addi	a1,a1,-1
    80001d1c:	05b2                	slli	a1,a1,0xc
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	6fc080e7          	jalr	1788(ra) # 8000141a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d26:	4681                	li	a3,0
    80001d28:	4605                	li	a2,1
    80001d2a:	020005b7          	lui	a1,0x2000
    80001d2e:	15fd                	addi	a1,a1,-1
    80001d30:	05b6                	slli	a1,a1,0xd
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	6e6080e7          	jalr	1766(ra) # 8000141a <uvmunmap>
  uvmfree(pagetable, sz);
    80001d3c:	85ca                	mv	a1,s2
    80001d3e:	8526                	mv	a0,s1
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	9a2080e7          	jalr	-1630(ra) # 800016e2 <uvmfree>
}
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6902                	ld	s2,0(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret

0000000080001d54 <freeproc>:
{
    80001d54:	1101                	addi	sp,sp,-32
    80001d56:	ec06                	sd	ra,24(sp)
    80001d58:	e822                	sd	s0,16(sp)
    80001d5a:	e426                	sd	s1,8(sp)
    80001d5c:	1000                	addi	s0,sp,32
    80001d5e:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001d60:	6948                	ld	a0,144(a0)
    80001d62:	c509                	beqz	a0,80001d6c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	dd8080e7          	jalr	-552(ra) # 80000b3c <kfree>
  p->trapframe = 0;
    80001d6c:	0804b823          	sd	zero,144(s1)
  if (p->copy)
    80001d70:	6cc8                	ld	a0,152(s1)
    80001d72:	c509                	beqz	a0,80001d7c <freeproc+0x28>
    kfree((void *)p->copy);
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	dc8080e7          	jalr	-568(ra) # 80000b3c <kfree>
  p->copy = 0;
    80001d7c:	0804bc23          	sd	zero,152(s1)
  if (p->pagetable)
    80001d80:	64c8                	ld	a0,136(s1)
    80001d82:	c511                	beqz	a0,80001d8e <freeproc+0x3a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d84:	60cc                	ld	a1,128(s1)
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	f7c080e7          	jalr	-132(ra) # 80001d02 <proc_freepagetable>
  p->pagetable = 0;
    80001d8e:	0804b423          	sd	zero,136(s1)
  p->sz = 0;
    80001d92:	0804b023          	sd	zero,128(s1)
  p->pid = 0;
    80001d96:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d9a:	0604b823          	sd	zero,112(s1)
  p->name[0] = 0;
    80001d9e:	18048c23          	sb	zero,408(s1)
  p->chan = 0;
    80001da2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001da6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001daa:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001dae:	0004ac23          	sw	zero,24(s1)
  p->ticks = 0;
    80001db2:	0204ae23          	sw	zero,60(s1)
  p->ticks_after = 0;
    80001db6:	0404a023          	sw	zero,64(s1)
  p->trace_mask = 0;
    80001dba:	0204aa23          	sw	zero,52(s1)
  p->alarm = 0;
    80001dbe:	0204ac23          	sw	zero,56(s1)
  p->handler = 0;
    80001dc2:	0604b023          	sd	zero,96(s1)
  p->trtime = 0;
    80001dc6:	0404a623          	sw	zero,76(s1)
  p->twtime = 0;
    80001dca:	0404a823          	sw	zero,80(s1)
  p->endtime = 0;
    80001dce:	0404ae23          	sw	zero,92(s1)
  p->queue_level = 0;
    80001dd2:	1a04a823          	sw	zero,432(s1)
  p->last_exec = 0;
    80001dd6:	1a04ac23          	sw	zero,440(s1)
}
    80001dda:	60e2                	ld	ra,24(sp)
    80001ddc:	6442                	ld	s0,16(sp)
    80001dde:	64a2                	ld	s1,8(sp)
    80001de0:	6105                	addi	sp,sp,32
    80001de2:	8082                	ret

0000000080001de4 <allocproc>:
{
    80001de4:	1101                	addi	sp,sp,-32
    80001de6:	ec06                	sd	ra,24(sp)
    80001de8:	e822                	sd	s0,16(sp)
    80001dea:	e426                	sd	s1,8(sp)
    80001dec:	e04a                	sd	s2,0(sp)
    80001dee:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001df0:	0022f497          	auipc	s1,0x22f
    80001df4:	49848493          	addi	s1,s1,1176 # 80231288 <proc>
    80001df8:	00236917          	auipc	s2,0x236
    80001dfc:	49090913          	addi	s2,s2,1168 # 80238288 <tickslock>
    acquire(&p->lock);
    80001e00:	8526                	mv	a0,s1
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	f82080e7          	jalr	-126(ra) # 80000d84 <acquire>
    if (p->state == UNUSED)
    80001e0a:	4c9c                	lw	a5,24(s1)
    80001e0c:	cf81                	beqz	a5,80001e24 <allocproc+0x40>
      release(&p->lock);
    80001e0e:	8526                	mv	a0,s1
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	028080e7          	jalr	40(ra) # 80000e38 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001e18:	1c048493          	addi	s1,s1,448
    80001e1c:	ff2492e3          	bne	s1,s2,80001e00 <allocproc+0x1c>
  return 0;
    80001e20:	4481                	li	s1,0
    80001e22:	a869                	j	80001ebc <allocproc+0xd8>
  p->pid = allocpid();
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	dfc080e7          	jalr	-516(ra) # 80001c20 <allocpid>
    80001e2c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e2e:	4785                	li	a5,1
    80001e30:	cc9c                	sw	a5,24(s1)
  p->trace_mask = 0;
    80001e32:	0204aa23          	sw	zero,52(s1)
  p->alarm = 0;
    80001e36:	0204ac23          	sw	zero,56(s1)
  p->ticks = 0;
    80001e3a:	0204ae23          	sw	zero,60(s1)
  p->ticks_after = 0;
    80001e3e:	0404a023          	sw	zero,64(s1)
  p->trtime = 0;
    80001e42:	0404a623          	sw	zero,76(s1)
  p->twtime = 0;
    80001e46:	0404a823          	sw	zero,80(s1)
  p->intime = ticks;
    80001e4a:	00007797          	auipc	a5,0x7
    80001e4e:	d8a7a783          	lw	a5,-630(a5) # 80008bd4 <ticks>
    80001e52:	0007871b          	sext.w	a4,a5
    80001e56:	ccb8                	sw	a4,88(s1)
  p->in_time = ticks;
    80001e58:	1782                	slli	a5,a5,0x20
    80001e5a:	9381                	srli	a5,a5,0x20
    80001e5c:	1af4b423          	sd	a5,424(s1)
  p->tick_ctr = 0;
    80001e60:	1a04aa23          	sw	zero,436(s1)
  p->queue_level = 0;
    80001e64:	1a04a823          	sw	zero,432(s1)
  p->last_exec = ticks;
    80001e68:	1ae4ac23          	sw	a4,440(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e14080e7          	jalr	-492(ra) # 80000c80 <kalloc>
    80001e74:	892a                	mv	s2,a0
    80001e76:	e8c8                	sd	a0,144(s1)
    80001e78:	c929                	beqz	a0,80001eca <allocproc+0xe6>
  if ((p->copy = (struct trapframe *)kalloc()) == 0)
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	e06080e7          	jalr	-506(ra) # 80000c80 <kalloc>
    80001e82:	892a                	mv	s2,a0
    80001e84:	ecc8                	sd	a0,152(s1)
    80001e86:	cd31                	beqz	a0,80001ee2 <allocproc+0xfe>
  p->pagetable = proc_pagetable(p);
    80001e88:	8526                	mv	a0,s1
    80001e8a:	00000097          	auipc	ra,0x0
    80001e8e:	ddc080e7          	jalr	-548(ra) # 80001c66 <proc_pagetable>
    80001e92:	892a                	mv	s2,a0
    80001e94:	e4c8                	sd	a0,136(s1)
  if (p->pagetable == 0)
    80001e96:	c135                	beqz	a0,80001efa <allocproc+0x116>
  memset(&p->context, 0, sizeof(p->context));
    80001e98:	07000613          	li	a2,112
    80001e9c:	4581                	li	a1,0
    80001e9e:	0a048513          	addi	a0,s1,160
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	fde080e7          	jalr	-34(ra) # 80000e80 <memset>
  p->context.ra = (uint64)forkret;
    80001eaa:	00000797          	auipc	a5,0x0
    80001eae:	d3078793          	addi	a5,a5,-720 # 80001bda <forkret>
    80001eb2:	f0dc                	sd	a5,160(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001eb4:	7cbc                	ld	a5,120(s1)
    80001eb6:	6705                	lui	a4,0x1
    80001eb8:	97ba                	add	a5,a5,a4
    80001eba:	f4dc                	sd	a5,168(s1)
}
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	60e2                	ld	ra,24(sp)
    80001ec0:	6442                	ld	s0,16(sp)
    80001ec2:	64a2                	ld	s1,8(sp)
    80001ec4:	6902                	ld	s2,0(sp)
    80001ec6:	6105                	addi	sp,sp,32
    80001ec8:	8082                	ret
    freeproc(p);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	e88080e7          	jalr	-376(ra) # 80001d54 <freeproc>
    release(&p->lock);
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	f62080e7          	jalr	-158(ra) # 80000e38 <release>
    return 0;
    80001ede:	84ca                	mv	s1,s2
    80001ee0:	bff1                	j	80001ebc <allocproc+0xd8>
    freeproc(p);
    80001ee2:	8526                	mv	a0,s1
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	e70080e7          	jalr	-400(ra) # 80001d54 <freeproc>
    release(&p->lock);
    80001eec:	8526                	mv	a0,s1
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	f4a080e7          	jalr	-182(ra) # 80000e38 <release>
    return 0;
    80001ef6:	84ca                	mv	s1,s2
    80001ef8:	b7d1                	j	80001ebc <allocproc+0xd8>
    freeproc(p);
    80001efa:	8526                	mv	a0,s1
    80001efc:	00000097          	auipc	ra,0x0
    80001f00:	e58080e7          	jalr	-424(ra) # 80001d54 <freeproc>
    release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	f32080e7          	jalr	-206(ra) # 80000e38 <release>
    return 0;
    80001f0e:	84ca                	mv	s1,s2
    80001f10:	b775                	j	80001ebc <allocproc+0xd8>

0000000080001f12 <userinit>:
{
    80001f12:	1101                	addi	sp,sp,-32
    80001f14:	ec06                	sd	ra,24(sp)
    80001f16:	e822                	sd	s0,16(sp)
    80001f18:	e426                	sd	s1,8(sp)
    80001f1a:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f1c:	00000097          	auipc	ra,0x0
    80001f20:	ec8080e7          	jalr	-312(ra) # 80001de4 <allocproc>
    80001f24:	84aa                	mv	s1,a0
  initproc = p;
    80001f26:	00007797          	auipc	a5,0x7
    80001f2a:	caa7b123          	sd	a0,-862(a5) # 80008bc8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f2e:	03400613          	li	a2,52
    80001f32:	00007597          	auipc	a1,0x7
    80001f36:	abe58593          	addi	a1,a1,-1346 # 800089f0 <initcode>
    80001f3a:	6548                	ld	a0,136(a0)
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	5d0080e7          	jalr	1488(ra) # 8000150c <uvmfirst>
  p->sz = PGSIZE;
    80001f44:	6785                	lui	a5,0x1
    80001f46:	e0dc                	sd	a5,128(s1)
  p->trapframe->epc = 0;     // user program counter
    80001f48:	68d8                	ld	a4,144(s1)
    80001f4a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001f4e:	68d8                	ld	a4,144(s1)
    80001f50:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f52:	4641                	li	a2,16
    80001f54:	00006597          	auipc	a1,0x6
    80001f58:	2cc58593          	addi	a1,a1,716 # 80008220 <digits+0x1e0>
    80001f5c:	19848513          	addi	a0,s1,408
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	072080e7          	jalr	114(ra) # 80000fd2 <safestrcpy>
  p->cwd = namei("/");
    80001f68:	00006517          	auipc	a0,0x6
    80001f6c:	2c850513          	addi	a0,a0,712 # 80008230 <digits+0x1f0>
    80001f70:	00003097          	auipc	ra,0x3
    80001f74:	b08080e7          	jalr	-1272(ra) # 80004a78 <namei>
    80001f78:	18a4b823          	sd	a0,400(s1)
  p->state = RUNNABLE;
    80001f7c:	478d                	li	a5,3
    80001f7e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f80:	8526                	mv	a0,s1
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	eb6080e7          	jalr	-330(ra) # 80000e38 <release>
}
    80001f8a:	60e2                	ld	ra,24(sp)
    80001f8c:	6442                	ld	s0,16(sp)
    80001f8e:	64a2                	ld	s1,8(sp)
    80001f90:	6105                	addi	sp,sp,32
    80001f92:	8082                	ret

0000000080001f94 <growproc>:
{
    80001f94:	1101                	addi	sp,sp,-32
    80001f96:	ec06                	sd	ra,24(sp)
    80001f98:	e822                	sd	s0,16(sp)
    80001f9a:	e426                	sd	s1,8(sp)
    80001f9c:	e04a                	sd	s2,0(sp)
    80001f9e:	1000                	addi	s0,sp,32
    80001fa0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001fa2:	00000097          	auipc	ra,0x0
    80001fa6:	c00080e7          	jalr	-1024(ra) # 80001ba2 <myproc>
    80001faa:	84aa                	mv	s1,a0
  sz = p->sz;
    80001fac:	614c                	ld	a1,128(a0)
  if (n > 0)
    80001fae:	01204c63          	bgtz	s2,80001fc6 <growproc+0x32>
  else if (n < 0)
    80001fb2:	02094663          	bltz	s2,80001fde <growproc+0x4a>
  p->sz = sz;
    80001fb6:	e0cc                	sd	a1,128(s1)
  return 0;
    80001fb8:	4501                	li	a0,0
}
    80001fba:	60e2                	ld	ra,24(sp)
    80001fbc:	6442                	ld	s0,16(sp)
    80001fbe:	64a2                	ld	s1,8(sp)
    80001fc0:	6902                	ld	s2,0(sp)
    80001fc2:	6105                	addi	sp,sp,32
    80001fc4:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001fc6:	4691                	li	a3,4
    80001fc8:	00b90633          	add	a2,s2,a1
    80001fcc:	6548                	ld	a0,136(a0)
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	5f8080e7          	jalr	1528(ra) # 800015c6 <uvmalloc>
    80001fd6:	85aa                	mv	a1,a0
    80001fd8:	fd79                	bnez	a0,80001fb6 <growproc+0x22>
      return -1;
    80001fda:	557d                	li	a0,-1
    80001fdc:	bff9                	j	80001fba <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fde:	00b90633          	add	a2,s2,a1
    80001fe2:	6548                	ld	a0,136(a0)
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	59a080e7          	jalr	1434(ra) # 8000157e <uvmdealloc>
    80001fec:	85aa                	mv	a1,a0
    80001fee:	b7e1                	j	80001fb6 <growproc+0x22>

0000000080001ff0 <fork>:
{
    80001ff0:	7179                	addi	sp,sp,-48
    80001ff2:	f406                	sd	ra,40(sp)
    80001ff4:	f022                	sd	s0,32(sp)
    80001ff6:	ec26                	sd	s1,24(sp)
    80001ff8:	e84a                	sd	s2,16(sp)
    80001ffa:	e44e                	sd	s3,8(sp)
    80001ffc:	e052                	sd	s4,0(sp)
    80001ffe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002000:	00000097          	auipc	ra,0x0
    80002004:	ba2080e7          	jalr	-1118(ra) # 80001ba2 <myproc>
    80002008:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    8000200a:	00000097          	auipc	ra,0x0
    8000200e:	dda080e7          	jalr	-550(ra) # 80001de4 <allocproc>
    80002012:	10050f63          	beqz	a0,80002130 <fork+0x140>
    80002016:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002018:	08093603          	ld	a2,128(s2)
    8000201c:	654c                	ld	a1,136(a0)
    8000201e:	08893503          	ld	a0,136(s2)
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	6f8080e7          	jalr	1784(ra) # 8000171a <uvmcopy>
    8000202a:	04054a63          	bltz	a0,8000207e <fork+0x8e>
  np->sz = p->sz;
    8000202e:	08093783          	ld	a5,128(s2)
    80002032:	08f9b023          	sd	a5,128(s3)
  np->trace_mask = p->trace_mask; // copying parents trace to child
    80002036:	03492783          	lw	a5,52(s2)
    8000203a:	02f9aa23          	sw	a5,52(s3)
  *(np->trapframe) = *(p->trapframe);
    8000203e:	09093683          	ld	a3,144(s2)
    80002042:	87b6                	mv	a5,a3
    80002044:	0909b703          	ld	a4,144(s3)
    80002048:	12068693          	addi	a3,a3,288
    8000204c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002050:	6788                	ld	a0,8(a5)
    80002052:	6b8c                	ld	a1,16(a5)
    80002054:	6f90                	ld	a2,24(a5)
    80002056:	01073023          	sd	a6,0(a4)
    8000205a:	e708                	sd	a0,8(a4)
    8000205c:	eb0c                	sd	a1,16(a4)
    8000205e:	ef10                	sd	a2,24(a4)
    80002060:	02078793          	addi	a5,a5,32
    80002064:	02070713          	addi	a4,a4,32
    80002068:	fed792e3          	bne	a5,a3,8000204c <fork+0x5c>
  np->trapframe->a0 = 0;
    8000206c:	0909b783          	ld	a5,144(s3)
    80002070:	0607b823          	sd	zero,112(a5)
    80002074:	11000493          	li	s1,272
  for (i = 0; i < NOFILE; i++)
    80002078:	19000a13          	li	s4,400
    8000207c:	a03d                	j	800020aa <fork+0xba>
    freeproc(np);
    8000207e:	854e                	mv	a0,s3
    80002080:	00000097          	auipc	ra,0x0
    80002084:	cd4080e7          	jalr	-812(ra) # 80001d54 <freeproc>
    release(&np->lock);
    80002088:	854e                	mv	a0,s3
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	dae080e7          	jalr	-594(ra) # 80000e38 <release>
    return -1;
    80002092:	5a7d                	li	s4,-1
    80002094:	a069                	j	8000211e <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80002096:	00003097          	auipc	ra,0x3
    8000209a:	078080e7          	jalr	120(ra) # 8000510e <filedup>
    8000209e:	009987b3          	add	a5,s3,s1
    800020a2:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    800020a4:	04a1                	addi	s1,s1,8
    800020a6:	01448763          	beq	s1,s4,800020b4 <fork+0xc4>
    if (p->ofile[i])
    800020aa:	009907b3          	add	a5,s2,s1
    800020ae:	6388                	ld	a0,0(a5)
    800020b0:	f17d                	bnez	a0,80002096 <fork+0xa6>
    800020b2:	bfcd                	j	800020a4 <fork+0xb4>
  np->cwd = idup(p->cwd);
    800020b4:	19093503          	ld	a0,400(s2)
    800020b8:	00002097          	auipc	ra,0x2
    800020bc:	1dc080e7          	jalr	476(ra) # 80004294 <idup>
    800020c0:	18a9b823          	sd	a0,400(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020c4:	4641                	li	a2,16
    800020c6:	19890593          	addi	a1,s2,408
    800020ca:	19898513          	addi	a0,s3,408
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	f04080e7          	jalr	-252(ra) # 80000fd2 <safestrcpy>
  pid = np->pid;
    800020d6:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800020da:	854e                	mv	a0,s3
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	d5c080e7          	jalr	-676(ra) # 80000e38 <release>
  acquire(&wait_lock);
    800020e4:	0022f497          	auipc	s1,0x22f
    800020e8:	d8c48493          	addi	s1,s1,-628 # 80230e70 <wait_lock>
    800020ec:	8526                	mv	a0,s1
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	c96080e7          	jalr	-874(ra) # 80000d84 <acquire>
  np->parent = p;
    800020f6:	0729b823          	sd	s2,112(s3)
  release(&wait_lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	d3c080e7          	jalr	-708(ra) # 80000e38 <release>
  acquire(&np->lock);
    80002104:	854e                	mv	a0,s3
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	c7e080e7          	jalr	-898(ra) # 80000d84 <acquire>
  np->state = RUNNABLE;
    8000210e:	478d                	li	a5,3
    80002110:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002114:	854e                	mv	a0,s3
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	d22080e7          	jalr	-734(ra) # 80000e38 <release>
}
    8000211e:	8552                	mv	a0,s4
    80002120:	70a2                	ld	ra,40(sp)
    80002122:	7402                	ld	s0,32(sp)
    80002124:	64e2                	ld	s1,24(sp)
    80002126:	6942                	ld	s2,16(sp)
    80002128:	69a2                	ld	s3,8(sp)
    8000212a:	6a02                	ld	s4,0(sp)
    8000212c:	6145                	addi	sp,sp,48
    8000212e:	8082                	ret
    return -1;
    80002130:	5a7d                	li	s4,-1
    80002132:	b7f5                	j	8000211e <fork+0x12e>

0000000080002134 <do_rand>:
{
    80002134:	1141                	addi	sp,sp,-16
    80002136:	e422                	sd	s0,8(sp)
    80002138:	0800                	addi	s0,sp,16
  x = (*ctx % 0x7ffffffe) + 1;
    8000213a:	611c                	ld	a5,0(a0)
    8000213c:	80000737          	lui	a4,0x80000
    80002140:	ffe74713          	xori	a4,a4,-2
    80002144:	02e7f7b3          	remu	a5,a5,a4
    80002148:	0785                	addi	a5,a5,1
  lo = x % 127773;
    8000214a:	66fd                	lui	a3,0x1f
    8000214c:	31d68693          	addi	a3,a3,797 # 1f31d <_entry-0x7ffe0ce3>
    80002150:	02d7e733          	rem	a4,a5,a3
  x = 16807 * lo - 2836 * hi;
    80002154:	6611                	lui	a2,0x4
    80002156:	1a760613          	addi	a2,a2,423 # 41a7 <_entry-0x7fffbe59>
    8000215a:	02c70733          	mul	a4,a4,a2
  hi = x / 127773;
    8000215e:	02d7c7b3          	div	a5,a5,a3
  x = 16807 * lo - 2836 * hi;
    80002162:	76fd                	lui	a3,0xfffff
    80002164:	4ec68693          	addi	a3,a3,1260 # fffffffffffff4ec <end+0xffffffff7fdbbe84>
    80002168:	02d787b3          	mul	a5,a5,a3
    8000216c:	97ba                	add	a5,a5,a4
  if (x < 0)
    8000216e:	0007c963          	bltz	a5,80002180 <do_rand+0x4c>
  x--;
    80002172:	17fd                	addi	a5,a5,-1
  *ctx = x;
    80002174:	e11c                	sd	a5,0(a0)
}
    80002176:	0007851b          	sext.w	a0,a5
    8000217a:	6422                	ld	s0,8(sp)
    8000217c:	0141                	addi	sp,sp,16
    8000217e:	8082                	ret
    x += 0x7fffffff;
    80002180:	80000737          	lui	a4,0x80000
    80002184:	fff74713          	not	a4,a4
    80002188:	97ba                	add	a5,a5,a4
    8000218a:	b7e5                	j	80002172 <do_rand+0x3e>

000000008000218c <rand>:
{
    8000218c:	1141                	addi	sp,sp,-16
    8000218e:	e406                	sd	ra,8(sp)
    80002190:	e022                	sd	s0,0(sp)
    80002192:	0800                	addi	s0,sp,16
  return (do_rand(&rand_next));
    80002194:	00007517          	auipc	a0,0x7
    80002198:	84450513          	addi	a0,a0,-1980 # 800089d8 <rand_next>
    8000219c:	00000097          	auipc	ra,0x0
    800021a0:	f98080e7          	jalr	-104(ra) # 80002134 <do_rand>
}
    800021a4:	60a2                	ld	ra,8(sp)
    800021a6:	6402                	ld	s0,0(sp)
    800021a8:	0141                	addi	sp,sp,16
    800021aa:	8082                	ret

00000000800021ac <priority_dp>:
{
    800021ac:	1141                	addi	sp,sp,-16
    800021ae:	e422                	sd	s0,8(sp)
    800021b0:	0800                	addi	s0,sp,16
  if (p->runtime != 0 || p->waittime != 0)
    800021b2:	4538                	lw	a4,72(a0)
    800021b4:	e701                	bnez	a4,800021bc <priority_dp+0x10>
    800021b6:	4974                	lw	a3,84(a0)
  int nice = 5, dp;
    800021b8:	4795                	li	a5,5
  if (p->runtime != 0 || p->waittime != 0)
    800021ba:	ca91                	beqz	a3,800021ce <priority_dp+0x22>
    nice = ((p->waittime) / (p->waittime + p->runtime)) * 10;
    800021bc:	497c                	lw	a5,84(a0)
    800021be:	9f3d                	addw	a4,a4,a5
    800021c0:	02e7c73b          	divw	a4,a5,a4
    800021c4:	0027179b          	slliw	a5,a4,0x2
    800021c8:	9fb9                	addw	a5,a5,a4
    800021ca:	0017979b          	slliw	a5,a5,0x1
  dp = p->priority - nice + 5 < 100 ? p->priority - nice + 5 : 100;
    800021ce:	5528                	lw	a0,104(a0)
    800021d0:	9d1d                	subw	a0,a0,a5
    800021d2:	0005071b          	sext.w	a4,a0
    800021d6:	05f00793          	li	a5,95
    800021da:	00e7d463          	bge	a5,a4,800021e2 <priority_dp+0x36>
    800021de:	05f00513          	li	a0,95
    800021e2:	2515                	addiw	a0,a0,5
  dp = dp > 0 ? dp : 0;
    800021e4:	0005079b          	sext.w	a5,a0
    800021e8:	fff7c793          	not	a5,a5
    800021ec:	97fd                	srai	a5,a5,0x3f
    800021ee:	8d7d                	and	a0,a0,a5
}
    800021f0:	2501                	sext.w	a0,a0
    800021f2:	6422                	ld	s0,8(sp)
    800021f4:	0141                	addi	sp,sp,16
    800021f6:	8082                	ret

00000000800021f8 <scheduler>:
{
    800021f8:	715d                	addi	sp,sp,-80
    800021fa:	e486                	sd	ra,72(sp)
    800021fc:	e0a2                	sd	s0,64(sp)
    800021fe:	fc26                	sd	s1,56(sp)
    80002200:	f84a                	sd	s2,48(sp)
    80002202:	f44e                	sd	s3,40(sp)
    80002204:	f052                	sd	s4,32(sp)
    80002206:	ec56                	sd	s5,24(sp)
    80002208:	e85a                	sd	s6,16(sp)
    8000220a:	e45e                	sd	s7,8(sp)
    8000220c:	e062                	sd	s8,0(sp)
    8000220e:	0880                	addi	s0,sp,80
    80002210:	8792                	mv	a5,tp
  int id = r_tp();
    80002212:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002214:	00779c13          	slli	s8,a5,0x7
    80002218:	0022f717          	auipc	a4,0x22f
    8000221c:	c4070713          	addi	a4,a4,-960 # 80230e58 <pid_lock>
    80002220:	9762                	add	a4,a4,s8
    80002222:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &proc_2->context);
    80002226:	0022f717          	auipc	a4,0x22f
    8000222a:	c6a70713          	addi	a4,a4,-918 # 80230e90 <cpus+0x8>
    8000222e:	9c3a                	add	s8,s8,a4
    for (p = proc; p < &proc[NPROC]; p++)
    80002230:	00236a97          	auipc	s5,0x236
    80002234:	058a8a93          	addi	s5,s5,88 # 80238288 <tickslock>
      else if (p->state == RUNNABLE && ((p->queue_level == proc_2->queue_level && p->in_time < proc_2->in_time) || p->queue_level < proc_2->queue_level))
    80002238:	4a0d                	li	s4,3
      c->proc = proc_2;
    8000223a:	079e                	slli	a5,a5,0x7
    8000223c:	0022fb97          	auipc	s7,0x22f
    80002240:	c1cb8b93          	addi	s7,s7,-996 # 80230e58 <pid_lock>
    80002244:	9bbe                	add	s7,s7,a5
    80002246:	a889                	j	80002298 <scheduler+0xa0>
      if (proc_2 == 0 && p->state == RUNNABLE)
    80002248:	4c9c                	lw	a5,24(s1)
    8000224a:	0b478d63          	beq	a5,s4,80002304 <scheduler+0x10c>
        release(&p->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	be8080e7          	jalr	-1048(ra) # 80000e38 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002258:	1c048793          	addi	a5,s1,448
    8000225c:	0757ea63          	bltu	a5,s5,800022d0 <scheduler+0xd8>
    if (proc_2 != 0)
    80002260:	02098d63          	beqz	s3,8000229a <scheduler+0xa2>
    for (p = proc; p < &proc[NPROC]; p++)
    80002264:	894e                	mv	s2,s3
      proc_2->state = RUNNING;
    80002266:	4791                	li	a5,4
    80002268:	00f92c23          	sw	a5,24(s2)
      proc_2->last_exec = ticks;
    8000226c:	00007797          	auipc	a5,0x7
    80002270:	9687a783          	lw	a5,-1688(a5) # 80008bd4 <ticks>
    80002274:	1af92c23          	sw	a5,440(s2)
      c->proc = proc_2;
    80002278:	032bb823          	sd	s2,48(s7)
      swtch(&c->context, &proc_2->context);
    8000227c:	0a090593          	addi	a1,s2,160
    80002280:	8562                	mv	a0,s8
    80002282:	00001097          	auipc	ra,0x1
    80002286:	88c080e7          	jalr	-1908(ra) # 80002b0e <swtch>
      c->proc = 0;
    8000228a:	020bb823          	sd	zero,48(s7)
      release(&proc_2->lock);
    8000228e:	854a                	mv	a0,s2
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	ba8080e7          	jalr	-1112(ra) # 80000e38 <release>
    struct proc *proc_2 = 0;
    80002298:	4b01                	li	s6,0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000229a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000229e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022a2:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800022a6:	0022f497          	auipc	s1,0x22f
    800022aa:	fe248493          	addi	s1,s1,-30 # 80231288 <proc>
    struct proc *proc_2 = 0;
    800022ae:	89da                	mv	s3,s6
    800022b0:	a015                	j	800022d4 <scheduler+0xdc>
      else if (p->state == RUNNABLE && ((p->queue_level == proc_2->queue_level && p->in_time < proc_2->in_time) || p->queue_level < proc_2->queue_level))
    800022b2:	1a84b703          	ld	a4,424(s1)
    800022b6:	1a89b783          	ld	a5,424(s3)
    800022ba:	04f76063          	bltu	a4,a5,800022fa <scheduler+0x102>
        release(&p->lock);
    800022be:	854a                	mv	a0,s2
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	b78080e7          	jalr	-1160(ra) # 80000e38 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800022c8:	1c048793          	addi	a5,s1,448
    800022cc:	f957fce3          	bgeu	a5,s5,80002264 <scheduler+0x6c>
    800022d0:	1c048493          	addi	s1,s1,448
    800022d4:	8926                	mv	s2,s1
      acquire(&p->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	aac080e7          	jalr	-1364(ra) # 80000d84 <acquire>
      if (proc_2 == 0 && p->state == RUNNABLE)
    800022e0:	f60984e3          	beqz	s3,80002248 <scheduler+0x50>
      else if (p->state == RUNNABLE && ((p->queue_level == proc_2->queue_level && p->in_time < proc_2->in_time) || p->queue_level < proc_2->queue_level))
    800022e4:	4c9c                	lw	a5,24(s1)
    800022e6:	fd479ce3          	bne	a5,s4,800022be <scheduler+0xc6>
    800022ea:	1b04a703          	lw	a4,432(s1)
    800022ee:	1b09a783          	lw	a5,432(s3)
    800022f2:	fcf700e3          	beq	a4,a5,800022b2 <scheduler+0xba>
    800022f6:	fcf754e3          	bge	a4,a5,800022be <scheduler+0xc6>
        release(&proc_2->lock);
    800022fa:	854e                	mv	a0,s3
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	b3c080e7          	jalr	-1220(ra) # 80000e38 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002304:	1c048793          	addi	a5,s1,448
    80002308:	f557ffe3          	bgeu	a5,s5,80002266 <scheduler+0x6e>
    8000230c:	89ca                	mv	s3,s2
    8000230e:	b7c9                	j	800022d0 <scheduler+0xd8>

0000000080002310 <sched>:
{
    80002310:	7179                	addi	sp,sp,-48
    80002312:	f406                	sd	ra,40(sp)
    80002314:	f022                	sd	s0,32(sp)
    80002316:	ec26                	sd	s1,24(sp)
    80002318:	e84a                	sd	s2,16(sp)
    8000231a:	e44e                	sd	s3,8(sp)
    8000231c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000231e:	00000097          	auipc	ra,0x0
    80002322:	884080e7          	jalr	-1916(ra) # 80001ba2 <myproc>
    80002326:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	9e2080e7          	jalr	-1566(ra) # 80000d0a <holding>
    80002330:	c93d                	beqz	a0,800023a6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002332:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002334:	2781                	sext.w	a5,a5
    80002336:	079e                	slli	a5,a5,0x7
    80002338:	0022f717          	auipc	a4,0x22f
    8000233c:	b2070713          	addi	a4,a4,-1248 # 80230e58 <pid_lock>
    80002340:	97ba                	add	a5,a5,a4
    80002342:	0a87a703          	lw	a4,168(a5)
    80002346:	4785                	li	a5,1
    80002348:	06f71763          	bne	a4,a5,800023b6 <sched+0xa6>
  if (p->state == RUNNING)
    8000234c:	4c98                	lw	a4,24(s1)
    8000234e:	4791                	li	a5,4
    80002350:	06f70b63          	beq	a4,a5,800023c6 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002354:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002358:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000235a:	efb5                	bnez	a5,800023d6 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000235c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000235e:	0022f917          	auipc	s2,0x22f
    80002362:	afa90913          	addi	s2,s2,-1286 # 80230e58 <pid_lock>
    80002366:	2781                	sext.w	a5,a5
    80002368:	079e                	slli	a5,a5,0x7
    8000236a:	97ca                	add	a5,a5,s2
    8000236c:	0ac7a983          	lw	s3,172(a5)
    80002370:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002372:	2781                	sext.w	a5,a5
    80002374:	079e                	slli	a5,a5,0x7
    80002376:	0022f597          	auipc	a1,0x22f
    8000237a:	b1a58593          	addi	a1,a1,-1254 # 80230e90 <cpus+0x8>
    8000237e:	95be                	add	a1,a1,a5
    80002380:	0a048513          	addi	a0,s1,160
    80002384:	00000097          	auipc	ra,0x0
    80002388:	78a080e7          	jalr	1930(ra) # 80002b0e <swtch>
    8000238c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000238e:	2781                	sext.w	a5,a5
    80002390:	079e                	slli	a5,a5,0x7
    80002392:	97ca                	add	a5,a5,s2
    80002394:	0b37a623          	sw	s3,172(a5)
}
    80002398:	70a2                	ld	ra,40(sp)
    8000239a:	7402                	ld	s0,32(sp)
    8000239c:	64e2                	ld	s1,24(sp)
    8000239e:	6942                	ld	s2,16(sp)
    800023a0:	69a2                	ld	s3,8(sp)
    800023a2:	6145                	addi	sp,sp,48
    800023a4:	8082                	ret
    panic("sched p->lock");
    800023a6:	00006517          	auipc	a0,0x6
    800023aa:	e9250513          	addi	a0,a0,-366 # 80008238 <digits+0x1f8>
    800023ae:	ffffe097          	auipc	ra,0xffffe
    800023b2:	196080e7          	jalr	406(ra) # 80000544 <panic>
    panic("sched locks");
    800023b6:	00006517          	auipc	a0,0x6
    800023ba:	e9250513          	addi	a0,a0,-366 # 80008248 <digits+0x208>
    800023be:	ffffe097          	auipc	ra,0xffffe
    800023c2:	186080e7          	jalr	390(ra) # 80000544 <panic>
    panic("sched running");
    800023c6:	00006517          	auipc	a0,0x6
    800023ca:	e9250513          	addi	a0,a0,-366 # 80008258 <digits+0x218>
    800023ce:	ffffe097          	auipc	ra,0xffffe
    800023d2:	176080e7          	jalr	374(ra) # 80000544 <panic>
    panic("sched interruptible");
    800023d6:	00006517          	auipc	a0,0x6
    800023da:	e9250513          	addi	a0,a0,-366 # 80008268 <digits+0x228>
    800023de:	ffffe097          	auipc	ra,0xffffe
    800023e2:	166080e7          	jalr	358(ra) # 80000544 <panic>

00000000800023e6 <yield>:
{
    800023e6:	1101                	addi	sp,sp,-32
    800023e8:	ec06                	sd	ra,24(sp)
    800023ea:	e822                	sd	s0,16(sp)
    800023ec:	e426                	sd	s1,8(sp)
    800023ee:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	7b2080e7          	jalr	1970(ra) # 80001ba2 <myproc>
    800023f8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	98a080e7          	jalr	-1654(ra) # 80000d84 <acquire>
  p->state = RUNNABLE;
    80002402:	478d                	li	a5,3
    80002404:	cc9c                	sw	a5,24(s1)
  sched();
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	f0a080e7          	jalr	-246(ra) # 80002310 <sched>
  release(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	a28080e7          	jalr	-1496(ra) # 80000e38 <release>
}
    80002418:	60e2                	ld	ra,24(sp)
    8000241a:	6442                	ld	s0,16(sp)
    8000241c:	64a2                	ld	s1,8(sp)
    8000241e:	6105                	addi	sp,sp,32
    80002420:	8082                	ret

0000000080002422 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002422:	7179                	addi	sp,sp,-48
    80002424:	f406                	sd	ra,40(sp)
    80002426:	f022                	sd	s0,32(sp)
    80002428:	ec26                	sd	s1,24(sp)
    8000242a:	e84a                	sd	s2,16(sp)
    8000242c:	e44e                	sd	s3,8(sp)
    8000242e:	1800                	addi	s0,sp,48
    80002430:	89aa                	mv	s3,a0
    80002432:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	76e080e7          	jalr	1902(ra) # 80001ba2 <myproc>
    8000243c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	946080e7          	jalr	-1722(ra) # 80000d84 <acquire>
  release(lk);
    80002446:	854a                	mv	a0,s2
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	9f0080e7          	jalr	-1552(ra) # 80000e38 <release>

  // Go to sleep.
  p->chan = chan;
    80002450:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002454:	4789                	li	a5,2
    80002456:	cc9c                	sw	a5,24(s1)

  sched();
    80002458:	00000097          	auipc	ra,0x0
    8000245c:	eb8080e7          	jalr	-328(ra) # 80002310 <sched>

  // Tidy up.
  p->chan = 0;
    80002460:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	9d2080e7          	jalr	-1582(ra) # 80000e38 <release>
  acquire(lk);
    8000246e:	854a                	mv	a0,s2
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	914080e7          	jalr	-1772(ra) # 80000d84 <acquire>
}
    80002478:	70a2                	ld	ra,40(sp)
    8000247a:	7402                	ld	s0,32(sp)
    8000247c:	64e2                	ld	s1,24(sp)
    8000247e:	6942                	ld	s2,16(sp)
    80002480:	69a2                	ld	s3,8(sp)
    80002482:	6145                	addi	sp,sp,48
    80002484:	8082                	ret

0000000080002486 <waitx>:
{
    80002486:	711d                	addi	sp,sp,-96
    80002488:	ec86                	sd	ra,88(sp)
    8000248a:	e8a2                	sd	s0,80(sp)
    8000248c:	e4a6                	sd	s1,72(sp)
    8000248e:	e0ca                	sd	s2,64(sp)
    80002490:	fc4e                	sd	s3,56(sp)
    80002492:	f852                	sd	s4,48(sp)
    80002494:	f456                	sd	s5,40(sp)
    80002496:	f05a                	sd	s6,32(sp)
    80002498:	ec5e                	sd	s7,24(sp)
    8000249a:	e862                	sd	s8,16(sp)
    8000249c:	e466                	sd	s9,8(sp)
    8000249e:	e06a                	sd	s10,0(sp)
    800024a0:	1080                	addi	s0,sp,96
    800024a2:	8b2a                	mv	s6,a0
    800024a4:	8c2e                	mv	s8,a1
    800024a6:	8bb2                	mv	s7,a2
  struct proc *p = myproc();
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	6fa080e7          	jalr	1786(ra) # 80001ba2 <myproc>
    800024b0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024b2:	0022f517          	auipc	a0,0x22f
    800024b6:	9be50513          	addi	a0,a0,-1602 # 80230e70 <wait_lock>
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	8ca080e7          	jalr	-1846(ra) # 80000d84 <acquire>
    havekids = 0;
    800024c2:	4c81                	li	s9,0
        if (np->state == ZOMBIE)
    800024c4:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    800024c6:	00236997          	auipc	s3,0x236
    800024ca:	dc298993          	addi	s3,s3,-574 # 80238288 <tickslock>
        havekids = 1;
    800024ce:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024d0:	0022fd17          	auipc	s10,0x22f
    800024d4:	9a0d0d13          	addi	s10,s10,-1632 # 80230e70 <wait_lock>
    havekids = 0;
    800024d8:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800024da:	0022f497          	auipc	s1,0x22f
    800024de:	dae48493          	addi	s1,s1,-594 # 80231288 <proc>
    800024e2:	a041                	j	80002562 <waitx+0xdc>
          pid = np->pid;
    800024e4:	0304a983          	lw	s3,48(s1)
          *rtime = np->trtime;
    800024e8:	44f8                	lw	a4,76(s1)
    800024ea:	00ec2023          	sw	a4,0(s8) # 1000 <_entry-0x7ffff000>
          *wtime = np->endtime - np->intime - np->trtime;
    800024ee:	4cfc                	lw	a5,92(s1)
    800024f0:	4cb4                	lw	a3,88(s1)
    800024f2:	9f95                	subw	a5,a5,a3
    800024f4:	9f99                	subw	a5,a5,a4
    800024f6:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024fa:	000b0e63          	beqz	s6,80002516 <waitx+0x90>
    800024fe:	4691                	li	a3,4
    80002500:	02c48613          	addi	a2,s1,44
    80002504:	85da                	mv	a1,s6
    80002506:	08893503          	ld	a0,136(s2)
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	31e080e7          	jalr	798(ra) # 80001828 <copyout>
    80002512:	02054563          	bltz	a0,8000253c <waitx+0xb6>
          freeproc(np);
    80002516:	8526                	mv	a0,s1
    80002518:	00000097          	auipc	ra,0x0
    8000251c:	83c080e7          	jalr	-1988(ra) # 80001d54 <freeproc>
          release(&np->lock);
    80002520:	8526                	mv	a0,s1
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	916080e7          	jalr	-1770(ra) # 80000e38 <release>
          release(&wait_lock);
    8000252a:	0022f517          	auipc	a0,0x22f
    8000252e:	94650513          	addi	a0,a0,-1722 # 80230e70 <wait_lock>
    80002532:	fffff097          	auipc	ra,0xfffff
    80002536:	906080e7          	jalr	-1786(ra) # 80000e38 <release>
          return pid;
    8000253a:	a09d                	j	800025a0 <waitx+0x11a>
            release(&np->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	8fa080e7          	jalr	-1798(ra) # 80000e38 <release>
            release(&wait_lock);
    80002546:	0022f517          	auipc	a0,0x22f
    8000254a:	92a50513          	addi	a0,a0,-1750 # 80230e70 <wait_lock>
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	8ea080e7          	jalr	-1814(ra) # 80000e38 <release>
            return -1;
    80002556:	59fd                	li	s3,-1
    80002558:	a0a1                	j	800025a0 <waitx+0x11a>
    for (np = proc; np < &proc[NPROC]; np++)
    8000255a:	1c048493          	addi	s1,s1,448
    8000255e:	03348463          	beq	s1,s3,80002586 <waitx+0x100>
      if (np->parent == p)
    80002562:	78bc                	ld	a5,112(s1)
    80002564:	ff279be3          	bne	a5,s2,8000255a <waitx+0xd4>
        acquire(&np->lock);
    80002568:	8526                	mv	a0,s1
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	81a080e7          	jalr	-2022(ra) # 80000d84 <acquire>
        if (np->state == ZOMBIE)
    80002572:	4c9c                	lw	a5,24(s1)
    80002574:	f74788e3          	beq	a5,s4,800024e4 <waitx+0x5e>
        release(&np->lock);
    80002578:	8526                	mv	a0,s1
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	8be080e7          	jalr	-1858(ra) # 80000e38 <release>
        havekids = 1;
    80002582:	8756                	mv	a4,s5
    80002584:	bfd9                	j	8000255a <waitx+0xd4>
    if (!havekids || p->killed)
    80002586:	c701                	beqz	a4,8000258e <waitx+0x108>
    80002588:	02892783          	lw	a5,40(s2)
    8000258c:	cb8d                	beqz	a5,800025be <waitx+0x138>
      release(&wait_lock);
    8000258e:	0022f517          	auipc	a0,0x22f
    80002592:	8e250513          	addi	a0,a0,-1822 # 80230e70 <wait_lock>
    80002596:	fffff097          	auipc	ra,0xfffff
    8000259a:	8a2080e7          	jalr	-1886(ra) # 80000e38 <release>
      return -1;
    8000259e:	59fd                	li	s3,-1
}
    800025a0:	854e                	mv	a0,s3
    800025a2:	60e6                	ld	ra,88(sp)
    800025a4:	6446                	ld	s0,80(sp)
    800025a6:	64a6                	ld	s1,72(sp)
    800025a8:	6906                	ld	s2,64(sp)
    800025aa:	79e2                	ld	s3,56(sp)
    800025ac:	7a42                	ld	s4,48(sp)
    800025ae:	7aa2                	ld	s5,40(sp)
    800025b0:	7b02                	ld	s6,32(sp)
    800025b2:	6be2                	ld	s7,24(sp)
    800025b4:	6c42                	ld	s8,16(sp)
    800025b6:	6ca2                	ld	s9,8(sp)
    800025b8:	6d02                	ld	s10,0(sp)
    800025ba:	6125                	addi	sp,sp,96
    800025bc:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025be:	85ea                	mv	a1,s10
    800025c0:	854a                	mv	a0,s2
    800025c2:	00000097          	auipc	ra,0x0
    800025c6:	e60080e7          	jalr	-416(ra) # 80002422 <sleep>
    havekids = 0;
    800025ca:	b739                	j	800024d8 <waitx+0x52>

00000000800025cc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800025cc:	7139                	addi	sp,sp,-64
    800025ce:	fc06                	sd	ra,56(sp)
    800025d0:	f822                	sd	s0,48(sp)
    800025d2:	f426                	sd	s1,40(sp)
    800025d4:	f04a                	sd	s2,32(sp)
    800025d6:	ec4e                	sd	s3,24(sp)
    800025d8:	e852                	sd	s4,16(sp)
    800025da:	e456                	sd	s5,8(sp)
    800025dc:	e05a                	sd	s6,0(sp)
    800025de:	0080                	addi	s0,sp,64
    800025e0:	8a2a                	mv	s4,a0
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800025e2:	0022f497          	auipc	s1,0x22f
    800025e6:	ca648493          	addi	s1,s1,-858 # 80231288 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800025ea:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800025ec:	4b0d                	li	s6,3
#ifdef MLFQ
        p->last_exec = ticks;
    800025ee:	00006a97          	auipc	s5,0x6
    800025f2:	5e6a8a93          	addi	s5,s5,1510 # 80008bd4 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    800025f6:	00236917          	auipc	s2,0x236
    800025fa:	c9290913          	addi	s2,s2,-878 # 80238288 <tickslock>
    800025fe:	a035                	j	8000262a <wakeup+0x5e>
        p->state = RUNNABLE;
    80002600:	0164ac23          	sw	s6,24(s1)
        p->last_exec = ticks;
    80002604:	000aa783          	lw	a5,0(s5)
    80002608:	1af4ac23          	sw	a5,440(s1)
        p->in_time = ticks;
    8000260c:	1782                	slli	a5,a5,0x20
    8000260e:	9381                	srli	a5,a5,0x20
    80002610:	1af4b423          	sd	a5,424(s1)
        p->tick_ctr = 0;
    80002614:	1a04aa23          	sw	zero,436(s1)

#ifdef LBS
        totaltickets += p->tickets;
#endif
      }
      release(&p->lock);
    80002618:	8526                	mv	a0,s1
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	81e080e7          	jalr	-2018(ra) # 80000e38 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002622:	1c048493          	addi	s1,s1,448
    80002626:	03248463          	beq	s1,s2,8000264e <wakeup+0x82>
    if (p != myproc())
    8000262a:	fffff097          	auipc	ra,0xfffff
    8000262e:	578080e7          	jalr	1400(ra) # 80001ba2 <myproc>
    80002632:	fea488e3          	beq	s1,a0,80002622 <wakeup+0x56>
      acquire(&p->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	74c080e7          	jalr	1868(ra) # 80000d84 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002640:	4c9c                	lw	a5,24(s1)
    80002642:	fd379be3          	bne	a5,s3,80002618 <wakeup+0x4c>
    80002646:	709c                	ld	a5,32(s1)
    80002648:	fd4798e3          	bne	a5,s4,80002618 <wakeup+0x4c>
    8000264c:	bf55                	j	80002600 <wakeup+0x34>
    }
  }
}
    8000264e:	70e2                	ld	ra,56(sp)
    80002650:	7442                	ld	s0,48(sp)
    80002652:	74a2                	ld	s1,40(sp)
    80002654:	7902                	ld	s2,32(sp)
    80002656:	69e2                	ld	s3,24(sp)
    80002658:	6a42                	ld	s4,16(sp)
    8000265a:	6aa2                	ld	s5,8(sp)
    8000265c:	6b02                	ld	s6,0(sp)
    8000265e:	6121                	addi	sp,sp,64
    80002660:	8082                	ret

0000000080002662 <reparent>:
{
    80002662:	7179                	addi	sp,sp,-48
    80002664:	f406                	sd	ra,40(sp)
    80002666:	f022                	sd	s0,32(sp)
    80002668:	ec26                	sd	s1,24(sp)
    8000266a:	e84a                	sd	s2,16(sp)
    8000266c:	e44e                	sd	s3,8(sp)
    8000266e:	e052                	sd	s4,0(sp)
    80002670:	1800                	addi	s0,sp,48
    80002672:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002674:	0022f497          	auipc	s1,0x22f
    80002678:	c1448493          	addi	s1,s1,-1004 # 80231288 <proc>
      pp->parent = initproc;
    8000267c:	00006a17          	auipc	s4,0x6
    80002680:	54ca0a13          	addi	s4,s4,1356 # 80008bc8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002684:	00236997          	auipc	s3,0x236
    80002688:	c0498993          	addi	s3,s3,-1020 # 80238288 <tickslock>
    8000268c:	a029                	j	80002696 <reparent+0x34>
    8000268e:	1c048493          	addi	s1,s1,448
    80002692:	01348d63          	beq	s1,s3,800026ac <reparent+0x4a>
    if (pp->parent == p)
    80002696:	78bc                	ld	a5,112(s1)
    80002698:	ff279be3          	bne	a5,s2,8000268e <reparent+0x2c>
      pp->parent = initproc;
    8000269c:	000a3503          	ld	a0,0(s4)
    800026a0:	f8a8                	sd	a0,112(s1)
      wakeup(initproc);
    800026a2:	00000097          	auipc	ra,0x0
    800026a6:	f2a080e7          	jalr	-214(ra) # 800025cc <wakeup>
    800026aa:	b7d5                	j	8000268e <reparent+0x2c>
}
    800026ac:	70a2                	ld	ra,40(sp)
    800026ae:	7402                	ld	s0,32(sp)
    800026b0:	64e2                	ld	s1,24(sp)
    800026b2:	6942                	ld	s2,16(sp)
    800026b4:	69a2                	ld	s3,8(sp)
    800026b6:	6a02                	ld	s4,0(sp)
    800026b8:	6145                	addi	sp,sp,48
    800026ba:	8082                	ret

00000000800026bc <exit>:
{
    800026bc:	7179                	addi	sp,sp,-48
    800026be:	f406                	sd	ra,40(sp)
    800026c0:	f022                	sd	s0,32(sp)
    800026c2:	ec26                	sd	s1,24(sp)
    800026c4:	e84a                	sd	s2,16(sp)
    800026c6:	e44e                	sd	s3,8(sp)
    800026c8:	e052                	sd	s4,0(sp)
    800026ca:	1800                	addi	s0,sp,48
    800026cc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026ce:	fffff097          	auipc	ra,0xfffff
    800026d2:	4d4080e7          	jalr	1236(ra) # 80001ba2 <myproc>
    800026d6:	89aa                	mv	s3,a0
  if (p == initproc)
    800026d8:	00006797          	auipc	a5,0x6
    800026dc:	4f07b783          	ld	a5,1264(a5) # 80008bc8 <initproc>
    800026e0:	11050493          	addi	s1,a0,272
    800026e4:	19050913          	addi	s2,a0,400
    800026e8:	02a79363          	bne	a5,a0,8000270e <exit+0x52>
    panic("init exiting");
    800026ec:	00006517          	auipc	a0,0x6
    800026f0:	b9450513          	addi	a0,a0,-1132 # 80008280 <digits+0x240>
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	e50080e7          	jalr	-432(ra) # 80000544 <panic>
      fileclose(f);
    800026fc:	00003097          	auipc	ra,0x3
    80002700:	a64080e7          	jalr	-1436(ra) # 80005160 <fileclose>
      p->ofile[fd] = 0;
    80002704:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002708:	04a1                	addi	s1,s1,8
    8000270a:	01248563          	beq	s1,s2,80002714 <exit+0x58>
    if (p->ofile[fd])
    8000270e:	6088                	ld	a0,0(s1)
    80002710:	f575                	bnez	a0,800026fc <exit+0x40>
    80002712:	bfdd                	j	80002708 <exit+0x4c>
  begin_op();
    80002714:	00002097          	auipc	ra,0x2
    80002718:	580080e7          	jalr	1408(ra) # 80004c94 <begin_op>
  iput(p->cwd);
    8000271c:	1909b503          	ld	a0,400(s3)
    80002720:	00002097          	auipc	ra,0x2
    80002724:	d6c080e7          	jalr	-660(ra) # 8000448c <iput>
  end_op();
    80002728:	00002097          	auipc	ra,0x2
    8000272c:	5ec080e7          	jalr	1516(ra) # 80004d14 <end_op>
  p->cwd = 0;
    80002730:	1809b823          	sd	zero,400(s3)
  acquire(&wait_lock);
    80002734:	0022e497          	auipc	s1,0x22e
    80002738:	73c48493          	addi	s1,s1,1852 # 80230e70 <wait_lock>
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	646080e7          	jalr	1606(ra) # 80000d84 <acquire>
  reparent(p);
    80002746:	854e                	mv	a0,s3
    80002748:	00000097          	auipc	ra,0x0
    8000274c:	f1a080e7          	jalr	-230(ra) # 80002662 <reparent>
  wakeup(p->parent);
    80002750:	0709b503          	ld	a0,112(s3)
    80002754:	00000097          	auipc	ra,0x0
    80002758:	e78080e7          	jalr	-392(ra) # 800025cc <wakeup>
  acquire(&p->lock);
    8000275c:	854e                	mv	a0,s3
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	626080e7          	jalr	1574(ra) # 80000d84 <acquire>
  p->xstate = status;
    80002766:	0349a623          	sw	s4,44(s3)
  p->endtime = ticks;
    8000276a:	00006797          	auipc	a5,0x6
    8000276e:	46a7a783          	lw	a5,1130(a5) # 80008bd4 <ticks>
    80002772:	04f9ae23          	sw	a5,92(s3)
  p->state = ZOMBIE;
    80002776:	4795                	li	a5,5
    80002778:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000277c:	8526                	mv	a0,s1
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	6ba080e7          	jalr	1722(ra) # 80000e38 <release>
  sched();
    80002786:	00000097          	auipc	ra,0x0
    8000278a:	b8a080e7          	jalr	-1142(ra) # 80002310 <sched>
  panic("zombie exit");
    8000278e:	00006517          	auipc	a0,0x6
    80002792:	b0250513          	addi	a0,a0,-1278 # 80008290 <digits+0x250>
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	dae080e7          	jalr	-594(ra) # 80000544 <panic>

000000008000279e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000279e:	7179                	addi	sp,sp,-48
    800027a0:	f406                	sd	ra,40(sp)
    800027a2:	f022                	sd	s0,32(sp)
    800027a4:	ec26                	sd	s1,24(sp)
    800027a6:	e84a                	sd	s2,16(sp)
    800027a8:	e44e                	sd	s3,8(sp)
    800027aa:	1800                	addi	s0,sp,48
    800027ac:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800027ae:	0022f497          	auipc	s1,0x22f
    800027b2:	ada48493          	addi	s1,s1,-1318 # 80231288 <proc>
    800027b6:	00236997          	auipc	s3,0x236
    800027ba:	ad298993          	addi	s3,s3,-1326 # 80238288 <tickslock>
  {
    acquire(&p->lock);
    800027be:	8526                	mv	a0,s1
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	5c4080e7          	jalr	1476(ra) # 80000d84 <acquire>
    if (p->pid == pid)
    800027c8:	589c                	lw	a5,48(s1)
    800027ca:	01278d63          	beq	a5,s2,800027e4 <kill+0x46>
#endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027ce:	8526                	mv	a0,s1
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	668080e7          	jalr	1640(ra) # 80000e38 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027d8:	1c048493          	addi	s1,s1,448
    800027dc:	ff3491e3          	bne	s1,s3,800027be <kill+0x20>
  }
  return -1;
    800027e0:	557d                	li	a0,-1
    800027e2:	a829                	j	800027fc <kill+0x5e>
      p->killed = 1;
    800027e4:	4785                	li	a5,1
    800027e6:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800027e8:	4c98                	lw	a4,24(s1)
    800027ea:	4789                	li	a5,2
    800027ec:	00f70f63          	beq	a4,a5,8000280a <kill+0x6c>
      release(&p->lock);
    800027f0:	8526                	mv	a0,s1
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	646080e7          	jalr	1606(ra) # 80000e38 <release>
      return 0;
    800027fa:	4501                	li	a0,0
}
    800027fc:	70a2                	ld	ra,40(sp)
    800027fe:	7402                	ld	s0,32(sp)
    80002800:	64e2                	ld	s1,24(sp)
    80002802:	6942                	ld	s2,16(sp)
    80002804:	69a2                	ld	s3,8(sp)
    80002806:	6145                	addi	sp,sp,48
    80002808:	8082                	ret
        p->state = RUNNABLE;
    8000280a:	478d                	li	a5,3
    8000280c:	cc9c                	sw	a5,24(s1)
        p->last_exec = ticks;
    8000280e:	00006797          	auipc	a5,0x6
    80002812:	3c67a783          	lw	a5,966(a5) # 80008bd4 <ticks>
    80002816:	1af4ac23          	sw	a5,440(s1)
        p->in_time = ticks;
    8000281a:	1782                	slli	a5,a5,0x20
    8000281c:	9381                	srli	a5,a5,0x20
    8000281e:	1af4b423          	sd	a5,424(s1)
        p->tick_ctr = 0;
    80002822:	1a04aa23          	sw	zero,436(s1)
    80002826:	b7e9                	j	800027f0 <kill+0x52>

0000000080002828 <setkilled>:

void setkilled(struct proc *p)
{
    80002828:	1101                	addi	sp,sp,-32
    8000282a:	ec06                	sd	ra,24(sp)
    8000282c:	e822                	sd	s0,16(sp)
    8000282e:	e426                	sd	s1,8(sp)
    80002830:	1000                	addi	s0,sp,32
    80002832:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	550080e7          	jalr	1360(ra) # 80000d84 <acquire>
  p->killed = 1;
    8000283c:	4785                	li	a5,1
    8000283e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002840:	8526                	mv	a0,s1
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	5f6080e7          	jalr	1526(ra) # 80000e38 <release>
}
    8000284a:	60e2                	ld	ra,24(sp)
    8000284c:	6442                	ld	s0,16(sp)
    8000284e:	64a2                	ld	s1,8(sp)
    80002850:	6105                	addi	sp,sp,32
    80002852:	8082                	ret

0000000080002854 <killed>:

int killed(struct proc *p)
{
    80002854:	1101                	addi	sp,sp,-32
    80002856:	ec06                	sd	ra,24(sp)
    80002858:	e822                	sd	s0,16(sp)
    8000285a:	e426                	sd	s1,8(sp)
    8000285c:	e04a                	sd	s2,0(sp)
    8000285e:	1000                	addi	s0,sp,32
    80002860:	84aa                	mv	s1,a0
  int k;
  acquire(&p->lock);
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	522080e7          	jalr	1314(ra) # 80000d84 <acquire>
  k = p->killed;
    8000286a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000286e:	8526                	mv	a0,s1
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	5c8080e7          	jalr	1480(ra) # 80000e38 <release>
  return k;
}
    80002878:	854a                	mv	a0,s2
    8000287a:	60e2                	ld	ra,24(sp)
    8000287c:	6442                	ld	s0,16(sp)
    8000287e:	64a2                	ld	s1,8(sp)
    80002880:	6902                	ld	s2,0(sp)
    80002882:	6105                	addi	sp,sp,32
    80002884:	8082                	ret

0000000080002886 <wait>:
{
    80002886:	715d                	addi	sp,sp,-80
    80002888:	e486                	sd	ra,72(sp)
    8000288a:	e0a2                	sd	s0,64(sp)
    8000288c:	fc26                	sd	s1,56(sp)
    8000288e:	f84a                	sd	s2,48(sp)
    80002890:	f44e                	sd	s3,40(sp)
    80002892:	f052                	sd	s4,32(sp)
    80002894:	ec56                	sd	s5,24(sp)
    80002896:	e85a                	sd	s6,16(sp)
    80002898:	e45e                	sd	s7,8(sp)
    8000289a:	e062                	sd	s8,0(sp)
    8000289c:	0880                	addi	s0,sp,80
    8000289e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800028a0:	fffff097          	auipc	ra,0xfffff
    800028a4:	302080e7          	jalr	770(ra) # 80001ba2 <myproc>
    800028a8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800028aa:	0022e517          	auipc	a0,0x22e
    800028ae:	5c650513          	addi	a0,a0,1478 # 80230e70 <wait_lock>
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	4d2080e7          	jalr	1234(ra) # 80000d84 <acquire>
    havekids = 0;
    800028ba:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800028bc:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028be:	00236997          	auipc	s3,0x236
    800028c2:	9ca98993          	addi	s3,s3,-1590 # 80238288 <tickslock>
        havekids = 1;
    800028c6:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028c8:	0022ec17          	auipc	s8,0x22e
    800028cc:	5a8c0c13          	addi	s8,s8,1448 # 80230e70 <wait_lock>
    havekids = 0;
    800028d0:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028d2:	0022f497          	auipc	s1,0x22f
    800028d6:	9b648493          	addi	s1,s1,-1610 # 80231288 <proc>
    800028da:	a0bd                	j	80002948 <wait+0xc2>
          pid = pp->pid;
    800028dc:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800028e0:	000b0e63          	beqz	s6,800028fc <wait+0x76>
    800028e4:	4691                	li	a3,4
    800028e6:	02c48613          	addi	a2,s1,44
    800028ea:	85da                	mv	a1,s6
    800028ec:	08893503          	ld	a0,136(s2)
    800028f0:	fffff097          	auipc	ra,0xfffff
    800028f4:	f38080e7          	jalr	-200(ra) # 80001828 <copyout>
    800028f8:	02054563          	bltz	a0,80002922 <wait+0x9c>
          freeproc(pp);
    800028fc:	8526                	mv	a0,s1
    800028fe:	fffff097          	auipc	ra,0xfffff
    80002902:	456080e7          	jalr	1110(ra) # 80001d54 <freeproc>
          release(&pp->lock);
    80002906:	8526                	mv	a0,s1
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	530080e7          	jalr	1328(ra) # 80000e38 <release>
          release(&wait_lock);
    80002910:	0022e517          	auipc	a0,0x22e
    80002914:	56050513          	addi	a0,a0,1376 # 80230e70 <wait_lock>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	520080e7          	jalr	1312(ra) # 80000e38 <release>
          return pid;
    80002920:	a0b5                	j	8000298c <wait+0x106>
            release(&pp->lock);
    80002922:	8526                	mv	a0,s1
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	514080e7          	jalr	1300(ra) # 80000e38 <release>
            release(&wait_lock);
    8000292c:	0022e517          	auipc	a0,0x22e
    80002930:	54450513          	addi	a0,a0,1348 # 80230e70 <wait_lock>
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	504080e7          	jalr	1284(ra) # 80000e38 <release>
            return -1;
    8000293c:	59fd                	li	s3,-1
    8000293e:	a0b9                	j	8000298c <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002940:	1c048493          	addi	s1,s1,448
    80002944:	03348463          	beq	s1,s3,8000296c <wait+0xe6>
      if (pp->parent == p)
    80002948:	78bc                	ld	a5,112(s1)
    8000294a:	ff279be3          	bne	a5,s2,80002940 <wait+0xba>
        acquire(&pp->lock);
    8000294e:	8526                	mv	a0,s1
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	434080e7          	jalr	1076(ra) # 80000d84 <acquire>
        if (pp->state == ZOMBIE)
    80002958:	4c9c                	lw	a5,24(s1)
    8000295a:	f94781e3          	beq	a5,s4,800028dc <wait+0x56>
        release(&pp->lock);
    8000295e:	8526                	mv	a0,s1
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	4d8080e7          	jalr	1240(ra) # 80000e38 <release>
        havekids = 1;
    80002968:	8756                	mv	a4,s5
    8000296a:	bfd9                	j	80002940 <wait+0xba>
    if (!havekids || killed(p))
    8000296c:	c719                	beqz	a4,8000297a <wait+0xf4>
    8000296e:	854a                	mv	a0,s2
    80002970:	00000097          	auipc	ra,0x0
    80002974:	ee4080e7          	jalr	-284(ra) # 80002854 <killed>
    80002978:	c51d                	beqz	a0,800029a6 <wait+0x120>
      release(&wait_lock);
    8000297a:	0022e517          	auipc	a0,0x22e
    8000297e:	4f650513          	addi	a0,a0,1270 # 80230e70 <wait_lock>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	4b6080e7          	jalr	1206(ra) # 80000e38 <release>
      return -1;
    8000298a:	59fd                	li	s3,-1
}
    8000298c:	854e                	mv	a0,s3
    8000298e:	60a6                	ld	ra,72(sp)
    80002990:	6406                	ld	s0,64(sp)
    80002992:	74e2                	ld	s1,56(sp)
    80002994:	7942                	ld	s2,48(sp)
    80002996:	79a2                	ld	s3,40(sp)
    80002998:	7a02                	ld	s4,32(sp)
    8000299a:	6ae2                	ld	s5,24(sp)
    8000299c:	6b42                	ld	s6,16(sp)
    8000299e:	6ba2                	ld	s7,8(sp)
    800029a0:	6c02                	ld	s8,0(sp)
    800029a2:	6161                	addi	sp,sp,80
    800029a4:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800029a6:	85e2                	mv	a1,s8
    800029a8:	854a                	mv	a0,s2
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	a78080e7          	jalr	-1416(ra) # 80002422 <sleep>
    havekids = 0;
    800029b2:	bf39                	j	800028d0 <wait+0x4a>

00000000800029b4 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029b4:	7179                	addi	sp,sp,-48
    800029b6:	f406                	sd	ra,40(sp)
    800029b8:	f022                	sd	s0,32(sp)
    800029ba:	ec26                	sd	s1,24(sp)
    800029bc:	e84a                	sd	s2,16(sp)
    800029be:	e44e                	sd	s3,8(sp)
    800029c0:	e052                	sd	s4,0(sp)
    800029c2:	1800                	addi	s0,sp,48
    800029c4:	84aa                	mv	s1,a0
    800029c6:	892e                	mv	s2,a1
    800029c8:	89b2                	mv	s3,a2
    800029ca:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029cc:	fffff097          	auipc	ra,0xfffff
    800029d0:	1d6080e7          	jalr	470(ra) # 80001ba2 <myproc>
  if (user_dst)
    800029d4:	c08d                	beqz	s1,800029f6 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800029d6:	86d2                	mv	a3,s4
    800029d8:	864e                	mv	a2,s3
    800029da:	85ca                	mv	a1,s2
    800029dc:	6548                	ld	a0,136(a0)
    800029de:	fffff097          	auipc	ra,0xfffff
    800029e2:	e4a080e7          	jalr	-438(ra) # 80001828 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029e6:	70a2                	ld	ra,40(sp)
    800029e8:	7402                	ld	s0,32(sp)
    800029ea:	64e2                	ld	s1,24(sp)
    800029ec:	6942                	ld	s2,16(sp)
    800029ee:	69a2                	ld	s3,8(sp)
    800029f0:	6a02                	ld	s4,0(sp)
    800029f2:	6145                	addi	sp,sp,48
    800029f4:	8082                	ret
    memmove((char *)dst, src, len);
    800029f6:	000a061b          	sext.w	a2,s4
    800029fa:	85ce                	mv	a1,s3
    800029fc:	854a                	mv	a0,s2
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	4e2080e7          	jalr	1250(ra) # 80000ee0 <memmove>
    return 0;
    80002a06:	8526                	mv	a0,s1
    80002a08:	bff9                	j	800029e6 <either_copyout+0x32>

0000000080002a0a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a0a:	7179                	addi	sp,sp,-48
    80002a0c:	f406                	sd	ra,40(sp)
    80002a0e:	f022                	sd	s0,32(sp)
    80002a10:	ec26                	sd	s1,24(sp)
    80002a12:	e84a                	sd	s2,16(sp)
    80002a14:	e44e                	sd	s3,8(sp)
    80002a16:	e052                	sd	s4,0(sp)
    80002a18:	1800                	addi	s0,sp,48
    80002a1a:	892a                	mv	s2,a0
    80002a1c:	84ae                	mv	s1,a1
    80002a1e:	89b2                	mv	s3,a2
    80002a20:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a22:	fffff097          	auipc	ra,0xfffff
    80002a26:	180080e7          	jalr	384(ra) # 80001ba2 <myproc>
  if (user_src)
    80002a2a:	c08d                	beqz	s1,80002a4c <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002a2c:	86d2                	mv	a3,s4
    80002a2e:	864e                	mv	a2,s3
    80002a30:	85ca                	mv	a1,s2
    80002a32:	6548                	ld	a0,136(a0)
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	eb8080e7          	jalr	-328(ra) # 800018ec <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002a3c:	70a2                	ld	ra,40(sp)
    80002a3e:	7402                	ld	s0,32(sp)
    80002a40:	64e2                	ld	s1,24(sp)
    80002a42:	6942                	ld	s2,16(sp)
    80002a44:	69a2                	ld	s3,8(sp)
    80002a46:	6a02                	ld	s4,0(sp)
    80002a48:	6145                	addi	sp,sp,48
    80002a4a:	8082                	ret
    memmove(dst, (char *)src, len);
    80002a4c:	000a061b          	sext.w	a2,s4
    80002a50:	85ce                	mv	a1,s3
    80002a52:	854a                	mv	a0,s2
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	48c080e7          	jalr	1164(ra) # 80000ee0 <memmove>
    return 0;
    80002a5c:	8526                	mv	a0,s1
    80002a5e:	bff9                	j	80002a3c <either_copyin+0x32>

0000000080002a60 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002a60:	715d                	addi	sp,sp,-80
    80002a62:	e486                	sd	ra,72(sp)
    80002a64:	e0a2                	sd	s0,64(sp)
    80002a66:	fc26                	sd	s1,56(sp)
    80002a68:	f84a                	sd	s2,48(sp)
    80002a6a:	f44e                	sd	s3,40(sp)
    80002a6c:	f052                	sd	s4,32(sp)
    80002a6e:	ec56                	sd	s5,24(sp)
    80002a70:	e85a                	sd	s6,16(sp)
    80002a72:	e45e                	sd	s7,8(sp)
    80002a74:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002a76:	00005517          	auipc	a0,0x5
    80002a7a:	67250513          	addi	a0,a0,1650 # 800080e8 <digits+0xa8>
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	b10080e7          	jalr	-1264(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a86:	0022f497          	auipc	s1,0x22f
    80002a8a:	99a48493          	addi	s1,s1,-1638 # 80231420 <proc+0x198>
    80002a8e:	00236917          	auipc	s2,0x236
    80002a92:	99290913          	addi	s2,s2,-1646 # 80238420 <bcache+0x180>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a96:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a98:	00006997          	auipc	s3,0x6
    80002a9c:	80898993          	addi	s3,s3,-2040 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002aa0:	00006a97          	auipc	s5,0x6
    80002aa4:	808a8a93          	addi	s5,s5,-2040 # 800082a8 <digits+0x268>
    printf("\n");
    80002aa8:	00005a17          	auipc	s4,0x5
    80002aac:	640a0a13          	addi	s4,s4,1600 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ab0:	00006b97          	auipc	s7,0x6
    80002ab4:	838b8b93          	addi	s7,s7,-1992 # 800082e8 <states.1783>
    80002ab8:	a00d                	j	80002ada <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002aba:	e986a583          	lw	a1,-360(a3)
    80002abe:	8556                	mv	a0,s5
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	ace080e7          	jalr	-1330(ra) # 8000058e <printf>
    printf("\n");
    80002ac8:	8552                	mv	a0,s4
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	ac4080e7          	jalr	-1340(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ad2:	1c048493          	addi	s1,s1,448
    80002ad6:	03248163          	beq	s1,s2,80002af8 <procdump+0x98>
    if (p->state == UNUSED)
    80002ada:	86a6                	mv	a3,s1
    80002adc:	e804a783          	lw	a5,-384(s1)
    80002ae0:	dbed                	beqz	a5,80002ad2 <procdump+0x72>
      state = "???";
    80002ae2:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ae4:	fcfb6be3          	bltu	s6,a5,80002aba <procdump+0x5a>
    80002ae8:	1782                	slli	a5,a5,0x20
    80002aea:	9381                	srli	a5,a5,0x20
    80002aec:	078e                	slli	a5,a5,0x3
    80002aee:	97de                	add	a5,a5,s7
    80002af0:	6390                	ld	a2,0(a5)
    80002af2:	f661                	bnez	a2,80002aba <procdump+0x5a>
      state = "???";
    80002af4:	864e                	mv	a2,s3
    80002af6:	b7d1                	j	80002aba <procdump+0x5a>
  }
}
    80002af8:	60a6                	ld	ra,72(sp)
    80002afa:	6406                	ld	s0,64(sp)
    80002afc:	74e2                	ld	s1,56(sp)
    80002afe:	7942                	ld	s2,48(sp)
    80002b00:	79a2                	ld	s3,40(sp)
    80002b02:	7a02                	ld	s4,32(sp)
    80002b04:	6ae2                	ld	s5,24(sp)
    80002b06:	6b42                	ld	s6,16(sp)
    80002b08:	6ba2                	ld	s7,8(sp)
    80002b0a:	6161                	addi	sp,sp,80
    80002b0c:	8082                	ret

0000000080002b0e <swtch>:
    80002b0e:	00153023          	sd	ra,0(a0)
    80002b12:	00253423          	sd	sp,8(a0)
    80002b16:	e900                	sd	s0,16(a0)
    80002b18:	ed04                	sd	s1,24(a0)
    80002b1a:	03253023          	sd	s2,32(a0)
    80002b1e:	03353423          	sd	s3,40(a0)
    80002b22:	03453823          	sd	s4,48(a0)
    80002b26:	03553c23          	sd	s5,56(a0)
    80002b2a:	05653023          	sd	s6,64(a0)
    80002b2e:	05753423          	sd	s7,72(a0)
    80002b32:	05853823          	sd	s8,80(a0)
    80002b36:	05953c23          	sd	s9,88(a0)
    80002b3a:	07a53023          	sd	s10,96(a0)
    80002b3e:	07b53423          	sd	s11,104(a0)
    80002b42:	0005b083          	ld	ra,0(a1)
    80002b46:	0085b103          	ld	sp,8(a1)
    80002b4a:	6980                	ld	s0,16(a1)
    80002b4c:	6d84                	ld	s1,24(a1)
    80002b4e:	0205b903          	ld	s2,32(a1)
    80002b52:	0285b983          	ld	s3,40(a1)
    80002b56:	0305ba03          	ld	s4,48(a1)
    80002b5a:	0385ba83          	ld	s5,56(a1)
    80002b5e:	0405bb03          	ld	s6,64(a1)
    80002b62:	0485bb83          	ld	s7,72(a1)
    80002b66:	0505bc03          	ld	s8,80(a1)
    80002b6a:	0585bc83          	ld	s9,88(a1)
    80002b6e:	0605bd03          	ld	s10,96(a1)
    80002b72:	0685bd83          	ld	s11,104(a1)
    80002b76:	8082                	ret

0000000080002b78 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b78:	1141                	addi	sp,sp,-16
    80002b7a:	e406                	sd	ra,8(sp)
    80002b7c:	e022                	sd	s0,0(sp)
    80002b7e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b80:	00005597          	auipc	a1,0x5
    80002b84:	79858593          	addi	a1,a1,1944 # 80008318 <states.1783+0x30>
    80002b88:	00235517          	auipc	a0,0x235
    80002b8c:	70050513          	addi	a0,a0,1792 # 80238288 <tickslock>
    80002b90:	ffffe097          	auipc	ra,0xffffe
    80002b94:	164080e7          	jalr	356(ra) # 80000cf4 <initlock>
}
    80002b98:	60a2                	ld	ra,8(sp)
    80002b9a:	6402                	ld	s0,0(sp)
    80002b9c:	0141                	addi	sp,sp,16
    80002b9e:	8082                	ret

0000000080002ba0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002ba0:	1141                	addi	sp,sp,-16
    80002ba2:	e422                	sd	s0,8(sp)
    80002ba4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ba6:	00004797          	auipc	a5,0x4
    80002baa:	bfa78793          	addi	a5,a5,-1030 # 800067a0 <kernelvec>
    80002bae:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bb2:	6422                	ld	s0,8(sp)
    80002bb4:	0141                	addi	sp,sp,16
    80002bb6:	8082                	ret

0000000080002bb8 <write_trap>:
int write_trap(void *va, pagetable_t pagetable)
{
    80002bb8:	7179                	addi	sp,sp,-48
    80002bba:	f406                	sd	ra,40(sp)
    80002bbc:	f022                	sd	s0,32(sp)
    80002bbe:	ec26                	sd	s1,24(sp)
    80002bc0:	e84a                	sd	s2,16(sp)
    80002bc2:	e44e                	sd	s3,8(sp)
    80002bc4:	e052                	sd	s4,0(sp)
    80002bc6:	1800                	addi	s0,sp,48
    80002bc8:	84aa                	mv	s1,a0
    80002bca:	892e                	mv	s2,a1

  struct proc *p = myproc();
    80002bcc:	fffff097          	auipc	ra,0xfffff
    80002bd0:	fd6080e7          	jalr	-42(ra) # 80001ba2 <myproc>
  if ((uint64)va < MAXVA && ((uint64)va < PGROUNDDOWN(p->trapframe->sp) - PGSIZE || (uint64)va > PGROUNDDOWN(p->trapframe->sp)))
    80002bd4:	57fd                	li	a5,-1
    80002bd6:	83e9                	srli	a5,a5,0x1a
    80002bd8:	0897e563          	bltu	a5,s1,80002c62 <write_trap+0xaa>
    80002bdc:	6958                	ld	a4,144(a0)
    80002bde:	77fd                	lui	a5,0xfffff
    80002be0:	7b18                	ld	a4,48(a4)
    80002be2:	8f7d                	and	a4,a4,a5
    80002be4:	97ba                	add	a5,a5,a4
    80002be6:	00f4e463          	bltu	s1,a5,80002bee <write_trap+0x36>
    80002bea:	06977e63          	bgeu	a4,s1,80002c66 <write_trap+0xae>
  {
    pte_t *pte;
    uint64 pa;
    uint flags;
    va = (void *)PGROUNDDOWN((uint64)va);
    pte = walk(pagetable, (uint64)va, 0);
    80002bee:	4601                	li	a2,0
    80002bf0:	75fd                	lui	a1,0xfffff
    80002bf2:	8de5                	and	a1,a1,s1
    80002bf4:	854a                	mv	a0,s2
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	576080e7          	jalr	1398(ra) # 8000116c <walk>
    80002bfe:	892a                	mv	s2,a0
    if (pte)
    80002c00:	c52d                	beqz	a0,80002c6a <write_trap+0xb2>
    {
      pa = PTE2PA(*pte);
    80002c02:	611c                	ld	a5,0(a0)
    80002c04:	00a7d993          	srli	s3,a5,0xa
    80002c08:	09b2                	slli	s3,s3,0xc
      if(!pa) return -1;
    80002c0a:	06098263          	beqz	s3,80002c6e <write_trap+0xb6>
    }
    else
    {
      return -1;
    }
    flags = PTE_FLAGS(*pte);
    80002c0e:	2781                	sext.w	a5,a5
    if (flags & PTE_C)
    80002c10:	0207f713          	andi	a4,a5,32
      memmove(mem, (void *)pa, PGSIZE);
      *pte = PA2PTE(mem) | flags;
      kfree((void *)pa);
      return 0;
    }
    return 0;
    80002c14:	4501                	li	a0,0
    if (flags & PTE_C)
    80002c16:	eb09                	bnez	a4,80002c28 <write_trap+0x70>
  }
  else
  {
    return -1;
  }
}
    80002c18:	70a2                	ld	ra,40(sp)
    80002c1a:	7402                	ld	s0,32(sp)
    80002c1c:	64e2                	ld	s1,24(sp)
    80002c1e:	6942                	ld	s2,16(sp)
    80002c20:	69a2                	ld	s3,8(sp)
    80002c22:	6a02                	ld	s4,0(sp)
    80002c24:	6145                	addi	sp,sp,48
    80002c26:	8082                	ret
      flags &= (~PTE_C);
    80002c28:	3df7f793          	andi	a5,a5,991
    80002c2c:	0047e493          	ori	s1,a5,4
      mem = kalloc();
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	050080e7          	jalr	80(ra) # 80000c80 <kalloc>
    80002c38:	8a2a                	mv	s4,a0
      if (!mem)
    80002c3a:	cd05                	beqz	a0,80002c72 <write_trap+0xba>
      memmove(mem, (void *)pa, PGSIZE);
    80002c3c:	6605                	lui	a2,0x1
    80002c3e:	85ce                	mv	a1,s3
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	2a0080e7          	jalr	672(ra) # 80000ee0 <memmove>
      *pte = PA2PTE(mem) | flags;
    80002c48:	00ca5793          	srli	a5,s4,0xc
    80002c4c:	07aa                	slli	a5,a5,0xa
    80002c4e:	8fc5                	or	a5,a5,s1
    80002c50:	00f93023          	sd	a5,0(s2)
      kfree((void *)pa);
    80002c54:	854e                	mv	a0,s3
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	ee6080e7          	jalr	-282(ra) # 80000b3c <kfree>
      return 0;
    80002c5e:	4501                	li	a0,0
    80002c60:	bf65                	j	80002c18 <write_trap+0x60>
    return -1;
    80002c62:	557d                	li	a0,-1
    80002c64:	bf55                	j	80002c18 <write_trap+0x60>
    80002c66:	557d                	li	a0,-1
    80002c68:	bf45                	j	80002c18 <write_trap+0x60>
      return -1;
    80002c6a:	557d                	li	a0,-1
    80002c6c:	b775                	j	80002c18 <write_trap+0x60>
      if(!pa) return -1;
    80002c6e:	557d                	li	a0,-1
    80002c70:	b765                	j	80002c18 <write_trap+0x60>
        return -1;
    80002c72:	557d                	li	a0,-1
    80002c74:	b755                	j	80002c18 <write_trap+0x60>

0000000080002c76 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002c76:	1141                	addi	sp,sp,-16
    80002c78:	e406                	sd	ra,8(sp)
    80002c7a:	e022                	sd	s0,0(sp)
    80002c7c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	f24080e7          	jalr	-220(ra) # 80001ba2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c8a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c8c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c90:	00004617          	auipc	a2,0x4
    80002c94:	37060613          	addi	a2,a2,880 # 80007000 <_trampoline>
    80002c98:	00004697          	auipc	a3,0x4
    80002c9c:	36868693          	addi	a3,a3,872 # 80007000 <_trampoline>
    80002ca0:	8e91                	sub	a3,a3,a2
    80002ca2:	040007b7          	lui	a5,0x4000
    80002ca6:	17fd                	addi	a5,a5,-1
    80002ca8:	07b2                	slli	a5,a5,0xc
    80002caa:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cac:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cb0:	6958                	ld	a4,144(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cb2:	180026f3          	csrr	a3,satp
    80002cb6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002cb8:	6958                	ld	a4,144(a0)
    80002cba:	7d34                	ld	a3,120(a0)
    80002cbc:	6585                	lui	a1,0x1
    80002cbe:	96ae                	add	a3,a3,a1
    80002cc0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002cc2:	6958                	ld	a4,144(a0)
    80002cc4:	00000697          	auipc	a3,0x0
    80002cc8:	19268693          	addi	a3,a3,402 # 80002e56 <usertrap>
    80002ccc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002cce:	6958                	ld	a4,144(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002cd0:	8692                	mv	a3,tp
    80002cd2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cd4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002cd8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002cdc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ce0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ce4:	6958                	ld	a4,144(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ce6:	6f18                	ld	a4,24(a4)
    80002ce8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002cec:	6548                	ld	a0,136(a0)
    80002cee:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002cf0:	00004717          	auipc	a4,0x4
    80002cf4:	3ac70713          	addi	a4,a4,940 # 8000709c <userret>
    80002cf8:	8f11                	sub	a4,a4,a2
    80002cfa:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002cfc:	577d                	li	a4,-1
    80002cfe:	177e                	slli	a4,a4,0x3f
    80002d00:	8d59                	or	a0,a0,a4
    80002d02:	9782                	jalr	a5
}
    80002d04:	60a2                	ld	ra,8(sp)
    80002d06:	6402                	ld	s0,0(sp)
    80002d08:	0141                	addi	sp,sp,16
    80002d0a:	8082                	ret

0000000080002d0c <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002d0c:	7179                	addi	sp,sp,-48
    80002d0e:	f406                	sd	ra,40(sp)
    80002d10:	f022                	sd	s0,32(sp)
    80002d12:	ec26                	sd	s1,24(sp)
    80002d14:	e84a                	sd	s2,16(sp)
    80002d16:	e44e                	sd	s3,8(sp)
    80002d18:	e052                	sd	s4,0(sp)
    80002d1a:	1800                	addi	s0,sp,48
  acquire(&tickslock);
    80002d1c:	00235517          	auipc	a0,0x235
    80002d20:	56c50513          	addi	a0,a0,1388 # 80238288 <tickslock>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	060080e7          	jalr	96(ra) # 80000d84 <acquire>
  ticks++;
    80002d2c:	00006717          	auipc	a4,0x6
    80002d30:	ea870713          	addi	a4,a4,-344 # 80008bd4 <ticks>
    80002d34:	431c                	lw	a5,0(a4)
    80002d36:	2785                	addiw	a5,a5,1
    80002d38:	c31c                	sw	a5,0(a4)
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002d3a:	0022e497          	auipc	s1,0x22e
    80002d3e:	54e48493          	addi	s1,s1,1358 # 80231288 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002d42:	4991                	li	s3,4
      p->trtime++;
#ifdef PBS
      p->runtime++;
#endif
    }
    if (p->state == SLEEPING)
    80002d44:	4a09                	li	s4,2
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002d46:	00235917          	auipc	s2,0x235
    80002d4a:	54290913          	addi	s2,s2,1346 # 80238288 <tickslock>
    80002d4e:	a829                	j	80002d68 <clockintr+0x5c>
      p->trtime++;
    80002d50:	44fc                	lw	a5,76(s1)
    80002d52:	2785                	addiw	a5,a5,1
    80002d54:	c4fc                	sw	a5,76(s1)
      p->twtime++;
#ifdef PBS
      p->waittime++;
#endif
    }
    release(&p->lock);
    80002d56:	8526                	mv	a0,s1
    80002d58:	ffffe097          	auipc	ra,0xffffe
    80002d5c:	0e0080e7          	jalr	224(ra) # 80000e38 <release>
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    80002d60:	1c048493          	addi	s1,s1,448
    80002d64:	03248063          	beq	s1,s2,80002d84 <clockintr+0x78>
    acquire(&p->lock);
    80002d68:	8526                	mv	a0,s1
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	01a080e7          	jalr	26(ra) # 80000d84 <acquire>
    if (p->state == RUNNING)
    80002d72:	4c9c                	lw	a5,24(s1)
    80002d74:	fd378ee3          	beq	a5,s3,80002d50 <clockintr+0x44>
    if (p->state == SLEEPING)
    80002d78:	fd479fe3          	bne	a5,s4,80002d56 <clockintr+0x4a>
      p->twtime++;
    80002d7c:	48bc                	lw	a5,80(s1)
    80002d7e:	2785                	addiw	a5,a5,1
    80002d80:	c8bc                	sw	a5,80(s1)
    80002d82:	bfd1                	j	80002d56 <clockintr+0x4a>
  }
  wakeup(&ticks);
    80002d84:	00006517          	auipc	a0,0x6
    80002d88:	e5050513          	addi	a0,a0,-432 # 80008bd4 <ticks>
    80002d8c:	00000097          	auipc	ra,0x0
    80002d90:	840080e7          	jalr	-1984(ra) # 800025cc <wakeup>
  release(&tickslock);
    80002d94:	00235517          	auipc	a0,0x235
    80002d98:	4f450513          	addi	a0,a0,1268 # 80238288 <tickslock>
    80002d9c:	ffffe097          	auipc	ra,0xffffe
    80002da0:	09c080e7          	jalr	156(ra) # 80000e38 <release>
}
    80002da4:	70a2                	ld	ra,40(sp)
    80002da6:	7402                	ld	s0,32(sp)
    80002da8:	64e2                	ld	s1,24(sp)
    80002daa:	6942                	ld	s2,16(sp)
    80002dac:	69a2                	ld	s3,8(sp)
    80002dae:	6a02                	ld	s4,0(sp)
    80002db0:	6145                	addi	sp,sp,48
    80002db2:	8082                	ret

0000000080002db4 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002db4:	1101                	addi	sp,sp,-32
    80002db6:	ec06                	sd	ra,24(sp)
    80002db8:	e822                	sd	s0,16(sp)
    80002dba:	e426                	sd	s1,8(sp)
    80002dbc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dbe:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002dc2:	00074d63          	bltz	a4,80002ddc <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002dc6:	57fd                	li	a5,-1
    80002dc8:	17fe                	slli	a5,a5,0x3f
    80002dca:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002dcc:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002dce:	06f70363          	beq	a4,a5,80002e34 <devintr+0x80>
  }
}
    80002dd2:	60e2                	ld	ra,24(sp)
    80002dd4:	6442                	ld	s0,16(sp)
    80002dd6:	64a2                	ld	s1,8(sp)
    80002dd8:	6105                	addi	sp,sp,32
    80002dda:	8082                	ret
      (scause & 0xff) == 9)
    80002ddc:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002de0:	46a5                	li	a3,9
    80002de2:	fed792e3          	bne	a5,a3,80002dc6 <devintr+0x12>
    int irq = plic_claim();
    80002de6:	00004097          	auipc	ra,0x4
    80002dea:	ac2080e7          	jalr	-1342(ra) # 800068a8 <plic_claim>
    80002dee:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002df0:	47a9                	li	a5,10
    80002df2:	02f50763          	beq	a0,a5,80002e20 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002df6:	4785                	li	a5,1
    80002df8:	02f50963          	beq	a0,a5,80002e2a <devintr+0x76>
    return 1;
    80002dfc:	4505                	li	a0,1
    else if (irq)
    80002dfe:	d8f1                	beqz	s1,80002dd2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e00:	85a6                	mv	a1,s1
    80002e02:	00005517          	auipc	a0,0x5
    80002e06:	51e50513          	addi	a0,a0,1310 # 80008320 <states.1783+0x38>
    80002e0a:	ffffd097          	auipc	ra,0xffffd
    80002e0e:	784080e7          	jalr	1924(ra) # 8000058e <printf>
      plic_complete(irq);
    80002e12:	8526                	mv	a0,s1
    80002e14:	00004097          	auipc	ra,0x4
    80002e18:	ab8080e7          	jalr	-1352(ra) # 800068cc <plic_complete>
    return 1;
    80002e1c:	4505                	li	a0,1
    80002e1e:	bf55                	j	80002dd2 <devintr+0x1e>
      uartintr();
    80002e20:	ffffe097          	auipc	ra,0xffffe
    80002e24:	b8e080e7          	jalr	-1138(ra) # 800009ae <uartintr>
    80002e28:	b7ed                	j	80002e12 <devintr+0x5e>
      virtio_disk_intr();
    80002e2a:	00004097          	auipc	ra,0x4
    80002e2e:	fcc080e7          	jalr	-52(ra) # 80006df6 <virtio_disk_intr>
    80002e32:	b7c5                	j	80002e12 <devintr+0x5e>
    if (cpuid() == 0)
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	d42080e7          	jalr	-702(ra) # 80001b76 <cpuid>
    80002e3c:	c901                	beqz	a0,80002e4c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e3e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e42:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e44:	14479073          	csrw	sip,a5
    return 2;
    80002e48:	4509                	li	a0,2
    80002e4a:	b761                	j	80002dd2 <devintr+0x1e>
      clockintr();
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	ec0080e7          	jalr	-320(ra) # 80002d0c <clockintr>
    80002e54:	b7ed                	j	80002e3e <devintr+0x8a>

0000000080002e56 <usertrap>:
{
    80002e56:	715d                	addi	sp,sp,-80
    80002e58:	e486                	sd	ra,72(sp)
    80002e5a:	e0a2                	sd	s0,64(sp)
    80002e5c:	fc26                	sd	s1,56(sp)
    80002e5e:	f84a                	sd	s2,48(sp)
    80002e60:	f44e                	sd	s3,40(sp)
    80002e62:	f052                	sd	s4,32(sp)
    80002e64:	ec56                	sd	s5,24(sp)
    80002e66:	e85a                	sd	s6,16(sp)
    80002e68:	e45e                	sd	s7,8(sp)
    80002e6a:	e062                	sd	s8,0(sp)
    80002e6c:	0880                	addi	s0,sp,80
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e6e:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002e72:	1007f793          	andi	a5,a5,256
    80002e76:	e7b1                	bnez	a5,80002ec2 <usertrap+0x6c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e78:	00004797          	auipc	a5,0x4
    80002e7c:	92878793          	addi	a5,a5,-1752 # 800067a0 <kernelvec>
    80002e80:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	d1e080e7          	jalr	-738(ra) # 80001ba2 <myproc>
    80002e8c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e8e:	695c                	ld	a5,144(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e90:	14102773          	csrr	a4,sepc
    80002e94:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e96:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002e9a:	47a1                	li	a5,8
    80002e9c:	02f70b63          	beq	a4,a5,80002ed2 <usertrap+0x7c>
  else if ((which_dev = devintr()) != 0)
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	f14080e7          	jalr	-236(ra) # 80002db4 <devintr>
    80002ea8:	892a                	mv	s2,a0
    80002eaa:	ed69                	bnez	a0,80002f84 <usertrap+0x12e>
    80002eac:	14202773          	csrr	a4,scause
  else if (r_scause() == 15)
    80002eb0:	47bd                	li	a5,15
    80002eb2:	08f71c63          	bne	a4,a5,80002f4a <usertrap+0xf4>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eb6:	143027f3          	csrr	a5,stval
    if (r_stval() == 0)
    80002eba:	ebbd                	bnez	a5,80002f30 <usertrap+0xda>
      p->killed = 1;
    80002ebc:	4785                	li	a5,1
    80002ebe:	d49c                	sw	a5,40(s1)
    80002ec0:	a825                	j	80002ef8 <usertrap+0xa2>
    panic("usertrap: not from user mode");
    80002ec2:	00005517          	auipc	a0,0x5
    80002ec6:	47e50513          	addi	a0,a0,1150 # 80008340 <states.1783+0x58>
    80002eca:	ffffd097          	auipc	ra,0xffffd
    80002ece:	67a080e7          	jalr	1658(ra) # 80000544 <panic>
    if (killed(p))
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	982080e7          	jalr	-1662(ra) # 80002854 <killed>
    80002eda:	e529                	bnez	a0,80002f24 <usertrap+0xce>
    p->trapframe->epc += 4;
    80002edc:	68d8                	ld	a4,144(s1)
    80002ede:	6f1c                	ld	a5,24(a4)
    80002ee0:	0791                	addi	a5,a5,4
    80002ee2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ee4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ee8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eec:	10079073          	csrw	sstatus,a5
    syscall();
    80002ef0:	00000097          	auipc	ra,0x0
    80002ef4:	5ec080e7          	jalr	1516(ra) # 800034dc <syscall>
  if (killed(p))
    80002ef8:	8526                	mv	a0,s1
    80002efa:	00000097          	auipc	ra,0x0
    80002efe:	95a080e7          	jalr	-1702(ra) # 80002854 <killed>
    80002f02:	e941                	bnez	a0,80002f92 <usertrap+0x13c>
  usertrapret();
    80002f04:	00000097          	auipc	ra,0x0
    80002f08:	d72080e7          	jalr	-654(ra) # 80002c76 <usertrapret>
}
    80002f0c:	60a6                	ld	ra,72(sp)
    80002f0e:	6406                	ld	s0,64(sp)
    80002f10:	74e2                	ld	s1,56(sp)
    80002f12:	7942                	ld	s2,48(sp)
    80002f14:	79a2                	ld	s3,40(sp)
    80002f16:	7a02                	ld	s4,32(sp)
    80002f18:	6ae2                	ld	s5,24(sp)
    80002f1a:	6b42                	ld	s6,16(sp)
    80002f1c:	6ba2                	ld	s7,8(sp)
    80002f1e:	6c02                	ld	s8,0(sp)
    80002f20:	6161                	addi	sp,sp,80
    80002f22:	8082                	ret
      exit(-1);
    80002f24:	557d                	li	a0,-1
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	796080e7          	jalr	1942(ra) # 800026bc <exit>
    80002f2e:	b77d                	j	80002edc <usertrap+0x86>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f30:	14302573          	csrr	a0,stval
      int res = write_trap((void *)r_stval(), p->pagetable);
    80002f34:	64cc                	ld	a1,136(s1)
    80002f36:	00000097          	auipc	ra,0x0
    80002f3a:	c82080e7          	jalr	-894(ra) # 80002bb8 <write_trap>
      if (res == -1)
    80002f3e:	57fd                	li	a5,-1
    80002f40:	faf51ce3          	bne	a0,a5,80002ef8 <usertrap+0xa2>
        p->killed = 1;
    80002f44:	4785                	li	a5,1
    80002f46:	d49c                	sw	a5,40(s1)
    80002f48:	bf45                	j	80002ef8 <usertrap+0xa2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f4a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f4e:	5890                	lw	a2,48(s1)
    80002f50:	00005517          	auipc	a0,0x5
    80002f54:	41050513          	addi	a0,a0,1040 # 80008360 <states.1783+0x78>
    80002f58:	ffffd097          	auipc	ra,0xffffd
    80002f5c:	636080e7          	jalr	1590(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f60:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f64:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f68:	00005517          	auipc	a0,0x5
    80002f6c:	42850513          	addi	a0,a0,1064 # 80008390 <states.1783+0xa8>
    80002f70:	ffffd097          	auipc	ra,0xffffd
    80002f74:	61e080e7          	jalr	1566(ra) # 8000058e <printf>
    setkilled(p);
    80002f78:	8526                	mv	a0,s1
    80002f7a:	00000097          	auipc	ra,0x0
    80002f7e:	8ae080e7          	jalr	-1874(ra) # 80002828 <setkilled>
    80002f82:	bf9d                	j	80002ef8 <usertrap+0xa2>
  if (killed(p))
    80002f84:	8526                	mv	a0,s1
    80002f86:	00000097          	auipc	ra,0x0
    80002f8a:	8ce080e7          	jalr	-1842(ra) # 80002854 <killed>
    80002f8e:	c901                	beqz	a0,80002f9e <usertrap+0x148>
    80002f90:	a011                	j	80002f94 <usertrap+0x13e>
    80002f92:	4901                	li	s2,0
    exit(-1);
    80002f94:	557d                	li	a0,-1
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	726080e7          	jalr	1830(ra) # 800026bc <exit>
  if (which_dev == 2)
    80002f9e:	4789                	li	a5,2
    80002fa0:	f6f912e3          	bne	s2,a5,80002f04 <usertrap+0xae>
    myproc()->ticks_after++;
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	bfe080e7          	jalr	-1026(ra) # 80001ba2 <myproc>
    80002fac:	413c                	lw	a5,64(a0)
    80002fae:	2785                	addiw	a5,a5,1
    80002fb0:	c13c                	sw	a5,64(a0)
    if (myproc()->alarm && myproc()->ticks == myproc()->ticks_after)
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	bf0080e7          	jalr	-1040(ra) # 80001ba2 <myproc>
    80002fba:	5d1c                	lw	a5,56(a0)
    80002fbc:	e79d                	bnez	a5,80002fea <usertrap+0x194>
    p->tick_ctr++;
    80002fbe:	1b44a783          	lw	a5,436(s1)
    80002fc2:	2785                	addiw	a5,a5,1
    80002fc4:	1af4aa23          	sw	a5,436(s1)
    int flg = 0;
    80002fc8:	4b01                	li	s6,0
    for (p = proc; p < &proc[NPROC]; p++)
    80002fca:	0022e497          	auipc	s1,0x22e
    80002fce:	2be48493          	addi	s1,s1,702 # 80231288 <proc>
      if (p->state ==RUNNABLE && ticks - p->last_exec > WAIT_TIME)
    80002fd2:	498d                	li	s3,3
    80002fd4:	00006a97          	auipc	s5,0x6
    80002fd8:	c00a8a93          	addi	s5,s5,-1024 # 80008bd4 <ticks>
    80002fdc:	4a79                	li	s4,30
        flg = 1;
    80002fde:	4b85                	li	s7,1
    for (p = proc; p < &proc[NPROC]; p++)
    80002fe0:	00235917          	auipc	s2,0x235
    80002fe4:	2a890913          	addi	s2,s2,680 # 80238288 <tickslock>
    80002fe8:	aa35                	j	80003124 <usertrap+0x2ce>
    if (myproc()->alarm && myproc()->ticks == myproc()->ticks_after)
    80002fea:	fffff097          	auipc	ra,0xfffff
    80002fee:	bb8080e7          	jalr	-1096(ra) # 80001ba2 <myproc>
    80002ff2:	03c52903          	lw	s2,60(a0)
    80002ff6:	fffff097          	auipc	ra,0xfffff
    80002ffa:	bac080e7          	jalr	-1108(ra) # 80001ba2 <myproc>
    80002ffe:	413c                	lw	a5,64(a0)
    80003000:	fb279fe3          	bne	a5,s2,80002fbe <usertrap+0x168>
      *(myproc()->copy) = *(myproc()->trapframe);
    80003004:	fffff097          	auipc	ra,0xfffff
    80003008:	b9e080e7          	jalr	-1122(ra) # 80001ba2 <myproc>
    8000300c:	09053903          	ld	s2,144(a0)
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	b92080e7          	jalr	-1134(ra) # 80001ba2 <myproc>
    80003018:	87ca                	mv	a5,s2
    8000301a:	6d58                	ld	a4,152(a0)
    8000301c:	12090693          	addi	a3,s2,288
    80003020:	0007b803          	ld	a6,0(a5)
    80003024:	6788                	ld	a0,8(a5)
    80003026:	6b8c                	ld	a1,16(a5)
    80003028:	6f90                	ld	a2,24(a5)
    8000302a:	01073023          	sd	a6,0(a4)
    8000302e:	e708                	sd	a0,8(a4)
    80003030:	eb0c                	sd	a1,16(a4)
    80003032:	ef10                	sd	a2,24(a4)
    80003034:	02078793          	addi	a5,a5,32
    80003038:	02070713          	addi	a4,a4,32
    8000303c:	fed792e3          	bne	a5,a3,80003020 <usertrap+0x1ca>
      myproc()->trapframe->epc = myproc()->handler;
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	b62080e7          	jalr	-1182(ra) # 80001ba2 <myproc>
    80003048:	892a                	mv	s2,a0
    8000304a:	fffff097          	auipc	ra,0xfffff
    8000304e:	b58080e7          	jalr	-1192(ra) # 80001ba2 <myproc>
    80003052:	695c                	ld	a5,144(a0)
    80003054:	06093703          	ld	a4,96(s2)
    80003058:	ef98                	sd	a4,24(a5)
      myproc()->ticks_after = 0;
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	b48080e7          	jalr	-1208(ra) # 80001ba2 <myproc>
    80003062:	04052023          	sw	zero,64(a0)
      myproc()->alarm = 0;
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	b3c080e7          	jalr	-1220(ra) # 80001ba2 <myproc>
    8000306e:	02052c23          	sw	zero,56(a0)
    80003072:	b7b1                	j	80002fbe <usertrap+0x168>
    p_sched = myproc();
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	b2e080e7          	jalr	-1234(ra) # 80001ba2 <myproc>
    int x = p_sched->queue_level;
    8000307c:	1b052603          	lw	a2,432(a0)
    while (x--)
    80003080:	fff6079b          	addiw	a5,a2,-1
    80003084:	ca39                	beqz	a2,800030da <usertrap+0x284>
    int y = 1;
    80003086:	4705                	li	a4,1
    while (x--)
    80003088:	56fd                	li	a3,-1
      y *= 2;
    8000308a:	0017171b          	slliw	a4,a4,0x1
    while (x--)
    8000308e:	37fd                	addiw	a5,a5,-1
    80003090:	fed79de3          	bne	a5,a3,8000308a <usertrap+0x234>
    if (p_sched->tick_ctr == y)
    80003094:	1b452783          	lw	a5,436(a0)
    80003098:	02e78163          	beq	a5,a4,800030ba <usertrap+0x264>
    else if (flg == 1)
    8000309c:	e60b04e3          	beqz	s6,80002f04 <usertrap+0xae>
      p_sched->tick_ctr = 0;
    800030a0:	1a052a23          	sw	zero,436(a0)
      p_sched->in_time = ticks;
    800030a4:	00006797          	auipc	a5,0x6
    800030a8:	b307e783          	lwu	a5,-1232(a5) # 80008bd4 <ticks>
    800030ac:	1af53423          	sd	a5,424(a0)
      yield();
    800030b0:	fffff097          	auipc	ra,0xfffff
    800030b4:	336080e7          	jalr	822(ra) # 800023e6 <yield>
    800030b8:	b5b1                	j	80002f04 <usertrap+0xae>
      p_sched->tick_ctr = 0;
    800030ba:	1a052a23          	sw	zero,436(a0)
      p_sched->in_time = ticks;
    800030be:	00006797          	auipc	a5,0x6
    800030c2:	b167e783          	lwu	a5,-1258(a5) # 80008bd4 <ticks>
    800030c6:	1af53423          	sd	a5,424(a0)
      if (p_sched->queue_level < 4)
    800030ca:	478d                	li	a5,3
    800030cc:	02c7d463          	bge	a5,a2,800030f4 <usertrap+0x29e>
      yield();
    800030d0:	fffff097          	auipc	ra,0xfffff
    800030d4:	316080e7          	jalr	790(ra) # 800023e6 <yield>
    800030d8:	b535                	j	80002f04 <usertrap+0xae>
    if (p_sched->tick_ctr == y)
    800030da:	1b452703          	lw	a4,436(a0)
    800030de:	4785                	li	a5,1
    800030e0:	faf71ee3          	bne	a4,a5,8000309c <usertrap+0x246>
      p_sched->tick_ctr = 0;
    800030e4:	1a052a23          	sw	zero,436(a0)
      p_sched->in_time = ticks;
    800030e8:	00006797          	auipc	a5,0x6
    800030ec:	aec7e783          	lwu	a5,-1300(a5) # 80008bd4 <ticks>
    800030f0:	1af53423          	sd	a5,424(a0)
        p_sched->queue_level++;
    800030f4:	2605                	addiw	a2,a2,1
    800030f6:	1ac52823          	sw	a2,432(a0)
    800030fa:	bfd9                	j	800030d0 <usertrap+0x27a>
      if (p->state == RUNNABLE && p->queue_level < myproc()->queue_level)
    800030fc:	1b04ac03          	lw	s8,432(s1)
    80003100:	fffff097          	auipc	ra,0xfffff
    80003104:	aa2080e7          	jalr	-1374(ra) # 80001ba2 <myproc>
    80003108:	1b052783          	lw	a5,432(a0)
    8000310c:	00fc5363          	bge	s8,a5,80003112 <usertrap+0x2bc>
        flg = 1;
    80003110:	8b5e                	mv	s6,s7
      release(&p->lock);
    80003112:	8526                	mv	a0,s1
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	d24080e7          	jalr	-732(ra) # 80000e38 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000311c:	1c048493          	addi	s1,s1,448
    80003120:	f5248ae3          	beq	s1,s2,80003074 <usertrap+0x21e>
      acquire(&p->lock);
    80003124:	8526                	mv	a0,s1
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	c5e080e7          	jalr	-930(ra) # 80000d84 <acquire>
      if (p->state ==RUNNABLE && ticks - p->last_exec > WAIT_TIME)
    8000312e:	4c9c                	lw	a5,24(s1)
    80003130:	ff3791e3          	bne	a5,s3,80003112 <usertrap+0x2bc>
    80003134:	000aa703          	lw	a4,0(s5)
    80003138:	1b84a783          	lw	a5,440(s1)
    8000313c:	40f707bb          	subw	a5,a4,a5
    80003140:	fafa7ee3          	bgeu	s4,a5,800030fc <usertrap+0x2a6>
        if (p->queue_level > 0)
    80003144:	1b04a783          	lw	a5,432(s1)
    80003148:	faf05ae3          	blez	a5,800030fc <usertrap+0x2a6>
          p->last_exec = ticks;
    8000314c:	1ae4ac23          	sw	a4,440(s1)
          p->in_time = ticks;
    80003150:	1702                	slli	a4,a4,0x20
    80003152:	9301                	srli	a4,a4,0x20
    80003154:	1ae4b423          	sd	a4,424(s1)
          p->queue_level--;
    80003158:	37fd                	addiw	a5,a5,-1
    8000315a:	1af4a823          	sw	a5,432(s1)
    8000315e:	bf79                	j	800030fc <usertrap+0x2a6>

0000000080003160 <kerneltrap>:
{
    80003160:	711d                	addi	sp,sp,-96
    80003162:	ec86                	sd	ra,88(sp)
    80003164:	e8a2                	sd	s0,80(sp)
    80003166:	e4a6                	sd	s1,72(sp)
    80003168:	e0ca                	sd	s2,64(sp)
    8000316a:	fc4e                	sd	s3,56(sp)
    8000316c:	f852                	sd	s4,48(sp)
    8000316e:	f456                	sd	s5,40(sp)
    80003170:	f05a                	sd	s6,32(sp)
    80003172:	ec5e                	sd	s7,24(sp)
    80003174:	e862                	sd	s8,16(sp)
    80003176:	e466                	sd	s9,8(sp)
    80003178:	e06a                	sd	s10,0(sp)
    8000317a:	1080                	addi	s0,sp,96
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000317c:	141029f3          	csrr	s3,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003180:	10002973          	csrr	s2,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003184:	142024f3          	csrr	s1,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80003188:	10097793          	andi	a5,s2,256
    8000318c:	cf9d                	beqz	a5,800031ca <kerneltrap+0x6a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000318e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003192:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80003194:	e3b9                	bnez	a5,800031da <kerneltrap+0x7a>
  if ((which_dev = devintr()) == 0)
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	c1e080e7          	jalr	-994(ra) # 80002db4 <devintr>
    8000319e:	c531                	beqz	a0,800031ea <kerneltrap+0x8a>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031a0:	4789                	li	a5,2
    800031a2:	08f50163          	beq	a0,a5,80003224 <kerneltrap+0xc4>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031a6:	14199073          	csrw	sepc,s3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031aa:	10091073          	csrw	sstatus,s2
}
    800031ae:	60e6                	ld	ra,88(sp)
    800031b0:	6446                	ld	s0,80(sp)
    800031b2:	64a6                	ld	s1,72(sp)
    800031b4:	6906                	ld	s2,64(sp)
    800031b6:	79e2                	ld	s3,56(sp)
    800031b8:	7a42                	ld	s4,48(sp)
    800031ba:	7aa2                	ld	s5,40(sp)
    800031bc:	7b02                	ld	s6,32(sp)
    800031be:	6be2                	ld	s7,24(sp)
    800031c0:	6c42                	ld	s8,16(sp)
    800031c2:	6ca2                	ld	s9,8(sp)
    800031c4:	6d02                	ld	s10,0(sp)
    800031c6:	6125                	addi	sp,sp,96
    800031c8:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800031ca:	00005517          	auipc	a0,0x5
    800031ce:	1e650513          	addi	a0,a0,486 # 800083b0 <states.1783+0xc8>
    800031d2:	ffffd097          	auipc	ra,0xffffd
    800031d6:	372080e7          	jalr	882(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    800031da:	00005517          	auipc	a0,0x5
    800031de:	1fe50513          	addi	a0,a0,510 # 800083d8 <states.1783+0xf0>
    800031e2:	ffffd097          	auipc	ra,0xffffd
    800031e6:	362080e7          	jalr	866(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    800031ea:	85a6                	mv	a1,s1
    800031ec:	00005517          	auipc	a0,0x5
    800031f0:	20c50513          	addi	a0,a0,524 # 800083f8 <states.1783+0x110>
    800031f4:	ffffd097          	auipc	ra,0xffffd
    800031f8:	39a080e7          	jalr	922(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031fc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003200:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003204:	00005517          	auipc	a0,0x5
    80003208:	20450513          	addi	a0,a0,516 # 80008408 <states.1783+0x120>
    8000320c:	ffffd097          	auipc	ra,0xffffd
    80003210:	382080e7          	jalr	898(ra) # 8000058e <printf>
    panic("kerneltrap");
    80003214:	00005517          	auipc	a0,0x5
    80003218:	20c50513          	addi	a0,a0,524 # 80008420 <states.1783+0x138>
    8000321c:	ffffd097          	auipc	ra,0xffffd
    80003220:	328080e7          	jalr	808(ra) # 80000544 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003224:	fffff097          	auipc	ra,0xfffff
    80003228:	97e080e7          	jalr	-1666(ra) # 80001ba2 <myproc>
    8000322c:	dd2d                	beqz	a0,800031a6 <kerneltrap+0x46>
    8000322e:	fffff097          	auipc	ra,0xfffff
    80003232:	974080e7          	jalr	-1676(ra) # 80001ba2 <myproc>
    80003236:	4d18                	lw	a4,24(a0)
    80003238:	4791                	li	a5,4
    8000323a:	f6f716e3          	bne	a4,a5,800031a6 <kerneltrap+0x46>
    myproc()->tick_ctr++;
    8000323e:	fffff097          	auipc	ra,0xfffff
    80003242:	964080e7          	jalr	-1692(ra) # 80001ba2 <myproc>
    80003246:	1b452783          	lw	a5,436(a0)
    8000324a:	2785                	addiw	a5,a5,1
    8000324c:	1af52a23          	sw	a5,436(a0)
    for (p = proc; p < &proc[NPROC]; p++)
    80003250:	0022e497          	auipc	s1,0x22e
    80003254:	03848493          	addi	s1,s1,56 # 80231288 <proc>
    int flg = 0;
    80003258:	4c01                	li	s8,0
      if (p->state == RUNNABLE && ticks - p->last_exec > WAIT_TIME)
    8000325a:	4a8d                	li	s5,3
    8000325c:	00006b97          	auipc	s7,0x6
    80003260:	978b8b93          	addi	s7,s7,-1672 # 80008bd4 <ticks>
    80003264:	4b79                	li	s6,30
        flg = 1;
    80003266:	4c85                	li	s9,1
    for (p = proc; p < &proc[NPROC]; p++)
    80003268:	00235a17          	auipc	s4,0x235
    8000326c:	020a0a13          	addi	s4,s4,32 # 80238288 <tickslock>
    80003270:	a84d                	j	80003322 <kerneltrap+0x1c2>
    p_sched = myproc();
    80003272:	fffff097          	auipc	ra,0xfffff
    80003276:	930080e7          	jalr	-1744(ra) # 80001ba2 <myproc>
    int x = p_sched->queue_level;
    8000327a:	1b052603          	lw	a2,432(a0)
    while (x--)
    8000327e:	fff6079b          	addiw	a5,a2,-1
    80003282:	ca39                	beqz	a2,800032d8 <kerneltrap+0x178>
    int y = 1;
    80003284:	4705                	li	a4,1
    while (x--)
    80003286:	56fd                	li	a3,-1
      y *= 2;
    80003288:	0017171b          	slliw	a4,a4,0x1
    while (x--)
    8000328c:	37fd                	addiw	a5,a5,-1
    8000328e:	fed79de3          	bne	a5,a3,80003288 <kerneltrap+0x128>
    if (p_sched->tick_ctr == y)
    80003292:	1b452783          	lw	a5,436(a0)
    80003296:	02e78163          	beq	a5,a4,800032b8 <kerneltrap+0x158>
    else if (flg == 1)
    8000329a:	f00c06e3          	beqz	s8,800031a6 <kerneltrap+0x46>
      p_sched->tick_ctr = 0;
    8000329e:	1a052a23          	sw	zero,436(a0)
      p_sched->in_time = ticks;
    800032a2:	00006797          	auipc	a5,0x6
    800032a6:	9327e783          	lwu	a5,-1742(a5) # 80008bd4 <ticks>
    800032aa:	1af53423          	sd	a5,424(a0)
      yield();
    800032ae:	fffff097          	auipc	ra,0xfffff
    800032b2:	138080e7          	jalr	312(ra) # 800023e6 <yield>
    800032b6:	bdc5                	j	800031a6 <kerneltrap+0x46>
      p_sched->tick_ctr = 0;
    800032b8:	1a052a23          	sw	zero,436(a0)
      p_sched->in_time = ticks;
    800032bc:	00006797          	auipc	a5,0x6
    800032c0:	9187e783          	lwu	a5,-1768(a5) # 80008bd4 <ticks>
    800032c4:	1af53423          	sd	a5,424(a0)
      if (p_sched->queue_level < 4)
    800032c8:	478d                	li	a5,3
    800032ca:	02c7d463          	bge	a5,a2,800032f2 <kerneltrap+0x192>
      yield();
    800032ce:	fffff097          	auipc	ra,0xfffff
    800032d2:	118080e7          	jalr	280(ra) # 800023e6 <yield>
    800032d6:	bdc1                	j	800031a6 <kerneltrap+0x46>
    if (p_sched->tick_ctr == y)
    800032d8:	1b452703          	lw	a4,436(a0)
    800032dc:	4785                	li	a5,1
    800032de:	faf71ee3          	bne	a4,a5,8000329a <kerneltrap+0x13a>
      p_sched->tick_ctr = 0;
    800032e2:	1a052a23          	sw	zero,436(a0)
      p_sched->in_time = ticks;
    800032e6:	00006797          	auipc	a5,0x6
    800032ea:	8ee7e783          	lwu	a5,-1810(a5) # 80008bd4 <ticks>
    800032ee:	1af53423          	sd	a5,424(a0)
        p_sched->queue_level++;
    800032f2:	2605                	addiw	a2,a2,1
    800032f4:	1ac52823          	sw	a2,432(a0)
    800032f8:	bfd9                	j	800032ce <kerneltrap+0x16e>
      if (p->state == RUNNABLE && p->queue_level < myproc()->queue_level)
    800032fa:	1b04ad03          	lw	s10,432(s1)
    800032fe:	fffff097          	auipc	ra,0xfffff
    80003302:	8a4080e7          	jalr	-1884(ra) # 80001ba2 <myproc>
    80003306:	1b052783          	lw	a5,432(a0)
    8000330a:	00fd5363          	bge	s10,a5,80003310 <kerneltrap+0x1b0>
        flg = 1;
    8000330e:	8c66                	mv	s8,s9
      release(&p->lock);
    80003310:	8526                	mv	a0,s1
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	b26080e7          	jalr	-1242(ra) # 80000e38 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000331a:	1c048493          	addi	s1,s1,448
    8000331e:	f5448ae3          	beq	s1,s4,80003272 <kerneltrap+0x112>
      acquire(&p->lock);
    80003322:	8526                	mv	a0,s1
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	a60080e7          	jalr	-1440(ra) # 80000d84 <acquire>
      if (p->state == RUNNABLE && ticks - p->last_exec > WAIT_TIME)
    8000332c:	4c9c                	lw	a5,24(s1)
    8000332e:	ff5791e3          	bne	a5,s5,80003310 <kerneltrap+0x1b0>
    80003332:	000ba703          	lw	a4,0(s7)
    80003336:	1b84a783          	lw	a5,440(s1)
    8000333a:	40f707bb          	subw	a5,a4,a5
    8000333e:	fafb7ee3          	bgeu	s6,a5,800032fa <kerneltrap+0x19a>
        if (p->queue_level > 0)
    80003342:	1b04a783          	lw	a5,432(s1)
    80003346:	faf05ae3          	blez	a5,800032fa <kerneltrap+0x19a>
          p->last_exec = ticks;
    8000334a:	1ae4ac23          	sw	a4,440(s1)
          p->in_time = ticks;
    8000334e:	1702                	slli	a4,a4,0x20
    80003350:	9301                	srli	a4,a4,0x20
    80003352:	1ae4b423          	sd	a4,424(s1)
          p->queue_level--;
    80003356:	37fd                	addiw	a5,a5,-1
    80003358:	1af4a823          	sw	a5,432(s1)
    8000335c:	bf79                	j	800032fa <kerneltrap+0x19a>

000000008000335e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000335e:	1101                	addi	sp,sp,-32
    80003360:	ec06                	sd	ra,24(sp)
    80003362:	e822                	sd	s0,16(sp)
    80003364:	e426                	sd	s1,8(sp)
    80003366:	1000                	addi	s0,sp,32
    80003368:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000336a:	fffff097          	auipc	ra,0xfffff
    8000336e:	838080e7          	jalr	-1992(ra) # 80001ba2 <myproc>
  switch (n)
    80003372:	4795                	li	a5,5
    80003374:	0497e163          	bltu	a5,s1,800033b6 <argraw+0x58>
    80003378:	048a                	slli	s1,s1,0x2
    8000337a:	00005717          	auipc	a4,0x5
    8000337e:	22670713          	addi	a4,a4,550 # 800085a0 <states.1783+0x2b8>
    80003382:	94ba                	add	s1,s1,a4
    80003384:	409c                	lw	a5,0(s1)
    80003386:	97ba                	add	a5,a5,a4
    80003388:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    8000338a:	695c                	ld	a5,144(a0)
    8000338c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000338e:	60e2                	ld	ra,24(sp)
    80003390:	6442                	ld	s0,16(sp)
    80003392:	64a2                	ld	s1,8(sp)
    80003394:	6105                	addi	sp,sp,32
    80003396:	8082                	ret
    return p->trapframe->a1;
    80003398:	695c                	ld	a5,144(a0)
    8000339a:	7fa8                	ld	a0,120(a5)
    8000339c:	bfcd                	j	8000338e <argraw+0x30>
    return p->trapframe->a2;
    8000339e:	695c                	ld	a5,144(a0)
    800033a0:	63c8                	ld	a0,128(a5)
    800033a2:	b7f5                	j	8000338e <argraw+0x30>
    return p->trapframe->a3;
    800033a4:	695c                	ld	a5,144(a0)
    800033a6:	67c8                	ld	a0,136(a5)
    800033a8:	b7dd                	j	8000338e <argraw+0x30>
    return p->trapframe->a4;
    800033aa:	695c                	ld	a5,144(a0)
    800033ac:	6bc8                	ld	a0,144(a5)
    800033ae:	b7c5                	j	8000338e <argraw+0x30>
    return p->trapframe->a5;
    800033b0:	695c                	ld	a5,144(a0)
    800033b2:	6fc8                	ld	a0,152(a5)
    800033b4:	bfe9                	j	8000338e <argraw+0x30>
  panic("argraw");
    800033b6:	00005517          	auipc	a0,0x5
    800033ba:	07a50513          	addi	a0,a0,122 # 80008430 <states.1783+0x148>
    800033be:	ffffd097          	auipc	ra,0xffffd
    800033c2:	186080e7          	jalr	390(ra) # 80000544 <panic>

00000000800033c6 <fetchaddr>:
{
    800033c6:	1101                	addi	sp,sp,-32
    800033c8:	ec06                	sd	ra,24(sp)
    800033ca:	e822                	sd	s0,16(sp)
    800033cc:	e426                	sd	s1,8(sp)
    800033ce:	e04a                	sd	s2,0(sp)
    800033d0:	1000                	addi	s0,sp,32
    800033d2:	84aa                	mv	s1,a0
    800033d4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033d6:	ffffe097          	auipc	ra,0xffffe
    800033da:	7cc080e7          	jalr	1996(ra) # 80001ba2 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800033de:	615c                	ld	a5,128(a0)
    800033e0:	02f4f863          	bgeu	s1,a5,80003410 <fetchaddr+0x4a>
    800033e4:	00848713          	addi	a4,s1,8
    800033e8:	02e7e663          	bltu	a5,a4,80003414 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033ec:	46a1                	li	a3,8
    800033ee:	8626                	mv	a2,s1
    800033f0:	85ca                	mv	a1,s2
    800033f2:	6548                	ld	a0,136(a0)
    800033f4:	ffffe097          	auipc	ra,0xffffe
    800033f8:	4f8080e7          	jalr	1272(ra) # 800018ec <copyin>
    800033fc:	00a03533          	snez	a0,a0
    80003400:	40a00533          	neg	a0,a0
}
    80003404:	60e2                	ld	ra,24(sp)
    80003406:	6442                	ld	s0,16(sp)
    80003408:	64a2                	ld	s1,8(sp)
    8000340a:	6902                	ld	s2,0(sp)
    8000340c:	6105                	addi	sp,sp,32
    8000340e:	8082                	ret
    return -1;
    80003410:	557d                	li	a0,-1
    80003412:	bfcd                	j	80003404 <fetchaddr+0x3e>
    80003414:	557d                	li	a0,-1
    80003416:	b7fd                	j	80003404 <fetchaddr+0x3e>

0000000080003418 <fetchstr>:
{
    80003418:	7179                	addi	sp,sp,-48
    8000341a:	f406                	sd	ra,40(sp)
    8000341c:	f022                	sd	s0,32(sp)
    8000341e:	ec26                	sd	s1,24(sp)
    80003420:	e84a                	sd	s2,16(sp)
    80003422:	e44e                	sd	s3,8(sp)
    80003424:	1800                	addi	s0,sp,48
    80003426:	892a                	mv	s2,a0
    80003428:	84ae                	mv	s1,a1
    8000342a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000342c:	ffffe097          	auipc	ra,0xffffe
    80003430:	776080e7          	jalr	1910(ra) # 80001ba2 <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003434:	86ce                	mv	a3,s3
    80003436:	864a                	mv	a2,s2
    80003438:	85a6                	mv	a1,s1
    8000343a:	6548                	ld	a0,136(a0)
    8000343c:	ffffe097          	auipc	ra,0xffffe
    80003440:	53c080e7          	jalr	1340(ra) # 80001978 <copyinstr>
    80003444:	00054e63          	bltz	a0,80003460 <fetchstr+0x48>
  return strlen(buf);
    80003448:	8526                	mv	a0,s1
    8000344a:	ffffe097          	auipc	ra,0xffffe
    8000344e:	bba080e7          	jalr	-1094(ra) # 80001004 <strlen>
}
    80003452:	70a2                	ld	ra,40(sp)
    80003454:	7402                	ld	s0,32(sp)
    80003456:	64e2                	ld	s1,24(sp)
    80003458:	6942                	ld	s2,16(sp)
    8000345a:	69a2                	ld	s3,8(sp)
    8000345c:	6145                	addi	sp,sp,48
    8000345e:	8082                	ret
    return -1;
    80003460:	557d                	li	a0,-1
    80003462:	bfc5                	j	80003452 <fetchstr+0x3a>

0000000080003464 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003464:	1101                	addi	sp,sp,-32
    80003466:	ec06                	sd	ra,24(sp)
    80003468:	e822                	sd	s0,16(sp)
    8000346a:	e426                	sd	s1,8(sp)
    8000346c:	1000                	addi	s0,sp,32
    8000346e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003470:	00000097          	auipc	ra,0x0
    80003474:	eee080e7          	jalr	-274(ra) # 8000335e <argraw>
    80003478:	c088                	sw	a0,0(s1)
}
    8000347a:	60e2                	ld	ra,24(sp)
    8000347c:	6442                	ld	s0,16(sp)
    8000347e:	64a2                	ld	s1,8(sp)
    80003480:	6105                	addi	sp,sp,32
    80003482:	8082                	ret

0000000080003484 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003484:	1101                	addi	sp,sp,-32
    80003486:	ec06                	sd	ra,24(sp)
    80003488:	e822                	sd	s0,16(sp)
    8000348a:	e426                	sd	s1,8(sp)
    8000348c:	1000                	addi	s0,sp,32
    8000348e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003490:	00000097          	auipc	ra,0x0
    80003494:	ece080e7          	jalr	-306(ra) # 8000335e <argraw>
    80003498:	e088                	sd	a0,0(s1)
}
    8000349a:	60e2                	ld	ra,24(sp)
    8000349c:	6442                	ld	s0,16(sp)
    8000349e:	64a2                	ld	s1,8(sp)
    800034a0:	6105                	addi	sp,sp,32
    800034a2:	8082                	ret

00000000800034a4 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800034a4:	7179                	addi	sp,sp,-48
    800034a6:	f406                	sd	ra,40(sp)
    800034a8:	f022                	sd	s0,32(sp)
    800034aa:	ec26                	sd	s1,24(sp)
    800034ac:	e84a                	sd	s2,16(sp)
    800034ae:	1800                	addi	s0,sp,48
    800034b0:	84ae                	mv	s1,a1
    800034b2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800034b4:	fd840593          	addi	a1,s0,-40
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	fcc080e7          	jalr	-52(ra) # 80003484 <argaddr>
  return fetchstr(addr, buf, max);
    800034c0:	864a                	mv	a2,s2
    800034c2:	85a6                	mv	a1,s1
    800034c4:	fd843503          	ld	a0,-40(s0)
    800034c8:	00000097          	auipc	ra,0x0
    800034cc:	f50080e7          	jalr	-176(ra) # 80003418 <fetchstr>
}
    800034d0:	70a2                	ld	ra,40(sp)
    800034d2:	7402                	ld	s0,32(sp)
    800034d4:	64e2                	ld	s1,24(sp)
    800034d6:	6942                	ld	s2,16(sp)
    800034d8:	6145                	addi	sp,sp,48
    800034da:	8082                	ret

00000000800034dc <syscall>:
    "link", "mkdir", "close", "trace", "sigalarm", "sigreturn", "settickets", "set_priority", "waitx"};

int syscall_num_para[28] = {0, 0, 1, 1, 1, 3, 1, 2, 2, 1, 1, 0, 1, 1, 0, 2, 3, 3, 1, 2, 1, 1, 1, 2, 0, 1, 2, 3};

void syscall(void)
{
    800034dc:	7179                	addi	sp,sp,-48
    800034de:	f406                	sd	ra,40(sp)
    800034e0:	f022                	sd	s0,32(sp)
    800034e2:	ec26                	sd	s1,24(sp)
    800034e4:	e84a                	sd	s2,16(sp)
    800034e6:	e44e                	sd	s3,8(sp)
    800034e8:	e052                	sd	s4,0(sp)
    800034ea:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    800034ec:	ffffe097          	auipc	ra,0xffffe
    800034f0:	6b6080e7          	jalr	1718(ra) # 80001ba2 <myproc>
    800034f4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034f6:	09053903          	ld	s2,144(a0)
    800034fa:	0a893783          	ld	a5,168(s2)
    800034fe:	0007899b          	sext.w	s3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003502:	37fd                	addiw	a5,a5,-1
    80003504:	4769                	li	a4,26
    80003506:	0ef76363          	bltu	a4,a5,800035ec <syscall+0x110>
    8000350a:	00399713          	slli	a4,s3,0x3
    8000350e:	00005797          	auipc	a5,0x5
    80003512:	0aa78793          	addi	a5,a5,170 # 800085b8 <syscalls>
    80003516:	97ba                	add	a5,a5,a4
    80003518:	639c                	ld	a5,0(a5)
    8000351a:	cbe9                	beqz	a5,800035ec <syscall+0x110>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    uint64 arg1 = p->trapframe->a0;
    8000351c:	07093a03          	ld	s4,112(s2)
    p->trapframe->a0 = syscalls[num]();
    80003520:	9782                	jalr	a5
    80003522:	06a93823          	sd	a0,112(s2)
    if (p->trace_mask & 1 << num)
    80003526:	58dc                	lw	a5,52(s1)
    80003528:	4137d7bb          	sraw	a5,a5,s3
    8000352c:	8b85                	andi	a5,a5,1
    8000352e:	cff1                	beqz	a5,8000360a <syscall+0x12e>
    {
      printf("%d: syscall %s ", p->pid, syscall_name[num]);
    80003530:	00005917          	auipc	s2,0x5
    80003534:	4f890913          	addi	s2,s2,1272 # 80008a28 <syscall_name>
    80003538:	00399793          	slli	a5,s3,0x3
    8000353c:	97ca                	add	a5,a5,s2
    8000353e:	6390                	ld	a2,0(a5)
    80003540:	588c                	lw	a1,48(s1)
    80003542:	00005517          	auipc	a0,0x5
    80003546:	ef650513          	addi	a0,a0,-266 # 80008438 <states.1783+0x150>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	044080e7          	jalr	68(ra) # 8000058e <printf>
      int num_arg = syscall_num_para[num];
    80003552:	098a                	slli	s3,s3,0x2
    80003554:	994e                	add	s2,s2,s3
    80003556:	0e092783          	lw	a5,224(s2)
      if (num_arg == 0)
    8000355a:	cf8d                	beqz	a5,80003594 <syscall+0xb8>
      {
        printf("-> ");
      }
      else if (num_arg == 1)
    8000355c:	4705                	li	a4,1
    8000355e:	04e78463          	beq	a5,a4,800035a6 <syscall+0xca>
      {
        printf("( %d ) -> ", arg1);
      }
      else if (num_arg == 2)
    80003562:	4709                	li	a4,2
    80003564:	04e78b63          	beq	a5,a4,800035ba <syscall+0xde>
      {
        printf("( %d %d ) -> ", arg1, p->trapframe->a1);
      }
      else if (num_arg == 3)
    80003568:	470d                	li	a4,3
    8000356a:	06e78463          	beq	a5,a4,800035d2 <syscall+0xf6>
      {
        printf("( %d %d %d ) ->", arg1, p->trapframe->a1, p->trapframe->a2);
      }
      printf("%d", p->trapframe->a0);
    8000356e:	68dc                	ld	a5,144(s1)
    80003570:	7bac                	ld	a1,112(a5)
    80003572:	00005517          	auipc	a0,0x5
    80003576:	f0e50513          	addi	a0,a0,-242 # 80008480 <states.1783+0x198>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	014080e7          	jalr	20(ra) # 8000058e <printf>
      printf("\n");
    80003582:	00005517          	auipc	a0,0x5
    80003586:	b6650513          	addi	a0,a0,-1178 # 800080e8 <digits+0xa8>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	004080e7          	jalr	4(ra) # 8000058e <printf>
    80003592:	a8a5                	j	8000360a <syscall+0x12e>
        printf("-> ");
    80003594:	00005517          	auipc	a0,0x5
    80003598:	eb450513          	addi	a0,a0,-332 # 80008448 <states.1783+0x160>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	ff2080e7          	jalr	-14(ra) # 8000058e <printf>
    800035a4:	b7e9                	j	8000356e <syscall+0x92>
        printf("( %d ) -> ", arg1);
    800035a6:	85d2                	mv	a1,s4
    800035a8:	00005517          	auipc	a0,0x5
    800035ac:	ea850513          	addi	a0,a0,-344 # 80008450 <states.1783+0x168>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	fde080e7          	jalr	-34(ra) # 8000058e <printf>
    800035b8:	bf5d                	j	8000356e <syscall+0x92>
        printf("( %d %d ) -> ", arg1, p->trapframe->a1);
    800035ba:	68dc                	ld	a5,144(s1)
    800035bc:	7fb0                	ld	a2,120(a5)
    800035be:	85d2                	mv	a1,s4
    800035c0:	00005517          	auipc	a0,0x5
    800035c4:	ea050513          	addi	a0,a0,-352 # 80008460 <states.1783+0x178>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	fc6080e7          	jalr	-58(ra) # 8000058e <printf>
    800035d0:	bf79                	j	8000356e <syscall+0x92>
        printf("( %d %d %d ) ->", arg1, p->trapframe->a1, p->trapframe->a2);
    800035d2:	68dc                	ld	a5,144(s1)
    800035d4:	63d4                	ld	a3,128(a5)
    800035d6:	7fb0                	ld	a2,120(a5)
    800035d8:	85d2                	mv	a1,s4
    800035da:	00005517          	auipc	a0,0x5
    800035de:	e9650513          	addi	a0,a0,-362 # 80008470 <states.1783+0x188>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	fac080e7          	jalr	-84(ra) # 8000058e <printf>
    800035ea:	b751                	j	8000356e <syscall+0x92>
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    800035ec:	86ce                	mv	a3,s3
    800035ee:	19848613          	addi	a2,s1,408
    800035f2:	588c                	lw	a1,48(s1)
    800035f4:	00005517          	auipc	a0,0x5
    800035f8:	e9450513          	addi	a0,a0,-364 # 80008488 <states.1783+0x1a0>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	f92080e7          	jalr	-110(ra) # 8000058e <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003604:	68dc                	ld	a5,144(s1)
    80003606:	577d                	li	a4,-1
    80003608:	fbb8                	sd	a4,112(a5)
  }
}
    8000360a:	70a2                	ld	ra,40(sp)
    8000360c:	7402                	ld	s0,32(sp)
    8000360e:	64e2                	ld	s1,24(sp)
    80003610:	6942                	ld	s2,16(sp)
    80003612:	69a2                	ld	s3,8(sp)
    80003614:	6a02                	ld	s4,0(sp)
    80003616:	6145                	addi	sp,sp,48
    80003618:	8082                	ret

000000008000361a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000361a:	1101                	addi	sp,sp,-32
    8000361c:	ec06                	sd	ra,24(sp)
    8000361e:	e822                	sd	s0,16(sp)
    80003620:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003622:	fec40593          	addi	a1,s0,-20
    80003626:	4501                	li	a0,0
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	e3c080e7          	jalr	-452(ra) # 80003464 <argint>
  exit(n);
    80003630:	fec42503          	lw	a0,-20(s0)
    80003634:	fffff097          	auipc	ra,0xfffff
    80003638:	088080e7          	jalr	136(ra) # 800026bc <exit>
  return 0; // not reached
}
    8000363c:	4501                	li	a0,0
    8000363e:	60e2                	ld	ra,24(sp)
    80003640:	6442                	ld	s0,16(sp)
    80003642:	6105                	addi	sp,sp,32
    80003644:	8082                	ret

0000000080003646 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003646:	1141                	addi	sp,sp,-16
    80003648:	e406                	sd	ra,8(sp)
    8000364a:	e022                	sd	s0,0(sp)
    8000364c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000364e:	ffffe097          	auipc	ra,0xffffe
    80003652:	554080e7          	jalr	1364(ra) # 80001ba2 <myproc>
}
    80003656:	5908                	lw	a0,48(a0)
    80003658:	60a2                	ld	ra,8(sp)
    8000365a:	6402                	ld	s0,0(sp)
    8000365c:	0141                	addi	sp,sp,16
    8000365e:	8082                	ret

0000000080003660 <sys_fork>:

uint64
sys_fork(void)
{
    80003660:	1141                	addi	sp,sp,-16
    80003662:	e406                	sd	ra,8(sp)
    80003664:	e022                	sd	s0,0(sp)
    80003666:	0800                	addi	s0,sp,16
  return fork();
    80003668:	fffff097          	auipc	ra,0xfffff
    8000366c:	988080e7          	jalr	-1656(ra) # 80001ff0 <fork>
}
    80003670:	60a2                	ld	ra,8(sp)
    80003672:	6402                	ld	s0,0(sp)
    80003674:	0141                	addi	sp,sp,16
    80003676:	8082                	ret

0000000080003678 <sys_wait>:

uint64
sys_wait(void)
{
    80003678:	1101                	addi	sp,sp,-32
    8000367a:	ec06                	sd	ra,24(sp)
    8000367c:	e822                	sd	s0,16(sp)
    8000367e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003680:	fe840593          	addi	a1,s0,-24
    80003684:	4501                	li	a0,0
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	dfe080e7          	jalr	-514(ra) # 80003484 <argaddr>
  return wait(p);
    8000368e:	fe843503          	ld	a0,-24(s0)
    80003692:	fffff097          	auipc	ra,0xfffff
    80003696:	1f4080e7          	jalr	500(ra) # 80002886 <wait>
}
    8000369a:	60e2                	ld	ra,24(sp)
    8000369c:	6442                	ld	s0,16(sp)
    8000369e:	6105                	addi	sp,sp,32
    800036a0:	8082                	ret

00000000800036a2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800036a2:	7179                	addi	sp,sp,-48
    800036a4:	f406                	sd	ra,40(sp)
    800036a6:	f022                	sd	s0,32(sp)
    800036a8:	ec26                	sd	s1,24(sp)
    800036aa:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800036ac:	fdc40593          	addi	a1,s0,-36
    800036b0:	4501                	li	a0,0
    800036b2:	00000097          	auipc	ra,0x0
    800036b6:	db2080e7          	jalr	-590(ra) # 80003464 <argint>
  addr = myproc()->sz;
    800036ba:	ffffe097          	auipc	ra,0xffffe
    800036be:	4e8080e7          	jalr	1256(ra) # 80001ba2 <myproc>
    800036c2:	6144                	ld	s1,128(a0)
  if (growproc(n) < 0)
    800036c4:	fdc42503          	lw	a0,-36(s0)
    800036c8:	fffff097          	auipc	ra,0xfffff
    800036cc:	8cc080e7          	jalr	-1844(ra) # 80001f94 <growproc>
    800036d0:	00054863          	bltz	a0,800036e0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800036d4:	8526                	mv	a0,s1
    800036d6:	70a2                	ld	ra,40(sp)
    800036d8:	7402                	ld	s0,32(sp)
    800036da:	64e2                	ld	s1,24(sp)
    800036dc:	6145                	addi	sp,sp,48
    800036de:	8082                	ret
    return -1;
    800036e0:	54fd                	li	s1,-1
    800036e2:	bfcd                	j	800036d4 <sys_sbrk+0x32>

00000000800036e4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800036e4:	7139                	addi	sp,sp,-64
    800036e6:	fc06                	sd	ra,56(sp)
    800036e8:	f822                	sd	s0,48(sp)
    800036ea:	f426                	sd	s1,40(sp)
    800036ec:	f04a                	sd	s2,32(sp)
    800036ee:	ec4e                	sd	s3,24(sp)
    800036f0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800036f2:	fcc40593          	addi	a1,s0,-52
    800036f6:	4501                	li	a0,0
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	d6c080e7          	jalr	-660(ra) # 80003464 <argint>
  acquire(&tickslock);
    80003700:	00235517          	auipc	a0,0x235
    80003704:	b8850513          	addi	a0,a0,-1144 # 80238288 <tickslock>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	67c080e7          	jalr	1660(ra) # 80000d84 <acquire>
  ticks0 = ticks;
    80003710:	00005917          	auipc	s2,0x5
    80003714:	4c492903          	lw	s2,1220(s2) # 80008bd4 <ticks>
  while (ticks - ticks0 < n)
    80003718:	fcc42783          	lw	a5,-52(s0)
    8000371c:	cf9d                	beqz	a5,8000375a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000371e:	00235997          	auipc	s3,0x235
    80003722:	b6a98993          	addi	s3,s3,-1174 # 80238288 <tickslock>
    80003726:	00005497          	auipc	s1,0x5
    8000372a:	4ae48493          	addi	s1,s1,1198 # 80008bd4 <ticks>
    if (killed(myproc()))
    8000372e:	ffffe097          	auipc	ra,0xffffe
    80003732:	474080e7          	jalr	1140(ra) # 80001ba2 <myproc>
    80003736:	fffff097          	auipc	ra,0xfffff
    8000373a:	11e080e7          	jalr	286(ra) # 80002854 <killed>
    8000373e:	ed15                	bnez	a0,8000377a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003740:	85ce                	mv	a1,s3
    80003742:	8526                	mv	a0,s1
    80003744:	fffff097          	auipc	ra,0xfffff
    80003748:	cde080e7          	jalr	-802(ra) # 80002422 <sleep>
  while (ticks - ticks0 < n)
    8000374c:	409c                	lw	a5,0(s1)
    8000374e:	412787bb          	subw	a5,a5,s2
    80003752:	fcc42703          	lw	a4,-52(s0)
    80003756:	fce7ece3          	bltu	a5,a4,8000372e <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000375a:	00235517          	auipc	a0,0x235
    8000375e:	b2e50513          	addi	a0,a0,-1234 # 80238288 <tickslock>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	6d6080e7          	jalr	1750(ra) # 80000e38 <release>
  return 0;
    8000376a:	4501                	li	a0,0
}
    8000376c:	70e2                	ld	ra,56(sp)
    8000376e:	7442                	ld	s0,48(sp)
    80003770:	74a2                	ld	s1,40(sp)
    80003772:	7902                	ld	s2,32(sp)
    80003774:	69e2                	ld	s3,24(sp)
    80003776:	6121                	addi	sp,sp,64
    80003778:	8082                	ret
      release(&tickslock);
    8000377a:	00235517          	auipc	a0,0x235
    8000377e:	b0e50513          	addi	a0,a0,-1266 # 80238288 <tickslock>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	6b6080e7          	jalr	1718(ra) # 80000e38 <release>
      return -1;
    8000378a:	557d                	li	a0,-1
    8000378c:	b7c5                	j	8000376c <sys_sleep+0x88>

000000008000378e <sys_kill>:

uint64
sys_kill(void)
{
    8000378e:	1101                	addi	sp,sp,-32
    80003790:	ec06                	sd	ra,24(sp)
    80003792:	e822                	sd	s0,16(sp)
    80003794:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003796:	fec40593          	addi	a1,s0,-20
    8000379a:	4501                	li	a0,0
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	cc8080e7          	jalr	-824(ra) # 80003464 <argint>
  return kill(pid);
    800037a4:	fec42503          	lw	a0,-20(s0)
    800037a8:	fffff097          	auipc	ra,0xfffff
    800037ac:	ff6080e7          	jalr	-10(ra) # 8000279e <kill>
}
    800037b0:	60e2                	ld	ra,24(sp)
    800037b2:	6442                	ld	s0,16(sp)
    800037b4:	6105                	addi	sp,sp,32
    800037b6:	8082                	ret

00000000800037b8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800037b8:	1101                	addi	sp,sp,-32
    800037ba:	ec06                	sd	ra,24(sp)
    800037bc:	e822                	sd	s0,16(sp)
    800037be:	e426                	sd	s1,8(sp)
    800037c0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800037c2:	00235517          	auipc	a0,0x235
    800037c6:	ac650513          	addi	a0,a0,-1338 # 80238288 <tickslock>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	5ba080e7          	jalr	1466(ra) # 80000d84 <acquire>
  xticks = ticks;
    800037d2:	00005497          	auipc	s1,0x5
    800037d6:	4024a483          	lw	s1,1026(s1) # 80008bd4 <ticks>
  release(&tickslock);
    800037da:	00235517          	auipc	a0,0x235
    800037de:	aae50513          	addi	a0,a0,-1362 # 80238288 <tickslock>
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	656080e7          	jalr	1622(ra) # 80000e38 <release>
  return xticks;
}
    800037ea:	02049513          	slli	a0,s1,0x20
    800037ee:	9101                	srli	a0,a0,0x20
    800037f0:	60e2                	ld	ra,24(sp)
    800037f2:	6442                	ld	s0,16(sp)
    800037f4:	64a2                	ld	s1,8(sp)
    800037f6:	6105                	addi	sp,sp,32
    800037f8:	8082                	ret

00000000800037fa <sys_trace>:

uint64
sys_trace(void)
{
    800037fa:	1101                	addi	sp,sp,-32
    800037fc:	ec06                	sd	ra,24(sp)
    800037fe:	e822                	sd	s0,16(sp)
    80003800:	1000                	addi	s0,sp,32
  int mask;
  argint(0, &mask);
    80003802:	fec40593          	addi	a1,s0,-20
    80003806:	4501                	li	a0,0
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	c5c080e7          	jalr	-932(ra) # 80003464 <argint>

  myproc()->trace_mask = mask;
    80003810:	ffffe097          	auipc	ra,0xffffe
    80003814:	392080e7          	jalr	914(ra) # 80001ba2 <myproc>
    80003818:	fec42783          	lw	a5,-20(s0)
    8000381c:	d95c                	sw	a5,52(a0)
  return 0;
}
    8000381e:	4501                	li	a0,0
    80003820:	60e2                	ld	ra,24(sp)
    80003822:	6442                	ld	s0,16(sp)
    80003824:	6105                	addi	sp,sp,32
    80003826:	8082                	ret

0000000080003828 <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    80003828:	1101                	addi	sp,sp,-32
    8000382a:	ec06                	sd	ra,24(sp)
    8000382c:	e822                	sd	s0,16(sp)
    8000382e:	1000                	addi	s0,sp,32
  int arg1;
  uint64 arg2;
  argint(0, &arg1), argaddr(1, &arg2);
    80003830:	fec40593          	addi	a1,s0,-20
    80003834:	4501                	li	a0,0
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	c2e080e7          	jalr	-978(ra) # 80003464 <argint>
    8000383e:	fe040593          	addi	a1,s0,-32
    80003842:	4505                	li	a0,1
    80003844:	00000097          	auipc	ra,0x0
    80003848:	c40080e7          	jalr	-960(ra) # 80003484 <argaddr>
  myproc()->alarm = 1, myproc()->ticks = arg1, myproc()->handler = arg2;
    8000384c:	ffffe097          	auipc	ra,0xffffe
    80003850:	356080e7          	jalr	854(ra) # 80001ba2 <myproc>
    80003854:	4785                	li	a5,1
    80003856:	dd1c                	sw	a5,56(a0)
    80003858:	ffffe097          	auipc	ra,0xffffe
    8000385c:	34a080e7          	jalr	842(ra) # 80001ba2 <myproc>
    80003860:	fec42783          	lw	a5,-20(s0)
    80003864:	dd5c                	sw	a5,60(a0)
    80003866:	ffffe097          	auipc	ra,0xffffe
    8000386a:	33c080e7          	jalr	828(ra) # 80001ba2 <myproc>
    8000386e:	fe043783          	ld	a5,-32(s0)
    80003872:	f13c                	sd	a5,96(a0)
  return 0;
}
    80003874:	4501                	li	a0,0
    80003876:	60e2                	ld	ra,24(sp)
    80003878:	6442                	ld	s0,16(sp)
    8000387a:	6105                	addi	sp,sp,32
    8000387c:	8082                	ret

000000008000387e <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    8000387e:	1141                	addi	sp,sp,-16
    80003880:	e406                	sd	ra,8(sp)
    80003882:	e022                	sd	s0,0(sp)
    80003884:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003886:	ffffe097          	auipc	ra,0xffffe
    8000388a:	31c080e7          	jalr	796(ra) # 80001ba2 <myproc>
  p->alarm = 1;
    8000388e:	4785                	li	a5,1
    80003890:	dd1c                	sw	a5,56(a0)
  p->copy->kernel_satp = p->trapframe->kernel_satp;
    80003892:	6d5c                	ld	a5,152(a0)
    80003894:	6958                	ld	a4,144(a0)
    80003896:	6318                	ld	a4,0(a4)
    80003898:	e398                	sd	a4,0(a5)
  p->copy->kernel_hartid = p->trapframe->kernel_hartid;
    8000389a:	6d5c                	ld	a5,152(a0)
    8000389c:	6958                	ld	a4,144(a0)
    8000389e:	7318                	ld	a4,32(a4)
    800038a0:	f398                	sd	a4,32(a5)
  p->copy->kernel_sp = p->trapframe->kernel_sp;
    800038a2:	6d5c                	ld	a5,152(a0)
    800038a4:	6958                	ld	a4,144(a0)
    800038a6:	6718                	ld	a4,8(a4)
    800038a8:	e798                	sd	a4,8(a5)
  p->copy->kernel_trap = p->trapframe->kernel_trap;
    800038aa:	6d5c                	ld	a5,152(a0)
    800038ac:	6958                	ld	a4,144(a0)
    800038ae:	6b18                	ld	a4,16(a4)
    800038b0:	eb98                	sd	a4,16(a5)

  *(p->trapframe) = *(p->copy);
    800038b2:	6d54                	ld	a3,152(a0)
    800038b4:	87b6                	mv	a5,a3
    800038b6:	6958                	ld	a4,144(a0)
    800038b8:	12068693          	addi	a3,a3,288
    800038bc:	0007b883          	ld	a7,0(a5)
    800038c0:	0087b803          	ld	a6,8(a5)
    800038c4:	6b8c                	ld	a1,16(a5)
    800038c6:	6f90                	ld	a2,24(a5)
    800038c8:	01173023          	sd	a7,0(a4)
    800038cc:	01073423          	sd	a6,8(a4)
    800038d0:	eb0c                	sd	a1,16(a4)
    800038d2:	ef10                	sd	a2,24(a4)
    800038d4:	02078793          	addi	a5,a5,32
    800038d8:	02070713          	addi	a4,a4,32
    800038dc:	fed790e3          	bne	a5,a3,800038bc <sys_sigreturn+0x3e>
  return p->trapframe->a0;
    800038e0:	695c                	ld	a5,144(a0)
}
    800038e2:	7ba8                	ld	a0,112(a5)
    800038e4:	60a2                	ld	ra,8(sp)
    800038e6:	6402                	ld	s0,0(sp)
    800038e8:	0141                	addi	sp,sp,16
    800038ea:	8082                	ret

00000000800038ec <sys_set_priority>:
}
#endif

uint64
sys_set_priority(void)
{
    800038ec:	7139                	addi	sp,sp,-64
    800038ee:	fc06                	sd	ra,56(sp)
    800038f0:	f822                	sd	s0,48(sp)
    800038f2:	f426                	sd	s1,40(sp)
    800038f4:	f04a                	sd	s2,32(sp)
    800038f6:	ec4e                	sd	s3,24(sp)
    800038f8:	0080                	addi	s0,sp,64
  int priority, pid, oldpriority = 101;
  argint(0, &priority);
    800038fa:	fcc40593          	addi	a1,s0,-52
    800038fe:	4501                	li	a0,0
    80003900:	00000097          	auipc	ra,0x0
    80003904:	b64080e7          	jalr	-1180(ra) # 80003464 <argint>
  argint(1, &pid);
    80003908:	fc840593          	addi	a1,s0,-56
    8000390c:	4505                	li	a0,1
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	b56080e7          	jalr	-1194(ra) # 80003464 <argint>
  if (priority < 0 || priority > 100)
    80003916:	fcc42703          	lw	a4,-52(s0)
    8000391a:	06400793          	li	a5,100
    return -1;
    8000391e:	557d                	li	a0,-1
  if (priority < 0 || priority > 100)
    80003920:	04e7eb63          	bltu	a5,a4,80003976 <sys_set_priority+0x8a>
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80003924:	0022e497          	auipc	s1,0x22e
    80003928:	96448493          	addi	s1,s1,-1692 # 80231288 <proc>
  int priority, pid, oldpriority = 101;
    8000392c:	06500993          	li	s3,101
  for (p = proc; p < &proc[NPROC]; p++)
    80003930:	00235917          	auipc	s2,0x235
    80003934:	95890913          	addi	s2,s2,-1704 # 80238288 <tickslock>
    80003938:	a811                	j	8000394c <sys_set_priority+0x60>
    if (p->pid == pid)
    {
      oldpriority = p->priority;
      p->priority = priority;
    }
    release(&p->lock);
    8000393a:	8526                	mv	a0,s1
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	4fc080e7          	jalr	1276(ra) # 80000e38 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80003944:	1c048493          	addi	s1,s1,448
    80003948:	03248263          	beq	s1,s2,8000396c <sys_set_priority+0x80>
    acquire(&p->lock);
    8000394c:	8526                	mv	a0,s1
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	436080e7          	jalr	1078(ra) # 80000d84 <acquire>
    if (p->pid == pid)
    80003956:	5898                	lw	a4,48(s1)
    80003958:	fc842783          	lw	a5,-56(s0)
    8000395c:	fcf71fe3          	bne	a4,a5,8000393a <sys_set_priority+0x4e>
      oldpriority = p->priority;
    80003960:	0684a983          	lw	s3,104(s1)
      p->priority = priority;
    80003964:	fcc42783          	lw	a5,-52(s0)
    80003968:	d4bc                	sw	a5,104(s1)
    8000396a:	bfc1                	j	8000393a <sys_set_priority+0x4e>
  }
  if (priority < oldpriority)
    8000396c:	fcc42783          	lw	a5,-52(s0)
    80003970:	0137ca63          	blt	a5,s3,80003984 <sys_set_priority+0x98>
    yield();
  return oldpriority;
    80003974:	854e                	mv	a0,s3
}
    80003976:	70e2                	ld	ra,56(sp)
    80003978:	7442                	ld	s0,48(sp)
    8000397a:	74a2                	ld	s1,40(sp)
    8000397c:	7902                	ld	s2,32(sp)
    8000397e:	69e2                	ld	s3,24(sp)
    80003980:	6121                	addi	sp,sp,64
    80003982:	8082                	ret
    yield();
    80003984:	fffff097          	auipc	ra,0xfffff
    80003988:	a62080e7          	jalr	-1438(ra) # 800023e6 <yield>
    8000398c:	b7e5                	j	80003974 <sys_set_priority+0x88>

000000008000398e <sys_waitx>:

uint64
sys_waitx(void)
{
    8000398e:	7139                	addi	sp,sp,-64
    80003990:	fc06                	sd	ra,56(sp)
    80003992:	f822                	sd	s0,48(sp)
    80003994:	f426                	sd	s1,40(sp)
    80003996:	f04a                	sd	s2,32(sp)
    80003998:	0080                	addi	s0,sp,64
  uint64 p, raddr, waddr;
  int rtime, wtime;
  argaddr(0, &p);
    8000399a:	fd840593          	addi	a1,s0,-40
    8000399e:	4501                	li	a0,0
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	ae4080e7          	jalr	-1308(ra) # 80003484 <argaddr>
  argaddr(1, &raddr);
    800039a8:	fd040593          	addi	a1,s0,-48
    800039ac:	4505                	li	a0,1
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	ad6080e7          	jalr	-1322(ra) # 80003484 <argaddr>
  argaddr(2, &waddr);
    800039b6:	fc840593          	addi	a1,s0,-56
    800039ba:	4509                	li	a0,2
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	ac8080e7          	jalr	-1336(ra) # 80003484 <argaddr>
  int ret = waitx(p, &rtime, &wtime);
    800039c4:	fc040613          	addi	a2,s0,-64
    800039c8:	fc440593          	addi	a1,s0,-60
    800039cc:	fd843503          	ld	a0,-40(s0)
    800039d0:	fffff097          	auipc	ra,0xfffff
    800039d4:	ab6080e7          	jalr	-1354(ra) # 80002486 <waitx>
    800039d8:	892a                	mv	s2,a0
  struct proc *proc = myproc();
    800039da:	ffffe097          	auipc	ra,0xffffe
    800039de:	1c8080e7          	jalr	456(ra) # 80001ba2 <myproc>
    800039e2:	84aa                	mv	s1,a0
  if (copyout(proc->pagetable, raddr, (char *)&rtime, sizeof(int)) < 0)
    800039e4:	4691                	li	a3,4
    800039e6:	fc440613          	addi	a2,s0,-60
    800039ea:	fd043583          	ld	a1,-48(s0)
    800039ee:	6548                	ld	a0,136(a0)
    800039f0:	ffffe097          	auipc	ra,0xffffe
    800039f4:	e38080e7          	jalr	-456(ra) # 80001828 <copyout>
    return -1;
    800039f8:	57fd                	li	a5,-1
  if (copyout(proc->pagetable, raddr, (char *)&rtime, sizeof(int)) < 0)
    800039fa:	00054f63          	bltz	a0,80003a18 <sys_waitx+0x8a>
  if (copyout(proc->pagetable, waddr, (char *)&wtime, sizeof(int)) < 0)
    800039fe:	4691                	li	a3,4
    80003a00:	fc040613          	addi	a2,s0,-64
    80003a04:	fc843583          	ld	a1,-56(s0)
    80003a08:	64c8                	ld	a0,136(s1)
    80003a0a:	ffffe097          	auipc	ra,0xffffe
    80003a0e:	e1e080e7          	jalr	-482(ra) # 80001828 <copyout>
    80003a12:	00054a63          	bltz	a0,80003a26 <sys_waitx+0x98>
    return -1;
  return ret;
    80003a16:	87ca                	mv	a5,s2
}
    80003a18:	853e                	mv	a0,a5
    80003a1a:	70e2                	ld	ra,56(sp)
    80003a1c:	7442                	ld	s0,48(sp)
    80003a1e:	74a2                	ld	s1,40(sp)
    80003a20:	7902                	ld	s2,32(sp)
    80003a22:	6121                	addi	sp,sp,64
    80003a24:	8082                	ret
    return -1;
    80003a26:	57fd                	li	a5,-1
    80003a28:	bfc5                	j	80003a18 <sys_waitx+0x8a>

0000000080003a2a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a2a:	7179                	addi	sp,sp,-48
    80003a2c:	f406                	sd	ra,40(sp)
    80003a2e:	f022                	sd	s0,32(sp)
    80003a30:	ec26                	sd	s1,24(sp)
    80003a32:	e84a                	sd	s2,16(sp)
    80003a34:	e44e                	sd	s3,8(sp)
    80003a36:	e052                	sd	s4,0(sp)
    80003a38:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003a3a:	00005597          	auipc	a1,0x5
    80003a3e:	c5e58593          	addi	a1,a1,-930 # 80008698 <syscalls+0xe0>
    80003a42:	00235517          	auipc	a0,0x235
    80003a46:	85e50513          	addi	a0,a0,-1954 # 802382a0 <bcache>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	2aa080e7          	jalr	682(ra) # 80000cf4 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003a52:	0023d797          	auipc	a5,0x23d
    80003a56:	84e78793          	addi	a5,a5,-1970 # 802402a0 <bcache+0x8000>
    80003a5a:	0023d717          	auipc	a4,0x23d
    80003a5e:	aae70713          	addi	a4,a4,-1362 # 80240508 <bcache+0x8268>
    80003a62:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003a66:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a6a:	00235497          	auipc	s1,0x235
    80003a6e:	84e48493          	addi	s1,s1,-1970 # 802382b8 <bcache+0x18>
    b->next = bcache.head.next;
    80003a72:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003a74:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003a76:	00005a17          	auipc	s4,0x5
    80003a7a:	c2aa0a13          	addi	s4,s4,-982 # 800086a0 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003a7e:	2b893783          	ld	a5,696(s2)
    80003a82:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003a84:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003a88:	85d2                	mv	a1,s4
    80003a8a:	01048513          	addi	a0,s1,16
    80003a8e:	00001097          	auipc	ra,0x1
    80003a92:	4c4080e7          	jalr	1220(ra) # 80004f52 <initsleeplock>
    bcache.head.next->prev = b;
    80003a96:	2b893783          	ld	a5,696(s2)
    80003a9a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003a9c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003aa0:	45848493          	addi	s1,s1,1112
    80003aa4:	fd349de3          	bne	s1,s3,80003a7e <binit+0x54>
  }
}
    80003aa8:	70a2                	ld	ra,40(sp)
    80003aaa:	7402                	ld	s0,32(sp)
    80003aac:	64e2                	ld	s1,24(sp)
    80003aae:	6942                	ld	s2,16(sp)
    80003ab0:	69a2                	ld	s3,8(sp)
    80003ab2:	6a02                	ld	s4,0(sp)
    80003ab4:	6145                	addi	sp,sp,48
    80003ab6:	8082                	ret

0000000080003ab8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003ab8:	7179                	addi	sp,sp,-48
    80003aba:	f406                	sd	ra,40(sp)
    80003abc:	f022                	sd	s0,32(sp)
    80003abe:	ec26                	sd	s1,24(sp)
    80003ac0:	e84a                	sd	s2,16(sp)
    80003ac2:	e44e                	sd	s3,8(sp)
    80003ac4:	1800                	addi	s0,sp,48
    80003ac6:	89aa                	mv	s3,a0
    80003ac8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003aca:	00234517          	auipc	a0,0x234
    80003ace:	7d650513          	addi	a0,a0,2006 # 802382a0 <bcache>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	2b2080e7          	jalr	690(ra) # 80000d84 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003ada:	0023d497          	auipc	s1,0x23d
    80003ade:	a7e4b483          	ld	s1,-1410(s1) # 80240558 <bcache+0x82b8>
    80003ae2:	0023d797          	auipc	a5,0x23d
    80003ae6:	a2678793          	addi	a5,a5,-1498 # 80240508 <bcache+0x8268>
    80003aea:	02f48f63          	beq	s1,a5,80003b28 <bread+0x70>
    80003aee:	873e                	mv	a4,a5
    80003af0:	a021                	j	80003af8 <bread+0x40>
    80003af2:	68a4                	ld	s1,80(s1)
    80003af4:	02e48a63          	beq	s1,a4,80003b28 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003af8:	449c                	lw	a5,8(s1)
    80003afa:	ff379ce3          	bne	a5,s3,80003af2 <bread+0x3a>
    80003afe:	44dc                	lw	a5,12(s1)
    80003b00:	ff2799e3          	bne	a5,s2,80003af2 <bread+0x3a>
      b->refcnt++;
    80003b04:	40bc                	lw	a5,64(s1)
    80003b06:	2785                	addiw	a5,a5,1
    80003b08:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b0a:	00234517          	auipc	a0,0x234
    80003b0e:	79650513          	addi	a0,a0,1942 # 802382a0 <bcache>
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	326080e7          	jalr	806(ra) # 80000e38 <release>
      acquiresleep(&b->lock);
    80003b1a:	01048513          	addi	a0,s1,16
    80003b1e:	00001097          	auipc	ra,0x1
    80003b22:	46e080e7          	jalr	1134(ra) # 80004f8c <acquiresleep>
      return b;
    80003b26:	a8b9                	j	80003b84 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b28:	0023d497          	auipc	s1,0x23d
    80003b2c:	a284b483          	ld	s1,-1496(s1) # 80240550 <bcache+0x82b0>
    80003b30:	0023d797          	auipc	a5,0x23d
    80003b34:	9d878793          	addi	a5,a5,-1576 # 80240508 <bcache+0x8268>
    80003b38:	00f48863          	beq	s1,a5,80003b48 <bread+0x90>
    80003b3c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003b3e:	40bc                	lw	a5,64(s1)
    80003b40:	cf81                	beqz	a5,80003b58 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b42:	64a4                	ld	s1,72(s1)
    80003b44:	fee49de3          	bne	s1,a4,80003b3e <bread+0x86>
  panic("bget: no buffers");
    80003b48:	00005517          	auipc	a0,0x5
    80003b4c:	b6050513          	addi	a0,a0,-1184 # 800086a8 <syscalls+0xf0>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	9f4080e7          	jalr	-1548(ra) # 80000544 <panic>
      b->dev = dev;
    80003b58:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003b5c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003b60:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003b64:	4785                	li	a5,1
    80003b66:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b68:	00234517          	auipc	a0,0x234
    80003b6c:	73850513          	addi	a0,a0,1848 # 802382a0 <bcache>
    80003b70:	ffffd097          	auipc	ra,0xffffd
    80003b74:	2c8080e7          	jalr	712(ra) # 80000e38 <release>
      acquiresleep(&b->lock);
    80003b78:	01048513          	addi	a0,s1,16
    80003b7c:	00001097          	auipc	ra,0x1
    80003b80:	410080e7          	jalr	1040(ra) # 80004f8c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003b84:	409c                	lw	a5,0(s1)
    80003b86:	cb89                	beqz	a5,80003b98 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003b88:	8526                	mv	a0,s1
    80003b8a:	70a2                	ld	ra,40(sp)
    80003b8c:	7402                	ld	s0,32(sp)
    80003b8e:	64e2                	ld	s1,24(sp)
    80003b90:	6942                	ld	s2,16(sp)
    80003b92:	69a2                	ld	s3,8(sp)
    80003b94:	6145                	addi	sp,sp,48
    80003b96:	8082                	ret
    virtio_disk_rw(b, 0);
    80003b98:	4581                	li	a1,0
    80003b9a:	8526                	mv	a0,s1
    80003b9c:	00003097          	auipc	ra,0x3
    80003ba0:	fcc080e7          	jalr	-52(ra) # 80006b68 <virtio_disk_rw>
    b->valid = 1;
    80003ba4:	4785                	li	a5,1
    80003ba6:	c09c                	sw	a5,0(s1)
  return b;
    80003ba8:	b7c5                	j	80003b88 <bread+0xd0>

0000000080003baa <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003baa:	1101                	addi	sp,sp,-32
    80003bac:	ec06                	sd	ra,24(sp)
    80003bae:	e822                	sd	s0,16(sp)
    80003bb0:	e426                	sd	s1,8(sp)
    80003bb2:	1000                	addi	s0,sp,32
    80003bb4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003bb6:	0541                	addi	a0,a0,16
    80003bb8:	00001097          	auipc	ra,0x1
    80003bbc:	46e080e7          	jalr	1134(ra) # 80005026 <holdingsleep>
    80003bc0:	cd01                	beqz	a0,80003bd8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003bc2:	4585                	li	a1,1
    80003bc4:	8526                	mv	a0,s1
    80003bc6:	00003097          	auipc	ra,0x3
    80003bca:	fa2080e7          	jalr	-94(ra) # 80006b68 <virtio_disk_rw>
}
    80003bce:	60e2                	ld	ra,24(sp)
    80003bd0:	6442                	ld	s0,16(sp)
    80003bd2:	64a2                	ld	s1,8(sp)
    80003bd4:	6105                	addi	sp,sp,32
    80003bd6:	8082                	ret
    panic("bwrite");
    80003bd8:	00005517          	auipc	a0,0x5
    80003bdc:	ae850513          	addi	a0,a0,-1304 # 800086c0 <syscalls+0x108>
    80003be0:	ffffd097          	auipc	ra,0xffffd
    80003be4:	964080e7          	jalr	-1692(ra) # 80000544 <panic>

0000000080003be8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003be8:	1101                	addi	sp,sp,-32
    80003bea:	ec06                	sd	ra,24(sp)
    80003bec:	e822                	sd	s0,16(sp)
    80003bee:	e426                	sd	s1,8(sp)
    80003bf0:	e04a                	sd	s2,0(sp)
    80003bf2:	1000                	addi	s0,sp,32
    80003bf4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003bf6:	01050913          	addi	s2,a0,16
    80003bfa:	854a                	mv	a0,s2
    80003bfc:	00001097          	auipc	ra,0x1
    80003c00:	42a080e7          	jalr	1066(ra) # 80005026 <holdingsleep>
    80003c04:	c92d                	beqz	a0,80003c76 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c06:	854a                	mv	a0,s2
    80003c08:	00001097          	auipc	ra,0x1
    80003c0c:	3da080e7          	jalr	986(ra) # 80004fe2 <releasesleep>

  acquire(&bcache.lock);
    80003c10:	00234517          	auipc	a0,0x234
    80003c14:	69050513          	addi	a0,a0,1680 # 802382a0 <bcache>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	16c080e7          	jalr	364(ra) # 80000d84 <acquire>
  b->refcnt--;
    80003c20:	40bc                	lw	a5,64(s1)
    80003c22:	37fd                	addiw	a5,a5,-1
    80003c24:	0007871b          	sext.w	a4,a5
    80003c28:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c2a:	eb05                	bnez	a4,80003c5a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c2c:	68bc                	ld	a5,80(s1)
    80003c2e:	64b8                	ld	a4,72(s1)
    80003c30:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003c32:	64bc                	ld	a5,72(s1)
    80003c34:	68b8                	ld	a4,80(s1)
    80003c36:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003c38:	0023c797          	auipc	a5,0x23c
    80003c3c:	66878793          	addi	a5,a5,1640 # 802402a0 <bcache+0x8000>
    80003c40:	2b87b703          	ld	a4,696(a5)
    80003c44:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003c46:	0023d717          	auipc	a4,0x23d
    80003c4a:	8c270713          	addi	a4,a4,-1854 # 80240508 <bcache+0x8268>
    80003c4e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003c50:	2b87b703          	ld	a4,696(a5)
    80003c54:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003c56:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003c5a:	00234517          	auipc	a0,0x234
    80003c5e:	64650513          	addi	a0,a0,1606 # 802382a0 <bcache>
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	1d6080e7          	jalr	470(ra) # 80000e38 <release>
}
    80003c6a:	60e2                	ld	ra,24(sp)
    80003c6c:	6442                	ld	s0,16(sp)
    80003c6e:	64a2                	ld	s1,8(sp)
    80003c70:	6902                	ld	s2,0(sp)
    80003c72:	6105                	addi	sp,sp,32
    80003c74:	8082                	ret
    panic("brelse");
    80003c76:	00005517          	auipc	a0,0x5
    80003c7a:	a5250513          	addi	a0,a0,-1454 # 800086c8 <syscalls+0x110>
    80003c7e:	ffffd097          	auipc	ra,0xffffd
    80003c82:	8c6080e7          	jalr	-1850(ra) # 80000544 <panic>

0000000080003c86 <bpin>:

void
bpin(struct buf *b) {
    80003c86:	1101                	addi	sp,sp,-32
    80003c88:	ec06                	sd	ra,24(sp)
    80003c8a:	e822                	sd	s0,16(sp)
    80003c8c:	e426                	sd	s1,8(sp)
    80003c8e:	1000                	addi	s0,sp,32
    80003c90:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c92:	00234517          	auipc	a0,0x234
    80003c96:	60e50513          	addi	a0,a0,1550 # 802382a0 <bcache>
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	0ea080e7          	jalr	234(ra) # 80000d84 <acquire>
  b->refcnt++;
    80003ca2:	40bc                	lw	a5,64(s1)
    80003ca4:	2785                	addiw	a5,a5,1
    80003ca6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ca8:	00234517          	auipc	a0,0x234
    80003cac:	5f850513          	addi	a0,a0,1528 # 802382a0 <bcache>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	188080e7          	jalr	392(ra) # 80000e38 <release>
}
    80003cb8:	60e2                	ld	ra,24(sp)
    80003cba:	6442                	ld	s0,16(sp)
    80003cbc:	64a2                	ld	s1,8(sp)
    80003cbe:	6105                	addi	sp,sp,32
    80003cc0:	8082                	ret

0000000080003cc2 <bunpin>:

void
bunpin(struct buf *b) {
    80003cc2:	1101                	addi	sp,sp,-32
    80003cc4:	ec06                	sd	ra,24(sp)
    80003cc6:	e822                	sd	s0,16(sp)
    80003cc8:	e426                	sd	s1,8(sp)
    80003cca:	1000                	addi	s0,sp,32
    80003ccc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003cce:	00234517          	auipc	a0,0x234
    80003cd2:	5d250513          	addi	a0,a0,1490 # 802382a0 <bcache>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	0ae080e7          	jalr	174(ra) # 80000d84 <acquire>
  b->refcnt--;
    80003cde:	40bc                	lw	a5,64(s1)
    80003ce0:	37fd                	addiw	a5,a5,-1
    80003ce2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ce4:	00234517          	auipc	a0,0x234
    80003ce8:	5bc50513          	addi	a0,a0,1468 # 802382a0 <bcache>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	14c080e7          	jalr	332(ra) # 80000e38 <release>
}
    80003cf4:	60e2                	ld	ra,24(sp)
    80003cf6:	6442                	ld	s0,16(sp)
    80003cf8:	64a2                	ld	s1,8(sp)
    80003cfa:	6105                	addi	sp,sp,32
    80003cfc:	8082                	ret

0000000080003cfe <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003cfe:	1101                	addi	sp,sp,-32
    80003d00:	ec06                	sd	ra,24(sp)
    80003d02:	e822                	sd	s0,16(sp)
    80003d04:	e426                	sd	s1,8(sp)
    80003d06:	e04a                	sd	s2,0(sp)
    80003d08:	1000                	addi	s0,sp,32
    80003d0a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003d0c:	00d5d59b          	srliw	a1,a1,0xd
    80003d10:	0023d797          	auipc	a5,0x23d
    80003d14:	c6c7a783          	lw	a5,-916(a5) # 8024097c <sb+0x1c>
    80003d18:	9dbd                	addw	a1,a1,a5
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	d9e080e7          	jalr	-610(ra) # 80003ab8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d22:	0074f713          	andi	a4,s1,7
    80003d26:	4785                	li	a5,1
    80003d28:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d2c:	14ce                	slli	s1,s1,0x33
    80003d2e:	90d9                	srli	s1,s1,0x36
    80003d30:	00950733          	add	a4,a0,s1
    80003d34:	05874703          	lbu	a4,88(a4)
    80003d38:	00e7f6b3          	and	a3,a5,a4
    80003d3c:	c69d                	beqz	a3,80003d6a <bfree+0x6c>
    80003d3e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003d40:	94aa                	add	s1,s1,a0
    80003d42:	fff7c793          	not	a5,a5
    80003d46:	8ff9                	and	a5,a5,a4
    80003d48:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003d4c:	00001097          	auipc	ra,0x1
    80003d50:	120080e7          	jalr	288(ra) # 80004e6c <log_write>
  brelse(bp);
    80003d54:	854a                	mv	a0,s2
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	e92080e7          	jalr	-366(ra) # 80003be8 <brelse>
}
    80003d5e:	60e2                	ld	ra,24(sp)
    80003d60:	6442                	ld	s0,16(sp)
    80003d62:	64a2                	ld	s1,8(sp)
    80003d64:	6902                	ld	s2,0(sp)
    80003d66:	6105                	addi	sp,sp,32
    80003d68:	8082                	ret
    panic("freeing free block");
    80003d6a:	00005517          	auipc	a0,0x5
    80003d6e:	96650513          	addi	a0,a0,-1690 # 800086d0 <syscalls+0x118>
    80003d72:	ffffc097          	auipc	ra,0xffffc
    80003d76:	7d2080e7          	jalr	2002(ra) # 80000544 <panic>

0000000080003d7a <balloc>:
{
    80003d7a:	711d                	addi	sp,sp,-96
    80003d7c:	ec86                	sd	ra,88(sp)
    80003d7e:	e8a2                	sd	s0,80(sp)
    80003d80:	e4a6                	sd	s1,72(sp)
    80003d82:	e0ca                	sd	s2,64(sp)
    80003d84:	fc4e                	sd	s3,56(sp)
    80003d86:	f852                	sd	s4,48(sp)
    80003d88:	f456                	sd	s5,40(sp)
    80003d8a:	f05a                	sd	s6,32(sp)
    80003d8c:	ec5e                	sd	s7,24(sp)
    80003d8e:	e862                	sd	s8,16(sp)
    80003d90:	e466                	sd	s9,8(sp)
    80003d92:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003d94:	0023d797          	auipc	a5,0x23d
    80003d98:	bd07a783          	lw	a5,-1072(a5) # 80240964 <sb+0x4>
    80003d9c:	10078163          	beqz	a5,80003e9e <balloc+0x124>
    80003da0:	8baa                	mv	s7,a0
    80003da2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003da4:	0023db17          	auipc	s6,0x23d
    80003da8:	bbcb0b13          	addi	s6,s6,-1092 # 80240960 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003dac:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003dae:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003db0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003db2:	6c89                	lui	s9,0x2
    80003db4:	a061                	j	80003e3c <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003db6:	974a                	add	a4,a4,s2
    80003db8:	8fd5                	or	a5,a5,a3
    80003dba:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	00001097          	auipc	ra,0x1
    80003dc4:	0ac080e7          	jalr	172(ra) # 80004e6c <log_write>
        brelse(bp);
    80003dc8:	854a                	mv	a0,s2
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	e1e080e7          	jalr	-482(ra) # 80003be8 <brelse>
  bp = bread(dev, bno);
    80003dd2:	85a6                	mv	a1,s1
    80003dd4:	855e                	mv	a0,s7
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	ce2080e7          	jalr	-798(ra) # 80003ab8 <bread>
    80003dde:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003de0:	40000613          	li	a2,1024
    80003de4:	4581                	li	a1,0
    80003de6:	05850513          	addi	a0,a0,88
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	096080e7          	jalr	150(ra) # 80000e80 <memset>
  log_write(bp);
    80003df2:	854a                	mv	a0,s2
    80003df4:	00001097          	auipc	ra,0x1
    80003df8:	078080e7          	jalr	120(ra) # 80004e6c <log_write>
  brelse(bp);
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	dea080e7          	jalr	-534(ra) # 80003be8 <brelse>
}
    80003e06:	8526                	mv	a0,s1
    80003e08:	60e6                	ld	ra,88(sp)
    80003e0a:	6446                	ld	s0,80(sp)
    80003e0c:	64a6                	ld	s1,72(sp)
    80003e0e:	6906                	ld	s2,64(sp)
    80003e10:	79e2                	ld	s3,56(sp)
    80003e12:	7a42                	ld	s4,48(sp)
    80003e14:	7aa2                	ld	s5,40(sp)
    80003e16:	7b02                	ld	s6,32(sp)
    80003e18:	6be2                	ld	s7,24(sp)
    80003e1a:	6c42                	ld	s8,16(sp)
    80003e1c:	6ca2                	ld	s9,8(sp)
    80003e1e:	6125                	addi	sp,sp,96
    80003e20:	8082                	ret
    brelse(bp);
    80003e22:	854a                	mv	a0,s2
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	dc4080e7          	jalr	-572(ra) # 80003be8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003e2c:	015c87bb          	addw	a5,s9,s5
    80003e30:	00078a9b          	sext.w	s5,a5
    80003e34:	004b2703          	lw	a4,4(s6)
    80003e38:	06eaf363          	bgeu	s5,a4,80003e9e <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003e3c:	41fad79b          	sraiw	a5,s5,0x1f
    80003e40:	0137d79b          	srliw	a5,a5,0x13
    80003e44:	015787bb          	addw	a5,a5,s5
    80003e48:	40d7d79b          	sraiw	a5,a5,0xd
    80003e4c:	01cb2583          	lw	a1,28(s6)
    80003e50:	9dbd                	addw	a1,a1,a5
    80003e52:	855e                	mv	a0,s7
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	c64080e7          	jalr	-924(ra) # 80003ab8 <bread>
    80003e5c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e5e:	004b2503          	lw	a0,4(s6)
    80003e62:	000a849b          	sext.w	s1,s5
    80003e66:	8662                	mv	a2,s8
    80003e68:	faa4fde3          	bgeu	s1,a0,80003e22 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003e6c:	41f6579b          	sraiw	a5,a2,0x1f
    80003e70:	01d7d69b          	srliw	a3,a5,0x1d
    80003e74:	00c6873b          	addw	a4,a3,a2
    80003e78:	00777793          	andi	a5,a4,7
    80003e7c:	9f95                	subw	a5,a5,a3
    80003e7e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e82:	4037571b          	sraiw	a4,a4,0x3
    80003e86:	00e906b3          	add	a3,s2,a4
    80003e8a:	0586c683          	lbu	a3,88(a3)
    80003e8e:	00d7f5b3          	and	a1,a5,a3
    80003e92:	d195                	beqz	a1,80003db6 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e94:	2605                	addiw	a2,a2,1
    80003e96:	2485                	addiw	s1,s1,1
    80003e98:	fd4618e3          	bne	a2,s4,80003e68 <balloc+0xee>
    80003e9c:	b759                	j	80003e22 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003e9e:	00005517          	auipc	a0,0x5
    80003ea2:	84a50513          	addi	a0,a0,-1974 # 800086e8 <syscalls+0x130>
    80003ea6:	ffffc097          	auipc	ra,0xffffc
    80003eaa:	6e8080e7          	jalr	1768(ra) # 8000058e <printf>
  return 0;
    80003eae:	4481                	li	s1,0
    80003eb0:	bf99                	j	80003e06 <balloc+0x8c>

0000000080003eb2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003eb2:	7179                	addi	sp,sp,-48
    80003eb4:	f406                	sd	ra,40(sp)
    80003eb6:	f022                	sd	s0,32(sp)
    80003eb8:	ec26                	sd	s1,24(sp)
    80003eba:	e84a                	sd	s2,16(sp)
    80003ebc:	e44e                	sd	s3,8(sp)
    80003ebe:	e052                	sd	s4,0(sp)
    80003ec0:	1800                	addi	s0,sp,48
    80003ec2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ec4:	47ad                	li	a5,11
    80003ec6:	02b7e763          	bltu	a5,a1,80003ef4 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003eca:	02059493          	slli	s1,a1,0x20
    80003ece:	9081                	srli	s1,s1,0x20
    80003ed0:	048a                	slli	s1,s1,0x2
    80003ed2:	94aa                	add	s1,s1,a0
    80003ed4:	0504a903          	lw	s2,80(s1)
    80003ed8:	06091e63          	bnez	s2,80003f54 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003edc:	4108                	lw	a0,0(a0)
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	e9c080e7          	jalr	-356(ra) # 80003d7a <balloc>
    80003ee6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003eea:	06090563          	beqz	s2,80003f54 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003eee:	0524a823          	sw	s2,80(s1)
    80003ef2:	a08d                	j	80003f54 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003ef4:	ff45849b          	addiw	s1,a1,-12
    80003ef8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003efc:	0ff00793          	li	a5,255
    80003f00:	08e7e563          	bltu	a5,a4,80003f8a <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003f04:	08052903          	lw	s2,128(a0)
    80003f08:	00091d63          	bnez	s2,80003f22 <bmap+0x70>
      addr = balloc(ip->dev);
    80003f0c:	4108                	lw	a0,0(a0)
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	e6c080e7          	jalr	-404(ra) # 80003d7a <balloc>
    80003f16:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003f1a:	02090d63          	beqz	s2,80003f54 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003f1e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003f22:	85ca                	mv	a1,s2
    80003f24:	0009a503          	lw	a0,0(s3)
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	b90080e7          	jalr	-1136(ra) # 80003ab8 <bread>
    80003f30:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003f32:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003f36:	02049593          	slli	a1,s1,0x20
    80003f3a:	9181                	srli	a1,a1,0x20
    80003f3c:	058a                	slli	a1,a1,0x2
    80003f3e:	00b784b3          	add	s1,a5,a1
    80003f42:	0004a903          	lw	s2,0(s1)
    80003f46:	02090063          	beqz	s2,80003f66 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003f4a:	8552                	mv	a0,s4
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	c9c080e7          	jalr	-868(ra) # 80003be8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003f54:	854a                	mv	a0,s2
    80003f56:	70a2                	ld	ra,40(sp)
    80003f58:	7402                	ld	s0,32(sp)
    80003f5a:	64e2                	ld	s1,24(sp)
    80003f5c:	6942                	ld	s2,16(sp)
    80003f5e:	69a2                	ld	s3,8(sp)
    80003f60:	6a02                	ld	s4,0(sp)
    80003f62:	6145                	addi	sp,sp,48
    80003f64:	8082                	ret
      addr = balloc(ip->dev);
    80003f66:	0009a503          	lw	a0,0(s3)
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	e10080e7          	jalr	-496(ra) # 80003d7a <balloc>
    80003f72:	0005091b          	sext.w	s2,a0
      if(addr){
    80003f76:	fc090ae3          	beqz	s2,80003f4a <bmap+0x98>
        a[bn] = addr;
    80003f7a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003f7e:	8552                	mv	a0,s4
    80003f80:	00001097          	auipc	ra,0x1
    80003f84:	eec080e7          	jalr	-276(ra) # 80004e6c <log_write>
    80003f88:	b7c9                	j	80003f4a <bmap+0x98>
  panic("bmap: out of range");
    80003f8a:	00004517          	auipc	a0,0x4
    80003f8e:	77650513          	addi	a0,a0,1910 # 80008700 <syscalls+0x148>
    80003f92:	ffffc097          	auipc	ra,0xffffc
    80003f96:	5b2080e7          	jalr	1458(ra) # 80000544 <panic>

0000000080003f9a <iget>:
{
    80003f9a:	7179                	addi	sp,sp,-48
    80003f9c:	f406                	sd	ra,40(sp)
    80003f9e:	f022                	sd	s0,32(sp)
    80003fa0:	ec26                	sd	s1,24(sp)
    80003fa2:	e84a                	sd	s2,16(sp)
    80003fa4:	e44e                	sd	s3,8(sp)
    80003fa6:	e052                	sd	s4,0(sp)
    80003fa8:	1800                	addi	s0,sp,48
    80003faa:	89aa                	mv	s3,a0
    80003fac:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003fae:	0023d517          	auipc	a0,0x23d
    80003fb2:	9d250513          	addi	a0,a0,-1582 # 80240980 <itable>
    80003fb6:	ffffd097          	auipc	ra,0xffffd
    80003fba:	dce080e7          	jalr	-562(ra) # 80000d84 <acquire>
  empty = 0;
    80003fbe:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fc0:	0023d497          	auipc	s1,0x23d
    80003fc4:	9d848493          	addi	s1,s1,-1576 # 80240998 <itable+0x18>
    80003fc8:	0023e697          	auipc	a3,0x23e
    80003fcc:	46068693          	addi	a3,a3,1120 # 80242428 <log>
    80003fd0:	a039                	j	80003fde <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fd2:	02090b63          	beqz	s2,80004008 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fd6:	08848493          	addi	s1,s1,136
    80003fda:	02d48a63          	beq	s1,a3,8000400e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003fde:	449c                	lw	a5,8(s1)
    80003fe0:	fef059e3          	blez	a5,80003fd2 <iget+0x38>
    80003fe4:	4098                	lw	a4,0(s1)
    80003fe6:	ff3716e3          	bne	a4,s3,80003fd2 <iget+0x38>
    80003fea:	40d8                	lw	a4,4(s1)
    80003fec:	ff4713e3          	bne	a4,s4,80003fd2 <iget+0x38>
      ip->ref++;
    80003ff0:	2785                	addiw	a5,a5,1
    80003ff2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ff4:	0023d517          	auipc	a0,0x23d
    80003ff8:	98c50513          	addi	a0,a0,-1652 # 80240980 <itable>
    80003ffc:	ffffd097          	auipc	ra,0xffffd
    80004000:	e3c080e7          	jalr	-452(ra) # 80000e38 <release>
      return ip;
    80004004:	8926                	mv	s2,s1
    80004006:	a03d                	j	80004034 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004008:	f7f9                	bnez	a5,80003fd6 <iget+0x3c>
    8000400a:	8926                	mv	s2,s1
    8000400c:	b7e9                	j	80003fd6 <iget+0x3c>
  if(empty == 0)
    8000400e:	02090c63          	beqz	s2,80004046 <iget+0xac>
  ip->dev = dev;
    80004012:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004016:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000401a:	4785                	li	a5,1
    8000401c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004020:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004024:	0023d517          	auipc	a0,0x23d
    80004028:	95c50513          	addi	a0,a0,-1700 # 80240980 <itable>
    8000402c:	ffffd097          	auipc	ra,0xffffd
    80004030:	e0c080e7          	jalr	-500(ra) # 80000e38 <release>
}
    80004034:	854a                	mv	a0,s2
    80004036:	70a2                	ld	ra,40(sp)
    80004038:	7402                	ld	s0,32(sp)
    8000403a:	64e2                	ld	s1,24(sp)
    8000403c:	6942                	ld	s2,16(sp)
    8000403e:	69a2                	ld	s3,8(sp)
    80004040:	6a02                	ld	s4,0(sp)
    80004042:	6145                	addi	sp,sp,48
    80004044:	8082                	ret
    panic("iget: no inodes");
    80004046:	00004517          	auipc	a0,0x4
    8000404a:	6d250513          	addi	a0,a0,1746 # 80008718 <syscalls+0x160>
    8000404e:	ffffc097          	auipc	ra,0xffffc
    80004052:	4f6080e7          	jalr	1270(ra) # 80000544 <panic>

0000000080004056 <fsinit>:
fsinit(int dev) {
    80004056:	7179                	addi	sp,sp,-48
    80004058:	f406                	sd	ra,40(sp)
    8000405a:	f022                	sd	s0,32(sp)
    8000405c:	ec26                	sd	s1,24(sp)
    8000405e:	e84a                	sd	s2,16(sp)
    80004060:	e44e                	sd	s3,8(sp)
    80004062:	1800                	addi	s0,sp,48
    80004064:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004066:	4585                	li	a1,1
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	a50080e7          	jalr	-1456(ra) # 80003ab8 <bread>
    80004070:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004072:	0023d997          	auipc	s3,0x23d
    80004076:	8ee98993          	addi	s3,s3,-1810 # 80240960 <sb>
    8000407a:	02000613          	li	a2,32
    8000407e:	05850593          	addi	a1,a0,88
    80004082:	854e                	mv	a0,s3
    80004084:	ffffd097          	auipc	ra,0xffffd
    80004088:	e5c080e7          	jalr	-420(ra) # 80000ee0 <memmove>
  brelse(bp);
    8000408c:	8526                	mv	a0,s1
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	b5a080e7          	jalr	-1190(ra) # 80003be8 <brelse>
  if(sb.magic != FSMAGIC)
    80004096:	0009a703          	lw	a4,0(s3)
    8000409a:	102037b7          	lui	a5,0x10203
    8000409e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800040a2:	02f71263          	bne	a4,a5,800040c6 <fsinit+0x70>
  initlog(dev, &sb);
    800040a6:	0023d597          	auipc	a1,0x23d
    800040aa:	8ba58593          	addi	a1,a1,-1862 # 80240960 <sb>
    800040ae:	854a                	mv	a0,s2
    800040b0:	00001097          	auipc	ra,0x1
    800040b4:	b40080e7          	jalr	-1216(ra) # 80004bf0 <initlog>
}
    800040b8:	70a2                	ld	ra,40(sp)
    800040ba:	7402                	ld	s0,32(sp)
    800040bc:	64e2                	ld	s1,24(sp)
    800040be:	6942                	ld	s2,16(sp)
    800040c0:	69a2                	ld	s3,8(sp)
    800040c2:	6145                	addi	sp,sp,48
    800040c4:	8082                	ret
    panic("invalid file system");
    800040c6:	00004517          	auipc	a0,0x4
    800040ca:	66250513          	addi	a0,a0,1634 # 80008728 <syscalls+0x170>
    800040ce:	ffffc097          	auipc	ra,0xffffc
    800040d2:	476080e7          	jalr	1142(ra) # 80000544 <panic>

00000000800040d6 <iinit>:
{
    800040d6:	7179                	addi	sp,sp,-48
    800040d8:	f406                	sd	ra,40(sp)
    800040da:	f022                	sd	s0,32(sp)
    800040dc:	ec26                	sd	s1,24(sp)
    800040de:	e84a                	sd	s2,16(sp)
    800040e0:	e44e                	sd	s3,8(sp)
    800040e2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800040e4:	00004597          	auipc	a1,0x4
    800040e8:	65c58593          	addi	a1,a1,1628 # 80008740 <syscalls+0x188>
    800040ec:	0023d517          	auipc	a0,0x23d
    800040f0:	89450513          	addi	a0,a0,-1900 # 80240980 <itable>
    800040f4:	ffffd097          	auipc	ra,0xffffd
    800040f8:	c00080e7          	jalr	-1024(ra) # 80000cf4 <initlock>
  for(i = 0; i < NINODE; i++) {
    800040fc:	0023d497          	auipc	s1,0x23d
    80004100:	8ac48493          	addi	s1,s1,-1876 # 802409a8 <itable+0x28>
    80004104:	0023e997          	auipc	s3,0x23e
    80004108:	33498993          	addi	s3,s3,820 # 80242438 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000410c:	00004917          	auipc	s2,0x4
    80004110:	63c90913          	addi	s2,s2,1596 # 80008748 <syscalls+0x190>
    80004114:	85ca                	mv	a1,s2
    80004116:	8526                	mv	a0,s1
    80004118:	00001097          	auipc	ra,0x1
    8000411c:	e3a080e7          	jalr	-454(ra) # 80004f52 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004120:	08848493          	addi	s1,s1,136
    80004124:	ff3498e3          	bne	s1,s3,80004114 <iinit+0x3e>
}
    80004128:	70a2                	ld	ra,40(sp)
    8000412a:	7402                	ld	s0,32(sp)
    8000412c:	64e2                	ld	s1,24(sp)
    8000412e:	6942                	ld	s2,16(sp)
    80004130:	69a2                	ld	s3,8(sp)
    80004132:	6145                	addi	sp,sp,48
    80004134:	8082                	ret

0000000080004136 <ialloc>:
{
    80004136:	715d                	addi	sp,sp,-80
    80004138:	e486                	sd	ra,72(sp)
    8000413a:	e0a2                	sd	s0,64(sp)
    8000413c:	fc26                	sd	s1,56(sp)
    8000413e:	f84a                	sd	s2,48(sp)
    80004140:	f44e                	sd	s3,40(sp)
    80004142:	f052                	sd	s4,32(sp)
    80004144:	ec56                	sd	s5,24(sp)
    80004146:	e85a                	sd	s6,16(sp)
    80004148:	e45e                	sd	s7,8(sp)
    8000414a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000414c:	0023d717          	auipc	a4,0x23d
    80004150:	82072703          	lw	a4,-2016(a4) # 8024096c <sb+0xc>
    80004154:	4785                	li	a5,1
    80004156:	04e7fa63          	bgeu	a5,a4,800041aa <ialloc+0x74>
    8000415a:	8aaa                	mv	s5,a0
    8000415c:	8bae                	mv	s7,a1
    8000415e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004160:	0023da17          	auipc	s4,0x23d
    80004164:	800a0a13          	addi	s4,s4,-2048 # 80240960 <sb>
    80004168:	00048b1b          	sext.w	s6,s1
    8000416c:	0044d593          	srli	a1,s1,0x4
    80004170:	018a2783          	lw	a5,24(s4)
    80004174:	9dbd                	addw	a1,a1,a5
    80004176:	8556                	mv	a0,s5
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	940080e7          	jalr	-1728(ra) # 80003ab8 <bread>
    80004180:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004182:	05850993          	addi	s3,a0,88
    80004186:	00f4f793          	andi	a5,s1,15
    8000418a:	079a                	slli	a5,a5,0x6
    8000418c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000418e:	00099783          	lh	a5,0(s3)
    80004192:	c3a1                	beqz	a5,800041d2 <ialloc+0x9c>
    brelse(bp);
    80004194:	00000097          	auipc	ra,0x0
    80004198:	a54080e7          	jalr	-1452(ra) # 80003be8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000419c:	0485                	addi	s1,s1,1
    8000419e:	00ca2703          	lw	a4,12(s4)
    800041a2:	0004879b          	sext.w	a5,s1
    800041a6:	fce7e1e3          	bltu	a5,a4,80004168 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800041aa:	00004517          	auipc	a0,0x4
    800041ae:	5a650513          	addi	a0,a0,1446 # 80008750 <syscalls+0x198>
    800041b2:	ffffc097          	auipc	ra,0xffffc
    800041b6:	3dc080e7          	jalr	988(ra) # 8000058e <printf>
  return 0;
    800041ba:	4501                	li	a0,0
}
    800041bc:	60a6                	ld	ra,72(sp)
    800041be:	6406                	ld	s0,64(sp)
    800041c0:	74e2                	ld	s1,56(sp)
    800041c2:	7942                	ld	s2,48(sp)
    800041c4:	79a2                	ld	s3,40(sp)
    800041c6:	7a02                	ld	s4,32(sp)
    800041c8:	6ae2                	ld	s5,24(sp)
    800041ca:	6b42                	ld	s6,16(sp)
    800041cc:	6ba2                	ld	s7,8(sp)
    800041ce:	6161                	addi	sp,sp,80
    800041d0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800041d2:	04000613          	li	a2,64
    800041d6:	4581                	li	a1,0
    800041d8:	854e                	mv	a0,s3
    800041da:	ffffd097          	auipc	ra,0xffffd
    800041de:	ca6080e7          	jalr	-858(ra) # 80000e80 <memset>
      dip->type = type;
    800041e2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800041e6:	854a                	mv	a0,s2
    800041e8:	00001097          	auipc	ra,0x1
    800041ec:	c84080e7          	jalr	-892(ra) # 80004e6c <log_write>
      brelse(bp);
    800041f0:	854a                	mv	a0,s2
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	9f6080e7          	jalr	-1546(ra) # 80003be8 <brelse>
      return iget(dev, inum);
    800041fa:	85da                	mv	a1,s6
    800041fc:	8556                	mv	a0,s5
    800041fe:	00000097          	auipc	ra,0x0
    80004202:	d9c080e7          	jalr	-612(ra) # 80003f9a <iget>
    80004206:	bf5d                	j	800041bc <ialloc+0x86>

0000000080004208 <iupdate>:
{
    80004208:	1101                	addi	sp,sp,-32
    8000420a:	ec06                	sd	ra,24(sp)
    8000420c:	e822                	sd	s0,16(sp)
    8000420e:	e426                	sd	s1,8(sp)
    80004210:	e04a                	sd	s2,0(sp)
    80004212:	1000                	addi	s0,sp,32
    80004214:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004216:	415c                	lw	a5,4(a0)
    80004218:	0047d79b          	srliw	a5,a5,0x4
    8000421c:	0023c597          	auipc	a1,0x23c
    80004220:	75c5a583          	lw	a1,1884(a1) # 80240978 <sb+0x18>
    80004224:	9dbd                	addw	a1,a1,a5
    80004226:	4108                	lw	a0,0(a0)
    80004228:	00000097          	auipc	ra,0x0
    8000422c:	890080e7          	jalr	-1904(ra) # 80003ab8 <bread>
    80004230:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004232:	05850793          	addi	a5,a0,88
    80004236:	40c8                	lw	a0,4(s1)
    80004238:	893d                	andi	a0,a0,15
    8000423a:	051a                	slli	a0,a0,0x6
    8000423c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000423e:	04449703          	lh	a4,68(s1)
    80004242:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004246:	04649703          	lh	a4,70(s1)
    8000424a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000424e:	04849703          	lh	a4,72(s1)
    80004252:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004256:	04a49703          	lh	a4,74(s1)
    8000425a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000425e:	44f8                	lw	a4,76(s1)
    80004260:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004262:	03400613          	li	a2,52
    80004266:	05048593          	addi	a1,s1,80
    8000426a:	0531                	addi	a0,a0,12
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	c74080e7          	jalr	-908(ra) # 80000ee0 <memmove>
  log_write(bp);
    80004274:	854a                	mv	a0,s2
    80004276:	00001097          	auipc	ra,0x1
    8000427a:	bf6080e7          	jalr	-1034(ra) # 80004e6c <log_write>
  brelse(bp);
    8000427e:	854a                	mv	a0,s2
    80004280:	00000097          	auipc	ra,0x0
    80004284:	968080e7          	jalr	-1688(ra) # 80003be8 <brelse>
}
    80004288:	60e2                	ld	ra,24(sp)
    8000428a:	6442                	ld	s0,16(sp)
    8000428c:	64a2                	ld	s1,8(sp)
    8000428e:	6902                	ld	s2,0(sp)
    80004290:	6105                	addi	sp,sp,32
    80004292:	8082                	ret

0000000080004294 <idup>:
{
    80004294:	1101                	addi	sp,sp,-32
    80004296:	ec06                	sd	ra,24(sp)
    80004298:	e822                	sd	s0,16(sp)
    8000429a:	e426                	sd	s1,8(sp)
    8000429c:	1000                	addi	s0,sp,32
    8000429e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800042a0:	0023c517          	auipc	a0,0x23c
    800042a4:	6e050513          	addi	a0,a0,1760 # 80240980 <itable>
    800042a8:	ffffd097          	auipc	ra,0xffffd
    800042ac:	adc080e7          	jalr	-1316(ra) # 80000d84 <acquire>
  ip->ref++;
    800042b0:	449c                	lw	a5,8(s1)
    800042b2:	2785                	addiw	a5,a5,1
    800042b4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800042b6:	0023c517          	auipc	a0,0x23c
    800042ba:	6ca50513          	addi	a0,a0,1738 # 80240980 <itable>
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	b7a080e7          	jalr	-1158(ra) # 80000e38 <release>
}
    800042c6:	8526                	mv	a0,s1
    800042c8:	60e2                	ld	ra,24(sp)
    800042ca:	6442                	ld	s0,16(sp)
    800042cc:	64a2                	ld	s1,8(sp)
    800042ce:	6105                	addi	sp,sp,32
    800042d0:	8082                	ret

00000000800042d2 <ilock>:
{
    800042d2:	1101                	addi	sp,sp,-32
    800042d4:	ec06                	sd	ra,24(sp)
    800042d6:	e822                	sd	s0,16(sp)
    800042d8:	e426                	sd	s1,8(sp)
    800042da:	e04a                	sd	s2,0(sp)
    800042dc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800042de:	c115                	beqz	a0,80004302 <ilock+0x30>
    800042e0:	84aa                	mv	s1,a0
    800042e2:	451c                	lw	a5,8(a0)
    800042e4:	00f05f63          	blez	a5,80004302 <ilock+0x30>
  acquiresleep(&ip->lock);
    800042e8:	0541                	addi	a0,a0,16
    800042ea:	00001097          	auipc	ra,0x1
    800042ee:	ca2080e7          	jalr	-862(ra) # 80004f8c <acquiresleep>
  if(ip->valid == 0){
    800042f2:	40bc                	lw	a5,64(s1)
    800042f4:	cf99                	beqz	a5,80004312 <ilock+0x40>
}
    800042f6:	60e2                	ld	ra,24(sp)
    800042f8:	6442                	ld	s0,16(sp)
    800042fa:	64a2                	ld	s1,8(sp)
    800042fc:	6902                	ld	s2,0(sp)
    800042fe:	6105                	addi	sp,sp,32
    80004300:	8082                	ret
    panic("ilock");
    80004302:	00004517          	auipc	a0,0x4
    80004306:	46650513          	addi	a0,a0,1126 # 80008768 <syscalls+0x1b0>
    8000430a:	ffffc097          	auipc	ra,0xffffc
    8000430e:	23a080e7          	jalr	570(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004312:	40dc                	lw	a5,4(s1)
    80004314:	0047d79b          	srliw	a5,a5,0x4
    80004318:	0023c597          	auipc	a1,0x23c
    8000431c:	6605a583          	lw	a1,1632(a1) # 80240978 <sb+0x18>
    80004320:	9dbd                	addw	a1,a1,a5
    80004322:	4088                	lw	a0,0(s1)
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	794080e7          	jalr	1940(ra) # 80003ab8 <bread>
    8000432c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000432e:	05850593          	addi	a1,a0,88
    80004332:	40dc                	lw	a5,4(s1)
    80004334:	8bbd                	andi	a5,a5,15
    80004336:	079a                	slli	a5,a5,0x6
    80004338:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000433a:	00059783          	lh	a5,0(a1)
    8000433e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004342:	00259783          	lh	a5,2(a1)
    80004346:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000434a:	00459783          	lh	a5,4(a1)
    8000434e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004352:	00659783          	lh	a5,6(a1)
    80004356:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000435a:	459c                	lw	a5,8(a1)
    8000435c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000435e:	03400613          	li	a2,52
    80004362:	05b1                	addi	a1,a1,12
    80004364:	05048513          	addi	a0,s1,80
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	b78080e7          	jalr	-1160(ra) # 80000ee0 <memmove>
    brelse(bp);
    80004370:	854a                	mv	a0,s2
    80004372:	00000097          	auipc	ra,0x0
    80004376:	876080e7          	jalr	-1930(ra) # 80003be8 <brelse>
    ip->valid = 1;
    8000437a:	4785                	li	a5,1
    8000437c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000437e:	04449783          	lh	a5,68(s1)
    80004382:	fbb5                	bnez	a5,800042f6 <ilock+0x24>
      panic("ilock: no type");
    80004384:	00004517          	auipc	a0,0x4
    80004388:	3ec50513          	addi	a0,a0,1004 # 80008770 <syscalls+0x1b8>
    8000438c:	ffffc097          	auipc	ra,0xffffc
    80004390:	1b8080e7          	jalr	440(ra) # 80000544 <panic>

0000000080004394 <iunlock>:
{
    80004394:	1101                	addi	sp,sp,-32
    80004396:	ec06                	sd	ra,24(sp)
    80004398:	e822                	sd	s0,16(sp)
    8000439a:	e426                	sd	s1,8(sp)
    8000439c:	e04a                	sd	s2,0(sp)
    8000439e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800043a0:	c905                	beqz	a0,800043d0 <iunlock+0x3c>
    800043a2:	84aa                	mv	s1,a0
    800043a4:	01050913          	addi	s2,a0,16
    800043a8:	854a                	mv	a0,s2
    800043aa:	00001097          	auipc	ra,0x1
    800043ae:	c7c080e7          	jalr	-900(ra) # 80005026 <holdingsleep>
    800043b2:	cd19                	beqz	a0,800043d0 <iunlock+0x3c>
    800043b4:	449c                	lw	a5,8(s1)
    800043b6:	00f05d63          	blez	a5,800043d0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800043ba:	854a                	mv	a0,s2
    800043bc:	00001097          	auipc	ra,0x1
    800043c0:	c26080e7          	jalr	-986(ra) # 80004fe2 <releasesleep>
}
    800043c4:	60e2                	ld	ra,24(sp)
    800043c6:	6442                	ld	s0,16(sp)
    800043c8:	64a2                	ld	s1,8(sp)
    800043ca:	6902                	ld	s2,0(sp)
    800043cc:	6105                	addi	sp,sp,32
    800043ce:	8082                	ret
    panic("iunlock");
    800043d0:	00004517          	auipc	a0,0x4
    800043d4:	3b050513          	addi	a0,a0,944 # 80008780 <syscalls+0x1c8>
    800043d8:	ffffc097          	auipc	ra,0xffffc
    800043dc:	16c080e7          	jalr	364(ra) # 80000544 <panic>

00000000800043e0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800043e0:	7179                	addi	sp,sp,-48
    800043e2:	f406                	sd	ra,40(sp)
    800043e4:	f022                	sd	s0,32(sp)
    800043e6:	ec26                	sd	s1,24(sp)
    800043e8:	e84a                	sd	s2,16(sp)
    800043ea:	e44e                	sd	s3,8(sp)
    800043ec:	e052                	sd	s4,0(sp)
    800043ee:	1800                	addi	s0,sp,48
    800043f0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800043f2:	05050493          	addi	s1,a0,80
    800043f6:	08050913          	addi	s2,a0,128
    800043fa:	a021                	j	80004402 <itrunc+0x22>
    800043fc:	0491                	addi	s1,s1,4
    800043fe:	01248d63          	beq	s1,s2,80004418 <itrunc+0x38>
    if(ip->addrs[i]){
    80004402:	408c                	lw	a1,0(s1)
    80004404:	dde5                	beqz	a1,800043fc <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004406:	0009a503          	lw	a0,0(s3)
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	8f4080e7          	jalr	-1804(ra) # 80003cfe <bfree>
      ip->addrs[i] = 0;
    80004412:	0004a023          	sw	zero,0(s1)
    80004416:	b7dd                	j	800043fc <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004418:	0809a583          	lw	a1,128(s3)
    8000441c:	e185                	bnez	a1,8000443c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000441e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004422:	854e                	mv	a0,s3
    80004424:	00000097          	auipc	ra,0x0
    80004428:	de4080e7          	jalr	-540(ra) # 80004208 <iupdate>
}
    8000442c:	70a2                	ld	ra,40(sp)
    8000442e:	7402                	ld	s0,32(sp)
    80004430:	64e2                	ld	s1,24(sp)
    80004432:	6942                	ld	s2,16(sp)
    80004434:	69a2                	ld	s3,8(sp)
    80004436:	6a02                	ld	s4,0(sp)
    80004438:	6145                	addi	sp,sp,48
    8000443a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000443c:	0009a503          	lw	a0,0(s3)
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	678080e7          	jalr	1656(ra) # 80003ab8 <bread>
    80004448:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000444a:	05850493          	addi	s1,a0,88
    8000444e:	45850913          	addi	s2,a0,1112
    80004452:	a811                	j	80004466 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004454:	0009a503          	lw	a0,0(s3)
    80004458:	00000097          	auipc	ra,0x0
    8000445c:	8a6080e7          	jalr	-1882(ra) # 80003cfe <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80004460:	0491                	addi	s1,s1,4
    80004462:	01248563          	beq	s1,s2,8000446c <itrunc+0x8c>
      if(a[j])
    80004466:	408c                	lw	a1,0(s1)
    80004468:	dde5                	beqz	a1,80004460 <itrunc+0x80>
    8000446a:	b7ed                	j	80004454 <itrunc+0x74>
    brelse(bp);
    8000446c:	8552                	mv	a0,s4
    8000446e:	fffff097          	auipc	ra,0xfffff
    80004472:	77a080e7          	jalr	1914(ra) # 80003be8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004476:	0809a583          	lw	a1,128(s3)
    8000447a:	0009a503          	lw	a0,0(s3)
    8000447e:	00000097          	auipc	ra,0x0
    80004482:	880080e7          	jalr	-1920(ra) # 80003cfe <bfree>
    ip->addrs[NDIRECT] = 0;
    80004486:	0809a023          	sw	zero,128(s3)
    8000448a:	bf51                	j	8000441e <itrunc+0x3e>

000000008000448c <iput>:
{
    8000448c:	1101                	addi	sp,sp,-32
    8000448e:	ec06                	sd	ra,24(sp)
    80004490:	e822                	sd	s0,16(sp)
    80004492:	e426                	sd	s1,8(sp)
    80004494:	e04a                	sd	s2,0(sp)
    80004496:	1000                	addi	s0,sp,32
    80004498:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000449a:	0023c517          	auipc	a0,0x23c
    8000449e:	4e650513          	addi	a0,a0,1254 # 80240980 <itable>
    800044a2:	ffffd097          	auipc	ra,0xffffd
    800044a6:	8e2080e7          	jalr	-1822(ra) # 80000d84 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044aa:	4498                	lw	a4,8(s1)
    800044ac:	4785                	li	a5,1
    800044ae:	02f70363          	beq	a4,a5,800044d4 <iput+0x48>
  ip->ref--;
    800044b2:	449c                	lw	a5,8(s1)
    800044b4:	37fd                	addiw	a5,a5,-1
    800044b6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800044b8:	0023c517          	auipc	a0,0x23c
    800044bc:	4c850513          	addi	a0,a0,1224 # 80240980 <itable>
    800044c0:	ffffd097          	auipc	ra,0xffffd
    800044c4:	978080e7          	jalr	-1672(ra) # 80000e38 <release>
}
    800044c8:	60e2                	ld	ra,24(sp)
    800044ca:	6442                	ld	s0,16(sp)
    800044cc:	64a2                	ld	s1,8(sp)
    800044ce:	6902                	ld	s2,0(sp)
    800044d0:	6105                	addi	sp,sp,32
    800044d2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044d4:	40bc                	lw	a5,64(s1)
    800044d6:	dff1                	beqz	a5,800044b2 <iput+0x26>
    800044d8:	04a49783          	lh	a5,74(s1)
    800044dc:	fbf9                	bnez	a5,800044b2 <iput+0x26>
    acquiresleep(&ip->lock);
    800044de:	01048913          	addi	s2,s1,16
    800044e2:	854a                	mv	a0,s2
    800044e4:	00001097          	auipc	ra,0x1
    800044e8:	aa8080e7          	jalr	-1368(ra) # 80004f8c <acquiresleep>
    release(&itable.lock);
    800044ec:	0023c517          	auipc	a0,0x23c
    800044f0:	49450513          	addi	a0,a0,1172 # 80240980 <itable>
    800044f4:	ffffd097          	auipc	ra,0xffffd
    800044f8:	944080e7          	jalr	-1724(ra) # 80000e38 <release>
    itrunc(ip);
    800044fc:	8526                	mv	a0,s1
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	ee2080e7          	jalr	-286(ra) # 800043e0 <itrunc>
    ip->type = 0;
    80004506:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000450a:	8526                	mv	a0,s1
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	cfc080e7          	jalr	-772(ra) # 80004208 <iupdate>
    ip->valid = 0;
    80004514:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004518:	854a                	mv	a0,s2
    8000451a:	00001097          	auipc	ra,0x1
    8000451e:	ac8080e7          	jalr	-1336(ra) # 80004fe2 <releasesleep>
    acquire(&itable.lock);
    80004522:	0023c517          	auipc	a0,0x23c
    80004526:	45e50513          	addi	a0,a0,1118 # 80240980 <itable>
    8000452a:	ffffd097          	auipc	ra,0xffffd
    8000452e:	85a080e7          	jalr	-1958(ra) # 80000d84 <acquire>
    80004532:	b741                	j	800044b2 <iput+0x26>

0000000080004534 <iunlockput>:
{
    80004534:	1101                	addi	sp,sp,-32
    80004536:	ec06                	sd	ra,24(sp)
    80004538:	e822                	sd	s0,16(sp)
    8000453a:	e426                	sd	s1,8(sp)
    8000453c:	1000                	addi	s0,sp,32
    8000453e:	84aa                	mv	s1,a0
  iunlock(ip);
    80004540:	00000097          	auipc	ra,0x0
    80004544:	e54080e7          	jalr	-428(ra) # 80004394 <iunlock>
  iput(ip);
    80004548:	8526                	mv	a0,s1
    8000454a:	00000097          	auipc	ra,0x0
    8000454e:	f42080e7          	jalr	-190(ra) # 8000448c <iput>
}
    80004552:	60e2                	ld	ra,24(sp)
    80004554:	6442                	ld	s0,16(sp)
    80004556:	64a2                	ld	s1,8(sp)
    80004558:	6105                	addi	sp,sp,32
    8000455a:	8082                	ret

000000008000455c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000455c:	1141                	addi	sp,sp,-16
    8000455e:	e422                	sd	s0,8(sp)
    80004560:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004562:	411c                	lw	a5,0(a0)
    80004564:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004566:	415c                	lw	a5,4(a0)
    80004568:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000456a:	04451783          	lh	a5,68(a0)
    8000456e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004572:	04a51783          	lh	a5,74(a0)
    80004576:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000457a:	04c56783          	lwu	a5,76(a0)
    8000457e:	e99c                	sd	a5,16(a1)
}
    80004580:	6422                	ld	s0,8(sp)
    80004582:	0141                	addi	sp,sp,16
    80004584:	8082                	ret

0000000080004586 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004586:	457c                	lw	a5,76(a0)
    80004588:	0ed7e963          	bltu	a5,a3,8000467a <readi+0xf4>
{
    8000458c:	7159                	addi	sp,sp,-112
    8000458e:	f486                	sd	ra,104(sp)
    80004590:	f0a2                	sd	s0,96(sp)
    80004592:	eca6                	sd	s1,88(sp)
    80004594:	e8ca                	sd	s2,80(sp)
    80004596:	e4ce                	sd	s3,72(sp)
    80004598:	e0d2                	sd	s4,64(sp)
    8000459a:	fc56                	sd	s5,56(sp)
    8000459c:	f85a                	sd	s6,48(sp)
    8000459e:	f45e                	sd	s7,40(sp)
    800045a0:	f062                	sd	s8,32(sp)
    800045a2:	ec66                	sd	s9,24(sp)
    800045a4:	e86a                	sd	s10,16(sp)
    800045a6:	e46e                	sd	s11,8(sp)
    800045a8:	1880                	addi	s0,sp,112
    800045aa:	8b2a                	mv	s6,a0
    800045ac:	8bae                	mv	s7,a1
    800045ae:	8a32                	mv	s4,a2
    800045b0:	84b6                	mv	s1,a3
    800045b2:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800045b4:	9f35                	addw	a4,a4,a3
    return 0;
    800045b6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800045b8:	0ad76063          	bltu	a4,a3,80004658 <readi+0xd2>
  if(off + n > ip->size)
    800045bc:	00e7f463          	bgeu	a5,a4,800045c4 <readi+0x3e>
    n = ip->size - off;
    800045c0:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045c4:	0a0a8963          	beqz	s5,80004676 <readi+0xf0>
    800045c8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800045ca:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800045ce:	5c7d                	li	s8,-1
    800045d0:	a82d                	j	8000460a <readi+0x84>
    800045d2:	020d1d93          	slli	s11,s10,0x20
    800045d6:	020ddd93          	srli	s11,s11,0x20
    800045da:	05890613          	addi	a2,s2,88
    800045de:	86ee                	mv	a3,s11
    800045e0:	963a                	add	a2,a2,a4
    800045e2:	85d2                	mv	a1,s4
    800045e4:	855e                	mv	a0,s7
    800045e6:	ffffe097          	auipc	ra,0xffffe
    800045ea:	3ce080e7          	jalr	974(ra) # 800029b4 <either_copyout>
    800045ee:	05850d63          	beq	a0,s8,80004648 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800045f2:	854a                	mv	a0,s2
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	5f4080e7          	jalr	1524(ra) # 80003be8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045fc:	013d09bb          	addw	s3,s10,s3
    80004600:	009d04bb          	addw	s1,s10,s1
    80004604:	9a6e                	add	s4,s4,s11
    80004606:	0559f763          	bgeu	s3,s5,80004654 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000460a:	00a4d59b          	srliw	a1,s1,0xa
    8000460e:	855a                	mv	a0,s6
    80004610:	00000097          	auipc	ra,0x0
    80004614:	8a2080e7          	jalr	-1886(ra) # 80003eb2 <bmap>
    80004618:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000461c:	cd85                	beqz	a1,80004654 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000461e:	000b2503          	lw	a0,0(s6)
    80004622:	fffff097          	auipc	ra,0xfffff
    80004626:	496080e7          	jalr	1174(ra) # 80003ab8 <bread>
    8000462a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000462c:	3ff4f713          	andi	a4,s1,1023
    80004630:	40ec87bb          	subw	a5,s9,a4
    80004634:	413a86bb          	subw	a3,s5,s3
    80004638:	8d3e                	mv	s10,a5
    8000463a:	2781                	sext.w	a5,a5
    8000463c:	0006861b          	sext.w	a2,a3
    80004640:	f8f679e3          	bgeu	a2,a5,800045d2 <readi+0x4c>
    80004644:	8d36                	mv	s10,a3
    80004646:	b771                	j	800045d2 <readi+0x4c>
      brelse(bp);
    80004648:	854a                	mv	a0,s2
    8000464a:	fffff097          	auipc	ra,0xfffff
    8000464e:	59e080e7          	jalr	1438(ra) # 80003be8 <brelse>
      tot = -1;
    80004652:	59fd                	li	s3,-1
  }
  return tot;
    80004654:	0009851b          	sext.w	a0,s3
}
    80004658:	70a6                	ld	ra,104(sp)
    8000465a:	7406                	ld	s0,96(sp)
    8000465c:	64e6                	ld	s1,88(sp)
    8000465e:	6946                	ld	s2,80(sp)
    80004660:	69a6                	ld	s3,72(sp)
    80004662:	6a06                	ld	s4,64(sp)
    80004664:	7ae2                	ld	s5,56(sp)
    80004666:	7b42                	ld	s6,48(sp)
    80004668:	7ba2                	ld	s7,40(sp)
    8000466a:	7c02                	ld	s8,32(sp)
    8000466c:	6ce2                	ld	s9,24(sp)
    8000466e:	6d42                	ld	s10,16(sp)
    80004670:	6da2                	ld	s11,8(sp)
    80004672:	6165                	addi	sp,sp,112
    80004674:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004676:	89d6                	mv	s3,s5
    80004678:	bff1                	j	80004654 <readi+0xce>
    return 0;
    8000467a:	4501                	li	a0,0
}
    8000467c:	8082                	ret

000000008000467e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000467e:	457c                	lw	a5,76(a0)
    80004680:	10d7e863          	bltu	a5,a3,80004790 <writei+0x112>
{
    80004684:	7159                	addi	sp,sp,-112
    80004686:	f486                	sd	ra,104(sp)
    80004688:	f0a2                	sd	s0,96(sp)
    8000468a:	eca6                	sd	s1,88(sp)
    8000468c:	e8ca                	sd	s2,80(sp)
    8000468e:	e4ce                	sd	s3,72(sp)
    80004690:	e0d2                	sd	s4,64(sp)
    80004692:	fc56                	sd	s5,56(sp)
    80004694:	f85a                	sd	s6,48(sp)
    80004696:	f45e                	sd	s7,40(sp)
    80004698:	f062                	sd	s8,32(sp)
    8000469a:	ec66                	sd	s9,24(sp)
    8000469c:	e86a                	sd	s10,16(sp)
    8000469e:	e46e                	sd	s11,8(sp)
    800046a0:	1880                	addi	s0,sp,112
    800046a2:	8aaa                	mv	s5,a0
    800046a4:	8bae                	mv	s7,a1
    800046a6:	8a32                	mv	s4,a2
    800046a8:	8936                	mv	s2,a3
    800046aa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800046ac:	00e687bb          	addw	a5,a3,a4
    800046b0:	0ed7e263          	bltu	a5,a3,80004794 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800046b4:	00043737          	lui	a4,0x43
    800046b8:	0ef76063          	bltu	a4,a5,80004798 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046bc:	0c0b0863          	beqz	s6,8000478c <writei+0x10e>
    800046c0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800046c2:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800046c6:	5c7d                	li	s8,-1
    800046c8:	a091                	j	8000470c <writei+0x8e>
    800046ca:	020d1d93          	slli	s11,s10,0x20
    800046ce:	020ddd93          	srli	s11,s11,0x20
    800046d2:	05848513          	addi	a0,s1,88
    800046d6:	86ee                	mv	a3,s11
    800046d8:	8652                	mv	a2,s4
    800046da:	85de                	mv	a1,s7
    800046dc:	953a                	add	a0,a0,a4
    800046de:	ffffe097          	auipc	ra,0xffffe
    800046e2:	32c080e7          	jalr	812(ra) # 80002a0a <either_copyin>
    800046e6:	07850263          	beq	a0,s8,8000474a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800046ea:	8526                	mv	a0,s1
    800046ec:	00000097          	auipc	ra,0x0
    800046f0:	780080e7          	jalr	1920(ra) # 80004e6c <log_write>
    brelse(bp);
    800046f4:	8526                	mv	a0,s1
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	4f2080e7          	jalr	1266(ra) # 80003be8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046fe:	013d09bb          	addw	s3,s10,s3
    80004702:	012d093b          	addw	s2,s10,s2
    80004706:	9a6e                	add	s4,s4,s11
    80004708:	0569f663          	bgeu	s3,s6,80004754 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000470c:	00a9559b          	srliw	a1,s2,0xa
    80004710:	8556                	mv	a0,s5
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	7a0080e7          	jalr	1952(ra) # 80003eb2 <bmap>
    8000471a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000471e:	c99d                	beqz	a1,80004754 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004720:	000aa503          	lw	a0,0(s5)
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	394080e7          	jalr	916(ra) # 80003ab8 <bread>
    8000472c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000472e:	3ff97713          	andi	a4,s2,1023
    80004732:	40ec87bb          	subw	a5,s9,a4
    80004736:	413b06bb          	subw	a3,s6,s3
    8000473a:	8d3e                	mv	s10,a5
    8000473c:	2781                	sext.w	a5,a5
    8000473e:	0006861b          	sext.w	a2,a3
    80004742:	f8f674e3          	bgeu	a2,a5,800046ca <writei+0x4c>
    80004746:	8d36                	mv	s10,a3
    80004748:	b749                	j	800046ca <writei+0x4c>
      brelse(bp);
    8000474a:	8526                	mv	a0,s1
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	49c080e7          	jalr	1180(ra) # 80003be8 <brelse>
  }

  if(off > ip->size)
    80004754:	04caa783          	lw	a5,76(s5)
    80004758:	0127f463          	bgeu	a5,s2,80004760 <writei+0xe2>
    ip->size = off;
    8000475c:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004760:	8556                	mv	a0,s5
    80004762:	00000097          	auipc	ra,0x0
    80004766:	aa6080e7          	jalr	-1370(ra) # 80004208 <iupdate>

  return tot;
    8000476a:	0009851b          	sext.w	a0,s3
}
    8000476e:	70a6                	ld	ra,104(sp)
    80004770:	7406                	ld	s0,96(sp)
    80004772:	64e6                	ld	s1,88(sp)
    80004774:	6946                	ld	s2,80(sp)
    80004776:	69a6                	ld	s3,72(sp)
    80004778:	6a06                	ld	s4,64(sp)
    8000477a:	7ae2                	ld	s5,56(sp)
    8000477c:	7b42                	ld	s6,48(sp)
    8000477e:	7ba2                	ld	s7,40(sp)
    80004780:	7c02                	ld	s8,32(sp)
    80004782:	6ce2                	ld	s9,24(sp)
    80004784:	6d42                	ld	s10,16(sp)
    80004786:	6da2                	ld	s11,8(sp)
    80004788:	6165                	addi	sp,sp,112
    8000478a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000478c:	89da                	mv	s3,s6
    8000478e:	bfc9                	j	80004760 <writei+0xe2>
    return -1;
    80004790:	557d                	li	a0,-1
}
    80004792:	8082                	ret
    return -1;
    80004794:	557d                	li	a0,-1
    80004796:	bfe1                	j	8000476e <writei+0xf0>
    return -1;
    80004798:	557d                	li	a0,-1
    8000479a:	bfd1                	j	8000476e <writei+0xf0>

000000008000479c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000479c:	1141                	addi	sp,sp,-16
    8000479e:	e406                	sd	ra,8(sp)
    800047a0:	e022                	sd	s0,0(sp)
    800047a2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800047a4:	4639                	li	a2,14
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	7b2080e7          	jalr	1970(ra) # 80000f58 <strncmp>
}
    800047ae:	60a2                	ld	ra,8(sp)
    800047b0:	6402                	ld	s0,0(sp)
    800047b2:	0141                	addi	sp,sp,16
    800047b4:	8082                	ret

00000000800047b6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800047b6:	7139                	addi	sp,sp,-64
    800047b8:	fc06                	sd	ra,56(sp)
    800047ba:	f822                	sd	s0,48(sp)
    800047bc:	f426                	sd	s1,40(sp)
    800047be:	f04a                	sd	s2,32(sp)
    800047c0:	ec4e                	sd	s3,24(sp)
    800047c2:	e852                	sd	s4,16(sp)
    800047c4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800047c6:	04451703          	lh	a4,68(a0)
    800047ca:	4785                	li	a5,1
    800047cc:	00f71a63          	bne	a4,a5,800047e0 <dirlookup+0x2a>
    800047d0:	892a                	mv	s2,a0
    800047d2:	89ae                	mv	s3,a1
    800047d4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800047d6:	457c                	lw	a5,76(a0)
    800047d8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800047da:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047dc:	e79d                	bnez	a5,8000480a <dirlookup+0x54>
    800047de:	a8a5                	j	80004856 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800047e0:	00004517          	auipc	a0,0x4
    800047e4:	fa850513          	addi	a0,a0,-88 # 80008788 <syscalls+0x1d0>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	d5c080e7          	jalr	-676(ra) # 80000544 <panic>
      panic("dirlookup read");
    800047f0:	00004517          	auipc	a0,0x4
    800047f4:	fb050513          	addi	a0,a0,-80 # 800087a0 <syscalls+0x1e8>
    800047f8:	ffffc097          	auipc	ra,0xffffc
    800047fc:	d4c080e7          	jalr	-692(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004800:	24c1                	addiw	s1,s1,16
    80004802:	04c92783          	lw	a5,76(s2)
    80004806:	04f4f763          	bgeu	s1,a5,80004854 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000480a:	4741                	li	a4,16
    8000480c:	86a6                	mv	a3,s1
    8000480e:	fc040613          	addi	a2,s0,-64
    80004812:	4581                	li	a1,0
    80004814:	854a                	mv	a0,s2
    80004816:	00000097          	auipc	ra,0x0
    8000481a:	d70080e7          	jalr	-656(ra) # 80004586 <readi>
    8000481e:	47c1                	li	a5,16
    80004820:	fcf518e3          	bne	a0,a5,800047f0 <dirlookup+0x3a>
    if(de.inum == 0)
    80004824:	fc045783          	lhu	a5,-64(s0)
    80004828:	dfe1                	beqz	a5,80004800 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000482a:	fc240593          	addi	a1,s0,-62
    8000482e:	854e                	mv	a0,s3
    80004830:	00000097          	auipc	ra,0x0
    80004834:	f6c080e7          	jalr	-148(ra) # 8000479c <namecmp>
    80004838:	f561                	bnez	a0,80004800 <dirlookup+0x4a>
      if(poff)
    8000483a:	000a0463          	beqz	s4,80004842 <dirlookup+0x8c>
        *poff = off;
    8000483e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004842:	fc045583          	lhu	a1,-64(s0)
    80004846:	00092503          	lw	a0,0(s2)
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	750080e7          	jalr	1872(ra) # 80003f9a <iget>
    80004852:	a011                	j	80004856 <dirlookup+0xa0>
  return 0;
    80004854:	4501                	li	a0,0
}
    80004856:	70e2                	ld	ra,56(sp)
    80004858:	7442                	ld	s0,48(sp)
    8000485a:	74a2                	ld	s1,40(sp)
    8000485c:	7902                	ld	s2,32(sp)
    8000485e:	69e2                	ld	s3,24(sp)
    80004860:	6a42                	ld	s4,16(sp)
    80004862:	6121                	addi	sp,sp,64
    80004864:	8082                	ret

0000000080004866 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004866:	711d                	addi	sp,sp,-96
    80004868:	ec86                	sd	ra,88(sp)
    8000486a:	e8a2                	sd	s0,80(sp)
    8000486c:	e4a6                	sd	s1,72(sp)
    8000486e:	e0ca                	sd	s2,64(sp)
    80004870:	fc4e                	sd	s3,56(sp)
    80004872:	f852                	sd	s4,48(sp)
    80004874:	f456                	sd	s5,40(sp)
    80004876:	f05a                	sd	s6,32(sp)
    80004878:	ec5e                	sd	s7,24(sp)
    8000487a:	e862                	sd	s8,16(sp)
    8000487c:	e466                	sd	s9,8(sp)
    8000487e:	1080                	addi	s0,sp,96
    80004880:	84aa                	mv	s1,a0
    80004882:	8b2e                	mv	s6,a1
    80004884:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004886:	00054703          	lbu	a4,0(a0)
    8000488a:	02f00793          	li	a5,47
    8000488e:	02f70363          	beq	a4,a5,800048b4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004892:	ffffd097          	auipc	ra,0xffffd
    80004896:	310080e7          	jalr	784(ra) # 80001ba2 <myproc>
    8000489a:	19053503          	ld	a0,400(a0)
    8000489e:	00000097          	auipc	ra,0x0
    800048a2:	9f6080e7          	jalr	-1546(ra) # 80004294 <idup>
    800048a6:	89aa                	mv	s3,a0
  while(*path == '/')
    800048a8:	02f00913          	li	s2,47
  len = path - s;
    800048ac:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800048ae:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800048b0:	4c05                	li	s8,1
    800048b2:	a865                	j	8000496a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800048b4:	4585                	li	a1,1
    800048b6:	4505                	li	a0,1
    800048b8:	fffff097          	auipc	ra,0xfffff
    800048bc:	6e2080e7          	jalr	1762(ra) # 80003f9a <iget>
    800048c0:	89aa                	mv	s3,a0
    800048c2:	b7dd                	j	800048a8 <namex+0x42>
      iunlockput(ip);
    800048c4:	854e                	mv	a0,s3
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	c6e080e7          	jalr	-914(ra) # 80004534 <iunlockput>
      return 0;
    800048ce:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800048d0:	854e                	mv	a0,s3
    800048d2:	60e6                	ld	ra,88(sp)
    800048d4:	6446                	ld	s0,80(sp)
    800048d6:	64a6                	ld	s1,72(sp)
    800048d8:	6906                	ld	s2,64(sp)
    800048da:	79e2                	ld	s3,56(sp)
    800048dc:	7a42                	ld	s4,48(sp)
    800048de:	7aa2                	ld	s5,40(sp)
    800048e0:	7b02                	ld	s6,32(sp)
    800048e2:	6be2                	ld	s7,24(sp)
    800048e4:	6c42                	ld	s8,16(sp)
    800048e6:	6ca2                	ld	s9,8(sp)
    800048e8:	6125                	addi	sp,sp,96
    800048ea:	8082                	ret
      iunlock(ip);
    800048ec:	854e                	mv	a0,s3
    800048ee:	00000097          	auipc	ra,0x0
    800048f2:	aa6080e7          	jalr	-1370(ra) # 80004394 <iunlock>
      return ip;
    800048f6:	bfe9                	j	800048d0 <namex+0x6a>
      iunlockput(ip);
    800048f8:	854e                	mv	a0,s3
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	c3a080e7          	jalr	-966(ra) # 80004534 <iunlockput>
      return 0;
    80004902:	89d2                	mv	s3,s4
    80004904:	b7f1                	j	800048d0 <namex+0x6a>
  len = path - s;
    80004906:	40b48633          	sub	a2,s1,a1
    8000490a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000490e:	094cd463          	bge	s9,s4,80004996 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004912:	4639                	li	a2,14
    80004914:	8556                	mv	a0,s5
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	5ca080e7          	jalr	1482(ra) # 80000ee0 <memmove>
  while(*path == '/')
    8000491e:	0004c783          	lbu	a5,0(s1)
    80004922:	01279763          	bne	a5,s2,80004930 <namex+0xca>
    path++;
    80004926:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004928:	0004c783          	lbu	a5,0(s1)
    8000492c:	ff278de3          	beq	a5,s2,80004926 <namex+0xc0>
    ilock(ip);
    80004930:	854e                	mv	a0,s3
    80004932:	00000097          	auipc	ra,0x0
    80004936:	9a0080e7          	jalr	-1632(ra) # 800042d2 <ilock>
    if(ip->type != T_DIR){
    8000493a:	04499783          	lh	a5,68(s3)
    8000493e:	f98793e3          	bne	a5,s8,800048c4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004942:	000b0563          	beqz	s6,8000494c <namex+0xe6>
    80004946:	0004c783          	lbu	a5,0(s1)
    8000494a:	d3cd                	beqz	a5,800048ec <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000494c:	865e                	mv	a2,s7
    8000494e:	85d6                	mv	a1,s5
    80004950:	854e                	mv	a0,s3
    80004952:	00000097          	auipc	ra,0x0
    80004956:	e64080e7          	jalr	-412(ra) # 800047b6 <dirlookup>
    8000495a:	8a2a                	mv	s4,a0
    8000495c:	dd51                	beqz	a0,800048f8 <namex+0x92>
    iunlockput(ip);
    8000495e:	854e                	mv	a0,s3
    80004960:	00000097          	auipc	ra,0x0
    80004964:	bd4080e7          	jalr	-1068(ra) # 80004534 <iunlockput>
    ip = next;
    80004968:	89d2                	mv	s3,s4
  while(*path == '/')
    8000496a:	0004c783          	lbu	a5,0(s1)
    8000496e:	05279763          	bne	a5,s2,800049bc <namex+0x156>
    path++;
    80004972:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004974:	0004c783          	lbu	a5,0(s1)
    80004978:	ff278de3          	beq	a5,s2,80004972 <namex+0x10c>
  if(*path == 0)
    8000497c:	c79d                	beqz	a5,800049aa <namex+0x144>
    path++;
    8000497e:	85a6                	mv	a1,s1
  len = path - s;
    80004980:	8a5e                	mv	s4,s7
    80004982:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004984:	01278963          	beq	a5,s2,80004996 <namex+0x130>
    80004988:	dfbd                	beqz	a5,80004906 <namex+0xa0>
    path++;
    8000498a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000498c:	0004c783          	lbu	a5,0(s1)
    80004990:	ff279ce3          	bne	a5,s2,80004988 <namex+0x122>
    80004994:	bf8d                	j	80004906 <namex+0xa0>
    memmove(name, s, len);
    80004996:	2601                	sext.w	a2,a2
    80004998:	8556                	mv	a0,s5
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	546080e7          	jalr	1350(ra) # 80000ee0 <memmove>
    name[len] = 0;
    800049a2:	9a56                	add	s4,s4,s5
    800049a4:	000a0023          	sb	zero,0(s4)
    800049a8:	bf9d                	j	8000491e <namex+0xb8>
  if(nameiparent){
    800049aa:	f20b03e3          	beqz	s6,800048d0 <namex+0x6a>
    iput(ip);
    800049ae:	854e                	mv	a0,s3
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	adc080e7          	jalr	-1316(ra) # 8000448c <iput>
    return 0;
    800049b8:	4981                	li	s3,0
    800049ba:	bf19                	j	800048d0 <namex+0x6a>
  if(*path == 0)
    800049bc:	d7fd                	beqz	a5,800049aa <namex+0x144>
  while(*path != '/' && *path != 0)
    800049be:	0004c783          	lbu	a5,0(s1)
    800049c2:	85a6                	mv	a1,s1
    800049c4:	b7d1                	j	80004988 <namex+0x122>

00000000800049c6 <dirlink>:
{
    800049c6:	7139                	addi	sp,sp,-64
    800049c8:	fc06                	sd	ra,56(sp)
    800049ca:	f822                	sd	s0,48(sp)
    800049cc:	f426                	sd	s1,40(sp)
    800049ce:	f04a                	sd	s2,32(sp)
    800049d0:	ec4e                	sd	s3,24(sp)
    800049d2:	e852                	sd	s4,16(sp)
    800049d4:	0080                	addi	s0,sp,64
    800049d6:	892a                	mv	s2,a0
    800049d8:	8a2e                	mv	s4,a1
    800049da:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800049dc:	4601                	li	a2,0
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	dd8080e7          	jalr	-552(ra) # 800047b6 <dirlookup>
    800049e6:	e93d                	bnez	a0,80004a5c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049e8:	04c92483          	lw	s1,76(s2)
    800049ec:	c49d                	beqz	s1,80004a1a <dirlink+0x54>
    800049ee:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049f0:	4741                	li	a4,16
    800049f2:	86a6                	mv	a3,s1
    800049f4:	fc040613          	addi	a2,s0,-64
    800049f8:	4581                	li	a1,0
    800049fa:	854a                	mv	a0,s2
    800049fc:	00000097          	auipc	ra,0x0
    80004a00:	b8a080e7          	jalr	-1142(ra) # 80004586 <readi>
    80004a04:	47c1                	li	a5,16
    80004a06:	06f51163          	bne	a0,a5,80004a68 <dirlink+0xa2>
    if(de.inum == 0)
    80004a0a:	fc045783          	lhu	a5,-64(s0)
    80004a0e:	c791                	beqz	a5,80004a1a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a10:	24c1                	addiw	s1,s1,16
    80004a12:	04c92783          	lw	a5,76(s2)
    80004a16:	fcf4ede3          	bltu	s1,a5,800049f0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004a1a:	4639                	li	a2,14
    80004a1c:	85d2                	mv	a1,s4
    80004a1e:	fc240513          	addi	a0,s0,-62
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	572080e7          	jalr	1394(ra) # 80000f94 <strncpy>
  de.inum = inum;
    80004a2a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a2e:	4741                	li	a4,16
    80004a30:	86a6                	mv	a3,s1
    80004a32:	fc040613          	addi	a2,s0,-64
    80004a36:	4581                	li	a1,0
    80004a38:	854a                	mv	a0,s2
    80004a3a:	00000097          	auipc	ra,0x0
    80004a3e:	c44080e7          	jalr	-956(ra) # 8000467e <writei>
    80004a42:	1541                	addi	a0,a0,-16
    80004a44:	00a03533          	snez	a0,a0
    80004a48:	40a00533          	neg	a0,a0
}
    80004a4c:	70e2                	ld	ra,56(sp)
    80004a4e:	7442                	ld	s0,48(sp)
    80004a50:	74a2                	ld	s1,40(sp)
    80004a52:	7902                	ld	s2,32(sp)
    80004a54:	69e2                	ld	s3,24(sp)
    80004a56:	6a42                	ld	s4,16(sp)
    80004a58:	6121                	addi	sp,sp,64
    80004a5a:	8082                	ret
    iput(ip);
    80004a5c:	00000097          	auipc	ra,0x0
    80004a60:	a30080e7          	jalr	-1488(ra) # 8000448c <iput>
    return -1;
    80004a64:	557d                	li	a0,-1
    80004a66:	b7dd                	j	80004a4c <dirlink+0x86>
      panic("dirlink read");
    80004a68:	00004517          	auipc	a0,0x4
    80004a6c:	d4850513          	addi	a0,a0,-696 # 800087b0 <syscalls+0x1f8>
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	ad4080e7          	jalr	-1324(ra) # 80000544 <panic>

0000000080004a78 <namei>:

struct inode*
namei(char *path)
{
    80004a78:	1101                	addi	sp,sp,-32
    80004a7a:	ec06                	sd	ra,24(sp)
    80004a7c:	e822                	sd	s0,16(sp)
    80004a7e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004a80:	fe040613          	addi	a2,s0,-32
    80004a84:	4581                	li	a1,0
    80004a86:	00000097          	auipc	ra,0x0
    80004a8a:	de0080e7          	jalr	-544(ra) # 80004866 <namex>
}
    80004a8e:	60e2                	ld	ra,24(sp)
    80004a90:	6442                	ld	s0,16(sp)
    80004a92:	6105                	addi	sp,sp,32
    80004a94:	8082                	ret

0000000080004a96 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004a96:	1141                	addi	sp,sp,-16
    80004a98:	e406                	sd	ra,8(sp)
    80004a9a:	e022                	sd	s0,0(sp)
    80004a9c:	0800                	addi	s0,sp,16
    80004a9e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004aa0:	4585                	li	a1,1
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	dc4080e7          	jalr	-572(ra) # 80004866 <namex>
}
    80004aaa:	60a2                	ld	ra,8(sp)
    80004aac:	6402                	ld	s0,0(sp)
    80004aae:	0141                	addi	sp,sp,16
    80004ab0:	8082                	ret

0000000080004ab2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004ab2:	1101                	addi	sp,sp,-32
    80004ab4:	ec06                	sd	ra,24(sp)
    80004ab6:	e822                	sd	s0,16(sp)
    80004ab8:	e426                	sd	s1,8(sp)
    80004aba:	e04a                	sd	s2,0(sp)
    80004abc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004abe:	0023e917          	auipc	s2,0x23e
    80004ac2:	96a90913          	addi	s2,s2,-1686 # 80242428 <log>
    80004ac6:	01892583          	lw	a1,24(s2)
    80004aca:	02892503          	lw	a0,40(s2)
    80004ace:	fffff097          	auipc	ra,0xfffff
    80004ad2:	fea080e7          	jalr	-22(ra) # 80003ab8 <bread>
    80004ad6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004ad8:	02c92683          	lw	a3,44(s2)
    80004adc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004ade:	02d05763          	blez	a3,80004b0c <write_head+0x5a>
    80004ae2:	0023e797          	auipc	a5,0x23e
    80004ae6:	97678793          	addi	a5,a5,-1674 # 80242458 <log+0x30>
    80004aea:	05c50713          	addi	a4,a0,92
    80004aee:	36fd                	addiw	a3,a3,-1
    80004af0:	1682                	slli	a3,a3,0x20
    80004af2:	9281                	srli	a3,a3,0x20
    80004af4:	068a                	slli	a3,a3,0x2
    80004af6:	0023e617          	auipc	a2,0x23e
    80004afa:	96660613          	addi	a2,a2,-1690 # 8024245c <log+0x34>
    80004afe:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004b00:	4390                	lw	a2,0(a5)
    80004b02:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b04:	0791                	addi	a5,a5,4
    80004b06:	0711                	addi	a4,a4,4
    80004b08:	fed79ce3          	bne	a5,a3,80004b00 <write_head+0x4e>
  }
  bwrite(buf);
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	fffff097          	auipc	ra,0xfffff
    80004b12:	09c080e7          	jalr	156(ra) # 80003baa <bwrite>
  brelse(buf);
    80004b16:	8526                	mv	a0,s1
    80004b18:	fffff097          	auipc	ra,0xfffff
    80004b1c:	0d0080e7          	jalr	208(ra) # 80003be8 <brelse>
}
    80004b20:	60e2                	ld	ra,24(sp)
    80004b22:	6442                	ld	s0,16(sp)
    80004b24:	64a2                	ld	s1,8(sp)
    80004b26:	6902                	ld	s2,0(sp)
    80004b28:	6105                	addi	sp,sp,32
    80004b2a:	8082                	ret

0000000080004b2c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b2c:	0023e797          	auipc	a5,0x23e
    80004b30:	9287a783          	lw	a5,-1752(a5) # 80242454 <log+0x2c>
    80004b34:	0af05d63          	blez	a5,80004bee <install_trans+0xc2>
{
    80004b38:	7139                	addi	sp,sp,-64
    80004b3a:	fc06                	sd	ra,56(sp)
    80004b3c:	f822                	sd	s0,48(sp)
    80004b3e:	f426                	sd	s1,40(sp)
    80004b40:	f04a                	sd	s2,32(sp)
    80004b42:	ec4e                	sd	s3,24(sp)
    80004b44:	e852                	sd	s4,16(sp)
    80004b46:	e456                	sd	s5,8(sp)
    80004b48:	e05a                	sd	s6,0(sp)
    80004b4a:	0080                	addi	s0,sp,64
    80004b4c:	8b2a                	mv	s6,a0
    80004b4e:	0023ea97          	auipc	s5,0x23e
    80004b52:	90aa8a93          	addi	s5,s5,-1782 # 80242458 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b56:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b58:	0023e997          	auipc	s3,0x23e
    80004b5c:	8d098993          	addi	s3,s3,-1840 # 80242428 <log>
    80004b60:	a035                	j	80004b8c <install_trans+0x60>
      bunpin(dbuf);
    80004b62:	8526                	mv	a0,s1
    80004b64:	fffff097          	auipc	ra,0xfffff
    80004b68:	15e080e7          	jalr	350(ra) # 80003cc2 <bunpin>
    brelse(lbuf);
    80004b6c:	854a                	mv	a0,s2
    80004b6e:	fffff097          	auipc	ra,0xfffff
    80004b72:	07a080e7          	jalr	122(ra) # 80003be8 <brelse>
    brelse(dbuf);
    80004b76:	8526                	mv	a0,s1
    80004b78:	fffff097          	auipc	ra,0xfffff
    80004b7c:	070080e7          	jalr	112(ra) # 80003be8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b80:	2a05                	addiw	s4,s4,1
    80004b82:	0a91                	addi	s5,s5,4
    80004b84:	02c9a783          	lw	a5,44(s3)
    80004b88:	04fa5963          	bge	s4,a5,80004bda <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004b8c:	0189a583          	lw	a1,24(s3)
    80004b90:	014585bb          	addw	a1,a1,s4
    80004b94:	2585                	addiw	a1,a1,1
    80004b96:	0289a503          	lw	a0,40(s3)
    80004b9a:	fffff097          	auipc	ra,0xfffff
    80004b9e:	f1e080e7          	jalr	-226(ra) # 80003ab8 <bread>
    80004ba2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004ba4:	000aa583          	lw	a1,0(s5)
    80004ba8:	0289a503          	lw	a0,40(s3)
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	f0c080e7          	jalr	-244(ra) # 80003ab8 <bread>
    80004bb4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004bb6:	40000613          	li	a2,1024
    80004bba:	05890593          	addi	a1,s2,88
    80004bbe:	05850513          	addi	a0,a0,88
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	31e080e7          	jalr	798(ra) # 80000ee0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004bca:	8526                	mv	a0,s1
    80004bcc:	fffff097          	auipc	ra,0xfffff
    80004bd0:	fde080e7          	jalr	-34(ra) # 80003baa <bwrite>
    if(recovering == 0)
    80004bd4:	f80b1ce3          	bnez	s6,80004b6c <install_trans+0x40>
    80004bd8:	b769                	j	80004b62 <install_trans+0x36>
}
    80004bda:	70e2                	ld	ra,56(sp)
    80004bdc:	7442                	ld	s0,48(sp)
    80004bde:	74a2                	ld	s1,40(sp)
    80004be0:	7902                	ld	s2,32(sp)
    80004be2:	69e2                	ld	s3,24(sp)
    80004be4:	6a42                	ld	s4,16(sp)
    80004be6:	6aa2                	ld	s5,8(sp)
    80004be8:	6b02                	ld	s6,0(sp)
    80004bea:	6121                	addi	sp,sp,64
    80004bec:	8082                	ret
    80004bee:	8082                	ret

0000000080004bf0 <initlog>:
{
    80004bf0:	7179                	addi	sp,sp,-48
    80004bf2:	f406                	sd	ra,40(sp)
    80004bf4:	f022                	sd	s0,32(sp)
    80004bf6:	ec26                	sd	s1,24(sp)
    80004bf8:	e84a                	sd	s2,16(sp)
    80004bfa:	e44e                	sd	s3,8(sp)
    80004bfc:	1800                	addi	s0,sp,48
    80004bfe:	892a                	mv	s2,a0
    80004c00:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c02:	0023e497          	auipc	s1,0x23e
    80004c06:	82648493          	addi	s1,s1,-2010 # 80242428 <log>
    80004c0a:	00004597          	auipc	a1,0x4
    80004c0e:	bb658593          	addi	a1,a1,-1098 # 800087c0 <syscalls+0x208>
    80004c12:	8526                	mv	a0,s1
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	0e0080e7          	jalr	224(ra) # 80000cf4 <initlock>
  log.start = sb->logstart;
    80004c1c:	0149a583          	lw	a1,20(s3)
    80004c20:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c22:	0109a783          	lw	a5,16(s3)
    80004c26:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c28:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c2c:	854a                	mv	a0,s2
    80004c2e:	fffff097          	auipc	ra,0xfffff
    80004c32:	e8a080e7          	jalr	-374(ra) # 80003ab8 <bread>
  log.lh.n = lh->n;
    80004c36:	4d3c                	lw	a5,88(a0)
    80004c38:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c3a:	02f05563          	blez	a5,80004c64 <initlog+0x74>
    80004c3e:	05c50713          	addi	a4,a0,92
    80004c42:	0023e697          	auipc	a3,0x23e
    80004c46:	81668693          	addi	a3,a3,-2026 # 80242458 <log+0x30>
    80004c4a:	37fd                	addiw	a5,a5,-1
    80004c4c:	1782                	slli	a5,a5,0x20
    80004c4e:	9381                	srli	a5,a5,0x20
    80004c50:	078a                	slli	a5,a5,0x2
    80004c52:	06050613          	addi	a2,a0,96
    80004c56:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004c58:	4310                	lw	a2,0(a4)
    80004c5a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004c5c:	0711                	addi	a4,a4,4
    80004c5e:	0691                	addi	a3,a3,4
    80004c60:	fef71ce3          	bne	a4,a5,80004c58 <initlog+0x68>
  brelse(buf);
    80004c64:	fffff097          	auipc	ra,0xfffff
    80004c68:	f84080e7          	jalr	-124(ra) # 80003be8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004c6c:	4505                	li	a0,1
    80004c6e:	00000097          	auipc	ra,0x0
    80004c72:	ebe080e7          	jalr	-322(ra) # 80004b2c <install_trans>
  log.lh.n = 0;
    80004c76:	0023d797          	auipc	a5,0x23d
    80004c7a:	7c07af23          	sw	zero,2014(a5) # 80242454 <log+0x2c>
  write_head(); // clear the log
    80004c7e:	00000097          	auipc	ra,0x0
    80004c82:	e34080e7          	jalr	-460(ra) # 80004ab2 <write_head>
}
    80004c86:	70a2                	ld	ra,40(sp)
    80004c88:	7402                	ld	s0,32(sp)
    80004c8a:	64e2                	ld	s1,24(sp)
    80004c8c:	6942                	ld	s2,16(sp)
    80004c8e:	69a2                	ld	s3,8(sp)
    80004c90:	6145                	addi	sp,sp,48
    80004c92:	8082                	ret

0000000080004c94 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004c94:	1101                	addi	sp,sp,-32
    80004c96:	ec06                	sd	ra,24(sp)
    80004c98:	e822                	sd	s0,16(sp)
    80004c9a:	e426                	sd	s1,8(sp)
    80004c9c:	e04a                	sd	s2,0(sp)
    80004c9e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004ca0:	0023d517          	auipc	a0,0x23d
    80004ca4:	78850513          	addi	a0,a0,1928 # 80242428 <log>
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	0dc080e7          	jalr	220(ra) # 80000d84 <acquire>
  while(1){
    if(log.committing){
    80004cb0:	0023d497          	auipc	s1,0x23d
    80004cb4:	77848493          	addi	s1,s1,1912 # 80242428 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004cb8:	4979                	li	s2,30
    80004cba:	a039                	j	80004cc8 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004cbc:	85a6                	mv	a1,s1
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	762080e7          	jalr	1890(ra) # 80002422 <sleep>
    if(log.committing){
    80004cc8:	50dc                	lw	a5,36(s1)
    80004cca:	fbed                	bnez	a5,80004cbc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004ccc:	509c                	lw	a5,32(s1)
    80004cce:	0017871b          	addiw	a4,a5,1
    80004cd2:	0007069b          	sext.w	a3,a4
    80004cd6:	0027179b          	slliw	a5,a4,0x2
    80004cda:	9fb9                	addw	a5,a5,a4
    80004cdc:	0017979b          	slliw	a5,a5,0x1
    80004ce0:	54d8                	lw	a4,44(s1)
    80004ce2:	9fb9                	addw	a5,a5,a4
    80004ce4:	00f95963          	bge	s2,a5,80004cf6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004ce8:	85a6                	mv	a1,s1
    80004cea:	8526                	mv	a0,s1
    80004cec:	ffffd097          	auipc	ra,0xffffd
    80004cf0:	736080e7          	jalr	1846(ra) # 80002422 <sleep>
    80004cf4:	bfd1                	j	80004cc8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004cf6:	0023d517          	auipc	a0,0x23d
    80004cfa:	73250513          	addi	a0,a0,1842 # 80242428 <log>
    80004cfe:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	138080e7          	jalr	312(ra) # 80000e38 <release>
      break;
    }
  }
}
    80004d08:	60e2                	ld	ra,24(sp)
    80004d0a:	6442                	ld	s0,16(sp)
    80004d0c:	64a2                	ld	s1,8(sp)
    80004d0e:	6902                	ld	s2,0(sp)
    80004d10:	6105                	addi	sp,sp,32
    80004d12:	8082                	ret

0000000080004d14 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d14:	7139                	addi	sp,sp,-64
    80004d16:	fc06                	sd	ra,56(sp)
    80004d18:	f822                	sd	s0,48(sp)
    80004d1a:	f426                	sd	s1,40(sp)
    80004d1c:	f04a                	sd	s2,32(sp)
    80004d1e:	ec4e                	sd	s3,24(sp)
    80004d20:	e852                	sd	s4,16(sp)
    80004d22:	e456                	sd	s5,8(sp)
    80004d24:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d26:	0023d497          	auipc	s1,0x23d
    80004d2a:	70248493          	addi	s1,s1,1794 # 80242428 <log>
    80004d2e:	8526                	mv	a0,s1
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	054080e7          	jalr	84(ra) # 80000d84 <acquire>
  log.outstanding -= 1;
    80004d38:	509c                	lw	a5,32(s1)
    80004d3a:	37fd                	addiw	a5,a5,-1
    80004d3c:	0007891b          	sext.w	s2,a5
    80004d40:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004d42:	50dc                	lw	a5,36(s1)
    80004d44:	efb9                	bnez	a5,80004da2 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004d46:	06091663          	bnez	s2,80004db2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004d4a:	0023d497          	auipc	s1,0x23d
    80004d4e:	6de48493          	addi	s1,s1,1758 # 80242428 <log>
    80004d52:	4785                	li	a5,1
    80004d54:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004d56:	8526                	mv	a0,s1
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	0e0080e7          	jalr	224(ra) # 80000e38 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004d60:	54dc                	lw	a5,44(s1)
    80004d62:	06f04763          	bgtz	a5,80004dd0 <end_op+0xbc>
    acquire(&log.lock);
    80004d66:	0023d497          	auipc	s1,0x23d
    80004d6a:	6c248493          	addi	s1,s1,1730 # 80242428 <log>
    80004d6e:	8526                	mv	a0,s1
    80004d70:	ffffc097          	auipc	ra,0xffffc
    80004d74:	014080e7          	jalr	20(ra) # 80000d84 <acquire>
    log.committing = 0;
    80004d78:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004d7c:	8526                	mv	a0,s1
    80004d7e:	ffffe097          	auipc	ra,0xffffe
    80004d82:	84e080e7          	jalr	-1970(ra) # 800025cc <wakeup>
    release(&log.lock);
    80004d86:	8526                	mv	a0,s1
    80004d88:	ffffc097          	auipc	ra,0xffffc
    80004d8c:	0b0080e7          	jalr	176(ra) # 80000e38 <release>
}
    80004d90:	70e2                	ld	ra,56(sp)
    80004d92:	7442                	ld	s0,48(sp)
    80004d94:	74a2                	ld	s1,40(sp)
    80004d96:	7902                	ld	s2,32(sp)
    80004d98:	69e2                	ld	s3,24(sp)
    80004d9a:	6a42                	ld	s4,16(sp)
    80004d9c:	6aa2                	ld	s5,8(sp)
    80004d9e:	6121                	addi	sp,sp,64
    80004da0:	8082                	ret
    panic("log.committing");
    80004da2:	00004517          	auipc	a0,0x4
    80004da6:	a2650513          	addi	a0,a0,-1498 # 800087c8 <syscalls+0x210>
    80004daa:	ffffb097          	auipc	ra,0xffffb
    80004dae:	79a080e7          	jalr	1946(ra) # 80000544 <panic>
    wakeup(&log);
    80004db2:	0023d497          	auipc	s1,0x23d
    80004db6:	67648493          	addi	s1,s1,1654 # 80242428 <log>
    80004dba:	8526                	mv	a0,s1
    80004dbc:	ffffe097          	auipc	ra,0xffffe
    80004dc0:	810080e7          	jalr	-2032(ra) # 800025cc <wakeup>
  release(&log.lock);
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	072080e7          	jalr	114(ra) # 80000e38 <release>
  if(do_commit){
    80004dce:	b7c9                	j	80004d90 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004dd0:	0023da97          	auipc	s5,0x23d
    80004dd4:	688a8a93          	addi	s5,s5,1672 # 80242458 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004dd8:	0023da17          	auipc	s4,0x23d
    80004ddc:	650a0a13          	addi	s4,s4,1616 # 80242428 <log>
    80004de0:	018a2583          	lw	a1,24(s4)
    80004de4:	012585bb          	addw	a1,a1,s2
    80004de8:	2585                	addiw	a1,a1,1
    80004dea:	028a2503          	lw	a0,40(s4)
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	cca080e7          	jalr	-822(ra) # 80003ab8 <bread>
    80004df6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004df8:	000aa583          	lw	a1,0(s5)
    80004dfc:	028a2503          	lw	a0,40(s4)
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	cb8080e7          	jalr	-840(ra) # 80003ab8 <bread>
    80004e08:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e0a:	40000613          	li	a2,1024
    80004e0e:	05850593          	addi	a1,a0,88
    80004e12:	05848513          	addi	a0,s1,88
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	0ca080e7          	jalr	202(ra) # 80000ee0 <memmove>
    bwrite(to);  // write the log
    80004e1e:	8526                	mv	a0,s1
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	d8a080e7          	jalr	-630(ra) # 80003baa <bwrite>
    brelse(from);
    80004e28:	854e                	mv	a0,s3
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	dbe080e7          	jalr	-578(ra) # 80003be8 <brelse>
    brelse(to);
    80004e32:	8526                	mv	a0,s1
    80004e34:	fffff097          	auipc	ra,0xfffff
    80004e38:	db4080e7          	jalr	-588(ra) # 80003be8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e3c:	2905                	addiw	s2,s2,1
    80004e3e:	0a91                	addi	s5,s5,4
    80004e40:	02ca2783          	lw	a5,44(s4)
    80004e44:	f8f94ee3          	blt	s2,a5,80004de0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004e48:	00000097          	auipc	ra,0x0
    80004e4c:	c6a080e7          	jalr	-918(ra) # 80004ab2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004e50:	4501                	li	a0,0
    80004e52:	00000097          	auipc	ra,0x0
    80004e56:	cda080e7          	jalr	-806(ra) # 80004b2c <install_trans>
    log.lh.n = 0;
    80004e5a:	0023d797          	auipc	a5,0x23d
    80004e5e:	5e07ad23          	sw	zero,1530(a5) # 80242454 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004e62:	00000097          	auipc	ra,0x0
    80004e66:	c50080e7          	jalr	-944(ra) # 80004ab2 <write_head>
    80004e6a:	bdf5                	j	80004d66 <end_op+0x52>

0000000080004e6c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004e6c:	1101                	addi	sp,sp,-32
    80004e6e:	ec06                	sd	ra,24(sp)
    80004e70:	e822                	sd	s0,16(sp)
    80004e72:	e426                	sd	s1,8(sp)
    80004e74:	e04a                	sd	s2,0(sp)
    80004e76:	1000                	addi	s0,sp,32
    80004e78:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004e7a:	0023d917          	auipc	s2,0x23d
    80004e7e:	5ae90913          	addi	s2,s2,1454 # 80242428 <log>
    80004e82:	854a                	mv	a0,s2
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	f00080e7          	jalr	-256(ra) # 80000d84 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004e8c:	02c92603          	lw	a2,44(s2)
    80004e90:	47f5                	li	a5,29
    80004e92:	06c7c563          	blt	a5,a2,80004efc <log_write+0x90>
    80004e96:	0023d797          	auipc	a5,0x23d
    80004e9a:	5ae7a783          	lw	a5,1454(a5) # 80242444 <log+0x1c>
    80004e9e:	37fd                	addiw	a5,a5,-1
    80004ea0:	04f65e63          	bge	a2,a5,80004efc <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ea4:	0023d797          	auipc	a5,0x23d
    80004ea8:	5a47a783          	lw	a5,1444(a5) # 80242448 <log+0x20>
    80004eac:	06f05063          	blez	a5,80004f0c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004eb0:	4781                	li	a5,0
    80004eb2:	06c05563          	blez	a2,80004f1c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004eb6:	44cc                	lw	a1,12(s1)
    80004eb8:	0023d717          	auipc	a4,0x23d
    80004ebc:	5a070713          	addi	a4,a4,1440 # 80242458 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ec0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ec2:	4314                	lw	a3,0(a4)
    80004ec4:	04b68c63          	beq	a3,a1,80004f1c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004ec8:	2785                	addiw	a5,a5,1
    80004eca:	0711                	addi	a4,a4,4
    80004ecc:	fef61be3          	bne	a2,a5,80004ec2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ed0:	0621                	addi	a2,a2,8
    80004ed2:	060a                	slli	a2,a2,0x2
    80004ed4:	0023d797          	auipc	a5,0x23d
    80004ed8:	55478793          	addi	a5,a5,1364 # 80242428 <log>
    80004edc:	963e                	add	a2,a2,a5
    80004ede:	44dc                	lw	a5,12(s1)
    80004ee0:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ee2:	8526                	mv	a0,s1
    80004ee4:	fffff097          	auipc	ra,0xfffff
    80004ee8:	da2080e7          	jalr	-606(ra) # 80003c86 <bpin>
    log.lh.n++;
    80004eec:	0023d717          	auipc	a4,0x23d
    80004ef0:	53c70713          	addi	a4,a4,1340 # 80242428 <log>
    80004ef4:	575c                	lw	a5,44(a4)
    80004ef6:	2785                	addiw	a5,a5,1
    80004ef8:	d75c                	sw	a5,44(a4)
    80004efa:	a835                	j	80004f36 <log_write+0xca>
    panic("too big a transaction");
    80004efc:	00004517          	auipc	a0,0x4
    80004f00:	8dc50513          	addi	a0,a0,-1828 # 800087d8 <syscalls+0x220>
    80004f04:	ffffb097          	auipc	ra,0xffffb
    80004f08:	640080e7          	jalr	1600(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004f0c:	00004517          	auipc	a0,0x4
    80004f10:	8e450513          	addi	a0,a0,-1820 # 800087f0 <syscalls+0x238>
    80004f14:	ffffb097          	auipc	ra,0xffffb
    80004f18:	630080e7          	jalr	1584(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004f1c:	00878713          	addi	a4,a5,8
    80004f20:	00271693          	slli	a3,a4,0x2
    80004f24:	0023d717          	auipc	a4,0x23d
    80004f28:	50470713          	addi	a4,a4,1284 # 80242428 <log>
    80004f2c:	9736                	add	a4,a4,a3
    80004f2e:	44d4                	lw	a3,12(s1)
    80004f30:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f32:	faf608e3          	beq	a2,a5,80004ee2 <log_write+0x76>
  }
  release(&log.lock);
    80004f36:	0023d517          	auipc	a0,0x23d
    80004f3a:	4f250513          	addi	a0,a0,1266 # 80242428 <log>
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	efa080e7          	jalr	-262(ra) # 80000e38 <release>
}
    80004f46:	60e2                	ld	ra,24(sp)
    80004f48:	6442                	ld	s0,16(sp)
    80004f4a:	64a2                	ld	s1,8(sp)
    80004f4c:	6902                	ld	s2,0(sp)
    80004f4e:	6105                	addi	sp,sp,32
    80004f50:	8082                	ret

0000000080004f52 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004f52:	1101                	addi	sp,sp,-32
    80004f54:	ec06                	sd	ra,24(sp)
    80004f56:	e822                	sd	s0,16(sp)
    80004f58:	e426                	sd	s1,8(sp)
    80004f5a:	e04a                	sd	s2,0(sp)
    80004f5c:	1000                	addi	s0,sp,32
    80004f5e:	84aa                	mv	s1,a0
    80004f60:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004f62:	00004597          	auipc	a1,0x4
    80004f66:	8ae58593          	addi	a1,a1,-1874 # 80008810 <syscalls+0x258>
    80004f6a:	0521                	addi	a0,a0,8
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	d88080e7          	jalr	-632(ra) # 80000cf4 <initlock>
  lk->name = name;
    80004f74:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004f78:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f7c:	0204a423          	sw	zero,40(s1)
}
    80004f80:	60e2                	ld	ra,24(sp)
    80004f82:	6442                	ld	s0,16(sp)
    80004f84:	64a2                	ld	s1,8(sp)
    80004f86:	6902                	ld	s2,0(sp)
    80004f88:	6105                	addi	sp,sp,32
    80004f8a:	8082                	ret

0000000080004f8c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004f8c:	1101                	addi	sp,sp,-32
    80004f8e:	ec06                	sd	ra,24(sp)
    80004f90:	e822                	sd	s0,16(sp)
    80004f92:	e426                	sd	s1,8(sp)
    80004f94:	e04a                	sd	s2,0(sp)
    80004f96:	1000                	addi	s0,sp,32
    80004f98:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f9a:	00850913          	addi	s2,a0,8
    80004f9e:	854a                	mv	a0,s2
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	de4080e7          	jalr	-540(ra) # 80000d84 <acquire>
  while (lk->locked) {
    80004fa8:	409c                	lw	a5,0(s1)
    80004faa:	cb89                	beqz	a5,80004fbc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004fac:	85ca                	mv	a1,s2
    80004fae:	8526                	mv	a0,s1
    80004fb0:	ffffd097          	auipc	ra,0xffffd
    80004fb4:	472080e7          	jalr	1138(ra) # 80002422 <sleep>
  while (lk->locked) {
    80004fb8:	409c                	lw	a5,0(s1)
    80004fba:	fbed                	bnez	a5,80004fac <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004fbc:	4785                	li	a5,1
    80004fbe:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004fc0:	ffffd097          	auipc	ra,0xffffd
    80004fc4:	be2080e7          	jalr	-1054(ra) # 80001ba2 <myproc>
    80004fc8:	591c                	lw	a5,48(a0)
    80004fca:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004fcc:	854a                	mv	a0,s2
    80004fce:	ffffc097          	auipc	ra,0xffffc
    80004fd2:	e6a080e7          	jalr	-406(ra) # 80000e38 <release>
}
    80004fd6:	60e2                	ld	ra,24(sp)
    80004fd8:	6442                	ld	s0,16(sp)
    80004fda:	64a2                	ld	s1,8(sp)
    80004fdc:	6902                	ld	s2,0(sp)
    80004fde:	6105                	addi	sp,sp,32
    80004fe0:	8082                	ret

0000000080004fe2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004fe2:	1101                	addi	sp,sp,-32
    80004fe4:	ec06                	sd	ra,24(sp)
    80004fe6:	e822                	sd	s0,16(sp)
    80004fe8:	e426                	sd	s1,8(sp)
    80004fea:	e04a                	sd	s2,0(sp)
    80004fec:	1000                	addi	s0,sp,32
    80004fee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ff0:	00850913          	addi	s2,a0,8
    80004ff4:	854a                	mv	a0,s2
    80004ff6:	ffffc097          	auipc	ra,0xffffc
    80004ffa:	d8e080e7          	jalr	-626(ra) # 80000d84 <acquire>
  lk->locked = 0;
    80004ffe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005002:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005006:	8526                	mv	a0,s1
    80005008:	ffffd097          	auipc	ra,0xffffd
    8000500c:	5c4080e7          	jalr	1476(ra) # 800025cc <wakeup>
  release(&lk->lk);
    80005010:	854a                	mv	a0,s2
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	e26080e7          	jalr	-474(ra) # 80000e38 <release>
}
    8000501a:	60e2                	ld	ra,24(sp)
    8000501c:	6442                	ld	s0,16(sp)
    8000501e:	64a2                	ld	s1,8(sp)
    80005020:	6902                	ld	s2,0(sp)
    80005022:	6105                	addi	sp,sp,32
    80005024:	8082                	ret

0000000080005026 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005026:	7179                	addi	sp,sp,-48
    80005028:	f406                	sd	ra,40(sp)
    8000502a:	f022                	sd	s0,32(sp)
    8000502c:	ec26                	sd	s1,24(sp)
    8000502e:	e84a                	sd	s2,16(sp)
    80005030:	e44e                	sd	s3,8(sp)
    80005032:	1800                	addi	s0,sp,48
    80005034:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005036:	00850913          	addi	s2,a0,8
    8000503a:	854a                	mv	a0,s2
    8000503c:	ffffc097          	auipc	ra,0xffffc
    80005040:	d48080e7          	jalr	-696(ra) # 80000d84 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005044:	409c                	lw	a5,0(s1)
    80005046:	ef99                	bnez	a5,80005064 <holdingsleep+0x3e>
    80005048:	4481                	li	s1,0
  release(&lk->lk);
    8000504a:	854a                	mv	a0,s2
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	dec080e7          	jalr	-532(ra) # 80000e38 <release>
  return r;
}
    80005054:	8526                	mv	a0,s1
    80005056:	70a2                	ld	ra,40(sp)
    80005058:	7402                	ld	s0,32(sp)
    8000505a:	64e2                	ld	s1,24(sp)
    8000505c:	6942                	ld	s2,16(sp)
    8000505e:	69a2                	ld	s3,8(sp)
    80005060:	6145                	addi	sp,sp,48
    80005062:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005064:	0284a983          	lw	s3,40(s1)
    80005068:	ffffd097          	auipc	ra,0xffffd
    8000506c:	b3a080e7          	jalr	-1222(ra) # 80001ba2 <myproc>
    80005070:	5904                	lw	s1,48(a0)
    80005072:	413484b3          	sub	s1,s1,s3
    80005076:	0014b493          	seqz	s1,s1
    8000507a:	bfc1                	j	8000504a <holdingsleep+0x24>

000000008000507c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000507c:	1141                	addi	sp,sp,-16
    8000507e:	e406                	sd	ra,8(sp)
    80005080:	e022                	sd	s0,0(sp)
    80005082:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005084:	00003597          	auipc	a1,0x3
    80005088:	79c58593          	addi	a1,a1,1948 # 80008820 <syscalls+0x268>
    8000508c:	0023d517          	auipc	a0,0x23d
    80005090:	4e450513          	addi	a0,a0,1252 # 80242570 <ftable>
    80005094:	ffffc097          	auipc	ra,0xffffc
    80005098:	c60080e7          	jalr	-928(ra) # 80000cf4 <initlock>
}
    8000509c:	60a2                	ld	ra,8(sp)
    8000509e:	6402                	ld	s0,0(sp)
    800050a0:	0141                	addi	sp,sp,16
    800050a2:	8082                	ret

00000000800050a4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800050a4:	1101                	addi	sp,sp,-32
    800050a6:	ec06                	sd	ra,24(sp)
    800050a8:	e822                	sd	s0,16(sp)
    800050aa:	e426                	sd	s1,8(sp)
    800050ac:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800050ae:	0023d517          	auipc	a0,0x23d
    800050b2:	4c250513          	addi	a0,a0,1218 # 80242570 <ftable>
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	cce080e7          	jalr	-818(ra) # 80000d84 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050be:	0023d497          	auipc	s1,0x23d
    800050c2:	4ca48493          	addi	s1,s1,1226 # 80242588 <ftable+0x18>
    800050c6:	0023e717          	auipc	a4,0x23e
    800050ca:	46270713          	addi	a4,a4,1122 # 80243528 <disk>
    if(f->ref == 0){
    800050ce:	40dc                	lw	a5,4(s1)
    800050d0:	cf99                	beqz	a5,800050ee <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800050d2:	02848493          	addi	s1,s1,40
    800050d6:	fee49ce3          	bne	s1,a4,800050ce <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800050da:	0023d517          	auipc	a0,0x23d
    800050de:	49650513          	addi	a0,a0,1174 # 80242570 <ftable>
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	d56080e7          	jalr	-682(ra) # 80000e38 <release>
  return 0;
    800050ea:	4481                	li	s1,0
    800050ec:	a819                	j	80005102 <filealloc+0x5e>
      f->ref = 1;
    800050ee:	4785                	li	a5,1
    800050f0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800050f2:	0023d517          	auipc	a0,0x23d
    800050f6:	47e50513          	addi	a0,a0,1150 # 80242570 <ftable>
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	d3e080e7          	jalr	-706(ra) # 80000e38 <release>
}
    80005102:	8526                	mv	a0,s1
    80005104:	60e2                	ld	ra,24(sp)
    80005106:	6442                	ld	s0,16(sp)
    80005108:	64a2                	ld	s1,8(sp)
    8000510a:	6105                	addi	sp,sp,32
    8000510c:	8082                	ret

000000008000510e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000510e:	1101                	addi	sp,sp,-32
    80005110:	ec06                	sd	ra,24(sp)
    80005112:	e822                	sd	s0,16(sp)
    80005114:	e426                	sd	s1,8(sp)
    80005116:	1000                	addi	s0,sp,32
    80005118:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000511a:	0023d517          	auipc	a0,0x23d
    8000511e:	45650513          	addi	a0,a0,1110 # 80242570 <ftable>
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	c62080e7          	jalr	-926(ra) # 80000d84 <acquire>
  if(f->ref < 1)
    8000512a:	40dc                	lw	a5,4(s1)
    8000512c:	02f05263          	blez	a5,80005150 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005130:	2785                	addiw	a5,a5,1
    80005132:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005134:	0023d517          	auipc	a0,0x23d
    80005138:	43c50513          	addi	a0,a0,1084 # 80242570 <ftable>
    8000513c:	ffffc097          	auipc	ra,0xffffc
    80005140:	cfc080e7          	jalr	-772(ra) # 80000e38 <release>
  return f;
}
    80005144:	8526                	mv	a0,s1
    80005146:	60e2                	ld	ra,24(sp)
    80005148:	6442                	ld	s0,16(sp)
    8000514a:	64a2                	ld	s1,8(sp)
    8000514c:	6105                	addi	sp,sp,32
    8000514e:	8082                	ret
    panic("filedup");
    80005150:	00003517          	auipc	a0,0x3
    80005154:	6d850513          	addi	a0,a0,1752 # 80008828 <syscalls+0x270>
    80005158:	ffffb097          	auipc	ra,0xffffb
    8000515c:	3ec080e7          	jalr	1004(ra) # 80000544 <panic>

0000000080005160 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005160:	7139                	addi	sp,sp,-64
    80005162:	fc06                	sd	ra,56(sp)
    80005164:	f822                	sd	s0,48(sp)
    80005166:	f426                	sd	s1,40(sp)
    80005168:	f04a                	sd	s2,32(sp)
    8000516a:	ec4e                	sd	s3,24(sp)
    8000516c:	e852                	sd	s4,16(sp)
    8000516e:	e456                	sd	s5,8(sp)
    80005170:	0080                	addi	s0,sp,64
    80005172:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005174:	0023d517          	auipc	a0,0x23d
    80005178:	3fc50513          	addi	a0,a0,1020 # 80242570 <ftable>
    8000517c:	ffffc097          	auipc	ra,0xffffc
    80005180:	c08080e7          	jalr	-1016(ra) # 80000d84 <acquire>
  if(f->ref < 1)
    80005184:	40dc                	lw	a5,4(s1)
    80005186:	06f05163          	blez	a5,800051e8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000518a:	37fd                	addiw	a5,a5,-1
    8000518c:	0007871b          	sext.w	a4,a5
    80005190:	c0dc                	sw	a5,4(s1)
    80005192:	06e04363          	bgtz	a4,800051f8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005196:	0004a903          	lw	s2,0(s1)
    8000519a:	0094ca83          	lbu	s5,9(s1)
    8000519e:	0104ba03          	ld	s4,16(s1)
    800051a2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800051a6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800051aa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800051ae:	0023d517          	auipc	a0,0x23d
    800051b2:	3c250513          	addi	a0,a0,962 # 80242570 <ftable>
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	c82080e7          	jalr	-894(ra) # 80000e38 <release>

  if(ff.type == FD_PIPE){
    800051be:	4785                	li	a5,1
    800051c0:	04f90d63          	beq	s2,a5,8000521a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800051c4:	3979                	addiw	s2,s2,-2
    800051c6:	4785                	li	a5,1
    800051c8:	0527e063          	bltu	a5,s2,80005208 <fileclose+0xa8>
    begin_op();
    800051cc:	00000097          	auipc	ra,0x0
    800051d0:	ac8080e7          	jalr	-1336(ra) # 80004c94 <begin_op>
    iput(ff.ip);
    800051d4:	854e                	mv	a0,s3
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	2b6080e7          	jalr	694(ra) # 8000448c <iput>
    end_op();
    800051de:	00000097          	auipc	ra,0x0
    800051e2:	b36080e7          	jalr	-1226(ra) # 80004d14 <end_op>
    800051e6:	a00d                	j	80005208 <fileclose+0xa8>
    panic("fileclose");
    800051e8:	00003517          	auipc	a0,0x3
    800051ec:	64850513          	addi	a0,a0,1608 # 80008830 <syscalls+0x278>
    800051f0:	ffffb097          	auipc	ra,0xffffb
    800051f4:	354080e7          	jalr	852(ra) # 80000544 <panic>
    release(&ftable.lock);
    800051f8:	0023d517          	auipc	a0,0x23d
    800051fc:	37850513          	addi	a0,a0,888 # 80242570 <ftable>
    80005200:	ffffc097          	auipc	ra,0xffffc
    80005204:	c38080e7          	jalr	-968(ra) # 80000e38 <release>
  }
}
    80005208:	70e2                	ld	ra,56(sp)
    8000520a:	7442                	ld	s0,48(sp)
    8000520c:	74a2                	ld	s1,40(sp)
    8000520e:	7902                	ld	s2,32(sp)
    80005210:	69e2                	ld	s3,24(sp)
    80005212:	6a42                	ld	s4,16(sp)
    80005214:	6aa2                	ld	s5,8(sp)
    80005216:	6121                	addi	sp,sp,64
    80005218:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000521a:	85d6                	mv	a1,s5
    8000521c:	8552                	mv	a0,s4
    8000521e:	00000097          	auipc	ra,0x0
    80005222:	34c080e7          	jalr	844(ra) # 8000556a <pipeclose>
    80005226:	b7cd                	j	80005208 <fileclose+0xa8>

0000000080005228 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005228:	715d                	addi	sp,sp,-80
    8000522a:	e486                	sd	ra,72(sp)
    8000522c:	e0a2                	sd	s0,64(sp)
    8000522e:	fc26                	sd	s1,56(sp)
    80005230:	f84a                	sd	s2,48(sp)
    80005232:	f44e                	sd	s3,40(sp)
    80005234:	0880                	addi	s0,sp,80
    80005236:	84aa                	mv	s1,a0
    80005238:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000523a:	ffffd097          	auipc	ra,0xffffd
    8000523e:	968080e7          	jalr	-1688(ra) # 80001ba2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005242:	409c                	lw	a5,0(s1)
    80005244:	37f9                	addiw	a5,a5,-2
    80005246:	4705                	li	a4,1
    80005248:	04f76763          	bltu	a4,a5,80005296 <filestat+0x6e>
    8000524c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000524e:	6c88                	ld	a0,24(s1)
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	082080e7          	jalr	130(ra) # 800042d2 <ilock>
    stati(f->ip, &st);
    80005258:	fb840593          	addi	a1,s0,-72
    8000525c:	6c88                	ld	a0,24(s1)
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	2fe080e7          	jalr	766(ra) # 8000455c <stati>
    iunlock(f->ip);
    80005266:	6c88                	ld	a0,24(s1)
    80005268:	fffff097          	auipc	ra,0xfffff
    8000526c:	12c080e7          	jalr	300(ra) # 80004394 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005270:	46e1                	li	a3,24
    80005272:	fb840613          	addi	a2,s0,-72
    80005276:	85ce                	mv	a1,s3
    80005278:	08893503          	ld	a0,136(s2)
    8000527c:	ffffc097          	auipc	ra,0xffffc
    80005280:	5ac080e7          	jalr	1452(ra) # 80001828 <copyout>
    80005284:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005288:	60a6                	ld	ra,72(sp)
    8000528a:	6406                	ld	s0,64(sp)
    8000528c:	74e2                	ld	s1,56(sp)
    8000528e:	7942                	ld	s2,48(sp)
    80005290:	79a2                	ld	s3,40(sp)
    80005292:	6161                	addi	sp,sp,80
    80005294:	8082                	ret
  return -1;
    80005296:	557d                	li	a0,-1
    80005298:	bfc5                	j	80005288 <filestat+0x60>

000000008000529a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000529a:	7179                	addi	sp,sp,-48
    8000529c:	f406                	sd	ra,40(sp)
    8000529e:	f022                	sd	s0,32(sp)
    800052a0:	ec26                	sd	s1,24(sp)
    800052a2:	e84a                	sd	s2,16(sp)
    800052a4:	e44e                	sd	s3,8(sp)
    800052a6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800052a8:	00854783          	lbu	a5,8(a0)
    800052ac:	c3d5                	beqz	a5,80005350 <fileread+0xb6>
    800052ae:	84aa                	mv	s1,a0
    800052b0:	89ae                	mv	s3,a1
    800052b2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800052b4:	411c                	lw	a5,0(a0)
    800052b6:	4705                	li	a4,1
    800052b8:	04e78963          	beq	a5,a4,8000530a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052bc:	470d                	li	a4,3
    800052be:	04e78d63          	beq	a5,a4,80005318 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800052c2:	4709                	li	a4,2
    800052c4:	06e79e63          	bne	a5,a4,80005340 <fileread+0xa6>
    ilock(f->ip);
    800052c8:	6d08                	ld	a0,24(a0)
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	008080e7          	jalr	8(ra) # 800042d2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800052d2:	874a                	mv	a4,s2
    800052d4:	5094                	lw	a3,32(s1)
    800052d6:	864e                	mv	a2,s3
    800052d8:	4585                	li	a1,1
    800052da:	6c88                	ld	a0,24(s1)
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	2aa080e7          	jalr	682(ra) # 80004586 <readi>
    800052e4:	892a                	mv	s2,a0
    800052e6:	00a05563          	blez	a0,800052f0 <fileread+0x56>
      f->off += r;
    800052ea:	509c                	lw	a5,32(s1)
    800052ec:	9fa9                	addw	a5,a5,a0
    800052ee:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800052f0:	6c88                	ld	a0,24(s1)
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	0a2080e7          	jalr	162(ra) # 80004394 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800052fa:	854a                	mv	a0,s2
    800052fc:	70a2                	ld	ra,40(sp)
    800052fe:	7402                	ld	s0,32(sp)
    80005300:	64e2                	ld	s1,24(sp)
    80005302:	6942                	ld	s2,16(sp)
    80005304:	69a2                	ld	s3,8(sp)
    80005306:	6145                	addi	sp,sp,48
    80005308:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000530a:	6908                	ld	a0,16(a0)
    8000530c:	00000097          	auipc	ra,0x0
    80005310:	3ce080e7          	jalr	974(ra) # 800056da <piperead>
    80005314:	892a                	mv	s2,a0
    80005316:	b7d5                	j	800052fa <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005318:	02451783          	lh	a5,36(a0)
    8000531c:	03079693          	slli	a3,a5,0x30
    80005320:	92c1                	srli	a3,a3,0x30
    80005322:	4725                	li	a4,9
    80005324:	02d76863          	bltu	a4,a3,80005354 <fileread+0xba>
    80005328:	0792                	slli	a5,a5,0x4
    8000532a:	0023d717          	auipc	a4,0x23d
    8000532e:	1a670713          	addi	a4,a4,422 # 802424d0 <devsw>
    80005332:	97ba                	add	a5,a5,a4
    80005334:	639c                	ld	a5,0(a5)
    80005336:	c38d                	beqz	a5,80005358 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005338:	4505                	li	a0,1
    8000533a:	9782                	jalr	a5
    8000533c:	892a                	mv	s2,a0
    8000533e:	bf75                	j	800052fa <fileread+0x60>
    panic("fileread");
    80005340:	00003517          	auipc	a0,0x3
    80005344:	50050513          	addi	a0,a0,1280 # 80008840 <syscalls+0x288>
    80005348:	ffffb097          	auipc	ra,0xffffb
    8000534c:	1fc080e7          	jalr	508(ra) # 80000544 <panic>
    return -1;
    80005350:	597d                	li	s2,-1
    80005352:	b765                	j	800052fa <fileread+0x60>
      return -1;
    80005354:	597d                	li	s2,-1
    80005356:	b755                	j	800052fa <fileread+0x60>
    80005358:	597d                	li	s2,-1
    8000535a:	b745                	j	800052fa <fileread+0x60>

000000008000535c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000535c:	715d                	addi	sp,sp,-80
    8000535e:	e486                	sd	ra,72(sp)
    80005360:	e0a2                	sd	s0,64(sp)
    80005362:	fc26                	sd	s1,56(sp)
    80005364:	f84a                	sd	s2,48(sp)
    80005366:	f44e                	sd	s3,40(sp)
    80005368:	f052                	sd	s4,32(sp)
    8000536a:	ec56                	sd	s5,24(sp)
    8000536c:	e85a                	sd	s6,16(sp)
    8000536e:	e45e                	sd	s7,8(sp)
    80005370:	e062                	sd	s8,0(sp)
    80005372:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005374:	00954783          	lbu	a5,9(a0)
    80005378:	10078663          	beqz	a5,80005484 <filewrite+0x128>
    8000537c:	892a                	mv	s2,a0
    8000537e:	8aae                	mv	s5,a1
    80005380:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005382:	411c                	lw	a5,0(a0)
    80005384:	4705                	li	a4,1
    80005386:	02e78263          	beq	a5,a4,800053aa <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000538a:	470d                	li	a4,3
    8000538c:	02e78663          	beq	a5,a4,800053b8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005390:	4709                	li	a4,2
    80005392:	0ee79163          	bne	a5,a4,80005474 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005396:	0ac05d63          	blez	a2,80005450 <filewrite+0xf4>
    int i = 0;
    8000539a:	4981                	li	s3,0
    8000539c:	6b05                	lui	s6,0x1
    8000539e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800053a2:	6b85                	lui	s7,0x1
    800053a4:	c00b8b9b          	addiw	s7,s7,-1024
    800053a8:	a861                	j	80005440 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800053aa:	6908                	ld	a0,16(a0)
    800053ac:	00000097          	auipc	ra,0x0
    800053b0:	22e080e7          	jalr	558(ra) # 800055da <pipewrite>
    800053b4:	8a2a                	mv	s4,a0
    800053b6:	a045                	j	80005456 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800053b8:	02451783          	lh	a5,36(a0)
    800053bc:	03079693          	slli	a3,a5,0x30
    800053c0:	92c1                	srli	a3,a3,0x30
    800053c2:	4725                	li	a4,9
    800053c4:	0cd76263          	bltu	a4,a3,80005488 <filewrite+0x12c>
    800053c8:	0792                	slli	a5,a5,0x4
    800053ca:	0023d717          	auipc	a4,0x23d
    800053ce:	10670713          	addi	a4,a4,262 # 802424d0 <devsw>
    800053d2:	97ba                	add	a5,a5,a4
    800053d4:	679c                	ld	a5,8(a5)
    800053d6:	cbdd                	beqz	a5,8000548c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800053d8:	4505                	li	a0,1
    800053da:	9782                	jalr	a5
    800053dc:	8a2a                	mv	s4,a0
    800053de:	a8a5                	j	80005456 <filewrite+0xfa>
    800053e0:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800053e4:	00000097          	auipc	ra,0x0
    800053e8:	8b0080e7          	jalr	-1872(ra) # 80004c94 <begin_op>
      ilock(f->ip);
    800053ec:	01893503          	ld	a0,24(s2)
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	ee2080e7          	jalr	-286(ra) # 800042d2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800053f8:	8762                	mv	a4,s8
    800053fa:	02092683          	lw	a3,32(s2)
    800053fe:	01598633          	add	a2,s3,s5
    80005402:	4585                	li	a1,1
    80005404:	01893503          	ld	a0,24(s2)
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	276080e7          	jalr	630(ra) # 8000467e <writei>
    80005410:	84aa                	mv	s1,a0
    80005412:	00a05763          	blez	a0,80005420 <filewrite+0xc4>
        f->off += r;
    80005416:	02092783          	lw	a5,32(s2)
    8000541a:	9fa9                	addw	a5,a5,a0
    8000541c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005420:	01893503          	ld	a0,24(s2)
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	f70080e7          	jalr	-144(ra) # 80004394 <iunlock>
      end_op();
    8000542c:	00000097          	auipc	ra,0x0
    80005430:	8e8080e7          	jalr	-1816(ra) # 80004d14 <end_op>

      if(r != n1){
    80005434:	009c1f63          	bne	s8,s1,80005452 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005438:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000543c:	0149db63          	bge	s3,s4,80005452 <filewrite+0xf6>
      int n1 = n - i;
    80005440:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005444:	84be                	mv	s1,a5
    80005446:	2781                	sext.w	a5,a5
    80005448:	f8fb5ce3          	bge	s6,a5,800053e0 <filewrite+0x84>
    8000544c:	84de                	mv	s1,s7
    8000544e:	bf49                	j	800053e0 <filewrite+0x84>
    int i = 0;
    80005450:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005452:	013a1f63          	bne	s4,s3,80005470 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005456:	8552                	mv	a0,s4
    80005458:	60a6                	ld	ra,72(sp)
    8000545a:	6406                	ld	s0,64(sp)
    8000545c:	74e2                	ld	s1,56(sp)
    8000545e:	7942                	ld	s2,48(sp)
    80005460:	79a2                	ld	s3,40(sp)
    80005462:	7a02                	ld	s4,32(sp)
    80005464:	6ae2                	ld	s5,24(sp)
    80005466:	6b42                	ld	s6,16(sp)
    80005468:	6ba2                	ld	s7,8(sp)
    8000546a:	6c02                	ld	s8,0(sp)
    8000546c:	6161                	addi	sp,sp,80
    8000546e:	8082                	ret
    ret = (i == n ? n : -1);
    80005470:	5a7d                	li	s4,-1
    80005472:	b7d5                	j	80005456 <filewrite+0xfa>
    panic("filewrite");
    80005474:	00003517          	auipc	a0,0x3
    80005478:	3dc50513          	addi	a0,a0,988 # 80008850 <syscalls+0x298>
    8000547c:	ffffb097          	auipc	ra,0xffffb
    80005480:	0c8080e7          	jalr	200(ra) # 80000544 <panic>
    return -1;
    80005484:	5a7d                	li	s4,-1
    80005486:	bfc1                	j	80005456 <filewrite+0xfa>
      return -1;
    80005488:	5a7d                	li	s4,-1
    8000548a:	b7f1                	j	80005456 <filewrite+0xfa>
    8000548c:	5a7d                	li	s4,-1
    8000548e:	b7e1                	j	80005456 <filewrite+0xfa>

0000000080005490 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005490:	7179                	addi	sp,sp,-48
    80005492:	f406                	sd	ra,40(sp)
    80005494:	f022                	sd	s0,32(sp)
    80005496:	ec26                	sd	s1,24(sp)
    80005498:	e84a                	sd	s2,16(sp)
    8000549a:	e44e                	sd	s3,8(sp)
    8000549c:	e052                	sd	s4,0(sp)
    8000549e:	1800                	addi	s0,sp,48
    800054a0:	84aa                	mv	s1,a0
    800054a2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800054a4:	0005b023          	sd	zero,0(a1)
    800054a8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800054ac:	00000097          	auipc	ra,0x0
    800054b0:	bf8080e7          	jalr	-1032(ra) # 800050a4 <filealloc>
    800054b4:	e088                	sd	a0,0(s1)
    800054b6:	c551                	beqz	a0,80005542 <pipealloc+0xb2>
    800054b8:	00000097          	auipc	ra,0x0
    800054bc:	bec080e7          	jalr	-1044(ra) # 800050a4 <filealloc>
    800054c0:	00aa3023          	sd	a0,0(s4)
    800054c4:	c92d                	beqz	a0,80005536 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800054c6:	ffffb097          	auipc	ra,0xffffb
    800054ca:	7ba080e7          	jalr	1978(ra) # 80000c80 <kalloc>
    800054ce:	892a                	mv	s2,a0
    800054d0:	c125                	beqz	a0,80005530 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800054d2:	4985                	li	s3,1
    800054d4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800054d8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800054dc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800054e0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800054e4:	00003597          	auipc	a1,0x3
    800054e8:	fe458593          	addi	a1,a1,-28 # 800084c8 <states.1783+0x1e0>
    800054ec:	ffffc097          	auipc	ra,0xffffc
    800054f0:	808080e7          	jalr	-2040(ra) # 80000cf4 <initlock>
  (*f0)->type = FD_PIPE;
    800054f4:	609c                	ld	a5,0(s1)
    800054f6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800054fa:	609c                	ld	a5,0(s1)
    800054fc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005500:	609c                	ld	a5,0(s1)
    80005502:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005506:	609c                	ld	a5,0(s1)
    80005508:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000550c:	000a3783          	ld	a5,0(s4)
    80005510:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005514:	000a3783          	ld	a5,0(s4)
    80005518:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000551c:	000a3783          	ld	a5,0(s4)
    80005520:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005524:	000a3783          	ld	a5,0(s4)
    80005528:	0127b823          	sd	s2,16(a5)
  return 0;
    8000552c:	4501                	li	a0,0
    8000552e:	a025                	j	80005556 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005530:	6088                	ld	a0,0(s1)
    80005532:	e501                	bnez	a0,8000553a <pipealloc+0xaa>
    80005534:	a039                	j	80005542 <pipealloc+0xb2>
    80005536:	6088                	ld	a0,0(s1)
    80005538:	c51d                	beqz	a0,80005566 <pipealloc+0xd6>
    fileclose(*f0);
    8000553a:	00000097          	auipc	ra,0x0
    8000553e:	c26080e7          	jalr	-986(ra) # 80005160 <fileclose>
  if(*f1)
    80005542:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005546:	557d                	li	a0,-1
  if(*f1)
    80005548:	c799                	beqz	a5,80005556 <pipealloc+0xc6>
    fileclose(*f1);
    8000554a:	853e                	mv	a0,a5
    8000554c:	00000097          	auipc	ra,0x0
    80005550:	c14080e7          	jalr	-1004(ra) # 80005160 <fileclose>
  return -1;
    80005554:	557d                	li	a0,-1
}
    80005556:	70a2                	ld	ra,40(sp)
    80005558:	7402                	ld	s0,32(sp)
    8000555a:	64e2                	ld	s1,24(sp)
    8000555c:	6942                	ld	s2,16(sp)
    8000555e:	69a2                	ld	s3,8(sp)
    80005560:	6a02                	ld	s4,0(sp)
    80005562:	6145                	addi	sp,sp,48
    80005564:	8082                	ret
  return -1;
    80005566:	557d                	li	a0,-1
    80005568:	b7fd                	j	80005556 <pipealloc+0xc6>

000000008000556a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000556a:	1101                	addi	sp,sp,-32
    8000556c:	ec06                	sd	ra,24(sp)
    8000556e:	e822                	sd	s0,16(sp)
    80005570:	e426                	sd	s1,8(sp)
    80005572:	e04a                	sd	s2,0(sp)
    80005574:	1000                	addi	s0,sp,32
    80005576:	84aa                	mv	s1,a0
    80005578:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000557a:	ffffc097          	auipc	ra,0xffffc
    8000557e:	80a080e7          	jalr	-2038(ra) # 80000d84 <acquire>
  if(writable){
    80005582:	02090d63          	beqz	s2,800055bc <pipeclose+0x52>
    pi->writeopen = 0;
    80005586:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000558a:	21848513          	addi	a0,s1,536
    8000558e:	ffffd097          	auipc	ra,0xffffd
    80005592:	03e080e7          	jalr	62(ra) # 800025cc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005596:	2204b783          	ld	a5,544(s1)
    8000559a:	eb95                	bnez	a5,800055ce <pipeclose+0x64>
    release(&pi->lock);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffc097          	auipc	ra,0xffffc
    800055a2:	89a080e7          	jalr	-1894(ra) # 80000e38 <release>
    kfree((char*)pi);
    800055a6:	8526                	mv	a0,s1
    800055a8:	ffffb097          	auipc	ra,0xffffb
    800055ac:	594080e7          	jalr	1428(ra) # 80000b3c <kfree>
  } else
    release(&pi->lock);
}
    800055b0:	60e2                	ld	ra,24(sp)
    800055b2:	6442                	ld	s0,16(sp)
    800055b4:	64a2                	ld	s1,8(sp)
    800055b6:	6902                	ld	s2,0(sp)
    800055b8:	6105                	addi	sp,sp,32
    800055ba:	8082                	ret
    pi->readopen = 0;
    800055bc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800055c0:	21c48513          	addi	a0,s1,540
    800055c4:	ffffd097          	auipc	ra,0xffffd
    800055c8:	008080e7          	jalr	8(ra) # 800025cc <wakeup>
    800055cc:	b7e9                	j	80005596 <pipeclose+0x2c>
    release(&pi->lock);
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffc097          	auipc	ra,0xffffc
    800055d4:	868080e7          	jalr	-1944(ra) # 80000e38 <release>
}
    800055d8:	bfe1                	j	800055b0 <pipeclose+0x46>

00000000800055da <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800055da:	7159                	addi	sp,sp,-112
    800055dc:	f486                	sd	ra,104(sp)
    800055de:	f0a2                	sd	s0,96(sp)
    800055e0:	eca6                	sd	s1,88(sp)
    800055e2:	e8ca                	sd	s2,80(sp)
    800055e4:	e4ce                	sd	s3,72(sp)
    800055e6:	e0d2                	sd	s4,64(sp)
    800055e8:	fc56                	sd	s5,56(sp)
    800055ea:	f85a                	sd	s6,48(sp)
    800055ec:	f45e                	sd	s7,40(sp)
    800055ee:	f062                	sd	s8,32(sp)
    800055f0:	ec66                	sd	s9,24(sp)
    800055f2:	1880                	addi	s0,sp,112
    800055f4:	84aa                	mv	s1,a0
    800055f6:	8aae                	mv	s5,a1
    800055f8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800055fa:	ffffc097          	auipc	ra,0xffffc
    800055fe:	5a8080e7          	jalr	1448(ra) # 80001ba2 <myproc>
    80005602:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005604:	8526                	mv	a0,s1
    80005606:	ffffb097          	auipc	ra,0xffffb
    8000560a:	77e080e7          	jalr	1918(ra) # 80000d84 <acquire>
  while(i < n){
    8000560e:	0d405463          	blez	s4,800056d6 <pipewrite+0xfc>
    80005612:	8ba6                	mv	s7,s1
  int i = 0;
    80005614:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005616:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005618:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000561c:	21c48c13          	addi	s8,s1,540
    80005620:	a08d                	j	80005682 <pipewrite+0xa8>
      release(&pi->lock);
    80005622:	8526                	mv	a0,s1
    80005624:	ffffc097          	auipc	ra,0xffffc
    80005628:	814080e7          	jalr	-2028(ra) # 80000e38 <release>
      return -1;
    8000562c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000562e:	854a                	mv	a0,s2
    80005630:	70a6                	ld	ra,104(sp)
    80005632:	7406                	ld	s0,96(sp)
    80005634:	64e6                	ld	s1,88(sp)
    80005636:	6946                	ld	s2,80(sp)
    80005638:	69a6                	ld	s3,72(sp)
    8000563a:	6a06                	ld	s4,64(sp)
    8000563c:	7ae2                	ld	s5,56(sp)
    8000563e:	7b42                	ld	s6,48(sp)
    80005640:	7ba2                	ld	s7,40(sp)
    80005642:	7c02                	ld	s8,32(sp)
    80005644:	6ce2                	ld	s9,24(sp)
    80005646:	6165                	addi	sp,sp,112
    80005648:	8082                	ret
      wakeup(&pi->nread);
    8000564a:	8566                	mv	a0,s9
    8000564c:	ffffd097          	auipc	ra,0xffffd
    80005650:	f80080e7          	jalr	-128(ra) # 800025cc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005654:	85de                	mv	a1,s7
    80005656:	8562                	mv	a0,s8
    80005658:	ffffd097          	auipc	ra,0xffffd
    8000565c:	dca080e7          	jalr	-566(ra) # 80002422 <sleep>
    80005660:	a839                	j	8000567e <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005662:	21c4a783          	lw	a5,540(s1)
    80005666:	0017871b          	addiw	a4,a5,1
    8000566a:	20e4ae23          	sw	a4,540(s1)
    8000566e:	1ff7f793          	andi	a5,a5,511
    80005672:	97a6                	add	a5,a5,s1
    80005674:	f9f44703          	lbu	a4,-97(s0)
    80005678:	00e78c23          	sb	a4,24(a5)
      i++;
    8000567c:	2905                	addiw	s2,s2,1
  while(i < n){
    8000567e:	05495063          	bge	s2,s4,800056be <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80005682:	2204a783          	lw	a5,544(s1)
    80005686:	dfd1                	beqz	a5,80005622 <pipewrite+0x48>
    80005688:	854e                	mv	a0,s3
    8000568a:	ffffd097          	auipc	ra,0xffffd
    8000568e:	1ca080e7          	jalr	458(ra) # 80002854 <killed>
    80005692:	f941                	bnez	a0,80005622 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005694:	2184a783          	lw	a5,536(s1)
    80005698:	21c4a703          	lw	a4,540(s1)
    8000569c:	2007879b          	addiw	a5,a5,512
    800056a0:	faf705e3          	beq	a4,a5,8000564a <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800056a4:	4685                	li	a3,1
    800056a6:	01590633          	add	a2,s2,s5
    800056aa:	f9f40593          	addi	a1,s0,-97
    800056ae:	0889b503          	ld	a0,136(s3)
    800056b2:	ffffc097          	auipc	ra,0xffffc
    800056b6:	23a080e7          	jalr	570(ra) # 800018ec <copyin>
    800056ba:	fb6514e3          	bne	a0,s6,80005662 <pipewrite+0x88>
  wakeup(&pi->nread);
    800056be:	21848513          	addi	a0,s1,536
    800056c2:	ffffd097          	auipc	ra,0xffffd
    800056c6:	f0a080e7          	jalr	-246(ra) # 800025cc <wakeup>
  release(&pi->lock);
    800056ca:	8526                	mv	a0,s1
    800056cc:	ffffb097          	auipc	ra,0xffffb
    800056d0:	76c080e7          	jalr	1900(ra) # 80000e38 <release>
  return i;
    800056d4:	bfa9                	j	8000562e <pipewrite+0x54>
  int i = 0;
    800056d6:	4901                	li	s2,0
    800056d8:	b7dd                	j	800056be <pipewrite+0xe4>

00000000800056da <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800056da:	715d                	addi	sp,sp,-80
    800056dc:	e486                	sd	ra,72(sp)
    800056de:	e0a2                	sd	s0,64(sp)
    800056e0:	fc26                	sd	s1,56(sp)
    800056e2:	f84a                	sd	s2,48(sp)
    800056e4:	f44e                	sd	s3,40(sp)
    800056e6:	f052                	sd	s4,32(sp)
    800056e8:	ec56                	sd	s5,24(sp)
    800056ea:	e85a                	sd	s6,16(sp)
    800056ec:	0880                	addi	s0,sp,80
    800056ee:	84aa                	mv	s1,a0
    800056f0:	892e                	mv	s2,a1
    800056f2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800056f4:	ffffc097          	auipc	ra,0xffffc
    800056f8:	4ae080e7          	jalr	1198(ra) # 80001ba2 <myproc>
    800056fc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800056fe:	8b26                	mv	s6,s1
    80005700:	8526                	mv	a0,s1
    80005702:	ffffb097          	auipc	ra,0xffffb
    80005706:	682080e7          	jalr	1666(ra) # 80000d84 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000570a:	2184a703          	lw	a4,536(s1)
    8000570e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005712:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005716:	02f71763          	bne	a4,a5,80005744 <piperead+0x6a>
    8000571a:	2244a783          	lw	a5,548(s1)
    8000571e:	c39d                	beqz	a5,80005744 <piperead+0x6a>
    if(killed(pr)){
    80005720:	8552                	mv	a0,s4
    80005722:	ffffd097          	auipc	ra,0xffffd
    80005726:	132080e7          	jalr	306(ra) # 80002854 <killed>
    8000572a:	e941                	bnez	a0,800057ba <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000572c:	85da                	mv	a1,s6
    8000572e:	854e                	mv	a0,s3
    80005730:	ffffd097          	auipc	ra,0xffffd
    80005734:	cf2080e7          	jalr	-782(ra) # 80002422 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005738:	2184a703          	lw	a4,536(s1)
    8000573c:	21c4a783          	lw	a5,540(s1)
    80005740:	fcf70de3          	beq	a4,a5,8000571a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005744:	09505263          	blez	s5,800057c8 <piperead+0xee>
    80005748:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000574a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000574c:	2184a783          	lw	a5,536(s1)
    80005750:	21c4a703          	lw	a4,540(s1)
    80005754:	02f70d63          	beq	a4,a5,8000578e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005758:	0017871b          	addiw	a4,a5,1
    8000575c:	20e4ac23          	sw	a4,536(s1)
    80005760:	1ff7f793          	andi	a5,a5,511
    80005764:	97a6                	add	a5,a5,s1
    80005766:	0187c783          	lbu	a5,24(a5)
    8000576a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000576e:	4685                	li	a3,1
    80005770:	fbf40613          	addi	a2,s0,-65
    80005774:	85ca                	mv	a1,s2
    80005776:	088a3503          	ld	a0,136(s4)
    8000577a:	ffffc097          	auipc	ra,0xffffc
    8000577e:	0ae080e7          	jalr	174(ra) # 80001828 <copyout>
    80005782:	01650663          	beq	a0,s6,8000578e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005786:	2985                	addiw	s3,s3,1
    80005788:	0905                	addi	s2,s2,1
    8000578a:	fd3a91e3          	bne	s5,s3,8000574c <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000578e:	21c48513          	addi	a0,s1,540
    80005792:	ffffd097          	auipc	ra,0xffffd
    80005796:	e3a080e7          	jalr	-454(ra) # 800025cc <wakeup>
  release(&pi->lock);
    8000579a:	8526                	mv	a0,s1
    8000579c:	ffffb097          	auipc	ra,0xffffb
    800057a0:	69c080e7          	jalr	1692(ra) # 80000e38 <release>
  return i;
}
    800057a4:	854e                	mv	a0,s3
    800057a6:	60a6                	ld	ra,72(sp)
    800057a8:	6406                	ld	s0,64(sp)
    800057aa:	74e2                	ld	s1,56(sp)
    800057ac:	7942                	ld	s2,48(sp)
    800057ae:	79a2                	ld	s3,40(sp)
    800057b0:	7a02                	ld	s4,32(sp)
    800057b2:	6ae2                	ld	s5,24(sp)
    800057b4:	6b42                	ld	s6,16(sp)
    800057b6:	6161                	addi	sp,sp,80
    800057b8:	8082                	ret
      release(&pi->lock);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffb097          	auipc	ra,0xffffb
    800057c0:	67c080e7          	jalr	1660(ra) # 80000e38 <release>
      return -1;
    800057c4:	59fd                	li	s3,-1
    800057c6:	bff9                	j	800057a4 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057c8:	4981                	li	s3,0
    800057ca:	b7d1                	j	8000578e <piperead+0xb4>

00000000800057cc <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800057cc:	1141                	addi	sp,sp,-16
    800057ce:	e422                	sd	s0,8(sp)
    800057d0:	0800                	addi	s0,sp,16
    800057d2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800057d4:	8905                	andi	a0,a0,1
    800057d6:	c111                	beqz	a0,800057da <flags2perm+0xe>
      perm = PTE_X;
    800057d8:	4521                	li	a0,8
    if(flags & 0x2)
    800057da:	8b89                	andi	a5,a5,2
    800057dc:	c399                	beqz	a5,800057e2 <flags2perm+0x16>
      perm |= PTE_W;
    800057de:	00456513          	ori	a0,a0,4
    return perm;
}
    800057e2:	6422                	ld	s0,8(sp)
    800057e4:	0141                	addi	sp,sp,16
    800057e6:	8082                	ret

00000000800057e8 <exec>:

int
exec(char *path, char **argv)
{
    800057e8:	df010113          	addi	sp,sp,-528
    800057ec:	20113423          	sd	ra,520(sp)
    800057f0:	20813023          	sd	s0,512(sp)
    800057f4:	ffa6                	sd	s1,504(sp)
    800057f6:	fbca                	sd	s2,496(sp)
    800057f8:	f7ce                	sd	s3,488(sp)
    800057fa:	f3d2                	sd	s4,480(sp)
    800057fc:	efd6                	sd	s5,472(sp)
    800057fe:	ebda                	sd	s6,464(sp)
    80005800:	e7de                	sd	s7,456(sp)
    80005802:	e3e2                	sd	s8,448(sp)
    80005804:	ff66                	sd	s9,440(sp)
    80005806:	fb6a                	sd	s10,432(sp)
    80005808:	f76e                	sd	s11,424(sp)
    8000580a:	0c00                	addi	s0,sp,528
    8000580c:	84aa                	mv	s1,a0
    8000580e:	dea43c23          	sd	a0,-520(s0)
    80005812:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005816:	ffffc097          	auipc	ra,0xffffc
    8000581a:	38c080e7          	jalr	908(ra) # 80001ba2 <myproc>
    8000581e:	892a                	mv	s2,a0

  begin_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	474080e7          	jalr	1140(ra) # 80004c94 <begin_op>

  if((ip = namei(path)) == 0){
    80005828:	8526                	mv	a0,s1
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	24e080e7          	jalr	590(ra) # 80004a78 <namei>
    80005832:	c92d                	beqz	a0,800058a4 <exec+0xbc>
    80005834:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	a9c080e7          	jalr	-1380(ra) # 800042d2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000583e:	04000713          	li	a4,64
    80005842:	4681                	li	a3,0
    80005844:	e5040613          	addi	a2,s0,-432
    80005848:	4581                	li	a1,0
    8000584a:	8526                	mv	a0,s1
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	d3a080e7          	jalr	-710(ra) # 80004586 <readi>
    80005854:	04000793          	li	a5,64
    80005858:	00f51a63          	bne	a0,a5,8000586c <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000585c:	e5042703          	lw	a4,-432(s0)
    80005860:	464c47b7          	lui	a5,0x464c4
    80005864:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005868:	04f70463          	beq	a4,a5,800058b0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000586c:	8526                	mv	a0,s1
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	cc6080e7          	jalr	-826(ra) # 80004534 <iunlockput>
    end_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	49e080e7          	jalr	1182(ra) # 80004d14 <end_op>
  }
  return -1;
    8000587e:	557d                	li	a0,-1
}
    80005880:	20813083          	ld	ra,520(sp)
    80005884:	20013403          	ld	s0,512(sp)
    80005888:	74fe                	ld	s1,504(sp)
    8000588a:	795e                	ld	s2,496(sp)
    8000588c:	79be                	ld	s3,488(sp)
    8000588e:	7a1e                	ld	s4,480(sp)
    80005890:	6afe                	ld	s5,472(sp)
    80005892:	6b5e                	ld	s6,464(sp)
    80005894:	6bbe                	ld	s7,456(sp)
    80005896:	6c1e                	ld	s8,448(sp)
    80005898:	7cfa                	ld	s9,440(sp)
    8000589a:	7d5a                	ld	s10,432(sp)
    8000589c:	7dba                	ld	s11,424(sp)
    8000589e:	21010113          	addi	sp,sp,528
    800058a2:	8082                	ret
    end_op();
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	470080e7          	jalr	1136(ra) # 80004d14 <end_op>
    return -1;
    800058ac:	557d                	li	a0,-1
    800058ae:	bfc9                	j	80005880 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800058b0:	854a                	mv	a0,s2
    800058b2:	ffffc097          	auipc	ra,0xffffc
    800058b6:	3b4080e7          	jalr	948(ra) # 80001c66 <proc_pagetable>
    800058ba:	8baa                	mv	s7,a0
    800058bc:	d945                	beqz	a0,8000586c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058be:	e7042983          	lw	s3,-400(s0)
    800058c2:	e8845783          	lhu	a5,-376(s0)
    800058c6:	c7ad                	beqz	a5,80005930 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800058c8:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800058ca:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800058cc:	6c85                	lui	s9,0x1
    800058ce:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800058d2:	def43823          	sd	a5,-528(s0)
    800058d6:	ac0d                	j	80005b08 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800058d8:	00003517          	auipc	a0,0x3
    800058dc:	f8850513          	addi	a0,a0,-120 # 80008860 <syscalls+0x2a8>
    800058e0:	ffffb097          	auipc	ra,0xffffb
    800058e4:	c64080e7          	jalr	-924(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800058e8:	8756                	mv	a4,s5
    800058ea:	012d86bb          	addw	a3,s11,s2
    800058ee:	4581                	li	a1,0
    800058f0:	8526                	mv	a0,s1
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	c94080e7          	jalr	-876(ra) # 80004586 <readi>
    800058fa:	2501                	sext.w	a0,a0
    800058fc:	1aaa9a63          	bne	s5,a0,80005ab0 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80005900:	6785                	lui	a5,0x1
    80005902:	0127893b          	addw	s2,a5,s2
    80005906:	77fd                	lui	a5,0xfffff
    80005908:	01478a3b          	addw	s4,a5,s4
    8000590c:	1f897563          	bgeu	s2,s8,80005af6 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80005910:	02091593          	slli	a1,s2,0x20
    80005914:	9181                	srli	a1,a1,0x20
    80005916:	95ea                	add	a1,a1,s10
    80005918:	855e                	mv	a0,s7
    8000591a:	ffffc097          	auipc	ra,0xffffc
    8000591e:	8f8080e7          	jalr	-1800(ra) # 80001212 <walkaddr>
    80005922:	862a                	mv	a2,a0
    if(pa == 0)
    80005924:	d955                	beqz	a0,800058d8 <exec+0xf0>
      n = PGSIZE;
    80005926:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005928:	fd9a70e3          	bgeu	s4,s9,800058e8 <exec+0x100>
      n = sz - i;
    8000592c:	8ad2                	mv	s5,s4
    8000592e:	bf6d                	j	800058e8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005930:	4a01                	li	s4,0
  iunlockput(ip);
    80005932:	8526                	mv	a0,s1
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	c00080e7          	jalr	-1024(ra) # 80004534 <iunlockput>
  end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	3d8080e7          	jalr	984(ra) # 80004d14 <end_op>
  p = myproc();
    80005944:	ffffc097          	auipc	ra,0xffffc
    80005948:	25e080e7          	jalr	606(ra) # 80001ba2 <myproc>
    8000594c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000594e:	08053d03          	ld	s10,128(a0)
  sz = PGROUNDUP(sz);
    80005952:	6785                	lui	a5,0x1
    80005954:	17fd                	addi	a5,a5,-1
    80005956:	9a3e                	add	s4,s4,a5
    80005958:	757d                	lui	a0,0xfffff
    8000595a:	00aa77b3          	and	a5,s4,a0
    8000595e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005962:	4691                	li	a3,4
    80005964:	6609                	lui	a2,0x2
    80005966:	963e                	add	a2,a2,a5
    80005968:	85be                	mv	a1,a5
    8000596a:	855e                	mv	a0,s7
    8000596c:	ffffc097          	auipc	ra,0xffffc
    80005970:	c5a080e7          	jalr	-934(ra) # 800015c6 <uvmalloc>
    80005974:	8b2a                	mv	s6,a0
  ip = 0;
    80005976:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005978:	12050c63          	beqz	a0,80005ab0 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000597c:	75f9                	lui	a1,0xffffe
    8000597e:	95aa                	add	a1,a1,a0
    80005980:	855e                	mv	a0,s7
    80005982:	ffffc097          	auipc	ra,0xffffc
    80005986:	e74080e7          	jalr	-396(ra) # 800017f6 <uvmclear>
  stackbase = sp - PGSIZE;
    8000598a:	7c7d                	lui	s8,0xfffff
    8000598c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000598e:	e0043783          	ld	a5,-512(s0)
    80005992:	6388                	ld	a0,0(a5)
    80005994:	c535                	beqz	a0,80005a00 <exec+0x218>
    80005996:	e9040993          	addi	s3,s0,-368
    8000599a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000599e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800059a0:	ffffb097          	auipc	ra,0xffffb
    800059a4:	664080e7          	jalr	1636(ra) # 80001004 <strlen>
    800059a8:	2505                	addiw	a0,a0,1
    800059aa:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800059ae:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800059b2:	13896663          	bltu	s2,s8,80005ade <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800059b6:	e0043d83          	ld	s11,-512(s0)
    800059ba:	000dba03          	ld	s4,0(s11)
    800059be:	8552                	mv	a0,s4
    800059c0:	ffffb097          	auipc	ra,0xffffb
    800059c4:	644080e7          	jalr	1604(ra) # 80001004 <strlen>
    800059c8:	0015069b          	addiw	a3,a0,1
    800059cc:	8652                	mv	a2,s4
    800059ce:	85ca                	mv	a1,s2
    800059d0:	855e                	mv	a0,s7
    800059d2:	ffffc097          	auipc	ra,0xffffc
    800059d6:	e56080e7          	jalr	-426(ra) # 80001828 <copyout>
    800059da:	10054663          	bltz	a0,80005ae6 <exec+0x2fe>
    ustack[argc] = sp;
    800059de:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800059e2:	0485                	addi	s1,s1,1
    800059e4:	008d8793          	addi	a5,s11,8
    800059e8:	e0f43023          	sd	a5,-512(s0)
    800059ec:	008db503          	ld	a0,8(s11)
    800059f0:	c911                	beqz	a0,80005a04 <exec+0x21c>
    if(argc >= MAXARG)
    800059f2:	09a1                	addi	s3,s3,8
    800059f4:	fb3c96e3          	bne	s9,s3,800059a0 <exec+0x1b8>
  sz = sz1;
    800059f8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800059fc:	4481                	li	s1,0
    800059fe:	a84d                	j	80005ab0 <exec+0x2c8>
  sp = sz;
    80005a00:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a02:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a04:	00349793          	slli	a5,s1,0x3
    80005a08:	f9040713          	addi	a4,s0,-112
    80005a0c:	97ba                	add	a5,a5,a4
    80005a0e:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005a12:	00148693          	addi	a3,s1,1
    80005a16:	068e                	slli	a3,a3,0x3
    80005a18:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005a1c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005a20:	01897663          	bgeu	s2,s8,80005a2c <exec+0x244>
  sz = sz1;
    80005a24:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a28:	4481                	li	s1,0
    80005a2a:	a059                	j	80005ab0 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005a2c:	e9040613          	addi	a2,s0,-368
    80005a30:	85ca                	mv	a1,s2
    80005a32:	855e                	mv	a0,s7
    80005a34:	ffffc097          	auipc	ra,0xffffc
    80005a38:	df4080e7          	jalr	-524(ra) # 80001828 <copyout>
    80005a3c:	0a054963          	bltz	a0,80005aee <exec+0x306>
  p->trapframe->a1 = sp;
    80005a40:	090ab783          	ld	a5,144(s5)
    80005a44:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005a48:	df843783          	ld	a5,-520(s0)
    80005a4c:	0007c703          	lbu	a4,0(a5)
    80005a50:	cf11                	beqz	a4,80005a6c <exec+0x284>
    80005a52:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005a54:	02f00693          	li	a3,47
    80005a58:	a039                	j	80005a66 <exec+0x27e>
      last = s+1;
    80005a5a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005a5e:	0785                	addi	a5,a5,1
    80005a60:	fff7c703          	lbu	a4,-1(a5)
    80005a64:	c701                	beqz	a4,80005a6c <exec+0x284>
    if(*s == '/')
    80005a66:	fed71ce3          	bne	a4,a3,80005a5e <exec+0x276>
    80005a6a:	bfc5                	j	80005a5a <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005a6c:	4641                	li	a2,16
    80005a6e:	df843583          	ld	a1,-520(s0)
    80005a72:	198a8513          	addi	a0,s5,408
    80005a76:	ffffb097          	auipc	ra,0xffffb
    80005a7a:	55c080e7          	jalr	1372(ra) # 80000fd2 <safestrcpy>
  oldpagetable = p->pagetable;
    80005a7e:	088ab503          	ld	a0,136(s5)
  p->pagetable = pagetable;
    80005a82:	097ab423          	sd	s7,136(s5)
  p->sz = sz;
    80005a86:	096ab023          	sd	s6,128(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005a8a:	090ab783          	ld	a5,144(s5)
    80005a8e:	e6843703          	ld	a4,-408(s0)
    80005a92:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005a94:	090ab783          	ld	a5,144(s5)
    80005a98:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005a9c:	85ea                	mv	a1,s10
    80005a9e:	ffffc097          	auipc	ra,0xffffc
    80005aa2:	264080e7          	jalr	612(ra) # 80001d02 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005aa6:	0004851b          	sext.w	a0,s1
    80005aaa:	bbd9                	j	80005880 <exec+0x98>
    80005aac:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005ab0:	e0843583          	ld	a1,-504(s0)
    80005ab4:	855e                	mv	a0,s7
    80005ab6:	ffffc097          	auipc	ra,0xffffc
    80005aba:	24c080e7          	jalr	588(ra) # 80001d02 <proc_freepagetable>
  if(ip){
    80005abe:	da0497e3          	bnez	s1,8000586c <exec+0x84>
  return -1;
    80005ac2:	557d                	li	a0,-1
    80005ac4:	bb75                	j	80005880 <exec+0x98>
    80005ac6:	e1443423          	sd	s4,-504(s0)
    80005aca:	b7dd                	j	80005ab0 <exec+0x2c8>
    80005acc:	e1443423          	sd	s4,-504(s0)
    80005ad0:	b7c5                	j	80005ab0 <exec+0x2c8>
    80005ad2:	e1443423          	sd	s4,-504(s0)
    80005ad6:	bfe9                	j	80005ab0 <exec+0x2c8>
    80005ad8:	e1443423          	sd	s4,-504(s0)
    80005adc:	bfd1                	j	80005ab0 <exec+0x2c8>
  sz = sz1;
    80005ade:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005ae2:	4481                	li	s1,0
    80005ae4:	b7f1                	j	80005ab0 <exec+0x2c8>
  sz = sz1;
    80005ae6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005aea:	4481                	li	s1,0
    80005aec:	b7d1                	j	80005ab0 <exec+0x2c8>
  sz = sz1;
    80005aee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005af2:	4481                	li	s1,0
    80005af4:	bf75                	j	80005ab0 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005af6:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005afa:	2b05                	addiw	s6,s6,1
    80005afc:	0389899b          	addiw	s3,s3,56
    80005b00:	e8845783          	lhu	a5,-376(s0)
    80005b04:	e2fb57e3          	bge	s6,a5,80005932 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005b08:	2981                	sext.w	s3,s3
    80005b0a:	03800713          	li	a4,56
    80005b0e:	86ce                	mv	a3,s3
    80005b10:	e1840613          	addi	a2,s0,-488
    80005b14:	4581                	li	a1,0
    80005b16:	8526                	mv	a0,s1
    80005b18:	fffff097          	auipc	ra,0xfffff
    80005b1c:	a6e080e7          	jalr	-1426(ra) # 80004586 <readi>
    80005b20:	03800793          	li	a5,56
    80005b24:	f8f514e3          	bne	a0,a5,80005aac <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005b28:	e1842783          	lw	a5,-488(s0)
    80005b2c:	4705                	li	a4,1
    80005b2e:	fce796e3          	bne	a5,a4,80005afa <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005b32:	e4043903          	ld	s2,-448(s0)
    80005b36:	e3843783          	ld	a5,-456(s0)
    80005b3a:	f8f966e3          	bltu	s2,a5,80005ac6 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005b3e:	e2843783          	ld	a5,-472(s0)
    80005b42:	993e                	add	s2,s2,a5
    80005b44:	f8f964e3          	bltu	s2,a5,80005acc <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005b48:	df043703          	ld	a4,-528(s0)
    80005b4c:	8ff9                	and	a5,a5,a4
    80005b4e:	f3d1                	bnez	a5,80005ad2 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005b50:	e1c42503          	lw	a0,-484(s0)
    80005b54:	00000097          	auipc	ra,0x0
    80005b58:	c78080e7          	jalr	-904(ra) # 800057cc <flags2perm>
    80005b5c:	86aa                	mv	a3,a0
    80005b5e:	864a                	mv	a2,s2
    80005b60:	85d2                	mv	a1,s4
    80005b62:	855e                	mv	a0,s7
    80005b64:	ffffc097          	auipc	ra,0xffffc
    80005b68:	a62080e7          	jalr	-1438(ra) # 800015c6 <uvmalloc>
    80005b6c:	e0a43423          	sd	a0,-504(s0)
    80005b70:	d525                	beqz	a0,80005ad8 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005b72:	e2843d03          	ld	s10,-472(s0)
    80005b76:	e2042d83          	lw	s11,-480(s0)
    80005b7a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005b7e:	f60c0ce3          	beqz	s8,80005af6 <exec+0x30e>
    80005b82:	8a62                	mv	s4,s8
    80005b84:	4901                	li	s2,0
    80005b86:	b369                	j	80005910 <exec+0x128>

0000000080005b88 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005b88:	7179                	addi	sp,sp,-48
    80005b8a:	f406                	sd	ra,40(sp)
    80005b8c:	f022                	sd	s0,32(sp)
    80005b8e:	ec26                	sd	s1,24(sp)
    80005b90:	e84a                	sd	s2,16(sp)
    80005b92:	1800                	addi	s0,sp,48
    80005b94:	892e                	mv	s2,a1
    80005b96:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005b98:	fdc40593          	addi	a1,s0,-36
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	8c8080e7          	jalr	-1848(ra) # 80003464 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005ba4:	fdc42703          	lw	a4,-36(s0)
    80005ba8:	47bd                	li	a5,15
    80005baa:	02e7eb63          	bltu	a5,a4,80005be0 <argfd+0x58>
    80005bae:	ffffc097          	auipc	ra,0xffffc
    80005bb2:	ff4080e7          	jalr	-12(ra) # 80001ba2 <myproc>
    80005bb6:	fdc42703          	lw	a4,-36(s0)
    80005bba:	02270793          	addi	a5,a4,34
    80005bbe:	078e                	slli	a5,a5,0x3
    80005bc0:	953e                	add	a0,a0,a5
    80005bc2:	611c                	ld	a5,0(a0)
    80005bc4:	c385                	beqz	a5,80005be4 <argfd+0x5c>
    return -1;
  if(pfd)
    80005bc6:	00090463          	beqz	s2,80005bce <argfd+0x46>
    *pfd = fd;
    80005bca:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005bce:	4501                	li	a0,0
  if(pf)
    80005bd0:	c091                	beqz	s1,80005bd4 <argfd+0x4c>
    *pf = f;
    80005bd2:	e09c                	sd	a5,0(s1)
}
    80005bd4:	70a2                	ld	ra,40(sp)
    80005bd6:	7402                	ld	s0,32(sp)
    80005bd8:	64e2                	ld	s1,24(sp)
    80005bda:	6942                	ld	s2,16(sp)
    80005bdc:	6145                	addi	sp,sp,48
    80005bde:	8082                	ret
    return -1;
    80005be0:	557d                	li	a0,-1
    80005be2:	bfcd                	j	80005bd4 <argfd+0x4c>
    80005be4:	557d                	li	a0,-1
    80005be6:	b7fd                	j	80005bd4 <argfd+0x4c>

0000000080005be8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005be8:	1101                	addi	sp,sp,-32
    80005bea:	ec06                	sd	ra,24(sp)
    80005bec:	e822                	sd	s0,16(sp)
    80005bee:	e426                	sd	s1,8(sp)
    80005bf0:	1000                	addi	s0,sp,32
    80005bf2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005bf4:	ffffc097          	auipc	ra,0xffffc
    80005bf8:	fae080e7          	jalr	-82(ra) # 80001ba2 <myproc>
    80005bfc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005bfe:	11050793          	addi	a5,a0,272 # fffffffffffff110 <end+0xffffffff7fdbbaa8>
    80005c02:	4501                	li	a0,0
    80005c04:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005c06:	6398                	ld	a4,0(a5)
    80005c08:	cb19                	beqz	a4,80005c1e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005c0a:	2505                	addiw	a0,a0,1
    80005c0c:	07a1                	addi	a5,a5,8
    80005c0e:	fed51ce3          	bne	a0,a3,80005c06 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005c12:	557d                	li	a0,-1
}
    80005c14:	60e2                	ld	ra,24(sp)
    80005c16:	6442                	ld	s0,16(sp)
    80005c18:	64a2                	ld	s1,8(sp)
    80005c1a:	6105                	addi	sp,sp,32
    80005c1c:	8082                	ret
      p->ofile[fd] = f;
    80005c1e:	02250793          	addi	a5,a0,34
    80005c22:	078e                	slli	a5,a5,0x3
    80005c24:	963e                	add	a2,a2,a5
    80005c26:	e204                	sd	s1,0(a2)
      return fd;
    80005c28:	b7f5                	j	80005c14 <fdalloc+0x2c>

0000000080005c2a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005c2a:	715d                	addi	sp,sp,-80
    80005c2c:	e486                	sd	ra,72(sp)
    80005c2e:	e0a2                	sd	s0,64(sp)
    80005c30:	fc26                	sd	s1,56(sp)
    80005c32:	f84a                	sd	s2,48(sp)
    80005c34:	f44e                	sd	s3,40(sp)
    80005c36:	f052                	sd	s4,32(sp)
    80005c38:	ec56                	sd	s5,24(sp)
    80005c3a:	e85a                	sd	s6,16(sp)
    80005c3c:	0880                	addi	s0,sp,80
    80005c3e:	8b2e                	mv	s6,a1
    80005c40:	89b2                	mv	s3,a2
    80005c42:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005c44:	fb040593          	addi	a1,s0,-80
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	e4e080e7          	jalr	-434(ra) # 80004a96 <nameiparent>
    80005c50:	84aa                	mv	s1,a0
    80005c52:	16050063          	beqz	a0,80005db2 <create+0x188>
    return 0;

  ilock(dp);
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	67c080e7          	jalr	1660(ra) # 800042d2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005c5e:	4601                	li	a2,0
    80005c60:	fb040593          	addi	a1,s0,-80
    80005c64:	8526                	mv	a0,s1
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	b50080e7          	jalr	-1200(ra) # 800047b6 <dirlookup>
    80005c6e:	8aaa                	mv	s5,a0
    80005c70:	c931                	beqz	a0,80005cc4 <create+0x9a>
    iunlockput(dp);
    80005c72:	8526                	mv	a0,s1
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	8c0080e7          	jalr	-1856(ra) # 80004534 <iunlockput>
    ilock(ip);
    80005c7c:	8556                	mv	a0,s5
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	654080e7          	jalr	1620(ra) # 800042d2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005c86:	000b059b          	sext.w	a1,s6
    80005c8a:	4789                	li	a5,2
    80005c8c:	02f59563          	bne	a1,a5,80005cb6 <create+0x8c>
    80005c90:	044ad783          	lhu	a5,68(s5)
    80005c94:	37f9                	addiw	a5,a5,-2
    80005c96:	17c2                	slli	a5,a5,0x30
    80005c98:	93c1                	srli	a5,a5,0x30
    80005c9a:	4705                	li	a4,1
    80005c9c:	00f76d63          	bltu	a4,a5,80005cb6 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005ca0:	8556                	mv	a0,s5
    80005ca2:	60a6                	ld	ra,72(sp)
    80005ca4:	6406                	ld	s0,64(sp)
    80005ca6:	74e2                	ld	s1,56(sp)
    80005ca8:	7942                	ld	s2,48(sp)
    80005caa:	79a2                	ld	s3,40(sp)
    80005cac:	7a02                	ld	s4,32(sp)
    80005cae:	6ae2                	ld	s5,24(sp)
    80005cb0:	6b42                	ld	s6,16(sp)
    80005cb2:	6161                	addi	sp,sp,80
    80005cb4:	8082                	ret
    iunlockput(ip);
    80005cb6:	8556                	mv	a0,s5
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	87c080e7          	jalr	-1924(ra) # 80004534 <iunlockput>
    return 0;
    80005cc0:	4a81                	li	s5,0
    80005cc2:	bff9                	j	80005ca0 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005cc4:	85da                	mv	a1,s6
    80005cc6:	4088                	lw	a0,0(s1)
    80005cc8:	ffffe097          	auipc	ra,0xffffe
    80005ccc:	46e080e7          	jalr	1134(ra) # 80004136 <ialloc>
    80005cd0:	8a2a                	mv	s4,a0
    80005cd2:	c921                	beqz	a0,80005d22 <create+0xf8>
  ilock(ip);
    80005cd4:	ffffe097          	auipc	ra,0xffffe
    80005cd8:	5fe080e7          	jalr	1534(ra) # 800042d2 <ilock>
  ip->major = major;
    80005cdc:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005ce0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005ce4:	4785                	li	a5,1
    80005ce6:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005cea:	8552                	mv	a0,s4
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	51c080e7          	jalr	1308(ra) # 80004208 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005cf4:	000b059b          	sext.w	a1,s6
    80005cf8:	4785                	li	a5,1
    80005cfa:	02f58b63          	beq	a1,a5,80005d30 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005cfe:	004a2603          	lw	a2,4(s4)
    80005d02:	fb040593          	addi	a1,s0,-80
    80005d06:	8526                	mv	a0,s1
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	cbe080e7          	jalr	-834(ra) # 800049c6 <dirlink>
    80005d10:	06054f63          	bltz	a0,80005d8e <create+0x164>
  iunlockput(dp);
    80005d14:	8526                	mv	a0,s1
    80005d16:	fffff097          	auipc	ra,0xfffff
    80005d1a:	81e080e7          	jalr	-2018(ra) # 80004534 <iunlockput>
  return ip;
    80005d1e:	8ad2                	mv	s5,s4
    80005d20:	b741                	j	80005ca0 <create+0x76>
    iunlockput(dp);
    80005d22:	8526                	mv	a0,s1
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	810080e7          	jalr	-2032(ra) # 80004534 <iunlockput>
    return 0;
    80005d2c:	8ad2                	mv	s5,s4
    80005d2e:	bf8d                	j	80005ca0 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005d30:	004a2603          	lw	a2,4(s4)
    80005d34:	00003597          	auipc	a1,0x3
    80005d38:	b4c58593          	addi	a1,a1,-1204 # 80008880 <syscalls+0x2c8>
    80005d3c:	8552                	mv	a0,s4
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	c88080e7          	jalr	-888(ra) # 800049c6 <dirlink>
    80005d46:	04054463          	bltz	a0,80005d8e <create+0x164>
    80005d4a:	40d0                	lw	a2,4(s1)
    80005d4c:	00003597          	auipc	a1,0x3
    80005d50:	b3c58593          	addi	a1,a1,-1220 # 80008888 <syscalls+0x2d0>
    80005d54:	8552                	mv	a0,s4
    80005d56:	fffff097          	auipc	ra,0xfffff
    80005d5a:	c70080e7          	jalr	-912(ra) # 800049c6 <dirlink>
    80005d5e:	02054863          	bltz	a0,80005d8e <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005d62:	004a2603          	lw	a2,4(s4)
    80005d66:	fb040593          	addi	a1,s0,-80
    80005d6a:	8526                	mv	a0,s1
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	c5a080e7          	jalr	-934(ra) # 800049c6 <dirlink>
    80005d74:	00054d63          	bltz	a0,80005d8e <create+0x164>
    dp->nlink++;  // for ".."
    80005d78:	04a4d783          	lhu	a5,74(s1)
    80005d7c:	2785                	addiw	a5,a5,1
    80005d7e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d82:	8526                	mv	a0,s1
    80005d84:	ffffe097          	auipc	ra,0xffffe
    80005d88:	484080e7          	jalr	1156(ra) # 80004208 <iupdate>
    80005d8c:	b761                	j	80005d14 <create+0xea>
  ip->nlink = 0;
    80005d8e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005d92:	8552                	mv	a0,s4
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	474080e7          	jalr	1140(ra) # 80004208 <iupdate>
  iunlockput(ip);
    80005d9c:	8552                	mv	a0,s4
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	796080e7          	jalr	1942(ra) # 80004534 <iunlockput>
  iunlockput(dp);
    80005da6:	8526                	mv	a0,s1
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	78c080e7          	jalr	1932(ra) # 80004534 <iunlockput>
  return 0;
    80005db0:	bdc5                	j	80005ca0 <create+0x76>
    return 0;
    80005db2:	8aaa                	mv	s5,a0
    80005db4:	b5f5                	j	80005ca0 <create+0x76>

0000000080005db6 <sys_dup>:
{
    80005db6:	7179                	addi	sp,sp,-48
    80005db8:	f406                	sd	ra,40(sp)
    80005dba:	f022                	sd	s0,32(sp)
    80005dbc:	ec26                	sd	s1,24(sp)
    80005dbe:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005dc0:	fd840613          	addi	a2,s0,-40
    80005dc4:	4581                	li	a1,0
    80005dc6:	4501                	li	a0,0
    80005dc8:	00000097          	auipc	ra,0x0
    80005dcc:	dc0080e7          	jalr	-576(ra) # 80005b88 <argfd>
    return -1;
    80005dd0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005dd2:	02054363          	bltz	a0,80005df8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005dd6:	fd843503          	ld	a0,-40(s0)
    80005dda:	00000097          	auipc	ra,0x0
    80005dde:	e0e080e7          	jalr	-498(ra) # 80005be8 <fdalloc>
    80005de2:	84aa                	mv	s1,a0
    return -1;
    80005de4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005de6:	00054963          	bltz	a0,80005df8 <sys_dup+0x42>
  filedup(f);
    80005dea:	fd843503          	ld	a0,-40(s0)
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	320080e7          	jalr	800(ra) # 8000510e <filedup>
  return fd;
    80005df6:	87a6                	mv	a5,s1
}
    80005df8:	853e                	mv	a0,a5
    80005dfa:	70a2                	ld	ra,40(sp)
    80005dfc:	7402                	ld	s0,32(sp)
    80005dfe:	64e2                	ld	s1,24(sp)
    80005e00:	6145                	addi	sp,sp,48
    80005e02:	8082                	ret

0000000080005e04 <sys_read>:
{
    80005e04:	7179                	addi	sp,sp,-48
    80005e06:	f406                	sd	ra,40(sp)
    80005e08:	f022                	sd	s0,32(sp)
    80005e0a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005e0c:	fd840593          	addi	a1,s0,-40
    80005e10:	4505                	li	a0,1
    80005e12:	ffffd097          	auipc	ra,0xffffd
    80005e16:	672080e7          	jalr	1650(ra) # 80003484 <argaddr>
  argint(2, &n);
    80005e1a:	fe440593          	addi	a1,s0,-28
    80005e1e:	4509                	li	a0,2
    80005e20:	ffffd097          	auipc	ra,0xffffd
    80005e24:	644080e7          	jalr	1604(ra) # 80003464 <argint>
  if(argfd(0, 0, &f) < 0)
    80005e28:	fe840613          	addi	a2,s0,-24
    80005e2c:	4581                	li	a1,0
    80005e2e:	4501                	li	a0,0
    80005e30:	00000097          	auipc	ra,0x0
    80005e34:	d58080e7          	jalr	-680(ra) # 80005b88 <argfd>
    80005e38:	87aa                	mv	a5,a0
    return -1;
    80005e3a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005e3c:	0007cc63          	bltz	a5,80005e54 <sys_read+0x50>
  return fileread(f, p, n);
    80005e40:	fe442603          	lw	a2,-28(s0)
    80005e44:	fd843583          	ld	a1,-40(s0)
    80005e48:	fe843503          	ld	a0,-24(s0)
    80005e4c:	fffff097          	auipc	ra,0xfffff
    80005e50:	44e080e7          	jalr	1102(ra) # 8000529a <fileread>
}
    80005e54:	70a2                	ld	ra,40(sp)
    80005e56:	7402                	ld	s0,32(sp)
    80005e58:	6145                	addi	sp,sp,48
    80005e5a:	8082                	ret

0000000080005e5c <sys_write>:
{
    80005e5c:	7179                	addi	sp,sp,-48
    80005e5e:	f406                	sd	ra,40(sp)
    80005e60:	f022                	sd	s0,32(sp)
    80005e62:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005e64:	fd840593          	addi	a1,s0,-40
    80005e68:	4505                	li	a0,1
    80005e6a:	ffffd097          	auipc	ra,0xffffd
    80005e6e:	61a080e7          	jalr	1562(ra) # 80003484 <argaddr>
  argint(2, &n);
    80005e72:	fe440593          	addi	a1,s0,-28
    80005e76:	4509                	li	a0,2
    80005e78:	ffffd097          	auipc	ra,0xffffd
    80005e7c:	5ec080e7          	jalr	1516(ra) # 80003464 <argint>
  if(argfd(0, 0, &f) < 0)
    80005e80:	fe840613          	addi	a2,s0,-24
    80005e84:	4581                	li	a1,0
    80005e86:	4501                	li	a0,0
    80005e88:	00000097          	auipc	ra,0x0
    80005e8c:	d00080e7          	jalr	-768(ra) # 80005b88 <argfd>
    80005e90:	87aa                	mv	a5,a0
    return -1;
    80005e92:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005e94:	0007cc63          	bltz	a5,80005eac <sys_write+0x50>
  return filewrite(f, p, n);
    80005e98:	fe442603          	lw	a2,-28(s0)
    80005e9c:	fd843583          	ld	a1,-40(s0)
    80005ea0:	fe843503          	ld	a0,-24(s0)
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	4b8080e7          	jalr	1208(ra) # 8000535c <filewrite>
}
    80005eac:	70a2                	ld	ra,40(sp)
    80005eae:	7402                	ld	s0,32(sp)
    80005eb0:	6145                	addi	sp,sp,48
    80005eb2:	8082                	ret

0000000080005eb4 <sys_close>:
{
    80005eb4:	1101                	addi	sp,sp,-32
    80005eb6:	ec06                	sd	ra,24(sp)
    80005eb8:	e822                	sd	s0,16(sp)
    80005eba:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005ebc:	fe040613          	addi	a2,s0,-32
    80005ec0:	fec40593          	addi	a1,s0,-20
    80005ec4:	4501                	li	a0,0
    80005ec6:	00000097          	auipc	ra,0x0
    80005eca:	cc2080e7          	jalr	-830(ra) # 80005b88 <argfd>
    return -1;
    80005ece:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ed0:	02054563          	bltz	a0,80005efa <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005ed4:	ffffc097          	auipc	ra,0xffffc
    80005ed8:	cce080e7          	jalr	-818(ra) # 80001ba2 <myproc>
    80005edc:	fec42783          	lw	a5,-20(s0)
    80005ee0:	02278793          	addi	a5,a5,34
    80005ee4:	078e                	slli	a5,a5,0x3
    80005ee6:	97aa                	add	a5,a5,a0
    80005ee8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005eec:	fe043503          	ld	a0,-32(s0)
    80005ef0:	fffff097          	auipc	ra,0xfffff
    80005ef4:	270080e7          	jalr	624(ra) # 80005160 <fileclose>
  return 0;
    80005ef8:	4781                	li	a5,0
}
    80005efa:	853e                	mv	a0,a5
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	6105                	addi	sp,sp,32
    80005f02:	8082                	ret

0000000080005f04 <sys_fstat>:
{
    80005f04:	1101                	addi	sp,sp,-32
    80005f06:	ec06                	sd	ra,24(sp)
    80005f08:	e822                	sd	s0,16(sp)
    80005f0a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005f0c:	fe040593          	addi	a1,s0,-32
    80005f10:	4505                	li	a0,1
    80005f12:	ffffd097          	auipc	ra,0xffffd
    80005f16:	572080e7          	jalr	1394(ra) # 80003484 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005f1a:	fe840613          	addi	a2,s0,-24
    80005f1e:	4581                	li	a1,0
    80005f20:	4501                	li	a0,0
    80005f22:	00000097          	auipc	ra,0x0
    80005f26:	c66080e7          	jalr	-922(ra) # 80005b88 <argfd>
    80005f2a:	87aa                	mv	a5,a0
    return -1;
    80005f2c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005f2e:	0007ca63          	bltz	a5,80005f42 <sys_fstat+0x3e>
  return filestat(f, st);
    80005f32:	fe043583          	ld	a1,-32(s0)
    80005f36:	fe843503          	ld	a0,-24(s0)
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	2ee080e7          	jalr	750(ra) # 80005228 <filestat>
}
    80005f42:	60e2                	ld	ra,24(sp)
    80005f44:	6442                	ld	s0,16(sp)
    80005f46:	6105                	addi	sp,sp,32
    80005f48:	8082                	ret

0000000080005f4a <sys_link>:
{
    80005f4a:	7169                	addi	sp,sp,-304
    80005f4c:	f606                	sd	ra,296(sp)
    80005f4e:	f222                	sd	s0,288(sp)
    80005f50:	ee26                	sd	s1,280(sp)
    80005f52:	ea4a                	sd	s2,272(sp)
    80005f54:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f56:	08000613          	li	a2,128
    80005f5a:	ed040593          	addi	a1,s0,-304
    80005f5e:	4501                	li	a0,0
    80005f60:	ffffd097          	auipc	ra,0xffffd
    80005f64:	544080e7          	jalr	1348(ra) # 800034a4 <argstr>
    return -1;
    80005f68:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f6a:	10054e63          	bltz	a0,80006086 <sys_link+0x13c>
    80005f6e:	08000613          	li	a2,128
    80005f72:	f5040593          	addi	a1,s0,-176
    80005f76:	4505                	li	a0,1
    80005f78:	ffffd097          	auipc	ra,0xffffd
    80005f7c:	52c080e7          	jalr	1324(ra) # 800034a4 <argstr>
    return -1;
    80005f80:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f82:	10054263          	bltz	a0,80006086 <sys_link+0x13c>
  begin_op();
    80005f86:	fffff097          	auipc	ra,0xfffff
    80005f8a:	d0e080e7          	jalr	-754(ra) # 80004c94 <begin_op>
  if((ip = namei(old)) == 0){
    80005f8e:	ed040513          	addi	a0,s0,-304
    80005f92:	fffff097          	auipc	ra,0xfffff
    80005f96:	ae6080e7          	jalr	-1306(ra) # 80004a78 <namei>
    80005f9a:	84aa                	mv	s1,a0
    80005f9c:	c551                	beqz	a0,80006028 <sys_link+0xde>
  ilock(ip);
    80005f9e:	ffffe097          	auipc	ra,0xffffe
    80005fa2:	334080e7          	jalr	820(ra) # 800042d2 <ilock>
  if(ip->type == T_DIR){
    80005fa6:	04449703          	lh	a4,68(s1)
    80005faa:	4785                	li	a5,1
    80005fac:	08f70463          	beq	a4,a5,80006034 <sys_link+0xea>
  ip->nlink++;
    80005fb0:	04a4d783          	lhu	a5,74(s1)
    80005fb4:	2785                	addiw	a5,a5,1
    80005fb6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005fba:	8526                	mv	a0,s1
    80005fbc:	ffffe097          	auipc	ra,0xffffe
    80005fc0:	24c080e7          	jalr	588(ra) # 80004208 <iupdate>
  iunlock(ip);
    80005fc4:	8526                	mv	a0,s1
    80005fc6:	ffffe097          	auipc	ra,0xffffe
    80005fca:	3ce080e7          	jalr	974(ra) # 80004394 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005fce:	fd040593          	addi	a1,s0,-48
    80005fd2:	f5040513          	addi	a0,s0,-176
    80005fd6:	fffff097          	auipc	ra,0xfffff
    80005fda:	ac0080e7          	jalr	-1344(ra) # 80004a96 <nameiparent>
    80005fde:	892a                	mv	s2,a0
    80005fe0:	c935                	beqz	a0,80006054 <sys_link+0x10a>
  ilock(dp);
    80005fe2:	ffffe097          	auipc	ra,0xffffe
    80005fe6:	2f0080e7          	jalr	752(ra) # 800042d2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005fea:	00092703          	lw	a4,0(s2)
    80005fee:	409c                	lw	a5,0(s1)
    80005ff0:	04f71d63          	bne	a4,a5,8000604a <sys_link+0x100>
    80005ff4:	40d0                	lw	a2,4(s1)
    80005ff6:	fd040593          	addi	a1,s0,-48
    80005ffa:	854a                	mv	a0,s2
    80005ffc:	fffff097          	auipc	ra,0xfffff
    80006000:	9ca080e7          	jalr	-1590(ra) # 800049c6 <dirlink>
    80006004:	04054363          	bltz	a0,8000604a <sys_link+0x100>
  iunlockput(dp);
    80006008:	854a                	mv	a0,s2
    8000600a:	ffffe097          	auipc	ra,0xffffe
    8000600e:	52a080e7          	jalr	1322(ra) # 80004534 <iunlockput>
  iput(ip);
    80006012:	8526                	mv	a0,s1
    80006014:	ffffe097          	auipc	ra,0xffffe
    80006018:	478080e7          	jalr	1144(ra) # 8000448c <iput>
  end_op();
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	cf8080e7          	jalr	-776(ra) # 80004d14 <end_op>
  return 0;
    80006024:	4781                	li	a5,0
    80006026:	a085                	j	80006086 <sys_link+0x13c>
    end_op();
    80006028:	fffff097          	auipc	ra,0xfffff
    8000602c:	cec080e7          	jalr	-788(ra) # 80004d14 <end_op>
    return -1;
    80006030:	57fd                	li	a5,-1
    80006032:	a891                	j	80006086 <sys_link+0x13c>
    iunlockput(ip);
    80006034:	8526                	mv	a0,s1
    80006036:	ffffe097          	auipc	ra,0xffffe
    8000603a:	4fe080e7          	jalr	1278(ra) # 80004534 <iunlockput>
    end_op();
    8000603e:	fffff097          	auipc	ra,0xfffff
    80006042:	cd6080e7          	jalr	-810(ra) # 80004d14 <end_op>
    return -1;
    80006046:	57fd                	li	a5,-1
    80006048:	a83d                	j	80006086 <sys_link+0x13c>
    iunlockput(dp);
    8000604a:	854a                	mv	a0,s2
    8000604c:	ffffe097          	auipc	ra,0xffffe
    80006050:	4e8080e7          	jalr	1256(ra) # 80004534 <iunlockput>
  ilock(ip);
    80006054:	8526                	mv	a0,s1
    80006056:	ffffe097          	auipc	ra,0xffffe
    8000605a:	27c080e7          	jalr	636(ra) # 800042d2 <ilock>
  ip->nlink--;
    8000605e:	04a4d783          	lhu	a5,74(s1)
    80006062:	37fd                	addiw	a5,a5,-1
    80006064:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006068:	8526                	mv	a0,s1
    8000606a:	ffffe097          	auipc	ra,0xffffe
    8000606e:	19e080e7          	jalr	414(ra) # 80004208 <iupdate>
  iunlockput(ip);
    80006072:	8526                	mv	a0,s1
    80006074:	ffffe097          	auipc	ra,0xffffe
    80006078:	4c0080e7          	jalr	1216(ra) # 80004534 <iunlockput>
  end_op();
    8000607c:	fffff097          	auipc	ra,0xfffff
    80006080:	c98080e7          	jalr	-872(ra) # 80004d14 <end_op>
  return -1;
    80006084:	57fd                	li	a5,-1
}
    80006086:	853e                	mv	a0,a5
    80006088:	70b2                	ld	ra,296(sp)
    8000608a:	7412                	ld	s0,288(sp)
    8000608c:	64f2                	ld	s1,280(sp)
    8000608e:	6952                	ld	s2,272(sp)
    80006090:	6155                	addi	sp,sp,304
    80006092:	8082                	ret

0000000080006094 <sys_unlink>:
{
    80006094:	7151                	addi	sp,sp,-240
    80006096:	f586                	sd	ra,232(sp)
    80006098:	f1a2                	sd	s0,224(sp)
    8000609a:	eda6                	sd	s1,216(sp)
    8000609c:	e9ca                	sd	s2,208(sp)
    8000609e:	e5ce                	sd	s3,200(sp)
    800060a0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800060a2:	08000613          	li	a2,128
    800060a6:	f3040593          	addi	a1,s0,-208
    800060aa:	4501                	li	a0,0
    800060ac:	ffffd097          	auipc	ra,0xffffd
    800060b0:	3f8080e7          	jalr	1016(ra) # 800034a4 <argstr>
    800060b4:	18054163          	bltz	a0,80006236 <sys_unlink+0x1a2>
  begin_op();
    800060b8:	fffff097          	auipc	ra,0xfffff
    800060bc:	bdc080e7          	jalr	-1060(ra) # 80004c94 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800060c0:	fb040593          	addi	a1,s0,-80
    800060c4:	f3040513          	addi	a0,s0,-208
    800060c8:	fffff097          	auipc	ra,0xfffff
    800060cc:	9ce080e7          	jalr	-1586(ra) # 80004a96 <nameiparent>
    800060d0:	84aa                	mv	s1,a0
    800060d2:	c979                	beqz	a0,800061a8 <sys_unlink+0x114>
  ilock(dp);
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	1fe080e7          	jalr	510(ra) # 800042d2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800060dc:	00002597          	auipc	a1,0x2
    800060e0:	7a458593          	addi	a1,a1,1956 # 80008880 <syscalls+0x2c8>
    800060e4:	fb040513          	addi	a0,s0,-80
    800060e8:	ffffe097          	auipc	ra,0xffffe
    800060ec:	6b4080e7          	jalr	1716(ra) # 8000479c <namecmp>
    800060f0:	14050a63          	beqz	a0,80006244 <sys_unlink+0x1b0>
    800060f4:	00002597          	auipc	a1,0x2
    800060f8:	79458593          	addi	a1,a1,1940 # 80008888 <syscalls+0x2d0>
    800060fc:	fb040513          	addi	a0,s0,-80
    80006100:	ffffe097          	auipc	ra,0xffffe
    80006104:	69c080e7          	jalr	1692(ra) # 8000479c <namecmp>
    80006108:	12050e63          	beqz	a0,80006244 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000610c:	f2c40613          	addi	a2,s0,-212
    80006110:	fb040593          	addi	a1,s0,-80
    80006114:	8526                	mv	a0,s1
    80006116:	ffffe097          	auipc	ra,0xffffe
    8000611a:	6a0080e7          	jalr	1696(ra) # 800047b6 <dirlookup>
    8000611e:	892a                	mv	s2,a0
    80006120:	12050263          	beqz	a0,80006244 <sys_unlink+0x1b0>
  ilock(ip);
    80006124:	ffffe097          	auipc	ra,0xffffe
    80006128:	1ae080e7          	jalr	430(ra) # 800042d2 <ilock>
  if(ip->nlink < 1)
    8000612c:	04a91783          	lh	a5,74(s2)
    80006130:	08f05263          	blez	a5,800061b4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006134:	04491703          	lh	a4,68(s2)
    80006138:	4785                	li	a5,1
    8000613a:	08f70563          	beq	a4,a5,800061c4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000613e:	4641                	li	a2,16
    80006140:	4581                	li	a1,0
    80006142:	fc040513          	addi	a0,s0,-64
    80006146:	ffffb097          	auipc	ra,0xffffb
    8000614a:	d3a080e7          	jalr	-710(ra) # 80000e80 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000614e:	4741                	li	a4,16
    80006150:	f2c42683          	lw	a3,-212(s0)
    80006154:	fc040613          	addi	a2,s0,-64
    80006158:	4581                	li	a1,0
    8000615a:	8526                	mv	a0,s1
    8000615c:	ffffe097          	auipc	ra,0xffffe
    80006160:	522080e7          	jalr	1314(ra) # 8000467e <writei>
    80006164:	47c1                	li	a5,16
    80006166:	0af51563          	bne	a0,a5,80006210 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000616a:	04491703          	lh	a4,68(s2)
    8000616e:	4785                	li	a5,1
    80006170:	0af70863          	beq	a4,a5,80006220 <sys_unlink+0x18c>
  iunlockput(dp);
    80006174:	8526                	mv	a0,s1
    80006176:	ffffe097          	auipc	ra,0xffffe
    8000617a:	3be080e7          	jalr	958(ra) # 80004534 <iunlockput>
  ip->nlink--;
    8000617e:	04a95783          	lhu	a5,74(s2)
    80006182:	37fd                	addiw	a5,a5,-1
    80006184:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006188:	854a                	mv	a0,s2
    8000618a:	ffffe097          	auipc	ra,0xffffe
    8000618e:	07e080e7          	jalr	126(ra) # 80004208 <iupdate>
  iunlockput(ip);
    80006192:	854a                	mv	a0,s2
    80006194:	ffffe097          	auipc	ra,0xffffe
    80006198:	3a0080e7          	jalr	928(ra) # 80004534 <iunlockput>
  end_op();
    8000619c:	fffff097          	auipc	ra,0xfffff
    800061a0:	b78080e7          	jalr	-1160(ra) # 80004d14 <end_op>
  return 0;
    800061a4:	4501                	li	a0,0
    800061a6:	a84d                	j	80006258 <sys_unlink+0x1c4>
    end_op();
    800061a8:	fffff097          	auipc	ra,0xfffff
    800061ac:	b6c080e7          	jalr	-1172(ra) # 80004d14 <end_op>
    return -1;
    800061b0:	557d                	li	a0,-1
    800061b2:	a05d                	j	80006258 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800061b4:	00002517          	auipc	a0,0x2
    800061b8:	6dc50513          	addi	a0,a0,1756 # 80008890 <syscalls+0x2d8>
    800061bc:	ffffa097          	auipc	ra,0xffffa
    800061c0:	388080e7          	jalr	904(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061c4:	04c92703          	lw	a4,76(s2)
    800061c8:	02000793          	li	a5,32
    800061cc:	f6e7f9e3          	bgeu	a5,a4,8000613e <sys_unlink+0xaa>
    800061d0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061d4:	4741                	li	a4,16
    800061d6:	86ce                	mv	a3,s3
    800061d8:	f1840613          	addi	a2,s0,-232
    800061dc:	4581                	li	a1,0
    800061de:	854a                	mv	a0,s2
    800061e0:	ffffe097          	auipc	ra,0xffffe
    800061e4:	3a6080e7          	jalr	934(ra) # 80004586 <readi>
    800061e8:	47c1                	li	a5,16
    800061ea:	00f51b63          	bne	a0,a5,80006200 <sys_unlink+0x16c>
    if(de.inum != 0)
    800061ee:	f1845783          	lhu	a5,-232(s0)
    800061f2:	e7a1                	bnez	a5,8000623a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800061f4:	29c1                	addiw	s3,s3,16
    800061f6:	04c92783          	lw	a5,76(s2)
    800061fa:	fcf9ede3          	bltu	s3,a5,800061d4 <sys_unlink+0x140>
    800061fe:	b781                	j	8000613e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006200:	00002517          	auipc	a0,0x2
    80006204:	6a850513          	addi	a0,a0,1704 # 800088a8 <syscalls+0x2f0>
    80006208:	ffffa097          	auipc	ra,0xffffa
    8000620c:	33c080e7          	jalr	828(ra) # 80000544 <panic>
    panic("unlink: writei");
    80006210:	00002517          	auipc	a0,0x2
    80006214:	6b050513          	addi	a0,a0,1712 # 800088c0 <syscalls+0x308>
    80006218:	ffffa097          	auipc	ra,0xffffa
    8000621c:	32c080e7          	jalr	812(ra) # 80000544 <panic>
    dp->nlink--;
    80006220:	04a4d783          	lhu	a5,74(s1)
    80006224:	37fd                	addiw	a5,a5,-1
    80006226:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000622a:	8526                	mv	a0,s1
    8000622c:	ffffe097          	auipc	ra,0xffffe
    80006230:	fdc080e7          	jalr	-36(ra) # 80004208 <iupdate>
    80006234:	b781                	j	80006174 <sys_unlink+0xe0>
    return -1;
    80006236:	557d                	li	a0,-1
    80006238:	a005                	j	80006258 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000623a:	854a                	mv	a0,s2
    8000623c:	ffffe097          	auipc	ra,0xffffe
    80006240:	2f8080e7          	jalr	760(ra) # 80004534 <iunlockput>
  iunlockput(dp);
    80006244:	8526                	mv	a0,s1
    80006246:	ffffe097          	auipc	ra,0xffffe
    8000624a:	2ee080e7          	jalr	750(ra) # 80004534 <iunlockput>
  end_op();
    8000624e:	fffff097          	auipc	ra,0xfffff
    80006252:	ac6080e7          	jalr	-1338(ra) # 80004d14 <end_op>
  return -1;
    80006256:	557d                	li	a0,-1
}
    80006258:	70ae                	ld	ra,232(sp)
    8000625a:	740e                	ld	s0,224(sp)
    8000625c:	64ee                	ld	s1,216(sp)
    8000625e:	694e                	ld	s2,208(sp)
    80006260:	69ae                	ld	s3,200(sp)
    80006262:	616d                	addi	sp,sp,240
    80006264:	8082                	ret

0000000080006266 <sys_open>:

uint64
sys_open(void)
{
    80006266:	7131                	addi	sp,sp,-192
    80006268:	fd06                	sd	ra,184(sp)
    8000626a:	f922                	sd	s0,176(sp)
    8000626c:	f526                	sd	s1,168(sp)
    8000626e:	f14a                	sd	s2,160(sp)
    80006270:	ed4e                	sd	s3,152(sp)
    80006272:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80006274:	f4c40593          	addi	a1,s0,-180
    80006278:	4505                	li	a0,1
    8000627a:	ffffd097          	auipc	ra,0xffffd
    8000627e:	1ea080e7          	jalr	490(ra) # 80003464 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006282:	08000613          	li	a2,128
    80006286:	f5040593          	addi	a1,s0,-176
    8000628a:	4501                	li	a0,0
    8000628c:	ffffd097          	auipc	ra,0xffffd
    80006290:	218080e7          	jalr	536(ra) # 800034a4 <argstr>
    80006294:	87aa                	mv	a5,a0
    return -1;
    80006296:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006298:	0a07c963          	bltz	a5,8000634a <sys_open+0xe4>

  begin_op();
    8000629c:	fffff097          	auipc	ra,0xfffff
    800062a0:	9f8080e7          	jalr	-1544(ra) # 80004c94 <begin_op>

  if(omode & O_CREATE){
    800062a4:	f4c42783          	lw	a5,-180(s0)
    800062a8:	2007f793          	andi	a5,a5,512
    800062ac:	cfc5                	beqz	a5,80006364 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800062ae:	4681                	li	a3,0
    800062b0:	4601                	li	a2,0
    800062b2:	4589                	li	a1,2
    800062b4:	f5040513          	addi	a0,s0,-176
    800062b8:	00000097          	auipc	ra,0x0
    800062bc:	972080e7          	jalr	-1678(ra) # 80005c2a <create>
    800062c0:	84aa                	mv	s1,a0
    if(ip == 0){
    800062c2:	c959                	beqz	a0,80006358 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800062c4:	04449703          	lh	a4,68(s1)
    800062c8:	478d                	li	a5,3
    800062ca:	00f71763          	bne	a4,a5,800062d8 <sys_open+0x72>
    800062ce:	0464d703          	lhu	a4,70(s1)
    800062d2:	47a5                	li	a5,9
    800062d4:	0ce7ed63          	bltu	a5,a4,800063ae <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800062d8:	fffff097          	auipc	ra,0xfffff
    800062dc:	dcc080e7          	jalr	-564(ra) # 800050a4 <filealloc>
    800062e0:	89aa                	mv	s3,a0
    800062e2:	10050363          	beqz	a0,800063e8 <sys_open+0x182>
    800062e6:	00000097          	auipc	ra,0x0
    800062ea:	902080e7          	jalr	-1790(ra) # 80005be8 <fdalloc>
    800062ee:	892a                	mv	s2,a0
    800062f0:	0e054763          	bltz	a0,800063de <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800062f4:	04449703          	lh	a4,68(s1)
    800062f8:	478d                	li	a5,3
    800062fa:	0cf70563          	beq	a4,a5,800063c4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800062fe:	4789                	li	a5,2
    80006300:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006304:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006308:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000630c:	f4c42783          	lw	a5,-180(s0)
    80006310:	0017c713          	xori	a4,a5,1
    80006314:	8b05                	andi	a4,a4,1
    80006316:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000631a:	0037f713          	andi	a4,a5,3
    8000631e:	00e03733          	snez	a4,a4
    80006322:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006326:	4007f793          	andi	a5,a5,1024
    8000632a:	c791                	beqz	a5,80006336 <sys_open+0xd0>
    8000632c:	04449703          	lh	a4,68(s1)
    80006330:	4789                	li	a5,2
    80006332:	0af70063          	beq	a4,a5,800063d2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006336:	8526                	mv	a0,s1
    80006338:	ffffe097          	auipc	ra,0xffffe
    8000633c:	05c080e7          	jalr	92(ra) # 80004394 <iunlock>
  end_op();
    80006340:	fffff097          	auipc	ra,0xfffff
    80006344:	9d4080e7          	jalr	-1580(ra) # 80004d14 <end_op>

  return fd;
    80006348:	854a                	mv	a0,s2
}
    8000634a:	70ea                	ld	ra,184(sp)
    8000634c:	744a                	ld	s0,176(sp)
    8000634e:	74aa                	ld	s1,168(sp)
    80006350:	790a                	ld	s2,160(sp)
    80006352:	69ea                	ld	s3,152(sp)
    80006354:	6129                	addi	sp,sp,192
    80006356:	8082                	ret
      end_op();
    80006358:	fffff097          	auipc	ra,0xfffff
    8000635c:	9bc080e7          	jalr	-1604(ra) # 80004d14 <end_op>
      return -1;
    80006360:	557d                	li	a0,-1
    80006362:	b7e5                	j	8000634a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006364:	f5040513          	addi	a0,s0,-176
    80006368:	ffffe097          	auipc	ra,0xffffe
    8000636c:	710080e7          	jalr	1808(ra) # 80004a78 <namei>
    80006370:	84aa                	mv	s1,a0
    80006372:	c905                	beqz	a0,800063a2 <sys_open+0x13c>
    ilock(ip);
    80006374:	ffffe097          	auipc	ra,0xffffe
    80006378:	f5e080e7          	jalr	-162(ra) # 800042d2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000637c:	04449703          	lh	a4,68(s1)
    80006380:	4785                	li	a5,1
    80006382:	f4f711e3          	bne	a4,a5,800062c4 <sys_open+0x5e>
    80006386:	f4c42783          	lw	a5,-180(s0)
    8000638a:	d7b9                	beqz	a5,800062d8 <sys_open+0x72>
      iunlockput(ip);
    8000638c:	8526                	mv	a0,s1
    8000638e:	ffffe097          	auipc	ra,0xffffe
    80006392:	1a6080e7          	jalr	422(ra) # 80004534 <iunlockput>
      end_op();
    80006396:	fffff097          	auipc	ra,0xfffff
    8000639a:	97e080e7          	jalr	-1666(ra) # 80004d14 <end_op>
      return -1;
    8000639e:	557d                	li	a0,-1
    800063a0:	b76d                	j	8000634a <sys_open+0xe4>
      end_op();
    800063a2:	fffff097          	auipc	ra,0xfffff
    800063a6:	972080e7          	jalr	-1678(ra) # 80004d14 <end_op>
      return -1;
    800063aa:	557d                	li	a0,-1
    800063ac:	bf79                	j	8000634a <sys_open+0xe4>
    iunlockput(ip);
    800063ae:	8526                	mv	a0,s1
    800063b0:	ffffe097          	auipc	ra,0xffffe
    800063b4:	184080e7          	jalr	388(ra) # 80004534 <iunlockput>
    end_op();
    800063b8:	fffff097          	auipc	ra,0xfffff
    800063bc:	95c080e7          	jalr	-1700(ra) # 80004d14 <end_op>
    return -1;
    800063c0:	557d                	li	a0,-1
    800063c2:	b761                	j	8000634a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800063c4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800063c8:	04649783          	lh	a5,70(s1)
    800063cc:	02f99223          	sh	a5,36(s3)
    800063d0:	bf25                	j	80006308 <sys_open+0xa2>
    itrunc(ip);
    800063d2:	8526                	mv	a0,s1
    800063d4:	ffffe097          	auipc	ra,0xffffe
    800063d8:	00c080e7          	jalr	12(ra) # 800043e0 <itrunc>
    800063dc:	bfa9                	j	80006336 <sys_open+0xd0>
      fileclose(f);
    800063de:	854e                	mv	a0,s3
    800063e0:	fffff097          	auipc	ra,0xfffff
    800063e4:	d80080e7          	jalr	-640(ra) # 80005160 <fileclose>
    iunlockput(ip);
    800063e8:	8526                	mv	a0,s1
    800063ea:	ffffe097          	auipc	ra,0xffffe
    800063ee:	14a080e7          	jalr	330(ra) # 80004534 <iunlockput>
    end_op();
    800063f2:	fffff097          	auipc	ra,0xfffff
    800063f6:	922080e7          	jalr	-1758(ra) # 80004d14 <end_op>
    return -1;
    800063fa:	557d                	li	a0,-1
    800063fc:	b7b9                	j	8000634a <sys_open+0xe4>

00000000800063fe <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800063fe:	7175                	addi	sp,sp,-144
    80006400:	e506                	sd	ra,136(sp)
    80006402:	e122                	sd	s0,128(sp)
    80006404:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006406:	fffff097          	auipc	ra,0xfffff
    8000640a:	88e080e7          	jalr	-1906(ra) # 80004c94 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000640e:	08000613          	li	a2,128
    80006412:	f7040593          	addi	a1,s0,-144
    80006416:	4501                	li	a0,0
    80006418:	ffffd097          	auipc	ra,0xffffd
    8000641c:	08c080e7          	jalr	140(ra) # 800034a4 <argstr>
    80006420:	02054963          	bltz	a0,80006452 <sys_mkdir+0x54>
    80006424:	4681                	li	a3,0
    80006426:	4601                	li	a2,0
    80006428:	4585                	li	a1,1
    8000642a:	f7040513          	addi	a0,s0,-144
    8000642e:	fffff097          	auipc	ra,0xfffff
    80006432:	7fc080e7          	jalr	2044(ra) # 80005c2a <create>
    80006436:	cd11                	beqz	a0,80006452 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006438:	ffffe097          	auipc	ra,0xffffe
    8000643c:	0fc080e7          	jalr	252(ra) # 80004534 <iunlockput>
  end_op();
    80006440:	fffff097          	auipc	ra,0xfffff
    80006444:	8d4080e7          	jalr	-1836(ra) # 80004d14 <end_op>
  return 0;
    80006448:	4501                	li	a0,0
}
    8000644a:	60aa                	ld	ra,136(sp)
    8000644c:	640a                	ld	s0,128(sp)
    8000644e:	6149                	addi	sp,sp,144
    80006450:	8082                	ret
    end_op();
    80006452:	fffff097          	auipc	ra,0xfffff
    80006456:	8c2080e7          	jalr	-1854(ra) # 80004d14 <end_op>
    return -1;
    8000645a:	557d                	li	a0,-1
    8000645c:	b7fd                	j	8000644a <sys_mkdir+0x4c>

000000008000645e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000645e:	7135                	addi	sp,sp,-160
    80006460:	ed06                	sd	ra,152(sp)
    80006462:	e922                	sd	s0,144(sp)
    80006464:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006466:	fffff097          	auipc	ra,0xfffff
    8000646a:	82e080e7          	jalr	-2002(ra) # 80004c94 <begin_op>
  argint(1, &major);
    8000646e:	f6c40593          	addi	a1,s0,-148
    80006472:	4505                	li	a0,1
    80006474:	ffffd097          	auipc	ra,0xffffd
    80006478:	ff0080e7          	jalr	-16(ra) # 80003464 <argint>
  argint(2, &minor);
    8000647c:	f6840593          	addi	a1,s0,-152
    80006480:	4509                	li	a0,2
    80006482:	ffffd097          	auipc	ra,0xffffd
    80006486:	fe2080e7          	jalr	-30(ra) # 80003464 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000648a:	08000613          	li	a2,128
    8000648e:	f7040593          	addi	a1,s0,-144
    80006492:	4501                	li	a0,0
    80006494:	ffffd097          	auipc	ra,0xffffd
    80006498:	010080e7          	jalr	16(ra) # 800034a4 <argstr>
    8000649c:	02054b63          	bltz	a0,800064d2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800064a0:	f6841683          	lh	a3,-152(s0)
    800064a4:	f6c41603          	lh	a2,-148(s0)
    800064a8:	458d                	li	a1,3
    800064aa:	f7040513          	addi	a0,s0,-144
    800064ae:	fffff097          	auipc	ra,0xfffff
    800064b2:	77c080e7          	jalr	1916(ra) # 80005c2a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800064b6:	cd11                	beqz	a0,800064d2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800064b8:	ffffe097          	auipc	ra,0xffffe
    800064bc:	07c080e7          	jalr	124(ra) # 80004534 <iunlockput>
  end_op();
    800064c0:	fffff097          	auipc	ra,0xfffff
    800064c4:	854080e7          	jalr	-1964(ra) # 80004d14 <end_op>
  return 0;
    800064c8:	4501                	li	a0,0
}
    800064ca:	60ea                	ld	ra,152(sp)
    800064cc:	644a                	ld	s0,144(sp)
    800064ce:	610d                	addi	sp,sp,160
    800064d0:	8082                	ret
    end_op();
    800064d2:	fffff097          	auipc	ra,0xfffff
    800064d6:	842080e7          	jalr	-1982(ra) # 80004d14 <end_op>
    return -1;
    800064da:	557d                	li	a0,-1
    800064dc:	b7fd                	j	800064ca <sys_mknod+0x6c>

00000000800064de <sys_chdir>:

uint64
sys_chdir(void)
{
    800064de:	7135                	addi	sp,sp,-160
    800064e0:	ed06                	sd	ra,152(sp)
    800064e2:	e922                	sd	s0,144(sp)
    800064e4:	e526                	sd	s1,136(sp)
    800064e6:	e14a                	sd	s2,128(sp)
    800064e8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800064ea:	ffffb097          	auipc	ra,0xffffb
    800064ee:	6b8080e7          	jalr	1720(ra) # 80001ba2 <myproc>
    800064f2:	892a                	mv	s2,a0
  
  begin_op();
    800064f4:	ffffe097          	auipc	ra,0xffffe
    800064f8:	7a0080e7          	jalr	1952(ra) # 80004c94 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800064fc:	08000613          	li	a2,128
    80006500:	f6040593          	addi	a1,s0,-160
    80006504:	4501                	li	a0,0
    80006506:	ffffd097          	auipc	ra,0xffffd
    8000650a:	f9e080e7          	jalr	-98(ra) # 800034a4 <argstr>
    8000650e:	04054b63          	bltz	a0,80006564 <sys_chdir+0x86>
    80006512:	f6040513          	addi	a0,s0,-160
    80006516:	ffffe097          	auipc	ra,0xffffe
    8000651a:	562080e7          	jalr	1378(ra) # 80004a78 <namei>
    8000651e:	84aa                	mv	s1,a0
    80006520:	c131                	beqz	a0,80006564 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006522:	ffffe097          	auipc	ra,0xffffe
    80006526:	db0080e7          	jalr	-592(ra) # 800042d2 <ilock>
  if(ip->type != T_DIR){
    8000652a:	04449703          	lh	a4,68(s1)
    8000652e:	4785                	li	a5,1
    80006530:	04f71063          	bne	a4,a5,80006570 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006534:	8526                	mv	a0,s1
    80006536:	ffffe097          	auipc	ra,0xffffe
    8000653a:	e5e080e7          	jalr	-418(ra) # 80004394 <iunlock>
  iput(p->cwd);
    8000653e:	19093503          	ld	a0,400(s2)
    80006542:	ffffe097          	auipc	ra,0xffffe
    80006546:	f4a080e7          	jalr	-182(ra) # 8000448c <iput>
  end_op();
    8000654a:	ffffe097          	auipc	ra,0xffffe
    8000654e:	7ca080e7          	jalr	1994(ra) # 80004d14 <end_op>
  p->cwd = ip;
    80006552:	18993823          	sd	s1,400(s2)
  return 0;
    80006556:	4501                	li	a0,0
}
    80006558:	60ea                	ld	ra,152(sp)
    8000655a:	644a                	ld	s0,144(sp)
    8000655c:	64aa                	ld	s1,136(sp)
    8000655e:	690a                	ld	s2,128(sp)
    80006560:	610d                	addi	sp,sp,160
    80006562:	8082                	ret
    end_op();
    80006564:	ffffe097          	auipc	ra,0xffffe
    80006568:	7b0080e7          	jalr	1968(ra) # 80004d14 <end_op>
    return -1;
    8000656c:	557d                	li	a0,-1
    8000656e:	b7ed                	j	80006558 <sys_chdir+0x7a>
    iunlockput(ip);
    80006570:	8526                	mv	a0,s1
    80006572:	ffffe097          	auipc	ra,0xffffe
    80006576:	fc2080e7          	jalr	-62(ra) # 80004534 <iunlockput>
    end_op();
    8000657a:	ffffe097          	auipc	ra,0xffffe
    8000657e:	79a080e7          	jalr	1946(ra) # 80004d14 <end_op>
    return -1;
    80006582:	557d                	li	a0,-1
    80006584:	bfd1                	j	80006558 <sys_chdir+0x7a>

0000000080006586 <sys_exec>:

uint64
sys_exec(void)
{
    80006586:	7145                	addi	sp,sp,-464
    80006588:	e786                	sd	ra,456(sp)
    8000658a:	e3a2                	sd	s0,448(sp)
    8000658c:	ff26                	sd	s1,440(sp)
    8000658e:	fb4a                	sd	s2,432(sp)
    80006590:	f74e                	sd	s3,424(sp)
    80006592:	f352                	sd	s4,416(sp)
    80006594:	ef56                	sd	s5,408(sp)
    80006596:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006598:	e3840593          	addi	a1,s0,-456
    8000659c:	4505                	li	a0,1
    8000659e:	ffffd097          	auipc	ra,0xffffd
    800065a2:	ee6080e7          	jalr	-282(ra) # 80003484 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800065a6:	08000613          	li	a2,128
    800065aa:	f4040593          	addi	a1,s0,-192
    800065ae:	4501                	li	a0,0
    800065b0:	ffffd097          	auipc	ra,0xffffd
    800065b4:	ef4080e7          	jalr	-268(ra) # 800034a4 <argstr>
    800065b8:	87aa                	mv	a5,a0
    return -1;
    800065ba:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800065bc:	0c07c263          	bltz	a5,80006680 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800065c0:	10000613          	li	a2,256
    800065c4:	4581                	li	a1,0
    800065c6:	e4040513          	addi	a0,s0,-448
    800065ca:	ffffb097          	auipc	ra,0xffffb
    800065ce:	8b6080e7          	jalr	-1866(ra) # 80000e80 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800065d2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800065d6:	89a6                	mv	s3,s1
    800065d8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800065da:	02000a13          	li	s4,32
    800065de:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800065e2:	00391513          	slli	a0,s2,0x3
    800065e6:	e3040593          	addi	a1,s0,-464
    800065ea:	e3843783          	ld	a5,-456(s0)
    800065ee:	953e                	add	a0,a0,a5
    800065f0:	ffffd097          	auipc	ra,0xffffd
    800065f4:	dd6080e7          	jalr	-554(ra) # 800033c6 <fetchaddr>
    800065f8:	02054a63          	bltz	a0,8000662c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800065fc:	e3043783          	ld	a5,-464(s0)
    80006600:	c3b9                	beqz	a5,80006646 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006602:	ffffa097          	auipc	ra,0xffffa
    80006606:	67e080e7          	jalr	1662(ra) # 80000c80 <kalloc>
    8000660a:	85aa                	mv	a1,a0
    8000660c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006610:	cd11                	beqz	a0,8000662c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006612:	6605                	lui	a2,0x1
    80006614:	e3043503          	ld	a0,-464(s0)
    80006618:	ffffd097          	auipc	ra,0xffffd
    8000661c:	e00080e7          	jalr	-512(ra) # 80003418 <fetchstr>
    80006620:	00054663          	bltz	a0,8000662c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006624:	0905                	addi	s2,s2,1
    80006626:	09a1                	addi	s3,s3,8
    80006628:	fb491be3          	bne	s2,s4,800065de <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000662c:	10048913          	addi	s2,s1,256
    80006630:	6088                	ld	a0,0(s1)
    80006632:	c531                	beqz	a0,8000667e <sys_exec+0xf8>
    kfree(argv[i]);
    80006634:	ffffa097          	auipc	ra,0xffffa
    80006638:	508080e7          	jalr	1288(ra) # 80000b3c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000663c:	04a1                	addi	s1,s1,8
    8000663e:	ff2499e3          	bne	s1,s2,80006630 <sys_exec+0xaa>
  return -1;
    80006642:	557d                	li	a0,-1
    80006644:	a835                	j	80006680 <sys_exec+0xfa>
      argv[i] = 0;
    80006646:	0a8e                	slli	s5,s5,0x3
    80006648:	fc040793          	addi	a5,s0,-64
    8000664c:	9abe                	add	s5,s5,a5
    8000664e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006652:	e4040593          	addi	a1,s0,-448
    80006656:	f4040513          	addi	a0,s0,-192
    8000665a:	fffff097          	auipc	ra,0xfffff
    8000665e:	18e080e7          	jalr	398(ra) # 800057e8 <exec>
    80006662:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006664:	10048993          	addi	s3,s1,256
    80006668:	6088                	ld	a0,0(s1)
    8000666a:	c901                	beqz	a0,8000667a <sys_exec+0xf4>
    kfree(argv[i]);
    8000666c:	ffffa097          	auipc	ra,0xffffa
    80006670:	4d0080e7          	jalr	1232(ra) # 80000b3c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006674:	04a1                	addi	s1,s1,8
    80006676:	ff3499e3          	bne	s1,s3,80006668 <sys_exec+0xe2>
  return ret;
    8000667a:	854a                	mv	a0,s2
    8000667c:	a011                	j	80006680 <sys_exec+0xfa>
  return -1;
    8000667e:	557d                	li	a0,-1
}
    80006680:	60be                	ld	ra,456(sp)
    80006682:	641e                	ld	s0,448(sp)
    80006684:	74fa                	ld	s1,440(sp)
    80006686:	795a                	ld	s2,432(sp)
    80006688:	79ba                	ld	s3,424(sp)
    8000668a:	7a1a                	ld	s4,416(sp)
    8000668c:	6afa                	ld	s5,408(sp)
    8000668e:	6179                	addi	sp,sp,464
    80006690:	8082                	ret

0000000080006692 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006692:	7139                	addi	sp,sp,-64
    80006694:	fc06                	sd	ra,56(sp)
    80006696:	f822                	sd	s0,48(sp)
    80006698:	f426                	sd	s1,40(sp)
    8000669a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000669c:	ffffb097          	auipc	ra,0xffffb
    800066a0:	506080e7          	jalr	1286(ra) # 80001ba2 <myproc>
    800066a4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800066a6:	fd840593          	addi	a1,s0,-40
    800066aa:	4501                	li	a0,0
    800066ac:	ffffd097          	auipc	ra,0xffffd
    800066b0:	dd8080e7          	jalr	-552(ra) # 80003484 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800066b4:	fc840593          	addi	a1,s0,-56
    800066b8:	fd040513          	addi	a0,s0,-48
    800066bc:	fffff097          	auipc	ra,0xfffff
    800066c0:	dd4080e7          	jalr	-556(ra) # 80005490 <pipealloc>
    return -1;
    800066c4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800066c6:	0c054763          	bltz	a0,80006794 <sys_pipe+0x102>
  fd0 = -1;
    800066ca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800066ce:	fd043503          	ld	a0,-48(s0)
    800066d2:	fffff097          	auipc	ra,0xfffff
    800066d6:	516080e7          	jalr	1302(ra) # 80005be8 <fdalloc>
    800066da:	fca42223          	sw	a0,-60(s0)
    800066de:	08054e63          	bltz	a0,8000677a <sys_pipe+0xe8>
    800066e2:	fc843503          	ld	a0,-56(s0)
    800066e6:	fffff097          	auipc	ra,0xfffff
    800066ea:	502080e7          	jalr	1282(ra) # 80005be8 <fdalloc>
    800066ee:	fca42023          	sw	a0,-64(s0)
    800066f2:	06054a63          	bltz	a0,80006766 <sys_pipe+0xd4>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800066f6:	4691                	li	a3,4
    800066f8:	fc440613          	addi	a2,s0,-60
    800066fc:	fd843583          	ld	a1,-40(s0)
    80006700:	64c8                	ld	a0,136(s1)
    80006702:	ffffb097          	auipc	ra,0xffffb
    80006706:	126080e7          	jalr	294(ra) # 80001828 <copyout>
    8000670a:	02054063          	bltz	a0,8000672a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000670e:	4691                	li	a3,4
    80006710:	fc040613          	addi	a2,s0,-64
    80006714:	fd843583          	ld	a1,-40(s0)
    80006718:	0591                	addi	a1,a1,4
    8000671a:	64c8                	ld	a0,136(s1)
    8000671c:	ffffb097          	auipc	ra,0xffffb
    80006720:	10c080e7          	jalr	268(ra) # 80001828 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006724:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006726:	06055763          	bgez	a0,80006794 <sys_pipe+0x102>
    p->ofile[fd0] = 0;
    8000672a:	fc442783          	lw	a5,-60(s0)
    8000672e:	02278793          	addi	a5,a5,34
    80006732:	078e                	slli	a5,a5,0x3
    80006734:	97a6                	add	a5,a5,s1
    80006736:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000673a:	fc042503          	lw	a0,-64(s0)
    8000673e:	02250513          	addi	a0,a0,34
    80006742:	050e                	slli	a0,a0,0x3
    80006744:	94aa                	add	s1,s1,a0
    80006746:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000674a:	fd043503          	ld	a0,-48(s0)
    8000674e:	fffff097          	auipc	ra,0xfffff
    80006752:	a12080e7          	jalr	-1518(ra) # 80005160 <fileclose>
    fileclose(wf);
    80006756:	fc843503          	ld	a0,-56(s0)
    8000675a:	fffff097          	auipc	ra,0xfffff
    8000675e:	a06080e7          	jalr	-1530(ra) # 80005160 <fileclose>
    return -1;
    80006762:	57fd                	li	a5,-1
    80006764:	a805                	j	80006794 <sys_pipe+0x102>
    if(fd0 >= 0)
    80006766:	fc442783          	lw	a5,-60(s0)
    8000676a:	0007c863          	bltz	a5,8000677a <sys_pipe+0xe8>
      p->ofile[fd0] = 0;
    8000676e:	02278793          	addi	a5,a5,34
    80006772:	078e                	slli	a5,a5,0x3
    80006774:	94be                	add	s1,s1,a5
    80006776:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000677a:	fd043503          	ld	a0,-48(s0)
    8000677e:	fffff097          	auipc	ra,0xfffff
    80006782:	9e2080e7          	jalr	-1566(ra) # 80005160 <fileclose>
    fileclose(wf);
    80006786:	fc843503          	ld	a0,-56(s0)
    8000678a:	fffff097          	auipc	ra,0xfffff
    8000678e:	9d6080e7          	jalr	-1578(ra) # 80005160 <fileclose>
    return -1;
    80006792:	57fd                	li	a5,-1
}
    80006794:	853e                	mv	a0,a5
    80006796:	70e2                	ld	ra,56(sp)
    80006798:	7442                	ld	s0,48(sp)
    8000679a:	74a2                	ld	s1,40(sp)
    8000679c:	6121                	addi	sp,sp,64
    8000679e:	8082                	ret

00000000800067a0 <kernelvec>:
    800067a0:	7111                	addi	sp,sp,-256
    800067a2:	e006                	sd	ra,0(sp)
    800067a4:	e40a                	sd	sp,8(sp)
    800067a6:	e80e                	sd	gp,16(sp)
    800067a8:	ec12                	sd	tp,24(sp)
    800067aa:	f016                	sd	t0,32(sp)
    800067ac:	f41a                	sd	t1,40(sp)
    800067ae:	f81e                	sd	t2,48(sp)
    800067b0:	fc22                	sd	s0,56(sp)
    800067b2:	e0a6                	sd	s1,64(sp)
    800067b4:	e4aa                	sd	a0,72(sp)
    800067b6:	e8ae                	sd	a1,80(sp)
    800067b8:	ecb2                	sd	a2,88(sp)
    800067ba:	f0b6                	sd	a3,96(sp)
    800067bc:	f4ba                	sd	a4,104(sp)
    800067be:	f8be                	sd	a5,112(sp)
    800067c0:	fcc2                	sd	a6,120(sp)
    800067c2:	e146                	sd	a7,128(sp)
    800067c4:	e54a                	sd	s2,136(sp)
    800067c6:	e94e                	sd	s3,144(sp)
    800067c8:	ed52                	sd	s4,152(sp)
    800067ca:	f156                	sd	s5,160(sp)
    800067cc:	f55a                	sd	s6,168(sp)
    800067ce:	f95e                	sd	s7,176(sp)
    800067d0:	fd62                	sd	s8,184(sp)
    800067d2:	e1e6                	sd	s9,192(sp)
    800067d4:	e5ea                	sd	s10,200(sp)
    800067d6:	e9ee                	sd	s11,208(sp)
    800067d8:	edf2                	sd	t3,216(sp)
    800067da:	f1f6                	sd	t4,224(sp)
    800067dc:	f5fa                	sd	t5,232(sp)
    800067de:	f9fe                	sd	t6,240(sp)
    800067e0:	981fc0ef          	jal	ra,80003160 <kerneltrap>
    800067e4:	6082                	ld	ra,0(sp)
    800067e6:	6122                	ld	sp,8(sp)
    800067e8:	61c2                	ld	gp,16(sp)
    800067ea:	7282                	ld	t0,32(sp)
    800067ec:	7322                	ld	t1,40(sp)
    800067ee:	73c2                	ld	t2,48(sp)
    800067f0:	7462                	ld	s0,56(sp)
    800067f2:	6486                	ld	s1,64(sp)
    800067f4:	6526                	ld	a0,72(sp)
    800067f6:	65c6                	ld	a1,80(sp)
    800067f8:	6666                	ld	a2,88(sp)
    800067fa:	7686                	ld	a3,96(sp)
    800067fc:	7726                	ld	a4,104(sp)
    800067fe:	77c6                	ld	a5,112(sp)
    80006800:	7866                	ld	a6,120(sp)
    80006802:	688a                	ld	a7,128(sp)
    80006804:	692a                	ld	s2,136(sp)
    80006806:	69ca                	ld	s3,144(sp)
    80006808:	6a6a                	ld	s4,152(sp)
    8000680a:	7a8a                	ld	s5,160(sp)
    8000680c:	7b2a                	ld	s6,168(sp)
    8000680e:	7bca                	ld	s7,176(sp)
    80006810:	7c6a                	ld	s8,184(sp)
    80006812:	6c8e                	ld	s9,192(sp)
    80006814:	6d2e                	ld	s10,200(sp)
    80006816:	6dce                	ld	s11,208(sp)
    80006818:	6e6e                	ld	t3,216(sp)
    8000681a:	7e8e                	ld	t4,224(sp)
    8000681c:	7f2e                	ld	t5,232(sp)
    8000681e:	7fce                	ld	t6,240(sp)
    80006820:	6111                	addi	sp,sp,256
    80006822:	10200073          	sret
    80006826:	00000013          	nop
    8000682a:	00000013          	nop
    8000682e:	0001                	nop

0000000080006830 <timervec>:
    80006830:	34051573          	csrrw	a0,mscratch,a0
    80006834:	e10c                	sd	a1,0(a0)
    80006836:	e510                	sd	a2,8(a0)
    80006838:	e914                	sd	a3,16(a0)
    8000683a:	6d0c                	ld	a1,24(a0)
    8000683c:	7110                	ld	a2,32(a0)
    8000683e:	6194                	ld	a3,0(a1)
    80006840:	96b2                	add	a3,a3,a2
    80006842:	e194                	sd	a3,0(a1)
    80006844:	4589                	li	a1,2
    80006846:	14459073          	csrw	sip,a1
    8000684a:	6914                	ld	a3,16(a0)
    8000684c:	6510                	ld	a2,8(a0)
    8000684e:	610c                	ld	a1,0(a0)
    80006850:	34051573          	csrrw	a0,mscratch,a0
    80006854:	30200073          	mret
	...

000000008000685a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000685a:	1141                	addi	sp,sp,-16
    8000685c:	e422                	sd	s0,8(sp)
    8000685e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006860:	0c0007b7          	lui	a5,0xc000
    80006864:	4705                	li	a4,1
    80006866:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006868:	c3d8                	sw	a4,4(a5)
}
    8000686a:	6422                	ld	s0,8(sp)
    8000686c:	0141                	addi	sp,sp,16
    8000686e:	8082                	ret

0000000080006870 <plicinithart>:

void
plicinithart(void)
{
    80006870:	1141                	addi	sp,sp,-16
    80006872:	e406                	sd	ra,8(sp)
    80006874:	e022                	sd	s0,0(sp)
    80006876:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006878:	ffffb097          	auipc	ra,0xffffb
    8000687c:	2fe080e7          	jalr	766(ra) # 80001b76 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006880:	0085171b          	slliw	a4,a0,0x8
    80006884:	0c0027b7          	lui	a5,0xc002
    80006888:	97ba                	add	a5,a5,a4
    8000688a:	40200713          	li	a4,1026
    8000688e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006892:	00d5151b          	slliw	a0,a0,0xd
    80006896:	0c2017b7          	lui	a5,0xc201
    8000689a:	953e                	add	a0,a0,a5
    8000689c:	00052023          	sw	zero,0(a0)
}
    800068a0:	60a2                	ld	ra,8(sp)
    800068a2:	6402                	ld	s0,0(sp)
    800068a4:	0141                	addi	sp,sp,16
    800068a6:	8082                	ret

00000000800068a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800068a8:	1141                	addi	sp,sp,-16
    800068aa:	e406                	sd	ra,8(sp)
    800068ac:	e022                	sd	s0,0(sp)
    800068ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800068b0:	ffffb097          	auipc	ra,0xffffb
    800068b4:	2c6080e7          	jalr	710(ra) # 80001b76 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800068b8:	00d5179b          	slliw	a5,a0,0xd
    800068bc:	0c201537          	lui	a0,0xc201
    800068c0:	953e                	add	a0,a0,a5
  return irq;
}
    800068c2:	4148                	lw	a0,4(a0)
    800068c4:	60a2                	ld	ra,8(sp)
    800068c6:	6402                	ld	s0,0(sp)
    800068c8:	0141                	addi	sp,sp,16
    800068ca:	8082                	ret

00000000800068cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800068cc:	1101                	addi	sp,sp,-32
    800068ce:	ec06                	sd	ra,24(sp)
    800068d0:	e822                	sd	s0,16(sp)
    800068d2:	e426                	sd	s1,8(sp)
    800068d4:	1000                	addi	s0,sp,32
    800068d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800068d8:	ffffb097          	auipc	ra,0xffffb
    800068dc:	29e080e7          	jalr	670(ra) # 80001b76 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800068e0:	00d5151b          	slliw	a0,a0,0xd
    800068e4:	0c2017b7          	lui	a5,0xc201
    800068e8:	97aa                	add	a5,a5,a0
    800068ea:	c3c4                	sw	s1,4(a5)
}
    800068ec:	60e2                	ld	ra,24(sp)
    800068ee:	6442                	ld	s0,16(sp)
    800068f0:	64a2                	ld	s1,8(sp)
    800068f2:	6105                	addi	sp,sp,32
    800068f4:	8082                	ret

00000000800068f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800068f6:	1141                	addi	sp,sp,-16
    800068f8:	e406                	sd	ra,8(sp)
    800068fa:	e022                	sd	s0,0(sp)
    800068fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800068fe:	479d                	li	a5,7
    80006900:	04a7cc63          	blt	a5,a0,80006958 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006904:	0023d797          	auipc	a5,0x23d
    80006908:	c2478793          	addi	a5,a5,-988 # 80243528 <disk>
    8000690c:	97aa                	add	a5,a5,a0
    8000690e:	0187c783          	lbu	a5,24(a5)
    80006912:	ebb9                	bnez	a5,80006968 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006914:	00451613          	slli	a2,a0,0x4
    80006918:	0023d797          	auipc	a5,0x23d
    8000691c:	c1078793          	addi	a5,a5,-1008 # 80243528 <disk>
    80006920:	6394                	ld	a3,0(a5)
    80006922:	96b2                	add	a3,a3,a2
    80006924:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006928:	6398                	ld	a4,0(a5)
    8000692a:	9732                	add	a4,a4,a2
    8000692c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006930:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006934:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006938:	953e                	add	a0,a0,a5
    8000693a:	4785                	li	a5,1
    8000693c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006940:	0023d517          	auipc	a0,0x23d
    80006944:	c0050513          	addi	a0,a0,-1024 # 80243540 <disk+0x18>
    80006948:	ffffc097          	auipc	ra,0xffffc
    8000694c:	c84080e7          	jalr	-892(ra) # 800025cc <wakeup>
}
    80006950:	60a2                	ld	ra,8(sp)
    80006952:	6402                	ld	s0,0(sp)
    80006954:	0141                	addi	sp,sp,16
    80006956:	8082                	ret
    panic("free_desc 1");
    80006958:	00002517          	auipc	a0,0x2
    8000695c:	f7850513          	addi	a0,a0,-136 # 800088d0 <syscalls+0x318>
    80006960:	ffffa097          	auipc	ra,0xffffa
    80006964:	be4080e7          	jalr	-1052(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006968:	00002517          	auipc	a0,0x2
    8000696c:	f7850513          	addi	a0,a0,-136 # 800088e0 <syscalls+0x328>
    80006970:	ffffa097          	auipc	ra,0xffffa
    80006974:	bd4080e7          	jalr	-1068(ra) # 80000544 <panic>

0000000080006978 <virtio_disk_init>:
{
    80006978:	1101                	addi	sp,sp,-32
    8000697a:	ec06                	sd	ra,24(sp)
    8000697c:	e822                	sd	s0,16(sp)
    8000697e:	e426                	sd	s1,8(sp)
    80006980:	e04a                	sd	s2,0(sp)
    80006982:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006984:	00002597          	auipc	a1,0x2
    80006988:	f6c58593          	addi	a1,a1,-148 # 800088f0 <syscalls+0x338>
    8000698c:	0023d517          	auipc	a0,0x23d
    80006990:	cc450513          	addi	a0,a0,-828 # 80243650 <disk+0x128>
    80006994:	ffffa097          	auipc	ra,0xffffa
    80006998:	360080e7          	jalr	864(ra) # 80000cf4 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000699c:	100017b7          	lui	a5,0x10001
    800069a0:	4398                	lw	a4,0(a5)
    800069a2:	2701                	sext.w	a4,a4
    800069a4:	747277b7          	lui	a5,0x74727
    800069a8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800069ac:	14f71e63          	bne	a4,a5,80006b08 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800069b0:	100017b7          	lui	a5,0x10001
    800069b4:	43dc                	lw	a5,4(a5)
    800069b6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069b8:	4709                	li	a4,2
    800069ba:	14e79763          	bne	a5,a4,80006b08 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800069be:	100017b7          	lui	a5,0x10001
    800069c2:	479c                	lw	a5,8(a5)
    800069c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800069c6:	14e79163          	bne	a5,a4,80006b08 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800069ca:	100017b7          	lui	a5,0x10001
    800069ce:	47d8                	lw	a4,12(a5)
    800069d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800069d2:	554d47b7          	lui	a5,0x554d4
    800069d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800069da:	12f71763          	bne	a4,a5,80006b08 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    800069de:	100017b7          	lui	a5,0x10001
    800069e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800069e6:	4705                	li	a4,1
    800069e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069ea:	470d                	li	a4,3
    800069ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800069ee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800069f0:	c7ffe737          	lui	a4,0xc7ffe
    800069f4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47dbb0f7>
    800069f8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800069fa:	2701                	sext.w	a4,a4
    800069fc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800069fe:	472d                	li	a4,11
    80006a00:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006a02:	0707a903          	lw	s2,112(a5)
    80006a06:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006a08:	00897793          	andi	a5,s2,8
    80006a0c:	10078663          	beqz	a5,80006b18 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006a10:	100017b7          	lui	a5,0x10001
    80006a14:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006a18:	43fc                	lw	a5,68(a5)
    80006a1a:	2781                	sext.w	a5,a5
    80006a1c:	10079663          	bnez	a5,80006b28 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006a20:	100017b7          	lui	a5,0x10001
    80006a24:	5bdc                	lw	a5,52(a5)
    80006a26:	2781                	sext.w	a5,a5
  if(max == 0)
    80006a28:	10078863          	beqz	a5,80006b38 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80006a2c:	471d                	li	a4,7
    80006a2e:	10f77d63          	bgeu	a4,a5,80006b48 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006a32:	ffffa097          	auipc	ra,0xffffa
    80006a36:	24e080e7          	jalr	590(ra) # 80000c80 <kalloc>
    80006a3a:	0023d497          	auipc	s1,0x23d
    80006a3e:	aee48493          	addi	s1,s1,-1298 # 80243528 <disk>
    80006a42:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006a44:	ffffa097          	auipc	ra,0xffffa
    80006a48:	23c080e7          	jalr	572(ra) # 80000c80 <kalloc>
    80006a4c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006a4e:	ffffa097          	auipc	ra,0xffffa
    80006a52:	232080e7          	jalr	562(ra) # 80000c80 <kalloc>
    80006a56:	87aa                	mv	a5,a0
    80006a58:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006a5a:	6088                	ld	a0,0(s1)
    80006a5c:	cd75                	beqz	a0,80006b58 <virtio_disk_init+0x1e0>
    80006a5e:	0023d717          	auipc	a4,0x23d
    80006a62:	ad273703          	ld	a4,-1326(a4) # 80243530 <disk+0x8>
    80006a66:	cb6d                	beqz	a4,80006b58 <virtio_disk_init+0x1e0>
    80006a68:	cbe5                	beqz	a5,80006b58 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80006a6a:	6605                	lui	a2,0x1
    80006a6c:	4581                	li	a1,0
    80006a6e:	ffffa097          	auipc	ra,0xffffa
    80006a72:	412080e7          	jalr	1042(ra) # 80000e80 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006a76:	0023d497          	auipc	s1,0x23d
    80006a7a:	ab248493          	addi	s1,s1,-1358 # 80243528 <disk>
    80006a7e:	6605                	lui	a2,0x1
    80006a80:	4581                	li	a1,0
    80006a82:	6488                	ld	a0,8(s1)
    80006a84:	ffffa097          	auipc	ra,0xffffa
    80006a88:	3fc080e7          	jalr	1020(ra) # 80000e80 <memset>
  memset(disk.used, 0, PGSIZE);
    80006a8c:	6605                	lui	a2,0x1
    80006a8e:	4581                	li	a1,0
    80006a90:	6888                	ld	a0,16(s1)
    80006a92:	ffffa097          	auipc	ra,0xffffa
    80006a96:	3ee080e7          	jalr	1006(ra) # 80000e80 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006a9a:	100017b7          	lui	a5,0x10001
    80006a9e:	4721                	li	a4,8
    80006aa0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006aa2:	4098                	lw	a4,0(s1)
    80006aa4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006aa8:	40d8                	lw	a4,4(s1)
    80006aaa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006aae:	6498                	ld	a4,8(s1)
    80006ab0:	0007069b          	sext.w	a3,a4
    80006ab4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006ab8:	9701                	srai	a4,a4,0x20
    80006aba:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006abe:	6898                	ld	a4,16(s1)
    80006ac0:	0007069b          	sext.w	a3,a4
    80006ac4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006ac8:	9701                	srai	a4,a4,0x20
    80006aca:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006ace:	4685                	li	a3,1
    80006ad0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006ad2:	4705                	li	a4,1
    80006ad4:	00d48c23          	sb	a3,24(s1)
    80006ad8:	00e48ca3          	sb	a4,25(s1)
    80006adc:	00e48d23          	sb	a4,26(s1)
    80006ae0:	00e48da3          	sb	a4,27(s1)
    80006ae4:	00e48e23          	sb	a4,28(s1)
    80006ae8:	00e48ea3          	sb	a4,29(s1)
    80006aec:	00e48f23          	sb	a4,30(s1)
    80006af0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006af4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006af8:	0727a823          	sw	s2,112(a5)
}
    80006afc:	60e2                	ld	ra,24(sp)
    80006afe:	6442                	ld	s0,16(sp)
    80006b00:	64a2                	ld	s1,8(sp)
    80006b02:	6902                	ld	s2,0(sp)
    80006b04:	6105                	addi	sp,sp,32
    80006b06:	8082                	ret
    panic("could not find virtio disk");
    80006b08:	00002517          	auipc	a0,0x2
    80006b0c:	df850513          	addi	a0,a0,-520 # 80008900 <syscalls+0x348>
    80006b10:	ffffa097          	auipc	ra,0xffffa
    80006b14:	a34080e7          	jalr	-1484(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006b18:	00002517          	auipc	a0,0x2
    80006b1c:	e0850513          	addi	a0,a0,-504 # 80008920 <syscalls+0x368>
    80006b20:	ffffa097          	auipc	ra,0xffffa
    80006b24:	a24080e7          	jalr	-1500(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006b28:	00002517          	auipc	a0,0x2
    80006b2c:	e1850513          	addi	a0,a0,-488 # 80008940 <syscalls+0x388>
    80006b30:	ffffa097          	auipc	ra,0xffffa
    80006b34:	a14080e7          	jalr	-1516(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006b38:	00002517          	auipc	a0,0x2
    80006b3c:	e2850513          	addi	a0,a0,-472 # 80008960 <syscalls+0x3a8>
    80006b40:	ffffa097          	auipc	ra,0xffffa
    80006b44:	a04080e7          	jalr	-1532(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006b48:	00002517          	auipc	a0,0x2
    80006b4c:	e3850513          	addi	a0,a0,-456 # 80008980 <syscalls+0x3c8>
    80006b50:	ffffa097          	auipc	ra,0xffffa
    80006b54:	9f4080e7          	jalr	-1548(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006b58:	00002517          	auipc	a0,0x2
    80006b5c:	e4850513          	addi	a0,a0,-440 # 800089a0 <syscalls+0x3e8>
    80006b60:	ffffa097          	auipc	ra,0xffffa
    80006b64:	9e4080e7          	jalr	-1564(ra) # 80000544 <panic>

0000000080006b68 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006b68:	7159                	addi	sp,sp,-112
    80006b6a:	f486                	sd	ra,104(sp)
    80006b6c:	f0a2                	sd	s0,96(sp)
    80006b6e:	eca6                	sd	s1,88(sp)
    80006b70:	e8ca                	sd	s2,80(sp)
    80006b72:	e4ce                	sd	s3,72(sp)
    80006b74:	e0d2                	sd	s4,64(sp)
    80006b76:	fc56                	sd	s5,56(sp)
    80006b78:	f85a                	sd	s6,48(sp)
    80006b7a:	f45e                	sd	s7,40(sp)
    80006b7c:	f062                	sd	s8,32(sp)
    80006b7e:	ec66                	sd	s9,24(sp)
    80006b80:	e86a                	sd	s10,16(sp)
    80006b82:	1880                	addi	s0,sp,112
    80006b84:	892a                	mv	s2,a0
    80006b86:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006b88:	00c52c83          	lw	s9,12(a0)
    80006b8c:	001c9c9b          	slliw	s9,s9,0x1
    80006b90:	1c82                	slli	s9,s9,0x20
    80006b92:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006b96:	0023d517          	auipc	a0,0x23d
    80006b9a:	aba50513          	addi	a0,a0,-1350 # 80243650 <disk+0x128>
    80006b9e:	ffffa097          	auipc	ra,0xffffa
    80006ba2:	1e6080e7          	jalr	486(ra) # 80000d84 <acquire>
  for(int i = 0; i < 3; i++){
    80006ba6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006ba8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    80006baa:	0023db17          	auipc	s6,0x23d
    80006bae:	97eb0b13          	addi	s6,s6,-1666 # 80243528 <disk>
  for(int i = 0; i < 3; i++){
    80006bb2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006bb4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006bb6:	0023dc17          	auipc	s8,0x23d
    80006bba:	a9ac0c13          	addi	s8,s8,-1382 # 80243650 <disk+0x128>
    80006bbe:	a8b5                	j	80006c3a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006bc0:	00fb06b3          	add	a3,s6,a5
    80006bc4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006bc8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006bca:	0207c563          	bltz	a5,80006bf4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006bce:	2485                	addiw	s1,s1,1
    80006bd0:	0711                	addi	a4,a4,4
    80006bd2:	1f548a63          	beq	s1,s5,80006dc6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006bd6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006bd8:	0023d697          	auipc	a3,0x23d
    80006bdc:	95068693          	addi	a3,a3,-1712 # 80243528 <disk>
    80006be0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006be2:	0186c583          	lbu	a1,24(a3)
    80006be6:	fde9                	bnez	a1,80006bc0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006be8:	2785                	addiw	a5,a5,1
    80006bea:	0685                	addi	a3,a3,1
    80006bec:	ff779be3          	bne	a5,s7,80006be2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006bf0:	57fd                	li	a5,-1
    80006bf2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006bf4:	02905a63          	blez	s1,80006c28 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006bf8:	f9042503          	lw	a0,-112(s0)
    80006bfc:	00000097          	auipc	ra,0x0
    80006c00:	cfa080e7          	jalr	-774(ra) # 800068f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006c04:	4785                	li	a5,1
    80006c06:	0297d163          	bge	a5,s1,80006c28 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006c0a:	f9442503          	lw	a0,-108(s0)
    80006c0e:	00000097          	auipc	ra,0x0
    80006c12:	ce8080e7          	jalr	-792(ra) # 800068f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006c16:	4789                	li	a5,2
    80006c18:	0097d863          	bge	a5,s1,80006c28 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006c1c:	f9842503          	lw	a0,-104(s0)
    80006c20:	00000097          	auipc	ra,0x0
    80006c24:	cd6080e7          	jalr	-810(ra) # 800068f6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c28:	85e2                	mv	a1,s8
    80006c2a:	0023d517          	auipc	a0,0x23d
    80006c2e:	91650513          	addi	a0,a0,-1770 # 80243540 <disk+0x18>
    80006c32:	ffffb097          	auipc	ra,0xffffb
    80006c36:	7f0080e7          	jalr	2032(ra) # 80002422 <sleep>
  for(int i = 0; i < 3; i++){
    80006c3a:	f9040713          	addi	a4,s0,-112
    80006c3e:	84ce                	mv	s1,s3
    80006c40:	bf59                	j	80006bd6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006c42:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006c46:	00479693          	slli	a3,a5,0x4
    80006c4a:	0023d797          	auipc	a5,0x23d
    80006c4e:	8de78793          	addi	a5,a5,-1826 # 80243528 <disk>
    80006c52:	97b6                	add	a5,a5,a3
    80006c54:	4685                	li	a3,1
    80006c56:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006c58:	0023d597          	auipc	a1,0x23d
    80006c5c:	8d058593          	addi	a1,a1,-1840 # 80243528 <disk>
    80006c60:	00a60793          	addi	a5,a2,10
    80006c64:	0792                	slli	a5,a5,0x4
    80006c66:	97ae                	add	a5,a5,a1
    80006c68:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    80006c6c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c70:	f6070693          	addi	a3,a4,-160
    80006c74:	619c                	ld	a5,0(a1)
    80006c76:	97b6                	add	a5,a5,a3
    80006c78:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006c7a:	6188                	ld	a0,0(a1)
    80006c7c:	96aa                	add	a3,a3,a0
    80006c7e:	47c1                	li	a5,16
    80006c80:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006c82:	4785                	li	a5,1
    80006c84:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006c88:	f9442783          	lw	a5,-108(s0)
    80006c8c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006c90:	0792                	slli	a5,a5,0x4
    80006c92:	953e                	add	a0,a0,a5
    80006c94:	05890693          	addi	a3,s2,88
    80006c98:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006c9a:	6188                	ld	a0,0(a1)
    80006c9c:	97aa                	add	a5,a5,a0
    80006c9e:	40000693          	li	a3,1024
    80006ca2:	c794                	sw	a3,8(a5)
  if(write)
    80006ca4:	100d0d63          	beqz	s10,80006dbe <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006ca8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006cac:	00c7d683          	lhu	a3,12(a5)
    80006cb0:	0016e693          	ori	a3,a3,1
    80006cb4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006cb8:	f9842583          	lw	a1,-104(s0)
    80006cbc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006cc0:	0023d697          	auipc	a3,0x23d
    80006cc4:	86868693          	addi	a3,a3,-1944 # 80243528 <disk>
    80006cc8:	00260793          	addi	a5,a2,2
    80006ccc:	0792                	slli	a5,a5,0x4
    80006cce:	97b6                	add	a5,a5,a3
    80006cd0:	587d                	li	a6,-1
    80006cd2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006cd6:	0592                	slli	a1,a1,0x4
    80006cd8:	952e                	add	a0,a0,a1
    80006cda:	f9070713          	addi	a4,a4,-112
    80006cde:	9736                	add	a4,a4,a3
    80006ce0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006ce2:	6298                	ld	a4,0(a3)
    80006ce4:	972e                	add	a4,a4,a1
    80006ce6:	4585                	li	a1,1
    80006ce8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006cea:	4509                	li	a0,2
    80006cec:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006cf0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006cf4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006cf8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006cfc:	6698                	ld	a4,8(a3)
    80006cfe:	00275783          	lhu	a5,2(a4)
    80006d02:	8b9d                	andi	a5,a5,7
    80006d04:	0786                	slli	a5,a5,0x1
    80006d06:	97ba                	add	a5,a5,a4
    80006d08:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    80006d0c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006d10:	6698                	ld	a4,8(a3)
    80006d12:	00275783          	lhu	a5,2(a4)
    80006d16:	2785                	addiw	a5,a5,1
    80006d18:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006d1c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006d20:	100017b7          	lui	a5,0x10001
    80006d24:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006d28:	00492703          	lw	a4,4(s2)
    80006d2c:	4785                	li	a5,1
    80006d2e:	02f71163          	bne	a4,a5,80006d50 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006d32:	0023d997          	auipc	s3,0x23d
    80006d36:	91e98993          	addi	s3,s3,-1762 # 80243650 <disk+0x128>
  while(b->disk == 1) {
    80006d3a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006d3c:	85ce                	mv	a1,s3
    80006d3e:	854a                	mv	a0,s2
    80006d40:	ffffb097          	auipc	ra,0xffffb
    80006d44:	6e2080e7          	jalr	1762(ra) # 80002422 <sleep>
  while(b->disk == 1) {
    80006d48:	00492783          	lw	a5,4(s2)
    80006d4c:	fe9788e3          	beq	a5,s1,80006d3c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006d50:	f9042903          	lw	s2,-112(s0)
    80006d54:	00290793          	addi	a5,s2,2
    80006d58:	00479713          	slli	a4,a5,0x4
    80006d5c:	0023c797          	auipc	a5,0x23c
    80006d60:	7cc78793          	addi	a5,a5,1996 # 80243528 <disk>
    80006d64:	97ba                	add	a5,a5,a4
    80006d66:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006d6a:	0023c997          	auipc	s3,0x23c
    80006d6e:	7be98993          	addi	s3,s3,1982 # 80243528 <disk>
    80006d72:	00491713          	slli	a4,s2,0x4
    80006d76:	0009b783          	ld	a5,0(s3)
    80006d7a:	97ba                	add	a5,a5,a4
    80006d7c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006d80:	854a                	mv	a0,s2
    80006d82:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006d86:	00000097          	auipc	ra,0x0
    80006d8a:	b70080e7          	jalr	-1168(ra) # 800068f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006d8e:	8885                	andi	s1,s1,1
    80006d90:	f0ed                	bnez	s1,80006d72 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006d92:	0023d517          	auipc	a0,0x23d
    80006d96:	8be50513          	addi	a0,a0,-1858 # 80243650 <disk+0x128>
    80006d9a:	ffffa097          	auipc	ra,0xffffa
    80006d9e:	09e080e7          	jalr	158(ra) # 80000e38 <release>
}
    80006da2:	70a6                	ld	ra,104(sp)
    80006da4:	7406                	ld	s0,96(sp)
    80006da6:	64e6                	ld	s1,88(sp)
    80006da8:	6946                	ld	s2,80(sp)
    80006daa:	69a6                	ld	s3,72(sp)
    80006dac:	6a06                	ld	s4,64(sp)
    80006dae:	7ae2                	ld	s5,56(sp)
    80006db0:	7b42                	ld	s6,48(sp)
    80006db2:	7ba2                	ld	s7,40(sp)
    80006db4:	7c02                	ld	s8,32(sp)
    80006db6:	6ce2                	ld	s9,24(sp)
    80006db8:	6d42                	ld	s10,16(sp)
    80006dba:	6165                	addi	sp,sp,112
    80006dbc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006dbe:	4689                	li	a3,2
    80006dc0:	00d79623          	sh	a3,12(a5)
    80006dc4:	b5e5                	j	80006cac <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006dc6:	f9042603          	lw	a2,-112(s0)
    80006dca:	00a60713          	addi	a4,a2,10
    80006dce:	0712                	slli	a4,a4,0x4
    80006dd0:	0023c517          	auipc	a0,0x23c
    80006dd4:	76050513          	addi	a0,a0,1888 # 80243530 <disk+0x8>
    80006dd8:	953a                	add	a0,a0,a4
  if(write)
    80006dda:	e60d14e3          	bnez	s10,80006c42 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006dde:	00a60793          	addi	a5,a2,10
    80006de2:	00479693          	slli	a3,a5,0x4
    80006de6:	0023c797          	auipc	a5,0x23c
    80006dea:	74278793          	addi	a5,a5,1858 # 80243528 <disk>
    80006dee:	97b6                	add	a5,a5,a3
    80006df0:	0007a423          	sw	zero,8(a5)
    80006df4:	b595                	j	80006c58 <virtio_disk_rw+0xf0>

0000000080006df6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006df6:	1101                	addi	sp,sp,-32
    80006df8:	ec06                	sd	ra,24(sp)
    80006dfa:	e822                	sd	s0,16(sp)
    80006dfc:	e426                	sd	s1,8(sp)
    80006dfe:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006e00:	0023c497          	auipc	s1,0x23c
    80006e04:	72848493          	addi	s1,s1,1832 # 80243528 <disk>
    80006e08:	0023d517          	auipc	a0,0x23d
    80006e0c:	84850513          	addi	a0,a0,-1976 # 80243650 <disk+0x128>
    80006e10:	ffffa097          	auipc	ra,0xffffa
    80006e14:	f74080e7          	jalr	-140(ra) # 80000d84 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006e18:	10001737          	lui	a4,0x10001
    80006e1c:	533c                	lw	a5,96(a4)
    80006e1e:	8b8d                	andi	a5,a5,3
    80006e20:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006e22:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006e26:	689c                	ld	a5,16(s1)
    80006e28:	0204d703          	lhu	a4,32(s1)
    80006e2c:	0027d783          	lhu	a5,2(a5)
    80006e30:	04f70863          	beq	a4,a5,80006e80 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006e34:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e38:	6898                	ld	a4,16(s1)
    80006e3a:	0204d783          	lhu	a5,32(s1)
    80006e3e:	8b9d                	andi	a5,a5,7
    80006e40:	078e                	slli	a5,a5,0x3
    80006e42:	97ba                	add	a5,a5,a4
    80006e44:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006e46:	00278713          	addi	a4,a5,2
    80006e4a:	0712                	slli	a4,a4,0x4
    80006e4c:	9726                	add	a4,a4,s1
    80006e4e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006e52:	e721                	bnez	a4,80006e9a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006e54:	0789                	addi	a5,a5,2
    80006e56:	0792                	slli	a5,a5,0x4
    80006e58:	97a6                	add	a5,a5,s1
    80006e5a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006e5c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006e60:	ffffb097          	auipc	ra,0xffffb
    80006e64:	76c080e7          	jalr	1900(ra) # 800025cc <wakeup>

    disk.used_idx += 1;
    80006e68:	0204d783          	lhu	a5,32(s1)
    80006e6c:	2785                	addiw	a5,a5,1
    80006e6e:	17c2                	slli	a5,a5,0x30
    80006e70:	93c1                	srli	a5,a5,0x30
    80006e72:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006e76:	6898                	ld	a4,16(s1)
    80006e78:	00275703          	lhu	a4,2(a4)
    80006e7c:	faf71ce3          	bne	a4,a5,80006e34 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006e80:	0023c517          	auipc	a0,0x23c
    80006e84:	7d050513          	addi	a0,a0,2000 # 80243650 <disk+0x128>
    80006e88:	ffffa097          	auipc	ra,0xffffa
    80006e8c:	fb0080e7          	jalr	-80(ra) # 80000e38 <release>
}
    80006e90:	60e2                	ld	ra,24(sp)
    80006e92:	6442                	ld	s0,16(sp)
    80006e94:	64a2                	ld	s1,8(sp)
    80006e96:	6105                	addi	sp,sp,32
    80006e98:	8082                	ret
      panic("virtio_disk_intr status");
    80006e9a:	00002517          	auipc	a0,0x2
    80006e9e:	b1e50513          	addi	a0,a0,-1250 # 800089b8 <syscalls+0x400>
    80006ea2:	ffff9097          	auipc	ra,0xffff9
    80006ea6:	6a2080e7          	jalr	1698(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
