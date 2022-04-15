
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
    80000068:	d6c78793          	addi	a5,a5,-660 # 80005dd0 <timervec>
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
    80000130:	5a6080e7          	jalr	1446(ra) # 800026d2 <either_copyin>
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
    800001d8:	fbc080e7          	jalr	-68(ra) # 80002190 <sleep>
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
    80000214:	46c080e7          	jalr	1132(ra) # 8000267c <either_copyout>
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
    800002f6:	436080e7          	jalr	1078(ra) # 80002728 <procdump>
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
    8000044a:	fd4080e7          	jalr	-44(ra) # 8000241a <wakeup>
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
    800008a4:	b7a080e7          	jalr	-1158(ra) # 8000241a <wakeup>
    
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
    80000930:	864080e7          	jalr	-1948(ra) # 80002190 <sleep>
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
    80000efa:	2fe080e7          	jalr	766(ra) # 800021f4 <pause_system>
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
    80000f8a:	6ac080e7          	jalr	1708(ra) # 80002632 <kill_system>
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
    80000ffc:	870080e7          	jalr	-1936(ra) # 80002868 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001000:	00005097          	auipc	ra,0x5
    80001004:	e10080e7          	jalr	-496(ra) # 80005e10 <plicinithart>
  }

  scheduler();    
    80001008:	00001097          	auipc	ra,0x1
    8000100c:	fd6080e7          	jalr	-42(ra) # 80001fde <scheduler>
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
    80001074:	7d0080e7          	jalr	2000(ra) # 80002840 <trapinit>
    trapinithart();  // install kernel trap vector
    80001078:	00001097          	auipc	ra,0x1
    8000107c:	7f0080e7          	jalr	2032(ra) # 80002868 <trapinithart>
    plicinit();      // set up interrupt controller
    80001080:	00005097          	auipc	ra,0x5
    80001084:	d7a080e7          	jalr	-646(ra) # 80005dfa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001088:	00005097          	auipc	ra,0x5
    8000108c:	d88080e7          	jalr	-632(ra) # 80005e10 <plicinithart>
    binit();         // buffer cache
    80001090:	00002097          	auipc	ra,0x2
    80001094:	f64080e7          	jalr	-156(ra) # 80002ff4 <binit>
    iinit();         // inode table
    80001098:	00002097          	auipc	ra,0x2
    8000109c:	5f4080e7          	jalr	1524(ra) # 8000368c <iinit>
    fileinit();      // file table
    800010a0:	00003097          	auipc	ra,0x3
    800010a4:	59e080e7          	jalr	1438(ra) # 8000463e <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010a8:	00005097          	auipc	ra,0x5
    800010ac:	e8a080e7          	jalr	-374(ra) # 80005f32 <virtio_disk_init>
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
    80001b28:	d3c7a783          	lw	a5,-708(a5) # 80008860 <first.1696>
    80001b2c:	eb89                	bnez	a5,80001b3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b2e:	00001097          	auipc	ra,0x1
    80001b32:	d52080e7          	jalr	-686(ra) # 80002880 <usertrapret>
}
    80001b36:	60a2                	ld	ra,8(sp)
    80001b38:	6402                	ld	s0,0(sp)
    80001b3a:	0141                	addi	sp,sp,16
    80001b3c:	8082                	ret
    first = 0;
    80001b3e:	00007797          	auipc	a5,0x7
    80001b42:	d207a123          	sw	zero,-734(a5) # 80008860 <first.1696>
    fsinit(ROOTDEV);
    80001b46:	4505                	li	a0,1
    80001b48:	00002097          	auipc	ra,0x2
    80001b4c:	ac4080e7          	jalr	-1340(ra) # 8000360c <fsinit>
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
    80001dc4:	26a7b423          	sd	a0,616(a5) # 80009028 <initproc>
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
    80001e0e:	230080e7          	jalr	560(ra) # 8000403a <namei>
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
    80001f44:	790080e7          	jalr	1936(ra) # 800046d0 <filedup>
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
    80001f66:	8e4080e7          	jalr	-1820(ra) # 80003846 <idup>
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

0000000080001fde <scheduler>:
{
    80001fde:	7139                	addi	sp,sp,-64
    80001fe0:	fc06                	sd	ra,56(sp)
    80001fe2:	f822                	sd	s0,48(sp)
    80001fe4:	f426                	sd	s1,40(sp)
    80001fe6:	f04a                	sd	s2,32(sp)
    80001fe8:	ec4e                	sd	s3,24(sp)
    80001fea:	e852                	sd	s4,16(sp)
    80001fec:	e456                	sd	s5,8(sp)
    80001fee:	e05a                	sd	s6,0(sp)
    80001ff0:	0080                	addi	s0,sp,64
    80001ff2:	8792                	mv	a5,tp
  int id = r_tp();
    80001ff4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ff6:	00779a93          	slli	s5,a5,0x7
    80001ffa:	0000f717          	auipc	a4,0xf
    80001ffe:	2a670713          	addi	a4,a4,678 # 800112a0 <pid_lock>
    80002002:	9756                	add	a4,a4,s5
    80002004:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002008:	0000f717          	auipc	a4,0xf
    8000200c:	2d070713          	addi	a4,a4,720 # 800112d8 <cpus+0x8>
    80002010:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002012:	498d                	li	s3,3
        p->state = RUNNING;
    80002014:	4b11                	li	s6,4
        c->proc = p;
    80002016:	079e                	slli	a5,a5,0x7
    80002018:	0000fa17          	auipc	s4,0xf
    8000201c:	288a0a13          	addi	s4,s4,648 # 800112a0 <pid_lock>
    80002020:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002022:	00015917          	auipc	s2,0x15
    80002026:	0ae90913          	addi	s2,s2,174 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000202e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002032:	10079073          	csrw	sstatus,a5
    80002036:	0000f497          	auipc	s1,0xf
    8000203a:	69a48493          	addi	s1,s1,1690 # 800116d0 <proc>
    8000203e:	a03d                	j	8000206c <scheduler+0x8e>
        p->state = RUNNING;
    80002040:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002044:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002048:	06048593          	addi	a1,s1,96
    8000204c:	8556                	mv	a0,s5
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	788080e7          	jalr	1928(ra) # 800027d6 <swtch>
        c->proc = 0;
    80002056:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    8000205a:	8526                	mv	a0,s1
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	c3c080e7          	jalr	-964(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002064:	16848493          	addi	s1,s1,360
    80002068:	fd2481e3          	beq	s1,s2,8000202a <scheduler+0x4c>
      acquire(&p->lock);
    8000206c:	8526                	mv	a0,s1
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	b76080e7          	jalr	-1162(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002076:	4c9c                	lw	a5,24(s1)
    80002078:	ff3791e3          	bne	a5,s3,8000205a <scheduler+0x7c>
    8000207c:	b7d1                	j	80002040 <scheduler+0x62>

000000008000207e <sched>:
{
    8000207e:	7179                	addi	sp,sp,-48
    80002080:	f406                	sd	ra,40(sp)
    80002082:	f022                	sd	s0,32(sp)
    80002084:	ec26                	sd	s1,24(sp)
    80002086:	e84a                	sd	s2,16(sp)
    80002088:	e44e                	sd	s3,8(sp)
    8000208a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000208c:	00000097          	auipc	ra,0x0
    80002090:	a48080e7          	jalr	-1464(ra) # 80001ad4 <myproc>
    80002094:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	ad4080e7          	jalr	-1324(ra) # 80000b6a <holding>
    8000209e:	c93d                	beqz	a0,80002114 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020a0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020a2:	2781                	sext.w	a5,a5
    800020a4:	079e                	slli	a5,a5,0x7
    800020a6:	0000f717          	auipc	a4,0xf
    800020aa:	1fa70713          	addi	a4,a4,506 # 800112a0 <pid_lock>
    800020ae:	97ba                	add	a5,a5,a4
    800020b0:	0a87a703          	lw	a4,168(a5)
    800020b4:	4785                	li	a5,1
    800020b6:	06f71763          	bne	a4,a5,80002124 <sched+0xa6>
  if(p->state == RUNNING)
    800020ba:	4c98                	lw	a4,24(s1)
    800020bc:	4791                	li	a5,4
    800020be:	06f70b63          	beq	a4,a5,80002134 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020c2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020c6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020c8:	efb5                	bnez	a5,80002144 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ca:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020cc:	0000f917          	auipc	s2,0xf
    800020d0:	1d490913          	addi	s2,s2,468 # 800112a0 <pid_lock>
    800020d4:	2781                	sext.w	a5,a5
    800020d6:	079e                	slli	a5,a5,0x7
    800020d8:	97ca                	add	a5,a5,s2
    800020da:	0ac7a983          	lw	s3,172(a5)
    800020de:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020e0:	2781                	sext.w	a5,a5
    800020e2:	079e                	slli	a5,a5,0x7
    800020e4:	0000f597          	auipc	a1,0xf
    800020e8:	1f458593          	addi	a1,a1,500 # 800112d8 <cpus+0x8>
    800020ec:	95be                	add	a1,a1,a5
    800020ee:	06048513          	addi	a0,s1,96
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	6e4080e7          	jalr	1764(ra) # 800027d6 <swtch>
    800020fa:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020fc:	2781                	sext.w	a5,a5
    800020fe:	079e                	slli	a5,a5,0x7
    80002100:	97ca                	add	a5,a5,s2
    80002102:	0b37a623          	sw	s3,172(a5)
}
    80002106:	70a2                	ld	ra,40(sp)
    80002108:	7402                	ld	s0,32(sp)
    8000210a:	64e2                	ld	s1,24(sp)
    8000210c:	6942                	ld	s2,16(sp)
    8000210e:	69a2                	ld	s3,8(sp)
    80002110:	6145                	addi	sp,sp,48
    80002112:	8082                	ret
    panic("sched p->lock");
    80002114:	00006517          	auipc	a0,0x6
    80002118:	14450513          	addi	a0,a0,324 # 80008258 <digits+0x218>
    8000211c:	ffffe097          	auipc	ra,0xffffe
    80002120:	422080e7          	jalr	1058(ra) # 8000053e <panic>
    panic("sched locks");
    80002124:	00006517          	auipc	a0,0x6
    80002128:	14450513          	addi	a0,a0,324 # 80008268 <digits+0x228>
    8000212c:	ffffe097          	auipc	ra,0xffffe
    80002130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("sched running");
    80002134:	00006517          	auipc	a0,0x6
    80002138:	14450513          	addi	a0,a0,324 # 80008278 <digits+0x238>
    8000213c:	ffffe097          	auipc	ra,0xffffe
    80002140:	402080e7          	jalr	1026(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002144:	00006517          	auipc	a0,0x6
    80002148:	14450513          	addi	a0,a0,324 # 80008288 <digits+0x248>
    8000214c:	ffffe097          	auipc	ra,0xffffe
    80002150:	3f2080e7          	jalr	1010(ra) # 8000053e <panic>

0000000080002154 <yield>:
{
    80002154:	1101                	addi	sp,sp,-32
    80002156:	ec06                	sd	ra,24(sp)
    80002158:	e822                	sd	s0,16(sp)
    8000215a:	e426                	sd	s1,8(sp)
    8000215c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	976080e7          	jalr	-1674(ra) # 80001ad4 <myproc>
    80002166:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	a7c080e7          	jalr	-1412(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002170:	478d                	li	a5,3
    80002172:	cc9c                	sw	a5,24(s1)
  sched();
    80002174:	00000097          	auipc	ra,0x0
    80002178:	f0a080e7          	jalr	-246(ra) # 8000207e <sched>
  release(&p->lock);
    8000217c:	8526                	mv	a0,s1
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	b1a080e7          	jalr	-1254(ra) # 80000c98 <release>
}
    80002186:	60e2                	ld	ra,24(sp)
    80002188:	6442                	ld	s0,16(sp)
    8000218a:	64a2                	ld	s1,8(sp)
    8000218c:	6105                	addi	sp,sp,32
    8000218e:	8082                	ret

0000000080002190 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002190:	7179                	addi	sp,sp,-48
    80002192:	f406                	sd	ra,40(sp)
    80002194:	f022                	sd	s0,32(sp)
    80002196:	ec26                	sd	s1,24(sp)
    80002198:	e84a                	sd	s2,16(sp)
    8000219a:	e44e                	sd	s3,8(sp)
    8000219c:	1800                	addi	s0,sp,48
    8000219e:	89aa                	mv	s3,a0
    800021a0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021a2:	00000097          	auipc	ra,0x0
    800021a6:	932080e7          	jalr	-1742(ra) # 80001ad4 <myproc>
    800021aa:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	a38080e7          	jalr	-1480(ra) # 80000be4 <acquire>
  release(lk);
    800021b4:	854a                	mv	a0,s2
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	ae2080e7          	jalr	-1310(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800021be:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021c2:	4789                	li	a5,2
    800021c4:	cc9c                	sw	a5,24(s1)

  sched();
    800021c6:	00000097          	auipc	ra,0x0
    800021ca:	eb8080e7          	jalr	-328(ra) # 8000207e <sched>

  // Tidy up.
  p->chan = 0;
    800021ce:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021d2:	8526                	mv	a0,s1
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	ac4080e7          	jalr	-1340(ra) # 80000c98 <release>
  acquire(lk);
    800021dc:	854a                	mv	a0,s2
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	a06080e7          	jalr	-1530(ra) # 80000be4 <acquire>
}
    800021e6:	70a2                	ld	ra,40(sp)
    800021e8:	7402                	ld	s0,32(sp)
    800021ea:	64e2                	ld	s1,24(sp)
    800021ec:	6942                	ld	s2,16(sp)
    800021ee:	69a2                	ld	s3,8(sp)
    800021f0:	6145                	addi	sp,sp,48
    800021f2:	8082                	ret

00000000800021f4 <pause_system>:
pause_system(int seconds){
    800021f4:	7149                	addi	sp,sp,-368
    800021f6:	f686                	sd	ra,360(sp)
    800021f8:	f2a2                	sd	s0,352(sp)
    800021fa:	eea6                	sd	s1,344(sp)
    800021fc:	eaca                	sd	s2,336(sp)
    800021fe:	e6ce                	sd	s3,328(sp)
    80002200:	e2d2                	sd	s4,320(sp)
    80002202:	fe56                	sd	s5,312(sp)
    80002204:	fa5a                	sd	s6,304(sp)
    80002206:	f65e                	sd	s7,296(sp)
    80002208:	f262                	sd	s8,288(sp)
    8000220a:	ee66                	sd	s9,280(sp)
    8000220c:	1a80                	addi	s0,sp,368
  uint ticks0 = seconds * 10; // * 1,000,000?
    8000220e:	0025179b          	slliw	a5,a0,0x2
    80002212:	9fa9                	addw	a5,a5,a0
    80002214:	0017979b          	slliw	a5,a5,0x1
    80002218:	e8f42e23          	sw	a5,-356(s0)
  if(seconds < 0)
    8000221c:	0c054963          	bltz	a0,800022ee <pause_system+0xfa>
    80002220:	0000f917          	auipc	s2,0xf
    80002224:	4b090913          	addi	s2,s2,1200 # 800116d0 <proc>
    80002228:	ea040993          	addi	s3,s0,-352
    8000222c:	00015b17          	auipc	s6,0x15
    80002230:	ea4b0b13          	addi	s6,s6,-348 # 800170d0 <tickslock>
    80002234:	8a4e                	mv	s4,s3
    80002236:	84ca                	mv	s1,s2
    if(proc[i].state == RUNNING && proc[i].pid > 2)
    80002238:	4b91                	li	s7,4
    8000223a:	4c09                	li	s8,2
      proc[i].state = RUNNABLE;
    8000223c:	4c8d                	li	s9,3
    8000223e:	a819                	j	80002254 <pause_system+0x60>
    release(&proc[i].lock);
    80002240:	8556                	mv	a0,s5
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
  for (int i = 0; i < NPROC; i++)
    8000224a:	16848493          	addi	s1,s1,360
    8000224e:	0a11                	addi	s4,s4,4
    80002250:	03648463          	beq	s1,s6,80002278 <pause_system+0x84>
    prevState[i] = proc[i].state;
    80002254:	8aa6                	mv	s5,s1
    80002256:	4c9c                	lw	a5,24(s1)
    80002258:	00fa2023          	sw	a5,0(s4)
    acquire(&proc[i].lock);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	986080e7          	jalr	-1658(ra) # 80000be4 <acquire>
    if(proc[i].state == RUNNING && proc[i].pid > 2)
    80002266:	4c9c                	lw	a5,24(s1)
    80002268:	fd779ce3          	bne	a5,s7,80002240 <pause_system+0x4c>
    8000226c:	589c                	lw	a5,48(s1)
    8000226e:	fcfc59e3          	bge	s8,a5,80002240 <pause_system+0x4c>
      proc[i].state = RUNNABLE;
    80002272:	0194ac23          	sw	s9,24(s1)
    80002276:	b7e9                	j	80002240 <pause_system+0x4c>
  acquire(&tickslock);
    80002278:	00015517          	auipc	a0,0x15
    8000227c:	e5850513          	addi	a0,a0,-424 # 800170d0 <tickslock>
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	964080e7          	jalr	-1692(ra) # 80000be4 <acquire>
  sleep(&ticks0, &tickslock);
    80002288:	00015597          	auipc	a1,0x15
    8000228c:	e4858593          	addi	a1,a1,-440 # 800170d0 <tickslock>
    80002290:	e9c40513          	addi	a0,s0,-356
    80002294:	00000097          	auipc	ra,0x0
    80002298:	efc080e7          	jalr	-260(ra) # 80002190 <sleep>
  release(&tickslock);
    8000229c:	00015517          	auipc	a0,0x15
    800022a0:	e3450513          	addi	a0,a0,-460 # 800170d0 <tickslock>
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	9f4080e7          	jalr	-1548(ra) # 80000c98 <release>
    acquire(&proc[i].lock);
    800022ac:	854a                	mv	a0,s2
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	936080e7          	jalr	-1738(ra) # 80000be4 <acquire>
    proc[i].state = prevState[i];
    800022b6:	0009a783          	lw	a5,0(s3)
    800022ba:	00f92c23          	sw	a5,24(s2)
    release(&proc[i].lock);
    800022be:	854a                	mv	a0,s2
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	9d8080e7          	jalr	-1576(ra) # 80000c98 <release>
  for (int i = 0; i < NPROC; i++){
    800022c8:	16890913          	addi	s2,s2,360
    800022cc:	0991                	addi	s3,s3,4
    800022ce:	fd691fe3          	bne	s2,s6,800022ac <pause_system+0xb8>
  return 0;
    800022d2:	4501                	li	a0,0
}
    800022d4:	70b6                	ld	ra,360(sp)
    800022d6:	7416                	ld	s0,352(sp)
    800022d8:	64f6                	ld	s1,344(sp)
    800022da:	6956                	ld	s2,336(sp)
    800022dc:	69b6                	ld	s3,328(sp)
    800022de:	6a16                	ld	s4,320(sp)
    800022e0:	7af2                	ld	s5,312(sp)
    800022e2:	7b52                	ld	s6,304(sp)
    800022e4:	7bb2                	ld	s7,296(sp)
    800022e6:	7c12                	ld	s8,288(sp)
    800022e8:	6cf2                	ld	s9,280(sp)
    800022ea:	6175                	addi	sp,sp,368
    800022ec:	8082                	ret
    return -1;
    800022ee:	557d                	li	a0,-1
    800022f0:	b7d5                	j	800022d4 <pause_system+0xe0>

00000000800022f2 <wait>:
{
    800022f2:	715d                	addi	sp,sp,-80
    800022f4:	e486                	sd	ra,72(sp)
    800022f6:	e0a2                	sd	s0,64(sp)
    800022f8:	fc26                	sd	s1,56(sp)
    800022fa:	f84a                	sd	s2,48(sp)
    800022fc:	f44e                	sd	s3,40(sp)
    800022fe:	f052                	sd	s4,32(sp)
    80002300:	ec56                	sd	s5,24(sp)
    80002302:	e85a                	sd	s6,16(sp)
    80002304:	e45e                	sd	s7,8(sp)
    80002306:	e062                	sd	s8,0(sp)
    80002308:	0880                	addi	s0,sp,80
    8000230a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	7c8080e7          	jalr	1992(ra) # 80001ad4 <myproc>
    80002314:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002316:	0000f517          	auipc	a0,0xf
    8000231a:	fa250513          	addi	a0,a0,-94 # 800112b8 <wait_lock>
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	8c6080e7          	jalr	-1850(ra) # 80000be4 <acquire>
    havekids = 0;
    80002326:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002328:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000232a:	00015997          	auipc	s3,0x15
    8000232e:	da698993          	addi	s3,s3,-602 # 800170d0 <tickslock>
        havekids = 1;
    80002332:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002334:	0000fc17          	auipc	s8,0xf
    80002338:	f84c0c13          	addi	s8,s8,-124 # 800112b8 <wait_lock>
    havekids = 0;
    8000233c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000233e:	0000f497          	auipc	s1,0xf
    80002342:	39248493          	addi	s1,s1,914 # 800116d0 <proc>
    80002346:	a0bd                	j	800023b4 <wait+0xc2>
          pid = np->pid;
    80002348:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000234c:	000b0e63          	beqz	s6,80002368 <wait+0x76>
    80002350:	4691                	li	a3,4
    80002352:	02c48613          	addi	a2,s1,44
    80002356:	85da                	mv	a1,s6
    80002358:	05093503          	ld	a0,80(s2)
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	43a080e7          	jalr	1082(ra) # 80001796 <copyout>
    80002364:	02054563          	bltz	a0,8000238e <wait+0x9c>
          freeproc(np);
    80002368:	8526                	mv	a0,s1
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	91c080e7          	jalr	-1764(ra) # 80001c86 <freeproc>
          release(&np->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
          release(&wait_lock);
    8000237c:	0000f517          	auipc	a0,0xf
    80002380:	f3c50513          	addi	a0,a0,-196 # 800112b8 <wait_lock>
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	914080e7          	jalr	-1772(ra) # 80000c98 <release>
          return pid;
    8000238c:	a09d                	j	800023f2 <wait+0x100>
            release(&np->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	908080e7          	jalr	-1784(ra) # 80000c98 <release>
            release(&wait_lock);
    80002398:	0000f517          	auipc	a0,0xf
    8000239c:	f2050513          	addi	a0,a0,-224 # 800112b8 <wait_lock>
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8f8080e7          	jalr	-1800(ra) # 80000c98 <release>
            return -1;
    800023a8:	59fd                	li	s3,-1
    800023aa:	a0a1                	j	800023f2 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800023ac:	16848493          	addi	s1,s1,360
    800023b0:	03348463          	beq	s1,s3,800023d8 <wait+0xe6>
      if(np->parent == p){
    800023b4:	7c9c                	ld	a5,56(s1)
    800023b6:	ff279be3          	bne	a5,s2,800023ac <wait+0xba>
        acquire(&np->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	828080e7          	jalr	-2008(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800023c4:	4c9c                	lw	a5,24(s1)
    800023c6:	f94781e3          	beq	a5,s4,80002348 <wait+0x56>
        release(&np->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8cc080e7          	jalr	-1844(ra) # 80000c98 <release>
        havekids = 1;
    800023d4:	8756                	mv	a4,s5
    800023d6:	bfd9                	j	800023ac <wait+0xba>
    if(!havekids || p->killed){
    800023d8:	c701                	beqz	a4,800023e0 <wait+0xee>
    800023da:	02892783          	lw	a5,40(s2)
    800023de:	c79d                	beqz	a5,8000240c <wait+0x11a>
      release(&wait_lock);
    800023e0:	0000f517          	auipc	a0,0xf
    800023e4:	ed850513          	addi	a0,a0,-296 # 800112b8 <wait_lock>
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	8b0080e7          	jalr	-1872(ra) # 80000c98 <release>
      return -1;
    800023f0:	59fd                	li	s3,-1
}
    800023f2:	854e                	mv	a0,s3
    800023f4:	60a6                	ld	ra,72(sp)
    800023f6:	6406                	ld	s0,64(sp)
    800023f8:	74e2                	ld	s1,56(sp)
    800023fa:	7942                	ld	s2,48(sp)
    800023fc:	79a2                	ld	s3,40(sp)
    800023fe:	7a02                	ld	s4,32(sp)
    80002400:	6ae2                	ld	s5,24(sp)
    80002402:	6b42                	ld	s6,16(sp)
    80002404:	6ba2                	ld	s7,8(sp)
    80002406:	6c02                	ld	s8,0(sp)
    80002408:	6161                	addi	sp,sp,80
    8000240a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000240c:	85e2                	mv	a1,s8
    8000240e:	854a                	mv	a0,s2
    80002410:	00000097          	auipc	ra,0x0
    80002414:	d80080e7          	jalr	-640(ra) # 80002190 <sleep>
    havekids = 0;
    80002418:	b715                	j	8000233c <wait+0x4a>

000000008000241a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000241a:	7139                	addi	sp,sp,-64
    8000241c:	fc06                	sd	ra,56(sp)
    8000241e:	f822                	sd	s0,48(sp)
    80002420:	f426                	sd	s1,40(sp)
    80002422:	f04a                	sd	s2,32(sp)
    80002424:	ec4e                	sd	s3,24(sp)
    80002426:	e852                	sd	s4,16(sp)
    80002428:	e456                	sd	s5,8(sp)
    8000242a:	0080                	addi	s0,sp,64
    8000242c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000242e:	0000f497          	auipc	s1,0xf
    80002432:	2a248493          	addi	s1,s1,674 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002436:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002438:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000243a:	00015917          	auipc	s2,0x15
    8000243e:	c9690913          	addi	s2,s2,-874 # 800170d0 <tickslock>
    80002442:	a821                	j	8000245a <wakeup+0x40>
        p->state = RUNNABLE;
    80002444:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002448:	8526                	mv	a0,s1
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	84e080e7          	jalr	-1970(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002452:	16848493          	addi	s1,s1,360
    80002456:	03248463          	beq	s1,s2,8000247e <wakeup+0x64>
    if(p != myproc()){
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	67a080e7          	jalr	1658(ra) # 80001ad4 <myproc>
    80002462:	fea488e3          	beq	s1,a0,80002452 <wakeup+0x38>
      acquire(&p->lock);
    80002466:	8526                	mv	a0,s1
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	77c080e7          	jalr	1916(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002470:	4c9c                	lw	a5,24(s1)
    80002472:	fd379be3          	bne	a5,s3,80002448 <wakeup+0x2e>
    80002476:	709c                	ld	a5,32(s1)
    80002478:	fd4798e3          	bne	a5,s4,80002448 <wakeup+0x2e>
    8000247c:	b7e1                	j	80002444 <wakeup+0x2a>
    }
  }
}
    8000247e:	70e2                	ld	ra,56(sp)
    80002480:	7442                	ld	s0,48(sp)
    80002482:	74a2                	ld	s1,40(sp)
    80002484:	7902                	ld	s2,32(sp)
    80002486:	69e2                	ld	s3,24(sp)
    80002488:	6a42                	ld	s4,16(sp)
    8000248a:	6aa2                	ld	s5,8(sp)
    8000248c:	6121                	addi	sp,sp,64
    8000248e:	8082                	ret

0000000080002490 <reparent>:
{
    80002490:	7179                	addi	sp,sp,-48
    80002492:	f406                	sd	ra,40(sp)
    80002494:	f022                	sd	s0,32(sp)
    80002496:	ec26                	sd	s1,24(sp)
    80002498:	e84a                	sd	s2,16(sp)
    8000249a:	e44e                	sd	s3,8(sp)
    8000249c:	e052                	sd	s4,0(sp)
    8000249e:	1800                	addi	s0,sp,48
    800024a0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024a2:	0000f497          	auipc	s1,0xf
    800024a6:	22e48493          	addi	s1,s1,558 # 800116d0 <proc>
      pp->parent = initproc;
    800024aa:	00007a17          	auipc	s4,0x7
    800024ae:	b7ea0a13          	addi	s4,s4,-1154 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024b2:	00015997          	auipc	s3,0x15
    800024b6:	c1e98993          	addi	s3,s3,-994 # 800170d0 <tickslock>
    800024ba:	a029                	j	800024c4 <reparent+0x34>
    800024bc:	16848493          	addi	s1,s1,360
    800024c0:	01348d63          	beq	s1,s3,800024da <reparent+0x4a>
    if(pp->parent == p){
    800024c4:	7c9c                	ld	a5,56(s1)
    800024c6:	ff279be3          	bne	a5,s2,800024bc <reparent+0x2c>
      pp->parent = initproc;
    800024ca:	000a3503          	ld	a0,0(s4)
    800024ce:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024d0:	00000097          	auipc	ra,0x0
    800024d4:	f4a080e7          	jalr	-182(ra) # 8000241a <wakeup>
    800024d8:	b7d5                	j	800024bc <reparent+0x2c>
}
    800024da:	70a2                	ld	ra,40(sp)
    800024dc:	7402                	ld	s0,32(sp)
    800024de:	64e2                	ld	s1,24(sp)
    800024e0:	6942                	ld	s2,16(sp)
    800024e2:	69a2                	ld	s3,8(sp)
    800024e4:	6a02                	ld	s4,0(sp)
    800024e6:	6145                	addi	sp,sp,48
    800024e8:	8082                	ret

00000000800024ea <exit>:
{
    800024ea:	7179                	addi	sp,sp,-48
    800024ec:	f406                	sd	ra,40(sp)
    800024ee:	f022                	sd	s0,32(sp)
    800024f0:	ec26                	sd	s1,24(sp)
    800024f2:	e84a                	sd	s2,16(sp)
    800024f4:	e44e                	sd	s3,8(sp)
    800024f6:	e052                	sd	s4,0(sp)
    800024f8:	1800                	addi	s0,sp,48
    800024fa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	5d8080e7          	jalr	1496(ra) # 80001ad4 <myproc>
    80002504:	89aa                	mv	s3,a0
  if(p == initproc)
    80002506:	00007797          	auipc	a5,0x7
    8000250a:	b227b783          	ld	a5,-1246(a5) # 80009028 <initproc>
    8000250e:	0d050493          	addi	s1,a0,208
    80002512:	15050913          	addi	s2,a0,336
    80002516:	02a79363          	bne	a5,a0,8000253c <exit+0x52>
    panic("init exiting");
    8000251a:	00006517          	auipc	a0,0x6
    8000251e:	d8650513          	addi	a0,a0,-634 # 800082a0 <digits+0x260>
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	01c080e7          	jalr	28(ra) # 8000053e <panic>
      fileclose(f);
    8000252a:	00002097          	auipc	ra,0x2
    8000252e:	1f8080e7          	jalr	504(ra) # 80004722 <fileclose>
      p->ofile[fd] = 0;
    80002532:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002536:	04a1                	addi	s1,s1,8
    80002538:	01248563          	beq	s1,s2,80002542 <exit+0x58>
    if(p->ofile[fd]){
    8000253c:	6088                	ld	a0,0(s1)
    8000253e:	f575                	bnez	a0,8000252a <exit+0x40>
    80002540:	bfdd                	j	80002536 <exit+0x4c>
  begin_op();
    80002542:	00002097          	auipc	ra,0x2
    80002546:	d14080e7          	jalr	-748(ra) # 80004256 <begin_op>
  iput(p->cwd);
    8000254a:	1509b503          	ld	a0,336(s3)
    8000254e:	00001097          	auipc	ra,0x1
    80002552:	4f0080e7          	jalr	1264(ra) # 80003a3e <iput>
  end_op();
    80002556:	00002097          	auipc	ra,0x2
    8000255a:	d80080e7          	jalr	-640(ra) # 800042d6 <end_op>
  p->cwd = 0;
    8000255e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002562:	0000f497          	auipc	s1,0xf
    80002566:	d5648493          	addi	s1,s1,-682 # 800112b8 <wait_lock>
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	678080e7          	jalr	1656(ra) # 80000be4 <acquire>
  reparent(p);
    80002574:	854e                	mv	a0,s3
    80002576:	00000097          	auipc	ra,0x0
    8000257a:	f1a080e7          	jalr	-230(ra) # 80002490 <reparent>
  wakeup(p->parent);
    8000257e:	0389b503          	ld	a0,56(s3)
    80002582:	00000097          	auipc	ra,0x0
    80002586:	e98080e7          	jalr	-360(ra) # 8000241a <wakeup>
  acquire(&p->lock);
    8000258a:	854e                	mv	a0,s3
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	658080e7          	jalr	1624(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002594:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002598:	4795                	li	a5,5
    8000259a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000259e:	8526                	mv	a0,s1
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	6f8080e7          	jalr	1784(ra) # 80000c98 <release>
  sched();
    800025a8:	00000097          	auipc	ra,0x0
    800025ac:	ad6080e7          	jalr	-1322(ra) # 8000207e <sched>
  panic("zombie exit");
    800025b0:	00006517          	auipc	a0,0x6
    800025b4:	d0050513          	addi	a0,a0,-768 # 800082b0 <digits+0x270>
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	f86080e7          	jalr	-122(ra) # 8000053e <panic>

00000000800025c0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025c0:	7179                	addi	sp,sp,-48
    800025c2:	f406                	sd	ra,40(sp)
    800025c4:	f022                	sd	s0,32(sp)
    800025c6:	ec26                	sd	s1,24(sp)
    800025c8:	e84a                	sd	s2,16(sp)
    800025ca:	e44e                	sd	s3,8(sp)
    800025cc:	1800                	addi	s0,sp,48
    800025ce:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025d0:	0000f497          	auipc	s1,0xf
    800025d4:	10048493          	addi	s1,s1,256 # 800116d0 <proc>
    800025d8:	00015997          	auipc	s3,0x15
    800025dc:	af898993          	addi	s3,s3,-1288 # 800170d0 <tickslock>
    acquire(&p->lock);
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	602080e7          	jalr	1538(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025ea:	589c                	lw	a5,48(s1)
    800025ec:	01278d63          	beq	a5,s2,80002606 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	6a6080e7          	jalr	1702(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025fa:	16848493          	addi	s1,s1,360
    800025fe:	ff3491e3          	bne	s1,s3,800025e0 <kill+0x20>
  }
  return -1;
    80002602:	557d                	li	a0,-1
    80002604:	a829                	j	8000261e <kill+0x5e>
      p->killed = 1;
    80002606:	4785                	li	a5,1
    80002608:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000260a:	4c98                	lw	a4,24(s1)
    8000260c:	4789                	li	a5,2
    8000260e:	00f70f63          	beq	a4,a5,8000262c <kill+0x6c>
      release(&p->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	684080e7          	jalr	1668(ra) # 80000c98 <release>
      return 0;
    8000261c:	4501                	li	a0,0
}
    8000261e:	70a2                	ld	ra,40(sp)
    80002620:	7402                	ld	s0,32(sp)
    80002622:	64e2                	ld	s1,24(sp)
    80002624:	6942                	ld	s2,16(sp)
    80002626:	69a2                	ld	s3,8(sp)
    80002628:	6145                	addi	sp,sp,48
    8000262a:	8082                	ret
        p->state = RUNNABLE;
    8000262c:	478d                	li	a5,3
    8000262e:	cc9c                	sw	a5,24(s1)
    80002630:	b7cd                	j	80002612 <kill+0x52>

0000000080002632 <kill_system>:
kill_system(void){
    80002632:	7179                	addi	sp,sp,-48
    80002634:	f406                	sd	ra,40(sp)
    80002636:	f022                	sd	s0,32(sp)
    80002638:	ec26                	sd	s1,24(sp)
    8000263a:	e84a                	sd	s2,16(sp)
    8000263c:	e44e                	sd	s3,8(sp)
    8000263e:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++)
    80002640:	0000f497          	auipc	s1,0xf
    80002644:	09048493          	addi	s1,s1,144 # 800116d0 <proc>
    if(p->pid > 2) // init process and shell?
    80002648:	4989                	li	s3,2
  for(p = proc; p < &proc[NPROC]; p++)
    8000264a:	00015917          	auipc	s2,0x15
    8000264e:	a8690913          	addi	s2,s2,-1402 # 800170d0 <tickslock>
    80002652:	a809                	j	80002664 <kill_system+0x32>
      kill(p->pid);
    80002654:	00000097          	auipc	ra,0x0
    80002658:	f6c080e7          	jalr	-148(ra) # 800025c0 <kill>
  for(p = proc; p < &proc[NPROC]; p++)
    8000265c:	16848493          	addi	s1,s1,360
    80002660:	01248663          	beq	s1,s2,8000266c <kill_system+0x3a>
    if(p->pid > 2) // init process and shell?
    80002664:	5888                	lw	a0,48(s1)
    80002666:	fea9dbe3          	bge	s3,a0,8000265c <kill_system+0x2a>
    8000266a:	b7ed                	j	80002654 <kill_system+0x22>
}
    8000266c:	4501                	li	a0,0
    8000266e:	70a2                	ld	ra,40(sp)
    80002670:	7402                	ld	s0,32(sp)
    80002672:	64e2                	ld	s1,24(sp)
    80002674:	6942                	ld	s2,16(sp)
    80002676:	69a2                	ld	s3,8(sp)
    80002678:	6145                	addi	sp,sp,48
    8000267a:	8082                	ret

000000008000267c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000267c:	7179                	addi	sp,sp,-48
    8000267e:	f406                	sd	ra,40(sp)
    80002680:	f022                	sd	s0,32(sp)
    80002682:	ec26                	sd	s1,24(sp)
    80002684:	e84a                	sd	s2,16(sp)
    80002686:	e44e                	sd	s3,8(sp)
    80002688:	e052                	sd	s4,0(sp)
    8000268a:	1800                	addi	s0,sp,48
    8000268c:	84aa                	mv	s1,a0
    8000268e:	892e                	mv	s2,a1
    80002690:	89b2                	mv	s3,a2
    80002692:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002694:	fffff097          	auipc	ra,0xfffff
    80002698:	440080e7          	jalr	1088(ra) # 80001ad4 <myproc>
  if(user_dst){
    8000269c:	c08d                	beqz	s1,800026be <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000269e:	86d2                	mv	a3,s4
    800026a0:	864e                	mv	a2,s3
    800026a2:	85ca                	mv	a1,s2
    800026a4:	6928                	ld	a0,80(a0)
    800026a6:	fffff097          	auipc	ra,0xfffff
    800026aa:	0f0080e7          	jalr	240(ra) # 80001796 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026ae:	70a2                	ld	ra,40(sp)
    800026b0:	7402                	ld	s0,32(sp)
    800026b2:	64e2                	ld	s1,24(sp)
    800026b4:	6942                	ld	s2,16(sp)
    800026b6:	69a2                	ld	s3,8(sp)
    800026b8:	6a02                	ld	s4,0(sp)
    800026ba:	6145                	addi	sp,sp,48
    800026bc:	8082                	ret
    memmove((char *)dst, src, len);
    800026be:	000a061b          	sext.w	a2,s4
    800026c2:	85ce                	mv	a1,s3
    800026c4:	854a                	mv	a0,s2
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	67a080e7          	jalr	1658(ra) # 80000d40 <memmove>
    return 0;
    800026ce:	8526                	mv	a0,s1
    800026d0:	bff9                	j	800026ae <either_copyout+0x32>

00000000800026d2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026d2:	7179                	addi	sp,sp,-48
    800026d4:	f406                	sd	ra,40(sp)
    800026d6:	f022                	sd	s0,32(sp)
    800026d8:	ec26                	sd	s1,24(sp)
    800026da:	e84a                	sd	s2,16(sp)
    800026dc:	e44e                	sd	s3,8(sp)
    800026de:	e052                	sd	s4,0(sp)
    800026e0:	1800                	addi	s0,sp,48
    800026e2:	892a                	mv	s2,a0
    800026e4:	84ae                	mv	s1,a1
    800026e6:	89b2                	mv	s3,a2
    800026e8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026ea:	fffff097          	auipc	ra,0xfffff
    800026ee:	3ea080e7          	jalr	1002(ra) # 80001ad4 <myproc>
  if(user_src){
    800026f2:	c08d                	beqz	s1,80002714 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026f4:	86d2                	mv	a3,s4
    800026f6:	864e                	mv	a2,s3
    800026f8:	85ca                	mv	a1,s2
    800026fa:	6928                	ld	a0,80(a0)
    800026fc:	fffff097          	auipc	ra,0xfffff
    80002700:	126080e7          	jalr	294(ra) # 80001822 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002704:	70a2                	ld	ra,40(sp)
    80002706:	7402                	ld	s0,32(sp)
    80002708:	64e2                	ld	s1,24(sp)
    8000270a:	6942                	ld	s2,16(sp)
    8000270c:	69a2                	ld	s3,8(sp)
    8000270e:	6a02                	ld	s4,0(sp)
    80002710:	6145                	addi	sp,sp,48
    80002712:	8082                	ret
    memmove(dst, (char*)src, len);
    80002714:	000a061b          	sext.w	a2,s4
    80002718:	85ce                	mv	a1,s3
    8000271a:	854a                	mv	a0,s2
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	624080e7          	jalr	1572(ra) # 80000d40 <memmove>
    return 0;
    80002724:	8526                	mv	a0,s1
    80002726:	bff9                	j	80002704 <either_copyin+0x32>

0000000080002728 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002728:	715d                	addi	sp,sp,-80
    8000272a:	e486                	sd	ra,72(sp)
    8000272c:	e0a2                	sd	s0,64(sp)
    8000272e:	fc26                	sd	s1,56(sp)
    80002730:	f84a                	sd	s2,48(sp)
    80002732:	f44e                	sd	s3,40(sp)
    80002734:	f052                	sd	s4,32(sp)
    80002736:	ec56                	sd	s5,24(sp)
    80002738:	e85a                	sd	s6,16(sp)
    8000273a:	e45e                	sd	s7,8(sp)
    8000273c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000273e:	00006517          	auipc	a0,0x6
    80002742:	9ca50513          	addi	a0,a0,-1590 # 80008108 <digits+0xc8>
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	e42080e7          	jalr	-446(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000274e:	0000f497          	auipc	s1,0xf
    80002752:	0da48493          	addi	s1,s1,218 # 80011828 <proc+0x158>
    80002756:	00015917          	auipc	s2,0x15
    8000275a:	ad290913          	addi	s2,s2,-1326 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000275e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002760:	00006997          	auipc	s3,0x6
    80002764:	b6098993          	addi	s3,s3,-1184 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    80002768:	00006a97          	auipc	s5,0x6
    8000276c:	b60a8a93          	addi	s5,s5,-1184 # 800082c8 <digits+0x288>
    printf("\n");
    80002770:	00006a17          	auipc	s4,0x6
    80002774:	998a0a13          	addi	s4,s4,-1640 # 80008108 <digits+0xc8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002778:	00006b97          	auipc	s7,0x6
    8000277c:	b88b8b93          	addi	s7,s7,-1144 # 80008300 <states.1733>
    80002780:	a00d                	j	800027a2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002782:	ed86a583          	lw	a1,-296(a3)
    80002786:	8556                	mv	a0,s5
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	e00080e7          	jalr	-512(ra) # 80000588 <printf>
    printf("\n");
    80002790:	8552                	mv	a0,s4
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	df6080e7          	jalr	-522(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000279a:	16848493          	addi	s1,s1,360
    8000279e:	03248163          	beq	s1,s2,800027c0 <procdump+0x98>
    if(p->state == UNUSED)
    800027a2:	86a6                	mv	a3,s1
    800027a4:	ec04a783          	lw	a5,-320(s1)
    800027a8:	dbed                	beqz	a5,8000279a <procdump+0x72>
      state = "???";
    800027aa:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ac:	fcfb6be3          	bltu	s6,a5,80002782 <procdump+0x5a>
    800027b0:	1782                	slli	a5,a5,0x20
    800027b2:	9381                	srli	a5,a5,0x20
    800027b4:	078e                	slli	a5,a5,0x3
    800027b6:	97de                	add	a5,a5,s7
    800027b8:	6390                	ld	a2,0(a5)
    800027ba:	f661                	bnez	a2,80002782 <procdump+0x5a>
      state = "???";
    800027bc:	864e                	mv	a2,s3
    800027be:	b7d1                	j	80002782 <procdump+0x5a>
  }
}
    800027c0:	60a6                	ld	ra,72(sp)
    800027c2:	6406                	ld	s0,64(sp)
    800027c4:	74e2                	ld	s1,56(sp)
    800027c6:	7942                	ld	s2,48(sp)
    800027c8:	79a2                	ld	s3,40(sp)
    800027ca:	7a02                	ld	s4,32(sp)
    800027cc:	6ae2                	ld	s5,24(sp)
    800027ce:	6b42                	ld	s6,16(sp)
    800027d0:	6ba2                	ld	s7,8(sp)
    800027d2:	6161                	addi	sp,sp,80
    800027d4:	8082                	ret

00000000800027d6 <swtch>:
    800027d6:	00153023          	sd	ra,0(a0)
    800027da:	00253423          	sd	sp,8(a0)
    800027de:	e900                	sd	s0,16(a0)
    800027e0:	ed04                	sd	s1,24(a0)
    800027e2:	03253023          	sd	s2,32(a0)
    800027e6:	03353423          	sd	s3,40(a0)
    800027ea:	03453823          	sd	s4,48(a0)
    800027ee:	03553c23          	sd	s5,56(a0)
    800027f2:	05653023          	sd	s6,64(a0)
    800027f6:	05753423          	sd	s7,72(a0)
    800027fa:	05853823          	sd	s8,80(a0)
    800027fe:	05953c23          	sd	s9,88(a0)
    80002802:	07a53023          	sd	s10,96(a0)
    80002806:	07b53423          	sd	s11,104(a0)
    8000280a:	0005b083          	ld	ra,0(a1)
    8000280e:	0085b103          	ld	sp,8(a1)
    80002812:	6980                	ld	s0,16(a1)
    80002814:	6d84                	ld	s1,24(a1)
    80002816:	0205b903          	ld	s2,32(a1)
    8000281a:	0285b983          	ld	s3,40(a1)
    8000281e:	0305ba03          	ld	s4,48(a1)
    80002822:	0385ba83          	ld	s5,56(a1)
    80002826:	0405bb03          	ld	s6,64(a1)
    8000282a:	0485bb83          	ld	s7,72(a1)
    8000282e:	0505bc03          	ld	s8,80(a1)
    80002832:	0585bc83          	ld	s9,88(a1)
    80002836:	0605bd03          	ld	s10,96(a1)
    8000283a:	0685bd83          	ld	s11,104(a1)
    8000283e:	8082                	ret

0000000080002840 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002840:	1141                	addi	sp,sp,-16
    80002842:	e406                	sd	ra,8(sp)
    80002844:	e022                	sd	s0,0(sp)
    80002846:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002848:	00006597          	auipc	a1,0x6
    8000284c:	ae858593          	addi	a1,a1,-1304 # 80008330 <states.1733+0x30>
    80002850:	00015517          	auipc	a0,0x15
    80002854:	88050513          	addi	a0,a0,-1920 # 800170d0 <tickslock>
    80002858:	ffffe097          	auipc	ra,0xffffe
    8000285c:	2fc080e7          	jalr	764(ra) # 80000b54 <initlock>
}
    80002860:	60a2                	ld	ra,8(sp)
    80002862:	6402                	ld	s0,0(sp)
    80002864:	0141                	addi	sp,sp,16
    80002866:	8082                	ret

0000000080002868 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002868:	1141                	addi	sp,sp,-16
    8000286a:	e422                	sd	s0,8(sp)
    8000286c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000286e:	00003797          	auipc	a5,0x3
    80002872:	4d278793          	addi	a5,a5,1234 # 80005d40 <kernelvec>
    80002876:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000287a:	6422                	ld	s0,8(sp)
    8000287c:	0141                	addi	sp,sp,16
    8000287e:	8082                	ret

0000000080002880 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002880:	1141                	addi	sp,sp,-16
    80002882:	e406                	sd	ra,8(sp)
    80002884:	e022                	sd	s0,0(sp)
    80002886:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002888:	fffff097          	auipc	ra,0xfffff
    8000288c:	24c080e7          	jalr	588(ra) # 80001ad4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002890:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002894:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002896:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000289a:	00004617          	auipc	a2,0x4
    8000289e:	76660613          	addi	a2,a2,1894 # 80007000 <_trampoline>
    800028a2:	00004697          	auipc	a3,0x4
    800028a6:	75e68693          	addi	a3,a3,1886 # 80007000 <_trampoline>
    800028aa:	8e91                	sub	a3,a3,a2
    800028ac:	040007b7          	lui	a5,0x4000
    800028b0:	17fd                	addi	a5,a5,-1
    800028b2:	07b2                	slli	a5,a5,0xc
    800028b4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028ba:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028bc:	180026f3          	csrr	a3,satp
    800028c0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028c2:	6d38                	ld	a4,88(a0)
    800028c4:	6134                	ld	a3,64(a0)
    800028c6:	6585                	lui	a1,0x1
    800028c8:	96ae                	add	a3,a3,a1
    800028ca:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028cc:	6d38                	ld	a4,88(a0)
    800028ce:	00000697          	auipc	a3,0x0
    800028d2:	13868693          	addi	a3,a3,312 # 80002a06 <usertrap>
    800028d6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028d8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028da:	8692                	mv	a3,tp
    800028dc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028de:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028e2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028e6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ea:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028ee:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028f0:	6f18                	ld	a4,24(a4)
    800028f2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028f6:	692c                	ld	a1,80(a0)
    800028f8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028fa:	00004717          	auipc	a4,0x4
    800028fe:	79670713          	addi	a4,a4,1942 # 80007090 <userret>
    80002902:	8f11                	sub	a4,a4,a2
    80002904:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002906:	577d                	li	a4,-1
    80002908:	177e                	slli	a4,a4,0x3f
    8000290a:	8dd9                	or	a1,a1,a4
    8000290c:	02000537          	lui	a0,0x2000
    80002910:	157d                	addi	a0,a0,-1
    80002912:	0536                	slli	a0,a0,0xd
    80002914:	9782                	jalr	a5
}
    80002916:	60a2                	ld	ra,8(sp)
    80002918:	6402                	ld	s0,0(sp)
    8000291a:	0141                	addi	sp,sp,16
    8000291c:	8082                	ret

000000008000291e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000291e:	1101                	addi	sp,sp,-32
    80002920:	ec06                	sd	ra,24(sp)
    80002922:	e822                	sd	s0,16(sp)
    80002924:	e426                	sd	s1,8(sp)
    80002926:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002928:	00014497          	auipc	s1,0x14
    8000292c:	7a848493          	addi	s1,s1,1960 # 800170d0 <tickslock>
    80002930:	8526                	mv	a0,s1
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	2b2080e7          	jalr	690(ra) # 80000be4 <acquire>
  ticks++;
    8000293a:	00006517          	auipc	a0,0x6
    8000293e:	6f650513          	addi	a0,a0,1782 # 80009030 <ticks>
    80002942:	411c                	lw	a5,0(a0)
    80002944:	2785                	addiw	a5,a5,1
    80002946:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002948:	00000097          	auipc	ra,0x0
    8000294c:	ad2080e7          	jalr	-1326(ra) # 8000241a <wakeup>
  release(&tickslock);
    80002950:	8526                	mv	a0,s1
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	346080e7          	jalr	838(ra) # 80000c98 <release>
}
    8000295a:	60e2                	ld	ra,24(sp)
    8000295c:	6442                	ld	s0,16(sp)
    8000295e:	64a2                	ld	s1,8(sp)
    80002960:	6105                	addi	sp,sp,32
    80002962:	8082                	ret

0000000080002964 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002964:	1101                	addi	sp,sp,-32
    80002966:	ec06                	sd	ra,24(sp)
    80002968:	e822                	sd	s0,16(sp)
    8000296a:	e426                	sd	s1,8(sp)
    8000296c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000296e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002972:	00074d63          	bltz	a4,8000298c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002976:	57fd                	li	a5,-1
    80002978:	17fe                	slli	a5,a5,0x3f
    8000297a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000297c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000297e:	06f70363          	beq	a4,a5,800029e4 <devintr+0x80>
  }
}
    80002982:	60e2                	ld	ra,24(sp)
    80002984:	6442                	ld	s0,16(sp)
    80002986:	64a2                	ld	s1,8(sp)
    80002988:	6105                	addi	sp,sp,32
    8000298a:	8082                	ret
     (scause & 0xff) == 9){
    8000298c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002990:	46a5                	li	a3,9
    80002992:	fed792e3          	bne	a5,a3,80002976 <devintr+0x12>
    int irq = plic_claim();
    80002996:	00003097          	auipc	ra,0x3
    8000299a:	4b2080e7          	jalr	1202(ra) # 80005e48 <plic_claim>
    8000299e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029a0:	47a9                	li	a5,10
    800029a2:	02f50763          	beq	a0,a5,800029d0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029a6:	4785                	li	a5,1
    800029a8:	02f50963          	beq	a0,a5,800029da <devintr+0x76>
    return 1;
    800029ac:	4505                	li	a0,1
    } else if(irq){
    800029ae:	d8f1                	beqz	s1,80002982 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029b0:	85a6                	mv	a1,s1
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	98650513          	addi	a0,a0,-1658 # 80008338 <states.1733+0x38>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	bce080e7          	jalr	-1074(ra) # 80000588 <printf>
      plic_complete(irq);
    800029c2:	8526                	mv	a0,s1
    800029c4:	00003097          	auipc	ra,0x3
    800029c8:	4a8080e7          	jalr	1192(ra) # 80005e6c <plic_complete>
    return 1;
    800029cc:	4505                	li	a0,1
    800029ce:	bf55                	j	80002982 <devintr+0x1e>
      uartintr();
    800029d0:	ffffe097          	auipc	ra,0xffffe
    800029d4:	fd8080e7          	jalr	-40(ra) # 800009a8 <uartintr>
    800029d8:	b7ed                	j	800029c2 <devintr+0x5e>
      virtio_disk_intr();
    800029da:	00004097          	auipc	ra,0x4
    800029de:	972080e7          	jalr	-1678(ra) # 8000634c <virtio_disk_intr>
    800029e2:	b7c5                	j	800029c2 <devintr+0x5e>
    if(cpuid() == 0){
    800029e4:	fffff097          	auipc	ra,0xfffff
    800029e8:	0c4080e7          	jalr	196(ra) # 80001aa8 <cpuid>
    800029ec:	c901                	beqz	a0,800029fc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029ee:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029f2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029f4:	14479073          	csrw	sip,a5
    return 2;
    800029f8:	4509                	li	a0,2
    800029fa:	b761                	j	80002982 <devintr+0x1e>
      clockintr();
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	f22080e7          	jalr	-222(ra) # 8000291e <clockintr>
    80002a04:	b7ed                	j	800029ee <devintr+0x8a>

0000000080002a06 <usertrap>:
{
    80002a06:	1101                	addi	sp,sp,-32
    80002a08:	ec06                	sd	ra,24(sp)
    80002a0a:	e822                	sd	s0,16(sp)
    80002a0c:	e426                	sd	s1,8(sp)
    80002a0e:	e04a                	sd	s2,0(sp)
    80002a10:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a12:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a16:	1007f793          	andi	a5,a5,256
    80002a1a:	e3ad                	bnez	a5,80002a7c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a1c:	00003797          	auipc	a5,0x3
    80002a20:	32478793          	addi	a5,a5,804 # 80005d40 <kernelvec>
    80002a24:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	0ac080e7          	jalr	172(ra) # 80001ad4 <myproc>
    80002a30:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a32:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a34:	14102773          	csrr	a4,sepc
    80002a38:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a3e:	47a1                	li	a5,8
    80002a40:	04f71c63          	bne	a4,a5,80002a98 <usertrap+0x92>
    if(p->killed)
    80002a44:	551c                	lw	a5,40(a0)
    80002a46:	e3b9                	bnez	a5,80002a8c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a48:	6cb8                	ld	a4,88(s1)
    80002a4a:	6f1c                	ld	a5,24(a4)
    80002a4c:	0791                	addi	a5,a5,4
    80002a4e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a58:	10079073          	csrw	sstatus,a5
    syscall();
    80002a5c:	00000097          	auipc	ra,0x0
    80002a60:	2e0080e7          	jalr	736(ra) # 80002d3c <syscall>
  if(p->killed)
    80002a64:	549c                	lw	a5,40(s1)
    80002a66:	ebc1                	bnez	a5,80002af6 <usertrap+0xf0>
  usertrapret();
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	e18080e7          	jalr	-488(ra) # 80002880 <usertrapret>
}
    80002a70:	60e2                	ld	ra,24(sp)
    80002a72:	6442                	ld	s0,16(sp)
    80002a74:	64a2                	ld	s1,8(sp)
    80002a76:	6902                	ld	s2,0(sp)
    80002a78:	6105                	addi	sp,sp,32
    80002a7a:	8082                	ret
    panic("usertrap: not from user mode");
    80002a7c:	00006517          	auipc	a0,0x6
    80002a80:	8dc50513          	addi	a0,a0,-1828 # 80008358 <states.1733+0x58>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	aba080e7          	jalr	-1350(ra) # 8000053e <panic>
      exit(-1);
    80002a8c:	557d                	li	a0,-1
    80002a8e:	00000097          	auipc	ra,0x0
    80002a92:	a5c080e7          	jalr	-1444(ra) # 800024ea <exit>
    80002a96:	bf4d                	j	80002a48 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a98:	00000097          	auipc	ra,0x0
    80002a9c:	ecc080e7          	jalr	-308(ra) # 80002964 <devintr>
    80002aa0:	892a                	mv	s2,a0
    80002aa2:	c501                	beqz	a0,80002aaa <usertrap+0xa4>
  if(p->killed)
    80002aa4:	549c                	lw	a5,40(s1)
    80002aa6:	c3a1                	beqz	a5,80002ae6 <usertrap+0xe0>
    80002aa8:	a815                	j	80002adc <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aaa:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002aae:	5890                	lw	a2,48(s1)
    80002ab0:	00006517          	auipc	a0,0x6
    80002ab4:	8c850513          	addi	a0,a0,-1848 # 80008378 <states.1733+0x78>
    80002ab8:	ffffe097          	auipc	ra,0xffffe
    80002abc:	ad0080e7          	jalr	-1328(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ac4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ac8:	00006517          	auipc	a0,0x6
    80002acc:	8e050513          	addi	a0,a0,-1824 # 800083a8 <states.1733+0xa8>
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	ab8080e7          	jalr	-1352(ra) # 80000588 <printf>
    p->killed = 1;
    80002ad8:	4785                	li	a5,1
    80002ada:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002adc:	557d                	li	a0,-1
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	a0c080e7          	jalr	-1524(ra) # 800024ea <exit>
  if(which_dev == 2)
    80002ae6:	4789                	li	a5,2
    80002ae8:	f8f910e3          	bne	s2,a5,80002a68 <usertrap+0x62>
    yield();
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	668080e7          	jalr	1640(ra) # 80002154 <yield>
    80002af4:	bf95                	j	80002a68 <usertrap+0x62>
  int which_dev = 0;
    80002af6:	4901                	li	s2,0
    80002af8:	b7d5                	j	80002adc <usertrap+0xd6>

0000000080002afa <kerneltrap>:
{
    80002afa:	7179                	addi	sp,sp,-48
    80002afc:	f406                	sd	ra,40(sp)
    80002afe:	f022                	sd	s0,32(sp)
    80002b00:	ec26                	sd	s1,24(sp)
    80002b02:	e84a                	sd	s2,16(sp)
    80002b04:	e44e                	sd	s3,8(sp)
    80002b06:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b08:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b0c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b10:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b14:	1004f793          	andi	a5,s1,256
    80002b18:	cb85                	beqz	a5,80002b48 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b1e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b20:	ef85                	bnez	a5,80002b58 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	e42080e7          	jalr	-446(ra) # 80002964 <devintr>
    80002b2a:	cd1d                	beqz	a0,80002b68 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b2c:	4789                	li	a5,2
    80002b2e:	06f50a63          	beq	a0,a5,80002ba2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b32:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b36:	10049073          	csrw	sstatus,s1
}
    80002b3a:	70a2                	ld	ra,40(sp)
    80002b3c:	7402                	ld	s0,32(sp)
    80002b3e:	64e2                	ld	s1,24(sp)
    80002b40:	6942                	ld	s2,16(sp)
    80002b42:	69a2                	ld	s3,8(sp)
    80002b44:	6145                	addi	sp,sp,48
    80002b46:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b48:	00006517          	auipc	a0,0x6
    80002b4c:	88050513          	addi	a0,a0,-1920 # 800083c8 <states.1733+0xc8>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	9ee080e7          	jalr	-1554(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b58:	00006517          	auipc	a0,0x6
    80002b5c:	89850513          	addi	a0,a0,-1896 # 800083f0 <states.1733+0xf0>
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	9de080e7          	jalr	-1570(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b68:	85ce                	mv	a1,s3
    80002b6a:	00006517          	auipc	a0,0x6
    80002b6e:	8a650513          	addi	a0,a0,-1882 # 80008410 <states.1733+0x110>
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	a16080e7          	jalr	-1514(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b7a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b7e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b82:	00006517          	auipc	a0,0x6
    80002b86:	89e50513          	addi	a0,a0,-1890 # 80008420 <states.1733+0x120>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	9fe080e7          	jalr	-1538(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b92:	00006517          	auipc	a0,0x6
    80002b96:	8a650513          	addi	a0,a0,-1882 # 80008438 <states.1733+0x138>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	9a4080e7          	jalr	-1628(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	f32080e7          	jalr	-206(ra) # 80001ad4 <myproc>
    80002baa:	d541                	beqz	a0,80002b32 <kerneltrap+0x38>
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	f28080e7          	jalr	-216(ra) # 80001ad4 <myproc>
    80002bb4:	4d18                	lw	a4,24(a0)
    80002bb6:	4791                	li	a5,4
    80002bb8:	f6f71de3          	bne	a4,a5,80002b32 <kerneltrap+0x38>
    yield();
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	598080e7          	jalr	1432(ra) # 80002154 <yield>
    80002bc4:	b7bd                	j	80002b32 <kerneltrap+0x38>

0000000080002bc6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bc6:	1101                	addi	sp,sp,-32
    80002bc8:	ec06                	sd	ra,24(sp)
    80002bca:	e822                	sd	s0,16(sp)
    80002bcc:	e426                	sd	s1,8(sp)
    80002bce:	1000                	addi	s0,sp,32
    80002bd0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	f02080e7          	jalr	-254(ra) # 80001ad4 <myproc>
  switch (n) {
    80002bda:	4795                	li	a5,5
    80002bdc:	0497e163          	bltu	a5,s1,80002c1e <argraw+0x58>
    80002be0:	048a                	slli	s1,s1,0x2
    80002be2:	00006717          	auipc	a4,0x6
    80002be6:	88e70713          	addi	a4,a4,-1906 # 80008470 <states.1733+0x170>
    80002bea:	94ba                	add	s1,s1,a4
    80002bec:	409c                	lw	a5,0(s1)
    80002bee:	97ba                	add	a5,a5,a4
    80002bf0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bf2:	6d3c                	ld	a5,88(a0)
    80002bf4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bf6:	60e2                	ld	ra,24(sp)
    80002bf8:	6442                	ld	s0,16(sp)
    80002bfa:	64a2                	ld	s1,8(sp)
    80002bfc:	6105                	addi	sp,sp,32
    80002bfe:	8082                	ret
    return p->trapframe->a1;
    80002c00:	6d3c                	ld	a5,88(a0)
    80002c02:	7fa8                	ld	a0,120(a5)
    80002c04:	bfcd                	j	80002bf6 <argraw+0x30>
    return p->trapframe->a2;
    80002c06:	6d3c                	ld	a5,88(a0)
    80002c08:	63c8                	ld	a0,128(a5)
    80002c0a:	b7f5                	j	80002bf6 <argraw+0x30>
    return p->trapframe->a3;
    80002c0c:	6d3c                	ld	a5,88(a0)
    80002c0e:	67c8                	ld	a0,136(a5)
    80002c10:	b7dd                	j	80002bf6 <argraw+0x30>
    return p->trapframe->a4;
    80002c12:	6d3c                	ld	a5,88(a0)
    80002c14:	6bc8                	ld	a0,144(a5)
    80002c16:	b7c5                	j	80002bf6 <argraw+0x30>
    return p->trapframe->a5;
    80002c18:	6d3c                	ld	a5,88(a0)
    80002c1a:	6fc8                	ld	a0,152(a5)
    80002c1c:	bfe9                	j	80002bf6 <argraw+0x30>
  panic("argraw");
    80002c1e:	00006517          	auipc	a0,0x6
    80002c22:	82a50513          	addi	a0,a0,-2006 # 80008448 <states.1733+0x148>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	918080e7          	jalr	-1768(ra) # 8000053e <panic>

0000000080002c2e <fetchaddr>:
{
    80002c2e:	1101                	addi	sp,sp,-32
    80002c30:	ec06                	sd	ra,24(sp)
    80002c32:	e822                	sd	s0,16(sp)
    80002c34:	e426                	sd	s1,8(sp)
    80002c36:	e04a                	sd	s2,0(sp)
    80002c38:	1000                	addi	s0,sp,32
    80002c3a:	84aa                	mv	s1,a0
    80002c3c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	e96080e7          	jalr	-362(ra) # 80001ad4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c46:	653c                	ld	a5,72(a0)
    80002c48:	02f4f863          	bgeu	s1,a5,80002c78 <fetchaddr+0x4a>
    80002c4c:	00848713          	addi	a4,s1,8
    80002c50:	02e7e663          	bltu	a5,a4,80002c7c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c54:	46a1                	li	a3,8
    80002c56:	8626                	mv	a2,s1
    80002c58:	85ca                	mv	a1,s2
    80002c5a:	6928                	ld	a0,80(a0)
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	bc6080e7          	jalr	-1082(ra) # 80001822 <copyin>
    80002c64:	00a03533          	snez	a0,a0
    80002c68:	40a00533          	neg	a0,a0
}
    80002c6c:	60e2                	ld	ra,24(sp)
    80002c6e:	6442                	ld	s0,16(sp)
    80002c70:	64a2                	ld	s1,8(sp)
    80002c72:	6902                	ld	s2,0(sp)
    80002c74:	6105                	addi	sp,sp,32
    80002c76:	8082                	ret
    return -1;
    80002c78:	557d                	li	a0,-1
    80002c7a:	bfcd                	j	80002c6c <fetchaddr+0x3e>
    80002c7c:	557d                	li	a0,-1
    80002c7e:	b7fd                	j	80002c6c <fetchaddr+0x3e>

0000000080002c80 <fetchstr>:
{
    80002c80:	7179                	addi	sp,sp,-48
    80002c82:	f406                	sd	ra,40(sp)
    80002c84:	f022                	sd	s0,32(sp)
    80002c86:	ec26                	sd	s1,24(sp)
    80002c88:	e84a                	sd	s2,16(sp)
    80002c8a:	e44e                	sd	s3,8(sp)
    80002c8c:	1800                	addi	s0,sp,48
    80002c8e:	892a                	mv	s2,a0
    80002c90:	84ae                	mv	s1,a1
    80002c92:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	e40080e7          	jalr	-448(ra) # 80001ad4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c9c:	86ce                	mv	a3,s3
    80002c9e:	864a                	mv	a2,s2
    80002ca0:	85a6                	mv	a1,s1
    80002ca2:	6928                	ld	a0,80(a0)
    80002ca4:	fffff097          	auipc	ra,0xfffff
    80002ca8:	c0a080e7          	jalr	-1014(ra) # 800018ae <copyinstr>
  if(err < 0)
    80002cac:	00054763          	bltz	a0,80002cba <fetchstr+0x3a>
  return strlen(buf);
    80002cb0:	8526                	mv	a0,s1
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	1b2080e7          	jalr	434(ra) # 80000e64 <strlen>
}
    80002cba:	70a2                	ld	ra,40(sp)
    80002cbc:	7402                	ld	s0,32(sp)
    80002cbe:	64e2                	ld	s1,24(sp)
    80002cc0:	6942                	ld	s2,16(sp)
    80002cc2:	69a2                	ld	s3,8(sp)
    80002cc4:	6145                	addi	sp,sp,48
    80002cc6:	8082                	ret

0000000080002cc8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cc8:	1101                	addi	sp,sp,-32
    80002cca:	ec06                	sd	ra,24(sp)
    80002ccc:	e822                	sd	s0,16(sp)
    80002cce:	e426                	sd	s1,8(sp)
    80002cd0:	1000                	addi	s0,sp,32
    80002cd2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cd4:	00000097          	auipc	ra,0x0
    80002cd8:	ef2080e7          	jalr	-270(ra) # 80002bc6 <argraw>
    80002cdc:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cde:	4501                	li	a0,0
    80002ce0:	60e2                	ld	ra,24(sp)
    80002ce2:	6442                	ld	s0,16(sp)
    80002ce4:	64a2                	ld	s1,8(sp)
    80002ce6:	6105                	addi	sp,sp,32
    80002ce8:	8082                	ret

0000000080002cea <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cea:	1101                	addi	sp,sp,-32
    80002cec:	ec06                	sd	ra,24(sp)
    80002cee:	e822                	sd	s0,16(sp)
    80002cf0:	e426                	sd	s1,8(sp)
    80002cf2:	1000                	addi	s0,sp,32
    80002cf4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cf6:	00000097          	auipc	ra,0x0
    80002cfa:	ed0080e7          	jalr	-304(ra) # 80002bc6 <argraw>
    80002cfe:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d00:	4501                	li	a0,0
    80002d02:	60e2                	ld	ra,24(sp)
    80002d04:	6442                	ld	s0,16(sp)
    80002d06:	64a2                	ld	s1,8(sp)
    80002d08:	6105                	addi	sp,sp,32
    80002d0a:	8082                	ret

0000000080002d0c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d0c:	1101                	addi	sp,sp,-32
    80002d0e:	ec06                	sd	ra,24(sp)
    80002d10:	e822                	sd	s0,16(sp)
    80002d12:	e426                	sd	s1,8(sp)
    80002d14:	e04a                	sd	s2,0(sp)
    80002d16:	1000                	addi	s0,sp,32
    80002d18:	84ae                	mv	s1,a1
    80002d1a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d1c:	00000097          	auipc	ra,0x0
    80002d20:	eaa080e7          	jalr	-342(ra) # 80002bc6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d24:	864a                	mv	a2,s2
    80002d26:	85a6                	mv	a1,s1
    80002d28:	00000097          	auipc	ra,0x0
    80002d2c:	f58080e7          	jalr	-168(ra) # 80002c80 <fetchstr>
}
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	64a2                	ld	s1,8(sp)
    80002d36:	6902                	ld	s2,0(sp)
    80002d38:	6105                	addi	sp,sp,32
    80002d3a:	8082                	ret

0000000080002d3c <syscall>:
[SYS_kill_system]   sys_kill_system
};

void
syscall(void)
{
    80002d3c:	1101                	addi	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	e426                	sd	s1,8(sp)
    80002d44:	e04a                	sd	s2,0(sp)
    80002d46:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	d8c080e7          	jalr	-628(ra) # 80001ad4 <myproc>
    80002d50:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d52:	05853903          	ld	s2,88(a0)
    80002d56:	0a893783          	ld	a5,168(s2)
    80002d5a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d5e:	37fd                	addiw	a5,a5,-1
    80002d60:	4759                	li	a4,22
    80002d62:	00f76f63          	bltu	a4,a5,80002d80 <syscall+0x44>
    80002d66:	00369713          	slli	a4,a3,0x3
    80002d6a:	00005797          	auipc	a5,0x5
    80002d6e:	71e78793          	addi	a5,a5,1822 # 80008488 <syscalls>
    80002d72:	97ba                	add	a5,a5,a4
    80002d74:	639c                	ld	a5,0(a5)
    80002d76:	c789                	beqz	a5,80002d80 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d78:	9782                	jalr	a5
    80002d7a:	06a93823          	sd	a0,112(s2)
    80002d7e:	a839                	j	80002d9c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d80:	15848613          	addi	a2,s1,344
    80002d84:	588c                	lw	a1,48(s1)
    80002d86:	00005517          	auipc	a0,0x5
    80002d8a:	6ca50513          	addi	a0,a0,1738 # 80008450 <states.1733+0x150>
    80002d8e:	ffffd097          	auipc	ra,0xffffd
    80002d92:	7fa080e7          	jalr	2042(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d96:	6cbc                	ld	a5,88(s1)
    80002d98:	577d                	li	a4,-1
    80002d9a:	fbb8                	sd	a4,112(a5)
  }
}
    80002d9c:	60e2                	ld	ra,24(sp)
    80002d9e:	6442                	ld	s0,16(sp)
    80002da0:	64a2                	ld	s1,8(sp)
    80002da2:	6902                	ld	s2,0(sp)
    80002da4:	6105                	addi	sp,sp,32
    80002da6:	8082                	ret

0000000080002da8 <sys_pause_system>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_pause_system(void)
{
    80002da8:	1101                	addi	sp,sp,-32
    80002daa:	ec06                	sd	ra,24(sp)
    80002dac:	e822                	sd	s0,16(sp)
    80002dae:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002db0:	fec40593          	addi	a1,s0,-20
    80002db4:	4501                	li	a0,0
    80002db6:	00000097          	auipc	ra,0x0
    80002dba:	f12080e7          	jalr	-238(ra) # 80002cc8 <argint>
    80002dbe:	87aa                	mv	a5,a0
    return -1;
    80002dc0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002dc2:	0007c863          	bltz	a5,80002dd2 <sys_pause_system+0x2a>
  
  return pause_system(n);
    80002dc6:	fec42503          	lw	a0,-20(s0)
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	42a080e7          	jalr	1066(ra) # 800021f4 <pause_system>
}
    80002dd2:	60e2                	ld	ra,24(sp)
    80002dd4:	6442                	ld	s0,16(sp)
    80002dd6:	6105                	addi	sp,sp,32
    80002dd8:	8082                	ret

0000000080002dda <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80002dda:	1141                	addi	sp,sp,-16
    80002ddc:	e406                	sd	ra,8(sp)
    80002dde:	e022                	sd	s0,0(sp)
    80002de0:	0800                	addi	s0,sp,16
  return kill_system();
    80002de2:	00000097          	auipc	ra,0x0
    80002de6:	850080e7          	jalr	-1968(ra) # 80002632 <kill_system>
}
    80002dea:	60a2                	ld	ra,8(sp)
    80002dec:	6402                	ld	s0,0(sp)
    80002dee:	0141                	addi	sp,sp,16
    80002df0:	8082                	ret

0000000080002df2 <sys_exit>:


uint64
sys_exit(void)
{
    80002df2:	1101                	addi	sp,sp,-32
    80002df4:	ec06                	sd	ra,24(sp)
    80002df6:	e822                	sd	s0,16(sp)
    80002df8:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dfa:	fec40593          	addi	a1,s0,-20
    80002dfe:	4501                	li	a0,0
    80002e00:	00000097          	auipc	ra,0x0
    80002e04:	ec8080e7          	jalr	-312(ra) # 80002cc8 <argint>
    return -1;
    80002e08:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e0a:	00054963          	bltz	a0,80002e1c <sys_exit+0x2a>
  exit(n);
    80002e0e:	fec42503          	lw	a0,-20(s0)
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	6d8080e7          	jalr	1752(ra) # 800024ea <exit>
  return 0;  // not reached
    80002e1a:	4781                	li	a5,0
}
    80002e1c:	853e                	mv	a0,a5
    80002e1e:	60e2                	ld	ra,24(sp)
    80002e20:	6442                	ld	s0,16(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e26:	1141                	addi	sp,sp,-16
    80002e28:	e406                	sd	ra,8(sp)
    80002e2a:	e022                	sd	s0,0(sp)
    80002e2c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	ca6080e7          	jalr	-858(ra) # 80001ad4 <myproc>
}
    80002e36:	5908                	lw	a0,48(a0)
    80002e38:	60a2                	ld	ra,8(sp)
    80002e3a:	6402                	ld	s0,0(sp)
    80002e3c:	0141                	addi	sp,sp,16
    80002e3e:	8082                	ret

0000000080002e40 <sys_fork>:

uint64
sys_fork(void)
{
    80002e40:	1141                	addi	sp,sp,-16
    80002e42:	e406                	sd	ra,8(sp)
    80002e44:	e022                	sd	s0,0(sp)
    80002e46:	0800                	addi	s0,sp,16
  return fork();
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	05a080e7          	jalr	90(ra) # 80001ea2 <fork>
}
    80002e50:	60a2                	ld	ra,8(sp)
    80002e52:	6402                	ld	s0,0(sp)
    80002e54:	0141                	addi	sp,sp,16
    80002e56:	8082                	ret

0000000080002e58 <sys_wait>:

uint64
sys_wait(void)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e60:	fe840593          	addi	a1,s0,-24
    80002e64:	4501                	li	a0,0
    80002e66:	00000097          	auipc	ra,0x0
    80002e6a:	e84080e7          	jalr	-380(ra) # 80002cea <argaddr>
    80002e6e:	87aa                	mv	a5,a0
    return -1;
    80002e70:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e72:	0007c863          	bltz	a5,80002e82 <sys_wait+0x2a>
  return wait(p);
    80002e76:	fe843503          	ld	a0,-24(s0)
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	478080e7          	jalr	1144(ra) # 800022f2 <wait>
}
    80002e82:	60e2                	ld	ra,24(sp)
    80002e84:	6442                	ld	s0,16(sp)
    80002e86:	6105                	addi	sp,sp,32
    80002e88:	8082                	ret

0000000080002e8a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e8a:	7179                	addi	sp,sp,-48
    80002e8c:	f406                	sd	ra,40(sp)
    80002e8e:	f022                	sd	s0,32(sp)
    80002e90:	ec26                	sd	s1,24(sp)
    80002e92:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e94:	fdc40593          	addi	a1,s0,-36
    80002e98:	4501                	li	a0,0
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	e2e080e7          	jalr	-466(ra) # 80002cc8 <argint>
    80002ea2:	87aa                	mv	a5,a0
    return -1;
    80002ea4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ea6:	0207c063          	bltz	a5,80002ec6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	c2a080e7          	jalr	-982(ra) # 80001ad4 <myproc>
    80002eb2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002eb4:	fdc42503          	lw	a0,-36(s0)
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	f76080e7          	jalr	-138(ra) # 80001e2e <growproc>
    80002ec0:	00054863          	bltz	a0,80002ed0 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ec4:	8526                	mv	a0,s1
}
    80002ec6:	70a2                	ld	ra,40(sp)
    80002ec8:	7402                	ld	s0,32(sp)
    80002eca:	64e2                	ld	s1,24(sp)
    80002ecc:	6145                	addi	sp,sp,48
    80002ece:	8082                	ret
    return -1;
    80002ed0:	557d                	li	a0,-1
    80002ed2:	bfd5                	j	80002ec6 <sys_sbrk+0x3c>

0000000080002ed4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ed4:	7139                	addi	sp,sp,-64
    80002ed6:	fc06                	sd	ra,56(sp)
    80002ed8:	f822                	sd	s0,48(sp)
    80002eda:	f426                	sd	s1,40(sp)
    80002edc:	f04a                	sd	s2,32(sp)
    80002ede:	ec4e                	sd	s3,24(sp)
    80002ee0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ee2:	fcc40593          	addi	a1,s0,-52
    80002ee6:	4501                	li	a0,0
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	de0080e7          	jalr	-544(ra) # 80002cc8 <argint>
    return -1;
    80002ef0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ef2:	06054563          	bltz	a0,80002f5c <sys_sleep+0x88>
  acquire(&tickslock);
    80002ef6:	00014517          	auipc	a0,0x14
    80002efa:	1da50513          	addi	a0,a0,474 # 800170d0 <tickslock>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	ce6080e7          	jalr	-794(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f06:	00006917          	auipc	s2,0x6
    80002f0a:	12a92903          	lw	s2,298(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f0e:	fcc42783          	lw	a5,-52(s0)
    80002f12:	cf85                	beqz	a5,80002f4a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f14:	00014997          	auipc	s3,0x14
    80002f18:	1bc98993          	addi	s3,s3,444 # 800170d0 <tickslock>
    80002f1c:	00006497          	auipc	s1,0x6
    80002f20:	11448493          	addi	s1,s1,276 # 80009030 <ticks>
    if(myproc()->killed){
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	bb0080e7          	jalr	-1104(ra) # 80001ad4 <myproc>
    80002f2c:	551c                	lw	a5,40(a0)
    80002f2e:	ef9d                	bnez	a5,80002f6c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f30:	85ce                	mv	a1,s3
    80002f32:	8526                	mv	a0,s1
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	25c080e7          	jalr	604(ra) # 80002190 <sleep>
  while(ticks - ticks0 < n){
    80002f3c:	409c                	lw	a5,0(s1)
    80002f3e:	412787bb          	subw	a5,a5,s2
    80002f42:	fcc42703          	lw	a4,-52(s0)
    80002f46:	fce7efe3          	bltu	a5,a4,80002f24 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f4a:	00014517          	auipc	a0,0x14
    80002f4e:	18650513          	addi	a0,a0,390 # 800170d0 <tickslock>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	d46080e7          	jalr	-698(ra) # 80000c98 <release>
  return 0;
    80002f5a:	4781                	li	a5,0
}
    80002f5c:	853e                	mv	a0,a5
    80002f5e:	70e2                	ld	ra,56(sp)
    80002f60:	7442                	ld	s0,48(sp)
    80002f62:	74a2                	ld	s1,40(sp)
    80002f64:	7902                	ld	s2,32(sp)
    80002f66:	69e2                	ld	s3,24(sp)
    80002f68:	6121                	addi	sp,sp,64
    80002f6a:	8082                	ret
      release(&tickslock);
    80002f6c:	00014517          	auipc	a0,0x14
    80002f70:	16450513          	addi	a0,a0,356 # 800170d0 <tickslock>
    80002f74:	ffffe097          	auipc	ra,0xffffe
    80002f78:	d24080e7          	jalr	-732(ra) # 80000c98 <release>
      return -1;
    80002f7c:	57fd                	li	a5,-1
    80002f7e:	bff9                	j	80002f5c <sys_sleep+0x88>

0000000080002f80 <sys_kill>:

uint64
sys_kill(void)
{
    80002f80:	1101                	addi	sp,sp,-32
    80002f82:	ec06                	sd	ra,24(sp)
    80002f84:	e822                	sd	s0,16(sp)
    80002f86:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f88:	fec40593          	addi	a1,s0,-20
    80002f8c:	4501                	li	a0,0
    80002f8e:	00000097          	auipc	ra,0x0
    80002f92:	d3a080e7          	jalr	-710(ra) # 80002cc8 <argint>
    80002f96:	87aa                	mv	a5,a0
    return -1;
    80002f98:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f9a:	0007c863          	bltz	a5,80002faa <sys_kill+0x2a>
  return kill(pid);
    80002f9e:	fec42503          	lw	a0,-20(s0)
    80002fa2:	fffff097          	auipc	ra,0xfffff
    80002fa6:	61e080e7          	jalr	1566(ra) # 800025c0 <kill>
}
    80002faa:	60e2                	ld	ra,24(sp)
    80002fac:	6442                	ld	s0,16(sp)
    80002fae:	6105                	addi	sp,sp,32
    80002fb0:	8082                	ret

0000000080002fb2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fb2:	1101                	addi	sp,sp,-32
    80002fb4:	ec06                	sd	ra,24(sp)
    80002fb6:	e822                	sd	s0,16(sp)
    80002fb8:	e426                	sd	s1,8(sp)
    80002fba:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fbc:	00014517          	auipc	a0,0x14
    80002fc0:	11450513          	addi	a0,a0,276 # 800170d0 <tickslock>
    80002fc4:	ffffe097          	auipc	ra,0xffffe
    80002fc8:	c20080e7          	jalr	-992(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002fcc:	00006497          	auipc	s1,0x6
    80002fd0:	0644a483          	lw	s1,100(s1) # 80009030 <ticks>
  release(&tickslock);
    80002fd4:	00014517          	auipc	a0,0x14
    80002fd8:	0fc50513          	addi	a0,a0,252 # 800170d0 <tickslock>
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	cbc080e7          	jalr	-836(ra) # 80000c98 <release>
  return xticks;
}
    80002fe4:	02049513          	slli	a0,s1,0x20
    80002fe8:	9101                	srli	a0,a0,0x20
    80002fea:	60e2                	ld	ra,24(sp)
    80002fec:	6442                	ld	s0,16(sp)
    80002fee:	64a2                	ld	s1,8(sp)
    80002ff0:	6105                	addi	sp,sp,32
    80002ff2:	8082                	ret

0000000080002ff4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ff4:	7179                	addi	sp,sp,-48
    80002ff6:	f406                	sd	ra,40(sp)
    80002ff8:	f022                	sd	s0,32(sp)
    80002ffa:	ec26                	sd	s1,24(sp)
    80002ffc:	e84a                	sd	s2,16(sp)
    80002ffe:	e44e                	sd	s3,8(sp)
    80003000:	e052                	sd	s4,0(sp)
    80003002:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003004:	00005597          	auipc	a1,0x5
    80003008:	54458593          	addi	a1,a1,1348 # 80008548 <syscalls+0xc0>
    8000300c:	00014517          	auipc	a0,0x14
    80003010:	0dc50513          	addi	a0,a0,220 # 800170e8 <bcache>
    80003014:	ffffe097          	auipc	ra,0xffffe
    80003018:	b40080e7          	jalr	-1216(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000301c:	0001c797          	auipc	a5,0x1c
    80003020:	0cc78793          	addi	a5,a5,204 # 8001f0e8 <bcache+0x8000>
    80003024:	0001c717          	auipc	a4,0x1c
    80003028:	32c70713          	addi	a4,a4,812 # 8001f350 <bcache+0x8268>
    8000302c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003030:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003034:	00014497          	auipc	s1,0x14
    80003038:	0cc48493          	addi	s1,s1,204 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    8000303c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000303e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003040:	00005a17          	auipc	s4,0x5
    80003044:	510a0a13          	addi	s4,s4,1296 # 80008550 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003048:	2b893783          	ld	a5,696(s2)
    8000304c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000304e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003052:	85d2                	mv	a1,s4
    80003054:	01048513          	addi	a0,s1,16
    80003058:	00001097          	auipc	ra,0x1
    8000305c:	4bc080e7          	jalr	1212(ra) # 80004514 <initsleeplock>
    bcache.head.next->prev = b;
    80003060:	2b893783          	ld	a5,696(s2)
    80003064:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003066:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000306a:	45848493          	addi	s1,s1,1112
    8000306e:	fd349de3          	bne	s1,s3,80003048 <binit+0x54>
  }
}
    80003072:	70a2                	ld	ra,40(sp)
    80003074:	7402                	ld	s0,32(sp)
    80003076:	64e2                	ld	s1,24(sp)
    80003078:	6942                	ld	s2,16(sp)
    8000307a:	69a2                	ld	s3,8(sp)
    8000307c:	6a02                	ld	s4,0(sp)
    8000307e:	6145                	addi	sp,sp,48
    80003080:	8082                	ret

0000000080003082 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003082:	7179                	addi	sp,sp,-48
    80003084:	f406                	sd	ra,40(sp)
    80003086:	f022                	sd	s0,32(sp)
    80003088:	ec26                	sd	s1,24(sp)
    8000308a:	e84a                	sd	s2,16(sp)
    8000308c:	e44e                	sd	s3,8(sp)
    8000308e:	1800                	addi	s0,sp,48
    80003090:	89aa                	mv	s3,a0
    80003092:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003094:	00014517          	auipc	a0,0x14
    80003098:	05450513          	addi	a0,a0,84 # 800170e8 <bcache>
    8000309c:	ffffe097          	auipc	ra,0xffffe
    800030a0:	b48080e7          	jalr	-1208(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030a4:	0001c497          	auipc	s1,0x1c
    800030a8:	2fc4b483          	ld	s1,764(s1) # 8001f3a0 <bcache+0x82b8>
    800030ac:	0001c797          	auipc	a5,0x1c
    800030b0:	2a478793          	addi	a5,a5,676 # 8001f350 <bcache+0x8268>
    800030b4:	02f48f63          	beq	s1,a5,800030f2 <bread+0x70>
    800030b8:	873e                	mv	a4,a5
    800030ba:	a021                	j	800030c2 <bread+0x40>
    800030bc:	68a4                	ld	s1,80(s1)
    800030be:	02e48a63          	beq	s1,a4,800030f2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030c2:	449c                	lw	a5,8(s1)
    800030c4:	ff379ce3          	bne	a5,s3,800030bc <bread+0x3a>
    800030c8:	44dc                	lw	a5,12(s1)
    800030ca:	ff2799e3          	bne	a5,s2,800030bc <bread+0x3a>
      b->refcnt++;
    800030ce:	40bc                	lw	a5,64(s1)
    800030d0:	2785                	addiw	a5,a5,1
    800030d2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030d4:	00014517          	auipc	a0,0x14
    800030d8:	01450513          	addi	a0,a0,20 # 800170e8 <bcache>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	bbc080e7          	jalr	-1092(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030e4:	01048513          	addi	a0,s1,16
    800030e8:	00001097          	auipc	ra,0x1
    800030ec:	466080e7          	jalr	1126(ra) # 8000454e <acquiresleep>
      return b;
    800030f0:	a8b9                	j	8000314e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030f2:	0001c497          	auipc	s1,0x1c
    800030f6:	2a64b483          	ld	s1,678(s1) # 8001f398 <bcache+0x82b0>
    800030fa:	0001c797          	auipc	a5,0x1c
    800030fe:	25678793          	addi	a5,a5,598 # 8001f350 <bcache+0x8268>
    80003102:	00f48863          	beq	s1,a5,80003112 <bread+0x90>
    80003106:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003108:	40bc                	lw	a5,64(s1)
    8000310a:	cf81                	beqz	a5,80003122 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000310c:	64a4                	ld	s1,72(s1)
    8000310e:	fee49de3          	bne	s1,a4,80003108 <bread+0x86>
  panic("bget: no buffers");
    80003112:	00005517          	auipc	a0,0x5
    80003116:	44650513          	addi	a0,a0,1094 # 80008558 <syscalls+0xd0>
    8000311a:	ffffd097          	auipc	ra,0xffffd
    8000311e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      b->dev = dev;
    80003122:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003126:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000312a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000312e:	4785                	li	a5,1
    80003130:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003132:	00014517          	auipc	a0,0x14
    80003136:	fb650513          	addi	a0,a0,-74 # 800170e8 <bcache>
    8000313a:	ffffe097          	auipc	ra,0xffffe
    8000313e:	b5e080e7          	jalr	-1186(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003142:	01048513          	addi	a0,s1,16
    80003146:	00001097          	auipc	ra,0x1
    8000314a:	408080e7          	jalr	1032(ra) # 8000454e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000314e:	409c                	lw	a5,0(s1)
    80003150:	cb89                	beqz	a5,80003162 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003152:	8526                	mv	a0,s1
    80003154:	70a2                	ld	ra,40(sp)
    80003156:	7402                	ld	s0,32(sp)
    80003158:	64e2                	ld	s1,24(sp)
    8000315a:	6942                	ld	s2,16(sp)
    8000315c:	69a2                	ld	s3,8(sp)
    8000315e:	6145                	addi	sp,sp,48
    80003160:	8082                	ret
    virtio_disk_rw(b, 0);
    80003162:	4581                	li	a1,0
    80003164:	8526                	mv	a0,s1
    80003166:	00003097          	auipc	ra,0x3
    8000316a:	f10080e7          	jalr	-240(ra) # 80006076 <virtio_disk_rw>
    b->valid = 1;
    8000316e:	4785                	li	a5,1
    80003170:	c09c                	sw	a5,0(s1)
  return b;
    80003172:	b7c5                	j	80003152 <bread+0xd0>

0000000080003174 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003174:	1101                	addi	sp,sp,-32
    80003176:	ec06                	sd	ra,24(sp)
    80003178:	e822                	sd	s0,16(sp)
    8000317a:	e426                	sd	s1,8(sp)
    8000317c:	1000                	addi	s0,sp,32
    8000317e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003180:	0541                	addi	a0,a0,16
    80003182:	00001097          	auipc	ra,0x1
    80003186:	466080e7          	jalr	1126(ra) # 800045e8 <holdingsleep>
    8000318a:	cd01                	beqz	a0,800031a2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000318c:	4585                	li	a1,1
    8000318e:	8526                	mv	a0,s1
    80003190:	00003097          	auipc	ra,0x3
    80003194:	ee6080e7          	jalr	-282(ra) # 80006076 <virtio_disk_rw>
}
    80003198:	60e2                	ld	ra,24(sp)
    8000319a:	6442                	ld	s0,16(sp)
    8000319c:	64a2                	ld	s1,8(sp)
    8000319e:	6105                	addi	sp,sp,32
    800031a0:	8082                	ret
    panic("bwrite");
    800031a2:	00005517          	auipc	a0,0x5
    800031a6:	3ce50513          	addi	a0,a0,974 # 80008570 <syscalls+0xe8>
    800031aa:	ffffd097          	auipc	ra,0xffffd
    800031ae:	394080e7          	jalr	916(ra) # 8000053e <panic>

00000000800031b2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031b2:	1101                	addi	sp,sp,-32
    800031b4:	ec06                	sd	ra,24(sp)
    800031b6:	e822                	sd	s0,16(sp)
    800031b8:	e426                	sd	s1,8(sp)
    800031ba:	e04a                	sd	s2,0(sp)
    800031bc:	1000                	addi	s0,sp,32
    800031be:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031c0:	01050913          	addi	s2,a0,16
    800031c4:	854a                	mv	a0,s2
    800031c6:	00001097          	auipc	ra,0x1
    800031ca:	422080e7          	jalr	1058(ra) # 800045e8 <holdingsleep>
    800031ce:	c92d                	beqz	a0,80003240 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031d0:	854a                	mv	a0,s2
    800031d2:	00001097          	auipc	ra,0x1
    800031d6:	3d2080e7          	jalr	978(ra) # 800045a4 <releasesleep>

  acquire(&bcache.lock);
    800031da:	00014517          	auipc	a0,0x14
    800031de:	f0e50513          	addi	a0,a0,-242 # 800170e8 <bcache>
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	a02080e7          	jalr	-1534(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031ea:	40bc                	lw	a5,64(s1)
    800031ec:	37fd                	addiw	a5,a5,-1
    800031ee:	0007871b          	sext.w	a4,a5
    800031f2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031f4:	eb05                	bnez	a4,80003224 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031f6:	68bc                	ld	a5,80(s1)
    800031f8:	64b8                	ld	a4,72(s1)
    800031fa:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031fc:	64bc                	ld	a5,72(s1)
    800031fe:	68b8                	ld	a4,80(s1)
    80003200:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003202:	0001c797          	auipc	a5,0x1c
    80003206:	ee678793          	addi	a5,a5,-282 # 8001f0e8 <bcache+0x8000>
    8000320a:	2b87b703          	ld	a4,696(a5)
    8000320e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003210:	0001c717          	auipc	a4,0x1c
    80003214:	14070713          	addi	a4,a4,320 # 8001f350 <bcache+0x8268>
    80003218:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000321a:	2b87b703          	ld	a4,696(a5)
    8000321e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003220:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003224:	00014517          	auipc	a0,0x14
    80003228:	ec450513          	addi	a0,a0,-316 # 800170e8 <bcache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>
}
    80003234:	60e2                	ld	ra,24(sp)
    80003236:	6442                	ld	s0,16(sp)
    80003238:	64a2                	ld	s1,8(sp)
    8000323a:	6902                	ld	s2,0(sp)
    8000323c:	6105                	addi	sp,sp,32
    8000323e:	8082                	ret
    panic("brelse");
    80003240:	00005517          	auipc	a0,0x5
    80003244:	33850513          	addi	a0,a0,824 # 80008578 <syscalls+0xf0>
    80003248:	ffffd097          	auipc	ra,0xffffd
    8000324c:	2f6080e7          	jalr	758(ra) # 8000053e <panic>

0000000080003250 <bpin>:

void
bpin(struct buf *b) {
    80003250:	1101                	addi	sp,sp,-32
    80003252:	ec06                	sd	ra,24(sp)
    80003254:	e822                	sd	s0,16(sp)
    80003256:	e426                	sd	s1,8(sp)
    80003258:	1000                	addi	s0,sp,32
    8000325a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000325c:	00014517          	auipc	a0,0x14
    80003260:	e8c50513          	addi	a0,a0,-372 # 800170e8 <bcache>
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	980080e7          	jalr	-1664(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000326c:	40bc                	lw	a5,64(s1)
    8000326e:	2785                	addiw	a5,a5,1
    80003270:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003272:	00014517          	auipc	a0,0x14
    80003276:	e7650513          	addi	a0,a0,-394 # 800170e8 <bcache>
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	a1e080e7          	jalr	-1506(ra) # 80000c98 <release>
}
    80003282:	60e2                	ld	ra,24(sp)
    80003284:	6442                	ld	s0,16(sp)
    80003286:	64a2                	ld	s1,8(sp)
    80003288:	6105                	addi	sp,sp,32
    8000328a:	8082                	ret

000000008000328c <bunpin>:

void
bunpin(struct buf *b) {
    8000328c:	1101                	addi	sp,sp,-32
    8000328e:	ec06                	sd	ra,24(sp)
    80003290:	e822                	sd	s0,16(sp)
    80003292:	e426                	sd	s1,8(sp)
    80003294:	1000                	addi	s0,sp,32
    80003296:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003298:	00014517          	auipc	a0,0x14
    8000329c:	e5050513          	addi	a0,a0,-432 # 800170e8 <bcache>
    800032a0:	ffffe097          	auipc	ra,0xffffe
    800032a4:	944080e7          	jalr	-1724(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032a8:	40bc                	lw	a5,64(s1)
    800032aa:	37fd                	addiw	a5,a5,-1
    800032ac:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032ae:	00014517          	auipc	a0,0x14
    800032b2:	e3a50513          	addi	a0,a0,-454 # 800170e8 <bcache>
    800032b6:	ffffe097          	auipc	ra,0xffffe
    800032ba:	9e2080e7          	jalr	-1566(ra) # 80000c98 <release>
}
    800032be:	60e2                	ld	ra,24(sp)
    800032c0:	6442                	ld	s0,16(sp)
    800032c2:	64a2                	ld	s1,8(sp)
    800032c4:	6105                	addi	sp,sp,32
    800032c6:	8082                	ret

00000000800032c8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032c8:	1101                	addi	sp,sp,-32
    800032ca:	ec06                	sd	ra,24(sp)
    800032cc:	e822                	sd	s0,16(sp)
    800032ce:	e426                	sd	s1,8(sp)
    800032d0:	e04a                	sd	s2,0(sp)
    800032d2:	1000                	addi	s0,sp,32
    800032d4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032d6:	00d5d59b          	srliw	a1,a1,0xd
    800032da:	0001c797          	auipc	a5,0x1c
    800032de:	4ea7a783          	lw	a5,1258(a5) # 8001f7c4 <sb+0x1c>
    800032e2:	9dbd                	addw	a1,a1,a5
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	d9e080e7          	jalr	-610(ra) # 80003082 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032ec:	0074f713          	andi	a4,s1,7
    800032f0:	4785                	li	a5,1
    800032f2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032f6:	14ce                	slli	s1,s1,0x33
    800032f8:	90d9                	srli	s1,s1,0x36
    800032fa:	00950733          	add	a4,a0,s1
    800032fe:	05874703          	lbu	a4,88(a4)
    80003302:	00e7f6b3          	and	a3,a5,a4
    80003306:	c69d                	beqz	a3,80003334 <bfree+0x6c>
    80003308:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000330a:	94aa                	add	s1,s1,a0
    8000330c:	fff7c793          	not	a5,a5
    80003310:	8ff9                	and	a5,a5,a4
    80003312:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	118080e7          	jalr	280(ra) # 8000442e <log_write>
  brelse(bp);
    8000331e:	854a                	mv	a0,s2
    80003320:	00000097          	auipc	ra,0x0
    80003324:	e92080e7          	jalr	-366(ra) # 800031b2 <brelse>
}
    80003328:	60e2                	ld	ra,24(sp)
    8000332a:	6442                	ld	s0,16(sp)
    8000332c:	64a2                	ld	s1,8(sp)
    8000332e:	6902                	ld	s2,0(sp)
    80003330:	6105                	addi	sp,sp,32
    80003332:	8082                	ret
    panic("freeing free block");
    80003334:	00005517          	auipc	a0,0x5
    80003338:	24c50513          	addi	a0,a0,588 # 80008580 <syscalls+0xf8>
    8000333c:	ffffd097          	auipc	ra,0xffffd
    80003340:	202080e7          	jalr	514(ra) # 8000053e <panic>

0000000080003344 <balloc>:
{
    80003344:	711d                	addi	sp,sp,-96
    80003346:	ec86                	sd	ra,88(sp)
    80003348:	e8a2                	sd	s0,80(sp)
    8000334a:	e4a6                	sd	s1,72(sp)
    8000334c:	e0ca                	sd	s2,64(sp)
    8000334e:	fc4e                	sd	s3,56(sp)
    80003350:	f852                	sd	s4,48(sp)
    80003352:	f456                	sd	s5,40(sp)
    80003354:	f05a                	sd	s6,32(sp)
    80003356:	ec5e                	sd	s7,24(sp)
    80003358:	e862                	sd	s8,16(sp)
    8000335a:	e466                	sd	s9,8(sp)
    8000335c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000335e:	0001c797          	auipc	a5,0x1c
    80003362:	44e7a783          	lw	a5,1102(a5) # 8001f7ac <sb+0x4>
    80003366:	cbd1                	beqz	a5,800033fa <balloc+0xb6>
    80003368:	8baa                	mv	s7,a0
    8000336a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000336c:	0001cb17          	auipc	s6,0x1c
    80003370:	43cb0b13          	addi	s6,s6,1084 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003374:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003376:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003378:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000337a:	6c89                	lui	s9,0x2
    8000337c:	a831                	j	80003398 <balloc+0x54>
    brelse(bp);
    8000337e:	854a                	mv	a0,s2
    80003380:	00000097          	auipc	ra,0x0
    80003384:	e32080e7          	jalr	-462(ra) # 800031b2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003388:	015c87bb          	addw	a5,s9,s5
    8000338c:	00078a9b          	sext.w	s5,a5
    80003390:	004b2703          	lw	a4,4(s6)
    80003394:	06eaf363          	bgeu	s5,a4,800033fa <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003398:	41fad79b          	sraiw	a5,s5,0x1f
    8000339c:	0137d79b          	srliw	a5,a5,0x13
    800033a0:	015787bb          	addw	a5,a5,s5
    800033a4:	40d7d79b          	sraiw	a5,a5,0xd
    800033a8:	01cb2583          	lw	a1,28(s6)
    800033ac:	9dbd                	addw	a1,a1,a5
    800033ae:	855e                	mv	a0,s7
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	cd2080e7          	jalr	-814(ra) # 80003082 <bread>
    800033b8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ba:	004b2503          	lw	a0,4(s6)
    800033be:	000a849b          	sext.w	s1,s5
    800033c2:	8662                	mv	a2,s8
    800033c4:	faa4fde3          	bgeu	s1,a0,8000337e <balloc+0x3a>
      m = 1 << (bi % 8);
    800033c8:	41f6579b          	sraiw	a5,a2,0x1f
    800033cc:	01d7d69b          	srliw	a3,a5,0x1d
    800033d0:	00c6873b          	addw	a4,a3,a2
    800033d4:	00777793          	andi	a5,a4,7
    800033d8:	9f95                	subw	a5,a5,a3
    800033da:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033de:	4037571b          	sraiw	a4,a4,0x3
    800033e2:	00e906b3          	add	a3,s2,a4
    800033e6:	0586c683          	lbu	a3,88(a3)
    800033ea:	00d7f5b3          	and	a1,a5,a3
    800033ee:	cd91                	beqz	a1,8000340a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f0:	2605                	addiw	a2,a2,1
    800033f2:	2485                	addiw	s1,s1,1
    800033f4:	fd4618e3          	bne	a2,s4,800033c4 <balloc+0x80>
    800033f8:	b759                	j	8000337e <balloc+0x3a>
  panic("balloc: out of blocks");
    800033fa:	00005517          	auipc	a0,0x5
    800033fe:	19e50513          	addi	a0,a0,414 # 80008598 <syscalls+0x110>
    80003402:	ffffd097          	auipc	ra,0xffffd
    80003406:	13c080e7          	jalr	316(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000340a:	974a                	add	a4,a4,s2
    8000340c:	8fd5                	or	a5,a5,a3
    8000340e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003412:	854a                	mv	a0,s2
    80003414:	00001097          	auipc	ra,0x1
    80003418:	01a080e7          	jalr	26(ra) # 8000442e <log_write>
        brelse(bp);
    8000341c:	854a                	mv	a0,s2
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	d94080e7          	jalr	-620(ra) # 800031b2 <brelse>
  bp = bread(dev, bno);
    80003426:	85a6                	mv	a1,s1
    80003428:	855e                	mv	a0,s7
    8000342a:	00000097          	auipc	ra,0x0
    8000342e:	c58080e7          	jalr	-936(ra) # 80003082 <bread>
    80003432:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003434:	40000613          	li	a2,1024
    80003438:	4581                	li	a1,0
    8000343a:	05850513          	addi	a0,a0,88
    8000343e:	ffffe097          	auipc	ra,0xffffe
    80003442:	8a2080e7          	jalr	-1886(ra) # 80000ce0 <memset>
  log_write(bp);
    80003446:	854a                	mv	a0,s2
    80003448:	00001097          	auipc	ra,0x1
    8000344c:	fe6080e7          	jalr	-26(ra) # 8000442e <log_write>
  brelse(bp);
    80003450:	854a                	mv	a0,s2
    80003452:	00000097          	auipc	ra,0x0
    80003456:	d60080e7          	jalr	-672(ra) # 800031b2 <brelse>
}
    8000345a:	8526                	mv	a0,s1
    8000345c:	60e6                	ld	ra,88(sp)
    8000345e:	6446                	ld	s0,80(sp)
    80003460:	64a6                	ld	s1,72(sp)
    80003462:	6906                	ld	s2,64(sp)
    80003464:	79e2                	ld	s3,56(sp)
    80003466:	7a42                	ld	s4,48(sp)
    80003468:	7aa2                	ld	s5,40(sp)
    8000346a:	7b02                	ld	s6,32(sp)
    8000346c:	6be2                	ld	s7,24(sp)
    8000346e:	6c42                	ld	s8,16(sp)
    80003470:	6ca2                	ld	s9,8(sp)
    80003472:	6125                	addi	sp,sp,96
    80003474:	8082                	ret

0000000080003476 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003476:	7179                	addi	sp,sp,-48
    80003478:	f406                	sd	ra,40(sp)
    8000347a:	f022                	sd	s0,32(sp)
    8000347c:	ec26                	sd	s1,24(sp)
    8000347e:	e84a                	sd	s2,16(sp)
    80003480:	e44e                	sd	s3,8(sp)
    80003482:	e052                	sd	s4,0(sp)
    80003484:	1800                	addi	s0,sp,48
    80003486:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003488:	47ad                	li	a5,11
    8000348a:	04b7fe63          	bgeu	a5,a1,800034e6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000348e:	ff45849b          	addiw	s1,a1,-12
    80003492:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003496:	0ff00793          	li	a5,255
    8000349a:	0ae7e363          	bltu	a5,a4,80003540 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000349e:	08052583          	lw	a1,128(a0)
    800034a2:	c5ad                	beqz	a1,8000350c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034a4:	00092503          	lw	a0,0(s2)
    800034a8:	00000097          	auipc	ra,0x0
    800034ac:	bda080e7          	jalr	-1062(ra) # 80003082 <bread>
    800034b0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034b2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034b6:	02049593          	slli	a1,s1,0x20
    800034ba:	9181                	srli	a1,a1,0x20
    800034bc:	058a                	slli	a1,a1,0x2
    800034be:	00b784b3          	add	s1,a5,a1
    800034c2:	0004a983          	lw	s3,0(s1)
    800034c6:	04098d63          	beqz	s3,80003520 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034ca:	8552                	mv	a0,s4
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	ce6080e7          	jalr	-794(ra) # 800031b2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034d4:	854e                	mv	a0,s3
    800034d6:	70a2                	ld	ra,40(sp)
    800034d8:	7402                	ld	s0,32(sp)
    800034da:	64e2                	ld	s1,24(sp)
    800034dc:	6942                	ld	s2,16(sp)
    800034de:	69a2                	ld	s3,8(sp)
    800034e0:	6a02                	ld	s4,0(sp)
    800034e2:	6145                	addi	sp,sp,48
    800034e4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034e6:	02059493          	slli	s1,a1,0x20
    800034ea:	9081                	srli	s1,s1,0x20
    800034ec:	048a                	slli	s1,s1,0x2
    800034ee:	94aa                	add	s1,s1,a0
    800034f0:	0504a983          	lw	s3,80(s1)
    800034f4:	fe0990e3          	bnez	s3,800034d4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034f8:	4108                	lw	a0,0(a0)
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	e4a080e7          	jalr	-438(ra) # 80003344 <balloc>
    80003502:	0005099b          	sext.w	s3,a0
    80003506:	0534a823          	sw	s3,80(s1)
    8000350a:	b7e9                	j	800034d4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000350c:	4108                	lw	a0,0(a0)
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	e36080e7          	jalr	-458(ra) # 80003344 <balloc>
    80003516:	0005059b          	sext.w	a1,a0
    8000351a:	08b92023          	sw	a1,128(s2)
    8000351e:	b759                	j	800034a4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003520:	00092503          	lw	a0,0(s2)
    80003524:	00000097          	auipc	ra,0x0
    80003528:	e20080e7          	jalr	-480(ra) # 80003344 <balloc>
    8000352c:	0005099b          	sext.w	s3,a0
    80003530:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003534:	8552                	mv	a0,s4
    80003536:	00001097          	auipc	ra,0x1
    8000353a:	ef8080e7          	jalr	-264(ra) # 8000442e <log_write>
    8000353e:	b771                	j	800034ca <bmap+0x54>
  panic("bmap: out of range");
    80003540:	00005517          	auipc	a0,0x5
    80003544:	07050513          	addi	a0,a0,112 # 800085b0 <syscalls+0x128>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	ff6080e7          	jalr	-10(ra) # 8000053e <panic>

0000000080003550 <iget>:
{
    80003550:	7179                	addi	sp,sp,-48
    80003552:	f406                	sd	ra,40(sp)
    80003554:	f022                	sd	s0,32(sp)
    80003556:	ec26                	sd	s1,24(sp)
    80003558:	e84a                	sd	s2,16(sp)
    8000355a:	e44e                	sd	s3,8(sp)
    8000355c:	e052                	sd	s4,0(sp)
    8000355e:	1800                	addi	s0,sp,48
    80003560:	89aa                	mv	s3,a0
    80003562:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003564:	0001c517          	auipc	a0,0x1c
    80003568:	26450513          	addi	a0,a0,612 # 8001f7c8 <itable>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	678080e7          	jalr	1656(ra) # 80000be4 <acquire>
  empty = 0;
    80003574:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003576:	0001c497          	auipc	s1,0x1c
    8000357a:	26a48493          	addi	s1,s1,618 # 8001f7e0 <itable+0x18>
    8000357e:	0001e697          	auipc	a3,0x1e
    80003582:	cf268693          	addi	a3,a3,-782 # 80021270 <log>
    80003586:	a039                	j	80003594 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003588:	02090b63          	beqz	s2,800035be <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000358c:	08848493          	addi	s1,s1,136
    80003590:	02d48a63          	beq	s1,a3,800035c4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003594:	449c                	lw	a5,8(s1)
    80003596:	fef059e3          	blez	a5,80003588 <iget+0x38>
    8000359a:	4098                	lw	a4,0(s1)
    8000359c:	ff3716e3          	bne	a4,s3,80003588 <iget+0x38>
    800035a0:	40d8                	lw	a4,4(s1)
    800035a2:	ff4713e3          	bne	a4,s4,80003588 <iget+0x38>
      ip->ref++;
    800035a6:	2785                	addiw	a5,a5,1
    800035a8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035aa:	0001c517          	auipc	a0,0x1c
    800035ae:	21e50513          	addi	a0,a0,542 # 8001f7c8 <itable>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	6e6080e7          	jalr	1766(ra) # 80000c98 <release>
      return ip;
    800035ba:	8926                	mv	s2,s1
    800035bc:	a03d                	j	800035ea <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035be:	f7f9                	bnez	a5,8000358c <iget+0x3c>
    800035c0:	8926                	mv	s2,s1
    800035c2:	b7e9                	j	8000358c <iget+0x3c>
  if(empty == 0)
    800035c4:	02090c63          	beqz	s2,800035fc <iget+0xac>
  ip->dev = dev;
    800035c8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035cc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035d0:	4785                	li	a5,1
    800035d2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035d6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035da:	0001c517          	auipc	a0,0x1c
    800035de:	1ee50513          	addi	a0,a0,494 # 8001f7c8 <itable>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	6b6080e7          	jalr	1718(ra) # 80000c98 <release>
}
    800035ea:	854a                	mv	a0,s2
    800035ec:	70a2                	ld	ra,40(sp)
    800035ee:	7402                	ld	s0,32(sp)
    800035f0:	64e2                	ld	s1,24(sp)
    800035f2:	6942                	ld	s2,16(sp)
    800035f4:	69a2                	ld	s3,8(sp)
    800035f6:	6a02                	ld	s4,0(sp)
    800035f8:	6145                	addi	sp,sp,48
    800035fa:	8082                	ret
    panic("iget: no inodes");
    800035fc:	00005517          	auipc	a0,0x5
    80003600:	fcc50513          	addi	a0,a0,-52 # 800085c8 <syscalls+0x140>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	f3a080e7          	jalr	-198(ra) # 8000053e <panic>

000000008000360c <fsinit>:
fsinit(int dev) {
    8000360c:	7179                	addi	sp,sp,-48
    8000360e:	f406                	sd	ra,40(sp)
    80003610:	f022                	sd	s0,32(sp)
    80003612:	ec26                	sd	s1,24(sp)
    80003614:	e84a                	sd	s2,16(sp)
    80003616:	e44e                	sd	s3,8(sp)
    80003618:	1800                	addi	s0,sp,48
    8000361a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000361c:	4585                	li	a1,1
    8000361e:	00000097          	auipc	ra,0x0
    80003622:	a64080e7          	jalr	-1436(ra) # 80003082 <bread>
    80003626:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003628:	0001c997          	auipc	s3,0x1c
    8000362c:	18098993          	addi	s3,s3,384 # 8001f7a8 <sb>
    80003630:	02000613          	li	a2,32
    80003634:	05850593          	addi	a1,a0,88
    80003638:	854e                	mv	a0,s3
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	706080e7          	jalr	1798(ra) # 80000d40 <memmove>
  brelse(bp);
    80003642:	8526                	mv	a0,s1
    80003644:	00000097          	auipc	ra,0x0
    80003648:	b6e080e7          	jalr	-1170(ra) # 800031b2 <brelse>
  if(sb.magic != FSMAGIC)
    8000364c:	0009a703          	lw	a4,0(s3)
    80003650:	102037b7          	lui	a5,0x10203
    80003654:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003658:	02f71263          	bne	a4,a5,8000367c <fsinit+0x70>
  initlog(dev, &sb);
    8000365c:	0001c597          	auipc	a1,0x1c
    80003660:	14c58593          	addi	a1,a1,332 # 8001f7a8 <sb>
    80003664:	854a                	mv	a0,s2
    80003666:	00001097          	auipc	ra,0x1
    8000366a:	b4c080e7          	jalr	-1204(ra) # 800041b2 <initlog>
}
    8000366e:	70a2                	ld	ra,40(sp)
    80003670:	7402                	ld	s0,32(sp)
    80003672:	64e2                	ld	s1,24(sp)
    80003674:	6942                	ld	s2,16(sp)
    80003676:	69a2                	ld	s3,8(sp)
    80003678:	6145                	addi	sp,sp,48
    8000367a:	8082                	ret
    panic("invalid file system");
    8000367c:	00005517          	auipc	a0,0x5
    80003680:	f5c50513          	addi	a0,a0,-164 # 800085d8 <syscalls+0x150>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	eba080e7          	jalr	-326(ra) # 8000053e <panic>

000000008000368c <iinit>:
{
    8000368c:	7179                	addi	sp,sp,-48
    8000368e:	f406                	sd	ra,40(sp)
    80003690:	f022                	sd	s0,32(sp)
    80003692:	ec26                	sd	s1,24(sp)
    80003694:	e84a                	sd	s2,16(sp)
    80003696:	e44e                	sd	s3,8(sp)
    80003698:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000369a:	00005597          	auipc	a1,0x5
    8000369e:	f5658593          	addi	a1,a1,-170 # 800085f0 <syscalls+0x168>
    800036a2:	0001c517          	auipc	a0,0x1c
    800036a6:	12650513          	addi	a0,a0,294 # 8001f7c8 <itable>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	4aa080e7          	jalr	1194(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036b2:	0001c497          	auipc	s1,0x1c
    800036b6:	13e48493          	addi	s1,s1,318 # 8001f7f0 <itable+0x28>
    800036ba:	0001e997          	auipc	s3,0x1e
    800036be:	bc698993          	addi	s3,s3,-1082 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036c2:	00005917          	auipc	s2,0x5
    800036c6:	f3690913          	addi	s2,s2,-202 # 800085f8 <syscalls+0x170>
    800036ca:	85ca                	mv	a1,s2
    800036cc:	8526                	mv	a0,s1
    800036ce:	00001097          	auipc	ra,0x1
    800036d2:	e46080e7          	jalr	-442(ra) # 80004514 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036d6:	08848493          	addi	s1,s1,136
    800036da:	ff3498e3          	bne	s1,s3,800036ca <iinit+0x3e>
}
    800036de:	70a2                	ld	ra,40(sp)
    800036e0:	7402                	ld	s0,32(sp)
    800036e2:	64e2                	ld	s1,24(sp)
    800036e4:	6942                	ld	s2,16(sp)
    800036e6:	69a2                	ld	s3,8(sp)
    800036e8:	6145                	addi	sp,sp,48
    800036ea:	8082                	ret

00000000800036ec <ialloc>:
{
    800036ec:	715d                	addi	sp,sp,-80
    800036ee:	e486                	sd	ra,72(sp)
    800036f0:	e0a2                	sd	s0,64(sp)
    800036f2:	fc26                	sd	s1,56(sp)
    800036f4:	f84a                	sd	s2,48(sp)
    800036f6:	f44e                	sd	s3,40(sp)
    800036f8:	f052                	sd	s4,32(sp)
    800036fa:	ec56                	sd	s5,24(sp)
    800036fc:	e85a                	sd	s6,16(sp)
    800036fe:	e45e                	sd	s7,8(sp)
    80003700:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003702:	0001c717          	auipc	a4,0x1c
    80003706:	0b272703          	lw	a4,178(a4) # 8001f7b4 <sb+0xc>
    8000370a:	4785                	li	a5,1
    8000370c:	04e7fa63          	bgeu	a5,a4,80003760 <ialloc+0x74>
    80003710:	8aaa                	mv	s5,a0
    80003712:	8bae                	mv	s7,a1
    80003714:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003716:	0001ca17          	auipc	s4,0x1c
    8000371a:	092a0a13          	addi	s4,s4,146 # 8001f7a8 <sb>
    8000371e:	00048b1b          	sext.w	s6,s1
    80003722:	0044d593          	srli	a1,s1,0x4
    80003726:	018a2783          	lw	a5,24(s4)
    8000372a:	9dbd                	addw	a1,a1,a5
    8000372c:	8556                	mv	a0,s5
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	954080e7          	jalr	-1708(ra) # 80003082 <bread>
    80003736:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003738:	05850993          	addi	s3,a0,88
    8000373c:	00f4f793          	andi	a5,s1,15
    80003740:	079a                	slli	a5,a5,0x6
    80003742:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003744:	00099783          	lh	a5,0(s3)
    80003748:	c785                	beqz	a5,80003770 <ialloc+0x84>
    brelse(bp);
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	a68080e7          	jalr	-1432(ra) # 800031b2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003752:	0485                	addi	s1,s1,1
    80003754:	00ca2703          	lw	a4,12(s4)
    80003758:	0004879b          	sext.w	a5,s1
    8000375c:	fce7e1e3          	bltu	a5,a4,8000371e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003760:	00005517          	auipc	a0,0x5
    80003764:	ea050513          	addi	a0,a0,-352 # 80008600 <syscalls+0x178>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	dd6080e7          	jalr	-554(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003770:	04000613          	li	a2,64
    80003774:	4581                	li	a1,0
    80003776:	854e                	mv	a0,s3
    80003778:	ffffd097          	auipc	ra,0xffffd
    8000377c:	568080e7          	jalr	1384(ra) # 80000ce0 <memset>
      dip->type = type;
    80003780:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003784:	854a                	mv	a0,s2
    80003786:	00001097          	auipc	ra,0x1
    8000378a:	ca8080e7          	jalr	-856(ra) # 8000442e <log_write>
      brelse(bp);
    8000378e:	854a                	mv	a0,s2
    80003790:	00000097          	auipc	ra,0x0
    80003794:	a22080e7          	jalr	-1502(ra) # 800031b2 <brelse>
      return iget(dev, inum);
    80003798:	85da                	mv	a1,s6
    8000379a:	8556                	mv	a0,s5
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	db4080e7          	jalr	-588(ra) # 80003550 <iget>
}
    800037a4:	60a6                	ld	ra,72(sp)
    800037a6:	6406                	ld	s0,64(sp)
    800037a8:	74e2                	ld	s1,56(sp)
    800037aa:	7942                	ld	s2,48(sp)
    800037ac:	79a2                	ld	s3,40(sp)
    800037ae:	7a02                	ld	s4,32(sp)
    800037b0:	6ae2                	ld	s5,24(sp)
    800037b2:	6b42                	ld	s6,16(sp)
    800037b4:	6ba2                	ld	s7,8(sp)
    800037b6:	6161                	addi	sp,sp,80
    800037b8:	8082                	ret

00000000800037ba <iupdate>:
{
    800037ba:	1101                	addi	sp,sp,-32
    800037bc:	ec06                	sd	ra,24(sp)
    800037be:	e822                	sd	s0,16(sp)
    800037c0:	e426                	sd	s1,8(sp)
    800037c2:	e04a                	sd	s2,0(sp)
    800037c4:	1000                	addi	s0,sp,32
    800037c6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037c8:	415c                	lw	a5,4(a0)
    800037ca:	0047d79b          	srliw	a5,a5,0x4
    800037ce:	0001c597          	auipc	a1,0x1c
    800037d2:	ff25a583          	lw	a1,-14(a1) # 8001f7c0 <sb+0x18>
    800037d6:	9dbd                	addw	a1,a1,a5
    800037d8:	4108                	lw	a0,0(a0)
    800037da:	00000097          	auipc	ra,0x0
    800037de:	8a8080e7          	jalr	-1880(ra) # 80003082 <bread>
    800037e2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037e4:	05850793          	addi	a5,a0,88
    800037e8:	40c8                	lw	a0,4(s1)
    800037ea:	893d                	andi	a0,a0,15
    800037ec:	051a                	slli	a0,a0,0x6
    800037ee:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037f0:	04449703          	lh	a4,68(s1)
    800037f4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037f8:	04649703          	lh	a4,70(s1)
    800037fc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003800:	04849703          	lh	a4,72(s1)
    80003804:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003808:	04a49703          	lh	a4,74(s1)
    8000380c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003810:	44f8                	lw	a4,76(s1)
    80003812:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003814:	03400613          	li	a2,52
    80003818:	05048593          	addi	a1,s1,80
    8000381c:	0531                	addi	a0,a0,12
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	522080e7          	jalr	1314(ra) # 80000d40 <memmove>
  log_write(bp);
    80003826:	854a                	mv	a0,s2
    80003828:	00001097          	auipc	ra,0x1
    8000382c:	c06080e7          	jalr	-1018(ra) # 8000442e <log_write>
  brelse(bp);
    80003830:	854a                	mv	a0,s2
    80003832:	00000097          	auipc	ra,0x0
    80003836:	980080e7          	jalr	-1664(ra) # 800031b2 <brelse>
}
    8000383a:	60e2                	ld	ra,24(sp)
    8000383c:	6442                	ld	s0,16(sp)
    8000383e:	64a2                	ld	s1,8(sp)
    80003840:	6902                	ld	s2,0(sp)
    80003842:	6105                	addi	sp,sp,32
    80003844:	8082                	ret

0000000080003846 <idup>:
{
    80003846:	1101                	addi	sp,sp,-32
    80003848:	ec06                	sd	ra,24(sp)
    8000384a:	e822                	sd	s0,16(sp)
    8000384c:	e426                	sd	s1,8(sp)
    8000384e:	1000                	addi	s0,sp,32
    80003850:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003852:	0001c517          	auipc	a0,0x1c
    80003856:	f7650513          	addi	a0,a0,-138 # 8001f7c8 <itable>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	38a080e7          	jalr	906(ra) # 80000be4 <acquire>
  ip->ref++;
    80003862:	449c                	lw	a5,8(s1)
    80003864:	2785                	addiw	a5,a5,1
    80003866:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003868:	0001c517          	auipc	a0,0x1c
    8000386c:	f6050513          	addi	a0,a0,-160 # 8001f7c8 <itable>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	428080e7          	jalr	1064(ra) # 80000c98 <release>
}
    80003878:	8526                	mv	a0,s1
    8000387a:	60e2                	ld	ra,24(sp)
    8000387c:	6442                	ld	s0,16(sp)
    8000387e:	64a2                	ld	s1,8(sp)
    80003880:	6105                	addi	sp,sp,32
    80003882:	8082                	ret

0000000080003884 <ilock>:
{
    80003884:	1101                	addi	sp,sp,-32
    80003886:	ec06                	sd	ra,24(sp)
    80003888:	e822                	sd	s0,16(sp)
    8000388a:	e426                	sd	s1,8(sp)
    8000388c:	e04a                	sd	s2,0(sp)
    8000388e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003890:	c115                	beqz	a0,800038b4 <ilock+0x30>
    80003892:	84aa                	mv	s1,a0
    80003894:	451c                	lw	a5,8(a0)
    80003896:	00f05f63          	blez	a5,800038b4 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000389a:	0541                	addi	a0,a0,16
    8000389c:	00001097          	auipc	ra,0x1
    800038a0:	cb2080e7          	jalr	-846(ra) # 8000454e <acquiresleep>
  if(ip->valid == 0){
    800038a4:	40bc                	lw	a5,64(s1)
    800038a6:	cf99                	beqz	a5,800038c4 <ilock+0x40>
}
    800038a8:	60e2                	ld	ra,24(sp)
    800038aa:	6442                	ld	s0,16(sp)
    800038ac:	64a2                	ld	s1,8(sp)
    800038ae:	6902                	ld	s2,0(sp)
    800038b0:	6105                	addi	sp,sp,32
    800038b2:	8082                	ret
    panic("ilock");
    800038b4:	00005517          	auipc	a0,0x5
    800038b8:	d6450513          	addi	a0,a0,-668 # 80008618 <syscalls+0x190>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	c82080e7          	jalr	-894(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038c4:	40dc                	lw	a5,4(s1)
    800038c6:	0047d79b          	srliw	a5,a5,0x4
    800038ca:	0001c597          	auipc	a1,0x1c
    800038ce:	ef65a583          	lw	a1,-266(a1) # 8001f7c0 <sb+0x18>
    800038d2:	9dbd                	addw	a1,a1,a5
    800038d4:	4088                	lw	a0,0(s1)
    800038d6:	fffff097          	auipc	ra,0xfffff
    800038da:	7ac080e7          	jalr	1964(ra) # 80003082 <bread>
    800038de:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e0:	05850593          	addi	a1,a0,88
    800038e4:	40dc                	lw	a5,4(s1)
    800038e6:	8bbd                	andi	a5,a5,15
    800038e8:	079a                	slli	a5,a5,0x6
    800038ea:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038ec:	00059783          	lh	a5,0(a1)
    800038f0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038f4:	00259783          	lh	a5,2(a1)
    800038f8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038fc:	00459783          	lh	a5,4(a1)
    80003900:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003904:	00659783          	lh	a5,6(a1)
    80003908:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000390c:	459c                	lw	a5,8(a1)
    8000390e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003910:	03400613          	li	a2,52
    80003914:	05b1                	addi	a1,a1,12
    80003916:	05048513          	addi	a0,s1,80
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	426080e7          	jalr	1062(ra) # 80000d40 <memmove>
    brelse(bp);
    80003922:	854a                	mv	a0,s2
    80003924:	00000097          	auipc	ra,0x0
    80003928:	88e080e7          	jalr	-1906(ra) # 800031b2 <brelse>
    ip->valid = 1;
    8000392c:	4785                	li	a5,1
    8000392e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003930:	04449783          	lh	a5,68(s1)
    80003934:	fbb5                	bnez	a5,800038a8 <ilock+0x24>
      panic("ilock: no type");
    80003936:	00005517          	auipc	a0,0x5
    8000393a:	cea50513          	addi	a0,a0,-790 # 80008620 <syscalls+0x198>
    8000393e:	ffffd097          	auipc	ra,0xffffd
    80003942:	c00080e7          	jalr	-1024(ra) # 8000053e <panic>

0000000080003946 <iunlock>:
{
    80003946:	1101                	addi	sp,sp,-32
    80003948:	ec06                	sd	ra,24(sp)
    8000394a:	e822                	sd	s0,16(sp)
    8000394c:	e426                	sd	s1,8(sp)
    8000394e:	e04a                	sd	s2,0(sp)
    80003950:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003952:	c905                	beqz	a0,80003982 <iunlock+0x3c>
    80003954:	84aa                	mv	s1,a0
    80003956:	01050913          	addi	s2,a0,16
    8000395a:	854a                	mv	a0,s2
    8000395c:	00001097          	auipc	ra,0x1
    80003960:	c8c080e7          	jalr	-884(ra) # 800045e8 <holdingsleep>
    80003964:	cd19                	beqz	a0,80003982 <iunlock+0x3c>
    80003966:	449c                	lw	a5,8(s1)
    80003968:	00f05d63          	blez	a5,80003982 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000396c:	854a                	mv	a0,s2
    8000396e:	00001097          	auipc	ra,0x1
    80003972:	c36080e7          	jalr	-970(ra) # 800045a4 <releasesleep>
}
    80003976:	60e2                	ld	ra,24(sp)
    80003978:	6442                	ld	s0,16(sp)
    8000397a:	64a2                	ld	s1,8(sp)
    8000397c:	6902                	ld	s2,0(sp)
    8000397e:	6105                	addi	sp,sp,32
    80003980:	8082                	ret
    panic("iunlock");
    80003982:	00005517          	auipc	a0,0x5
    80003986:	cae50513          	addi	a0,a0,-850 # 80008630 <syscalls+0x1a8>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	bb4080e7          	jalr	-1100(ra) # 8000053e <panic>

0000000080003992 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003992:	7179                	addi	sp,sp,-48
    80003994:	f406                	sd	ra,40(sp)
    80003996:	f022                	sd	s0,32(sp)
    80003998:	ec26                	sd	s1,24(sp)
    8000399a:	e84a                	sd	s2,16(sp)
    8000399c:	e44e                	sd	s3,8(sp)
    8000399e:	e052                	sd	s4,0(sp)
    800039a0:	1800                	addi	s0,sp,48
    800039a2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039a4:	05050493          	addi	s1,a0,80
    800039a8:	08050913          	addi	s2,a0,128
    800039ac:	a021                	j	800039b4 <itrunc+0x22>
    800039ae:	0491                	addi	s1,s1,4
    800039b0:	01248d63          	beq	s1,s2,800039ca <itrunc+0x38>
    if(ip->addrs[i]){
    800039b4:	408c                	lw	a1,0(s1)
    800039b6:	dde5                	beqz	a1,800039ae <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039b8:	0009a503          	lw	a0,0(s3)
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	90c080e7          	jalr	-1780(ra) # 800032c8 <bfree>
      ip->addrs[i] = 0;
    800039c4:	0004a023          	sw	zero,0(s1)
    800039c8:	b7dd                	j	800039ae <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039ca:	0809a583          	lw	a1,128(s3)
    800039ce:	e185                	bnez	a1,800039ee <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039d0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039d4:	854e                	mv	a0,s3
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	de4080e7          	jalr	-540(ra) # 800037ba <iupdate>
}
    800039de:	70a2                	ld	ra,40(sp)
    800039e0:	7402                	ld	s0,32(sp)
    800039e2:	64e2                	ld	s1,24(sp)
    800039e4:	6942                	ld	s2,16(sp)
    800039e6:	69a2                	ld	s3,8(sp)
    800039e8:	6a02                	ld	s4,0(sp)
    800039ea:	6145                	addi	sp,sp,48
    800039ec:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039ee:	0009a503          	lw	a0,0(s3)
    800039f2:	fffff097          	auipc	ra,0xfffff
    800039f6:	690080e7          	jalr	1680(ra) # 80003082 <bread>
    800039fa:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039fc:	05850493          	addi	s1,a0,88
    80003a00:	45850913          	addi	s2,a0,1112
    80003a04:	a811                	j	80003a18 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a06:	0009a503          	lw	a0,0(s3)
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	8be080e7          	jalr	-1858(ra) # 800032c8 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a12:	0491                	addi	s1,s1,4
    80003a14:	01248563          	beq	s1,s2,80003a1e <itrunc+0x8c>
      if(a[j])
    80003a18:	408c                	lw	a1,0(s1)
    80003a1a:	dde5                	beqz	a1,80003a12 <itrunc+0x80>
    80003a1c:	b7ed                	j	80003a06 <itrunc+0x74>
    brelse(bp);
    80003a1e:	8552                	mv	a0,s4
    80003a20:	fffff097          	auipc	ra,0xfffff
    80003a24:	792080e7          	jalr	1938(ra) # 800031b2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a28:	0809a583          	lw	a1,128(s3)
    80003a2c:	0009a503          	lw	a0,0(s3)
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	898080e7          	jalr	-1896(ra) # 800032c8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a38:	0809a023          	sw	zero,128(s3)
    80003a3c:	bf51                	j	800039d0 <itrunc+0x3e>

0000000080003a3e <iput>:
{
    80003a3e:	1101                	addi	sp,sp,-32
    80003a40:	ec06                	sd	ra,24(sp)
    80003a42:	e822                	sd	s0,16(sp)
    80003a44:	e426                	sd	s1,8(sp)
    80003a46:	e04a                	sd	s2,0(sp)
    80003a48:	1000                	addi	s0,sp,32
    80003a4a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a4c:	0001c517          	auipc	a0,0x1c
    80003a50:	d7c50513          	addi	a0,a0,-644 # 8001f7c8 <itable>
    80003a54:	ffffd097          	auipc	ra,0xffffd
    80003a58:	190080e7          	jalr	400(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a5c:	4498                	lw	a4,8(s1)
    80003a5e:	4785                	li	a5,1
    80003a60:	02f70363          	beq	a4,a5,80003a86 <iput+0x48>
  ip->ref--;
    80003a64:	449c                	lw	a5,8(s1)
    80003a66:	37fd                	addiw	a5,a5,-1
    80003a68:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a6a:	0001c517          	auipc	a0,0x1c
    80003a6e:	d5e50513          	addi	a0,a0,-674 # 8001f7c8 <itable>
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	226080e7          	jalr	550(ra) # 80000c98 <release>
}
    80003a7a:	60e2                	ld	ra,24(sp)
    80003a7c:	6442                	ld	s0,16(sp)
    80003a7e:	64a2                	ld	s1,8(sp)
    80003a80:	6902                	ld	s2,0(sp)
    80003a82:	6105                	addi	sp,sp,32
    80003a84:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a86:	40bc                	lw	a5,64(s1)
    80003a88:	dff1                	beqz	a5,80003a64 <iput+0x26>
    80003a8a:	04a49783          	lh	a5,74(s1)
    80003a8e:	fbf9                	bnez	a5,80003a64 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a90:	01048913          	addi	s2,s1,16
    80003a94:	854a                	mv	a0,s2
    80003a96:	00001097          	auipc	ra,0x1
    80003a9a:	ab8080e7          	jalr	-1352(ra) # 8000454e <acquiresleep>
    release(&itable.lock);
    80003a9e:	0001c517          	auipc	a0,0x1c
    80003aa2:	d2a50513          	addi	a0,a0,-726 # 8001f7c8 <itable>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	1f2080e7          	jalr	498(ra) # 80000c98 <release>
    itrunc(ip);
    80003aae:	8526                	mv	a0,s1
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	ee2080e7          	jalr	-286(ra) # 80003992 <itrunc>
    ip->type = 0;
    80003ab8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003abc:	8526                	mv	a0,s1
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	cfc080e7          	jalr	-772(ra) # 800037ba <iupdate>
    ip->valid = 0;
    80003ac6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003aca:	854a                	mv	a0,s2
    80003acc:	00001097          	auipc	ra,0x1
    80003ad0:	ad8080e7          	jalr	-1320(ra) # 800045a4 <releasesleep>
    acquire(&itable.lock);
    80003ad4:	0001c517          	auipc	a0,0x1c
    80003ad8:	cf450513          	addi	a0,a0,-780 # 8001f7c8 <itable>
    80003adc:	ffffd097          	auipc	ra,0xffffd
    80003ae0:	108080e7          	jalr	264(ra) # 80000be4 <acquire>
    80003ae4:	b741                	j	80003a64 <iput+0x26>

0000000080003ae6 <iunlockput>:
{
    80003ae6:	1101                	addi	sp,sp,-32
    80003ae8:	ec06                	sd	ra,24(sp)
    80003aea:	e822                	sd	s0,16(sp)
    80003aec:	e426                	sd	s1,8(sp)
    80003aee:	1000                	addi	s0,sp,32
    80003af0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003af2:	00000097          	auipc	ra,0x0
    80003af6:	e54080e7          	jalr	-428(ra) # 80003946 <iunlock>
  iput(ip);
    80003afa:	8526                	mv	a0,s1
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	f42080e7          	jalr	-190(ra) # 80003a3e <iput>
}
    80003b04:	60e2                	ld	ra,24(sp)
    80003b06:	6442                	ld	s0,16(sp)
    80003b08:	64a2                	ld	s1,8(sp)
    80003b0a:	6105                	addi	sp,sp,32
    80003b0c:	8082                	ret

0000000080003b0e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b0e:	1141                	addi	sp,sp,-16
    80003b10:	e422                	sd	s0,8(sp)
    80003b12:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b14:	411c                	lw	a5,0(a0)
    80003b16:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b18:	415c                	lw	a5,4(a0)
    80003b1a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b1c:	04451783          	lh	a5,68(a0)
    80003b20:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b24:	04a51783          	lh	a5,74(a0)
    80003b28:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b2c:	04c56783          	lwu	a5,76(a0)
    80003b30:	e99c                	sd	a5,16(a1)
}
    80003b32:	6422                	ld	s0,8(sp)
    80003b34:	0141                	addi	sp,sp,16
    80003b36:	8082                	ret

0000000080003b38 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b38:	457c                	lw	a5,76(a0)
    80003b3a:	0ed7e963          	bltu	a5,a3,80003c2c <readi+0xf4>
{
    80003b3e:	7159                	addi	sp,sp,-112
    80003b40:	f486                	sd	ra,104(sp)
    80003b42:	f0a2                	sd	s0,96(sp)
    80003b44:	eca6                	sd	s1,88(sp)
    80003b46:	e8ca                	sd	s2,80(sp)
    80003b48:	e4ce                	sd	s3,72(sp)
    80003b4a:	e0d2                	sd	s4,64(sp)
    80003b4c:	fc56                	sd	s5,56(sp)
    80003b4e:	f85a                	sd	s6,48(sp)
    80003b50:	f45e                	sd	s7,40(sp)
    80003b52:	f062                	sd	s8,32(sp)
    80003b54:	ec66                	sd	s9,24(sp)
    80003b56:	e86a                	sd	s10,16(sp)
    80003b58:	e46e                	sd	s11,8(sp)
    80003b5a:	1880                	addi	s0,sp,112
    80003b5c:	8baa                	mv	s7,a0
    80003b5e:	8c2e                	mv	s8,a1
    80003b60:	8ab2                	mv	s5,a2
    80003b62:	84b6                	mv	s1,a3
    80003b64:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b66:	9f35                	addw	a4,a4,a3
    return 0;
    80003b68:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b6a:	0ad76063          	bltu	a4,a3,80003c0a <readi+0xd2>
  if(off + n > ip->size)
    80003b6e:	00e7f463          	bgeu	a5,a4,80003b76 <readi+0x3e>
    n = ip->size - off;
    80003b72:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b76:	0a0b0963          	beqz	s6,80003c28 <readi+0xf0>
    80003b7a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b7c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b80:	5cfd                	li	s9,-1
    80003b82:	a82d                	j	80003bbc <readi+0x84>
    80003b84:	020a1d93          	slli	s11,s4,0x20
    80003b88:	020ddd93          	srli	s11,s11,0x20
    80003b8c:	05890613          	addi	a2,s2,88
    80003b90:	86ee                	mv	a3,s11
    80003b92:	963a                	add	a2,a2,a4
    80003b94:	85d6                	mv	a1,s5
    80003b96:	8562                	mv	a0,s8
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	ae4080e7          	jalr	-1308(ra) # 8000267c <either_copyout>
    80003ba0:	05950d63          	beq	a0,s9,80003bfa <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ba4:	854a                	mv	a0,s2
    80003ba6:	fffff097          	auipc	ra,0xfffff
    80003baa:	60c080e7          	jalr	1548(ra) # 800031b2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bae:	013a09bb          	addw	s3,s4,s3
    80003bb2:	009a04bb          	addw	s1,s4,s1
    80003bb6:	9aee                	add	s5,s5,s11
    80003bb8:	0569f763          	bgeu	s3,s6,80003c06 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bbc:	000ba903          	lw	s2,0(s7)
    80003bc0:	00a4d59b          	srliw	a1,s1,0xa
    80003bc4:	855e                	mv	a0,s7
    80003bc6:	00000097          	auipc	ra,0x0
    80003bca:	8b0080e7          	jalr	-1872(ra) # 80003476 <bmap>
    80003bce:	0005059b          	sext.w	a1,a0
    80003bd2:	854a                	mv	a0,s2
    80003bd4:	fffff097          	auipc	ra,0xfffff
    80003bd8:	4ae080e7          	jalr	1198(ra) # 80003082 <bread>
    80003bdc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bde:	3ff4f713          	andi	a4,s1,1023
    80003be2:	40ed07bb          	subw	a5,s10,a4
    80003be6:	413b06bb          	subw	a3,s6,s3
    80003bea:	8a3e                	mv	s4,a5
    80003bec:	2781                	sext.w	a5,a5
    80003bee:	0006861b          	sext.w	a2,a3
    80003bf2:	f8f679e3          	bgeu	a2,a5,80003b84 <readi+0x4c>
    80003bf6:	8a36                	mv	s4,a3
    80003bf8:	b771                	j	80003b84 <readi+0x4c>
      brelse(bp);
    80003bfa:	854a                	mv	a0,s2
    80003bfc:	fffff097          	auipc	ra,0xfffff
    80003c00:	5b6080e7          	jalr	1462(ra) # 800031b2 <brelse>
      tot = -1;
    80003c04:	59fd                	li	s3,-1
  }
  return tot;
    80003c06:	0009851b          	sext.w	a0,s3
}
    80003c0a:	70a6                	ld	ra,104(sp)
    80003c0c:	7406                	ld	s0,96(sp)
    80003c0e:	64e6                	ld	s1,88(sp)
    80003c10:	6946                	ld	s2,80(sp)
    80003c12:	69a6                	ld	s3,72(sp)
    80003c14:	6a06                	ld	s4,64(sp)
    80003c16:	7ae2                	ld	s5,56(sp)
    80003c18:	7b42                	ld	s6,48(sp)
    80003c1a:	7ba2                	ld	s7,40(sp)
    80003c1c:	7c02                	ld	s8,32(sp)
    80003c1e:	6ce2                	ld	s9,24(sp)
    80003c20:	6d42                	ld	s10,16(sp)
    80003c22:	6da2                	ld	s11,8(sp)
    80003c24:	6165                	addi	sp,sp,112
    80003c26:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c28:	89da                	mv	s3,s6
    80003c2a:	bff1                	j	80003c06 <readi+0xce>
    return 0;
    80003c2c:	4501                	li	a0,0
}
    80003c2e:	8082                	ret

0000000080003c30 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c30:	457c                	lw	a5,76(a0)
    80003c32:	10d7e863          	bltu	a5,a3,80003d42 <writei+0x112>
{
    80003c36:	7159                	addi	sp,sp,-112
    80003c38:	f486                	sd	ra,104(sp)
    80003c3a:	f0a2                	sd	s0,96(sp)
    80003c3c:	eca6                	sd	s1,88(sp)
    80003c3e:	e8ca                	sd	s2,80(sp)
    80003c40:	e4ce                	sd	s3,72(sp)
    80003c42:	e0d2                	sd	s4,64(sp)
    80003c44:	fc56                	sd	s5,56(sp)
    80003c46:	f85a                	sd	s6,48(sp)
    80003c48:	f45e                	sd	s7,40(sp)
    80003c4a:	f062                	sd	s8,32(sp)
    80003c4c:	ec66                	sd	s9,24(sp)
    80003c4e:	e86a                	sd	s10,16(sp)
    80003c50:	e46e                	sd	s11,8(sp)
    80003c52:	1880                	addi	s0,sp,112
    80003c54:	8b2a                	mv	s6,a0
    80003c56:	8c2e                	mv	s8,a1
    80003c58:	8ab2                	mv	s5,a2
    80003c5a:	8936                	mv	s2,a3
    80003c5c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c5e:	00e687bb          	addw	a5,a3,a4
    80003c62:	0ed7e263          	bltu	a5,a3,80003d46 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c66:	00043737          	lui	a4,0x43
    80003c6a:	0ef76063          	bltu	a4,a5,80003d4a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c6e:	0c0b8863          	beqz	s7,80003d3e <writei+0x10e>
    80003c72:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c74:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c78:	5cfd                	li	s9,-1
    80003c7a:	a091                	j	80003cbe <writei+0x8e>
    80003c7c:	02099d93          	slli	s11,s3,0x20
    80003c80:	020ddd93          	srli	s11,s11,0x20
    80003c84:	05848513          	addi	a0,s1,88
    80003c88:	86ee                	mv	a3,s11
    80003c8a:	8656                	mv	a2,s5
    80003c8c:	85e2                	mv	a1,s8
    80003c8e:	953a                	add	a0,a0,a4
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	a42080e7          	jalr	-1470(ra) # 800026d2 <either_copyin>
    80003c98:	07950263          	beq	a0,s9,80003cfc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c9c:	8526                	mv	a0,s1
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	790080e7          	jalr	1936(ra) # 8000442e <log_write>
    brelse(bp);
    80003ca6:	8526                	mv	a0,s1
    80003ca8:	fffff097          	auipc	ra,0xfffff
    80003cac:	50a080e7          	jalr	1290(ra) # 800031b2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cb0:	01498a3b          	addw	s4,s3,s4
    80003cb4:	0129893b          	addw	s2,s3,s2
    80003cb8:	9aee                	add	s5,s5,s11
    80003cba:	057a7663          	bgeu	s4,s7,80003d06 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cbe:	000b2483          	lw	s1,0(s6)
    80003cc2:	00a9559b          	srliw	a1,s2,0xa
    80003cc6:	855a                	mv	a0,s6
    80003cc8:	fffff097          	auipc	ra,0xfffff
    80003ccc:	7ae080e7          	jalr	1966(ra) # 80003476 <bmap>
    80003cd0:	0005059b          	sext.w	a1,a0
    80003cd4:	8526                	mv	a0,s1
    80003cd6:	fffff097          	auipc	ra,0xfffff
    80003cda:	3ac080e7          	jalr	940(ra) # 80003082 <bread>
    80003cde:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce0:	3ff97713          	andi	a4,s2,1023
    80003ce4:	40ed07bb          	subw	a5,s10,a4
    80003ce8:	414b86bb          	subw	a3,s7,s4
    80003cec:	89be                	mv	s3,a5
    80003cee:	2781                	sext.w	a5,a5
    80003cf0:	0006861b          	sext.w	a2,a3
    80003cf4:	f8f674e3          	bgeu	a2,a5,80003c7c <writei+0x4c>
    80003cf8:	89b6                	mv	s3,a3
    80003cfa:	b749                	j	80003c7c <writei+0x4c>
      brelse(bp);
    80003cfc:	8526                	mv	a0,s1
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	4b4080e7          	jalr	1204(ra) # 800031b2 <brelse>
  }

  if(off > ip->size)
    80003d06:	04cb2783          	lw	a5,76(s6)
    80003d0a:	0127f463          	bgeu	a5,s2,80003d12 <writei+0xe2>
    ip->size = off;
    80003d0e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d12:	855a                	mv	a0,s6
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	aa6080e7          	jalr	-1370(ra) # 800037ba <iupdate>

  return tot;
    80003d1c:	000a051b          	sext.w	a0,s4
}
    80003d20:	70a6                	ld	ra,104(sp)
    80003d22:	7406                	ld	s0,96(sp)
    80003d24:	64e6                	ld	s1,88(sp)
    80003d26:	6946                	ld	s2,80(sp)
    80003d28:	69a6                	ld	s3,72(sp)
    80003d2a:	6a06                	ld	s4,64(sp)
    80003d2c:	7ae2                	ld	s5,56(sp)
    80003d2e:	7b42                	ld	s6,48(sp)
    80003d30:	7ba2                	ld	s7,40(sp)
    80003d32:	7c02                	ld	s8,32(sp)
    80003d34:	6ce2                	ld	s9,24(sp)
    80003d36:	6d42                	ld	s10,16(sp)
    80003d38:	6da2                	ld	s11,8(sp)
    80003d3a:	6165                	addi	sp,sp,112
    80003d3c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d3e:	8a5e                	mv	s4,s7
    80003d40:	bfc9                	j	80003d12 <writei+0xe2>
    return -1;
    80003d42:	557d                	li	a0,-1
}
    80003d44:	8082                	ret
    return -1;
    80003d46:	557d                	li	a0,-1
    80003d48:	bfe1                	j	80003d20 <writei+0xf0>
    return -1;
    80003d4a:	557d                	li	a0,-1
    80003d4c:	bfd1                	j	80003d20 <writei+0xf0>

0000000080003d4e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d4e:	1141                	addi	sp,sp,-16
    80003d50:	e406                	sd	ra,8(sp)
    80003d52:	e022                	sd	s0,0(sp)
    80003d54:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d56:	4639                	li	a2,14
    80003d58:	ffffd097          	auipc	ra,0xffffd
    80003d5c:	060080e7          	jalr	96(ra) # 80000db8 <strncmp>
}
    80003d60:	60a2                	ld	ra,8(sp)
    80003d62:	6402                	ld	s0,0(sp)
    80003d64:	0141                	addi	sp,sp,16
    80003d66:	8082                	ret

0000000080003d68 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d68:	7139                	addi	sp,sp,-64
    80003d6a:	fc06                	sd	ra,56(sp)
    80003d6c:	f822                	sd	s0,48(sp)
    80003d6e:	f426                	sd	s1,40(sp)
    80003d70:	f04a                	sd	s2,32(sp)
    80003d72:	ec4e                	sd	s3,24(sp)
    80003d74:	e852                	sd	s4,16(sp)
    80003d76:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d78:	04451703          	lh	a4,68(a0)
    80003d7c:	4785                	li	a5,1
    80003d7e:	00f71a63          	bne	a4,a5,80003d92 <dirlookup+0x2a>
    80003d82:	892a                	mv	s2,a0
    80003d84:	89ae                	mv	s3,a1
    80003d86:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d88:	457c                	lw	a5,76(a0)
    80003d8a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d8c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d8e:	e79d                	bnez	a5,80003dbc <dirlookup+0x54>
    80003d90:	a8a5                	j	80003e08 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d92:	00005517          	auipc	a0,0x5
    80003d96:	8a650513          	addi	a0,a0,-1882 # 80008638 <syscalls+0x1b0>
    80003d9a:	ffffc097          	auipc	ra,0xffffc
    80003d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003da2:	00005517          	auipc	a0,0x5
    80003da6:	8ae50513          	addi	a0,a0,-1874 # 80008650 <syscalls+0x1c8>
    80003daa:	ffffc097          	auipc	ra,0xffffc
    80003dae:	794080e7          	jalr	1940(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db2:	24c1                	addiw	s1,s1,16
    80003db4:	04c92783          	lw	a5,76(s2)
    80003db8:	04f4f763          	bgeu	s1,a5,80003e06 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dbc:	4741                	li	a4,16
    80003dbe:	86a6                	mv	a3,s1
    80003dc0:	fc040613          	addi	a2,s0,-64
    80003dc4:	4581                	li	a1,0
    80003dc6:	854a                	mv	a0,s2
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	d70080e7          	jalr	-656(ra) # 80003b38 <readi>
    80003dd0:	47c1                	li	a5,16
    80003dd2:	fcf518e3          	bne	a0,a5,80003da2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003dd6:	fc045783          	lhu	a5,-64(s0)
    80003dda:	dfe1                	beqz	a5,80003db2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ddc:	fc240593          	addi	a1,s0,-62
    80003de0:	854e                	mv	a0,s3
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	f6c080e7          	jalr	-148(ra) # 80003d4e <namecmp>
    80003dea:	f561                	bnez	a0,80003db2 <dirlookup+0x4a>
      if(poff)
    80003dec:	000a0463          	beqz	s4,80003df4 <dirlookup+0x8c>
        *poff = off;
    80003df0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003df4:	fc045583          	lhu	a1,-64(s0)
    80003df8:	00092503          	lw	a0,0(s2)
    80003dfc:	fffff097          	auipc	ra,0xfffff
    80003e00:	754080e7          	jalr	1876(ra) # 80003550 <iget>
    80003e04:	a011                	j	80003e08 <dirlookup+0xa0>
  return 0;
    80003e06:	4501                	li	a0,0
}
    80003e08:	70e2                	ld	ra,56(sp)
    80003e0a:	7442                	ld	s0,48(sp)
    80003e0c:	74a2                	ld	s1,40(sp)
    80003e0e:	7902                	ld	s2,32(sp)
    80003e10:	69e2                	ld	s3,24(sp)
    80003e12:	6a42                	ld	s4,16(sp)
    80003e14:	6121                	addi	sp,sp,64
    80003e16:	8082                	ret

0000000080003e18 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e18:	711d                	addi	sp,sp,-96
    80003e1a:	ec86                	sd	ra,88(sp)
    80003e1c:	e8a2                	sd	s0,80(sp)
    80003e1e:	e4a6                	sd	s1,72(sp)
    80003e20:	e0ca                	sd	s2,64(sp)
    80003e22:	fc4e                	sd	s3,56(sp)
    80003e24:	f852                	sd	s4,48(sp)
    80003e26:	f456                	sd	s5,40(sp)
    80003e28:	f05a                	sd	s6,32(sp)
    80003e2a:	ec5e                	sd	s7,24(sp)
    80003e2c:	e862                	sd	s8,16(sp)
    80003e2e:	e466                	sd	s9,8(sp)
    80003e30:	1080                	addi	s0,sp,96
    80003e32:	84aa                	mv	s1,a0
    80003e34:	8b2e                	mv	s6,a1
    80003e36:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e38:	00054703          	lbu	a4,0(a0)
    80003e3c:	02f00793          	li	a5,47
    80003e40:	02f70363          	beq	a4,a5,80003e66 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e44:	ffffe097          	auipc	ra,0xffffe
    80003e48:	c90080e7          	jalr	-880(ra) # 80001ad4 <myproc>
    80003e4c:	15053503          	ld	a0,336(a0)
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	9f6080e7          	jalr	-1546(ra) # 80003846 <idup>
    80003e58:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e5a:	02f00913          	li	s2,47
  len = path - s;
    80003e5e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e60:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e62:	4c05                	li	s8,1
    80003e64:	a865                	j	80003f1c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e66:	4585                	li	a1,1
    80003e68:	4505                	li	a0,1
    80003e6a:	fffff097          	auipc	ra,0xfffff
    80003e6e:	6e6080e7          	jalr	1766(ra) # 80003550 <iget>
    80003e72:	89aa                	mv	s3,a0
    80003e74:	b7dd                	j	80003e5a <namex+0x42>
      iunlockput(ip);
    80003e76:	854e                	mv	a0,s3
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	c6e080e7          	jalr	-914(ra) # 80003ae6 <iunlockput>
      return 0;
    80003e80:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e82:	854e                	mv	a0,s3
    80003e84:	60e6                	ld	ra,88(sp)
    80003e86:	6446                	ld	s0,80(sp)
    80003e88:	64a6                	ld	s1,72(sp)
    80003e8a:	6906                	ld	s2,64(sp)
    80003e8c:	79e2                	ld	s3,56(sp)
    80003e8e:	7a42                	ld	s4,48(sp)
    80003e90:	7aa2                	ld	s5,40(sp)
    80003e92:	7b02                	ld	s6,32(sp)
    80003e94:	6be2                	ld	s7,24(sp)
    80003e96:	6c42                	ld	s8,16(sp)
    80003e98:	6ca2                	ld	s9,8(sp)
    80003e9a:	6125                	addi	sp,sp,96
    80003e9c:	8082                	ret
      iunlock(ip);
    80003e9e:	854e                	mv	a0,s3
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	aa6080e7          	jalr	-1370(ra) # 80003946 <iunlock>
      return ip;
    80003ea8:	bfe9                	j	80003e82 <namex+0x6a>
      iunlockput(ip);
    80003eaa:	854e                	mv	a0,s3
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	c3a080e7          	jalr	-966(ra) # 80003ae6 <iunlockput>
      return 0;
    80003eb4:	89d2                	mv	s3,s4
    80003eb6:	b7f1                	j	80003e82 <namex+0x6a>
  len = path - s;
    80003eb8:	40b48633          	sub	a2,s1,a1
    80003ebc:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ec0:	094cd463          	bge	s9,s4,80003f48 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ec4:	4639                	li	a2,14
    80003ec6:	8556                	mv	a0,s5
    80003ec8:	ffffd097          	auipc	ra,0xffffd
    80003ecc:	e78080e7          	jalr	-392(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ed0:	0004c783          	lbu	a5,0(s1)
    80003ed4:	01279763          	bne	a5,s2,80003ee2 <namex+0xca>
    path++;
    80003ed8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eda:	0004c783          	lbu	a5,0(s1)
    80003ede:	ff278de3          	beq	a5,s2,80003ed8 <namex+0xc0>
    ilock(ip);
    80003ee2:	854e                	mv	a0,s3
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	9a0080e7          	jalr	-1632(ra) # 80003884 <ilock>
    if(ip->type != T_DIR){
    80003eec:	04499783          	lh	a5,68(s3)
    80003ef0:	f98793e3          	bne	a5,s8,80003e76 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ef4:	000b0563          	beqz	s6,80003efe <namex+0xe6>
    80003ef8:	0004c783          	lbu	a5,0(s1)
    80003efc:	d3cd                	beqz	a5,80003e9e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003efe:	865e                	mv	a2,s7
    80003f00:	85d6                	mv	a1,s5
    80003f02:	854e                	mv	a0,s3
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	e64080e7          	jalr	-412(ra) # 80003d68 <dirlookup>
    80003f0c:	8a2a                	mv	s4,a0
    80003f0e:	dd51                	beqz	a0,80003eaa <namex+0x92>
    iunlockput(ip);
    80003f10:	854e                	mv	a0,s3
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	bd4080e7          	jalr	-1068(ra) # 80003ae6 <iunlockput>
    ip = next;
    80003f1a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f1c:	0004c783          	lbu	a5,0(s1)
    80003f20:	05279763          	bne	a5,s2,80003f6e <namex+0x156>
    path++;
    80003f24:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f26:	0004c783          	lbu	a5,0(s1)
    80003f2a:	ff278de3          	beq	a5,s2,80003f24 <namex+0x10c>
  if(*path == 0)
    80003f2e:	c79d                	beqz	a5,80003f5c <namex+0x144>
    path++;
    80003f30:	85a6                	mv	a1,s1
  len = path - s;
    80003f32:	8a5e                	mv	s4,s7
    80003f34:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f36:	01278963          	beq	a5,s2,80003f48 <namex+0x130>
    80003f3a:	dfbd                	beqz	a5,80003eb8 <namex+0xa0>
    path++;
    80003f3c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f3e:	0004c783          	lbu	a5,0(s1)
    80003f42:	ff279ce3          	bne	a5,s2,80003f3a <namex+0x122>
    80003f46:	bf8d                	j	80003eb8 <namex+0xa0>
    memmove(name, s, len);
    80003f48:	2601                	sext.w	a2,a2
    80003f4a:	8556                	mv	a0,s5
    80003f4c:	ffffd097          	auipc	ra,0xffffd
    80003f50:	df4080e7          	jalr	-524(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f54:	9a56                	add	s4,s4,s5
    80003f56:	000a0023          	sb	zero,0(s4)
    80003f5a:	bf9d                	j	80003ed0 <namex+0xb8>
  if(nameiparent){
    80003f5c:	f20b03e3          	beqz	s6,80003e82 <namex+0x6a>
    iput(ip);
    80003f60:	854e                	mv	a0,s3
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	adc080e7          	jalr	-1316(ra) # 80003a3e <iput>
    return 0;
    80003f6a:	4981                	li	s3,0
    80003f6c:	bf19                	j	80003e82 <namex+0x6a>
  if(*path == 0)
    80003f6e:	d7fd                	beqz	a5,80003f5c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f70:	0004c783          	lbu	a5,0(s1)
    80003f74:	85a6                	mv	a1,s1
    80003f76:	b7d1                	j	80003f3a <namex+0x122>

0000000080003f78 <dirlink>:
{
    80003f78:	7139                	addi	sp,sp,-64
    80003f7a:	fc06                	sd	ra,56(sp)
    80003f7c:	f822                	sd	s0,48(sp)
    80003f7e:	f426                	sd	s1,40(sp)
    80003f80:	f04a                	sd	s2,32(sp)
    80003f82:	ec4e                	sd	s3,24(sp)
    80003f84:	e852                	sd	s4,16(sp)
    80003f86:	0080                	addi	s0,sp,64
    80003f88:	892a                	mv	s2,a0
    80003f8a:	8a2e                	mv	s4,a1
    80003f8c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f8e:	4601                	li	a2,0
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	dd8080e7          	jalr	-552(ra) # 80003d68 <dirlookup>
    80003f98:	e93d                	bnez	a0,8000400e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f9a:	04c92483          	lw	s1,76(s2)
    80003f9e:	c49d                	beqz	s1,80003fcc <dirlink+0x54>
    80003fa0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa2:	4741                	li	a4,16
    80003fa4:	86a6                	mv	a3,s1
    80003fa6:	fc040613          	addi	a2,s0,-64
    80003faa:	4581                	li	a1,0
    80003fac:	854a                	mv	a0,s2
    80003fae:	00000097          	auipc	ra,0x0
    80003fb2:	b8a080e7          	jalr	-1142(ra) # 80003b38 <readi>
    80003fb6:	47c1                	li	a5,16
    80003fb8:	06f51163          	bne	a0,a5,8000401a <dirlink+0xa2>
    if(de.inum == 0)
    80003fbc:	fc045783          	lhu	a5,-64(s0)
    80003fc0:	c791                	beqz	a5,80003fcc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc2:	24c1                	addiw	s1,s1,16
    80003fc4:	04c92783          	lw	a5,76(s2)
    80003fc8:	fcf4ede3          	bltu	s1,a5,80003fa2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fcc:	4639                	li	a2,14
    80003fce:	85d2                	mv	a1,s4
    80003fd0:	fc240513          	addi	a0,s0,-62
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	e20080e7          	jalr	-480(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003fdc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe0:	4741                	li	a4,16
    80003fe2:	86a6                	mv	a3,s1
    80003fe4:	fc040613          	addi	a2,s0,-64
    80003fe8:	4581                	li	a1,0
    80003fea:	854a                	mv	a0,s2
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	c44080e7          	jalr	-956(ra) # 80003c30 <writei>
    80003ff4:	872a                	mv	a4,a0
    80003ff6:	47c1                	li	a5,16
  return 0;
    80003ff8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffa:	02f71863          	bne	a4,a5,8000402a <dirlink+0xb2>
}
    80003ffe:	70e2                	ld	ra,56(sp)
    80004000:	7442                	ld	s0,48(sp)
    80004002:	74a2                	ld	s1,40(sp)
    80004004:	7902                	ld	s2,32(sp)
    80004006:	69e2                	ld	s3,24(sp)
    80004008:	6a42                	ld	s4,16(sp)
    8000400a:	6121                	addi	sp,sp,64
    8000400c:	8082                	ret
    iput(ip);
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	a30080e7          	jalr	-1488(ra) # 80003a3e <iput>
    return -1;
    80004016:	557d                	li	a0,-1
    80004018:	b7dd                	j	80003ffe <dirlink+0x86>
      panic("dirlink read");
    8000401a:	00004517          	auipc	a0,0x4
    8000401e:	64650513          	addi	a0,a0,1606 # 80008660 <syscalls+0x1d8>
    80004022:	ffffc097          	auipc	ra,0xffffc
    80004026:	51c080e7          	jalr	1308(ra) # 8000053e <panic>
    panic("dirlink");
    8000402a:	00004517          	auipc	a0,0x4
    8000402e:	74650513          	addi	a0,a0,1862 # 80008770 <syscalls+0x2e8>
    80004032:	ffffc097          	auipc	ra,0xffffc
    80004036:	50c080e7          	jalr	1292(ra) # 8000053e <panic>

000000008000403a <namei>:

struct inode*
namei(char *path)
{
    8000403a:	1101                	addi	sp,sp,-32
    8000403c:	ec06                	sd	ra,24(sp)
    8000403e:	e822                	sd	s0,16(sp)
    80004040:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004042:	fe040613          	addi	a2,s0,-32
    80004046:	4581                	li	a1,0
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	dd0080e7          	jalr	-560(ra) # 80003e18 <namex>
}
    80004050:	60e2                	ld	ra,24(sp)
    80004052:	6442                	ld	s0,16(sp)
    80004054:	6105                	addi	sp,sp,32
    80004056:	8082                	ret

0000000080004058 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004058:	1141                	addi	sp,sp,-16
    8000405a:	e406                	sd	ra,8(sp)
    8000405c:	e022                	sd	s0,0(sp)
    8000405e:	0800                	addi	s0,sp,16
    80004060:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004062:	4585                	li	a1,1
    80004064:	00000097          	auipc	ra,0x0
    80004068:	db4080e7          	jalr	-588(ra) # 80003e18 <namex>
}
    8000406c:	60a2                	ld	ra,8(sp)
    8000406e:	6402                	ld	s0,0(sp)
    80004070:	0141                	addi	sp,sp,16
    80004072:	8082                	ret

0000000080004074 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004074:	1101                	addi	sp,sp,-32
    80004076:	ec06                	sd	ra,24(sp)
    80004078:	e822                	sd	s0,16(sp)
    8000407a:	e426                	sd	s1,8(sp)
    8000407c:	e04a                	sd	s2,0(sp)
    8000407e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004080:	0001d917          	auipc	s2,0x1d
    80004084:	1f090913          	addi	s2,s2,496 # 80021270 <log>
    80004088:	01892583          	lw	a1,24(s2)
    8000408c:	02892503          	lw	a0,40(s2)
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	ff2080e7          	jalr	-14(ra) # 80003082 <bread>
    80004098:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000409a:	02c92683          	lw	a3,44(s2)
    8000409e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040a0:	02d05763          	blez	a3,800040ce <write_head+0x5a>
    800040a4:	0001d797          	auipc	a5,0x1d
    800040a8:	1fc78793          	addi	a5,a5,508 # 800212a0 <log+0x30>
    800040ac:	05c50713          	addi	a4,a0,92
    800040b0:	36fd                	addiw	a3,a3,-1
    800040b2:	1682                	slli	a3,a3,0x20
    800040b4:	9281                	srli	a3,a3,0x20
    800040b6:	068a                	slli	a3,a3,0x2
    800040b8:	0001d617          	auipc	a2,0x1d
    800040bc:	1ec60613          	addi	a2,a2,492 # 800212a4 <log+0x34>
    800040c0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040c2:	4390                	lw	a2,0(a5)
    800040c4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040c6:	0791                	addi	a5,a5,4
    800040c8:	0711                	addi	a4,a4,4
    800040ca:	fed79ce3          	bne	a5,a3,800040c2 <write_head+0x4e>
  }
  bwrite(buf);
    800040ce:	8526                	mv	a0,s1
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	0a4080e7          	jalr	164(ra) # 80003174 <bwrite>
  brelse(buf);
    800040d8:	8526                	mv	a0,s1
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	0d8080e7          	jalr	216(ra) # 800031b2 <brelse>
}
    800040e2:	60e2                	ld	ra,24(sp)
    800040e4:	6442                	ld	s0,16(sp)
    800040e6:	64a2                	ld	s1,8(sp)
    800040e8:	6902                	ld	s2,0(sp)
    800040ea:	6105                	addi	sp,sp,32
    800040ec:	8082                	ret

00000000800040ee <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ee:	0001d797          	auipc	a5,0x1d
    800040f2:	1ae7a783          	lw	a5,430(a5) # 8002129c <log+0x2c>
    800040f6:	0af05d63          	blez	a5,800041b0 <install_trans+0xc2>
{
    800040fa:	7139                	addi	sp,sp,-64
    800040fc:	fc06                	sd	ra,56(sp)
    800040fe:	f822                	sd	s0,48(sp)
    80004100:	f426                	sd	s1,40(sp)
    80004102:	f04a                	sd	s2,32(sp)
    80004104:	ec4e                	sd	s3,24(sp)
    80004106:	e852                	sd	s4,16(sp)
    80004108:	e456                	sd	s5,8(sp)
    8000410a:	e05a                	sd	s6,0(sp)
    8000410c:	0080                	addi	s0,sp,64
    8000410e:	8b2a                	mv	s6,a0
    80004110:	0001da97          	auipc	s5,0x1d
    80004114:	190a8a93          	addi	s5,s5,400 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004118:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000411a:	0001d997          	auipc	s3,0x1d
    8000411e:	15698993          	addi	s3,s3,342 # 80021270 <log>
    80004122:	a035                	j	8000414e <install_trans+0x60>
      bunpin(dbuf);
    80004124:	8526                	mv	a0,s1
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	166080e7          	jalr	358(ra) # 8000328c <bunpin>
    brelse(lbuf);
    8000412e:	854a                	mv	a0,s2
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	082080e7          	jalr	130(ra) # 800031b2 <brelse>
    brelse(dbuf);
    80004138:	8526                	mv	a0,s1
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	078080e7          	jalr	120(ra) # 800031b2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004142:	2a05                	addiw	s4,s4,1
    80004144:	0a91                	addi	s5,s5,4
    80004146:	02c9a783          	lw	a5,44(s3)
    8000414a:	04fa5963          	bge	s4,a5,8000419c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000414e:	0189a583          	lw	a1,24(s3)
    80004152:	014585bb          	addw	a1,a1,s4
    80004156:	2585                	addiw	a1,a1,1
    80004158:	0289a503          	lw	a0,40(s3)
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	f26080e7          	jalr	-218(ra) # 80003082 <bread>
    80004164:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004166:	000aa583          	lw	a1,0(s5)
    8000416a:	0289a503          	lw	a0,40(s3)
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	f14080e7          	jalr	-236(ra) # 80003082 <bread>
    80004176:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004178:	40000613          	li	a2,1024
    8000417c:	05890593          	addi	a1,s2,88
    80004180:	05850513          	addi	a0,a0,88
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	bbc080e7          	jalr	-1092(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000418c:	8526                	mv	a0,s1
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	fe6080e7          	jalr	-26(ra) # 80003174 <bwrite>
    if(recovering == 0)
    80004196:	f80b1ce3          	bnez	s6,8000412e <install_trans+0x40>
    8000419a:	b769                	j	80004124 <install_trans+0x36>
}
    8000419c:	70e2                	ld	ra,56(sp)
    8000419e:	7442                	ld	s0,48(sp)
    800041a0:	74a2                	ld	s1,40(sp)
    800041a2:	7902                	ld	s2,32(sp)
    800041a4:	69e2                	ld	s3,24(sp)
    800041a6:	6a42                	ld	s4,16(sp)
    800041a8:	6aa2                	ld	s5,8(sp)
    800041aa:	6b02                	ld	s6,0(sp)
    800041ac:	6121                	addi	sp,sp,64
    800041ae:	8082                	ret
    800041b0:	8082                	ret

00000000800041b2 <initlog>:
{
    800041b2:	7179                	addi	sp,sp,-48
    800041b4:	f406                	sd	ra,40(sp)
    800041b6:	f022                	sd	s0,32(sp)
    800041b8:	ec26                	sd	s1,24(sp)
    800041ba:	e84a                	sd	s2,16(sp)
    800041bc:	e44e                	sd	s3,8(sp)
    800041be:	1800                	addi	s0,sp,48
    800041c0:	892a                	mv	s2,a0
    800041c2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041c4:	0001d497          	auipc	s1,0x1d
    800041c8:	0ac48493          	addi	s1,s1,172 # 80021270 <log>
    800041cc:	00004597          	auipc	a1,0x4
    800041d0:	4a458593          	addi	a1,a1,1188 # 80008670 <syscalls+0x1e8>
    800041d4:	8526                	mv	a0,s1
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	97e080e7          	jalr	-1666(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800041de:	0149a583          	lw	a1,20(s3)
    800041e2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041e4:	0109a783          	lw	a5,16(s3)
    800041e8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041ea:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041ee:	854a                	mv	a0,s2
    800041f0:	fffff097          	auipc	ra,0xfffff
    800041f4:	e92080e7          	jalr	-366(ra) # 80003082 <bread>
  log.lh.n = lh->n;
    800041f8:	4d3c                	lw	a5,88(a0)
    800041fa:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041fc:	02f05563          	blez	a5,80004226 <initlog+0x74>
    80004200:	05c50713          	addi	a4,a0,92
    80004204:	0001d697          	auipc	a3,0x1d
    80004208:	09c68693          	addi	a3,a3,156 # 800212a0 <log+0x30>
    8000420c:	37fd                	addiw	a5,a5,-1
    8000420e:	1782                	slli	a5,a5,0x20
    80004210:	9381                	srli	a5,a5,0x20
    80004212:	078a                	slli	a5,a5,0x2
    80004214:	06050613          	addi	a2,a0,96
    80004218:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000421a:	4310                	lw	a2,0(a4)
    8000421c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000421e:	0711                	addi	a4,a4,4
    80004220:	0691                	addi	a3,a3,4
    80004222:	fef71ce3          	bne	a4,a5,8000421a <initlog+0x68>
  brelse(buf);
    80004226:	fffff097          	auipc	ra,0xfffff
    8000422a:	f8c080e7          	jalr	-116(ra) # 800031b2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000422e:	4505                	li	a0,1
    80004230:	00000097          	auipc	ra,0x0
    80004234:	ebe080e7          	jalr	-322(ra) # 800040ee <install_trans>
  log.lh.n = 0;
    80004238:	0001d797          	auipc	a5,0x1d
    8000423c:	0607a223          	sw	zero,100(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004240:	00000097          	auipc	ra,0x0
    80004244:	e34080e7          	jalr	-460(ra) # 80004074 <write_head>
}
    80004248:	70a2                	ld	ra,40(sp)
    8000424a:	7402                	ld	s0,32(sp)
    8000424c:	64e2                	ld	s1,24(sp)
    8000424e:	6942                	ld	s2,16(sp)
    80004250:	69a2                	ld	s3,8(sp)
    80004252:	6145                	addi	sp,sp,48
    80004254:	8082                	ret

0000000080004256 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004256:	1101                	addi	sp,sp,-32
    80004258:	ec06                	sd	ra,24(sp)
    8000425a:	e822                	sd	s0,16(sp)
    8000425c:	e426                	sd	s1,8(sp)
    8000425e:	e04a                	sd	s2,0(sp)
    80004260:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004262:	0001d517          	auipc	a0,0x1d
    80004266:	00e50513          	addi	a0,a0,14 # 80021270 <log>
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	97a080e7          	jalr	-1670(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004272:	0001d497          	auipc	s1,0x1d
    80004276:	ffe48493          	addi	s1,s1,-2 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000427a:	4979                	li	s2,30
    8000427c:	a039                	j	8000428a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000427e:	85a6                	mv	a1,s1
    80004280:	8526                	mv	a0,s1
    80004282:	ffffe097          	auipc	ra,0xffffe
    80004286:	f0e080e7          	jalr	-242(ra) # 80002190 <sleep>
    if(log.committing){
    8000428a:	50dc                	lw	a5,36(s1)
    8000428c:	fbed                	bnez	a5,8000427e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000428e:	509c                	lw	a5,32(s1)
    80004290:	0017871b          	addiw	a4,a5,1
    80004294:	0007069b          	sext.w	a3,a4
    80004298:	0027179b          	slliw	a5,a4,0x2
    8000429c:	9fb9                	addw	a5,a5,a4
    8000429e:	0017979b          	slliw	a5,a5,0x1
    800042a2:	54d8                	lw	a4,44(s1)
    800042a4:	9fb9                	addw	a5,a5,a4
    800042a6:	00f95963          	bge	s2,a5,800042b8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042aa:	85a6                	mv	a1,s1
    800042ac:	8526                	mv	a0,s1
    800042ae:	ffffe097          	auipc	ra,0xffffe
    800042b2:	ee2080e7          	jalr	-286(ra) # 80002190 <sleep>
    800042b6:	bfd1                	j	8000428a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042b8:	0001d517          	auipc	a0,0x1d
    800042bc:	fb850513          	addi	a0,a0,-72 # 80021270 <log>
    800042c0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	9d6080e7          	jalr	-1578(ra) # 80000c98 <release>
      break;
    }
  }
}
    800042ca:	60e2                	ld	ra,24(sp)
    800042cc:	6442                	ld	s0,16(sp)
    800042ce:	64a2                	ld	s1,8(sp)
    800042d0:	6902                	ld	s2,0(sp)
    800042d2:	6105                	addi	sp,sp,32
    800042d4:	8082                	ret

00000000800042d6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042d6:	7139                	addi	sp,sp,-64
    800042d8:	fc06                	sd	ra,56(sp)
    800042da:	f822                	sd	s0,48(sp)
    800042dc:	f426                	sd	s1,40(sp)
    800042de:	f04a                	sd	s2,32(sp)
    800042e0:	ec4e                	sd	s3,24(sp)
    800042e2:	e852                	sd	s4,16(sp)
    800042e4:	e456                	sd	s5,8(sp)
    800042e6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042e8:	0001d497          	auipc	s1,0x1d
    800042ec:	f8848493          	addi	s1,s1,-120 # 80021270 <log>
    800042f0:	8526                	mv	a0,s1
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	8f2080e7          	jalr	-1806(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800042fa:	509c                	lw	a5,32(s1)
    800042fc:	37fd                	addiw	a5,a5,-1
    800042fe:	0007891b          	sext.w	s2,a5
    80004302:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004304:	50dc                	lw	a5,36(s1)
    80004306:	efb9                	bnez	a5,80004364 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004308:	06091663          	bnez	s2,80004374 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000430c:	0001d497          	auipc	s1,0x1d
    80004310:	f6448493          	addi	s1,s1,-156 # 80021270 <log>
    80004314:	4785                	li	a5,1
    80004316:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004318:	8526                	mv	a0,s1
    8000431a:	ffffd097          	auipc	ra,0xffffd
    8000431e:	97e080e7          	jalr	-1666(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004322:	54dc                	lw	a5,44(s1)
    80004324:	06f04763          	bgtz	a5,80004392 <end_op+0xbc>
    acquire(&log.lock);
    80004328:	0001d497          	auipc	s1,0x1d
    8000432c:	f4848493          	addi	s1,s1,-184 # 80021270 <log>
    80004330:	8526                	mv	a0,s1
    80004332:	ffffd097          	auipc	ra,0xffffd
    80004336:	8b2080e7          	jalr	-1870(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000433a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000433e:	8526                	mv	a0,s1
    80004340:	ffffe097          	auipc	ra,0xffffe
    80004344:	0da080e7          	jalr	218(ra) # 8000241a <wakeup>
    release(&log.lock);
    80004348:	8526                	mv	a0,s1
    8000434a:	ffffd097          	auipc	ra,0xffffd
    8000434e:	94e080e7          	jalr	-1714(ra) # 80000c98 <release>
}
    80004352:	70e2                	ld	ra,56(sp)
    80004354:	7442                	ld	s0,48(sp)
    80004356:	74a2                	ld	s1,40(sp)
    80004358:	7902                	ld	s2,32(sp)
    8000435a:	69e2                	ld	s3,24(sp)
    8000435c:	6a42                	ld	s4,16(sp)
    8000435e:	6aa2                	ld	s5,8(sp)
    80004360:	6121                	addi	sp,sp,64
    80004362:	8082                	ret
    panic("log.committing");
    80004364:	00004517          	auipc	a0,0x4
    80004368:	31450513          	addi	a0,a0,788 # 80008678 <syscalls+0x1f0>
    8000436c:	ffffc097          	auipc	ra,0xffffc
    80004370:	1d2080e7          	jalr	466(ra) # 8000053e <panic>
    wakeup(&log);
    80004374:	0001d497          	auipc	s1,0x1d
    80004378:	efc48493          	addi	s1,s1,-260 # 80021270 <log>
    8000437c:	8526                	mv	a0,s1
    8000437e:	ffffe097          	auipc	ra,0xffffe
    80004382:	09c080e7          	jalr	156(ra) # 8000241a <wakeup>
  release(&log.lock);
    80004386:	8526                	mv	a0,s1
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
  if(do_commit){
    80004390:	b7c9                	j	80004352 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004392:	0001da97          	auipc	s5,0x1d
    80004396:	f0ea8a93          	addi	s5,s5,-242 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000439a:	0001da17          	auipc	s4,0x1d
    8000439e:	ed6a0a13          	addi	s4,s4,-298 # 80021270 <log>
    800043a2:	018a2583          	lw	a1,24(s4)
    800043a6:	012585bb          	addw	a1,a1,s2
    800043aa:	2585                	addiw	a1,a1,1
    800043ac:	028a2503          	lw	a0,40(s4)
    800043b0:	fffff097          	auipc	ra,0xfffff
    800043b4:	cd2080e7          	jalr	-814(ra) # 80003082 <bread>
    800043b8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043ba:	000aa583          	lw	a1,0(s5)
    800043be:	028a2503          	lw	a0,40(s4)
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	cc0080e7          	jalr	-832(ra) # 80003082 <bread>
    800043ca:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043cc:	40000613          	li	a2,1024
    800043d0:	05850593          	addi	a1,a0,88
    800043d4:	05848513          	addi	a0,s1,88
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	968080e7          	jalr	-1688(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800043e0:	8526                	mv	a0,s1
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	d92080e7          	jalr	-622(ra) # 80003174 <bwrite>
    brelse(from);
    800043ea:	854e                	mv	a0,s3
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	dc6080e7          	jalr	-570(ra) # 800031b2 <brelse>
    brelse(to);
    800043f4:	8526                	mv	a0,s1
    800043f6:	fffff097          	auipc	ra,0xfffff
    800043fa:	dbc080e7          	jalr	-580(ra) # 800031b2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fe:	2905                	addiw	s2,s2,1
    80004400:	0a91                	addi	s5,s5,4
    80004402:	02ca2783          	lw	a5,44(s4)
    80004406:	f8f94ee3          	blt	s2,a5,800043a2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	c6a080e7          	jalr	-918(ra) # 80004074 <write_head>
    install_trans(0); // Now install writes to home locations
    80004412:	4501                	li	a0,0
    80004414:	00000097          	auipc	ra,0x0
    80004418:	cda080e7          	jalr	-806(ra) # 800040ee <install_trans>
    log.lh.n = 0;
    8000441c:	0001d797          	auipc	a5,0x1d
    80004420:	e807a023          	sw	zero,-384(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004424:	00000097          	auipc	ra,0x0
    80004428:	c50080e7          	jalr	-944(ra) # 80004074 <write_head>
    8000442c:	bdf5                	j	80004328 <end_op+0x52>

000000008000442e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000442e:	1101                	addi	sp,sp,-32
    80004430:	ec06                	sd	ra,24(sp)
    80004432:	e822                	sd	s0,16(sp)
    80004434:	e426                	sd	s1,8(sp)
    80004436:	e04a                	sd	s2,0(sp)
    80004438:	1000                	addi	s0,sp,32
    8000443a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000443c:	0001d917          	auipc	s2,0x1d
    80004440:	e3490913          	addi	s2,s2,-460 # 80021270 <log>
    80004444:	854a                	mv	a0,s2
    80004446:	ffffc097          	auipc	ra,0xffffc
    8000444a:	79e080e7          	jalr	1950(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000444e:	02c92603          	lw	a2,44(s2)
    80004452:	47f5                	li	a5,29
    80004454:	06c7c563          	blt	a5,a2,800044be <log_write+0x90>
    80004458:	0001d797          	auipc	a5,0x1d
    8000445c:	e347a783          	lw	a5,-460(a5) # 8002128c <log+0x1c>
    80004460:	37fd                	addiw	a5,a5,-1
    80004462:	04f65e63          	bge	a2,a5,800044be <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004466:	0001d797          	auipc	a5,0x1d
    8000446a:	e2a7a783          	lw	a5,-470(a5) # 80021290 <log+0x20>
    8000446e:	06f05063          	blez	a5,800044ce <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004472:	4781                	li	a5,0
    80004474:	06c05563          	blez	a2,800044de <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004478:	44cc                	lw	a1,12(s1)
    8000447a:	0001d717          	auipc	a4,0x1d
    8000447e:	e2670713          	addi	a4,a4,-474 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004482:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004484:	4314                	lw	a3,0(a4)
    80004486:	04b68c63          	beq	a3,a1,800044de <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000448a:	2785                	addiw	a5,a5,1
    8000448c:	0711                	addi	a4,a4,4
    8000448e:	fef61be3          	bne	a2,a5,80004484 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004492:	0621                	addi	a2,a2,8
    80004494:	060a                	slli	a2,a2,0x2
    80004496:	0001d797          	auipc	a5,0x1d
    8000449a:	dda78793          	addi	a5,a5,-550 # 80021270 <log>
    8000449e:	963e                	add	a2,a2,a5
    800044a0:	44dc                	lw	a5,12(s1)
    800044a2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044a4:	8526                	mv	a0,s1
    800044a6:	fffff097          	auipc	ra,0xfffff
    800044aa:	daa080e7          	jalr	-598(ra) # 80003250 <bpin>
    log.lh.n++;
    800044ae:	0001d717          	auipc	a4,0x1d
    800044b2:	dc270713          	addi	a4,a4,-574 # 80021270 <log>
    800044b6:	575c                	lw	a5,44(a4)
    800044b8:	2785                	addiw	a5,a5,1
    800044ba:	d75c                	sw	a5,44(a4)
    800044bc:	a835                	j	800044f8 <log_write+0xca>
    panic("too big a transaction");
    800044be:	00004517          	auipc	a0,0x4
    800044c2:	1ca50513          	addi	a0,a0,458 # 80008688 <syscalls+0x200>
    800044c6:	ffffc097          	auipc	ra,0xffffc
    800044ca:	078080e7          	jalr	120(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044ce:	00004517          	auipc	a0,0x4
    800044d2:	1d250513          	addi	a0,a0,466 # 800086a0 <syscalls+0x218>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	068080e7          	jalr	104(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044de:	00878713          	addi	a4,a5,8
    800044e2:	00271693          	slli	a3,a4,0x2
    800044e6:	0001d717          	auipc	a4,0x1d
    800044ea:	d8a70713          	addi	a4,a4,-630 # 80021270 <log>
    800044ee:	9736                	add	a4,a4,a3
    800044f0:	44d4                	lw	a3,12(s1)
    800044f2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044f4:	faf608e3          	beq	a2,a5,800044a4 <log_write+0x76>
  }
  release(&log.lock);
    800044f8:	0001d517          	auipc	a0,0x1d
    800044fc:	d7850513          	addi	a0,a0,-648 # 80021270 <log>
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	798080e7          	jalr	1944(ra) # 80000c98 <release>
}
    80004508:	60e2                	ld	ra,24(sp)
    8000450a:	6442                	ld	s0,16(sp)
    8000450c:	64a2                	ld	s1,8(sp)
    8000450e:	6902                	ld	s2,0(sp)
    80004510:	6105                	addi	sp,sp,32
    80004512:	8082                	ret

0000000080004514 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004514:	1101                	addi	sp,sp,-32
    80004516:	ec06                	sd	ra,24(sp)
    80004518:	e822                	sd	s0,16(sp)
    8000451a:	e426                	sd	s1,8(sp)
    8000451c:	e04a                	sd	s2,0(sp)
    8000451e:	1000                	addi	s0,sp,32
    80004520:	84aa                	mv	s1,a0
    80004522:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004524:	00004597          	auipc	a1,0x4
    80004528:	19c58593          	addi	a1,a1,412 # 800086c0 <syscalls+0x238>
    8000452c:	0521                	addi	a0,a0,8
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	626080e7          	jalr	1574(ra) # 80000b54 <initlock>
  lk->name = name;
    80004536:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000453a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000453e:	0204a423          	sw	zero,40(s1)
}
    80004542:	60e2                	ld	ra,24(sp)
    80004544:	6442                	ld	s0,16(sp)
    80004546:	64a2                	ld	s1,8(sp)
    80004548:	6902                	ld	s2,0(sp)
    8000454a:	6105                	addi	sp,sp,32
    8000454c:	8082                	ret

000000008000454e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000454e:	1101                	addi	sp,sp,-32
    80004550:	ec06                	sd	ra,24(sp)
    80004552:	e822                	sd	s0,16(sp)
    80004554:	e426                	sd	s1,8(sp)
    80004556:	e04a                	sd	s2,0(sp)
    80004558:	1000                	addi	s0,sp,32
    8000455a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000455c:	00850913          	addi	s2,a0,8
    80004560:	854a                	mv	a0,s2
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	682080e7          	jalr	1666(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000456a:	409c                	lw	a5,0(s1)
    8000456c:	cb89                	beqz	a5,8000457e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000456e:	85ca                	mv	a1,s2
    80004570:	8526                	mv	a0,s1
    80004572:	ffffe097          	auipc	ra,0xffffe
    80004576:	c1e080e7          	jalr	-994(ra) # 80002190 <sleep>
  while (lk->locked) {
    8000457a:	409c                	lw	a5,0(s1)
    8000457c:	fbed                	bnez	a5,8000456e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000457e:	4785                	li	a5,1
    80004580:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004582:	ffffd097          	auipc	ra,0xffffd
    80004586:	552080e7          	jalr	1362(ra) # 80001ad4 <myproc>
    8000458a:	591c                	lw	a5,48(a0)
    8000458c:	d49c                	sw	a5,40(s1)
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

00000000800045a4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045a4:	1101                	addi	sp,sp,-32
    800045a6:	ec06                	sd	ra,24(sp)
    800045a8:	e822                	sd	s0,16(sp)
    800045aa:	e426                	sd	s1,8(sp)
    800045ac:	e04a                	sd	s2,0(sp)
    800045ae:	1000                	addi	s0,sp,32
    800045b0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045b2:	00850913          	addi	s2,a0,8
    800045b6:	854a                	mv	a0,s2
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	62c080e7          	jalr	1580(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800045c0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045c4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045c8:	8526                	mv	a0,s1
    800045ca:	ffffe097          	auipc	ra,0xffffe
    800045ce:	e50080e7          	jalr	-432(ra) # 8000241a <wakeup>
  release(&lk->lk);
    800045d2:	854a                	mv	a0,s2
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	6c4080e7          	jalr	1732(ra) # 80000c98 <release>
}
    800045dc:	60e2                	ld	ra,24(sp)
    800045de:	6442                	ld	s0,16(sp)
    800045e0:	64a2                	ld	s1,8(sp)
    800045e2:	6902                	ld	s2,0(sp)
    800045e4:	6105                	addi	sp,sp,32
    800045e6:	8082                	ret

00000000800045e8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045e8:	7179                	addi	sp,sp,-48
    800045ea:	f406                	sd	ra,40(sp)
    800045ec:	f022                	sd	s0,32(sp)
    800045ee:	ec26                	sd	s1,24(sp)
    800045f0:	e84a                	sd	s2,16(sp)
    800045f2:	e44e                	sd	s3,8(sp)
    800045f4:	1800                	addi	s0,sp,48
    800045f6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045f8:	00850913          	addi	s2,a0,8
    800045fc:	854a                	mv	a0,s2
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	5e6080e7          	jalr	1510(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004606:	409c                	lw	a5,0(s1)
    80004608:	ef99                	bnez	a5,80004626 <holdingsleep+0x3e>
    8000460a:	4481                	li	s1,0
  release(&lk->lk);
    8000460c:	854a                	mv	a0,s2
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	68a080e7          	jalr	1674(ra) # 80000c98 <release>
  return r;
}
    80004616:	8526                	mv	a0,s1
    80004618:	70a2                	ld	ra,40(sp)
    8000461a:	7402                	ld	s0,32(sp)
    8000461c:	64e2                	ld	s1,24(sp)
    8000461e:	6942                	ld	s2,16(sp)
    80004620:	69a2                	ld	s3,8(sp)
    80004622:	6145                	addi	sp,sp,48
    80004624:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004626:	0284a983          	lw	s3,40(s1)
    8000462a:	ffffd097          	auipc	ra,0xffffd
    8000462e:	4aa080e7          	jalr	1194(ra) # 80001ad4 <myproc>
    80004632:	5904                	lw	s1,48(a0)
    80004634:	413484b3          	sub	s1,s1,s3
    80004638:	0014b493          	seqz	s1,s1
    8000463c:	bfc1                	j	8000460c <holdingsleep+0x24>

000000008000463e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000463e:	1141                	addi	sp,sp,-16
    80004640:	e406                	sd	ra,8(sp)
    80004642:	e022                	sd	s0,0(sp)
    80004644:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004646:	00004597          	auipc	a1,0x4
    8000464a:	08a58593          	addi	a1,a1,138 # 800086d0 <syscalls+0x248>
    8000464e:	0001d517          	auipc	a0,0x1d
    80004652:	d6a50513          	addi	a0,a0,-662 # 800213b8 <ftable>
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	4fe080e7          	jalr	1278(ra) # 80000b54 <initlock>
}
    8000465e:	60a2                	ld	ra,8(sp)
    80004660:	6402                	ld	s0,0(sp)
    80004662:	0141                	addi	sp,sp,16
    80004664:	8082                	ret

0000000080004666 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004666:	1101                	addi	sp,sp,-32
    80004668:	ec06                	sd	ra,24(sp)
    8000466a:	e822                	sd	s0,16(sp)
    8000466c:	e426                	sd	s1,8(sp)
    8000466e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004670:	0001d517          	auipc	a0,0x1d
    80004674:	d4850513          	addi	a0,a0,-696 # 800213b8 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	56c080e7          	jalr	1388(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004680:	0001d497          	auipc	s1,0x1d
    80004684:	d5048493          	addi	s1,s1,-688 # 800213d0 <ftable+0x18>
    80004688:	0001e717          	auipc	a4,0x1e
    8000468c:	ce870713          	addi	a4,a4,-792 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004690:	40dc                	lw	a5,4(s1)
    80004692:	cf99                	beqz	a5,800046b0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004694:	02848493          	addi	s1,s1,40
    80004698:	fee49ce3          	bne	s1,a4,80004690 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000469c:	0001d517          	auipc	a0,0x1d
    800046a0:	d1c50513          	addi	a0,a0,-740 # 800213b8 <ftable>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	5f4080e7          	jalr	1524(ra) # 80000c98 <release>
  return 0;
    800046ac:	4481                	li	s1,0
    800046ae:	a819                	j	800046c4 <filealloc+0x5e>
      f->ref = 1;
    800046b0:	4785                	li	a5,1
    800046b2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046b4:	0001d517          	auipc	a0,0x1d
    800046b8:	d0450513          	addi	a0,a0,-764 # 800213b8 <ftable>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	5dc080e7          	jalr	1500(ra) # 80000c98 <release>
}
    800046c4:	8526                	mv	a0,s1
    800046c6:	60e2                	ld	ra,24(sp)
    800046c8:	6442                	ld	s0,16(sp)
    800046ca:	64a2                	ld	s1,8(sp)
    800046cc:	6105                	addi	sp,sp,32
    800046ce:	8082                	ret

00000000800046d0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046d0:	1101                	addi	sp,sp,-32
    800046d2:	ec06                	sd	ra,24(sp)
    800046d4:	e822                	sd	s0,16(sp)
    800046d6:	e426                	sd	s1,8(sp)
    800046d8:	1000                	addi	s0,sp,32
    800046da:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046dc:	0001d517          	auipc	a0,0x1d
    800046e0:	cdc50513          	addi	a0,a0,-804 # 800213b8 <ftable>
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	500080e7          	jalr	1280(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046ec:	40dc                	lw	a5,4(s1)
    800046ee:	02f05263          	blez	a5,80004712 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046f2:	2785                	addiw	a5,a5,1
    800046f4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046f6:	0001d517          	auipc	a0,0x1d
    800046fa:	cc250513          	addi	a0,a0,-830 # 800213b8 <ftable>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	59a080e7          	jalr	1434(ra) # 80000c98 <release>
  return f;
}
    80004706:	8526                	mv	a0,s1
    80004708:	60e2                	ld	ra,24(sp)
    8000470a:	6442                	ld	s0,16(sp)
    8000470c:	64a2                	ld	s1,8(sp)
    8000470e:	6105                	addi	sp,sp,32
    80004710:	8082                	ret
    panic("filedup");
    80004712:	00004517          	auipc	a0,0x4
    80004716:	fc650513          	addi	a0,a0,-58 # 800086d8 <syscalls+0x250>
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	e24080e7          	jalr	-476(ra) # 8000053e <panic>

0000000080004722 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004722:	7139                	addi	sp,sp,-64
    80004724:	fc06                	sd	ra,56(sp)
    80004726:	f822                	sd	s0,48(sp)
    80004728:	f426                	sd	s1,40(sp)
    8000472a:	f04a                	sd	s2,32(sp)
    8000472c:	ec4e                	sd	s3,24(sp)
    8000472e:	e852                	sd	s4,16(sp)
    80004730:	e456                	sd	s5,8(sp)
    80004732:	0080                	addi	s0,sp,64
    80004734:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004736:	0001d517          	auipc	a0,0x1d
    8000473a:	c8250513          	addi	a0,a0,-894 # 800213b8 <ftable>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	4a6080e7          	jalr	1190(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004746:	40dc                	lw	a5,4(s1)
    80004748:	06f05163          	blez	a5,800047aa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000474c:	37fd                	addiw	a5,a5,-1
    8000474e:	0007871b          	sext.w	a4,a5
    80004752:	c0dc                	sw	a5,4(s1)
    80004754:	06e04363          	bgtz	a4,800047ba <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004758:	0004a903          	lw	s2,0(s1)
    8000475c:	0094ca83          	lbu	s5,9(s1)
    80004760:	0104ba03          	ld	s4,16(s1)
    80004764:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004768:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000476c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004770:	0001d517          	auipc	a0,0x1d
    80004774:	c4850513          	addi	a0,a0,-952 # 800213b8 <ftable>
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	520080e7          	jalr	1312(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004780:	4785                	li	a5,1
    80004782:	04f90d63          	beq	s2,a5,800047dc <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004786:	3979                	addiw	s2,s2,-2
    80004788:	4785                	li	a5,1
    8000478a:	0527e063          	bltu	a5,s2,800047ca <fileclose+0xa8>
    begin_op();
    8000478e:	00000097          	auipc	ra,0x0
    80004792:	ac8080e7          	jalr	-1336(ra) # 80004256 <begin_op>
    iput(ff.ip);
    80004796:	854e                	mv	a0,s3
    80004798:	fffff097          	auipc	ra,0xfffff
    8000479c:	2a6080e7          	jalr	678(ra) # 80003a3e <iput>
    end_op();
    800047a0:	00000097          	auipc	ra,0x0
    800047a4:	b36080e7          	jalr	-1226(ra) # 800042d6 <end_op>
    800047a8:	a00d                	j	800047ca <fileclose+0xa8>
    panic("fileclose");
    800047aa:	00004517          	auipc	a0,0x4
    800047ae:	f3650513          	addi	a0,a0,-202 # 800086e0 <syscalls+0x258>
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	d8c080e7          	jalr	-628(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047ba:	0001d517          	auipc	a0,0x1d
    800047be:	bfe50513          	addi	a0,a0,-1026 # 800213b8 <ftable>
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	4d6080e7          	jalr	1238(ra) # 80000c98 <release>
  }
}
    800047ca:	70e2                	ld	ra,56(sp)
    800047cc:	7442                	ld	s0,48(sp)
    800047ce:	74a2                	ld	s1,40(sp)
    800047d0:	7902                	ld	s2,32(sp)
    800047d2:	69e2                	ld	s3,24(sp)
    800047d4:	6a42                	ld	s4,16(sp)
    800047d6:	6aa2                	ld	s5,8(sp)
    800047d8:	6121                	addi	sp,sp,64
    800047da:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047dc:	85d6                	mv	a1,s5
    800047de:	8552                	mv	a0,s4
    800047e0:	00000097          	auipc	ra,0x0
    800047e4:	34c080e7          	jalr	844(ra) # 80004b2c <pipeclose>
    800047e8:	b7cd                	j	800047ca <fileclose+0xa8>

00000000800047ea <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047ea:	715d                	addi	sp,sp,-80
    800047ec:	e486                	sd	ra,72(sp)
    800047ee:	e0a2                	sd	s0,64(sp)
    800047f0:	fc26                	sd	s1,56(sp)
    800047f2:	f84a                	sd	s2,48(sp)
    800047f4:	f44e                	sd	s3,40(sp)
    800047f6:	0880                	addi	s0,sp,80
    800047f8:	84aa                	mv	s1,a0
    800047fa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047fc:	ffffd097          	auipc	ra,0xffffd
    80004800:	2d8080e7          	jalr	728(ra) # 80001ad4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004804:	409c                	lw	a5,0(s1)
    80004806:	37f9                	addiw	a5,a5,-2
    80004808:	4705                	li	a4,1
    8000480a:	04f76763          	bltu	a4,a5,80004858 <filestat+0x6e>
    8000480e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004810:	6c88                	ld	a0,24(s1)
    80004812:	fffff097          	auipc	ra,0xfffff
    80004816:	072080e7          	jalr	114(ra) # 80003884 <ilock>
    stati(f->ip, &st);
    8000481a:	fb840593          	addi	a1,s0,-72
    8000481e:	6c88                	ld	a0,24(s1)
    80004820:	fffff097          	auipc	ra,0xfffff
    80004824:	2ee080e7          	jalr	750(ra) # 80003b0e <stati>
    iunlock(f->ip);
    80004828:	6c88                	ld	a0,24(s1)
    8000482a:	fffff097          	auipc	ra,0xfffff
    8000482e:	11c080e7          	jalr	284(ra) # 80003946 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004832:	46e1                	li	a3,24
    80004834:	fb840613          	addi	a2,s0,-72
    80004838:	85ce                	mv	a1,s3
    8000483a:	05093503          	ld	a0,80(s2)
    8000483e:	ffffd097          	auipc	ra,0xffffd
    80004842:	f58080e7          	jalr	-168(ra) # 80001796 <copyout>
    80004846:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000484a:	60a6                	ld	ra,72(sp)
    8000484c:	6406                	ld	s0,64(sp)
    8000484e:	74e2                	ld	s1,56(sp)
    80004850:	7942                	ld	s2,48(sp)
    80004852:	79a2                	ld	s3,40(sp)
    80004854:	6161                	addi	sp,sp,80
    80004856:	8082                	ret
  return -1;
    80004858:	557d                	li	a0,-1
    8000485a:	bfc5                	j	8000484a <filestat+0x60>

000000008000485c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000485c:	7179                	addi	sp,sp,-48
    8000485e:	f406                	sd	ra,40(sp)
    80004860:	f022                	sd	s0,32(sp)
    80004862:	ec26                	sd	s1,24(sp)
    80004864:	e84a                	sd	s2,16(sp)
    80004866:	e44e                	sd	s3,8(sp)
    80004868:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000486a:	00854783          	lbu	a5,8(a0)
    8000486e:	c3d5                	beqz	a5,80004912 <fileread+0xb6>
    80004870:	84aa                	mv	s1,a0
    80004872:	89ae                	mv	s3,a1
    80004874:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004876:	411c                	lw	a5,0(a0)
    80004878:	4705                	li	a4,1
    8000487a:	04e78963          	beq	a5,a4,800048cc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000487e:	470d                	li	a4,3
    80004880:	04e78d63          	beq	a5,a4,800048da <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004884:	4709                	li	a4,2
    80004886:	06e79e63          	bne	a5,a4,80004902 <fileread+0xa6>
    ilock(f->ip);
    8000488a:	6d08                	ld	a0,24(a0)
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	ff8080e7          	jalr	-8(ra) # 80003884 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004894:	874a                	mv	a4,s2
    80004896:	5094                	lw	a3,32(s1)
    80004898:	864e                	mv	a2,s3
    8000489a:	4585                	li	a1,1
    8000489c:	6c88                	ld	a0,24(s1)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	29a080e7          	jalr	666(ra) # 80003b38 <readi>
    800048a6:	892a                	mv	s2,a0
    800048a8:	00a05563          	blez	a0,800048b2 <fileread+0x56>
      f->off += r;
    800048ac:	509c                	lw	a5,32(s1)
    800048ae:	9fa9                	addw	a5,a5,a0
    800048b0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048b2:	6c88                	ld	a0,24(s1)
    800048b4:	fffff097          	auipc	ra,0xfffff
    800048b8:	092080e7          	jalr	146(ra) # 80003946 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048bc:	854a                	mv	a0,s2
    800048be:	70a2                	ld	ra,40(sp)
    800048c0:	7402                	ld	s0,32(sp)
    800048c2:	64e2                	ld	s1,24(sp)
    800048c4:	6942                	ld	s2,16(sp)
    800048c6:	69a2                	ld	s3,8(sp)
    800048c8:	6145                	addi	sp,sp,48
    800048ca:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048cc:	6908                	ld	a0,16(a0)
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	3c8080e7          	jalr	968(ra) # 80004c96 <piperead>
    800048d6:	892a                	mv	s2,a0
    800048d8:	b7d5                	j	800048bc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048da:	02451783          	lh	a5,36(a0)
    800048de:	03079693          	slli	a3,a5,0x30
    800048e2:	92c1                	srli	a3,a3,0x30
    800048e4:	4725                	li	a4,9
    800048e6:	02d76863          	bltu	a4,a3,80004916 <fileread+0xba>
    800048ea:	0792                	slli	a5,a5,0x4
    800048ec:	0001d717          	auipc	a4,0x1d
    800048f0:	a2c70713          	addi	a4,a4,-1492 # 80021318 <devsw>
    800048f4:	97ba                	add	a5,a5,a4
    800048f6:	639c                	ld	a5,0(a5)
    800048f8:	c38d                	beqz	a5,8000491a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048fa:	4505                	li	a0,1
    800048fc:	9782                	jalr	a5
    800048fe:	892a                	mv	s2,a0
    80004900:	bf75                	j	800048bc <fileread+0x60>
    panic("fileread");
    80004902:	00004517          	auipc	a0,0x4
    80004906:	dee50513          	addi	a0,a0,-530 # 800086f0 <syscalls+0x268>
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	c34080e7          	jalr	-972(ra) # 8000053e <panic>
    return -1;
    80004912:	597d                	li	s2,-1
    80004914:	b765                	j	800048bc <fileread+0x60>
      return -1;
    80004916:	597d                	li	s2,-1
    80004918:	b755                	j	800048bc <fileread+0x60>
    8000491a:	597d                	li	s2,-1
    8000491c:	b745                	j	800048bc <fileread+0x60>

000000008000491e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000491e:	715d                	addi	sp,sp,-80
    80004920:	e486                	sd	ra,72(sp)
    80004922:	e0a2                	sd	s0,64(sp)
    80004924:	fc26                	sd	s1,56(sp)
    80004926:	f84a                	sd	s2,48(sp)
    80004928:	f44e                	sd	s3,40(sp)
    8000492a:	f052                	sd	s4,32(sp)
    8000492c:	ec56                	sd	s5,24(sp)
    8000492e:	e85a                	sd	s6,16(sp)
    80004930:	e45e                	sd	s7,8(sp)
    80004932:	e062                	sd	s8,0(sp)
    80004934:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004936:	00954783          	lbu	a5,9(a0)
    8000493a:	10078663          	beqz	a5,80004a46 <filewrite+0x128>
    8000493e:	892a                	mv	s2,a0
    80004940:	8aae                	mv	s5,a1
    80004942:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004944:	411c                	lw	a5,0(a0)
    80004946:	4705                	li	a4,1
    80004948:	02e78263          	beq	a5,a4,8000496c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000494c:	470d                	li	a4,3
    8000494e:	02e78663          	beq	a5,a4,8000497a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004952:	4709                	li	a4,2
    80004954:	0ee79163          	bne	a5,a4,80004a36 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004958:	0ac05d63          	blez	a2,80004a12 <filewrite+0xf4>
    int i = 0;
    8000495c:	4981                	li	s3,0
    8000495e:	6b05                	lui	s6,0x1
    80004960:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004964:	6b85                	lui	s7,0x1
    80004966:	c00b8b9b          	addiw	s7,s7,-1024
    8000496a:	a861                	j	80004a02 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000496c:	6908                	ld	a0,16(a0)
    8000496e:	00000097          	auipc	ra,0x0
    80004972:	22e080e7          	jalr	558(ra) # 80004b9c <pipewrite>
    80004976:	8a2a                	mv	s4,a0
    80004978:	a045                	j	80004a18 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000497a:	02451783          	lh	a5,36(a0)
    8000497e:	03079693          	slli	a3,a5,0x30
    80004982:	92c1                	srli	a3,a3,0x30
    80004984:	4725                	li	a4,9
    80004986:	0cd76263          	bltu	a4,a3,80004a4a <filewrite+0x12c>
    8000498a:	0792                	slli	a5,a5,0x4
    8000498c:	0001d717          	auipc	a4,0x1d
    80004990:	98c70713          	addi	a4,a4,-1652 # 80021318 <devsw>
    80004994:	97ba                	add	a5,a5,a4
    80004996:	679c                	ld	a5,8(a5)
    80004998:	cbdd                	beqz	a5,80004a4e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000499a:	4505                	li	a0,1
    8000499c:	9782                	jalr	a5
    8000499e:	8a2a                	mv	s4,a0
    800049a0:	a8a5                	j	80004a18 <filewrite+0xfa>
    800049a2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049a6:	00000097          	auipc	ra,0x0
    800049aa:	8b0080e7          	jalr	-1872(ra) # 80004256 <begin_op>
      ilock(f->ip);
    800049ae:	01893503          	ld	a0,24(s2)
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	ed2080e7          	jalr	-302(ra) # 80003884 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049ba:	8762                	mv	a4,s8
    800049bc:	02092683          	lw	a3,32(s2)
    800049c0:	01598633          	add	a2,s3,s5
    800049c4:	4585                	li	a1,1
    800049c6:	01893503          	ld	a0,24(s2)
    800049ca:	fffff097          	auipc	ra,0xfffff
    800049ce:	266080e7          	jalr	614(ra) # 80003c30 <writei>
    800049d2:	84aa                	mv	s1,a0
    800049d4:	00a05763          	blez	a0,800049e2 <filewrite+0xc4>
        f->off += r;
    800049d8:	02092783          	lw	a5,32(s2)
    800049dc:	9fa9                	addw	a5,a5,a0
    800049de:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049e2:	01893503          	ld	a0,24(s2)
    800049e6:	fffff097          	auipc	ra,0xfffff
    800049ea:	f60080e7          	jalr	-160(ra) # 80003946 <iunlock>
      end_op();
    800049ee:	00000097          	auipc	ra,0x0
    800049f2:	8e8080e7          	jalr	-1816(ra) # 800042d6 <end_op>

      if(r != n1){
    800049f6:	009c1f63          	bne	s8,s1,80004a14 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049fa:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049fe:	0149db63          	bge	s3,s4,80004a14 <filewrite+0xf6>
      int n1 = n - i;
    80004a02:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a06:	84be                	mv	s1,a5
    80004a08:	2781                	sext.w	a5,a5
    80004a0a:	f8fb5ce3          	bge	s6,a5,800049a2 <filewrite+0x84>
    80004a0e:	84de                	mv	s1,s7
    80004a10:	bf49                	j	800049a2 <filewrite+0x84>
    int i = 0;
    80004a12:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a14:	013a1f63          	bne	s4,s3,80004a32 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a18:	8552                	mv	a0,s4
    80004a1a:	60a6                	ld	ra,72(sp)
    80004a1c:	6406                	ld	s0,64(sp)
    80004a1e:	74e2                	ld	s1,56(sp)
    80004a20:	7942                	ld	s2,48(sp)
    80004a22:	79a2                	ld	s3,40(sp)
    80004a24:	7a02                	ld	s4,32(sp)
    80004a26:	6ae2                	ld	s5,24(sp)
    80004a28:	6b42                	ld	s6,16(sp)
    80004a2a:	6ba2                	ld	s7,8(sp)
    80004a2c:	6c02                	ld	s8,0(sp)
    80004a2e:	6161                	addi	sp,sp,80
    80004a30:	8082                	ret
    ret = (i == n ? n : -1);
    80004a32:	5a7d                	li	s4,-1
    80004a34:	b7d5                	j	80004a18 <filewrite+0xfa>
    panic("filewrite");
    80004a36:	00004517          	auipc	a0,0x4
    80004a3a:	cca50513          	addi	a0,a0,-822 # 80008700 <syscalls+0x278>
    80004a3e:	ffffc097          	auipc	ra,0xffffc
    80004a42:	b00080e7          	jalr	-1280(ra) # 8000053e <panic>
    return -1;
    80004a46:	5a7d                	li	s4,-1
    80004a48:	bfc1                	j	80004a18 <filewrite+0xfa>
      return -1;
    80004a4a:	5a7d                	li	s4,-1
    80004a4c:	b7f1                	j	80004a18 <filewrite+0xfa>
    80004a4e:	5a7d                	li	s4,-1
    80004a50:	b7e1                	j	80004a18 <filewrite+0xfa>

0000000080004a52 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a52:	7179                	addi	sp,sp,-48
    80004a54:	f406                	sd	ra,40(sp)
    80004a56:	f022                	sd	s0,32(sp)
    80004a58:	ec26                	sd	s1,24(sp)
    80004a5a:	e84a                	sd	s2,16(sp)
    80004a5c:	e44e                	sd	s3,8(sp)
    80004a5e:	e052                	sd	s4,0(sp)
    80004a60:	1800                	addi	s0,sp,48
    80004a62:	84aa                	mv	s1,a0
    80004a64:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a66:	0005b023          	sd	zero,0(a1)
    80004a6a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	bf8080e7          	jalr	-1032(ra) # 80004666 <filealloc>
    80004a76:	e088                	sd	a0,0(s1)
    80004a78:	c551                	beqz	a0,80004b04 <pipealloc+0xb2>
    80004a7a:	00000097          	auipc	ra,0x0
    80004a7e:	bec080e7          	jalr	-1044(ra) # 80004666 <filealloc>
    80004a82:	00aa3023          	sd	a0,0(s4)
    80004a86:	c92d                	beqz	a0,80004af8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	06c080e7          	jalr	108(ra) # 80000af4 <kalloc>
    80004a90:	892a                	mv	s2,a0
    80004a92:	c125                	beqz	a0,80004af2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a94:	4985                	li	s3,1
    80004a96:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a9a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a9e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aa2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004aa6:	00004597          	auipc	a1,0x4
    80004aaa:	c6a58593          	addi	a1,a1,-918 # 80008710 <syscalls+0x288>
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	0a6080e7          	jalr	166(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004ab6:	609c                	ld	a5,0(s1)
    80004ab8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004abc:	609c                	ld	a5,0(s1)
    80004abe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ac2:	609c                	ld	a5,0(s1)
    80004ac4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ac8:	609c                	ld	a5,0(s1)
    80004aca:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ace:	000a3783          	ld	a5,0(s4)
    80004ad2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ad6:	000a3783          	ld	a5,0(s4)
    80004ada:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ade:	000a3783          	ld	a5,0(s4)
    80004ae2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ae6:	000a3783          	ld	a5,0(s4)
    80004aea:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aee:	4501                	li	a0,0
    80004af0:	a025                	j	80004b18 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004af2:	6088                	ld	a0,0(s1)
    80004af4:	e501                	bnez	a0,80004afc <pipealloc+0xaa>
    80004af6:	a039                	j	80004b04 <pipealloc+0xb2>
    80004af8:	6088                	ld	a0,0(s1)
    80004afa:	c51d                	beqz	a0,80004b28 <pipealloc+0xd6>
    fileclose(*f0);
    80004afc:	00000097          	auipc	ra,0x0
    80004b00:	c26080e7          	jalr	-986(ra) # 80004722 <fileclose>
  if(*f1)
    80004b04:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b08:	557d                	li	a0,-1
  if(*f1)
    80004b0a:	c799                	beqz	a5,80004b18 <pipealloc+0xc6>
    fileclose(*f1);
    80004b0c:	853e                	mv	a0,a5
    80004b0e:	00000097          	auipc	ra,0x0
    80004b12:	c14080e7          	jalr	-1004(ra) # 80004722 <fileclose>
  return -1;
    80004b16:	557d                	li	a0,-1
}
    80004b18:	70a2                	ld	ra,40(sp)
    80004b1a:	7402                	ld	s0,32(sp)
    80004b1c:	64e2                	ld	s1,24(sp)
    80004b1e:	6942                	ld	s2,16(sp)
    80004b20:	69a2                	ld	s3,8(sp)
    80004b22:	6a02                	ld	s4,0(sp)
    80004b24:	6145                	addi	sp,sp,48
    80004b26:	8082                	ret
  return -1;
    80004b28:	557d                	li	a0,-1
    80004b2a:	b7fd                	j	80004b18 <pipealloc+0xc6>

0000000080004b2c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b2c:	1101                	addi	sp,sp,-32
    80004b2e:	ec06                	sd	ra,24(sp)
    80004b30:	e822                	sd	s0,16(sp)
    80004b32:	e426                	sd	s1,8(sp)
    80004b34:	e04a                	sd	s2,0(sp)
    80004b36:	1000                	addi	s0,sp,32
    80004b38:	84aa                	mv	s1,a0
    80004b3a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	0a8080e7          	jalr	168(ra) # 80000be4 <acquire>
  if(writable){
    80004b44:	02090d63          	beqz	s2,80004b7e <pipeclose+0x52>
    pi->writeopen = 0;
    80004b48:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b4c:	21848513          	addi	a0,s1,536
    80004b50:	ffffe097          	auipc	ra,0xffffe
    80004b54:	8ca080e7          	jalr	-1846(ra) # 8000241a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b58:	2204b783          	ld	a5,544(s1)
    80004b5c:	eb95                	bnez	a5,80004b90 <pipeclose+0x64>
    release(&pi->lock);
    80004b5e:	8526                	mv	a0,s1
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	138080e7          	jalr	312(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b68:	8526                	mv	a0,s1
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	e8e080e7          	jalr	-370(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b72:	60e2                	ld	ra,24(sp)
    80004b74:	6442                	ld	s0,16(sp)
    80004b76:	64a2                	ld	s1,8(sp)
    80004b78:	6902                	ld	s2,0(sp)
    80004b7a:	6105                	addi	sp,sp,32
    80004b7c:	8082                	ret
    pi->readopen = 0;
    80004b7e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b82:	21c48513          	addi	a0,s1,540
    80004b86:	ffffe097          	auipc	ra,0xffffe
    80004b8a:	894080e7          	jalr	-1900(ra) # 8000241a <wakeup>
    80004b8e:	b7e9                	j	80004b58 <pipeclose+0x2c>
    release(&pi->lock);
    80004b90:	8526                	mv	a0,s1
    80004b92:	ffffc097          	auipc	ra,0xffffc
    80004b96:	106080e7          	jalr	262(ra) # 80000c98 <release>
}
    80004b9a:	bfe1                	j	80004b72 <pipeclose+0x46>

0000000080004b9c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b9c:	7159                	addi	sp,sp,-112
    80004b9e:	f486                	sd	ra,104(sp)
    80004ba0:	f0a2                	sd	s0,96(sp)
    80004ba2:	eca6                	sd	s1,88(sp)
    80004ba4:	e8ca                	sd	s2,80(sp)
    80004ba6:	e4ce                	sd	s3,72(sp)
    80004ba8:	e0d2                	sd	s4,64(sp)
    80004baa:	fc56                	sd	s5,56(sp)
    80004bac:	f85a                	sd	s6,48(sp)
    80004bae:	f45e                	sd	s7,40(sp)
    80004bb0:	f062                	sd	s8,32(sp)
    80004bb2:	ec66                	sd	s9,24(sp)
    80004bb4:	1880                	addi	s0,sp,112
    80004bb6:	84aa                	mv	s1,a0
    80004bb8:	8aae                	mv	s5,a1
    80004bba:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	f18080e7          	jalr	-232(ra) # 80001ad4 <myproc>
    80004bc4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	01c080e7          	jalr	28(ra) # 80000be4 <acquire>
  while(i < n){
    80004bd0:	0d405163          	blez	s4,80004c92 <pipewrite+0xf6>
    80004bd4:	8ba6                	mv	s7,s1
  int i = 0;
    80004bd6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bd8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bda:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bde:	21c48c13          	addi	s8,s1,540
    80004be2:	a08d                	j	80004c44 <pipewrite+0xa8>
      release(&pi->lock);
    80004be4:	8526                	mv	a0,s1
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
      return -1;
    80004bee:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bf0:	854a                	mv	a0,s2
    80004bf2:	70a6                	ld	ra,104(sp)
    80004bf4:	7406                	ld	s0,96(sp)
    80004bf6:	64e6                	ld	s1,88(sp)
    80004bf8:	6946                	ld	s2,80(sp)
    80004bfa:	69a6                	ld	s3,72(sp)
    80004bfc:	6a06                	ld	s4,64(sp)
    80004bfe:	7ae2                	ld	s5,56(sp)
    80004c00:	7b42                	ld	s6,48(sp)
    80004c02:	7ba2                	ld	s7,40(sp)
    80004c04:	7c02                	ld	s8,32(sp)
    80004c06:	6ce2                	ld	s9,24(sp)
    80004c08:	6165                	addi	sp,sp,112
    80004c0a:	8082                	ret
      wakeup(&pi->nread);
    80004c0c:	8566                	mv	a0,s9
    80004c0e:	ffffe097          	auipc	ra,0xffffe
    80004c12:	80c080e7          	jalr	-2036(ra) # 8000241a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c16:	85de                	mv	a1,s7
    80004c18:	8562                	mv	a0,s8
    80004c1a:	ffffd097          	auipc	ra,0xffffd
    80004c1e:	576080e7          	jalr	1398(ra) # 80002190 <sleep>
    80004c22:	a839                	j	80004c40 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c24:	21c4a783          	lw	a5,540(s1)
    80004c28:	0017871b          	addiw	a4,a5,1
    80004c2c:	20e4ae23          	sw	a4,540(s1)
    80004c30:	1ff7f793          	andi	a5,a5,511
    80004c34:	97a6                	add	a5,a5,s1
    80004c36:	f9f44703          	lbu	a4,-97(s0)
    80004c3a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c3e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c40:	03495d63          	bge	s2,s4,80004c7a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c44:	2204a783          	lw	a5,544(s1)
    80004c48:	dfd1                	beqz	a5,80004be4 <pipewrite+0x48>
    80004c4a:	0289a783          	lw	a5,40(s3)
    80004c4e:	fbd9                	bnez	a5,80004be4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c50:	2184a783          	lw	a5,536(s1)
    80004c54:	21c4a703          	lw	a4,540(s1)
    80004c58:	2007879b          	addiw	a5,a5,512
    80004c5c:	faf708e3          	beq	a4,a5,80004c0c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c60:	4685                	li	a3,1
    80004c62:	01590633          	add	a2,s2,s5
    80004c66:	f9f40593          	addi	a1,s0,-97
    80004c6a:	0509b503          	ld	a0,80(s3)
    80004c6e:	ffffd097          	auipc	ra,0xffffd
    80004c72:	bb4080e7          	jalr	-1100(ra) # 80001822 <copyin>
    80004c76:	fb6517e3          	bne	a0,s6,80004c24 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c7a:	21848513          	addi	a0,s1,536
    80004c7e:	ffffd097          	auipc	ra,0xffffd
    80004c82:	79c080e7          	jalr	1948(ra) # 8000241a <wakeup>
  release(&pi->lock);
    80004c86:	8526                	mv	a0,s1
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	010080e7          	jalr	16(ra) # 80000c98 <release>
  return i;
    80004c90:	b785                	j	80004bf0 <pipewrite+0x54>
  int i = 0;
    80004c92:	4901                	li	s2,0
    80004c94:	b7dd                	j	80004c7a <pipewrite+0xde>

0000000080004c96 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c96:	715d                	addi	sp,sp,-80
    80004c98:	e486                	sd	ra,72(sp)
    80004c9a:	e0a2                	sd	s0,64(sp)
    80004c9c:	fc26                	sd	s1,56(sp)
    80004c9e:	f84a                	sd	s2,48(sp)
    80004ca0:	f44e                	sd	s3,40(sp)
    80004ca2:	f052                	sd	s4,32(sp)
    80004ca4:	ec56                	sd	s5,24(sp)
    80004ca6:	e85a                	sd	s6,16(sp)
    80004ca8:	0880                	addi	s0,sp,80
    80004caa:	84aa                	mv	s1,a0
    80004cac:	892e                	mv	s2,a1
    80004cae:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cb0:	ffffd097          	auipc	ra,0xffffd
    80004cb4:	e24080e7          	jalr	-476(ra) # 80001ad4 <myproc>
    80004cb8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cba:	8b26                	mv	s6,s1
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	f26080e7          	jalr	-218(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cc6:	2184a703          	lw	a4,536(s1)
    80004cca:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cce:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd2:	02f71463          	bne	a4,a5,80004cfa <piperead+0x64>
    80004cd6:	2244a783          	lw	a5,548(s1)
    80004cda:	c385                	beqz	a5,80004cfa <piperead+0x64>
    if(pr->killed){
    80004cdc:	028a2783          	lw	a5,40(s4)
    80004ce0:	ebc1                	bnez	a5,80004d70 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ce2:	85da                	mv	a1,s6
    80004ce4:	854e                	mv	a0,s3
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	4aa080e7          	jalr	1194(ra) # 80002190 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cee:	2184a703          	lw	a4,536(s1)
    80004cf2:	21c4a783          	lw	a5,540(s1)
    80004cf6:	fef700e3          	beq	a4,a5,80004cd6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cfa:	09505263          	blez	s5,80004d7e <piperead+0xe8>
    80004cfe:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d00:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d02:	2184a783          	lw	a5,536(s1)
    80004d06:	21c4a703          	lw	a4,540(s1)
    80004d0a:	02f70d63          	beq	a4,a5,80004d44 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d0e:	0017871b          	addiw	a4,a5,1
    80004d12:	20e4ac23          	sw	a4,536(s1)
    80004d16:	1ff7f793          	andi	a5,a5,511
    80004d1a:	97a6                	add	a5,a5,s1
    80004d1c:	0187c783          	lbu	a5,24(a5)
    80004d20:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d24:	4685                	li	a3,1
    80004d26:	fbf40613          	addi	a2,s0,-65
    80004d2a:	85ca                	mv	a1,s2
    80004d2c:	050a3503          	ld	a0,80(s4)
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	a66080e7          	jalr	-1434(ra) # 80001796 <copyout>
    80004d38:	01650663          	beq	a0,s6,80004d44 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d3c:	2985                	addiw	s3,s3,1
    80004d3e:	0905                	addi	s2,s2,1
    80004d40:	fd3a91e3          	bne	s5,s3,80004d02 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d44:	21c48513          	addi	a0,s1,540
    80004d48:	ffffd097          	auipc	ra,0xffffd
    80004d4c:	6d2080e7          	jalr	1746(ra) # 8000241a <wakeup>
  release(&pi->lock);
    80004d50:	8526                	mv	a0,s1
    80004d52:	ffffc097          	auipc	ra,0xffffc
    80004d56:	f46080e7          	jalr	-186(ra) # 80000c98 <release>
  return i;
}
    80004d5a:	854e                	mv	a0,s3
    80004d5c:	60a6                	ld	ra,72(sp)
    80004d5e:	6406                	ld	s0,64(sp)
    80004d60:	74e2                	ld	s1,56(sp)
    80004d62:	7942                	ld	s2,48(sp)
    80004d64:	79a2                	ld	s3,40(sp)
    80004d66:	7a02                	ld	s4,32(sp)
    80004d68:	6ae2                	ld	s5,24(sp)
    80004d6a:	6b42                	ld	s6,16(sp)
    80004d6c:	6161                	addi	sp,sp,80
    80004d6e:	8082                	ret
      release(&pi->lock);
    80004d70:	8526                	mv	a0,s1
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	f26080e7          	jalr	-218(ra) # 80000c98 <release>
      return -1;
    80004d7a:	59fd                	li	s3,-1
    80004d7c:	bff9                	j	80004d5a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7e:	4981                	li	s3,0
    80004d80:	b7d1                	j	80004d44 <piperead+0xae>

0000000080004d82 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d82:	df010113          	addi	sp,sp,-528
    80004d86:	20113423          	sd	ra,520(sp)
    80004d8a:	20813023          	sd	s0,512(sp)
    80004d8e:	ffa6                	sd	s1,504(sp)
    80004d90:	fbca                	sd	s2,496(sp)
    80004d92:	f7ce                	sd	s3,488(sp)
    80004d94:	f3d2                	sd	s4,480(sp)
    80004d96:	efd6                	sd	s5,472(sp)
    80004d98:	ebda                	sd	s6,464(sp)
    80004d9a:	e7de                	sd	s7,456(sp)
    80004d9c:	e3e2                	sd	s8,448(sp)
    80004d9e:	ff66                	sd	s9,440(sp)
    80004da0:	fb6a                	sd	s10,432(sp)
    80004da2:	f76e                	sd	s11,424(sp)
    80004da4:	0c00                	addi	s0,sp,528
    80004da6:	84aa                	mv	s1,a0
    80004da8:	dea43c23          	sd	a0,-520(s0)
    80004dac:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	d24080e7          	jalr	-732(ra) # 80001ad4 <myproc>
    80004db8:	892a                	mv	s2,a0

  begin_op();
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	49c080e7          	jalr	1180(ra) # 80004256 <begin_op>

  if((ip = namei(path)) == 0){
    80004dc2:	8526                	mv	a0,s1
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	276080e7          	jalr	630(ra) # 8000403a <namei>
    80004dcc:	c92d                	beqz	a0,80004e3e <exec+0xbc>
    80004dce:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	ab4080e7          	jalr	-1356(ra) # 80003884 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dd8:	04000713          	li	a4,64
    80004ddc:	4681                	li	a3,0
    80004dde:	e5040613          	addi	a2,s0,-432
    80004de2:	4581                	li	a1,0
    80004de4:	8526                	mv	a0,s1
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	d52080e7          	jalr	-686(ra) # 80003b38 <readi>
    80004dee:	04000793          	li	a5,64
    80004df2:	00f51a63          	bne	a0,a5,80004e06 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004df6:	e5042703          	lw	a4,-432(s0)
    80004dfa:	464c47b7          	lui	a5,0x464c4
    80004dfe:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e02:	04f70463          	beq	a4,a5,80004e4a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e06:	8526                	mv	a0,s1
    80004e08:	fffff097          	auipc	ra,0xfffff
    80004e0c:	cde080e7          	jalr	-802(ra) # 80003ae6 <iunlockput>
    end_op();
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	4c6080e7          	jalr	1222(ra) # 800042d6 <end_op>
  }
  return -1;
    80004e18:	557d                	li	a0,-1
}
    80004e1a:	20813083          	ld	ra,520(sp)
    80004e1e:	20013403          	ld	s0,512(sp)
    80004e22:	74fe                	ld	s1,504(sp)
    80004e24:	795e                	ld	s2,496(sp)
    80004e26:	79be                	ld	s3,488(sp)
    80004e28:	7a1e                	ld	s4,480(sp)
    80004e2a:	6afe                	ld	s5,472(sp)
    80004e2c:	6b5e                	ld	s6,464(sp)
    80004e2e:	6bbe                	ld	s7,456(sp)
    80004e30:	6c1e                	ld	s8,448(sp)
    80004e32:	7cfa                	ld	s9,440(sp)
    80004e34:	7d5a                	ld	s10,432(sp)
    80004e36:	7dba                	ld	s11,424(sp)
    80004e38:	21010113          	addi	sp,sp,528
    80004e3c:	8082                	ret
    end_op();
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	498080e7          	jalr	1176(ra) # 800042d6 <end_op>
    return -1;
    80004e46:	557d                	li	a0,-1
    80004e48:	bfc9                	j	80004e1a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e4a:	854a                	mv	a0,s2
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	d4c080e7          	jalr	-692(ra) # 80001b98 <proc_pagetable>
    80004e54:	8baa                	mv	s7,a0
    80004e56:	d945                	beqz	a0,80004e06 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e58:	e7042983          	lw	s3,-400(s0)
    80004e5c:	e8845783          	lhu	a5,-376(s0)
    80004e60:	c7ad                	beqz	a5,80004eca <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e62:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e64:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e66:	6c85                	lui	s9,0x1
    80004e68:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e6c:	def43823          	sd	a5,-528(s0)
    80004e70:	a42d                	j	8000509a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e72:	00004517          	auipc	a0,0x4
    80004e76:	8a650513          	addi	a0,a0,-1882 # 80008718 <syscalls+0x290>
    80004e7a:	ffffb097          	auipc	ra,0xffffb
    80004e7e:	6c4080e7          	jalr	1732(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e82:	8756                	mv	a4,s5
    80004e84:	012d86bb          	addw	a3,s11,s2
    80004e88:	4581                	li	a1,0
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	fffff097          	auipc	ra,0xfffff
    80004e90:	cac080e7          	jalr	-852(ra) # 80003b38 <readi>
    80004e94:	2501                	sext.w	a0,a0
    80004e96:	1aaa9963          	bne	s5,a0,80005048 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e9a:	6785                	lui	a5,0x1
    80004e9c:	0127893b          	addw	s2,a5,s2
    80004ea0:	77fd                	lui	a5,0xfffff
    80004ea2:	01478a3b          	addw	s4,a5,s4
    80004ea6:	1f897163          	bgeu	s2,s8,80005088 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004eaa:	02091593          	slli	a1,s2,0x20
    80004eae:	9181                	srli	a1,a1,0x20
    80004eb0:	95ea                	add	a1,a1,s10
    80004eb2:	855e                	mv	a0,s7
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	2de080e7          	jalr	734(ra) # 80001192 <walkaddr>
    80004ebc:	862a                	mv	a2,a0
    if(pa == 0)
    80004ebe:	d955                	beqz	a0,80004e72 <exec+0xf0>
      n = PGSIZE;
    80004ec0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ec2:	fd9a70e3          	bgeu	s4,s9,80004e82 <exec+0x100>
      n = sz - i;
    80004ec6:	8ad2                	mv	s5,s4
    80004ec8:	bf6d                	j	80004e82 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eca:	4901                	li	s2,0
  iunlockput(ip);
    80004ecc:	8526                	mv	a0,s1
    80004ece:	fffff097          	auipc	ra,0xfffff
    80004ed2:	c18080e7          	jalr	-1000(ra) # 80003ae6 <iunlockput>
  end_op();
    80004ed6:	fffff097          	auipc	ra,0xfffff
    80004eda:	400080e7          	jalr	1024(ra) # 800042d6 <end_op>
  p = myproc();
    80004ede:	ffffd097          	auipc	ra,0xffffd
    80004ee2:	bf6080e7          	jalr	-1034(ra) # 80001ad4 <myproc>
    80004ee6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ee8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eec:	6785                	lui	a5,0x1
    80004eee:	17fd                	addi	a5,a5,-1
    80004ef0:	993e                	add	s2,s2,a5
    80004ef2:	757d                	lui	a0,0xfffff
    80004ef4:	00a977b3          	and	a5,s2,a0
    80004ef8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004efc:	6609                	lui	a2,0x2
    80004efe:	963e                	add	a2,a2,a5
    80004f00:	85be                	mv	a1,a5
    80004f02:	855e                	mv	a0,s7
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	642080e7          	jalr	1602(ra) # 80001546 <uvmalloc>
    80004f0c:	8b2a                	mv	s6,a0
  ip = 0;
    80004f0e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f10:	12050c63          	beqz	a0,80005048 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f14:	75f9                	lui	a1,0xffffe
    80004f16:	95aa                	add	a1,a1,a0
    80004f18:	855e                	mv	a0,s7
    80004f1a:	ffffd097          	auipc	ra,0xffffd
    80004f1e:	84a080e7          	jalr	-1974(ra) # 80001764 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f22:	7c7d                	lui	s8,0xfffff
    80004f24:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f26:	e0043783          	ld	a5,-512(s0)
    80004f2a:	6388                	ld	a0,0(a5)
    80004f2c:	c535                	beqz	a0,80004f98 <exec+0x216>
    80004f2e:	e9040993          	addi	s3,s0,-368
    80004f32:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f36:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	f2c080e7          	jalr	-212(ra) # 80000e64 <strlen>
    80004f40:	2505                	addiw	a0,a0,1
    80004f42:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f46:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f4a:	13896363          	bltu	s2,s8,80005070 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f4e:	e0043d83          	ld	s11,-512(s0)
    80004f52:	000dba03          	ld	s4,0(s11)
    80004f56:	8552                	mv	a0,s4
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	f0c080e7          	jalr	-244(ra) # 80000e64 <strlen>
    80004f60:	0015069b          	addiw	a3,a0,1
    80004f64:	8652                	mv	a2,s4
    80004f66:	85ca                	mv	a1,s2
    80004f68:	855e                	mv	a0,s7
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	82c080e7          	jalr	-2004(ra) # 80001796 <copyout>
    80004f72:	10054363          	bltz	a0,80005078 <exec+0x2f6>
    ustack[argc] = sp;
    80004f76:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f7a:	0485                	addi	s1,s1,1
    80004f7c:	008d8793          	addi	a5,s11,8
    80004f80:	e0f43023          	sd	a5,-512(s0)
    80004f84:	008db503          	ld	a0,8(s11)
    80004f88:	c911                	beqz	a0,80004f9c <exec+0x21a>
    if(argc >= MAXARG)
    80004f8a:	09a1                	addi	s3,s3,8
    80004f8c:	fb3c96e3          	bne	s9,s3,80004f38 <exec+0x1b6>
  sz = sz1;
    80004f90:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f94:	4481                	li	s1,0
    80004f96:	a84d                	j	80005048 <exec+0x2c6>
  sp = sz;
    80004f98:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f9a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f9c:	00349793          	slli	a5,s1,0x3
    80004fa0:	f9040713          	addi	a4,s0,-112
    80004fa4:	97ba                	add	a5,a5,a4
    80004fa6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004faa:	00148693          	addi	a3,s1,1
    80004fae:	068e                	slli	a3,a3,0x3
    80004fb0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fb4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fb8:	01897663          	bgeu	s2,s8,80004fc4 <exec+0x242>
  sz = sz1;
    80004fbc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc0:	4481                	li	s1,0
    80004fc2:	a059                	j	80005048 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fc4:	e9040613          	addi	a2,s0,-368
    80004fc8:	85ca                	mv	a1,s2
    80004fca:	855e                	mv	a0,s7
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	7ca080e7          	jalr	1994(ra) # 80001796 <copyout>
    80004fd4:	0a054663          	bltz	a0,80005080 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004fd8:	058ab783          	ld	a5,88(s5)
    80004fdc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fe0:	df843783          	ld	a5,-520(s0)
    80004fe4:	0007c703          	lbu	a4,0(a5)
    80004fe8:	cf11                	beqz	a4,80005004 <exec+0x282>
    80004fea:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fec:	02f00693          	li	a3,47
    80004ff0:	a039                	j	80004ffe <exec+0x27c>
      last = s+1;
    80004ff2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004ff6:	0785                	addi	a5,a5,1
    80004ff8:	fff7c703          	lbu	a4,-1(a5)
    80004ffc:	c701                	beqz	a4,80005004 <exec+0x282>
    if(*s == '/')
    80004ffe:	fed71ce3          	bne	a4,a3,80004ff6 <exec+0x274>
    80005002:	bfc5                	j	80004ff2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005004:	4641                	li	a2,16
    80005006:	df843583          	ld	a1,-520(s0)
    8000500a:	158a8513          	addi	a0,s5,344
    8000500e:	ffffc097          	auipc	ra,0xffffc
    80005012:	e24080e7          	jalr	-476(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005016:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000501a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000501e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005022:	058ab783          	ld	a5,88(s5)
    80005026:	e6843703          	ld	a4,-408(s0)
    8000502a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000502c:	058ab783          	ld	a5,88(s5)
    80005030:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005034:	85ea                	mv	a1,s10
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	bfe080e7          	jalr	-1026(ra) # 80001c34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000503e:	0004851b          	sext.w	a0,s1
    80005042:	bbe1                	j	80004e1a <exec+0x98>
    80005044:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005048:	e0843583          	ld	a1,-504(s0)
    8000504c:	855e                	mv	a0,s7
    8000504e:	ffffd097          	auipc	ra,0xffffd
    80005052:	be6080e7          	jalr	-1050(ra) # 80001c34 <proc_freepagetable>
  if(ip){
    80005056:	da0498e3          	bnez	s1,80004e06 <exec+0x84>
  return -1;
    8000505a:	557d                	li	a0,-1
    8000505c:	bb7d                	j	80004e1a <exec+0x98>
    8000505e:	e1243423          	sd	s2,-504(s0)
    80005062:	b7dd                	j	80005048 <exec+0x2c6>
    80005064:	e1243423          	sd	s2,-504(s0)
    80005068:	b7c5                	j	80005048 <exec+0x2c6>
    8000506a:	e1243423          	sd	s2,-504(s0)
    8000506e:	bfe9                	j	80005048 <exec+0x2c6>
  sz = sz1;
    80005070:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005074:	4481                	li	s1,0
    80005076:	bfc9                	j	80005048 <exec+0x2c6>
  sz = sz1;
    80005078:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000507c:	4481                	li	s1,0
    8000507e:	b7e9                	j	80005048 <exec+0x2c6>
  sz = sz1;
    80005080:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005084:	4481                	li	s1,0
    80005086:	b7c9                	j	80005048 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005088:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000508c:	2b05                	addiw	s6,s6,1
    8000508e:	0389899b          	addiw	s3,s3,56
    80005092:	e8845783          	lhu	a5,-376(s0)
    80005096:	e2fb5be3          	bge	s6,a5,80004ecc <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000509a:	2981                	sext.w	s3,s3
    8000509c:	03800713          	li	a4,56
    800050a0:	86ce                	mv	a3,s3
    800050a2:	e1840613          	addi	a2,s0,-488
    800050a6:	4581                	li	a1,0
    800050a8:	8526                	mv	a0,s1
    800050aa:	fffff097          	auipc	ra,0xfffff
    800050ae:	a8e080e7          	jalr	-1394(ra) # 80003b38 <readi>
    800050b2:	03800793          	li	a5,56
    800050b6:	f8f517e3          	bne	a0,a5,80005044 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050ba:	e1842783          	lw	a5,-488(s0)
    800050be:	4705                	li	a4,1
    800050c0:	fce796e3          	bne	a5,a4,8000508c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050c4:	e4043603          	ld	a2,-448(s0)
    800050c8:	e3843783          	ld	a5,-456(s0)
    800050cc:	f8f669e3          	bltu	a2,a5,8000505e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050d0:	e2843783          	ld	a5,-472(s0)
    800050d4:	963e                	add	a2,a2,a5
    800050d6:	f8f667e3          	bltu	a2,a5,80005064 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050da:	85ca                	mv	a1,s2
    800050dc:	855e                	mv	a0,s7
    800050de:	ffffc097          	auipc	ra,0xffffc
    800050e2:	468080e7          	jalr	1128(ra) # 80001546 <uvmalloc>
    800050e6:	e0a43423          	sd	a0,-504(s0)
    800050ea:	d141                	beqz	a0,8000506a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050ec:	e2843d03          	ld	s10,-472(s0)
    800050f0:	df043783          	ld	a5,-528(s0)
    800050f4:	00fd77b3          	and	a5,s10,a5
    800050f8:	fba1                	bnez	a5,80005048 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050fa:	e2042d83          	lw	s11,-480(s0)
    800050fe:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005102:	f80c03e3          	beqz	s8,80005088 <exec+0x306>
    80005106:	8a62                	mv	s4,s8
    80005108:	4901                	li	s2,0
    8000510a:	b345                	j	80004eaa <exec+0x128>

000000008000510c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000510c:	7179                	addi	sp,sp,-48
    8000510e:	f406                	sd	ra,40(sp)
    80005110:	f022                	sd	s0,32(sp)
    80005112:	ec26                	sd	s1,24(sp)
    80005114:	e84a                	sd	s2,16(sp)
    80005116:	1800                	addi	s0,sp,48
    80005118:	892e                	mv	s2,a1
    8000511a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000511c:	fdc40593          	addi	a1,s0,-36
    80005120:	ffffe097          	auipc	ra,0xffffe
    80005124:	ba8080e7          	jalr	-1112(ra) # 80002cc8 <argint>
    80005128:	04054063          	bltz	a0,80005168 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000512c:	fdc42703          	lw	a4,-36(s0)
    80005130:	47bd                	li	a5,15
    80005132:	02e7ed63          	bltu	a5,a4,8000516c <argfd+0x60>
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	99e080e7          	jalr	-1634(ra) # 80001ad4 <myproc>
    8000513e:	fdc42703          	lw	a4,-36(s0)
    80005142:	01a70793          	addi	a5,a4,26
    80005146:	078e                	slli	a5,a5,0x3
    80005148:	953e                	add	a0,a0,a5
    8000514a:	611c                	ld	a5,0(a0)
    8000514c:	c395                	beqz	a5,80005170 <argfd+0x64>
    return -1;
  if(pfd)
    8000514e:	00090463          	beqz	s2,80005156 <argfd+0x4a>
    *pfd = fd;
    80005152:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005156:	4501                	li	a0,0
  if(pf)
    80005158:	c091                	beqz	s1,8000515c <argfd+0x50>
    *pf = f;
    8000515a:	e09c                	sd	a5,0(s1)
}
    8000515c:	70a2                	ld	ra,40(sp)
    8000515e:	7402                	ld	s0,32(sp)
    80005160:	64e2                	ld	s1,24(sp)
    80005162:	6942                	ld	s2,16(sp)
    80005164:	6145                	addi	sp,sp,48
    80005166:	8082                	ret
    return -1;
    80005168:	557d                	li	a0,-1
    8000516a:	bfcd                	j	8000515c <argfd+0x50>
    return -1;
    8000516c:	557d                	li	a0,-1
    8000516e:	b7fd                	j	8000515c <argfd+0x50>
    80005170:	557d                	li	a0,-1
    80005172:	b7ed                	j	8000515c <argfd+0x50>

0000000080005174 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005174:	1101                	addi	sp,sp,-32
    80005176:	ec06                	sd	ra,24(sp)
    80005178:	e822                	sd	s0,16(sp)
    8000517a:	e426                	sd	s1,8(sp)
    8000517c:	1000                	addi	s0,sp,32
    8000517e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005180:	ffffd097          	auipc	ra,0xffffd
    80005184:	954080e7          	jalr	-1708(ra) # 80001ad4 <myproc>
    80005188:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000518a:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000518e:	4501                	li	a0,0
    80005190:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005192:	6398                	ld	a4,0(a5)
    80005194:	cb19                	beqz	a4,800051aa <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005196:	2505                	addiw	a0,a0,1
    80005198:	07a1                	addi	a5,a5,8
    8000519a:	fed51ce3          	bne	a0,a3,80005192 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000519e:	557d                	li	a0,-1
}
    800051a0:	60e2                	ld	ra,24(sp)
    800051a2:	6442                	ld	s0,16(sp)
    800051a4:	64a2                	ld	s1,8(sp)
    800051a6:	6105                	addi	sp,sp,32
    800051a8:	8082                	ret
      p->ofile[fd] = f;
    800051aa:	01a50793          	addi	a5,a0,26
    800051ae:	078e                	slli	a5,a5,0x3
    800051b0:	963e                	add	a2,a2,a5
    800051b2:	e204                	sd	s1,0(a2)
      return fd;
    800051b4:	b7f5                	j	800051a0 <fdalloc+0x2c>

00000000800051b6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051b6:	715d                	addi	sp,sp,-80
    800051b8:	e486                	sd	ra,72(sp)
    800051ba:	e0a2                	sd	s0,64(sp)
    800051bc:	fc26                	sd	s1,56(sp)
    800051be:	f84a                	sd	s2,48(sp)
    800051c0:	f44e                	sd	s3,40(sp)
    800051c2:	f052                	sd	s4,32(sp)
    800051c4:	ec56                	sd	s5,24(sp)
    800051c6:	0880                	addi	s0,sp,80
    800051c8:	89ae                	mv	s3,a1
    800051ca:	8ab2                	mv	s5,a2
    800051cc:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051ce:	fb040593          	addi	a1,s0,-80
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	e86080e7          	jalr	-378(ra) # 80004058 <nameiparent>
    800051da:	892a                	mv	s2,a0
    800051dc:	12050f63          	beqz	a0,8000531a <create+0x164>
    return 0;

  ilock(dp);
    800051e0:	ffffe097          	auipc	ra,0xffffe
    800051e4:	6a4080e7          	jalr	1700(ra) # 80003884 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051e8:	4601                	li	a2,0
    800051ea:	fb040593          	addi	a1,s0,-80
    800051ee:	854a                	mv	a0,s2
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	b78080e7          	jalr	-1160(ra) # 80003d68 <dirlookup>
    800051f8:	84aa                	mv	s1,a0
    800051fa:	c921                	beqz	a0,8000524a <create+0x94>
    iunlockput(dp);
    800051fc:	854a                	mv	a0,s2
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	8e8080e7          	jalr	-1816(ra) # 80003ae6 <iunlockput>
    ilock(ip);
    80005206:	8526                	mv	a0,s1
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	67c080e7          	jalr	1660(ra) # 80003884 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005210:	2981                	sext.w	s3,s3
    80005212:	4789                	li	a5,2
    80005214:	02f99463          	bne	s3,a5,8000523c <create+0x86>
    80005218:	0444d783          	lhu	a5,68(s1)
    8000521c:	37f9                	addiw	a5,a5,-2
    8000521e:	17c2                	slli	a5,a5,0x30
    80005220:	93c1                	srli	a5,a5,0x30
    80005222:	4705                	li	a4,1
    80005224:	00f76c63          	bltu	a4,a5,8000523c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005228:	8526                	mv	a0,s1
    8000522a:	60a6                	ld	ra,72(sp)
    8000522c:	6406                	ld	s0,64(sp)
    8000522e:	74e2                	ld	s1,56(sp)
    80005230:	7942                	ld	s2,48(sp)
    80005232:	79a2                	ld	s3,40(sp)
    80005234:	7a02                	ld	s4,32(sp)
    80005236:	6ae2                	ld	s5,24(sp)
    80005238:	6161                	addi	sp,sp,80
    8000523a:	8082                	ret
    iunlockput(ip);
    8000523c:	8526                	mv	a0,s1
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	8a8080e7          	jalr	-1880(ra) # 80003ae6 <iunlockput>
    return 0;
    80005246:	4481                	li	s1,0
    80005248:	b7c5                	j	80005228 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000524a:	85ce                	mv	a1,s3
    8000524c:	00092503          	lw	a0,0(s2)
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	49c080e7          	jalr	1180(ra) # 800036ec <ialloc>
    80005258:	84aa                	mv	s1,a0
    8000525a:	c529                	beqz	a0,800052a4 <create+0xee>
  ilock(ip);
    8000525c:	ffffe097          	auipc	ra,0xffffe
    80005260:	628080e7          	jalr	1576(ra) # 80003884 <ilock>
  ip->major = major;
    80005264:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005268:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000526c:	4785                	li	a5,1
    8000526e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005272:	8526                	mv	a0,s1
    80005274:	ffffe097          	auipc	ra,0xffffe
    80005278:	546080e7          	jalr	1350(ra) # 800037ba <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000527c:	2981                	sext.w	s3,s3
    8000527e:	4785                	li	a5,1
    80005280:	02f98a63          	beq	s3,a5,800052b4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005284:	40d0                	lw	a2,4(s1)
    80005286:	fb040593          	addi	a1,s0,-80
    8000528a:	854a                	mv	a0,s2
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	cec080e7          	jalr	-788(ra) # 80003f78 <dirlink>
    80005294:	06054b63          	bltz	a0,8000530a <create+0x154>
  iunlockput(dp);
    80005298:	854a                	mv	a0,s2
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	84c080e7          	jalr	-1972(ra) # 80003ae6 <iunlockput>
  return ip;
    800052a2:	b759                	j	80005228 <create+0x72>
    panic("create: ialloc");
    800052a4:	00003517          	auipc	a0,0x3
    800052a8:	49450513          	addi	a0,a0,1172 # 80008738 <syscalls+0x2b0>
    800052ac:	ffffb097          	auipc	ra,0xffffb
    800052b0:	292080e7          	jalr	658(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800052b4:	04a95783          	lhu	a5,74(s2)
    800052b8:	2785                	addiw	a5,a5,1
    800052ba:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052be:	854a                	mv	a0,s2
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	4fa080e7          	jalr	1274(ra) # 800037ba <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052c8:	40d0                	lw	a2,4(s1)
    800052ca:	00003597          	auipc	a1,0x3
    800052ce:	47e58593          	addi	a1,a1,1150 # 80008748 <syscalls+0x2c0>
    800052d2:	8526                	mv	a0,s1
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	ca4080e7          	jalr	-860(ra) # 80003f78 <dirlink>
    800052dc:	00054f63          	bltz	a0,800052fa <create+0x144>
    800052e0:	00492603          	lw	a2,4(s2)
    800052e4:	00003597          	auipc	a1,0x3
    800052e8:	46c58593          	addi	a1,a1,1132 # 80008750 <syscalls+0x2c8>
    800052ec:	8526                	mv	a0,s1
    800052ee:	fffff097          	auipc	ra,0xfffff
    800052f2:	c8a080e7          	jalr	-886(ra) # 80003f78 <dirlink>
    800052f6:	f80557e3          	bgez	a0,80005284 <create+0xce>
      panic("create dots");
    800052fa:	00003517          	auipc	a0,0x3
    800052fe:	45e50513          	addi	a0,a0,1118 # 80008758 <syscalls+0x2d0>
    80005302:	ffffb097          	auipc	ra,0xffffb
    80005306:	23c080e7          	jalr	572(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000530a:	00003517          	auipc	a0,0x3
    8000530e:	45e50513          	addi	a0,a0,1118 # 80008768 <syscalls+0x2e0>
    80005312:	ffffb097          	auipc	ra,0xffffb
    80005316:	22c080e7          	jalr	556(ra) # 8000053e <panic>
    return 0;
    8000531a:	84aa                	mv	s1,a0
    8000531c:	b731                	j	80005228 <create+0x72>

000000008000531e <sys_dup>:
{
    8000531e:	7179                	addi	sp,sp,-48
    80005320:	f406                	sd	ra,40(sp)
    80005322:	f022                	sd	s0,32(sp)
    80005324:	ec26                	sd	s1,24(sp)
    80005326:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005328:	fd840613          	addi	a2,s0,-40
    8000532c:	4581                	li	a1,0
    8000532e:	4501                	li	a0,0
    80005330:	00000097          	auipc	ra,0x0
    80005334:	ddc080e7          	jalr	-548(ra) # 8000510c <argfd>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000533a:	02054363          	bltz	a0,80005360 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000533e:	fd843503          	ld	a0,-40(s0)
    80005342:	00000097          	auipc	ra,0x0
    80005346:	e32080e7          	jalr	-462(ra) # 80005174 <fdalloc>
    8000534a:	84aa                	mv	s1,a0
    return -1;
    8000534c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000534e:	00054963          	bltz	a0,80005360 <sys_dup+0x42>
  filedup(f);
    80005352:	fd843503          	ld	a0,-40(s0)
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	37a080e7          	jalr	890(ra) # 800046d0 <filedup>
  return fd;
    8000535e:	87a6                	mv	a5,s1
}
    80005360:	853e                	mv	a0,a5
    80005362:	70a2                	ld	ra,40(sp)
    80005364:	7402                	ld	s0,32(sp)
    80005366:	64e2                	ld	s1,24(sp)
    80005368:	6145                	addi	sp,sp,48
    8000536a:	8082                	ret

000000008000536c <sys_read>:
{
    8000536c:	7179                	addi	sp,sp,-48
    8000536e:	f406                	sd	ra,40(sp)
    80005370:	f022                	sd	s0,32(sp)
    80005372:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005374:	fe840613          	addi	a2,s0,-24
    80005378:	4581                	li	a1,0
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	d90080e7          	jalr	-624(ra) # 8000510c <argfd>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005386:	04054163          	bltz	a0,800053c8 <sys_read+0x5c>
    8000538a:	fe440593          	addi	a1,s0,-28
    8000538e:	4509                	li	a0,2
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	938080e7          	jalr	-1736(ra) # 80002cc8 <argint>
    return -1;
    80005398:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539a:	02054763          	bltz	a0,800053c8 <sys_read+0x5c>
    8000539e:	fd840593          	addi	a1,s0,-40
    800053a2:	4505                	li	a0,1
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	946080e7          	jalr	-1722(ra) # 80002cea <argaddr>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ae:	00054d63          	bltz	a0,800053c8 <sys_read+0x5c>
  return fileread(f, p, n);
    800053b2:	fe442603          	lw	a2,-28(s0)
    800053b6:	fd843583          	ld	a1,-40(s0)
    800053ba:	fe843503          	ld	a0,-24(s0)
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	49e080e7          	jalr	1182(ra) # 8000485c <fileread>
    800053c6:	87aa                	mv	a5,a0
}
    800053c8:	853e                	mv	a0,a5
    800053ca:	70a2                	ld	ra,40(sp)
    800053cc:	7402                	ld	s0,32(sp)
    800053ce:	6145                	addi	sp,sp,48
    800053d0:	8082                	ret

00000000800053d2 <sys_write>:
{
    800053d2:	7179                	addi	sp,sp,-48
    800053d4:	f406                	sd	ra,40(sp)
    800053d6:	f022                	sd	s0,32(sp)
    800053d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053da:	fe840613          	addi	a2,s0,-24
    800053de:	4581                	li	a1,0
    800053e0:	4501                	li	a0,0
    800053e2:	00000097          	auipc	ra,0x0
    800053e6:	d2a080e7          	jalr	-726(ra) # 8000510c <argfd>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ec:	04054163          	bltz	a0,8000542e <sys_write+0x5c>
    800053f0:	fe440593          	addi	a1,s0,-28
    800053f4:	4509                	li	a0,2
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	8d2080e7          	jalr	-1838(ra) # 80002cc8 <argint>
    return -1;
    800053fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005400:	02054763          	bltz	a0,8000542e <sys_write+0x5c>
    80005404:	fd840593          	addi	a1,s0,-40
    80005408:	4505                	li	a0,1
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	8e0080e7          	jalr	-1824(ra) # 80002cea <argaddr>
    return -1;
    80005412:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005414:	00054d63          	bltz	a0,8000542e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005418:	fe442603          	lw	a2,-28(s0)
    8000541c:	fd843583          	ld	a1,-40(s0)
    80005420:	fe843503          	ld	a0,-24(s0)
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	4fa080e7          	jalr	1274(ra) # 8000491e <filewrite>
    8000542c:	87aa                	mv	a5,a0
}
    8000542e:	853e                	mv	a0,a5
    80005430:	70a2                	ld	ra,40(sp)
    80005432:	7402                	ld	s0,32(sp)
    80005434:	6145                	addi	sp,sp,48
    80005436:	8082                	ret

0000000080005438 <sys_close>:
{
    80005438:	1101                	addi	sp,sp,-32
    8000543a:	ec06                	sd	ra,24(sp)
    8000543c:	e822                	sd	s0,16(sp)
    8000543e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005440:	fe040613          	addi	a2,s0,-32
    80005444:	fec40593          	addi	a1,s0,-20
    80005448:	4501                	li	a0,0
    8000544a:	00000097          	auipc	ra,0x0
    8000544e:	cc2080e7          	jalr	-830(ra) # 8000510c <argfd>
    return -1;
    80005452:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005454:	02054463          	bltz	a0,8000547c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005458:	ffffc097          	auipc	ra,0xffffc
    8000545c:	67c080e7          	jalr	1660(ra) # 80001ad4 <myproc>
    80005460:	fec42783          	lw	a5,-20(s0)
    80005464:	07e9                	addi	a5,a5,26
    80005466:	078e                	slli	a5,a5,0x3
    80005468:	97aa                	add	a5,a5,a0
    8000546a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000546e:	fe043503          	ld	a0,-32(s0)
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	2b0080e7          	jalr	688(ra) # 80004722 <fileclose>
  return 0;
    8000547a:	4781                	li	a5,0
}
    8000547c:	853e                	mv	a0,a5
    8000547e:	60e2                	ld	ra,24(sp)
    80005480:	6442                	ld	s0,16(sp)
    80005482:	6105                	addi	sp,sp,32
    80005484:	8082                	ret

0000000080005486 <sys_fstat>:
{
    80005486:	1101                	addi	sp,sp,-32
    80005488:	ec06                	sd	ra,24(sp)
    8000548a:	e822                	sd	s0,16(sp)
    8000548c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000548e:	fe840613          	addi	a2,s0,-24
    80005492:	4581                	li	a1,0
    80005494:	4501                	li	a0,0
    80005496:	00000097          	auipc	ra,0x0
    8000549a:	c76080e7          	jalr	-906(ra) # 8000510c <argfd>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054a0:	02054563          	bltz	a0,800054ca <sys_fstat+0x44>
    800054a4:	fe040593          	addi	a1,s0,-32
    800054a8:	4505                	li	a0,1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	840080e7          	jalr	-1984(ra) # 80002cea <argaddr>
    return -1;
    800054b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054b4:	00054b63          	bltz	a0,800054ca <sys_fstat+0x44>
  return filestat(f, st);
    800054b8:	fe043583          	ld	a1,-32(s0)
    800054bc:	fe843503          	ld	a0,-24(s0)
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	32a080e7          	jalr	810(ra) # 800047ea <filestat>
    800054c8:	87aa                	mv	a5,a0
}
    800054ca:	853e                	mv	a0,a5
    800054cc:	60e2                	ld	ra,24(sp)
    800054ce:	6442                	ld	s0,16(sp)
    800054d0:	6105                	addi	sp,sp,32
    800054d2:	8082                	ret

00000000800054d4 <sys_link>:
{
    800054d4:	7169                	addi	sp,sp,-304
    800054d6:	f606                	sd	ra,296(sp)
    800054d8:	f222                	sd	s0,288(sp)
    800054da:	ee26                	sd	s1,280(sp)
    800054dc:	ea4a                	sd	s2,272(sp)
    800054de:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054e0:	08000613          	li	a2,128
    800054e4:	ed040593          	addi	a1,s0,-304
    800054e8:	4501                	li	a0,0
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	822080e7          	jalr	-2014(ra) # 80002d0c <argstr>
    return -1;
    800054f2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054f4:	10054e63          	bltz	a0,80005610 <sys_link+0x13c>
    800054f8:	08000613          	li	a2,128
    800054fc:	f5040593          	addi	a1,s0,-176
    80005500:	4505                	li	a0,1
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	80a080e7          	jalr	-2038(ra) # 80002d0c <argstr>
    return -1;
    8000550a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000550c:	10054263          	bltz	a0,80005610 <sys_link+0x13c>
  begin_op();
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	d46080e7          	jalr	-698(ra) # 80004256 <begin_op>
  if((ip = namei(old)) == 0){
    80005518:	ed040513          	addi	a0,s0,-304
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	b1e080e7          	jalr	-1250(ra) # 8000403a <namei>
    80005524:	84aa                	mv	s1,a0
    80005526:	c551                	beqz	a0,800055b2 <sys_link+0xde>
  ilock(ip);
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	35c080e7          	jalr	860(ra) # 80003884 <ilock>
  if(ip->type == T_DIR){
    80005530:	04449703          	lh	a4,68(s1)
    80005534:	4785                	li	a5,1
    80005536:	08f70463          	beq	a4,a5,800055be <sys_link+0xea>
  ip->nlink++;
    8000553a:	04a4d783          	lhu	a5,74(s1)
    8000553e:	2785                	addiw	a5,a5,1
    80005540:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	274080e7          	jalr	628(ra) # 800037ba <iupdate>
  iunlock(ip);
    8000554e:	8526                	mv	a0,s1
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	3f6080e7          	jalr	1014(ra) # 80003946 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005558:	fd040593          	addi	a1,s0,-48
    8000555c:	f5040513          	addi	a0,s0,-176
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	af8080e7          	jalr	-1288(ra) # 80004058 <nameiparent>
    80005568:	892a                	mv	s2,a0
    8000556a:	c935                	beqz	a0,800055de <sys_link+0x10a>
  ilock(dp);
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	318080e7          	jalr	792(ra) # 80003884 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005574:	00092703          	lw	a4,0(s2)
    80005578:	409c                	lw	a5,0(s1)
    8000557a:	04f71d63          	bne	a4,a5,800055d4 <sys_link+0x100>
    8000557e:	40d0                	lw	a2,4(s1)
    80005580:	fd040593          	addi	a1,s0,-48
    80005584:	854a                	mv	a0,s2
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	9f2080e7          	jalr	-1550(ra) # 80003f78 <dirlink>
    8000558e:	04054363          	bltz	a0,800055d4 <sys_link+0x100>
  iunlockput(dp);
    80005592:	854a                	mv	a0,s2
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	552080e7          	jalr	1362(ra) # 80003ae6 <iunlockput>
  iput(ip);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	4a0080e7          	jalr	1184(ra) # 80003a3e <iput>
  end_op();
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	d30080e7          	jalr	-720(ra) # 800042d6 <end_op>
  return 0;
    800055ae:	4781                	li	a5,0
    800055b0:	a085                	j	80005610 <sys_link+0x13c>
    end_op();
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	d24080e7          	jalr	-732(ra) # 800042d6 <end_op>
    return -1;
    800055ba:	57fd                	li	a5,-1
    800055bc:	a891                	j	80005610 <sys_link+0x13c>
    iunlockput(ip);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	526080e7          	jalr	1318(ra) # 80003ae6 <iunlockput>
    end_op();
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	d0e080e7          	jalr	-754(ra) # 800042d6 <end_op>
    return -1;
    800055d0:	57fd                	li	a5,-1
    800055d2:	a83d                	j	80005610 <sys_link+0x13c>
    iunlockput(dp);
    800055d4:	854a                	mv	a0,s2
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	510080e7          	jalr	1296(ra) # 80003ae6 <iunlockput>
  ilock(ip);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	2a4080e7          	jalr	676(ra) # 80003884 <ilock>
  ip->nlink--;
    800055e8:	04a4d783          	lhu	a5,74(s1)
    800055ec:	37fd                	addiw	a5,a5,-1
    800055ee:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	1c6080e7          	jalr	454(ra) # 800037ba <iupdate>
  iunlockput(ip);
    800055fc:	8526                	mv	a0,s1
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	4e8080e7          	jalr	1256(ra) # 80003ae6 <iunlockput>
  end_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	cd0080e7          	jalr	-816(ra) # 800042d6 <end_op>
  return -1;
    8000560e:	57fd                	li	a5,-1
}
    80005610:	853e                	mv	a0,a5
    80005612:	70b2                	ld	ra,296(sp)
    80005614:	7412                	ld	s0,288(sp)
    80005616:	64f2                	ld	s1,280(sp)
    80005618:	6952                	ld	s2,272(sp)
    8000561a:	6155                	addi	sp,sp,304
    8000561c:	8082                	ret

000000008000561e <sys_unlink>:
{
    8000561e:	7151                	addi	sp,sp,-240
    80005620:	f586                	sd	ra,232(sp)
    80005622:	f1a2                	sd	s0,224(sp)
    80005624:	eda6                	sd	s1,216(sp)
    80005626:	e9ca                	sd	s2,208(sp)
    80005628:	e5ce                	sd	s3,200(sp)
    8000562a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000562c:	08000613          	li	a2,128
    80005630:	f3040593          	addi	a1,s0,-208
    80005634:	4501                	li	a0,0
    80005636:	ffffd097          	auipc	ra,0xffffd
    8000563a:	6d6080e7          	jalr	1750(ra) # 80002d0c <argstr>
    8000563e:	18054163          	bltz	a0,800057c0 <sys_unlink+0x1a2>
  begin_op();
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	c14080e7          	jalr	-1004(ra) # 80004256 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000564a:	fb040593          	addi	a1,s0,-80
    8000564e:	f3040513          	addi	a0,s0,-208
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	a06080e7          	jalr	-1530(ra) # 80004058 <nameiparent>
    8000565a:	84aa                	mv	s1,a0
    8000565c:	c979                	beqz	a0,80005732 <sys_unlink+0x114>
  ilock(dp);
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	226080e7          	jalr	550(ra) # 80003884 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005666:	00003597          	auipc	a1,0x3
    8000566a:	0e258593          	addi	a1,a1,226 # 80008748 <syscalls+0x2c0>
    8000566e:	fb040513          	addi	a0,s0,-80
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	6dc080e7          	jalr	1756(ra) # 80003d4e <namecmp>
    8000567a:	14050a63          	beqz	a0,800057ce <sys_unlink+0x1b0>
    8000567e:	00003597          	auipc	a1,0x3
    80005682:	0d258593          	addi	a1,a1,210 # 80008750 <syscalls+0x2c8>
    80005686:	fb040513          	addi	a0,s0,-80
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	6c4080e7          	jalr	1732(ra) # 80003d4e <namecmp>
    80005692:	12050e63          	beqz	a0,800057ce <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005696:	f2c40613          	addi	a2,s0,-212
    8000569a:	fb040593          	addi	a1,s0,-80
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	6c8080e7          	jalr	1736(ra) # 80003d68 <dirlookup>
    800056a8:	892a                	mv	s2,a0
    800056aa:	12050263          	beqz	a0,800057ce <sys_unlink+0x1b0>
  ilock(ip);
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	1d6080e7          	jalr	470(ra) # 80003884 <ilock>
  if(ip->nlink < 1)
    800056b6:	04a91783          	lh	a5,74(s2)
    800056ba:	08f05263          	blez	a5,8000573e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056be:	04491703          	lh	a4,68(s2)
    800056c2:	4785                	li	a5,1
    800056c4:	08f70563          	beq	a4,a5,8000574e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056c8:	4641                	li	a2,16
    800056ca:	4581                	li	a1,0
    800056cc:	fc040513          	addi	a0,s0,-64
    800056d0:	ffffb097          	auipc	ra,0xffffb
    800056d4:	610080e7          	jalr	1552(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056d8:	4741                	li	a4,16
    800056da:	f2c42683          	lw	a3,-212(s0)
    800056de:	fc040613          	addi	a2,s0,-64
    800056e2:	4581                	li	a1,0
    800056e4:	8526                	mv	a0,s1
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	54a080e7          	jalr	1354(ra) # 80003c30 <writei>
    800056ee:	47c1                	li	a5,16
    800056f0:	0af51563          	bne	a0,a5,8000579a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056f4:	04491703          	lh	a4,68(s2)
    800056f8:	4785                	li	a5,1
    800056fa:	0af70863          	beq	a4,a5,800057aa <sys_unlink+0x18c>
  iunlockput(dp);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	3e6080e7          	jalr	998(ra) # 80003ae6 <iunlockput>
  ip->nlink--;
    80005708:	04a95783          	lhu	a5,74(s2)
    8000570c:	37fd                	addiw	a5,a5,-1
    8000570e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005712:	854a                	mv	a0,s2
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	0a6080e7          	jalr	166(ra) # 800037ba <iupdate>
  iunlockput(ip);
    8000571c:	854a                	mv	a0,s2
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	3c8080e7          	jalr	968(ra) # 80003ae6 <iunlockput>
  end_op();
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	bb0080e7          	jalr	-1104(ra) # 800042d6 <end_op>
  return 0;
    8000572e:	4501                	li	a0,0
    80005730:	a84d                	j	800057e2 <sys_unlink+0x1c4>
    end_op();
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	ba4080e7          	jalr	-1116(ra) # 800042d6 <end_op>
    return -1;
    8000573a:	557d                	li	a0,-1
    8000573c:	a05d                	j	800057e2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000573e:	00003517          	auipc	a0,0x3
    80005742:	03a50513          	addi	a0,a0,58 # 80008778 <syscalls+0x2f0>
    80005746:	ffffb097          	auipc	ra,0xffffb
    8000574a:	df8080e7          	jalr	-520(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000574e:	04c92703          	lw	a4,76(s2)
    80005752:	02000793          	li	a5,32
    80005756:	f6e7f9e3          	bgeu	a5,a4,800056c8 <sys_unlink+0xaa>
    8000575a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000575e:	4741                	li	a4,16
    80005760:	86ce                	mv	a3,s3
    80005762:	f1840613          	addi	a2,s0,-232
    80005766:	4581                	li	a1,0
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	3ce080e7          	jalr	974(ra) # 80003b38 <readi>
    80005772:	47c1                	li	a5,16
    80005774:	00f51b63          	bne	a0,a5,8000578a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005778:	f1845783          	lhu	a5,-232(s0)
    8000577c:	e7a1                	bnez	a5,800057c4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000577e:	29c1                	addiw	s3,s3,16
    80005780:	04c92783          	lw	a5,76(s2)
    80005784:	fcf9ede3          	bltu	s3,a5,8000575e <sys_unlink+0x140>
    80005788:	b781                	j	800056c8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000578a:	00003517          	auipc	a0,0x3
    8000578e:	00650513          	addi	a0,a0,6 # 80008790 <syscalls+0x308>
    80005792:	ffffb097          	auipc	ra,0xffffb
    80005796:	dac080e7          	jalr	-596(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000579a:	00003517          	auipc	a0,0x3
    8000579e:	00e50513          	addi	a0,a0,14 # 800087a8 <syscalls+0x320>
    800057a2:	ffffb097          	auipc	ra,0xffffb
    800057a6:	d9c080e7          	jalr	-612(ra) # 8000053e <panic>
    dp->nlink--;
    800057aa:	04a4d783          	lhu	a5,74(s1)
    800057ae:	37fd                	addiw	a5,a5,-1
    800057b0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057b4:	8526                	mv	a0,s1
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	004080e7          	jalr	4(ra) # 800037ba <iupdate>
    800057be:	b781                	j	800056fe <sys_unlink+0xe0>
    return -1;
    800057c0:	557d                	li	a0,-1
    800057c2:	a005                	j	800057e2 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057c4:	854a                	mv	a0,s2
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	320080e7          	jalr	800(ra) # 80003ae6 <iunlockput>
  iunlockput(dp);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	316080e7          	jalr	790(ra) # 80003ae6 <iunlockput>
  end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	afe080e7          	jalr	-1282(ra) # 800042d6 <end_op>
  return -1;
    800057e0:	557d                	li	a0,-1
}
    800057e2:	70ae                	ld	ra,232(sp)
    800057e4:	740e                	ld	s0,224(sp)
    800057e6:	64ee                	ld	s1,216(sp)
    800057e8:	694e                	ld	s2,208(sp)
    800057ea:	69ae                	ld	s3,200(sp)
    800057ec:	616d                	addi	sp,sp,240
    800057ee:	8082                	ret

00000000800057f0 <sys_open>:

uint64
sys_open(void)
{
    800057f0:	7131                	addi	sp,sp,-192
    800057f2:	fd06                	sd	ra,184(sp)
    800057f4:	f922                	sd	s0,176(sp)
    800057f6:	f526                	sd	s1,168(sp)
    800057f8:	f14a                	sd	s2,160(sp)
    800057fa:	ed4e                	sd	s3,152(sp)
    800057fc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057fe:	08000613          	li	a2,128
    80005802:	f5040593          	addi	a1,s0,-176
    80005806:	4501                	li	a0,0
    80005808:	ffffd097          	auipc	ra,0xffffd
    8000580c:	504080e7          	jalr	1284(ra) # 80002d0c <argstr>
    return -1;
    80005810:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005812:	0c054163          	bltz	a0,800058d4 <sys_open+0xe4>
    80005816:	f4c40593          	addi	a1,s0,-180
    8000581a:	4505                	li	a0,1
    8000581c:	ffffd097          	auipc	ra,0xffffd
    80005820:	4ac080e7          	jalr	1196(ra) # 80002cc8 <argint>
    80005824:	0a054863          	bltz	a0,800058d4 <sys_open+0xe4>

  begin_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	a2e080e7          	jalr	-1490(ra) # 80004256 <begin_op>

  if(omode & O_CREATE){
    80005830:	f4c42783          	lw	a5,-180(s0)
    80005834:	2007f793          	andi	a5,a5,512
    80005838:	cbdd                	beqz	a5,800058ee <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000583a:	4681                	li	a3,0
    8000583c:	4601                	li	a2,0
    8000583e:	4589                	li	a1,2
    80005840:	f5040513          	addi	a0,s0,-176
    80005844:	00000097          	auipc	ra,0x0
    80005848:	972080e7          	jalr	-1678(ra) # 800051b6 <create>
    8000584c:	892a                	mv	s2,a0
    if(ip == 0){
    8000584e:	c959                	beqz	a0,800058e4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005850:	04491703          	lh	a4,68(s2)
    80005854:	478d                	li	a5,3
    80005856:	00f71763          	bne	a4,a5,80005864 <sys_open+0x74>
    8000585a:	04695703          	lhu	a4,70(s2)
    8000585e:	47a5                	li	a5,9
    80005860:	0ce7ec63          	bltu	a5,a4,80005938 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	e02080e7          	jalr	-510(ra) # 80004666 <filealloc>
    8000586c:	89aa                	mv	s3,a0
    8000586e:	10050263          	beqz	a0,80005972 <sys_open+0x182>
    80005872:	00000097          	auipc	ra,0x0
    80005876:	902080e7          	jalr	-1790(ra) # 80005174 <fdalloc>
    8000587a:	84aa                	mv	s1,a0
    8000587c:	0e054663          	bltz	a0,80005968 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005880:	04491703          	lh	a4,68(s2)
    80005884:	478d                	li	a5,3
    80005886:	0cf70463          	beq	a4,a5,8000594e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000588a:	4789                	li	a5,2
    8000588c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005890:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005894:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005898:	f4c42783          	lw	a5,-180(s0)
    8000589c:	0017c713          	xori	a4,a5,1
    800058a0:	8b05                	andi	a4,a4,1
    800058a2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058a6:	0037f713          	andi	a4,a5,3
    800058aa:	00e03733          	snez	a4,a4
    800058ae:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058b2:	4007f793          	andi	a5,a5,1024
    800058b6:	c791                	beqz	a5,800058c2 <sys_open+0xd2>
    800058b8:	04491703          	lh	a4,68(s2)
    800058bc:	4789                	li	a5,2
    800058be:	08f70f63          	beq	a4,a5,8000595c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058c2:	854a                	mv	a0,s2
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	082080e7          	jalr	130(ra) # 80003946 <iunlock>
  end_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	a0a080e7          	jalr	-1526(ra) # 800042d6 <end_op>

  return fd;
}
    800058d4:	8526                	mv	a0,s1
    800058d6:	70ea                	ld	ra,184(sp)
    800058d8:	744a                	ld	s0,176(sp)
    800058da:	74aa                	ld	s1,168(sp)
    800058dc:	790a                	ld	s2,160(sp)
    800058de:	69ea                	ld	s3,152(sp)
    800058e0:	6129                	addi	sp,sp,192
    800058e2:	8082                	ret
      end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	9f2080e7          	jalr	-1550(ra) # 800042d6 <end_op>
      return -1;
    800058ec:	b7e5                	j	800058d4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058ee:	f5040513          	addi	a0,s0,-176
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	748080e7          	jalr	1864(ra) # 8000403a <namei>
    800058fa:	892a                	mv	s2,a0
    800058fc:	c905                	beqz	a0,8000592c <sys_open+0x13c>
    ilock(ip);
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	f86080e7          	jalr	-122(ra) # 80003884 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005906:	04491703          	lh	a4,68(s2)
    8000590a:	4785                	li	a5,1
    8000590c:	f4f712e3          	bne	a4,a5,80005850 <sys_open+0x60>
    80005910:	f4c42783          	lw	a5,-180(s0)
    80005914:	dba1                	beqz	a5,80005864 <sys_open+0x74>
      iunlockput(ip);
    80005916:	854a                	mv	a0,s2
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	1ce080e7          	jalr	462(ra) # 80003ae6 <iunlockput>
      end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	9b6080e7          	jalr	-1610(ra) # 800042d6 <end_op>
      return -1;
    80005928:	54fd                	li	s1,-1
    8000592a:	b76d                	j	800058d4 <sys_open+0xe4>
      end_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	9aa080e7          	jalr	-1622(ra) # 800042d6 <end_op>
      return -1;
    80005934:	54fd                	li	s1,-1
    80005936:	bf79                	j	800058d4 <sys_open+0xe4>
    iunlockput(ip);
    80005938:	854a                	mv	a0,s2
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	1ac080e7          	jalr	428(ra) # 80003ae6 <iunlockput>
    end_op();
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	994080e7          	jalr	-1644(ra) # 800042d6 <end_op>
    return -1;
    8000594a:	54fd                	li	s1,-1
    8000594c:	b761                	j	800058d4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000594e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005952:	04691783          	lh	a5,70(s2)
    80005956:	02f99223          	sh	a5,36(s3)
    8000595a:	bf2d                	j	80005894 <sys_open+0xa4>
    itrunc(ip);
    8000595c:	854a                	mv	a0,s2
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	034080e7          	jalr	52(ra) # 80003992 <itrunc>
    80005966:	bfb1                	j	800058c2 <sys_open+0xd2>
      fileclose(f);
    80005968:	854e                	mv	a0,s3
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	db8080e7          	jalr	-584(ra) # 80004722 <fileclose>
    iunlockput(ip);
    80005972:	854a                	mv	a0,s2
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	172080e7          	jalr	370(ra) # 80003ae6 <iunlockput>
    end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	95a080e7          	jalr	-1702(ra) # 800042d6 <end_op>
    return -1;
    80005984:	54fd                	li	s1,-1
    80005986:	b7b9                	j	800058d4 <sys_open+0xe4>

0000000080005988 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005988:	7175                	addi	sp,sp,-144
    8000598a:	e506                	sd	ra,136(sp)
    8000598c:	e122                	sd	s0,128(sp)
    8000598e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	8c6080e7          	jalr	-1850(ra) # 80004256 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005998:	08000613          	li	a2,128
    8000599c:	f7040593          	addi	a1,s0,-144
    800059a0:	4501                	li	a0,0
    800059a2:	ffffd097          	auipc	ra,0xffffd
    800059a6:	36a080e7          	jalr	874(ra) # 80002d0c <argstr>
    800059aa:	02054963          	bltz	a0,800059dc <sys_mkdir+0x54>
    800059ae:	4681                	li	a3,0
    800059b0:	4601                	li	a2,0
    800059b2:	4585                	li	a1,1
    800059b4:	f7040513          	addi	a0,s0,-144
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	7fe080e7          	jalr	2046(ra) # 800051b6 <create>
    800059c0:	cd11                	beqz	a0,800059dc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	124080e7          	jalr	292(ra) # 80003ae6 <iunlockput>
  end_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	90c080e7          	jalr	-1780(ra) # 800042d6 <end_op>
  return 0;
    800059d2:	4501                	li	a0,0
}
    800059d4:	60aa                	ld	ra,136(sp)
    800059d6:	640a                	ld	s0,128(sp)
    800059d8:	6149                	addi	sp,sp,144
    800059da:	8082                	ret
    end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	8fa080e7          	jalr	-1798(ra) # 800042d6 <end_op>
    return -1;
    800059e4:	557d                	li	a0,-1
    800059e6:	b7fd                	j	800059d4 <sys_mkdir+0x4c>

00000000800059e8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059e8:	7135                	addi	sp,sp,-160
    800059ea:	ed06                	sd	ra,152(sp)
    800059ec:	e922                	sd	s0,144(sp)
    800059ee:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	866080e7          	jalr	-1946(ra) # 80004256 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059f8:	08000613          	li	a2,128
    800059fc:	f7040593          	addi	a1,s0,-144
    80005a00:	4501                	li	a0,0
    80005a02:	ffffd097          	auipc	ra,0xffffd
    80005a06:	30a080e7          	jalr	778(ra) # 80002d0c <argstr>
    80005a0a:	04054a63          	bltz	a0,80005a5e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a0e:	f6c40593          	addi	a1,s0,-148
    80005a12:	4505                	li	a0,1
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	2b4080e7          	jalr	692(ra) # 80002cc8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a1c:	04054163          	bltz	a0,80005a5e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a20:	f6840593          	addi	a1,s0,-152
    80005a24:	4509                	li	a0,2
    80005a26:	ffffd097          	auipc	ra,0xffffd
    80005a2a:	2a2080e7          	jalr	674(ra) # 80002cc8 <argint>
     argint(1, &major) < 0 ||
    80005a2e:	02054863          	bltz	a0,80005a5e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a32:	f6841683          	lh	a3,-152(s0)
    80005a36:	f6c41603          	lh	a2,-148(s0)
    80005a3a:	458d                	li	a1,3
    80005a3c:	f7040513          	addi	a0,s0,-144
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	776080e7          	jalr	1910(ra) # 800051b6 <create>
     argint(2, &minor) < 0 ||
    80005a48:	c919                	beqz	a0,80005a5e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	09c080e7          	jalr	156(ra) # 80003ae6 <iunlockput>
  end_op();
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	884080e7          	jalr	-1916(ra) # 800042d6 <end_op>
  return 0;
    80005a5a:	4501                	li	a0,0
    80005a5c:	a031                	j	80005a68 <sys_mknod+0x80>
    end_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	878080e7          	jalr	-1928(ra) # 800042d6 <end_op>
    return -1;
    80005a66:	557d                	li	a0,-1
}
    80005a68:	60ea                	ld	ra,152(sp)
    80005a6a:	644a                	ld	s0,144(sp)
    80005a6c:	610d                	addi	sp,sp,160
    80005a6e:	8082                	ret

0000000080005a70 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a70:	7135                	addi	sp,sp,-160
    80005a72:	ed06                	sd	ra,152(sp)
    80005a74:	e922                	sd	s0,144(sp)
    80005a76:	e526                	sd	s1,136(sp)
    80005a78:	e14a                	sd	s2,128(sp)
    80005a7a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a7c:	ffffc097          	auipc	ra,0xffffc
    80005a80:	058080e7          	jalr	88(ra) # 80001ad4 <myproc>
    80005a84:	892a                	mv	s2,a0
  
  begin_op();
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	7d0080e7          	jalr	2000(ra) # 80004256 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a8e:	08000613          	li	a2,128
    80005a92:	f6040593          	addi	a1,s0,-160
    80005a96:	4501                	li	a0,0
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	274080e7          	jalr	628(ra) # 80002d0c <argstr>
    80005aa0:	04054b63          	bltz	a0,80005af6 <sys_chdir+0x86>
    80005aa4:	f6040513          	addi	a0,s0,-160
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	592080e7          	jalr	1426(ra) # 8000403a <namei>
    80005ab0:	84aa                	mv	s1,a0
    80005ab2:	c131                	beqz	a0,80005af6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	dd0080e7          	jalr	-560(ra) # 80003884 <ilock>
  if(ip->type != T_DIR){
    80005abc:	04449703          	lh	a4,68(s1)
    80005ac0:	4785                	li	a5,1
    80005ac2:	04f71063          	bne	a4,a5,80005b02 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	e7e080e7          	jalr	-386(ra) # 80003946 <iunlock>
  iput(p->cwd);
    80005ad0:	15093503          	ld	a0,336(s2)
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	f6a080e7          	jalr	-150(ra) # 80003a3e <iput>
  end_op();
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	7fa080e7          	jalr	2042(ra) # 800042d6 <end_op>
  p->cwd = ip;
    80005ae4:	14993823          	sd	s1,336(s2)
  return 0;
    80005ae8:	4501                	li	a0,0
}
    80005aea:	60ea                	ld	ra,152(sp)
    80005aec:	644a                	ld	s0,144(sp)
    80005aee:	64aa                	ld	s1,136(sp)
    80005af0:	690a                	ld	s2,128(sp)
    80005af2:	610d                	addi	sp,sp,160
    80005af4:	8082                	ret
    end_op();
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	7e0080e7          	jalr	2016(ra) # 800042d6 <end_op>
    return -1;
    80005afe:	557d                	li	a0,-1
    80005b00:	b7ed                	j	80005aea <sys_chdir+0x7a>
    iunlockput(ip);
    80005b02:	8526                	mv	a0,s1
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	fe2080e7          	jalr	-30(ra) # 80003ae6 <iunlockput>
    end_op();
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	7ca080e7          	jalr	1994(ra) # 800042d6 <end_op>
    return -1;
    80005b14:	557d                	li	a0,-1
    80005b16:	bfd1                	j	80005aea <sys_chdir+0x7a>

0000000080005b18 <sys_exec>:

uint64
sys_exec(void)
{
    80005b18:	7145                	addi	sp,sp,-464
    80005b1a:	e786                	sd	ra,456(sp)
    80005b1c:	e3a2                	sd	s0,448(sp)
    80005b1e:	ff26                	sd	s1,440(sp)
    80005b20:	fb4a                	sd	s2,432(sp)
    80005b22:	f74e                	sd	s3,424(sp)
    80005b24:	f352                	sd	s4,416(sp)
    80005b26:	ef56                	sd	s5,408(sp)
    80005b28:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b2a:	08000613          	li	a2,128
    80005b2e:	f4040593          	addi	a1,s0,-192
    80005b32:	4501                	li	a0,0
    80005b34:	ffffd097          	auipc	ra,0xffffd
    80005b38:	1d8080e7          	jalr	472(ra) # 80002d0c <argstr>
    return -1;
    80005b3c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b3e:	0c054a63          	bltz	a0,80005c12 <sys_exec+0xfa>
    80005b42:	e3840593          	addi	a1,s0,-456
    80005b46:	4505                	li	a0,1
    80005b48:	ffffd097          	auipc	ra,0xffffd
    80005b4c:	1a2080e7          	jalr	418(ra) # 80002cea <argaddr>
    80005b50:	0c054163          	bltz	a0,80005c12 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b54:	10000613          	li	a2,256
    80005b58:	4581                	li	a1,0
    80005b5a:	e4040513          	addi	a0,s0,-448
    80005b5e:	ffffb097          	auipc	ra,0xffffb
    80005b62:	182080e7          	jalr	386(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b66:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b6a:	89a6                	mv	s3,s1
    80005b6c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b6e:	02000a13          	li	s4,32
    80005b72:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b76:	00391513          	slli	a0,s2,0x3
    80005b7a:	e3040593          	addi	a1,s0,-464
    80005b7e:	e3843783          	ld	a5,-456(s0)
    80005b82:	953e                	add	a0,a0,a5
    80005b84:	ffffd097          	auipc	ra,0xffffd
    80005b88:	0aa080e7          	jalr	170(ra) # 80002c2e <fetchaddr>
    80005b8c:	02054a63          	bltz	a0,80005bc0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b90:	e3043783          	ld	a5,-464(s0)
    80005b94:	c3b9                	beqz	a5,80005bda <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b96:	ffffb097          	auipc	ra,0xffffb
    80005b9a:	f5e080e7          	jalr	-162(ra) # 80000af4 <kalloc>
    80005b9e:	85aa                	mv	a1,a0
    80005ba0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ba4:	cd11                	beqz	a0,80005bc0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ba6:	6605                	lui	a2,0x1
    80005ba8:	e3043503          	ld	a0,-464(s0)
    80005bac:	ffffd097          	auipc	ra,0xffffd
    80005bb0:	0d4080e7          	jalr	212(ra) # 80002c80 <fetchstr>
    80005bb4:	00054663          	bltz	a0,80005bc0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bb8:	0905                	addi	s2,s2,1
    80005bba:	09a1                	addi	s3,s3,8
    80005bbc:	fb491be3          	bne	s2,s4,80005b72 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc0:	10048913          	addi	s2,s1,256
    80005bc4:	6088                	ld	a0,0(s1)
    80005bc6:	c529                	beqz	a0,80005c10 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bc8:	ffffb097          	auipc	ra,0xffffb
    80005bcc:	e30080e7          	jalr	-464(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd0:	04a1                	addi	s1,s1,8
    80005bd2:	ff2499e3          	bne	s1,s2,80005bc4 <sys_exec+0xac>
  return -1;
    80005bd6:	597d                	li	s2,-1
    80005bd8:	a82d                	j	80005c12 <sys_exec+0xfa>
      argv[i] = 0;
    80005bda:	0a8e                	slli	s5,s5,0x3
    80005bdc:	fc040793          	addi	a5,s0,-64
    80005be0:	9abe                	add	s5,s5,a5
    80005be2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005be6:	e4040593          	addi	a1,s0,-448
    80005bea:	f4040513          	addi	a0,s0,-192
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	194080e7          	jalr	404(ra) # 80004d82 <exec>
    80005bf6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf8:	10048993          	addi	s3,s1,256
    80005bfc:	6088                	ld	a0,0(s1)
    80005bfe:	c911                	beqz	a0,80005c12 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c00:	ffffb097          	auipc	ra,0xffffb
    80005c04:	df8080e7          	jalr	-520(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c08:	04a1                	addi	s1,s1,8
    80005c0a:	ff3499e3          	bne	s1,s3,80005bfc <sys_exec+0xe4>
    80005c0e:	a011                	j	80005c12 <sys_exec+0xfa>
  return -1;
    80005c10:	597d                	li	s2,-1
}
    80005c12:	854a                	mv	a0,s2
    80005c14:	60be                	ld	ra,456(sp)
    80005c16:	641e                	ld	s0,448(sp)
    80005c18:	74fa                	ld	s1,440(sp)
    80005c1a:	795a                	ld	s2,432(sp)
    80005c1c:	79ba                	ld	s3,424(sp)
    80005c1e:	7a1a                	ld	s4,416(sp)
    80005c20:	6afa                	ld	s5,408(sp)
    80005c22:	6179                	addi	sp,sp,464
    80005c24:	8082                	ret

0000000080005c26 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c26:	7139                	addi	sp,sp,-64
    80005c28:	fc06                	sd	ra,56(sp)
    80005c2a:	f822                	sd	s0,48(sp)
    80005c2c:	f426                	sd	s1,40(sp)
    80005c2e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c30:	ffffc097          	auipc	ra,0xffffc
    80005c34:	ea4080e7          	jalr	-348(ra) # 80001ad4 <myproc>
    80005c38:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c3a:	fd840593          	addi	a1,s0,-40
    80005c3e:	4501                	li	a0,0
    80005c40:	ffffd097          	auipc	ra,0xffffd
    80005c44:	0aa080e7          	jalr	170(ra) # 80002cea <argaddr>
    return -1;
    80005c48:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c4a:	0e054063          	bltz	a0,80005d2a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c4e:	fc840593          	addi	a1,s0,-56
    80005c52:	fd040513          	addi	a0,s0,-48
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	dfc080e7          	jalr	-516(ra) # 80004a52 <pipealloc>
    return -1;
    80005c5e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c60:	0c054563          	bltz	a0,80005d2a <sys_pipe+0x104>
  fd0 = -1;
    80005c64:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c68:	fd043503          	ld	a0,-48(s0)
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	508080e7          	jalr	1288(ra) # 80005174 <fdalloc>
    80005c74:	fca42223          	sw	a0,-60(s0)
    80005c78:	08054c63          	bltz	a0,80005d10 <sys_pipe+0xea>
    80005c7c:	fc843503          	ld	a0,-56(s0)
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	4f4080e7          	jalr	1268(ra) # 80005174 <fdalloc>
    80005c88:	fca42023          	sw	a0,-64(s0)
    80005c8c:	06054863          	bltz	a0,80005cfc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c90:	4691                	li	a3,4
    80005c92:	fc440613          	addi	a2,s0,-60
    80005c96:	fd843583          	ld	a1,-40(s0)
    80005c9a:	68a8                	ld	a0,80(s1)
    80005c9c:	ffffc097          	auipc	ra,0xffffc
    80005ca0:	afa080e7          	jalr	-1286(ra) # 80001796 <copyout>
    80005ca4:	02054063          	bltz	a0,80005cc4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ca8:	4691                	li	a3,4
    80005caa:	fc040613          	addi	a2,s0,-64
    80005cae:	fd843583          	ld	a1,-40(s0)
    80005cb2:	0591                	addi	a1,a1,4
    80005cb4:	68a8                	ld	a0,80(s1)
    80005cb6:	ffffc097          	auipc	ra,0xffffc
    80005cba:	ae0080e7          	jalr	-1312(ra) # 80001796 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cbe:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cc0:	06055563          	bgez	a0,80005d2a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cc4:	fc442783          	lw	a5,-60(s0)
    80005cc8:	07e9                	addi	a5,a5,26
    80005cca:	078e                	slli	a5,a5,0x3
    80005ccc:	97a6                	add	a5,a5,s1
    80005cce:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cd2:	fc042503          	lw	a0,-64(s0)
    80005cd6:	0569                	addi	a0,a0,26
    80005cd8:	050e                	slli	a0,a0,0x3
    80005cda:	9526                	add	a0,a0,s1
    80005cdc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ce0:	fd043503          	ld	a0,-48(s0)
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	a3e080e7          	jalr	-1474(ra) # 80004722 <fileclose>
    fileclose(wf);
    80005cec:	fc843503          	ld	a0,-56(s0)
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	a32080e7          	jalr	-1486(ra) # 80004722 <fileclose>
    return -1;
    80005cf8:	57fd                	li	a5,-1
    80005cfa:	a805                	j	80005d2a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cfc:	fc442783          	lw	a5,-60(s0)
    80005d00:	0007c863          	bltz	a5,80005d10 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d04:	01a78513          	addi	a0,a5,26
    80005d08:	050e                	slli	a0,a0,0x3
    80005d0a:	9526                	add	a0,a0,s1
    80005d0c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d10:	fd043503          	ld	a0,-48(s0)
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	a0e080e7          	jalr	-1522(ra) # 80004722 <fileclose>
    fileclose(wf);
    80005d1c:	fc843503          	ld	a0,-56(s0)
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	a02080e7          	jalr	-1534(ra) # 80004722 <fileclose>
    return -1;
    80005d28:	57fd                	li	a5,-1
}
    80005d2a:	853e                	mv	a0,a5
    80005d2c:	70e2                	ld	ra,56(sp)
    80005d2e:	7442                	ld	s0,48(sp)
    80005d30:	74a2                	ld	s1,40(sp)
    80005d32:	6121                	addi	sp,sp,64
    80005d34:	8082                	ret
	...

0000000080005d40 <kernelvec>:
    80005d40:	7111                	addi	sp,sp,-256
    80005d42:	e006                	sd	ra,0(sp)
    80005d44:	e40a                	sd	sp,8(sp)
    80005d46:	e80e                	sd	gp,16(sp)
    80005d48:	ec12                	sd	tp,24(sp)
    80005d4a:	f016                	sd	t0,32(sp)
    80005d4c:	f41a                	sd	t1,40(sp)
    80005d4e:	f81e                	sd	t2,48(sp)
    80005d50:	fc22                	sd	s0,56(sp)
    80005d52:	e0a6                	sd	s1,64(sp)
    80005d54:	e4aa                	sd	a0,72(sp)
    80005d56:	e8ae                	sd	a1,80(sp)
    80005d58:	ecb2                	sd	a2,88(sp)
    80005d5a:	f0b6                	sd	a3,96(sp)
    80005d5c:	f4ba                	sd	a4,104(sp)
    80005d5e:	f8be                	sd	a5,112(sp)
    80005d60:	fcc2                	sd	a6,120(sp)
    80005d62:	e146                	sd	a7,128(sp)
    80005d64:	e54a                	sd	s2,136(sp)
    80005d66:	e94e                	sd	s3,144(sp)
    80005d68:	ed52                	sd	s4,152(sp)
    80005d6a:	f156                	sd	s5,160(sp)
    80005d6c:	f55a                	sd	s6,168(sp)
    80005d6e:	f95e                	sd	s7,176(sp)
    80005d70:	fd62                	sd	s8,184(sp)
    80005d72:	e1e6                	sd	s9,192(sp)
    80005d74:	e5ea                	sd	s10,200(sp)
    80005d76:	e9ee                	sd	s11,208(sp)
    80005d78:	edf2                	sd	t3,216(sp)
    80005d7a:	f1f6                	sd	t4,224(sp)
    80005d7c:	f5fa                	sd	t5,232(sp)
    80005d7e:	f9fe                	sd	t6,240(sp)
    80005d80:	d7bfc0ef          	jal	ra,80002afa <kerneltrap>
    80005d84:	6082                	ld	ra,0(sp)
    80005d86:	6122                	ld	sp,8(sp)
    80005d88:	61c2                	ld	gp,16(sp)
    80005d8a:	7282                	ld	t0,32(sp)
    80005d8c:	7322                	ld	t1,40(sp)
    80005d8e:	73c2                	ld	t2,48(sp)
    80005d90:	7462                	ld	s0,56(sp)
    80005d92:	6486                	ld	s1,64(sp)
    80005d94:	6526                	ld	a0,72(sp)
    80005d96:	65c6                	ld	a1,80(sp)
    80005d98:	6666                	ld	a2,88(sp)
    80005d9a:	7686                	ld	a3,96(sp)
    80005d9c:	7726                	ld	a4,104(sp)
    80005d9e:	77c6                	ld	a5,112(sp)
    80005da0:	7866                	ld	a6,120(sp)
    80005da2:	688a                	ld	a7,128(sp)
    80005da4:	692a                	ld	s2,136(sp)
    80005da6:	69ca                	ld	s3,144(sp)
    80005da8:	6a6a                	ld	s4,152(sp)
    80005daa:	7a8a                	ld	s5,160(sp)
    80005dac:	7b2a                	ld	s6,168(sp)
    80005dae:	7bca                	ld	s7,176(sp)
    80005db0:	7c6a                	ld	s8,184(sp)
    80005db2:	6c8e                	ld	s9,192(sp)
    80005db4:	6d2e                	ld	s10,200(sp)
    80005db6:	6dce                	ld	s11,208(sp)
    80005db8:	6e6e                	ld	t3,216(sp)
    80005dba:	7e8e                	ld	t4,224(sp)
    80005dbc:	7f2e                	ld	t5,232(sp)
    80005dbe:	7fce                	ld	t6,240(sp)
    80005dc0:	6111                	addi	sp,sp,256
    80005dc2:	10200073          	sret
    80005dc6:	00000013          	nop
    80005dca:	00000013          	nop
    80005dce:	0001                	nop

0000000080005dd0 <timervec>:
    80005dd0:	34051573          	csrrw	a0,mscratch,a0
    80005dd4:	e10c                	sd	a1,0(a0)
    80005dd6:	e510                	sd	a2,8(a0)
    80005dd8:	e914                	sd	a3,16(a0)
    80005dda:	6d0c                	ld	a1,24(a0)
    80005ddc:	7110                	ld	a2,32(a0)
    80005dde:	6194                	ld	a3,0(a1)
    80005de0:	96b2                	add	a3,a3,a2
    80005de2:	e194                	sd	a3,0(a1)
    80005de4:	4589                	li	a1,2
    80005de6:	14459073          	csrw	sip,a1
    80005dea:	6914                	ld	a3,16(a0)
    80005dec:	6510                	ld	a2,8(a0)
    80005dee:	610c                	ld	a1,0(a0)
    80005df0:	34051573          	csrrw	a0,mscratch,a0
    80005df4:	30200073          	mret
	...

0000000080005dfa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dfa:	1141                	addi	sp,sp,-16
    80005dfc:	e422                	sd	s0,8(sp)
    80005dfe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e00:	0c0007b7          	lui	a5,0xc000
    80005e04:	4705                	li	a4,1
    80005e06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e08:	c3d8                	sw	a4,4(a5)
}
    80005e0a:	6422                	ld	s0,8(sp)
    80005e0c:	0141                	addi	sp,sp,16
    80005e0e:	8082                	ret

0000000080005e10 <plicinithart>:

void
plicinithart(void)
{
    80005e10:	1141                	addi	sp,sp,-16
    80005e12:	e406                	sd	ra,8(sp)
    80005e14:	e022                	sd	s0,0(sp)
    80005e16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	c90080e7          	jalr	-880(ra) # 80001aa8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e20:	0085171b          	slliw	a4,a0,0x8
    80005e24:	0c0027b7          	lui	a5,0xc002
    80005e28:	97ba                	add	a5,a5,a4
    80005e2a:	40200713          	li	a4,1026
    80005e2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e32:	00d5151b          	slliw	a0,a0,0xd
    80005e36:	0c2017b7          	lui	a5,0xc201
    80005e3a:	953e                	add	a0,a0,a5
    80005e3c:	00052023          	sw	zero,0(a0)
}
    80005e40:	60a2                	ld	ra,8(sp)
    80005e42:	6402                	ld	s0,0(sp)
    80005e44:	0141                	addi	sp,sp,16
    80005e46:	8082                	ret

0000000080005e48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e48:	1141                	addi	sp,sp,-16
    80005e4a:	e406                	sd	ra,8(sp)
    80005e4c:	e022                	sd	s0,0(sp)
    80005e4e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e50:	ffffc097          	auipc	ra,0xffffc
    80005e54:	c58080e7          	jalr	-936(ra) # 80001aa8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e58:	00d5179b          	slliw	a5,a0,0xd
    80005e5c:	0c201537          	lui	a0,0xc201
    80005e60:	953e                	add	a0,a0,a5
  return irq;
}
    80005e62:	4148                	lw	a0,4(a0)
    80005e64:	60a2                	ld	ra,8(sp)
    80005e66:	6402                	ld	s0,0(sp)
    80005e68:	0141                	addi	sp,sp,16
    80005e6a:	8082                	ret

0000000080005e6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e6c:	1101                	addi	sp,sp,-32
    80005e6e:	ec06                	sd	ra,24(sp)
    80005e70:	e822                	sd	s0,16(sp)
    80005e72:	e426                	sd	s1,8(sp)
    80005e74:	1000                	addi	s0,sp,32
    80005e76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e78:	ffffc097          	auipc	ra,0xffffc
    80005e7c:	c30080e7          	jalr	-976(ra) # 80001aa8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e80:	00d5151b          	slliw	a0,a0,0xd
    80005e84:	0c2017b7          	lui	a5,0xc201
    80005e88:	97aa                	add	a5,a5,a0
    80005e8a:	c3c4                	sw	s1,4(a5)
}
    80005e8c:	60e2                	ld	ra,24(sp)
    80005e8e:	6442                	ld	s0,16(sp)
    80005e90:	64a2                	ld	s1,8(sp)
    80005e92:	6105                	addi	sp,sp,32
    80005e94:	8082                	ret

0000000080005e96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e96:	1141                	addi	sp,sp,-16
    80005e98:	e406                	sd	ra,8(sp)
    80005e9a:	e022                	sd	s0,0(sp)
    80005e9c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e9e:	479d                	li	a5,7
    80005ea0:	06a7c963          	blt	a5,a0,80005f12 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ea4:	0001d797          	auipc	a5,0x1d
    80005ea8:	15c78793          	addi	a5,a5,348 # 80023000 <disk>
    80005eac:	00a78733          	add	a4,a5,a0
    80005eb0:	6789                	lui	a5,0x2
    80005eb2:	97ba                	add	a5,a5,a4
    80005eb4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005eb8:	e7ad                	bnez	a5,80005f22 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005eba:	00451793          	slli	a5,a0,0x4
    80005ebe:	0001f717          	auipc	a4,0x1f
    80005ec2:	14270713          	addi	a4,a4,322 # 80025000 <disk+0x2000>
    80005ec6:	6314                	ld	a3,0(a4)
    80005ec8:	96be                	add	a3,a3,a5
    80005eca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ece:	6314                	ld	a3,0(a4)
    80005ed0:	96be                	add	a3,a3,a5
    80005ed2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ed6:	6314                	ld	a3,0(a4)
    80005ed8:	96be                	add	a3,a3,a5
    80005eda:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005ede:	6318                	ld	a4,0(a4)
    80005ee0:	97ba                	add	a5,a5,a4
    80005ee2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ee6:	0001d797          	auipc	a5,0x1d
    80005eea:	11a78793          	addi	a5,a5,282 # 80023000 <disk>
    80005eee:	97aa                	add	a5,a5,a0
    80005ef0:	6509                	lui	a0,0x2
    80005ef2:	953e                	add	a0,a0,a5
    80005ef4:	4785                	li	a5,1
    80005ef6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005efa:	0001f517          	auipc	a0,0x1f
    80005efe:	11e50513          	addi	a0,a0,286 # 80025018 <disk+0x2018>
    80005f02:	ffffc097          	auipc	ra,0xffffc
    80005f06:	518080e7          	jalr	1304(ra) # 8000241a <wakeup>
}
    80005f0a:	60a2                	ld	ra,8(sp)
    80005f0c:	6402                	ld	s0,0(sp)
    80005f0e:	0141                	addi	sp,sp,16
    80005f10:	8082                	ret
    panic("free_desc 1");
    80005f12:	00003517          	auipc	a0,0x3
    80005f16:	8a650513          	addi	a0,a0,-1882 # 800087b8 <syscalls+0x330>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	624080e7          	jalr	1572(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f22:	00003517          	auipc	a0,0x3
    80005f26:	8a650513          	addi	a0,a0,-1882 # 800087c8 <syscalls+0x340>
    80005f2a:	ffffa097          	auipc	ra,0xffffa
    80005f2e:	614080e7          	jalr	1556(ra) # 8000053e <panic>

0000000080005f32 <virtio_disk_init>:
{
    80005f32:	1101                	addi	sp,sp,-32
    80005f34:	ec06                	sd	ra,24(sp)
    80005f36:	e822                	sd	s0,16(sp)
    80005f38:	e426                	sd	s1,8(sp)
    80005f3a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f3c:	00003597          	auipc	a1,0x3
    80005f40:	89c58593          	addi	a1,a1,-1892 # 800087d8 <syscalls+0x350>
    80005f44:	0001f517          	auipc	a0,0x1f
    80005f48:	1e450513          	addi	a0,a0,484 # 80025128 <disk+0x2128>
    80005f4c:	ffffb097          	auipc	ra,0xffffb
    80005f50:	c08080e7          	jalr	-1016(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f54:	100017b7          	lui	a5,0x10001
    80005f58:	4398                	lw	a4,0(a5)
    80005f5a:	2701                	sext.w	a4,a4
    80005f5c:	747277b7          	lui	a5,0x74727
    80005f60:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f64:	0ef71163          	bne	a4,a5,80006046 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f68:	100017b7          	lui	a5,0x10001
    80005f6c:	43dc                	lw	a5,4(a5)
    80005f6e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f70:	4705                	li	a4,1
    80005f72:	0ce79a63          	bne	a5,a4,80006046 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f76:	100017b7          	lui	a5,0x10001
    80005f7a:	479c                	lw	a5,8(a5)
    80005f7c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f7e:	4709                	li	a4,2
    80005f80:	0ce79363          	bne	a5,a4,80006046 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f84:	100017b7          	lui	a5,0x10001
    80005f88:	47d8                	lw	a4,12(a5)
    80005f8a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f8c:	554d47b7          	lui	a5,0x554d4
    80005f90:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f94:	0af71963          	bne	a4,a5,80006046 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f98:	100017b7          	lui	a5,0x10001
    80005f9c:	4705                	li	a4,1
    80005f9e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa0:	470d                	li	a4,3
    80005fa2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fa4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fa6:	c7ffe737          	lui	a4,0xc7ffe
    80005faa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005fae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fb0:	2701                	sext.w	a4,a4
    80005fb2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb4:	472d                	li	a4,11
    80005fb6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb8:	473d                	li	a4,15
    80005fba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fbc:	6705                	lui	a4,0x1
    80005fbe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fc0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fc4:	5bdc                	lw	a5,52(a5)
    80005fc6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fc8:	c7d9                	beqz	a5,80006056 <virtio_disk_init+0x124>
  if(max < NUM)
    80005fca:	471d                	li	a4,7
    80005fcc:	08f77d63          	bgeu	a4,a5,80006066 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fd0:	100014b7          	lui	s1,0x10001
    80005fd4:	47a1                	li	a5,8
    80005fd6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fd8:	6609                	lui	a2,0x2
    80005fda:	4581                	li	a1,0
    80005fdc:	0001d517          	auipc	a0,0x1d
    80005fe0:	02450513          	addi	a0,a0,36 # 80023000 <disk>
    80005fe4:	ffffb097          	auipc	ra,0xffffb
    80005fe8:	cfc080e7          	jalr	-772(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fec:	0001d717          	auipc	a4,0x1d
    80005ff0:	01470713          	addi	a4,a4,20 # 80023000 <disk>
    80005ff4:	00c75793          	srli	a5,a4,0xc
    80005ff8:	2781                	sext.w	a5,a5
    80005ffa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005ffc:	0001f797          	auipc	a5,0x1f
    80006000:	00478793          	addi	a5,a5,4 # 80025000 <disk+0x2000>
    80006004:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006006:	0001d717          	auipc	a4,0x1d
    8000600a:	07a70713          	addi	a4,a4,122 # 80023080 <disk+0x80>
    8000600e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006010:	0001e717          	auipc	a4,0x1e
    80006014:	ff070713          	addi	a4,a4,-16 # 80024000 <disk+0x1000>
    80006018:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000601a:	4705                	li	a4,1
    8000601c:	00e78c23          	sb	a4,24(a5)
    80006020:	00e78ca3          	sb	a4,25(a5)
    80006024:	00e78d23          	sb	a4,26(a5)
    80006028:	00e78da3          	sb	a4,27(a5)
    8000602c:	00e78e23          	sb	a4,28(a5)
    80006030:	00e78ea3          	sb	a4,29(a5)
    80006034:	00e78f23          	sb	a4,30(a5)
    80006038:	00e78fa3          	sb	a4,31(a5)
}
    8000603c:	60e2                	ld	ra,24(sp)
    8000603e:	6442                	ld	s0,16(sp)
    80006040:	64a2                	ld	s1,8(sp)
    80006042:	6105                	addi	sp,sp,32
    80006044:	8082                	ret
    panic("could not find virtio disk");
    80006046:	00002517          	auipc	a0,0x2
    8000604a:	7a250513          	addi	a0,a0,1954 # 800087e8 <syscalls+0x360>
    8000604e:	ffffa097          	auipc	ra,0xffffa
    80006052:	4f0080e7          	jalr	1264(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006056:	00002517          	auipc	a0,0x2
    8000605a:	7b250513          	addi	a0,a0,1970 # 80008808 <syscalls+0x380>
    8000605e:	ffffa097          	auipc	ra,0xffffa
    80006062:	4e0080e7          	jalr	1248(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006066:	00002517          	auipc	a0,0x2
    8000606a:	7c250513          	addi	a0,a0,1986 # 80008828 <syscalls+0x3a0>
    8000606e:	ffffa097          	auipc	ra,0xffffa
    80006072:	4d0080e7          	jalr	1232(ra) # 8000053e <panic>

0000000080006076 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006076:	7159                	addi	sp,sp,-112
    80006078:	f486                	sd	ra,104(sp)
    8000607a:	f0a2                	sd	s0,96(sp)
    8000607c:	eca6                	sd	s1,88(sp)
    8000607e:	e8ca                	sd	s2,80(sp)
    80006080:	e4ce                	sd	s3,72(sp)
    80006082:	e0d2                	sd	s4,64(sp)
    80006084:	fc56                	sd	s5,56(sp)
    80006086:	f85a                	sd	s6,48(sp)
    80006088:	f45e                	sd	s7,40(sp)
    8000608a:	f062                	sd	s8,32(sp)
    8000608c:	ec66                	sd	s9,24(sp)
    8000608e:	e86a                	sd	s10,16(sp)
    80006090:	1880                	addi	s0,sp,112
    80006092:	892a                	mv	s2,a0
    80006094:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006096:	00c52c83          	lw	s9,12(a0)
    8000609a:	001c9c9b          	slliw	s9,s9,0x1
    8000609e:	1c82                	slli	s9,s9,0x20
    800060a0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060a4:	0001f517          	auipc	a0,0x1f
    800060a8:	08450513          	addi	a0,a0,132 # 80025128 <disk+0x2128>
    800060ac:	ffffb097          	auipc	ra,0xffffb
    800060b0:	b38080e7          	jalr	-1224(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800060b4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060b6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060b8:	0001db97          	auipc	s7,0x1d
    800060bc:	f48b8b93          	addi	s7,s7,-184 # 80023000 <disk>
    800060c0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060c4:	8a4e                	mv	s4,s3
    800060c6:	a051                	j	8000614a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060c8:	00fb86b3          	add	a3,s7,a5
    800060cc:	96da                	add	a3,a3,s6
    800060ce:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060d2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060d4:	0207c563          	bltz	a5,800060fe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060d8:	2485                	addiw	s1,s1,1
    800060da:	0711                	addi	a4,a4,4
    800060dc:	25548063          	beq	s1,s5,8000631c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060e0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060e2:	0001f697          	auipc	a3,0x1f
    800060e6:	f3668693          	addi	a3,a3,-202 # 80025018 <disk+0x2018>
    800060ea:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060ec:	0006c583          	lbu	a1,0(a3)
    800060f0:	fde1                	bnez	a1,800060c8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060f2:	2785                	addiw	a5,a5,1
    800060f4:	0685                	addi	a3,a3,1
    800060f6:	ff879be3          	bne	a5,s8,800060ec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060fa:	57fd                	li	a5,-1
    800060fc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060fe:	02905a63          	blez	s1,80006132 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006102:	f9042503          	lw	a0,-112(s0)
    80006106:	00000097          	auipc	ra,0x0
    8000610a:	d90080e7          	jalr	-624(ra) # 80005e96 <free_desc>
      for(int j = 0; j < i; j++)
    8000610e:	4785                	li	a5,1
    80006110:	0297d163          	bge	a5,s1,80006132 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006114:	f9442503          	lw	a0,-108(s0)
    80006118:	00000097          	auipc	ra,0x0
    8000611c:	d7e080e7          	jalr	-642(ra) # 80005e96 <free_desc>
      for(int j = 0; j < i; j++)
    80006120:	4789                	li	a5,2
    80006122:	0097d863          	bge	a5,s1,80006132 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006126:	f9842503          	lw	a0,-104(s0)
    8000612a:	00000097          	auipc	ra,0x0
    8000612e:	d6c080e7          	jalr	-660(ra) # 80005e96 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006132:	0001f597          	auipc	a1,0x1f
    80006136:	ff658593          	addi	a1,a1,-10 # 80025128 <disk+0x2128>
    8000613a:	0001f517          	auipc	a0,0x1f
    8000613e:	ede50513          	addi	a0,a0,-290 # 80025018 <disk+0x2018>
    80006142:	ffffc097          	auipc	ra,0xffffc
    80006146:	04e080e7          	jalr	78(ra) # 80002190 <sleep>
  for(int i = 0; i < 3; i++){
    8000614a:	f9040713          	addi	a4,s0,-112
    8000614e:	84ce                	mv	s1,s3
    80006150:	bf41                	j	800060e0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006152:	20058713          	addi	a4,a1,512
    80006156:	00471693          	slli	a3,a4,0x4
    8000615a:	0001d717          	auipc	a4,0x1d
    8000615e:	ea670713          	addi	a4,a4,-346 # 80023000 <disk>
    80006162:	9736                	add	a4,a4,a3
    80006164:	4685                	li	a3,1
    80006166:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000616a:	20058713          	addi	a4,a1,512
    8000616e:	00471693          	slli	a3,a4,0x4
    80006172:	0001d717          	auipc	a4,0x1d
    80006176:	e8e70713          	addi	a4,a4,-370 # 80023000 <disk>
    8000617a:	9736                	add	a4,a4,a3
    8000617c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006180:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006184:	7679                	lui	a2,0xffffe
    80006186:	963e                	add	a2,a2,a5
    80006188:	0001f697          	auipc	a3,0x1f
    8000618c:	e7868693          	addi	a3,a3,-392 # 80025000 <disk+0x2000>
    80006190:	6298                	ld	a4,0(a3)
    80006192:	9732                	add	a4,a4,a2
    80006194:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006196:	6298                	ld	a4,0(a3)
    80006198:	9732                	add	a4,a4,a2
    8000619a:	4541                	li	a0,16
    8000619c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000619e:	6298                	ld	a4,0(a3)
    800061a0:	9732                	add	a4,a4,a2
    800061a2:	4505                	li	a0,1
    800061a4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061a8:	f9442703          	lw	a4,-108(s0)
    800061ac:	6288                	ld	a0,0(a3)
    800061ae:	962a                	add	a2,a2,a0
    800061b0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061b4:	0712                	slli	a4,a4,0x4
    800061b6:	6290                	ld	a2,0(a3)
    800061b8:	963a                	add	a2,a2,a4
    800061ba:	05890513          	addi	a0,s2,88
    800061be:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061c0:	6294                	ld	a3,0(a3)
    800061c2:	96ba                	add	a3,a3,a4
    800061c4:	40000613          	li	a2,1024
    800061c8:	c690                	sw	a2,8(a3)
  if(write)
    800061ca:	140d0063          	beqz	s10,8000630a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061ce:	0001f697          	auipc	a3,0x1f
    800061d2:	e326b683          	ld	a3,-462(a3) # 80025000 <disk+0x2000>
    800061d6:	96ba                	add	a3,a3,a4
    800061d8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061dc:	0001d817          	auipc	a6,0x1d
    800061e0:	e2480813          	addi	a6,a6,-476 # 80023000 <disk>
    800061e4:	0001f517          	auipc	a0,0x1f
    800061e8:	e1c50513          	addi	a0,a0,-484 # 80025000 <disk+0x2000>
    800061ec:	6114                	ld	a3,0(a0)
    800061ee:	96ba                	add	a3,a3,a4
    800061f0:	00c6d603          	lhu	a2,12(a3)
    800061f4:	00166613          	ori	a2,a2,1
    800061f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061fc:	f9842683          	lw	a3,-104(s0)
    80006200:	6110                	ld	a2,0(a0)
    80006202:	9732                	add	a4,a4,a2
    80006204:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006208:	20058613          	addi	a2,a1,512
    8000620c:	0612                	slli	a2,a2,0x4
    8000620e:	9642                	add	a2,a2,a6
    80006210:	577d                	li	a4,-1
    80006212:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006216:	00469713          	slli	a4,a3,0x4
    8000621a:	6114                	ld	a3,0(a0)
    8000621c:	96ba                	add	a3,a3,a4
    8000621e:	03078793          	addi	a5,a5,48
    80006222:	97c2                	add	a5,a5,a6
    80006224:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006226:	611c                	ld	a5,0(a0)
    80006228:	97ba                	add	a5,a5,a4
    8000622a:	4685                	li	a3,1
    8000622c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000622e:	611c                	ld	a5,0(a0)
    80006230:	97ba                	add	a5,a5,a4
    80006232:	4809                	li	a6,2
    80006234:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006238:	611c                	ld	a5,0(a0)
    8000623a:	973e                	add	a4,a4,a5
    8000623c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006240:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006244:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006248:	6518                	ld	a4,8(a0)
    8000624a:	00275783          	lhu	a5,2(a4)
    8000624e:	8b9d                	andi	a5,a5,7
    80006250:	0786                	slli	a5,a5,0x1
    80006252:	97ba                	add	a5,a5,a4
    80006254:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006258:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000625c:	6518                	ld	a4,8(a0)
    8000625e:	00275783          	lhu	a5,2(a4)
    80006262:	2785                	addiw	a5,a5,1
    80006264:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006268:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000626c:	100017b7          	lui	a5,0x10001
    80006270:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006274:	00492703          	lw	a4,4(s2)
    80006278:	4785                	li	a5,1
    8000627a:	02f71163          	bne	a4,a5,8000629c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000627e:	0001f997          	auipc	s3,0x1f
    80006282:	eaa98993          	addi	s3,s3,-342 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006286:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006288:	85ce                	mv	a1,s3
    8000628a:	854a                	mv	a0,s2
    8000628c:	ffffc097          	auipc	ra,0xffffc
    80006290:	f04080e7          	jalr	-252(ra) # 80002190 <sleep>
  while(b->disk == 1) {
    80006294:	00492783          	lw	a5,4(s2)
    80006298:	fe9788e3          	beq	a5,s1,80006288 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000629c:	f9042903          	lw	s2,-112(s0)
    800062a0:	20090793          	addi	a5,s2,512
    800062a4:	00479713          	slli	a4,a5,0x4
    800062a8:	0001d797          	auipc	a5,0x1d
    800062ac:	d5878793          	addi	a5,a5,-680 # 80023000 <disk>
    800062b0:	97ba                	add	a5,a5,a4
    800062b2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062b6:	0001f997          	auipc	s3,0x1f
    800062ba:	d4a98993          	addi	s3,s3,-694 # 80025000 <disk+0x2000>
    800062be:	00491713          	slli	a4,s2,0x4
    800062c2:	0009b783          	ld	a5,0(s3)
    800062c6:	97ba                	add	a5,a5,a4
    800062c8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062cc:	854a                	mv	a0,s2
    800062ce:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062d2:	00000097          	auipc	ra,0x0
    800062d6:	bc4080e7          	jalr	-1084(ra) # 80005e96 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062da:	8885                	andi	s1,s1,1
    800062dc:	f0ed                	bnez	s1,800062be <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062de:	0001f517          	auipc	a0,0x1f
    800062e2:	e4a50513          	addi	a0,a0,-438 # 80025128 <disk+0x2128>
    800062e6:	ffffb097          	auipc	ra,0xffffb
    800062ea:	9b2080e7          	jalr	-1614(ra) # 80000c98 <release>
}
    800062ee:	70a6                	ld	ra,104(sp)
    800062f0:	7406                	ld	s0,96(sp)
    800062f2:	64e6                	ld	s1,88(sp)
    800062f4:	6946                	ld	s2,80(sp)
    800062f6:	69a6                	ld	s3,72(sp)
    800062f8:	6a06                	ld	s4,64(sp)
    800062fa:	7ae2                	ld	s5,56(sp)
    800062fc:	7b42                	ld	s6,48(sp)
    800062fe:	7ba2                	ld	s7,40(sp)
    80006300:	7c02                	ld	s8,32(sp)
    80006302:	6ce2                	ld	s9,24(sp)
    80006304:	6d42                	ld	s10,16(sp)
    80006306:	6165                	addi	sp,sp,112
    80006308:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000630a:	0001f697          	auipc	a3,0x1f
    8000630e:	cf66b683          	ld	a3,-778(a3) # 80025000 <disk+0x2000>
    80006312:	96ba                	add	a3,a3,a4
    80006314:	4609                	li	a2,2
    80006316:	00c69623          	sh	a2,12(a3)
    8000631a:	b5c9                	j	800061dc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000631c:	f9042583          	lw	a1,-112(s0)
    80006320:	20058793          	addi	a5,a1,512
    80006324:	0792                	slli	a5,a5,0x4
    80006326:	0001d517          	auipc	a0,0x1d
    8000632a:	d8250513          	addi	a0,a0,-638 # 800230a8 <disk+0xa8>
    8000632e:	953e                	add	a0,a0,a5
  if(write)
    80006330:	e20d11e3          	bnez	s10,80006152 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006334:	20058713          	addi	a4,a1,512
    80006338:	00471693          	slli	a3,a4,0x4
    8000633c:	0001d717          	auipc	a4,0x1d
    80006340:	cc470713          	addi	a4,a4,-828 # 80023000 <disk>
    80006344:	9736                	add	a4,a4,a3
    80006346:	0a072423          	sw	zero,168(a4)
    8000634a:	b505                	j	8000616a <virtio_disk_rw+0xf4>

000000008000634c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000634c:	1101                	addi	sp,sp,-32
    8000634e:	ec06                	sd	ra,24(sp)
    80006350:	e822                	sd	s0,16(sp)
    80006352:	e426                	sd	s1,8(sp)
    80006354:	e04a                	sd	s2,0(sp)
    80006356:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006358:	0001f517          	auipc	a0,0x1f
    8000635c:	dd050513          	addi	a0,a0,-560 # 80025128 <disk+0x2128>
    80006360:	ffffb097          	auipc	ra,0xffffb
    80006364:	884080e7          	jalr	-1916(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006368:	10001737          	lui	a4,0x10001
    8000636c:	533c                	lw	a5,96(a4)
    8000636e:	8b8d                	andi	a5,a5,3
    80006370:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006372:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006376:	0001f797          	auipc	a5,0x1f
    8000637a:	c8a78793          	addi	a5,a5,-886 # 80025000 <disk+0x2000>
    8000637e:	6b94                	ld	a3,16(a5)
    80006380:	0207d703          	lhu	a4,32(a5)
    80006384:	0026d783          	lhu	a5,2(a3)
    80006388:	06f70163          	beq	a4,a5,800063ea <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000638c:	0001d917          	auipc	s2,0x1d
    80006390:	c7490913          	addi	s2,s2,-908 # 80023000 <disk>
    80006394:	0001f497          	auipc	s1,0x1f
    80006398:	c6c48493          	addi	s1,s1,-916 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000639c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063a0:	6898                	ld	a4,16(s1)
    800063a2:	0204d783          	lhu	a5,32(s1)
    800063a6:	8b9d                	andi	a5,a5,7
    800063a8:	078e                	slli	a5,a5,0x3
    800063aa:	97ba                	add	a5,a5,a4
    800063ac:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063ae:	20078713          	addi	a4,a5,512
    800063b2:	0712                	slli	a4,a4,0x4
    800063b4:	974a                	add	a4,a4,s2
    800063b6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063ba:	e731                	bnez	a4,80006406 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063bc:	20078793          	addi	a5,a5,512
    800063c0:	0792                	slli	a5,a5,0x4
    800063c2:	97ca                	add	a5,a5,s2
    800063c4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063c6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063ca:	ffffc097          	auipc	ra,0xffffc
    800063ce:	050080e7          	jalr	80(ra) # 8000241a <wakeup>

    disk.used_idx += 1;
    800063d2:	0204d783          	lhu	a5,32(s1)
    800063d6:	2785                	addiw	a5,a5,1
    800063d8:	17c2                	slli	a5,a5,0x30
    800063da:	93c1                	srli	a5,a5,0x30
    800063dc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063e0:	6898                	ld	a4,16(s1)
    800063e2:	00275703          	lhu	a4,2(a4)
    800063e6:	faf71be3          	bne	a4,a5,8000639c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063ea:	0001f517          	auipc	a0,0x1f
    800063ee:	d3e50513          	addi	a0,a0,-706 # 80025128 <disk+0x2128>
    800063f2:	ffffb097          	auipc	ra,0xffffb
    800063f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
}
    800063fa:	60e2                	ld	ra,24(sp)
    800063fc:	6442                	ld	s0,16(sp)
    800063fe:	64a2                	ld	s1,8(sp)
    80006400:	6902                	ld	s2,0(sp)
    80006402:	6105                	addi	sp,sp,32
    80006404:	8082                	ret
      panic("virtio_disk_intr status");
    80006406:	00002517          	auipc	a0,0x2
    8000640a:	44250513          	addi	a0,a0,1090 # 80008848 <syscalls+0x3c0>
    8000640e:	ffffa097          	auipc	ra,0xffffa
    80006412:	130080e7          	jalr	304(ra) # 8000053e <panic>
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
