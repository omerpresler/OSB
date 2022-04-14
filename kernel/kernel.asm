
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
    80000130:	5a8080e7          	jalr	1448(ra) # 800026d4 <either_copyin>
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
    800001c8:	91c080e7          	jalr	-1764(ra) # 80001ae0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	fc8080e7          	jalr	-56(ra) # 8000219c <sleep>
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
    80000214:	46e080e7          	jalr	1134(ra) # 8000267e <either_copyout>
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
    800002f6:	438080e7          	jalr	1080(ra) # 8000272a <procdump>
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
    8000044a:	fca080e7          	jalr	-54(ra) # 80002410 <wakeup>
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
    800008a4:	b70080e7          	jalr	-1168(ra) # 80002410 <wakeup>
    
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
    80000930:	870080e7          	jalr	-1936(ra) # 8000219c <sleep>
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
    80000b82:	f46080e7          	jalr	-186(ra) # 80001ac4 <mycpu>
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
    80000bb4:	f14080e7          	jalr	-236(ra) # 80001ac4 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	f08080e7          	jalr	-248(ra) # 80001ac4 <mycpu>
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
    80000bd8:	ef0080e7          	jalr	-272(ra) # 80001ac4 <mycpu>
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
    80000c18:	eb0080e7          	jalr	-336(ra) # 80001ac4 <mycpu>
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
    80000c44:	e84080e7          	jalr	-380(ra) # 80001ac4 <mycpu>
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
    80000eac:	006080e7          	jalr	6(ra) # 80001eae <fork>
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	ffe080e7          	jalr	-2(ra) # 80001eae <fork>
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
    80000efa:	30a080e7          	jalr	778(ra) # 80002200 <pause_system>
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
    80000f3e:	f74080e7          	jalr	-140(ra) # 80001eae <fork>
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	f6c080e7          	jalr	-148(ra) # 80001eae <fork>
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
    80000f8a:	6a2080e7          	jalr	1698(ra) # 80002628 <kill_system>
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
  //example_pause_system(1, 2, 5);
  example_kill_system(5, 5);
    80000fba:	4595                	li	a1,5
    80000fbc:	4515                	li	a0,5
    80000fbe:	00000097          	auipc	ra,0x0
    80000fc2:	f66080e7          	jalr	-154(ra) # 80000f24 <example_kill_system>

  if(cpuid() == 0){
    80000fc6:	00001097          	auipc	ra,0x1
    80000fca:	aee080e7          	jalr	-1298(ra) # 80001ab4 <cpuid>
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
    
  } else {
    while(started == 0)
    80000fce:	00008717          	auipc	a4,0x8
    80000fd2:	04a70713          	addi	a4,a4,74 # 80009018 <started>
  if(cpuid() == 0){
    80000fd6:	c139                	beqz	a0,8000101c <main+0x6a>
    while(started == 0)
    80000fd8:	431c                	lw	a5,0(a4)
    80000fda:	2781                	sext.w	a5,a5
    80000fdc:	dff5                	beqz	a5,80000fd8 <main+0x26>
      ;
    __sync_synchronize();
    80000fde:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fe2:	00001097          	auipc	ra,0x1
    80000fe6:	ad2080e7          	jalr	-1326(ra) # 80001ab4 <cpuid>
    80000fea:	85aa                	mv	a1,a0
    80000fec:	00007517          	auipc	a0,0x7
    80000ff0:	10c50513          	addi	a0,a0,268 # 800080f8 <digits+0xb8>
    80000ff4:	fffff097          	auipc	ra,0xfffff
    80000ff8:	594080e7          	jalr	1428(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ffc:	00000097          	auipc	ra,0x0
    80001000:	0d8080e7          	jalr	216(ra) # 800010d4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001004:	00002097          	auipc	ra,0x2
    80001008:	866080e7          	jalr	-1946(ra) # 8000286a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000100c:	00005097          	auipc	ra,0x5
    80001010:	e04080e7          	jalr	-508(ra) # 80005e10 <plicinithart>
  }

  scheduler();    
    80001014:	00001097          	auipc	ra,0x1
    80001018:	fd6080e7          	jalr	-42(ra) # 80001fea <scheduler>
    consoleinit();
    8000101c:	fffff097          	auipc	ra,0xfffff
    80001020:	434080e7          	jalr	1076(ra) # 80000450 <consoleinit>
    printfinit();
    80001024:	fffff097          	auipc	ra,0xfffff
    80001028:	74a080e7          	jalr	1866(ra) # 8000076e <printfinit>
    printf("\n");
    8000102c:	00007517          	auipc	a0,0x7
    80001030:	0dc50513          	addi	a0,a0,220 # 80008108 <digits+0xc8>
    80001034:	fffff097          	auipc	ra,0xfffff
    80001038:	554080e7          	jalr	1364(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    8000103c:	00007517          	auipc	a0,0x7
    80001040:	0a450513          	addi	a0,a0,164 # 800080e0 <digits+0xa0>
    80001044:	fffff097          	auipc	ra,0xfffff
    80001048:	544080e7          	jalr	1348(ra) # 80000588 <printf>
    printf("\n");
    8000104c:	00007517          	auipc	a0,0x7
    80001050:	0bc50513          	addi	a0,a0,188 # 80008108 <digits+0xc8>
    80001054:	fffff097          	auipc	ra,0xfffff
    80001058:	534080e7          	jalr	1332(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    8000105c:	00000097          	auipc	ra,0x0
    80001060:	a5c080e7          	jalr	-1444(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80001064:	00000097          	auipc	ra,0x0
    80001068:	322080e7          	jalr	802(ra) # 80001386 <kvminit>
    kvminithart();   // turn on paging
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	068080e7          	jalr	104(ra) # 800010d4 <kvminithart>
    procinit();      // process table
    80001074:	00001097          	auipc	ra,0x1
    80001078:	990080e7          	jalr	-1648(ra) # 80001a04 <procinit>
    trapinit();      // trap vectors
    8000107c:	00001097          	auipc	ra,0x1
    80001080:	7c6080e7          	jalr	1990(ra) # 80002842 <trapinit>
    trapinithart();  // install kernel trap vector
    80001084:	00001097          	auipc	ra,0x1
    80001088:	7e6080e7          	jalr	2022(ra) # 8000286a <trapinithart>
    plicinit();      // set up interrupt controller
    8000108c:	00005097          	auipc	ra,0x5
    80001090:	d6e080e7          	jalr	-658(ra) # 80005dfa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001094:	00005097          	auipc	ra,0x5
    80001098:	d7c080e7          	jalr	-644(ra) # 80005e10 <plicinithart>
    binit();         // buffer cache
    8000109c:	00002097          	auipc	ra,0x2
    800010a0:	f5a080e7          	jalr	-166(ra) # 80002ff6 <binit>
    iinit();         // inode table
    800010a4:	00002097          	auipc	ra,0x2
    800010a8:	5ea080e7          	jalr	1514(ra) # 8000368e <iinit>
    fileinit();      // file table
    800010ac:	00003097          	auipc	ra,0x3
    800010b0:	594080e7          	jalr	1428(ra) # 80004640 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010b4:	00005097          	auipc	ra,0x5
    800010b8:	e7e080e7          	jalr	-386(ra) # 80005f32 <virtio_disk_init>
    userinit();      // first user process
    800010bc:	00001097          	auipc	ra,0x1
    800010c0:	cfc080e7          	jalr	-772(ra) # 80001db8 <userinit>
    __sync_synchronize();
    800010c4:	0ff0000f          	fence
    started = 1;
    800010c8:	4785                	li	a5,1
    800010ca:	00008717          	auipc	a4,0x8
    800010ce:	f4f72723          	sw	a5,-178(a4) # 80009018 <started>
    800010d2:	b789                	j	80001014 <main+0x62>

00000000800010d4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010d4:	1141                	addi	sp,sp,-16
    800010d6:	e422                	sd	s0,8(sp)
    800010d8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010da:	00008797          	auipc	a5,0x8
    800010de:	f467b783          	ld	a5,-186(a5) # 80009020 <kernel_pagetable>
    800010e2:	83b1                	srli	a5,a5,0xc
    800010e4:	577d                	li	a4,-1
    800010e6:	177e                	slli	a4,a4,0x3f
    800010e8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010ea:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010ee:	12000073          	sfence.vma
  sfence_vma();
}
    800010f2:	6422                	ld	s0,8(sp)
    800010f4:	0141                	addi	sp,sp,16
    800010f6:	8082                	ret

00000000800010f8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010f8:	7139                	addi	sp,sp,-64
    800010fa:	fc06                	sd	ra,56(sp)
    800010fc:	f822                	sd	s0,48(sp)
    800010fe:	f426                	sd	s1,40(sp)
    80001100:	f04a                	sd	s2,32(sp)
    80001102:	ec4e                	sd	s3,24(sp)
    80001104:	e852                	sd	s4,16(sp)
    80001106:	e456                	sd	s5,8(sp)
    80001108:	e05a                	sd	s6,0(sp)
    8000110a:	0080                	addi	s0,sp,64
    8000110c:	84aa                	mv	s1,a0
    8000110e:	89ae                	mv	s3,a1
    80001110:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001112:	57fd                	li	a5,-1
    80001114:	83e9                	srli	a5,a5,0x1a
    80001116:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001118:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000111a:	04b7f263          	bgeu	a5,a1,8000115e <walk+0x66>
    panic("walk");
    8000111e:	00007517          	auipc	a0,0x7
    80001122:	ff250513          	addi	a0,a0,-14 # 80008110 <digits+0xd0>
    80001126:	fffff097          	auipc	ra,0xfffff
    8000112a:	418080e7          	jalr	1048(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000112e:	060a8663          	beqz	s5,8000119a <walk+0xa2>
    80001132:	00000097          	auipc	ra,0x0
    80001136:	9c2080e7          	jalr	-1598(ra) # 80000af4 <kalloc>
    8000113a:	84aa                	mv	s1,a0
    8000113c:	c529                	beqz	a0,80001186 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000113e:	6605                	lui	a2,0x1
    80001140:	4581                	li	a1,0
    80001142:	00000097          	auipc	ra,0x0
    80001146:	b9e080e7          	jalr	-1122(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000114a:	00c4d793          	srli	a5,s1,0xc
    8000114e:	07aa                	slli	a5,a5,0xa
    80001150:	0017e793          	ori	a5,a5,1
    80001154:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001158:	3a5d                	addiw	s4,s4,-9
    8000115a:	036a0063          	beq	s4,s6,8000117a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000115e:	0149d933          	srl	s2,s3,s4
    80001162:	1ff97913          	andi	s2,s2,511
    80001166:	090e                	slli	s2,s2,0x3
    80001168:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000116a:	00093483          	ld	s1,0(s2)
    8000116e:	0014f793          	andi	a5,s1,1
    80001172:	dfd5                	beqz	a5,8000112e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001174:	80a9                	srli	s1,s1,0xa
    80001176:	04b2                	slli	s1,s1,0xc
    80001178:	b7c5                	j	80001158 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000117a:	00c9d513          	srli	a0,s3,0xc
    8000117e:	1ff57513          	andi	a0,a0,511
    80001182:	050e                	slli	a0,a0,0x3
    80001184:	9526                	add	a0,a0,s1
}
    80001186:	70e2                	ld	ra,56(sp)
    80001188:	7442                	ld	s0,48(sp)
    8000118a:	74a2                	ld	s1,40(sp)
    8000118c:	7902                	ld	s2,32(sp)
    8000118e:	69e2                	ld	s3,24(sp)
    80001190:	6a42                	ld	s4,16(sp)
    80001192:	6aa2                	ld	s5,8(sp)
    80001194:	6b02                	ld	s6,0(sp)
    80001196:	6121                	addi	sp,sp,64
    80001198:	8082                	ret
        return 0;
    8000119a:	4501                	li	a0,0
    8000119c:	b7ed                	j	80001186 <walk+0x8e>

000000008000119e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000119e:	57fd                	li	a5,-1
    800011a0:	83e9                	srli	a5,a5,0x1a
    800011a2:	00b7f463          	bgeu	a5,a1,800011aa <walkaddr+0xc>
    return 0;
    800011a6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011a8:	8082                	ret
{
    800011aa:	1141                	addi	sp,sp,-16
    800011ac:	e406                	sd	ra,8(sp)
    800011ae:	e022                	sd	s0,0(sp)
    800011b0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011b2:	4601                	li	a2,0
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f44080e7          	jalr	-188(ra) # 800010f8 <walk>
  if(pte == 0)
    800011bc:	c105                	beqz	a0,800011dc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011be:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011c0:	0117f693          	andi	a3,a5,17
    800011c4:	4745                	li	a4,17
    return 0;
    800011c6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011c8:	00e68663          	beq	a3,a4,800011d4 <walkaddr+0x36>
}
    800011cc:	60a2                	ld	ra,8(sp)
    800011ce:	6402                	ld	s0,0(sp)
    800011d0:	0141                	addi	sp,sp,16
    800011d2:	8082                	ret
  pa = PTE2PA(*pte);
    800011d4:	00a7d513          	srli	a0,a5,0xa
    800011d8:	0532                	slli	a0,a0,0xc
  return pa;
    800011da:	bfcd                	j	800011cc <walkaddr+0x2e>
    return 0;
    800011dc:	4501                	li	a0,0
    800011de:	b7fd                	j	800011cc <walkaddr+0x2e>

00000000800011e0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011e0:	715d                	addi	sp,sp,-80
    800011e2:	e486                	sd	ra,72(sp)
    800011e4:	e0a2                	sd	s0,64(sp)
    800011e6:	fc26                	sd	s1,56(sp)
    800011e8:	f84a                	sd	s2,48(sp)
    800011ea:	f44e                	sd	s3,40(sp)
    800011ec:	f052                	sd	s4,32(sp)
    800011ee:	ec56                	sd	s5,24(sp)
    800011f0:	e85a                	sd	s6,16(sp)
    800011f2:	e45e                	sd	s7,8(sp)
    800011f4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011f6:	c205                	beqz	a2,80001216 <mappages+0x36>
    800011f8:	8aaa                	mv	s5,a0
    800011fa:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011fc:	77fd                	lui	a5,0xfffff
    800011fe:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001202:	15fd                	addi	a1,a1,-1
    80001204:	00c589b3          	add	s3,a1,a2
    80001208:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000120c:	8952                	mv	s2,s4
    8000120e:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001212:	6b85                	lui	s7,0x1
    80001214:	a015                	j	80001238 <mappages+0x58>
    panic("mappages: size");
    80001216:	00007517          	auipc	a0,0x7
    8000121a:	f0250513          	addi	a0,a0,-254 # 80008118 <digits+0xd8>
    8000121e:	fffff097          	auipc	ra,0xfffff
    80001222:	320080e7          	jalr	800(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001226:	00007517          	auipc	a0,0x7
    8000122a:	f0250513          	addi	a0,a0,-254 # 80008128 <digits+0xe8>
    8000122e:	fffff097          	auipc	ra,0xfffff
    80001232:	310080e7          	jalr	784(ra) # 8000053e <panic>
    a += PGSIZE;
    80001236:	995e                	add	s2,s2,s7
  for(;;){
    80001238:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000123c:	4605                	li	a2,1
    8000123e:	85ca                	mv	a1,s2
    80001240:	8556                	mv	a0,s5
    80001242:	00000097          	auipc	ra,0x0
    80001246:	eb6080e7          	jalr	-330(ra) # 800010f8 <walk>
    8000124a:	cd19                	beqz	a0,80001268 <mappages+0x88>
    if(*pte & PTE_V)
    8000124c:	611c                	ld	a5,0(a0)
    8000124e:	8b85                	andi	a5,a5,1
    80001250:	fbf9                	bnez	a5,80001226 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001252:	80b1                	srli	s1,s1,0xc
    80001254:	04aa                	slli	s1,s1,0xa
    80001256:	0164e4b3          	or	s1,s1,s6
    8000125a:	0014e493          	ori	s1,s1,1
    8000125e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001260:	fd391be3          	bne	s2,s3,80001236 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001264:	4501                	li	a0,0
    80001266:	a011                	j	8000126a <mappages+0x8a>
      return -1;
    80001268:	557d                	li	a0,-1
}
    8000126a:	60a6                	ld	ra,72(sp)
    8000126c:	6406                	ld	s0,64(sp)
    8000126e:	74e2                	ld	s1,56(sp)
    80001270:	7942                	ld	s2,48(sp)
    80001272:	79a2                	ld	s3,40(sp)
    80001274:	7a02                	ld	s4,32(sp)
    80001276:	6ae2                	ld	s5,24(sp)
    80001278:	6b42                	ld	s6,16(sp)
    8000127a:	6ba2                	ld	s7,8(sp)
    8000127c:	6161                	addi	sp,sp,80
    8000127e:	8082                	ret

0000000080001280 <kvmmap>:
{
    80001280:	1141                	addi	sp,sp,-16
    80001282:	e406                	sd	ra,8(sp)
    80001284:	e022                	sd	s0,0(sp)
    80001286:	0800                	addi	s0,sp,16
    80001288:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000128a:	86b2                	mv	a3,a2
    8000128c:	863e                	mv	a2,a5
    8000128e:	00000097          	auipc	ra,0x0
    80001292:	f52080e7          	jalr	-174(ra) # 800011e0 <mappages>
    80001296:	e509                	bnez	a0,800012a0 <kvmmap+0x20>
}
    80001298:	60a2                	ld	ra,8(sp)
    8000129a:	6402                	ld	s0,0(sp)
    8000129c:	0141                	addi	sp,sp,16
    8000129e:	8082                	ret
    panic("kvmmap");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e9850513          	addi	a0,a0,-360 # 80008138 <digits+0xf8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	296080e7          	jalr	662(ra) # 8000053e <panic>

00000000800012b0 <kvmmake>:
{
    800012b0:	1101                	addi	sp,sp,-32
    800012b2:	ec06                	sd	ra,24(sp)
    800012b4:	e822                	sd	s0,16(sp)
    800012b6:	e426                	sd	s1,8(sp)
    800012b8:	e04a                	sd	s2,0(sp)
    800012ba:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012bc:	00000097          	auipc	ra,0x0
    800012c0:	838080e7          	jalr	-1992(ra) # 80000af4 <kalloc>
    800012c4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012c6:	6605                	lui	a2,0x1
    800012c8:	4581                	li	a1,0
    800012ca:	00000097          	auipc	ra,0x0
    800012ce:	a16080e7          	jalr	-1514(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012d2:	4719                	li	a4,6
    800012d4:	6685                	lui	a3,0x1
    800012d6:	10000637          	lui	a2,0x10000
    800012da:	100005b7          	lui	a1,0x10000
    800012de:	8526                	mv	a0,s1
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	fa0080e7          	jalr	-96(ra) # 80001280 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012e8:	4719                	li	a4,6
    800012ea:	6685                	lui	a3,0x1
    800012ec:	10001637          	lui	a2,0x10001
    800012f0:	100015b7          	lui	a1,0x10001
    800012f4:	8526                	mv	a0,s1
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	f8a080e7          	jalr	-118(ra) # 80001280 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012fe:	4719                	li	a4,6
    80001300:	004006b7          	lui	a3,0x400
    80001304:	0c000637          	lui	a2,0xc000
    80001308:	0c0005b7          	lui	a1,0xc000
    8000130c:	8526                	mv	a0,s1
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f72080e7          	jalr	-142(ra) # 80001280 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001316:	00007917          	auipc	s2,0x7
    8000131a:	cea90913          	addi	s2,s2,-790 # 80008000 <etext>
    8000131e:	4729                	li	a4,10
    80001320:	80007697          	auipc	a3,0x80007
    80001324:	ce068693          	addi	a3,a3,-800 # 8000 <_entry-0x7fff8000>
    80001328:	4605                	li	a2,1
    8000132a:	067e                	slli	a2,a2,0x1f
    8000132c:	85b2                	mv	a1,a2
    8000132e:	8526                	mv	a0,s1
    80001330:	00000097          	auipc	ra,0x0
    80001334:	f50080e7          	jalr	-176(ra) # 80001280 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001338:	4719                	li	a4,6
    8000133a:	46c5                	li	a3,17
    8000133c:	06ee                	slli	a3,a3,0x1b
    8000133e:	412686b3          	sub	a3,a3,s2
    80001342:	864a                	mv	a2,s2
    80001344:	85ca                	mv	a1,s2
    80001346:	8526                	mv	a0,s1
    80001348:	00000097          	auipc	ra,0x0
    8000134c:	f38080e7          	jalr	-200(ra) # 80001280 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001350:	4729                	li	a4,10
    80001352:	6685                	lui	a3,0x1
    80001354:	00006617          	auipc	a2,0x6
    80001358:	cac60613          	addi	a2,a2,-852 # 80007000 <_trampoline>
    8000135c:	040005b7          	lui	a1,0x4000
    80001360:	15fd                	addi	a1,a1,-1
    80001362:	05b2                	slli	a1,a1,0xc
    80001364:	8526                	mv	a0,s1
    80001366:	00000097          	auipc	ra,0x0
    8000136a:	f1a080e7          	jalr	-230(ra) # 80001280 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000136e:	8526                	mv	a0,s1
    80001370:	00000097          	auipc	ra,0x0
    80001374:	5fe080e7          	jalr	1534(ra) # 8000196e <proc_mapstacks>
}
    80001378:	8526                	mv	a0,s1
    8000137a:	60e2                	ld	ra,24(sp)
    8000137c:	6442                	ld	s0,16(sp)
    8000137e:	64a2                	ld	s1,8(sp)
    80001380:	6902                	ld	s2,0(sp)
    80001382:	6105                	addi	sp,sp,32
    80001384:	8082                	ret

0000000080001386 <kvminit>:
{
    80001386:	1141                	addi	sp,sp,-16
    80001388:	e406                	sd	ra,8(sp)
    8000138a:	e022                	sd	s0,0(sp)
    8000138c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000138e:	00000097          	auipc	ra,0x0
    80001392:	f22080e7          	jalr	-222(ra) # 800012b0 <kvmmake>
    80001396:	00008797          	auipc	a5,0x8
    8000139a:	c8a7b523          	sd	a0,-886(a5) # 80009020 <kernel_pagetable>
}
    8000139e:	60a2                	ld	ra,8(sp)
    800013a0:	6402                	ld	s0,0(sp)
    800013a2:	0141                	addi	sp,sp,16
    800013a4:	8082                	ret

00000000800013a6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013a6:	715d                	addi	sp,sp,-80
    800013a8:	e486                	sd	ra,72(sp)
    800013aa:	e0a2                	sd	s0,64(sp)
    800013ac:	fc26                	sd	s1,56(sp)
    800013ae:	f84a                	sd	s2,48(sp)
    800013b0:	f44e                	sd	s3,40(sp)
    800013b2:	f052                	sd	s4,32(sp)
    800013b4:	ec56                	sd	s5,24(sp)
    800013b6:	e85a                	sd	s6,16(sp)
    800013b8:	e45e                	sd	s7,8(sp)
    800013ba:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013bc:	03459793          	slli	a5,a1,0x34
    800013c0:	e795                	bnez	a5,800013ec <uvmunmap+0x46>
    800013c2:	8a2a                	mv	s4,a0
    800013c4:	892e                	mv	s2,a1
    800013c6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c8:	0632                	slli	a2,a2,0xc
    800013ca:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ce:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d0:	6b05                	lui	s6,0x1
    800013d2:	0735e863          	bltu	a1,s3,80001442 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013d6:	60a6                	ld	ra,72(sp)
    800013d8:	6406                	ld	s0,64(sp)
    800013da:	74e2                	ld	s1,56(sp)
    800013dc:	7942                	ld	s2,48(sp)
    800013de:	79a2                	ld	s3,40(sp)
    800013e0:	7a02                	ld	s4,32(sp)
    800013e2:	6ae2                	ld	s5,24(sp)
    800013e4:	6b42                	ld	s6,16(sp)
    800013e6:	6ba2                	ld	s7,8(sp)
    800013e8:	6161                	addi	sp,sp,80
    800013ea:	8082                	ret
    panic("uvmunmap: not aligned");
    800013ec:	00007517          	auipc	a0,0x7
    800013f0:	d5450513          	addi	a0,a0,-684 # 80008140 <digits+0x100>
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	14a080e7          	jalr	330(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800013fc:	00007517          	auipc	a0,0x7
    80001400:	d5c50513          	addi	a0,a0,-676 # 80008158 <digits+0x118>
    80001404:	fffff097          	auipc	ra,0xfffff
    80001408:	13a080e7          	jalr	314(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000140c:	00007517          	auipc	a0,0x7
    80001410:	d5c50513          	addi	a0,a0,-676 # 80008168 <digits+0x128>
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	12a080e7          	jalr	298(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000141c:	00007517          	auipc	a0,0x7
    80001420:	d6450513          	addi	a0,a0,-668 # 80008180 <digits+0x140>
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	11a080e7          	jalr	282(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    8000142c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000142e:	0532                	slli	a0,a0,0xc
    80001430:	fffff097          	auipc	ra,0xfffff
    80001434:	5c8080e7          	jalr	1480(ra) # 800009f8 <kfree>
    *pte = 0;
    80001438:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000143c:	995a                	add	s2,s2,s6
    8000143e:	f9397ce3          	bgeu	s2,s3,800013d6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001442:	4601                	li	a2,0
    80001444:	85ca                	mv	a1,s2
    80001446:	8552                	mv	a0,s4
    80001448:	00000097          	auipc	ra,0x0
    8000144c:	cb0080e7          	jalr	-848(ra) # 800010f8 <walk>
    80001450:	84aa                	mv	s1,a0
    80001452:	d54d                	beqz	a0,800013fc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001454:	6108                	ld	a0,0(a0)
    80001456:	00157793          	andi	a5,a0,1
    8000145a:	dbcd                	beqz	a5,8000140c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000145c:	3ff57793          	andi	a5,a0,1023
    80001460:	fb778ee3          	beq	a5,s7,8000141c <uvmunmap+0x76>
    if(do_free){
    80001464:	fc0a8ae3          	beqz	s5,80001438 <uvmunmap+0x92>
    80001468:	b7d1                	j	8000142c <uvmunmap+0x86>

000000008000146a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000146a:	1101                	addi	sp,sp,-32
    8000146c:	ec06                	sd	ra,24(sp)
    8000146e:	e822                	sd	s0,16(sp)
    80001470:	e426                	sd	s1,8(sp)
    80001472:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001474:	fffff097          	auipc	ra,0xfffff
    80001478:	680080e7          	jalr	1664(ra) # 80000af4 <kalloc>
    8000147c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000147e:	c519                	beqz	a0,8000148c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001480:	6605                	lui	a2,0x1
    80001482:	4581                	li	a1,0
    80001484:	00000097          	auipc	ra,0x0
    80001488:	85c080e7          	jalr	-1956(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000148c:	8526                	mv	a0,s1
    8000148e:	60e2                	ld	ra,24(sp)
    80001490:	6442                	ld	s0,16(sp)
    80001492:	64a2                	ld	s1,8(sp)
    80001494:	6105                	addi	sp,sp,32
    80001496:	8082                	ret

0000000080001498 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001498:	7179                	addi	sp,sp,-48
    8000149a:	f406                	sd	ra,40(sp)
    8000149c:	f022                	sd	s0,32(sp)
    8000149e:	ec26                	sd	s1,24(sp)
    800014a0:	e84a                	sd	s2,16(sp)
    800014a2:	e44e                	sd	s3,8(sp)
    800014a4:	e052                	sd	s4,0(sp)
    800014a6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014a8:	6785                	lui	a5,0x1
    800014aa:	04f67863          	bgeu	a2,a5,800014fa <uvminit+0x62>
    800014ae:	8a2a                	mv	s4,a0
    800014b0:	89ae                	mv	s3,a1
    800014b2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014b4:	fffff097          	auipc	ra,0xfffff
    800014b8:	640080e7          	jalr	1600(ra) # 80000af4 <kalloc>
    800014bc:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014be:	6605                	lui	a2,0x1
    800014c0:	4581                	li	a1,0
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	81e080e7          	jalr	-2018(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014ca:	4779                	li	a4,30
    800014cc:	86ca                	mv	a3,s2
    800014ce:	6605                	lui	a2,0x1
    800014d0:	4581                	li	a1,0
    800014d2:	8552                	mv	a0,s4
    800014d4:	00000097          	auipc	ra,0x0
    800014d8:	d0c080e7          	jalr	-756(ra) # 800011e0 <mappages>
  memmove(mem, src, sz);
    800014dc:	8626                	mv	a2,s1
    800014de:	85ce                	mv	a1,s3
    800014e0:	854a                	mv	a0,s2
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	85e080e7          	jalr	-1954(ra) # 80000d40 <memmove>
}
    800014ea:	70a2                	ld	ra,40(sp)
    800014ec:	7402                	ld	s0,32(sp)
    800014ee:	64e2                	ld	s1,24(sp)
    800014f0:	6942                	ld	s2,16(sp)
    800014f2:	69a2                	ld	s3,8(sp)
    800014f4:	6a02                	ld	s4,0(sp)
    800014f6:	6145                	addi	sp,sp,48
    800014f8:	8082                	ret
    panic("inituvm: more than a page");
    800014fa:	00007517          	auipc	a0,0x7
    800014fe:	c9e50513          	addi	a0,a0,-866 # 80008198 <digits+0x158>
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	03c080e7          	jalr	60(ra) # 8000053e <panic>

000000008000150a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000150a:	1101                	addi	sp,sp,-32
    8000150c:	ec06                	sd	ra,24(sp)
    8000150e:	e822                	sd	s0,16(sp)
    80001510:	e426                	sd	s1,8(sp)
    80001512:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001514:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001516:	00b67d63          	bgeu	a2,a1,80001530 <uvmdealloc+0x26>
    8000151a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000151c:	6785                	lui	a5,0x1
    8000151e:	17fd                	addi	a5,a5,-1
    80001520:	00f60733          	add	a4,a2,a5
    80001524:	767d                	lui	a2,0xfffff
    80001526:	8f71                	and	a4,a4,a2
    80001528:	97ae                	add	a5,a5,a1
    8000152a:	8ff1                	and	a5,a5,a2
    8000152c:	00f76863          	bltu	a4,a5,8000153c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001530:	8526                	mv	a0,s1
    80001532:	60e2                	ld	ra,24(sp)
    80001534:	6442                	ld	s0,16(sp)
    80001536:	64a2                	ld	s1,8(sp)
    80001538:	6105                	addi	sp,sp,32
    8000153a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000153c:	8f99                	sub	a5,a5,a4
    8000153e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001540:	4685                	li	a3,1
    80001542:	0007861b          	sext.w	a2,a5
    80001546:	85ba                	mv	a1,a4
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	e5e080e7          	jalr	-418(ra) # 800013a6 <uvmunmap>
    80001550:	b7c5                	j	80001530 <uvmdealloc+0x26>

0000000080001552 <uvmalloc>:
  if(newsz < oldsz)
    80001552:	0ab66163          	bltu	a2,a1,800015f4 <uvmalloc+0xa2>
{
    80001556:	7139                	addi	sp,sp,-64
    80001558:	fc06                	sd	ra,56(sp)
    8000155a:	f822                	sd	s0,48(sp)
    8000155c:	f426                	sd	s1,40(sp)
    8000155e:	f04a                	sd	s2,32(sp)
    80001560:	ec4e                	sd	s3,24(sp)
    80001562:	e852                	sd	s4,16(sp)
    80001564:	e456                	sd	s5,8(sp)
    80001566:	0080                	addi	s0,sp,64
    80001568:	8aaa                	mv	s5,a0
    8000156a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000156c:	6985                	lui	s3,0x1
    8000156e:	19fd                	addi	s3,s3,-1
    80001570:	95ce                	add	a1,a1,s3
    80001572:	79fd                	lui	s3,0xfffff
    80001574:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001578:	08c9f063          	bgeu	s3,a2,800015f8 <uvmalloc+0xa6>
    8000157c:	894e                	mv	s2,s3
    mem = kalloc();
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	576080e7          	jalr	1398(ra) # 80000af4 <kalloc>
    80001586:	84aa                	mv	s1,a0
    if(mem == 0){
    80001588:	c51d                	beqz	a0,800015b6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000158a:	6605                	lui	a2,0x1
    8000158c:	4581                	li	a1,0
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	752080e7          	jalr	1874(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001596:	4779                	li	a4,30
    80001598:	86a6                	mv	a3,s1
    8000159a:	6605                	lui	a2,0x1
    8000159c:	85ca                	mv	a1,s2
    8000159e:	8556                	mv	a0,s5
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	c40080e7          	jalr	-960(ra) # 800011e0 <mappages>
    800015a8:	e905                	bnez	a0,800015d8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015aa:	6785                	lui	a5,0x1
    800015ac:	993e                	add	s2,s2,a5
    800015ae:	fd4968e3          	bltu	s2,s4,8000157e <uvmalloc+0x2c>
  return newsz;
    800015b2:	8552                	mv	a0,s4
    800015b4:	a809                	j	800015c6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015b6:	864e                	mv	a2,s3
    800015b8:	85ca                	mv	a1,s2
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	f4e080e7          	jalr	-178(ra) # 8000150a <uvmdealloc>
      return 0;
    800015c4:	4501                	li	a0,0
}
    800015c6:	70e2                	ld	ra,56(sp)
    800015c8:	7442                	ld	s0,48(sp)
    800015ca:	74a2                	ld	s1,40(sp)
    800015cc:	7902                	ld	s2,32(sp)
    800015ce:	69e2                	ld	s3,24(sp)
    800015d0:	6a42                	ld	s4,16(sp)
    800015d2:	6aa2                	ld	s5,8(sp)
    800015d4:	6121                	addi	sp,sp,64
    800015d6:	8082                	ret
      kfree(mem);
    800015d8:	8526                	mv	a0,s1
    800015da:	fffff097          	auipc	ra,0xfffff
    800015de:	41e080e7          	jalr	1054(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015e2:	864e                	mv	a2,s3
    800015e4:	85ca                	mv	a1,s2
    800015e6:	8556                	mv	a0,s5
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	f22080e7          	jalr	-222(ra) # 8000150a <uvmdealloc>
      return 0;
    800015f0:	4501                	li	a0,0
    800015f2:	bfd1                	j	800015c6 <uvmalloc+0x74>
    return oldsz;
    800015f4:	852e                	mv	a0,a1
}
    800015f6:	8082                	ret
  return newsz;
    800015f8:	8532                	mv	a0,a2
    800015fa:	b7f1                	j	800015c6 <uvmalloc+0x74>

00000000800015fc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015fc:	7179                	addi	sp,sp,-48
    800015fe:	f406                	sd	ra,40(sp)
    80001600:	f022                	sd	s0,32(sp)
    80001602:	ec26                	sd	s1,24(sp)
    80001604:	e84a                	sd	s2,16(sp)
    80001606:	e44e                	sd	s3,8(sp)
    80001608:	e052                	sd	s4,0(sp)
    8000160a:	1800                	addi	s0,sp,48
    8000160c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000160e:	84aa                	mv	s1,a0
    80001610:	6905                	lui	s2,0x1
    80001612:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001614:	4985                	li	s3,1
    80001616:	a821                	j	8000162e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001618:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000161a:	0532                	slli	a0,a0,0xc
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	fe0080e7          	jalr	-32(ra) # 800015fc <freewalk>
      pagetable[i] = 0;
    80001624:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001628:	04a1                	addi	s1,s1,8
    8000162a:	03248163          	beq	s1,s2,8000164c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000162e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001630:	00f57793          	andi	a5,a0,15
    80001634:	ff3782e3          	beq	a5,s3,80001618 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001638:	8905                	andi	a0,a0,1
    8000163a:	d57d                	beqz	a0,80001628 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000163c:	00007517          	auipc	a0,0x7
    80001640:	b7c50513          	addi	a0,a0,-1156 # 800081b8 <digits+0x178>
    80001644:	fffff097          	auipc	ra,0xfffff
    80001648:	efa080e7          	jalr	-262(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000164c:	8552                	mv	a0,s4
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	3aa080e7          	jalr	938(ra) # 800009f8 <kfree>
}
    80001656:	70a2                	ld	ra,40(sp)
    80001658:	7402                	ld	s0,32(sp)
    8000165a:	64e2                	ld	s1,24(sp)
    8000165c:	6942                	ld	s2,16(sp)
    8000165e:	69a2                	ld	s3,8(sp)
    80001660:	6a02                	ld	s4,0(sp)
    80001662:	6145                	addi	sp,sp,48
    80001664:	8082                	ret

0000000080001666 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001666:	1101                	addi	sp,sp,-32
    80001668:	ec06                	sd	ra,24(sp)
    8000166a:	e822                	sd	s0,16(sp)
    8000166c:	e426                	sd	s1,8(sp)
    8000166e:	1000                	addi	s0,sp,32
    80001670:	84aa                	mv	s1,a0
  if(sz > 0)
    80001672:	e999                	bnez	a1,80001688 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001674:	8526                	mv	a0,s1
    80001676:	00000097          	auipc	ra,0x0
    8000167a:	f86080e7          	jalr	-122(ra) # 800015fc <freewalk>
}
    8000167e:	60e2                	ld	ra,24(sp)
    80001680:	6442                	ld	s0,16(sp)
    80001682:	64a2                	ld	s1,8(sp)
    80001684:	6105                	addi	sp,sp,32
    80001686:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001688:	6605                	lui	a2,0x1
    8000168a:	167d                	addi	a2,a2,-1
    8000168c:	962e                	add	a2,a2,a1
    8000168e:	4685                	li	a3,1
    80001690:	8231                	srli	a2,a2,0xc
    80001692:	4581                	li	a1,0
    80001694:	00000097          	auipc	ra,0x0
    80001698:	d12080e7          	jalr	-750(ra) # 800013a6 <uvmunmap>
    8000169c:	bfe1                	j	80001674 <uvmfree+0xe>

000000008000169e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000169e:	c679                	beqz	a2,8000176c <uvmcopy+0xce>
{
    800016a0:	715d                	addi	sp,sp,-80
    800016a2:	e486                	sd	ra,72(sp)
    800016a4:	e0a2                	sd	s0,64(sp)
    800016a6:	fc26                	sd	s1,56(sp)
    800016a8:	f84a                	sd	s2,48(sp)
    800016aa:	f44e                	sd	s3,40(sp)
    800016ac:	f052                	sd	s4,32(sp)
    800016ae:	ec56                	sd	s5,24(sp)
    800016b0:	e85a                	sd	s6,16(sp)
    800016b2:	e45e                	sd	s7,8(sp)
    800016b4:	0880                	addi	s0,sp,80
    800016b6:	8b2a                	mv	s6,a0
    800016b8:	8aae                	mv	s5,a1
    800016ba:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016bc:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800016be:	4601                	li	a2,0
    800016c0:	85ce                	mv	a1,s3
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	a34080e7          	jalr	-1484(ra) # 800010f8 <walk>
    800016cc:	c531                	beqz	a0,80001718 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016ce:	6118                	ld	a4,0(a0)
    800016d0:	00177793          	andi	a5,a4,1
    800016d4:	cbb1                	beqz	a5,80001728 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016d6:	00a75593          	srli	a1,a4,0xa
    800016da:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016de:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016e2:	fffff097          	auipc	ra,0xfffff
    800016e6:	412080e7          	jalr	1042(ra) # 80000af4 <kalloc>
    800016ea:	892a                	mv	s2,a0
    800016ec:	c939                	beqz	a0,80001742 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016ee:	6605                	lui	a2,0x1
    800016f0:	85de                	mv	a1,s7
    800016f2:	fffff097          	auipc	ra,0xfffff
    800016f6:	64e080e7          	jalr	1614(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016fa:	8726                	mv	a4,s1
    800016fc:	86ca                	mv	a3,s2
    800016fe:	6605                	lui	a2,0x1
    80001700:	85ce                	mv	a1,s3
    80001702:	8556                	mv	a0,s5
    80001704:	00000097          	auipc	ra,0x0
    80001708:	adc080e7          	jalr	-1316(ra) # 800011e0 <mappages>
    8000170c:	e515                	bnez	a0,80001738 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000170e:	6785                	lui	a5,0x1
    80001710:	99be                	add	s3,s3,a5
    80001712:	fb49e6e3          	bltu	s3,s4,800016be <uvmcopy+0x20>
    80001716:	a081                	j	80001756 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001718:	00007517          	auipc	a0,0x7
    8000171c:	ab050513          	addi	a0,a0,-1360 # 800081c8 <digits+0x188>
    80001720:	fffff097          	auipc	ra,0xfffff
    80001724:	e1e080e7          	jalr	-482(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001728:	00007517          	auipc	a0,0x7
    8000172c:	ac050513          	addi	a0,a0,-1344 # 800081e8 <digits+0x1a8>
    80001730:	fffff097          	auipc	ra,0xfffff
    80001734:	e0e080e7          	jalr	-498(ra) # 8000053e <panic>
      kfree(mem);
    80001738:	854a                	mv	a0,s2
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	2be080e7          	jalr	702(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001742:	4685                	li	a3,1
    80001744:	00c9d613          	srli	a2,s3,0xc
    80001748:	4581                	li	a1,0
    8000174a:	8556                	mv	a0,s5
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	c5a080e7          	jalr	-934(ra) # 800013a6 <uvmunmap>
  return -1;
    80001754:	557d                	li	a0,-1
}
    80001756:	60a6                	ld	ra,72(sp)
    80001758:	6406                	ld	s0,64(sp)
    8000175a:	74e2                	ld	s1,56(sp)
    8000175c:	7942                	ld	s2,48(sp)
    8000175e:	79a2                	ld	s3,40(sp)
    80001760:	7a02                	ld	s4,32(sp)
    80001762:	6ae2                	ld	s5,24(sp)
    80001764:	6b42                	ld	s6,16(sp)
    80001766:	6ba2                	ld	s7,8(sp)
    80001768:	6161                	addi	sp,sp,80
    8000176a:	8082                	ret
  return 0;
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret

0000000080001770 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001770:	1141                	addi	sp,sp,-16
    80001772:	e406                	sd	ra,8(sp)
    80001774:	e022                	sd	s0,0(sp)
    80001776:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001778:	4601                	li	a2,0
    8000177a:	00000097          	auipc	ra,0x0
    8000177e:	97e080e7          	jalr	-1666(ra) # 800010f8 <walk>
  if(pte == 0)
    80001782:	c901                	beqz	a0,80001792 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001784:	611c                	ld	a5,0(a0)
    80001786:	9bbd                	andi	a5,a5,-17
    80001788:	e11c                	sd	a5,0(a0)
}
    8000178a:	60a2                	ld	ra,8(sp)
    8000178c:	6402                	ld	s0,0(sp)
    8000178e:	0141                	addi	sp,sp,16
    80001790:	8082                	ret
    panic("uvmclear");
    80001792:	00007517          	auipc	a0,0x7
    80001796:	a7650513          	addi	a0,a0,-1418 # 80008208 <digits+0x1c8>
    8000179a:	fffff097          	auipc	ra,0xfffff
    8000179e:	da4080e7          	jalr	-604(ra) # 8000053e <panic>

00000000800017a2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a2:	c6bd                	beqz	a3,80001810 <copyout+0x6e>
{
    800017a4:	715d                	addi	sp,sp,-80
    800017a6:	e486                	sd	ra,72(sp)
    800017a8:	e0a2                	sd	s0,64(sp)
    800017aa:	fc26                	sd	s1,56(sp)
    800017ac:	f84a                	sd	s2,48(sp)
    800017ae:	f44e                	sd	s3,40(sp)
    800017b0:	f052                	sd	s4,32(sp)
    800017b2:	ec56                	sd	s5,24(sp)
    800017b4:	e85a                	sd	s6,16(sp)
    800017b6:	e45e                	sd	s7,8(sp)
    800017b8:	e062                	sd	s8,0(sp)
    800017ba:	0880                	addi	s0,sp,80
    800017bc:	8b2a                	mv	s6,a0
    800017be:	8c2e                	mv	s8,a1
    800017c0:	8a32                	mv	s4,a2
    800017c2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017c4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017c6:	6a85                	lui	s5,0x1
    800017c8:	a015                	j	800017ec <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017ca:	9562                	add	a0,a0,s8
    800017cc:	0004861b          	sext.w	a2,s1
    800017d0:	85d2                	mv	a1,s4
    800017d2:	41250533          	sub	a0,a0,s2
    800017d6:	fffff097          	auipc	ra,0xfffff
    800017da:	56a080e7          	jalr	1386(ra) # 80000d40 <memmove>

    len -= n;
    800017de:	409989b3          	sub	s3,s3,s1
    src += n;
    800017e2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017e4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017e8:	02098263          	beqz	s3,8000180c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017ec:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	855a                	mv	a0,s6
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	9aa080e7          	jalr	-1622(ra) # 8000119e <walkaddr>
    if(pa0 == 0)
    800017fc:	cd01                	beqz	a0,80001814 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017fe:	418904b3          	sub	s1,s2,s8
    80001802:	94d6                	add	s1,s1,s5
    if(n > len)
    80001804:	fc99f3e3          	bgeu	s3,s1,800017ca <copyout+0x28>
    80001808:	84ce                	mv	s1,s3
    8000180a:	b7c1                	j	800017ca <copyout+0x28>
  }
  return 0;
    8000180c:	4501                	li	a0,0
    8000180e:	a021                	j	80001816 <copyout+0x74>
    80001810:	4501                	li	a0,0
}
    80001812:	8082                	ret
      return -1;
    80001814:	557d                	li	a0,-1
}
    80001816:	60a6                	ld	ra,72(sp)
    80001818:	6406                	ld	s0,64(sp)
    8000181a:	74e2                	ld	s1,56(sp)
    8000181c:	7942                	ld	s2,48(sp)
    8000181e:	79a2                	ld	s3,40(sp)
    80001820:	7a02                	ld	s4,32(sp)
    80001822:	6ae2                	ld	s5,24(sp)
    80001824:	6b42                	ld	s6,16(sp)
    80001826:	6ba2                	ld	s7,8(sp)
    80001828:	6c02                	ld	s8,0(sp)
    8000182a:	6161                	addi	sp,sp,80
    8000182c:	8082                	ret

000000008000182e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000182e:	c6bd                	beqz	a3,8000189c <copyin+0x6e>
{
    80001830:	715d                	addi	sp,sp,-80
    80001832:	e486                	sd	ra,72(sp)
    80001834:	e0a2                	sd	s0,64(sp)
    80001836:	fc26                	sd	s1,56(sp)
    80001838:	f84a                	sd	s2,48(sp)
    8000183a:	f44e                	sd	s3,40(sp)
    8000183c:	f052                	sd	s4,32(sp)
    8000183e:	ec56                	sd	s5,24(sp)
    80001840:	e85a                	sd	s6,16(sp)
    80001842:	e45e                	sd	s7,8(sp)
    80001844:	e062                	sd	s8,0(sp)
    80001846:	0880                	addi	s0,sp,80
    80001848:	8b2a                	mv	s6,a0
    8000184a:	8a2e                	mv	s4,a1
    8000184c:	8c32                	mv	s8,a2
    8000184e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001850:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001852:	6a85                	lui	s5,0x1
    80001854:	a015                	j	80001878 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001856:	9562                	add	a0,a0,s8
    80001858:	0004861b          	sext.w	a2,s1
    8000185c:	412505b3          	sub	a1,a0,s2
    80001860:	8552                	mv	a0,s4
    80001862:	fffff097          	auipc	ra,0xfffff
    80001866:	4de080e7          	jalr	1246(ra) # 80000d40 <memmove>

    len -= n;
    8000186a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000186e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001870:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001874:	02098263          	beqz	s3,80001898 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001878:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000187c:	85ca                	mv	a1,s2
    8000187e:	855a                	mv	a0,s6
    80001880:	00000097          	auipc	ra,0x0
    80001884:	91e080e7          	jalr	-1762(ra) # 8000119e <walkaddr>
    if(pa0 == 0)
    80001888:	cd01                	beqz	a0,800018a0 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000188a:	418904b3          	sub	s1,s2,s8
    8000188e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001890:	fc99f3e3          	bgeu	s3,s1,80001856 <copyin+0x28>
    80001894:	84ce                	mv	s1,s3
    80001896:	b7c1                	j	80001856 <copyin+0x28>
  }
  return 0;
    80001898:	4501                	li	a0,0
    8000189a:	a021                	j	800018a2 <copyin+0x74>
    8000189c:	4501                	li	a0,0
}
    8000189e:	8082                	ret
      return -1;
    800018a0:	557d                	li	a0,-1
}
    800018a2:	60a6                	ld	ra,72(sp)
    800018a4:	6406                	ld	s0,64(sp)
    800018a6:	74e2                	ld	s1,56(sp)
    800018a8:	7942                	ld	s2,48(sp)
    800018aa:	79a2                	ld	s3,40(sp)
    800018ac:	7a02                	ld	s4,32(sp)
    800018ae:	6ae2                	ld	s5,24(sp)
    800018b0:	6b42                	ld	s6,16(sp)
    800018b2:	6ba2                	ld	s7,8(sp)
    800018b4:	6c02                	ld	s8,0(sp)
    800018b6:	6161                	addi	sp,sp,80
    800018b8:	8082                	ret

00000000800018ba <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018ba:	c6c5                	beqz	a3,80001962 <copyinstr+0xa8>
{
    800018bc:	715d                	addi	sp,sp,-80
    800018be:	e486                	sd	ra,72(sp)
    800018c0:	e0a2                	sd	s0,64(sp)
    800018c2:	fc26                	sd	s1,56(sp)
    800018c4:	f84a                	sd	s2,48(sp)
    800018c6:	f44e                	sd	s3,40(sp)
    800018c8:	f052                	sd	s4,32(sp)
    800018ca:	ec56                	sd	s5,24(sp)
    800018cc:	e85a                	sd	s6,16(sp)
    800018ce:	e45e                	sd	s7,8(sp)
    800018d0:	0880                	addi	s0,sp,80
    800018d2:	8a2a                	mv	s4,a0
    800018d4:	8b2e                	mv	s6,a1
    800018d6:	8bb2                	mv	s7,a2
    800018d8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018da:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018dc:	6985                	lui	s3,0x1
    800018de:	a035                	j	8000190a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018e0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018e4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018e6:	0017b793          	seqz	a5,a5
    800018ea:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018ee:	60a6                	ld	ra,72(sp)
    800018f0:	6406                	ld	s0,64(sp)
    800018f2:	74e2                	ld	s1,56(sp)
    800018f4:	7942                	ld	s2,48(sp)
    800018f6:	79a2                	ld	s3,40(sp)
    800018f8:	7a02                	ld	s4,32(sp)
    800018fa:	6ae2                	ld	s5,24(sp)
    800018fc:	6b42                	ld	s6,16(sp)
    800018fe:	6ba2                	ld	s7,8(sp)
    80001900:	6161                	addi	sp,sp,80
    80001902:	8082                	ret
    srcva = va0 + PGSIZE;
    80001904:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001908:	c8a9                	beqz	s1,8000195a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000190a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000190e:	85ca                	mv	a1,s2
    80001910:	8552                	mv	a0,s4
    80001912:	00000097          	auipc	ra,0x0
    80001916:	88c080e7          	jalr	-1908(ra) # 8000119e <walkaddr>
    if(pa0 == 0)
    8000191a:	c131                	beqz	a0,8000195e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000191c:	41790833          	sub	a6,s2,s7
    80001920:	984e                	add	a6,a6,s3
    if(n > max)
    80001922:	0104f363          	bgeu	s1,a6,80001928 <copyinstr+0x6e>
    80001926:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001928:	955e                	add	a0,a0,s7
    8000192a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000192e:	fc080be3          	beqz	a6,80001904 <copyinstr+0x4a>
    80001932:	985a                	add	a6,a6,s6
    80001934:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001936:	41650633          	sub	a2,a0,s6
    8000193a:	14fd                	addi	s1,s1,-1
    8000193c:	9b26                	add	s6,s6,s1
    8000193e:	00f60733          	add	a4,a2,a5
    80001942:	00074703          	lbu	a4,0(a4)
    80001946:	df49                	beqz	a4,800018e0 <copyinstr+0x26>
        *dst = *p;
    80001948:	00e78023          	sb	a4,0(a5)
      --max;
    8000194c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001950:	0785                	addi	a5,a5,1
    while(n > 0){
    80001952:	ff0796e3          	bne	a5,a6,8000193e <copyinstr+0x84>
      dst++;
    80001956:	8b42                	mv	s6,a6
    80001958:	b775                	j	80001904 <copyinstr+0x4a>
    8000195a:	4781                	li	a5,0
    8000195c:	b769                	j	800018e6 <copyinstr+0x2c>
      return -1;
    8000195e:	557d                	li	a0,-1
    80001960:	b779                	j	800018ee <copyinstr+0x34>
  int got_null = 0;
    80001962:	4781                	li	a5,0
  if(got_null){
    80001964:	0017b793          	seqz	a5,a5
    80001968:	40f00533          	neg	a0,a5
}
    8000196c:	8082                	ret

000000008000196e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000196e:	7139                	addi	sp,sp,-64
    80001970:	fc06                	sd	ra,56(sp)
    80001972:	f822                	sd	s0,48(sp)
    80001974:	f426                	sd	s1,40(sp)
    80001976:	f04a                	sd	s2,32(sp)
    80001978:	ec4e                	sd	s3,24(sp)
    8000197a:	e852                	sd	s4,16(sp)
    8000197c:	e456                	sd	s5,8(sp)
    8000197e:	e05a                	sd	s6,0(sp)
    80001980:	0080                	addi	s0,sp,64
    80001982:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001984:	00010497          	auipc	s1,0x10
    80001988:	d4c48493          	addi	s1,s1,-692 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000198c:	8b26                	mv	s6,s1
    8000198e:	00006a97          	auipc	s5,0x6
    80001992:	672a8a93          	addi	s5,s5,1650 # 80008000 <etext>
    80001996:	04000937          	lui	s2,0x4000
    8000199a:	197d                	addi	s2,s2,-1
    8000199c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199e:	00015a17          	auipc	s4,0x15
    800019a2:	732a0a13          	addi	s4,s4,1842 # 800170d0 <tickslock>
    char *pa = kalloc();
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	14e080e7          	jalr	334(ra) # 80000af4 <kalloc>
    800019ae:	862a                	mv	a2,a0
    if(pa == 0)
    800019b0:	c131                	beqz	a0,800019f4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019b2:	416485b3          	sub	a1,s1,s6
    800019b6:	858d                	srai	a1,a1,0x3
    800019b8:	000ab783          	ld	a5,0(s5)
    800019bc:	02f585b3          	mul	a1,a1,a5
    800019c0:	2585                	addiw	a1,a1,1
    800019c2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019c6:	4719                	li	a4,6
    800019c8:	6685                	lui	a3,0x1
    800019ca:	40b905b3          	sub	a1,s2,a1
    800019ce:	854e                	mv	a0,s3
    800019d0:	00000097          	auipc	ra,0x0
    800019d4:	8b0080e7          	jalr	-1872(ra) # 80001280 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019d8:	16848493          	addi	s1,s1,360
    800019dc:	fd4495e3          	bne	s1,s4,800019a6 <proc_mapstacks+0x38>
  }
}
    800019e0:	70e2                	ld	ra,56(sp)
    800019e2:	7442                	ld	s0,48(sp)
    800019e4:	74a2                	ld	s1,40(sp)
    800019e6:	7902                	ld	s2,32(sp)
    800019e8:	69e2                	ld	s3,24(sp)
    800019ea:	6a42                	ld	s4,16(sp)
    800019ec:	6aa2                	ld	s5,8(sp)
    800019ee:	6b02                	ld	s6,0(sp)
    800019f0:	6121                	addi	sp,sp,64
    800019f2:	8082                	ret
      panic("kalloc");
    800019f4:	00007517          	auipc	a0,0x7
    800019f8:	82450513          	addi	a0,a0,-2012 # 80008218 <digits+0x1d8>
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	b42080e7          	jalr	-1214(ra) # 8000053e <panic>

0000000080001a04 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001a04:	7139                	addi	sp,sp,-64
    80001a06:	fc06                	sd	ra,56(sp)
    80001a08:	f822                	sd	s0,48(sp)
    80001a0a:	f426                	sd	s1,40(sp)
    80001a0c:	f04a                	sd	s2,32(sp)
    80001a0e:	ec4e                	sd	s3,24(sp)
    80001a10:	e852                	sd	s4,16(sp)
    80001a12:	e456                	sd	s5,8(sp)
    80001a14:	e05a                	sd	s6,0(sp)
    80001a16:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a18:	00007597          	auipc	a1,0x7
    80001a1c:	80858593          	addi	a1,a1,-2040 # 80008220 <digits+0x1e0>
    80001a20:	00010517          	auipc	a0,0x10
    80001a24:	88050513          	addi	a0,a0,-1920 # 800112a0 <pid_lock>
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	12c080e7          	jalr	300(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a30:	00006597          	auipc	a1,0x6
    80001a34:	7f858593          	addi	a1,a1,2040 # 80008228 <digits+0x1e8>
    80001a38:	00010517          	auipc	a0,0x10
    80001a3c:	88050513          	addi	a0,a0,-1920 # 800112b8 <wait_lock>
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	114080e7          	jalr	276(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a48:	00010497          	auipc	s1,0x10
    80001a4c:	c8848493          	addi	s1,s1,-888 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001a50:	00006b17          	auipc	s6,0x6
    80001a54:	7e8b0b13          	addi	s6,s6,2024 # 80008238 <digits+0x1f8>
      p->kstack = KSTACK((int) (p - proc));
    80001a58:	8aa6                	mv	s5,s1
    80001a5a:	00006a17          	auipc	s4,0x6
    80001a5e:	5a6a0a13          	addi	s4,s4,1446 # 80008000 <etext>
    80001a62:	04000937          	lui	s2,0x4000
    80001a66:	197d                	addi	s2,s2,-1
    80001a68:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6a:	00015997          	auipc	s3,0x15
    80001a6e:	66698993          	addi	s3,s3,1638 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a72:	85da                	mv	a1,s6
    80001a74:	8526                	mv	a0,s1
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	0de080e7          	jalr	222(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a7e:	415487b3          	sub	a5,s1,s5
    80001a82:	878d                	srai	a5,a5,0x3
    80001a84:	000a3703          	ld	a4,0(s4)
    80001a88:	02e787b3          	mul	a5,a5,a4
    80001a8c:	2785                	addiw	a5,a5,1
    80001a8e:	00d7979b          	slliw	a5,a5,0xd
    80001a92:	40f907b3          	sub	a5,s2,a5
    80001a96:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a98:	16848493          	addi	s1,s1,360
    80001a9c:	fd349be3          	bne	s1,s3,80001a72 <procinit+0x6e>
  }
}
    80001aa0:	70e2                	ld	ra,56(sp)
    80001aa2:	7442                	ld	s0,48(sp)
    80001aa4:	74a2                	ld	s1,40(sp)
    80001aa6:	7902                	ld	s2,32(sp)
    80001aa8:	69e2                	ld	s3,24(sp)
    80001aaa:	6a42                	ld	s4,16(sp)
    80001aac:	6aa2                	ld	s5,8(sp)
    80001aae:	6b02                	ld	s6,0(sp)
    80001ab0:	6121                	addi	sp,sp,64
    80001ab2:	8082                	ret

0000000080001ab4 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ab4:	1141                	addi	sp,sp,-16
    80001ab6:	e422                	sd	s0,8(sp)
    80001ab8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aba:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001abc:	2501                	sext.w	a0,a0
    80001abe:	6422                	ld	s0,8(sp)
    80001ac0:	0141                	addi	sp,sp,16
    80001ac2:	8082                	ret

0000000080001ac4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001ac4:	1141                	addi	sp,sp,-16
    80001ac6:	e422                	sd	s0,8(sp)
    80001ac8:	0800                	addi	s0,sp,16
    80001aca:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001acc:	2781                	sext.w	a5,a5
    80001ace:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ad0:	00010517          	auipc	a0,0x10
    80001ad4:	80050513          	addi	a0,a0,-2048 # 800112d0 <cpus>
    80001ad8:	953e                	add	a0,a0,a5
    80001ada:	6422                	ld	s0,8(sp)
    80001adc:	0141                	addi	sp,sp,16
    80001ade:	8082                	ret

0000000080001ae0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ae0:	1101                	addi	sp,sp,-32
    80001ae2:	ec06                	sd	ra,24(sp)
    80001ae4:	e822                	sd	s0,16(sp)
    80001ae6:	e426                	sd	s1,8(sp)
    80001ae8:	1000                	addi	s0,sp,32
  push_off();
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	0ae080e7          	jalr	174(ra) # 80000b98 <push_off>
    80001af2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001af4:	2781                	sext.w	a5,a5
    80001af6:	079e                	slli	a5,a5,0x7
    80001af8:	0000f717          	auipc	a4,0xf
    80001afc:	7a870713          	addi	a4,a4,1960 # 800112a0 <pid_lock>
    80001b00:	97ba                	add	a5,a5,a4
    80001b02:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b04:	fffff097          	auipc	ra,0xfffff
    80001b08:	134080e7          	jalr	308(ra) # 80000c38 <pop_off>
  return p;
}
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	60e2                	ld	ra,24(sp)
    80001b10:	6442                	ld	s0,16(sp)
    80001b12:	64a2                	ld	s1,8(sp)
    80001b14:	6105                	addi	sp,sp,32
    80001b16:	8082                	ret

0000000080001b18 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b18:	1141                	addi	sp,sp,-16
    80001b1a:	e406                	sd	ra,8(sp)
    80001b1c:	e022                	sd	s0,0(sp)
    80001b1e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b20:	00000097          	auipc	ra,0x0
    80001b24:	fc0080e7          	jalr	-64(ra) # 80001ae0 <myproc>
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	170080e7          	jalr	368(ra) # 80000c98 <release>

  if (first) {
    80001b30:	00007797          	auipc	a5,0x7
    80001b34:	d307a783          	lw	a5,-720(a5) # 80008860 <first.1696>
    80001b38:	eb89                	bnez	a5,80001b4a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b3a:	00001097          	auipc	ra,0x1
    80001b3e:	d48080e7          	jalr	-696(ra) # 80002882 <usertrapret>
}
    80001b42:	60a2                	ld	ra,8(sp)
    80001b44:	6402                	ld	s0,0(sp)
    80001b46:	0141                	addi	sp,sp,16
    80001b48:	8082                	ret
    first = 0;
    80001b4a:	00007797          	auipc	a5,0x7
    80001b4e:	d007ab23          	sw	zero,-746(a5) # 80008860 <first.1696>
    fsinit(ROOTDEV);
    80001b52:	4505                	li	a0,1
    80001b54:	00002097          	auipc	ra,0x2
    80001b58:	aba080e7          	jalr	-1350(ra) # 8000360e <fsinit>
    80001b5c:	bff9                	j	80001b3a <forkret+0x22>

0000000080001b5e <allocpid>:
allocpid() {
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	e04a                	sd	s2,0(sp)
    80001b68:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b6a:	0000f917          	auipc	s2,0xf
    80001b6e:	73690913          	addi	s2,s2,1846 # 800112a0 <pid_lock>
    80001b72:	854a                	mv	a0,s2
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	070080e7          	jalr	112(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b7c:	00007797          	auipc	a5,0x7
    80001b80:	ce878793          	addi	a5,a5,-792 # 80008864 <nextpid>
    80001b84:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b86:	0014871b          	addiw	a4,s1,1
    80001b8a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b8c:	854a                	mv	a0,s2
    80001b8e:	fffff097          	auipc	ra,0xfffff
    80001b92:	10a080e7          	jalr	266(ra) # 80000c98 <release>
}
    80001b96:	8526                	mv	a0,s1
    80001b98:	60e2                	ld	ra,24(sp)
    80001b9a:	6442                	ld	s0,16(sp)
    80001b9c:	64a2                	ld	s1,8(sp)
    80001b9e:	6902                	ld	s2,0(sp)
    80001ba0:	6105                	addi	sp,sp,32
    80001ba2:	8082                	ret

0000000080001ba4 <proc_pagetable>:
{
    80001ba4:	1101                	addi	sp,sp,-32
    80001ba6:	ec06                	sd	ra,24(sp)
    80001ba8:	e822                	sd	s0,16(sp)
    80001baa:	e426                	sd	s1,8(sp)
    80001bac:	e04a                	sd	s2,0(sp)
    80001bae:	1000                	addi	s0,sp,32
    80001bb0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bb2:	00000097          	auipc	ra,0x0
    80001bb6:	8b8080e7          	jalr	-1864(ra) # 8000146a <uvmcreate>
    80001bba:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bbc:	c121                	beqz	a0,80001bfc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bbe:	4729                	li	a4,10
    80001bc0:	00005697          	auipc	a3,0x5
    80001bc4:	44068693          	addi	a3,a3,1088 # 80007000 <_trampoline>
    80001bc8:	6605                	lui	a2,0x1
    80001bca:	040005b7          	lui	a1,0x4000
    80001bce:	15fd                	addi	a1,a1,-1
    80001bd0:	05b2                	slli	a1,a1,0xc
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	60e080e7          	jalr	1550(ra) # 800011e0 <mappages>
    80001bda:	02054863          	bltz	a0,80001c0a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bde:	4719                	li	a4,6
    80001be0:	05893683          	ld	a3,88(s2)
    80001be4:	6605                	lui	a2,0x1
    80001be6:	020005b7          	lui	a1,0x2000
    80001bea:	15fd                	addi	a1,a1,-1
    80001bec:	05b6                	slli	a1,a1,0xd
    80001bee:	8526                	mv	a0,s1
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	5f0080e7          	jalr	1520(ra) # 800011e0 <mappages>
    80001bf8:	02054163          	bltz	a0,80001c1a <proc_pagetable+0x76>
}
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	60e2                	ld	ra,24(sp)
    80001c00:	6442                	ld	s0,16(sp)
    80001c02:	64a2                	ld	s1,8(sp)
    80001c04:	6902                	ld	s2,0(sp)
    80001c06:	6105                	addi	sp,sp,32
    80001c08:	8082                	ret
    uvmfree(pagetable, 0);
    80001c0a:	4581                	li	a1,0
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	a58080e7          	jalr	-1448(ra) # 80001666 <uvmfree>
    return 0;
    80001c16:	4481                	li	s1,0
    80001c18:	b7d5                	j	80001bfc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c1a:	4681                	li	a3,0
    80001c1c:	4605                	li	a2,1
    80001c1e:	040005b7          	lui	a1,0x4000
    80001c22:	15fd                	addi	a1,a1,-1
    80001c24:	05b2                	slli	a1,a1,0xc
    80001c26:	8526                	mv	a0,s1
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	77e080e7          	jalr	1918(ra) # 800013a6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c30:	4581                	li	a1,0
    80001c32:	8526                	mv	a0,s1
    80001c34:	00000097          	auipc	ra,0x0
    80001c38:	a32080e7          	jalr	-1486(ra) # 80001666 <uvmfree>
    return 0;
    80001c3c:	4481                	li	s1,0
    80001c3e:	bf7d                	j	80001bfc <proc_pagetable+0x58>

0000000080001c40 <proc_freepagetable>:
{
    80001c40:	1101                	addi	sp,sp,-32
    80001c42:	ec06                	sd	ra,24(sp)
    80001c44:	e822                	sd	s0,16(sp)
    80001c46:	e426                	sd	s1,8(sp)
    80001c48:	e04a                	sd	s2,0(sp)
    80001c4a:	1000                	addi	s0,sp,32
    80001c4c:	84aa                	mv	s1,a0
    80001c4e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c50:	4681                	li	a3,0
    80001c52:	4605                	li	a2,1
    80001c54:	040005b7          	lui	a1,0x4000
    80001c58:	15fd                	addi	a1,a1,-1
    80001c5a:	05b2                	slli	a1,a1,0xc
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	74a080e7          	jalr	1866(ra) # 800013a6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c64:	4681                	li	a3,0
    80001c66:	4605                	li	a2,1
    80001c68:	020005b7          	lui	a1,0x2000
    80001c6c:	15fd                	addi	a1,a1,-1
    80001c6e:	05b6                	slli	a1,a1,0xd
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	734080e7          	jalr	1844(ra) # 800013a6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c7a:	85ca                	mv	a1,s2
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	9e8080e7          	jalr	-1560(ra) # 80001666 <uvmfree>
}
    80001c86:	60e2                	ld	ra,24(sp)
    80001c88:	6442                	ld	s0,16(sp)
    80001c8a:	64a2                	ld	s1,8(sp)
    80001c8c:	6902                	ld	s2,0(sp)
    80001c8e:	6105                	addi	sp,sp,32
    80001c90:	8082                	ret

0000000080001c92 <freeproc>:
{
    80001c92:	1101                	addi	sp,sp,-32
    80001c94:	ec06                	sd	ra,24(sp)
    80001c96:	e822                	sd	s0,16(sp)
    80001c98:	e426                	sd	s1,8(sp)
    80001c9a:	1000                	addi	s0,sp,32
    80001c9c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c9e:	6d28                	ld	a0,88(a0)
    80001ca0:	c509                	beqz	a0,80001caa <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	d56080e7          	jalr	-682(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001caa:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cae:	68a8                	ld	a0,80(s1)
    80001cb0:	c511                	beqz	a0,80001cbc <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cb2:	64ac                	ld	a1,72(s1)
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	f8c080e7          	jalr	-116(ra) # 80001c40 <proc_freepagetable>
  p->pagetable = 0;
    80001cbc:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cc0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cc4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cc8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ccc:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cd0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cd4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cd8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cdc:	0004ac23          	sw	zero,24(s1)
}
    80001ce0:	60e2                	ld	ra,24(sp)
    80001ce2:	6442                	ld	s0,16(sp)
    80001ce4:	64a2                	ld	s1,8(sp)
    80001ce6:	6105                	addi	sp,sp,32
    80001ce8:	8082                	ret

0000000080001cea <allocproc>:
{
    80001cea:	1101                	addi	sp,sp,-32
    80001cec:	ec06                	sd	ra,24(sp)
    80001cee:	e822                	sd	s0,16(sp)
    80001cf0:	e426                	sd	s1,8(sp)
    80001cf2:	e04a                	sd	s2,0(sp)
    80001cf4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf6:	00010497          	auipc	s1,0x10
    80001cfa:	9da48493          	addi	s1,s1,-1574 # 800116d0 <proc>
    80001cfe:	00015917          	auipc	s2,0x15
    80001d02:	3d290913          	addi	s2,s2,978 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	edc080e7          	jalr	-292(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001d10:	4c9c                	lw	a5,24(s1)
    80001d12:	cf81                	beqz	a5,80001d2a <allocproc+0x40>
      release(&p->lock);
    80001d14:	8526                	mv	a0,s1
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	f82080e7          	jalr	-126(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d1e:	16848493          	addi	s1,s1,360
    80001d22:	ff2492e3          	bne	s1,s2,80001d06 <allocproc+0x1c>
  return 0;
    80001d26:	4481                	li	s1,0
    80001d28:	a889                	j	80001d7a <allocproc+0x90>
  p->pid = allocpid();
    80001d2a:	00000097          	auipc	ra,0x0
    80001d2e:	e34080e7          	jalr	-460(ra) # 80001b5e <allocpid>
    80001d32:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d34:	4785                	li	a5,1
    80001d36:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	dbc080e7          	jalr	-580(ra) # 80000af4 <kalloc>
    80001d40:	892a                	mv	s2,a0
    80001d42:	eca8                	sd	a0,88(s1)
    80001d44:	c131                	beqz	a0,80001d88 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d46:	8526                	mv	a0,s1
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	e5c080e7          	jalr	-420(ra) # 80001ba4 <proc_pagetable>
    80001d50:	892a                	mv	s2,a0
    80001d52:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d54:	c531                	beqz	a0,80001da0 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d56:	07000613          	li	a2,112
    80001d5a:	4581                	li	a1,0
    80001d5c:	06048513          	addi	a0,s1,96
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	f80080e7          	jalr	-128(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d68:	00000797          	auipc	a5,0x0
    80001d6c:	db078793          	addi	a5,a5,-592 # 80001b18 <forkret>
    80001d70:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d72:	60bc                	ld	a5,64(s1)
    80001d74:	6705                	lui	a4,0x1
    80001d76:	97ba                	add	a5,a5,a4
    80001d78:	f4bc                	sd	a5,104(s1)
}
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	60e2                	ld	ra,24(sp)
    80001d7e:	6442                	ld	s0,16(sp)
    80001d80:	64a2                	ld	s1,8(sp)
    80001d82:	6902                	ld	s2,0(sp)
    80001d84:	6105                	addi	sp,sp,32
    80001d86:	8082                	ret
    freeproc(p);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	00000097          	auipc	ra,0x0
    80001d8e:	f08080e7          	jalr	-248(ra) # 80001c92 <freeproc>
    release(&p->lock);
    80001d92:	8526                	mv	a0,s1
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	f04080e7          	jalr	-252(ra) # 80000c98 <release>
    return 0;
    80001d9c:	84ca                	mv	s1,s2
    80001d9e:	bff1                	j	80001d7a <allocproc+0x90>
    freeproc(p);
    80001da0:	8526                	mv	a0,s1
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	ef0080e7          	jalr	-272(ra) # 80001c92 <freeproc>
    release(&p->lock);
    80001daa:	8526                	mv	a0,s1
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	eec080e7          	jalr	-276(ra) # 80000c98 <release>
    return 0;
    80001db4:	84ca                	mv	s1,s2
    80001db6:	b7d1                	j	80001d7a <allocproc+0x90>

0000000080001db8 <userinit>:
{
    80001db8:	1101                	addi	sp,sp,-32
    80001dba:	ec06                	sd	ra,24(sp)
    80001dbc:	e822                	sd	s0,16(sp)
    80001dbe:	e426                	sd	s1,8(sp)
    80001dc0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	f28080e7          	jalr	-216(ra) # 80001cea <allocproc>
    80001dca:	84aa                	mv	s1,a0
  initproc = p;
    80001dcc:	00007797          	auipc	a5,0x7
    80001dd0:	24a7be23          	sd	a0,604(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dd4:	03400613          	li	a2,52
    80001dd8:	00007597          	auipc	a1,0x7
    80001ddc:	a9858593          	addi	a1,a1,-1384 # 80008870 <initcode>
    80001de0:	6928                	ld	a0,80(a0)
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	6b6080e7          	jalr	1718(ra) # 80001498 <uvminit>
  p->sz = PGSIZE;
    80001dea:	6785                	lui	a5,0x1
    80001dec:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dee:	6cb8                	ld	a4,88(s1)
    80001df0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001df4:	6cb8                	ld	a4,88(s1)
    80001df6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001df8:	4641                	li	a2,16
    80001dfa:	00006597          	auipc	a1,0x6
    80001dfe:	44658593          	addi	a1,a1,1094 # 80008240 <digits+0x200>
    80001e02:	15848513          	addi	a0,s1,344
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	02c080e7          	jalr	44(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001e0e:	00006517          	auipc	a0,0x6
    80001e12:	44250513          	addi	a0,a0,1090 # 80008250 <digits+0x210>
    80001e16:	00002097          	auipc	ra,0x2
    80001e1a:	226080e7          	jalr	550(ra) # 8000403c <namei>
    80001e1e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e22:	478d                	li	a5,3
    80001e24:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e26:	8526                	mv	a0,s1
    80001e28:	fffff097          	auipc	ra,0xfffff
    80001e2c:	e70080e7          	jalr	-400(ra) # 80000c98 <release>
}
    80001e30:	60e2                	ld	ra,24(sp)
    80001e32:	6442                	ld	s0,16(sp)
    80001e34:	64a2                	ld	s1,8(sp)
    80001e36:	6105                	addi	sp,sp,32
    80001e38:	8082                	ret

0000000080001e3a <growproc>:
{
    80001e3a:	1101                	addi	sp,sp,-32
    80001e3c:	ec06                	sd	ra,24(sp)
    80001e3e:	e822                	sd	s0,16(sp)
    80001e40:	e426                	sd	s1,8(sp)
    80001e42:	e04a                	sd	s2,0(sp)
    80001e44:	1000                	addi	s0,sp,32
    80001e46:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	c98080e7          	jalr	-872(ra) # 80001ae0 <myproc>
    80001e50:	892a                	mv	s2,a0
  sz = p->sz;
    80001e52:	652c                	ld	a1,72(a0)
    80001e54:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e58:	00904f63          	bgtz	s1,80001e76 <growproc+0x3c>
  } else if(n < 0){
    80001e5c:	0204cc63          	bltz	s1,80001e94 <growproc+0x5a>
  p->sz = sz;
    80001e60:	1602                	slli	a2,a2,0x20
    80001e62:	9201                	srli	a2,a2,0x20
    80001e64:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e68:	4501                	li	a0,0
}
    80001e6a:	60e2                	ld	ra,24(sp)
    80001e6c:	6442                	ld	s0,16(sp)
    80001e6e:	64a2                	ld	s1,8(sp)
    80001e70:	6902                	ld	s2,0(sp)
    80001e72:	6105                	addi	sp,sp,32
    80001e74:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e76:	9e25                	addw	a2,a2,s1
    80001e78:	1602                	slli	a2,a2,0x20
    80001e7a:	9201                	srli	a2,a2,0x20
    80001e7c:	1582                	slli	a1,a1,0x20
    80001e7e:	9181                	srli	a1,a1,0x20
    80001e80:	6928                	ld	a0,80(a0)
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	6d0080e7          	jalr	1744(ra) # 80001552 <uvmalloc>
    80001e8a:	0005061b          	sext.w	a2,a0
    80001e8e:	fa69                	bnez	a2,80001e60 <growproc+0x26>
      return -1;
    80001e90:	557d                	li	a0,-1
    80001e92:	bfe1                	j	80001e6a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e94:	9e25                	addw	a2,a2,s1
    80001e96:	1602                	slli	a2,a2,0x20
    80001e98:	9201                	srli	a2,a2,0x20
    80001e9a:	1582                	slli	a1,a1,0x20
    80001e9c:	9181                	srli	a1,a1,0x20
    80001e9e:	6928                	ld	a0,80(a0)
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	66a080e7          	jalr	1642(ra) # 8000150a <uvmdealloc>
    80001ea8:	0005061b          	sext.w	a2,a0
    80001eac:	bf55                	j	80001e60 <growproc+0x26>

0000000080001eae <fork>:
{
    80001eae:	7179                	addi	sp,sp,-48
    80001eb0:	f406                	sd	ra,40(sp)
    80001eb2:	f022                	sd	s0,32(sp)
    80001eb4:	ec26                	sd	s1,24(sp)
    80001eb6:	e84a                	sd	s2,16(sp)
    80001eb8:	e44e                	sd	s3,8(sp)
    80001eba:	e052                	sd	s4,0(sp)
    80001ebc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ebe:	00000097          	auipc	ra,0x0
    80001ec2:	c22080e7          	jalr	-990(ra) # 80001ae0 <myproc>
    80001ec6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	e22080e7          	jalr	-478(ra) # 80001cea <allocproc>
    80001ed0:	10050b63          	beqz	a0,80001fe6 <fork+0x138>
    80001ed4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ed6:	04893603          	ld	a2,72(s2)
    80001eda:	692c                	ld	a1,80(a0)
    80001edc:	05093503          	ld	a0,80(s2)
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	7be080e7          	jalr	1982(ra) # 8000169e <uvmcopy>
    80001ee8:	04054663          	bltz	a0,80001f34 <fork+0x86>
  np->sz = p->sz;
    80001eec:	04893783          	ld	a5,72(s2)
    80001ef0:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ef4:	05893683          	ld	a3,88(s2)
    80001ef8:	87b6                	mv	a5,a3
    80001efa:	0589b703          	ld	a4,88(s3)
    80001efe:	12068693          	addi	a3,a3,288
    80001f02:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f06:	6788                	ld	a0,8(a5)
    80001f08:	6b8c                	ld	a1,16(a5)
    80001f0a:	6f90                	ld	a2,24(a5)
    80001f0c:	01073023          	sd	a6,0(a4)
    80001f10:	e708                	sd	a0,8(a4)
    80001f12:	eb0c                	sd	a1,16(a4)
    80001f14:	ef10                	sd	a2,24(a4)
    80001f16:	02078793          	addi	a5,a5,32
    80001f1a:	02070713          	addi	a4,a4,32
    80001f1e:	fed792e3          	bne	a5,a3,80001f02 <fork+0x54>
  np->trapframe->a0 = 0;
    80001f22:	0589b783          	ld	a5,88(s3)
    80001f26:	0607b823          	sd	zero,112(a5)
    80001f2a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f2e:	15000a13          	li	s4,336
    80001f32:	a03d                	j	80001f60 <fork+0xb2>
    freeproc(np);
    80001f34:	854e                	mv	a0,s3
    80001f36:	00000097          	auipc	ra,0x0
    80001f3a:	d5c080e7          	jalr	-676(ra) # 80001c92 <freeproc>
    release(&np->lock);
    80001f3e:	854e                	mv	a0,s3
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	d58080e7          	jalr	-680(ra) # 80000c98 <release>
    return -1;
    80001f48:	5a7d                	li	s4,-1
    80001f4a:	a069                	j	80001fd4 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f4c:	00002097          	auipc	ra,0x2
    80001f50:	786080e7          	jalr	1926(ra) # 800046d2 <filedup>
    80001f54:	009987b3          	add	a5,s3,s1
    80001f58:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f5a:	04a1                	addi	s1,s1,8
    80001f5c:	01448763          	beq	s1,s4,80001f6a <fork+0xbc>
    if(p->ofile[i])
    80001f60:	009907b3          	add	a5,s2,s1
    80001f64:	6388                	ld	a0,0(a5)
    80001f66:	f17d                	bnez	a0,80001f4c <fork+0x9e>
    80001f68:	bfcd                	j	80001f5a <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f6a:	15093503          	ld	a0,336(s2)
    80001f6e:	00002097          	auipc	ra,0x2
    80001f72:	8da080e7          	jalr	-1830(ra) # 80003848 <idup>
    80001f76:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f7a:	4641                	li	a2,16
    80001f7c:	15890593          	addi	a1,s2,344
    80001f80:	15898513          	addi	a0,s3,344
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	eae080e7          	jalr	-338(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f8c:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f90:	854e                	mv	a0,s3
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	d06080e7          	jalr	-762(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f9a:	0000f497          	auipc	s1,0xf
    80001f9e:	31e48493          	addi	s1,s1,798 # 800112b8 <wait_lock>
    80001fa2:	8526                	mv	a0,s1
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	c40080e7          	jalr	-960(ra) # 80000be4 <acquire>
  np->parent = p;
    80001fac:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	ce6080e7          	jalr	-794(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001fba:	854e                	mv	a0,s3
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	c28080e7          	jalr	-984(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001fc4:	478d                	li	a5,3
    80001fc6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fca:	854e                	mv	a0,s3
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	ccc080e7          	jalr	-820(ra) # 80000c98 <release>
}
    80001fd4:	8552                	mv	a0,s4
    80001fd6:	70a2                	ld	ra,40(sp)
    80001fd8:	7402                	ld	s0,32(sp)
    80001fda:	64e2                	ld	s1,24(sp)
    80001fdc:	6942                	ld	s2,16(sp)
    80001fde:	69a2                	ld	s3,8(sp)
    80001fe0:	6a02                	ld	s4,0(sp)
    80001fe2:	6145                	addi	sp,sp,48
    80001fe4:	8082                	ret
    return -1;
    80001fe6:	5a7d                	li	s4,-1
    80001fe8:	b7f5                	j	80001fd4 <fork+0x126>

0000000080001fea <scheduler>:
{
    80001fea:	7139                	addi	sp,sp,-64
    80001fec:	fc06                	sd	ra,56(sp)
    80001fee:	f822                	sd	s0,48(sp)
    80001ff0:	f426                	sd	s1,40(sp)
    80001ff2:	f04a                	sd	s2,32(sp)
    80001ff4:	ec4e                	sd	s3,24(sp)
    80001ff6:	e852                	sd	s4,16(sp)
    80001ff8:	e456                	sd	s5,8(sp)
    80001ffa:	e05a                	sd	s6,0(sp)
    80001ffc:	0080                	addi	s0,sp,64
    80001ffe:	8792                	mv	a5,tp
  int id = r_tp();
    80002000:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002002:	00779a93          	slli	s5,a5,0x7
    80002006:	0000f717          	auipc	a4,0xf
    8000200a:	29a70713          	addi	a4,a4,666 # 800112a0 <pid_lock>
    8000200e:	9756                	add	a4,a4,s5
    80002010:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002014:	0000f717          	auipc	a4,0xf
    80002018:	2c470713          	addi	a4,a4,708 # 800112d8 <cpus+0x8>
    8000201c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000201e:	498d                	li	s3,3
        p->state = RUNNING;
    80002020:	4b11                	li	s6,4
        c->proc = p;
    80002022:	079e                	slli	a5,a5,0x7
    80002024:	0000fa17          	auipc	s4,0xf
    80002028:	27ca0a13          	addi	s4,s4,636 # 800112a0 <pid_lock>
    8000202c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000202e:	00015917          	auipc	s2,0x15
    80002032:	0a290913          	addi	s2,s2,162 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002036:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000203a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000203e:	10079073          	csrw	sstatus,a5
    80002042:	0000f497          	auipc	s1,0xf
    80002046:	68e48493          	addi	s1,s1,1678 # 800116d0 <proc>
    8000204a:	a03d                	j	80002078 <scheduler+0x8e>
        p->state = RUNNING;
    8000204c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002050:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002054:	06048593          	addi	a1,s1,96
    80002058:	8556                	mv	a0,s5
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	77e080e7          	jalr	1918(ra) # 800027d8 <swtch>
        c->proc = 0;
    80002062:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80002066:	8526                	mv	a0,s1
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	c30080e7          	jalr	-976(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002070:	16848493          	addi	s1,s1,360
    80002074:	fd2481e3          	beq	s1,s2,80002036 <scheduler+0x4c>
      acquire(&p->lock);
    80002078:	8526                	mv	a0,s1
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	b6a080e7          	jalr	-1174(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002082:	4c9c                	lw	a5,24(s1)
    80002084:	ff3791e3          	bne	a5,s3,80002066 <scheduler+0x7c>
    80002088:	b7d1                	j	8000204c <scheduler+0x62>

000000008000208a <sched>:
{
    8000208a:	7179                	addi	sp,sp,-48
    8000208c:	f406                	sd	ra,40(sp)
    8000208e:	f022                	sd	s0,32(sp)
    80002090:	ec26                	sd	s1,24(sp)
    80002092:	e84a                	sd	s2,16(sp)
    80002094:	e44e                	sd	s3,8(sp)
    80002096:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	a48080e7          	jalr	-1464(ra) # 80001ae0 <myproc>
    800020a0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	ac8080e7          	jalr	-1336(ra) # 80000b6a <holding>
    800020aa:	c93d                	beqz	a0,80002120 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ac:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020ae:	2781                	sext.w	a5,a5
    800020b0:	079e                	slli	a5,a5,0x7
    800020b2:	0000f717          	auipc	a4,0xf
    800020b6:	1ee70713          	addi	a4,a4,494 # 800112a0 <pid_lock>
    800020ba:	97ba                	add	a5,a5,a4
    800020bc:	0a87a703          	lw	a4,168(a5)
    800020c0:	4785                	li	a5,1
    800020c2:	06f71763          	bne	a4,a5,80002130 <sched+0xa6>
  if(p->state == RUNNING)
    800020c6:	4c98                	lw	a4,24(s1)
    800020c8:	4791                	li	a5,4
    800020ca:	06f70b63          	beq	a4,a5,80002140 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ce:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020d2:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020d4:	efb5                	bnez	a5,80002150 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020d8:	0000f917          	auipc	s2,0xf
    800020dc:	1c890913          	addi	s2,s2,456 # 800112a0 <pid_lock>
    800020e0:	2781                	sext.w	a5,a5
    800020e2:	079e                	slli	a5,a5,0x7
    800020e4:	97ca                	add	a5,a5,s2
    800020e6:	0ac7a983          	lw	s3,172(a5)
    800020ea:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020ec:	2781                	sext.w	a5,a5
    800020ee:	079e                	slli	a5,a5,0x7
    800020f0:	0000f597          	auipc	a1,0xf
    800020f4:	1e858593          	addi	a1,a1,488 # 800112d8 <cpus+0x8>
    800020f8:	95be                	add	a1,a1,a5
    800020fa:	06048513          	addi	a0,s1,96
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	6da080e7          	jalr	1754(ra) # 800027d8 <swtch>
    80002106:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002108:	2781                	sext.w	a5,a5
    8000210a:	079e                	slli	a5,a5,0x7
    8000210c:	97ca                	add	a5,a5,s2
    8000210e:	0b37a623          	sw	s3,172(a5)
}
    80002112:	70a2                	ld	ra,40(sp)
    80002114:	7402                	ld	s0,32(sp)
    80002116:	64e2                	ld	s1,24(sp)
    80002118:	6942                	ld	s2,16(sp)
    8000211a:	69a2                	ld	s3,8(sp)
    8000211c:	6145                	addi	sp,sp,48
    8000211e:	8082                	ret
    panic("sched p->lock");
    80002120:	00006517          	auipc	a0,0x6
    80002124:	13850513          	addi	a0,a0,312 # 80008258 <digits+0x218>
    80002128:	ffffe097          	auipc	ra,0xffffe
    8000212c:	416080e7          	jalr	1046(ra) # 8000053e <panic>
    panic("sched locks");
    80002130:	00006517          	auipc	a0,0x6
    80002134:	13850513          	addi	a0,a0,312 # 80008268 <digits+0x228>
    80002138:	ffffe097          	auipc	ra,0xffffe
    8000213c:	406080e7          	jalr	1030(ra) # 8000053e <panic>
    panic("sched running");
    80002140:	00006517          	auipc	a0,0x6
    80002144:	13850513          	addi	a0,a0,312 # 80008278 <digits+0x238>
    80002148:	ffffe097          	auipc	ra,0xffffe
    8000214c:	3f6080e7          	jalr	1014(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002150:	00006517          	auipc	a0,0x6
    80002154:	13850513          	addi	a0,a0,312 # 80008288 <digits+0x248>
    80002158:	ffffe097          	auipc	ra,0xffffe
    8000215c:	3e6080e7          	jalr	998(ra) # 8000053e <panic>

0000000080002160 <yield>:
{
    80002160:	1101                	addi	sp,sp,-32
    80002162:	ec06                	sd	ra,24(sp)
    80002164:	e822                	sd	s0,16(sp)
    80002166:	e426                	sd	s1,8(sp)
    80002168:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000216a:	00000097          	auipc	ra,0x0
    8000216e:	976080e7          	jalr	-1674(ra) # 80001ae0 <myproc>
    80002172:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	a70080e7          	jalr	-1424(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000217c:	478d                	li	a5,3
    8000217e:	cc9c                	sw	a5,24(s1)
  sched();
    80002180:	00000097          	auipc	ra,0x0
    80002184:	f0a080e7          	jalr	-246(ra) # 8000208a <sched>
  release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b0e080e7          	jalr	-1266(ra) # 80000c98 <release>
}
    80002192:	60e2                	ld	ra,24(sp)
    80002194:	6442                	ld	s0,16(sp)
    80002196:	64a2                	ld	s1,8(sp)
    80002198:	6105                	addi	sp,sp,32
    8000219a:	8082                	ret

000000008000219c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000219c:	7179                	addi	sp,sp,-48
    8000219e:	f406                	sd	ra,40(sp)
    800021a0:	f022                	sd	s0,32(sp)
    800021a2:	ec26                	sd	s1,24(sp)
    800021a4:	e84a                	sd	s2,16(sp)
    800021a6:	e44e                	sd	s3,8(sp)
    800021a8:	1800                	addi	s0,sp,48
    800021aa:	89aa                	mv	s3,a0
    800021ac:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021ae:	00000097          	auipc	ra,0x0
    800021b2:	932080e7          	jalr	-1742(ra) # 80001ae0 <myproc>
    800021b6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	a2c080e7          	jalr	-1492(ra) # 80000be4 <acquire>
  release(lk);
    800021c0:	854a                	mv	a0,s2
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	ad6080e7          	jalr	-1322(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800021ca:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021ce:	4789                	li	a5,2
    800021d0:	cc9c                	sw	a5,24(s1)

  sched();
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	eb8080e7          	jalr	-328(ra) # 8000208a <sched>

  // Tidy up.
  p->chan = 0;
    800021da:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	ab8080e7          	jalr	-1352(ra) # 80000c98 <release>
  acquire(lk);
    800021e8:	854a                	mv	a0,s2
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	9fa080e7          	jalr	-1542(ra) # 80000be4 <acquire>
}
    800021f2:	70a2                	ld	ra,40(sp)
    800021f4:	7402                	ld	s0,32(sp)
    800021f6:	64e2                	ld	s1,24(sp)
    800021f8:	6942                	ld	s2,16(sp)
    800021fa:	69a2                	ld	s3,8(sp)
    800021fc:	6145                	addi	sp,sp,48
    800021fe:	8082                	ret

0000000080002200 <pause_system>:
pause_system(int seconds){
    80002200:	710d                	addi	sp,sp,-352
    80002202:	ee86                	sd	ra,344(sp)
    80002204:	eaa2                	sd	s0,336(sp)
    80002206:	e6a6                	sd	s1,328(sp)
    80002208:	e2ca                	sd	s2,320(sp)
    8000220a:	fe4e                	sd	s3,312(sp)
    8000220c:	fa52                	sd	s4,304(sp)
    8000220e:	f656                	sd	s5,296(sp)
    80002210:	f25a                	sd	s6,288(sp)
    80002212:	ee5e                	sd	s7,280(sp)
    80002214:	ea62                	sd	s8,272(sp)
    80002216:	1280                	addi	s0,sp,352
  uint ticks0 = seconds; // * 1,000,000?
    80002218:	eaa42623          	sw	a0,-340(s0)
  if(seconds < 0)
    8000221c:	0c054463          	bltz	a0,800022e4 <pause_system+0xe4>
    80002220:	0000f917          	auipc	s2,0xf
    80002224:	4b090913          	addi	s2,s2,1200 # 800116d0 <proc>
    80002228:	eb040993          	addi	s3,s0,-336
    8000222c:	00015a97          	auipc	s5,0x15
    80002230:	ea4a8a93          	addi	s5,s5,-348 # 800170d0 <tickslock>
    80002234:	8a4e                	mv	s4,s3
    80002236:	84ca                	mv	s1,s2
    if(proc[i].state == RUNNING)
    80002238:	4b91                	li	s7,4
      proc[i].state = RUNNABLE;
    8000223a:	4c0d                	li	s8,3
    8000223c:	a819                	j	80002252 <pause_system+0x52>
    release(&proc[i].lock);
    8000223e:	855a                	mv	a0,s6
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a58080e7          	jalr	-1448(ra) # 80000c98 <release>
  for (int i = 0; i < NPROC; i++)
    80002248:	16848493          	addi	s1,s1,360
    8000224c:	0a11                	addi	s4,s4,4
    8000224e:	03548163          	beq	s1,s5,80002270 <pause_system+0x70>
    prevState[i] = proc[i].state;
    80002252:	8b26                	mv	s6,s1
    80002254:	4c9c                	lw	a5,24(s1)
    80002256:	00fa2023          	sw	a5,0(s4)
    acquire(&proc[i].lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	988080e7          	jalr	-1656(ra) # 80000be4 <acquire>
    if(proc[i].state == RUNNING)
    80002264:	4c9c                	lw	a5,24(s1)
    80002266:	fd779ce3          	bne	a5,s7,8000223e <pause_system+0x3e>
      proc[i].state = RUNNABLE;
    8000226a:	0184ac23          	sw	s8,24(s1)
    8000226e:	bfc1                	j	8000223e <pause_system+0x3e>
  acquire(&tickslock);
    80002270:	00015517          	auipc	a0,0x15
    80002274:	e6050513          	addi	a0,a0,-416 # 800170d0 <tickslock>
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	96c080e7          	jalr	-1684(ra) # 80000be4 <acquire>
  sleep(&ticks0, &tickslock);
    80002280:	00015597          	auipc	a1,0x15
    80002284:	e5058593          	addi	a1,a1,-432 # 800170d0 <tickslock>
    80002288:	eac40513          	addi	a0,s0,-340
    8000228c:	00000097          	auipc	ra,0x0
    80002290:	f10080e7          	jalr	-240(ra) # 8000219c <sleep>
  release(&tickslock);
    80002294:	00015517          	auipc	a0,0x15
    80002298:	e3c50513          	addi	a0,a0,-452 # 800170d0 <tickslock>
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	9fc080e7          	jalr	-1540(ra) # 80000c98 <release>
    acquire(&proc[i].lock);
    800022a4:	854a                	mv	a0,s2
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	93e080e7          	jalr	-1730(ra) # 80000be4 <acquire>
    proc[i].state = prevState[i];
    800022ae:	0009a783          	lw	a5,0(s3)
    800022b2:	00f92c23          	sw	a5,24(s2)
    release(&proc[i].lock);
    800022b6:	854a                	mv	a0,s2
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	9e0080e7          	jalr	-1568(ra) # 80000c98 <release>
  for (int i = 0; i < NPROC; i++){
    800022c0:	16890913          	addi	s2,s2,360
    800022c4:	0991                	addi	s3,s3,4
    800022c6:	fd591fe3          	bne	s2,s5,800022a4 <pause_system+0xa4>
  return 0;
    800022ca:	4501                	li	a0,0
}
    800022cc:	60f6                	ld	ra,344(sp)
    800022ce:	6456                	ld	s0,336(sp)
    800022d0:	64b6                	ld	s1,328(sp)
    800022d2:	6916                	ld	s2,320(sp)
    800022d4:	79f2                	ld	s3,312(sp)
    800022d6:	7a52                	ld	s4,304(sp)
    800022d8:	7ab2                	ld	s5,296(sp)
    800022da:	7b12                	ld	s6,288(sp)
    800022dc:	6bf2                	ld	s7,280(sp)
    800022de:	6c52                	ld	s8,272(sp)
    800022e0:	6135                	addi	sp,sp,352
    800022e2:	8082                	ret
    return -1;
    800022e4:	557d                	li	a0,-1
    800022e6:	b7dd                	j	800022cc <pause_system+0xcc>

00000000800022e8 <wait>:
{
    800022e8:	715d                	addi	sp,sp,-80
    800022ea:	e486                	sd	ra,72(sp)
    800022ec:	e0a2                	sd	s0,64(sp)
    800022ee:	fc26                	sd	s1,56(sp)
    800022f0:	f84a                	sd	s2,48(sp)
    800022f2:	f44e                	sd	s3,40(sp)
    800022f4:	f052                	sd	s4,32(sp)
    800022f6:	ec56                	sd	s5,24(sp)
    800022f8:	e85a                	sd	s6,16(sp)
    800022fa:	e45e                	sd	s7,8(sp)
    800022fc:	e062                	sd	s8,0(sp)
    800022fe:	0880                	addi	s0,sp,80
    80002300:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	7de080e7          	jalr	2014(ra) # 80001ae0 <myproc>
    8000230a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000230c:	0000f517          	auipc	a0,0xf
    80002310:	fac50513          	addi	a0,a0,-84 # 800112b8 <wait_lock>
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	8d0080e7          	jalr	-1840(ra) # 80000be4 <acquire>
    havekids = 0;
    8000231c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000231e:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002320:	00015997          	auipc	s3,0x15
    80002324:	db098993          	addi	s3,s3,-592 # 800170d0 <tickslock>
        havekids = 1;
    80002328:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000232a:	0000fc17          	auipc	s8,0xf
    8000232e:	f8ec0c13          	addi	s8,s8,-114 # 800112b8 <wait_lock>
    havekids = 0;
    80002332:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002334:	0000f497          	auipc	s1,0xf
    80002338:	39c48493          	addi	s1,s1,924 # 800116d0 <proc>
    8000233c:	a0bd                	j	800023aa <wait+0xc2>
          pid = np->pid;
    8000233e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002342:	000b0e63          	beqz	s6,8000235e <wait+0x76>
    80002346:	4691                	li	a3,4
    80002348:	02c48613          	addi	a2,s1,44
    8000234c:	85da                	mv	a1,s6
    8000234e:	05093503          	ld	a0,80(s2)
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	450080e7          	jalr	1104(ra) # 800017a2 <copyout>
    8000235a:	02054563          	bltz	a0,80002384 <wait+0x9c>
          freeproc(np);
    8000235e:	8526                	mv	a0,s1
    80002360:	00000097          	auipc	ra,0x0
    80002364:	932080e7          	jalr	-1742(ra) # 80001c92 <freeproc>
          release(&np->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	92e080e7          	jalr	-1746(ra) # 80000c98 <release>
          release(&wait_lock);
    80002372:	0000f517          	auipc	a0,0xf
    80002376:	f4650513          	addi	a0,a0,-186 # 800112b8 <wait_lock>
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	91e080e7          	jalr	-1762(ra) # 80000c98 <release>
          return pid;
    80002382:	a09d                	j	800023e8 <wait+0x100>
            release(&np->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	912080e7          	jalr	-1774(ra) # 80000c98 <release>
            release(&wait_lock);
    8000238e:	0000f517          	auipc	a0,0xf
    80002392:	f2a50513          	addi	a0,a0,-214 # 800112b8 <wait_lock>
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	902080e7          	jalr	-1790(ra) # 80000c98 <release>
            return -1;
    8000239e:	59fd                	li	s3,-1
    800023a0:	a0a1                	j	800023e8 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800023a2:	16848493          	addi	s1,s1,360
    800023a6:	03348463          	beq	s1,s3,800023ce <wait+0xe6>
      if(np->parent == p){
    800023aa:	7c9c                	ld	a5,56(s1)
    800023ac:	ff279be3          	bne	a5,s2,800023a2 <wait+0xba>
        acquire(&np->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	832080e7          	jalr	-1998(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800023ba:	4c9c                	lw	a5,24(s1)
    800023bc:	f94781e3          	beq	a5,s4,8000233e <wait+0x56>
        release(&np->lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	8d6080e7          	jalr	-1834(ra) # 80000c98 <release>
        havekids = 1;
    800023ca:	8756                	mv	a4,s5
    800023cc:	bfd9                	j	800023a2 <wait+0xba>
    if(!havekids || p->killed){
    800023ce:	c701                	beqz	a4,800023d6 <wait+0xee>
    800023d0:	02892783          	lw	a5,40(s2)
    800023d4:	c79d                	beqz	a5,80002402 <wait+0x11a>
      release(&wait_lock);
    800023d6:	0000f517          	auipc	a0,0xf
    800023da:	ee250513          	addi	a0,a0,-286 # 800112b8 <wait_lock>
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8ba080e7          	jalr	-1862(ra) # 80000c98 <release>
      return -1;
    800023e6:	59fd                	li	s3,-1
}
    800023e8:	854e                	mv	a0,s3
    800023ea:	60a6                	ld	ra,72(sp)
    800023ec:	6406                	ld	s0,64(sp)
    800023ee:	74e2                	ld	s1,56(sp)
    800023f0:	7942                	ld	s2,48(sp)
    800023f2:	79a2                	ld	s3,40(sp)
    800023f4:	7a02                	ld	s4,32(sp)
    800023f6:	6ae2                	ld	s5,24(sp)
    800023f8:	6b42                	ld	s6,16(sp)
    800023fa:	6ba2                	ld	s7,8(sp)
    800023fc:	6c02                	ld	s8,0(sp)
    800023fe:	6161                	addi	sp,sp,80
    80002400:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002402:	85e2                	mv	a1,s8
    80002404:	854a                	mv	a0,s2
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	d96080e7          	jalr	-618(ra) # 8000219c <sleep>
    havekids = 0;
    8000240e:	b715                	j	80002332 <wait+0x4a>

0000000080002410 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002410:	7139                	addi	sp,sp,-64
    80002412:	fc06                	sd	ra,56(sp)
    80002414:	f822                	sd	s0,48(sp)
    80002416:	f426                	sd	s1,40(sp)
    80002418:	f04a                	sd	s2,32(sp)
    8000241a:	ec4e                	sd	s3,24(sp)
    8000241c:	e852                	sd	s4,16(sp)
    8000241e:	e456                	sd	s5,8(sp)
    80002420:	0080                	addi	s0,sp,64
    80002422:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002424:	0000f497          	auipc	s1,0xf
    80002428:	2ac48493          	addi	s1,s1,684 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000242c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000242e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002430:	00015917          	auipc	s2,0x15
    80002434:	ca090913          	addi	s2,s2,-864 # 800170d0 <tickslock>
    80002438:	a821                	j	80002450 <wakeup+0x40>
        p->state = RUNNABLE;
    8000243a:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	858080e7          	jalr	-1960(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002448:	16848493          	addi	s1,s1,360
    8000244c:	03248463          	beq	s1,s2,80002474 <wakeup+0x64>
    if(p != myproc()){
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	690080e7          	jalr	1680(ra) # 80001ae0 <myproc>
    80002458:	fea488e3          	beq	s1,a0,80002448 <wakeup+0x38>
      acquire(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	ffffe097          	auipc	ra,0xffffe
    80002462:	786080e7          	jalr	1926(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002466:	4c9c                	lw	a5,24(s1)
    80002468:	fd379be3          	bne	a5,s3,8000243e <wakeup+0x2e>
    8000246c:	709c                	ld	a5,32(s1)
    8000246e:	fd4798e3          	bne	a5,s4,8000243e <wakeup+0x2e>
    80002472:	b7e1                	j	8000243a <wakeup+0x2a>
    }
  }
}
    80002474:	70e2                	ld	ra,56(sp)
    80002476:	7442                	ld	s0,48(sp)
    80002478:	74a2                	ld	s1,40(sp)
    8000247a:	7902                	ld	s2,32(sp)
    8000247c:	69e2                	ld	s3,24(sp)
    8000247e:	6a42                	ld	s4,16(sp)
    80002480:	6aa2                	ld	s5,8(sp)
    80002482:	6121                	addi	sp,sp,64
    80002484:	8082                	ret

0000000080002486 <reparent>:
{
    80002486:	7179                	addi	sp,sp,-48
    80002488:	f406                	sd	ra,40(sp)
    8000248a:	f022                	sd	s0,32(sp)
    8000248c:	ec26                	sd	s1,24(sp)
    8000248e:	e84a                	sd	s2,16(sp)
    80002490:	e44e                	sd	s3,8(sp)
    80002492:	e052                	sd	s4,0(sp)
    80002494:	1800                	addi	s0,sp,48
    80002496:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002498:	0000f497          	auipc	s1,0xf
    8000249c:	23848493          	addi	s1,s1,568 # 800116d0 <proc>
      pp->parent = initproc;
    800024a0:	00007a17          	auipc	s4,0x7
    800024a4:	b88a0a13          	addi	s4,s4,-1144 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024a8:	00015997          	auipc	s3,0x15
    800024ac:	c2898993          	addi	s3,s3,-984 # 800170d0 <tickslock>
    800024b0:	a029                	j	800024ba <reparent+0x34>
    800024b2:	16848493          	addi	s1,s1,360
    800024b6:	01348d63          	beq	s1,s3,800024d0 <reparent+0x4a>
    if(pp->parent == p){
    800024ba:	7c9c                	ld	a5,56(s1)
    800024bc:	ff279be3          	bne	a5,s2,800024b2 <reparent+0x2c>
      pp->parent = initproc;
    800024c0:	000a3503          	ld	a0,0(s4)
    800024c4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024c6:	00000097          	auipc	ra,0x0
    800024ca:	f4a080e7          	jalr	-182(ra) # 80002410 <wakeup>
    800024ce:	b7d5                	j	800024b2 <reparent+0x2c>
}
    800024d0:	70a2                	ld	ra,40(sp)
    800024d2:	7402                	ld	s0,32(sp)
    800024d4:	64e2                	ld	s1,24(sp)
    800024d6:	6942                	ld	s2,16(sp)
    800024d8:	69a2                	ld	s3,8(sp)
    800024da:	6a02                	ld	s4,0(sp)
    800024dc:	6145                	addi	sp,sp,48
    800024de:	8082                	ret

00000000800024e0 <exit>:
{
    800024e0:	7179                	addi	sp,sp,-48
    800024e2:	f406                	sd	ra,40(sp)
    800024e4:	f022                	sd	s0,32(sp)
    800024e6:	ec26                	sd	s1,24(sp)
    800024e8:	e84a                	sd	s2,16(sp)
    800024ea:	e44e                	sd	s3,8(sp)
    800024ec:	e052                	sd	s4,0(sp)
    800024ee:	1800                	addi	s0,sp,48
    800024f0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	5ee080e7          	jalr	1518(ra) # 80001ae0 <myproc>
    800024fa:	89aa                	mv	s3,a0
  if(p == initproc)
    800024fc:	00007797          	auipc	a5,0x7
    80002500:	b2c7b783          	ld	a5,-1236(a5) # 80009028 <initproc>
    80002504:	0d050493          	addi	s1,a0,208
    80002508:	15050913          	addi	s2,a0,336
    8000250c:	02a79363          	bne	a5,a0,80002532 <exit+0x52>
    panic("init exiting");
    80002510:	00006517          	auipc	a0,0x6
    80002514:	d9050513          	addi	a0,a0,-624 # 800082a0 <digits+0x260>
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	026080e7          	jalr	38(ra) # 8000053e <panic>
      fileclose(f);
    80002520:	00002097          	auipc	ra,0x2
    80002524:	204080e7          	jalr	516(ra) # 80004724 <fileclose>
      p->ofile[fd] = 0;
    80002528:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000252c:	04a1                	addi	s1,s1,8
    8000252e:	01248563          	beq	s1,s2,80002538 <exit+0x58>
    if(p->ofile[fd]){
    80002532:	6088                	ld	a0,0(s1)
    80002534:	f575                	bnez	a0,80002520 <exit+0x40>
    80002536:	bfdd                	j	8000252c <exit+0x4c>
  begin_op();
    80002538:	00002097          	auipc	ra,0x2
    8000253c:	d20080e7          	jalr	-736(ra) # 80004258 <begin_op>
  iput(p->cwd);
    80002540:	1509b503          	ld	a0,336(s3)
    80002544:	00001097          	auipc	ra,0x1
    80002548:	4fc080e7          	jalr	1276(ra) # 80003a40 <iput>
  end_op();
    8000254c:	00002097          	auipc	ra,0x2
    80002550:	d8c080e7          	jalr	-628(ra) # 800042d8 <end_op>
  p->cwd = 0;
    80002554:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002558:	0000f497          	auipc	s1,0xf
    8000255c:	d6048493          	addi	s1,s1,-672 # 800112b8 <wait_lock>
    80002560:	8526                	mv	a0,s1
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	682080e7          	jalr	1666(ra) # 80000be4 <acquire>
  reparent(p);
    8000256a:	854e                	mv	a0,s3
    8000256c:	00000097          	auipc	ra,0x0
    80002570:	f1a080e7          	jalr	-230(ra) # 80002486 <reparent>
  wakeup(p->parent);
    80002574:	0389b503          	ld	a0,56(s3)
    80002578:	00000097          	auipc	ra,0x0
    8000257c:	e98080e7          	jalr	-360(ra) # 80002410 <wakeup>
  acquire(&p->lock);
    80002580:	854e                	mv	a0,s3
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	662080e7          	jalr	1634(ra) # 80000be4 <acquire>
  p->xstate = status;
    8000258a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000258e:	4795                	li	a5,5
    80002590:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002594:	8526                	mv	a0,s1
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	702080e7          	jalr	1794(ra) # 80000c98 <release>
  sched();
    8000259e:	00000097          	auipc	ra,0x0
    800025a2:	aec080e7          	jalr	-1300(ra) # 8000208a <sched>
  panic("zombie exit");
    800025a6:	00006517          	auipc	a0,0x6
    800025aa:	d0a50513          	addi	a0,a0,-758 # 800082b0 <digits+0x270>
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>

00000000800025b6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025b6:	7179                	addi	sp,sp,-48
    800025b8:	f406                	sd	ra,40(sp)
    800025ba:	f022                	sd	s0,32(sp)
    800025bc:	ec26                	sd	s1,24(sp)
    800025be:	e84a                	sd	s2,16(sp)
    800025c0:	e44e                	sd	s3,8(sp)
    800025c2:	1800                	addi	s0,sp,48
    800025c4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025c6:	0000f497          	auipc	s1,0xf
    800025ca:	10a48493          	addi	s1,s1,266 # 800116d0 <proc>
    800025ce:	00015997          	auipc	s3,0x15
    800025d2:	b0298993          	addi	s3,s3,-1278 # 800170d0 <tickslock>
    acquire(&p->lock);
    800025d6:	8526                	mv	a0,s1
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	60c080e7          	jalr	1548(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025e0:	589c                	lw	a5,48(s1)
    800025e2:	01278d63          	beq	a5,s2,800025fc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025e6:	8526                	mv	a0,s1
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	6b0080e7          	jalr	1712(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f0:	16848493          	addi	s1,s1,360
    800025f4:	ff3491e3          	bne	s1,s3,800025d6 <kill+0x20>
  }
  return -1;
    800025f8:	557d                	li	a0,-1
    800025fa:	a829                	j	80002614 <kill+0x5e>
      p->killed = 1;
    800025fc:	4785                	li	a5,1
    800025fe:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002600:	4c98                	lw	a4,24(s1)
    80002602:	4789                	li	a5,2
    80002604:	00f70f63          	beq	a4,a5,80002622 <kill+0x6c>
      release(&p->lock);
    80002608:	8526                	mv	a0,s1
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	68e080e7          	jalr	1678(ra) # 80000c98 <release>
      return 0;
    80002612:	4501                	li	a0,0
}
    80002614:	70a2                	ld	ra,40(sp)
    80002616:	7402                	ld	s0,32(sp)
    80002618:	64e2                	ld	s1,24(sp)
    8000261a:	6942                	ld	s2,16(sp)
    8000261c:	69a2                	ld	s3,8(sp)
    8000261e:	6145                	addi	sp,sp,48
    80002620:	8082                	ret
        p->state = RUNNABLE;
    80002622:	478d                	li	a5,3
    80002624:	cc9c                	sw	a5,24(s1)
    80002626:	b7cd                	j	80002608 <kill+0x52>

0000000080002628 <kill_system>:
kill_system(void){
    80002628:	7179                	addi	sp,sp,-48
    8000262a:	f406                	sd	ra,40(sp)
    8000262c:	f022                	sd	s0,32(sp)
    8000262e:	ec26                	sd	s1,24(sp)
    80002630:	e84a                	sd	s2,16(sp)
    80002632:	e44e                	sd	s3,8(sp)
    80002634:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++)
    80002636:	0000f497          	auipc	s1,0xf
    8000263a:	09a48493          	addi	s1,s1,154 # 800116d0 <proc>
    if(p != initproc && p->pid != 0) // init process and shell?
    8000263e:	00007997          	auipc	s3,0x7
    80002642:	9ea98993          	addi	s3,s3,-1558 # 80009028 <initproc>
  for(p = proc; p < &proc[NPROC]; p++)
    80002646:	00015917          	auipc	s2,0x15
    8000264a:	a8a90913          	addi	s2,s2,-1398 # 800170d0 <tickslock>
    8000264e:	a809                	j	80002660 <kill_system+0x38>
      kill(p->pid);
    80002650:	00000097          	auipc	ra,0x0
    80002654:	f66080e7          	jalr	-154(ra) # 800025b6 <kill>
  for(p = proc; p < &proc[NPROC]; p++)
    80002658:	16848493          	addi	s1,s1,360
    8000265c:	01248963          	beq	s1,s2,8000266e <kill_system+0x46>
    if(p != initproc && p->pid != 0) // init process and shell?
    80002660:	0009b783          	ld	a5,0(s3)
    80002664:	fe978ae3          	beq	a5,s1,80002658 <kill_system+0x30>
    80002668:	5888                	lw	a0,48(s1)
    8000266a:	d57d                	beqz	a0,80002658 <kill_system+0x30>
    8000266c:	b7d5                	j	80002650 <kill_system+0x28>
}
    8000266e:	4501                	li	a0,0
    80002670:	70a2                	ld	ra,40(sp)
    80002672:	7402                	ld	s0,32(sp)
    80002674:	64e2                	ld	s1,24(sp)
    80002676:	6942                	ld	s2,16(sp)
    80002678:	69a2                	ld	s3,8(sp)
    8000267a:	6145                	addi	sp,sp,48
    8000267c:	8082                	ret

000000008000267e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000267e:	7179                	addi	sp,sp,-48
    80002680:	f406                	sd	ra,40(sp)
    80002682:	f022                	sd	s0,32(sp)
    80002684:	ec26                	sd	s1,24(sp)
    80002686:	e84a                	sd	s2,16(sp)
    80002688:	e44e                	sd	s3,8(sp)
    8000268a:	e052                	sd	s4,0(sp)
    8000268c:	1800                	addi	s0,sp,48
    8000268e:	84aa                	mv	s1,a0
    80002690:	892e                	mv	s2,a1
    80002692:	89b2                	mv	s3,a2
    80002694:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002696:	fffff097          	auipc	ra,0xfffff
    8000269a:	44a080e7          	jalr	1098(ra) # 80001ae0 <myproc>
  if(user_dst){
    8000269e:	c08d                	beqz	s1,800026c0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026a0:	86d2                	mv	a3,s4
    800026a2:	864e                	mv	a2,s3
    800026a4:	85ca                	mv	a1,s2
    800026a6:	6928                	ld	a0,80(a0)
    800026a8:	fffff097          	auipc	ra,0xfffff
    800026ac:	0fa080e7          	jalr	250(ra) # 800017a2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026b0:	70a2                	ld	ra,40(sp)
    800026b2:	7402                	ld	s0,32(sp)
    800026b4:	64e2                	ld	s1,24(sp)
    800026b6:	6942                	ld	s2,16(sp)
    800026b8:	69a2                	ld	s3,8(sp)
    800026ba:	6a02                	ld	s4,0(sp)
    800026bc:	6145                	addi	sp,sp,48
    800026be:	8082                	ret
    memmove((char *)dst, src, len);
    800026c0:	000a061b          	sext.w	a2,s4
    800026c4:	85ce                	mv	a1,s3
    800026c6:	854a                	mv	a0,s2
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	678080e7          	jalr	1656(ra) # 80000d40 <memmove>
    return 0;
    800026d0:	8526                	mv	a0,s1
    800026d2:	bff9                	j	800026b0 <either_copyout+0x32>

00000000800026d4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026d4:	7179                	addi	sp,sp,-48
    800026d6:	f406                	sd	ra,40(sp)
    800026d8:	f022                	sd	s0,32(sp)
    800026da:	ec26                	sd	s1,24(sp)
    800026dc:	e84a                	sd	s2,16(sp)
    800026de:	e44e                	sd	s3,8(sp)
    800026e0:	e052                	sd	s4,0(sp)
    800026e2:	1800                	addi	s0,sp,48
    800026e4:	892a                	mv	s2,a0
    800026e6:	84ae                	mv	s1,a1
    800026e8:	89b2                	mv	s3,a2
    800026ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026ec:	fffff097          	auipc	ra,0xfffff
    800026f0:	3f4080e7          	jalr	1012(ra) # 80001ae0 <myproc>
  if(user_src){
    800026f4:	c08d                	beqz	s1,80002716 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026f6:	86d2                	mv	a3,s4
    800026f8:	864e                	mv	a2,s3
    800026fa:	85ca                	mv	a1,s2
    800026fc:	6928                	ld	a0,80(a0)
    800026fe:	fffff097          	auipc	ra,0xfffff
    80002702:	130080e7          	jalr	304(ra) # 8000182e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002706:	70a2                	ld	ra,40(sp)
    80002708:	7402                	ld	s0,32(sp)
    8000270a:	64e2                	ld	s1,24(sp)
    8000270c:	6942                	ld	s2,16(sp)
    8000270e:	69a2                	ld	s3,8(sp)
    80002710:	6a02                	ld	s4,0(sp)
    80002712:	6145                	addi	sp,sp,48
    80002714:	8082                	ret
    memmove(dst, (char*)src, len);
    80002716:	000a061b          	sext.w	a2,s4
    8000271a:	85ce                	mv	a1,s3
    8000271c:	854a                	mv	a0,s2
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	622080e7          	jalr	1570(ra) # 80000d40 <memmove>
    return 0;
    80002726:	8526                	mv	a0,s1
    80002728:	bff9                	j	80002706 <either_copyin+0x32>

000000008000272a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000272a:	715d                	addi	sp,sp,-80
    8000272c:	e486                	sd	ra,72(sp)
    8000272e:	e0a2                	sd	s0,64(sp)
    80002730:	fc26                	sd	s1,56(sp)
    80002732:	f84a                	sd	s2,48(sp)
    80002734:	f44e                	sd	s3,40(sp)
    80002736:	f052                	sd	s4,32(sp)
    80002738:	ec56                	sd	s5,24(sp)
    8000273a:	e85a                	sd	s6,16(sp)
    8000273c:	e45e                	sd	s7,8(sp)
    8000273e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002740:	00006517          	auipc	a0,0x6
    80002744:	9c850513          	addi	a0,a0,-1592 # 80008108 <digits+0xc8>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	e40080e7          	jalr	-448(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002750:	0000f497          	auipc	s1,0xf
    80002754:	0d848493          	addi	s1,s1,216 # 80011828 <proc+0x158>
    80002758:	00015917          	auipc	s2,0x15
    8000275c:	ad090913          	addi	s2,s2,-1328 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002760:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002762:	00006997          	auipc	s3,0x6
    80002766:	b5e98993          	addi	s3,s3,-1186 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    8000276a:	00006a97          	auipc	s5,0x6
    8000276e:	b5ea8a93          	addi	s5,s5,-1186 # 800082c8 <digits+0x288>
    printf("\n");
    80002772:	00006a17          	auipc	s4,0x6
    80002776:	996a0a13          	addi	s4,s4,-1642 # 80008108 <digits+0xc8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000277a:	00006b97          	auipc	s7,0x6
    8000277e:	b86b8b93          	addi	s7,s7,-1146 # 80008300 <states.1733>
    80002782:	a00d                	j	800027a4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002784:	ed86a583          	lw	a1,-296(a3)
    80002788:	8556                	mv	a0,s5
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	dfe080e7          	jalr	-514(ra) # 80000588 <printf>
    printf("\n");
    80002792:	8552                	mv	a0,s4
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	df4080e7          	jalr	-524(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000279c:	16848493          	addi	s1,s1,360
    800027a0:	03248163          	beq	s1,s2,800027c2 <procdump+0x98>
    if(p->state == UNUSED)
    800027a4:	86a6                	mv	a3,s1
    800027a6:	ec04a783          	lw	a5,-320(s1)
    800027aa:	dbed                	beqz	a5,8000279c <procdump+0x72>
      state = "???";
    800027ac:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ae:	fcfb6be3          	bltu	s6,a5,80002784 <procdump+0x5a>
    800027b2:	1782                	slli	a5,a5,0x20
    800027b4:	9381                	srli	a5,a5,0x20
    800027b6:	078e                	slli	a5,a5,0x3
    800027b8:	97de                	add	a5,a5,s7
    800027ba:	6390                	ld	a2,0(a5)
    800027bc:	f661                	bnez	a2,80002784 <procdump+0x5a>
      state = "???";
    800027be:	864e                	mv	a2,s3
    800027c0:	b7d1                	j	80002784 <procdump+0x5a>
  }
}
    800027c2:	60a6                	ld	ra,72(sp)
    800027c4:	6406                	ld	s0,64(sp)
    800027c6:	74e2                	ld	s1,56(sp)
    800027c8:	7942                	ld	s2,48(sp)
    800027ca:	79a2                	ld	s3,40(sp)
    800027cc:	7a02                	ld	s4,32(sp)
    800027ce:	6ae2                	ld	s5,24(sp)
    800027d0:	6b42                	ld	s6,16(sp)
    800027d2:	6ba2                	ld	s7,8(sp)
    800027d4:	6161                	addi	sp,sp,80
    800027d6:	8082                	ret

00000000800027d8 <swtch>:
    800027d8:	00153023          	sd	ra,0(a0)
    800027dc:	00253423          	sd	sp,8(a0)
    800027e0:	e900                	sd	s0,16(a0)
    800027e2:	ed04                	sd	s1,24(a0)
    800027e4:	03253023          	sd	s2,32(a0)
    800027e8:	03353423          	sd	s3,40(a0)
    800027ec:	03453823          	sd	s4,48(a0)
    800027f0:	03553c23          	sd	s5,56(a0)
    800027f4:	05653023          	sd	s6,64(a0)
    800027f8:	05753423          	sd	s7,72(a0)
    800027fc:	05853823          	sd	s8,80(a0)
    80002800:	05953c23          	sd	s9,88(a0)
    80002804:	07a53023          	sd	s10,96(a0)
    80002808:	07b53423          	sd	s11,104(a0)
    8000280c:	0005b083          	ld	ra,0(a1)
    80002810:	0085b103          	ld	sp,8(a1)
    80002814:	6980                	ld	s0,16(a1)
    80002816:	6d84                	ld	s1,24(a1)
    80002818:	0205b903          	ld	s2,32(a1)
    8000281c:	0285b983          	ld	s3,40(a1)
    80002820:	0305ba03          	ld	s4,48(a1)
    80002824:	0385ba83          	ld	s5,56(a1)
    80002828:	0405bb03          	ld	s6,64(a1)
    8000282c:	0485bb83          	ld	s7,72(a1)
    80002830:	0505bc03          	ld	s8,80(a1)
    80002834:	0585bc83          	ld	s9,88(a1)
    80002838:	0605bd03          	ld	s10,96(a1)
    8000283c:	0685bd83          	ld	s11,104(a1)
    80002840:	8082                	ret

0000000080002842 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002842:	1141                	addi	sp,sp,-16
    80002844:	e406                	sd	ra,8(sp)
    80002846:	e022                	sd	s0,0(sp)
    80002848:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000284a:	00006597          	auipc	a1,0x6
    8000284e:	ae658593          	addi	a1,a1,-1306 # 80008330 <states.1733+0x30>
    80002852:	00015517          	auipc	a0,0x15
    80002856:	87e50513          	addi	a0,a0,-1922 # 800170d0 <tickslock>
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	2fa080e7          	jalr	762(ra) # 80000b54 <initlock>
}
    80002862:	60a2                	ld	ra,8(sp)
    80002864:	6402                	ld	s0,0(sp)
    80002866:	0141                	addi	sp,sp,16
    80002868:	8082                	ret

000000008000286a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000286a:	1141                	addi	sp,sp,-16
    8000286c:	e422                	sd	s0,8(sp)
    8000286e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002870:	00003797          	auipc	a5,0x3
    80002874:	4d078793          	addi	a5,a5,1232 # 80005d40 <kernelvec>
    80002878:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000287c:	6422                	ld	s0,8(sp)
    8000287e:	0141                	addi	sp,sp,16
    80002880:	8082                	ret

0000000080002882 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002882:	1141                	addi	sp,sp,-16
    80002884:	e406                	sd	ra,8(sp)
    80002886:	e022                	sd	s0,0(sp)
    80002888:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	256080e7          	jalr	598(ra) # 80001ae0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002892:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002896:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002898:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000289c:	00004617          	auipc	a2,0x4
    800028a0:	76460613          	addi	a2,a2,1892 # 80007000 <_trampoline>
    800028a4:	00004697          	auipc	a3,0x4
    800028a8:	75c68693          	addi	a3,a3,1884 # 80007000 <_trampoline>
    800028ac:	8e91                	sub	a3,a3,a2
    800028ae:	040007b7          	lui	a5,0x4000
    800028b2:	17fd                	addi	a5,a5,-1
    800028b4:	07b2                	slli	a5,a5,0xc
    800028b6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028bc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028be:	180026f3          	csrr	a3,satp
    800028c2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028c4:	6d38                	ld	a4,88(a0)
    800028c6:	6134                	ld	a3,64(a0)
    800028c8:	6585                	lui	a1,0x1
    800028ca:	96ae                	add	a3,a3,a1
    800028cc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028ce:	6d38                	ld	a4,88(a0)
    800028d0:	00000697          	auipc	a3,0x0
    800028d4:	13868693          	addi	a3,a3,312 # 80002a08 <usertrap>
    800028d8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028da:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028dc:	8692                	mv	a3,tp
    800028de:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028e4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028e8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ec:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028f0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028f2:	6f18                	ld	a4,24(a4)
    800028f4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028f8:	692c                	ld	a1,80(a0)
    800028fa:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028fc:	00004717          	auipc	a4,0x4
    80002900:	79470713          	addi	a4,a4,1940 # 80007090 <userret>
    80002904:	8f11                	sub	a4,a4,a2
    80002906:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002908:	577d                	li	a4,-1
    8000290a:	177e                	slli	a4,a4,0x3f
    8000290c:	8dd9                	or	a1,a1,a4
    8000290e:	02000537          	lui	a0,0x2000
    80002912:	157d                	addi	a0,a0,-1
    80002914:	0536                	slli	a0,a0,0xd
    80002916:	9782                	jalr	a5
}
    80002918:	60a2                	ld	ra,8(sp)
    8000291a:	6402                	ld	s0,0(sp)
    8000291c:	0141                	addi	sp,sp,16
    8000291e:	8082                	ret

0000000080002920 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002920:	1101                	addi	sp,sp,-32
    80002922:	ec06                	sd	ra,24(sp)
    80002924:	e822                	sd	s0,16(sp)
    80002926:	e426                	sd	s1,8(sp)
    80002928:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000292a:	00014497          	auipc	s1,0x14
    8000292e:	7a648493          	addi	s1,s1,1958 # 800170d0 <tickslock>
    80002932:	8526                	mv	a0,s1
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	2b0080e7          	jalr	688(ra) # 80000be4 <acquire>
  ticks++;
    8000293c:	00006517          	auipc	a0,0x6
    80002940:	6f450513          	addi	a0,a0,1780 # 80009030 <ticks>
    80002944:	411c                	lw	a5,0(a0)
    80002946:	2785                	addiw	a5,a5,1
    80002948:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	ac6080e7          	jalr	-1338(ra) # 80002410 <wakeup>
  release(&tickslock);
    80002952:	8526                	mv	a0,s1
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	344080e7          	jalr	836(ra) # 80000c98 <release>
}
    8000295c:	60e2                	ld	ra,24(sp)
    8000295e:	6442                	ld	s0,16(sp)
    80002960:	64a2                	ld	s1,8(sp)
    80002962:	6105                	addi	sp,sp,32
    80002964:	8082                	ret

0000000080002966 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002966:	1101                	addi	sp,sp,-32
    80002968:	ec06                	sd	ra,24(sp)
    8000296a:	e822                	sd	s0,16(sp)
    8000296c:	e426                	sd	s1,8(sp)
    8000296e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002970:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002974:	00074d63          	bltz	a4,8000298e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002978:	57fd                	li	a5,-1
    8000297a:	17fe                	slli	a5,a5,0x3f
    8000297c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000297e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002980:	06f70363          	beq	a4,a5,800029e6 <devintr+0x80>
  }
}
    80002984:	60e2                	ld	ra,24(sp)
    80002986:	6442                	ld	s0,16(sp)
    80002988:	64a2                	ld	s1,8(sp)
    8000298a:	6105                	addi	sp,sp,32
    8000298c:	8082                	ret
     (scause & 0xff) == 9){
    8000298e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002992:	46a5                	li	a3,9
    80002994:	fed792e3          	bne	a5,a3,80002978 <devintr+0x12>
    int irq = plic_claim();
    80002998:	00003097          	auipc	ra,0x3
    8000299c:	4b0080e7          	jalr	1200(ra) # 80005e48 <plic_claim>
    800029a0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029a2:	47a9                	li	a5,10
    800029a4:	02f50763          	beq	a0,a5,800029d2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029a8:	4785                	li	a5,1
    800029aa:	02f50963          	beq	a0,a5,800029dc <devintr+0x76>
    return 1;
    800029ae:	4505                	li	a0,1
    } else if(irq){
    800029b0:	d8f1                	beqz	s1,80002984 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029b2:	85a6                	mv	a1,s1
    800029b4:	00006517          	auipc	a0,0x6
    800029b8:	98450513          	addi	a0,a0,-1660 # 80008338 <states.1733+0x38>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	bcc080e7          	jalr	-1076(ra) # 80000588 <printf>
      plic_complete(irq);
    800029c4:	8526                	mv	a0,s1
    800029c6:	00003097          	auipc	ra,0x3
    800029ca:	4a6080e7          	jalr	1190(ra) # 80005e6c <plic_complete>
    return 1;
    800029ce:	4505                	li	a0,1
    800029d0:	bf55                	j	80002984 <devintr+0x1e>
      uartintr();
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	fd6080e7          	jalr	-42(ra) # 800009a8 <uartintr>
    800029da:	b7ed                	j	800029c4 <devintr+0x5e>
      virtio_disk_intr();
    800029dc:	00004097          	auipc	ra,0x4
    800029e0:	970080e7          	jalr	-1680(ra) # 8000634c <virtio_disk_intr>
    800029e4:	b7c5                	j	800029c4 <devintr+0x5e>
    if(cpuid() == 0){
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	0ce080e7          	jalr	206(ra) # 80001ab4 <cpuid>
    800029ee:	c901                	beqz	a0,800029fe <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029f0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029f4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029f6:	14479073          	csrw	sip,a5
    return 2;
    800029fa:	4509                	li	a0,2
    800029fc:	b761                	j	80002984 <devintr+0x1e>
      clockintr();
    800029fe:	00000097          	auipc	ra,0x0
    80002a02:	f22080e7          	jalr	-222(ra) # 80002920 <clockintr>
    80002a06:	b7ed                	j	800029f0 <devintr+0x8a>

0000000080002a08 <usertrap>:
{
    80002a08:	1101                	addi	sp,sp,-32
    80002a0a:	ec06                	sd	ra,24(sp)
    80002a0c:	e822                	sd	s0,16(sp)
    80002a0e:	e426                	sd	s1,8(sp)
    80002a10:	e04a                	sd	s2,0(sp)
    80002a12:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a14:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a18:	1007f793          	andi	a5,a5,256
    80002a1c:	e3ad                	bnez	a5,80002a7e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a1e:	00003797          	auipc	a5,0x3
    80002a22:	32278793          	addi	a5,a5,802 # 80005d40 <kernelvec>
    80002a26:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a2a:	fffff097          	auipc	ra,0xfffff
    80002a2e:	0b6080e7          	jalr	182(ra) # 80001ae0 <myproc>
    80002a32:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a34:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a36:	14102773          	csrr	a4,sepc
    80002a3a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a40:	47a1                	li	a5,8
    80002a42:	04f71c63          	bne	a4,a5,80002a9a <usertrap+0x92>
    if(p->killed)
    80002a46:	551c                	lw	a5,40(a0)
    80002a48:	e3b9                	bnez	a5,80002a8e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a4a:	6cb8                	ld	a4,88(s1)
    80002a4c:	6f1c                	ld	a5,24(a4)
    80002a4e:	0791                	addi	a5,a5,4
    80002a50:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a5a:	10079073          	csrw	sstatus,a5
    syscall();
    80002a5e:	00000097          	auipc	ra,0x0
    80002a62:	2e0080e7          	jalr	736(ra) # 80002d3e <syscall>
  if(p->killed)
    80002a66:	549c                	lw	a5,40(s1)
    80002a68:	ebc1                	bnez	a5,80002af8 <usertrap+0xf0>
  usertrapret();
    80002a6a:	00000097          	auipc	ra,0x0
    80002a6e:	e18080e7          	jalr	-488(ra) # 80002882 <usertrapret>
}
    80002a72:	60e2                	ld	ra,24(sp)
    80002a74:	6442                	ld	s0,16(sp)
    80002a76:	64a2                	ld	s1,8(sp)
    80002a78:	6902                	ld	s2,0(sp)
    80002a7a:	6105                	addi	sp,sp,32
    80002a7c:	8082                	ret
    panic("usertrap: not from user mode");
    80002a7e:	00006517          	auipc	a0,0x6
    80002a82:	8da50513          	addi	a0,a0,-1830 # 80008358 <states.1733+0x58>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	ab8080e7          	jalr	-1352(ra) # 8000053e <panic>
      exit(-1);
    80002a8e:	557d                	li	a0,-1
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	a50080e7          	jalr	-1456(ra) # 800024e0 <exit>
    80002a98:	bf4d                	j	80002a4a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	ecc080e7          	jalr	-308(ra) # 80002966 <devintr>
    80002aa2:	892a                	mv	s2,a0
    80002aa4:	c501                	beqz	a0,80002aac <usertrap+0xa4>
  if(p->killed)
    80002aa6:	549c                	lw	a5,40(s1)
    80002aa8:	c3a1                	beqz	a5,80002ae8 <usertrap+0xe0>
    80002aaa:	a815                	j	80002ade <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aac:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ab0:	5890                	lw	a2,48(s1)
    80002ab2:	00006517          	auipc	a0,0x6
    80002ab6:	8c650513          	addi	a0,a0,-1850 # 80008378 <states.1733+0x78>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	ace080e7          	jalr	-1330(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ac6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aca:	00006517          	auipc	a0,0x6
    80002ace:	8de50513          	addi	a0,a0,-1826 # 800083a8 <states.1733+0xa8>
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	ab6080e7          	jalr	-1354(ra) # 80000588 <printf>
    p->killed = 1;
    80002ada:	4785                	li	a5,1
    80002adc:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ade:	557d                	li	a0,-1
    80002ae0:	00000097          	auipc	ra,0x0
    80002ae4:	a00080e7          	jalr	-1536(ra) # 800024e0 <exit>
  if(which_dev == 2)
    80002ae8:	4789                	li	a5,2
    80002aea:	f8f910e3          	bne	s2,a5,80002a6a <usertrap+0x62>
    yield();
    80002aee:	fffff097          	auipc	ra,0xfffff
    80002af2:	672080e7          	jalr	1650(ra) # 80002160 <yield>
    80002af6:	bf95                	j	80002a6a <usertrap+0x62>
  int which_dev = 0;
    80002af8:	4901                	li	s2,0
    80002afa:	b7d5                	j	80002ade <usertrap+0xd6>

0000000080002afc <kerneltrap>:
{
    80002afc:	7179                	addi	sp,sp,-48
    80002afe:	f406                	sd	ra,40(sp)
    80002b00:	f022                	sd	s0,32(sp)
    80002b02:	ec26                	sd	s1,24(sp)
    80002b04:	e84a                	sd	s2,16(sp)
    80002b06:	e44e                	sd	s3,8(sp)
    80002b08:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b0a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b0e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b12:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b16:	1004f793          	andi	a5,s1,256
    80002b1a:	cb85                	beqz	a5,80002b4a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b20:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b22:	ef85                	bnez	a5,80002b5a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b24:	00000097          	auipc	ra,0x0
    80002b28:	e42080e7          	jalr	-446(ra) # 80002966 <devintr>
    80002b2c:	cd1d                	beqz	a0,80002b6a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b2e:	4789                	li	a5,2
    80002b30:	06f50a63          	beq	a0,a5,80002ba4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b34:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b38:	10049073          	csrw	sstatus,s1
}
    80002b3c:	70a2                	ld	ra,40(sp)
    80002b3e:	7402                	ld	s0,32(sp)
    80002b40:	64e2                	ld	s1,24(sp)
    80002b42:	6942                	ld	s2,16(sp)
    80002b44:	69a2                	ld	s3,8(sp)
    80002b46:	6145                	addi	sp,sp,48
    80002b48:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b4a:	00006517          	auipc	a0,0x6
    80002b4e:	87e50513          	addi	a0,a0,-1922 # 800083c8 <states.1733+0xc8>
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	9ec080e7          	jalr	-1556(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	89650513          	addi	a0,a0,-1898 # 800083f0 <states.1733+0xf0>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	9dc080e7          	jalr	-1572(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b6a:	85ce                	mv	a1,s3
    80002b6c:	00006517          	auipc	a0,0x6
    80002b70:	8a450513          	addi	a0,a0,-1884 # 80008410 <states.1733+0x110>
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	a14080e7          	jalr	-1516(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b7c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b80:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b84:	00006517          	auipc	a0,0x6
    80002b88:	89c50513          	addi	a0,a0,-1892 # 80008420 <states.1733+0x120>
    80002b8c:	ffffe097          	auipc	ra,0xffffe
    80002b90:	9fc080e7          	jalr	-1540(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b94:	00006517          	auipc	a0,0x6
    80002b98:	8a450513          	addi	a0,a0,-1884 # 80008438 <states.1733+0x138>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	9a2080e7          	jalr	-1630(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	f3c080e7          	jalr	-196(ra) # 80001ae0 <myproc>
    80002bac:	d541                	beqz	a0,80002b34 <kerneltrap+0x38>
    80002bae:	fffff097          	auipc	ra,0xfffff
    80002bb2:	f32080e7          	jalr	-206(ra) # 80001ae0 <myproc>
    80002bb6:	4d18                	lw	a4,24(a0)
    80002bb8:	4791                	li	a5,4
    80002bba:	f6f71de3          	bne	a4,a5,80002b34 <kerneltrap+0x38>
    yield();
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	5a2080e7          	jalr	1442(ra) # 80002160 <yield>
    80002bc6:	b7bd                	j	80002b34 <kerneltrap+0x38>

0000000080002bc8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bc8:	1101                	addi	sp,sp,-32
    80002bca:	ec06                	sd	ra,24(sp)
    80002bcc:	e822                	sd	s0,16(sp)
    80002bce:	e426                	sd	s1,8(sp)
    80002bd0:	1000                	addi	s0,sp,32
    80002bd2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	f0c080e7          	jalr	-244(ra) # 80001ae0 <myproc>
  switch (n) {
    80002bdc:	4795                	li	a5,5
    80002bde:	0497e163          	bltu	a5,s1,80002c20 <argraw+0x58>
    80002be2:	048a                	slli	s1,s1,0x2
    80002be4:	00006717          	auipc	a4,0x6
    80002be8:	88c70713          	addi	a4,a4,-1908 # 80008470 <states.1733+0x170>
    80002bec:	94ba                	add	s1,s1,a4
    80002bee:	409c                	lw	a5,0(s1)
    80002bf0:	97ba                	add	a5,a5,a4
    80002bf2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bf4:	6d3c                	ld	a5,88(a0)
    80002bf6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bf8:	60e2                	ld	ra,24(sp)
    80002bfa:	6442                	ld	s0,16(sp)
    80002bfc:	64a2                	ld	s1,8(sp)
    80002bfe:	6105                	addi	sp,sp,32
    80002c00:	8082                	ret
    return p->trapframe->a1;
    80002c02:	6d3c                	ld	a5,88(a0)
    80002c04:	7fa8                	ld	a0,120(a5)
    80002c06:	bfcd                	j	80002bf8 <argraw+0x30>
    return p->trapframe->a2;
    80002c08:	6d3c                	ld	a5,88(a0)
    80002c0a:	63c8                	ld	a0,128(a5)
    80002c0c:	b7f5                	j	80002bf8 <argraw+0x30>
    return p->trapframe->a3;
    80002c0e:	6d3c                	ld	a5,88(a0)
    80002c10:	67c8                	ld	a0,136(a5)
    80002c12:	b7dd                	j	80002bf8 <argraw+0x30>
    return p->trapframe->a4;
    80002c14:	6d3c                	ld	a5,88(a0)
    80002c16:	6bc8                	ld	a0,144(a5)
    80002c18:	b7c5                	j	80002bf8 <argraw+0x30>
    return p->trapframe->a5;
    80002c1a:	6d3c                	ld	a5,88(a0)
    80002c1c:	6fc8                	ld	a0,152(a5)
    80002c1e:	bfe9                	j	80002bf8 <argraw+0x30>
  panic("argraw");
    80002c20:	00006517          	auipc	a0,0x6
    80002c24:	82850513          	addi	a0,a0,-2008 # 80008448 <states.1733+0x148>
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	916080e7          	jalr	-1770(ra) # 8000053e <panic>

0000000080002c30 <fetchaddr>:
{
    80002c30:	1101                	addi	sp,sp,-32
    80002c32:	ec06                	sd	ra,24(sp)
    80002c34:	e822                	sd	s0,16(sp)
    80002c36:	e426                	sd	s1,8(sp)
    80002c38:	e04a                	sd	s2,0(sp)
    80002c3a:	1000                	addi	s0,sp,32
    80002c3c:	84aa                	mv	s1,a0
    80002c3e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	ea0080e7          	jalr	-352(ra) # 80001ae0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c48:	653c                	ld	a5,72(a0)
    80002c4a:	02f4f863          	bgeu	s1,a5,80002c7a <fetchaddr+0x4a>
    80002c4e:	00848713          	addi	a4,s1,8
    80002c52:	02e7e663          	bltu	a5,a4,80002c7e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c56:	46a1                	li	a3,8
    80002c58:	8626                	mv	a2,s1
    80002c5a:	85ca                	mv	a1,s2
    80002c5c:	6928                	ld	a0,80(a0)
    80002c5e:	fffff097          	auipc	ra,0xfffff
    80002c62:	bd0080e7          	jalr	-1072(ra) # 8000182e <copyin>
    80002c66:	00a03533          	snez	a0,a0
    80002c6a:	40a00533          	neg	a0,a0
}
    80002c6e:	60e2                	ld	ra,24(sp)
    80002c70:	6442                	ld	s0,16(sp)
    80002c72:	64a2                	ld	s1,8(sp)
    80002c74:	6902                	ld	s2,0(sp)
    80002c76:	6105                	addi	sp,sp,32
    80002c78:	8082                	ret
    return -1;
    80002c7a:	557d                	li	a0,-1
    80002c7c:	bfcd                	j	80002c6e <fetchaddr+0x3e>
    80002c7e:	557d                	li	a0,-1
    80002c80:	b7fd                	j	80002c6e <fetchaddr+0x3e>

0000000080002c82 <fetchstr>:
{
    80002c82:	7179                	addi	sp,sp,-48
    80002c84:	f406                	sd	ra,40(sp)
    80002c86:	f022                	sd	s0,32(sp)
    80002c88:	ec26                	sd	s1,24(sp)
    80002c8a:	e84a                	sd	s2,16(sp)
    80002c8c:	e44e                	sd	s3,8(sp)
    80002c8e:	1800                	addi	s0,sp,48
    80002c90:	892a                	mv	s2,a0
    80002c92:	84ae                	mv	s1,a1
    80002c94:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	e4a080e7          	jalr	-438(ra) # 80001ae0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c9e:	86ce                	mv	a3,s3
    80002ca0:	864a                	mv	a2,s2
    80002ca2:	85a6                	mv	a1,s1
    80002ca4:	6928                	ld	a0,80(a0)
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	c14080e7          	jalr	-1004(ra) # 800018ba <copyinstr>
  if(err < 0)
    80002cae:	00054763          	bltz	a0,80002cbc <fetchstr+0x3a>
  return strlen(buf);
    80002cb2:	8526                	mv	a0,s1
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	1b0080e7          	jalr	432(ra) # 80000e64 <strlen>
}
    80002cbc:	70a2                	ld	ra,40(sp)
    80002cbe:	7402                	ld	s0,32(sp)
    80002cc0:	64e2                	ld	s1,24(sp)
    80002cc2:	6942                	ld	s2,16(sp)
    80002cc4:	69a2                	ld	s3,8(sp)
    80002cc6:	6145                	addi	sp,sp,48
    80002cc8:	8082                	ret

0000000080002cca <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cca:	1101                	addi	sp,sp,-32
    80002ccc:	ec06                	sd	ra,24(sp)
    80002cce:	e822                	sd	s0,16(sp)
    80002cd0:	e426                	sd	s1,8(sp)
    80002cd2:	1000                	addi	s0,sp,32
    80002cd4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	ef2080e7          	jalr	-270(ra) # 80002bc8 <argraw>
    80002cde:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ce0:	4501                	li	a0,0
    80002ce2:	60e2                	ld	ra,24(sp)
    80002ce4:	6442                	ld	s0,16(sp)
    80002ce6:	64a2                	ld	s1,8(sp)
    80002ce8:	6105                	addi	sp,sp,32
    80002cea:	8082                	ret

0000000080002cec <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cec:	1101                	addi	sp,sp,-32
    80002cee:	ec06                	sd	ra,24(sp)
    80002cf0:	e822                	sd	s0,16(sp)
    80002cf2:	e426                	sd	s1,8(sp)
    80002cf4:	1000                	addi	s0,sp,32
    80002cf6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cf8:	00000097          	auipc	ra,0x0
    80002cfc:	ed0080e7          	jalr	-304(ra) # 80002bc8 <argraw>
    80002d00:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d02:	4501                	li	a0,0
    80002d04:	60e2                	ld	ra,24(sp)
    80002d06:	6442                	ld	s0,16(sp)
    80002d08:	64a2                	ld	s1,8(sp)
    80002d0a:	6105                	addi	sp,sp,32
    80002d0c:	8082                	ret

0000000080002d0e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d0e:	1101                	addi	sp,sp,-32
    80002d10:	ec06                	sd	ra,24(sp)
    80002d12:	e822                	sd	s0,16(sp)
    80002d14:	e426                	sd	s1,8(sp)
    80002d16:	e04a                	sd	s2,0(sp)
    80002d18:	1000                	addi	s0,sp,32
    80002d1a:	84ae                	mv	s1,a1
    80002d1c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d1e:	00000097          	auipc	ra,0x0
    80002d22:	eaa080e7          	jalr	-342(ra) # 80002bc8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d26:	864a                	mv	a2,s2
    80002d28:	85a6                	mv	a1,s1
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	f58080e7          	jalr	-168(ra) # 80002c82 <fetchstr>
}
    80002d32:	60e2                	ld	ra,24(sp)
    80002d34:	6442                	ld	s0,16(sp)
    80002d36:	64a2                	ld	s1,8(sp)
    80002d38:	6902                	ld	s2,0(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <syscall>:
[SYS_killsystem]   sys_killsystem
};

void
syscall(void)
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	e04a                	sd	s2,0(sp)
    80002d48:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	d96080e7          	jalr	-618(ra) # 80001ae0 <myproc>
    80002d52:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d54:	05853903          	ld	s2,88(a0)
    80002d58:	0a893783          	ld	a5,168(s2)
    80002d5c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d60:	37fd                	addiw	a5,a5,-1
    80002d62:	4759                	li	a4,22
    80002d64:	00f76f63          	bltu	a4,a5,80002d82 <syscall+0x44>
    80002d68:	00369713          	slli	a4,a3,0x3
    80002d6c:	00005797          	auipc	a5,0x5
    80002d70:	71c78793          	addi	a5,a5,1820 # 80008488 <syscalls>
    80002d74:	97ba                	add	a5,a5,a4
    80002d76:	639c                	ld	a5,0(a5)
    80002d78:	c789                	beqz	a5,80002d82 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d7a:	9782                	jalr	a5
    80002d7c:	06a93823          	sd	a0,112(s2)
    80002d80:	a839                	j	80002d9e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d82:	15848613          	addi	a2,s1,344
    80002d86:	588c                	lw	a1,48(s1)
    80002d88:	00005517          	auipc	a0,0x5
    80002d8c:	6c850513          	addi	a0,a0,1736 # 80008450 <states.1733+0x150>
    80002d90:	ffffd097          	auipc	ra,0xffffd
    80002d94:	7f8080e7          	jalr	2040(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d98:	6cbc                	ld	a5,88(s1)
    80002d9a:	577d                	li	a4,-1
    80002d9c:	fbb8                	sd	a4,112(a5)
  }
}
    80002d9e:	60e2                	ld	ra,24(sp)
    80002da0:	6442                	ld	s0,16(sp)
    80002da2:	64a2                	ld	s1,8(sp)
    80002da4:	6902                	ld	s2,0(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret

0000000080002daa <sys_pause>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_pause(void)
{
    80002daa:	1101                	addi	sp,sp,-32
    80002dac:	ec06                	sd	ra,24(sp)
    80002dae:	e822                	sd	s0,16(sp)
    80002db0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002db2:	fec40593          	addi	a1,s0,-20
    80002db6:	4501                	li	a0,0
    80002db8:	00000097          	auipc	ra,0x0
    80002dbc:	f12080e7          	jalr	-238(ra) # 80002cca <argint>
    80002dc0:	87aa                	mv	a5,a0
    return -1;
    80002dc2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002dc4:	0007c863          	bltz	a5,80002dd4 <sys_pause+0x2a>
  
  return pause_system(n);
    80002dc8:	fec42503          	lw	a0,-20(s0)
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	434080e7          	jalr	1076(ra) # 80002200 <pause_system>
}
    80002dd4:	60e2                	ld	ra,24(sp)
    80002dd6:	6442                	ld	s0,16(sp)
    80002dd8:	6105                	addi	sp,sp,32
    80002dda:	8082                	ret

0000000080002ddc <sys_killsystem>:

uint64
sys_killsystem(void)
{
    80002ddc:	1141                	addi	sp,sp,-16
    80002dde:	e406                	sd	ra,8(sp)
    80002de0:	e022                	sd	s0,0(sp)
    80002de2:	0800                	addi	s0,sp,16
  return kill_system();
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	844080e7          	jalr	-1980(ra) # 80002628 <kill_system>
}
    80002dec:	60a2                	ld	ra,8(sp)
    80002dee:	6402                	ld	s0,0(sp)
    80002df0:	0141                	addi	sp,sp,16
    80002df2:	8082                	ret

0000000080002df4 <sys_exit>:


uint64
sys_exit(void)
{
    80002df4:	1101                	addi	sp,sp,-32
    80002df6:	ec06                	sd	ra,24(sp)
    80002df8:	e822                	sd	s0,16(sp)
    80002dfa:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dfc:	fec40593          	addi	a1,s0,-20
    80002e00:	4501                	li	a0,0
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	ec8080e7          	jalr	-312(ra) # 80002cca <argint>
    return -1;
    80002e0a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e0c:	00054963          	bltz	a0,80002e1e <sys_exit+0x2a>
  exit(n);
    80002e10:	fec42503          	lw	a0,-20(s0)
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	6cc080e7          	jalr	1740(ra) # 800024e0 <exit>
  return 0;  // not reached
    80002e1c:	4781                	li	a5,0
}
    80002e1e:	853e                	mv	a0,a5
    80002e20:	60e2                	ld	ra,24(sp)
    80002e22:	6442                	ld	s0,16(sp)
    80002e24:	6105                	addi	sp,sp,32
    80002e26:	8082                	ret

0000000080002e28 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e28:	1141                	addi	sp,sp,-16
    80002e2a:	e406                	sd	ra,8(sp)
    80002e2c:	e022                	sd	s0,0(sp)
    80002e2e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	cb0080e7          	jalr	-848(ra) # 80001ae0 <myproc>
}
    80002e38:	5908                	lw	a0,48(a0)
    80002e3a:	60a2                	ld	ra,8(sp)
    80002e3c:	6402                	ld	s0,0(sp)
    80002e3e:	0141                	addi	sp,sp,16
    80002e40:	8082                	ret

0000000080002e42 <sys_fork>:

uint64
sys_fork(void)
{
    80002e42:	1141                	addi	sp,sp,-16
    80002e44:	e406                	sd	ra,8(sp)
    80002e46:	e022                	sd	s0,0(sp)
    80002e48:	0800                	addi	s0,sp,16
  return fork();
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	064080e7          	jalr	100(ra) # 80001eae <fork>
}
    80002e52:	60a2                	ld	ra,8(sp)
    80002e54:	6402                	ld	s0,0(sp)
    80002e56:	0141                	addi	sp,sp,16
    80002e58:	8082                	ret

0000000080002e5a <sys_wait>:

uint64
sys_wait(void)
{
    80002e5a:	1101                	addi	sp,sp,-32
    80002e5c:	ec06                	sd	ra,24(sp)
    80002e5e:	e822                	sd	s0,16(sp)
    80002e60:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e62:	fe840593          	addi	a1,s0,-24
    80002e66:	4501                	li	a0,0
    80002e68:	00000097          	auipc	ra,0x0
    80002e6c:	e84080e7          	jalr	-380(ra) # 80002cec <argaddr>
    80002e70:	87aa                	mv	a5,a0
    return -1;
    80002e72:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e74:	0007c863          	bltz	a5,80002e84 <sys_wait+0x2a>
  return wait(p);
    80002e78:	fe843503          	ld	a0,-24(s0)
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	46c080e7          	jalr	1132(ra) # 800022e8 <wait>
}
    80002e84:	60e2                	ld	ra,24(sp)
    80002e86:	6442                	ld	s0,16(sp)
    80002e88:	6105                	addi	sp,sp,32
    80002e8a:	8082                	ret

0000000080002e8c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e8c:	7179                	addi	sp,sp,-48
    80002e8e:	f406                	sd	ra,40(sp)
    80002e90:	f022                	sd	s0,32(sp)
    80002e92:	ec26                	sd	s1,24(sp)
    80002e94:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e96:	fdc40593          	addi	a1,s0,-36
    80002e9a:	4501                	li	a0,0
    80002e9c:	00000097          	auipc	ra,0x0
    80002ea0:	e2e080e7          	jalr	-466(ra) # 80002cca <argint>
    80002ea4:	87aa                	mv	a5,a0
    return -1;
    80002ea6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ea8:	0207c063          	bltz	a5,80002ec8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	c34080e7          	jalr	-972(ra) # 80001ae0 <myproc>
    80002eb4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002eb6:	fdc42503          	lw	a0,-36(s0)
    80002eba:	fffff097          	auipc	ra,0xfffff
    80002ebe:	f80080e7          	jalr	-128(ra) # 80001e3a <growproc>
    80002ec2:	00054863          	bltz	a0,80002ed2 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ec6:	8526                	mv	a0,s1
}
    80002ec8:	70a2                	ld	ra,40(sp)
    80002eca:	7402                	ld	s0,32(sp)
    80002ecc:	64e2                	ld	s1,24(sp)
    80002ece:	6145                	addi	sp,sp,48
    80002ed0:	8082                	ret
    return -1;
    80002ed2:	557d                	li	a0,-1
    80002ed4:	bfd5                	j	80002ec8 <sys_sbrk+0x3c>

0000000080002ed6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ed6:	7139                	addi	sp,sp,-64
    80002ed8:	fc06                	sd	ra,56(sp)
    80002eda:	f822                	sd	s0,48(sp)
    80002edc:	f426                	sd	s1,40(sp)
    80002ede:	f04a                	sd	s2,32(sp)
    80002ee0:	ec4e                	sd	s3,24(sp)
    80002ee2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ee4:	fcc40593          	addi	a1,s0,-52
    80002ee8:	4501                	li	a0,0
    80002eea:	00000097          	auipc	ra,0x0
    80002eee:	de0080e7          	jalr	-544(ra) # 80002cca <argint>
    return -1;
    80002ef2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ef4:	06054563          	bltz	a0,80002f5e <sys_sleep+0x88>
  acquire(&tickslock);
    80002ef8:	00014517          	auipc	a0,0x14
    80002efc:	1d850513          	addi	a0,a0,472 # 800170d0 <tickslock>
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	ce4080e7          	jalr	-796(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f08:	00006917          	auipc	s2,0x6
    80002f0c:	12892903          	lw	s2,296(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f10:	fcc42783          	lw	a5,-52(s0)
    80002f14:	cf85                	beqz	a5,80002f4c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f16:	00014997          	auipc	s3,0x14
    80002f1a:	1ba98993          	addi	s3,s3,442 # 800170d0 <tickslock>
    80002f1e:	00006497          	auipc	s1,0x6
    80002f22:	11248493          	addi	s1,s1,274 # 80009030 <ticks>
    if(myproc()->killed){
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	bba080e7          	jalr	-1094(ra) # 80001ae0 <myproc>
    80002f2e:	551c                	lw	a5,40(a0)
    80002f30:	ef9d                	bnez	a5,80002f6e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f32:	85ce                	mv	a1,s3
    80002f34:	8526                	mv	a0,s1
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	266080e7          	jalr	614(ra) # 8000219c <sleep>
  while(ticks - ticks0 < n){
    80002f3e:	409c                	lw	a5,0(s1)
    80002f40:	412787bb          	subw	a5,a5,s2
    80002f44:	fcc42703          	lw	a4,-52(s0)
    80002f48:	fce7efe3          	bltu	a5,a4,80002f26 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f4c:	00014517          	auipc	a0,0x14
    80002f50:	18450513          	addi	a0,a0,388 # 800170d0 <tickslock>
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	d44080e7          	jalr	-700(ra) # 80000c98 <release>
  return 0;
    80002f5c:	4781                	li	a5,0
}
    80002f5e:	853e                	mv	a0,a5
    80002f60:	70e2                	ld	ra,56(sp)
    80002f62:	7442                	ld	s0,48(sp)
    80002f64:	74a2                	ld	s1,40(sp)
    80002f66:	7902                	ld	s2,32(sp)
    80002f68:	69e2                	ld	s3,24(sp)
    80002f6a:	6121                	addi	sp,sp,64
    80002f6c:	8082                	ret
      release(&tickslock);
    80002f6e:	00014517          	auipc	a0,0x14
    80002f72:	16250513          	addi	a0,a0,354 # 800170d0 <tickslock>
    80002f76:	ffffe097          	auipc	ra,0xffffe
    80002f7a:	d22080e7          	jalr	-734(ra) # 80000c98 <release>
      return -1;
    80002f7e:	57fd                	li	a5,-1
    80002f80:	bff9                	j	80002f5e <sys_sleep+0x88>

0000000080002f82 <sys_kill>:

uint64
sys_kill(void)
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f8a:	fec40593          	addi	a1,s0,-20
    80002f8e:	4501                	li	a0,0
    80002f90:	00000097          	auipc	ra,0x0
    80002f94:	d3a080e7          	jalr	-710(ra) # 80002cca <argint>
    80002f98:	87aa                	mv	a5,a0
    return -1;
    80002f9a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f9c:	0007c863          	bltz	a5,80002fac <sys_kill+0x2a>
  return kill(pid);
    80002fa0:	fec42503          	lw	a0,-20(s0)
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	612080e7          	jalr	1554(ra) # 800025b6 <kill>
}
    80002fac:	60e2                	ld	ra,24(sp)
    80002fae:	6442                	ld	s0,16(sp)
    80002fb0:	6105                	addi	sp,sp,32
    80002fb2:	8082                	ret

0000000080002fb4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fb4:	1101                	addi	sp,sp,-32
    80002fb6:	ec06                	sd	ra,24(sp)
    80002fb8:	e822                	sd	s0,16(sp)
    80002fba:	e426                	sd	s1,8(sp)
    80002fbc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fbe:	00014517          	auipc	a0,0x14
    80002fc2:	11250513          	addi	a0,a0,274 # 800170d0 <tickslock>
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	c1e080e7          	jalr	-994(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002fce:	00006497          	auipc	s1,0x6
    80002fd2:	0624a483          	lw	s1,98(s1) # 80009030 <ticks>
  release(&tickslock);
    80002fd6:	00014517          	auipc	a0,0x14
    80002fda:	0fa50513          	addi	a0,a0,250 # 800170d0 <tickslock>
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	cba080e7          	jalr	-838(ra) # 80000c98 <release>
  return xticks;
}
    80002fe6:	02049513          	slli	a0,s1,0x20
    80002fea:	9101                	srli	a0,a0,0x20
    80002fec:	60e2                	ld	ra,24(sp)
    80002fee:	6442                	ld	s0,16(sp)
    80002ff0:	64a2                	ld	s1,8(sp)
    80002ff2:	6105                	addi	sp,sp,32
    80002ff4:	8082                	ret

0000000080002ff6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ff6:	7179                	addi	sp,sp,-48
    80002ff8:	f406                	sd	ra,40(sp)
    80002ffa:	f022                	sd	s0,32(sp)
    80002ffc:	ec26                	sd	s1,24(sp)
    80002ffe:	e84a                	sd	s2,16(sp)
    80003000:	e44e                	sd	s3,8(sp)
    80003002:	e052                	sd	s4,0(sp)
    80003004:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003006:	00005597          	auipc	a1,0x5
    8000300a:	54258593          	addi	a1,a1,1346 # 80008548 <syscalls+0xc0>
    8000300e:	00014517          	auipc	a0,0x14
    80003012:	0da50513          	addi	a0,a0,218 # 800170e8 <bcache>
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	b3e080e7          	jalr	-1218(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000301e:	0001c797          	auipc	a5,0x1c
    80003022:	0ca78793          	addi	a5,a5,202 # 8001f0e8 <bcache+0x8000>
    80003026:	0001c717          	auipc	a4,0x1c
    8000302a:	32a70713          	addi	a4,a4,810 # 8001f350 <bcache+0x8268>
    8000302e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003032:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003036:	00014497          	auipc	s1,0x14
    8000303a:	0ca48493          	addi	s1,s1,202 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    8000303e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003040:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003042:	00005a17          	auipc	s4,0x5
    80003046:	50ea0a13          	addi	s4,s4,1294 # 80008550 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000304a:	2b893783          	ld	a5,696(s2)
    8000304e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003050:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003054:	85d2                	mv	a1,s4
    80003056:	01048513          	addi	a0,s1,16
    8000305a:	00001097          	auipc	ra,0x1
    8000305e:	4bc080e7          	jalr	1212(ra) # 80004516 <initsleeplock>
    bcache.head.next->prev = b;
    80003062:	2b893783          	ld	a5,696(s2)
    80003066:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003068:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000306c:	45848493          	addi	s1,s1,1112
    80003070:	fd349de3          	bne	s1,s3,8000304a <binit+0x54>
  }
}
    80003074:	70a2                	ld	ra,40(sp)
    80003076:	7402                	ld	s0,32(sp)
    80003078:	64e2                	ld	s1,24(sp)
    8000307a:	6942                	ld	s2,16(sp)
    8000307c:	69a2                	ld	s3,8(sp)
    8000307e:	6a02                	ld	s4,0(sp)
    80003080:	6145                	addi	sp,sp,48
    80003082:	8082                	ret

0000000080003084 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003084:	7179                	addi	sp,sp,-48
    80003086:	f406                	sd	ra,40(sp)
    80003088:	f022                	sd	s0,32(sp)
    8000308a:	ec26                	sd	s1,24(sp)
    8000308c:	e84a                	sd	s2,16(sp)
    8000308e:	e44e                	sd	s3,8(sp)
    80003090:	1800                	addi	s0,sp,48
    80003092:	89aa                	mv	s3,a0
    80003094:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003096:	00014517          	auipc	a0,0x14
    8000309a:	05250513          	addi	a0,a0,82 # 800170e8 <bcache>
    8000309e:	ffffe097          	auipc	ra,0xffffe
    800030a2:	b46080e7          	jalr	-1210(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030a6:	0001c497          	auipc	s1,0x1c
    800030aa:	2fa4b483          	ld	s1,762(s1) # 8001f3a0 <bcache+0x82b8>
    800030ae:	0001c797          	auipc	a5,0x1c
    800030b2:	2a278793          	addi	a5,a5,674 # 8001f350 <bcache+0x8268>
    800030b6:	02f48f63          	beq	s1,a5,800030f4 <bread+0x70>
    800030ba:	873e                	mv	a4,a5
    800030bc:	a021                	j	800030c4 <bread+0x40>
    800030be:	68a4                	ld	s1,80(s1)
    800030c0:	02e48a63          	beq	s1,a4,800030f4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030c4:	449c                	lw	a5,8(s1)
    800030c6:	ff379ce3          	bne	a5,s3,800030be <bread+0x3a>
    800030ca:	44dc                	lw	a5,12(s1)
    800030cc:	ff2799e3          	bne	a5,s2,800030be <bread+0x3a>
      b->refcnt++;
    800030d0:	40bc                	lw	a5,64(s1)
    800030d2:	2785                	addiw	a5,a5,1
    800030d4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030d6:	00014517          	auipc	a0,0x14
    800030da:	01250513          	addi	a0,a0,18 # 800170e8 <bcache>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	bba080e7          	jalr	-1094(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030e6:	01048513          	addi	a0,s1,16
    800030ea:	00001097          	auipc	ra,0x1
    800030ee:	466080e7          	jalr	1126(ra) # 80004550 <acquiresleep>
      return b;
    800030f2:	a8b9                	j	80003150 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030f4:	0001c497          	auipc	s1,0x1c
    800030f8:	2a44b483          	ld	s1,676(s1) # 8001f398 <bcache+0x82b0>
    800030fc:	0001c797          	auipc	a5,0x1c
    80003100:	25478793          	addi	a5,a5,596 # 8001f350 <bcache+0x8268>
    80003104:	00f48863          	beq	s1,a5,80003114 <bread+0x90>
    80003108:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000310a:	40bc                	lw	a5,64(s1)
    8000310c:	cf81                	beqz	a5,80003124 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000310e:	64a4                	ld	s1,72(s1)
    80003110:	fee49de3          	bne	s1,a4,8000310a <bread+0x86>
  panic("bget: no buffers");
    80003114:	00005517          	auipc	a0,0x5
    80003118:	44450513          	addi	a0,a0,1092 # 80008558 <syscalls+0xd0>
    8000311c:	ffffd097          	auipc	ra,0xffffd
    80003120:	422080e7          	jalr	1058(ra) # 8000053e <panic>
      b->dev = dev;
    80003124:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003128:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000312c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003130:	4785                	li	a5,1
    80003132:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003134:	00014517          	auipc	a0,0x14
    80003138:	fb450513          	addi	a0,a0,-76 # 800170e8 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	b5c080e7          	jalr	-1188(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003144:	01048513          	addi	a0,s1,16
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	408080e7          	jalr	1032(ra) # 80004550 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003150:	409c                	lw	a5,0(s1)
    80003152:	cb89                	beqz	a5,80003164 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003154:	8526                	mv	a0,s1
    80003156:	70a2                	ld	ra,40(sp)
    80003158:	7402                	ld	s0,32(sp)
    8000315a:	64e2                	ld	s1,24(sp)
    8000315c:	6942                	ld	s2,16(sp)
    8000315e:	69a2                	ld	s3,8(sp)
    80003160:	6145                	addi	sp,sp,48
    80003162:	8082                	ret
    virtio_disk_rw(b, 0);
    80003164:	4581                	li	a1,0
    80003166:	8526                	mv	a0,s1
    80003168:	00003097          	auipc	ra,0x3
    8000316c:	f0e080e7          	jalr	-242(ra) # 80006076 <virtio_disk_rw>
    b->valid = 1;
    80003170:	4785                	li	a5,1
    80003172:	c09c                	sw	a5,0(s1)
  return b;
    80003174:	b7c5                	j	80003154 <bread+0xd0>

0000000080003176 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003176:	1101                	addi	sp,sp,-32
    80003178:	ec06                	sd	ra,24(sp)
    8000317a:	e822                	sd	s0,16(sp)
    8000317c:	e426                	sd	s1,8(sp)
    8000317e:	1000                	addi	s0,sp,32
    80003180:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003182:	0541                	addi	a0,a0,16
    80003184:	00001097          	auipc	ra,0x1
    80003188:	466080e7          	jalr	1126(ra) # 800045ea <holdingsleep>
    8000318c:	cd01                	beqz	a0,800031a4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000318e:	4585                	li	a1,1
    80003190:	8526                	mv	a0,s1
    80003192:	00003097          	auipc	ra,0x3
    80003196:	ee4080e7          	jalr	-284(ra) # 80006076 <virtio_disk_rw>
}
    8000319a:	60e2                	ld	ra,24(sp)
    8000319c:	6442                	ld	s0,16(sp)
    8000319e:	64a2                	ld	s1,8(sp)
    800031a0:	6105                	addi	sp,sp,32
    800031a2:	8082                	ret
    panic("bwrite");
    800031a4:	00005517          	auipc	a0,0x5
    800031a8:	3cc50513          	addi	a0,a0,972 # 80008570 <syscalls+0xe8>
    800031ac:	ffffd097          	auipc	ra,0xffffd
    800031b0:	392080e7          	jalr	914(ra) # 8000053e <panic>

00000000800031b4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	e426                	sd	s1,8(sp)
    800031bc:	e04a                	sd	s2,0(sp)
    800031be:	1000                	addi	s0,sp,32
    800031c0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031c2:	01050913          	addi	s2,a0,16
    800031c6:	854a                	mv	a0,s2
    800031c8:	00001097          	auipc	ra,0x1
    800031cc:	422080e7          	jalr	1058(ra) # 800045ea <holdingsleep>
    800031d0:	c92d                	beqz	a0,80003242 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031d2:	854a                	mv	a0,s2
    800031d4:	00001097          	auipc	ra,0x1
    800031d8:	3d2080e7          	jalr	978(ra) # 800045a6 <releasesleep>

  acquire(&bcache.lock);
    800031dc:	00014517          	auipc	a0,0x14
    800031e0:	f0c50513          	addi	a0,a0,-244 # 800170e8 <bcache>
    800031e4:	ffffe097          	auipc	ra,0xffffe
    800031e8:	a00080e7          	jalr	-1536(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031ec:	40bc                	lw	a5,64(s1)
    800031ee:	37fd                	addiw	a5,a5,-1
    800031f0:	0007871b          	sext.w	a4,a5
    800031f4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031f6:	eb05                	bnez	a4,80003226 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031f8:	68bc                	ld	a5,80(s1)
    800031fa:	64b8                	ld	a4,72(s1)
    800031fc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031fe:	64bc                	ld	a5,72(s1)
    80003200:	68b8                	ld	a4,80(s1)
    80003202:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003204:	0001c797          	auipc	a5,0x1c
    80003208:	ee478793          	addi	a5,a5,-284 # 8001f0e8 <bcache+0x8000>
    8000320c:	2b87b703          	ld	a4,696(a5)
    80003210:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003212:	0001c717          	auipc	a4,0x1c
    80003216:	13e70713          	addi	a4,a4,318 # 8001f350 <bcache+0x8268>
    8000321a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000321c:	2b87b703          	ld	a4,696(a5)
    80003220:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003222:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003226:	00014517          	auipc	a0,0x14
    8000322a:	ec250513          	addi	a0,a0,-318 # 800170e8 <bcache>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	a6a080e7          	jalr	-1430(ra) # 80000c98 <release>
}
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	64a2                	ld	s1,8(sp)
    8000323c:	6902                	ld	s2,0(sp)
    8000323e:	6105                	addi	sp,sp,32
    80003240:	8082                	ret
    panic("brelse");
    80003242:	00005517          	auipc	a0,0x5
    80003246:	33650513          	addi	a0,a0,822 # 80008578 <syscalls+0xf0>
    8000324a:	ffffd097          	auipc	ra,0xffffd
    8000324e:	2f4080e7          	jalr	756(ra) # 8000053e <panic>

0000000080003252 <bpin>:

void
bpin(struct buf *b) {
    80003252:	1101                	addi	sp,sp,-32
    80003254:	ec06                	sd	ra,24(sp)
    80003256:	e822                	sd	s0,16(sp)
    80003258:	e426                	sd	s1,8(sp)
    8000325a:	1000                	addi	s0,sp,32
    8000325c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000325e:	00014517          	auipc	a0,0x14
    80003262:	e8a50513          	addi	a0,a0,-374 # 800170e8 <bcache>
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	97e080e7          	jalr	-1666(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000326e:	40bc                	lw	a5,64(s1)
    80003270:	2785                	addiw	a5,a5,1
    80003272:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003274:	00014517          	auipc	a0,0x14
    80003278:	e7450513          	addi	a0,a0,-396 # 800170e8 <bcache>
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	a1c080e7          	jalr	-1508(ra) # 80000c98 <release>
}
    80003284:	60e2                	ld	ra,24(sp)
    80003286:	6442                	ld	s0,16(sp)
    80003288:	64a2                	ld	s1,8(sp)
    8000328a:	6105                	addi	sp,sp,32
    8000328c:	8082                	ret

000000008000328e <bunpin>:

void
bunpin(struct buf *b) {
    8000328e:	1101                	addi	sp,sp,-32
    80003290:	ec06                	sd	ra,24(sp)
    80003292:	e822                	sd	s0,16(sp)
    80003294:	e426                	sd	s1,8(sp)
    80003296:	1000                	addi	s0,sp,32
    80003298:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000329a:	00014517          	auipc	a0,0x14
    8000329e:	e4e50513          	addi	a0,a0,-434 # 800170e8 <bcache>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	942080e7          	jalr	-1726(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032aa:	40bc                	lw	a5,64(s1)
    800032ac:	37fd                	addiw	a5,a5,-1
    800032ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032b0:	00014517          	auipc	a0,0x14
    800032b4:	e3850513          	addi	a0,a0,-456 # 800170e8 <bcache>
    800032b8:	ffffe097          	auipc	ra,0xffffe
    800032bc:	9e0080e7          	jalr	-1568(ra) # 80000c98 <release>
}
    800032c0:	60e2                	ld	ra,24(sp)
    800032c2:	6442                	ld	s0,16(sp)
    800032c4:	64a2                	ld	s1,8(sp)
    800032c6:	6105                	addi	sp,sp,32
    800032c8:	8082                	ret

00000000800032ca <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032ca:	1101                	addi	sp,sp,-32
    800032cc:	ec06                	sd	ra,24(sp)
    800032ce:	e822                	sd	s0,16(sp)
    800032d0:	e426                	sd	s1,8(sp)
    800032d2:	e04a                	sd	s2,0(sp)
    800032d4:	1000                	addi	s0,sp,32
    800032d6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032d8:	00d5d59b          	srliw	a1,a1,0xd
    800032dc:	0001c797          	auipc	a5,0x1c
    800032e0:	4e87a783          	lw	a5,1256(a5) # 8001f7c4 <sb+0x1c>
    800032e4:	9dbd                	addw	a1,a1,a5
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	d9e080e7          	jalr	-610(ra) # 80003084 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032ee:	0074f713          	andi	a4,s1,7
    800032f2:	4785                	li	a5,1
    800032f4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032f8:	14ce                	slli	s1,s1,0x33
    800032fa:	90d9                	srli	s1,s1,0x36
    800032fc:	00950733          	add	a4,a0,s1
    80003300:	05874703          	lbu	a4,88(a4)
    80003304:	00e7f6b3          	and	a3,a5,a4
    80003308:	c69d                	beqz	a3,80003336 <bfree+0x6c>
    8000330a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000330c:	94aa                	add	s1,s1,a0
    8000330e:	fff7c793          	not	a5,a5
    80003312:	8ff9                	and	a5,a5,a4
    80003314:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003318:	00001097          	auipc	ra,0x1
    8000331c:	118080e7          	jalr	280(ra) # 80004430 <log_write>
  brelse(bp);
    80003320:	854a                	mv	a0,s2
    80003322:	00000097          	auipc	ra,0x0
    80003326:	e92080e7          	jalr	-366(ra) # 800031b4 <brelse>
}
    8000332a:	60e2                	ld	ra,24(sp)
    8000332c:	6442                	ld	s0,16(sp)
    8000332e:	64a2                	ld	s1,8(sp)
    80003330:	6902                	ld	s2,0(sp)
    80003332:	6105                	addi	sp,sp,32
    80003334:	8082                	ret
    panic("freeing free block");
    80003336:	00005517          	auipc	a0,0x5
    8000333a:	24a50513          	addi	a0,a0,586 # 80008580 <syscalls+0xf8>
    8000333e:	ffffd097          	auipc	ra,0xffffd
    80003342:	200080e7          	jalr	512(ra) # 8000053e <panic>

0000000080003346 <balloc>:
{
    80003346:	711d                	addi	sp,sp,-96
    80003348:	ec86                	sd	ra,88(sp)
    8000334a:	e8a2                	sd	s0,80(sp)
    8000334c:	e4a6                	sd	s1,72(sp)
    8000334e:	e0ca                	sd	s2,64(sp)
    80003350:	fc4e                	sd	s3,56(sp)
    80003352:	f852                	sd	s4,48(sp)
    80003354:	f456                	sd	s5,40(sp)
    80003356:	f05a                	sd	s6,32(sp)
    80003358:	ec5e                	sd	s7,24(sp)
    8000335a:	e862                	sd	s8,16(sp)
    8000335c:	e466                	sd	s9,8(sp)
    8000335e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003360:	0001c797          	auipc	a5,0x1c
    80003364:	44c7a783          	lw	a5,1100(a5) # 8001f7ac <sb+0x4>
    80003368:	cbd1                	beqz	a5,800033fc <balloc+0xb6>
    8000336a:	8baa                	mv	s7,a0
    8000336c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000336e:	0001cb17          	auipc	s6,0x1c
    80003372:	43ab0b13          	addi	s6,s6,1082 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003376:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003378:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000337a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000337c:	6c89                	lui	s9,0x2
    8000337e:	a831                	j	8000339a <balloc+0x54>
    brelse(bp);
    80003380:	854a                	mv	a0,s2
    80003382:	00000097          	auipc	ra,0x0
    80003386:	e32080e7          	jalr	-462(ra) # 800031b4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000338a:	015c87bb          	addw	a5,s9,s5
    8000338e:	00078a9b          	sext.w	s5,a5
    80003392:	004b2703          	lw	a4,4(s6)
    80003396:	06eaf363          	bgeu	s5,a4,800033fc <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000339a:	41fad79b          	sraiw	a5,s5,0x1f
    8000339e:	0137d79b          	srliw	a5,a5,0x13
    800033a2:	015787bb          	addw	a5,a5,s5
    800033a6:	40d7d79b          	sraiw	a5,a5,0xd
    800033aa:	01cb2583          	lw	a1,28(s6)
    800033ae:	9dbd                	addw	a1,a1,a5
    800033b0:	855e                	mv	a0,s7
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	cd2080e7          	jalr	-814(ra) # 80003084 <bread>
    800033ba:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033bc:	004b2503          	lw	a0,4(s6)
    800033c0:	000a849b          	sext.w	s1,s5
    800033c4:	8662                	mv	a2,s8
    800033c6:	faa4fde3          	bgeu	s1,a0,80003380 <balloc+0x3a>
      m = 1 << (bi % 8);
    800033ca:	41f6579b          	sraiw	a5,a2,0x1f
    800033ce:	01d7d69b          	srliw	a3,a5,0x1d
    800033d2:	00c6873b          	addw	a4,a3,a2
    800033d6:	00777793          	andi	a5,a4,7
    800033da:	9f95                	subw	a5,a5,a3
    800033dc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033e0:	4037571b          	sraiw	a4,a4,0x3
    800033e4:	00e906b3          	add	a3,s2,a4
    800033e8:	0586c683          	lbu	a3,88(a3)
    800033ec:	00d7f5b3          	and	a1,a5,a3
    800033f0:	cd91                	beqz	a1,8000340c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f2:	2605                	addiw	a2,a2,1
    800033f4:	2485                	addiw	s1,s1,1
    800033f6:	fd4618e3          	bne	a2,s4,800033c6 <balloc+0x80>
    800033fa:	b759                	j	80003380 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033fc:	00005517          	auipc	a0,0x5
    80003400:	19c50513          	addi	a0,a0,412 # 80008598 <syscalls+0x110>
    80003404:	ffffd097          	auipc	ra,0xffffd
    80003408:	13a080e7          	jalr	314(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000340c:	974a                	add	a4,a4,s2
    8000340e:	8fd5                	or	a5,a5,a3
    80003410:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003414:	854a                	mv	a0,s2
    80003416:	00001097          	auipc	ra,0x1
    8000341a:	01a080e7          	jalr	26(ra) # 80004430 <log_write>
        brelse(bp);
    8000341e:	854a                	mv	a0,s2
    80003420:	00000097          	auipc	ra,0x0
    80003424:	d94080e7          	jalr	-620(ra) # 800031b4 <brelse>
  bp = bread(dev, bno);
    80003428:	85a6                	mv	a1,s1
    8000342a:	855e                	mv	a0,s7
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	c58080e7          	jalr	-936(ra) # 80003084 <bread>
    80003434:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003436:	40000613          	li	a2,1024
    8000343a:	4581                	li	a1,0
    8000343c:	05850513          	addi	a0,a0,88
    80003440:	ffffe097          	auipc	ra,0xffffe
    80003444:	8a0080e7          	jalr	-1888(ra) # 80000ce0 <memset>
  log_write(bp);
    80003448:	854a                	mv	a0,s2
    8000344a:	00001097          	auipc	ra,0x1
    8000344e:	fe6080e7          	jalr	-26(ra) # 80004430 <log_write>
  brelse(bp);
    80003452:	854a                	mv	a0,s2
    80003454:	00000097          	auipc	ra,0x0
    80003458:	d60080e7          	jalr	-672(ra) # 800031b4 <brelse>
}
    8000345c:	8526                	mv	a0,s1
    8000345e:	60e6                	ld	ra,88(sp)
    80003460:	6446                	ld	s0,80(sp)
    80003462:	64a6                	ld	s1,72(sp)
    80003464:	6906                	ld	s2,64(sp)
    80003466:	79e2                	ld	s3,56(sp)
    80003468:	7a42                	ld	s4,48(sp)
    8000346a:	7aa2                	ld	s5,40(sp)
    8000346c:	7b02                	ld	s6,32(sp)
    8000346e:	6be2                	ld	s7,24(sp)
    80003470:	6c42                	ld	s8,16(sp)
    80003472:	6ca2                	ld	s9,8(sp)
    80003474:	6125                	addi	sp,sp,96
    80003476:	8082                	ret

0000000080003478 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003478:	7179                	addi	sp,sp,-48
    8000347a:	f406                	sd	ra,40(sp)
    8000347c:	f022                	sd	s0,32(sp)
    8000347e:	ec26                	sd	s1,24(sp)
    80003480:	e84a                	sd	s2,16(sp)
    80003482:	e44e                	sd	s3,8(sp)
    80003484:	e052                	sd	s4,0(sp)
    80003486:	1800                	addi	s0,sp,48
    80003488:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000348a:	47ad                	li	a5,11
    8000348c:	04b7fe63          	bgeu	a5,a1,800034e8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003490:	ff45849b          	addiw	s1,a1,-12
    80003494:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003498:	0ff00793          	li	a5,255
    8000349c:	0ae7e363          	bltu	a5,a4,80003542 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034a0:	08052583          	lw	a1,128(a0)
    800034a4:	c5ad                	beqz	a1,8000350e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034a6:	00092503          	lw	a0,0(s2)
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	bda080e7          	jalr	-1062(ra) # 80003084 <bread>
    800034b2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034b4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034b8:	02049593          	slli	a1,s1,0x20
    800034bc:	9181                	srli	a1,a1,0x20
    800034be:	058a                	slli	a1,a1,0x2
    800034c0:	00b784b3          	add	s1,a5,a1
    800034c4:	0004a983          	lw	s3,0(s1)
    800034c8:	04098d63          	beqz	s3,80003522 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034cc:	8552                	mv	a0,s4
    800034ce:	00000097          	auipc	ra,0x0
    800034d2:	ce6080e7          	jalr	-794(ra) # 800031b4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034d6:	854e                	mv	a0,s3
    800034d8:	70a2                	ld	ra,40(sp)
    800034da:	7402                	ld	s0,32(sp)
    800034dc:	64e2                	ld	s1,24(sp)
    800034de:	6942                	ld	s2,16(sp)
    800034e0:	69a2                	ld	s3,8(sp)
    800034e2:	6a02                	ld	s4,0(sp)
    800034e4:	6145                	addi	sp,sp,48
    800034e6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034e8:	02059493          	slli	s1,a1,0x20
    800034ec:	9081                	srli	s1,s1,0x20
    800034ee:	048a                	slli	s1,s1,0x2
    800034f0:	94aa                	add	s1,s1,a0
    800034f2:	0504a983          	lw	s3,80(s1)
    800034f6:	fe0990e3          	bnez	s3,800034d6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034fa:	4108                	lw	a0,0(a0)
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	e4a080e7          	jalr	-438(ra) # 80003346 <balloc>
    80003504:	0005099b          	sext.w	s3,a0
    80003508:	0534a823          	sw	s3,80(s1)
    8000350c:	b7e9                	j	800034d6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000350e:	4108                	lw	a0,0(a0)
    80003510:	00000097          	auipc	ra,0x0
    80003514:	e36080e7          	jalr	-458(ra) # 80003346 <balloc>
    80003518:	0005059b          	sext.w	a1,a0
    8000351c:	08b92023          	sw	a1,128(s2)
    80003520:	b759                	j	800034a6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003522:	00092503          	lw	a0,0(s2)
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	e20080e7          	jalr	-480(ra) # 80003346 <balloc>
    8000352e:	0005099b          	sext.w	s3,a0
    80003532:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003536:	8552                	mv	a0,s4
    80003538:	00001097          	auipc	ra,0x1
    8000353c:	ef8080e7          	jalr	-264(ra) # 80004430 <log_write>
    80003540:	b771                	j	800034cc <bmap+0x54>
  panic("bmap: out of range");
    80003542:	00005517          	auipc	a0,0x5
    80003546:	06e50513          	addi	a0,a0,110 # 800085b0 <syscalls+0x128>
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	ff4080e7          	jalr	-12(ra) # 8000053e <panic>

0000000080003552 <iget>:
{
    80003552:	7179                	addi	sp,sp,-48
    80003554:	f406                	sd	ra,40(sp)
    80003556:	f022                	sd	s0,32(sp)
    80003558:	ec26                	sd	s1,24(sp)
    8000355a:	e84a                	sd	s2,16(sp)
    8000355c:	e44e                	sd	s3,8(sp)
    8000355e:	e052                	sd	s4,0(sp)
    80003560:	1800                	addi	s0,sp,48
    80003562:	89aa                	mv	s3,a0
    80003564:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003566:	0001c517          	auipc	a0,0x1c
    8000356a:	26250513          	addi	a0,a0,610 # 8001f7c8 <itable>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	676080e7          	jalr	1654(ra) # 80000be4 <acquire>
  empty = 0;
    80003576:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003578:	0001c497          	auipc	s1,0x1c
    8000357c:	26848493          	addi	s1,s1,616 # 8001f7e0 <itable+0x18>
    80003580:	0001e697          	auipc	a3,0x1e
    80003584:	cf068693          	addi	a3,a3,-784 # 80021270 <log>
    80003588:	a039                	j	80003596 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000358a:	02090b63          	beqz	s2,800035c0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000358e:	08848493          	addi	s1,s1,136
    80003592:	02d48a63          	beq	s1,a3,800035c6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003596:	449c                	lw	a5,8(s1)
    80003598:	fef059e3          	blez	a5,8000358a <iget+0x38>
    8000359c:	4098                	lw	a4,0(s1)
    8000359e:	ff3716e3          	bne	a4,s3,8000358a <iget+0x38>
    800035a2:	40d8                	lw	a4,4(s1)
    800035a4:	ff4713e3          	bne	a4,s4,8000358a <iget+0x38>
      ip->ref++;
    800035a8:	2785                	addiw	a5,a5,1
    800035aa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035ac:	0001c517          	auipc	a0,0x1c
    800035b0:	21c50513          	addi	a0,a0,540 # 8001f7c8 <itable>
    800035b4:	ffffd097          	auipc	ra,0xffffd
    800035b8:	6e4080e7          	jalr	1764(ra) # 80000c98 <release>
      return ip;
    800035bc:	8926                	mv	s2,s1
    800035be:	a03d                	j	800035ec <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035c0:	f7f9                	bnez	a5,8000358e <iget+0x3c>
    800035c2:	8926                	mv	s2,s1
    800035c4:	b7e9                	j	8000358e <iget+0x3c>
  if(empty == 0)
    800035c6:	02090c63          	beqz	s2,800035fe <iget+0xac>
  ip->dev = dev;
    800035ca:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035ce:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035d2:	4785                	li	a5,1
    800035d4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035d8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035dc:	0001c517          	auipc	a0,0x1c
    800035e0:	1ec50513          	addi	a0,a0,492 # 8001f7c8 <itable>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	6b4080e7          	jalr	1716(ra) # 80000c98 <release>
}
    800035ec:	854a                	mv	a0,s2
    800035ee:	70a2                	ld	ra,40(sp)
    800035f0:	7402                	ld	s0,32(sp)
    800035f2:	64e2                	ld	s1,24(sp)
    800035f4:	6942                	ld	s2,16(sp)
    800035f6:	69a2                	ld	s3,8(sp)
    800035f8:	6a02                	ld	s4,0(sp)
    800035fa:	6145                	addi	sp,sp,48
    800035fc:	8082                	ret
    panic("iget: no inodes");
    800035fe:	00005517          	auipc	a0,0x5
    80003602:	fca50513          	addi	a0,a0,-54 # 800085c8 <syscalls+0x140>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	f38080e7          	jalr	-200(ra) # 8000053e <panic>

000000008000360e <fsinit>:
fsinit(int dev) {
    8000360e:	7179                	addi	sp,sp,-48
    80003610:	f406                	sd	ra,40(sp)
    80003612:	f022                	sd	s0,32(sp)
    80003614:	ec26                	sd	s1,24(sp)
    80003616:	e84a                	sd	s2,16(sp)
    80003618:	e44e                	sd	s3,8(sp)
    8000361a:	1800                	addi	s0,sp,48
    8000361c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000361e:	4585                	li	a1,1
    80003620:	00000097          	auipc	ra,0x0
    80003624:	a64080e7          	jalr	-1436(ra) # 80003084 <bread>
    80003628:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000362a:	0001c997          	auipc	s3,0x1c
    8000362e:	17e98993          	addi	s3,s3,382 # 8001f7a8 <sb>
    80003632:	02000613          	li	a2,32
    80003636:	05850593          	addi	a1,a0,88
    8000363a:	854e                	mv	a0,s3
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	704080e7          	jalr	1796(ra) # 80000d40 <memmove>
  brelse(bp);
    80003644:	8526                	mv	a0,s1
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	b6e080e7          	jalr	-1170(ra) # 800031b4 <brelse>
  if(sb.magic != FSMAGIC)
    8000364e:	0009a703          	lw	a4,0(s3)
    80003652:	102037b7          	lui	a5,0x10203
    80003656:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000365a:	02f71263          	bne	a4,a5,8000367e <fsinit+0x70>
  initlog(dev, &sb);
    8000365e:	0001c597          	auipc	a1,0x1c
    80003662:	14a58593          	addi	a1,a1,330 # 8001f7a8 <sb>
    80003666:	854a                	mv	a0,s2
    80003668:	00001097          	auipc	ra,0x1
    8000366c:	b4c080e7          	jalr	-1204(ra) # 800041b4 <initlog>
}
    80003670:	70a2                	ld	ra,40(sp)
    80003672:	7402                	ld	s0,32(sp)
    80003674:	64e2                	ld	s1,24(sp)
    80003676:	6942                	ld	s2,16(sp)
    80003678:	69a2                	ld	s3,8(sp)
    8000367a:	6145                	addi	sp,sp,48
    8000367c:	8082                	ret
    panic("invalid file system");
    8000367e:	00005517          	auipc	a0,0x5
    80003682:	f5a50513          	addi	a0,a0,-166 # 800085d8 <syscalls+0x150>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	eb8080e7          	jalr	-328(ra) # 8000053e <panic>

000000008000368e <iinit>:
{
    8000368e:	7179                	addi	sp,sp,-48
    80003690:	f406                	sd	ra,40(sp)
    80003692:	f022                	sd	s0,32(sp)
    80003694:	ec26                	sd	s1,24(sp)
    80003696:	e84a                	sd	s2,16(sp)
    80003698:	e44e                	sd	s3,8(sp)
    8000369a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000369c:	00005597          	auipc	a1,0x5
    800036a0:	f5458593          	addi	a1,a1,-172 # 800085f0 <syscalls+0x168>
    800036a4:	0001c517          	auipc	a0,0x1c
    800036a8:	12450513          	addi	a0,a0,292 # 8001f7c8 <itable>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	4a8080e7          	jalr	1192(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036b4:	0001c497          	auipc	s1,0x1c
    800036b8:	13c48493          	addi	s1,s1,316 # 8001f7f0 <itable+0x28>
    800036bc:	0001e997          	auipc	s3,0x1e
    800036c0:	bc498993          	addi	s3,s3,-1084 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036c4:	00005917          	auipc	s2,0x5
    800036c8:	f3490913          	addi	s2,s2,-204 # 800085f8 <syscalls+0x170>
    800036cc:	85ca                	mv	a1,s2
    800036ce:	8526                	mv	a0,s1
    800036d0:	00001097          	auipc	ra,0x1
    800036d4:	e46080e7          	jalr	-442(ra) # 80004516 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036d8:	08848493          	addi	s1,s1,136
    800036dc:	ff3498e3          	bne	s1,s3,800036cc <iinit+0x3e>
}
    800036e0:	70a2                	ld	ra,40(sp)
    800036e2:	7402                	ld	s0,32(sp)
    800036e4:	64e2                	ld	s1,24(sp)
    800036e6:	6942                	ld	s2,16(sp)
    800036e8:	69a2                	ld	s3,8(sp)
    800036ea:	6145                	addi	sp,sp,48
    800036ec:	8082                	ret

00000000800036ee <ialloc>:
{
    800036ee:	715d                	addi	sp,sp,-80
    800036f0:	e486                	sd	ra,72(sp)
    800036f2:	e0a2                	sd	s0,64(sp)
    800036f4:	fc26                	sd	s1,56(sp)
    800036f6:	f84a                	sd	s2,48(sp)
    800036f8:	f44e                	sd	s3,40(sp)
    800036fa:	f052                	sd	s4,32(sp)
    800036fc:	ec56                	sd	s5,24(sp)
    800036fe:	e85a                	sd	s6,16(sp)
    80003700:	e45e                	sd	s7,8(sp)
    80003702:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003704:	0001c717          	auipc	a4,0x1c
    80003708:	0b072703          	lw	a4,176(a4) # 8001f7b4 <sb+0xc>
    8000370c:	4785                	li	a5,1
    8000370e:	04e7fa63          	bgeu	a5,a4,80003762 <ialloc+0x74>
    80003712:	8aaa                	mv	s5,a0
    80003714:	8bae                	mv	s7,a1
    80003716:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003718:	0001ca17          	auipc	s4,0x1c
    8000371c:	090a0a13          	addi	s4,s4,144 # 8001f7a8 <sb>
    80003720:	00048b1b          	sext.w	s6,s1
    80003724:	0044d593          	srli	a1,s1,0x4
    80003728:	018a2783          	lw	a5,24(s4)
    8000372c:	9dbd                	addw	a1,a1,a5
    8000372e:	8556                	mv	a0,s5
    80003730:	00000097          	auipc	ra,0x0
    80003734:	954080e7          	jalr	-1708(ra) # 80003084 <bread>
    80003738:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000373a:	05850993          	addi	s3,a0,88
    8000373e:	00f4f793          	andi	a5,s1,15
    80003742:	079a                	slli	a5,a5,0x6
    80003744:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003746:	00099783          	lh	a5,0(s3)
    8000374a:	c785                	beqz	a5,80003772 <ialloc+0x84>
    brelse(bp);
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	a68080e7          	jalr	-1432(ra) # 800031b4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003754:	0485                	addi	s1,s1,1
    80003756:	00ca2703          	lw	a4,12(s4)
    8000375a:	0004879b          	sext.w	a5,s1
    8000375e:	fce7e1e3          	bltu	a5,a4,80003720 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003762:	00005517          	auipc	a0,0x5
    80003766:	e9e50513          	addi	a0,a0,-354 # 80008600 <syscalls+0x178>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	dd4080e7          	jalr	-556(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003772:	04000613          	li	a2,64
    80003776:	4581                	li	a1,0
    80003778:	854e                	mv	a0,s3
    8000377a:	ffffd097          	auipc	ra,0xffffd
    8000377e:	566080e7          	jalr	1382(ra) # 80000ce0 <memset>
      dip->type = type;
    80003782:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003786:	854a                	mv	a0,s2
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	ca8080e7          	jalr	-856(ra) # 80004430 <log_write>
      brelse(bp);
    80003790:	854a                	mv	a0,s2
    80003792:	00000097          	auipc	ra,0x0
    80003796:	a22080e7          	jalr	-1502(ra) # 800031b4 <brelse>
      return iget(dev, inum);
    8000379a:	85da                	mv	a1,s6
    8000379c:	8556                	mv	a0,s5
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	db4080e7          	jalr	-588(ra) # 80003552 <iget>
}
    800037a6:	60a6                	ld	ra,72(sp)
    800037a8:	6406                	ld	s0,64(sp)
    800037aa:	74e2                	ld	s1,56(sp)
    800037ac:	7942                	ld	s2,48(sp)
    800037ae:	79a2                	ld	s3,40(sp)
    800037b0:	7a02                	ld	s4,32(sp)
    800037b2:	6ae2                	ld	s5,24(sp)
    800037b4:	6b42                	ld	s6,16(sp)
    800037b6:	6ba2                	ld	s7,8(sp)
    800037b8:	6161                	addi	sp,sp,80
    800037ba:	8082                	ret

00000000800037bc <iupdate>:
{
    800037bc:	1101                	addi	sp,sp,-32
    800037be:	ec06                	sd	ra,24(sp)
    800037c0:	e822                	sd	s0,16(sp)
    800037c2:	e426                	sd	s1,8(sp)
    800037c4:	e04a                	sd	s2,0(sp)
    800037c6:	1000                	addi	s0,sp,32
    800037c8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037ca:	415c                	lw	a5,4(a0)
    800037cc:	0047d79b          	srliw	a5,a5,0x4
    800037d0:	0001c597          	auipc	a1,0x1c
    800037d4:	ff05a583          	lw	a1,-16(a1) # 8001f7c0 <sb+0x18>
    800037d8:	9dbd                	addw	a1,a1,a5
    800037da:	4108                	lw	a0,0(a0)
    800037dc:	00000097          	auipc	ra,0x0
    800037e0:	8a8080e7          	jalr	-1880(ra) # 80003084 <bread>
    800037e4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037e6:	05850793          	addi	a5,a0,88
    800037ea:	40c8                	lw	a0,4(s1)
    800037ec:	893d                	andi	a0,a0,15
    800037ee:	051a                	slli	a0,a0,0x6
    800037f0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037f2:	04449703          	lh	a4,68(s1)
    800037f6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037fa:	04649703          	lh	a4,70(s1)
    800037fe:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003802:	04849703          	lh	a4,72(s1)
    80003806:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000380a:	04a49703          	lh	a4,74(s1)
    8000380e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003812:	44f8                	lw	a4,76(s1)
    80003814:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003816:	03400613          	li	a2,52
    8000381a:	05048593          	addi	a1,s1,80
    8000381e:	0531                	addi	a0,a0,12
    80003820:	ffffd097          	auipc	ra,0xffffd
    80003824:	520080e7          	jalr	1312(ra) # 80000d40 <memmove>
  log_write(bp);
    80003828:	854a                	mv	a0,s2
    8000382a:	00001097          	auipc	ra,0x1
    8000382e:	c06080e7          	jalr	-1018(ra) # 80004430 <log_write>
  brelse(bp);
    80003832:	854a                	mv	a0,s2
    80003834:	00000097          	auipc	ra,0x0
    80003838:	980080e7          	jalr	-1664(ra) # 800031b4 <brelse>
}
    8000383c:	60e2                	ld	ra,24(sp)
    8000383e:	6442                	ld	s0,16(sp)
    80003840:	64a2                	ld	s1,8(sp)
    80003842:	6902                	ld	s2,0(sp)
    80003844:	6105                	addi	sp,sp,32
    80003846:	8082                	ret

0000000080003848 <idup>:
{
    80003848:	1101                	addi	sp,sp,-32
    8000384a:	ec06                	sd	ra,24(sp)
    8000384c:	e822                	sd	s0,16(sp)
    8000384e:	e426                	sd	s1,8(sp)
    80003850:	1000                	addi	s0,sp,32
    80003852:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003854:	0001c517          	auipc	a0,0x1c
    80003858:	f7450513          	addi	a0,a0,-140 # 8001f7c8 <itable>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	388080e7          	jalr	904(ra) # 80000be4 <acquire>
  ip->ref++;
    80003864:	449c                	lw	a5,8(s1)
    80003866:	2785                	addiw	a5,a5,1
    80003868:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000386a:	0001c517          	auipc	a0,0x1c
    8000386e:	f5e50513          	addi	a0,a0,-162 # 8001f7c8 <itable>
    80003872:	ffffd097          	auipc	ra,0xffffd
    80003876:	426080e7          	jalr	1062(ra) # 80000c98 <release>
}
    8000387a:	8526                	mv	a0,s1
    8000387c:	60e2                	ld	ra,24(sp)
    8000387e:	6442                	ld	s0,16(sp)
    80003880:	64a2                	ld	s1,8(sp)
    80003882:	6105                	addi	sp,sp,32
    80003884:	8082                	ret

0000000080003886 <ilock>:
{
    80003886:	1101                	addi	sp,sp,-32
    80003888:	ec06                	sd	ra,24(sp)
    8000388a:	e822                	sd	s0,16(sp)
    8000388c:	e426                	sd	s1,8(sp)
    8000388e:	e04a                	sd	s2,0(sp)
    80003890:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003892:	c115                	beqz	a0,800038b6 <ilock+0x30>
    80003894:	84aa                	mv	s1,a0
    80003896:	451c                	lw	a5,8(a0)
    80003898:	00f05f63          	blez	a5,800038b6 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000389c:	0541                	addi	a0,a0,16
    8000389e:	00001097          	auipc	ra,0x1
    800038a2:	cb2080e7          	jalr	-846(ra) # 80004550 <acquiresleep>
  if(ip->valid == 0){
    800038a6:	40bc                	lw	a5,64(s1)
    800038a8:	cf99                	beqz	a5,800038c6 <ilock+0x40>
}
    800038aa:	60e2                	ld	ra,24(sp)
    800038ac:	6442                	ld	s0,16(sp)
    800038ae:	64a2                	ld	s1,8(sp)
    800038b0:	6902                	ld	s2,0(sp)
    800038b2:	6105                	addi	sp,sp,32
    800038b4:	8082                	ret
    panic("ilock");
    800038b6:	00005517          	auipc	a0,0x5
    800038ba:	d6250513          	addi	a0,a0,-670 # 80008618 <syscalls+0x190>
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	c80080e7          	jalr	-896(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038c6:	40dc                	lw	a5,4(s1)
    800038c8:	0047d79b          	srliw	a5,a5,0x4
    800038cc:	0001c597          	auipc	a1,0x1c
    800038d0:	ef45a583          	lw	a1,-268(a1) # 8001f7c0 <sb+0x18>
    800038d4:	9dbd                	addw	a1,a1,a5
    800038d6:	4088                	lw	a0,0(s1)
    800038d8:	fffff097          	auipc	ra,0xfffff
    800038dc:	7ac080e7          	jalr	1964(ra) # 80003084 <bread>
    800038e0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e2:	05850593          	addi	a1,a0,88
    800038e6:	40dc                	lw	a5,4(s1)
    800038e8:	8bbd                	andi	a5,a5,15
    800038ea:	079a                	slli	a5,a5,0x6
    800038ec:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038ee:	00059783          	lh	a5,0(a1)
    800038f2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038f6:	00259783          	lh	a5,2(a1)
    800038fa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038fe:	00459783          	lh	a5,4(a1)
    80003902:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003906:	00659783          	lh	a5,6(a1)
    8000390a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000390e:	459c                	lw	a5,8(a1)
    80003910:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003912:	03400613          	li	a2,52
    80003916:	05b1                	addi	a1,a1,12
    80003918:	05048513          	addi	a0,s1,80
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	424080e7          	jalr	1060(ra) # 80000d40 <memmove>
    brelse(bp);
    80003924:	854a                	mv	a0,s2
    80003926:	00000097          	auipc	ra,0x0
    8000392a:	88e080e7          	jalr	-1906(ra) # 800031b4 <brelse>
    ip->valid = 1;
    8000392e:	4785                	li	a5,1
    80003930:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003932:	04449783          	lh	a5,68(s1)
    80003936:	fbb5                	bnez	a5,800038aa <ilock+0x24>
      panic("ilock: no type");
    80003938:	00005517          	auipc	a0,0x5
    8000393c:	ce850513          	addi	a0,a0,-792 # 80008620 <syscalls+0x198>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	bfe080e7          	jalr	-1026(ra) # 8000053e <panic>

0000000080003948 <iunlock>:
{
    80003948:	1101                	addi	sp,sp,-32
    8000394a:	ec06                	sd	ra,24(sp)
    8000394c:	e822                	sd	s0,16(sp)
    8000394e:	e426                	sd	s1,8(sp)
    80003950:	e04a                	sd	s2,0(sp)
    80003952:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003954:	c905                	beqz	a0,80003984 <iunlock+0x3c>
    80003956:	84aa                	mv	s1,a0
    80003958:	01050913          	addi	s2,a0,16
    8000395c:	854a                	mv	a0,s2
    8000395e:	00001097          	auipc	ra,0x1
    80003962:	c8c080e7          	jalr	-884(ra) # 800045ea <holdingsleep>
    80003966:	cd19                	beqz	a0,80003984 <iunlock+0x3c>
    80003968:	449c                	lw	a5,8(s1)
    8000396a:	00f05d63          	blez	a5,80003984 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000396e:	854a                	mv	a0,s2
    80003970:	00001097          	auipc	ra,0x1
    80003974:	c36080e7          	jalr	-970(ra) # 800045a6 <releasesleep>
}
    80003978:	60e2                	ld	ra,24(sp)
    8000397a:	6442                	ld	s0,16(sp)
    8000397c:	64a2                	ld	s1,8(sp)
    8000397e:	6902                	ld	s2,0(sp)
    80003980:	6105                	addi	sp,sp,32
    80003982:	8082                	ret
    panic("iunlock");
    80003984:	00005517          	auipc	a0,0x5
    80003988:	cac50513          	addi	a0,a0,-852 # 80008630 <syscalls+0x1a8>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	bb2080e7          	jalr	-1102(ra) # 8000053e <panic>

0000000080003994 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003994:	7179                	addi	sp,sp,-48
    80003996:	f406                	sd	ra,40(sp)
    80003998:	f022                	sd	s0,32(sp)
    8000399a:	ec26                	sd	s1,24(sp)
    8000399c:	e84a                	sd	s2,16(sp)
    8000399e:	e44e                	sd	s3,8(sp)
    800039a0:	e052                	sd	s4,0(sp)
    800039a2:	1800                	addi	s0,sp,48
    800039a4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039a6:	05050493          	addi	s1,a0,80
    800039aa:	08050913          	addi	s2,a0,128
    800039ae:	a021                	j	800039b6 <itrunc+0x22>
    800039b0:	0491                	addi	s1,s1,4
    800039b2:	01248d63          	beq	s1,s2,800039cc <itrunc+0x38>
    if(ip->addrs[i]){
    800039b6:	408c                	lw	a1,0(s1)
    800039b8:	dde5                	beqz	a1,800039b0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039ba:	0009a503          	lw	a0,0(s3)
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	90c080e7          	jalr	-1780(ra) # 800032ca <bfree>
      ip->addrs[i] = 0;
    800039c6:	0004a023          	sw	zero,0(s1)
    800039ca:	b7dd                	j	800039b0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039cc:	0809a583          	lw	a1,128(s3)
    800039d0:	e185                	bnez	a1,800039f0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039d2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039d6:	854e                	mv	a0,s3
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	de4080e7          	jalr	-540(ra) # 800037bc <iupdate>
}
    800039e0:	70a2                	ld	ra,40(sp)
    800039e2:	7402                	ld	s0,32(sp)
    800039e4:	64e2                	ld	s1,24(sp)
    800039e6:	6942                	ld	s2,16(sp)
    800039e8:	69a2                	ld	s3,8(sp)
    800039ea:	6a02                	ld	s4,0(sp)
    800039ec:	6145                	addi	sp,sp,48
    800039ee:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039f0:	0009a503          	lw	a0,0(s3)
    800039f4:	fffff097          	auipc	ra,0xfffff
    800039f8:	690080e7          	jalr	1680(ra) # 80003084 <bread>
    800039fc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039fe:	05850493          	addi	s1,a0,88
    80003a02:	45850913          	addi	s2,a0,1112
    80003a06:	a811                	j	80003a1a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a08:	0009a503          	lw	a0,0(s3)
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	8be080e7          	jalr	-1858(ra) # 800032ca <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a14:	0491                	addi	s1,s1,4
    80003a16:	01248563          	beq	s1,s2,80003a20 <itrunc+0x8c>
      if(a[j])
    80003a1a:	408c                	lw	a1,0(s1)
    80003a1c:	dde5                	beqz	a1,80003a14 <itrunc+0x80>
    80003a1e:	b7ed                	j	80003a08 <itrunc+0x74>
    brelse(bp);
    80003a20:	8552                	mv	a0,s4
    80003a22:	fffff097          	auipc	ra,0xfffff
    80003a26:	792080e7          	jalr	1938(ra) # 800031b4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a2a:	0809a583          	lw	a1,128(s3)
    80003a2e:	0009a503          	lw	a0,0(s3)
    80003a32:	00000097          	auipc	ra,0x0
    80003a36:	898080e7          	jalr	-1896(ra) # 800032ca <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a3a:	0809a023          	sw	zero,128(s3)
    80003a3e:	bf51                	j	800039d2 <itrunc+0x3e>

0000000080003a40 <iput>:
{
    80003a40:	1101                	addi	sp,sp,-32
    80003a42:	ec06                	sd	ra,24(sp)
    80003a44:	e822                	sd	s0,16(sp)
    80003a46:	e426                	sd	s1,8(sp)
    80003a48:	e04a                	sd	s2,0(sp)
    80003a4a:	1000                	addi	s0,sp,32
    80003a4c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a4e:	0001c517          	auipc	a0,0x1c
    80003a52:	d7a50513          	addi	a0,a0,-646 # 8001f7c8 <itable>
    80003a56:	ffffd097          	auipc	ra,0xffffd
    80003a5a:	18e080e7          	jalr	398(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a5e:	4498                	lw	a4,8(s1)
    80003a60:	4785                	li	a5,1
    80003a62:	02f70363          	beq	a4,a5,80003a88 <iput+0x48>
  ip->ref--;
    80003a66:	449c                	lw	a5,8(s1)
    80003a68:	37fd                	addiw	a5,a5,-1
    80003a6a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a6c:	0001c517          	auipc	a0,0x1c
    80003a70:	d5c50513          	addi	a0,a0,-676 # 8001f7c8 <itable>
    80003a74:	ffffd097          	auipc	ra,0xffffd
    80003a78:	224080e7          	jalr	548(ra) # 80000c98 <release>
}
    80003a7c:	60e2                	ld	ra,24(sp)
    80003a7e:	6442                	ld	s0,16(sp)
    80003a80:	64a2                	ld	s1,8(sp)
    80003a82:	6902                	ld	s2,0(sp)
    80003a84:	6105                	addi	sp,sp,32
    80003a86:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a88:	40bc                	lw	a5,64(s1)
    80003a8a:	dff1                	beqz	a5,80003a66 <iput+0x26>
    80003a8c:	04a49783          	lh	a5,74(s1)
    80003a90:	fbf9                	bnez	a5,80003a66 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a92:	01048913          	addi	s2,s1,16
    80003a96:	854a                	mv	a0,s2
    80003a98:	00001097          	auipc	ra,0x1
    80003a9c:	ab8080e7          	jalr	-1352(ra) # 80004550 <acquiresleep>
    release(&itable.lock);
    80003aa0:	0001c517          	auipc	a0,0x1c
    80003aa4:	d2850513          	addi	a0,a0,-728 # 8001f7c8 <itable>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	1f0080e7          	jalr	496(ra) # 80000c98 <release>
    itrunc(ip);
    80003ab0:	8526                	mv	a0,s1
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	ee2080e7          	jalr	-286(ra) # 80003994 <itrunc>
    ip->type = 0;
    80003aba:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003abe:	8526                	mv	a0,s1
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	cfc080e7          	jalr	-772(ra) # 800037bc <iupdate>
    ip->valid = 0;
    80003ac8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003acc:	854a                	mv	a0,s2
    80003ace:	00001097          	auipc	ra,0x1
    80003ad2:	ad8080e7          	jalr	-1320(ra) # 800045a6 <releasesleep>
    acquire(&itable.lock);
    80003ad6:	0001c517          	auipc	a0,0x1c
    80003ada:	cf250513          	addi	a0,a0,-782 # 8001f7c8 <itable>
    80003ade:	ffffd097          	auipc	ra,0xffffd
    80003ae2:	106080e7          	jalr	262(ra) # 80000be4 <acquire>
    80003ae6:	b741                	j	80003a66 <iput+0x26>

0000000080003ae8 <iunlockput>:
{
    80003ae8:	1101                	addi	sp,sp,-32
    80003aea:	ec06                	sd	ra,24(sp)
    80003aec:	e822                	sd	s0,16(sp)
    80003aee:	e426                	sd	s1,8(sp)
    80003af0:	1000                	addi	s0,sp,32
    80003af2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	e54080e7          	jalr	-428(ra) # 80003948 <iunlock>
  iput(ip);
    80003afc:	8526                	mv	a0,s1
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	f42080e7          	jalr	-190(ra) # 80003a40 <iput>
}
    80003b06:	60e2                	ld	ra,24(sp)
    80003b08:	6442                	ld	s0,16(sp)
    80003b0a:	64a2                	ld	s1,8(sp)
    80003b0c:	6105                	addi	sp,sp,32
    80003b0e:	8082                	ret

0000000080003b10 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b10:	1141                	addi	sp,sp,-16
    80003b12:	e422                	sd	s0,8(sp)
    80003b14:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b16:	411c                	lw	a5,0(a0)
    80003b18:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b1a:	415c                	lw	a5,4(a0)
    80003b1c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b1e:	04451783          	lh	a5,68(a0)
    80003b22:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b26:	04a51783          	lh	a5,74(a0)
    80003b2a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b2e:	04c56783          	lwu	a5,76(a0)
    80003b32:	e99c                	sd	a5,16(a1)
}
    80003b34:	6422                	ld	s0,8(sp)
    80003b36:	0141                	addi	sp,sp,16
    80003b38:	8082                	ret

0000000080003b3a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b3a:	457c                	lw	a5,76(a0)
    80003b3c:	0ed7e963          	bltu	a5,a3,80003c2e <readi+0xf4>
{
    80003b40:	7159                	addi	sp,sp,-112
    80003b42:	f486                	sd	ra,104(sp)
    80003b44:	f0a2                	sd	s0,96(sp)
    80003b46:	eca6                	sd	s1,88(sp)
    80003b48:	e8ca                	sd	s2,80(sp)
    80003b4a:	e4ce                	sd	s3,72(sp)
    80003b4c:	e0d2                	sd	s4,64(sp)
    80003b4e:	fc56                	sd	s5,56(sp)
    80003b50:	f85a                	sd	s6,48(sp)
    80003b52:	f45e                	sd	s7,40(sp)
    80003b54:	f062                	sd	s8,32(sp)
    80003b56:	ec66                	sd	s9,24(sp)
    80003b58:	e86a                	sd	s10,16(sp)
    80003b5a:	e46e                	sd	s11,8(sp)
    80003b5c:	1880                	addi	s0,sp,112
    80003b5e:	8baa                	mv	s7,a0
    80003b60:	8c2e                	mv	s8,a1
    80003b62:	8ab2                	mv	s5,a2
    80003b64:	84b6                	mv	s1,a3
    80003b66:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b68:	9f35                	addw	a4,a4,a3
    return 0;
    80003b6a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b6c:	0ad76063          	bltu	a4,a3,80003c0c <readi+0xd2>
  if(off + n > ip->size)
    80003b70:	00e7f463          	bgeu	a5,a4,80003b78 <readi+0x3e>
    n = ip->size - off;
    80003b74:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b78:	0a0b0963          	beqz	s6,80003c2a <readi+0xf0>
    80003b7c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b7e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b82:	5cfd                	li	s9,-1
    80003b84:	a82d                	j	80003bbe <readi+0x84>
    80003b86:	020a1d93          	slli	s11,s4,0x20
    80003b8a:	020ddd93          	srli	s11,s11,0x20
    80003b8e:	05890613          	addi	a2,s2,88
    80003b92:	86ee                	mv	a3,s11
    80003b94:	963a                	add	a2,a2,a4
    80003b96:	85d6                	mv	a1,s5
    80003b98:	8562                	mv	a0,s8
    80003b9a:	fffff097          	auipc	ra,0xfffff
    80003b9e:	ae4080e7          	jalr	-1308(ra) # 8000267e <either_copyout>
    80003ba2:	05950d63          	beq	a0,s9,80003bfc <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ba6:	854a                	mv	a0,s2
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	60c080e7          	jalr	1548(ra) # 800031b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bb0:	013a09bb          	addw	s3,s4,s3
    80003bb4:	009a04bb          	addw	s1,s4,s1
    80003bb8:	9aee                	add	s5,s5,s11
    80003bba:	0569f763          	bgeu	s3,s6,80003c08 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bbe:	000ba903          	lw	s2,0(s7)
    80003bc2:	00a4d59b          	srliw	a1,s1,0xa
    80003bc6:	855e                	mv	a0,s7
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	8b0080e7          	jalr	-1872(ra) # 80003478 <bmap>
    80003bd0:	0005059b          	sext.w	a1,a0
    80003bd4:	854a                	mv	a0,s2
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	4ae080e7          	jalr	1198(ra) # 80003084 <bread>
    80003bde:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003be0:	3ff4f713          	andi	a4,s1,1023
    80003be4:	40ed07bb          	subw	a5,s10,a4
    80003be8:	413b06bb          	subw	a3,s6,s3
    80003bec:	8a3e                	mv	s4,a5
    80003bee:	2781                	sext.w	a5,a5
    80003bf0:	0006861b          	sext.w	a2,a3
    80003bf4:	f8f679e3          	bgeu	a2,a5,80003b86 <readi+0x4c>
    80003bf8:	8a36                	mv	s4,a3
    80003bfa:	b771                	j	80003b86 <readi+0x4c>
      brelse(bp);
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	fffff097          	auipc	ra,0xfffff
    80003c02:	5b6080e7          	jalr	1462(ra) # 800031b4 <brelse>
      tot = -1;
    80003c06:	59fd                	li	s3,-1
  }
  return tot;
    80003c08:	0009851b          	sext.w	a0,s3
}
    80003c0c:	70a6                	ld	ra,104(sp)
    80003c0e:	7406                	ld	s0,96(sp)
    80003c10:	64e6                	ld	s1,88(sp)
    80003c12:	6946                	ld	s2,80(sp)
    80003c14:	69a6                	ld	s3,72(sp)
    80003c16:	6a06                	ld	s4,64(sp)
    80003c18:	7ae2                	ld	s5,56(sp)
    80003c1a:	7b42                	ld	s6,48(sp)
    80003c1c:	7ba2                	ld	s7,40(sp)
    80003c1e:	7c02                	ld	s8,32(sp)
    80003c20:	6ce2                	ld	s9,24(sp)
    80003c22:	6d42                	ld	s10,16(sp)
    80003c24:	6da2                	ld	s11,8(sp)
    80003c26:	6165                	addi	sp,sp,112
    80003c28:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2a:	89da                	mv	s3,s6
    80003c2c:	bff1                	j	80003c08 <readi+0xce>
    return 0;
    80003c2e:	4501                	li	a0,0
}
    80003c30:	8082                	ret

0000000080003c32 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c32:	457c                	lw	a5,76(a0)
    80003c34:	10d7e863          	bltu	a5,a3,80003d44 <writei+0x112>
{
    80003c38:	7159                	addi	sp,sp,-112
    80003c3a:	f486                	sd	ra,104(sp)
    80003c3c:	f0a2                	sd	s0,96(sp)
    80003c3e:	eca6                	sd	s1,88(sp)
    80003c40:	e8ca                	sd	s2,80(sp)
    80003c42:	e4ce                	sd	s3,72(sp)
    80003c44:	e0d2                	sd	s4,64(sp)
    80003c46:	fc56                	sd	s5,56(sp)
    80003c48:	f85a                	sd	s6,48(sp)
    80003c4a:	f45e                	sd	s7,40(sp)
    80003c4c:	f062                	sd	s8,32(sp)
    80003c4e:	ec66                	sd	s9,24(sp)
    80003c50:	e86a                	sd	s10,16(sp)
    80003c52:	e46e                	sd	s11,8(sp)
    80003c54:	1880                	addi	s0,sp,112
    80003c56:	8b2a                	mv	s6,a0
    80003c58:	8c2e                	mv	s8,a1
    80003c5a:	8ab2                	mv	s5,a2
    80003c5c:	8936                	mv	s2,a3
    80003c5e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c60:	00e687bb          	addw	a5,a3,a4
    80003c64:	0ed7e263          	bltu	a5,a3,80003d48 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c68:	00043737          	lui	a4,0x43
    80003c6c:	0ef76063          	bltu	a4,a5,80003d4c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c70:	0c0b8863          	beqz	s7,80003d40 <writei+0x10e>
    80003c74:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c76:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c7a:	5cfd                	li	s9,-1
    80003c7c:	a091                	j	80003cc0 <writei+0x8e>
    80003c7e:	02099d93          	slli	s11,s3,0x20
    80003c82:	020ddd93          	srli	s11,s11,0x20
    80003c86:	05848513          	addi	a0,s1,88
    80003c8a:	86ee                	mv	a3,s11
    80003c8c:	8656                	mv	a2,s5
    80003c8e:	85e2                	mv	a1,s8
    80003c90:	953a                	add	a0,a0,a4
    80003c92:	fffff097          	auipc	ra,0xfffff
    80003c96:	a42080e7          	jalr	-1470(ra) # 800026d4 <either_copyin>
    80003c9a:	07950263          	beq	a0,s9,80003cfe <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c9e:	8526                	mv	a0,s1
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	790080e7          	jalr	1936(ra) # 80004430 <log_write>
    brelse(bp);
    80003ca8:	8526                	mv	a0,s1
    80003caa:	fffff097          	auipc	ra,0xfffff
    80003cae:	50a080e7          	jalr	1290(ra) # 800031b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cb2:	01498a3b          	addw	s4,s3,s4
    80003cb6:	0129893b          	addw	s2,s3,s2
    80003cba:	9aee                	add	s5,s5,s11
    80003cbc:	057a7663          	bgeu	s4,s7,80003d08 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cc0:	000b2483          	lw	s1,0(s6)
    80003cc4:	00a9559b          	srliw	a1,s2,0xa
    80003cc8:	855a                	mv	a0,s6
    80003cca:	fffff097          	auipc	ra,0xfffff
    80003cce:	7ae080e7          	jalr	1966(ra) # 80003478 <bmap>
    80003cd2:	0005059b          	sext.w	a1,a0
    80003cd6:	8526                	mv	a0,s1
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	3ac080e7          	jalr	940(ra) # 80003084 <bread>
    80003ce0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce2:	3ff97713          	andi	a4,s2,1023
    80003ce6:	40ed07bb          	subw	a5,s10,a4
    80003cea:	414b86bb          	subw	a3,s7,s4
    80003cee:	89be                	mv	s3,a5
    80003cf0:	2781                	sext.w	a5,a5
    80003cf2:	0006861b          	sext.w	a2,a3
    80003cf6:	f8f674e3          	bgeu	a2,a5,80003c7e <writei+0x4c>
    80003cfa:	89b6                	mv	s3,a3
    80003cfc:	b749                	j	80003c7e <writei+0x4c>
      brelse(bp);
    80003cfe:	8526                	mv	a0,s1
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	4b4080e7          	jalr	1204(ra) # 800031b4 <brelse>
  }

  if(off > ip->size)
    80003d08:	04cb2783          	lw	a5,76(s6)
    80003d0c:	0127f463          	bgeu	a5,s2,80003d14 <writei+0xe2>
    ip->size = off;
    80003d10:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d14:	855a                	mv	a0,s6
    80003d16:	00000097          	auipc	ra,0x0
    80003d1a:	aa6080e7          	jalr	-1370(ra) # 800037bc <iupdate>

  return tot;
    80003d1e:	000a051b          	sext.w	a0,s4
}
    80003d22:	70a6                	ld	ra,104(sp)
    80003d24:	7406                	ld	s0,96(sp)
    80003d26:	64e6                	ld	s1,88(sp)
    80003d28:	6946                	ld	s2,80(sp)
    80003d2a:	69a6                	ld	s3,72(sp)
    80003d2c:	6a06                	ld	s4,64(sp)
    80003d2e:	7ae2                	ld	s5,56(sp)
    80003d30:	7b42                	ld	s6,48(sp)
    80003d32:	7ba2                	ld	s7,40(sp)
    80003d34:	7c02                	ld	s8,32(sp)
    80003d36:	6ce2                	ld	s9,24(sp)
    80003d38:	6d42                	ld	s10,16(sp)
    80003d3a:	6da2                	ld	s11,8(sp)
    80003d3c:	6165                	addi	sp,sp,112
    80003d3e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d40:	8a5e                	mv	s4,s7
    80003d42:	bfc9                	j	80003d14 <writei+0xe2>
    return -1;
    80003d44:	557d                	li	a0,-1
}
    80003d46:	8082                	ret
    return -1;
    80003d48:	557d                	li	a0,-1
    80003d4a:	bfe1                	j	80003d22 <writei+0xf0>
    return -1;
    80003d4c:	557d                	li	a0,-1
    80003d4e:	bfd1                	j	80003d22 <writei+0xf0>

0000000080003d50 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d50:	1141                	addi	sp,sp,-16
    80003d52:	e406                	sd	ra,8(sp)
    80003d54:	e022                	sd	s0,0(sp)
    80003d56:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d58:	4639                	li	a2,14
    80003d5a:	ffffd097          	auipc	ra,0xffffd
    80003d5e:	05e080e7          	jalr	94(ra) # 80000db8 <strncmp>
}
    80003d62:	60a2                	ld	ra,8(sp)
    80003d64:	6402                	ld	s0,0(sp)
    80003d66:	0141                	addi	sp,sp,16
    80003d68:	8082                	ret

0000000080003d6a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d6a:	7139                	addi	sp,sp,-64
    80003d6c:	fc06                	sd	ra,56(sp)
    80003d6e:	f822                	sd	s0,48(sp)
    80003d70:	f426                	sd	s1,40(sp)
    80003d72:	f04a                	sd	s2,32(sp)
    80003d74:	ec4e                	sd	s3,24(sp)
    80003d76:	e852                	sd	s4,16(sp)
    80003d78:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d7a:	04451703          	lh	a4,68(a0)
    80003d7e:	4785                	li	a5,1
    80003d80:	00f71a63          	bne	a4,a5,80003d94 <dirlookup+0x2a>
    80003d84:	892a                	mv	s2,a0
    80003d86:	89ae                	mv	s3,a1
    80003d88:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d8a:	457c                	lw	a5,76(a0)
    80003d8c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d8e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d90:	e79d                	bnez	a5,80003dbe <dirlookup+0x54>
    80003d92:	a8a5                	j	80003e0a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d94:	00005517          	auipc	a0,0x5
    80003d98:	8a450513          	addi	a0,a0,-1884 # 80008638 <syscalls+0x1b0>
    80003d9c:	ffffc097          	auipc	ra,0xffffc
    80003da0:	7a2080e7          	jalr	1954(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003da4:	00005517          	auipc	a0,0x5
    80003da8:	8ac50513          	addi	a0,a0,-1876 # 80008650 <syscalls+0x1c8>
    80003dac:	ffffc097          	auipc	ra,0xffffc
    80003db0:	792080e7          	jalr	1938(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db4:	24c1                	addiw	s1,s1,16
    80003db6:	04c92783          	lw	a5,76(s2)
    80003dba:	04f4f763          	bgeu	s1,a5,80003e08 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dbe:	4741                	li	a4,16
    80003dc0:	86a6                	mv	a3,s1
    80003dc2:	fc040613          	addi	a2,s0,-64
    80003dc6:	4581                	li	a1,0
    80003dc8:	854a                	mv	a0,s2
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	d70080e7          	jalr	-656(ra) # 80003b3a <readi>
    80003dd2:	47c1                	li	a5,16
    80003dd4:	fcf518e3          	bne	a0,a5,80003da4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003dd8:	fc045783          	lhu	a5,-64(s0)
    80003ddc:	dfe1                	beqz	a5,80003db4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dde:	fc240593          	addi	a1,s0,-62
    80003de2:	854e                	mv	a0,s3
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	f6c080e7          	jalr	-148(ra) # 80003d50 <namecmp>
    80003dec:	f561                	bnez	a0,80003db4 <dirlookup+0x4a>
      if(poff)
    80003dee:	000a0463          	beqz	s4,80003df6 <dirlookup+0x8c>
        *poff = off;
    80003df2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003df6:	fc045583          	lhu	a1,-64(s0)
    80003dfa:	00092503          	lw	a0,0(s2)
    80003dfe:	fffff097          	auipc	ra,0xfffff
    80003e02:	754080e7          	jalr	1876(ra) # 80003552 <iget>
    80003e06:	a011                	j	80003e0a <dirlookup+0xa0>
  return 0;
    80003e08:	4501                	li	a0,0
}
    80003e0a:	70e2                	ld	ra,56(sp)
    80003e0c:	7442                	ld	s0,48(sp)
    80003e0e:	74a2                	ld	s1,40(sp)
    80003e10:	7902                	ld	s2,32(sp)
    80003e12:	69e2                	ld	s3,24(sp)
    80003e14:	6a42                	ld	s4,16(sp)
    80003e16:	6121                	addi	sp,sp,64
    80003e18:	8082                	ret

0000000080003e1a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e1a:	711d                	addi	sp,sp,-96
    80003e1c:	ec86                	sd	ra,88(sp)
    80003e1e:	e8a2                	sd	s0,80(sp)
    80003e20:	e4a6                	sd	s1,72(sp)
    80003e22:	e0ca                	sd	s2,64(sp)
    80003e24:	fc4e                	sd	s3,56(sp)
    80003e26:	f852                	sd	s4,48(sp)
    80003e28:	f456                	sd	s5,40(sp)
    80003e2a:	f05a                	sd	s6,32(sp)
    80003e2c:	ec5e                	sd	s7,24(sp)
    80003e2e:	e862                	sd	s8,16(sp)
    80003e30:	e466                	sd	s9,8(sp)
    80003e32:	1080                	addi	s0,sp,96
    80003e34:	84aa                	mv	s1,a0
    80003e36:	8b2e                	mv	s6,a1
    80003e38:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e3a:	00054703          	lbu	a4,0(a0)
    80003e3e:	02f00793          	li	a5,47
    80003e42:	02f70363          	beq	a4,a5,80003e68 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e46:	ffffe097          	auipc	ra,0xffffe
    80003e4a:	c9a080e7          	jalr	-870(ra) # 80001ae0 <myproc>
    80003e4e:	15053503          	ld	a0,336(a0)
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	9f6080e7          	jalr	-1546(ra) # 80003848 <idup>
    80003e5a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e5c:	02f00913          	li	s2,47
  len = path - s;
    80003e60:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e62:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e64:	4c05                	li	s8,1
    80003e66:	a865                	j	80003f1e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e68:	4585                	li	a1,1
    80003e6a:	4505                	li	a0,1
    80003e6c:	fffff097          	auipc	ra,0xfffff
    80003e70:	6e6080e7          	jalr	1766(ra) # 80003552 <iget>
    80003e74:	89aa                	mv	s3,a0
    80003e76:	b7dd                	j	80003e5c <namex+0x42>
      iunlockput(ip);
    80003e78:	854e                	mv	a0,s3
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	c6e080e7          	jalr	-914(ra) # 80003ae8 <iunlockput>
      return 0;
    80003e82:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e84:	854e                	mv	a0,s3
    80003e86:	60e6                	ld	ra,88(sp)
    80003e88:	6446                	ld	s0,80(sp)
    80003e8a:	64a6                	ld	s1,72(sp)
    80003e8c:	6906                	ld	s2,64(sp)
    80003e8e:	79e2                	ld	s3,56(sp)
    80003e90:	7a42                	ld	s4,48(sp)
    80003e92:	7aa2                	ld	s5,40(sp)
    80003e94:	7b02                	ld	s6,32(sp)
    80003e96:	6be2                	ld	s7,24(sp)
    80003e98:	6c42                	ld	s8,16(sp)
    80003e9a:	6ca2                	ld	s9,8(sp)
    80003e9c:	6125                	addi	sp,sp,96
    80003e9e:	8082                	ret
      iunlock(ip);
    80003ea0:	854e                	mv	a0,s3
    80003ea2:	00000097          	auipc	ra,0x0
    80003ea6:	aa6080e7          	jalr	-1370(ra) # 80003948 <iunlock>
      return ip;
    80003eaa:	bfe9                	j	80003e84 <namex+0x6a>
      iunlockput(ip);
    80003eac:	854e                	mv	a0,s3
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	c3a080e7          	jalr	-966(ra) # 80003ae8 <iunlockput>
      return 0;
    80003eb6:	89d2                	mv	s3,s4
    80003eb8:	b7f1                	j	80003e84 <namex+0x6a>
  len = path - s;
    80003eba:	40b48633          	sub	a2,s1,a1
    80003ebe:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ec2:	094cd463          	bge	s9,s4,80003f4a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ec6:	4639                	li	a2,14
    80003ec8:	8556                	mv	a0,s5
    80003eca:	ffffd097          	auipc	ra,0xffffd
    80003ece:	e76080e7          	jalr	-394(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ed2:	0004c783          	lbu	a5,0(s1)
    80003ed6:	01279763          	bne	a5,s2,80003ee4 <namex+0xca>
    path++;
    80003eda:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003edc:	0004c783          	lbu	a5,0(s1)
    80003ee0:	ff278de3          	beq	a5,s2,80003eda <namex+0xc0>
    ilock(ip);
    80003ee4:	854e                	mv	a0,s3
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	9a0080e7          	jalr	-1632(ra) # 80003886 <ilock>
    if(ip->type != T_DIR){
    80003eee:	04499783          	lh	a5,68(s3)
    80003ef2:	f98793e3          	bne	a5,s8,80003e78 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ef6:	000b0563          	beqz	s6,80003f00 <namex+0xe6>
    80003efa:	0004c783          	lbu	a5,0(s1)
    80003efe:	d3cd                	beqz	a5,80003ea0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f00:	865e                	mv	a2,s7
    80003f02:	85d6                	mv	a1,s5
    80003f04:	854e                	mv	a0,s3
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	e64080e7          	jalr	-412(ra) # 80003d6a <dirlookup>
    80003f0e:	8a2a                	mv	s4,a0
    80003f10:	dd51                	beqz	a0,80003eac <namex+0x92>
    iunlockput(ip);
    80003f12:	854e                	mv	a0,s3
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	bd4080e7          	jalr	-1068(ra) # 80003ae8 <iunlockput>
    ip = next;
    80003f1c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f1e:	0004c783          	lbu	a5,0(s1)
    80003f22:	05279763          	bne	a5,s2,80003f70 <namex+0x156>
    path++;
    80003f26:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f28:	0004c783          	lbu	a5,0(s1)
    80003f2c:	ff278de3          	beq	a5,s2,80003f26 <namex+0x10c>
  if(*path == 0)
    80003f30:	c79d                	beqz	a5,80003f5e <namex+0x144>
    path++;
    80003f32:	85a6                	mv	a1,s1
  len = path - s;
    80003f34:	8a5e                	mv	s4,s7
    80003f36:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f38:	01278963          	beq	a5,s2,80003f4a <namex+0x130>
    80003f3c:	dfbd                	beqz	a5,80003eba <namex+0xa0>
    path++;
    80003f3e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f40:	0004c783          	lbu	a5,0(s1)
    80003f44:	ff279ce3          	bne	a5,s2,80003f3c <namex+0x122>
    80003f48:	bf8d                	j	80003eba <namex+0xa0>
    memmove(name, s, len);
    80003f4a:	2601                	sext.w	a2,a2
    80003f4c:	8556                	mv	a0,s5
    80003f4e:	ffffd097          	auipc	ra,0xffffd
    80003f52:	df2080e7          	jalr	-526(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f56:	9a56                	add	s4,s4,s5
    80003f58:	000a0023          	sb	zero,0(s4)
    80003f5c:	bf9d                	j	80003ed2 <namex+0xb8>
  if(nameiparent){
    80003f5e:	f20b03e3          	beqz	s6,80003e84 <namex+0x6a>
    iput(ip);
    80003f62:	854e                	mv	a0,s3
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	adc080e7          	jalr	-1316(ra) # 80003a40 <iput>
    return 0;
    80003f6c:	4981                	li	s3,0
    80003f6e:	bf19                	j	80003e84 <namex+0x6a>
  if(*path == 0)
    80003f70:	d7fd                	beqz	a5,80003f5e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f72:	0004c783          	lbu	a5,0(s1)
    80003f76:	85a6                	mv	a1,s1
    80003f78:	b7d1                	j	80003f3c <namex+0x122>

0000000080003f7a <dirlink>:
{
    80003f7a:	7139                	addi	sp,sp,-64
    80003f7c:	fc06                	sd	ra,56(sp)
    80003f7e:	f822                	sd	s0,48(sp)
    80003f80:	f426                	sd	s1,40(sp)
    80003f82:	f04a                	sd	s2,32(sp)
    80003f84:	ec4e                	sd	s3,24(sp)
    80003f86:	e852                	sd	s4,16(sp)
    80003f88:	0080                	addi	s0,sp,64
    80003f8a:	892a                	mv	s2,a0
    80003f8c:	8a2e                	mv	s4,a1
    80003f8e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f90:	4601                	li	a2,0
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	dd8080e7          	jalr	-552(ra) # 80003d6a <dirlookup>
    80003f9a:	e93d                	bnez	a0,80004010 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f9c:	04c92483          	lw	s1,76(s2)
    80003fa0:	c49d                	beqz	s1,80003fce <dirlink+0x54>
    80003fa2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa4:	4741                	li	a4,16
    80003fa6:	86a6                	mv	a3,s1
    80003fa8:	fc040613          	addi	a2,s0,-64
    80003fac:	4581                	li	a1,0
    80003fae:	854a                	mv	a0,s2
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	b8a080e7          	jalr	-1142(ra) # 80003b3a <readi>
    80003fb8:	47c1                	li	a5,16
    80003fba:	06f51163          	bne	a0,a5,8000401c <dirlink+0xa2>
    if(de.inum == 0)
    80003fbe:	fc045783          	lhu	a5,-64(s0)
    80003fc2:	c791                	beqz	a5,80003fce <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc4:	24c1                	addiw	s1,s1,16
    80003fc6:	04c92783          	lw	a5,76(s2)
    80003fca:	fcf4ede3          	bltu	s1,a5,80003fa4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fce:	4639                	li	a2,14
    80003fd0:	85d2                	mv	a1,s4
    80003fd2:	fc240513          	addi	a0,s0,-62
    80003fd6:	ffffd097          	auipc	ra,0xffffd
    80003fda:	e1e080e7          	jalr	-482(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003fde:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe2:	4741                	li	a4,16
    80003fe4:	86a6                	mv	a3,s1
    80003fe6:	fc040613          	addi	a2,s0,-64
    80003fea:	4581                	li	a1,0
    80003fec:	854a                	mv	a0,s2
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	c44080e7          	jalr	-956(ra) # 80003c32 <writei>
    80003ff6:	872a                	mv	a4,a0
    80003ff8:	47c1                	li	a5,16
  return 0;
    80003ffa:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ffc:	02f71863          	bne	a4,a5,8000402c <dirlink+0xb2>
}
    80004000:	70e2                	ld	ra,56(sp)
    80004002:	7442                	ld	s0,48(sp)
    80004004:	74a2                	ld	s1,40(sp)
    80004006:	7902                	ld	s2,32(sp)
    80004008:	69e2                	ld	s3,24(sp)
    8000400a:	6a42                	ld	s4,16(sp)
    8000400c:	6121                	addi	sp,sp,64
    8000400e:	8082                	ret
    iput(ip);
    80004010:	00000097          	auipc	ra,0x0
    80004014:	a30080e7          	jalr	-1488(ra) # 80003a40 <iput>
    return -1;
    80004018:	557d                	li	a0,-1
    8000401a:	b7dd                	j	80004000 <dirlink+0x86>
      panic("dirlink read");
    8000401c:	00004517          	auipc	a0,0x4
    80004020:	64450513          	addi	a0,a0,1604 # 80008660 <syscalls+0x1d8>
    80004024:	ffffc097          	auipc	ra,0xffffc
    80004028:	51a080e7          	jalr	1306(ra) # 8000053e <panic>
    panic("dirlink");
    8000402c:	00004517          	auipc	a0,0x4
    80004030:	74450513          	addi	a0,a0,1860 # 80008770 <syscalls+0x2e8>
    80004034:	ffffc097          	auipc	ra,0xffffc
    80004038:	50a080e7          	jalr	1290(ra) # 8000053e <panic>

000000008000403c <namei>:

struct inode*
namei(char *path)
{
    8000403c:	1101                	addi	sp,sp,-32
    8000403e:	ec06                	sd	ra,24(sp)
    80004040:	e822                	sd	s0,16(sp)
    80004042:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004044:	fe040613          	addi	a2,s0,-32
    80004048:	4581                	li	a1,0
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	dd0080e7          	jalr	-560(ra) # 80003e1a <namex>
}
    80004052:	60e2                	ld	ra,24(sp)
    80004054:	6442                	ld	s0,16(sp)
    80004056:	6105                	addi	sp,sp,32
    80004058:	8082                	ret

000000008000405a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000405a:	1141                	addi	sp,sp,-16
    8000405c:	e406                	sd	ra,8(sp)
    8000405e:	e022                	sd	s0,0(sp)
    80004060:	0800                	addi	s0,sp,16
    80004062:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004064:	4585                	li	a1,1
    80004066:	00000097          	auipc	ra,0x0
    8000406a:	db4080e7          	jalr	-588(ra) # 80003e1a <namex>
}
    8000406e:	60a2                	ld	ra,8(sp)
    80004070:	6402                	ld	s0,0(sp)
    80004072:	0141                	addi	sp,sp,16
    80004074:	8082                	ret

0000000080004076 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004076:	1101                	addi	sp,sp,-32
    80004078:	ec06                	sd	ra,24(sp)
    8000407a:	e822                	sd	s0,16(sp)
    8000407c:	e426                	sd	s1,8(sp)
    8000407e:	e04a                	sd	s2,0(sp)
    80004080:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004082:	0001d917          	auipc	s2,0x1d
    80004086:	1ee90913          	addi	s2,s2,494 # 80021270 <log>
    8000408a:	01892583          	lw	a1,24(s2)
    8000408e:	02892503          	lw	a0,40(s2)
    80004092:	fffff097          	auipc	ra,0xfffff
    80004096:	ff2080e7          	jalr	-14(ra) # 80003084 <bread>
    8000409a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000409c:	02c92683          	lw	a3,44(s2)
    800040a0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040a2:	02d05763          	blez	a3,800040d0 <write_head+0x5a>
    800040a6:	0001d797          	auipc	a5,0x1d
    800040aa:	1fa78793          	addi	a5,a5,506 # 800212a0 <log+0x30>
    800040ae:	05c50713          	addi	a4,a0,92
    800040b2:	36fd                	addiw	a3,a3,-1
    800040b4:	1682                	slli	a3,a3,0x20
    800040b6:	9281                	srli	a3,a3,0x20
    800040b8:	068a                	slli	a3,a3,0x2
    800040ba:	0001d617          	auipc	a2,0x1d
    800040be:	1ea60613          	addi	a2,a2,490 # 800212a4 <log+0x34>
    800040c2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040c4:	4390                	lw	a2,0(a5)
    800040c6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040c8:	0791                	addi	a5,a5,4
    800040ca:	0711                	addi	a4,a4,4
    800040cc:	fed79ce3          	bne	a5,a3,800040c4 <write_head+0x4e>
  }
  bwrite(buf);
    800040d0:	8526                	mv	a0,s1
    800040d2:	fffff097          	auipc	ra,0xfffff
    800040d6:	0a4080e7          	jalr	164(ra) # 80003176 <bwrite>
  brelse(buf);
    800040da:	8526                	mv	a0,s1
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	0d8080e7          	jalr	216(ra) # 800031b4 <brelse>
}
    800040e4:	60e2                	ld	ra,24(sp)
    800040e6:	6442                	ld	s0,16(sp)
    800040e8:	64a2                	ld	s1,8(sp)
    800040ea:	6902                	ld	s2,0(sp)
    800040ec:	6105                	addi	sp,sp,32
    800040ee:	8082                	ret

00000000800040f0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040f0:	0001d797          	auipc	a5,0x1d
    800040f4:	1ac7a783          	lw	a5,428(a5) # 8002129c <log+0x2c>
    800040f8:	0af05d63          	blez	a5,800041b2 <install_trans+0xc2>
{
    800040fc:	7139                	addi	sp,sp,-64
    800040fe:	fc06                	sd	ra,56(sp)
    80004100:	f822                	sd	s0,48(sp)
    80004102:	f426                	sd	s1,40(sp)
    80004104:	f04a                	sd	s2,32(sp)
    80004106:	ec4e                	sd	s3,24(sp)
    80004108:	e852                	sd	s4,16(sp)
    8000410a:	e456                	sd	s5,8(sp)
    8000410c:	e05a                	sd	s6,0(sp)
    8000410e:	0080                	addi	s0,sp,64
    80004110:	8b2a                	mv	s6,a0
    80004112:	0001da97          	auipc	s5,0x1d
    80004116:	18ea8a93          	addi	s5,s5,398 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000411a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000411c:	0001d997          	auipc	s3,0x1d
    80004120:	15498993          	addi	s3,s3,340 # 80021270 <log>
    80004124:	a035                	j	80004150 <install_trans+0x60>
      bunpin(dbuf);
    80004126:	8526                	mv	a0,s1
    80004128:	fffff097          	auipc	ra,0xfffff
    8000412c:	166080e7          	jalr	358(ra) # 8000328e <bunpin>
    brelse(lbuf);
    80004130:	854a                	mv	a0,s2
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	082080e7          	jalr	130(ra) # 800031b4 <brelse>
    brelse(dbuf);
    8000413a:	8526                	mv	a0,s1
    8000413c:	fffff097          	auipc	ra,0xfffff
    80004140:	078080e7          	jalr	120(ra) # 800031b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004144:	2a05                	addiw	s4,s4,1
    80004146:	0a91                	addi	s5,s5,4
    80004148:	02c9a783          	lw	a5,44(s3)
    8000414c:	04fa5963          	bge	s4,a5,8000419e <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004150:	0189a583          	lw	a1,24(s3)
    80004154:	014585bb          	addw	a1,a1,s4
    80004158:	2585                	addiw	a1,a1,1
    8000415a:	0289a503          	lw	a0,40(s3)
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	f26080e7          	jalr	-218(ra) # 80003084 <bread>
    80004166:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004168:	000aa583          	lw	a1,0(s5)
    8000416c:	0289a503          	lw	a0,40(s3)
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	f14080e7          	jalr	-236(ra) # 80003084 <bread>
    80004178:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000417a:	40000613          	li	a2,1024
    8000417e:	05890593          	addi	a1,s2,88
    80004182:	05850513          	addi	a0,a0,88
    80004186:	ffffd097          	auipc	ra,0xffffd
    8000418a:	bba080e7          	jalr	-1094(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000418e:	8526                	mv	a0,s1
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	fe6080e7          	jalr	-26(ra) # 80003176 <bwrite>
    if(recovering == 0)
    80004198:	f80b1ce3          	bnez	s6,80004130 <install_trans+0x40>
    8000419c:	b769                	j	80004126 <install_trans+0x36>
}
    8000419e:	70e2                	ld	ra,56(sp)
    800041a0:	7442                	ld	s0,48(sp)
    800041a2:	74a2                	ld	s1,40(sp)
    800041a4:	7902                	ld	s2,32(sp)
    800041a6:	69e2                	ld	s3,24(sp)
    800041a8:	6a42                	ld	s4,16(sp)
    800041aa:	6aa2                	ld	s5,8(sp)
    800041ac:	6b02                	ld	s6,0(sp)
    800041ae:	6121                	addi	sp,sp,64
    800041b0:	8082                	ret
    800041b2:	8082                	ret

00000000800041b4 <initlog>:
{
    800041b4:	7179                	addi	sp,sp,-48
    800041b6:	f406                	sd	ra,40(sp)
    800041b8:	f022                	sd	s0,32(sp)
    800041ba:	ec26                	sd	s1,24(sp)
    800041bc:	e84a                	sd	s2,16(sp)
    800041be:	e44e                	sd	s3,8(sp)
    800041c0:	1800                	addi	s0,sp,48
    800041c2:	892a                	mv	s2,a0
    800041c4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041c6:	0001d497          	auipc	s1,0x1d
    800041ca:	0aa48493          	addi	s1,s1,170 # 80021270 <log>
    800041ce:	00004597          	auipc	a1,0x4
    800041d2:	4a258593          	addi	a1,a1,1186 # 80008670 <syscalls+0x1e8>
    800041d6:	8526                	mv	a0,s1
    800041d8:	ffffd097          	auipc	ra,0xffffd
    800041dc:	97c080e7          	jalr	-1668(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800041e0:	0149a583          	lw	a1,20(s3)
    800041e4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041e6:	0109a783          	lw	a5,16(s3)
    800041ea:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041ec:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041f0:	854a                	mv	a0,s2
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	e92080e7          	jalr	-366(ra) # 80003084 <bread>
  log.lh.n = lh->n;
    800041fa:	4d3c                	lw	a5,88(a0)
    800041fc:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041fe:	02f05563          	blez	a5,80004228 <initlog+0x74>
    80004202:	05c50713          	addi	a4,a0,92
    80004206:	0001d697          	auipc	a3,0x1d
    8000420a:	09a68693          	addi	a3,a3,154 # 800212a0 <log+0x30>
    8000420e:	37fd                	addiw	a5,a5,-1
    80004210:	1782                	slli	a5,a5,0x20
    80004212:	9381                	srli	a5,a5,0x20
    80004214:	078a                	slli	a5,a5,0x2
    80004216:	06050613          	addi	a2,a0,96
    8000421a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000421c:	4310                	lw	a2,0(a4)
    8000421e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004220:	0711                	addi	a4,a4,4
    80004222:	0691                	addi	a3,a3,4
    80004224:	fef71ce3          	bne	a4,a5,8000421c <initlog+0x68>
  brelse(buf);
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	f8c080e7          	jalr	-116(ra) # 800031b4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004230:	4505                	li	a0,1
    80004232:	00000097          	auipc	ra,0x0
    80004236:	ebe080e7          	jalr	-322(ra) # 800040f0 <install_trans>
  log.lh.n = 0;
    8000423a:	0001d797          	auipc	a5,0x1d
    8000423e:	0607a123          	sw	zero,98(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004242:	00000097          	auipc	ra,0x0
    80004246:	e34080e7          	jalr	-460(ra) # 80004076 <write_head>
}
    8000424a:	70a2                	ld	ra,40(sp)
    8000424c:	7402                	ld	s0,32(sp)
    8000424e:	64e2                	ld	s1,24(sp)
    80004250:	6942                	ld	s2,16(sp)
    80004252:	69a2                	ld	s3,8(sp)
    80004254:	6145                	addi	sp,sp,48
    80004256:	8082                	ret

0000000080004258 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004258:	1101                	addi	sp,sp,-32
    8000425a:	ec06                	sd	ra,24(sp)
    8000425c:	e822                	sd	s0,16(sp)
    8000425e:	e426                	sd	s1,8(sp)
    80004260:	e04a                	sd	s2,0(sp)
    80004262:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004264:	0001d517          	auipc	a0,0x1d
    80004268:	00c50513          	addi	a0,a0,12 # 80021270 <log>
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	978080e7          	jalr	-1672(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004274:	0001d497          	auipc	s1,0x1d
    80004278:	ffc48493          	addi	s1,s1,-4 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000427c:	4979                	li	s2,30
    8000427e:	a039                	j	8000428c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004280:	85a6                	mv	a1,s1
    80004282:	8526                	mv	a0,s1
    80004284:	ffffe097          	auipc	ra,0xffffe
    80004288:	f18080e7          	jalr	-232(ra) # 8000219c <sleep>
    if(log.committing){
    8000428c:	50dc                	lw	a5,36(s1)
    8000428e:	fbed                	bnez	a5,80004280 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004290:	509c                	lw	a5,32(s1)
    80004292:	0017871b          	addiw	a4,a5,1
    80004296:	0007069b          	sext.w	a3,a4
    8000429a:	0027179b          	slliw	a5,a4,0x2
    8000429e:	9fb9                	addw	a5,a5,a4
    800042a0:	0017979b          	slliw	a5,a5,0x1
    800042a4:	54d8                	lw	a4,44(s1)
    800042a6:	9fb9                	addw	a5,a5,a4
    800042a8:	00f95963          	bge	s2,a5,800042ba <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042ac:	85a6                	mv	a1,s1
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffe097          	auipc	ra,0xffffe
    800042b4:	eec080e7          	jalr	-276(ra) # 8000219c <sleep>
    800042b8:	bfd1                	j	8000428c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042ba:	0001d517          	auipc	a0,0x1d
    800042be:	fb650513          	addi	a0,a0,-74 # 80021270 <log>
    800042c2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	9d4080e7          	jalr	-1580(ra) # 80000c98 <release>
      break;
    }
  }
}
    800042cc:	60e2                	ld	ra,24(sp)
    800042ce:	6442                	ld	s0,16(sp)
    800042d0:	64a2                	ld	s1,8(sp)
    800042d2:	6902                	ld	s2,0(sp)
    800042d4:	6105                	addi	sp,sp,32
    800042d6:	8082                	ret

00000000800042d8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042d8:	7139                	addi	sp,sp,-64
    800042da:	fc06                	sd	ra,56(sp)
    800042dc:	f822                	sd	s0,48(sp)
    800042de:	f426                	sd	s1,40(sp)
    800042e0:	f04a                	sd	s2,32(sp)
    800042e2:	ec4e                	sd	s3,24(sp)
    800042e4:	e852                	sd	s4,16(sp)
    800042e6:	e456                	sd	s5,8(sp)
    800042e8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042ea:	0001d497          	auipc	s1,0x1d
    800042ee:	f8648493          	addi	s1,s1,-122 # 80021270 <log>
    800042f2:	8526                	mv	a0,s1
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	8f0080e7          	jalr	-1808(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800042fc:	509c                	lw	a5,32(s1)
    800042fe:	37fd                	addiw	a5,a5,-1
    80004300:	0007891b          	sext.w	s2,a5
    80004304:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004306:	50dc                	lw	a5,36(s1)
    80004308:	efb9                	bnez	a5,80004366 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000430a:	06091663          	bnez	s2,80004376 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000430e:	0001d497          	auipc	s1,0x1d
    80004312:	f6248493          	addi	s1,s1,-158 # 80021270 <log>
    80004316:	4785                	li	a5,1
    80004318:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000431a:	8526                	mv	a0,s1
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	97c080e7          	jalr	-1668(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004324:	54dc                	lw	a5,44(s1)
    80004326:	06f04763          	bgtz	a5,80004394 <end_op+0xbc>
    acquire(&log.lock);
    8000432a:	0001d497          	auipc	s1,0x1d
    8000432e:	f4648493          	addi	s1,s1,-186 # 80021270 <log>
    80004332:	8526                	mv	a0,s1
    80004334:	ffffd097          	auipc	ra,0xffffd
    80004338:	8b0080e7          	jalr	-1872(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000433c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004340:	8526                	mv	a0,s1
    80004342:	ffffe097          	auipc	ra,0xffffe
    80004346:	0ce080e7          	jalr	206(ra) # 80002410 <wakeup>
    release(&log.lock);
    8000434a:	8526                	mv	a0,s1
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	94c080e7          	jalr	-1716(ra) # 80000c98 <release>
}
    80004354:	70e2                	ld	ra,56(sp)
    80004356:	7442                	ld	s0,48(sp)
    80004358:	74a2                	ld	s1,40(sp)
    8000435a:	7902                	ld	s2,32(sp)
    8000435c:	69e2                	ld	s3,24(sp)
    8000435e:	6a42                	ld	s4,16(sp)
    80004360:	6aa2                	ld	s5,8(sp)
    80004362:	6121                	addi	sp,sp,64
    80004364:	8082                	ret
    panic("log.committing");
    80004366:	00004517          	auipc	a0,0x4
    8000436a:	31250513          	addi	a0,a0,786 # 80008678 <syscalls+0x1f0>
    8000436e:	ffffc097          	auipc	ra,0xffffc
    80004372:	1d0080e7          	jalr	464(ra) # 8000053e <panic>
    wakeup(&log);
    80004376:	0001d497          	auipc	s1,0x1d
    8000437a:	efa48493          	addi	s1,s1,-262 # 80021270 <log>
    8000437e:	8526                	mv	a0,s1
    80004380:	ffffe097          	auipc	ra,0xffffe
    80004384:	090080e7          	jalr	144(ra) # 80002410 <wakeup>
  release(&log.lock);
    80004388:	8526                	mv	a0,s1
    8000438a:	ffffd097          	auipc	ra,0xffffd
    8000438e:	90e080e7          	jalr	-1778(ra) # 80000c98 <release>
  if(do_commit){
    80004392:	b7c9                	j	80004354 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004394:	0001da97          	auipc	s5,0x1d
    80004398:	f0ca8a93          	addi	s5,s5,-244 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000439c:	0001da17          	auipc	s4,0x1d
    800043a0:	ed4a0a13          	addi	s4,s4,-300 # 80021270 <log>
    800043a4:	018a2583          	lw	a1,24(s4)
    800043a8:	012585bb          	addw	a1,a1,s2
    800043ac:	2585                	addiw	a1,a1,1
    800043ae:	028a2503          	lw	a0,40(s4)
    800043b2:	fffff097          	auipc	ra,0xfffff
    800043b6:	cd2080e7          	jalr	-814(ra) # 80003084 <bread>
    800043ba:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043bc:	000aa583          	lw	a1,0(s5)
    800043c0:	028a2503          	lw	a0,40(s4)
    800043c4:	fffff097          	auipc	ra,0xfffff
    800043c8:	cc0080e7          	jalr	-832(ra) # 80003084 <bread>
    800043cc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043ce:	40000613          	li	a2,1024
    800043d2:	05850593          	addi	a1,a0,88
    800043d6:	05848513          	addi	a0,s1,88
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	966080e7          	jalr	-1690(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800043e2:	8526                	mv	a0,s1
    800043e4:	fffff097          	auipc	ra,0xfffff
    800043e8:	d92080e7          	jalr	-622(ra) # 80003176 <bwrite>
    brelse(from);
    800043ec:	854e                	mv	a0,s3
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	dc6080e7          	jalr	-570(ra) # 800031b4 <brelse>
    brelse(to);
    800043f6:	8526                	mv	a0,s1
    800043f8:	fffff097          	auipc	ra,0xfffff
    800043fc:	dbc080e7          	jalr	-580(ra) # 800031b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004400:	2905                	addiw	s2,s2,1
    80004402:	0a91                	addi	s5,s5,4
    80004404:	02ca2783          	lw	a5,44(s4)
    80004408:	f8f94ee3          	blt	s2,a5,800043a4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000440c:	00000097          	auipc	ra,0x0
    80004410:	c6a080e7          	jalr	-918(ra) # 80004076 <write_head>
    install_trans(0); // Now install writes to home locations
    80004414:	4501                	li	a0,0
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	cda080e7          	jalr	-806(ra) # 800040f0 <install_trans>
    log.lh.n = 0;
    8000441e:	0001d797          	auipc	a5,0x1d
    80004422:	e607af23          	sw	zero,-386(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004426:	00000097          	auipc	ra,0x0
    8000442a:	c50080e7          	jalr	-944(ra) # 80004076 <write_head>
    8000442e:	bdf5                	j	8000432a <end_op+0x52>

0000000080004430 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004430:	1101                	addi	sp,sp,-32
    80004432:	ec06                	sd	ra,24(sp)
    80004434:	e822                	sd	s0,16(sp)
    80004436:	e426                	sd	s1,8(sp)
    80004438:	e04a                	sd	s2,0(sp)
    8000443a:	1000                	addi	s0,sp,32
    8000443c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000443e:	0001d917          	auipc	s2,0x1d
    80004442:	e3290913          	addi	s2,s2,-462 # 80021270 <log>
    80004446:	854a                	mv	a0,s2
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	79c080e7          	jalr	1948(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004450:	02c92603          	lw	a2,44(s2)
    80004454:	47f5                	li	a5,29
    80004456:	06c7c563          	blt	a5,a2,800044c0 <log_write+0x90>
    8000445a:	0001d797          	auipc	a5,0x1d
    8000445e:	e327a783          	lw	a5,-462(a5) # 8002128c <log+0x1c>
    80004462:	37fd                	addiw	a5,a5,-1
    80004464:	04f65e63          	bge	a2,a5,800044c0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004468:	0001d797          	auipc	a5,0x1d
    8000446c:	e287a783          	lw	a5,-472(a5) # 80021290 <log+0x20>
    80004470:	06f05063          	blez	a5,800044d0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004474:	4781                	li	a5,0
    80004476:	06c05563          	blez	a2,800044e0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000447a:	44cc                	lw	a1,12(s1)
    8000447c:	0001d717          	auipc	a4,0x1d
    80004480:	e2470713          	addi	a4,a4,-476 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004484:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004486:	4314                	lw	a3,0(a4)
    80004488:	04b68c63          	beq	a3,a1,800044e0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000448c:	2785                	addiw	a5,a5,1
    8000448e:	0711                	addi	a4,a4,4
    80004490:	fef61be3          	bne	a2,a5,80004486 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004494:	0621                	addi	a2,a2,8
    80004496:	060a                	slli	a2,a2,0x2
    80004498:	0001d797          	auipc	a5,0x1d
    8000449c:	dd878793          	addi	a5,a5,-552 # 80021270 <log>
    800044a0:	963e                	add	a2,a2,a5
    800044a2:	44dc                	lw	a5,12(s1)
    800044a4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044a6:	8526                	mv	a0,s1
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	daa080e7          	jalr	-598(ra) # 80003252 <bpin>
    log.lh.n++;
    800044b0:	0001d717          	auipc	a4,0x1d
    800044b4:	dc070713          	addi	a4,a4,-576 # 80021270 <log>
    800044b8:	575c                	lw	a5,44(a4)
    800044ba:	2785                	addiw	a5,a5,1
    800044bc:	d75c                	sw	a5,44(a4)
    800044be:	a835                	j	800044fa <log_write+0xca>
    panic("too big a transaction");
    800044c0:	00004517          	auipc	a0,0x4
    800044c4:	1c850513          	addi	a0,a0,456 # 80008688 <syscalls+0x200>
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	076080e7          	jalr	118(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044d0:	00004517          	auipc	a0,0x4
    800044d4:	1d050513          	addi	a0,a0,464 # 800086a0 <syscalls+0x218>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	066080e7          	jalr	102(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044e0:	00878713          	addi	a4,a5,8
    800044e4:	00271693          	slli	a3,a4,0x2
    800044e8:	0001d717          	auipc	a4,0x1d
    800044ec:	d8870713          	addi	a4,a4,-632 # 80021270 <log>
    800044f0:	9736                	add	a4,a4,a3
    800044f2:	44d4                	lw	a3,12(s1)
    800044f4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044f6:	faf608e3          	beq	a2,a5,800044a6 <log_write+0x76>
  }
  release(&log.lock);
    800044fa:	0001d517          	auipc	a0,0x1d
    800044fe:	d7650513          	addi	a0,a0,-650 # 80021270 <log>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	796080e7          	jalr	1942(ra) # 80000c98 <release>
}
    8000450a:	60e2                	ld	ra,24(sp)
    8000450c:	6442                	ld	s0,16(sp)
    8000450e:	64a2                	ld	s1,8(sp)
    80004510:	6902                	ld	s2,0(sp)
    80004512:	6105                	addi	sp,sp,32
    80004514:	8082                	ret

0000000080004516 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004516:	1101                	addi	sp,sp,-32
    80004518:	ec06                	sd	ra,24(sp)
    8000451a:	e822                	sd	s0,16(sp)
    8000451c:	e426                	sd	s1,8(sp)
    8000451e:	e04a                	sd	s2,0(sp)
    80004520:	1000                	addi	s0,sp,32
    80004522:	84aa                	mv	s1,a0
    80004524:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004526:	00004597          	auipc	a1,0x4
    8000452a:	19a58593          	addi	a1,a1,410 # 800086c0 <syscalls+0x238>
    8000452e:	0521                	addi	a0,a0,8
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	624080e7          	jalr	1572(ra) # 80000b54 <initlock>
  lk->name = name;
    80004538:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000453c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004540:	0204a423          	sw	zero,40(s1)
}
    80004544:	60e2                	ld	ra,24(sp)
    80004546:	6442                	ld	s0,16(sp)
    80004548:	64a2                	ld	s1,8(sp)
    8000454a:	6902                	ld	s2,0(sp)
    8000454c:	6105                	addi	sp,sp,32
    8000454e:	8082                	ret

0000000080004550 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004550:	1101                	addi	sp,sp,-32
    80004552:	ec06                	sd	ra,24(sp)
    80004554:	e822                	sd	s0,16(sp)
    80004556:	e426                	sd	s1,8(sp)
    80004558:	e04a                	sd	s2,0(sp)
    8000455a:	1000                	addi	s0,sp,32
    8000455c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000455e:	00850913          	addi	s2,a0,8
    80004562:	854a                	mv	a0,s2
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	680080e7          	jalr	1664(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000456c:	409c                	lw	a5,0(s1)
    8000456e:	cb89                	beqz	a5,80004580 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004570:	85ca                	mv	a1,s2
    80004572:	8526                	mv	a0,s1
    80004574:	ffffe097          	auipc	ra,0xffffe
    80004578:	c28080e7          	jalr	-984(ra) # 8000219c <sleep>
  while (lk->locked) {
    8000457c:	409c                	lw	a5,0(s1)
    8000457e:	fbed                	bnez	a5,80004570 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004580:	4785                	li	a5,1
    80004582:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004584:	ffffd097          	auipc	ra,0xffffd
    80004588:	55c080e7          	jalr	1372(ra) # 80001ae0 <myproc>
    8000458c:	591c                	lw	a5,48(a0)
    8000458e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004590:	854a                	mv	a0,s2
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	706080e7          	jalr	1798(ra) # 80000c98 <release>
}
    8000459a:	60e2                	ld	ra,24(sp)
    8000459c:	6442                	ld	s0,16(sp)
    8000459e:	64a2                	ld	s1,8(sp)
    800045a0:	6902                	ld	s2,0(sp)
    800045a2:	6105                	addi	sp,sp,32
    800045a4:	8082                	ret

00000000800045a6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045a6:	1101                	addi	sp,sp,-32
    800045a8:	ec06                	sd	ra,24(sp)
    800045aa:	e822                	sd	s0,16(sp)
    800045ac:	e426                	sd	s1,8(sp)
    800045ae:	e04a                	sd	s2,0(sp)
    800045b0:	1000                	addi	s0,sp,32
    800045b2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045b4:	00850913          	addi	s2,a0,8
    800045b8:	854a                	mv	a0,s2
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	62a080e7          	jalr	1578(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800045c2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045c6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045ca:	8526                	mv	a0,s1
    800045cc:	ffffe097          	auipc	ra,0xffffe
    800045d0:	e44080e7          	jalr	-444(ra) # 80002410 <wakeup>
  release(&lk->lk);
    800045d4:	854a                	mv	a0,s2
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6c2080e7          	jalr	1730(ra) # 80000c98 <release>
}
    800045de:	60e2                	ld	ra,24(sp)
    800045e0:	6442                	ld	s0,16(sp)
    800045e2:	64a2                	ld	s1,8(sp)
    800045e4:	6902                	ld	s2,0(sp)
    800045e6:	6105                	addi	sp,sp,32
    800045e8:	8082                	ret

00000000800045ea <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045ea:	7179                	addi	sp,sp,-48
    800045ec:	f406                	sd	ra,40(sp)
    800045ee:	f022                	sd	s0,32(sp)
    800045f0:	ec26                	sd	s1,24(sp)
    800045f2:	e84a                	sd	s2,16(sp)
    800045f4:	e44e                	sd	s3,8(sp)
    800045f6:	1800                	addi	s0,sp,48
    800045f8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045fa:	00850913          	addi	s2,a0,8
    800045fe:	854a                	mv	a0,s2
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004608:	409c                	lw	a5,0(s1)
    8000460a:	ef99                	bnez	a5,80004628 <holdingsleep+0x3e>
    8000460c:	4481                	li	s1,0
  release(&lk->lk);
    8000460e:	854a                	mv	a0,s2
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	688080e7          	jalr	1672(ra) # 80000c98 <release>
  return r;
}
    80004618:	8526                	mv	a0,s1
    8000461a:	70a2                	ld	ra,40(sp)
    8000461c:	7402                	ld	s0,32(sp)
    8000461e:	64e2                	ld	s1,24(sp)
    80004620:	6942                	ld	s2,16(sp)
    80004622:	69a2                	ld	s3,8(sp)
    80004624:	6145                	addi	sp,sp,48
    80004626:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004628:	0284a983          	lw	s3,40(s1)
    8000462c:	ffffd097          	auipc	ra,0xffffd
    80004630:	4b4080e7          	jalr	1204(ra) # 80001ae0 <myproc>
    80004634:	5904                	lw	s1,48(a0)
    80004636:	413484b3          	sub	s1,s1,s3
    8000463a:	0014b493          	seqz	s1,s1
    8000463e:	bfc1                	j	8000460e <holdingsleep+0x24>

0000000080004640 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004640:	1141                	addi	sp,sp,-16
    80004642:	e406                	sd	ra,8(sp)
    80004644:	e022                	sd	s0,0(sp)
    80004646:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004648:	00004597          	auipc	a1,0x4
    8000464c:	08858593          	addi	a1,a1,136 # 800086d0 <syscalls+0x248>
    80004650:	0001d517          	auipc	a0,0x1d
    80004654:	d6850513          	addi	a0,a0,-664 # 800213b8 <ftable>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	4fc080e7          	jalr	1276(ra) # 80000b54 <initlock>
}
    80004660:	60a2                	ld	ra,8(sp)
    80004662:	6402                	ld	s0,0(sp)
    80004664:	0141                	addi	sp,sp,16
    80004666:	8082                	ret

0000000080004668 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004668:	1101                	addi	sp,sp,-32
    8000466a:	ec06                	sd	ra,24(sp)
    8000466c:	e822                	sd	s0,16(sp)
    8000466e:	e426                	sd	s1,8(sp)
    80004670:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004672:	0001d517          	auipc	a0,0x1d
    80004676:	d4650513          	addi	a0,a0,-698 # 800213b8 <ftable>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	56a080e7          	jalr	1386(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004682:	0001d497          	auipc	s1,0x1d
    80004686:	d4e48493          	addi	s1,s1,-690 # 800213d0 <ftable+0x18>
    8000468a:	0001e717          	auipc	a4,0x1e
    8000468e:	ce670713          	addi	a4,a4,-794 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004692:	40dc                	lw	a5,4(s1)
    80004694:	cf99                	beqz	a5,800046b2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004696:	02848493          	addi	s1,s1,40
    8000469a:	fee49ce3          	bne	s1,a4,80004692 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000469e:	0001d517          	auipc	a0,0x1d
    800046a2:	d1a50513          	addi	a0,a0,-742 # 800213b8 <ftable>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	5f2080e7          	jalr	1522(ra) # 80000c98 <release>
  return 0;
    800046ae:	4481                	li	s1,0
    800046b0:	a819                	j	800046c6 <filealloc+0x5e>
      f->ref = 1;
    800046b2:	4785                	li	a5,1
    800046b4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046b6:	0001d517          	auipc	a0,0x1d
    800046ba:	d0250513          	addi	a0,a0,-766 # 800213b8 <ftable>
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	5da080e7          	jalr	1498(ra) # 80000c98 <release>
}
    800046c6:	8526                	mv	a0,s1
    800046c8:	60e2                	ld	ra,24(sp)
    800046ca:	6442                	ld	s0,16(sp)
    800046cc:	64a2                	ld	s1,8(sp)
    800046ce:	6105                	addi	sp,sp,32
    800046d0:	8082                	ret

00000000800046d2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046d2:	1101                	addi	sp,sp,-32
    800046d4:	ec06                	sd	ra,24(sp)
    800046d6:	e822                	sd	s0,16(sp)
    800046d8:	e426                	sd	s1,8(sp)
    800046da:	1000                	addi	s0,sp,32
    800046dc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046de:	0001d517          	auipc	a0,0x1d
    800046e2:	cda50513          	addi	a0,a0,-806 # 800213b8 <ftable>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	4fe080e7          	jalr	1278(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046ee:	40dc                	lw	a5,4(s1)
    800046f0:	02f05263          	blez	a5,80004714 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046f4:	2785                	addiw	a5,a5,1
    800046f6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046f8:	0001d517          	auipc	a0,0x1d
    800046fc:	cc050513          	addi	a0,a0,-832 # 800213b8 <ftable>
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	598080e7          	jalr	1432(ra) # 80000c98 <release>
  return f;
}
    80004708:	8526                	mv	a0,s1
    8000470a:	60e2                	ld	ra,24(sp)
    8000470c:	6442                	ld	s0,16(sp)
    8000470e:	64a2                	ld	s1,8(sp)
    80004710:	6105                	addi	sp,sp,32
    80004712:	8082                	ret
    panic("filedup");
    80004714:	00004517          	auipc	a0,0x4
    80004718:	fc450513          	addi	a0,a0,-60 # 800086d8 <syscalls+0x250>
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	e22080e7          	jalr	-478(ra) # 8000053e <panic>

0000000080004724 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004724:	7139                	addi	sp,sp,-64
    80004726:	fc06                	sd	ra,56(sp)
    80004728:	f822                	sd	s0,48(sp)
    8000472a:	f426                	sd	s1,40(sp)
    8000472c:	f04a                	sd	s2,32(sp)
    8000472e:	ec4e                	sd	s3,24(sp)
    80004730:	e852                	sd	s4,16(sp)
    80004732:	e456                	sd	s5,8(sp)
    80004734:	0080                	addi	s0,sp,64
    80004736:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004738:	0001d517          	auipc	a0,0x1d
    8000473c:	c8050513          	addi	a0,a0,-896 # 800213b8 <ftable>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	4a4080e7          	jalr	1188(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004748:	40dc                	lw	a5,4(s1)
    8000474a:	06f05163          	blez	a5,800047ac <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000474e:	37fd                	addiw	a5,a5,-1
    80004750:	0007871b          	sext.w	a4,a5
    80004754:	c0dc                	sw	a5,4(s1)
    80004756:	06e04363          	bgtz	a4,800047bc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000475a:	0004a903          	lw	s2,0(s1)
    8000475e:	0094ca83          	lbu	s5,9(s1)
    80004762:	0104ba03          	ld	s4,16(s1)
    80004766:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000476a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000476e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004772:	0001d517          	auipc	a0,0x1d
    80004776:	c4650513          	addi	a0,a0,-954 # 800213b8 <ftable>
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	51e080e7          	jalr	1310(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004782:	4785                	li	a5,1
    80004784:	04f90d63          	beq	s2,a5,800047de <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004788:	3979                	addiw	s2,s2,-2
    8000478a:	4785                	li	a5,1
    8000478c:	0527e063          	bltu	a5,s2,800047cc <fileclose+0xa8>
    begin_op();
    80004790:	00000097          	auipc	ra,0x0
    80004794:	ac8080e7          	jalr	-1336(ra) # 80004258 <begin_op>
    iput(ff.ip);
    80004798:	854e                	mv	a0,s3
    8000479a:	fffff097          	auipc	ra,0xfffff
    8000479e:	2a6080e7          	jalr	678(ra) # 80003a40 <iput>
    end_op();
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	b36080e7          	jalr	-1226(ra) # 800042d8 <end_op>
    800047aa:	a00d                	j	800047cc <fileclose+0xa8>
    panic("fileclose");
    800047ac:	00004517          	auipc	a0,0x4
    800047b0:	f3450513          	addi	a0,a0,-204 # 800086e0 <syscalls+0x258>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047bc:	0001d517          	auipc	a0,0x1d
    800047c0:	bfc50513          	addi	a0,a0,-1028 # 800213b8 <ftable>
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	4d4080e7          	jalr	1236(ra) # 80000c98 <release>
  }
}
    800047cc:	70e2                	ld	ra,56(sp)
    800047ce:	7442                	ld	s0,48(sp)
    800047d0:	74a2                	ld	s1,40(sp)
    800047d2:	7902                	ld	s2,32(sp)
    800047d4:	69e2                	ld	s3,24(sp)
    800047d6:	6a42                	ld	s4,16(sp)
    800047d8:	6aa2                	ld	s5,8(sp)
    800047da:	6121                	addi	sp,sp,64
    800047dc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047de:	85d6                	mv	a1,s5
    800047e0:	8552                	mv	a0,s4
    800047e2:	00000097          	auipc	ra,0x0
    800047e6:	34c080e7          	jalr	844(ra) # 80004b2e <pipeclose>
    800047ea:	b7cd                	j	800047cc <fileclose+0xa8>

00000000800047ec <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047ec:	715d                	addi	sp,sp,-80
    800047ee:	e486                	sd	ra,72(sp)
    800047f0:	e0a2                	sd	s0,64(sp)
    800047f2:	fc26                	sd	s1,56(sp)
    800047f4:	f84a                	sd	s2,48(sp)
    800047f6:	f44e                	sd	s3,40(sp)
    800047f8:	0880                	addi	s0,sp,80
    800047fa:	84aa                	mv	s1,a0
    800047fc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047fe:	ffffd097          	auipc	ra,0xffffd
    80004802:	2e2080e7          	jalr	738(ra) # 80001ae0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004806:	409c                	lw	a5,0(s1)
    80004808:	37f9                	addiw	a5,a5,-2
    8000480a:	4705                	li	a4,1
    8000480c:	04f76763          	bltu	a4,a5,8000485a <filestat+0x6e>
    80004810:	892a                	mv	s2,a0
    ilock(f->ip);
    80004812:	6c88                	ld	a0,24(s1)
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	072080e7          	jalr	114(ra) # 80003886 <ilock>
    stati(f->ip, &st);
    8000481c:	fb840593          	addi	a1,s0,-72
    80004820:	6c88                	ld	a0,24(s1)
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	2ee080e7          	jalr	750(ra) # 80003b10 <stati>
    iunlock(f->ip);
    8000482a:	6c88                	ld	a0,24(s1)
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	11c080e7          	jalr	284(ra) # 80003948 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004834:	46e1                	li	a3,24
    80004836:	fb840613          	addi	a2,s0,-72
    8000483a:	85ce                	mv	a1,s3
    8000483c:	05093503          	ld	a0,80(s2)
    80004840:	ffffd097          	auipc	ra,0xffffd
    80004844:	f62080e7          	jalr	-158(ra) # 800017a2 <copyout>
    80004848:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000484c:	60a6                	ld	ra,72(sp)
    8000484e:	6406                	ld	s0,64(sp)
    80004850:	74e2                	ld	s1,56(sp)
    80004852:	7942                	ld	s2,48(sp)
    80004854:	79a2                	ld	s3,40(sp)
    80004856:	6161                	addi	sp,sp,80
    80004858:	8082                	ret
  return -1;
    8000485a:	557d                	li	a0,-1
    8000485c:	bfc5                	j	8000484c <filestat+0x60>

000000008000485e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000485e:	7179                	addi	sp,sp,-48
    80004860:	f406                	sd	ra,40(sp)
    80004862:	f022                	sd	s0,32(sp)
    80004864:	ec26                	sd	s1,24(sp)
    80004866:	e84a                	sd	s2,16(sp)
    80004868:	e44e                	sd	s3,8(sp)
    8000486a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000486c:	00854783          	lbu	a5,8(a0)
    80004870:	c3d5                	beqz	a5,80004914 <fileread+0xb6>
    80004872:	84aa                	mv	s1,a0
    80004874:	89ae                	mv	s3,a1
    80004876:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004878:	411c                	lw	a5,0(a0)
    8000487a:	4705                	li	a4,1
    8000487c:	04e78963          	beq	a5,a4,800048ce <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004880:	470d                	li	a4,3
    80004882:	04e78d63          	beq	a5,a4,800048dc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004886:	4709                	li	a4,2
    80004888:	06e79e63          	bne	a5,a4,80004904 <fileread+0xa6>
    ilock(f->ip);
    8000488c:	6d08                	ld	a0,24(a0)
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	ff8080e7          	jalr	-8(ra) # 80003886 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004896:	874a                	mv	a4,s2
    80004898:	5094                	lw	a3,32(s1)
    8000489a:	864e                	mv	a2,s3
    8000489c:	4585                	li	a1,1
    8000489e:	6c88                	ld	a0,24(s1)
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	29a080e7          	jalr	666(ra) # 80003b3a <readi>
    800048a8:	892a                	mv	s2,a0
    800048aa:	00a05563          	blez	a0,800048b4 <fileread+0x56>
      f->off += r;
    800048ae:	509c                	lw	a5,32(s1)
    800048b0:	9fa9                	addw	a5,a5,a0
    800048b2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048b4:	6c88                	ld	a0,24(s1)
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	092080e7          	jalr	146(ra) # 80003948 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048be:	854a                	mv	a0,s2
    800048c0:	70a2                	ld	ra,40(sp)
    800048c2:	7402                	ld	s0,32(sp)
    800048c4:	64e2                	ld	s1,24(sp)
    800048c6:	6942                	ld	s2,16(sp)
    800048c8:	69a2                	ld	s3,8(sp)
    800048ca:	6145                	addi	sp,sp,48
    800048cc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048ce:	6908                	ld	a0,16(a0)
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	3c8080e7          	jalr	968(ra) # 80004c98 <piperead>
    800048d8:	892a                	mv	s2,a0
    800048da:	b7d5                	j	800048be <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048dc:	02451783          	lh	a5,36(a0)
    800048e0:	03079693          	slli	a3,a5,0x30
    800048e4:	92c1                	srli	a3,a3,0x30
    800048e6:	4725                	li	a4,9
    800048e8:	02d76863          	bltu	a4,a3,80004918 <fileread+0xba>
    800048ec:	0792                	slli	a5,a5,0x4
    800048ee:	0001d717          	auipc	a4,0x1d
    800048f2:	a2a70713          	addi	a4,a4,-1494 # 80021318 <devsw>
    800048f6:	97ba                	add	a5,a5,a4
    800048f8:	639c                	ld	a5,0(a5)
    800048fa:	c38d                	beqz	a5,8000491c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048fc:	4505                	li	a0,1
    800048fe:	9782                	jalr	a5
    80004900:	892a                	mv	s2,a0
    80004902:	bf75                	j	800048be <fileread+0x60>
    panic("fileread");
    80004904:	00004517          	auipc	a0,0x4
    80004908:	dec50513          	addi	a0,a0,-532 # 800086f0 <syscalls+0x268>
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	c32080e7          	jalr	-974(ra) # 8000053e <panic>
    return -1;
    80004914:	597d                	li	s2,-1
    80004916:	b765                	j	800048be <fileread+0x60>
      return -1;
    80004918:	597d                	li	s2,-1
    8000491a:	b755                	j	800048be <fileread+0x60>
    8000491c:	597d                	li	s2,-1
    8000491e:	b745                	j	800048be <fileread+0x60>

0000000080004920 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004920:	715d                	addi	sp,sp,-80
    80004922:	e486                	sd	ra,72(sp)
    80004924:	e0a2                	sd	s0,64(sp)
    80004926:	fc26                	sd	s1,56(sp)
    80004928:	f84a                	sd	s2,48(sp)
    8000492a:	f44e                	sd	s3,40(sp)
    8000492c:	f052                	sd	s4,32(sp)
    8000492e:	ec56                	sd	s5,24(sp)
    80004930:	e85a                	sd	s6,16(sp)
    80004932:	e45e                	sd	s7,8(sp)
    80004934:	e062                	sd	s8,0(sp)
    80004936:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004938:	00954783          	lbu	a5,9(a0)
    8000493c:	10078663          	beqz	a5,80004a48 <filewrite+0x128>
    80004940:	892a                	mv	s2,a0
    80004942:	8aae                	mv	s5,a1
    80004944:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004946:	411c                	lw	a5,0(a0)
    80004948:	4705                	li	a4,1
    8000494a:	02e78263          	beq	a5,a4,8000496e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000494e:	470d                	li	a4,3
    80004950:	02e78663          	beq	a5,a4,8000497c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004954:	4709                	li	a4,2
    80004956:	0ee79163          	bne	a5,a4,80004a38 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000495a:	0ac05d63          	blez	a2,80004a14 <filewrite+0xf4>
    int i = 0;
    8000495e:	4981                	li	s3,0
    80004960:	6b05                	lui	s6,0x1
    80004962:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004966:	6b85                	lui	s7,0x1
    80004968:	c00b8b9b          	addiw	s7,s7,-1024
    8000496c:	a861                	j	80004a04 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000496e:	6908                	ld	a0,16(a0)
    80004970:	00000097          	auipc	ra,0x0
    80004974:	22e080e7          	jalr	558(ra) # 80004b9e <pipewrite>
    80004978:	8a2a                	mv	s4,a0
    8000497a:	a045                	j	80004a1a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000497c:	02451783          	lh	a5,36(a0)
    80004980:	03079693          	slli	a3,a5,0x30
    80004984:	92c1                	srli	a3,a3,0x30
    80004986:	4725                	li	a4,9
    80004988:	0cd76263          	bltu	a4,a3,80004a4c <filewrite+0x12c>
    8000498c:	0792                	slli	a5,a5,0x4
    8000498e:	0001d717          	auipc	a4,0x1d
    80004992:	98a70713          	addi	a4,a4,-1654 # 80021318 <devsw>
    80004996:	97ba                	add	a5,a5,a4
    80004998:	679c                	ld	a5,8(a5)
    8000499a:	cbdd                	beqz	a5,80004a50 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000499c:	4505                	li	a0,1
    8000499e:	9782                	jalr	a5
    800049a0:	8a2a                	mv	s4,a0
    800049a2:	a8a5                	j	80004a1a <filewrite+0xfa>
    800049a4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	8b0080e7          	jalr	-1872(ra) # 80004258 <begin_op>
      ilock(f->ip);
    800049b0:	01893503          	ld	a0,24(s2)
    800049b4:	fffff097          	auipc	ra,0xfffff
    800049b8:	ed2080e7          	jalr	-302(ra) # 80003886 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049bc:	8762                	mv	a4,s8
    800049be:	02092683          	lw	a3,32(s2)
    800049c2:	01598633          	add	a2,s3,s5
    800049c6:	4585                	li	a1,1
    800049c8:	01893503          	ld	a0,24(s2)
    800049cc:	fffff097          	auipc	ra,0xfffff
    800049d0:	266080e7          	jalr	614(ra) # 80003c32 <writei>
    800049d4:	84aa                	mv	s1,a0
    800049d6:	00a05763          	blez	a0,800049e4 <filewrite+0xc4>
        f->off += r;
    800049da:	02092783          	lw	a5,32(s2)
    800049de:	9fa9                	addw	a5,a5,a0
    800049e0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049e4:	01893503          	ld	a0,24(s2)
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	f60080e7          	jalr	-160(ra) # 80003948 <iunlock>
      end_op();
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	8e8080e7          	jalr	-1816(ra) # 800042d8 <end_op>

      if(r != n1){
    800049f8:	009c1f63          	bne	s8,s1,80004a16 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049fc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a00:	0149db63          	bge	s3,s4,80004a16 <filewrite+0xf6>
      int n1 = n - i;
    80004a04:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a08:	84be                	mv	s1,a5
    80004a0a:	2781                	sext.w	a5,a5
    80004a0c:	f8fb5ce3          	bge	s6,a5,800049a4 <filewrite+0x84>
    80004a10:	84de                	mv	s1,s7
    80004a12:	bf49                	j	800049a4 <filewrite+0x84>
    int i = 0;
    80004a14:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a16:	013a1f63          	bne	s4,s3,80004a34 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a1a:	8552                	mv	a0,s4
    80004a1c:	60a6                	ld	ra,72(sp)
    80004a1e:	6406                	ld	s0,64(sp)
    80004a20:	74e2                	ld	s1,56(sp)
    80004a22:	7942                	ld	s2,48(sp)
    80004a24:	79a2                	ld	s3,40(sp)
    80004a26:	7a02                	ld	s4,32(sp)
    80004a28:	6ae2                	ld	s5,24(sp)
    80004a2a:	6b42                	ld	s6,16(sp)
    80004a2c:	6ba2                	ld	s7,8(sp)
    80004a2e:	6c02                	ld	s8,0(sp)
    80004a30:	6161                	addi	sp,sp,80
    80004a32:	8082                	ret
    ret = (i == n ? n : -1);
    80004a34:	5a7d                	li	s4,-1
    80004a36:	b7d5                	j	80004a1a <filewrite+0xfa>
    panic("filewrite");
    80004a38:	00004517          	auipc	a0,0x4
    80004a3c:	cc850513          	addi	a0,a0,-824 # 80008700 <syscalls+0x278>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	afe080e7          	jalr	-1282(ra) # 8000053e <panic>
    return -1;
    80004a48:	5a7d                	li	s4,-1
    80004a4a:	bfc1                	j	80004a1a <filewrite+0xfa>
      return -1;
    80004a4c:	5a7d                	li	s4,-1
    80004a4e:	b7f1                	j	80004a1a <filewrite+0xfa>
    80004a50:	5a7d                	li	s4,-1
    80004a52:	b7e1                	j	80004a1a <filewrite+0xfa>

0000000080004a54 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a54:	7179                	addi	sp,sp,-48
    80004a56:	f406                	sd	ra,40(sp)
    80004a58:	f022                	sd	s0,32(sp)
    80004a5a:	ec26                	sd	s1,24(sp)
    80004a5c:	e84a                	sd	s2,16(sp)
    80004a5e:	e44e                	sd	s3,8(sp)
    80004a60:	e052                	sd	s4,0(sp)
    80004a62:	1800                	addi	s0,sp,48
    80004a64:	84aa                	mv	s1,a0
    80004a66:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a68:	0005b023          	sd	zero,0(a1)
    80004a6c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a70:	00000097          	auipc	ra,0x0
    80004a74:	bf8080e7          	jalr	-1032(ra) # 80004668 <filealloc>
    80004a78:	e088                	sd	a0,0(s1)
    80004a7a:	c551                	beqz	a0,80004b06 <pipealloc+0xb2>
    80004a7c:	00000097          	auipc	ra,0x0
    80004a80:	bec080e7          	jalr	-1044(ra) # 80004668 <filealloc>
    80004a84:	00aa3023          	sd	a0,0(s4)
    80004a88:	c92d                	beqz	a0,80004afa <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	06a080e7          	jalr	106(ra) # 80000af4 <kalloc>
    80004a92:	892a                	mv	s2,a0
    80004a94:	c125                	beqz	a0,80004af4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a96:	4985                	li	s3,1
    80004a98:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a9c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aa0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004aa4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004aa8:	00004597          	auipc	a1,0x4
    80004aac:	c6858593          	addi	a1,a1,-920 # 80008710 <syscalls+0x288>
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	0a4080e7          	jalr	164(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004ab8:	609c                	ld	a5,0(s1)
    80004aba:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004abe:	609c                	ld	a5,0(s1)
    80004ac0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ac4:	609c                	ld	a5,0(s1)
    80004ac6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aca:	609c                	ld	a5,0(s1)
    80004acc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ad0:	000a3783          	ld	a5,0(s4)
    80004ad4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ad8:	000a3783          	ld	a5,0(s4)
    80004adc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ae0:	000a3783          	ld	a5,0(s4)
    80004ae4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ae8:	000a3783          	ld	a5,0(s4)
    80004aec:	0127b823          	sd	s2,16(a5)
  return 0;
    80004af0:	4501                	li	a0,0
    80004af2:	a025                	j	80004b1a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004af4:	6088                	ld	a0,0(s1)
    80004af6:	e501                	bnez	a0,80004afe <pipealloc+0xaa>
    80004af8:	a039                	j	80004b06 <pipealloc+0xb2>
    80004afa:	6088                	ld	a0,0(s1)
    80004afc:	c51d                	beqz	a0,80004b2a <pipealloc+0xd6>
    fileclose(*f0);
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	c26080e7          	jalr	-986(ra) # 80004724 <fileclose>
  if(*f1)
    80004b06:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b0a:	557d                	li	a0,-1
  if(*f1)
    80004b0c:	c799                	beqz	a5,80004b1a <pipealloc+0xc6>
    fileclose(*f1);
    80004b0e:	853e                	mv	a0,a5
    80004b10:	00000097          	auipc	ra,0x0
    80004b14:	c14080e7          	jalr	-1004(ra) # 80004724 <fileclose>
  return -1;
    80004b18:	557d                	li	a0,-1
}
    80004b1a:	70a2                	ld	ra,40(sp)
    80004b1c:	7402                	ld	s0,32(sp)
    80004b1e:	64e2                	ld	s1,24(sp)
    80004b20:	6942                	ld	s2,16(sp)
    80004b22:	69a2                	ld	s3,8(sp)
    80004b24:	6a02                	ld	s4,0(sp)
    80004b26:	6145                	addi	sp,sp,48
    80004b28:	8082                	ret
  return -1;
    80004b2a:	557d                	li	a0,-1
    80004b2c:	b7fd                	j	80004b1a <pipealloc+0xc6>

0000000080004b2e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b2e:	1101                	addi	sp,sp,-32
    80004b30:	ec06                	sd	ra,24(sp)
    80004b32:	e822                	sd	s0,16(sp)
    80004b34:	e426                	sd	s1,8(sp)
    80004b36:	e04a                	sd	s2,0(sp)
    80004b38:	1000                	addi	s0,sp,32
    80004b3a:	84aa                	mv	s1,a0
    80004b3c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	0a6080e7          	jalr	166(ra) # 80000be4 <acquire>
  if(writable){
    80004b46:	02090d63          	beqz	s2,80004b80 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b4a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b4e:	21848513          	addi	a0,s1,536
    80004b52:	ffffe097          	auipc	ra,0xffffe
    80004b56:	8be080e7          	jalr	-1858(ra) # 80002410 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b5a:	2204b783          	ld	a5,544(s1)
    80004b5e:	eb95                	bnez	a5,80004b92 <pipeclose+0x64>
    release(&pi->lock);
    80004b60:	8526                	mv	a0,s1
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	136080e7          	jalr	310(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	e8c080e7          	jalr	-372(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b74:	60e2                	ld	ra,24(sp)
    80004b76:	6442                	ld	s0,16(sp)
    80004b78:	64a2                	ld	s1,8(sp)
    80004b7a:	6902                	ld	s2,0(sp)
    80004b7c:	6105                	addi	sp,sp,32
    80004b7e:	8082                	ret
    pi->readopen = 0;
    80004b80:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b84:	21c48513          	addi	a0,s1,540
    80004b88:	ffffe097          	auipc	ra,0xffffe
    80004b8c:	888080e7          	jalr	-1912(ra) # 80002410 <wakeup>
    80004b90:	b7e9                	j	80004b5a <pipeclose+0x2c>
    release(&pi->lock);
    80004b92:	8526                	mv	a0,s1
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	104080e7          	jalr	260(ra) # 80000c98 <release>
}
    80004b9c:	bfe1                	j	80004b74 <pipeclose+0x46>

0000000080004b9e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b9e:	7159                	addi	sp,sp,-112
    80004ba0:	f486                	sd	ra,104(sp)
    80004ba2:	f0a2                	sd	s0,96(sp)
    80004ba4:	eca6                	sd	s1,88(sp)
    80004ba6:	e8ca                	sd	s2,80(sp)
    80004ba8:	e4ce                	sd	s3,72(sp)
    80004baa:	e0d2                	sd	s4,64(sp)
    80004bac:	fc56                	sd	s5,56(sp)
    80004bae:	f85a                	sd	s6,48(sp)
    80004bb0:	f45e                	sd	s7,40(sp)
    80004bb2:	f062                	sd	s8,32(sp)
    80004bb4:	ec66                	sd	s9,24(sp)
    80004bb6:	1880                	addi	s0,sp,112
    80004bb8:	84aa                	mv	s1,a0
    80004bba:	8aae                	mv	s5,a1
    80004bbc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	f22080e7          	jalr	-222(ra) # 80001ae0 <myproc>
    80004bc6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	01a080e7          	jalr	26(ra) # 80000be4 <acquire>
  while(i < n){
    80004bd2:	0d405163          	blez	s4,80004c94 <pipewrite+0xf6>
    80004bd6:	8ba6                	mv	s7,s1
  int i = 0;
    80004bd8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bda:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bdc:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004be0:	21c48c13          	addi	s8,s1,540
    80004be4:	a08d                	j	80004c46 <pipewrite+0xa8>
      release(&pi->lock);
    80004be6:	8526                	mv	a0,s1
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	0b0080e7          	jalr	176(ra) # 80000c98 <release>
      return -1;
    80004bf0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bf2:	854a                	mv	a0,s2
    80004bf4:	70a6                	ld	ra,104(sp)
    80004bf6:	7406                	ld	s0,96(sp)
    80004bf8:	64e6                	ld	s1,88(sp)
    80004bfa:	6946                	ld	s2,80(sp)
    80004bfc:	69a6                	ld	s3,72(sp)
    80004bfe:	6a06                	ld	s4,64(sp)
    80004c00:	7ae2                	ld	s5,56(sp)
    80004c02:	7b42                	ld	s6,48(sp)
    80004c04:	7ba2                	ld	s7,40(sp)
    80004c06:	7c02                	ld	s8,32(sp)
    80004c08:	6ce2                	ld	s9,24(sp)
    80004c0a:	6165                	addi	sp,sp,112
    80004c0c:	8082                	ret
      wakeup(&pi->nread);
    80004c0e:	8566                	mv	a0,s9
    80004c10:	ffffe097          	auipc	ra,0xffffe
    80004c14:	800080e7          	jalr	-2048(ra) # 80002410 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c18:	85de                	mv	a1,s7
    80004c1a:	8562                	mv	a0,s8
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	580080e7          	jalr	1408(ra) # 8000219c <sleep>
    80004c24:	a839                	j	80004c42 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c26:	21c4a783          	lw	a5,540(s1)
    80004c2a:	0017871b          	addiw	a4,a5,1
    80004c2e:	20e4ae23          	sw	a4,540(s1)
    80004c32:	1ff7f793          	andi	a5,a5,511
    80004c36:	97a6                	add	a5,a5,s1
    80004c38:	f9f44703          	lbu	a4,-97(s0)
    80004c3c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c40:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c42:	03495d63          	bge	s2,s4,80004c7c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c46:	2204a783          	lw	a5,544(s1)
    80004c4a:	dfd1                	beqz	a5,80004be6 <pipewrite+0x48>
    80004c4c:	0289a783          	lw	a5,40(s3)
    80004c50:	fbd9                	bnez	a5,80004be6 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c52:	2184a783          	lw	a5,536(s1)
    80004c56:	21c4a703          	lw	a4,540(s1)
    80004c5a:	2007879b          	addiw	a5,a5,512
    80004c5e:	faf708e3          	beq	a4,a5,80004c0e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c62:	4685                	li	a3,1
    80004c64:	01590633          	add	a2,s2,s5
    80004c68:	f9f40593          	addi	a1,s0,-97
    80004c6c:	0509b503          	ld	a0,80(s3)
    80004c70:	ffffd097          	auipc	ra,0xffffd
    80004c74:	bbe080e7          	jalr	-1090(ra) # 8000182e <copyin>
    80004c78:	fb6517e3          	bne	a0,s6,80004c26 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c7c:	21848513          	addi	a0,s1,536
    80004c80:	ffffd097          	auipc	ra,0xffffd
    80004c84:	790080e7          	jalr	1936(ra) # 80002410 <wakeup>
  release(&pi->lock);
    80004c88:	8526                	mv	a0,s1
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	00e080e7          	jalr	14(ra) # 80000c98 <release>
  return i;
    80004c92:	b785                	j	80004bf2 <pipewrite+0x54>
  int i = 0;
    80004c94:	4901                	li	s2,0
    80004c96:	b7dd                	j	80004c7c <pipewrite+0xde>

0000000080004c98 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c98:	715d                	addi	sp,sp,-80
    80004c9a:	e486                	sd	ra,72(sp)
    80004c9c:	e0a2                	sd	s0,64(sp)
    80004c9e:	fc26                	sd	s1,56(sp)
    80004ca0:	f84a                	sd	s2,48(sp)
    80004ca2:	f44e                	sd	s3,40(sp)
    80004ca4:	f052                	sd	s4,32(sp)
    80004ca6:	ec56                	sd	s5,24(sp)
    80004ca8:	e85a                	sd	s6,16(sp)
    80004caa:	0880                	addi	s0,sp,80
    80004cac:	84aa                	mv	s1,a0
    80004cae:	892e                	mv	s2,a1
    80004cb0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cb2:	ffffd097          	auipc	ra,0xffffd
    80004cb6:	e2e080e7          	jalr	-466(ra) # 80001ae0 <myproc>
    80004cba:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cbc:	8b26                	mv	s6,s1
    80004cbe:	8526                	mv	a0,s1
    80004cc0:	ffffc097          	auipc	ra,0xffffc
    80004cc4:	f24080e7          	jalr	-220(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cc8:	2184a703          	lw	a4,536(s1)
    80004ccc:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cd0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd4:	02f71463          	bne	a4,a5,80004cfc <piperead+0x64>
    80004cd8:	2244a783          	lw	a5,548(s1)
    80004cdc:	c385                	beqz	a5,80004cfc <piperead+0x64>
    if(pr->killed){
    80004cde:	028a2783          	lw	a5,40(s4)
    80004ce2:	ebc1                	bnez	a5,80004d72 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ce4:	85da                	mv	a1,s6
    80004ce6:	854e                	mv	a0,s3
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	4b4080e7          	jalr	1204(ra) # 8000219c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cf0:	2184a703          	lw	a4,536(s1)
    80004cf4:	21c4a783          	lw	a5,540(s1)
    80004cf8:	fef700e3          	beq	a4,a5,80004cd8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cfc:	09505263          	blez	s5,80004d80 <piperead+0xe8>
    80004d00:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d02:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d04:	2184a783          	lw	a5,536(s1)
    80004d08:	21c4a703          	lw	a4,540(s1)
    80004d0c:	02f70d63          	beq	a4,a5,80004d46 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d10:	0017871b          	addiw	a4,a5,1
    80004d14:	20e4ac23          	sw	a4,536(s1)
    80004d18:	1ff7f793          	andi	a5,a5,511
    80004d1c:	97a6                	add	a5,a5,s1
    80004d1e:	0187c783          	lbu	a5,24(a5)
    80004d22:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d26:	4685                	li	a3,1
    80004d28:	fbf40613          	addi	a2,s0,-65
    80004d2c:	85ca                	mv	a1,s2
    80004d2e:	050a3503          	ld	a0,80(s4)
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	a70080e7          	jalr	-1424(ra) # 800017a2 <copyout>
    80004d3a:	01650663          	beq	a0,s6,80004d46 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d3e:	2985                	addiw	s3,s3,1
    80004d40:	0905                	addi	s2,s2,1
    80004d42:	fd3a91e3          	bne	s5,s3,80004d04 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d46:	21c48513          	addi	a0,s1,540
    80004d4a:	ffffd097          	auipc	ra,0xffffd
    80004d4e:	6c6080e7          	jalr	1734(ra) # 80002410 <wakeup>
  release(&pi->lock);
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	f44080e7          	jalr	-188(ra) # 80000c98 <release>
  return i;
}
    80004d5c:	854e                	mv	a0,s3
    80004d5e:	60a6                	ld	ra,72(sp)
    80004d60:	6406                	ld	s0,64(sp)
    80004d62:	74e2                	ld	s1,56(sp)
    80004d64:	7942                	ld	s2,48(sp)
    80004d66:	79a2                	ld	s3,40(sp)
    80004d68:	7a02                	ld	s4,32(sp)
    80004d6a:	6ae2                	ld	s5,24(sp)
    80004d6c:	6b42                	ld	s6,16(sp)
    80004d6e:	6161                	addi	sp,sp,80
    80004d70:	8082                	ret
      release(&pi->lock);
    80004d72:	8526                	mv	a0,s1
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	f24080e7          	jalr	-220(ra) # 80000c98 <release>
      return -1;
    80004d7c:	59fd                	li	s3,-1
    80004d7e:	bff9                	j	80004d5c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d80:	4981                	li	s3,0
    80004d82:	b7d1                	j	80004d46 <piperead+0xae>

0000000080004d84 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d84:	df010113          	addi	sp,sp,-528
    80004d88:	20113423          	sd	ra,520(sp)
    80004d8c:	20813023          	sd	s0,512(sp)
    80004d90:	ffa6                	sd	s1,504(sp)
    80004d92:	fbca                	sd	s2,496(sp)
    80004d94:	f7ce                	sd	s3,488(sp)
    80004d96:	f3d2                	sd	s4,480(sp)
    80004d98:	efd6                	sd	s5,472(sp)
    80004d9a:	ebda                	sd	s6,464(sp)
    80004d9c:	e7de                	sd	s7,456(sp)
    80004d9e:	e3e2                	sd	s8,448(sp)
    80004da0:	ff66                	sd	s9,440(sp)
    80004da2:	fb6a                	sd	s10,432(sp)
    80004da4:	f76e                	sd	s11,424(sp)
    80004da6:	0c00                	addi	s0,sp,528
    80004da8:	84aa                	mv	s1,a0
    80004daa:	dea43c23          	sd	a0,-520(s0)
    80004dae:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	d2e080e7          	jalr	-722(ra) # 80001ae0 <myproc>
    80004dba:	892a                	mv	s2,a0

  begin_op();
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	49c080e7          	jalr	1180(ra) # 80004258 <begin_op>

  if((ip = namei(path)) == 0){
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	fffff097          	auipc	ra,0xfffff
    80004dca:	276080e7          	jalr	630(ra) # 8000403c <namei>
    80004dce:	c92d                	beqz	a0,80004e40 <exec+0xbc>
    80004dd0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	ab4080e7          	jalr	-1356(ra) # 80003886 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dda:	04000713          	li	a4,64
    80004dde:	4681                	li	a3,0
    80004de0:	e5040613          	addi	a2,s0,-432
    80004de4:	4581                	li	a1,0
    80004de6:	8526                	mv	a0,s1
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	d52080e7          	jalr	-686(ra) # 80003b3a <readi>
    80004df0:	04000793          	li	a5,64
    80004df4:	00f51a63          	bne	a0,a5,80004e08 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004df8:	e5042703          	lw	a4,-432(s0)
    80004dfc:	464c47b7          	lui	a5,0x464c4
    80004e00:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e04:	04f70463          	beq	a4,a5,80004e4c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e08:	8526                	mv	a0,s1
    80004e0a:	fffff097          	auipc	ra,0xfffff
    80004e0e:	cde080e7          	jalr	-802(ra) # 80003ae8 <iunlockput>
    end_op();
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	4c6080e7          	jalr	1222(ra) # 800042d8 <end_op>
  }
  return -1;
    80004e1a:	557d                	li	a0,-1
}
    80004e1c:	20813083          	ld	ra,520(sp)
    80004e20:	20013403          	ld	s0,512(sp)
    80004e24:	74fe                	ld	s1,504(sp)
    80004e26:	795e                	ld	s2,496(sp)
    80004e28:	79be                	ld	s3,488(sp)
    80004e2a:	7a1e                	ld	s4,480(sp)
    80004e2c:	6afe                	ld	s5,472(sp)
    80004e2e:	6b5e                	ld	s6,464(sp)
    80004e30:	6bbe                	ld	s7,456(sp)
    80004e32:	6c1e                	ld	s8,448(sp)
    80004e34:	7cfa                	ld	s9,440(sp)
    80004e36:	7d5a                	ld	s10,432(sp)
    80004e38:	7dba                	ld	s11,424(sp)
    80004e3a:	21010113          	addi	sp,sp,528
    80004e3e:	8082                	ret
    end_op();
    80004e40:	fffff097          	auipc	ra,0xfffff
    80004e44:	498080e7          	jalr	1176(ra) # 800042d8 <end_op>
    return -1;
    80004e48:	557d                	li	a0,-1
    80004e4a:	bfc9                	j	80004e1c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e4c:	854a                	mv	a0,s2
    80004e4e:	ffffd097          	auipc	ra,0xffffd
    80004e52:	d56080e7          	jalr	-682(ra) # 80001ba4 <proc_pagetable>
    80004e56:	8baa                	mv	s7,a0
    80004e58:	d945                	beqz	a0,80004e08 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e5a:	e7042983          	lw	s3,-400(s0)
    80004e5e:	e8845783          	lhu	a5,-376(s0)
    80004e62:	c7ad                	beqz	a5,80004ecc <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e64:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e66:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e68:	6c85                	lui	s9,0x1
    80004e6a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e6e:	def43823          	sd	a5,-528(s0)
    80004e72:	a42d                	j	8000509c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e74:	00004517          	auipc	a0,0x4
    80004e78:	8a450513          	addi	a0,a0,-1884 # 80008718 <syscalls+0x290>
    80004e7c:	ffffb097          	auipc	ra,0xffffb
    80004e80:	6c2080e7          	jalr	1730(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e84:	8756                	mv	a4,s5
    80004e86:	012d86bb          	addw	a3,s11,s2
    80004e8a:	4581                	li	a1,0
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	cac080e7          	jalr	-852(ra) # 80003b3a <readi>
    80004e96:	2501                	sext.w	a0,a0
    80004e98:	1aaa9963          	bne	s5,a0,8000504a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e9c:	6785                	lui	a5,0x1
    80004e9e:	0127893b          	addw	s2,a5,s2
    80004ea2:	77fd                	lui	a5,0xfffff
    80004ea4:	01478a3b          	addw	s4,a5,s4
    80004ea8:	1f897163          	bgeu	s2,s8,8000508a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004eac:	02091593          	slli	a1,s2,0x20
    80004eb0:	9181                	srli	a1,a1,0x20
    80004eb2:	95ea                	add	a1,a1,s10
    80004eb4:	855e                	mv	a0,s7
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	2e8080e7          	jalr	744(ra) # 8000119e <walkaddr>
    80004ebe:	862a                	mv	a2,a0
    if(pa == 0)
    80004ec0:	d955                	beqz	a0,80004e74 <exec+0xf0>
      n = PGSIZE;
    80004ec2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ec4:	fd9a70e3          	bgeu	s4,s9,80004e84 <exec+0x100>
      n = sz - i;
    80004ec8:	8ad2                	mv	s5,s4
    80004eca:	bf6d                	j	80004e84 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ecc:	4901                	li	s2,0
  iunlockput(ip);
    80004ece:	8526                	mv	a0,s1
    80004ed0:	fffff097          	auipc	ra,0xfffff
    80004ed4:	c18080e7          	jalr	-1000(ra) # 80003ae8 <iunlockput>
  end_op();
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	400080e7          	jalr	1024(ra) # 800042d8 <end_op>
  p = myproc();
    80004ee0:	ffffd097          	auipc	ra,0xffffd
    80004ee4:	c00080e7          	jalr	-1024(ra) # 80001ae0 <myproc>
    80004ee8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eea:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eee:	6785                	lui	a5,0x1
    80004ef0:	17fd                	addi	a5,a5,-1
    80004ef2:	993e                	add	s2,s2,a5
    80004ef4:	757d                	lui	a0,0xfffff
    80004ef6:	00a977b3          	and	a5,s2,a0
    80004efa:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004efe:	6609                	lui	a2,0x2
    80004f00:	963e                	add	a2,a2,a5
    80004f02:	85be                	mv	a1,a5
    80004f04:	855e                	mv	a0,s7
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	64c080e7          	jalr	1612(ra) # 80001552 <uvmalloc>
    80004f0e:	8b2a                	mv	s6,a0
  ip = 0;
    80004f10:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f12:	12050c63          	beqz	a0,8000504a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f16:	75f9                	lui	a1,0xffffe
    80004f18:	95aa                	add	a1,a1,a0
    80004f1a:	855e                	mv	a0,s7
    80004f1c:	ffffd097          	auipc	ra,0xffffd
    80004f20:	854080e7          	jalr	-1964(ra) # 80001770 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f24:	7c7d                	lui	s8,0xfffff
    80004f26:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f28:	e0043783          	ld	a5,-512(s0)
    80004f2c:	6388                	ld	a0,0(a5)
    80004f2e:	c535                	beqz	a0,80004f9a <exec+0x216>
    80004f30:	e9040993          	addi	s3,s0,-368
    80004f34:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f38:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	f2a080e7          	jalr	-214(ra) # 80000e64 <strlen>
    80004f42:	2505                	addiw	a0,a0,1
    80004f44:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f48:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f4c:	13896363          	bltu	s2,s8,80005072 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f50:	e0043d83          	ld	s11,-512(s0)
    80004f54:	000dba03          	ld	s4,0(s11)
    80004f58:	8552                	mv	a0,s4
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	f0a080e7          	jalr	-246(ra) # 80000e64 <strlen>
    80004f62:	0015069b          	addiw	a3,a0,1
    80004f66:	8652                	mv	a2,s4
    80004f68:	85ca                	mv	a1,s2
    80004f6a:	855e                	mv	a0,s7
    80004f6c:	ffffd097          	auipc	ra,0xffffd
    80004f70:	836080e7          	jalr	-1994(ra) # 800017a2 <copyout>
    80004f74:	10054363          	bltz	a0,8000507a <exec+0x2f6>
    ustack[argc] = sp;
    80004f78:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f7c:	0485                	addi	s1,s1,1
    80004f7e:	008d8793          	addi	a5,s11,8
    80004f82:	e0f43023          	sd	a5,-512(s0)
    80004f86:	008db503          	ld	a0,8(s11)
    80004f8a:	c911                	beqz	a0,80004f9e <exec+0x21a>
    if(argc >= MAXARG)
    80004f8c:	09a1                	addi	s3,s3,8
    80004f8e:	fb3c96e3          	bne	s9,s3,80004f3a <exec+0x1b6>
  sz = sz1;
    80004f92:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f96:	4481                	li	s1,0
    80004f98:	a84d                	j	8000504a <exec+0x2c6>
  sp = sz;
    80004f9a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f9c:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f9e:	00349793          	slli	a5,s1,0x3
    80004fa2:	f9040713          	addi	a4,s0,-112
    80004fa6:	97ba                	add	a5,a5,a4
    80004fa8:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004fac:	00148693          	addi	a3,s1,1
    80004fb0:	068e                	slli	a3,a3,0x3
    80004fb2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fb6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fba:	01897663          	bgeu	s2,s8,80004fc6 <exec+0x242>
  sz = sz1;
    80004fbe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc2:	4481                	li	s1,0
    80004fc4:	a059                	j	8000504a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fc6:	e9040613          	addi	a2,s0,-368
    80004fca:	85ca                	mv	a1,s2
    80004fcc:	855e                	mv	a0,s7
    80004fce:	ffffc097          	auipc	ra,0xffffc
    80004fd2:	7d4080e7          	jalr	2004(ra) # 800017a2 <copyout>
    80004fd6:	0a054663          	bltz	a0,80005082 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004fda:	058ab783          	ld	a5,88(s5)
    80004fde:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fe2:	df843783          	ld	a5,-520(s0)
    80004fe6:	0007c703          	lbu	a4,0(a5)
    80004fea:	cf11                	beqz	a4,80005006 <exec+0x282>
    80004fec:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fee:	02f00693          	li	a3,47
    80004ff2:	a039                	j	80005000 <exec+0x27c>
      last = s+1;
    80004ff4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004ff8:	0785                	addi	a5,a5,1
    80004ffa:	fff7c703          	lbu	a4,-1(a5)
    80004ffe:	c701                	beqz	a4,80005006 <exec+0x282>
    if(*s == '/')
    80005000:	fed71ce3          	bne	a4,a3,80004ff8 <exec+0x274>
    80005004:	bfc5                	j	80004ff4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005006:	4641                	li	a2,16
    80005008:	df843583          	ld	a1,-520(s0)
    8000500c:	158a8513          	addi	a0,s5,344
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	e22080e7          	jalr	-478(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005018:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000501c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005020:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005024:	058ab783          	ld	a5,88(s5)
    80005028:	e6843703          	ld	a4,-408(s0)
    8000502c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000502e:	058ab783          	ld	a5,88(s5)
    80005032:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005036:	85ea                	mv	a1,s10
    80005038:	ffffd097          	auipc	ra,0xffffd
    8000503c:	c08080e7          	jalr	-1016(ra) # 80001c40 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005040:	0004851b          	sext.w	a0,s1
    80005044:	bbe1                	j	80004e1c <exec+0x98>
    80005046:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000504a:	e0843583          	ld	a1,-504(s0)
    8000504e:	855e                	mv	a0,s7
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	bf0080e7          	jalr	-1040(ra) # 80001c40 <proc_freepagetable>
  if(ip){
    80005058:	da0498e3          	bnez	s1,80004e08 <exec+0x84>
  return -1;
    8000505c:	557d                	li	a0,-1
    8000505e:	bb7d                	j	80004e1c <exec+0x98>
    80005060:	e1243423          	sd	s2,-504(s0)
    80005064:	b7dd                	j	8000504a <exec+0x2c6>
    80005066:	e1243423          	sd	s2,-504(s0)
    8000506a:	b7c5                	j	8000504a <exec+0x2c6>
    8000506c:	e1243423          	sd	s2,-504(s0)
    80005070:	bfe9                	j	8000504a <exec+0x2c6>
  sz = sz1;
    80005072:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005076:	4481                	li	s1,0
    80005078:	bfc9                	j	8000504a <exec+0x2c6>
  sz = sz1;
    8000507a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000507e:	4481                	li	s1,0
    80005080:	b7e9                	j	8000504a <exec+0x2c6>
  sz = sz1;
    80005082:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005086:	4481                	li	s1,0
    80005088:	b7c9                	j	8000504a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000508a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000508e:	2b05                	addiw	s6,s6,1
    80005090:	0389899b          	addiw	s3,s3,56
    80005094:	e8845783          	lhu	a5,-376(s0)
    80005098:	e2fb5be3          	bge	s6,a5,80004ece <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000509c:	2981                	sext.w	s3,s3
    8000509e:	03800713          	li	a4,56
    800050a2:	86ce                	mv	a3,s3
    800050a4:	e1840613          	addi	a2,s0,-488
    800050a8:	4581                	li	a1,0
    800050aa:	8526                	mv	a0,s1
    800050ac:	fffff097          	auipc	ra,0xfffff
    800050b0:	a8e080e7          	jalr	-1394(ra) # 80003b3a <readi>
    800050b4:	03800793          	li	a5,56
    800050b8:	f8f517e3          	bne	a0,a5,80005046 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050bc:	e1842783          	lw	a5,-488(s0)
    800050c0:	4705                	li	a4,1
    800050c2:	fce796e3          	bne	a5,a4,8000508e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050c6:	e4043603          	ld	a2,-448(s0)
    800050ca:	e3843783          	ld	a5,-456(s0)
    800050ce:	f8f669e3          	bltu	a2,a5,80005060 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050d2:	e2843783          	ld	a5,-472(s0)
    800050d6:	963e                	add	a2,a2,a5
    800050d8:	f8f667e3          	bltu	a2,a5,80005066 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050dc:	85ca                	mv	a1,s2
    800050de:	855e                	mv	a0,s7
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	472080e7          	jalr	1138(ra) # 80001552 <uvmalloc>
    800050e8:	e0a43423          	sd	a0,-504(s0)
    800050ec:	d141                	beqz	a0,8000506c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050ee:	e2843d03          	ld	s10,-472(s0)
    800050f2:	df043783          	ld	a5,-528(s0)
    800050f6:	00fd77b3          	and	a5,s10,a5
    800050fa:	fba1                	bnez	a5,8000504a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050fc:	e2042d83          	lw	s11,-480(s0)
    80005100:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005104:	f80c03e3          	beqz	s8,8000508a <exec+0x306>
    80005108:	8a62                	mv	s4,s8
    8000510a:	4901                	li	s2,0
    8000510c:	b345                	j	80004eac <exec+0x128>

000000008000510e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000510e:	7179                	addi	sp,sp,-48
    80005110:	f406                	sd	ra,40(sp)
    80005112:	f022                	sd	s0,32(sp)
    80005114:	ec26                	sd	s1,24(sp)
    80005116:	e84a                	sd	s2,16(sp)
    80005118:	1800                	addi	s0,sp,48
    8000511a:	892e                	mv	s2,a1
    8000511c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000511e:	fdc40593          	addi	a1,s0,-36
    80005122:	ffffe097          	auipc	ra,0xffffe
    80005126:	ba8080e7          	jalr	-1112(ra) # 80002cca <argint>
    8000512a:	04054063          	bltz	a0,8000516a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000512e:	fdc42703          	lw	a4,-36(s0)
    80005132:	47bd                	li	a5,15
    80005134:	02e7ed63          	bltu	a5,a4,8000516e <argfd+0x60>
    80005138:	ffffd097          	auipc	ra,0xffffd
    8000513c:	9a8080e7          	jalr	-1624(ra) # 80001ae0 <myproc>
    80005140:	fdc42703          	lw	a4,-36(s0)
    80005144:	01a70793          	addi	a5,a4,26
    80005148:	078e                	slli	a5,a5,0x3
    8000514a:	953e                	add	a0,a0,a5
    8000514c:	611c                	ld	a5,0(a0)
    8000514e:	c395                	beqz	a5,80005172 <argfd+0x64>
    return -1;
  if(pfd)
    80005150:	00090463          	beqz	s2,80005158 <argfd+0x4a>
    *pfd = fd;
    80005154:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005158:	4501                	li	a0,0
  if(pf)
    8000515a:	c091                	beqz	s1,8000515e <argfd+0x50>
    *pf = f;
    8000515c:	e09c                	sd	a5,0(s1)
}
    8000515e:	70a2                	ld	ra,40(sp)
    80005160:	7402                	ld	s0,32(sp)
    80005162:	64e2                	ld	s1,24(sp)
    80005164:	6942                	ld	s2,16(sp)
    80005166:	6145                	addi	sp,sp,48
    80005168:	8082                	ret
    return -1;
    8000516a:	557d                	li	a0,-1
    8000516c:	bfcd                	j	8000515e <argfd+0x50>
    return -1;
    8000516e:	557d                	li	a0,-1
    80005170:	b7fd                	j	8000515e <argfd+0x50>
    80005172:	557d                	li	a0,-1
    80005174:	b7ed                	j	8000515e <argfd+0x50>

0000000080005176 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005176:	1101                	addi	sp,sp,-32
    80005178:	ec06                	sd	ra,24(sp)
    8000517a:	e822                	sd	s0,16(sp)
    8000517c:	e426                	sd	s1,8(sp)
    8000517e:	1000                	addi	s0,sp,32
    80005180:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	95e080e7          	jalr	-1698(ra) # 80001ae0 <myproc>
    8000518a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000518c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005190:	4501                	li	a0,0
    80005192:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005194:	6398                	ld	a4,0(a5)
    80005196:	cb19                	beqz	a4,800051ac <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005198:	2505                	addiw	a0,a0,1
    8000519a:	07a1                	addi	a5,a5,8
    8000519c:	fed51ce3          	bne	a0,a3,80005194 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051a0:	557d                	li	a0,-1
}
    800051a2:	60e2                	ld	ra,24(sp)
    800051a4:	6442                	ld	s0,16(sp)
    800051a6:	64a2                	ld	s1,8(sp)
    800051a8:	6105                	addi	sp,sp,32
    800051aa:	8082                	ret
      p->ofile[fd] = f;
    800051ac:	01a50793          	addi	a5,a0,26
    800051b0:	078e                	slli	a5,a5,0x3
    800051b2:	963e                	add	a2,a2,a5
    800051b4:	e204                	sd	s1,0(a2)
      return fd;
    800051b6:	b7f5                	j	800051a2 <fdalloc+0x2c>

00000000800051b8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051b8:	715d                	addi	sp,sp,-80
    800051ba:	e486                	sd	ra,72(sp)
    800051bc:	e0a2                	sd	s0,64(sp)
    800051be:	fc26                	sd	s1,56(sp)
    800051c0:	f84a                	sd	s2,48(sp)
    800051c2:	f44e                	sd	s3,40(sp)
    800051c4:	f052                	sd	s4,32(sp)
    800051c6:	ec56                	sd	s5,24(sp)
    800051c8:	0880                	addi	s0,sp,80
    800051ca:	89ae                	mv	s3,a1
    800051cc:	8ab2                	mv	s5,a2
    800051ce:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051d0:	fb040593          	addi	a1,s0,-80
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	e86080e7          	jalr	-378(ra) # 8000405a <nameiparent>
    800051dc:	892a                	mv	s2,a0
    800051de:	12050f63          	beqz	a0,8000531c <create+0x164>
    return 0;

  ilock(dp);
    800051e2:	ffffe097          	auipc	ra,0xffffe
    800051e6:	6a4080e7          	jalr	1700(ra) # 80003886 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051ea:	4601                	li	a2,0
    800051ec:	fb040593          	addi	a1,s0,-80
    800051f0:	854a                	mv	a0,s2
    800051f2:	fffff097          	auipc	ra,0xfffff
    800051f6:	b78080e7          	jalr	-1160(ra) # 80003d6a <dirlookup>
    800051fa:	84aa                	mv	s1,a0
    800051fc:	c921                	beqz	a0,8000524c <create+0x94>
    iunlockput(dp);
    800051fe:	854a                	mv	a0,s2
    80005200:	fffff097          	auipc	ra,0xfffff
    80005204:	8e8080e7          	jalr	-1816(ra) # 80003ae8 <iunlockput>
    ilock(ip);
    80005208:	8526                	mv	a0,s1
    8000520a:	ffffe097          	auipc	ra,0xffffe
    8000520e:	67c080e7          	jalr	1660(ra) # 80003886 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005212:	2981                	sext.w	s3,s3
    80005214:	4789                	li	a5,2
    80005216:	02f99463          	bne	s3,a5,8000523e <create+0x86>
    8000521a:	0444d783          	lhu	a5,68(s1)
    8000521e:	37f9                	addiw	a5,a5,-2
    80005220:	17c2                	slli	a5,a5,0x30
    80005222:	93c1                	srli	a5,a5,0x30
    80005224:	4705                	li	a4,1
    80005226:	00f76c63          	bltu	a4,a5,8000523e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000522a:	8526                	mv	a0,s1
    8000522c:	60a6                	ld	ra,72(sp)
    8000522e:	6406                	ld	s0,64(sp)
    80005230:	74e2                	ld	s1,56(sp)
    80005232:	7942                	ld	s2,48(sp)
    80005234:	79a2                	ld	s3,40(sp)
    80005236:	7a02                	ld	s4,32(sp)
    80005238:	6ae2                	ld	s5,24(sp)
    8000523a:	6161                	addi	sp,sp,80
    8000523c:	8082                	ret
    iunlockput(ip);
    8000523e:	8526                	mv	a0,s1
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	8a8080e7          	jalr	-1880(ra) # 80003ae8 <iunlockput>
    return 0;
    80005248:	4481                	li	s1,0
    8000524a:	b7c5                	j	8000522a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000524c:	85ce                	mv	a1,s3
    8000524e:	00092503          	lw	a0,0(s2)
    80005252:	ffffe097          	auipc	ra,0xffffe
    80005256:	49c080e7          	jalr	1180(ra) # 800036ee <ialloc>
    8000525a:	84aa                	mv	s1,a0
    8000525c:	c529                	beqz	a0,800052a6 <create+0xee>
  ilock(ip);
    8000525e:	ffffe097          	auipc	ra,0xffffe
    80005262:	628080e7          	jalr	1576(ra) # 80003886 <ilock>
  ip->major = major;
    80005266:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000526a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000526e:	4785                	li	a5,1
    80005270:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005274:	8526                	mv	a0,s1
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	546080e7          	jalr	1350(ra) # 800037bc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000527e:	2981                	sext.w	s3,s3
    80005280:	4785                	li	a5,1
    80005282:	02f98a63          	beq	s3,a5,800052b6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005286:	40d0                	lw	a2,4(s1)
    80005288:	fb040593          	addi	a1,s0,-80
    8000528c:	854a                	mv	a0,s2
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	cec080e7          	jalr	-788(ra) # 80003f7a <dirlink>
    80005296:	06054b63          	bltz	a0,8000530c <create+0x154>
  iunlockput(dp);
    8000529a:	854a                	mv	a0,s2
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	84c080e7          	jalr	-1972(ra) # 80003ae8 <iunlockput>
  return ip;
    800052a4:	b759                	j	8000522a <create+0x72>
    panic("create: ialloc");
    800052a6:	00003517          	auipc	a0,0x3
    800052aa:	49250513          	addi	a0,a0,1170 # 80008738 <syscalls+0x2b0>
    800052ae:	ffffb097          	auipc	ra,0xffffb
    800052b2:	290080e7          	jalr	656(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800052b6:	04a95783          	lhu	a5,74(s2)
    800052ba:	2785                	addiw	a5,a5,1
    800052bc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052c0:	854a                	mv	a0,s2
    800052c2:	ffffe097          	auipc	ra,0xffffe
    800052c6:	4fa080e7          	jalr	1274(ra) # 800037bc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052ca:	40d0                	lw	a2,4(s1)
    800052cc:	00003597          	auipc	a1,0x3
    800052d0:	47c58593          	addi	a1,a1,1148 # 80008748 <syscalls+0x2c0>
    800052d4:	8526                	mv	a0,s1
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	ca4080e7          	jalr	-860(ra) # 80003f7a <dirlink>
    800052de:	00054f63          	bltz	a0,800052fc <create+0x144>
    800052e2:	00492603          	lw	a2,4(s2)
    800052e6:	00003597          	auipc	a1,0x3
    800052ea:	46a58593          	addi	a1,a1,1130 # 80008750 <syscalls+0x2c8>
    800052ee:	8526                	mv	a0,s1
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	c8a080e7          	jalr	-886(ra) # 80003f7a <dirlink>
    800052f8:	f80557e3          	bgez	a0,80005286 <create+0xce>
      panic("create dots");
    800052fc:	00003517          	auipc	a0,0x3
    80005300:	45c50513          	addi	a0,a0,1116 # 80008758 <syscalls+0x2d0>
    80005304:	ffffb097          	auipc	ra,0xffffb
    80005308:	23a080e7          	jalr	570(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000530c:	00003517          	auipc	a0,0x3
    80005310:	45c50513          	addi	a0,a0,1116 # 80008768 <syscalls+0x2e0>
    80005314:	ffffb097          	auipc	ra,0xffffb
    80005318:	22a080e7          	jalr	554(ra) # 8000053e <panic>
    return 0;
    8000531c:	84aa                	mv	s1,a0
    8000531e:	b731                	j	8000522a <create+0x72>

0000000080005320 <sys_dup>:
{
    80005320:	7179                	addi	sp,sp,-48
    80005322:	f406                	sd	ra,40(sp)
    80005324:	f022                	sd	s0,32(sp)
    80005326:	ec26                	sd	s1,24(sp)
    80005328:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000532a:	fd840613          	addi	a2,s0,-40
    8000532e:	4581                	li	a1,0
    80005330:	4501                	li	a0,0
    80005332:	00000097          	auipc	ra,0x0
    80005336:	ddc080e7          	jalr	-548(ra) # 8000510e <argfd>
    return -1;
    8000533a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000533c:	02054363          	bltz	a0,80005362 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005340:	fd843503          	ld	a0,-40(s0)
    80005344:	00000097          	auipc	ra,0x0
    80005348:	e32080e7          	jalr	-462(ra) # 80005176 <fdalloc>
    8000534c:	84aa                	mv	s1,a0
    return -1;
    8000534e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005350:	00054963          	bltz	a0,80005362 <sys_dup+0x42>
  filedup(f);
    80005354:	fd843503          	ld	a0,-40(s0)
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	37a080e7          	jalr	890(ra) # 800046d2 <filedup>
  return fd;
    80005360:	87a6                	mv	a5,s1
}
    80005362:	853e                	mv	a0,a5
    80005364:	70a2                	ld	ra,40(sp)
    80005366:	7402                	ld	s0,32(sp)
    80005368:	64e2                	ld	s1,24(sp)
    8000536a:	6145                	addi	sp,sp,48
    8000536c:	8082                	ret

000000008000536e <sys_read>:
{
    8000536e:	7179                	addi	sp,sp,-48
    80005370:	f406                	sd	ra,40(sp)
    80005372:	f022                	sd	s0,32(sp)
    80005374:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005376:	fe840613          	addi	a2,s0,-24
    8000537a:	4581                	li	a1,0
    8000537c:	4501                	li	a0,0
    8000537e:	00000097          	auipc	ra,0x0
    80005382:	d90080e7          	jalr	-624(ra) # 8000510e <argfd>
    return -1;
    80005386:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005388:	04054163          	bltz	a0,800053ca <sys_read+0x5c>
    8000538c:	fe440593          	addi	a1,s0,-28
    80005390:	4509                	li	a0,2
    80005392:	ffffe097          	auipc	ra,0xffffe
    80005396:	938080e7          	jalr	-1736(ra) # 80002cca <argint>
    return -1;
    8000539a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539c:	02054763          	bltz	a0,800053ca <sys_read+0x5c>
    800053a0:	fd840593          	addi	a1,s0,-40
    800053a4:	4505                	li	a0,1
    800053a6:	ffffe097          	auipc	ra,0xffffe
    800053aa:	946080e7          	jalr	-1722(ra) # 80002cec <argaddr>
    return -1;
    800053ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b0:	00054d63          	bltz	a0,800053ca <sys_read+0x5c>
  return fileread(f, p, n);
    800053b4:	fe442603          	lw	a2,-28(s0)
    800053b8:	fd843583          	ld	a1,-40(s0)
    800053bc:	fe843503          	ld	a0,-24(s0)
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	49e080e7          	jalr	1182(ra) # 8000485e <fileread>
    800053c8:	87aa                	mv	a5,a0
}
    800053ca:	853e                	mv	a0,a5
    800053cc:	70a2                	ld	ra,40(sp)
    800053ce:	7402                	ld	s0,32(sp)
    800053d0:	6145                	addi	sp,sp,48
    800053d2:	8082                	ret

00000000800053d4 <sys_write>:
{
    800053d4:	7179                	addi	sp,sp,-48
    800053d6:	f406                	sd	ra,40(sp)
    800053d8:	f022                	sd	s0,32(sp)
    800053da:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053dc:	fe840613          	addi	a2,s0,-24
    800053e0:	4581                	li	a1,0
    800053e2:	4501                	li	a0,0
    800053e4:	00000097          	auipc	ra,0x0
    800053e8:	d2a080e7          	jalr	-726(ra) # 8000510e <argfd>
    return -1;
    800053ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ee:	04054163          	bltz	a0,80005430 <sys_write+0x5c>
    800053f2:	fe440593          	addi	a1,s0,-28
    800053f6:	4509                	li	a0,2
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	8d2080e7          	jalr	-1838(ra) # 80002cca <argint>
    return -1;
    80005400:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005402:	02054763          	bltz	a0,80005430 <sys_write+0x5c>
    80005406:	fd840593          	addi	a1,s0,-40
    8000540a:	4505                	li	a0,1
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	8e0080e7          	jalr	-1824(ra) # 80002cec <argaddr>
    return -1;
    80005414:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005416:	00054d63          	bltz	a0,80005430 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000541a:	fe442603          	lw	a2,-28(s0)
    8000541e:	fd843583          	ld	a1,-40(s0)
    80005422:	fe843503          	ld	a0,-24(s0)
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	4fa080e7          	jalr	1274(ra) # 80004920 <filewrite>
    8000542e:	87aa                	mv	a5,a0
}
    80005430:	853e                	mv	a0,a5
    80005432:	70a2                	ld	ra,40(sp)
    80005434:	7402                	ld	s0,32(sp)
    80005436:	6145                	addi	sp,sp,48
    80005438:	8082                	ret

000000008000543a <sys_close>:
{
    8000543a:	1101                	addi	sp,sp,-32
    8000543c:	ec06                	sd	ra,24(sp)
    8000543e:	e822                	sd	s0,16(sp)
    80005440:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005442:	fe040613          	addi	a2,s0,-32
    80005446:	fec40593          	addi	a1,s0,-20
    8000544a:	4501                	li	a0,0
    8000544c:	00000097          	auipc	ra,0x0
    80005450:	cc2080e7          	jalr	-830(ra) # 8000510e <argfd>
    return -1;
    80005454:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005456:	02054463          	bltz	a0,8000547e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000545a:	ffffc097          	auipc	ra,0xffffc
    8000545e:	686080e7          	jalr	1670(ra) # 80001ae0 <myproc>
    80005462:	fec42783          	lw	a5,-20(s0)
    80005466:	07e9                	addi	a5,a5,26
    80005468:	078e                	slli	a5,a5,0x3
    8000546a:	97aa                	add	a5,a5,a0
    8000546c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005470:	fe043503          	ld	a0,-32(s0)
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	2b0080e7          	jalr	688(ra) # 80004724 <fileclose>
  return 0;
    8000547c:	4781                	li	a5,0
}
    8000547e:	853e                	mv	a0,a5
    80005480:	60e2                	ld	ra,24(sp)
    80005482:	6442                	ld	s0,16(sp)
    80005484:	6105                	addi	sp,sp,32
    80005486:	8082                	ret

0000000080005488 <sys_fstat>:
{
    80005488:	1101                	addi	sp,sp,-32
    8000548a:	ec06                	sd	ra,24(sp)
    8000548c:	e822                	sd	s0,16(sp)
    8000548e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005490:	fe840613          	addi	a2,s0,-24
    80005494:	4581                	li	a1,0
    80005496:	4501                	li	a0,0
    80005498:	00000097          	auipc	ra,0x0
    8000549c:	c76080e7          	jalr	-906(ra) # 8000510e <argfd>
    return -1;
    800054a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054a2:	02054563          	bltz	a0,800054cc <sys_fstat+0x44>
    800054a6:	fe040593          	addi	a1,s0,-32
    800054aa:	4505                	li	a0,1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	840080e7          	jalr	-1984(ra) # 80002cec <argaddr>
    return -1;
    800054b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054b6:	00054b63          	bltz	a0,800054cc <sys_fstat+0x44>
  return filestat(f, st);
    800054ba:	fe043583          	ld	a1,-32(s0)
    800054be:	fe843503          	ld	a0,-24(s0)
    800054c2:	fffff097          	auipc	ra,0xfffff
    800054c6:	32a080e7          	jalr	810(ra) # 800047ec <filestat>
    800054ca:	87aa                	mv	a5,a0
}
    800054cc:	853e                	mv	a0,a5
    800054ce:	60e2                	ld	ra,24(sp)
    800054d0:	6442                	ld	s0,16(sp)
    800054d2:	6105                	addi	sp,sp,32
    800054d4:	8082                	ret

00000000800054d6 <sys_link>:
{
    800054d6:	7169                	addi	sp,sp,-304
    800054d8:	f606                	sd	ra,296(sp)
    800054da:	f222                	sd	s0,288(sp)
    800054dc:	ee26                	sd	s1,280(sp)
    800054de:	ea4a                	sd	s2,272(sp)
    800054e0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054e2:	08000613          	li	a2,128
    800054e6:	ed040593          	addi	a1,s0,-304
    800054ea:	4501                	li	a0,0
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	822080e7          	jalr	-2014(ra) # 80002d0e <argstr>
    return -1;
    800054f4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054f6:	10054e63          	bltz	a0,80005612 <sys_link+0x13c>
    800054fa:	08000613          	li	a2,128
    800054fe:	f5040593          	addi	a1,s0,-176
    80005502:	4505                	li	a0,1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	80a080e7          	jalr	-2038(ra) # 80002d0e <argstr>
    return -1;
    8000550c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000550e:	10054263          	bltz	a0,80005612 <sys_link+0x13c>
  begin_op();
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	d46080e7          	jalr	-698(ra) # 80004258 <begin_op>
  if((ip = namei(old)) == 0){
    8000551a:	ed040513          	addi	a0,s0,-304
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	b1e080e7          	jalr	-1250(ra) # 8000403c <namei>
    80005526:	84aa                	mv	s1,a0
    80005528:	c551                	beqz	a0,800055b4 <sys_link+0xde>
  ilock(ip);
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	35c080e7          	jalr	860(ra) # 80003886 <ilock>
  if(ip->type == T_DIR){
    80005532:	04449703          	lh	a4,68(s1)
    80005536:	4785                	li	a5,1
    80005538:	08f70463          	beq	a4,a5,800055c0 <sys_link+0xea>
  ip->nlink++;
    8000553c:	04a4d783          	lhu	a5,74(s1)
    80005540:	2785                	addiw	a5,a5,1
    80005542:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005546:	8526                	mv	a0,s1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	274080e7          	jalr	628(ra) # 800037bc <iupdate>
  iunlock(ip);
    80005550:	8526                	mv	a0,s1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	3f6080e7          	jalr	1014(ra) # 80003948 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000555a:	fd040593          	addi	a1,s0,-48
    8000555e:	f5040513          	addi	a0,s0,-176
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	af8080e7          	jalr	-1288(ra) # 8000405a <nameiparent>
    8000556a:	892a                	mv	s2,a0
    8000556c:	c935                	beqz	a0,800055e0 <sys_link+0x10a>
  ilock(dp);
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	318080e7          	jalr	792(ra) # 80003886 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005576:	00092703          	lw	a4,0(s2)
    8000557a:	409c                	lw	a5,0(s1)
    8000557c:	04f71d63          	bne	a4,a5,800055d6 <sys_link+0x100>
    80005580:	40d0                	lw	a2,4(s1)
    80005582:	fd040593          	addi	a1,s0,-48
    80005586:	854a                	mv	a0,s2
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	9f2080e7          	jalr	-1550(ra) # 80003f7a <dirlink>
    80005590:	04054363          	bltz	a0,800055d6 <sys_link+0x100>
  iunlockput(dp);
    80005594:	854a                	mv	a0,s2
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	552080e7          	jalr	1362(ra) # 80003ae8 <iunlockput>
  iput(ip);
    8000559e:	8526                	mv	a0,s1
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	4a0080e7          	jalr	1184(ra) # 80003a40 <iput>
  end_op();
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	d30080e7          	jalr	-720(ra) # 800042d8 <end_op>
  return 0;
    800055b0:	4781                	li	a5,0
    800055b2:	a085                	j	80005612 <sys_link+0x13c>
    end_op();
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	d24080e7          	jalr	-732(ra) # 800042d8 <end_op>
    return -1;
    800055bc:	57fd                	li	a5,-1
    800055be:	a891                	j	80005612 <sys_link+0x13c>
    iunlockput(ip);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	526080e7          	jalr	1318(ra) # 80003ae8 <iunlockput>
    end_op();
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	d0e080e7          	jalr	-754(ra) # 800042d8 <end_op>
    return -1;
    800055d2:	57fd                	li	a5,-1
    800055d4:	a83d                	j	80005612 <sys_link+0x13c>
    iunlockput(dp);
    800055d6:	854a                	mv	a0,s2
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	510080e7          	jalr	1296(ra) # 80003ae8 <iunlockput>
  ilock(ip);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	2a4080e7          	jalr	676(ra) # 80003886 <ilock>
  ip->nlink--;
    800055ea:	04a4d783          	lhu	a5,74(s1)
    800055ee:	37fd                	addiw	a5,a5,-1
    800055f0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055f4:	8526                	mv	a0,s1
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	1c6080e7          	jalr	454(ra) # 800037bc <iupdate>
  iunlockput(ip);
    800055fe:	8526                	mv	a0,s1
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	4e8080e7          	jalr	1256(ra) # 80003ae8 <iunlockput>
  end_op();
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	cd0080e7          	jalr	-816(ra) # 800042d8 <end_op>
  return -1;
    80005610:	57fd                	li	a5,-1
}
    80005612:	853e                	mv	a0,a5
    80005614:	70b2                	ld	ra,296(sp)
    80005616:	7412                	ld	s0,288(sp)
    80005618:	64f2                	ld	s1,280(sp)
    8000561a:	6952                	ld	s2,272(sp)
    8000561c:	6155                	addi	sp,sp,304
    8000561e:	8082                	ret

0000000080005620 <sys_unlink>:
{
    80005620:	7151                	addi	sp,sp,-240
    80005622:	f586                	sd	ra,232(sp)
    80005624:	f1a2                	sd	s0,224(sp)
    80005626:	eda6                	sd	s1,216(sp)
    80005628:	e9ca                	sd	s2,208(sp)
    8000562a:	e5ce                	sd	s3,200(sp)
    8000562c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000562e:	08000613          	li	a2,128
    80005632:	f3040593          	addi	a1,s0,-208
    80005636:	4501                	li	a0,0
    80005638:	ffffd097          	auipc	ra,0xffffd
    8000563c:	6d6080e7          	jalr	1750(ra) # 80002d0e <argstr>
    80005640:	18054163          	bltz	a0,800057c2 <sys_unlink+0x1a2>
  begin_op();
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	c14080e7          	jalr	-1004(ra) # 80004258 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000564c:	fb040593          	addi	a1,s0,-80
    80005650:	f3040513          	addi	a0,s0,-208
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	a06080e7          	jalr	-1530(ra) # 8000405a <nameiparent>
    8000565c:	84aa                	mv	s1,a0
    8000565e:	c979                	beqz	a0,80005734 <sys_unlink+0x114>
  ilock(dp);
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	226080e7          	jalr	550(ra) # 80003886 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005668:	00003597          	auipc	a1,0x3
    8000566c:	0e058593          	addi	a1,a1,224 # 80008748 <syscalls+0x2c0>
    80005670:	fb040513          	addi	a0,s0,-80
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	6dc080e7          	jalr	1756(ra) # 80003d50 <namecmp>
    8000567c:	14050a63          	beqz	a0,800057d0 <sys_unlink+0x1b0>
    80005680:	00003597          	auipc	a1,0x3
    80005684:	0d058593          	addi	a1,a1,208 # 80008750 <syscalls+0x2c8>
    80005688:	fb040513          	addi	a0,s0,-80
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	6c4080e7          	jalr	1732(ra) # 80003d50 <namecmp>
    80005694:	12050e63          	beqz	a0,800057d0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005698:	f2c40613          	addi	a2,s0,-212
    8000569c:	fb040593          	addi	a1,s0,-80
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	6c8080e7          	jalr	1736(ra) # 80003d6a <dirlookup>
    800056aa:	892a                	mv	s2,a0
    800056ac:	12050263          	beqz	a0,800057d0 <sys_unlink+0x1b0>
  ilock(ip);
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	1d6080e7          	jalr	470(ra) # 80003886 <ilock>
  if(ip->nlink < 1)
    800056b8:	04a91783          	lh	a5,74(s2)
    800056bc:	08f05263          	blez	a5,80005740 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056c0:	04491703          	lh	a4,68(s2)
    800056c4:	4785                	li	a5,1
    800056c6:	08f70563          	beq	a4,a5,80005750 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056ca:	4641                	li	a2,16
    800056cc:	4581                	li	a1,0
    800056ce:	fc040513          	addi	a0,s0,-64
    800056d2:	ffffb097          	auipc	ra,0xffffb
    800056d6:	60e080e7          	jalr	1550(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056da:	4741                	li	a4,16
    800056dc:	f2c42683          	lw	a3,-212(s0)
    800056e0:	fc040613          	addi	a2,s0,-64
    800056e4:	4581                	li	a1,0
    800056e6:	8526                	mv	a0,s1
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	54a080e7          	jalr	1354(ra) # 80003c32 <writei>
    800056f0:	47c1                	li	a5,16
    800056f2:	0af51563          	bne	a0,a5,8000579c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056f6:	04491703          	lh	a4,68(s2)
    800056fa:	4785                	li	a5,1
    800056fc:	0af70863          	beq	a4,a5,800057ac <sys_unlink+0x18c>
  iunlockput(dp);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	3e6080e7          	jalr	998(ra) # 80003ae8 <iunlockput>
  ip->nlink--;
    8000570a:	04a95783          	lhu	a5,74(s2)
    8000570e:	37fd                	addiw	a5,a5,-1
    80005710:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005714:	854a                	mv	a0,s2
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	0a6080e7          	jalr	166(ra) # 800037bc <iupdate>
  iunlockput(ip);
    8000571e:	854a                	mv	a0,s2
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	3c8080e7          	jalr	968(ra) # 80003ae8 <iunlockput>
  end_op();
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	bb0080e7          	jalr	-1104(ra) # 800042d8 <end_op>
  return 0;
    80005730:	4501                	li	a0,0
    80005732:	a84d                	j	800057e4 <sys_unlink+0x1c4>
    end_op();
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	ba4080e7          	jalr	-1116(ra) # 800042d8 <end_op>
    return -1;
    8000573c:	557d                	li	a0,-1
    8000573e:	a05d                	j	800057e4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005740:	00003517          	auipc	a0,0x3
    80005744:	03850513          	addi	a0,a0,56 # 80008778 <syscalls+0x2f0>
    80005748:	ffffb097          	auipc	ra,0xffffb
    8000574c:	df6080e7          	jalr	-522(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005750:	04c92703          	lw	a4,76(s2)
    80005754:	02000793          	li	a5,32
    80005758:	f6e7f9e3          	bgeu	a5,a4,800056ca <sys_unlink+0xaa>
    8000575c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005760:	4741                	li	a4,16
    80005762:	86ce                	mv	a3,s3
    80005764:	f1840613          	addi	a2,s0,-232
    80005768:	4581                	li	a1,0
    8000576a:	854a                	mv	a0,s2
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	3ce080e7          	jalr	974(ra) # 80003b3a <readi>
    80005774:	47c1                	li	a5,16
    80005776:	00f51b63          	bne	a0,a5,8000578c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000577a:	f1845783          	lhu	a5,-232(s0)
    8000577e:	e7a1                	bnez	a5,800057c6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005780:	29c1                	addiw	s3,s3,16
    80005782:	04c92783          	lw	a5,76(s2)
    80005786:	fcf9ede3          	bltu	s3,a5,80005760 <sys_unlink+0x140>
    8000578a:	b781                	j	800056ca <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000578c:	00003517          	auipc	a0,0x3
    80005790:	00450513          	addi	a0,a0,4 # 80008790 <syscalls+0x308>
    80005794:	ffffb097          	auipc	ra,0xffffb
    80005798:	daa080e7          	jalr	-598(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000579c:	00003517          	auipc	a0,0x3
    800057a0:	00c50513          	addi	a0,a0,12 # 800087a8 <syscalls+0x320>
    800057a4:	ffffb097          	auipc	ra,0xffffb
    800057a8:	d9a080e7          	jalr	-614(ra) # 8000053e <panic>
    dp->nlink--;
    800057ac:	04a4d783          	lhu	a5,74(s1)
    800057b0:	37fd                	addiw	a5,a5,-1
    800057b2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057b6:	8526                	mv	a0,s1
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	004080e7          	jalr	4(ra) # 800037bc <iupdate>
    800057c0:	b781                	j	80005700 <sys_unlink+0xe0>
    return -1;
    800057c2:	557d                	li	a0,-1
    800057c4:	a005                	j	800057e4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057c6:	854a                	mv	a0,s2
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	320080e7          	jalr	800(ra) # 80003ae8 <iunlockput>
  iunlockput(dp);
    800057d0:	8526                	mv	a0,s1
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	316080e7          	jalr	790(ra) # 80003ae8 <iunlockput>
  end_op();
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	afe080e7          	jalr	-1282(ra) # 800042d8 <end_op>
  return -1;
    800057e2:	557d                	li	a0,-1
}
    800057e4:	70ae                	ld	ra,232(sp)
    800057e6:	740e                	ld	s0,224(sp)
    800057e8:	64ee                	ld	s1,216(sp)
    800057ea:	694e                	ld	s2,208(sp)
    800057ec:	69ae                	ld	s3,200(sp)
    800057ee:	616d                	addi	sp,sp,240
    800057f0:	8082                	ret

00000000800057f2 <sys_open>:

uint64
sys_open(void)
{
    800057f2:	7131                	addi	sp,sp,-192
    800057f4:	fd06                	sd	ra,184(sp)
    800057f6:	f922                	sd	s0,176(sp)
    800057f8:	f526                	sd	s1,168(sp)
    800057fa:	f14a                	sd	s2,160(sp)
    800057fc:	ed4e                	sd	s3,152(sp)
    800057fe:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005800:	08000613          	li	a2,128
    80005804:	f5040593          	addi	a1,s0,-176
    80005808:	4501                	li	a0,0
    8000580a:	ffffd097          	auipc	ra,0xffffd
    8000580e:	504080e7          	jalr	1284(ra) # 80002d0e <argstr>
    return -1;
    80005812:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005814:	0c054163          	bltz	a0,800058d6 <sys_open+0xe4>
    80005818:	f4c40593          	addi	a1,s0,-180
    8000581c:	4505                	li	a0,1
    8000581e:	ffffd097          	auipc	ra,0xffffd
    80005822:	4ac080e7          	jalr	1196(ra) # 80002cca <argint>
    80005826:	0a054863          	bltz	a0,800058d6 <sys_open+0xe4>

  begin_op();
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	a2e080e7          	jalr	-1490(ra) # 80004258 <begin_op>

  if(omode & O_CREATE){
    80005832:	f4c42783          	lw	a5,-180(s0)
    80005836:	2007f793          	andi	a5,a5,512
    8000583a:	cbdd                	beqz	a5,800058f0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000583c:	4681                	li	a3,0
    8000583e:	4601                	li	a2,0
    80005840:	4589                	li	a1,2
    80005842:	f5040513          	addi	a0,s0,-176
    80005846:	00000097          	auipc	ra,0x0
    8000584a:	972080e7          	jalr	-1678(ra) # 800051b8 <create>
    8000584e:	892a                	mv	s2,a0
    if(ip == 0){
    80005850:	c959                	beqz	a0,800058e6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005852:	04491703          	lh	a4,68(s2)
    80005856:	478d                	li	a5,3
    80005858:	00f71763          	bne	a4,a5,80005866 <sys_open+0x74>
    8000585c:	04695703          	lhu	a4,70(s2)
    80005860:	47a5                	li	a5,9
    80005862:	0ce7ec63          	bltu	a5,a4,8000593a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	e02080e7          	jalr	-510(ra) # 80004668 <filealloc>
    8000586e:	89aa                	mv	s3,a0
    80005870:	10050263          	beqz	a0,80005974 <sys_open+0x182>
    80005874:	00000097          	auipc	ra,0x0
    80005878:	902080e7          	jalr	-1790(ra) # 80005176 <fdalloc>
    8000587c:	84aa                	mv	s1,a0
    8000587e:	0e054663          	bltz	a0,8000596a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005882:	04491703          	lh	a4,68(s2)
    80005886:	478d                	li	a5,3
    80005888:	0cf70463          	beq	a4,a5,80005950 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000588c:	4789                	li	a5,2
    8000588e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005892:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005896:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000589a:	f4c42783          	lw	a5,-180(s0)
    8000589e:	0017c713          	xori	a4,a5,1
    800058a2:	8b05                	andi	a4,a4,1
    800058a4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058a8:	0037f713          	andi	a4,a5,3
    800058ac:	00e03733          	snez	a4,a4
    800058b0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058b4:	4007f793          	andi	a5,a5,1024
    800058b8:	c791                	beqz	a5,800058c4 <sys_open+0xd2>
    800058ba:	04491703          	lh	a4,68(s2)
    800058be:	4789                	li	a5,2
    800058c0:	08f70f63          	beq	a4,a5,8000595e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058c4:	854a                	mv	a0,s2
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	082080e7          	jalr	130(ra) # 80003948 <iunlock>
  end_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	a0a080e7          	jalr	-1526(ra) # 800042d8 <end_op>

  return fd;
}
    800058d6:	8526                	mv	a0,s1
    800058d8:	70ea                	ld	ra,184(sp)
    800058da:	744a                	ld	s0,176(sp)
    800058dc:	74aa                	ld	s1,168(sp)
    800058de:	790a                	ld	s2,160(sp)
    800058e0:	69ea                	ld	s3,152(sp)
    800058e2:	6129                	addi	sp,sp,192
    800058e4:	8082                	ret
      end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	9f2080e7          	jalr	-1550(ra) # 800042d8 <end_op>
      return -1;
    800058ee:	b7e5                	j	800058d6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058f0:	f5040513          	addi	a0,s0,-176
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	748080e7          	jalr	1864(ra) # 8000403c <namei>
    800058fc:	892a                	mv	s2,a0
    800058fe:	c905                	beqz	a0,8000592e <sys_open+0x13c>
    ilock(ip);
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	f86080e7          	jalr	-122(ra) # 80003886 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005908:	04491703          	lh	a4,68(s2)
    8000590c:	4785                	li	a5,1
    8000590e:	f4f712e3          	bne	a4,a5,80005852 <sys_open+0x60>
    80005912:	f4c42783          	lw	a5,-180(s0)
    80005916:	dba1                	beqz	a5,80005866 <sys_open+0x74>
      iunlockput(ip);
    80005918:	854a                	mv	a0,s2
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	1ce080e7          	jalr	462(ra) # 80003ae8 <iunlockput>
      end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	9b6080e7          	jalr	-1610(ra) # 800042d8 <end_op>
      return -1;
    8000592a:	54fd                	li	s1,-1
    8000592c:	b76d                	j	800058d6 <sys_open+0xe4>
      end_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	9aa080e7          	jalr	-1622(ra) # 800042d8 <end_op>
      return -1;
    80005936:	54fd                	li	s1,-1
    80005938:	bf79                	j	800058d6 <sys_open+0xe4>
    iunlockput(ip);
    8000593a:	854a                	mv	a0,s2
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	1ac080e7          	jalr	428(ra) # 80003ae8 <iunlockput>
    end_op();
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	994080e7          	jalr	-1644(ra) # 800042d8 <end_op>
    return -1;
    8000594c:	54fd                	li	s1,-1
    8000594e:	b761                	j	800058d6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005950:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005954:	04691783          	lh	a5,70(s2)
    80005958:	02f99223          	sh	a5,36(s3)
    8000595c:	bf2d                	j	80005896 <sys_open+0xa4>
    itrunc(ip);
    8000595e:	854a                	mv	a0,s2
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	034080e7          	jalr	52(ra) # 80003994 <itrunc>
    80005968:	bfb1                	j	800058c4 <sys_open+0xd2>
      fileclose(f);
    8000596a:	854e                	mv	a0,s3
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	db8080e7          	jalr	-584(ra) # 80004724 <fileclose>
    iunlockput(ip);
    80005974:	854a                	mv	a0,s2
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	172080e7          	jalr	370(ra) # 80003ae8 <iunlockput>
    end_op();
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	95a080e7          	jalr	-1702(ra) # 800042d8 <end_op>
    return -1;
    80005986:	54fd                	li	s1,-1
    80005988:	b7b9                	j	800058d6 <sys_open+0xe4>

000000008000598a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000598a:	7175                	addi	sp,sp,-144
    8000598c:	e506                	sd	ra,136(sp)
    8000598e:	e122                	sd	s0,128(sp)
    80005990:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	8c6080e7          	jalr	-1850(ra) # 80004258 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000599a:	08000613          	li	a2,128
    8000599e:	f7040593          	addi	a1,s0,-144
    800059a2:	4501                	li	a0,0
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	36a080e7          	jalr	874(ra) # 80002d0e <argstr>
    800059ac:	02054963          	bltz	a0,800059de <sys_mkdir+0x54>
    800059b0:	4681                	li	a3,0
    800059b2:	4601                	li	a2,0
    800059b4:	4585                	li	a1,1
    800059b6:	f7040513          	addi	a0,s0,-144
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	7fe080e7          	jalr	2046(ra) # 800051b8 <create>
    800059c2:	cd11                	beqz	a0,800059de <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	124080e7          	jalr	292(ra) # 80003ae8 <iunlockput>
  end_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	90c080e7          	jalr	-1780(ra) # 800042d8 <end_op>
  return 0;
    800059d4:	4501                	li	a0,0
}
    800059d6:	60aa                	ld	ra,136(sp)
    800059d8:	640a                	ld	s0,128(sp)
    800059da:	6149                	addi	sp,sp,144
    800059dc:	8082                	ret
    end_op();
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	8fa080e7          	jalr	-1798(ra) # 800042d8 <end_op>
    return -1;
    800059e6:	557d                	li	a0,-1
    800059e8:	b7fd                	j	800059d6 <sys_mkdir+0x4c>

00000000800059ea <sys_mknod>:

uint64
sys_mknod(void)
{
    800059ea:	7135                	addi	sp,sp,-160
    800059ec:	ed06                	sd	ra,152(sp)
    800059ee:	e922                	sd	s0,144(sp)
    800059f0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	866080e7          	jalr	-1946(ra) # 80004258 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059fa:	08000613          	li	a2,128
    800059fe:	f7040593          	addi	a1,s0,-144
    80005a02:	4501                	li	a0,0
    80005a04:	ffffd097          	auipc	ra,0xffffd
    80005a08:	30a080e7          	jalr	778(ra) # 80002d0e <argstr>
    80005a0c:	04054a63          	bltz	a0,80005a60 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a10:	f6c40593          	addi	a1,s0,-148
    80005a14:	4505                	li	a0,1
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	2b4080e7          	jalr	692(ra) # 80002cca <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a1e:	04054163          	bltz	a0,80005a60 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a22:	f6840593          	addi	a1,s0,-152
    80005a26:	4509                	li	a0,2
    80005a28:	ffffd097          	auipc	ra,0xffffd
    80005a2c:	2a2080e7          	jalr	674(ra) # 80002cca <argint>
     argint(1, &major) < 0 ||
    80005a30:	02054863          	bltz	a0,80005a60 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a34:	f6841683          	lh	a3,-152(s0)
    80005a38:	f6c41603          	lh	a2,-148(s0)
    80005a3c:	458d                	li	a1,3
    80005a3e:	f7040513          	addi	a0,s0,-144
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	776080e7          	jalr	1910(ra) # 800051b8 <create>
     argint(2, &minor) < 0 ||
    80005a4a:	c919                	beqz	a0,80005a60 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	09c080e7          	jalr	156(ra) # 80003ae8 <iunlockput>
  end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	884080e7          	jalr	-1916(ra) # 800042d8 <end_op>
  return 0;
    80005a5c:	4501                	li	a0,0
    80005a5e:	a031                	j	80005a6a <sys_mknod+0x80>
    end_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	878080e7          	jalr	-1928(ra) # 800042d8 <end_op>
    return -1;
    80005a68:	557d                	li	a0,-1
}
    80005a6a:	60ea                	ld	ra,152(sp)
    80005a6c:	644a                	ld	s0,144(sp)
    80005a6e:	610d                	addi	sp,sp,160
    80005a70:	8082                	ret

0000000080005a72 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a72:	7135                	addi	sp,sp,-160
    80005a74:	ed06                	sd	ra,152(sp)
    80005a76:	e922                	sd	s0,144(sp)
    80005a78:	e526                	sd	s1,136(sp)
    80005a7a:	e14a                	sd	s2,128(sp)
    80005a7c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a7e:	ffffc097          	auipc	ra,0xffffc
    80005a82:	062080e7          	jalr	98(ra) # 80001ae0 <myproc>
    80005a86:	892a                	mv	s2,a0
  
  begin_op();
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	7d0080e7          	jalr	2000(ra) # 80004258 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a90:	08000613          	li	a2,128
    80005a94:	f6040593          	addi	a1,s0,-160
    80005a98:	4501                	li	a0,0
    80005a9a:	ffffd097          	auipc	ra,0xffffd
    80005a9e:	274080e7          	jalr	628(ra) # 80002d0e <argstr>
    80005aa2:	04054b63          	bltz	a0,80005af8 <sys_chdir+0x86>
    80005aa6:	f6040513          	addi	a0,s0,-160
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	592080e7          	jalr	1426(ra) # 8000403c <namei>
    80005ab2:	84aa                	mv	s1,a0
    80005ab4:	c131                	beqz	a0,80005af8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	dd0080e7          	jalr	-560(ra) # 80003886 <ilock>
  if(ip->type != T_DIR){
    80005abe:	04449703          	lh	a4,68(s1)
    80005ac2:	4785                	li	a5,1
    80005ac4:	04f71063          	bne	a4,a5,80005b04 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ac8:	8526                	mv	a0,s1
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	e7e080e7          	jalr	-386(ra) # 80003948 <iunlock>
  iput(p->cwd);
    80005ad2:	15093503          	ld	a0,336(s2)
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	f6a080e7          	jalr	-150(ra) # 80003a40 <iput>
  end_op();
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	7fa080e7          	jalr	2042(ra) # 800042d8 <end_op>
  p->cwd = ip;
    80005ae6:	14993823          	sd	s1,336(s2)
  return 0;
    80005aea:	4501                	li	a0,0
}
    80005aec:	60ea                	ld	ra,152(sp)
    80005aee:	644a                	ld	s0,144(sp)
    80005af0:	64aa                	ld	s1,136(sp)
    80005af2:	690a                	ld	s2,128(sp)
    80005af4:	610d                	addi	sp,sp,160
    80005af6:	8082                	ret
    end_op();
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	7e0080e7          	jalr	2016(ra) # 800042d8 <end_op>
    return -1;
    80005b00:	557d                	li	a0,-1
    80005b02:	b7ed                	j	80005aec <sys_chdir+0x7a>
    iunlockput(ip);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	fe2080e7          	jalr	-30(ra) # 80003ae8 <iunlockput>
    end_op();
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	7ca080e7          	jalr	1994(ra) # 800042d8 <end_op>
    return -1;
    80005b16:	557d                	li	a0,-1
    80005b18:	bfd1                	j	80005aec <sys_chdir+0x7a>

0000000080005b1a <sys_exec>:

uint64
sys_exec(void)
{
    80005b1a:	7145                	addi	sp,sp,-464
    80005b1c:	e786                	sd	ra,456(sp)
    80005b1e:	e3a2                	sd	s0,448(sp)
    80005b20:	ff26                	sd	s1,440(sp)
    80005b22:	fb4a                	sd	s2,432(sp)
    80005b24:	f74e                	sd	s3,424(sp)
    80005b26:	f352                	sd	s4,416(sp)
    80005b28:	ef56                	sd	s5,408(sp)
    80005b2a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b2c:	08000613          	li	a2,128
    80005b30:	f4040593          	addi	a1,s0,-192
    80005b34:	4501                	li	a0,0
    80005b36:	ffffd097          	auipc	ra,0xffffd
    80005b3a:	1d8080e7          	jalr	472(ra) # 80002d0e <argstr>
    return -1;
    80005b3e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b40:	0c054a63          	bltz	a0,80005c14 <sys_exec+0xfa>
    80005b44:	e3840593          	addi	a1,s0,-456
    80005b48:	4505                	li	a0,1
    80005b4a:	ffffd097          	auipc	ra,0xffffd
    80005b4e:	1a2080e7          	jalr	418(ra) # 80002cec <argaddr>
    80005b52:	0c054163          	bltz	a0,80005c14 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b56:	10000613          	li	a2,256
    80005b5a:	4581                	li	a1,0
    80005b5c:	e4040513          	addi	a0,s0,-448
    80005b60:	ffffb097          	auipc	ra,0xffffb
    80005b64:	180080e7          	jalr	384(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b68:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b6c:	89a6                	mv	s3,s1
    80005b6e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b70:	02000a13          	li	s4,32
    80005b74:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b78:	00391513          	slli	a0,s2,0x3
    80005b7c:	e3040593          	addi	a1,s0,-464
    80005b80:	e3843783          	ld	a5,-456(s0)
    80005b84:	953e                	add	a0,a0,a5
    80005b86:	ffffd097          	auipc	ra,0xffffd
    80005b8a:	0aa080e7          	jalr	170(ra) # 80002c30 <fetchaddr>
    80005b8e:	02054a63          	bltz	a0,80005bc2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b92:	e3043783          	ld	a5,-464(s0)
    80005b96:	c3b9                	beqz	a5,80005bdc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b98:	ffffb097          	auipc	ra,0xffffb
    80005b9c:	f5c080e7          	jalr	-164(ra) # 80000af4 <kalloc>
    80005ba0:	85aa                	mv	a1,a0
    80005ba2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ba6:	cd11                	beqz	a0,80005bc2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ba8:	6605                	lui	a2,0x1
    80005baa:	e3043503          	ld	a0,-464(s0)
    80005bae:	ffffd097          	auipc	ra,0xffffd
    80005bb2:	0d4080e7          	jalr	212(ra) # 80002c82 <fetchstr>
    80005bb6:	00054663          	bltz	a0,80005bc2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bba:	0905                	addi	s2,s2,1
    80005bbc:	09a1                	addi	s3,s3,8
    80005bbe:	fb491be3          	bne	s2,s4,80005b74 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc2:	10048913          	addi	s2,s1,256
    80005bc6:	6088                	ld	a0,0(s1)
    80005bc8:	c529                	beqz	a0,80005c12 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bca:	ffffb097          	auipc	ra,0xffffb
    80005bce:	e2e080e7          	jalr	-466(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd2:	04a1                	addi	s1,s1,8
    80005bd4:	ff2499e3          	bne	s1,s2,80005bc6 <sys_exec+0xac>
  return -1;
    80005bd8:	597d                	li	s2,-1
    80005bda:	a82d                	j	80005c14 <sys_exec+0xfa>
      argv[i] = 0;
    80005bdc:	0a8e                	slli	s5,s5,0x3
    80005bde:	fc040793          	addi	a5,s0,-64
    80005be2:	9abe                	add	s5,s5,a5
    80005be4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005be8:	e4040593          	addi	a1,s0,-448
    80005bec:	f4040513          	addi	a0,s0,-192
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	194080e7          	jalr	404(ra) # 80004d84 <exec>
    80005bf8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bfa:	10048993          	addi	s3,s1,256
    80005bfe:	6088                	ld	a0,0(s1)
    80005c00:	c911                	beqz	a0,80005c14 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c02:	ffffb097          	auipc	ra,0xffffb
    80005c06:	df6080e7          	jalr	-522(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0a:	04a1                	addi	s1,s1,8
    80005c0c:	ff3499e3          	bne	s1,s3,80005bfe <sys_exec+0xe4>
    80005c10:	a011                	j	80005c14 <sys_exec+0xfa>
  return -1;
    80005c12:	597d                	li	s2,-1
}
    80005c14:	854a                	mv	a0,s2
    80005c16:	60be                	ld	ra,456(sp)
    80005c18:	641e                	ld	s0,448(sp)
    80005c1a:	74fa                	ld	s1,440(sp)
    80005c1c:	795a                	ld	s2,432(sp)
    80005c1e:	79ba                	ld	s3,424(sp)
    80005c20:	7a1a                	ld	s4,416(sp)
    80005c22:	6afa                	ld	s5,408(sp)
    80005c24:	6179                	addi	sp,sp,464
    80005c26:	8082                	ret

0000000080005c28 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c28:	7139                	addi	sp,sp,-64
    80005c2a:	fc06                	sd	ra,56(sp)
    80005c2c:	f822                	sd	s0,48(sp)
    80005c2e:	f426                	sd	s1,40(sp)
    80005c30:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c32:	ffffc097          	auipc	ra,0xffffc
    80005c36:	eae080e7          	jalr	-338(ra) # 80001ae0 <myproc>
    80005c3a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c3c:	fd840593          	addi	a1,s0,-40
    80005c40:	4501                	li	a0,0
    80005c42:	ffffd097          	auipc	ra,0xffffd
    80005c46:	0aa080e7          	jalr	170(ra) # 80002cec <argaddr>
    return -1;
    80005c4a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c4c:	0e054063          	bltz	a0,80005d2c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c50:	fc840593          	addi	a1,s0,-56
    80005c54:	fd040513          	addi	a0,s0,-48
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	dfc080e7          	jalr	-516(ra) # 80004a54 <pipealloc>
    return -1;
    80005c60:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c62:	0c054563          	bltz	a0,80005d2c <sys_pipe+0x104>
  fd0 = -1;
    80005c66:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c6a:	fd043503          	ld	a0,-48(s0)
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	508080e7          	jalr	1288(ra) # 80005176 <fdalloc>
    80005c76:	fca42223          	sw	a0,-60(s0)
    80005c7a:	08054c63          	bltz	a0,80005d12 <sys_pipe+0xea>
    80005c7e:	fc843503          	ld	a0,-56(s0)
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	4f4080e7          	jalr	1268(ra) # 80005176 <fdalloc>
    80005c8a:	fca42023          	sw	a0,-64(s0)
    80005c8e:	06054863          	bltz	a0,80005cfe <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c92:	4691                	li	a3,4
    80005c94:	fc440613          	addi	a2,s0,-60
    80005c98:	fd843583          	ld	a1,-40(s0)
    80005c9c:	68a8                	ld	a0,80(s1)
    80005c9e:	ffffc097          	auipc	ra,0xffffc
    80005ca2:	b04080e7          	jalr	-1276(ra) # 800017a2 <copyout>
    80005ca6:	02054063          	bltz	a0,80005cc6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005caa:	4691                	li	a3,4
    80005cac:	fc040613          	addi	a2,s0,-64
    80005cb0:	fd843583          	ld	a1,-40(s0)
    80005cb4:	0591                	addi	a1,a1,4
    80005cb6:	68a8                	ld	a0,80(s1)
    80005cb8:	ffffc097          	auipc	ra,0xffffc
    80005cbc:	aea080e7          	jalr	-1302(ra) # 800017a2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cc0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cc2:	06055563          	bgez	a0,80005d2c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cc6:	fc442783          	lw	a5,-60(s0)
    80005cca:	07e9                	addi	a5,a5,26
    80005ccc:	078e                	slli	a5,a5,0x3
    80005cce:	97a6                	add	a5,a5,s1
    80005cd0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cd4:	fc042503          	lw	a0,-64(s0)
    80005cd8:	0569                	addi	a0,a0,26
    80005cda:	050e                	slli	a0,a0,0x3
    80005cdc:	9526                	add	a0,a0,s1
    80005cde:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ce2:	fd043503          	ld	a0,-48(s0)
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	a3e080e7          	jalr	-1474(ra) # 80004724 <fileclose>
    fileclose(wf);
    80005cee:	fc843503          	ld	a0,-56(s0)
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	a32080e7          	jalr	-1486(ra) # 80004724 <fileclose>
    return -1;
    80005cfa:	57fd                	li	a5,-1
    80005cfc:	a805                	j	80005d2c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cfe:	fc442783          	lw	a5,-60(s0)
    80005d02:	0007c863          	bltz	a5,80005d12 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d06:	01a78513          	addi	a0,a5,26
    80005d0a:	050e                	slli	a0,a0,0x3
    80005d0c:	9526                	add	a0,a0,s1
    80005d0e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d12:	fd043503          	ld	a0,-48(s0)
    80005d16:	fffff097          	auipc	ra,0xfffff
    80005d1a:	a0e080e7          	jalr	-1522(ra) # 80004724 <fileclose>
    fileclose(wf);
    80005d1e:	fc843503          	ld	a0,-56(s0)
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	a02080e7          	jalr	-1534(ra) # 80004724 <fileclose>
    return -1;
    80005d2a:	57fd                	li	a5,-1
}
    80005d2c:	853e                	mv	a0,a5
    80005d2e:	70e2                	ld	ra,56(sp)
    80005d30:	7442                	ld	s0,48(sp)
    80005d32:	74a2                	ld	s1,40(sp)
    80005d34:	6121                	addi	sp,sp,64
    80005d36:	8082                	ret
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
    80005d80:	d7dfc0ef          	jal	ra,80002afc <kerneltrap>
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
    80005e1c:	c9c080e7          	jalr	-868(ra) # 80001ab4 <cpuid>
  
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
    80005e54:	c64080e7          	jalr	-924(ra) # 80001ab4 <cpuid>
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
    80005e7c:	c3c080e7          	jalr	-964(ra) # 80001ab4 <cpuid>
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
    80005f06:	50e080e7          	jalr	1294(ra) # 80002410 <wakeup>
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
    80006146:	05a080e7          	jalr	90(ra) # 8000219c <sleep>
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
    80006290:	f10080e7          	jalr	-240(ra) # 8000219c <sleep>
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
    800063ce:	046080e7          	jalr	70(ra) # 80002410 <wakeup>

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
