
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
    80000068:	2fc78793          	addi	a5,a5,764 # 80006360 <timervec>
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
    80000130:	b22080e7          	jalr	-1246(ra) # 80002c4e <either_copyin>
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
    800001c8:	a32080e7          	jalr	-1486(ra) # 80001bf6 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	566080e7          	jalr	1382(ra) # 8000273a <sleep>
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
    80000214:	9e8080e7          	jalr	-1560(ra) # 80002bf8 <either_copyout>
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
    800002f6:	9b2080e7          	jalr	-1614(ra) # 80002ca4 <procdump>
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
    8000044a:	480080e7          	jalr	1152(ra) # 800028c6 <wakeup>
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
    800008a4:	026080e7          	jalr	38(ra) # 800028c6 <wakeup>
    
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
    80000930:	e0e080e7          	jalr	-498(ra) # 8000273a <sleep>
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
    80000b82:	05c080e7          	jalr	92(ra) # 80001bda <mycpu>
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
    80000bb4:	02a080e7          	jalr	42(ra) # 80001bda <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	01e080e7          	jalr	30(ra) # 80001bda <mycpu>
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
    80000bd8:	006080e7          	jalr	6(ra) # 80001bda <mycpu>
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
    80000c18:	fc6080e7          	jalr	-58(ra) # 80001bda <mycpu>
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
    80000c44:	f9a080e7          	jalr	-102(ra) # 80001bda <mycpu>
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
    80000eac:	132080e7          	jalr	306(ra) # 80001fda <fork>
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	12a080e7          	jalr	298(ra) # 80001fda <fork>
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
    80000efa:	7a2080e7          	jalr	1954(ra) # 80002698 <pause_system>
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
    80000f3e:	0a0080e7          	jalr	160(ra) # 80001fda <fork>
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	098080e7          	jalr	152(ra) # 80001fda <fork>
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
    80000f8a:	c28080e7          	jalr	-984(ra) # 80002bae <kill_system>
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
    80000fbe:	c10080e7          	jalr	-1008(ra) # 80001bca <cpuid>
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
    80000fda:	bf4080e7          	jalr	-1036(ra) # 80001bca <cpuid>
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
    80000ffc:	dec080e7          	jalr	-532(ra) # 80002de4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001000:	00005097          	auipc	ra,0x5
    80001004:	3a0080e7          	jalr	928(ra) # 800063a0 <plicinithart>
  }

  scheduler();    
    80001008:	00001097          	auipc	ra,0x1
    8000100c:	564080e7          	jalr	1380(ra) # 8000256c <scheduler>
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
    8000106c:	a9a080e7          	jalr	-1382(ra) # 80001b02 <procinit>
    trapinit();      // trap vectors
    80001070:	00002097          	auipc	ra,0x2
    80001074:	d4c080e7          	jalr	-692(ra) # 80002dbc <trapinit>
    trapinithart();  // install kernel trap vector
    80001078:	00002097          	auipc	ra,0x2
    8000107c:	d6c080e7          	jalr	-660(ra) # 80002de4 <trapinithart>
    plicinit();      // set up interrupt controller
    80001080:	00005097          	auipc	ra,0x5
    80001084:	30a080e7          	jalr	778(ra) # 8000638a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001088:	00005097          	auipc	ra,0x5
    8000108c:	318080e7          	jalr	792(ra) # 800063a0 <plicinithart>
    binit();         // buffer cache
    80001090:	00002097          	auipc	ra,0x2
    80001094:	4f8080e7          	jalr	1272(ra) # 80003588 <binit>
    iinit();         // inode table
    80001098:	00003097          	auipc	ra,0x3
    8000109c:	b88080e7          	jalr	-1144(ra) # 80003c20 <iinit>
    fileinit();      // file table
    800010a0:	00004097          	auipc	ra,0x4
    800010a4:	b32080e7          	jalr	-1230(ra) # 80004bd2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a8:	00005097          	auipc	ra,0x5
    800010ac:	41a080e7          	jalr	1050(ra) # 800064c2 <virtio_disk_init>
    userinit();      // first user process
    800010b0:	00001097          	auipc	ra,0x1
    800010b4:	e2a080e7          	jalr	-470(ra) # 80001eda <userinit>
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
    80001368:	708080e7          	jalr	1800(ra) # 80001a6c <proc_mapstacks>
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
    800019c8:	1141                	addi	sp,sp,-16
    800019ca:	e422                	sd	s0,8(sp)
    800019cc:	0800                	addi	s0,sp,16
  p->state = RUNNABLE;
    800019ce:	478d                	li	a5,3
    800019d0:	cd1c                	sw	a5,24(a0)
  p->last_runnable_time = ticks;
    800019d2:	00007797          	auipc	a5,0x7
    800019d6:	6867a783          	lw	a5,1670(a5) # 80009058 <ticks>
    800019da:	c53c                	sw	a5,72(a0)
}
    800019dc:	6422                	ld	s0,8(sp)
    800019de:	0141                	addi	sp,sp,16
    800019e0:	8082                	ret

00000000800019e2 <print_stats>:

  return 0;
}

int print_stats(void)
{
    800019e2:	1141                	addi	sp,sp,-16
    800019e4:	e406                	sd	ra,8(sp)
    800019e6:	e022                	sd	s0,0(sp)
    800019e8:	0800                	addi	s0,sp,16
  printf("sleeping_processes_mean: %d\n", sleeping_processes_mean);
    800019ea:	00007597          	auipc	a1,0x7
    800019ee:	65e5a583          	lw	a1,1630(a1) # 80009048 <sleeping_processes_mean>
    800019f2:	00007517          	auipc	a0,0x7
    800019f6:	82650513          	addi	a0,a0,-2010 # 80008218 <digits+0x1d8>
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	b8e080e7          	jalr	-1138(ra) # 80000588 <printf>
  printf("runnable_time_mean: %d\n", runnable_time_mean);
    80001a02:	00007597          	auipc	a1,0x7
    80001a06:	6425a583          	lw	a1,1602(a1) # 80009044 <runnable_time_mean>
    80001a0a:	00007517          	auipc	a0,0x7
    80001a0e:	82e50513          	addi	a0,a0,-2002 # 80008238 <digits+0x1f8>
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	b76080e7          	jalr	-1162(ra) # 80000588 <printf>
  printf("running_time_count: %d\n", running_time_count);
    80001a1a:	00007597          	auipc	a1,0x7
    80001a1e:	61a5a583          	lw	a1,1562(a1) # 80009034 <running_time_count>
    80001a22:	00007517          	auipc	a0,0x7
    80001a26:	82e50513          	addi	a0,a0,-2002 # 80008250 <digits+0x210>
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	b5e080e7          	jalr	-1186(ra) # 80000588 <printf>
  printf("program_time: %d\n", program_time);
    80001a32:	00007597          	auipc	a1,0x7
    80001a36:	5fe5a583          	lw	a1,1534(a1) # 80009030 <program_time>
    80001a3a:	00007517          	auipc	a0,0x7
    80001a3e:	82e50513          	addi	a0,a0,-2002 # 80008268 <digits+0x228>
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	b46080e7          	jalr	-1210(ra) # 80000588 <printf>
  printf("cpu_utilization: %d\n", cpu_utilization);
    80001a4a:	00007597          	auipc	a1,0x7
    80001a4e:	5e25a583          	lw	a1,1506(a1) # 8000902c <cpu_utilization>
    80001a52:	00007517          	auipc	a0,0x7
    80001a56:	82e50513          	addi	a0,a0,-2002 # 80008280 <digits+0x240>
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	b2e080e7          	jalr	-1234(ra) # 80000588 <printf>

  return 0;
}
    80001a62:	4501                	li	a0,0
    80001a64:	60a2                	ld	ra,8(sp)
    80001a66:	6402                	ld	s0,0(sp)
    80001a68:	0141                	addi	sp,sp,16
    80001a6a:	8082                	ret

0000000080001a6c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001a6c:	7139                	addi	sp,sp,-64
    80001a6e:	fc06                	sd	ra,56(sp)
    80001a70:	f822                	sd	s0,48(sp)
    80001a72:	f426                	sd	s1,40(sp)
    80001a74:	f04a                	sd	s2,32(sp)
    80001a76:	ec4e                	sd	s3,24(sp)
    80001a78:	e852                	sd	s4,16(sp)
    80001a7a:	e456                	sd	s5,8(sp)
    80001a7c:	e05a                	sd	s6,0(sp)
    80001a7e:	0080                	addi	s0,sp,64
    80001a80:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a82:	00010497          	auipc	s1,0x10
    80001a86:	c6e48493          	addi	s1,s1,-914 # 800116f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001a8a:	8b26                	mv	s6,s1
    80001a8c:	00006a97          	auipc	s5,0x6
    80001a90:	574a8a93          	addi	s5,s5,1396 # 80008000 <etext>
    80001a94:	04000937          	lui	s2,0x4000
    80001a98:	197d                	addi	s2,s2,-1
    80001a9a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a9c:	00016a17          	auipc	s4,0x16
    80001aa0:	e54a0a13          	addi	s4,s4,-428 # 800178f0 <tickslock>
    char *pa = kalloc();
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	050080e7          	jalr	80(ra) # 80000af4 <kalloc>
    80001aac:	862a                	mv	a2,a0
    if(pa == 0)
    80001aae:	c131                	beqz	a0,80001af2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001ab0:	416485b3          	sub	a1,s1,s6
    80001ab4:	858d                	srai	a1,a1,0x3
    80001ab6:	000ab783          	ld	a5,0(s5)
    80001aba:	02f585b3          	mul	a1,a1,a5
    80001abe:	2585                	addiw	a1,a1,1
    80001ac0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ac4:	4719                	li	a4,6
    80001ac6:	6685                	lui	a3,0x1
    80001ac8:	40b905b3          	sub	a1,s2,a1
    80001acc:	854e                	mv	a0,s3
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	7a6080e7          	jalr	1958(ra) # 80001274 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad6:	18848493          	addi	s1,s1,392
    80001ada:	fd4495e3          	bne	s1,s4,80001aa4 <proc_mapstacks+0x38>
  }
}
    80001ade:	70e2                	ld	ra,56(sp)
    80001ae0:	7442                	ld	s0,48(sp)
    80001ae2:	74a2                	ld	s1,40(sp)
    80001ae4:	7902                	ld	s2,32(sp)
    80001ae6:	69e2                	ld	s3,24(sp)
    80001ae8:	6a42                	ld	s4,16(sp)
    80001aea:	6aa2                	ld	s5,8(sp)
    80001aec:	6b02                	ld	s6,0(sp)
    80001aee:	6121                	addi	sp,sp,64
    80001af0:	8082                	ret
      panic("kalloc");
    80001af2:	00006517          	auipc	a0,0x6
    80001af6:	7a650513          	addi	a0,a0,1958 # 80008298 <digits+0x258>
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	a44080e7          	jalr	-1468(ra) # 8000053e <panic>

0000000080001b02 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b02:	7139                	addi	sp,sp,-64
    80001b04:	fc06                	sd	ra,56(sp)
    80001b06:	f822                	sd	s0,48(sp)
    80001b08:	f426                	sd	s1,40(sp)
    80001b0a:	f04a                	sd	s2,32(sp)
    80001b0c:	ec4e                	sd	s3,24(sp)
    80001b0e:	e852                	sd	s4,16(sp)
    80001b10:	e456                	sd	s5,8(sp)
    80001b12:	e05a                	sd	s6,0(sp)
    80001b14:	0080                	addi	s0,sp,64
  struct proc *p;
  cpu_utilization = ticks;
    80001b16:	00007797          	auipc	a5,0x7
    80001b1a:	5427a783          	lw	a5,1346(a5) # 80009058 <ticks>
    80001b1e:	00007717          	auipc	a4,0x7
    80001b22:	50f72723          	sw	a5,1294(a4) # 8000902c <cpu_utilization>
  start_time = ticks;
    80001b26:	00007717          	auipc	a4,0x7
    80001b2a:	50f72123          	sw	a5,1282(a4) # 80009028 <start_time>
  
  initlock(&pid_lock, "nextpid");
    80001b2e:	00006597          	auipc	a1,0x6
    80001b32:	77258593          	addi	a1,a1,1906 # 800082a0 <digits+0x260>
    80001b36:	0000f517          	auipc	a0,0xf
    80001b3a:	78a50513          	addi	a0,a0,1930 # 800112c0 <pid_lock>
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	016080e7          	jalr	22(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b46:	00006597          	auipc	a1,0x6
    80001b4a:	76258593          	addi	a1,a1,1890 # 800082a8 <digits+0x268>
    80001b4e:	0000f517          	auipc	a0,0xf
    80001b52:	78a50513          	addi	a0,a0,1930 # 800112d8 <wait_lock>
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	ffe080e7          	jalr	-2(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b5e:	00010497          	auipc	s1,0x10
    80001b62:	b9248493          	addi	s1,s1,-1134 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001b66:	00006b17          	auipc	s6,0x6
    80001b6a:	752b0b13          	addi	s6,s6,1874 # 800082b8 <digits+0x278>
      p->kstack = KSTACK((int) (p - proc));
    80001b6e:	8aa6                	mv	s5,s1
    80001b70:	00006a17          	auipc	s4,0x6
    80001b74:	490a0a13          	addi	s4,s4,1168 # 80008000 <etext>
    80001b78:	04000937          	lui	s2,0x4000
    80001b7c:	197d                	addi	s2,s2,-1
    80001b7e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b80:	00016997          	auipc	s3,0x16
    80001b84:	d7098993          	addi	s3,s3,-656 # 800178f0 <tickslock>
      initlock(&p->lock, "proc");
    80001b88:	85da                	mv	a1,s6
    80001b8a:	8526                	mv	a0,s1
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	fc8080e7          	jalr	-56(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001b94:	415487b3          	sub	a5,s1,s5
    80001b98:	878d                	srai	a5,a5,0x3
    80001b9a:	000a3703          	ld	a4,0(s4)
    80001b9e:	02e787b3          	mul	a5,a5,a4
    80001ba2:	2785                	addiw	a5,a5,1
    80001ba4:	00d7979b          	slliw	a5,a5,0xd
    80001ba8:	40f907b3          	sub	a5,s2,a5
    80001bac:	f0bc                	sd	a5,96(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bae:	18848493          	addi	s1,s1,392
    80001bb2:	fd349be3          	bne	s1,s3,80001b88 <procinit+0x86>
  }
}
    80001bb6:	70e2                	ld	ra,56(sp)
    80001bb8:	7442                	ld	s0,48(sp)
    80001bba:	74a2                	ld	s1,40(sp)
    80001bbc:	7902                	ld	s2,32(sp)
    80001bbe:	69e2                	ld	s3,24(sp)
    80001bc0:	6a42                	ld	s4,16(sp)
    80001bc2:	6aa2                	ld	s5,8(sp)
    80001bc4:	6b02                	ld	s6,0(sp)
    80001bc6:	6121                	addi	sp,sp,64
    80001bc8:	8082                	ret

0000000080001bca <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001bca:	1141                	addi	sp,sp,-16
    80001bcc:	e422                	sd	s0,8(sp)
    80001bce:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bd0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001bd2:	2501                	sext.w	a0,a0
    80001bd4:	6422                	ld	s0,8(sp)
    80001bd6:	0141                	addi	sp,sp,16
    80001bd8:	8082                	ret

0000000080001bda <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001bda:	1141                	addi	sp,sp,-16
    80001bdc:	e422                	sd	s0,8(sp)
    80001bde:	0800                	addi	s0,sp,16
    80001be0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001be2:	2781                	sext.w	a5,a5
    80001be4:	079e                	slli	a5,a5,0x7
  return c;
}
    80001be6:	0000f517          	auipc	a0,0xf
    80001bea:	70a50513          	addi	a0,a0,1802 # 800112f0 <cpus>
    80001bee:	953e                	add	a0,a0,a5
    80001bf0:	6422                	ld	s0,8(sp)
    80001bf2:	0141                	addi	sp,sp,16
    80001bf4:	8082                	ret

0000000080001bf6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001bf6:	1101                	addi	sp,sp,-32
    80001bf8:	ec06                	sd	ra,24(sp)
    80001bfa:	e822                	sd	s0,16(sp)
    80001bfc:	e426                	sd	s1,8(sp)
    80001bfe:	1000                	addi	s0,sp,32
  push_off();
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	f98080e7          	jalr	-104(ra) # 80000b98 <push_off>
    80001c08:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c0a:	2781                	sext.w	a5,a5
    80001c0c:	079e                	slli	a5,a5,0x7
    80001c0e:	0000f717          	auipc	a4,0xf
    80001c12:	6b270713          	addi	a4,a4,1714 # 800112c0 <pid_lock>
    80001c16:	97ba                	add	a5,a5,a4
    80001c18:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	01e080e7          	jalr	30(ra) # 80000c38 <pop_off>
  return p;
}
    80001c22:	8526                	mv	a0,s1
    80001c24:	60e2                	ld	ra,24(sp)
    80001c26:	6442                	ld	s0,16(sp)
    80001c28:	64a2                	ld	s1,8(sp)
    80001c2a:	6105                	addi	sp,sp,32
    80001c2c:	8082                	ret

0000000080001c2e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c2e:	1141                	addi	sp,sp,-16
    80001c30:	e406                	sd	ra,8(sp)
    80001c32:	e022                	sd	s0,0(sp)
    80001c34:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c36:	00000097          	auipc	ra,0x0
    80001c3a:	fc0080e7          	jalr	-64(ra) # 80001bf6 <myproc>
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	05a080e7          	jalr	90(ra) # 80000c98 <release>

  if (first) {
    80001c46:	00007797          	auipc	a5,0x7
    80001c4a:	caa7a783          	lw	a5,-854(a5) # 800088f0 <first.1758>
    80001c4e:	eb89                	bnez	a5,80001c60 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c50:	00001097          	auipc	ra,0x1
    80001c54:	1ac080e7          	jalr	428(ra) # 80002dfc <usertrapret>
}
    80001c58:	60a2                	ld	ra,8(sp)
    80001c5a:	6402                	ld	s0,0(sp)
    80001c5c:	0141                	addi	sp,sp,16
    80001c5e:	8082                	ret
    first = 0;
    80001c60:	00007797          	auipc	a5,0x7
    80001c64:	c807a823          	sw	zero,-880(a5) # 800088f0 <first.1758>
    fsinit(ROOTDEV);
    80001c68:	4505                	li	a0,1
    80001c6a:	00002097          	auipc	ra,0x2
    80001c6e:	f36080e7          	jalr	-202(ra) # 80003ba0 <fsinit>
    80001c72:	bff9                	j	80001c50 <forkret+0x22>

0000000080001c74 <allocpid>:
allocpid() {
    80001c74:	1101                	addi	sp,sp,-32
    80001c76:	ec06                	sd	ra,24(sp)
    80001c78:	e822                	sd	s0,16(sp)
    80001c7a:	e426                	sd	s1,8(sp)
    80001c7c:	e04a                	sd	s2,0(sp)
    80001c7e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c80:	0000f917          	auipc	s2,0xf
    80001c84:	64090913          	addi	s2,s2,1600 # 800112c0 <pid_lock>
    80001c88:	854a                	mv	a0,s2
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	f5a080e7          	jalr	-166(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001c92:	00007797          	auipc	a5,0x7
    80001c96:	c6678793          	addi	a5,a5,-922 # 800088f8 <nextpid>
    80001c9a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c9c:	0014871b          	addiw	a4,s1,1
    80001ca0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ca2:	854a                	mv	a0,s2
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	ff4080e7          	jalr	-12(ra) # 80000c98 <release>
}
    80001cac:	8526                	mv	a0,s1
    80001cae:	60e2                	ld	ra,24(sp)
    80001cb0:	6442                	ld	s0,16(sp)
    80001cb2:	64a2                	ld	s1,8(sp)
    80001cb4:	6902                	ld	s2,0(sp)
    80001cb6:	6105                	addi	sp,sp,32
    80001cb8:	8082                	ret

0000000080001cba <proc_pagetable>:
{
    80001cba:	1101                	addi	sp,sp,-32
    80001cbc:	ec06                	sd	ra,24(sp)
    80001cbe:	e822                	sd	s0,16(sp)
    80001cc0:	e426                	sd	s1,8(sp)
    80001cc2:	e04a                	sd	s2,0(sp)
    80001cc4:	1000                	addi	s0,sp,32
    80001cc6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	796080e7          	jalr	1942(ra) # 8000145e <uvmcreate>
    80001cd0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001cd2:	c121                	beqz	a0,80001d12 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cd4:	4729                	li	a4,10
    80001cd6:	00005697          	auipc	a3,0x5
    80001cda:	32a68693          	addi	a3,a3,810 # 80007000 <_trampoline>
    80001cde:	6605                	lui	a2,0x1
    80001ce0:	040005b7          	lui	a1,0x4000
    80001ce4:	15fd                	addi	a1,a1,-1
    80001ce6:	05b2                	slli	a1,a1,0xc
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	4ec080e7          	jalr	1260(ra) # 800011d4 <mappages>
    80001cf0:	02054863          	bltz	a0,80001d20 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cf4:	4719                	li	a4,6
    80001cf6:	07893683          	ld	a3,120(s2)
    80001cfa:	6605                	lui	a2,0x1
    80001cfc:	020005b7          	lui	a1,0x2000
    80001d00:	15fd                	addi	a1,a1,-1
    80001d02:	05b6                	slli	a1,a1,0xd
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	4ce080e7          	jalr	1230(ra) # 800011d4 <mappages>
    80001d0e:	02054163          	bltz	a0,80001d30 <proc_pagetable+0x76>
}
    80001d12:	8526                	mv	a0,s1
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6902                	ld	s2,0(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret
    uvmfree(pagetable, 0);
    80001d20:	4581                	li	a1,0
    80001d22:	8526                	mv	a0,s1
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	936080e7          	jalr	-1738(ra) # 8000165a <uvmfree>
    return 0;
    80001d2c:	4481                	li	s1,0
    80001d2e:	b7d5                	j	80001d12 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d30:	4681                	li	a3,0
    80001d32:	4605                	li	a2,1
    80001d34:	040005b7          	lui	a1,0x4000
    80001d38:	15fd                	addi	a1,a1,-1
    80001d3a:	05b2                	slli	a1,a1,0xc
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	65c080e7          	jalr	1628(ra) # 8000139a <uvmunmap>
    uvmfree(pagetable, 0);
    80001d46:	4581                	li	a1,0
    80001d48:	8526                	mv	a0,s1
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	910080e7          	jalr	-1776(ra) # 8000165a <uvmfree>
    return 0;
    80001d52:	4481                	li	s1,0
    80001d54:	bf7d                	j	80001d12 <proc_pagetable+0x58>

0000000080001d56 <proc_freepagetable>:
{
    80001d56:	1101                	addi	sp,sp,-32
    80001d58:	ec06                	sd	ra,24(sp)
    80001d5a:	e822                	sd	s0,16(sp)
    80001d5c:	e426                	sd	s1,8(sp)
    80001d5e:	e04a                	sd	s2,0(sp)
    80001d60:	1000                	addi	s0,sp,32
    80001d62:	84aa                	mv	s1,a0
    80001d64:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d66:	4681                	li	a3,0
    80001d68:	4605                	li	a2,1
    80001d6a:	040005b7          	lui	a1,0x4000
    80001d6e:	15fd                	addi	a1,a1,-1
    80001d70:	05b2                	slli	a1,a1,0xc
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	628080e7          	jalr	1576(ra) # 8000139a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d7a:	4681                	li	a3,0
    80001d7c:	4605                	li	a2,1
    80001d7e:	020005b7          	lui	a1,0x2000
    80001d82:	15fd                	addi	a1,a1,-1
    80001d84:	05b6                	slli	a1,a1,0xd
    80001d86:	8526                	mv	a0,s1
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	612080e7          	jalr	1554(ra) # 8000139a <uvmunmap>
  uvmfree(pagetable, sz);
    80001d90:	85ca                	mv	a1,s2
    80001d92:	8526                	mv	a0,s1
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	8c6080e7          	jalr	-1850(ra) # 8000165a <uvmfree>
}
    80001d9c:	60e2                	ld	ra,24(sp)
    80001d9e:	6442                	ld	s0,16(sp)
    80001da0:	64a2                	ld	s1,8(sp)
    80001da2:	6902                	ld	s2,0(sp)
    80001da4:	6105                	addi	sp,sp,32
    80001da6:	8082                	ret

0000000080001da8 <freeproc>:
{
    80001da8:	1101                	addi	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	1000                	addi	s0,sp,32
    80001db2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001db4:	7d28                	ld	a0,120(a0)
    80001db6:	c509                	beqz	a0,80001dc0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	c40080e7          	jalr	-960(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001dc0:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001dc4:	78a8                	ld	a0,112(s1)
    80001dc6:	c511                	beqz	a0,80001dd2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001dc8:	74ac                	ld	a1,104(s1)
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	f8c080e7          	jalr	-116(ra) # 80001d56 <proc_freepagetable>
  p->pagetable = 0;
    80001dd2:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001dd6:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001dda:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001dde:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001de2:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001de6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001dea:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001dee:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001df2:	0004ac23          	sw	zero,24(s1)
}
    80001df6:	60e2                	ld	ra,24(sp)
    80001df8:	6442                	ld	s0,16(sp)
    80001dfa:	64a2                	ld	s1,8(sp)
    80001dfc:	6105                	addi	sp,sp,32
    80001dfe:	8082                	ret

0000000080001e00 <allocproc>:
{
    80001e00:	1101                	addi	sp,sp,-32
    80001e02:	ec06                	sd	ra,24(sp)
    80001e04:	e822                	sd	s0,16(sp)
    80001e06:	e426                	sd	s1,8(sp)
    80001e08:	e04a                	sd	s2,0(sp)
    80001e0a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e0c:	00010497          	auipc	s1,0x10
    80001e10:	8e448493          	addi	s1,s1,-1820 # 800116f0 <proc>
    80001e14:	00016917          	auipc	s2,0x16
    80001e18:	adc90913          	addi	s2,s2,-1316 # 800178f0 <tickslock>
    acquire(&p->lock);
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	dc6080e7          	jalr	-570(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001e26:	4c9c                	lw	a5,24(s1)
    80001e28:	cf81                	beqz	a5,80001e40 <allocproc+0x40>
      release(&p->lock);
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	e6c080e7          	jalr	-404(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e34:	18848493          	addi	s1,s1,392
    80001e38:	ff2492e3          	bne	s1,s2,80001e1c <allocproc+0x1c>
  return 0;
    80001e3c:	4481                	li	s1,0
    80001e3e:	a8b9                	j	80001e9c <allocproc+0x9c>
  p->pid = allocpid();
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	e34080e7          	jalr	-460(ra) # 80001c74 <allocpid>
    80001e48:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e4a:	4785                	li	a5,1
    80001e4c:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = 0;
    80001e4e:	0404a423          	sw	zero,72(s1)
  p->mean_ticks = 0;
    80001e52:	0404a023          	sw	zero,64(s1)
  p->last_ticks = 0;
    80001e56:	0404a223          	sw	zero,68(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	c9a080e7          	jalr	-870(ra) # 80000af4 <kalloc>
    80001e62:	892a                	mv	s2,a0
    80001e64:	fca8                	sd	a0,120(s1)
    80001e66:	c131                	beqz	a0,80001eaa <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	00000097          	auipc	ra,0x0
    80001e6e:	e50080e7          	jalr	-432(ra) # 80001cba <proc_pagetable>
    80001e72:	892a                	mv	s2,a0
    80001e74:	f8a8                	sd	a0,112(s1)
  if(p->pagetable == 0){
    80001e76:	c531                	beqz	a0,80001ec2 <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001e78:	07000613          	li	a2,112
    80001e7c:	4581                	li	a1,0
    80001e7e:	08048513          	addi	a0,s1,128
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e5e080e7          	jalr	-418(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001e8a:	00000797          	auipc	a5,0x0
    80001e8e:	da478793          	addi	a5,a5,-604 # 80001c2e <forkret>
    80001e92:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e94:	70bc                	ld	a5,96(s1)
    80001e96:	6705                	lui	a4,0x1
    80001e98:	97ba                	add	a5,a5,a4
    80001e9a:	e4dc                	sd	a5,136(s1)
}
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	60e2                	ld	ra,24(sp)
    80001ea0:	6442                	ld	s0,16(sp)
    80001ea2:	64a2                	ld	s1,8(sp)
    80001ea4:	6902                	ld	s2,0(sp)
    80001ea6:	6105                	addi	sp,sp,32
    80001ea8:	8082                	ret
    freeproc(p);
    80001eaa:	8526                	mv	a0,s1
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	efc080e7          	jalr	-260(ra) # 80001da8 <freeproc>
    release(&p->lock);
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	de2080e7          	jalr	-542(ra) # 80000c98 <release>
    return 0;
    80001ebe:	84ca                	mv	s1,s2
    80001ec0:	bff1                	j	80001e9c <allocproc+0x9c>
    freeproc(p);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	00000097          	auipc	ra,0x0
    80001ec8:	ee4080e7          	jalr	-284(ra) # 80001da8 <freeproc>
    release(&p->lock);
    80001ecc:	8526                	mv	a0,s1
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	dca080e7          	jalr	-566(ra) # 80000c98 <release>
    return 0;
    80001ed6:	84ca                	mv	s1,s2
    80001ed8:	b7d1                	j	80001e9c <allocproc+0x9c>

0000000080001eda <userinit>:
{
    80001eda:	1101                	addi	sp,sp,-32
    80001edc:	ec06                	sd	ra,24(sp)
    80001ede:	e822                	sd	s0,16(sp)
    80001ee0:	e426                	sd	s1,8(sp)
    80001ee2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	f1c080e7          	jalr	-228(ra) # 80001e00 <allocproc>
    80001eec:	84aa                	mv	s1,a0
  initproc = p;
    80001eee:	00007797          	auipc	a5,0x7
    80001ef2:	16a7b123          	sd	a0,354(a5) # 80009050 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ef6:	03400613          	li	a2,52
    80001efa:	00007597          	auipc	a1,0x7
    80001efe:	a0658593          	addi	a1,a1,-1530 # 80008900 <initcode>
    80001f02:	7928                	ld	a0,112(a0)
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	588080e7          	jalr	1416(ra) # 8000148c <uvminit>
  p->sz = PGSIZE;
    80001f0c:	6785                	lui	a5,0x1
    80001f0e:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f10:	7cb8                	ld	a4,120(s1)
    80001f12:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f16:	7cb8                	ld	a4,120(s1)
    80001f18:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f1a:	4641                	li	a2,16
    80001f1c:	00006597          	auipc	a1,0x6
    80001f20:	3a458593          	addi	a1,a1,932 # 800082c0 <digits+0x280>
    80001f24:	17848513          	addi	a0,s1,376
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	f0a080e7          	jalr	-246(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001f30:	00006517          	auipc	a0,0x6
    80001f34:	3a050513          	addi	a0,a0,928 # 800082d0 <digits+0x290>
    80001f38:	00002097          	auipc	ra,0x2
    80001f3c:	696080e7          	jalr	1686(ra) # 800045ce <namei>
    80001f40:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001f44:	478d                	li	a5,3
    80001f46:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80001f48:	00007797          	auipc	a5,0x7
    80001f4c:	1107a783          	lw	a5,272(a5) # 80009058 <ticks>
    80001f50:	c4bc                	sw	a5,72(s1)
  release(&p->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d44080e7          	jalr	-700(ra) # 80000c98 <release>
}
    80001f5c:	60e2                	ld	ra,24(sp)
    80001f5e:	6442                	ld	s0,16(sp)
    80001f60:	64a2                	ld	s1,8(sp)
    80001f62:	6105                	addi	sp,sp,32
    80001f64:	8082                	ret

0000000080001f66 <growproc>:
{
    80001f66:	1101                	addi	sp,sp,-32
    80001f68:	ec06                	sd	ra,24(sp)
    80001f6a:	e822                	sd	s0,16(sp)
    80001f6c:	e426                	sd	s1,8(sp)
    80001f6e:	e04a                	sd	s2,0(sp)
    80001f70:	1000                	addi	s0,sp,32
    80001f72:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f74:	00000097          	auipc	ra,0x0
    80001f78:	c82080e7          	jalr	-894(ra) # 80001bf6 <myproc>
    80001f7c:	892a                	mv	s2,a0
  sz = p->sz;
    80001f7e:	752c                	ld	a1,104(a0)
    80001f80:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f84:	00904f63          	bgtz	s1,80001fa2 <growproc+0x3c>
  } else if(n < 0){
    80001f88:	0204cc63          	bltz	s1,80001fc0 <growproc+0x5a>
  p->sz = sz;
    80001f8c:	1602                	slli	a2,a2,0x20
    80001f8e:	9201                	srli	a2,a2,0x20
    80001f90:	06c93423          	sd	a2,104(s2)
  return 0;
    80001f94:	4501                	li	a0,0
}
    80001f96:	60e2                	ld	ra,24(sp)
    80001f98:	6442                	ld	s0,16(sp)
    80001f9a:	64a2                	ld	s1,8(sp)
    80001f9c:	6902                	ld	s2,0(sp)
    80001f9e:	6105                	addi	sp,sp,32
    80001fa0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fa2:	9e25                	addw	a2,a2,s1
    80001fa4:	1602                	slli	a2,a2,0x20
    80001fa6:	9201                	srli	a2,a2,0x20
    80001fa8:	1582                	slli	a1,a1,0x20
    80001faa:	9181                	srli	a1,a1,0x20
    80001fac:	7928                	ld	a0,112(a0)
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	598080e7          	jalr	1432(ra) # 80001546 <uvmalloc>
    80001fb6:	0005061b          	sext.w	a2,a0
    80001fba:	fa69                	bnez	a2,80001f8c <growproc+0x26>
      return -1;
    80001fbc:	557d                	li	a0,-1
    80001fbe:	bfe1                	j	80001f96 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fc0:	9e25                	addw	a2,a2,s1
    80001fc2:	1602                	slli	a2,a2,0x20
    80001fc4:	9201                	srli	a2,a2,0x20
    80001fc6:	1582                	slli	a1,a1,0x20
    80001fc8:	9181                	srli	a1,a1,0x20
    80001fca:	7928                	ld	a0,112(a0)
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	532080e7          	jalr	1330(ra) # 800014fe <uvmdealloc>
    80001fd4:	0005061b          	sext.w	a2,a0
    80001fd8:	bf55                	j	80001f8c <growproc+0x26>

0000000080001fda <fork>:
{
    80001fda:	7179                	addi	sp,sp,-48
    80001fdc:	f406                	sd	ra,40(sp)
    80001fde:	f022                	sd	s0,32(sp)
    80001fe0:	ec26                	sd	s1,24(sp)
    80001fe2:	e84a                	sd	s2,16(sp)
    80001fe4:	e44e                	sd	s3,8(sp)
    80001fe6:	e052                	sd	s4,0(sp)
    80001fe8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fea:	00000097          	auipc	ra,0x0
    80001fee:	c0c080e7          	jalr	-1012(ra) # 80001bf6 <myproc>
    80001ff2:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001ff4:	00000097          	auipc	ra,0x0
    80001ff8:	e0c080e7          	jalr	-500(ra) # 80001e00 <allocproc>
    80001ffc:	12050163          	beqz	a0,8000211e <fork+0x144>
    80002000:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002002:	06893603          	ld	a2,104(s2)
    80002006:	792c                	ld	a1,112(a0)
    80002008:	07093503          	ld	a0,112(s2)
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	686080e7          	jalr	1670(ra) # 80001692 <uvmcopy>
    80002014:	04054663          	bltz	a0,80002060 <fork+0x86>
  np->sz = p->sz;
    80002018:	06893783          	ld	a5,104(s2)
    8000201c:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    80002020:	07893683          	ld	a3,120(s2)
    80002024:	87b6                	mv	a5,a3
    80002026:	0789b703          	ld	a4,120(s3)
    8000202a:	12068693          	addi	a3,a3,288
    8000202e:	0007b803          	ld	a6,0(a5)
    80002032:	6788                	ld	a0,8(a5)
    80002034:	6b8c                	ld	a1,16(a5)
    80002036:	6f90                	ld	a2,24(a5)
    80002038:	01073023          	sd	a6,0(a4)
    8000203c:	e708                	sd	a0,8(a4)
    8000203e:	eb0c                	sd	a1,16(a4)
    80002040:	ef10                	sd	a2,24(a4)
    80002042:	02078793          	addi	a5,a5,32
    80002046:	02070713          	addi	a4,a4,32
    8000204a:	fed792e3          	bne	a5,a3,8000202e <fork+0x54>
  np->trapframe->a0 = 0;
    8000204e:	0789b783          	ld	a5,120(s3)
    80002052:	0607b823          	sd	zero,112(a5)
    80002056:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    8000205a:	17000a13          	li	s4,368
    8000205e:	a03d                	j	8000208c <fork+0xb2>
    freeproc(np);
    80002060:	854e                	mv	a0,s3
    80002062:	00000097          	auipc	ra,0x0
    80002066:	d46080e7          	jalr	-698(ra) # 80001da8 <freeproc>
    release(&np->lock);
    8000206a:	854e                	mv	a0,s3
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	c2c080e7          	jalr	-980(ra) # 80000c98 <release>
    return -1;
    80002074:	5a7d                	li	s4,-1
    80002076:	a859                	j	8000210c <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80002078:	00003097          	auipc	ra,0x3
    8000207c:	bec080e7          	jalr	-1044(ra) # 80004c64 <filedup>
    80002080:	009987b3          	add	a5,s3,s1
    80002084:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002086:	04a1                	addi	s1,s1,8
    80002088:	01448763          	beq	s1,s4,80002096 <fork+0xbc>
    if(p->ofile[i])
    8000208c:	009907b3          	add	a5,s2,s1
    80002090:	6388                	ld	a0,0(a5)
    80002092:	f17d                	bnez	a0,80002078 <fork+0x9e>
    80002094:	bfcd                	j	80002086 <fork+0xac>
  np->cwd = idup(p->cwd);
    80002096:	17093503          	ld	a0,368(s2)
    8000209a:	00002097          	auipc	ra,0x2
    8000209e:	d40080e7          	jalr	-704(ra) # 80003dda <idup>
    800020a2:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020a6:	4641                	li	a2,16
    800020a8:	17890593          	addi	a1,s2,376
    800020ac:	17898513          	addi	a0,s3,376
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	d82080e7          	jalr	-638(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    800020b8:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    800020bc:	854e                	mv	a0,s3
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	bda080e7          	jalr	-1062(ra) # 80000c98 <release>
  acquire(&wait_lock);
    800020c6:	0000f497          	auipc	s1,0xf
    800020ca:	21248493          	addi	s1,s1,530 # 800112d8 <wait_lock>
    800020ce:	8526                	mv	a0,s1
    800020d0:	fffff097          	auipc	ra,0xfffff
    800020d4:	b14080e7          	jalr	-1260(ra) # 80000be4 <acquire>
  np->parent = p;
    800020d8:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	bba080e7          	jalr	-1094(ra) # 80000c98 <release>
  acquire(&np->lock);
    800020e6:	854e                	mv	a0,s3
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	afc080e7          	jalr	-1284(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020f0:	478d                	li	a5,3
    800020f2:	00f9ac23          	sw	a5,24(s3)
  p->last_runnable_time = ticks;
    800020f6:	00007797          	auipc	a5,0x7
    800020fa:	f627a783          	lw	a5,-158(a5) # 80009058 <ticks>
    800020fe:	04f9a423          	sw	a5,72(s3)
  release(&np->lock);
    80002102:	854e                	mv	a0,s3
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	b94080e7          	jalr	-1132(ra) # 80000c98 <release>
}
    8000210c:	8552                	mv	a0,s4
    8000210e:	70a2                	ld	ra,40(sp)
    80002110:	7402                	ld	s0,32(sp)
    80002112:	64e2                	ld	s1,24(sp)
    80002114:	6942                	ld	s2,16(sp)
    80002116:	69a2                	ld	s3,8(sp)
    80002118:	6a02                	ld	s4,0(sp)
    8000211a:	6145                	addi	sp,sp,48
    8000211c:	8082                	ret
    return -1;
    8000211e:	5a7d                	li	s4,-1
    80002120:	b7f5                	j	8000210c <fork+0x132>

0000000080002122 <minMeanTicks>:
{
    80002122:	7179                	addi	sp,sp,-48
    80002124:	f406                	sd	ra,40(sp)
    80002126:	f022                	sd	s0,32(sp)
    80002128:	ec26                	sd	s1,24(sp)
    8000212a:	e84a                	sd	s2,16(sp)
    8000212c:	e44e                	sd	s3,8(sp)
    8000212e:	e052                	sd	s4,0(sp)
    80002130:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80002132:	0000f497          	auipc	s1,0xf
    80002136:	5be48493          	addi	s1,s1,1470 # 800116f0 <proc>
    if(p->state == RUNNABLE)
    8000213a:	490d                	li	s2,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000213c:	00015997          	auipc	s3,0x15
    80002140:	7b498993          	addi	s3,s3,1972 # 800178f0 <tickslock>
    acquire(&p->lock);
    80002144:	8526                	mv	a0,s1
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	a9e080e7          	jalr	-1378(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE)
    8000214e:	4c9c                	lw	a5,24(s1)
    80002150:	03278f63          	beq	a5,s2,8000218e <minMeanTicks+0x6c>
    release(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b42080e7          	jalr	-1214(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000215e:	18848493          	addi	s1,s1,392
    80002162:	ff3491e3          	bne	s1,s3,80002144 <minMeanTicks+0x22>
  acquire(&min->lock);
    80002166:	0000f517          	auipc	a0,0xf
    8000216a:	58a50513          	addi	a0,a0,1418 # 800116f0 <proc>
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	a76080e7          	jalr	-1418(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    80002176:	0000f717          	auipc	a4,0xf
    8000217a:	59272703          	lw	a4,1426(a4) # 80011708 <proc+0x18>
    8000217e:	478d                	li	a5,3
    80002180:	04f70c63          	beq	a4,a5,800021d8 <minMeanTicks+0xb6>
  min = proc;
    80002184:	0000f497          	auipc	s1,0xf
    80002188:	56c48493          	addi	s1,s1,1388 # 800116f0 <proc>
    8000218c:	a839                	j	800021aa <minMeanTicks+0x88>
      release(&p->lock);
    8000218e:	8526                	mv	a0,s1
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	b08080e7          	jalr	-1272(ra) # 80000c98 <release>
  acquire(&min->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	a4a080e7          	jalr	-1462(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    800021a2:	4c98                	lw	a4,24(s1)
    800021a4:	478d                	li	a5,3
    800021a6:	00f70b63          	beq	a4,a5,800021bc <minMeanTicks+0x9a>
}
    800021aa:	8526                	mv	a0,s1
    800021ac:	70a2                	ld	ra,40(sp)
    800021ae:	7402                	ld	s0,32(sp)
    800021b0:	64e2                	ld	s1,24(sp)
    800021b2:	6942                	ld	s2,16(sp)
    800021b4:	69a2                	ld	s3,8(sp)
    800021b6:	6a02                	ld	s4,0(sp)
    800021b8:	6145                	addi	sp,sp,48
    800021ba:	8082                	ret
    for (p = min+1; p < &proc[NPROC]; p++)
    800021bc:	18848913          	addi	s2,s1,392
    800021c0:	00015797          	auipc	a5,0x15
    800021c4:	73078793          	addi	a5,a5,1840 # 800178f0 <tickslock>
    800021c8:	fef971e3          	bgeu	s2,a5,800021aa <minMeanTicks+0x88>
      if(p->state == RUNNABLE && min->mean_ticks > p->mean_ticks)
    800021cc:	4a0d                	li	s4,3
    for (p = min+1; p < &proc[NPROC]; p++)
    800021ce:	00015997          	auipc	s3,0x15
    800021d2:	72298993          	addi	s3,s3,1826 # 800178f0 <tickslock>
    800021d6:	a01d                	j	800021fc <minMeanTicks+0xda>
  min = proc;
    800021d8:	0000f497          	auipc	s1,0xf
    800021dc:	51848493          	addi	s1,s1,1304 # 800116f0 <proc>
    for (p = min+1; p < &proc[NPROC]; p++)
    800021e0:	0000f917          	auipc	s2,0xf
    800021e4:	69890913          	addi	s2,s2,1688 # 80011878 <proc+0x188>
    800021e8:	b7d5                	j	800021cc <minMeanTicks+0xaa>
        release(&p->lock);
    800021ea:	854a                	mv	a0,s2
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	aac080e7          	jalr	-1364(ra) # 80000c98 <release>
    for (p = min+1; p < &proc[NPROC]; p++)
    800021f4:	18890913          	addi	s2,s2,392
    800021f8:	fb3979e3          	bgeu	s2,s3,800021aa <minMeanTicks+0x88>
      acquire(&p->lock);
    800021fc:	854a                	mv	a0,s2
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	9e6080e7          	jalr	-1562(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && min->mean_ticks > p->mean_ticks)
    80002206:	01892783          	lw	a5,24(s2)
    8000220a:	ff4790e3          	bne	a5,s4,800021ea <minMeanTicks+0xc8>
    8000220e:	40b8                	lw	a4,64(s1)
    80002210:	04092783          	lw	a5,64(s2)
    80002214:	fce7dbe3          	bge	a5,a4,800021ea <minMeanTicks+0xc8>
        release(&min->lock);
    80002218:	8526                	mv	a0,s1
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	a7e080e7          	jalr	-1410(ra) # 80000c98 <release>
        min = p;
    80002222:	84ca                	mv	s1,s2
    80002224:	bfc1                	j	800021f4 <minMeanTicks+0xd2>

0000000080002226 <SJFScheduler>:
{
    80002226:	711d                	addi	sp,sp,-96
    80002228:	ec86                	sd	ra,88(sp)
    8000222a:	e8a2                	sd	s0,80(sp)
    8000222c:	e4a6                	sd	s1,72(sp)
    8000222e:	e0ca                	sd	s2,64(sp)
    80002230:	fc4e                	sd	s3,56(sp)
    80002232:	f852                	sd	s4,48(sp)
    80002234:	f456                	sd	s5,40(sp)
    80002236:	f05a                	sd	s6,32(sp)
    80002238:	ec5e                	sd	s7,24(sp)
    8000223a:	e862                	sd	s8,16(sp)
    8000223c:	e466                	sd	s9,8(sp)
    8000223e:	1080                	addi	s0,sp,96
    80002240:	8792                	mv	a5,tp
  int id = r_tp();
    80002242:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002244:	00779b93          	slli	s7,a5,0x7
    80002248:	0000f717          	auipc	a4,0xf
    8000224c:	07870713          	addi	a4,a4,120 # 800112c0 <pid_lock>
    80002250:	975e                	add	a4,a4,s7
    80002252:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002256:	0000f717          	auipc	a4,0xf
    8000225a:	0a270713          	addi	a4,a4,162 # 800112f8 <cpus+0x8>
    8000225e:	9bba                	add	s7,s7,a4
    if (ticks >= nextGoodTicks)
    80002260:	00007997          	auipc	s3,0x7
    80002264:	df898993          	addi	s3,s3,-520 # 80009058 <ticks>
    80002268:	00007a17          	auipc	s4,0x7
    8000226c:	de4a0a13          	addi	s4,s4,-540 # 8000904c <nextGoodTicks>
      if (p->state == RUNNABLE)
    80002270:	4a8d                	li	s5,3
        p->state = RUNNING;
    80002272:	4c91                	li	s9,4
        c->proc = p;
    80002274:	079e                	slli	a5,a5,0x7
    80002276:	0000fb17          	auipc	s6,0xf
    8000227a:	04ab0b13          	addi	s6,s6,74 # 800112c0 <pid_lock>
    8000227e:	9b3e                	add	s6,s6,a5
        p->mean_ticks =  ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    80002280:	00006c17          	auipc	s8,0x6
    80002284:	674c0c13          	addi	s8,s8,1652 # 800088f4 <rate>
    80002288:	a031                	j	80002294 <SJFScheduler+0x6e>
    release(&p->lock);
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	a0c080e7          	jalr	-1524(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002294:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002298:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000229c:	10079073          	csrw	sstatus,a5
    p = minMeanTicks();
    800022a0:	00000097          	auipc	ra,0x0
    800022a4:	e82080e7          	jalr	-382(ra) # 80002122 <minMeanTicks>
    800022a8:	84aa                	mv	s1,a0
    if (ticks >= nextGoodTicks)
    800022aa:	0009a903          	lw	s2,0(s3)
    800022ae:	000a2783          	lw	a5,0(s4)
    800022b2:	fcf96ce3          	bltu	s2,a5,8000228a <SJFScheduler+0x64>
      if (p->state == RUNNABLE)
    800022b6:	4d1c                	lw	a5,24(a0)
    800022b8:	fd5799e3          	bne	a5,s5,8000228a <SJFScheduler+0x64>
        p->state = RUNNING;
    800022bc:	01952c23          	sw	s9,24(a0)
        c->proc = p;
    800022c0:	02ab3823          	sd	a0,48(s6)
        swtch(&c->context, &p->context);
    800022c4:	08050593          	addi	a1,a0,128
    800022c8:	855e                	mv	a0,s7
    800022ca:	00001097          	auipc	ra,0x1
    800022ce:	a88080e7          	jalr	-1400(ra) # 80002d52 <swtch>
        c->proc = 0;
    800022d2:	020b3823          	sd	zero,48(s6)
        p->last_ticks = ticks - prevTicks;
    800022d6:	0009a783          	lw	a5,0(s3)
    800022da:	4127893b          	subw	s2,a5,s2
    800022de:	0524a223          	sw	s2,68(s1)
        p->mean_ticks =  ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    800022e2:	000c2683          	lw	a3,0(s8)
    800022e6:	4729                	li	a4,10
    800022e8:	40d707bb          	subw	a5,a4,a3
    800022ec:	40b0                	lw	a2,64(s1)
    800022ee:	02c787bb          	mulw	a5,a5,a2
    800022f2:	02d9093b          	mulw	s2,s2,a3
    800022f6:	012787bb          	addw	a5,a5,s2
    800022fa:	02e7c7bb          	divw	a5,a5,a4
    800022fe:	c0bc                	sw	a5,64(s1)
    80002300:	b769                	j	8000228a <SJFScheduler+0x64>

0000000080002302 <minLastRunnableTime>:
{
    80002302:	7179                	addi	sp,sp,-48
    80002304:	f406                	sd	ra,40(sp)
    80002306:	f022                	sd	s0,32(sp)
    80002308:	ec26                	sd	s1,24(sp)
    8000230a:	e84a                	sd	s2,16(sp)
    8000230c:	e44e                	sd	s3,8(sp)
    8000230e:	e052                	sd	s4,0(sp)
    80002310:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80002312:	0000f497          	auipc	s1,0xf
    80002316:	3de48493          	addi	s1,s1,990 # 800116f0 <proc>
    if(p->state == RUNNABLE)
    8000231a:	490d                	li	s2,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000231c:	00015997          	auipc	s3,0x15
    80002320:	5d498993          	addi	s3,s3,1492 # 800178f0 <tickslock>
    acquire(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	8be080e7          	jalr	-1858(ra) # 80000be4 <acquire>
    if(p->state == RUNNABLE)
    8000232e:	4c9c                	lw	a5,24(s1)
    80002330:	03278f63          	beq	a5,s2,8000236e <minLastRunnableTime+0x6c>
    release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000233e:	18848493          	addi	s1,s1,392
    80002342:	ff3491e3          	bne	s1,s3,80002324 <minLastRunnableTime+0x22>
  acquire(&min->lock);
    80002346:	0000f517          	auipc	a0,0xf
    8000234a:	3aa50513          	addi	a0,a0,938 # 800116f0 <proc>
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	896080e7          	jalr	-1898(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    80002356:	0000f717          	auipc	a4,0xf
    8000235a:	3b272703          	lw	a4,946(a4) # 80011708 <proc+0x18>
    8000235e:	478d                	li	a5,3
    80002360:	04f70c63          	beq	a4,a5,800023b8 <minLastRunnableTime+0xb6>
  min = proc;
    80002364:	0000f497          	auipc	s1,0xf
    80002368:	38c48493          	addi	s1,s1,908 # 800116f0 <proc>
    8000236c:	a839                	j	8000238a <minLastRunnableTime+0x88>
      release(&p->lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	928080e7          	jalr	-1752(ra) # 80000c98 <release>
  acquire(&min->lock);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	86a080e7          	jalr	-1942(ra) # 80000be4 <acquire>
  if(min->state == RUNNABLE)
    80002382:	4c98                	lw	a4,24(s1)
    80002384:	478d                	li	a5,3
    80002386:	00f70b63          	beq	a4,a5,8000239c <minLastRunnableTime+0x9a>
}
    8000238a:	8526                	mv	a0,s1
    8000238c:	70a2                	ld	ra,40(sp)
    8000238e:	7402                	ld	s0,32(sp)
    80002390:	64e2                	ld	s1,24(sp)
    80002392:	6942                	ld	s2,16(sp)
    80002394:	69a2                	ld	s3,8(sp)
    80002396:	6a02                	ld	s4,0(sp)
    80002398:	6145                	addi	sp,sp,48
    8000239a:	8082                	ret
    for (p = min+1; p < &proc[NPROC]; p++)
    8000239c:	18848913          	addi	s2,s1,392
    800023a0:	00015797          	auipc	a5,0x15
    800023a4:	55078793          	addi	a5,a5,1360 # 800178f0 <tickslock>
    800023a8:	fef971e3          	bgeu	s2,a5,8000238a <minLastRunnableTime+0x88>
      if(p->state == RUNNABLE && min->last_runnable_time > p->last_runnable_time)
    800023ac:	4a0d                	li	s4,3
    for (p = min+1; p < &proc[NPROC]; p++)
    800023ae:	00015997          	auipc	s3,0x15
    800023b2:	54298993          	addi	s3,s3,1346 # 800178f0 <tickslock>
    800023b6:	a01d                	j	800023dc <minLastRunnableTime+0xda>
  min = proc;
    800023b8:	0000f497          	auipc	s1,0xf
    800023bc:	33848493          	addi	s1,s1,824 # 800116f0 <proc>
    for (p = min+1; p < &proc[NPROC]; p++)
    800023c0:	0000f917          	auipc	s2,0xf
    800023c4:	4b890913          	addi	s2,s2,1208 # 80011878 <proc+0x188>
    800023c8:	b7d5                	j	800023ac <minLastRunnableTime+0xaa>
        release(&p->lock);
    800023ca:	854a                	mv	a0,s2
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8cc080e7          	jalr	-1844(ra) # 80000c98 <release>
    for (p = min+1; p < &proc[NPROC]; p++)
    800023d4:	18890913          	addi	s2,s2,392
    800023d8:	fb3979e3          	bgeu	s2,s3,8000238a <minLastRunnableTime+0x88>
      acquire(&p->lock);
    800023dc:	854a                	mv	a0,s2
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	806080e7          	jalr	-2042(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE && min->last_runnable_time > p->last_runnable_time)
    800023e6:	01892783          	lw	a5,24(s2)
    800023ea:	ff4790e3          	bne	a5,s4,800023ca <minLastRunnableTime+0xc8>
    800023ee:	44b8                	lw	a4,72(s1)
    800023f0:	04892783          	lw	a5,72(s2)
    800023f4:	fce7dbe3          	bge	a5,a4,800023ca <minLastRunnableTime+0xc8>
        release(&min->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	89e080e7          	jalr	-1890(ra) # 80000c98 <release>
        min = p;
    80002402:	84ca                	mv	s1,s2
    80002404:	bfc1                	j	800023d4 <minLastRunnableTime+0xd2>

0000000080002406 <FCFSScheduler>:
{
    80002406:	715d                	addi	sp,sp,-80
    80002408:	e486                	sd	ra,72(sp)
    8000240a:	e0a2                	sd	s0,64(sp)
    8000240c:	fc26                	sd	s1,56(sp)
    8000240e:	f84a                	sd	s2,48(sp)
    80002410:	f44e                	sd	s3,40(sp)
    80002412:	f052                	sd	s4,32(sp)
    80002414:	ec56                	sd	s5,24(sp)
    80002416:	e85a                	sd	s6,16(sp)
    80002418:	e45e                	sd	s7,8(sp)
    8000241a:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    8000241c:	8792                	mv	a5,tp
  int id = r_tp();
    8000241e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002420:	00779b13          	slli	s6,a5,0x7
    80002424:	0000f717          	auipc	a4,0xf
    80002428:	e9c70713          	addi	a4,a4,-356 # 800112c0 <pid_lock>
    8000242c:	975a                	add	a4,a4,s6
    8000242e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002432:	0000f717          	auipc	a4,0xf
    80002436:	ec670713          	addi	a4,a4,-314 # 800112f8 <cpus+0x8>
    8000243a:	9b3a                	add	s6,s6,a4
    if (ticks >= nextGoodTicks)
    8000243c:	00007997          	auipc	s3,0x7
    80002440:	c1c98993          	addi	s3,s3,-996 # 80009058 <ticks>
    80002444:	00007917          	auipc	s2,0x7
    80002448:	c0890913          	addi	s2,s2,-1016 # 8000904c <nextGoodTicks>
      if (p->state == RUNNABLE)
    8000244c:	4a0d                	li	s4,3
        p->state = RUNNING;
    8000244e:	4b91                	li	s7,4
        c->proc = p;
    80002450:	079e                	slli	a5,a5,0x7
    80002452:	0000fa97          	auipc	s5,0xf
    80002456:	e6ea8a93          	addi	s5,s5,-402 # 800112c0 <pid_lock>
    8000245a:	9abe                	add	s5,s5,a5
    8000245c:	a031                	j	80002468 <FCFSScheduler+0x62>
    release(&p->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	838080e7          	jalr	-1992(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002468:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000246c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002470:	10079073          	csrw	sstatus,a5
    p = minLastRunnableTime();
    80002474:	00000097          	auipc	ra,0x0
    80002478:	e8e080e7          	jalr	-370(ra) # 80002302 <minLastRunnableTime>
    8000247c:	84aa                	mv	s1,a0
    if (ticks >= nextGoodTicks)
    8000247e:	0009a703          	lw	a4,0(s3)
    80002482:	00092783          	lw	a5,0(s2)
    80002486:	fcf76ce3          	bltu	a4,a5,8000245e <FCFSScheduler+0x58>
      if (p->state == RUNNABLE)
    8000248a:	4d1c                	lw	a5,24(a0)
    8000248c:	fd4799e3          	bne	a5,s4,8000245e <FCFSScheduler+0x58>
        p->state = RUNNING;
    80002490:	01752c23          	sw	s7,24(a0)
        c->proc = p;
    80002494:	02aab823          	sd	a0,48(s5)
        swtch(&c->context, &p->context);
    80002498:	08050593          	addi	a1,a0,128
    8000249c:	855a                	mv	a0,s6
    8000249e:	00001097          	auipc	ra,0x1
    800024a2:	8b4080e7          	jalr	-1868(ra) # 80002d52 <swtch>
        c->proc = 0;
    800024a6:	020ab823          	sd	zero,48(s5)
    800024aa:	bf55                	j	8000245e <FCFSScheduler+0x58>

00000000800024ac <regulerScheduler>:
{
    800024ac:	715d                	addi	sp,sp,-80
    800024ae:	e486                	sd	ra,72(sp)
    800024b0:	e0a2                	sd	s0,64(sp)
    800024b2:	fc26                	sd	s1,56(sp)
    800024b4:	f84a                	sd	s2,48(sp)
    800024b6:	f44e                	sd	s3,40(sp)
    800024b8:	f052                	sd	s4,32(sp)
    800024ba:	ec56                	sd	s5,24(sp)
    800024bc:	e85a                	sd	s6,16(sp)
    800024be:	e45e                	sd	s7,8(sp)
    800024c0:	e062                	sd	s8,0(sp)
    800024c2:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    800024c4:	8792                	mv	a5,tp
  int id = r_tp();
    800024c6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800024c8:	00779c13          	slli	s8,a5,0x7
    800024cc:	0000f717          	auipc	a4,0xf
    800024d0:	df470713          	addi	a4,a4,-524 # 800112c0 <pid_lock>
    800024d4:	9762                	add	a4,a4,s8
    800024d6:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    800024da:	0000f717          	auipc	a4,0xf
    800024de:	e1e70713          	addi	a4,a4,-482 # 800112f8 <cpus+0x8>
    800024e2:	9c3a                	add	s8,s8,a4
      if (ticks >= nextGoodTicks)
    800024e4:	00007a17          	auipc	s4,0x7
    800024e8:	b74a0a13          	addi	s4,s4,-1164 # 80009058 <ticks>
    800024ec:	00007997          	auipc	s3,0x7
    800024f0:	b6098993          	addi	s3,s3,-1184 # 8000904c <nextGoodTicks>
        if (p->state == RUNNABLE)
    800024f4:	4a8d                	li	s5,3
          c->proc = p;
    800024f6:	079e                	slli	a5,a5,0x7
    800024f8:	0000fb17          	auipc	s6,0xf
    800024fc:	dc8b0b13          	addi	s6,s6,-568 # 800112c0 <pid_lock>
    80002500:	9b3e                	add	s6,s6,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80002502:	00015917          	auipc	s2,0x15
    80002506:	3ee90913          	addi	s2,s2,1006 # 800178f0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000250a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000250e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002512:	10079073          	csrw	sstatus,a5
    80002516:	0000f497          	auipc	s1,0xf
    8000251a:	1da48493          	addi	s1,s1,474 # 800116f0 <proc>
          p->state = RUNNING;
    8000251e:	4b91                	li	s7,4
    80002520:	a03d                	j	8000254e <regulerScheduler+0xa2>
    80002522:	0174ac23          	sw	s7,24(s1)
          c->proc = p;
    80002526:	029b3823          	sd	s1,48(s6)
          swtch(&c->context, &p->context);
    8000252a:	08048593          	addi	a1,s1,128
    8000252e:	8562                	mv	a0,s8
    80002530:	00001097          	auipc	ra,0x1
    80002534:	822080e7          	jalr	-2014(ra) # 80002d52 <swtch>
          c->proc = 0;
    80002538:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	75a080e7          	jalr	1882(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002546:	18848493          	addi	s1,s1,392
    8000254a:	fd2480e3          	beq	s1,s2,8000250a <regulerScheduler+0x5e>
      if (ticks >= nextGoodTicks)
    8000254e:	000a2703          	lw	a4,0(s4)
    80002552:	0009a783          	lw	a5,0(s3)
    80002556:	fef768e3          	bltu	a4,a5,80002546 <regulerScheduler+0x9a>
        acquire(&p->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	688080e7          	jalr	1672(ra) # 80000be4 <acquire>
        if (p->state == RUNNABLE)
    80002564:	4c9c                	lw	a5,24(s1)
    80002566:	fd579be3          	bne	a5,s5,8000253c <regulerScheduler+0x90>
    8000256a:	bf65                	j	80002522 <regulerScheduler+0x76>

000000008000256c <scheduler>:
{
    8000256c:	1141                	addi	sp,sp,-16
    8000256e:	e406                	sd	ra,8(sp)
    80002570:	e022                	sd	s0,0(sp)
    80002572:	0800                	addi	s0,sp,16
    regulerScheduler();
    80002574:	00000097          	auipc	ra,0x0
    80002578:	f38080e7          	jalr	-200(ra) # 800024ac <regulerScheduler>

000000008000257c <sched>:
{
    8000257c:	7179                	addi	sp,sp,-48
    8000257e:	f406                	sd	ra,40(sp)
    80002580:	f022                	sd	s0,32(sp)
    80002582:	ec26                	sd	s1,24(sp)
    80002584:	e84a                	sd	s2,16(sp)
    80002586:	e44e                	sd	s3,8(sp)
    80002588:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000258a:	fffff097          	auipc	ra,0xfffff
    8000258e:	66c080e7          	jalr	1644(ra) # 80001bf6 <myproc>
    80002592:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	5d6080e7          	jalr	1494(ra) # 80000b6a <holding>
    8000259c:	c93d                	beqz	a0,80002612 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000259e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800025a0:	2781                	sext.w	a5,a5
    800025a2:	079e                	slli	a5,a5,0x7
    800025a4:	0000f717          	auipc	a4,0xf
    800025a8:	d1c70713          	addi	a4,a4,-740 # 800112c0 <pid_lock>
    800025ac:	97ba                	add	a5,a5,a4
    800025ae:	0a87a703          	lw	a4,168(a5)
    800025b2:	4785                	li	a5,1
    800025b4:	06f71763          	bne	a4,a5,80002622 <sched+0xa6>
  if(p->state == RUNNING)
    800025b8:	4c98                	lw	a4,24(s1)
    800025ba:	4791                	li	a5,4
    800025bc:	06f70b63          	beq	a4,a5,80002632 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025c0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800025c4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800025c6:	efb5                	bnez	a5,80002642 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800025c8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800025ca:	0000f917          	auipc	s2,0xf
    800025ce:	cf690913          	addi	s2,s2,-778 # 800112c0 <pid_lock>
    800025d2:	2781                	sext.w	a5,a5
    800025d4:	079e                	slli	a5,a5,0x7
    800025d6:	97ca                	add	a5,a5,s2
    800025d8:	0ac7a983          	lw	s3,172(a5)
    800025dc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800025de:	2781                	sext.w	a5,a5
    800025e0:	079e                	slli	a5,a5,0x7
    800025e2:	0000f597          	auipc	a1,0xf
    800025e6:	d1658593          	addi	a1,a1,-746 # 800112f8 <cpus+0x8>
    800025ea:	95be                	add	a1,a1,a5
    800025ec:	08048513          	addi	a0,s1,128
    800025f0:	00000097          	auipc	ra,0x0
    800025f4:	762080e7          	jalr	1890(ra) # 80002d52 <swtch>
    800025f8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800025fa:	2781                	sext.w	a5,a5
    800025fc:	079e                	slli	a5,a5,0x7
    800025fe:	97ca                	add	a5,a5,s2
    80002600:	0b37a623          	sw	s3,172(a5)
}
    80002604:	70a2                	ld	ra,40(sp)
    80002606:	7402                	ld	s0,32(sp)
    80002608:	64e2                	ld	s1,24(sp)
    8000260a:	6942                	ld	s2,16(sp)
    8000260c:	69a2                	ld	s3,8(sp)
    8000260e:	6145                	addi	sp,sp,48
    80002610:	8082                	ret
    panic("sched p->lock");
    80002612:	00006517          	auipc	a0,0x6
    80002616:	cc650513          	addi	a0,a0,-826 # 800082d8 <digits+0x298>
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	f24080e7          	jalr	-220(ra) # 8000053e <panic>
    panic("sched locks");
    80002622:	00006517          	auipc	a0,0x6
    80002626:	cc650513          	addi	a0,a0,-826 # 800082e8 <digits+0x2a8>
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	f14080e7          	jalr	-236(ra) # 8000053e <panic>
    panic("sched running");
    80002632:	00006517          	auipc	a0,0x6
    80002636:	cc650513          	addi	a0,a0,-826 # 800082f8 <digits+0x2b8>
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	f04080e7          	jalr	-252(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002642:	00006517          	auipc	a0,0x6
    80002646:	cc650513          	addi	a0,a0,-826 # 80008308 <digits+0x2c8>
    8000264a:	ffffe097          	auipc	ra,0xffffe
    8000264e:	ef4080e7          	jalr	-268(ra) # 8000053e <panic>

0000000080002652 <yield>:
{
    80002652:	1101                	addi	sp,sp,-32
    80002654:	ec06                	sd	ra,24(sp)
    80002656:	e822                	sd	s0,16(sp)
    80002658:	e426                	sd	s1,8(sp)
    8000265a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000265c:	fffff097          	auipc	ra,0xfffff
    80002660:	59a080e7          	jalr	1434(ra) # 80001bf6 <myproc>
    80002664:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	57e080e7          	jalr	1406(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000266e:	478d                	li	a5,3
    80002670:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002672:	00007797          	auipc	a5,0x7
    80002676:	9e67a783          	lw	a5,-1562(a5) # 80009058 <ticks>
    8000267a:	c4bc                	sw	a5,72(s1)
  sched();
    8000267c:	00000097          	auipc	ra,0x0
    80002680:	f00080e7          	jalr	-256(ra) # 8000257c <sched>
  release(&p->lock);
    80002684:	8526                	mv	a0,s1
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	612080e7          	jalr	1554(ra) # 80000c98 <release>
}
    8000268e:	60e2                	ld	ra,24(sp)
    80002690:	6442                	ld	s0,16(sp)
    80002692:	64a2                	ld	s1,8(sp)
    80002694:	6105                	addi	sp,sp,32
    80002696:	8082                	ret

0000000080002698 <pause_system>:
{
    80002698:	7139                	addi	sp,sp,-64
    8000269a:	fc06                	sd	ra,56(sp)
    8000269c:	f822                	sd	s0,48(sp)
    8000269e:	f426                	sd	s1,40(sp)
    800026a0:	f04a                	sd	s2,32(sp)
    800026a2:	ec4e                	sd	s3,24(sp)
    800026a4:	e852                	sd	s4,16(sp)
    800026a6:	e456                	sd	s5,8(sp)
    800026a8:	e05a                	sd	s6,0(sp)
    800026aa:	0080                	addi	s0,sp,64
  nextGoodTicks = ticks + 10 * seconds;
    800026ac:	0025179b          	slliw	a5,a0,0x2
    800026b0:	9fa9                	addw	a5,a5,a0
    800026b2:	0017979b          	slliw	a5,a5,0x1
    800026b6:	00007717          	auipc	a4,0x7
    800026ba:	9a272703          	lw	a4,-1630(a4) # 80009058 <ticks>
    800026be:	9fb9                	addw	a5,a5,a4
    800026c0:	00007717          	auipc	a4,0x7
    800026c4:	98f72623          	sw	a5,-1652(a4) # 8000904c <nextGoodTicks>
  for (p = proc; p < &proc[NPROC]; p++)
    800026c8:	0000f497          	auipc	s1,0xf
    800026cc:	02848493          	addi	s1,s1,40 # 800116f0 <proc>
    if (p->state == RUNNING && p->pid > 2)
    800026d0:	4991                	li	s3,4
    800026d2:	4a09                	li	s4,2
  p->state = RUNNABLE;
    800026d4:	4b0d                	li	s6,3
  p->last_runnable_time = ticks;
    800026d6:	00007a97          	auipc	s5,0x7
    800026da:	982a8a93          	addi	s5,s5,-1662 # 80009058 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    800026de:	00015917          	auipc	s2,0x15
    800026e2:	21290913          	addi	s2,s2,530 # 800178f0 <tickslock>
    800026e6:	a839                	j	80002704 <pause_system+0x6c>
  p->state = RUNNABLE;
    800026e8:	0164ac23          	sw	s6,24(s1)
  p->last_runnable_time = ticks;
    800026ec:	000aa783          	lw	a5,0(s5)
    800026f0:	c4bc                	sw	a5,72(s1)
    release(&p->lock);
    800026f2:	8526                	mv	a0,s1
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	5a4080e7          	jalr	1444(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026fc:	18848493          	addi	s1,s1,392
    80002700:	01248e63          	beq	s1,s2,8000271c <pause_system+0x84>
    acquire(&p->lock);
    80002704:	8526                	mv	a0,s1
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	4de080e7          	jalr	1246(ra) # 80000be4 <acquire>
    if (p->state == RUNNING && p->pid > 2)
    8000270e:	4c9c                	lw	a5,24(s1)
    80002710:	ff3791e3          	bne	a5,s3,800026f2 <pause_system+0x5a>
    80002714:	589c                	lw	a5,48(s1)
    80002716:	fcfa5ee3          	bge	s4,a5,800026f2 <pause_system+0x5a>
    8000271a:	b7f9                	j	800026e8 <pause_system+0x50>
  yield();
    8000271c:	00000097          	auipc	ra,0x0
    80002720:	f36080e7          	jalr	-202(ra) # 80002652 <yield>
}
    80002724:	4501                	li	a0,0
    80002726:	70e2                	ld	ra,56(sp)
    80002728:	7442                	ld	s0,48(sp)
    8000272a:	74a2                	ld	s1,40(sp)
    8000272c:	7902                	ld	s2,32(sp)
    8000272e:	69e2                	ld	s3,24(sp)
    80002730:	6a42                	ld	s4,16(sp)
    80002732:	6aa2                	ld	s5,8(sp)
    80002734:	6b02                	ld	s6,0(sp)
    80002736:	6121                	addi	sp,sp,64
    80002738:	8082                	ret

000000008000273a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000273a:	7179                	addi	sp,sp,-48
    8000273c:	f406                	sd	ra,40(sp)
    8000273e:	f022                	sd	s0,32(sp)
    80002740:	ec26                	sd	s1,24(sp)
    80002742:	e84a                	sd	s2,16(sp)
    80002744:	e44e                	sd	s3,8(sp)
    80002746:	1800                	addi	s0,sp,48
    80002748:	89aa                	mv	s3,a0
    8000274a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000274c:	fffff097          	auipc	ra,0xfffff
    80002750:	4aa080e7          	jalr	1194(ra) # 80001bf6 <myproc>
    80002754:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	48e080e7          	jalr	1166(ra) # 80000be4 <acquire>
  release(lk);
    8000275e:	854a                	mv	a0,s2
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	538080e7          	jalr	1336(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002768:	0334b023          	sd	s3,32(s1)

  p->state = SLEEPING;
    8000276c:	4789                	li	a5,2
    8000276e:	cc9c                	sw	a5,24(s1)

  sched();
    80002770:	00000097          	auipc	ra,0x0
    80002774:	e0c080e7          	jalr	-500(ra) # 8000257c <sched>

  // Tidy up.
  p->chan = 0;
    80002778:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000277c:	8526                	mv	a0,s1
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	51a080e7          	jalr	1306(ra) # 80000c98 <release>
  acquire(lk);
    80002786:	854a                	mv	a0,s2
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	45c080e7          	jalr	1116(ra) # 80000be4 <acquire>
}
    80002790:	70a2                	ld	ra,40(sp)
    80002792:	7402                	ld	s0,32(sp)
    80002794:	64e2                	ld	s1,24(sp)
    80002796:	6942                	ld	s2,16(sp)
    80002798:	69a2                	ld	s3,8(sp)
    8000279a:	6145                	addi	sp,sp,48
    8000279c:	8082                	ret

000000008000279e <wait>:
{
    8000279e:	715d                	addi	sp,sp,-80
    800027a0:	e486                	sd	ra,72(sp)
    800027a2:	e0a2                	sd	s0,64(sp)
    800027a4:	fc26                	sd	s1,56(sp)
    800027a6:	f84a                	sd	s2,48(sp)
    800027a8:	f44e                	sd	s3,40(sp)
    800027aa:	f052                	sd	s4,32(sp)
    800027ac:	ec56                	sd	s5,24(sp)
    800027ae:	e85a                	sd	s6,16(sp)
    800027b0:	e45e                	sd	s7,8(sp)
    800027b2:	e062                	sd	s8,0(sp)
    800027b4:	0880                	addi	s0,sp,80
    800027b6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	43e080e7          	jalr	1086(ra) # 80001bf6 <myproc>
    800027c0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800027c2:	0000f517          	auipc	a0,0xf
    800027c6:	b1650513          	addi	a0,a0,-1258 # 800112d8 <wait_lock>
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	41a080e7          	jalr	1050(ra) # 80000be4 <acquire>
    havekids = 0;
    800027d2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800027d4:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800027d6:	00015997          	auipc	s3,0x15
    800027da:	11a98993          	addi	s3,s3,282 # 800178f0 <tickslock>
        havekids = 1;
    800027de:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800027e0:	0000fc17          	auipc	s8,0xf
    800027e4:	af8c0c13          	addi	s8,s8,-1288 # 800112d8 <wait_lock>
    havekids = 0;
    800027e8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800027ea:	0000f497          	auipc	s1,0xf
    800027ee:	f0648493          	addi	s1,s1,-250 # 800116f0 <proc>
    800027f2:	a0bd                	j	80002860 <wait+0xc2>
          pid = np->pid;
    800027f4:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027f8:	000b0e63          	beqz	s6,80002814 <wait+0x76>
    800027fc:	4691                	li	a3,4
    800027fe:	02c48613          	addi	a2,s1,44
    80002802:	85da                	mv	a1,s6
    80002804:	07093503          	ld	a0,112(s2)
    80002808:	fffff097          	auipc	ra,0xfffff
    8000280c:	f8e080e7          	jalr	-114(ra) # 80001796 <copyout>
    80002810:	02054563          	bltz	a0,8000283a <wait+0x9c>
          freeproc(np);
    80002814:	8526                	mv	a0,s1
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	592080e7          	jalr	1426(ra) # 80001da8 <freeproc>
          release(&np->lock);
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	478080e7          	jalr	1144(ra) # 80000c98 <release>
          release(&wait_lock);
    80002828:	0000f517          	auipc	a0,0xf
    8000282c:	ab050513          	addi	a0,a0,-1360 # 800112d8 <wait_lock>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	468080e7          	jalr	1128(ra) # 80000c98 <release>
          return pid;
    80002838:	a09d                	j	8000289e <wait+0x100>
            release(&np->lock);
    8000283a:	8526                	mv	a0,s1
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	45c080e7          	jalr	1116(ra) # 80000c98 <release>
            release(&wait_lock);
    80002844:	0000f517          	auipc	a0,0xf
    80002848:	a9450513          	addi	a0,a0,-1388 # 800112d8 <wait_lock>
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	44c080e7          	jalr	1100(ra) # 80000c98 <release>
            return -1;
    80002854:	59fd                	li	s3,-1
    80002856:	a0a1                	j	8000289e <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002858:	18848493          	addi	s1,s1,392
    8000285c:	03348463          	beq	s1,s3,80002884 <wait+0xe6>
      if(np->parent == p){
    80002860:	7c9c                	ld	a5,56(s1)
    80002862:	ff279be3          	bne	a5,s2,80002858 <wait+0xba>
        acquire(&np->lock);
    80002866:	8526                	mv	a0,s1
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	37c080e7          	jalr	892(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002870:	4c9c                	lw	a5,24(s1)
    80002872:	f94781e3          	beq	a5,s4,800027f4 <wait+0x56>
        release(&np->lock);
    80002876:	8526                	mv	a0,s1
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	420080e7          	jalr	1056(ra) # 80000c98 <release>
        havekids = 1;
    80002880:	8756                	mv	a4,s5
    80002882:	bfd9                	j	80002858 <wait+0xba>
    if(!havekids || p->killed){
    80002884:	c701                	beqz	a4,8000288c <wait+0xee>
    80002886:	02892783          	lw	a5,40(s2)
    8000288a:	c79d                	beqz	a5,800028b8 <wait+0x11a>
      release(&wait_lock);
    8000288c:	0000f517          	auipc	a0,0xf
    80002890:	a4c50513          	addi	a0,a0,-1460 # 800112d8 <wait_lock>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	404080e7          	jalr	1028(ra) # 80000c98 <release>
      return -1;
    8000289c:	59fd                	li	s3,-1
}
    8000289e:	854e                	mv	a0,s3
    800028a0:	60a6                	ld	ra,72(sp)
    800028a2:	6406                	ld	s0,64(sp)
    800028a4:	74e2                	ld	s1,56(sp)
    800028a6:	7942                	ld	s2,48(sp)
    800028a8:	79a2                	ld	s3,40(sp)
    800028aa:	7a02                	ld	s4,32(sp)
    800028ac:	6ae2                	ld	s5,24(sp)
    800028ae:	6b42                	ld	s6,16(sp)
    800028b0:	6ba2                	ld	s7,8(sp)
    800028b2:	6c02                	ld	s8,0(sp)
    800028b4:	6161                	addi	sp,sp,80
    800028b6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028b8:	85e2                	mv	a1,s8
    800028ba:	854a                	mv	a0,s2
    800028bc:	00000097          	auipc	ra,0x0
    800028c0:	e7e080e7          	jalr	-386(ra) # 8000273a <sleep>
    havekids = 0;
    800028c4:	b715                	j	800027e8 <wait+0x4a>

00000000800028c6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800028c6:	7139                	addi	sp,sp,-64
    800028c8:	fc06                	sd	ra,56(sp)
    800028ca:	f822                	sd	s0,48(sp)
    800028cc:	f426                	sd	s1,40(sp)
    800028ce:	f04a                	sd	s2,32(sp)
    800028d0:	ec4e                	sd	s3,24(sp)
    800028d2:	e852                	sd	s4,16(sp)
    800028d4:	e456                	sd	s5,8(sp)
    800028d6:	e05a                	sd	s6,0(sp)
    800028d8:	0080                	addi	s0,sp,64
    800028da:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800028dc:	0000f497          	auipc	s1,0xf
    800028e0:	e1448493          	addi	s1,s1,-492 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800028e4:	4989                	li	s3,2
  p->state = RUNNABLE;
    800028e6:	4b0d                	li	s6,3
  p->last_runnable_time = ticks;
    800028e8:	00006a97          	auipc	s5,0x6
    800028ec:	770a8a93          	addi	s5,s5,1904 # 80009058 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    800028f0:	00015917          	auipc	s2,0x15
    800028f4:	00090913          	mv	s2,s2
    800028f8:	a811                	j	8000290c <wakeup+0x46>
        changeStateToRunnable(p);
      }
      release(&p->lock);
    800028fa:	8526                	mv	a0,s1
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	39c080e7          	jalr	924(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002904:	18848493          	addi	s1,s1,392
    80002908:	03248963          	beq	s1,s2,8000293a <wakeup+0x74>
    if(p != myproc()){
    8000290c:	fffff097          	auipc	ra,0xfffff
    80002910:	2ea080e7          	jalr	746(ra) # 80001bf6 <myproc>
    80002914:	fea488e3          	beq	s1,a0,80002904 <wakeup+0x3e>
      acquire(&p->lock);
    80002918:	8526                	mv	a0,s1
    8000291a:	ffffe097          	auipc	ra,0xffffe
    8000291e:	2ca080e7          	jalr	714(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002922:	4c9c                	lw	a5,24(s1)
    80002924:	fd379be3          	bne	a5,s3,800028fa <wakeup+0x34>
    80002928:	709c                	ld	a5,32(s1)
    8000292a:	fd4798e3          	bne	a5,s4,800028fa <wakeup+0x34>
  p->state = RUNNABLE;
    8000292e:	0164ac23          	sw	s6,24(s1)
  p->last_runnable_time = ticks;
    80002932:	000aa783          	lw	a5,0(s5)
    80002936:	c4bc                	sw	a5,72(s1)
}
    80002938:	b7c9                	j	800028fa <wakeup+0x34>
    }
  }
}
    8000293a:	70e2                	ld	ra,56(sp)
    8000293c:	7442                	ld	s0,48(sp)
    8000293e:	74a2                	ld	s1,40(sp)
    80002940:	7902                	ld	s2,32(sp)
    80002942:	69e2                	ld	s3,24(sp)
    80002944:	6a42                	ld	s4,16(sp)
    80002946:	6aa2                	ld	s5,8(sp)
    80002948:	6b02                	ld	s6,0(sp)
    8000294a:	6121                	addi	sp,sp,64
    8000294c:	8082                	ret

000000008000294e <reparent>:
{
    8000294e:	7179                	addi	sp,sp,-48
    80002950:	f406                	sd	ra,40(sp)
    80002952:	f022                	sd	s0,32(sp)
    80002954:	ec26                	sd	s1,24(sp)
    80002956:	e84a                	sd	s2,16(sp)
    80002958:	e44e                	sd	s3,8(sp)
    8000295a:	e052                	sd	s4,0(sp)
    8000295c:	1800                	addi	s0,sp,48
    8000295e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002960:	0000f497          	auipc	s1,0xf
    80002964:	d9048493          	addi	s1,s1,-624 # 800116f0 <proc>
      pp->parent = initproc;
    80002968:	00006a17          	auipc	s4,0x6
    8000296c:	6e8a0a13          	addi	s4,s4,1768 # 80009050 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002970:	00015997          	auipc	s3,0x15
    80002974:	f8098993          	addi	s3,s3,-128 # 800178f0 <tickslock>
    80002978:	a029                	j	80002982 <reparent+0x34>
    8000297a:	18848493          	addi	s1,s1,392
    8000297e:	01348d63          	beq	s1,s3,80002998 <reparent+0x4a>
    if(pp->parent == p){
    80002982:	7c9c                	ld	a5,56(s1)
    80002984:	ff279be3          	bne	a5,s2,8000297a <reparent+0x2c>
      pp->parent = initproc;
    80002988:	000a3503          	ld	a0,0(s4)
    8000298c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000298e:	00000097          	auipc	ra,0x0
    80002992:	f38080e7          	jalr	-200(ra) # 800028c6 <wakeup>
    80002996:	b7d5                	j	8000297a <reparent+0x2c>
}
    80002998:	70a2                	ld	ra,40(sp)
    8000299a:	7402                	ld	s0,32(sp)
    8000299c:	64e2                	ld	s1,24(sp)
    8000299e:	6942                	ld	s2,16(sp)
    800029a0:	69a2                	ld	s3,8(sp)
    800029a2:	6a02                	ld	s4,0(sp)
    800029a4:	6145                	addi	sp,sp,48
    800029a6:	8082                	ret

00000000800029a8 <exit>:
{
    800029a8:	7179                	addi	sp,sp,-48
    800029aa:	f406                	sd	ra,40(sp)
    800029ac:	f022                	sd	s0,32(sp)
    800029ae:	ec26                	sd	s1,24(sp)
    800029b0:	e84a                	sd	s2,16(sp)
    800029b2:	e44e                	sd	s3,8(sp)
    800029b4:	e052                	sd	s4,0(sp)
    800029b6:	1800                	addi	s0,sp,48
    800029b8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800029ba:	fffff097          	auipc	ra,0xfffff
    800029be:	23c080e7          	jalr	572(ra) # 80001bf6 <myproc>
    800029c2:	89aa                	mv	s3,a0
  if(p == initproc)
    800029c4:	00006797          	auipc	a5,0x6
    800029c8:	68c7b783          	ld	a5,1676(a5) # 80009050 <initproc>
    800029cc:	0f050493          	addi	s1,a0,240
    800029d0:	17050913          	addi	s2,a0,368
    800029d4:	02a79363          	bne	a5,a0,800029fa <exit+0x52>
    panic("init exiting");
    800029d8:	00006517          	auipc	a0,0x6
    800029dc:	94850513          	addi	a0,a0,-1720 # 80008320 <digits+0x2e0>
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	b5e080e7          	jalr	-1186(ra) # 8000053e <panic>
      fileclose(f);
    800029e8:	00002097          	auipc	ra,0x2
    800029ec:	2ce080e7          	jalr	718(ra) # 80004cb6 <fileclose>
      p->ofile[fd] = 0;
    800029f0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800029f4:	04a1                	addi	s1,s1,8
    800029f6:	01248563          	beq	s1,s2,80002a00 <exit+0x58>
    if(p->ofile[fd]){
    800029fa:	6088                	ld	a0,0(s1)
    800029fc:	f575                	bnez	a0,800029e8 <exit+0x40>
    800029fe:	bfdd                	j	800029f4 <exit+0x4c>
  begin_op();
    80002a00:	00002097          	auipc	ra,0x2
    80002a04:	dea080e7          	jalr	-534(ra) # 800047ea <begin_op>
  iput(p->cwd);
    80002a08:	1709b503          	ld	a0,368(s3)
    80002a0c:	00001097          	auipc	ra,0x1
    80002a10:	5c6080e7          	jalr	1478(ra) # 80003fd2 <iput>
  end_op();
    80002a14:	00002097          	auipc	ra,0x2
    80002a18:	e56080e7          	jalr	-426(ra) # 8000486a <end_op>
  p->cwd = 0;
    80002a1c:	1609b823          	sd	zero,368(s3)
  acquire(&wait_lock);
    80002a20:	0000f497          	auipc	s1,0xf
    80002a24:	8b848493          	addi	s1,s1,-1864 # 800112d8 <wait_lock>
    80002a28:	8526                	mv	a0,s1
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	1ba080e7          	jalr	442(ra) # 80000be4 <acquire>
  reparent(p);
    80002a32:	854e                	mv	a0,s3
    80002a34:	00000097          	auipc	ra,0x0
    80002a38:	f1a080e7          	jalr	-230(ra) # 8000294e <reparent>
  wakeup(p->parent);
    80002a3c:	0389b503          	ld	a0,56(s3)
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	e86080e7          	jalr	-378(ra) # 800028c6 <wakeup>
  acquire(&p->lock);
    80002a48:	854e                	mv	a0,s3
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	19a080e7          	jalr	410(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002a52:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002a56:	4795                	li	a5,5
    80002a58:	00f9ac23          	sw	a5,24(s3)
  sleeping_processes_mean = (sleeping_processes_mean * sleeping_processes_count + p->sleeping_time) / (sleeping_processes_count+1);
    80002a5c:	00006817          	auipc	a6,0x6
    80002a60:	5e080813          	addi	a6,a6,1504 # 8000903c <sleeping_processes_count>
    80002a64:	00082683          	lw	a3,0(a6)
    80002a68:	0016889b          	addiw	a7,a3,1
    80002a6c:	00006717          	auipc	a4,0x6
    80002a70:	5dc70713          	addi	a4,a4,1500 # 80009048 <sleeping_processes_mean>
    80002a74:	431c                	lw	a5,0(a4)
    80002a76:	02d787bb          	mulw	a5,a5,a3
    80002a7a:	0509a683          	lw	a3,80(s3)
    80002a7e:	9fb5                	addw	a5,a5,a3
    80002a80:	0317c7bb          	divw	a5,a5,a7
    80002a84:	c31c                	sw	a5,0(a4)
  runnable_time_mean = (runnable_time_mean * runnable_time_count + p->runnable_time) / (runnable_time_count+1);
    80002a86:	00006597          	auipc	a1,0x6
    80002a8a:	5b258593          	addi	a1,a1,1458 # 80009038 <runnable_time_count>
    80002a8e:	4194                	lw	a3,0(a1)
    80002a90:	0016851b          	addiw	a0,a3,1
    80002a94:	00006717          	auipc	a4,0x6
    80002a98:	5b070713          	addi	a4,a4,1456 # 80009044 <runnable_time_mean>
    80002a9c:	431c                	lw	a5,0(a4)
    80002a9e:	02d787bb          	mulw	a5,a5,a3
    80002aa2:	0549a683          	lw	a3,84(s3)
    80002aa6:	9fb5                	addw	a5,a5,a3
    80002aa8:	02a7c7bb          	divw	a5,a5,a0
    80002aac:	c31c                	sw	a5,0(a4)
  running_time_mean = (running_time_mean * running_time_count + p->running_time) / (running_time_count+1);
    80002aae:	00006717          	auipc	a4,0x6
    80002ab2:	58670713          	addi	a4,a4,1414 # 80009034 <running_time_count>
    80002ab6:	00072e03          	lw	t3,0(a4)
    80002aba:	0589a683          	lw	a3,88(s3)
    80002abe:	001e061b          	addiw	a2,t3,1
    80002ac2:	00006317          	auipc	t1,0x6
    80002ac6:	57e30313          	addi	t1,t1,1406 # 80009040 <running_time_mean>
    80002aca:	00032783          	lw	a5,0(t1)
    80002ace:	03c787bb          	mulw	a5,a5,t3
    80002ad2:	9fb5                	addw	a5,a5,a3
    80002ad4:	02c7c7bb          	divw	a5,a5,a2
    80002ad8:	00f32023          	sw	a5,0(t1)
  sleeping_processes_count++;
    80002adc:	01182023          	sw	a7,0(a6)
  runnable_time_count++;
    80002ae0:	c188                	sw	a0,0(a1)
  running_time_count++;
    80002ae2:	c310                	sw	a2,0(a4)
  program_time += p->running_time;
    80002ae4:	00006717          	auipc	a4,0x6
    80002ae8:	54c70713          	addi	a4,a4,1356 # 80009030 <program_time>
    80002aec:	431c                	lw	a5,0(a4)
    80002aee:	9fb5                	addw	a5,a5,a3
    80002af0:	c31c                	sw	a5,0(a4)
  cpu_utilization = program_time / (ticks - start_time);
    80002af2:	00006717          	auipc	a4,0x6
    80002af6:	56672703          	lw	a4,1382(a4) # 80009058 <ticks>
    80002afa:	00006697          	auipc	a3,0x6
    80002afe:	52e6a683          	lw	a3,1326(a3) # 80009028 <start_time>
    80002b02:	9f15                	subw	a4,a4,a3
    80002b04:	02e7d7bb          	divuw	a5,a5,a4
    80002b08:	00006717          	auipc	a4,0x6
    80002b0c:	52f72223          	sw	a5,1316(a4) # 8000902c <cpu_utilization>
  release(&wait_lock);
    80002b10:	8526                	mv	a0,s1
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	186080e7          	jalr	390(ra) # 80000c98 <release>
  sched();
    80002b1a:	00000097          	auipc	ra,0x0
    80002b1e:	a62080e7          	jalr	-1438(ra) # 8000257c <sched>
  panic("zombie exit");
    80002b22:	00006517          	auipc	a0,0x6
    80002b26:	80e50513          	addi	a0,a0,-2034 # 80008330 <digits+0x2f0>
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	a14080e7          	jalr	-1516(ra) # 8000053e <panic>

0000000080002b32 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002b32:	7179                	addi	sp,sp,-48
    80002b34:	f406                	sd	ra,40(sp)
    80002b36:	f022                	sd	s0,32(sp)
    80002b38:	ec26                	sd	s1,24(sp)
    80002b3a:	e84a                	sd	s2,16(sp)
    80002b3c:	e44e                	sd	s3,8(sp)
    80002b3e:	1800                	addi	s0,sp,48
    80002b40:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002b42:	0000f497          	auipc	s1,0xf
    80002b46:	bae48493          	addi	s1,s1,-1106 # 800116f0 <proc>
    80002b4a:	00015997          	auipc	s3,0x15
    80002b4e:	da698993          	addi	s3,s3,-602 # 800178f0 <tickslock>
    acquire(&p->lock);
    80002b52:	8526                	mv	a0,s1
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	090080e7          	jalr	144(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002b5c:	589c                	lw	a5,48(s1)
    80002b5e:	01278d63          	beq	a5,s2,80002b78 <kill+0x46>
        changeStateToRunnable(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002b62:	8526                	mv	a0,s1
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	134080e7          	jalr	308(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002b6c:	18848493          	addi	s1,s1,392
    80002b70:	ff3491e3          	bne	s1,s3,80002b52 <kill+0x20>
  }
  return -1;
    80002b74:	557d                	li	a0,-1
    80002b76:	a829                	j	80002b90 <kill+0x5e>
      p->killed = 1;
    80002b78:	4785                	li	a5,1
    80002b7a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002b7c:	4c98                	lw	a4,24(s1)
    80002b7e:	4789                	li	a5,2
    80002b80:	00f70f63          	beq	a4,a5,80002b9e <kill+0x6c>
      release(&p->lock);
    80002b84:	8526                	mv	a0,s1
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	112080e7          	jalr	274(ra) # 80000c98 <release>
      return 0;
    80002b8e:	4501                	li	a0,0
}
    80002b90:	70a2                	ld	ra,40(sp)
    80002b92:	7402                	ld	s0,32(sp)
    80002b94:	64e2                	ld	s1,24(sp)
    80002b96:	6942                	ld	s2,16(sp)
    80002b98:	69a2                	ld	s3,8(sp)
    80002b9a:	6145                	addi	sp,sp,48
    80002b9c:	8082                	ret
  p->state = RUNNABLE;
    80002b9e:	478d                	li	a5,3
    80002ba0:	cc9c                	sw	a5,24(s1)
  p->last_runnable_time = ticks;
    80002ba2:	00006797          	auipc	a5,0x6
    80002ba6:	4b67a783          	lw	a5,1206(a5) # 80009058 <ticks>
    80002baa:	c4bc                	sw	a5,72(s1)
}
    80002bac:	bfe1                	j	80002b84 <kill+0x52>

0000000080002bae <kill_system>:
{
    80002bae:	7179                	addi	sp,sp,-48
    80002bb0:	f406                	sd	ra,40(sp)
    80002bb2:	f022                	sd	s0,32(sp)
    80002bb4:	ec26                	sd	s1,24(sp)
    80002bb6:	e84a                	sd	s2,16(sp)
    80002bb8:	e44e                	sd	s3,8(sp)
    80002bba:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80002bbc:	0000f497          	auipc	s1,0xf
    80002bc0:	b3448493          	addi	s1,s1,-1228 # 800116f0 <proc>
    if (p->pid > 2) // init process and shell?
    80002bc4:	4989                	li	s3,2
  for (p = proc; p < &proc[NPROC]; p++)
    80002bc6:	00015917          	auipc	s2,0x15
    80002bca:	d2a90913          	addi	s2,s2,-726 # 800178f0 <tickslock>
    80002bce:	a809                	j	80002be0 <kill_system+0x32>
      kill(p->pid);
    80002bd0:	00000097          	auipc	ra,0x0
    80002bd4:	f62080e7          	jalr	-158(ra) # 80002b32 <kill>
  for (p = proc; p < &proc[NPROC]; p++)
    80002bd8:	18848493          	addi	s1,s1,392
    80002bdc:	01248663          	beq	s1,s2,80002be8 <kill_system+0x3a>
    if (p->pid > 2) // init process and shell?
    80002be0:	5888                	lw	a0,48(s1)
    80002be2:	fea9dbe3          	bge	s3,a0,80002bd8 <kill_system+0x2a>
    80002be6:	b7ed                	j	80002bd0 <kill_system+0x22>
}
    80002be8:	4501                	li	a0,0
    80002bea:	70a2                	ld	ra,40(sp)
    80002bec:	7402                	ld	s0,32(sp)
    80002bee:	64e2                	ld	s1,24(sp)
    80002bf0:	6942                	ld	s2,16(sp)
    80002bf2:	69a2                	ld	s3,8(sp)
    80002bf4:	6145                	addi	sp,sp,48
    80002bf6:	8082                	ret

0000000080002bf8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002bf8:	7179                	addi	sp,sp,-48
    80002bfa:	f406                	sd	ra,40(sp)
    80002bfc:	f022                	sd	s0,32(sp)
    80002bfe:	ec26                	sd	s1,24(sp)
    80002c00:	e84a                	sd	s2,16(sp)
    80002c02:	e44e                	sd	s3,8(sp)
    80002c04:	e052                	sd	s4,0(sp)
    80002c06:	1800                	addi	s0,sp,48
    80002c08:	84aa                	mv	s1,a0
    80002c0a:	892e                	mv	s2,a1
    80002c0c:	89b2                	mv	s3,a2
    80002c0e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	fe6080e7          	jalr	-26(ra) # 80001bf6 <myproc>
  if(user_dst){
    80002c18:	c08d                	beqz	s1,80002c3a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002c1a:	86d2                	mv	a3,s4
    80002c1c:	864e                	mv	a2,s3
    80002c1e:	85ca                	mv	a1,s2
    80002c20:	7928                	ld	a0,112(a0)
    80002c22:	fffff097          	auipc	ra,0xfffff
    80002c26:	b74080e7          	jalr	-1164(ra) # 80001796 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002c2a:	70a2                	ld	ra,40(sp)
    80002c2c:	7402                	ld	s0,32(sp)
    80002c2e:	64e2                	ld	s1,24(sp)
    80002c30:	6942                	ld	s2,16(sp)
    80002c32:	69a2                	ld	s3,8(sp)
    80002c34:	6a02                	ld	s4,0(sp)
    80002c36:	6145                	addi	sp,sp,48
    80002c38:	8082                	ret
    memmove((char *)dst, src, len);
    80002c3a:	000a061b          	sext.w	a2,s4
    80002c3e:	85ce                	mv	a1,s3
    80002c40:	854a                	mv	a0,s2
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	0fe080e7          	jalr	254(ra) # 80000d40 <memmove>
    return 0;
    80002c4a:	8526                	mv	a0,s1
    80002c4c:	bff9                	j	80002c2a <either_copyout+0x32>

0000000080002c4e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002c4e:	7179                	addi	sp,sp,-48
    80002c50:	f406                	sd	ra,40(sp)
    80002c52:	f022                	sd	s0,32(sp)
    80002c54:	ec26                	sd	s1,24(sp)
    80002c56:	e84a                	sd	s2,16(sp)
    80002c58:	e44e                	sd	s3,8(sp)
    80002c5a:	e052                	sd	s4,0(sp)
    80002c5c:	1800                	addi	s0,sp,48
    80002c5e:	892a                	mv	s2,a0
    80002c60:	84ae                	mv	s1,a1
    80002c62:	89b2                	mv	s3,a2
    80002c64:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002c66:	fffff097          	auipc	ra,0xfffff
    80002c6a:	f90080e7          	jalr	-112(ra) # 80001bf6 <myproc>
  if(user_src){
    80002c6e:	c08d                	beqz	s1,80002c90 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002c70:	86d2                	mv	a3,s4
    80002c72:	864e                	mv	a2,s3
    80002c74:	85ca                	mv	a1,s2
    80002c76:	7928                	ld	a0,112(a0)
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	baa080e7          	jalr	-1110(ra) # 80001822 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002c80:	70a2                	ld	ra,40(sp)
    80002c82:	7402                	ld	s0,32(sp)
    80002c84:	64e2                	ld	s1,24(sp)
    80002c86:	6942                	ld	s2,16(sp)
    80002c88:	69a2                	ld	s3,8(sp)
    80002c8a:	6a02                	ld	s4,0(sp)
    80002c8c:	6145                	addi	sp,sp,48
    80002c8e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002c90:	000a061b          	sext.w	a2,s4
    80002c94:	85ce                	mv	a1,s3
    80002c96:	854a                	mv	a0,s2
    80002c98:	ffffe097          	auipc	ra,0xffffe
    80002c9c:	0a8080e7          	jalr	168(ra) # 80000d40 <memmove>
    return 0;
    80002ca0:	8526                	mv	a0,s1
    80002ca2:	bff9                	j	80002c80 <either_copyin+0x32>

0000000080002ca4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002ca4:	715d                	addi	sp,sp,-80
    80002ca6:	e486                	sd	ra,72(sp)
    80002ca8:	e0a2                	sd	s0,64(sp)
    80002caa:	fc26                	sd	s1,56(sp)
    80002cac:	f84a                	sd	s2,48(sp)
    80002cae:	f44e                	sd	s3,40(sp)
    80002cb0:	f052                	sd	s4,32(sp)
    80002cb2:	ec56                	sd	s5,24(sp)
    80002cb4:	e85a                	sd	s6,16(sp)
    80002cb6:	e45e                	sd	s7,8(sp)
    80002cb8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002cba:	00005517          	auipc	a0,0x5
    80002cbe:	5be50513          	addi	a0,a0,1470 # 80008278 <digits+0x238>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8c6080e7          	jalr	-1850(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002cca:	0000f497          	auipc	s1,0xf
    80002cce:	b9e48493          	addi	s1,s1,-1122 # 80011868 <proc+0x178>
    80002cd2:	00015917          	auipc	s2,0x15
    80002cd6:	d9690913          	addi	s2,s2,-618 # 80017a68 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cda:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002cdc:	00005997          	auipc	s3,0x5
    80002ce0:	66498993          	addi	s3,s3,1636 # 80008340 <digits+0x300>
    printf("%d %s %s", p->pid, state, p->name);
    80002ce4:	00005a97          	auipc	s5,0x5
    80002ce8:	664a8a93          	addi	s5,s5,1636 # 80008348 <digits+0x308>
    printf("\n");
    80002cec:	00005a17          	auipc	s4,0x5
    80002cf0:	58ca0a13          	addi	s4,s4,1420 # 80008278 <digits+0x238>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002cf4:	00005b97          	auipc	s7,0x5
    80002cf8:	68cb8b93          	addi	s7,s7,1676 # 80008380 <states.1795>
    80002cfc:	a00d                	j	80002d1e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002cfe:	eb86a583          	lw	a1,-328(a3)
    80002d02:	8556                	mv	a0,s5
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	884080e7          	jalr	-1916(ra) # 80000588 <printf>
    printf("\n");
    80002d0c:	8552                	mv	a0,s4
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	87a080e7          	jalr	-1926(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d16:	18848493          	addi	s1,s1,392
    80002d1a:	03248163          	beq	s1,s2,80002d3c <procdump+0x98>
    if(p->state == UNUSED)
    80002d1e:	86a6                	mv	a3,s1
    80002d20:	ea04a783          	lw	a5,-352(s1)
    80002d24:	dbed                	beqz	a5,80002d16 <procdump+0x72>
      state = "???";
    80002d26:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002d28:	fcfb6be3          	bltu	s6,a5,80002cfe <procdump+0x5a>
    80002d2c:	1782                	slli	a5,a5,0x20
    80002d2e:	9381                	srli	a5,a5,0x20
    80002d30:	078e                	slli	a5,a5,0x3
    80002d32:	97de                	add	a5,a5,s7
    80002d34:	6390                	ld	a2,0(a5)
    80002d36:	f661                	bnez	a2,80002cfe <procdump+0x5a>
      state = "???";
    80002d38:	864e                	mv	a2,s3
    80002d3a:	b7d1                	j	80002cfe <procdump+0x5a>
  }
}
    80002d3c:	60a6                	ld	ra,72(sp)
    80002d3e:	6406                	ld	s0,64(sp)
    80002d40:	74e2                	ld	s1,56(sp)
    80002d42:	7942                	ld	s2,48(sp)
    80002d44:	79a2                	ld	s3,40(sp)
    80002d46:	7a02                	ld	s4,32(sp)
    80002d48:	6ae2                	ld	s5,24(sp)
    80002d4a:	6b42                	ld	s6,16(sp)
    80002d4c:	6ba2                	ld	s7,8(sp)
    80002d4e:	6161                	addi	sp,sp,80
    80002d50:	8082                	ret

0000000080002d52 <swtch>:
    80002d52:	00153023          	sd	ra,0(a0)
    80002d56:	00253423          	sd	sp,8(a0)
    80002d5a:	e900                	sd	s0,16(a0)
    80002d5c:	ed04                	sd	s1,24(a0)
    80002d5e:	03253023          	sd	s2,32(a0)
    80002d62:	03353423          	sd	s3,40(a0)
    80002d66:	03453823          	sd	s4,48(a0)
    80002d6a:	03553c23          	sd	s5,56(a0)
    80002d6e:	05653023          	sd	s6,64(a0)
    80002d72:	05753423          	sd	s7,72(a0)
    80002d76:	05853823          	sd	s8,80(a0)
    80002d7a:	05953c23          	sd	s9,88(a0)
    80002d7e:	07a53023          	sd	s10,96(a0)
    80002d82:	07b53423          	sd	s11,104(a0)
    80002d86:	0005b083          	ld	ra,0(a1)
    80002d8a:	0085b103          	ld	sp,8(a1)
    80002d8e:	6980                	ld	s0,16(a1)
    80002d90:	6d84                	ld	s1,24(a1)
    80002d92:	0205b903          	ld	s2,32(a1)
    80002d96:	0285b983          	ld	s3,40(a1)
    80002d9a:	0305ba03          	ld	s4,48(a1)
    80002d9e:	0385ba83          	ld	s5,56(a1)
    80002da2:	0405bb03          	ld	s6,64(a1)
    80002da6:	0485bb83          	ld	s7,72(a1)
    80002daa:	0505bc03          	ld	s8,80(a1)
    80002dae:	0585bc83          	ld	s9,88(a1)
    80002db2:	0605bd03          	ld	s10,96(a1)
    80002db6:	0685bd83          	ld	s11,104(a1)
    80002dba:	8082                	ret

0000000080002dbc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002dbc:	1141                	addi	sp,sp,-16
    80002dbe:	e406                	sd	ra,8(sp)
    80002dc0:	e022                	sd	s0,0(sp)
    80002dc2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002dc4:	00005597          	auipc	a1,0x5
    80002dc8:	5ec58593          	addi	a1,a1,1516 # 800083b0 <states.1795+0x30>
    80002dcc:	00015517          	auipc	a0,0x15
    80002dd0:	b2450513          	addi	a0,a0,-1244 # 800178f0 <tickslock>
    80002dd4:	ffffe097          	auipc	ra,0xffffe
    80002dd8:	d80080e7          	jalr	-640(ra) # 80000b54 <initlock>
}
    80002ddc:	60a2                	ld	ra,8(sp)
    80002dde:	6402                	ld	s0,0(sp)
    80002de0:	0141                	addi	sp,sp,16
    80002de2:	8082                	ret

0000000080002de4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002de4:	1141                	addi	sp,sp,-16
    80002de6:	e422                	sd	s0,8(sp)
    80002de8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002dea:	00003797          	auipc	a5,0x3
    80002dee:	4e678793          	addi	a5,a5,1254 # 800062d0 <kernelvec>
    80002df2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002df6:	6422                	ld	s0,8(sp)
    80002df8:	0141                	addi	sp,sp,16
    80002dfa:	8082                	ret

0000000080002dfc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002dfc:	1141                	addi	sp,sp,-16
    80002dfe:	e406                	sd	ra,8(sp)
    80002e00:	e022                	sd	s0,0(sp)
    80002e02:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	df2080e7          	jalr	-526(ra) # 80001bf6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e0c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e10:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e12:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002e16:	00004617          	auipc	a2,0x4
    80002e1a:	1ea60613          	addi	a2,a2,490 # 80007000 <_trampoline>
    80002e1e:	00004697          	auipc	a3,0x4
    80002e22:	1e268693          	addi	a3,a3,482 # 80007000 <_trampoline>
    80002e26:	8e91                	sub	a3,a3,a2
    80002e28:	040007b7          	lui	a5,0x4000
    80002e2c:	17fd                	addi	a5,a5,-1
    80002e2e:	07b2                	slli	a5,a5,0xc
    80002e30:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e32:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e36:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e38:	180026f3          	csrr	a3,satp
    80002e3c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e3e:	7d38                	ld	a4,120(a0)
    80002e40:	7134                	ld	a3,96(a0)
    80002e42:	6585                	lui	a1,0x1
    80002e44:	96ae                	add	a3,a3,a1
    80002e46:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e48:	7d38                	ld	a4,120(a0)
    80002e4a:	00000697          	auipc	a3,0x0
    80002e4e:	13868693          	addi	a3,a3,312 # 80002f82 <usertrap>
    80002e52:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e54:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e56:	8692                	mv	a3,tp
    80002e58:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e5a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e5e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e62:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e66:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002e6a:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e6c:	6f18                	ld	a4,24(a4)
    80002e6e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002e72:	792c                	ld	a1,112(a0)
    80002e74:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002e76:	00004717          	auipc	a4,0x4
    80002e7a:	21a70713          	addi	a4,a4,538 # 80007090 <userret>
    80002e7e:	8f11                	sub	a4,a4,a2
    80002e80:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002e82:	577d                	li	a4,-1
    80002e84:	177e                	slli	a4,a4,0x3f
    80002e86:	8dd9                	or	a1,a1,a4
    80002e88:	02000537          	lui	a0,0x2000
    80002e8c:	157d                	addi	a0,a0,-1
    80002e8e:	0536                	slli	a0,a0,0xd
    80002e90:	9782                	jalr	a5
}
    80002e92:	60a2                	ld	ra,8(sp)
    80002e94:	6402                	ld	s0,0(sp)
    80002e96:	0141                	addi	sp,sp,16
    80002e98:	8082                	ret

0000000080002e9a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002e9a:	1101                	addi	sp,sp,-32
    80002e9c:	ec06                	sd	ra,24(sp)
    80002e9e:	e822                	sd	s0,16(sp)
    80002ea0:	e426                	sd	s1,8(sp)
    80002ea2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ea4:	00015497          	auipc	s1,0x15
    80002ea8:	a4c48493          	addi	s1,s1,-1460 # 800178f0 <tickslock>
    80002eac:	8526                	mv	a0,s1
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	d36080e7          	jalr	-714(ra) # 80000be4 <acquire>
  ticks++;
    80002eb6:	00006517          	auipc	a0,0x6
    80002eba:	1a250513          	addi	a0,a0,418 # 80009058 <ticks>
    80002ebe:	411c                	lw	a5,0(a0)
    80002ec0:	2785                	addiw	a5,a5,1
    80002ec2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ec4:	00000097          	auipc	ra,0x0
    80002ec8:	a02080e7          	jalr	-1534(ra) # 800028c6 <wakeup>
  release(&tickslock);
    80002ecc:	8526                	mv	a0,s1
    80002ece:	ffffe097          	auipc	ra,0xffffe
    80002ed2:	dca080e7          	jalr	-566(ra) # 80000c98 <release>
}
    80002ed6:	60e2                	ld	ra,24(sp)
    80002ed8:	6442                	ld	s0,16(sp)
    80002eda:	64a2                	ld	s1,8(sp)
    80002edc:	6105                	addi	sp,sp,32
    80002ede:	8082                	ret

0000000080002ee0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ee0:	1101                	addi	sp,sp,-32
    80002ee2:	ec06                	sd	ra,24(sp)
    80002ee4:	e822                	sd	s0,16(sp)
    80002ee6:	e426                	sd	s1,8(sp)
    80002ee8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eea:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002eee:	00074d63          	bltz	a4,80002f08 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ef2:	57fd                	li	a5,-1
    80002ef4:	17fe                	slli	a5,a5,0x3f
    80002ef6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ef8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002efa:	06f70363          	beq	a4,a5,80002f60 <devintr+0x80>
  }
}
    80002efe:	60e2                	ld	ra,24(sp)
    80002f00:	6442                	ld	s0,16(sp)
    80002f02:	64a2                	ld	s1,8(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret
     (scause & 0xff) == 9){
    80002f08:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f0c:	46a5                	li	a3,9
    80002f0e:	fed792e3          	bne	a5,a3,80002ef2 <devintr+0x12>
    int irq = plic_claim();
    80002f12:	00003097          	auipc	ra,0x3
    80002f16:	4c6080e7          	jalr	1222(ra) # 800063d8 <plic_claim>
    80002f1a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f1c:	47a9                	li	a5,10
    80002f1e:	02f50763          	beq	a0,a5,80002f4c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002f22:	4785                	li	a5,1
    80002f24:	02f50963          	beq	a0,a5,80002f56 <devintr+0x76>
    return 1;
    80002f28:	4505                	li	a0,1
    } else if(irq){
    80002f2a:	d8f1                	beqz	s1,80002efe <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f2c:	85a6                	mv	a1,s1
    80002f2e:	00005517          	auipc	a0,0x5
    80002f32:	48a50513          	addi	a0,a0,1162 # 800083b8 <states.1795+0x38>
    80002f36:	ffffd097          	auipc	ra,0xffffd
    80002f3a:	652080e7          	jalr	1618(ra) # 80000588 <printf>
      plic_complete(irq);
    80002f3e:	8526                	mv	a0,s1
    80002f40:	00003097          	auipc	ra,0x3
    80002f44:	4bc080e7          	jalr	1212(ra) # 800063fc <plic_complete>
    return 1;
    80002f48:	4505                	li	a0,1
    80002f4a:	bf55                	j	80002efe <devintr+0x1e>
      uartintr();
    80002f4c:	ffffe097          	auipc	ra,0xffffe
    80002f50:	a5c080e7          	jalr	-1444(ra) # 800009a8 <uartintr>
    80002f54:	b7ed                	j	80002f3e <devintr+0x5e>
      virtio_disk_intr();
    80002f56:	00004097          	auipc	ra,0x4
    80002f5a:	986080e7          	jalr	-1658(ra) # 800068dc <virtio_disk_intr>
    80002f5e:	b7c5                	j	80002f3e <devintr+0x5e>
    if(cpuid() == 0){
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	c6a080e7          	jalr	-918(ra) # 80001bca <cpuid>
    80002f68:	c901                	beqz	a0,80002f78 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002f6a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002f6e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002f70:	14479073          	csrw	sip,a5
    return 2;
    80002f74:	4509                	li	a0,2
    80002f76:	b761                	j	80002efe <devintr+0x1e>
      clockintr();
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	f22080e7          	jalr	-222(ra) # 80002e9a <clockintr>
    80002f80:	b7ed                	j	80002f6a <devintr+0x8a>

0000000080002f82 <usertrap>:
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	e426                	sd	s1,8(sp)
    80002f8a:	e04a                	sd	s2,0(sp)
    80002f8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f8e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002f92:	1007f793          	andi	a5,a5,256
    80002f96:	e3ad                	bnez	a5,80002ff8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f98:	00003797          	auipc	a5,0x3
    80002f9c:	33878793          	addi	a5,a5,824 # 800062d0 <kernelvec>
    80002fa0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	c52080e7          	jalr	-942(ra) # 80001bf6 <myproc>
    80002fac:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002fae:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fb0:	14102773          	csrr	a4,sepc
    80002fb4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fb6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002fba:	47a1                	li	a5,8
    80002fbc:	04f71c63          	bne	a4,a5,80003014 <usertrap+0x92>
    if(p->killed)
    80002fc0:	551c                	lw	a5,40(a0)
    80002fc2:	e3b9                	bnez	a5,80003008 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002fc4:	7cb8                	ld	a4,120(s1)
    80002fc6:	6f1c                	ld	a5,24(a4)
    80002fc8:	0791                	addi	a5,a5,4
    80002fca:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fcc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002fd0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fd4:	10079073          	csrw	sstatus,a5
    syscall();
    80002fd8:	00000097          	auipc	ra,0x0
    80002fdc:	2e0080e7          	jalr	736(ra) # 800032b8 <syscall>
  if(p->killed)
    80002fe0:	549c                	lw	a5,40(s1)
    80002fe2:	ebc1                	bnez	a5,80003072 <usertrap+0xf0>
  usertrapret();
    80002fe4:	00000097          	auipc	ra,0x0
    80002fe8:	e18080e7          	jalr	-488(ra) # 80002dfc <usertrapret>
}
    80002fec:	60e2                	ld	ra,24(sp)
    80002fee:	6442                	ld	s0,16(sp)
    80002ff0:	64a2                	ld	s1,8(sp)
    80002ff2:	6902                	ld	s2,0(sp)
    80002ff4:	6105                	addi	sp,sp,32
    80002ff6:	8082                	ret
    panic("usertrap: not from user mode");
    80002ff8:	00005517          	auipc	a0,0x5
    80002ffc:	3e050513          	addi	a0,a0,992 # 800083d8 <states.1795+0x58>
    80003000:	ffffd097          	auipc	ra,0xffffd
    80003004:	53e080e7          	jalr	1342(ra) # 8000053e <panic>
      exit(-1);
    80003008:	557d                	li	a0,-1
    8000300a:	00000097          	auipc	ra,0x0
    8000300e:	99e080e7          	jalr	-1634(ra) # 800029a8 <exit>
    80003012:	bf4d                	j	80002fc4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003014:	00000097          	auipc	ra,0x0
    80003018:	ecc080e7          	jalr	-308(ra) # 80002ee0 <devintr>
    8000301c:	892a                	mv	s2,a0
    8000301e:	c501                	beqz	a0,80003026 <usertrap+0xa4>
  if(p->killed)
    80003020:	549c                	lw	a5,40(s1)
    80003022:	c3a1                	beqz	a5,80003062 <usertrap+0xe0>
    80003024:	a815                	j	80003058 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003026:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000302a:	5890                	lw	a2,48(s1)
    8000302c:	00005517          	auipc	a0,0x5
    80003030:	3cc50513          	addi	a0,a0,972 # 800083f8 <states.1795+0x78>
    80003034:	ffffd097          	auipc	ra,0xffffd
    80003038:	554080e7          	jalr	1364(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000303c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003040:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003044:	00005517          	auipc	a0,0x5
    80003048:	3e450513          	addi	a0,a0,996 # 80008428 <states.1795+0xa8>
    8000304c:	ffffd097          	auipc	ra,0xffffd
    80003050:	53c080e7          	jalr	1340(ra) # 80000588 <printf>
    p->killed = 1;
    80003054:	4785                	li	a5,1
    80003056:	d49c                	sw	a5,40(s1)
    exit(-1);
    80003058:	557d                	li	a0,-1
    8000305a:	00000097          	auipc	ra,0x0
    8000305e:	94e080e7          	jalr	-1714(ra) # 800029a8 <exit>
  if(which_dev == 2)
    80003062:	4789                	li	a5,2
    80003064:	f8f910e3          	bne	s2,a5,80002fe4 <usertrap+0x62>
    yield();
    80003068:	fffff097          	auipc	ra,0xfffff
    8000306c:	5ea080e7          	jalr	1514(ra) # 80002652 <yield>
    80003070:	bf95                	j	80002fe4 <usertrap+0x62>
  int which_dev = 0;
    80003072:	4901                	li	s2,0
    80003074:	b7d5                	j	80003058 <usertrap+0xd6>

0000000080003076 <kerneltrap>:
{
    80003076:	7179                	addi	sp,sp,-48
    80003078:	f406                	sd	ra,40(sp)
    8000307a:	f022                	sd	s0,32(sp)
    8000307c:	ec26                	sd	s1,24(sp)
    8000307e:	e84a                	sd	s2,16(sp)
    80003080:	e44e                	sd	s3,8(sp)
    80003082:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003084:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003088:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000308c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003090:	1004f793          	andi	a5,s1,256
    80003094:	cb85                	beqz	a5,800030c4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003096:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000309a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000309c:	ef85                	bnez	a5,800030d4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000309e:	00000097          	auipc	ra,0x0
    800030a2:	e42080e7          	jalr	-446(ra) # 80002ee0 <devintr>
    800030a6:	cd1d                	beqz	a0,800030e4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030a8:	4789                	li	a5,2
    800030aa:	06f50a63          	beq	a0,a5,8000311e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030ae:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030b2:	10049073          	csrw	sstatus,s1
}
    800030b6:	70a2                	ld	ra,40(sp)
    800030b8:	7402                	ld	s0,32(sp)
    800030ba:	64e2                	ld	s1,24(sp)
    800030bc:	6942                	ld	s2,16(sp)
    800030be:	69a2                	ld	s3,8(sp)
    800030c0:	6145                	addi	sp,sp,48
    800030c2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030c4:	00005517          	auipc	a0,0x5
    800030c8:	38450513          	addi	a0,a0,900 # 80008448 <states.1795+0xc8>
    800030cc:	ffffd097          	auipc	ra,0xffffd
    800030d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800030d4:	00005517          	auipc	a0,0x5
    800030d8:	39c50513          	addi	a0,a0,924 # 80008470 <states.1795+0xf0>
    800030dc:	ffffd097          	auipc	ra,0xffffd
    800030e0:	462080e7          	jalr	1122(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800030e4:	85ce                	mv	a1,s3
    800030e6:	00005517          	auipc	a0,0x5
    800030ea:	3aa50513          	addi	a0,a0,938 # 80008490 <states.1795+0x110>
    800030ee:	ffffd097          	auipc	ra,0xffffd
    800030f2:	49a080e7          	jalr	1178(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030f6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800030fa:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800030fe:	00005517          	auipc	a0,0x5
    80003102:	3a250513          	addi	a0,a0,930 # 800084a0 <states.1795+0x120>
    80003106:	ffffd097          	auipc	ra,0xffffd
    8000310a:	482080e7          	jalr	1154(ra) # 80000588 <printf>
    panic("kerneltrap");
    8000310e:	00005517          	auipc	a0,0x5
    80003112:	3aa50513          	addi	a0,a0,938 # 800084b8 <states.1795+0x138>
    80003116:	ffffd097          	auipc	ra,0xffffd
    8000311a:	428080e7          	jalr	1064(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000311e:	fffff097          	auipc	ra,0xfffff
    80003122:	ad8080e7          	jalr	-1320(ra) # 80001bf6 <myproc>
    80003126:	d541                	beqz	a0,800030ae <kerneltrap+0x38>
    80003128:	fffff097          	auipc	ra,0xfffff
    8000312c:	ace080e7          	jalr	-1330(ra) # 80001bf6 <myproc>
    80003130:	4d18                	lw	a4,24(a0)
    80003132:	4791                	li	a5,4
    80003134:	f6f71de3          	bne	a4,a5,800030ae <kerneltrap+0x38>
    yield();
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	51a080e7          	jalr	1306(ra) # 80002652 <yield>
    80003140:	b7bd                	j	800030ae <kerneltrap+0x38>

0000000080003142 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000314e:	fffff097          	auipc	ra,0xfffff
    80003152:	aa8080e7          	jalr	-1368(ra) # 80001bf6 <myproc>
  switch (n) {
    80003156:	4795                	li	a5,5
    80003158:	0497e163          	bltu	a5,s1,8000319a <argraw+0x58>
    8000315c:	048a                	slli	s1,s1,0x2
    8000315e:	00005717          	auipc	a4,0x5
    80003162:	39270713          	addi	a4,a4,914 # 800084f0 <states.1795+0x170>
    80003166:	94ba                	add	s1,s1,a4
    80003168:	409c                	lw	a5,0(s1)
    8000316a:	97ba                	add	a5,a5,a4
    8000316c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000316e:	7d3c                	ld	a5,120(a0)
    80003170:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003172:	60e2                	ld	ra,24(sp)
    80003174:	6442                	ld	s0,16(sp)
    80003176:	64a2                	ld	s1,8(sp)
    80003178:	6105                	addi	sp,sp,32
    8000317a:	8082                	ret
    return p->trapframe->a1;
    8000317c:	7d3c                	ld	a5,120(a0)
    8000317e:	7fa8                	ld	a0,120(a5)
    80003180:	bfcd                	j	80003172 <argraw+0x30>
    return p->trapframe->a2;
    80003182:	7d3c                	ld	a5,120(a0)
    80003184:	63c8                	ld	a0,128(a5)
    80003186:	b7f5                	j	80003172 <argraw+0x30>
    return p->trapframe->a3;
    80003188:	7d3c                	ld	a5,120(a0)
    8000318a:	67c8                	ld	a0,136(a5)
    8000318c:	b7dd                	j	80003172 <argraw+0x30>
    return p->trapframe->a4;
    8000318e:	7d3c                	ld	a5,120(a0)
    80003190:	6bc8                	ld	a0,144(a5)
    80003192:	b7c5                	j	80003172 <argraw+0x30>
    return p->trapframe->a5;
    80003194:	7d3c                	ld	a5,120(a0)
    80003196:	6fc8                	ld	a0,152(a5)
    80003198:	bfe9                	j	80003172 <argraw+0x30>
  panic("argraw");
    8000319a:	00005517          	auipc	a0,0x5
    8000319e:	32e50513          	addi	a0,a0,814 # 800084c8 <states.1795+0x148>
    800031a2:	ffffd097          	auipc	ra,0xffffd
    800031a6:	39c080e7          	jalr	924(ra) # 8000053e <panic>

00000000800031aa <fetchaddr>:
{
    800031aa:	1101                	addi	sp,sp,-32
    800031ac:	ec06                	sd	ra,24(sp)
    800031ae:	e822                	sd	s0,16(sp)
    800031b0:	e426                	sd	s1,8(sp)
    800031b2:	e04a                	sd	s2,0(sp)
    800031b4:	1000                	addi	s0,sp,32
    800031b6:	84aa                	mv	s1,a0
    800031b8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031ba:	fffff097          	auipc	ra,0xfffff
    800031be:	a3c080e7          	jalr	-1476(ra) # 80001bf6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031c2:	753c                	ld	a5,104(a0)
    800031c4:	02f4f863          	bgeu	s1,a5,800031f4 <fetchaddr+0x4a>
    800031c8:	00848713          	addi	a4,s1,8
    800031cc:	02e7e663          	bltu	a5,a4,800031f8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031d0:	46a1                	li	a3,8
    800031d2:	8626                	mv	a2,s1
    800031d4:	85ca                	mv	a1,s2
    800031d6:	7928                	ld	a0,112(a0)
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	64a080e7          	jalr	1610(ra) # 80001822 <copyin>
    800031e0:	00a03533          	snez	a0,a0
    800031e4:	40a00533          	neg	a0,a0
}
    800031e8:	60e2                	ld	ra,24(sp)
    800031ea:	6442                	ld	s0,16(sp)
    800031ec:	64a2                	ld	s1,8(sp)
    800031ee:	6902                	ld	s2,0(sp)
    800031f0:	6105                	addi	sp,sp,32
    800031f2:	8082                	ret
    return -1;
    800031f4:	557d                	li	a0,-1
    800031f6:	bfcd                	j	800031e8 <fetchaddr+0x3e>
    800031f8:	557d                	li	a0,-1
    800031fa:	b7fd                	j	800031e8 <fetchaddr+0x3e>

00000000800031fc <fetchstr>:
{
    800031fc:	7179                	addi	sp,sp,-48
    800031fe:	f406                	sd	ra,40(sp)
    80003200:	f022                	sd	s0,32(sp)
    80003202:	ec26                	sd	s1,24(sp)
    80003204:	e84a                	sd	s2,16(sp)
    80003206:	e44e                	sd	s3,8(sp)
    80003208:	1800                	addi	s0,sp,48
    8000320a:	892a                	mv	s2,a0
    8000320c:	84ae                	mv	s1,a1
    8000320e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003210:	fffff097          	auipc	ra,0xfffff
    80003214:	9e6080e7          	jalr	-1562(ra) # 80001bf6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003218:	86ce                	mv	a3,s3
    8000321a:	864a                	mv	a2,s2
    8000321c:	85a6                	mv	a1,s1
    8000321e:	7928                	ld	a0,112(a0)
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	68e080e7          	jalr	1678(ra) # 800018ae <copyinstr>
  if(err < 0)
    80003228:	00054763          	bltz	a0,80003236 <fetchstr+0x3a>
  return strlen(buf);
    8000322c:	8526                	mv	a0,s1
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	c36080e7          	jalr	-970(ra) # 80000e64 <strlen>
}
    80003236:	70a2                	ld	ra,40(sp)
    80003238:	7402                	ld	s0,32(sp)
    8000323a:	64e2                	ld	s1,24(sp)
    8000323c:	6942                	ld	s2,16(sp)
    8000323e:	69a2                	ld	s3,8(sp)
    80003240:	6145                	addi	sp,sp,48
    80003242:	8082                	ret

0000000080003244 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003244:	1101                	addi	sp,sp,-32
    80003246:	ec06                	sd	ra,24(sp)
    80003248:	e822                	sd	s0,16(sp)
    8000324a:	e426                	sd	s1,8(sp)
    8000324c:	1000                	addi	s0,sp,32
    8000324e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003250:	00000097          	auipc	ra,0x0
    80003254:	ef2080e7          	jalr	-270(ra) # 80003142 <argraw>
    80003258:	c088                	sw	a0,0(s1)
  return 0;
}
    8000325a:	4501                	li	a0,0
    8000325c:	60e2                	ld	ra,24(sp)
    8000325e:	6442                	ld	s0,16(sp)
    80003260:	64a2                	ld	s1,8(sp)
    80003262:	6105                	addi	sp,sp,32
    80003264:	8082                	ret

0000000080003266 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	e426                	sd	s1,8(sp)
    8000326e:	1000                	addi	s0,sp,32
    80003270:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003272:	00000097          	auipc	ra,0x0
    80003276:	ed0080e7          	jalr	-304(ra) # 80003142 <argraw>
    8000327a:	e088                	sd	a0,0(s1)
  return 0;
}
    8000327c:	4501                	li	a0,0
    8000327e:	60e2                	ld	ra,24(sp)
    80003280:	6442                	ld	s0,16(sp)
    80003282:	64a2                	ld	s1,8(sp)
    80003284:	6105                	addi	sp,sp,32
    80003286:	8082                	ret

0000000080003288 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003288:	1101                	addi	sp,sp,-32
    8000328a:	ec06                	sd	ra,24(sp)
    8000328c:	e822                	sd	s0,16(sp)
    8000328e:	e426                	sd	s1,8(sp)
    80003290:	e04a                	sd	s2,0(sp)
    80003292:	1000                	addi	s0,sp,32
    80003294:	84ae                	mv	s1,a1
    80003296:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	eaa080e7          	jalr	-342(ra) # 80003142 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032a0:	864a                	mv	a2,s2
    800032a2:	85a6                	mv	a1,s1
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	f58080e7          	jalr	-168(ra) # 800031fc <fetchstr>
}
    800032ac:	60e2                	ld	ra,24(sp)
    800032ae:	6442                	ld	s0,16(sp)
    800032b0:	64a2                	ld	s1,8(sp)
    800032b2:	6902                	ld	s2,0(sp)
    800032b4:	6105                	addi	sp,sp,32
    800032b6:	8082                	ret

00000000800032b8 <syscall>:
[SYS_print_stats]   sys_print_stats
};

void
syscall(void)
{
    800032b8:	1101                	addi	sp,sp,-32
    800032ba:	ec06                	sd	ra,24(sp)
    800032bc:	e822                	sd	s0,16(sp)
    800032be:	e426                	sd	s1,8(sp)
    800032c0:	e04a                	sd	s2,0(sp)
    800032c2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032c4:	fffff097          	auipc	ra,0xfffff
    800032c8:	932080e7          	jalr	-1742(ra) # 80001bf6 <myproc>
    800032cc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032ce:	07853903          	ld	s2,120(a0)
    800032d2:	0a893783          	ld	a5,168(s2)
    800032d6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032da:	37fd                	addiw	a5,a5,-1
    800032dc:	475d                	li	a4,23
    800032de:	00f76f63          	bltu	a4,a5,800032fc <syscall+0x44>
    800032e2:	00369713          	slli	a4,a3,0x3
    800032e6:	00005797          	auipc	a5,0x5
    800032ea:	22278793          	addi	a5,a5,546 # 80008508 <syscalls>
    800032ee:	97ba                	add	a5,a5,a4
    800032f0:	639c                	ld	a5,0(a5)
    800032f2:	c789                	beqz	a5,800032fc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800032f4:	9782                	jalr	a5
    800032f6:	06a93823          	sd	a0,112(s2)
    800032fa:	a839                	j	80003318 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800032fc:	17848613          	addi	a2,s1,376
    80003300:	588c                	lw	a1,48(s1)
    80003302:	00005517          	auipc	a0,0x5
    80003306:	1ce50513          	addi	a0,a0,462 # 800084d0 <states.1795+0x150>
    8000330a:	ffffd097          	auipc	ra,0xffffd
    8000330e:	27e080e7          	jalr	638(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003312:	7cbc                	ld	a5,120(s1)
    80003314:	577d                	li	a4,-1
    80003316:	fbb8                	sd	a4,112(a5)
  }
}
    80003318:	60e2                	ld	ra,24(sp)
    8000331a:	6442                	ld	s0,16(sp)
    8000331c:	64a2                	ld	s1,8(sp)
    8000331e:	6902                	ld	s2,0(sp)
    80003320:	6105                	addi	sp,sp,32
    80003322:	8082                	ret

0000000080003324 <sys_pause_system>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_pause_system(void)
{
    80003324:	1101                	addi	sp,sp,-32
    80003326:	ec06                	sd	ra,24(sp)
    80003328:	e822                	sd	s0,16(sp)
    8000332a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000332c:	fec40593          	addi	a1,s0,-20
    80003330:	4501                	li	a0,0
    80003332:	00000097          	auipc	ra,0x0
    80003336:	f12080e7          	jalr	-238(ra) # 80003244 <argint>
    8000333a:	87aa                	mv	a5,a0
    return -1;
    8000333c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000333e:	0007c863          	bltz	a5,8000334e <sys_pause_system+0x2a>
  
  return pause_system(n);
    80003342:	fec42503          	lw	a0,-20(s0)
    80003346:	fffff097          	auipc	ra,0xfffff
    8000334a:	352080e7          	jalr	850(ra) # 80002698 <pause_system>
}
    8000334e:	60e2                	ld	ra,24(sp)
    80003350:	6442                	ld	s0,16(sp)
    80003352:	6105                	addi	sp,sp,32
    80003354:	8082                	ret

0000000080003356 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80003356:	1141                	addi	sp,sp,-16
    80003358:	e406                	sd	ra,8(sp)
    8000335a:	e022                	sd	s0,0(sp)
    8000335c:	0800                	addi	s0,sp,16
  return kill_system();
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	850080e7          	jalr	-1968(ra) # 80002bae <kill_system>
}
    80003366:	60a2                	ld	ra,8(sp)
    80003368:	6402                	ld	s0,0(sp)
    8000336a:	0141                	addi	sp,sp,16
    8000336c:	8082                	ret

000000008000336e <sys_print_stats>:

uint64
sys_print_stats(void)
{
    8000336e:	1141                	addi	sp,sp,-16
    80003370:	e406                	sd	ra,8(sp)
    80003372:	e022                	sd	s0,0(sp)
    80003374:	0800                	addi	s0,sp,16
  return print_stats();
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	66c080e7          	jalr	1644(ra) # 800019e2 <print_stats>
}
    8000337e:	60a2                	ld	ra,8(sp)
    80003380:	6402                	ld	s0,0(sp)
    80003382:	0141                	addi	sp,sp,16
    80003384:	8082                	ret

0000000080003386 <sys_exit>:

uint64
sys_exit(void)
{
    80003386:	1101                	addi	sp,sp,-32
    80003388:	ec06                	sd	ra,24(sp)
    8000338a:	e822                	sd	s0,16(sp)
    8000338c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000338e:	fec40593          	addi	a1,s0,-20
    80003392:	4501                	li	a0,0
    80003394:	00000097          	auipc	ra,0x0
    80003398:	eb0080e7          	jalr	-336(ra) # 80003244 <argint>
    return -1;
    8000339c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000339e:	00054963          	bltz	a0,800033b0 <sys_exit+0x2a>
  exit(n);
    800033a2:	fec42503          	lw	a0,-20(s0)
    800033a6:	fffff097          	auipc	ra,0xfffff
    800033aa:	602080e7          	jalr	1538(ra) # 800029a8 <exit>
  return 0;  // not reached
    800033ae:	4781                	li	a5,0
}
    800033b0:	853e                	mv	a0,a5
    800033b2:	60e2                	ld	ra,24(sp)
    800033b4:	6442                	ld	s0,16(sp)
    800033b6:	6105                	addi	sp,sp,32
    800033b8:	8082                	ret

00000000800033ba <sys_getpid>:

uint64
sys_getpid(void)
{
    800033ba:	1141                	addi	sp,sp,-16
    800033bc:	e406                	sd	ra,8(sp)
    800033be:	e022                	sd	s0,0(sp)
    800033c0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033c2:	fffff097          	auipc	ra,0xfffff
    800033c6:	834080e7          	jalr	-1996(ra) # 80001bf6 <myproc>
}
    800033ca:	5908                	lw	a0,48(a0)
    800033cc:	60a2                	ld	ra,8(sp)
    800033ce:	6402                	ld	s0,0(sp)
    800033d0:	0141                	addi	sp,sp,16
    800033d2:	8082                	ret

00000000800033d4 <sys_fork>:

uint64
sys_fork(void)
{
    800033d4:	1141                	addi	sp,sp,-16
    800033d6:	e406                	sd	ra,8(sp)
    800033d8:	e022                	sd	s0,0(sp)
    800033da:	0800                	addi	s0,sp,16
  return fork();
    800033dc:	fffff097          	auipc	ra,0xfffff
    800033e0:	bfe080e7          	jalr	-1026(ra) # 80001fda <fork>
}
    800033e4:	60a2                	ld	ra,8(sp)
    800033e6:	6402                	ld	s0,0(sp)
    800033e8:	0141                	addi	sp,sp,16
    800033ea:	8082                	ret

00000000800033ec <sys_wait>:

uint64
sys_wait(void)
{
    800033ec:	1101                	addi	sp,sp,-32
    800033ee:	ec06                	sd	ra,24(sp)
    800033f0:	e822                	sd	s0,16(sp)
    800033f2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800033f4:	fe840593          	addi	a1,s0,-24
    800033f8:	4501                	li	a0,0
    800033fa:	00000097          	auipc	ra,0x0
    800033fe:	e6c080e7          	jalr	-404(ra) # 80003266 <argaddr>
    80003402:	87aa                	mv	a5,a0
    return -1;
    80003404:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003406:	0007c863          	bltz	a5,80003416 <sys_wait+0x2a>
  return wait(p);
    8000340a:	fe843503          	ld	a0,-24(s0)
    8000340e:	fffff097          	auipc	ra,0xfffff
    80003412:	390080e7          	jalr	912(ra) # 8000279e <wait>
}
    80003416:	60e2                	ld	ra,24(sp)
    80003418:	6442                	ld	s0,16(sp)
    8000341a:	6105                	addi	sp,sp,32
    8000341c:	8082                	ret

000000008000341e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000341e:	7179                	addi	sp,sp,-48
    80003420:	f406                	sd	ra,40(sp)
    80003422:	f022                	sd	s0,32(sp)
    80003424:	ec26                	sd	s1,24(sp)
    80003426:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003428:	fdc40593          	addi	a1,s0,-36
    8000342c:	4501                	li	a0,0
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	e16080e7          	jalr	-490(ra) # 80003244 <argint>
    80003436:	87aa                	mv	a5,a0
    return -1;
    80003438:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000343a:	0207c063          	bltz	a5,8000345a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	7b8080e7          	jalr	1976(ra) # 80001bf6 <myproc>
    80003446:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003448:	fdc42503          	lw	a0,-36(s0)
    8000344c:	fffff097          	auipc	ra,0xfffff
    80003450:	b1a080e7          	jalr	-1254(ra) # 80001f66 <growproc>
    80003454:	00054863          	bltz	a0,80003464 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003458:	8526                	mv	a0,s1
}
    8000345a:	70a2                	ld	ra,40(sp)
    8000345c:	7402                	ld	s0,32(sp)
    8000345e:	64e2                	ld	s1,24(sp)
    80003460:	6145                	addi	sp,sp,48
    80003462:	8082                	ret
    return -1;
    80003464:	557d                	li	a0,-1
    80003466:	bfd5                	j	8000345a <sys_sbrk+0x3c>

0000000080003468 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003468:	7139                	addi	sp,sp,-64
    8000346a:	fc06                	sd	ra,56(sp)
    8000346c:	f822                	sd	s0,48(sp)
    8000346e:	f426                	sd	s1,40(sp)
    80003470:	f04a                	sd	s2,32(sp)
    80003472:	ec4e                	sd	s3,24(sp)
    80003474:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003476:	fcc40593          	addi	a1,s0,-52
    8000347a:	4501                	li	a0,0
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	dc8080e7          	jalr	-568(ra) # 80003244 <argint>
    return -1;
    80003484:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003486:	06054563          	bltz	a0,800034f0 <sys_sleep+0x88>
  acquire(&tickslock);
    8000348a:	00014517          	auipc	a0,0x14
    8000348e:	46650513          	addi	a0,a0,1126 # 800178f0 <tickslock>
    80003492:	ffffd097          	auipc	ra,0xffffd
    80003496:	752080e7          	jalr	1874(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000349a:	00006917          	auipc	s2,0x6
    8000349e:	bbe92903          	lw	s2,-1090(s2) # 80009058 <ticks>
  while(ticks - ticks0 < n){
    800034a2:	fcc42783          	lw	a5,-52(s0)
    800034a6:	cf85                	beqz	a5,800034de <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034a8:	00014997          	auipc	s3,0x14
    800034ac:	44898993          	addi	s3,s3,1096 # 800178f0 <tickslock>
    800034b0:	00006497          	auipc	s1,0x6
    800034b4:	ba848493          	addi	s1,s1,-1112 # 80009058 <ticks>
    if(myproc()->killed){
    800034b8:	ffffe097          	auipc	ra,0xffffe
    800034bc:	73e080e7          	jalr	1854(ra) # 80001bf6 <myproc>
    800034c0:	551c                	lw	a5,40(a0)
    800034c2:	ef9d                	bnez	a5,80003500 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800034c4:	85ce                	mv	a1,s3
    800034c6:	8526                	mv	a0,s1
    800034c8:	fffff097          	auipc	ra,0xfffff
    800034cc:	272080e7          	jalr	626(ra) # 8000273a <sleep>
  while(ticks - ticks0 < n){
    800034d0:	409c                	lw	a5,0(s1)
    800034d2:	412787bb          	subw	a5,a5,s2
    800034d6:	fcc42703          	lw	a4,-52(s0)
    800034da:	fce7efe3          	bltu	a5,a4,800034b8 <sys_sleep+0x50>
  }
  release(&tickslock);
    800034de:	00014517          	auipc	a0,0x14
    800034e2:	41250513          	addi	a0,a0,1042 # 800178f0 <tickslock>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	7b2080e7          	jalr	1970(ra) # 80000c98 <release>
  return 0;
    800034ee:	4781                	li	a5,0
}
    800034f0:	853e                	mv	a0,a5
    800034f2:	70e2                	ld	ra,56(sp)
    800034f4:	7442                	ld	s0,48(sp)
    800034f6:	74a2                	ld	s1,40(sp)
    800034f8:	7902                	ld	s2,32(sp)
    800034fa:	69e2                	ld	s3,24(sp)
    800034fc:	6121                	addi	sp,sp,64
    800034fe:	8082                	ret
      release(&tickslock);
    80003500:	00014517          	auipc	a0,0x14
    80003504:	3f050513          	addi	a0,a0,1008 # 800178f0 <tickslock>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	790080e7          	jalr	1936(ra) # 80000c98 <release>
      return -1;
    80003510:	57fd                	li	a5,-1
    80003512:	bff9                	j	800034f0 <sys_sleep+0x88>

0000000080003514 <sys_kill>:

uint64
sys_kill(void)
{
    80003514:	1101                	addi	sp,sp,-32
    80003516:	ec06                	sd	ra,24(sp)
    80003518:	e822                	sd	s0,16(sp)
    8000351a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000351c:	fec40593          	addi	a1,s0,-20
    80003520:	4501                	li	a0,0
    80003522:	00000097          	auipc	ra,0x0
    80003526:	d22080e7          	jalr	-734(ra) # 80003244 <argint>
    8000352a:	87aa                	mv	a5,a0
    return -1;
    8000352c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000352e:	0007c863          	bltz	a5,8000353e <sys_kill+0x2a>
  return kill(pid);
    80003532:	fec42503          	lw	a0,-20(s0)
    80003536:	fffff097          	auipc	ra,0xfffff
    8000353a:	5fc080e7          	jalr	1532(ra) # 80002b32 <kill>
}
    8000353e:	60e2                	ld	ra,24(sp)
    80003540:	6442                	ld	s0,16(sp)
    80003542:	6105                	addi	sp,sp,32
    80003544:	8082                	ret

0000000080003546 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003546:	1101                	addi	sp,sp,-32
    80003548:	ec06                	sd	ra,24(sp)
    8000354a:	e822                	sd	s0,16(sp)
    8000354c:	e426                	sd	s1,8(sp)
    8000354e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003550:	00014517          	auipc	a0,0x14
    80003554:	3a050513          	addi	a0,a0,928 # 800178f0 <tickslock>
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	68c080e7          	jalr	1676(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003560:	00006497          	auipc	s1,0x6
    80003564:	af84a483          	lw	s1,-1288(s1) # 80009058 <ticks>
  release(&tickslock);
    80003568:	00014517          	auipc	a0,0x14
    8000356c:	38850513          	addi	a0,a0,904 # 800178f0 <tickslock>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	728080e7          	jalr	1832(ra) # 80000c98 <release>
  return xticks;
}
    80003578:	02049513          	slli	a0,s1,0x20
    8000357c:	9101                	srli	a0,a0,0x20
    8000357e:	60e2                	ld	ra,24(sp)
    80003580:	6442                	ld	s0,16(sp)
    80003582:	64a2                	ld	s1,8(sp)
    80003584:	6105                	addi	sp,sp,32
    80003586:	8082                	ret

0000000080003588 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003588:	7179                	addi	sp,sp,-48
    8000358a:	f406                	sd	ra,40(sp)
    8000358c:	f022                	sd	s0,32(sp)
    8000358e:	ec26                	sd	s1,24(sp)
    80003590:	e84a                	sd	s2,16(sp)
    80003592:	e44e                	sd	s3,8(sp)
    80003594:	e052                	sd	s4,0(sp)
    80003596:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003598:	00005597          	auipc	a1,0x5
    8000359c:	03858593          	addi	a1,a1,56 # 800085d0 <syscalls+0xc8>
    800035a0:	00014517          	auipc	a0,0x14
    800035a4:	36850513          	addi	a0,a0,872 # 80017908 <bcache>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	5ac080e7          	jalr	1452(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035b0:	0001c797          	auipc	a5,0x1c
    800035b4:	35878793          	addi	a5,a5,856 # 8001f908 <bcache+0x8000>
    800035b8:	0001c717          	auipc	a4,0x1c
    800035bc:	5b870713          	addi	a4,a4,1464 # 8001fb70 <bcache+0x8268>
    800035c0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035c4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035c8:	00014497          	auipc	s1,0x14
    800035cc:	35848493          	addi	s1,s1,856 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    800035d0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035d2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035d4:	00005a17          	auipc	s4,0x5
    800035d8:	004a0a13          	addi	s4,s4,4 # 800085d8 <syscalls+0xd0>
    b->next = bcache.head.next;
    800035dc:	2b893783          	ld	a5,696(s2)
    800035e0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035e2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035e6:	85d2                	mv	a1,s4
    800035e8:	01048513          	addi	a0,s1,16
    800035ec:	00001097          	auipc	ra,0x1
    800035f0:	4bc080e7          	jalr	1212(ra) # 80004aa8 <initsleeplock>
    bcache.head.next->prev = b;
    800035f4:	2b893783          	ld	a5,696(s2)
    800035f8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035fa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035fe:	45848493          	addi	s1,s1,1112
    80003602:	fd349de3          	bne	s1,s3,800035dc <binit+0x54>
  }
}
    80003606:	70a2                	ld	ra,40(sp)
    80003608:	7402                	ld	s0,32(sp)
    8000360a:	64e2                	ld	s1,24(sp)
    8000360c:	6942                	ld	s2,16(sp)
    8000360e:	69a2                	ld	s3,8(sp)
    80003610:	6a02                	ld	s4,0(sp)
    80003612:	6145                	addi	sp,sp,48
    80003614:	8082                	ret

0000000080003616 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003616:	7179                	addi	sp,sp,-48
    80003618:	f406                	sd	ra,40(sp)
    8000361a:	f022                	sd	s0,32(sp)
    8000361c:	ec26                	sd	s1,24(sp)
    8000361e:	e84a                	sd	s2,16(sp)
    80003620:	e44e                	sd	s3,8(sp)
    80003622:	1800                	addi	s0,sp,48
    80003624:	89aa                	mv	s3,a0
    80003626:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003628:	00014517          	auipc	a0,0x14
    8000362c:	2e050513          	addi	a0,a0,736 # 80017908 <bcache>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	5b4080e7          	jalr	1460(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003638:	0001c497          	auipc	s1,0x1c
    8000363c:	5884b483          	ld	s1,1416(s1) # 8001fbc0 <bcache+0x82b8>
    80003640:	0001c797          	auipc	a5,0x1c
    80003644:	53078793          	addi	a5,a5,1328 # 8001fb70 <bcache+0x8268>
    80003648:	02f48f63          	beq	s1,a5,80003686 <bread+0x70>
    8000364c:	873e                	mv	a4,a5
    8000364e:	a021                	j	80003656 <bread+0x40>
    80003650:	68a4                	ld	s1,80(s1)
    80003652:	02e48a63          	beq	s1,a4,80003686 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003656:	449c                	lw	a5,8(s1)
    80003658:	ff379ce3          	bne	a5,s3,80003650 <bread+0x3a>
    8000365c:	44dc                	lw	a5,12(s1)
    8000365e:	ff2799e3          	bne	a5,s2,80003650 <bread+0x3a>
      b->refcnt++;
    80003662:	40bc                	lw	a5,64(s1)
    80003664:	2785                	addiw	a5,a5,1
    80003666:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003668:	00014517          	auipc	a0,0x14
    8000366c:	2a050513          	addi	a0,a0,672 # 80017908 <bcache>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	628080e7          	jalr	1576(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003678:	01048513          	addi	a0,s1,16
    8000367c:	00001097          	auipc	ra,0x1
    80003680:	466080e7          	jalr	1126(ra) # 80004ae2 <acquiresleep>
      return b;
    80003684:	a8b9                	j	800036e2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003686:	0001c497          	auipc	s1,0x1c
    8000368a:	5324b483          	ld	s1,1330(s1) # 8001fbb8 <bcache+0x82b0>
    8000368e:	0001c797          	auipc	a5,0x1c
    80003692:	4e278793          	addi	a5,a5,1250 # 8001fb70 <bcache+0x8268>
    80003696:	00f48863          	beq	s1,a5,800036a6 <bread+0x90>
    8000369a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000369c:	40bc                	lw	a5,64(s1)
    8000369e:	cf81                	beqz	a5,800036b6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036a0:	64a4                	ld	s1,72(s1)
    800036a2:	fee49de3          	bne	s1,a4,8000369c <bread+0x86>
  panic("bget: no buffers");
    800036a6:	00005517          	auipc	a0,0x5
    800036aa:	f3a50513          	addi	a0,a0,-198 # 800085e0 <syscalls+0xd8>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	e90080e7          	jalr	-368(ra) # 8000053e <panic>
      b->dev = dev;
    800036b6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800036ba:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800036be:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036c2:	4785                	li	a5,1
    800036c4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036c6:	00014517          	auipc	a0,0x14
    800036ca:	24250513          	addi	a0,a0,578 # 80017908 <bcache>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	5ca080e7          	jalr	1482(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800036d6:	01048513          	addi	a0,s1,16
    800036da:	00001097          	auipc	ra,0x1
    800036de:	408080e7          	jalr	1032(ra) # 80004ae2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036e2:	409c                	lw	a5,0(s1)
    800036e4:	cb89                	beqz	a5,800036f6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036e6:	8526                	mv	a0,s1
    800036e8:	70a2                	ld	ra,40(sp)
    800036ea:	7402                	ld	s0,32(sp)
    800036ec:	64e2                	ld	s1,24(sp)
    800036ee:	6942                	ld	s2,16(sp)
    800036f0:	69a2                	ld	s3,8(sp)
    800036f2:	6145                	addi	sp,sp,48
    800036f4:	8082                	ret
    virtio_disk_rw(b, 0);
    800036f6:	4581                	li	a1,0
    800036f8:	8526                	mv	a0,s1
    800036fa:	00003097          	auipc	ra,0x3
    800036fe:	f0c080e7          	jalr	-244(ra) # 80006606 <virtio_disk_rw>
    b->valid = 1;
    80003702:	4785                	li	a5,1
    80003704:	c09c                	sw	a5,0(s1)
  return b;
    80003706:	b7c5                	j	800036e6 <bread+0xd0>

0000000080003708 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003708:	1101                	addi	sp,sp,-32
    8000370a:	ec06                	sd	ra,24(sp)
    8000370c:	e822                	sd	s0,16(sp)
    8000370e:	e426                	sd	s1,8(sp)
    80003710:	1000                	addi	s0,sp,32
    80003712:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003714:	0541                	addi	a0,a0,16
    80003716:	00001097          	auipc	ra,0x1
    8000371a:	466080e7          	jalr	1126(ra) # 80004b7c <holdingsleep>
    8000371e:	cd01                	beqz	a0,80003736 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003720:	4585                	li	a1,1
    80003722:	8526                	mv	a0,s1
    80003724:	00003097          	auipc	ra,0x3
    80003728:	ee2080e7          	jalr	-286(ra) # 80006606 <virtio_disk_rw>
}
    8000372c:	60e2                	ld	ra,24(sp)
    8000372e:	6442                	ld	s0,16(sp)
    80003730:	64a2                	ld	s1,8(sp)
    80003732:	6105                	addi	sp,sp,32
    80003734:	8082                	ret
    panic("bwrite");
    80003736:	00005517          	auipc	a0,0x5
    8000373a:	ec250513          	addi	a0,a0,-318 # 800085f8 <syscalls+0xf0>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	e00080e7          	jalr	-512(ra) # 8000053e <panic>

0000000080003746 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003746:	1101                	addi	sp,sp,-32
    80003748:	ec06                	sd	ra,24(sp)
    8000374a:	e822                	sd	s0,16(sp)
    8000374c:	e426                	sd	s1,8(sp)
    8000374e:	e04a                	sd	s2,0(sp)
    80003750:	1000                	addi	s0,sp,32
    80003752:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003754:	01050913          	addi	s2,a0,16
    80003758:	854a                	mv	a0,s2
    8000375a:	00001097          	auipc	ra,0x1
    8000375e:	422080e7          	jalr	1058(ra) # 80004b7c <holdingsleep>
    80003762:	c92d                	beqz	a0,800037d4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003764:	854a                	mv	a0,s2
    80003766:	00001097          	auipc	ra,0x1
    8000376a:	3d2080e7          	jalr	978(ra) # 80004b38 <releasesleep>

  acquire(&bcache.lock);
    8000376e:	00014517          	auipc	a0,0x14
    80003772:	19a50513          	addi	a0,a0,410 # 80017908 <bcache>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	46e080e7          	jalr	1134(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000377e:	40bc                	lw	a5,64(s1)
    80003780:	37fd                	addiw	a5,a5,-1
    80003782:	0007871b          	sext.w	a4,a5
    80003786:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003788:	eb05                	bnez	a4,800037b8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000378a:	68bc                	ld	a5,80(s1)
    8000378c:	64b8                	ld	a4,72(s1)
    8000378e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003790:	64bc                	ld	a5,72(s1)
    80003792:	68b8                	ld	a4,80(s1)
    80003794:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003796:	0001c797          	auipc	a5,0x1c
    8000379a:	17278793          	addi	a5,a5,370 # 8001f908 <bcache+0x8000>
    8000379e:	2b87b703          	ld	a4,696(a5)
    800037a2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037a4:	0001c717          	auipc	a4,0x1c
    800037a8:	3cc70713          	addi	a4,a4,972 # 8001fb70 <bcache+0x8268>
    800037ac:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037ae:	2b87b703          	ld	a4,696(a5)
    800037b2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037b4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037b8:	00014517          	auipc	a0,0x14
    800037bc:	15050513          	addi	a0,a0,336 # 80017908 <bcache>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	4d8080e7          	jalr	1240(ra) # 80000c98 <release>
}
    800037c8:	60e2                	ld	ra,24(sp)
    800037ca:	6442                	ld	s0,16(sp)
    800037cc:	64a2                	ld	s1,8(sp)
    800037ce:	6902                	ld	s2,0(sp)
    800037d0:	6105                	addi	sp,sp,32
    800037d2:	8082                	ret
    panic("brelse");
    800037d4:	00005517          	auipc	a0,0x5
    800037d8:	e2c50513          	addi	a0,a0,-468 # 80008600 <syscalls+0xf8>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	d62080e7          	jalr	-670(ra) # 8000053e <panic>

00000000800037e4 <bpin>:

void
bpin(struct buf *b) {
    800037e4:	1101                	addi	sp,sp,-32
    800037e6:	ec06                	sd	ra,24(sp)
    800037e8:	e822                	sd	s0,16(sp)
    800037ea:	e426                	sd	s1,8(sp)
    800037ec:	1000                	addi	s0,sp,32
    800037ee:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037f0:	00014517          	auipc	a0,0x14
    800037f4:	11850513          	addi	a0,a0,280 # 80017908 <bcache>
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	3ec080e7          	jalr	1004(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003800:	40bc                	lw	a5,64(s1)
    80003802:	2785                	addiw	a5,a5,1
    80003804:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003806:	00014517          	auipc	a0,0x14
    8000380a:	10250513          	addi	a0,a0,258 # 80017908 <bcache>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	48a080e7          	jalr	1162(ra) # 80000c98 <release>
}
    80003816:	60e2                	ld	ra,24(sp)
    80003818:	6442                	ld	s0,16(sp)
    8000381a:	64a2                	ld	s1,8(sp)
    8000381c:	6105                	addi	sp,sp,32
    8000381e:	8082                	ret

0000000080003820 <bunpin>:

void
bunpin(struct buf *b) {
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
  b->refcnt--;
    8000383c:	40bc                	lw	a5,64(s1)
    8000383e:	37fd                	addiw	a5,a5,-1
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

000000008000385c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000385c:	1101                	addi	sp,sp,-32
    8000385e:	ec06                	sd	ra,24(sp)
    80003860:	e822                	sd	s0,16(sp)
    80003862:	e426                	sd	s1,8(sp)
    80003864:	e04a                	sd	s2,0(sp)
    80003866:	1000                	addi	s0,sp,32
    80003868:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000386a:	00d5d59b          	srliw	a1,a1,0xd
    8000386e:	0001c797          	auipc	a5,0x1c
    80003872:	7767a783          	lw	a5,1910(a5) # 8001ffe4 <sb+0x1c>
    80003876:	9dbd                	addw	a1,a1,a5
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	d9e080e7          	jalr	-610(ra) # 80003616 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003880:	0074f713          	andi	a4,s1,7
    80003884:	4785                	li	a5,1
    80003886:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000388a:	14ce                	slli	s1,s1,0x33
    8000388c:	90d9                	srli	s1,s1,0x36
    8000388e:	00950733          	add	a4,a0,s1
    80003892:	05874703          	lbu	a4,88(a4)
    80003896:	00e7f6b3          	and	a3,a5,a4
    8000389a:	c69d                	beqz	a3,800038c8 <bfree+0x6c>
    8000389c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000389e:	94aa                	add	s1,s1,a0
    800038a0:	fff7c793          	not	a5,a5
    800038a4:	8ff9                	and	a5,a5,a4
    800038a6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800038aa:	00001097          	auipc	ra,0x1
    800038ae:	118080e7          	jalr	280(ra) # 800049c2 <log_write>
  brelse(bp);
    800038b2:	854a                	mv	a0,s2
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	e92080e7          	jalr	-366(ra) # 80003746 <brelse>
}
    800038bc:	60e2                	ld	ra,24(sp)
    800038be:	6442                	ld	s0,16(sp)
    800038c0:	64a2                	ld	s1,8(sp)
    800038c2:	6902                	ld	s2,0(sp)
    800038c4:	6105                	addi	sp,sp,32
    800038c6:	8082                	ret
    panic("freeing free block");
    800038c8:	00005517          	auipc	a0,0x5
    800038cc:	d4050513          	addi	a0,a0,-704 # 80008608 <syscalls+0x100>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	c6e080e7          	jalr	-914(ra) # 8000053e <panic>

00000000800038d8 <balloc>:
{
    800038d8:	711d                	addi	sp,sp,-96
    800038da:	ec86                	sd	ra,88(sp)
    800038dc:	e8a2                	sd	s0,80(sp)
    800038de:	e4a6                	sd	s1,72(sp)
    800038e0:	e0ca                	sd	s2,64(sp)
    800038e2:	fc4e                	sd	s3,56(sp)
    800038e4:	f852                	sd	s4,48(sp)
    800038e6:	f456                	sd	s5,40(sp)
    800038e8:	f05a                	sd	s6,32(sp)
    800038ea:	ec5e                	sd	s7,24(sp)
    800038ec:	e862                	sd	s8,16(sp)
    800038ee:	e466                	sd	s9,8(sp)
    800038f0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038f2:	0001c797          	auipc	a5,0x1c
    800038f6:	6da7a783          	lw	a5,1754(a5) # 8001ffcc <sb+0x4>
    800038fa:	cbd1                	beqz	a5,8000398e <balloc+0xb6>
    800038fc:	8baa                	mv	s7,a0
    800038fe:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003900:	0001cb17          	auipc	s6,0x1c
    80003904:	6c8b0b13          	addi	s6,s6,1736 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003908:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000390a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000390c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000390e:	6c89                	lui	s9,0x2
    80003910:	a831                	j	8000392c <balloc+0x54>
    brelse(bp);
    80003912:	854a                	mv	a0,s2
    80003914:	00000097          	auipc	ra,0x0
    80003918:	e32080e7          	jalr	-462(ra) # 80003746 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000391c:	015c87bb          	addw	a5,s9,s5
    80003920:	00078a9b          	sext.w	s5,a5
    80003924:	004b2703          	lw	a4,4(s6)
    80003928:	06eaf363          	bgeu	s5,a4,8000398e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000392c:	41fad79b          	sraiw	a5,s5,0x1f
    80003930:	0137d79b          	srliw	a5,a5,0x13
    80003934:	015787bb          	addw	a5,a5,s5
    80003938:	40d7d79b          	sraiw	a5,a5,0xd
    8000393c:	01cb2583          	lw	a1,28(s6)
    80003940:	9dbd                	addw	a1,a1,a5
    80003942:	855e                	mv	a0,s7
    80003944:	00000097          	auipc	ra,0x0
    80003948:	cd2080e7          	jalr	-814(ra) # 80003616 <bread>
    8000394c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000394e:	004b2503          	lw	a0,4(s6)
    80003952:	000a849b          	sext.w	s1,s5
    80003956:	8662                	mv	a2,s8
    80003958:	faa4fde3          	bgeu	s1,a0,80003912 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000395c:	41f6579b          	sraiw	a5,a2,0x1f
    80003960:	01d7d69b          	srliw	a3,a5,0x1d
    80003964:	00c6873b          	addw	a4,a3,a2
    80003968:	00777793          	andi	a5,a4,7
    8000396c:	9f95                	subw	a5,a5,a3
    8000396e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003972:	4037571b          	sraiw	a4,a4,0x3
    80003976:	00e906b3          	add	a3,s2,a4
    8000397a:	0586c683          	lbu	a3,88(a3)
    8000397e:	00d7f5b3          	and	a1,a5,a3
    80003982:	cd91                	beqz	a1,8000399e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003984:	2605                	addiw	a2,a2,1
    80003986:	2485                	addiw	s1,s1,1
    80003988:	fd4618e3          	bne	a2,s4,80003958 <balloc+0x80>
    8000398c:	b759                	j	80003912 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000398e:	00005517          	auipc	a0,0x5
    80003992:	c9250513          	addi	a0,a0,-878 # 80008620 <syscalls+0x118>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	ba8080e7          	jalr	-1112(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000399e:	974a                	add	a4,a4,s2
    800039a0:	8fd5                	or	a5,a5,a3
    800039a2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800039a6:	854a                	mv	a0,s2
    800039a8:	00001097          	auipc	ra,0x1
    800039ac:	01a080e7          	jalr	26(ra) # 800049c2 <log_write>
        brelse(bp);
    800039b0:	854a                	mv	a0,s2
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	d94080e7          	jalr	-620(ra) # 80003746 <brelse>
  bp = bread(dev, bno);
    800039ba:	85a6                	mv	a1,s1
    800039bc:	855e                	mv	a0,s7
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	c58080e7          	jalr	-936(ra) # 80003616 <bread>
    800039c6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039c8:	40000613          	li	a2,1024
    800039cc:	4581                	li	a1,0
    800039ce:	05850513          	addi	a0,a0,88
    800039d2:	ffffd097          	auipc	ra,0xffffd
    800039d6:	30e080e7          	jalr	782(ra) # 80000ce0 <memset>
  log_write(bp);
    800039da:	854a                	mv	a0,s2
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	fe6080e7          	jalr	-26(ra) # 800049c2 <log_write>
  brelse(bp);
    800039e4:	854a                	mv	a0,s2
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	d60080e7          	jalr	-672(ra) # 80003746 <brelse>
}
    800039ee:	8526                	mv	a0,s1
    800039f0:	60e6                	ld	ra,88(sp)
    800039f2:	6446                	ld	s0,80(sp)
    800039f4:	64a6                	ld	s1,72(sp)
    800039f6:	6906                	ld	s2,64(sp)
    800039f8:	79e2                	ld	s3,56(sp)
    800039fa:	7a42                	ld	s4,48(sp)
    800039fc:	7aa2                	ld	s5,40(sp)
    800039fe:	7b02                	ld	s6,32(sp)
    80003a00:	6be2                	ld	s7,24(sp)
    80003a02:	6c42                	ld	s8,16(sp)
    80003a04:	6ca2                	ld	s9,8(sp)
    80003a06:	6125                	addi	sp,sp,96
    80003a08:	8082                	ret

0000000080003a0a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a0a:	7179                	addi	sp,sp,-48
    80003a0c:	f406                	sd	ra,40(sp)
    80003a0e:	f022                	sd	s0,32(sp)
    80003a10:	ec26                	sd	s1,24(sp)
    80003a12:	e84a                	sd	s2,16(sp)
    80003a14:	e44e                	sd	s3,8(sp)
    80003a16:	e052                	sd	s4,0(sp)
    80003a18:	1800                	addi	s0,sp,48
    80003a1a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a1c:	47ad                	li	a5,11
    80003a1e:	04b7fe63          	bgeu	a5,a1,80003a7a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a22:	ff45849b          	addiw	s1,a1,-12
    80003a26:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a2a:	0ff00793          	li	a5,255
    80003a2e:	0ae7e363          	bltu	a5,a4,80003ad4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a32:	08052583          	lw	a1,128(a0)
    80003a36:	c5ad                	beqz	a1,80003aa0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a38:	00092503          	lw	a0,0(s2)
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	bda080e7          	jalr	-1062(ra) # 80003616 <bread>
    80003a44:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a46:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a4a:	02049593          	slli	a1,s1,0x20
    80003a4e:	9181                	srli	a1,a1,0x20
    80003a50:	058a                	slli	a1,a1,0x2
    80003a52:	00b784b3          	add	s1,a5,a1
    80003a56:	0004a983          	lw	s3,0(s1)
    80003a5a:	04098d63          	beqz	s3,80003ab4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a5e:	8552                	mv	a0,s4
    80003a60:	00000097          	auipc	ra,0x0
    80003a64:	ce6080e7          	jalr	-794(ra) # 80003746 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a68:	854e                	mv	a0,s3
    80003a6a:	70a2                	ld	ra,40(sp)
    80003a6c:	7402                	ld	s0,32(sp)
    80003a6e:	64e2                	ld	s1,24(sp)
    80003a70:	6942                	ld	s2,16(sp)
    80003a72:	69a2                	ld	s3,8(sp)
    80003a74:	6a02                	ld	s4,0(sp)
    80003a76:	6145                	addi	sp,sp,48
    80003a78:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a7a:	02059493          	slli	s1,a1,0x20
    80003a7e:	9081                	srli	s1,s1,0x20
    80003a80:	048a                	slli	s1,s1,0x2
    80003a82:	94aa                	add	s1,s1,a0
    80003a84:	0504a983          	lw	s3,80(s1)
    80003a88:	fe0990e3          	bnez	s3,80003a68 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a8c:	4108                	lw	a0,0(a0)
    80003a8e:	00000097          	auipc	ra,0x0
    80003a92:	e4a080e7          	jalr	-438(ra) # 800038d8 <balloc>
    80003a96:	0005099b          	sext.w	s3,a0
    80003a9a:	0534a823          	sw	s3,80(s1)
    80003a9e:	b7e9                	j	80003a68 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003aa0:	4108                	lw	a0,0(a0)
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	e36080e7          	jalr	-458(ra) # 800038d8 <balloc>
    80003aaa:	0005059b          	sext.w	a1,a0
    80003aae:	08b92023          	sw	a1,128(s2)
    80003ab2:	b759                	j	80003a38 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003ab4:	00092503          	lw	a0,0(s2)
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	e20080e7          	jalr	-480(ra) # 800038d8 <balloc>
    80003ac0:	0005099b          	sext.w	s3,a0
    80003ac4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003ac8:	8552                	mv	a0,s4
    80003aca:	00001097          	auipc	ra,0x1
    80003ace:	ef8080e7          	jalr	-264(ra) # 800049c2 <log_write>
    80003ad2:	b771                	j	80003a5e <bmap+0x54>
  panic("bmap: out of range");
    80003ad4:	00005517          	auipc	a0,0x5
    80003ad8:	b6450513          	addi	a0,a0,-1180 # 80008638 <syscalls+0x130>
    80003adc:	ffffd097          	auipc	ra,0xffffd
    80003ae0:	a62080e7          	jalr	-1438(ra) # 8000053e <panic>

0000000080003ae4 <iget>:
{
    80003ae4:	7179                	addi	sp,sp,-48
    80003ae6:	f406                	sd	ra,40(sp)
    80003ae8:	f022                	sd	s0,32(sp)
    80003aea:	ec26                	sd	s1,24(sp)
    80003aec:	e84a                	sd	s2,16(sp)
    80003aee:	e44e                	sd	s3,8(sp)
    80003af0:	e052                	sd	s4,0(sp)
    80003af2:	1800                	addi	s0,sp,48
    80003af4:	89aa                	mv	s3,a0
    80003af6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003af8:	0001c517          	auipc	a0,0x1c
    80003afc:	4f050513          	addi	a0,a0,1264 # 8001ffe8 <itable>
    80003b00:	ffffd097          	auipc	ra,0xffffd
    80003b04:	0e4080e7          	jalr	228(ra) # 80000be4 <acquire>
  empty = 0;
    80003b08:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b0a:	0001c497          	auipc	s1,0x1c
    80003b0e:	4f648493          	addi	s1,s1,1270 # 80020000 <itable+0x18>
    80003b12:	0001e697          	auipc	a3,0x1e
    80003b16:	f7e68693          	addi	a3,a3,-130 # 80021a90 <log>
    80003b1a:	a039                	j	80003b28 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b1c:	02090b63          	beqz	s2,80003b52 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b20:	08848493          	addi	s1,s1,136
    80003b24:	02d48a63          	beq	s1,a3,80003b58 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b28:	449c                	lw	a5,8(s1)
    80003b2a:	fef059e3          	blez	a5,80003b1c <iget+0x38>
    80003b2e:	4098                	lw	a4,0(s1)
    80003b30:	ff3716e3          	bne	a4,s3,80003b1c <iget+0x38>
    80003b34:	40d8                	lw	a4,4(s1)
    80003b36:	ff4713e3          	bne	a4,s4,80003b1c <iget+0x38>
      ip->ref++;
    80003b3a:	2785                	addiw	a5,a5,1
    80003b3c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b3e:	0001c517          	auipc	a0,0x1c
    80003b42:	4aa50513          	addi	a0,a0,1194 # 8001ffe8 <itable>
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	152080e7          	jalr	338(ra) # 80000c98 <release>
      return ip;
    80003b4e:	8926                	mv	s2,s1
    80003b50:	a03d                	j	80003b7e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b52:	f7f9                	bnez	a5,80003b20 <iget+0x3c>
    80003b54:	8926                	mv	s2,s1
    80003b56:	b7e9                	j	80003b20 <iget+0x3c>
  if(empty == 0)
    80003b58:	02090c63          	beqz	s2,80003b90 <iget+0xac>
  ip->dev = dev;
    80003b5c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b60:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b64:	4785                	li	a5,1
    80003b66:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b6a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b6e:	0001c517          	auipc	a0,0x1c
    80003b72:	47a50513          	addi	a0,a0,1146 # 8001ffe8 <itable>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	122080e7          	jalr	290(ra) # 80000c98 <release>
}
    80003b7e:	854a                	mv	a0,s2
    80003b80:	70a2                	ld	ra,40(sp)
    80003b82:	7402                	ld	s0,32(sp)
    80003b84:	64e2                	ld	s1,24(sp)
    80003b86:	6942                	ld	s2,16(sp)
    80003b88:	69a2                	ld	s3,8(sp)
    80003b8a:	6a02                	ld	s4,0(sp)
    80003b8c:	6145                	addi	sp,sp,48
    80003b8e:	8082                	ret
    panic("iget: no inodes");
    80003b90:	00005517          	auipc	a0,0x5
    80003b94:	ac050513          	addi	a0,a0,-1344 # 80008650 <syscalls+0x148>
    80003b98:	ffffd097          	auipc	ra,0xffffd
    80003b9c:	9a6080e7          	jalr	-1626(ra) # 8000053e <panic>

0000000080003ba0 <fsinit>:
fsinit(int dev) {
    80003ba0:	7179                	addi	sp,sp,-48
    80003ba2:	f406                	sd	ra,40(sp)
    80003ba4:	f022                	sd	s0,32(sp)
    80003ba6:	ec26                	sd	s1,24(sp)
    80003ba8:	e84a                	sd	s2,16(sp)
    80003baa:	e44e                	sd	s3,8(sp)
    80003bac:	1800                	addi	s0,sp,48
    80003bae:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bb0:	4585                	li	a1,1
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	a64080e7          	jalr	-1436(ra) # 80003616 <bread>
    80003bba:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bbc:	0001c997          	auipc	s3,0x1c
    80003bc0:	40c98993          	addi	s3,s3,1036 # 8001ffc8 <sb>
    80003bc4:	02000613          	li	a2,32
    80003bc8:	05850593          	addi	a1,a0,88
    80003bcc:	854e                	mv	a0,s3
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	172080e7          	jalr	370(ra) # 80000d40 <memmove>
  brelse(bp);
    80003bd6:	8526                	mv	a0,s1
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	b6e080e7          	jalr	-1170(ra) # 80003746 <brelse>
  if(sb.magic != FSMAGIC)
    80003be0:	0009a703          	lw	a4,0(s3)
    80003be4:	102037b7          	lui	a5,0x10203
    80003be8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bec:	02f71263          	bne	a4,a5,80003c10 <fsinit+0x70>
  initlog(dev, &sb);
    80003bf0:	0001c597          	auipc	a1,0x1c
    80003bf4:	3d858593          	addi	a1,a1,984 # 8001ffc8 <sb>
    80003bf8:	854a                	mv	a0,s2
    80003bfa:	00001097          	auipc	ra,0x1
    80003bfe:	b4c080e7          	jalr	-1204(ra) # 80004746 <initlog>
}
    80003c02:	70a2                	ld	ra,40(sp)
    80003c04:	7402                	ld	s0,32(sp)
    80003c06:	64e2                	ld	s1,24(sp)
    80003c08:	6942                	ld	s2,16(sp)
    80003c0a:	69a2                	ld	s3,8(sp)
    80003c0c:	6145                	addi	sp,sp,48
    80003c0e:	8082                	ret
    panic("invalid file system");
    80003c10:	00005517          	auipc	a0,0x5
    80003c14:	a5050513          	addi	a0,a0,-1456 # 80008660 <syscalls+0x158>
    80003c18:	ffffd097          	auipc	ra,0xffffd
    80003c1c:	926080e7          	jalr	-1754(ra) # 8000053e <panic>

0000000080003c20 <iinit>:
{
    80003c20:	7179                	addi	sp,sp,-48
    80003c22:	f406                	sd	ra,40(sp)
    80003c24:	f022                	sd	s0,32(sp)
    80003c26:	ec26                	sd	s1,24(sp)
    80003c28:	e84a                	sd	s2,16(sp)
    80003c2a:	e44e                	sd	s3,8(sp)
    80003c2c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c2e:	00005597          	auipc	a1,0x5
    80003c32:	a4a58593          	addi	a1,a1,-1462 # 80008678 <syscalls+0x170>
    80003c36:	0001c517          	auipc	a0,0x1c
    80003c3a:	3b250513          	addi	a0,a0,946 # 8001ffe8 <itable>
    80003c3e:	ffffd097          	auipc	ra,0xffffd
    80003c42:	f16080e7          	jalr	-234(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c46:	0001c497          	auipc	s1,0x1c
    80003c4a:	3ca48493          	addi	s1,s1,970 # 80020010 <itable+0x28>
    80003c4e:	0001e997          	auipc	s3,0x1e
    80003c52:	e5298993          	addi	s3,s3,-430 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c56:	00005917          	auipc	s2,0x5
    80003c5a:	a2a90913          	addi	s2,s2,-1494 # 80008680 <syscalls+0x178>
    80003c5e:	85ca                	mv	a1,s2
    80003c60:	8526                	mv	a0,s1
    80003c62:	00001097          	auipc	ra,0x1
    80003c66:	e46080e7          	jalr	-442(ra) # 80004aa8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c6a:	08848493          	addi	s1,s1,136
    80003c6e:	ff3498e3          	bne	s1,s3,80003c5e <iinit+0x3e>
}
    80003c72:	70a2                	ld	ra,40(sp)
    80003c74:	7402                	ld	s0,32(sp)
    80003c76:	64e2                	ld	s1,24(sp)
    80003c78:	6942                	ld	s2,16(sp)
    80003c7a:	69a2                	ld	s3,8(sp)
    80003c7c:	6145                	addi	sp,sp,48
    80003c7e:	8082                	ret

0000000080003c80 <ialloc>:
{
    80003c80:	715d                	addi	sp,sp,-80
    80003c82:	e486                	sd	ra,72(sp)
    80003c84:	e0a2                	sd	s0,64(sp)
    80003c86:	fc26                	sd	s1,56(sp)
    80003c88:	f84a                	sd	s2,48(sp)
    80003c8a:	f44e                	sd	s3,40(sp)
    80003c8c:	f052                	sd	s4,32(sp)
    80003c8e:	ec56                	sd	s5,24(sp)
    80003c90:	e85a                	sd	s6,16(sp)
    80003c92:	e45e                	sd	s7,8(sp)
    80003c94:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c96:	0001c717          	auipc	a4,0x1c
    80003c9a:	33e72703          	lw	a4,830(a4) # 8001ffd4 <sb+0xc>
    80003c9e:	4785                	li	a5,1
    80003ca0:	04e7fa63          	bgeu	a5,a4,80003cf4 <ialloc+0x74>
    80003ca4:	8aaa                	mv	s5,a0
    80003ca6:	8bae                	mv	s7,a1
    80003ca8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003caa:	0001ca17          	auipc	s4,0x1c
    80003cae:	31ea0a13          	addi	s4,s4,798 # 8001ffc8 <sb>
    80003cb2:	00048b1b          	sext.w	s6,s1
    80003cb6:	0044d593          	srli	a1,s1,0x4
    80003cba:	018a2783          	lw	a5,24(s4)
    80003cbe:	9dbd                	addw	a1,a1,a5
    80003cc0:	8556                	mv	a0,s5
    80003cc2:	00000097          	auipc	ra,0x0
    80003cc6:	954080e7          	jalr	-1708(ra) # 80003616 <bread>
    80003cca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ccc:	05850993          	addi	s3,a0,88
    80003cd0:	00f4f793          	andi	a5,s1,15
    80003cd4:	079a                	slli	a5,a5,0x6
    80003cd6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003cd8:	00099783          	lh	a5,0(s3)
    80003cdc:	c785                	beqz	a5,80003d04 <ialloc+0x84>
    brelse(bp);
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	a68080e7          	jalr	-1432(ra) # 80003746 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ce6:	0485                	addi	s1,s1,1
    80003ce8:	00ca2703          	lw	a4,12(s4)
    80003cec:	0004879b          	sext.w	a5,s1
    80003cf0:	fce7e1e3          	bltu	a5,a4,80003cb2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cf4:	00005517          	auipc	a0,0x5
    80003cf8:	99450513          	addi	a0,a0,-1644 # 80008688 <syscalls+0x180>
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	842080e7          	jalr	-1982(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003d04:	04000613          	li	a2,64
    80003d08:	4581                	li	a1,0
    80003d0a:	854e                	mv	a0,s3
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	fd4080e7          	jalr	-44(ra) # 80000ce0 <memset>
      dip->type = type;
    80003d14:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d18:	854a                	mv	a0,s2
    80003d1a:	00001097          	auipc	ra,0x1
    80003d1e:	ca8080e7          	jalr	-856(ra) # 800049c2 <log_write>
      brelse(bp);
    80003d22:	854a                	mv	a0,s2
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	a22080e7          	jalr	-1502(ra) # 80003746 <brelse>
      return iget(dev, inum);
    80003d2c:	85da                	mv	a1,s6
    80003d2e:	8556                	mv	a0,s5
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	db4080e7          	jalr	-588(ra) # 80003ae4 <iget>
}
    80003d38:	60a6                	ld	ra,72(sp)
    80003d3a:	6406                	ld	s0,64(sp)
    80003d3c:	74e2                	ld	s1,56(sp)
    80003d3e:	7942                	ld	s2,48(sp)
    80003d40:	79a2                	ld	s3,40(sp)
    80003d42:	7a02                	ld	s4,32(sp)
    80003d44:	6ae2                	ld	s5,24(sp)
    80003d46:	6b42                	ld	s6,16(sp)
    80003d48:	6ba2                	ld	s7,8(sp)
    80003d4a:	6161                	addi	sp,sp,80
    80003d4c:	8082                	ret

0000000080003d4e <iupdate>:
{
    80003d4e:	1101                	addi	sp,sp,-32
    80003d50:	ec06                	sd	ra,24(sp)
    80003d52:	e822                	sd	s0,16(sp)
    80003d54:	e426                	sd	s1,8(sp)
    80003d56:	e04a                	sd	s2,0(sp)
    80003d58:	1000                	addi	s0,sp,32
    80003d5a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d5c:	415c                	lw	a5,4(a0)
    80003d5e:	0047d79b          	srliw	a5,a5,0x4
    80003d62:	0001c597          	auipc	a1,0x1c
    80003d66:	27e5a583          	lw	a1,638(a1) # 8001ffe0 <sb+0x18>
    80003d6a:	9dbd                	addw	a1,a1,a5
    80003d6c:	4108                	lw	a0,0(a0)
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	8a8080e7          	jalr	-1880(ra) # 80003616 <bread>
    80003d76:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d78:	05850793          	addi	a5,a0,88
    80003d7c:	40c8                	lw	a0,4(s1)
    80003d7e:	893d                	andi	a0,a0,15
    80003d80:	051a                	slli	a0,a0,0x6
    80003d82:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d84:	04449703          	lh	a4,68(s1)
    80003d88:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d8c:	04649703          	lh	a4,70(s1)
    80003d90:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d94:	04849703          	lh	a4,72(s1)
    80003d98:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d9c:	04a49703          	lh	a4,74(s1)
    80003da0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003da4:	44f8                	lw	a4,76(s1)
    80003da6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003da8:	03400613          	li	a2,52
    80003dac:	05048593          	addi	a1,s1,80
    80003db0:	0531                	addi	a0,a0,12
    80003db2:	ffffd097          	auipc	ra,0xffffd
    80003db6:	f8e080e7          	jalr	-114(ra) # 80000d40 <memmove>
  log_write(bp);
    80003dba:	854a                	mv	a0,s2
    80003dbc:	00001097          	auipc	ra,0x1
    80003dc0:	c06080e7          	jalr	-1018(ra) # 800049c2 <log_write>
  brelse(bp);
    80003dc4:	854a                	mv	a0,s2
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	980080e7          	jalr	-1664(ra) # 80003746 <brelse>
}
    80003dce:	60e2                	ld	ra,24(sp)
    80003dd0:	6442                	ld	s0,16(sp)
    80003dd2:	64a2                	ld	s1,8(sp)
    80003dd4:	6902                	ld	s2,0(sp)
    80003dd6:	6105                	addi	sp,sp,32
    80003dd8:	8082                	ret

0000000080003dda <idup>:
{
    80003dda:	1101                	addi	sp,sp,-32
    80003ddc:	ec06                	sd	ra,24(sp)
    80003dde:	e822                	sd	s0,16(sp)
    80003de0:	e426                	sd	s1,8(sp)
    80003de2:	1000                	addi	s0,sp,32
    80003de4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003de6:	0001c517          	auipc	a0,0x1c
    80003dea:	20250513          	addi	a0,a0,514 # 8001ffe8 <itable>
    80003dee:	ffffd097          	auipc	ra,0xffffd
    80003df2:	df6080e7          	jalr	-522(ra) # 80000be4 <acquire>
  ip->ref++;
    80003df6:	449c                	lw	a5,8(s1)
    80003df8:	2785                	addiw	a5,a5,1
    80003dfa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dfc:	0001c517          	auipc	a0,0x1c
    80003e00:	1ec50513          	addi	a0,a0,492 # 8001ffe8 <itable>
    80003e04:	ffffd097          	auipc	ra,0xffffd
    80003e08:	e94080e7          	jalr	-364(ra) # 80000c98 <release>
}
    80003e0c:	8526                	mv	a0,s1
    80003e0e:	60e2                	ld	ra,24(sp)
    80003e10:	6442                	ld	s0,16(sp)
    80003e12:	64a2                	ld	s1,8(sp)
    80003e14:	6105                	addi	sp,sp,32
    80003e16:	8082                	ret

0000000080003e18 <ilock>:
{
    80003e18:	1101                	addi	sp,sp,-32
    80003e1a:	ec06                	sd	ra,24(sp)
    80003e1c:	e822                	sd	s0,16(sp)
    80003e1e:	e426                	sd	s1,8(sp)
    80003e20:	e04a                	sd	s2,0(sp)
    80003e22:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e24:	c115                	beqz	a0,80003e48 <ilock+0x30>
    80003e26:	84aa                	mv	s1,a0
    80003e28:	451c                	lw	a5,8(a0)
    80003e2a:	00f05f63          	blez	a5,80003e48 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e2e:	0541                	addi	a0,a0,16
    80003e30:	00001097          	auipc	ra,0x1
    80003e34:	cb2080e7          	jalr	-846(ra) # 80004ae2 <acquiresleep>
  if(ip->valid == 0){
    80003e38:	40bc                	lw	a5,64(s1)
    80003e3a:	cf99                	beqz	a5,80003e58 <ilock+0x40>
}
    80003e3c:	60e2                	ld	ra,24(sp)
    80003e3e:	6442                	ld	s0,16(sp)
    80003e40:	64a2                	ld	s1,8(sp)
    80003e42:	6902                	ld	s2,0(sp)
    80003e44:	6105                	addi	sp,sp,32
    80003e46:	8082                	ret
    panic("ilock");
    80003e48:	00005517          	auipc	a0,0x5
    80003e4c:	85850513          	addi	a0,a0,-1960 # 800086a0 <syscalls+0x198>
    80003e50:	ffffc097          	auipc	ra,0xffffc
    80003e54:	6ee080e7          	jalr	1774(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e58:	40dc                	lw	a5,4(s1)
    80003e5a:	0047d79b          	srliw	a5,a5,0x4
    80003e5e:	0001c597          	auipc	a1,0x1c
    80003e62:	1825a583          	lw	a1,386(a1) # 8001ffe0 <sb+0x18>
    80003e66:	9dbd                	addw	a1,a1,a5
    80003e68:	4088                	lw	a0,0(s1)
    80003e6a:	fffff097          	auipc	ra,0xfffff
    80003e6e:	7ac080e7          	jalr	1964(ra) # 80003616 <bread>
    80003e72:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e74:	05850593          	addi	a1,a0,88
    80003e78:	40dc                	lw	a5,4(s1)
    80003e7a:	8bbd                	andi	a5,a5,15
    80003e7c:	079a                	slli	a5,a5,0x6
    80003e7e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e80:	00059783          	lh	a5,0(a1)
    80003e84:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e88:	00259783          	lh	a5,2(a1)
    80003e8c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e90:	00459783          	lh	a5,4(a1)
    80003e94:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e98:	00659783          	lh	a5,6(a1)
    80003e9c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ea0:	459c                	lw	a5,8(a1)
    80003ea2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ea4:	03400613          	li	a2,52
    80003ea8:	05b1                	addi	a1,a1,12
    80003eaa:	05048513          	addi	a0,s1,80
    80003eae:	ffffd097          	auipc	ra,0xffffd
    80003eb2:	e92080e7          	jalr	-366(ra) # 80000d40 <memmove>
    brelse(bp);
    80003eb6:	854a                	mv	a0,s2
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	88e080e7          	jalr	-1906(ra) # 80003746 <brelse>
    ip->valid = 1;
    80003ec0:	4785                	li	a5,1
    80003ec2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ec4:	04449783          	lh	a5,68(s1)
    80003ec8:	fbb5                	bnez	a5,80003e3c <ilock+0x24>
      panic("ilock: no type");
    80003eca:	00004517          	auipc	a0,0x4
    80003ece:	7de50513          	addi	a0,a0,2014 # 800086a8 <syscalls+0x1a0>
    80003ed2:	ffffc097          	auipc	ra,0xffffc
    80003ed6:	66c080e7          	jalr	1644(ra) # 8000053e <panic>

0000000080003eda <iunlock>:
{
    80003eda:	1101                	addi	sp,sp,-32
    80003edc:	ec06                	sd	ra,24(sp)
    80003ede:	e822                	sd	s0,16(sp)
    80003ee0:	e426                	sd	s1,8(sp)
    80003ee2:	e04a                	sd	s2,0(sp)
    80003ee4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ee6:	c905                	beqz	a0,80003f16 <iunlock+0x3c>
    80003ee8:	84aa                	mv	s1,a0
    80003eea:	01050913          	addi	s2,a0,16
    80003eee:	854a                	mv	a0,s2
    80003ef0:	00001097          	auipc	ra,0x1
    80003ef4:	c8c080e7          	jalr	-884(ra) # 80004b7c <holdingsleep>
    80003ef8:	cd19                	beqz	a0,80003f16 <iunlock+0x3c>
    80003efa:	449c                	lw	a5,8(s1)
    80003efc:	00f05d63          	blez	a5,80003f16 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f00:	854a                	mv	a0,s2
    80003f02:	00001097          	auipc	ra,0x1
    80003f06:	c36080e7          	jalr	-970(ra) # 80004b38 <releasesleep>
}
    80003f0a:	60e2                	ld	ra,24(sp)
    80003f0c:	6442                	ld	s0,16(sp)
    80003f0e:	64a2                	ld	s1,8(sp)
    80003f10:	6902                	ld	s2,0(sp)
    80003f12:	6105                	addi	sp,sp,32
    80003f14:	8082                	ret
    panic("iunlock");
    80003f16:	00004517          	auipc	a0,0x4
    80003f1a:	7a250513          	addi	a0,a0,1954 # 800086b8 <syscalls+0x1b0>
    80003f1e:	ffffc097          	auipc	ra,0xffffc
    80003f22:	620080e7          	jalr	1568(ra) # 8000053e <panic>

0000000080003f26 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f26:	7179                	addi	sp,sp,-48
    80003f28:	f406                	sd	ra,40(sp)
    80003f2a:	f022                	sd	s0,32(sp)
    80003f2c:	ec26                	sd	s1,24(sp)
    80003f2e:	e84a                	sd	s2,16(sp)
    80003f30:	e44e                	sd	s3,8(sp)
    80003f32:	e052                	sd	s4,0(sp)
    80003f34:	1800                	addi	s0,sp,48
    80003f36:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f38:	05050493          	addi	s1,a0,80
    80003f3c:	08050913          	addi	s2,a0,128
    80003f40:	a021                	j	80003f48 <itrunc+0x22>
    80003f42:	0491                	addi	s1,s1,4
    80003f44:	01248d63          	beq	s1,s2,80003f5e <itrunc+0x38>
    if(ip->addrs[i]){
    80003f48:	408c                	lw	a1,0(s1)
    80003f4a:	dde5                	beqz	a1,80003f42 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f4c:	0009a503          	lw	a0,0(s3)
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	90c080e7          	jalr	-1780(ra) # 8000385c <bfree>
      ip->addrs[i] = 0;
    80003f58:	0004a023          	sw	zero,0(s1)
    80003f5c:	b7dd                	j	80003f42 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f5e:	0809a583          	lw	a1,128(s3)
    80003f62:	e185                	bnez	a1,80003f82 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f64:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f68:	854e                	mv	a0,s3
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	de4080e7          	jalr	-540(ra) # 80003d4e <iupdate>
}
    80003f72:	70a2                	ld	ra,40(sp)
    80003f74:	7402                	ld	s0,32(sp)
    80003f76:	64e2                	ld	s1,24(sp)
    80003f78:	6942                	ld	s2,16(sp)
    80003f7a:	69a2                	ld	s3,8(sp)
    80003f7c:	6a02                	ld	s4,0(sp)
    80003f7e:	6145                	addi	sp,sp,48
    80003f80:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f82:	0009a503          	lw	a0,0(s3)
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	690080e7          	jalr	1680(ra) # 80003616 <bread>
    80003f8e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f90:	05850493          	addi	s1,a0,88
    80003f94:	45850913          	addi	s2,a0,1112
    80003f98:	a811                	j	80003fac <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f9a:	0009a503          	lw	a0,0(s3)
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	8be080e7          	jalr	-1858(ra) # 8000385c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003fa6:	0491                	addi	s1,s1,4
    80003fa8:	01248563          	beq	s1,s2,80003fb2 <itrunc+0x8c>
      if(a[j])
    80003fac:	408c                	lw	a1,0(s1)
    80003fae:	dde5                	beqz	a1,80003fa6 <itrunc+0x80>
    80003fb0:	b7ed                	j	80003f9a <itrunc+0x74>
    brelse(bp);
    80003fb2:	8552                	mv	a0,s4
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	792080e7          	jalr	1938(ra) # 80003746 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fbc:	0809a583          	lw	a1,128(s3)
    80003fc0:	0009a503          	lw	a0,0(s3)
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	898080e7          	jalr	-1896(ra) # 8000385c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003fcc:	0809a023          	sw	zero,128(s3)
    80003fd0:	bf51                	j	80003f64 <itrunc+0x3e>

0000000080003fd2 <iput>:
{
    80003fd2:	1101                	addi	sp,sp,-32
    80003fd4:	ec06                	sd	ra,24(sp)
    80003fd6:	e822                	sd	s0,16(sp)
    80003fd8:	e426                	sd	s1,8(sp)
    80003fda:	e04a                	sd	s2,0(sp)
    80003fdc:	1000                	addi	s0,sp,32
    80003fde:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fe0:	0001c517          	auipc	a0,0x1c
    80003fe4:	00850513          	addi	a0,a0,8 # 8001ffe8 <itable>
    80003fe8:	ffffd097          	auipc	ra,0xffffd
    80003fec:	bfc080e7          	jalr	-1028(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ff0:	4498                	lw	a4,8(s1)
    80003ff2:	4785                	li	a5,1
    80003ff4:	02f70363          	beq	a4,a5,8000401a <iput+0x48>
  ip->ref--;
    80003ff8:	449c                	lw	a5,8(s1)
    80003ffa:	37fd                	addiw	a5,a5,-1
    80003ffc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ffe:	0001c517          	auipc	a0,0x1c
    80004002:	fea50513          	addi	a0,a0,-22 # 8001ffe8 <itable>
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	c92080e7          	jalr	-878(ra) # 80000c98 <release>
}
    8000400e:	60e2                	ld	ra,24(sp)
    80004010:	6442                	ld	s0,16(sp)
    80004012:	64a2                	ld	s1,8(sp)
    80004014:	6902                	ld	s2,0(sp)
    80004016:	6105                	addi	sp,sp,32
    80004018:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000401a:	40bc                	lw	a5,64(s1)
    8000401c:	dff1                	beqz	a5,80003ff8 <iput+0x26>
    8000401e:	04a49783          	lh	a5,74(s1)
    80004022:	fbf9                	bnez	a5,80003ff8 <iput+0x26>
    acquiresleep(&ip->lock);
    80004024:	01048913          	addi	s2,s1,16
    80004028:	854a                	mv	a0,s2
    8000402a:	00001097          	auipc	ra,0x1
    8000402e:	ab8080e7          	jalr	-1352(ra) # 80004ae2 <acquiresleep>
    release(&itable.lock);
    80004032:	0001c517          	auipc	a0,0x1c
    80004036:	fb650513          	addi	a0,a0,-74 # 8001ffe8 <itable>
    8000403a:	ffffd097          	auipc	ra,0xffffd
    8000403e:	c5e080e7          	jalr	-930(ra) # 80000c98 <release>
    itrunc(ip);
    80004042:	8526                	mv	a0,s1
    80004044:	00000097          	auipc	ra,0x0
    80004048:	ee2080e7          	jalr	-286(ra) # 80003f26 <itrunc>
    ip->type = 0;
    8000404c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004050:	8526                	mv	a0,s1
    80004052:	00000097          	auipc	ra,0x0
    80004056:	cfc080e7          	jalr	-772(ra) # 80003d4e <iupdate>
    ip->valid = 0;
    8000405a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000405e:	854a                	mv	a0,s2
    80004060:	00001097          	auipc	ra,0x1
    80004064:	ad8080e7          	jalr	-1320(ra) # 80004b38 <releasesleep>
    acquire(&itable.lock);
    80004068:	0001c517          	auipc	a0,0x1c
    8000406c:	f8050513          	addi	a0,a0,-128 # 8001ffe8 <itable>
    80004070:	ffffd097          	auipc	ra,0xffffd
    80004074:	b74080e7          	jalr	-1164(ra) # 80000be4 <acquire>
    80004078:	b741                	j	80003ff8 <iput+0x26>

000000008000407a <iunlockput>:
{
    8000407a:	1101                	addi	sp,sp,-32
    8000407c:	ec06                	sd	ra,24(sp)
    8000407e:	e822                	sd	s0,16(sp)
    80004080:	e426                	sd	s1,8(sp)
    80004082:	1000                	addi	s0,sp,32
    80004084:	84aa                	mv	s1,a0
  iunlock(ip);
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	e54080e7          	jalr	-428(ra) # 80003eda <iunlock>
  iput(ip);
    8000408e:	8526                	mv	a0,s1
    80004090:	00000097          	auipc	ra,0x0
    80004094:	f42080e7          	jalr	-190(ra) # 80003fd2 <iput>
}
    80004098:	60e2                	ld	ra,24(sp)
    8000409a:	6442                	ld	s0,16(sp)
    8000409c:	64a2                	ld	s1,8(sp)
    8000409e:	6105                	addi	sp,sp,32
    800040a0:	8082                	ret

00000000800040a2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040a2:	1141                	addi	sp,sp,-16
    800040a4:	e422                	sd	s0,8(sp)
    800040a6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040a8:	411c                	lw	a5,0(a0)
    800040aa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040ac:	415c                	lw	a5,4(a0)
    800040ae:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040b0:	04451783          	lh	a5,68(a0)
    800040b4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040b8:	04a51783          	lh	a5,74(a0)
    800040bc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040c0:	04c56783          	lwu	a5,76(a0)
    800040c4:	e99c                	sd	a5,16(a1)
}
    800040c6:	6422                	ld	s0,8(sp)
    800040c8:	0141                	addi	sp,sp,16
    800040ca:	8082                	ret

00000000800040cc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040cc:	457c                	lw	a5,76(a0)
    800040ce:	0ed7e963          	bltu	a5,a3,800041c0 <readi+0xf4>
{
    800040d2:	7159                	addi	sp,sp,-112
    800040d4:	f486                	sd	ra,104(sp)
    800040d6:	f0a2                	sd	s0,96(sp)
    800040d8:	eca6                	sd	s1,88(sp)
    800040da:	e8ca                	sd	s2,80(sp)
    800040dc:	e4ce                	sd	s3,72(sp)
    800040de:	e0d2                	sd	s4,64(sp)
    800040e0:	fc56                	sd	s5,56(sp)
    800040e2:	f85a                	sd	s6,48(sp)
    800040e4:	f45e                	sd	s7,40(sp)
    800040e6:	f062                	sd	s8,32(sp)
    800040e8:	ec66                	sd	s9,24(sp)
    800040ea:	e86a                	sd	s10,16(sp)
    800040ec:	e46e                	sd	s11,8(sp)
    800040ee:	1880                	addi	s0,sp,112
    800040f0:	8baa                	mv	s7,a0
    800040f2:	8c2e                	mv	s8,a1
    800040f4:	8ab2                	mv	s5,a2
    800040f6:	84b6                	mv	s1,a3
    800040f8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040fa:	9f35                	addw	a4,a4,a3
    return 0;
    800040fc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040fe:	0ad76063          	bltu	a4,a3,8000419e <readi+0xd2>
  if(off + n > ip->size)
    80004102:	00e7f463          	bgeu	a5,a4,8000410a <readi+0x3e>
    n = ip->size - off;
    80004106:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000410a:	0a0b0963          	beqz	s6,800041bc <readi+0xf0>
    8000410e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004110:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004114:	5cfd                	li	s9,-1
    80004116:	a82d                	j	80004150 <readi+0x84>
    80004118:	020a1d93          	slli	s11,s4,0x20
    8000411c:	020ddd93          	srli	s11,s11,0x20
    80004120:	05890613          	addi	a2,s2,88
    80004124:	86ee                	mv	a3,s11
    80004126:	963a                	add	a2,a2,a4
    80004128:	85d6                	mv	a1,s5
    8000412a:	8562                	mv	a0,s8
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	acc080e7          	jalr	-1332(ra) # 80002bf8 <either_copyout>
    80004134:	05950d63          	beq	a0,s9,8000418e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004138:	854a                	mv	a0,s2
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	60c080e7          	jalr	1548(ra) # 80003746 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004142:	013a09bb          	addw	s3,s4,s3
    80004146:	009a04bb          	addw	s1,s4,s1
    8000414a:	9aee                	add	s5,s5,s11
    8000414c:	0569f763          	bgeu	s3,s6,8000419a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004150:	000ba903          	lw	s2,0(s7)
    80004154:	00a4d59b          	srliw	a1,s1,0xa
    80004158:	855e                	mv	a0,s7
    8000415a:	00000097          	auipc	ra,0x0
    8000415e:	8b0080e7          	jalr	-1872(ra) # 80003a0a <bmap>
    80004162:	0005059b          	sext.w	a1,a0
    80004166:	854a                	mv	a0,s2
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	4ae080e7          	jalr	1198(ra) # 80003616 <bread>
    80004170:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004172:	3ff4f713          	andi	a4,s1,1023
    80004176:	40ed07bb          	subw	a5,s10,a4
    8000417a:	413b06bb          	subw	a3,s6,s3
    8000417e:	8a3e                	mv	s4,a5
    80004180:	2781                	sext.w	a5,a5
    80004182:	0006861b          	sext.w	a2,a3
    80004186:	f8f679e3          	bgeu	a2,a5,80004118 <readi+0x4c>
    8000418a:	8a36                	mv	s4,a3
    8000418c:	b771                	j	80004118 <readi+0x4c>
      brelse(bp);
    8000418e:	854a                	mv	a0,s2
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	5b6080e7          	jalr	1462(ra) # 80003746 <brelse>
      tot = -1;
    80004198:	59fd                	li	s3,-1
  }
  return tot;
    8000419a:	0009851b          	sext.w	a0,s3
}
    8000419e:	70a6                	ld	ra,104(sp)
    800041a0:	7406                	ld	s0,96(sp)
    800041a2:	64e6                	ld	s1,88(sp)
    800041a4:	6946                	ld	s2,80(sp)
    800041a6:	69a6                	ld	s3,72(sp)
    800041a8:	6a06                	ld	s4,64(sp)
    800041aa:	7ae2                	ld	s5,56(sp)
    800041ac:	7b42                	ld	s6,48(sp)
    800041ae:	7ba2                	ld	s7,40(sp)
    800041b0:	7c02                	ld	s8,32(sp)
    800041b2:	6ce2                	ld	s9,24(sp)
    800041b4:	6d42                	ld	s10,16(sp)
    800041b6:	6da2                	ld	s11,8(sp)
    800041b8:	6165                	addi	sp,sp,112
    800041ba:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041bc:	89da                	mv	s3,s6
    800041be:	bff1                	j	8000419a <readi+0xce>
    return 0;
    800041c0:	4501                	li	a0,0
}
    800041c2:	8082                	ret

00000000800041c4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041c4:	457c                	lw	a5,76(a0)
    800041c6:	10d7e863          	bltu	a5,a3,800042d6 <writei+0x112>
{
    800041ca:	7159                	addi	sp,sp,-112
    800041cc:	f486                	sd	ra,104(sp)
    800041ce:	f0a2                	sd	s0,96(sp)
    800041d0:	eca6                	sd	s1,88(sp)
    800041d2:	e8ca                	sd	s2,80(sp)
    800041d4:	e4ce                	sd	s3,72(sp)
    800041d6:	e0d2                	sd	s4,64(sp)
    800041d8:	fc56                	sd	s5,56(sp)
    800041da:	f85a                	sd	s6,48(sp)
    800041dc:	f45e                	sd	s7,40(sp)
    800041de:	f062                	sd	s8,32(sp)
    800041e0:	ec66                	sd	s9,24(sp)
    800041e2:	e86a                	sd	s10,16(sp)
    800041e4:	e46e                	sd	s11,8(sp)
    800041e6:	1880                	addi	s0,sp,112
    800041e8:	8b2a                	mv	s6,a0
    800041ea:	8c2e                	mv	s8,a1
    800041ec:	8ab2                	mv	s5,a2
    800041ee:	8936                	mv	s2,a3
    800041f0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041f2:	00e687bb          	addw	a5,a3,a4
    800041f6:	0ed7e263          	bltu	a5,a3,800042da <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041fa:	00043737          	lui	a4,0x43
    800041fe:	0ef76063          	bltu	a4,a5,800042de <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004202:	0c0b8863          	beqz	s7,800042d2 <writei+0x10e>
    80004206:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004208:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000420c:	5cfd                	li	s9,-1
    8000420e:	a091                	j	80004252 <writei+0x8e>
    80004210:	02099d93          	slli	s11,s3,0x20
    80004214:	020ddd93          	srli	s11,s11,0x20
    80004218:	05848513          	addi	a0,s1,88
    8000421c:	86ee                	mv	a3,s11
    8000421e:	8656                	mv	a2,s5
    80004220:	85e2                	mv	a1,s8
    80004222:	953a                	add	a0,a0,a4
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	a2a080e7          	jalr	-1494(ra) # 80002c4e <either_copyin>
    8000422c:	07950263          	beq	a0,s9,80004290 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004230:	8526                	mv	a0,s1
    80004232:	00000097          	auipc	ra,0x0
    80004236:	790080e7          	jalr	1936(ra) # 800049c2 <log_write>
    brelse(bp);
    8000423a:	8526                	mv	a0,s1
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	50a080e7          	jalr	1290(ra) # 80003746 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004244:	01498a3b          	addw	s4,s3,s4
    80004248:	0129893b          	addw	s2,s3,s2
    8000424c:	9aee                	add	s5,s5,s11
    8000424e:	057a7663          	bgeu	s4,s7,8000429a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004252:	000b2483          	lw	s1,0(s6)
    80004256:	00a9559b          	srliw	a1,s2,0xa
    8000425a:	855a                	mv	a0,s6
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	7ae080e7          	jalr	1966(ra) # 80003a0a <bmap>
    80004264:	0005059b          	sext.w	a1,a0
    80004268:	8526                	mv	a0,s1
    8000426a:	fffff097          	auipc	ra,0xfffff
    8000426e:	3ac080e7          	jalr	940(ra) # 80003616 <bread>
    80004272:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004274:	3ff97713          	andi	a4,s2,1023
    80004278:	40ed07bb          	subw	a5,s10,a4
    8000427c:	414b86bb          	subw	a3,s7,s4
    80004280:	89be                	mv	s3,a5
    80004282:	2781                	sext.w	a5,a5
    80004284:	0006861b          	sext.w	a2,a3
    80004288:	f8f674e3          	bgeu	a2,a5,80004210 <writei+0x4c>
    8000428c:	89b6                	mv	s3,a3
    8000428e:	b749                	j	80004210 <writei+0x4c>
      brelse(bp);
    80004290:	8526                	mv	a0,s1
    80004292:	fffff097          	auipc	ra,0xfffff
    80004296:	4b4080e7          	jalr	1204(ra) # 80003746 <brelse>
  }

  if(off > ip->size)
    8000429a:	04cb2783          	lw	a5,76(s6)
    8000429e:	0127f463          	bgeu	a5,s2,800042a6 <writei+0xe2>
    ip->size = off;
    800042a2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042a6:	855a                	mv	a0,s6
    800042a8:	00000097          	auipc	ra,0x0
    800042ac:	aa6080e7          	jalr	-1370(ra) # 80003d4e <iupdate>

  return tot;
    800042b0:	000a051b          	sext.w	a0,s4
}
    800042b4:	70a6                	ld	ra,104(sp)
    800042b6:	7406                	ld	s0,96(sp)
    800042b8:	64e6                	ld	s1,88(sp)
    800042ba:	6946                	ld	s2,80(sp)
    800042bc:	69a6                	ld	s3,72(sp)
    800042be:	6a06                	ld	s4,64(sp)
    800042c0:	7ae2                	ld	s5,56(sp)
    800042c2:	7b42                	ld	s6,48(sp)
    800042c4:	7ba2                	ld	s7,40(sp)
    800042c6:	7c02                	ld	s8,32(sp)
    800042c8:	6ce2                	ld	s9,24(sp)
    800042ca:	6d42                	ld	s10,16(sp)
    800042cc:	6da2                	ld	s11,8(sp)
    800042ce:	6165                	addi	sp,sp,112
    800042d0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042d2:	8a5e                	mv	s4,s7
    800042d4:	bfc9                	j	800042a6 <writei+0xe2>
    return -1;
    800042d6:	557d                	li	a0,-1
}
    800042d8:	8082                	ret
    return -1;
    800042da:	557d                	li	a0,-1
    800042dc:	bfe1                	j	800042b4 <writei+0xf0>
    return -1;
    800042de:	557d                	li	a0,-1
    800042e0:	bfd1                	j	800042b4 <writei+0xf0>

00000000800042e2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042e2:	1141                	addi	sp,sp,-16
    800042e4:	e406                	sd	ra,8(sp)
    800042e6:	e022                	sd	s0,0(sp)
    800042e8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042ea:	4639                	li	a2,14
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	acc080e7          	jalr	-1332(ra) # 80000db8 <strncmp>
}
    800042f4:	60a2                	ld	ra,8(sp)
    800042f6:	6402                	ld	s0,0(sp)
    800042f8:	0141                	addi	sp,sp,16
    800042fa:	8082                	ret

00000000800042fc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042fc:	7139                	addi	sp,sp,-64
    800042fe:	fc06                	sd	ra,56(sp)
    80004300:	f822                	sd	s0,48(sp)
    80004302:	f426                	sd	s1,40(sp)
    80004304:	f04a                	sd	s2,32(sp)
    80004306:	ec4e                	sd	s3,24(sp)
    80004308:	e852                	sd	s4,16(sp)
    8000430a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000430c:	04451703          	lh	a4,68(a0)
    80004310:	4785                	li	a5,1
    80004312:	00f71a63          	bne	a4,a5,80004326 <dirlookup+0x2a>
    80004316:	892a                	mv	s2,a0
    80004318:	89ae                	mv	s3,a1
    8000431a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000431c:	457c                	lw	a5,76(a0)
    8000431e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004320:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004322:	e79d                	bnez	a5,80004350 <dirlookup+0x54>
    80004324:	a8a5                	j	8000439c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004326:	00004517          	auipc	a0,0x4
    8000432a:	39a50513          	addi	a0,a0,922 # 800086c0 <syscalls+0x1b8>
    8000432e:	ffffc097          	auipc	ra,0xffffc
    80004332:	210080e7          	jalr	528(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004336:	00004517          	auipc	a0,0x4
    8000433a:	3a250513          	addi	a0,a0,930 # 800086d8 <syscalls+0x1d0>
    8000433e:	ffffc097          	auipc	ra,0xffffc
    80004342:	200080e7          	jalr	512(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004346:	24c1                	addiw	s1,s1,16
    80004348:	04c92783          	lw	a5,76(s2)
    8000434c:	04f4f763          	bgeu	s1,a5,8000439a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004350:	4741                	li	a4,16
    80004352:	86a6                	mv	a3,s1
    80004354:	fc040613          	addi	a2,s0,-64
    80004358:	4581                	li	a1,0
    8000435a:	854a                	mv	a0,s2
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	d70080e7          	jalr	-656(ra) # 800040cc <readi>
    80004364:	47c1                	li	a5,16
    80004366:	fcf518e3          	bne	a0,a5,80004336 <dirlookup+0x3a>
    if(de.inum == 0)
    8000436a:	fc045783          	lhu	a5,-64(s0)
    8000436e:	dfe1                	beqz	a5,80004346 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004370:	fc240593          	addi	a1,s0,-62
    80004374:	854e                	mv	a0,s3
    80004376:	00000097          	auipc	ra,0x0
    8000437a:	f6c080e7          	jalr	-148(ra) # 800042e2 <namecmp>
    8000437e:	f561                	bnez	a0,80004346 <dirlookup+0x4a>
      if(poff)
    80004380:	000a0463          	beqz	s4,80004388 <dirlookup+0x8c>
        *poff = off;
    80004384:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004388:	fc045583          	lhu	a1,-64(s0)
    8000438c:	00092503          	lw	a0,0(s2)
    80004390:	fffff097          	auipc	ra,0xfffff
    80004394:	754080e7          	jalr	1876(ra) # 80003ae4 <iget>
    80004398:	a011                	j	8000439c <dirlookup+0xa0>
  return 0;
    8000439a:	4501                	li	a0,0
}
    8000439c:	70e2                	ld	ra,56(sp)
    8000439e:	7442                	ld	s0,48(sp)
    800043a0:	74a2                	ld	s1,40(sp)
    800043a2:	7902                	ld	s2,32(sp)
    800043a4:	69e2                	ld	s3,24(sp)
    800043a6:	6a42                	ld	s4,16(sp)
    800043a8:	6121                	addi	sp,sp,64
    800043aa:	8082                	ret

00000000800043ac <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043ac:	711d                	addi	sp,sp,-96
    800043ae:	ec86                	sd	ra,88(sp)
    800043b0:	e8a2                	sd	s0,80(sp)
    800043b2:	e4a6                	sd	s1,72(sp)
    800043b4:	e0ca                	sd	s2,64(sp)
    800043b6:	fc4e                	sd	s3,56(sp)
    800043b8:	f852                	sd	s4,48(sp)
    800043ba:	f456                	sd	s5,40(sp)
    800043bc:	f05a                	sd	s6,32(sp)
    800043be:	ec5e                	sd	s7,24(sp)
    800043c0:	e862                	sd	s8,16(sp)
    800043c2:	e466                	sd	s9,8(sp)
    800043c4:	1080                	addi	s0,sp,96
    800043c6:	84aa                	mv	s1,a0
    800043c8:	8b2e                	mv	s6,a1
    800043ca:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043cc:	00054703          	lbu	a4,0(a0)
    800043d0:	02f00793          	li	a5,47
    800043d4:	02f70363          	beq	a4,a5,800043fa <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043d8:	ffffe097          	auipc	ra,0xffffe
    800043dc:	81e080e7          	jalr	-2018(ra) # 80001bf6 <myproc>
    800043e0:	17053503          	ld	a0,368(a0)
    800043e4:	00000097          	auipc	ra,0x0
    800043e8:	9f6080e7          	jalr	-1546(ra) # 80003dda <idup>
    800043ec:	89aa                	mv	s3,a0
  while(*path == '/')
    800043ee:	02f00913          	li	s2,47
  len = path - s;
    800043f2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043f4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043f6:	4c05                	li	s8,1
    800043f8:	a865                	j	800044b0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043fa:	4585                	li	a1,1
    800043fc:	4505                	li	a0,1
    800043fe:	fffff097          	auipc	ra,0xfffff
    80004402:	6e6080e7          	jalr	1766(ra) # 80003ae4 <iget>
    80004406:	89aa                	mv	s3,a0
    80004408:	b7dd                	j	800043ee <namex+0x42>
      iunlockput(ip);
    8000440a:	854e                	mv	a0,s3
    8000440c:	00000097          	auipc	ra,0x0
    80004410:	c6e080e7          	jalr	-914(ra) # 8000407a <iunlockput>
      return 0;
    80004414:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004416:	854e                	mv	a0,s3
    80004418:	60e6                	ld	ra,88(sp)
    8000441a:	6446                	ld	s0,80(sp)
    8000441c:	64a6                	ld	s1,72(sp)
    8000441e:	6906                	ld	s2,64(sp)
    80004420:	79e2                	ld	s3,56(sp)
    80004422:	7a42                	ld	s4,48(sp)
    80004424:	7aa2                	ld	s5,40(sp)
    80004426:	7b02                	ld	s6,32(sp)
    80004428:	6be2                	ld	s7,24(sp)
    8000442a:	6c42                	ld	s8,16(sp)
    8000442c:	6ca2                	ld	s9,8(sp)
    8000442e:	6125                	addi	sp,sp,96
    80004430:	8082                	ret
      iunlock(ip);
    80004432:	854e                	mv	a0,s3
    80004434:	00000097          	auipc	ra,0x0
    80004438:	aa6080e7          	jalr	-1370(ra) # 80003eda <iunlock>
      return ip;
    8000443c:	bfe9                	j	80004416 <namex+0x6a>
      iunlockput(ip);
    8000443e:	854e                	mv	a0,s3
    80004440:	00000097          	auipc	ra,0x0
    80004444:	c3a080e7          	jalr	-966(ra) # 8000407a <iunlockput>
      return 0;
    80004448:	89d2                	mv	s3,s4
    8000444a:	b7f1                	j	80004416 <namex+0x6a>
  len = path - s;
    8000444c:	40b48633          	sub	a2,s1,a1
    80004450:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004454:	094cd463          	bge	s9,s4,800044dc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004458:	4639                	li	a2,14
    8000445a:	8556                	mv	a0,s5
    8000445c:	ffffd097          	auipc	ra,0xffffd
    80004460:	8e4080e7          	jalr	-1820(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004464:	0004c783          	lbu	a5,0(s1)
    80004468:	01279763          	bne	a5,s2,80004476 <namex+0xca>
    path++;
    8000446c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000446e:	0004c783          	lbu	a5,0(s1)
    80004472:	ff278de3          	beq	a5,s2,8000446c <namex+0xc0>
    ilock(ip);
    80004476:	854e                	mv	a0,s3
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	9a0080e7          	jalr	-1632(ra) # 80003e18 <ilock>
    if(ip->type != T_DIR){
    80004480:	04499783          	lh	a5,68(s3)
    80004484:	f98793e3          	bne	a5,s8,8000440a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004488:	000b0563          	beqz	s6,80004492 <namex+0xe6>
    8000448c:	0004c783          	lbu	a5,0(s1)
    80004490:	d3cd                	beqz	a5,80004432 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004492:	865e                	mv	a2,s7
    80004494:	85d6                	mv	a1,s5
    80004496:	854e                	mv	a0,s3
    80004498:	00000097          	auipc	ra,0x0
    8000449c:	e64080e7          	jalr	-412(ra) # 800042fc <dirlookup>
    800044a0:	8a2a                	mv	s4,a0
    800044a2:	dd51                	beqz	a0,8000443e <namex+0x92>
    iunlockput(ip);
    800044a4:	854e                	mv	a0,s3
    800044a6:	00000097          	auipc	ra,0x0
    800044aa:	bd4080e7          	jalr	-1068(ra) # 8000407a <iunlockput>
    ip = next;
    800044ae:	89d2                	mv	s3,s4
  while(*path == '/')
    800044b0:	0004c783          	lbu	a5,0(s1)
    800044b4:	05279763          	bne	a5,s2,80004502 <namex+0x156>
    path++;
    800044b8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044ba:	0004c783          	lbu	a5,0(s1)
    800044be:	ff278de3          	beq	a5,s2,800044b8 <namex+0x10c>
  if(*path == 0)
    800044c2:	c79d                	beqz	a5,800044f0 <namex+0x144>
    path++;
    800044c4:	85a6                	mv	a1,s1
  len = path - s;
    800044c6:	8a5e                	mv	s4,s7
    800044c8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800044ca:	01278963          	beq	a5,s2,800044dc <namex+0x130>
    800044ce:	dfbd                	beqz	a5,8000444c <namex+0xa0>
    path++;
    800044d0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044d2:	0004c783          	lbu	a5,0(s1)
    800044d6:	ff279ce3          	bne	a5,s2,800044ce <namex+0x122>
    800044da:	bf8d                	j	8000444c <namex+0xa0>
    memmove(name, s, len);
    800044dc:	2601                	sext.w	a2,a2
    800044de:	8556                	mv	a0,s5
    800044e0:	ffffd097          	auipc	ra,0xffffd
    800044e4:	860080e7          	jalr	-1952(ra) # 80000d40 <memmove>
    name[len] = 0;
    800044e8:	9a56                	add	s4,s4,s5
    800044ea:	000a0023          	sb	zero,0(s4)
    800044ee:	bf9d                	j	80004464 <namex+0xb8>
  if(nameiparent){
    800044f0:	f20b03e3          	beqz	s6,80004416 <namex+0x6a>
    iput(ip);
    800044f4:	854e                	mv	a0,s3
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	adc080e7          	jalr	-1316(ra) # 80003fd2 <iput>
    return 0;
    800044fe:	4981                	li	s3,0
    80004500:	bf19                	j	80004416 <namex+0x6a>
  if(*path == 0)
    80004502:	d7fd                	beqz	a5,800044f0 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004504:	0004c783          	lbu	a5,0(s1)
    80004508:	85a6                	mv	a1,s1
    8000450a:	b7d1                	j	800044ce <namex+0x122>

000000008000450c <dirlink>:
{
    8000450c:	7139                	addi	sp,sp,-64
    8000450e:	fc06                	sd	ra,56(sp)
    80004510:	f822                	sd	s0,48(sp)
    80004512:	f426                	sd	s1,40(sp)
    80004514:	f04a                	sd	s2,32(sp)
    80004516:	ec4e                	sd	s3,24(sp)
    80004518:	e852                	sd	s4,16(sp)
    8000451a:	0080                	addi	s0,sp,64
    8000451c:	892a                	mv	s2,a0
    8000451e:	8a2e                	mv	s4,a1
    80004520:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004522:	4601                	li	a2,0
    80004524:	00000097          	auipc	ra,0x0
    80004528:	dd8080e7          	jalr	-552(ra) # 800042fc <dirlookup>
    8000452c:	e93d                	bnez	a0,800045a2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000452e:	04c92483          	lw	s1,76(s2)
    80004532:	c49d                	beqz	s1,80004560 <dirlink+0x54>
    80004534:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004536:	4741                	li	a4,16
    80004538:	86a6                	mv	a3,s1
    8000453a:	fc040613          	addi	a2,s0,-64
    8000453e:	4581                	li	a1,0
    80004540:	854a                	mv	a0,s2
    80004542:	00000097          	auipc	ra,0x0
    80004546:	b8a080e7          	jalr	-1142(ra) # 800040cc <readi>
    8000454a:	47c1                	li	a5,16
    8000454c:	06f51163          	bne	a0,a5,800045ae <dirlink+0xa2>
    if(de.inum == 0)
    80004550:	fc045783          	lhu	a5,-64(s0)
    80004554:	c791                	beqz	a5,80004560 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004556:	24c1                	addiw	s1,s1,16
    80004558:	04c92783          	lw	a5,76(s2)
    8000455c:	fcf4ede3          	bltu	s1,a5,80004536 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004560:	4639                	li	a2,14
    80004562:	85d2                	mv	a1,s4
    80004564:	fc240513          	addi	a0,s0,-62
    80004568:	ffffd097          	auipc	ra,0xffffd
    8000456c:	88c080e7          	jalr	-1908(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004570:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004574:	4741                	li	a4,16
    80004576:	86a6                	mv	a3,s1
    80004578:	fc040613          	addi	a2,s0,-64
    8000457c:	4581                	li	a1,0
    8000457e:	854a                	mv	a0,s2
    80004580:	00000097          	auipc	ra,0x0
    80004584:	c44080e7          	jalr	-956(ra) # 800041c4 <writei>
    80004588:	872a                	mv	a4,a0
    8000458a:	47c1                	li	a5,16
  return 0;
    8000458c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000458e:	02f71863          	bne	a4,a5,800045be <dirlink+0xb2>
}
    80004592:	70e2                	ld	ra,56(sp)
    80004594:	7442                	ld	s0,48(sp)
    80004596:	74a2                	ld	s1,40(sp)
    80004598:	7902                	ld	s2,32(sp)
    8000459a:	69e2                	ld	s3,24(sp)
    8000459c:	6a42                	ld	s4,16(sp)
    8000459e:	6121                	addi	sp,sp,64
    800045a0:	8082                	ret
    iput(ip);
    800045a2:	00000097          	auipc	ra,0x0
    800045a6:	a30080e7          	jalr	-1488(ra) # 80003fd2 <iput>
    return -1;
    800045aa:	557d                	li	a0,-1
    800045ac:	b7dd                	j	80004592 <dirlink+0x86>
      panic("dirlink read");
    800045ae:	00004517          	auipc	a0,0x4
    800045b2:	13a50513          	addi	a0,a0,314 # 800086e8 <syscalls+0x1e0>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	f88080e7          	jalr	-120(ra) # 8000053e <panic>
    panic("dirlink");
    800045be:	00004517          	auipc	a0,0x4
    800045c2:	23a50513          	addi	a0,a0,570 # 800087f8 <syscalls+0x2f0>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	f78080e7          	jalr	-136(ra) # 8000053e <panic>

00000000800045ce <namei>:

struct inode*
namei(char *path)
{
    800045ce:	1101                	addi	sp,sp,-32
    800045d0:	ec06                	sd	ra,24(sp)
    800045d2:	e822                	sd	s0,16(sp)
    800045d4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045d6:	fe040613          	addi	a2,s0,-32
    800045da:	4581                	li	a1,0
    800045dc:	00000097          	auipc	ra,0x0
    800045e0:	dd0080e7          	jalr	-560(ra) # 800043ac <namex>
}
    800045e4:	60e2                	ld	ra,24(sp)
    800045e6:	6442                	ld	s0,16(sp)
    800045e8:	6105                	addi	sp,sp,32
    800045ea:	8082                	ret

00000000800045ec <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045ec:	1141                	addi	sp,sp,-16
    800045ee:	e406                	sd	ra,8(sp)
    800045f0:	e022                	sd	s0,0(sp)
    800045f2:	0800                	addi	s0,sp,16
    800045f4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045f6:	4585                	li	a1,1
    800045f8:	00000097          	auipc	ra,0x0
    800045fc:	db4080e7          	jalr	-588(ra) # 800043ac <namex>
}
    80004600:	60a2                	ld	ra,8(sp)
    80004602:	6402                	ld	s0,0(sp)
    80004604:	0141                	addi	sp,sp,16
    80004606:	8082                	ret

0000000080004608 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004608:	1101                	addi	sp,sp,-32
    8000460a:	ec06                	sd	ra,24(sp)
    8000460c:	e822                	sd	s0,16(sp)
    8000460e:	e426                	sd	s1,8(sp)
    80004610:	e04a                	sd	s2,0(sp)
    80004612:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004614:	0001d917          	auipc	s2,0x1d
    80004618:	47c90913          	addi	s2,s2,1148 # 80021a90 <log>
    8000461c:	01892583          	lw	a1,24(s2)
    80004620:	02892503          	lw	a0,40(s2)
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	ff2080e7          	jalr	-14(ra) # 80003616 <bread>
    8000462c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000462e:	02c92683          	lw	a3,44(s2)
    80004632:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004634:	02d05763          	blez	a3,80004662 <write_head+0x5a>
    80004638:	0001d797          	auipc	a5,0x1d
    8000463c:	48878793          	addi	a5,a5,1160 # 80021ac0 <log+0x30>
    80004640:	05c50713          	addi	a4,a0,92
    80004644:	36fd                	addiw	a3,a3,-1
    80004646:	1682                	slli	a3,a3,0x20
    80004648:	9281                	srli	a3,a3,0x20
    8000464a:	068a                	slli	a3,a3,0x2
    8000464c:	0001d617          	auipc	a2,0x1d
    80004650:	47860613          	addi	a2,a2,1144 # 80021ac4 <log+0x34>
    80004654:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004656:	4390                	lw	a2,0(a5)
    80004658:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000465a:	0791                	addi	a5,a5,4
    8000465c:	0711                	addi	a4,a4,4
    8000465e:	fed79ce3          	bne	a5,a3,80004656 <write_head+0x4e>
  }
  bwrite(buf);
    80004662:	8526                	mv	a0,s1
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	0a4080e7          	jalr	164(ra) # 80003708 <bwrite>
  brelse(buf);
    8000466c:	8526                	mv	a0,s1
    8000466e:	fffff097          	auipc	ra,0xfffff
    80004672:	0d8080e7          	jalr	216(ra) # 80003746 <brelse>
}
    80004676:	60e2                	ld	ra,24(sp)
    80004678:	6442                	ld	s0,16(sp)
    8000467a:	64a2                	ld	s1,8(sp)
    8000467c:	6902                	ld	s2,0(sp)
    8000467e:	6105                	addi	sp,sp,32
    80004680:	8082                	ret

0000000080004682 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004682:	0001d797          	auipc	a5,0x1d
    80004686:	43a7a783          	lw	a5,1082(a5) # 80021abc <log+0x2c>
    8000468a:	0af05d63          	blez	a5,80004744 <install_trans+0xc2>
{
    8000468e:	7139                	addi	sp,sp,-64
    80004690:	fc06                	sd	ra,56(sp)
    80004692:	f822                	sd	s0,48(sp)
    80004694:	f426                	sd	s1,40(sp)
    80004696:	f04a                	sd	s2,32(sp)
    80004698:	ec4e                	sd	s3,24(sp)
    8000469a:	e852                	sd	s4,16(sp)
    8000469c:	e456                	sd	s5,8(sp)
    8000469e:	e05a                	sd	s6,0(sp)
    800046a0:	0080                	addi	s0,sp,64
    800046a2:	8b2a                	mv	s6,a0
    800046a4:	0001da97          	auipc	s5,0x1d
    800046a8:	41ca8a93          	addi	s5,s5,1052 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ac:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046ae:	0001d997          	auipc	s3,0x1d
    800046b2:	3e298993          	addi	s3,s3,994 # 80021a90 <log>
    800046b6:	a035                	j	800046e2 <install_trans+0x60>
      bunpin(dbuf);
    800046b8:	8526                	mv	a0,s1
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	166080e7          	jalr	358(ra) # 80003820 <bunpin>
    brelse(lbuf);
    800046c2:	854a                	mv	a0,s2
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	082080e7          	jalr	130(ra) # 80003746 <brelse>
    brelse(dbuf);
    800046cc:	8526                	mv	a0,s1
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	078080e7          	jalr	120(ra) # 80003746 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046d6:	2a05                	addiw	s4,s4,1
    800046d8:	0a91                	addi	s5,s5,4
    800046da:	02c9a783          	lw	a5,44(s3)
    800046de:	04fa5963          	bge	s4,a5,80004730 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046e2:	0189a583          	lw	a1,24(s3)
    800046e6:	014585bb          	addw	a1,a1,s4
    800046ea:	2585                	addiw	a1,a1,1
    800046ec:	0289a503          	lw	a0,40(s3)
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	f26080e7          	jalr	-218(ra) # 80003616 <bread>
    800046f8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046fa:	000aa583          	lw	a1,0(s5)
    800046fe:	0289a503          	lw	a0,40(s3)
    80004702:	fffff097          	auipc	ra,0xfffff
    80004706:	f14080e7          	jalr	-236(ra) # 80003616 <bread>
    8000470a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000470c:	40000613          	li	a2,1024
    80004710:	05890593          	addi	a1,s2,88
    80004714:	05850513          	addi	a0,a0,88
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	628080e7          	jalr	1576(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004720:	8526                	mv	a0,s1
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	fe6080e7          	jalr	-26(ra) # 80003708 <bwrite>
    if(recovering == 0)
    8000472a:	f80b1ce3          	bnez	s6,800046c2 <install_trans+0x40>
    8000472e:	b769                	j	800046b8 <install_trans+0x36>
}
    80004730:	70e2                	ld	ra,56(sp)
    80004732:	7442                	ld	s0,48(sp)
    80004734:	74a2                	ld	s1,40(sp)
    80004736:	7902                	ld	s2,32(sp)
    80004738:	69e2                	ld	s3,24(sp)
    8000473a:	6a42                	ld	s4,16(sp)
    8000473c:	6aa2                	ld	s5,8(sp)
    8000473e:	6b02                	ld	s6,0(sp)
    80004740:	6121                	addi	sp,sp,64
    80004742:	8082                	ret
    80004744:	8082                	ret

0000000080004746 <initlog>:
{
    80004746:	7179                	addi	sp,sp,-48
    80004748:	f406                	sd	ra,40(sp)
    8000474a:	f022                	sd	s0,32(sp)
    8000474c:	ec26                	sd	s1,24(sp)
    8000474e:	e84a                	sd	s2,16(sp)
    80004750:	e44e                	sd	s3,8(sp)
    80004752:	1800                	addi	s0,sp,48
    80004754:	892a                	mv	s2,a0
    80004756:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004758:	0001d497          	auipc	s1,0x1d
    8000475c:	33848493          	addi	s1,s1,824 # 80021a90 <log>
    80004760:	00004597          	auipc	a1,0x4
    80004764:	f9858593          	addi	a1,a1,-104 # 800086f8 <syscalls+0x1f0>
    80004768:	8526                	mv	a0,s1
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	3ea080e7          	jalr	1002(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004772:	0149a583          	lw	a1,20(s3)
    80004776:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004778:	0109a783          	lw	a5,16(s3)
    8000477c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000477e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004782:	854a                	mv	a0,s2
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	e92080e7          	jalr	-366(ra) # 80003616 <bread>
  log.lh.n = lh->n;
    8000478c:	4d3c                	lw	a5,88(a0)
    8000478e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004790:	02f05563          	blez	a5,800047ba <initlog+0x74>
    80004794:	05c50713          	addi	a4,a0,92
    80004798:	0001d697          	auipc	a3,0x1d
    8000479c:	32868693          	addi	a3,a3,808 # 80021ac0 <log+0x30>
    800047a0:	37fd                	addiw	a5,a5,-1
    800047a2:	1782                	slli	a5,a5,0x20
    800047a4:	9381                	srli	a5,a5,0x20
    800047a6:	078a                	slli	a5,a5,0x2
    800047a8:	06050613          	addi	a2,a0,96
    800047ac:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800047ae:	4310                	lw	a2,0(a4)
    800047b0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800047b2:	0711                	addi	a4,a4,4
    800047b4:	0691                	addi	a3,a3,4
    800047b6:	fef71ce3          	bne	a4,a5,800047ae <initlog+0x68>
  brelse(buf);
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	f8c080e7          	jalr	-116(ra) # 80003746 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047c2:	4505                	li	a0,1
    800047c4:	00000097          	auipc	ra,0x0
    800047c8:	ebe080e7          	jalr	-322(ra) # 80004682 <install_trans>
  log.lh.n = 0;
    800047cc:	0001d797          	auipc	a5,0x1d
    800047d0:	2e07a823          	sw	zero,752(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    800047d4:	00000097          	auipc	ra,0x0
    800047d8:	e34080e7          	jalr	-460(ra) # 80004608 <write_head>
}
    800047dc:	70a2                	ld	ra,40(sp)
    800047de:	7402                	ld	s0,32(sp)
    800047e0:	64e2                	ld	s1,24(sp)
    800047e2:	6942                	ld	s2,16(sp)
    800047e4:	69a2                	ld	s3,8(sp)
    800047e6:	6145                	addi	sp,sp,48
    800047e8:	8082                	ret

00000000800047ea <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047ea:	1101                	addi	sp,sp,-32
    800047ec:	ec06                	sd	ra,24(sp)
    800047ee:	e822                	sd	s0,16(sp)
    800047f0:	e426                	sd	s1,8(sp)
    800047f2:	e04a                	sd	s2,0(sp)
    800047f4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047f6:	0001d517          	auipc	a0,0x1d
    800047fa:	29a50513          	addi	a0,a0,666 # 80021a90 <log>
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	3e6080e7          	jalr	998(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004806:	0001d497          	auipc	s1,0x1d
    8000480a:	28a48493          	addi	s1,s1,650 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000480e:	4979                	li	s2,30
    80004810:	a039                	j	8000481e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004812:	85a6                	mv	a1,s1
    80004814:	8526                	mv	a0,s1
    80004816:	ffffe097          	auipc	ra,0xffffe
    8000481a:	f24080e7          	jalr	-220(ra) # 8000273a <sleep>
    if(log.committing){
    8000481e:	50dc                	lw	a5,36(s1)
    80004820:	fbed                	bnez	a5,80004812 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004822:	509c                	lw	a5,32(s1)
    80004824:	0017871b          	addiw	a4,a5,1
    80004828:	0007069b          	sext.w	a3,a4
    8000482c:	0027179b          	slliw	a5,a4,0x2
    80004830:	9fb9                	addw	a5,a5,a4
    80004832:	0017979b          	slliw	a5,a5,0x1
    80004836:	54d8                	lw	a4,44(s1)
    80004838:	9fb9                	addw	a5,a5,a4
    8000483a:	00f95963          	bge	s2,a5,8000484c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000483e:	85a6                	mv	a1,s1
    80004840:	8526                	mv	a0,s1
    80004842:	ffffe097          	auipc	ra,0xffffe
    80004846:	ef8080e7          	jalr	-264(ra) # 8000273a <sleep>
    8000484a:	bfd1                	j	8000481e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000484c:	0001d517          	auipc	a0,0x1d
    80004850:	24450513          	addi	a0,a0,580 # 80021a90 <log>
    80004854:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	442080e7          	jalr	1090(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000485e:	60e2                	ld	ra,24(sp)
    80004860:	6442                	ld	s0,16(sp)
    80004862:	64a2                	ld	s1,8(sp)
    80004864:	6902                	ld	s2,0(sp)
    80004866:	6105                	addi	sp,sp,32
    80004868:	8082                	ret

000000008000486a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000486a:	7139                	addi	sp,sp,-64
    8000486c:	fc06                	sd	ra,56(sp)
    8000486e:	f822                	sd	s0,48(sp)
    80004870:	f426                	sd	s1,40(sp)
    80004872:	f04a                	sd	s2,32(sp)
    80004874:	ec4e                	sd	s3,24(sp)
    80004876:	e852                	sd	s4,16(sp)
    80004878:	e456                	sd	s5,8(sp)
    8000487a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000487c:	0001d497          	auipc	s1,0x1d
    80004880:	21448493          	addi	s1,s1,532 # 80021a90 <log>
    80004884:	8526                	mv	a0,s1
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	35e080e7          	jalr	862(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000488e:	509c                	lw	a5,32(s1)
    80004890:	37fd                	addiw	a5,a5,-1
    80004892:	0007891b          	sext.w	s2,a5
    80004896:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004898:	50dc                	lw	a5,36(s1)
    8000489a:	efb9                	bnez	a5,800048f8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000489c:	06091663          	bnez	s2,80004908 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800048a0:	0001d497          	auipc	s1,0x1d
    800048a4:	1f048493          	addi	s1,s1,496 # 80021a90 <log>
    800048a8:	4785                	li	a5,1
    800048aa:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048ac:	8526                	mv	a0,s1
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	3ea080e7          	jalr	1002(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048b6:	54dc                	lw	a5,44(s1)
    800048b8:	06f04763          	bgtz	a5,80004926 <end_op+0xbc>
    acquire(&log.lock);
    800048bc:	0001d497          	auipc	s1,0x1d
    800048c0:	1d448493          	addi	s1,s1,468 # 80021a90 <log>
    800048c4:	8526                	mv	a0,s1
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	31e080e7          	jalr	798(ra) # 80000be4 <acquire>
    log.committing = 0;
    800048ce:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048d2:	8526                	mv	a0,s1
    800048d4:	ffffe097          	auipc	ra,0xffffe
    800048d8:	ff2080e7          	jalr	-14(ra) # 800028c6 <wakeup>
    release(&log.lock);
    800048dc:	8526                	mv	a0,s1
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	3ba080e7          	jalr	954(ra) # 80000c98 <release>
}
    800048e6:	70e2                	ld	ra,56(sp)
    800048e8:	7442                	ld	s0,48(sp)
    800048ea:	74a2                	ld	s1,40(sp)
    800048ec:	7902                	ld	s2,32(sp)
    800048ee:	69e2                	ld	s3,24(sp)
    800048f0:	6a42                	ld	s4,16(sp)
    800048f2:	6aa2                	ld	s5,8(sp)
    800048f4:	6121                	addi	sp,sp,64
    800048f6:	8082                	ret
    panic("log.committing");
    800048f8:	00004517          	auipc	a0,0x4
    800048fc:	e0850513          	addi	a0,a0,-504 # 80008700 <syscalls+0x1f8>
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	c3e080e7          	jalr	-962(ra) # 8000053e <panic>
    wakeup(&log);
    80004908:	0001d497          	auipc	s1,0x1d
    8000490c:	18848493          	addi	s1,s1,392 # 80021a90 <log>
    80004910:	8526                	mv	a0,s1
    80004912:	ffffe097          	auipc	ra,0xffffe
    80004916:	fb4080e7          	jalr	-76(ra) # 800028c6 <wakeup>
  release(&log.lock);
    8000491a:	8526                	mv	a0,s1
    8000491c:	ffffc097          	auipc	ra,0xffffc
    80004920:	37c080e7          	jalr	892(ra) # 80000c98 <release>
  if(do_commit){
    80004924:	b7c9                	j	800048e6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004926:	0001da97          	auipc	s5,0x1d
    8000492a:	19aa8a93          	addi	s5,s5,410 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000492e:	0001da17          	auipc	s4,0x1d
    80004932:	162a0a13          	addi	s4,s4,354 # 80021a90 <log>
    80004936:	018a2583          	lw	a1,24(s4)
    8000493a:	012585bb          	addw	a1,a1,s2
    8000493e:	2585                	addiw	a1,a1,1
    80004940:	028a2503          	lw	a0,40(s4)
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	cd2080e7          	jalr	-814(ra) # 80003616 <bread>
    8000494c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000494e:	000aa583          	lw	a1,0(s5)
    80004952:	028a2503          	lw	a0,40(s4)
    80004956:	fffff097          	auipc	ra,0xfffff
    8000495a:	cc0080e7          	jalr	-832(ra) # 80003616 <bread>
    8000495e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004960:	40000613          	li	a2,1024
    80004964:	05850593          	addi	a1,a0,88
    80004968:	05848513          	addi	a0,s1,88
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	3d4080e7          	jalr	980(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004974:	8526                	mv	a0,s1
    80004976:	fffff097          	auipc	ra,0xfffff
    8000497a:	d92080e7          	jalr	-622(ra) # 80003708 <bwrite>
    brelse(from);
    8000497e:	854e                	mv	a0,s3
    80004980:	fffff097          	auipc	ra,0xfffff
    80004984:	dc6080e7          	jalr	-570(ra) # 80003746 <brelse>
    brelse(to);
    80004988:	8526                	mv	a0,s1
    8000498a:	fffff097          	auipc	ra,0xfffff
    8000498e:	dbc080e7          	jalr	-580(ra) # 80003746 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004992:	2905                	addiw	s2,s2,1
    80004994:	0a91                	addi	s5,s5,4
    80004996:	02ca2783          	lw	a5,44(s4)
    8000499a:	f8f94ee3          	blt	s2,a5,80004936 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	c6a080e7          	jalr	-918(ra) # 80004608 <write_head>
    install_trans(0); // Now install writes to home locations
    800049a6:	4501                	li	a0,0
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	cda080e7          	jalr	-806(ra) # 80004682 <install_trans>
    log.lh.n = 0;
    800049b0:	0001d797          	auipc	a5,0x1d
    800049b4:	1007a623          	sw	zero,268(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049b8:	00000097          	auipc	ra,0x0
    800049bc:	c50080e7          	jalr	-944(ra) # 80004608 <write_head>
    800049c0:	bdf5                	j	800048bc <end_op+0x52>

00000000800049c2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049c2:	1101                	addi	sp,sp,-32
    800049c4:	ec06                	sd	ra,24(sp)
    800049c6:	e822                	sd	s0,16(sp)
    800049c8:	e426                	sd	s1,8(sp)
    800049ca:	e04a                	sd	s2,0(sp)
    800049cc:	1000                	addi	s0,sp,32
    800049ce:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049d0:	0001d917          	auipc	s2,0x1d
    800049d4:	0c090913          	addi	s2,s2,192 # 80021a90 <log>
    800049d8:	854a                	mv	a0,s2
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	20a080e7          	jalr	522(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049e2:	02c92603          	lw	a2,44(s2)
    800049e6:	47f5                	li	a5,29
    800049e8:	06c7c563          	blt	a5,a2,80004a52 <log_write+0x90>
    800049ec:	0001d797          	auipc	a5,0x1d
    800049f0:	0c07a783          	lw	a5,192(a5) # 80021aac <log+0x1c>
    800049f4:	37fd                	addiw	a5,a5,-1
    800049f6:	04f65e63          	bge	a2,a5,80004a52 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049fa:	0001d797          	auipc	a5,0x1d
    800049fe:	0b67a783          	lw	a5,182(a5) # 80021ab0 <log+0x20>
    80004a02:	06f05063          	blez	a5,80004a62 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a06:	4781                	li	a5,0
    80004a08:	06c05563          	blez	a2,80004a72 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a0c:	44cc                	lw	a1,12(s1)
    80004a0e:	0001d717          	auipc	a4,0x1d
    80004a12:	0b270713          	addi	a4,a4,178 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a16:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a18:	4314                	lw	a3,0(a4)
    80004a1a:	04b68c63          	beq	a3,a1,80004a72 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a1e:	2785                	addiw	a5,a5,1
    80004a20:	0711                	addi	a4,a4,4
    80004a22:	fef61be3          	bne	a2,a5,80004a18 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a26:	0621                	addi	a2,a2,8
    80004a28:	060a                	slli	a2,a2,0x2
    80004a2a:	0001d797          	auipc	a5,0x1d
    80004a2e:	06678793          	addi	a5,a5,102 # 80021a90 <log>
    80004a32:	963e                	add	a2,a2,a5
    80004a34:	44dc                	lw	a5,12(s1)
    80004a36:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a38:	8526                	mv	a0,s1
    80004a3a:	fffff097          	auipc	ra,0xfffff
    80004a3e:	daa080e7          	jalr	-598(ra) # 800037e4 <bpin>
    log.lh.n++;
    80004a42:	0001d717          	auipc	a4,0x1d
    80004a46:	04e70713          	addi	a4,a4,78 # 80021a90 <log>
    80004a4a:	575c                	lw	a5,44(a4)
    80004a4c:	2785                	addiw	a5,a5,1
    80004a4e:	d75c                	sw	a5,44(a4)
    80004a50:	a835                	j	80004a8c <log_write+0xca>
    panic("too big a transaction");
    80004a52:	00004517          	auipc	a0,0x4
    80004a56:	cbe50513          	addi	a0,a0,-834 # 80008710 <syscalls+0x208>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	ae4080e7          	jalr	-1308(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a62:	00004517          	auipc	a0,0x4
    80004a66:	cc650513          	addi	a0,a0,-826 # 80008728 <syscalls+0x220>
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	ad4080e7          	jalr	-1324(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a72:	00878713          	addi	a4,a5,8
    80004a76:	00271693          	slli	a3,a4,0x2
    80004a7a:	0001d717          	auipc	a4,0x1d
    80004a7e:	01670713          	addi	a4,a4,22 # 80021a90 <log>
    80004a82:	9736                	add	a4,a4,a3
    80004a84:	44d4                	lw	a3,12(s1)
    80004a86:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a88:	faf608e3          	beq	a2,a5,80004a38 <log_write+0x76>
  }
  release(&log.lock);
    80004a8c:	0001d517          	auipc	a0,0x1d
    80004a90:	00450513          	addi	a0,a0,4 # 80021a90 <log>
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	204080e7          	jalr	516(ra) # 80000c98 <release>
}
    80004a9c:	60e2                	ld	ra,24(sp)
    80004a9e:	6442                	ld	s0,16(sp)
    80004aa0:	64a2                	ld	s1,8(sp)
    80004aa2:	6902                	ld	s2,0(sp)
    80004aa4:	6105                	addi	sp,sp,32
    80004aa6:	8082                	ret

0000000080004aa8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004aa8:	1101                	addi	sp,sp,-32
    80004aaa:	ec06                	sd	ra,24(sp)
    80004aac:	e822                	sd	s0,16(sp)
    80004aae:	e426                	sd	s1,8(sp)
    80004ab0:	e04a                	sd	s2,0(sp)
    80004ab2:	1000                	addi	s0,sp,32
    80004ab4:	84aa                	mv	s1,a0
    80004ab6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ab8:	00004597          	auipc	a1,0x4
    80004abc:	c9058593          	addi	a1,a1,-880 # 80008748 <syscalls+0x240>
    80004ac0:	0521                	addi	a0,a0,8
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	092080e7          	jalr	146(ra) # 80000b54 <initlock>
  lk->name = name;
    80004aca:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ace:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ad2:	0204a423          	sw	zero,40(s1)
}
    80004ad6:	60e2                	ld	ra,24(sp)
    80004ad8:	6442                	ld	s0,16(sp)
    80004ada:	64a2                	ld	s1,8(sp)
    80004adc:	6902                	ld	s2,0(sp)
    80004ade:	6105                	addi	sp,sp,32
    80004ae0:	8082                	ret

0000000080004ae2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ae2:	1101                	addi	sp,sp,-32
    80004ae4:	ec06                	sd	ra,24(sp)
    80004ae6:	e822                	sd	s0,16(sp)
    80004ae8:	e426                	sd	s1,8(sp)
    80004aea:	e04a                	sd	s2,0(sp)
    80004aec:	1000                	addi	s0,sp,32
    80004aee:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004af0:	00850913          	addi	s2,a0,8
    80004af4:	854a                	mv	a0,s2
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	0ee080e7          	jalr	238(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004afe:	409c                	lw	a5,0(s1)
    80004b00:	cb89                	beqz	a5,80004b12 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b02:	85ca                	mv	a1,s2
    80004b04:	8526                	mv	a0,s1
    80004b06:	ffffe097          	auipc	ra,0xffffe
    80004b0a:	c34080e7          	jalr	-972(ra) # 8000273a <sleep>
  while (lk->locked) {
    80004b0e:	409c                	lw	a5,0(s1)
    80004b10:	fbed                	bnez	a5,80004b02 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b12:	4785                	li	a5,1
    80004b14:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b16:	ffffd097          	auipc	ra,0xffffd
    80004b1a:	0e0080e7          	jalr	224(ra) # 80001bf6 <myproc>
    80004b1e:	591c                	lw	a5,48(a0)
    80004b20:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b22:	854a                	mv	a0,s2
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	174080e7          	jalr	372(ra) # 80000c98 <release>
}
    80004b2c:	60e2                	ld	ra,24(sp)
    80004b2e:	6442                	ld	s0,16(sp)
    80004b30:	64a2                	ld	s1,8(sp)
    80004b32:	6902                	ld	s2,0(sp)
    80004b34:	6105                	addi	sp,sp,32
    80004b36:	8082                	ret

0000000080004b38 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b38:	1101                	addi	sp,sp,-32
    80004b3a:	ec06                	sd	ra,24(sp)
    80004b3c:	e822                	sd	s0,16(sp)
    80004b3e:	e426                	sd	s1,8(sp)
    80004b40:	e04a                	sd	s2,0(sp)
    80004b42:	1000                	addi	s0,sp,32
    80004b44:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b46:	00850913          	addi	s2,a0,8
    80004b4a:	854a                	mv	a0,s2
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	098080e7          	jalr	152(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b54:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b58:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b5c:	8526                	mv	a0,s1
    80004b5e:	ffffe097          	auipc	ra,0xffffe
    80004b62:	d68080e7          	jalr	-664(ra) # 800028c6 <wakeup>
  release(&lk->lk);
    80004b66:	854a                	mv	a0,s2
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	130080e7          	jalr	304(ra) # 80000c98 <release>
}
    80004b70:	60e2                	ld	ra,24(sp)
    80004b72:	6442                	ld	s0,16(sp)
    80004b74:	64a2                	ld	s1,8(sp)
    80004b76:	6902                	ld	s2,0(sp)
    80004b78:	6105                	addi	sp,sp,32
    80004b7a:	8082                	ret

0000000080004b7c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b7c:	7179                	addi	sp,sp,-48
    80004b7e:	f406                	sd	ra,40(sp)
    80004b80:	f022                	sd	s0,32(sp)
    80004b82:	ec26                	sd	s1,24(sp)
    80004b84:	e84a                	sd	s2,16(sp)
    80004b86:	e44e                	sd	s3,8(sp)
    80004b88:	1800                	addi	s0,sp,48
    80004b8a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b8c:	00850913          	addi	s2,a0,8
    80004b90:	854a                	mv	a0,s2
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	052080e7          	jalr	82(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b9a:	409c                	lw	a5,0(s1)
    80004b9c:	ef99                	bnez	a5,80004bba <holdingsleep+0x3e>
    80004b9e:	4481                	li	s1,0
  release(&lk->lk);
    80004ba0:	854a                	mv	a0,s2
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	0f6080e7          	jalr	246(ra) # 80000c98 <release>
  return r;
}
    80004baa:	8526                	mv	a0,s1
    80004bac:	70a2                	ld	ra,40(sp)
    80004bae:	7402                	ld	s0,32(sp)
    80004bb0:	64e2                	ld	s1,24(sp)
    80004bb2:	6942                	ld	s2,16(sp)
    80004bb4:	69a2                	ld	s3,8(sp)
    80004bb6:	6145                	addi	sp,sp,48
    80004bb8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bba:	0284a983          	lw	s3,40(s1)
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	038080e7          	jalr	56(ra) # 80001bf6 <myproc>
    80004bc6:	5904                	lw	s1,48(a0)
    80004bc8:	413484b3          	sub	s1,s1,s3
    80004bcc:	0014b493          	seqz	s1,s1
    80004bd0:	bfc1                	j	80004ba0 <holdingsleep+0x24>

0000000080004bd2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004bd2:	1141                	addi	sp,sp,-16
    80004bd4:	e406                	sd	ra,8(sp)
    80004bd6:	e022                	sd	s0,0(sp)
    80004bd8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004bda:	00004597          	auipc	a1,0x4
    80004bde:	b7e58593          	addi	a1,a1,-1154 # 80008758 <syscalls+0x250>
    80004be2:	0001d517          	auipc	a0,0x1d
    80004be6:	ff650513          	addi	a0,a0,-10 # 80021bd8 <ftable>
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	f6a080e7          	jalr	-150(ra) # 80000b54 <initlock>
}
    80004bf2:	60a2                	ld	ra,8(sp)
    80004bf4:	6402                	ld	s0,0(sp)
    80004bf6:	0141                	addi	sp,sp,16
    80004bf8:	8082                	ret

0000000080004bfa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bfa:	1101                	addi	sp,sp,-32
    80004bfc:	ec06                	sd	ra,24(sp)
    80004bfe:	e822                	sd	s0,16(sp)
    80004c00:	e426                	sd	s1,8(sp)
    80004c02:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c04:	0001d517          	auipc	a0,0x1d
    80004c08:	fd450513          	addi	a0,a0,-44 # 80021bd8 <ftable>
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	fd8080e7          	jalr	-40(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c14:	0001d497          	auipc	s1,0x1d
    80004c18:	fdc48493          	addi	s1,s1,-36 # 80021bf0 <ftable+0x18>
    80004c1c:	0001e717          	auipc	a4,0x1e
    80004c20:	f7470713          	addi	a4,a4,-140 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004c24:	40dc                	lw	a5,4(s1)
    80004c26:	cf99                	beqz	a5,80004c44 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c28:	02848493          	addi	s1,s1,40
    80004c2c:	fee49ce3          	bne	s1,a4,80004c24 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c30:	0001d517          	auipc	a0,0x1d
    80004c34:	fa850513          	addi	a0,a0,-88 # 80021bd8 <ftable>
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	060080e7          	jalr	96(ra) # 80000c98 <release>
  return 0;
    80004c40:	4481                	li	s1,0
    80004c42:	a819                	j	80004c58 <filealloc+0x5e>
      f->ref = 1;
    80004c44:	4785                	li	a5,1
    80004c46:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c48:	0001d517          	auipc	a0,0x1d
    80004c4c:	f9050513          	addi	a0,a0,-112 # 80021bd8 <ftable>
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	048080e7          	jalr	72(ra) # 80000c98 <release>
}
    80004c58:	8526                	mv	a0,s1
    80004c5a:	60e2                	ld	ra,24(sp)
    80004c5c:	6442                	ld	s0,16(sp)
    80004c5e:	64a2                	ld	s1,8(sp)
    80004c60:	6105                	addi	sp,sp,32
    80004c62:	8082                	ret

0000000080004c64 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c64:	1101                	addi	sp,sp,-32
    80004c66:	ec06                	sd	ra,24(sp)
    80004c68:	e822                	sd	s0,16(sp)
    80004c6a:	e426                	sd	s1,8(sp)
    80004c6c:	1000                	addi	s0,sp,32
    80004c6e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c70:	0001d517          	auipc	a0,0x1d
    80004c74:	f6850513          	addi	a0,a0,-152 # 80021bd8 <ftable>
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	f6c080e7          	jalr	-148(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c80:	40dc                	lw	a5,4(s1)
    80004c82:	02f05263          	blez	a5,80004ca6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c86:	2785                	addiw	a5,a5,1
    80004c88:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c8a:	0001d517          	auipc	a0,0x1d
    80004c8e:	f4e50513          	addi	a0,a0,-178 # 80021bd8 <ftable>
    80004c92:	ffffc097          	auipc	ra,0xffffc
    80004c96:	006080e7          	jalr	6(ra) # 80000c98 <release>
  return f;
}
    80004c9a:	8526                	mv	a0,s1
    80004c9c:	60e2                	ld	ra,24(sp)
    80004c9e:	6442                	ld	s0,16(sp)
    80004ca0:	64a2                	ld	s1,8(sp)
    80004ca2:	6105                	addi	sp,sp,32
    80004ca4:	8082                	ret
    panic("filedup");
    80004ca6:	00004517          	auipc	a0,0x4
    80004caa:	aba50513          	addi	a0,a0,-1350 # 80008760 <syscalls+0x258>
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	890080e7          	jalr	-1904(ra) # 8000053e <panic>

0000000080004cb6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cb6:	7139                	addi	sp,sp,-64
    80004cb8:	fc06                	sd	ra,56(sp)
    80004cba:	f822                	sd	s0,48(sp)
    80004cbc:	f426                	sd	s1,40(sp)
    80004cbe:	f04a                	sd	s2,32(sp)
    80004cc0:	ec4e                	sd	s3,24(sp)
    80004cc2:	e852                	sd	s4,16(sp)
    80004cc4:	e456                	sd	s5,8(sp)
    80004cc6:	0080                	addi	s0,sp,64
    80004cc8:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004cca:	0001d517          	auipc	a0,0x1d
    80004cce:	f0e50513          	addi	a0,a0,-242 # 80021bd8 <ftable>
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	f12080e7          	jalr	-238(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004cda:	40dc                	lw	a5,4(s1)
    80004cdc:	06f05163          	blez	a5,80004d3e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ce0:	37fd                	addiw	a5,a5,-1
    80004ce2:	0007871b          	sext.w	a4,a5
    80004ce6:	c0dc                	sw	a5,4(s1)
    80004ce8:	06e04363          	bgtz	a4,80004d4e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004cec:	0004a903          	lw	s2,0(s1)
    80004cf0:	0094ca83          	lbu	s5,9(s1)
    80004cf4:	0104ba03          	ld	s4,16(s1)
    80004cf8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cfc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d00:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d04:	0001d517          	auipc	a0,0x1d
    80004d08:	ed450513          	addi	a0,a0,-300 # 80021bd8 <ftable>
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	f8c080e7          	jalr	-116(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004d14:	4785                	li	a5,1
    80004d16:	04f90d63          	beq	s2,a5,80004d70 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d1a:	3979                	addiw	s2,s2,-2
    80004d1c:	4785                	li	a5,1
    80004d1e:	0527e063          	bltu	a5,s2,80004d5e <fileclose+0xa8>
    begin_op();
    80004d22:	00000097          	auipc	ra,0x0
    80004d26:	ac8080e7          	jalr	-1336(ra) # 800047ea <begin_op>
    iput(ff.ip);
    80004d2a:	854e                	mv	a0,s3
    80004d2c:	fffff097          	auipc	ra,0xfffff
    80004d30:	2a6080e7          	jalr	678(ra) # 80003fd2 <iput>
    end_op();
    80004d34:	00000097          	auipc	ra,0x0
    80004d38:	b36080e7          	jalr	-1226(ra) # 8000486a <end_op>
    80004d3c:	a00d                	j	80004d5e <fileclose+0xa8>
    panic("fileclose");
    80004d3e:	00004517          	auipc	a0,0x4
    80004d42:	a2a50513          	addi	a0,a0,-1494 # 80008768 <syscalls+0x260>
    80004d46:	ffffb097          	auipc	ra,0xffffb
    80004d4a:	7f8080e7          	jalr	2040(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d4e:	0001d517          	auipc	a0,0x1d
    80004d52:	e8a50513          	addi	a0,a0,-374 # 80021bd8 <ftable>
    80004d56:	ffffc097          	auipc	ra,0xffffc
    80004d5a:	f42080e7          	jalr	-190(ra) # 80000c98 <release>
  }
}
    80004d5e:	70e2                	ld	ra,56(sp)
    80004d60:	7442                	ld	s0,48(sp)
    80004d62:	74a2                	ld	s1,40(sp)
    80004d64:	7902                	ld	s2,32(sp)
    80004d66:	69e2                	ld	s3,24(sp)
    80004d68:	6a42                	ld	s4,16(sp)
    80004d6a:	6aa2                	ld	s5,8(sp)
    80004d6c:	6121                	addi	sp,sp,64
    80004d6e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d70:	85d6                	mv	a1,s5
    80004d72:	8552                	mv	a0,s4
    80004d74:	00000097          	auipc	ra,0x0
    80004d78:	34c080e7          	jalr	844(ra) # 800050c0 <pipeclose>
    80004d7c:	b7cd                	j	80004d5e <fileclose+0xa8>

0000000080004d7e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d7e:	715d                	addi	sp,sp,-80
    80004d80:	e486                	sd	ra,72(sp)
    80004d82:	e0a2                	sd	s0,64(sp)
    80004d84:	fc26                	sd	s1,56(sp)
    80004d86:	f84a                	sd	s2,48(sp)
    80004d88:	f44e                	sd	s3,40(sp)
    80004d8a:	0880                	addi	s0,sp,80
    80004d8c:	84aa                	mv	s1,a0
    80004d8e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d90:	ffffd097          	auipc	ra,0xffffd
    80004d94:	e66080e7          	jalr	-410(ra) # 80001bf6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d98:	409c                	lw	a5,0(s1)
    80004d9a:	37f9                	addiw	a5,a5,-2
    80004d9c:	4705                	li	a4,1
    80004d9e:	04f76763          	bltu	a4,a5,80004dec <filestat+0x6e>
    80004da2:	892a                	mv	s2,a0
    ilock(f->ip);
    80004da4:	6c88                	ld	a0,24(s1)
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	072080e7          	jalr	114(ra) # 80003e18 <ilock>
    stati(f->ip, &st);
    80004dae:	fb840593          	addi	a1,s0,-72
    80004db2:	6c88                	ld	a0,24(s1)
    80004db4:	fffff097          	auipc	ra,0xfffff
    80004db8:	2ee080e7          	jalr	750(ra) # 800040a2 <stati>
    iunlock(f->ip);
    80004dbc:	6c88                	ld	a0,24(s1)
    80004dbe:	fffff097          	auipc	ra,0xfffff
    80004dc2:	11c080e7          	jalr	284(ra) # 80003eda <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004dc6:	46e1                	li	a3,24
    80004dc8:	fb840613          	addi	a2,s0,-72
    80004dcc:	85ce                	mv	a1,s3
    80004dce:	07093503          	ld	a0,112(s2)
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	9c4080e7          	jalr	-1596(ra) # 80001796 <copyout>
    80004dda:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dde:	60a6                	ld	ra,72(sp)
    80004de0:	6406                	ld	s0,64(sp)
    80004de2:	74e2                	ld	s1,56(sp)
    80004de4:	7942                	ld	s2,48(sp)
    80004de6:	79a2                	ld	s3,40(sp)
    80004de8:	6161                	addi	sp,sp,80
    80004dea:	8082                	ret
  return -1;
    80004dec:	557d                	li	a0,-1
    80004dee:	bfc5                	j	80004dde <filestat+0x60>

0000000080004df0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004df0:	7179                	addi	sp,sp,-48
    80004df2:	f406                	sd	ra,40(sp)
    80004df4:	f022                	sd	s0,32(sp)
    80004df6:	ec26                	sd	s1,24(sp)
    80004df8:	e84a                	sd	s2,16(sp)
    80004dfa:	e44e                	sd	s3,8(sp)
    80004dfc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004dfe:	00854783          	lbu	a5,8(a0)
    80004e02:	c3d5                	beqz	a5,80004ea6 <fileread+0xb6>
    80004e04:	84aa                	mv	s1,a0
    80004e06:	89ae                	mv	s3,a1
    80004e08:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e0a:	411c                	lw	a5,0(a0)
    80004e0c:	4705                	li	a4,1
    80004e0e:	04e78963          	beq	a5,a4,80004e60 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e12:	470d                	li	a4,3
    80004e14:	04e78d63          	beq	a5,a4,80004e6e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e18:	4709                	li	a4,2
    80004e1a:	06e79e63          	bne	a5,a4,80004e96 <fileread+0xa6>
    ilock(f->ip);
    80004e1e:	6d08                	ld	a0,24(a0)
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	ff8080e7          	jalr	-8(ra) # 80003e18 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e28:	874a                	mv	a4,s2
    80004e2a:	5094                	lw	a3,32(s1)
    80004e2c:	864e                	mv	a2,s3
    80004e2e:	4585                	li	a1,1
    80004e30:	6c88                	ld	a0,24(s1)
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	29a080e7          	jalr	666(ra) # 800040cc <readi>
    80004e3a:	892a                	mv	s2,a0
    80004e3c:	00a05563          	blez	a0,80004e46 <fileread+0x56>
      f->off += r;
    80004e40:	509c                	lw	a5,32(s1)
    80004e42:	9fa9                	addw	a5,a5,a0
    80004e44:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e46:	6c88                	ld	a0,24(s1)
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	092080e7          	jalr	146(ra) # 80003eda <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e50:	854a                	mv	a0,s2
    80004e52:	70a2                	ld	ra,40(sp)
    80004e54:	7402                	ld	s0,32(sp)
    80004e56:	64e2                	ld	s1,24(sp)
    80004e58:	6942                	ld	s2,16(sp)
    80004e5a:	69a2                	ld	s3,8(sp)
    80004e5c:	6145                	addi	sp,sp,48
    80004e5e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e60:	6908                	ld	a0,16(a0)
    80004e62:	00000097          	auipc	ra,0x0
    80004e66:	3c8080e7          	jalr	968(ra) # 8000522a <piperead>
    80004e6a:	892a                	mv	s2,a0
    80004e6c:	b7d5                	j	80004e50 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e6e:	02451783          	lh	a5,36(a0)
    80004e72:	03079693          	slli	a3,a5,0x30
    80004e76:	92c1                	srli	a3,a3,0x30
    80004e78:	4725                	li	a4,9
    80004e7a:	02d76863          	bltu	a4,a3,80004eaa <fileread+0xba>
    80004e7e:	0792                	slli	a5,a5,0x4
    80004e80:	0001d717          	auipc	a4,0x1d
    80004e84:	cb870713          	addi	a4,a4,-840 # 80021b38 <devsw>
    80004e88:	97ba                	add	a5,a5,a4
    80004e8a:	639c                	ld	a5,0(a5)
    80004e8c:	c38d                	beqz	a5,80004eae <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e8e:	4505                	li	a0,1
    80004e90:	9782                	jalr	a5
    80004e92:	892a                	mv	s2,a0
    80004e94:	bf75                	j	80004e50 <fileread+0x60>
    panic("fileread");
    80004e96:	00004517          	auipc	a0,0x4
    80004e9a:	8e250513          	addi	a0,a0,-1822 # 80008778 <syscalls+0x270>
    80004e9e:	ffffb097          	auipc	ra,0xffffb
    80004ea2:	6a0080e7          	jalr	1696(ra) # 8000053e <panic>
    return -1;
    80004ea6:	597d                	li	s2,-1
    80004ea8:	b765                	j	80004e50 <fileread+0x60>
      return -1;
    80004eaa:	597d                	li	s2,-1
    80004eac:	b755                	j	80004e50 <fileread+0x60>
    80004eae:	597d                	li	s2,-1
    80004eb0:	b745                	j	80004e50 <fileread+0x60>

0000000080004eb2 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004eb2:	715d                	addi	sp,sp,-80
    80004eb4:	e486                	sd	ra,72(sp)
    80004eb6:	e0a2                	sd	s0,64(sp)
    80004eb8:	fc26                	sd	s1,56(sp)
    80004eba:	f84a                	sd	s2,48(sp)
    80004ebc:	f44e                	sd	s3,40(sp)
    80004ebe:	f052                	sd	s4,32(sp)
    80004ec0:	ec56                	sd	s5,24(sp)
    80004ec2:	e85a                	sd	s6,16(sp)
    80004ec4:	e45e                	sd	s7,8(sp)
    80004ec6:	e062                	sd	s8,0(sp)
    80004ec8:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004eca:	00954783          	lbu	a5,9(a0)
    80004ece:	10078663          	beqz	a5,80004fda <filewrite+0x128>
    80004ed2:	892a                	mv	s2,a0
    80004ed4:	8aae                	mv	s5,a1
    80004ed6:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ed8:	411c                	lw	a5,0(a0)
    80004eda:	4705                	li	a4,1
    80004edc:	02e78263          	beq	a5,a4,80004f00 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ee0:	470d                	li	a4,3
    80004ee2:	02e78663          	beq	a5,a4,80004f0e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ee6:	4709                	li	a4,2
    80004ee8:	0ee79163          	bne	a5,a4,80004fca <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004eec:	0ac05d63          	blez	a2,80004fa6 <filewrite+0xf4>
    int i = 0;
    80004ef0:	4981                	li	s3,0
    80004ef2:	6b05                	lui	s6,0x1
    80004ef4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ef8:	6b85                	lui	s7,0x1
    80004efa:	c00b8b9b          	addiw	s7,s7,-1024
    80004efe:	a861                	j	80004f96 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f00:	6908                	ld	a0,16(a0)
    80004f02:	00000097          	auipc	ra,0x0
    80004f06:	22e080e7          	jalr	558(ra) # 80005130 <pipewrite>
    80004f0a:	8a2a                	mv	s4,a0
    80004f0c:	a045                	j	80004fac <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f0e:	02451783          	lh	a5,36(a0)
    80004f12:	03079693          	slli	a3,a5,0x30
    80004f16:	92c1                	srli	a3,a3,0x30
    80004f18:	4725                	li	a4,9
    80004f1a:	0cd76263          	bltu	a4,a3,80004fde <filewrite+0x12c>
    80004f1e:	0792                	slli	a5,a5,0x4
    80004f20:	0001d717          	auipc	a4,0x1d
    80004f24:	c1870713          	addi	a4,a4,-1000 # 80021b38 <devsw>
    80004f28:	97ba                	add	a5,a5,a4
    80004f2a:	679c                	ld	a5,8(a5)
    80004f2c:	cbdd                	beqz	a5,80004fe2 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f2e:	4505                	li	a0,1
    80004f30:	9782                	jalr	a5
    80004f32:	8a2a                	mv	s4,a0
    80004f34:	a8a5                	j	80004fac <filewrite+0xfa>
    80004f36:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f3a:	00000097          	auipc	ra,0x0
    80004f3e:	8b0080e7          	jalr	-1872(ra) # 800047ea <begin_op>
      ilock(f->ip);
    80004f42:	01893503          	ld	a0,24(s2)
    80004f46:	fffff097          	auipc	ra,0xfffff
    80004f4a:	ed2080e7          	jalr	-302(ra) # 80003e18 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f4e:	8762                	mv	a4,s8
    80004f50:	02092683          	lw	a3,32(s2)
    80004f54:	01598633          	add	a2,s3,s5
    80004f58:	4585                	li	a1,1
    80004f5a:	01893503          	ld	a0,24(s2)
    80004f5e:	fffff097          	auipc	ra,0xfffff
    80004f62:	266080e7          	jalr	614(ra) # 800041c4 <writei>
    80004f66:	84aa                	mv	s1,a0
    80004f68:	00a05763          	blez	a0,80004f76 <filewrite+0xc4>
        f->off += r;
    80004f6c:	02092783          	lw	a5,32(s2)
    80004f70:	9fa9                	addw	a5,a5,a0
    80004f72:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f76:	01893503          	ld	a0,24(s2)
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	f60080e7          	jalr	-160(ra) # 80003eda <iunlock>
      end_op();
    80004f82:	00000097          	auipc	ra,0x0
    80004f86:	8e8080e7          	jalr	-1816(ra) # 8000486a <end_op>

      if(r != n1){
    80004f8a:	009c1f63          	bne	s8,s1,80004fa8 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f8e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f92:	0149db63          	bge	s3,s4,80004fa8 <filewrite+0xf6>
      int n1 = n - i;
    80004f96:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f9a:	84be                	mv	s1,a5
    80004f9c:	2781                	sext.w	a5,a5
    80004f9e:	f8fb5ce3          	bge	s6,a5,80004f36 <filewrite+0x84>
    80004fa2:	84de                	mv	s1,s7
    80004fa4:	bf49                	j	80004f36 <filewrite+0x84>
    int i = 0;
    80004fa6:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fa8:	013a1f63          	bne	s4,s3,80004fc6 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fac:	8552                	mv	a0,s4
    80004fae:	60a6                	ld	ra,72(sp)
    80004fb0:	6406                	ld	s0,64(sp)
    80004fb2:	74e2                	ld	s1,56(sp)
    80004fb4:	7942                	ld	s2,48(sp)
    80004fb6:	79a2                	ld	s3,40(sp)
    80004fb8:	7a02                	ld	s4,32(sp)
    80004fba:	6ae2                	ld	s5,24(sp)
    80004fbc:	6b42                	ld	s6,16(sp)
    80004fbe:	6ba2                	ld	s7,8(sp)
    80004fc0:	6c02                	ld	s8,0(sp)
    80004fc2:	6161                	addi	sp,sp,80
    80004fc4:	8082                	ret
    ret = (i == n ? n : -1);
    80004fc6:	5a7d                	li	s4,-1
    80004fc8:	b7d5                	j	80004fac <filewrite+0xfa>
    panic("filewrite");
    80004fca:	00003517          	auipc	a0,0x3
    80004fce:	7be50513          	addi	a0,a0,1982 # 80008788 <syscalls+0x280>
    80004fd2:	ffffb097          	auipc	ra,0xffffb
    80004fd6:	56c080e7          	jalr	1388(ra) # 8000053e <panic>
    return -1;
    80004fda:	5a7d                	li	s4,-1
    80004fdc:	bfc1                	j	80004fac <filewrite+0xfa>
      return -1;
    80004fde:	5a7d                	li	s4,-1
    80004fe0:	b7f1                	j	80004fac <filewrite+0xfa>
    80004fe2:	5a7d                	li	s4,-1
    80004fe4:	b7e1                	j	80004fac <filewrite+0xfa>

0000000080004fe6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fe6:	7179                	addi	sp,sp,-48
    80004fe8:	f406                	sd	ra,40(sp)
    80004fea:	f022                	sd	s0,32(sp)
    80004fec:	ec26                	sd	s1,24(sp)
    80004fee:	e84a                	sd	s2,16(sp)
    80004ff0:	e44e                	sd	s3,8(sp)
    80004ff2:	e052                	sd	s4,0(sp)
    80004ff4:	1800                	addi	s0,sp,48
    80004ff6:	84aa                	mv	s1,a0
    80004ff8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ffa:	0005b023          	sd	zero,0(a1)
    80004ffe:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005002:	00000097          	auipc	ra,0x0
    80005006:	bf8080e7          	jalr	-1032(ra) # 80004bfa <filealloc>
    8000500a:	e088                	sd	a0,0(s1)
    8000500c:	c551                	beqz	a0,80005098 <pipealloc+0xb2>
    8000500e:	00000097          	auipc	ra,0x0
    80005012:	bec080e7          	jalr	-1044(ra) # 80004bfa <filealloc>
    80005016:	00aa3023          	sd	a0,0(s4)
    8000501a:	c92d                	beqz	a0,8000508c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	ad8080e7          	jalr	-1320(ra) # 80000af4 <kalloc>
    80005024:	892a                	mv	s2,a0
    80005026:	c125                	beqz	a0,80005086 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005028:	4985                	li	s3,1
    8000502a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000502e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005032:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005036:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000503a:	00003597          	auipc	a1,0x3
    8000503e:	75e58593          	addi	a1,a1,1886 # 80008798 <syscalls+0x290>
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	b12080e7          	jalr	-1262(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    8000504a:	609c                	ld	a5,0(s1)
    8000504c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005050:	609c                	ld	a5,0(s1)
    80005052:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005056:	609c                	ld	a5,0(s1)
    80005058:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000505c:	609c                	ld	a5,0(s1)
    8000505e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005062:	000a3783          	ld	a5,0(s4)
    80005066:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000506a:	000a3783          	ld	a5,0(s4)
    8000506e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005072:	000a3783          	ld	a5,0(s4)
    80005076:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000507a:	000a3783          	ld	a5,0(s4)
    8000507e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005082:	4501                	li	a0,0
    80005084:	a025                	j	800050ac <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005086:	6088                	ld	a0,0(s1)
    80005088:	e501                	bnez	a0,80005090 <pipealloc+0xaa>
    8000508a:	a039                	j	80005098 <pipealloc+0xb2>
    8000508c:	6088                	ld	a0,0(s1)
    8000508e:	c51d                	beqz	a0,800050bc <pipealloc+0xd6>
    fileclose(*f0);
    80005090:	00000097          	auipc	ra,0x0
    80005094:	c26080e7          	jalr	-986(ra) # 80004cb6 <fileclose>
  if(*f1)
    80005098:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000509c:	557d                	li	a0,-1
  if(*f1)
    8000509e:	c799                	beqz	a5,800050ac <pipealloc+0xc6>
    fileclose(*f1);
    800050a0:	853e                	mv	a0,a5
    800050a2:	00000097          	auipc	ra,0x0
    800050a6:	c14080e7          	jalr	-1004(ra) # 80004cb6 <fileclose>
  return -1;
    800050aa:	557d                	li	a0,-1
}
    800050ac:	70a2                	ld	ra,40(sp)
    800050ae:	7402                	ld	s0,32(sp)
    800050b0:	64e2                	ld	s1,24(sp)
    800050b2:	6942                	ld	s2,16(sp)
    800050b4:	69a2                	ld	s3,8(sp)
    800050b6:	6a02                	ld	s4,0(sp)
    800050b8:	6145                	addi	sp,sp,48
    800050ba:	8082                	ret
  return -1;
    800050bc:	557d                	li	a0,-1
    800050be:	b7fd                	j	800050ac <pipealloc+0xc6>

00000000800050c0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050c0:	1101                	addi	sp,sp,-32
    800050c2:	ec06                	sd	ra,24(sp)
    800050c4:	e822                	sd	s0,16(sp)
    800050c6:	e426                	sd	s1,8(sp)
    800050c8:	e04a                	sd	s2,0(sp)
    800050ca:	1000                	addi	s0,sp,32
    800050cc:	84aa                	mv	s1,a0
    800050ce:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	b14080e7          	jalr	-1260(ra) # 80000be4 <acquire>
  if(writable){
    800050d8:	02090d63          	beqz	s2,80005112 <pipeclose+0x52>
    pi->writeopen = 0;
    800050dc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050e0:	21848513          	addi	a0,s1,536
    800050e4:	ffffd097          	auipc	ra,0xffffd
    800050e8:	7e2080e7          	jalr	2018(ra) # 800028c6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050ec:	2204b783          	ld	a5,544(s1)
    800050f0:	eb95                	bnez	a5,80005124 <pipeclose+0x64>
    release(&pi->lock);
    800050f2:	8526                	mv	a0,s1
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	ba4080e7          	jalr	-1116(ra) # 80000c98 <release>
    kfree((char*)pi);
    800050fc:	8526                	mv	a0,s1
    800050fe:	ffffc097          	auipc	ra,0xffffc
    80005102:	8fa080e7          	jalr	-1798(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80005106:	60e2                	ld	ra,24(sp)
    80005108:	6442                	ld	s0,16(sp)
    8000510a:	64a2                	ld	s1,8(sp)
    8000510c:	6902                	ld	s2,0(sp)
    8000510e:	6105                	addi	sp,sp,32
    80005110:	8082                	ret
    pi->readopen = 0;
    80005112:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005116:	21c48513          	addi	a0,s1,540
    8000511a:	ffffd097          	auipc	ra,0xffffd
    8000511e:	7ac080e7          	jalr	1964(ra) # 800028c6 <wakeup>
    80005122:	b7e9                	j	800050ec <pipeclose+0x2c>
    release(&pi->lock);
    80005124:	8526                	mv	a0,s1
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	b72080e7          	jalr	-1166(ra) # 80000c98 <release>
}
    8000512e:	bfe1                	j	80005106 <pipeclose+0x46>

0000000080005130 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005130:	7159                	addi	sp,sp,-112
    80005132:	f486                	sd	ra,104(sp)
    80005134:	f0a2                	sd	s0,96(sp)
    80005136:	eca6                	sd	s1,88(sp)
    80005138:	e8ca                	sd	s2,80(sp)
    8000513a:	e4ce                	sd	s3,72(sp)
    8000513c:	e0d2                	sd	s4,64(sp)
    8000513e:	fc56                	sd	s5,56(sp)
    80005140:	f85a                	sd	s6,48(sp)
    80005142:	f45e                	sd	s7,40(sp)
    80005144:	f062                	sd	s8,32(sp)
    80005146:	ec66                	sd	s9,24(sp)
    80005148:	1880                	addi	s0,sp,112
    8000514a:	84aa                	mv	s1,a0
    8000514c:	8aae                	mv	s5,a1
    8000514e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005150:	ffffd097          	auipc	ra,0xffffd
    80005154:	aa6080e7          	jalr	-1370(ra) # 80001bf6 <myproc>
    80005158:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000515a:	8526                	mv	a0,s1
    8000515c:	ffffc097          	auipc	ra,0xffffc
    80005160:	a88080e7          	jalr	-1400(ra) # 80000be4 <acquire>
  while(i < n){
    80005164:	0d405163          	blez	s4,80005226 <pipewrite+0xf6>
    80005168:	8ba6                	mv	s7,s1
  int i = 0;
    8000516a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000516c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000516e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005172:	21c48c13          	addi	s8,s1,540
    80005176:	a08d                	j	800051d8 <pipewrite+0xa8>
      release(&pi->lock);
    80005178:	8526                	mv	a0,s1
    8000517a:	ffffc097          	auipc	ra,0xffffc
    8000517e:	b1e080e7          	jalr	-1250(ra) # 80000c98 <release>
      return -1;
    80005182:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005184:	854a                	mv	a0,s2
    80005186:	70a6                	ld	ra,104(sp)
    80005188:	7406                	ld	s0,96(sp)
    8000518a:	64e6                	ld	s1,88(sp)
    8000518c:	6946                	ld	s2,80(sp)
    8000518e:	69a6                	ld	s3,72(sp)
    80005190:	6a06                	ld	s4,64(sp)
    80005192:	7ae2                	ld	s5,56(sp)
    80005194:	7b42                	ld	s6,48(sp)
    80005196:	7ba2                	ld	s7,40(sp)
    80005198:	7c02                	ld	s8,32(sp)
    8000519a:	6ce2                	ld	s9,24(sp)
    8000519c:	6165                	addi	sp,sp,112
    8000519e:	8082                	ret
      wakeup(&pi->nread);
    800051a0:	8566                	mv	a0,s9
    800051a2:	ffffd097          	auipc	ra,0xffffd
    800051a6:	724080e7          	jalr	1828(ra) # 800028c6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051aa:	85de                	mv	a1,s7
    800051ac:	8562                	mv	a0,s8
    800051ae:	ffffd097          	auipc	ra,0xffffd
    800051b2:	58c080e7          	jalr	1420(ra) # 8000273a <sleep>
    800051b6:	a839                	j	800051d4 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051b8:	21c4a783          	lw	a5,540(s1)
    800051bc:	0017871b          	addiw	a4,a5,1
    800051c0:	20e4ae23          	sw	a4,540(s1)
    800051c4:	1ff7f793          	andi	a5,a5,511
    800051c8:	97a6                	add	a5,a5,s1
    800051ca:	f9f44703          	lbu	a4,-97(s0)
    800051ce:	00e78c23          	sb	a4,24(a5)
      i++;
    800051d2:	2905                	addiw	s2,s2,1
  while(i < n){
    800051d4:	03495d63          	bge	s2,s4,8000520e <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800051d8:	2204a783          	lw	a5,544(s1)
    800051dc:	dfd1                	beqz	a5,80005178 <pipewrite+0x48>
    800051de:	0289a783          	lw	a5,40(s3)
    800051e2:	fbd9                	bnez	a5,80005178 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051e4:	2184a783          	lw	a5,536(s1)
    800051e8:	21c4a703          	lw	a4,540(s1)
    800051ec:	2007879b          	addiw	a5,a5,512
    800051f0:	faf708e3          	beq	a4,a5,800051a0 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051f4:	4685                	li	a3,1
    800051f6:	01590633          	add	a2,s2,s5
    800051fa:	f9f40593          	addi	a1,s0,-97
    800051fe:	0709b503          	ld	a0,112(s3)
    80005202:	ffffc097          	auipc	ra,0xffffc
    80005206:	620080e7          	jalr	1568(ra) # 80001822 <copyin>
    8000520a:	fb6517e3          	bne	a0,s6,800051b8 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000520e:	21848513          	addi	a0,s1,536
    80005212:	ffffd097          	auipc	ra,0xffffd
    80005216:	6b4080e7          	jalr	1716(ra) # 800028c6 <wakeup>
  release(&pi->lock);
    8000521a:	8526                	mv	a0,s1
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	a7c080e7          	jalr	-1412(ra) # 80000c98 <release>
  return i;
    80005224:	b785                	j	80005184 <pipewrite+0x54>
  int i = 0;
    80005226:	4901                	li	s2,0
    80005228:	b7dd                	j	8000520e <pipewrite+0xde>

000000008000522a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000522a:	715d                	addi	sp,sp,-80
    8000522c:	e486                	sd	ra,72(sp)
    8000522e:	e0a2                	sd	s0,64(sp)
    80005230:	fc26                	sd	s1,56(sp)
    80005232:	f84a                	sd	s2,48(sp)
    80005234:	f44e                	sd	s3,40(sp)
    80005236:	f052                	sd	s4,32(sp)
    80005238:	ec56                	sd	s5,24(sp)
    8000523a:	e85a                	sd	s6,16(sp)
    8000523c:	0880                	addi	s0,sp,80
    8000523e:	84aa                	mv	s1,a0
    80005240:	892e                	mv	s2,a1
    80005242:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005244:	ffffd097          	auipc	ra,0xffffd
    80005248:	9b2080e7          	jalr	-1614(ra) # 80001bf6 <myproc>
    8000524c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000524e:	8b26                	mv	s6,s1
    80005250:	8526                	mv	a0,s1
    80005252:	ffffc097          	auipc	ra,0xffffc
    80005256:	992080e7          	jalr	-1646(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000525a:	2184a703          	lw	a4,536(s1)
    8000525e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005262:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005266:	02f71463          	bne	a4,a5,8000528e <piperead+0x64>
    8000526a:	2244a783          	lw	a5,548(s1)
    8000526e:	c385                	beqz	a5,8000528e <piperead+0x64>
    if(pr->killed){
    80005270:	028a2783          	lw	a5,40(s4)
    80005274:	ebc1                	bnez	a5,80005304 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005276:	85da                	mv	a1,s6
    80005278:	854e                	mv	a0,s3
    8000527a:	ffffd097          	auipc	ra,0xffffd
    8000527e:	4c0080e7          	jalr	1216(ra) # 8000273a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005282:	2184a703          	lw	a4,536(s1)
    80005286:	21c4a783          	lw	a5,540(s1)
    8000528a:	fef700e3          	beq	a4,a5,8000526a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000528e:	09505263          	blez	s5,80005312 <piperead+0xe8>
    80005292:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005294:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005296:	2184a783          	lw	a5,536(s1)
    8000529a:	21c4a703          	lw	a4,540(s1)
    8000529e:	02f70d63          	beq	a4,a5,800052d8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052a2:	0017871b          	addiw	a4,a5,1
    800052a6:	20e4ac23          	sw	a4,536(s1)
    800052aa:	1ff7f793          	andi	a5,a5,511
    800052ae:	97a6                	add	a5,a5,s1
    800052b0:	0187c783          	lbu	a5,24(a5)
    800052b4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052b8:	4685                	li	a3,1
    800052ba:	fbf40613          	addi	a2,s0,-65
    800052be:	85ca                	mv	a1,s2
    800052c0:	070a3503          	ld	a0,112(s4)
    800052c4:	ffffc097          	auipc	ra,0xffffc
    800052c8:	4d2080e7          	jalr	1234(ra) # 80001796 <copyout>
    800052cc:	01650663          	beq	a0,s6,800052d8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052d0:	2985                	addiw	s3,s3,1
    800052d2:	0905                	addi	s2,s2,1
    800052d4:	fd3a91e3          	bne	s5,s3,80005296 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052d8:	21c48513          	addi	a0,s1,540
    800052dc:	ffffd097          	auipc	ra,0xffffd
    800052e0:	5ea080e7          	jalr	1514(ra) # 800028c6 <wakeup>
  release(&pi->lock);
    800052e4:	8526                	mv	a0,s1
    800052e6:	ffffc097          	auipc	ra,0xffffc
    800052ea:	9b2080e7          	jalr	-1614(ra) # 80000c98 <release>
  return i;
}
    800052ee:	854e                	mv	a0,s3
    800052f0:	60a6                	ld	ra,72(sp)
    800052f2:	6406                	ld	s0,64(sp)
    800052f4:	74e2                	ld	s1,56(sp)
    800052f6:	7942                	ld	s2,48(sp)
    800052f8:	79a2                	ld	s3,40(sp)
    800052fa:	7a02                	ld	s4,32(sp)
    800052fc:	6ae2                	ld	s5,24(sp)
    800052fe:	6b42                	ld	s6,16(sp)
    80005300:	6161                	addi	sp,sp,80
    80005302:	8082                	ret
      release(&pi->lock);
    80005304:	8526                	mv	a0,s1
    80005306:	ffffc097          	auipc	ra,0xffffc
    8000530a:	992080e7          	jalr	-1646(ra) # 80000c98 <release>
      return -1;
    8000530e:	59fd                	li	s3,-1
    80005310:	bff9                	j	800052ee <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005312:	4981                	li	s3,0
    80005314:	b7d1                	j	800052d8 <piperead+0xae>

0000000080005316 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005316:	df010113          	addi	sp,sp,-528
    8000531a:	20113423          	sd	ra,520(sp)
    8000531e:	20813023          	sd	s0,512(sp)
    80005322:	ffa6                	sd	s1,504(sp)
    80005324:	fbca                	sd	s2,496(sp)
    80005326:	f7ce                	sd	s3,488(sp)
    80005328:	f3d2                	sd	s4,480(sp)
    8000532a:	efd6                	sd	s5,472(sp)
    8000532c:	ebda                	sd	s6,464(sp)
    8000532e:	e7de                	sd	s7,456(sp)
    80005330:	e3e2                	sd	s8,448(sp)
    80005332:	ff66                	sd	s9,440(sp)
    80005334:	fb6a                	sd	s10,432(sp)
    80005336:	f76e                	sd	s11,424(sp)
    80005338:	0c00                	addi	s0,sp,528
    8000533a:	84aa                	mv	s1,a0
    8000533c:	dea43c23          	sd	a0,-520(s0)
    80005340:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005344:	ffffd097          	auipc	ra,0xffffd
    80005348:	8b2080e7          	jalr	-1870(ra) # 80001bf6 <myproc>
    8000534c:	892a                	mv	s2,a0

  begin_op();
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	49c080e7          	jalr	1180(ra) # 800047ea <begin_op>

  if((ip = namei(path)) == 0){
    80005356:	8526                	mv	a0,s1
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	276080e7          	jalr	630(ra) # 800045ce <namei>
    80005360:	c92d                	beqz	a0,800053d2 <exec+0xbc>
    80005362:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	ab4080e7          	jalr	-1356(ra) # 80003e18 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000536c:	04000713          	li	a4,64
    80005370:	4681                	li	a3,0
    80005372:	e5040613          	addi	a2,s0,-432
    80005376:	4581                	li	a1,0
    80005378:	8526                	mv	a0,s1
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	d52080e7          	jalr	-686(ra) # 800040cc <readi>
    80005382:	04000793          	li	a5,64
    80005386:	00f51a63          	bne	a0,a5,8000539a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000538a:	e5042703          	lw	a4,-432(s0)
    8000538e:	464c47b7          	lui	a5,0x464c4
    80005392:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005396:	04f70463          	beq	a4,a5,800053de <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000539a:	8526                	mv	a0,s1
    8000539c:	fffff097          	auipc	ra,0xfffff
    800053a0:	cde080e7          	jalr	-802(ra) # 8000407a <iunlockput>
    end_op();
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	4c6080e7          	jalr	1222(ra) # 8000486a <end_op>
  }
  return -1;
    800053ac:	557d                	li	a0,-1
}
    800053ae:	20813083          	ld	ra,520(sp)
    800053b2:	20013403          	ld	s0,512(sp)
    800053b6:	74fe                	ld	s1,504(sp)
    800053b8:	795e                	ld	s2,496(sp)
    800053ba:	79be                	ld	s3,488(sp)
    800053bc:	7a1e                	ld	s4,480(sp)
    800053be:	6afe                	ld	s5,472(sp)
    800053c0:	6b5e                	ld	s6,464(sp)
    800053c2:	6bbe                	ld	s7,456(sp)
    800053c4:	6c1e                	ld	s8,448(sp)
    800053c6:	7cfa                	ld	s9,440(sp)
    800053c8:	7d5a                	ld	s10,432(sp)
    800053ca:	7dba                	ld	s11,424(sp)
    800053cc:	21010113          	addi	sp,sp,528
    800053d0:	8082                	ret
    end_op();
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	498080e7          	jalr	1176(ra) # 8000486a <end_op>
    return -1;
    800053da:	557d                	li	a0,-1
    800053dc:	bfc9                	j	800053ae <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800053de:	854a                	mv	a0,s2
    800053e0:	ffffd097          	auipc	ra,0xffffd
    800053e4:	8da080e7          	jalr	-1830(ra) # 80001cba <proc_pagetable>
    800053e8:	8baa                	mv	s7,a0
    800053ea:	d945                	beqz	a0,8000539a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053ec:	e7042983          	lw	s3,-400(s0)
    800053f0:	e8845783          	lhu	a5,-376(s0)
    800053f4:	c7ad                	beqz	a5,8000545e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053f6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053f8:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800053fa:	6c85                	lui	s9,0x1
    800053fc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005400:	def43823          	sd	a5,-528(s0)
    80005404:	a42d                	j	8000562e <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005406:	00003517          	auipc	a0,0x3
    8000540a:	39a50513          	addi	a0,a0,922 # 800087a0 <syscalls+0x298>
    8000540e:	ffffb097          	auipc	ra,0xffffb
    80005412:	130080e7          	jalr	304(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005416:	8756                	mv	a4,s5
    80005418:	012d86bb          	addw	a3,s11,s2
    8000541c:	4581                	li	a1,0
    8000541e:	8526                	mv	a0,s1
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	cac080e7          	jalr	-852(ra) # 800040cc <readi>
    80005428:	2501                	sext.w	a0,a0
    8000542a:	1aaa9963          	bne	s5,a0,800055dc <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000542e:	6785                	lui	a5,0x1
    80005430:	0127893b          	addw	s2,a5,s2
    80005434:	77fd                	lui	a5,0xfffff
    80005436:	01478a3b          	addw	s4,a5,s4
    8000543a:	1f897163          	bgeu	s2,s8,8000561c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000543e:	02091593          	slli	a1,s2,0x20
    80005442:	9181                	srli	a1,a1,0x20
    80005444:	95ea                	add	a1,a1,s10
    80005446:	855e                	mv	a0,s7
    80005448:	ffffc097          	auipc	ra,0xffffc
    8000544c:	d4a080e7          	jalr	-694(ra) # 80001192 <walkaddr>
    80005450:	862a                	mv	a2,a0
    if(pa == 0)
    80005452:	d955                	beqz	a0,80005406 <exec+0xf0>
      n = PGSIZE;
    80005454:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005456:	fd9a70e3          	bgeu	s4,s9,80005416 <exec+0x100>
      n = sz - i;
    8000545a:	8ad2                	mv	s5,s4
    8000545c:	bf6d                	j	80005416 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000545e:	4901                	li	s2,0
  iunlockput(ip);
    80005460:	8526                	mv	a0,s1
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	c18080e7          	jalr	-1000(ra) # 8000407a <iunlockput>
  end_op();
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	400080e7          	jalr	1024(ra) # 8000486a <end_op>
  p = myproc();
    80005472:	ffffc097          	auipc	ra,0xffffc
    80005476:	784080e7          	jalr	1924(ra) # 80001bf6 <myproc>
    8000547a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000547c:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005480:	6785                	lui	a5,0x1
    80005482:	17fd                	addi	a5,a5,-1
    80005484:	993e                	add	s2,s2,a5
    80005486:	757d                	lui	a0,0xfffff
    80005488:	00a977b3          	and	a5,s2,a0
    8000548c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005490:	6609                	lui	a2,0x2
    80005492:	963e                	add	a2,a2,a5
    80005494:	85be                	mv	a1,a5
    80005496:	855e                	mv	a0,s7
    80005498:	ffffc097          	auipc	ra,0xffffc
    8000549c:	0ae080e7          	jalr	174(ra) # 80001546 <uvmalloc>
    800054a0:	8b2a                	mv	s6,a0
  ip = 0;
    800054a2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054a4:	12050c63          	beqz	a0,800055dc <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054a8:	75f9                	lui	a1,0xffffe
    800054aa:	95aa                	add	a1,a1,a0
    800054ac:	855e                	mv	a0,s7
    800054ae:	ffffc097          	auipc	ra,0xffffc
    800054b2:	2b6080e7          	jalr	694(ra) # 80001764 <uvmclear>
  stackbase = sp - PGSIZE;
    800054b6:	7c7d                	lui	s8,0xfffff
    800054b8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800054ba:	e0043783          	ld	a5,-512(s0)
    800054be:	6388                	ld	a0,0(a5)
    800054c0:	c535                	beqz	a0,8000552c <exec+0x216>
    800054c2:	e9040993          	addi	s3,s0,-368
    800054c6:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054ca:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	998080e7          	jalr	-1640(ra) # 80000e64 <strlen>
    800054d4:	2505                	addiw	a0,a0,1
    800054d6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054da:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800054de:	13896363          	bltu	s2,s8,80005604 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800054e2:	e0043d83          	ld	s11,-512(s0)
    800054e6:	000dba03          	ld	s4,0(s11)
    800054ea:	8552                	mv	a0,s4
    800054ec:	ffffc097          	auipc	ra,0xffffc
    800054f0:	978080e7          	jalr	-1672(ra) # 80000e64 <strlen>
    800054f4:	0015069b          	addiw	a3,a0,1
    800054f8:	8652                	mv	a2,s4
    800054fa:	85ca                	mv	a1,s2
    800054fc:	855e                	mv	a0,s7
    800054fe:	ffffc097          	auipc	ra,0xffffc
    80005502:	298080e7          	jalr	664(ra) # 80001796 <copyout>
    80005506:	10054363          	bltz	a0,8000560c <exec+0x2f6>
    ustack[argc] = sp;
    8000550a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000550e:	0485                	addi	s1,s1,1
    80005510:	008d8793          	addi	a5,s11,8
    80005514:	e0f43023          	sd	a5,-512(s0)
    80005518:	008db503          	ld	a0,8(s11)
    8000551c:	c911                	beqz	a0,80005530 <exec+0x21a>
    if(argc >= MAXARG)
    8000551e:	09a1                	addi	s3,s3,8
    80005520:	fb3c96e3          	bne	s9,s3,800054cc <exec+0x1b6>
  sz = sz1;
    80005524:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005528:	4481                	li	s1,0
    8000552a:	a84d                	j	800055dc <exec+0x2c6>
  sp = sz;
    8000552c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000552e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005530:	00349793          	slli	a5,s1,0x3
    80005534:	f9040713          	addi	a4,s0,-112
    80005538:	97ba                	add	a5,a5,a4
    8000553a:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000553e:	00148693          	addi	a3,s1,1
    80005542:	068e                	slli	a3,a3,0x3
    80005544:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005548:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000554c:	01897663          	bgeu	s2,s8,80005558 <exec+0x242>
  sz = sz1;
    80005550:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005554:	4481                	li	s1,0
    80005556:	a059                	j	800055dc <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005558:	e9040613          	addi	a2,s0,-368
    8000555c:	85ca                	mv	a1,s2
    8000555e:	855e                	mv	a0,s7
    80005560:	ffffc097          	auipc	ra,0xffffc
    80005564:	236080e7          	jalr	566(ra) # 80001796 <copyout>
    80005568:	0a054663          	bltz	a0,80005614 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000556c:	078ab783          	ld	a5,120(s5)
    80005570:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005574:	df843783          	ld	a5,-520(s0)
    80005578:	0007c703          	lbu	a4,0(a5)
    8000557c:	cf11                	beqz	a4,80005598 <exec+0x282>
    8000557e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005580:	02f00693          	li	a3,47
    80005584:	a039                	j	80005592 <exec+0x27c>
      last = s+1;
    80005586:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000558a:	0785                	addi	a5,a5,1
    8000558c:	fff7c703          	lbu	a4,-1(a5)
    80005590:	c701                	beqz	a4,80005598 <exec+0x282>
    if(*s == '/')
    80005592:	fed71ce3          	bne	a4,a3,8000558a <exec+0x274>
    80005596:	bfc5                	j	80005586 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005598:	4641                	li	a2,16
    8000559a:	df843583          	ld	a1,-520(s0)
    8000559e:	178a8513          	addi	a0,s5,376
    800055a2:	ffffc097          	auipc	ra,0xffffc
    800055a6:	890080e7          	jalr	-1904(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800055aa:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800055ae:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800055b2:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055b6:	078ab783          	ld	a5,120(s5)
    800055ba:	e6843703          	ld	a4,-408(s0)
    800055be:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055c0:	078ab783          	ld	a5,120(s5)
    800055c4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055c8:	85ea                	mv	a1,s10
    800055ca:	ffffc097          	auipc	ra,0xffffc
    800055ce:	78c080e7          	jalr	1932(ra) # 80001d56 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055d2:	0004851b          	sext.w	a0,s1
    800055d6:	bbe1                	j	800053ae <exec+0x98>
    800055d8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055dc:	e0843583          	ld	a1,-504(s0)
    800055e0:	855e                	mv	a0,s7
    800055e2:	ffffc097          	auipc	ra,0xffffc
    800055e6:	774080e7          	jalr	1908(ra) # 80001d56 <proc_freepagetable>
  if(ip){
    800055ea:	da0498e3          	bnez	s1,8000539a <exec+0x84>
  return -1;
    800055ee:	557d                	li	a0,-1
    800055f0:	bb7d                	j	800053ae <exec+0x98>
    800055f2:	e1243423          	sd	s2,-504(s0)
    800055f6:	b7dd                	j	800055dc <exec+0x2c6>
    800055f8:	e1243423          	sd	s2,-504(s0)
    800055fc:	b7c5                	j	800055dc <exec+0x2c6>
    800055fe:	e1243423          	sd	s2,-504(s0)
    80005602:	bfe9                	j	800055dc <exec+0x2c6>
  sz = sz1;
    80005604:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005608:	4481                	li	s1,0
    8000560a:	bfc9                	j	800055dc <exec+0x2c6>
  sz = sz1;
    8000560c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005610:	4481                	li	s1,0
    80005612:	b7e9                	j	800055dc <exec+0x2c6>
  sz = sz1;
    80005614:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005618:	4481                	li	s1,0
    8000561a:	b7c9                	j	800055dc <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000561c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005620:	2b05                	addiw	s6,s6,1
    80005622:	0389899b          	addiw	s3,s3,56
    80005626:	e8845783          	lhu	a5,-376(s0)
    8000562a:	e2fb5be3          	bge	s6,a5,80005460 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000562e:	2981                	sext.w	s3,s3
    80005630:	03800713          	li	a4,56
    80005634:	86ce                	mv	a3,s3
    80005636:	e1840613          	addi	a2,s0,-488
    8000563a:	4581                	li	a1,0
    8000563c:	8526                	mv	a0,s1
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	a8e080e7          	jalr	-1394(ra) # 800040cc <readi>
    80005646:	03800793          	li	a5,56
    8000564a:	f8f517e3          	bne	a0,a5,800055d8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000564e:	e1842783          	lw	a5,-488(s0)
    80005652:	4705                	li	a4,1
    80005654:	fce796e3          	bne	a5,a4,80005620 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005658:	e4043603          	ld	a2,-448(s0)
    8000565c:	e3843783          	ld	a5,-456(s0)
    80005660:	f8f669e3          	bltu	a2,a5,800055f2 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005664:	e2843783          	ld	a5,-472(s0)
    80005668:	963e                	add	a2,a2,a5
    8000566a:	f8f667e3          	bltu	a2,a5,800055f8 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000566e:	85ca                	mv	a1,s2
    80005670:	855e                	mv	a0,s7
    80005672:	ffffc097          	auipc	ra,0xffffc
    80005676:	ed4080e7          	jalr	-300(ra) # 80001546 <uvmalloc>
    8000567a:	e0a43423          	sd	a0,-504(s0)
    8000567e:	d141                	beqz	a0,800055fe <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005680:	e2843d03          	ld	s10,-472(s0)
    80005684:	df043783          	ld	a5,-528(s0)
    80005688:	00fd77b3          	and	a5,s10,a5
    8000568c:	fba1                	bnez	a5,800055dc <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000568e:	e2042d83          	lw	s11,-480(s0)
    80005692:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005696:	f80c03e3          	beqz	s8,8000561c <exec+0x306>
    8000569a:	8a62                	mv	s4,s8
    8000569c:	4901                	li	s2,0
    8000569e:	b345                	j	8000543e <exec+0x128>

00000000800056a0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056a0:	7179                	addi	sp,sp,-48
    800056a2:	f406                	sd	ra,40(sp)
    800056a4:	f022                	sd	s0,32(sp)
    800056a6:	ec26                	sd	s1,24(sp)
    800056a8:	e84a                	sd	s2,16(sp)
    800056aa:	1800                	addi	s0,sp,48
    800056ac:	892e                	mv	s2,a1
    800056ae:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056b0:	fdc40593          	addi	a1,s0,-36
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	b90080e7          	jalr	-1136(ra) # 80003244 <argint>
    800056bc:	04054063          	bltz	a0,800056fc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056c0:	fdc42703          	lw	a4,-36(s0)
    800056c4:	47bd                	li	a5,15
    800056c6:	02e7ed63          	bltu	a5,a4,80005700 <argfd+0x60>
    800056ca:	ffffc097          	auipc	ra,0xffffc
    800056ce:	52c080e7          	jalr	1324(ra) # 80001bf6 <myproc>
    800056d2:	fdc42703          	lw	a4,-36(s0)
    800056d6:	01e70793          	addi	a5,a4,30
    800056da:	078e                	slli	a5,a5,0x3
    800056dc:	953e                	add	a0,a0,a5
    800056de:	611c                	ld	a5,0(a0)
    800056e0:	c395                	beqz	a5,80005704 <argfd+0x64>
    return -1;
  if(pfd)
    800056e2:	00090463          	beqz	s2,800056ea <argfd+0x4a>
    *pfd = fd;
    800056e6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056ea:	4501                	li	a0,0
  if(pf)
    800056ec:	c091                	beqz	s1,800056f0 <argfd+0x50>
    *pf = f;
    800056ee:	e09c                	sd	a5,0(s1)
}
    800056f0:	70a2                	ld	ra,40(sp)
    800056f2:	7402                	ld	s0,32(sp)
    800056f4:	64e2                	ld	s1,24(sp)
    800056f6:	6942                	ld	s2,16(sp)
    800056f8:	6145                	addi	sp,sp,48
    800056fa:	8082                	ret
    return -1;
    800056fc:	557d                	li	a0,-1
    800056fe:	bfcd                	j	800056f0 <argfd+0x50>
    return -1;
    80005700:	557d                	li	a0,-1
    80005702:	b7fd                	j	800056f0 <argfd+0x50>
    80005704:	557d                	li	a0,-1
    80005706:	b7ed                	j	800056f0 <argfd+0x50>

0000000080005708 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005708:	1101                	addi	sp,sp,-32
    8000570a:	ec06                	sd	ra,24(sp)
    8000570c:	e822                	sd	s0,16(sp)
    8000570e:	e426                	sd	s1,8(sp)
    80005710:	1000                	addi	s0,sp,32
    80005712:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005714:	ffffc097          	auipc	ra,0xffffc
    80005718:	4e2080e7          	jalr	1250(ra) # 80001bf6 <myproc>
    8000571c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000571e:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    80005722:	4501                	li	a0,0
    80005724:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005726:	6398                	ld	a4,0(a5)
    80005728:	cb19                	beqz	a4,8000573e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000572a:	2505                	addiw	a0,a0,1
    8000572c:	07a1                	addi	a5,a5,8
    8000572e:	fed51ce3          	bne	a0,a3,80005726 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005732:	557d                	li	a0,-1
}
    80005734:	60e2                	ld	ra,24(sp)
    80005736:	6442                	ld	s0,16(sp)
    80005738:	64a2                	ld	s1,8(sp)
    8000573a:	6105                	addi	sp,sp,32
    8000573c:	8082                	ret
      p->ofile[fd] = f;
    8000573e:	01e50793          	addi	a5,a0,30
    80005742:	078e                	slli	a5,a5,0x3
    80005744:	963e                	add	a2,a2,a5
    80005746:	e204                	sd	s1,0(a2)
      return fd;
    80005748:	b7f5                	j	80005734 <fdalloc+0x2c>

000000008000574a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000574a:	715d                	addi	sp,sp,-80
    8000574c:	e486                	sd	ra,72(sp)
    8000574e:	e0a2                	sd	s0,64(sp)
    80005750:	fc26                	sd	s1,56(sp)
    80005752:	f84a                	sd	s2,48(sp)
    80005754:	f44e                	sd	s3,40(sp)
    80005756:	f052                	sd	s4,32(sp)
    80005758:	ec56                	sd	s5,24(sp)
    8000575a:	0880                	addi	s0,sp,80
    8000575c:	89ae                	mv	s3,a1
    8000575e:	8ab2                	mv	s5,a2
    80005760:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005762:	fb040593          	addi	a1,s0,-80
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	e86080e7          	jalr	-378(ra) # 800045ec <nameiparent>
    8000576e:	892a                	mv	s2,a0
    80005770:	12050f63          	beqz	a0,800058ae <create+0x164>
    return 0;

  ilock(dp);
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	6a4080e7          	jalr	1700(ra) # 80003e18 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000577c:	4601                	li	a2,0
    8000577e:	fb040593          	addi	a1,s0,-80
    80005782:	854a                	mv	a0,s2
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	b78080e7          	jalr	-1160(ra) # 800042fc <dirlookup>
    8000578c:	84aa                	mv	s1,a0
    8000578e:	c921                	beqz	a0,800057de <create+0x94>
    iunlockput(dp);
    80005790:	854a                	mv	a0,s2
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	8e8080e7          	jalr	-1816(ra) # 8000407a <iunlockput>
    ilock(ip);
    8000579a:	8526                	mv	a0,s1
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	67c080e7          	jalr	1660(ra) # 80003e18 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057a4:	2981                	sext.w	s3,s3
    800057a6:	4789                	li	a5,2
    800057a8:	02f99463          	bne	s3,a5,800057d0 <create+0x86>
    800057ac:	0444d783          	lhu	a5,68(s1)
    800057b0:	37f9                	addiw	a5,a5,-2
    800057b2:	17c2                	slli	a5,a5,0x30
    800057b4:	93c1                	srli	a5,a5,0x30
    800057b6:	4705                	li	a4,1
    800057b8:	00f76c63          	bltu	a4,a5,800057d0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800057bc:	8526                	mv	a0,s1
    800057be:	60a6                	ld	ra,72(sp)
    800057c0:	6406                	ld	s0,64(sp)
    800057c2:	74e2                	ld	s1,56(sp)
    800057c4:	7942                	ld	s2,48(sp)
    800057c6:	79a2                	ld	s3,40(sp)
    800057c8:	7a02                	ld	s4,32(sp)
    800057ca:	6ae2                	ld	s5,24(sp)
    800057cc:	6161                	addi	sp,sp,80
    800057ce:	8082                	ret
    iunlockput(ip);
    800057d0:	8526                	mv	a0,s1
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	8a8080e7          	jalr	-1880(ra) # 8000407a <iunlockput>
    return 0;
    800057da:	4481                	li	s1,0
    800057dc:	b7c5                	j	800057bc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800057de:	85ce                	mv	a1,s3
    800057e0:	00092503          	lw	a0,0(s2)
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	49c080e7          	jalr	1180(ra) # 80003c80 <ialloc>
    800057ec:	84aa                	mv	s1,a0
    800057ee:	c529                	beqz	a0,80005838 <create+0xee>
  ilock(ip);
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	628080e7          	jalr	1576(ra) # 80003e18 <ilock>
  ip->major = major;
    800057f8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800057fc:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005800:	4785                	li	a5,1
    80005802:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005806:	8526                	mv	a0,s1
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	546080e7          	jalr	1350(ra) # 80003d4e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005810:	2981                	sext.w	s3,s3
    80005812:	4785                	li	a5,1
    80005814:	02f98a63          	beq	s3,a5,80005848 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005818:	40d0                	lw	a2,4(s1)
    8000581a:	fb040593          	addi	a1,s0,-80
    8000581e:	854a                	mv	a0,s2
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	cec080e7          	jalr	-788(ra) # 8000450c <dirlink>
    80005828:	06054b63          	bltz	a0,8000589e <create+0x154>
  iunlockput(dp);
    8000582c:	854a                	mv	a0,s2
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	84c080e7          	jalr	-1972(ra) # 8000407a <iunlockput>
  return ip;
    80005836:	b759                	j	800057bc <create+0x72>
    panic("create: ialloc");
    80005838:	00003517          	auipc	a0,0x3
    8000583c:	f8850513          	addi	a0,a0,-120 # 800087c0 <syscalls+0x2b8>
    80005840:	ffffb097          	auipc	ra,0xffffb
    80005844:	cfe080e7          	jalr	-770(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005848:	04a95783          	lhu	a5,74(s2)
    8000584c:	2785                	addiw	a5,a5,1
    8000584e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005852:	854a                	mv	a0,s2
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	4fa080e7          	jalr	1274(ra) # 80003d4e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000585c:	40d0                	lw	a2,4(s1)
    8000585e:	00003597          	auipc	a1,0x3
    80005862:	f7258593          	addi	a1,a1,-142 # 800087d0 <syscalls+0x2c8>
    80005866:	8526                	mv	a0,s1
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	ca4080e7          	jalr	-860(ra) # 8000450c <dirlink>
    80005870:	00054f63          	bltz	a0,8000588e <create+0x144>
    80005874:	00492603          	lw	a2,4(s2)
    80005878:	00003597          	auipc	a1,0x3
    8000587c:	f6058593          	addi	a1,a1,-160 # 800087d8 <syscalls+0x2d0>
    80005880:	8526                	mv	a0,s1
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	c8a080e7          	jalr	-886(ra) # 8000450c <dirlink>
    8000588a:	f80557e3          	bgez	a0,80005818 <create+0xce>
      panic("create dots");
    8000588e:	00003517          	auipc	a0,0x3
    80005892:	f5250513          	addi	a0,a0,-174 # 800087e0 <syscalls+0x2d8>
    80005896:	ffffb097          	auipc	ra,0xffffb
    8000589a:	ca8080e7          	jalr	-856(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000589e:	00003517          	auipc	a0,0x3
    800058a2:	f5250513          	addi	a0,a0,-174 # 800087f0 <syscalls+0x2e8>
    800058a6:	ffffb097          	auipc	ra,0xffffb
    800058aa:	c98080e7          	jalr	-872(ra) # 8000053e <panic>
    return 0;
    800058ae:	84aa                	mv	s1,a0
    800058b0:	b731                	j	800057bc <create+0x72>

00000000800058b2 <sys_dup>:
{
    800058b2:	7179                	addi	sp,sp,-48
    800058b4:	f406                	sd	ra,40(sp)
    800058b6:	f022                	sd	s0,32(sp)
    800058b8:	ec26                	sd	s1,24(sp)
    800058ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058bc:	fd840613          	addi	a2,s0,-40
    800058c0:	4581                	li	a1,0
    800058c2:	4501                	li	a0,0
    800058c4:	00000097          	auipc	ra,0x0
    800058c8:	ddc080e7          	jalr	-548(ra) # 800056a0 <argfd>
    return -1;
    800058cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058ce:	02054363          	bltz	a0,800058f4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058d2:	fd843503          	ld	a0,-40(s0)
    800058d6:	00000097          	auipc	ra,0x0
    800058da:	e32080e7          	jalr	-462(ra) # 80005708 <fdalloc>
    800058de:	84aa                	mv	s1,a0
    return -1;
    800058e0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058e2:	00054963          	bltz	a0,800058f4 <sys_dup+0x42>
  filedup(f);
    800058e6:	fd843503          	ld	a0,-40(s0)
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	37a080e7          	jalr	890(ra) # 80004c64 <filedup>
  return fd;
    800058f2:	87a6                	mv	a5,s1
}
    800058f4:	853e                	mv	a0,a5
    800058f6:	70a2                	ld	ra,40(sp)
    800058f8:	7402                	ld	s0,32(sp)
    800058fa:	64e2                	ld	s1,24(sp)
    800058fc:	6145                	addi	sp,sp,48
    800058fe:	8082                	ret

0000000080005900 <sys_read>:
{
    80005900:	7179                	addi	sp,sp,-48
    80005902:	f406                	sd	ra,40(sp)
    80005904:	f022                	sd	s0,32(sp)
    80005906:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005908:	fe840613          	addi	a2,s0,-24
    8000590c:	4581                	li	a1,0
    8000590e:	4501                	li	a0,0
    80005910:	00000097          	auipc	ra,0x0
    80005914:	d90080e7          	jalr	-624(ra) # 800056a0 <argfd>
    return -1;
    80005918:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000591a:	04054163          	bltz	a0,8000595c <sys_read+0x5c>
    8000591e:	fe440593          	addi	a1,s0,-28
    80005922:	4509                	li	a0,2
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	920080e7          	jalr	-1760(ra) # 80003244 <argint>
    return -1;
    8000592c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000592e:	02054763          	bltz	a0,8000595c <sys_read+0x5c>
    80005932:	fd840593          	addi	a1,s0,-40
    80005936:	4505                	li	a0,1
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	92e080e7          	jalr	-1746(ra) # 80003266 <argaddr>
    return -1;
    80005940:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005942:	00054d63          	bltz	a0,8000595c <sys_read+0x5c>
  return fileread(f, p, n);
    80005946:	fe442603          	lw	a2,-28(s0)
    8000594a:	fd843583          	ld	a1,-40(s0)
    8000594e:	fe843503          	ld	a0,-24(s0)
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	49e080e7          	jalr	1182(ra) # 80004df0 <fileread>
    8000595a:	87aa                	mv	a5,a0
}
    8000595c:	853e                	mv	a0,a5
    8000595e:	70a2                	ld	ra,40(sp)
    80005960:	7402                	ld	s0,32(sp)
    80005962:	6145                	addi	sp,sp,48
    80005964:	8082                	ret

0000000080005966 <sys_write>:
{
    80005966:	7179                	addi	sp,sp,-48
    80005968:	f406                	sd	ra,40(sp)
    8000596a:	f022                	sd	s0,32(sp)
    8000596c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000596e:	fe840613          	addi	a2,s0,-24
    80005972:	4581                	li	a1,0
    80005974:	4501                	li	a0,0
    80005976:	00000097          	auipc	ra,0x0
    8000597a:	d2a080e7          	jalr	-726(ra) # 800056a0 <argfd>
    return -1;
    8000597e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005980:	04054163          	bltz	a0,800059c2 <sys_write+0x5c>
    80005984:	fe440593          	addi	a1,s0,-28
    80005988:	4509                	li	a0,2
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	8ba080e7          	jalr	-1862(ra) # 80003244 <argint>
    return -1;
    80005992:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005994:	02054763          	bltz	a0,800059c2 <sys_write+0x5c>
    80005998:	fd840593          	addi	a1,s0,-40
    8000599c:	4505                	li	a0,1
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	8c8080e7          	jalr	-1848(ra) # 80003266 <argaddr>
    return -1;
    800059a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059a8:	00054d63          	bltz	a0,800059c2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800059ac:	fe442603          	lw	a2,-28(s0)
    800059b0:	fd843583          	ld	a1,-40(s0)
    800059b4:	fe843503          	ld	a0,-24(s0)
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	4fa080e7          	jalr	1274(ra) # 80004eb2 <filewrite>
    800059c0:	87aa                	mv	a5,a0
}
    800059c2:	853e                	mv	a0,a5
    800059c4:	70a2                	ld	ra,40(sp)
    800059c6:	7402                	ld	s0,32(sp)
    800059c8:	6145                	addi	sp,sp,48
    800059ca:	8082                	ret

00000000800059cc <sys_close>:
{
    800059cc:	1101                	addi	sp,sp,-32
    800059ce:	ec06                	sd	ra,24(sp)
    800059d0:	e822                	sd	s0,16(sp)
    800059d2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059d4:	fe040613          	addi	a2,s0,-32
    800059d8:	fec40593          	addi	a1,s0,-20
    800059dc:	4501                	li	a0,0
    800059de:	00000097          	auipc	ra,0x0
    800059e2:	cc2080e7          	jalr	-830(ra) # 800056a0 <argfd>
    return -1;
    800059e6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059e8:	02054463          	bltz	a0,80005a10 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059ec:	ffffc097          	auipc	ra,0xffffc
    800059f0:	20a080e7          	jalr	522(ra) # 80001bf6 <myproc>
    800059f4:	fec42783          	lw	a5,-20(s0)
    800059f8:	07f9                	addi	a5,a5,30
    800059fa:	078e                	slli	a5,a5,0x3
    800059fc:	97aa                	add	a5,a5,a0
    800059fe:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a02:	fe043503          	ld	a0,-32(s0)
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	2b0080e7          	jalr	688(ra) # 80004cb6 <fileclose>
  return 0;
    80005a0e:	4781                	li	a5,0
}
    80005a10:	853e                	mv	a0,a5
    80005a12:	60e2                	ld	ra,24(sp)
    80005a14:	6442                	ld	s0,16(sp)
    80005a16:	6105                	addi	sp,sp,32
    80005a18:	8082                	ret

0000000080005a1a <sys_fstat>:
{
    80005a1a:	1101                	addi	sp,sp,-32
    80005a1c:	ec06                	sd	ra,24(sp)
    80005a1e:	e822                	sd	s0,16(sp)
    80005a20:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a22:	fe840613          	addi	a2,s0,-24
    80005a26:	4581                	li	a1,0
    80005a28:	4501                	li	a0,0
    80005a2a:	00000097          	auipc	ra,0x0
    80005a2e:	c76080e7          	jalr	-906(ra) # 800056a0 <argfd>
    return -1;
    80005a32:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a34:	02054563          	bltz	a0,80005a5e <sys_fstat+0x44>
    80005a38:	fe040593          	addi	a1,s0,-32
    80005a3c:	4505                	li	a0,1
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	828080e7          	jalr	-2008(ra) # 80003266 <argaddr>
    return -1;
    80005a46:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a48:	00054b63          	bltz	a0,80005a5e <sys_fstat+0x44>
  return filestat(f, st);
    80005a4c:	fe043583          	ld	a1,-32(s0)
    80005a50:	fe843503          	ld	a0,-24(s0)
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	32a080e7          	jalr	810(ra) # 80004d7e <filestat>
    80005a5c:	87aa                	mv	a5,a0
}
    80005a5e:	853e                	mv	a0,a5
    80005a60:	60e2                	ld	ra,24(sp)
    80005a62:	6442                	ld	s0,16(sp)
    80005a64:	6105                	addi	sp,sp,32
    80005a66:	8082                	ret

0000000080005a68 <sys_link>:
{
    80005a68:	7169                	addi	sp,sp,-304
    80005a6a:	f606                	sd	ra,296(sp)
    80005a6c:	f222                	sd	s0,288(sp)
    80005a6e:	ee26                	sd	s1,280(sp)
    80005a70:	ea4a                	sd	s2,272(sp)
    80005a72:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a74:	08000613          	li	a2,128
    80005a78:	ed040593          	addi	a1,s0,-304
    80005a7c:	4501                	li	a0,0
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	80a080e7          	jalr	-2038(ra) # 80003288 <argstr>
    return -1;
    80005a86:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a88:	10054e63          	bltz	a0,80005ba4 <sys_link+0x13c>
    80005a8c:	08000613          	li	a2,128
    80005a90:	f5040593          	addi	a1,s0,-176
    80005a94:	4505                	li	a0,1
    80005a96:	ffffd097          	auipc	ra,0xffffd
    80005a9a:	7f2080e7          	jalr	2034(ra) # 80003288 <argstr>
    return -1;
    80005a9e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aa0:	10054263          	bltz	a0,80005ba4 <sys_link+0x13c>
  begin_op();
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	d46080e7          	jalr	-698(ra) # 800047ea <begin_op>
  if((ip = namei(old)) == 0){
    80005aac:	ed040513          	addi	a0,s0,-304
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	b1e080e7          	jalr	-1250(ra) # 800045ce <namei>
    80005ab8:	84aa                	mv	s1,a0
    80005aba:	c551                	beqz	a0,80005b46 <sys_link+0xde>
  ilock(ip);
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	35c080e7          	jalr	860(ra) # 80003e18 <ilock>
  if(ip->type == T_DIR){
    80005ac4:	04449703          	lh	a4,68(s1)
    80005ac8:	4785                	li	a5,1
    80005aca:	08f70463          	beq	a4,a5,80005b52 <sys_link+0xea>
  ip->nlink++;
    80005ace:	04a4d783          	lhu	a5,74(s1)
    80005ad2:	2785                	addiw	a5,a5,1
    80005ad4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ad8:	8526                	mv	a0,s1
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	274080e7          	jalr	628(ra) # 80003d4e <iupdate>
  iunlock(ip);
    80005ae2:	8526                	mv	a0,s1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	3f6080e7          	jalr	1014(ra) # 80003eda <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005aec:	fd040593          	addi	a1,s0,-48
    80005af0:	f5040513          	addi	a0,s0,-176
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	af8080e7          	jalr	-1288(ra) # 800045ec <nameiparent>
    80005afc:	892a                	mv	s2,a0
    80005afe:	c935                	beqz	a0,80005b72 <sys_link+0x10a>
  ilock(dp);
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	318080e7          	jalr	792(ra) # 80003e18 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b08:	00092703          	lw	a4,0(s2)
    80005b0c:	409c                	lw	a5,0(s1)
    80005b0e:	04f71d63          	bne	a4,a5,80005b68 <sys_link+0x100>
    80005b12:	40d0                	lw	a2,4(s1)
    80005b14:	fd040593          	addi	a1,s0,-48
    80005b18:	854a                	mv	a0,s2
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	9f2080e7          	jalr	-1550(ra) # 8000450c <dirlink>
    80005b22:	04054363          	bltz	a0,80005b68 <sys_link+0x100>
  iunlockput(dp);
    80005b26:	854a                	mv	a0,s2
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	552080e7          	jalr	1362(ra) # 8000407a <iunlockput>
  iput(ip);
    80005b30:	8526                	mv	a0,s1
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	4a0080e7          	jalr	1184(ra) # 80003fd2 <iput>
  end_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	d30080e7          	jalr	-720(ra) # 8000486a <end_op>
  return 0;
    80005b42:	4781                	li	a5,0
    80005b44:	a085                	j	80005ba4 <sys_link+0x13c>
    end_op();
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	d24080e7          	jalr	-732(ra) # 8000486a <end_op>
    return -1;
    80005b4e:	57fd                	li	a5,-1
    80005b50:	a891                	j	80005ba4 <sys_link+0x13c>
    iunlockput(ip);
    80005b52:	8526                	mv	a0,s1
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	526080e7          	jalr	1318(ra) # 8000407a <iunlockput>
    end_op();
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	d0e080e7          	jalr	-754(ra) # 8000486a <end_op>
    return -1;
    80005b64:	57fd                	li	a5,-1
    80005b66:	a83d                	j	80005ba4 <sys_link+0x13c>
    iunlockput(dp);
    80005b68:	854a                	mv	a0,s2
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	510080e7          	jalr	1296(ra) # 8000407a <iunlockput>
  ilock(ip);
    80005b72:	8526                	mv	a0,s1
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	2a4080e7          	jalr	676(ra) # 80003e18 <ilock>
  ip->nlink--;
    80005b7c:	04a4d783          	lhu	a5,74(s1)
    80005b80:	37fd                	addiw	a5,a5,-1
    80005b82:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b86:	8526                	mv	a0,s1
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	1c6080e7          	jalr	454(ra) # 80003d4e <iupdate>
  iunlockput(ip);
    80005b90:	8526                	mv	a0,s1
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	4e8080e7          	jalr	1256(ra) # 8000407a <iunlockput>
  end_op();
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	cd0080e7          	jalr	-816(ra) # 8000486a <end_op>
  return -1;
    80005ba2:	57fd                	li	a5,-1
}
    80005ba4:	853e                	mv	a0,a5
    80005ba6:	70b2                	ld	ra,296(sp)
    80005ba8:	7412                	ld	s0,288(sp)
    80005baa:	64f2                	ld	s1,280(sp)
    80005bac:	6952                	ld	s2,272(sp)
    80005bae:	6155                	addi	sp,sp,304
    80005bb0:	8082                	ret

0000000080005bb2 <sys_unlink>:
{
    80005bb2:	7151                	addi	sp,sp,-240
    80005bb4:	f586                	sd	ra,232(sp)
    80005bb6:	f1a2                	sd	s0,224(sp)
    80005bb8:	eda6                	sd	s1,216(sp)
    80005bba:	e9ca                	sd	s2,208(sp)
    80005bbc:	e5ce                	sd	s3,200(sp)
    80005bbe:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005bc0:	08000613          	li	a2,128
    80005bc4:	f3040593          	addi	a1,s0,-208
    80005bc8:	4501                	li	a0,0
    80005bca:	ffffd097          	auipc	ra,0xffffd
    80005bce:	6be080e7          	jalr	1726(ra) # 80003288 <argstr>
    80005bd2:	18054163          	bltz	a0,80005d54 <sys_unlink+0x1a2>
  begin_op();
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	c14080e7          	jalr	-1004(ra) # 800047ea <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bde:	fb040593          	addi	a1,s0,-80
    80005be2:	f3040513          	addi	a0,s0,-208
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	a06080e7          	jalr	-1530(ra) # 800045ec <nameiparent>
    80005bee:	84aa                	mv	s1,a0
    80005bf0:	c979                	beqz	a0,80005cc6 <sys_unlink+0x114>
  ilock(dp);
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	226080e7          	jalr	550(ra) # 80003e18 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bfa:	00003597          	auipc	a1,0x3
    80005bfe:	bd658593          	addi	a1,a1,-1066 # 800087d0 <syscalls+0x2c8>
    80005c02:	fb040513          	addi	a0,s0,-80
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	6dc080e7          	jalr	1756(ra) # 800042e2 <namecmp>
    80005c0e:	14050a63          	beqz	a0,80005d62 <sys_unlink+0x1b0>
    80005c12:	00003597          	auipc	a1,0x3
    80005c16:	bc658593          	addi	a1,a1,-1082 # 800087d8 <syscalls+0x2d0>
    80005c1a:	fb040513          	addi	a0,s0,-80
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	6c4080e7          	jalr	1732(ra) # 800042e2 <namecmp>
    80005c26:	12050e63          	beqz	a0,80005d62 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c2a:	f2c40613          	addi	a2,s0,-212
    80005c2e:	fb040593          	addi	a1,s0,-80
    80005c32:	8526                	mv	a0,s1
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	6c8080e7          	jalr	1736(ra) # 800042fc <dirlookup>
    80005c3c:	892a                	mv	s2,a0
    80005c3e:	12050263          	beqz	a0,80005d62 <sys_unlink+0x1b0>
  ilock(ip);
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	1d6080e7          	jalr	470(ra) # 80003e18 <ilock>
  if(ip->nlink < 1)
    80005c4a:	04a91783          	lh	a5,74(s2)
    80005c4e:	08f05263          	blez	a5,80005cd2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c52:	04491703          	lh	a4,68(s2)
    80005c56:	4785                	li	a5,1
    80005c58:	08f70563          	beq	a4,a5,80005ce2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c5c:	4641                	li	a2,16
    80005c5e:	4581                	li	a1,0
    80005c60:	fc040513          	addi	a0,s0,-64
    80005c64:	ffffb097          	auipc	ra,0xffffb
    80005c68:	07c080e7          	jalr	124(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c6c:	4741                	li	a4,16
    80005c6e:	f2c42683          	lw	a3,-212(s0)
    80005c72:	fc040613          	addi	a2,s0,-64
    80005c76:	4581                	li	a1,0
    80005c78:	8526                	mv	a0,s1
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	54a080e7          	jalr	1354(ra) # 800041c4 <writei>
    80005c82:	47c1                	li	a5,16
    80005c84:	0af51563          	bne	a0,a5,80005d2e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c88:	04491703          	lh	a4,68(s2)
    80005c8c:	4785                	li	a5,1
    80005c8e:	0af70863          	beq	a4,a5,80005d3e <sys_unlink+0x18c>
  iunlockput(dp);
    80005c92:	8526                	mv	a0,s1
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	3e6080e7          	jalr	998(ra) # 8000407a <iunlockput>
  ip->nlink--;
    80005c9c:	04a95783          	lhu	a5,74(s2)
    80005ca0:	37fd                	addiw	a5,a5,-1
    80005ca2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ca6:	854a                	mv	a0,s2
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	0a6080e7          	jalr	166(ra) # 80003d4e <iupdate>
  iunlockput(ip);
    80005cb0:	854a                	mv	a0,s2
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	3c8080e7          	jalr	968(ra) # 8000407a <iunlockput>
  end_op();
    80005cba:	fffff097          	auipc	ra,0xfffff
    80005cbe:	bb0080e7          	jalr	-1104(ra) # 8000486a <end_op>
  return 0;
    80005cc2:	4501                	li	a0,0
    80005cc4:	a84d                	j	80005d76 <sys_unlink+0x1c4>
    end_op();
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	ba4080e7          	jalr	-1116(ra) # 8000486a <end_op>
    return -1;
    80005cce:	557d                	li	a0,-1
    80005cd0:	a05d                	j	80005d76 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005cd2:	00003517          	auipc	a0,0x3
    80005cd6:	b2e50513          	addi	a0,a0,-1234 # 80008800 <syscalls+0x2f8>
    80005cda:	ffffb097          	auipc	ra,0xffffb
    80005cde:	864080e7          	jalr	-1948(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ce2:	04c92703          	lw	a4,76(s2)
    80005ce6:	02000793          	li	a5,32
    80005cea:	f6e7f9e3          	bgeu	a5,a4,80005c5c <sys_unlink+0xaa>
    80005cee:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cf2:	4741                	li	a4,16
    80005cf4:	86ce                	mv	a3,s3
    80005cf6:	f1840613          	addi	a2,s0,-232
    80005cfa:	4581                	li	a1,0
    80005cfc:	854a                	mv	a0,s2
    80005cfe:	ffffe097          	auipc	ra,0xffffe
    80005d02:	3ce080e7          	jalr	974(ra) # 800040cc <readi>
    80005d06:	47c1                	li	a5,16
    80005d08:	00f51b63          	bne	a0,a5,80005d1e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d0c:	f1845783          	lhu	a5,-232(s0)
    80005d10:	e7a1                	bnez	a5,80005d58 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d12:	29c1                	addiw	s3,s3,16
    80005d14:	04c92783          	lw	a5,76(s2)
    80005d18:	fcf9ede3          	bltu	s3,a5,80005cf2 <sys_unlink+0x140>
    80005d1c:	b781                	j	80005c5c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d1e:	00003517          	auipc	a0,0x3
    80005d22:	afa50513          	addi	a0,a0,-1286 # 80008818 <syscalls+0x310>
    80005d26:	ffffb097          	auipc	ra,0xffffb
    80005d2a:	818080e7          	jalr	-2024(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d2e:	00003517          	auipc	a0,0x3
    80005d32:	b0250513          	addi	a0,a0,-1278 # 80008830 <syscalls+0x328>
    80005d36:	ffffb097          	auipc	ra,0xffffb
    80005d3a:	808080e7          	jalr	-2040(ra) # 8000053e <panic>
    dp->nlink--;
    80005d3e:	04a4d783          	lhu	a5,74(s1)
    80005d42:	37fd                	addiw	a5,a5,-1
    80005d44:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d48:	8526                	mv	a0,s1
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	004080e7          	jalr	4(ra) # 80003d4e <iupdate>
    80005d52:	b781                	j	80005c92 <sys_unlink+0xe0>
    return -1;
    80005d54:	557d                	li	a0,-1
    80005d56:	a005                	j	80005d76 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d58:	854a                	mv	a0,s2
    80005d5a:	ffffe097          	auipc	ra,0xffffe
    80005d5e:	320080e7          	jalr	800(ra) # 8000407a <iunlockput>
  iunlockput(dp);
    80005d62:	8526                	mv	a0,s1
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	316080e7          	jalr	790(ra) # 8000407a <iunlockput>
  end_op();
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	afe080e7          	jalr	-1282(ra) # 8000486a <end_op>
  return -1;
    80005d74:	557d                	li	a0,-1
}
    80005d76:	70ae                	ld	ra,232(sp)
    80005d78:	740e                	ld	s0,224(sp)
    80005d7a:	64ee                	ld	s1,216(sp)
    80005d7c:	694e                	ld	s2,208(sp)
    80005d7e:	69ae                	ld	s3,200(sp)
    80005d80:	616d                	addi	sp,sp,240
    80005d82:	8082                	ret

0000000080005d84 <sys_open>:

uint64
sys_open(void)
{
    80005d84:	7131                	addi	sp,sp,-192
    80005d86:	fd06                	sd	ra,184(sp)
    80005d88:	f922                	sd	s0,176(sp)
    80005d8a:	f526                	sd	s1,168(sp)
    80005d8c:	f14a                	sd	s2,160(sp)
    80005d8e:	ed4e                	sd	s3,152(sp)
    80005d90:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d92:	08000613          	li	a2,128
    80005d96:	f5040593          	addi	a1,s0,-176
    80005d9a:	4501                	li	a0,0
    80005d9c:	ffffd097          	auipc	ra,0xffffd
    80005da0:	4ec080e7          	jalr	1260(ra) # 80003288 <argstr>
    return -1;
    80005da4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005da6:	0c054163          	bltz	a0,80005e68 <sys_open+0xe4>
    80005daa:	f4c40593          	addi	a1,s0,-180
    80005dae:	4505                	li	a0,1
    80005db0:	ffffd097          	auipc	ra,0xffffd
    80005db4:	494080e7          	jalr	1172(ra) # 80003244 <argint>
    80005db8:	0a054863          	bltz	a0,80005e68 <sys_open+0xe4>

  begin_op();
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	a2e080e7          	jalr	-1490(ra) # 800047ea <begin_op>

  if(omode & O_CREATE){
    80005dc4:	f4c42783          	lw	a5,-180(s0)
    80005dc8:	2007f793          	andi	a5,a5,512
    80005dcc:	cbdd                	beqz	a5,80005e82 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005dce:	4681                	li	a3,0
    80005dd0:	4601                	li	a2,0
    80005dd2:	4589                	li	a1,2
    80005dd4:	f5040513          	addi	a0,s0,-176
    80005dd8:	00000097          	auipc	ra,0x0
    80005ddc:	972080e7          	jalr	-1678(ra) # 8000574a <create>
    80005de0:	892a                	mv	s2,a0
    if(ip == 0){
    80005de2:	c959                	beqz	a0,80005e78 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005de4:	04491703          	lh	a4,68(s2)
    80005de8:	478d                	li	a5,3
    80005dea:	00f71763          	bne	a4,a5,80005df8 <sys_open+0x74>
    80005dee:	04695703          	lhu	a4,70(s2)
    80005df2:	47a5                	li	a5,9
    80005df4:	0ce7ec63          	bltu	a5,a4,80005ecc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	e02080e7          	jalr	-510(ra) # 80004bfa <filealloc>
    80005e00:	89aa                	mv	s3,a0
    80005e02:	10050263          	beqz	a0,80005f06 <sys_open+0x182>
    80005e06:	00000097          	auipc	ra,0x0
    80005e0a:	902080e7          	jalr	-1790(ra) # 80005708 <fdalloc>
    80005e0e:	84aa                	mv	s1,a0
    80005e10:	0e054663          	bltz	a0,80005efc <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e14:	04491703          	lh	a4,68(s2)
    80005e18:	478d                	li	a5,3
    80005e1a:	0cf70463          	beq	a4,a5,80005ee2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e1e:	4789                	li	a5,2
    80005e20:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e24:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e28:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e2c:	f4c42783          	lw	a5,-180(s0)
    80005e30:	0017c713          	xori	a4,a5,1
    80005e34:	8b05                	andi	a4,a4,1
    80005e36:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e3a:	0037f713          	andi	a4,a5,3
    80005e3e:	00e03733          	snez	a4,a4
    80005e42:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e46:	4007f793          	andi	a5,a5,1024
    80005e4a:	c791                	beqz	a5,80005e56 <sys_open+0xd2>
    80005e4c:	04491703          	lh	a4,68(s2)
    80005e50:	4789                	li	a5,2
    80005e52:	08f70f63          	beq	a4,a5,80005ef0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e56:	854a                	mv	a0,s2
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	082080e7          	jalr	130(ra) # 80003eda <iunlock>
  end_op();
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	a0a080e7          	jalr	-1526(ra) # 8000486a <end_op>

  return fd;
}
    80005e68:	8526                	mv	a0,s1
    80005e6a:	70ea                	ld	ra,184(sp)
    80005e6c:	744a                	ld	s0,176(sp)
    80005e6e:	74aa                	ld	s1,168(sp)
    80005e70:	790a                	ld	s2,160(sp)
    80005e72:	69ea                	ld	s3,152(sp)
    80005e74:	6129                	addi	sp,sp,192
    80005e76:	8082                	ret
      end_op();
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	9f2080e7          	jalr	-1550(ra) # 8000486a <end_op>
      return -1;
    80005e80:	b7e5                	j	80005e68 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e82:	f5040513          	addi	a0,s0,-176
    80005e86:	ffffe097          	auipc	ra,0xffffe
    80005e8a:	748080e7          	jalr	1864(ra) # 800045ce <namei>
    80005e8e:	892a                	mv	s2,a0
    80005e90:	c905                	beqz	a0,80005ec0 <sys_open+0x13c>
    ilock(ip);
    80005e92:	ffffe097          	auipc	ra,0xffffe
    80005e96:	f86080e7          	jalr	-122(ra) # 80003e18 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e9a:	04491703          	lh	a4,68(s2)
    80005e9e:	4785                	li	a5,1
    80005ea0:	f4f712e3          	bne	a4,a5,80005de4 <sys_open+0x60>
    80005ea4:	f4c42783          	lw	a5,-180(s0)
    80005ea8:	dba1                	beqz	a5,80005df8 <sys_open+0x74>
      iunlockput(ip);
    80005eaa:	854a                	mv	a0,s2
    80005eac:	ffffe097          	auipc	ra,0xffffe
    80005eb0:	1ce080e7          	jalr	462(ra) # 8000407a <iunlockput>
      end_op();
    80005eb4:	fffff097          	auipc	ra,0xfffff
    80005eb8:	9b6080e7          	jalr	-1610(ra) # 8000486a <end_op>
      return -1;
    80005ebc:	54fd                	li	s1,-1
    80005ebe:	b76d                	j	80005e68 <sys_open+0xe4>
      end_op();
    80005ec0:	fffff097          	auipc	ra,0xfffff
    80005ec4:	9aa080e7          	jalr	-1622(ra) # 8000486a <end_op>
      return -1;
    80005ec8:	54fd                	li	s1,-1
    80005eca:	bf79                	j	80005e68 <sys_open+0xe4>
    iunlockput(ip);
    80005ecc:	854a                	mv	a0,s2
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	1ac080e7          	jalr	428(ra) # 8000407a <iunlockput>
    end_op();
    80005ed6:	fffff097          	auipc	ra,0xfffff
    80005eda:	994080e7          	jalr	-1644(ra) # 8000486a <end_op>
    return -1;
    80005ede:	54fd                	li	s1,-1
    80005ee0:	b761                	j	80005e68 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ee2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ee6:	04691783          	lh	a5,70(s2)
    80005eea:	02f99223          	sh	a5,36(s3)
    80005eee:	bf2d                	j	80005e28 <sys_open+0xa4>
    itrunc(ip);
    80005ef0:	854a                	mv	a0,s2
    80005ef2:	ffffe097          	auipc	ra,0xffffe
    80005ef6:	034080e7          	jalr	52(ra) # 80003f26 <itrunc>
    80005efa:	bfb1                	j	80005e56 <sys_open+0xd2>
      fileclose(f);
    80005efc:	854e                	mv	a0,s3
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	db8080e7          	jalr	-584(ra) # 80004cb6 <fileclose>
    iunlockput(ip);
    80005f06:	854a                	mv	a0,s2
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	172080e7          	jalr	370(ra) # 8000407a <iunlockput>
    end_op();
    80005f10:	fffff097          	auipc	ra,0xfffff
    80005f14:	95a080e7          	jalr	-1702(ra) # 8000486a <end_op>
    return -1;
    80005f18:	54fd                	li	s1,-1
    80005f1a:	b7b9                	j	80005e68 <sys_open+0xe4>

0000000080005f1c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f1c:	7175                	addi	sp,sp,-144
    80005f1e:	e506                	sd	ra,136(sp)
    80005f20:	e122                	sd	s0,128(sp)
    80005f22:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f24:	fffff097          	auipc	ra,0xfffff
    80005f28:	8c6080e7          	jalr	-1850(ra) # 800047ea <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f2c:	08000613          	li	a2,128
    80005f30:	f7040593          	addi	a1,s0,-144
    80005f34:	4501                	li	a0,0
    80005f36:	ffffd097          	auipc	ra,0xffffd
    80005f3a:	352080e7          	jalr	850(ra) # 80003288 <argstr>
    80005f3e:	02054963          	bltz	a0,80005f70 <sys_mkdir+0x54>
    80005f42:	4681                	li	a3,0
    80005f44:	4601                	li	a2,0
    80005f46:	4585                	li	a1,1
    80005f48:	f7040513          	addi	a0,s0,-144
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	7fe080e7          	jalr	2046(ra) # 8000574a <create>
    80005f54:	cd11                	beqz	a0,80005f70 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f56:	ffffe097          	auipc	ra,0xffffe
    80005f5a:	124080e7          	jalr	292(ra) # 8000407a <iunlockput>
  end_op();
    80005f5e:	fffff097          	auipc	ra,0xfffff
    80005f62:	90c080e7          	jalr	-1780(ra) # 8000486a <end_op>
  return 0;
    80005f66:	4501                	li	a0,0
}
    80005f68:	60aa                	ld	ra,136(sp)
    80005f6a:	640a                	ld	s0,128(sp)
    80005f6c:	6149                	addi	sp,sp,144
    80005f6e:	8082                	ret
    end_op();
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	8fa080e7          	jalr	-1798(ra) # 8000486a <end_op>
    return -1;
    80005f78:	557d                	li	a0,-1
    80005f7a:	b7fd                	j	80005f68 <sys_mkdir+0x4c>

0000000080005f7c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f7c:	7135                	addi	sp,sp,-160
    80005f7e:	ed06                	sd	ra,152(sp)
    80005f80:	e922                	sd	s0,144(sp)
    80005f82:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	866080e7          	jalr	-1946(ra) # 800047ea <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f8c:	08000613          	li	a2,128
    80005f90:	f7040593          	addi	a1,s0,-144
    80005f94:	4501                	li	a0,0
    80005f96:	ffffd097          	auipc	ra,0xffffd
    80005f9a:	2f2080e7          	jalr	754(ra) # 80003288 <argstr>
    80005f9e:	04054a63          	bltz	a0,80005ff2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005fa2:	f6c40593          	addi	a1,s0,-148
    80005fa6:	4505                	li	a0,1
    80005fa8:	ffffd097          	auipc	ra,0xffffd
    80005fac:	29c080e7          	jalr	668(ra) # 80003244 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fb0:	04054163          	bltz	a0,80005ff2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005fb4:	f6840593          	addi	a1,s0,-152
    80005fb8:	4509                	li	a0,2
    80005fba:	ffffd097          	auipc	ra,0xffffd
    80005fbe:	28a080e7          	jalr	650(ra) # 80003244 <argint>
     argint(1, &major) < 0 ||
    80005fc2:	02054863          	bltz	a0,80005ff2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005fc6:	f6841683          	lh	a3,-152(s0)
    80005fca:	f6c41603          	lh	a2,-148(s0)
    80005fce:	458d                	li	a1,3
    80005fd0:	f7040513          	addi	a0,s0,-144
    80005fd4:	fffff097          	auipc	ra,0xfffff
    80005fd8:	776080e7          	jalr	1910(ra) # 8000574a <create>
     argint(2, &minor) < 0 ||
    80005fdc:	c919                	beqz	a0,80005ff2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005fde:	ffffe097          	auipc	ra,0xffffe
    80005fe2:	09c080e7          	jalr	156(ra) # 8000407a <iunlockput>
  end_op();
    80005fe6:	fffff097          	auipc	ra,0xfffff
    80005fea:	884080e7          	jalr	-1916(ra) # 8000486a <end_op>
  return 0;
    80005fee:	4501                	li	a0,0
    80005ff0:	a031                	j	80005ffc <sys_mknod+0x80>
    end_op();
    80005ff2:	fffff097          	auipc	ra,0xfffff
    80005ff6:	878080e7          	jalr	-1928(ra) # 8000486a <end_op>
    return -1;
    80005ffa:	557d                	li	a0,-1
}
    80005ffc:	60ea                	ld	ra,152(sp)
    80005ffe:	644a                	ld	s0,144(sp)
    80006000:	610d                	addi	sp,sp,160
    80006002:	8082                	ret

0000000080006004 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006004:	7135                	addi	sp,sp,-160
    80006006:	ed06                	sd	ra,152(sp)
    80006008:	e922                	sd	s0,144(sp)
    8000600a:	e526                	sd	s1,136(sp)
    8000600c:	e14a                	sd	s2,128(sp)
    8000600e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006010:	ffffc097          	auipc	ra,0xffffc
    80006014:	be6080e7          	jalr	-1050(ra) # 80001bf6 <myproc>
    80006018:	892a                	mv	s2,a0
  
  begin_op();
    8000601a:	ffffe097          	auipc	ra,0xffffe
    8000601e:	7d0080e7          	jalr	2000(ra) # 800047ea <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006022:	08000613          	li	a2,128
    80006026:	f6040593          	addi	a1,s0,-160
    8000602a:	4501                	li	a0,0
    8000602c:	ffffd097          	auipc	ra,0xffffd
    80006030:	25c080e7          	jalr	604(ra) # 80003288 <argstr>
    80006034:	04054b63          	bltz	a0,8000608a <sys_chdir+0x86>
    80006038:	f6040513          	addi	a0,s0,-160
    8000603c:	ffffe097          	auipc	ra,0xffffe
    80006040:	592080e7          	jalr	1426(ra) # 800045ce <namei>
    80006044:	84aa                	mv	s1,a0
    80006046:	c131                	beqz	a0,8000608a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006048:	ffffe097          	auipc	ra,0xffffe
    8000604c:	dd0080e7          	jalr	-560(ra) # 80003e18 <ilock>
  if(ip->type != T_DIR){
    80006050:	04449703          	lh	a4,68(s1)
    80006054:	4785                	li	a5,1
    80006056:	04f71063          	bne	a4,a5,80006096 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000605a:	8526                	mv	a0,s1
    8000605c:	ffffe097          	auipc	ra,0xffffe
    80006060:	e7e080e7          	jalr	-386(ra) # 80003eda <iunlock>
  iput(p->cwd);
    80006064:	17093503          	ld	a0,368(s2)
    80006068:	ffffe097          	auipc	ra,0xffffe
    8000606c:	f6a080e7          	jalr	-150(ra) # 80003fd2 <iput>
  end_op();
    80006070:	ffffe097          	auipc	ra,0xffffe
    80006074:	7fa080e7          	jalr	2042(ra) # 8000486a <end_op>
  p->cwd = ip;
    80006078:	16993823          	sd	s1,368(s2)
  return 0;
    8000607c:	4501                	li	a0,0
}
    8000607e:	60ea                	ld	ra,152(sp)
    80006080:	644a                	ld	s0,144(sp)
    80006082:	64aa                	ld	s1,136(sp)
    80006084:	690a                	ld	s2,128(sp)
    80006086:	610d                	addi	sp,sp,160
    80006088:	8082                	ret
    end_op();
    8000608a:	ffffe097          	auipc	ra,0xffffe
    8000608e:	7e0080e7          	jalr	2016(ra) # 8000486a <end_op>
    return -1;
    80006092:	557d                	li	a0,-1
    80006094:	b7ed                	j	8000607e <sys_chdir+0x7a>
    iunlockput(ip);
    80006096:	8526                	mv	a0,s1
    80006098:	ffffe097          	auipc	ra,0xffffe
    8000609c:	fe2080e7          	jalr	-30(ra) # 8000407a <iunlockput>
    end_op();
    800060a0:	ffffe097          	auipc	ra,0xffffe
    800060a4:	7ca080e7          	jalr	1994(ra) # 8000486a <end_op>
    return -1;
    800060a8:	557d                	li	a0,-1
    800060aa:	bfd1                	j	8000607e <sys_chdir+0x7a>

00000000800060ac <sys_exec>:

uint64
sys_exec(void)
{
    800060ac:	7145                	addi	sp,sp,-464
    800060ae:	e786                	sd	ra,456(sp)
    800060b0:	e3a2                	sd	s0,448(sp)
    800060b2:	ff26                	sd	s1,440(sp)
    800060b4:	fb4a                	sd	s2,432(sp)
    800060b6:	f74e                	sd	s3,424(sp)
    800060b8:	f352                	sd	s4,416(sp)
    800060ba:	ef56                	sd	s5,408(sp)
    800060bc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060be:	08000613          	li	a2,128
    800060c2:	f4040593          	addi	a1,s0,-192
    800060c6:	4501                	li	a0,0
    800060c8:	ffffd097          	auipc	ra,0xffffd
    800060cc:	1c0080e7          	jalr	448(ra) # 80003288 <argstr>
    return -1;
    800060d0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060d2:	0c054a63          	bltz	a0,800061a6 <sys_exec+0xfa>
    800060d6:	e3840593          	addi	a1,s0,-456
    800060da:	4505                	li	a0,1
    800060dc:	ffffd097          	auipc	ra,0xffffd
    800060e0:	18a080e7          	jalr	394(ra) # 80003266 <argaddr>
    800060e4:	0c054163          	bltz	a0,800061a6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060e8:	10000613          	li	a2,256
    800060ec:	4581                	li	a1,0
    800060ee:	e4040513          	addi	a0,s0,-448
    800060f2:	ffffb097          	auipc	ra,0xffffb
    800060f6:	bee080e7          	jalr	-1042(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060fa:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060fe:	89a6                	mv	s3,s1
    80006100:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006102:	02000a13          	li	s4,32
    80006106:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000610a:	00391513          	slli	a0,s2,0x3
    8000610e:	e3040593          	addi	a1,s0,-464
    80006112:	e3843783          	ld	a5,-456(s0)
    80006116:	953e                	add	a0,a0,a5
    80006118:	ffffd097          	auipc	ra,0xffffd
    8000611c:	092080e7          	jalr	146(ra) # 800031aa <fetchaddr>
    80006120:	02054a63          	bltz	a0,80006154 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006124:	e3043783          	ld	a5,-464(s0)
    80006128:	c3b9                	beqz	a5,8000616e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000612a:	ffffb097          	auipc	ra,0xffffb
    8000612e:	9ca080e7          	jalr	-1590(ra) # 80000af4 <kalloc>
    80006132:	85aa                	mv	a1,a0
    80006134:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006138:	cd11                	beqz	a0,80006154 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000613a:	6605                	lui	a2,0x1
    8000613c:	e3043503          	ld	a0,-464(s0)
    80006140:	ffffd097          	auipc	ra,0xffffd
    80006144:	0bc080e7          	jalr	188(ra) # 800031fc <fetchstr>
    80006148:	00054663          	bltz	a0,80006154 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000614c:	0905                	addi	s2,s2,1
    8000614e:	09a1                	addi	s3,s3,8
    80006150:	fb491be3          	bne	s2,s4,80006106 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006154:	10048913          	addi	s2,s1,256
    80006158:	6088                	ld	a0,0(s1)
    8000615a:	c529                	beqz	a0,800061a4 <sys_exec+0xf8>
    kfree(argv[i]);
    8000615c:	ffffb097          	auipc	ra,0xffffb
    80006160:	89c080e7          	jalr	-1892(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006164:	04a1                	addi	s1,s1,8
    80006166:	ff2499e3          	bne	s1,s2,80006158 <sys_exec+0xac>
  return -1;
    8000616a:	597d                	li	s2,-1
    8000616c:	a82d                	j	800061a6 <sys_exec+0xfa>
      argv[i] = 0;
    8000616e:	0a8e                	slli	s5,s5,0x3
    80006170:	fc040793          	addi	a5,s0,-64
    80006174:	9abe                	add	s5,s5,a5
    80006176:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000617a:	e4040593          	addi	a1,s0,-448
    8000617e:	f4040513          	addi	a0,s0,-192
    80006182:	fffff097          	auipc	ra,0xfffff
    80006186:	194080e7          	jalr	404(ra) # 80005316 <exec>
    8000618a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000618c:	10048993          	addi	s3,s1,256
    80006190:	6088                	ld	a0,0(s1)
    80006192:	c911                	beqz	a0,800061a6 <sys_exec+0xfa>
    kfree(argv[i]);
    80006194:	ffffb097          	auipc	ra,0xffffb
    80006198:	864080e7          	jalr	-1948(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000619c:	04a1                	addi	s1,s1,8
    8000619e:	ff3499e3          	bne	s1,s3,80006190 <sys_exec+0xe4>
    800061a2:	a011                	j	800061a6 <sys_exec+0xfa>
  return -1;
    800061a4:	597d                	li	s2,-1
}
    800061a6:	854a                	mv	a0,s2
    800061a8:	60be                	ld	ra,456(sp)
    800061aa:	641e                	ld	s0,448(sp)
    800061ac:	74fa                	ld	s1,440(sp)
    800061ae:	795a                	ld	s2,432(sp)
    800061b0:	79ba                	ld	s3,424(sp)
    800061b2:	7a1a                	ld	s4,416(sp)
    800061b4:	6afa                	ld	s5,408(sp)
    800061b6:	6179                	addi	sp,sp,464
    800061b8:	8082                	ret

00000000800061ba <sys_pipe>:

uint64
sys_pipe(void)
{
    800061ba:	7139                	addi	sp,sp,-64
    800061bc:	fc06                	sd	ra,56(sp)
    800061be:	f822                	sd	s0,48(sp)
    800061c0:	f426                	sd	s1,40(sp)
    800061c2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061c4:	ffffc097          	auipc	ra,0xffffc
    800061c8:	a32080e7          	jalr	-1486(ra) # 80001bf6 <myproc>
    800061cc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800061ce:	fd840593          	addi	a1,s0,-40
    800061d2:	4501                	li	a0,0
    800061d4:	ffffd097          	auipc	ra,0xffffd
    800061d8:	092080e7          	jalr	146(ra) # 80003266 <argaddr>
    return -1;
    800061dc:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800061de:	0e054063          	bltz	a0,800062be <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800061e2:	fc840593          	addi	a1,s0,-56
    800061e6:	fd040513          	addi	a0,s0,-48
    800061ea:	fffff097          	auipc	ra,0xfffff
    800061ee:	dfc080e7          	jalr	-516(ra) # 80004fe6 <pipealloc>
    return -1;
    800061f2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061f4:	0c054563          	bltz	a0,800062be <sys_pipe+0x104>
  fd0 = -1;
    800061f8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061fc:	fd043503          	ld	a0,-48(s0)
    80006200:	fffff097          	auipc	ra,0xfffff
    80006204:	508080e7          	jalr	1288(ra) # 80005708 <fdalloc>
    80006208:	fca42223          	sw	a0,-60(s0)
    8000620c:	08054c63          	bltz	a0,800062a4 <sys_pipe+0xea>
    80006210:	fc843503          	ld	a0,-56(s0)
    80006214:	fffff097          	auipc	ra,0xfffff
    80006218:	4f4080e7          	jalr	1268(ra) # 80005708 <fdalloc>
    8000621c:	fca42023          	sw	a0,-64(s0)
    80006220:	06054863          	bltz	a0,80006290 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006224:	4691                	li	a3,4
    80006226:	fc440613          	addi	a2,s0,-60
    8000622a:	fd843583          	ld	a1,-40(s0)
    8000622e:	78a8                	ld	a0,112(s1)
    80006230:	ffffb097          	auipc	ra,0xffffb
    80006234:	566080e7          	jalr	1382(ra) # 80001796 <copyout>
    80006238:	02054063          	bltz	a0,80006258 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000623c:	4691                	li	a3,4
    8000623e:	fc040613          	addi	a2,s0,-64
    80006242:	fd843583          	ld	a1,-40(s0)
    80006246:	0591                	addi	a1,a1,4
    80006248:	78a8                	ld	a0,112(s1)
    8000624a:	ffffb097          	auipc	ra,0xffffb
    8000624e:	54c080e7          	jalr	1356(ra) # 80001796 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006252:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006254:	06055563          	bgez	a0,800062be <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006258:	fc442783          	lw	a5,-60(s0)
    8000625c:	07f9                	addi	a5,a5,30
    8000625e:	078e                	slli	a5,a5,0x3
    80006260:	97a6                	add	a5,a5,s1
    80006262:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006266:	fc042503          	lw	a0,-64(s0)
    8000626a:	0579                	addi	a0,a0,30
    8000626c:	050e                	slli	a0,a0,0x3
    8000626e:	9526                	add	a0,a0,s1
    80006270:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006274:	fd043503          	ld	a0,-48(s0)
    80006278:	fffff097          	auipc	ra,0xfffff
    8000627c:	a3e080e7          	jalr	-1474(ra) # 80004cb6 <fileclose>
    fileclose(wf);
    80006280:	fc843503          	ld	a0,-56(s0)
    80006284:	fffff097          	auipc	ra,0xfffff
    80006288:	a32080e7          	jalr	-1486(ra) # 80004cb6 <fileclose>
    return -1;
    8000628c:	57fd                	li	a5,-1
    8000628e:	a805                	j	800062be <sys_pipe+0x104>
    if(fd0 >= 0)
    80006290:	fc442783          	lw	a5,-60(s0)
    80006294:	0007c863          	bltz	a5,800062a4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006298:	01e78513          	addi	a0,a5,30
    8000629c:	050e                	slli	a0,a0,0x3
    8000629e:	9526                	add	a0,a0,s1
    800062a0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062a4:	fd043503          	ld	a0,-48(s0)
    800062a8:	fffff097          	auipc	ra,0xfffff
    800062ac:	a0e080e7          	jalr	-1522(ra) # 80004cb6 <fileclose>
    fileclose(wf);
    800062b0:	fc843503          	ld	a0,-56(s0)
    800062b4:	fffff097          	auipc	ra,0xfffff
    800062b8:	a02080e7          	jalr	-1534(ra) # 80004cb6 <fileclose>
    return -1;
    800062bc:	57fd                	li	a5,-1
}
    800062be:	853e                	mv	a0,a5
    800062c0:	70e2                	ld	ra,56(sp)
    800062c2:	7442                	ld	s0,48(sp)
    800062c4:	74a2                	ld	s1,40(sp)
    800062c6:	6121                	addi	sp,sp,64
    800062c8:	8082                	ret
    800062ca:	0000                	unimp
    800062cc:	0000                	unimp
	...

00000000800062d0 <kernelvec>:
    800062d0:	7111                	addi	sp,sp,-256
    800062d2:	e006                	sd	ra,0(sp)
    800062d4:	e40a                	sd	sp,8(sp)
    800062d6:	e80e                	sd	gp,16(sp)
    800062d8:	ec12                	sd	tp,24(sp)
    800062da:	f016                	sd	t0,32(sp)
    800062dc:	f41a                	sd	t1,40(sp)
    800062de:	f81e                	sd	t2,48(sp)
    800062e0:	fc22                	sd	s0,56(sp)
    800062e2:	e0a6                	sd	s1,64(sp)
    800062e4:	e4aa                	sd	a0,72(sp)
    800062e6:	e8ae                	sd	a1,80(sp)
    800062e8:	ecb2                	sd	a2,88(sp)
    800062ea:	f0b6                	sd	a3,96(sp)
    800062ec:	f4ba                	sd	a4,104(sp)
    800062ee:	f8be                	sd	a5,112(sp)
    800062f0:	fcc2                	sd	a6,120(sp)
    800062f2:	e146                	sd	a7,128(sp)
    800062f4:	e54a                	sd	s2,136(sp)
    800062f6:	e94e                	sd	s3,144(sp)
    800062f8:	ed52                	sd	s4,152(sp)
    800062fa:	f156                	sd	s5,160(sp)
    800062fc:	f55a                	sd	s6,168(sp)
    800062fe:	f95e                	sd	s7,176(sp)
    80006300:	fd62                	sd	s8,184(sp)
    80006302:	e1e6                	sd	s9,192(sp)
    80006304:	e5ea                	sd	s10,200(sp)
    80006306:	e9ee                	sd	s11,208(sp)
    80006308:	edf2                	sd	t3,216(sp)
    8000630a:	f1f6                	sd	t4,224(sp)
    8000630c:	f5fa                	sd	t5,232(sp)
    8000630e:	f9fe                	sd	t6,240(sp)
    80006310:	d67fc0ef          	jal	ra,80003076 <kerneltrap>
    80006314:	6082                	ld	ra,0(sp)
    80006316:	6122                	ld	sp,8(sp)
    80006318:	61c2                	ld	gp,16(sp)
    8000631a:	7282                	ld	t0,32(sp)
    8000631c:	7322                	ld	t1,40(sp)
    8000631e:	73c2                	ld	t2,48(sp)
    80006320:	7462                	ld	s0,56(sp)
    80006322:	6486                	ld	s1,64(sp)
    80006324:	6526                	ld	a0,72(sp)
    80006326:	65c6                	ld	a1,80(sp)
    80006328:	6666                	ld	a2,88(sp)
    8000632a:	7686                	ld	a3,96(sp)
    8000632c:	7726                	ld	a4,104(sp)
    8000632e:	77c6                	ld	a5,112(sp)
    80006330:	7866                	ld	a6,120(sp)
    80006332:	688a                	ld	a7,128(sp)
    80006334:	692a                	ld	s2,136(sp)
    80006336:	69ca                	ld	s3,144(sp)
    80006338:	6a6a                	ld	s4,152(sp)
    8000633a:	7a8a                	ld	s5,160(sp)
    8000633c:	7b2a                	ld	s6,168(sp)
    8000633e:	7bca                	ld	s7,176(sp)
    80006340:	7c6a                	ld	s8,184(sp)
    80006342:	6c8e                	ld	s9,192(sp)
    80006344:	6d2e                	ld	s10,200(sp)
    80006346:	6dce                	ld	s11,208(sp)
    80006348:	6e6e                	ld	t3,216(sp)
    8000634a:	7e8e                	ld	t4,224(sp)
    8000634c:	7f2e                	ld	t5,232(sp)
    8000634e:	7fce                	ld	t6,240(sp)
    80006350:	6111                	addi	sp,sp,256
    80006352:	10200073          	sret
    80006356:	00000013          	nop
    8000635a:	00000013          	nop
    8000635e:	0001                	nop

0000000080006360 <timervec>:
    80006360:	34051573          	csrrw	a0,mscratch,a0
    80006364:	e10c                	sd	a1,0(a0)
    80006366:	e510                	sd	a2,8(a0)
    80006368:	e914                	sd	a3,16(a0)
    8000636a:	6d0c                	ld	a1,24(a0)
    8000636c:	7110                	ld	a2,32(a0)
    8000636e:	6194                	ld	a3,0(a1)
    80006370:	96b2                	add	a3,a3,a2
    80006372:	e194                	sd	a3,0(a1)
    80006374:	4589                	li	a1,2
    80006376:	14459073          	csrw	sip,a1
    8000637a:	6914                	ld	a3,16(a0)
    8000637c:	6510                	ld	a2,8(a0)
    8000637e:	610c                	ld	a1,0(a0)
    80006380:	34051573          	csrrw	a0,mscratch,a0
    80006384:	30200073          	mret
	...

000000008000638a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000638a:	1141                	addi	sp,sp,-16
    8000638c:	e422                	sd	s0,8(sp)
    8000638e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006390:	0c0007b7          	lui	a5,0xc000
    80006394:	4705                	li	a4,1
    80006396:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006398:	c3d8                	sw	a4,4(a5)
}
    8000639a:	6422                	ld	s0,8(sp)
    8000639c:	0141                	addi	sp,sp,16
    8000639e:	8082                	ret

00000000800063a0 <plicinithart>:

void
plicinithart(void)
{
    800063a0:	1141                	addi	sp,sp,-16
    800063a2:	e406                	sd	ra,8(sp)
    800063a4:	e022                	sd	s0,0(sp)
    800063a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063a8:	ffffc097          	auipc	ra,0xffffc
    800063ac:	822080e7          	jalr	-2014(ra) # 80001bca <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063b0:	0085171b          	slliw	a4,a0,0x8
    800063b4:	0c0027b7          	lui	a5,0xc002
    800063b8:	97ba                	add	a5,a5,a4
    800063ba:	40200713          	li	a4,1026
    800063be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063c2:	00d5151b          	slliw	a0,a0,0xd
    800063c6:	0c2017b7          	lui	a5,0xc201
    800063ca:	953e                	add	a0,a0,a5
    800063cc:	00052023          	sw	zero,0(a0)
}
    800063d0:	60a2                	ld	ra,8(sp)
    800063d2:	6402                	ld	s0,0(sp)
    800063d4:	0141                	addi	sp,sp,16
    800063d6:	8082                	ret

00000000800063d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800063d8:	1141                	addi	sp,sp,-16
    800063da:	e406                	sd	ra,8(sp)
    800063dc:	e022                	sd	s0,0(sp)
    800063de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063e0:	ffffb097          	auipc	ra,0xffffb
    800063e4:	7ea080e7          	jalr	2026(ra) # 80001bca <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063e8:	00d5179b          	slliw	a5,a0,0xd
    800063ec:	0c201537          	lui	a0,0xc201
    800063f0:	953e                	add	a0,a0,a5
  return irq;
}
    800063f2:	4148                	lw	a0,4(a0)
    800063f4:	60a2                	ld	ra,8(sp)
    800063f6:	6402                	ld	s0,0(sp)
    800063f8:	0141                	addi	sp,sp,16
    800063fa:	8082                	ret

00000000800063fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063fc:	1101                	addi	sp,sp,-32
    800063fe:	ec06                	sd	ra,24(sp)
    80006400:	e822                	sd	s0,16(sp)
    80006402:	e426                	sd	s1,8(sp)
    80006404:	1000                	addi	s0,sp,32
    80006406:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006408:	ffffb097          	auipc	ra,0xffffb
    8000640c:	7c2080e7          	jalr	1986(ra) # 80001bca <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006410:	00d5151b          	slliw	a0,a0,0xd
    80006414:	0c2017b7          	lui	a5,0xc201
    80006418:	97aa                	add	a5,a5,a0
    8000641a:	c3c4                	sw	s1,4(a5)
}
    8000641c:	60e2                	ld	ra,24(sp)
    8000641e:	6442                	ld	s0,16(sp)
    80006420:	64a2                	ld	s1,8(sp)
    80006422:	6105                	addi	sp,sp,32
    80006424:	8082                	ret

0000000080006426 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006426:	1141                	addi	sp,sp,-16
    80006428:	e406                	sd	ra,8(sp)
    8000642a:	e022                	sd	s0,0(sp)
    8000642c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000642e:	479d                	li	a5,7
    80006430:	06a7c963          	blt	a5,a0,800064a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006434:	0001d797          	auipc	a5,0x1d
    80006438:	bcc78793          	addi	a5,a5,-1076 # 80023000 <disk>
    8000643c:	00a78733          	add	a4,a5,a0
    80006440:	6789                	lui	a5,0x2
    80006442:	97ba                	add	a5,a5,a4
    80006444:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006448:	e7ad                	bnez	a5,800064b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000644a:	00451793          	slli	a5,a0,0x4
    8000644e:	0001f717          	auipc	a4,0x1f
    80006452:	bb270713          	addi	a4,a4,-1102 # 80025000 <disk+0x2000>
    80006456:	6314                	ld	a3,0(a4)
    80006458:	96be                	add	a3,a3,a5
    8000645a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000645e:	6314                	ld	a3,0(a4)
    80006460:	96be                	add	a3,a3,a5
    80006462:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006466:	6314                	ld	a3,0(a4)
    80006468:	96be                	add	a3,a3,a5
    8000646a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000646e:	6318                	ld	a4,0(a4)
    80006470:	97ba                	add	a5,a5,a4
    80006472:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006476:	0001d797          	auipc	a5,0x1d
    8000647a:	b8a78793          	addi	a5,a5,-1142 # 80023000 <disk>
    8000647e:	97aa                	add	a5,a5,a0
    80006480:	6509                	lui	a0,0x2
    80006482:	953e                	add	a0,a0,a5
    80006484:	4785                	li	a5,1
    80006486:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000648a:	0001f517          	auipc	a0,0x1f
    8000648e:	b8e50513          	addi	a0,a0,-1138 # 80025018 <disk+0x2018>
    80006492:	ffffc097          	auipc	ra,0xffffc
    80006496:	434080e7          	jalr	1076(ra) # 800028c6 <wakeup>
}
    8000649a:	60a2                	ld	ra,8(sp)
    8000649c:	6402                	ld	s0,0(sp)
    8000649e:	0141                	addi	sp,sp,16
    800064a0:	8082                	ret
    panic("free_desc 1");
    800064a2:	00002517          	auipc	a0,0x2
    800064a6:	39e50513          	addi	a0,a0,926 # 80008840 <syscalls+0x338>
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	094080e7          	jalr	148(ra) # 8000053e <panic>
    panic("free_desc 2");
    800064b2:	00002517          	auipc	a0,0x2
    800064b6:	39e50513          	addi	a0,a0,926 # 80008850 <syscalls+0x348>
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	084080e7          	jalr	132(ra) # 8000053e <panic>

00000000800064c2 <virtio_disk_init>:
{
    800064c2:	1101                	addi	sp,sp,-32
    800064c4:	ec06                	sd	ra,24(sp)
    800064c6:	e822                	sd	s0,16(sp)
    800064c8:	e426                	sd	s1,8(sp)
    800064ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064cc:	00002597          	auipc	a1,0x2
    800064d0:	39458593          	addi	a1,a1,916 # 80008860 <syscalls+0x358>
    800064d4:	0001f517          	auipc	a0,0x1f
    800064d8:	c5450513          	addi	a0,a0,-940 # 80025128 <disk+0x2128>
    800064dc:	ffffa097          	auipc	ra,0xffffa
    800064e0:	678080e7          	jalr	1656(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064e4:	100017b7          	lui	a5,0x10001
    800064e8:	4398                	lw	a4,0(a5)
    800064ea:	2701                	sext.w	a4,a4
    800064ec:	747277b7          	lui	a5,0x74727
    800064f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064f4:	0ef71163          	bne	a4,a5,800065d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064f8:	100017b7          	lui	a5,0x10001
    800064fc:	43dc                	lw	a5,4(a5)
    800064fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006500:	4705                	li	a4,1
    80006502:	0ce79a63          	bne	a5,a4,800065d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006506:	100017b7          	lui	a5,0x10001
    8000650a:	479c                	lw	a5,8(a5)
    8000650c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000650e:	4709                	li	a4,2
    80006510:	0ce79363          	bne	a5,a4,800065d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006514:	100017b7          	lui	a5,0x10001
    80006518:	47d8                	lw	a4,12(a5)
    8000651a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000651c:	554d47b7          	lui	a5,0x554d4
    80006520:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006524:	0af71963          	bne	a4,a5,800065d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006528:	100017b7          	lui	a5,0x10001
    8000652c:	4705                	li	a4,1
    8000652e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006530:	470d                	li	a4,3
    80006532:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006534:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006536:	c7ffe737          	lui	a4,0xc7ffe
    8000653a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000653e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006540:	2701                	sext.w	a4,a4
    80006542:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006544:	472d                	li	a4,11
    80006546:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006548:	473d                	li	a4,15
    8000654a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000654c:	6705                	lui	a4,0x1
    8000654e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006550:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006554:	5bdc                	lw	a5,52(a5)
    80006556:	2781                	sext.w	a5,a5
  if(max == 0)
    80006558:	c7d9                	beqz	a5,800065e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000655a:	471d                	li	a4,7
    8000655c:	08f77d63          	bgeu	a4,a5,800065f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006560:	100014b7          	lui	s1,0x10001
    80006564:	47a1                	li	a5,8
    80006566:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006568:	6609                	lui	a2,0x2
    8000656a:	4581                	li	a1,0
    8000656c:	0001d517          	auipc	a0,0x1d
    80006570:	a9450513          	addi	a0,a0,-1388 # 80023000 <disk>
    80006574:	ffffa097          	auipc	ra,0xffffa
    80006578:	76c080e7          	jalr	1900(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000657c:	0001d717          	auipc	a4,0x1d
    80006580:	a8470713          	addi	a4,a4,-1404 # 80023000 <disk>
    80006584:	00c75793          	srli	a5,a4,0xc
    80006588:	2781                	sext.w	a5,a5
    8000658a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000658c:	0001f797          	auipc	a5,0x1f
    80006590:	a7478793          	addi	a5,a5,-1420 # 80025000 <disk+0x2000>
    80006594:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006596:	0001d717          	auipc	a4,0x1d
    8000659a:	aea70713          	addi	a4,a4,-1302 # 80023080 <disk+0x80>
    8000659e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800065a0:	0001e717          	auipc	a4,0x1e
    800065a4:	a6070713          	addi	a4,a4,-1440 # 80024000 <disk+0x1000>
    800065a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800065aa:	4705                	li	a4,1
    800065ac:	00e78c23          	sb	a4,24(a5)
    800065b0:	00e78ca3          	sb	a4,25(a5)
    800065b4:	00e78d23          	sb	a4,26(a5)
    800065b8:	00e78da3          	sb	a4,27(a5)
    800065bc:	00e78e23          	sb	a4,28(a5)
    800065c0:	00e78ea3          	sb	a4,29(a5)
    800065c4:	00e78f23          	sb	a4,30(a5)
    800065c8:	00e78fa3          	sb	a4,31(a5)
}
    800065cc:	60e2                	ld	ra,24(sp)
    800065ce:	6442                	ld	s0,16(sp)
    800065d0:	64a2                	ld	s1,8(sp)
    800065d2:	6105                	addi	sp,sp,32
    800065d4:	8082                	ret
    panic("could not find virtio disk");
    800065d6:	00002517          	auipc	a0,0x2
    800065da:	29a50513          	addi	a0,a0,666 # 80008870 <syscalls+0x368>
    800065de:	ffffa097          	auipc	ra,0xffffa
    800065e2:	f60080e7          	jalr	-160(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800065e6:	00002517          	auipc	a0,0x2
    800065ea:	2aa50513          	addi	a0,a0,682 # 80008890 <syscalls+0x388>
    800065ee:	ffffa097          	auipc	ra,0xffffa
    800065f2:	f50080e7          	jalr	-176(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800065f6:	00002517          	auipc	a0,0x2
    800065fa:	2ba50513          	addi	a0,a0,698 # 800088b0 <syscalls+0x3a8>
    800065fe:	ffffa097          	auipc	ra,0xffffa
    80006602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>

0000000080006606 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006606:	7159                	addi	sp,sp,-112
    80006608:	f486                	sd	ra,104(sp)
    8000660a:	f0a2                	sd	s0,96(sp)
    8000660c:	eca6                	sd	s1,88(sp)
    8000660e:	e8ca                	sd	s2,80(sp)
    80006610:	e4ce                	sd	s3,72(sp)
    80006612:	e0d2                	sd	s4,64(sp)
    80006614:	fc56                	sd	s5,56(sp)
    80006616:	f85a                	sd	s6,48(sp)
    80006618:	f45e                	sd	s7,40(sp)
    8000661a:	f062                	sd	s8,32(sp)
    8000661c:	ec66                	sd	s9,24(sp)
    8000661e:	e86a                	sd	s10,16(sp)
    80006620:	1880                	addi	s0,sp,112
    80006622:	892a                	mv	s2,a0
    80006624:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006626:	00c52c83          	lw	s9,12(a0)
    8000662a:	001c9c9b          	slliw	s9,s9,0x1
    8000662e:	1c82                	slli	s9,s9,0x20
    80006630:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006634:	0001f517          	auipc	a0,0x1f
    80006638:	af450513          	addi	a0,a0,-1292 # 80025128 <disk+0x2128>
    8000663c:	ffffa097          	auipc	ra,0xffffa
    80006640:	5a8080e7          	jalr	1448(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006644:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006646:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006648:	0001db97          	auipc	s7,0x1d
    8000664c:	9b8b8b93          	addi	s7,s7,-1608 # 80023000 <disk>
    80006650:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006652:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006654:	8a4e                	mv	s4,s3
    80006656:	a051                	j	800066da <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006658:	00fb86b3          	add	a3,s7,a5
    8000665c:	96da                	add	a3,a3,s6
    8000665e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006662:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006664:	0207c563          	bltz	a5,8000668e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006668:	2485                	addiw	s1,s1,1
    8000666a:	0711                	addi	a4,a4,4
    8000666c:	25548063          	beq	s1,s5,800068ac <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006670:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006672:	0001f697          	auipc	a3,0x1f
    80006676:	9a668693          	addi	a3,a3,-1626 # 80025018 <disk+0x2018>
    8000667a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000667c:	0006c583          	lbu	a1,0(a3)
    80006680:	fde1                	bnez	a1,80006658 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006682:	2785                	addiw	a5,a5,1
    80006684:	0685                	addi	a3,a3,1
    80006686:	ff879be3          	bne	a5,s8,8000667c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000668a:	57fd                	li	a5,-1
    8000668c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000668e:	02905a63          	blez	s1,800066c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006692:	f9042503          	lw	a0,-112(s0)
    80006696:	00000097          	auipc	ra,0x0
    8000669a:	d90080e7          	jalr	-624(ra) # 80006426 <free_desc>
      for(int j = 0; j < i; j++)
    8000669e:	4785                	li	a5,1
    800066a0:	0297d163          	bge	a5,s1,800066c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066a4:	f9442503          	lw	a0,-108(s0)
    800066a8:	00000097          	auipc	ra,0x0
    800066ac:	d7e080e7          	jalr	-642(ra) # 80006426 <free_desc>
      for(int j = 0; j < i; j++)
    800066b0:	4789                	li	a5,2
    800066b2:	0097d863          	bge	a5,s1,800066c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066b6:	f9842503          	lw	a0,-104(s0)
    800066ba:	00000097          	auipc	ra,0x0
    800066be:	d6c080e7          	jalr	-660(ra) # 80006426 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066c2:	0001f597          	auipc	a1,0x1f
    800066c6:	a6658593          	addi	a1,a1,-1434 # 80025128 <disk+0x2128>
    800066ca:	0001f517          	auipc	a0,0x1f
    800066ce:	94e50513          	addi	a0,a0,-1714 # 80025018 <disk+0x2018>
    800066d2:	ffffc097          	auipc	ra,0xffffc
    800066d6:	068080e7          	jalr	104(ra) # 8000273a <sleep>
  for(int i = 0; i < 3; i++){
    800066da:	f9040713          	addi	a4,s0,-112
    800066de:	84ce                	mv	s1,s3
    800066e0:	bf41                	j	80006670 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066e2:	20058713          	addi	a4,a1,512
    800066e6:	00471693          	slli	a3,a4,0x4
    800066ea:	0001d717          	auipc	a4,0x1d
    800066ee:	91670713          	addi	a4,a4,-1770 # 80023000 <disk>
    800066f2:	9736                	add	a4,a4,a3
    800066f4:	4685                	li	a3,1
    800066f6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066fa:	20058713          	addi	a4,a1,512
    800066fe:	00471693          	slli	a3,a4,0x4
    80006702:	0001d717          	auipc	a4,0x1d
    80006706:	8fe70713          	addi	a4,a4,-1794 # 80023000 <disk>
    8000670a:	9736                	add	a4,a4,a3
    8000670c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006710:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006714:	7679                	lui	a2,0xffffe
    80006716:	963e                	add	a2,a2,a5
    80006718:	0001f697          	auipc	a3,0x1f
    8000671c:	8e868693          	addi	a3,a3,-1816 # 80025000 <disk+0x2000>
    80006720:	6298                	ld	a4,0(a3)
    80006722:	9732                	add	a4,a4,a2
    80006724:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006726:	6298                	ld	a4,0(a3)
    80006728:	9732                	add	a4,a4,a2
    8000672a:	4541                	li	a0,16
    8000672c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000672e:	6298                	ld	a4,0(a3)
    80006730:	9732                	add	a4,a4,a2
    80006732:	4505                	li	a0,1
    80006734:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006738:	f9442703          	lw	a4,-108(s0)
    8000673c:	6288                	ld	a0,0(a3)
    8000673e:	962a                	add	a2,a2,a0
    80006740:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006744:	0712                	slli	a4,a4,0x4
    80006746:	6290                	ld	a2,0(a3)
    80006748:	963a                	add	a2,a2,a4
    8000674a:	05890513          	addi	a0,s2,88
    8000674e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006750:	6294                	ld	a3,0(a3)
    80006752:	96ba                	add	a3,a3,a4
    80006754:	40000613          	li	a2,1024
    80006758:	c690                	sw	a2,8(a3)
  if(write)
    8000675a:	140d0063          	beqz	s10,8000689a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000675e:	0001f697          	auipc	a3,0x1f
    80006762:	8a26b683          	ld	a3,-1886(a3) # 80025000 <disk+0x2000>
    80006766:	96ba                	add	a3,a3,a4
    80006768:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000676c:	0001d817          	auipc	a6,0x1d
    80006770:	89480813          	addi	a6,a6,-1900 # 80023000 <disk>
    80006774:	0001f517          	auipc	a0,0x1f
    80006778:	88c50513          	addi	a0,a0,-1908 # 80025000 <disk+0x2000>
    8000677c:	6114                	ld	a3,0(a0)
    8000677e:	96ba                	add	a3,a3,a4
    80006780:	00c6d603          	lhu	a2,12(a3)
    80006784:	00166613          	ori	a2,a2,1
    80006788:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000678c:	f9842683          	lw	a3,-104(s0)
    80006790:	6110                	ld	a2,0(a0)
    80006792:	9732                	add	a4,a4,a2
    80006794:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006798:	20058613          	addi	a2,a1,512
    8000679c:	0612                	slli	a2,a2,0x4
    8000679e:	9642                	add	a2,a2,a6
    800067a0:	577d                	li	a4,-1
    800067a2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067a6:	00469713          	slli	a4,a3,0x4
    800067aa:	6114                	ld	a3,0(a0)
    800067ac:	96ba                	add	a3,a3,a4
    800067ae:	03078793          	addi	a5,a5,48
    800067b2:	97c2                	add	a5,a5,a6
    800067b4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800067b6:	611c                	ld	a5,0(a0)
    800067b8:	97ba                	add	a5,a5,a4
    800067ba:	4685                	li	a3,1
    800067bc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067be:	611c                	ld	a5,0(a0)
    800067c0:	97ba                	add	a5,a5,a4
    800067c2:	4809                	li	a6,2
    800067c4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800067c8:	611c                	ld	a5,0(a0)
    800067ca:	973e                	add	a4,a4,a5
    800067cc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067d0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800067d4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067d8:	6518                	ld	a4,8(a0)
    800067da:	00275783          	lhu	a5,2(a4)
    800067de:	8b9d                	andi	a5,a5,7
    800067e0:	0786                	slli	a5,a5,0x1
    800067e2:	97ba                	add	a5,a5,a4
    800067e4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067e8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067ec:	6518                	ld	a4,8(a0)
    800067ee:	00275783          	lhu	a5,2(a4)
    800067f2:	2785                	addiw	a5,a5,1
    800067f4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067f8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067fc:	100017b7          	lui	a5,0x10001
    80006800:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006804:	00492703          	lw	a4,4(s2)
    80006808:	4785                	li	a5,1
    8000680a:	02f71163          	bne	a4,a5,8000682c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000680e:	0001f997          	auipc	s3,0x1f
    80006812:	91a98993          	addi	s3,s3,-1766 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006816:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006818:	85ce                	mv	a1,s3
    8000681a:	854a                	mv	a0,s2
    8000681c:	ffffc097          	auipc	ra,0xffffc
    80006820:	f1e080e7          	jalr	-226(ra) # 8000273a <sleep>
  while(b->disk == 1) {
    80006824:	00492783          	lw	a5,4(s2)
    80006828:	fe9788e3          	beq	a5,s1,80006818 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000682c:	f9042903          	lw	s2,-112(s0)
    80006830:	20090793          	addi	a5,s2,512
    80006834:	00479713          	slli	a4,a5,0x4
    80006838:	0001c797          	auipc	a5,0x1c
    8000683c:	7c878793          	addi	a5,a5,1992 # 80023000 <disk>
    80006840:	97ba                	add	a5,a5,a4
    80006842:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006846:	0001e997          	auipc	s3,0x1e
    8000684a:	7ba98993          	addi	s3,s3,1978 # 80025000 <disk+0x2000>
    8000684e:	00491713          	slli	a4,s2,0x4
    80006852:	0009b783          	ld	a5,0(s3)
    80006856:	97ba                	add	a5,a5,a4
    80006858:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000685c:	854a                	mv	a0,s2
    8000685e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006862:	00000097          	auipc	ra,0x0
    80006866:	bc4080e7          	jalr	-1084(ra) # 80006426 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000686a:	8885                	andi	s1,s1,1
    8000686c:	f0ed                	bnez	s1,8000684e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000686e:	0001f517          	auipc	a0,0x1f
    80006872:	8ba50513          	addi	a0,a0,-1862 # 80025128 <disk+0x2128>
    80006876:	ffffa097          	auipc	ra,0xffffa
    8000687a:	422080e7          	jalr	1058(ra) # 80000c98 <release>
}
    8000687e:	70a6                	ld	ra,104(sp)
    80006880:	7406                	ld	s0,96(sp)
    80006882:	64e6                	ld	s1,88(sp)
    80006884:	6946                	ld	s2,80(sp)
    80006886:	69a6                	ld	s3,72(sp)
    80006888:	6a06                	ld	s4,64(sp)
    8000688a:	7ae2                	ld	s5,56(sp)
    8000688c:	7b42                	ld	s6,48(sp)
    8000688e:	7ba2                	ld	s7,40(sp)
    80006890:	7c02                	ld	s8,32(sp)
    80006892:	6ce2                	ld	s9,24(sp)
    80006894:	6d42                	ld	s10,16(sp)
    80006896:	6165                	addi	sp,sp,112
    80006898:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000689a:	0001e697          	auipc	a3,0x1e
    8000689e:	7666b683          	ld	a3,1894(a3) # 80025000 <disk+0x2000>
    800068a2:	96ba                	add	a3,a3,a4
    800068a4:	4609                	li	a2,2
    800068a6:	00c69623          	sh	a2,12(a3)
    800068aa:	b5c9                	j	8000676c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068ac:	f9042583          	lw	a1,-112(s0)
    800068b0:	20058793          	addi	a5,a1,512
    800068b4:	0792                	slli	a5,a5,0x4
    800068b6:	0001c517          	auipc	a0,0x1c
    800068ba:	7f250513          	addi	a0,a0,2034 # 800230a8 <disk+0xa8>
    800068be:	953e                	add	a0,a0,a5
  if(write)
    800068c0:	e20d11e3          	bnez	s10,800066e2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800068c4:	20058713          	addi	a4,a1,512
    800068c8:	00471693          	slli	a3,a4,0x4
    800068cc:	0001c717          	auipc	a4,0x1c
    800068d0:	73470713          	addi	a4,a4,1844 # 80023000 <disk>
    800068d4:	9736                	add	a4,a4,a3
    800068d6:	0a072423          	sw	zero,168(a4)
    800068da:	b505                	j	800066fa <virtio_disk_rw+0xf4>

00000000800068dc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800068dc:	1101                	addi	sp,sp,-32
    800068de:	ec06                	sd	ra,24(sp)
    800068e0:	e822                	sd	s0,16(sp)
    800068e2:	e426                	sd	s1,8(sp)
    800068e4:	e04a                	sd	s2,0(sp)
    800068e6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068e8:	0001f517          	auipc	a0,0x1f
    800068ec:	84050513          	addi	a0,a0,-1984 # 80025128 <disk+0x2128>
    800068f0:	ffffa097          	auipc	ra,0xffffa
    800068f4:	2f4080e7          	jalr	756(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068f8:	10001737          	lui	a4,0x10001
    800068fc:	533c                	lw	a5,96(a4)
    800068fe:	8b8d                	andi	a5,a5,3
    80006900:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006902:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006906:	0001e797          	auipc	a5,0x1e
    8000690a:	6fa78793          	addi	a5,a5,1786 # 80025000 <disk+0x2000>
    8000690e:	6b94                	ld	a3,16(a5)
    80006910:	0207d703          	lhu	a4,32(a5)
    80006914:	0026d783          	lhu	a5,2(a3)
    80006918:	06f70163          	beq	a4,a5,8000697a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000691c:	0001c917          	auipc	s2,0x1c
    80006920:	6e490913          	addi	s2,s2,1764 # 80023000 <disk>
    80006924:	0001e497          	auipc	s1,0x1e
    80006928:	6dc48493          	addi	s1,s1,1756 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000692c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006930:	6898                	ld	a4,16(s1)
    80006932:	0204d783          	lhu	a5,32(s1)
    80006936:	8b9d                	andi	a5,a5,7
    80006938:	078e                	slli	a5,a5,0x3
    8000693a:	97ba                	add	a5,a5,a4
    8000693c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000693e:	20078713          	addi	a4,a5,512
    80006942:	0712                	slli	a4,a4,0x4
    80006944:	974a                	add	a4,a4,s2
    80006946:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000694a:	e731                	bnez	a4,80006996 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000694c:	20078793          	addi	a5,a5,512
    80006950:	0792                	slli	a5,a5,0x4
    80006952:	97ca                	add	a5,a5,s2
    80006954:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006956:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000695a:	ffffc097          	auipc	ra,0xffffc
    8000695e:	f6c080e7          	jalr	-148(ra) # 800028c6 <wakeup>

    disk.used_idx += 1;
    80006962:	0204d783          	lhu	a5,32(s1)
    80006966:	2785                	addiw	a5,a5,1
    80006968:	17c2                	slli	a5,a5,0x30
    8000696a:	93c1                	srli	a5,a5,0x30
    8000696c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006970:	6898                	ld	a4,16(s1)
    80006972:	00275703          	lhu	a4,2(a4)
    80006976:	faf71be3          	bne	a4,a5,8000692c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000697a:	0001e517          	auipc	a0,0x1e
    8000697e:	7ae50513          	addi	a0,a0,1966 # 80025128 <disk+0x2128>
    80006982:	ffffa097          	auipc	ra,0xffffa
    80006986:	316080e7          	jalr	790(ra) # 80000c98 <release>
}
    8000698a:	60e2                	ld	ra,24(sp)
    8000698c:	6442                	ld	s0,16(sp)
    8000698e:	64a2                	ld	s1,8(sp)
    80006990:	6902                	ld	s2,0(sp)
    80006992:	6105                	addi	sp,sp,32
    80006994:	8082                	ret
      panic("virtio_disk_intr status");
    80006996:	00002517          	auipc	a0,0x2
    8000699a:	f3a50513          	addi	a0,a0,-198 # 800088d0 <syscalls+0x3c8>
    8000699e:	ffffa097          	auipc	ra,0xffffa
    800069a2:	ba0080e7          	jalr	-1120(ra) # 8000053e <panic>
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
