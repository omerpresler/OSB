
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
    80000068:	33c78793          	addi	a5,a5,828 # 800063a0 <timervec>
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
    80000130:	b5e080e7          	jalr	-1186(ra) # 80002c8a <either_copyin>
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
    800001c8:	a44080e7          	jalr	-1468(ra) # 80001c08 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	584080e7          	jalr	1412(ra) # 80002758 <sleep>
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
    80000214:	a24080e7          	jalr	-1500(ra) # 80002c34 <either_copyout>
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
    800002f6:	9ee080e7          	jalr	-1554(ra) # 80002ce0 <procdump>
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
    8000044a:	4a8080e7          	jalr	1192(ra) # 800028ee <wakeup>
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
    800008a4:	04e080e7          	jalr	78(ra) # 800028ee <wakeup>
    
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
    80000930:	e2c080e7          	jalr	-468(ra) # 80002758 <sleep>
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
    80000b82:	06e080e7          	jalr	110(ra) # 80001bec <mycpu>
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
    80000bb4:	03c080e7          	jalr	60(ra) # 80001bec <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	030080e7          	jalr	48(ra) # 80001bec <mycpu>
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
    80000bd8:	018080e7          	jalr	24(ra) # 80001bec <mycpu>
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
    80000c18:	fd8080e7          	jalr	-40(ra) # 80001bec <mycpu>
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
    80000c44:	fac080e7          	jalr	-84(ra) # 80001bec <mycpu>
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
    80000eac:	154080e7          	jalr	340(ra) # 80001ffc <fork>
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	14c080e7          	jalr	332(ra) # 80001ffc <fork>
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
    80000efa:	7d2080e7          	jalr	2002(ra) # 800026c8 <pause_system>
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
    80000f3e:	0c2080e7          	jalr	194(ra) # 80001ffc <fork>
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	0ba080e7          	jalr	186(ra) # 80001ffc <fork>
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
    80000f8a:	c44080e7          	jalr	-956(ra) # 80002bca <kill_system>
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
    80000fbe:	c22080e7          	jalr	-990(ra) # 80001bdc <cpuid>
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
    80000fda:	c06080e7          	jalr	-1018(ra) # 80001bdc <cpuid>
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
    80000ffc:	e28080e7          	jalr	-472(ra) # 80002e20 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001000:	00005097          	auipc	ra,0x5
    80001004:	3e0080e7          	jalr	992(ra) # 800063e0 <plicinithart>
  }

  scheduler();    
    80001008:	00001097          	auipc	ra,0x1
    8000100c:	598080e7          	jalr	1432(ra) # 800025a0 <scheduler>
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
    8000106c:	aac080e7          	jalr	-1364(ra) # 80001b14 <procinit>
    trapinit();      // trap vectors
    80001070:	00002097          	auipc	ra,0x2
    80001074:	d88080e7          	jalr	-632(ra) # 80002df8 <trapinit>
    trapinithart();  // install kernel trap vector
    80001078:	00002097          	auipc	ra,0x2
    8000107c:	da8080e7          	jalr	-600(ra) # 80002e20 <trapinithart>
    plicinit();      // set up interrupt controller
    80001080:	00005097          	auipc	ra,0x5
    80001084:	34a080e7          	jalr	842(ra) # 800063ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001088:	00005097          	auipc	ra,0x5
    8000108c:	358080e7          	jalr	856(ra) # 800063e0 <plicinithart>
    binit();         // buffer cache
    80001090:	00002097          	auipc	ra,0x2
    80001094:	534080e7          	jalr	1332(ra) # 800035c4 <binit>
    iinit();         // inode table
    80001098:	00003097          	auipc	ra,0x3
    8000109c:	bc4080e7          	jalr	-1084(ra) # 80003c5c <iinit>
    fileinit();      // file table
    800010a0:	00004097          	auipc	ra,0x4
    800010a4:	b6e080e7          	jalr	-1170(ra) # 80004c0e <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a8:	00005097          	auipc	ra,0x5
    800010ac:	45a080e7          	jalr	1114(ra) # 80006502 <virtio_disk_init>
    userinit();      // first user process
    800010b0:	00001097          	auipc	ra,0x1
    800010b4:	e50080e7          	jalr	-432(ra) # 80001f00 <userinit>
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
    80001368:	71a080e7          	jalr	1818(ra) # 80001a7e <proc_mapstacks>
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
    80001980:	6dc7a783          	lw	a5,1756(a5) # 80009058 <ticks>
    80001984:	c57c                	sw	a5,76(a0)
}
    80001986:	6422                	ld	s0,8(sp)
    80001988:	0141                	addi	sp,sp,16
    8000198a:	8082                	ret
    p->sleeping_time += ticks - p->last_time_changed;
    8000198c:	493c                	lw	a5,80(a0)
    8000198e:	00007717          	auipc	a4,0x7
    80001992:	6ca72703          	lw	a4,1738(a4) # 80009058 <ticks>
    80001996:	9fb9                	addw	a5,a5,a4
    80001998:	4578                	lw	a4,76(a0)
    8000199a:	9f99                	subw	a5,a5,a4
    8000199c:	c93c                	sw	a5,80(a0)
    break;
    8000199e:	bff9                	j	8000197c <stateChange+0x1a>
    p->runnable_time += ticks - p->last_time_changed;
    800019a0:	497c                	lw	a5,84(a0)
    800019a2:	00007717          	auipc	a4,0x7
    800019a6:	6b672703          	lw	a4,1718(a4) # 80009058 <ticks>
    800019aa:	9fb9                	addw	a5,a5,a4
    800019ac:	4578                	lw	a4,76(a0)
    800019ae:	9f99                	subw	a5,a5,a4
    800019b0:	c97c                	sw	a5,84(a0)
    break;
    800019b2:	b7e9                	j	8000197c <stateChange+0x1a>
    p->running_time += ticks - p->last_time_changed;
    800019b4:	4d3c                	lw	a5,88(a0)
    800019b6:	00007717          	auipc	a4,0x7
    800019ba:	6a272703          	lw	a4,1698(a4) # 80009058 <ticks>
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
    800019e4:	6787a783          	lw	a5,1656(a5) # 80009058 <ticks>
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
    800019f4:	1141                	addi	sp,sp,-16
    800019f6:	e406                	sd	ra,8(sp)
    800019f8:	e022                	sd	s0,0(sp)
    800019fa:	0800                	addi	s0,sp,16
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    800019fc:	00007597          	auipc	a1,0x7
    80001a00:	64c5a583          	lw	a1,1612(a1) # 80009048 <sleeping_processes_mean>
    80001a04:	00007517          	auipc	a0,0x7
    80001a08:	81450513          	addi	a0,a0,-2028 # 80008218 <digits+0x1d8>
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	b7c080e7          	jalr	-1156(ra) # 80000588 <printf>
  printf("runnable_time_mean: %d\n", runnable_time_mean);
    80001a14:	00007597          	auipc	a1,0x7
    80001a18:	6305a583          	lw	a1,1584(a1) # 80009044 <runnable_time_mean>
    80001a1c:	00007517          	auipc	a0,0x7
    80001a20:	81c50513          	addi	a0,a0,-2020 # 80008238 <digits+0x1f8>
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	b64080e7          	jalr	-1180(ra) # 80000588 <printf>
  printf("running_time_count: %d\n", running_time_count);
    80001a2c:	00007597          	auipc	a1,0x7
    80001a30:	6085a583          	lw	a1,1544(a1) # 80009034 <running_time_count>
    80001a34:	00007517          	auipc	a0,0x7
    80001a38:	81c50513          	addi	a0,a0,-2020 # 80008250 <digits+0x210>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	b4c080e7          	jalr	-1204(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    80001a44:	00007597          	auipc	a1,0x7
    80001a48:	5ec5a583          	lw	a1,1516(a1) # 80009030 <program_time>
    80001a4c:	00007517          	auipc	a0,0x7
    80001a50:	81c50513          	addi	a0,a0,-2020 # 80008268 <digits+0x228>
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	b34080e7          	jalr	-1228(ra) # 80000588 <printf>
  printf("cpu_utilization: %d\n", cpu_utilization);
    80001a5c:	00007597          	auipc	a1,0x7
    80001a60:	5d05a583          	lw	a1,1488(a1) # 8000902c <cpu_utilization>
    80001a64:	00007517          	auipc	a0,0x7
    80001a68:	81c50513          	addi	a0,a0,-2020 # 80008280 <digits+0x240>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	b1c080e7          	jalr	-1252(ra) # 80000588 <printf>

  return 0;
}
    80001a74:	4501                	li	a0,0
    80001a76:	60a2                	ld	ra,8(sp)
    80001a78:	6402                	ld	s0,0(sp)
    80001a7a:	0141                	addi	sp,sp,16
    80001a7c:	8082                	ret

0000000080001a7e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001a7e:	7139                	addi	sp,sp,-64
    80001a80:	fc06                	sd	ra,56(sp)
    80001a82:	f822                	sd	s0,48(sp)
    80001a84:	f426                	sd	s1,40(sp)
    80001a86:	f04a                	sd	s2,32(sp)
    80001a88:	ec4e                	sd	s3,24(sp)
    80001a8a:	e852                	sd	s4,16(sp)
    80001a8c:	e456                	sd	s5,8(sp)
    80001a8e:	e05a                	sd	s6,0(sp)
    80001a90:	0080                	addi	s0,sp,64
    80001a92:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a94:	00010497          	auipc	s1,0x10
    80001a98:	c5c48493          	addi	s1,s1,-932 # 800116f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a9c:	8b26                	mv	s6,s1
    80001a9e:	00006a97          	auipc	s5,0x6
    80001aa2:	562a8a93          	addi	s5,s5,1378 # 80008000 <etext>
    80001aa6:	04000937          	lui	s2,0x4000
    80001aaa:	197d                	addi	s2,s2,-1
    80001aac:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aae:	00016a17          	auipc	s4,0x16
    80001ab2:	e42a0a13          	addi	s4,s4,-446 # 800178f0 <tickslock>
    char *pa = kalloc();
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	03e080e7          	jalr	62(ra) # 80000af4 <kalloc>
    80001abe:	862a                	mv	a2,a0
    if(pa == 0)
    80001ac0:	c131                	beqz	a0,80001b04 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001ac2:	416485b3          	sub	a1,s1,s6
    80001ac6:	858d                	srai	a1,a1,0x3
    80001ac8:	000ab783          	ld	a5,0(s5)
    80001acc:	02f585b3          	mul	a1,a1,a5
    80001ad0:	2585                	addiw	a1,a1,1
    80001ad2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ad6:	4719                	li	a4,6
    80001ad8:	6685                	lui	a3,0x1
    80001ada:	40b905b3          	sub	a1,s2,a1
    80001ade:	854e                	mv	a0,s3
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	794080e7          	jalr	1940(ra) # 80001274 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ae8:	18848493          	addi	s1,s1,392
    80001aec:	fd4495e3          	bne	s1,s4,80001ab6 <proc_mapstacks+0x38>
  }
}
    80001af0:	70e2                	ld	ra,56(sp)
    80001af2:	7442                	ld	s0,48(sp)
    80001af4:	74a2                	ld	s1,40(sp)
    80001af6:	7902                	ld	s2,32(sp)
    80001af8:	69e2                	ld	s3,24(sp)
    80001afa:	6a42                	ld	s4,16(sp)
    80001afc:	6aa2                	ld	s5,8(sp)
    80001afe:	6b02                	ld	s6,0(sp)
    80001b00:	6121                	addi	sp,sp,64
    80001b02:	8082                	ret
      panic("kalloc");
    80001b04:	00006517          	auipc	a0,0x6
    80001b08:	79450513          	addi	a0,a0,1940 # 80008298 <digits+0x258>
    80001b0c:	fffff097          	auipc	ra,0xfffff
    80001b10:	a32080e7          	jalr	-1486(ra) # 8000053e <panic>

0000000080001b14 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b14:	7139                	addi	sp,sp,-64
    80001b16:	fc06                	sd	ra,56(sp)
    80001b18:	f822                	sd	s0,48(sp)
    80001b1a:	f426                	sd	s1,40(sp)
    80001b1c:	f04a                	sd	s2,32(sp)
    80001b1e:	ec4e                	sd	s3,24(sp)
    80001b20:	e852                	sd	s4,16(sp)
    80001b22:	e456                	sd	s5,8(sp)
    80001b24:	e05a                	sd	s6,0(sp)
    80001b26:	0080                	addi	s0,sp,64
  struct proc *p;
  cpu_utilization = ticks;
    80001b28:	00007797          	auipc	a5,0x7
    80001b2c:	5307a783          	lw	a5,1328(a5) # 80009058 <ticks>
    80001b30:	00007717          	auipc	a4,0x7
    80001b34:	4ef72e23          	sw	a5,1276(a4) # 8000902c <cpu_utilization>
  start_time = ticks;
    80001b38:	00007717          	auipc	a4,0x7
    80001b3c:	4ef72823          	sw	a5,1264(a4) # 80009028 <start_time>
  
  initlock(&pid_lock, "nextpid");
    80001b40:	00006597          	auipc	a1,0x6
    80001b44:	76058593          	addi	a1,a1,1888 # 800082a0 <digits+0x260>
    80001b48:	0000f517          	auipc	a0,0xf
    80001b4c:	77850513          	addi	a0,a0,1912 # 800112c0 <pid_lock>
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	004080e7          	jalr	4(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b58:	00006597          	auipc	a1,0x6
    80001b5c:	75058593          	addi	a1,a1,1872 # 800082a8 <digits+0x268>
    80001b60:	0000f517          	auipc	a0,0xf
    80001b64:	77850513          	addi	a0,a0,1912 # 800112d8 <wait_lock>
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	fec080e7          	jalr	-20(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b70:	00010497          	auipc	s1,0x10
    80001b74:	b8048493          	addi	s1,s1,-1152 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001b78:	00006b17          	auipc	s6,0x6
    80001b7c:	740b0b13          	addi	s6,s6,1856 # 800082b8 <digits+0x278>
      p->kstack = KSTACK((int) (p - proc));
    80001b80:	8aa6                	mv	s5,s1
    80001b82:	00006a17          	auipc	s4,0x6
    80001b86:	47ea0a13          	addi	s4,s4,1150 # 80008000 <etext>
    80001b8a:	04000937          	lui	s2,0x4000
    80001b8e:	197d                	addi	s2,s2,-1
    80001b90:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b92:	00016997          	auipc	s3,0x16
    80001b96:	d5e98993          	addi	s3,s3,-674 # 800178f0 <tickslock>
      initlock(&p->lock, "proc");
    80001b9a:	85da                	mv	a1,s6
    80001b9c:	8526                	mv	a0,s1
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	fb6080e7          	jalr	-74(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001ba6:	415487b3          	sub	a5,s1,s5
    80001baa:	878d                	srai	a5,a5,0x3
    80001bac:	000a3703          	ld	a4,0(s4)
    80001bb0:	02e787b3          	mul	a5,a5,a4
    80001bb4:	2785                	addiw	a5,a5,1
    80001bb6:	00d7979b          	slliw	a5,a5,0xd
    80001bba:	40f907b3          	sub	a5,s2,a5
    80001bbe:	f0bc                	sd	a5,96(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc0:	18848493          	addi	s1,s1,392
    80001bc4:	fd349be3          	bne	s1,s3,80001b9a <procinit+0x86>
  }
}
    80001bc8:	70e2                	ld	ra,56(sp)
    80001bca:	7442                	ld	s0,48(sp)
    80001bcc:	74a2                	ld	s1,40(sp)
    80001bce:	7902                	ld	s2,32(sp)
    80001bd0:	69e2                	ld	s3,24(sp)
    80001bd2:	6a42                	ld	s4,16(sp)
    80001bd4:	6aa2                	ld	s5,8(sp)
    80001bd6:	6b02                	ld	s6,0(sp)
    80001bd8:	6121                	addi	sp,sp,64
    80001bda:	8082                	ret

0000000080001bdc <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001bdc:	1141                	addi	sp,sp,-16
    80001bde:	e422                	sd	s0,8(sp)
    80001be0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001be2:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001be4:	2501                	sext.w	a0,a0
    80001be6:	6422                	ld	s0,8(sp)
    80001be8:	0141                	addi	sp,sp,16
    80001bea:	8082                	ret

0000000080001bec <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001bec:	1141                	addi	sp,sp,-16
    80001bee:	e422                	sd	s0,8(sp)
    80001bf0:	0800                	addi	s0,sp,16
    80001bf2:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001bf4:	2781                	sext.w	a5,a5
    80001bf6:	079e                	slli	a5,a5,0x7
  return c;
}
    80001bf8:	0000f517          	auipc	a0,0xf
    80001bfc:	6f850513          	addi	a0,a0,1784 # 800112f0 <cpus>
    80001c00:	953e                	add	a0,a0,a5
    80001c02:	6422                	ld	s0,8(sp)
    80001c04:	0141                	addi	sp,sp,16
    80001c06:	8082                	ret

0000000080001c08 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c08:	1101                	addi	sp,sp,-32
    80001c0a:	ec06                	sd	ra,24(sp)
    80001c0c:	e822                	sd	s0,16(sp)
    80001c0e:	e426                	sd	s1,8(sp)
    80001c10:	1000                	addi	s0,sp,32
  push_off();
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	f86080e7          	jalr	-122(ra) # 80000b98 <push_off>
    80001c1a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c1c:	2781                	sext.w	a5,a5
    80001c1e:	079e                	slli	a5,a5,0x7
    80001c20:	0000f717          	auipc	a4,0xf
    80001c24:	6a070713          	addi	a4,a4,1696 # 800112c0 <pid_lock>
    80001c28:	97ba                	add	a5,a5,a4
    80001c2a:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	00c080e7          	jalr	12(ra) # 80000c38 <pop_off>
  return p;
}
    80001c34:	8526                	mv	a0,s1
    80001c36:	60e2                	ld	ra,24(sp)
    80001c38:	6442                	ld	s0,16(sp)
    80001c3a:	64a2                	ld	s1,8(sp)
    80001c3c:	6105                	addi	sp,sp,32
    80001c3e:	8082                	ret

0000000080001c40 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c40:	1141                	addi	sp,sp,-16
    80001c42:	e406                	sd	ra,8(sp)
    80001c44:	e022                	sd	s0,0(sp)
    80001c46:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	fc0080e7          	jalr	-64(ra) # 80001c08 <myproc>
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	048080e7          	jalr	72(ra) # 80000c98 <release>

  if (first) {
    80001c58:	00007797          	auipc	a5,0x7
    80001c5c:	c987a783          	lw	a5,-872(a5) # 800088f0 <first.1758>
    80001c60:	eb89                	bnez	a5,80001c72 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c62:	00001097          	auipc	ra,0x1
    80001c66:	1d6080e7          	jalr	470(ra) # 80002e38 <usertrapret>
}
    80001c6a:	60a2                	ld	ra,8(sp)
    80001c6c:	6402                	ld	s0,0(sp)
    80001c6e:	0141                	addi	sp,sp,16
    80001c70:	8082                	ret
    first = 0;
    80001c72:	00007797          	auipc	a5,0x7
    80001c76:	c607af23          	sw	zero,-898(a5) # 800088f0 <first.1758>
    fsinit(ROOTDEV);
    80001c7a:	4505                	li	a0,1
    80001c7c:	00002097          	auipc	ra,0x2
    80001c80:	f60080e7          	jalr	-160(ra) # 80003bdc <fsinit>
    80001c84:	bff9                	j	80001c62 <forkret+0x22>

0000000080001c86 <allocpid>:
allocpid() {
    80001c86:	1101                	addi	sp,sp,-32
    80001c88:	ec06                	sd	ra,24(sp)
    80001c8a:	e822                	sd	s0,16(sp)
    80001c8c:	e426                	sd	s1,8(sp)
    80001c8e:	e04a                	sd	s2,0(sp)
    80001c90:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c92:	0000f917          	auipc	s2,0xf
    80001c96:	62e90913          	addi	s2,s2,1582 # 800112c0 <pid_lock>
    80001c9a:	854a                	mv	a0,s2
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	f48080e7          	jalr	-184(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001ca4:	00007797          	auipc	a5,0x7
    80001ca8:	c5478793          	addi	a5,a5,-940 # 800088f8 <nextpid>
    80001cac:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001cae:	0014871b          	addiw	a4,s1,1
    80001cb2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001cb4:	854a                	mv	a0,s2
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	fe2080e7          	jalr	-30(ra) # 80000c98 <release>
}
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	60e2                	ld	ra,24(sp)
    80001cc2:	6442                	ld	s0,16(sp)
    80001cc4:	64a2                	ld	s1,8(sp)
    80001cc6:	6902                	ld	s2,0(sp)
    80001cc8:	6105                	addi	sp,sp,32
    80001cca:	8082                	ret

0000000080001ccc <proc_pagetable>:
{
    80001ccc:	1101                	addi	sp,sp,-32
    80001cce:	ec06                	sd	ra,24(sp)
    80001cd0:	e822                	sd	s0,16(sp)
    80001cd2:	e426                	sd	s1,8(sp)
    80001cd4:	e04a                	sd	s2,0(sp)
    80001cd6:	1000                	addi	s0,sp,32
    80001cd8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	784080e7          	jalr	1924(ra) # 8000145e <uvmcreate>
    80001ce2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ce4:	c121                	beqz	a0,80001d24 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ce6:	4729                	li	a4,10
    80001ce8:	00005697          	auipc	a3,0x5
    80001cec:	31868693          	addi	a3,a3,792 # 80007000 <_trampoline>
    80001cf0:	6605                	lui	a2,0x1
    80001cf2:	040005b7          	lui	a1,0x4000
    80001cf6:	15fd                	addi	a1,a1,-1
    80001cf8:	05b2                	slli	a1,a1,0xc
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	4da080e7          	jalr	1242(ra) # 800011d4 <mappages>
    80001d02:	02054863          	bltz	a0,80001d32 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d06:	4719                	li	a4,6
    80001d08:	07893683          	ld	a3,120(s2)
    80001d0c:	6605                	lui	a2,0x1
    80001d0e:	020005b7          	lui	a1,0x2000
    80001d12:	15fd                	addi	a1,a1,-1
    80001d14:	05b6                	slli	a1,a1,0xd
    80001d16:	8526                	mv	a0,s1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	4bc080e7          	jalr	1212(ra) # 800011d4 <mappages>
    80001d20:	02054163          	bltz	a0,80001d42 <proc_pagetable+0x76>
}
    80001d24:	8526                	mv	a0,s1
    80001d26:	60e2                	ld	ra,24(sp)
    80001d28:	6442                	ld	s0,16(sp)
    80001d2a:	64a2                	ld	s1,8(sp)
    80001d2c:	6902                	ld	s2,0(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret
    uvmfree(pagetable, 0);
    80001d32:	4581                	li	a1,0
    80001d34:	8526                	mv	a0,s1
    80001d36:	00000097          	auipc	ra,0x0
    80001d3a:	924080e7          	jalr	-1756(ra) # 8000165a <uvmfree>
    return 0;
    80001d3e:	4481                	li	s1,0
    80001d40:	b7d5                	j	80001d24 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d42:	4681                	li	a3,0
    80001d44:	4605                	li	a2,1
    80001d46:	040005b7          	lui	a1,0x4000
    80001d4a:	15fd                	addi	a1,a1,-1
    80001d4c:	05b2                	slli	a1,a1,0xc
    80001d4e:	8526                	mv	a0,s1
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	64a080e7          	jalr	1610(ra) # 8000139a <uvmunmap>
    uvmfree(pagetable, 0);
    80001d58:	4581                	li	a1,0
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	8fe080e7          	jalr	-1794(ra) # 8000165a <uvmfree>
    return 0;
    80001d64:	4481                	li	s1,0
    80001d66:	bf7d                	j	80001d24 <proc_pagetable+0x58>

0000000080001d68 <proc_freepagetable>:
{
    80001d68:	1101                	addi	sp,sp,-32
    80001d6a:	ec06                	sd	ra,24(sp)
    80001d6c:	e822                	sd	s0,16(sp)
    80001d6e:	e426                	sd	s1,8(sp)
    80001d70:	e04a                	sd	s2,0(sp)
    80001d72:	1000                	addi	s0,sp,32
    80001d74:	84aa                	mv	s1,a0
    80001d76:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d78:	4681                	li	a3,0
    80001d7a:	4605                	li	a2,1
    80001d7c:	040005b7          	lui	a1,0x4000
    80001d80:	15fd                	addi	a1,a1,-1
    80001d82:	05b2                	slli	a1,a1,0xc
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	616080e7          	jalr	1558(ra) # 8000139a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d8c:	4681                	li	a3,0
    80001d8e:	4605                	li	a2,1
    80001d90:	020005b7          	lui	a1,0x2000
    80001d94:	15fd                	addi	a1,a1,-1
    80001d96:	05b6                	slli	a1,a1,0xd
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	600080e7          	jalr	1536(ra) # 8000139a <uvmunmap>
  uvmfree(pagetable, sz);
    80001da2:	85ca                	mv	a1,s2
    80001da4:	8526                	mv	a0,s1
    80001da6:	00000097          	auipc	ra,0x0
    80001daa:	8b4080e7          	jalr	-1868(ra) # 8000165a <uvmfree>
}
    80001dae:	60e2                	ld	ra,24(sp)
    80001db0:	6442                	ld	s0,16(sp)
    80001db2:	64a2                	ld	s1,8(sp)
    80001db4:	6902                	ld	s2,0(sp)
    80001db6:	6105                	addi	sp,sp,32
    80001db8:	8082                	ret

0000000080001dba <freeproc>:
{
    80001dba:	1101                	addi	sp,sp,-32
    80001dbc:	ec06                	sd	ra,24(sp)
    80001dbe:	e822                	sd	s0,16(sp)
    80001dc0:	e426                	sd	s1,8(sp)
    80001dc2:	1000                	addi	s0,sp,32
    80001dc4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001dc6:	7d28                	ld	a0,120(a0)
    80001dc8:	c509                	beqz	a0,80001dd2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	c2e080e7          	jalr	-978(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001dd2:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001dd6:	78a8                	ld	a0,112(s1)
    80001dd8:	c511                	beqz	a0,80001de4 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001dda:	74ac                	ld	a1,104(s1)
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	f8c080e7          	jalr	-116(ra) # 80001d68 <proc_freepagetable>
  p->pagetable = 0;
    80001de4:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001de8:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001dec:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001df0:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001df4:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001df8:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001dfc:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e00:	0204a623          	sw	zero,44(s1)
  stateChange(p);
    80001e04:	8526                	mv	a0,s1
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	b5c080e7          	jalr	-1188(ra) # 80001962 <stateChange>
  p->state = UNUSED;
    80001e0e:	0004ac23          	sw	zero,24(s1)
}
    80001e12:	60e2                	ld	ra,24(sp)
    80001e14:	6442                	ld	s0,16(sp)
    80001e16:	64a2                	ld	s1,8(sp)
    80001e18:	6105                	addi	sp,sp,32
    80001e1a:	8082                	ret

0000000080001e1c <allocproc>:
{
    80001e1c:	1101                	addi	sp,sp,-32
    80001e1e:	ec06                	sd	ra,24(sp)
    80001e20:	e822                	sd	s0,16(sp)
    80001e22:	e426                	sd	s1,8(sp)
    80001e24:	e04a                	sd	s2,0(sp)
    80001e26:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e28:	00010497          	auipc	s1,0x10
    80001e2c:	8c848493          	addi	s1,s1,-1848 # 800116f0 <proc>
    80001e30:	00016917          	auipc	s2,0x16
    80001e34:	ac090913          	addi	s2,s2,-1344 # 800178f0 <tickslock>
    acquire(&p->lock);
    80001e38:	8526                	mv	a0,s1
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	daa080e7          	jalr	-598(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001e42:	4c9c                	lw	a5,24(s1)
    80001e44:	cf81                	beqz	a5,80001e5c <allocproc+0x40>
      release(&p->lock);
    80001e46:	8526                	mv	a0,s1
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e50080e7          	jalr	-432(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e50:	18848493          	addi	s1,s1,392
    80001e54:	ff2492e3          	bne	s1,s2,80001e38 <allocproc+0x1c>
  return 0;
    80001e58:	4481                	li	s1,0
    80001e5a:	a0a5                	j	80001ec2 <allocproc+0xa6>
  p->pid = allocpid();
    80001e5c:	00000097          	auipc	ra,0x0
    80001e60:	e2a080e7          	jalr	-470(ra) # 80001c86 <allocpid>
    80001e64:	d888                	sw	a0,48(s1)
  stateChange(p);
    80001e66:	8526                	mv	a0,s1
    80001e68:	00000097          	auipc	ra,0x0
    80001e6c:	afa080e7          	jalr	-1286(ra) # 80001962 <stateChange>
  p->state = USED;
    80001e70:	4785                	li	a5,1
    80001e72:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = 0;
    80001e74:	0404a423          	sw	zero,72(s1)
  p->mean_ticks = 0;
    80001e78:	0404a023          	sw	zero,64(s1)
  p->last_ticks = 0;
    80001e7c:	0404a223          	sw	zero,68(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	c74080e7          	jalr	-908(ra) # 80000af4 <kalloc>
    80001e88:	892a                	mv	s2,a0
    80001e8a:	fca8                	sd	a0,120(s1)
    80001e8c:	c131                	beqz	a0,80001ed0 <allocproc+0xb4>
  p->pagetable = proc_pagetable(p);
    80001e8e:	8526                	mv	a0,s1
    80001e90:	00000097          	auipc	ra,0x0
    80001e94:	e3c080e7          	jalr	-452(ra) # 80001ccc <proc_pagetable>
    80001e98:	892a                	mv	s2,a0
    80001e9a:	f8a8                	sd	a0,112(s1)
  if(p->pagetable == 0){
    80001e9c:	c531                	beqz	a0,80001ee8 <allocproc+0xcc>
  memset(&p->context, 0, sizeof(p->context));
    80001e9e:	07000613          	li	a2,112
    80001ea2:	4581                	li	a1,0
    80001ea4:	08048513          	addi	a0,s1,128
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	e38080e7          	jalr	-456(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001eb0:	00000797          	auipc	a5,0x0
    80001eb4:	d9078793          	addi	a5,a5,-624 # 80001c40 <forkret>
    80001eb8:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001eba:	70bc                	ld	a5,96(s1)
    80001ebc:	6705                	lui	a4,0x1
    80001ebe:	97ba                	add	a5,a5,a4
    80001ec0:	e4dc                	sd	a5,136(s1)
}
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	60e2                	ld	ra,24(sp)
    80001ec6:	6442                	ld	s0,16(sp)
    80001ec8:	64a2                	ld	s1,8(sp)
    80001eca:	6902                	ld	s2,0(sp)
    80001ecc:	6105                	addi	sp,sp,32
    80001ece:	8082                	ret
    freeproc(p);
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	ee8080e7          	jalr	-280(ra) # 80001dba <freeproc>
    release(&p->lock);
    80001eda:	8526                	mv	a0,s1
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	dbc080e7          	jalr	-580(ra) # 80000c98 <release>
    return 0;
    80001ee4:	84ca                	mv	s1,s2
    80001ee6:	bff1                	j	80001ec2 <allocproc+0xa6>
    freeproc(p);
    80001ee8:	8526                	mv	a0,s1
    80001eea:	00000097          	auipc	ra,0x0
    80001eee:	ed0080e7          	jalr	-304(ra) # 80001dba <freeproc>
    release(&p->lock);
    80001ef2:	8526                	mv	a0,s1
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	da4080e7          	jalr	-604(ra) # 80000c98 <release>
    return 0;
    80001efc:	84ca                	mv	s1,s2
    80001efe:	b7d1                	j	80001ec2 <allocproc+0xa6>

0000000080001f00 <userinit>:
{
    80001f00:	1101                	addi	sp,sp,-32
    80001f02:	ec06                	sd	ra,24(sp)
    80001f04:	e822                	sd	s0,16(sp)
    80001f06:	e426                	sd	s1,8(sp)
    80001f08:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f0a:	00000097          	auipc	ra,0x0
    80001f0e:	f12080e7          	jalr	-238(ra) # 80001e1c <allocproc>
    80001f12:	84aa                	mv	s1,a0
  initproc = p;
    80001f14:	00007797          	auipc	a5,0x7
    80001f18:	12a7be23          	sd	a0,316(a5) # 80009050 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f1c:	03400613          	li	a2,52
    80001f20:	00007597          	auipc	a1,0x7
    80001f24:	9e058593          	addi	a1,a1,-1568 # 80008900 <initcode>
    80001f28:	7928                	ld	a0,112(a0)
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	562080e7          	jalr	1378(ra) # 8000148c <uvminit>
  p->sz = PGSIZE;
    80001f32:	6785                	lui	a5,0x1
    80001f34:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f36:	7cb8                	ld	a4,120(s1)
    80001f38:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f3c:	7cb8                	ld	a4,120(s1)
    80001f3e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f40:	4641                	li	a2,16
    80001f42:	00006597          	auipc	a1,0x6
    80001f46:	37e58593          	addi	a1,a1,894 # 800082c0 <digits+0x280>
    80001f4a:	17848513          	addi	a0,s1,376
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	ee4080e7          	jalr	-284(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001f56:	00006517          	auipc	a0,0x6
    80001f5a:	37a50513          	addi	a0,a0,890 # 800082d0 <digits+0x290>
    80001f5e:	00002097          	auipc	ra,0x2
    80001f62:	6ac080e7          	jalr	1708(ra) # 8000460a <namei>
    80001f66:	16a4b823          	sd	a0,368(s1)
  changeStateToRunnable(p);
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	00000097          	auipc	ra,0x0
    80001f70:	a5c080e7          	jalr	-1444(ra) # 800019c8 <changeStateToRunnable>
  release(&p->lock);
    80001f74:	8526                	mv	a0,s1
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	d22080e7          	jalr	-734(ra) # 80000c98 <release>
}
    80001f7e:	60e2                	ld	ra,24(sp)
    80001f80:	6442                	ld	s0,16(sp)
    80001f82:	64a2                	ld	s1,8(sp)
    80001f84:	6105                	addi	sp,sp,32
    80001f86:	8082                	ret

0000000080001f88 <growproc>:
{
    80001f88:	1101                	addi	sp,sp,-32
    80001f8a:	ec06                	sd	ra,24(sp)
    80001f8c:	e822                	sd	s0,16(sp)
    80001f8e:	e426                	sd	s1,8(sp)
    80001f90:	e04a                	sd	s2,0(sp)
    80001f92:	1000                	addi	s0,sp,32
    80001f94:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f96:	00000097          	auipc	ra,0x0
    80001f9a:	c72080e7          	jalr	-910(ra) # 80001c08 <myproc>
    80001f9e:	892a                	mv	s2,a0
  sz = p->sz;
    80001fa0:	752c                	ld	a1,104(a0)
    80001fa2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001fa6:	00904f63          	bgtz	s1,80001fc4 <growproc+0x3c>
  } else if(n < 0){
    80001faa:	0204cc63          	bltz	s1,80001fe2 <growproc+0x5a>
  p->sz = sz;
    80001fae:	1602                	slli	a2,a2,0x20
    80001fb0:	9201                	srli	a2,a2,0x20
    80001fb2:	06c93423          	sd	a2,104(s2)
  return 0;
    80001fb6:	4501                	li	a0,0
}
    80001fb8:	60e2                	ld	ra,24(sp)
    80001fba:	6442                	ld	s0,16(sp)
    80001fbc:	64a2                	ld	s1,8(sp)
    80001fbe:	6902                	ld	s2,0(sp)
    80001fc0:	6105                	addi	sp,sp,32
    80001fc2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fc4:	9e25                	addw	a2,a2,s1
    80001fc6:	1602                	slli	a2,a2,0x20
    80001fc8:	9201                	srli	a2,a2,0x20
    80001fca:	1582                	slli	a1,a1,0x20
    80001fcc:	9181                	srli	a1,a1,0x20
    80001fce:	7928                	ld	a0,112(a0)
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	576080e7          	jalr	1398(ra) # 80001546 <uvmalloc>
    80001fd8:	0005061b          	sext.w	a2,a0
    80001fdc:	fa69                	bnez	a2,80001fae <growproc+0x26>
      return -1;
    80001fde:	557d                	li	a0,-1
    80001fe0:	bfe1                	j	80001fb8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fe2:	9e25                	addw	a2,a2,s1
    80001fe4:	1602                	slli	a2,a2,0x20
    80001fe6:	9201                	srli	a2,a2,0x20
    80001fe8:	1582                	slli	a1,a1,0x20
    80001fea:	9181                	srli	a1,a1,0x20
    80001fec:	7928                	ld	a0,112(a0)
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	510080e7          	jalr	1296(ra) # 800014fe <uvmdealloc>
    80001ff6:	0005061b          	sext.w	a2,a0
    80001ffa:	bf55                	j	80001fae <growproc+0x26>

0000000080001ffc <fork>:
{
    80001ffc:	7179                	addi	sp,sp,-48
    80001ffe:	f406                	sd	ra,40(sp)
    80002000:	f022                	sd	s0,32(sp)
    80002002:	ec26                	sd	s1,24(sp)
    80002004:	e84a                	sd	s2,16(sp)
    80002006:	e44e                	sd	s3,8(sp)
    80002008:	e052                	sd	s4,0(sp)
    8000200a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	bfc080e7          	jalr	-1028(ra) # 80001c08 <myproc>
    80002014:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	e06080e7          	jalr	-506(ra) # 80001e1c <allocproc>
    8000201e:	10050d63          	beqz	a0,80002138 <fork+0x13c>
    80002022:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002024:	06893603          	ld	a2,104(s2)
    80002028:	792c                	ld	a1,112(a0)
    8000202a:	07093503          	ld	a0,112(s2)
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	664080e7          	jalr	1636(ra) # 80001692 <uvmcopy>
    80002036:	04054663          	bltz	a0,80002082 <fork+0x86>
  np->sz = p->sz;
    8000203a:	06893783          	ld	a5,104(s2)
    8000203e:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    80002042:	07893683          	ld	a3,120(s2)
    80002046:	87b6                	mv	a5,a3
    80002048:	0789b703          	ld	a4,120(s3)
    8000204c:	12068693          	addi	a3,a3,288
    80002050:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002054:	6788                	ld	a0,8(a5)
    80002056:	6b8c                	ld	a1,16(a5)
    80002058:	6f90                	ld	a2,24(a5)
    8000205a:	01073023          	sd	a6,0(a4)
    8000205e:	e708                	sd	a0,8(a4)
    80002060:	eb0c                	sd	a1,16(a4)
    80002062:	ef10                	sd	a2,24(a4)
    80002064:	02078793          	addi	a5,a5,32
    80002068:	02070713          	addi	a4,a4,32
    8000206c:	fed792e3          	bne	a5,a3,80002050 <fork+0x54>
  np->trapframe->a0 = 0;
    80002070:	0789b783          	ld	a5,120(s3)
    80002074:	0607b823          	sd	zero,112(a5)
    80002078:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    8000207c:	17000a13          	li	s4,368
    80002080:	a03d                	j	800020ae <fork+0xb2>
    freeproc(np);
    80002082:	854e                	mv	a0,s3
    80002084:	00000097          	auipc	ra,0x0
    80002088:	d36080e7          	jalr	-714(ra) # 80001dba <freeproc>
    release(&np->lock);
    8000208c:	854e                	mv	a0,s3
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	c0a080e7          	jalr	-1014(ra) # 80000c98 <release>
    return -1;
    80002096:	5a7d                	li	s4,-1
    80002098:	a079                	j	80002126 <fork+0x12a>
      np->ofile[i] = filedup(p->ofile[i]);
    8000209a:	00003097          	auipc	ra,0x3
    8000209e:	c06080e7          	jalr	-1018(ra) # 80004ca0 <filedup>
    800020a2:	009987b3          	add	a5,s3,s1
    800020a6:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800020a8:	04a1                	addi	s1,s1,8
    800020aa:	01448763          	beq	s1,s4,800020b8 <fork+0xbc>
    if(p->ofile[i])
    800020ae:	009907b3          	add	a5,s2,s1
    800020b2:	6388                	ld	a0,0(a5)
    800020b4:	f17d                	bnez	a0,8000209a <fork+0x9e>
    800020b6:	bfcd                	j	800020a8 <fork+0xac>
  np->cwd = idup(p->cwd);
    800020b8:	17093503          	ld	a0,368(s2)
    800020bc:	00002097          	auipc	ra,0x2
    800020c0:	d5a080e7          	jalr	-678(ra) # 80003e16 <idup>
    800020c4:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020c8:	4641                	li	a2,16
    800020ca:	17890593          	addi	a1,s2,376
    800020ce:	17898513          	addi	a0,s3,376
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	d60080e7          	jalr	-672(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800020da:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800020de:	854e                	mv	a0,s3
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	bb8080e7          	jalr	-1096(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800020e8:	0000f497          	auipc	s1,0xf
    800020ec:	1f048493          	addi	s1,s1,496 # 800112d8 <wait_lock>
    800020f0:	8526                	mv	a0,s1
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	af2080e7          	jalr	-1294(ra) # 80000be4 <acquire>
  np->parent = p;
    800020fa:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	b98080e7          	jalr	-1128(ra) # 80000c98 <release>
  acquire(&np->lock);
    80002108:	854e                	mv	a0,s3
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	ada080e7          	jalr	-1318(ra) # 80000be4 <acquire>
  changeStateToRunnable(np);
    80002112:	854e                	mv	a0,s3
    80002114:	00000097          	auipc	ra,0x0
    80002118:	8b4080e7          	jalr	-1868(ra) # 800019c8 <changeStateToRunnable>
  release(&np->lock);
    8000211c:	854e                	mv	a0,s3
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	b7a080e7          	jalr	-1158(ra) # 80000c98 <release>
}
    80002126:	8552                	mv	a0,s4
    80002128:	70a2                	ld	ra,40(sp)
    8000212a:	7402                	ld	s0,32(sp)
    8000212c:	64e2                	ld	s1,24(sp)
    8000212e:	6942                	ld	s2,16(sp)
    80002130:	69a2                	ld	s3,8(sp)
    80002132:	6a02                	ld	s4,0(sp)
    80002134:	6145                	addi	sp,sp,48
    80002136:	8082                	ret
    return -1;
    80002138:	5a7d                	li	s4,-1
    8000213a:	b7f5                	j	80002126 <fork+0x12a>

000000008000213c <minMeanTicks>:
{
    8000213c:	7179                	addi	sp,sp,-48
    8000213e:	f406                	sd	ra,40(sp)
    80002140:	f022                	sd	s0,32(sp)
    80002142:	ec26                	sd	s1,24(sp)
    80002144:	e84a                	sd	s2,16(sp)
    80002146:	e44e                	sd	s3,8(sp)
    80002148:	e052                	sd	s4,0(sp)
    8000214a:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    8000214c:	0000f497          	auipc	s1,0xf
    80002150:	5a448493          	addi	s1,s1,1444 # 800116f0 <proc>
    if(p->state == RUNNABLE)
    80002154:	490d                	li	s2,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002156:	00015997          	auipc	s3,0x15
    8000215a:	79a98993          	addi	s3,s3,1946 # 800178f0 <tickslock>
    acquire(&p->lock);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	a84080e7          	jalr	-1404(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE)
    80002168:	4c9c                	lw	a5,24(s1)
    8000216a:	03278f63          	beq	a5,s2,800021a8 <minMeanTicks+0x6c>
    release(&p->lock);
    8000216e:	8526                	mv	a0,s1
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	b28080e7          	jalr	-1240(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002178:	18848493          	addi	s1,s1,392
    8000217c:	ff3491e3          	bne	s1,s3,8000215e <minMeanTicks+0x22>
  acquire(&min->lock);
    80002180:	0000f517          	auipc	a0,0xf
    80002184:	57050513          	addi	a0,a0,1392 # 800116f0 <proc>
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	a5c080e7          	jalr	-1444(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    80002190:	0000f717          	auipc	a4,0xf
    80002194:	57872703          	lw	a4,1400(a4) # 80011708 <proc+0x18>
    80002198:	478d                	li	a5,3
    8000219a:	04f70c63          	beq	a4,a5,800021f2 <minMeanTicks+0xb6>
  min = proc;
    8000219e:	0000f497          	auipc	s1,0xf
    800021a2:	55248493          	addi	s1,s1,1362 # 800116f0 <proc>
    800021a6:	a839                	j	800021c4 <minMeanTicks+0x88>
      release(&p->lock);
    800021a8:	8526                	mv	a0,s1
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	aee080e7          	jalr	-1298(ra) # 80000c98 <release>
  acquire(&min->lock);
    800021b2:	8526                	mv	a0,s1
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	a30080e7          	jalr	-1488(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    800021bc:	4c98                	lw	a4,24(s1)
    800021be:	478d                	li	a5,3
    800021c0:	00f70b63          	beq	a4,a5,800021d6 <minMeanTicks+0x9a>
}
    800021c4:	8526                	mv	a0,s1
    800021c6:	70a2                	ld	ra,40(sp)
    800021c8:	7402                	ld	s0,32(sp)
    800021ca:	64e2                	ld	s1,24(sp)
    800021cc:	6942                	ld	s2,16(sp)
    800021ce:	69a2                	ld	s3,8(sp)
    800021d0:	6a02                	ld	s4,0(sp)
    800021d2:	6145                	addi	sp,sp,48
    800021d4:	8082                	ret
    for (p = min+1; p < &proc[NPROC]; p++)
    800021d6:	18848913          	addi	s2,s1,392
    800021da:	00015797          	auipc	a5,0x15
    800021de:	71678793          	addi	a5,a5,1814 # 800178f0 <tickslock>
    800021e2:	fef971e3          	bgeu	s2,a5,800021c4 <minMeanTicks+0x88>
      if(p->state == RUNNABLE && min->mean_ticks > p->mean_ticks)
    800021e6:	4a0d                	li	s4,3
    for (p = min+1; p < &proc[NPROC]; p++)
    800021e8:	00015997          	auipc	s3,0x15
    800021ec:	70898993          	addi	s3,s3,1800 # 800178f0 <tickslock>
    800021f0:	a01d                	j	80002216 <minMeanTicks+0xda>
  min = proc;
    800021f2:	0000f497          	auipc	s1,0xf
    800021f6:	4fe48493          	addi	s1,s1,1278 # 800116f0 <proc>
    for (p = min+1; p < &proc[NPROC]; p++)
    800021fa:	0000f917          	auipc	s2,0xf
    800021fe:	67e90913          	addi	s2,s2,1662 # 80011878 <proc+0x188>
    80002202:	b7d5                	j	800021e6 <minMeanTicks+0xaa>
        release(&p->lock);
    80002204:	854a                	mv	a0,s2
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
    for (p = min+1; p < &proc[NPROC]; p++)
    8000220e:	18890913          	addi	s2,s2,392
    80002212:	fb3979e3          	bgeu	s2,s3,800021c4 <minMeanTicks+0x88>
      acquire(&p->lock);
    80002216:	854a                	mv	a0,s2
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	9cc080e7          	jalr	-1588(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && min->mean_ticks > p->mean_ticks)
    80002220:	01892783          	lw	a5,24(s2)
    80002224:	ff4790e3          	bne	a5,s4,80002204 <minMeanTicks+0xc8>
    80002228:	40b8                	lw	a4,64(s1)
    8000222a:	04092783          	lw	a5,64(s2)
    8000222e:	fce7dbe3          	bge	a5,a4,80002204 <minMeanTicks+0xc8>
        release(&min->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	a64080e7          	jalr	-1436(ra) # 80000c98 <release>
        min = p;
    8000223c:	84ca                	mv	s1,s2
    8000223e:	bfc1                	j	8000220e <minMeanTicks+0xd2>

0000000080002240 <SJFScheduler>:
{
    80002240:	711d                	addi	sp,sp,-96
    80002242:	ec86                	sd	ra,88(sp)
    80002244:	e8a2                	sd	s0,80(sp)
    80002246:	e4a6                	sd	s1,72(sp)
    80002248:	e0ca                	sd	s2,64(sp)
    8000224a:	fc4e                	sd	s3,56(sp)
    8000224c:	f852                	sd	s4,48(sp)
    8000224e:	f456                	sd	s5,40(sp)
    80002250:	f05a                	sd	s6,32(sp)
    80002252:	ec5e                	sd	s7,24(sp)
    80002254:	e862                	sd	s8,16(sp)
    80002256:	e466                	sd	s9,8(sp)
    80002258:	1080                	addi	s0,sp,96
    8000225a:	8792                	mv	a5,tp
  int id = r_tp();
    8000225c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000225e:	00779b13          	slli	s6,a5,0x7
    80002262:	0000f717          	auipc	a4,0xf
    80002266:	05e70713          	addi	a4,a4,94 # 800112c0 <pid_lock>
    8000226a:	975a                	add	a4,a4,s6
    8000226c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002270:	0000f717          	auipc	a4,0xf
    80002274:	08870713          	addi	a4,a4,136 # 800112f8 <cpus+0x8>
    80002278:	9b3a                	add	s6,s6,a4
    if (ticks >= nextGoodTicks)
    8000227a:	00007917          	auipc	s2,0x7
    8000227e:	dde90913          	addi	s2,s2,-546 # 80009058 <ticks>
    80002282:	00007997          	auipc	s3,0x7
    80002286:	dca98993          	addi	s3,s3,-566 # 8000904c <nextGoodTicks>
      if (p->state == RUNNABLE)
    8000228a:	4a0d                	li	s4,3
        p->state = RUNNING;
    8000228c:	4c11                	li	s8,4
        c->proc = p;
    8000228e:	079e                	slli	a5,a5,0x7
    80002290:	0000fa97          	auipc	s5,0xf
    80002294:	030a8a93          	addi	s5,s5,48 # 800112c0 <pid_lock>
    80002298:	9abe                	add	s5,s5,a5
        p->mean_ticks =  ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    8000229a:	00006b97          	auipc	s7,0x6
    8000229e:	65ab8b93          	addi	s7,s7,1626 # 800088f4 <rate>
    800022a2:	a031                	j	800022ae <SJFScheduler+0x6e>
    release(&p->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	9f2080e7          	jalr	-1550(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022b2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022b6:	10079073          	csrw	sstatus,a5
    p = minMeanTicks();
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	e82080e7          	jalr	-382(ra) # 8000213c <minMeanTicks>
    800022c2:	84aa                	mv	s1,a0
    if (ticks >= nextGoodTicks)
    800022c4:	00092703          	lw	a4,0(s2)
    800022c8:	0009a783          	lw	a5,0(s3)
    800022cc:	fcf76ce3          	bltu	a4,a5,800022a4 <SJFScheduler+0x64>
      if (p->state == RUNNABLE)
    800022d0:	4d1c                	lw	a5,24(a0)
    800022d2:	fd4799e3          	bne	a5,s4,800022a4 <SJFScheduler+0x64>
        stateChange(p);
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	68c080e7          	jalr	1676(ra) # 80001962 <stateChange>
        p->state = RUNNING;
    800022de:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    800022e2:	029ab823          	sd	s1,48(s5)
        prevTicks = ticks;
    800022e6:	00092c83          	lw	s9,0(s2)
        swtch(&c->context, &p->context);
    800022ea:	08048593          	addi	a1,s1,128
    800022ee:	855a                	mv	a0,s6
    800022f0:	00001097          	auipc	ra,0x1
    800022f4:	a9e080e7          	jalr	-1378(ra) # 80002d8e <swtch>
        c->proc = 0;
    800022f8:	020ab823          	sd	zero,48(s5)
        p->last_ticks = ticks - prevTicks;
    800022fc:	00092703          	lw	a4,0(s2)
    80002300:	4197073b          	subw	a4,a4,s9
    80002304:	c0f8                	sw	a4,68(s1)
        p->mean_ticks =  ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    80002306:	000ba603          	lw	a2,0(s7)
    8000230a:	46a9                	li	a3,10
    8000230c:	40c687bb          	subw	a5,a3,a2
    80002310:	40ac                	lw	a1,64(s1)
    80002312:	02b787bb          	mulw	a5,a5,a1
    80002316:	02c7073b          	mulw	a4,a4,a2
    8000231a:	9fb9                	addw	a5,a5,a4
    8000231c:	02d7c7bb          	divw	a5,a5,a3
    80002320:	c0bc                	sw	a5,64(s1)
    80002322:	b749                	j	800022a4 <SJFScheduler+0x64>

0000000080002324 <minLastRunnableTime>:
{
    80002324:	7179                	addi	sp,sp,-48
    80002326:	f406                	sd	ra,40(sp)
    80002328:	f022                	sd	s0,32(sp)
    8000232a:	ec26                	sd	s1,24(sp)
    8000232c:	e84a                	sd	s2,16(sp)
    8000232e:	e44e                	sd	s3,8(sp)
    80002330:	e052                	sd	s4,0(sp)
    80002332:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80002334:	0000f497          	auipc	s1,0xf
    80002338:	3bc48493          	addi	s1,s1,956 # 800116f0 <proc>
    if(p->state == RUNNABLE)
    8000233c:	490d                	li	s2,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000233e:	00015997          	auipc	s3,0x15
    80002342:	5b298993          	addi	s3,s3,1458 # 800178f0 <tickslock>
    acquire(&p->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	89c080e7          	jalr	-1892(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE)
    80002350:	4c9c                	lw	a5,24(s1)
    80002352:	03278f63          	beq	a5,s2,80002390 <minLastRunnableTime+0x6c>
    release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	940080e7          	jalr	-1728(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002360:	18848493          	addi	s1,s1,392
    80002364:	ff3491e3          	bne	s1,s3,80002346 <minLastRunnableTime+0x22>
  acquire(&min->lock);
    80002368:	0000f517          	auipc	a0,0xf
    8000236c:	38850513          	addi	a0,a0,904 # 800116f0 <proc>
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	874080e7          	jalr	-1932(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    80002378:	0000f717          	auipc	a4,0xf
    8000237c:	39072703          	lw	a4,912(a4) # 80011708 <proc+0x18>
    80002380:	478d                	li	a5,3
    80002382:	04f70c63          	beq	a4,a5,800023da <minLastRunnableTime+0xb6>
  min = proc;
    80002386:	0000f497          	auipc	s1,0xf
    8000238a:	36a48493          	addi	s1,s1,874 # 800116f0 <proc>
    8000238e:	a839                	j	800023ac <minLastRunnableTime+0x88>
      release(&p->lock);
    80002390:	8526                	mv	a0,s1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	906080e7          	jalr	-1786(ra) # 80000c98 <release>
  acquire(&min->lock);
    8000239a:	8526                	mv	a0,s1
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	848080e7          	jalr	-1976(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    800023a4:	4c98                	lw	a4,24(s1)
    800023a6:	478d                	li	a5,3
    800023a8:	00f70b63          	beq	a4,a5,800023be <minLastRunnableTime+0x9a>
}
    800023ac:	8526                	mv	a0,s1
    800023ae:	70a2                	ld	ra,40(sp)
    800023b0:	7402                	ld	s0,32(sp)
    800023b2:	64e2                	ld	s1,24(sp)
    800023b4:	6942                	ld	s2,16(sp)
    800023b6:	69a2                	ld	s3,8(sp)
    800023b8:	6a02                	ld	s4,0(sp)
    800023ba:	6145                	addi	sp,sp,48
    800023bc:	8082                	ret
    for (p = min+1; p < &proc[NPROC]; p++)
    800023be:	18848913          	addi	s2,s1,392
    800023c2:	00015797          	auipc	a5,0x15
    800023c6:	52e78793          	addi	a5,a5,1326 # 800178f0 <tickslock>
    800023ca:	fef971e3          	bgeu	s2,a5,800023ac <minLastRunnableTime+0x88>
      if(p->state == RUNNABLE && min->last_runnable_time > p->last_runnable_time)
    800023ce:	4a0d                	li	s4,3
    for (p = min+1; p < &proc[NPROC]; p++)
    800023d0:	00015997          	auipc	s3,0x15
    800023d4:	52098993          	addi	s3,s3,1312 # 800178f0 <tickslock>
    800023d8:	a01d                	j	800023fe <minLastRunnableTime+0xda>
  min = proc;
    800023da:	0000f497          	auipc	s1,0xf
    800023de:	31648493          	addi	s1,s1,790 # 800116f0 <proc>
    for (p = min+1; p < &proc[NPROC]; p++)
    800023e2:	0000f917          	auipc	s2,0xf
    800023e6:	49690913          	addi	s2,s2,1174 # 80011878 <proc+0x188>
    800023ea:	b7d5                	j	800023ce <minLastRunnableTime+0xaa>
        release(&p->lock);
    800023ec:	854a                	mv	a0,s2
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	8aa080e7          	jalr	-1878(ra) # 80000c98 <release>
    for (p = min+1; p < &proc[NPROC]; p++)
    800023f6:	18890913          	addi	s2,s2,392
    800023fa:	fb3979e3          	bgeu	s2,s3,800023ac <minLastRunnableTime+0x88>
      acquire(&p->lock);
    800023fe:	854a                	mv	a0,s2
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7e4080e7          	jalr	2020(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && min->last_runnable_time > p->last_runnable_time)
    80002408:	01892783          	lw	a5,24(s2)
    8000240c:	ff4790e3          	bne	a5,s4,800023ec <minLastRunnableTime+0xc8>
    80002410:	44b8                	lw	a4,72(s1)
    80002412:	04892783          	lw	a5,72(s2)
    80002416:	fce7dbe3          	bge	a5,a4,800023ec <minLastRunnableTime+0xc8>
        release(&min->lock);
    8000241a:	8526                	mv	a0,s1
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	87c080e7          	jalr	-1924(ra) # 80000c98 <release>
        min = p;
    80002424:	84ca                	mv	s1,s2
    80002426:	bfc1                	j	800023f6 <minLastRunnableTime+0xd2>

0000000080002428 <FCFSScheduler>:
{
    80002428:	715d                	addi	sp,sp,-80
    8000242a:	e486                	sd	ra,72(sp)
    8000242c:	e0a2                	sd	s0,64(sp)
    8000242e:	fc26                	sd	s1,56(sp)
    80002430:	f84a                	sd	s2,48(sp)
    80002432:	f44e                	sd	s3,40(sp)
    80002434:	f052                	sd	s4,32(sp)
    80002436:	ec56                	sd	s5,24(sp)
    80002438:	e85a                	sd	s6,16(sp)
    8000243a:	e45e                	sd	s7,8(sp)
    8000243c:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    8000243e:	8792                	mv	a5,tp
  int id = r_tp();
    80002440:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002442:	00779b13          	slli	s6,a5,0x7
    80002446:	0000f717          	auipc	a4,0xf
    8000244a:	e7a70713          	addi	a4,a4,-390 # 800112c0 <pid_lock>
    8000244e:	975a                	add	a4,a4,s6
    80002450:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002454:	0000f717          	auipc	a4,0xf
    80002458:	ea470713          	addi	a4,a4,-348 # 800112f8 <cpus+0x8>
    8000245c:	9b3a                	add	s6,s6,a4
    if (ticks >= nextGoodTicks)
    8000245e:	00007997          	auipc	s3,0x7
    80002462:	bfa98993          	addi	s3,s3,-1030 # 80009058 <ticks>
    80002466:	00007917          	auipc	s2,0x7
    8000246a:	be690913          	addi	s2,s2,-1050 # 8000904c <nextGoodTicks>
      if (p->state == RUNNABLE)
    8000246e:	4a0d                	li	s4,3
        p->state = RUNNING;
    80002470:	4b91                	li	s7,4
        c->proc = p;
    80002472:	079e                	slli	a5,a5,0x7
    80002474:	0000fa97          	auipc	s5,0xf
    80002478:	e4ca8a93          	addi	s5,s5,-436 # 800112c0 <pid_lock>
    8000247c:	9abe                	add	s5,s5,a5
    8000247e:	a031                	j	8000248a <FCFSScheduler+0x62>
    release(&p->lock);
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	816080e7          	jalr	-2026(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000248a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000248e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002492:	10079073          	csrw	sstatus,a5
    p = minLastRunnableTime();
    80002496:	00000097          	auipc	ra,0x0
    8000249a:	e8e080e7          	jalr	-370(ra) # 80002324 <minLastRunnableTime>
    8000249e:	84aa                	mv	s1,a0
    if (ticks >= nextGoodTicks)
    800024a0:	0009a703          	lw	a4,0(s3)
    800024a4:	00092783          	lw	a5,0(s2)
    800024a8:	fcf76ce3          	bltu	a4,a5,80002480 <FCFSScheduler+0x58>
      if (p->state == RUNNABLE)
    800024ac:	4d1c                	lw	a5,24(a0)
    800024ae:	fd4799e3          	bne	a5,s4,80002480 <FCFSScheduler+0x58>
        stateChange(p);
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	4b0080e7          	jalr	1200(ra) # 80001962 <stateChange>
        p->state = RUNNING;
    800024ba:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    800024be:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    800024c2:	08048593          	addi	a1,s1,128
    800024c6:	855a                	mv	a0,s6
    800024c8:	00001097          	auipc	ra,0x1
    800024cc:	8c6080e7          	jalr	-1850(ra) # 80002d8e <swtch>
        c->proc = 0;
    800024d0:	020ab823          	sd	zero,48(s5)
    800024d4:	b775                	j	80002480 <FCFSScheduler+0x58>

00000000800024d6 <regulerScheduler>:
{
    800024d6:	715d                	addi	sp,sp,-80
    800024d8:	e486                	sd	ra,72(sp)
    800024da:	e0a2                	sd	s0,64(sp)
    800024dc:	fc26                	sd	s1,56(sp)
    800024de:	f84a                	sd	s2,48(sp)
    800024e0:	f44e                	sd	s3,40(sp)
    800024e2:	f052                	sd	s4,32(sp)
    800024e4:	ec56                	sd	s5,24(sp)
    800024e6:	e85a                	sd	s6,16(sp)
    800024e8:	e45e                	sd	s7,8(sp)
    800024ea:	e062                	sd	s8,0(sp)
    800024ec:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    800024ee:	8792                	mv	a5,tp
  int id = r_tp();
    800024f0:	2781                	sext.w	a5,a5
  c->proc = 0;
    800024f2:	00779c13          	slli	s8,a5,0x7
    800024f6:	0000f717          	auipc	a4,0xf
    800024fa:	dca70713          	addi	a4,a4,-566 # 800112c0 <pid_lock>
    800024fe:	9762                	add	a4,a4,s8
    80002500:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80002504:	0000f717          	auipc	a4,0xf
    80002508:	df470713          	addi	a4,a4,-524 # 800112f8 <cpus+0x8>
    8000250c:	9c3a                	add	s8,s8,a4
      if (ticks >= nextGoodTicks)
    8000250e:	00007a17          	auipc	s4,0x7
    80002512:	b4aa0a13          	addi	s4,s4,-1206 # 80009058 <ticks>
    80002516:	00007997          	auipc	s3,0x7
    8000251a:	b3698993          	addi	s3,s3,-1226 # 8000904c <nextGoodTicks>
        if (p->state == RUNNABLE)
    8000251e:	4a8d                	li	s5,3
          c->proc = p;
    80002520:	079e                	slli	a5,a5,0x7
    80002522:	0000fb17          	auipc	s6,0xf
    80002526:	d9eb0b13          	addi	s6,s6,-610 # 800112c0 <pid_lock>
    8000252a:	9b3e                	add	s6,s6,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000252c:	00015917          	auipc	s2,0x15
    80002530:	3c490913          	addi	s2,s2,964 # 800178f0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002534:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002538:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000253c:	10079073          	csrw	sstatus,a5
    80002540:	0000f497          	auipc	s1,0xf
    80002544:	1b048493          	addi	s1,s1,432 # 800116f0 <proc>
          p->state = RUNNING;
    80002548:	4b91                	li	s7,4
    8000254a:	a825                	j	80002582 <regulerScheduler+0xac>
          stateChange(p);
    8000254c:	8526                	mv	a0,s1
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	414080e7          	jalr	1044(ra) # 80001962 <stateChange>
          p->state = RUNNING;
    80002556:	0174ac23          	sw	s7,24(s1)
          c->proc = p;
    8000255a:	029b3823          	sd	s1,48(s6)
          swtch(&c->context, &p->context);
    8000255e:	08048593          	addi	a1,s1,128
    80002562:	8562                	mv	a0,s8
    80002564:	00001097          	auipc	ra,0x1
    80002568:	82a080e7          	jalr	-2006(ra) # 80002d8e <swtch>
          c->proc = 0;
    8000256c:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    80002570:	8526                	mv	a0,s1
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	726080e7          	jalr	1830(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000257a:	18848493          	addi	s1,s1,392
    8000257e:	fb248be3          	beq	s1,s2,80002534 <regulerScheduler+0x5e>
      if (ticks >= nextGoodTicks)
    80002582:	000a2703          	lw	a4,0(s4)
    80002586:	0009a783          	lw	a5,0(s3)
    8000258a:	fef768e3          	bltu	a4,a5,8000257a <regulerScheduler+0xa4>
        acquire(&p->lock);
    8000258e:	8526                	mv	a0,s1
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	654080e7          	jalr	1620(ra) # 80000be4 <acquire>
        if (p->state == RUNNABLE)
    80002598:	4c9c                	lw	a5,24(s1)
    8000259a:	fd579be3          	bne	a5,s5,80002570 <regulerScheduler+0x9a>
    8000259e:	b77d                	j	8000254c <regulerScheduler+0x76>

00000000800025a0 <scheduler>:
{
    800025a0:	1141                	addi	sp,sp,-16
    800025a2:	e406                	sd	ra,8(sp)
    800025a4:	e022                	sd	s0,0(sp)
    800025a6:	0800                	addi	s0,sp,16
    regulerScheduler();
    800025a8:	00000097          	auipc	ra,0x0
    800025ac:	f2e080e7          	jalr	-210(ra) # 800024d6 <regulerScheduler>

00000000800025b0 <sched>:
{
    800025b0:	7179                	addi	sp,sp,-48
    800025b2:	f406                	sd	ra,40(sp)
    800025b4:	f022                	sd	s0,32(sp)
    800025b6:	ec26                	sd	s1,24(sp)
    800025b8:	e84a                	sd	s2,16(sp)
    800025ba:	e44e                	sd	s3,8(sp)
    800025bc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	64a080e7          	jalr	1610(ra) # 80001c08 <myproc>
    800025c6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	5a2080e7          	jalr	1442(ra) # 80000b6a <holding>
    800025d0:	c93d                	beqz	a0,80002646 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025d2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800025d4:	2781                	sext.w	a5,a5
    800025d6:	079e                	slli	a5,a5,0x7
    800025d8:	0000f717          	auipc	a4,0xf
    800025dc:	ce870713          	addi	a4,a4,-792 # 800112c0 <pid_lock>
    800025e0:	97ba                	add	a5,a5,a4
    800025e2:	0a87a703          	lw	a4,168(a5)
    800025e6:	4785                	li	a5,1
    800025e8:	06f71763          	bne	a4,a5,80002656 <sched+0xa6>
  if(p->state == RUNNING)
    800025ec:	4c98                	lw	a4,24(s1)
    800025ee:	4791                	li	a5,4
    800025f0:	06f70b63          	beq	a4,a5,80002666 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025f4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025f8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800025fa:	efb5                	bnez	a5,80002676 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025fc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025fe:	0000f917          	auipc	s2,0xf
    80002602:	cc290913          	addi	s2,s2,-830 # 800112c0 <pid_lock>
    80002606:	2781                	sext.w	a5,a5
    80002608:	079e                	slli	a5,a5,0x7
    8000260a:	97ca                	add	a5,a5,s2
    8000260c:	0ac7a983          	lw	s3,172(a5)
    80002610:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002612:	2781                	sext.w	a5,a5
    80002614:	079e                	slli	a5,a5,0x7
    80002616:	0000f597          	auipc	a1,0xf
    8000261a:	ce258593          	addi	a1,a1,-798 # 800112f8 <cpus+0x8>
    8000261e:	95be                	add	a1,a1,a5
    80002620:	08048513          	addi	a0,s1,128
    80002624:	00000097          	auipc	ra,0x0
    80002628:	76a080e7          	jalr	1898(ra) # 80002d8e <swtch>
    8000262c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000262e:	2781                	sext.w	a5,a5
    80002630:	079e                	slli	a5,a5,0x7
    80002632:	97ca                	add	a5,a5,s2
    80002634:	0b37a623          	sw	s3,172(a5)
}
    80002638:	70a2                	ld	ra,40(sp)
    8000263a:	7402                	ld	s0,32(sp)
    8000263c:	64e2                	ld	s1,24(sp)
    8000263e:	6942                	ld	s2,16(sp)
    80002640:	69a2                	ld	s3,8(sp)
    80002642:	6145                	addi	sp,sp,48
    80002644:	8082                	ret
    panic("sched p->lock");
    80002646:	00006517          	auipc	a0,0x6
    8000264a:	c9250513          	addi	a0,a0,-878 # 800082d8 <digits+0x298>
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	ef0080e7          	jalr	-272(ra) # 8000053e <panic>
    panic("sched locks");
    80002656:	00006517          	auipc	a0,0x6
    8000265a:	c9250513          	addi	a0,a0,-878 # 800082e8 <digits+0x2a8>
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>
    panic("sched running");
    80002666:	00006517          	auipc	a0,0x6
    8000266a:	c9250513          	addi	a0,a0,-878 # 800082f8 <digits+0x2b8>
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	ed0080e7          	jalr	-304(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002676:	00006517          	auipc	a0,0x6
    8000267a:	c9250513          	addi	a0,a0,-878 # 80008308 <digits+0x2c8>
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	ec0080e7          	jalr	-320(ra) # 8000053e <panic>

0000000080002686 <yield>:
{
    80002686:	1101                	addi	sp,sp,-32
    80002688:	ec06                	sd	ra,24(sp)
    8000268a:	e822                	sd	s0,16(sp)
    8000268c:	e426                	sd	s1,8(sp)
    8000268e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002690:	fffff097          	auipc	ra,0xfffff
    80002694:	578080e7          	jalr	1400(ra) # 80001c08 <myproc>
    80002698:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000269a:	ffffe097          	auipc	ra,0xffffe
    8000269e:	54a080e7          	jalr	1354(ra) # 80000be4 <acquire>
  changeStateToRunnable(p);
    800026a2:	8526                	mv	a0,s1
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	324080e7          	jalr	804(ra) # 800019c8 <changeStateToRunnable>
  sched();
    800026ac:	00000097          	auipc	ra,0x0
    800026b0:	f04080e7          	jalr	-252(ra) # 800025b0 <sched>
  release(&p->lock);
    800026b4:	8526                	mv	a0,s1
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	5e2080e7          	jalr	1506(ra) # 80000c98 <release>
}
    800026be:	60e2                	ld	ra,24(sp)
    800026c0:	6442                	ld	s0,16(sp)
    800026c2:	64a2                	ld	s1,8(sp)
    800026c4:	6105                	addi	sp,sp,32
    800026c6:	8082                	ret

00000000800026c8 <pause_system>:
{
    800026c8:	7179                	addi	sp,sp,-48
    800026ca:	f406                	sd	ra,40(sp)
    800026cc:	f022                	sd	s0,32(sp)
    800026ce:	ec26                	sd	s1,24(sp)
    800026d0:	e84a                	sd	s2,16(sp)
    800026d2:	e44e                	sd	s3,8(sp)
    800026d4:	e052                	sd	s4,0(sp)
    800026d6:	1800                	addi	s0,sp,48
  nextGoodTicks = ticks + 10 * seconds;
    800026d8:	0025179b          	slliw	a5,a0,0x2
    800026dc:	9fa9                	addw	a5,a5,a0
    800026de:	0017979b          	slliw	a5,a5,0x1
    800026e2:	00007717          	auipc	a4,0x7
    800026e6:	97672703          	lw	a4,-1674(a4) # 80009058 <ticks>
    800026ea:	9fb9                	addw	a5,a5,a4
    800026ec:	00007717          	auipc	a4,0x7
    800026f0:	96f72023          	sw	a5,-1696(a4) # 8000904c <nextGoodTicks>
  for (p = proc; p < &proc[NPROC]; p++)
    800026f4:	0000f497          	auipc	s1,0xf
    800026f8:	ffc48493          	addi	s1,s1,-4 # 800116f0 <proc>
    if (p->state == RUNNING && p->pid > 2)
    800026fc:	4991                	li	s3,4
    800026fe:	4a09                	li	s4,2
  for (p = proc; p < &proc[NPROC]; p++)
    80002700:	00015917          	auipc	s2,0x15
    80002704:	1f090913          	addi	s2,s2,496 # 800178f0 <tickslock>
    80002708:	a839                	j	80002726 <pause_system+0x5e>
      changeStateToRunnable(p);
    8000270a:	8526                	mv	a0,s1
    8000270c:	fffff097          	auipc	ra,0xfffff
    80002710:	2bc080e7          	jalr	700(ra) # 800019c8 <changeStateToRunnable>
    release(&p->lock);
    80002714:	8526                	mv	a0,s1
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	582080e7          	jalr	1410(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000271e:	18848493          	addi	s1,s1,392
    80002722:	01248e63          	beq	s1,s2,8000273e <pause_system+0x76>
    acquire(&p->lock);
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	4bc080e7          	jalr	1212(ra) # 80000be4 <acquire>
    if (p->state == RUNNING && p->pid > 2)
    80002730:	4c9c                	lw	a5,24(s1)
    80002732:	ff3791e3          	bne	a5,s3,80002714 <pause_system+0x4c>
    80002736:	589c                	lw	a5,48(s1)
    80002738:	fcfa5ee3          	bge	s4,a5,80002714 <pause_system+0x4c>
    8000273c:	b7f9                	j	8000270a <pause_system+0x42>
  yield();
    8000273e:	00000097          	auipc	ra,0x0
    80002742:	f48080e7          	jalr	-184(ra) # 80002686 <yield>
}
    80002746:	4501                	li	a0,0
    80002748:	70a2                	ld	ra,40(sp)
    8000274a:	7402                	ld	s0,32(sp)
    8000274c:	64e2                	ld	s1,24(sp)
    8000274e:	6942                	ld	s2,16(sp)
    80002750:	69a2                	ld	s3,8(sp)
    80002752:	6a02                	ld	s4,0(sp)
    80002754:	6145                	addi	sp,sp,48
    80002756:	8082                	ret

0000000080002758 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002758:	7179                	addi	sp,sp,-48
    8000275a:	f406                	sd	ra,40(sp)
    8000275c:	f022                	sd	s0,32(sp)
    8000275e:	ec26                	sd	s1,24(sp)
    80002760:	e84a                	sd	s2,16(sp)
    80002762:	e44e                	sd	s3,8(sp)
    80002764:	1800                	addi	s0,sp,48
    80002766:	89aa                	mv	s3,a0
    80002768:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000276a:	fffff097          	auipc	ra,0xfffff
    8000276e:	49e080e7          	jalr	1182(ra) # 80001c08 <myproc>
    80002772:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	470080e7          	jalr	1136(ra) # 80000be4 <acquire>
  release(lk);
    8000277c:	854a                	mv	a0,s2
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	51a080e7          	jalr	1306(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002786:	0334b023          	sd	s3,32(s1)

  stateChange(p);
    8000278a:	8526                	mv	a0,s1
    8000278c:	fffff097          	auipc	ra,0xfffff
    80002790:	1d6080e7          	jalr	470(ra) # 80001962 <stateChange>
  p->state = SLEEPING;
    80002794:	4789                	li	a5,2
    80002796:	cc9c                	sw	a5,24(s1)

  sched();
    80002798:	00000097          	auipc	ra,0x0
    8000279c:	e18080e7          	jalr	-488(ra) # 800025b0 <sched>

  // Tidy up.
  p->chan = 0;
    800027a0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800027a4:	8526                	mv	a0,s1
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	4f2080e7          	jalr	1266(ra) # 80000c98 <release>
  acquire(lk);
    800027ae:	854a                	mv	a0,s2
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	434080e7          	jalr	1076(ra) # 80000be4 <acquire>
}
    800027b8:	70a2                	ld	ra,40(sp)
    800027ba:	7402                	ld	s0,32(sp)
    800027bc:	64e2                	ld	s1,24(sp)
    800027be:	6942                	ld	s2,16(sp)
    800027c0:	69a2                	ld	s3,8(sp)
    800027c2:	6145                	addi	sp,sp,48
    800027c4:	8082                	ret

00000000800027c6 <wait>:
{
    800027c6:	715d                	addi	sp,sp,-80
    800027c8:	e486                	sd	ra,72(sp)
    800027ca:	e0a2                	sd	s0,64(sp)
    800027cc:	fc26                	sd	s1,56(sp)
    800027ce:	f84a                	sd	s2,48(sp)
    800027d0:	f44e                	sd	s3,40(sp)
    800027d2:	f052                	sd	s4,32(sp)
    800027d4:	ec56                	sd	s5,24(sp)
    800027d6:	e85a                	sd	s6,16(sp)
    800027d8:	e45e                	sd	s7,8(sp)
    800027da:	e062                	sd	s8,0(sp)
    800027dc:	0880                	addi	s0,sp,80
    800027de:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027e0:	fffff097          	auipc	ra,0xfffff
    800027e4:	428080e7          	jalr	1064(ra) # 80001c08 <myproc>
    800027e8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027ea:	0000f517          	auipc	a0,0xf
    800027ee:	aee50513          	addi	a0,a0,-1298 # 800112d8 <wait_lock>
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	3f2080e7          	jalr	1010(ra) # 80000be4 <acquire>
    havekids = 0;
    800027fa:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800027fc:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800027fe:	00015997          	auipc	s3,0x15
    80002802:	0f298993          	addi	s3,s3,242 # 800178f0 <tickslock>
        havekids = 1;
    80002806:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002808:	0000fc17          	auipc	s8,0xf
    8000280c:	ad0c0c13          	addi	s8,s8,-1328 # 800112d8 <wait_lock>
    havekids = 0;
    80002810:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002812:	0000f497          	auipc	s1,0xf
    80002816:	ede48493          	addi	s1,s1,-290 # 800116f0 <proc>
    8000281a:	a0bd                	j	80002888 <wait+0xc2>
          pid = np->pid;
    8000281c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002820:	000b0e63          	beqz	s6,8000283c <wait+0x76>
    80002824:	4691                	li	a3,4
    80002826:	02c48613          	addi	a2,s1,44
    8000282a:	85da                	mv	a1,s6
    8000282c:	07093503          	ld	a0,112(s2)
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	f66080e7          	jalr	-154(ra) # 80001796 <copyout>
    80002838:	02054563          	bltz	a0,80002862 <wait+0x9c>
          freeproc(np);
    8000283c:	8526                	mv	a0,s1
    8000283e:	fffff097          	auipc	ra,0xfffff
    80002842:	57c080e7          	jalr	1404(ra) # 80001dba <freeproc>
          release(&np->lock);
    80002846:	8526                	mv	a0,s1
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	450080e7          	jalr	1104(ra) # 80000c98 <release>
          release(&wait_lock);
    80002850:	0000f517          	auipc	a0,0xf
    80002854:	a8850513          	addi	a0,a0,-1400 # 800112d8 <wait_lock>
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	440080e7          	jalr	1088(ra) # 80000c98 <release>
          return pid;
    80002860:	a09d                	j	800028c6 <wait+0x100>
            release(&np->lock);
    80002862:	8526                	mv	a0,s1
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	434080e7          	jalr	1076(ra) # 80000c98 <release>
            release(&wait_lock);
    8000286c:	0000f517          	auipc	a0,0xf
    80002870:	a6c50513          	addi	a0,a0,-1428 # 800112d8 <wait_lock>
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	424080e7          	jalr	1060(ra) # 80000c98 <release>
            return -1;
    8000287c:	59fd                	li	s3,-1
    8000287e:	a0a1                	j	800028c6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002880:	18848493          	addi	s1,s1,392
    80002884:	03348463          	beq	s1,s3,800028ac <wait+0xe6>
      if(np->parent == p){
    80002888:	7c9c                	ld	a5,56(s1)
    8000288a:	ff279be3          	bne	a5,s2,80002880 <wait+0xba>
        acquire(&np->lock);
    8000288e:	8526                	mv	a0,s1
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	354080e7          	jalr	852(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002898:	4c9c                	lw	a5,24(s1)
    8000289a:	f94781e3          	beq	a5,s4,8000281c <wait+0x56>
        release(&np->lock);
    8000289e:	8526                	mv	a0,s1
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	3f8080e7          	jalr	1016(ra) # 80000c98 <release>
        havekids = 1;
    800028a8:	8756                	mv	a4,s5
    800028aa:	bfd9                	j	80002880 <wait+0xba>
    if(!havekids || p->killed){
    800028ac:	c701                	beqz	a4,800028b4 <wait+0xee>
    800028ae:	02892783          	lw	a5,40(s2)
    800028b2:	c79d                	beqz	a5,800028e0 <wait+0x11a>
      release(&wait_lock);
    800028b4:	0000f517          	auipc	a0,0xf
    800028b8:	a2450513          	addi	a0,a0,-1500 # 800112d8 <wait_lock>
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	3dc080e7          	jalr	988(ra) # 80000c98 <release>
      return -1;
    800028c4:	59fd                	li	s3,-1
}
    800028c6:	854e                	mv	a0,s3
    800028c8:	60a6                	ld	ra,72(sp)
    800028ca:	6406                	ld	s0,64(sp)
    800028cc:	74e2                	ld	s1,56(sp)
    800028ce:	7942                	ld	s2,48(sp)
    800028d0:	79a2                	ld	s3,40(sp)
    800028d2:	7a02                	ld	s4,32(sp)
    800028d4:	6ae2                	ld	s5,24(sp)
    800028d6:	6b42                	ld	s6,16(sp)
    800028d8:	6ba2                	ld	s7,8(sp)
    800028da:	6c02                	ld	s8,0(sp)
    800028dc:	6161                	addi	sp,sp,80
    800028de:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028e0:	85e2                	mv	a1,s8
    800028e2:	854a                	mv	a0,s2
    800028e4:	00000097          	auipc	ra,0x0
    800028e8:	e74080e7          	jalr	-396(ra) # 80002758 <sleep>
    havekids = 0;
    800028ec:	b715                	j	80002810 <wait+0x4a>

00000000800028ee <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800028ee:	7179                	addi	sp,sp,-48
    800028f0:	f406                	sd	ra,40(sp)
    800028f2:	f022                	sd	s0,32(sp)
    800028f4:	ec26                	sd	s1,24(sp)
    800028f6:	e84a                	sd	s2,16(sp)
    800028f8:	e44e                	sd	s3,8(sp)
    800028fa:	e052                	sd	s4,0(sp)
    800028fc:	1800                	addi	s0,sp,48
    800028fe:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002900:	0000f497          	auipc	s1,0xf
    80002904:	df048493          	addi	s1,s1,-528 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002908:	4989                	li	s3,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000290a:	00015917          	auipc	s2,0x15
    8000290e:	fe690913          	addi	s2,s2,-26 # 800178f0 <tickslock>
    80002912:	a811                	j	80002926 <wakeup+0x38>
        changeStateToRunnable(p);
      }
      release(&p->lock);
    80002914:	8526                	mv	a0,s1
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	382080e7          	jalr	898(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000291e:	18848493          	addi	s1,s1,392
    80002922:	03248963          	beq	s1,s2,80002954 <wakeup+0x66>
    if(p != myproc()){
    80002926:	fffff097          	auipc	ra,0xfffff
    8000292a:	2e2080e7          	jalr	738(ra) # 80001c08 <myproc>
    8000292e:	fea488e3          	beq	s1,a0,8000291e <wakeup+0x30>
      acquire(&p->lock);
    80002932:	8526                	mv	a0,s1
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	2b0080e7          	jalr	688(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000293c:	4c9c                	lw	a5,24(s1)
    8000293e:	fd379be3          	bne	a5,s3,80002914 <wakeup+0x26>
    80002942:	709c                	ld	a5,32(s1)
    80002944:	fd4798e3          	bne	a5,s4,80002914 <wakeup+0x26>
        changeStateToRunnable(p);
    80002948:	8526                	mv	a0,s1
    8000294a:	fffff097          	auipc	ra,0xfffff
    8000294e:	07e080e7          	jalr	126(ra) # 800019c8 <changeStateToRunnable>
    80002952:	b7c9                	j	80002914 <wakeup+0x26>
    }
  }
}
    80002954:	70a2                	ld	ra,40(sp)
    80002956:	7402                	ld	s0,32(sp)
    80002958:	64e2                	ld	s1,24(sp)
    8000295a:	6942                	ld	s2,16(sp)
    8000295c:	69a2                	ld	s3,8(sp)
    8000295e:	6a02                	ld	s4,0(sp)
    80002960:	6145                	addi	sp,sp,48
    80002962:	8082                	ret

0000000080002964 <reparent>:
{
    80002964:	7179                	addi	sp,sp,-48
    80002966:	f406                	sd	ra,40(sp)
    80002968:	f022                	sd	s0,32(sp)
    8000296a:	ec26                	sd	s1,24(sp)
    8000296c:	e84a                	sd	s2,16(sp)
    8000296e:	e44e                	sd	s3,8(sp)
    80002970:	e052                	sd	s4,0(sp)
    80002972:	1800                	addi	s0,sp,48
    80002974:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002976:	0000f497          	auipc	s1,0xf
    8000297a:	d7a48493          	addi	s1,s1,-646 # 800116f0 <proc>
      pp->parent = initproc;
    8000297e:	00006a17          	auipc	s4,0x6
    80002982:	6d2a0a13          	addi	s4,s4,1746 # 80009050 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002986:	00015997          	auipc	s3,0x15
    8000298a:	f6a98993          	addi	s3,s3,-150 # 800178f0 <tickslock>
    8000298e:	a029                	j	80002998 <reparent+0x34>
    80002990:	18848493          	addi	s1,s1,392
    80002994:	01348d63          	beq	s1,s3,800029ae <reparent+0x4a>
    if(pp->parent == p){
    80002998:	7c9c                	ld	a5,56(s1)
    8000299a:	ff279be3          	bne	a5,s2,80002990 <reparent+0x2c>
      pp->parent = initproc;
    8000299e:	000a3503          	ld	a0,0(s4)
    800029a2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800029a4:	00000097          	auipc	ra,0x0
    800029a8:	f4a080e7          	jalr	-182(ra) # 800028ee <wakeup>
    800029ac:	b7d5                	j	80002990 <reparent+0x2c>
}
    800029ae:	70a2                	ld	ra,40(sp)
    800029b0:	7402                	ld	s0,32(sp)
    800029b2:	64e2                	ld	s1,24(sp)
    800029b4:	6942                	ld	s2,16(sp)
    800029b6:	69a2                	ld	s3,8(sp)
    800029b8:	6a02                	ld	s4,0(sp)
    800029ba:	6145                	addi	sp,sp,48
    800029bc:	8082                	ret

00000000800029be <exit>:
{
    800029be:	7179                	addi	sp,sp,-48
    800029c0:	f406                	sd	ra,40(sp)
    800029c2:	f022                	sd	s0,32(sp)
    800029c4:	ec26                	sd	s1,24(sp)
    800029c6:	e84a                	sd	s2,16(sp)
    800029c8:	e44e                	sd	s3,8(sp)
    800029ca:	e052                	sd	s4,0(sp)
    800029cc:	1800                	addi	s0,sp,48
    800029ce:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	238080e7          	jalr	568(ra) # 80001c08 <myproc>
    800029d8:	892a                	mv	s2,a0
  if(p == initproc)
    800029da:	00006797          	auipc	a5,0x6
    800029de:	6767b783          	ld	a5,1654(a5) # 80009050 <initproc>
    800029e2:	0f050493          	addi	s1,a0,240
    800029e6:	17050993          	addi	s3,a0,368
    800029ea:	02a79363          	bne	a5,a0,80002a10 <exit+0x52>
    panic("init exiting");
    800029ee:	00006517          	auipc	a0,0x6
    800029f2:	93250513          	addi	a0,a0,-1742 # 80008320 <digits+0x2e0>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	b48080e7          	jalr	-1208(ra) # 8000053e <panic>
      fileclose(f);
    800029fe:	00002097          	auipc	ra,0x2
    80002a02:	2f4080e7          	jalr	756(ra) # 80004cf2 <fileclose>
      p->ofile[fd] = 0;
    80002a06:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a0a:	04a1                	addi	s1,s1,8
    80002a0c:	01348563          	beq	s1,s3,80002a16 <exit+0x58>
    if(p->ofile[fd]){
    80002a10:	6088                	ld	a0,0(s1)
    80002a12:	f575                	bnez	a0,800029fe <exit+0x40>
    80002a14:	bfdd                	j	80002a0a <exit+0x4c>
  begin_op();
    80002a16:	00002097          	auipc	ra,0x2
    80002a1a:	e10080e7          	jalr	-496(ra) # 80004826 <begin_op>
  iput(p->cwd);
    80002a1e:	17093503          	ld	a0,368(s2)
    80002a22:	00001097          	auipc	ra,0x1
    80002a26:	5ec080e7          	jalr	1516(ra) # 8000400e <iput>
  end_op();
    80002a2a:	00002097          	auipc	ra,0x2
    80002a2e:	e7c080e7          	jalr	-388(ra) # 800048a6 <end_op>
  p->cwd = 0;
    80002a32:	16093823          	sd	zero,368(s2)
  acquire(&wait_lock);
    80002a36:	0000f497          	auipc	s1,0xf
    80002a3a:	8a248493          	addi	s1,s1,-1886 # 800112d8 <wait_lock>
    80002a3e:	8526                	mv	a0,s1
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	1a4080e7          	jalr	420(ra) # 80000be4 <acquire>
  reparent(p);
    80002a48:	854a                	mv	a0,s2
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	f1a080e7          	jalr	-230(ra) # 80002964 <reparent>
  wakeup(p->parent);
    80002a52:	03893503          	ld	a0,56(s2)
    80002a56:	00000097          	auipc	ra,0x0
    80002a5a:	e98080e7          	jalr	-360(ra) # 800028ee <wakeup>
  acquire(&p->lock);
    80002a5e:	854a                	mv	a0,s2
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	184080e7          	jalr	388(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002a68:	03492623          	sw	s4,44(s2)
  stateChange(p);
    80002a6c:	854a                	mv	a0,s2
    80002a6e:	fffff097          	auipc	ra,0xfffff
    80002a72:	ef4080e7          	jalr	-268(ra) # 80001962 <stateChange>
  p->state = ZOMBIE;
    80002a76:	4795                	li	a5,5
    80002a78:	00f92c23          	sw	a5,24(s2)
  sleeping_processes_mean = (sleeping_processes_mean * sleeping_processes_count + p->sleeping_time) / (sleeping_processes_count+1);
    80002a7c:	00006817          	auipc	a6,0x6
    80002a80:	5c080813          	addi	a6,a6,1472 # 8000903c <sleeping_processes_count>
    80002a84:	00082683          	lw	a3,0(a6)
    80002a88:	0016889b          	addiw	a7,a3,1
    80002a8c:	00006717          	auipc	a4,0x6
    80002a90:	5bc70713          	addi	a4,a4,1468 # 80009048 <sleeping_processes_mean>
    80002a94:	431c                	lw	a5,0(a4)
    80002a96:	02d787bb          	mulw	a5,a5,a3
    80002a9a:	05092683          	lw	a3,80(s2)
    80002a9e:	9fb5                	addw	a5,a5,a3
    80002aa0:	0317c7bb          	divw	a5,a5,a7
    80002aa4:	c31c                	sw	a5,0(a4)
  runnable_time_mean = (runnable_time_mean * runnable_time_count + p->runnable_time) / (runnable_time_count+1);
    80002aa6:	00006597          	auipc	a1,0x6
    80002aaa:	59258593          	addi	a1,a1,1426 # 80009038 <runnable_time_count>
    80002aae:	4194                	lw	a3,0(a1)
    80002ab0:	0016851b          	addiw	a0,a3,1
    80002ab4:	00006717          	auipc	a4,0x6
    80002ab8:	59070713          	addi	a4,a4,1424 # 80009044 <runnable_time_mean>
    80002abc:	431c                	lw	a5,0(a4)
    80002abe:	02d787bb          	mulw	a5,a5,a3
    80002ac2:	05492683          	lw	a3,84(s2)
    80002ac6:	9fb5                	addw	a5,a5,a3
    80002ac8:	02a7c7bb          	divw	a5,a5,a0
    80002acc:	c31c                	sw	a5,0(a4)
  running_time_mean = (running_time_mean * running_time_count + p->running_time) / (running_time_count+1);
    80002ace:	00006717          	auipc	a4,0x6
    80002ad2:	56670713          	addi	a4,a4,1382 # 80009034 <running_time_count>
    80002ad6:	00072e03          	lw	t3,0(a4)
    80002ada:	05892683          	lw	a3,88(s2)
    80002ade:	001e061b          	addiw	a2,t3,1
    80002ae2:	00006317          	auipc	t1,0x6
    80002ae6:	55e30313          	addi	t1,t1,1374 # 80009040 <running_time_mean>
    80002aea:	00032783          	lw	a5,0(t1)
    80002aee:	03c787bb          	mulw	a5,a5,t3
    80002af2:	9fb5                	addw	a5,a5,a3
    80002af4:	02c7c7bb          	divw	a5,a5,a2
    80002af8:	00f32023          	sw	a5,0(t1)
  sleeping_processes_count++;
    80002afc:	01182023          	sw	a7,0(a6)
  runnable_time_count++;
    80002b00:	c188                	sw	a0,0(a1)
  running_time_count++;
    80002b02:	c310                	sw	a2,0(a4)
  program_time += p->running_time;
    80002b04:	00006717          	auipc	a4,0x6
    80002b08:	52c70713          	addi	a4,a4,1324 # 80009030 <program_time>
    80002b0c:	431c                	lw	a5,0(a4)
    80002b0e:	9fb5                	addw	a5,a5,a3
    80002b10:	c31c                	sw	a5,0(a4)
  cpu_utilization = program_time / (ticks - start_time);
    80002b12:	00006717          	auipc	a4,0x6
    80002b16:	54672703          	lw	a4,1350(a4) # 80009058 <ticks>
    80002b1a:	00006697          	auipc	a3,0x6
    80002b1e:	50e6a683          	lw	a3,1294(a3) # 80009028 <start_time>
    80002b22:	9f15                	subw	a4,a4,a3
    80002b24:	02e7d7bb          	divuw	a5,a5,a4
    80002b28:	00006717          	auipc	a4,0x6
    80002b2c:	50f72223          	sw	a5,1284(a4) # 8000902c <cpu_utilization>
  release(&wait_lock);
    80002b30:	8526                	mv	a0,s1
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	166080e7          	jalr	358(ra) # 80000c98 <release>
  sched();
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	a76080e7          	jalr	-1418(ra) # 800025b0 <sched>
  panic("zombie exit");
    80002b42:	00005517          	auipc	a0,0x5
    80002b46:	7ee50513          	addi	a0,a0,2030 # 80008330 <digits+0x2f0>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	9f4080e7          	jalr	-1548(ra) # 8000053e <panic>

0000000080002b52 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002b52:	7179                	addi	sp,sp,-48
    80002b54:	f406                	sd	ra,40(sp)
    80002b56:	f022                	sd	s0,32(sp)
    80002b58:	ec26                	sd	s1,24(sp)
    80002b5a:	e84a                	sd	s2,16(sp)
    80002b5c:	e44e                	sd	s3,8(sp)
    80002b5e:	1800                	addi	s0,sp,48
    80002b60:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002b62:	0000f497          	auipc	s1,0xf
    80002b66:	b8e48493          	addi	s1,s1,-1138 # 800116f0 <proc>
    80002b6a:	00015997          	auipc	s3,0x15
    80002b6e:	d8698993          	addi	s3,s3,-634 # 800178f0 <tickslock>
    acquire(&p->lock);
    80002b72:	8526                	mv	a0,s1
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	070080e7          	jalr	112(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002b7c:	589c                	lw	a5,48(s1)
    80002b7e:	01278d63          	beq	a5,s2,80002b98 <kill+0x46>
        changeStateToRunnable(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002b82:	8526                	mv	a0,s1
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	114080e7          	jalr	276(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b8c:	18848493          	addi	s1,s1,392
    80002b90:	ff3491e3          	bne	s1,s3,80002b72 <kill+0x20>
  }
  return -1;
    80002b94:	557d                	li	a0,-1
    80002b96:	a829                	j	80002bb0 <kill+0x5e>
      p->killed = 1;
    80002b98:	4785                	li	a5,1
    80002b9a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002b9c:	4c98                	lw	a4,24(s1)
    80002b9e:	4789                	li	a5,2
    80002ba0:	00f70f63          	beq	a4,a5,80002bbe <kill+0x6c>
      release(&p->lock);
    80002ba4:	8526                	mv	a0,s1
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	0f2080e7          	jalr	242(ra) # 80000c98 <release>
      return 0;
    80002bae:	4501                	li	a0,0
}
    80002bb0:	70a2                	ld	ra,40(sp)
    80002bb2:	7402                	ld	s0,32(sp)
    80002bb4:	64e2                	ld	s1,24(sp)
    80002bb6:	6942                	ld	s2,16(sp)
    80002bb8:	69a2                	ld	s3,8(sp)
    80002bba:	6145                	addi	sp,sp,48
    80002bbc:	8082                	ret
        changeStateToRunnable(p);
    80002bbe:	8526                	mv	a0,s1
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	e08080e7          	jalr	-504(ra) # 800019c8 <changeStateToRunnable>
    80002bc8:	bff1                	j	80002ba4 <kill+0x52>

0000000080002bca <kill_system>:
{
    80002bca:	7179                	addi	sp,sp,-48
    80002bcc:	f406                	sd	ra,40(sp)
    80002bce:	f022                	sd	s0,32(sp)
    80002bd0:	ec26                	sd	s1,24(sp)
    80002bd2:	e84a                	sd	s2,16(sp)
    80002bd4:	e44e                	sd	s3,8(sp)
    80002bd6:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80002bd8:	0000f497          	auipc	s1,0xf
    80002bdc:	b1848493          	addi	s1,s1,-1256 # 800116f0 <proc>
    if (p->pid > 2) // init process and shell?
    80002be0:	4989                	li	s3,2
  for (p = proc; p < &proc[NPROC]; p++)
    80002be2:	00015917          	auipc	s2,0x15
    80002be6:	d0e90913          	addi	s2,s2,-754 # 800178f0 <tickslock>
    80002bea:	a811                	j	80002bfe <kill_system+0x34>
      release(&p->lock);
    80002bec:	8526                	mv	a0,s1
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	0aa080e7          	jalr	170(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002bf6:	18848493          	addi	s1,s1,392
    80002bfa:	03248563          	beq	s1,s2,80002c24 <kill_system+0x5a>
    acquire(&p->lock);
    80002bfe:	8526                	mv	a0,s1
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	fe4080e7          	jalr	-28(ra) # 80000be4 <acquire>
    if (p->pid > 2) // init process and shell?
    80002c08:	589c                	lw	a5,48(s1)
    80002c0a:	fef9d1e3          	bge	s3,a5,80002bec <kill_system+0x22>
      release(&p->lock);
    80002c0e:	8526                	mv	a0,s1
    80002c10:	ffffe097          	auipc	ra,0xffffe
    80002c14:	088080e7          	jalr	136(ra) # 80000c98 <release>
      kill(p->pid);
    80002c18:	5888                	lw	a0,48(s1)
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	f38080e7          	jalr	-200(ra) # 80002b52 <kill>
    80002c22:	bfd1                	j	80002bf6 <kill_system+0x2c>
}
    80002c24:	4501                	li	a0,0
    80002c26:	70a2                	ld	ra,40(sp)
    80002c28:	7402                	ld	s0,32(sp)
    80002c2a:	64e2                	ld	s1,24(sp)
    80002c2c:	6942                	ld	s2,16(sp)
    80002c2e:	69a2                	ld	s3,8(sp)
    80002c30:	6145                	addi	sp,sp,48
    80002c32:	8082                	ret

0000000080002c34 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002c34:	7179                	addi	sp,sp,-48
    80002c36:	f406                	sd	ra,40(sp)
    80002c38:	f022                	sd	s0,32(sp)
    80002c3a:	ec26                	sd	s1,24(sp)
    80002c3c:	e84a                	sd	s2,16(sp)
    80002c3e:	e44e                	sd	s3,8(sp)
    80002c40:	e052                	sd	s4,0(sp)
    80002c42:	1800                	addi	s0,sp,48
    80002c44:	84aa                	mv	s1,a0
    80002c46:	892e                	mv	s2,a1
    80002c48:	89b2                	mv	s3,a2
    80002c4a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	fbc080e7          	jalr	-68(ra) # 80001c08 <myproc>
  if(user_dst){
    80002c54:	c08d                	beqz	s1,80002c76 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002c56:	86d2                	mv	a3,s4
    80002c58:	864e                	mv	a2,s3
    80002c5a:	85ca                	mv	a1,s2
    80002c5c:	7928                	ld	a0,112(a0)
    80002c5e:	fffff097          	auipc	ra,0xfffff
    80002c62:	b38080e7          	jalr	-1224(ra) # 80001796 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002c66:	70a2                	ld	ra,40(sp)
    80002c68:	7402                	ld	s0,32(sp)
    80002c6a:	64e2                	ld	s1,24(sp)
    80002c6c:	6942                	ld	s2,16(sp)
    80002c6e:	69a2                	ld	s3,8(sp)
    80002c70:	6a02                	ld	s4,0(sp)
    80002c72:	6145                	addi	sp,sp,48
    80002c74:	8082                	ret
    memmove((char *)dst, src, len);
    80002c76:	000a061b          	sext.w	a2,s4
    80002c7a:	85ce                	mv	a1,s3
    80002c7c:	854a                	mv	a0,s2
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	0c2080e7          	jalr	194(ra) # 80000d40 <memmove>
    return 0;
    80002c86:	8526                	mv	a0,s1
    80002c88:	bff9                	j	80002c66 <either_copyout+0x32>

0000000080002c8a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002c8a:	7179                	addi	sp,sp,-48
    80002c8c:	f406                	sd	ra,40(sp)
    80002c8e:	f022                	sd	s0,32(sp)
    80002c90:	ec26                	sd	s1,24(sp)
    80002c92:	e84a                	sd	s2,16(sp)
    80002c94:	e44e                	sd	s3,8(sp)
    80002c96:	e052                	sd	s4,0(sp)
    80002c98:	1800                	addi	s0,sp,48
    80002c9a:	892a                	mv	s2,a0
    80002c9c:	84ae                	mv	s1,a1
    80002c9e:	89b2                	mv	s3,a2
    80002ca0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	f66080e7          	jalr	-154(ra) # 80001c08 <myproc>
  if(user_src){
    80002caa:	c08d                	beqz	s1,80002ccc <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002cac:	86d2                	mv	a3,s4
    80002cae:	864e                	mv	a2,s3
    80002cb0:	85ca                	mv	a1,s2
    80002cb2:	7928                	ld	a0,112(a0)
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	b6e080e7          	jalr	-1170(ra) # 80001822 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002cbc:	70a2                	ld	ra,40(sp)
    80002cbe:	7402                	ld	s0,32(sp)
    80002cc0:	64e2                	ld	s1,24(sp)
    80002cc2:	6942                	ld	s2,16(sp)
    80002cc4:	69a2                	ld	s3,8(sp)
    80002cc6:	6a02                	ld	s4,0(sp)
    80002cc8:	6145                	addi	sp,sp,48
    80002cca:	8082                	ret
    memmove(dst, (char*)src, len);
    80002ccc:	000a061b          	sext.w	a2,s4
    80002cd0:	85ce                	mv	a1,s3
    80002cd2:	854a                	mv	a0,s2
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	06c080e7          	jalr	108(ra) # 80000d40 <memmove>
    return 0;
    80002cdc:	8526                	mv	a0,s1
    80002cde:	bff9                	j	80002cbc <either_copyin+0x32>

0000000080002ce0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002ce0:	715d                	addi	sp,sp,-80
    80002ce2:	e486                	sd	ra,72(sp)
    80002ce4:	e0a2                	sd	s0,64(sp)
    80002ce6:	fc26                	sd	s1,56(sp)
    80002ce8:	f84a                	sd	s2,48(sp)
    80002cea:	f44e                	sd	s3,40(sp)
    80002cec:	f052                	sd	s4,32(sp)
    80002cee:	ec56                	sd	s5,24(sp)
    80002cf0:	e85a                	sd	s6,16(sp)
    80002cf2:	e45e                	sd	s7,8(sp)
    80002cf4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002cf6:	00005517          	auipc	a0,0x5
    80002cfa:	58250513          	addi	a0,a0,1410 # 80008278 <digits+0x238>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	88a080e7          	jalr	-1910(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d06:	0000f497          	auipc	s1,0xf
    80002d0a:	b6248493          	addi	s1,s1,-1182 # 80011868 <proc+0x178>
    80002d0e:	00015917          	auipc	s2,0x15
    80002d12:	d5a90913          	addi	s2,s2,-678 # 80017a68 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d16:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002d18:	00005997          	auipc	s3,0x5
    80002d1c:	62898993          	addi	s3,s3,1576 # 80008340 <digits+0x300>
    printf("%d %s %s", p->pid, state, p->name);
    80002d20:	00005a97          	auipc	s5,0x5
    80002d24:	628a8a93          	addi	s5,s5,1576 # 80008348 <digits+0x308>
    printf("\n");
    80002d28:	00005a17          	auipc	s4,0x5
    80002d2c:	550a0a13          	addi	s4,s4,1360 # 80008278 <digits+0x238>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d30:	00005b97          	auipc	s7,0x5
    80002d34:	650b8b93          	addi	s7,s7,1616 # 80008380 <states.1795>
    80002d38:	a00d                	j	80002d5a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002d3a:	eb86a583          	lw	a1,-328(a3)
    80002d3e:	8556                	mv	a0,s5
    80002d40:	ffffe097          	auipc	ra,0xffffe
    80002d44:	848080e7          	jalr	-1976(ra) # 80000588 <printf>
    printf("\n");
    80002d48:	8552                	mv	a0,s4
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	83e080e7          	jalr	-1986(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d52:	18848493          	addi	s1,s1,392
    80002d56:	03248163          	beq	s1,s2,80002d78 <procdump+0x98>
    if(p->state == UNUSED)
    80002d5a:	86a6                	mv	a3,s1
    80002d5c:	ea04a783          	lw	a5,-352(s1)
    80002d60:	dbed                	beqz	a5,80002d52 <procdump+0x72>
      state = "???";
    80002d62:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d64:	fcfb6be3          	bltu	s6,a5,80002d3a <procdump+0x5a>
    80002d68:	1782                	slli	a5,a5,0x20
    80002d6a:	9381                	srli	a5,a5,0x20
    80002d6c:	078e                	slli	a5,a5,0x3
    80002d6e:	97de                	add	a5,a5,s7
    80002d70:	6390                	ld	a2,0(a5)
    80002d72:	f661                	bnez	a2,80002d3a <procdump+0x5a>
      state = "???";
    80002d74:	864e                	mv	a2,s3
    80002d76:	b7d1                	j	80002d3a <procdump+0x5a>
  }
}
    80002d78:	60a6                	ld	ra,72(sp)
    80002d7a:	6406                	ld	s0,64(sp)
    80002d7c:	74e2                	ld	s1,56(sp)
    80002d7e:	7942                	ld	s2,48(sp)
    80002d80:	79a2                	ld	s3,40(sp)
    80002d82:	7a02                	ld	s4,32(sp)
    80002d84:	6ae2                	ld	s5,24(sp)
    80002d86:	6b42                	ld	s6,16(sp)
    80002d88:	6ba2                	ld	s7,8(sp)
    80002d8a:	6161                	addi	sp,sp,80
    80002d8c:	8082                	ret

0000000080002d8e <swtch>:
    80002d8e:	00153023          	sd	ra,0(a0)
    80002d92:	00253423          	sd	sp,8(a0)
    80002d96:	e900                	sd	s0,16(a0)
    80002d98:	ed04                	sd	s1,24(a0)
    80002d9a:	03253023          	sd	s2,32(a0)
    80002d9e:	03353423          	sd	s3,40(a0)
    80002da2:	03453823          	sd	s4,48(a0)
    80002da6:	03553c23          	sd	s5,56(a0)
    80002daa:	05653023          	sd	s6,64(a0)
    80002dae:	05753423          	sd	s7,72(a0)
    80002db2:	05853823          	sd	s8,80(a0)
    80002db6:	05953c23          	sd	s9,88(a0)
    80002dba:	07a53023          	sd	s10,96(a0)
    80002dbe:	07b53423          	sd	s11,104(a0)
    80002dc2:	0005b083          	ld	ra,0(a1)
    80002dc6:	0085b103          	ld	sp,8(a1)
    80002dca:	6980                	ld	s0,16(a1)
    80002dcc:	6d84                	ld	s1,24(a1)
    80002dce:	0205b903          	ld	s2,32(a1)
    80002dd2:	0285b983          	ld	s3,40(a1)
    80002dd6:	0305ba03          	ld	s4,48(a1)
    80002dda:	0385ba83          	ld	s5,56(a1)
    80002dde:	0405bb03          	ld	s6,64(a1)
    80002de2:	0485bb83          	ld	s7,72(a1)
    80002de6:	0505bc03          	ld	s8,80(a1)
    80002dea:	0585bc83          	ld	s9,88(a1)
    80002dee:	0605bd03          	ld	s10,96(a1)
    80002df2:	0685bd83          	ld	s11,104(a1)
    80002df6:	8082                	ret

0000000080002df8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002df8:	1141                	addi	sp,sp,-16
    80002dfa:	e406                	sd	ra,8(sp)
    80002dfc:	e022                	sd	s0,0(sp)
    80002dfe:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002e00:	00005597          	auipc	a1,0x5
    80002e04:	5b058593          	addi	a1,a1,1456 # 800083b0 <states.1795+0x30>
    80002e08:	00015517          	auipc	a0,0x15
    80002e0c:	ae850513          	addi	a0,a0,-1304 # 800178f0 <tickslock>
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	d44080e7          	jalr	-700(ra) # 80000b54 <initlock>
}
    80002e18:	60a2                	ld	ra,8(sp)
    80002e1a:	6402                	ld	s0,0(sp)
    80002e1c:	0141                	addi	sp,sp,16
    80002e1e:	8082                	ret

0000000080002e20 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002e20:	1141                	addi	sp,sp,-16
    80002e22:	e422                	sd	s0,8(sp)
    80002e24:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e26:	00003797          	auipc	a5,0x3
    80002e2a:	4ea78793          	addi	a5,a5,1258 # 80006310 <kernelvec>
    80002e2e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e32:	6422                	ld	s0,8(sp)
    80002e34:	0141                	addi	sp,sp,16
    80002e36:	8082                	ret

0000000080002e38 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002e38:	1141                	addi	sp,sp,-16
    80002e3a:	e406                	sd	ra,8(sp)
    80002e3c:	e022                	sd	s0,0(sp)
    80002e3e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e40:	fffff097          	auipc	ra,0xfffff
    80002e44:	dc8080e7          	jalr	-568(ra) # 80001c08 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e4c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e4e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002e52:	00004617          	auipc	a2,0x4
    80002e56:	1ae60613          	addi	a2,a2,430 # 80007000 <_trampoline>
    80002e5a:	00004697          	auipc	a3,0x4
    80002e5e:	1a668693          	addi	a3,a3,422 # 80007000 <_trampoline>
    80002e62:	8e91                	sub	a3,a3,a2
    80002e64:	040007b7          	lui	a5,0x4000
    80002e68:	17fd                	addi	a5,a5,-1
    80002e6a:	07b2                	slli	a5,a5,0xc
    80002e6c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e6e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e72:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e74:	180026f3          	csrr	a3,satp
    80002e78:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e7a:	7d38                	ld	a4,120(a0)
    80002e7c:	7134                	ld	a3,96(a0)
    80002e7e:	6585                	lui	a1,0x1
    80002e80:	96ae                	add	a3,a3,a1
    80002e82:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e84:	7d38                	ld	a4,120(a0)
    80002e86:	00000697          	auipc	a3,0x0
    80002e8a:	13868693          	addi	a3,a3,312 # 80002fbe <usertrap>
    80002e8e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e90:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e92:	8692                	mv	a3,tp
    80002e94:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e96:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e9a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e9e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ea2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ea6:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ea8:	6f18                	ld	a4,24(a4)
    80002eaa:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002eae:	792c                	ld	a1,112(a0)
    80002eb0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002eb2:	00004717          	auipc	a4,0x4
    80002eb6:	1de70713          	addi	a4,a4,478 # 80007090 <userret>
    80002eba:	8f11                	sub	a4,a4,a2
    80002ebc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ebe:	577d                	li	a4,-1
    80002ec0:	177e                	slli	a4,a4,0x3f
    80002ec2:	8dd9                	or	a1,a1,a4
    80002ec4:	02000537          	lui	a0,0x2000
    80002ec8:	157d                	addi	a0,a0,-1
    80002eca:	0536                	slli	a0,a0,0xd
    80002ecc:	9782                	jalr	a5
}
    80002ece:	60a2                	ld	ra,8(sp)
    80002ed0:	6402                	ld	s0,0(sp)
    80002ed2:	0141                	addi	sp,sp,16
    80002ed4:	8082                	ret

0000000080002ed6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ed6:	1101                	addi	sp,sp,-32
    80002ed8:	ec06                	sd	ra,24(sp)
    80002eda:	e822                	sd	s0,16(sp)
    80002edc:	e426                	sd	s1,8(sp)
    80002ede:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ee0:	00015497          	auipc	s1,0x15
    80002ee4:	a1048493          	addi	s1,s1,-1520 # 800178f0 <tickslock>
    80002ee8:	8526                	mv	a0,s1
    80002eea:	ffffe097          	auipc	ra,0xffffe
    80002eee:	cfa080e7          	jalr	-774(ra) # 80000be4 <acquire>
  ticks++;
    80002ef2:	00006517          	auipc	a0,0x6
    80002ef6:	16650513          	addi	a0,a0,358 # 80009058 <ticks>
    80002efa:	411c                	lw	a5,0(a0)
    80002efc:	2785                	addiw	a5,a5,1
    80002efe:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002f00:	00000097          	auipc	ra,0x0
    80002f04:	9ee080e7          	jalr	-1554(ra) # 800028ee <wakeup>
  release(&tickslock);
    80002f08:	8526                	mv	a0,s1
    80002f0a:	ffffe097          	auipc	ra,0xffffe
    80002f0e:	d8e080e7          	jalr	-626(ra) # 80000c98 <release>
}
    80002f12:	60e2                	ld	ra,24(sp)
    80002f14:	6442                	ld	s0,16(sp)
    80002f16:	64a2                	ld	s1,8(sp)
    80002f18:	6105                	addi	sp,sp,32
    80002f1a:	8082                	ret

0000000080002f1c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002f1c:	1101                	addi	sp,sp,-32
    80002f1e:	ec06                	sd	ra,24(sp)
    80002f20:	e822                	sd	s0,16(sp)
    80002f22:	e426                	sd	s1,8(sp)
    80002f24:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f26:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002f2a:	00074d63          	bltz	a4,80002f44 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002f2e:	57fd                	li	a5,-1
    80002f30:	17fe                	slli	a5,a5,0x3f
    80002f32:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002f34:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002f36:	06f70363          	beq	a4,a5,80002f9c <devintr+0x80>
  }
}
    80002f3a:	60e2                	ld	ra,24(sp)
    80002f3c:	6442                	ld	s0,16(sp)
    80002f3e:	64a2                	ld	s1,8(sp)
    80002f40:	6105                	addi	sp,sp,32
    80002f42:	8082                	ret
     (scause & 0xff) == 9){
    80002f44:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f48:	46a5                	li	a3,9
    80002f4a:	fed792e3          	bne	a5,a3,80002f2e <devintr+0x12>
    int irq = plic_claim();
    80002f4e:	00003097          	auipc	ra,0x3
    80002f52:	4ca080e7          	jalr	1226(ra) # 80006418 <plic_claim>
    80002f56:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f58:	47a9                	li	a5,10
    80002f5a:	02f50763          	beq	a0,a5,80002f88 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002f5e:	4785                	li	a5,1
    80002f60:	02f50963          	beq	a0,a5,80002f92 <devintr+0x76>
    return 1;
    80002f64:	4505                	li	a0,1
    } else if(irq){
    80002f66:	d8f1                	beqz	s1,80002f3a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f68:	85a6                	mv	a1,s1
    80002f6a:	00005517          	auipc	a0,0x5
    80002f6e:	44e50513          	addi	a0,a0,1102 # 800083b8 <states.1795+0x38>
    80002f72:	ffffd097          	auipc	ra,0xffffd
    80002f76:	616080e7          	jalr	1558(ra) # 80000588 <printf>
      plic_complete(irq);
    80002f7a:	8526                	mv	a0,s1
    80002f7c:	00003097          	auipc	ra,0x3
    80002f80:	4c0080e7          	jalr	1216(ra) # 8000643c <plic_complete>
    return 1;
    80002f84:	4505                	li	a0,1
    80002f86:	bf55                	j	80002f3a <devintr+0x1e>
      uartintr();
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	a20080e7          	jalr	-1504(ra) # 800009a8 <uartintr>
    80002f90:	b7ed                	j	80002f7a <devintr+0x5e>
      virtio_disk_intr();
    80002f92:	00004097          	auipc	ra,0x4
    80002f96:	98a080e7          	jalr	-1654(ra) # 8000691c <virtio_disk_intr>
    80002f9a:	b7c5                	j	80002f7a <devintr+0x5e>
    if(cpuid() == 0){
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	c40080e7          	jalr	-960(ra) # 80001bdc <cpuid>
    80002fa4:	c901                	beqz	a0,80002fb4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002fa6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002faa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002fac:	14479073          	csrw	sip,a5
    return 2;
    80002fb0:	4509                	li	a0,2
    80002fb2:	b761                	j	80002f3a <devintr+0x1e>
      clockintr();
    80002fb4:	00000097          	auipc	ra,0x0
    80002fb8:	f22080e7          	jalr	-222(ra) # 80002ed6 <clockintr>
    80002fbc:	b7ed                	j	80002fa6 <devintr+0x8a>

0000000080002fbe <usertrap>:
{
    80002fbe:	1101                	addi	sp,sp,-32
    80002fc0:	ec06                	sd	ra,24(sp)
    80002fc2:	e822                	sd	s0,16(sp)
    80002fc4:	e426                	sd	s1,8(sp)
    80002fc6:	e04a                	sd	s2,0(sp)
    80002fc8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fca:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002fce:	1007f793          	andi	a5,a5,256
    80002fd2:	e3ad                	bnez	a5,80003034 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fd4:	00003797          	auipc	a5,0x3
    80002fd8:	33c78793          	addi	a5,a5,828 # 80006310 <kernelvec>
    80002fdc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	c28080e7          	jalr	-984(ra) # 80001c08 <myproc>
    80002fe8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002fea:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fec:	14102773          	csrr	a4,sepc
    80002ff0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ff2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ff6:	47a1                	li	a5,8
    80002ff8:	04f71c63          	bne	a4,a5,80003050 <usertrap+0x92>
    if(p->killed)
    80002ffc:	551c                	lw	a5,40(a0)
    80002ffe:	e3b9                	bnez	a5,80003044 <usertrap+0x86>
    p->trapframe->epc += 4;
    80003000:	7cb8                	ld	a4,120(s1)
    80003002:	6f1c                	ld	a5,24(a4)
    80003004:	0791                	addi	a5,a5,4
    80003006:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003008:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000300c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003010:	10079073          	csrw	sstatus,a5
    syscall();
    80003014:	00000097          	auipc	ra,0x0
    80003018:	2e0080e7          	jalr	736(ra) # 800032f4 <syscall>
  if(p->killed)
    8000301c:	549c                	lw	a5,40(s1)
    8000301e:	ebc1                	bnez	a5,800030ae <usertrap+0xf0>
  usertrapret();
    80003020:	00000097          	auipc	ra,0x0
    80003024:	e18080e7          	jalr	-488(ra) # 80002e38 <usertrapret>
}
    80003028:	60e2                	ld	ra,24(sp)
    8000302a:	6442                	ld	s0,16(sp)
    8000302c:	64a2                	ld	s1,8(sp)
    8000302e:	6902                	ld	s2,0(sp)
    80003030:	6105                	addi	sp,sp,32
    80003032:	8082                	ret
    panic("usertrap: not from user mode");
    80003034:	00005517          	auipc	a0,0x5
    80003038:	3a450513          	addi	a0,a0,932 # 800083d8 <states.1795+0x58>
    8000303c:	ffffd097          	auipc	ra,0xffffd
    80003040:	502080e7          	jalr	1282(ra) # 8000053e <panic>
      exit(-1);
    80003044:	557d                	li	a0,-1
    80003046:	00000097          	auipc	ra,0x0
    8000304a:	978080e7          	jalr	-1672(ra) # 800029be <exit>
    8000304e:	bf4d                	j	80003000 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003050:	00000097          	auipc	ra,0x0
    80003054:	ecc080e7          	jalr	-308(ra) # 80002f1c <devintr>
    80003058:	892a                	mv	s2,a0
    8000305a:	c501                	beqz	a0,80003062 <usertrap+0xa4>
  if(p->killed)
    8000305c:	549c                	lw	a5,40(s1)
    8000305e:	c3a1                	beqz	a5,8000309e <usertrap+0xe0>
    80003060:	a815                	j	80003094 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003062:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003066:	5890                	lw	a2,48(s1)
    80003068:	00005517          	auipc	a0,0x5
    8000306c:	39050513          	addi	a0,a0,912 # 800083f8 <states.1795+0x78>
    80003070:	ffffd097          	auipc	ra,0xffffd
    80003074:	518080e7          	jalr	1304(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003078:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000307c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003080:	00005517          	auipc	a0,0x5
    80003084:	3a850513          	addi	a0,a0,936 # 80008428 <states.1795+0xa8>
    80003088:	ffffd097          	auipc	ra,0xffffd
    8000308c:	500080e7          	jalr	1280(ra) # 80000588 <printf>
    p->killed = 1;
    80003090:	4785                	li	a5,1
    80003092:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003094:	557d                	li	a0,-1
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	928080e7          	jalr	-1752(ra) # 800029be <exit>
  if(which_dev == 2)
    8000309e:	4789                	li	a5,2
    800030a0:	f8f910e3          	bne	s2,a5,80003020 <usertrap+0x62>
    yield();
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	5e2080e7          	jalr	1506(ra) # 80002686 <yield>
    800030ac:	bf95                	j	80003020 <usertrap+0x62>
  int which_dev = 0;
    800030ae:	4901                	li	s2,0
    800030b0:	b7d5                	j	80003094 <usertrap+0xd6>

00000000800030b2 <kerneltrap>:
{
    800030b2:	7179                	addi	sp,sp,-48
    800030b4:	f406                	sd	ra,40(sp)
    800030b6:	f022                	sd	s0,32(sp)
    800030b8:	ec26                	sd	s1,24(sp)
    800030ba:	e84a                	sd	s2,16(sp)
    800030bc:	e44e                	sd	s3,8(sp)
    800030be:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030c0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030c4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030c8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800030cc:	1004f793          	andi	a5,s1,256
    800030d0:	cb85                	beqz	a5,80003100 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030d2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030d6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800030d8:	ef85                	bnez	a5,80003110 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800030da:	00000097          	auipc	ra,0x0
    800030de:	e42080e7          	jalr	-446(ra) # 80002f1c <devintr>
    800030e2:	cd1d                	beqz	a0,80003120 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030e4:	4789                	li	a5,2
    800030e6:	06f50a63          	beq	a0,a5,8000315a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030ea:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030ee:	10049073          	csrw	sstatus,s1
}
    800030f2:	70a2                	ld	ra,40(sp)
    800030f4:	7402                	ld	s0,32(sp)
    800030f6:	64e2                	ld	s1,24(sp)
    800030f8:	6942                	ld	s2,16(sp)
    800030fa:	69a2                	ld	s3,8(sp)
    800030fc:	6145                	addi	sp,sp,48
    800030fe:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003100:	00005517          	auipc	a0,0x5
    80003104:	34850513          	addi	a0,a0,840 # 80008448 <states.1795+0xc8>
    80003108:	ffffd097          	auipc	ra,0xffffd
    8000310c:	436080e7          	jalr	1078(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80003110:	00005517          	auipc	a0,0x5
    80003114:	36050513          	addi	a0,a0,864 # 80008470 <states.1795+0xf0>
    80003118:	ffffd097          	auipc	ra,0xffffd
    8000311c:	426080e7          	jalr	1062(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80003120:	85ce                	mv	a1,s3
    80003122:	00005517          	auipc	a0,0x5
    80003126:	36e50513          	addi	a0,a0,878 # 80008490 <states.1795+0x110>
    8000312a:	ffffd097          	auipc	ra,0xffffd
    8000312e:	45e080e7          	jalr	1118(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003132:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003136:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000313a:	00005517          	auipc	a0,0x5
    8000313e:	36650513          	addi	a0,a0,870 # 800084a0 <states.1795+0x120>
    80003142:	ffffd097          	auipc	ra,0xffffd
    80003146:	446080e7          	jalr	1094(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000314a:	00005517          	auipc	a0,0x5
    8000314e:	36e50513          	addi	a0,a0,878 # 800084b8 <states.1795+0x138>
    80003152:	ffffd097          	auipc	ra,0xffffd
    80003156:	3ec080e7          	jalr	1004(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000315a:	fffff097          	auipc	ra,0xfffff
    8000315e:	aae080e7          	jalr	-1362(ra) # 80001c08 <myproc>
    80003162:	d541                	beqz	a0,800030ea <kerneltrap+0x38>
    80003164:	fffff097          	auipc	ra,0xfffff
    80003168:	aa4080e7          	jalr	-1372(ra) # 80001c08 <myproc>
    8000316c:	4d18                	lw	a4,24(a0)
    8000316e:	4791                	li	a5,4
    80003170:	f6f71de3          	bne	a4,a5,800030ea <kerneltrap+0x38>
    yield();
    80003174:	fffff097          	auipc	ra,0xfffff
    80003178:	512080e7          	jalr	1298(ra) # 80002686 <yield>
    8000317c:	b7bd                	j	800030ea <kerneltrap+0x38>

000000008000317e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000317e:	1101                	addi	sp,sp,-32
    80003180:	ec06                	sd	ra,24(sp)
    80003182:	e822                	sd	s0,16(sp)
    80003184:	e426                	sd	s1,8(sp)
    80003186:	1000                	addi	s0,sp,32
    80003188:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000318a:	fffff097          	auipc	ra,0xfffff
    8000318e:	a7e080e7          	jalr	-1410(ra) # 80001c08 <myproc>
  switch (n) {
    80003192:	4795                	li	a5,5
    80003194:	0497e163          	bltu	a5,s1,800031d6 <argraw+0x58>
    80003198:	048a                	slli	s1,s1,0x2
    8000319a:	00005717          	auipc	a4,0x5
    8000319e:	35670713          	addi	a4,a4,854 # 800084f0 <states.1795+0x170>
    800031a2:	94ba                	add	s1,s1,a4
    800031a4:	409c                	lw	a5,0(s1)
    800031a6:	97ba                	add	a5,a5,a4
    800031a8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800031aa:	7d3c                	ld	a5,120(a0)
    800031ac:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800031ae:	60e2                	ld	ra,24(sp)
    800031b0:	6442                	ld	s0,16(sp)
    800031b2:	64a2                	ld	s1,8(sp)
    800031b4:	6105                	addi	sp,sp,32
    800031b6:	8082                	ret
    return p->trapframe->a1;
    800031b8:	7d3c                	ld	a5,120(a0)
    800031ba:	7fa8                	ld	a0,120(a5)
    800031bc:	bfcd                	j	800031ae <argraw+0x30>
    return p->trapframe->a2;
    800031be:	7d3c                	ld	a5,120(a0)
    800031c0:	63c8                	ld	a0,128(a5)
    800031c2:	b7f5                	j	800031ae <argraw+0x30>
    return p->trapframe->a3;
    800031c4:	7d3c                	ld	a5,120(a0)
    800031c6:	67c8                	ld	a0,136(a5)
    800031c8:	b7dd                	j	800031ae <argraw+0x30>
    return p->trapframe->a4;
    800031ca:	7d3c                	ld	a5,120(a0)
    800031cc:	6bc8                	ld	a0,144(a5)
    800031ce:	b7c5                	j	800031ae <argraw+0x30>
    return p->trapframe->a5;
    800031d0:	7d3c                	ld	a5,120(a0)
    800031d2:	6fc8                	ld	a0,152(a5)
    800031d4:	bfe9                	j	800031ae <argraw+0x30>
  panic("argraw");
    800031d6:	00005517          	auipc	a0,0x5
    800031da:	2f250513          	addi	a0,a0,754 # 800084c8 <states.1795+0x148>
    800031de:	ffffd097          	auipc	ra,0xffffd
    800031e2:	360080e7          	jalr	864(ra) # 8000053e <panic>

00000000800031e6 <fetchaddr>:
{
    800031e6:	1101                	addi	sp,sp,-32
    800031e8:	ec06                	sd	ra,24(sp)
    800031ea:	e822                	sd	s0,16(sp)
    800031ec:	e426                	sd	s1,8(sp)
    800031ee:	e04a                	sd	s2,0(sp)
    800031f0:	1000                	addi	s0,sp,32
    800031f2:	84aa                	mv	s1,a0
    800031f4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031f6:	fffff097          	auipc	ra,0xfffff
    800031fa:	a12080e7          	jalr	-1518(ra) # 80001c08 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031fe:	753c                	ld	a5,104(a0)
    80003200:	02f4f863          	bgeu	s1,a5,80003230 <fetchaddr+0x4a>
    80003204:	00848713          	addi	a4,s1,8
    80003208:	02e7e663          	bltu	a5,a4,80003234 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000320c:	46a1                	li	a3,8
    8000320e:	8626                	mv	a2,s1
    80003210:	85ca                	mv	a1,s2
    80003212:	7928                	ld	a0,112(a0)
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	60e080e7          	jalr	1550(ra) # 80001822 <copyin>
    8000321c:	00a03533          	snez	a0,a0
    80003220:	40a00533          	neg	a0,a0
}
    80003224:	60e2                	ld	ra,24(sp)
    80003226:	6442                	ld	s0,16(sp)
    80003228:	64a2                	ld	s1,8(sp)
    8000322a:	6902                	ld	s2,0(sp)
    8000322c:	6105                	addi	sp,sp,32
    8000322e:	8082                	ret
    return -1;
    80003230:	557d                	li	a0,-1
    80003232:	bfcd                	j	80003224 <fetchaddr+0x3e>
    80003234:	557d                	li	a0,-1
    80003236:	b7fd                	j	80003224 <fetchaddr+0x3e>

0000000080003238 <fetchstr>:
{
    80003238:	7179                	addi	sp,sp,-48
    8000323a:	f406                	sd	ra,40(sp)
    8000323c:	f022                	sd	s0,32(sp)
    8000323e:	ec26                	sd	s1,24(sp)
    80003240:	e84a                	sd	s2,16(sp)
    80003242:	e44e                	sd	s3,8(sp)
    80003244:	1800                	addi	s0,sp,48
    80003246:	892a                	mv	s2,a0
    80003248:	84ae                	mv	s1,a1
    8000324a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000324c:	fffff097          	auipc	ra,0xfffff
    80003250:	9bc080e7          	jalr	-1604(ra) # 80001c08 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003254:	86ce                	mv	a3,s3
    80003256:	864a                	mv	a2,s2
    80003258:	85a6                	mv	a1,s1
    8000325a:	7928                	ld	a0,112(a0)
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	652080e7          	jalr	1618(ra) # 800018ae <copyinstr>
  if(err < 0)
    80003264:	00054763          	bltz	a0,80003272 <fetchstr+0x3a>
  return strlen(buf);
    80003268:	8526                	mv	a0,s1
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	bfa080e7          	jalr	-1030(ra) # 80000e64 <strlen>
}
    80003272:	70a2                	ld	ra,40(sp)
    80003274:	7402                	ld	s0,32(sp)
    80003276:	64e2                	ld	s1,24(sp)
    80003278:	6942                	ld	s2,16(sp)
    8000327a:	69a2                	ld	s3,8(sp)
    8000327c:	6145                	addi	sp,sp,48
    8000327e:	8082                	ret

0000000080003280 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003280:	1101                	addi	sp,sp,-32
    80003282:	ec06                	sd	ra,24(sp)
    80003284:	e822                	sd	s0,16(sp)
    80003286:	e426                	sd	s1,8(sp)
    80003288:	1000                	addi	s0,sp,32
    8000328a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000328c:	00000097          	auipc	ra,0x0
    80003290:	ef2080e7          	jalr	-270(ra) # 8000317e <argraw>
    80003294:	c088                	sw	a0,0(s1)
  return 0;
}
    80003296:	4501                	li	a0,0
    80003298:	60e2                	ld	ra,24(sp)
    8000329a:	6442                	ld	s0,16(sp)
    8000329c:	64a2                	ld	s1,8(sp)
    8000329e:	6105                	addi	sp,sp,32
    800032a0:	8082                	ret

00000000800032a2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800032a2:	1101                	addi	sp,sp,-32
    800032a4:	ec06                	sd	ra,24(sp)
    800032a6:	e822                	sd	s0,16(sp)
    800032a8:	e426                	sd	s1,8(sp)
    800032aa:	1000                	addi	s0,sp,32
    800032ac:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032ae:	00000097          	auipc	ra,0x0
    800032b2:	ed0080e7          	jalr	-304(ra) # 8000317e <argraw>
    800032b6:	e088                	sd	a0,0(s1)
  return 0;
}
    800032b8:	4501                	li	a0,0
    800032ba:	60e2                	ld	ra,24(sp)
    800032bc:	6442                	ld	s0,16(sp)
    800032be:	64a2                	ld	s1,8(sp)
    800032c0:	6105                	addi	sp,sp,32
    800032c2:	8082                	ret

00000000800032c4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800032c4:	1101                	addi	sp,sp,-32
    800032c6:	ec06                	sd	ra,24(sp)
    800032c8:	e822                	sd	s0,16(sp)
    800032ca:	e426                	sd	s1,8(sp)
    800032cc:	e04a                	sd	s2,0(sp)
    800032ce:	1000                	addi	s0,sp,32
    800032d0:	84ae                	mv	s1,a1
    800032d2:	8932                	mv	s2,a2
  *ip = argraw(n);
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	eaa080e7          	jalr	-342(ra) # 8000317e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032dc:	864a                	mv	a2,s2
    800032de:	85a6                	mv	a1,s1
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	f58080e7          	jalr	-168(ra) # 80003238 <fetchstr>
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6902                	ld	s2,0(sp)
    800032f0:	6105                	addi	sp,sp,32
    800032f2:	8082                	ret

00000000800032f4 <syscall>:
[SYS_print_stats]   sys_print_stats
};

void
syscall(void)
{
    800032f4:	1101                	addi	sp,sp,-32
    800032f6:	ec06                	sd	ra,24(sp)
    800032f8:	e822                	sd	s0,16(sp)
    800032fa:	e426                	sd	s1,8(sp)
    800032fc:	e04a                	sd	s2,0(sp)
    800032fe:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003300:	fffff097          	auipc	ra,0xfffff
    80003304:	908080e7          	jalr	-1784(ra) # 80001c08 <myproc>
    80003308:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000330a:	07853903          	ld	s2,120(a0)
    8000330e:	0a893783          	ld	a5,168(s2)
    80003312:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003316:	37fd                	addiw	a5,a5,-1
    80003318:	475d                	li	a4,23
    8000331a:	00f76f63          	bltu	a4,a5,80003338 <syscall+0x44>
    8000331e:	00369713          	slli	a4,a3,0x3
    80003322:	00005797          	auipc	a5,0x5
    80003326:	1e678793          	addi	a5,a5,486 # 80008508 <syscalls>
    8000332a:	97ba                	add	a5,a5,a4
    8000332c:	639c                	ld	a5,0(a5)
    8000332e:	c789                	beqz	a5,80003338 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003330:	9782                	jalr	a5
    80003332:	06a93823          	sd	a0,112(s2)
    80003336:	a839                	j	80003354 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003338:	17848613          	addi	a2,s1,376
    8000333c:	588c                	lw	a1,48(s1)
    8000333e:	00005517          	auipc	a0,0x5
    80003342:	19250513          	addi	a0,a0,402 # 800084d0 <states.1795+0x150>
    80003346:	ffffd097          	auipc	ra,0xffffd
    8000334a:	242080e7          	jalr	578(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000334e:	7cbc                	ld	a5,120(s1)
    80003350:	577d                	li	a4,-1
    80003352:	fbb8                	sd	a4,112(a5)
  }
}
    80003354:	60e2                	ld	ra,24(sp)
    80003356:	6442                	ld	s0,16(sp)
    80003358:	64a2                	ld	s1,8(sp)
    8000335a:	6902                	ld	s2,0(sp)
    8000335c:	6105                	addi	sp,sp,32
    8000335e:	8082                	ret

0000000080003360 <sys_pause_system>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_pause_system(void)
{
    80003360:	1101                	addi	sp,sp,-32
    80003362:	ec06                	sd	ra,24(sp)
    80003364:	e822                	sd	s0,16(sp)
    80003366:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003368:	fec40593          	addi	a1,s0,-20
    8000336c:	4501                	li	a0,0
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	f12080e7          	jalr	-238(ra) # 80003280 <argint>
    80003376:	87aa                	mv	a5,a0
    return -1;
    80003378:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000337a:	0007c863          	bltz	a5,8000338a <sys_pause_system+0x2a>
  
  return pause_system(n);
    8000337e:	fec42503          	lw	a0,-20(s0)
    80003382:	fffff097          	auipc	ra,0xfffff
    80003386:	346080e7          	jalr	838(ra) # 800026c8 <pause_system>
}
    8000338a:	60e2                	ld	ra,24(sp)
    8000338c:	6442                	ld	s0,16(sp)
    8000338e:	6105                	addi	sp,sp,32
    80003390:	8082                	ret

0000000080003392 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80003392:	1141                	addi	sp,sp,-16
    80003394:	e406                	sd	ra,8(sp)
    80003396:	e022                	sd	s0,0(sp)
    80003398:	0800                	addi	s0,sp,16
  return kill_system();
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	830080e7          	jalr	-2000(ra) # 80002bca <kill_system>
}
    800033a2:	60a2                	ld	ra,8(sp)
    800033a4:	6402                	ld	s0,0(sp)
    800033a6:	0141                	addi	sp,sp,16
    800033a8:	8082                	ret

00000000800033aa <sys_print_stats>:

uint64
sys_print_stats(void)
{
    800033aa:	1141                	addi	sp,sp,-16
    800033ac:	e406                	sd	ra,8(sp)
    800033ae:	e022                	sd	s0,0(sp)
    800033b0:	0800                	addi	s0,sp,16
  return print_stats();
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	642080e7          	jalr	1602(ra) # 800019f4 <print_stats>
}
    800033ba:	60a2                	ld	ra,8(sp)
    800033bc:	6402                	ld	s0,0(sp)
    800033be:	0141                	addi	sp,sp,16
    800033c0:	8082                	ret

00000000800033c2 <sys_exit>:

uint64
sys_exit(void)
{
    800033c2:	1101                	addi	sp,sp,-32
    800033c4:	ec06                	sd	ra,24(sp)
    800033c6:	e822                	sd	s0,16(sp)
    800033c8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800033ca:	fec40593          	addi	a1,s0,-20
    800033ce:	4501                	li	a0,0
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	eb0080e7          	jalr	-336(ra) # 80003280 <argint>
    return -1;
    800033d8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800033da:	00054963          	bltz	a0,800033ec <sys_exit+0x2a>
  exit(n);
    800033de:	fec42503          	lw	a0,-20(s0)
    800033e2:	fffff097          	auipc	ra,0xfffff
    800033e6:	5dc080e7          	jalr	1500(ra) # 800029be <exit>
  return 0;  // not reached
    800033ea:	4781                	li	a5,0
}
    800033ec:	853e                	mv	a0,a5
    800033ee:	60e2                	ld	ra,24(sp)
    800033f0:	6442                	ld	s0,16(sp)
    800033f2:	6105                	addi	sp,sp,32
    800033f4:	8082                	ret

00000000800033f6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800033f6:	1141                	addi	sp,sp,-16
    800033f8:	e406                	sd	ra,8(sp)
    800033fa:	e022                	sd	s0,0(sp)
    800033fc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033fe:	fffff097          	auipc	ra,0xfffff
    80003402:	80a080e7          	jalr	-2038(ra) # 80001c08 <myproc>
}
    80003406:	5908                	lw	a0,48(a0)
    80003408:	60a2                	ld	ra,8(sp)
    8000340a:	6402                	ld	s0,0(sp)
    8000340c:	0141                	addi	sp,sp,16
    8000340e:	8082                	ret

0000000080003410 <sys_fork>:

uint64
sys_fork(void)
{
    80003410:	1141                	addi	sp,sp,-16
    80003412:	e406                	sd	ra,8(sp)
    80003414:	e022                	sd	s0,0(sp)
    80003416:	0800                	addi	s0,sp,16
  return fork();
    80003418:	fffff097          	auipc	ra,0xfffff
    8000341c:	be4080e7          	jalr	-1052(ra) # 80001ffc <fork>
}
    80003420:	60a2                	ld	ra,8(sp)
    80003422:	6402                	ld	s0,0(sp)
    80003424:	0141                	addi	sp,sp,16
    80003426:	8082                	ret

0000000080003428 <sys_wait>:

uint64
sys_wait(void)
{
    80003428:	1101                	addi	sp,sp,-32
    8000342a:	ec06                	sd	ra,24(sp)
    8000342c:	e822                	sd	s0,16(sp)
    8000342e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003430:	fe840593          	addi	a1,s0,-24
    80003434:	4501                	li	a0,0
    80003436:	00000097          	auipc	ra,0x0
    8000343a:	e6c080e7          	jalr	-404(ra) # 800032a2 <argaddr>
    8000343e:	87aa                	mv	a5,a0
    return -1;
    80003440:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003442:	0007c863          	bltz	a5,80003452 <sys_wait+0x2a>
  return wait(p);
    80003446:	fe843503          	ld	a0,-24(s0)
    8000344a:	fffff097          	auipc	ra,0xfffff
    8000344e:	37c080e7          	jalr	892(ra) # 800027c6 <wait>
}
    80003452:	60e2                	ld	ra,24(sp)
    80003454:	6442                	ld	s0,16(sp)
    80003456:	6105                	addi	sp,sp,32
    80003458:	8082                	ret

000000008000345a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000345a:	7179                	addi	sp,sp,-48
    8000345c:	f406                	sd	ra,40(sp)
    8000345e:	f022                	sd	s0,32(sp)
    80003460:	ec26                	sd	s1,24(sp)
    80003462:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003464:	fdc40593          	addi	a1,s0,-36
    80003468:	4501                	li	a0,0
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	e16080e7          	jalr	-490(ra) # 80003280 <argint>
    80003472:	87aa                	mv	a5,a0
    return -1;
    80003474:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003476:	0207c063          	bltz	a5,80003496 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000347a:	ffffe097          	auipc	ra,0xffffe
    8000347e:	78e080e7          	jalr	1934(ra) # 80001c08 <myproc>
    80003482:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003484:	fdc42503          	lw	a0,-36(s0)
    80003488:	fffff097          	auipc	ra,0xfffff
    8000348c:	b00080e7          	jalr	-1280(ra) # 80001f88 <growproc>
    80003490:	00054863          	bltz	a0,800034a0 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003494:	8526                	mv	a0,s1
}
    80003496:	70a2                	ld	ra,40(sp)
    80003498:	7402                	ld	s0,32(sp)
    8000349a:	64e2                	ld	s1,24(sp)
    8000349c:	6145                	addi	sp,sp,48
    8000349e:	8082                	ret
    return -1;
    800034a0:	557d                	li	a0,-1
    800034a2:	bfd5                	j	80003496 <sys_sbrk+0x3c>

00000000800034a4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800034a4:	7139                	addi	sp,sp,-64
    800034a6:	fc06                	sd	ra,56(sp)
    800034a8:	f822                	sd	s0,48(sp)
    800034aa:	f426                	sd	s1,40(sp)
    800034ac:	f04a                	sd	s2,32(sp)
    800034ae:	ec4e                	sd	s3,24(sp)
    800034b0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800034b2:	fcc40593          	addi	a1,s0,-52
    800034b6:	4501                	li	a0,0
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	dc8080e7          	jalr	-568(ra) # 80003280 <argint>
    return -1;
    800034c0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800034c2:	06054563          	bltz	a0,8000352c <sys_sleep+0x88>
  acquire(&tickslock);
    800034c6:	00014517          	auipc	a0,0x14
    800034ca:	42a50513          	addi	a0,a0,1066 # 800178f0 <tickslock>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	716080e7          	jalr	1814(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800034d6:	00006917          	auipc	s2,0x6
    800034da:	b8292903          	lw	s2,-1150(s2) # 80009058 <ticks>
  while(ticks - ticks0 < n){
    800034de:	fcc42783          	lw	a5,-52(s0)
    800034e2:	cf85                	beqz	a5,8000351a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034e4:	00014997          	auipc	s3,0x14
    800034e8:	40c98993          	addi	s3,s3,1036 # 800178f0 <tickslock>
    800034ec:	00006497          	auipc	s1,0x6
    800034f0:	b6c48493          	addi	s1,s1,-1172 # 80009058 <ticks>
    if(myproc()->killed){
    800034f4:	ffffe097          	auipc	ra,0xffffe
    800034f8:	714080e7          	jalr	1812(ra) # 80001c08 <myproc>
    800034fc:	551c                	lw	a5,40(a0)
    800034fe:	ef9d                	bnez	a5,8000353c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003500:	85ce                	mv	a1,s3
    80003502:	8526                	mv	a0,s1
    80003504:	fffff097          	auipc	ra,0xfffff
    80003508:	254080e7          	jalr	596(ra) # 80002758 <sleep>
  while(ticks - ticks0 < n){
    8000350c:	409c                	lw	a5,0(s1)
    8000350e:	412787bb          	subw	a5,a5,s2
    80003512:	fcc42703          	lw	a4,-52(s0)
    80003516:	fce7efe3          	bltu	a5,a4,800034f4 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000351a:	00014517          	auipc	a0,0x14
    8000351e:	3d650513          	addi	a0,a0,982 # 800178f0 <tickslock>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	776080e7          	jalr	1910(ra) # 80000c98 <release>
  return 0;
    8000352a:	4781                	li	a5,0
}
    8000352c:	853e                	mv	a0,a5
    8000352e:	70e2                	ld	ra,56(sp)
    80003530:	7442                	ld	s0,48(sp)
    80003532:	74a2                	ld	s1,40(sp)
    80003534:	7902                	ld	s2,32(sp)
    80003536:	69e2                	ld	s3,24(sp)
    80003538:	6121                	addi	sp,sp,64
    8000353a:	8082                	ret
      release(&tickslock);
    8000353c:	00014517          	auipc	a0,0x14
    80003540:	3b450513          	addi	a0,a0,948 # 800178f0 <tickslock>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	754080e7          	jalr	1876(ra) # 80000c98 <release>
      return -1;
    8000354c:	57fd                	li	a5,-1
    8000354e:	bff9                	j	8000352c <sys_sleep+0x88>

0000000080003550 <sys_kill>:

uint64
sys_kill(void)
{
    80003550:	1101                	addi	sp,sp,-32
    80003552:	ec06                	sd	ra,24(sp)
    80003554:	e822                	sd	s0,16(sp)
    80003556:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003558:	fec40593          	addi	a1,s0,-20
    8000355c:	4501                	li	a0,0
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	d22080e7          	jalr	-734(ra) # 80003280 <argint>
    80003566:	87aa                	mv	a5,a0
    return -1;
    80003568:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000356a:	0007c863          	bltz	a5,8000357a <sys_kill+0x2a>
  return kill(pid);
    8000356e:	fec42503          	lw	a0,-20(s0)
    80003572:	fffff097          	auipc	ra,0xfffff
    80003576:	5e0080e7          	jalr	1504(ra) # 80002b52 <kill>
}
    8000357a:	60e2                	ld	ra,24(sp)
    8000357c:	6442                	ld	s0,16(sp)
    8000357e:	6105                	addi	sp,sp,32
    80003580:	8082                	ret

0000000080003582 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003582:	1101                	addi	sp,sp,-32
    80003584:	ec06                	sd	ra,24(sp)
    80003586:	e822                	sd	s0,16(sp)
    80003588:	e426                	sd	s1,8(sp)
    8000358a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000358c:	00014517          	auipc	a0,0x14
    80003590:	36450513          	addi	a0,a0,868 # 800178f0 <tickslock>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	650080e7          	jalr	1616(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000359c:	00006497          	auipc	s1,0x6
    800035a0:	abc4a483          	lw	s1,-1348(s1) # 80009058 <ticks>
  release(&tickslock);
    800035a4:	00014517          	auipc	a0,0x14
    800035a8:	34c50513          	addi	a0,a0,844 # 800178f0 <tickslock>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	6ec080e7          	jalr	1772(ra) # 80000c98 <release>
  return xticks;
}
    800035b4:	02049513          	slli	a0,s1,0x20
    800035b8:	9101                	srli	a0,a0,0x20
    800035ba:	60e2                	ld	ra,24(sp)
    800035bc:	6442                	ld	s0,16(sp)
    800035be:	64a2                	ld	s1,8(sp)
    800035c0:	6105                	addi	sp,sp,32
    800035c2:	8082                	ret

00000000800035c4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035c4:	7179                	addi	sp,sp,-48
    800035c6:	f406                	sd	ra,40(sp)
    800035c8:	f022                	sd	s0,32(sp)
    800035ca:	ec26                	sd	s1,24(sp)
    800035cc:	e84a                	sd	s2,16(sp)
    800035ce:	e44e                	sd	s3,8(sp)
    800035d0:	e052                	sd	s4,0(sp)
    800035d2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800035d4:	00005597          	auipc	a1,0x5
    800035d8:	ffc58593          	addi	a1,a1,-4 # 800085d0 <syscalls+0xc8>
    800035dc:	00014517          	auipc	a0,0x14
    800035e0:	32c50513          	addi	a0,a0,812 # 80017908 <bcache>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	570080e7          	jalr	1392(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035ec:	0001c797          	auipc	a5,0x1c
    800035f0:	31c78793          	addi	a5,a5,796 # 8001f908 <bcache+0x8000>
    800035f4:	0001c717          	auipc	a4,0x1c
    800035f8:	57c70713          	addi	a4,a4,1404 # 8001fb70 <bcache+0x8268>
    800035fc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003600:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003604:	00014497          	auipc	s1,0x14
    80003608:	31c48493          	addi	s1,s1,796 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    8000360c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000360e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003610:	00005a17          	auipc	s4,0x5
    80003614:	fc8a0a13          	addi	s4,s4,-56 # 800085d8 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003618:	2b893783          	ld	a5,696(s2)
    8000361c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000361e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003622:	85d2                	mv	a1,s4
    80003624:	01048513          	addi	a0,s1,16
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	4bc080e7          	jalr	1212(ra) # 80004ae4 <initsleeplock>
    bcache.head.next->prev = b;
    80003630:	2b893783          	ld	a5,696(s2)
    80003634:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003636:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000363a:	45848493          	addi	s1,s1,1112
    8000363e:	fd349de3          	bne	s1,s3,80003618 <binit+0x54>
  }
}
    80003642:	70a2                	ld	ra,40(sp)
    80003644:	7402                	ld	s0,32(sp)
    80003646:	64e2                	ld	s1,24(sp)
    80003648:	6942                	ld	s2,16(sp)
    8000364a:	69a2                	ld	s3,8(sp)
    8000364c:	6a02                	ld	s4,0(sp)
    8000364e:	6145                	addi	sp,sp,48
    80003650:	8082                	ret

0000000080003652 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003652:	7179                	addi	sp,sp,-48
    80003654:	f406                	sd	ra,40(sp)
    80003656:	f022                	sd	s0,32(sp)
    80003658:	ec26                	sd	s1,24(sp)
    8000365a:	e84a                	sd	s2,16(sp)
    8000365c:	e44e                	sd	s3,8(sp)
    8000365e:	1800                	addi	s0,sp,48
    80003660:	89aa                	mv	s3,a0
    80003662:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003664:	00014517          	auipc	a0,0x14
    80003668:	2a450513          	addi	a0,a0,676 # 80017908 <bcache>
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	578080e7          	jalr	1400(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003674:	0001c497          	auipc	s1,0x1c
    80003678:	54c4b483          	ld	s1,1356(s1) # 8001fbc0 <bcache+0x82b8>
    8000367c:	0001c797          	auipc	a5,0x1c
    80003680:	4f478793          	addi	a5,a5,1268 # 8001fb70 <bcache+0x8268>
    80003684:	02f48f63          	beq	s1,a5,800036c2 <bread+0x70>
    80003688:	873e                	mv	a4,a5
    8000368a:	a021                	j	80003692 <bread+0x40>
    8000368c:	68a4                	ld	s1,80(s1)
    8000368e:	02e48a63          	beq	s1,a4,800036c2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003692:	449c                	lw	a5,8(s1)
    80003694:	ff379ce3          	bne	a5,s3,8000368c <bread+0x3a>
    80003698:	44dc                	lw	a5,12(s1)
    8000369a:	ff2799e3          	bne	a5,s2,8000368c <bread+0x3a>
      b->refcnt++;
    8000369e:	40bc                	lw	a5,64(s1)
    800036a0:	2785                	addiw	a5,a5,1
    800036a2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036a4:	00014517          	auipc	a0,0x14
    800036a8:	26450513          	addi	a0,a0,612 # 80017908 <bcache>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	5ec080e7          	jalr	1516(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800036b4:	01048513          	addi	a0,s1,16
    800036b8:	00001097          	auipc	ra,0x1
    800036bc:	466080e7          	jalr	1126(ra) # 80004b1e <acquiresleep>
      return b;
    800036c0:	a8b9                	j	8000371e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036c2:	0001c497          	auipc	s1,0x1c
    800036c6:	4f64b483          	ld	s1,1270(s1) # 8001fbb8 <bcache+0x82b0>
    800036ca:	0001c797          	auipc	a5,0x1c
    800036ce:	4a678793          	addi	a5,a5,1190 # 8001fb70 <bcache+0x8268>
    800036d2:	00f48863          	beq	s1,a5,800036e2 <bread+0x90>
    800036d6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036d8:	40bc                	lw	a5,64(s1)
    800036da:	cf81                	beqz	a5,800036f2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036dc:	64a4                	ld	s1,72(s1)
    800036de:	fee49de3          	bne	s1,a4,800036d8 <bread+0x86>
  panic("bget: no buffers");
    800036e2:	00005517          	auipc	a0,0x5
    800036e6:	efe50513          	addi	a0,a0,-258 # 800085e0 <syscalls+0xd8>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	e54080e7          	jalr	-428(ra) # 8000053e <panic>
      b->dev = dev;
    800036f2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800036f6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800036fa:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036fe:	4785                	li	a5,1
    80003700:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003702:	00014517          	auipc	a0,0x14
    80003706:	20650513          	addi	a0,a0,518 # 80017908 <bcache>
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	58e080e7          	jalr	1422(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003712:	01048513          	addi	a0,s1,16
    80003716:	00001097          	auipc	ra,0x1
    8000371a:	408080e7          	jalr	1032(ra) # 80004b1e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000371e:	409c                	lw	a5,0(s1)
    80003720:	cb89                	beqz	a5,80003732 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003722:	8526                	mv	a0,s1
    80003724:	70a2                	ld	ra,40(sp)
    80003726:	7402                	ld	s0,32(sp)
    80003728:	64e2                	ld	s1,24(sp)
    8000372a:	6942                	ld	s2,16(sp)
    8000372c:	69a2                	ld	s3,8(sp)
    8000372e:	6145                	addi	sp,sp,48
    80003730:	8082                	ret
    virtio_disk_rw(b, 0);
    80003732:	4581                	li	a1,0
    80003734:	8526                	mv	a0,s1
    80003736:	00003097          	auipc	ra,0x3
    8000373a:	f10080e7          	jalr	-240(ra) # 80006646 <virtio_disk_rw>
    b->valid = 1;
    8000373e:	4785                	li	a5,1
    80003740:	c09c                	sw	a5,0(s1)
  return b;
    80003742:	b7c5                	j	80003722 <bread+0xd0>

0000000080003744 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003744:	1101                	addi	sp,sp,-32
    80003746:	ec06                	sd	ra,24(sp)
    80003748:	e822                	sd	s0,16(sp)
    8000374a:	e426                	sd	s1,8(sp)
    8000374c:	1000                	addi	s0,sp,32
    8000374e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003750:	0541                	addi	a0,a0,16
    80003752:	00001097          	auipc	ra,0x1
    80003756:	466080e7          	jalr	1126(ra) # 80004bb8 <holdingsleep>
    8000375a:	cd01                	beqz	a0,80003772 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000375c:	4585                	li	a1,1
    8000375e:	8526                	mv	a0,s1
    80003760:	00003097          	auipc	ra,0x3
    80003764:	ee6080e7          	jalr	-282(ra) # 80006646 <virtio_disk_rw>
}
    80003768:	60e2                	ld	ra,24(sp)
    8000376a:	6442                	ld	s0,16(sp)
    8000376c:	64a2                	ld	s1,8(sp)
    8000376e:	6105                	addi	sp,sp,32
    80003770:	8082                	ret
    panic("bwrite");
    80003772:	00005517          	auipc	a0,0x5
    80003776:	e8650513          	addi	a0,a0,-378 # 800085f8 <syscalls+0xf0>
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	dc4080e7          	jalr	-572(ra) # 8000053e <panic>

0000000080003782 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003782:	1101                	addi	sp,sp,-32
    80003784:	ec06                	sd	ra,24(sp)
    80003786:	e822                	sd	s0,16(sp)
    80003788:	e426                	sd	s1,8(sp)
    8000378a:	e04a                	sd	s2,0(sp)
    8000378c:	1000                	addi	s0,sp,32
    8000378e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003790:	01050913          	addi	s2,a0,16
    80003794:	854a                	mv	a0,s2
    80003796:	00001097          	auipc	ra,0x1
    8000379a:	422080e7          	jalr	1058(ra) # 80004bb8 <holdingsleep>
    8000379e:	c92d                	beqz	a0,80003810 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800037a0:	854a                	mv	a0,s2
    800037a2:	00001097          	auipc	ra,0x1
    800037a6:	3d2080e7          	jalr	978(ra) # 80004b74 <releasesleep>

  acquire(&bcache.lock);
    800037aa:	00014517          	auipc	a0,0x14
    800037ae:	15e50513          	addi	a0,a0,350 # 80017908 <bcache>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	432080e7          	jalr	1074(ra) # 80000be4 <acquire>
  b->refcnt--;
    800037ba:	40bc                	lw	a5,64(s1)
    800037bc:	37fd                	addiw	a5,a5,-1
    800037be:	0007871b          	sext.w	a4,a5
    800037c2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037c4:	eb05                	bnez	a4,800037f4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037c6:	68bc                	ld	a5,80(s1)
    800037c8:	64b8                	ld	a4,72(s1)
    800037ca:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800037cc:	64bc                	ld	a5,72(s1)
    800037ce:	68b8                	ld	a4,80(s1)
    800037d0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037d2:	0001c797          	auipc	a5,0x1c
    800037d6:	13678793          	addi	a5,a5,310 # 8001f908 <bcache+0x8000>
    800037da:	2b87b703          	ld	a4,696(a5)
    800037de:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037e0:	0001c717          	auipc	a4,0x1c
    800037e4:	39070713          	addi	a4,a4,912 # 8001fb70 <bcache+0x8268>
    800037e8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037ea:	2b87b703          	ld	a4,696(a5)
    800037ee:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037f0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037f4:	00014517          	auipc	a0,0x14
    800037f8:	11450513          	addi	a0,a0,276 # 80017908 <bcache>
    800037fc:	ffffd097          	auipc	ra,0xffffd
    80003800:	49c080e7          	jalr	1180(ra) # 80000c98 <release>
}
    80003804:	60e2                	ld	ra,24(sp)
    80003806:	6442                	ld	s0,16(sp)
    80003808:	64a2                	ld	s1,8(sp)
    8000380a:	6902                	ld	s2,0(sp)
    8000380c:	6105                	addi	sp,sp,32
    8000380e:	8082                	ret
    panic("brelse");
    80003810:	00005517          	auipc	a0,0x5
    80003814:	df050513          	addi	a0,a0,-528 # 80008600 <syscalls+0xf8>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	d26080e7          	jalr	-730(ra) # 8000053e <panic>

0000000080003820 <bpin>:

void
bpin(struct buf *b) {
    80003820:	1101                	addi	sp,sp,-32
    80003822:	ec06                	sd	ra,24(sp)
    80003824:	e822                	sd	s0,16(sp)
    80003826:	e426                	sd	s1,8(sp)
    80003828:	1000                	addi	s0,sp,32
    8000382a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000382c:	00014517          	auipc	a0,0x14
    80003830:	0dc50513          	addi	a0,a0,220 # 80017908 <bcache>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	3b0080e7          	jalr	944(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000383c:	40bc                	lw	a5,64(s1)
    8000383e:	2785                	addiw	a5,a5,1
    80003840:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003842:	00014517          	auipc	a0,0x14
    80003846:	0c650513          	addi	a0,a0,198 # 80017908 <bcache>
    8000384a:	ffffd097          	auipc	ra,0xffffd
    8000384e:	44e080e7          	jalr	1102(ra) # 80000c98 <release>
}
    80003852:	60e2                	ld	ra,24(sp)
    80003854:	6442                	ld	s0,16(sp)
    80003856:	64a2                	ld	s1,8(sp)
    80003858:	6105                	addi	sp,sp,32
    8000385a:	8082                	ret

000000008000385c <bunpin>:

void
bunpin(struct buf *b) {
    8000385c:	1101                	addi	sp,sp,-32
    8000385e:	ec06                	sd	ra,24(sp)
    80003860:	e822                	sd	s0,16(sp)
    80003862:	e426                	sd	s1,8(sp)
    80003864:	1000                	addi	s0,sp,32
    80003866:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003868:	00014517          	auipc	a0,0x14
    8000386c:	0a050513          	addi	a0,a0,160 # 80017908 <bcache>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	374080e7          	jalr	884(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003878:	40bc                	lw	a5,64(s1)
    8000387a:	37fd                	addiw	a5,a5,-1
    8000387c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000387e:	00014517          	auipc	a0,0x14
    80003882:	08a50513          	addi	a0,a0,138 # 80017908 <bcache>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	412080e7          	jalr	1042(ra) # 80000c98 <release>
}
    8000388e:	60e2                	ld	ra,24(sp)
    80003890:	6442                	ld	s0,16(sp)
    80003892:	64a2                	ld	s1,8(sp)
    80003894:	6105                	addi	sp,sp,32
    80003896:	8082                	ret

0000000080003898 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003898:	1101                	addi	sp,sp,-32
    8000389a:	ec06                	sd	ra,24(sp)
    8000389c:	e822                	sd	s0,16(sp)
    8000389e:	e426                	sd	s1,8(sp)
    800038a0:	e04a                	sd	s2,0(sp)
    800038a2:	1000                	addi	s0,sp,32
    800038a4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800038a6:	00d5d59b          	srliw	a1,a1,0xd
    800038aa:	0001c797          	auipc	a5,0x1c
    800038ae:	73a7a783          	lw	a5,1850(a5) # 8001ffe4 <sb+0x1c>
    800038b2:	9dbd                	addw	a1,a1,a5
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	d9e080e7          	jalr	-610(ra) # 80003652 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800038bc:	0074f713          	andi	a4,s1,7
    800038c0:	4785                	li	a5,1
    800038c2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800038c6:	14ce                	slli	s1,s1,0x33
    800038c8:	90d9                	srli	s1,s1,0x36
    800038ca:	00950733          	add	a4,a0,s1
    800038ce:	05874703          	lbu	a4,88(a4)
    800038d2:	00e7f6b3          	and	a3,a5,a4
    800038d6:	c69d                	beqz	a3,80003904 <bfree+0x6c>
    800038d8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038da:	94aa                	add	s1,s1,a0
    800038dc:	fff7c793          	not	a5,a5
    800038e0:	8ff9                	and	a5,a5,a4
    800038e2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800038e6:	00001097          	auipc	ra,0x1
    800038ea:	118080e7          	jalr	280(ra) # 800049fe <log_write>
  brelse(bp);
    800038ee:	854a                	mv	a0,s2
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	e92080e7          	jalr	-366(ra) # 80003782 <brelse>
}
    800038f8:	60e2                	ld	ra,24(sp)
    800038fa:	6442                	ld	s0,16(sp)
    800038fc:	64a2                	ld	s1,8(sp)
    800038fe:	6902                	ld	s2,0(sp)
    80003900:	6105                	addi	sp,sp,32
    80003902:	8082                	ret
    panic("freeing free block");
    80003904:	00005517          	auipc	a0,0x5
    80003908:	d0450513          	addi	a0,a0,-764 # 80008608 <syscalls+0x100>
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	c32080e7          	jalr	-974(ra) # 8000053e <panic>

0000000080003914 <balloc>:
{
    80003914:	711d                	addi	sp,sp,-96
    80003916:	ec86                	sd	ra,88(sp)
    80003918:	e8a2                	sd	s0,80(sp)
    8000391a:	e4a6                	sd	s1,72(sp)
    8000391c:	e0ca                	sd	s2,64(sp)
    8000391e:	fc4e                	sd	s3,56(sp)
    80003920:	f852                	sd	s4,48(sp)
    80003922:	f456                	sd	s5,40(sp)
    80003924:	f05a                	sd	s6,32(sp)
    80003926:	ec5e                	sd	s7,24(sp)
    80003928:	e862                	sd	s8,16(sp)
    8000392a:	e466                	sd	s9,8(sp)
    8000392c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000392e:	0001c797          	auipc	a5,0x1c
    80003932:	69e7a783          	lw	a5,1694(a5) # 8001ffcc <sb+0x4>
    80003936:	cbd1                	beqz	a5,800039ca <balloc+0xb6>
    80003938:	8baa                	mv	s7,a0
    8000393a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000393c:	0001cb17          	auipc	s6,0x1c
    80003940:	68cb0b13          	addi	s6,s6,1676 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003944:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003946:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003948:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000394a:	6c89                	lui	s9,0x2
    8000394c:	a831                	j	80003968 <balloc+0x54>
    brelse(bp);
    8000394e:	854a                	mv	a0,s2
    80003950:	00000097          	auipc	ra,0x0
    80003954:	e32080e7          	jalr	-462(ra) # 80003782 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003958:	015c87bb          	addw	a5,s9,s5
    8000395c:	00078a9b          	sext.w	s5,a5
    80003960:	004b2703          	lw	a4,4(s6)
    80003964:	06eaf363          	bgeu	s5,a4,800039ca <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003968:	41fad79b          	sraiw	a5,s5,0x1f
    8000396c:	0137d79b          	srliw	a5,a5,0x13
    80003970:	015787bb          	addw	a5,a5,s5
    80003974:	40d7d79b          	sraiw	a5,a5,0xd
    80003978:	01cb2583          	lw	a1,28(s6)
    8000397c:	9dbd                	addw	a1,a1,a5
    8000397e:	855e                	mv	a0,s7
    80003980:	00000097          	auipc	ra,0x0
    80003984:	cd2080e7          	jalr	-814(ra) # 80003652 <bread>
    80003988:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000398a:	004b2503          	lw	a0,4(s6)
    8000398e:	000a849b          	sext.w	s1,s5
    80003992:	8662                	mv	a2,s8
    80003994:	faa4fde3          	bgeu	s1,a0,8000394e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003998:	41f6579b          	sraiw	a5,a2,0x1f
    8000399c:	01d7d69b          	srliw	a3,a5,0x1d
    800039a0:	00c6873b          	addw	a4,a3,a2
    800039a4:	00777793          	andi	a5,a4,7
    800039a8:	9f95                	subw	a5,a5,a3
    800039aa:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800039ae:	4037571b          	sraiw	a4,a4,0x3
    800039b2:	00e906b3          	add	a3,s2,a4
    800039b6:	0586c683          	lbu	a3,88(a3)
    800039ba:	00d7f5b3          	and	a1,a5,a3
    800039be:	cd91                	beqz	a1,800039da <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039c0:	2605                	addiw	a2,a2,1
    800039c2:	2485                	addiw	s1,s1,1
    800039c4:	fd4618e3          	bne	a2,s4,80003994 <balloc+0x80>
    800039c8:	b759                	j	8000394e <balloc+0x3a>
  panic("balloc: out of blocks");
    800039ca:	00005517          	auipc	a0,0x5
    800039ce:	c5650513          	addi	a0,a0,-938 # 80008620 <syscalls+0x118>
    800039d2:	ffffd097          	auipc	ra,0xffffd
    800039d6:	b6c080e7          	jalr	-1172(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039da:	974a                	add	a4,a4,s2
    800039dc:	8fd5                	or	a5,a5,a3
    800039de:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800039e2:	854a                	mv	a0,s2
    800039e4:	00001097          	auipc	ra,0x1
    800039e8:	01a080e7          	jalr	26(ra) # 800049fe <log_write>
        brelse(bp);
    800039ec:	854a                	mv	a0,s2
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	d94080e7          	jalr	-620(ra) # 80003782 <brelse>
  bp = bread(dev, bno);
    800039f6:	85a6                	mv	a1,s1
    800039f8:	855e                	mv	a0,s7
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	c58080e7          	jalr	-936(ra) # 80003652 <bread>
    80003a02:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a04:	40000613          	li	a2,1024
    80003a08:	4581                	li	a1,0
    80003a0a:	05850513          	addi	a0,a0,88
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	2d2080e7          	jalr	722(ra) # 80000ce0 <memset>
  log_write(bp);
    80003a16:	854a                	mv	a0,s2
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	fe6080e7          	jalr	-26(ra) # 800049fe <log_write>
  brelse(bp);
    80003a20:	854a                	mv	a0,s2
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	d60080e7          	jalr	-672(ra) # 80003782 <brelse>
}
    80003a2a:	8526                	mv	a0,s1
    80003a2c:	60e6                	ld	ra,88(sp)
    80003a2e:	6446                	ld	s0,80(sp)
    80003a30:	64a6                	ld	s1,72(sp)
    80003a32:	6906                	ld	s2,64(sp)
    80003a34:	79e2                	ld	s3,56(sp)
    80003a36:	7a42                	ld	s4,48(sp)
    80003a38:	7aa2                	ld	s5,40(sp)
    80003a3a:	7b02                	ld	s6,32(sp)
    80003a3c:	6be2                	ld	s7,24(sp)
    80003a3e:	6c42                	ld	s8,16(sp)
    80003a40:	6ca2                	ld	s9,8(sp)
    80003a42:	6125                	addi	sp,sp,96
    80003a44:	8082                	ret

0000000080003a46 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a46:	7179                	addi	sp,sp,-48
    80003a48:	f406                	sd	ra,40(sp)
    80003a4a:	f022                	sd	s0,32(sp)
    80003a4c:	ec26                	sd	s1,24(sp)
    80003a4e:	e84a                	sd	s2,16(sp)
    80003a50:	e44e                	sd	s3,8(sp)
    80003a52:	e052                	sd	s4,0(sp)
    80003a54:	1800                	addi	s0,sp,48
    80003a56:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a58:	47ad                	li	a5,11
    80003a5a:	04b7fe63          	bgeu	a5,a1,80003ab6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a5e:	ff45849b          	addiw	s1,a1,-12
    80003a62:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a66:	0ff00793          	li	a5,255
    80003a6a:	0ae7e363          	bltu	a5,a4,80003b10 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a6e:	08052583          	lw	a1,128(a0)
    80003a72:	c5ad                	beqz	a1,80003adc <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a74:	00092503          	lw	a0,0(s2)
    80003a78:	00000097          	auipc	ra,0x0
    80003a7c:	bda080e7          	jalr	-1062(ra) # 80003652 <bread>
    80003a80:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a82:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a86:	02049593          	slli	a1,s1,0x20
    80003a8a:	9181                	srli	a1,a1,0x20
    80003a8c:	058a                	slli	a1,a1,0x2
    80003a8e:	00b784b3          	add	s1,a5,a1
    80003a92:	0004a983          	lw	s3,0(s1)
    80003a96:	04098d63          	beqz	s3,80003af0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a9a:	8552                	mv	a0,s4
    80003a9c:	00000097          	auipc	ra,0x0
    80003aa0:	ce6080e7          	jalr	-794(ra) # 80003782 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003aa4:	854e                	mv	a0,s3
    80003aa6:	70a2                	ld	ra,40(sp)
    80003aa8:	7402                	ld	s0,32(sp)
    80003aaa:	64e2                	ld	s1,24(sp)
    80003aac:	6942                	ld	s2,16(sp)
    80003aae:	69a2                	ld	s3,8(sp)
    80003ab0:	6a02                	ld	s4,0(sp)
    80003ab2:	6145                	addi	sp,sp,48
    80003ab4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003ab6:	02059493          	slli	s1,a1,0x20
    80003aba:	9081                	srli	s1,s1,0x20
    80003abc:	048a                	slli	s1,s1,0x2
    80003abe:	94aa                	add	s1,s1,a0
    80003ac0:	0504a983          	lw	s3,80(s1)
    80003ac4:	fe0990e3          	bnez	s3,80003aa4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003ac8:	4108                	lw	a0,0(a0)
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	e4a080e7          	jalr	-438(ra) # 80003914 <balloc>
    80003ad2:	0005099b          	sext.w	s3,a0
    80003ad6:	0534a823          	sw	s3,80(s1)
    80003ada:	b7e9                	j	80003aa4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003adc:	4108                	lw	a0,0(a0)
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	e36080e7          	jalr	-458(ra) # 80003914 <balloc>
    80003ae6:	0005059b          	sext.w	a1,a0
    80003aea:	08b92023          	sw	a1,128(s2)
    80003aee:	b759                	j	80003a74 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003af0:	00092503          	lw	a0,0(s2)
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	e20080e7          	jalr	-480(ra) # 80003914 <balloc>
    80003afc:	0005099b          	sext.w	s3,a0
    80003b00:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b04:	8552                	mv	a0,s4
    80003b06:	00001097          	auipc	ra,0x1
    80003b0a:	ef8080e7          	jalr	-264(ra) # 800049fe <log_write>
    80003b0e:	b771                	j	80003a9a <bmap+0x54>
  panic("bmap: out of range");
    80003b10:	00005517          	auipc	a0,0x5
    80003b14:	b2850513          	addi	a0,a0,-1240 # 80008638 <syscalls+0x130>
    80003b18:	ffffd097          	auipc	ra,0xffffd
    80003b1c:	a26080e7          	jalr	-1498(ra) # 8000053e <panic>

0000000080003b20 <iget>:
{
    80003b20:	7179                	addi	sp,sp,-48
    80003b22:	f406                	sd	ra,40(sp)
    80003b24:	f022                	sd	s0,32(sp)
    80003b26:	ec26                	sd	s1,24(sp)
    80003b28:	e84a                	sd	s2,16(sp)
    80003b2a:	e44e                	sd	s3,8(sp)
    80003b2c:	e052                	sd	s4,0(sp)
    80003b2e:	1800                	addi	s0,sp,48
    80003b30:	89aa                	mv	s3,a0
    80003b32:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b34:	0001c517          	auipc	a0,0x1c
    80003b38:	4b450513          	addi	a0,a0,1204 # 8001ffe8 <itable>
    80003b3c:	ffffd097          	auipc	ra,0xffffd
    80003b40:	0a8080e7          	jalr	168(ra) # 80000be4 <acquire>
  empty = 0;
    80003b44:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b46:	0001c497          	auipc	s1,0x1c
    80003b4a:	4ba48493          	addi	s1,s1,1210 # 80020000 <itable+0x18>
    80003b4e:	0001e697          	auipc	a3,0x1e
    80003b52:	f4268693          	addi	a3,a3,-190 # 80021a90 <log>
    80003b56:	a039                	j	80003b64 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b58:	02090b63          	beqz	s2,80003b8e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b5c:	08848493          	addi	s1,s1,136
    80003b60:	02d48a63          	beq	s1,a3,80003b94 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b64:	449c                	lw	a5,8(s1)
    80003b66:	fef059e3          	blez	a5,80003b58 <iget+0x38>
    80003b6a:	4098                	lw	a4,0(s1)
    80003b6c:	ff3716e3          	bne	a4,s3,80003b58 <iget+0x38>
    80003b70:	40d8                	lw	a4,4(s1)
    80003b72:	ff4713e3          	bne	a4,s4,80003b58 <iget+0x38>
      ip->ref++;
    80003b76:	2785                	addiw	a5,a5,1
    80003b78:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b7a:	0001c517          	auipc	a0,0x1c
    80003b7e:	46e50513          	addi	a0,a0,1134 # 8001ffe8 <itable>
    80003b82:	ffffd097          	auipc	ra,0xffffd
    80003b86:	116080e7          	jalr	278(ra) # 80000c98 <release>
      return ip;
    80003b8a:	8926                	mv	s2,s1
    80003b8c:	a03d                	j	80003bba <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b8e:	f7f9                	bnez	a5,80003b5c <iget+0x3c>
    80003b90:	8926                	mv	s2,s1
    80003b92:	b7e9                	j	80003b5c <iget+0x3c>
  if(empty == 0)
    80003b94:	02090c63          	beqz	s2,80003bcc <iget+0xac>
  ip->dev = dev;
    80003b98:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b9c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003ba0:	4785                	li	a5,1
    80003ba2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003ba6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003baa:	0001c517          	auipc	a0,0x1c
    80003bae:	43e50513          	addi	a0,a0,1086 # 8001ffe8 <itable>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	0e6080e7          	jalr	230(ra) # 80000c98 <release>
}
    80003bba:	854a                	mv	a0,s2
    80003bbc:	70a2                	ld	ra,40(sp)
    80003bbe:	7402                	ld	s0,32(sp)
    80003bc0:	64e2                	ld	s1,24(sp)
    80003bc2:	6942                	ld	s2,16(sp)
    80003bc4:	69a2                	ld	s3,8(sp)
    80003bc6:	6a02                	ld	s4,0(sp)
    80003bc8:	6145                	addi	sp,sp,48
    80003bca:	8082                	ret
    panic("iget: no inodes");
    80003bcc:	00005517          	auipc	a0,0x5
    80003bd0:	a8450513          	addi	a0,a0,-1404 # 80008650 <syscalls+0x148>
    80003bd4:	ffffd097          	auipc	ra,0xffffd
    80003bd8:	96a080e7          	jalr	-1686(ra) # 8000053e <panic>

0000000080003bdc <fsinit>:
fsinit(int dev) {
    80003bdc:	7179                	addi	sp,sp,-48
    80003bde:	f406                	sd	ra,40(sp)
    80003be0:	f022                	sd	s0,32(sp)
    80003be2:	ec26                	sd	s1,24(sp)
    80003be4:	e84a                	sd	s2,16(sp)
    80003be6:	e44e                	sd	s3,8(sp)
    80003be8:	1800                	addi	s0,sp,48
    80003bea:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bec:	4585                	li	a1,1
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	a64080e7          	jalr	-1436(ra) # 80003652 <bread>
    80003bf6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bf8:	0001c997          	auipc	s3,0x1c
    80003bfc:	3d098993          	addi	s3,s3,976 # 8001ffc8 <sb>
    80003c00:	02000613          	li	a2,32
    80003c04:	05850593          	addi	a1,a0,88
    80003c08:	854e                	mv	a0,s3
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	136080e7          	jalr	310(ra) # 80000d40 <memmove>
  brelse(bp);
    80003c12:	8526                	mv	a0,s1
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	b6e080e7          	jalr	-1170(ra) # 80003782 <brelse>
  if(sb.magic != FSMAGIC)
    80003c1c:	0009a703          	lw	a4,0(s3)
    80003c20:	102037b7          	lui	a5,0x10203
    80003c24:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c28:	02f71263          	bne	a4,a5,80003c4c <fsinit+0x70>
  initlog(dev, &sb);
    80003c2c:	0001c597          	auipc	a1,0x1c
    80003c30:	39c58593          	addi	a1,a1,924 # 8001ffc8 <sb>
    80003c34:	854a                	mv	a0,s2
    80003c36:	00001097          	auipc	ra,0x1
    80003c3a:	b4c080e7          	jalr	-1204(ra) # 80004782 <initlog>
}
    80003c3e:	70a2                	ld	ra,40(sp)
    80003c40:	7402                	ld	s0,32(sp)
    80003c42:	64e2                	ld	s1,24(sp)
    80003c44:	6942                	ld	s2,16(sp)
    80003c46:	69a2                	ld	s3,8(sp)
    80003c48:	6145                	addi	sp,sp,48
    80003c4a:	8082                	ret
    panic("invalid file system");
    80003c4c:	00005517          	auipc	a0,0x5
    80003c50:	a1450513          	addi	a0,a0,-1516 # 80008660 <syscalls+0x158>
    80003c54:	ffffd097          	auipc	ra,0xffffd
    80003c58:	8ea080e7          	jalr	-1814(ra) # 8000053e <panic>

0000000080003c5c <iinit>:
{
    80003c5c:	7179                	addi	sp,sp,-48
    80003c5e:	f406                	sd	ra,40(sp)
    80003c60:	f022                	sd	s0,32(sp)
    80003c62:	ec26                	sd	s1,24(sp)
    80003c64:	e84a                	sd	s2,16(sp)
    80003c66:	e44e                	sd	s3,8(sp)
    80003c68:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c6a:	00005597          	auipc	a1,0x5
    80003c6e:	a0e58593          	addi	a1,a1,-1522 # 80008678 <syscalls+0x170>
    80003c72:	0001c517          	auipc	a0,0x1c
    80003c76:	37650513          	addi	a0,a0,886 # 8001ffe8 <itable>
    80003c7a:	ffffd097          	auipc	ra,0xffffd
    80003c7e:	eda080e7          	jalr	-294(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c82:	0001c497          	auipc	s1,0x1c
    80003c86:	38e48493          	addi	s1,s1,910 # 80020010 <itable+0x28>
    80003c8a:	0001e997          	auipc	s3,0x1e
    80003c8e:	e1698993          	addi	s3,s3,-490 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c92:	00005917          	auipc	s2,0x5
    80003c96:	9ee90913          	addi	s2,s2,-1554 # 80008680 <syscalls+0x178>
    80003c9a:	85ca                	mv	a1,s2
    80003c9c:	8526                	mv	a0,s1
    80003c9e:	00001097          	auipc	ra,0x1
    80003ca2:	e46080e7          	jalr	-442(ra) # 80004ae4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003ca6:	08848493          	addi	s1,s1,136
    80003caa:	ff3498e3          	bne	s1,s3,80003c9a <iinit+0x3e>
}
    80003cae:	70a2                	ld	ra,40(sp)
    80003cb0:	7402                	ld	s0,32(sp)
    80003cb2:	64e2                	ld	s1,24(sp)
    80003cb4:	6942                	ld	s2,16(sp)
    80003cb6:	69a2                	ld	s3,8(sp)
    80003cb8:	6145                	addi	sp,sp,48
    80003cba:	8082                	ret

0000000080003cbc <ialloc>:
{
    80003cbc:	715d                	addi	sp,sp,-80
    80003cbe:	e486                	sd	ra,72(sp)
    80003cc0:	e0a2                	sd	s0,64(sp)
    80003cc2:	fc26                	sd	s1,56(sp)
    80003cc4:	f84a                	sd	s2,48(sp)
    80003cc6:	f44e                	sd	s3,40(sp)
    80003cc8:	f052                	sd	s4,32(sp)
    80003cca:	ec56                	sd	s5,24(sp)
    80003ccc:	e85a                	sd	s6,16(sp)
    80003cce:	e45e                	sd	s7,8(sp)
    80003cd0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cd2:	0001c717          	auipc	a4,0x1c
    80003cd6:	30272703          	lw	a4,770(a4) # 8001ffd4 <sb+0xc>
    80003cda:	4785                	li	a5,1
    80003cdc:	04e7fa63          	bgeu	a5,a4,80003d30 <ialloc+0x74>
    80003ce0:	8aaa                	mv	s5,a0
    80003ce2:	8bae                	mv	s7,a1
    80003ce4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ce6:	0001ca17          	auipc	s4,0x1c
    80003cea:	2e2a0a13          	addi	s4,s4,738 # 8001ffc8 <sb>
    80003cee:	00048b1b          	sext.w	s6,s1
    80003cf2:	0044d593          	srli	a1,s1,0x4
    80003cf6:	018a2783          	lw	a5,24(s4)
    80003cfa:	9dbd                	addw	a1,a1,a5
    80003cfc:	8556                	mv	a0,s5
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	954080e7          	jalr	-1708(ra) # 80003652 <bread>
    80003d06:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d08:	05850993          	addi	s3,a0,88
    80003d0c:	00f4f793          	andi	a5,s1,15
    80003d10:	079a                	slli	a5,a5,0x6
    80003d12:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d14:	00099783          	lh	a5,0(s3)
    80003d18:	c785                	beqz	a5,80003d40 <ialloc+0x84>
    brelse(bp);
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	a68080e7          	jalr	-1432(ra) # 80003782 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d22:	0485                	addi	s1,s1,1
    80003d24:	00ca2703          	lw	a4,12(s4)
    80003d28:	0004879b          	sext.w	a5,s1
    80003d2c:	fce7e1e3          	bltu	a5,a4,80003cee <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d30:	00005517          	auipc	a0,0x5
    80003d34:	95850513          	addi	a0,a0,-1704 # 80008688 <syscalls+0x180>
    80003d38:	ffffd097          	auipc	ra,0xffffd
    80003d3c:	806080e7          	jalr	-2042(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003d40:	04000613          	li	a2,64
    80003d44:	4581                	li	a1,0
    80003d46:	854e                	mv	a0,s3
    80003d48:	ffffd097          	auipc	ra,0xffffd
    80003d4c:	f98080e7          	jalr	-104(ra) # 80000ce0 <memset>
      dip->type = type;
    80003d50:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d54:	854a                	mv	a0,s2
    80003d56:	00001097          	auipc	ra,0x1
    80003d5a:	ca8080e7          	jalr	-856(ra) # 800049fe <log_write>
      brelse(bp);
    80003d5e:	854a                	mv	a0,s2
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	a22080e7          	jalr	-1502(ra) # 80003782 <brelse>
      return iget(dev, inum);
    80003d68:	85da                	mv	a1,s6
    80003d6a:	8556                	mv	a0,s5
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	db4080e7          	jalr	-588(ra) # 80003b20 <iget>
}
    80003d74:	60a6                	ld	ra,72(sp)
    80003d76:	6406                	ld	s0,64(sp)
    80003d78:	74e2                	ld	s1,56(sp)
    80003d7a:	7942                	ld	s2,48(sp)
    80003d7c:	79a2                	ld	s3,40(sp)
    80003d7e:	7a02                	ld	s4,32(sp)
    80003d80:	6ae2                	ld	s5,24(sp)
    80003d82:	6b42                	ld	s6,16(sp)
    80003d84:	6ba2                	ld	s7,8(sp)
    80003d86:	6161                	addi	sp,sp,80
    80003d88:	8082                	ret

0000000080003d8a <iupdate>:
{
    80003d8a:	1101                	addi	sp,sp,-32
    80003d8c:	ec06                	sd	ra,24(sp)
    80003d8e:	e822                	sd	s0,16(sp)
    80003d90:	e426                	sd	s1,8(sp)
    80003d92:	e04a                	sd	s2,0(sp)
    80003d94:	1000                	addi	s0,sp,32
    80003d96:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d98:	415c                	lw	a5,4(a0)
    80003d9a:	0047d79b          	srliw	a5,a5,0x4
    80003d9e:	0001c597          	auipc	a1,0x1c
    80003da2:	2425a583          	lw	a1,578(a1) # 8001ffe0 <sb+0x18>
    80003da6:	9dbd                	addw	a1,a1,a5
    80003da8:	4108                	lw	a0,0(a0)
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	8a8080e7          	jalr	-1880(ra) # 80003652 <bread>
    80003db2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003db4:	05850793          	addi	a5,a0,88
    80003db8:	40c8                	lw	a0,4(s1)
    80003dba:	893d                	andi	a0,a0,15
    80003dbc:	051a                	slli	a0,a0,0x6
    80003dbe:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003dc0:	04449703          	lh	a4,68(s1)
    80003dc4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003dc8:	04649703          	lh	a4,70(s1)
    80003dcc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003dd0:	04849703          	lh	a4,72(s1)
    80003dd4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003dd8:	04a49703          	lh	a4,74(s1)
    80003ddc:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003de0:	44f8                	lw	a4,76(s1)
    80003de2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003de4:	03400613          	li	a2,52
    80003de8:	05048593          	addi	a1,s1,80
    80003dec:	0531                	addi	a0,a0,12
    80003dee:	ffffd097          	auipc	ra,0xffffd
    80003df2:	f52080e7          	jalr	-174(ra) # 80000d40 <memmove>
  log_write(bp);
    80003df6:	854a                	mv	a0,s2
    80003df8:	00001097          	auipc	ra,0x1
    80003dfc:	c06080e7          	jalr	-1018(ra) # 800049fe <log_write>
  brelse(bp);
    80003e00:	854a                	mv	a0,s2
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	980080e7          	jalr	-1664(ra) # 80003782 <brelse>
}
    80003e0a:	60e2                	ld	ra,24(sp)
    80003e0c:	6442                	ld	s0,16(sp)
    80003e0e:	64a2                	ld	s1,8(sp)
    80003e10:	6902                	ld	s2,0(sp)
    80003e12:	6105                	addi	sp,sp,32
    80003e14:	8082                	ret

0000000080003e16 <idup>:
{
    80003e16:	1101                	addi	sp,sp,-32
    80003e18:	ec06                	sd	ra,24(sp)
    80003e1a:	e822                	sd	s0,16(sp)
    80003e1c:	e426                	sd	s1,8(sp)
    80003e1e:	1000                	addi	s0,sp,32
    80003e20:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e22:	0001c517          	auipc	a0,0x1c
    80003e26:	1c650513          	addi	a0,a0,454 # 8001ffe8 <itable>
    80003e2a:	ffffd097          	auipc	ra,0xffffd
    80003e2e:	dba080e7          	jalr	-582(ra) # 80000be4 <acquire>
  ip->ref++;
    80003e32:	449c                	lw	a5,8(s1)
    80003e34:	2785                	addiw	a5,a5,1
    80003e36:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e38:	0001c517          	auipc	a0,0x1c
    80003e3c:	1b050513          	addi	a0,a0,432 # 8001ffe8 <itable>
    80003e40:	ffffd097          	auipc	ra,0xffffd
    80003e44:	e58080e7          	jalr	-424(ra) # 80000c98 <release>
}
    80003e48:	8526                	mv	a0,s1
    80003e4a:	60e2                	ld	ra,24(sp)
    80003e4c:	6442                	ld	s0,16(sp)
    80003e4e:	64a2                	ld	s1,8(sp)
    80003e50:	6105                	addi	sp,sp,32
    80003e52:	8082                	ret

0000000080003e54 <ilock>:
{
    80003e54:	1101                	addi	sp,sp,-32
    80003e56:	ec06                	sd	ra,24(sp)
    80003e58:	e822                	sd	s0,16(sp)
    80003e5a:	e426                	sd	s1,8(sp)
    80003e5c:	e04a                	sd	s2,0(sp)
    80003e5e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e60:	c115                	beqz	a0,80003e84 <ilock+0x30>
    80003e62:	84aa                	mv	s1,a0
    80003e64:	451c                	lw	a5,8(a0)
    80003e66:	00f05f63          	blez	a5,80003e84 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e6a:	0541                	addi	a0,a0,16
    80003e6c:	00001097          	auipc	ra,0x1
    80003e70:	cb2080e7          	jalr	-846(ra) # 80004b1e <acquiresleep>
  if(ip->valid == 0){
    80003e74:	40bc                	lw	a5,64(s1)
    80003e76:	cf99                	beqz	a5,80003e94 <ilock+0x40>
}
    80003e78:	60e2                	ld	ra,24(sp)
    80003e7a:	6442                	ld	s0,16(sp)
    80003e7c:	64a2                	ld	s1,8(sp)
    80003e7e:	6902                	ld	s2,0(sp)
    80003e80:	6105                	addi	sp,sp,32
    80003e82:	8082                	ret
    panic("ilock");
    80003e84:	00005517          	auipc	a0,0x5
    80003e88:	81c50513          	addi	a0,a0,-2020 # 800086a0 <syscalls+0x198>
    80003e8c:	ffffc097          	auipc	ra,0xffffc
    80003e90:	6b2080e7          	jalr	1714(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e94:	40dc                	lw	a5,4(s1)
    80003e96:	0047d79b          	srliw	a5,a5,0x4
    80003e9a:	0001c597          	auipc	a1,0x1c
    80003e9e:	1465a583          	lw	a1,326(a1) # 8001ffe0 <sb+0x18>
    80003ea2:	9dbd                	addw	a1,a1,a5
    80003ea4:	4088                	lw	a0,0(s1)
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	7ac080e7          	jalr	1964(ra) # 80003652 <bread>
    80003eae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003eb0:	05850593          	addi	a1,a0,88
    80003eb4:	40dc                	lw	a5,4(s1)
    80003eb6:	8bbd                	andi	a5,a5,15
    80003eb8:	079a                	slli	a5,a5,0x6
    80003eba:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ebc:	00059783          	lh	a5,0(a1)
    80003ec0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ec4:	00259783          	lh	a5,2(a1)
    80003ec8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ecc:	00459783          	lh	a5,4(a1)
    80003ed0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ed4:	00659783          	lh	a5,6(a1)
    80003ed8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003edc:	459c                	lw	a5,8(a1)
    80003ede:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ee0:	03400613          	li	a2,52
    80003ee4:	05b1                	addi	a1,a1,12
    80003ee6:	05048513          	addi	a0,s1,80
    80003eea:	ffffd097          	auipc	ra,0xffffd
    80003eee:	e56080e7          	jalr	-426(ra) # 80000d40 <memmove>
    brelse(bp);
    80003ef2:	854a                	mv	a0,s2
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	88e080e7          	jalr	-1906(ra) # 80003782 <brelse>
    ip->valid = 1;
    80003efc:	4785                	li	a5,1
    80003efe:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f00:	04449783          	lh	a5,68(s1)
    80003f04:	fbb5                	bnez	a5,80003e78 <ilock+0x24>
      panic("ilock: no type");
    80003f06:	00004517          	auipc	a0,0x4
    80003f0a:	7a250513          	addi	a0,a0,1954 # 800086a8 <syscalls+0x1a0>
    80003f0e:	ffffc097          	auipc	ra,0xffffc
    80003f12:	630080e7          	jalr	1584(ra) # 8000053e <panic>

0000000080003f16 <iunlock>:
{
    80003f16:	1101                	addi	sp,sp,-32
    80003f18:	ec06                	sd	ra,24(sp)
    80003f1a:	e822                	sd	s0,16(sp)
    80003f1c:	e426                	sd	s1,8(sp)
    80003f1e:	e04a                	sd	s2,0(sp)
    80003f20:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f22:	c905                	beqz	a0,80003f52 <iunlock+0x3c>
    80003f24:	84aa                	mv	s1,a0
    80003f26:	01050913          	addi	s2,a0,16
    80003f2a:	854a                	mv	a0,s2
    80003f2c:	00001097          	auipc	ra,0x1
    80003f30:	c8c080e7          	jalr	-884(ra) # 80004bb8 <holdingsleep>
    80003f34:	cd19                	beqz	a0,80003f52 <iunlock+0x3c>
    80003f36:	449c                	lw	a5,8(s1)
    80003f38:	00f05d63          	blez	a5,80003f52 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f3c:	854a                	mv	a0,s2
    80003f3e:	00001097          	auipc	ra,0x1
    80003f42:	c36080e7          	jalr	-970(ra) # 80004b74 <releasesleep>
}
    80003f46:	60e2                	ld	ra,24(sp)
    80003f48:	6442                	ld	s0,16(sp)
    80003f4a:	64a2                	ld	s1,8(sp)
    80003f4c:	6902                	ld	s2,0(sp)
    80003f4e:	6105                	addi	sp,sp,32
    80003f50:	8082                	ret
    panic("iunlock");
    80003f52:	00004517          	auipc	a0,0x4
    80003f56:	76650513          	addi	a0,a0,1894 # 800086b8 <syscalls+0x1b0>
    80003f5a:	ffffc097          	auipc	ra,0xffffc
    80003f5e:	5e4080e7          	jalr	1508(ra) # 8000053e <panic>

0000000080003f62 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f62:	7179                	addi	sp,sp,-48
    80003f64:	f406                	sd	ra,40(sp)
    80003f66:	f022                	sd	s0,32(sp)
    80003f68:	ec26                	sd	s1,24(sp)
    80003f6a:	e84a                	sd	s2,16(sp)
    80003f6c:	e44e                	sd	s3,8(sp)
    80003f6e:	e052                	sd	s4,0(sp)
    80003f70:	1800                	addi	s0,sp,48
    80003f72:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f74:	05050493          	addi	s1,a0,80
    80003f78:	08050913          	addi	s2,a0,128
    80003f7c:	a021                	j	80003f84 <itrunc+0x22>
    80003f7e:	0491                	addi	s1,s1,4
    80003f80:	01248d63          	beq	s1,s2,80003f9a <itrunc+0x38>
    if(ip->addrs[i]){
    80003f84:	408c                	lw	a1,0(s1)
    80003f86:	dde5                	beqz	a1,80003f7e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f88:	0009a503          	lw	a0,0(s3)
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	90c080e7          	jalr	-1780(ra) # 80003898 <bfree>
      ip->addrs[i] = 0;
    80003f94:	0004a023          	sw	zero,0(s1)
    80003f98:	b7dd                	j	80003f7e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f9a:	0809a583          	lw	a1,128(s3)
    80003f9e:	e185                	bnez	a1,80003fbe <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003fa0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003fa4:	854e                	mv	a0,s3
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	de4080e7          	jalr	-540(ra) # 80003d8a <iupdate>
}
    80003fae:	70a2                	ld	ra,40(sp)
    80003fb0:	7402                	ld	s0,32(sp)
    80003fb2:	64e2                	ld	s1,24(sp)
    80003fb4:	6942                	ld	s2,16(sp)
    80003fb6:	69a2                	ld	s3,8(sp)
    80003fb8:	6a02                	ld	s4,0(sp)
    80003fba:	6145                	addi	sp,sp,48
    80003fbc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003fbe:	0009a503          	lw	a0,0(s3)
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	690080e7          	jalr	1680(ra) # 80003652 <bread>
    80003fca:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003fcc:	05850493          	addi	s1,a0,88
    80003fd0:	45850913          	addi	s2,a0,1112
    80003fd4:	a811                	j	80003fe8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003fd6:	0009a503          	lw	a0,0(s3)
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	8be080e7          	jalr	-1858(ra) # 80003898 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003fe2:	0491                	addi	s1,s1,4
    80003fe4:	01248563          	beq	s1,s2,80003fee <itrunc+0x8c>
      if(a[j])
    80003fe8:	408c                	lw	a1,0(s1)
    80003fea:	dde5                	beqz	a1,80003fe2 <itrunc+0x80>
    80003fec:	b7ed                	j	80003fd6 <itrunc+0x74>
    brelse(bp);
    80003fee:	8552                	mv	a0,s4
    80003ff0:	fffff097          	auipc	ra,0xfffff
    80003ff4:	792080e7          	jalr	1938(ra) # 80003782 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ff8:	0809a583          	lw	a1,128(s3)
    80003ffc:	0009a503          	lw	a0,0(s3)
    80004000:	00000097          	auipc	ra,0x0
    80004004:	898080e7          	jalr	-1896(ra) # 80003898 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004008:	0809a023          	sw	zero,128(s3)
    8000400c:	bf51                	j	80003fa0 <itrunc+0x3e>

000000008000400e <iput>:
{
    8000400e:	1101                	addi	sp,sp,-32
    80004010:	ec06                	sd	ra,24(sp)
    80004012:	e822                	sd	s0,16(sp)
    80004014:	e426                	sd	s1,8(sp)
    80004016:	e04a                	sd	s2,0(sp)
    80004018:	1000                	addi	s0,sp,32
    8000401a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000401c:	0001c517          	auipc	a0,0x1c
    80004020:	fcc50513          	addi	a0,a0,-52 # 8001ffe8 <itable>
    80004024:	ffffd097          	auipc	ra,0xffffd
    80004028:	bc0080e7          	jalr	-1088(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000402c:	4498                	lw	a4,8(s1)
    8000402e:	4785                	li	a5,1
    80004030:	02f70363          	beq	a4,a5,80004056 <iput+0x48>
  ip->ref--;
    80004034:	449c                	lw	a5,8(s1)
    80004036:	37fd                	addiw	a5,a5,-1
    80004038:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000403a:	0001c517          	auipc	a0,0x1c
    8000403e:	fae50513          	addi	a0,a0,-82 # 8001ffe8 <itable>
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	c56080e7          	jalr	-938(ra) # 80000c98 <release>
}
    8000404a:	60e2                	ld	ra,24(sp)
    8000404c:	6442                	ld	s0,16(sp)
    8000404e:	64a2                	ld	s1,8(sp)
    80004050:	6902                	ld	s2,0(sp)
    80004052:	6105                	addi	sp,sp,32
    80004054:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004056:	40bc                	lw	a5,64(s1)
    80004058:	dff1                	beqz	a5,80004034 <iput+0x26>
    8000405a:	04a49783          	lh	a5,74(s1)
    8000405e:	fbf9                	bnez	a5,80004034 <iput+0x26>
    acquiresleep(&ip->lock);
    80004060:	01048913          	addi	s2,s1,16
    80004064:	854a                	mv	a0,s2
    80004066:	00001097          	auipc	ra,0x1
    8000406a:	ab8080e7          	jalr	-1352(ra) # 80004b1e <acquiresleep>
    release(&itable.lock);
    8000406e:	0001c517          	auipc	a0,0x1c
    80004072:	f7a50513          	addi	a0,a0,-134 # 8001ffe8 <itable>
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	c22080e7          	jalr	-990(ra) # 80000c98 <release>
    itrunc(ip);
    8000407e:	8526                	mv	a0,s1
    80004080:	00000097          	auipc	ra,0x0
    80004084:	ee2080e7          	jalr	-286(ra) # 80003f62 <itrunc>
    ip->type = 0;
    80004088:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000408c:	8526                	mv	a0,s1
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	cfc080e7          	jalr	-772(ra) # 80003d8a <iupdate>
    ip->valid = 0;
    80004096:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000409a:	854a                	mv	a0,s2
    8000409c:	00001097          	auipc	ra,0x1
    800040a0:	ad8080e7          	jalr	-1320(ra) # 80004b74 <releasesleep>
    acquire(&itable.lock);
    800040a4:	0001c517          	auipc	a0,0x1c
    800040a8:	f4450513          	addi	a0,a0,-188 # 8001ffe8 <itable>
    800040ac:	ffffd097          	auipc	ra,0xffffd
    800040b0:	b38080e7          	jalr	-1224(ra) # 80000be4 <acquire>
    800040b4:	b741                	j	80004034 <iput+0x26>

00000000800040b6 <iunlockput>:
{
    800040b6:	1101                	addi	sp,sp,-32
    800040b8:	ec06                	sd	ra,24(sp)
    800040ba:	e822                	sd	s0,16(sp)
    800040bc:	e426                	sd	s1,8(sp)
    800040be:	1000                	addi	s0,sp,32
    800040c0:	84aa                	mv	s1,a0
  iunlock(ip);
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	e54080e7          	jalr	-428(ra) # 80003f16 <iunlock>
  iput(ip);
    800040ca:	8526                	mv	a0,s1
    800040cc:	00000097          	auipc	ra,0x0
    800040d0:	f42080e7          	jalr	-190(ra) # 8000400e <iput>
}
    800040d4:	60e2                	ld	ra,24(sp)
    800040d6:	6442                	ld	s0,16(sp)
    800040d8:	64a2                	ld	s1,8(sp)
    800040da:	6105                	addi	sp,sp,32
    800040dc:	8082                	ret

00000000800040de <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040de:	1141                	addi	sp,sp,-16
    800040e0:	e422                	sd	s0,8(sp)
    800040e2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040e4:	411c                	lw	a5,0(a0)
    800040e6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040e8:	415c                	lw	a5,4(a0)
    800040ea:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040ec:	04451783          	lh	a5,68(a0)
    800040f0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040f4:	04a51783          	lh	a5,74(a0)
    800040f8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040fc:	04c56783          	lwu	a5,76(a0)
    80004100:	e99c                	sd	a5,16(a1)
}
    80004102:	6422                	ld	s0,8(sp)
    80004104:	0141                	addi	sp,sp,16
    80004106:	8082                	ret

0000000080004108 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004108:	457c                	lw	a5,76(a0)
    8000410a:	0ed7e963          	bltu	a5,a3,800041fc <readi+0xf4>
{
    8000410e:	7159                	addi	sp,sp,-112
    80004110:	f486                	sd	ra,104(sp)
    80004112:	f0a2                	sd	s0,96(sp)
    80004114:	eca6                	sd	s1,88(sp)
    80004116:	e8ca                	sd	s2,80(sp)
    80004118:	e4ce                	sd	s3,72(sp)
    8000411a:	e0d2                	sd	s4,64(sp)
    8000411c:	fc56                	sd	s5,56(sp)
    8000411e:	f85a                	sd	s6,48(sp)
    80004120:	f45e                	sd	s7,40(sp)
    80004122:	f062                	sd	s8,32(sp)
    80004124:	ec66                	sd	s9,24(sp)
    80004126:	e86a                	sd	s10,16(sp)
    80004128:	e46e                	sd	s11,8(sp)
    8000412a:	1880                	addi	s0,sp,112
    8000412c:	8baa                	mv	s7,a0
    8000412e:	8c2e                	mv	s8,a1
    80004130:	8ab2                	mv	s5,a2
    80004132:	84b6                	mv	s1,a3
    80004134:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004136:	9f35                	addw	a4,a4,a3
    return 0;
    80004138:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000413a:	0ad76063          	bltu	a4,a3,800041da <readi+0xd2>
  if(off + n > ip->size)
    8000413e:	00e7f463          	bgeu	a5,a4,80004146 <readi+0x3e>
    n = ip->size - off;
    80004142:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004146:	0a0b0963          	beqz	s6,800041f8 <readi+0xf0>
    8000414a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000414c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004150:	5cfd                	li	s9,-1
    80004152:	a82d                	j	8000418c <readi+0x84>
    80004154:	020a1d93          	slli	s11,s4,0x20
    80004158:	020ddd93          	srli	s11,s11,0x20
    8000415c:	05890613          	addi	a2,s2,88
    80004160:	86ee                	mv	a3,s11
    80004162:	963a                	add	a2,a2,a4
    80004164:	85d6                	mv	a1,s5
    80004166:	8562                	mv	a0,s8
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	acc080e7          	jalr	-1332(ra) # 80002c34 <either_copyout>
    80004170:	05950d63          	beq	a0,s9,800041ca <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004174:	854a                	mv	a0,s2
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	60c080e7          	jalr	1548(ra) # 80003782 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000417e:	013a09bb          	addw	s3,s4,s3
    80004182:	009a04bb          	addw	s1,s4,s1
    80004186:	9aee                	add	s5,s5,s11
    80004188:	0569f763          	bgeu	s3,s6,800041d6 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000418c:	000ba903          	lw	s2,0(s7)
    80004190:	00a4d59b          	srliw	a1,s1,0xa
    80004194:	855e                	mv	a0,s7
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	8b0080e7          	jalr	-1872(ra) # 80003a46 <bmap>
    8000419e:	0005059b          	sext.w	a1,a0
    800041a2:	854a                	mv	a0,s2
    800041a4:	fffff097          	auipc	ra,0xfffff
    800041a8:	4ae080e7          	jalr	1198(ra) # 80003652 <bread>
    800041ac:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041ae:	3ff4f713          	andi	a4,s1,1023
    800041b2:	40ed07bb          	subw	a5,s10,a4
    800041b6:	413b06bb          	subw	a3,s6,s3
    800041ba:	8a3e                	mv	s4,a5
    800041bc:	2781                	sext.w	a5,a5
    800041be:	0006861b          	sext.w	a2,a3
    800041c2:	f8f679e3          	bgeu	a2,a5,80004154 <readi+0x4c>
    800041c6:	8a36                	mv	s4,a3
    800041c8:	b771                	j	80004154 <readi+0x4c>
      brelse(bp);
    800041ca:	854a                	mv	a0,s2
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	5b6080e7          	jalr	1462(ra) # 80003782 <brelse>
      tot = -1;
    800041d4:	59fd                	li	s3,-1
  }
  return tot;
    800041d6:	0009851b          	sext.w	a0,s3
}
    800041da:	70a6                	ld	ra,104(sp)
    800041dc:	7406                	ld	s0,96(sp)
    800041de:	64e6                	ld	s1,88(sp)
    800041e0:	6946                	ld	s2,80(sp)
    800041e2:	69a6                	ld	s3,72(sp)
    800041e4:	6a06                	ld	s4,64(sp)
    800041e6:	7ae2                	ld	s5,56(sp)
    800041e8:	7b42                	ld	s6,48(sp)
    800041ea:	7ba2                	ld	s7,40(sp)
    800041ec:	7c02                	ld	s8,32(sp)
    800041ee:	6ce2                	ld	s9,24(sp)
    800041f0:	6d42                	ld	s10,16(sp)
    800041f2:	6da2                	ld	s11,8(sp)
    800041f4:	6165                	addi	sp,sp,112
    800041f6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041f8:	89da                	mv	s3,s6
    800041fa:	bff1                	j	800041d6 <readi+0xce>
    return 0;
    800041fc:	4501                	li	a0,0
}
    800041fe:	8082                	ret

0000000080004200 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004200:	457c                	lw	a5,76(a0)
    80004202:	10d7e863          	bltu	a5,a3,80004312 <writei+0x112>
{
    80004206:	7159                	addi	sp,sp,-112
    80004208:	f486                	sd	ra,104(sp)
    8000420a:	f0a2                	sd	s0,96(sp)
    8000420c:	eca6                	sd	s1,88(sp)
    8000420e:	e8ca                	sd	s2,80(sp)
    80004210:	e4ce                	sd	s3,72(sp)
    80004212:	e0d2                	sd	s4,64(sp)
    80004214:	fc56                	sd	s5,56(sp)
    80004216:	f85a                	sd	s6,48(sp)
    80004218:	f45e                	sd	s7,40(sp)
    8000421a:	f062                	sd	s8,32(sp)
    8000421c:	ec66                	sd	s9,24(sp)
    8000421e:	e86a                	sd	s10,16(sp)
    80004220:	e46e                	sd	s11,8(sp)
    80004222:	1880                	addi	s0,sp,112
    80004224:	8b2a                	mv	s6,a0
    80004226:	8c2e                	mv	s8,a1
    80004228:	8ab2                	mv	s5,a2
    8000422a:	8936                	mv	s2,a3
    8000422c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000422e:	00e687bb          	addw	a5,a3,a4
    80004232:	0ed7e263          	bltu	a5,a3,80004316 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004236:	00043737          	lui	a4,0x43
    8000423a:	0ef76063          	bltu	a4,a5,8000431a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000423e:	0c0b8863          	beqz	s7,8000430e <writei+0x10e>
    80004242:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004244:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004248:	5cfd                	li	s9,-1
    8000424a:	a091                	j	8000428e <writei+0x8e>
    8000424c:	02099d93          	slli	s11,s3,0x20
    80004250:	020ddd93          	srli	s11,s11,0x20
    80004254:	05848513          	addi	a0,s1,88
    80004258:	86ee                	mv	a3,s11
    8000425a:	8656                	mv	a2,s5
    8000425c:	85e2                	mv	a1,s8
    8000425e:	953a                	add	a0,a0,a4
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	a2a080e7          	jalr	-1494(ra) # 80002c8a <either_copyin>
    80004268:	07950263          	beq	a0,s9,800042cc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000426c:	8526                	mv	a0,s1
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	790080e7          	jalr	1936(ra) # 800049fe <log_write>
    brelse(bp);
    80004276:	8526                	mv	a0,s1
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	50a080e7          	jalr	1290(ra) # 80003782 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004280:	01498a3b          	addw	s4,s3,s4
    80004284:	0129893b          	addw	s2,s3,s2
    80004288:	9aee                	add	s5,s5,s11
    8000428a:	057a7663          	bgeu	s4,s7,800042d6 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000428e:	000b2483          	lw	s1,0(s6)
    80004292:	00a9559b          	srliw	a1,s2,0xa
    80004296:	855a                	mv	a0,s6
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	7ae080e7          	jalr	1966(ra) # 80003a46 <bmap>
    800042a0:	0005059b          	sext.w	a1,a0
    800042a4:	8526                	mv	a0,s1
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	3ac080e7          	jalr	940(ra) # 80003652 <bread>
    800042ae:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042b0:	3ff97713          	andi	a4,s2,1023
    800042b4:	40ed07bb          	subw	a5,s10,a4
    800042b8:	414b86bb          	subw	a3,s7,s4
    800042bc:	89be                	mv	s3,a5
    800042be:	2781                	sext.w	a5,a5
    800042c0:	0006861b          	sext.w	a2,a3
    800042c4:	f8f674e3          	bgeu	a2,a5,8000424c <writei+0x4c>
    800042c8:	89b6                	mv	s3,a3
    800042ca:	b749                	j	8000424c <writei+0x4c>
      brelse(bp);
    800042cc:	8526                	mv	a0,s1
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	4b4080e7          	jalr	1204(ra) # 80003782 <brelse>
  }

  if(off > ip->size)
    800042d6:	04cb2783          	lw	a5,76(s6)
    800042da:	0127f463          	bgeu	a5,s2,800042e2 <writei+0xe2>
    ip->size = off;
    800042de:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042e2:	855a                	mv	a0,s6
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	aa6080e7          	jalr	-1370(ra) # 80003d8a <iupdate>

  return tot;
    800042ec:	000a051b          	sext.w	a0,s4
}
    800042f0:	70a6                	ld	ra,104(sp)
    800042f2:	7406                	ld	s0,96(sp)
    800042f4:	64e6                	ld	s1,88(sp)
    800042f6:	6946                	ld	s2,80(sp)
    800042f8:	69a6                	ld	s3,72(sp)
    800042fa:	6a06                	ld	s4,64(sp)
    800042fc:	7ae2                	ld	s5,56(sp)
    800042fe:	7b42                	ld	s6,48(sp)
    80004300:	7ba2                	ld	s7,40(sp)
    80004302:	7c02                	ld	s8,32(sp)
    80004304:	6ce2                	ld	s9,24(sp)
    80004306:	6d42                	ld	s10,16(sp)
    80004308:	6da2                	ld	s11,8(sp)
    8000430a:	6165                	addi	sp,sp,112
    8000430c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000430e:	8a5e                	mv	s4,s7
    80004310:	bfc9                	j	800042e2 <writei+0xe2>
    return -1;
    80004312:	557d                	li	a0,-1
}
    80004314:	8082                	ret
    return -1;
    80004316:	557d                	li	a0,-1
    80004318:	bfe1                	j	800042f0 <writei+0xf0>
    return -1;
    8000431a:	557d                	li	a0,-1
    8000431c:	bfd1                	j	800042f0 <writei+0xf0>

000000008000431e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000431e:	1141                	addi	sp,sp,-16
    80004320:	e406                	sd	ra,8(sp)
    80004322:	e022                	sd	s0,0(sp)
    80004324:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004326:	4639                	li	a2,14
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	a90080e7          	jalr	-1392(ra) # 80000db8 <strncmp>
}
    80004330:	60a2                	ld	ra,8(sp)
    80004332:	6402                	ld	s0,0(sp)
    80004334:	0141                	addi	sp,sp,16
    80004336:	8082                	ret

0000000080004338 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004338:	7139                	addi	sp,sp,-64
    8000433a:	fc06                	sd	ra,56(sp)
    8000433c:	f822                	sd	s0,48(sp)
    8000433e:	f426                	sd	s1,40(sp)
    80004340:	f04a                	sd	s2,32(sp)
    80004342:	ec4e                	sd	s3,24(sp)
    80004344:	e852                	sd	s4,16(sp)
    80004346:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004348:	04451703          	lh	a4,68(a0)
    8000434c:	4785                	li	a5,1
    8000434e:	00f71a63          	bne	a4,a5,80004362 <dirlookup+0x2a>
    80004352:	892a                	mv	s2,a0
    80004354:	89ae                	mv	s3,a1
    80004356:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004358:	457c                	lw	a5,76(a0)
    8000435a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000435c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000435e:	e79d                	bnez	a5,8000438c <dirlookup+0x54>
    80004360:	a8a5                	j	800043d8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004362:	00004517          	auipc	a0,0x4
    80004366:	35e50513          	addi	a0,a0,862 # 800086c0 <syscalls+0x1b8>
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	1d4080e7          	jalr	468(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004372:	00004517          	auipc	a0,0x4
    80004376:	36650513          	addi	a0,a0,870 # 800086d8 <syscalls+0x1d0>
    8000437a:	ffffc097          	auipc	ra,0xffffc
    8000437e:	1c4080e7          	jalr	452(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004382:	24c1                	addiw	s1,s1,16
    80004384:	04c92783          	lw	a5,76(s2)
    80004388:	04f4f763          	bgeu	s1,a5,800043d6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000438c:	4741                	li	a4,16
    8000438e:	86a6                	mv	a3,s1
    80004390:	fc040613          	addi	a2,s0,-64
    80004394:	4581                	li	a1,0
    80004396:	854a                	mv	a0,s2
    80004398:	00000097          	auipc	ra,0x0
    8000439c:	d70080e7          	jalr	-656(ra) # 80004108 <readi>
    800043a0:	47c1                	li	a5,16
    800043a2:	fcf518e3          	bne	a0,a5,80004372 <dirlookup+0x3a>
    if(de.inum == 0)
    800043a6:	fc045783          	lhu	a5,-64(s0)
    800043aa:	dfe1                	beqz	a5,80004382 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800043ac:	fc240593          	addi	a1,s0,-62
    800043b0:	854e                	mv	a0,s3
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	f6c080e7          	jalr	-148(ra) # 8000431e <namecmp>
    800043ba:	f561                	bnez	a0,80004382 <dirlookup+0x4a>
      if(poff)
    800043bc:	000a0463          	beqz	s4,800043c4 <dirlookup+0x8c>
        *poff = off;
    800043c0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043c4:	fc045583          	lhu	a1,-64(s0)
    800043c8:	00092503          	lw	a0,0(s2)
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	754080e7          	jalr	1876(ra) # 80003b20 <iget>
    800043d4:	a011                	j	800043d8 <dirlookup+0xa0>
  return 0;
    800043d6:	4501                	li	a0,0
}
    800043d8:	70e2                	ld	ra,56(sp)
    800043da:	7442                	ld	s0,48(sp)
    800043dc:	74a2                	ld	s1,40(sp)
    800043de:	7902                	ld	s2,32(sp)
    800043e0:	69e2                	ld	s3,24(sp)
    800043e2:	6a42                	ld	s4,16(sp)
    800043e4:	6121                	addi	sp,sp,64
    800043e6:	8082                	ret

00000000800043e8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043e8:	711d                	addi	sp,sp,-96
    800043ea:	ec86                	sd	ra,88(sp)
    800043ec:	e8a2                	sd	s0,80(sp)
    800043ee:	e4a6                	sd	s1,72(sp)
    800043f0:	e0ca                	sd	s2,64(sp)
    800043f2:	fc4e                	sd	s3,56(sp)
    800043f4:	f852                	sd	s4,48(sp)
    800043f6:	f456                	sd	s5,40(sp)
    800043f8:	f05a                	sd	s6,32(sp)
    800043fa:	ec5e                	sd	s7,24(sp)
    800043fc:	e862                	sd	s8,16(sp)
    800043fe:	e466                	sd	s9,8(sp)
    80004400:	1080                	addi	s0,sp,96
    80004402:	84aa                	mv	s1,a0
    80004404:	8b2e                	mv	s6,a1
    80004406:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004408:	00054703          	lbu	a4,0(a0)
    8000440c:	02f00793          	li	a5,47
    80004410:	02f70363          	beq	a4,a5,80004436 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	7f4080e7          	jalr	2036(ra) # 80001c08 <myproc>
    8000441c:	17053503          	ld	a0,368(a0)
    80004420:	00000097          	auipc	ra,0x0
    80004424:	9f6080e7          	jalr	-1546(ra) # 80003e16 <idup>
    80004428:	89aa                	mv	s3,a0
  while(*path == '/')
    8000442a:	02f00913          	li	s2,47
  len = path - s;
    8000442e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004430:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004432:	4c05                	li	s8,1
    80004434:	a865                	j	800044ec <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004436:	4585                	li	a1,1
    80004438:	4505                	li	a0,1
    8000443a:	fffff097          	auipc	ra,0xfffff
    8000443e:	6e6080e7          	jalr	1766(ra) # 80003b20 <iget>
    80004442:	89aa                	mv	s3,a0
    80004444:	b7dd                	j	8000442a <namex+0x42>
      iunlockput(ip);
    80004446:	854e                	mv	a0,s3
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	c6e080e7          	jalr	-914(ra) # 800040b6 <iunlockput>
      return 0;
    80004450:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004452:	854e                	mv	a0,s3
    80004454:	60e6                	ld	ra,88(sp)
    80004456:	6446                	ld	s0,80(sp)
    80004458:	64a6                	ld	s1,72(sp)
    8000445a:	6906                	ld	s2,64(sp)
    8000445c:	79e2                	ld	s3,56(sp)
    8000445e:	7a42                	ld	s4,48(sp)
    80004460:	7aa2                	ld	s5,40(sp)
    80004462:	7b02                	ld	s6,32(sp)
    80004464:	6be2                	ld	s7,24(sp)
    80004466:	6c42                	ld	s8,16(sp)
    80004468:	6ca2                	ld	s9,8(sp)
    8000446a:	6125                	addi	sp,sp,96
    8000446c:	8082                	ret
      iunlock(ip);
    8000446e:	854e                	mv	a0,s3
    80004470:	00000097          	auipc	ra,0x0
    80004474:	aa6080e7          	jalr	-1370(ra) # 80003f16 <iunlock>
      return ip;
    80004478:	bfe9                	j	80004452 <namex+0x6a>
      iunlockput(ip);
    8000447a:	854e                	mv	a0,s3
    8000447c:	00000097          	auipc	ra,0x0
    80004480:	c3a080e7          	jalr	-966(ra) # 800040b6 <iunlockput>
      return 0;
    80004484:	89d2                	mv	s3,s4
    80004486:	b7f1                	j	80004452 <namex+0x6a>
  len = path - s;
    80004488:	40b48633          	sub	a2,s1,a1
    8000448c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004490:	094cd463          	bge	s9,s4,80004518 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004494:	4639                	li	a2,14
    80004496:	8556                	mv	a0,s5
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	8a8080e7          	jalr	-1880(ra) # 80000d40 <memmove>
  while(*path == '/')
    800044a0:	0004c783          	lbu	a5,0(s1)
    800044a4:	01279763          	bne	a5,s2,800044b2 <namex+0xca>
    path++;
    800044a8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044aa:	0004c783          	lbu	a5,0(s1)
    800044ae:	ff278de3          	beq	a5,s2,800044a8 <namex+0xc0>
    ilock(ip);
    800044b2:	854e                	mv	a0,s3
    800044b4:	00000097          	auipc	ra,0x0
    800044b8:	9a0080e7          	jalr	-1632(ra) # 80003e54 <ilock>
    if(ip->type != T_DIR){
    800044bc:	04499783          	lh	a5,68(s3)
    800044c0:	f98793e3          	bne	a5,s8,80004446 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800044c4:	000b0563          	beqz	s6,800044ce <namex+0xe6>
    800044c8:	0004c783          	lbu	a5,0(s1)
    800044cc:	d3cd                	beqz	a5,8000446e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044ce:	865e                	mv	a2,s7
    800044d0:	85d6                	mv	a1,s5
    800044d2:	854e                	mv	a0,s3
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	e64080e7          	jalr	-412(ra) # 80004338 <dirlookup>
    800044dc:	8a2a                	mv	s4,a0
    800044de:	dd51                	beqz	a0,8000447a <namex+0x92>
    iunlockput(ip);
    800044e0:	854e                	mv	a0,s3
    800044e2:	00000097          	auipc	ra,0x0
    800044e6:	bd4080e7          	jalr	-1068(ra) # 800040b6 <iunlockput>
    ip = next;
    800044ea:	89d2                	mv	s3,s4
  while(*path == '/')
    800044ec:	0004c783          	lbu	a5,0(s1)
    800044f0:	05279763          	bne	a5,s2,8000453e <namex+0x156>
    path++;
    800044f4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044f6:	0004c783          	lbu	a5,0(s1)
    800044fa:	ff278de3          	beq	a5,s2,800044f4 <namex+0x10c>
  if(*path == 0)
    800044fe:	c79d                	beqz	a5,8000452c <namex+0x144>
    path++;
    80004500:	85a6                	mv	a1,s1
  len = path - s;
    80004502:	8a5e                	mv	s4,s7
    80004504:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004506:	01278963          	beq	a5,s2,80004518 <namex+0x130>
    8000450a:	dfbd                	beqz	a5,80004488 <namex+0xa0>
    path++;
    8000450c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000450e:	0004c783          	lbu	a5,0(s1)
    80004512:	ff279ce3          	bne	a5,s2,8000450a <namex+0x122>
    80004516:	bf8d                	j	80004488 <namex+0xa0>
    memmove(name, s, len);
    80004518:	2601                	sext.w	a2,a2
    8000451a:	8556                	mv	a0,s5
    8000451c:	ffffd097          	auipc	ra,0xffffd
    80004520:	824080e7          	jalr	-2012(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004524:	9a56                	add	s4,s4,s5
    80004526:	000a0023          	sb	zero,0(s4)
    8000452a:	bf9d                	j	800044a0 <namex+0xb8>
  if(nameiparent){
    8000452c:	f20b03e3          	beqz	s6,80004452 <namex+0x6a>
    iput(ip);
    80004530:	854e                	mv	a0,s3
    80004532:	00000097          	auipc	ra,0x0
    80004536:	adc080e7          	jalr	-1316(ra) # 8000400e <iput>
    return 0;
    8000453a:	4981                	li	s3,0
    8000453c:	bf19                	j	80004452 <namex+0x6a>
  if(*path == 0)
    8000453e:	d7fd                	beqz	a5,8000452c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004540:	0004c783          	lbu	a5,0(s1)
    80004544:	85a6                	mv	a1,s1
    80004546:	b7d1                	j	8000450a <namex+0x122>

0000000080004548 <dirlink>:
{
    80004548:	7139                	addi	sp,sp,-64
    8000454a:	fc06                	sd	ra,56(sp)
    8000454c:	f822                	sd	s0,48(sp)
    8000454e:	f426                	sd	s1,40(sp)
    80004550:	f04a                	sd	s2,32(sp)
    80004552:	ec4e                	sd	s3,24(sp)
    80004554:	e852                	sd	s4,16(sp)
    80004556:	0080                	addi	s0,sp,64
    80004558:	892a                	mv	s2,a0
    8000455a:	8a2e                	mv	s4,a1
    8000455c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000455e:	4601                	li	a2,0
    80004560:	00000097          	auipc	ra,0x0
    80004564:	dd8080e7          	jalr	-552(ra) # 80004338 <dirlookup>
    80004568:	e93d                	bnez	a0,800045de <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000456a:	04c92483          	lw	s1,76(s2)
    8000456e:	c49d                	beqz	s1,8000459c <dirlink+0x54>
    80004570:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004572:	4741                	li	a4,16
    80004574:	86a6                	mv	a3,s1
    80004576:	fc040613          	addi	a2,s0,-64
    8000457a:	4581                	li	a1,0
    8000457c:	854a                	mv	a0,s2
    8000457e:	00000097          	auipc	ra,0x0
    80004582:	b8a080e7          	jalr	-1142(ra) # 80004108 <readi>
    80004586:	47c1                	li	a5,16
    80004588:	06f51163          	bne	a0,a5,800045ea <dirlink+0xa2>
    if(de.inum == 0)
    8000458c:	fc045783          	lhu	a5,-64(s0)
    80004590:	c791                	beqz	a5,8000459c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004592:	24c1                	addiw	s1,s1,16
    80004594:	04c92783          	lw	a5,76(s2)
    80004598:	fcf4ede3          	bltu	s1,a5,80004572 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000459c:	4639                	li	a2,14
    8000459e:	85d2                	mv	a1,s4
    800045a0:	fc240513          	addi	a0,s0,-62
    800045a4:	ffffd097          	auipc	ra,0xffffd
    800045a8:	850080e7          	jalr	-1968(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800045ac:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045b0:	4741                	li	a4,16
    800045b2:	86a6                	mv	a3,s1
    800045b4:	fc040613          	addi	a2,s0,-64
    800045b8:	4581                	li	a1,0
    800045ba:	854a                	mv	a0,s2
    800045bc:	00000097          	auipc	ra,0x0
    800045c0:	c44080e7          	jalr	-956(ra) # 80004200 <writei>
    800045c4:	872a                	mv	a4,a0
    800045c6:	47c1                	li	a5,16
  return 0;
    800045c8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045ca:	02f71863          	bne	a4,a5,800045fa <dirlink+0xb2>
}
    800045ce:	70e2                	ld	ra,56(sp)
    800045d0:	7442                	ld	s0,48(sp)
    800045d2:	74a2                	ld	s1,40(sp)
    800045d4:	7902                	ld	s2,32(sp)
    800045d6:	69e2                	ld	s3,24(sp)
    800045d8:	6a42                	ld	s4,16(sp)
    800045da:	6121                	addi	sp,sp,64
    800045dc:	8082                	ret
    iput(ip);
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	a30080e7          	jalr	-1488(ra) # 8000400e <iput>
    return -1;
    800045e6:	557d                	li	a0,-1
    800045e8:	b7dd                	j	800045ce <dirlink+0x86>
      panic("dirlink read");
    800045ea:	00004517          	auipc	a0,0x4
    800045ee:	0fe50513          	addi	a0,a0,254 # 800086e8 <syscalls+0x1e0>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	f4c080e7          	jalr	-180(ra) # 8000053e <panic>
    panic("dirlink");
    800045fa:	00004517          	auipc	a0,0x4
    800045fe:	1fe50513          	addi	a0,a0,510 # 800087f8 <syscalls+0x2f0>
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	f3c080e7          	jalr	-196(ra) # 8000053e <panic>

000000008000460a <namei>:

struct inode*
namei(char *path)
{
    8000460a:	1101                	addi	sp,sp,-32
    8000460c:	ec06                	sd	ra,24(sp)
    8000460e:	e822                	sd	s0,16(sp)
    80004610:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004612:	fe040613          	addi	a2,s0,-32
    80004616:	4581                	li	a1,0
    80004618:	00000097          	auipc	ra,0x0
    8000461c:	dd0080e7          	jalr	-560(ra) # 800043e8 <namex>
}
    80004620:	60e2                	ld	ra,24(sp)
    80004622:	6442                	ld	s0,16(sp)
    80004624:	6105                	addi	sp,sp,32
    80004626:	8082                	ret

0000000080004628 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004628:	1141                	addi	sp,sp,-16
    8000462a:	e406                	sd	ra,8(sp)
    8000462c:	e022                	sd	s0,0(sp)
    8000462e:	0800                	addi	s0,sp,16
    80004630:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004632:	4585                	li	a1,1
    80004634:	00000097          	auipc	ra,0x0
    80004638:	db4080e7          	jalr	-588(ra) # 800043e8 <namex>
}
    8000463c:	60a2                	ld	ra,8(sp)
    8000463e:	6402                	ld	s0,0(sp)
    80004640:	0141                	addi	sp,sp,16
    80004642:	8082                	ret

0000000080004644 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004644:	1101                	addi	sp,sp,-32
    80004646:	ec06                	sd	ra,24(sp)
    80004648:	e822                	sd	s0,16(sp)
    8000464a:	e426                	sd	s1,8(sp)
    8000464c:	e04a                	sd	s2,0(sp)
    8000464e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004650:	0001d917          	auipc	s2,0x1d
    80004654:	44090913          	addi	s2,s2,1088 # 80021a90 <log>
    80004658:	01892583          	lw	a1,24(s2)
    8000465c:	02892503          	lw	a0,40(s2)
    80004660:	fffff097          	auipc	ra,0xfffff
    80004664:	ff2080e7          	jalr	-14(ra) # 80003652 <bread>
    80004668:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000466a:	02c92683          	lw	a3,44(s2)
    8000466e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004670:	02d05763          	blez	a3,8000469e <write_head+0x5a>
    80004674:	0001d797          	auipc	a5,0x1d
    80004678:	44c78793          	addi	a5,a5,1100 # 80021ac0 <log+0x30>
    8000467c:	05c50713          	addi	a4,a0,92
    80004680:	36fd                	addiw	a3,a3,-1
    80004682:	1682                	slli	a3,a3,0x20
    80004684:	9281                	srli	a3,a3,0x20
    80004686:	068a                	slli	a3,a3,0x2
    80004688:	0001d617          	auipc	a2,0x1d
    8000468c:	43c60613          	addi	a2,a2,1084 # 80021ac4 <log+0x34>
    80004690:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004692:	4390                	lw	a2,0(a5)
    80004694:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004696:	0791                	addi	a5,a5,4
    80004698:	0711                	addi	a4,a4,4
    8000469a:	fed79ce3          	bne	a5,a3,80004692 <write_head+0x4e>
  }
  bwrite(buf);
    8000469e:	8526                	mv	a0,s1
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	0a4080e7          	jalr	164(ra) # 80003744 <bwrite>
  brelse(buf);
    800046a8:	8526                	mv	a0,s1
    800046aa:	fffff097          	auipc	ra,0xfffff
    800046ae:	0d8080e7          	jalr	216(ra) # 80003782 <brelse>
}
    800046b2:	60e2                	ld	ra,24(sp)
    800046b4:	6442                	ld	s0,16(sp)
    800046b6:	64a2                	ld	s1,8(sp)
    800046b8:	6902                	ld	s2,0(sp)
    800046ba:	6105                	addi	sp,sp,32
    800046bc:	8082                	ret

00000000800046be <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800046be:	0001d797          	auipc	a5,0x1d
    800046c2:	3fe7a783          	lw	a5,1022(a5) # 80021abc <log+0x2c>
    800046c6:	0af05d63          	blez	a5,80004780 <install_trans+0xc2>
{
    800046ca:	7139                	addi	sp,sp,-64
    800046cc:	fc06                	sd	ra,56(sp)
    800046ce:	f822                	sd	s0,48(sp)
    800046d0:	f426                	sd	s1,40(sp)
    800046d2:	f04a                	sd	s2,32(sp)
    800046d4:	ec4e                	sd	s3,24(sp)
    800046d6:	e852                	sd	s4,16(sp)
    800046d8:	e456                	sd	s5,8(sp)
    800046da:	e05a                	sd	s6,0(sp)
    800046dc:	0080                	addi	s0,sp,64
    800046de:	8b2a                	mv	s6,a0
    800046e0:	0001da97          	auipc	s5,0x1d
    800046e4:	3e0a8a93          	addi	s5,s5,992 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046e8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046ea:	0001d997          	auipc	s3,0x1d
    800046ee:	3a698993          	addi	s3,s3,934 # 80021a90 <log>
    800046f2:	a035                	j	8000471e <install_trans+0x60>
      bunpin(dbuf);
    800046f4:	8526                	mv	a0,s1
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	166080e7          	jalr	358(ra) # 8000385c <bunpin>
    brelse(lbuf);
    800046fe:	854a                	mv	a0,s2
    80004700:	fffff097          	auipc	ra,0xfffff
    80004704:	082080e7          	jalr	130(ra) # 80003782 <brelse>
    brelse(dbuf);
    80004708:	8526                	mv	a0,s1
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	078080e7          	jalr	120(ra) # 80003782 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004712:	2a05                	addiw	s4,s4,1
    80004714:	0a91                	addi	s5,s5,4
    80004716:	02c9a783          	lw	a5,44(s3)
    8000471a:	04fa5963          	bge	s4,a5,8000476c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000471e:	0189a583          	lw	a1,24(s3)
    80004722:	014585bb          	addw	a1,a1,s4
    80004726:	2585                	addiw	a1,a1,1
    80004728:	0289a503          	lw	a0,40(s3)
    8000472c:	fffff097          	auipc	ra,0xfffff
    80004730:	f26080e7          	jalr	-218(ra) # 80003652 <bread>
    80004734:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004736:	000aa583          	lw	a1,0(s5)
    8000473a:	0289a503          	lw	a0,40(s3)
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	f14080e7          	jalr	-236(ra) # 80003652 <bread>
    80004746:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004748:	40000613          	li	a2,1024
    8000474c:	05890593          	addi	a1,s2,88
    80004750:	05850513          	addi	a0,a0,88
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	5ec080e7          	jalr	1516(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000475c:	8526                	mv	a0,s1
    8000475e:	fffff097          	auipc	ra,0xfffff
    80004762:	fe6080e7          	jalr	-26(ra) # 80003744 <bwrite>
    if(recovering == 0)
    80004766:	f80b1ce3          	bnez	s6,800046fe <install_trans+0x40>
    8000476a:	b769                	j	800046f4 <install_trans+0x36>
}
    8000476c:	70e2                	ld	ra,56(sp)
    8000476e:	7442                	ld	s0,48(sp)
    80004770:	74a2                	ld	s1,40(sp)
    80004772:	7902                	ld	s2,32(sp)
    80004774:	69e2                	ld	s3,24(sp)
    80004776:	6a42                	ld	s4,16(sp)
    80004778:	6aa2                	ld	s5,8(sp)
    8000477a:	6b02                	ld	s6,0(sp)
    8000477c:	6121                	addi	sp,sp,64
    8000477e:	8082                	ret
    80004780:	8082                	ret

0000000080004782 <initlog>:
{
    80004782:	7179                	addi	sp,sp,-48
    80004784:	f406                	sd	ra,40(sp)
    80004786:	f022                	sd	s0,32(sp)
    80004788:	ec26                	sd	s1,24(sp)
    8000478a:	e84a                	sd	s2,16(sp)
    8000478c:	e44e                	sd	s3,8(sp)
    8000478e:	1800                	addi	s0,sp,48
    80004790:	892a                	mv	s2,a0
    80004792:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004794:	0001d497          	auipc	s1,0x1d
    80004798:	2fc48493          	addi	s1,s1,764 # 80021a90 <log>
    8000479c:	00004597          	auipc	a1,0x4
    800047a0:	f5c58593          	addi	a1,a1,-164 # 800086f8 <syscalls+0x1f0>
    800047a4:	8526                	mv	a0,s1
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	3ae080e7          	jalr	942(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800047ae:	0149a583          	lw	a1,20(s3)
    800047b2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800047b4:	0109a783          	lw	a5,16(s3)
    800047b8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800047ba:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800047be:	854a                	mv	a0,s2
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	e92080e7          	jalr	-366(ra) # 80003652 <bread>
  log.lh.n = lh->n;
    800047c8:	4d3c                	lw	a5,88(a0)
    800047ca:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047cc:	02f05563          	blez	a5,800047f6 <initlog+0x74>
    800047d0:	05c50713          	addi	a4,a0,92
    800047d4:	0001d697          	auipc	a3,0x1d
    800047d8:	2ec68693          	addi	a3,a3,748 # 80021ac0 <log+0x30>
    800047dc:	37fd                	addiw	a5,a5,-1
    800047de:	1782                	slli	a5,a5,0x20
    800047e0:	9381                	srli	a5,a5,0x20
    800047e2:	078a                	slli	a5,a5,0x2
    800047e4:	06050613          	addi	a2,a0,96
    800047e8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800047ea:	4310                	lw	a2,0(a4)
    800047ec:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800047ee:	0711                	addi	a4,a4,4
    800047f0:	0691                	addi	a3,a3,4
    800047f2:	fef71ce3          	bne	a4,a5,800047ea <initlog+0x68>
  brelse(buf);
    800047f6:	fffff097          	auipc	ra,0xfffff
    800047fa:	f8c080e7          	jalr	-116(ra) # 80003782 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047fe:	4505                	li	a0,1
    80004800:	00000097          	auipc	ra,0x0
    80004804:	ebe080e7          	jalr	-322(ra) # 800046be <install_trans>
  log.lh.n = 0;
    80004808:	0001d797          	auipc	a5,0x1d
    8000480c:	2a07aa23          	sw	zero,692(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    80004810:	00000097          	auipc	ra,0x0
    80004814:	e34080e7          	jalr	-460(ra) # 80004644 <write_head>
}
    80004818:	70a2                	ld	ra,40(sp)
    8000481a:	7402                	ld	s0,32(sp)
    8000481c:	64e2                	ld	s1,24(sp)
    8000481e:	6942                	ld	s2,16(sp)
    80004820:	69a2                	ld	s3,8(sp)
    80004822:	6145                	addi	sp,sp,48
    80004824:	8082                	ret

0000000080004826 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004826:	1101                	addi	sp,sp,-32
    80004828:	ec06                	sd	ra,24(sp)
    8000482a:	e822                	sd	s0,16(sp)
    8000482c:	e426                	sd	s1,8(sp)
    8000482e:	e04a                	sd	s2,0(sp)
    80004830:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004832:	0001d517          	auipc	a0,0x1d
    80004836:	25e50513          	addi	a0,a0,606 # 80021a90 <log>
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	3aa080e7          	jalr	938(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004842:	0001d497          	auipc	s1,0x1d
    80004846:	24e48493          	addi	s1,s1,590 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000484a:	4979                	li	s2,30
    8000484c:	a039                	j	8000485a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000484e:	85a6                	mv	a1,s1
    80004850:	8526                	mv	a0,s1
    80004852:	ffffe097          	auipc	ra,0xffffe
    80004856:	f06080e7          	jalr	-250(ra) # 80002758 <sleep>
    if(log.committing){
    8000485a:	50dc                	lw	a5,36(s1)
    8000485c:	fbed                	bnez	a5,8000484e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000485e:	509c                	lw	a5,32(s1)
    80004860:	0017871b          	addiw	a4,a5,1
    80004864:	0007069b          	sext.w	a3,a4
    80004868:	0027179b          	slliw	a5,a4,0x2
    8000486c:	9fb9                	addw	a5,a5,a4
    8000486e:	0017979b          	slliw	a5,a5,0x1
    80004872:	54d8                	lw	a4,44(s1)
    80004874:	9fb9                	addw	a5,a5,a4
    80004876:	00f95963          	bge	s2,a5,80004888 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000487a:	85a6                	mv	a1,s1
    8000487c:	8526                	mv	a0,s1
    8000487e:	ffffe097          	auipc	ra,0xffffe
    80004882:	eda080e7          	jalr	-294(ra) # 80002758 <sleep>
    80004886:	bfd1                	j	8000485a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004888:	0001d517          	auipc	a0,0x1d
    8000488c:	20850513          	addi	a0,a0,520 # 80021a90 <log>
    80004890:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004892:	ffffc097          	auipc	ra,0xffffc
    80004896:	406080e7          	jalr	1030(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000489a:	60e2                	ld	ra,24(sp)
    8000489c:	6442                	ld	s0,16(sp)
    8000489e:	64a2                	ld	s1,8(sp)
    800048a0:	6902                	ld	s2,0(sp)
    800048a2:	6105                	addi	sp,sp,32
    800048a4:	8082                	ret

00000000800048a6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800048a6:	7139                	addi	sp,sp,-64
    800048a8:	fc06                	sd	ra,56(sp)
    800048aa:	f822                	sd	s0,48(sp)
    800048ac:	f426                	sd	s1,40(sp)
    800048ae:	f04a                	sd	s2,32(sp)
    800048b0:	ec4e                	sd	s3,24(sp)
    800048b2:	e852                	sd	s4,16(sp)
    800048b4:	e456                	sd	s5,8(sp)
    800048b6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800048b8:	0001d497          	auipc	s1,0x1d
    800048bc:	1d848493          	addi	s1,s1,472 # 80021a90 <log>
    800048c0:	8526                	mv	a0,s1
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	322080e7          	jalr	802(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800048ca:	509c                	lw	a5,32(s1)
    800048cc:	37fd                	addiw	a5,a5,-1
    800048ce:	0007891b          	sext.w	s2,a5
    800048d2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048d4:	50dc                	lw	a5,36(s1)
    800048d6:	efb9                	bnez	a5,80004934 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048d8:	06091663          	bnez	s2,80004944 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800048dc:	0001d497          	auipc	s1,0x1d
    800048e0:	1b448493          	addi	s1,s1,436 # 80021a90 <log>
    800048e4:	4785                	li	a5,1
    800048e6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048e8:	8526                	mv	a0,s1
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	3ae080e7          	jalr	942(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048f2:	54dc                	lw	a5,44(s1)
    800048f4:	06f04763          	bgtz	a5,80004962 <end_op+0xbc>
    acquire(&log.lock);
    800048f8:	0001d497          	auipc	s1,0x1d
    800048fc:	19848493          	addi	s1,s1,408 # 80021a90 <log>
    80004900:	8526                	mv	a0,s1
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	2e2080e7          	jalr	738(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000490a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000490e:	8526                	mv	a0,s1
    80004910:	ffffe097          	auipc	ra,0xffffe
    80004914:	fde080e7          	jalr	-34(ra) # 800028ee <wakeup>
    release(&log.lock);
    80004918:	8526                	mv	a0,s1
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	37e080e7          	jalr	894(ra) # 80000c98 <release>
}
    80004922:	70e2                	ld	ra,56(sp)
    80004924:	7442                	ld	s0,48(sp)
    80004926:	74a2                	ld	s1,40(sp)
    80004928:	7902                	ld	s2,32(sp)
    8000492a:	69e2                	ld	s3,24(sp)
    8000492c:	6a42                	ld	s4,16(sp)
    8000492e:	6aa2                	ld	s5,8(sp)
    80004930:	6121                	addi	sp,sp,64
    80004932:	8082                	ret
    panic("log.committing");
    80004934:	00004517          	auipc	a0,0x4
    80004938:	dcc50513          	addi	a0,a0,-564 # 80008700 <syscalls+0x1f8>
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	c02080e7          	jalr	-1022(ra) # 8000053e <panic>
    wakeup(&log);
    80004944:	0001d497          	auipc	s1,0x1d
    80004948:	14c48493          	addi	s1,s1,332 # 80021a90 <log>
    8000494c:	8526                	mv	a0,s1
    8000494e:	ffffe097          	auipc	ra,0xffffe
    80004952:	fa0080e7          	jalr	-96(ra) # 800028ee <wakeup>
  release(&log.lock);
    80004956:	8526                	mv	a0,s1
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	340080e7          	jalr	832(ra) # 80000c98 <release>
  if(do_commit){
    80004960:	b7c9                	j	80004922 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004962:	0001da97          	auipc	s5,0x1d
    80004966:	15ea8a93          	addi	s5,s5,350 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000496a:	0001da17          	auipc	s4,0x1d
    8000496e:	126a0a13          	addi	s4,s4,294 # 80021a90 <log>
    80004972:	018a2583          	lw	a1,24(s4)
    80004976:	012585bb          	addw	a1,a1,s2
    8000497a:	2585                	addiw	a1,a1,1
    8000497c:	028a2503          	lw	a0,40(s4)
    80004980:	fffff097          	auipc	ra,0xfffff
    80004984:	cd2080e7          	jalr	-814(ra) # 80003652 <bread>
    80004988:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000498a:	000aa583          	lw	a1,0(s5)
    8000498e:	028a2503          	lw	a0,40(s4)
    80004992:	fffff097          	auipc	ra,0xfffff
    80004996:	cc0080e7          	jalr	-832(ra) # 80003652 <bread>
    8000499a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000499c:	40000613          	li	a2,1024
    800049a0:	05850593          	addi	a1,a0,88
    800049a4:	05848513          	addi	a0,s1,88
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	398080e7          	jalr	920(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800049b0:	8526                	mv	a0,s1
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	d92080e7          	jalr	-622(ra) # 80003744 <bwrite>
    brelse(from);
    800049ba:	854e                	mv	a0,s3
    800049bc:	fffff097          	auipc	ra,0xfffff
    800049c0:	dc6080e7          	jalr	-570(ra) # 80003782 <brelse>
    brelse(to);
    800049c4:	8526                	mv	a0,s1
    800049c6:	fffff097          	auipc	ra,0xfffff
    800049ca:	dbc080e7          	jalr	-580(ra) # 80003782 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049ce:	2905                	addiw	s2,s2,1
    800049d0:	0a91                	addi	s5,s5,4
    800049d2:	02ca2783          	lw	a5,44(s4)
    800049d6:	f8f94ee3          	blt	s2,a5,80004972 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049da:	00000097          	auipc	ra,0x0
    800049de:	c6a080e7          	jalr	-918(ra) # 80004644 <write_head>
    install_trans(0); // Now install writes to home locations
    800049e2:	4501                	li	a0,0
    800049e4:	00000097          	auipc	ra,0x0
    800049e8:	cda080e7          	jalr	-806(ra) # 800046be <install_trans>
    log.lh.n = 0;
    800049ec:	0001d797          	auipc	a5,0x1d
    800049f0:	0c07a823          	sw	zero,208(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049f4:	00000097          	auipc	ra,0x0
    800049f8:	c50080e7          	jalr	-944(ra) # 80004644 <write_head>
    800049fc:	bdf5                	j	800048f8 <end_op+0x52>

00000000800049fe <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049fe:	1101                	addi	sp,sp,-32
    80004a00:	ec06                	sd	ra,24(sp)
    80004a02:	e822                	sd	s0,16(sp)
    80004a04:	e426                	sd	s1,8(sp)
    80004a06:	e04a                	sd	s2,0(sp)
    80004a08:	1000                	addi	s0,sp,32
    80004a0a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a0c:	0001d917          	auipc	s2,0x1d
    80004a10:	08490913          	addi	s2,s2,132 # 80021a90 <log>
    80004a14:	854a                	mv	a0,s2
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	1ce080e7          	jalr	462(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a1e:	02c92603          	lw	a2,44(s2)
    80004a22:	47f5                	li	a5,29
    80004a24:	06c7c563          	blt	a5,a2,80004a8e <log_write+0x90>
    80004a28:	0001d797          	auipc	a5,0x1d
    80004a2c:	0847a783          	lw	a5,132(a5) # 80021aac <log+0x1c>
    80004a30:	37fd                	addiw	a5,a5,-1
    80004a32:	04f65e63          	bge	a2,a5,80004a8e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a36:	0001d797          	auipc	a5,0x1d
    80004a3a:	07a7a783          	lw	a5,122(a5) # 80021ab0 <log+0x20>
    80004a3e:	06f05063          	blez	a5,80004a9e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a42:	4781                	li	a5,0
    80004a44:	06c05563          	blez	a2,80004aae <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a48:	44cc                	lw	a1,12(s1)
    80004a4a:	0001d717          	auipc	a4,0x1d
    80004a4e:	07670713          	addi	a4,a4,118 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a52:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a54:	4314                	lw	a3,0(a4)
    80004a56:	04b68c63          	beq	a3,a1,80004aae <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a5a:	2785                	addiw	a5,a5,1
    80004a5c:	0711                	addi	a4,a4,4
    80004a5e:	fef61be3          	bne	a2,a5,80004a54 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a62:	0621                	addi	a2,a2,8
    80004a64:	060a                	slli	a2,a2,0x2
    80004a66:	0001d797          	auipc	a5,0x1d
    80004a6a:	02a78793          	addi	a5,a5,42 # 80021a90 <log>
    80004a6e:	963e                	add	a2,a2,a5
    80004a70:	44dc                	lw	a5,12(s1)
    80004a72:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a74:	8526                	mv	a0,s1
    80004a76:	fffff097          	auipc	ra,0xfffff
    80004a7a:	daa080e7          	jalr	-598(ra) # 80003820 <bpin>
    log.lh.n++;
    80004a7e:	0001d717          	auipc	a4,0x1d
    80004a82:	01270713          	addi	a4,a4,18 # 80021a90 <log>
    80004a86:	575c                	lw	a5,44(a4)
    80004a88:	2785                	addiw	a5,a5,1
    80004a8a:	d75c                	sw	a5,44(a4)
    80004a8c:	a835                	j	80004ac8 <log_write+0xca>
    panic("too big a transaction");
    80004a8e:	00004517          	auipc	a0,0x4
    80004a92:	c8250513          	addi	a0,a0,-894 # 80008710 <syscalls+0x208>
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	aa8080e7          	jalr	-1368(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a9e:	00004517          	auipc	a0,0x4
    80004aa2:	c8a50513          	addi	a0,a0,-886 # 80008728 <syscalls+0x220>
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	a98080e7          	jalr	-1384(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004aae:	00878713          	addi	a4,a5,8
    80004ab2:	00271693          	slli	a3,a4,0x2
    80004ab6:	0001d717          	auipc	a4,0x1d
    80004aba:	fda70713          	addi	a4,a4,-38 # 80021a90 <log>
    80004abe:	9736                	add	a4,a4,a3
    80004ac0:	44d4                	lw	a3,12(s1)
    80004ac2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004ac4:	faf608e3          	beq	a2,a5,80004a74 <log_write+0x76>
  }
  release(&log.lock);
    80004ac8:	0001d517          	auipc	a0,0x1d
    80004acc:	fc850513          	addi	a0,a0,-56 # 80021a90 <log>
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	1c8080e7          	jalr	456(ra) # 80000c98 <release>
}
    80004ad8:	60e2                	ld	ra,24(sp)
    80004ada:	6442                	ld	s0,16(sp)
    80004adc:	64a2                	ld	s1,8(sp)
    80004ade:	6902                	ld	s2,0(sp)
    80004ae0:	6105                	addi	sp,sp,32
    80004ae2:	8082                	ret

0000000080004ae4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ae4:	1101                	addi	sp,sp,-32
    80004ae6:	ec06                	sd	ra,24(sp)
    80004ae8:	e822                	sd	s0,16(sp)
    80004aea:	e426                	sd	s1,8(sp)
    80004aec:	e04a                	sd	s2,0(sp)
    80004aee:	1000                	addi	s0,sp,32
    80004af0:	84aa                	mv	s1,a0
    80004af2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004af4:	00004597          	auipc	a1,0x4
    80004af8:	c5458593          	addi	a1,a1,-940 # 80008748 <syscalls+0x240>
    80004afc:	0521                	addi	a0,a0,8
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	056080e7          	jalr	86(ra) # 80000b54 <initlock>
  lk->name = name;
    80004b06:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b0a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b0e:	0204a423          	sw	zero,40(s1)
}
    80004b12:	60e2                	ld	ra,24(sp)
    80004b14:	6442                	ld	s0,16(sp)
    80004b16:	64a2                	ld	s1,8(sp)
    80004b18:	6902                	ld	s2,0(sp)
    80004b1a:	6105                	addi	sp,sp,32
    80004b1c:	8082                	ret

0000000080004b1e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b1e:	1101                	addi	sp,sp,-32
    80004b20:	ec06                	sd	ra,24(sp)
    80004b22:	e822                	sd	s0,16(sp)
    80004b24:	e426                	sd	s1,8(sp)
    80004b26:	e04a                	sd	s2,0(sp)
    80004b28:	1000                	addi	s0,sp,32
    80004b2a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b2c:	00850913          	addi	s2,a0,8
    80004b30:	854a                	mv	a0,s2
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	0b2080e7          	jalr	178(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004b3a:	409c                	lw	a5,0(s1)
    80004b3c:	cb89                	beqz	a5,80004b4e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b3e:	85ca                	mv	a1,s2
    80004b40:	8526                	mv	a0,s1
    80004b42:	ffffe097          	auipc	ra,0xffffe
    80004b46:	c16080e7          	jalr	-1002(ra) # 80002758 <sleep>
  while (lk->locked) {
    80004b4a:	409c                	lw	a5,0(s1)
    80004b4c:	fbed                	bnez	a5,80004b3e <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b4e:	4785                	li	a5,1
    80004b50:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	0b6080e7          	jalr	182(ra) # 80001c08 <myproc>
    80004b5a:	591c                	lw	a5,48(a0)
    80004b5c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b5e:	854a                	mv	a0,s2
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	138080e7          	jalr	312(ra) # 80000c98 <release>
}
    80004b68:	60e2                	ld	ra,24(sp)
    80004b6a:	6442                	ld	s0,16(sp)
    80004b6c:	64a2                	ld	s1,8(sp)
    80004b6e:	6902                	ld	s2,0(sp)
    80004b70:	6105                	addi	sp,sp,32
    80004b72:	8082                	ret

0000000080004b74 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b74:	1101                	addi	sp,sp,-32
    80004b76:	ec06                	sd	ra,24(sp)
    80004b78:	e822                	sd	s0,16(sp)
    80004b7a:	e426                	sd	s1,8(sp)
    80004b7c:	e04a                	sd	s2,0(sp)
    80004b7e:	1000                	addi	s0,sp,32
    80004b80:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b82:	00850913          	addi	s2,a0,8
    80004b86:	854a                	mv	a0,s2
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	05c080e7          	jalr	92(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b90:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b94:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffe097          	auipc	ra,0xffffe
    80004b9e:	d54080e7          	jalr	-684(ra) # 800028ee <wakeup>
  release(&lk->lk);
    80004ba2:	854a                	mv	a0,s2
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	0f4080e7          	jalr	244(ra) # 80000c98 <release>
}
    80004bac:	60e2                	ld	ra,24(sp)
    80004bae:	6442                	ld	s0,16(sp)
    80004bb0:	64a2                	ld	s1,8(sp)
    80004bb2:	6902                	ld	s2,0(sp)
    80004bb4:	6105                	addi	sp,sp,32
    80004bb6:	8082                	ret

0000000080004bb8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004bb8:	7179                	addi	sp,sp,-48
    80004bba:	f406                	sd	ra,40(sp)
    80004bbc:	f022                	sd	s0,32(sp)
    80004bbe:	ec26                	sd	s1,24(sp)
    80004bc0:	e84a                	sd	s2,16(sp)
    80004bc2:	e44e                	sd	s3,8(sp)
    80004bc4:	1800                	addi	s0,sp,48
    80004bc6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004bc8:	00850913          	addi	s2,a0,8
    80004bcc:	854a                	mv	a0,s2
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	016080e7          	jalr	22(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bd6:	409c                	lw	a5,0(s1)
    80004bd8:	ef99                	bnez	a5,80004bf6 <holdingsleep+0x3e>
    80004bda:	4481                	li	s1,0
  release(&lk->lk);
    80004bdc:	854a                	mv	a0,s2
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	0ba080e7          	jalr	186(ra) # 80000c98 <release>
  return r;
}
    80004be6:	8526                	mv	a0,s1
    80004be8:	70a2                	ld	ra,40(sp)
    80004bea:	7402                	ld	s0,32(sp)
    80004bec:	64e2                	ld	s1,24(sp)
    80004bee:	6942                	ld	s2,16(sp)
    80004bf0:	69a2                	ld	s3,8(sp)
    80004bf2:	6145                	addi	sp,sp,48
    80004bf4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bf6:	0284a983          	lw	s3,40(s1)
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	00e080e7          	jalr	14(ra) # 80001c08 <myproc>
    80004c02:	5904                	lw	s1,48(a0)
    80004c04:	413484b3          	sub	s1,s1,s3
    80004c08:	0014b493          	seqz	s1,s1
    80004c0c:	bfc1                	j	80004bdc <holdingsleep+0x24>

0000000080004c0e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c0e:	1141                	addi	sp,sp,-16
    80004c10:	e406                	sd	ra,8(sp)
    80004c12:	e022                	sd	s0,0(sp)
    80004c14:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c16:	00004597          	auipc	a1,0x4
    80004c1a:	b4258593          	addi	a1,a1,-1214 # 80008758 <syscalls+0x250>
    80004c1e:	0001d517          	auipc	a0,0x1d
    80004c22:	fba50513          	addi	a0,a0,-70 # 80021bd8 <ftable>
    80004c26:	ffffc097          	auipc	ra,0xffffc
    80004c2a:	f2e080e7          	jalr	-210(ra) # 80000b54 <initlock>
}
    80004c2e:	60a2                	ld	ra,8(sp)
    80004c30:	6402                	ld	s0,0(sp)
    80004c32:	0141                	addi	sp,sp,16
    80004c34:	8082                	ret

0000000080004c36 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c36:	1101                	addi	sp,sp,-32
    80004c38:	ec06                	sd	ra,24(sp)
    80004c3a:	e822                	sd	s0,16(sp)
    80004c3c:	e426                	sd	s1,8(sp)
    80004c3e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c40:	0001d517          	auipc	a0,0x1d
    80004c44:	f9850513          	addi	a0,a0,-104 # 80021bd8 <ftable>
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	f9c080e7          	jalr	-100(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c50:	0001d497          	auipc	s1,0x1d
    80004c54:	fa048493          	addi	s1,s1,-96 # 80021bf0 <ftable+0x18>
    80004c58:	0001e717          	auipc	a4,0x1e
    80004c5c:	f3870713          	addi	a4,a4,-200 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004c60:	40dc                	lw	a5,4(s1)
    80004c62:	cf99                	beqz	a5,80004c80 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c64:	02848493          	addi	s1,s1,40
    80004c68:	fee49ce3          	bne	s1,a4,80004c60 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c6c:	0001d517          	auipc	a0,0x1d
    80004c70:	f6c50513          	addi	a0,a0,-148 # 80021bd8 <ftable>
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	024080e7          	jalr	36(ra) # 80000c98 <release>
  return 0;
    80004c7c:	4481                	li	s1,0
    80004c7e:	a819                	j	80004c94 <filealloc+0x5e>
      f->ref = 1;
    80004c80:	4785                	li	a5,1
    80004c82:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c84:	0001d517          	auipc	a0,0x1d
    80004c88:	f5450513          	addi	a0,a0,-172 # 80021bd8 <ftable>
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	00c080e7          	jalr	12(ra) # 80000c98 <release>
}
    80004c94:	8526                	mv	a0,s1
    80004c96:	60e2                	ld	ra,24(sp)
    80004c98:	6442                	ld	s0,16(sp)
    80004c9a:	64a2                	ld	s1,8(sp)
    80004c9c:	6105                	addi	sp,sp,32
    80004c9e:	8082                	ret

0000000080004ca0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ca0:	1101                	addi	sp,sp,-32
    80004ca2:	ec06                	sd	ra,24(sp)
    80004ca4:	e822                	sd	s0,16(sp)
    80004ca6:	e426                	sd	s1,8(sp)
    80004ca8:	1000                	addi	s0,sp,32
    80004caa:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004cac:	0001d517          	auipc	a0,0x1d
    80004cb0:	f2c50513          	addi	a0,a0,-212 # 80021bd8 <ftable>
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	f30080e7          	jalr	-208(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004cbc:	40dc                	lw	a5,4(s1)
    80004cbe:	02f05263          	blez	a5,80004ce2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004cc2:	2785                	addiw	a5,a5,1
    80004cc4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004cc6:	0001d517          	auipc	a0,0x1d
    80004cca:	f1250513          	addi	a0,a0,-238 # 80021bd8 <ftable>
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	fca080e7          	jalr	-54(ra) # 80000c98 <release>
  return f;
}
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	60e2                	ld	ra,24(sp)
    80004cda:	6442                	ld	s0,16(sp)
    80004cdc:	64a2                	ld	s1,8(sp)
    80004cde:	6105                	addi	sp,sp,32
    80004ce0:	8082                	ret
    panic("filedup");
    80004ce2:	00004517          	auipc	a0,0x4
    80004ce6:	a7e50513          	addi	a0,a0,-1410 # 80008760 <syscalls+0x258>
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>

0000000080004cf2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cf2:	7139                	addi	sp,sp,-64
    80004cf4:	fc06                	sd	ra,56(sp)
    80004cf6:	f822                	sd	s0,48(sp)
    80004cf8:	f426                	sd	s1,40(sp)
    80004cfa:	f04a                	sd	s2,32(sp)
    80004cfc:	ec4e                	sd	s3,24(sp)
    80004cfe:	e852                	sd	s4,16(sp)
    80004d00:	e456                	sd	s5,8(sp)
    80004d02:	0080                	addi	s0,sp,64
    80004d04:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d06:	0001d517          	auipc	a0,0x1d
    80004d0a:	ed250513          	addi	a0,a0,-302 # 80021bd8 <ftable>
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	ed6080e7          	jalr	-298(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004d16:	40dc                	lw	a5,4(s1)
    80004d18:	06f05163          	blez	a5,80004d7a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d1c:	37fd                	addiw	a5,a5,-1
    80004d1e:	0007871b          	sext.w	a4,a5
    80004d22:	c0dc                	sw	a5,4(s1)
    80004d24:	06e04363          	bgtz	a4,80004d8a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d28:	0004a903          	lw	s2,0(s1)
    80004d2c:	0094ca83          	lbu	s5,9(s1)
    80004d30:	0104ba03          	ld	s4,16(s1)
    80004d34:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d38:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d3c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d40:	0001d517          	auipc	a0,0x1d
    80004d44:	e9850513          	addi	a0,a0,-360 # 80021bd8 <ftable>
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	f50080e7          	jalr	-176(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004d50:	4785                	li	a5,1
    80004d52:	04f90d63          	beq	s2,a5,80004dac <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d56:	3979                	addiw	s2,s2,-2
    80004d58:	4785                	li	a5,1
    80004d5a:	0527e063          	bltu	a5,s2,80004d9a <fileclose+0xa8>
    begin_op();
    80004d5e:	00000097          	auipc	ra,0x0
    80004d62:	ac8080e7          	jalr	-1336(ra) # 80004826 <begin_op>
    iput(ff.ip);
    80004d66:	854e                	mv	a0,s3
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	2a6080e7          	jalr	678(ra) # 8000400e <iput>
    end_op();
    80004d70:	00000097          	auipc	ra,0x0
    80004d74:	b36080e7          	jalr	-1226(ra) # 800048a6 <end_op>
    80004d78:	a00d                	j	80004d9a <fileclose+0xa8>
    panic("fileclose");
    80004d7a:	00004517          	auipc	a0,0x4
    80004d7e:	9ee50513          	addi	a0,a0,-1554 # 80008768 <syscalls+0x260>
    80004d82:	ffffb097          	auipc	ra,0xffffb
    80004d86:	7bc080e7          	jalr	1980(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d8a:	0001d517          	auipc	a0,0x1d
    80004d8e:	e4e50513          	addi	a0,a0,-434 # 80021bd8 <ftable>
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	f06080e7          	jalr	-250(ra) # 80000c98 <release>
  }
}
    80004d9a:	70e2                	ld	ra,56(sp)
    80004d9c:	7442                	ld	s0,48(sp)
    80004d9e:	74a2                	ld	s1,40(sp)
    80004da0:	7902                	ld	s2,32(sp)
    80004da2:	69e2                	ld	s3,24(sp)
    80004da4:	6a42                	ld	s4,16(sp)
    80004da6:	6aa2                	ld	s5,8(sp)
    80004da8:	6121                	addi	sp,sp,64
    80004daa:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004dac:	85d6                	mv	a1,s5
    80004dae:	8552                	mv	a0,s4
    80004db0:	00000097          	auipc	ra,0x0
    80004db4:	34c080e7          	jalr	844(ra) # 800050fc <pipeclose>
    80004db8:	b7cd                	j	80004d9a <fileclose+0xa8>

0000000080004dba <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004dba:	715d                	addi	sp,sp,-80
    80004dbc:	e486                	sd	ra,72(sp)
    80004dbe:	e0a2                	sd	s0,64(sp)
    80004dc0:	fc26                	sd	s1,56(sp)
    80004dc2:	f84a                	sd	s2,48(sp)
    80004dc4:	f44e                	sd	s3,40(sp)
    80004dc6:	0880                	addi	s0,sp,80
    80004dc8:	84aa                	mv	s1,a0
    80004dca:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	e3c080e7          	jalr	-452(ra) # 80001c08 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004dd4:	409c                	lw	a5,0(s1)
    80004dd6:	37f9                	addiw	a5,a5,-2
    80004dd8:	4705                	li	a4,1
    80004dda:	04f76763          	bltu	a4,a5,80004e28 <filestat+0x6e>
    80004dde:	892a                	mv	s2,a0
    ilock(f->ip);
    80004de0:	6c88                	ld	a0,24(s1)
    80004de2:	fffff097          	auipc	ra,0xfffff
    80004de6:	072080e7          	jalr	114(ra) # 80003e54 <ilock>
    stati(f->ip, &st);
    80004dea:	fb840593          	addi	a1,s0,-72
    80004dee:	6c88                	ld	a0,24(s1)
    80004df0:	fffff097          	auipc	ra,0xfffff
    80004df4:	2ee080e7          	jalr	750(ra) # 800040de <stati>
    iunlock(f->ip);
    80004df8:	6c88                	ld	a0,24(s1)
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	11c080e7          	jalr	284(ra) # 80003f16 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e02:	46e1                	li	a3,24
    80004e04:	fb840613          	addi	a2,s0,-72
    80004e08:	85ce                	mv	a1,s3
    80004e0a:	07093503          	ld	a0,112(s2)
    80004e0e:	ffffd097          	auipc	ra,0xffffd
    80004e12:	988080e7          	jalr	-1656(ra) # 80001796 <copyout>
    80004e16:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e1a:	60a6                	ld	ra,72(sp)
    80004e1c:	6406                	ld	s0,64(sp)
    80004e1e:	74e2                	ld	s1,56(sp)
    80004e20:	7942                	ld	s2,48(sp)
    80004e22:	79a2                	ld	s3,40(sp)
    80004e24:	6161                	addi	sp,sp,80
    80004e26:	8082                	ret
  return -1;
    80004e28:	557d                	li	a0,-1
    80004e2a:	bfc5                	j	80004e1a <filestat+0x60>

0000000080004e2c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e2c:	7179                	addi	sp,sp,-48
    80004e2e:	f406                	sd	ra,40(sp)
    80004e30:	f022                	sd	s0,32(sp)
    80004e32:	ec26                	sd	s1,24(sp)
    80004e34:	e84a                	sd	s2,16(sp)
    80004e36:	e44e                	sd	s3,8(sp)
    80004e38:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e3a:	00854783          	lbu	a5,8(a0)
    80004e3e:	c3d5                	beqz	a5,80004ee2 <fileread+0xb6>
    80004e40:	84aa                	mv	s1,a0
    80004e42:	89ae                	mv	s3,a1
    80004e44:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e46:	411c                	lw	a5,0(a0)
    80004e48:	4705                	li	a4,1
    80004e4a:	04e78963          	beq	a5,a4,80004e9c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e4e:	470d                	li	a4,3
    80004e50:	04e78d63          	beq	a5,a4,80004eaa <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e54:	4709                	li	a4,2
    80004e56:	06e79e63          	bne	a5,a4,80004ed2 <fileread+0xa6>
    ilock(f->ip);
    80004e5a:	6d08                	ld	a0,24(a0)
    80004e5c:	fffff097          	auipc	ra,0xfffff
    80004e60:	ff8080e7          	jalr	-8(ra) # 80003e54 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e64:	874a                	mv	a4,s2
    80004e66:	5094                	lw	a3,32(s1)
    80004e68:	864e                	mv	a2,s3
    80004e6a:	4585                	li	a1,1
    80004e6c:	6c88                	ld	a0,24(s1)
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	29a080e7          	jalr	666(ra) # 80004108 <readi>
    80004e76:	892a                	mv	s2,a0
    80004e78:	00a05563          	blez	a0,80004e82 <fileread+0x56>
      f->off += r;
    80004e7c:	509c                	lw	a5,32(s1)
    80004e7e:	9fa9                	addw	a5,a5,a0
    80004e80:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e82:	6c88                	ld	a0,24(s1)
    80004e84:	fffff097          	auipc	ra,0xfffff
    80004e88:	092080e7          	jalr	146(ra) # 80003f16 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e8c:	854a                	mv	a0,s2
    80004e8e:	70a2                	ld	ra,40(sp)
    80004e90:	7402                	ld	s0,32(sp)
    80004e92:	64e2                	ld	s1,24(sp)
    80004e94:	6942                	ld	s2,16(sp)
    80004e96:	69a2                	ld	s3,8(sp)
    80004e98:	6145                	addi	sp,sp,48
    80004e9a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e9c:	6908                	ld	a0,16(a0)
    80004e9e:	00000097          	auipc	ra,0x0
    80004ea2:	3c8080e7          	jalr	968(ra) # 80005266 <piperead>
    80004ea6:	892a                	mv	s2,a0
    80004ea8:	b7d5                	j	80004e8c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004eaa:	02451783          	lh	a5,36(a0)
    80004eae:	03079693          	slli	a3,a5,0x30
    80004eb2:	92c1                	srli	a3,a3,0x30
    80004eb4:	4725                	li	a4,9
    80004eb6:	02d76863          	bltu	a4,a3,80004ee6 <fileread+0xba>
    80004eba:	0792                	slli	a5,a5,0x4
    80004ebc:	0001d717          	auipc	a4,0x1d
    80004ec0:	c7c70713          	addi	a4,a4,-900 # 80021b38 <devsw>
    80004ec4:	97ba                	add	a5,a5,a4
    80004ec6:	639c                	ld	a5,0(a5)
    80004ec8:	c38d                	beqz	a5,80004eea <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004eca:	4505                	li	a0,1
    80004ecc:	9782                	jalr	a5
    80004ece:	892a                	mv	s2,a0
    80004ed0:	bf75                	j	80004e8c <fileread+0x60>
    panic("fileread");
    80004ed2:	00004517          	auipc	a0,0x4
    80004ed6:	8a650513          	addi	a0,a0,-1882 # 80008778 <syscalls+0x270>
    80004eda:	ffffb097          	auipc	ra,0xffffb
    80004ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
    return -1;
    80004ee2:	597d                	li	s2,-1
    80004ee4:	b765                	j	80004e8c <fileread+0x60>
      return -1;
    80004ee6:	597d                	li	s2,-1
    80004ee8:	b755                	j	80004e8c <fileread+0x60>
    80004eea:	597d                	li	s2,-1
    80004eec:	b745                	j	80004e8c <fileread+0x60>

0000000080004eee <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004eee:	715d                	addi	sp,sp,-80
    80004ef0:	e486                	sd	ra,72(sp)
    80004ef2:	e0a2                	sd	s0,64(sp)
    80004ef4:	fc26                	sd	s1,56(sp)
    80004ef6:	f84a                	sd	s2,48(sp)
    80004ef8:	f44e                	sd	s3,40(sp)
    80004efa:	f052                	sd	s4,32(sp)
    80004efc:	ec56                	sd	s5,24(sp)
    80004efe:	e85a                	sd	s6,16(sp)
    80004f00:	e45e                	sd	s7,8(sp)
    80004f02:	e062                	sd	s8,0(sp)
    80004f04:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f06:	00954783          	lbu	a5,9(a0)
    80004f0a:	10078663          	beqz	a5,80005016 <filewrite+0x128>
    80004f0e:	892a                	mv	s2,a0
    80004f10:	8aae                	mv	s5,a1
    80004f12:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f14:	411c                	lw	a5,0(a0)
    80004f16:	4705                	li	a4,1
    80004f18:	02e78263          	beq	a5,a4,80004f3c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f1c:	470d                	li	a4,3
    80004f1e:	02e78663          	beq	a5,a4,80004f4a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f22:	4709                	li	a4,2
    80004f24:	0ee79163          	bne	a5,a4,80005006 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f28:	0ac05d63          	blez	a2,80004fe2 <filewrite+0xf4>
    int i = 0;
    80004f2c:	4981                	li	s3,0
    80004f2e:	6b05                	lui	s6,0x1
    80004f30:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f34:	6b85                	lui	s7,0x1
    80004f36:	c00b8b9b          	addiw	s7,s7,-1024
    80004f3a:	a861                	j	80004fd2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f3c:	6908                	ld	a0,16(a0)
    80004f3e:	00000097          	auipc	ra,0x0
    80004f42:	22e080e7          	jalr	558(ra) # 8000516c <pipewrite>
    80004f46:	8a2a                	mv	s4,a0
    80004f48:	a045                	j	80004fe8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f4a:	02451783          	lh	a5,36(a0)
    80004f4e:	03079693          	slli	a3,a5,0x30
    80004f52:	92c1                	srli	a3,a3,0x30
    80004f54:	4725                	li	a4,9
    80004f56:	0cd76263          	bltu	a4,a3,8000501a <filewrite+0x12c>
    80004f5a:	0792                	slli	a5,a5,0x4
    80004f5c:	0001d717          	auipc	a4,0x1d
    80004f60:	bdc70713          	addi	a4,a4,-1060 # 80021b38 <devsw>
    80004f64:	97ba                	add	a5,a5,a4
    80004f66:	679c                	ld	a5,8(a5)
    80004f68:	cbdd                	beqz	a5,8000501e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f6a:	4505                	li	a0,1
    80004f6c:	9782                	jalr	a5
    80004f6e:	8a2a                	mv	s4,a0
    80004f70:	a8a5                	j	80004fe8 <filewrite+0xfa>
    80004f72:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f76:	00000097          	auipc	ra,0x0
    80004f7a:	8b0080e7          	jalr	-1872(ra) # 80004826 <begin_op>
      ilock(f->ip);
    80004f7e:	01893503          	ld	a0,24(s2)
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	ed2080e7          	jalr	-302(ra) # 80003e54 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f8a:	8762                	mv	a4,s8
    80004f8c:	02092683          	lw	a3,32(s2)
    80004f90:	01598633          	add	a2,s3,s5
    80004f94:	4585                	li	a1,1
    80004f96:	01893503          	ld	a0,24(s2)
    80004f9a:	fffff097          	auipc	ra,0xfffff
    80004f9e:	266080e7          	jalr	614(ra) # 80004200 <writei>
    80004fa2:	84aa                	mv	s1,a0
    80004fa4:	00a05763          	blez	a0,80004fb2 <filewrite+0xc4>
        f->off += r;
    80004fa8:	02092783          	lw	a5,32(s2)
    80004fac:	9fa9                	addw	a5,a5,a0
    80004fae:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004fb2:	01893503          	ld	a0,24(s2)
    80004fb6:	fffff097          	auipc	ra,0xfffff
    80004fba:	f60080e7          	jalr	-160(ra) # 80003f16 <iunlock>
      end_op();
    80004fbe:	00000097          	auipc	ra,0x0
    80004fc2:	8e8080e7          	jalr	-1816(ra) # 800048a6 <end_op>

      if(r != n1){
    80004fc6:	009c1f63          	bne	s8,s1,80004fe4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004fca:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004fce:	0149db63          	bge	s3,s4,80004fe4 <filewrite+0xf6>
      int n1 = n - i;
    80004fd2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004fd6:	84be                	mv	s1,a5
    80004fd8:	2781                	sext.w	a5,a5
    80004fda:	f8fb5ce3          	bge	s6,a5,80004f72 <filewrite+0x84>
    80004fde:	84de                	mv	s1,s7
    80004fe0:	bf49                	j	80004f72 <filewrite+0x84>
    int i = 0;
    80004fe2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fe4:	013a1f63          	bne	s4,s3,80005002 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fe8:	8552                	mv	a0,s4
    80004fea:	60a6                	ld	ra,72(sp)
    80004fec:	6406                	ld	s0,64(sp)
    80004fee:	74e2                	ld	s1,56(sp)
    80004ff0:	7942                	ld	s2,48(sp)
    80004ff2:	79a2                	ld	s3,40(sp)
    80004ff4:	7a02                	ld	s4,32(sp)
    80004ff6:	6ae2                	ld	s5,24(sp)
    80004ff8:	6b42                	ld	s6,16(sp)
    80004ffa:	6ba2                	ld	s7,8(sp)
    80004ffc:	6c02                	ld	s8,0(sp)
    80004ffe:	6161                	addi	sp,sp,80
    80005000:	8082                	ret
    ret = (i == n ? n : -1);
    80005002:	5a7d                	li	s4,-1
    80005004:	b7d5                	j	80004fe8 <filewrite+0xfa>
    panic("filewrite");
    80005006:	00003517          	auipc	a0,0x3
    8000500a:	78250513          	addi	a0,a0,1922 # 80008788 <syscalls+0x280>
    8000500e:	ffffb097          	auipc	ra,0xffffb
    80005012:	530080e7          	jalr	1328(ra) # 8000053e <panic>
    return -1;
    80005016:	5a7d                	li	s4,-1
    80005018:	bfc1                	j	80004fe8 <filewrite+0xfa>
      return -1;
    8000501a:	5a7d                	li	s4,-1
    8000501c:	b7f1                	j	80004fe8 <filewrite+0xfa>
    8000501e:	5a7d                	li	s4,-1
    80005020:	b7e1                	j	80004fe8 <filewrite+0xfa>

0000000080005022 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005022:	7179                	addi	sp,sp,-48
    80005024:	f406                	sd	ra,40(sp)
    80005026:	f022                	sd	s0,32(sp)
    80005028:	ec26                	sd	s1,24(sp)
    8000502a:	e84a                	sd	s2,16(sp)
    8000502c:	e44e                	sd	s3,8(sp)
    8000502e:	e052                	sd	s4,0(sp)
    80005030:	1800                	addi	s0,sp,48
    80005032:	84aa                	mv	s1,a0
    80005034:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005036:	0005b023          	sd	zero,0(a1)
    8000503a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000503e:	00000097          	auipc	ra,0x0
    80005042:	bf8080e7          	jalr	-1032(ra) # 80004c36 <filealloc>
    80005046:	e088                	sd	a0,0(s1)
    80005048:	c551                	beqz	a0,800050d4 <pipealloc+0xb2>
    8000504a:	00000097          	auipc	ra,0x0
    8000504e:	bec080e7          	jalr	-1044(ra) # 80004c36 <filealloc>
    80005052:	00aa3023          	sd	a0,0(s4)
    80005056:	c92d                	beqz	a0,800050c8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	a9c080e7          	jalr	-1380(ra) # 80000af4 <kalloc>
    80005060:	892a                	mv	s2,a0
    80005062:	c125                	beqz	a0,800050c2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005064:	4985                	li	s3,1
    80005066:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000506a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000506e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005072:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005076:	00003597          	auipc	a1,0x3
    8000507a:	72258593          	addi	a1,a1,1826 # 80008798 <syscalls+0x290>
    8000507e:	ffffc097          	auipc	ra,0xffffc
    80005082:	ad6080e7          	jalr	-1322(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005086:	609c                	ld	a5,0(s1)
    80005088:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000508c:	609c                	ld	a5,0(s1)
    8000508e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005092:	609c                	ld	a5,0(s1)
    80005094:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005098:	609c                	ld	a5,0(s1)
    8000509a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000509e:	000a3783          	ld	a5,0(s4)
    800050a2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800050a6:	000a3783          	ld	a5,0(s4)
    800050aa:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800050ae:	000a3783          	ld	a5,0(s4)
    800050b2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800050b6:	000a3783          	ld	a5,0(s4)
    800050ba:	0127b823          	sd	s2,16(a5)
  return 0;
    800050be:	4501                	li	a0,0
    800050c0:	a025                	j	800050e8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800050c2:	6088                	ld	a0,0(s1)
    800050c4:	e501                	bnez	a0,800050cc <pipealloc+0xaa>
    800050c6:	a039                	j	800050d4 <pipealloc+0xb2>
    800050c8:	6088                	ld	a0,0(s1)
    800050ca:	c51d                	beqz	a0,800050f8 <pipealloc+0xd6>
    fileclose(*f0);
    800050cc:	00000097          	auipc	ra,0x0
    800050d0:	c26080e7          	jalr	-986(ra) # 80004cf2 <fileclose>
  if(*f1)
    800050d4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800050d8:	557d                	li	a0,-1
  if(*f1)
    800050da:	c799                	beqz	a5,800050e8 <pipealloc+0xc6>
    fileclose(*f1);
    800050dc:	853e                	mv	a0,a5
    800050de:	00000097          	auipc	ra,0x0
    800050e2:	c14080e7          	jalr	-1004(ra) # 80004cf2 <fileclose>
  return -1;
    800050e6:	557d                	li	a0,-1
}
    800050e8:	70a2                	ld	ra,40(sp)
    800050ea:	7402                	ld	s0,32(sp)
    800050ec:	64e2                	ld	s1,24(sp)
    800050ee:	6942                	ld	s2,16(sp)
    800050f0:	69a2                	ld	s3,8(sp)
    800050f2:	6a02                	ld	s4,0(sp)
    800050f4:	6145                	addi	sp,sp,48
    800050f6:	8082                	ret
  return -1;
    800050f8:	557d                	li	a0,-1
    800050fa:	b7fd                	j	800050e8 <pipealloc+0xc6>

00000000800050fc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050fc:	1101                	addi	sp,sp,-32
    800050fe:	ec06                	sd	ra,24(sp)
    80005100:	e822                	sd	s0,16(sp)
    80005102:	e426                	sd	s1,8(sp)
    80005104:	e04a                	sd	s2,0(sp)
    80005106:	1000                	addi	s0,sp,32
    80005108:	84aa                	mv	s1,a0
    8000510a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000510c:	ffffc097          	auipc	ra,0xffffc
    80005110:	ad8080e7          	jalr	-1320(ra) # 80000be4 <acquire>
  if(writable){
    80005114:	02090d63          	beqz	s2,8000514e <pipeclose+0x52>
    pi->writeopen = 0;
    80005118:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000511c:	21848513          	addi	a0,s1,536
    80005120:	ffffd097          	auipc	ra,0xffffd
    80005124:	7ce080e7          	jalr	1998(ra) # 800028ee <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005128:	2204b783          	ld	a5,544(s1)
    8000512c:	eb95                	bnez	a5,80005160 <pipeclose+0x64>
    release(&pi->lock);
    8000512e:	8526                	mv	a0,s1
    80005130:	ffffc097          	auipc	ra,0xffffc
    80005134:	b68080e7          	jalr	-1176(ra) # 80000c98 <release>
    kfree((char*)pi);
    80005138:	8526                	mv	a0,s1
    8000513a:	ffffc097          	auipc	ra,0xffffc
    8000513e:	8be080e7          	jalr	-1858(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005142:	60e2                	ld	ra,24(sp)
    80005144:	6442                	ld	s0,16(sp)
    80005146:	64a2                	ld	s1,8(sp)
    80005148:	6902                	ld	s2,0(sp)
    8000514a:	6105                	addi	sp,sp,32
    8000514c:	8082                	ret
    pi->readopen = 0;
    8000514e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005152:	21c48513          	addi	a0,s1,540
    80005156:	ffffd097          	auipc	ra,0xffffd
    8000515a:	798080e7          	jalr	1944(ra) # 800028ee <wakeup>
    8000515e:	b7e9                	j	80005128 <pipeclose+0x2c>
    release(&pi->lock);
    80005160:	8526                	mv	a0,s1
    80005162:	ffffc097          	auipc	ra,0xffffc
    80005166:	b36080e7          	jalr	-1226(ra) # 80000c98 <release>
}
    8000516a:	bfe1                	j	80005142 <pipeclose+0x46>

000000008000516c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000516c:	7159                	addi	sp,sp,-112
    8000516e:	f486                	sd	ra,104(sp)
    80005170:	f0a2                	sd	s0,96(sp)
    80005172:	eca6                	sd	s1,88(sp)
    80005174:	e8ca                	sd	s2,80(sp)
    80005176:	e4ce                	sd	s3,72(sp)
    80005178:	e0d2                	sd	s4,64(sp)
    8000517a:	fc56                	sd	s5,56(sp)
    8000517c:	f85a                	sd	s6,48(sp)
    8000517e:	f45e                	sd	s7,40(sp)
    80005180:	f062                	sd	s8,32(sp)
    80005182:	ec66                	sd	s9,24(sp)
    80005184:	1880                	addi	s0,sp,112
    80005186:	84aa                	mv	s1,a0
    80005188:	8aae                	mv	s5,a1
    8000518a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000518c:	ffffd097          	auipc	ra,0xffffd
    80005190:	a7c080e7          	jalr	-1412(ra) # 80001c08 <myproc>
    80005194:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005196:	8526                	mv	a0,s1
    80005198:	ffffc097          	auipc	ra,0xffffc
    8000519c:	a4c080e7          	jalr	-1460(ra) # 80000be4 <acquire>
  while(i < n){
    800051a0:	0d405163          	blez	s4,80005262 <pipewrite+0xf6>
    800051a4:	8ba6                	mv	s7,s1
  int i = 0;
    800051a6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051a8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800051aa:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800051ae:	21c48c13          	addi	s8,s1,540
    800051b2:	a08d                	j	80005214 <pipewrite+0xa8>
      release(&pi->lock);
    800051b4:	8526                	mv	a0,s1
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	ae2080e7          	jalr	-1310(ra) # 80000c98 <release>
      return -1;
    800051be:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800051c0:	854a                	mv	a0,s2
    800051c2:	70a6                	ld	ra,104(sp)
    800051c4:	7406                	ld	s0,96(sp)
    800051c6:	64e6                	ld	s1,88(sp)
    800051c8:	6946                	ld	s2,80(sp)
    800051ca:	69a6                	ld	s3,72(sp)
    800051cc:	6a06                	ld	s4,64(sp)
    800051ce:	7ae2                	ld	s5,56(sp)
    800051d0:	7b42                	ld	s6,48(sp)
    800051d2:	7ba2                	ld	s7,40(sp)
    800051d4:	7c02                	ld	s8,32(sp)
    800051d6:	6ce2                	ld	s9,24(sp)
    800051d8:	6165                	addi	sp,sp,112
    800051da:	8082                	ret
      wakeup(&pi->nread);
    800051dc:	8566                	mv	a0,s9
    800051de:	ffffd097          	auipc	ra,0xffffd
    800051e2:	710080e7          	jalr	1808(ra) # 800028ee <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051e6:	85de                	mv	a1,s7
    800051e8:	8562                	mv	a0,s8
    800051ea:	ffffd097          	auipc	ra,0xffffd
    800051ee:	56e080e7          	jalr	1390(ra) # 80002758 <sleep>
    800051f2:	a839                	j	80005210 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051f4:	21c4a783          	lw	a5,540(s1)
    800051f8:	0017871b          	addiw	a4,a5,1
    800051fc:	20e4ae23          	sw	a4,540(s1)
    80005200:	1ff7f793          	andi	a5,a5,511
    80005204:	97a6                	add	a5,a5,s1
    80005206:	f9f44703          	lbu	a4,-97(s0)
    8000520a:	00e78c23          	sb	a4,24(a5)
      i++;
    8000520e:	2905                	addiw	s2,s2,1
  while(i < n){
    80005210:	03495d63          	bge	s2,s4,8000524a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005214:	2204a783          	lw	a5,544(s1)
    80005218:	dfd1                	beqz	a5,800051b4 <pipewrite+0x48>
    8000521a:	0289a783          	lw	a5,40(s3)
    8000521e:	fbd9                	bnez	a5,800051b4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005220:	2184a783          	lw	a5,536(s1)
    80005224:	21c4a703          	lw	a4,540(s1)
    80005228:	2007879b          	addiw	a5,a5,512
    8000522c:	faf708e3          	beq	a4,a5,800051dc <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005230:	4685                	li	a3,1
    80005232:	01590633          	add	a2,s2,s5
    80005236:	f9f40593          	addi	a1,s0,-97
    8000523a:	0709b503          	ld	a0,112(s3)
    8000523e:	ffffc097          	auipc	ra,0xffffc
    80005242:	5e4080e7          	jalr	1508(ra) # 80001822 <copyin>
    80005246:	fb6517e3          	bne	a0,s6,800051f4 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000524a:	21848513          	addi	a0,s1,536
    8000524e:	ffffd097          	auipc	ra,0xffffd
    80005252:	6a0080e7          	jalr	1696(ra) # 800028ee <wakeup>
  release(&pi->lock);
    80005256:	8526                	mv	a0,s1
    80005258:	ffffc097          	auipc	ra,0xffffc
    8000525c:	a40080e7          	jalr	-1472(ra) # 80000c98 <release>
  return i;
    80005260:	b785                	j	800051c0 <pipewrite+0x54>
  int i = 0;
    80005262:	4901                	li	s2,0
    80005264:	b7dd                	j	8000524a <pipewrite+0xde>

0000000080005266 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005266:	715d                	addi	sp,sp,-80
    80005268:	e486                	sd	ra,72(sp)
    8000526a:	e0a2                	sd	s0,64(sp)
    8000526c:	fc26                	sd	s1,56(sp)
    8000526e:	f84a                	sd	s2,48(sp)
    80005270:	f44e                	sd	s3,40(sp)
    80005272:	f052                	sd	s4,32(sp)
    80005274:	ec56                	sd	s5,24(sp)
    80005276:	e85a                	sd	s6,16(sp)
    80005278:	0880                	addi	s0,sp,80
    8000527a:	84aa                	mv	s1,a0
    8000527c:	892e                	mv	s2,a1
    8000527e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005280:	ffffd097          	auipc	ra,0xffffd
    80005284:	988080e7          	jalr	-1656(ra) # 80001c08 <myproc>
    80005288:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000528a:	8b26                	mv	s6,s1
    8000528c:	8526                	mv	a0,s1
    8000528e:	ffffc097          	auipc	ra,0xffffc
    80005292:	956080e7          	jalr	-1706(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005296:	2184a703          	lw	a4,536(s1)
    8000529a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000529e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052a2:	02f71463          	bne	a4,a5,800052ca <piperead+0x64>
    800052a6:	2244a783          	lw	a5,548(s1)
    800052aa:	c385                	beqz	a5,800052ca <piperead+0x64>
    if(pr->killed){
    800052ac:	028a2783          	lw	a5,40(s4)
    800052b0:	ebc1                	bnez	a5,80005340 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052b2:	85da                	mv	a1,s6
    800052b4:	854e                	mv	a0,s3
    800052b6:	ffffd097          	auipc	ra,0xffffd
    800052ba:	4a2080e7          	jalr	1186(ra) # 80002758 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052be:	2184a703          	lw	a4,536(s1)
    800052c2:	21c4a783          	lw	a5,540(s1)
    800052c6:	fef700e3          	beq	a4,a5,800052a6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052ca:	09505263          	blez	s5,8000534e <piperead+0xe8>
    800052ce:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052d0:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800052d2:	2184a783          	lw	a5,536(s1)
    800052d6:	21c4a703          	lw	a4,540(s1)
    800052da:	02f70d63          	beq	a4,a5,80005314 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052de:	0017871b          	addiw	a4,a5,1
    800052e2:	20e4ac23          	sw	a4,536(s1)
    800052e6:	1ff7f793          	andi	a5,a5,511
    800052ea:	97a6                	add	a5,a5,s1
    800052ec:	0187c783          	lbu	a5,24(a5)
    800052f0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052f4:	4685                	li	a3,1
    800052f6:	fbf40613          	addi	a2,s0,-65
    800052fa:	85ca                	mv	a1,s2
    800052fc:	070a3503          	ld	a0,112(s4)
    80005300:	ffffc097          	auipc	ra,0xffffc
    80005304:	496080e7          	jalr	1174(ra) # 80001796 <copyout>
    80005308:	01650663          	beq	a0,s6,80005314 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000530c:	2985                	addiw	s3,s3,1
    8000530e:	0905                	addi	s2,s2,1
    80005310:	fd3a91e3          	bne	s5,s3,800052d2 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005314:	21c48513          	addi	a0,s1,540
    80005318:	ffffd097          	auipc	ra,0xffffd
    8000531c:	5d6080e7          	jalr	1494(ra) # 800028ee <wakeup>
  release(&pi->lock);
    80005320:	8526                	mv	a0,s1
    80005322:	ffffc097          	auipc	ra,0xffffc
    80005326:	976080e7          	jalr	-1674(ra) # 80000c98 <release>
  return i;
}
    8000532a:	854e                	mv	a0,s3
    8000532c:	60a6                	ld	ra,72(sp)
    8000532e:	6406                	ld	s0,64(sp)
    80005330:	74e2                	ld	s1,56(sp)
    80005332:	7942                	ld	s2,48(sp)
    80005334:	79a2                	ld	s3,40(sp)
    80005336:	7a02                	ld	s4,32(sp)
    80005338:	6ae2                	ld	s5,24(sp)
    8000533a:	6b42                	ld	s6,16(sp)
    8000533c:	6161                	addi	sp,sp,80
    8000533e:	8082                	ret
      release(&pi->lock);
    80005340:	8526                	mv	a0,s1
    80005342:	ffffc097          	auipc	ra,0xffffc
    80005346:	956080e7          	jalr	-1706(ra) # 80000c98 <release>
      return -1;
    8000534a:	59fd                	li	s3,-1
    8000534c:	bff9                	j	8000532a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000534e:	4981                	li	s3,0
    80005350:	b7d1                	j	80005314 <piperead+0xae>

0000000080005352 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005352:	df010113          	addi	sp,sp,-528
    80005356:	20113423          	sd	ra,520(sp)
    8000535a:	20813023          	sd	s0,512(sp)
    8000535e:	ffa6                	sd	s1,504(sp)
    80005360:	fbca                	sd	s2,496(sp)
    80005362:	f7ce                	sd	s3,488(sp)
    80005364:	f3d2                	sd	s4,480(sp)
    80005366:	efd6                	sd	s5,472(sp)
    80005368:	ebda                	sd	s6,464(sp)
    8000536a:	e7de                	sd	s7,456(sp)
    8000536c:	e3e2                	sd	s8,448(sp)
    8000536e:	ff66                	sd	s9,440(sp)
    80005370:	fb6a                	sd	s10,432(sp)
    80005372:	f76e                	sd	s11,424(sp)
    80005374:	0c00                	addi	s0,sp,528
    80005376:	84aa                	mv	s1,a0
    80005378:	dea43c23          	sd	a0,-520(s0)
    8000537c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005380:	ffffd097          	auipc	ra,0xffffd
    80005384:	888080e7          	jalr	-1912(ra) # 80001c08 <myproc>
    80005388:	892a                	mv	s2,a0

  begin_op();
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	49c080e7          	jalr	1180(ra) # 80004826 <begin_op>

  if((ip = namei(path)) == 0){
    80005392:	8526                	mv	a0,s1
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	276080e7          	jalr	630(ra) # 8000460a <namei>
    8000539c:	c92d                	beqz	a0,8000540e <exec+0xbc>
    8000539e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	ab4080e7          	jalr	-1356(ra) # 80003e54 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800053a8:	04000713          	li	a4,64
    800053ac:	4681                	li	a3,0
    800053ae:	e5040613          	addi	a2,s0,-432
    800053b2:	4581                	li	a1,0
    800053b4:	8526                	mv	a0,s1
    800053b6:	fffff097          	auipc	ra,0xfffff
    800053ba:	d52080e7          	jalr	-686(ra) # 80004108 <readi>
    800053be:	04000793          	li	a5,64
    800053c2:	00f51a63          	bne	a0,a5,800053d6 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800053c6:	e5042703          	lw	a4,-432(s0)
    800053ca:	464c47b7          	lui	a5,0x464c4
    800053ce:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053d2:	04f70463          	beq	a4,a5,8000541a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053d6:	8526                	mv	a0,s1
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	cde080e7          	jalr	-802(ra) # 800040b6 <iunlockput>
    end_op();
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	4c6080e7          	jalr	1222(ra) # 800048a6 <end_op>
  }
  return -1;
    800053e8:	557d                	li	a0,-1
}
    800053ea:	20813083          	ld	ra,520(sp)
    800053ee:	20013403          	ld	s0,512(sp)
    800053f2:	74fe                	ld	s1,504(sp)
    800053f4:	795e                	ld	s2,496(sp)
    800053f6:	79be                	ld	s3,488(sp)
    800053f8:	7a1e                	ld	s4,480(sp)
    800053fa:	6afe                	ld	s5,472(sp)
    800053fc:	6b5e                	ld	s6,464(sp)
    800053fe:	6bbe                	ld	s7,456(sp)
    80005400:	6c1e                	ld	s8,448(sp)
    80005402:	7cfa                	ld	s9,440(sp)
    80005404:	7d5a                	ld	s10,432(sp)
    80005406:	7dba                	ld	s11,424(sp)
    80005408:	21010113          	addi	sp,sp,528
    8000540c:	8082                	ret
    end_op();
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	498080e7          	jalr	1176(ra) # 800048a6 <end_op>
    return -1;
    80005416:	557d                	li	a0,-1
    80005418:	bfc9                	j	800053ea <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000541a:	854a                	mv	a0,s2
    8000541c:	ffffd097          	auipc	ra,0xffffd
    80005420:	8b0080e7          	jalr	-1872(ra) # 80001ccc <proc_pagetable>
    80005424:	8baa                	mv	s7,a0
    80005426:	d945                	beqz	a0,800053d6 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005428:	e7042983          	lw	s3,-400(s0)
    8000542c:	e8845783          	lhu	a5,-376(s0)
    80005430:	c7ad                	beqz	a5,8000549a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005432:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005434:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005436:	6c85                	lui	s9,0x1
    80005438:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000543c:	def43823          	sd	a5,-528(s0)
    80005440:	a42d                	j	8000566a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005442:	00003517          	auipc	a0,0x3
    80005446:	35e50513          	addi	a0,a0,862 # 800087a0 <syscalls+0x298>
    8000544a:	ffffb097          	auipc	ra,0xffffb
    8000544e:	0f4080e7          	jalr	244(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005452:	8756                	mv	a4,s5
    80005454:	012d86bb          	addw	a3,s11,s2
    80005458:	4581                	li	a1,0
    8000545a:	8526                	mv	a0,s1
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	cac080e7          	jalr	-852(ra) # 80004108 <readi>
    80005464:	2501                	sext.w	a0,a0
    80005466:	1aaa9963          	bne	s5,a0,80005618 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000546a:	6785                	lui	a5,0x1
    8000546c:	0127893b          	addw	s2,a5,s2
    80005470:	77fd                	lui	a5,0xfffff
    80005472:	01478a3b          	addw	s4,a5,s4
    80005476:	1f897163          	bgeu	s2,s8,80005658 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000547a:	02091593          	slli	a1,s2,0x20
    8000547e:	9181                	srli	a1,a1,0x20
    80005480:	95ea                	add	a1,a1,s10
    80005482:	855e                	mv	a0,s7
    80005484:	ffffc097          	auipc	ra,0xffffc
    80005488:	d0e080e7          	jalr	-754(ra) # 80001192 <walkaddr>
    8000548c:	862a                	mv	a2,a0
    if(pa == 0)
    8000548e:	d955                	beqz	a0,80005442 <exec+0xf0>
      n = PGSIZE;
    80005490:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005492:	fd9a70e3          	bgeu	s4,s9,80005452 <exec+0x100>
      n = sz - i;
    80005496:	8ad2                	mv	s5,s4
    80005498:	bf6d                	j	80005452 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000549a:	4901                	li	s2,0
  iunlockput(ip);
    8000549c:	8526                	mv	a0,s1
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	c18080e7          	jalr	-1000(ra) # 800040b6 <iunlockput>
  end_op();
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	400080e7          	jalr	1024(ra) # 800048a6 <end_op>
  p = myproc();
    800054ae:	ffffc097          	auipc	ra,0xffffc
    800054b2:	75a080e7          	jalr	1882(ra) # 80001c08 <myproc>
    800054b6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800054b8:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800054bc:	6785                	lui	a5,0x1
    800054be:	17fd                	addi	a5,a5,-1
    800054c0:	993e                	add	s2,s2,a5
    800054c2:	757d                	lui	a0,0xfffff
    800054c4:	00a977b3          	and	a5,s2,a0
    800054c8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054cc:	6609                	lui	a2,0x2
    800054ce:	963e                	add	a2,a2,a5
    800054d0:	85be                	mv	a1,a5
    800054d2:	855e                	mv	a0,s7
    800054d4:	ffffc097          	auipc	ra,0xffffc
    800054d8:	072080e7          	jalr	114(ra) # 80001546 <uvmalloc>
    800054dc:	8b2a                	mv	s6,a0
  ip = 0;
    800054de:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054e0:	12050c63          	beqz	a0,80005618 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054e4:	75f9                	lui	a1,0xffffe
    800054e6:	95aa                	add	a1,a1,a0
    800054e8:	855e                	mv	a0,s7
    800054ea:	ffffc097          	auipc	ra,0xffffc
    800054ee:	27a080e7          	jalr	634(ra) # 80001764 <uvmclear>
  stackbase = sp - PGSIZE;
    800054f2:	7c7d                	lui	s8,0xfffff
    800054f4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800054f6:	e0043783          	ld	a5,-512(s0)
    800054fa:	6388                	ld	a0,0(a5)
    800054fc:	c535                	beqz	a0,80005568 <exec+0x216>
    800054fe:	e9040993          	addi	s3,s0,-368
    80005502:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005506:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005508:	ffffc097          	auipc	ra,0xffffc
    8000550c:	95c080e7          	jalr	-1700(ra) # 80000e64 <strlen>
    80005510:	2505                	addiw	a0,a0,1
    80005512:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005516:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000551a:	13896363          	bltu	s2,s8,80005640 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000551e:	e0043d83          	ld	s11,-512(s0)
    80005522:	000dba03          	ld	s4,0(s11)
    80005526:	8552                	mv	a0,s4
    80005528:	ffffc097          	auipc	ra,0xffffc
    8000552c:	93c080e7          	jalr	-1732(ra) # 80000e64 <strlen>
    80005530:	0015069b          	addiw	a3,a0,1
    80005534:	8652                	mv	a2,s4
    80005536:	85ca                	mv	a1,s2
    80005538:	855e                	mv	a0,s7
    8000553a:	ffffc097          	auipc	ra,0xffffc
    8000553e:	25c080e7          	jalr	604(ra) # 80001796 <copyout>
    80005542:	10054363          	bltz	a0,80005648 <exec+0x2f6>
    ustack[argc] = sp;
    80005546:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000554a:	0485                	addi	s1,s1,1
    8000554c:	008d8793          	addi	a5,s11,8
    80005550:	e0f43023          	sd	a5,-512(s0)
    80005554:	008db503          	ld	a0,8(s11)
    80005558:	c911                	beqz	a0,8000556c <exec+0x21a>
    if(argc >= MAXARG)
    8000555a:	09a1                	addi	s3,s3,8
    8000555c:	fb3c96e3          	bne	s9,s3,80005508 <exec+0x1b6>
  sz = sz1;
    80005560:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005564:	4481                	li	s1,0
    80005566:	a84d                	j	80005618 <exec+0x2c6>
  sp = sz;
    80005568:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000556a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000556c:	00349793          	slli	a5,s1,0x3
    80005570:	f9040713          	addi	a4,s0,-112
    80005574:	97ba                	add	a5,a5,a4
    80005576:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000557a:	00148693          	addi	a3,s1,1
    8000557e:	068e                	slli	a3,a3,0x3
    80005580:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005584:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005588:	01897663          	bgeu	s2,s8,80005594 <exec+0x242>
  sz = sz1;
    8000558c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005590:	4481                	li	s1,0
    80005592:	a059                	j	80005618 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005594:	e9040613          	addi	a2,s0,-368
    80005598:	85ca                	mv	a1,s2
    8000559a:	855e                	mv	a0,s7
    8000559c:	ffffc097          	auipc	ra,0xffffc
    800055a0:	1fa080e7          	jalr	506(ra) # 80001796 <copyout>
    800055a4:	0a054663          	bltz	a0,80005650 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800055a8:	078ab783          	ld	a5,120(s5)
    800055ac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800055b0:	df843783          	ld	a5,-520(s0)
    800055b4:	0007c703          	lbu	a4,0(a5)
    800055b8:	cf11                	beqz	a4,800055d4 <exec+0x282>
    800055ba:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055bc:	02f00693          	li	a3,47
    800055c0:	a039                	j	800055ce <exec+0x27c>
      last = s+1;
    800055c2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055c6:	0785                	addi	a5,a5,1
    800055c8:	fff7c703          	lbu	a4,-1(a5)
    800055cc:	c701                	beqz	a4,800055d4 <exec+0x282>
    if(*s == '/')
    800055ce:	fed71ce3          	bne	a4,a3,800055c6 <exec+0x274>
    800055d2:	bfc5                	j	800055c2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800055d4:	4641                	li	a2,16
    800055d6:	df843583          	ld	a1,-520(s0)
    800055da:	178a8513          	addi	a0,s5,376
    800055de:	ffffc097          	auipc	ra,0xffffc
    800055e2:	854080e7          	jalr	-1964(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800055e6:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800055ea:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800055ee:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055f2:	078ab783          	ld	a5,120(s5)
    800055f6:	e6843703          	ld	a4,-408(s0)
    800055fa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055fc:	078ab783          	ld	a5,120(s5)
    80005600:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005604:	85ea                	mv	a1,s10
    80005606:	ffffc097          	auipc	ra,0xffffc
    8000560a:	762080e7          	jalr	1890(ra) # 80001d68 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000560e:	0004851b          	sext.w	a0,s1
    80005612:	bbe1                	j	800053ea <exec+0x98>
    80005614:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005618:	e0843583          	ld	a1,-504(s0)
    8000561c:	855e                	mv	a0,s7
    8000561e:	ffffc097          	auipc	ra,0xffffc
    80005622:	74a080e7          	jalr	1866(ra) # 80001d68 <proc_freepagetable>
  if(ip){
    80005626:	da0498e3          	bnez	s1,800053d6 <exec+0x84>
  return -1;
    8000562a:	557d                	li	a0,-1
    8000562c:	bb7d                	j	800053ea <exec+0x98>
    8000562e:	e1243423          	sd	s2,-504(s0)
    80005632:	b7dd                	j	80005618 <exec+0x2c6>
    80005634:	e1243423          	sd	s2,-504(s0)
    80005638:	b7c5                	j	80005618 <exec+0x2c6>
    8000563a:	e1243423          	sd	s2,-504(s0)
    8000563e:	bfe9                	j	80005618 <exec+0x2c6>
  sz = sz1;
    80005640:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005644:	4481                	li	s1,0
    80005646:	bfc9                	j	80005618 <exec+0x2c6>
  sz = sz1;
    80005648:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000564c:	4481                	li	s1,0
    8000564e:	b7e9                	j	80005618 <exec+0x2c6>
  sz = sz1;
    80005650:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005654:	4481                	li	s1,0
    80005656:	b7c9                	j	80005618 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005658:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000565c:	2b05                	addiw	s6,s6,1
    8000565e:	0389899b          	addiw	s3,s3,56
    80005662:	e8845783          	lhu	a5,-376(s0)
    80005666:	e2fb5be3          	bge	s6,a5,8000549c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000566a:	2981                	sext.w	s3,s3
    8000566c:	03800713          	li	a4,56
    80005670:	86ce                	mv	a3,s3
    80005672:	e1840613          	addi	a2,s0,-488
    80005676:	4581                	li	a1,0
    80005678:	8526                	mv	a0,s1
    8000567a:	fffff097          	auipc	ra,0xfffff
    8000567e:	a8e080e7          	jalr	-1394(ra) # 80004108 <readi>
    80005682:	03800793          	li	a5,56
    80005686:	f8f517e3          	bne	a0,a5,80005614 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000568a:	e1842783          	lw	a5,-488(s0)
    8000568e:	4705                	li	a4,1
    80005690:	fce796e3          	bne	a5,a4,8000565c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005694:	e4043603          	ld	a2,-448(s0)
    80005698:	e3843783          	ld	a5,-456(s0)
    8000569c:	f8f669e3          	bltu	a2,a5,8000562e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800056a0:	e2843783          	ld	a5,-472(s0)
    800056a4:	963e                	add	a2,a2,a5
    800056a6:	f8f667e3          	bltu	a2,a5,80005634 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056aa:	85ca                	mv	a1,s2
    800056ac:	855e                	mv	a0,s7
    800056ae:	ffffc097          	auipc	ra,0xffffc
    800056b2:	e98080e7          	jalr	-360(ra) # 80001546 <uvmalloc>
    800056b6:	e0a43423          	sd	a0,-504(s0)
    800056ba:	d141                	beqz	a0,8000563a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800056bc:	e2843d03          	ld	s10,-472(s0)
    800056c0:	df043783          	ld	a5,-528(s0)
    800056c4:	00fd77b3          	and	a5,s10,a5
    800056c8:	fba1                	bnez	a5,80005618 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056ca:	e2042d83          	lw	s11,-480(s0)
    800056ce:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056d2:	f80c03e3          	beqz	s8,80005658 <exec+0x306>
    800056d6:	8a62                	mv	s4,s8
    800056d8:	4901                	li	s2,0
    800056da:	b345                	j	8000547a <exec+0x128>

00000000800056dc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056dc:	7179                	addi	sp,sp,-48
    800056de:	f406                	sd	ra,40(sp)
    800056e0:	f022                	sd	s0,32(sp)
    800056e2:	ec26                	sd	s1,24(sp)
    800056e4:	e84a                	sd	s2,16(sp)
    800056e6:	1800                	addi	s0,sp,48
    800056e8:	892e                	mv	s2,a1
    800056ea:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056ec:	fdc40593          	addi	a1,s0,-36
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	b90080e7          	jalr	-1136(ra) # 80003280 <argint>
    800056f8:	04054063          	bltz	a0,80005738 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056fc:	fdc42703          	lw	a4,-36(s0)
    80005700:	47bd                	li	a5,15
    80005702:	02e7ed63          	bltu	a5,a4,8000573c <argfd+0x60>
    80005706:	ffffc097          	auipc	ra,0xffffc
    8000570a:	502080e7          	jalr	1282(ra) # 80001c08 <myproc>
    8000570e:	fdc42703          	lw	a4,-36(s0)
    80005712:	01e70793          	addi	a5,a4,30
    80005716:	078e                	slli	a5,a5,0x3
    80005718:	953e                	add	a0,a0,a5
    8000571a:	611c                	ld	a5,0(a0)
    8000571c:	c395                	beqz	a5,80005740 <argfd+0x64>
    return -1;
  if(pfd)
    8000571e:	00090463          	beqz	s2,80005726 <argfd+0x4a>
    *pfd = fd;
    80005722:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005726:	4501                	li	a0,0
  if(pf)
    80005728:	c091                	beqz	s1,8000572c <argfd+0x50>
    *pf = f;
    8000572a:	e09c                	sd	a5,0(s1)
}
    8000572c:	70a2                	ld	ra,40(sp)
    8000572e:	7402                	ld	s0,32(sp)
    80005730:	64e2                	ld	s1,24(sp)
    80005732:	6942                	ld	s2,16(sp)
    80005734:	6145                	addi	sp,sp,48
    80005736:	8082                	ret
    return -1;
    80005738:	557d                	li	a0,-1
    8000573a:	bfcd                	j	8000572c <argfd+0x50>
    return -1;
    8000573c:	557d                	li	a0,-1
    8000573e:	b7fd                	j	8000572c <argfd+0x50>
    80005740:	557d                	li	a0,-1
    80005742:	b7ed                	j	8000572c <argfd+0x50>

0000000080005744 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005744:	1101                	addi	sp,sp,-32
    80005746:	ec06                	sd	ra,24(sp)
    80005748:	e822                	sd	s0,16(sp)
    8000574a:	e426                	sd	s1,8(sp)
    8000574c:	1000                	addi	s0,sp,32
    8000574e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005750:	ffffc097          	auipc	ra,0xffffc
    80005754:	4b8080e7          	jalr	1208(ra) # 80001c08 <myproc>
    80005758:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000575a:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    8000575e:	4501                	li	a0,0
    80005760:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005762:	6398                	ld	a4,0(a5)
    80005764:	cb19                	beqz	a4,8000577a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005766:	2505                	addiw	a0,a0,1
    80005768:	07a1                	addi	a5,a5,8
    8000576a:	fed51ce3          	bne	a0,a3,80005762 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000576e:	557d                	li	a0,-1
}
    80005770:	60e2                	ld	ra,24(sp)
    80005772:	6442                	ld	s0,16(sp)
    80005774:	64a2                	ld	s1,8(sp)
    80005776:	6105                	addi	sp,sp,32
    80005778:	8082                	ret
      p->ofile[fd] = f;
    8000577a:	01e50793          	addi	a5,a0,30
    8000577e:	078e                	slli	a5,a5,0x3
    80005780:	963e                	add	a2,a2,a5
    80005782:	e204                	sd	s1,0(a2)
      return fd;
    80005784:	b7f5                	j	80005770 <fdalloc+0x2c>

0000000080005786 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005786:	715d                	addi	sp,sp,-80
    80005788:	e486                	sd	ra,72(sp)
    8000578a:	e0a2                	sd	s0,64(sp)
    8000578c:	fc26                	sd	s1,56(sp)
    8000578e:	f84a                	sd	s2,48(sp)
    80005790:	f44e                	sd	s3,40(sp)
    80005792:	f052                	sd	s4,32(sp)
    80005794:	ec56                	sd	s5,24(sp)
    80005796:	0880                	addi	s0,sp,80
    80005798:	89ae                	mv	s3,a1
    8000579a:	8ab2                	mv	s5,a2
    8000579c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000579e:	fb040593          	addi	a1,s0,-80
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	e86080e7          	jalr	-378(ra) # 80004628 <nameiparent>
    800057aa:	892a                	mv	s2,a0
    800057ac:	12050f63          	beqz	a0,800058ea <create+0x164>
    return 0;

  ilock(dp);
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	6a4080e7          	jalr	1700(ra) # 80003e54 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800057b8:	4601                	li	a2,0
    800057ba:	fb040593          	addi	a1,s0,-80
    800057be:	854a                	mv	a0,s2
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	b78080e7          	jalr	-1160(ra) # 80004338 <dirlookup>
    800057c8:	84aa                	mv	s1,a0
    800057ca:	c921                	beqz	a0,8000581a <create+0x94>
    iunlockput(dp);
    800057cc:	854a                	mv	a0,s2
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	8e8080e7          	jalr	-1816(ra) # 800040b6 <iunlockput>
    ilock(ip);
    800057d6:	8526                	mv	a0,s1
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	67c080e7          	jalr	1660(ra) # 80003e54 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057e0:	2981                	sext.w	s3,s3
    800057e2:	4789                	li	a5,2
    800057e4:	02f99463          	bne	s3,a5,8000580c <create+0x86>
    800057e8:	0444d783          	lhu	a5,68(s1)
    800057ec:	37f9                	addiw	a5,a5,-2
    800057ee:	17c2                	slli	a5,a5,0x30
    800057f0:	93c1                	srli	a5,a5,0x30
    800057f2:	4705                	li	a4,1
    800057f4:	00f76c63          	bltu	a4,a5,8000580c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800057f8:	8526                	mv	a0,s1
    800057fa:	60a6                	ld	ra,72(sp)
    800057fc:	6406                	ld	s0,64(sp)
    800057fe:	74e2                	ld	s1,56(sp)
    80005800:	7942                	ld	s2,48(sp)
    80005802:	79a2                	ld	s3,40(sp)
    80005804:	7a02                	ld	s4,32(sp)
    80005806:	6ae2                	ld	s5,24(sp)
    80005808:	6161                	addi	sp,sp,80
    8000580a:	8082                	ret
    iunlockput(ip);
    8000580c:	8526                	mv	a0,s1
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	8a8080e7          	jalr	-1880(ra) # 800040b6 <iunlockput>
    return 0;
    80005816:	4481                	li	s1,0
    80005818:	b7c5                	j	800057f8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000581a:	85ce                	mv	a1,s3
    8000581c:	00092503          	lw	a0,0(s2)
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	49c080e7          	jalr	1180(ra) # 80003cbc <ialloc>
    80005828:	84aa                	mv	s1,a0
    8000582a:	c529                	beqz	a0,80005874 <create+0xee>
  ilock(ip);
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	628080e7          	jalr	1576(ra) # 80003e54 <ilock>
  ip->major = major;
    80005834:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005838:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000583c:	4785                	li	a5,1
    8000583e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005842:	8526                	mv	a0,s1
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	546080e7          	jalr	1350(ra) # 80003d8a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000584c:	2981                	sext.w	s3,s3
    8000584e:	4785                	li	a5,1
    80005850:	02f98a63          	beq	s3,a5,80005884 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005854:	40d0                	lw	a2,4(s1)
    80005856:	fb040593          	addi	a1,s0,-80
    8000585a:	854a                	mv	a0,s2
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	cec080e7          	jalr	-788(ra) # 80004548 <dirlink>
    80005864:	06054b63          	bltz	a0,800058da <create+0x154>
  iunlockput(dp);
    80005868:	854a                	mv	a0,s2
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	84c080e7          	jalr	-1972(ra) # 800040b6 <iunlockput>
  return ip;
    80005872:	b759                	j	800057f8 <create+0x72>
    panic("create: ialloc");
    80005874:	00003517          	auipc	a0,0x3
    80005878:	f4c50513          	addi	a0,a0,-180 # 800087c0 <syscalls+0x2b8>
    8000587c:	ffffb097          	auipc	ra,0xffffb
    80005880:	cc2080e7          	jalr	-830(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005884:	04a95783          	lhu	a5,74(s2)
    80005888:	2785                	addiw	a5,a5,1
    8000588a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000588e:	854a                	mv	a0,s2
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	4fa080e7          	jalr	1274(ra) # 80003d8a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005898:	40d0                	lw	a2,4(s1)
    8000589a:	00003597          	auipc	a1,0x3
    8000589e:	f3658593          	addi	a1,a1,-202 # 800087d0 <syscalls+0x2c8>
    800058a2:	8526                	mv	a0,s1
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	ca4080e7          	jalr	-860(ra) # 80004548 <dirlink>
    800058ac:	00054f63          	bltz	a0,800058ca <create+0x144>
    800058b0:	00492603          	lw	a2,4(s2)
    800058b4:	00003597          	auipc	a1,0x3
    800058b8:	f2458593          	addi	a1,a1,-220 # 800087d8 <syscalls+0x2d0>
    800058bc:	8526                	mv	a0,s1
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	c8a080e7          	jalr	-886(ra) # 80004548 <dirlink>
    800058c6:	f80557e3          	bgez	a0,80005854 <create+0xce>
      panic("create dots");
    800058ca:	00003517          	auipc	a0,0x3
    800058ce:	f1650513          	addi	a0,a0,-234 # 800087e0 <syscalls+0x2d8>
    800058d2:	ffffb097          	auipc	ra,0xffffb
    800058d6:	c6c080e7          	jalr	-916(ra) # 8000053e <panic>
    panic("create: dirlink");
    800058da:	00003517          	auipc	a0,0x3
    800058de:	f1650513          	addi	a0,a0,-234 # 800087f0 <syscalls+0x2e8>
    800058e2:	ffffb097          	auipc	ra,0xffffb
    800058e6:	c5c080e7          	jalr	-932(ra) # 8000053e <panic>
    return 0;
    800058ea:	84aa                	mv	s1,a0
    800058ec:	b731                	j	800057f8 <create+0x72>

00000000800058ee <sys_dup>:
{
    800058ee:	7179                	addi	sp,sp,-48
    800058f0:	f406                	sd	ra,40(sp)
    800058f2:	f022                	sd	s0,32(sp)
    800058f4:	ec26                	sd	s1,24(sp)
    800058f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058f8:	fd840613          	addi	a2,s0,-40
    800058fc:	4581                	li	a1,0
    800058fe:	4501                	li	a0,0
    80005900:	00000097          	auipc	ra,0x0
    80005904:	ddc080e7          	jalr	-548(ra) # 800056dc <argfd>
    return -1;
    80005908:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000590a:	02054363          	bltz	a0,80005930 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000590e:	fd843503          	ld	a0,-40(s0)
    80005912:	00000097          	auipc	ra,0x0
    80005916:	e32080e7          	jalr	-462(ra) # 80005744 <fdalloc>
    8000591a:	84aa                	mv	s1,a0
    return -1;
    8000591c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000591e:	00054963          	bltz	a0,80005930 <sys_dup+0x42>
  filedup(f);
    80005922:	fd843503          	ld	a0,-40(s0)
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	37a080e7          	jalr	890(ra) # 80004ca0 <filedup>
  return fd;
    8000592e:	87a6                	mv	a5,s1
}
    80005930:	853e                	mv	a0,a5
    80005932:	70a2                	ld	ra,40(sp)
    80005934:	7402                	ld	s0,32(sp)
    80005936:	64e2                	ld	s1,24(sp)
    80005938:	6145                	addi	sp,sp,48
    8000593a:	8082                	ret

000000008000593c <sys_read>:
{
    8000593c:	7179                	addi	sp,sp,-48
    8000593e:	f406                	sd	ra,40(sp)
    80005940:	f022                	sd	s0,32(sp)
    80005942:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005944:	fe840613          	addi	a2,s0,-24
    80005948:	4581                	li	a1,0
    8000594a:	4501                	li	a0,0
    8000594c:	00000097          	auipc	ra,0x0
    80005950:	d90080e7          	jalr	-624(ra) # 800056dc <argfd>
    return -1;
    80005954:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005956:	04054163          	bltz	a0,80005998 <sys_read+0x5c>
    8000595a:	fe440593          	addi	a1,s0,-28
    8000595e:	4509                	li	a0,2
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	920080e7          	jalr	-1760(ra) # 80003280 <argint>
    return -1;
    80005968:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000596a:	02054763          	bltz	a0,80005998 <sys_read+0x5c>
    8000596e:	fd840593          	addi	a1,s0,-40
    80005972:	4505                	li	a0,1
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	92e080e7          	jalr	-1746(ra) # 800032a2 <argaddr>
    return -1;
    8000597c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000597e:	00054d63          	bltz	a0,80005998 <sys_read+0x5c>
  return fileread(f, p, n);
    80005982:	fe442603          	lw	a2,-28(s0)
    80005986:	fd843583          	ld	a1,-40(s0)
    8000598a:	fe843503          	ld	a0,-24(s0)
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	49e080e7          	jalr	1182(ra) # 80004e2c <fileread>
    80005996:	87aa                	mv	a5,a0
}
    80005998:	853e                	mv	a0,a5
    8000599a:	70a2                	ld	ra,40(sp)
    8000599c:	7402                	ld	s0,32(sp)
    8000599e:	6145                	addi	sp,sp,48
    800059a0:	8082                	ret

00000000800059a2 <sys_write>:
{
    800059a2:	7179                	addi	sp,sp,-48
    800059a4:	f406                	sd	ra,40(sp)
    800059a6:	f022                	sd	s0,32(sp)
    800059a8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059aa:	fe840613          	addi	a2,s0,-24
    800059ae:	4581                	li	a1,0
    800059b0:	4501                	li	a0,0
    800059b2:	00000097          	auipc	ra,0x0
    800059b6:	d2a080e7          	jalr	-726(ra) # 800056dc <argfd>
    return -1;
    800059ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059bc:	04054163          	bltz	a0,800059fe <sys_write+0x5c>
    800059c0:	fe440593          	addi	a1,s0,-28
    800059c4:	4509                	li	a0,2
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	8ba080e7          	jalr	-1862(ra) # 80003280 <argint>
    return -1;
    800059ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059d0:	02054763          	bltz	a0,800059fe <sys_write+0x5c>
    800059d4:	fd840593          	addi	a1,s0,-40
    800059d8:	4505                	li	a0,1
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	8c8080e7          	jalr	-1848(ra) # 800032a2 <argaddr>
    return -1;
    800059e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059e4:	00054d63          	bltz	a0,800059fe <sys_write+0x5c>
  return filewrite(f, p, n);
    800059e8:	fe442603          	lw	a2,-28(s0)
    800059ec:	fd843583          	ld	a1,-40(s0)
    800059f0:	fe843503          	ld	a0,-24(s0)
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	4fa080e7          	jalr	1274(ra) # 80004eee <filewrite>
    800059fc:	87aa                	mv	a5,a0
}
    800059fe:	853e                	mv	a0,a5
    80005a00:	70a2                	ld	ra,40(sp)
    80005a02:	7402                	ld	s0,32(sp)
    80005a04:	6145                	addi	sp,sp,48
    80005a06:	8082                	ret

0000000080005a08 <sys_close>:
{
    80005a08:	1101                	addi	sp,sp,-32
    80005a0a:	ec06                	sd	ra,24(sp)
    80005a0c:	e822                	sd	s0,16(sp)
    80005a0e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a10:	fe040613          	addi	a2,s0,-32
    80005a14:	fec40593          	addi	a1,s0,-20
    80005a18:	4501                	li	a0,0
    80005a1a:	00000097          	auipc	ra,0x0
    80005a1e:	cc2080e7          	jalr	-830(ra) # 800056dc <argfd>
    return -1;
    80005a22:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a24:	02054463          	bltz	a0,80005a4c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a28:	ffffc097          	auipc	ra,0xffffc
    80005a2c:	1e0080e7          	jalr	480(ra) # 80001c08 <myproc>
    80005a30:	fec42783          	lw	a5,-20(s0)
    80005a34:	07f9                	addi	a5,a5,30
    80005a36:	078e                	slli	a5,a5,0x3
    80005a38:	97aa                	add	a5,a5,a0
    80005a3a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a3e:	fe043503          	ld	a0,-32(s0)
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	2b0080e7          	jalr	688(ra) # 80004cf2 <fileclose>
  return 0;
    80005a4a:	4781                	li	a5,0
}
    80005a4c:	853e                	mv	a0,a5
    80005a4e:	60e2                	ld	ra,24(sp)
    80005a50:	6442                	ld	s0,16(sp)
    80005a52:	6105                	addi	sp,sp,32
    80005a54:	8082                	ret

0000000080005a56 <sys_fstat>:
{
    80005a56:	1101                	addi	sp,sp,-32
    80005a58:	ec06                	sd	ra,24(sp)
    80005a5a:	e822                	sd	s0,16(sp)
    80005a5c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a5e:	fe840613          	addi	a2,s0,-24
    80005a62:	4581                	li	a1,0
    80005a64:	4501                	li	a0,0
    80005a66:	00000097          	auipc	ra,0x0
    80005a6a:	c76080e7          	jalr	-906(ra) # 800056dc <argfd>
    return -1;
    80005a6e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a70:	02054563          	bltz	a0,80005a9a <sys_fstat+0x44>
    80005a74:	fe040593          	addi	a1,s0,-32
    80005a78:	4505                	li	a0,1
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	828080e7          	jalr	-2008(ra) # 800032a2 <argaddr>
    return -1;
    80005a82:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a84:	00054b63          	bltz	a0,80005a9a <sys_fstat+0x44>
  return filestat(f, st);
    80005a88:	fe043583          	ld	a1,-32(s0)
    80005a8c:	fe843503          	ld	a0,-24(s0)
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	32a080e7          	jalr	810(ra) # 80004dba <filestat>
    80005a98:	87aa                	mv	a5,a0
}
    80005a9a:	853e                	mv	a0,a5
    80005a9c:	60e2                	ld	ra,24(sp)
    80005a9e:	6442                	ld	s0,16(sp)
    80005aa0:	6105                	addi	sp,sp,32
    80005aa2:	8082                	ret

0000000080005aa4 <sys_link>:
{
    80005aa4:	7169                	addi	sp,sp,-304
    80005aa6:	f606                	sd	ra,296(sp)
    80005aa8:	f222                	sd	s0,288(sp)
    80005aaa:	ee26                	sd	s1,280(sp)
    80005aac:	ea4a                	sd	s2,272(sp)
    80005aae:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ab0:	08000613          	li	a2,128
    80005ab4:	ed040593          	addi	a1,s0,-304
    80005ab8:	4501                	li	a0,0
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	80a080e7          	jalr	-2038(ra) # 800032c4 <argstr>
    return -1;
    80005ac2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ac4:	10054e63          	bltz	a0,80005be0 <sys_link+0x13c>
    80005ac8:	08000613          	li	a2,128
    80005acc:	f5040593          	addi	a1,s0,-176
    80005ad0:	4505                	li	a0,1
    80005ad2:	ffffd097          	auipc	ra,0xffffd
    80005ad6:	7f2080e7          	jalr	2034(ra) # 800032c4 <argstr>
    return -1;
    80005ada:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005adc:	10054263          	bltz	a0,80005be0 <sys_link+0x13c>
  begin_op();
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	d46080e7          	jalr	-698(ra) # 80004826 <begin_op>
  if((ip = namei(old)) == 0){
    80005ae8:	ed040513          	addi	a0,s0,-304
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	b1e080e7          	jalr	-1250(ra) # 8000460a <namei>
    80005af4:	84aa                	mv	s1,a0
    80005af6:	c551                	beqz	a0,80005b82 <sys_link+0xde>
  ilock(ip);
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	35c080e7          	jalr	860(ra) # 80003e54 <ilock>
  if(ip->type == T_DIR){
    80005b00:	04449703          	lh	a4,68(s1)
    80005b04:	4785                	li	a5,1
    80005b06:	08f70463          	beq	a4,a5,80005b8e <sys_link+0xea>
  ip->nlink++;
    80005b0a:	04a4d783          	lhu	a5,74(s1)
    80005b0e:	2785                	addiw	a5,a5,1
    80005b10:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b14:	8526                	mv	a0,s1
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	274080e7          	jalr	628(ra) # 80003d8a <iupdate>
  iunlock(ip);
    80005b1e:	8526                	mv	a0,s1
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	3f6080e7          	jalr	1014(ra) # 80003f16 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b28:	fd040593          	addi	a1,s0,-48
    80005b2c:	f5040513          	addi	a0,s0,-176
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	af8080e7          	jalr	-1288(ra) # 80004628 <nameiparent>
    80005b38:	892a                	mv	s2,a0
    80005b3a:	c935                	beqz	a0,80005bae <sys_link+0x10a>
  ilock(dp);
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	318080e7          	jalr	792(ra) # 80003e54 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b44:	00092703          	lw	a4,0(s2)
    80005b48:	409c                	lw	a5,0(s1)
    80005b4a:	04f71d63          	bne	a4,a5,80005ba4 <sys_link+0x100>
    80005b4e:	40d0                	lw	a2,4(s1)
    80005b50:	fd040593          	addi	a1,s0,-48
    80005b54:	854a                	mv	a0,s2
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	9f2080e7          	jalr	-1550(ra) # 80004548 <dirlink>
    80005b5e:	04054363          	bltz	a0,80005ba4 <sys_link+0x100>
  iunlockput(dp);
    80005b62:	854a                	mv	a0,s2
    80005b64:	ffffe097          	auipc	ra,0xffffe
    80005b68:	552080e7          	jalr	1362(ra) # 800040b6 <iunlockput>
  iput(ip);
    80005b6c:	8526                	mv	a0,s1
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	4a0080e7          	jalr	1184(ra) # 8000400e <iput>
  end_op();
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	d30080e7          	jalr	-720(ra) # 800048a6 <end_op>
  return 0;
    80005b7e:	4781                	li	a5,0
    80005b80:	a085                	j	80005be0 <sys_link+0x13c>
    end_op();
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	d24080e7          	jalr	-732(ra) # 800048a6 <end_op>
    return -1;
    80005b8a:	57fd                	li	a5,-1
    80005b8c:	a891                	j	80005be0 <sys_link+0x13c>
    iunlockput(ip);
    80005b8e:	8526                	mv	a0,s1
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	526080e7          	jalr	1318(ra) # 800040b6 <iunlockput>
    end_op();
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	d0e080e7          	jalr	-754(ra) # 800048a6 <end_op>
    return -1;
    80005ba0:	57fd                	li	a5,-1
    80005ba2:	a83d                	j	80005be0 <sys_link+0x13c>
    iunlockput(dp);
    80005ba4:	854a                	mv	a0,s2
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	510080e7          	jalr	1296(ra) # 800040b6 <iunlockput>
  ilock(ip);
    80005bae:	8526                	mv	a0,s1
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	2a4080e7          	jalr	676(ra) # 80003e54 <ilock>
  ip->nlink--;
    80005bb8:	04a4d783          	lhu	a5,74(s1)
    80005bbc:	37fd                	addiw	a5,a5,-1
    80005bbe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bc2:	8526                	mv	a0,s1
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	1c6080e7          	jalr	454(ra) # 80003d8a <iupdate>
  iunlockput(ip);
    80005bcc:	8526                	mv	a0,s1
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	4e8080e7          	jalr	1256(ra) # 800040b6 <iunlockput>
  end_op();
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	cd0080e7          	jalr	-816(ra) # 800048a6 <end_op>
  return -1;
    80005bde:	57fd                	li	a5,-1
}
    80005be0:	853e                	mv	a0,a5
    80005be2:	70b2                	ld	ra,296(sp)
    80005be4:	7412                	ld	s0,288(sp)
    80005be6:	64f2                	ld	s1,280(sp)
    80005be8:	6952                	ld	s2,272(sp)
    80005bea:	6155                	addi	sp,sp,304
    80005bec:	8082                	ret

0000000080005bee <sys_unlink>:
{
    80005bee:	7151                	addi	sp,sp,-240
    80005bf0:	f586                	sd	ra,232(sp)
    80005bf2:	f1a2                	sd	s0,224(sp)
    80005bf4:	eda6                	sd	s1,216(sp)
    80005bf6:	e9ca                	sd	s2,208(sp)
    80005bf8:	e5ce                	sd	s3,200(sp)
    80005bfa:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005bfc:	08000613          	li	a2,128
    80005c00:	f3040593          	addi	a1,s0,-208
    80005c04:	4501                	li	a0,0
    80005c06:	ffffd097          	auipc	ra,0xffffd
    80005c0a:	6be080e7          	jalr	1726(ra) # 800032c4 <argstr>
    80005c0e:	18054163          	bltz	a0,80005d90 <sys_unlink+0x1a2>
  begin_op();
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	c14080e7          	jalr	-1004(ra) # 80004826 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c1a:	fb040593          	addi	a1,s0,-80
    80005c1e:	f3040513          	addi	a0,s0,-208
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	a06080e7          	jalr	-1530(ra) # 80004628 <nameiparent>
    80005c2a:	84aa                	mv	s1,a0
    80005c2c:	c979                	beqz	a0,80005d02 <sys_unlink+0x114>
  ilock(dp);
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	226080e7          	jalr	550(ra) # 80003e54 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c36:	00003597          	auipc	a1,0x3
    80005c3a:	b9a58593          	addi	a1,a1,-1126 # 800087d0 <syscalls+0x2c8>
    80005c3e:	fb040513          	addi	a0,s0,-80
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	6dc080e7          	jalr	1756(ra) # 8000431e <namecmp>
    80005c4a:	14050a63          	beqz	a0,80005d9e <sys_unlink+0x1b0>
    80005c4e:	00003597          	auipc	a1,0x3
    80005c52:	b8a58593          	addi	a1,a1,-1142 # 800087d8 <syscalls+0x2d0>
    80005c56:	fb040513          	addi	a0,s0,-80
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	6c4080e7          	jalr	1732(ra) # 8000431e <namecmp>
    80005c62:	12050e63          	beqz	a0,80005d9e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c66:	f2c40613          	addi	a2,s0,-212
    80005c6a:	fb040593          	addi	a1,s0,-80
    80005c6e:	8526                	mv	a0,s1
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	6c8080e7          	jalr	1736(ra) # 80004338 <dirlookup>
    80005c78:	892a                	mv	s2,a0
    80005c7a:	12050263          	beqz	a0,80005d9e <sys_unlink+0x1b0>
  ilock(ip);
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	1d6080e7          	jalr	470(ra) # 80003e54 <ilock>
  if(ip->nlink < 1)
    80005c86:	04a91783          	lh	a5,74(s2)
    80005c8a:	08f05263          	blez	a5,80005d0e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c8e:	04491703          	lh	a4,68(s2)
    80005c92:	4785                	li	a5,1
    80005c94:	08f70563          	beq	a4,a5,80005d1e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c98:	4641                	li	a2,16
    80005c9a:	4581                	li	a1,0
    80005c9c:	fc040513          	addi	a0,s0,-64
    80005ca0:	ffffb097          	auipc	ra,0xffffb
    80005ca4:	040080e7          	jalr	64(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ca8:	4741                	li	a4,16
    80005caa:	f2c42683          	lw	a3,-212(s0)
    80005cae:	fc040613          	addi	a2,s0,-64
    80005cb2:	4581                	li	a1,0
    80005cb4:	8526                	mv	a0,s1
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	54a080e7          	jalr	1354(ra) # 80004200 <writei>
    80005cbe:	47c1                	li	a5,16
    80005cc0:	0af51563          	bne	a0,a5,80005d6a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005cc4:	04491703          	lh	a4,68(s2)
    80005cc8:	4785                	li	a5,1
    80005cca:	0af70863          	beq	a4,a5,80005d7a <sys_unlink+0x18c>
  iunlockput(dp);
    80005cce:	8526                	mv	a0,s1
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	3e6080e7          	jalr	998(ra) # 800040b6 <iunlockput>
  ip->nlink--;
    80005cd8:	04a95783          	lhu	a5,74(s2)
    80005cdc:	37fd                	addiw	a5,a5,-1
    80005cde:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ce2:	854a                	mv	a0,s2
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	0a6080e7          	jalr	166(ra) # 80003d8a <iupdate>
  iunlockput(ip);
    80005cec:	854a                	mv	a0,s2
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	3c8080e7          	jalr	968(ra) # 800040b6 <iunlockput>
  end_op();
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	bb0080e7          	jalr	-1104(ra) # 800048a6 <end_op>
  return 0;
    80005cfe:	4501                	li	a0,0
    80005d00:	a84d                	j	80005db2 <sys_unlink+0x1c4>
    end_op();
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	ba4080e7          	jalr	-1116(ra) # 800048a6 <end_op>
    return -1;
    80005d0a:	557d                	li	a0,-1
    80005d0c:	a05d                	j	80005db2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d0e:	00003517          	auipc	a0,0x3
    80005d12:	af250513          	addi	a0,a0,-1294 # 80008800 <syscalls+0x2f8>
    80005d16:	ffffb097          	auipc	ra,0xffffb
    80005d1a:	828080e7          	jalr	-2008(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d1e:	04c92703          	lw	a4,76(s2)
    80005d22:	02000793          	li	a5,32
    80005d26:	f6e7f9e3          	bgeu	a5,a4,80005c98 <sys_unlink+0xaa>
    80005d2a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d2e:	4741                	li	a4,16
    80005d30:	86ce                	mv	a3,s3
    80005d32:	f1840613          	addi	a2,s0,-232
    80005d36:	4581                	li	a1,0
    80005d38:	854a                	mv	a0,s2
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	3ce080e7          	jalr	974(ra) # 80004108 <readi>
    80005d42:	47c1                	li	a5,16
    80005d44:	00f51b63          	bne	a0,a5,80005d5a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d48:	f1845783          	lhu	a5,-232(s0)
    80005d4c:	e7a1                	bnez	a5,80005d94 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d4e:	29c1                	addiw	s3,s3,16
    80005d50:	04c92783          	lw	a5,76(s2)
    80005d54:	fcf9ede3          	bltu	s3,a5,80005d2e <sys_unlink+0x140>
    80005d58:	b781                	j	80005c98 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d5a:	00003517          	auipc	a0,0x3
    80005d5e:	abe50513          	addi	a0,a0,-1346 # 80008818 <syscalls+0x310>
    80005d62:	ffffa097          	auipc	ra,0xffffa
    80005d66:	7dc080e7          	jalr	2012(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d6a:	00003517          	auipc	a0,0x3
    80005d6e:	ac650513          	addi	a0,a0,-1338 # 80008830 <syscalls+0x328>
    80005d72:	ffffa097          	auipc	ra,0xffffa
    80005d76:	7cc080e7          	jalr	1996(ra) # 8000053e <panic>
    dp->nlink--;
    80005d7a:	04a4d783          	lhu	a5,74(s1)
    80005d7e:	37fd                	addiw	a5,a5,-1
    80005d80:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d84:	8526                	mv	a0,s1
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	004080e7          	jalr	4(ra) # 80003d8a <iupdate>
    80005d8e:	b781                	j	80005cce <sys_unlink+0xe0>
    return -1;
    80005d90:	557d                	li	a0,-1
    80005d92:	a005                	j	80005db2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d94:	854a                	mv	a0,s2
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	320080e7          	jalr	800(ra) # 800040b6 <iunlockput>
  iunlockput(dp);
    80005d9e:	8526                	mv	a0,s1
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	316080e7          	jalr	790(ra) # 800040b6 <iunlockput>
  end_op();
    80005da8:	fffff097          	auipc	ra,0xfffff
    80005dac:	afe080e7          	jalr	-1282(ra) # 800048a6 <end_op>
  return -1;
    80005db0:	557d                	li	a0,-1
}
    80005db2:	70ae                	ld	ra,232(sp)
    80005db4:	740e                	ld	s0,224(sp)
    80005db6:	64ee                	ld	s1,216(sp)
    80005db8:	694e                	ld	s2,208(sp)
    80005dba:	69ae                	ld	s3,200(sp)
    80005dbc:	616d                	addi	sp,sp,240
    80005dbe:	8082                	ret

0000000080005dc0 <sys_open>:

uint64
sys_open(void)
{
    80005dc0:	7131                	addi	sp,sp,-192
    80005dc2:	fd06                	sd	ra,184(sp)
    80005dc4:	f922                	sd	s0,176(sp)
    80005dc6:	f526                	sd	s1,168(sp)
    80005dc8:	f14a                	sd	s2,160(sp)
    80005dca:	ed4e                	sd	s3,152(sp)
    80005dcc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005dce:	08000613          	li	a2,128
    80005dd2:	f5040593          	addi	a1,s0,-176
    80005dd6:	4501                	li	a0,0
    80005dd8:	ffffd097          	auipc	ra,0xffffd
    80005ddc:	4ec080e7          	jalr	1260(ra) # 800032c4 <argstr>
    return -1;
    80005de0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005de2:	0c054163          	bltz	a0,80005ea4 <sys_open+0xe4>
    80005de6:	f4c40593          	addi	a1,s0,-180
    80005dea:	4505                	li	a0,1
    80005dec:	ffffd097          	auipc	ra,0xffffd
    80005df0:	494080e7          	jalr	1172(ra) # 80003280 <argint>
    80005df4:	0a054863          	bltz	a0,80005ea4 <sys_open+0xe4>

  begin_op();
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	a2e080e7          	jalr	-1490(ra) # 80004826 <begin_op>

  if(omode & O_CREATE){
    80005e00:	f4c42783          	lw	a5,-180(s0)
    80005e04:	2007f793          	andi	a5,a5,512
    80005e08:	cbdd                	beqz	a5,80005ebe <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e0a:	4681                	li	a3,0
    80005e0c:	4601                	li	a2,0
    80005e0e:	4589                	li	a1,2
    80005e10:	f5040513          	addi	a0,s0,-176
    80005e14:	00000097          	auipc	ra,0x0
    80005e18:	972080e7          	jalr	-1678(ra) # 80005786 <create>
    80005e1c:	892a                	mv	s2,a0
    if(ip == 0){
    80005e1e:	c959                	beqz	a0,80005eb4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e20:	04491703          	lh	a4,68(s2)
    80005e24:	478d                	li	a5,3
    80005e26:	00f71763          	bne	a4,a5,80005e34 <sys_open+0x74>
    80005e2a:	04695703          	lhu	a4,70(s2)
    80005e2e:	47a5                	li	a5,9
    80005e30:	0ce7ec63          	bltu	a5,a4,80005f08 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e34:	fffff097          	auipc	ra,0xfffff
    80005e38:	e02080e7          	jalr	-510(ra) # 80004c36 <filealloc>
    80005e3c:	89aa                	mv	s3,a0
    80005e3e:	10050263          	beqz	a0,80005f42 <sys_open+0x182>
    80005e42:	00000097          	auipc	ra,0x0
    80005e46:	902080e7          	jalr	-1790(ra) # 80005744 <fdalloc>
    80005e4a:	84aa                	mv	s1,a0
    80005e4c:	0e054663          	bltz	a0,80005f38 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e50:	04491703          	lh	a4,68(s2)
    80005e54:	478d                	li	a5,3
    80005e56:	0cf70463          	beq	a4,a5,80005f1e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e5a:	4789                	li	a5,2
    80005e5c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e60:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e64:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e68:	f4c42783          	lw	a5,-180(s0)
    80005e6c:	0017c713          	xori	a4,a5,1
    80005e70:	8b05                	andi	a4,a4,1
    80005e72:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e76:	0037f713          	andi	a4,a5,3
    80005e7a:	00e03733          	snez	a4,a4
    80005e7e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e82:	4007f793          	andi	a5,a5,1024
    80005e86:	c791                	beqz	a5,80005e92 <sys_open+0xd2>
    80005e88:	04491703          	lh	a4,68(s2)
    80005e8c:	4789                	li	a5,2
    80005e8e:	08f70f63          	beq	a4,a5,80005f2c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e92:	854a                	mv	a0,s2
    80005e94:	ffffe097          	auipc	ra,0xffffe
    80005e98:	082080e7          	jalr	130(ra) # 80003f16 <iunlock>
  end_op();
    80005e9c:	fffff097          	auipc	ra,0xfffff
    80005ea0:	a0a080e7          	jalr	-1526(ra) # 800048a6 <end_op>

  return fd;
}
    80005ea4:	8526                	mv	a0,s1
    80005ea6:	70ea                	ld	ra,184(sp)
    80005ea8:	744a                	ld	s0,176(sp)
    80005eaa:	74aa                	ld	s1,168(sp)
    80005eac:	790a                	ld	s2,160(sp)
    80005eae:	69ea                	ld	s3,152(sp)
    80005eb0:	6129                	addi	sp,sp,192
    80005eb2:	8082                	ret
      end_op();
    80005eb4:	fffff097          	auipc	ra,0xfffff
    80005eb8:	9f2080e7          	jalr	-1550(ra) # 800048a6 <end_op>
      return -1;
    80005ebc:	b7e5                	j	80005ea4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ebe:	f5040513          	addi	a0,s0,-176
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	748080e7          	jalr	1864(ra) # 8000460a <namei>
    80005eca:	892a                	mv	s2,a0
    80005ecc:	c905                	beqz	a0,80005efc <sys_open+0x13c>
    ilock(ip);
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	f86080e7          	jalr	-122(ra) # 80003e54 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ed6:	04491703          	lh	a4,68(s2)
    80005eda:	4785                	li	a5,1
    80005edc:	f4f712e3          	bne	a4,a5,80005e20 <sys_open+0x60>
    80005ee0:	f4c42783          	lw	a5,-180(s0)
    80005ee4:	dba1                	beqz	a5,80005e34 <sys_open+0x74>
      iunlockput(ip);
    80005ee6:	854a                	mv	a0,s2
    80005ee8:	ffffe097          	auipc	ra,0xffffe
    80005eec:	1ce080e7          	jalr	462(ra) # 800040b6 <iunlockput>
      end_op();
    80005ef0:	fffff097          	auipc	ra,0xfffff
    80005ef4:	9b6080e7          	jalr	-1610(ra) # 800048a6 <end_op>
      return -1;
    80005ef8:	54fd                	li	s1,-1
    80005efa:	b76d                	j	80005ea4 <sys_open+0xe4>
      end_op();
    80005efc:	fffff097          	auipc	ra,0xfffff
    80005f00:	9aa080e7          	jalr	-1622(ra) # 800048a6 <end_op>
      return -1;
    80005f04:	54fd                	li	s1,-1
    80005f06:	bf79                	j	80005ea4 <sys_open+0xe4>
    iunlockput(ip);
    80005f08:	854a                	mv	a0,s2
    80005f0a:	ffffe097          	auipc	ra,0xffffe
    80005f0e:	1ac080e7          	jalr	428(ra) # 800040b6 <iunlockput>
    end_op();
    80005f12:	fffff097          	auipc	ra,0xfffff
    80005f16:	994080e7          	jalr	-1644(ra) # 800048a6 <end_op>
    return -1;
    80005f1a:	54fd                	li	s1,-1
    80005f1c:	b761                	j	80005ea4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f1e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f22:	04691783          	lh	a5,70(s2)
    80005f26:	02f99223          	sh	a5,36(s3)
    80005f2a:	bf2d                	j	80005e64 <sys_open+0xa4>
    itrunc(ip);
    80005f2c:	854a                	mv	a0,s2
    80005f2e:	ffffe097          	auipc	ra,0xffffe
    80005f32:	034080e7          	jalr	52(ra) # 80003f62 <itrunc>
    80005f36:	bfb1                	j	80005e92 <sys_open+0xd2>
      fileclose(f);
    80005f38:	854e                	mv	a0,s3
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	db8080e7          	jalr	-584(ra) # 80004cf2 <fileclose>
    iunlockput(ip);
    80005f42:	854a                	mv	a0,s2
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	172080e7          	jalr	370(ra) # 800040b6 <iunlockput>
    end_op();
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	95a080e7          	jalr	-1702(ra) # 800048a6 <end_op>
    return -1;
    80005f54:	54fd                	li	s1,-1
    80005f56:	b7b9                	j	80005ea4 <sys_open+0xe4>

0000000080005f58 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f58:	7175                	addi	sp,sp,-144
    80005f5a:	e506                	sd	ra,136(sp)
    80005f5c:	e122                	sd	s0,128(sp)
    80005f5e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f60:	fffff097          	auipc	ra,0xfffff
    80005f64:	8c6080e7          	jalr	-1850(ra) # 80004826 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f68:	08000613          	li	a2,128
    80005f6c:	f7040593          	addi	a1,s0,-144
    80005f70:	4501                	li	a0,0
    80005f72:	ffffd097          	auipc	ra,0xffffd
    80005f76:	352080e7          	jalr	850(ra) # 800032c4 <argstr>
    80005f7a:	02054963          	bltz	a0,80005fac <sys_mkdir+0x54>
    80005f7e:	4681                	li	a3,0
    80005f80:	4601                	li	a2,0
    80005f82:	4585                	li	a1,1
    80005f84:	f7040513          	addi	a0,s0,-144
    80005f88:	fffff097          	auipc	ra,0xfffff
    80005f8c:	7fe080e7          	jalr	2046(ra) # 80005786 <create>
    80005f90:	cd11                	beqz	a0,80005fac <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	124080e7          	jalr	292(ra) # 800040b6 <iunlockput>
  end_op();
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	90c080e7          	jalr	-1780(ra) # 800048a6 <end_op>
  return 0;
    80005fa2:	4501                	li	a0,0
}
    80005fa4:	60aa                	ld	ra,136(sp)
    80005fa6:	640a                	ld	s0,128(sp)
    80005fa8:	6149                	addi	sp,sp,144
    80005faa:	8082                	ret
    end_op();
    80005fac:	fffff097          	auipc	ra,0xfffff
    80005fb0:	8fa080e7          	jalr	-1798(ra) # 800048a6 <end_op>
    return -1;
    80005fb4:	557d                	li	a0,-1
    80005fb6:	b7fd                	j	80005fa4 <sys_mkdir+0x4c>

0000000080005fb8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005fb8:	7135                	addi	sp,sp,-160
    80005fba:	ed06                	sd	ra,152(sp)
    80005fbc:	e922                	sd	s0,144(sp)
    80005fbe:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fc0:	fffff097          	auipc	ra,0xfffff
    80005fc4:	866080e7          	jalr	-1946(ra) # 80004826 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fc8:	08000613          	li	a2,128
    80005fcc:	f7040593          	addi	a1,s0,-144
    80005fd0:	4501                	li	a0,0
    80005fd2:	ffffd097          	auipc	ra,0xffffd
    80005fd6:	2f2080e7          	jalr	754(ra) # 800032c4 <argstr>
    80005fda:	04054a63          	bltz	a0,8000602e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005fde:	f6c40593          	addi	a1,s0,-148
    80005fe2:	4505                	li	a0,1
    80005fe4:	ffffd097          	auipc	ra,0xffffd
    80005fe8:	29c080e7          	jalr	668(ra) # 80003280 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fec:	04054163          	bltz	a0,8000602e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ff0:	f6840593          	addi	a1,s0,-152
    80005ff4:	4509                	li	a0,2
    80005ff6:	ffffd097          	auipc	ra,0xffffd
    80005ffa:	28a080e7          	jalr	650(ra) # 80003280 <argint>
     argint(1, &major) < 0 ||
    80005ffe:	02054863          	bltz	a0,8000602e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006002:	f6841683          	lh	a3,-152(s0)
    80006006:	f6c41603          	lh	a2,-148(s0)
    8000600a:	458d                	li	a1,3
    8000600c:	f7040513          	addi	a0,s0,-144
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	776080e7          	jalr	1910(ra) # 80005786 <create>
     argint(2, &minor) < 0 ||
    80006018:	c919                	beqz	a0,8000602e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	09c080e7          	jalr	156(ra) # 800040b6 <iunlockput>
  end_op();
    80006022:	fffff097          	auipc	ra,0xfffff
    80006026:	884080e7          	jalr	-1916(ra) # 800048a6 <end_op>
  return 0;
    8000602a:	4501                	li	a0,0
    8000602c:	a031                	j	80006038 <sys_mknod+0x80>
    end_op();
    8000602e:	fffff097          	auipc	ra,0xfffff
    80006032:	878080e7          	jalr	-1928(ra) # 800048a6 <end_op>
    return -1;
    80006036:	557d                	li	a0,-1
}
    80006038:	60ea                	ld	ra,152(sp)
    8000603a:	644a                	ld	s0,144(sp)
    8000603c:	610d                	addi	sp,sp,160
    8000603e:	8082                	ret

0000000080006040 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006040:	7135                	addi	sp,sp,-160
    80006042:	ed06                	sd	ra,152(sp)
    80006044:	e922                	sd	s0,144(sp)
    80006046:	e526                	sd	s1,136(sp)
    80006048:	e14a                	sd	s2,128(sp)
    8000604a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000604c:	ffffc097          	auipc	ra,0xffffc
    80006050:	bbc080e7          	jalr	-1092(ra) # 80001c08 <myproc>
    80006054:	892a                	mv	s2,a0
  
  begin_op();
    80006056:	ffffe097          	auipc	ra,0xffffe
    8000605a:	7d0080e7          	jalr	2000(ra) # 80004826 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000605e:	08000613          	li	a2,128
    80006062:	f6040593          	addi	a1,s0,-160
    80006066:	4501                	li	a0,0
    80006068:	ffffd097          	auipc	ra,0xffffd
    8000606c:	25c080e7          	jalr	604(ra) # 800032c4 <argstr>
    80006070:	04054b63          	bltz	a0,800060c6 <sys_chdir+0x86>
    80006074:	f6040513          	addi	a0,s0,-160
    80006078:	ffffe097          	auipc	ra,0xffffe
    8000607c:	592080e7          	jalr	1426(ra) # 8000460a <namei>
    80006080:	84aa                	mv	s1,a0
    80006082:	c131                	beqz	a0,800060c6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006084:	ffffe097          	auipc	ra,0xffffe
    80006088:	dd0080e7          	jalr	-560(ra) # 80003e54 <ilock>
  if(ip->type != T_DIR){
    8000608c:	04449703          	lh	a4,68(s1)
    80006090:	4785                	li	a5,1
    80006092:	04f71063          	bne	a4,a5,800060d2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006096:	8526                	mv	a0,s1
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	e7e080e7          	jalr	-386(ra) # 80003f16 <iunlock>
  iput(p->cwd);
    800060a0:	17093503          	ld	a0,368(s2)
    800060a4:	ffffe097          	auipc	ra,0xffffe
    800060a8:	f6a080e7          	jalr	-150(ra) # 8000400e <iput>
  end_op();
    800060ac:	ffffe097          	auipc	ra,0xffffe
    800060b0:	7fa080e7          	jalr	2042(ra) # 800048a6 <end_op>
  p->cwd = ip;
    800060b4:	16993823          	sd	s1,368(s2)
  return 0;
    800060b8:	4501                	li	a0,0
}
    800060ba:	60ea                	ld	ra,152(sp)
    800060bc:	644a                	ld	s0,144(sp)
    800060be:	64aa                	ld	s1,136(sp)
    800060c0:	690a                	ld	s2,128(sp)
    800060c2:	610d                	addi	sp,sp,160
    800060c4:	8082                	ret
    end_op();
    800060c6:	ffffe097          	auipc	ra,0xffffe
    800060ca:	7e0080e7          	jalr	2016(ra) # 800048a6 <end_op>
    return -1;
    800060ce:	557d                	li	a0,-1
    800060d0:	b7ed                	j	800060ba <sys_chdir+0x7a>
    iunlockput(ip);
    800060d2:	8526                	mv	a0,s1
    800060d4:	ffffe097          	auipc	ra,0xffffe
    800060d8:	fe2080e7          	jalr	-30(ra) # 800040b6 <iunlockput>
    end_op();
    800060dc:	ffffe097          	auipc	ra,0xffffe
    800060e0:	7ca080e7          	jalr	1994(ra) # 800048a6 <end_op>
    return -1;
    800060e4:	557d                	li	a0,-1
    800060e6:	bfd1                	j	800060ba <sys_chdir+0x7a>

00000000800060e8 <sys_exec>:

uint64
sys_exec(void)
{
    800060e8:	7145                	addi	sp,sp,-464
    800060ea:	e786                	sd	ra,456(sp)
    800060ec:	e3a2                	sd	s0,448(sp)
    800060ee:	ff26                	sd	s1,440(sp)
    800060f0:	fb4a                	sd	s2,432(sp)
    800060f2:	f74e                	sd	s3,424(sp)
    800060f4:	f352                	sd	s4,416(sp)
    800060f6:	ef56                	sd	s5,408(sp)
    800060f8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060fa:	08000613          	li	a2,128
    800060fe:	f4040593          	addi	a1,s0,-192
    80006102:	4501                	li	a0,0
    80006104:	ffffd097          	auipc	ra,0xffffd
    80006108:	1c0080e7          	jalr	448(ra) # 800032c4 <argstr>
    return -1;
    8000610c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000610e:	0c054a63          	bltz	a0,800061e2 <sys_exec+0xfa>
    80006112:	e3840593          	addi	a1,s0,-456
    80006116:	4505                	li	a0,1
    80006118:	ffffd097          	auipc	ra,0xffffd
    8000611c:	18a080e7          	jalr	394(ra) # 800032a2 <argaddr>
    80006120:	0c054163          	bltz	a0,800061e2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006124:	10000613          	li	a2,256
    80006128:	4581                	li	a1,0
    8000612a:	e4040513          	addi	a0,s0,-448
    8000612e:	ffffb097          	auipc	ra,0xffffb
    80006132:	bb2080e7          	jalr	-1102(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006136:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000613a:	89a6                	mv	s3,s1
    8000613c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000613e:	02000a13          	li	s4,32
    80006142:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006146:	00391513          	slli	a0,s2,0x3
    8000614a:	e3040593          	addi	a1,s0,-464
    8000614e:	e3843783          	ld	a5,-456(s0)
    80006152:	953e                	add	a0,a0,a5
    80006154:	ffffd097          	auipc	ra,0xffffd
    80006158:	092080e7          	jalr	146(ra) # 800031e6 <fetchaddr>
    8000615c:	02054a63          	bltz	a0,80006190 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006160:	e3043783          	ld	a5,-464(s0)
    80006164:	c3b9                	beqz	a5,800061aa <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006166:	ffffb097          	auipc	ra,0xffffb
    8000616a:	98e080e7          	jalr	-1650(ra) # 80000af4 <kalloc>
    8000616e:	85aa                	mv	a1,a0
    80006170:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006174:	cd11                	beqz	a0,80006190 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006176:	6605                	lui	a2,0x1
    80006178:	e3043503          	ld	a0,-464(s0)
    8000617c:	ffffd097          	auipc	ra,0xffffd
    80006180:	0bc080e7          	jalr	188(ra) # 80003238 <fetchstr>
    80006184:	00054663          	bltz	a0,80006190 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006188:	0905                	addi	s2,s2,1
    8000618a:	09a1                	addi	s3,s3,8
    8000618c:	fb491be3          	bne	s2,s4,80006142 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006190:	10048913          	addi	s2,s1,256
    80006194:	6088                	ld	a0,0(s1)
    80006196:	c529                	beqz	a0,800061e0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006198:	ffffb097          	auipc	ra,0xffffb
    8000619c:	860080e7          	jalr	-1952(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061a0:	04a1                	addi	s1,s1,8
    800061a2:	ff2499e3          	bne	s1,s2,80006194 <sys_exec+0xac>
  return -1;
    800061a6:	597d                	li	s2,-1
    800061a8:	a82d                	j	800061e2 <sys_exec+0xfa>
      argv[i] = 0;
    800061aa:	0a8e                	slli	s5,s5,0x3
    800061ac:	fc040793          	addi	a5,s0,-64
    800061b0:	9abe                	add	s5,s5,a5
    800061b2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800061b6:	e4040593          	addi	a1,s0,-448
    800061ba:	f4040513          	addi	a0,s0,-192
    800061be:	fffff097          	auipc	ra,0xfffff
    800061c2:	194080e7          	jalr	404(ra) # 80005352 <exec>
    800061c6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061c8:	10048993          	addi	s3,s1,256
    800061cc:	6088                	ld	a0,0(s1)
    800061ce:	c911                	beqz	a0,800061e2 <sys_exec+0xfa>
    kfree(argv[i]);
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	828080e7          	jalr	-2008(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061d8:	04a1                	addi	s1,s1,8
    800061da:	ff3499e3          	bne	s1,s3,800061cc <sys_exec+0xe4>
    800061de:	a011                	j	800061e2 <sys_exec+0xfa>
  return -1;
    800061e0:	597d                	li	s2,-1
}
    800061e2:	854a                	mv	a0,s2
    800061e4:	60be                	ld	ra,456(sp)
    800061e6:	641e                	ld	s0,448(sp)
    800061e8:	74fa                	ld	s1,440(sp)
    800061ea:	795a                	ld	s2,432(sp)
    800061ec:	79ba                	ld	s3,424(sp)
    800061ee:	7a1a                	ld	s4,416(sp)
    800061f0:	6afa                	ld	s5,408(sp)
    800061f2:	6179                	addi	sp,sp,464
    800061f4:	8082                	ret

00000000800061f6 <sys_pipe>:

uint64
sys_pipe(void)
{
    800061f6:	7139                	addi	sp,sp,-64
    800061f8:	fc06                	sd	ra,56(sp)
    800061fa:	f822                	sd	s0,48(sp)
    800061fc:	f426                	sd	s1,40(sp)
    800061fe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006200:	ffffc097          	auipc	ra,0xffffc
    80006204:	a08080e7          	jalr	-1528(ra) # 80001c08 <myproc>
    80006208:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000620a:	fd840593          	addi	a1,s0,-40
    8000620e:	4501                	li	a0,0
    80006210:	ffffd097          	auipc	ra,0xffffd
    80006214:	092080e7          	jalr	146(ra) # 800032a2 <argaddr>
    return -1;
    80006218:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000621a:	0e054063          	bltz	a0,800062fa <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000621e:	fc840593          	addi	a1,s0,-56
    80006222:	fd040513          	addi	a0,s0,-48
    80006226:	fffff097          	auipc	ra,0xfffff
    8000622a:	dfc080e7          	jalr	-516(ra) # 80005022 <pipealloc>
    return -1;
    8000622e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006230:	0c054563          	bltz	a0,800062fa <sys_pipe+0x104>
  fd0 = -1;
    80006234:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006238:	fd043503          	ld	a0,-48(s0)
    8000623c:	fffff097          	auipc	ra,0xfffff
    80006240:	508080e7          	jalr	1288(ra) # 80005744 <fdalloc>
    80006244:	fca42223          	sw	a0,-60(s0)
    80006248:	08054c63          	bltz	a0,800062e0 <sys_pipe+0xea>
    8000624c:	fc843503          	ld	a0,-56(s0)
    80006250:	fffff097          	auipc	ra,0xfffff
    80006254:	4f4080e7          	jalr	1268(ra) # 80005744 <fdalloc>
    80006258:	fca42023          	sw	a0,-64(s0)
    8000625c:	06054863          	bltz	a0,800062cc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006260:	4691                	li	a3,4
    80006262:	fc440613          	addi	a2,s0,-60
    80006266:	fd843583          	ld	a1,-40(s0)
    8000626a:	78a8                	ld	a0,112(s1)
    8000626c:	ffffb097          	auipc	ra,0xffffb
    80006270:	52a080e7          	jalr	1322(ra) # 80001796 <copyout>
    80006274:	02054063          	bltz	a0,80006294 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006278:	4691                	li	a3,4
    8000627a:	fc040613          	addi	a2,s0,-64
    8000627e:	fd843583          	ld	a1,-40(s0)
    80006282:	0591                	addi	a1,a1,4
    80006284:	78a8                	ld	a0,112(s1)
    80006286:	ffffb097          	auipc	ra,0xffffb
    8000628a:	510080e7          	jalr	1296(ra) # 80001796 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000628e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006290:	06055563          	bgez	a0,800062fa <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006294:	fc442783          	lw	a5,-60(s0)
    80006298:	07f9                	addi	a5,a5,30
    8000629a:	078e                	slli	a5,a5,0x3
    8000629c:	97a6                	add	a5,a5,s1
    8000629e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800062a2:	fc042503          	lw	a0,-64(s0)
    800062a6:	0579                	addi	a0,a0,30
    800062a8:	050e                	slli	a0,a0,0x3
    800062aa:	9526                	add	a0,a0,s1
    800062ac:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062b0:	fd043503          	ld	a0,-48(s0)
    800062b4:	fffff097          	auipc	ra,0xfffff
    800062b8:	a3e080e7          	jalr	-1474(ra) # 80004cf2 <fileclose>
    fileclose(wf);
    800062bc:	fc843503          	ld	a0,-56(s0)
    800062c0:	fffff097          	auipc	ra,0xfffff
    800062c4:	a32080e7          	jalr	-1486(ra) # 80004cf2 <fileclose>
    return -1;
    800062c8:	57fd                	li	a5,-1
    800062ca:	a805                	j	800062fa <sys_pipe+0x104>
    if(fd0 >= 0)
    800062cc:	fc442783          	lw	a5,-60(s0)
    800062d0:	0007c863          	bltz	a5,800062e0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800062d4:	01e78513          	addi	a0,a5,30
    800062d8:	050e                	slli	a0,a0,0x3
    800062da:	9526                	add	a0,a0,s1
    800062dc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062e0:	fd043503          	ld	a0,-48(s0)
    800062e4:	fffff097          	auipc	ra,0xfffff
    800062e8:	a0e080e7          	jalr	-1522(ra) # 80004cf2 <fileclose>
    fileclose(wf);
    800062ec:	fc843503          	ld	a0,-56(s0)
    800062f0:	fffff097          	auipc	ra,0xfffff
    800062f4:	a02080e7          	jalr	-1534(ra) # 80004cf2 <fileclose>
    return -1;
    800062f8:	57fd                	li	a5,-1
}
    800062fa:	853e                	mv	a0,a5
    800062fc:	70e2                	ld	ra,56(sp)
    800062fe:	7442                	ld	s0,48(sp)
    80006300:	74a2                	ld	s1,40(sp)
    80006302:	6121                	addi	sp,sp,64
    80006304:	8082                	ret
	...

0000000080006310 <kernelvec>:
    80006310:	7111                	addi	sp,sp,-256
    80006312:	e006                	sd	ra,0(sp)
    80006314:	e40a                	sd	sp,8(sp)
    80006316:	e80e                	sd	gp,16(sp)
    80006318:	ec12                	sd	tp,24(sp)
    8000631a:	f016                	sd	t0,32(sp)
    8000631c:	f41a                	sd	t1,40(sp)
    8000631e:	f81e                	sd	t2,48(sp)
    80006320:	fc22                	sd	s0,56(sp)
    80006322:	e0a6                	sd	s1,64(sp)
    80006324:	e4aa                	sd	a0,72(sp)
    80006326:	e8ae                	sd	a1,80(sp)
    80006328:	ecb2                	sd	a2,88(sp)
    8000632a:	f0b6                	sd	a3,96(sp)
    8000632c:	f4ba                	sd	a4,104(sp)
    8000632e:	f8be                	sd	a5,112(sp)
    80006330:	fcc2                	sd	a6,120(sp)
    80006332:	e146                	sd	a7,128(sp)
    80006334:	e54a                	sd	s2,136(sp)
    80006336:	e94e                	sd	s3,144(sp)
    80006338:	ed52                	sd	s4,152(sp)
    8000633a:	f156                	sd	s5,160(sp)
    8000633c:	f55a                	sd	s6,168(sp)
    8000633e:	f95e                	sd	s7,176(sp)
    80006340:	fd62                	sd	s8,184(sp)
    80006342:	e1e6                	sd	s9,192(sp)
    80006344:	e5ea                	sd	s10,200(sp)
    80006346:	e9ee                	sd	s11,208(sp)
    80006348:	edf2                	sd	t3,216(sp)
    8000634a:	f1f6                	sd	t4,224(sp)
    8000634c:	f5fa                	sd	t5,232(sp)
    8000634e:	f9fe                	sd	t6,240(sp)
    80006350:	d63fc0ef          	jal	ra,800030b2 <kerneltrap>
    80006354:	6082                	ld	ra,0(sp)
    80006356:	6122                	ld	sp,8(sp)
    80006358:	61c2                	ld	gp,16(sp)
    8000635a:	7282                	ld	t0,32(sp)
    8000635c:	7322                	ld	t1,40(sp)
    8000635e:	73c2                	ld	t2,48(sp)
    80006360:	7462                	ld	s0,56(sp)
    80006362:	6486                	ld	s1,64(sp)
    80006364:	6526                	ld	a0,72(sp)
    80006366:	65c6                	ld	a1,80(sp)
    80006368:	6666                	ld	a2,88(sp)
    8000636a:	7686                	ld	a3,96(sp)
    8000636c:	7726                	ld	a4,104(sp)
    8000636e:	77c6                	ld	a5,112(sp)
    80006370:	7866                	ld	a6,120(sp)
    80006372:	688a                	ld	a7,128(sp)
    80006374:	692a                	ld	s2,136(sp)
    80006376:	69ca                	ld	s3,144(sp)
    80006378:	6a6a                	ld	s4,152(sp)
    8000637a:	7a8a                	ld	s5,160(sp)
    8000637c:	7b2a                	ld	s6,168(sp)
    8000637e:	7bca                	ld	s7,176(sp)
    80006380:	7c6a                	ld	s8,184(sp)
    80006382:	6c8e                	ld	s9,192(sp)
    80006384:	6d2e                	ld	s10,200(sp)
    80006386:	6dce                	ld	s11,208(sp)
    80006388:	6e6e                	ld	t3,216(sp)
    8000638a:	7e8e                	ld	t4,224(sp)
    8000638c:	7f2e                	ld	t5,232(sp)
    8000638e:	7fce                	ld	t6,240(sp)
    80006390:	6111                	addi	sp,sp,256
    80006392:	10200073          	sret
    80006396:	00000013          	nop
    8000639a:	00000013          	nop
    8000639e:	0001                	nop

00000000800063a0 <timervec>:
    800063a0:	34051573          	csrrw	a0,mscratch,a0
    800063a4:	e10c                	sd	a1,0(a0)
    800063a6:	e510                	sd	a2,8(a0)
    800063a8:	e914                	sd	a3,16(a0)
    800063aa:	6d0c                	ld	a1,24(a0)
    800063ac:	7110                	ld	a2,32(a0)
    800063ae:	6194                	ld	a3,0(a1)
    800063b0:	96b2                	add	a3,a3,a2
    800063b2:	e194                	sd	a3,0(a1)
    800063b4:	4589                	li	a1,2
    800063b6:	14459073          	csrw	sip,a1
    800063ba:	6914                	ld	a3,16(a0)
    800063bc:	6510                	ld	a2,8(a0)
    800063be:	610c                	ld	a1,0(a0)
    800063c0:	34051573          	csrrw	a0,mscratch,a0
    800063c4:	30200073          	mret
	...

00000000800063ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063ca:	1141                	addi	sp,sp,-16
    800063cc:	e422                	sd	s0,8(sp)
    800063ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063d0:	0c0007b7          	lui	a5,0xc000
    800063d4:	4705                	li	a4,1
    800063d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063d8:	c3d8                	sw	a4,4(a5)
}
    800063da:	6422                	ld	s0,8(sp)
    800063dc:	0141                	addi	sp,sp,16
    800063de:	8082                	ret

00000000800063e0 <plicinithart>:

void
plicinithart(void)
{
    800063e0:	1141                	addi	sp,sp,-16
    800063e2:	e406                	sd	ra,8(sp)
    800063e4:	e022                	sd	s0,0(sp)
    800063e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063e8:	ffffb097          	auipc	ra,0xffffb
    800063ec:	7f4080e7          	jalr	2036(ra) # 80001bdc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063f0:	0085171b          	slliw	a4,a0,0x8
    800063f4:	0c0027b7          	lui	a5,0xc002
    800063f8:	97ba                	add	a5,a5,a4
    800063fa:	40200713          	li	a4,1026
    800063fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006402:	00d5151b          	slliw	a0,a0,0xd
    80006406:	0c2017b7          	lui	a5,0xc201
    8000640a:	953e                	add	a0,a0,a5
    8000640c:	00052023          	sw	zero,0(a0)
}
    80006410:	60a2                	ld	ra,8(sp)
    80006412:	6402                	ld	s0,0(sp)
    80006414:	0141                	addi	sp,sp,16
    80006416:	8082                	ret

0000000080006418 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006418:	1141                	addi	sp,sp,-16
    8000641a:	e406                	sd	ra,8(sp)
    8000641c:	e022                	sd	s0,0(sp)
    8000641e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006420:	ffffb097          	auipc	ra,0xffffb
    80006424:	7bc080e7          	jalr	1980(ra) # 80001bdc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006428:	00d5179b          	slliw	a5,a0,0xd
    8000642c:	0c201537          	lui	a0,0xc201
    80006430:	953e                	add	a0,a0,a5
  return irq;
}
    80006432:	4148                	lw	a0,4(a0)
    80006434:	60a2                	ld	ra,8(sp)
    80006436:	6402                	ld	s0,0(sp)
    80006438:	0141                	addi	sp,sp,16
    8000643a:	8082                	ret

000000008000643c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000643c:	1101                	addi	sp,sp,-32
    8000643e:	ec06                	sd	ra,24(sp)
    80006440:	e822                	sd	s0,16(sp)
    80006442:	e426                	sd	s1,8(sp)
    80006444:	1000                	addi	s0,sp,32
    80006446:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006448:	ffffb097          	auipc	ra,0xffffb
    8000644c:	794080e7          	jalr	1940(ra) # 80001bdc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006450:	00d5151b          	slliw	a0,a0,0xd
    80006454:	0c2017b7          	lui	a5,0xc201
    80006458:	97aa                	add	a5,a5,a0
    8000645a:	c3c4                	sw	s1,4(a5)
}
    8000645c:	60e2                	ld	ra,24(sp)
    8000645e:	6442                	ld	s0,16(sp)
    80006460:	64a2                	ld	s1,8(sp)
    80006462:	6105                	addi	sp,sp,32
    80006464:	8082                	ret

0000000080006466 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006466:	1141                	addi	sp,sp,-16
    80006468:	e406                	sd	ra,8(sp)
    8000646a:	e022                	sd	s0,0(sp)
    8000646c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000646e:	479d                	li	a5,7
    80006470:	06a7c963          	blt	a5,a0,800064e2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006474:	0001d797          	auipc	a5,0x1d
    80006478:	b8c78793          	addi	a5,a5,-1140 # 80023000 <disk>
    8000647c:	00a78733          	add	a4,a5,a0
    80006480:	6789                	lui	a5,0x2
    80006482:	97ba                	add	a5,a5,a4
    80006484:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006488:	e7ad                	bnez	a5,800064f2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000648a:	00451793          	slli	a5,a0,0x4
    8000648e:	0001f717          	auipc	a4,0x1f
    80006492:	b7270713          	addi	a4,a4,-1166 # 80025000 <disk+0x2000>
    80006496:	6314                	ld	a3,0(a4)
    80006498:	96be                	add	a3,a3,a5
    8000649a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000649e:	6314                	ld	a3,0(a4)
    800064a0:	96be                	add	a3,a3,a5
    800064a2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800064a6:	6314                	ld	a3,0(a4)
    800064a8:	96be                	add	a3,a3,a5
    800064aa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800064ae:	6318                	ld	a4,0(a4)
    800064b0:	97ba                	add	a5,a5,a4
    800064b2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800064b6:	0001d797          	auipc	a5,0x1d
    800064ba:	b4a78793          	addi	a5,a5,-1206 # 80023000 <disk>
    800064be:	97aa                	add	a5,a5,a0
    800064c0:	6509                	lui	a0,0x2
    800064c2:	953e                	add	a0,a0,a5
    800064c4:	4785                	li	a5,1
    800064c6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800064ca:	0001f517          	auipc	a0,0x1f
    800064ce:	b4e50513          	addi	a0,a0,-1202 # 80025018 <disk+0x2018>
    800064d2:	ffffc097          	auipc	ra,0xffffc
    800064d6:	41c080e7          	jalr	1052(ra) # 800028ee <wakeup>
}
    800064da:	60a2                	ld	ra,8(sp)
    800064dc:	6402                	ld	s0,0(sp)
    800064de:	0141                	addi	sp,sp,16
    800064e0:	8082                	ret
    panic("free_desc 1");
    800064e2:	00002517          	auipc	a0,0x2
    800064e6:	35e50513          	addi	a0,a0,862 # 80008840 <syscalls+0x338>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	054080e7          	jalr	84(ra) # 8000053e <panic>
    panic("free_desc 2");
    800064f2:	00002517          	auipc	a0,0x2
    800064f6:	35e50513          	addi	a0,a0,862 # 80008850 <syscalls+0x348>
    800064fa:	ffffa097          	auipc	ra,0xffffa
    800064fe:	044080e7          	jalr	68(ra) # 8000053e <panic>

0000000080006502 <virtio_disk_init>:
{
    80006502:	1101                	addi	sp,sp,-32
    80006504:	ec06                	sd	ra,24(sp)
    80006506:	e822                	sd	s0,16(sp)
    80006508:	e426                	sd	s1,8(sp)
    8000650a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000650c:	00002597          	auipc	a1,0x2
    80006510:	35458593          	addi	a1,a1,852 # 80008860 <syscalls+0x358>
    80006514:	0001f517          	auipc	a0,0x1f
    80006518:	c1450513          	addi	a0,a0,-1004 # 80025128 <disk+0x2128>
    8000651c:	ffffa097          	auipc	ra,0xffffa
    80006520:	638080e7          	jalr	1592(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006524:	100017b7          	lui	a5,0x10001
    80006528:	4398                	lw	a4,0(a5)
    8000652a:	2701                	sext.w	a4,a4
    8000652c:	747277b7          	lui	a5,0x74727
    80006530:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006534:	0ef71163          	bne	a4,a5,80006616 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006538:	100017b7          	lui	a5,0x10001
    8000653c:	43dc                	lw	a5,4(a5)
    8000653e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006540:	4705                	li	a4,1
    80006542:	0ce79a63          	bne	a5,a4,80006616 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006546:	100017b7          	lui	a5,0x10001
    8000654a:	479c                	lw	a5,8(a5)
    8000654c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000654e:	4709                	li	a4,2
    80006550:	0ce79363          	bne	a5,a4,80006616 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006554:	100017b7          	lui	a5,0x10001
    80006558:	47d8                	lw	a4,12(a5)
    8000655a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000655c:	554d47b7          	lui	a5,0x554d4
    80006560:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006564:	0af71963          	bne	a4,a5,80006616 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006568:	100017b7          	lui	a5,0x10001
    8000656c:	4705                	li	a4,1
    8000656e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006570:	470d                	li	a4,3
    80006572:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006574:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006576:	c7ffe737          	lui	a4,0xc7ffe
    8000657a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000657e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006580:	2701                	sext.w	a4,a4
    80006582:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006584:	472d                	li	a4,11
    80006586:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006588:	473d                	li	a4,15
    8000658a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000658c:	6705                	lui	a4,0x1
    8000658e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006590:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006594:	5bdc                	lw	a5,52(a5)
    80006596:	2781                	sext.w	a5,a5
  if(max == 0)
    80006598:	c7d9                	beqz	a5,80006626 <virtio_disk_init+0x124>
  if(max < NUM)
    8000659a:	471d                	li	a4,7
    8000659c:	08f77d63          	bgeu	a4,a5,80006636 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800065a0:	100014b7          	lui	s1,0x10001
    800065a4:	47a1                	li	a5,8
    800065a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800065a8:	6609                	lui	a2,0x2
    800065aa:	4581                	li	a1,0
    800065ac:	0001d517          	auipc	a0,0x1d
    800065b0:	a5450513          	addi	a0,a0,-1452 # 80023000 <disk>
    800065b4:	ffffa097          	auipc	ra,0xffffa
    800065b8:	72c080e7          	jalr	1836(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800065bc:	0001d717          	auipc	a4,0x1d
    800065c0:	a4470713          	addi	a4,a4,-1468 # 80023000 <disk>
    800065c4:	00c75793          	srli	a5,a4,0xc
    800065c8:	2781                	sext.w	a5,a5
    800065ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800065cc:	0001f797          	auipc	a5,0x1f
    800065d0:	a3478793          	addi	a5,a5,-1484 # 80025000 <disk+0x2000>
    800065d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800065d6:	0001d717          	auipc	a4,0x1d
    800065da:	aaa70713          	addi	a4,a4,-1366 # 80023080 <disk+0x80>
    800065de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800065e0:	0001e717          	auipc	a4,0x1e
    800065e4:	a2070713          	addi	a4,a4,-1504 # 80024000 <disk+0x1000>
    800065e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800065ea:	4705                	li	a4,1
    800065ec:	00e78c23          	sb	a4,24(a5)
    800065f0:	00e78ca3          	sb	a4,25(a5)
    800065f4:	00e78d23          	sb	a4,26(a5)
    800065f8:	00e78da3          	sb	a4,27(a5)
    800065fc:	00e78e23          	sb	a4,28(a5)
    80006600:	00e78ea3          	sb	a4,29(a5)
    80006604:	00e78f23          	sb	a4,30(a5)
    80006608:	00e78fa3          	sb	a4,31(a5)
}
    8000660c:	60e2                	ld	ra,24(sp)
    8000660e:	6442                	ld	s0,16(sp)
    80006610:	64a2                	ld	s1,8(sp)
    80006612:	6105                	addi	sp,sp,32
    80006614:	8082                	ret
    panic("could not find virtio disk");
    80006616:	00002517          	auipc	a0,0x2
    8000661a:	25a50513          	addi	a0,a0,602 # 80008870 <syscalls+0x368>
    8000661e:	ffffa097          	auipc	ra,0xffffa
    80006622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006626:	00002517          	auipc	a0,0x2
    8000662a:	26a50513          	addi	a0,a0,618 # 80008890 <syscalls+0x388>
    8000662e:	ffffa097          	auipc	ra,0xffffa
    80006632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006636:	00002517          	auipc	a0,0x2
    8000663a:	27a50513          	addi	a0,a0,634 # 800088b0 <syscalls+0x3a8>
    8000663e:	ffffa097          	auipc	ra,0xffffa
    80006642:	f00080e7          	jalr	-256(ra) # 8000053e <panic>

0000000080006646 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006646:	7159                	addi	sp,sp,-112
    80006648:	f486                	sd	ra,104(sp)
    8000664a:	f0a2                	sd	s0,96(sp)
    8000664c:	eca6                	sd	s1,88(sp)
    8000664e:	e8ca                	sd	s2,80(sp)
    80006650:	e4ce                	sd	s3,72(sp)
    80006652:	e0d2                	sd	s4,64(sp)
    80006654:	fc56                	sd	s5,56(sp)
    80006656:	f85a                	sd	s6,48(sp)
    80006658:	f45e                	sd	s7,40(sp)
    8000665a:	f062                	sd	s8,32(sp)
    8000665c:	ec66                	sd	s9,24(sp)
    8000665e:	e86a                	sd	s10,16(sp)
    80006660:	1880                	addi	s0,sp,112
    80006662:	892a                	mv	s2,a0
    80006664:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006666:	00c52c83          	lw	s9,12(a0)
    8000666a:	001c9c9b          	slliw	s9,s9,0x1
    8000666e:	1c82                	slli	s9,s9,0x20
    80006670:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006674:	0001f517          	auipc	a0,0x1f
    80006678:	ab450513          	addi	a0,a0,-1356 # 80025128 <disk+0x2128>
    8000667c:	ffffa097          	auipc	ra,0xffffa
    80006680:	568080e7          	jalr	1384(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006684:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006686:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006688:	0001db97          	auipc	s7,0x1d
    8000668c:	978b8b93          	addi	s7,s7,-1672 # 80023000 <disk>
    80006690:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006692:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006694:	8a4e                	mv	s4,s3
    80006696:	a051                	j	8000671a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006698:	00fb86b3          	add	a3,s7,a5
    8000669c:	96da                	add	a3,a3,s6
    8000669e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800066a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800066a4:	0207c563          	bltz	a5,800066ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800066a8:	2485                	addiw	s1,s1,1
    800066aa:	0711                	addi	a4,a4,4
    800066ac:	25548063          	beq	s1,s5,800068ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800066b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800066b2:	0001f697          	auipc	a3,0x1f
    800066b6:	96668693          	addi	a3,a3,-1690 # 80025018 <disk+0x2018>
    800066ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800066bc:	0006c583          	lbu	a1,0(a3)
    800066c0:	fde1                	bnez	a1,80006698 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800066c2:	2785                	addiw	a5,a5,1
    800066c4:	0685                	addi	a3,a3,1
    800066c6:	ff879be3          	bne	a5,s8,800066bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800066ca:	57fd                	li	a5,-1
    800066cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800066ce:	02905a63          	blez	s1,80006702 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066d2:	f9042503          	lw	a0,-112(s0)
    800066d6:	00000097          	auipc	ra,0x0
    800066da:	d90080e7          	jalr	-624(ra) # 80006466 <free_desc>
      for(int j = 0; j < i; j++)
    800066de:	4785                	li	a5,1
    800066e0:	0297d163          	bge	a5,s1,80006702 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066e4:	f9442503          	lw	a0,-108(s0)
    800066e8:	00000097          	auipc	ra,0x0
    800066ec:	d7e080e7          	jalr	-642(ra) # 80006466 <free_desc>
      for(int j = 0; j < i; j++)
    800066f0:	4789                	li	a5,2
    800066f2:	0097d863          	bge	a5,s1,80006702 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066f6:	f9842503          	lw	a0,-104(s0)
    800066fa:	00000097          	auipc	ra,0x0
    800066fe:	d6c080e7          	jalr	-660(ra) # 80006466 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006702:	0001f597          	auipc	a1,0x1f
    80006706:	a2658593          	addi	a1,a1,-1498 # 80025128 <disk+0x2128>
    8000670a:	0001f517          	auipc	a0,0x1f
    8000670e:	90e50513          	addi	a0,a0,-1778 # 80025018 <disk+0x2018>
    80006712:	ffffc097          	auipc	ra,0xffffc
    80006716:	046080e7          	jalr	70(ra) # 80002758 <sleep>
  for(int i = 0; i < 3; i++){
    8000671a:	f9040713          	addi	a4,s0,-112
    8000671e:	84ce                	mv	s1,s3
    80006720:	bf41                	j	800066b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006722:	20058713          	addi	a4,a1,512
    80006726:	00471693          	slli	a3,a4,0x4
    8000672a:	0001d717          	auipc	a4,0x1d
    8000672e:	8d670713          	addi	a4,a4,-1834 # 80023000 <disk>
    80006732:	9736                	add	a4,a4,a3
    80006734:	4685                	li	a3,1
    80006736:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000673a:	20058713          	addi	a4,a1,512
    8000673e:	00471693          	slli	a3,a4,0x4
    80006742:	0001d717          	auipc	a4,0x1d
    80006746:	8be70713          	addi	a4,a4,-1858 # 80023000 <disk>
    8000674a:	9736                	add	a4,a4,a3
    8000674c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006750:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006754:	7679                	lui	a2,0xffffe
    80006756:	963e                	add	a2,a2,a5
    80006758:	0001f697          	auipc	a3,0x1f
    8000675c:	8a868693          	addi	a3,a3,-1880 # 80025000 <disk+0x2000>
    80006760:	6298                	ld	a4,0(a3)
    80006762:	9732                	add	a4,a4,a2
    80006764:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006766:	6298                	ld	a4,0(a3)
    80006768:	9732                	add	a4,a4,a2
    8000676a:	4541                	li	a0,16
    8000676c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000676e:	6298                	ld	a4,0(a3)
    80006770:	9732                	add	a4,a4,a2
    80006772:	4505                	li	a0,1
    80006774:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006778:	f9442703          	lw	a4,-108(s0)
    8000677c:	6288                	ld	a0,0(a3)
    8000677e:	962a                	add	a2,a2,a0
    80006780:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006784:	0712                	slli	a4,a4,0x4
    80006786:	6290                	ld	a2,0(a3)
    80006788:	963a                	add	a2,a2,a4
    8000678a:	05890513          	addi	a0,s2,88
    8000678e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006790:	6294                	ld	a3,0(a3)
    80006792:	96ba                	add	a3,a3,a4
    80006794:	40000613          	li	a2,1024
    80006798:	c690                	sw	a2,8(a3)
  if(write)
    8000679a:	140d0063          	beqz	s10,800068da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000679e:	0001f697          	auipc	a3,0x1f
    800067a2:	8626b683          	ld	a3,-1950(a3) # 80025000 <disk+0x2000>
    800067a6:	96ba                	add	a3,a3,a4
    800067a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067ac:	0001d817          	auipc	a6,0x1d
    800067b0:	85480813          	addi	a6,a6,-1964 # 80023000 <disk>
    800067b4:	0001f517          	auipc	a0,0x1f
    800067b8:	84c50513          	addi	a0,a0,-1972 # 80025000 <disk+0x2000>
    800067bc:	6114                	ld	a3,0(a0)
    800067be:	96ba                	add	a3,a3,a4
    800067c0:	00c6d603          	lhu	a2,12(a3)
    800067c4:	00166613          	ori	a2,a2,1
    800067c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800067cc:	f9842683          	lw	a3,-104(s0)
    800067d0:	6110                	ld	a2,0(a0)
    800067d2:	9732                	add	a4,a4,a2
    800067d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067d8:	20058613          	addi	a2,a1,512
    800067dc:	0612                	slli	a2,a2,0x4
    800067de:	9642                	add	a2,a2,a6
    800067e0:	577d                	li	a4,-1
    800067e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067e6:	00469713          	slli	a4,a3,0x4
    800067ea:	6114                	ld	a3,0(a0)
    800067ec:	96ba                	add	a3,a3,a4
    800067ee:	03078793          	addi	a5,a5,48
    800067f2:	97c2                	add	a5,a5,a6
    800067f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800067f6:	611c                	ld	a5,0(a0)
    800067f8:	97ba                	add	a5,a5,a4
    800067fa:	4685                	li	a3,1
    800067fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067fe:	611c                	ld	a5,0(a0)
    80006800:	97ba                	add	a5,a5,a4
    80006802:	4809                	li	a6,2
    80006804:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006808:	611c                	ld	a5,0(a0)
    8000680a:	973e                	add	a4,a4,a5
    8000680c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006810:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006814:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006818:	6518                	ld	a4,8(a0)
    8000681a:	00275783          	lhu	a5,2(a4)
    8000681e:	8b9d                	andi	a5,a5,7
    80006820:	0786                	slli	a5,a5,0x1
    80006822:	97ba                	add	a5,a5,a4
    80006824:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006828:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000682c:	6518                	ld	a4,8(a0)
    8000682e:	00275783          	lhu	a5,2(a4)
    80006832:	2785                	addiw	a5,a5,1
    80006834:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006838:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000683c:	100017b7          	lui	a5,0x10001
    80006840:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006844:	00492703          	lw	a4,4(s2)
    80006848:	4785                	li	a5,1
    8000684a:	02f71163          	bne	a4,a5,8000686c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000684e:	0001f997          	auipc	s3,0x1f
    80006852:	8da98993          	addi	s3,s3,-1830 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006856:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006858:	85ce                	mv	a1,s3
    8000685a:	854a                	mv	a0,s2
    8000685c:	ffffc097          	auipc	ra,0xffffc
    80006860:	efc080e7          	jalr	-260(ra) # 80002758 <sleep>
  while(b->disk == 1) {
    80006864:	00492783          	lw	a5,4(s2)
    80006868:	fe9788e3          	beq	a5,s1,80006858 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000686c:	f9042903          	lw	s2,-112(s0)
    80006870:	20090793          	addi	a5,s2,512
    80006874:	00479713          	slli	a4,a5,0x4
    80006878:	0001c797          	auipc	a5,0x1c
    8000687c:	78878793          	addi	a5,a5,1928 # 80023000 <disk>
    80006880:	97ba                	add	a5,a5,a4
    80006882:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006886:	0001e997          	auipc	s3,0x1e
    8000688a:	77a98993          	addi	s3,s3,1914 # 80025000 <disk+0x2000>
    8000688e:	00491713          	slli	a4,s2,0x4
    80006892:	0009b783          	ld	a5,0(s3)
    80006896:	97ba                	add	a5,a5,a4
    80006898:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000689c:	854a                	mv	a0,s2
    8000689e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800068a2:	00000097          	auipc	ra,0x0
    800068a6:	bc4080e7          	jalr	-1084(ra) # 80006466 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068aa:	8885                	andi	s1,s1,1
    800068ac:	f0ed                	bnez	s1,8000688e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800068ae:	0001f517          	auipc	a0,0x1f
    800068b2:	87a50513          	addi	a0,a0,-1926 # 80025128 <disk+0x2128>
    800068b6:	ffffa097          	auipc	ra,0xffffa
    800068ba:	3e2080e7          	jalr	994(ra) # 80000c98 <release>
}
    800068be:	70a6                	ld	ra,104(sp)
    800068c0:	7406                	ld	s0,96(sp)
    800068c2:	64e6                	ld	s1,88(sp)
    800068c4:	6946                	ld	s2,80(sp)
    800068c6:	69a6                	ld	s3,72(sp)
    800068c8:	6a06                	ld	s4,64(sp)
    800068ca:	7ae2                	ld	s5,56(sp)
    800068cc:	7b42                	ld	s6,48(sp)
    800068ce:	7ba2                	ld	s7,40(sp)
    800068d0:	7c02                	ld	s8,32(sp)
    800068d2:	6ce2                	ld	s9,24(sp)
    800068d4:	6d42                	ld	s10,16(sp)
    800068d6:	6165                	addi	sp,sp,112
    800068d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800068da:	0001e697          	auipc	a3,0x1e
    800068de:	7266b683          	ld	a3,1830(a3) # 80025000 <disk+0x2000>
    800068e2:	96ba                	add	a3,a3,a4
    800068e4:	4609                	li	a2,2
    800068e6:	00c69623          	sh	a2,12(a3)
    800068ea:	b5c9                	j	800067ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068ec:	f9042583          	lw	a1,-112(s0)
    800068f0:	20058793          	addi	a5,a1,512
    800068f4:	0792                	slli	a5,a5,0x4
    800068f6:	0001c517          	auipc	a0,0x1c
    800068fa:	7b250513          	addi	a0,a0,1970 # 800230a8 <disk+0xa8>
    800068fe:	953e                	add	a0,a0,a5
  if(write)
    80006900:	e20d11e3          	bnez	s10,80006722 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006904:	20058713          	addi	a4,a1,512
    80006908:	00471693          	slli	a3,a4,0x4
    8000690c:	0001c717          	auipc	a4,0x1c
    80006910:	6f470713          	addi	a4,a4,1780 # 80023000 <disk>
    80006914:	9736                	add	a4,a4,a3
    80006916:	0a072423          	sw	zero,168(a4)
    8000691a:	b505                	j	8000673a <virtio_disk_rw+0xf4>

000000008000691c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000691c:	1101                	addi	sp,sp,-32
    8000691e:	ec06                	sd	ra,24(sp)
    80006920:	e822                	sd	s0,16(sp)
    80006922:	e426                	sd	s1,8(sp)
    80006924:	e04a                	sd	s2,0(sp)
    80006926:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006928:	0001f517          	auipc	a0,0x1f
    8000692c:	80050513          	addi	a0,a0,-2048 # 80025128 <disk+0x2128>
    80006930:	ffffa097          	auipc	ra,0xffffa
    80006934:	2b4080e7          	jalr	692(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006938:	10001737          	lui	a4,0x10001
    8000693c:	533c                	lw	a5,96(a4)
    8000693e:	8b8d                	andi	a5,a5,3
    80006940:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006942:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006946:	0001e797          	auipc	a5,0x1e
    8000694a:	6ba78793          	addi	a5,a5,1722 # 80025000 <disk+0x2000>
    8000694e:	6b94                	ld	a3,16(a5)
    80006950:	0207d703          	lhu	a4,32(a5)
    80006954:	0026d783          	lhu	a5,2(a3)
    80006958:	06f70163          	beq	a4,a5,800069ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000695c:	0001c917          	auipc	s2,0x1c
    80006960:	6a490913          	addi	s2,s2,1700 # 80023000 <disk>
    80006964:	0001e497          	auipc	s1,0x1e
    80006968:	69c48493          	addi	s1,s1,1692 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000696c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006970:	6898                	ld	a4,16(s1)
    80006972:	0204d783          	lhu	a5,32(s1)
    80006976:	8b9d                	andi	a5,a5,7
    80006978:	078e                	slli	a5,a5,0x3
    8000697a:	97ba                	add	a5,a5,a4
    8000697c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000697e:	20078713          	addi	a4,a5,512
    80006982:	0712                	slli	a4,a4,0x4
    80006984:	974a                	add	a4,a4,s2
    80006986:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000698a:	e731                	bnez	a4,800069d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000698c:	20078793          	addi	a5,a5,512
    80006990:	0792                	slli	a5,a5,0x4
    80006992:	97ca                	add	a5,a5,s2
    80006994:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006996:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000699a:	ffffc097          	auipc	ra,0xffffc
    8000699e:	f54080e7          	jalr	-172(ra) # 800028ee <wakeup>

    disk.used_idx += 1;
    800069a2:	0204d783          	lhu	a5,32(s1)
    800069a6:	2785                	addiw	a5,a5,1
    800069a8:	17c2                	slli	a5,a5,0x30
    800069aa:	93c1                	srli	a5,a5,0x30
    800069ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800069b0:	6898                	ld	a4,16(s1)
    800069b2:	00275703          	lhu	a4,2(a4)
    800069b6:	faf71be3          	bne	a4,a5,8000696c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800069ba:	0001e517          	auipc	a0,0x1e
    800069be:	76e50513          	addi	a0,a0,1902 # 80025128 <disk+0x2128>
    800069c2:	ffffa097          	auipc	ra,0xffffa
    800069c6:	2d6080e7          	jalr	726(ra) # 80000c98 <release>
}
    800069ca:	60e2                	ld	ra,24(sp)
    800069cc:	6442                	ld	s0,16(sp)
    800069ce:	64a2                	ld	s1,8(sp)
    800069d0:	6902                	ld	s2,0(sp)
    800069d2:	6105                	addi	sp,sp,32
    800069d4:	8082                	ret
      panic("virtio_disk_intr status");
    800069d6:	00002517          	auipc	a0,0x2
    800069da:	efa50513          	addi	a0,a0,-262 # 800088d0 <syscalls+0x3c8>
    800069de:	ffffa097          	auipc	ra,0xffffa
    800069e2:	b60080e7          	jalr	-1184(ra) # 8000053e <panic>
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
