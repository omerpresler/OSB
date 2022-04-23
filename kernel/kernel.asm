
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	d2c78793          	addi	a5,a5,-724 # 80005d90 <timervec>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	562080e7          	jalr	1378(ra) # 8000268e <either_copyin>
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
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
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
    800001c8:	910080e7          	jalr	-1776(ra) # 80001ad4 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	076080e7          	jalr	118(ra) # 8000224a <sleep>
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
    80000210:	00002097          	auipc	ra,0x2
    80000214:	428080e7          	jalr	1064(ra) # 80002638 <either_copyout>
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
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
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
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
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
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
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
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	3f2080e7          	jalr	1010(ra) # 800026e4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
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
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
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
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
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
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
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
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
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
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f90080e7          	jalr	-112(ra) # 800023d6 <wakeup>
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
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
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
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
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
    80000570:	b9c50513          	addi	a0,a0,-1124 # 80008108 <digits+0xc8>
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
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
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
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
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
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
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
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
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
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
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
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
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
    800008a4:	b36080e7          	jalr	-1226(ra) # 800023d6 <wakeup>
    
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
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
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
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	91e080e7          	jalr	-1762(ra) # 8000224a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
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
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
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
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
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
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
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
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
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
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
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
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
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
    80000b82:	f3a080e7          	jalr	-198(ra) # 80001ab8 <mycpu>
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
    80000bb4:	f08080e7          	jalr	-248(ra) # 80001ab8 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	efc080e7          	jalr	-260(ra) # 80001ab8 <mycpu>
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
    80000bd8:	ee4080e7          	jalr	-284(ra) # 80001ab8 <mycpu>
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
    80000c18:	ea4080e7          	jalr	-348(ra) # 80001ab8 <mycpu>
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
    80000c44:	e78080e7          	jalr	-392(ra) # 80001ab8 <mycpu>
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
    80000eac:	ffa080e7          	jalr	-6(ra) # 80001ea2 <fork>
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	ff2080e7          	jalr	-14(ra) # 80001ea2 <fork>
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
    80000efa:	2e2080e7          	jalr	738(ra) # 800021d8 <pause_system>
    80000efe:	b7e5                	j	80000ee6 <example_pause_system+0x58>
        }
    }
    printf("\n");
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	20850513          	addi	a0,a0,520 # 80008108 <digits+0xc8>
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
    80000f3e:	f68080e7          	jalr	-152(ra) # 80001ea2 <fork>
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	f60080e7          	jalr	-160(ra) # 80001ea2 <fork>
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
    80000f86:	00001097          	auipc	ra,0x1
    80000f8a:	668080e7          	jalr	1640(ra) # 800025ee <kill_system>
    80000f8e:	b7ed                	j	80000f78 <example_kill_system+0x54>
        }
    }
    printf("\n");
    80000f90:	00007517          	auipc	a0,0x7
    80000f94:	17850513          	addi	a0,a0,376 # 80008108 <digits+0xc8>
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
    80000fbe:	aee080e7          	jalr	-1298(ra) # 80001aa8 <cpuid>
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
    80000fda:	ad2080e7          	jalr	-1326(ra) # 80001aa8 <cpuid>
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
    80000ffc:	82c080e7          	jalr	-2004(ra) # 80002824 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001000:	00005097          	auipc	ra,0x5
    80001004:	dd0080e7          	jalr	-560(ra) # 80005dd0 <plicinithart>
  }

  scheduler();    
    80001008:	00001097          	auipc	ra,0x1
    8000100c:	0ae080e7          	jalr	174(ra) # 800020b6 <scheduler>
    consoleinit();
    80001010:	fffff097          	auipc	ra,0xfffff
    80001014:	440080e7          	jalr	1088(ra) # 80000450 <consoleinit>
    printfinit();
    80001018:	fffff097          	auipc	ra,0xfffff
    8000101c:	756080e7          	jalr	1878(ra) # 8000076e <printfinit>
    printf("\n");
    80001020:	00007517          	auipc	a0,0x7
    80001024:	0e850513          	addi	a0,a0,232 # 80008108 <digits+0xc8>
    80001028:	fffff097          	auipc	ra,0xfffff
    8000102c:	560080e7          	jalr	1376(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80001030:	00007517          	auipc	a0,0x7
    80001034:	0b050513          	addi	a0,a0,176 # 800080e0 <digits+0xa0>
    80001038:	fffff097          	auipc	ra,0xfffff
    8000103c:	550080e7          	jalr	1360(ra) # 80000588 <printf>
    printf("\n");
    80001040:	00007517          	auipc	a0,0x7
    80001044:	0c850513          	addi	a0,a0,200 # 80008108 <digits+0xc8>
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
    8000106c:	990080e7          	jalr	-1648(ra) # 800019f8 <procinit>
    trapinit();      // trap vectors
    80001070:	00001097          	auipc	ra,0x1
    80001074:	78c080e7          	jalr	1932(ra) # 800027fc <trapinit>
    trapinithart();  // install kernel trap vector
    80001078:	00001097          	auipc	ra,0x1
    8000107c:	7ac080e7          	jalr	1964(ra) # 80002824 <trapinithart>
    plicinit();      // set up interrupt controller
    80001080:	00005097          	auipc	ra,0x5
    80001084:	d3a080e7          	jalr	-710(ra) # 80005dba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001088:	00005097          	auipc	ra,0x5
    8000108c:	d48080e7          	jalr	-696(ra) # 80005dd0 <plicinithart>
    binit();         // buffer cache
    80001090:	00002097          	auipc	ra,0x2
    80001094:	f20080e7          	jalr	-224(ra) # 80002fb0 <binit>
    iinit();         // inode table
    80001098:	00002097          	auipc	ra,0x2
    8000109c:	5b0080e7          	jalr	1456(ra) # 80003648 <iinit>
    fileinit();      // file table
    800010a0:	00003097          	auipc	ra,0x3
    800010a4:	55a080e7          	jalr	1370(ra) # 800045fa <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a8:	00005097          	auipc	ra,0x5
    800010ac:	e4a080e7          	jalr	-438(ra) # 80005ef2 <virtio_disk_init>
    userinit();      // first user process
    800010b0:	00001097          	auipc	ra,0x1
    800010b4:	cfc080e7          	jalr	-772(ra) # 80001dac <userinit>
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
    80001368:	5fe080e7          	jalr	1534(ra) # 80001962 <proc_mapstacks>
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

0000000080001962 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001962:	7139                	addi	sp,sp,-64
    80001964:	fc06                	sd	ra,56(sp)
    80001966:	f822                	sd	s0,48(sp)
    80001968:	f426                	sd	s1,40(sp)
    8000196a:	f04a                	sd	s2,32(sp)
    8000196c:	ec4e                	sd	s3,24(sp)
    8000196e:	e852                	sd	s4,16(sp)
    80001970:	e456                	sd	s5,8(sp)
    80001972:	e05a                	sd	s6,0(sp)
    80001974:	0080                	addi	s0,sp,64
    80001976:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001978:	00010497          	auipc	s1,0x10
    8000197c:	d5848493          	addi	s1,s1,-680 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001980:	8b26                	mv	s6,s1
    80001982:	00006a97          	auipc	s5,0x6
    80001986:	67ea8a93          	addi	s5,s5,1662 # 80008000 <etext>
    8000198a:	04000937          	lui	s2,0x4000
    8000198e:	197d                	addi	s2,s2,-1
    80001990:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001992:	00015a17          	auipc	s4,0x15
    80001996:	73ea0a13          	addi	s4,s4,1854 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	15a080e7          	jalr	346(ra) # 80000af4 <kalloc>
    800019a2:	862a                	mv	a2,a0
    if(pa == 0)
    800019a4:	c131                	beqz	a0,800019e8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019a6:	416485b3          	sub	a1,s1,s6
    800019aa:	858d                	srai	a1,a1,0x3
    800019ac:	000ab783          	ld	a5,0(s5)
    800019b0:	02f585b3          	mul	a1,a1,a5
    800019b4:	2585                	addiw	a1,a1,1
    800019b6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019ba:	4719                	li	a4,6
    800019bc:	6685                	lui	a3,0x1
    800019be:	40b905b3          	sub	a1,s2,a1
    800019c2:	854e                	mv	a0,s3
    800019c4:	00000097          	auipc	ra,0x0
    800019c8:	8b0080e7          	jalr	-1872(ra) # 80001274 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019cc:	16848493          	addi	s1,s1,360
    800019d0:	fd4495e3          	bne	s1,s4,8000199a <proc_mapstacks+0x38>
  }
}
    800019d4:	70e2                	ld	ra,56(sp)
    800019d6:	7442                	ld	s0,48(sp)
    800019d8:	74a2                	ld	s1,40(sp)
    800019da:	7902                	ld	s2,32(sp)
    800019dc:	69e2                	ld	s3,24(sp)
    800019de:	6a42                	ld	s4,16(sp)
    800019e0:	6aa2                	ld	s5,8(sp)
    800019e2:	6b02                	ld	s6,0(sp)
    800019e4:	6121                	addi	sp,sp,64
    800019e6:	8082                	ret
      panic("kalloc");
    800019e8:	00007517          	auipc	a0,0x7
    800019ec:	83050513          	addi	a0,a0,-2000 # 80008218 <digits+0x1d8>
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	b4e080e7          	jalr	-1202(ra) # 8000053e <panic>

00000000800019f8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019f8:	7139                	addi	sp,sp,-64
    800019fa:	fc06                	sd	ra,56(sp)
    800019fc:	f822                	sd	s0,48(sp)
    800019fe:	f426                	sd	s1,40(sp)
    80001a00:	f04a                	sd	s2,32(sp)
    80001a02:	ec4e                	sd	s3,24(sp)
    80001a04:	e852                	sd	s4,16(sp)
    80001a06:	e456                	sd	s5,8(sp)
    80001a08:	e05a                	sd	s6,0(sp)
    80001a0a:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a0c:	00007597          	auipc	a1,0x7
    80001a10:	81458593          	addi	a1,a1,-2028 # 80008220 <digits+0x1e0>
    80001a14:	00010517          	auipc	a0,0x10
    80001a18:	88c50513          	addi	a0,a0,-1908 # 800112a0 <pid_lock>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	138080e7          	jalr	312(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a24:	00007597          	auipc	a1,0x7
    80001a28:	80458593          	addi	a1,a1,-2044 # 80008228 <digits+0x1e8>
    80001a2c:	00010517          	auipc	a0,0x10
    80001a30:	88c50513          	addi	a0,a0,-1908 # 800112b8 <wait_lock>
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	120080e7          	jalr	288(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a3c:	00010497          	auipc	s1,0x10
    80001a40:	c9448493          	addi	s1,s1,-876 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001a44:	00006b17          	auipc	s6,0x6
    80001a48:	7f4b0b13          	addi	s6,s6,2036 # 80008238 <digits+0x1f8>
      p->kstack = KSTACK((int) (p - proc));
    80001a4c:	8aa6                	mv	s5,s1
    80001a4e:	00006a17          	auipc	s4,0x6
    80001a52:	5b2a0a13          	addi	s4,s4,1458 # 80008000 <etext>
    80001a56:	04000937          	lui	s2,0x4000
    80001a5a:	197d                	addi	s2,s2,-1
    80001a5c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a5e:	00015997          	auipc	s3,0x15
    80001a62:	67298993          	addi	s3,s3,1650 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a66:	85da                	mv	a1,s6
    80001a68:	8526                	mv	a0,s1
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	0ea080e7          	jalr	234(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a72:	415487b3          	sub	a5,s1,s5
    80001a76:	878d                	srai	a5,a5,0x3
    80001a78:	000a3703          	ld	a4,0(s4)
    80001a7c:	02e787b3          	mul	a5,a5,a4
    80001a80:	2785                	addiw	a5,a5,1
    80001a82:	00d7979b          	slliw	a5,a5,0xd
    80001a86:	40f907b3          	sub	a5,s2,a5
    80001a8a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a8c:	16848493          	addi	s1,s1,360
    80001a90:	fd349be3          	bne	s1,s3,80001a66 <procinit+0x6e>
  }
}
    80001a94:	70e2                	ld	ra,56(sp)
    80001a96:	7442                	ld	s0,48(sp)
    80001a98:	74a2                	ld	s1,40(sp)
    80001a9a:	7902                	ld	s2,32(sp)
    80001a9c:	69e2                	ld	s3,24(sp)
    80001a9e:	6a42                	ld	s4,16(sp)
    80001aa0:	6aa2                	ld	s5,8(sp)
    80001aa2:	6b02                	ld	s6,0(sp)
    80001aa4:	6121                	addi	sp,sp,64
    80001aa6:	8082                	ret

0000000080001aa8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001aa8:	1141                	addi	sp,sp,-16
    80001aaa:	e422                	sd	s0,8(sp)
    80001aac:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aae:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ab0:	2501                	sext.w	a0,a0
    80001ab2:	6422                	ld	s0,8(sp)
    80001ab4:	0141                	addi	sp,sp,16
    80001ab6:	8082                	ret

0000000080001ab8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001ab8:	1141                	addi	sp,sp,-16
    80001aba:	e422                	sd	s0,8(sp)
    80001abc:	0800                	addi	s0,sp,16
    80001abe:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ac0:	2781                	sext.w	a5,a5
    80001ac2:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ac4:	00010517          	auipc	a0,0x10
    80001ac8:	80c50513          	addi	a0,a0,-2036 # 800112d0 <cpus>
    80001acc:	953e                	add	a0,a0,a5
    80001ace:	6422                	ld	s0,8(sp)
    80001ad0:	0141                	addi	sp,sp,16
    80001ad2:	8082                	ret

0000000080001ad4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ad4:	1101                	addi	sp,sp,-32
    80001ad6:	ec06                	sd	ra,24(sp)
    80001ad8:	e822                	sd	s0,16(sp)
    80001ada:	e426                	sd	s1,8(sp)
    80001adc:	1000                	addi	s0,sp,32
  push_off();
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	0ba080e7          	jalr	186(ra) # 80000b98 <push_off>
    80001ae6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ae8:	2781                	sext.w	a5,a5
    80001aea:	079e                	slli	a5,a5,0x7
    80001aec:	0000f717          	auipc	a4,0xf
    80001af0:	7b470713          	addi	a4,a4,1972 # 800112a0 <pid_lock>
    80001af4:	97ba                	add	a5,a5,a4
    80001af6:	7b84                	ld	s1,48(a5)
  pop_off();
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	140080e7          	jalr	320(ra) # 80000c38 <pop_off>
  return p;
}
    80001b00:	8526                	mv	a0,s1
    80001b02:	60e2                	ld	ra,24(sp)
    80001b04:	6442                	ld	s0,16(sp)
    80001b06:	64a2                	ld	s1,8(sp)
    80001b08:	6105                	addi	sp,sp,32
    80001b0a:	8082                	ret

0000000080001b0c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b0c:	1141                	addi	sp,sp,-16
    80001b0e:	e406                	sd	ra,8(sp)
    80001b10:	e022                	sd	s0,0(sp)
    80001b12:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	fc0080e7          	jalr	-64(ra) # 80001ad4 <myproc>
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	17c080e7          	jalr	380(ra) # 80000c98 <release>

  if (first) {
    80001b24:	00007797          	auipc	a5,0x7
    80001b28:	d3c7a783          	lw	a5,-708(a5) # 80008860 <first.1699>
    80001b2c:	eb89                	bnez	a5,80001b3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b2e:	00001097          	auipc	ra,0x1
    80001b32:	d0e080e7          	jalr	-754(ra) # 8000283c <usertrapret>
}
    80001b36:	60a2                	ld	ra,8(sp)
    80001b38:	6402                	ld	s0,0(sp)
    80001b3a:	0141                	addi	sp,sp,16
    80001b3c:	8082                	ret
    first = 0;
    80001b3e:	00007797          	auipc	a5,0x7
    80001b42:	d207a123          	sw	zero,-734(a5) # 80008860 <first.1699>
    fsinit(ROOTDEV);
    80001b46:	4505                	li	a0,1
    80001b48:	00002097          	auipc	ra,0x2
    80001b4c:	a80080e7          	jalr	-1408(ra) # 800035c8 <fsinit>
    80001b50:	bff9                	j	80001b2e <forkret+0x22>

0000000080001b52 <allocpid>:
allocpid() {
    80001b52:	1101                	addi	sp,sp,-32
    80001b54:	ec06                	sd	ra,24(sp)
    80001b56:	e822                	sd	s0,16(sp)
    80001b58:	e426                	sd	s1,8(sp)
    80001b5a:	e04a                	sd	s2,0(sp)
    80001b5c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b5e:	0000f917          	auipc	s2,0xf
    80001b62:	74290913          	addi	s2,s2,1858 # 800112a0 <pid_lock>
    80001b66:	854a                	mv	a0,s2
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	07c080e7          	jalr	124(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b70:	00007797          	auipc	a5,0x7
    80001b74:	cf478793          	addi	a5,a5,-780 # 80008864 <nextpid>
    80001b78:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b7a:	0014871b          	addiw	a4,s1,1
    80001b7e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b80:	854a                	mv	a0,s2
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	116080e7          	jalr	278(ra) # 80000c98 <release>
}
    80001b8a:	8526                	mv	a0,s1
    80001b8c:	60e2                	ld	ra,24(sp)
    80001b8e:	6442                	ld	s0,16(sp)
    80001b90:	64a2                	ld	s1,8(sp)
    80001b92:	6902                	ld	s2,0(sp)
    80001b94:	6105                	addi	sp,sp,32
    80001b96:	8082                	ret

0000000080001b98 <proc_pagetable>:
{
    80001b98:	1101                	addi	sp,sp,-32
    80001b9a:	ec06                	sd	ra,24(sp)
    80001b9c:	e822                	sd	s0,16(sp)
    80001b9e:	e426                	sd	s1,8(sp)
    80001ba0:	e04a                	sd	s2,0(sp)
    80001ba2:	1000                	addi	s0,sp,32
    80001ba4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ba6:	00000097          	auipc	ra,0x0
    80001baa:	8b8080e7          	jalr	-1864(ra) # 8000145e <uvmcreate>
    80001bae:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bb0:	c121                	beqz	a0,80001bf0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bb2:	4729                	li	a4,10
    80001bb4:	00005697          	auipc	a3,0x5
    80001bb8:	44c68693          	addi	a3,a3,1100 # 80007000 <_trampoline>
    80001bbc:	6605                	lui	a2,0x1
    80001bbe:	040005b7          	lui	a1,0x4000
    80001bc2:	15fd                	addi	a1,a1,-1
    80001bc4:	05b2                	slli	a1,a1,0xc
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	60e080e7          	jalr	1550(ra) # 800011d4 <mappages>
    80001bce:	02054863          	bltz	a0,80001bfe <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bd2:	4719                	li	a4,6
    80001bd4:	05893683          	ld	a3,88(s2)
    80001bd8:	6605                	lui	a2,0x1
    80001bda:	020005b7          	lui	a1,0x2000
    80001bde:	15fd                	addi	a1,a1,-1
    80001be0:	05b6                	slli	a1,a1,0xd
    80001be2:	8526                	mv	a0,s1
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	5f0080e7          	jalr	1520(ra) # 800011d4 <mappages>
    80001bec:	02054163          	bltz	a0,80001c0e <proc_pagetable+0x76>
}
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	60e2                	ld	ra,24(sp)
    80001bf4:	6442                	ld	s0,16(sp)
    80001bf6:	64a2                	ld	s1,8(sp)
    80001bf8:	6902                	ld	s2,0(sp)
    80001bfa:	6105                	addi	sp,sp,32
    80001bfc:	8082                	ret
    uvmfree(pagetable, 0);
    80001bfe:	4581                	li	a1,0
    80001c00:	8526                	mv	a0,s1
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	a58080e7          	jalr	-1448(ra) # 8000165a <uvmfree>
    return 0;
    80001c0a:	4481                	li	s1,0
    80001c0c:	b7d5                	j	80001bf0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c0e:	4681                	li	a3,0
    80001c10:	4605                	li	a2,1
    80001c12:	040005b7          	lui	a1,0x4000
    80001c16:	15fd                	addi	a1,a1,-1
    80001c18:	05b2                	slli	a1,a1,0xc
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	77e080e7          	jalr	1918(ra) # 8000139a <uvmunmap>
    uvmfree(pagetable, 0);
    80001c24:	4581                	li	a1,0
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	a32080e7          	jalr	-1486(ra) # 8000165a <uvmfree>
    return 0;
    80001c30:	4481                	li	s1,0
    80001c32:	bf7d                	j	80001bf0 <proc_pagetable+0x58>

0000000080001c34 <proc_freepagetable>:
{
    80001c34:	1101                	addi	sp,sp,-32
    80001c36:	ec06                	sd	ra,24(sp)
    80001c38:	e822                	sd	s0,16(sp)
    80001c3a:	e426                	sd	s1,8(sp)
    80001c3c:	e04a                	sd	s2,0(sp)
    80001c3e:	1000                	addi	s0,sp,32
    80001c40:	84aa                	mv	s1,a0
    80001c42:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c44:	4681                	li	a3,0
    80001c46:	4605                	li	a2,1
    80001c48:	040005b7          	lui	a1,0x4000
    80001c4c:	15fd                	addi	a1,a1,-1
    80001c4e:	05b2                	slli	a1,a1,0xc
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	74a080e7          	jalr	1866(ra) # 8000139a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c58:	4681                	li	a3,0
    80001c5a:	4605                	li	a2,1
    80001c5c:	020005b7          	lui	a1,0x2000
    80001c60:	15fd                	addi	a1,a1,-1
    80001c62:	05b6                	slli	a1,a1,0xd
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	734080e7          	jalr	1844(ra) # 8000139a <uvmunmap>
  uvmfree(pagetable, sz);
    80001c6e:	85ca                	mv	a1,s2
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	9e8080e7          	jalr	-1560(ra) # 8000165a <uvmfree>
}
    80001c7a:	60e2                	ld	ra,24(sp)
    80001c7c:	6442                	ld	s0,16(sp)
    80001c7e:	64a2                	ld	s1,8(sp)
    80001c80:	6902                	ld	s2,0(sp)
    80001c82:	6105                	addi	sp,sp,32
    80001c84:	8082                	ret

0000000080001c86 <freeproc>:
{
    80001c86:	1101                	addi	sp,sp,-32
    80001c88:	ec06                	sd	ra,24(sp)
    80001c8a:	e822                	sd	s0,16(sp)
    80001c8c:	e426                	sd	s1,8(sp)
    80001c8e:	1000                	addi	s0,sp,32
    80001c90:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c92:	6d28                	ld	a0,88(a0)
    80001c94:	c509                	beqz	a0,80001c9e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	d62080e7          	jalr	-670(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001c9e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ca2:	68a8                	ld	a0,80(s1)
    80001ca4:	c511                	beqz	a0,80001cb0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ca6:	64ac                	ld	a1,72(s1)
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f8c080e7          	jalr	-116(ra) # 80001c34 <proc_freepagetable>
  p->pagetable = 0;
    80001cb0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cb4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cb8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cbc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cc0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cc4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cc8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ccc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cd0:	0004ac23          	sw	zero,24(s1)
}
    80001cd4:	60e2                	ld	ra,24(sp)
    80001cd6:	6442                	ld	s0,16(sp)
    80001cd8:	64a2                	ld	s1,8(sp)
    80001cda:	6105                	addi	sp,sp,32
    80001cdc:	8082                	ret

0000000080001cde <allocproc>:
{
    80001cde:	1101                	addi	sp,sp,-32
    80001ce0:	ec06                	sd	ra,24(sp)
    80001ce2:	e822                	sd	s0,16(sp)
    80001ce4:	e426                	sd	s1,8(sp)
    80001ce6:	e04a                	sd	s2,0(sp)
    80001ce8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cea:	00010497          	auipc	s1,0x10
    80001cee:	9e648493          	addi	s1,s1,-1562 # 800116d0 <proc>
    80001cf2:	00015917          	auipc	s2,0x15
    80001cf6:	3de90913          	addi	s2,s2,990 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	ee8080e7          	jalr	-280(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001d04:	4c9c                	lw	a5,24(s1)
    80001d06:	cf81                	beqz	a5,80001d1e <allocproc+0x40>
      release(&p->lock);
    80001d08:	8526                	mv	a0,s1
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	f8e080e7          	jalr	-114(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d12:	16848493          	addi	s1,s1,360
    80001d16:	ff2492e3          	bne	s1,s2,80001cfa <allocproc+0x1c>
  return 0;
    80001d1a:	4481                	li	s1,0
    80001d1c:	a889                	j	80001d6e <allocproc+0x90>
  p->pid = allocpid();
    80001d1e:	00000097          	auipc	ra,0x0
    80001d22:	e34080e7          	jalr	-460(ra) # 80001b52 <allocpid>
    80001d26:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d28:	4785                	li	a5,1
    80001d2a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	dc8080e7          	jalr	-568(ra) # 80000af4 <kalloc>
    80001d34:	892a                	mv	s2,a0
    80001d36:	eca8                	sd	a0,88(s1)
    80001d38:	c131                	beqz	a0,80001d7c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	e5c080e7          	jalr	-420(ra) # 80001b98 <proc_pagetable>
    80001d44:	892a                	mv	s2,a0
    80001d46:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d48:	c531                	beqz	a0,80001d94 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d4a:	07000613          	li	a2,112
    80001d4e:	4581                	li	a1,0
    80001d50:	06048513          	addi	a0,s1,96
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	f8c080e7          	jalr	-116(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d5c:	00000797          	auipc	a5,0x0
    80001d60:	db078793          	addi	a5,a5,-592 # 80001b0c <forkret>
    80001d64:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d66:	60bc                	ld	a5,64(s1)
    80001d68:	6705                	lui	a4,0x1
    80001d6a:	97ba                	add	a5,a5,a4
    80001d6c:	f4bc                	sd	a5,104(s1)
}
    80001d6e:	8526                	mv	a0,s1
    80001d70:	60e2                	ld	ra,24(sp)
    80001d72:	6442                	ld	s0,16(sp)
    80001d74:	64a2                	ld	s1,8(sp)
    80001d76:	6902                	ld	s2,0(sp)
    80001d78:	6105                	addi	sp,sp,32
    80001d7a:	8082                	ret
    freeproc(p);
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	f08080e7          	jalr	-248(ra) # 80001c86 <freeproc>
    release(&p->lock);
    80001d86:	8526                	mv	a0,s1
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	f10080e7          	jalr	-240(ra) # 80000c98 <release>
    return 0;
    80001d90:	84ca                	mv	s1,s2
    80001d92:	bff1                	j	80001d6e <allocproc+0x90>
    freeproc(p);
    80001d94:	8526                	mv	a0,s1
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	ef0080e7          	jalr	-272(ra) # 80001c86 <freeproc>
    release(&p->lock);
    80001d9e:	8526                	mv	a0,s1
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	ef8080e7          	jalr	-264(ra) # 80000c98 <release>
    return 0;
    80001da8:	84ca                	mv	s1,s2
    80001daa:	b7d1                	j	80001d6e <allocproc+0x90>

0000000080001dac <userinit>:
{
    80001dac:	1101                	addi	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	f28080e7          	jalr	-216(ra) # 80001cde <allocproc>
    80001dbe:	84aa                	mv	s1,a0
  initproc = p;
    80001dc0:	00007797          	auipc	a5,0x7
    80001dc4:	26a7b823          	sd	a0,624(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dc8:	03400613          	li	a2,52
    80001dcc:	00007597          	auipc	a1,0x7
    80001dd0:	aa458593          	addi	a1,a1,-1372 # 80008870 <initcode>
    80001dd4:	6928                	ld	a0,80(a0)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	6b6080e7          	jalr	1718(ra) # 8000148c <uvminit>
  p->sz = PGSIZE;
    80001dde:	6785                	lui	a5,0x1
    80001de0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001de2:	6cb8                	ld	a4,88(s1)
    80001de4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001de8:	6cb8                	ld	a4,88(s1)
    80001dea:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dec:	4641                	li	a2,16
    80001dee:	00006597          	auipc	a1,0x6
    80001df2:	45258593          	addi	a1,a1,1106 # 80008240 <digits+0x200>
    80001df6:	15848513          	addi	a0,s1,344
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	038080e7          	jalr	56(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001e02:	00006517          	auipc	a0,0x6
    80001e06:	44e50513          	addi	a0,a0,1102 # 80008250 <digits+0x210>
    80001e0a:	00002097          	auipc	ra,0x2
    80001e0e:	1ec080e7          	jalr	492(ra) # 80003ff6 <namei>
    80001e12:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e16:	478d                	li	a5,3
    80001e18:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e1a:	8526                	mv	a0,s1
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	e7c080e7          	jalr	-388(ra) # 80000c98 <release>
}
    80001e24:	60e2                	ld	ra,24(sp)
    80001e26:	6442                	ld	s0,16(sp)
    80001e28:	64a2                	ld	s1,8(sp)
    80001e2a:	6105                	addi	sp,sp,32
    80001e2c:	8082                	ret

0000000080001e2e <growproc>:
{
    80001e2e:	1101                	addi	sp,sp,-32
    80001e30:	ec06                	sd	ra,24(sp)
    80001e32:	e822                	sd	s0,16(sp)
    80001e34:	e426                	sd	s1,8(sp)
    80001e36:	e04a                	sd	s2,0(sp)
    80001e38:	1000                	addi	s0,sp,32
    80001e3a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	c98080e7          	jalr	-872(ra) # 80001ad4 <myproc>
    80001e44:	892a                	mv	s2,a0
  sz = p->sz;
    80001e46:	652c                	ld	a1,72(a0)
    80001e48:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e4c:	00904f63          	bgtz	s1,80001e6a <growproc+0x3c>
  } else if(n < 0){
    80001e50:	0204cc63          	bltz	s1,80001e88 <growproc+0x5a>
  p->sz = sz;
    80001e54:	1602                	slli	a2,a2,0x20
    80001e56:	9201                	srli	a2,a2,0x20
    80001e58:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e5c:	4501                	li	a0,0
}
    80001e5e:	60e2                	ld	ra,24(sp)
    80001e60:	6442                	ld	s0,16(sp)
    80001e62:	64a2                	ld	s1,8(sp)
    80001e64:	6902                	ld	s2,0(sp)
    80001e66:	6105                	addi	sp,sp,32
    80001e68:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e6a:	9e25                	addw	a2,a2,s1
    80001e6c:	1602                	slli	a2,a2,0x20
    80001e6e:	9201                	srli	a2,a2,0x20
    80001e70:	1582                	slli	a1,a1,0x20
    80001e72:	9181                	srli	a1,a1,0x20
    80001e74:	6928                	ld	a0,80(a0)
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	6d0080e7          	jalr	1744(ra) # 80001546 <uvmalloc>
    80001e7e:	0005061b          	sext.w	a2,a0
    80001e82:	fa69                	bnez	a2,80001e54 <growproc+0x26>
      return -1;
    80001e84:	557d                	li	a0,-1
    80001e86:	bfe1                	j	80001e5e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e88:	9e25                	addw	a2,a2,s1
    80001e8a:	1602                	slli	a2,a2,0x20
    80001e8c:	9201                	srli	a2,a2,0x20
    80001e8e:	1582                	slli	a1,a1,0x20
    80001e90:	9181                	srli	a1,a1,0x20
    80001e92:	6928                	ld	a0,80(a0)
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	66a080e7          	jalr	1642(ra) # 800014fe <uvmdealloc>
    80001e9c:	0005061b          	sext.w	a2,a0
    80001ea0:	bf55                	j	80001e54 <growproc+0x26>

0000000080001ea2 <fork>:
{
    80001ea2:	7179                	addi	sp,sp,-48
    80001ea4:	f406                	sd	ra,40(sp)
    80001ea6:	f022                	sd	s0,32(sp)
    80001ea8:	ec26                	sd	s1,24(sp)
    80001eaa:	e84a                	sd	s2,16(sp)
    80001eac:	e44e                	sd	s3,8(sp)
    80001eae:	e052                	sd	s4,0(sp)
    80001eb0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	c22080e7          	jalr	-990(ra) # 80001ad4 <myproc>
    80001eba:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001ebc:	00000097          	auipc	ra,0x0
    80001ec0:	e22080e7          	jalr	-478(ra) # 80001cde <allocproc>
    80001ec4:	10050b63          	beqz	a0,80001fda <fork+0x138>
    80001ec8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eca:	04893603          	ld	a2,72(s2)
    80001ece:	692c                	ld	a1,80(a0)
    80001ed0:	05093503          	ld	a0,80(s2)
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	7be080e7          	jalr	1982(ra) # 80001692 <uvmcopy>
    80001edc:	04054663          	bltz	a0,80001f28 <fork+0x86>
  np->sz = p->sz;
    80001ee0:	04893783          	ld	a5,72(s2)
    80001ee4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ee8:	05893683          	ld	a3,88(s2)
    80001eec:	87b6                	mv	a5,a3
    80001eee:	0589b703          	ld	a4,88(s3)
    80001ef2:	12068693          	addi	a3,a3,288
    80001ef6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001efa:	6788                	ld	a0,8(a5)
    80001efc:	6b8c                	ld	a1,16(a5)
    80001efe:	6f90                	ld	a2,24(a5)
    80001f00:	01073023          	sd	a6,0(a4)
    80001f04:	e708                	sd	a0,8(a4)
    80001f06:	eb0c                	sd	a1,16(a4)
    80001f08:	ef10                	sd	a2,24(a4)
    80001f0a:	02078793          	addi	a5,a5,32
    80001f0e:	02070713          	addi	a4,a4,32
    80001f12:	fed792e3          	bne	a5,a3,80001ef6 <fork+0x54>
  np->trapframe->a0 = 0;
    80001f16:	0589b783          	ld	a5,88(s3)
    80001f1a:	0607b823          	sd	zero,112(a5)
    80001f1e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f22:	15000a13          	li	s4,336
    80001f26:	a03d                	j	80001f54 <fork+0xb2>
    freeproc(np);
    80001f28:	854e                	mv	a0,s3
    80001f2a:	00000097          	auipc	ra,0x0
    80001f2e:	d5c080e7          	jalr	-676(ra) # 80001c86 <freeproc>
    release(&np->lock);
    80001f32:	854e                	mv	a0,s3
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	d64080e7          	jalr	-668(ra) # 80000c98 <release>
    return -1;
    80001f3c:	5a7d                	li	s4,-1
    80001f3e:	a069                	j	80001fc8 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f40:	00002097          	auipc	ra,0x2
    80001f44:	74c080e7          	jalr	1868(ra) # 8000468c <filedup>
    80001f48:	009987b3          	add	a5,s3,s1
    80001f4c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f4e:	04a1                	addi	s1,s1,8
    80001f50:	01448763          	beq	s1,s4,80001f5e <fork+0xbc>
    if(p->ofile[i])
    80001f54:	009907b3          	add	a5,s2,s1
    80001f58:	6388                	ld	a0,0(a5)
    80001f5a:	f17d                	bnez	a0,80001f40 <fork+0x9e>
    80001f5c:	bfcd                	j	80001f4e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f5e:	15093503          	ld	a0,336(s2)
    80001f62:	00002097          	auipc	ra,0x2
    80001f66:	8a0080e7          	jalr	-1888(ra) # 80003802 <idup>
    80001f6a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f6e:	4641                	li	a2,16
    80001f70:	15890593          	addi	a1,s2,344
    80001f74:	15898513          	addi	a0,s3,344
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	eba080e7          	jalr	-326(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f80:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f84:	854e                	mv	a0,s3
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d12080e7          	jalr	-750(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f8e:	0000f497          	auipc	s1,0xf
    80001f92:	32a48493          	addi	s1,s1,810 # 800112b8 <wait_lock>
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	c4c080e7          	jalr	-948(ra) # 80000be4 <acquire>
  np->parent = p;
    80001fa0:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	cf2080e7          	jalr	-782(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001fae:	854e                	mv	a0,s3
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	c34080e7          	jalr	-972(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001fb8:	478d                	li	a5,3
    80001fba:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fbe:	854e                	mv	a0,s3
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	cd8080e7          	jalr	-808(ra) # 80000c98 <release>
}
    80001fc8:	8552                	mv	a0,s4
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6a02                	ld	s4,0(sp)
    80001fd6:	6145                	addi	sp,sp,48
    80001fd8:	8082                	ret
    return -1;
    80001fda:	5a7d                	li	s4,-1
    80001fdc:	b7f5                	j	80001fc8 <fork+0x126>

0000000080001fde <SJFtScheduler>:
{
    80001fde:	1141                	addi	sp,sp,-16
    80001fe0:	e422                	sd	s0,8(sp)
    80001fe2:	0800                	addi	s0,sp,16
}
    80001fe4:	6422                	ld	s0,8(sp)
    80001fe6:	0141                	addi	sp,sp,16
    80001fe8:	8082                	ret

0000000080001fea <FCFSScheduler>:
{
    80001fea:	1141                	addi	sp,sp,-16
    80001fec:	e422                	sd	s0,8(sp)
    80001fee:	0800                	addi	s0,sp,16
  }
    80001ff0:	6422                	ld	s0,8(sp)
    80001ff2:	0141                	addi	sp,sp,16
    80001ff4:	8082                	ret

0000000080001ff6 <regulerScheduler>:
{
    80001ff6:	715d                	addi	sp,sp,-80
    80001ff8:	e486                	sd	ra,72(sp)
    80001ffa:	e0a2                	sd	s0,64(sp)
    80001ffc:	fc26                	sd	s1,56(sp)
    80001ffe:	f84a                	sd	s2,48(sp)
    80002000:	f44e                	sd	s3,40(sp)
    80002002:	f052                	sd	s4,32(sp)
    80002004:	ec56                	sd	s5,24(sp)
    80002006:	e85a                	sd	s6,16(sp)
    80002008:	e45e                	sd	s7,8(sp)
    8000200a:	e062                	sd	s8,0(sp)
    8000200c:	0880                	addi	s0,sp,80
    8000200e:	8792                	mv	a5,tp
  int id = r_tp();
    80002010:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002012:	00779c13          	slli	s8,a5,0x7
    80002016:	0000f717          	auipc	a4,0xf
    8000201a:	28a70713          	addi	a4,a4,650 # 800112a0 <pid_lock>
    8000201e:	9762                	add	a4,a4,s8
    80002020:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80002024:	0000f717          	auipc	a4,0xf
    80002028:	2b470713          	addi	a4,a4,692 # 800112d8 <cpus+0x8>
    8000202c:	9c3a                	add	s8,s8,a4
      if (ticks > nextGoodTicks)
    8000202e:	00007a17          	auipc	s4,0x7
    80002032:	00aa0a13          	addi	s4,s4,10 # 80009038 <ticks>
    80002036:	00007997          	auipc	s3,0x7
    8000203a:	ff298993          	addi	s3,s3,-14 # 80009028 <nextGoodTicks>
        if (p->state == RUNNABLE)
    8000203e:	4a8d                	li	s5,3
          c->proc = p;
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	0000fb17          	auipc	s6,0xf
    80002046:	25eb0b13          	addi	s6,s6,606 # 800112a0 <pid_lock>
    8000204a:	9b3e                	add	s6,s6,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000204c:	00015917          	auipc	s2,0x15
    80002050:	08490913          	addi	s2,s2,132 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002054:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002058:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000205c:	10079073          	csrw	sstatus,a5
    80002060:	0000f497          	auipc	s1,0xf
    80002064:	67048493          	addi	s1,s1,1648 # 800116d0 <proc>
          p->state = RUNNING;
    80002068:	4b91                	li	s7,4
    8000206a:	a03d                	j	80002098 <regulerScheduler+0xa2>
    8000206c:	0174ac23          	sw	s7,24(s1)
          c->proc = p;
    80002070:	029b3823          	sd	s1,48(s6)
          swtch(&c->context, &p->context);
    80002074:	06048593          	addi	a1,s1,96
    80002078:	8562                	mv	a0,s8
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	718080e7          	jalr	1816(ra) # 80002792 <swtch>
          c->proc = 0;
    80002082:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    80002086:	8526                	mv	a0,s1
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	c10080e7          	jalr	-1008(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002090:	16848493          	addi	s1,s1,360
    80002094:	fd2480e3          	beq	s1,s2,80002054 <regulerScheduler+0x5e>
      if (ticks > nextGoodTicks)
    80002098:	000a2703          	lw	a4,0(s4)
    8000209c:	0009a783          	lw	a5,0(s3)
    800020a0:	fee7f8e3          	bgeu	a5,a4,80002090 <regulerScheduler+0x9a>
        acquire(&p->lock);
    800020a4:	8526                	mv	a0,s1
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	b3e080e7          	jalr	-1218(ra) # 80000be4 <acquire>
        if (p->state == RUNNABLE)
    800020ae:	4c9c                	lw	a5,24(s1)
    800020b0:	fd579be3          	bne	a5,s5,80002086 <regulerScheduler+0x90>
    800020b4:	bf65                	j	8000206c <regulerScheduler+0x76>

00000000800020b6 <scheduler>:
{
    800020b6:	1141                	addi	sp,sp,-16
    800020b8:	e406                	sd	ra,8(sp)
    800020ba:	e022                	sd	s0,0(sp)
    800020bc:	0800                	addi	s0,sp,16
    regulerScheduler();
    800020be:	00000097          	auipc	ra,0x0
    800020c2:	f38080e7          	jalr	-200(ra) # 80001ff6 <regulerScheduler>

00000000800020c6 <sched>:
{
    800020c6:	7179                	addi	sp,sp,-48
    800020c8:	f406                	sd	ra,40(sp)
    800020ca:	f022                	sd	s0,32(sp)
    800020cc:	ec26                	sd	s1,24(sp)
    800020ce:	e84a                	sd	s2,16(sp)
    800020d0:	e44e                	sd	s3,8(sp)
    800020d2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	a00080e7          	jalr	-1536(ra) # 80001ad4 <myproc>
    800020dc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	a8c080e7          	jalr	-1396(ra) # 80000b6a <holding>
    800020e6:	c93d                	beqz	a0,8000215c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020e8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020ea:	2781                	sext.w	a5,a5
    800020ec:	079e                	slli	a5,a5,0x7
    800020ee:	0000f717          	auipc	a4,0xf
    800020f2:	1b270713          	addi	a4,a4,434 # 800112a0 <pid_lock>
    800020f6:	97ba                	add	a5,a5,a4
    800020f8:	0a87a703          	lw	a4,168(a5)
    800020fc:	4785                	li	a5,1
    800020fe:	06f71763          	bne	a4,a5,8000216c <sched+0xa6>
  if(p->state == RUNNING)
    80002102:	4c98                	lw	a4,24(s1)
    80002104:	4791                	li	a5,4
    80002106:	06f70b63          	beq	a4,a5,8000217c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000210a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000210e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002110:	efb5                	bnez	a5,8000218c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002112:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002114:	0000f917          	auipc	s2,0xf
    80002118:	18c90913          	addi	s2,s2,396 # 800112a0 <pid_lock>
    8000211c:	2781                	sext.w	a5,a5
    8000211e:	079e                	slli	a5,a5,0x7
    80002120:	97ca                	add	a5,a5,s2
    80002122:	0ac7a983          	lw	s3,172(a5)
    80002126:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002128:	2781                	sext.w	a5,a5
    8000212a:	079e                	slli	a5,a5,0x7
    8000212c:	0000f597          	auipc	a1,0xf
    80002130:	1ac58593          	addi	a1,a1,428 # 800112d8 <cpus+0x8>
    80002134:	95be                	add	a1,a1,a5
    80002136:	06048513          	addi	a0,s1,96
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	658080e7          	jalr	1624(ra) # 80002792 <swtch>
    80002142:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002144:	2781                	sext.w	a5,a5
    80002146:	079e                	slli	a5,a5,0x7
    80002148:	97ca                	add	a5,a5,s2
    8000214a:	0b37a623          	sw	s3,172(a5)
}
    8000214e:	70a2                	ld	ra,40(sp)
    80002150:	7402                	ld	s0,32(sp)
    80002152:	64e2                	ld	s1,24(sp)
    80002154:	6942                	ld	s2,16(sp)
    80002156:	69a2                	ld	s3,8(sp)
    80002158:	6145                	addi	sp,sp,48
    8000215a:	8082                	ret
    panic("sched p->lock");
    8000215c:	00006517          	auipc	a0,0x6
    80002160:	0fc50513          	addi	a0,a0,252 # 80008258 <digits+0x218>
    80002164:	ffffe097          	auipc	ra,0xffffe
    80002168:	3da080e7          	jalr	986(ra) # 8000053e <panic>
    panic("sched locks");
    8000216c:	00006517          	auipc	a0,0x6
    80002170:	0fc50513          	addi	a0,a0,252 # 80008268 <digits+0x228>
    80002174:	ffffe097          	auipc	ra,0xffffe
    80002178:	3ca080e7          	jalr	970(ra) # 8000053e <panic>
    panic("sched running");
    8000217c:	00006517          	auipc	a0,0x6
    80002180:	0fc50513          	addi	a0,a0,252 # 80008278 <digits+0x238>
    80002184:	ffffe097          	auipc	ra,0xffffe
    80002188:	3ba080e7          	jalr	954(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000218c:	00006517          	auipc	a0,0x6
    80002190:	0fc50513          	addi	a0,a0,252 # 80008288 <digits+0x248>
    80002194:	ffffe097          	auipc	ra,0xffffe
    80002198:	3aa080e7          	jalr	938(ra) # 8000053e <panic>

000000008000219c <yield>:
{
    8000219c:	1101                	addi	sp,sp,-32
    8000219e:	ec06                	sd	ra,24(sp)
    800021a0:	e822                	sd	s0,16(sp)
    800021a2:	e426                	sd	s1,8(sp)
    800021a4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021a6:	00000097          	auipc	ra,0x0
    800021aa:	92e080e7          	jalr	-1746(ra) # 80001ad4 <myproc>
    800021ae:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	a34080e7          	jalr	-1484(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800021b8:	478d                	li	a5,3
    800021ba:	cc9c                	sw	a5,24(s1)
  sched();
    800021bc:	00000097          	auipc	ra,0x0
    800021c0:	f0a080e7          	jalr	-246(ra) # 800020c6 <sched>
  release(&p->lock);
    800021c4:	8526                	mv	a0,s1
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	ad2080e7          	jalr	-1326(ra) # 80000c98 <release>
}
    800021ce:	60e2                	ld	ra,24(sp)
    800021d0:	6442                	ld	s0,16(sp)
    800021d2:	64a2                	ld	s1,8(sp)
    800021d4:	6105                	addi	sp,sp,32
    800021d6:	8082                	ret

00000000800021d8 <pause_system>:
  nextGoodTicks = StartingTicks + 10 * seconds;
    800021d8:	0025179b          	slliw	a5,a0,0x2
    800021dc:	9fa9                	addw	a5,a5,a0
    800021de:	0017979b          	slliw	a5,a5,0x1
    800021e2:	00007717          	auipc	a4,0x7
    800021e6:	e5672703          	lw	a4,-426(a4) # 80009038 <ticks>
    800021ea:	9fb9                	addw	a5,a5,a4
    800021ec:	00007717          	auipc	a4,0x7
    800021f0:	e2f72e23          	sw	a5,-452(a4) # 80009028 <nextGoodTicks>
  if (seconds < 0)
    800021f4:	04054963          	bltz	a0,80002246 <pause_system+0x6e>
{
    800021f8:	1101                	addi	sp,sp,-32
    800021fa:	ec06                	sd	ra,24(sp)
    800021fc:	e822                	sd	s0,16(sp)
    800021fe:	e426                	sd	s1,8(sp)
    80002200:	e04a                	sd	s2,0(sp)
    80002202:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80002204:	0000f497          	auipc	s1,0xf
    80002208:	4cc48493          	addi	s1,s1,1228 # 800116d0 <proc>
    8000220c:	00015917          	auipc	s2,0x15
    80002210:	ec490913          	addi	s2,s2,-316 # 800170d0 <tickslock>
    acquire(&p->lock);
    80002214:	8526                	mv	a0,s1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	9ce080e7          	jalr	-1586(ra) # 80000be4 <acquire>
    release(&p->lock);
    8000221e:	8526                	mv	a0,s1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	a78080e7          	jalr	-1416(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002228:	16848493          	addi	s1,s1,360
    8000222c:	ff2494e3          	bne	s1,s2,80002214 <pause_system+0x3c>
  yield();
    80002230:	00000097          	auipc	ra,0x0
    80002234:	f6c080e7          	jalr	-148(ra) # 8000219c <yield>
  return 0;
    80002238:	4501                	li	a0,0
}
    8000223a:	60e2                	ld	ra,24(sp)
    8000223c:	6442                	ld	s0,16(sp)
    8000223e:	64a2                	ld	s1,8(sp)
    80002240:	6902                	ld	s2,0(sp)
    80002242:	6105                	addi	sp,sp,32
    80002244:	8082                	ret
    return -1;
    80002246:	557d                	li	a0,-1
}
    80002248:	8082                	ret

000000008000224a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000224a:	7179                	addi	sp,sp,-48
    8000224c:	f406                	sd	ra,40(sp)
    8000224e:	f022                	sd	s0,32(sp)
    80002250:	ec26                	sd	s1,24(sp)
    80002252:	e84a                	sd	s2,16(sp)
    80002254:	e44e                	sd	s3,8(sp)
    80002256:	1800                	addi	s0,sp,48
    80002258:	89aa                	mv	s3,a0
    8000225a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	878080e7          	jalr	-1928(ra) # 80001ad4 <myproc>
    80002264:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	97e080e7          	jalr	-1666(ra) # 80000be4 <acquire>
  release(lk);
    8000226e:	854a                	mv	a0,s2
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	a28080e7          	jalr	-1496(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002278:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000227c:	4789                	li	a5,2
    8000227e:	cc9c                	sw	a5,24(s1)

  sched();
    80002280:	00000097          	auipc	ra,0x0
    80002284:	e46080e7          	jalr	-442(ra) # 800020c6 <sched>

  // Tidy up.
  p->chan = 0;
    80002288:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	a0a080e7          	jalr	-1526(ra) # 80000c98 <release>
  acquire(lk);
    80002296:	854a                	mv	a0,s2
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	94c080e7          	jalr	-1716(ra) # 80000be4 <acquire>
}
    800022a0:	70a2                	ld	ra,40(sp)
    800022a2:	7402                	ld	s0,32(sp)
    800022a4:	64e2                	ld	s1,24(sp)
    800022a6:	6942                	ld	s2,16(sp)
    800022a8:	69a2                	ld	s3,8(sp)
    800022aa:	6145                	addi	sp,sp,48
    800022ac:	8082                	ret

00000000800022ae <wait>:
{
    800022ae:	715d                	addi	sp,sp,-80
    800022b0:	e486                	sd	ra,72(sp)
    800022b2:	e0a2                	sd	s0,64(sp)
    800022b4:	fc26                	sd	s1,56(sp)
    800022b6:	f84a                	sd	s2,48(sp)
    800022b8:	f44e                	sd	s3,40(sp)
    800022ba:	f052                	sd	s4,32(sp)
    800022bc:	ec56                	sd	s5,24(sp)
    800022be:	e85a                	sd	s6,16(sp)
    800022c0:	e45e                	sd	s7,8(sp)
    800022c2:	e062                	sd	s8,0(sp)
    800022c4:	0880                	addi	s0,sp,80
    800022c6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	80c080e7          	jalr	-2036(ra) # 80001ad4 <myproc>
    800022d0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022d2:	0000f517          	auipc	a0,0xf
    800022d6:	fe650513          	addi	a0,a0,-26 # 800112b8 <wait_lock>
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	90a080e7          	jalr	-1782(ra) # 80000be4 <acquire>
    havekids = 0;
    800022e2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022e4:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022e6:	00015997          	auipc	s3,0x15
    800022ea:	dea98993          	addi	s3,s3,-534 # 800170d0 <tickslock>
        havekids = 1;
    800022ee:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022f0:	0000fc17          	auipc	s8,0xf
    800022f4:	fc8c0c13          	addi	s8,s8,-56 # 800112b8 <wait_lock>
    havekids = 0;
    800022f8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022fa:	0000f497          	auipc	s1,0xf
    800022fe:	3d648493          	addi	s1,s1,982 # 800116d0 <proc>
    80002302:	a0bd                	j	80002370 <wait+0xc2>
          pid = np->pid;
    80002304:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002308:	000b0e63          	beqz	s6,80002324 <wait+0x76>
    8000230c:	4691                	li	a3,4
    8000230e:	02c48613          	addi	a2,s1,44
    80002312:	85da                	mv	a1,s6
    80002314:	05093503          	ld	a0,80(s2)
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	47e080e7          	jalr	1150(ra) # 80001796 <copyout>
    80002320:	02054563          	bltz	a0,8000234a <wait+0x9c>
          freeproc(np);
    80002324:	8526                	mv	a0,s1
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	960080e7          	jalr	-1696(ra) # 80001c86 <freeproc>
          release(&np->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	968080e7          	jalr	-1688(ra) # 80000c98 <release>
          release(&wait_lock);
    80002338:	0000f517          	auipc	a0,0xf
    8000233c:	f8050513          	addi	a0,a0,-128 # 800112b8 <wait_lock>
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	958080e7          	jalr	-1704(ra) # 80000c98 <release>
          return pid;
    80002348:	a09d                	j	800023ae <wait+0x100>
            release(&np->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	94c080e7          	jalr	-1716(ra) # 80000c98 <release>
            release(&wait_lock);
    80002354:	0000f517          	auipc	a0,0xf
    80002358:	f6450513          	addi	a0,a0,-156 # 800112b8 <wait_lock>
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	93c080e7          	jalr	-1732(ra) # 80000c98 <release>
            return -1;
    80002364:	59fd                	li	s3,-1
    80002366:	a0a1                	j	800023ae <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002368:	16848493          	addi	s1,s1,360
    8000236c:	03348463          	beq	s1,s3,80002394 <wait+0xe6>
      if(np->parent == p){
    80002370:	7c9c                	ld	a5,56(s1)
    80002372:	ff279be3          	bne	a5,s2,80002368 <wait+0xba>
        acquire(&np->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	86c080e7          	jalr	-1940(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002380:	4c9c                	lw	a5,24(s1)
    80002382:	f94781e3          	beq	a5,s4,80002304 <wait+0x56>
        release(&np->lock);
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
        havekids = 1;
    80002390:	8756                	mv	a4,s5
    80002392:	bfd9                	j	80002368 <wait+0xba>
    if(!havekids || p->killed){
    80002394:	c701                	beqz	a4,8000239c <wait+0xee>
    80002396:	02892783          	lw	a5,40(s2)
    8000239a:	c79d                	beqz	a5,800023c8 <wait+0x11a>
      release(&wait_lock);
    8000239c:	0000f517          	auipc	a0,0xf
    800023a0:	f1c50513          	addi	a0,a0,-228 # 800112b8 <wait_lock>
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
      return -1;
    800023ac:	59fd                	li	s3,-1
}
    800023ae:	854e                	mv	a0,s3
    800023b0:	60a6                	ld	ra,72(sp)
    800023b2:	6406                	ld	s0,64(sp)
    800023b4:	74e2                	ld	s1,56(sp)
    800023b6:	7942                	ld	s2,48(sp)
    800023b8:	79a2                	ld	s3,40(sp)
    800023ba:	7a02                	ld	s4,32(sp)
    800023bc:	6ae2                	ld	s5,24(sp)
    800023be:	6b42                	ld	s6,16(sp)
    800023c0:	6ba2                	ld	s7,8(sp)
    800023c2:	6c02                	ld	s8,0(sp)
    800023c4:	6161                	addi	sp,sp,80
    800023c6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023c8:	85e2                	mv	a1,s8
    800023ca:	854a                	mv	a0,s2
    800023cc:	00000097          	auipc	ra,0x0
    800023d0:	e7e080e7          	jalr	-386(ra) # 8000224a <sleep>
    havekids = 0;
    800023d4:	b715                	j	800022f8 <wait+0x4a>

00000000800023d6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023d6:	7139                	addi	sp,sp,-64
    800023d8:	fc06                	sd	ra,56(sp)
    800023da:	f822                	sd	s0,48(sp)
    800023dc:	f426                	sd	s1,40(sp)
    800023de:	f04a                	sd	s2,32(sp)
    800023e0:	ec4e                	sd	s3,24(sp)
    800023e2:	e852                	sd	s4,16(sp)
    800023e4:	e456                	sd	s5,8(sp)
    800023e6:	0080                	addi	s0,sp,64
    800023e8:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023ea:	0000f497          	auipc	s1,0xf
    800023ee:	2e648493          	addi	s1,s1,742 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023f2:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023f4:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f6:	00015917          	auipc	s2,0x15
    800023fa:	cda90913          	addi	s2,s2,-806 # 800170d0 <tickslock>
    800023fe:	a821                	j	80002416 <wakeup+0x40>
        p->state = RUNNABLE;
    80002400:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	892080e7          	jalr	-1902(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000240e:	16848493          	addi	s1,s1,360
    80002412:	03248463          	beq	s1,s2,8000243a <wakeup+0x64>
    if(p != myproc()){
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	6be080e7          	jalr	1726(ra) # 80001ad4 <myproc>
    8000241e:	fea488e3          	beq	s1,a0,8000240e <wakeup+0x38>
      acquire(&p->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	7c0080e7          	jalr	1984(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000242c:	4c9c                	lw	a5,24(s1)
    8000242e:	fd379be3          	bne	a5,s3,80002404 <wakeup+0x2e>
    80002432:	709c                	ld	a5,32(s1)
    80002434:	fd4798e3          	bne	a5,s4,80002404 <wakeup+0x2e>
    80002438:	b7e1                	j	80002400 <wakeup+0x2a>
    }
  }
}
    8000243a:	70e2                	ld	ra,56(sp)
    8000243c:	7442                	ld	s0,48(sp)
    8000243e:	74a2                	ld	s1,40(sp)
    80002440:	7902                	ld	s2,32(sp)
    80002442:	69e2                	ld	s3,24(sp)
    80002444:	6a42                	ld	s4,16(sp)
    80002446:	6aa2                	ld	s5,8(sp)
    80002448:	6121                	addi	sp,sp,64
    8000244a:	8082                	ret

000000008000244c <reparent>:
{
    8000244c:	7179                	addi	sp,sp,-48
    8000244e:	f406                	sd	ra,40(sp)
    80002450:	f022                	sd	s0,32(sp)
    80002452:	ec26                	sd	s1,24(sp)
    80002454:	e84a                	sd	s2,16(sp)
    80002456:	e44e                	sd	s3,8(sp)
    80002458:	e052                	sd	s4,0(sp)
    8000245a:	1800                	addi	s0,sp,48
    8000245c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000245e:	0000f497          	auipc	s1,0xf
    80002462:	27248493          	addi	s1,s1,626 # 800116d0 <proc>
      pp->parent = initproc;
    80002466:	00007a17          	auipc	s4,0x7
    8000246a:	bcaa0a13          	addi	s4,s4,-1078 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000246e:	00015997          	auipc	s3,0x15
    80002472:	c6298993          	addi	s3,s3,-926 # 800170d0 <tickslock>
    80002476:	a029                	j	80002480 <reparent+0x34>
    80002478:	16848493          	addi	s1,s1,360
    8000247c:	01348d63          	beq	s1,s3,80002496 <reparent+0x4a>
    if(pp->parent == p){
    80002480:	7c9c                	ld	a5,56(s1)
    80002482:	ff279be3          	bne	a5,s2,80002478 <reparent+0x2c>
      pp->parent = initproc;
    80002486:	000a3503          	ld	a0,0(s4)
    8000248a:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	f4a080e7          	jalr	-182(ra) # 800023d6 <wakeup>
    80002494:	b7d5                	j	80002478 <reparent+0x2c>
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6a02                	ld	s4,0(sp)
    800024a2:	6145                	addi	sp,sp,48
    800024a4:	8082                	ret

00000000800024a6 <exit>:
{
    800024a6:	7179                	addi	sp,sp,-48
    800024a8:	f406                	sd	ra,40(sp)
    800024aa:	f022                	sd	s0,32(sp)
    800024ac:	ec26                	sd	s1,24(sp)
    800024ae:	e84a                	sd	s2,16(sp)
    800024b0:	e44e                	sd	s3,8(sp)
    800024b2:	e052                	sd	s4,0(sp)
    800024b4:	1800                	addi	s0,sp,48
    800024b6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	61c080e7          	jalr	1564(ra) # 80001ad4 <myproc>
    800024c0:	89aa                	mv	s3,a0
  if(p == initproc)
    800024c2:	00007797          	auipc	a5,0x7
    800024c6:	b6e7b783          	ld	a5,-1170(a5) # 80009030 <initproc>
    800024ca:	0d050493          	addi	s1,a0,208
    800024ce:	15050913          	addi	s2,a0,336
    800024d2:	02a79363          	bne	a5,a0,800024f8 <exit+0x52>
    panic("init exiting");
    800024d6:	00006517          	auipc	a0,0x6
    800024da:	dca50513          	addi	a0,a0,-566 # 800082a0 <digits+0x260>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	060080e7          	jalr	96(ra) # 8000053e <panic>
      fileclose(f);
    800024e6:	00002097          	auipc	ra,0x2
    800024ea:	1f8080e7          	jalr	504(ra) # 800046de <fileclose>
      p->ofile[fd] = 0;
    800024ee:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024f2:	04a1                	addi	s1,s1,8
    800024f4:	01248563          	beq	s1,s2,800024fe <exit+0x58>
    if(p->ofile[fd]){
    800024f8:	6088                	ld	a0,0(s1)
    800024fa:	f575                	bnez	a0,800024e6 <exit+0x40>
    800024fc:	bfdd                	j	800024f2 <exit+0x4c>
  begin_op();
    800024fe:	00002097          	auipc	ra,0x2
    80002502:	d14080e7          	jalr	-748(ra) # 80004212 <begin_op>
  iput(p->cwd);
    80002506:	1509b503          	ld	a0,336(s3)
    8000250a:	00001097          	auipc	ra,0x1
    8000250e:	4f0080e7          	jalr	1264(ra) # 800039fa <iput>
  end_op();
    80002512:	00002097          	auipc	ra,0x2
    80002516:	d80080e7          	jalr	-640(ra) # 80004292 <end_op>
  p->cwd = 0;
    8000251a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000251e:	0000f497          	auipc	s1,0xf
    80002522:	d9a48493          	addi	s1,s1,-614 # 800112b8 <wait_lock>
    80002526:	8526                	mv	a0,s1
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	6bc080e7          	jalr	1724(ra) # 80000be4 <acquire>
  reparent(p);
    80002530:	854e                	mv	a0,s3
    80002532:	00000097          	auipc	ra,0x0
    80002536:	f1a080e7          	jalr	-230(ra) # 8000244c <reparent>
  wakeup(p->parent);
    8000253a:	0389b503          	ld	a0,56(s3)
    8000253e:	00000097          	auipc	ra,0x0
    80002542:	e98080e7          	jalr	-360(ra) # 800023d6 <wakeup>
  acquire(&p->lock);
    80002546:	854e                	mv	a0,s3
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	69c080e7          	jalr	1692(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002550:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002554:	4795                	li	a5,5
    80002556:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	73c080e7          	jalr	1852(ra) # 80000c98 <release>
  sched();
    80002564:	00000097          	auipc	ra,0x0
    80002568:	b62080e7          	jalr	-1182(ra) # 800020c6 <sched>
  panic("zombie exit");
    8000256c:	00006517          	auipc	a0,0x6
    80002570:	d4450513          	addi	a0,a0,-700 # 800082b0 <digits+0x270>
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	fca080e7          	jalr	-54(ra) # 8000053e <panic>

000000008000257c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000257c:	7179                	addi	sp,sp,-48
    8000257e:	f406                	sd	ra,40(sp)
    80002580:	f022                	sd	s0,32(sp)
    80002582:	ec26                	sd	s1,24(sp)
    80002584:	e84a                	sd	s2,16(sp)
    80002586:	e44e                	sd	s3,8(sp)
    80002588:	1800                	addi	s0,sp,48
    8000258a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000258c:	0000f497          	auipc	s1,0xf
    80002590:	14448493          	addi	s1,s1,324 # 800116d0 <proc>
    80002594:	00015997          	auipc	s3,0x15
    80002598:	b3c98993          	addi	s3,s3,-1220 # 800170d0 <tickslock>
    acquire(&p->lock);
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	646080e7          	jalr	1606(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025a6:	589c                	lw	a5,48(s1)
    800025a8:	01278d63          	beq	a5,s2,800025c2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b6:	16848493          	addi	s1,s1,360
    800025ba:	ff3491e3          	bne	s1,s3,8000259c <kill+0x20>
  }
  return -1;
    800025be:	557d                	li	a0,-1
    800025c0:	a829                	j	800025da <kill+0x5e>
      p->killed = 1;
    800025c2:	4785                	li	a5,1
    800025c4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025c6:	4c98                	lw	a4,24(s1)
    800025c8:	4789                	li	a5,2
    800025ca:	00f70f63          	beq	a4,a5,800025e8 <kill+0x6c>
      release(&p->lock);
    800025ce:	8526                	mv	a0,s1
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6c8080e7          	jalr	1736(ra) # 80000c98 <release>
      return 0;
    800025d8:	4501                	li	a0,0
}
    800025da:	70a2                	ld	ra,40(sp)
    800025dc:	7402                	ld	s0,32(sp)
    800025de:	64e2                	ld	s1,24(sp)
    800025e0:	6942                	ld	s2,16(sp)
    800025e2:	69a2                	ld	s3,8(sp)
    800025e4:	6145                	addi	sp,sp,48
    800025e6:	8082                	ret
        p->state = RUNNABLE;
    800025e8:	478d                	li	a5,3
    800025ea:	cc9c                	sw	a5,24(s1)
    800025ec:	b7cd                	j	800025ce <kill+0x52>

00000000800025ee <kill_system>:
{
    800025ee:	7179                	addi	sp,sp,-48
    800025f0:	f406                	sd	ra,40(sp)
    800025f2:	f022                	sd	s0,32(sp)
    800025f4:	ec26                	sd	s1,24(sp)
    800025f6:	e84a                	sd	s2,16(sp)
    800025f8:	e44e                	sd	s3,8(sp)
    800025fa:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    800025fc:	0000f497          	auipc	s1,0xf
    80002600:	0d448493          	addi	s1,s1,212 # 800116d0 <proc>
    if (p->pid > 2) // init process and shell?
    80002604:	4989                	li	s3,2
  for (p = proc; p < &proc[NPROC]; p++)
    80002606:	00015917          	auipc	s2,0x15
    8000260a:	aca90913          	addi	s2,s2,-1334 # 800170d0 <tickslock>
    8000260e:	a809                	j	80002620 <kill_system+0x32>
      kill(p->pid);
    80002610:	00000097          	auipc	ra,0x0
    80002614:	f6c080e7          	jalr	-148(ra) # 8000257c <kill>
  for (p = proc; p < &proc[NPROC]; p++)
    80002618:	16848493          	addi	s1,s1,360
    8000261c:	01248663          	beq	s1,s2,80002628 <kill_system+0x3a>
    if (p->pid > 2) // init process and shell?
    80002620:	5888                	lw	a0,48(s1)
    80002622:	fea9dbe3          	bge	s3,a0,80002618 <kill_system+0x2a>
    80002626:	b7ed                	j	80002610 <kill_system+0x22>
}
    80002628:	4501                	li	a0,0
    8000262a:	70a2                	ld	ra,40(sp)
    8000262c:	7402                	ld	s0,32(sp)
    8000262e:	64e2                	ld	s1,24(sp)
    80002630:	6942                	ld	s2,16(sp)
    80002632:	69a2                	ld	s3,8(sp)
    80002634:	6145                	addi	sp,sp,48
    80002636:	8082                	ret

0000000080002638 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002638:	7179                	addi	sp,sp,-48
    8000263a:	f406                	sd	ra,40(sp)
    8000263c:	f022                	sd	s0,32(sp)
    8000263e:	ec26                	sd	s1,24(sp)
    80002640:	e84a                	sd	s2,16(sp)
    80002642:	e44e                	sd	s3,8(sp)
    80002644:	e052                	sd	s4,0(sp)
    80002646:	1800                	addi	s0,sp,48
    80002648:	84aa                	mv	s1,a0
    8000264a:	892e                	mv	s2,a1
    8000264c:	89b2                	mv	s3,a2
    8000264e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	484080e7          	jalr	1156(ra) # 80001ad4 <myproc>
  if(user_dst){
    80002658:	c08d                	beqz	s1,8000267a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000265a:	86d2                	mv	a3,s4
    8000265c:	864e                	mv	a2,s3
    8000265e:	85ca                	mv	a1,s2
    80002660:	6928                	ld	a0,80(a0)
    80002662:	fffff097          	auipc	ra,0xfffff
    80002666:	134080e7          	jalr	308(ra) # 80001796 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000266a:	70a2                	ld	ra,40(sp)
    8000266c:	7402                	ld	s0,32(sp)
    8000266e:	64e2                	ld	s1,24(sp)
    80002670:	6942                	ld	s2,16(sp)
    80002672:	69a2                	ld	s3,8(sp)
    80002674:	6a02                	ld	s4,0(sp)
    80002676:	6145                	addi	sp,sp,48
    80002678:	8082                	ret
    memmove((char *)dst, src, len);
    8000267a:	000a061b          	sext.w	a2,s4
    8000267e:	85ce                	mv	a1,s3
    80002680:	854a                	mv	a0,s2
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	6be080e7          	jalr	1726(ra) # 80000d40 <memmove>
    return 0;
    8000268a:	8526                	mv	a0,s1
    8000268c:	bff9                	j	8000266a <either_copyout+0x32>

000000008000268e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000268e:	7179                	addi	sp,sp,-48
    80002690:	f406                	sd	ra,40(sp)
    80002692:	f022                	sd	s0,32(sp)
    80002694:	ec26                	sd	s1,24(sp)
    80002696:	e84a                	sd	s2,16(sp)
    80002698:	e44e                	sd	s3,8(sp)
    8000269a:	e052                	sd	s4,0(sp)
    8000269c:	1800                	addi	s0,sp,48
    8000269e:	892a                	mv	s2,a0
    800026a0:	84ae                	mv	s1,a1
    800026a2:	89b2                	mv	s3,a2
    800026a4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026a6:	fffff097          	auipc	ra,0xfffff
    800026aa:	42e080e7          	jalr	1070(ra) # 80001ad4 <myproc>
  if(user_src){
    800026ae:	c08d                	beqz	s1,800026d0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026b0:	86d2                	mv	a3,s4
    800026b2:	864e                	mv	a2,s3
    800026b4:	85ca                	mv	a1,s2
    800026b6:	6928                	ld	a0,80(a0)
    800026b8:	fffff097          	auipc	ra,0xfffff
    800026bc:	16a080e7          	jalr	362(ra) # 80001822 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026c0:	70a2                	ld	ra,40(sp)
    800026c2:	7402                	ld	s0,32(sp)
    800026c4:	64e2                	ld	s1,24(sp)
    800026c6:	6942                	ld	s2,16(sp)
    800026c8:	69a2                	ld	s3,8(sp)
    800026ca:	6a02                	ld	s4,0(sp)
    800026cc:	6145                	addi	sp,sp,48
    800026ce:	8082                	ret
    memmove(dst, (char*)src, len);
    800026d0:	000a061b          	sext.w	a2,s4
    800026d4:	85ce                	mv	a1,s3
    800026d6:	854a                	mv	a0,s2
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	668080e7          	jalr	1640(ra) # 80000d40 <memmove>
    return 0;
    800026e0:	8526                	mv	a0,s1
    800026e2:	bff9                	j	800026c0 <either_copyin+0x32>

00000000800026e4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026e4:	715d                	addi	sp,sp,-80
    800026e6:	e486                	sd	ra,72(sp)
    800026e8:	e0a2                	sd	s0,64(sp)
    800026ea:	fc26                	sd	s1,56(sp)
    800026ec:	f84a                	sd	s2,48(sp)
    800026ee:	f44e                	sd	s3,40(sp)
    800026f0:	f052                	sd	s4,32(sp)
    800026f2:	ec56                	sd	s5,24(sp)
    800026f4:	e85a                	sd	s6,16(sp)
    800026f6:	e45e                	sd	s7,8(sp)
    800026f8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026fa:	00006517          	auipc	a0,0x6
    800026fe:	a0e50513          	addi	a0,a0,-1522 # 80008108 <digits+0xc8>
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	e86080e7          	jalr	-378(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000270a:	0000f497          	auipc	s1,0xf
    8000270e:	11e48493          	addi	s1,s1,286 # 80011828 <proc+0x158>
    80002712:	00015917          	auipc	s2,0x15
    80002716:	b1690913          	addi	s2,s2,-1258 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000271a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000271c:	00006997          	auipc	s3,0x6
    80002720:	ba498993          	addi	s3,s3,-1116 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    80002724:	00006a97          	auipc	s5,0x6
    80002728:	ba4a8a93          	addi	s5,s5,-1116 # 800082c8 <digits+0x288>
    printf("\n");
    8000272c:	00006a17          	auipc	s4,0x6
    80002730:	9dca0a13          	addi	s4,s4,-1572 # 80008108 <digits+0xc8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002734:	00006b97          	auipc	s7,0x6
    80002738:	bccb8b93          	addi	s7,s7,-1076 # 80008300 <states.1736>
    8000273c:	a00d                	j	8000275e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000273e:	ed86a583          	lw	a1,-296(a3)
    80002742:	8556                	mv	a0,s5
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	e44080e7          	jalr	-444(ra) # 80000588 <printf>
    printf("\n");
    8000274c:	8552                	mv	a0,s4
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	e3a080e7          	jalr	-454(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002756:	16848493          	addi	s1,s1,360
    8000275a:	03248163          	beq	s1,s2,8000277c <procdump+0x98>
    if(p->state == UNUSED)
    8000275e:	86a6                	mv	a3,s1
    80002760:	ec04a783          	lw	a5,-320(s1)
    80002764:	dbed                	beqz	a5,80002756 <procdump+0x72>
      state = "???";
    80002766:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002768:	fcfb6be3          	bltu	s6,a5,8000273e <procdump+0x5a>
    8000276c:	1782                	slli	a5,a5,0x20
    8000276e:	9381                	srli	a5,a5,0x20
    80002770:	078e                	slli	a5,a5,0x3
    80002772:	97de                	add	a5,a5,s7
    80002774:	6390                	ld	a2,0(a5)
    80002776:	f661                	bnez	a2,8000273e <procdump+0x5a>
      state = "???";
    80002778:	864e                	mv	a2,s3
    8000277a:	b7d1                	j	8000273e <procdump+0x5a>
  }
}
    8000277c:	60a6                	ld	ra,72(sp)
    8000277e:	6406                	ld	s0,64(sp)
    80002780:	74e2                	ld	s1,56(sp)
    80002782:	7942                	ld	s2,48(sp)
    80002784:	79a2                	ld	s3,40(sp)
    80002786:	7a02                	ld	s4,32(sp)
    80002788:	6ae2                	ld	s5,24(sp)
    8000278a:	6b42                	ld	s6,16(sp)
    8000278c:	6ba2                	ld	s7,8(sp)
    8000278e:	6161                	addi	sp,sp,80
    80002790:	8082                	ret

0000000080002792 <swtch>:
    80002792:	00153023          	sd	ra,0(a0)
    80002796:	00253423          	sd	sp,8(a0)
    8000279a:	e900                	sd	s0,16(a0)
    8000279c:	ed04                	sd	s1,24(a0)
    8000279e:	03253023          	sd	s2,32(a0)
    800027a2:	03353423          	sd	s3,40(a0)
    800027a6:	03453823          	sd	s4,48(a0)
    800027aa:	03553c23          	sd	s5,56(a0)
    800027ae:	05653023          	sd	s6,64(a0)
    800027b2:	05753423          	sd	s7,72(a0)
    800027b6:	05853823          	sd	s8,80(a0)
    800027ba:	05953c23          	sd	s9,88(a0)
    800027be:	07a53023          	sd	s10,96(a0)
    800027c2:	07b53423          	sd	s11,104(a0)
    800027c6:	0005b083          	ld	ra,0(a1)
    800027ca:	0085b103          	ld	sp,8(a1)
    800027ce:	6980                	ld	s0,16(a1)
    800027d0:	6d84                	ld	s1,24(a1)
    800027d2:	0205b903          	ld	s2,32(a1)
    800027d6:	0285b983          	ld	s3,40(a1)
    800027da:	0305ba03          	ld	s4,48(a1)
    800027de:	0385ba83          	ld	s5,56(a1)
    800027e2:	0405bb03          	ld	s6,64(a1)
    800027e6:	0485bb83          	ld	s7,72(a1)
    800027ea:	0505bc03          	ld	s8,80(a1)
    800027ee:	0585bc83          	ld	s9,88(a1)
    800027f2:	0605bd03          	ld	s10,96(a1)
    800027f6:	0685bd83          	ld	s11,104(a1)
    800027fa:	8082                	ret

00000000800027fc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027fc:	1141                	addi	sp,sp,-16
    800027fe:	e406                	sd	ra,8(sp)
    80002800:	e022                	sd	s0,0(sp)
    80002802:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002804:	00006597          	auipc	a1,0x6
    80002808:	b2c58593          	addi	a1,a1,-1236 # 80008330 <states.1736+0x30>
    8000280c:	00015517          	auipc	a0,0x15
    80002810:	8c450513          	addi	a0,a0,-1852 # 800170d0 <tickslock>
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	340080e7          	jalr	832(ra) # 80000b54 <initlock>
}
    8000281c:	60a2                	ld	ra,8(sp)
    8000281e:	6402                	ld	s0,0(sp)
    80002820:	0141                	addi	sp,sp,16
    80002822:	8082                	ret

0000000080002824 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002824:	1141                	addi	sp,sp,-16
    80002826:	e422                	sd	s0,8(sp)
    80002828:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000282a:	00003797          	auipc	a5,0x3
    8000282e:	4d678793          	addi	a5,a5,1238 # 80005d00 <kernelvec>
    80002832:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002836:	6422                	ld	s0,8(sp)
    80002838:	0141                	addi	sp,sp,16
    8000283a:	8082                	ret

000000008000283c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000283c:	1141                	addi	sp,sp,-16
    8000283e:	e406                	sd	ra,8(sp)
    80002840:	e022                	sd	s0,0(sp)
    80002842:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	290080e7          	jalr	656(ra) # 80001ad4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000284c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002850:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002852:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002856:	00004617          	auipc	a2,0x4
    8000285a:	7aa60613          	addi	a2,a2,1962 # 80007000 <_trampoline>
    8000285e:	00004697          	auipc	a3,0x4
    80002862:	7a268693          	addi	a3,a3,1954 # 80007000 <_trampoline>
    80002866:	8e91                	sub	a3,a3,a2
    80002868:	040007b7          	lui	a5,0x4000
    8000286c:	17fd                	addi	a5,a5,-1
    8000286e:	07b2                	slli	a5,a5,0xc
    80002870:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002872:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002876:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002878:	180026f3          	csrr	a3,satp
    8000287c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000287e:	6d38                	ld	a4,88(a0)
    80002880:	6134                	ld	a3,64(a0)
    80002882:	6585                	lui	a1,0x1
    80002884:	96ae                	add	a3,a3,a1
    80002886:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002888:	6d38                	ld	a4,88(a0)
    8000288a:	00000697          	auipc	a3,0x0
    8000288e:	13868693          	addi	a3,a3,312 # 800029c2 <usertrap>
    80002892:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002894:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002896:	8692                	mv	a3,tp
    80002898:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000289e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028a2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028aa:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ac:	6f18                	ld	a4,24(a4)
    800028ae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028b2:	692c                	ld	a1,80(a0)
    800028b4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028b6:	00004717          	auipc	a4,0x4
    800028ba:	7da70713          	addi	a4,a4,2010 # 80007090 <userret>
    800028be:	8f11                	sub	a4,a4,a2
    800028c0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028c2:	577d                	li	a4,-1
    800028c4:	177e                	slli	a4,a4,0x3f
    800028c6:	8dd9                	or	a1,a1,a4
    800028c8:	02000537          	lui	a0,0x2000
    800028cc:	157d                	addi	a0,a0,-1
    800028ce:	0536                	slli	a0,a0,0xd
    800028d0:	9782                	jalr	a5
}
    800028d2:	60a2                	ld	ra,8(sp)
    800028d4:	6402                	ld	s0,0(sp)
    800028d6:	0141                	addi	sp,sp,16
    800028d8:	8082                	ret

00000000800028da <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028da:	1101                	addi	sp,sp,-32
    800028dc:	ec06                	sd	ra,24(sp)
    800028de:	e822                	sd	s0,16(sp)
    800028e0:	e426                	sd	s1,8(sp)
    800028e2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028e4:	00014497          	auipc	s1,0x14
    800028e8:	7ec48493          	addi	s1,s1,2028 # 800170d0 <tickslock>
    800028ec:	8526                	mv	a0,s1
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	2f6080e7          	jalr	758(ra) # 80000be4 <acquire>
  ticks++;
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	74250513          	addi	a0,a0,1858 # 80009038 <ticks>
    800028fe:	411c                	lw	a5,0(a0)
    80002900:	2785                	addiw	a5,a5,1
    80002902:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002904:	00000097          	auipc	ra,0x0
    80002908:	ad2080e7          	jalr	-1326(ra) # 800023d6 <wakeup>
  release(&tickslock);
    8000290c:	8526                	mv	a0,s1
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	38a080e7          	jalr	906(ra) # 80000c98 <release>
}
    80002916:	60e2                	ld	ra,24(sp)
    80002918:	6442                	ld	s0,16(sp)
    8000291a:	64a2                	ld	s1,8(sp)
    8000291c:	6105                	addi	sp,sp,32
    8000291e:	8082                	ret

0000000080002920 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002920:	1101                	addi	sp,sp,-32
    80002922:	ec06                	sd	ra,24(sp)
    80002924:	e822                	sd	s0,16(sp)
    80002926:	e426                	sd	s1,8(sp)
    80002928:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000292a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000292e:	00074d63          	bltz	a4,80002948 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002932:	57fd                	li	a5,-1
    80002934:	17fe                	slli	a5,a5,0x3f
    80002936:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002938:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000293a:	06f70363          	beq	a4,a5,800029a0 <devintr+0x80>
  }
}
    8000293e:	60e2                	ld	ra,24(sp)
    80002940:	6442                	ld	s0,16(sp)
    80002942:	64a2                	ld	s1,8(sp)
    80002944:	6105                	addi	sp,sp,32
    80002946:	8082                	ret
     (scause & 0xff) == 9){
    80002948:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000294c:	46a5                	li	a3,9
    8000294e:	fed792e3          	bne	a5,a3,80002932 <devintr+0x12>
    int irq = plic_claim();
    80002952:	00003097          	auipc	ra,0x3
    80002956:	4b6080e7          	jalr	1206(ra) # 80005e08 <plic_claim>
    8000295a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000295c:	47a9                	li	a5,10
    8000295e:	02f50763          	beq	a0,a5,8000298c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002962:	4785                	li	a5,1
    80002964:	02f50963          	beq	a0,a5,80002996 <devintr+0x76>
    return 1;
    80002968:	4505                	li	a0,1
    } else if(irq){
    8000296a:	d8f1                	beqz	s1,8000293e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000296c:	85a6                	mv	a1,s1
    8000296e:	00006517          	auipc	a0,0x6
    80002972:	9ca50513          	addi	a0,a0,-1590 # 80008338 <states.1736+0x38>
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	c12080e7          	jalr	-1006(ra) # 80000588 <printf>
      plic_complete(irq);
    8000297e:	8526                	mv	a0,s1
    80002980:	00003097          	auipc	ra,0x3
    80002984:	4ac080e7          	jalr	1196(ra) # 80005e2c <plic_complete>
    return 1;
    80002988:	4505                	li	a0,1
    8000298a:	bf55                	j	8000293e <devintr+0x1e>
      uartintr();
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	01c080e7          	jalr	28(ra) # 800009a8 <uartintr>
    80002994:	b7ed                	j	8000297e <devintr+0x5e>
      virtio_disk_intr();
    80002996:	00004097          	auipc	ra,0x4
    8000299a:	976080e7          	jalr	-1674(ra) # 8000630c <virtio_disk_intr>
    8000299e:	b7c5                	j	8000297e <devintr+0x5e>
    if(cpuid() == 0){
    800029a0:	fffff097          	auipc	ra,0xfffff
    800029a4:	108080e7          	jalr	264(ra) # 80001aa8 <cpuid>
    800029a8:	c901                	beqz	a0,800029b8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029aa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029ae:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029b0:	14479073          	csrw	sip,a5
    return 2;
    800029b4:	4509                	li	a0,2
    800029b6:	b761                	j	8000293e <devintr+0x1e>
      clockintr();
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	f22080e7          	jalr	-222(ra) # 800028da <clockintr>
    800029c0:	b7ed                	j	800029aa <devintr+0x8a>

00000000800029c2 <usertrap>:
{
    800029c2:	1101                	addi	sp,sp,-32
    800029c4:	ec06                	sd	ra,24(sp)
    800029c6:	e822                	sd	s0,16(sp)
    800029c8:	e426                	sd	s1,8(sp)
    800029ca:	e04a                	sd	s2,0(sp)
    800029cc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ce:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029d2:	1007f793          	andi	a5,a5,256
    800029d6:	e3ad                	bnez	a5,80002a38 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029d8:	00003797          	auipc	a5,0x3
    800029dc:	32878793          	addi	a5,a5,808 # 80005d00 <kernelvec>
    800029e0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029e4:	fffff097          	auipc	ra,0xfffff
    800029e8:	0f0080e7          	jalr	240(ra) # 80001ad4 <myproc>
    800029ec:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029ee:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f0:	14102773          	csrr	a4,sepc
    800029f4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029fa:	47a1                	li	a5,8
    800029fc:	04f71c63          	bne	a4,a5,80002a54 <usertrap+0x92>
    if(p->killed)
    80002a00:	551c                	lw	a5,40(a0)
    80002a02:	e3b9                	bnez	a5,80002a48 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a04:	6cb8                	ld	a4,88(s1)
    80002a06:	6f1c                	ld	a5,24(a4)
    80002a08:	0791                	addi	a5,a5,4
    80002a0a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a10:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a14:	10079073          	csrw	sstatus,a5
    syscall();
    80002a18:	00000097          	auipc	ra,0x0
    80002a1c:	2e0080e7          	jalr	736(ra) # 80002cf8 <syscall>
  if(p->killed)
    80002a20:	549c                	lw	a5,40(s1)
    80002a22:	ebc1                	bnez	a5,80002ab2 <usertrap+0xf0>
  usertrapret();
    80002a24:	00000097          	auipc	ra,0x0
    80002a28:	e18080e7          	jalr	-488(ra) # 8000283c <usertrapret>
}
    80002a2c:	60e2                	ld	ra,24(sp)
    80002a2e:	6442                	ld	s0,16(sp)
    80002a30:	64a2                	ld	s1,8(sp)
    80002a32:	6902                	ld	s2,0(sp)
    80002a34:	6105                	addi	sp,sp,32
    80002a36:	8082                	ret
    panic("usertrap: not from user mode");
    80002a38:	00006517          	auipc	a0,0x6
    80002a3c:	92050513          	addi	a0,a0,-1760 # 80008358 <states.1736+0x58>
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	afe080e7          	jalr	-1282(ra) # 8000053e <panic>
      exit(-1);
    80002a48:	557d                	li	a0,-1
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	a5c080e7          	jalr	-1444(ra) # 800024a6 <exit>
    80002a52:	bf4d                	j	80002a04 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a54:	00000097          	auipc	ra,0x0
    80002a58:	ecc080e7          	jalr	-308(ra) # 80002920 <devintr>
    80002a5c:	892a                	mv	s2,a0
    80002a5e:	c501                	beqz	a0,80002a66 <usertrap+0xa4>
  if(p->killed)
    80002a60:	549c                	lw	a5,40(s1)
    80002a62:	c3a1                	beqz	a5,80002aa2 <usertrap+0xe0>
    80002a64:	a815                	j	80002a98 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a66:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a6a:	5890                	lw	a2,48(s1)
    80002a6c:	00006517          	auipc	a0,0x6
    80002a70:	90c50513          	addi	a0,a0,-1780 # 80008378 <states.1736+0x78>
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	b14080e7          	jalr	-1260(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a7c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a80:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a84:	00006517          	auipc	a0,0x6
    80002a88:	92450513          	addi	a0,a0,-1756 # 800083a8 <states.1736+0xa8>
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	afc080e7          	jalr	-1284(ra) # 80000588 <printf>
    p->killed = 1;
    80002a94:	4785                	li	a5,1
    80002a96:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a98:	557d                	li	a0,-1
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	a0c080e7          	jalr	-1524(ra) # 800024a6 <exit>
  if(which_dev == 2)
    80002aa2:	4789                	li	a5,2
    80002aa4:	f8f910e3          	bne	s2,a5,80002a24 <usertrap+0x62>
    yield();
    80002aa8:	fffff097          	auipc	ra,0xfffff
    80002aac:	6f4080e7          	jalr	1780(ra) # 8000219c <yield>
    80002ab0:	bf95                	j	80002a24 <usertrap+0x62>
  int which_dev = 0;
    80002ab2:	4901                	li	s2,0
    80002ab4:	b7d5                	j	80002a98 <usertrap+0xd6>

0000000080002ab6 <kerneltrap>:
{
    80002ab6:	7179                	addi	sp,sp,-48
    80002ab8:	f406                	sd	ra,40(sp)
    80002aba:	f022                	sd	s0,32(sp)
    80002abc:	ec26                	sd	s1,24(sp)
    80002abe:	e84a                	sd	s2,16(sp)
    80002ac0:	e44e                	sd	s3,8(sp)
    80002ac2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002acc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002ad0:	1004f793          	andi	a5,s1,256
    80002ad4:	cb85                	beqz	a5,80002b04 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ad6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ada:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002adc:	ef85                	bnez	a5,80002b14 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	e42080e7          	jalr	-446(ra) # 80002920 <devintr>
    80002ae6:	cd1d                	beqz	a0,80002b24 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ae8:	4789                	li	a5,2
    80002aea:	06f50a63          	beq	a0,a5,80002b5e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002aee:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af2:	10049073          	csrw	sstatus,s1
}
    80002af6:	70a2                	ld	ra,40(sp)
    80002af8:	7402                	ld	s0,32(sp)
    80002afa:	64e2                	ld	s1,24(sp)
    80002afc:	6942                	ld	s2,16(sp)
    80002afe:	69a2                	ld	s3,8(sp)
    80002b00:	6145                	addi	sp,sp,48
    80002b02:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	8c450513          	addi	a0,a0,-1852 # 800083c8 <states.1736+0xc8>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a32080e7          	jalr	-1486(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	8dc50513          	addi	a0,a0,-1828 # 800083f0 <states.1736+0xf0>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a22080e7          	jalr	-1502(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b24:	85ce                	mv	a1,s3
    80002b26:	00006517          	auipc	a0,0x6
    80002b2a:	8ea50513          	addi	a0,a0,-1814 # 80008410 <states.1736+0x110>
    80002b2e:	ffffe097          	auipc	ra,0xffffe
    80002b32:	a5a080e7          	jalr	-1446(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b36:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b3a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b3e:	00006517          	auipc	a0,0x6
    80002b42:	8e250513          	addi	a0,a0,-1822 # 80008420 <states.1736+0x120>
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	a42080e7          	jalr	-1470(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b4e:	00006517          	auipc	a0,0x6
    80002b52:	8ea50513          	addi	a0,a0,-1814 # 80008438 <states.1736+0x138>
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	9e8080e7          	jalr	-1560(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b5e:	fffff097          	auipc	ra,0xfffff
    80002b62:	f76080e7          	jalr	-138(ra) # 80001ad4 <myproc>
    80002b66:	d541                	beqz	a0,80002aee <kerneltrap+0x38>
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	f6c080e7          	jalr	-148(ra) # 80001ad4 <myproc>
    80002b70:	4d18                	lw	a4,24(a0)
    80002b72:	4791                	li	a5,4
    80002b74:	f6f71de3          	bne	a4,a5,80002aee <kerneltrap+0x38>
    yield();
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	624080e7          	jalr	1572(ra) # 8000219c <yield>
    80002b80:	b7bd                	j	80002aee <kerneltrap+0x38>

0000000080002b82 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b82:	1101                	addi	sp,sp,-32
    80002b84:	ec06                	sd	ra,24(sp)
    80002b86:	e822                	sd	s0,16(sp)
    80002b88:	e426                	sd	s1,8(sp)
    80002b8a:	1000                	addi	s0,sp,32
    80002b8c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	f46080e7          	jalr	-186(ra) # 80001ad4 <myproc>
  switch (n) {
    80002b96:	4795                	li	a5,5
    80002b98:	0497e163          	bltu	a5,s1,80002bda <argraw+0x58>
    80002b9c:	048a                	slli	s1,s1,0x2
    80002b9e:	00006717          	auipc	a4,0x6
    80002ba2:	8d270713          	addi	a4,a4,-1838 # 80008470 <states.1736+0x170>
    80002ba6:	94ba                	add	s1,s1,a4
    80002ba8:	409c                	lw	a5,0(s1)
    80002baa:	97ba                	add	a5,a5,a4
    80002bac:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bae:	6d3c                	ld	a5,88(a0)
    80002bb0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bb2:	60e2                	ld	ra,24(sp)
    80002bb4:	6442                	ld	s0,16(sp)
    80002bb6:	64a2                	ld	s1,8(sp)
    80002bb8:	6105                	addi	sp,sp,32
    80002bba:	8082                	ret
    return p->trapframe->a1;
    80002bbc:	6d3c                	ld	a5,88(a0)
    80002bbe:	7fa8                	ld	a0,120(a5)
    80002bc0:	bfcd                	j	80002bb2 <argraw+0x30>
    return p->trapframe->a2;
    80002bc2:	6d3c                	ld	a5,88(a0)
    80002bc4:	63c8                	ld	a0,128(a5)
    80002bc6:	b7f5                	j	80002bb2 <argraw+0x30>
    return p->trapframe->a3;
    80002bc8:	6d3c                	ld	a5,88(a0)
    80002bca:	67c8                	ld	a0,136(a5)
    80002bcc:	b7dd                	j	80002bb2 <argraw+0x30>
    return p->trapframe->a4;
    80002bce:	6d3c                	ld	a5,88(a0)
    80002bd0:	6bc8                	ld	a0,144(a5)
    80002bd2:	b7c5                	j	80002bb2 <argraw+0x30>
    return p->trapframe->a5;
    80002bd4:	6d3c                	ld	a5,88(a0)
    80002bd6:	6fc8                	ld	a0,152(a5)
    80002bd8:	bfe9                	j	80002bb2 <argraw+0x30>
  panic("argraw");
    80002bda:	00006517          	auipc	a0,0x6
    80002bde:	86e50513          	addi	a0,a0,-1938 # 80008448 <states.1736+0x148>
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	95c080e7          	jalr	-1700(ra) # 8000053e <panic>

0000000080002bea <fetchaddr>:
{
    80002bea:	1101                	addi	sp,sp,-32
    80002bec:	ec06                	sd	ra,24(sp)
    80002bee:	e822                	sd	s0,16(sp)
    80002bf0:	e426                	sd	s1,8(sp)
    80002bf2:	e04a                	sd	s2,0(sp)
    80002bf4:	1000                	addi	s0,sp,32
    80002bf6:	84aa                	mv	s1,a0
    80002bf8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	eda080e7          	jalr	-294(ra) # 80001ad4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c02:	653c                	ld	a5,72(a0)
    80002c04:	02f4f863          	bgeu	s1,a5,80002c34 <fetchaddr+0x4a>
    80002c08:	00848713          	addi	a4,s1,8
    80002c0c:	02e7e663          	bltu	a5,a4,80002c38 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c10:	46a1                	li	a3,8
    80002c12:	8626                	mv	a2,s1
    80002c14:	85ca                	mv	a1,s2
    80002c16:	6928                	ld	a0,80(a0)
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	c0a080e7          	jalr	-1014(ra) # 80001822 <copyin>
    80002c20:	00a03533          	snez	a0,a0
    80002c24:	40a00533          	neg	a0,a0
}
    80002c28:	60e2                	ld	ra,24(sp)
    80002c2a:	6442                	ld	s0,16(sp)
    80002c2c:	64a2                	ld	s1,8(sp)
    80002c2e:	6902                	ld	s2,0(sp)
    80002c30:	6105                	addi	sp,sp,32
    80002c32:	8082                	ret
    return -1;
    80002c34:	557d                	li	a0,-1
    80002c36:	bfcd                	j	80002c28 <fetchaddr+0x3e>
    80002c38:	557d                	li	a0,-1
    80002c3a:	b7fd                	j	80002c28 <fetchaddr+0x3e>

0000000080002c3c <fetchstr>:
{
    80002c3c:	7179                	addi	sp,sp,-48
    80002c3e:	f406                	sd	ra,40(sp)
    80002c40:	f022                	sd	s0,32(sp)
    80002c42:	ec26                	sd	s1,24(sp)
    80002c44:	e84a                	sd	s2,16(sp)
    80002c46:	e44e                	sd	s3,8(sp)
    80002c48:	1800                	addi	s0,sp,48
    80002c4a:	892a                	mv	s2,a0
    80002c4c:	84ae                	mv	s1,a1
    80002c4e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	e84080e7          	jalr	-380(ra) # 80001ad4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c58:	86ce                	mv	a3,s3
    80002c5a:	864a                	mv	a2,s2
    80002c5c:	85a6                	mv	a1,s1
    80002c5e:	6928                	ld	a0,80(a0)
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	c4e080e7          	jalr	-946(ra) # 800018ae <copyinstr>
  if(err < 0)
    80002c68:	00054763          	bltz	a0,80002c76 <fetchstr+0x3a>
  return strlen(buf);
    80002c6c:	8526                	mv	a0,s1
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	1f6080e7          	jalr	502(ra) # 80000e64 <strlen>
}
    80002c76:	70a2                	ld	ra,40(sp)
    80002c78:	7402                	ld	s0,32(sp)
    80002c7a:	64e2                	ld	s1,24(sp)
    80002c7c:	6942                	ld	s2,16(sp)
    80002c7e:	69a2                	ld	s3,8(sp)
    80002c80:	6145                	addi	sp,sp,48
    80002c82:	8082                	ret

0000000080002c84 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c84:	1101                	addi	sp,sp,-32
    80002c86:	ec06                	sd	ra,24(sp)
    80002c88:	e822                	sd	s0,16(sp)
    80002c8a:	e426                	sd	s1,8(sp)
    80002c8c:	1000                	addi	s0,sp,32
    80002c8e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c90:	00000097          	auipc	ra,0x0
    80002c94:	ef2080e7          	jalr	-270(ra) # 80002b82 <argraw>
    80002c98:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c9a:	4501                	li	a0,0
    80002c9c:	60e2                	ld	ra,24(sp)
    80002c9e:	6442                	ld	s0,16(sp)
    80002ca0:	64a2                	ld	s1,8(sp)
    80002ca2:	6105                	addi	sp,sp,32
    80002ca4:	8082                	ret

0000000080002ca6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ca6:	1101                	addi	sp,sp,-32
    80002ca8:	ec06                	sd	ra,24(sp)
    80002caa:	e822                	sd	s0,16(sp)
    80002cac:	e426                	sd	s1,8(sp)
    80002cae:	1000                	addi	s0,sp,32
    80002cb0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	ed0080e7          	jalr	-304(ra) # 80002b82 <argraw>
    80002cba:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cbc:	4501                	li	a0,0
    80002cbe:	60e2                	ld	ra,24(sp)
    80002cc0:	6442                	ld	s0,16(sp)
    80002cc2:	64a2                	ld	s1,8(sp)
    80002cc4:	6105                	addi	sp,sp,32
    80002cc6:	8082                	ret

0000000080002cc8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cc8:	1101                	addi	sp,sp,-32
    80002cca:	ec06                	sd	ra,24(sp)
    80002ccc:	e822                	sd	s0,16(sp)
    80002cce:	e426                	sd	s1,8(sp)
    80002cd0:	e04a                	sd	s2,0(sp)
    80002cd2:	1000                	addi	s0,sp,32
    80002cd4:	84ae                	mv	s1,a1
    80002cd6:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cd8:	00000097          	auipc	ra,0x0
    80002cdc:	eaa080e7          	jalr	-342(ra) # 80002b82 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ce0:	864a                	mv	a2,s2
    80002ce2:	85a6                	mv	a1,s1
    80002ce4:	00000097          	auipc	ra,0x0
    80002ce8:	f58080e7          	jalr	-168(ra) # 80002c3c <fetchstr>
}
    80002cec:	60e2                	ld	ra,24(sp)
    80002cee:	6442                	ld	s0,16(sp)
    80002cf0:	64a2                	ld	s1,8(sp)
    80002cf2:	6902                	ld	s2,0(sp)
    80002cf4:	6105                	addi	sp,sp,32
    80002cf6:	8082                	ret

0000000080002cf8 <syscall>:
[SYS_kill_system]   sys_kill_system
};

void
syscall(void)
{
    80002cf8:	1101                	addi	sp,sp,-32
    80002cfa:	ec06                	sd	ra,24(sp)
    80002cfc:	e822                	sd	s0,16(sp)
    80002cfe:	e426                	sd	s1,8(sp)
    80002d00:	e04a                	sd	s2,0(sp)
    80002d02:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d04:	fffff097          	auipc	ra,0xfffff
    80002d08:	dd0080e7          	jalr	-560(ra) # 80001ad4 <myproc>
    80002d0c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d0e:	05853903          	ld	s2,88(a0)
    80002d12:	0a893783          	ld	a5,168(s2)
    80002d16:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d1a:	37fd                	addiw	a5,a5,-1
    80002d1c:	4759                	li	a4,22
    80002d1e:	00f76f63          	bltu	a4,a5,80002d3c <syscall+0x44>
    80002d22:	00369713          	slli	a4,a3,0x3
    80002d26:	00005797          	auipc	a5,0x5
    80002d2a:	76278793          	addi	a5,a5,1890 # 80008488 <syscalls>
    80002d2e:	97ba                	add	a5,a5,a4
    80002d30:	639c                	ld	a5,0(a5)
    80002d32:	c789                	beqz	a5,80002d3c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d34:	9782                	jalr	a5
    80002d36:	06a93823          	sd	a0,112(s2)
    80002d3a:	a839                	j	80002d58 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d3c:	15848613          	addi	a2,s1,344
    80002d40:	588c                	lw	a1,48(s1)
    80002d42:	00005517          	auipc	a0,0x5
    80002d46:	70e50513          	addi	a0,a0,1806 # 80008450 <states.1736+0x150>
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	83e080e7          	jalr	-1986(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d52:	6cbc                	ld	a5,88(s1)
    80002d54:	577d                	li	a4,-1
    80002d56:	fbb8                	sd	a4,112(a5)
  }
}
    80002d58:	60e2                	ld	ra,24(sp)
    80002d5a:	6442                	ld	s0,16(sp)
    80002d5c:	64a2                	ld	s1,8(sp)
    80002d5e:	6902                	ld	s2,0(sp)
    80002d60:	6105                	addi	sp,sp,32
    80002d62:	8082                	ret

0000000080002d64 <sys_pause_system>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_pause_system(void)
{
    80002d64:	1101                	addi	sp,sp,-32
    80002d66:	ec06                	sd	ra,24(sp)
    80002d68:	e822                	sd	s0,16(sp)
    80002d6a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d6c:	fec40593          	addi	a1,s0,-20
    80002d70:	4501                	li	a0,0
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	f12080e7          	jalr	-238(ra) # 80002c84 <argint>
    80002d7a:	87aa                	mv	a5,a0
    return -1;
    80002d7c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d7e:	0007c863          	bltz	a5,80002d8e <sys_pause_system+0x2a>
  
  return pause_system(n);
    80002d82:	fec42503          	lw	a0,-20(s0)
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	452080e7          	jalr	1106(ra) # 800021d8 <pause_system>
}
    80002d8e:	60e2                	ld	ra,24(sp)
    80002d90:	6442                	ld	s0,16(sp)
    80002d92:	6105                	addi	sp,sp,32
    80002d94:	8082                	ret

0000000080002d96 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002d96:	1141                	addi	sp,sp,-16
    80002d98:	e406                	sd	ra,8(sp)
    80002d9a:	e022                	sd	s0,0(sp)
    80002d9c:	0800                	addi	s0,sp,16
  return kill_system();
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	850080e7          	jalr	-1968(ra) # 800025ee <kill_system>
}
    80002da6:	60a2                	ld	ra,8(sp)
    80002da8:	6402                	ld	s0,0(sp)
    80002daa:	0141                	addi	sp,sp,16
    80002dac:	8082                	ret

0000000080002dae <sys_exit>:


uint64
sys_exit(void)
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002db6:	fec40593          	addi	a1,s0,-20
    80002dba:	4501                	li	a0,0
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	ec8080e7          	jalr	-312(ra) # 80002c84 <argint>
    return -1;
    80002dc4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dc6:	00054963          	bltz	a0,80002dd8 <sys_exit+0x2a>
  exit(n);
    80002dca:	fec42503          	lw	a0,-20(s0)
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	6d8080e7          	jalr	1752(ra) # 800024a6 <exit>
  return 0;  // not reached
    80002dd6:	4781                	li	a5,0
}
    80002dd8:	853e                	mv	a0,a5
    80002dda:	60e2                	ld	ra,24(sp)
    80002ddc:	6442                	ld	s0,16(sp)
    80002dde:	6105                	addi	sp,sp,32
    80002de0:	8082                	ret

0000000080002de2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002de2:	1141                	addi	sp,sp,-16
    80002de4:	e406                	sd	ra,8(sp)
    80002de6:	e022                	sd	s0,0(sp)
    80002de8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	cea080e7          	jalr	-790(ra) # 80001ad4 <myproc>
}
    80002df2:	5908                	lw	a0,48(a0)
    80002df4:	60a2                	ld	ra,8(sp)
    80002df6:	6402                	ld	s0,0(sp)
    80002df8:	0141                	addi	sp,sp,16
    80002dfa:	8082                	ret

0000000080002dfc <sys_fork>:

uint64
sys_fork(void)
{
    80002dfc:	1141                	addi	sp,sp,-16
    80002dfe:	e406                	sd	ra,8(sp)
    80002e00:	e022                	sd	s0,0(sp)
    80002e02:	0800                	addi	s0,sp,16
  return fork();
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	09e080e7          	jalr	158(ra) # 80001ea2 <fork>
}
    80002e0c:	60a2                	ld	ra,8(sp)
    80002e0e:	6402                	ld	s0,0(sp)
    80002e10:	0141                	addi	sp,sp,16
    80002e12:	8082                	ret

0000000080002e14 <sys_wait>:

uint64
sys_wait(void)
{
    80002e14:	1101                	addi	sp,sp,-32
    80002e16:	ec06                	sd	ra,24(sp)
    80002e18:	e822                	sd	s0,16(sp)
    80002e1a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e1c:	fe840593          	addi	a1,s0,-24
    80002e20:	4501                	li	a0,0
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	e84080e7          	jalr	-380(ra) # 80002ca6 <argaddr>
    80002e2a:	87aa                	mv	a5,a0
    return -1;
    80002e2c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e2e:	0007c863          	bltz	a5,80002e3e <sys_wait+0x2a>
  return wait(p);
    80002e32:	fe843503          	ld	a0,-24(s0)
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	478080e7          	jalr	1144(ra) # 800022ae <wait>
}
    80002e3e:	60e2                	ld	ra,24(sp)
    80002e40:	6442                	ld	s0,16(sp)
    80002e42:	6105                	addi	sp,sp,32
    80002e44:	8082                	ret

0000000080002e46 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e46:	7179                	addi	sp,sp,-48
    80002e48:	f406                	sd	ra,40(sp)
    80002e4a:	f022                	sd	s0,32(sp)
    80002e4c:	ec26                	sd	s1,24(sp)
    80002e4e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e50:	fdc40593          	addi	a1,s0,-36
    80002e54:	4501                	li	a0,0
    80002e56:	00000097          	auipc	ra,0x0
    80002e5a:	e2e080e7          	jalr	-466(ra) # 80002c84 <argint>
    80002e5e:	87aa                	mv	a5,a0
    return -1;
    80002e60:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e62:	0207c063          	bltz	a5,80002e82 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e66:	fffff097          	auipc	ra,0xfffff
    80002e6a:	c6e080e7          	jalr	-914(ra) # 80001ad4 <myproc>
    80002e6e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e70:	fdc42503          	lw	a0,-36(s0)
    80002e74:	fffff097          	auipc	ra,0xfffff
    80002e78:	fba080e7          	jalr	-70(ra) # 80001e2e <growproc>
    80002e7c:	00054863          	bltz	a0,80002e8c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e80:	8526                	mv	a0,s1
}
    80002e82:	70a2                	ld	ra,40(sp)
    80002e84:	7402                	ld	s0,32(sp)
    80002e86:	64e2                	ld	s1,24(sp)
    80002e88:	6145                	addi	sp,sp,48
    80002e8a:	8082                	ret
    return -1;
    80002e8c:	557d                	li	a0,-1
    80002e8e:	bfd5                	j	80002e82 <sys_sbrk+0x3c>

0000000080002e90 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e90:	7139                	addi	sp,sp,-64
    80002e92:	fc06                	sd	ra,56(sp)
    80002e94:	f822                	sd	s0,48(sp)
    80002e96:	f426                	sd	s1,40(sp)
    80002e98:	f04a                	sd	s2,32(sp)
    80002e9a:	ec4e                	sd	s3,24(sp)
    80002e9c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e9e:	fcc40593          	addi	a1,s0,-52
    80002ea2:	4501                	li	a0,0
    80002ea4:	00000097          	auipc	ra,0x0
    80002ea8:	de0080e7          	jalr	-544(ra) # 80002c84 <argint>
    return -1;
    80002eac:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002eae:	06054563          	bltz	a0,80002f18 <sys_sleep+0x88>
  acquire(&tickslock);
    80002eb2:	00014517          	auipc	a0,0x14
    80002eb6:	21e50513          	addi	a0,a0,542 # 800170d0 <tickslock>
    80002eba:	ffffe097          	auipc	ra,0xffffe
    80002ebe:	d2a080e7          	jalr	-726(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002ec2:	00006917          	auipc	s2,0x6
    80002ec6:	17692903          	lw	s2,374(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002eca:	fcc42783          	lw	a5,-52(s0)
    80002ece:	cf85                	beqz	a5,80002f06 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ed0:	00014997          	auipc	s3,0x14
    80002ed4:	20098993          	addi	s3,s3,512 # 800170d0 <tickslock>
    80002ed8:	00006497          	auipc	s1,0x6
    80002edc:	16048493          	addi	s1,s1,352 # 80009038 <ticks>
    if(myproc()->killed){
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	bf4080e7          	jalr	-1036(ra) # 80001ad4 <myproc>
    80002ee8:	551c                	lw	a5,40(a0)
    80002eea:	ef9d                	bnez	a5,80002f28 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002eec:	85ce                	mv	a1,s3
    80002eee:	8526                	mv	a0,s1
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	35a080e7          	jalr	858(ra) # 8000224a <sleep>
  while(ticks - ticks0 < n){
    80002ef8:	409c                	lw	a5,0(s1)
    80002efa:	412787bb          	subw	a5,a5,s2
    80002efe:	fcc42703          	lw	a4,-52(s0)
    80002f02:	fce7efe3          	bltu	a5,a4,80002ee0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f06:	00014517          	auipc	a0,0x14
    80002f0a:	1ca50513          	addi	a0,a0,458 # 800170d0 <tickslock>
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	d8a080e7          	jalr	-630(ra) # 80000c98 <release>
  return 0;
    80002f16:	4781                	li	a5,0
}
    80002f18:	853e                	mv	a0,a5
    80002f1a:	70e2                	ld	ra,56(sp)
    80002f1c:	7442                	ld	s0,48(sp)
    80002f1e:	74a2                	ld	s1,40(sp)
    80002f20:	7902                	ld	s2,32(sp)
    80002f22:	69e2                	ld	s3,24(sp)
    80002f24:	6121                	addi	sp,sp,64
    80002f26:	8082                	ret
      release(&tickslock);
    80002f28:	00014517          	auipc	a0,0x14
    80002f2c:	1a850513          	addi	a0,a0,424 # 800170d0 <tickslock>
    80002f30:	ffffe097          	auipc	ra,0xffffe
    80002f34:	d68080e7          	jalr	-664(ra) # 80000c98 <release>
      return -1;
    80002f38:	57fd                	li	a5,-1
    80002f3a:	bff9                	j	80002f18 <sys_sleep+0x88>

0000000080002f3c <sys_kill>:

uint64
sys_kill(void)
{
    80002f3c:	1101                	addi	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f44:	fec40593          	addi	a1,s0,-20
    80002f48:	4501                	li	a0,0
    80002f4a:	00000097          	auipc	ra,0x0
    80002f4e:	d3a080e7          	jalr	-710(ra) # 80002c84 <argint>
    80002f52:	87aa                	mv	a5,a0
    return -1;
    80002f54:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f56:	0007c863          	bltz	a5,80002f66 <sys_kill+0x2a>
  return kill(pid);
    80002f5a:	fec42503          	lw	a0,-20(s0)
    80002f5e:	fffff097          	auipc	ra,0xfffff
    80002f62:	61e080e7          	jalr	1566(ra) # 8000257c <kill>
}
    80002f66:	60e2                	ld	ra,24(sp)
    80002f68:	6442                	ld	s0,16(sp)
    80002f6a:	6105                	addi	sp,sp,32
    80002f6c:	8082                	ret

0000000080002f6e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f6e:	1101                	addi	sp,sp,-32
    80002f70:	ec06                	sd	ra,24(sp)
    80002f72:	e822                	sd	s0,16(sp)
    80002f74:	e426                	sd	s1,8(sp)
    80002f76:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f78:	00014517          	auipc	a0,0x14
    80002f7c:	15850513          	addi	a0,a0,344 # 800170d0 <tickslock>
    80002f80:	ffffe097          	auipc	ra,0xffffe
    80002f84:	c64080e7          	jalr	-924(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002f88:	00006497          	auipc	s1,0x6
    80002f8c:	0b04a483          	lw	s1,176(s1) # 80009038 <ticks>
  release(&tickslock);
    80002f90:	00014517          	auipc	a0,0x14
    80002f94:	14050513          	addi	a0,a0,320 # 800170d0 <tickslock>
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	d00080e7          	jalr	-768(ra) # 80000c98 <release>
  return xticks;
}
    80002fa0:	02049513          	slli	a0,s1,0x20
    80002fa4:	9101                	srli	a0,a0,0x20
    80002fa6:	60e2                	ld	ra,24(sp)
    80002fa8:	6442                	ld	s0,16(sp)
    80002faa:	64a2                	ld	s1,8(sp)
    80002fac:	6105                	addi	sp,sp,32
    80002fae:	8082                	ret

0000000080002fb0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fb0:	7179                	addi	sp,sp,-48
    80002fb2:	f406                	sd	ra,40(sp)
    80002fb4:	f022                	sd	s0,32(sp)
    80002fb6:	ec26                	sd	s1,24(sp)
    80002fb8:	e84a                	sd	s2,16(sp)
    80002fba:	e44e                	sd	s3,8(sp)
    80002fbc:	e052                	sd	s4,0(sp)
    80002fbe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fc0:	00005597          	auipc	a1,0x5
    80002fc4:	58858593          	addi	a1,a1,1416 # 80008548 <syscalls+0xc0>
    80002fc8:	00014517          	auipc	a0,0x14
    80002fcc:	12050513          	addi	a0,a0,288 # 800170e8 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	b84080e7          	jalr	-1148(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fd8:	0001c797          	auipc	a5,0x1c
    80002fdc:	11078793          	addi	a5,a5,272 # 8001f0e8 <bcache+0x8000>
    80002fe0:	0001c717          	auipc	a4,0x1c
    80002fe4:	37070713          	addi	a4,a4,880 # 8001f350 <bcache+0x8268>
    80002fe8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fec:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ff0:	00014497          	auipc	s1,0x14
    80002ff4:	11048493          	addi	s1,s1,272 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002ff8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ffa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ffc:	00005a17          	auipc	s4,0x5
    80003000:	554a0a13          	addi	s4,s4,1364 # 80008550 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003004:	2b893783          	ld	a5,696(s2)
    80003008:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000300a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000300e:	85d2                	mv	a1,s4
    80003010:	01048513          	addi	a0,s1,16
    80003014:	00001097          	auipc	ra,0x1
    80003018:	4bc080e7          	jalr	1212(ra) # 800044d0 <initsleeplock>
    bcache.head.next->prev = b;
    8000301c:	2b893783          	ld	a5,696(s2)
    80003020:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003022:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003026:	45848493          	addi	s1,s1,1112
    8000302a:	fd349de3          	bne	s1,s3,80003004 <binit+0x54>
  }
}
    8000302e:	70a2                	ld	ra,40(sp)
    80003030:	7402                	ld	s0,32(sp)
    80003032:	64e2                	ld	s1,24(sp)
    80003034:	6942                	ld	s2,16(sp)
    80003036:	69a2                	ld	s3,8(sp)
    80003038:	6a02                	ld	s4,0(sp)
    8000303a:	6145                	addi	sp,sp,48
    8000303c:	8082                	ret

000000008000303e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000303e:	7179                	addi	sp,sp,-48
    80003040:	f406                	sd	ra,40(sp)
    80003042:	f022                	sd	s0,32(sp)
    80003044:	ec26                	sd	s1,24(sp)
    80003046:	e84a                	sd	s2,16(sp)
    80003048:	e44e                	sd	s3,8(sp)
    8000304a:	1800                	addi	s0,sp,48
    8000304c:	89aa                	mv	s3,a0
    8000304e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003050:	00014517          	auipc	a0,0x14
    80003054:	09850513          	addi	a0,a0,152 # 800170e8 <bcache>
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	b8c080e7          	jalr	-1140(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003060:	0001c497          	auipc	s1,0x1c
    80003064:	3404b483          	ld	s1,832(s1) # 8001f3a0 <bcache+0x82b8>
    80003068:	0001c797          	auipc	a5,0x1c
    8000306c:	2e878793          	addi	a5,a5,744 # 8001f350 <bcache+0x8268>
    80003070:	02f48f63          	beq	s1,a5,800030ae <bread+0x70>
    80003074:	873e                	mv	a4,a5
    80003076:	a021                	j	8000307e <bread+0x40>
    80003078:	68a4                	ld	s1,80(s1)
    8000307a:	02e48a63          	beq	s1,a4,800030ae <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000307e:	449c                	lw	a5,8(s1)
    80003080:	ff379ce3          	bne	a5,s3,80003078 <bread+0x3a>
    80003084:	44dc                	lw	a5,12(s1)
    80003086:	ff2799e3          	bne	a5,s2,80003078 <bread+0x3a>
      b->refcnt++;
    8000308a:	40bc                	lw	a5,64(s1)
    8000308c:	2785                	addiw	a5,a5,1
    8000308e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003090:	00014517          	auipc	a0,0x14
    80003094:	05850513          	addi	a0,a0,88 # 800170e8 <bcache>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	c00080e7          	jalr	-1024(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030a0:	01048513          	addi	a0,s1,16
    800030a4:	00001097          	auipc	ra,0x1
    800030a8:	466080e7          	jalr	1126(ra) # 8000450a <acquiresleep>
      return b;
    800030ac:	a8b9                	j	8000310a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030ae:	0001c497          	auipc	s1,0x1c
    800030b2:	2ea4b483          	ld	s1,746(s1) # 8001f398 <bcache+0x82b0>
    800030b6:	0001c797          	auipc	a5,0x1c
    800030ba:	29a78793          	addi	a5,a5,666 # 8001f350 <bcache+0x8268>
    800030be:	00f48863          	beq	s1,a5,800030ce <bread+0x90>
    800030c2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030c4:	40bc                	lw	a5,64(s1)
    800030c6:	cf81                	beqz	a5,800030de <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030c8:	64a4                	ld	s1,72(s1)
    800030ca:	fee49de3          	bne	s1,a4,800030c4 <bread+0x86>
  panic("bget: no buffers");
    800030ce:	00005517          	auipc	a0,0x5
    800030d2:	48a50513          	addi	a0,a0,1162 # 80008558 <syscalls+0xd0>
    800030d6:	ffffd097          	auipc	ra,0xffffd
    800030da:	468080e7          	jalr	1128(ra) # 8000053e <panic>
      b->dev = dev;
    800030de:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030e2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030e6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030ea:	4785                	li	a5,1
    800030ec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	ffa50513          	addi	a0,a0,-6 # 800170e8 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	ba2080e7          	jalr	-1118(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030fe:	01048513          	addi	a0,s1,16
    80003102:	00001097          	auipc	ra,0x1
    80003106:	408080e7          	jalr	1032(ra) # 8000450a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000310a:	409c                	lw	a5,0(s1)
    8000310c:	cb89                	beqz	a5,8000311e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000310e:	8526                	mv	a0,s1
    80003110:	70a2                	ld	ra,40(sp)
    80003112:	7402                	ld	s0,32(sp)
    80003114:	64e2                	ld	s1,24(sp)
    80003116:	6942                	ld	s2,16(sp)
    80003118:	69a2                	ld	s3,8(sp)
    8000311a:	6145                	addi	sp,sp,48
    8000311c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000311e:	4581                	li	a1,0
    80003120:	8526                	mv	a0,s1
    80003122:	00003097          	auipc	ra,0x3
    80003126:	f14080e7          	jalr	-236(ra) # 80006036 <virtio_disk_rw>
    b->valid = 1;
    8000312a:	4785                	li	a5,1
    8000312c:	c09c                	sw	a5,0(s1)
  return b;
    8000312e:	b7c5                	j	8000310e <bread+0xd0>

0000000080003130 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003130:	1101                	addi	sp,sp,-32
    80003132:	ec06                	sd	ra,24(sp)
    80003134:	e822                	sd	s0,16(sp)
    80003136:	e426                	sd	s1,8(sp)
    80003138:	1000                	addi	s0,sp,32
    8000313a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000313c:	0541                	addi	a0,a0,16
    8000313e:	00001097          	auipc	ra,0x1
    80003142:	466080e7          	jalr	1126(ra) # 800045a4 <holdingsleep>
    80003146:	cd01                	beqz	a0,8000315e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003148:	4585                	li	a1,1
    8000314a:	8526                	mv	a0,s1
    8000314c:	00003097          	auipc	ra,0x3
    80003150:	eea080e7          	jalr	-278(ra) # 80006036 <virtio_disk_rw>
}
    80003154:	60e2                	ld	ra,24(sp)
    80003156:	6442                	ld	s0,16(sp)
    80003158:	64a2                	ld	s1,8(sp)
    8000315a:	6105                	addi	sp,sp,32
    8000315c:	8082                	ret
    panic("bwrite");
    8000315e:	00005517          	auipc	a0,0x5
    80003162:	41250513          	addi	a0,a0,1042 # 80008570 <syscalls+0xe8>
    80003166:	ffffd097          	auipc	ra,0xffffd
    8000316a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000316e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000316e:	1101                	addi	sp,sp,-32
    80003170:	ec06                	sd	ra,24(sp)
    80003172:	e822                	sd	s0,16(sp)
    80003174:	e426                	sd	s1,8(sp)
    80003176:	e04a                	sd	s2,0(sp)
    80003178:	1000                	addi	s0,sp,32
    8000317a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000317c:	01050913          	addi	s2,a0,16
    80003180:	854a                	mv	a0,s2
    80003182:	00001097          	auipc	ra,0x1
    80003186:	422080e7          	jalr	1058(ra) # 800045a4 <holdingsleep>
    8000318a:	c92d                	beqz	a0,800031fc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000318c:	854a                	mv	a0,s2
    8000318e:	00001097          	auipc	ra,0x1
    80003192:	3d2080e7          	jalr	978(ra) # 80004560 <releasesleep>

  acquire(&bcache.lock);
    80003196:	00014517          	auipc	a0,0x14
    8000319a:	f5250513          	addi	a0,a0,-174 # 800170e8 <bcache>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	a46080e7          	jalr	-1466(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031a6:	40bc                	lw	a5,64(s1)
    800031a8:	37fd                	addiw	a5,a5,-1
    800031aa:	0007871b          	sext.w	a4,a5
    800031ae:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031b0:	eb05                	bnez	a4,800031e0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031b2:	68bc                	ld	a5,80(s1)
    800031b4:	64b8                	ld	a4,72(s1)
    800031b6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031b8:	64bc                	ld	a5,72(s1)
    800031ba:	68b8                	ld	a4,80(s1)
    800031bc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031be:	0001c797          	auipc	a5,0x1c
    800031c2:	f2a78793          	addi	a5,a5,-214 # 8001f0e8 <bcache+0x8000>
    800031c6:	2b87b703          	ld	a4,696(a5)
    800031ca:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031cc:	0001c717          	auipc	a4,0x1c
    800031d0:	18470713          	addi	a4,a4,388 # 8001f350 <bcache+0x8268>
    800031d4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031d6:	2b87b703          	ld	a4,696(a5)
    800031da:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031dc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031e0:	00014517          	auipc	a0,0x14
    800031e4:	f0850513          	addi	a0,a0,-248 # 800170e8 <bcache>
    800031e8:	ffffe097          	auipc	ra,0xffffe
    800031ec:	ab0080e7          	jalr	-1360(ra) # 80000c98 <release>
}
    800031f0:	60e2                	ld	ra,24(sp)
    800031f2:	6442                	ld	s0,16(sp)
    800031f4:	64a2                	ld	s1,8(sp)
    800031f6:	6902                	ld	s2,0(sp)
    800031f8:	6105                	addi	sp,sp,32
    800031fa:	8082                	ret
    panic("brelse");
    800031fc:	00005517          	auipc	a0,0x5
    80003200:	37c50513          	addi	a0,a0,892 # 80008578 <syscalls+0xf0>
    80003204:	ffffd097          	auipc	ra,0xffffd
    80003208:	33a080e7          	jalr	826(ra) # 8000053e <panic>

000000008000320c <bpin>:

void
bpin(struct buf *b) {
    8000320c:	1101                	addi	sp,sp,-32
    8000320e:	ec06                	sd	ra,24(sp)
    80003210:	e822                	sd	s0,16(sp)
    80003212:	e426                	sd	s1,8(sp)
    80003214:	1000                	addi	s0,sp,32
    80003216:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003218:	00014517          	auipc	a0,0x14
    8000321c:	ed050513          	addi	a0,a0,-304 # 800170e8 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	9c4080e7          	jalr	-1596(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003228:	40bc                	lw	a5,64(s1)
    8000322a:	2785                	addiw	a5,a5,1
    8000322c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000322e:	00014517          	auipc	a0,0x14
    80003232:	eba50513          	addi	a0,a0,-326 # 800170e8 <bcache>
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	a62080e7          	jalr	-1438(ra) # 80000c98 <release>
}
    8000323e:	60e2                	ld	ra,24(sp)
    80003240:	6442                	ld	s0,16(sp)
    80003242:	64a2                	ld	s1,8(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret

0000000080003248 <bunpin>:

void
bunpin(struct buf *b) {
    80003248:	1101                	addi	sp,sp,-32
    8000324a:	ec06                	sd	ra,24(sp)
    8000324c:	e822                	sd	s0,16(sp)
    8000324e:	e426                	sd	s1,8(sp)
    80003250:	1000                	addi	s0,sp,32
    80003252:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003254:	00014517          	auipc	a0,0x14
    80003258:	e9450513          	addi	a0,a0,-364 # 800170e8 <bcache>
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	988080e7          	jalr	-1656(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003264:	40bc                	lw	a5,64(s1)
    80003266:	37fd                	addiw	a5,a5,-1
    80003268:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000326a:	00014517          	auipc	a0,0x14
    8000326e:	e7e50513          	addi	a0,a0,-386 # 800170e8 <bcache>
    80003272:	ffffe097          	auipc	ra,0xffffe
    80003276:	a26080e7          	jalr	-1498(ra) # 80000c98 <release>
}
    8000327a:	60e2                	ld	ra,24(sp)
    8000327c:	6442                	ld	s0,16(sp)
    8000327e:	64a2                	ld	s1,8(sp)
    80003280:	6105                	addi	sp,sp,32
    80003282:	8082                	ret

0000000080003284 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003284:	1101                	addi	sp,sp,-32
    80003286:	ec06                	sd	ra,24(sp)
    80003288:	e822                	sd	s0,16(sp)
    8000328a:	e426                	sd	s1,8(sp)
    8000328c:	e04a                	sd	s2,0(sp)
    8000328e:	1000                	addi	s0,sp,32
    80003290:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003292:	00d5d59b          	srliw	a1,a1,0xd
    80003296:	0001c797          	auipc	a5,0x1c
    8000329a:	52e7a783          	lw	a5,1326(a5) # 8001f7c4 <sb+0x1c>
    8000329e:	9dbd                	addw	a1,a1,a5
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	d9e080e7          	jalr	-610(ra) # 8000303e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032a8:	0074f713          	andi	a4,s1,7
    800032ac:	4785                	li	a5,1
    800032ae:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032b2:	14ce                	slli	s1,s1,0x33
    800032b4:	90d9                	srli	s1,s1,0x36
    800032b6:	00950733          	add	a4,a0,s1
    800032ba:	05874703          	lbu	a4,88(a4)
    800032be:	00e7f6b3          	and	a3,a5,a4
    800032c2:	c69d                	beqz	a3,800032f0 <bfree+0x6c>
    800032c4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032c6:	94aa                	add	s1,s1,a0
    800032c8:	fff7c793          	not	a5,a5
    800032cc:	8ff9                	and	a5,a5,a4
    800032ce:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	118080e7          	jalr	280(ra) # 800043ea <log_write>
  brelse(bp);
    800032da:	854a                	mv	a0,s2
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	e92080e7          	jalr	-366(ra) # 8000316e <brelse>
}
    800032e4:	60e2                	ld	ra,24(sp)
    800032e6:	6442                	ld	s0,16(sp)
    800032e8:	64a2                	ld	s1,8(sp)
    800032ea:	6902                	ld	s2,0(sp)
    800032ec:	6105                	addi	sp,sp,32
    800032ee:	8082                	ret
    panic("freeing free block");
    800032f0:	00005517          	auipc	a0,0x5
    800032f4:	29050513          	addi	a0,a0,656 # 80008580 <syscalls+0xf8>
    800032f8:	ffffd097          	auipc	ra,0xffffd
    800032fc:	246080e7          	jalr	582(ra) # 8000053e <panic>

0000000080003300 <balloc>:
{
    80003300:	711d                	addi	sp,sp,-96
    80003302:	ec86                	sd	ra,88(sp)
    80003304:	e8a2                	sd	s0,80(sp)
    80003306:	e4a6                	sd	s1,72(sp)
    80003308:	e0ca                	sd	s2,64(sp)
    8000330a:	fc4e                	sd	s3,56(sp)
    8000330c:	f852                	sd	s4,48(sp)
    8000330e:	f456                	sd	s5,40(sp)
    80003310:	f05a                	sd	s6,32(sp)
    80003312:	ec5e                	sd	s7,24(sp)
    80003314:	e862                	sd	s8,16(sp)
    80003316:	e466                	sd	s9,8(sp)
    80003318:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000331a:	0001c797          	auipc	a5,0x1c
    8000331e:	4927a783          	lw	a5,1170(a5) # 8001f7ac <sb+0x4>
    80003322:	cbd1                	beqz	a5,800033b6 <balloc+0xb6>
    80003324:	8baa                	mv	s7,a0
    80003326:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003328:	0001cb17          	auipc	s6,0x1c
    8000332c:	480b0b13          	addi	s6,s6,1152 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003330:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003332:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003334:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003336:	6c89                	lui	s9,0x2
    80003338:	a831                	j	80003354 <balloc+0x54>
    brelse(bp);
    8000333a:	854a                	mv	a0,s2
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	e32080e7          	jalr	-462(ra) # 8000316e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003344:	015c87bb          	addw	a5,s9,s5
    80003348:	00078a9b          	sext.w	s5,a5
    8000334c:	004b2703          	lw	a4,4(s6)
    80003350:	06eaf363          	bgeu	s5,a4,800033b6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003354:	41fad79b          	sraiw	a5,s5,0x1f
    80003358:	0137d79b          	srliw	a5,a5,0x13
    8000335c:	015787bb          	addw	a5,a5,s5
    80003360:	40d7d79b          	sraiw	a5,a5,0xd
    80003364:	01cb2583          	lw	a1,28(s6)
    80003368:	9dbd                	addw	a1,a1,a5
    8000336a:	855e                	mv	a0,s7
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	cd2080e7          	jalr	-814(ra) # 8000303e <bread>
    80003374:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003376:	004b2503          	lw	a0,4(s6)
    8000337a:	000a849b          	sext.w	s1,s5
    8000337e:	8662                	mv	a2,s8
    80003380:	faa4fde3          	bgeu	s1,a0,8000333a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003384:	41f6579b          	sraiw	a5,a2,0x1f
    80003388:	01d7d69b          	srliw	a3,a5,0x1d
    8000338c:	00c6873b          	addw	a4,a3,a2
    80003390:	00777793          	andi	a5,a4,7
    80003394:	9f95                	subw	a5,a5,a3
    80003396:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000339a:	4037571b          	sraiw	a4,a4,0x3
    8000339e:	00e906b3          	add	a3,s2,a4
    800033a2:	0586c683          	lbu	a3,88(a3)
    800033a6:	00d7f5b3          	and	a1,a5,a3
    800033aa:	cd91                	beqz	a1,800033c6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ac:	2605                	addiw	a2,a2,1
    800033ae:	2485                	addiw	s1,s1,1
    800033b0:	fd4618e3          	bne	a2,s4,80003380 <balloc+0x80>
    800033b4:	b759                	j	8000333a <balloc+0x3a>
  panic("balloc: out of blocks");
    800033b6:	00005517          	auipc	a0,0x5
    800033ba:	1e250513          	addi	a0,a0,482 # 80008598 <syscalls+0x110>
    800033be:	ffffd097          	auipc	ra,0xffffd
    800033c2:	180080e7          	jalr	384(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033c6:	974a                	add	a4,a4,s2
    800033c8:	8fd5                	or	a5,a5,a3
    800033ca:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033ce:	854a                	mv	a0,s2
    800033d0:	00001097          	auipc	ra,0x1
    800033d4:	01a080e7          	jalr	26(ra) # 800043ea <log_write>
        brelse(bp);
    800033d8:	854a                	mv	a0,s2
    800033da:	00000097          	auipc	ra,0x0
    800033de:	d94080e7          	jalr	-620(ra) # 8000316e <brelse>
  bp = bread(dev, bno);
    800033e2:	85a6                	mv	a1,s1
    800033e4:	855e                	mv	a0,s7
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	c58080e7          	jalr	-936(ra) # 8000303e <bread>
    800033ee:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033f0:	40000613          	li	a2,1024
    800033f4:	4581                	li	a1,0
    800033f6:	05850513          	addi	a0,a0,88
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	8e6080e7          	jalr	-1818(ra) # 80000ce0 <memset>
  log_write(bp);
    80003402:	854a                	mv	a0,s2
    80003404:	00001097          	auipc	ra,0x1
    80003408:	fe6080e7          	jalr	-26(ra) # 800043ea <log_write>
  brelse(bp);
    8000340c:	854a                	mv	a0,s2
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	d60080e7          	jalr	-672(ra) # 8000316e <brelse>
}
    80003416:	8526                	mv	a0,s1
    80003418:	60e6                	ld	ra,88(sp)
    8000341a:	6446                	ld	s0,80(sp)
    8000341c:	64a6                	ld	s1,72(sp)
    8000341e:	6906                	ld	s2,64(sp)
    80003420:	79e2                	ld	s3,56(sp)
    80003422:	7a42                	ld	s4,48(sp)
    80003424:	7aa2                	ld	s5,40(sp)
    80003426:	7b02                	ld	s6,32(sp)
    80003428:	6be2                	ld	s7,24(sp)
    8000342a:	6c42                	ld	s8,16(sp)
    8000342c:	6ca2                	ld	s9,8(sp)
    8000342e:	6125                	addi	sp,sp,96
    80003430:	8082                	ret

0000000080003432 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003432:	7179                	addi	sp,sp,-48
    80003434:	f406                	sd	ra,40(sp)
    80003436:	f022                	sd	s0,32(sp)
    80003438:	ec26                	sd	s1,24(sp)
    8000343a:	e84a                	sd	s2,16(sp)
    8000343c:	e44e                	sd	s3,8(sp)
    8000343e:	e052                	sd	s4,0(sp)
    80003440:	1800                	addi	s0,sp,48
    80003442:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003444:	47ad                	li	a5,11
    80003446:	04b7fe63          	bgeu	a5,a1,800034a2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000344a:	ff45849b          	addiw	s1,a1,-12
    8000344e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003452:	0ff00793          	li	a5,255
    80003456:	0ae7e363          	bltu	a5,a4,800034fc <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000345a:	08052583          	lw	a1,128(a0)
    8000345e:	c5ad                	beqz	a1,800034c8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003460:	00092503          	lw	a0,0(s2)
    80003464:	00000097          	auipc	ra,0x0
    80003468:	bda080e7          	jalr	-1062(ra) # 8000303e <bread>
    8000346c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000346e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003472:	02049593          	slli	a1,s1,0x20
    80003476:	9181                	srli	a1,a1,0x20
    80003478:	058a                	slli	a1,a1,0x2
    8000347a:	00b784b3          	add	s1,a5,a1
    8000347e:	0004a983          	lw	s3,0(s1)
    80003482:	04098d63          	beqz	s3,800034dc <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003486:	8552                	mv	a0,s4
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	ce6080e7          	jalr	-794(ra) # 8000316e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003490:	854e                	mv	a0,s3
    80003492:	70a2                	ld	ra,40(sp)
    80003494:	7402                	ld	s0,32(sp)
    80003496:	64e2                	ld	s1,24(sp)
    80003498:	6942                	ld	s2,16(sp)
    8000349a:	69a2                	ld	s3,8(sp)
    8000349c:	6a02                	ld	s4,0(sp)
    8000349e:	6145                	addi	sp,sp,48
    800034a0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034a2:	02059493          	slli	s1,a1,0x20
    800034a6:	9081                	srli	s1,s1,0x20
    800034a8:	048a                	slli	s1,s1,0x2
    800034aa:	94aa                	add	s1,s1,a0
    800034ac:	0504a983          	lw	s3,80(s1)
    800034b0:	fe0990e3          	bnez	s3,80003490 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034b4:	4108                	lw	a0,0(a0)
    800034b6:	00000097          	auipc	ra,0x0
    800034ba:	e4a080e7          	jalr	-438(ra) # 80003300 <balloc>
    800034be:	0005099b          	sext.w	s3,a0
    800034c2:	0534a823          	sw	s3,80(s1)
    800034c6:	b7e9                	j	80003490 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034c8:	4108                	lw	a0,0(a0)
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	e36080e7          	jalr	-458(ra) # 80003300 <balloc>
    800034d2:	0005059b          	sext.w	a1,a0
    800034d6:	08b92023          	sw	a1,128(s2)
    800034da:	b759                	j	80003460 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034dc:	00092503          	lw	a0,0(s2)
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	e20080e7          	jalr	-480(ra) # 80003300 <balloc>
    800034e8:	0005099b          	sext.w	s3,a0
    800034ec:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034f0:	8552                	mv	a0,s4
    800034f2:	00001097          	auipc	ra,0x1
    800034f6:	ef8080e7          	jalr	-264(ra) # 800043ea <log_write>
    800034fa:	b771                	j	80003486 <bmap+0x54>
  panic("bmap: out of range");
    800034fc:	00005517          	auipc	a0,0x5
    80003500:	0b450513          	addi	a0,a0,180 # 800085b0 <syscalls+0x128>
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	03a080e7          	jalr	58(ra) # 8000053e <panic>

000000008000350c <iget>:
{
    8000350c:	7179                	addi	sp,sp,-48
    8000350e:	f406                	sd	ra,40(sp)
    80003510:	f022                	sd	s0,32(sp)
    80003512:	ec26                	sd	s1,24(sp)
    80003514:	e84a                	sd	s2,16(sp)
    80003516:	e44e                	sd	s3,8(sp)
    80003518:	e052                	sd	s4,0(sp)
    8000351a:	1800                	addi	s0,sp,48
    8000351c:	89aa                	mv	s3,a0
    8000351e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003520:	0001c517          	auipc	a0,0x1c
    80003524:	2a850513          	addi	a0,a0,680 # 8001f7c8 <itable>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	6bc080e7          	jalr	1724(ra) # 80000be4 <acquire>
  empty = 0;
    80003530:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003532:	0001c497          	auipc	s1,0x1c
    80003536:	2ae48493          	addi	s1,s1,686 # 8001f7e0 <itable+0x18>
    8000353a:	0001e697          	auipc	a3,0x1e
    8000353e:	d3668693          	addi	a3,a3,-714 # 80021270 <log>
    80003542:	a039                	j	80003550 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003544:	02090b63          	beqz	s2,8000357a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003548:	08848493          	addi	s1,s1,136
    8000354c:	02d48a63          	beq	s1,a3,80003580 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003550:	449c                	lw	a5,8(s1)
    80003552:	fef059e3          	blez	a5,80003544 <iget+0x38>
    80003556:	4098                	lw	a4,0(s1)
    80003558:	ff3716e3          	bne	a4,s3,80003544 <iget+0x38>
    8000355c:	40d8                	lw	a4,4(s1)
    8000355e:	ff4713e3          	bne	a4,s4,80003544 <iget+0x38>
      ip->ref++;
    80003562:	2785                	addiw	a5,a5,1
    80003564:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003566:	0001c517          	auipc	a0,0x1c
    8000356a:	26250513          	addi	a0,a0,610 # 8001f7c8 <itable>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	72a080e7          	jalr	1834(ra) # 80000c98 <release>
      return ip;
    80003576:	8926                	mv	s2,s1
    80003578:	a03d                	j	800035a6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000357a:	f7f9                	bnez	a5,80003548 <iget+0x3c>
    8000357c:	8926                	mv	s2,s1
    8000357e:	b7e9                	j	80003548 <iget+0x3c>
  if(empty == 0)
    80003580:	02090c63          	beqz	s2,800035b8 <iget+0xac>
  ip->dev = dev;
    80003584:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003588:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000358c:	4785                	li	a5,1
    8000358e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003592:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003596:	0001c517          	auipc	a0,0x1c
    8000359a:	23250513          	addi	a0,a0,562 # 8001f7c8 <itable>
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	6fa080e7          	jalr	1786(ra) # 80000c98 <release>
}
    800035a6:	854a                	mv	a0,s2
    800035a8:	70a2                	ld	ra,40(sp)
    800035aa:	7402                	ld	s0,32(sp)
    800035ac:	64e2                	ld	s1,24(sp)
    800035ae:	6942                	ld	s2,16(sp)
    800035b0:	69a2                	ld	s3,8(sp)
    800035b2:	6a02                	ld	s4,0(sp)
    800035b4:	6145                	addi	sp,sp,48
    800035b6:	8082                	ret
    panic("iget: no inodes");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	01050513          	addi	a0,a0,16 # 800085c8 <syscalls+0x140>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	f7e080e7          	jalr	-130(ra) # 8000053e <panic>

00000000800035c8 <fsinit>:
fsinit(int dev) {
    800035c8:	7179                	addi	sp,sp,-48
    800035ca:	f406                	sd	ra,40(sp)
    800035cc:	f022                	sd	s0,32(sp)
    800035ce:	ec26                	sd	s1,24(sp)
    800035d0:	e84a                	sd	s2,16(sp)
    800035d2:	e44e                	sd	s3,8(sp)
    800035d4:	1800                	addi	s0,sp,48
    800035d6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035d8:	4585                	li	a1,1
    800035da:	00000097          	auipc	ra,0x0
    800035de:	a64080e7          	jalr	-1436(ra) # 8000303e <bread>
    800035e2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035e4:	0001c997          	auipc	s3,0x1c
    800035e8:	1c498993          	addi	s3,s3,452 # 8001f7a8 <sb>
    800035ec:	02000613          	li	a2,32
    800035f0:	05850593          	addi	a1,a0,88
    800035f4:	854e                	mv	a0,s3
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	74a080e7          	jalr	1866(ra) # 80000d40 <memmove>
  brelse(bp);
    800035fe:	8526                	mv	a0,s1
    80003600:	00000097          	auipc	ra,0x0
    80003604:	b6e080e7          	jalr	-1170(ra) # 8000316e <brelse>
  if(sb.magic != FSMAGIC)
    80003608:	0009a703          	lw	a4,0(s3)
    8000360c:	102037b7          	lui	a5,0x10203
    80003610:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003614:	02f71263          	bne	a4,a5,80003638 <fsinit+0x70>
  initlog(dev, &sb);
    80003618:	0001c597          	auipc	a1,0x1c
    8000361c:	19058593          	addi	a1,a1,400 # 8001f7a8 <sb>
    80003620:	854a                	mv	a0,s2
    80003622:	00001097          	auipc	ra,0x1
    80003626:	b4c080e7          	jalr	-1204(ra) # 8000416e <initlog>
}
    8000362a:	70a2                	ld	ra,40(sp)
    8000362c:	7402                	ld	s0,32(sp)
    8000362e:	64e2                	ld	s1,24(sp)
    80003630:	6942                	ld	s2,16(sp)
    80003632:	69a2                	ld	s3,8(sp)
    80003634:	6145                	addi	sp,sp,48
    80003636:	8082                	ret
    panic("invalid file system");
    80003638:	00005517          	auipc	a0,0x5
    8000363c:	fa050513          	addi	a0,a0,-96 # 800085d8 <syscalls+0x150>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	efe080e7          	jalr	-258(ra) # 8000053e <panic>

0000000080003648 <iinit>:
{
    80003648:	7179                	addi	sp,sp,-48
    8000364a:	f406                	sd	ra,40(sp)
    8000364c:	f022                	sd	s0,32(sp)
    8000364e:	ec26                	sd	s1,24(sp)
    80003650:	e84a                	sd	s2,16(sp)
    80003652:	e44e                	sd	s3,8(sp)
    80003654:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003656:	00005597          	auipc	a1,0x5
    8000365a:	f9a58593          	addi	a1,a1,-102 # 800085f0 <syscalls+0x168>
    8000365e:	0001c517          	auipc	a0,0x1c
    80003662:	16a50513          	addi	a0,a0,362 # 8001f7c8 <itable>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	4ee080e7          	jalr	1262(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000366e:	0001c497          	auipc	s1,0x1c
    80003672:	18248493          	addi	s1,s1,386 # 8001f7f0 <itable+0x28>
    80003676:	0001e997          	auipc	s3,0x1e
    8000367a:	c0a98993          	addi	s3,s3,-1014 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000367e:	00005917          	auipc	s2,0x5
    80003682:	f7a90913          	addi	s2,s2,-134 # 800085f8 <syscalls+0x170>
    80003686:	85ca                	mv	a1,s2
    80003688:	8526                	mv	a0,s1
    8000368a:	00001097          	auipc	ra,0x1
    8000368e:	e46080e7          	jalr	-442(ra) # 800044d0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003692:	08848493          	addi	s1,s1,136
    80003696:	ff3498e3          	bne	s1,s3,80003686 <iinit+0x3e>
}
    8000369a:	70a2                	ld	ra,40(sp)
    8000369c:	7402                	ld	s0,32(sp)
    8000369e:	64e2                	ld	s1,24(sp)
    800036a0:	6942                	ld	s2,16(sp)
    800036a2:	69a2                	ld	s3,8(sp)
    800036a4:	6145                	addi	sp,sp,48
    800036a6:	8082                	ret

00000000800036a8 <ialloc>:
{
    800036a8:	715d                	addi	sp,sp,-80
    800036aa:	e486                	sd	ra,72(sp)
    800036ac:	e0a2                	sd	s0,64(sp)
    800036ae:	fc26                	sd	s1,56(sp)
    800036b0:	f84a                	sd	s2,48(sp)
    800036b2:	f44e                	sd	s3,40(sp)
    800036b4:	f052                	sd	s4,32(sp)
    800036b6:	ec56                	sd	s5,24(sp)
    800036b8:	e85a                	sd	s6,16(sp)
    800036ba:	e45e                	sd	s7,8(sp)
    800036bc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036be:	0001c717          	auipc	a4,0x1c
    800036c2:	0f672703          	lw	a4,246(a4) # 8001f7b4 <sb+0xc>
    800036c6:	4785                	li	a5,1
    800036c8:	04e7fa63          	bgeu	a5,a4,8000371c <ialloc+0x74>
    800036cc:	8aaa                	mv	s5,a0
    800036ce:	8bae                	mv	s7,a1
    800036d0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036d2:	0001ca17          	auipc	s4,0x1c
    800036d6:	0d6a0a13          	addi	s4,s4,214 # 8001f7a8 <sb>
    800036da:	00048b1b          	sext.w	s6,s1
    800036de:	0044d593          	srli	a1,s1,0x4
    800036e2:	018a2783          	lw	a5,24(s4)
    800036e6:	9dbd                	addw	a1,a1,a5
    800036e8:	8556                	mv	a0,s5
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	954080e7          	jalr	-1708(ra) # 8000303e <bread>
    800036f2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036f4:	05850993          	addi	s3,a0,88
    800036f8:	00f4f793          	andi	a5,s1,15
    800036fc:	079a                	slli	a5,a5,0x6
    800036fe:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003700:	00099783          	lh	a5,0(s3)
    80003704:	c785                	beqz	a5,8000372c <ialloc+0x84>
    brelse(bp);
    80003706:	00000097          	auipc	ra,0x0
    8000370a:	a68080e7          	jalr	-1432(ra) # 8000316e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000370e:	0485                	addi	s1,s1,1
    80003710:	00ca2703          	lw	a4,12(s4)
    80003714:	0004879b          	sext.w	a5,s1
    80003718:	fce7e1e3          	bltu	a5,a4,800036da <ialloc+0x32>
  panic("ialloc: no inodes");
    8000371c:	00005517          	auipc	a0,0x5
    80003720:	ee450513          	addi	a0,a0,-284 # 80008600 <syscalls+0x178>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	e1a080e7          	jalr	-486(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000372c:	04000613          	li	a2,64
    80003730:	4581                	li	a1,0
    80003732:	854e                	mv	a0,s3
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	5ac080e7          	jalr	1452(ra) # 80000ce0 <memset>
      dip->type = type;
    8000373c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003740:	854a                	mv	a0,s2
    80003742:	00001097          	auipc	ra,0x1
    80003746:	ca8080e7          	jalr	-856(ra) # 800043ea <log_write>
      brelse(bp);
    8000374a:	854a                	mv	a0,s2
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	a22080e7          	jalr	-1502(ra) # 8000316e <brelse>
      return iget(dev, inum);
    80003754:	85da                	mv	a1,s6
    80003756:	8556                	mv	a0,s5
    80003758:	00000097          	auipc	ra,0x0
    8000375c:	db4080e7          	jalr	-588(ra) # 8000350c <iget>
}
    80003760:	60a6                	ld	ra,72(sp)
    80003762:	6406                	ld	s0,64(sp)
    80003764:	74e2                	ld	s1,56(sp)
    80003766:	7942                	ld	s2,48(sp)
    80003768:	79a2                	ld	s3,40(sp)
    8000376a:	7a02                	ld	s4,32(sp)
    8000376c:	6ae2                	ld	s5,24(sp)
    8000376e:	6b42                	ld	s6,16(sp)
    80003770:	6ba2                	ld	s7,8(sp)
    80003772:	6161                	addi	sp,sp,80
    80003774:	8082                	ret

0000000080003776 <iupdate>:
{
    80003776:	1101                	addi	sp,sp,-32
    80003778:	ec06                	sd	ra,24(sp)
    8000377a:	e822                	sd	s0,16(sp)
    8000377c:	e426                	sd	s1,8(sp)
    8000377e:	e04a                	sd	s2,0(sp)
    80003780:	1000                	addi	s0,sp,32
    80003782:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003784:	415c                	lw	a5,4(a0)
    80003786:	0047d79b          	srliw	a5,a5,0x4
    8000378a:	0001c597          	auipc	a1,0x1c
    8000378e:	0365a583          	lw	a1,54(a1) # 8001f7c0 <sb+0x18>
    80003792:	9dbd                	addw	a1,a1,a5
    80003794:	4108                	lw	a0,0(a0)
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	8a8080e7          	jalr	-1880(ra) # 8000303e <bread>
    8000379e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037a0:	05850793          	addi	a5,a0,88
    800037a4:	40c8                	lw	a0,4(s1)
    800037a6:	893d                	andi	a0,a0,15
    800037a8:	051a                	slli	a0,a0,0x6
    800037aa:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037ac:	04449703          	lh	a4,68(s1)
    800037b0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037b4:	04649703          	lh	a4,70(s1)
    800037b8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037bc:	04849703          	lh	a4,72(s1)
    800037c0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037c4:	04a49703          	lh	a4,74(s1)
    800037c8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037cc:	44f8                	lw	a4,76(s1)
    800037ce:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037d0:	03400613          	li	a2,52
    800037d4:	05048593          	addi	a1,s1,80
    800037d8:	0531                	addi	a0,a0,12
    800037da:	ffffd097          	auipc	ra,0xffffd
    800037de:	566080e7          	jalr	1382(ra) # 80000d40 <memmove>
  log_write(bp);
    800037e2:	854a                	mv	a0,s2
    800037e4:	00001097          	auipc	ra,0x1
    800037e8:	c06080e7          	jalr	-1018(ra) # 800043ea <log_write>
  brelse(bp);
    800037ec:	854a                	mv	a0,s2
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	980080e7          	jalr	-1664(ra) # 8000316e <brelse>
}
    800037f6:	60e2                	ld	ra,24(sp)
    800037f8:	6442                	ld	s0,16(sp)
    800037fa:	64a2                	ld	s1,8(sp)
    800037fc:	6902                	ld	s2,0(sp)
    800037fe:	6105                	addi	sp,sp,32
    80003800:	8082                	ret

0000000080003802 <idup>:
{
    80003802:	1101                	addi	sp,sp,-32
    80003804:	ec06                	sd	ra,24(sp)
    80003806:	e822                	sd	s0,16(sp)
    80003808:	e426                	sd	s1,8(sp)
    8000380a:	1000                	addi	s0,sp,32
    8000380c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000380e:	0001c517          	auipc	a0,0x1c
    80003812:	fba50513          	addi	a0,a0,-70 # 8001f7c8 <itable>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	3ce080e7          	jalr	974(ra) # 80000be4 <acquire>
  ip->ref++;
    8000381e:	449c                	lw	a5,8(s1)
    80003820:	2785                	addiw	a5,a5,1
    80003822:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003824:	0001c517          	auipc	a0,0x1c
    80003828:	fa450513          	addi	a0,a0,-92 # 8001f7c8 <itable>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	46c080e7          	jalr	1132(ra) # 80000c98 <release>
}
    80003834:	8526                	mv	a0,s1
    80003836:	60e2                	ld	ra,24(sp)
    80003838:	6442                	ld	s0,16(sp)
    8000383a:	64a2                	ld	s1,8(sp)
    8000383c:	6105                	addi	sp,sp,32
    8000383e:	8082                	ret

0000000080003840 <ilock>:
{
    80003840:	1101                	addi	sp,sp,-32
    80003842:	ec06                	sd	ra,24(sp)
    80003844:	e822                	sd	s0,16(sp)
    80003846:	e426                	sd	s1,8(sp)
    80003848:	e04a                	sd	s2,0(sp)
    8000384a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000384c:	c115                	beqz	a0,80003870 <ilock+0x30>
    8000384e:	84aa                	mv	s1,a0
    80003850:	451c                	lw	a5,8(a0)
    80003852:	00f05f63          	blez	a5,80003870 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003856:	0541                	addi	a0,a0,16
    80003858:	00001097          	auipc	ra,0x1
    8000385c:	cb2080e7          	jalr	-846(ra) # 8000450a <acquiresleep>
  if(ip->valid == 0){
    80003860:	40bc                	lw	a5,64(s1)
    80003862:	cf99                	beqz	a5,80003880 <ilock+0x40>
}
    80003864:	60e2                	ld	ra,24(sp)
    80003866:	6442                	ld	s0,16(sp)
    80003868:	64a2                	ld	s1,8(sp)
    8000386a:	6902                	ld	s2,0(sp)
    8000386c:	6105                	addi	sp,sp,32
    8000386e:	8082                	ret
    panic("ilock");
    80003870:	00005517          	auipc	a0,0x5
    80003874:	da850513          	addi	a0,a0,-600 # 80008618 <syscalls+0x190>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	cc6080e7          	jalr	-826(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003880:	40dc                	lw	a5,4(s1)
    80003882:	0047d79b          	srliw	a5,a5,0x4
    80003886:	0001c597          	auipc	a1,0x1c
    8000388a:	f3a5a583          	lw	a1,-198(a1) # 8001f7c0 <sb+0x18>
    8000388e:	9dbd                	addw	a1,a1,a5
    80003890:	4088                	lw	a0,0(s1)
    80003892:	fffff097          	auipc	ra,0xfffff
    80003896:	7ac080e7          	jalr	1964(ra) # 8000303e <bread>
    8000389a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000389c:	05850593          	addi	a1,a0,88
    800038a0:	40dc                	lw	a5,4(s1)
    800038a2:	8bbd                	andi	a5,a5,15
    800038a4:	079a                	slli	a5,a5,0x6
    800038a6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038a8:	00059783          	lh	a5,0(a1)
    800038ac:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038b0:	00259783          	lh	a5,2(a1)
    800038b4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038b8:	00459783          	lh	a5,4(a1)
    800038bc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038c0:	00659783          	lh	a5,6(a1)
    800038c4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038c8:	459c                	lw	a5,8(a1)
    800038ca:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038cc:	03400613          	li	a2,52
    800038d0:	05b1                	addi	a1,a1,12
    800038d2:	05048513          	addi	a0,s1,80
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	46a080e7          	jalr	1130(ra) # 80000d40 <memmove>
    brelse(bp);
    800038de:	854a                	mv	a0,s2
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	88e080e7          	jalr	-1906(ra) # 8000316e <brelse>
    ip->valid = 1;
    800038e8:	4785                	li	a5,1
    800038ea:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038ec:	04449783          	lh	a5,68(s1)
    800038f0:	fbb5                	bnez	a5,80003864 <ilock+0x24>
      panic("ilock: no type");
    800038f2:	00005517          	auipc	a0,0x5
    800038f6:	d2e50513          	addi	a0,a0,-722 # 80008620 <syscalls+0x198>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	c44080e7          	jalr	-956(ra) # 8000053e <panic>

0000000080003902 <iunlock>:
{
    80003902:	1101                	addi	sp,sp,-32
    80003904:	ec06                	sd	ra,24(sp)
    80003906:	e822                	sd	s0,16(sp)
    80003908:	e426                	sd	s1,8(sp)
    8000390a:	e04a                	sd	s2,0(sp)
    8000390c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000390e:	c905                	beqz	a0,8000393e <iunlock+0x3c>
    80003910:	84aa                	mv	s1,a0
    80003912:	01050913          	addi	s2,a0,16
    80003916:	854a                	mv	a0,s2
    80003918:	00001097          	auipc	ra,0x1
    8000391c:	c8c080e7          	jalr	-884(ra) # 800045a4 <holdingsleep>
    80003920:	cd19                	beqz	a0,8000393e <iunlock+0x3c>
    80003922:	449c                	lw	a5,8(s1)
    80003924:	00f05d63          	blez	a5,8000393e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003928:	854a                	mv	a0,s2
    8000392a:	00001097          	auipc	ra,0x1
    8000392e:	c36080e7          	jalr	-970(ra) # 80004560 <releasesleep>
}
    80003932:	60e2                	ld	ra,24(sp)
    80003934:	6442                	ld	s0,16(sp)
    80003936:	64a2                	ld	s1,8(sp)
    80003938:	6902                	ld	s2,0(sp)
    8000393a:	6105                	addi	sp,sp,32
    8000393c:	8082                	ret
    panic("iunlock");
    8000393e:	00005517          	auipc	a0,0x5
    80003942:	cf250513          	addi	a0,a0,-782 # 80008630 <syscalls+0x1a8>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	bf8080e7          	jalr	-1032(ra) # 8000053e <panic>

000000008000394e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000394e:	7179                	addi	sp,sp,-48
    80003950:	f406                	sd	ra,40(sp)
    80003952:	f022                	sd	s0,32(sp)
    80003954:	ec26                	sd	s1,24(sp)
    80003956:	e84a                	sd	s2,16(sp)
    80003958:	e44e                	sd	s3,8(sp)
    8000395a:	e052                	sd	s4,0(sp)
    8000395c:	1800                	addi	s0,sp,48
    8000395e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003960:	05050493          	addi	s1,a0,80
    80003964:	08050913          	addi	s2,a0,128
    80003968:	a021                	j	80003970 <itrunc+0x22>
    8000396a:	0491                	addi	s1,s1,4
    8000396c:	01248d63          	beq	s1,s2,80003986 <itrunc+0x38>
    if(ip->addrs[i]){
    80003970:	408c                	lw	a1,0(s1)
    80003972:	dde5                	beqz	a1,8000396a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003974:	0009a503          	lw	a0,0(s3)
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	90c080e7          	jalr	-1780(ra) # 80003284 <bfree>
      ip->addrs[i] = 0;
    80003980:	0004a023          	sw	zero,0(s1)
    80003984:	b7dd                	j	8000396a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003986:	0809a583          	lw	a1,128(s3)
    8000398a:	e185                	bnez	a1,800039aa <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000398c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003990:	854e                	mv	a0,s3
    80003992:	00000097          	auipc	ra,0x0
    80003996:	de4080e7          	jalr	-540(ra) # 80003776 <iupdate>
}
    8000399a:	70a2                	ld	ra,40(sp)
    8000399c:	7402                	ld	s0,32(sp)
    8000399e:	64e2                	ld	s1,24(sp)
    800039a0:	6942                	ld	s2,16(sp)
    800039a2:	69a2                	ld	s3,8(sp)
    800039a4:	6a02                	ld	s4,0(sp)
    800039a6:	6145                	addi	sp,sp,48
    800039a8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039aa:	0009a503          	lw	a0,0(s3)
    800039ae:	fffff097          	auipc	ra,0xfffff
    800039b2:	690080e7          	jalr	1680(ra) # 8000303e <bread>
    800039b6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039b8:	05850493          	addi	s1,a0,88
    800039bc:	45850913          	addi	s2,a0,1112
    800039c0:	a811                	j	800039d4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039c2:	0009a503          	lw	a0,0(s3)
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	8be080e7          	jalr	-1858(ra) # 80003284 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039ce:	0491                	addi	s1,s1,4
    800039d0:	01248563          	beq	s1,s2,800039da <itrunc+0x8c>
      if(a[j])
    800039d4:	408c                	lw	a1,0(s1)
    800039d6:	dde5                	beqz	a1,800039ce <itrunc+0x80>
    800039d8:	b7ed                	j	800039c2 <itrunc+0x74>
    brelse(bp);
    800039da:	8552                	mv	a0,s4
    800039dc:	fffff097          	auipc	ra,0xfffff
    800039e0:	792080e7          	jalr	1938(ra) # 8000316e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039e4:	0809a583          	lw	a1,128(s3)
    800039e8:	0009a503          	lw	a0,0(s3)
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	898080e7          	jalr	-1896(ra) # 80003284 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039f4:	0809a023          	sw	zero,128(s3)
    800039f8:	bf51                	j	8000398c <itrunc+0x3e>

00000000800039fa <iput>:
{
    800039fa:	1101                	addi	sp,sp,-32
    800039fc:	ec06                	sd	ra,24(sp)
    800039fe:	e822                	sd	s0,16(sp)
    80003a00:	e426                	sd	s1,8(sp)
    80003a02:	e04a                	sd	s2,0(sp)
    80003a04:	1000                	addi	s0,sp,32
    80003a06:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a08:	0001c517          	auipc	a0,0x1c
    80003a0c:	dc050513          	addi	a0,a0,-576 # 8001f7c8 <itable>
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	1d4080e7          	jalr	468(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a18:	4498                	lw	a4,8(s1)
    80003a1a:	4785                	li	a5,1
    80003a1c:	02f70363          	beq	a4,a5,80003a42 <iput+0x48>
  ip->ref--;
    80003a20:	449c                	lw	a5,8(s1)
    80003a22:	37fd                	addiw	a5,a5,-1
    80003a24:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a26:	0001c517          	auipc	a0,0x1c
    80003a2a:	da250513          	addi	a0,a0,-606 # 8001f7c8 <itable>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	26a080e7          	jalr	618(ra) # 80000c98 <release>
}
    80003a36:	60e2                	ld	ra,24(sp)
    80003a38:	6442                	ld	s0,16(sp)
    80003a3a:	64a2                	ld	s1,8(sp)
    80003a3c:	6902                	ld	s2,0(sp)
    80003a3e:	6105                	addi	sp,sp,32
    80003a40:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a42:	40bc                	lw	a5,64(s1)
    80003a44:	dff1                	beqz	a5,80003a20 <iput+0x26>
    80003a46:	04a49783          	lh	a5,74(s1)
    80003a4a:	fbf9                	bnez	a5,80003a20 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a4c:	01048913          	addi	s2,s1,16
    80003a50:	854a                	mv	a0,s2
    80003a52:	00001097          	auipc	ra,0x1
    80003a56:	ab8080e7          	jalr	-1352(ra) # 8000450a <acquiresleep>
    release(&itable.lock);
    80003a5a:	0001c517          	auipc	a0,0x1c
    80003a5e:	d6e50513          	addi	a0,a0,-658 # 8001f7c8 <itable>
    80003a62:	ffffd097          	auipc	ra,0xffffd
    80003a66:	236080e7          	jalr	566(ra) # 80000c98 <release>
    itrunc(ip);
    80003a6a:	8526                	mv	a0,s1
    80003a6c:	00000097          	auipc	ra,0x0
    80003a70:	ee2080e7          	jalr	-286(ra) # 8000394e <itrunc>
    ip->type = 0;
    80003a74:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a78:	8526                	mv	a0,s1
    80003a7a:	00000097          	auipc	ra,0x0
    80003a7e:	cfc080e7          	jalr	-772(ra) # 80003776 <iupdate>
    ip->valid = 0;
    80003a82:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a86:	854a                	mv	a0,s2
    80003a88:	00001097          	auipc	ra,0x1
    80003a8c:	ad8080e7          	jalr	-1320(ra) # 80004560 <releasesleep>
    acquire(&itable.lock);
    80003a90:	0001c517          	auipc	a0,0x1c
    80003a94:	d3850513          	addi	a0,a0,-712 # 8001f7c8 <itable>
    80003a98:	ffffd097          	auipc	ra,0xffffd
    80003a9c:	14c080e7          	jalr	332(ra) # 80000be4 <acquire>
    80003aa0:	b741                	j	80003a20 <iput+0x26>

0000000080003aa2 <iunlockput>:
{
    80003aa2:	1101                	addi	sp,sp,-32
    80003aa4:	ec06                	sd	ra,24(sp)
    80003aa6:	e822                	sd	s0,16(sp)
    80003aa8:	e426                	sd	s1,8(sp)
    80003aaa:	1000                	addi	s0,sp,32
    80003aac:	84aa                	mv	s1,a0
  iunlock(ip);
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	e54080e7          	jalr	-428(ra) # 80003902 <iunlock>
  iput(ip);
    80003ab6:	8526                	mv	a0,s1
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	f42080e7          	jalr	-190(ra) # 800039fa <iput>
}
    80003ac0:	60e2                	ld	ra,24(sp)
    80003ac2:	6442                	ld	s0,16(sp)
    80003ac4:	64a2                	ld	s1,8(sp)
    80003ac6:	6105                	addi	sp,sp,32
    80003ac8:	8082                	ret

0000000080003aca <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003aca:	1141                	addi	sp,sp,-16
    80003acc:	e422                	sd	s0,8(sp)
    80003ace:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ad0:	411c                	lw	a5,0(a0)
    80003ad2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ad4:	415c                	lw	a5,4(a0)
    80003ad6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ad8:	04451783          	lh	a5,68(a0)
    80003adc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ae0:	04a51783          	lh	a5,74(a0)
    80003ae4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ae8:	04c56783          	lwu	a5,76(a0)
    80003aec:	e99c                	sd	a5,16(a1)
}
    80003aee:	6422                	ld	s0,8(sp)
    80003af0:	0141                	addi	sp,sp,16
    80003af2:	8082                	ret

0000000080003af4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003af4:	457c                	lw	a5,76(a0)
    80003af6:	0ed7e963          	bltu	a5,a3,80003be8 <readi+0xf4>
{
    80003afa:	7159                	addi	sp,sp,-112
    80003afc:	f486                	sd	ra,104(sp)
    80003afe:	f0a2                	sd	s0,96(sp)
    80003b00:	eca6                	sd	s1,88(sp)
    80003b02:	e8ca                	sd	s2,80(sp)
    80003b04:	e4ce                	sd	s3,72(sp)
    80003b06:	e0d2                	sd	s4,64(sp)
    80003b08:	fc56                	sd	s5,56(sp)
    80003b0a:	f85a                	sd	s6,48(sp)
    80003b0c:	f45e                	sd	s7,40(sp)
    80003b0e:	f062                	sd	s8,32(sp)
    80003b10:	ec66                	sd	s9,24(sp)
    80003b12:	e86a                	sd	s10,16(sp)
    80003b14:	e46e                	sd	s11,8(sp)
    80003b16:	1880                	addi	s0,sp,112
    80003b18:	8baa                	mv	s7,a0
    80003b1a:	8c2e                	mv	s8,a1
    80003b1c:	8ab2                	mv	s5,a2
    80003b1e:	84b6                	mv	s1,a3
    80003b20:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b22:	9f35                	addw	a4,a4,a3
    return 0;
    80003b24:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b26:	0ad76063          	bltu	a4,a3,80003bc6 <readi+0xd2>
  if(off + n > ip->size)
    80003b2a:	00e7f463          	bgeu	a5,a4,80003b32 <readi+0x3e>
    n = ip->size - off;
    80003b2e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b32:	0a0b0963          	beqz	s6,80003be4 <readi+0xf0>
    80003b36:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b38:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b3c:	5cfd                	li	s9,-1
    80003b3e:	a82d                	j	80003b78 <readi+0x84>
    80003b40:	020a1d93          	slli	s11,s4,0x20
    80003b44:	020ddd93          	srli	s11,s11,0x20
    80003b48:	05890613          	addi	a2,s2,88
    80003b4c:	86ee                	mv	a3,s11
    80003b4e:	963a                	add	a2,a2,a4
    80003b50:	85d6                	mv	a1,s5
    80003b52:	8562                	mv	a0,s8
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	ae4080e7          	jalr	-1308(ra) # 80002638 <either_copyout>
    80003b5c:	05950d63          	beq	a0,s9,80003bb6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b60:	854a                	mv	a0,s2
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	60c080e7          	jalr	1548(ra) # 8000316e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b6a:	013a09bb          	addw	s3,s4,s3
    80003b6e:	009a04bb          	addw	s1,s4,s1
    80003b72:	9aee                	add	s5,s5,s11
    80003b74:	0569f763          	bgeu	s3,s6,80003bc2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b78:	000ba903          	lw	s2,0(s7)
    80003b7c:	00a4d59b          	srliw	a1,s1,0xa
    80003b80:	855e                	mv	a0,s7
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	8b0080e7          	jalr	-1872(ra) # 80003432 <bmap>
    80003b8a:	0005059b          	sext.w	a1,a0
    80003b8e:	854a                	mv	a0,s2
    80003b90:	fffff097          	auipc	ra,0xfffff
    80003b94:	4ae080e7          	jalr	1198(ra) # 8000303e <bread>
    80003b98:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b9a:	3ff4f713          	andi	a4,s1,1023
    80003b9e:	40ed07bb          	subw	a5,s10,a4
    80003ba2:	413b06bb          	subw	a3,s6,s3
    80003ba6:	8a3e                	mv	s4,a5
    80003ba8:	2781                	sext.w	a5,a5
    80003baa:	0006861b          	sext.w	a2,a3
    80003bae:	f8f679e3          	bgeu	a2,a5,80003b40 <readi+0x4c>
    80003bb2:	8a36                	mv	s4,a3
    80003bb4:	b771                	j	80003b40 <readi+0x4c>
      brelse(bp);
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	5b6080e7          	jalr	1462(ra) # 8000316e <brelse>
      tot = -1;
    80003bc0:	59fd                	li	s3,-1
  }
  return tot;
    80003bc2:	0009851b          	sext.w	a0,s3
}
    80003bc6:	70a6                	ld	ra,104(sp)
    80003bc8:	7406                	ld	s0,96(sp)
    80003bca:	64e6                	ld	s1,88(sp)
    80003bcc:	6946                	ld	s2,80(sp)
    80003bce:	69a6                	ld	s3,72(sp)
    80003bd0:	6a06                	ld	s4,64(sp)
    80003bd2:	7ae2                	ld	s5,56(sp)
    80003bd4:	7b42                	ld	s6,48(sp)
    80003bd6:	7ba2                	ld	s7,40(sp)
    80003bd8:	7c02                	ld	s8,32(sp)
    80003bda:	6ce2                	ld	s9,24(sp)
    80003bdc:	6d42                	ld	s10,16(sp)
    80003bde:	6da2                	ld	s11,8(sp)
    80003be0:	6165                	addi	sp,sp,112
    80003be2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be4:	89da                	mv	s3,s6
    80003be6:	bff1                	j	80003bc2 <readi+0xce>
    return 0;
    80003be8:	4501                	li	a0,0
}
    80003bea:	8082                	ret

0000000080003bec <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bec:	457c                	lw	a5,76(a0)
    80003bee:	10d7e863          	bltu	a5,a3,80003cfe <writei+0x112>
{
    80003bf2:	7159                	addi	sp,sp,-112
    80003bf4:	f486                	sd	ra,104(sp)
    80003bf6:	f0a2                	sd	s0,96(sp)
    80003bf8:	eca6                	sd	s1,88(sp)
    80003bfa:	e8ca                	sd	s2,80(sp)
    80003bfc:	e4ce                	sd	s3,72(sp)
    80003bfe:	e0d2                	sd	s4,64(sp)
    80003c00:	fc56                	sd	s5,56(sp)
    80003c02:	f85a                	sd	s6,48(sp)
    80003c04:	f45e                	sd	s7,40(sp)
    80003c06:	f062                	sd	s8,32(sp)
    80003c08:	ec66                	sd	s9,24(sp)
    80003c0a:	e86a                	sd	s10,16(sp)
    80003c0c:	e46e                	sd	s11,8(sp)
    80003c0e:	1880                	addi	s0,sp,112
    80003c10:	8b2a                	mv	s6,a0
    80003c12:	8c2e                	mv	s8,a1
    80003c14:	8ab2                	mv	s5,a2
    80003c16:	8936                	mv	s2,a3
    80003c18:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c1a:	00e687bb          	addw	a5,a3,a4
    80003c1e:	0ed7e263          	bltu	a5,a3,80003d02 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c22:	00043737          	lui	a4,0x43
    80003c26:	0ef76063          	bltu	a4,a5,80003d06 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c2a:	0c0b8863          	beqz	s7,80003cfa <writei+0x10e>
    80003c2e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c30:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c34:	5cfd                	li	s9,-1
    80003c36:	a091                	j	80003c7a <writei+0x8e>
    80003c38:	02099d93          	slli	s11,s3,0x20
    80003c3c:	020ddd93          	srli	s11,s11,0x20
    80003c40:	05848513          	addi	a0,s1,88
    80003c44:	86ee                	mv	a3,s11
    80003c46:	8656                	mv	a2,s5
    80003c48:	85e2                	mv	a1,s8
    80003c4a:	953a                	add	a0,a0,a4
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	a42080e7          	jalr	-1470(ra) # 8000268e <either_copyin>
    80003c54:	07950263          	beq	a0,s9,80003cb8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c58:	8526                	mv	a0,s1
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	790080e7          	jalr	1936(ra) # 800043ea <log_write>
    brelse(bp);
    80003c62:	8526                	mv	a0,s1
    80003c64:	fffff097          	auipc	ra,0xfffff
    80003c68:	50a080e7          	jalr	1290(ra) # 8000316e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c6c:	01498a3b          	addw	s4,s3,s4
    80003c70:	0129893b          	addw	s2,s3,s2
    80003c74:	9aee                	add	s5,s5,s11
    80003c76:	057a7663          	bgeu	s4,s7,80003cc2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c7a:	000b2483          	lw	s1,0(s6)
    80003c7e:	00a9559b          	srliw	a1,s2,0xa
    80003c82:	855a                	mv	a0,s6
    80003c84:	fffff097          	auipc	ra,0xfffff
    80003c88:	7ae080e7          	jalr	1966(ra) # 80003432 <bmap>
    80003c8c:	0005059b          	sext.w	a1,a0
    80003c90:	8526                	mv	a0,s1
    80003c92:	fffff097          	auipc	ra,0xfffff
    80003c96:	3ac080e7          	jalr	940(ra) # 8000303e <bread>
    80003c9a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c9c:	3ff97713          	andi	a4,s2,1023
    80003ca0:	40ed07bb          	subw	a5,s10,a4
    80003ca4:	414b86bb          	subw	a3,s7,s4
    80003ca8:	89be                	mv	s3,a5
    80003caa:	2781                	sext.w	a5,a5
    80003cac:	0006861b          	sext.w	a2,a3
    80003cb0:	f8f674e3          	bgeu	a2,a5,80003c38 <writei+0x4c>
    80003cb4:	89b6                	mv	s3,a3
    80003cb6:	b749                	j	80003c38 <writei+0x4c>
      brelse(bp);
    80003cb8:	8526                	mv	a0,s1
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	4b4080e7          	jalr	1204(ra) # 8000316e <brelse>
  }

  if(off > ip->size)
    80003cc2:	04cb2783          	lw	a5,76(s6)
    80003cc6:	0127f463          	bgeu	a5,s2,80003cce <writei+0xe2>
    ip->size = off;
    80003cca:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cce:	855a                	mv	a0,s6
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	aa6080e7          	jalr	-1370(ra) # 80003776 <iupdate>

  return tot;
    80003cd8:	000a051b          	sext.w	a0,s4
}
    80003cdc:	70a6                	ld	ra,104(sp)
    80003cde:	7406                	ld	s0,96(sp)
    80003ce0:	64e6                	ld	s1,88(sp)
    80003ce2:	6946                	ld	s2,80(sp)
    80003ce4:	69a6                	ld	s3,72(sp)
    80003ce6:	6a06                	ld	s4,64(sp)
    80003ce8:	7ae2                	ld	s5,56(sp)
    80003cea:	7b42                	ld	s6,48(sp)
    80003cec:	7ba2                	ld	s7,40(sp)
    80003cee:	7c02                	ld	s8,32(sp)
    80003cf0:	6ce2                	ld	s9,24(sp)
    80003cf2:	6d42                	ld	s10,16(sp)
    80003cf4:	6da2                	ld	s11,8(sp)
    80003cf6:	6165                	addi	sp,sp,112
    80003cf8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cfa:	8a5e                	mv	s4,s7
    80003cfc:	bfc9                	j	80003cce <writei+0xe2>
    return -1;
    80003cfe:	557d                	li	a0,-1
}
    80003d00:	8082                	ret
    return -1;
    80003d02:	557d                	li	a0,-1
    80003d04:	bfe1                	j	80003cdc <writei+0xf0>
    return -1;
    80003d06:	557d                	li	a0,-1
    80003d08:	bfd1                	j	80003cdc <writei+0xf0>

0000000080003d0a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d0a:	1141                	addi	sp,sp,-16
    80003d0c:	e406                	sd	ra,8(sp)
    80003d0e:	e022                	sd	s0,0(sp)
    80003d10:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d12:	4639                	li	a2,14
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	0a4080e7          	jalr	164(ra) # 80000db8 <strncmp>
}
    80003d1c:	60a2                	ld	ra,8(sp)
    80003d1e:	6402                	ld	s0,0(sp)
    80003d20:	0141                	addi	sp,sp,16
    80003d22:	8082                	ret

0000000080003d24 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d24:	7139                	addi	sp,sp,-64
    80003d26:	fc06                	sd	ra,56(sp)
    80003d28:	f822                	sd	s0,48(sp)
    80003d2a:	f426                	sd	s1,40(sp)
    80003d2c:	f04a                	sd	s2,32(sp)
    80003d2e:	ec4e                	sd	s3,24(sp)
    80003d30:	e852                	sd	s4,16(sp)
    80003d32:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d34:	04451703          	lh	a4,68(a0)
    80003d38:	4785                	li	a5,1
    80003d3a:	00f71a63          	bne	a4,a5,80003d4e <dirlookup+0x2a>
    80003d3e:	892a                	mv	s2,a0
    80003d40:	89ae                	mv	s3,a1
    80003d42:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d44:	457c                	lw	a5,76(a0)
    80003d46:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d48:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4a:	e79d                	bnez	a5,80003d78 <dirlookup+0x54>
    80003d4c:	a8a5                	j	80003dc4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d4e:	00005517          	auipc	a0,0x5
    80003d52:	8ea50513          	addi	a0,a0,-1814 # 80008638 <syscalls+0x1b0>
    80003d56:	ffffc097          	auipc	ra,0xffffc
    80003d5a:	7e8080e7          	jalr	2024(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003d5e:	00005517          	auipc	a0,0x5
    80003d62:	8f250513          	addi	a0,a0,-1806 # 80008650 <syscalls+0x1c8>
    80003d66:	ffffc097          	auipc	ra,0xffffc
    80003d6a:	7d8080e7          	jalr	2008(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d6e:	24c1                	addiw	s1,s1,16
    80003d70:	04c92783          	lw	a5,76(s2)
    80003d74:	04f4f763          	bgeu	s1,a5,80003dc2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d78:	4741                	li	a4,16
    80003d7a:	86a6                	mv	a3,s1
    80003d7c:	fc040613          	addi	a2,s0,-64
    80003d80:	4581                	li	a1,0
    80003d82:	854a                	mv	a0,s2
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	d70080e7          	jalr	-656(ra) # 80003af4 <readi>
    80003d8c:	47c1                	li	a5,16
    80003d8e:	fcf518e3          	bne	a0,a5,80003d5e <dirlookup+0x3a>
    if(de.inum == 0)
    80003d92:	fc045783          	lhu	a5,-64(s0)
    80003d96:	dfe1                	beqz	a5,80003d6e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d98:	fc240593          	addi	a1,s0,-62
    80003d9c:	854e                	mv	a0,s3
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	f6c080e7          	jalr	-148(ra) # 80003d0a <namecmp>
    80003da6:	f561                	bnez	a0,80003d6e <dirlookup+0x4a>
      if(poff)
    80003da8:	000a0463          	beqz	s4,80003db0 <dirlookup+0x8c>
        *poff = off;
    80003dac:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003db0:	fc045583          	lhu	a1,-64(s0)
    80003db4:	00092503          	lw	a0,0(s2)
    80003db8:	fffff097          	auipc	ra,0xfffff
    80003dbc:	754080e7          	jalr	1876(ra) # 8000350c <iget>
    80003dc0:	a011                	j	80003dc4 <dirlookup+0xa0>
  return 0;
    80003dc2:	4501                	li	a0,0
}
    80003dc4:	70e2                	ld	ra,56(sp)
    80003dc6:	7442                	ld	s0,48(sp)
    80003dc8:	74a2                	ld	s1,40(sp)
    80003dca:	7902                	ld	s2,32(sp)
    80003dcc:	69e2                	ld	s3,24(sp)
    80003dce:	6a42                	ld	s4,16(sp)
    80003dd0:	6121                	addi	sp,sp,64
    80003dd2:	8082                	ret

0000000080003dd4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dd4:	711d                	addi	sp,sp,-96
    80003dd6:	ec86                	sd	ra,88(sp)
    80003dd8:	e8a2                	sd	s0,80(sp)
    80003dda:	e4a6                	sd	s1,72(sp)
    80003ddc:	e0ca                	sd	s2,64(sp)
    80003dde:	fc4e                	sd	s3,56(sp)
    80003de0:	f852                	sd	s4,48(sp)
    80003de2:	f456                	sd	s5,40(sp)
    80003de4:	f05a                	sd	s6,32(sp)
    80003de6:	ec5e                	sd	s7,24(sp)
    80003de8:	e862                	sd	s8,16(sp)
    80003dea:	e466                	sd	s9,8(sp)
    80003dec:	1080                	addi	s0,sp,96
    80003dee:	84aa                	mv	s1,a0
    80003df0:	8b2e                	mv	s6,a1
    80003df2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003df4:	00054703          	lbu	a4,0(a0)
    80003df8:	02f00793          	li	a5,47
    80003dfc:	02f70363          	beq	a4,a5,80003e22 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e00:	ffffe097          	auipc	ra,0xffffe
    80003e04:	cd4080e7          	jalr	-812(ra) # 80001ad4 <myproc>
    80003e08:	15053503          	ld	a0,336(a0)
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	9f6080e7          	jalr	-1546(ra) # 80003802 <idup>
    80003e14:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e16:	02f00913          	li	s2,47
  len = path - s;
    80003e1a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e1c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e1e:	4c05                	li	s8,1
    80003e20:	a865                	j	80003ed8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e22:	4585                	li	a1,1
    80003e24:	4505                	li	a0,1
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	6e6080e7          	jalr	1766(ra) # 8000350c <iget>
    80003e2e:	89aa                	mv	s3,a0
    80003e30:	b7dd                	j	80003e16 <namex+0x42>
      iunlockput(ip);
    80003e32:	854e                	mv	a0,s3
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	c6e080e7          	jalr	-914(ra) # 80003aa2 <iunlockput>
      return 0;
    80003e3c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e3e:	854e                	mv	a0,s3
    80003e40:	60e6                	ld	ra,88(sp)
    80003e42:	6446                	ld	s0,80(sp)
    80003e44:	64a6                	ld	s1,72(sp)
    80003e46:	6906                	ld	s2,64(sp)
    80003e48:	79e2                	ld	s3,56(sp)
    80003e4a:	7a42                	ld	s4,48(sp)
    80003e4c:	7aa2                	ld	s5,40(sp)
    80003e4e:	7b02                	ld	s6,32(sp)
    80003e50:	6be2                	ld	s7,24(sp)
    80003e52:	6c42                	ld	s8,16(sp)
    80003e54:	6ca2                	ld	s9,8(sp)
    80003e56:	6125                	addi	sp,sp,96
    80003e58:	8082                	ret
      iunlock(ip);
    80003e5a:	854e                	mv	a0,s3
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	aa6080e7          	jalr	-1370(ra) # 80003902 <iunlock>
      return ip;
    80003e64:	bfe9                	j	80003e3e <namex+0x6a>
      iunlockput(ip);
    80003e66:	854e                	mv	a0,s3
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	c3a080e7          	jalr	-966(ra) # 80003aa2 <iunlockput>
      return 0;
    80003e70:	89d2                	mv	s3,s4
    80003e72:	b7f1                	j	80003e3e <namex+0x6a>
  len = path - s;
    80003e74:	40b48633          	sub	a2,s1,a1
    80003e78:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e7c:	094cd463          	bge	s9,s4,80003f04 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e80:	4639                	li	a2,14
    80003e82:	8556                	mv	a0,s5
    80003e84:	ffffd097          	auipc	ra,0xffffd
    80003e88:	ebc080e7          	jalr	-324(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003e8c:	0004c783          	lbu	a5,0(s1)
    80003e90:	01279763          	bne	a5,s2,80003e9e <namex+0xca>
    path++;
    80003e94:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e96:	0004c783          	lbu	a5,0(s1)
    80003e9a:	ff278de3          	beq	a5,s2,80003e94 <namex+0xc0>
    ilock(ip);
    80003e9e:	854e                	mv	a0,s3
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	9a0080e7          	jalr	-1632(ra) # 80003840 <ilock>
    if(ip->type != T_DIR){
    80003ea8:	04499783          	lh	a5,68(s3)
    80003eac:	f98793e3          	bne	a5,s8,80003e32 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003eb0:	000b0563          	beqz	s6,80003eba <namex+0xe6>
    80003eb4:	0004c783          	lbu	a5,0(s1)
    80003eb8:	d3cd                	beqz	a5,80003e5a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eba:	865e                	mv	a2,s7
    80003ebc:	85d6                	mv	a1,s5
    80003ebe:	854e                	mv	a0,s3
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	e64080e7          	jalr	-412(ra) # 80003d24 <dirlookup>
    80003ec8:	8a2a                	mv	s4,a0
    80003eca:	dd51                	beqz	a0,80003e66 <namex+0x92>
    iunlockput(ip);
    80003ecc:	854e                	mv	a0,s3
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	bd4080e7          	jalr	-1068(ra) # 80003aa2 <iunlockput>
    ip = next;
    80003ed6:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ed8:	0004c783          	lbu	a5,0(s1)
    80003edc:	05279763          	bne	a5,s2,80003f2a <namex+0x156>
    path++;
    80003ee0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ee2:	0004c783          	lbu	a5,0(s1)
    80003ee6:	ff278de3          	beq	a5,s2,80003ee0 <namex+0x10c>
  if(*path == 0)
    80003eea:	c79d                	beqz	a5,80003f18 <namex+0x144>
    path++;
    80003eec:	85a6                	mv	a1,s1
  len = path - s;
    80003eee:	8a5e                	mv	s4,s7
    80003ef0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ef2:	01278963          	beq	a5,s2,80003f04 <namex+0x130>
    80003ef6:	dfbd                	beqz	a5,80003e74 <namex+0xa0>
    path++;
    80003ef8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003efa:	0004c783          	lbu	a5,0(s1)
    80003efe:	ff279ce3          	bne	a5,s2,80003ef6 <namex+0x122>
    80003f02:	bf8d                	j	80003e74 <namex+0xa0>
    memmove(name, s, len);
    80003f04:	2601                	sext.w	a2,a2
    80003f06:	8556                	mv	a0,s5
    80003f08:	ffffd097          	auipc	ra,0xffffd
    80003f0c:	e38080e7          	jalr	-456(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f10:	9a56                	add	s4,s4,s5
    80003f12:	000a0023          	sb	zero,0(s4)
    80003f16:	bf9d                	j	80003e8c <namex+0xb8>
  if(nameiparent){
    80003f18:	f20b03e3          	beqz	s6,80003e3e <namex+0x6a>
    iput(ip);
    80003f1c:	854e                	mv	a0,s3
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	adc080e7          	jalr	-1316(ra) # 800039fa <iput>
    return 0;
    80003f26:	4981                	li	s3,0
    80003f28:	bf19                	j	80003e3e <namex+0x6a>
  if(*path == 0)
    80003f2a:	d7fd                	beqz	a5,80003f18 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f2c:	0004c783          	lbu	a5,0(s1)
    80003f30:	85a6                	mv	a1,s1
    80003f32:	b7d1                	j	80003ef6 <namex+0x122>

0000000080003f34 <dirlink>:
{
    80003f34:	7139                	addi	sp,sp,-64
    80003f36:	fc06                	sd	ra,56(sp)
    80003f38:	f822                	sd	s0,48(sp)
    80003f3a:	f426                	sd	s1,40(sp)
    80003f3c:	f04a                	sd	s2,32(sp)
    80003f3e:	ec4e                	sd	s3,24(sp)
    80003f40:	e852                	sd	s4,16(sp)
    80003f42:	0080                	addi	s0,sp,64
    80003f44:	892a                	mv	s2,a0
    80003f46:	8a2e                	mv	s4,a1
    80003f48:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f4a:	4601                	li	a2,0
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	dd8080e7          	jalr	-552(ra) # 80003d24 <dirlookup>
    80003f54:	e93d                	bnez	a0,80003fca <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f56:	04c92483          	lw	s1,76(s2)
    80003f5a:	c49d                	beqz	s1,80003f88 <dirlink+0x54>
    80003f5c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f5e:	4741                	li	a4,16
    80003f60:	86a6                	mv	a3,s1
    80003f62:	fc040613          	addi	a2,s0,-64
    80003f66:	4581                	li	a1,0
    80003f68:	854a                	mv	a0,s2
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	b8a080e7          	jalr	-1142(ra) # 80003af4 <readi>
    80003f72:	47c1                	li	a5,16
    80003f74:	06f51163          	bne	a0,a5,80003fd6 <dirlink+0xa2>
    if(de.inum == 0)
    80003f78:	fc045783          	lhu	a5,-64(s0)
    80003f7c:	c791                	beqz	a5,80003f88 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f7e:	24c1                	addiw	s1,s1,16
    80003f80:	04c92783          	lw	a5,76(s2)
    80003f84:	fcf4ede3          	bltu	s1,a5,80003f5e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f88:	4639                	li	a2,14
    80003f8a:	85d2                	mv	a1,s4
    80003f8c:	fc240513          	addi	a0,s0,-62
    80003f90:	ffffd097          	auipc	ra,0xffffd
    80003f94:	e64080e7          	jalr	-412(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003f98:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f9c:	4741                	li	a4,16
    80003f9e:	86a6                	mv	a3,s1
    80003fa0:	fc040613          	addi	a2,s0,-64
    80003fa4:	4581                	li	a1,0
    80003fa6:	854a                	mv	a0,s2
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	c44080e7          	jalr	-956(ra) # 80003bec <writei>
    80003fb0:	872a                	mv	a4,a0
    80003fb2:	47c1                	li	a5,16
  return 0;
    80003fb4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb6:	02f71863          	bne	a4,a5,80003fe6 <dirlink+0xb2>
}
    80003fba:	70e2                	ld	ra,56(sp)
    80003fbc:	7442                	ld	s0,48(sp)
    80003fbe:	74a2                	ld	s1,40(sp)
    80003fc0:	7902                	ld	s2,32(sp)
    80003fc2:	69e2                	ld	s3,24(sp)
    80003fc4:	6a42                	ld	s4,16(sp)
    80003fc6:	6121                	addi	sp,sp,64
    80003fc8:	8082                	ret
    iput(ip);
    80003fca:	00000097          	auipc	ra,0x0
    80003fce:	a30080e7          	jalr	-1488(ra) # 800039fa <iput>
    return -1;
    80003fd2:	557d                	li	a0,-1
    80003fd4:	b7dd                	j	80003fba <dirlink+0x86>
      panic("dirlink read");
    80003fd6:	00004517          	auipc	a0,0x4
    80003fda:	68a50513          	addi	a0,a0,1674 # 80008660 <syscalls+0x1d8>
    80003fde:	ffffc097          	auipc	ra,0xffffc
    80003fe2:	560080e7          	jalr	1376(ra) # 8000053e <panic>
    panic("dirlink");
    80003fe6:	00004517          	auipc	a0,0x4
    80003fea:	78a50513          	addi	a0,a0,1930 # 80008770 <syscalls+0x2e8>
    80003fee:	ffffc097          	auipc	ra,0xffffc
    80003ff2:	550080e7          	jalr	1360(ra) # 8000053e <panic>

0000000080003ff6 <namei>:

struct inode*
namei(char *path)
{
    80003ff6:	1101                	addi	sp,sp,-32
    80003ff8:	ec06                	sd	ra,24(sp)
    80003ffa:	e822                	sd	s0,16(sp)
    80003ffc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ffe:	fe040613          	addi	a2,s0,-32
    80004002:	4581                	li	a1,0
    80004004:	00000097          	auipc	ra,0x0
    80004008:	dd0080e7          	jalr	-560(ra) # 80003dd4 <namex>
}
    8000400c:	60e2                	ld	ra,24(sp)
    8000400e:	6442                	ld	s0,16(sp)
    80004010:	6105                	addi	sp,sp,32
    80004012:	8082                	ret

0000000080004014 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004014:	1141                	addi	sp,sp,-16
    80004016:	e406                	sd	ra,8(sp)
    80004018:	e022                	sd	s0,0(sp)
    8000401a:	0800                	addi	s0,sp,16
    8000401c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000401e:	4585                	li	a1,1
    80004020:	00000097          	auipc	ra,0x0
    80004024:	db4080e7          	jalr	-588(ra) # 80003dd4 <namex>
}
    80004028:	60a2                	ld	ra,8(sp)
    8000402a:	6402                	ld	s0,0(sp)
    8000402c:	0141                	addi	sp,sp,16
    8000402e:	8082                	ret

0000000080004030 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004030:	1101                	addi	sp,sp,-32
    80004032:	ec06                	sd	ra,24(sp)
    80004034:	e822                	sd	s0,16(sp)
    80004036:	e426                	sd	s1,8(sp)
    80004038:	e04a                	sd	s2,0(sp)
    8000403a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000403c:	0001d917          	auipc	s2,0x1d
    80004040:	23490913          	addi	s2,s2,564 # 80021270 <log>
    80004044:	01892583          	lw	a1,24(s2)
    80004048:	02892503          	lw	a0,40(s2)
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	ff2080e7          	jalr	-14(ra) # 8000303e <bread>
    80004054:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004056:	02c92683          	lw	a3,44(s2)
    8000405a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000405c:	02d05763          	blez	a3,8000408a <write_head+0x5a>
    80004060:	0001d797          	auipc	a5,0x1d
    80004064:	24078793          	addi	a5,a5,576 # 800212a0 <log+0x30>
    80004068:	05c50713          	addi	a4,a0,92
    8000406c:	36fd                	addiw	a3,a3,-1
    8000406e:	1682                	slli	a3,a3,0x20
    80004070:	9281                	srli	a3,a3,0x20
    80004072:	068a                	slli	a3,a3,0x2
    80004074:	0001d617          	auipc	a2,0x1d
    80004078:	23060613          	addi	a2,a2,560 # 800212a4 <log+0x34>
    8000407c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000407e:	4390                	lw	a2,0(a5)
    80004080:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004082:	0791                	addi	a5,a5,4
    80004084:	0711                	addi	a4,a4,4
    80004086:	fed79ce3          	bne	a5,a3,8000407e <write_head+0x4e>
  }
  bwrite(buf);
    8000408a:	8526                	mv	a0,s1
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	0a4080e7          	jalr	164(ra) # 80003130 <bwrite>
  brelse(buf);
    80004094:	8526                	mv	a0,s1
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	0d8080e7          	jalr	216(ra) # 8000316e <brelse>
}
    8000409e:	60e2                	ld	ra,24(sp)
    800040a0:	6442                	ld	s0,16(sp)
    800040a2:	64a2                	ld	s1,8(sp)
    800040a4:	6902                	ld	s2,0(sp)
    800040a6:	6105                	addi	sp,sp,32
    800040a8:	8082                	ret

00000000800040aa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040aa:	0001d797          	auipc	a5,0x1d
    800040ae:	1f27a783          	lw	a5,498(a5) # 8002129c <log+0x2c>
    800040b2:	0af05d63          	blez	a5,8000416c <install_trans+0xc2>
{
    800040b6:	7139                	addi	sp,sp,-64
    800040b8:	fc06                	sd	ra,56(sp)
    800040ba:	f822                	sd	s0,48(sp)
    800040bc:	f426                	sd	s1,40(sp)
    800040be:	f04a                	sd	s2,32(sp)
    800040c0:	ec4e                	sd	s3,24(sp)
    800040c2:	e852                	sd	s4,16(sp)
    800040c4:	e456                	sd	s5,8(sp)
    800040c6:	e05a                	sd	s6,0(sp)
    800040c8:	0080                	addi	s0,sp,64
    800040ca:	8b2a                	mv	s6,a0
    800040cc:	0001da97          	auipc	s5,0x1d
    800040d0:	1d4a8a93          	addi	s5,s5,468 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040d4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040d6:	0001d997          	auipc	s3,0x1d
    800040da:	19a98993          	addi	s3,s3,410 # 80021270 <log>
    800040de:	a035                	j	8000410a <install_trans+0x60>
      bunpin(dbuf);
    800040e0:	8526                	mv	a0,s1
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	166080e7          	jalr	358(ra) # 80003248 <bunpin>
    brelse(lbuf);
    800040ea:	854a                	mv	a0,s2
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	082080e7          	jalr	130(ra) # 8000316e <brelse>
    brelse(dbuf);
    800040f4:	8526                	mv	a0,s1
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	078080e7          	jalr	120(ra) # 8000316e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040fe:	2a05                	addiw	s4,s4,1
    80004100:	0a91                	addi	s5,s5,4
    80004102:	02c9a783          	lw	a5,44(s3)
    80004106:	04fa5963          	bge	s4,a5,80004158 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000410a:	0189a583          	lw	a1,24(s3)
    8000410e:	014585bb          	addw	a1,a1,s4
    80004112:	2585                	addiw	a1,a1,1
    80004114:	0289a503          	lw	a0,40(s3)
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	f26080e7          	jalr	-218(ra) # 8000303e <bread>
    80004120:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004122:	000aa583          	lw	a1,0(s5)
    80004126:	0289a503          	lw	a0,40(s3)
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	f14080e7          	jalr	-236(ra) # 8000303e <bread>
    80004132:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004134:	40000613          	li	a2,1024
    80004138:	05890593          	addi	a1,s2,88
    8000413c:	05850513          	addi	a0,a0,88
    80004140:	ffffd097          	auipc	ra,0xffffd
    80004144:	c00080e7          	jalr	-1024(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004148:	8526                	mv	a0,s1
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	fe6080e7          	jalr	-26(ra) # 80003130 <bwrite>
    if(recovering == 0)
    80004152:	f80b1ce3          	bnez	s6,800040ea <install_trans+0x40>
    80004156:	b769                	j	800040e0 <install_trans+0x36>
}
    80004158:	70e2                	ld	ra,56(sp)
    8000415a:	7442                	ld	s0,48(sp)
    8000415c:	74a2                	ld	s1,40(sp)
    8000415e:	7902                	ld	s2,32(sp)
    80004160:	69e2                	ld	s3,24(sp)
    80004162:	6a42                	ld	s4,16(sp)
    80004164:	6aa2                	ld	s5,8(sp)
    80004166:	6b02                	ld	s6,0(sp)
    80004168:	6121                	addi	sp,sp,64
    8000416a:	8082                	ret
    8000416c:	8082                	ret

000000008000416e <initlog>:
{
    8000416e:	7179                	addi	sp,sp,-48
    80004170:	f406                	sd	ra,40(sp)
    80004172:	f022                	sd	s0,32(sp)
    80004174:	ec26                	sd	s1,24(sp)
    80004176:	e84a                	sd	s2,16(sp)
    80004178:	e44e                	sd	s3,8(sp)
    8000417a:	1800                	addi	s0,sp,48
    8000417c:	892a                	mv	s2,a0
    8000417e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004180:	0001d497          	auipc	s1,0x1d
    80004184:	0f048493          	addi	s1,s1,240 # 80021270 <log>
    80004188:	00004597          	auipc	a1,0x4
    8000418c:	4e858593          	addi	a1,a1,1256 # 80008670 <syscalls+0x1e8>
    80004190:	8526                	mv	a0,s1
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	9c2080e7          	jalr	-1598(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000419a:	0149a583          	lw	a1,20(s3)
    8000419e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041a0:	0109a783          	lw	a5,16(s3)
    800041a4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041a6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041aa:	854a                	mv	a0,s2
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	e92080e7          	jalr	-366(ra) # 8000303e <bread>
  log.lh.n = lh->n;
    800041b4:	4d3c                	lw	a5,88(a0)
    800041b6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041b8:	02f05563          	blez	a5,800041e2 <initlog+0x74>
    800041bc:	05c50713          	addi	a4,a0,92
    800041c0:	0001d697          	auipc	a3,0x1d
    800041c4:	0e068693          	addi	a3,a3,224 # 800212a0 <log+0x30>
    800041c8:	37fd                	addiw	a5,a5,-1
    800041ca:	1782                	slli	a5,a5,0x20
    800041cc:	9381                	srli	a5,a5,0x20
    800041ce:	078a                	slli	a5,a5,0x2
    800041d0:	06050613          	addi	a2,a0,96
    800041d4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041d6:	4310                	lw	a2,0(a4)
    800041d8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041da:	0711                	addi	a4,a4,4
    800041dc:	0691                	addi	a3,a3,4
    800041de:	fef71ce3          	bne	a4,a5,800041d6 <initlog+0x68>
  brelse(buf);
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	f8c080e7          	jalr	-116(ra) # 8000316e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041ea:	4505                	li	a0,1
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	ebe080e7          	jalr	-322(ra) # 800040aa <install_trans>
  log.lh.n = 0;
    800041f4:	0001d797          	auipc	a5,0x1d
    800041f8:	0a07a423          	sw	zero,168(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	e34080e7          	jalr	-460(ra) # 80004030 <write_head>
}
    80004204:	70a2                	ld	ra,40(sp)
    80004206:	7402                	ld	s0,32(sp)
    80004208:	64e2                	ld	s1,24(sp)
    8000420a:	6942                	ld	s2,16(sp)
    8000420c:	69a2                	ld	s3,8(sp)
    8000420e:	6145                	addi	sp,sp,48
    80004210:	8082                	ret

0000000080004212 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004212:	1101                	addi	sp,sp,-32
    80004214:	ec06                	sd	ra,24(sp)
    80004216:	e822                	sd	s0,16(sp)
    80004218:	e426                	sd	s1,8(sp)
    8000421a:	e04a                	sd	s2,0(sp)
    8000421c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000421e:	0001d517          	auipc	a0,0x1d
    80004222:	05250513          	addi	a0,a0,82 # 80021270 <log>
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	9be080e7          	jalr	-1602(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000422e:	0001d497          	auipc	s1,0x1d
    80004232:	04248493          	addi	s1,s1,66 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004236:	4979                	li	s2,30
    80004238:	a039                	j	80004246 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000423a:	85a6                	mv	a1,s1
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffe097          	auipc	ra,0xffffe
    80004242:	00c080e7          	jalr	12(ra) # 8000224a <sleep>
    if(log.committing){
    80004246:	50dc                	lw	a5,36(s1)
    80004248:	fbed                	bnez	a5,8000423a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000424a:	509c                	lw	a5,32(s1)
    8000424c:	0017871b          	addiw	a4,a5,1
    80004250:	0007069b          	sext.w	a3,a4
    80004254:	0027179b          	slliw	a5,a4,0x2
    80004258:	9fb9                	addw	a5,a5,a4
    8000425a:	0017979b          	slliw	a5,a5,0x1
    8000425e:	54d8                	lw	a4,44(s1)
    80004260:	9fb9                	addw	a5,a5,a4
    80004262:	00f95963          	bge	s2,a5,80004274 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004266:	85a6                	mv	a1,s1
    80004268:	8526                	mv	a0,s1
    8000426a:	ffffe097          	auipc	ra,0xffffe
    8000426e:	fe0080e7          	jalr	-32(ra) # 8000224a <sleep>
    80004272:	bfd1                	j	80004246 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004274:	0001d517          	auipc	a0,0x1d
    80004278:	ffc50513          	addi	a0,a0,-4 # 80021270 <log>
    8000427c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	a1a080e7          	jalr	-1510(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004286:	60e2                	ld	ra,24(sp)
    80004288:	6442                	ld	s0,16(sp)
    8000428a:	64a2                	ld	s1,8(sp)
    8000428c:	6902                	ld	s2,0(sp)
    8000428e:	6105                	addi	sp,sp,32
    80004290:	8082                	ret

0000000080004292 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004292:	7139                	addi	sp,sp,-64
    80004294:	fc06                	sd	ra,56(sp)
    80004296:	f822                	sd	s0,48(sp)
    80004298:	f426                	sd	s1,40(sp)
    8000429a:	f04a                	sd	s2,32(sp)
    8000429c:	ec4e                	sd	s3,24(sp)
    8000429e:	e852                	sd	s4,16(sp)
    800042a0:	e456                	sd	s5,8(sp)
    800042a2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042a4:	0001d497          	auipc	s1,0x1d
    800042a8:	fcc48493          	addi	s1,s1,-52 # 80021270 <log>
    800042ac:	8526                	mv	a0,s1
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	936080e7          	jalr	-1738(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800042b6:	509c                	lw	a5,32(s1)
    800042b8:	37fd                	addiw	a5,a5,-1
    800042ba:	0007891b          	sext.w	s2,a5
    800042be:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042c0:	50dc                	lw	a5,36(s1)
    800042c2:	efb9                	bnez	a5,80004320 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042c4:	06091663          	bnez	s2,80004330 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042c8:	0001d497          	auipc	s1,0x1d
    800042cc:	fa848493          	addi	s1,s1,-88 # 80021270 <log>
    800042d0:	4785                	li	a5,1
    800042d2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042d4:	8526                	mv	a0,s1
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	9c2080e7          	jalr	-1598(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042de:	54dc                	lw	a5,44(s1)
    800042e0:	06f04763          	bgtz	a5,8000434e <end_op+0xbc>
    acquire(&log.lock);
    800042e4:	0001d497          	auipc	s1,0x1d
    800042e8:	f8c48493          	addi	s1,s1,-116 # 80021270 <log>
    800042ec:	8526                	mv	a0,s1
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	8f6080e7          	jalr	-1802(ra) # 80000be4 <acquire>
    log.committing = 0;
    800042f6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042fa:	8526                	mv	a0,s1
    800042fc:	ffffe097          	auipc	ra,0xffffe
    80004300:	0da080e7          	jalr	218(ra) # 800023d6 <wakeup>
    release(&log.lock);
    80004304:	8526                	mv	a0,s1
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	992080e7          	jalr	-1646(ra) # 80000c98 <release>
}
    8000430e:	70e2                	ld	ra,56(sp)
    80004310:	7442                	ld	s0,48(sp)
    80004312:	74a2                	ld	s1,40(sp)
    80004314:	7902                	ld	s2,32(sp)
    80004316:	69e2                	ld	s3,24(sp)
    80004318:	6a42                	ld	s4,16(sp)
    8000431a:	6aa2                	ld	s5,8(sp)
    8000431c:	6121                	addi	sp,sp,64
    8000431e:	8082                	ret
    panic("log.committing");
    80004320:	00004517          	auipc	a0,0x4
    80004324:	35850513          	addi	a0,a0,856 # 80008678 <syscalls+0x1f0>
    80004328:	ffffc097          	auipc	ra,0xffffc
    8000432c:	216080e7          	jalr	534(ra) # 8000053e <panic>
    wakeup(&log);
    80004330:	0001d497          	auipc	s1,0x1d
    80004334:	f4048493          	addi	s1,s1,-192 # 80021270 <log>
    80004338:	8526                	mv	a0,s1
    8000433a:	ffffe097          	auipc	ra,0xffffe
    8000433e:	09c080e7          	jalr	156(ra) # 800023d6 <wakeup>
  release(&log.lock);
    80004342:	8526                	mv	a0,s1
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	954080e7          	jalr	-1708(ra) # 80000c98 <release>
  if(do_commit){
    8000434c:	b7c9                	j	8000430e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000434e:	0001da97          	auipc	s5,0x1d
    80004352:	f52a8a93          	addi	s5,s5,-174 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004356:	0001da17          	auipc	s4,0x1d
    8000435a:	f1aa0a13          	addi	s4,s4,-230 # 80021270 <log>
    8000435e:	018a2583          	lw	a1,24(s4)
    80004362:	012585bb          	addw	a1,a1,s2
    80004366:	2585                	addiw	a1,a1,1
    80004368:	028a2503          	lw	a0,40(s4)
    8000436c:	fffff097          	auipc	ra,0xfffff
    80004370:	cd2080e7          	jalr	-814(ra) # 8000303e <bread>
    80004374:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004376:	000aa583          	lw	a1,0(s5)
    8000437a:	028a2503          	lw	a0,40(s4)
    8000437e:	fffff097          	auipc	ra,0xfffff
    80004382:	cc0080e7          	jalr	-832(ra) # 8000303e <bread>
    80004386:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004388:	40000613          	li	a2,1024
    8000438c:	05850593          	addi	a1,a0,88
    80004390:	05848513          	addi	a0,s1,88
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	9ac080e7          	jalr	-1620(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000439c:	8526                	mv	a0,s1
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	d92080e7          	jalr	-622(ra) # 80003130 <bwrite>
    brelse(from);
    800043a6:	854e                	mv	a0,s3
    800043a8:	fffff097          	auipc	ra,0xfffff
    800043ac:	dc6080e7          	jalr	-570(ra) # 8000316e <brelse>
    brelse(to);
    800043b0:	8526                	mv	a0,s1
    800043b2:	fffff097          	auipc	ra,0xfffff
    800043b6:	dbc080e7          	jalr	-580(ra) # 8000316e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ba:	2905                	addiw	s2,s2,1
    800043bc:	0a91                	addi	s5,s5,4
    800043be:	02ca2783          	lw	a5,44(s4)
    800043c2:	f8f94ee3          	blt	s2,a5,8000435e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	c6a080e7          	jalr	-918(ra) # 80004030 <write_head>
    install_trans(0); // Now install writes to home locations
    800043ce:	4501                	li	a0,0
    800043d0:	00000097          	auipc	ra,0x0
    800043d4:	cda080e7          	jalr	-806(ra) # 800040aa <install_trans>
    log.lh.n = 0;
    800043d8:	0001d797          	auipc	a5,0x1d
    800043dc:	ec07a223          	sw	zero,-316(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043e0:	00000097          	auipc	ra,0x0
    800043e4:	c50080e7          	jalr	-944(ra) # 80004030 <write_head>
    800043e8:	bdf5                	j	800042e4 <end_op+0x52>

00000000800043ea <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043ea:	1101                	addi	sp,sp,-32
    800043ec:	ec06                	sd	ra,24(sp)
    800043ee:	e822                	sd	s0,16(sp)
    800043f0:	e426                	sd	s1,8(sp)
    800043f2:	e04a                	sd	s2,0(sp)
    800043f4:	1000                	addi	s0,sp,32
    800043f6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043f8:	0001d917          	auipc	s2,0x1d
    800043fc:	e7890913          	addi	s2,s2,-392 # 80021270 <log>
    80004400:	854a                	mv	a0,s2
    80004402:	ffffc097          	auipc	ra,0xffffc
    80004406:	7e2080e7          	jalr	2018(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000440a:	02c92603          	lw	a2,44(s2)
    8000440e:	47f5                	li	a5,29
    80004410:	06c7c563          	blt	a5,a2,8000447a <log_write+0x90>
    80004414:	0001d797          	auipc	a5,0x1d
    80004418:	e787a783          	lw	a5,-392(a5) # 8002128c <log+0x1c>
    8000441c:	37fd                	addiw	a5,a5,-1
    8000441e:	04f65e63          	bge	a2,a5,8000447a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004422:	0001d797          	auipc	a5,0x1d
    80004426:	e6e7a783          	lw	a5,-402(a5) # 80021290 <log+0x20>
    8000442a:	06f05063          	blez	a5,8000448a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000442e:	4781                	li	a5,0
    80004430:	06c05563          	blez	a2,8000449a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004434:	44cc                	lw	a1,12(s1)
    80004436:	0001d717          	auipc	a4,0x1d
    8000443a:	e6a70713          	addi	a4,a4,-406 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000443e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004440:	4314                	lw	a3,0(a4)
    80004442:	04b68c63          	beq	a3,a1,8000449a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004446:	2785                	addiw	a5,a5,1
    80004448:	0711                	addi	a4,a4,4
    8000444a:	fef61be3          	bne	a2,a5,80004440 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000444e:	0621                	addi	a2,a2,8
    80004450:	060a                	slli	a2,a2,0x2
    80004452:	0001d797          	auipc	a5,0x1d
    80004456:	e1e78793          	addi	a5,a5,-482 # 80021270 <log>
    8000445a:	963e                	add	a2,a2,a5
    8000445c:	44dc                	lw	a5,12(s1)
    8000445e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004460:	8526                	mv	a0,s1
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	daa080e7          	jalr	-598(ra) # 8000320c <bpin>
    log.lh.n++;
    8000446a:	0001d717          	auipc	a4,0x1d
    8000446e:	e0670713          	addi	a4,a4,-506 # 80021270 <log>
    80004472:	575c                	lw	a5,44(a4)
    80004474:	2785                	addiw	a5,a5,1
    80004476:	d75c                	sw	a5,44(a4)
    80004478:	a835                	j	800044b4 <log_write+0xca>
    panic("too big a transaction");
    8000447a:	00004517          	auipc	a0,0x4
    8000447e:	20e50513          	addi	a0,a0,526 # 80008688 <syscalls+0x200>
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	0bc080e7          	jalr	188(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000448a:	00004517          	auipc	a0,0x4
    8000448e:	21650513          	addi	a0,a0,534 # 800086a0 <syscalls+0x218>
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	0ac080e7          	jalr	172(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000449a:	00878713          	addi	a4,a5,8
    8000449e:	00271693          	slli	a3,a4,0x2
    800044a2:	0001d717          	auipc	a4,0x1d
    800044a6:	dce70713          	addi	a4,a4,-562 # 80021270 <log>
    800044aa:	9736                	add	a4,a4,a3
    800044ac:	44d4                	lw	a3,12(s1)
    800044ae:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044b0:	faf608e3          	beq	a2,a5,80004460 <log_write+0x76>
  }
  release(&log.lock);
    800044b4:	0001d517          	auipc	a0,0x1d
    800044b8:	dbc50513          	addi	a0,a0,-580 # 80021270 <log>
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	7dc080e7          	jalr	2012(ra) # 80000c98 <release>
}
    800044c4:	60e2                	ld	ra,24(sp)
    800044c6:	6442                	ld	s0,16(sp)
    800044c8:	64a2                	ld	s1,8(sp)
    800044ca:	6902                	ld	s2,0(sp)
    800044cc:	6105                	addi	sp,sp,32
    800044ce:	8082                	ret

00000000800044d0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044d0:	1101                	addi	sp,sp,-32
    800044d2:	ec06                	sd	ra,24(sp)
    800044d4:	e822                	sd	s0,16(sp)
    800044d6:	e426                	sd	s1,8(sp)
    800044d8:	e04a                	sd	s2,0(sp)
    800044da:	1000                	addi	s0,sp,32
    800044dc:	84aa                	mv	s1,a0
    800044de:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044e0:	00004597          	auipc	a1,0x4
    800044e4:	1e058593          	addi	a1,a1,480 # 800086c0 <syscalls+0x238>
    800044e8:	0521                	addi	a0,a0,8
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	66a080e7          	jalr	1642(ra) # 80000b54 <initlock>
  lk->name = name;
    800044f2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044f6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fa:	0204a423          	sw	zero,40(s1)
}
    800044fe:	60e2                	ld	ra,24(sp)
    80004500:	6442                	ld	s0,16(sp)
    80004502:	64a2                	ld	s1,8(sp)
    80004504:	6902                	ld	s2,0(sp)
    80004506:	6105                	addi	sp,sp,32
    80004508:	8082                	ret

000000008000450a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000450a:	1101                	addi	sp,sp,-32
    8000450c:	ec06                	sd	ra,24(sp)
    8000450e:	e822                	sd	s0,16(sp)
    80004510:	e426                	sd	s1,8(sp)
    80004512:	e04a                	sd	s2,0(sp)
    80004514:	1000                	addi	s0,sp,32
    80004516:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004518:	00850913          	addi	s2,a0,8
    8000451c:	854a                	mv	a0,s2
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	6c6080e7          	jalr	1734(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004526:	409c                	lw	a5,0(s1)
    80004528:	cb89                	beqz	a5,8000453a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000452a:	85ca                	mv	a1,s2
    8000452c:	8526                	mv	a0,s1
    8000452e:	ffffe097          	auipc	ra,0xffffe
    80004532:	d1c080e7          	jalr	-740(ra) # 8000224a <sleep>
  while (lk->locked) {
    80004536:	409c                	lw	a5,0(s1)
    80004538:	fbed                	bnez	a5,8000452a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000453a:	4785                	li	a5,1
    8000453c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000453e:	ffffd097          	auipc	ra,0xffffd
    80004542:	596080e7          	jalr	1430(ra) # 80001ad4 <myproc>
    80004546:	591c                	lw	a5,48(a0)
    80004548:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000454a:	854a                	mv	a0,s2
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	74c080e7          	jalr	1868(ra) # 80000c98 <release>
}
    80004554:	60e2                	ld	ra,24(sp)
    80004556:	6442                	ld	s0,16(sp)
    80004558:	64a2                	ld	s1,8(sp)
    8000455a:	6902                	ld	s2,0(sp)
    8000455c:	6105                	addi	sp,sp,32
    8000455e:	8082                	ret

0000000080004560 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004560:	1101                	addi	sp,sp,-32
    80004562:	ec06                	sd	ra,24(sp)
    80004564:	e822                	sd	s0,16(sp)
    80004566:	e426                	sd	s1,8(sp)
    80004568:	e04a                	sd	s2,0(sp)
    8000456a:	1000                	addi	s0,sp,32
    8000456c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000456e:	00850913          	addi	s2,a0,8
    80004572:	854a                	mv	a0,s2
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	670080e7          	jalr	1648(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000457c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004580:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004584:	8526                	mv	a0,s1
    80004586:	ffffe097          	auipc	ra,0xffffe
    8000458a:	e50080e7          	jalr	-432(ra) # 800023d6 <wakeup>
  release(&lk->lk);
    8000458e:	854a                	mv	a0,s2
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	708080e7          	jalr	1800(ra) # 80000c98 <release>
}
    80004598:	60e2                	ld	ra,24(sp)
    8000459a:	6442                	ld	s0,16(sp)
    8000459c:	64a2                	ld	s1,8(sp)
    8000459e:	6902                	ld	s2,0(sp)
    800045a0:	6105                	addi	sp,sp,32
    800045a2:	8082                	ret

00000000800045a4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045a4:	7179                	addi	sp,sp,-48
    800045a6:	f406                	sd	ra,40(sp)
    800045a8:	f022                	sd	s0,32(sp)
    800045aa:	ec26                	sd	s1,24(sp)
    800045ac:	e84a                	sd	s2,16(sp)
    800045ae:	e44e                	sd	s3,8(sp)
    800045b0:	1800                	addi	s0,sp,48
    800045b2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045b4:	00850913          	addi	s2,a0,8
    800045b8:	854a                	mv	a0,s2
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	62a080e7          	jalr	1578(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c2:	409c                	lw	a5,0(s1)
    800045c4:	ef99                	bnez	a5,800045e2 <holdingsleep+0x3e>
    800045c6:	4481                	li	s1,0
  release(&lk->lk);
    800045c8:	854a                	mv	a0,s2
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	6ce080e7          	jalr	1742(ra) # 80000c98 <release>
  return r;
}
    800045d2:	8526                	mv	a0,s1
    800045d4:	70a2                	ld	ra,40(sp)
    800045d6:	7402                	ld	s0,32(sp)
    800045d8:	64e2                	ld	s1,24(sp)
    800045da:	6942                	ld	s2,16(sp)
    800045dc:	69a2                	ld	s3,8(sp)
    800045de:	6145                	addi	sp,sp,48
    800045e0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045e2:	0284a983          	lw	s3,40(s1)
    800045e6:	ffffd097          	auipc	ra,0xffffd
    800045ea:	4ee080e7          	jalr	1262(ra) # 80001ad4 <myproc>
    800045ee:	5904                	lw	s1,48(a0)
    800045f0:	413484b3          	sub	s1,s1,s3
    800045f4:	0014b493          	seqz	s1,s1
    800045f8:	bfc1                	j	800045c8 <holdingsleep+0x24>

00000000800045fa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045fa:	1141                	addi	sp,sp,-16
    800045fc:	e406                	sd	ra,8(sp)
    800045fe:	e022                	sd	s0,0(sp)
    80004600:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004602:	00004597          	auipc	a1,0x4
    80004606:	0ce58593          	addi	a1,a1,206 # 800086d0 <syscalls+0x248>
    8000460a:	0001d517          	auipc	a0,0x1d
    8000460e:	dae50513          	addi	a0,a0,-594 # 800213b8 <ftable>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	542080e7          	jalr	1346(ra) # 80000b54 <initlock>
}
    8000461a:	60a2                	ld	ra,8(sp)
    8000461c:	6402                	ld	s0,0(sp)
    8000461e:	0141                	addi	sp,sp,16
    80004620:	8082                	ret

0000000080004622 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004622:	1101                	addi	sp,sp,-32
    80004624:	ec06                	sd	ra,24(sp)
    80004626:	e822                	sd	s0,16(sp)
    80004628:	e426                	sd	s1,8(sp)
    8000462a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000462c:	0001d517          	auipc	a0,0x1d
    80004630:	d8c50513          	addi	a0,a0,-628 # 800213b8 <ftable>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	5b0080e7          	jalr	1456(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000463c:	0001d497          	auipc	s1,0x1d
    80004640:	d9448493          	addi	s1,s1,-620 # 800213d0 <ftable+0x18>
    80004644:	0001e717          	auipc	a4,0x1e
    80004648:	d2c70713          	addi	a4,a4,-724 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    8000464c:	40dc                	lw	a5,4(s1)
    8000464e:	cf99                	beqz	a5,8000466c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004650:	02848493          	addi	s1,s1,40
    80004654:	fee49ce3          	bne	s1,a4,8000464c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004658:	0001d517          	auipc	a0,0x1d
    8000465c:	d6050513          	addi	a0,a0,-672 # 800213b8 <ftable>
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	638080e7          	jalr	1592(ra) # 80000c98 <release>
  return 0;
    80004668:	4481                	li	s1,0
    8000466a:	a819                	j	80004680 <filealloc+0x5e>
      f->ref = 1;
    8000466c:	4785                	li	a5,1
    8000466e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004670:	0001d517          	auipc	a0,0x1d
    80004674:	d4850513          	addi	a0,a0,-696 # 800213b8 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	620080e7          	jalr	1568(ra) # 80000c98 <release>
}
    80004680:	8526                	mv	a0,s1
    80004682:	60e2                	ld	ra,24(sp)
    80004684:	6442                	ld	s0,16(sp)
    80004686:	64a2                	ld	s1,8(sp)
    80004688:	6105                	addi	sp,sp,32
    8000468a:	8082                	ret

000000008000468c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000468c:	1101                	addi	sp,sp,-32
    8000468e:	ec06                	sd	ra,24(sp)
    80004690:	e822                	sd	s0,16(sp)
    80004692:	e426                	sd	s1,8(sp)
    80004694:	1000                	addi	s0,sp,32
    80004696:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004698:	0001d517          	auipc	a0,0x1d
    8000469c:	d2050513          	addi	a0,a0,-736 # 800213b8 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	544080e7          	jalr	1348(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046a8:	40dc                	lw	a5,4(s1)
    800046aa:	02f05263          	blez	a5,800046ce <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046ae:	2785                	addiw	a5,a5,1
    800046b0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046b2:	0001d517          	auipc	a0,0x1d
    800046b6:	d0650513          	addi	a0,a0,-762 # 800213b8 <ftable>
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	5de080e7          	jalr	1502(ra) # 80000c98 <release>
  return f;
}
    800046c2:	8526                	mv	a0,s1
    800046c4:	60e2                	ld	ra,24(sp)
    800046c6:	6442                	ld	s0,16(sp)
    800046c8:	64a2                	ld	s1,8(sp)
    800046ca:	6105                	addi	sp,sp,32
    800046cc:	8082                	ret
    panic("filedup");
    800046ce:	00004517          	auipc	a0,0x4
    800046d2:	00a50513          	addi	a0,a0,10 # 800086d8 <syscalls+0x250>
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	e68080e7          	jalr	-408(ra) # 8000053e <panic>

00000000800046de <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046de:	7139                	addi	sp,sp,-64
    800046e0:	fc06                	sd	ra,56(sp)
    800046e2:	f822                	sd	s0,48(sp)
    800046e4:	f426                	sd	s1,40(sp)
    800046e6:	f04a                	sd	s2,32(sp)
    800046e8:	ec4e                	sd	s3,24(sp)
    800046ea:	e852                	sd	s4,16(sp)
    800046ec:	e456                	sd	s5,8(sp)
    800046ee:	0080                	addi	s0,sp,64
    800046f0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046f2:	0001d517          	auipc	a0,0x1d
    800046f6:	cc650513          	addi	a0,a0,-826 # 800213b8 <ftable>
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	4ea080e7          	jalr	1258(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004702:	40dc                	lw	a5,4(s1)
    80004704:	06f05163          	blez	a5,80004766 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004708:	37fd                	addiw	a5,a5,-1
    8000470a:	0007871b          	sext.w	a4,a5
    8000470e:	c0dc                	sw	a5,4(s1)
    80004710:	06e04363          	bgtz	a4,80004776 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004714:	0004a903          	lw	s2,0(s1)
    80004718:	0094ca83          	lbu	s5,9(s1)
    8000471c:	0104ba03          	ld	s4,16(s1)
    80004720:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004724:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004728:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000472c:	0001d517          	auipc	a0,0x1d
    80004730:	c8c50513          	addi	a0,a0,-884 # 800213b8 <ftable>
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	564080e7          	jalr	1380(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000473c:	4785                	li	a5,1
    8000473e:	04f90d63          	beq	s2,a5,80004798 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004742:	3979                	addiw	s2,s2,-2
    80004744:	4785                	li	a5,1
    80004746:	0527e063          	bltu	a5,s2,80004786 <fileclose+0xa8>
    begin_op();
    8000474a:	00000097          	auipc	ra,0x0
    8000474e:	ac8080e7          	jalr	-1336(ra) # 80004212 <begin_op>
    iput(ff.ip);
    80004752:	854e                	mv	a0,s3
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	2a6080e7          	jalr	678(ra) # 800039fa <iput>
    end_op();
    8000475c:	00000097          	auipc	ra,0x0
    80004760:	b36080e7          	jalr	-1226(ra) # 80004292 <end_op>
    80004764:	a00d                	j	80004786 <fileclose+0xa8>
    panic("fileclose");
    80004766:	00004517          	auipc	a0,0x4
    8000476a:	f7a50513          	addi	a0,a0,-134 # 800086e0 <syscalls+0x258>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	dd0080e7          	jalr	-560(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004776:	0001d517          	auipc	a0,0x1d
    8000477a:	c4250513          	addi	a0,a0,-958 # 800213b8 <ftable>
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	51a080e7          	jalr	1306(ra) # 80000c98 <release>
  }
}
    80004786:	70e2                	ld	ra,56(sp)
    80004788:	7442                	ld	s0,48(sp)
    8000478a:	74a2                	ld	s1,40(sp)
    8000478c:	7902                	ld	s2,32(sp)
    8000478e:	69e2                	ld	s3,24(sp)
    80004790:	6a42                	ld	s4,16(sp)
    80004792:	6aa2                	ld	s5,8(sp)
    80004794:	6121                	addi	sp,sp,64
    80004796:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004798:	85d6                	mv	a1,s5
    8000479a:	8552                	mv	a0,s4
    8000479c:	00000097          	auipc	ra,0x0
    800047a0:	34c080e7          	jalr	844(ra) # 80004ae8 <pipeclose>
    800047a4:	b7cd                	j	80004786 <fileclose+0xa8>

00000000800047a6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047a6:	715d                	addi	sp,sp,-80
    800047a8:	e486                	sd	ra,72(sp)
    800047aa:	e0a2                	sd	s0,64(sp)
    800047ac:	fc26                	sd	s1,56(sp)
    800047ae:	f84a                	sd	s2,48(sp)
    800047b0:	f44e                	sd	s3,40(sp)
    800047b2:	0880                	addi	s0,sp,80
    800047b4:	84aa                	mv	s1,a0
    800047b6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047b8:	ffffd097          	auipc	ra,0xffffd
    800047bc:	31c080e7          	jalr	796(ra) # 80001ad4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047c0:	409c                	lw	a5,0(s1)
    800047c2:	37f9                	addiw	a5,a5,-2
    800047c4:	4705                	li	a4,1
    800047c6:	04f76763          	bltu	a4,a5,80004814 <filestat+0x6e>
    800047ca:	892a                	mv	s2,a0
    ilock(f->ip);
    800047cc:	6c88                	ld	a0,24(s1)
    800047ce:	fffff097          	auipc	ra,0xfffff
    800047d2:	072080e7          	jalr	114(ra) # 80003840 <ilock>
    stati(f->ip, &st);
    800047d6:	fb840593          	addi	a1,s0,-72
    800047da:	6c88                	ld	a0,24(s1)
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	2ee080e7          	jalr	750(ra) # 80003aca <stati>
    iunlock(f->ip);
    800047e4:	6c88                	ld	a0,24(s1)
    800047e6:	fffff097          	auipc	ra,0xfffff
    800047ea:	11c080e7          	jalr	284(ra) # 80003902 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047ee:	46e1                	li	a3,24
    800047f0:	fb840613          	addi	a2,s0,-72
    800047f4:	85ce                	mv	a1,s3
    800047f6:	05093503          	ld	a0,80(s2)
    800047fa:	ffffd097          	auipc	ra,0xffffd
    800047fe:	f9c080e7          	jalr	-100(ra) # 80001796 <copyout>
    80004802:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004806:	60a6                	ld	ra,72(sp)
    80004808:	6406                	ld	s0,64(sp)
    8000480a:	74e2                	ld	s1,56(sp)
    8000480c:	7942                	ld	s2,48(sp)
    8000480e:	79a2                	ld	s3,40(sp)
    80004810:	6161                	addi	sp,sp,80
    80004812:	8082                	ret
  return -1;
    80004814:	557d                	li	a0,-1
    80004816:	bfc5                	j	80004806 <filestat+0x60>

0000000080004818 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004818:	7179                	addi	sp,sp,-48
    8000481a:	f406                	sd	ra,40(sp)
    8000481c:	f022                	sd	s0,32(sp)
    8000481e:	ec26                	sd	s1,24(sp)
    80004820:	e84a                	sd	s2,16(sp)
    80004822:	e44e                	sd	s3,8(sp)
    80004824:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004826:	00854783          	lbu	a5,8(a0)
    8000482a:	c3d5                	beqz	a5,800048ce <fileread+0xb6>
    8000482c:	84aa                	mv	s1,a0
    8000482e:	89ae                	mv	s3,a1
    80004830:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004832:	411c                	lw	a5,0(a0)
    80004834:	4705                	li	a4,1
    80004836:	04e78963          	beq	a5,a4,80004888 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000483a:	470d                	li	a4,3
    8000483c:	04e78d63          	beq	a5,a4,80004896 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004840:	4709                	li	a4,2
    80004842:	06e79e63          	bne	a5,a4,800048be <fileread+0xa6>
    ilock(f->ip);
    80004846:	6d08                	ld	a0,24(a0)
    80004848:	fffff097          	auipc	ra,0xfffff
    8000484c:	ff8080e7          	jalr	-8(ra) # 80003840 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004850:	874a                	mv	a4,s2
    80004852:	5094                	lw	a3,32(s1)
    80004854:	864e                	mv	a2,s3
    80004856:	4585                	li	a1,1
    80004858:	6c88                	ld	a0,24(s1)
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	29a080e7          	jalr	666(ra) # 80003af4 <readi>
    80004862:	892a                	mv	s2,a0
    80004864:	00a05563          	blez	a0,8000486e <fileread+0x56>
      f->off += r;
    80004868:	509c                	lw	a5,32(s1)
    8000486a:	9fa9                	addw	a5,a5,a0
    8000486c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000486e:	6c88                	ld	a0,24(s1)
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	092080e7          	jalr	146(ra) # 80003902 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004878:	854a                	mv	a0,s2
    8000487a:	70a2                	ld	ra,40(sp)
    8000487c:	7402                	ld	s0,32(sp)
    8000487e:	64e2                	ld	s1,24(sp)
    80004880:	6942                	ld	s2,16(sp)
    80004882:	69a2                	ld	s3,8(sp)
    80004884:	6145                	addi	sp,sp,48
    80004886:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004888:	6908                	ld	a0,16(a0)
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	3c8080e7          	jalr	968(ra) # 80004c52 <piperead>
    80004892:	892a                	mv	s2,a0
    80004894:	b7d5                	j	80004878 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004896:	02451783          	lh	a5,36(a0)
    8000489a:	03079693          	slli	a3,a5,0x30
    8000489e:	92c1                	srli	a3,a3,0x30
    800048a0:	4725                	li	a4,9
    800048a2:	02d76863          	bltu	a4,a3,800048d2 <fileread+0xba>
    800048a6:	0792                	slli	a5,a5,0x4
    800048a8:	0001d717          	auipc	a4,0x1d
    800048ac:	a7070713          	addi	a4,a4,-1424 # 80021318 <devsw>
    800048b0:	97ba                	add	a5,a5,a4
    800048b2:	639c                	ld	a5,0(a5)
    800048b4:	c38d                	beqz	a5,800048d6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048b6:	4505                	li	a0,1
    800048b8:	9782                	jalr	a5
    800048ba:	892a                	mv	s2,a0
    800048bc:	bf75                	j	80004878 <fileread+0x60>
    panic("fileread");
    800048be:	00004517          	auipc	a0,0x4
    800048c2:	e3250513          	addi	a0,a0,-462 # 800086f0 <syscalls+0x268>
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	c78080e7          	jalr	-904(ra) # 8000053e <panic>
    return -1;
    800048ce:	597d                	li	s2,-1
    800048d0:	b765                	j	80004878 <fileread+0x60>
      return -1;
    800048d2:	597d                	li	s2,-1
    800048d4:	b755                	j	80004878 <fileread+0x60>
    800048d6:	597d                	li	s2,-1
    800048d8:	b745                	j	80004878 <fileread+0x60>

00000000800048da <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048da:	715d                	addi	sp,sp,-80
    800048dc:	e486                	sd	ra,72(sp)
    800048de:	e0a2                	sd	s0,64(sp)
    800048e0:	fc26                	sd	s1,56(sp)
    800048e2:	f84a                	sd	s2,48(sp)
    800048e4:	f44e                	sd	s3,40(sp)
    800048e6:	f052                	sd	s4,32(sp)
    800048e8:	ec56                	sd	s5,24(sp)
    800048ea:	e85a                	sd	s6,16(sp)
    800048ec:	e45e                	sd	s7,8(sp)
    800048ee:	e062                	sd	s8,0(sp)
    800048f0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048f2:	00954783          	lbu	a5,9(a0)
    800048f6:	10078663          	beqz	a5,80004a02 <filewrite+0x128>
    800048fa:	892a                	mv	s2,a0
    800048fc:	8aae                	mv	s5,a1
    800048fe:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004900:	411c                	lw	a5,0(a0)
    80004902:	4705                	li	a4,1
    80004904:	02e78263          	beq	a5,a4,80004928 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004908:	470d                	li	a4,3
    8000490a:	02e78663          	beq	a5,a4,80004936 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000490e:	4709                	li	a4,2
    80004910:	0ee79163          	bne	a5,a4,800049f2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004914:	0ac05d63          	blez	a2,800049ce <filewrite+0xf4>
    int i = 0;
    80004918:	4981                	li	s3,0
    8000491a:	6b05                	lui	s6,0x1
    8000491c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004920:	6b85                	lui	s7,0x1
    80004922:	c00b8b9b          	addiw	s7,s7,-1024
    80004926:	a861                	j	800049be <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004928:	6908                	ld	a0,16(a0)
    8000492a:	00000097          	auipc	ra,0x0
    8000492e:	22e080e7          	jalr	558(ra) # 80004b58 <pipewrite>
    80004932:	8a2a                	mv	s4,a0
    80004934:	a045                	j	800049d4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004936:	02451783          	lh	a5,36(a0)
    8000493a:	03079693          	slli	a3,a5,0x30
    8000493e:	92c1                	srli	a3,a3,0x30
    80004940:	4725                	li	a4,9
    80004942:	0cd76263          	bltu	a4,a3,80004a06 <filewrite+0x12c>
    80004946:	0792                	slli	a5,a5,0x4
    80004948:	0001d717          	auipc	a4,0x1d
    8000494c:	9d070713          	addi	a4,a4,-1584 # 80021318 <devsw>
    80004950:	97ba                	add	a5,a5,a4
    80004952:	679c                	ld	a5,8(a5)
    80004954:	cbdd                	beqz	a5,80004a0a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004956:	4505                	li	a0,1
    80004958:	9782                	jalr	a5
    8000495a:	8a2a                	mv	s4,a0
    8000495c:	a8a5                	j	800049d4 <filewrite+0xfa>
    8000495e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004962:	00000097          	auipc	ra,0x0
    80004966:	8b0080e7          	jalr	-1872(ra) # 80004212 <begin_op>
      ilock(f->ip);
    8000496a:	01893503          	ld	a0,24(s2)
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	ed2080e7          	jalr	-302(ra) # 80003840 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004976:	8762                	mv	a4,s8
    80004978:	02092683          	lw	a3,32(s2)
    8000497c:	01598633          	add	a2,s3,s5
    80004980:	4585                	li	a1,1
    80004982:	01893503          	ld	a0,24(s2)
    80004986:	fffff097          	auipc	ra,0xfffff
    8000498a:	266080e7          	jalr	614(ra) # 80003bec <writei>
    8000498e:	84aa                	mv	s1,a0
    80004990:	00a05763          	blez	a0,8000499e <filewrite+0xc4>
        f->off += r;
    80004994:	02092783          	lw	a5,32(s2)
    80004998:	9fa9                	addw	a5,a5,a0
    8000499a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000499e:	01893503          	ld	a0,24(s2)
    800049a2:	fffff097          	auipc	ra,0xfffff
    800049a6:	f60080e7          	jalr	-160(ra) # 80003902 <iunlock>
      end_op();
    800049aa:	00000097          	auipc	ra,0x0
    800049ae:	8e8080e7          	jalr	-1816(ra) # 80004292 <end_op>

      if(r != n1){
    800049b2:	009c1f63          	bne	s8,s1,800049d0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049b6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049ba:	0149db63          	bge	s3,s4,800049d0 <filewrite+0xf6>
      int n1 = n - i;
    800049be:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049c2:	84be                	mv	s1,a5
    800049c4:	2781                	sext.w	a5,a5
    800049c6:	f8fb5ce3          	bge	s6,a5,8000495e <filewrite+0x84>
    800049ca:	84de                	mv	s1,s7
    800049cc:	bf49                	j	8000495e <filewrite+0x84>
    int i = 0;
    800049ce:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049d0:	013a1f63          	bne	s4,s3,800049ee <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049d4:	8552                	mv	a0,s4
    800049d6:	60a6                	ld	ra,72(sp)
    800049d8:	6406                	ld	s0,64(sp)
    800049da:	74e2                	ld	s1,56(sp)
    800049dc:	7942                	ld	s2,48(sp)
    800049de:	79a2                	ld	s3,40(sp)
    800049e0:	7a02                	ld	s4,32(sp)
    800049e2:	6ae2                	ld	s5,24(sp)
    800049e4:	6b42                	ld	s6,16(sp)
    800049e6:	6ba2                	ld	s7,8(sp)
    800049e8:	6c02                	ld	s8,0(sp)
    800049ea:	6161                	addi	sp,sp,80
    800049ec:	8082                	ret
    ret = (i == n ? n : -1);
    800049ee:	5a7d                	li	s4,-1
    800049f0:	b7d5                	j	800049d4 <filewrite+0xfa>
    panic("filewrite");
    800049f2:	00004517          	auipc	a0,0x4
    800049f6:	d0e50513          	addi	a0,a0,-754 # 80008700 <syscalls+0x278>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	b44080e7          	jalr	-1212(ra) # 8000053e <panic>
    return -1;
    80004a02:	5a7d                	li	s4,-1
    80004a04:	bfc1                	j	800049d4 <filewrite+0xfa>
      return -1;
    80004a06:	5a7d                	li	s4,-1
    80004a08:	b7f1                	j	800049d4 <filewrite+0xfa>
    80004a0a:	5a7d                	li	s4,-1
    80004a0c:	b7e1                	j	800049d4 <filewrite+0xfa>

0000000080004a0e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a0e:	7179                	addi	sp,sp,-48
    80004a10:	f406                	sd	ra,40(sp)
    80004a12:	f022                	sd	s0,32(sp)
    80004a14:	ec26                	sd	s1,24(sp)
    80004a16:	e84a                	sd	s2,16(sp)
    80004a18:	e44e                	sd	s3,8(sp)
    80004a1a:	e052                	sd	s4,0(sp)
    80004a1c:	1800                	addi	s0,sp,48
    80004a1e:	84aa                	mv	s1,a0
    80004a20:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a22:	0005b023          	sd	zero,0(a1)
    80004a26:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a2a:	00000097          	auipc	ra,0x0
    80004a2e:	bf8080e7          	jalr	-1032(ra) # 80004622 <filealloc>
    80004a32:	e088                	sd	a0,0(s1)
    80004a34:	c551                	beqz	a0,80004ac0 <pipealloc+0xb2>
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	bec080e7          	jalr	-1044(ra) # 80004622 <filealloc>
    80004a3e:	00aa3023          	sd	a0,0(s4)
    80004a42:	c92d                	beqz	a0,80004ab4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	0b0080e7          	jalr	176(ra) # 80000af4 <kalloc>
    80004a4c:	892a                	mv	s2,a0
    80004a4e:	c125                	beqz	a0,80004aae <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a50:	4985                	li	s3,1
    80004a52:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a56:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a5a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a5e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a62:	00004597          	auipc	a1,0x4
    80004a66:	cae58593          	addi	a1,a1,-850 # 80008710 <syscalls+0x288>
    80004a6a:	ffffc097          	auipc	ra,0xffffc
    80004a6e:	0ea080e7          	jalr	234(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004a72:	609c                	ld	a5,0(s1)
    80004a74:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a78:	609c                	ld	a5,0(s1)
    80004a7a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a7e:	609c                	ld	a5,0(s1)
    80004a80:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a84:	609c                	ld	a5,0(s1)
    80004a86:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a8a:	000a3783          	ld	a5,0(s4)
    80004a8e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a92:	000a3783          	ld	a5,0(s4)
    80004a96:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a9a:	000a3783          	ld	a5,0(s4)
    80004a9e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004aa2:	000a3783          	ld	a5,0(s4)
    80004aa6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aaa:	4501                	li	a0,0
    80004aac:	a025                	j	80004ad4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004aae:	6088                	ld	a0,0(s1)
    80004ab0:	e501                	bnez	a0,80004ab8 <pipealloc+0xaa>
    80004ab2:	a039                	j	80004ac0 <pipealloc+0xb2>
    80004ab4:	6088                	ld	a0,0(s1)
    80004ab6:	c51d                	beqz	a0,80004ae4 <pipealloc+0xd6>
    fileclose(*f0);
    80004ab8:	00000097          	auipc	ra,0x0
    80004abc:	c26080e7          	jalr	-986(ra) # 800046de <fileclose>
  if(*f1)
    80004ac0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ac4:	557d                	li	a0,-1
  if(*f1)
    80004ac6:	c799                	beqz	a5,80004ad4 <pipealloc+0xc6>
    fileclose(*f1);
    80004ac8:	853e                	mv	a0,a5
    80004aca:	00000097          	auipc	ra,0x0
    80004ace:	c14080e7          	jalr	-1004(ra) # 800046de <fileclose>
  return -1;
    80004ad2:	557d                	li	a0,-1
}
    80004ad4:	70a2                	ld	ra,40(sp)
    80004ad6:	7402                	ld	s0,32(sp)
    80004ad8:	64e2                	ld	s1,24(sp)
    80004ada:	6942                	ld	s2,16(sp)
    80004adc:	69a2                	ld	s3,8(sp)
    80004ade:	6a02                	ld	s4,0(sp)
    80004ae0:	6145                	addi	sp,sp,48
    80004ae2:	8082                	ret
  return -1;
    80004ae4:	557d                	li	a0,-1
    80004ae6:	b7fd                	j	80004ad4 <pipealloc+0xc6>

0000000080004ae8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ae8:	1101                	addi	sp,sp,-32
    80004aea:	ec06                	sd	ra,24(sp)
    80004aec:	e822                	sd	s0,16(sp)
    80004aee:	e426                	sd	s1,8(sp)
    80004af0:	e04a                	sd	s2,0(sp)
    80004af2:	1000                	addi	s0,sp,32
    80004af4:	84aa                	mv	s1,a0
    80004af6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004af8:	ffffc097          	auipc	ra,0xffffc
    80004afc:	0ec080e7          	jalr	236(ra) # 80000be4 <acquire>
  if(writable){
    80004b00:	02090d63          	beqz	s2,80004b3a <pipeclose+0x52>
    pi->writeopen = 0;
    80004b04:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b08:	21848513          	addi	a0,s1,536
    80004b0c:	ffffe097          	auipc	ra,0xffffe
    80004b10:	8ca080e7          	jalr	-1846(ra) # 800023d6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b14:	2204b783          	ld	a5,544(s1)
    80004b18:	eb95                	bnez	a5,80004b4c <pipeclose+0x64>
    release(&pi->lock);
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	17c080e7          	jalr	380(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b24:	8526                	mv	a0,s1
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	ed2080e7          	jalr	-302(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b2e:	60e2                	ld	ra,24(sp)
    80004b30:	6442                	ld	s0,16(sp)
    80004b32:	64a2                	ld	s1,8(sp)
    80004b34:	6902                	ld	s2,0(sp)
    80004b36:	6105                	addi	sp,sp,32
    80004b38:	8082                	ret
    pi->readopen = 0;
    80004b3a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b3e:	21c48513          	addi	a0,s1,540
    80004b42:	ffffe097          	auipc	ra,0xffffe
    80004b46:	894080e7          	jalr	-1900(ra) # 800023d6 <wakeup>
    80004b4a:	b7e9                	j	80004b14 <pipeclose+0x2c>
    release(&pi->lock);
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	14a080e7          	jalr	330(ra) # 80000c98 <release>
}
    80004b56:	bfe1                	j	80004b2e <pipeclose+0x46>

0000000080004b58 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b58:	7159                	addi	sp,sp,-112
    80004b5a:	f486                	sd	ra,104(sp)
    80004b5c:	f0a2                	sd	s0,96(sp)
    80004b5e:	eca6                	sd	s1,88(sp)
    80004b60:	e8ca                	sd	s2,80(sp)
    80004b62:	e4ce                	sd	s3,72(sp)
    80004b64:	e0d2                	sd	s4,64(sp)
    80004b66:	fc56                	sd	s5,56(sp)
    80004b68:	f85a                	sd	s6,48(sp)
    80004b6a:	f45e                	sd	s7,40(sp)
    80004b6c:	f062                	sd	s8,32(sp)
    80004b6e:	ec66                	sd	s9,24(sp)
    80004b70:	1880                	addi	s0,sp,112
    80004b72:	84aa                	mv	s1,a0
    80004b74:	8aae                	mv	s5,a1
    80004b76:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b78:	ffffd097          	auipc	ra,0xffffd
    80004b7c:	f5c080e7          	jalr	-164(ra) # 80001ad4 <myproc>
    80004b80:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b82:	8526                	mv	a0,s1
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	060080e7          	jalr	96(ra) # 80000be4 <acquire>
  while(i < n){
    80004b8c:	0d405163          	blez	s4,80004c4e <pipewrite+0xf6>
    80004b90:	8ba6                	mv	s7,s1
  int i = 0;
    80004b92:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b94:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b96:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b9a:	21c48c13          	addi	s8,s1,540
    80004b9e:	a08d                	j	80004c00 <pipewrite+0xa8>
      release(&pi->lock);
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	0f6080e7          	jalr	246(ra) # 80000c98 <release>
      return -1;
    80004baa:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bac:	854a                	mv	a0,s2
    80004bae:	70a6                	ld	ra,104(sp)
    80004bb0:	7406                	ld	s0,96(sp)
    80004bb2:	64e6                	ld	s1,88(sp)
    80004bb4:	6946                	ld	s2,80(sp)
    80004bb6:	69a6                	ld	s3,72(sp)
    80004bb8:	6a06                	ld	s4,64(sp)
    80004bba:	7ae2                	ld	s5,56(sp)
    80004bbc:	7b42                	ld	s6,48(sp)
    80004bbe:	7ba2                	ld	s7,40(sp)
    80004bc0:	7c02                	ld	s8,32(sp)
    80004bc2:	6ce2                	ld	s9,24(sp)
    80004bc4:	6165                	addi	sp,sp,112
    80004bc6:	8082                	ret
      wakeup(&pi->nread);
    80004bc8:	8566                	mv	a0,s9
    80004bca:	ffffe097          	auipc	ra,0xffffe
    80004bce:	80c080e7          	jalr	-2036(ra) # 800023d6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bd2:	85de                	mv	a1,s7
    80004bd4:	8562                	mv	a0,s8
    80004bd6:	ffffd097          	auipc	ra,0xffffd
    80004bda:	674080e7          	jalr	1652(ra) # 8000224a <sleep>
    80004bde:	a839                	j	80004bfc <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004be0:	21c4a783          	lw	a5,540(s1)
    80004be4:	0017871b          	addiw	a4,a5,1
    80004be8:	20e4ae23          	sw	a4,540(s1)
    80004bec:	1ff7f793          	andi	a5,a5,511
    80004bf0:	97a6                	add	a5,a5,s1
    80004bf2:	f9f44703          	lbu	a4,-97(s0)
    80004bf6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bfa:	2905                	addiw	s2,s2,1
  while(i < n){
    80004bfc:	03495d63          	bge	s2,s4,80004c36 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c00:	2204a783          	lw	a5,544(s1)
    80004c04:	dfd1                	beqz	a5,80004ba0 <pipewrite+0x48>
    80004c06:	0289a783          	lw	a5,40(s3)
    80004c0a:	fbd9                	bnez	a5,80004ba0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c0c:	2184a783          	lw	a5,536(s1)
    80004c10:	21c4a703          	lw	a4,540(s1)
    80004c14:	2007879b          	addiw	a5,a5,512
    80004c18:	faf708e3          	beq	a4,a5,80004bc8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c1c:	4685                	li	a3,1
    80004c1e:	01590633          	add	a2,s2,s5
    80004c22:	f9f40593          	addi	a1,s0,-97
    80004c26:	0509b503          	ld	a0,80(s3)
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	bf8080e7          	jalr	-1032(ra) # 80001822 <copyin>
    80004c32:	fb6517e3          	bne	a0,s6,80004be0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c36:	21848513          	addi	a0,s1,536
    80004c3a:	ffffd097          	auipc	ra,0xffffd
    80004c3e:	79c080e7          	jalr	1948(ra) # 800023d6 <wakeup>
  release(&pi->lock);
    80004c42:	8526                	mv	a0,s1
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	054080e7          	jalr	84(ra) # 80000c98 <release>
  return i;
    80004c4c:	b785                	j	80004bac <pipewrite+0x54>
  int i = 0;
    80004c4e:	4901                	li	s2,0
    80004c50:	b7dd                	j	80004c36 <pipewrite+0xde>

0000000080004c52 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c52:	715d                	addi	sp,sp,-80
    80004c54:	e486                	sd	ra,72(sp)
    80004c56:	e0a2                	sd	s0,64(sp)
    80004c58:	fc26                	sd	s1,56(sp)
    80004c5a:	f84a                	sd	s2,48(sp)
    80004c5c:	f44e                	sd	s3,40(sp)
    80004c5e:	f052                	sd	s4,32(sp)
    80004c60:	ec56                	sd	s5,24(sp)
    80004c62:	e85a                	sd	s6,16(sp)
    80004c64:	0880                	addi	s0,sp,80
    80004c66:	84aa                	mv	s1,a0
    80004c68:	892e                	mv	s2,a1
    80004c6a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	e68080e7          	jalr	-408(ra) # 80001ad4 <myproc>
    80004c74:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c76:	8b26                	mv	s6,s1
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	f6a080e7          	jalr	-150(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c82:	2184a703          	lw	a4,536(s1)
    80004c86:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c8a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c8e:	02f71463          	bne	a4,a5,80004cb6 <piperead+0x64>
    80004c92:	2244a783          	lw	a5,548(s1)
    80004c96:	c385                	beqz	a5,80004cb6 <piperead+0x64>
    if(pr->killed){
    80004c98:	028a2783          	lw	a5,40(s4)
    80004c9c:	ebc1                	bnez	a5,80004d2c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c9e:	85da                	mv	a1,s6
    80004ca0:	854e                	mv	a0,s3
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	5a8080e7          	jalr	1448(ra) # 8000224a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004caa:	2184a703          	lw	a4,536(s1)
    80004cae:	21c4a783          	lw	a5,540(s1)
    80004cb2:	fef700e3          	beq	a4,a5,80004c92 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb6:	09505263          	blez	s5,80004d3a <piperead+0xe8>
    80004cba:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cbc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004cbe:	2184a783          	lw	a5,536(s1)
    80004cc2:	21c4a703          	lw	a4,540(s1)
    80004cc6:	02f70d63          	beq	a4,a5,80004d00 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cca:	0017871b          	addiw	a4,a5,1
    80004cce:	20e4ac23          	sw	a4,536(s1)
    80004cd2:	1ff7f793          	andi	a5,a5,511
    80004cd6:	97a6                	add	a5,a5,s1
    80004cd8:	0187c783          	lbu	a5,24(a5)
    80004cdc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ce0:	4685                	li	a3,1
    80004ce2:	fbf40613          	addi	a2,s0,-65
    80004ce6:	85ca                	mv	a1,s2
    80004ce8:	050a3503          	ld	a0,80(s4)
    80004cec:	ffffd097          	auipc	ra,0xffffd
    80004cf0:	aaa080e7          	jalr	-1366(ra) # 80001796 <copyout>
    80004cf4:	01650663          	beq	a0,s6,80004d00 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cf8:	2985                	addiw	s3,s3,1
    80004cfa:	0905                	addi	s2,s2,1
    80004cfc:	fd3a91e3          	bne	s5,s3,80004cbe <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d00:	21c48513          	addi	a0,s1,540
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	6d2080e7          	jalr	1746(ra) # 800023d6 <wakeup>
  release(&pi->lock);
    80004d0c:	8526                	mv	a0,s1
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	f8a080e7          	jalr	-118(ra) # 80000c98 <release>
  return i;
}
    80004d16:	854e                	mv	a0,s3
    80004d18:	60a6                	ld	ra,72(sp)
    80004d1a:	6406                	ld	s0,64(sp)
    80004d1c:	74e2                	ld	s1,56(sp)
    80004d1e:	7942                	ld	s2,48(sp)
    80004d20:	79a2                	ld	s3,40(sp)
    80004d22:	7a02                	ld	s4,32(sp)
    80004d24:	6ae2                	ld	s5,24(sp)
    80004d26:	6b42                	ld	s6,16(sp)
    80004d28:	6161                	addi	sp,sp,80
    80004d2a:	8082                	ret
      release(&pi->lock);
    80004d2c:	8526                	mv	a0,s1
    80004d2e:	ffffc097          	auipc	ra,0xffffc
    80004d32:	f6a080e7          	jalr	-150(ra) # 80000c98 <release>
      return -1;
    80004d36:	59fd                	li	s3,-1
    80004d38:	bff9                	j	80004d16 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d3a:	4981                	li	s3,0
    80004d3c:	b7d1                	j	80004d00 <piperead+0xae>

0000000080004d3e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d3e:	df010113          	addi	sp,sp,-528
    80004d42:	20113423          	sd	ra,520(sp)
    80004d46:	20813023          	sd	s0,512(sp)
    80004d4a:	ffa6                	sd	s1,504(sp)
    80004d4c:	fbca                	sd	s2,496(sp)
    80004d4e:	f7ce                	sd	s3,488(sp)
    80004d50:	f3d2                	sd	s4,480(sp)
    80004d52:	efd6                	sd	s5,472(sp)
    80004d54:	ebda                	sd	s6,464(sp)
    80004d56:	e7de                	sd	s7,456(sp)
    80004d58:	e3e2                	sd	s8,448(sp)
    80004d5a:	ff66                	sd	s9,440(sp)
    80004d5c:	fb6a                	sd	s10,432(sp)
    80004d5e:	f76e                	sd	s11,424(sp)
    80004d60:	0c00                	addi	s0,sp,528
    80004d62:	84aa                	mv	s1,a0
    80004d64:	dea43c23          	sd	a0,-520(s0)
    80004d68:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d6c:	ffffd097          	auipc	ra,0xffffd
    80004d70:	d68080e7          	jalr	-664(ra) # 80001ad4 <myproc>
    80004d74:	892a                	mv	s2,a0

  begin_op();
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	49c080e7          	jalr	1180(ra) # 80004212 <begin_op>

  if((ip = namei(path)) == 0){
    80004d7e:	8526                	mv	a0,s1
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	276080e7          	jalr	630(ra) # 80003ff6 <namei>
    80004d88:	c92d                	beqz	a0,80004dfa <exec+0xbc>
    80004d8a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	ab4080e7          	jalr	-1356(ra) # 80003840 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d94:	04000713          	li	a4,64
    80004d98:	4681                	li	a3,0
    80004d9a:	e5040613          	addi	a2,s0,-432
    80004d9e:	4581                	li	a1,0
    80004da0:	8526                	mv	a0,s1
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	d52080e7          	jalr	-686(ra) # 80003af4 <readi>
    80004daa:	04000793          	li	a5,64
    80004dae:	00f51a63          	bne	a0,a5,80004dc2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004db2:	e5042703          	lw	a4,-432(s0)
    80004db6:	464c47b7          	lui	a5,0x464c4
    80004dba:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dbe:	04f70463          	beq	a4,a5,80004e06 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dc2:	8526                	mv	a0,s1
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	cde080e7          	jalr	-802(ra) # 80003aa2 <iunlockput>
    end_op();
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	4c6080e7          	jalr	1222(ra) # 80004292 <end_op>
  }
  return -1;
    80004dd4:	557d                	li	a0,-1
}
    80004dd6:	20813083          	ld	ra,520(sp)
    80004dda:	20013403          	ld	s0,512(sp)
    80004dde:	74fe                	ld	s1,504(sp)
    80004de0:	795e                	ld	s2,496(sp)
    80004de2:	79be                	ld	s3,488(sp)
    80004de4:	7a1e                	ld	s4,480(sp)
    80004de6:	6afe                	ld	s5,472(sp)
    80004de8:	6b5e                	ld	s6,464(sp)
    80004dea:	6bbe                	ld	s7,456(sp)
    80004dec:	6c1e                	ld	s8,448(sp)
    80004dee:	7cfa                	ld	s9,440(sp)
    80004df0:	7d5a                	ld	s10,432(sp)
    80004df2:	7dba                	ld	s11,424(sp)
    80004df4:	21010113          	addi	sp,sp,528
    80004df8:	8082                	ret
    end_op();
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	498080e7          	jalr	1176(ra) # 80004292 <end_op>
    return -1;
    80004e02:	557d                	li	a0,-1
    80004e04:	bfc9                	j	80004dd6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e06:	854a                	mv	a0,s2
    80004e08:	ffffd097          	auipc	ra,0xffffd
    80004e0c:	d90080e7          	jalr	-624(ra) # 80001b98 <proc_pagetable>
    80004e10:	8baa                	mv	s7,a0
    80004e12:	d945                	beqz	a0,80004dc2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e14:	e7042983          	lw	s3,-400(s0)
    80004e18:	e8845783          	lhu	a5,-376(s0)
    80004e1c:	c7ad                	beqz	a5,80004e86 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e1e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e20:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e22:	6c85                	lui	s9,0x1
    80004e24:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e28:	def43823          	sd	a5,-528(s0)
    80004e2c:	a42d                	j	80005056 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e2e:	00004517          	auipc	a0,0x4
    80004e32:	8ea50513          	addi	a0,a0,-1814 # 80008718 <syscalls+0x290>
    80004e36:	ffffb097          	auipc	ra,0xffffb
    80004e3a:	708080e7          	jalr	1800(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e3e:	8756                	mv	a4,s5
    80004e40:	012d86bb          	addw	a3,s11,s2
    80004e44:	4581                	li	a1,0
    80004e46:	8526                	mv	a0,s1
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	cac080e7          	jalr	-852(ra) # 80003af4 <readi>
    80004e50:	2501                	sext.w	a0,a0
    80004e52:	1aaa9963          	bne	s5,a0,80005004 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e56:	6785                	lui	a5,0x1
    80004e58:	0127893b          	addw	s2,a5,s2
    80004e5c:	77fd                	lui	a5,0xfffff
    80004e5e:	01478a3b          	addw	s4,a5,s4
    80004e62:	1f897163          	bgeu	s2,s8,80005044 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e66:	02091593          	slli	a1,s2,0x20
    80004e6a:	9181                	srli	a1,a1,0x20
    80004e6c:	95ea                	add	a1,a1,s10
    80004e6e:	855e                	mv	a0,s7
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	322080e7          	jalr	802(ra) # 80001192 <walkaddr>
    80004e78:	862a                	mv	a2,a0
    if(pa == 0)
    80004e7a:	d955                	beqz	a0,80004e2e <exec+0xf0>
      n = PGSIZE;
    80004e7c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e7e:	fd9a70e3          	bgeu	s4,s9,80004e3e <exec+0x100>
      n = sz - i;
    80004e82:	8ad2                	mv	s5,s4
    80004e84:	bf6d                	j	80004e3e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e86:	4901                	li	s2,0
  iunlockput(ip);
    80004e88:	8526                	mv	a0,s1
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	c18080e7          	jalr	-1000(ra) # 80003aa2 <iunlockput>
  end_op();
    80004e92:	fffff097          	auipc	ra,0xfffff
    80004e96:	400080e7          	jalr	1024(ra) # 80004292 <end_op>
  p = myproc();
    80004e9a:	ffffd097          	auipc	ra,0xffffd
    80004e9e:	c3a080e7          	jalr	-966(ra) # 80001ad4 <myproc>
    80004ea2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ea4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ea8:	6785                	lui	a5,0x1
    80004eaa:	17fd                	addi	a5,a5,-1
    80004eac:	993e                	add	s2,s2,a5
    80004eae:	757d                	lui	a0,0xfffff
    80004eb0:	00a977b3          	and	a5,s2,a0
    80004eb4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eb8:	6609                	lui	a2,0x2
    80004eba:	963e                	add	a2,a2,a5
    80004ebc:	85be                	mv	a1,a5
    80004ebe:	855e                	mv	a0,s7
    80004ec0:	ffffc097          	auipc	ra,0xffffc
    80004ec4:	686080e7          	jalr	1670(ra) # 80001546 <uvmalloc>
    80004ec8:	8b2a                	mv	s6,a0
  ip = 0;
    80004eca:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ecc:	12050c63          	beqz	a0,80005004 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ed0:	75f9                	lui	a1,0xffffe
    80004ed2:	95aa                	add	a1,a1,a0
    80004ed4:	855e                	mv	a0,s7
    80004ed6:	ffffd097          	auipc	ra,0xffffd
    80004eda:	88e080e7          	jalr	-1906(ra) # 80001764 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ede:	7c7d                	lui	s8,0xfffff
    80004ee0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ee2:	e0043783          	ld	a5,-512(s0)
    80004ee6:	6388                	ld	a0,0(a5)
    80004ee8:	c535                	beqz	a0,80004f54 <exec+0x216>
    80004eea:	e9040993          	addi	s3,s0,-368
    80004eee:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004ef2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	f70080e7          	jalr	-144(ra) # 80000e64 <strlen>
    80004efc:	2505                	addiw	a0,a0,1
    80004efe:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f02:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f06:	13896363          	bltu	s2,s8,8000502c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f0a:	e0043d83          	ld	s11,-512(s0)
    80004f0e:	000dba03          	ld	s4,0(s11)
    80004f12:	8552                	mv	a0,s4
    80004f14:	ffffc097          	auipc	ra,0xffffc
    80004f18:	f50080e7          	jalr	-176(ra) # 80000e64 <strlen>
    80004f1c:	0015069b          	addiw	a3,a0,1
    80004f20:	8652                	mv	a2,s4
    80004f22:	85ca                	mv	a1,s2
    80004f24:	855e                	mv	a0,s7
    80004f26:	ffffd097          	auipc	ra,0xffffd
    80004f2a:	870080e7          	jalr	-1936(ra) # 80001796 <copyout>
    80004f2e:	10054363          	bltz	a0,80005034 <exec+0x2f6>
    ustack[argc] = sp;
    80004f32:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f36:	0485                	addi	s1,s1,1
    80004f38:	008d8793          	addi	a5,s11,8
    80004f3c:	e0f43023          	sd	a5,-512(s0)
    80004f40:	008db503          	ld	a0,8(s11)
    80004f44:	c911                	beqz	a0,80004f58 <exec+0x21a>
    if(argc >= MAXARG)
    80004f46:	09a1                	addi	s3,s3,8
    80004f48:	fb3c96e3          	bne	s9,s3,80004ef4 <exec+0x1b6>
  sz = sz1;
    80004f4c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f50:	4481                	li	s1,0
    80004f52:	a84d                	j	80005004 <exec+0x2c6>
  sp = sz;
    80004f54:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f56:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f58:	00349793          	slli	a5,s1,0x3
    80004f5c:	f9040713          	addi	a4,s0,-112
    80004f60:	97ba                	add	a5,a5,a4
    80004f62:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f66:	00148693          	addi	a3,s1,1
    80004f6a:	068e                	slli	a3,a3,0x3
    80004f6c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f70:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f74:	01897663          	bgeu	s2,s8,80004f80 <exec+0x242>
  sz = sz1;
    80004f78:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f7c:	4481                	li	s1,0
    80004f7e:	a059                	j	80005004 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f80:	e9040613          	addi	a2,s0,-368
    80004f84:	85ca                	mv	a1,s2
    80004f86:	855e                	mv	a0,s7
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	80e080e7          	jalr	-2034(ra) # 80001796 <copyout>
    80004f90:	0a054663          	bltz	a0,8000503c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f94:	058ab783          	ld	a5,88(s5)
    80004f98:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f9c:	df843783          	ld	a5,-520(s0)
    80004fa0:	0007c703          	lbu	a4,0(a5)
    80004fa4:	cf11                	beqz	a4,80004fc0 <exec+0x282>
    80004fa6:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fa8:	02f00693          	li	a3,47
    80004fac:	a039                	j	80004fba <exec+0x27c>
      last = s+1;
    80004fae:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fb2:	0785                	addi	a5,a5,1
    80004fb4:	fff7c703          	lbu	a4,-1(a5)
    80004fb8:	c701                	beqz	a4,80004fc0 <exec+0x282>
    if(*s == '/')
    80004fba:	fed71ce3          	bne	a4,a3,80004fb2 <exec+0x274>
    80004fbe:	bfc5                	j	80004fae <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fc0:	4641                	li	a2,16
    80004fc2:	df843583          	ld	a1,-520(s0)
    80004fc6:	158a8513          	addi	a0,s5,344
    80004fca:	ffffc097          	auipc	ra,0xffffc
    80004fce:	e68080e7          	jalr	-408(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fd2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fd6:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fda:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fde:	058ab783          	ld	a5,88(s5)
    80004fe2:	e6843703          	ld	a4,-408(s0)
    80004fe6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fe8:	058ab783          	ld	a5,88(s5)
    80004fec:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ff0:	85ea                	mv	a1,s10
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	c42080e7          	jalr	-958(ra) # 80001c34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ffa:	0004851b          	sext.w	a0,s1
    80004ffe:	bbe1                	j	80004dd6 <exec+0x98>
    80005000:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005004:	e0843583          	ld	a1,-504(s0)
    80005008:	855e                	mv	a0,s7
    8000500a:	ffffd097          	auipc	ra,0xffffd
    8000500e:	c2a080e7          	jalr	-982(ra) # 80001c34 <proc_freepagetable>
  if(ip){
    80005012:	da0498e3          	bnez	s1,80004dc2 <exec+0x84>
  return -1;
    80005016:	557d                	li	a0,-1
    80005018:	bb7d                	j	80004dd6 <exec+0x98>
    8000501a:	e1243423          	sd	s2,-504(s0)
    8000501e:	b7dd                	j	80005004 <exec+0x2c6>
    80005020:	e1243423          	sd	s2,-504(s0)
    80005024:	b7c5                	j	80005004 <exec+0x2c6>
    80005026:	e1243423          	sd	s2,-504(s0)
    8000502a:	bfe9                	j	80005004 <exec+0x2c6>
  sz = sz1;
    8000502c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005030:	4481                	li	s1,0
    80005032:	bfc9                	j	80005004 <exec+0x2c6>
  sz = sz1;
    80005034:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005038:	4481                	li	s1,0
    8000503a:	b7e9                	j	80005004 <exec+0x2c6>
  sz = sz1;
    8000503c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005040:	4481                	li	s1,0
    80005042:	b7c9                	j	80005004 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005044:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005048:	2b05                	addiw	s6,s6,1
    8000504a:	0389899b          	addiw	s3,s3,56
    8000504e:	e8845783          	lhu	a5,-376(s0)
    80005052:	e2fb5be3          	bge	s6,a5,80004e88 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005056:	2981                	sext.w	s3,s3
    80005058:	03800713          	li	a4,56
    8000505c:	86ce                	mv	a3,s3
    8000505e:	e1840613          	addi	a2,s0,-488
    80005062:	4581                	li	a1,0
    80005064:	8526                	mv	a0,s1
    80005066:	fffff097          	auipc	ra,0xfffff
    8000506a:	a8e080e7          	jalr	-1394(ra) # 80003af4 <readi>
    8000506e:	03800793          	li	a5,56
    80005072:	f8f517e3          	bne	a0,a5,80005000 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005076:	e1842783          	lw	a5,-488(s0)
    8000507a:	4705                	li	a4,1
    8000507c:	fce796e3          	bne	a5,a4,80005048 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005080:	e4043603          	ld	a2,-448(s0)
    80005084:	e3843783          	ld	a5,-456(s0)
    80005088:	f8f669e3          	bltu	a2,a5,8000501a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000508c:	e2843783          	ld	a5,-472(s0)
    80005090:	963e                	add	a2,a2,a5
    80005092:	f8f667e3          	bltu	a2,a5,80005020 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005096:	85ca                	mv	a1,s2
    80005098:	855e                	mv	a0,s7
    8000509a:	ffffc097          	auipc	ra,0xffffc
    8000509e:	4ac080e7          	jalr	1196(ra) # 80001546 <uvmalloc>
    800050a2:	e0a43423          	sd	a0,-504(s0)
    800050a6:	d141                	beqz	a0,80005026 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050a8:	e2843d03          	ld	s10,-472(s0)
    800050ac:	df043783          	ld	a5,-528(s0)
    800050b0:	00fd77b3          	and	a5,s10,a5
    800050b4:	fba1                	bnez	a5,80005004 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050b6:	e2042d83          	lw	s11,-480(s0)
    800050ba:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050be:	f80c03e3          	beqz	s8,80005044 <exec+0x306>
    800050c2:	8a62                	mv	s4,s8
    800050c4:	4901                	li	s2,0
    800050c6:	b345                	j	80004e66 <exec+0x128>

00000000800050c8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050c8:	7179                	addi	sp,sp,-48
    800050ca:	f406                	sd	ra,40(sp)
    800050cc:	f022                	sd	s0,32(sp)
    800050ce:	ec26                	sd	s1,24(sp)
    800050d0:	e84a                	sd	s2,16(sp)
    800050d2:	1800                	addi	s0,sp,48
    800050d4:	892e                	mv	s2,a1
    800050d6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050d8:	fdc40593          	addi	a1,s0,-36
    800050dc:	ffffe097          	auipc	ra,0xffffe
    800050e0:	ba8080e7          	jalr	-1112(ra) # 80002c84 <argint>
    800050e4:	04054063          	bltz	a0,80005124 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050e8:	fdc42703          	lw	a4,-36(s0)
    800050ec:	47bd                	li	a5,15
    800050ee:	02e7ed63          	bltu	a5,a4,80005128 <argfd+0x60>
    800050f2:	ffffd097          	auipc	ra,0xffffd
    800050f6:	9e2080e7          	jalr	-1566(ra) # 80001ad4 <myproc>
    800050fa:	fdc42703          	lw	a4,-36(s0)
    800050fe:	01a70793          	addi	a5,a4,26
    80005102:	078e                	slli	a5,a5,0x3
    80005104:	953e                	add	a0,a0,a5
    80005106:	611c                	ld	a5,0(a0)
    80005108:	c395                	beqz	a5,8000512c <argfd+0x64>
    return -1;
  if(pfd)
    8000510a:	00090463          	beqz	s2,80005112 <argfd+0x4a>
    *pfd = fd;
    8000510e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005112:	4501                	li	a0,0
  if(pf)
    80005114:	c091                	beqz	s1,80005118 <argfd+0x50>
    *pf = f;
    80005116:	e09c                	sd	a5,0(s1)
}
    80005118:	70a2                	ld	ra,40(sp)
    8000511a:	7402                	ld	s0,32(sp)
    8000511c:	64e2                	ld	s1,24(sp)
    8000511e:	6942                	ld	s2,16(sp)
    80005120:	6145                	addi	sp,sp,48
    80005122:	8082                	ret
    return -1;
    80005124:	557d                	li	a0,-1
    80005126:	bfcd                	j	80005118 <argfd+0x50>
    return -1;
    80005128:	557d                	li	a0,-1
    8000512a:	b7fd                	j	80005118 <argfd+0x50>
    8000512c:	557d                	li	a0,-1
    8000512e:	b7ed                	j	80005118 <argfd+0x50>

0000000080005130 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005130:	1101                	addi	sp,sp,-32
    80005132:	ec06                	sd	ra,24(sp)
    80005134:	e822                	sd	s0,16(sp)
    80005136:	e426                	sd	s1,8(sp)
    80005138:	1000                	addi	s0,sp,32
    8000513a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000513c:	ffffd097          	auipc	ra,0xffffd
    80005140:	998080e7          	jalr	-1640(ra) # 80001ad4 <myproc>
    80005144:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005146:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000514a:	4501                	li	a0,0
    8000514c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000514e:	6398                	ld	a4,0(a5)
    80005150:	cb19                	beqz	a4,80005166 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005152:	2505                	addiw	a0,a0,1
    80005154:	07a1                	addi	a5,a5,8
    80005156:	fed51ce3          	bne	a0,a3,8000514e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000515a:	557d                	li	a0,-1
}
    8000515c:	60e2                	ld	ra,24(sp)
    8000515e:	6442                	ld	s0,16(sp)
    80005160:	64a2                	ld	s1,8(sp)
    80005162:	6105                	addi	sp,sp,32
    80005164:	8082                	ret
      p->ofile[fd] = f;
    80005166:	01a50793          	addi	a5,a0,26
    8000516a:	078e                	slli	a5,a5,0x3
    8000516c:	963e                	add	a2,a2,a5
    8000516e:	e204                	sd	s1,0(a2)
      return fd;
    80005170:	b7f5                	j	8000515c <fdalloc+0x2c>

0000000080005172 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005172:	715d                	addi	sp,sp,-80
    80005174:	e486                	sd	ra,72(sp)
    80005176:	e0a2                	sd	s0,64(sp)
    80005178:	fc26                	sd	s1,56(sp)
    8000517a:	f84a                	sd	s2,48(sp)
    8000517c:	f44e                	sd	s3,40(sp)
    8000517e:	f052                	sd	s4,32(sp)
    80005180:	ec56                	sd	s5,24(sp)
    80005182:	0880                	addi	s0,sp,80
    80005184:	89ae                	mv	s3,a1
    80005186:	8ab2                	mv	s5,a2
    80005188:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000518a:	fb040593          	addi	a1,s0,-80
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	e86080e7          	jalr	-378(ra) # 80004014 <nameiparent>
    80005196:	892a                	mv	s2,a0
    80005198:	12050f63          	beqz	a0,800052d6 <create+0x164>
    return 0;

  ilock(dp);
    8000519c:	ffffe097          	auipc	ra,0xffffe
    800051a0:	6a4080e7          	jalr	1700(ra) # 80003840 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051a4:	4601                	li	a2,0
    800051a6:	fb040593          	addi	a1,s0,-80
    800051aa:	854a                	mv	a0,s2
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	b78080e7          	jalr	-1160(ra) # 80003d24 <dirlookup>
    800051b4:	84aa                	mv	s1,a0
    800051b6:	c921                	beqz	a0,80005206 <create+0x94>
    iunlockput(dp);
    800051b8:	854a                	mv	a0,s2
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	8e8080e7          	jalr	-1816(ra) # 80003aa2 <iunlockput>
    ilock(ip);
    800051c2:	8526                	mv	a0,s1
    800051c4:	ffffe097          	auipc	ra,0xffffe
    800051c8:	67c080e7          	jalr	1660(ra) # 80003840 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051cc:	2981                	sext.w	s3,s3
    800051ce:	4789                	li	a5,2
    800051d0:	02f99463          	bne	s3,a5,800051f8 <create+0x86>
    800051d4:	0444d783          	lhu	a5,68(s1)
    800051d8:	37f9                	addiw	a5,a5,-2
    800051da:	17c2                	slli	a5,a5,0x30
    800051dc:	93c1                	srli	a5,a5,0x30
    800051de:	4705                	li	a4,1
    800051e0:	00f76c63          	bltu	a4,a5,800051f8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051e4:	8526                	mv	a0,s1
    800051e6:	60a6                	ld	ra,72(sp)
    800051e8:	6406                	ld	s0,64(sp)
    800051ea:	74e2                	ld	s1,56(sp)
    800051ec:	7942                	ld	s2,48(sp)
    800051ee:	79a2                	ld	s3,40(sp)
    800051f0:	7a02                	ld	s4,32(sp)
    800051f2:	6ae2                	ld	s5,24(sp)
    800051f4:	6161                	addi	sp,sp,80
    800051f6:	8082                	ret
    iunlockput(ip);
    800051f8:	8526                	mv	a0,s1
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	8a8080e7          	jalr	-1880(ra) # 80003aa2 <iunlockput>
    return 0;
    80005202:	4481                	li	s1,0
    80005204:	b7c5                	j	800051e4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005206:	85ce                	mv	a1,s3
    80005208:	00092503          	lw	a0,0(s2)
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	49c080e7          	jalr	1180(ra) # 800036a8 <ialloc>
    80005214:	84aa                	mv	s1,a0
    80005216:	c529                	beqz	a0,80005260 <create+0xee>
  ilock(ip);
    80005218:	ffffe097          	auipc	ra,0xffffe
    8000521c:	628080e7          	jalr	1576(ra) # 80003840 <ilock>
  ip->major = major;
    80005220:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005224:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005228:	4785                	li	a5,1
    8000522a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000522e:	8526                	mv	a0,s1
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	546080e7          	jalr	1350(ra) # 80003776 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005238:	2981                	sext.w	s3,s3
    8000523a:	4785                	li	a5,1
    8000523c:	02f98a63          	beq	s3,a5,80005270 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005240:	40d0                	lw	a2,4(s1)
    80005242:	fb040593          	addi	a1,s0,-80
    80005246:	854a                	mv	a0,s2
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	cec080e7          	jalr	-788(ra) # 80003f34 <dirlink>
    80005250:	06054b63          	bltz	a0,800052c6 <create+0x154>
  iunlockput(dp);
    80005254:	854a                	mv	a0,s2
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	84c080e7          	jalr	-1972(ra) # 80003aa2 <iunlockput>
  return ip;
    8000525e:	b759                	j	800051e4 <create+0x72>
    panic("create: ialloc");
    80005260:	00003517          	auipc	a0,0x3
    80005264:	4d850513          	addi	a0,a0,1240 # 80008738 <syscalls+0x2b0>
    80005268:	ffffb097          	auipc	ra,0xffffb
    8000526c:	2d6080e7          	jalr	726(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005270:	04a95783          	lhu	a5,74(s2)
    80005274:	2785                	addiw	a5,a5,1
    80005276:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000527a:	854a                	mv	a0,s2
    8000527c:	ffffe097          	auipc	ra,0xffffe
    80005280:	4fa080e7          	jalr	1274(ra) # 80003776 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005284:	40d0                	lw	a2,4(s1)
    80005286:	00003597          	auipc	a1,0x3
    8000528a:	4c258593          	addi	a1,a1,1218 # 80008748 <syscalls+0x2c0>
    8000528e:	8526                	mv	a0,s1
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	ca4080e7          	jalr	-860(ra) # 80003f34 <dirlink>
    80005298:	00054f63          	bltz	a0,800052b6 <create+0x144>
    8000529c:	00492603          	lw	a2,4(s2)
    800052a0:	00003597          	auipc	a1,0x3
    800052a4:	4b058593          	addi	a1,a1,1200 # 80008750 <syscalls+0x2c8>
    800052a8:	8526                	mv	a0,s1
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	c8a080e7          	jalr	-886(ra) # 80003f34 <dirlink>
    800052b2:	f80557e3          	bgez	a0,80005240 <create+0xce>
      panic("create dots");
    800052b6:	00003517          	auipc	a0,0x3
    800052ba:	4a250513          	addi	a0,a0,1186 # 80008758 <syscalls+0x2d0>
    800052be:	ffffb097          	auipc	ra,0xffffb
    800052c2:	280080e7          	jalr	640(ra) # 8000053e <panic>
    panic("create: dirlink");
    800052c6:	00003517          	auipc	a0,0x3
    800052ca:	4a250513          	addi	a0,a0,1186 # 80008768 <syscalls+0x2e0>
    800052ce:	ffffb097          	auipc	ra,0xffffb
    800052d2:	270080e7          	jalr	624(ra) # 8000053e <panic>
    return 0;
    800052d6:	84aa                	mv	s1,a0
    800052d8:	b731                	j	800051e4 <create+0x72>

00000000800052da <sys_dup>:
{
    800052da:	7179                	addi	sp,sp,-48
    800052dc:	f406                	sd	ra,40(sp)
    800052de:	f022                	sd	s0,32(sp)
    800052e0:	ec26                	sd	s1,24(sp)
    800052e2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052e4:	fd840613          	addi	a2,s0,-40
    800052e8:	4581                	li	a1,0
    800052ea:	4501                	li	a0,0
    800052ec:	00000097          	auipc	ra,0x0
    800052f0:	ddc080e7          	jalr	-548(ra) # 800050c8 <argfd>
    return -1;
    800052f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052f6:	02054363          	bltz	a0,8000531c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052fa:	fd843503          	ld	a0,-40(s0)
    800052fe:	00000097          	auipc	ra,0x0
    80005302:	e32080e7          	jalr	-462(ra) # 80005130 <fdalloc>
    80005306:	84aa                	mv	s1,a0
    return -1;
    80005308:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000530a:	00054963          	bltz	a0,8000531c <sys_dup+0x42>
  filedup(f);
    8000530e:	fd843503          	ld	a0,-40(s0)
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	37a080e7          	jalr	890(ra) # 8000468c <filedup>
  return fd;
    8000531a:	87a6                	mv	a5,s1
}
    8000531c:	853e                	mv	a0,a5
    8000531e:	70a2                	ld	ra,40(sp)
    80005320:	7402                	ld	s0,32(sp)
    80005322:	64e2                	ld	s1,24(sp)
    80005324:	6145                	addi	sp,sp,48
    80005326:	8082                	ret

0000000080005328 <sys_read>:
{
    80005328:	7179                	addi	sp,sp,-48
    8000532a:	f406                	sd	ra,40(sp)
    8000532c:	f022                	sd	s0,32(sp)
    8000532e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005330:	fe840613          	addi	a2,s0,-24
    80005334:	4581                	li	a1,0
    80005336:	4501                	li	a0,0
    80005338:	00000097          	auipc	ra,0x0
    8000533c:	d90080e7          	jalr	-624(ra) # 800050c8 <argfd>
    return -1;
    80005340:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005342:	04054163          	bltz	a0,80005384 <sys_read+0x5c>
    80005346:	fe440593          	addi	a1,s0,-28
    8000534a:	4509                	li	a0,2
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	938080e7          	jalr	-1736(ra) # 80002c84 <argint>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005356:	02054763          	bltz	a0,80005384 <sys_read+0x5c>
    8000535a:	fd840593          	addi	a1,s0,-40
    8000535e:	4505                	li	a0,1
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	946080e7          	jalr	-1722(ra) # 80002ca6 <argaddr>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536a:	00054d63          	bltz	a0,80005384 <sys_read+0x5c>
  return fileread(f, p, n);
    8000536e:	fe442603          	lw	a2,-28(s0)
    80005372:	fd843583          	ld	a1,-40(s0)
    80005376:	fe843503          	ld	a0,-24(s0)
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	49e080e7          	jalr	1182(ra) # 80004818 <fileread>
    80005382:	87aa                	mv	a5,a0
}
    80005384:	853e                	mv	a0,a5
    80005386:	70a2                	ld	ra,40(sp)
    80005388:	7402                	ld	s0,32(sp)
    8000538a:	6145                	addi	sp,sp,48
    8000538c:	8082                	ret

000000008000538e <sys_write>:
{
    8000538e:	7179                	addi	sp,sp,-48
    80005390:	f406                	sd	ra,40(sp)
    80005392:	f022                	sd	s0,32(sp)
    80005394:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005396:	fe840613          	addi	a2,s0,-24
    8000539a:	4581                	li	a1,0
    8000539c:	4501                	li	a0,0
    8000539e:	00000097          	auipc	ra,0x0
    800053a2:	d2a080e7          	jalr	-726(ra) # 800050c8 <argfd>
    return -1;
    800053a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a8:	04054163          	bltz	a0,800053ea <sys_write+0x5c>
    800053ac:	fe440593          	addi	a1,s0,-28
    800053b0:	4509                	li	a0,2
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	8d2080e7          	jalr	-1838(ra) # 80002c84 <argint>
    return -1;
    800053ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053bc:	02054763          	bltz	a0,800053ea <sys_write+0x5c>
    800053c0:	fd840593          	addi	a1,s0,-40
    800053c4:	4505                	li	a0,1
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	8e0080e7          	jalr	-1824(ra) # 80002ca6 <argaddr>
    return -1;
    800053ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d0:	00054d63          	bltz	a0,800053ea <sys_write+0x5c>
  return filewrite(f, p, n);
    800053d4:	fe442603          	lw	a2,-28(s0)
    800053d8:	fd843583          	ld	a1,-40(s0)
    800053dc:	fe843503          	ld	a0,-24(s0)
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	4fa080e7          	jalr	1274(ra) # 800048da <filewrite>
    800053e8:	87aa                	mv	a5,a0
}
    800053ea:	853e                	mv	a0,a5
    800053ec:	70a2                	ld	ra,40(sp)
    800053ee:	7402                	ld	s0,32(sp)
    800053f0:	6145                	addi	sp,sp,48
    800053f2:	8082                	ret

00000000800053f4 <sys_close>:
{
    800053f4:	1101                	addi	sp,sp,-32
    800053f6:	ec06                	sd	ra,24(sp)
    800053f8:	e822                	sd	s0,16(sp)
    800053fa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053fc:	fe040613          	addi	a2,s0,-32
    80005400:	fec40593          	addi	a1,s0,-20
    80005404:	4501                	li	a0,0
    80005406:	00000097          	auipc	ra,0x0
    8000540a:	cc2080e7          	jalr	-830(ra) # 800050c8 <argfd>
    return -1;
    8000540e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005410:	02054463          	bltz	a0,80005438 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005414:	ffffc097          	auipc	ra,0xffffc
    80005418:	6c0080e7          	jalr	1728(ra) # 80001ad4 <myproc>
    8000541c:	fec42783          	lw	a5,-20(s0)
    80005420:	07e9                	addi	a5,a5,26
    80005422:	078e                	slli	a5,a5,0x3
    80005424:	97aa                	add	a5,a5,a0
    80005426:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000542a:	fe043503          	ld	a0,-32(s0)
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	2b0080e7          	jalr	688(ra) # 800046de <fileclose>
  return 0;
    80005436:	4781                	li	a5,0
}
    80005438:	853e                	mv	a0,a5
    8000543a:	60e2                	ld	ra,24(sp)
    8000543c:	6442                	ld	s0,16(sp)
    8000543e:	6105                	addi	sp,sp,32
    80005440:	8082                	ret

0000000080005442 <sys_fstat>:
{
    80005442:	1101                	addi	sp,sp,-32
    80005444:	ec06                	sd	ra,24(sp)
    80005446:	e822                	sd	s0,16(sp)
    80005448:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000544a:	fe840613          	addi	a2,s0,-24
    8000544e:	4581                	li	a1,0
    80005450:	4501                	li	a0,0
    80005452:	00000097          	auipc	ra,0x0
    80005456:	c76080e7          	jalr	-906(ra) # 800050c8 <argfd>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000545c:	02054563          	bltz	a0,80005486 <sys_fstat+0x44>
    80005460:	fe040593          	addi	a1,s0,-32
    80005464:	4505                	li	a0,1
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	840080e7          	jalr	-1984(ra) # 80002ca6 <argaddr>
    return -1;
    8000546e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005470:	00054b63          	bltz	a0,80005486 <sys_fstat+0x44>
  return filestat(f, st);
    80005474:	fe043583          	ld	a1,-32(s0)
    80005478:	fe843503          	ld	a0,-24(s0)
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	32a080e7          	jalr	810(ra) # 800047a6 <filestat>
    80005484:	87aa                	mv	a5,a0
}
    80005486:	853e                	mv	a0,a5
    80005488:	60e2                	ld	ra,24(sp)
    8000548a:	6442                	ld	s0,16(sp)
    8000548c:	6105                	addi	sp,sp,32
    8000548e:	8082                	ret

0000000080005490 <sys_link>:
{
    80005490:	7169                	addi	sp,sp,-304
    80005492:	f606                	sd	ra,296(sp)
    80005494:	f222                	sd	s0,288(sp)
    80005496:	ee26                	sd	s1,280(sp)
    80005498:	ea4a                	sd	s2,272(sp)
    8000549a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000549c:	08000613          	li	a2,128
    800054a0:	ed040593          	addi	a1,s0,-304
    800054a4:	4501                	li	a0,0
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	822080e7          	jalr	-2014(ra) # 80002cc8 <argstr>
    return -1;
    800054ae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b0:	10054e63          	bltz	a0,800055cc <sys_link+0x13c>
    800054b4:	08000613          	li	a2,128
    800054b8:	f5040593          	addi	a1,s0,-176
    800054bc:	4505                	li	a0,1
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	80a080e7          	jalr	-2038(ra) # 80002cc8 <argstr>
    return -1;
    800054c6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054c8:	10054263          	bltz	a0,800055cc <sys_link+0x13c>
  begin_op();
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	d46080e7          	jalr	-698(ra) # 80004212 <begin_op>
  if((ip = namei(old)) == 0){
    800054d4:	ed040513          	addi	a0,s0,-304
    800054d8:	fffff097          	auipc	ra,0xfffff
    800054dc:	b1e080e7          	jalr	-1250(ra) # 80003ff6 <namei>
    800054e0:	84aa                	mv	s1,a0
    800054e2:	c551                	beqz	a0,8000556e <sys_link+0xde>
  ilock(ip);
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	35c080e7          	jalr	860(ra) # 80003840 <ilock>
  if(ip->type == T_DIR){
    800054ec:	04449703          	lh	a4,68(s1)
    800054f0:	4785                	li	a5,1
    800054f2:	08f70463          	beq	a4,a5,8000557a <sys_link+0xea>
  ip->nlink++;
    800054f6:	04a4d783          	lhu	a5,74(s1)
    800054fa:	2785                	addiw	a5,a5,1
    800054fc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005500:	8526                	mv	a0,s1
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	274080e7          	jalr	628(ra) # 80003776 <iupdate>
  iunlock(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	3f6080e7          	jalr	1014(ra) # 80003902 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005514:	fd040593          	addi	a1,s0,-48
    80005518:	f5040513          	addi	a0,s0,-176
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	af8080e7          	jalr	-1288(ra) # 80004014 <nameiparent>
    80005524:	892a                	mv	s2,a0
    80005526:	c935                	beqz	a0,8000559a <sys_link+0x10a>
  ilock(dp);
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	318080e7          	jalr	792(ra) # 80003840 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005530:	00092703          	lw	a4,0(s2)
    80005534:	409c                	lw	a5,0(s1)
    80005536:	04f71d63          	bne	a4,a5,80005590 <sys_link+0x100>
    8000553a:	40d0                	lw	a2,4(s1)
    8000553c:	fd040593          	addi	a1,s0,-48
    80005540:	854a                	mv	a0,s2
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	9f2080e7          	jalr	-1550(ra) # 80003f34 <dirlink>
    8000554a:	04054363          	bltz	a0,80005590 <sys_link+0x100>
  iunlockput(dp);
    8000554e:	854a                	mv	a0,s2
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	552080e7          	jalr	1362(ra) # 80003aa2 <iunlockput>
  iput(ip);
    80005558:	8526                	mv	a0,s1
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	4a0080e7          	jalr	1184(ra) # 800039fa <iput>
  end_op();
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	d30080e7          	jalr	-720(ra) # 80004292 <end_op>
  return 0;
    8000556a:	4781                	li	a5,0
    8000556c:	a085                	j	800055cc <sys_link+0x13c>
    end_op();
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	d24080e7          	jalr	-732(ra) # 80004292 <end_op>
    return -1;
    80005576:	57fd                	li	a5,-1
    80005578:	a891                	j	800055cc <sys_link+0x13c>
    iunlockput(ip);
    8000557a:	8526                	mv	a0,s1
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	526080e7          	jalr	1318(ra) # 80003aa2 <iunlockput>
    end_op();
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	d0e080e7          	jalr	-754(ra) # 80004292 <end_op>
    return -1;
    8000558c:	57fd                	li	a5,-1
    8000558e:	a83d                	j	800055cc <sys_link+0x13c>
    iunlockput(dp);
    80005590:	854a                	mv	a0,s2
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	510080e7          	jalr	1296(ra) # 80003aa2 <iunlockput>
  ilock(ip);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	2a4080e7          	jalr	676(ra) # 80003840 <ilock>
  ip->nlink--;
    800055a4:	04a4d783          	lhu	a5,74(s1)
    800055a8:	37fd                	addiw	a5,a5,-1
    800055aa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055ae:	8526                	mv	a0,s1
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	1c6080e7          	jalr	454(ra) # 80003776 <iupdate>
  iunlockput(ip);
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	4e8080e7          	jalr	1256(ra) # 80003aa2 <iunlockput>
  end_op();
    800055c2:	fffff097          	auipc	ra,0xfffff
    800055c6:	cd0080e7          	jalr	-816(ra) # 80004292 <end_op>
  return -1;
    800055ca:	57fd                	li	a5,-1
}
    800055cc:	853e                	mv	a0,a5
    800055ce:	70b2                	ld	ra,296(sp)
    800055d0:	7412                	ld	s0,288(sp)
    800055d2:	64f2                	ld	s1,280(sp)
    800055d4:	6952                	ld	s2,272(sp)
    800055d6:	6155                	addi	sp,sp,304
    800055d8:	8082                	ret

00000000800055da <sys_unlink>:
{
    800055da:	7151                	addi	sp,sp,-240
    800055dc:	f586                	sd	ra,232(sp)
    800055de:	f1a2                	sd	s0,224(sp)
    800055e0:	eda6                	sd	s1,216(sp)
    800055e2:	e9ca                	sd	s2,208(sp)
    800055e4:	e5ce                	sd	s3,200(sp)
    800055e6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055e8:	08000613          	li	a2,128
    800055ec:	f3040593          	addi	a1,s0,-208
    800055f0:	4501                	li	a0,0
    800055f2:	ffffd097          	auipc	ra,0xffffd
    800055f6:	6d6080e7          	jalr	1750(ra) # 80002cc8 <argstr>
    800055fa:	18054163          	bltz	a0,8000577c <sys_unlink+0x1a2>
  begin_op();
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	c14080e7          	jalr	-1004(ra) # 80004212 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005606:	fb040593          	addi	a1,s0,-80
    8000560a:	f3040513          	addi	a0,s0,-208
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	a06080e7          	jalr	-1530(ra) # 80004014 <nameiparent>
    80005616:	84aa                	mv	s1,a0
    80005618:	c979                	beqz	a0,800056ee <sys_unlink+0x114>
  ilock(dp);
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	226080e7          	jalr	550(ra) # 80003840 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005622:	00003597          	auipc	a1,0x3
    80005626:	12658593          	addi	a1,a1,294 # 80008748 <syscalls+0x2c0>
    8000562a:	fb040513          	addi	a0,s0,-80
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	6dc080e7          	jalr	1756(ra) # 80003d0a <namecmp>
    80005636:	14050a63          	beqz	a0,8000578a <sys_unlink+0x1b0>
    8000563a:	00003597          	auipc	a1,0x3
    8000563e:	11658593          	addi	a1,a1,278 # 80008750 <syscalls+0x2c8>
    80005642:	fb040513          	addi	a0,s0,-80
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	6c4080e7          	jalr	1732(ra) # 80003d0a <namecmp>
    8000564e:	12050e63          	beqz	a0,8000578a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005652:	f2c40613          	addi	a2,s0,-212
    80005656:	fb040593          	addi	a1,s0,-80
    8000565a:	8526                	mv	a0,s1
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	6c8080e7          	jalr	1736(ra) # 80003d24 <dirlookup>
    80005664:	892a                	mv	s2,a0
    80005666:	12050263          	beqz	a0,8000578a <sys_unlink+0x1b0>
  ilock(ip);
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	1d6080e7          	jalr	470(ra) # 80003840 <ilock>
  if(ip->nlink < 1)
    80005672:	04a91783          	lh	a5,74(s2)
    80005676:	08f05263          	blez	a5,800056fa <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000567a:	04491703          	lh	a4,68(s2)
    8000567e:	4785                	li	a5,1
    80005680:	08f70563          	beq	a4,a5,8000570a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005684:	4641                	li	a2,16
    80005686:	4581                	li	a1,0
    80005688:	fc040513          	addi	a0,s0,-64
    8000568c:	ffffb097          	auipc	ra,0xffffb
    80005690:	654080e7          	jalr	1620(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005694:	4741                	li	a4,16
    80005696:	f2c42683          	lw	a3,-212(s0)
    8000569a:	fc040613          	addi	a2,s0,-64
    8000569e:	4581                	li	a1,0
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	54a080e7          	jalr	1354(ra) # 80003bec <writei>
    800056aa:	47c1                	li	a5,16
    800056ac:	0af51563          	bne	a0,a5,80005756 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056b0:	04491703          	lh	a4,68(s2)
    800056b4:	4785                	li	a5,1
    800056b6:	0af70863          	beq	a4,a5,80005766 <sys_unlink+0x18c>
  iunlockput(dp);
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	3e6080e7          	jalr	998(ra) # 80003aa2 <iunlockput>
  ip->nlink--;
    800056c4:	04a95783          	lhu	a5,74(s2)
    800056c8:	37fd                	addiw	a5,a5,-1
    800056ca:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056ce:	854a                	mv	a0,s2
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	0a6080e7          	jalr	166(ra) # 80003776 <iupdate>
  iunlockput(ip);
    800056d8:	854a                	mv	a0,s2
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	3c8080e7          	jalr	968(ra) # 80003aa2 <iunlockput>
  end_op();
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	bb0080e7          	jalr	-1104(ra) # 80004292 <end_op>
  return 0;
    800056ea:	4501                	li	a0,0
    800056ec:	a84d                	j	8000579e <sys_unlink+0x1c4>
    end_op();
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	ba4080e7          	jalr	-1116(ra) # 80004292 <end_op>
    return -1;
    800056f6:	557d                	li	a0,-1
    800056f8:	a05d                	j	8000579e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056fa:	00003517          	auipc	a0,0x3
    800056fe:	07e50513          	addi	a0,a0,126 # 80008778 <syscalls+0x2f0>
    80005702:	ffffb097          	auipc	ra,0xffffb
    80005706:	e3c080e7          	jalr	-452(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000570a:	04c92703          	lw	a4,76(s2)
    8000570e:	02000793          	li	a5,32
    80005712:	f6e7f9e3          	bgeu	a5,a4,80005684 <sys_unlink+0xaa>
    80005716:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000571a:	4741                	li	a4,16
    8000571c:	86ce                	mv	a3,s3
    8000571e:	f1840613          	addi	a2,s0,-232
    80005722:	4581                	li	a1,0
    80005724:	854a                	mv	a0,s2
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	3ce080e7          	jalr	974(ra) # 80003af4 <readi>
    8000572e:	47c1                	li	a5,16
    80005730:	00f51b63          	bne	a0,a5,80005746 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005734:	f1845783          	lhu	a5,-232(s0)
    80005738:	e7a1                	bnez	a5,80005780 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000573a:	29c1                	addiw	s3,s3,16
    8000573c:	04c92783          	lw	a5,76(s2)
    80005740:	fcf9ede3          	bltu	s3,a5,8000571a <sys_unlink+0x140>
    80005744:	b781                	j	80005684 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005746:	00003517          	auipc	a0,0x3
    8000574a:	04a50513          	addi	a0,a0,74 # 80008790 <syscalls+0x308>
    8000574e:	ffffb097          	auipc	ra,0xffffb
    80005752:	df0080e7          	jalr	-528(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005756:	00003517          	auipc	a0,0x3
    8000575a:	05250513          	addi	a0,a0,82 # 800087a8 <syscalls+0x320>
    8000575e:	ffffb097          	auipc	ra,0xffffb
    80005762:	de0080e7          	jalr	-544(ra) # 8000053e <panic>
    dp->nlink--;
    80005766:	04a4d783          	lhu	a5,74(s1)
    8000576a:	37fd                	addiw	a5,a5,-1
    8000576c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005770:	8526                	mv	a0,s1
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	004080e7          	jalr	4(ra) # 80003776 <iupdate>
    8000577a:	b781                	j	800056ba <sys_unlink+0xe0>
    return -1;
    8000577c:	557d                	li	a0,-1
    8000577e:	a005                	j	8000579e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005780:	854a                	mv	a0,s2
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	320080e7          	jalr	800(ra) # 80003aa2 <iunlockput>
  iunlockput(dp);
    8000578a:	8526                	mv	a0,s1
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	316080e7          	jalr	790(ra) # 80003aa2 <iunlockput>
  end_op();
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	afe080e7          	jalr	-1282(ra) # 80004292 <end_op>
  return -1;
    8000579c:	557d                	li	a0,-1
}
    8000579e:	70ae                	ld	ra,232(sp)
    800057a0:	740e                	ld	s0,224(sp)
    800057a2:	64ee                	ld	s1,216(sp)
    800057a4:	694e                	ld	s2,208(sp)
    800057a6:	69ae                	ld	s3,200(sp)
    800057a8:	616d                	addi	sp,sp,240
    800057aa:	8082                	ret

00000000800057ac <sys_open>:

uint64
sys_open(void)
{
    800057ac:	7131                	addi	sp,sp,-192
    800057ae:	fd06                	sd	ra,184(sp)
    800057b0:	f922                	sd	s0,176(sp)
    800057b2:	f526                	sd	s1,168(sp)
    800057b4:	f14a                	sd	s2,160(sp)
    800057b6:	ed4e                	sd	s3,152(sp)
    800057b8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057ba:	08000613          	li	a2,128
    800057be:	f5040593          	addi	a1,s0,-176
    800057c2:	4501                	li	a0,0
    800057c4:	ffffd097          	auipc	ra,0xffffd
    800057c8:	504080e7          	jalr	1284(ra) # 80002cc8 <argstr>
    return -1;
    800057cc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057ce:	0c054163          	bltz	a0,80005890 <sys_open+0xe4>
    800057d2:	f4c40593          	addi	a1,s0,-180
    800057d6:	4505                	li	a0,1
    800057d8:	ffffd097          	auipc	ra,0xffffd
    800057dc:	4ac080e7          	jalr	1196(ra) # 80002c84 <argint>
    800057e0:	0a054863          	bltz	a0,80005890 <sys_open+0xe4>

  begin_op();
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	a2e080e7          	jalr	-1490(ra) # 80004212 <begin_op>

  if(omode & O_CREATE){
    800057ec:	f4c42783          	lw	a5,-180(s0)
    800057f0:	2007f793          	andi	a5,a5,512
    800057f4:	cbdd                	beqz	a5,800058aa <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057f6:	4681                	li	a3,0
    800057f8:	4601                	li	a2,0
    800057fa:	4589                	li	a1,2
    800057fc:	f5040513          	addi	a0,s0,-176
    80005800:	00000097          	auipc	ra,0x0
    80005804:	972080e7          	jalr	-1678(ra) # 80005172 <create>
    80005808:	892a                	mv	s2,a0
    if(ip == 0){
    8000580a:	c959                	beqz	a0,800058a0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000580c:	04491703          	lh	a4,68(s2)
    80005810:	478d                	li	a5,3
    80005812:	00f71763          	bne	a4,a5,80005820 <sys_open+0x74>
    80005816:	04695703          	lhu	a4,70(s2)
    8000581a:	47a5                	li	a5,9
    8000581c:	0ce7ec63          	bltu	a5,a4,800058f4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	e02080e7          	jalr	-510(ra) # 80004622 <filealloc>
    80005828:	89aa                	mv	s3,a0
    8000582a:	10050263          	beqz	a0,8000592e <sys_open+0x182>
    8000582e:	00000097          	auipc	ra,0x0
    80005832:	902080e7          	jalr	-1790(ra) # 80005130 <fdalloc>
    80005836:	84aa                	mv	s1,a0
    80005838:	0e054663          	bltz	a0,80005924 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000583c:	04491703          	lh	a4,68(s2)
    80005840:	478d                	li	a5,3
    80005842:	0cf70463          	beq	a4,a5,8000590a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005846:	4789                	li	a5,2
    80005848:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000584c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005850:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005854:	f4c42783          	lw	a5,-180(s0)
    80005858:	0017c713          	xori	a4,a5,1
    8000585c:	8b05                	andi	a4,a4,1
    8000585e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005862:	0037f713          	andi	a4,a5,3
    80005866:	00e03733          	snez	a4,a4
    8000586a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000586e:	4007f793          	andi	a5,a5,1024
    80005872:	c791                	beqz	a5,8000587e <sys_open+0xd2>
    80005874:	04491703          	lh	a4,68(s2)
    80005878:	4789                	li	a5,2
    8000587a:	08f70f63          	beq	a4,a5,80005918 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000587e:	854a                	mv	a0,s2
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	082080e7          	jalr	130(ra) # 80003902 <iunlock>
  end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	a0a080e7          	jalr	-1526(ra) # 80004292 <end_op>

  return fd;
}
    80005890:	8526                	mv	a0,s1
    80005892:	70ea                	ld	ra,184(sp)
    80005894:	744a                	ld	s0,176(sp)
    80005896:	74aa                	ld	s1,168(sp)
    80005898:	790a                	ld	s2,160(sp)
    8000589a:	69ea                	ld	s3,152(sp)
    8000589c:	6129                	addi	sp,sp,192
    8000589e:	8082                	ret
      end_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	9f2080e7          	jalr	-1550(ra) # 80004292 <end_op>
      return -1;
    800058a8:	b7e5                	j	80005890 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058aa:	f5040513          	addi	a0,s0,-176
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	748080e7          	jalr	1864(ra) # 80003ff6 <namei>
    800058b6:	892a                	mv	s2,a0
    800058b8:	c905                	beqz	a0,800058e8 <sys_open+0x13c>
    ilock(ip);
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	f86080e7          	jalr	-122(ra) # 80003840 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058c2:	04491703          	lh	a4,68(s2)
    800058c6:	4785                	li	a5,1
    800058c8:	f4f712e3          	bne	a4,a5,8000580c <sys_open+0x60>
    800058cc:	f4c42783          	lw	a5,-180(s0)
    800058d0:	dba1                	beqz	a5,80005820 <sys_open+0x74>
      iunlockput(ip);
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	1ce080e7          	jalr	462(ra) # 80003aa2 <iunlockput>
      end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	9b6080e7          	jalr	-1610(ra) # 80004292 <end_op>
      return -1;
    800058e4:	54fd                	li	s1,-1
    800058e6:	b76d                	j	80005890 <sys_open+0xe4>
      end_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	9aa080e7          	jalr	-1622(ra) # 80004292 <end_op>
      return -1;
    800058f0:	54fd                	li	s1,-1
    800058f2:	bf79                	j	80005890 <sys_open+0xe4>
    iunlockput(ip);
    800058f4:	854a                	mv	a0,s2
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	1ac080e7          	jalr	428(ra) # 80003aa2 <iunlockput>
    end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	994080e7          	jalr	-1644(ra) # 80004292 <end_op>
    return -1;
    80005906:	54fd                	li	s1,-1
    80005908:	b761                	j	80005890 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000590a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000590e:	04691783          	lh	a5,70(s2)
    80005912:	02f99223          	sh	a5,36(s3)
    80005916:	bf2d                	j	80005850 <sys_open+0xa4>
    itrunc(ip);
    80005918:	854a                	mv	a0,s2
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	034080e7          	jalr	52(ra) # 8000394e <itrunc>
    80005922:	bfb1                	j	8000587e <sys_open+0xd2>
      fileclose(f);
    80005924:	854e                	mv	a0,s3
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	db8080e7          	jalr	-584(ra) # 800046de <fileclose>
    iunlockput(ip);
    8000592e:	854a                	mv	a0,s2
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	172080e7          	jalr	370(ra) # 80003aa2 <iunlockput>
    end_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	95a080e7          	jalr	-1702(ra) # 80004292 <end_op>
    return -1;
    80005940:	54fd                	li	s1,-1
    80005942:	b7b9                	j	80005890 <sys_open+0xe4>

0000000080005944 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005944:	7175                	addi	sp,sp,-144
    80005946:	e506                	sd	ra,136(sp)
    80005948:	e122                	sd	s0,128(sp)
    8000594a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	8c6080e7          	jalr	-1850(ra) # 80004212 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005954:	08000613          	li	a2,128
    80005958:	f7040593          	addi	a1,s0,-144
    8000595c:	4501                	li	a0,0
    8000595e:	ffffd097          	auipc	ra,0xffffd
    80005962:	36a080e7          	jalr	874(ra) # 80002cc8 <argstr>
    80005966:	02054963          	bltz	a0,80005998 <sys_mkdir+0x54>
    8000596a:	4681                	li	a3,0
    8000596c:	4601                	li	a2,0
    8000596e:	4585                	li	a1,1
    80005970:	f7040513          	addi	a0,s0,-144
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	7fe080e7          	jalr	2046(ra) # 80005172 <create>
    8000597c:	cd11                	beqz	a0,80005998 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	124080e7          	jalr	292(ra) # 80003aa2 <iunlockput>
  end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	90c080e7          	jalr	-1780(ra) # 80004292 <end_op>
  return 0;
    8000598e:	4501                	li	a0,0
}
    80005990:	60aa                	ld	ra,136(sp)
    80005992:	640a                	ld	s0,128(sp)
    80005994:	6149                	addi	sp,sp,144
    80005996:	8082                	ret
    end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	8fa080e7          	jalr	-1798(ra) # 80004292 <end_op>
    return -1;
    800059a0:	557d                	li	a0,-1
    800059a2:	b7fd                	j	80005990 <sys_mkdir+0x4c>

00000000800059a4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059a4:	7135                	addi	sp,sp,-160
    800059a6:	ed06                	sd	ra,152(sp)
    800059a8:	e922                	sd	s0,144(sp)
    800059aa:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	866080e7          	jalr	-1946(ra) # 80004212 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059b4:	08000613          	li	a2,128
    800059b8:	f7040593          	addi	a1,s0,-144
    800059bc:	4501                	li	a0,0
    800059be:	ffffd097          	auipc	ra,0xffffd
    800059c2:	30a080e7          	jalr	778(ra) # 80002cc8 <argstr>
    800059c6:	04054a63          	bltz	a0,80005a1a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059ca:	f6c40593          	addi	a1,s0,-148
    800059ce:	4505                	li	a0,1
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	2b4080e7          	jalr	692(ra) # 80002c84 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059d8:	04054163          	bltz	a0,80005a1a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059dc:	f6840593          	addi	a1,s0,-152
    800059e0:	4509                	li	a0,2
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	2a2080e7          	jalr	674(ra) # 80002c84 <argint>
     argint(1, &major) < 0 ||
    800059ea:	02054863          	bltz	a0,80005a1a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059ee:	f6841683          	lh	a3,-152(s0)
    800059f2:	f6c41603          	lh	a2,-148(s0)
    800059f6:	458d                	li	a1,3
    800059f8:	f7040513          	addi	a0,s0,-144
    800059fc:	fffff097          	auipc	ra,0xfffff
    80005a00:	776080e7          	jalr	1910(ra) # 80005172 <create>
     argint(2, &minor) < 0 ||
    80005a04:	c919                	beqz	a0,80005a1a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	09c080e7          	jalr	156(ra) # 80003aa2 <iunlockput>
  end_op();
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	884080e7          	jalr	-1916(ra) # 80004292 <end_op>
  return 0;
    80005a16:	4501                	li	a0,0
    80005a18:	a031                	j	80005a24 <sys_mknod+0x80>
    end_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	878080e7          	jalr	-1928(ra) # 80004292 <end_op>
    return -1;
    80005a22:	557d                	li	a0,-1
}
    80005a24:	60ea                	ld	ra,152(sp)
    80005a26:	644a                	ld	s0,144(sp)
    80005a28:	610d                	addi	sp,sp,160
    80005a2a:	8082                	ret

0000000080005a2c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a2c:	7135                	addi	sp,sp,-160
    80005a2e:	ed06                	sd	ra,152(sp)
    80005a30:	e922                	sd	s0,144(sp)
    80005a32:	e526                	sd	s1,136(sp)
    80005a34:	e14a                	sd	s2,128(sp)
    80005a36:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a38:	ffffc097          	auipc	ra,0xffffc
    80005a3c:	09c080e7          	jalr	156(ra) # 80001ad4 <myproc>
    80005a40:	892a                	mv	s2,a0
  
  begin_op();
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	7d0080e7          	jalr	2000(ra) # 80004212 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a4a:	08000613          	li	a2,128
    80005a4e:	f6040593          	addi	a1,s0,-160
    80005a52:	4501                	li	a0,0
    80005a54:	ffffd097          	auipc	ra,0xffffd
    80005a58:	274080e7          	jalr	628(ra) # 80002cc8 <argstr>
    80005a5c:	04054b63          	bltz	a0,80005ab2 <sys_chdir+0x86>
    80005a60:	f6040513          	addi	a0,s0,-160
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	592080e7          	jalr	1426(ra) # 80003ff6 <namei>
    80005a6c:	84aa                	mv	s1,a0
    80005a6e:	c131                	beqz	a0,80005ab2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	dd0080e7          	jalr	-560(ra) # 80003840 <ilock>
  if(ip->type != T_DIR){
    80005a78:	04449703          	lh	a4,68(s1)
    80005a7c:	4785                	li	a5,1
    80005a7e:	04f71063          	bne	a4,a5,80005abe <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a82:	8526                	mv	a0,s1
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	e7e080e7          	jalr	-386(ra) # 80003902 <iunlock>
  iput(p->cwd);
    80005a8c:	15093503          	ld	a0,336(s2)
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	f6a080e7          	jalr	-150(ra) # 800039fa <iput>
  end_op();
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	7fa080e7          	jalr	2042(ra) # 80004292 <end_op>
  p->cwd = ip;
    80005aa0:	14993823          	sd	s1,336(s2)
  return 0;
    80005aa4:	4501                	li	a0,0
}
    80005aa6:	60ea                	ld	ra,152(sp)
    80005aa8:	644a                	ld	s0,144(sp)
    80005aaa:	64aa                	ld	s1,136(sp)
    80005aac:	690a                	ld	s2,128(sp)
    80005aae:	610d                	addi	sp,sp,160
    80005ab0:	8082                	ret
    end_op();
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	7e0080e7          	jalr	2016(ra) # 80004292 <end_op>
    return -1;
    80005aba:	557d                	li	a0,-1
    80005abc:	b7ed                	j	80005aa6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005abe:	8526                	mv	a0,s1
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	fe2080e7          	jalr	-30(ra) # 80003aa2 <iunlockput>
    end_op();
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	7ca080e7          	jalr	1994(ra) # 80004292 <end_op>
    return -1;
    80005ad0:	557d                	li	a0,-1
    80005ad2:	bfd1                	j	80005aa6 <sys_chdir+0x7a>

0000000080005ad4 <sys_exec>:

uint64
sys_exec(void)
{
    80005ad4:	7145                	addi	sp,sp,-464
    80005ad6:	e786                	sd	ra,456(sp)
    80005ad8:	e3a2                	sd	s0,448(sp)
    80005ada:	ff26                	sd	s1,440(sp)
    80005adc:	fb4a                	sd	s2,432(sp)
    80005ade:	f74e                	sd	s3,424(sp)
    80005ae0:	f352                	sd	s4,416(sp)
    80005ae2:	ef56                	sd	s5,408(sp)
    80005ae4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ae6:	08000613          	li	a2,128
    80005aea:	f4040593          	addi	a1,s0,-192
    80005aee:	4501                	li	a0,0
    80005af0:	ffffd097          	auipc	ra,0xffffd
    80005af4:	1d8080e7          	jalr	472(ra) # 80002cc8 <argstr>
    return -1;
    80005af8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005afa:	0c054a63          	bltz	a0,80005bce <sys_exec+0xfa>
    80005afe:	e3840593          	addi	a1,s0,-456
    80005b02:	4505                	li	a0,1
    80005b04:	ffffd097          	auipc	ra,0xffffd
    80005b08:	1a2080e7          	jalr	418(ra) # 80002ca6 <argaddr>
    80005b0c:	0c054163          	bltz	a0,80005bce <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b10:	10000613          	li	a2,256
    80005b14:	4581                	li	a1,0
    80005b16:	e4040513          	addi	a0,s0,-448
    80005b1a:	ffffb097          	auipc	ra,0xffffb
    80005b1e:	1c6080e7          	jalr	454(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b22:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b26:	89a6                	mv	s3,s1
    80005b28:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b2a:	02000a13          	li	s4,32
    80005b2e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b32:	00391513          	slli	a0,s2,0x3
    80005b36:	e3040593          	addi	a1,s0,-464
    80005b3a:	e3843783          	ld	a5,-456(s0)
    80005b3e:	953e                	add	a0,a0,a5
    80005b40:	ffffd097          	auipc	ra,0xffffd
    80005b44:	0aa080e7          	jalr	170(ra) # 80002bea <fetchaddr>
    80005b48:	02054a63          	bltz	a0,80005b7c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b4c:	e3043783          	ld	a5,-464(s0)
    80005b50:	c3b9                	beqz	a5,80005b96 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b52:	ffffb097          	auipc	ra,0xffffb
    80005b56:	fa2080e7          	jalr	-94(ra) # 80000af4 <kalloc>
    80005b5a:	85aa                	mv	a1,a0
    80005b5c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b60:	cd11                	beqz	a0,80005b7c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b62:	6605                	lui	a2,0x1
    80005b64:	e3043503          	ld	a0,-464(s0)
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	0d4080e7          	jalr	212(ra) # 80002c3c <fetchstr>
    80005b70:	00054663          	bltz	a0,80005b7c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b74:	0905                	addi	s2,s2,1
    80005b76:	09a1                	addi	s3,s3,8
    80005b78:	fb491be3          	bne	s2,s4,80005b2e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b7c:	10048913          	addi	s2,s1,256
    80005b80:	6088                	ld	a0,0(s1)
    80005b82:	c529                	beqz	a0,80005bcc <sys_exec+0xf8>
    kfree(argv[i]);
    80005b84:	ffffb097          	auipc	ra,0xffffb
    80005b88:	e74080e7          	jalr	-396(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b8c:	04a1                	addi	s1,s1,8
    80005b8e:	ff2499e3          	bne	s1,s2,80005b80 <sys_exec+0xac>
  return -1;
    80005b92:	597d                	li	s2,-1
    80005b94:	a82d                	j	80005bce <sys_exec+0xfa>
      argv[i] = 0;
    80005b96:	0a8e                	slli	s5,s5,0x3
    80005b98:	fc040793          	addi	a5,s0,-64
    80005b9c:	9abe                	add	s5,s5,a5
    80005b9e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ba2:	e4040593          	addi	a1,s0,-448
    80005ba6:	f4040513          	addi	a0,s0,-192
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	194080e7          	jalr	404(ra) # 80004d3e <exec>
    80005bb2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bb4:	10048993          	addi	s3,s1,256
    80005bb8:	6088                	ld	a0,0(s1)
    80005bba:	c911                	beqz	a0,80005bce <sys_exec+0xfa>
    kfree(argv[i]);
    80005bbc:	ffffb097          	auipc	ra,0xffffb
    80005bc0:	e3c080e7          	jalr	-452(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc4:	04a1                	addi	s1,s1,8
    80005bc6:	ff3499e3          	bne	s1,s3,80005bb8 <sys_exec+0xe4>
    80005bca:	a011                	j	80005bce <sys_exec+0xfa>
  return -1;
    80005bcc:	597d                	li	s2,-1
}
    80005bce:	854a                	mv	a0,s2
    80005bd0:	60be                	ld	ra,456(sp)
    80005bd2:	641e                	ld	s0,448(sp)
    80005bd4:	74fa                	ld	s1,440(sp)
    80005bd6:	795a                	ld	s2,432(sp)
    80005bd8:	79ba                	ld	s3,424(sp)
    80005bda:	7a1a                	ld	s4,416(sp)
    80005bdc:	6afa                	ld	s5,408(sp)
    80005bde:	6179                	addi	sp,sp,464
    80005be0:	8082                	ret

0000000080005be2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005be2:	7139                	addi	sp,sp,-64
    80005be4:	fc06                	sd	ra,56(sp)
    80005be6:	f822                	sd	s0,48(sp)
    80005be8:	f426                	sd	s1,40(sp)
    80005bea:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bec:	ffffc097          	auipc	ra,0xffffc
    80005bf0:	ee8080e7          	jalr	-280(ra) # 80001ad4 <myproc>
    80005bf4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bf6:	fd840593          	addi	a1,s0,-40
    80005bfa:	4501                	li	a0,0
    80005bfc:	ffffd097          	auipc	ra,0xffffd
    80005c00:	0aa080e7          	jalr	170(ra) # 80002ca6 <argaddr>
    return -1;
    80005c04:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c06:	0e054063          	bltz	a0,80005ce6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c0a:	fc840593          	addi	a1,s0,-56
    80005c0e:	fd040513          	addi	a0,s0,-48
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	dfc080e7          	jalr	-516(ra) # 80004a0e <pipealloc>
    return -1;
    80005c1a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c1c:	0c054563          	bltz	a0,80005ce6 <sys_pipe+0x104>
  fd0 = -1;
    80005c20:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c24:	fd043503          	ld	a0,-48(s0)
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	508080e7          	jalr	1288(ra) # 80005130 <fdalloc>
    80005c30:	fca42223          	sw	a0,-60(s0)
    80005c34:	08054c63          	bltz	a0,80005ccc <sys_pipe+0xea>
    80005c38:	fc843503          	ld	a0,-56(s0)
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	4f4080e7          	jalr	1268(ra) # 80005130 <fdalloc>
    80005c44:	fca42023          	sw	a0,-64(s0)
    80005c48:	06054863          	bltz	a0,80005cb8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c4c:	4691                	li	a3,4
    80005c4e:	fc440613          	addi	a2,s0,-60
    80005c52:	fd843583          	ld	a1,-40(s0)
    80005c56:	68a8                	ld	a0,80(s1)
    80005c58:	ffffc097          	auipc	ra,0xffffc
    80005c5c:	b3e080e7          	jalr	-1218(ra) # 80001796 <copyout>
    80005c60:	02054063          	bltz	a0,80005c80 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c64:	4691                	li	a3,4
    80005c66:	fc040613          	addi	a2,s0,-64
    80005c6a:	fd843583          	ld	a1,-40(s0)
    80005c6e:	0591                	addi	a1,a1,4
    80005c70:	68a8                	ld	a0,80(s1)
    80005c72:	ffffc097          	auipc	ra,0xffffc
    80005c76:	b24080e7          	jalr	-1244(ra) # 80001796 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c7a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c7c:	06055563          	bgez	a0,80005ce6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c80:	fc442783          	lw	a5,-60(s0)
    80005c84:	07e9                	addi	a5,a5,26
    80005c86:	078e                	slli	a5,a5,0x3
    80005c88:	97a6                	add	a5,a5,s1
    80005c8a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c8e:	fc042503          	lw	a0,-64(s0)
    80005c92:	0569                	addi	a0,a0,26
    80005c94:	050e                	slli	a0,a0,0x3
    80005c96:	9526                	add	a0,a0,s1
    80005c98:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c9c:	fd043503          	ld	a0,-48(s0)
    80005ca0:	fffff097          	auipc	ra,0xfffff
    80005ca4:	a3e080e7          	jalr	-1474(ra) # 800046de <fileclose>
    fileclose(wf);
    80005ca8:	fc843503          	ld	a0,-56(s0)
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	a32080e7          	jalr	-1486(ra) # 800046de <fileclose>
    return -1;
    80005cb4:	57fd                	li	a5,-1
    80005cb6:	a805                	j	80005ce6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cb8:	fc442783          	lw	a5,-60(s0)
    80005cbc:	0007c863          	bltz	a5,80005ccc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cc0:	01a78513          	addi	a0,a5,26
    80005cc4:	050e                	slli	a0,a0,0x3
    80005cc6:	9526                	add	a0,a0,s1
    80005cc8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ccc:	fd043503          	ld	a0,-48(s0)
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	a0e080e7          	jalr	-1522(ra) # 800046de <fileclose>
    fileclose(wf);
    80005cd8:	fc843503          	ld	a0,-56(s0)
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	a02080e7          	jalr	-1534(ra) # 800046de <fileclose>
    return -1;
    80005ce4:	57fd                	li	a5,-1
}
    80005ce6:	853e                	mv	a0,a5
    80005ce8:	70e2                	ld	ra,56(sp)
    80005cea:	7442                	ld	s0,48(sp)
    80005cec:	74a2                	ld	s1,40(sp)
    80005cee:	6121                	addi	sp,sp,64
    80005cf0:	8082                	ret
	...

0000000080005d00 <kernelvec>:
    80005d00:	7111                	addi	sp,sp,-256
    80005d02:	e006                	sd	ra,0(sp)
    80005d04:	e40a                	sd	sp,8(sp)
    80005d06:	e80e                	sd	gp,16(sp)
    80005d08:	ec12                	sd	tp,24(sp)
    80005d0a:	f016                	sd	t0,32(sp)
    80005d0c:	f41a                	sd	t1,40(sp)
    80005d0e:	f81e                	sd	t2,48(sp)
    80005d10:	fc22                	sd	s0,56(sp)
    80005d12:	e0a6                	sd	s1,64(sp)
    80005d14:	e4aa                	sd	a0,72(sp)
    80005d16:	e8ae                	sd	a1,80(sp)
    80005d18:	ecb2                	sd	a2,88(sp)
    80005d1a:	f0b6                	sd	a3,96(sp)
    80005d1c:	f4ba                	sd	a4,104(sp)
    80005d1e:	f8be                	sd	a5,112(sp)
    80005d20:	fcc2                	sd	a6,120(sp)
    80005d22:	e146                	sd	a7,128(sp)
    80005d24:	e54a                	sd	s2,136(sp)
    80005d26:	e94e                	sd	s3,144(sp)
    80005d28:	ed52                	sd	s4,152(sp)
    80005d2a:	f156                	sd	s5,160(sp)
    80005d2c:	f55a                	sd	s6,168(sp)
    80005d2e:	f95e                	sd	s7,176(sp)
    80005d30:	fd62                	sd	s8,184(sp)
    80005d32:	e1e6                	sd	s9,192(sp)
    80005d34:	e5ea                	sd	s10,200(sp)
    80005d36:	e9ee                	sd	s11,208(sp)
    80005d38:	edf2                	sd	t3,216(sp)
    80005d3a:	f1f6                	sd	t4,224(sp)
    80005d3c:	f5fa                	sd	t5,232(sp)
    80005d3e:	f9fe                	sd	t6,240(sp)
    80005d40:	d77fc0ef          	jal	ra,80002ab6 <kerneltrap>
    80005d44:	6082                	ld	ra,0(sp)
    80005d46:	6122                	ld	sp,8(sp)
    80005d48:	61c2                	ld	gp,16(sp)
    80005d4a:	7282                	ld	t0,32(sp)
    80005d4c:	7322                	ld	t1,40(sp)
    80005d4e:	73c2                	ld	t2,48(sp)
    80005d50:	7462                	ld	s0,56(sp)
    80005d52:	6486                	ld	s1,64(sp)
    80005d54:	6526                	ld	a0,72(sp)
    80005d56:	65c6                	ld	a1,80(sp)
    80005d58:	6666                	ld	a2,88(sp)
    80005d5a:	7686                	ld	a3,96(sp)
    80005d5c:	7726                	ld	a4,104(sp)
    80005d5e:	77c6                	ld	a5,112(sp)
    80005d60:	7866                	ld	a6,120(sp)
    80005d62:	688a                	ld	a7,128(sp)
    80005d64:	692a                	ld	s2,136(sp)
    80005d66:	69ca                	ld	s3,144(sp)
    80005d68:	6a6a                	ld	s4,152(sp)
    80005d6a:	7a8a                	ld	s5,160(sp)
    80005d6c:	7b2a                	ld	s6,168(sp)
    80005d6e:	7bca                	ld	s7,176(sp)
    80005d70:	7c6a                	ld	s8,184(sp)
    80005d72:	6c8e                	ld	s9,192(sp)
    80005d74:	6d2e                	ld	s10,200(sp)
    80005d76:	6dce                	ld	s11,208(sp)
    80005d78:	6e6e                	ld	t3,216(sp)
    80005d7a:	7e8e                	ld	t4,224(sp)
    80005d7c:	7f2e                	ld	t5,232(sp)
    80005d7e:	7fce                	ld	t6,240(sp)
    80005d80:	6111                	addi	sp,sp,256
    80005d82:	10200073          	sret
    80005d86:	00000013          	nop
    80005d8a:	00000013          	nop
    80005d8e:	0001                	nop

0000000080005d90 <timervec>:
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	e10c                	sd	a1,0(a0)
    80005d96:	e510                	sd	a2,8(a0)
    80005d98:	e914                	sd	a3,16(a0)
    80005d9a:	6d0c                	ld	a1,24(a0)
    80005d9c:	7110                	ld	a2,32(a0)
    80005d9e:	6194                	ld	a3,0(a1)
    80005da0:	96b2                	add	a3,a3,a2
    80005da2:	e194                	sd	a3,0(a1)
    80005da4:	4589                	li	a1,2
    80005da6:	14459073          	csrw	sip,a1
    80005daa:	6914                	ld	a3,16(a0)
    80005dac:	6510                	ld	a2,8(a0)
    80005dae:	610c                	ld	a1,0(a0)
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	30200073          	mret
	...

0000000080005dba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dba:	1141                	addi	sp,sp,-16
    80005dbc:	e422                	sd	s0,8(sp)
    80005dbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dc0:	0c0007b7          	lui	a5,0xc000
    80005dc4:	4705                	li	a4,1
    80005dc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dc8:	c3d8                	sw	a4,4(a5)
}
    80005dca:	6422                	ld	s0,8(sp)
    80005dcc:	0141                	addi	sp,sp,16
    80005dce:	8082                	ret

0000000080005dd0 <plicinithart>:

void
plicinithart(void)
{
    80005dd0:	1141                	addi	sp,sp,-16
    80005dd2:	e406                	sd	ra,8(sp)
    80005dd4:	e022                	sd	s0,0(sp)
    80005dd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	cd0080e7          	jalr	-816(ra) # 80001aa8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005de0:	0085171b          	slliw	a4,a0,0x8
    80005de4:	0c0027b7          	lui	a5,0xc002
    80005de8:	97ba                	add	a5,a5,a4
    80005dea:	40200713          	li	a4,1026
    80005dee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005df2:	00d5151b          	slliw	a0,a0,0xd
    80005df6:	0c2017b7          	lui	a5,0xc201
    80005dfa:	953e                	add	a0,a0,a5
    80005dfc:	00052023          	sw	zero,0(a0)
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret

0000000080005e08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e08:	1141                	addi	sp,sp,-16
    80005e0a:	e406                	sd	ra,8(sp)
    80005e0c:	e022                	sd	s0,0(sp)
    80005e0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	c98080e7          	jalr	-872(ra) # 80001aa8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e18:	00d5179b          	slliw	a5,a0,0xd
    80005e1c:	0c201537          	lui	a0,0xc201
    80005e20:	953e                	add	a0,a0,a5
  return irq;
}
    80005e22:	4148                	lw	a0,4(a0)
    80005e24:	60a2                	ld	ra,8(sp)
    80005e26:	6402                	ld	s0,0(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e2c:	1101                	addi	sp,sp,-32
    80005e2e:	ec06                	sd	ra,24(sp)
    80005e30:	e822                	sd	s0,16(sp)
    80005e32:	e426                	sd	s1,8(sp)
    80005e34:	1000                	addi	s0,sp,32
    80005e36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	c70080e7          	jalr	-912(ra) # 80001aa8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e40:	00d5151b          	slliw	a0,a0,0xd
    80005e44:	0c2017b7          	lui	a5,0xc201
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	c3c4                	sw	s1,4(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret

0000000080005e56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e56:	1141                	addi	sp,sp,-16
    80005e58:	e406                	sd	ra,8(sp)
    80005e5a:	e022                	sd	s0,0(sp)
    80005e5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e5e:	479d                	li	a5,7
    80005e60:	06a7c963          	blt	a5,a0,80005ed2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e64:	0001d797          	auipc	a5,0x1d
    80005e68:	19c78793          	addi	a5,a5,412 # 80023000 <disk>
    80005e6c:	00a78733          	add	a4,a5,a0
    80005e70:	6789                	lui	a5,0x2
    80005e72:	97ba                	add	a5,a5,a4
    80005e74:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e78:	e7ad                	bnez	a5,80005ee2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e7a:	00451793          	slli	a5,a0,0x4
    80005e7e:	0001f717          	auipc	a4,0x1f
    80005e82:	18270713          	addi	a4,a4,386 # 80025000 <disk+0x2000>
    80005e86:	6314                	ld	a3,0(a4)
    80005e88:	96be                	add	a3,a3,a5
    80005e8a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e8e:	6314                	ld	a3,0(a4)
    80005e90:	96be                	add	a3,a3,a5
    80005e92:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e96:	6314                	ld	a3,0(a4)
    80005e98:	96be                	add	a3,a3,a5
    80005e9a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e9e:	6318                	ld	a4,0(a4)
    80005ea0:	97ba                	add	a5,a5,a4
    80005ea2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ea6:	0001d797          	auipc	a5,0x1d
    80005eaa:	15a78793          	addi	a5,a5,346 # 80023000 <disk>
    80005eae:	97aa                	add	a5,a5,a0
    80005eb0:	6509                	lui	a0,0x2
    80005eb2:	953e                	add	a0,a0,a5
    80005eb4:	4785                	li	a5,1
    80005eb6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eba:	0001f517          	auipc	a0,0x1f
    80005ebe:	15e50513          	addi	a0,a0,350 # 80025018 <disk+0x2018>
    80005ec2:	ffffc097          	auipc	ra,0xffffc
    80005ec6:	514080e7          	jalr	1300(ra) # 800023d6 <wakeup>
}
    80005eca:	60a2                	ld	ra,8(sp)
    80005ecc:	6402                	ld	s0,0(sp)
    80005ece:	0141                	addi	sp,sp,16
    80005ed0:	8082                	ret
    panic("free_desc 1");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	8e650513          	addi	a0,a0,-1818 # 800087b8 <syscalls+0x330>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ee2:	00003517          	auipc	a0,0x3
    80005ee6:	8e650513          	addi	a0,a0,-1818 # 800087c8 <syscalls+0x340>
    80005eea:	ffffa097          	auipc	ra,0xffffa
    80005eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>

0000000080005ef2 <virtio_disk_init>:
{
    80005ef2:	1101                	addi	sp,sp,-32
    80005ef4:	ec06                	sd	ra,24(sp)
    80005ef6:	e822                	sd	s0,16(sp)
    80005ef8:	e426                	sd	s1,8(sp)
    80005efa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005efc:	00003597          	auipc	a1,0x3
    80005f00:	8dc58593          	addi	a1,a1,-1828 # 800087d8 <syscalls+0x350>
    80005f04:	0001f517          	auipc	a0,0x1f
    80005f08:	22450513          	addi	a0,a0,548 # 80025128 <disk+0x2128>
    80005f0c:	ffffb097          	auipc	ra,0xffffb
    80005f10:	c48080e7          	jalr	-952(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f14:	100017b7          	lui	a5,0x10001
    80005f18:	4398                	lw	a4,0(a5)
    80005f1a:	2701                	sext.w	a4,a4
    80005f1c:	747277b7          	lui	a5,0x74727
    80005f20:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f24:	0ef71163          	bne	a4,a5,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f28:	100017b7          	lui	a5,0x10001
    80005f2c:	43dc                	lw	a5,4(a5)
    80005f2e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f30:	4705                	li	a4,1
    80005f32:	0ce79a63          	bne	a5,a4,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f36:	100017b7          	lui	a5,0x10001
    80005f3a:	479c                	lw	a5,8(a5)
    80005f3c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f3e:	4709                	li	a4,2
    80005f40:	0ce79363          	bne	a5,a4,80006006 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f44:	100017b7          	lui	a5,0x10001
    80005f48:	47d8                	lw	a4,12(a5)
    80005f4a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f4c:	554d47b7          	lui	a5,0x554d4
    80005f50:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f54:	0af71963          	bne	a4,a5,80006006 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f58:	100017b7          	lui	a5,0x10001
    80005f5c:	4705                	li	a4,1
    80005f5e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f60:	470d                	li	a4,3
    80005f62:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f64:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f66:	c7ffe737          	lui	a4,0xc7ffe
    80005f6a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f6e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f70:	2701                	sext.w	a4,a4
    80005f72:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f74:	472d                	li	a4,11
    80005f76:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f78:	473d                	li	a4,15
    80005f7a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f7c:	6705                	lui	a4,0x1
    80005f7e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f80:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f84:	5bdc                	lw	a5,52(a5)
    80005f86:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f88:	c7d9                	beqz	a5,80006016 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f8a:	471d                	li	a4,7
    80005f8c:	08f77d63          	bgeu	a4,a5,80006026 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f90:	100014b7          	lui	s1,0x10001
    80005f94:	47a1                	li	a5,8
    80005f96:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f98:	6609                	lui	a2,0x2
    80005f9a:	4581                	li	a1,0
    80005f9c:	0001d517          	auipc	a0,0x1d
    80005fa0:	06450513          	addi	a0,a0,100 # 80023000 <disk>
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	d3c080e7          	jalr	-708(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fac:	0001d717          	auipc	a4,0x1d
    80005fb0:	05470713          	addi	a4,a4,84 # 80023000 <disk>
    80005fb4:	00c75793          	srli	a5,a4,0xc
    80005fb8:	2781                	sext.w	a5,a5
    80005fba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fbc:	0001f797          	auipc	a5,0x1f
    80005fc0:	04478793          	addi	a5,a5,68 # 80025000 <disk+0x2000>
    80005fc4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fc6:	0001d717          	auipc	a4,0x1d
    80005fca:	0ba70713          	addi	a4,a4,186 # 80023080 <disk+0x80>
    80005fce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fd0:	0001e717          	auipc	a4,0x1e
    80005fd4:	03070713          	addi	a4,a4,48 # 80024000 <disk+0x1000>
    80005fd8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fda:	4705                	li	a4,1
    80005fdc:	00e78c23          	sb	a4,24(a5)
    80005fe0:	00e78ca3          	sb	a4,25(a5)
    80005fe4:	00e78d23          	sb	a4,26(a5)
    80005fe8:	00e78da3          	sb	a4,27(a5)
    80005fec:	00e78e23          	sb	a4,28(a5)
    80005ff0:	00e78ea3          	sb	a4,29(a5)
    80005ff4:	00e78f23          	sb	a4,30(a5)
    80005ff8:	00e78fa3          	sb	a4,31(a5)
}
    80005ffc:	60e2                	ld	ra,24(sp)
    80005ffe:	6442                	ld	s0,16(sp)
    80006000:	64a2                	ld	s1,8(sp)
    80006002:	6105                	addi	sp,sp,32
    80006004:	8082                	ret
    panic("could not find virtio disk");
    80006006:	00002517          	auipc	a0,0x2
    8000600a:	7e250513          	addi	a0,a0,2018 # 800087e8 <syscalls+0x360>
    8000600e:	ffffa097          	auipc	ra,0xffffa
    80006012:	530080e7          	jalr	1328(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006016:	00002517          	auipc	a0,0x2
    8000601a:	7f250513          	addi	a0,a0,2034 # 80008808 <syscalls+0x380>
    8000601e:	ffffa097          	auipc	ra,0xffffa
    80006022:	520080e7          	jalr	1312(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006026:	00003517          	auipc	a0,0x3
    8000602a:	80250513          	addi	a0,a0,-2046 # 80008828 <syscalls+0x3a0>
    8000602e:	ffffa097          	auipc	ra,0xffffa
    80006032:	510080e7          	jalr	1296(ra) # 8000053e <panic>

0000000080006036 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006036:	7159                	addi	sp,sp,-112
    80006038:	f486                	sd	ra,104(sp)
    8000603a:	f0a2                	sd	s0,96(sp)
    8000603c:	eca6                	sd	s1,88(sp)
    8000603e:	e8ca                	sd	s2,80(sp)
    80006040:	e4ce                	sd	s3,72(sp)
    80006042:	e0d2                	sd	s4,64(sp)
    80006044:	fc56                	sd	s5,56(sp)
    80006046:	f85a                	sd	s6,48(sp)
    80006048:	f45e                	sd	s7,40(sp)
    8000604a:	f062                	sd	s8,32(sp)
    8000604c:	ec66                	sd	s9,24(sp)
    8000604e:	e86a                	sd	s10,16(sp)
    80006050:	1880                	addi	s0,sp,112
    80006052:	892a                	mv	s2,a0
    80006054:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006056:	00c52c83          	lw	s9,12(a0)
    8000605a:	001c9c9b          	slliw	s9,s9,0x1
    8000605e:	1c82                	slli	s9,s9,0x20
    80006060:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006064:	0001f517          	auipc	a0,0x1f
    80006068:	0c450513          	addi	a0,a0,196 # 80025128 <disk+0x2128>
    8000606c:	ffffb097          	auipc	ra,0xffffb
    80006070:	b78080e7          	jalr	-1160(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006074:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006076:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006078:	0001db97          	auipc	s7,0x1d
    8000607c:	f88b8b93          	addi	s7,s7,-120 # 80023000 <disk>
    80006080:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006082:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006084:	8a4e                	mv	s4,s3
    80006086:	a051                	j	8000610a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006088:	00fb86b3          	add	a3,s7,a5
    8000608c:	96da                	add	a3,a3,s6
    8000608e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006092:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006094:	0207c563          	bltz	a5,800060be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006098:	2485                	addiw	s1,s1,1
    8000609a:	0711                	addi	a4,a4,4
    8000609c:	25548063          	beq	s1,s5,800062dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060a2:	0001f697          	auipc	a3,0x1f
    800060a6:	f7668693          	addi	a3,a3,-138 # 80025018 <disk+0x2018>
    800060aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060ac:	0006c583          	lbu	a1,0(a3)
    800060b0:	fde1                	bnez	a1,80006088 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060b2:	2785                	addiw	a5,a5,1
    800060b4:	0685                	addi	a3,a3,1
    800060b6:	ff879be3          	bne	a5,s8,800060ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060ba:	57fd                	li	a5,-1
    800060bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060be:	02905a63          	blez	s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060c2:	f9042503          	lw	a0,-112(s0)
    800060c6:	00000097          	auipc	ra,0x0
    800060ca:	d90080e7          	jalr	-624(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060ce:	4785                	li	a5,1
    800060d0:	0297d163          	bge	a5,s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060d4:	f9442503          	lw	a0,-108(s0)
    800060d8:	00000097          	auipc	ra,0x0
    800060dc:	d7e080e7          	jalr	-642(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060e0:	4789                	li	a5,2
    800060e2:	0097d863          	bge	a5,s1,800060f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060e6:	f9842503          	lw	a0,-104(s0)
    800060ea:	00000097          	auipc	ra,0x0
    800060ee:	d6c080e7          	jalr	-660(ra) # 80005e56 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060f2:	0001f597          	auipc	a1,0x1f
    800060f6:	03658593          	addi	a1,a1,54 # 80025128 <disk+0x2128>
    800060fa:	0001f517          	auipc	a0,0x1f
    800060fe:	f1e50513          	addi	a0,a0,-226 # 80025018 <disk+0x2018>
    80006102:	ffffc097          	auipc	ra,0xffffc
    80006106:	148080e7          	jalr	328(ra) # 8000224a <sleep>
  for(int i = 0; i < 3; i++){
    8000610a:	f9040713          	addi	a4,s0,-112
    8000610e:	84ce                	mv	s1,s3
    80006110:	bf41                	j	800060a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006112:	20058713          	addi	a4,a1,512
    80006116:	00471693          	slli	a3,a4,0x4
    8000611a:	0001d717          	auipc	a4,0x1d
    8000611e:	ee670713          	addi	a4,a4,-282 # 80023000 <disk>
    80006122:	9736                	add	a4,a4,a3
    80006124:	4685                	li	a3,1
    80006126:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000612a:	20058713          	addi	a4,a1,512
    8000612e:	00471693          	slli	a3,a4,0x4
    80006132:	0001d717          	auipc	a4,0x1d
    80006136:	ece70713          	addi	a4,a4,-306 # 80023000 <disk>
    8000613a:	9736                	add	a4,a4,a3
    8000613c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006140:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006144:	7679                	lui	a2,0xffffe
    80006146:	963e                	add	a2,a2,a5
    80006148:	0001f697          	auipc	a3,0x1f
    8000614c:	eb868693          	addi	a3,a3,-328 # 80025000 <disk+0x2000>
    80006150:	6298                	ld	a4,0(a3)
    80006152:	9732                	add	a4,a4,a2
    80006154:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006156:	6298                	ld	a4,0(a3)
    80006158:	9732                	add	a4,a4,a2
    8000615a:	4541                	li	a0,16
    8000615c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000615e:	6298                	ld	a4,0(a3)
    80006160:	9732                	add	a4,a4,a2
    80006162:	4505                	li	a0,1
    80006164:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006168:	f9442703          	lw	a4,-108(s0)
    8000616c:	6288                	ld	a0,0(a3)
    8000616e:	962a                	add	a2,a2,a0
    80006170:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006174:	0712                	slli	a4,a4,0x4
    80006176:	6290                	ld	a2,0(a3)
    80006178:	963a                	add	a2,a2,a4
    8000617a:	05890513          	addi	a0,s2,88
    8000617e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006180:	6294                	ld	a3,0(a3)
    80006182:	96ba                	add	a3,a3,a4
    80006184:	40000613          	li	a2,1024
    80006188:	c690                	sw	a2,8(a3)
  if(write)
    8000618a:	140d0063          	beqz	s10,800062ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000618e:	0001f697          	auipc	a3,0x1f
    80006192:	e726b683          	ld	a3,-398(a3) # 80025000 <disk+0x2000>
    80006196:	96ba                	add	a3,a3,a4
    80006198:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000619c:	0001d817          	auipc	a6,0x1d
    800061a0:	e6480813          	addi	a6,a6,-412 # 80023000 <disk>
    800061a4:	0001f517          	auipc	a0,0x1f
    800061a8:	e5c50513          	addi	a0,a0,-420 # 80025000 <disk+0x2000>
    800061ac:	6114                	ld	a3,0(a0)
    800061ae:	96ba                	add	a3,a3,a4
    800061b0:	00c6d603          	lhu	a2,12(a3)
    800061b4:	00166613          	ori	a2,a2,1
    800061b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061bc:	f9842683          	lw	a3,-104(s0)
    800061c0:	6110                	ld	a2,0(a0)
    800061c2:	9732                	add	a4,a4,a2
    800061c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061c8:	20058613          	addi	a2,a1,512
    800061cc:	0612                	slli	a2,a2,0x4
    800061ce:	9642                	add	a2,a2,a6
    800061d0:	577d                	li	a4,-1
    800061d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061d6:	00469713          	slli	a4,a3,0x4
    800061da:	6114                	ld	a3,0(a0)
    800061dc:	96ba                	add	a3,a3,a4
    800061de:	03078793          	addi	a5,a5,48
    800061e2:	97c2                	add	a5,a5,a6
    800061e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800061e6:	611c                	ld	a5,0(a0)
    800061e8:	97ba                	add	a5,a5,a4
    800061ea:	4685                	li	a3,1
    800061ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061ee:	611c                	ld	a5,0(a0)
    800061f0:	97ba                	add	a5,a5,a4
    800061f2:	4809                	li	a6,2
    800061f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061f8:	611c                	ld	a5,0(a0)
    800061fa:	973e                	add	a4,a4,a5
    800061fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006200:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006204:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006208:	6518                	ld	a4,8(a0)
    8000620a:	00275783          	lhu	a5,2(a4)
    8000620e:	8b9d                	andi	a5,a5,7
    80006210:	0786                	slli	a5,a5,0x1
    80006212:	97ba                	add	a5,a5,a4
    80006214:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006218:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000621c:	6518                	ld	a4,8(a0)
    8000621e:	00275783          	lhu	a5,2(a4)
    80006222:	2785                	addiw	a5,a5,1
    80006224:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006228:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000622c:	100017b7          	lui	a5,0x10001
    80006230:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006234:	00492703          	lw	a4,4(s2)
    80006238:	4785                	li	a5,1
    8000623a:	02f71163          	bne	a4,a5,8000625c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000623e:	0001f997          	auipc	s3,0x1f
    80006242:	eea98993          	addi	s3,s3,-278 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006246:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006248:	85ce                	mv	a1,s3
    8000624a:	854a                	mv	a0,s2
    8000624c:	ffffc097          	auipc	ra,0xffffc
    80006250:	ffe080e7          	jalr	-2(ra) # 8000224a <sleep>
  while(b->disk == 1) {
    80006254:	00492783          	lw	a5,4(s2)
    80006258:	fe9788e3          	beq	a5,s1,80006248 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000625c:	f9042903          	lw	s2,-112(s0)
    80006260:	20090793          	addi	a5,s2,512
    80006264:	00479713          	slli	a4,a5,0x4
    80006268:	0001d797          	auipc	a5,0x1d
    8000626c:	d9878793          	addi	a5,a5,-616 # 80023000 <disk>
    80006270:	97ba                	add	a5,a5,a4
    80006272:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006276:	0001f997          	auipc	s3,0x1f
    8000627a:	d8a98993          	addi	s3,s3,-630 # 80025000 <disk+0x2000>
    8000627e:	00491713          	slli	a4,s2,0x4
    80006282:	0009b783          	ld	a5,0(s3)
    80006286:	97ba                	add	a5,a5,a4
    80006288:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000628c:	854a                	mv	a0,s2
    8000628e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006292:	00000097          	auipc	ra,0x0
    80006296:	bc4080e7          	jalr	-1084(ra) # 80005e56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000629a:	8885                	andi	s1,s1,1
    8000629c:	f0ed                	bnez	s1,8000627e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000629e:	0001f517          	auipc	a0,0x1f
    800062a2:	e8a50513          	addi	a0,a0,-374 # 80025128 <disk+0x2128>
    800062a6:	ffffb097          	auipc	ra,0xffffb
    800062aa:	9f2080e7          	jalr	-1550(ra) # 80000c98 <release>
}
    800062ae:	70a6                	ld	ra,104(sp)
    800062b0:	7406                	ld	s0,96(sp)
    800062b2:	64e6                	ld	s1,88(sp)
    800062b4:	6946                	ld	s2,80(sp)
    800062b6:	69a6                	ld	s3,72(sp)
    800062b8:	6a06                	ld	s4,64(sp)
    800062ba:	7ae2                	ld	s5,56(sp)
    800062bc:	7b42                	ld	s6,48(sp)
    800062be:	7ba2                	ld	s7,40(sp)
    800062c0:	7c02                	ld	s8,32(sp)
    800062c2:	6ce2                	ld	s9,24(sp)
    800062c4:	6d42                	ld	s10,16(sp)
    800062c6:	6165                	addi	sp,sp,112
    800062c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062ca:	0001f697          	auipc	a3,0x1f
    800062ce:	d366b683          	ld	a3,-714(a3) # 80025000 <disk+0x2000>
    800062d2:	96ba                	add	a3,a3,a4
    800062d4:	4609                	li	a2,2
    800062d6:	00c69623          	sh	a2,12(a3)
    800062da:	b5c9                	j	8000619c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062dc:	f9042583          	lw	a1,-112(s0)
    800062e0:	20058793          	addi	a5,a1,512
    800062e4:	0792                	slli	a5,a5,0x4
    800062e6:	0001d517          	auipc	a0,0x1d
    800062ea:	dc250513          	addi	a0,a0,-574 # 800230a8 <disk+0xa8>
    800062ee:	953e                	add	a0,a0,a5
  if(write)
    800062f0:	e20d11e3          	bnez	s10,80006112 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062f4:	20058713          	addi	a4,a1,512
    800062f8:	00471693          	slli	a3,a4,0x4
    800062fc:	0001d717          	auipc	a4,0x1d
    80006300:	d0470713          	addi	a4,a4,-764 # 80023000 <disk>
    80006304:	9736                	add	a4,a4,a3
    80006306:	0a072423          	sw	zero,168(a4)
    8000630a:	b505                	j	8000612a <virtio_disk_rw+0xf4>

000000008000630c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000630c:	1101                	addi	sp,sp,-32
    8000630e:	ec06                	sd	ra,24(sp)
    80006310:	e822                	sd	s0,16(sp)
    80006312:	e426                	sd	s1,8(sp)
    80006314:	e04a                	sd	s2,0(sp)
    80006316:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006318:	0001f517          	auipc	a0,0x1f
    8000631c:	e1050513          	addi	a0,a0,-496 # 80025128 <disk+0x2128>
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	8c4080e7          	jalr	-1852(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006328:	10001737          	lui	a4,0x10001
    8000632c:	533c                	lw	a5,96(a4)
    8000632e:	8b8d                	andi	a5,a5,3
    80006330:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006332:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006336:	0001f797          	auipc	a5,0x1f
    8000633a:	cca78793          	addi	a5,a5,-822 # 80025000 <disk+0x2000>
    8000633e:	6b94                	ld	a3,16(a5)
    80006340:	0207d703          	lhu	a4,32(a5)
    80006344:	0026d783          	lhu	a5,2(a3)
    80006348:	06f70163          	beq	a4,a5,800063aa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000634c:	0001d917          	auipc	s2,0x1d
    80006350:	cb490913          	addi	s2,s2,-844 # 80023000 <disk>
    80006354:	0001f497          	auipc	s1,0x1f
    80006358:	cac48493          	addi	s1,s1,-852 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000635c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006360:	6898                	ld	a4,16(s1)
    80006362:	0204d783          	lhu	a5,32(s1)
    80006366:	8b9d                	andi	a5,a5,7
    80006368:	078e                	slli	a5,a5,0x3
    8000636a:	97ba                	add	a5,a5,a4
    8000636c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000636e:	20078713          	addi	a4,a5,512
    80006372:	0712                	slli	a4,a4,0x4
    80006374:	974a                	add	a4,a4,s2
    80006376:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000637a:	e731                	bnez	a4,800063c6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000637c:	20078793          	addi	a5,a5,512
    80006380:	0792                	slli	a5,a5,0x4
    80006382:	97ca                	add	a5,a5,s2
    80006384:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006386:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000638a:	ffffc097          	auipc	ra,0xffffc
    8000638e:	04c080e7          	jalr	76(ra) # 800023d6 <wakeup>

    disk.used_idx += 1;
    80006392:	0204d783          	lhu	a5,32(s1)
    80006396:	2785                	addiw	a5,a5,1
    80006398:	17c2                	slli	a5,a5,0x30
    8000639a:	93c1                	srli	a5,a5,0x30
    8000639c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063a0:	6898                	ld	a4,16(s1)
    800063a2:	00275703          	lhu	a4,2(a4)
    800063a6:	faf71be3          	bne	a4,a5,8000635c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063aa:	0001f517          	auipc	a0,0x1f
    800063ae:	d7e50513          	addi	a0,a0,-642 # 80025128 <disk+0x2128>
    800063b2:	ffffb097          	auipc	ra,0xffffb
    800063b6:	8e6080e7          	jalr	-1818(ra) # 80000c98 <release>
}
    800063ba:	60e2                	ld	ra,24(sp)
    800063bc:	6442                	ld	s0,16(sp)
    800063be:	64a2                	ld	s1,8(sp)
    800063c0:	6902                	ld	s2,0(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret
      panic("virtio_disk_intr status");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	48250513          	addi	a0,a0,1154 # 80008848 <syscalls+0x3c0>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	170080e7          	jalr	368(ra) # 8000053e <panic>
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
