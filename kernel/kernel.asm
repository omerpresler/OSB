
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	94013103          	ld	sp,-1728(sp) # 80008940 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
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
    80000068:	31c78793          	addi	a5,a5,796 # 80006380 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	f0478793          	addi	a5,a5,-252 # 80000fb2 <main>
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
    80000130:	b40080e7          	jalr	-1216(ra) # 80002c6c <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
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
    80000190:	01450513          	addi	a0,a0,20 # 800111a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	00448493          	addi	s1,s1,4 # 800111a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	09290913          	addi	s2,s2,146 # 80011238 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

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
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	a62080e7          	jalr	-1438(ra) # 80001c26 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	5a2080e7          	jalr	1442(ra) # 80002776 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00003097          	auipc	ra,0x3
    80000214:	a06080e7          	jalr	-1530(ra) # 80002c16 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f7c50513          	addi	a0,a0,-132 # 800111a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f6650513          	addi	a0,a0,-154 # 800111a0 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	fcf72323          	sw	a5,-58(a4) # 80011238 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ed450513          	addi	a0,a0,-300 # 800111a0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	9d0080e7          	jalr	-1584(ra) # 80002cc2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ea650513          	addi	a0,a0,-346 # 800111a0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e8270713          	addi	a4,a4,-382 # 800111a0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e5878793          	addi	a5,a5,-424 # 800111a0 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80011238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e1670713          	addi	a4,a4,-490 # 800111a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e0648493          	addi	s1,s1,-506 # 800111a0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	dca70713          	addi	a4,a4,-566 # 800111a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80011240 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d8e78793          	addi	a5,a5,-626 # 800111a0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001123c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dfa50513          	addi	a0,a0,-518 # 80011238 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	4c6080e7          	jalr	1222(ra) # 8000290c <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d4050513          	addi	a0,a0,-704 # 800111a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	6c078793          	addi	a5,a5,1728 # 80021b38 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80011260 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	d0c50513          	addi	a0,a0,-756 # 80008278 <digits+0x238>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80011260 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c5050513          	addi	a0,a0,-944 # 80011248 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	aec50513          	addi	a0,a0,-1300 # 80011248 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80011248 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80011268 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80011268 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	06c080e7          	jalr	108(ra) # 8000290c <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80011268 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80011268 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	e4a080e7          	jalr	-438(ra) # 80002776 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	92648493          	addi	s1,s1,-1754 # 80011268 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80011268 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	87490913          	addi	s2,s2,-1932 # 800112a0 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7d850513          	addi	a0,a0,2008 # 800112a0 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	7a248493          	addi	s1,s1,1954 # 800112a0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800112a0 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	75e50513          	addi	a0,a0,1886 # 800112a0 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	08c080e7          	jalr	140(ra) # 80001c0a <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	05a080e7          	jalr	90(ra) # 80001c0a <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	04e080e7          	jalr	78(ra) # 80001c0a <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	036080e7          	jalr	54(ra) # 80001c0a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	ff6080e7          	jalr	-10(ra) # 80001c0a <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	fca080e7          	jalr	-54(ra) # 80001c0a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <example_pause_system>:
#include "riscv.h"
#include "defs.h"

volatile static int started = 0;

void example_pause_system(int interval, int pause_seconds, int loop_size) {
    80000e8e:	7139                	addi	sp,sp,-64
    80000e90:	fc06                	sd	ra,56(sp)
    80000e92:	f822                	sd	s0,48(sp)
    80000e94:	f426                	sd	s1,40(sp)
    80000e96:	f04a                	sd	s2,32(sp)
    80000e98:	ec4e                	sd	s3,24(sp)
    80000e9a:	e852                	sd	s4,16(sp)
    80000e9c:	e456                	sd	s5,8(sp)
    80000e9e:	e05a                	sd	s6,0(sp)
    80000ea0:	0080                	addi	s0,sp,64
    80000ea2:	8a2a                	mv	s4,a0
    80000ea4:	8aae                	mv	s5,a1
    80000ea6:	8932                	mv	s2,a2
    int n_forks = 2;
    for (int i = 0; i < n_forks; i++) {
    	fork();
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	172080e7          	jalr	370(ra) # 8000201a <fork>
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	16a080e7          	jalr	362(ra) # 8000201a <fork>
    }
    for (int i = 0; i < loop_size; i++) {
    80000eb8:	05205463          	blez	s2,80000f00 <example_pause_system+0x72>
        if (i % interval == 0) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2){
    80000ebc:	01f9599b          	srliw	s3,s2,0x1f
    80000ec0:	012989bb          	addw	s3,s3,s2
    80000ec4:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
    80000ec8:	4481                	li	s1,0
            printf("pause system %d/%d completed.\n", i, loop_size);
    80000eca:	00007b17          	auipc	s6,0x7
    80000ece:	1d6b0b13          	addi	s6,s6,470 # 800080a0 <digits+0x60>
    80000ed2:	a829                	j	80000eec <example_pause_system+0x5e>
    80000ed4:	864a                	mv	a2,s2
    80000ed6:	85a6                	mv	a1,s1
    80000ed8:	855a                	mv	a0,s6
    80000eda:	fffff097          	auipc	ra,0xfffff
    80000ede:	6ae080e7          	jalr	1710(ra) # 80000588 <printf>
        if (i == loop_size / 2){
    80000ee2:	00998963          	beq	s3,s1,80000ef4 <example_pause_system+0x66>
    for (int i = 0; i < loop_size; i++) {
    80000ee6:	2485                	addiw	s1,s1,1
    80000ee8:	00990c63          	beq	s2,s1,80000f00 <example_pause_system+0x72>
        if (i % interval == 0) {
    80000eec:	0344e7bb          	remw	a5,s1,s4
    80000ef0:	fbed                	bnez	a5,80000ee2 <example_pause_system+0x54>
    80000ef2:	b7cd                	j	80000ed4 <example_pause_system+0x46>
            pause_system(pause_seconds);
    80000ef4:	8556                	mv	a0,s5
    80000ef6:	00001097          	auipc	ra,0x1
    80000efa:	7f0080e7          	jalr	2032(ra) # 800026e6 <pause_system>
    80000efe:	b7e5                	j	80000ee6 <example_pause_system+0x58>
        }
    }
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	37850513          	addi	a0,a0,888 # 80008278 <digits+0x238>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	680080e7          	jalr	1664(ra) # 80000588 <printf>
}
    80000f10:	70e2                	ld	ra,56(sp)
    80000f12:	7442                	ld	s0,48(sp)
    80000f14:	74a2                	ld	s1,40(sp)
    80000f16:	7902                	ld	s2,32(sp)
    80000f18:	69e2                	ld	s3,24(sp)
    80000f1a:	6a42                	ld	s4,16(sp)
    80000f1c:	6aa2                	ld	s5,8(sp)
    80000f1e:	6b02                	ld	s6,0(sp)
    80000f20:	6121                	addi	sp,sp,64
    80000f22:	8082                	ret

0000000080000f24 <example_kill_system>:

void example_kill_system(int interval, int loop_size) {
    80000f24:	7139                	addi	sp,sp,-64
    80000f26:	fc06                	sd	ra,56(sp)
    80000f28:	f822                	sd	s0,48(sp)
    80000f2a:	f426                	sd	s1,40(sp)
    80000f2c:	f04a                	sd	s2,32(sp)
    80000f2e:	ec4e                	sd	s3,24(sp)
    80000f30:	e852                	sd	s4,16(sp)
    80000f32:	e456                	sd	s5,8(sp)
    80000f34:	0080                	addi	s0,sp,64
    80000f36:	8a2a                	mv	s4,a0
    80000f38:	892e                	mv	s2,a1
    int n_forks = 2;
    for (int i = 0; i < n_forks; i++) {
    	fork();
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	0e0080e7          	jalr	224(ra) # 8000201a <fork>
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	0d8080e7          	jalr	216(ra) # 8000201a <fork>
    }
    for (int i = 0; i < loop_size; i++) {
    80000f4a:	05205363          	blez	s2,80000f90 <example_kill_system+0x6c>
        if (i % interval == 0) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2){
    80000f4e:	01f9599b          	srliw	s3,s2,0x1f
    80000f52:	012989bb          	addw	s3,s3,s2
    80000f56:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
    80000f5a:	4481                	li	s1,0
            printf("kill system %d/%d completed.\n", i, loop_size);
    80000f5c:	00007a97          	auipc	s5,0x7
    80000f60:	164a8a93          	addi	s5,s5,356 # 800080c0 <digits+0x80>
    80000f64:	a829                	j	80000f7e <example_kill_system+0x5a>
    80000f66:	864a                	mv	a2,s2
    80000f68:	85a6                	mv	a1,s1
    80000f6a:	8556                	mv	a0,s5
    80000f6c:	fffff097          	auipc	ra,0xfffff
    80000f70:	61c080e7          	jalr	1564(ra) # 80000588 <printf>
        if (i == loop_size / 2){
    80000f74:	00998963          	beq	s3,s1,80000f86 <example_kill_system+0x62>
    for (int i = 0; i < loop_size; i++) {
    80000f78:	2485                	addiw	s1,s1,1
    80000f7a:	00990b63          	beq	s2,s1,80000f90 <example_kill_system+0x6c>
        if (i % interval == 0) {
    80000f7e:	0344e7bb          	remw	a5,s1,s4
    80000f82:	fbed                	bnez	a5,80000f74 <example_kill_system+0x50>
    80000f84:	b7cd                	j	80000f66 <example_kill_system+0x42>
            kill_system();
    80000f86:	00002097          	auipc	ra,0x2
    80000f8a:	c26080e7          	jalr	-986(ra) # 80002bac <kill_system>
    80000f8e:	b7ed                	j	80000f78 <example_kill_system+0x54>
        }
    }
    printf("\n");
    80000f90:	00007517          	auipc	a0,0x7
    80000f94:	2e850513          	addi	a0,a0,744 # 80008278 <digits+0x238>
    80000f98:	fffff097          	auipc	ra,0xfffff
    80000f9c:	5f0080e7          	jalr	1520(ra) # 80000588 <printf>
}
    80000fa0:	70e2                	ld	ra,56(sp)
    80000fa2:	7442                	ld	s0,48(sp)
    80000fa4:	74a2                	ld	s1,40(sp)
    80000fa6:	7902                	ld	s2,32(sp)
    80000fa8:	69e2                	ld	s3,24(sp)
    80000faa:	6a42                	ld	s4,16(sp)
    80000fac:	6aa2                	ld	s5,8(sp)
    80000fae:	6121                	addi	sp,sp,64
    80000fb0:	8082                	ret

0000000080000fb2 <main>:

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fb2:	1141                	addi	sp,sp,-16
    80000fb4:	e406                	sd	ra,8(sp)
    80000fb6:	e022                	sd	s0,0(sp)
    80000fb8:	0800                	addi	s0,sp,16
  //example_pause_system(2, 2, 5);
  //example_kill_system(5, 5);

  if(cpuid() == 0){
    80000fba:	00001097          	auipc	ra,0x1
    80000fbe:	c40080e7          	jalr	-960(ra) # 80001bfa <cpuid>
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
    
  } else {
    while(started == 0)
    80000fc2:	00008717          	auipc	a4,0x8
    80000fc6:	05670713          	addi	a4,a4,86 # 80009018 <started>
  if(cpuid() == 0){
    80000fca:	c139                	beqz	a0,80001010 <main+0x5e>
    while(started == 0)
    80000fcc:	431c                	lw	a5,0(a4)
    80000fce:	2781                	sext.w	a5,a5
    80000fd0:	dff5                	beqz	a5,80000fcc <main+0x1a>
      ;
    __sync_synchronize();
    80000fd2:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fd6:	00001097          	auipc	ra,0x1
    80000fda:	c24080e7          	jalr	-988(ra) # 80001bfa <cpuid>
    80000fde:	85aa                	mv	a1,a0
    80000fe0:	00007517          	auipc	a0,0x7
    80000fe4:	11850513          	addi	a0,a0,280 # 800080f8 <digits+0xb8>
    80000fe8:	fffff097          	auipc	ra,0xfffff
    80000fec:	5a0080e7          	jalr	1440(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	0d8080e7          	jalr	216(ra) # 800010c8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ff8:	00002097          	auipc	ra,0x2
    80000ffc:	e0a080e7          	jalr	-502(ra) # 80002e02 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001000:	00005097          	auipc	ra,0x5
    80001004:	3c0080e7          	jalr	960(ra) # 800063c0 <plicinithart>
  }

  scheduler();    
    80001008:	00001097          	auipc	ra,0x1
    8000100c:	5b6080e7          	jalr	1462(ra) # 800025be <scheduler>
    consoleinit();
    80001010:	fffff097          	auipc	ra,0xfffff
    80001014:	440080e7          	jalr	1088(ra) # 80000450 <consoleinit>
    printfinit();
    80001018:	fffff097          	auipc	ra,0xfffff
    8000101c:	756080e7          	jalr	1878(ra) # 8000076e <printfinit>
    printf("\n");
    80001020:	00007517          	auipc	a0,0x7
    80001024:	25850513          	addi	a0,a0,600 # 80008278 <digits+0x238>
    80001028:	fffff097          	auipc	ra,0xfffff
    8000102c:	560080e7          	jalr	1376(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80001030:	00007517          	auipc	a0,0x7
    80001034:	0b050513          	addi	a0,a0,176 # 800080e0 <digits+0xa0>
    80001038:	fffff097          	auipc	ra,0xfffff
    8000103c:	550080e7          	jalr	1360(ra) # 80000588 <printf>
    printf("\n");
    80001040:	00007517          	auipc	a0,0x7
    80001044:	23850513          	addi	a0,a0,568 # 80008278 <digits+0x238>
    80001048:	fffff097          	auipc	ra,0xfffff
    8000104c:	540080e7          	jalr	1344(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80001050:	00000097          	auipc	ra,0x0
    80001054:	a68080e7          	jalr	-1432(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80001058:	00000097          	auipc	ra,0x0
    8000105c:	322080e7          	jalr	802(ra) # 8000137a <kvminit>
    kvminithart();   // turn on paging
    80001060:	00000097          	auipc	ra,0x0
    80001064:	068080e7          	jalr	104(ra) # 800010c8 <kvminithart>
    procinit();      // process table
    80001068:	00001097          	auipc	ra,0x1
    8000106c:	aca080e7          	jalr	-1334(ra) # 80001b32 <procinit>
    trapinit();      // trap vectors
    80001070:	00002097          	auipc	ra,0x2
    80001074:	d6a080e7          	jalr	-662(ra) # 80002dda <trapinit>
    trapinithart();  // install kernel trap vector
    80001078:	00002097          	auipc	ra,0x2
    8000107c:	d8a080e7          	jalr	-630(ra) # 80002e02 <trapinithart>
    plicinit();      // set up interrupt controller
    80001080:	00005097          	auipc	ra,0x5
    80001084:	32a080e7          	jalr	810(ra) # 800063aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001088:	00005097          	auipc	ra,0x5
    8000108c:	338080e7          	jalr	824(ra) # 800063c0 <plicinithart>
    binit();         // buffer cache
    80001090:	00002097          	auipc	ra,0x2
    80001094:	516080e7          	jalr	1302(ra) # 800035a6 <binit>
    iinit();         // inode table
    80001098:	00003097          	auipc	ra,0x3
    8000109c:	ba6080e7          	jalr	-1114(ra) # 80003c3e <iinit>
    fileinit();      // file table
    800010a0:	00004097          	auipc	ra,0x4
    800010a4:	b50080e7          	jalr	-1200(ra) # 80004bf0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a8:	00005097          	auipc	ra,0x5
    800010ac:	43a080e7          	jalr	1082(ra) # 800064e2 <virtio_disk_init>
    userinit();      // first user process
    800010b0:	00001097          	auipc	ra,0x1
    800010b4:	e6e080e7          	jalr	-402(ra) # 80001f1e <userinit>
    __sync_synchronize();
    800010b8:	0ff0000f          	fence
    started = 1;
    800010bc:	4785                	li	a5,1
    800010be:	00008717          	auipc	a4,0x8
    800010c2:	f4f72d23          	sw	a5,-166(a4) # 80009018 <started>
    800010c6:	b789                	j	80001008 <main+0x56>

00000000800010c8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010c8:	1141                	addi	sp,sp,-16
    800010ca:	e422                	sd	s0,8(sp)
    800010cc:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010ce:	00008797          	auipc	a5,0x8
    800010d2:	f527b783          	ld	a5,-174(a5) # 80009020 <kernel_pagetable>
    800010d6:	83b1                	srli	a5,a5,0xc
    800010d8:	577d                	li	a4,-1
    800010da:	177e                	slli	a4,a4,0x3f
    800010dc:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010de:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010e2:	12000073          	sfence.vma
  sfence_vma();
}
    800010e6:	6422                	ld	s0,8(sp)
    800010e8:	0141                	addi	sp,sp,16
    800010ea:	8082                	ret

00000000800010ec <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010ec:	7139                	addi	sp,sp,-64
    800010ee:	fc06                	sd	ra,56(sp)
    800010f0:	f822                	sd	s0,48(sp)
    800010f2:	f426                	sd	s1,40(sp)
    800010f4:	f04a                	sd	s2,32(sp)
    800010f6:	ec4e                	sd	s3,24(sp)
    800010f8:	e852                	sd	s4,16(sp)
    800010fa:	e456                	sd	s5,8(sp)
    800010fc:	e05a                	sd	s6,0(sp)
    800010fe:	0080                	addi	s0,sp,64
    80001100:	84aa                	mv	s1,a0
    80001102:	89ae                	mv	s3,a1
    80001104:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001106:	57fd                	li	a5,-1
    80001108:	83e9                	srli	a5,a5,0x1a
    8000110a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000110c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000110e:	04b7f263          	bgeu	a5,a1,80001152 <walk+0x66>
    panic("walk");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	ffe50513          	addi	a0,a0,-2 # 80008110 <digits+0xd0>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001122:	060a8663          	beqz	s5,8000118e <walk+0xa2>
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	9ce080e7          	jalr	-1586(ra) # 80000af4 <kalloc>
    8000112e:	84aa                	mv	s1,a0
    80001130:	c529                	beqz	a0,8000117a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001132:	6605                	lui	a2,0x1
    80001134:	4581                	li	a1,0
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	baa080e7          	jalr	-1110(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000113e:	00c4d793          	srli	a5,s1,0xc
    80001142:	07aa                	slli	a5,a5,0xa
    80001144:	0017e793          	ori	a5,a5,1
    80001148:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000114c:	3a5d                	addiw	s4,s4,-9
    8000114e:	036a0063          	beq	s4,s6,8000116e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001152:	0149d933          	srl	s2,s3,s4
    80001156:	1ff97913          	andi	s2,s2,511
    8000115a:	090e                	slli	s2,s2,0x3
    8000115c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000115e:	00093483          	ld	s1,0(s2)
    80001162:	0014f793          	andi	a5,s1,1
    80001166:	dfd5                	beqz	a5,80001122 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001168:	80a9                	srli	s1,s1,0xa
    8000116a:	04b2                	slli	s1,s1,0xc
    8000116c:	b7c5                	j	8000114c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000116e:	00c9d513          	srli	a0,s3,0xc
    80001172:	1ff57513          	andi	a0,a0,511
    80001176:	050e                	slli	a0,a0,0x3
    80001178:	9526                	add	a0,a0,s1
}
    8000117a:	70e2                	ld	ra,56(sp)
    8000117c:	7442                	ld	s0,48(sp)
    8000117e:	74a2                	ld	s1,40(sp)
    80001180:	7902                	ld	s2,32(sp)
    80001182:	69e2                	ld	s3,24(sp)
    80001184:	6a42                	ld	s4,16(sp)
    80001186:	6aa2                	ld	s5,8(sp)
    80001188:	6b02                	ld	s6,0(sp)
    8000118a:	6121                	addi	sp,sp,64
    8000118c:	8082                	ret
        return 0;
    8000118e:	4501                	li	a0,0
    80001190:	b7ed                	j	8000117a <walk+0x8e>

0000000080001192 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001192:	57fd                	li	a5,-1
    80001194:	83e9                	srli	a5,a5,0x1a
    80001196:	00b7f463          	bgeu	a5,a1,8000119e <walkaddr+0xc>
    return 0;
    8000119a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000119c:	8082                	ret
{
    8000119e:	1141                	addi	sp,sp,-16
    800011a0:	e406                	sd	ra,8(sp)
    800011a2:	e022                	sd	s0,0(sp)
    800011a4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011a6:	4601                	li	a2,0
    800011a8:	00000097          	auipc	ra,0x0
    800011ac:	f44080e7          	jalr	-188(ra) # 800010ec <walk>
  if(pte == 0)
    800011b0:	c105                	beqz	a0,800011d0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011b2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011b4:	0117f693          	andi	a3,a5,17
    800011b8:	4745                	li	a4,17
    return 0;
    800011ba:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011bc:	00e68663          	beq	a3,a4,800011c8 <walkaddr+0x36>
}
    800011c0:	60a2                	ld	ra,8(sp)
    800011c2:	6402                	ld	s0,0(sp)
    800011c4:	0141                	addi	sp,sp,16
    800011c6:	8082                	ret
  pa = PTE2PA(*pte);
    800011c8:	00a7d513          	srli	a0,a5,0xa
    800011cc:	0532                	slli	a0,a0,0xc
  return pa;
    800011ce:	bfcd                	j	800011c0 <walkaddr+0x2e>
    return 0;
    800011d0:	4501                	li	a0,0
    800011d2:	b7fd                	j	800011c0 <walkaddr+0x2e>

00000000800011d4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011d4:	715d                	addi	sp,sp,-80
    800011d6:	e486                	sd	ra,72(sp)
    800011d8:	e0a2                	sd	s0,64(sp)
    800011da:	fc26                	sd	s1,56(sp)
    800011dc:	f84a                	sd	s2,48(sp)
    800011de:	f44e                	sd	s3,40(sp)
    800011e0:	f052                	sd	s4,32(sp)
    800011e2:	ec56                	sd	s5,24(sp)
    800011e4:	e85a                	sd	s6,16(sp)
    800011e6:	e45e                	sd	s7,8(sp)
    800011e8:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011ea:	c205                	beqz	a2,8000120a <mappages+0x36>
    800011ec:	8aaa                	mv	s5,a0
    800011ee:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011f0:	77fd                	lui	a5,0xfffff
    800011f2:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011f6:	15fd                	addi	a1,a1,-1
    800011f8:	00c589b3          	add	s3,a1,a2
    800011fc:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001200:	8952                	mv	s2,s4
    80001202:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001206:	6b85                	lui	s7,0x1
    80001208:	a015                	j	8000122c <mappages+0x58>
    panic("mappages: size");
    8000120a:	00007517          	auipc	a0,0x7
    8000120e:	f0e50513          	addi	a0,a0,-242 # 80008118 <digits+0xd8>
    80001212:	fffff097          	auipc	ra,0xfffff
    80001216:	32c080e7          	jalr	812(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000121a:	00007517          	auipc	a0,0x7
    8000121e:	f0e50513          	addi	a0,a0,-242 # 80008128 <digits+0xe8>
    80001222:	fffff097          	auipc	ra,0xfffff
    80001226:	31c080e7          	jalr	796(ra) # 8000053e <panic>
    a += PGSIZE;
    8000122a:	995e                	add	s2,s2,s7
  for(;;){
    8000122c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001230:	4605                	li	a2,1
    80001232:	85ca                	mv	a1,s2
    80001234:	8556                	mv	a0,s5
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	eb6080e7          	jalr	-330(ra) # 800010ec <walk>
    8000123e:	cd19                	beqz	a0,8000125c <mappages+0x88>
    if(*pte & PTE_V)
    80001240:	611c                	ld	a5,0(a0)
    80001242:	8b85                	andi	a5,a5,1
    80001244:	fbf9                	bnez	a5,8000121a <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001246:	80b1                	srli	s1,s1,0xc
    80001248:	04aa                	slli	s1,s1,0xa
    8000124a:	0164e4b3          	or	s1,s1,s6
    8000124e:	0014e493          	ori	s1,s1,1
    80001252:	e104                	sd	s1,0(a0)
    if(a == last)
    80001254:	fd391be3          	bne	s2,s3,8000122a <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001258:	4501                	li	a0,0
    8000125a:	a011                	j	8000125e <mappages+0x8a>
      return -1;
    8000125c:	557d                	li	a0,-1
}
    8000125e:	60a6                	ld	ra,72(sp)
    80001260:	6406                	ld	s0,64(sp)
    80001262:	74e2                	ld	s1,56(sp)
    80001264:	7942                	ld	s2,48(sp)
    80001266:	79a2                	ld	s3,40(sp)
    80001268:	7a02                	ld	s4,32(sp)
    8000126a:	6ae2                	ld	s5,24(sp)
    8000126c:	6b42                	ld	s6,16(sp)
    8000126e:	6ba2                	ld	s7,8(sp)
    80001270:	6161                	addi	sp,sp,80
    80001272:	8082                	ret

0000000080001274 <kvmmap>:
{
    80001274:	1141                	addi	sp,sp,-16
    80001276:	e406                	sd	ra,8(sp)
    80001278:	e022                	sd	s0,0(sp)
    8000127a:	0800                	addi	s0,sp,16
    8000127c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000127e:	86b2                	mv	a3,a2
    80001280:	863e                	mv	a2,a5
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f52080e7          	jalr	-174(ra) # 800011d4 <mappages>
    8000128a:	e509                	bnez	a0,80001294 <kvmmap+0x20>
}
    8000128c:	60a2                	ld	ra,8(sp)
    8000128e:	6402                	ld	s0,0(sp)
    80001290:	0141                	addi	sp,sp,16
    80001292:	8082                	ret
    panic("kvmmap");
    80001294:	00007517          	auipc	a0,0x7
    80001298:	ea450513          	addi	a0,a0,-348 # 80008138 <digits+0xf8>
    8000129c:	fffff097          	auipc	ra,0xfffff
    800012a0:	2a2080e7          	jalr	674(ra) # 8000053e <panic>

00000000800012a4 <kvmmake>:
{
    800012a4:	1101                	addi	sp,sp,-32
    800012a6:	ec06                	sd	ra,24(sp)
    800012a8:	e822                	sd	s0,16(sp)
    800012aa:	e426                	sd	s1,8(sp)
    800012ac:	e04a                	sd	s2,0(sp)
    800012ae:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	844080e7          	jalr	-1980(ra) # 80000af4 <kalloc>
    800012b8:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012ba:	6605                	lui	a2,0x1
    800012bc:	4581                	li	a1,0
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	a22080e7          	jalr	-1502(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012c6:	4719                	li	a4,6
    800012c8:	6685                	lui	a3,0x1
    800012ca:	10000637          	lui	a2,0x10000
    800012ce:	100005b7          	lui	a1,0x10000
    800012d2:	8526                	mv	a0,s1
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	fa0080e7          	jalr	-96(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012dc:	4719                	li	a4,6
    800012de:	6685                	lui	a3,0x1
    800012e0:	10001637          	lui	a2,0x10001
    800012e4:	100015b7          	lui	a1,0x10001
    800012e8:	8526                	mv	a0,s1
    800012ea:	00000097          	auipc	ra,0x0
    800012ee:	f8a080e7          	jalr	-118(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012f2:	4719                	li	a4,6
    800012f4:	004006b7          	lui	a3,0x400
    800012f8:	0c000637          	lui	a2,0xc000
    800012fc:	0c0005b7          	lui	a1,0xc000
    80001300:	8526                	mv	a0,s1
    80001302:	00000097          	auipc	ra,0x0
    80001306:	f72080e7          	jalr	-142(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000130a:	00007917          	auipc	s2,0x7
    8000130e:	cf690913          	addi	s2,s2,-778 # 80008000 <etext>
    80001312:	4729                	li	a4,10
    80001314:	80007697          	auipc	a3,0x80007
    80001318:	cec68693          	addi	a3,a3,-788 # 8000 <_entry-0x7fff8000>
    8000131c:	4605                	li	a2,1
    8000131e:	067e                	slli	a2,a2,0x1f
    80001320:	85b2                	mv	a1,a2
    80001322:	8526                	mv	a0,s1
    80001324:	00000097          	auipc	ra,0x0
    80001328:	f50080e7          	jalr	-176(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000132c:	4719                	li	a4,6
    8000132e:	46c5                	li	a3,17
    80001330:	06ee                	slli	a3,a3,0x1b
    80001332:	412686b3          	sub	a3,a3,s2
    80001336:	864a                	mv	a2,s2
    80001338:	85ca                	mv	a1,s2
    8000133a:	8526                	mv	a0,s1
    8000133c:	00000097          	auipc	ra,0x0
    80001340:	f38080e7          	jalr	-200(ra) # 80001274 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001344:	4729                	li	a4,10
    80001346:	6685                	lui	a3,0x1
    80001348:	00006617          	auipc	a2,0x6
    8000134c:	cb860613          	addi	a2,a2,-840 # 80007000 <_trampoline>
    80001350:	040005b7          	lui	a1,0x4000
    80001354:	15fd                	addi	a1,a1,-1
    80001356:	05b2                	slli	a1,a1,0xc
    80001358:	8526                	mv	a0,s1
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	f1a080e7          	jalr	-230(ra) # 80001274 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001362:	8526                	mv	a0,s1
    80001364:	00000097          	auipc	ra,0x0
    80001368:	738080e7          	jalr	1848(ra) # 80001a9c <proc_mapstacks>
}
    8000136c:	8526                	mv	a0,s1
    8000136e:	60e2                	ld	ra,24(sp)
    80001370:	6442                	ld	s0,16(sp)
    80001372:	64a2                	ld	s1,8(sp)
    80001374:	6902                	ld	s2,0(sp)
    80001376:	6105                	addi	sp,sp,32
    80001378:	8082                	ret

000000008000137a <kvminit>:
{
    8000137a:	1141                	addi	sp,sp,-16
    8000137c:	e406                	sd	ra,8(sp)
    8000137e:	e022                	sd	s0,0(sp)
    80001380:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001382:	00000097          	auipc	ra,0x0
    80001386:	f22080e7          	jalr	-222(ra) # 800012a4 <kvmmake>
    8000138a:	00008797          	auipc	a5,0x8
    8000138e:	c8a7bb23          	sd	a0,-874(a5) # 80009020 <kernel_pagetable>
}
    80001392:	60a2                	ld	ra,8(sp)
    80001394:	6402                	ld	s0,0(sp)
    80001396:	0141                	addi	sp,sp,16
    80001398:	8082                	ret

000000008000139a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000139a:	715d                	addi	sp,sp,-80
    8000139c:	e486                	sd	ra,72(sp)
    8000139e:	e0a2                	sd	s0,64(sp)
    800013a0:	fc26                	sd	s1,56(sp)
    800013a2:	f84a                	sd	s2,48(sp)
    800013a4:	f44e                	sd	s3,40(sp)
    800013a6:	f052                	sd	s4,32(sp)
    800013a8:	ec56                	sd	s5,24(sp)
    800013aa:	e85a                	sd	s6,16(sp)
    800013ac:	e45e                	sd	s7,8(sp)
    800013ae:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013b0:	03459793          	slli	a5,a1,0x34
    800013b4:	e795                	bnez	a5,800013e0 <uvmunmap+0x46>
    800013b6:	8a2a                	mv	s4,a0
    800013b8:	892e                	mv	s2,a1
    800013ba:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013bc:	0632                	slli	a2,a2,0xc
    800013be:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013c2:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c4:	6b05                	lui	s6,0x1
    800013c6:	0735e863          	bltu	a1,s3,80001436 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013ca:	60a6                	ld	ra,72(sp)
    800013cc:	6406                	ld	s0,64(sp)
    800013ce:	74e2                	ld	s1,56(sp)
    800013d0:	7942                	ld	s2,48(sp)
    800013d2:	79a2                	ld	s3,40(sp)
    800013d4:	7a02                	ld	s4,32(sp)
    800013d6:	6ae2                	ld	s5,24(sp)
    800013d8:	6b42                	ld	s6,16(sp)
    800013da:	6ba2                	ld	s7,8(sp)
    800013dc:	6161                	addi	sp,sp,80
    800013de:	8082                	ret
    panic("uvmunmap: not aligned");
    800013e0:	00007517          	auipc	a0,0x7
    800013e4:	d6050513          	addi	a0,a0,-672 # 80008140 <digits+0x100>
    800013e8:	fffff097          	auipc	ra,0xfffff
    800013ec:	156080e7          	jalr	342(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800013f0:	00007517          	auipc	a0,0x7
    800013f4:	d6850513          	addi	a0,a0,-664 # 80008158 <digits+0x118>
    800013f8:	fffff097          	auipc	ra,0xfffff
    800013fc:	146080e7          	jalr	326(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001400:	00007517          	auipc	a0,0x7
    80001404:	d6850513          	addi	a0,a0,-664 # 80008168 <digits+0x128>
    80001408:	fffff097          	auipc	ra,0xfffff
    8000140c:	136080e7          	jalr	310(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001410:	00007517          	auipc	a0,0x7
    80001414:	d7050513          	addi	a0,a0,-656 # 80008180 <digits+0x140>
    80001418:	fffff097          	auipc	ra,0xfffff
    8000141c:	126080e7          	jalr	294(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001420:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001422:	0532                	slli	a0,a0,0xc
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	5d4080e7          	jalr	1492(ra) # 800009f8 <kfree>
    *pte = 0;
    8000142c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001430:	995a                	add	s2,s2,s6
    80001432:	f9397ce3          	bgeu	s2,s3,800013ca <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001436:	4601                	li	a2,0
    80001438:	85ca                	mv	a1,s2
    8000143a:	8552                	mv	a0,s4
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	cb0080e7          	jalr	-848(ra) # 800010ec <walk>
    80001444:	84aa                	mv	s1,a0
    80001446:	d54d                	beqz	a0,800013f0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001448:	6108                	ld	a0,0(a0)
    8000144a:	00157793          	andi	a5,a0,1
    8000144e:	dbcd                	beqz	a5,80001400 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001450:	3ff57793          	andi	a5,a0,1023
    80001454:	fb778ee3          	beq	a5,s7,80001410 <uvmunmap+0x76>
    if(do_free){
    80001458:	fc0a8ae3          	beqz	s5,8000142c <uvmunmap+0x92>
    8000145c:	b7d1                	j	80001420 <uvmunmap+0x86>

000000008000145e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000145e:	1101                	addi	sp,sp,-32
    80001460:	ec06                	sd	ra,24(sp)
    80001462:	e822                	sd	s0,16(sp)
    80001464:	e426                	sd	s1,8(sp)
    80001466:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	68c080e7          	jalr	1676(ra) # 80000af4 <kalloc>
    80001470:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001472:	c519                	beqz	a0,80001480 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001474:	6605                	lui	a2,0x1
    80001476:	4581                	li	a1,0
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	868080e7          	jalr	-1944(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001480:	8526                	mv	a0,s1
    80001482:	60e2                	ld	ra,24(sp)
    80001484:	6442                	ld	s0,16(sp)
    80001486:	64a2                	ld	s1,8(sp)
    80001488:	6105                	addi	sp,sp,32
    8000148a:	8082                	ret

000000008000148c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000148c:	7179                	addi	sp,sp,-48
    8000148e:	f406                	sd	ra,40(sp)
    80001490:	f022                	sd	s0,32(sp)
    80001492:	ec26                	sd	s1,24(sp)
    80001494:	e84a                	sd	s2,16(sp)
    80001496:	e44e                	sd	s3,8(sp)
    80001498:	e052                	sd	s4,0(sp)
    8000149a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000149c:	6785                	lui	a5,0x1
    8000149e:	04f67863          	bgeu	a2,a5,800014ee <uvminit+0x62>
    800014a2:	8a2a                	mv	s4,a0
    800014a4:	89ae                	mv	s3,a1
    800014a6:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014a8:	fffff097          	auipc	ra,0xfffff
    800014ac:	64c080e7          	jalr	1612(ra) # 80000af4 <kalloc>
    800014b0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014b2:	6605                	lui	a2,0x1
    800014b4:	4581                	li	a1,0
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	82a080e7          	jalr	-2006(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014be:	4779                	li	a4,30
    800014c0:	86ca                	mv	a3,s2
    800014c2:	6605                	lui	a2,0x1
    800014c4:	4581                	li	a1,0
    800014c6:	8552                	mv	a0,s4
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	d0c080e7          	jalr	-756(ra) # 800011d4 <mappages>
  memmove(mem, src, sz);
    800014d0:	8626                	mv	a2,s1
    800014d2:	85ce                	mv	a1,s3
    800014d4:	854a                	mv	a0,s2
    800014d6:	00000097          	auipc	ra,0x0
    800014da:	86a080e7          	jalr	-1942(ra) # 80000d40 <memmove>
}
    800014de:	70a2                	ld	ra,40(sp)
    800014e0:	7402                	ld	s0,32(sp)
    800014e2:	64e2                	ld	s1,24(sp)
    800014e4:	6942                	ld	s2,16(sp)
    800014e6:	69a2                	ld	s3,8(sp)
    800014e8:	6a02                	ld	s4,0(sp)
    800014ea:	6145                	addi	sp,sp,48
    800014ec:	8082                	ret
    panic("inituvm: more than a page");
    800014ee:	00007517          	auipc	a0,0x7
    800014f2:	caa50513          	addi	a0,a0,-854 # 80008198 <digits+0x158>
    800014f6:	fffff097          	auipc	ra,0xfffff
    800014fa:	048080e7          	jalr	72(ra) # 8000053e <panic>

00000000800014fe <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014fe:	1101                	addi	sp,sp,-32
    80001500:	ec06                	sd	ra,24(sp)
    80001502:	e822                	sd	s0,16(sp)
    80001504:	e426                	sd	s1,8(sp)
    80001506:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001508:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000150a:	00b67d63          	bgeu	a2,a1,80001524 <uvmdealloc+0x26>
    8000150e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001510:	6785                	lui	a5,0x1
    80001512:	17fd                	addi	a5,a5,-1
    80001514:	00f60733          	add	a4,a2,a5
    80001518:	767d                	lui	a2,0xfffff
    8000151a:	8f71                	and	a4,a4,a2
    8000151c:	97ae                	add	a5,a5,a1
    8000151e:	8ff1                	and	a5,a5,a2
    80001520:	00f76863          	bltu	a4,a5,80001530 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001524:	8526                	mv	a0,s1
    80001526:	60e2                	ld	ra,24(sp)
    80001528:	6442                	ld	s0,16(sp)
    8000152a:	64a2                	ld	s1,8(sp)
    8000152c:	6105                	addi	sp,sp,32
    8000152e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001530:	8f99                	sub	a5,a5,a4
    80001532:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001534:	4685                	li	a3,1
    80001536:	0007861b          	sext.w	a2,a5
    8000153a:	85ba                	mv	a1,a4
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	e5e080e7          	jalr	-418(ra) # 8000139a <uvmunmap>
    80001544:	b7c5                	j	80001524 <uvmdealloc+0x26>

0000000080001546 <uvmalloc>:
  if(newsz < oldsz)
    80001546:	0ab66163          	bltu	a2,a1,800015e8 <uvmalloc+0xa2>
{
    8000154a:	7139                	addi	sp,sp,-64
    8000154c:	fc06                	sd	ra,56(sp)
    8000154e:	f822                	sd	s0,48(sp)
    80001550:	f426                	sd	s1,40(sp)
    80001552:	f04a                	sd	s2,32(sp)
    80001554:	ec4e                	sd	s3,24(sp)
    80001556:	e852                	sd	s4,16(sp)
    80001558:	e456                	sd	s5,8(sp)
    8000155a:	0080                	addi	s0,sp,64
    8000155c:	8aaa                	mv	s5,a0
    8000155e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001560:	6985                	lui	s3,0x1
    80001562:	19fd                	addi	s3,s3,-1
    80001564:	95ce                	add	a1,a1,s3
    80001566:	79fd                	lui	s3,0xfffff
    80001568:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000156c:	08c9f063          	bgeu	s3,a2,800015ec <uvmalloc+0xa6>
    80001570:	894e                	mv	s2,s3
    mem = kalloc();
    80001572:	fffff097          	auipc	ra,0xfffff
    80001576:	582080e7          	jalr	1410(ra) # 80000af4 <kalloc>
    8000157a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000157c:	c51d                	beqz	a0,800015aa <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000157e:	6605                	lui	a2,0x1
    80001580:	4581                	li	a1,0
    80001582:	fffff097          	auipc	ra,0xfffff
    80001586:	75e080e7          	jalr	1886(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000158a:	4779                	li	a4,30
    8000158c:	86a6                	mv	a3,s1
    8000158e:	6605                	lui	a2,0x1
    80001590:	85ca                	mv	a1,s2
    80001592:	8556                	mv	a0,s5
    80001594:	00000097          	auipc	ra,0x0
    80001598:	c40080e7          	jalr	-960(ra) # 800011d4 <mappages>
    8000159c:	e905                	bnez	a0,800015cc <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000159e:	6785                	lui	a5,0x1
    800015a0:	993e                	add	s2,s2,a5
    800015a2:	fd4968e3          	bltu	s2,s4,80001572 <uvmalloc+0x2c>
  return newsz;
    800015a6:	8552                	mv	a0,s4
    800015a8:	a809                	j	800015ba <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015aa:	864e                	mv	a2,s3
    800015ac:	85ca                	mv	a1,s2
    800015ae:	8556                	mv	a0,s5
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	f4e080e7          	jalr	-178(ra) # 800014fe <uvmdealloc>
      return 0;
    800015b8:	4501                	li	a0,0
}
    800015ba:	70e2                	ld	ra,56(sp)
    800015bc:	7442                	ld	s0,48(sp)
    800015be:	74a2                	ld	s1,40(sp)
    800015c0:	7902                	ld	s2,32(sp)
    800015c2:	69e2                	ld	s3,24(sp)
    800015c4:	6a42                	ld	s4,16(sp)
    800015c6:	6aa2                	ld	s5,8(sp)
    800015c8:	6121                	addi	sp,sp,64
    800015ca:	8082                	ret
      kfree(mem);
    800015cc:	8526                	mv	a0,s1
    800015ce:	fffff097          	auipc	ra,0xfffff
    800015d2:	42a080e7          	jalr	1066(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015d6:	864e                	mv	a2,s3
    800015d8:	85ca                	mv	a1,s2
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	f22080e7          	jalr	-222(ra) # 800014fe <uvmdealloc>
      return 0;
    800015e4:	4501                	li	a0,0
    800015e6:	bfd1                	j	800015ba <uvmalloc+0x74>
    return oldsz;
    800015e8:	852e                	mv	a0,a1
}
    800015ea:	8082                	ret
  return newsz;
    800015ec:	8532                	mv	a0,a2
    800015ee:	b7f1                	j	800015ba <uvmalloc+0x74>

00000000800015f0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015f0:	7179                	addi	sp,sp,-48
    800015f2:	f406                	sd	ra,40(sp)
    800015f4:	f022                	sd	s0,32(sp)
    800015f6:	ec26                	sd	s1,24(sp)
    800015f8:	e84a                	sd	s2,16(sp)
    800015fa:	e44e                	sd	s3,8(sp)
    800015fc:	e052                	sd	s4,0(sp)
    800015fe:	1800                	addi	s0,sp,48
    80001600:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001602:	84aa                	mv	s1,a0
    80001604:	6905                	lui	s2,0x1
    80001606:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001608:	4985                	li	s3,1
    8000160a:	a821                	j	80001622 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000160c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000160e:	0532                	slli	a0,a0,0xc
    80001610:	00000097          	auipc	ra,0x0
    80001614:	fe0080e7          	jalr	-32(ra) # 800015f0 <freewalk>
      pagetable[i] = 0;
    80001618:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000161c:	04a1                	addi	s1,s1,8
    8000161e:	03248163          	beq	s1,s2,80001640 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001622:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001624:	00f57793          	andi	a5,a0,15
    80001628:	ff3782e3          	beq	a5,s3,8000160c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000162c:	8905                	andi	a0,a0,1
    8000162e:	d57d                	beqz	a0,8000161c <freewalk+0x2c>
      panic("freewalk: leaf");
    80001630:	00007517          	auipc	a0,0x7
    80001634:	b8850513          	addi	a0,a0,-1144 # 800081b8 <digits+0x178>
    80001638:	fffff097          	auipc	ra,0xfffff
    8000163c:	f06080e7          	jalr	-250(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001640:	8552                	mv	a0,s4
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	3b6080e7          	jalr	950(ra) # 800009f8 <kfree>
}
    8000164a:	70a2                	ld	ra,40(sp)
    8000164c:	7402                	ld	s0,32(sp)
    8000164e:	64e2                	ld	s1,24(sp)
    80001650:	6942                	ld	s2,16(sp)
    80001652:	69a2                	ld	s3,8(sp)
    80001654:	6a02                	ld	s4,0(sp)
    80001656:	6145                	addi	sp,sp,48
    80001658:	8082                	ret

000000008000165a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000165a:	1101                	addi	sp,sp,-32
    8000165c:	ec06                	sd	ra,24(sp)
    8000165e:	e822                	sd	s0,16(sp)
    80001660:	e426                	sd	s1,8(sp)
    80001662:	1000                	addi	s0,sp,32
    80001664:	84aa                	mv	s1,a0
  if(sz > 0)
    80001666:	e999                	bnez	a1,8000167c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001668:	8526                	mv	a0,s1
    8000166a:	00000097          	auipc	ra,0x0
    8000166e:	f86080e7          	jalr	-122(ra) # 800015f0 <freewalk>
}
    80001672:	60e2                	ld	ra,24(sp)
    80001674:	6442                	ld	s0,16(sp)
    80001676:	64a2                	ld	s1,8(sp)
    80001678:	6105                	addi	sp,sp,32
    8000167a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000167c:	6605                	lui	a2,0x1
    8000167e:	167d                	addi	a2,a2,-1
    80001680:	962e                	add	a2,a2,a1
    80001682:	4685                	li	a3,1
    80001684:	8231                	srli	a2,a2,0xc
    80001686:	4581                	li	a1,0
    80001688:	00000097          	auipc	ra,0x0
    8000168c:	d12080e7          	jalr	-750(ra) # 8000139a <uvmunmap>
    80001690:	bfe1                	j	80001668 <uvmfree+0xe>

0000000080001692 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001692:	c679                	beqz	a2,80001760 <uvmcopy+0xce>
{
    80001694:	715d                	addi	sp,sp,-80
    80001696:	e486                	sd	ra,72(sp)
    80001698:	e0a2                	sd	s0,64(sp)
    8000169a:	fc26                	sd	s1,56(sp)
    8000169c:	f84a                	sd	s2,48(sp)
    8000169e:	f44e                	sd	s3,40(sp)
    800016a0:	f052                	sd	s4,32(sp)
    800016a2:	ec56                	sd	s5,24(sp)
    800016a4:	e85a                	sd	s6,16(sp)
    800016a6:	e45e                	sd	s7,8(sp)
    800016a8:	0880                	addi	s0,sp,80
    800016aa:	8b2a                	mv	s6,a0
    800016ac:	8aae                	mv	s5,a1
    800016ae:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016b0:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800016b2:	4601                	li	a2,0
    800016b4:	85ce                	mv	a1,s3
    800016b6:	855a                	mv	a0,s6
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	a34080e7          	jalr	-1484(ra) # 800010ec <walk>
    800016c0:	c531                	beqz	a0,8000170c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016c2:	6118                	ld	a4,0(a0)
    800016c4:	00177793          	andi	a5,a4,1
    800016c8:	cbb1                	beqz	a5,8000171c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016ca:	00a75593          	srli	a1,a4,0xa
    800016ce:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016d2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016d6:	fffff097          	auipc	ra,0xfffff
    800016da:	41e080e7          	jalr	1054(ra) # 80000af4 <kalloc>
    800016de:	892a                	mv	s2,a0
    800016e0:	c939                	beqz	a0,80001736 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016e2:	6605                	lui	a2,0x1
    800016e4:	85de                	mv	a1,s7
    800016e6:	fffff097          	auipc	ra,0xfffff
    800016ea:	65a080e7          	jalr	1626(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016ee:	8726                	mv	a4,s1
    800016f0:	86ca                	mv	a3,s2
    800016f2:	6605                	lui	a2,0x1
    800016f4:	85ce                	mv	a1,s3
    800016f6:	8556                	mv	a0,s5
    800016f8:	00000097          	auipc	ra,0x0
    800016fc:	adc080e7          	jalr	-1316(ra) # 800011d4 <mappages>
    80001700:	e515                	bnez	a0,8000172c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001702:	6785                	lui	a5,0x1
    80001704:	99be                	add	s3,s3,a5
    80001706:	fb49e6e3          	bltu	s3,s4,800016b2 <uvmcopy+0x20>
    8000170a:	a081                	j	8000174a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000170c:	00007517          	auipc	a0,0x7
    80001710:	abc50513          	addi	a0,a0,-1348 # 800081c8 <digits+0x188>
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	e2a080e7          	jalr	-470(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000171c:	00007517          	auipc	a0,0x7
    80001720:	acc50513          	addi	a0,a0,-1332 # 800081e8 <digits+0x1a8>
    80001724:	fffff097          	auipc	ra,0xfffff
    80001728:	e1a080e7          	jalr	-486(ra) # 8000053e <panic>
      kfree(mem);
    8000172c:	854a                	mv	a0,s2
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	2ca080e7          	jalr	714(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001736:	4685                	li	a3,1
    80001738:	00c9d613          	srli	a2,s3,0xc
    8000173c:	4581                	li	a1,0
    8000173e:	8556                	mv	a0,s5
    80001740:	00000097          	auipc	ra,0x0
    80001744:	c5a080e7          	jalr	-934(ra) # 8000139a <uvmunmap>
  return -1;
    80001748:	557d                	li	a0,-1
}
    8000174a:	60a6                	ld	ra,72(sp)
    8000174c:	6406                	ld	s0,64(sp)
    8000174e:	74e2                	ld	s1,56(sp)
    80001750:	7942                	ld	s2,48(sp)
    80001752:	79a2                	ld	s3,40(sp)
    80001754:	7a02                	ld	s4,32(sp)
    80001756:	6ae2                	ld	s5,24(sp)
    80001758:	6b42                	ld	s6,16(sp)
    8000175a:	6ba2                	ld	s7,8(sp)
    8000175c:	6161                	addi	sp,sp,80
    8000175e:	8082                	ret
  return 0;
    80001760:	4501                	li	a0,0
}
    80001762:	8082                	ret

0000000080001764 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001764:	1141                	addi	sp,sp,-16
    80001766:	e406                	sd	ra,8(sp)
    80001768:	e022                	sd	s0,0(sp)
    8000176a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000176c:	4601                	li	a2,0
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	97e080e7          	jalr	-1666(ra) # 800010ec <walk>
  if(pte == 0)
    80001776:	c901                	beqz	a0,80001786 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001778:	611c                	ld	a5,0(a0)
    8000177a:	9bbd                	andi	a5,a5,-17
    8000177c:	e11c                	sd	a5,0(a0)
}
    8000177e:	60a2                	ld	ra,8(sp)
    80001780:	6402                	ld	s0,0(sp)
    80001782:	0141                	addi	sp,sp,16
    80001784:	8082                	ret
    panic("uvmclear");
    80001786:	00007517          	auipc	a0,0x7
    8000178a:	a8250513          	addi	a0,a0,-1406 # 80008208 <digits+0x1c8>
    8000178e:	fffff097          	auipc	ra,0xfffff
    80001792:	db0080e7          	jalr	-592(ra) # 8000053e <panic>

0000000080001796 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001796:	c6bd                	beqz	a3,80001804 <copyout+0x6e>
{
    80001798:	715d                	addi	sp,sp,-80
    8000179a:	e486                	sd	ra,72(sp)
    8000179c:	e0a2                	sd	s0,64(sp)
    8000179e:	fc26                	sd	s1,56(sp)
    800017a0:	f84a                	sd	s2,48(sp)
    800017a2:	f44e                	sd	s3,40(sp)
    800017a4:	f052                	sd	s4,32(sp)
    800017a6:	ec56                	sd	s5,24(sp)
    800017a8:	e85a                	sd	s6,16(sp)
    800017aa:	e45e                	sd	s7,8(sp)
    800017ac:	e062                	sd	s8,0(sp)
    800017ae:	0880                	addi	s0,sp,80
    800017b0:	8b2a                	mv	s6,a0
    800017b2:	8c2e                	mv	s8,a1
    800017b4:	8a32                	mv	s4,a2
    800017b6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017b8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017ba:	6a85                	lui	s5,0x1
    800017bc:	a015                	j	800017e0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017be:	9562                	add	a0,a0,s8
    800017c0:	0004861b          	sext.w	a2,s1
    800017c4:	85d2                	mv	a1,s4
    800017c6:	41250533          	sub	a0,a0,s2
    800017ca:	fffff097          	auipc	ra,0xfffff
    800017ce:	576080e7          	jalr	1398(ra) # 80000d40 <memmove>

    len -= n;
    800017d2:	409989b3          	sub	s3,s3,s1
    src += n;
    800017d6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017d8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017dc:	02098263          	beqz	s3,80001800 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017e0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017e4:	85ca                	mv	a1,s2
    800017e6:	855a                	mv	a0,s6
    800017e8:	00000097          	auipc	ra,0x0
    800017ec:	9aa080e7          	jalr	-1622(ra) # 80001192 <walkaddr>
    if(pa0 == 0)
    800017f0:	cd01                	beqz	a0,80001808 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017f2:	418904b3          	sub	s1,s2,s8
    800017f6:	94d6                	add	s1,s1,s5
    if(n > len)
    800017f8:	fc99f3e3          	bgeu	s3,s1,800017be <copyout+0x28>
    800017fc:	84ce                	mv	s1,s3
    800017fe:	b7c1                	j	800017be <copyout+0x28>
  }
  return 0;
    80001800:	4501                	li	a0,0
    80001802:	a021                	j	8000180a <copyout+0x74>
    80001804:	4501                	li	a0,0
}
    80001806:	8082                	ret
      return -1;
    80001808:	557d                	li	a0,-1
}
    8000180a:	60a6                	ld	ra,72(sp)
    8000180c:	6406                	ld	s0,64(sp)
    8000180e:	74e2                	ld	s1,56(sp)
    80001810:	7942                	ld	s2,48(sp)
    80001812:	79a2                	ld	s3,40(sp)
    80001814:	7a02                	ld	s4,32(sp)
    80001816:	6ae2                	ld	s5,24(sp)
    80001818:	6b42                	ld	s6,16(sp)
    8000181a:	6ba2                	ld	s7,8(sp)
    8000181c:	6c02                	ld	s8,0(sp)
    8000181e:	6161                	addi	sp,sp,80
    80001820:	8082                	ret

0000000080001822 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001822:	c6bd                	beqz	a3,80001890 <copyin+0x6e>
{
    80001824:	715d                	addi	sp,sp,-80
    80001826:	e486                	sd	ra,72(sp)
    80001828:	e0a2                	sd	s0,64(sp)
    8000182a:	fc26                	sd	s1,56(sp)
    8000182c:	f84a                	sd	s2,48(sp)
    8000182e:	f44e                	sd	s3,40(sp)
    80001830:	f052                	sd	s4,32(sp)
    80001832:	ec56                	sd	s5,24(sp)
    80001834:	e85a                	sd	s6,16(sp)
    80001836:	e45e                	sd	s7,8(sp)
    80001838:	e062                	sd	s8,0(sp)
    8000183a:	0880                	addi	s0,sp,80
    8000183c:	8b2a                	mv	s6,a0
    8000183e:	8a2e                	mv	s4,a1
    80001840:	8c32                	mv	s8,a2
    80001842:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001844:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001846:	6a85                	lui	s5,0x1
    80001848:	a015                	j	8000186c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000184a:	9562                	add	a0,a0,s8
    8000184c:	0004861b          	sext.w	a2,s1
    80001850:	412505b3          	sub	a1,a0,s2
    80001854:	8552                	mv	a0,s4
    80001856:	fffff097          	auipc	ra,0xfffff
    8000185a:	4ea080e7          	jalr	1258(ra) # 80000d40 <memmove>

    len -= n;
    8000185e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001862:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001864:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001868:	02098263          	beqz	s3,8000188c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000186c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001870:	85ca                	mv	a1,s2
    80001872:	855a                	mv	a0,s6
    80001874:	00000097          	auipc	ra,0x0
    80001878:	91e080e7          	jalr	-1762(ra) # 80001192 <walkaddr>
    if(pa0 == 0)
    8000187c:	cd01                	beqz	a0,80001894 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000187e:	418904b3          	sub	s1,s2,s8
    80001882:	94d6                	add	s1,s1,s5
    if(n > len)
    80001884:	fc99f3e3          	bgeu	s3,s1,8000184a <copyin+0x28>
    80001888:	84ce                	mv	s1,s3
    8000188a:	b7c1                	j	8000184a <copyin+0x28>
  }
  return 0;
    8000188c:	4501                	li	a0,0
    8000188e:	a021                	j	80001896 <copyin+0x74>
    80001890:	4501                	li	a0,0
}
    80001892:	8082                	ret
      return -1;
    80001894:	557d                	li	a0,-1
}
    80001896:	60a6                	ld	ra,72(sp)
    80001898:	6406                	ld	s0,64(sp)
    8000189a:	74e2                	ld	s1,56(sp)
    8000189c:	7942                	ld	s2,48(sp)
    8000189e:	79a2                	ld	s3,40(sp)
    800018a0:	7a02                	ld	s4,32(sp)
    800018a2:	6ae2                	ld	s5,24(sp)
    800018a4:	6b42                	ld	s6,16(sp)
    800018a6:	6ba2                	ld	s7,8(sp)
    800018a8:	6c02                	ld	s8,0(sp)
    800018aa:	6161                	addi	sp,sp,80
    800018ac:	8082                	ret

00000000800018ae <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018ae:	c6c5                	beqz	a3,80001956 <copyinstr+0xa8>
{
    800018b0:	715d                	addi	sp,sp,-80
    800018b2:	e486                	sd	ra,72(sp)
    800018b4:	e0a2                	sd	s0,64(sp)
    800018b6:	fc26                	sd	s1,56(sp)
    800018b8:	f84a                	sd	s2,48(sp)
    800018ba:	f44e                	sd	s3,40(sp)
    800018bc:	f052                	sd	s4,32(sp)
    800018be:	ec56                	sd	s5,24(sp)
    800018c0:	e85a                	sd	s6,16(sp)
    800018c2:	e45e                	sd	s7,8(sp)
    800018c4:	0880                	addi	s0,sp,80
    800018c6:	8a2a                	mv	s4,a0
    800018c8:	8b2e                	mv	s6,a1
    800018ca:	8bb2                	mv	s7,a2
    800018cc:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018ce:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018d0:	6985                	lui	s3,0x1
    800018d2:	a035                	j	800018fe <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018d4:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018d8:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018da:	0017b793          	seqz	a5,a5
    800018de:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018e2:	60a6                	ld	ra,72(sp)
    800018e4:	6406                	ld	s0,64(sp)
    800018e6:	74e2                	ld	s1,56(sp)
    800018e8:	7942                	ld	s2,48(sp)
    800018ea:	79a2                	ld	s3,40(sp)
    800018ec:	7a02                	ld	s4,32(sp)
    800018ee:	6ae2                	ld	s5,24(sp)
    800018f0:	6b42                	ld	s6,16(sp)
    800018f2:	6ba2                	ld	s7,8(sp)
    800018f4:	6161                	addi	sp,sp,80
    800018f6:	8082                	ret
    srcva = va0 + PGSIZE;
    800018f8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018fc:	c8a9                	beqz	s1,8000194e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018fe:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001902:	85ca                	mv	a1,s2
    80001904:	8552                	mv	a0,s4
    80001906:	00000097          	auipc	ra,0x0
    8000190a:	88c080e7          	jalr	-1908(ra) # 80001192 <walkaddr>
    if(pa0 == 0)
    8000190e:	c131                	beqz	a0,80001952 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001910:	41790833          	sub	a6,s2,s7
    80001914:	984e                	add	a6,a6,s3
    if(n > max)
    80001916:	0104f363          	bgeu	s1,a6,8000191c <copyinstr+0x6e>
    8000191a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000191c:	955e                	add	a0,a0,s7
    8000191e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001922:	fc080be3          	beqz	a6,800018f8 <copyinstr+0x4a>
    80001926:	985a                	add	a6,a6,s6
    80001928:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000192a:	41650633          	sub	a2,a0,s6
    8000192e:	14fd                	addi	s1,s1,-1
    80001930:	9b26                	add	s6,s6,s1
    80001932:	00f60733          	add	a4,a2,a5
    80001936:	00074703          	lbu	a4,0(a4)
    8000193a:	df49                	beqz	a4,800018d4 <copyinstr+0x26>
        *dst = *p;
    8000193c:	00e78023          	sb	a4,0(a5)
      --max;
    80001940:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001944:	0785                	addi	a5,a5,1
    while(n > 0){
    80001946:	ff0796e3          	bne	a5,a6,80001932 <copyinstr+0x84>
      dst++;
    8000194a:	8b42                	mv	s6,a6
    8000194c:	b775                	j	800018f8 <copyinstr+0x4a>
    8000194e:	4781                	li	a5,0
    80001950:	b769                	j	800018da <copyinstr+0x2c>
      return -1;
    80001952:	557d                	li	a0,-1
    80001954:	b779                	j	800018e2 <copyinstr+0x34>
  int got_null = 0;
    80001956:	4781                	li	a5,0
  if(got_null){
    80001958:	0017b793          	seqz	a5,a5
    8000195c:	40f00533          	neg	a0,a5
}
    80001960:	8082                	ret

0000000080001962 <stateChange>:
struct spinlock wait_lock;

//******************OSB***********************

void stateChange(struct proc* p)
{
    80001962:	1141                	addi	sp,sp,-16
    80001964:	e422                	sd	s0,8(sp)
    80001966:	0800                	addi	s0,sp,16
  
  switch (p->state)
    80001968:	4d1c                	lw	a5,24(a0)
    8000196a:	470d                	li	a4,3
    8000196c:	02e78a63          	beq	a5,a4,800019a0 <stateChange+0x3e>
    80001970:	4711                	li	a4,4
    80001972:	04e78163          	beq	a5,a4,800019b4 <stateChange+0x52>
    80001976:	4709                	li	a4,2
    80001978:	00e78a63          	beq	a5,a4,8000198c <stateChange+0x2a>
    break;
  
  default:
    break;
  }
  p->last_time_changed = ticks;
    8000197c:	00007797          	auipc	a5,0x7
    80001980:	6d47a783          	lw	a5,1748(a5) # 80009050 <ticks>
    80001984:	c57c                	sw	a5,76(a0)
}
    80001986:	6422                	ld	s0,8(sp)
    80001988:	0141                	addi	sp,sp,16
    8000198a:	8082                	ret
    p->sleeping_time += ticks - p->last_time_changed;
    8000198c:	493c                	lw	a5,80(a0)
    8000198e:	00007717          	auipc	a4,0x7
    80001992:	6c272703          	lw	a4,1730(a4) # 80009050 <ticks>
    80001996:	9fb9                	addw	a5,a5,a4
    80001998:	4578                	lw	a4,76(a0)
    8000199a:	9f99                	subw	a5,a5,a4
    8000199c:	c93c                	sw	a5,80(a0)
    break;
    8000199e:	bff9                	j	8000197c <stateChange+0x1a>
    p->runnable_time += ticks - p->last_time_changed;
    800019a0:	497c                	lw	a5,84(a0)
    800019a2:	00007717          	auipc	a4,0x7
    800019a6:	6ae72703          	lw	a4,1710(a4) # 80009050 <ticks>
    800019aa:	9fb9                	addw	a5,a5,a4
    800019ac:	4578                	lw	a4,76(a0)
    800019ae:	9f99                	subw	a5,a5,a4
    800019b0:	c97c                	sw	a5,84(a0)
    break;
    800019b2:	b7e9                	j	8000197c <stateChange+0x1a>
    p->running_time += ticks - p->last_time_changed;
    800019b4:	4d3c                	lw	a5,88(a0)
    800019b6:	00007717          	auipc	a4,0x7
    800019ba:	69a72703          	lw	a4,1690(a4) # 80009050 <ticks>
    800019be:	9fb9                	addw	a5,a5,a4
    800019c0:	4578                	lw	a4,76(a0)
    800019c2:	9f99                	subw	a5,a5,a4
    800019c4:	cd3c                	sw	a5,88(a0)
    break;
    800019c6:	bf5d                	j	8000197c <stateChange+0x1a>

00000000800019c8 <changeStateToRunnable>:

void changeStateToRunnable(struct proc* p)
{
    800019c8:	1101                	addi	sp,sp,-32
    800019ca:	ec06                	sd	ra,24(sp)
    800019cc:	e822                	sd	s0,16(sp)
    800019ce:	e426                	sd	s1,8(sp)
    800019d0:	1000                	addi	s0,sp,32
    800019d2:	84aa                	mv	s1,a0
  stateChange(p);
    800019d4:	00000097          	auipc	ra,0x0
    800019d8:	f8e080e7          	jalr	-114(ra) # 80001962 <stateChange>
  p->state = RUNNABLE;
    800019dc:	478d                	li	a5,3
    800019de:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    800019e0:	00007797          	auipc	a5,0x7
    800019e4:	6707a783          	lw	a5,1648(a5) # 80009050 <ticks>
    800019e8:	c4bc                	sw	a5,72(s1)
}
    800019ea:	60e2                	ld	ra,24(sp)
    800019ec:	6442                	ld	s0,16(sp)
    800019ee:	64a2                	ld	s1,8(sp)
    800019f0:	6105                	addi	sp,sp,32
    800019f2:	8082                	ret

00000000800019f4 <print_stats>:

  return 0;
}

int print_stats(void)
{
    800019f4:	1101                	addi	sp,sp,-32
    800019f6:	ec06                	sd	ra,24(sp)
    800019f8:	e822                	sd	s0,16(sp)
    800019fa:	e426                	sd	s1,8(sp)
    800019fc:	1000                	addi	s0,sp,32
  printf("sleeping_processes_mean: %d\n", (sleeping_processes_total / processes_count));
    800019fe:	00007497          	auipc	s1,0x7
    80001a02:	63648493          	addi	s1,s1,1590 # 80009034 <processes_count>
    80001a06:	409c                	lw	a5,0(s1)
    80001a08:	00007597          	auipc	a1,0x7
    80001a0c:	6385a583          	lw	a1,1592(a1) # 80009040 <sleeping_processes_total>
    80001a10:	02f5c5bb          	divw	a1,a1,a5
    80001a14:	00007517          	auipc	a0,0x7
    80001a18:	80450513          	addi	a0,a0,-2044 # 80008218 <digits+0x1d8>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	b6c080e7          	jalr	-1172(ra) # 80000588 <printf>
  printf("runnable_time_mean: %d\n", (runnable_time_total / processes_count));
    80001a24:	409c                	lw	a5,0(s1)
    80001a26:	00007597          	auipc	a1,0x7
    80001a2a:	6165a583          	lw	a1,1558(a1) # 8000903c <runnable_time_total>
    80001a2e:	02f5c5bb          	divw	a1,a1,a5
    80001a32:	00007517          	auipc	a0,0x7
    80001a36:	80650513          	addi	a0,a0,-2042 # 80008238 <digits+0x1f8>
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	b4e080e7          	jalr	-1202(ra) # 80000588 <printf>
  printf("running_time_mean: %d\n", (running_time_total / processes_count));
    80001a42:	409c                	lw	a5,0(s1)
    80001a44:	00007597          	auipc	a1,0x7
    80001a48:	5f45a583          	lw	a1,1524(a1) # 80009038 <running_time_total>
    80001a4c:	02f5c5bb          	divw	a1,a1,a5
    80001a50:	00007517          	auipc	a0,0x7
    80001a54:	80050513          	addi	a0,a0,-2048 # 80008250 <digits+0x210>
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	b30080e7          	jalr	-1232(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    80001a60:	00007597          	auipc	a1,0x7
    80001a64:	5d05a583          	lw	a1,1488(a1) # 80009030 <program_time>
    80001a68:	00007517          	auipc	a0,0x7
    80001a6c:	80050513          	addi	a0,a0,-2048 # 80008268 <digits+0x228>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	b18080e7          	jalr	-1256(ra) # 80000588 <printf>
  printf("cpu_utilization: %d%%\n", cpu_utilization);
    80001a78:	00007597          	auipc	a1,0x7
    80001a7c:	5b45a583          	lw	a1,1460(a1) # 8000902c <cpu_utilization>
    80001a80:	00007517          	auipc	a0,0x7
    80001a84:	80050513          	addi	a0,a0,-2048 # 80008280 <digits+0x240>
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	b00080e7          	jalr	-1280(ra) # 80000588 <printf>

  return 0;
}
    80001a90:	4501                	li	a0,0
    80001a92:	60e2                	ld	ra,24(sp)
    80001a94:	6442                	ld	s0,16(sp)
    80001a96:	64a2                	ld	s1,8(sp)
    80001a98:	6105                	addi	sp,sp,32
    80001a9a:	8082                	ret

0000000080001a9c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001a9c:	7139                	addi	sp,sp,-64
    80001a9e:	fc06                	sd	ra,56(sp)
    80001aa0:	f822                	sd	s0,48(sp)
    80001aa2:	f426                	sd	s1,40(sp)
    80001aa4:	f04a                	sd	s2,32(sp)
    80001aa6:	ec4e                	sd	s3,24(sp)
    80001aa8:	e852                	sd	s4,16(sp)
    80001aaa:	e456                	sd	s5,8(sp)
    80001aac:	e05a                	sd	s6,0(sp)
    80001aae:	0080                	addi	s0,sp,64
    80001ab0:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab2:	00010497          	auipc	s1,0x10
    80001ab6:	c3e48493          	addi	s1,s1,-962 # 800116f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001aba:	8b26                	mv	s6,s1
    80001abc:	00006a97          	auipc	s5,0x6
    80001ac0:	544a8a93          	addi	s5,s5,1348 # 80008000 <etext>
    80001ac4:	04000937          	lui	s2,0x4000
    80001ac8:	197d                	addi	s2,s2,-1
    80001aca:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001acc:	00016a17          	auipc	s4,0x16
    80001ad0:	e24a0a13          	addi	s4,s4,-476 # 800178f0 <tickslock>
    char *pa = kalloc();
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	020080e7          	jalr	32(ra) # 80000af4 <kalloc>
    80001adc:	862a                	mv	a2,a0
    if(pa == 0)
    80001ade:	c131                	beqz	a0,80001b22 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001ae0:	416485b3          	sub	a1,s1,s6
    80001ae4:	858d                	srai	a1,a1,0x3
    80001ae6:	000ab783          	ld	a5,0(s5)
    80001aea:	02f585b3          	mul	a1,a1,a5
    80001aee:	2585                	addiw	a1,a1,1
    80001af0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001af4:	4719                	li	a4,6
    80001af6:	6685                	lui	a3,0x1
    80001af8:	40b905b3          	sub	a1,s2,a1
    80001afc:	854e                	mv	a0,s3
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	776080e7          	jalr	1910(ra) # 80001274 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b06:	18848493          	addi	s1,s1,392
    80001b0a:	fd4495e3          	bne	s1,s4,80001ad4 <proc_mapstacks+0x38>
  }
}
    80001b0e:	70e2                	ld	ra,56(sp)
    80001b10:	7442                	ld	s0,48(sp)
    80001b12:	74a2                	ld	s1,40(sp)
    80001b14:	7902                	ld	s2,32(sp)
    80001b16:	69e2                	ld	s3,24(sp)
    80001b18:	6a42                	ld	s4,16(sp)
    80001b1a:	6aa2                	ld	s5,8(sp)
    80001b1c:	6b02                	ld	s6,0(sp)
    80001b1e:	6121                	addi	sp,sp,64
    80001b20:	8082                	ret
      panic("kalloc");
    80001b22:	00006517          	auipc	a0,0x6
    80001b26:	77650513          	addi	a0,a0,1910 # 80008298 <digits+0x258>
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	a14080e7          	jalr	-1516(ra) # 8000053e <panic>

0000000080001b32 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b32:	7139                	addi	sp,sp,-64
    80001b34:	fc06                	sd	ra,56(sp)
    80001b36:	f822                	sd	s0,48(sp)
    80001b38:	f426                	sd	s1,40(sp)
    80001b3a:	f04a                	sd	s2,32(sp)
    80001b3c:	ec4e                	sd	s3,24(sp)
    80001b3e:	e852                	sd	s4,16(sp)
    80001b40:	e456                	sd	s5,8(sp)
    80001b42:	e05a                	sd	s6,0(sp)
    80001b44:	0080                	addi	s0,sp,64
  struct proc *p;
  cpu_utilization = ticks;
    80001b46:	00007797          	auipc	a5,0x7
    80001b4a:	50a7a783          	lw	a5,1290(a5) # 80009050 <ticks>
    80001b4e:	00007717          	auipc	a4,0x7
    80001b52:	4cf72f23          	sw	a5,1246(a4) # 8000902c <cpu_utilization>
  start_time = ticks;
    80001b56:	00007717          	auipc	a4,0x7
    80001b5a:	4cf72923          	sw	a5,1234(a4) # 80009028 <start_time>
  
  initlock(&pid_lock, "nextpid");
    80001b5e:	00006597          	auipc	a1,0x6
    80001b62:	74258593          	addi	a1,a1,1858 # 800082a0 <digits+0x260>
    80001b66:	0000f517          	auipc	a0,0xf
    80001b6a:	75a50513          	addi	a0,a0,1882 # 800112c0 <pid_lock>
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	fe6080e7          	jalr	-26(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b76:	00006597          	auipc	a1,0x6
    80001b7a:	73258593          	addi	a1,a1,1842 # 800082a8 <digits+0x268>
    80001b7e:	0000f517          	auipc	a0,0xf
    80001b82:	75a50513          	addi	a0,a0,1882 # 800112d8 <wait_lock>
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	fce080e7          	jalr	-50(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b8e:	00010497          	auipc	s1,0x10
    80001b92:	b6248493          	addi	s1,s1,-1182 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001b96:	00006b17          	auipc	s6,0x6
    80001b9a:	722b0b13          	addi	s6,s6,1826 # 800082b8 <digits+0x278>
      p->kstack = KSTACK((int) (p - proc));
    80001b9e:	8aa6                	mv	s5,s1
    80001ba0:	00006a17          	auipc	s4,0x6
    80001ba4:	460a0a13          	addi	s4,s4,1120 # 80008000 <etext>
    80001ba8:	04000937          	lui	s2,0x4000
    80001bac:	197d                	addi	s2,s2,-1
    80001bae:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bb0:	00016997          	auipc	s3,0x16
    80001bb4:	d4098993          	addi	s3,s3,-704 # 800178f0 <tickslock>
      initlock(&p->lock, "proc");
    80001bb8:	85da                	mv	a1,s6
    80001bba:	8526                	mv	a0,s1
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	f98080e7          	jalr	-104(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001bc4:	415487b3          	sub	a5,s1,s5
    80001bc8:	878d                	srai	a5,a5,0x3
    80001bca:	000a3703          	ld	a4,0(s4)
    80001bce:	02e787b3          	mul	a5,a5,a4
    80001bd2:	2785                	addiw	a5,a5,1
    80001bd4:	00d7979b          	slliw	a5,a5,0xd
    80001bd8:	40f907b3          	sub	a5,s2,a5
    80001bdc:	f0bc                	sd	a5,96(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bde:	18848493          	addi	s1,s1,392
    80001be2:	fd349be3          	bne	s1,s3,80001bb8 <procinit+0x86>
  }
}
    80001be6:	70e2                	ld	ra,56(sp)
    80001be8:	7442                	ld	s0,48(sp)
    80001bea:	74a2                	ld	s1,40(sp)
    80001bec:	7902                	ld	s2,32(sp)
    80001bee:	69e2                	ld	s3,24(sp)
    80001bf0:	6a42                	ld	s4,16(sp)
    80001bf2:	6aa2                	ld	s5,8(sp)
    80001bf4:	6b02                	ld	s6,0(sp)
    80001bf6:	6121                	addi	sp,sp,64
    80001bf8:	8082                	ret

0000000080001bfa <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001bfa:	1141                	addi	sp,sp,-16
    80001bfc:	e422                	sd	s0,8(sp)
    80001bfe:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c00:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001c02:	2501                	sext.w	a0,a0
    80001c04:	6422                	ld	s0,8(sp)
    80001c06:	0141                	addi	sp,sp,16
    80001c08:	8082                	ret

0000000080001c0a <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001c0a:	1141                	addi	sp,sp,-16
    80001c0c:	e422                	sd	s0,8(sp)
    80001c0e:	0800                	addi	s0,sp,16
    80001c10:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c12:	2781                	sext.w	a5,a5
    80001c14:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c16:	0000f517          	auipc	a0,0xf
    80001c1a:	6da50513          	addi	a0,a0,1754 # 800112f0 <cpus>
    80001c1e:	953e                	add	a0,a0,a5
    80001c20:	6422                	ld	s0,8(sp)
    80001c22:	0141                	addi	sp,sp,16
    80001c24:	8082                	ret

0000000080001c26 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c26:	1101                	addi	sp,sp,-32
    80001c28:	ec06                	sd	ra,24(sp)
    80001c2a:	e822                	sd	s0,16(sp)
    80001c2c:	e426                	sd	s1,8(sp)
    80001c2e:	1000                	addi	s0,sp,32
  push_off();
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	f68080e7          	jalr	-152(ra) # 80000b98 <push_off>
    80001c38:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c3a:	2781                	sext.w	a5,a5
    80001c3c:	079e                	slli	a5,a5,0x7
    80001c3e:	0000f717          	auipc	a4,0xf
    80001c42:	68270713          	addi	a4,a4,1666 # 800112c0 <pid_lock>
    80001c46:	97ba                	add	a5,a5,a4
    80001c48:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	fee080e7          	jalr	-18(ra) # 80000c38 <pop_off>
  return p;
}
    80001c52:	8526                	mv	a0,s1
    80001c54:	60e2                	ld	ra,24(sp)
    80001c56:	6442                	ld	s0,16(sp)
    80001c58:	64a2                	ld	s1,8(sp)
    80001c5a:	6105                	addi	sp,sp,32
    80001c5c:	8082                	ret

0000000080001c5e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c5e:	1141                	addi	sp,sp,-16
    80001c60:	e406                	sd	ra,8(sp)
    80001c62:	e022                	sd	s0,0(sp)
    80001c64:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	fc0080e7          	jalr	-64(ra) # 80001c26 <myproc>
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	02a080e7          	jalr	42(ra) # 80000c98 <release>

  if (first) {
    80001c76:	00007797          	auipc	a5,0x7
    80001c7a:	c7a7a783          	lw	a5,-902(a5) # 800088f0 <first.1756>
    80001c7e:	eb89                	bnez	a5,80001c90 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c80:	00001097          	auipc	ra,0x1
    80001c84:	19a080e7          	jalr	410(ra) # 80002e1a <usertrapret>
}
    80001c88:	60a2                	ld	ra,8(sp)
    80001c8a:	6402                	ld	s0,0(sp)
    80001c8c:	0141                	addi	sp,sp,16
    80001c8e:	8082                	ret
    first = 0;
    80001c90:	00007797          	auipc	a5,0x7
    80001c94:	c607a023          	sw	zero,-928(a5) # 800088f0 <first.1756>
    fsinit(ROOTDEV);
    80001c98:	4505                	li	a0,1
    80001c9a:	00002097          	auipc	ra,0x2
    80001c9e:	f24080e7          	jalr	-220(ra) # 80003bbe <fsinit>
    80001ca2:	bff9                	j	80001c80 <forkret+0x22>

0000000080001ca4 <allocpid>:
allocpid() {
    80001ca4:	1101                	addi	sp,sp,-32
    80001ca6:	ec06                	sd	ra,24(sp)
    80001ca8:	e822                	sd	s0,16(sp)
    80001caa:	e426                	sd	s1,8(sp)
    80001cac:	e04a                	sd	s2,0(sp)
    80001cae:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001cb0:	0000f917          	auipc	s2,0xf
    80001cb4:	61090913          	addi	s2,s2,1552 # 800112c0 <pid_lock>
    80001cb8:	854a                	mv	a0,s2
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	f2a080e7          	jalr	-214(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001cc2:	00007797          	auipc	a5,0x7
    80001cc6:	c3678793          	addi	a5,a5,-970 # 800088f8 <nextpid>
    80001cca:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ccc:	0014871b          	addiw	a4,s1,1
    80001cd0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001cd2:	854a                	mv	a0,s2
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	fc4080e7          	jalr	-60(ra) # 80000c98 <release>
}
    80001cdc:	8526                	mv	a0,s1
    80001cde:	60e2                	ld	ra,24(sp)
    80001ce0:	6442                	ld	s0,16(sp)
    80001ce2:	64a2                	ld	s1,8(sp)
    80001ce4:	6902                	ld	s2,0(sp)
    80001ce6:	6105                	addi	sp,sp,32
    80001ce8:	8082                	ret

0000000080001cea <proc_pagetable>:
{
    80001cea:	1101                	addi	sp,sp,-32
    80001cec:	ec06                	sd	ra,24(sp)
    80001cee:	e822                	sd	s0,16(sp)
    80001cf0:	e426                	sd	s1,8(sp)
    80001cf2:	e04a                	sd	s2,0(sp)
    80001cf4:	1000                	addi	s0,sp,32
    80001cf6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	766080e7          	jalr	1894(ra) # 8000145e <uvmcreate>
    80001d00:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d02:	c121                	beqz	a0,80001d42 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d04:	4729                	li	a4,10
    80001d06:	00005697          	auipc	a3,0x5
    80001d0a:	2fa68693          	addi	a3,a3,762 # 80007000 <_trampoline>
    80001d0e:	6605                	lui	a2,0x1
    80001d10:	040005b7          	lui	a1,0x4000
    80001d14:	15fd                	addi	a1,a1,-1
    80001d16:	05b2                	slli	a1,a1,0xc
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	4bc080e7          	jalr	1212(ra) # 800011d4 <mappages>
    80001d20:	02054863          	bltz	a0,80001d50 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d24:	4719                	li	a4,6
    80001d26:	07893683          	ld	a3,120(s2)
    80001d2a:	6605                	lui	a2,0x1
    80001d2c:	020005b7          	lui	a1,0x2000
    80001d30:	15fd                	addi	a1,a1,-1
    80001d32:	05b6                	slli	a1,a1,0xd
    80001d34:	8526                	mv	a0,s1
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	49e080e7          	jalr	1182(ra) # 800011d4 <mappages>
    80001d3e:	02054163          	bltz	a0,80001d60 <proc_pagetable+0x76>
}
    80001d42:	8526                	mv	a0,s1
    80001d44:	60e2                	ld	ra,24(sp)
    80001d46:	6442                	ld	s0,16(sp)
    80001d48:	64a2                	ld	s1,8(sp)
    80001d4a:	6902                	ld	s2,0(sp)
    80001d4c:	6105                	addi	sp,sp,32
    80001d4e:	8082                	ret
    uvmfree(pagetable, 0);
    80001d50:	4581                	li	a1,0
    80001d52:	8526                	mv	a0,s1
    80001d54:	00000097          	auipc	ra,0x0
    80001d58:	906080e7          	jalr	-1786(ra) # 8000165a <uvmfree>
    return 0;
    80001d5c:	4481                	li	s1,0
    80001d5e:	b7d5                	j	80001d42 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d60:	4681                	li	a3,0
    80001d62:	4605                	li	a2,1
    80001d64:	040005b7          	lui	a1,0x4000
    80001d68:	15fd                	addi	a1,a1,-1
    80001d6a:	05b2                	slli	a1,a1,0xc
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	62c080e7          	jalr	1580(ra) # 8000139a <uvmunmap>
    uvmfree(pagetable, 0);
    80001d76:	4581                	li	a1,0
    80001d78:	8526                	mv	a0,s1
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	8e0080e7          	jalr	-1824(ra) # 8000165a <uvmfree>
    return 0;
    80001d82:	4481                	li	s1,0
    80001d84:	bf7d                	j	80001d42 <proc_pagetable+0x58>

0000000080001d86 <proc_freepagetable>:
{
    80001d86:	1101                	addi	sp,sp,-32
    80001d88:	ec06                	sd	ra,24(sp)
    80001d8a:	e822                	sd	s0,16(sp)
    80001d8c:	e426                	sd	s1,8(sp)
    80001d8e:	e04a                	sd	s2,0(sp)
    80001d90:	1000                	addi	s0,sp,32
    80001d92:	84aa                	mv	s1,a0
    80001d94:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d96:	4681                	li	a3,0
    80001d98:	4605                	li	a2,1
    80001d9a:	040005b7          	lui	a1,0x4000
    80001d9e:	15fd                	addi	a1,a1,-1
    80001da0:	05b2                	slli	a1,a1,0xc
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	5f8080e7          	jalr	1528(ra) # 8000139a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001daa:	4681                	li	a3,0
    80001dac:	4605                	li	a2,1
    80001dae:	020005b7          	lui	a1,0x2000
    80001db2:	15fd                	addi	a1,a1,-1
    80001db4:	05b6                	slli	a1,a1,0xd
    80001db6:	8526                	mv	a0,s1
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	5e2080e7          	jalr	1506(ra) # 8000139a <uvmunmap>
  uvmfree(pagetable, sz);
    80001dc0:	85ca                	mv	a1,s2
    80001dc2:	8526                	mv	a0,s1
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	896080e7          	jalr	-1898(ra) # 8000165a <uvmfree>
}
    80001dcc:	60e2                	ld	ra,24(sp)
    80001dce:	6442                	ld	s0,16(sp)
    80001dd0:	64a2                	ld	s1,8(sp)
    80001dd2:	6902                	ld	s2,0(sp)
    80001dd4:	6105                	addi	sp,sp,32
    80001dd6:	8082                	ret

0000000080001dd8 <freeproc>:
{
    80001dd8:	1101                	addi	sp,sp,-32
    80001dda:	ec06                	sd	ra,24(sp)
    80001ddc:	e822                	sd	s0,16(sp)
    80001dde:	e426                	sd	s1,8(sp)
    80001de0:	1000                	addi	s0,sp,32
    80001de2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001de4:	7d28                	ld	a0,120(a0)
    80001de6:	c509                	beqz	a0,80001df0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	c10080e7          	jalr	-1008(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001df0:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001df4:	78a8                	ld	a0,112(s1)
    80001df6:	c511                	beqz	a0,80001e02 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001df8:	74ac                	ld	a1,104(s1)
    80001dfa:	00000097          	auipc	ra,0x0
    80001dfe:	f8c080e7          	jalr	-116(ra) # 80001d86 <proc_freepagetable>
  p->pagetable = 0;
    80001e02:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001e06:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001e0a:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e0e:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001e12:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001e16:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e1a:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e1e:	0204a623          	sw	zero,44(s1)
  stateChange(p);
    80001e22:	8526                	mv	a0,s1
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	b3e080e7          	jalr	-1218(ra) # 80001962 <stateChange>
  p->state = UNUSED;
    80001e2c:	0004ac23          	sw	zero,24(s1)
}
    80001e30:	60e2                	ld	ra,24(sp)
    80001e32:	6442                	ld	s0,16(sp)
    80001e34:	64a2                	ld	s1,8(sp)
    80001e36:	6105                	addi	sp,sp,32
    80001e38:	8082                	ret

0000000080001e3a <allocproc>:
{
    80001e3a:	1101                	addi	sp,sp,-32
    80001e3c:	ec06                	sd	ra,24(sp)
    80001e3e:	e822                	sd	s0,16(sp)
    80001e40:	e426                	sd	s1,8(sp)
    80001e42:	e04a                	sd	s2,0(sp)
    80001e44:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e46:	00010497          	auipc	s1,0x10
    80001e4a:	8aa48493          	addi	s1,s1,-1878 # 800116f0 <proc>
    80001e4e:	00016917          	auipc	s2,0x16
    80001e52:	aa290913          	addi	s2,s2,-1374 # 800178f0 <tickslock>
    acquire(&p->lock);
    80001e56:	8526                	mv	a0,s1
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	d8c080e7          	jalr	-628(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001e60:	4c9c                	lw	a5,24(s1)
    80001e62:	cf81                	beqz	a5,80001e7a <allocproc+0x40>
      release(&p->lock);
    80001e64:	8526                	mv	a0,s1
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	e32080e7          	jalr	-462(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e6e:	18848493          	addi	s1,s1,392
    80001e72:	ff2492e3          	bne	s1,s2,80001e56 <allocproc+0x1c>
  return 0;
    80001e76:	4481                	li	s1,0
    80001e78:	a0a5                	j	80001ee0 <allocproc+0xa6>
  p->pid = allocpid();
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	e2a080e7          	jalr	-470(ra) # 80001ca4 <allocpid>
    80001e82:	d888                	sw	a0,48(s1)
  stateChange(p);
    80001e84:	8526                	mv	a0,s1
    80001e86:	00000097          	auipc	ra,0x0
    80001e8a:	adc080e7          	jalr	-1316(ra) # 80001962 <stateChange>
  p->state = USED;
    80001e8e:	4785                	li	a5,1
    80001e90:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = 0;
    80001e92:	0404a423          	sw	zero,72(s1)
  p->mean_ticks = 0;
    80001e96:	0404a023          	sw	zero,64(s1)
  p->last_ticks = 0;
    80001e9a:	0404a223          	sw	zero,68(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	c56080e7          	jalr	-938(ra) # 80000af4 <kalloc>
    80001ea6:	892a                	mv	s2,a0
    80001ea8:	fca8                	sd	a0,120(s1)
    80001eaa:	c131                	beqz	a0,80001eee <allocproc+0xb4>
  p->pagetable = proc_pagetable(p);
    80001eac:	8526                	mv	a0,s1
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	e3c080e7          	jalr	-452(ra) # 80001cea <proc_pagetable>
    80001eb6:	892a                	mv	s2,a0
    80001eb8:	f8a8                	sd	a0,112(s1)
  if(p->pagetable == 0){
    80001eba:	c531                	beqz	a0,80001f06 <allocproc+0xcc>
  memset(&p->context, 0, sizeof(p->context));
    80001ebc:	07000613          	li	a2,112
    80001ec0:	4581                	li	a1,0
    80001ec2:	08048513          	addi	a0,s1,128
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	e1a080e7          	jalr	-486(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001ece:	00000797          	auipc	a5,0x0
    80001ed2:	d9078793          	addi	a5,a5,-624 # 80001c5e <forkret>
    80001ed6:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ed8:	70bc                	ld	a5,96(s1)
    80001eda:	6705                	lui	a4,0x1
    80001edc:	97ba                	add	a5,a5,a4
    80001ede:	e4dc                	sd	a5,136(s1)
}
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	60e2                	ld	ra,24(sp)
    80001ee4:	6442                	ld	s0,16(sp)
    80001ee6:	64a2                	ld	s1,8(sp)
    80001ee8:	6902                	ld	s2,0(sp)
    80001eea:	6105                	addi	sp,sp,32
    80001eec:	8082                	ret
    freeproc(p);
    80001eee:	8526                	mv	a0,s1
    80001ef0:	00000097          	auipc	ra,0x0
    80001ef4:	ee8080e7          	jalr	-280(ra) # 80001dd8 <freeproc>
    release(&p->lock);
    80001ef8:	8526                	mv	a0,s1
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	d9e080e7          	jalr	-610(ra) # 80000c98 <release>
    return 0;
    80001f02:	84ca                	mv	s1,s2
    80001f04:	bff1                	j	80001ee0 <allocproc+0xa6>
    freeproc(p);
    80001f06:	8526                	mv	a0,s1
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	ed0080e7          	jalr	-304(ra) # 80001dd8 <freeproc>
    release(&p->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	d86080e7          	jalr	-634(ra) # 80000c98 <release>
    return 0;
    80001f1a:	84ca                	mv	s1,s2
    80001f1c:	b7d1                	j	80001ee0 <allocproc+0xa6>

0000000080001f1e <userinit>:
{
    80001f1e:	1101                	addi	sp,sp,-32
    80001f20:	ec06                	sd	ra,24(sp)
    80001f22:	e822                	sd	s0,16(sp)
    80001f24:	e426                	sd	s1,8(sp)
    80001f26:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f28:	00000097          	auipc	ra,0x0
    80001f2c:	f12080e7          	jalr	-238(ra) # 80001e3a <allocproc>
    80001f30:	84aa                	mv	s1,a0
  initproc = p;
    80001f32:	00007797          	auipc	a5,0x7
    80001f36:	10a7bb23          	sd	a0,278(a5) # 80009048 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f3a:	03400613          	li	a2,52
    80001f3e:	00007597          	auipc	a1,0x7
    80001f42:	9c258593          	addi	a1,a1,-1598 # 80008900 <initcode>
    80001f46:	7928                	ld	a0,112(a0)
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	544080e7          	jalr	1348(ra) # 8000148c <uvminit>
  p->sz = PGSIZE;
    80001f50:	6785                	lui	a5,0x1
    80001f52:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f54:	7cb8                	ld	a4,120(s1)
    80001f56:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f5a:	7cb8                	ld	a4,120(s1)
    80001f5c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f5e:	4641                	li	a2,16
    80001f60:	00006597          	auipc	a1,0x6
    80001f64:	36058593          	addi	a1,a1,864 # 800082c0 <digits+0x280>
    80001f68:	17848513          	addi	a0,s1,376
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	ec6080e7          	jalr	-314(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001f74:	00006517          	auipc	a0,0x6
    80001f78:	35c50513          	addi	a0,a0,860 # 800082d0 <digits+0x290>
    80001f7c:	00002097          	auipc	ra,0x2
    80001f80:	670080e7          	jalr	1648(ra) # 800045ec <namei>
    80001f84:	16a4b823          	sd	a0,368(s1)
  changeStateToRunnable(p);
    80001f88:	8526                	mv	a0,s1
    80001f8a:	00000097          	auipc	ra,0x0
    80001f8e:	a3e080e7          	jalr	-1474(ra) # 800019c8 <changeStateToRunnable>
  release(&p->lock);
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	d04080e7          	jalr	-764(ra) # 80000c98 <release>
}
    80001f9c:	60e2                	ld	ra,24(sp)
    80001f9e:	6442                	ld	s0,16(sp)
    80001fa0:	64a2                	ld	s1,8(sp)
    80001fa2:	6105                	addi	sp,sp,32
    80001fa4:	8082                	ret

0000000080001fa6 <growproc>:
{
    80001fa6:	1101                	addi	sp,sp,-32
    80001fa8:	ec06                	sd	ra,24(sp)
    80001faa:	e822                	sd	s0,16(sp)
    80001fac:	e426                	sd	s1,8(sp)
    80001fae:	e04a                	sd	s2,0(sp)
    80001fb0:	1000                	addi	s0,sp,32
    80001fb2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001fb4:	00000097          	auipc	ra,0x0
    80001fb8:	c72080e7          	jalr	-910(ra) # 80001c26 <myproc>
    80001fbc:	892a                	mv	s2,a0
  sz = p->sz;
    80001fbe:	752c                	ld	a1,104(a0)
    80001fc0:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001fc4:	00904f63          	bgtz	s1,80001fe2 <growproc+0x3c>
  } else if(n < 0){
    80001fc8:	0204cc63          	bltz	s1,80002000 <growproc+0x5a>
  p->sz = sz;
    80001fcc:	1602                	slli	a2,a2,0x20
    80001fce:	9201                	srli	a2,a2,0x20
    80001fd0:	06c93423          	sd	a2,104(s2)
  return 0;
    80001fd4:	4501                	li	a0,0
}
    80001fd6:	60e2                	ld	ra,24(sp)
    80001fd8:	6442                	ld	s0,16(sp)
    80001fda:	64a2                	ld	s1,8(sp)
    80001fdc:	6902                	ld	s2,0(sp)
    80001fde:	6105                	addi	sp,sp,32
    80001fe0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fe2:	9e25                	addw	a2,a2,s1
    80001fe4:	1602                	slli	a2,a2,0x20
    80001fe6:	9201                	srli	a2,a2,0x20
    80001fe8:	1582                	slli	a1,a1,0x20
    80001fea:	9181                	srli	a1,a1,0x20
    80001fec:	7928                	ld	a0,112(a0)
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	558080e7          	jalr	1368(ra) # 80001546 <uvmalloc>
    80001ff6:	0005061b          	sext.w	a2,a0
    80001ffa:	fa69                	bnez	a2,80001fcc <growproc+0x26>
      return -1;
    80001ffc:	557d                	li	a0,-1
    80001ffe:	bfe1                	j	80001fd6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002000:	9e25                	addw	a2,a2,s1
    80002002:	1602                	slli	a2,a2,0x20
    80002004:	9201                	srli	a2,a2,0x20
    80002006:	1582                	slli	a1,a1,0x20
    80002008:	9181                	srli	a1,a1,0x20
    8000200a:	7928                	ld	a0,112(a0)
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	4f2080e7          	jalr	1266(ra) # 800014fe <uvmdealloc>
    80002014:	0005061b          	sext.w	a2,a0
    80002018:	bf55                	j	80001fcc <growproc+0x26>

000000008000201a <fork>:
{
    8000201a:	7179                	addi	sp,sp,-48
    8000201c:	f406                	sd	ra,40(sp)
    8000201e:	f022                	sd	s0,32(sp)
    80002020:	ec26                	sd	s1,24(sp)
    80002022:	e84a                	sd	s2,16(sp)
    80002024:	e44e                	sd	s3,8(sp)
    80002026:	e052                	sd	s4,0(sp)
    80002028:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000202a:	00000097          	auipc	ra,0x0
    8000202e:	bfc080e7          	jalr	-1028(ra) # 80001c26 <myproc>
    80002032:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002034:	00000097          	auipc	ra,0x0
    80002038:	e06080e7          	jalr	-506(ra) # 80001e3a <allocproc>
    8000203c:	10050d63          	beqz	a0,80002156 <fork+0x13c>
    80002040:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002042:	06893603          	ld	a2,104(s2)
    80002046:	792c                	ld	a1,112(a0)
    80002048:	07093503          	ld	a0,112(s2)
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	646080e7          	jalr	1606(ra) # 80001692 <uvmcopy>
    80002054:	04054663          	bltz	a0,800020a0 <fork+0x86>
  np->sz = p->sz;
    80002058:	06893783          	ld	a5,104(s2)
    8000205c:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    80002060:	07893683          	ld	a3,120(s2)
    80002064:	87b6                	mv	a5,a3
    80002066:	0789b703          	ld	a4,120(s3)
    8000206a:	12068693          	addi	a3,a3,288
    8000206e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002072:	6788                	ld	a0,8(a5)
    80002074:	6b8c                	ld	a1,16(a5)
    80002076:	6f90                	ld	a2,24(a5)
    80002078:	01073023          	sd	a6,0(a4)
    8000207c:	e708                	sd	a0,8(a4)
    8000207e:	eb0c                	sd	a1,16(a4)
    80002080:	ef10                	sd	a2,24(a4)
    80002082:	02078793          	addi	a5,a5,32
    80002086:	02070713          	addi	a4,a4,32
    8000208a:	fed792e3          	bne	a5,a3,8000206e <fork+0x54>
  np->trapframe->a0 = 0;
    8000208e:	0789b783          	ld	a5,120(s3)
    80002092:	0607b823          	sd	zero,112(a5)
    80002096:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    8000209a:	17000a13          	li	s4,368
    8000209e:	a03d                	j	800020cc <fork+0xb2>
    freeproc(np);
    800020a0:	854e                	mv	a0,s3
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	d36080e7          	jalr	-714(ra) # 80001dd8 <freeproc>
    release(&np->lock);
    800020aa:	854e                	mv	a0,s3
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	bec080e7          	jalr	-1044(ra) # 80000c98 <release>
    return -1;
    800020b4:	5a7d                	li	s4,-1
    800020b6:	a079                	j	80002144 <fork+0x12a>
      np->ofile[i] = filedup(p->ofile[i]);
    800020b8:	00003097          	auipc	ra,0x3
    800020bc:	bca080e7          	jalr	-1078(ra) # 80004c82 <filedup>
    800020c0:	009987b3          	add	a5,s3,s1
    800020c4:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800020c6:	04a1                	addi	s1,s1,8
    800020c8:	01448763          	beq	s1,s4,800020d6 <fork+0xbc>
    if(p->ofile[i])
    800020cc:	009907b3          	add	a5,s2,s1
    800020d0:	6388                	ld	a0,0(a5)
    800020d2:	f17d                	bnez	a0,800020b8 <fork+0x9e>
    800020d4:	bfcd                	j	800020c6 <fork+0xac>
  np->cwd = idup(p->cwd);
    800020d6:	17093503          	ld	a0,368(s2)
    800020da:	00002097          	auipc	ra,0x2
    800020de:	d1e080e7          	jalr	-738(ra) # 80003df8 <idup>
    800020e2:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020e6:	4641                	li	a2,16
    800020e8:	17890593          	addi	a1,s2,376
    800020ec:	17898513          	addi	a0,s3,376
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	d42080e7          	jalr	-702(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800020f8:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800020fc:	854e                	mv	a0,s3
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	b9a080e7          	jalr	-1126(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80002106:	0000f497          	auipc	s1,0xf
    8000210a:	1d248493          	addi	s1,s1,466 # 800112d8 <wait_lock>
    8000210e:	8526                	mv	a0,s1
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	ad4080e7          	jalr	-1324(ra) # 80000be4 <acquire>
  np->parent = p;
    80002118:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    8000211c:	8526                	mv	a0,s1
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	b7a080e7          	jalr	-1158(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002126:	854e                	mv	a0,s3
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	abc080e7          	jalr	-1348(ra) # 80000be4 <acquire>
  changeStateToRunnable(np);
    80002130:	854e                	mv	a0,s3
    80002132:	00000097          	auipc	ra,0x0
    80002136:	896080e7          	jalr	-1898(ra) # 800019c8 <changeStateToRunnable>
  release(&np->lock);
    8000213a:	854e                	mv	a0,s3
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	b5c080e7          	jalr	-1188(ra) # 80000c98 <release>
}
    80002144:	8552                	mv	a0,s4
    80002146:	70a2                	ld	ra,40(sp)
    80002148:	7402                	ld	s0,32(sp)
    8000214a:	64e2                	ld	s1,24(sp)
    8000214c:	6942                	ld	s2,16(sp)
    8000214e:	69a2                	ld	s3,8(sp)
    80002150:	6a02                	ld	s4,0(sp)
    80002152:	6145                	addi	sp,sp,48
    80002154:	8082                	ret
    return -1;
    80002156:	5a7d                	li	s4,-1
    80002158:	b7f5                	j	80002144 <fork+0x12a>

000000008000215a <minMeanTicks>:
{
    8000215a:	7179                	addi	sp,sp,-48
    8000215c:	f406                	sd	ra,40(sp)
    8000215e:	f022                	sd	s0,32(sp)
    80002160:	ec26                	sd	s1,24(sp)
    80002162:	e84a                	sd	s2,16(sp)
    80002164:	e44e                	sd	s3,8(sp)
    80002166:	e052                	sd	s4,0(sp)
    80002168:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    8000216a:	0000f497          	auipc	s1,0xf
    8000216e:	58648493          	addi	s1,s1,1414 # 800116f0 <proc>
    if(p->state == RUNNABLE)
    80002172:	490d                	li	s2,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002174:	00015997          	auipc	s3,0x15
    80002178:	77c98993          	addi	s3,s3,1916 # 800178f0 <tickslock>
    acquire(&p->lock);
    8000217c:	8526                	mv	a0,s1
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	a66080e7          	jalr	-1434(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE)
    80002186:	4c9c                	lw	a5,24(s1)
    80002188:	03278f63          	beq	a5,s2,800021c6 <minMeanTicks+0x6c>
    release(&p->lock);
    8000218c:	8526                	mv	a0,s1
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	b0a080e7          	jalr	-1270(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002196:	18848493          	addi	s1,s1,392
    8000219a:	ff3491e3          	bne	s1,s3,8000217c <minMeanTicks+0x22>
  acquire(&min->lock);
    8000219e:	0000f517          	auipc	a0,0xf
    800021a2:	55250513          	addi	a0,a0,1362 # 800116f0 <proc>
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	a3e080e7          	jalr	-1474(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    800021ae:	0000f717          	auipc	a4,0xf
    800021b2:	55a72703          	lw	a4,1370(a4) # 80011708 <proc+0x18>
    800021b6:	478d                	li	a5,3
    800021b8:	04f70c63          	beq	a4,a5,80002210 <minMeanTicks+0xb6>
  min = proc;
    800021bc:	0000f497          	auipc	s1,0xf
    800021c0:	53448493          	addi	s1,s1,1332 # 800116f0 <proc>
    800021c4:	a839                	j	800021e2 <minMeanTicks+0x88>
      release(&p->lock);
    800021c6:	8526                	mv	a0,s1
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	ad0080e7          	jalr	-1328(ra) # 80000c98 <release>
  acquire(&min->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	a12080e7          	jalr	-1518(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    800021da:	4c98                	lw	a4,24(s1)
    800021dc:	478d                	li	a5,3
    800021de:	00f70b63          	beq	a4,a5,800021f4 <minMeanTicks+0x9a>
}
    800021e2:	8526                	mv	a0,s1
    800021e4:	70a2                	ld	ra,40(sp)
    800021e6:	7402                	ld	s0,32(sp)
    800021e8:	64e2                	ld	s1,24(sp)
    800021ea:	6942                	ld	s2,16(sp)
    800021ec:	69a2                	ld	s3,8(sp)
    800021ee:	6a02                	ld	s4,0(sp)
    800021f0:	6145                	addi	sp,sp,48
    800021f2:	8082                	ret
    for (p = min+1; p < &proc[NPROC]; p++)
    800021f4:	18848913          	addi	s2,s1,392
    800021f8:	00015797          	auipc	a5,0x15
    800021fc:	6f878793          	addi	a5,a5,1784 # 800178f0 <tickslock>
    80002200:	fef971e3          	bgeu	s2,a5,800021e2 <minMeanTicks+0x88>
      if(p->state == RUNNABLE && min->mean_ticks > p->mean_ticks)
    80002204:	4a0d                	li	s4,3
    for (p = min+1; p < &proc[NPROC]; p++)
    80002206:	00015997          	auipc	s3,0x15
    8000220a:	6ea98993          	addi	s3,s3,1770 # 800178f0 <tickslock>
    8000220e:	a01d                	j	80002234 <minMeanTicks+0xda>
  min = proc;
    80002210:	0000f497          	auipc	s1,0xf
    80002214:	4e048493          	addi	s1,s1,1248 # 800116f0 <proc>
    for (p = min+1; p < &proc[NPROC]; p++)
    80002218:	0000f917          	auipc	s2,0xf
    8000221c:	66090913          	addi	s2,s2,1632 # 80011878 <proc+0x188>
    80002220:	b7d5                	j	80002204 <minMeanTicks+0xaa>
        release(&p->lock);
    80002222:	854a                	mv	a0,s2
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	a74080e7          	jalr	-1420(ra) # 80000c98 <release>
    for (p = min+1; p < &proc[NPROC]; p++)
    8000222c:	18890913          	addi	s2,s2,392
    80002230:	fb3979e3          	bgeu	s2,s3,800021e2 <minMeanTicks+0x88>
      acquire(&p->lock);
    80002234:	854a                	mv	a0,s2
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	9ae080e7          	jalr	-1618(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && min->mean_ticks > p->mean_ticks)
    8000223e:	01892783          	lw	a5,24(s2)
    80002242:	ff4790e3          	bne	a5,s4,80002222 <minMeanTicks+0xc8>
    80002246:	40b8                	lw	a4,64(s1)
    80002248:	04092783          	lw	a5,64(s2)
    8000224c:	fce7dbe3          	bge	a5,a4,80002222 <minMeanTicks+0xc8>
        release(&min->lock);
    80002250:	8526                	mv	a0,s1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	a46080e7          	jalr	-1466(ra) # 80000c98 <release>
        min = p;
    8000225a:	84ca                	mv	s1,s2
    8000225c:	bfc1                	j	8000222c <minMeanTicks+0xd2>

000000008000225e <SJFScheduler>:
{
    8000225e:	711d                	addi	sp,sp,-96
    80002260:	ec86                	sd	ra,88(sp)
    80002262:	e8a2                	sd	s0,80(sp)
    80002264:	e4a6                	sd	s1,72(sp)
    80002266:	e0ca                	sd	s2,64(sp)
    80002268:	fc4e                	sd	s3,56(sp)
    8000226a:	f852                	sd	s4,48(sp)
    8000226c:	f456                	sd	s5,40(sp)
    8000226e:	f05a                	sd	s6,32(sp)
    80002270:	ec5e                	sd	s7,24(sp)
    80002272:	e862                	sd	s8,16(sp)
    80002274:	e466                	sd	s9,8(sp)
    80002276:	1080                	addi	s0,sp,96
    80002278:	8792                	mv	a5,tp
  int id = r_tp();
    8000227a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000227c:	00779b13          	slli	s6,a5,0x7
    80002280:	0000f717          	auipc	a4,0xf
    80002284:	04070713          	addi	a4,a4,64 # 800112c0 <pid_lock>
    80002288:	975a                	add	a4,a4,s6
    8000228a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000228e:	0000f717          	auipc	a4,0xf
    80002292:	06a70713          	addi	a4,a4,106 # 800112f8 <cpus+0x8>
    80002296:	9b3a                	add	s6,s6,a4
    if (ticks >= nextGoodTicks)
    80002298:	00007917          	auipc	s2,0x7
    8000229c:	db890913          	addi	s2,s2,-584 # 80009050 <ticks>
    800022a0:	00007997          	auipc	s3,0x7
    800022a4:	da498993          	addi	s3,s3,-604 # 80009044 <nextGoodTicks>
      if (p->state == RUNNABLE)
    800022a8:	4a0d                	li	s4,3
        p->state = RUNNING;
    800022aa:	4c11                	li	s8,4
        c->proc = p;
    800022ac:	079e                	slli	a5,a5,0x7
    800022ae:	0000fa97          	auipc	s5,0xf
    800022b2:	012a8a93          	addi	s5,s5,18 # 800112c0 <pid_lock>
    800022b6:	9abe                	add	s5,s5,a5
        p->mean_ticks =  ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    800022b8:	00006b97          	auipc	s7,0x6
    800022bc:	63cb8b93          	addi	s7,s7,1596 # 800088f4 <rate>
    800022c0:	a031                	j	800022cc <SJFScheduler+0x6e>
    release(&p->lock);
    800022c2:	8526                	mv	a0,s1
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	9d4080e7          	jalr	-1580(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022cc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022d0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022d4:	10079073          	csrw	sstatus,a5
    p = minMeanTicks();
    800022d8:	00000097          	auipc	ra,0x0
    800022dc:	e82080e7          	jalr	-382(ra) # 8000215a <minMeanTicks>
    800022e0:	84aa                	mv	s1,a0
    if (ticks >= nextGoodTicks)
    800022e2:	00092703          	lw	a4,0(s2)
    800022e6:	0009a783          	lw	a5,0(s3)
    800022ea:	fcf76ce3          	bltu	a4,a5,800022c2 <SJFScheduler+0x64>
      if (p->state == RUNNABLE)
    800022ee:	4d1c                	lw	a5,24(a0)
    800022f0:	fd4799e3          	bne	a5,s4,800022c2 <SJFScheduler+0x64>
        stateChange(p);
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	66e080e7          	jalr	1646(ra) # 80001962 <stateChange>
        p->state = RUNNING;
    800022fc:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002300:	029ab823          	sd	s1,48(s5)
        prevTicks = ticks;
    80002304:	00092c83          	lw	s9,0(s2)
        swtch(&c->context, &p->context);
    80002308:	08048593          	addi	a1,s1,128
    8000230c:	855a                	mv	a0,s6
    8000230e:	00001097          	auipc	ra,0x1
    80002312:	a62080e7          	jalr	-1438(ra) # 80002d70 <swtch>
        c->proc = 0;
    80002316:	020ab823          	sd	zero,48(s5)
        p->last_ticks = ticks - prevTicks;
    8000231a:	00092703          	lw	a4,0(s2)
    8000231e:	4197073b          	subw	a4,a4,s9
    80002322:	c0f8                	sw	a4,68(s1)
        p->mean_ticks =  ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    80002324:	000ba603          	lw	a2,0(s7)
    80002328:	46a9                	li	a3,10
    8000232a:	40c687bb          	subw	a5,a3,a2
    8000232e:	40ac                	lw	a1,64(s1)
    80002330:	02b787bb          	mulw	a5,a5,a1
    80002334:	02c7073b          	mulw	a4,a4,a2
    80002338:	9fb9                	addw	a5,a5,a4
    8000233a:	02d7c7bb          	divw	a5,a5,a3
    8000233e:	c0bc                	sw	a5,64(s1)
    80002340:	b749                	j	800022c2 <SJFScheduler+0x64>

0000000080002342 <minLastRunnableTime>:
{
    80002342:	7179                	addi	sp,sp,-48
    80002344:	f406                	sd	ra,40(sp)
    80002346:	f022                	sd	s0,32(sp)
    80002348:	ec26                	sd	s1,24(sp)
    8000234a:	e84a                	sd	s2,16(sp)
    8000234c:	e44e                	sd	s3,8(sp)
    8000234e:	e052                	sd	s4,0(sp)
    80002350:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80002352:	0000f497          	auipc	s1,0xf
    80002356:	39e48493          	addi	s1,s1,926 # 800116f0 <proc>
    if(p->state == RUNNABLE)
    8000235a:	490d                	li	s2,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000235c:	00015997          	auipc	s3,0x15
    80002360:	59498993          	addi	s3,s3,1428 # 800178f0 <tickslock>
    acquire(&p->lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	87e080e7          	jalr	-1922(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE)
    8000236e:	4c9c                	lw	a5,24(s1)
    80002370:	03278f63          	beq	a5,s2,800023ae <minLastRunnableTime+0x6c>
    release(&p->lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	922080e7          	jalr	-1758(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000237e:	18848493          	addi	s1,s1,392
    80002382:	ff3491e3          	bne	s1,s3,80002364 <minLastRunnableTime+0x22>
  acquire(&min->lock);
    80002386:	0000f517          	auipc	a0,0xf
    8000238a:	36a50513          	addi	a0,a0,874 # 800116f0 <proc>
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	856080e7          	jalr	-1962(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    80002396:	0000f717          	auipc	a4,0xf
    8000239a:	37272703          	lw	a4,882(a4) # 80011708 <proc+0x18>
    8000239e:	478d                	li	a5,3
    800023a0:	04f70c63          	beq	a4,a5,800023f8 <minLastRunnableTime+0xb6>
  min = proc;
    800023a4:	0000f497          	auipc	s1,0xf
    800023a8:	34c48493          	addi	s1,s1,844 # 800116f0 <proc>
    800023ac:	a839                	j	800023ca <minLastRunnableTime+0x88>
      release(&p->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8e8080e7          	jalr	-1816(ra) # 80000c98 <release>
  acquire(&min->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	82a080e7          	jalr	-2006(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    800023c2:	4c98                	lw	a4,24(s1)
    800023c4:	478d                	li	a5,3
    800023c6:	00f70b63          	beq	a4,a5,800023dc <minLastRunnableTime+0x9a>
}
    800023ca:	8526                	mv	a0,s1
    800023cc:	70a2                	ld	ra,40(sp)
    800023ce:	7402                	ld	s0,32(sp)
    800023d0:	64e2                	ld	s1,24(sp)
    800023d2:	6942                	ld	s2,16(sp)
    800023d4:	69a2                	ld	s3,8(sp)
    800023d6:	6a02                	ld	s4,0(sp)
    800023d8:	6145                	addi	sp,sp,48
    800023da:	8082                	ret
    for (p = min+1; p < &proc[NPROC]; p++)
    800023dc:	18848913          	addi	s2,s1,392
    800023e0:	00015797          	auipc	a5,0x15
    800023e4:	51078793          	addi	a5,a5,1296 # 800178f0 <tickslock>
    800023e8:	fef971e3          	bgeu	s2,a5,800023ca <minLastRunnableTime+0x88>
      if(p->state == RUNNABLE && min->last_runnable_time > p->last_runnable_time)
    800023ec:	4a0d                	li	s4,3
    for (p = min+1; p < &proc[NPROC]; p++)
    800023ee:	00015997          	auipc	s3,0x15
    800023f2:	50298993          	addi	s3,s3,1282 # 800178f0 <tickslock>
    800023f6:	a01d                	j	8000241c <minLastRunnableTime+0xda>
  min = proc;
    800023f8:	0000f497          	auipc	s1,0xf
    800023fc:	2f848493          	addi	s1,s1,760 # 800116f0 <proc>
    for (p = min+1; p < &proc[NPROC]; p++)
    80002400:	0000f917          	auipc	s2,0xf
    80002404:	47890913          	addi	s2,s2,1144 # 80011878 <proc+0x188>
    80002408:	b7d5                	j	800023ec <minLastRunnableTime+0xaa>
        release(&p->lock);
    8000240a:	854a                	mv	a0,s2
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	88c080e7          	jalr	-1908(ra) # 80000c98 <release>
    for (p = min+1; p < &proc[NPROC]; p++)
    80002414:	18890913          	addi	s2,s2,392
    80002418:	fb3979e3          	bgeu	s2,s3,800023ca <minLastRunnableTime+0x88>
      acquire(&p->lock);
    8000241c:	854a                	mv	a0,s2
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	7c6080e7          	jalr	1990(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && min->last_runnable_time > p->last_runnable_time)
    80002426:	01892783          	lw	a5,24(s2)
    8000242a:	ff4790e3          	bne	a5,s4,8000240a <minLastRunnableTime+0xc8>
    8000242e:	44b8                	lw	a4,72(s1)
    80002430:	04892783          	lw	a5,72(s2)
    80002434:	fce7dbe3          	bge	a5,a4,8000240a <minLastRunnableTime+0xc8>
        release(&min->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	85e080e7          	jalr	-1954(ra) # 80000c98 <release>
        min = p;
    80002442:	84ca                	mv	s1,s2
    80002444:	bfc1                	j	80002414 <minLastRunnableTime+0xd2>

0000000080002446 <FCFSScheduler>:
{
    80002446:	715d                	addi	sp,sp,-80
    80002448:	e486                	sd	ra,72(sp)
    8000244a:	e0a2                	sd	s0,64(sp)
    8000244c:	fc26                	sd	s1,56(sp)
    8000244e:	f84a                	sd	s2,48(sp)
    80002450:	f44e                	sd	s3,40(sp)
    80002452:	f052                	sd	s4,32(sp)
    80002454:	ec56                	sd	s5,24(sp)
    80002456:	e85a                	sd	s6,16(sp)
    80002458:	e45e                	sd	s7,8(sp)
    8000245a:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    8000245c:	8792                	mv	a5,tp
  int id = r_tp();
    8000245e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002460:	00779b13          	slli	s6,a5,0x7
    80002464:	0000f717          	auipc	a4,0xf
    80002468:	e5c70713          	addi	a4,a4,-420 # 800112c0 <pid_lock>
    8000246c:	975a                	add	a4,a4,s6
    8000246e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002472:	0000f717          	auipc	a4,0xf
    80002476:	e8670713          	addi	a4,a4,-378 # 800112f8 <cpus+0x8>
    8000247a:	9b3a                	add	s6,s6,a4
    if (ticks >= nextGoodTicks)
    8000247c:	00007997          	auipc	s3,0x7
    80002480:	bd498993          	addi	s3,s3,-1068 # 80009050 <ticks>
    80002484:	00007917          	auipc	s2,0x7
    80002488:	bc090913          	addi	s2,s2,-1088 # 80009044 <nextGoodTicks>
      if (p->state == RUNNABLE)
    8000248c:	4a0d                	li	s4,3
        p->state = RUNNING;
    8000248e:	4b91                	li	s7,4
        c->proc = p;
    80002490:	079e                	slli	a5,a5,0x7
    80002492:	0000fa97          	auipc	s5,0xf
    80002496:	e2ea8a93          	addi	s5,s5,-466 # 800112c0 <pid_lock>
    8000249a:	9abe                	add	s5,s5,a5
    8000249c:	a031                	j	800024a8 <FCFSScheduler+0x62>
    release(&p->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7f8080e7          	jalr	2040(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024a8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800024ac:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024b0:	10079073          	csrw	sstatus,a5
    p = minLastRunnableTime();
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	e8e080e7          	jalr	-370(ra) # 80002342 <minLastRunnableTime>
    800024bc:	84aa                	mv	s1,a0
    if (ticks >= nextGoodTicks)
    800024be:	0009a703          	lw	a4,0(s3)
    800024c2:	00092783          	lw	a5,0(s2)
    800024c6:	fcf76ce3          	bltu	a4,a5,8000249e <FCFSScheduler+0x58>
      if (p->state == RUNNABLE)
    800024ca:	4d1c                	lw	a5,24(a0)
    800024cc:	fd4799e3          	bne	a5,s4,8000249e <FCFSScheduler+0x58>
        stateChange(p);
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	492080e7          	jalr	1170(ra) # 80001962 <stateChange>
        p->state = RUNNING;
    800024d8:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    800024dc:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    800024e0:	08048593          	addi	a1,s1,128
    800024e4:	855a                	mv	a0,s6
    800024e6:	00001097          	auipc	ra,0x1
    800024ea:	88a080e7          	jalr	-1910(ra) # 80002d70 <swtch>
        c->proc = 0;
    800024ee:	020ab823          	sd	zero,48(s5)
    800024f2:	b775                	j	8000249e <FCFSScheduler+0x58>

00000000800024f4 <regulerScheduler>:
{
    800024f4:	715d                	addi	sp,sp,-80
    800024f6:	e486                	sd	ra,72(sp)
    800024f8:	e0a2                	sd	s0,64(sp)
    800024fa:	fc26                	sd	s1,56(sp)
    800024fc:	f84a                	sd	s2,48(sp)
    800024fe:	f44e                	sd	s3,40(sp)
    80002500:	f052                	sd	s4,32(sp)
    80002502:	ec56                	sd	s5,24(sp)
    80002504:	e85a                	sd	s6,16(sp)
    80002506:	e45e                	sd	s7,8(sp)
    80002508:	e062                	sd	s8,0(sp)
    8000250a:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    8000250c:	8792                	mv	a5,tp
  int id = r_tp();
    8000250e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002510:	00779c13          	slli	s8,a5,0x7
    80002514:	0000f717          	auipc	a4,0xf
    80002518:	dac70713          	addi	a4,a4,-596 # 800112c0 <pid_lock>
    8000251c:	9762                	add	a4,a4,s8
    8000251e:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80002522:	0000f717          	auipc	a4,0xf
    80002526:	dd670713          	addi	a4,a4,-554 # 800112f8 <cpus+0x8>
    8000252a:	9c3a                	add	s8,s8,a4
      if (ticks >= nextGoodTicks)
    8000252c:	00007a17          	auipc	s4,0x7
    80002530:	b24a0a13          	addi	s4,s4,-1244 # 80009050 <ticks>
    80002534:	00007997          	auipc	s3,0x7
    80002538:	b1098993          	addi	s3,s3,-1264 # 80009044 <nextGoodTicks>
        if (p->state == RUNNABLE)
    8000253c:	4a8d                	li	s5,3
          c->proc = p;
    8000253e:	079e                	slli	a5,a5,0x7
    80002540:	0000fb17          	auipc	s6,0xf
    80002544:	d80b0b13          	addi	s6,s6,-640 # 800112c0 <pid_lock>
    80002548:	9b3e                	add	s6,s6,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000254a:	00015917          	auipc	s2,0x15
    8000254e:	3a690913          	addi	s2,s2,934 # 800178f0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002552:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002556:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000255a:	10079073          	csrw	sstatus,a5
    8000255e:	0000f497          	auipc	s1,0xf
    80002562:	19248493          	addi	s1,s1,402 # 800116f0 <proc>
          p->state = RUNNING;
    80002566:	4b91                	li	s7,4
    80002568:	a825                	j	800025a0 <regulerScheduler+0xac>
          stateChange(p);
    8000256a:	8526                	mv	a0,s1
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	3f6080e7          	jalr	1014(ra) # 80001962 <stateChange>
          p->state = RUNNING;
    80002574:	0174ac23          	sw	s7,24(s1)
          c->proc = p;
    80002578:	029b3823          	sd	s1,48(s6)
          swtch(&c->context, &p->context);
    8000257c:	08048593          	addi	a1,s1,128
    80002580:	8562                	mv	a0,s8
    80002582:	00000097          	auipc	ra,0x0
    80002586:	7ee080e7          	jalr	2030(ra) # 80002d70 <swtch>
          c->proc = 0;
    8000258a:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    8000258e:	8526                	mv	a0,s1
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	708080e7          	jalr	1800(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002598:	18848493          	addi	s1,s1,392
    8000259c:	fb248be3          	beq	s1,s2,80002552 <regulerScheduler+0x5e>
      if (ticks >= nextGoodTicks)
    800025a0:	000a2703          	lw	a4,0(s4)
    800025a4:	0009a783          	lw	a5,0(s3)
    800025a8:	fef768e3          	bltu	a4,a5,80002598 <regulerScheduler+0xa4>
        acquire(&p->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	636080e7          	jalr	1590(ra) # 80000be4 <acquire>
        if (p->state == RUNNABLE)
    800025b6:	4c9c                	lw	a5,24(s1)
    800025b8:	fd579be3          	bne	a5,s5,8000258e <regulerScheduler+0x9a>
    800025bc:	b77d                	j	8000256a <regulerScheduler+0x76>

00000000800025be <scheduler>:
{
    800025be:	1141                	addi	sp,sp,-16
    800025c0:	e406                	sd	ra,8(sp)
    800025c2:	e022                	sd	s0,0(sp)
    800025c4:	0800                	addi	s0,sp,16
    regulerScheduler();
    800025c6:	00000097          	auipc	ra,0x0
    800025ca:	f2e080e7          	jalr	-210(ra) # 800024f4 <regulerScheduler>

00000000800025ce <sched>:
{
    800025ce:	7179                	addi	sp,sp,-48
    800025d0:	f406                	sd	ra,40(sp)
    800025d2:	f022                	sd	s0,32(sp)
    800025d4:	ec26                	sd	s1,24(sp)
    800025d6:	e84a                	sd	s2,16(sp)
    800025d8:	e44e                	sd	s3,8(sp)
    800025da:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800025dc:	fffff097          	auipc	ra,0xfffff
    800025e0:	64a080e7          	jalr	1610(ra) # 80001c26 <myproc>
    800025e4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	584080e7          	jalr	1412(ra) # 80000b6a <holding>
    800025ee:	c93d                	beqz	a0,80002664 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025f0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800025f2:	2781                	sext.w	a5,a5
    800025f4:	079e                	slli	a5,a5,0x7
    800025f6:	0000f717          	auipc	a4,0xf
    800025fa:	cca70713          	addi	a4,a4,-822 # 800112c0 <pid_lock>
    800025fe:	97ba                	add	a5,a5,a4
    80002600:	0a87a703          	lw	a4,168(a5)
    80002604:	4785                	li	a5,1
    80002606:	06f71763          	bne	a4,a5,80002674 <sched+0xa6>
  if(p->state == RUNNING)
    8000260a:	4c98                	lw	a4,24(s1)
    8000260c:	4791                	li	a5,4
    8000260e:	06f70b63          	beq	a4,a5,80002684 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002612:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002616:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002618:	efb5                	bnez	a5,80002694 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000261a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000261c:	0000f917          	auipc	s2,0xf
    80002620:	ca490913          	addi	s2,s2,-860 # 800112c0 <pid_lock>
    80002624:	2781                	sext.w	a5,a5
    80002626:	079e                	slli	a5,a5,0x7
    80002628:	97ca                	add	a5,a5,s2
    8000262a:	0ac7a983          	lw	s3,172(a5)
    8000262e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002630:	2781                	sext.w	a5,a5
    80002632:	079e                	slli	a5,a5,0x7
    80002634:	0000f597          	auipc	a1,0xf
    80002638:	cc458593          	addi	a1,a1,-828 # 800112f8 <cpus+0x8>
    8000263c:	95be                	add	a1,a1,a5
    8000263e:	08048513          	addi	a0,s1,128
    80002642:	00000097          	auipc	ra,0x0
    80002646:	72e080e7          	jalr	1838(ra) # 80002d70 <swtch>
    8000264a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000264c:	2781                	sext.w	a5,a5
    8000264e:	079e                	slli	a5,a5,0x7
    80002650:	97ca                	add	a5,a5,s2
    80002652:	0b37a623          	sw	s3,172(a5)
}
    80002656:	70a2                	ld	ra,40(sp)
    80002658:	7402                	ld	s0,32(sp)
    8000265a:	64e2                	ld	s1,24(sp)
    8000265c:	6942                	ld	s2,16(sp)
    8000265e:	69a2                	ld	s3,8(sp)
    80002660:	6145                	addi	sp,sp,48
    80002662:	8082                	ret
    panic("sched p->lock");
    80002664:	00006517          	auipc	a0,0x6
    80002668:	c7450513          	addi	a0,a0,-908 # 800082d8 <digits+0x298>
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	ed2080e7          	jalr	-302(ra) # 8000053e <panic>
    panic("sched locks");
    80002674:	00006517          	auipc	a0,0x6
    80002678:	c7450513          	addi	a0,a0,-908 # 800082e8 <digits+0x2a8>
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	ec2080e7          	jalr	-318(ra) # 8000053e <panic>
    panic("sched running");
    80002684:	00006517          	auipc	a0,0x6
    80002688:	c7450513          	addi	a0,a0,-908 # 800082f8 <digits+0x2b8>
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	eb2080e7          	jalr	-334(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002694:	00006517          	auipc	a0,0x6
    80002698:	c7450513          	addi	a0,a0,-908 # 80008308 <digits+0x2c8>
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	ea2080e7          	jalr	-350(ra) # 8000053e <panic>

00000000800026a4 <yield>:
{
    800026a4:	1101                	addi	sp,sp,-32
    800026a6:	ec06                	sd	ra,24(sp)
    800026a8:	e822                	sd	s0,16(sp)
    800026aa:	e426                	sd	s1,8(sp)
    800026ac:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	578080e7          	jalr	1400(ra) # 80001c26 <myproc>
    800026b6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	52c080e7          	jalr	1324(ra) # 80000be4 <acquire>
  changeStateToRunnable(p);
    800026c0:	8526                	mv	a0,s1
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	306080e7          	jalr	774(ra) # 800019c8 <changeStateToRunnable>
  sched();
    800026ca:	00000097          	auipc	ra,0x0
    800026ce:	f04080e7          	jalr	-252(ra) # 800025ce <sched>
  release(&p->lock);
    800026d2:	8526                	mv	a0,s1
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	5c4080e7          	jalr	1476(ra) # 80000c98 <release>
}
    800026dc:	60e2                	ld	ra,24(sp)
    800026de:	6442                	ld	s0,16(sp)
    800026e0:	64a2                	ld	s1,8(sp)
    800026e2:	6105                	addi	sp,sp,32
    800026e4:	8082                	ret

00000000800026e6 <pause_system>:
{
    800026e6:	7179                	addi	sp,sp,-48
    800026e8:	f406                	sd	ra,40(sp)
    800026ea:	f022                	sd	s0,32(sp)
    800026ec:	ec26                	sd	s1,24(sp)
    800026ee:	e84a                	sd	s2,16(sp)
    800026f0:	e44e                	sd	s3,8(sp)
    800026f2:	e052                	sd	s4,0(sp)
    800026f4:	1800                	addi	s0,sp,48
  nextGoodTicks = ticks + 10 * seconds;
    800026f6:	0025179b          	slliw	a5,a0,0x2
    800026fa:	9fa9                	addw	a5,a5,a0
    800026fc:	0017979b          	slliw	a5,a5,0x1
    80002700:	00007717          	auipc	a4,0x7
    80002704:	95072703          	lw	a4,-1712(a4) # 80009050 <ticks>
    80002708:	9fb9                	addw	a5,a5,a4
    8000270a:	00007717          	auipc	a4,0x7
    8000270e:	92f72d23          	sw	a5,-1734(a4) # 80009044 <nextGoodTicks>
  for (p = proc; p < &proc[NPROC]; p++)
    80002712:	0000f497          	auipc	s1,0xf
    80002716:	fde48493          	addi	s1,s1,-34 # 800116f0 <proc>
    if (p->state == RUNNING && p->pid > 2)
    8000271a:	4991                	li	s3,4
    8000271c:	4a09                	li	s4,2
  for (p = proc; p < &proc[NPROC]; p++)
    8000271e:	00015917          	auipc	s2,0x15
    80002722:	1d290913          	addi	s2,s2,466 # 800178f0 <tickslock>
    80002726:	a839                	j	80002744 <pause_system+0x5e>
      changeStateToRunnable(p);
    80002728:	8526                	mv	a0,s1
    8000272a:	fffff097          	auipc	ra,0xfffff
    8000272e:	29e080e7          	jalr	670(ra) # 800019c8 <changeStateToRunnable>
    release(&p->lock);
    80002732:	8526                	mv	a0,s1
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	564080e7          	jalr	1380(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000273c:	18848493          	addi	s1,s1,392
    80002740:	01248e63          	beq	s1,s2,8000275c <pause_system+0x76>
    acquire(&p->lock);
    80002744:	8526                	mv	a0,s1
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	49e080e7          	jalr	1182(ra) # 80000be4 <acquire>
    if (p->state == RUNNING && p->pid > 2)
    8000274e:	4c9c                	lw	a5,24(s1)
    80002750:	ff3791e3          	bne	a5,s3,80002732 <pause_system+0x4c>
    80002754:	589c                	lw	a5,48(s1)
    80002756:	fcfa5ee3          	bge	s4,a5,80002732 <pause_system+0x4c>
    8000275a:	b7f9                	j	80002728 <pause_system+0x42>
  yield();
    8000275c:	00000097          	auipc	ra,0x0
    80002760:	f48080e7          	jalr	-184(ra) # 800026a4 <yield>
}
    80002764:	4501                	li	a0,0
    80002766:	70a2                	ld	ra,40(sp)
    80002768:	7402                	ld	s0,32(sp)
    8000276a:	64e2                	ld	s1,24(sp)
    8000276c:	6942                	ld	s2,16(sp)
    8000276e:	69a2                	ld	s3,8(sp)
    80002770:	6a02                	ld	s4,0(sp)
    80002772:	6145                	addi	sp,sp,48
    80002774:	8082                	ret

0000000080002776 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002776:	7179                	addi	sp,sp,-48
    80002778:	f406                	sd	ra,40(sp)
    8000277a:	f022                	sd	s0,32(sp)
    8000277c:	ec26                	sd	s1,24(sp)
    8000277e:	e84a                	sd	s2,16(sp)
    80002780:	e44e                	sd	s3,8(sp)
    80002782:	1800                	addi	s0,sp,48
    80002784:	89aa                	mv	s3,a0
    80002786:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002788:	fffff097          	auipc	ra,0xfffff
    8000278c:	49e080e7          	jalr	1182(ra) # 80001c26 <myproc>
    80002790:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	452080e7          	jalr	1106(ra) # 80000be4 <acquire>
  release(lk);
    8000279a:	854a                	mv	a0,s2
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	4fc080e7          	jalr	1276(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800027a4:	0334b023          	sd	s3,32(s1)

  stateChange(p);
    800027a8:	8526                	mv	a0,s1
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	1b8080e7          	jalr	440(ra) # 80001962 <stateChange>
  p->state = SLEEPING;
    800027b2:	4789                	li	a5,2
    800027b4:	cc9c                	sw	a5,24(s1)

  sched();
    800027b6:	00000097          	auipc	ra,0x0
    800027ba:	e18080e7          	jalr	-488(ra) # 800025ce <sched>

  // Tidy up.
  p->chan = 0;
    800027be:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800027c2:	8526                	mv	a0,s1
    800027c4:	ffffe097          	auipc	ra,0xffffe
    800027c8:	4d4080e7          	jalr	1236(ra) # 80000c98 <release>
  acquire(lk);
    800027cc:	854a                	mv	a0,s2
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	416080e7          	jalr	1046(ra) # 80000be4 <acquire>
}
    800027d6:	70a2                	ld	ra,40(sp)
    800027d8:	7402                	ld	s0,32(sp)
    800027da:	64e2                	ld	s1,24(sp)
    800027dc:	6942                	ld	s2,16(sp)
    800027de:	69a2                	ld	s3,8(sp)
    800027e0:	6145                	addi	sp,sp,48
    800027e2:	8082                	ret

00000000800027e4 <wait>:
{
    800027e4:	715d                	addi	sp,sp,-80
    800027e6:	e486                	sd	ra,72(sp)
    800027e8:	e0a2                	sd	s0,64(sp)
    800027ea:	fc26                	sd	s1,56(sp)
    800027ec:	f84a                	sd	s2,48(sp)
    800027ee:	f44e                	sd	s3,40(sp)
    800027f0:	f052                	sd	s4,32(sp)
    800027f2:	ec56                	sd	s5,24(sp)
    800027f4:	e85a                	sd	s6,16(sp)
    800027f6:	e45e                	sd	s7,8(sp)
    800027f8:	e062                	sd	s8,0(sp)
    800027fa:	0880                	addi	s0,sp,80
    800027fc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027fe:	fffff097          	auipc	ra,0xfffff
    80002802:	428080e7          	jalr	1064(ra) # 80001c26 <myproc>
    80002806:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002808:	0000f517          	auipc	a0,0xf
    8000280c:	ad050513          	addi	a0,a0,-1328 # 800112d8 <wait_lock>
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	3d4080e7          	jalr	980(ra) # 80000be4 <acquire>
    havekids = 0;
    80002818:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000281a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000281c:	00015997          	auipc	s3,0x15
    80002820:	0d498993          	addi	s3,s3,212 # 800178f0 <tickslock>
        havekids = 1;
    80002824:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002826:	0000fc17          	auipc	s8,0xf
    8000282a:	ab2c0c13          	addi	s8,s8,-1358 # 800112d8 <wait_lock>
    havekids = 0;
    8000282e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002830:	0000f497          	auipc	s1,0xf
    80002834:	ec048493          	addi	s1,s1,-320 # 800116f0 <proc>
    80002838:	a0bd                	j	800028a6 <wait+0xc2>
          pid = np->pid;
    8000283a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000283e:	000b0e63          	beqz	s6,8000285a <wait+0x76>
    80002842:	4691                	li	a3,4
    80002844:	02c48613          	addi	a2,s1,44
    80002848:	85da                	mv	a1,s6
    8000284a:	07093503          	ld	a0,112(s2)
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	f48080e7          	jalr	-184(ra) # 80001796 <copyout>
    80002856:	02054563          	bltz	a0,80002880 <wait+0x9c>
          freeproc(np);
    8000285a:	8526                	mv	a0,s1
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	57c080e7          	jalr	1404(ra) # 80001dd8 <freeproc>
          release(&np->lock);
    80002864:	8526                	mv	a0,s1
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	432080e7          	jalr	1074(ra) # 80000c98 <release>
          release(&wait_lock);
    8000286e:	0000f517          	auipc	a0,0xf
    80002872:	a6a50513          	addi	a0,a0,-1430 # 800112d8 <wait_lock>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	422080e7          	jalr	1058(ra) # 80000c98 <release>
          return pid;
    8000287e:	a09d                	j	800028e4 <wait+0x100>
            release(&np->lock);
    80002880:	8526                	mv	a0,s1
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	416080e7          	jalr	1046(ra) # 80000c98 <release>
            release(&wait_lock);
    8000288a:	0000f517          	auipc	a0,0xf
    8000288e:	a4e50513          	addi	a0,a0,-1458 # 800112d8 <wait_lock>
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	406080e7          	jalr	1030(ra) # 80000c98 <release>
            return -1;
    8000289a:	59fd                	li	s3,-1
    8000289c:	a0a1                	j	800028e4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000289e:	18848493          	addi	s1,s1,392
    800028a2:	03348463          	beq	s1,s3,800028ca <wait+0xe6>
      if(np->parent == p){
    800028a6:	7c9c                	ld	a5,56(s1)
    800028a8:	ff279be3          	bne	a5,s2,8000289e <wait+0xba>
        acquire(&np->lock);
    800028ac:	8526                	mv	a0,s1
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	336080e7          	jalr	822(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800028b6:	4c9c                	lw	a5,24(s1)
    800028b8:	f94781e3          	beq	a5,s4,8000283a <wait+0x56>
        release(&np->lock);
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	3da080e7          	jalr	986(ra) # 80000c98 <release>
        havekids = 1;
    800028c6:	8756                	mv	a4,s5
    800028c8:	bfd9                	j	8000289e <wait+0xba>
    if(!havekids || p->killed){
    800028ca:	c701                	beqz	a4,800028d2 <wait+0xee>
    800028cc:	02892783          	lw	a5,40(s2)
    800028d0:	c79d                	beqz	a5,800028fe <wait+0x11a>
      release(&wait_lock);
    800028d2:	0000f517          	auipc	a0,0xf
    800028d6:	a0650513          	addi	a0,a0,-1530 # 800112d8 <wait_lock>
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	3be080e7          	jalr	958(ra) # 80000c98 <release>
      return -1;
    800028e2:	59fd                	li	s3,-1
}
    800028e4:	854e                	mv	a0,s3
    800028e6:	60a6                	ld	ra,72(sp)
    800028e8:	6406                	ld	s0,64(sp)
    800028ea:	74e2                	ld	s1,56(sp)
    800028ec:	7942                	ld	s2,48(sp)
    800028ee:	79a2                	ld	s3,40(sp)
    800028f0:	7a02                	ld	s4,32(sp)
    800028f2:	6ae2                	ld	s5,24(sp)
    800028f4:	6b42                	ld	s6,16(sp)
    800028f6:	6ba2                	ld	s7,8(sp)
    800028f8:	6c02                	ld	s8,0(sp)
    800028fa:	6161                	addi	sp,sp,80
    800028fc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028fe:	85e2                	mv	a1,s8
    80002900:	854a                	mv	a0,s2
    80002902:	00000097          	auipc	ra,0x0
    80002906:	e74080e7          	jalr	-396(ra) # 80002776 <sleep>
    havekids = 0;
    8000290a:	b715                	j	8000282e <wait+0x4a>

000000008000290c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000290c:	7179                	addi	sp,sp,-48
    8000290e:	f406                	sd	ra,40(sp)
    80002910:	f022                	sd	s0,32(sp)
    80002912:	ec26                	sd	s1,24(sp)
    80002914:	e84a                	sd	s2,16(sp)
    80002916:	e44e                	sd	s3,8(sp)
    80002918:	e052                	sd	s4,0(sp)
    8000291a:	1800                	addi	s0,sp,48
    8000291c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000291e:	0000f497          	auipc	s1,0xf
    80002922:	dd248493          	addi	s1,s1,-558 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002926:	4989                	li	s3,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002928:	00015917          	auipc	s2,0x15
    8000292c:	fc890913          	addi	s2,s2,-56 # 800178f0 <tickslock>
    80002930:	a811                	j	80002944 <wakeup+0x38>
        changeStateToRunnable(p);
      }
      release(&p->lock);
    80002932:	8526                	mv	a0,s1
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	364080e7          	jalr	868(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000293c:	18848493          	addi	s1,s1,392
    80002940:	03248963          	beq	s1,s2,80002972 <wakeup+0x66>
    if(p != myproc()){
    80002944:	fffff097          	auipc	ra,0xfffff
    80002948:	2e2080e7          	jalr	738(ra) # 80001c26 <myproc>
    8000294c:	fea488e3          	beq	s1,a0,8000293c <wakeup+0x30>
      acquire(&p->lock);
    80002950:	8526                	mv	a0,s1
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	292080e7          	jalr	658(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000295a:	4c9c                	lw	a5,24(s1)
    8000295c:	fd379be3          	bne	a5,s3,80002932 <wakeup+0x26>
    80002960:	709c                	ld	a5,32(s1)
    80002962:	fd4798e3          	bne	a5,s4,80002932 <wakeup+0x26>
        changeStateToRunnable(p);
    80002966:	8526                	mv	a0,s1
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	060080e7          	jalr	96(ra) # 800019c8 <changeStateToRunnable>
    80002970:	b7c9                	j	80002932 <wakeup+0x26>
    }
  }
}
    80002972:	70a2                	ld	ra,40(sp)
    80002974:	7402                	ld	s0,32(sp)
    80002976:	64e2                	ld	s1,24(sp)
    80002978:	6942                	ld	s2,16(sp)
    8000297a:	69a2                	ld	s3,8(sp)
    8000297c:	6a02                	ld	s4,0(sp)
    8000297e:	6145                	addi	sp,sp,48
    80002980:	8082                	ret

0000000080002982 <reparent>:
{
    80002982:	7179                	addi	sp,sp,-48
    80002984:	f406                	sd	ra,40(sp)
    80002986:	f022                	sd	s0,32(sp)
    80002988:	ec26                	sd	s1,24(sp)
    8000298a:	e84a                	sd	s2,16(sp)
    8000298c:	e44e                	sd	s3,8(sp)
    8000298e:	e052                	sd	s4,0(sp)
    80002990:	1800                	addi	s0,sp,48
    80002992:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002994:	0000f497          	auipc	s1,0xf
    80002998:	d5c48493          	addi	s1,s1,-676 # 800116f0 <proc>
      pp->parent = initproc;
    8000299c:	00006a17          	auipc	s4,0x6
    800029a0:	6aca0a13          	addi	s4,s4,1708 # 80009048 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800029a4:	00015997          	auipc	s3,0x15
    800029a8:	f4c98993          	addi	s3,s3,-180 # 800178f0 <tickslock>
    800029ac:	a029                	j	800029b6 <reparent+0x34>
    800029ae:	18848493          	addi	s1,s1,392
    800029b2:	01348d63          	beq	s1,s3,800029cc <reparent+0x4a>
    if(pp->parent == p){
    800029b6:	7c9c                	ld	a5,56(s1)
    800029b8:	ff279be3          	bne	a5,s2,800029ae <reparent+0x2c>
      pp->parent = initproc;
    800029bc:	000a3503          	ld	a0,0(s4)
    800029c0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800029c2:	00000097          	auipc	ra,0x0
    800029c6:	f4a080e7          	jalr	-182(ra) # 8000290c <wakeup>
    800029ca:	b7d5                	j	800029ae <reparent+0x2c>
}
    800029cc:	70a2                	ld	ra,40(sp)
    800029ce:	7402                	ld	s0,32(sp)
    800029d0:	64e2                	ld	s1,24(sp)
    800029d2:	6942                	ld	s2,16(sp)
    800029d4:	69a2                	ld	s3,8(sp)
    800029d6:	6a02                	ld	s4,0(sp)
    800029d8:	6145                	addi	sp,sp,48
    800029da:	8082                	ret

00000000800029dc <exit>:
{
    800029dc:	7179                	addi	sp,sp,-48
    800029de:	f406                	sd	ra,40(sp)
    800029e0:	f022                	sd	s0,32(sp)
    800029e2:	ec26                	sd	s1,24(sp)
    800029e4:	e84a                	sd	s2,16(sp)
    800029e6:	e44e                	sd	s3,8(sp)
    800029e8:	e052                	sd	s4,0(sp)
    800029ea:	1800                	addi	s0,sp,48
    800029ec:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800029ee:	fffff097          	auipc	ra,0xfffff
    800029f2:	238080e7          	jalr	568(ra) # 80001c26 <myproc>
    800029f6:	892a                	mv	s2,a0
  if(p == initproc)
    800029f8:	00006797          	auipc	a5,0x6
    800029fc:	6507b783          	ld	a5,1616(a5) # 80009048 <initproc>
    80002a00:	0f050493          	addi	s1,a0,240
    80002a04:	17050993          	addi	s3,a0,368
    80002a08:	02a79363          	bne	a5,a0,80002a2e <exit+0x52>
    panic("init exiting");
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	91450513          	addi	a0,a0,-1772 # 80008320 <digits+0x2e0>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b2a080e7          	jalr	-1238(ra) # 8000053e <panic>
      fileclose(f);
    80002a1c:	00002097          	auipc	ra,0x2
    80002a20:	2b8080e7          	jalr	696(ra) # 80004cd4 <fileclose>
      p->ofile[fd] = 0;
    80002a24:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a28:	04a1                	addi	s1,s1,8
    80002a2a:	01348563          	beq	s1,s3,80002a34 <exit+0x58>
    if(p->ofile[fd]){
    80002a2e:	6088                	ld	a0,0(s1)
    80002a30:	f575                	bnez	a0,80002a1c <exit+0x40>
    80002a32:	bfdd                	j	80002a28 <exit+0x4c>
  begin_op();
    80002a34:	00002097          	auipc	ra,0x2
    80002a38:	dd4080e7          	jalr	-556(ra) # 80004808 <begin_op>
  iput(p->cwd);
    80002a3c:	17093503          	ld	a0,368(s2)
    80002a40:	00001097          	auipc	ra,0x1
    80002a44:	5b0080e7          	jalr	1456(ra) # 80003ff0 <iput>
  end_op();
    80002a48:	00002097          	auipc	ra,0x2
    80002a4c:	e40080e7          	jalr	-448(ra) # 80004888 <end_op>
  p->cwd = 0;
    80002a50:	16093823          	sd	zero,368(s2)
  acquire(&wait_lock);
    80002a54:	0000f497          	auipc	s1,0xf
    80002a58:	88448493          	addi	s1,s1,-1916 # 800112d8 <wait_lock>
    80002a5c:	8526                	mv	a0,s1
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	186080e7          	jalr	390(ra) # 80000be4 <acquire>
  reparent(p);
    80002a66:	854a                	mv	a0,s2
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	f1a080e7          	jalr	-230(ra) # 80002982 <reparent>
  wakeup(p->parent);
    80002a70:	03893503          	ld	a0,56(s2)
    80002a74:	00000097          	auipc	ra,0x0
    80002a78:	e98080e7          	jalr	-360(ra) # 8000290c <wakeup>
  acquire(&p->lock);
    80002a7c:	854a                	mv	a0,s2
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	166080e7          	jalr	358(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002a86:	03492623          	sw	s4,44(s2)
  stateChange(p);
    80002a8a:	854a                	mv	a0,s2
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	ed6080e7          	jalr	-298(ra) # 80001962 <stateChange>
  p->state = ZOMBIE;
    80002a94:	4795                	li	a5,5
    80002a96:	00f92c23          	sw	a5,24(s2)
  sleeping_processes_total += p->sleeping_time;
    80002a9a:	00006717          	auipc	a4,0x6
    80002a9e:	5a670713          	addi	a4,a4,1446 # 80009040 <sleeping_processes_total>
    80002aa2:	05092783          	lw	a5,80(s2)
    80002aa6:	4314                	lw	a3,0(a4)
    80002aa8:	9fb5                	addw	a5,a5,a3
    80002aaa:	c31c                	sw	a5,0(a4)
  runnable_time_total += p->runnable_time;
    80002aac:	00006717          	auipc	a4,0x6
    80002ab0:	59070713          	addi	a4,a4,1424 # 8000903c <runnable_time_total>
    80002ab4:	05492783          	lw	a5,84(s2)
    80002ab8:	4314                	lw	a3,0(a4)
    80002aba:	9fb5                	addw	a5,a5,a3
    80002abc:	c31c                	sw	a5,0(a4)
  running_time_total += p->running_time;
    80002abe:	05892703          	lw	a4,88(s2)
    80002ac2:	00006797          	auipc	a5,0x6
    80002ac6:	57678793          	addi	a5,a5,1398 # 80009038 <running_time_total>
    80002aca:	4394                	lw	a3,0(a5)
    80002acc:	9eb9                	addw	a3,a3,a4
    80002ace:	c394                	sw	a3,0(a5)
  processes_count++;
    80002ad0:	00006797          	auipc	a5,0x6
    80002ad4:	56478793          	addi	a5,a5,1380 # 80009034 <processes_count>
    80002ad8:	4394                	lw	a3,0(a5)
    80002ada:	2685                	addiw	a3,a3,1
    80002adc:	c394                	sw	a3,0(a5)
  program_time += p->running_time;
    80002ade:	00006697          	auipc	a3,0x6
    80002ae2:	55268693          	addi	a3,a3,1362 # 80009030 <program_time>
    80002ae6:	429c                	lw	a5,0(a3)
    80002ae8:	9f3d                	addw	a4,a4,a5
    80002aea:	c298                	sw	a4,0(a3)
  cpu_utilization = program_time * 100 / (ticks - start_time);
    80002aec:	06400793          	li	a5,100
    80002af0:	02e787bb          	mulw	a5,a5,a4
    80002af4:	00006717          	auipc	a4,0x6
    80002af8:	55c72703          	lw	a4,1372(a4) # 80009050 <ticks>
    80002afc:	00006697          	auipc	a3,0x6
    80002b00:	52c6a683          	lw	a3,1324(a3) # 80009028 <start_time>
    80002b04:	9f15                	subw	a4,a4,a3
    80002b06:	02e7d7bb          	divuw	a5,a5,a4
    80002b0a:	00006717          	auipc	a4,0x6
    80002b0e:	52f72123          	sw	a5,1314(a4) # 8000902c <cpu_utilization>
  release(&wait_lock);
    80002b12:	8526                	mv	a0,s1
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	184080e7          	jalr	388(ra) # 80000c98 <release>
  sched();
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	ab2080e7          	jalr	-1358(ra) # 800025ce <sched>
  panic("zombie exit");
    80002b24:	00006517          	auipc	a0,0x6
    80002b28:	80c50513          	addi	a0,a0,-2036 # 80008330 <digits+0x2f0>
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	a12080e7          	jalr	-1518(ra) # 8000053e <panic>

0000000080002b34 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002b34:	7179                	addi	sp,sp,-48
    80002b36:	f406                	sd	ra,40(sp)
    80002b38:	f022                	sd	s0,32(sp)
    80002b3a:	ec26                	sd	s1,24(sp)
    80002b3c:	e84a                	sd	s2,16(sp)
    80002b3e:	e44e                	sd	s3,8(sp)
    80002b40:	1800                	addi	s0,sp,48
    80002b42:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002b44:	0000f497          	auipc	s1,0xf
    80002b48:	bac48493          	addi	s1,s1,-1108 # 800116f0 <proc>
    80002b4c:	00015997          	auipc	s3,0x15
    80002b50:	da498993          	addi	s3,s3,-604 # 800178f0 <tickslock>
    acquire(&p->lock);
    80002b54:	8526                	mv	a0,s1
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	08e080e7          	jalr	142(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002b5e:	589c                	lw	a5,48(s1)
    80002b60:	01278d63          	beq	a5,s2,80002b7a <kill+0x46>
        changeStateToRunnable(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002b64:	8526                	mv	a0,s1
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	132080e7          	jalr	306(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b6e:	18848493          	addi	s1,s1,392
    80002b72:	ff3491e3          	bne	s1,s3,80002b54 <kill+0x20>
  }
  return -1;
    80002b76:	557d                	li	a0,-1
    80002b78:	a829                	j	80002b92 <kill+0x5e>
      p->killed = 1;
    80002b7a:	4785                	li	a5,1
    80002b7c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002b7e:	4c98                	lw	a4,24(s1)
    80002b80:	4789                	li	a5,2
    80002b82:	00f70f63          	beq	a4,a5,80002ba0 <kill+0x6c>
      release(&p->lock);
    80002b86:	8526                	mv	a0,s1
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	110080e7          	jalr	272(ra) # 80000c98 <release>
      return 0;
    80002b90:	4501                	li	a0,0
}
    80002b92:	70a2                	ld	ra,40(sp)
    80002b94:	7402                	ld	s0,32(sp)
    80002b96:	64e2                	ld	s1,24(sp)
    80002b98:	6942                	ld	s2,16(sp)
    80002b9a:	69a2                	ld	s3,8(sp)
    80002b9c:	6145                	addi	sp,sp,48
    80002b9e:	8082                	ret
        changeStateToRunnable(p);
    80002ba0:	8526                	mv	a0,s1
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	e26080e7          	jalr	-474(ra) # 800019c8 <changeStateToRunnable>
    80002baa:	bff1                	j	80002b86 <kill+0x52>

0000000080002bac <kill_system>:
{
    80002bac:	7179                	addi	sp,sp,-48
    80002bae:	f406                	sd	ra,40(sp)
    80002bb0:	f022                	sd	s0,32(sp)
    80002bb2:	ec26                	sd	s1,24(sp)
    80002bb4:	e84a                	sd	s2,16(sp)
    80002bb6:	e44e                	sd	s3,8(sp)
    80002bb8:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80002bba:	0000f497          	auipc	s1,0xf
    80002bbe:	b3648493          	addi	s1,s1,-1226 # 800116f0 <proc>
    if (p->pid > 2) // init process and shell?
    80002bc2:	4989                	li	s3,2
  for (p = proc; p < &proc[NPROC]; p++)
    80002bc4:	00015917          	auipc	s2,0x15
    80002bc8:	d2c90913          	addi	s2,s2,-724 # 800178f0 <tickslock>
    80002bcc:	a811                	j	80002be0 <kill_system+0x34>
      release(&p->lock);
    80002bce:	8526                	mv	a0,s1
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	0c8080e7          	jalr	200(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002bd8:	18848493          	addi	s1,s1,392
    80002bdc:	03248563          	beq	s1,s2,80002c06 <kill_system+0x5a>
    acquire(&p->lock);
    80002be0:	8526                	mv	a0,s1
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	002080e7          	jalr	2(ra) # 80000be4 <acquire>
    if (p->pid > 2) // init process and shell?
    80002bea:	589c                	lw	a5,48(s1)
    80002bec:	fef9d1e3          	bge	s3,a5,80002bce <kill_system+0x22>
      release(&p->lock);
    80002bf0:	8526                	mv	a0,s1
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	0a6080e7          	jalr	166(ra) # 80000c98 <release>
      kill(p->pid);
    80002bfa:	5888                	lw	a0,48(s1)
    80002bfc:	00000097          	auipc	ra,0x0
    80002c00:	f38080e7          	jalr	-200(ra) # 80002b34 <kill>
    80002c04:	bfd1                	j	80002bd8 <kill_system+0x2c>
}
    80002c06:	4501                	li	a0,0
    80002c08:	70a2                	ld	ra,40(sp)
    80002c0a:	7402                	ld	s0,32(sp)
    80002c0c:	64e2                	ld	s1,24(sp)
    80002c0e:	6942                	ld	s2,16(sp)
    80002c10:	69a2                	ld	s3,8(sp)
    80002c12:	6145                	addi	sp,sp,48
    80002c14:	8082                	ret

0000000080002c16 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002c16:	7179                	addi	sp,sp,-48
    80002c18:	f406                	sd	ra,40(sp)
    80002c1a:	f022                	sd	s0,32(sp)
    80002c1c:	ec26                	sd	s1,24(sp)
    80002c1e:	e84a                	sd	s2,16(sp)
    80002c20:	e44e                	sd	s3,8(sp)
    80002c22:	e052                	sd	s4,0(sp)
    80002c24:	1800                	addi	s0,sp,48
    80002c26:	84aa                	mv	s1,a0
    80002c28:	892e                	mv	s2,a1
    80002c2a:	89b2                	mv	s3,a2
    80002c2c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	ff8080e7          	jalr	-8(ra) # 80001c26 <myproc>
  if(user_dst){
    80002c36:	c08d                	beqz	s1,80002c58 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002c38:	86d2                	mv	a3,s4
    80002c3a:	864e                	mv	a2,s3
    80002c3c:	85ca                	mv	a1,s2
    80002c3e:	7928                	ld	a0,112(a0)
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	b56080e7          	jalr	-1194(ra) # 80001796 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002c48:	70a2                	ld	ra,40(sp)
    80002c4a:	7402                	ld	s0,32(sp)
    80002c4c:	64e2                	ld	s1,24(sp)
    80002c4e:	6942                	ld	s2,16(sp)
    80002c50:	69a2                	ld	s3,8(sp)
    80002c52:	6a02                	ld	s4,0(sp)
    80002c54:	6145                	addi	sp,sp,48
    80002c56:	8082                	ret
    memmove((char *)dst, src, len);
    80002c58:	000a061b          	sext.w	a2,s4
    80002c5c:	85ce                	mv	a1,s3
    80002c5e:	854a                	mv	a0,s2
    80002c60:	ffffe097          	auipc	ra,0xffffe
    80002c64:	0e0080e7          	jalr	224(ra) # 80000d40 <memmove>
    return 0;
    80002c68:	8526                	mv	a0,s1
    80002c6a:	bff9                	j	80002c48 <either_copyout+0x32>

0000000080002c6c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002c6c:	7179                	addi	sp,sp,-48
    80002c6e:	f406                	sd	ra,40(sp)
    80002c70:	f022                	sd	s0,32(sp)
    80002c72:	ec26                	sd	s1,24(sp)
    80002c74:	e84a                	sd	s2,16(sp)
    80002c76:	e44e                	sd	s3,8(sp)
    80002c78:	e052                	sd	s4,0(sp)
    80002c7a:	1800                	addi	s0,sp,48
    80002c7c:	892a                	mv	s2,a0
    80002c7e:	84ae                	mv	s1,a1
    80002c80:	89b2                	mv	s3,a2
    80002c82:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	fa2080e7          	jalr	-94(ra) # 80001c26 <myproc>
  if(user_src){
    80002c8c:	c08d                	beqz	s1,80002cae <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002c8e:	86d2                	mv	a3,s4
    80002c90:	864e                	mv	a2,s3
    80002c92:	85ca                	mv	a1,s2
    80002c94:	7928                	ld	a0,112(a0)
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	b8c080e7          	jalr	-1140(ra) # 80001822 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002c9e:	70a2                	ld	ra,40(sp)
    80002ca0:	7402                	ld	s0,32(sp)
    80002ca2:	64e2                	ld	s1,24(sp)
    80002ca4:	6942                	ld	s2,16(sp)
    80002ca6:	69a2                	ld	s3,8(sp)
    80002ca8:	6a02                	ld	s4,0(sp)
    80002caa:	6145                	addi	sp,sp,48
    80002cac:	8082                	ret
    memmove(dst, (char*)src, len);
    80002cae:	000a061b          	sext.w	a2,s4
    80002cb2:	85ce                	mv	a1,s3
    80002cb4:	854a                	mv	a0,s2
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	08a080e7          	jalr	138(ra) # 80000d40 <memmove>
    return 0;
    80002cbe:	8526                	mv	a0,s1
    80002cc0:	bff9                	j	80002c9e <either_copyin+0x32>

0000000080002cc2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002cc2:	715d                	addi	sp,sp,-80
    80002cc4:	e486                	sd	ra,72(sp)
    80002cc6:	e0a2                	sd	s0,64(sp)
    80002cc8:	fc26                	sd	s1,56(sp)
    80002cca:	f84a                	sd	s2,48(sp)
    80002ccc:	f44e                	sd	s3,40(sp)
    80002cce:	f052                	sd	s4,32(sp)
    80002cd0:	ec56                	sd	s5,24(sp)
    80002cd2:	e85a                	sd	s6,16(sp)
    80002cd4:	e45e                	sd	s7,8(sp)
    80002cd6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002cd8:	00005517          	auipc	a0,0x5
    80002cdc:	5a050513          	addi	a0,a0,1440 # 80008278 <digits+0x238>
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	8a8080e7          	jalr	-1880(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ce8:	0000f497          	auipc	s1,0xf
    80002cec:	b8048493          	addi	s1,s1,-1152 # 80011868 <proc+0x178>
    80002cf0:	00015917          	auipc	s2,0x15
    80002cf4:	d7890913          	addi	s2,s2,-648 # 80017a68 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cf8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002cfa:	00005997          	auipc	s3,0x5
    80002cfe:	64698993          	addi	s3,s3,1606 # 80008340 <digits+0x300>
    printf("%d %s %s", p->pid, state, p->name);
    80002d02:	00005a97          	auipc	s5,0x5
    80002d06:	646a8a93          	addi	s5,s5,1606 # 80008348 <digits+0x308>
    printf("\n");
    80002d0a:	00005a17          	auipc	s4,0x5
    80002d0e:	56ea0a13          	addi	s4,s4,1390 # 80008278 <digits+0x238>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d12:	00005b97          	auipc	s7,0x5
    80002d16:	66eb8b93          	addi	s7,s7,1646 # 80008380 <states.1793>
    80002d1a:	a00d                	j	80002d3c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002d1c:	eb86a583          	lw	a1,-328(a3)
    80002d20:	8556                	mv	a0,s5
    80002d22:	ffffe097          	auipc	ra,0xffffe
    80002d26:	866080e7          	jalr	-1946(ra) # 80000588 <printf>
    printf("\n");
    80002d2a:	8552                	mv	a0,s4
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	85c080e7          	jalr	-1956(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d34:	18848493          	addi	s1,s1,392
    80002d38:	03248163          	beq	s1,s2,80002d5a <procdump+0x98>
    if(p->state == UNUSED)
    80002d3c:	86a6                	mv	a3,s1
    80002d3e:	ea04a783          	lw	a5,-352(s1)
    80002d42:	dbed                	beqz	a5,80002d34 <procdump+0x72>
      state = "???";
    80002d44:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d46:	fcfb6be3          	bltu	s6,a5,80002d1c <procdump+0x5a>
    80002d4a:	1782                	slli	a5,a5,0x20
    80002d4c:	9381                	srli	a5,a5,0x20
    80002d4e:	078e                	slli	a5,a5,0x3
    80002d50:	97de                	add	a5,a5,s7
    80002d52:	6390                	ld	a2,0(a5)
    80002d54:	f661                	bnez	a2,80002d1c <procdump+0x5a>
      state = "???";
    80002d56:	864e                	mv	a2,s3
    80002d58:	b7d1                	j	80002d1c <procdump+0x5a>
  }
}
    80002d5a:	60a6                	ld	ra,72(sp)
    80002d5c:	6406                	ld	s0,64(sp)
    80002d5e:	74e2                	ld	s1,56(sp)
    80002d60:	7942                	ld	s2,48(sp)
    80002d62:	79a2                	ld	s3,40(sp)
    80002d64:	7a02                	ld	s4,32(sp)
    80002d66:	6ae2                	ld	s5,24(sp)
    80002d68:	6b42                	ld	s6,16(sp)
    80002d6a:	6ba2                	ld	s7,8(sp)
    80002d6c:	6161                	addi	sp,sp,80
    80002d6e:	8082                	ret

0000000080002d70 <swtch>:
    80002d70:	00153023          	sd	ra,0(a0)
    80002d74:	00253423          	sd	sp,8(a0)
    80002d78:	e900                	sd	s0,16(a0)
    80002d7a:	ed04                	sd	s1,24(a0)
    80002d7c:	03253023          	sd	s2,32(a0)
    80002d80:	03353423          	sd	s3,40(a0)
    80002d84:	03453823          	sd	s4,48(a0)
    80002d88:	03553c23          	sd	s5,56(a0)
    80002d8c:	05653023          	sd	s6,64(a0)
    80002d90:	05753423          	sd	s7,72(a0)
    80002d94:	05853823          	sd	s8,80(a0)
    80002d98:	05953c23          	sd	s9,88(a0)
    80002d9c:	07a53023          	sd	s10,96(a0)
    80002da0:	07b53423          	sd	s11,104(a0)
    80002da4:	0005b083          	ld	ra,0(a1)
    80002da8:	0085b103          	ld	sp,8(a1)
    80002dac:	6980                	ld	s0,16(a1)
    80002dae:	6d84                	ld	s1,24(a1)
    80002db0:	0205b903          	ld	s2,32(a1)
    80002db4:	0285b983          	ld	s3,40(a1)
    80002db8:	0305ba03          	ld	s4,48(a1)
    80002dbc:	0385ba83          	ld	s5,56(a1)
    80002dc0:	0405bb03          	ld	s6,64(a1)
    80002dc4:	0485bb83          	ld	s7,72(a1)
    80002dc8:	0505bc03          	ld	s8,80(a1)
    80002dcc:	0585bc83          	ld	s9,88(a1)
    80002dd0:	0605bd03          	ld	s10,96(a1)
    80002dd4:	0685bd83          	ld	s11,104(a1)
    80002dd8:	8082                	ret

0000000080002dda <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002dda:	1141                	addi	sp,sp,-16
    80002ddc:	e406                	sd	ra,8(sp)
    80002dde:	e022                	sd	s0,0(sp)
    80002de0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002de2:	00005597          	auipc	a1,0x5
    80002de6:	5ce58593          	addi	a1,a1,1486 # 800083b0 <states.1793+0x30>
    80002dea:	00015517          	auipc	a0,0x15
    80002dee:	b0650513          	addi	a0,a0,-1274 # 800178f0 <tickslock>
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	d62080e7          	jalr	-670(ra) # 80000b54 <initlock>
}
    80002dfa:	60a2                	ld	ra,8(sp)
    80002dfc:	6402                	ld	s0,0(sp)
    80002dfe:	0141                	addi	sp,sp,16
    80002e00:	8082                	ret

0000000080002e02 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002e02:	1141                	addi	sp,sp,-16
    80002e04:	e422                	sd	s0,8(sp)
    80002e06:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e08:	00003797          	auipc	a5,0x3
    80002e0c:	4e878793          	addi	a5,a5,1256 # 800062f0 <kernelvec>
    80002e10:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e14:	6422                	ld	s0,8(sp)
    80002e16:	0141                	addi	sp,sp,16
    80002e18:	8082                	ret

0000000080002e1a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002e1a:	1141                	addi	sp,sp,-16
    80002e1c:	e406                	sd	ra,8(sp)
    80002e1e:	e022                	sd	s0,0(sp)
    80002e20:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	e04080e7          	jalr	-508(ra) # 80001c26 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e2a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e2e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e30:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002e34:	00004617          	auipc	a2,0x4
    80002e38:	1cc60613          	addi	a2,a2,460 # 80007000 <_trampoline>
    80002e3c:	00004697          	auipc	a3,0x4
    80002e40:	1c468693          	addi	a3,a3,452 # 80007000 <_trampoline>
    80002e44:	8e91                	sub	a3,a3,a2
    80002e46:	040007b7          	lui	a5,0x4000
    80002e4a:	17fd                	addi	a5,a5,-1
    80002e4c:	07b2                	slli	a5,a5,0xc
    80002e4e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e50:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e54:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e56:	180026f3          	csrr	a3,satp
    80002e5a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e5c:	7d38                	ld	a4,120(a0)
    80002e5e:	7134                	ld	a3,96(a0)
    80002e60:	6585                	lui	a1,0x1
    80002e62:	96ae                	add	a3,a3,a1
    80002e64:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e66:	7d38                	ld	a4,120(a0)
    80002e68:	00000697          	auipc	a3,0x0
    80002e6c:	13868693          	addi	a3,a3,312 # 80002fa0 <usertrap>
    80002e70:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e72:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e74:	8692                	mv	a3,tp
    80002e76:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e78:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e7c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e80:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e84:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002e88:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e8a:	6f18                	ld	a4,24(a4)
    80002e8c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002e90:	792c                	ld	a1,112(a0)
    80002e92:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002e94:	00004717          	auipc	a4,0x4
    80002e98:	1fc70713          	addi	a4,a4,508 # 80007090 <userret>
    80002e9c:	8f11                	sub	a4,a4,a2
    80002e9e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ea0:	577d                	li	a4,-1
    80002ea2:	177e                	slli	a4,a4,0x3f
    80002ea4:	8dd9                	or	a1,a1,a4
    80002ea6:	02000537          	lui	a0,0x2000
    80002eaa:	157d                	addi	a0,a0,-1
    80002eac:	0536                	slli	a0,a0,0xd
    80002eae:	9782                	jalr	a5
}
    80002eb0:	60a2                	ld	ra,8(sp)
    80002eb2:	6402                	ld	s0,0(sp)
    80002eb4:	0141                	addi	sp,sp,16
    80002eb6:	8082                	ret

0000000080002eb8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002eb8:	1101                	addi	sp,sp,-32
    80002eba:	ec06                	sd	ra,24(sp)
    80002ebc:	e822                	sd	s0,16(sp)
    80002ebe:	e426                	sd	s1,8(sp)
    80002ec0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ec2:	00015497          	auipc	s1,0x15
    80002ec6:	a2e48493          	addi	s1,s1,-1490 # 800178f0 <tickslock>
    80002eca:	8526                	mv	a0,s1
    80002ecc:	ffffe097          	auipc	ra,0xffffe
    80002ed0:	d18080e7          	jalr	-744(ra) # 80000be4 <acquire>
  ticks++;
    80002ed4:	00006517          	auipc	a0,0x6
    80002ed8:	17c50513          	addi	a0,a0,380 # 80009050 <ticks>
    80002edc:	411c                	lw	a5,0(a0)
    80002ede:	2785                	addiw	a5,a5,1
    80002ee0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	a2a080e7          	jalr	-1494(ra) # 8000290c <wakeup>
  release(&tickslock);
    80002eea:	8526                	mv	a0,s1
    80002eec:	ffffe097          	auipc	ra,0xffffe
    80002ef0:	dac080e7          	jalr	-596(ra) # 80000c98 <release>
}
    80002ef4:	60e2                	ld	ra,24(sp)
    80002ef6:	6442                	ld	s0,16(sp)
    80002ef8:	64a2                	ld	s1,8(sp)
    80002efa:	6105                	addi	sp,sp,32
    80002efc:	8082                	ret

0000000080002efe <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002efe:	1101                	addi	sp,sp,-32
    80002f00:	ec06                	sd	ra,24(sp)
    80002f02:	e822                	sd	s0,16(sp)
    80002f04:	e426                	sd	s1,8(sp)
    80002f06:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f08:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002f0c:	00074d63          	bltz	a4,80002f26 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002f10:	57fd                	li	a5,-1
    80002f12:	17fe                	slli	a5,a5,0x3f
    80002f14:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002f16:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002f18:	06f70363          	beq	a4,a5,80002f7e <devintr+0x80>
  }
}
    80002f1c:	60e2                	ld	ra,24(sp)
    80002f1e:	6442                	ld	s0,16(sp)
    80002f20:	64a2                	ld	s1,8(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret
     (scause & 0xff) == 9){
    80002f26:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f2a:	46a5                	li	a3,9
    80002f2c:	fed792e3          	bne	a5,a3,80002f10 <devintr+0x12>
    int irq = plic_claim();
    80002f30:	00003097          	auipc	ra,0x3
    80002f34:	4c8080e7          	jalr	1224(ra) # 800063f8 <plic_claim>
    80002f38:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f3a:	47a9                	li	a5,10
    80002f3c:	02f50763          	beq	a0,a5,80002f6a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002f40:	4785                	li	a5,1
    80002f42:	02f50963          	beq	a0,a5,80002f74 <devintr+0x76>
    return 1;
    80002f46:	4505                	li	a0,1
    } else if(irq){
    80002f48:	d8f1                	beqz	s1,80002f1c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f4a:	85a6                	mv	a1,s1
    80002f4c:	00005517          	auipc	a0,0x5
    80002f50:	46c50513          	addi	a0,a0,1132 # 800083b8 <states.1793+0x38>
    80002f54:	ffffd097          	auipc	ra,0xffffd
    80002f58:	634080e7          	jalr	1588(ra) # 80000588 <printf>
      plic_complete(irq);
    80002f5c:	8526                	mv	a0,s1
    80002f5e:	00003097          	auipc	ra,0x3
    80002f62:	4be080e7          	jalr	1214(ra) # 8000641c <plic_complete>
    return 1;
    80002f66:	4505                	li	a0,1
    80002f68:	bf55                	j	80002f1c <devintr+0x1e>
      uartintr();
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	a3e080e7          	jalr	-1474(ra) # 800009a8 <uartintr>
    80002f72:	b7ed                	j	80002f5c <devintr+0x5e>
      virtio_disk_intr();
    80002f74:	00004097          	auipc	ra,0x4
    80002f78:	988080e7          	jalr	-1656(ra) # 800068fc <virtio_disk_intr>
    80002f7c:	b7c5                	j	80002f5c <devintr+0x5e>
    if(cpuid() == 0){
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	c7c080e7          	jalr	-900(ra) # 80001bfa <cpuid>
    80002f86:	c901                	beqz	a0,80002f96 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002f88:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002f8c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002f8e:	14479073          	csrw	sip,a5
    return 2;
    80002f92:	4509                	li	a0,2
    80002f94:	b761                	j	80002f1c <devintr+0x1e>
      clockintr();
    80002f96:	00000097          	auipc	ra,0x0
    80002f9a:	f22080e7          	jalr	-222(ra) # 80002eb8 <clockintr>
    80002f9e:	b7ed                	j	80002f88 <devintr+0x8a>

0000000080002fa0 <usertrap>:
{
    80002fa0:	1101                	addi	sp,sp,-32
    80002fa2:	ec06                	sd	ra,24(sp)
    80002fa4:	e822                	sd	s0,16(sp)
    80002fa6:	e426                	sd	s1,8(sp)
    80002fa8:	e04a                	sd	s2,0(sp)
    80002faa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fac:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002fb0:	1007f793          	andi	a5,a5,256
    80002fb4:	e3ad                	bnez	a5,80003016 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fb6:	00003797          	auipc	a5,0x3
    80002fba:	33a78793          	addi	a5,a5,826 # 800062f0 <kernelvec>
    80002fbe:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002fc2:	fffff097          	auipc	ra,0xfffff
    80002fc6:	c64080e7          	jalr	-924(ra) # 80001c26 <myproc>
    80002fca:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002fcc:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fce:	14102773          	csrr	a4,sepc
    80002fd2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fd4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002fd8:	47a1                	li	a5,8
    80002fda:	04f71c63          	bne	a4,a5,80003032 <usertrap+0x92>
    if(p->killed)
    80002fde:	551c                	lw	a5,40(a0)
    80002fe0:	e3b9                	bnez	a5,80003026 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002fe2:	7cb8                	ld	a4,120(s1)
    80002fe4:	6f1c                	ld	a5,24(a4)
    80002fe6:	0791                	addi	a5,a5,4
    80002fe8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002fee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ff2:	10079073          	csrw	sstatus,a5
    syscall();
    80002ff6:	00000097          	auipc	ra,0x0
    80002ffa:	2e0080e7          	jalr	736(ra) # 800032d6 <syscall>
  if(p->killed)
    80002ffe:	549c                	lw	a5,40(s1)
    80003000:	ebc1                	bnez	a5,80003090 <usertrap+0xf0>
  usertrapret();
    80003002:	00000097          	auipc	ra,0x0
    80003006:	e18080e7          	jalr	-488(ra) # 80002e1a <usertrapret>
}
    8000300a:	60e2                	ld	ra,24(sp)
    8000300c:	6442                	ld	s0,16(sp)
    8000300e:	64a2                	ld	s1,8(sp)
    80003010:	6902                	ld	s2,0(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret
    panic("usertrap: not from user mode");
    80003016:	00005517          	auipc	a0,0x5
    8000301a:	3c250513          	addi	a0,a0,962 # 800083d8 <states.1793+0x58>
    8000301e:	ffffd097          	auipc	ra,0xffffd
    80003022:	520080e7          	jalr	1312(ra) # 8000053e <panic>
      exit(-1);
    80003026:	557d                	li	a0,-1
    80003028:	00000097          	auipc	ra,0x0
    8000302c:	9b4080e7          	jalr	-1612(ra) # 800029dc <exit>
    80003030:	bf4d                	j	80002fe2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003032:	00000097          	auipc	ra,0x0
    80003036:	ecc080e7          	jalr	-308(ra) # 80002efe <devintr>
    8000303a:	892a                	mv	s2,a0
    8000303c:	c501                	beqz	a0,80003044 <usertrap+0xa4>
  if(p->killed)
    8000303e:	549c                	lw	a5,40(s1)
    80003040:	c3a1                	beqz	a5,80003080 <usertrap+0xe0>
    80003042:	a815                	j	80003076 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003044:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003048:	5890                	lw	a2,48(s1)
    8000304a:	00005517          	auipc	a0,0x5
    8000304e:	3ae50513          	addi	a0,a0,942 # 800083f8 <states.1793+0x78>
    80003052:	ffffd097          	auipc	ra,0xffffd
    80003056:	536080e7          	jalr	1334(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000305a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000305e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003062:	00005517          	auipc	a0,0x5
    80003066:	3c650513          	addi	a0,a0,966 # 80008428 <states.1793+0xa8>
    8000306a:	ffffd097          	auipc	ra,0xffffd
    8000306e:	51e080e7          	jalr	1310(ra) # 80000588 <printf>
    p->killed = 1;
    80003072:	4785                	li	a5,1
    80003074:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003076:	557d                	li	a0,-1
    80003078:	00000097          	auipc	ra,0x0
    8000307c:	964080e7          	jalr	-1692(ra) # 800029dc <exit>
  if(which_dev == 2)
    80003080:	4789                	li	a5,2
    80003082:	f8f910e3          	bne	s2,a5,80003002 <usertrap+0x62>
    yield();
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	61e080e7          	jalr	1566(ra) # 800026a4 <yield>
    8000308e:	bf95                	j	80003002 <usertrap+0x62>
  int which_dev = 0;
    80003090:	4901                	li	s2,0
    80003092:	b7d5                	j	80003076 <usertrap+0xd6>

0000000080003094 <kerneltrap>:
{
    80003094:	7179                	addi	sp,sp,-48
    80003096:	f406                	sd	ra,40(sp)
    80003098:	f022                	sd	s0,32(sp)
    8000309a:	ec26                	sd	s1,24(sp)
    8000309c:	e84a                	sd	s2,16(sp)
    8000309e:	e44e                	sd	s3,8(sp)
    800030a0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030a2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030a6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030aa:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800030ae:	1004f793          	andi	a5,s1,256
    800030b2:	cb85                	beqz	a5,800030e2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030b4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030b8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800030ba:	ef85                	bnez	a5,800030f2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800030bc:	00000097          	auipc	ra,0x0
    800030c0:	e42080e7          	jalr	-446(ra) # 80002efe <devintr>
    800030c4:	cd1d                	beqz	a0,80003102 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030c6:	4789                	li	a5,2
    800030c8:	06f50a63          	beq	a0,a5,8000313c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030cc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030d0:	10049073          	csrw	sstatus,s1
}
    800030d4:	70a2                	ld	ra,40(sp)
    800030d6:	7402                	ld	s0,32(sp)
    800030d8:	64e2                	ld	s1,24(sp)
    800030da:	6942                	ld	s2,16(sp)
    800030dc:	69a2                	ld	s3,8(sp)
    800030de:	6145                	addi	sp,sp,48
    800030e0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030e2:	00005517          	auipc	a0,0x5
    800030e6:	36650513          	addi	a0,a0,870 # 80008448 <states.1793+0xc8>
    800030ea:	ffffd097          	auipc	ra,0xffffd
    800030ee:	454080e7          	jalr	1108(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800030f2:	00005517          	auipc	a0,0x5
    800030f6:	37e50513          	addi	a0,a0,894 # 80008470 <states.1793+0xf0>
    800030fa:	ffffd097          	auipc	ra,0xffffd
    800030fe:	444080e7          	jalr	1092(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003102:	85ce                	mv	a1,s3
    80003104:	00005517          	auipc	a0,0x5
    80003108:	38c50513          	addi	a0,a0,908 # 80008490 <states.1793+0x110>
    8000310c:	ffffd097          	auipc	ra,0xffffd
    80003110:	47c080e7          	jalr	1148(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003114:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003118:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000311c:	00005517          	auipc	a0,0x5
    80003120:	38450513          	addi	a0,a0,900 # 800084a0 <states.1793+0x120>
    80003124:	ffffd097          	auipc	ra,0xffffd
    80003128:	464080e7          	jalr	1124(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000312c:	00005517          	auipc	a0,0x5
    80003130:	38c50513          	addi	a0,a0,908 # 800084b8 <states.1793+0x138>
    80003134:	ffffd097          	auipc	ra,0xffffd
    80003138:	40a080e7          	jalr	1034(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000313c:	fffff097          	auipc	ra,0xfffff
    80003140:	aea080e7          	jalr	-1302(ra) # 80001c26 <myproc>
    80003144:	d541                	beqz	a0,800030cc <kerneltrap+0x38>
    80003146:	fffff097          	auipc	ra,0xfffff
    8000314a:	ae0080e7          	jalr	-1312(ra) # 80001c26 <myproc>
    8000314e:	4d18                	lw	a4,24(a0)
    80003150:	4791                	li	a5,4
    80003152:	f6f71de3          	bne	a4,a5,800030cc <kerneltrap+0x38>
    yield();
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	54e080e7          	jalr	1358(ra) # 800026a4 <yield>
    8000315e:	b7bd                	j	800030cc <kerneltrap+0x38>

0000000080003160 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003160:	1101                	addi	sp,sp,-32
    80003162:	ec06                	sd	ra,24(sp)
    80003164:	e822                	sd	s0,16(sp)
    80003166:	e426                	sd	s1,8(sp)
    80003168:	1000                	addi	s0,sp,32
    8000316a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000316c:	fffff097          	auipc	ra,0xfffff
    80003170:	aba080e7          	jalr	-1350(ra) # 80001c26 <myproc>
  switch (n) {
    80003174:	4795                	li	a5,5
    80003176:	0497e163          	bltu	a5,s1,800031b8 <argraw+0x58>
    8000317a:	048a                	slli	s1,s1,0x2
    8000317c:	00005717          	auipc	a4,0x5
    80003180:	37470713          	addi	a4,a4,884 # 800084f0 <states.1793+0x170>
    80003184:	94ba                	add	s1,s1,a4
    80003186:	409c                	lw	a5,0(s1)
    80003188:	97ba                	add	a5,a5,a4
    8000318a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000318c:	7d3c                	ld	a5,120(a0)
    8000318e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003190:	60e2                	ld	ra,24(sp)
    80003192:	6442                	ld	s0,16(sp)
    80003194:	64a2                	ld	s1,8(sp)
    80003196:	6105                	addi	sp,sp,32
    80003198:	8082                	ret
    return p->trapframe->a1;
    8000319a:	7d3c                	ld	a5,120(a0)
    8000319c:	7fa8                	ld	a0,120(a5)
    8000319e:	bfcd                	j	80003190 <argraw+0x30>
    return p->trapframe->a2;
    800031a0:	7d3c                	ld	a5,120(a0)
    800031a2:	63c8                	ld	a0,128(a5)
    800031a4:	b7f5                	j	80003190 <argraw+0x30>
    return p->trapframe->a3;
    800031a6:	7d3c                	ld	a5,120(a0)
    800031a8:	67c8                	ld	a0,136(a5)
    800031aa:	b7dd                	j	80003190 <argraw+0x30>
    return p->trapframe->a4;
    800031ac:	7d3c                	ld	a5,120(a0)
    800031ae:	6bc8                	ld	a0,144(a5)
    800031b0:	b7c5                	j	80003190 <argraw+0x30>
    return p->trapframe->a5;
    800031b2:	7d3c                	ld	a5,120(a0)
    800031b4:	6fc8                	ld	a0,152(a5)
    800031b6:	bfe9                	j	80003190 <argraw+0x30>
  panic("argraw");
    800031b8:	00005517          	auipc	a0,0x5
    800031bc:	31050513          	addi	a0,a0,784 # 800084c8 <states.1793+0x148>
    800031c0:	ffffd097          	auipc	ra,0xffffd
    800031c4:	37e080e7          	jalr	894(ra) # 8000053e <panic>

00000000800031c8 <fetchaddr>:
{
    800031c8:	1101                	addi	sp,sp,-32
    800031ca:	ec06                	sd	ra,24(sp)
    800031cc:	e822                	sd	s0,16(sp)
    800031ce:	e426                	sd	s1,8(sp)
    800031d0:	e04a                	sd	s2,0(sp)
    800031d2:	1000                	addi	s0,sp,32
    800031d4:	84aa                	mv	s1,a0
    800031d6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031d8:	fffff097          	auipc	ra,0xfffff
    800031dc:	a4e080e7          	jalr	-1458(ra) # 80001c26 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031e0:	753c                	ld	a5,104(a0)
    800031e2:	02f4f863          	bgeu	s1,a5,80003212 <fetchaddr+0x4a>
    800031e6:	00848713          	addi	a4,s1,8
    800031ea:	02e7e663          	bltu	a5,a4,80003216 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031ee:	46a1                	li	a3,8
    800031f0:	8626                	mv	a2,s1
    800031f2:	85ca                	mv	a1,s2
    800031f4:	7928                	ld	a0,112(a0)
    800031f6:	ffffe097          	auipc	ra,0xffffe
    800031fa:	62c080e7          	jalr	1580(ra) # 80001822 <copyin>
    800031fe:	00a03533          	snez	a0,a0
    80003202:	40a00533          	neg	a0,a0
}
    80003206:	60e2                	ld	ra,24(sp)
    80003208:	6442                	ld	s0,16(sp)
    8000320a:	64a2                	ld	s1,8(sp)
    8000320c:	6902                	ld	s2,0(sp)
    8000320e:	6105                	addi	sp,sp,32
    80003210:	8082                	ret
    return -1;
    80003212:	557d                	li	a0,-1
    80003214:	bfcd                	j	80003206 <fetchaddr+0x3e>
    80003216:	557d                	li	a0,-1
    80003218:	b7fd                	j	80003206 <fetchaddr+0x3e>

000000008000321a <fetchstr>:
{
    8000321a:	7179                	addi	sp,sp,-48
    8000321c:	f406                	sd	ra,40(sp)
    8000321e:	f022                	sd	s0,32(sp)
    80003220:	ec26                	sd	s1,24(sp)
    80003222:	e84a                	sd	s2,16(sp)
    80003224:	e44e                	sd	s3,8(sp)
    80003226:	1800                	addi	s0,sp,48
    80003228:	892a                	mv	s2,a0
    8000322a:	84ae                	mv	s1,a1
    8000322c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000322e:	fffff097          	auipc	ra,0xfffff
    80003232:	9f8080e7          	jalr	-1544(ra) # 80001c26 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003236:	86ce                	mv	a3,s3
    80003238:	864a                	mv	a2,s2
    8000323a:	85a6                	mv	a1,s1
    8000323c:	7928                	ld	a0,112(a0)
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	670080e7          	jalr	1648(ra) # 800018ae <copyinstr>
  if(err < 0)
    80003246:	00054763          	bltz	a0,80003254 <fetchstr+0x3a>
  return strlen(buf);
    8000324a:	8526                	mv	a0,s1
    8000324c:	ffffe097          	auipc	ra,0xffffe
    80003250:	c18080e7          	jalr	-1000(ra) # 80000e64 <strlen>
}
    80003254:	70a2                	ld	ra,40(sp)
    80003256:	7402                	ld	s0,32(sp)
    80003258:	64e2                	ld	s1,24(sp)
    8000325a:	6942                	ld	s2,16(sp)
    8000325c:	69a2                	ld	s3,8(sp)
    8000325e:	6145                	addi	sp,sp,48
    80003260:	8082                	ret

0000000080003262 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003262:	1101                	addi	sp,sp,-32
    80003264:	ec06                	sd	ra,24(sp)
    80003266:	e822                	sd	s0,16(sp)
    80003268:	e426                	sd	s1,8(sp)
    8000326a:	1000                	addi	s0,sp,32
    8000326c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	ef2080e7          	jalr	-270(ra) # 80003160 <argraw>
    80003276:	c088                	sw	a0,0(s1)
  return 0;
}
    80003278:	4501                	li	a0,0
    8000327a:	60e2                	ld	ra,24(sp)
    8000327c:	6442                	ld	s0,16(sp)
    8000327e:	64a2                	ld	s1,8(sp)
    80003280:	6105                	addi	sp,sp,32
    80003282:	8082                	ret

0000000080003284 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003284:	1101                	addi	sp,sp,-32
    80003286:	ec06                	sd	ra,24(sp)
    80003288:	e822                	sd	s0,16(sp)
    8000328a:	e426                	sd	s1,8(sp)
    8000328c:	1000                	addi	s0,sp,32
    8000328e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003290:	00000097          	auipc	ra,0x0
    80003294:	ed0080e7          	jalr	-304(ra) # 80003160 <argraw>
    80003298:	e088                	sd	a0,0(s1)
  return 0;
}
    8000329a:	4501                	li	a0,0
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	64a2                	ld	s1,8(sp)
    800032a2:	6105                	addi	sp,sp,32
    800032a4:	8082                	ret

00000000800032a6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800032a6:	1101                	addi	sp,sp,-32
    800032a8:	ec06                	sd	ra,24(sp)
    800032aa:	e822                	sd	s0,16(sp)
    800032ac:	e426                	sd	s1,8(sp)
    800032ae:	e04a                	sd	s2,0(sp)
    800032b0:	1000                	addi	s0,sp,32
    800032b2:	84ae                	mv	s1,a1
    800032b4:	8932                	mv	s2,a2
  *ip = argraw(n);
    800032b6:	00000097          	auipc	ra,0x0
    800032ba:	eaa080e7          	jalr	-342(ra) # 80003160 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032be:	864a                	mv	a2,s2
    800032c0:	85a6                	mv	a1,s1
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	f58080e7          	jalr	-168(ra) # 8000321a <fetchstr>
}
    800032ca:	60e2                	ld	ra,24(sp)
    800032cc:	6442                	ld	s0,16(sp)
    800032ce:	64a2                	ld	s1,8(sp)
    800032d0:	6902                	ld	s2,0(sp)
    800032d2:	6105                	addi	sp,sp,32
    800032d4:	8082                	ret

00000000800032d6 <syscall>:
[SYS_print_stats]   sys_print_stats
};

void
syscall(void)
{
    800032d6:	1101                	addi	sp,sp,-32
    800032d8:	ec06                	sd	ra,24(sp)
    800032da:	e822                	sd	s0,16(sp)
    800032dc:	e426                	sd	s1,8(sp)
    800032de:	e04a                	sd	s2,0(sp)
    800032e0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032e2:	fffff097          	auipc	ra,0xfffff
    800032e6:	944080e7          	jalr	-1724(ra) # 80001c26 <myproc>
    800032ea:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032ec:	07853903          	ld	s2,120(a0)
    800032f0:	0a893783          	ld	a5,168(s2)
    800032f4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032f8:	37fd                	addiw	a5,a5,-1
    800032fa:	475d                	li	a4,23
    800032fc:	00f76f63          	bltu	a4,a5,8000331a <syscall+0x44>
    80003300:	00369713          	slli	a4,a3,0x3
    80003304:	00005797          	auipc	a5,0x5
    80003308:	20478793          	addi	a5,a5,516 # 80008508 <syscalls>
    8000330c:	97ba                	add	a5,a5,a4
    8000330e:	639c                	ld	a5,0(a5)
    80003310:	c789                	beqz	a5,8000331a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003312:	9782                	jalr	a5
    80003314:	06a93823          	sd	a0,112(s2)
    80003318:	a839                	j	80003336 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000331a:	17848613          	addi	a2,s1,376
    8000331e:	588c                	lw	a1,48(s1)
    80003320:	00005517          	auipc	a0,0x5
    80003324:	1b050513          	addi	a0,a0,432 # 800084d0 <states.1793+0x150>
    80003328:	ffffd097          	auipc	ra,0xffffd
    8000332c:	260080e7          	jalr	608(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003330:	7cbc                	ld	a5,120(s1)
    80003332:	577d                	li	a4,-1
    80003334:	fbb8                	sd	a4,112(a5)
  }
}
    80003336:	60e2                	ld	ra,24(sp)
    80003338:	6442                	ld	s0,16(sp)
    8000333a:	64a2                	ld	s1,8(sp)
    8000333c:	6902                	ld	s2,0(sp)
    8000333e:	6105                	addi	sp,sp,32
    80003340:	8082                	ret

0000000080003342 <sys_pause_system>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_pause_system(void)
{
    80003342:	1101                	addi	sp,sp,-32
    80003344:	ec06                	sd	ra,24(sp)
    80003346:	e822                	sd	s0,16(sp)
    80003348:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000334a:	fec40593          	addi	a1,s0,-20
    8000334e:	4501                	li	a0,0
    80003350:	00000097          	auipc	ra,0x0
    80003354:	f12080e7          	jalr	-238(ra) # 80003262 <argint>
    80003358:	87aa                	mv	a5,a0
    return -1;
    8000335a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000335c:	0007c863          	bltz	a5,8000336c <sys_pause_system+0x2a>
  
  return pause_system(n);
    80003360:	fec42503          	lw	a0,-20(s0)
    80003364:	fffff097          	auipc	ra,0xfffff
    80003368:	382080e7          	jalr	898(ra) # 800026e6 <pause_system>
}
    8000336c:	60e2                	ld	ra,24(sp)
    8000336e:	6442                	ld	s0,16(sp)
    80003370:	6105                	addi	sp,sp,32
    80003372:	8082                	ret

0000000080003374 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80003374:	1141                	addi	sp,sp,-16
    80003376:	e406                	sd	ra,8(sp)
    80003378:	e022                	sd	s0,0(sp)
    8000337a:	0800                	addi	s0,sp,16
  return kill_system();
    8000337c:	00000097          	auipc	ra,0x0
    80003380:	830080e7          	jalr	-2000(ra) # 80002bac <kill_system>
}
    80003384:	60a2                	ld	ra,8(sp)
    80003386:	6402                	ld	s0,0(sp)
    80003388:	0141                	addi	sp,sp,16
    8000338a:	8082                	ret

000000008000338c <sys_print_stats>:

uint64
sys_print_stats(void)
{
    8000338c:	1141                	addi	sp,sp,-16
    8000338e:	e406                	sd	ra,8(sp)
    80003390:	e022                	sd	s0,0(sp)
    80003392:	0800                	addi	s0,sp,16
  return print_stats();
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	660080e7          	jalr	1632(ra) # 800019f4 <print_stats>
}
    8000339c:	60a2                	ld	ra,8(sp)
    8000339e:	6402                	ld	s0,0(sp)
    800033a0:	0141                	addi	sp,sp,16
    800033a2:	8082                	ret

00000000800033a4 <sys_exit>:

uint64
sys_exit(void)
{
    800033a4:	1101                	addi	sp,sp,-32
    800033a6:	ec06                	sd	ra,24(sp)
    800033a8:	e822                	sd	s0,16(sp)
    800033aa:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800033ac:	fec40593          	addi	a1,s0,-20
    800033b0:	4501                	li	a0,0
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	eb0080e7          	jalr	-336(ra) # 80003262 <argint>
    return -1;
    800033ba:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033bc:	00054963          	bltz	a0,800033ce <sys_exit+0x2a>
  exit(n);
    800033c0:	fec42503          	lw	a0,-20(s0)
    800033c4:	fffff097          	auipc	ra,0xfffff
    800033c8:	618080e7          	jalr	1560(ra) # 800029dc <exit>
  return 0;  // not reached
    800033cc:	4781                	li	a5,0
}
    800033ce:	853e                	mv	a0,a5
    800033d0:	60e2                	ld	ra,24(sp)
    800033d2:	6442                	ld	s0,16(sp)
    800033d4:	6105                	addi	sp,sp,32
    800033d6:	8082                	ret

00000000800033d8 <sys_getpid>:

uint64
sys_getpid(void)
{
    800033d8:	1141                	addi	sp,sp,-16
    800033da:	e406                	sd	ra,8(sp)
    800033dc:	e022                	sd	s0,0(sp)
    800033de:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033e0:	fffff097          	auipc	ra,0xfffff
    800033e4:	846080e7          	jalr	-1978(ra) # 80001c26 <myproc>
}
    800033e8:	5908                	lw	a0,48(a0)
    800033ea:	60a2                	ld	ra,8(sp)
    800033ec:	6402                	ld	s0,0(sp)
    800033ee:	0141                	addi	sp,sp,16
    800033f0:	8082                	ret

00000000800033f2 <sys_fork>:

uint64
sys_fork(void)
{
    800033f2:	1141                	addi	sp,sp,-16
    800033f4:	e406                	sd	ra,8(sp)
    800033f6:	e022                	sd	s0,0(sp)
    800033f8:	0800                	addi	s0,sp,16
  return fork();
    800033fa:	fffff097          	auipc	ra,0xfffff
    800033fe:	c20080e7          	jalr	-992(ra) # 8000201a <fork>
}
    80003402:	60a2                	ld	ra,8(sp)
    80003404:	6402                	ld	s0,0(sp)
    80003406:	0141                	addi	sp,sp,16
    80003408:	8082                	ret

000000008000340a <sys_wait>:

uint64
sys_wait(void)
{
    8000340a:	1101                	addi	sp,sp,-32
    8000340c:	ec06                	sd	ra,24(sp)
    8000340e:	e822                	sd	s0,16(sp)
    80003410:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003412:	fe840593          	addi	a1,s0,-24
    80003416:	4501                	li	a0,0
    80003418:	00000097          	auipc	ra,0x0
    8000341c:	e6c080e7          	jalr	-404(ra) # 80003284 <argaddr>
    80003420:	87aa                	mv	a5,a0
    return -1;
    80003422:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003424:	0007c863          	bltz	a5,80003434 <sys_wait+0x2a>
  return wait(p);
    80003428:	fe843503          	ld	a0,-24(s0)
    8000342c:	fffff097          	auipc	ra,0xfffff
    80003430:	3b8080e7          	jalr	952(ra) # 800027e4 <wait>
}
    80003434:	60e2                	ld	ra,24(sp)
    80003436:	6442                	ld	s0,16(sp)
    80003438:	6105                	addi	sp,sp,32
    8000343a:	8082                	ret

000000008000343c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000343c:	7179                	addi	sp,sp,-48
    8000343e:	f406                	sd	ra,40(sp)
    80003440:	f022                	sd	s0,32(sp)
    80003442:	ec26                	sd	s1,24(sp)
    80003444:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003446:	fdc40593          	addi	a1,s0,-36
    8000344a:	4501                	li	a0,0
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	e16080e7          	jalr	-490(ra) # 80003262 <argint>
    80003454:	87aa                	mv	a5,a0
    return -1;
    80003456:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003458:	0207c063          	bltz	a5,80003478 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000345c:	ffffe097          	auipc	ra,0xffffe
    80003460:	7ca080e7          	jalr	1994(ra) # 80001c26 <myproc>
    80003464:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003466:	fdc42503          	lw	a0,-36(s0)
    8000346a:	fffff097          	auipc	ra,0xfffff
    8000346e:	b3c080e7          	jalr	-1220(ra) # 80001fa6 <growproc>
    80003472:	00054863          	bltz	a0,80003482 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003476:	8526                	mv	a0,s1
}
    80003478:	70a2                	ld	ra,40(sp)
    8000347a:	7402                	ld	s0,32(sp)
    8000347c:	64e2                	ld	s1,24(sp)
    8000347e:	6145                	addi	sp,sp,48
    80003480:	8082                	ret
    return -1;
    80003482:	557d                	li	a0,-1
    80003484:	bfd5                	j	80003478 <sys_sbrk+0x3c>

0000000080003486 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003486:	7139                	addi	sp,sp,-64
    80003488:	fc06                	sd	ra,56(sp)
    8000348a:	f822                	sd	s0,48(sp)
    8000348c:	f426                	sd	s1,40(sp)
    8000348e:	f04a                	sd	s2,32(sp)
    80003490:	ec4e                	sd	s3,24(sp)
    80003492:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003494:	fcc40593          	addi	a1,s0,-52
    80003498:	4501                	li	a0,0
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	dc8080e7          	jalr	-568(ra) # 80003262 <argint>
    return -1;
    800034a2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800034a4:	06054563          	bltz	a0,8000350e <sys_sleep+0x88>
  acquire(&tickslock);
    800034a8:	00014517          	auipc	a0,0x14
    800034ac:	44850513          	addi	a0,a0,1096 # 800178f0 <tickslock>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	734080e7          	jalr	1844(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800034b8:	00006917          	auipc	s2,0x6
    800034bc:	b9892903          	lw	s2,-1128(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    800034c0:	fcc42783          	lw	a5,-52(s0)
    800034c4:	cf85                	beqz	a5,800034fc <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034c6:	00014997          	auipc	s3,0x14
    800034ca:	42a98993          	addi	s3,s3,1066 # 800178f0 <tickslock>
    800034ce:	00006497          	auipc	s1,0x6
    800034d2:	b8248493          	addi	s1,s1,-1150 # 80009050 <ticks>
    if(myproc()->killed){
    800034d6:	ffffe097          	auipc	ra,0xffffe
    800034da:	750080e7          	jalr	1872(ra) # 80001c26 <myproc>
    800034de:	551c                	lw	a5,40(a0)
    800034e0:	ef9d                	bnez	a5,8000351e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800034e2:	85ce                	mv	a1,s3
    800034e4:	8526                	mv	a0,s1
    800034e6:	fffff097          	auipc	ra,0xfffff
    800034ea:	290080e7          	jalr	656(ra) # 80002776 <sleep>
  while(ticks - ticks0 < n){
    800034ee:	409c                	lw	a5,0(s1)
    800034f0:	412787bb          	subw	a5,a5,s2
    800034f4:	fcc42703          	lw	a4,-52(s0)
    800034f8:	fce7efe3          	bltu	a5,a4,800034d6 <sys_sleep+0x50>
  }
  release(&tickslock);
    800034fc:	00014517          	auipc	a0,0x14
    80003500:	3f450513          	addi	a0,a0,1012 # 800178f0 <tickslock>
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	794080e7          	jalr	1940(ra) # 80000c98 <release>
  return 0;
    8000350c:	4781                	li	a5,0
}
    8000350e:	853e                	mv	a0,a5
    80003510:	70e2                	ld	ra,56(sp)
    80003512:	7442                	ld	s0,48(sp)
    80003514:	74a2                	ld	s1,40(sp)
    80003516:	7902                	ld	s2,32(sp)
    80003518:	69e2                	ld	s3,24(sp)
    8000351a:	6121                	addi	sp,sp,64
    8000351c:	8082                	ret
      release(&tickslock);
    8000351e:	00014517          	auipc	a0,0x14
    80003522:	3d250513          	addi	a0,a0,978 # 800178f0 <tickslock>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	772080e7          	jalr	1906(ra) # 80000c98 <release>
      return -1;
    8000352e:	57fd                	li	a5,-1
    80003530:	bff9                	j	8000350e <sys_sleep+0x88>

0000000080003532 <sys_kill>:

uint64
sys_kill(void)
{
    80003532:	1101                	addi	sp,sp,-32
    80003534:	ec06                	sd	ra,24(sp)
    80003536:	e822                	sd	s0,16(sp)
    80003538:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000353a:	fec40593          	addi	a1,s0,-20
    8000353e:	4501                	li	a0,0
    80003540:	00000097          	auipc	ra,0x0
    80003544:	d22080e7          	jalr	-734(ra) # 80003262 <argint>
    80003548:	87aa                	mv	a5,a0
    return -1;
    8000354a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000354c:	0007c863          	bltz	a5,8000355c <sys_kill+0x2a>
  return kill(pid);
    80003550:	fec42503          	lw	a0,-20(s0)
    80003554:	fffff097          	auipc	ra,0xfffff
    80003558:	5e0080e7          	jalr	1504(ra) # 80002b34 <kill>
}
    8000355c:	60e2                	ld	ra,24(sp)
    8000355e:	6442                	ld	s0,16(sp)
    80003560:	6105                	addi	sp,sp,32
    80003562:	8082                	ret

0000000080003564 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003564:	1101                	addi	sp,sp,-32
    80003566:	ec06                	sd	ra,24(sp)
    80003568:	e822                	sd	s0,16(sp)
    8000356a:	e426                	sd	s1,8(sp)
    8000356c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000356e:	00014517          	auipc	a0,0x14
    80003572:	38250513          	addi	a0,a0,898 # 800178f0 <tickslock>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	66e080e7          	jalr	1646(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000357e:	00006497          	auipc	s1,0x6
    80003582:	ad24a483          	lw	s1,-1326(s1) # 80009050 <ticks>
  release(&tickslock);
    80003586:	00014517          	auipc	a0,0x14
    8000358a:	36a50513          	addi	a0,a0,874 # 800178f0 <tickslock>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	70a080e7          	jalr	1802(ra) # 80000c98 <release>
  return xticks;
}
    80003596:	02049513          	slli	a0,s1,0x20
    8000359a:	9101                	srli	a0,a0,0x20
    8000359c:	60e2                	ld	ra,24(sp)
    8000359e:	6442                	ld	s0,16(sp)
    800035a0:	64a2                	ld	s1,8(sp)
    800035a2:	6105                	addi	sp,sp,32
    800035a4:	8082                	ret

00000000800035a6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035a6:	7179                	addi	sp,sp,-48
    800035a8:	f406                	sd	ra,40(sp)
    800035aa:	f022                	sd	s0,32(sp)
    800035ac:	ec26                	sd	s1,24(sp)
    800035ae:	e84a                	sd	s2,16(sp)
    800035b0:	e44e                	sd	s3,8(sp)
    800035b2:	e052                	sd	s4,0(sp)
    800035b4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800035b6:	00005597          	auipc	a1,0x5
    800035ba:	01a58593          	addi	a1,a1,26 # 800085d0 <syscalls+0xc8>
    800035be:	00014517          	auipc	a0,0x14
    800035c2:	34a50513          	addi	a0,a0,842 # 80017908 <bcache>
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	58e080e7          	jalr	1422(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035ce:	0001c797          	auipc	a5,0x1c
    800035d2:	33a78793          	addi	a5,a5,826 # 8001f908 <bcache+0x8000>
    800035d6:	0001c717          	auipc	a4,0x1c
    800035da:	59a70713          	addi	a4,a4,1434 # 8001fb70 <bcache+0x8268>
    800035de:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035e2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035e6:	00014497          	auipc	s1,0x14
    800035ea:	33a48493          	addi	s1,s1,826 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    800035ee:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035f0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035f2:	00005a17          	auipc	s4,0x5
    800035f6:	fe6a0a13          	addi	s4,s4,-26 # 800085d8 <syscalls+0xd0>
    b->next = bcache.head.next;
    800035fa:	2b893783          	ld	a5,696(s2)
    800035fe:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003600:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003604:	85d2                	mv	a1,s4
    80003606:	01048513          	addi	a0,s1,16
    8000360a:	00001097          	auipc	ra,0x1
    8000360e:	4bc080e7          	jalr	1212(ra) # 80004ac6 <initsleeplock>
    bcache.head.next->prev = b;
    80003612:	2b893783          	ld	a5,696(s2)
    80003616:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003618:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000361c:	45848493          	addi	s1,s1,1112
    80003620:	fd349de3          	bne	s1,s3,800035fa <binit+0x54>
  }
}
    80003624:	70a2                	ld	ra,40(sp)
    80003626:	7402                	ld	s0,32(sp)
    80003628:	64e2                	ld	s1,24(sp)
    8000362a:	6942                	ld	s2,16(sp)
    8000362c:	69a2                	ld	s3,8(sp)
    8000362e:	6a02                	ld	s4,0(sp)
    80003630:	6145                	addi	sp,sp,48
    80003632:	8082                	ret

0000000080003634 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003634:	7179                	addi	sp,sp,-48
    80003636:	f406                	sd	ra,40(sp)
    80003638:	f022                	sd	s0,32(sp)
    8000363a:	ec26                	sd	s1,24(sp)
    8000363c:	e84a                	sd	s2,16(sp)
    8000363e:	e44e                	sd	s3,8(sp)
    80003640:	1800                	addi	s0,sp,48
    80003642:	89aa                	mv	s3,a0
    80003644:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003646:	00014517          	auipc	a0,0x14
    8000364a:	2c250513          	addi	a0,a0,706 # 80017908 <bcache>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	596080e7          	jalr	1430(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003656:	0001c497          	auipc	s1,0x1c
    8000365a:	56a4b483          	ld	s1,1386(s1) # 8001fbc0 <bcache+0x82b8>
    8000365e:	0001c797          	auipc	a5,0x1c
    80003662:	51278793          	addi	a5,a5,1298 # 8001fb70 <bcache+0x8268>
    80003666:	02f48f63          	beq	s1,a5,800036a4 <bread+0x70>
    8000366a:	873e                	mv	a4,a5
    8000366c:	a021                	j	80003674 <bread+0x40>
    8000366e:	68a4                	ld	s1,80(s1)
    80003670:	02e48a63          	beq	s1,a4,800036a4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003674:	449c                	lw	a5,8(s1)
    80003676:	ff379ce3          	bne	a5,s3,8000366e <bread+0x3a>
    8000367a:	44dc                	lw	a5,12(s1)
    8000367c:	ff2799e3          	bne	a5,s2,8000366e <bread+0x3a>
      b->refcnt++;
    80003680:	40bc                	lw	a5,64(s1)
    80003682:	2785                	addiw	a5,a5,1
    80003684:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003686:	00014517          	auipc	a0,0x14
    8000368a:	28250513          	addi	a0,a0,642 # 80017908 <bcache>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	60a080e7          	jalr	1546(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003696:	01048513          	addi	a0,s1,16
    8000369a:	00001097          	auipc	ra,0x1
    8000369e:	466080e7          	jalr	1126(ra) # 80004b00 <acquiresleep>
      return b;
    800036a2:	a8b9                	j	80003700 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036a4:	0001c497          	auipc	s1,0x1c
    800036a8:	5144b483          	ld	s1,1300(s1) # 8001fbb8 <bcache+0x82b0>
    800036ac:	0001c797          	auipc	a5,0x1c
    800036b0:	4c478793          	addi	a5,a5,1220 # 8001fb70 <bcache+0x8268>
    800036b4:	00f48863          	beq	s1,a5,800036c4 <bread+0x90>
    800036b8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036ba:	40bc                	lw	a5,64(s1)
    800036bc:	cf81                	beqz	a5,800036d4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036be:	64a4                	ld	s1,72(s1)
    800036c0:	fee49de3          	bne	s1,a4,800036ba <bread+0x86>
  panic("bget: no buffers");
    800036c4:	00005517          	auipc	a0,0x5
    800036c8:	f1c50513          	addi	a0,a0,-228 # 800085e0 <syscalls+0xd8>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	e72080e7          	jalr	-398(ra) # 8000053e <panic>
      b->dev = dev;
    800036d4:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800036d8:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800036dc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036e0:	4785                	li	a5,1
    800036e2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036e4:	00014517          	auipc	a0,0x14
    800036e8:	22450513          	addi	a0,a0,548 # 80017908 <bcache>
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	5ac080e7          	jalr	1452(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800036f4:	01048513          	addi	a0,s1,16
    800036f8:	00001097          	auipc	ra,0x1
    800036fc:	408080e7          	jalr	1032(ra) # 80004b00 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003700:	409c                	lw	a5,0(s1)
    80003702:	cb89                	beqz	a5,80003714 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003704:	8526                	mv	a0,s1
    80003706:	70a2                	ld	ra,40(sp)
    80003708:	7402                	ld	s0,32(sp)
    8000370a:	64e2                	ld	s1,24(sp)
    8000370c:	6942                	ld	s2,16(sp)
    8000370e:	69a2                	ld	s3,8(sp)
    80003710:	6145                	addi	sp,sp,48
    80003712:	8082                	ret
    virtio_disk_rw(b, 0);
    80003714:	4581                	li	a1,0
    80003716:	8526                	mv	a0,s1
    80003718:	00003097          	auipc	ra,0x3
    8000371c:	f0e080e7          	jalr	-242(ra) # 80006626 <virtio_disk_rw>
    b->valid = 1;
    80003720:	4785                	li	a5,1
    80003722:	c09c                	sw	a5,0(s1)
  return b;
    80003724:	b7c5                	j	80003704 <bread+0xd0>

0000000080003726 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003726:	1101                	addi	sp,sp,-32
    80003728:	ec06                	sd	ra,24(sp)
    8000372a:	e822                	sd	s0,16(sp)
    8000372c:	e426                	sd	s1,8(sp)
    8000372e:	1000                	addi	s0,sp,32
    80003730:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003732:	0541                	addi	a0,a0,16
    80003734:	00001097          	auipc	ra,0x1
    80003738:	466080e7          	jalr	1126(ra) # 80004b9a <holdingsleep>
    8000373c:	cd01                	beqz	a0,80003754 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000373e:	4585                	li	a1,1
    80003740:	8526                	mv	a0,s1
    80003742:	00003097          	auipc	ra,0x3
    80003746:	ee4080e7          	jalr	-284(ra) # 80006626 <virtio_disk_rw>
}
    8000374a:	60e2                	ld	ra,24(sp)
    8000374c:	6442                	ld	s0,16(sp)
    8000374e:	64a2                	ld	s1,8(sp)
    80003750:	6105                	addi	sp,sp,32
    80003752:	8082                	ret
    panic("bwrite");
    80003754:	00005517          	auipc	a0,0x5
    80003758:	ea450513          	addi	a0,a0,-348 # 800085f8 <syscalls+0xf0>
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	de2080e7          	jalr	-542(ra) # 8000053e <panic>

0000000080003764 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003764:	1101                	addi	sp,sp,-32
    80003766:	ec06                	sd	ra,24(sp)
    80003768:	e822                	sd	s0,16(sp)
    8000376a:	e426                	sd	s1,8(sp)
    8000376c:	e04a                	sd	s2,0(sp)
    8000376e:	1000                	addi	s0,sp,32
    80003770:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003772:	01050913          	addi	s2,a0,16
    80003776:	854a                	mv	a0,s2
    80003778:	00001097          	auipc	ra,0x1
    8000377c:	422080e7          	jalr	1058(ra) # 80004b9a <holdingsleep>
    80003780:	c92d                	beqz	a0,800037f2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003782:	854a                	mv	a0,s2
    80003784:	00001097          	auipc	ra,0x1
    80003788:	3d2080e7          	jalr	978(ra) # 80004b56 <releasesleep>

  acquire(&bcache.lock);
    8000378c:	00014517          	auipc	a0,0x14
    80003790:	17c50513          	addi	a0,a0,380 # 80017908 <bcache>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	450080e7          	jalr	1104(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000379c:	40bc                	lw	a5,64(s1)
    8000379e:	37fd                	addiw	a5,a5,-1
    800037a0:	0007871b          	sext.w	a4,a5
    800037a4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037a6:	eb05                	bnez	a4,800037d6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037a8:	68bc                	ld	a5,80(s1)
    800037aa:	64b8                	ld	a4,72(s1)
    800037ac:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800037ae:	64bc                	ld	a5,72(s1)
    800037b0:	68b8                	ld	a4,80(s1)
    800037b2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037b4:	0001c797          	auipc	a5,0x1c
    800037b8:	15478793          	addi	a5,a5,340 # 8001f908 <bcache+0x8000>
    800037bc:	2b87b703          	ld	a4,696(a5)
    800037c0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037c2:	0001c717          	auipc	a4,0x1c
    800037c6:	3ae70713          	addi	a4,a4,942 # 8001fb70 <bcache+0x8268>
    800037ca:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037cc:	2b87b703          	ld	a4,696(a5)
    800037d0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037d2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037d6:	00014517          	auipc	a0,0x14
    800037da:	13250513          	addi	a0,a0,306 # 80017908 <bcache>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	4ba080e7          	jalr	1210(ra) # 80000c98 <release>
}
    800037e6:	60e2                	ld	ra,24(sp)
    800037e8:	6442                	ld	s0,16(sp)
    800037ea:	64a2                	ld	s1,8(sp)
    800037ec:	6902                	ld	s2,0(sp)
    800037ee:	6105                	addi	sp,sp,32
    800037f0:	8082                	ret
    panic("brelse");
    800037f2:	00005517          	auipc	a0,0x5
    800037f6:	e0e50513          	addi	a0,a0,-498 # 80008600 <syscalls+0xf8>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	d44080e7          	jalr	-700(ra) # 8000053e <panic>

0000000080003802 <bpin>:

void
bpin(struct buf *b) {
    80003802:	1101                	addi	sp,sp,-32
    80003804:	ec06                	sd	ra,24(sp)
    80003806:	e822                	sd	s0,16(sp)
    80003808:	e426                	sd	s1,8(sp)
    8000380a:	1000                	addi	s0,sp,32
    8000380c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000380e:	00014517          	auipc	a0,0x14
    80003812:	0fa50513          	addi	a0,a0,250 # 80017908 <bcache>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	3ce080e7          	jalr	974(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000381e:	40bc                	lw	a5,64(s1)
    80003820:	2785                	addiw	a5,a5,1
    80003822:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003824:	00014517          	auipc	a0,0x14
    80003828:	0e450513          	addi	a0,a0,228 # 80017908 <bcache>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	46c080e7          	jalr	1132(ra) # 80000c98 <release>
}
    80003834:	60e2                	ld	ra,24(sp)
    80003836:	6442                	ld	s0,16(sp)
    80003838:	64a2                	ld	s1,8(sp)
    8000383a:	6105                	addi	sp,sp,32
    8000383c:	8082                	ret

000000008000383e <bunpin>:

void
bunpin(struct buf *b) {
    8000383e:	1101                	addi	sp,sp,-32
    80003840:	ec06                	sd	ra,24(sp)
    80003842:	e822                	sd	s0,16(sp)
    80003844:	e426                	sd	s1,8(sp)
    80003846:	1000                	addi	s0,sp,32
    80003848:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000384a:	00014517          	auipc	a0,0x14
    8000384e:	0be50513          	addi	a0,a0,190 # 80017908 <bcache>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	392080e7          	jalr	914(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000385a:	40bc                	lw	a5,64(s1)
    8000385c:	37fd                	addiw	a5,a5,-1
    8000385e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003860:	00014517          	auipc	a0,0x14
    80003864:	0a850513          	addi	a0,a0,168 # 80017908 <bcache>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	430080e7          	jalr	1072(ra) # 80000c98 <release>
}
    80003870:	60e2                	ld	ra,24(sp)
    80003872:	6442                	ld	s0,16(sp)
    80003874:	64a2                	ld	s1,8(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret

000000008000387a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000387a:	1101                	addi	sp,sp,-32
    8000387c:	ec06                	sd	ra,24(sp)
    8000387e:	e822                	sd	s0,16(sp)
    80003880:	e426                	sd	s1,8(sp)
    80003882:	e04a                	sd	s2,0(sp)
    80003884:	1000                	addi	s0,sp,32
    80003886:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003888:	00d5d59b          	srliw	a1,a1,0xd
    8000388c:	0001c797          	auipc	a5,0x1c
    80003890:	7587a783          	lw	a5,1880(a5) # 8001ffe4 <sb+0x1c>
    80003894:	9dbd                	addw	a1,a1,a5
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	d9e080e7          	jalr	-610(ra) # 80003634 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000389e:	0074f713          	andi	a4,s1,7
    800038a2:	4785                	li	a5,1
    800038a4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800038a8:	14ce                	slli	s1,s1,0x33
    800038aa:	90d9                	srli	s1,s1,0x36
    800038ac:	00950733          	add	a4,a0,s1
    800038b0:	05874703          	lbu	a4,88(a4)
    800038b4:	00e7f6b3          	and	a3,a5,a4
    800038b8:	c69d                	beqz	a3,800038e6 <bfree+0x6c>
    800038ba:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038bc:	94aa                	add	s1,s1,a0
    800038be:	fff7c793          	not	a5,a5
    800038c2:	8ff9                	and	a5,a5,a4
    800038c4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800038c8:	00001097          	auipc	ra,0x1
    800038cc:	118080e7          	jalr	280(ra) # 800049e0 <log_write>
  brelse(bp);
    800038d0:	854a                	mv	a0,s2
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	e92080e7          	jalr	-366(ra) # 80003764 <brelse>
}
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6902                	ld	s2,0(sp)
    800038e2:	6105                	addi	sp,sp,32
    800038e4:	8082                	ret
    panic("freeing free block");
    800038e6:	00005517          	auipc	a0,0x5
    800038ea:	d2250513          	addi	a0,a0,-734 # 80008608 <syscalls+0x100>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	c50080e7          	jalr	-944(ra) # 8000053e <panic>

00000000800038f6 <balloc>:
{
    800038f6:	711d                	addi	sp,sp,-96
    800038f8:	ec86                	sd	ra,88(sp)
    800038fa:	e8a2                	sd	s0,80(sp)
    800038fc:	e4a6                	sd	s1,72(sp)
    800038fe:	e0ca                	sd	s2,64(sp)
    80003900:	fc4e                	sd	s3,56(sp)
    80003902:	f852                	sd	s4,48(sp)
    80003904:	f456                	sd	s5,40(sp)
    80003906:	f05a                	sd	s6,32(sp)
    80003908:	ec5e                	sd	s7,24(sp)
    8000390a:	e862                	sd	s8,16(sp)
    8000390c:	e466                	sd	s9,8(sp)
    8000390e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003910:	0001c797          	auipc	a5,0x1c
    80003914:	6bc7a783          	lw	a5,1724(a5) # 8001ffcc <sb+0x4>
    80003918:	cbd1                	beqz	a5,800039ac <balloc+0xb6>
    8000391a:	8baa                	mv	s7,a0
    8000391c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000391e:	0001cb17          	auipc	s6,0x1c
    80003922:	6aab0b13          	addi	s6,s6,1706 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003926:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003928:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000392a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000392c:	6c89                	lui	s9,0x2
    8000392e:	a831                	j	8000394a <balloc+0x54>
    brelse(bp);
    80003930:	854a                	mv	a0,s2
    80003932:	00000097          	auipc	ra,0x0
    80003936:	e32080e7          	jalr	-462(ra) # 80003764 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000393a:	015c87bb          	addw	a5,s9,s5
    8000393e:	00078a9b          	sext.w	s5,a5
    80003942:	004b2703          	lw	a4,4(s6)
    80003946:	06eaf363          	bgeu	s5,a4,800039ac <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000394a:	41fad79b          	sraiw	a5,s5,0x1f
    8000394e:	0137d79b          	srliw	a5,a5,0x13
    80003952:	015787bb          	addw	a5,a5,s5
    80003956:	40d7d79b          	sraiw	a5,a5,0xd
    8000395a:	01cb2583          	lw	a1,28(s6)
    8000395e:	9dbd                	addw	a1,a1,a5
    80003960:	855e                	mv	a0,s7
    80003962:	00000097          	auipc	ra,0x0
    80003966:	cd2080e7          	jalr	-814(ra) # 80003634 <bread>
    8000396a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000396c:	004b2503          	lw	a0,4(s6)
    80003970:	000a849b          	sext.w	s1,s5
    80003974:	8662                	mv	a2,s8
    80003976:	faa4fde3          	bgeu	s1,a0,80003930 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000397a:	41f6579b          	sraiw	a5,a2,0x1f
    8000397e:	01d7d69b          	srliw	a3,a5,0x1d
    80003982:	00c6873b          	addw	a4,a3,a2
    80003986:	00777793          	andi	a5,a4,7
    8000398a:	9f95                	subw	a5,a5,a3
    8000398c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003990:	4037571b          	sraiw	a4,a4,0x3
    80003994:	00e906b3          	add	a3,s2,a4
    80003998:	0586c683          	lbu	a3,88(a3)
    8000399c:	00d7f5b3          	and	a1,a5,a3
    800039a0:	cd91                	beqz	a1,800039bc <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039a2:	2605                	addiw	a2,a2,1
    800039a4:	2485                	addiw	s1,s1,1
    800039a6:	fd4618e3          	bne	a2,s4,80003976 <balloc+0x80>
    800039aa:	b759                	j	80003930 <balloc+0x3a>
  panic("balloc: out of blocks");
    800039ac:	00005517          	auipc	a0,0x5
    800039b0:	c7450513          	addi	a0,a0,-908 # 80008620 <syscalls+0x118>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	b8a080e7          	jalr	-1142(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039bc:	974a                	add	a4,a4,s2
    800039be:	8fd5                	or	a5,a5,a3
    800039c0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800039c4:	854a                	mv	a0,s2
    800039c6:	00001097          	auipc	ra,0x1
    800039ca:	01a080e7          	jalr	26(ra) # 800049e0 <log_write>
        brelse(bp);
    800039ce:	854a                	mv	a0,s2
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	d94080e7          	jalr	-620(ra) # 80003764 <brelse>
  bp = bread(dev, bno);
    800039d8:	85a6                	mv	a1,s1
    800039da:	855e                	mv	a0,s7
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	c58080e7          	jalr	-936(ra) # 80003634 <bread>
    800039e4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039e6:	40000613          	li	a2,1024
    800039ea:	4581                	li	a1,0
    800039ec:	05850513          	addi	a0,a0,88
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	2f0080e7          	jalr	752(ra) # 80000ce0 <memset>
  log_write(bp);
    800039f8:	854a                	mv	a0,s2
    800039fa:	00001097          	auipc	ra,0x1
    800039fe:	fe6080e7          	jalr	-26(ra) # 800049e0 <log_write>
  brelse(bp);
    80003a02:	854a                	mv	a0,s2
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	d60080e7          	jalr	-672(ra) # 80003764 <brelse>
}
    80003a0c:	8526                	mv	a0,s1
    80003a0e:	60e6                	ld	ra,88(sp)
    80003a10:	6446                	ld	s0,80(sp)
    80003a12:	64a6                	ld	s1,72(sp)
    80003a14:	6906                	ld	s2,64(sp)
    80003a16:	79e2                	ld	s3,56(sp)
    80003a18:	7a42                	ld	s4,48(sp)
    80003a1a:	7aa2                	ld	s5,40(sp)
    80003a1c:	7b02                	ld	s6,32(sp)
    80003a1e:	6be2                	ld	s7,24(sp)
    80003a20:	6c42                	ld	s8,16(sp)
    80003a22:	6ca2                	ld	s9,8(sp)
    80003a24:	6125                	addi	sp,sp,96
    80003a26:	8082                	ret

0000000080003a28 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a28:	7179                	addi	sp,sp,-48
    80003a2a:	f406                	sd	ra,40(sp)
    80003a2c:	f022                	sd	s0,32(sp)
    80003a2e:	ec26                	sd	s1,24(sp)
    80003a30:	e84a                	sd	s2,16(sp)
    80003a32:	e44e                	sd	s3,8(sp)
    80003a34:	e052                	sd	s4,0(sp)
    80003a36:	1800                	addi	s0,sp,48
    80003a38:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a3a:	47ad                	li	a5,11
    80003a3c:	04b7fe63          	bgeu	a5,a1,80003a98 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a40:	ff45849b          	addiw	s1,a1,-12
    80003a44:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a48:	0ff00793          	li	a5,255
    80003a4c:	0ae7e363          	bltu	a5,a4,80003af2 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a50:	08052583          	lw	a1,128(a0)
    80003a54:	c5ad                	beqz	a1,80003abe <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a56:	00092503          	lw	a0,0(s2)
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	bda080e7          	jalr	-1062(ra) # 80003634 <bread>
    80003a62:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a64:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a68:	02049593          	slli	a1,s1,0x20
    80003a6c:	9181                	srli	a1,a1,0x20
    80003a6e:	058a                	slli	a1,a1,0x2
    80003a70:	00b784b3          	add	s1,a5,a1
    80003a74:	0004a983          	lw	s3,0(s1)
    80003a78:	04098d63          	beqz	s3,80003ad2 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a7c:	8552                	mv	a0,s4
    80003a7e:	00000097          	auipc	ra,0x0
    80003a82:	ce6080e7          	jalr	-794(ra) # 80003764 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a86:	854e                	mv	a0,s3
    80003a88:	70a2                	ld	ra,40(sp)
    80003a8a:	7402                	ld	s0,32(sp)
    80003a8c:	64e2                	ld	s1,24(sp)
    80003a8e:	6942                	ld	s2,16(sp)
    80003a90:	69a2                	ld	s3,8(sp)
    80003a92:	6a02                	ld	s4,0(sp)
    80003a94:	6145                	addi	sp,sp,48
    80003a96:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a98:	02059493          	slli	s1,a1,0x20
    80003a9c:	9081                	srli	s1,s1,0x20
    80003a9e:	048a                	slli	s1,s1,0x2
    80003aa0:	94aa                	add	s1,s1,a0
    80003aa2:	0504a983          	lw	s3,80(s1)
    80003aa6:	fe0990e3          	bnez	s3,80003a86 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003aaa:	4108                	lw	a0,0(a0)
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	e4a080e7          	jalr	-438(ra) # 800038f6 <balloc>
    80003ab4:	0005099b          	sext.w	s3,a0
    80003ab8:	0534a823          	sw	s3,80(s1)
    80003abc:	b7e9                	j	80003a86 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003abe:	4108                	lw	a0,0(a0)
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	e36080e7          	jalr	-458(ra) # 800038f6 <balloc>
    80003ac8:	0005059b          	sext.w	a1,a0
    80003acc:	08b92023          	sw	a1,128(s2)
    80003ad0:	b759                	j	80003a56 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003ad2:	00092503          	lw	a0,0(s2)
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	e20080e7          	jalr	-480(ra) # 800038f6 <balloc>
    80003ade:	0005099b          	sext.w	s3,a0
    80003ae2:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003ae6:	8552                	mv	a0,s4
    80003ae8:	00001097          	auipc	ra,0x1
    80003aec:	ef8080e7          	jalr	-264(ra) # 800049e0 <log_write>
    80003af0:	b771                	j	80003a7c <bmap+0x54>
  panic("bmap: out of range");
    80003af2:	00005517          	auipc	a0,0x5
    80003af6:	b4650513          	addi	a0,a0,-1210 # 80008638 <syscalls+0x130>
    80003afa:	ffffd097          	auipc	ra,0xffffd
    80003afe:	a44080e7          	jalr	-1468(ra) # 8000053e <panic>

0000000080003b02 <iget>:
{
    80003b02:	7179                	addi	sp,sp,-48
    80003b04:	f406                	sd	ra,40(sp)
    80003b06:	f022                	sd	s0,32(sp)
    80003b08:	ec26                	sd	s1,24(sp)
    80003b0a:	e84a                	sd	s2,16(sp)
    80003b0c:	e44e                	sd	s3,8(sp)
    80003b0e:	e052                	sd	s4,0(sp)
    80003b10:	1800                	addi	s0,sp,48
    80003b12:	89aa                	mv	s3,a0
    80003b14:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b16:	0001c517          	auipc	a0,0x1c
    80003b1a:	4d250513          	addi	a0,a0,1234 # 8001ffe8 <itable>
    80003b1e:	ffffd097          	auipc	ra,0xffffd
    80003b22:	0c6080e7          	jalr	198(ra) # 80000be4 <acquire>
  empty = 0;
    80003b26:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b28:	0001c497          	auipc	s1,0x1c
    80003b2c:	4d848493          	addi	s1,s1,1240 # 80020000 <itable+0x18>
    80003b30:	0001e697          	auipc	a3,0x1e
    80003b34:	f6068693          	addi	a3,a3,-160 # 80021a90 <log>
    80003b38:	a039                	j	80003b46 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b3a:	02090b63          	beqz	s2,80003b70 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b3e:	08848493          	addi	s1,s1,136
    80003b42:	02d48a63          	beq	s1,a3,80003b76 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b46:	449c                	lw	a5,8(s1)
    80003b48:	fef059e3          	blez	a5,80003b3a <iget+0x38>
    80003b4c:	4098                	lw	a4,0(s1)
    80003b4e:	ff3716e3          	bne	a4,s3,80003b3a <iget+0x38>
    80003b52:	40d8                	lw	a4,4(s1)
    80003b54:	ff4713e3          	bne	a4,s4,80003b3a <iget+0x38>
      ip->ref++;
    80003b58:	2785                	addiw	a5,a5,1
    80003b5a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b5c:	0001c517          	auipc	a0,0x1c
    80003b60:	48c50513          	addi	a0,a0,1164 # 8001ffe8 <itable>
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	134080e7          	jalr	308(ra) # 80000c98 <release>
      return ip;
    80003b6c:	8926                	mv	s2,s1
    80003b6e:	a03d                	j	80003b9c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b70:	f7f9                	bnez	a5,80003b3e <iget+0x3c>
    80003b72:	8926                	mv	s2,s1
    80003b74:	b7e9                	j	80003b3e <iget+0x3c>
  if(empty == 0)
    80003b76:	02090c63          	beqz	s2,80003bae <iget+0xac>
  ip->dev = dev;
    80003b7a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b7e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b82:	4785                	li	a5,1
    80003b84:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b88:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b8c:	0001c517          	auipc	a0,0x1c
    80003b90:	45c50513          	addi	a0,a0,1116 # 8001ffe8 <itable>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	104080e7          	jalr	260(ra) # 80000c98 <release>
}
    80003b9c:	854a                	mv	a0,s2
    80003b9e:	70a2                	ld	ra,40(sp)
    80003ba0:	7402                	ld	s0,32(sp)
    80003ba2:	64e2                	ld	s1,24(sp)
    80003ba4:	6942                	ld	s2,16(sp)
    80003ba6:	69a2                	ld	s3,8(sp)
    80003ba8:	6a02                	ld	s4,0(sp)
    80003baa:	6145                	addi	sp,sp,48
    80003bac:	8082                	ret
    panic("iget: no inodes");
    80003bae:	00005517          	auipc	a0,0x5
    80003bb2:	aa250513          	addi	a0,a0,-1374 # 80008650 <syscalls+0x148>
    80003bb6:	ffffd097          	auipc	ra,0xffffd
    80003bba:	988080e7          	jalr	-1656(ra) # 8000053e <panic>

0000000080003bbe <fsinit>:
fsinit(int dev) {
    80003bbe:	7179                	addi	sp,sp,-48
    80003bc0:	f406                	sd	ra,40(sp)
    80003bc2:	f022                	sd	s0,32(sp)
    80003bc4:	ec26                	sd	s1,24(sp)
    80003bc6:	e84a                	sd	s2,16(sp)
    80003bc8:	e44e                	sd	s3,8(sp)
    80003bca:	1800                	addi	s0,sp,48
    80003bcc:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bce:	4585                	li	a1,1
    80003bd0:	00000097          	auipc	ra,0x0
    80003bd4:	a64080e7          	jalr	-1436(ra) # 80003634 <bread>
    80003bd8:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bda:	0001c997          	auipc	s3,0x1c
    80003bde:	3ee98993          	addi	s3,s3,1006 # 8001ffc8 <sb>
    80003be2:	02000613          	li	a2,32
    80003be6:	05850593          	addi	a1,a0,88
    80003bea:	854e                	mv	a0,s3
    80003bec:	ffffd097          	auipc	ra,0xffffd
    80003bf0:	154080e7          	jalr	340(ra) # 80000d40 <memmove>
  brelse(bp);
    80003bf4:	8526                	mv	a0,s1
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	b6e080e7          	jalr	-1170(ra) # 80003764 <brelse>
  if(sb.magic != FSMAGIC)
    80003bfe:	0009a703          	lw	a4,0(s3)
    80003c02:	102037b7          	lui	a5,0x10203
    80003c06:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c0a:	02f71263          	bne	a4,a5,80003c2e <fsinit+0x70>
  initlog(dev, &sb);
    80003c0e:	0001c597          	auipc	a1,0x1c
    80003c12:	3ba58593          	addi	a1,a1,954 # 8001ffc8 <sb>
    80003c16:	854a                	mv	a0,s2
    80003c18:	00001097          	auipc	ra,0x1
    80003c1c:	b4c080e7          	jalr	-1204(ra) # 80004764 <initlog>
}
    80003c20:	70a2                	ld	ra,40(sp)
    80003c22:	7402                	ld	s0,32(sp)
    80003c24:	64e2                	ld	s1,24(sp)
    80003c26:	6942                	ld	s2,16(sp)
    80003c28:	69a2                	ld	s3,8(sp)
    80003c2a:	6145                	addi	sp,sp,48
    80003c2c:	8082                	ret
    panic("invalid file system");
    80003c2e:	00005517          	auipc	a0,0x5
    80003c32:	a3250513          	addi	a0,a0,-1486 # 80008660 <syscalls+0x158>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	908080e7          	jalr	-1784(ra) # 8000053e <panic>

0000000080003c3e <iinit>:
{
    80003c3e:	7179                	addi	sp,sp,-48
    80003c40:	f406                	sd	ra,40(sp)
    80003c42:	f022                	sd	s0,32(sp)
    80003c44:	ec26                	sd	s1,24(sp)
    80003c46:	e84a                	sd	s2,16(sp)
    80003c48:	e44e                	sd	s3,8(sp)
    80003c4a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c4c:	00005597          	auipc	a1,0x5
    80003c50:	a2c58593          	addi	a1,a1,-1492 # 80008678 <syscalls+0x170>
    80003c54:	0001c517          	auipc	a0,0x1c
    80003c58:	39450513          	addi	a0,a0,916 # 8001ffe8 <itable>
    80003c5c:	ffffd097          	auipc	ra,0xffffd
    80003c60:	ef8080e7          	jalr	-264(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c64:	0001c497          	auipc	s1,0x1c
    80003c68:	3ac48493          	addi	s1,s1,940 # 80020010 <itable+0x28>
    80003c6c:	0001e997          	auipc	s3,0x1e
    80003c70:	e3498993          	addi	s3,s3,-460 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c74:	00005917          	auipc	s2,0x5
    80003c78:	a0c90913          	addi	s2,s2,-1524 # 80008680 <syscalls+0x178>
    80003c7c:	85ca                	mv	a1,s2
    80003c7e:	8526                	mv	a0,s1
    80003c80:	00001097          	auipc	ra,0x1
    80003c84:	e46080e7          	jalr	-442(ra) # 80004ac6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c88:	08848493          	addi	s1,s1,136
    80003c8c:	ff3498e3          	bne	s1,s3,80003c7c <iinit+0x3e>
}
    80003c90:	70a2                	ld	ra,40(sp)
    80003c92:	7402                	ld	s0,32(sp)
    80003c94:	64e2                	ld	s1,24(sp)
    80003c96:	6942                	ld	s2,16(sp)
    80003c98:	69a2                	ld	s3,8(sp)
    80003c9a:	6145                	addi	sp,sp,48
    80003c9c:	8082                	ret

0000000080003c9e <ialloc>:
{
    80003c9e:	715d                	addi	sp,sp,-80
    80003ca0:	e486                	sd	ra,72(sp)
    80003ca2:	e0a2                	sd	s0,64(sp)
    80003ca4:	fc26                	sd	s1,56(sp)
    80003ca6:	f84a                	sd	s2,48(sp)
    80003ca8:	f44e                	sd	s3,40(sp)
    80003caa:	f052                	sd	s4,32(sp)
    80003cac:	ec56                	sd	s5,24(sp)
    80003cae:	e85a                	sd	s6,16(sp)
    80003cb0:	e45e                	sd	s7,8(sp)
    80003cb2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb4:	0001c717          	auipc	a4,0x1c
    80003cb8:	32072703          	lw	a4,800(a4) # 8001ffd4 <sb+0xc>
    80003cbc:	4785                	li	a5,1
    80003cbe:	04e7fa63          	bgeu	a5,a4,80003d12 <ialloc+0x74>
    80003cc2:	8aaa                	mv	s5,a0
    80003cc4:	8bae                	mv	s7,a1
    80003cc6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003cc8:	0001ca17          	auipc	s4,0x1c
    80003ccc:	300a0a13          	addi	s4,s4,768 # 8001ffc8 <sb>
    80003cd0:	00048b1b          	sext.w	s6,s1
    80003cd4:	0044d593          	srli	a1,s1,0x4
    80003cd8:	018a2783          	lw	a5,24(s4)
    80003cdc:	9dbd                	addw	a1,a1,a5
    80003cde:	8556                	mv	a0,s5
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	954080e7          	jalr	-1708(ra) # 80003634 <bread>
    80003ce8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003cea:	05850993          	addi	s3,a0,88
    80003cee:	00f4f793          	andi	a5,s1,15
    80003cf2:	079a                	slli	a5,a5,0x6
    80003cf4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003cf6:	00099783          	lh	a5,0(s3)
    80003cfa:	c785                	beqz	a5,80003d22 <ialloc+0x84>
    brelse(bp);
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	a68080e7          	jalr	-1432(ra) # 80003764 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d04:	0485                	addi	s1,s1,1
    80003d06:	00ca2703          	lw	a4,12(s4)
    80003d0a:	0004879b          	sext.w	a5,s1
    80003d0e:	fce7e1e3          	bltu	a5,a4,80003cd0 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d12:	00005517          	auipc	a0,0x5
    80003d16:	97650513          	addi	a0,a0,-1674 # 80008688 <syscalls+0x180>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	824080e7          	jalr	-2012(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003d22:	04000613          	li	a2,64
    80003d26:	4581                	li	a1,0
    80003d28:	854e                	mv	a0,s3
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	fb6080e7          	jalr	-74(ra) # 80000ce0 <memset>
      dip->type = type;
    80003d32:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d36:	854a                	mv	a0,s2
    80003d38:	00001097          	auipc	ra,0x1
    80003d3c:	ca8080e7          	jalr	-856(ra) # 800049e0 <log_write>
      brelse(bp);
    80003d40:	854a                	mv	a0,s2
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	a22080e7          	jalr	-1502(ra) # 80003764 <brelse>
      return iget(dev, inum);
    80003d4a:	85da                	mv	a1,s6
    80003d4c:	8556                	mv	a0,s5
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	db4080e7          	jalr	-588(ra) # 80003b02 <iget>
}
    80003d56:	60a6                	ld	ra,72(sp)
    80003d58:	6406                	ld	s0,64(sp)
    80003d5a:	74e2                	ld	s1,56(sp)
    80003d5c:	7942                	ld	s2,48(sp)
    80003d5e:	79a2                	ld	s3,40(sp)
    80003d60:	7a02                	ld	s4,32(sp)
    80003d62:	6ae2                	ld	s5,24(sp)
    80003d64:	6b42                	ld	s6,16(sp)
    80003d66:	6ba2                	ld	s7,8(sp)
    80003d68:	6161                	addi	sp,sp,80
    80003d6a:	8082                	ret

0000000080003d6c <iupdate>:
{
    80003d6c:	1101                	addi	sp,sp,-32
    80003d6e:	ec06                	sd	ra,24(sp)
    80003d70:	e822                	sd	s0,16(sp)
    80003d72:	e426                	sd	s1,8(sp)
    80003d74:	e04a                	sd	s2,0(sp)
    80003d76:	1000                	addi	s0,sp,32
    80003d78:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d7a:	415c                	lw	a5,4(a0)
    80003d7c:	0047d79b          	srliw	a5,a5,0x4
    80003d80:	0001c597          	auipc	a1,0x1c
    80003d84:	2605a583          	lw	a1,608(a1) # 8001ffe0 <sb+0x18>
    80003d88:	9dbd                	addw	a1,a1,a5
    80003d8a:	4108                	lw	a0,0(a0)
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	8a8080e7          	jalr	-1880(ra) # 80003634 <bread>
    80003d94:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d96:	05850793          	addi	a5,a0,88
    80003d9a:	40c8                	lw	a0,4(s1)
    80003d9c:	893d                	andi	a0,a0,15
    80003d9e:	051a                	slli	a0,a0,0x6
    80003da0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003da2:	04449703          	lh	a4,68(s1)
    80003da6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003daa:	04649703          	lh	a4,70(s1)
    80003dae:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003db2:	04849703          	lh	a4,72(s1)
    80003db6:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003dba:	04a49703          	lh	a4,74(s1)
    80003dbe:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003dc2:	44f8                	lw	a4,76(s1)
    80003dc4:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003dc6:	03400613          	li	a2,52
    80003dca:	05048593          	addi	a1,s1,80
    80003dce:	0531                	addi	a0,a0,12
    80003dd0:	ffffd097          	auipc	ra,0xffffd
    80003dd4:	f70080e7          	jalr	-144(ra) # 80000d40 <memmove>
  log_write(bp);
    80003dd8:	854a                	mv	a0,s2
    80003dda:	00001097          	auipc	ra,0x1
    80003dde:	c06080e7          	jalr	-1018(ra) # 800049e0 <log_write>
  brelse(bp);
    80003de2:	854a                	mv	a0,s2
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	980080e7          	jalr	-1664(ra) # 80003764 <brelse>
}
    80003dec:	60e2                	ld	ra,24(sp)
    80003dee:	6442                	ld	s0,16(sp)
    80003df0:	64a2                	ld	s1,8(sp)
    80003df2:	6902                	ld	s2,0(sp)
    80003df4:	6105                	addi	sp,sp,32
    80003df6:	8082                	ret

0000000080003df8 <idup>:
{
    80003df8:	1101                	addi	sp,sp,-32
    80003dfa:	ec06                	sd	ra,24(sp)
    80003dfc:	e822                	sd	s0,16(sp)
    80003dfe:	e426                	sd	s1,8(sp)
    80003e00:	1000                	addi	s0,sp,32
    80003e02:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e04:	0001c517          	auipc	a0,0x1c
    80003e08:	1e450513          	addi	a0,a0,484 # 8001ffe8 <itable>
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	dd8080e7          	jalr	-552(ra) # 80000be4 <acquire>
  ip->ref++;
    80003e14:	449c                	lw	a5,8(s1)
    80003e16:	2785                	addiw	a5,a5,1
    80003e18:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e1a:	0001c517          	auipc	a0,0x1c
    80003e1e:	1ce50513          	addi	a0,a0,462 # 8001ffe8 <itable>
    80003e22:	ffffd097          	auipc	ra,0xffffd
    80003e26:	e76080e7          	jalr	-394(ra) # 80000c98 <release>
}
    80003e2a:	8526                	mv	a0,s1
    80003e2c:	60e2                	ld	ra,24(sp)
    80003e2e:	6442                	ld	s0,16(sp)
    80003e30:	64a2                	ld	s1,8(sp)
    80003e32:	6105                	addi	sp,sp,32
    80003e34:	8082                	ret

0000000080003e36 <ilock>:
{
    80003e36:	1101                	addi	sp,sp,-32
    80003e38:	ec06                	sd	ra,24(sp)
    80003e3a:	e822                	sd	s0,16(sp)
    80003e3c:	e426                	sd	s1,8(sp)
    80003e3e:	e04a                	sd	s2,0(sp)
    80003e40:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e42:	c115                	beqz	a0,80003e66 <ilock+0x30>
    80003e44:	84aa                	mv	s1,a0
    80003e46:	451c                	lw	a5,8(a0)
    80003e48:	00f05f63          	blez	a5,80003e66 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e4c:	0541                	addi	a0,a0,16
    80003e4e:	00001097          	auipc	ra,0x1
    80003e52:	cb2080e7          	jalr	-846(ra) # 80004b00 <acquiresleep>
  if(ip->valid == 0){
    80003e56:	40bc                	lw	a5,64(s1)
    80003e58:	cf99                	beqz	a5,80003e76 <ilock+0x40>
}
    80003e5a:	60e2                	ld	ra,24(sp)
    80003e5c:	6442                	ld	s0,16(sp)
    80003e5e:	64a2                	ld	s1,8(sp)
    80003e60:	6902                	ld	s2,0(sp)
    80003e62:	6105                	addi	sp,sp,32
    80003e64:	8082                	ret
    panic("ilock");
    80003e66:	00005517          	auipc	a0,0x5
    80003e6a:	83a50513          	addi	a0,a0,-1990 # 800086a0 <syscalls+0x198>
    80003e6e:	ffffc097          	auipc	ra,0xffffc
    80003e72:	6d0080e7          	jalr	1744(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e76:	40dc                	lw	a5,4(s1)
    80003e78:	0047d79b          	srliw	a5,a5,0x4
    80003e7c:	0001c597          	auipc	a1,0x1c
    80003e80:	1645a583          	lw	a1,356(a1) # 8001ffe0 <sb+0x18>
    80003e84:	9dbd                	addw	a1,a1,a5
    80003e86:	4088                	lw	a0,0(s1)
    80003e88:	fffff097          	auipc	ra,0xfffff
    80003e8c:	7ac080e7          	jalr	1964(ra) # 80003634 <bread>
    80003e90:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e92:	05850593          	addi	a1,a0,88
    80003e96:	40dc                	lw	a5,4(s1)
    80003e98:	8bbd                	andi	a5,a5,15
    80003e9a:	079a                	slli	a5,a5,0x6
    80003e9c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e9e:	00059783          	lh	a5,0(a1)
    80003ea2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ea6:	00259783          	lh	a5,2(a1)
    80003eaa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003eae:	00459783          	lh	a5,4(a1)
    80003eb2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003eb6:	00659783          	lh	a5,6(a1)
    80003eba:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ebe:	459c                	lw	a5,8(a1)
    80003ec0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ec2:	03400613          	li	a2,52
    80003ec6:	05b1                	addi	a1,a1,12
    80003ec8:	05048513          	addi	a0,s1,80
    80003ecc:	ffffd097          	auipc	ra,0xffffd
    80003ed0:	e74080e7          	jalr	-396(ra) # 80000d40 <memmove>
    brelse(bp);
    80003ed4:	854a                	mv	a0,s2
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	88e080e7          	jalr	-1906(ra) # 80003764 <brelse>
    ip->valid = 1;
    80003ede:	4785                	li	a5,1
    80003ee0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ee2:	04449783          	lh	a5,68(s1)
    80003ee6:	fbb5                	bnez	a5,80003e5a <ilock+0x24>
      panic("ilock: no type");
    80003ee8:	00004517          	auipc	a0,0x4
    80003eec:	7c050513          	addi	a0,a0,1984 # 800086a8 <syscalls+0x1a0>
    80003ef0:	ffffc097          	auipc	ra,0xffffc
    80003ef4:	64e080e7          	jalr	1614(ra) # 8000053e <panic>

0000000080003ef8 <iunlock>:
{
    80003ef8:	1101                	addi	sp,sp,-32
    80003efa:	ec06                	sd	ra,24(sp)
    80003efc:	e822                	sd	s0,16(sp)
    80003efe:	e426                	sd	s1,8(sp)
    80003f00:	e04a                	sd	s2,0(sp)
    80003f02:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f04:	c905                	beqz	a0,80003f34 <iunlock+0x3c>
    80003f06:	84aa                	mv	s1,a0
    80003f08:	01050913          	addi	s2,a0,16
    80003f0c:	854a                	mv	a0,s2
    80003f0e:	00001097          	auipc	ra,0x1
    80003f12:	c8c080e7          	jalr	-884(ra) # 80004b9a <holdingsleep>
    80003f16:	cd19                	beqz	a0,80003f34 <iunlock+0x3c>
    80003f18:	449c                	lw	a5,8(s1)
    80003f1a:	00f05d63          	blez	a5,80003f34 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f1e:	854a                	mv	a0,s2
    80003f20:	00001097          	auipc	ra,0x1
    80003f24:	c36080e7          	jalr	-970(ra) # 80004b56 <releasesleep>
}
    80003f28:	60e2                	ld	ra,24(sp)
    80003f2a:	6442                	ld	s0,16(sp)
    80003f2c:	64a2                	ld	s1,8(sp)
    80003f2e:	6902                	ld	s2,0(sp)
    80003f30:	6105                	addi	sp,sp,32
    80003f32:	8082                	ret
    panic("iunlock");
    80003f34:	00004517          	auipc	a0,0x4
    80003f38:	78450513          	addi	a0,a0,1924 # 800086b8 <syscalls+0x1b0>
    80003f3c:	ffffc097          	auipc	ra,0xffffc
    80003f40:	602080e7          	jalr	1538(ra) # 8000053e <panic>

0000000080003f44 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f44:	7179                	addi	sp,sp,-48
    80003f46:	f406                	sd	ra,40(sp)
    80003f48:	f022                	sd	s0,32(sp)
    80003f4a:	ec26                	sd	s1,24(sp)
    80003f4c:	e84a                	sd	s2,16(sp)
    80003f4e:	e44e                	sd	s3,8(sp)
    80003f50:	e052                	sd	s4,0(sp)
    80003f52:	1800                	addi	s0,sp,48
    80003f54:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f56:	05050493          	addi	s1,a0,80
    80003f5a:	08050913          	addi	s2,a0,128
    80003f5e:	a021                	j	80003f66 <itrunc+0x22>
    80003f60:	0491                	addi	s1,s1,4
    80003f62:	01248d63          	beq	s1,s2,80003f7c <itrunc+0x38>
    if(ip->addrs[i]){
    80003f66:	408c                	lw	a1,0(s1)
    80003f68:	dde5                	beqz	a1,80003f60 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f6a:	0009a503          	lw	a0,0(s3)
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	90c080e7          	jalr	-1780(ra) # 8000387a <bfree>
      ip->addrs[i] = 0;
    80003f76:	0004a023          	sw	zero,0(s1)
    80003f7a:	b7dd                	j	80003f60 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f7c:	0809a583          	lw	a1,128(s3)
    80003f80:	e185                	bnez	a1,80003fa0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f82:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f86:	854e                	mv	a0,s3
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	de4080e7          	jalr	-540(ra) # 80003d6c <iupdate>
}
    80003f90:	70a2                	ld	ra,40(sp)
    80003f92:	7402                	ld	s0,32(sp)
    80003f94:	64e2                	ld	s1,24(sp)
    80003f96:	6942                	ld	s2,16(sp)
    80003f98:	69a2                	ld	s3,8(sp)
    80003f9a:	6a02                	ld	s4,0(sp)
    80003f9c:	6145                	addi	sp,sp,48
    80003f9e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003fa0:	0009a503          	lw	a0,0(s3)
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	690080e7          	jalr	1680(ra) # 80003634 <bread>
    80003fac:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003fae:	05850493          	addi	s1,a0,88
    80003fb2:	45850913          	addi	s2,a0,1112
    80003fb6:	a811                	j	80003fca <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003fb8:	0009a503          	lw	a0,0(s3)
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	8be080e7          	jalr	-1858(ra) # 8000387a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003fc4:	0491                	addi	s1,s1,4
    80003fc6:	01248563          	beq	s1,s2,80003fd0 <itrunc+0x8c>
      if(a[j])
    80003fca:	408c                	lw	a1,0(s1)
    80003fcc:	dde5                	beqz	a1,80003fc4 <itrunc+0x80>
    80003fce:	b7ed                	j	80003fb8 <itrunc+0x74>
    brelse(bp);
    80003fd0:	8552                	mv	a0,s4
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	792080e7          	jalr	1938(ra) # 80003764 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fda:	0809a583          	lw	a1,128(s3)
    80003fde:	0009a503          	lw	a0,0(s3)
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	898080e7          	jalr	-1896(ra) # 8000387a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003fea:	0809a023          	sw	zero,128(s3)
    80003fee:	bf51                	j	80003f82 <itrunc+0x3e>

0000000080003ff0 <iput>:
{
    80003ff0:	1101                	addi	sp,sp,-32
    80003ff2:	ec06                	sd	ra,24(sp)
    80003ff4:	e822                	sd	s0,16(sp)
    80003ff6:	e426                	sd	s1,8(sp)
    80003ff8:	e04a                	sd	s2,0(sp)
    80003ffa:	1000                	addi	s0,sp,32
    80003ffc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ffe:	0001c517          	auipc	a0,0x1c
    80004002:	fea50513          	addi	a0,a0,-22 # 8001ffe8 <itable>
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	bde080e7          	jalr	-1058(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000400e:	4498                	lw	a4,8(s1)
    80004010:	4785                	li	a5,1
    80004012:	02f70363          	beq	a4,a5,80004038 <iput+0x48>
  ip->ref--;
    80004016:	449c                	lw	a5,8(s1)
    80004018:	37fd                	addiw	a5,a5,-1
    8000401a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000401c:	0001c517          	auipc	a0,0x1c
    80004020:	fcc50513          	addi	a0,a0,-52 # 8001ffe8 <itable>
    80004024:	ffffd097          	auipc	ra,0xffffd
    80004028:	c74080e7          	jalr	-908(ra) # 80000c98 <release>
}
    8000402c:	60e2                	ld	ra,24(sp)
    8000402e:	6442                	ld	s0,16(sp)
    80004030:	64a2                	ld	s1,8(sp)
    80004032:	6902                	ld	s2,0(sp)
    80004034:	6105                	addi	sp,sp,32
    80004036:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004038:	40bc                	lw	a5,64(s1)
    8000403a:	dff1                	beqz	a5,80004016 <iput+0x26>
    8000403c:	04a49783          	lh	a5,74(s1)
    80004040:	fbf9                	bnez	a5,80004016 <iput+0x26>
    acquiresleep(&ip->lock);
    80004042:	01048913          	addi	s2,s1,16
    80004046:	854a                	mv	a0,s2
    80004048:	00001097          	auipc	ra,0x1
    8000404c:	ab8080e7          	jalr	-1352(ra) # 80004b00 <acquiresleep>
    release(&itable.lock);
    80004050:	0001c517          	auipc	a0,0x1c
    80004054:	f9850513          	addi	a0,a0,-104 # 8001ffe8 <itable>
    80004058:	ffffd097          	auipc	ra,0xffffd
    8000405c:	c40080e7          	jalr	-960(ra) # 80000c98 <release>
    itrunc(ip);
    80004060:	8526                	mv	a0,s1
    80004062:	00000097          	auipc	ra,0x0
    80004066:	ee2080e7          	jalr	-286(ra) # 80003f44 <itrunc>
    ip->type = 0;
    8000406a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000406e:	8526                	mv	a0,s1
    80004070:	00000097          	auipc	ra,0x0
    80004074:	cfc080e7          	jalr	-772(ra) # 80003d6c <iupdate>
    ip->valid = 0;
    80004078:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000407c:	854a                	mv	a0,s2
    8000407e:	00001097          	auipc	ra,0x1
    80004082:	ad8080e7          	jalr	-1320(ra) # 80004b56 <releasesleep>
    acquire(&itable.lock);
    80004086:	0001c517          	auipc	a0,0x1c
    8000408a:	f6250513          	addi	a0,a0,-158 # 8001ffe8 <itable>
    8000408e:	ffffd097          	auipc	ra,0xffffd
    80004092:	b56080e7          	jalr	-1194(ra) # 80000be4 <acquire>
    80004096:	b741                	j	80004016 <iput+0x26>

0000000080004098 <iunlockput>:
{
    80004098:	1101                	addi	sp,sp,-32
    8000409a:	ec06                	sd	ra,24(sp)
    8000409c:	e822                	sd	s0,16(sp)
    8000409e:	e426                	sd	s1,8(sp)
    800040a0:	1000                	addi	s0,sp,32
    800040a2:	84aa                	mv	s1,a0
  iunlock(ip);
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	e54080e7          	jalr	-428(ra) # 80003ef8 <iunlock>
  iput(ip);
    800040ac:	8526                	mv	a0,s1
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	f42080e7          	jalr	-190(ra) # 80003ff0 <iput>
}
    800040b6:	60e2                	ld	ra,24(sp)
    800040b8:	6442                	ld	s0,16(sp)
    800040ba:	64a2                	ld	s1,8(sp)
    800040bc:	6105                	addi	sp,sp,32
    800040be:	8082                	ret

00000000800040c0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040c0:	1141                	addi	sp,sp,-16
    800040c2:	e422                	sd	s0,8(sp)
    800040c4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040c6:	411c                	lw	a5,0(a0)
    800040c8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040ca:	415c                	lw	a5,4(a0)
    800040cc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040ce:	04451783          	lh	a5,68(a0)
    800040d2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040d6:	04a51783          	lh	a5,74(a0)
    800040da:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040de:	04c56783          	lwu	a5,76(a0)
    800040e2:	e99c                	sd	a5,16(a1)
}
    800040e4:	6422                	ld	s0,8(sp)
    800040e6:	0141                	addi	sp,sp,16
    800040e8:	8082                	ret

00000000800040ea <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040ea:	457c                	lw	a5,76(a0)
    800040ec:	0ed7e963          	bltu	a5,a3,800041de <readi+0xf4>
{
    800040f0:	7159                	addi	sp,sp,-112
    800040f2:	f486                	sd	ra,104(sp)
    800040f4:	f0a2                	sd	s0,96(sp)
    800040f6:	eca6                	sd	s1,88(sp)
    800040f8:	e8ca                	sd	s2,80(sp)
    800040fa:	e4ce                	sd	s3,72(sp)
    800040fc:	e0d2                	sd	s4,64(sp)
    800040fe:	fc56                	sd	s5,56(sp)
    80004100:	f85a                	sd	s6,48(sp)
    80004102:	f45e                	sd	s7,40(sp)
    80004104:	f062                	sd	s8,32(sp)
    80004106:	ec66                	sd	s9,24(sp)
    80004108:	e86a                	sd	s10,16(sp)
    8000410a:	e46e                	sd	s11,8(sp)
    8000410c:	1880                	addi	s0,sp,112
    8000410e:	8baa                	mv	s7,a0
    80004110:	8c2e                	mv	s8,a1
    80004112:	8ab2                	mv	s5,a2
    80004114:	84b6                	mv	s1,a3
    80004116:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004118:	9f35                	addw	a4,a4,a3
    return 0;
    8000411a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000411c:	0ad76063          	bltu	a4,a3,800041bc <readi+0xd2>
  if(off + n > ip->size)
    80004120:	00e7f463          	bgeu	a5,a4,80004128 <readi+0x3e>
    n = ip->size - off;
    80004124:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004128:	0a0b0963          	beqz	s6,800041da <readi+0xf0>
    8000412c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000412e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004132:	5cfd                	li	s9,-1
    80004134:	a82d                	j	8000416e <readi+0x84>
    80004136:	020a1d93          	slli	s11,s4,0x20
    8000413a:	020ddd93          	srli	s11,s11,0x20
    8000413e:	05890613          	addi	a2,s2,88
    80004142:	86ee                	mv	a3,s11
    80004144:	963a                	add	a2,a2,a4
    80004146:	85d6                	mv	a1,s5
    80004148:	8562                	mv	a0,s8
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	acc080e7          	jalr	-1332(ra) # 80002c16 <either_copyout>
    80004152:	05950d63          	beq	a0,s9,800041ac <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004156:	854a                	mv	a0,s2
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	60c080e7          	jalr	1548(ra) # 80003764 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004160:	013a09bb          	addw	s3,s4,s3
    80004164:	009a04bb          	addw	s1,s4,s1
    80004168:	9aee                	add	s5,s5,s11
    8000416a:	0569f763          	bgeu	s3,s6,800041b8 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000416e:	000ba903          	lw	s2,0(s7)
    80004172:	00a4d59b          	srliw	a1,s1,0xa
    80004176:	855e                	mv	a0,s7
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	8b0080e7          	jalr	-1872(ra) # 80003a28 <bmap>
    80004180:	0005059b          	sext.w	a1,a0
    80004184:	854a                	mv	a0,s2
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	4ae080e7          	jalr	1198(ra) # 80003634 <bread>
    8000418e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004190:	3ff4f713          	andi	a4,s1,1023
    80004194:	40ed07bb          	subw	a5,s10,a4
    80004198:	413b06bb          	subw	a3,s6,s3
    8000419c:	8a3e                	mv	s4,a5
    8000419e:	2781                	sext.w	a5,a5
    800041a0:	0006861b          	sext.w	a2,a3
    800041a4:	f8f679e3          	bgeu	a2,a5,80004136 <readi+0x4c>
    800041a8:	8a36                	mv	s4,a3
    800041aa:	b771                	j	80004136 <readi+0x4c>
      brelse(bp);
    800041ac:	854a                	mv	a0,s2
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	5b6080e7          	jalr	1462(ra) # 80003764 <brelse>
      tot = -1;
    800041b6:	59fd                	li	s3,-1
  }
  return tot;
    800041b8:	0009851b          	sext.w	a0,s3
}
    800041bc:	70a6                	ld	ra,104(sp)
    800041be:	7406                	ld	s0,96(sp)
    800041c0:	64e6                	ld	s1,88(sp)
    800041c2:	6946                	ld	s2,80(sp)
    800041c4:	69a6                	ld	s3,72(sp)
    800041c6:	6a06                	ld	s4,64(sp)
    800041c8:	7ae2                	ld	s5,56(sp)
    800041ca:	7b42                	ld	s6,48(sp)
    800041cc:	7ba2                	ld	s7,40(sp)
    800041ce:	7c02                	ld	s8,32(sp)
    800041d0:	6ce2                	ld	s9,24(sp)
    800041d2:	6d42                	ld	s10,16(sp)
    800041d4:	6da2                	ld	s11,8(sp)
    800041d6:	6165                	addi	sp,sp,112
    800041d8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041da:	89da                	mv	s3,s6
    800041dc:	bff1                	j	800041b8 <readi+0xce>
    return 0;
    800041de:	4501                	li	a0,0
}
    800041e0:	8082                	ret

00000000800041e2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041e2:	457c                	lw	a5,76(a0)
    800041e4:	10d7e863          	bltu	a5,a3,800042f4 <writei+0x112>
{
    800041e8:	7159                	addi	sp,sp,-112
    800041ea:	f486                	sd	ra,104(sp)
    800041ec:	f0a2                	sd	s0,96(sp)
    800041ee:	eca6                	sd	s1,88(sp)
    800041f0:	e8ca                	sd	s2,80(sp)
    800041f2:	e4ce                	sd	s3,72(sp)
    800041f4:	e0d2                	sd	s4,64(sp)
    800041f6:	fc56                	sd	s5,56(sp)
    800041f8:	f85a                	sd	s6,48(sp)
    800041fa:	f45e                	sd	s7,40(sp)
    800041fc:	f062                	sd	s8,32(sp)
    800041fe:	ec66                	sd	s9,24(sp)
    80004200:	e86a                	sd	s10,16(sp)
    80004202:	e46e                	sd	s11,8(sp)
    80004204:	1880                	addi	s0,sp,112
    80004206:	8b2a                	mv	s6,a0
    80004208:	8c2e                	mv	s8,a1
    8000420a:	8ab2                	mv	s5,a2
    8000420c:	8936                	mv	s2,a3
    8000420e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004210:	00e687bb          	addw	a5,a3,a4
    80004214:	0ed7e263          	bltu	a5,a3,800042f8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004218:	00043737          	lui	a4,0x43
    8000421c:	0ef76063          	bltu	a4,a5,800042fc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004220:	0c0b8863          	beqz	s7,800042f0 <writei+0x10e>
    80004224:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004226:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000422a:	5cfd                	li	s9,-1
    8000422c:	a091                	j	80004270 <writei+0x8e>
    8000422e:	02099d93          	slli	s11,s3,0x20
    80004232:	020ddd93          	srli	s11,s11,0x20
    80004236:	05848513          	addi	a0,s1,88
    8000423a:	86ee                	mv	a3,s11
    8000423c:	8656                	mv	a2,s5
    8000423e:	85e2                	mv	a1,s8
    80004240:	953a                	add	a0,a0,a4
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	a2a080e7          	jalr	-1494(ra) # 80002c6c <either_copyin>
    8000424a:	07950263          	beq	a0,s9,800042ae <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000424e:	8526                	mv	a0,s1
    80004250:	00000097          	auipc	ra,0x0
    80004254:	790080e7          	jalr	1936(ra) # 800049e0 <log_write>
    brelse(bp);
    80004258:	8526                	mv	a0,s1
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	50a080e7          	jalr	1290(ra) # 80003764 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004262:	01498a3b          	addw	s4,s3,s4
    80004266:	0129893b          	addw	s2,s3,s2
    8000426a:	9aee                	add	s5,s5,s11
    8000426c:	057a7663          	bgeu	s4,s7,800042b8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004270:	000b2483          	lw	s1,0(s6)
    80004274:	00a9559b          	srliw	a1,s2,0xa
    80004278:	855a                	mv	a0,s6
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	7ae080e7          	jalr	1966(ra) # 80003a28 <bmap>
    80004282:	0005059b          	sext.w	a1,a0
    80004286:	8526                	mv	a0,s1
    80004288:	fffff097          	auipc	ra,0xfffff
    8000428c:	3ac080e7          	jalr	940(ra) # 80003634 <bread>
    80004290:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004292:	3ff97713          	andi	a4,s2,1023
    80004296:	40ed07bb          	subw	a5,s10,a4
    8000429a:	414b86bb          	subw	a3,s7,s4
    8000429e:	89be                	mv	s3,a5
    800042a0:	2781                	sext.w	a5,a5
    800042a2:	0006861b          	sext.w	a2,a3
    800042a6:	f8f674e3          	bgeu	a2,a5,8000422e <writei+0x4c>
    800042aa:	89b6                	mv	s3,a3
    800042ac:	b749                	j	8000422e <writei+0x4c>
      brelse(bp);
    800042ae:	8526                	mv	a0,s1
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	4b4080e7          	jalr	1204(ra) # 80003764 <brelse>
  }

  if(off > ip->size)
    800042b8:	04cb2783          	lw	a5,76(s6)
    800042bc:	0127f463          	bgeu	a5,s2,800042c4 <writei+0xe2>
    ip->size = off;
    800042c0:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042c4:	855a                	mv	a0,s6
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	aa6080e7          	jalr	-1370(ra) # 80003d6c <iupdate>

  return tot;
    800042ce:	000a051b          	sext.w	a0,s4
}
    800042d2:	70a6                	ld	ra,104(sp)
    800042d4:	7406                	ld	s0,96(sp)
    800042d6:	64e6                	ld	s1,88(sp)
    800042d8:	6946                	ld	s2,80(sp)
    800042da:	69a6                	ld	s3,72(sp)
    800042dc:	6a06                	ld	s4,64(sp)
    800042de:	7ae2                	ld	s5,56(sp)
    800042e0:	7b42                	ld	s6,48(sp)
    800042e2:	7ba2                	ld	s7,40(sp)
    800042e4:	7c02                	ld	s8,32(sp)
    800042e6:	6ce2                	ld	s9,24(sp)
    800042e8:	6d42                	ld	s10,16(sp)
    800042ea:	6da2                	ld	s11,8(sp)
    800042ec:	6165                	addi	sp,sp,112
    800042ee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042f0:	8a5e                	mv	s4,s7
    800042f2:	bfc9                	j	800042c4 <writei+0xe2>
    return -1;
    800042f4:	557d                	li	a0,-1
}
    800042f6:	8082                	ret
    return -1;
    800042f8:	557d                	li	a0,-1
    800042fa:	bfe1                	j	800042d2 <writei+0xf0>
    return -1;
    800042fc:	557d                	li	a0,-1
    800042fe:	bfd1                	j	800042d2 <writei+0xf0>

0000000080004300 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004300:	1141                	addi	sp,sp,-16
    80004302:	e406                	sd	ra,8(sp)
    80004304:	e022                	sd	s0,0(sp)
    80004306:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004308:	4639                	li	a2,14
    8000430a:	ffffd097          	auipc	ra,0xffffd
    8000430e:	aae080e7          	jalr	-1362(ra) # 80000db8 <strncmp>
}
    80004312:	60a2                	ld	ra,8(sp)
    80004314:	6402                	ld	s0,0(sp)
    80004316:	0141                	addi	sp,sp,16
    80004318:	8082                	ret

000000008000431a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000431a:	7139                	addi	sp,sp,-64
    8000431c:	fc06                	sd	ra,56(sp)
    8000431e:	f822                	sd	s0,48(sp)
    80004320:	f426                	sd	s1,40(sp)
    80004322:	f04a                	sd	s2,32(sp)
    80004324:	ec4e                	sd	s3,24(sp)
    80004326:	e852                	sd	s4,16(sp)
    80004328:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000432a:	04451703          	lh	a4,68(a0)
    8000432e:	4785                	li	a5,1
    80004330:	00f71a63          	bne	a4,a5,80004344 <dirlookup+0x2a>
    80004334:	892a                	mv	s2,a0
    80004336:	89ae                	mv	s3,a1
    80004338:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000433a:	457c                	lw	a5,76(a0)
    8000433c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000433e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004340:	e79d                	bnez	a5,8000436e <dirlookup+0x54>
    80004342:	a8a5                	j	800043ba <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004344:	00004517          	auipc	a0,0x4
    80004348:	37c50513          	addi	a0,a0,892 # 800086c0 <syscalls+0x1b8>
    8000434c:	ffffc097          	auipc	ra,0xffffc
    80004350:	1f2080e7          	jalr	498(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004354:	00004517          	auipc	a0,0x4
    80004358:	38450513          	addi	a0,a0,900 # 800086d8 <syscalls+0x1d0>
    8000435c:	ffffc097          	auipc	ra,0xffffc
    80004360:	1e2080e7          	jalr	482(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004364:	24c1                	addiw	s1,s1,16
    80004366:	04c92783          	lw	a5,76(s2)
    8000436a:	04f4f763          	bgeu	s1,a5,800043b8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000436e:	4741                	li	a4,16
    80004370:	86a6                	mv	a3,s1
    80004372:	fc040613          	addi	a2,s0,-64
    80004376:	4581                	li	a1,0
    80004378:	854a                	mv	a0,s2
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	d70080e7          	jalr	-656(ra) # 800040ea <readi>
    80004382:	47c1                	li	a5,16
    80004384:	fcf518e3          	bne	a0,a5,80004354 <dirlookup+0x3a>
    if(de.inum == 0)
    80004388:	fc045783          	lhu	a5,-64(s0)
    8000438c:	dfe1                	beqz	a5,80004364 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000438e:	fc240593          	addi	a1,s0,-62
    80004392:	854e                	mv	a0,s3
    80004394:	00000097          	auipc	ra,0x0
    80004398:	f6c080e7          	jalr	-148(ra) # 80004300 <namecmp>
    8000439c:	f561                	bnez	a0,80004364 <dirlookup+0x4a>
      if(poff)
    8000439e:	000a0463          	beqz	s4,800043a6 <dirlookup+0x8c>
        *poff = off;
    800043a2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043a6:	fc045583          	lhu	a1,-64(s0)
    800043aa:	00092503          	lw	a0,0(s2)
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	754080e7          	jalr	1876(ra) # 80003b02 <iget>
    800043b6:	a011                	j	800043ba <dirlookup+0xa0>
  return 0;
    800043b8:	4501                	li	a0,0
}
    800043ba:	70e2                	ld	ra,56(sp)
    800043bc:	7442                	ld	s0,48(sp)
    800043be:	74a2                	ld	s1,40(sp)
    800043c0:	7902                	ld	s2,32(sp)
    800043c2:	69e2                	ld	s3,24(sp)
    800043c4:	6a42                	ld	s4,16(sp)
    800043c6:	6121                	addi	sp,sp,64
    800043c8:	8082                	ret

00000000800043ca <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043ca:	711d                	addi	sp,sp,-96
    800043cc:	ec86                	sd	ra,88(sp)
    800043ce:	e8a2                	sd	s0,80(sp)
    800043d0:	e4a6                	sd	s1,72(sp)
    800043d2:	e0ca                	sd	s2,64(sp)
    800043d4:	fc4e                	sd	s3,56(sp)
    800043d6:	f852                	sd	s4,48(sp)
    800043d8:	f456                	sd	s5,40(sp)
    800043da:	f05a                	sd	s6,32(sp)
    800043dc:	ec5e                	sd	s7,24(sp)
    800043de:	e862                	sd	s8,16(sp)
    800043e0:	e466                	sd	s9,8(sp)
    800043e2:	1080                	addi	s0,sp,96
    800043e4:	84aa                	mv	s1,a0
    800043e6:	8b2e                	mv	s6,a1
    800043e8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043ea:	00054703          	lbu	a4,0(a0)
    800043ee:	02f00793          	li	a5,47
    800043f2:	02f70363          	beq	a4,a5,80004418 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043f6:	ffffe097          	auipc	ra,0xffffe
    800043fa:	830080e7          	jalr	-2000(ra) # 80001c26 <myproc>
    800043fe:	17053503          	ld	a0,368(a0)
    80004402:	00000097          	auipc	ra,0x0
    80004406:	9f6080e7          	jalr	-1546(ra) # 80003df8 <idup>
    8000440a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000440c:	02f00913          	li	s2,47
  len = path - s;
    80004410:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004412:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004414:	4c05                	li	s8,1
    80004416:	a865                	j	800044ce <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004418:	4585                	li	a1,1
    8000441a:	4505                	li	a0,1
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	6e6080e7          	jalr	1766(ra) # 80003b02 <iget>
    80004424:	89aa                	mv	s3,a0
    80004426:	b7dd                	j	8000440c <namex+0x42>
      iunlockput(ip);
    80004428:	854e                	mv	a0,s3
    8000442a:	00000097          	auipc	ra,0x0
    8000442e:	c6e080e7          	jalr	-914(ra) # 80004098 <iunlockput>
      return 0;
    80004432:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004434:	854e                	mv	a0,s3
    80004436:	60e6                	ld	ra,88(sp)
    80004438:	6446                	ld	s0,80(sp)
    8000443a:	64a6                	ld	s1,72(sp)
    8000443c:	6906                	ld	s2,64(sp)
    8000443e:	79e2                	ld	s3,56(sp)
    80004440:	7a42                	ld	s4,48(sp)
    80004442:	7aa2                	ld	s5,40(sp)
    80004444:	7b02                	ld	s6,32(sp)
    80004446:	6be2                	ld	s7,24(sp)
    80004448:	6c42                	ld	s8,16(sp)
    8000444a:	6ca2                	ld	s9,8(sp)
    8000444c:	6125                	addi	sp,sp,96
    8000444e:	8082                	ret
      iunlock(ip);
    80004450:	854e                	mv	a0,s3
    80004452:	00000097          	auipc	ra,0x0
    80004456:	aa6080e7          	jalr	-1370(ra) # 80003ef8 <iunlock>
      return ip;
    8000445a:	bfe9                	j	80004434 <namex+0x6a>
      iunlockput(ip);
    8000445c:	854e                	mv	a0,s3
    8000445e:	00000097          	auipc	ra,0x0
    80004462:	c3a080e7          	jalr	-966(ra) # 80004098 <iunlockput>
      return 0;
    80004466:	89d2                	mv	s3,s4
    80004468:	b7f1                	j	80004434 <namex+0x6a>
  len = path - s;
    8000446a:	40b48633          	sub	a2,s1,a1
    8000446e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004472:	094cd463          	bge	s9,s4,800044fa <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004476:	4639                	li	a2,14
    80004478:	8556                	mv	a0,s5
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	8c6080e7          	jalr	-1850(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004482:	0004c783          	lbu	a5,0(s1)
    80004486:	01279763          	bne	a5,s2,80004494 <namex+0xca>
    path++;
    8000448a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000448c:	0004c783          	lbu	a5,0(s1)
    80004490:	ff278de3          	beq	a5,s2,8000448a <namex+0xc0>
    ilock(ip);
    80004494:	854e                	mv	a0,s3
    80004496:	00000097          	auipc	ra,0x0
    8000449a:	9a0080e7          	jalr	-1632(ra) # 80003e36 <ilock>
    if(ip->type != T_DIR){
    8000449e:	04499783          	lh	a5,68(s3)
    800044a2:	f98793e3          	bne	a5,s8,80004428 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800044a6:	000b0563          	beqz	s6,800044b0 <namex+0xe6>
    800044aa:	0004c783          	lbu	a5,0(s1)
    800044ae:	d3cd                	beqz	a5,80004450 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044b0:	865e                	mv	a2,s7
    800044b2:	85d6                	mv	a1,s5
    800044b4:	854e                	mv	a0,s3
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	e64080e7          	jalr	-412(ra) # 8000431a <dirlookup>
    800044be:	8a2a                	mv	s4,a0
    800044c0:	dd51                	beqz	a0,8000445c <namex+0x92>
    iunlockput(ip);
    800044c2:	854e                	mv	a0,s3
    800044c4:	00000097          	auipc	ra,0x0
    800044c8:	bd4080e7          	jalr	-1068(ra) # 80004098 <iunlockput>
    ip = next;
    800044cc:	89d2                	mv	s3,s4
  while(*path == '/')
    800044ce:	0004c783          	lbu	a5,0(s1)
    800044d2:	05279763          	bne	a5,s2,80004520 <namex+0x156>
    path++;
    800044d6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044d8:	0004c783          	lbu	a5,0(s1)
    800044dc:	ff278de3          	beq	a5,s2,800044d6 <namex+0x10c>
  if(*path == 0)
    800044e0:	c79d                	beqz	a5,8000450e <namex+0x144>
    path++;
    800044e2:	85a6                	mv	a1,s1
  len = path - s;
    800044e4:	8a5e                	mv	s4,s7
    800044e6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800044e8:	01278963          	beq	a5,s2,800044fa <namex+0x130>
    800044ec:	dfbd                	beqz	a5,8000446a <namex+0xa0>
    path++;
    800044ee:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044f0:	0004c783          	lbu	a5,0(s1)
    800044f4:	ff279ce3          	bne	a5,s2,800044ec <namex+0x122>
    800044f8:	bf8d                	j	8000446a <namex+0xa0>
    memmove(name, s, len);
    800044fa:	2601                	sext.w	a2,a2
    800044fc:	8556                	mv	a0,s5
    800044fe:	ffffd097          	auipc	ra,0xffffd
    80004502:	842080e7          	jalr	-1982(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004506:	9a56                	add	s4,s4,s5
    80004508:	000a0023          	sb	zero,0(s4)
    8000450c:	bf9d                	j	80004482 <namex+0xb8>
  if(nameiparent){
    8000450e:	f20b03e3          	beqz	s6,80004434 <namex+0x6a>
    iput(ip);
    80004512:	854e                	mv	a0,s3
    80004514:	00000097          	auipc	ra,0x0
    80004518:	adc080e7          	jalr	-1316(ra) # 80003ff0 <iput>
    return 0;
    8000451c:	4981                	li	s3,0
    8000451e:	bf19                	j	80004434 <namex+0x6a>
  if(*path == 0)
    80004520:	d7fd                	beqz	a5,8000450e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004522:	0004c783          	lbu	a5,0(s1)
    80004526:	85a6                	mv	a1,s1
    80004528:	b7d1                	j	800044ec <namex+0x122>

000000008000452a <dirlink>:
{
    8000452a:	7139                	addi	sp,sp,-64
    8000452c:	fc06                	sd	ra,56(sp)
    8000452e:	f822                	sd	s0,48(sp)
    80004530:	f426                	sd	s1,40(sp)
    80004532:	f04a                	sd	s2,32(sp)
    80004534:	ec4e                	sd	s3,24(sp)
    80004536:	e852                	sd	s4,16(sp)
    80004538:	0080                	addi	s0,sp,64
    8000453a:	892a                	mv	s2,a0
    8000453c:	8a2e                	mv	s4,a1
    8000453e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004540:	4601                	li	a2,0
    80004542:	00000097          	auipc	ra,0x0
    80004546:	dd8080e7          	jalr	-552(ra) # 8000431a <dirlookup>
    8000454a:	e93d                	bnez	a0,800045c0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000454c:	04c92483          	lw	s1,76(s2)
    80004550:	c49d                	beqz	s1,8000457e <dirlink+0x54>
    80004552:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004554:	4741                	li	a4,16
    80004556:	86a6                	mv	a3,s1
    80004558:	fc040613          	addi	a2,s0,-64
    8000455c:	4581                	li	a1,0
    8000455e:	854a                	mv	a0,s2
    80004560:	00000097          	auipc	ra,0x0
    80004564:	b8a080e7          	jalr	-1142(ra) # 800040ea <readi>
    80004568:	47c1                	li	a5,16
    8000456a:	06f51163          	bne	a0,a5,800045cc <dirlink+0xa2>
    if(de.inum == 0)
    8000456e:	fc045783          	lhu	a5,-64(s0)
    80004572:	c791                	beqz	a5,8000457e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004574:	24c1                	addiw	s1,s1,16
    80004576:	04c92783          	lw	a5,76(s2)
    8000457a:	fcf4ede3          	bltu	s1,a5,80004554 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000457e:	4639                	li	a2,14
    80004580:	85d2                	mv	a1,s4
    80004582:	fc240513          	addi	a0,s0,-62
    80004586:	ffffd097          	auipc	ra,0xffffd
    8000458a:	86e080e7          	jalr	-1938(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000458e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004592:	4741                	li	a4,16
    80004594:	86a6                	mv	a3,s1
    80004596:	fc040613          	addi	a2,s0,-64
    8000459a:	4581                	li	a1,0
    8000459c:	854a                	mv	a0,s2
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	c44080e7          	jalr	-956(ra) # 800041e2 <writei>
    800045a6:	872a                	mv	a4,a0
    800045a8:	47c1                	li	a5,16
  return 0;
    800045aa:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045ac:	02f71863          	bne	a4,a5,800045dc <dirlink+0xb2>
}
    800045b0:	70e2                	ld	ra,56(sp)
    800045b2:	7442                	ld	s0,48(sp)
    800045b4:	74a2                	ld	s1,40(sp)
    800045b6:	7902                	ld	s2,32(sp)
    800045b8:	69e2                	ld	s3,24(sp)
    800045ba:	6a42                	ld	s4,16(sp)
    800045bc:	6121                	addi	sp,sp,64
    800045be:	8082                	ret
    iput(ip);
    800045c0:	00000097          	auipc	ra,0x0
    800045c4:	a30080e7          	jalr	-1488(ra) # 80003ff0 <iput>
    return -1;
    800045c8:	557d                	li	a0,-1
    800045ca:	b7dd                	j	800045b0 <dirlink+0x86>
      panic("dirlink read");
    800045cc:	00004517          	auipc	a0,0x4
    800045d0:	11c50513          	addi	a0,a0,284 # 800086e8 <syscalls+0x1e0>
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	f6a080e7          	jalr	-150(ra) # 8000053e <panic>
    panic("dirlink");
    800045dc:	00004517          	auipc	a0,0x4
    800045e0:	21c50513          	addi	a0,a0,540 # 800087f8 <syscalls+0x2f0>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	f5a080e7          	jalr	-166(ra) # 8000053e <panic>

00000000800045ec <namei>:

struct inode*
namei(char *path)
{
    800045ec:	1101                	addi	sp,sp,-32
    800045ee:	ec06                	sd	ra,24(sp)
    800045f0:	e822                	sd	s0,16(sp)
    800045f2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045f4:	fe040613          	addi	a2,s0,-32
    800045f8:	4581                	li	a1,0
    800045fa:	00000097          	auipc	ra,0x0
    800045fe:	dd0080e7          	jalr	-560(ra) # 800043ca <namex>
}
    80004602:	60e2                	ld	ra,24(sp)
    80004604:	6442                	ld	s0,16(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret

000000008000460a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000460a:	1141                	addi	sp,sp,-16
    8000460c:	e406                	sd	ra,8(sp)
    8000460e:	e022                	sd	s0,0(sp)
    80004610:	0800                	addi	s0,sp,16
    80004612:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004614:	4585                	li	a1,1
    80004616:	00000097          	auipc	ra,0x0
    8000461a:	db4080e7          	jalr	-588(ra) # 800043ca <namex>
}
    8000461e:	60a2                	ld	ra,8(sp)
    80004620:	6402                	ld	s0,0(sp)
    80004622:	0141                	addi	sp,sp,16
    80004624:	8082                	ret

0000000080004626 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004626:	1101                	addi	sp,sp,-32
    80004628:	ec06                	sd	ra,24(sp)
    8000462a:	e822                	sd	s0,16(sp)
    8000462c:	e426                	sd	s1,8(sp)
    8000462e:	e04a                	sd	s2,0(sp)
    80004630:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004632:	0001d917          	auipc	s2,0x1d
    80004636:	45e90913          	addi	s2,s2,1118 # 80021a90 <log>
    8000463a:	01892583          	lw	a1,24(s2)
    8000463e:	02892503          	lw	a0,40(s2)
    80004642:	fffff097          	auipc	ra,0xfffff
    80004646:	ff2080e7          	jalr	-14(ra) # 80003634 <bread>
    8000464a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000464c:	02c92683          	lw	a3,44(s2)
    80004650:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004652:	02d05763          	blez	a3,80004680 <write_head+0x5a>
    80004656:	0001d797          	auipc	a5,0x1d
    8000465a:	46a78793          	addi	a5,a5,1130 # 80021ac0 <log+0x30>
    8000465e:	05c50713          	addi	a4,a0,92
    80004662:	36fd                	addiw	a3,a3,-1
    80004664:	1682                	slli	a3,a3,0x20
    80004666:	9281                	srli	a3,a3,0x20
    80004668:	068a                	slli	a3,a3,0x2
    8000466a:	0001d617          	auipc	a2,0x1d
    8000466e:	45a60613          	addi	a2,a2,1114 # 80021ac4 <log+0x34>
    80004672:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004674:	4390                	lw	a2,0(a5)
    80004676:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004678:	0791                	addi	a5,a5,4
    8000467a:	0711                	addi	a4,a4,4
    8000467c:	fed79ce3          	bne	a5,a3,80004674 <write_head+0x4e>
  }
  bwrite(buf);
    80004680:	8526                	mv	a0,s1
    80004682:	fffff097          	auipc	ra,0xfffff
    80004686:	0a4080e7          	jalr	164(ra) # 80003726 <bwrite>
  brelse(buf);
    8000468a:	8526                	mv	a0,s1
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	0d8080e7          	jalr	216(ra) # 80003764 <brelse>
}
    80004694:	60e2                	ld	ra,24(sp)
    80004696:	6442                	ld	s0,16(sp)
    80004698:	64a2                	ld	s1,8(sp)
    8000469a:	6902                	ld	s2,0(sp)
    8000469c:	6105                	addi	sp,sp,32
    8000469e:	8082                	ret

00000000800046a0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a0:	0001d797          	auipc	a5,0x1d
    800046a4:	41c7a783          	lw	a5,1052(a5) # 80021abc <log+0x2c>
    800046a8:	0af05d63          	blez	a5,80004762 <install_trans+0xc2>
{
    800046ac:	7139                	addi	sp,sp,-64
    800046ae:	fc06                	sd	ra,56(sp)
    800046b0:	f822                	sd	s0,48(sp)
    800046b2:	f426                	sd	s1,40(sp)
    800046b4:	f04a                	sd	s2,32(sp)
    800046b6:	ec4e                	sd	s3,24(sp)
    800046b8:	e852                	sd	s4,16(sp)
    800046ba:	e456                	sd	s5,8(sp)
    800046bc:	e05a                	sd	s6,0(sp)
    800046be:	0080                	addi	s0,sp,64
    800046c0:	8b2a                	mv	s6,a0
    800046c2:	0001da97          	auipc	s5,0x1d
    800046c6:	3fea8a93          	addi	s5,s5,1022 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ca:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046cc:	0001d997          	auipc	s3,0x1d
    800046d0:	3c498993          	addi	s3,s3,964 # 80021a90 <log>
    800046d4:	a035                	j	80004700 <install_trans+0x60>
      bunpin(dbuf);
    800046d6:	8526                	mv	a0,s1
    800046d8:	fffff097          	auipc	ra,0xfffff
    800046dc:	166080e7          	jalr	358(ra) # 8000383e <bunpin>
    brelse(lbuf);
    800046e0:	854a                	mv	a0,s2
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	082080e7          	jalr	130(ra) # 80003764 <brelse>
    brelse(dbuf);
    800046ea:	8526                	mv	a0,s1
    800046ec:	fffff097          	auipc	ra,0xfffff
    800046f0:	078080e7          	jalr	120(ra) # 80003764 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046f4:	2a05                	addiw	s4,s4,1
    800046f6:	0a91                	addi	s5,s5,4
    800046f8:	02c9a783          	lw	a5,44(s3)
    800046fc:	04fa5963          	bge	s4,a5,8000474e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004700:	0189a583          	lw	a1,24(s3)
    80004704:	014585bb          	addw	a1,a1,s4
    80004708:	2585                	addiw	a1,a1,1
    8000470a:	0289a503          	lw	a0,40(s3)
    8000470e:	fffff097          	auipc	ra,0xfffff
    80004712:	f26080e7          	jalr	-218(ra) # 80003634 <bread>
    80004716:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004718:	000aa583          	lw	a1,0(s5)
    8000471c:	0289a503          	lw	a0,40(s3)
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	f14080e7          	jalr	-236(ra) # 80003634 <bread>
    80004728:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000472a:	40000613          	li	a2,1024
    8000472e:	05890593          	addi	a1,s2,88
    80004732:	05850513          	addi	a0,a0,88
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	60a080e7          	jalr	1546(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000473e:	8526                	mv	a0,s1
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	fe6080e7          	jalr	-26(ra) # 80003726 <bwrite>
    if(recovering == 0)
    80004748:	f80b1ce3          	bnez	s6,800046e0 <install_trans+0x40>
    8000474c:	b769                	j	800046d6 <install_trans+0x36>
}
    8000474e:	70e2                	ld	ra,56(sp)
    80004750:	7442                	ld	s0,48(sp)
    80004752:	74a2                	ld	s1,40(sp)
    80004754:	7902                	ld	s2,32(sp)
    80004756:	69e2                	ld	s3,24(sp)
    80004758:	6a42                	ld	s4,16(sp)
    8000475a:	6aa2                	ld	s5,8(sp)
    8000475c:	6b02                	ld	s6,0(sp)
    8000475e:	6121                	addi	sp,sp,64
    80004760:	8082                	ret
    80004762:	8082                	ret

0000000080004764 <initlog>:
{
    80004764:	7179                	addi	sp,sp,-48
    80004766:	f406                	sd	ra,40(sp)
    80004768:	f022                	sd	s0,32(sp)
    8000476a:	ec26                	sd	s1,24(sp)
    8000476c:	e84a                	sd	s2,16(sp)
    8000476e:	e44e                	sd	s3,8(sp)
    80004770:	1800                	addi	s0,sp,48
    80004772:	892a                	mv	s2,a0
    80004774:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004776:	0001d497          	auipc	s1,0x1d
    8000477a:	31a48493          	addi	s1,s1,794 # 80021a90 <log>
    8000477e:	00004597          	auipc	a1,0x4
    80004782:	f7a58593          	addi	a1,a1,-134 # 800086f8 <syscalls+0x1f0>
    80004786:	8526                	mv	a0,s1
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	3cc080e7          	jalr	972(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004790:	0149a583          	lw	a1,20(s3)
    80004794:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004796:	0109a783          	lw	a5,16(s3)
    8000479a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000479c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800047a0:	854a                	mv	a0,s2
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	e92080e7          	jalr	-366(ra) # 80003634 <bread>
  log.lh.n = lh->n;
    800047aa:	4d3c                	lw	a5,88(a0)
    800047ac:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047ae:	02f05563          	blez	a5,800047d8 <initlog+0x74>
    800047b2:	05c50713          	addi	a4,a0,92
    800047b6:	0001d697          	auipc	a3,0x1d
    800047ba:	30a68693          	addi	a3,a3,778 # 80021ac0 <log+0x30>
    800047be:	37fd                	addiw	a5,a5,-1
    800047c0:	1782                	slli	a5,a5,0x20
    800047c2:	9381                	srli	a5,a5,0x20
    800047c4:	078a                	slli	a5,a5,0x2
    800047c6:	06050613          	addi	a2,a0,96
    800047ca:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800047cc:	4310                	lw	a2,0(a4)
    800047ce:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800047d0:	0711                	addi	a4,a4,4
    800047d2:	0691                	addi	a3,a3,4
    800047d4:	fef71ce3          	bne	a4,a5,800047cc <initlog+0x68>
  brelse(buf);
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	f8c080e7          	jalr	-116(ra) # 80003764 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047e0:	4505                	li	a0,1
    800047e2:	00000097          	auipc	ra,0x0
    800047e6:	ebe080e7          	jalr	-322(ra) # 800046a0 <install_trans>
  log.lh.n = 0;
    800047ea:	0001d797          	auipc	a5,0x1d
    800047ee:	2c07a923          	sw	zero,722(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    800047f2:	00000097          	auipc	ra,0x0
    800047f6:	e34080e7          	jalr	-460(ra) # 80004626 <write_head>
}
    800047fa:	70a2                	ld	ra,40(sp)
    800047fc:	7402                	ld	s0,32(sp)
    800047fe:	64e2                	ld	s1,24(sp)
    80004800:	6942                	ld	s2,16(sp)
    80004802:	69a2                	ld	s3,8(sp)
    80004804:	6145                	addi	sp,sp,48
    80004806:	8082                	ret

0000000080004808 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004808:	1101                	addi	sp,sp,-32
    8000480a:	ec06                	sd	ra,24(sp)
    8000480c:	e822                	sd	s0,16(sp)
    8000480e:	e426                	sd	s1,8(sp)
    80004810:	e04a                	sd	s2,0(sp)
    80004812:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004814:	0001d517          	auipc	a0,0x1d
    80004818:	27c50513          	addi	a0,a0,636 # 80021a90 <log>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	3c8080e7          	jalr	968(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004824:	0001d497          	auipc	s1,0x1d
    80004828:	26c48493          	addi	s1,s1,620 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000482c:	4979                	li	s2,30
    8000482e:	a039                	j	8000483c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004830:	85a6                	mv	a1,s1
    80004832:	8526                	mv	a0,s1
    80004834:	ffffe097          	auipc	ra,0xffffe
    80004838:	f42080e7          	jalr	-190(ra) # 80002776 <sleep>
    if(log.committing){
    8000483c:	50dc                	lw	a5,36(s1)
    8000483e:	fbed                	bnez	a5,80004830 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004840:	509c                	lw	a5,32(s1)
    80004842:	0017871b          	addiw	a4,a5,1
    80004846:	0007069b          	sext.w	a3,a4
    8000484a:	0027179b          	slliw	a5,a4,0x2
    8000484e:	9fb9                	addw	a5,a5,a4
    80004850:	0017979b          	slliw	a5,a5,0x1
    80004854:	54d8                	lw	a4,44(s1)
    80004856:	9fb9                	addw	a5,a5,a4
    80004858:	00f95963          	bge	s2,a5,8000486a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000485c:	85a6                	mv	a1,s1
    8000485e:	8526                	mv	a0,s1
    80004860:	ffffe097          	auipc	ra,0xffffe
    80004864:	f16080e7          	jalr	-234(ra) # 80002776 <sleep>
    80004868:	bfd1                	j	8000483c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000486a:	0001d517          	auipc	a0,0x1d
    8000486e:	22650513          	addi	a0,a0,550 # 80021a90 <log>
    80004872:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	424080e7          	jalr	1060(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000487c:	60e2                	ld	ra,24(sp)
    8000487e:	6442                	ld	s0,16(sp)
    80004880:	64a2                	ld	s1,8(sp)
    80004882:	6902                	ld	s2,0(sp)
    80004884:	6105                	addi	sp,sp,32
    80004886:	8082                	ret

0000000080004888 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004888:	7139                	addi	sp,sp,-64
    8000488a:	fc06                	sd	ra,56(sp)
    8000488c:	f822                	sd	s0,48(sp)
    8000488e:	f426                	sd	s1,40(sp)
    80004890:	f04a                	sd	s2,32(sp)
    80004892:	ec4e                	sd	s3,24(sp)
    80004894:	e852                	sd	s4,16(sp)
    80004896:	e456                	sd	s5,8(sp)
    80004898:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000489a:	0001d497          	auipc	s1,0x1d
    8000489e:	1f648493          	addi	s1,s1,502 # 80021a90 <log>
    800048a2:	8526                	mv	a0,s1
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	340080e7          	jalr	832(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800048ac:	509c                	lw	a5,32(s1)
    800048ae:	37fd                	addiw	a5,a5,-1
    800048b0:	0007891b          	sext.w	s2,a5
    800048b4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048b6:	50dc                	lw	a5,36(s1)
    800048b8:	efb9                	bnez	a5,80004916 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048ba:	06091663          	bnez	s2,80004926 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800048be:	0001d497          	auipc	s1,0x1d
    800048c2:	1d248493          	addi	s1,s1,466 # 80021a90 <log>
    800048c6:	4785                	li	a5,1
    800048c8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048ca:	8526                	mv	a0,s1
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	3cc080e7          	jalr	972(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048d4:	54dc                	lw	a5,44(s1)
    800048d6:	06f04763          	bgtz	a5,80004944 <end_op+0xbc>
    acquire(&log.lock);
    800048da:	0001d497          	auipc	s1,0x1d
    800048de:	1b648493          	addi	s1,s1,438 # 80021a90 <log>
    800048e2:	8526                	mv	a0,s1
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
    log.committing = 0;
    800048ec:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048f0:	8526                	mv	a0,s1
    800048f2:	ffffe097          	auipc	ra,0xffffe
    800048f6:	01a080e7          	jalr	26(ra) # 8000290c <wakeup>
    release(&log.lock);
    800048fa:	8526                	mv	a0,s1
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	39c080e7          	jalr	924(ra) # 80000c98 <release>
}
    80004904:	70e2                	ld	ra,56(sp)
    80004906:	7442                	ld	s0,48(sp)
    80004908:	74a2                	ld	s1,40(sp)
    8000490a:	7902                	ld	s2,32(sp)
    8000490c:	69e2                	ld	s3,24(sp)
    8000490e:	6a42                	ld	s4,16(sp)
    80004910:	6aa2                	ld	s5,8(sp)
    80004912:	6121                	addi	sp,sp,64
    80004914:	8082                	ret
    panic("log.committing");
    80004916:	00004517          	auipc	a0,0x4
    8000491a:	dea50513          	addi	a0,a0,-534 # 80008700 <syscalls+0x1f8>
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	c20080e7          	jalr	-992(ra) # 8000053e <panic>
    wakeup(&log);
    80004926:	0001d497          	auipc	s1,0x1d
    8000492a:	16a48493          	addi	s1,s1,362 # 80021a90 <log>
    8000492e:	8526                	mv	a0,s1
    80004930:	ffffe097          	auipc	ra,0xffffe
    80004934:	fdc080e7          	jalr	-36(ra) # 8000290c <wakeup>
  release(&log.lock);
    80004938:	8526                	mv	a0,s1
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	35e080e7          	jalr	862(ra) # 80000c98 <release>
  if(do_commit){
    80004942:	b7c9                	j	80004904 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004944:	0001da97          	auipc	s5,0x1d
    80004948:	17ca8a93          	addi	s5,s5,380 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000494c:	0001da17          	auipc	s4,0x1d
    80004950:	144a0a13          	addi	s4,s4,324 # 80021a90 <log>
    80004954:	018a2583          	lw	a1,24(s4)
    80004958:	012585bb          	addw	a1,a1,s2
    8000495c:	2585                	addiw	a1,a1,1
    8000495e:	028a2503          	lw	a0,40(s4)
    80004962:	fffff097          	auipc	ra,0xfffff
    80004966:	cd2080e7          	jalr	-814(ra) # 80003634 <bread>
    8000496a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000496c:	000aa583          	lw	a1,0(s5)
    80004970:	028a2503          	lw	a0,40(s4)
    80004974:	fffff097          	auipc	ra,0xfffff
    80004978:	cc0080e7          	jalr	-832(ra) # 80003634 <bread>
    8000497c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000497e:	40000613          	li	a2,1024
    80004982:	05850593          	addi	a1,a0,88
    80004986:	05848513          	addi	a0,s1,88
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	3b6080e7          	jalr	950(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004992:	8526                	mv	a0,s1
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	d92080e7          	jalr	-622(ra) # 80003726 <bwrite>
    brelse(from);
    8000499c:	854e                	mv	a0,s3
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	dc6080e7          	jalr	-570(ra) # 80003764 <brelse>
    brelse(to);
    800049a6:	8526                	mv	a0,s1
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	dbc080e7          	jalr	-580(ra) # 80003764 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049b0:	2905                	addiw	s2,s2,1
    800049b2:	0a91                	addi	s5,s5,4
    800049b4:	02ca2783          	lw	a5,44(s4)
    800049b8:	f8f94ee3          	blt	s2,a5,80004954 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049bc:	00000097          	auipc	ra,0x0
    800049c0:	c6a080e7          	jalr	-918(ra) # 80004626 <write_head>
    install_trans(0); // Now install writes to home locations
    800049c4:	4501                	li	a0,0
    800049c6:	00000097          	auipc	ra,0x0
    800049ca:	cda080e7          	jalr	-806(ra) # 800046a0 <install_trans>
    log.lh.n = 0;
    800049ce:	0001d797          	auipc	a5,0x1d
    800049d2:	0e07a723          	sw	zero,238(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	c50080e7          	jalr	-944(ra) # 80004626 <write_head>
    800049de:	bdf5                	j	800048da <end_op+0x52>

00000000800049e0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049e0:	1101                	addi	sp,sp,-32
    800049e2:	ec06                	sd	ra,24(sp)
    800049e4:	e822                	sd	s0,16(sp)
    800049e6:	e426                	sd	s1,8(sp)
    800049e8:	e04a                	sd	s2,0(sp)
    800049ea:	1000                	addi	s0,sp,32
    800049ec:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049ee:	0001d917          	auipc	s2,0x1d
    800049f2:	0a290913          	addi	s2,s2,162 # 80021a90 <log>
    800049f6:	854a                	mv	a0,s2
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	1ec080e7          	jalr	492(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a00:	02c92603          	lw	a2,44(s2)
    80004a04:	47f5                	li	a5,29
    80004a06:	06c7c563          	blt	a5,a2,80004a70 <log_write+0x90>
    80004a0a:	0001d797          	auipc	a5,0x1d
    80004a0e:	0a27a783          	lw	a5,162(a5) # 80021aac <log+0x1c>
    80004a12:	37fd                	addiw	a5,a5,-1
    80004a14:	04f65e63          	bge	a2,a5,80004a70 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a18:	0001d797          	auipc	a5,0x1d
    80004a1c:	0987a783          	lw	a5,152(a5) # 80021ab0 <log+0x20>
    80004a20:	06f05063          	blez	a5,80004a80 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a24:	4781                	li	a5,0
    80004a26:	06c05563          	blez	a2,80004a90 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a2a:	44cc                	lw	a1,12(s1)
    80004a2c:	0001d717          	auipc	a4,0x1d
    80004a30:	09470713          	addi	a4,a4,148 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a34:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a36:	4314                	lw	a3,0(a4)
    80004a38:	04b68c63          	beq	a3,a1,80004a90 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a3c:	2785                	addiw	a5,a5,1
    80004a3e:	0711                	addi	a4,a4,4
    80004a40:	fef61be3          	bne	a2,a5,80004a36 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a44:	0621                	addi	a2,a2,8
    80004a46:	060a                	slli	a2,a2,0x2
    80004a48:	0001d797          	auipc	a5,0x1d
    80004a4c:	04878793          	addi	a5,a5,72 # 80021a90 <log>
    80004a50:	963e                	add	a2,a2,a5
    80004a52:	44dc                	lw	a5,12(s1)
    80004a54:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a56:	8526                	mv	a0,s1
    80004a58:	fffff097          	auipc	ra,0xfffff
    80004a5c:	daa080e7          	jalr	-598(ra) # 80003802 <bpin>
    log.lh.n++;
    80004a60:	0001d717          	auipc	a4,0x1d
    80004a64:	03070713          	addi	a4,a4,48 # 80021a90 <log>
    80004a68:	575c                	lw	a5,44(a4)
    80004a6a:	2785                	addiw	a5,a5,1
    80004a6c:	d75c                	sw	a5,44(a4)
    80004a6e:	a835                	j	80004aaa <log_write+0xca>
    panic("too big a transaction");
    80004a70:	00004517          	auipc	a0,0x4
    80004a74:	ca050513          	addi	a0,a0,-864 # 80008710 <syscalls+0x208>
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	ac6080e7          	jalr	-1338(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a80:	00004517          	auipc	a0,0x4
    80004a84:	ca850513          	addi	a0,a0,-856 # 80008728 <syscalls+0x220>
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	ab6080e7          	jalr	-1354(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a90:	00878713          	addi	a4,a5,8
    80004a94:	00271693          	slli	a3,a4,0x2
    80004a98:	0001d717          	auipc	a4,0x1d
    80004a9c:	ff870713          	addi	a4,a4,-8 # 80021a90 <log>
    80004aa0:	9736                	add	a4,a4,a3
    80004aa2:	44d4                	lw	a3,12(s1)
    80004aa4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004aa6:	faf608e3          	beq	a2,a5,80004a56 <log_write+0x76>
  }
  release(&log.lock);
    80004aaa:	0001d517          	auipc	a0,0x1d
    80004aae:	fe650513          	addi	a0,a0,-26 # 80021a90 <log>
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	1e6080e7          	jalr	486(ra) # 80000c98 <release>
}
    80004aba:	60e2                	ld	ra,24(sp)
    80004abc:	6442                	ld	s0,16(sp)
    80004abe:	64a2                	ld	s1,8(sp)
    80004ac0:	6902                	ld	s2,0(sp)
    80004ac2:	6105                	addi	sp,sp,32
    80004ac4:	8082                	ret

0000000080004ac6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ac6:	1101                	addi	sp,sp,-32
    80004ac8:	ec06                	sd	ra,24(sp)
    80004aca:	e822                	sd	s0,16(sp)
    80004acc:	e426                	sd	s1,8(sp)
    80004ace:	e04a                	sd	s2,0(sp)
    80004ad0:	1000                	addi	s0,sp,32
    80004ad2:	84aa                	mv	s1,a0
    80004ad4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ad6:	00004597          	auipc	a1,0x4
    80004ada:	c7258593          	addi	a1,a1,-910 # 80008748 <syscalls+0x240>
    80004ade:	0521                	addi	a0,a0,8
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	074080e7          	jalr	116(ra) # 80000b54 <initlock>
  lk->name = name;
    80004ae8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004aec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004af0:	0204a423          	sw	zero,40(s1)
}
    80004af4:	60e2                	ld	ra,24(sp)
    80004af6:	6442                	ld	s0,16(sp)
    80004af8:	64a2                	ld	s1,8(sp)
    80004afa:	6902                	ld	s2,0(sp)
    80004afc:	6105                	addi	sp,sp,32
    80004afe:	8082                	ret

0000000080004b00 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b00:	1101                	addi	sp,sp,-32
    80004b02:	ec06                	sd	ra,24(sp)
    80004b04:	e822                	sd	s0,16(sp)
    80004b06:	e426                	sd	s1,8(sp)
    80004b08:	e04a                	sd	s2,0(sp)
    80004b0a:	1000                	addi	s0,sp,32
    80004b0c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b0e:	00850913          	addi	s2,a0,8
    80004b12:	854a                	mv	a0,s2
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	0d0080e7          	jalr	208(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004b1c:	409c                	lw	a5,0(s1)
    80004b1e:	cb89                	beqz	a5,80004b30 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b20:	85ca                	mv	a1,s2
    80004b22:	8526                	mv	a0,s1
    80004b24:	ffffe097          	auipc	ra,0xffffe
    80004b28:	c52080e7          	jalr	-942(ra) # 80002776 <sleep>
  while (lk->locked) {
    80004b2c:	409c                	lw	a5,0(s1)
    80004b2e:	fbed                	bnez	a5,80004b20 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b30:	4785                	li	a5,1
    80004b32:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	0f2080e7          	jalr	242(ra) # 80001c26 <myproc>
    80004b3c:	591c                	lw	a5,48(a0)
    80004b3e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b40:	854a                	mv	a0,s2
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	156080e7          	jalr	342(ra) # 80000c98 <release>
}
    80004b4a:	60e2                	ld	ra,24(sp)
    80004b4c:	6442                	ld	s0,16(sp)
    80004b4e:	64a2                	ld	s1,8(sp)
    80004b50:	6902                	ld	s2,0(sp)
    80004b52:	6105                	addi	sp,sp,32
    80004b54:	8082                	ret

0000000080004b56 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b56:	1101                	addi	sp,sp,-32
    80004b58:	ec06                	sd	ra,24(sp)
    80004b5a:	e822                	sd	s0,16(sp)
    80004b5c:	e426                	sd	s1,8(sp)
    80004b5e:	e04a                	sd	s2,0(sp)
    80004b60:	1000                	addi	s0,sp,32
    80004b62:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b64:	00850913          	addi	s2,a0,8
    80004b68:	854a                	mv	a0,s2
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	07a080e7          	jalr	122(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b72:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b76:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b7a:	8526                	mv	a0,s1
    80004b7c:	ffffe097          	auipc	ra,0xffffe
    80004b80:	d90080e7          	jalr	-624(ra) # 8000290c <wakeup>
  release(&lk->lk);
    80004b84:	854a                	mv	a0,s2
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	112080e7          	jalr	274(ra) # 80000c98 <release>
}
    80004b8e:	60e2                	ld	ra,24(sp)
    80004b90:	6442                	ld	s0,16(sp)
    80004b92:	64a2                	ld	s1,8(sp)
    80004b94:	6902                	ld	s2,0(sp)
    80004b96:	6105                	addi	sp,sp,32
    80004b98:	8082                	ret

0000000080004b9a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b9a:	7179                	addi	sp,sp,-48
    80004b9c:	f406                	sd	ra,40(sp)
    80004b9e:	f022                	sd	s0,32(sp)
    80004ba0:	ec26                	sd	s1,24(sp)
    80004ba2:	e84a                	sd	s2,16(sp)
    80004ba4:	e44e                	sd	s3,8(sp)
    80004ba6:	1800                	addi	s0,sp,48
    80004ba8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004baa:	00850913          	addi	s2,a0,8
    80004bae:	854a                	mv	a0,s2
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	034080e7          	jalr	52(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bb8:	409c                	lw	a5,0(s1)
    80004bba:	ef99                	bnez	a5,80004bd8 <holdingsleep+0x3e>
    80004bbc:	4481                	li	s1,0
  release(&lk->lk);
    80004bbe:	854a                	mv	a0,s2
    80004bc0:	ffffc097          	auipc	ra,0xffffc
    80004bc4:	0d8080e7          	jalr	216(ra) # 80000c98 <release>
  return r;
}
    80004bc8:	8526                	mv	a0,s1
    80004bca:	70a2                	ld	ra,40(sp)
    80004bcc:	7402                	ld	s0,32(sp)
    80004bce:	64e2                	ld	s1,24(sp)
    80004bd0:	6942                	ld	s2,16(sp)
    80004bd2:	69a2                	ld	s3,8(sp)
    80004bd4:	6145                	addi	sp,sp,48
    80004bd6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bd8:	0284a983          	lw	s3,40(s1)
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	04a080e7          	jalr	74(ra) # 80001c26 <myproc>
    80004be4:	5904                	lw	s1,48(a0)
    80004be6:	413484b3          	sub	s1,s1,s3
    80004bea:	0014b493          	seqz	s1,s1
    80004bee:	bfc1                	j	80004bbe <holdingsleep+0x24>

0000000080004bf0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004bf0:	1141                	addi	sp,sp,-16
    80004bf2:	e406                	sd	ra,8(sp)
    80004bf4:	e022                	sd	s0,0(sp)
    80004bf6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004bf8:	00004597          	auipc	a1,0x4
    80004bfc:	b6058593          	addi	a1,a1,-1184 # 80008758 <syscalls+0x250>
    80004c00:	0001d517          	auipc	a0,0x1d
    80004c04:	fd850513          	addi	a0,a0,-40 # 80021bd8 <ftable>
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	f4c080e7          	jalr	-180(ra) # 80000b54 <initlock>
}
    80004c10:	60a2                	ld	ra,8(sp)
    80004c12:	6402                	ld	s0,0(sp)
    80004c14:	0141                	addi	sp,sp,16
    80004c16:	8082                	ret

0000000080004c18 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c18:	1101                	addi	sp,sp,-32
    80004c1a:	ec06                	sd	ra,24(sp)
    80004c1c:	e822                	sd	s0,16(sp)
    80004c1e:	e426                	sd	s1,8(sp)
    80004c20:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c22:	0001d517          	auipc	a0,0x1d
    80004c26:	fb650513          	addi	a0,a0,-74 # 80021bd8 <ftable>
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	fba080e7          	jalr	-70(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c32:	0001d497          	auipc	s1,0x1d
    80004c36:	fbe48493          	addi	s1,s1,-66 # 80021bf0 <ftable+0x18>
    80004c3a:	0001e717          	auipc	a4,0x1e
    80004c3e:	f5670713          	addi	a4,a4,-170 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004c42:	40dc                	lw	a5,4(s1)
    80004c44:	cf99                	beqz	a5,80004c62 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c46:	02848493          	addi	s1,s1,40
    80004c4a:	fee49ce3          	bne	s1,a4,80004c42 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c4e:	0001d517          	auipc	a0,0x1d
    80004c52:	f8a50513          	addi	a0,a0,-118 # 80021bd8 <ftable>
    80004c56:	ffffc097          	auipc	ra,0xffffc
    80004c5a:	042080e7          	jalr	66(ra) # 80000c98 <release>
  return 0;
    80004c5e:	4481                	li	s1,0
    80004c60:	a819                	j	80004c76 <filealloc+0x5e>
      f->ref = 1;
    80004c62:	4785                	li	a5,1
    80004c64:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c66:	0001d517          	auipc	a0,0x1d
    80004c6a:	f7250513          	addi	a0,a0,-142 # 80021bd8 <ftable>
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	02a080e7          	jalr	42(ra) # 80000c98 <release>
}
    80004c76:	8526                	mv	a0,s1
    80004c78:	60e2                	ld	ra,24(sp)
    80004c7a:	6442                	ld	s0,16(sp)
    80004c7c:	64a2                	ld	s1,8(sp)
    80004c7e:	6105                	addi	sp,sp,32
    80004c80:	8082                	ret

0000000080004c82 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c82:	1101                	addi	sp,sp,-32
    80004c84:	ec06                	sd	ra,24(sp)
    80004c86:	e822                	sd	s0,16(sp)
    80004c88:	e426                	sd	s1,8(sp)
    80004c8a:	1000                	addi	s0,sp,32
    80004c8c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c8e:	0001d517          	auipc	a0,0x1d
    80004c92:	f4a50513          	addi	a0,a0,-182 # 80021bd8 <ftable>
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	f4e080e7          	jalr	-178(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c9e:	40dc                	lw	a5,4(s1)
    80004ca0:	02f05263          	blez	a5,80004cc4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ca4:	2785                	addiw	a5,a5,1
    80004ca6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ca8:	0001d517          	auipc	a0,0x1d
    80004cac:	f3050513          	addi	a0,a0,-208 # 80021bd8 <ftable>
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	fe8080e7          	jalr	-24(ra) # 80000c98 <release>
  return f;
}
    80004cb8:	8526                	mv	a0,s1
    80004cba:	60e2                	ld	ra,24(sp)
    80004cbc:	6442                	ld	s0,16(sp)
    80004cbe:	64a2                	ld	s1,8(sp)
    80004cc0:	6105                	addi	sp,sp,32
    80004cc2:	8082                	ret
    panic("filedup");
    80004cc4:	00004517          	auipc	a0,0x4
    80004cc8:	a9c50513          	addi	a0,a0,-1380 # 80008760 <syscalls+0x258>
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	872080e7          	jalr	-1934(ra) # 8000053e <panic>

0000000080004cd4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cd4:	7139                	addi	sp,sp,-64
    80004cd6:	fc06                	sd	ra,56(sp)
    80004cd8:	f822                	sd	s0,48(sp)
    80004cda:	f426                	sd	s1,40(sp)
    80004cdc:	f04a                	sd	s2,32(sp)
    80004cde:	ec4e                	sd	s3,24(sp)
    80004ce0:	e852                	sd	s4,16(sp)
    80004ce2:	e456                	sd	s5,8(sp)
    80004ce4:	0080                	addi	s0,sp,64
    80004ce6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ce8:	0001d517          	auipc	a0,0x1d
    80004cec:	ef050513          	addi	a0,a0,-272 # 80021bd8 <ftable>
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	ef4080e7          	jalr	-268(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004cf8:	40dc                	lw	a5,4(s1)
    80004cfa:	06f05163          	blez	a5,80004d5c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cfe:	37fd                	addiw	a5,a5,-1
    80004d00:	0007871b          	sext.w	a4,a5
    80004d04:	c0dc                	sw	a5,4(s1)
    80004d06:	06e04363          	bgtz	a4,80004d6c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d0a:	0004a903          	lw	s2,0(s1)
    80004d0e:	0094ca83          	lbu	s5,9(s1)
    80004d12:	0104ba03          	ld	s4,16(s1)
    80004d16:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d1a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d1e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d22:	0001d517          	auipc	a0,0x1d
    80004d26:	eb650513          	addi	a0,a0,-330 # 80021bd8 <ftable>
    80004d2a:	ffffc097          	auipc	ra,0xffffc
    80004d2e:	f6e080e7          	jalr	-146(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004d32:	4785                	li	a5,1
    80004d34:	04f90d63          	beq	s2,a5,80004d8e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d38:	3979                	addiw	s2,s2,-2
    80004d3a:	4785                	li	a5,1
    80004d3c:	0527e063          	bltu	a5,s2,80004d7c <fileclose+0xa8>
    begin_op();
    80004d40:	00000097          	auipc	ra,0x0
    80004d44:	ac8080e7          	jalr	-1336(ra) # 80004808 <begin_op>
    iput(ff.ip);
    80004d48:	854e                	mv	a0,s3
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	2a6080e7          	jalr	678(ra) # 80003ff0 <iput>
    end_op();
    80004d52:	00000097          	auipc	ra,0x0
    80004d56:	b36080e7          	jalr	-1226(ra) # 80004888 <end_op>
    80004d5a:	a00d                	j	80004d7c <fileclose+0xa8>
    panic("fileclose");
    80004d5c:	00004517          	auipc	a0,0x4
    80004d60:	a0c50513          	addi	a0,a0,-1524 # 80008768 <syscalls+0x260>
    80004d64:	ffffb097          	auipc	ra,0xffffb
    80004d68:	7da080e7          	jalr	2010(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d6c:	0001d517          	auipc	a0,0x1d
    80004d70:	e6c50513          	addi	a0,a0,-404 # 80021bd8 <ftable>
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	f24080e7          	jalr	-220(ra) # 80000c98 <release>
  }
}
    80004d7c:	70e2                	ld	ra,56(sp)
    80004d7e:	7442                	ld	s0,48(sp)
    80004d80:	74a2                	ld	s1,40(sp)
    80004d82:	7902                	ld	s2,32(sp)
    80004d84:	69e2                	ld	s3,24(sp)
    80004d86:	6a42                	ld	s4,16(sp)
    80004d88:	6aa2                	ld	s5,8(sp)
    80004d8a:	6121                	addi	sp,sp,64
    80004d8c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d8e:	85d6                	mv	a1,s5
    80004d90:	8552                	mv	a0,s4
    80004d92:	00000097          	auipc	ra,0x0
    80004d96:	34c080e7          	jalr	844(ra) # 800050de <pipeclose>
    80004d9a:	b7cd                	j	80004d7c <fileclose+0xa8>

0000000080004d9c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d9c:	715d                	addi	sp,sp,-80
    80004d9e:	e486                	sd	ra,72(sp)
    80004da0:	e0a2                	sd	s0,64(sp)
    80004da2:	fc26                	sd	s1,56(sp)
    80004da4:	f84a                	sd	s2,48(sp)
    80004da6:	f44e                	sd	s3,40(sp)
    80004da8:	0880                	addi	s0,sp,80
    80004daa:	84aa                	mv	s1,a0
    80004dac:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004dae:	ffffd097          	auipc	ra,0xffffd
    80004db2:	e78080e7          	jalr	-392(ra) # 80001c26 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004db6:	409c                	lw	a5,0(s1)
    80004db8:	37f9                	addiw	a5,a5,-2
    80004dba:	4705                	li	a4,1
    80004dbc:	04f76763          	bltu	a4,a5,80004e0a <filestat+0x6e>
    80004dc0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004dc2:	6c88                	ld	a0,24(s1)
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	072080e7          	jalr	114(ra) # 80003e36 <ilock>
    stati(f->ip, &st);
    80004dcc:	fb840593          	addi	a1,s0,-72
    80004dd0:	6c88                	ld	a0,24(s1)
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	2ee080e7          	jalr	750(ra) # 800040c0 <stati>
    iunlock(f->ip);
    80004dda:	6c88                	ld	a0,24(s1)
    80004ddc:	fffff097          	auipc	ra,0xfffff
    80004de0:	11c080e7          	jalr	284(ra) # 80003ef8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004de4:	46e1                	li	a3,24
    80004de6:	fb840613          	addi	a2,s0,-72
    80004dea:	85ce                	mv	a1,s3
    80004dec:	07093503          	ld	a0,112(s2)
    80004df0:	ffffd097          	auipc	ra,0xffffd
    80004df4:	9a6080e7          	jalr	-1626(ra) # 80001796 <copyout>
    80004df8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dfc:	60a6                	ld	ra,72(sp)
    80004dfe:	6406                	ld	s0,64(sp)
    80004e00:	74e2                	ld	s1,56(sp)
    80004e02:	7942                	ld	s2,48(sp)
    80004e04:	79a2                	ld	s3,40(sp)
    80004e06:	6161                	addi	sp,sp,80
    80004e08:	8082                	ret
  return -1;
    80004e0a:	557d                	li	a0,-1
    80004e0c:	bfc5                	j	80004dfc <filestat+0x60>

0000000080004e0e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e0e:	7179                	addi	sp,sp,-48
    80004e10:	f406                	sd	ra,40(sp)
    80004e12:	f022                	sd	s0,32(sp)
    80004e14:	ec26                	sd	s1,24(sp)
    80004e16:	e84a                	sd	s2,16(sp)
    80004e18:	e44e                	sd	s3,8(sp)
    80004e1a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e1c:	00854783          	lbu	a5,8(a0)
    80004e20:	c3d5                	beqz	a5,80004ec4 <fileread+0xb6>
    80004e22:	84aa                	mv	s1,a0
    80004e24:	89ae                	mv	s3,a1
    80004e26:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e28:	411c                	lw	a5,0(a0)
    80004e2a:	4705                	li	a4,1
    80004e2c:	04e78963          	beq	a5,a4,80004e7e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e30:	470d                	li	a4,3
    80004e32:	04e78d63          	beq	a5,a4,80004e8c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e36:	4709                	li	a4,2
    80004e38:	06e79e63          	bne	a5,a4,80004eb4 <fileread+0xa6>
    ilock(f->ip);
    80004e3c:	6d08                	ld	a0,24(a0)
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	ff8080e7          	jalr	-8(ra) # 80003e36 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e46:	874a                	mv	a4,s2
    80004e48:	5094                	lw	a3,32(s1)
    80004e4a:	864e                	mv	a2,s3
    80004e4c:	4585                	li	a1,1
    80004e4e:	6c88                	ld	a0,24(s1)
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	29a080e7          	jalr	666(ra) # 800040ea <readi>
    80004e58:	892a                	mv	s2,a0
    80004e5a:	00a05563          	blez	a0,80004e64 <fileread+0x56>
      f->off += r;
    80004e5e:	509c                	lw	a5,32(s1)
    80004e60:	9fa9                	addw	a5,a5,a0
    80004e62:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e64:	6c88                	ld	a0,24(s1)
    80004e66:	fffff097          	auipc	ra,0xfffff
    80004e6a:	092080e7          	jalr	146(ra) # 80003ef8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e6e:	854a                	mv	a0,s2
    80004e70:	70a2                	ld	ra,40(sp)
    80004e72:	7402                	ld	s0,32(sp)
    80004e74:	64e2                	ld	s1,24(sp)
    80004e76:	6942                	ld	s2,16(sp)
    80004e78:	69a2                	ld	s3,8(sp)
    80004e7a:	6145                	addi	sp,sp,48
    80004e7c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e7e:	6908                	ld	a0,16(a0)
    80004e80:	00000097          	auipc	ra,0x0
    80004e84:	3c8080e7          	jalr	968(ra) # 80005248 <piperead>
    80004e88:	892a                	mv	s2,a0
    80004e8a:	b7d5                	j	80004e6e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e8c:	02451783          	lh	a5,36(a0)
    80004e90:	03079693          	slli	a3,a5,0x30
    80004e94:	92c1                	srli	a3,a3,0x30
    80004e96:	4725                	li	a4,9
    80004e98:	02d76863          	bltu	a4,a3,80004ec8 <fileread+0xba>
    80004e9c:	0792                	slli	a5,a5,0x4
    80004e9e:	0001d717          	auipc	a4,0x1d
    80004ea2:	c9a70713          	addi	a4,a4,-870 # 80021b38 <devsw>
    80004ea6:	97ba                	add	a5,a5,a4
    80004ea8:	639c                	ld	a5,0(a5)
    80004eaa:	c38d                	beqz	a5,80004ecc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004eac:	4505                	li	a0,1
    80004eae:	9782                	jalr	a5
    80004eb0:	892a                	mv	s2,a0
    80004eb2:	bf75                	j	80004e6e <fileread+0x60>
    panic("fileread");
    80004eb4:	00004517          	auipc	a0,0x4
    80004eb8:	8c450513          	addi	a0,a0,-1852 # 80008778 <syscalls+0x270>
    80004ebc:	ffffb097          	auipc	ra,0xffffb
    80004ec0:	682080e7          	jalr	1666(ra) # 8000053e <panic>
    return -1;
    80004ec4:	597d                	li	s2,-1
    80004ec6:	b765                	j	80004e6e <fileread+0x60>
      return -1;
    80004ec8:	597d                	li	s2,-1
    80004eca:	b755                	j	80004e6e <fileread+0x60>
    80004ecc:	597d                	li	s2,-1
    80004ece:	b745                	j	80004e6e <fileread+0x60>

0000000080004ed0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ed0:	715d                	addi	sp,sp,-80
    80004ed2:	e486                	sd	ra,72(sp)
    80004ed4:	e0a2                	sd	s0,64(sp)
    80004ed6:	fc26                	sd	s1,56(sp)
    80004ed8:	f84a                	sd	s2,48(sp)
    80004eda:	f44e                	sd	s3,40(sp)
    80004edc:	f052                	sd	s4,32(sp)
    80004ede:	ec56                	sd	s5,24(sp)
    80004ee0:	e85a                	sd	s6,16(sp)
    80004ee2:	e45e                	sd	s7,8(sp)
    80004ee4:	e062                	sd	s8,0(sp)
    80004ee6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ee8:	00954783          	lbu	a5,9(a0)
    80004eec:	10078663          	beqz	a5,80004ff8 <filewrite+0x128>
    80004ef0:	892a                	mv	s2,a0
    80004ef2:	8aae                	mv	s5,a1
    80004ef4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ef6:	411c                	lw	a5,0(a0)
    80004ef8:	4705                	li	a4,1
    80004efa:	02e78263          	beq	a5,a4,80004f1e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004efe:	470d                	li	a4,3
    80004f00:	02e78663          	beq	a5,a4,80004f2c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f04:	4709                	li	a4,2
    80004f06:	0ee79163          	bne	a5,a4,80004fe8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f0a:	0ac05d63          	blez	a2,80004fc4 <filewrite+0xf4>
    int i = 0;
    80004f0e:	4981                	li	s3,0
    80004f10:	6b05                	lui	s6,0x1
    80004f12:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f16:	6b85                	lui	s7,0x1
    80004f18:	c00b8b9b          	addiw	s7,s7,-1024
    80004f1c:	a861                	j	80004fb4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f1e:	6908                	ld	a0,16(a0)
    80004f20:	00000097          	auipc	ra,0x0
    80004f24:	22e080e7          	jalr	558(ra) # 8000514e <pipewrite>
    80004f28:	8a2a                	mv	s4,a0
    80004f2a:	a045                	j	80004fca <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f2c:	02451783          	lh	a5,36(a0)
    80004f30:	03079693          	slli	a3,a5,0x30
    80004f34:	92c1                	srli	a3,a3,0x30
    80004f36:	4725                	li	a4,9
    80004f38:	0cd76263          	bltu	a4,a3,80004ffc <filewrite+0x12c>
    80004f3c:	0792                	slli	a5,a5,0x4
    80004f3e:	0001d717          	auipc	a4,0x1d
    80004f42:	bfa70713          	addi	a4,a4,-1030 # 80021b38 <devsw>
    80004f46:	97ba                	add	a5,a5,a4
    80004f48:	679c                	ld	a5,8(a5)
    80004f4a:	cbdd                	beqz	a5,80005000 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f4c:	4505                	li	a0,1
    80004f4e:	9782                	jalr	a5
    80004f50:	8a2a                	mv	s4,a0
    80004f52:	a8a5                	j	80004fca <filewrite+0xfa>
    80004f54:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f58:	00000097          	auipc	ra,0x0
    80004f5c:	8b0080e7          	jalr	-1872(ra) # 80004808 <begin_op>
      ilock(f->ip);
    80004f60:	01893503          	ld	a0,24(s2)
    80004f64:	fffff097          	auipc	ra,0xfffff
    80004f68:	ed2080e7          	jalr	-302(ra) # 80003e36 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f6c:	8762                	mv	a4,s8
    80004f6e:	02092683          	lw	a3,32(s2)
    80004f72:	01598633          	add	a2,s3,s5
    80004f76:	4585                	li	a1,1
    80004f78:	01893503          	ld	a0,24(s2)
    80004f7c:	fffff097          	auipc	ra,0xfffff
    80004f80:	266080e7          	jalr	614(ra) # 800041e2 <writei>
    80004f84:	84aa                	mv	s1,a0
    80004f86:	00a05763          	blez	a0,80004f94 <filewrite+0xc4>
        f->off += r;
    80004f8a:	02092783          	lw	a5,32(s2)
    80004f8e:	9fa9                	addw	a5,a5,a0
    80004f90:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f94:	01893503          	ld	a0,24(s2)
    80004f98:	fffff097          	auipc	ra,0xfffff
    80004f9c:	f60080e7          	jalr	-160(ra) # 80003ef8 <iunlock>
      end_op();
    80004fa0:	00000097          	auipc	ra,0x0
    80004fa4:	8e8080e7          	jalr	-1816(ra) # 80004888 <end_op>

      if(r != n1){
    80004fa8:	009c1f63          	bne	s8,s1,80004fc6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004fac:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004fb0:	0149db63          	bge	s3,s4,80004fc6 <filewrite+0xf6>
      int n1 = n - i;
    80004fb4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004fb8:	84be                	mv	s1,a5
    80004fba:	2781                	sext.w	a5,a5
    80004fbc:	f8fb5ce3          	bge	s6,a5,80004f54 <filewrite+0x84>
    80004fc0:	84de                	mv	s1,s7
    80004fc2:	bf49                	j	80004f54 <filewrite+0x84>
    int i = 0;
    80004fc4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fc6:	013a1f63          	bne	s4,s3,80004fe4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fca:	8552                	mv	a0,s4
    80004fcc:	60a6                	ld	ra,72(sp)
    80004fce:	6406                	ld	s0,64(sp)
    80004fd0:	74e2                	ld	s1,56(sp)
    80004fd2:	7942                	ld	s2,48(sp)
    80004fd4:	79a2                	ld	s3,40(sp)
    80004fd6:	7a02                	ld	s4,32(sp)
    80004fd8:	6ae2                	ld	s5,24(sp)
    80004fda:	6b42                	ld	s6,16(sp)
    80004fdc:	6ba2                	ld	s7,8(sp)
    80004fde:	6c02                	ld	s8,0(sp)
    80004fe0:	6161                	addi	sp,sp,80
    80004fe2:	8082                	ret
    ret = (i == n ? n : -1);
    80004fe4:	5a7d                	li	s4,-1
    80004fe6:	b7d5                	j	80004fca <filewrite+0xfa>
    panic("filewrite");
    80004fe8:	00003517          	auipc	a0,0x3
    80004fec:	7a050513          	addi	a0,a0,1952 # 80008788 <syscalls+0x280>
    80004ff0:	ffffb097          	auipc	ra,0xffffb
    80004ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>
    return -1;
    80004ff8:	5a7d                	li	s4,-1
    80004ffa:	bfc1                	j	80004fca <filewrite+0xfa>
      return -1;
    80004ffc:	5a7d                	li	s4,-1
    80004ffe:	b7f1                	j	80004fca <filewrite+0xfa>
    80005000:	5a7d                	li	s4,-1
    80005002:	b7e1                	j	80004fca <filewrite+0xfa>

0000000080005004 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005004:	7179                	addi	sp,sp,-48
    80005006:	f406                	sd	ra,40(sp)
    80005008:	f022                	sd	s0,32(sp)
    8000500a:	ec26                	sd	s1,24(sp)
    8000500c:	e84a                	sd	s2,16(sp)
    8000500e:	e44e                	sd	s3,8(sp)
    80005010:	e052                	sd	s4,0(sp)
    80005012:	1800                	addi	s0,sp,48
    80005014:	84aa                	mv	s1,a0
    80005016:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005018:	0005b023          	sd	zero,0(a1)
    8000501c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005020:	00000097          	auipc	ra,0x0
    80005024:	bf8080e7          	jalr	-1032(ra) # 80004c18 <filealloc>
    80005028:	e088                	sd	a0,0(s1)
    8000502a:	c551                	beqz	a0,800050b6 <pipealloc+0xb2>
    8000502c:	00000097          	auipc	ra,0x0
    80005030:	bec080e7          	jalr	-1044(ra) # 80004c18 <filealloc>
    80005034:	00aa3023          	sd	a0,0(s4)
    80005038:	c92d                	beqz	a0,800050aa <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	aba080e7          	jalr	-1350(ra) # 80000af4 <kalloc>
    80005042:	892a                	mv	s2,a0
    80005044:	c125                	beqz	a0,800050a4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005046:	4985                	li	s3,1
    80005048:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000504c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005050:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005054:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005058:	00003597          	auipc	a1,0x3
    8000505c:	74058593          	addi	a1,a1,1856 # 80008798 <syscalls+0x290>
    80005060:	ffffc097          	auipc	ra,0xffffc
    80005064:	af4080e7          	jalr	-1292(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005068:	609c                	ld	a5,0(s1)
    8000506a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000506e:	609c                	ld	a5,0(s1)
    80005070:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005074:	609c                	ld	a5,0(s1)
    80005076:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000507a:	609c                	ld	a5,0(s1)
    8000507c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005080:	000a3783          	ld	a5,0(s4)
    80005084:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005088:	000a3783          	ld	a5,0(s4)
    8000508c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005090:	000a3783          	ld	a5,0(s4)
    80005094:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005098:	000a3783          	ld	a5,0(s4)
    8000509c:	0127b823          	sd	s2,16(a5)
  return 0;
    800050a0:	4501                	li	a0,0
    800050a2:	a025                	j	800050ca <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800050a4:	6088                	ld	a0,0(s1)
    800050a6:	e501                	bnez	a0,800050ae <pipealloc+0xaa>
    800050a8:	a039                	j	800050b6 <pipealloc+0xb2>
    800050aa:	6088                	ld	a0,0(s1)
    800050ac:	c51d                	beqz	a0,800050da <pipealloc+0xd6>
    fileclose(*f0);
    800050ae:	00000097          	auipc	ra,0x0
    800050b2:	c26080e7          	jalr	-986(ra) # 80004cd4 <fileclose>
  if(*f1)
    800050b6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800050ba:	557d                	li	a0,-1
  if(*f1)
    800050bc:	c799                	beqz	a5,800050ca <pipealloc+0xc6>
    fileclose(*f1);
    800050be:	853e                	mv	a0,a5
    800050c0:	00000097          	auipc	ra,0x0
    800050c4:	c14080e7          	jalr	-1004(ra) # 80004cd4 <fileclose>
  return -1;
    800050c8:	557d                	li	a0,-1
}
    800050ca:	70a2                	ld	ra,40(sp)
    800050cc:	7402                	ld	s0,32(sp)
    800050ce:	64e2                	ld	s1,24(sp)
    800050d0:	6942                	ld	s2,16(sp)
    800050d2:	69a2                	ld	s3,8(sp)
    800050d4:	6a02                	ld	s4,0(sp)
    800050d6:	6145                	addi	sp,sp,48
    800050d8:	8082                	ret
  return -1;
    800050da:	557d                	li	a0,-1
    800050dc:	b7fd                	j	800050ca <pipealloc+0xc6>

00000000800050de <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050de:	1101                	addi	sp,sp,-32
    800050e0:	ec06                	sd	ra,24(sp)
    800050e2:	e822                	sd	s0,16(sp)
    800050e4:	e426                	sd	s1,8(sp)
    800050e6:	e04a                	sd	s2,0(sp)
    800050e8:	1000                	addi	s0,sp,32
    800050ea:	84aa                	mv	s1,a0
    800050ec:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	af6080e7          	jalr	-1290(ra) # 80000be4 <acquire>
  if(writable){
    800050f6:	02090d63          	beqz	s2,80005130 <pipeclose+0x52>
    pi->writeopen = 0;
    800050fa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050fe:	21848513          	addi	a0,s1,536
    80005102:	ffffe097          	auipc	ra,0xffffe
    80005106:	80a080e7          	jalr	-2038(ra) # 8000290c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000510a:	2204b783          	ld	a5,544(s1)
    8000510e:	eb95                	bnez	a5,80005142 <pipeclose+0x64>
    release(&pi->lock);
    80005110:	8526                	mv	a0,s1
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	b86080e7          	jalr	-1146(ra) # 80000c98 <release>
    kfree((char*)pi);
    8000511a:	8526                	mv	a0,s1
    8000511c:	ffffc097          	auipc	ra,0xffffc
    80005120:	8dc080e7          	jalr	-1828(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005124:	60e2                	ld	ra,24(sp)
    80005126:	6442                	ld	s0,16(sp)
    80005128:	64a2                	ld	s1,8(sp)
    8000512a:	6902                	ld	s2,0(sp)
    8000512c:	6105                	addi	sp,sp,32
    8000512e:	8082                	ret
    pi->readopen = 0;
    80005130:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005134:	21c48513          	addi	a0,s1,540
    80005138:	ffffd097          	auipc	ra,0xffffd
    8000513c:	7d4080e7          	jalr	2004(ra) # 8000290c <wakeup>
    80005140:	b7e9                	j	8000510a <pipeclose+0x2c>
    release(&pi->lock);
    80005142:	8526                	mv	a0,s1
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	b54080e7          	jalr	-1196(ra) # 80000c98 <release>
}
    8000514c:	bfe1                	j	80005124 <pipeclose+0x46>

000000008000514e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000514e:	7159                	addi	sp,sp,-112
    80005150:	f486                	sd	ra,104(sp)
    80005152:	f0a2                	sd	s0,96(sp)
    80005154:	eca6                	sd	s1,88(sp)
    80005156:	e8ca                	sd	s2,80(sp)
    80005158:	e4ce                	sd	s3,72(sp)
    8000515a:	e0d2                	sd	s4,64(sp)
    8000515c:	fc56                	sd	s5,56(sp)
    8000515e:	f85a                	sd	s6,48(sp)
    80005160:	f45e                	sd	s7,40(sp)
    80005162:	f062                	sd	s8,32(sp)
    80005164:	ec66                	sd	s9,24(sp)
    80005166:	1880                	addi	s0,sp,112
    80005168:	84aa                	mv	s1,a0
    8000516a:	8aae                	mv	s5,a1
    8000516c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000516e:	ffffd097          	auipc	ra,0xffffd
    80005172:	ab8080e7          	jalr	-1352(ra) # 80001c26 <myproc>
    80005176:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005178:	8526                	mv	a0,s1
    8000517a:	ffffc097          	auipc	ra,0xffffc
    8000517e:	a6a080e7          	jalr	-1430(ra) # 80000be4 <acquire>
  while(i < n){
    80005182:	0d405163          	blez	s4,80005244 <pipewrite+0xf6>
    80005186:	8ba6                	mv	s7,s1
  int i = 0;
    80005188:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000518a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000518c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005190:	21c48c13          	addi	s8,s1,540
    80005194:	a08d                	j	800051f6 <pipewrite+0xa8>
      release(&pi->lock);
    80005196:	8526                	mv	a0,s1
    80005198:	ffffc097          	auipc	ra,0xffffc
    8000519c:	b00080e7          	jalr	-1280(ra) # 80000c98 <release>
      return -1;
    800051a0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800051a2:	854a                	mv	a0,s2
    800051a4:	70a6                	ld	ra,104(sp)
    800051a6:	7406                	ld	s0,96(sp)
    800051a8:	64e6                	ld	s1,88(sp)
    800051aa:	6946                	ld	s2,80(sp)
    800051ac:	69a6                	ld	s3,72(sp)
    800051ae:	6a06                	ld	s4,64(sp)
    800051b0:	7ae2                	ld	s5,56(sp)
    800051b2:	7b42                	ld	s6,48(sp)
    800051b4:	7ba2                	ld	s7,40(sp)
    800051b6:	7c02                	ld	s8,32(sp)
    800051b8:	6ce2                	ld	s9,24(sp)
    800051ba:	6165                	addi	sp,sp,112
    800051bc:	8082                	ret
      wakeup(&pi->nread);
    800051be:	8566                	mv	a0,s9
    800051c0:	ffffd097          	auipc	ra,0xffffd
    800051c4:	74c080e7          	jalr	1868(ra) # 8000290c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051c8:	85de                	mv	a1,s7
    800051ca:	8562                	mv	a0,s8
    800051cc:	ffffd097          	auipc	ra,0xffffd
    800051d0:	5aa080e7          	jalr	1450(ra) # 80002776 <sleep>
    800051d4:	a839                	j	800051f2 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051d6:	21c4a783          	lw	a5,540(s1)
    800051da:	0017871b          	addiw	a4,a5,1
    800051de:	20e4ae23          	sw	a4,540(s1)
    800051e2:	1ff7f793          	andi	a5,a5,511
    800051e6:	97a6                	add	a5,a5,s1
    800051e8:	f9f44703          	lbu	a4,-97(s0)
    800051ec:	00e78c23          	sb	a4,24(a5)
      i++;
    800051f0:	2905                	addiw	s2,s2,1
  while(i < n){
    800051f2:	03495d63          	bge	s2,s4,8000522c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800051f6:	2204a783          	lw	a5,544(s1)
    800051fa:	dfd1                	beqz	a5,80005196 <pipewrite+0x48>
    800051fc:	0289a783          	lw	a5,40(s3)
    80005200:	fbd9                	bnez	a5,80005196 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005202:	2184a783          	lw	a5,536(s1)
    80005206:	21c4a703          	lw	a4,540(s1)
    8000520a:	2007879b          	addiw	a5,a5,512
    8000520e:	faf708e3          	beq	a4,a5,800051be <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005212:	4685                	li	a3,1
    80005214:	01590633          	add	a2,s2,s5
    80005218:	f9f40593          	addi	a1,s0,-97
    8000521c:	0709b503          	ld	a0,112(s3)
    80005220:	ffffc097          	auipc	ra,0xffffc
    80005224:	602080e7          	jalr	1538(ra) # 80001822 <copyin>
    80005228:	fb6517e3          	bne	a0,s6,800051d6 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000522c:	21848513          	addi	a0,s1,536
    80005230:	ffffd097          	auipc	ra,0xffffd
    80005234:	6dc080e7          	jalr	1756(ra) # 8000290c <wakeup>
  release(&pi->lock);
    80005238:	8526                	mv	a0,s1
    8000523a:	ffffc097          	auipc	ra,0xffffc
    8000523e:	a5e080e7          	jalr	-1442(ra) # 80000c98 <release>
  return i;
    80005242:	b785                	j	800051a2 <pipewrite+0x54>
  int i = 0;
    80005244:	4901                	li	s2,0
    80005246:	b7dd                	j	8000522c <pipewrite+0xde>

0000000080005248 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005248:	715d                	addi	sp,sp,-80
    8000524a:	e486                	sd	ra,72(sp)
    8000524c:	e0a2                	sd	s0,64(sp)
    8000524e:	fc26                	sd	s1,56(sp)
    80005250:	f84a                	sd	s2,48(sp)
    80005252:	f44e                	sd	s3,40(sp)
    80005254:	f052                	sd	s4,32(sp)
    80005256:	ec56                	sd	s5,24(sp)
    80005258:	e85a                	sd	s6,16(sp)
    8000525a:	0880                	addi	s0,sp,80
    8000525c:	84aa                	mv	s1,a0
    8000525e:	892e                	mv	s2,a1
    80005260:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005262:	ffffd097          	auipc	ra,0xffffd
    80005266:	9c4080e7          	jalr	-1596(ra) # 80001c26 <myproc>
    8000526a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000526c:	8b26                	mv	s6,s1
    8000526e:	8526                	mv	a0,s1
    80005270:	ffffc097          	auipc	ra,0xffffc
    80005274:	974080e7          	jalr	-1676(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005278:	2184a703          	lw	a4,536(s1)
    8000527c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005280:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005284:	02f71463          	bne	a4,a5,800052ac <piperead+0x64>
    80005288:	2244a783          	lw	a5,548(s1)
    8000528c:	c385                	beqz	a5,800052ac <piperead+0x64>
    if(pr->killed){
    8000528e:	028a2783          	lw	a5,40(s4)
    80005292:	ebc1                	bnez	a5,80005322 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005294:	85da                	mv	a1,s6
    80005296:	854e                	mv	a0,s3
    80005298:	ffffd097          	auipc	ra,0xffffd
    8000529c:	4de080e7          	jalr	1246(ra) # 80002776 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052a0:	2184a703          	lw	a4,536(s1)
    800052a4:	21c4a783          	lw	a5,540(s1)
    800052a8:	fef700e3          	beq	a4,a5,80005288 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052ac:	09505263          	blez	s5,80005330 <piperead+0xe8>
    800052b0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052b2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800052b4:	2184a783          	lw	a5,536(s1)
    800052b8:	21c4a703          	lw	a4,540(s1)
    800052bc:	02f70d63          	beq	a4,a5,800052f6 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052c0:	0017871b          	addiw	a4,a5,1
    800052c4:	20e4ac23          	sw	a4,536(s1)
    800052c8:	1ff7f793          	andi	a5,a5,511
    800052cc:	97a6                	add	a5,a5,s1
    800052ce:	0187c783          	lbu	a5,24(a5)
    800052d2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052d6:	4685                	li	a3,1
    800052d8:	fbf40613          	addi	a2,s0,-65
    800052dc:	85ca                	mv	a1,s2
    800052de:	070a3503          	ld	a0,112(s4)
    800052e2:	ffffc097          	auipc	ra,0xffffc
    800052e6:	4b4080e7          	jalr	1204(ra) # 80001796 <copyout>
    800052ea:	01650663          	beq	a0,s6,800052f6 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052ee:	2985                	addiw	s3,s3,1
    800052f0:	0905                	addi	s2,s2,1
    800052f2:	fd3a91e3          	bne	s5,s3,800052b4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052f6:	21c48513          	addi	a0,s1,540
    800052fa:	ffffd097          	auipc	ra,0xffffd
    800052fe:	612080e7          	jalr	1554(ra) # 8000290c <wakeup>
  release(&pi->lock);
    80005302:	8526                	mv	a0,s1
    80005304:	ffffc097          	auipc	ra,0xffffc
    80005308:	994080e7          	jalr	-1644(ra) # 80000c98 <release>
  return i;
}
    8000530c:	854e                	mv	a0,s3
    8000530e:	60a6                	ld	ra,72(sp)
    80005310:	6406                	ld	s0,64(sp)
    80005312:	74e2                	ld	s1,56(sp)
    80005314:	7942                	ld	s2,48(sp)
    80005316:	79a2                	ld	s3,40(sp)
    80005318:	7a02                	ld	s4,32(sp)
    8000531a:	6ae2                	ld	s5,24(sp)
    8000531c:	6b42                	ld	s6,16(sp)
    8000531e:	6161                	addi	sp,sp,80
    80005320:	8082                	ret
      release(&pi->lock);
    80005322:	8526                	mv	a0,s1
    80005324:	ffffc097          	auipc	ra,0xffffc
    80005328:	974080e7          	jalr	-1676(ra) # 80000c98 <release>
      return -1;
    8000532c:	59fd                	li	s3,-1
    8000532e:	bff9                	j	8000530c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005330:	4981                	li	s3,0
    80005332:	b7d1                	j	800052f6 <piperead+0xae>

0000000080005334 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005334:	df010113          	addi	sp,sp,-528
    80005338:	20113423          	sd	ra,520(sp)
    8000533c:	20813023          	sd	s0,512(sp)
    80005340:	ffa6                	sd	s1,504(sp)
    80005342:	fbca                	sd	s2,496(sp)
    80005344:	f7ce                	sd	s3,488(sp)
    80005346:	f3d2                	sd	s4,480(sp)
    80005348:	efd6                	sd	s5,472(sp)
    8000534a:	ebda                	sd	s6,464(sp)
    8000534c:	e7de                	sd	s7,456(sp)
    8000534e:	e3e2                	sd	s8,448(sp)
    80005350:	ff66                	sd	s9,440(sp)
    80005352:	fb6a                	sd	s10,432(sp)
    80005354:	f76e                	sd	s11,424(sp)
    80005356:	0c00                	addi	s0,sp,528
    80005358:	84aa                	mv	s1,a0
    8000535a:	dea43c23          	sd	a0,-520(s0)
    8000535e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005362:	ffffd097          	auipc	ra,0xffffd
    80005366:	8c4080e7          	jalr	-1852(ra) # 80001c26 <myproc>
    8000536a:	892a                	mv	s2,a0

  begin_op();
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	49c080e7          	jalr	1180(ra) # 80004808 <begin_op>

  if((ip = namei(path)) == 0){
    80005374:	8526                	mv	a0,s1
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	276080e7          	jalr	630(ra) # 800045ec <namei>
    8000537e:	c92d                	beqz	a0,800053f0 <exec+0xbc>
    80005380:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	ab4080e7          	jalr	-1356(ra) # 80003e36 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000538a:	04000713          	li	a4,64
    8000538e:	4681                	li	a3,0
    80005390:	e5040613          	addi	a2,s0,-432
    80005394:	4581                	li	a1,0
    80005396:	8526                	mv	a0,s1
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	d52080e7          	jalr	-686(ra) # 800040ea <readi>
    800053a0:	04000793          	li	a5,64
    800053a4:	00f51a63          	bne	a0,a5,800053b8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800053a8:	e5042703          	lw	a4,-432(s0)
    800053ac:	464c47b7          	lui	a5,0x464c4
    800053b0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053b4:	04f70463          	beq	a4,a5,800053fc <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053b8:	8526                	mv	a0,s1
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	cde080e7          	jalr	-802(ra) # 80004098 <iunlockput>
    end_op();
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	4c6080e7          	jalr	1222(ra) # 80004888 <end_op>
  }
  return -1;
    800053ca:	557d                	li	a0,-1
}
    800053cc:	20813083          	ld	ra,520(sp)
    800053d0:	20013403          	ld	s0,512(sp)
    800053d4:	74fe                	ld	s1,504(sp)
    800053d6:	795e                	ld	s2,496(sp)
    800053d8:	79be                	ld	s3,488(sp)
    800053da:	7a1e                	ld	s4,480(sp)
    800053dc:	6afe                	ld	s5,472(sp)
    800053de:	6b5e                	ld	s6,464(sp)
    800053e0:	6bbe                	ld	s7,456(sp)
    800053e2:	6c1e                	ld	s8,448(sp)
    800053e4:	7cfa                	ld	s9,440(sp)
    800053e6:	7d5a                	ld	s10,432(sp)
    800053e8:	7dba                	ld	s11,424(sp)
    800053ea:	21010113          	addi	sp,sp,528
    800053ee:	8082                	ret
    end_op();
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	498080e7          	jalr	1176(ra) # 80004888 <end_op>
    return -1;
    800053f8:	557d                	li	a0,-1
    800053fa:	bfc9                	j	800053cc <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053fc:	854a                	mv	a0,s2
    800053fe:	ffffd097          	auipc	ra,0xffffd
    80005402:	8ec080e7          	jalr	-1812(ra) # 80001cea <proc_pagetable>
    80005406:	8baa                	mv	s7,a0
    80005408:	d945                	beqz	a0,800053b8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000540a:	e7042983          	lw	s3,-400(s0)
    8000540e:	e8845783          	lhu	a5,-376(s0)
    80005412:	c7ad                	beqz	a5,8000547c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005414:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005416:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005418:	6c85                	lui	s9,0x1
    8000541a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000541e:	def43823          	sd	a5,-528(s0)
    80005422:	a42d                	j	8000564c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005424:	00003517          	auipc	a0,0x3
    80005428:	37c50513          	addi	a0,a0,892 # 800087a0 <syscalls+0x298>
    8000542c:	ffffb097          	auipc	ra,0xffffb
    80005430:	112080e7          	jalr	274(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005434:	8756                	mv	a4,s5
    80005436:	012d86bb          	addw	a3,s11,s2
    8000543a:	4581                	li	a1,0
    8000543c:	8526                	mv	a0,s1
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	cac080e7          	jalr	-852(ra) # 800040ea <readi>
    80005446:	2501                	sext.w	a0,a0
    80005448:	1aaa9963          	bne	s5,a0,800055fa <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000544c:	6785                	lui	a5,0x1
    8000544e:	0127893b          	addw	s2,a5,s2
    80005452:	77fd                	lui	a5,0xfffff
    80005454:	01478a3b          	addw	s4,a5,s4
    80005458:	1f897163          	bgeu	s2,s8,8000563a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000545c:	02091593          	slli	a1,s2,0x20
    80005460:	9181                	srli	a1,a1,0x20
    80005462:	95ea                	add	a1,a1,s10
    80005464:	855e                	mv	a0,s7
    80005466:	ffffc097          	auipc	ra,0xffffc
    8000546a:	d2c080e7          	jalr	-724(ra) # 80001192 <walkaddr>
    8000546e:	862a                	mv	a2,a0
    if(pa == 0)
    80005470:	d955                	beqz	a0,80005424 <exec+0xf0>
      n = PGSIZE;
    80005472:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005474:	fd9a70e3          	bgeu	s4,s9,80005434 <exec+0x100>
      n = sz - i;
    80005478:	8ad2                	mv	s5,s4
    8000547a:	bf6d                	j	80005434 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000547c:	4901                	li	s2,0
  iunlockput(ip);
    8000547e:	8526                	mv	a0,s1
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	c18080e7          	jalr	-1000(ra) # 80004098 <iunlockput>
  end_op();
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	400080e7          	jalr	1024(ra) # 80004888 <end_op>
  p = myproc();
    80005490:	ffffc097          	auipc	ra,0xffffc
    80005494:	796080e7          	jalr	1942(ra) # 80001c26 <myproc>
    80005498:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000549a:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    8000549e:	6785                	lui	a5,0x1
    800054a0:	17fd                	addi	a5,a5,-1
    800054a2:	993e                	add	s2,s2,a5
    800054a4:	757d                	lui	a0,0xfffff
    800054a6:	00a977b3          	and	a5,s2,a0
    800054aa:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054ae:	6609                	lui	a2,0x2
    800054b0:	963e                	add	a2,a2,a5
    800054b2:	85be                	mv	a1,a5
    800054b4:	855e                	mv	a0,s7
    800054b6:	ffffc097          	auipc	ra,0xffffc
    800054ba:	090080e7          	jalr	144(ra) # 80001546 <uvmalloc>
    800054be:	8b2a                	mv	s6,a0
  ip = 0;
    800054c0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054c2:	12050c63          	beqz	a0,800055fa <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054c6:	75f9                	lui	a1,0xffffe
    800054c8:	95aa                	add	a1,a1,a0
    800054ca:	855e                	mv	a0,s7
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	298080e7          	jalr	664(ra) # 80001764 <uvmclear>
  stackbase = sp - PGSIZE;
    800054d4:	7c7d                	lui	s8,0xfffff
    800054d6:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800054d8:	e0043783          	ld	a5,-512(s0)
    800054dc:	6388                	ld	a0,0(a5)
    800054de:	c535                	beqz	a0,8000554a <exec+0x216>
    800054e0:	e9040993          	addi	s3,s0,-368
    800054e4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054e8:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800054ea:	ffffc097          	auipc	ra,0xffffc
    800054ee:	97a080e7          	jalr	-1670(ra) # 80000e64 <strlen>
    800054f2:	2505                	addiw	a0,a0,1
    800054f4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054f8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054fc:	13896363          	bltu	s2,s8,80005622 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005500:	e0043d83          	ld	s11,-512(s0)
    80005504:	000dba03          	ld	s4,0(s11)
    80005508:	8552                	mv	a0,s4
    8000550a:	ffffc097          	auipc	ra,0xffffc
    8000550e:	95a080e7          	jalr	-1702(ra) # 80000e64 <strlen>
    80005512:	0015069b          	addiw	a3,a0,1
    80005516:	8652                	mv	a2,s4
    80005518:	85ca                	mv	a1,s2
    8000551a:	855e                	mv	a0,s7
    8000551c:	ffffc097          	auipc	ra,0xffffc
    80005520:	27a080e7          	jalr	634(ra) # 80001796 <copyout>
    80005524:	10054363          	bltz	a0,8000562a <exec+0x2f6>
    ustack[argc] = sp;
    80005528:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000552c:	0485                	addi	s1,s1,1
    8000552e:	008d8793          	addi	a5,s11,8
    80005532:	e0f43023          	sd	a5,-512(s0)
    80005536:	008db503          	ld	a0,8(s11)
    8000553a:	c911                	beqz	a0,8000554e <exec+0x21a>
    if(argc >= MAXARG)
    8000553c:	09a1                	addi	s3,s3,8
    8000553e:	fb3c96e3          	bne	s9,s3,800054ea <exec+0x1b6>
  sz = sz1;
    80005542:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005546:	4481                	li	s1,0
    80005548:	a84d                	j	800055fa <exec+0x2c6>
  sp = sz;
    8000554a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000554c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000554e:	00349793          	slli	a5,s1,0x3
    80005552:	f9040713          	addi	a4,s0,-112
    80005556:	97ba                	add	a5,a5,a4
    80005558:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000555c:	00148693          	addi	a3,s1,1
    80005560:	068e                	slli	a3,a3,0x3
    80005562:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005566:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000556a:	01897663          	bgeu	s2,s8,80005576 <exec+0x242>
  sz = sz1;
    8000556e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005572:	4481                	li	s1,0
    80005574:	a059                	j	800055fa <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005576:	e9040613          	addi	a2,s0,-368
    8000557a:	85ca                	mv	a1,s2
    8000557c:	855e                	mv	a0,s7
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	218080e7          	jalr	536(ra) # 80001796 <copyout>
    80005586:	0a054663          	bltz	a0,80005632 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000558a:	078ab783          	ld	a5,120(s5)
    8000558e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005592:	df843783          	ld	a5,-520(s0)
    80005596:	0007c703          	lbu	a4,0(a5)
    8000559a:	cf11                	beqz	a4,800055b6 <exec+0x282>
    8000559c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000559e:	02f00693          	li	a3,47
    800055a2:	a039                	j	800055b0 <exec+0x27c>
      last = s+1;
    800055a4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055a8:	0785                	addi	a5,a5,1
    800055aa:	fff7c703          	lbu	a4,-1(a5)
    800055ae:	c701                	beqz	a4,800055b6 <exec+0x282>
    if(*s == '/')
    800055b0:	fed71ce3          	bne	a4,a3,800055a8 <exec+0x274>
    800055b4:	bfc5                	j	800055a4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800055b6:	4641                	li	a2,16
    800055b8:	df843583          	ld	a1,-520(s0)
    800055bc:	178a8513          	addi	a0,s5,376
    800055c0:	ffffc097          	auipc	ra,0xffffc
    800055c4:	872080e7          	jalr	-1934(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800055c8:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800055cc:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800055d0:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055d4:	078ab783          	ld	a5,120(s5)
    800055d8:	e6843703          	ld	a4,-408(s0)
    800055dc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055de:	078ab783          	ld	a5,120(s5)
    800055e2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055e6:	85ea                	mv	a1,s10
    800055e8:	ffffc097          	auipc	ra,0xffffc
    800055ec:	79e080e7          	jalr	1950(ra) # 80001d86 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055f0:	0004851b          	sext.w	a0,s1
    800055f4:	bbe1                	j	800053cc <exec+0x98>
    800055f6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055fa:	e0843583          	ld	a1,-504(s0)
    800055fe:	855e                	mv	a0,s7
    80005600:	ffffc097          	auipc	ra,0xffffc
    80005604:	786080e7          	jalr	1926(ra) # 80001d86 <proc_freepagetable>
  if(ip){
    80005608:	da0498e3          	bnez	s1,800053b8 <exec+0x84>
  return -1;
    8000560c:	557d                	li	a0,-1
    8000560e:	bb7d                	j	800053cc <exec+0x98>
    80005610:	e1243423          	sd	s2,-504(s0)
    80005614:	b7dd                	j	800055fa <exec+0x2c6>
    80005616:	e1243423          	sd	s2,-504(s0)
    8000561a:	b7c5                	j	800055fa <exec+0x2c6>
    8000561c:	e1243423          	sd	s2,-504(s0)
    80005620:	bfe9                	j	800055fa <exec+0x2c6>
  sz = sz1;
    80005622:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005626:	4481                	li	s1,0
    80005628:	bfc9                	j	800055fa <exec+0x2c6>
  sz = sz1;
    8000562a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000562e:	4481                	li	s1,0
    80005630:	b7e9                	j	800055fa <exec+0x2c6>
  sz = sz1;
    80005632:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005636:	4481                	li	s1,0
    80005638:	b7c9                	j	800055fa <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000563a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000563e:	2b05                	addiw	s6,s6,1
    80005640:	0389899b          	addiw	s3,s3,56
    80005644:	e8845783          	lhu	a5,-376(s0)
    80005648:	e2fb5be3          	bge	s6,a5,8000547e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000564c:	2981                	sext.w	s3,s3
    8000564e:	03800713          	li	a4,56
    80005652:	86ce                	mv	a3,s3
    80005654:	e1840613          	addi	a2,s0,-488
    80005658:	4581                	li	a1,0
    8000565a:	8526                	mv	a0,s1
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	a8e080e7          	jalr	-1394(ra) # 800040ea <readi>
    80005664:	03800793          	li	a5,56
    80005668:	f8f517e3          	bne	a0,a5,800055f6 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000566c:	e1842783          	lw	a5,-488(s0)
    80005670:	4705                	li	a4,1
    80005672:	fce796e3          	bne	a5,a4,8000563e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005676:	e4043603          	ld	a2,-448(s0)
    8000567a:	e3843783          	ld	a5,-456(s0)
    8000567e:	f8f669e3          	bltu	a2,a5,80005610 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005682:	e2843783          	ld	a5,-472(s0)
    80005686:	963e                	add	a2,a2,a5
    80005688:	f8f667e3          	bltu	a2,a5,80005616 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000568c:	85ca                	mv	a1,s2
    8000568e:	855e                	mv	a0,s7
    80005690:	ffffc097          	auipc	ra,0xffffc
    80005694:	eb6080e7          	jalr	-330(ra) # 80001546 <uvmalloc>
    80005698:	e0a43423          	sd	a0,-504(s0)
    8000569c:	d141                	beqz	a0,8000561c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000569e:	e2843d03          	ld	s10,-472(s0)
    800056a2:	df043783          	ld	a5,-528(s0)
    800056a6:	00fd77b3          	and	a5,s10,a5
    800056aa:	fba1                	bnez	a5,800055fa <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056ac:	e2042d83          	lw	s11,-480(s0)
    800056b0:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056b4:	f80c03e3          	beqz	s8,8000563a <exec+0x306>
    800056b8:	8a62                	mv	s4,s8
    800056ba:	4901                	li	s2,0
    800056bc:	b345                	j	8000545c <exec+0x128>

00000000800056be <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056be:	7179                	addi	sp,sp,-48
    800056c0:	f406                	sd	ra,40(sp)
    800056c2:	f022                	sd	s0,32(sp)
    800056c4:	ec26                	sd	s1,24(sp)
    800056c6:	e84a                	sd	s2,16(sp)
    800056c8:	1800                	addi	s0,sp,48
    800056ca:	892e                	mv	s2,a1
    800056cc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056ce:	fdc40593          	addi	a1,s0,-36
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	b90080e7          	jalr	-1136(ra) # 80003262 <argint>
    800056da:	04054063          	bltz	a0,8000571a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056de:	fdc42703          	lw	a4,-36(s0)
    800056e2:	47bd                	li	a5,15
    800056e4:	02e7ed63          	bltu	a5,a4,8000571e <argfd+0x60>
    800056e8:	ffffc097          	auipc	ra,0xffffc
    800056ec:	53e080e7          	jalr	1342(ra) # 80001c26 <myproc>
    800056f0:	fdc42703          	lw	a4,-36(s0)
    800056f4:	01e70793          	addi	a5,a4,30
    800056f8:	078e                	slli	a5,a5,0x3
    800056fa:	953e                	add	a0,a0,a5
    800056fc:	611c                	ld	a5,0(a0)
    800056fe:	c395                	beqz	a5,80005722 <argfd+0x64>
    return -1;
  if(pfd)
    80005700:	00090463          	beqz	s2,80005708 <argfd+0x4a>
    *pfd = fd;
    80005704:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005708:	4501                	li	a0,0
  if(pf)
    8000570a:	c091                	beqz	s1,8000570e <argfd+0x50>
    *pf = f;
    8000570c:	e09c                	sd	a5,0(s1)
}
    8000570e:	70a2                	ld	ra,40(sp)
    80005710:	7402                	ld	s0,32(sp)
    80005712:	64e2                	ld	s1,24(sp)
    80005714:	6942                	ld	s2,16(sp)
    80005716:	6145                	addi	sp,sp,48
    80005718:	8082                	ret
    return -1;
    8000571a:	557d                	li	a0,-1
    8000571c:	bfcd                	j	8000570e <argfd+0x50>
    return -1;
    8000571e:	557d                	li	a0,-1
    80005720:	b7fd                	j	8000570e <argfd+0x50>
    80005722:	557d                	li	a0,-1
    80005724:	b7ed                	j	8000570e <argfd+0x50>

0000000080005726 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005726:	1101                	addi	sp,sp,-32
    80005728:	ec06                	sd	ra,24(sp)
    8000572a:	e822                	sd	s0,16(sp)
    8000572c:	e426                	sd	s1,8(sp)
    8000572e:	1000                	addi	s0,sp,32
    80005730:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005732:	ffffc097          	auipc	ra,0xffffc
    80005736:	4f4080e7          	jalr	1268(ra) # 80001c26 <myproc>
    8000573a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000573c:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005740:	4501                	li	a0,0
    80005742:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005744:	6398                	ld	a4,0(a5)
    80005746:	cb19                	beqz	a4,8000575c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005748:	2505                	addiw	a0,a0,1
    8000574a:	07a1                	addi	a5,a5,8
    8000574c:	fed51ce3          	bne	a0,a3,80005744 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005750:	557d                	li	a0,-1
}
    80005752:	60e2                	ld	ra,24(sp)
    80005754:	6442                	ld	s0,16(sp)
    80005756:	64a2                	ld	s1,8(sp)
    80005758:	6105                	addi	sp,sp,32
    8000575a:	8082                	ret
      p->ofile[fd] = f;
    8000575c:	01e50793          	addi	a5,a0,30
    80005760:	078e                	slli	a5,a5,0x3
    80005762:	963e                	add	a2,a2,a5
    80005764:	e204                	sd	s1,0(a2)
      return fd;
    80005766:	b7f5                	j	80005752 <fdalloc+0x2c>

0000000080005768 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005768:	715d                	addi	sp,sp,-80
    8000576a:	e486                	sd	ra,72(sp)
    8000576c:	e0a2                	sd	s0,64(sp)
    8000576e:	fc26                	sd	s1,56(sp)
    80005770:	f84a                	sd	s2,48(sp)
    80005772:	f44e                	sd	s3,40(sp)
    80005774:	f052                	sd	s4,32(sp)
    80005776:	ec56                	sd	s5,24(sp)
    80005778:	0880                	addi	s0,sp,80
    8000577a:	89ae                	mv	s3,a1
    8000577c:	8ab2                	mv	s5,a2
    8000577e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005780:	fb040593          	addi	a1,s0,-80
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	e86080e7          	jalr	-378(ra) # 8000460a <nameiparent>
    8000578c:	892a                	mv	s2,a0
    8000578e:	12050f63          	beqz	a0,800058cc <create+0x164>
    return 0;

  ilock(dp);
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	6a4080e7          	jalr	1700(ra) # 80003e36 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000579a:	4601                	li	a2,0
    8000579c:	fb040593          	addi	a1,s0,-80
    800057a0:	854a                	mv	a0,s2
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	b78080e7          	jalr	-1160(ra) # 8000431a <dirlookup>
    800057aa:	84aa                	mv	s1,a0
    800057ac:	c921                	beqz	a0,800057fc <create+0x94>
    iunlockput(dp);
    800057ae:	854a                	mv	a0,s2
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	8e8080e7          	jalr	-1816(ra) # 80004098 <iunlockput>
    ilock(ip);
    800057b8:	8526                	mv	a0,s1
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	67c080e7          	jalr	1660(ra) # 80003e36 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057c2:	2981                	sext.w	s3,s3
    800057c4:	4789                	li	a5,2
    800057c6:	02f99463          	bne	s3,a5,800057ee <create+0x86>
    800057ca:	0444d783          	lhu	a5,68(s1)
    800057ce:	37f9                	addiw	a5,a5,-2
    800057d0:	17c2                	slli	a5,a5,0x30
    800057d2:	93c1                	srli	a5,a5,0x30
    800057d4:	4705                	li	a4,1
    800057d6:	00f76c63          	bltu	a4,a5,800057ee <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800057da:	8526                	mv	a0,s1
    800057dc:	60a6                	ld	ra,72(sp)
    800057de:	6406                	ld	s0,64(sp)
    800057e0:	74e2                	ld	s1,56(sp)
    800057e2:	7942                	ld	s2,48(sp)
    800057e4:	79a2                	ld	s3,40(sp)
    800057e6:	7a02                	ld	s4,32(sp)
    800057e8:	6ae2                	ld	s5,24(sp)
    800057ea:	6161                	addi	sp,sp,80
    800057ec:	8082                	ret
    iunlockput(ip);
    800057ee:	8526                	mv	a0,s1
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	8a8080e7          	jalr	-1880(ra) # 80004098 <iunlockput>
    return 0;
    800057f8:	4481                	li	s1,0
    800057fa:	b7c5                	j	800057da <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057fc:	85ce                	mv	a1,s3
    800057fe:	00092503          	lw	a0,0(s2)
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	49c080e7          	jalr	1180(ra) # 80003c9e <ialloc>
    8000580a:	84aa                	mv	s1,a0
    8000580c:	c529                	beqz	a0,80005856 <create+0xee>
  ilock(ip);
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	628080e7          	jalr	1576(ra) # 80003e36 <ilock>
  ip->major = major;
    80005816:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000581a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000581e:	4785                	li	a5,1
    80005820:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	546080e7          	jalr	1350(ra) # 80003d6c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000582e:	2981                	sext.w	s3,s3
    80005830:	4785                	li	a5,1
    80005832:	02f98a63          	beq	s3,a5,80005866 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005836:	40d0                	lw	a2,4(s1)
    80005838:	fb040593          	addi	a1,s0,-80
    8000583c:	854a                	mv	a0,s2
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	cec080e7          	jalr	-788(ra) # 8000452a <dirlink>
    80005846:	06054b63          	bltz	a0,800058bc <create+0x154>
  iunlockput(dp);
    8000584a:	854a                	mv	a0,s2
    8000584c:	fffff097          	auipc	ra,0xfffff
    80005850:	84c080e7          	jalr	-1972(ra) # 80004098 <iunlockput>
  return ip;
    80005854:	b759                	j	800057da <create+0x72>
    panic("create: ialloc");
    80005856:	00003517          	auipc	a0,0x3
    8000585a:	f6a50513          	addi	a0,a0,-150 # 800087c0 <syscalls+0x2b8>
    8000585e:	ffffb097          	auipc	ra,0xffffb
    80005862:	ce0080e7          	jalr	-800(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005866:	04a95783          	lhu	a5,74(s2)
    8000586a:	2785                	addiw	a5,a5,1
    8000586c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005870:	854a                	mv	a0,s2
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	4fa080e7          	jalr	1274(ra) # 80003d6c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000587a:	40d0                	lw	a2,4(s1)
    8000587c:	00003597          	auipc	a1,0x3
    80005880:	f5458593          	addi	a1,a1,-172 # 800087d0 <syscalls+0x2c8>
    80005884:	8526                	mv	a0,s1
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	ca4080e7          	jalr	-860(ra) # 8000452a <dirlink>
    8000588e:	00054f63          	bltz	a0,800058ac <create+0x144>
    80005892:	00492603          	lw	a2,4(s2)
    80005896:	00003597          	auipc	a1,0x3
    8000589a:	f4258593          	addi	a1,a1,-190 # 800087d8 <syscalls+0x2d0>
    8000589e:	8526                	mv	a0,s1
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	c8a080e7          	jalr	-886(ra) # 8000452a <dirlink>
    800058a8:	f80557e3          	bgez	a0,80005836 <create+0xce>
      panic("create dots");
    800058ac:	00003517          	auipc	a0,0x3
    800058b0:	f3450513          	addi	a0,a0,-204 # 800087e0 <syscalls+0x2d8>
    800058b4:	ffffb097          	auipc	ra,0xffffb
    800058b8:	c8a080e7          	jalr	-886(ra) # 8000053e <panic>
    panic("create: dirlink");
    800058bc:	00003517          	auipc	a0,0x3
    800058c0:	f3450513          	addi	a0,a0,-204 # 800087f0 <syscalls+0x2e8>
    800058c4:	ffffb097          	auipc	ra,0xffffb
    800058c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>
    return 0;
    800058cc:	84aa                	mv	s1,a0
    800058ce:	b731                	j	800057da <create+0x72>

00000000800058d0 <sys_dup>:
{
    800058d0:	7179                	addi	sp,sp,-48
    800058d2:	f406                	sd	ra,40(sp)
    800058d4:	f022                	sd	s0,32(sp)
    800058d6:	ec26                	sd	s1,24(sp)
    800058d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058da:	fd840613          	addi	a2,s0,-40
    800058de:	4581                	li	a1,0
    800058e0:	4501                	li	a0,0
    800058e2:	00000097          	auipc	ra,0x0
    800058e6:	ddc080e7          	jalr	-548(ra) # 800056be <argfd>
    return -1;
    800058ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058ec:	02054363          	bltz	a0,80005912 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058f0:	fd843503          	ld	a0,-40(s0)
    800058f4:	00000097          	auipc	ra,0x0
    800058f8:	e32080e7          	jalr	-462(ra) # 80005726 <fdalloc>
    800058fc:	84aa                	mv	s1,a0
    return -1;
    800058fe:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005900:	00054963          	bltz	a0,80005912 <sys_dup+0x42>
  filedup(f);
    80005904:	fd843503          	ld	a0,-40(s0)
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	37a080e7          	jalr	890(ra) # 80004c82 <filedup>
  return fd;
    80005910:	87a6                	mv	a5,s1
}
    80005912:	853e                	mv	a0,a5
    80005914:	70a2                	ld	ra,40(sp)
    80005916:	7402                	ld	s0,32(sp)
    80005918:	64e2                	ld	s1,24(sp)
    8000591a:	6145                	addi	sp,sp,48
    8000591c:	8082                	ret

000000008000591e <sys_read>:
{
    8000591e:	7179                	addi	sp,sp,-48
    80005920:	f406                	sd	ra,40(sp)
    80005922:	f022                	sd	s0,32(sp)
    80005924:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005926:	fe840613          	addi	a2,s0,-24
    8000592a:	4581                	li	a1,0
    8000592c:	4501                	li	a0,0
    8000592e:	00000097          	auipc	ra,0x0
    80005932:	d90080e7          	jalr	-624(ra) # 800056be <argfd>
    return -1;
    80005936:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005938:	04054163          	bltz	a0,8000597a <sys_read+0x5c>
    8000593c:	fe440593          	addi	a1,s0,-28
    80005940:	4509                	li	a0,2
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	920080e7          	jalr	-1760(ra) # 80003262 <argint>
    return -1;
    8000594a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000594c:	02054763          	bltz	a0,8000597a <sys_read+0x5c>
    80005950:	fd840593          	addi	a1,s0,-40
    80005954:	4505                	li	a0,1
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	92e080e7          	jalr	-1746(ra) # 80003284 <argaddr>
    return -1;
    8000595e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005960:	00054d63          	bltz	a0,8000597a <sys_read+0x5c>
  return fileread(f, p, n);
    80005964:	fe442603          	lw	a2,-28(s0)
    80005968:	fd843583          	ld	a1,-40(s0)
    8000596c:	fe843503          	ld	a0,-24(s0)
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	49e080e7          	jalr	1182(ra) # 80004e0e <fileread>
    80005978:	87aa                	mv	a5,a0
}
    8000597a:	853e                	mv	a0,a5
    8000597c:	70a2                	ld	ra,40(sp)
    8000597e:	7402                	ld	s0,32(sp)
    80005980:	6145                	addi	sp,sp,48
    80005982:	8082                	ret

0000000080005984 <sys_write>:
{
    80005984:	7179                	addi	sp,sp,-48
    80005986:	f406                	sd	ra,40(sp)
    80005988:	f022                	sd	s0,32(sp)
    8000598a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000598c:	fe840613          	addi	a2,s0,-24
    80005990:	4581                	li	a1,0
    80005992:	4501                	li	a0,0
    80005994:	00000097          	auipc	ra,0x0
    80005998:	d2a080e7          	jalr	-726(ra) # 800056be <argfd>
    return -1;
    8000599c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000599e:	04054163          	bltz	a0,800059e0 <sys_write+0x5c>
    800059a2:	fe440593          	addi	a1,s0,-28
    800059a6:	4509                	li	a0,2
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	8ba080e7          	jalr	-1862(ra) # 80003262 <argint>
    return -1;
    800059b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059b2:	02054763          	bltz	a0,800059e0 <sys_write+0x5c>
    800059b6:	fd840593          	addi	a1,s0,-40
    800059ba:	4505                	li	a0,1
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	8c8080e7          	jalr	-1848(ra) # 80003284 <argaddr>
    return -1;
    800059c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059c6:	00054d63          	bltz	a0,800059e0 <sys_write+0x5c>
  return filewrite(f, p, n);
    800059ca:	fe442603          	lw	a2,-28(s0)
    800059ce:	fd843583          	ld	a1,-40(s0)
    800059d2:	fe843503          	ld	a0,-24(s0)
    800059d6:	fffff097          	auipc	ra,0xfffff
    800059da:	4fa080e7          	jalr	1274(ra) # 80004ed0 <filewrite>
    800059de:	87aa                	mv	a5,a0
}
    800059e0:	853e                	mv	a0,a5
    800059e2:	70a2                	ld	ra,40(sp)
    800059e4:	7402                	ld	s0,32(sp)
    800059e6:	6145                	addi	sp,sp,48
    800059e8:	8082                	ret

00000000800059ea <sys_close>:
{
    800059ea:	1101                	addi	sp,sp,-32
    800059ec:	ec06                	sd	ra,24(sp)
    800059ee:	e822                	sd	s0,16(sp)
    800059f0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059f2:	fe040613          	addi	a2,s0,-32
    800059f6:	fec40593          	addi	a1,s0,-20
    800059fa:	4501                	li	a0,0
    800059fc:	00000097          	auipc	ra,0x0
    80005a00:	cc2080e7          	jalr	-830(ra) # 800056be <argfd>
    return -1;
    80005a04:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a06:	02054463          	bltz	a0,80005a2e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a0a:	ffffc097          	auipc	ra,0xffffc
    80005a0e:	21c080e7          	jalr	540(ra) # 80001c26 <myproc>
    80005a12:	fec42783          	lw	a5,-20(s0)
    80005a16:	07f9                	addi	a5,a5,30
    80005a18:	078e                	slli	a5,a5,0x3
    80005a1a:	97aa                	add	a5,a5,a0
    80005a1c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a20:	fe043503          	ld	a0,-32(s0)
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	2b0080e7          	jalr	688(ra) # 80004cd4 <fileclose>
  return 0;
    80005a2c:	4781                	li	a5,0
}
    80005a2e:	853e                	mv	a0,a5
    80005a30:	60e2                	ld	ra,24(sp)
    80005a32:	6442                	ld	s0,16(sp)
    80005a34:	6105                	addi	sp,sp,32
    80005a36:	8082                	ret

0000000080005a38 <sys_fstat>:
{
    80005a38:	1101                	addi	sp,sp,-32
    80005a3a:	ec06                	sd	ra,24(sp)
    80005a3c:	e822                	sd	s0,16(sp)
    80005a3e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a40:	fe840613          	addi	a2,s0,-24
    80005a44:	4581                	li	a1,0
    80005a46:	4501                	li	a0,0
    80005a48:	00000097          	auipc	ra,0x0
    80005a4c:	c76080e7          	jalr	-906(ra) # 800056be <argfd>
    return -1;
    80005a50:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a52:	02054563          	bltz	a0,80005a7c <sys_fstat+0x44>
    80005a56:	fe040593          	addi	a1,s0,-32
    80005a5a:	4505                	li	a0,1
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	828080e7          	jalr	-2008(ra) # 80003284 <argaddr>
    return -1;
    80005a64:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a66:	00054b63          	bltz	a0,80005a7c <sys_fstat+0x44>
  return filestat(f, st);
    80005a6a:	fe043583          	ld	a1,-32(s0)
    80005a6e:	fe843503          	ld	a0,-24(s0)
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	32a080e7          	jalr	810(ra) # 80004d9c <filestat>
    80005a7a:	87aa                	mv	a5,a0
}
    80005a7c:	853e                	mv	a0,a5
    80005a7e:	60e2                	ld	ra,24(sp)
    80005a80:	6442                	ld	s0,16(sp)
    80005a82:	6105                	addi	sp,sp,32
    80005a84:	8082                	ret

0000000080005a86 <sys_link>:
{
    80005a86:	7169                	addi	sp,sp,-304
    80005a88:	f606                	sd	ra,296(sp)
    80005a8a:	f222                	sd	s0,288(sp)
    80005a8c:	ee26                	sd	s1,280(sp)
    80005a8e:	ea4a                	sd	s2,272(sp)
    80005a90:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a92:	08000613          	li	a2,128
    80005a96:	ed040593          	addi	a1,s0,-304
    80005a9a:	4501                	li	a0,0
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	80a080e7          	jalr	-2038(ra) # 800032a6 <argstr>
    return -1;
    80005aa4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aa6:	10054e63          	bltz	a0,80005bc2 <sys_link+0x13c>
    80005aaa:	08000613          	li	a2,128
    80005aae:	f5040593          	addi	a1,s0,-176
    80005ab2:	4505                	li	a0,1
    80005ab4:	ffffd097          	auipc	ra,0xffffd
    80005ab8:	7f2080e7          	jalr	2034(ra) # 800032a6 <argstr>
    return -1;
    80005abc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005abe:	10054263          	bltz	a0,80005bc2 <sys_link+0x13c>
  begin_op();
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	d46080e7          	jalr	-698(ra) # 80004808 <begin_op>
  if((ip = namei(old)) == 0){
    80005aca:	ed040513          	addi	a0,s0,-304
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	b1e080e7          	jalr	-1250(ra) # 800045ec <namei>
    80005ad6:	84aa                	mv	s1,a0
    80005ad8:	c551                	beqz	a0,80005b64 <sys_link+0xde>
  ilock(ip);
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	35c080e7          	jalr	860(ra) # 80003e36 <ilock>
  if(ip->type == T_DIR){
    80005ae2:	04449703          	lh	a4,68(s1)
    80005ae6:	4785                	li	a5,1
    80005ae8:	08f70463          	beq	a4,a5,80005b70 <sys_link+0xea>
  ip->nlink++;
    80005aec:	04a4d783          	lhu	a5,74(s1)
    80005af0:	2785                	addiw	a5,a5,1
    80005af2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005af6:	8526                	mv	a0,s1
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	274080e7          	jalr	628(ra) # 80003d6c <iupdate>
  iunlock(ip);
    80005b00:	8526                	mv	a0,s1
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	3f6080e7          	jalr	1014(ra) # 80003ef8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b0a:	fd040593          	addi	a1,s0,-48
    80005b0e:	f5040513          	addi	a0,s0,-176
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	af8080e7          	jalr	-1288(ra) # 8000460a <nameiparent>
    80005b1a:	892a                	mv	s2,a0
    80005b1c:	c935                	beqz	a0,80005b90 <sys_link+0x10a>
  ilock(dp);
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	318080e7          	jalr	792(ra) # 80003e36 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b26:	00092703          	lw	a4,0(s2)
    80005b2a:	409c                	lw	a5,0(s1)
    80005b2c:	04f71d63          	bne	a4,a5,80005b86 <sys_link+0x100>
    80005b30:	40d0                	lw	a2,4(s1)
    80005b32:	fd040593          	addi	a1,s0,-48
    80005b36:	854a                	mv	a0,s2
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	9f2080e7          	jalr	-1550(ra) # 8000452a <dirlink>
    80005b40:	04054363          	bltz	a0,80005b86 <sys_link+0x100>
  iunlockput(dp);
    80005b44:	854a                	mv	a0,s2
    80005b46:	ffffe097          	auipc	ra,0xffffe
    80005b4a:	552080e7          	jalr	1362(ra) # 80004098 <iunlockput>
  iput(ip);
    80005b4e:	8526                	mv	a0,s1
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	4a0080e7          	jalr	1184(ra) # 80003ff0 <iput>
  end_op();
    80005b58:	fffff097          	auipc	ra,0xfffff
    80005b5c:	d30080e7          	jalr	-720(ra) # 80004888 <end_op>
  return 0;
    80005b60:	4781                	li	a5,0
    80005b62:	a085                	j	80005bc2 <sys_link+0x13c>
    end_op();
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	d24080e7          	jalr	-732(ra) # 80004888 <end_op>
    return -1;
    80005b6c:	57fd                	li	a5,-1
    80005b6e:	a891                	j	80005bc2 <sys_link+0x13c>
    iunlockput(ip);
    80005b70:	8526                	mv	a0,s1
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	526080e7          	jalr	1318(ra) # 80004098 <iunlockput>
    end_op();
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	d0e080e7          	jalr	-754(ra) # 80004888 <end_op>
    return -1;
    80005b82:	57fd                	li	a5,-1
    80005b84:	a83d                	j	80005bc2 <sys_link+0x13c>
    iunlockput(dp);
    80005b86:	854a                	mv	a0,s2
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	510080e7          	jalr	1296(ra) # 80004098 <iunlockput>
  ilock(ip);
    80005b90:	8526                	mv	a0,s1
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	2a4080e7          	jalr	676(ra) # 80003e36 <ilock>
  ip->nlink--;
    80005b9a:	04a4d783          	lhu	a5,74(s1)
    80005b9e:	37fd                	addiw	a5,a5,-1
    80005ba0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ba4:	8526                	mv	a0,s1
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	1c6080e7          	jalr	454(ra) # 80003d6c <iupdate>
  iunlockput(ip);
    80005bae:	8526                	mv	a0,s1
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	4e8080e7          	jalr	1256(ra) # 80004098 <iunlockput>
  end_op();
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	cd0080e7          	jalr	-816(ra) # 80004888 <end_op>
  return -1;
    80005bc0:	57fd                	li	a5,-1
}
    80005bc2:	853e                	mv	a0,a5
    80005bc4:	70b2                	ld	ra,296(sp)
    80005bc6:	7412                	ld	s0,288(sp)
    80005bc8:	64f2                	ld	s1,280(sp)
    80005bca:	6952                	ld	s2,272(sp)
    80005bcc:	6155                	addi	sp,sp,304
    80005bce:	8082                	ret

0000000080005bd0 <sys_unlink>:
{
    80005bd0:	7151                	addi	sp,sp,-240
    80005bd2:	f586                	sd	ra,232(sp)
    80005bd4:	f1a2                	sd	s0,224(sp)
    80005bd6:	eda6                	sd	s1,216(sp)
    80005bd8:	e9ca                	sd	s2,208(sp)
    80005bda:	e5ce                	sd	s3,200(sp)
    80005bdc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005bde:	08000613          	li	a2,128
    80005be2:	f3040593          	addi	a1,s0,-208
    80005be6:	4501                	li	a0,0
    80005be8:	ffffd097          	auipc	ra,0xffffd
    80005bec:	6be080e7          	jalr	1726(ra) # 800032a6 <argstr>
    80005bf0:	18054163          	bltz	a0,80005d72 <sys_unlink+0x1a2>
  begin_op();
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	c14080e7          	jalr	-1004(ra) # 80004808 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bfc:	fb040593          	addi	a1,s0,-80
    80005c00:	f3040513          	addi	a0,s0,-208
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	a06080e7          	jalr	-1530(ra) # 8000460a <nameiparent>
    80005c0c:	84aa                	mv	s1,a0
    80005c0e:	c979                	beqz	a0,80005ce4 <sys_unlink+0x114>
  ilock(dp);
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	226080e7          	jalr	550(ra) # 80003e36 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c18:	00003597          	auipc	a1,0x3
    80005c1c:	bb858593          	addi	a1,a1,-1096 # 800087d0 <syscalls+0x2c8>
    80005c20:	fb040513          	addi	a0,s0,-80
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	6dc080e7          	jalr	1756(ra) # 80004300 <namecmp>
    80005c2c:	14050a63          	beqz	a0,80005d80 <sys_unlink+0x1b0>
    80005c30:	00003597          	auipc	a1,0x3
    80005c34:	ba858593          	addi	a1,a1,-1112 # 800087d8 <syscalls+0x2d0>
    80005c38:	fb040513          	addi	a0,s0,-80
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	6c4080e7          	jalr	1732(ra) # 80004300 <namecmp>
    80005c44:	12050e63          	beqz	a0,80005d80 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c48:	f2c40613          	addi	a2,s0,-212
    80005c4c:	fb040593          	addi	a1,s0,-80
    80005c50:	8526                	mv	a0,s1
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	6c8080e7          	jalr	1736(ra) # 8000431a <dirlookup>
    80005c5a:	892a                	mv	s2,a0
    80005c5c:	12050263          	beqz	a0,80005d80 <sys_unlink+0x1b0>
  ilock(ip);
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	1d6080e7          	jalr	470(ra) # 80003e36 <ilock>
  if(ip->nlink < 1)
    80005c68:	04a91783          	lh	a5,74(s2)
    80005c6c:	08f05263          	blez	a5,80005cf0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c70:	04491703          	lh	a4,68(s2)
    80005c74:	4785                	li	a5,1
    80005c76:	08f70563          	beq	a4,a5,80005d00 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c7a:	4641                	li	a2,16
    80005c7c:	4581                	li	a1,0
    80005c7e:	fc040513          	addi	a0,s0,-64
    80005c82:	ffffb097          	auipc	ra,0xffffb
    80005c86:	05e080e7          	jalr	94(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c8a:	4741                	li	a4,16
    80005c8c:	f2c42683          	lw	a3,-212(s0)
    80005c90:	fc040613          	addi	a2,s0,-64
    80005c94:	4581                	li	a1,0
    80005c96:	8526                	mv	a0,s1
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	54a080e7          	jalr	1354(ra) # 800041e2 <writei>
    80005ca0:	47c1                	li	a5,16
    80005ca2:	0af51563          	bne	a0,a5,80005d4c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ca6:	04491703          	lh	a4,68(s2)
    80005caa:	4785                	li	a5,1
    80005cac:	0af70863          	beq	a4,a5,80005d5c <sys_unlink+0x18c>
  iunlockput(dp);
    80005cb0:	8526                	mv	a0,s1
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	3e6080e7          	jalr	998(ra) # 80004098 <iunlockput>
  ip->nlink--;
    80005cba:	04a95783          	lhu	a5,74(s2)
    80005cbe:	37fd                	addiw	a5,a5,-1
    80005cc0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005cc4:	854a                	mv	a0,s2
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	0a6080e7          	jalr	166(ra) # 80003d6c <iupdate>
  iunlockput(ip);
    80005cce:	854a                	mv	a0,s2
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	3c8080e7          	jalr	968(ra) # 80004098 <iunlockput>
  end_op();
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	bb0080e7          	jalr	-1104(ra) # 80004888 <end_op>
  return 0;
    80005ce0:	4501                	li	a0,0
    80005ce2:	a84d                	j	80005d94 <sys_unlink+0x1c4>
    end_op();
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	ba4080e7          	jalr	-1116(ra) # 80004888 <end_op>
    return -1;
    80005cec:	557d                	li	a0,-1
    80005cee:	a05d                	j	80005d94 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005cf0:	00003517          	auipc	a0,0x3
    80005cf4:	b1050513          	addi	a0,a0,-1264 # 80008800 <syscalls+0x2f8>
    80005cf8:	ffffb097          	auipc	ra,0xffffb
    80005cfc:	846080e7          	jalr	-1978(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d00:	04c92703          	lw	a4,76(s2)
    80005d04:	02000793          	li	a5,32
    80005d08:	f6e7f9e3          	bgeu	a5,a4,80005c7a <sys_unlink+0xaa>
    80005d0c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d10:	4741                	li	a4,16
    80005d12:	86ce                	mv	a3,s3
    80005d14:	f1840613          	addi	a2,s0,-232
    80005d18:	4581                	li	a1,0
    80005d1a:	854a                	mv	a0,s2
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	3ce080e7          	jalr	974(ra) # 800040ea <readi>
    80005d24:	47c1                	li	a5,16
    80005d26:	00f51b63          	bne	a0,a5,80005d3c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d2a:	f1845783          	lhu	a5,-232(s0)
    80005d2e:	e7a1                	bnez	a5,80005d76 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d30:	29c1                	addiw	s3,s3,16
    80005d32:	04c92783          	lw	a5,76(s2)
    80005d36:	fcf9ede3          	bltu	s3,a5,80005d10 <sys_unlink+0x140>
    80005d3a:	b781                	j	80005c7a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d3c:	00003517          	auipc	a0,0x3
    80005d40:	adc50513          	addi	a0,a0,-1316 # 80008818 <syscalls+0x310>
    80005d44:	ffffa097          	auipc	ra,0xffffa
    80005d48:	7fa080e7          	jalr	2042(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d4c:	00003517          	auipc	a0,0x3
    80005d50:	ae450513          	addi	a0,a0,-1308 # 80008830 <syscalls+0x328>
    80005d54:	ffffa097          	auipc	ra,0xffffa
    80005d58:	7ea080e7          	jalr	2026(ra) # 8000053e <panic>
    dp->nlink--;
    80005d5c:	04a4d783          	lhu	a5,74(s1)
    80005d60:	37fd                	addiw	a5,a5,-1
    80005d62:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d66:	8526                	mv	a0,s1
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	004080e7          	jalr	4(ra) # 80003d6c <iupdate>
    80005d70:	b781                	j	80005cb0 <sys_unlink+0xe0>
    return -1;
    80005d72:	557d                	li	a0,-1
    80005d74:	a005                	j	80005d94 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d76:	854a                	mv	a0,s2
    80005d78:	ffffe097          	auipc	ra,0xffffe
    80005d7c:	320080e7          	jalr	800(ra) # 80004098 <iunlockput>
  iunlockput(dp);
    80005d80:	8526                	mv	a0,s1
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	316080e7          	jalr	790(ra) # 80004098 <iunlockput>
  end_op();
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	afe080e7          	jalr	-1282(ra) # 80004888 <end_op>
  return -1;
    80005d92:	557d                	li	a0,-1
}
    80005d94:	70ae                	ld	ra,232(sp)
    80005d96:	740e                	ld	s0,224(sp)
    80005d98:	64ee                	ld	s1,216(sp)
    80005d9a:	694e                	ld	s2,208(sp)
    80005d9c:	69ae                	ld	s3,200(sp)
    80005d9e:	616d                	addi	sp,sp,240
    80005da0:	8082                	ret

0000000080005da2 <sys_open>:

uint64
sys_open(void)
{
    80005da2:	7131                	addi	sp,sp,-192
    80005da4:	fd06                	sd	ra,184(sp)
    80005da6:	f922                	sd	s0,176(sp)
    80005da8:	f526                	sd	s1,168(sp)
    80005daa:	f14a                	sd	s2,160(sp)
    80005dac:	ed4e                	sd	s3,152(sp)
    80005dae:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005db0:	08000613          	li	a2,128
    80005db4:	f5040593          	addi	a1,s0,-176
    80005db8:	4501                	li	a0,0
    80005dba:	ffffd097          	auipc	ra,0xffffd
    80005dbe:	4ec080e7          	jalr	1260(ra) # 800032a6 <argstr>
    return -1;
    80005dc2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005dc4:	0c054163          	bltz	a0,80005e86 <sys_open+0xe4>
    80005dc8:	f4c40593          	addi	a1,s0,-180
    80005dcc:	4505                	li	a0,1
    80005dce:	ffffd097          	auipc	ra,0xffffd
    80005dd2:	494080e7          	jalr	1172(ra) # 80003262 <argint>
    80005dd6:	0a054863          	bltz	a0,80005e86 <sys_open+0xe4>

  begin_op();
    80005dda:	fffff097          	auipc	ra,0xfffff
    80005dde:	a2e080e7          	jalr	-1490(ra) # 80004808 <begin_op>

  if(omode & O_CREATE){
    80005de2:	f4c42783          	lw	a5,-180(s0)
    80005de6:	2007f793          	andi	a5,a5,512
    80005dea:	cbdd                	beqz	a5,80005ea0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005dec:	4681                	li	a3,0
    80005dee:	4601                	li	a2,0
    80005df0:	4589                	li	a1,2
    80005df2:	f5040513          	addi	a0,s0,-176
    80005df6:	00000097          	auipc	ra,0x0
    80005dfa:	972080e7          	jalr	-1678(ra) # 80005768 <create>
    80005dfe:	892a                	mv	s2,a0
    if(ip == 0){
    80005e00:	c959                	beqz	a0,80005e96 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e02:	04491703          	lh	a4,68(s2)
    80005e06:	478d                	li	a5,3
    80005e08:	00f71763          	bne	a4,a5,80005e16 <sys_open+0x74>
    80005e0c:	04695703          	lhu	a4,70(s2)
    80005e10:	47a5                	li	a5,9
    80005e12:	0ce7ec63          	bltu	a5,a4,80005eea <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e16:	fffff097          	auipc	ra,0xfffff
    80005e1a:	e02080e7          	jalr	-510(ra) # 80004c18 <filealloc>
    80005e1e:	89aa                	mv	s3,a0
    80005e20:	10050263          	beqz	a0,80005f24 <sys_open+0x182>
    80005e24:	00000097          	auipc	ra,0x0
    80005e28:	902080e7          	jalr	-1790(ra) # 80005726 <fdalloc>
    80005e2c:	84aa                	mv	s1,a0
    80005e2e:	0e054663          	bltz	a0,80005f1a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e32:	04491703          	lh	a4,68(s2)
    80005e36:	478d                	li	a5,3
    80005e38:	0cf70463          	beq	a4,a5,80005f00 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e3c:	4789                	li	a5,2
    80005e3e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e42:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e46:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e4a:	f4c42783          	lw	a5,-180(s0)
    80005e4e:	0017c713          	xori	a4,a5,1
    80005e52:	8b05                	andi	a4,a4,1
    80005e54:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e58:	0037f713          	andi	a4,a5,3
    80005e5c:	00e03733          	snez	a4,a4
    80005e60:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e64:	4007f793          	andi	a5,a5,1024
    80005e68:	c791                	beqz	a5,80005e74 <sys_open+0xd2>
    80005e6a:	04491703          	lh	a4,68(s2)
    80005e6e:	4789                	li	a5,2
    80005e70:	08f70f63          	beq	a4,a5,80005f0e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e74:	854a                	mv	a0,s2
    80005e76:	ffffe097          	auipc	ra,0xffffe
    80005e7a:	082080e7          	jalr	130(ra) # 80003ef8 <iunlock>
  end_op();
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	a0a080e7          	jalr	-1526(ra) # 80004888 <end_op>

  return fd;
}
    80005e86:	8526                	mv	a0,s1
    80005e88:	70ea                	ld	ra,184(sp)
    80005e8a:	744a                	ld	s0,176(sp)
    80005e8c:	74aa                	ld	s1,168(sp)
    80005e8e:	790a                	ld	s2,160(sp)
    80005e90:	69ea                	ld	s3,152(sp)
    80005e92:	6129                	addi	sp,sp,192
    80005e94:	8082                	ret
      end_op();
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	9f2080e7          	jalr	-1550(ra) # 80004888 <end_op>
      return -1;
    80005e9e:	b7e5                	j	80005e86 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ea0:	f5040513          	addi	a0,s0,-176
    80005ea4:	ffffe097          	auipc	ra,0xffffe
    80005ea8:	748080e7          	jalr	1864(ra) # 800045ec <namei>
    80005eac:	892a                	mv	s2,a0
    80005eae:	c905                	beqz	a0,80005ede <sys_open+0x13c>
    ilock(ip);
    80005eb0:	ffffe097          	auipc	ra,0xffffe
    80005eb4:	f86080e7          	jalr	-122(ra) # 80003e36 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005eb8:	04491703          	lh	a4,68(s2)
    80005ebc:	4785                	li	a5,1
    80005ebe:	f4f712e3          	bne	a4,a5,80005e02 <sys_open+0x60>
    80005ec2:	f4c42783          	lw	a5,-180(s0)
    80005ec6:	dba1                	beqz	a5,80005e16 <sys_open+0x74>
      iunlockput(ip);
    80005ec8:	854a                	mv	a0,s2
    80005eca:	ffffe097          	auipc	ra,0xffffe
    80005ece:	1ce080e7          	jalr	462(ra) # 80004098 <iunlockput>
      end_op();
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	9b6080e7          	jalr	-1610(ra) # 80004888 <end_op>
      return -1;
    80005eda:	54fd                	li	s1,-1
    80005edc:	b76d                	j	80005e86 <sys_open+0xe4>
      end_op();
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	9aa080e7          	jalr	-1622(ra) # 80004888 <end_op>
      return -1;
    80005ee6:	54fd                	li	s1,-1
    80005ee8:	bf79                	j	80005e86 <sys_open+0xe4>
    iunlockput(ip);
    80005eea:	854a                	mv	a0,s2
    80005eec:	ffffe097          	auipc	ra,0xffffe
    80005ef0:	1ac080e7          	jalr	428(ra) # 80004098 <iunlockput>
    end_op();
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	994080e7          	jalr	-1644(ra) # 80004888 <end_op>
    return -1;
    80005efc:	54fd                	li	s1,-1
    80005efe:	b761                	j	80005e86 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f00:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f04:	04691783          	lh	a5,70(s2)
    80005f08:	02f99223          	sh	a5,36(s3)
    80005f0c:	bf2d                	j	80005e46 <sys_open+0xa4>
    itrunc(ip);
    80005f0e:	854a                	mv	a0,s2
    80005f10:	ffffe097          	auipc	ra,0xffffe
    80005f14:	034080e7          	jalr	52(ra) # 80003f44 <itrunc>
    80005f18:	bfb1                	j	80005e74 <sys_open+0xd2>
      fileclose(f);
    80005f1a:	854e                	mv	a0,s3
    80005f1c:	fffff097          	auipc	ra,0xfffff
    80005f20:	db8080e7          	jalr	-584(ra) # 80004cd4 <fileclose>
    iunlockput(ip);
    80005f24:	854a                	mv	a0,s2
    80005f26:	ffffe097          	auipc	ra,0xffffe
    80005f2a:	172080e7          	jalr	370(ra) # 80004098 <iunlockput>
    end_op();
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	95a080e7          	jalr	-1702(ra) # 80004888 <end_op>
    return -1;
    80005f36:	54fd                	li	s1,-1
    80005f38:	b7b9                	j	80005e86 <sys_open+0xe4>

0000000080005f3a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f3a:	7175                	addi	sp,sp,-144
    80005f3c:	e506                	sd	ra,136(sp)
    80005f3e:	e122                	sd	s0,128(sp)
    80005f40:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	8c6080e7          	jalr	-1850(ra) # 80004808 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f4a:	08000613          	li	a2,128
    80005f4e:	f7040593          	addi	a1,s0,-144
    80005f52:	4501                	li	a0,0
    80005f54:	ffffd097          	auipc	ra,0xffffd
    80005f58:	352080e7          	jalr	850(ra) # 800032a6 <argstr>
    80005f5c:	02054963          	bltz	a0,80005f8e <sys_mkdir+0x54>
    80005f60:	4681                	li	a3,0
    80005f62:	4601                	li	a2,0
    80005f64:	4585                	li	a1,1
    80005f66:	f7040513          	addi	a0,s0,-144
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	7fe080e7          	jalr	2046(ra) # 80005768 <create>
    80005f72:	cd11                	beqz	a0,80005f8e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f74:	ffffe097          	auipc	ra,0xffffe
    80005f78:	124080e7          	jalr	292(ra) # 80004098 <iunlockput>
  end_op();
    80005f7c:	fffff097          	auipc	ra,0xfffff
    80005f80:	90c080e7          	jalr	-1780(ra) # 80004888 <end_op>
  return 0;
    80005f84:	4501                	li	a0,0
}
    80005f86:	60aa                	ld	ra,136(sp)
    80005f88:	640a                	ld	s0,128(sp)
    80005f8a:	6149                	addi	sp,sp,144
    80005f8c:	8082                	ret
    end_op();
    80005f8e:	fffff097          	auipc	ra,0xfffff
    80005f92:	8fa080e7          	jalr	-1798(ra) # 80004888 <end_op>
    return -1;
    80005f96:	557d                	li	a0,-1
    80005f98:	b7fd                	j	80005f86 <sys_mkdir+0x4c>

0000000080005f9a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f9a:	7135                	addi	sp,sp,-160
    80005f9c:	ed06                	sd	ra,152(sp)
    80005f9e:	e922                	sd	s0,144(sp)
    80005fa0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fa2:	fffff097          	auipc	ra,0xfffff
    80005fa6:	866080e7          	jalr	-1946(ra) # 80004808 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005faa:	08000613          	li	a2,128
    80005fae:	f7040593          	addi	a1,s0,-144
    80005fb2:	4501                	li	a0,0
    80005fb4:	ffffd097          	auipc	ra,0xffffd
    80005fb8:	2f2080e7          	jalr	754(ra) # 800032a6 <argstr>
    80005fbc:	04054a63          	bltz	a0,80006010 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005fc0:	f6c40593          	addi	a1,s0,-148
    80005fc4:	4505                	li	a0,1
    80005fc6:	ffffd097          	auipc	ra,0xffffd
    80005fca:	29c080e7          	jalr	668(ra) # 80003262 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fce:	04054163          	bltz	a0,80006010 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005fd2:	f6840593          	addi	a1,s0,-152
    80005fd6:	4509                	li	a0,2
    80005fd8:	ffffd097          	auipc	ra,0xffffd
    80005fdc:	28a080e7          	jalr	650(ra) # 80003262 <argint>
     argint(1, &major) < 0 ||
    80005fe0:	02054863          	bltz	a0,80006010 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fe4:	f6841683          	lh	a3,-152(s0)
    80005fe8:	f6c41603          	lh	a2,-148(s0)
    80005fec:	458d                	li	a1,3
    80005fee:	f7040513          	addi	a0,s0,-144
    80005ff2:	fffff097          	auipc	ra,0xfffff
    80005ff6:	776080e7          	jalr	1910(ra) # 80005768 <create>
     argint(2, &minor) < 0 ||
    80005ffa:	c919                	beqz	a0,80006010 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	09c080e7          	jalr	156(ra) # 80004098 <iunlockput>
  end_op();
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	884080e7          	jalr	-1916(ra) # 80004888 <end_op>
  return 0;
    8000600c:	4501                	li	a0,0
    8000600e:	a031                	j	8000601a <sys_mknod+0x80>
    end_op();
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	878080e7          	jalr	-1928(ra) # 80004888 <end_op>
    return -1;
    80006018:	557d                	li	a0,-1
}
    8000601a:	60ea                	ld	ra,152(sp)
    8000601c:	644a                	ld	s0,144(sp)
    8000601e:	610d                	addi	sp,sp,160
    80006020:	8082                	ret

0000000080006022 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006022:	7135                	addi	sp,sp,-160
    80006024:	ed06                	sd	ra,152(sp)
    80006026:	e922                	sd	s0,144(sp)
    80006028:	e526                	sd	s1,136(sp)
    8000602a:	e14a                	sd	s2,128(sp)
    8000602c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000602e:	ffffc097          	auipc	ra,0xffffc
    80006032:	bf8080e7          	jalr	-1032(ra) # 80001c26 <myproc>
    80006036:	892a                	mv	s2,a0
  
  begin_op();
    80006038:	ffffe097          	auipc	ra,0xffffe
    8000603c:	7d0080e7          	jalr	2000(ra) # 80004808 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006040:	08000613          	li	a2,128
    80006044:	f6040593          	addi	a1,s0,-160
    80006048:	4501                	li	a0,0
    8000604a:	ffffd097          	auipc	ra,0xffffd
    8000604e:	25c080e7          	jalr	604(ra) # 800032a6 <argstr>
    80006052:	04054b63          	bltz	a0,800060a8 <sys_chdir+0x86>
    80006056:	f6040513          	addi	a0,s0,-160
    8000605a:	ffffe097          	auipc	ra,0xffffe
    8000605e:	592080e7          	jalr	1426(ra) # 800045ec <namei>
    80006062:	84aa                	mv	s1,a0
    80006064:	c131                	beqz	a0,800060a8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	dd0080e7          	jalr	-560(ra) # 80003e36 <ilock>
  if(ip->type != T_DIR){
    8000606e:	04449703          	lh	a4,68(s1)
    80006072:	4785                	li	a5,1
    80006074:	04f71063          	bne	a4,a5,800060b4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006078:	8526                	mv	a0,s1
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	e7e080e7          	jalr	-386(ra) # 80003ef8 <iunlock>
  iput(p->cwd);
    80006082:	17093503          	ld	a0,368(s2)
    80006086:	ffffe097          	auipc	ra,0xffffe
    8000608a:	f6a080e7          	jalr	-150(ra) # 80003ff0 <iput>
  end_op();
    8000608e:	ffffe097          	auipc	ra,0xffffe
    80006092:	7fa080e7          	jalr	2042(ra) # 80004888 <end_op>
  p->cwd = ip;
    80006096:	16993823          	sd	s1,368(s2)
  return 0;
    8000609a:	4501                	li	a0,0
}
    8000609c:	60ea                	ld	ra,152(sp)
    8000609e:	644a                	ld	s0,144(sp)
    800060a0:	64aa                	ld	s1,136(sp)
    800060a2:	690a                	ld	s2,128(sp)
    800060a4:	610d                	addi	sp,sp,160
    800060a6:	8082                	ret
    end_op();
    800060a8:	ffffe097          	auipc	ra,0xffffe
    800060ac:	7e0080e7          	jalr	2016(ra) # 80004888 <end_op>
    return -1;
    800060b0:	557d                	li	a0,-1
    800060b2:	b7ed                	j	8000609c <sys_chdir+0x7a>
    iunlockput(ip);
    800060b4:	8526                	mv	a0,s1
    800060b6:	ffffe097          	auipc	ra,0xffffe
    800060ba:	fe2080e7          	jalr	-30(ra) # 80004098 <iunlockput>
    end_op();
    800060be:	ffffe097          	auipc	ra,0xffffe
    800060c2:	7ca080e7          	jalr	1994(ra) # 80004888 <end_op>
    return -1;
    800060c6:	557d                	li	a0,-1
    800060c8:	bfd1                	j	8000609c <sys_chdir+0x7a>

00000000800060ca <sys_exec>:

uint64
sys_exec(void)
{
    800060ca:	7145                	addi	sp,sp,-464
    800060cc:	e786                	sd	ra,456(sp)
    800060ce:	e3a2                	sd	s0,448(sp)
    800060d0:	ff26                	sd	s1,440(sp)
    800060d2:	fb4a                	sd	s2,432(sp)
    800060d4:	f74e                	sd	s3,424(sp)
    800060d6:	f352                	sd	s4,416(sp)
    800060d8:	ef56                	sd	s5,408(sp)
    800060da:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060dc:	08000613          	li	a2,128
    800060e0:	f4040593          	addi	a1,s0,-192
    800060e4:	4501                	li	a0,0
    800060e6:	ffffd097          	auipc	ra,0xffffd
    800060ea:	1c0080e7          	jalr	448(ra) # 800032a6 <argstr>
    return -1;
    800060ee:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060f0:	0c054a63          	bltz	a0,800061c4 <sys_exec+0xfa>
    800060f4:	e3840593          	addi	a1,s0,-456
    800060f8:	4505                	li	a0,1
    800060fa:	ffffd097          	auipc	ra,0xffffd
    800060fe:	18a080e7          	jalr	394(ra) # 80003284 <argaddr>
    80006102:	0c054163          	bltz	a0,800061c4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006106:	10000613          	li	a2,256
    8000610a:	4581                	li	a1,0
    8000610c:	e4040513          	addi	a0,s0,-448
    80006110:	ffffb097          	auipc	ra,0xffffb
    80006114:	bd0080e7          	jalr	-1072(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006118:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000611c:	89a6                	mv	s3,s1
    8000611e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006120:	02000a13          	li	s4,32
    80006124:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006128:	00391513          	slli	a0,s2,0x3
    8000612c:	e3040593          	addi	a1,s0,-464
    80006130:	e3843783          	ld	a5,-456(s0)
    80006134:	953e                	add	a0,a0,a5
    80006136:	ffffd097          	auipc	ra,0xffffd
    8000613a:	092080e7          	jalr	146(ra) # 800031c8 <fetchaddr>
    8000613e:	02054a63          	bltz	a0,80006172 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006142:	e3043783          	ld	a5,-464(s0)
    80006146:	c3b9                	beqz	a5,8000618c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006148:	ffffb097          	auipc	ra,0xffffb
    8000614c:	9ac080e7          	jalr	-1620(ra) # 80000af4 <kalloc>
    80006150:	85aa                	mv	a1,a0
    80006152:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006156:	cd11                	beqz	a0,80006172 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006158:	6605                	lui	a2,0x1
    8000615a:	e3043503          	ld	a0,-464(s0)
    8000615e:	ffffd097          	auipc	ra,0xffffd
    80006162:	0bc080e7          	jalr	188(ra) # 8000321a <fetchstr>
    80006166:	00054663          	bltz	a0,80006172 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000616a:	0905                	addi	s2,s2,1
    8000616c:	09a1                	addi	s3,s3,8
    8000616e:	fb491be3          	bne	s2,s4,80006124 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006172:	10048913          	addi	s2,s1,256
    80006176:	6088                	ld	a0,0(s1)
    80006178:	c529                	beqz	a0,800061c2 <sys_exec+0xf8>
    kfree(argv[i]);
    8000617a:	ffffb097          	auipc	ra,0xffffb
    8000617e:	87e080e7          	jalr	-1922(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006182:	04a1                	addi	s1,s1,8
    80006184:	ff2499e3          	bne	s1,s2,80006176 <sys_exec+0xac>
  return -1;
    80006188:	597d                	li	s2,-1
    8000618a:	a82d                	j	800061c4 <sys_exec+0xfa>
      argv[i] = 0;
    8000618c:	0a8e                	slli	s5,s5,0x3
    8000618e:	fc040793          	addi	a5,s0,-64
    80006192:	9abe                	add	s5,s5,a5
    80006194:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006198:	e4040593          	addi	a1,s0,-448
    8000619c:	f4040513          	addi	a0,s0,-192
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	194080e7          	jalr	404(ra) # 80005334 <exec>
    800061a8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061aa:	10048993          	addi	s3,s1,256
    800061ae:	6088                	ld	a0,0(s1)
    800061b0:	c911                	beqz	a0,800061c4 <sys_exec+0xfa>
    kfree(argv[i]);
    800061b2:	ffffb097          	auipc	ra,0xffffb
    800061b6:	846080e7          	jalr	-1978(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061ba:	04a1                	addi	s1,s1,8
    800061bc:	ff3499e3          	bne	s1,s3,800061ae <sys_exec+0xe4>
    800061c0:	a011                	j	800061c4 <sys_exec+0xfa>
  return -1;
    800061c2:	597d                	li	s2,-1
}
    800061c4:	854a                	mv	a0,s2
    800061c6:	60be                	ld	ra,456(sp)
    800061c8:	641e                	ld	s0,448(sp)
    800061ca:	74fa                	ld	s1,440(sp)
    800061cc:	795a                	ld	s2,432(sp)
    800061ce:	79ba                	ld	s3,424(sp)
    800061d0:	7a1a                	ld	s4,416(sp)
    800061d2:	6afa                	ld	s5,408(sp)
    800061d4:	6179                	addi	sp,sp,464
    800061d6:	8082                	ret

00000000800061d8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800061d8:	7139                	addi	sp,sp,-64
    800061da:	fc06                	sd	ra,56(sp)
    800061dc:	f822                	sd	s0,48(sp)
    800061de:	f426                	sd	s1,40(sp)
    800061e0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061e2:	ffffc097          	auipc	ra,0xffffc
    800061e6:	a44080e7          	jalr	-1468(ra) # 80001c26 <myproc>
    800061ea:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800061ec:	fd840593          	addi	a1,s0,-40
    800061f0:	4501                	li	a0,0
    800061f2:	ffffd097          	auipc	ra,0xffffd
    800061f6:	092080e7          	jalr	146(ra) # 80003284 <argaddr>
    return -1;
    800061fa:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061fc:	0e054063          	bltz	a0,800062dc <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006200:	fc840593          	addi	a1,s0,-56
    80006204:	fd040513          	addi	a0,s0,-48
    80006208:	fffff097          	auipc	ra,0xfffff
    8000620c:	dfc080e7          	jalr	-516(ra) # 80005004 <pipealloc>
    return -1;
    80006210:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006212:	0c054563          	bltz	a0,800062dc <sys_pipe+0x104>
  fd0 = -1;
    80006216:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000621a:	fd043503          	ld	a0,-48(s0)
    8000621e:	fffff097          	auipc	ra,0xfffff
    80006222:	508080e7          	jalr	1288(ra) # 80005726 <fdalloc>
    80006226:	fca42223          	sw	a0,-60(s0)
    8000622a:	08054c63          	bltz	a0,800062c2 <sys_pipe+0xea>
    8000622e:	fc843503          	ld	a0,-56(s0)
    80006232:	fffff097          	auipc	ra,0xfffff
    80006236:	4f4080e7          	jalr	1268(ra) # 80005726 <fdalloc>
    8000623a:	fca42023          	sw	a0,-64(s0)
    8000623e:	06054863          	bltz	a0,800062ae <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006242:	4691                	li	a3,4
    80006244:	fc440613          	addi	a2,s0,-60
    80006248:	fd843583          	ld	a1,-40(s0)
    8000624c:	78a8                	ld	a0,112(s1)
    8000624e:	ffffb097          	auipc	ra,0xffffb
    80006252:	548080e7          	jalr	1352(ra) # 80001796 <copyout>
    80006256:	02054063          	bltz	a0,80006276 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000625a:	4691                	li	a3,4
    8000625c:	fc040613          	addi	a2,s0,-64
    80006260:	fd843583          	ld	a1,-40(s0)
    80006264:	0591                	addi	a1,a1,4
    80006266:	78a8                	ld	a0,112(s1)
    80006268:	ffffb097          	auipc	ra,0xffffb
    8000626c:	52e080e7          	jalr	1326(ra) # 80001796 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006270:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006272:	06055563          	bgez	a0,800062dc <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006276:	fc442783          	lw	a5,-60(s0)
    8000627a:	07f9                	addi	a5,a5,30
    8000627c:	078e                	slli	a5,a5,0x3
    8000627e:	97a6                	add	a5,a5,s1
    80006280:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006284:	fc042503          	lw	a0,-64(s0)
    80006288:	0579                	addi	a0,a0,30
    8000628a:	050e                	slli	a0,a0,0x3
    8000628c:	9526                	add	a0,a0,s1
    8000628e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006292:	fd043503          	ld	a0,-48(s0)
    80006296:	fffff097          	auipc	ra,0xfffff
    8000629a:	a3e080e7          	jalr	-1474(ra) # 80004cd4 <fileclose>
    fileclose(wf);
    8000629e:	fc843503          	ld	a0,-56(s0)
    800062a2:	fffff097          	auipc	ra,0xfffff
    800062a6:	a32080e7          	jalr	-1486(ra) # 80004cd4 <fileclose>
    return -1;
    800062aa:	57fd                	li	a5,-1
    800062ac:	a805                	j	800062dc <sys_pipe+0x104>
    if(fd0 >= 0)
    800062ae:	fc442783          	lw	a5,-60(s0)
    800062b2:	0007c863          	bltz	a5,800062c2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800062b6:	01e78513          	addi	a0,a5,30
    800062ba:	050e                	slli	a0,a0,0x3
    800062bc:	9526                	add	a0,a0,s1
    800062be:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062c2:	fd043503          	ld	a0,-48(s0)
    800062c6:	fffff097          	auipc	ra,0xfffff
    800062ca:	a0e080e7          	jalr	-1522(ra) # 80004cd4 <fileclose>
    fileclose(wf);
    800062ce:	fc843503          	ld	a0,-56(s0)
    800062d2:	fffff097          	auipc	ra,0xfffff
    800062d6:	a02080e7          	jalr	-1534(ra) # 80004cd4 <fileclose>
    return -1;
    800062da:	57fd                	li	a5,-1
}
    800062dc:	853e                	mv	a0,a5
    800062de:	70e2                	ld	ra,56(sp)
    800062e0:	7442                	ld	s0,48(sp)
    800062e2:	74a2                	ld	s1,40(sp)
    800062e4:	6121                	addi	sp,sp,64
    800062e6:	8082                	ret
	...

00000000800062f0 <kernelvec>:
    800062f0:	7111                	addi	sp,sp,-256
    800062f2:	e006                	sd	ra,0(sp)
    800062f4:	e40a                	sd	sp,8(sp)
    800062f6:	e80e                	sd	gp,16(sp)
    800062f8:	ec12                	sd	tp,24(sp)
    800062fa:	f016                	sd	t0,32(sp)
    800062fc:	f41a                	sd	t1,40(sp)
    800062fe:	f81e                	sd	t2,48(sp)
    80006300:	fc22                	sd	s0,56(sp)
    80006302:	e0a6                	sd	s1,64(sp)
    80006304:	e4aa                	sd	a0,72(sp)
    80006306:	e8ae                	sd	a1,80(sp)
    80006308:	ecb2                	sd	a2,88(sp)
    8000630a:	f0b6                	sd	a3,96(sp)
    8000630c:	f4ba                	sd	a4,104(sp)
    8000630e:	f8be                	sd	a5,112(sp)
    80006310:	fcc2                	sd	a6,120(sp)
    80006312:	e146                	sd	a7,128(sp)
    80006314:	e54a                	sd	s2,136(sp)
    80006316:	e94e                	sd	s3,144(sp)
    80006318:	ed52                	sd	s4,152(sp)
    8000631a:	f156                	sd	s5,160(sp)
    8000631c:	f55a                	sd	s6,168(sp)
    8000631e:	f95e                	sd	s7,176(sp)
    80006320:	fd62                	sd	s8,184(sp)
    80006322:	e1e6                	sd	s9,192(sp)
    80006324:	e5ea                	sd	s10,200(sp)
    80006326:	e9ee                	sd	s11,208(sp)
    80006328:	edf2                	sd	t3,216(sp)
    8000632a:	f1f6                	sd	t4,224(sp)
    8000632c:	f5fa                	sd	t5,232(sp)
    8000632e:	f9fe                	sd	t6,240(sp)
    80006330:	d65fc0ef          	jal	ra,80003094 <kerneltrap>
    80006334:	6082                	ld	ra,0(sp)
    80006336:	6122                	ld	sp,8(sp)
    80006338:	61c2                	ld	gp,16(sp)
    8000633a:	7282                	ld	t0,32(sp)
    8000633c:	7322                	ld	t1,40(sp)
    8000633e:	73c2                	ld	t2,48(sp)
    80006340:	7462                	ld	s0,56(sp)
    80006342:	6486                	ld	s1,64(sp)
    80006344:	6526                	ld	a0,72(sp)
    80006346:	65c6                	ld	a1,80(sp)
    80006348:	6666                	ld	a2,88(sp)
    8000634a:	7686                	ld	a3,96(sp)
    8000634c:	7726                	ld	a4,104(sp)
    8000634e:	77c6                	ld	a5,112(sp)
    80006350:	7866                	ld	a6,120(sp)
    80006352:	688a                	ld	a7,128(sp)
    80006354:	692a                	ld	s2,136(sp)
    80006356:	69ca                	ld	s3,144(sp)
    80006358:	6a6a                	ld	s4,152(sp)
    8000635a:	7a8a                	ld	s5,160(sp)
    8000635c:	7b2a                	ld	s6,168(sp)
    8000635e:	7bca                	ld	s7,176(sp)
    80006360:	7c6a                	ld	s8,184(sp)
    80006362:	6c8e                	ld	s9,192(sp)
    80006364:	6d2e                	ld	s10,200(sp)
    80006366:	6dce                	ld	s11,208(sp)
    80006368:	6e6e                	ld	t3,216(sp)
    8000636a:	7e8e                	ld	t4,224(sp)
    8000636c:	7f2e                	ld	t5,232(sp)
    8000636e:	7fce                	ld	t6,240(sp)
    80006370:	6111                	addi	sp,sp,256
    80006372:	10200073          	sret
    80006376:	00000013          	nop
    8000637a:	00000013          	nop
    8000637e:	0001                	nop

0000000080006380 <timervec>:
    80006380:	34051573          	csrrw	a0,mscratch,a0
    80006384:	e10c                	sd	a1,0(a0)
    80006386:	e510                	sd	a2,8(a0)
    80006388:	e914                	sd	a3,16(a0)
    8000638a:	6d0c                	ld	a1,24(a0)
    8000638c:	7110                	ld	a2,32(a0)
    8000638e:	6194                	ld	a3,0(a1)
    80006390:	96b2                	add	a3,a3,a2
    80006392:	e194                	sd	a3,0(a1)
    80006394:	4589                	li	a1,2
    80006396:	14459073          	csrw	sip,a1
    8000639a:	6914                	ld	a3,16(a0)
    8000639c:	6510                	ld	a2,8(a0)
    8000639e:	610c                	ld	a1,0(a0)
    800063a0:	34051573          	csrrw	a0,mscratch,a0
    800063a4:	30200073          	mret
	...

00000000800063aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063aa:	1141                	addi	sp,sp,-16
    800063ac:	e422                	sd	s0,8(sp)
    800063ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063b0:	0c0007b7          	lui	a5,0xc000
    800063b4:	4705                	li	a4,1
    800063b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063b8:	c3d8                	sw	a4,4(a5)
}
    800063ba:	6422                	ld	s0,8(sp)
    800063bc:	0141                	addi	sp,sp,16
    800063be:	8082                	ret

00000000800063c0 <plicinithart>:

void
plicinithart(void)
{
    800063c0:	1141                	addi	sp,sp,-16
    800063c2:	e406                	sd	ra,8(sp)
    800063c4:	e022                	sd	s0,0(sp)
    800063c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063c8:	ffffc097          	auipc	ra,0xffffc
    800063cc:	832080e7          	jalr	-1998(ra) # 80001bfa <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063d0:	0085171b          	slliw	a4,a0,0x8
    800063d4:	0c0027b7          	lui	a5,0xc002
    800063d8:	97ba                	add	a5,a5,a4
    800063da:	40200713          	li	a4,1026
    800063de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063e2:	00d5151b          	slliw	a0,a0,0xd
    800063e6:	0c2017b7          	lui	a5,0xc201
    800063ea:	953e                	add	a0,a0,a5
    800063ec:	00052023          	sw	zero,0(a0)
}
    800063f0:	60a2                	ld	ra,8(sp)
    800063f2:	6402                	ld	s0,0(sp)
    800063f4:	0141                	addi	sp,sp,16
    800063f6:	8082                	ret

00000000800063f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063f8:	1141                	addi	sp,sp,-16
    800063fa:	e406                	sd	ra,8(sp)
    800063fc:	e022                	sd	s0,0(sp)
    800063fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006400:	ffffb097          	auipc	ra,0xffffb
    80006404:	7fa080e7          	jalr	2042(ra) # 80001bfa <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006408:	00d5179b          	slliw	a5,a0,0xd
    8000640c:	0c201537          	lui	a0,0xc201
    80006410:	953e                	add	a0,a0,a5
  return irq;
}
    80006412:	4148                	lw	a0,4(a0)
    80006414:	60a2                	ld	ra,8(sp)
    80006416:	6402                	ld	s0,0(sp)
    80006418:	0141                	addi	sp,sp,16
    8000641a:	8082                	ret

000000008000641c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000641c:	1101                	addi	sp,sp,-32
    8000641e:	ec06                	sd	ra,24(sp)
    80006420:	e822                	sd	s0,16(sp)
    80006422:	e426                	sd	s1,8(sp)
    80006424:	1000                	addi	s0,sp,32
    80006426:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006428:	ffffb097          	auipc	ra,0xffffb
    8000642c:	7d2080e7          	jalr	2002(ra) # 80001bfa <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006430:	00d5151b          	slliw	a0,a0,0xd
    80006434:	0c2017b7          	lui	a5,0xc201
    80006438:	97aa                	add	a5,a5,a0
    8000643a:	c3c4                	sw	s1,4(a5)
}
    8000643c:	60e2                	ld	ra,24(sp)
    8000643e:	6442                	ld	s0,16(sp)
    80006440:	64a2                	ld	s1,8(sp)
    80006442:	6105                	addi	sp,sp,32
    80006444:	8082                	ret

0000000080006446 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006446:	1141                	addi	sp,sp,-16
    80006448:	e406                	sd	ra,8(sp)
    8000644a:	e022                	sd	s0,0(sp)
    8000644c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000644e:	479d                	li	a5,7
    80006450:	06a7c963          	blt	a5,a0,800064c2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006454:	0001d797          	auipc	a5,0x1d
    80006458:	bac78793          	addi	a5,a5,-1108 # 80023000 <disk>
    8000645c:	00a78733          	add	a4,a5,a0
    80006460:	6789                	lui	a5,0x2
    80006462:	97ba                	add	a5,a5,a4
    80006464:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006468:	e7ad                	bnez	a5,800064d2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000646a:	00451793          	slli	a5,a0,0x4
    8000646e:	0001f717          	auipc	a4,0x1f
    80006472:	b9270713          	addi	a4,a4,-1134 # 80025000 <disk+0x2000>
    80006476:	6314                	ld	a3,0(a4)
    80006478:	96be                	add	a3,a3,a5
    8000647a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000647e:	6314                	ld	a3,0(a4)
    80006480:	96be                	add	a3,a3,a5
    80006482:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006486:	6314                	ld	a3,0(a4)
    80006488:	96be                	add	a3,a3,a5
    8000648a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000648e:	6318                	ld	a4,0(a4)
    80006490:	97ba                	add	a5,a5,a4
    80006492:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006496:	0001d797          	auipc	a5,0x1d
    8000649a:	b6a78793          	addi	a5,a5,-1174 # 80023000 <disk>
    8000649e:	97aa                	add	a5,a5,a0
    800064a0:	6509                	lui	a0,0x2
    800064a2:	953e                	add	a0,a0,a5
    800064a4:	4785                	li	a5,1
    800064a6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800064aa:	0001f517          	auipc	a0,0x1f
    800064ae:	b6e50513          	addi	a0,a0,-1170 # 80025018 <disk+0x2018>
    800064b2:	ffffc097          	auipc	ra,0xffffc
    800064b6:	45a080e7          	jalr	1114(ra) # 8000290c <wakeup>
}
    800064ba:	60a2                	ld	ra,8(sp)
    800064bc:	6402                	ld	s0,0(sp)
    800064be:	0141                	addi	sp,sp,16
    800064c0:	8082                	ret
    panic("free_desc 1");
    800064c2:	00002517          	auipc	a0,0x2
    800064c6:	37e50513          	addi	a0,a0,894 # 80008840 <syscalls+0x338>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	074080e7          	jalr	116(ra) # 8000053e <panic>
    panic("free_desc 2");
    800064d2:	00002517          	auipc	a0,0x2
    800064d6:	37e50513          	addi	a0,a0,894 # 80008850 <syscalls+0x348>
    800064da:	ffffa097          	auipc	ra,0xffffa
    800064de:	064080e7          	jalr	100(ra) # 8000053e <panic>

00000000800064e2 <virtio_disk_init>:
{
    800064e2:	1101                	addi	sp,sp,-32
    800064e4:	ec06                	sd	ra,24(sp)
    800064e6:	e822                	sd	s0,16(sp)
    800064e8:	e426                	sd	s1,8(sp)
    800064ea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064ec:	00002597          	auipc	a1,0x2
    800064f0:	37458593          	addi	a1,a1,884 # 80008860 <syscalls+0x358>
    800064f4:	0001f517          	auipc	a0,0x1f
    800064f8:	c3450513          	addi	a0,a0,-972 # 80025128 <disk+0x2128>
    800064fc:	ffffa097          	auipc	ra,0xffffa
    80006500:	658080e7          	jalr	1624(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006504:	100017b7          	lui	a5,0x10001
    80006508:	4398                	lw	a4,0(a5)
    8000650a:	2701                	sext.w	a4,a4
    8000650c:	747277b7          	lui	a5,0x74727
    80006510:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006514:	0ef71163          	bne	a4,a5,800065f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006518:	100017b7          	lui	a5,0x10001
    8000651c:	43dc                	lw	a5,4(a5)
    8000651e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006520:	4705                	li	a4,1
    80006522:	0ce79a63          	bne	a5,a4,800065f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006526:	100017b7          	lui	a5,0x10001
    8000652a:	479c                	lw	a5,8(a5)
    8000652c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000652e:	4709                	li	a4,2
    80006530:	0ce79363          	bne	a5,a4,800065f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006534:	100017b7          	lui	a5,0x10001
    80006538:	47d8                	lw	a4,12(a5)
    8000653a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000653c:	554d47b7          	lui	a5,0x554d4
    80006540:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006544:	0af71963          	bne	a4,a5,800065f6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006548:	100017b7          	lui	a5,0x10001
    8000654c:	4705                	li	a4,1
    8000654e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006550:	470d                	li	a4,3
    80006552:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006554:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006556:	c7ffe737          	lui	a4,0xc7ffe
    8000655a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000655e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006560:	2701                	sext.w	a4,a4
    80006562:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006564:	472d                	li	a4,11
    80006566:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006568:	473d                	li	a4,15
    8000656a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000656c:	6705                	lui	a4,0x1
    8000656e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006570:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006574:	5bdc                	lw	a5,52(a5)
    80006576:	2781                	sext.w	a5,a5
  if(max == 0)
    80006578:	c7d9                	beqz	a5,80006606 <virtio_disk_init+0x124>
  if(max < NUM)
    8000657a:	471d                	li	a4,7
    8000657c:	08f77d63          	bgeu	a4,a5,80006616 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006580:	100014b7          	lui	s1,0x10001
    80006584:	47a1                	li	a5,8
    80006586:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006588:	6609                	lui	a2,0x2
    8000658a:	4581                	li	a1,0
    8000658c:	0001d517          	auipc	a0,0x1d
    80006590:	a7450513          	addi	a0,a0,-1420 # 80023000 <disk>
    80006594:	ffffa097          	auipc	ra,0xffffa
    80006598:	74c080e7          	jalr	1868(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000659c:	0001d717          	auipc	a4,0x1d
    800065a0:	a6470713          	addi	a4,a4,-1436 # 80023000 <disk>
    800065a4:	00c75793          	srli	a5,a4,0xc
    800065a8:	2781                	sext.w	a5,a5
    800065aa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800065ac:	0001f797          	auipc	a5,0x1f
    800065b0:	a5478793          	addi	a5,a5,-1452 # 80025000 <disk+0x2000>
    800065b4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800065b6:	0001d717          	auipc	a4,0x1d
    800065ba:	aca70713          	addi	a4,a4,-1334 # 80023080 <disk+0x80>
    800065be:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800065c0:	0001e717          	auipc	a4,0x1e
    800065c4:	a4070713          	addi	a4,a4,-1472 # 80024000 <disk+0x1000>
    800065c8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800065ca:	4705                	li	a4,1
    800065cc:	00e78c23          	sb	a4,24(a5)
    800065d0:	00e78ca3          	sb	a4,25(a5)
    800065d4:	00e78d23          	sb	a4,26(a5)
    800065d8:	00e78da3          	sb	a4,27(a5)
    800065dc:	00e78e23          	sb	a4,28(a5)
    800065e0:	00e78ea3          	sb	a4,29(a5)
    800065e4:	00e78f23          	sb	a4,30(a5)
    800065e8:	00e78fa3          	sb	a4,31(a5)
}
    800065ec:	60e2                	ld	ra,24(sp)
    800065ee:	6442                	ld	s0,16(sp)
    800065f0:	64a2                	ld	s1,8(sp)
    800065f2:	6105                	addi	sp,sp,32
    800065f4:	8082                	ret
    panic("could not find virtio disk");
    800065f6:	00002517          	auipc	a0,0x2
    800065fa:	27a50513          	addi	a0,a0,634 # 80008870 <syscalls+0x368>
    800065fe:	ffffa097          	auipc	ra,0xffffa
    80006602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006606:	00002517          	auipc	a0,0x2
    8000660a:	28a50513          	addi	a0,a0,650 # 80008890 <syscalls+0x388>
    8000660e:	ffffa097          	auipc	ra,0xffffa
    80006612:	f30080e7          	jalr	-208(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006616:	00002517          	auipc	a0,0x2
    8000661a:	29a50513          	addi	a0,a0,666 # 800088b0 <syscalls+0x3a8>
    8000661e:	ffffa097          	auipc	ra,0xffffa
    80006622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>

0000000080006626 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006626:	7159                	addi	sp,sp,-112
    80006628:	f486                	sd	ra,104(sp)
    8000662a:	f0a2                	sd	s0,96(sp)
    8000662c:	eca6                	sd	s1,88(sp)
    8000662e:	e8ca                	sd	s2,80(sp)
    80006630:	e4ce                	sd	s3,72(sp)
    80006632:	e0d2                	sd	s4,64(sp)
    80006634:	fc56                	sd	s5,56(sp)
    80006636:	f85a                	sd	s6,48(sp)
    80006638:	f45e                	sd	s7,40(sp)
    8000663a:	f062                	sd	s8,32(sp)
    8000663c:	ec66                	sd	s9,24(sp)
    8000663e:	e86a                	sd	s10,16(sp)
    80006640:	1880                	addi	s0,sp,112
    80006642:	892a                	mv	s2,a0
    80006644:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006646:	00c52c83          	lw	s9,12(a0)
    8000664a:	001c9c9b          	slliw	s9,s9,0x1
    8000664e:	1c82                	slli	s9,s9,0x20
    80006650:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006654:	0001f517          	auipc	a0,0x1f
    80006658:	ad450513          	addi	a0,a0,-1324 # 80025128 <disk+0x2128>
    8000665c:	ffffa097          	auipc	ra,0xffffa
    80006660:	588080e7          	jalr	1416(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006664:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006666:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006668:	0001db97          	auipc	s7,0x1d
    8000666c:	998b8b93          	addi	s7,s7,-1640 # 80023000 <disk>
    80006670:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006672:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006674:	8a4e                	mv	s4,s3
    80006676:	a051                	j	800066fa <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006678:	00fb86b3          	add	a3,s7,a5
    8000667c:	96da                	add	a3,a3,s6
    8000667e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006682:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006684:	0207c563          	bltz	a5,800066ae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006688:	2485                	addiw	s1,s1,1
    8000668a:	0711                	addi	a4,a4,4
    8000668c:	25548063          	beq	s1,s5,800068cc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006690:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006692:	0001f697          	auipc	a3,0x1f
    80006696:	98668693          	addi	a3,a3,-1658 # 80025018 <disk+0x2018>
    8000669a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000669c:	0006c583          	lbu	a1,0(a3)
    800066a0:	fde1                	bnez	a1,80006678 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800066a2:	2785                	addiw	a5,a5,1
    800066a4:	0685                	addi	a3,a3,1
    800066a6:	ff879be3          	bne	a5,s8,8000669c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800066aa:	57fd                	li	a5,-1
    800066ac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800066ae:	02905a63          	blez	s1,800066e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066b2:	f9042503          	lw	a0,-112(s0)
    800066b6:	00000097          	auipc	ra,0x0
    800066ba:	d90080e7          	jalr	-624(ra) # 80006446 <free_desc>
      for(int j = 0; j < i; j++)
    800066be:	4785                	li	a5,1
    800066c0:	0297d163          	bge	a5,s1,800066e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066c4:	f9442503          	lw	a0,-108(s0)
    800066c8:	00000097          	auipc	ra,0x0
    800066cc:	d7e080e7          	jalr	-642(ra) # 80006446 <free_desc>
      for(int j = 0; j < i; j++)
    800066d0:	4789                	li	a5,2
    800066d2:	0097d863          	bge	a5,s1,800066e2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066d6:	f9842503          	lw	a0,-104(s0)
    800066da:	00000097          	auipc	ra,0x0
    800066de:	d6c080e7          	jalr	-660(ra) # 80006446 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066e2:	0001f597          	auipc	a1,0x1f
    800066e6:	a4658593          	addi	a1,a1,-1466 # 80025128 <disk+0x2128>
    800066ea:	0001f517          	auipc	a0,0x1f
    800066ee:	92e50513          	addi	a0,a0,-1746 # 80025018 <disk+0x2018>
    800066f2:	ffffc097          	auipc	ra,0xffffc
    800066f6:	084080e7          	jalr	132(ra) # 80002776 <sleep>
  for(int i = 0; i < 3; i++){
    800066fa:	f9040713          	addi	a4,s0,-112
    800066fe:	84ce                	mv	s1,s3
    80006700:	bf41                	j	80006690 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006702:	20058713          	addi	a4,a1,512
    80006706:	00471693          	slli	a3,a4,0x4
    8000670a:	0001d717          	auipc	a4,0x1d
    8000670e:	8f670713          	addi	a4,a4,-1802 # 80023000 <disk>
    80006712:	9736                	add	a4,a4,a3
    80006714:	4685                	li	a3,1
    80006716:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000671a:	20058713          	addi	a4,a1,512
    8000671e:	00471693          	slli	a3,a4,0x4
    80006722:	0001d717          	auipc	a4,0x1d
    80006726:	8de70713          	addi	a4,a4,-1826 # 80023000 <disk>
    8000672a:	9736                	add	a4,a4,a3
    8000672c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006730:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006734:	7679                	lui	a2,0xffffe
    80006736:	963e                	add	a2,a2,a5
    80006738:	0001f697          	auipc	a3,0x1f
    8000673c:	8c868693          	addi	a3,a3,-1848 # 80025000 <disk+0x2000>
    80006740:	6298                	ld	a4,0(a3)
    80006742:	9732                	add	a4,a4,a2
    80006744:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006746:	6298                	ld	a4,0(a3)
    80006748:	9732                	add	a4,a4,a2
    8000674a:	4541                	li	a0,16
    8000674c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000674e:	6298                	ld	a4,0(a3)
    80006750:	9732                	add	a4,a4,a2
    80006752:	4505                	li	a0,1
    80006754:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006758:	f9442703          	lw	a4,-108(s0)
    8000675c:	6288                	ld	a0,0(a3)
    8000675e:	962a                	add	a2,a2,a0
    80006760:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006764:	0712                	slli	a4,a4,0x4
    80006766:	6290                	ld	a2,0(a3)
    80006768:	963a                	add	a2,a2,a4
    8000676a:	05890513          	addi	a0,s2,88
    8000676e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006770:	6294                	ld	a3,0(a3)
    80006772:	96ba                	add	a3,a3,a4
    80006774:	40000613          	li	a2,1024
    80006778:	c690                	sw	a2,8(a3)
  if(write)
    8000677a:	140d0063          	beqz	s10,800068ba <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000677e:	0001f697          	auipc	a3,0x1f
    80006782:	8826b683          	ld	a3,-1918(a3) # 80025000 <disk+0x2000>
    80006786:	96ba                	add	a3,a3,a4
    80006788:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000678c:	0001d817          	auipc	a6,0x1d
    80006790:	87480813          	addi	a6,a6,-1932 # 80023000 <disk>
    80006794:	0001f517          	auipc	a0,0x1f
    80006798:	86c50513          	addi	a0,a0,-1940 # 80025000 <disk+0x2000>
    8000679c:	6114                	ld	a3,0(a0)
    8000679e:	96ba                	add	a3,a3,a4
    800067a0:	00c6d603          	lhu	a2,12(a3)
    800067a4:	00166613          	ori	a2,a2,1
    800067a8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800067ac:	f9842683          	lw	a3,-104(s0)
    800067b0:	6110                	ld	a2,0(a0)
    800067b2:	9732                	add	a4,a4,a2
    800067b4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067b8:	20058613          	addi	a2,a1,512
    800067bc:	0612                	slli	a2,a2,0x4
    800067be:	9642                	add	a2,a2,a6
    800067c0:	577d                	li	a4,-1
    800067c2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067c6:	00469713          	slli	a4,a3,0x4
    800067ca:	6114                	ld	a3,0(a0)
    800067cc:	96ba                	add	a3,a3,a4
    800067ce:	03078793          	addi	a5,a5,48
    800067d2:	97c2                	add	a5,a5,a6
    800067d4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800067d6:	611c                	ld	a5,0(a0)
    800067d8:	97ba                	add	a5,a5,a4
    800067da:	4685                	li	a3,1
    800067dc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067de:	611c                	ld	a5,0(a0)
    800067e0:	97ba                	add	a5,a5,a4
    800067e2:	4809                	li	a6,2
    800067e4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800067e8:	611c                	ld	a5,0(a0)
    800067ea:	973e                	add	a4,a4,a5
    800067ec:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067f0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800067f4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067f8:	6518                	ld	a4,8(a0)
    800067fa:	00275783          	lhu	a5,2(a4)
    800067fe:	8b9d                	andi	a5,a5,7
    80006800:	0786                	slli	a5,a5,0x1
    80006802:	97ba                	add	a5,a5,a4
    80006804:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006808:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000680c:	6518                	ld	a4,8(a0)
    8000680e:	00275783          	lhu	a5,2(a4)
    80006812:	2785                	addiw	a5,a5,1
    80006814:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006818:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000681c:	100017b7          	lui	a5,0x10001
    80006820:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006824:	00492703          	lw	a4,4(s2)
    80006828:	4785                	li	a5,1
    8000682a:	02f71163          	bne	a4,a5,8000684c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000682e:	0001f997          	auipc	s3,0x1f
    80006832:	8fa98993          	addi	s3,s3,-1798 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006836:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006838:	85ce                	mv	a1,s3
    8000683a:	854a                	mv	a0,s2
    8000683c:	ffffc097          	auipc	ra,0xffffc
    80006840:	f3a080e7          	jalr	-198(ra) # 80002776 <sleep>
  while(b->disk == 1) {
    80006844:	00492783          	lw	a5,4(s2)
    80006848:	fe9788e3          	beq	a5,s1,80006838 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000684c:	f9042903          	lw	s2,-112(s0)
    80006850:	20090793          	addi	a5,s2,512
    80006854:	00479713          	slli	a4,a5,0x4
    80006858:	0001c797          	auipc	a5,0x1c
    8000685c:	7a878793          	addi	a5,a5,1960 # 80023000 <disk>
    80006860:	97ba                	add	a5,a5,a4
    80006862:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006866:	0001e997          	auipc	s3,0x1e
    8000686a:	79a98993          	addi	s3,s3,1946 # 80025000 <disk+0x2000>
    8000686e:	00491713          	slli	a4,s2,0x4
    80006872:	0009b783          	ld	a5,0(s3)
    80006876:	97ba                	add	a5,a5,a4
    80006878:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000687c:	854a                	mv	a0,s2
    8000687e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006882:	00000097          	auipc	ra,0x0
    80006886:	bc4080e7          	jalr	-1084(ra) # 80006446 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000688a:	8885                	andi	s1,s1,1
    8000688c:	f0ed                	bnez	s1,8000686e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000688e:	0001f517          	auipc	a0,0x1f
    80006892:	89a50513          	addi	a0,a0,-1894 # 80025128 <disk+0x2128>
    80006896:	ffffa097          	auipc	ra,0xffffa
    8000689a:	402080e7          	jalr	1026(ra) # 80000c98 <release>
}
    8000689e:	70a6                	ld	ra,104(sp)
    800068a0:	7406                	ld	s0,96(sp)
    800068a2:	64e6                	ld	s1,88(sp)
    800068a4:	6946                	ld	s2,80(sp)
    800068a6:	69a6                	ld	s3,72(sp)
    800068a8:	6a06                	ld	s4,64(sp)
    800068aa:	7ae2                	ld	s5,56(sp)
    800068ac:	7b42                	ld	s6,48(sp)
    800068ae:	7ba2                	ld	s7,40(sp)
    800068b0:	7c02                	ld	s8,32(sp)
    800068b2:	6ce2                	ld	s9,24(sp)
    800068b4:	6d42                	ld	s10,16(sp)
    800068b6:	6165                	addi	sp,sp,112
    800068b8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800068ba:	0001e697          	auipc	a3,0x1e
    800068be:	7466b683          	ld	a3,1862(a3) # 80025000 <disk+0x2000>
    800068c2:	96ba                	add	a3,a3,a4
    800068c4:	4609                	li	a2,2
    800068c6:	00c69623          	sh	a2,12(a3)
    800068ca:	b5c9                	j	8000678c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068cc:	f9042583          	lw	a1,-112(s0)
    800068d0:	20058793          	addi	a5,a1,512
    800068d4:	0792                	slli	a5,a5,0x4
    800068d6:	0001c517          	auipc	a0,0x1c
    800068da:	7d250513          	addi	a0,a0,2002 # 800230a8 <disk+0xa8>
    800068de:	953e                	add	a0,a0,a5
  if(write)
    800068e0:	e20d11e3          	bnez	s10,80006702 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800068e4:	20058713          	addi	a4,a1,512
    800068e8:	00471693          	slli	a3,a4,0x4
    800068ec:	0001c717          	auipc	a4,0x1c
    800068f0:	71470713          	addi	a4,a4,1812 # 80023000 <disk>
    800068f4:	9736                	add	a4,a4,a3
    800068f6:	0a072423          	sw	zero,168(a4)
    800068fa:	b505                	j	8000671a <virtio_disk_rw+0xf4>

00000000800068fc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068fc:	1101                	addi	sp,sp,-32
    800068fe:	ec06                	sd	ra,24(sp)
    80006900:	e822                	sd	s0,16(sp)
    80006902:	e426                	sd	s1,8(sp)
    80006904:	e04a                	sd	s2,0(sp)
    80006906:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006908:	0001f517          	auipc	a0,0x1f
    8000690c:	82050513          	addi	a0,a0,-2016 # 80025128 <disk+0x2128>
    80006910:	ffffa097          	auipc	ra,0xffffa
    80006914:	2d4080e7          	jalr	724(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006918:	10001737          	lui	a4,0x10001
    8000691c:	533c                	lw	a5,96(a4)
    8000691e:	8b8d                	andi	a5,a5,3
    80006920:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006922:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006926:	0001e797          	auipc	a5,0x1e
    8000692a:	6da78793          	addi	a5,a5,1754 # 80025000 <disk+0x2000>
    8000692e:	6b94                	ld	a3,16(a5)
    80006930:	0207d703          	lhu	a4,32(a5)
    80006934:	0026d783          	lhu	a5,2(a3)
    80006938:	06f70163          	beq	a4,a5,8000699a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000693c:	0001c917          	auipc	s2,0x1c
    80006940:	6c490913          	addi	s2,s2,1732 # 80023000 <disk>
    80006944:	0001e497          	auipc	s1,0x1e
    80006948:	6bc48493          	addi	s1,s1,1724 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000694c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006950:	6898                	ld	a4,16(s1)
    80006952:	0204d783          	lhu	a5,32(s1)
    80006956:	8b9d                	andi	a5,a5,7
    80006958:	078e                	slli	a5,a5,0x3
    8000695a:	97ba                	add	a5,a5,a4
    8000695c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000695e:	20078713          	addi	a4,a5,512
    80006962:	0712                	slli	a4,a4,0x4
    80006964:	974a                	add	a4,a4,s2
    80006966:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000696a:	e731                	bnez	a4,800069b6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000696c:	20078793          	addi	a5,a5,512
    80006970:	0792                	slli	a5,a5,0x4
    80006972:	97ca                	add	a5,a5,s2
    80006974:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006976:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000697a:	ffffc097          	auipc	ra,0xffffc
    8000697e:	f92080e7          	jalr	-110(ra) # 8000290c <wakeup>

    disk.used_idx += 1;
    80006982:	0204d783          	lhu	a5,32(s1)
    80006986:	2785                	addiw	a5,a5,1
    80006988:	17c2                	slli	a5,a5,0x30
    8000698a:	93c1                	srli	a5,a5,0x30
    8000698c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006990:	6898                	ld	a4,16(s1)
    80006992:	00275703          	lhu	a4,2(a4)
    80006996:	faf71be3          	bne	a4,a5,8000694c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000699a:	0001e517          	auipc	a0,0x1e
    8000699e:	78e50513          	addi	a0,a0,1934 # 80025128 <disk+0x2128>
    800069a2:	ffffa097          	auipc	ra,0xffffa
    800069a6:	2f6080e7          	jalr	758(ra) # 80000c98 <release>
}
    800069aa:	60e2                	ld	ra,24(sp)
    800069ac:	6442                	ld	s0,16(sp)
    800069ae:	64a2                	ld	s1,8(sp)
    800069b0:	6902                	ld	s2,0(sp)
    800069b2:	6105                	addi	sp,sp,32
    800069b4:	8082                	ret
      panic("virtio_disk_intr status");
    800069b6:	00002517          	auipc	a0,0x2
    800069ba:	f1a50513          	addi	a0,a0,-230 # 800088d0 <syscalls+0x3c8>
    800069be:	ffffa097          	auipc	ra,0xffffa
    800069c2:	b80080e7          	jalr	-1152(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
