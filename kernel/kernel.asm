
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
    80000068:	d7c78793          	addi	a5,a5,-644 # 80005de0 <timervec>
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
    80000130:	5b6080e7          	jalr	1462(ra) # 800026e2 <either_copyin>
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
    800001c8:	91e080e7          	jalr	-1762(ra) # 80001ae2 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	fca080e7          	jalr	-54(ra) # 8000219e <sleep>
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
    80000214:	47c080e7          	jalr	1148(ra) # 8000268c <either_copyout>
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
    800002f6:	446080e7          	jalr	1094(ra) # 80002738 <procdump>
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
    8000044a:	fd8080e7          	jalr	-40(ra) # 8000241e <wakeup>
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
    800008a4:	b7e080e7          	jalr	-1154(ra) # 8000241e <wakeup>
    
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
    80000930:	872080e7          	jalr	-1934(ra) # 8000219e <sleep>
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
    80000b82:	f48080e7          	jalr	-184(ra) # 80001ac6 <mycpu>
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
    80000bb4:	f16080e7          	jalr	-234(ra) # 80001ac6 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	f0a080e7          	jalr	-246(ra) # 80001ac6 <mycpu>
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
    80000bd8:	ef2080e7          	jalr	-270(ra) # 80001ac6 <mycpu>
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
    80000c18:	eb2080e7          	jalr	-334(ra) # 80001ac6 <mycpu>
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
    80000c44:	e86080e7          	jalr	-378(ra) # 80001ac6 <mycpu>
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
    80000eac:	008080e7          	jalr	8(ra) # 80001eb0 <fork>
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	000080e7          	jalr	ra # 80001eb0 <fork>
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
    80000efa:	30c080e7          	jalr	780(ra) # 80002202 <pause_system>
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
    80000f3e:	f76080e7          	jalr	-138(ra) # 80001eb0 <fork>
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	f6e080e7          	jalr	-146(ra) # 80001eb0 <fork>
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
    80000f8a:	6b0080e7          	jalr	1712(ra) # 80002636 <kill_system>
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
  example_pause_system(2, 2, 5);
    80000fba:	4615                	li	a2,5
    80000fbc:	4589                	li	a1,2
    80000fbe:	4509                	li	a0,2
    80000fc0:	00000097          	auipc	ra,0x0
    80000fc4:	ece080e7          	jalr	-306(ra) # 80000e8e <example_pause_system>
  //example_kill_system(5, 5);

  if(cpuid() == 0){
    80000fc8:	00001097          	auipc	ra,0x1
    80000fcc:	aee080e7          	jalr	-1298(ra) # 80001ab6 <cpuid>
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
    
  } else {
    while(started == 0)
    80000fd0:	00008717          	auipc	a4,0x8
    80000fd4:	04870713          	addi	a4,a4,72 # 80009018 <started>
  if(cpuid() == 0){
    80000fd8:	c139                	beqz	a0,8000101e <main+0x6c>
    while(started == 0)
    80000fda:	431c                	lw	a5,0(a4)
    80000fdc:	2781                	sext.w	a5,a5
    80000fde:	dff5                	beqz	a5,80000fda <main+0x28>
      ;
    __sync_synchronize();
    80000fe0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fe4:	00001097          	auipc	ra,0x1
    80000fe8:	ad2080e7          	jalr	-1326(ra) # 80001ab6 <cpuid>
    80000fec:	85aa                	mv	a1,a0
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	10a50513          	addi	a0,a0,266 # 800080f8 <digits+0xb8>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	592080e7          	jalr	1426(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ffe:	00000097          	auipc	ra,0x0
    80001002:	0d8080e7          	jalr	216(ra) # 800010d6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001006:	00002097          	auipc	ra,0x2
    8000100a:	872080e7          	jalr	-1934(ra) # 80002878 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000100e:	00005097          	auipc	ra,0x5
    80001012:	e12080e7          	jalr	-494(ra) # 80005e20 <plicinithart>
  }

  scheduler();    
    80001016:	00001097          	auipc	ra,0x1
    8000101a:	fd6080e7          	jalr	-42(ra) # 80001fec <scheduler>
    consoleinit();
    8000101e:	fffff097          	auipc	ra,0xfffff
    80001022:	432080e7          	jalr	1074(ra) # 80000450 <consoleinit>
    printfinit();
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	748080e7          	jalr	1864(ra) # 8000076e <printfinit>
    printf("\n");
    8000102e:	00007517          	auipc	a0,0x7
    80001032:	0da50513          	addi	a0,a0,218 # 80008108 <digits+0xc8>
    80001036:	fffff097          	auipc	ra,0xfffff
    8000103a:	552080e7          	jalr	1362(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    8000103e:	00007517          	auipc	a0,0x7
    80001042:	0a250513          	addi	a0,a0,162 # 800080e0 <digits+0xa0>
    80001046:	fffff097          	auipc	ra,0xfffff
    8000104a:	542080e7          	jalr	1346(ra) # 80000588 <printf>
    printf("\n");
    8000104e:	00007517          	auipc	a0,0x7
    80001052:	0ba50513          	addi	a0,a0,186 # 80008108 <digits+0xc8>
    80001056:	fffff097          	auipc	ra,0xfffff
    8000105a:	532080e7          	jalr	1330(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    8000105e:	00000097          	auipc	ra,0x0
    80001062:	a5a080e7          	jalr	-1446(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80001066:	00000097          	auipc	ra,0x0
    8000106a:	322080e7          	jalr	802(ra) # 80001388 <kvminit>
    kvminithart();   // turn on paging
    8000106e:	00000097          	auipc	ra,0x0
    80001072:	068080e7          	jalr	104(ra) # 800010d6 <kvminithart>
    procinit();      // process table
    80001076:	00001097          	auipc	ra,0x1
    8000107a:	990080e7          	jalr	-1648(ra) # 80001a06 <procinit>
    trapinit();      // trap vectors
    8000107e:	00001097          	auipc	ra,0x1
    80001082:	7d2080e7          	jalr	2002(ra) # 80002850 <trapinit>
    trapinithart();  // install kernel trap vector
    80001086:	00001097          	auipc	ra,0x1
    8000108a:	7f2080e7          	jalr	2034(ra) # 80002878 <trapinithart>
    plicinit();      // set up interrupt controller
    8000108e:	00005097          	auipc	ra,0x5
    80001092:	d7c080e7          	jalr	-644(ra) # 80005e0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001096:	00005097          	auipc	ra,0x5
    8000109a:	d8a080e7          	jalr	-630(ra) # 80005e20 <plicinithart>
    binit();         // buffer cache
    8000109e:	00002097          	auipc	ra,0x2
    800010a2:	f66080e7          	jalr	-154(ra) # 80003004 <binit>
    iinit();         // inode table
    800010a6:	00002097          	auipc	ra,0x2
    800010aa:	5f6080e7          	jalr	1526(ra) # 8000369c <iinit>
    fileinit();      // file table
    800010ae:	00003097          	auipc	ra,0x3
    800010b2:	5a0080e7          	jalr	1440(ra) # 8000464e <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010b6:	00005097          	auipc	ra,0x5
    800010ba:	e8c080e7          	jalr	-372(ra) # 80005f42 <virtio_disk_init>
    userinit();      // first user process
    800010be:	00001097          	auipc	ra,0x1
    800010c2:	cfc080e7          	jalr	-772(ra) # 80001dba <userinit>
    __sync_synchronize();
    800010c6:	0ff0000f          	fence
    started = 1;
    800010ca:	4785                	li	a5,1
    800010cc:	00008717          	auipc	a4,0x8
    800010d0:	f4f72623          	sw	a5,-180(a4) # 80009018 <started>
    800010d4:	b789                	j	80001016 <main+0x64>

00000000800010d6 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010d6:	1141                	addi	sp,sp,-16
    800010d8:	e422                	sd	s0,8(sp)
    800010da:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010dc:	00008797          	auipc	a5,0x8
    800010e0:	f447b783          	ld	a5,-188(a5) # 80009020 <kernel_pagetable>
    800010e4:	83b1                	srli	a5,a5,0xc
    800010e6:	577d                	li	a4,-1
    800010e8:	177e                	slli	a4,a4,0x3f
    800010ea:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010ec:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010f0:	12000073          	sfence.vma
  sfence_vma();
}
    800010f4:	6422                	ld	s0,8(sp)
    800010f6:	0141                	addi	sp,sp,16
    800010f8:	8082                	ret

00000000800010fa <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010fa:	7139                	addi	sp,sp,-64
    800010fc:	fc06                	sd	ra,56(sp)
    800010fe:	f822                	sd	s0,48(sp)
    80001100:	f426                	sd	s1,40(sp)
    80001102:	f04a                	sd	s2,32(sp)
    80001104:	ec4e                	sd	s3,24(sp)
    80001106:	e852                	sd	s4,16(sp)
    80001108:	e456                	sd	s5,8(sp)
    8000110a:	e05a                	sd	s6,0(sp)
    8000110c:	0080                	addi	s0,sp,64
    8000110e:	84aa                	mv	s1,a0
    80001110:	89ae                	mv	s3,a1
    80001112:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001114:	57fd                	li	a5,-1
    80001116:	83e9                	srli	a5,a5,0x1a
    80001118:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000111a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000111c:	04b7f263          	bgeu	a5,a1,80001160 <walk+0x66>
    panic("walk");
    80001120:	00007517          	auipc	a0,0x7
    80001124:	ff050513          	addi	a0,a0,-16 # 80008110 <digits+0xd0>
    80001128:	fffff097          	auipc	ra,0xfffff
    8000112c:	416080e7          	jalr	1046(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001130:	060a8663          	beqz	s5,8000119c <walk+0xa2>
    80001134:	00000097          	auipc	ra,0x0
    80001138:	9c0080e7          	jalr	-1600(ra) # 80000af4 <kalloc>
    8000113c:	84aa                	mv	s1,a0
    8000113e:	c529                	beqz	a0,80001188 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001140:	6605                	lui	a2,0x1
    80001142:	4581                	li	a1,0
    80001144:	00000097          	auipc	ra,0x0
    80001148:	b9c080e7          	jalr	-1124(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000114c:	00c4d793          	srli	a5,s1,0xc
    80001150:	07aa                	slli	a5,a5,0xa
    80001152:	0017e793          	ori	a5,a5,1
    80001156:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000115a:	3a5d                	addiw	s4,s4,-9
    8000115c:	036a0063          	beq	s4,s6,8000117c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001160:	0149d933          	srl	s2,s3,s4
    80001164:	1ff97913          	andi	s2,s2,511
    80001168:	090e                	slli	s2,s2,0x3
    8000116a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000116c:	00093483          	ld	s1,0(s2)
    80001170:	0014f793          	andi	a5,s1,1
    80001174:	dfd5                	beqz	a5,80001130 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001176:	80a9                	srli	s1,s1,0xa
    80001178:	04b2                	slli	s1,s1,0xc
    8000117a:	b7c5                	j	8000115a <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000117c:	00c9d513          	srli	a0,s3,0xc
    80001180:	1ff57513          	andi	a0,a0,511
    80001184:	050e                	slli	a0,a0,0x3
    80001186:	9526                	add	a0,a0,s1
}
    80001188:	70e2                	ld	ra,56(sp)
    8000118a:	7442                	ld	s0,48(sp)
    8000118c:	74a2                	ld	s1,40(sp)
    8000118e:	7902                	ld	s2,32(sp)
    80001190:	69e2                	ld	s3,24(sp)
    80001192:	6a42                	ld	s4,16(sp)
    80001194:	6aa2                	ld	s5,8(sp)
    80001196:	6b02                	ld	s6,0(sp)
    80001198:	6121                	addi	sp,sp,64
    8000119a:	8082                	ret
        return 0;
    8000119c:	4501                	li	a0,0
    8000119e:	b7ed                	j	80001188 <walk+0x8e>

00000000800011a0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011a0:	57fd                	li	a5,-1
    800011a2:	83e9                	srli	a5,a5,0x1a
    800011a4:	00b7f463          	bgeu	a5,a1,800011ac <walkaddr+0xc>
    return 0;
    800011a8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011aa:	8082                	ret
{
    800011ac:	1141                	addi	sp,sp,-16
    800011ae:	e406                	sd	ra,8(sp)
    800011b0:	e022                	sd	s0,0(sp)
    800011b2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011b4:	4601                	li	a2,0
    800011b6:	00000097          	auipc	ra,0x0
    800011ba:	f44080e7          	jalr	-188(ra) # 800010fa <walk>
  if(pte == 0)
    800011be:	c105                	beqz	a0,800011de <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011c0:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011c2:	0117f693          	andi	a3,a5,17
    800011c6:	4745                	li	a4,17
    return 0;
    800011c8:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011ca:	00e68663          	beq	a3,a4,800011d6 <walkaddr+0x36>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	addi	sp,sp,16
    800011d4:	8082                	ret
  pa = PTE2PA(*pte);
    800011d6:	00a7d513          	srli	a0,a5,0xa
    800011da:	0532                	slli	a0,a0,0xc
  return pa;
    800011dc:	bfcd                	j	800011ce <walkaddr+0x2e>
    return 0;
    800011de:	4501                	li	a0,0
    800011e0:	b7fd                	j	800011ce <walkaddr+0x2e>

00000000800011e2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011e2:	715d                	addi	sp,sp,-80
    800011e4:	e486                	sd	ra,72(sp)
    800011e6:	e0a2                	sd	s0,64(sp)
    800011e8:	fc26                	sd	s1,56(sp)
    800011ea:	f84a                	sd	s2,48(sp)
    800011ec:	f44e                	sd	s3,40(sp)
    800011ee:	f052                	sd	s4,32(sp)
    800011f0:	ec56                	sd	s5,24(sp)
    800011f2:	e85a                	sd	s6,16(sp)
    800011f4:	e45e                	sd	s7,8(sp)
    800011f6:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011f8:	c205                	beqz	a2,80001218 <mappages+0x36>
    800011fa:	8aaa                	mv	s5,a0
    800011fc:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011fe:	77fd                	lui	a5,0xfffff
    80001200:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001204:	15fd                	addi	a1,a1,-1
    80001206:	00c589b3          	add	s3,a1,a2
    8000120a:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000120e:	8952                	mv	s2,s4
    80001210:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001214:	6b85                	lui	s7,0x1
    80001216:	a015                	j	8000123a <mappages+0x58>
    panic("mappages: size");
    80001218:	00007517          	auipc	a0,0x7
    8000121c:	f0050513          	addi	a0,a0,-256 # 80008118 <digits+0xd8>
    80001220:	fffff097          	auipc	ra,0xfffff
    80001224:	31e080e7          	jalr	798(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001228:	00007517          	auipc	a0,0x7
    8000122c:	f0050513          	addi	a0,a0,-256 # 80008128 <digits+0xe8>
    80001230:	fffff097          	auipc	ra,0xfffff
    80001234:	30e080e7          	jalr	782(ra) # 8000053e <panic>
    a += PGSIZE;
    80001238:	995e                	add	s2,s2,s7
  for(;;){
    8000123a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000123e:	4605                	li	a2,1
    80001240:	85ca                	mv	a1,s2
    80001242:	8556                	mv	a0,s5
    80001244:	00000097          	auipc	ra,0x0
    80001248:	eb6080e7          	jalr	-330(ra) # 800010fa <walk>
    8000124c:	cd19                	beqz	a0,8000126a <mappages+0x88>
    if(*pte & PTE_V)
    8000124e:	611c                	ld	a5,0(a0)
    80001250:	8b85                	andi	a5,a5,1
    80001252:	fbf9                	bnez	a5,80001228 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001254:	80b1                	srli	s1,s1,0xc
    80001256:	04aa                	slli	s1,s1,0xa
    80001258:	0164e4b3          	or	s1,s1,s6
    8000125c:	0014e493          	ori	s1,s1,1
    80001260:	e104                	sd	s1,0(a0)
    if(a == last)
    80001262:	fd391be3          	bne	s2,s3,80001238 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001266:	4501                	li	a0,0
    80001268:	a011                	j	8000126c <mappages+0x8a>
      return -1;
    8000126a:	557d                	li	a0,-1
}
    8000126c:	60a6                	ld	ra,72(sp)
    8000126e:	6406                	ld	s0,64(sp)
    80001270:	74e2                	ld	s1,56(sp)
    80001272:	7942                	ld	s2,48(sp)
    80001274:	79a2                	ld	s3,40(sp)
    80001276:	7a02                	ld	s4,32(sp)
    80001278:	6ae2                	ld	s5,24(sp)
    8000127a:	6b42                	ld	s6,16(sp)
    8000127c:	6ba2                	ld	s7,8(sp)
    8000127e:	6161                	addi	sp,sp,80
    80001280:	8082                	ret

0000000080001282 <kvmmap>:
{
    80001282:	1141                	addi	sp,sp,-16
    80001284:	e406                	sd	ra,8(sp)
    80001286:	e022                	sd	s0,0(sp)
    80001288:	0800                	addi	s0,sp,16
    8000128a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000128c:	86b2                	mv	a3,a2
    8000128e:	863e                	mv	a2,a5
    80001290:	00000097          	auipc	ra,0x0
    80001294:	f52080e7          	jalr	-174(ra) # 800011e2 <mappages>
    80001298:	e509                	bnez	a0,800012a2 <kvmmap+0x20>
}
    8000129a:	60a2                	ld	ra,8(sp)
    8000129c:	6402                	ld	s0,0(sp)
    8000129e:	0141                	addi	sp,sp,16
    800012a0:	8082                	ret
    panic("kvmmap");
    800012a2:	00007517          	auipc	a0,0x7
    800012a6:	e9650513          	addi	a0,a0,-362 # 80008138 <digits+0xf8>
    800012aa:	fffff097          	auipc	ra,0xfffff
    800012ae:	294080e7          	jalr	660(ra) # 8000053e <panic>

00000000800012b2 <kvmmake>:
{
    800012b2:	1101                	addi	sp,sp,-32
    800012b4:	ec06                	sd	ra,24(sp)
    800012b6:	e822                	sd	s0,16(sp)
    800012b8:	e426                	sd	s1,8(sp)
    800012ba:	e04a                	sd	s2,0(sp)
    800012bc:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	836080e7          	jalr	-1994(ra) # 80000af4 <kalloc>
    800012c6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012c8:	6605                	lui	a2,0x1
    800012ca:	4581                	li	a1,0
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	a14080e7          	jalr	-1516(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012d4:	4719                	li	a4,6
    800012d6:	6685                	lui	a3,0x1
    800012d8:	10000637          	lui	a2,0x10000
    800012dc:	100005b7          	lui	a1,0x10000
    800012e0:	8526                	mv	a0,s1
    800012e2:	00000097          	auipc	ra,0x0
    800012e6:	fa0080e7          	jalr	-96(ra) # 80001282 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012ea:	4719                	li	a4,6
    800012ec:	6685                	lui	a3,0x1
    800012ee:	10001637          	lui	a2,0x10001
    800012f2:	100015b7          	lui	a1,0x10001
    800012f6:	8526                	mv	a0,s1
    800012f8:	00000097          	auipc	ra,0x0
    800012fc:	f8a080e7          	jalr	-118(ra) # 80001282 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001300:	4719                	li	a4,6
    80001302:	004006b7          	lui	a3,0x400
    80001306:	0c000637          	lui	a2,0xc000
    8000130a:	0c0005b7          	lui	a1,0xc000
    8000130e:	8526                	mv	a0,s1
    80001310:	00000097          	auipc	ra,0x0
    80001314:	f72080e7          	jalr	-142(ra) # 80001282 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001318:	00007917          	auipc	s2,0x7
    8000131c:	ce890913          	addi	s2,s2,-792 # 80008000 <etext>
    80001320:	4729                	li	a4,10
    80001322:	80007697          	auipc	a3,0x80007
    80001326:	cde68693          	addi	a3,a3,-802 # 8000 <_entry-0x7fff8000>
    8000132a:	4605                	li	a2,1
    8000132c:	067e                	slli	a2,a2,0x1f
    8000132e:	85b2                	mv	a1,a2
    80001330:	8526                	mv	a0,s1
    80001332:	00000097          	auipc	ra,0x0
    80001336:	f50080e7          	jalr	-176(ra) # 80001282 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000133a:	4719                	li	a4,6
    8000133c:	46c5                	li	a3,17
    8000133e:	06ee                	slli	a3,a3,0x1b
    80001340:	412686b3          	sub	a3,a3,s2
    80001344:	864a                	mv	a2,s2
    80001346:	85ca                	mv	a1,s2
    80001348:	8526                	mv	a0,s1
    8000134a:	00000097          	auipc	ra,0x0
    8000134e:	f38080e7          	jalr	-200(ra) # 80001282 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001352:	4729                	li	a4,10
    80001354:	6685                	lui	a3,0x1
    80001356:	00006617          	auipc	a2,0x6
    8000135a:	caa60613          	addi	a2,a2,-854 # 80007000 <_trampoline>
    8000135e:	040005b7          	lui	a1,0x4000
    80001362:	15fd                	addi	a1,a1,-1
    80001364:	05b2                	slli	a1,a1,0xc
    80001366:	8526                	mv	a0,s1
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	f1a080e7          	jalr	-230(ra) # 80001282 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001370:	8526                	mv	a0,s1
    80001372:	00000097          	auipc	ra,0x0
    80001376:	5fe080e7          	jalr	1534(ra) # 80001970 <proc_mapstacks>
}
    8000137a:	8526                	mv	a0,s1
    8000137c:	60e2                	ld	ra,24(sp)
    8000137e:	6442                	ld	s0,16(sp)
    80001380:	64a2                	ld	s1,8(sp)
    80001382:	6902                	ld	s2,0(sp)
    80001384:	6105                	addi	sp,sp,32
    80001386:	8082                	ret

0000000080001388 <kvminit>:
{
    80001388:	1141                	addi	sp,sp,-16
    8000138a:	e406                	sd	ra,8(sp)
    8000138c:	e022                	sd	s0,0(sp)
    8000138e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001390:	00000097          	auipc	ra,0x0
    80001394:	f22080e7          	jalr	-222(ra) # 800012b2 <kvmmake>
    80001398:	00008797          	auipc	a5,0x8
    8000139c:	c8a7b423          	sd	a0,-888(a5) # 80009020 <kernel_pagetable>
}
    800013a0:	60a2                	ld	ra,8(sp)
    800013a2:	6402                	ld	s0,0(sp)
    800013a4:	0141                	addi	sp,sp,16
    800013a6:	8082                	ret

00000000800013a8 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013a8:	715d                	addi	sp,sp,-80
    800013aa:	e486                	sd	ra,72(sp)
    800013ac:	e0a2                	sd	s0,64(sp)
    800013ae:	fc26                	sd	s1,56(sp)
    800013b0:	f84a                	sd	s2,48(sp)
    800013b2:	f44e                	sd	s3,40(sp)
    800013b4:	f052                	sd	s4,32(sp)
    800013b6:	ec56                	sd	s5,24(sp)
    800013b8:	e85a                	sd	s6,16(sp)
    800013ba:	e45e                	sd	s7,8(sp)
    800013bc:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013be:	03459793          	slli	a5,a1,0x34
    800013c2:	e795                	bnez	a5,800013ee <uvmunmap+0x46>
    800013c4:	8a2a                	mv	s4,a0
    800013c6:	892e                	mv	s2,a1
    800013c8:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013ca:	0632                	slli	a2,a2,0xc
    800013cc:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013d0:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d2:	6b05                	lui	s6,0x1
    800013d4:	0735e863          	bltu	a1,s3,80001444 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013d8:	60a6                	ld	ra,72(sp)
    800013da:	6406                	ld	s0,64(sp)
    800013dc:	74e2                	ld	s1,56(sp)
    800013de:	7942                	ld	s2,48(sp)
    800013e0:	79a2                	ld	s3,40(sp)
    800013e2:	7a02                	ld	s4,32(sp)
    800013e4:	6ae2                	ld	s5,24(sp)
    800013e6:	6b42                	ld	s6,16(sp)
    800013e8:	6ba2                	ld	s7,8(sp)
    800013ea:	6161                	addi	sp,sp,80
    800013ec:	8082                	ret
    panic("uvmunmap: not aligned");
    800013ee:	00007517          	auipc	a0,0x7
    800013f2:	d5250513          	addi	a0,a0,-686 # 80008140 <digits+0x100>
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	148080e7          	jalr	328(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800013fe:	00007517          	auipc	a0,0x7
    80001402:	d5a50513          	addi	a0,a0,-678 # 80008158 <digits+0x118>
    80001406:	fffff097          	auipc	ra,0xfffff
    8000140a:	138080e7          	jalr	312(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000140e:	00007517          	auipc	a0,0x7
    80001412:	d5a50513          	addi	a0,a0,-678 # 80008168 <digits+0x128>
    80001416:	fffff097          	auipc	ra,0xfffff
    8000141a:	128080e7          	jalr	296(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000141e:	00007517          	auipc	a0,0x7
    80001422:	d6250513          	addi	a0,a0,-670 # 80008180 <digits+0x140>
    80001426:	fffff097          	auipc	ra,0xfffff
    8000142a:	118080e7          	jalr	280(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    8000142e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001430:	0532                	slli	a0,a0,0xc
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	5c6080e7          	jalr	1478(ra) # 800009f8 <kfree>
    *pte = 0;
    8000143a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000143e:	995a                	add	s2,s2,s6
    80001440:	f9397ce3          	bgeu	s2,s3,800013d8 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001444:	4601                	li	a2,0
    80001446:	85ca                	mv	a1,s2
    80001448:	8552                	mv	a0,s4
    8000144a:	00000097          	auipc	ra,0x0
    8000144e:	cb0080e7          	jalr	-848(ra) # 800010fa <walk>
    80001452:	84aa                	mv	s1,a0
    80001454:	d54d                	beqz	a0,800013fe <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001456:	6108                	ld	a0,0(a0)
    80001458:	00157793          	andi	a5,a0,1
    8000145c:	dbcd                	beqz	a5,8000140e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000145e:	3ff57793          	andi	a5,a0,1023
    80001462:	fb778ee3          	beq	a5,s7,8000141e <uvmunmap+0x76>
    if(do_free){
    80001466:	fc0a8ae3          	beqz	s5,8000143a <uvmunmap+0x92>
    8000146a:	b7d1                	j	8000142e <uvmunmap+0x86>

000000008000146c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000146c:	1101                	addi	sp,sp,-32
    8000146e:	ec06                	sd	ra,24(sp)
    80001470:	e822                	sd	s0,16(sp)
    80001472:	e426                	sd	s1,8(sp)
    80001474:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	67e080e7          	jalr	1662(ra) # 80000af4 <kalloc>
    8000147e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001480:	c519                	beqz	a0,8000148e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001482:	6605                	lui	a2,0x1
    80001484:	4581                	li	a1,0
    80001486:	00000097          	auipc	ra,0x0
    8000148a:	85a080e7          	jalr	-1958(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000148e:	8526                	mv	a0,s1
    80001490:	60e2                	ld	ra,24(sp)
    80001492:	6442                	ld	s0,16(sp)
    80001494:	64a2                	ld	s1,8(sp)
    80001496:	6105                	addi	sp,sp,32
    80001498:	8082                	ret

000000008000149a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000149a:	7179                	addi	sp,sp,-48
    8000149c:	f406                	sd	ra,40(sp)
    8000149e:	f022                	sd	s0,32(sp)
    800014a0:	ec26                	sd	s1,24(sp)
    800014a2:	e84a                	sd	s2,16(sp)
    800014a4:	e44e                	sd	s3,8(sp)
    800014a6:	e052                	sd	s4,0(sp)
    800014a8:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014aa:	6785                	lui	a5,0x1
    800014ac:	04f67863          	bgeu	a2,a5,800014fc <uvminit+0x62>
    800014b0:	8a2a                	mv	s4,a0
    800014b2:	89ae                	mv	s3,a1
    800014b4:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014b6:	fffff097          	auipc	ra,0xfffff
    800014ba:	63e080e7          	jalr	1598(ra) # 80000af4 <kalloc>
    800014be:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014c0:	6605                	lui	a2,0x1
    800014c2:	4581                	li	a1,0
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	81c080e7          	jalr	-2020(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014cc:	4779                	li	a4,30
    800014ce:	86ca                	mv	a3,s2
    800014d0:	6605                	lui	a2,0x1
    800014d2:	4581                	li	a1,0
    800014d4:	8552                	mv	a0,s4
    800014d6:	00000097          	auipc	ra,0x0
    800014da:	d0c080e7          	jalr	-756(ra) # 800011e2 <mappages>
  memmove(mem, src, sz);
    800014de:	8626                	mv	a2,s1
    800014e0:	85ce                	mv	a1,s3
    800014e2:	854a                	mv	a0,s2
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	85c080e7          	jalr	-1956(ra) # 80000d40 <memmove>
}
    800014ec:	70a2                	ld	ra,40(sp)
    800014ee:	7402                	ld	s0,32(sp)
    800014f0:	64e2                	ld	s1,24(sp)
    800014f2:	6942                	ld	s2,16(sp)
    800014f4:	69a2                	ld	s3,8(sp)
    800014f6:	6a02                	ld	s4,0(sp)
    800014f8:	6145                	addi	sp,sp,48
    800014fa:	8082                	ret
    panic("inituvm: more than a page");
    800014fc:	00007517          	auipc	a0,0x7
    80001500:	c9c50513          	addi	a0,a0,-868 # 80008198 <digits+0x158>
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	03a080e7          	jalr	58(ra) # 8000053e <panic>

000000008000150c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000150c:	1101                	addi	sp,sp,-32
    8000150e:	ec06                	sd	ra,24(sp)
    80001510:	e822                	sd	s0,16(sp)
    80001512:	e426                	sd	s1,8(sp)
    80001514:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001516:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001518:	00b67d63          	bgeu	a2,a1,80001532 <uvmdealloc+0x26>
    8000151c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000151e:	6785                	lui	a5,0x1
    80001520:	17fd                	addi	a5,a5,-1
    80001522:	00f60733          	add	a4,a2,a5
    80001526:	767d                	lui	a2,0xfffff
    80001528:	8f71                	and	a4,a4,a2
    8000152a:	97ae                	add	a5,a5,a1
    8000152c:	8ff1                	and	a5,a5,a2
    8000152e:	00f76863          	bltu	a4,a5,8000153e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001532:	8526                	mv	a0,s1
    80001534:	60e2                	ld	ra,24(sp)
    80001536:	6442                	ld	s0,16(sp)
    80001538:	64a2                	ld	s1,8(sp)
    8000153a:	6105                	addi	sp,sp,32
    8000153c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000153e:	8f99                	sub	a5,a5,a4
    80001540:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001542:	4685                	li	a3,1
    80001544:	0007861b          	sext.w	a2,a5
    80001548:	85ba                	mv	a1,a4
    8000154a:	00000097          	auipc	ra,0x0
    8000154e:	e5e080e7          	jalr	-418(ra) # 800013a8 <uvmunmap>
    80001552:	b7c5                	j	80001532 <uvmdealloc+0x26>

0000000080001554 <uvmalloc>:
  if(newsz < oldsz)
    80001554:	0ab66163          	bltu	a2,a1,800015f6 <uvmalloc+0xa2>
{
    80001558:	7139                	addi	sp,sp,-64
    8000155a:	fc06                	sd	ra,56(sp)
    8000155c:	f822                	sd	s0,48(sp)
    8000155e:	f426                	sd	s1,40(sp)
    80001560:	f04a                	sd	s2,32(sp)
    80001562:	ec4e                	sd	s3,24(sp)
    80001564:	e852                	sd	s4,16(sp)
    80001566:	e456                	sd	s5,8(sp)
    80001568:	0080                	addi	s0,sp,64
    8000156a:	8aaa                	mv	s5,a0
    8000156c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000156e:	6985                	lui	s3,0x1
    80001570:	19fd                	addi	s3,s3,-1
    80001572:	95ce                	add	a1,a1,s3
    80001574:	79fd                	lui	s3,0xfffff
    80001576:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000157a:	08c9f063          	bgeu	s3,a2,800015fa <uvmalloc+0xa6>
    8000157e:	894e                	mv	s2,s3
    mem = kalloc();
    80001580:	fffff097          	auipc	ra,0xfffff
    80001584:	574080e7          	jalr	1396(ra) # 80000af4 <kalloc>
    80001588:	84aa                	mv	s1,a0
    if(mem == 0){
    8000158a:	c51d                	beqz	a0,800015b8 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000158c:	6605                	lui	a2,0x1
    8000158e:	4581                	li	a1,0
    80001590:	fffff097          	auipc	ra,0xfffff
    80001594:	750080e7          	jalr	1872(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001598:	4779                	li	a4,30
    8000159a:	86a6                	mv	a3,s1
    8000159c:	6605                	lui	a2,0x1
    8000159e:	85ca                	mv	a1,s2
    800015a0:	8556                	mv	a0,s5
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	c40080e7          	jalr	-960(ra) # 800011e2 <mappages>
    800015aa:	e905                	bnez	a0,800015da <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015ac:	6785                	lui	a5,0x1
    800015ae:	993e                	add	s2,s2,a5
    800015b0:	fd4968e3          	bltu	s2,s4,80001580 <uvmalloc+0x2c>
  return newsz;
    800015b4:	8552                	mv	a0,s4
    800015b6:	a809                	j	800015c8 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015b8:	864e                	mv	a2,s3
    800015ba:	85ca                	mv	a1,s2
    800015bc:	8556                	mv	a0,s5
    800015be:	00000097          	auipc	ra,0x0
    800015c2:	f4e080e7          	jalr	-178(ra) # 8000150c <uvmdealloc>
      return 0;
    800015c6:	4501                	li	a0,0
}
    800015c8:	70e2                	ld	ra,56(sp)
    800015ca:	7442                	ld	s0,48(sp)
    800015cc:	74a2                	ld	s1,40(sp)
    800015ce:	7902                	ld	s2,32(sp)
    800015d0:	69e2                	ld	s3,24(sp)
    800015d2:	6a42                	ld	s4,16(sp)
    800015d4:	6aa2                	ld	s5,8(sp)
    800015d6:	6121                	addi	sp,sp,64
    800015d8:	8082                	ret
      kfree(mem);
    800015da:	8526                	mv	a0,s1
    800015dc:	fffff097          	auipc	ra,0xfffff
    800015e0:	41c080e7          	jalr	1052(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015e4:	864e                	mv	a2,s3
    800015e6:	85ca                	mv	a1,s2
    800015e8:	8556                	mv	a0,s5
    800015ea:	00000097          	auipc	ra,0x0
    800015ee:	f22080e7          	jalr	-222(ra) # 8000150c <uvmdealloc>
      return 0;
    800015f2:	4501                	li	a0,0
    800015f4:	bfd1                	j	800015c8 <uvmalloc+0x74>
    return oldsz;
    800015f6:	852e                	mv	a0,a1
}
    800015f8:	8082                	ret
  return newsz;
    800015fa:	8532                	mv	a0,a2
    800015fc:	b7f1                	j	800015c8 <uvmalloc+0x74>

00000000800015fe <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015fe:	7179                	addi	sp,sp,-48
    80001600:	f406                	sd	ra,40(sp)
    80001602:	f022                	sd	s0,32(sp)
    80001604:	ec26                	sd	s1,24(sp)
    80001606:	e84a                	sd	s2,16(sp)
    80001608:	e44e                	sd	s3,8(sp)
    8000160a:	e052                	sd	s4,0(sp)
    8000160c:	1800                	addi	s0,sp,48
    8000160e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001610:	84aa                	mv	s1,a0
    80001612:	6905                	lui	s2,0x1
    80001614:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001616:	4985                	li	s3,1
    80001618:	a821                	j	80001630 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000161a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000161c:	0532                	slli	a0,a0,0xc
    8000161e:	00000097          	auipc	ra,0x0
    80001622:	fe0080e7          	jalr	-32(ra) # 800015fe <freewalk>
      pagetable[i] = 0;
    80001626:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000162a:	04a1                	addi	s1,s1,8
    8000162c:	03248163          	beq	s1,s2,8000164e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001630:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001632:	00f57793          	andi	a5,a0,15
    80001636:	ff3782e3          	beq	a5,s3,8000161a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000163a:	8905                	andi	a0,a0,1
    8000163c:	d57d                	beqz	a0,8000162a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000163e:	00007517          	auipc	a0,0x7
    80001642:	b7a50513          	addi	a0,a0,-1158 # 800081b8 <digits+0x178>
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	ef8080e7          	jalr	-264(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000164e:	8552                	mv	a0,s4
    80001650:	fffff097          	auipc	ra,0xfffff
    80001654:	3a8080e7          	jalr	936(ra) # 800009f8 <kfree>
}
    80001658:	70a2                	ld	ra,40(sp)
    8000165a:	7402                	ld	s0,32(sp)
    8000165c:	64e2                	ld	s1,24(sp)
    8000165e:	6942                	ld	s2,16(sp)
    80001660:	69a2                	ld	s3,8(sp)
    80001662:	6a02                	ld	s4,0(sp)
    80001664:	6145                	addi	sp,sp,48
    80001666:	8082                	ret

0000000080001668 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001668:	1101                	addi	sp,sp,-32
    8000166a:	ec06                	sd	ra,24(sp)
    8000166c:	e822                	sd	s0,16(sp)
    8000166e:	e426                	sd	s1,8(sp)
    80001670:	1000                	addi	s0,sp,32
    80001672:	84aa                	mv	s1,a0
  if(sz > 0)
    80001674:	e999                	bnez	a1,8000168a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001676:	8526                	mv	a0,s1
    80001678:	00000097          	auipc	ra,0x0
    8000167c:	f86080e7          	jalr	-122(ra) # 800015fe <freewalk>
}
    80001680:	60e2                	ld	ra,24(sp)
    80001682:	6442                	ld	s0,16(sp)
    80001684:	64a2                	ld	s1,8(sp)
    80001686:	6105                	addi	sp,sp,32
    80001688:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000168a:	6605                	lui	a2,0x1
    8000168c:	167d                	addi	a2,a2,-1
    8000168e:	962e                	add	a2,a2,a1
    80001690:	4685                	li	a3,1
    80001692:	8231                	srli	a2,a2,0xc
    80001694:	4581                	li	a1,0
    80001696:	00000097          	auipc	ra,0x0
    8000169a:	d12080e7          	jalr	-750(ra) # 800013a8 <uvmunmap>
    8000169e:	bfe1                	j	80001676 <uvmfree+0xe>

00000000800016a0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016a0:	c679                	beqz	a2,8000176e <uvmcopy+0xce>
{
    800016a2:	715d                	addi	sp,sp,-80
    800016a4:	e486                	sd	ra,72(sp)
    800016a6:	e0a2                	sd	s0,64(sp)
    800016a8:	fc26                	sd	s1,56(sp)
    800016aa:	f84a                	sd	s2,48(sp)
    800016ac:	f44e                	sd	s3,40(sp)
    800016ae:	f052                	sd	s4,32(sp)
    800016b0:	ec56                	sd	s5,24(sp)
    800016b2:	e85a                	sd	s6,16(sp)
    800016b4:	e45e                	sd	s7,8(sp)
    800016b6:	0880                	addi	s0,sp,80
    800016b8:	8b2a                	mv	s6,a0
    800016ba:	8aae                	mv	s5,a1
    800016bc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016be:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800016c0:	4601                	li	a2,0
    800016c2:	85ce                	mv	a1,s3
    800016c4:	855a                	mv	a0,s6
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	a34080e7          	jalr	-1484(ra) # 800010fa <walk>
    800016ce:	c531                	beqz	a0,8000171a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016d0:	6118                	ld	a4,0(a0)
    800016d2:	00177793          	andi	a5,a4,1
    800016d6:	cbb1                	beqz	a5,8000172a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016d8:	00a75593          	srli	a1,a4,0xa
    800016dc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016e0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016e4:	fffff097          	auipc	ra,0xfffff
    800016e8:	410080e7          	jalr	1040(ra) # 80000af4 <kalloc>
    800016ec:	892a                	mv	s2,a0
    800016ee:	c939                	beqz	a0,80001744 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016f0:	6605                	lui	a2,0x1
    800016f2:	85de                	mv	a1,s7
    800016f4:	fffff097          	auipc	ra,0xfffff
    800016f8:	64c080e7          	jalr	1612(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016fc:	8726                	mv	a4,s1
    800016fe:	86ca                	mv	a3,s2
    80001700:	6605                	lui	a2,0x1
    80001702:	85ce                	mv	a1,s3
    80001704:	8556                	mv	a0,s5
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	adc080e7          	jalr	-1316(ra) # 800011e2 <mappages>
    8000170e:	e515                	bnez	a0,8000173a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001710:	6785                	lui	a5,0x1
    80001712:	99be                	add	s3,s3,a5
    80001714:	fb49e6e3          	bltu	s3,s4,800016c0 <uvmcopy+0x20>
    80001718:	a081                	j	80001758 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000171a:	00007517          	auipc	a0,0x7
    8000171e:	aae50513          	addi	a0,a0,-1362 # 800081c8 <digits+0x188>
    80001722:	fffff097          	auipc	ra,0xfffff
    80001726:	e1c080e7          	jalr	-484(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000172a:	00007517          	auipc	a0,0x7
    8000172e:	abe50513          	addi	a0,a0,-1346 # 800081e8 <digits+0x1a8>
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	e0c080e7          	jalr	-500(ra) # 8000053e <panic>
      kfree(mem);
    8000173a:	854a                	mv	a0,s2
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	2bc080e7          	jalr	700(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001744:	4685                	li	a3,1
    80001746:	00c9d613          	srli	a2,s3,0xc
    8000174a:	4581                	li	a1,0
    8000174c:	8556                	mv	a0,s5
    8000174e:	00000097          	auipc	ra,0x0
    80001752:	c5a080e7          	jalr	-934(ra) # 800013a8 <uvmunmap>
  return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6161                	addi	sp,sp,80
    8000176c:	8082                	ret
  return 0;
    8000176e:	4501                	li	a0,0
}
    80001770:	8082                	ret

0000000080001772 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001772:	1141                	addi	sp,sp,-16
    80001774:	e406                	sd	ra,8(sp)
    80001776:	e022                	sd	s0,0(sp)
    80001778:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000177a:	4601                	li	a2,0
    8000177c:	00000097          	auipc	ra,0x0
    80001780:	97e080e7          	jalr	-1666(ra) # 800010fa <walk>
  if(pte == 0)
    80001784:	c901                	beqz	a0,80001794 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001786:	611c                	ld	a5,0(a0)
    80001788:	9bbd                	andi	a5,a5,-17
    8000178a:	e11c                	sd	a5,0(a0)
}
    8000178c:	60a2                	ld	ra,8(sp)
    8000178e:	6402                	ld	s0,0(sp)
    80001790:	0141                	addi	sp,sp,16
    80001792:	8082                	ret
    panic("uvmclear");
    80001794:	00007517          	auipc	a0,0x7
    80001798:	a7450513          	addi	a0,a0,-1420 # 80008208 <digits+0x1c8>
    8000179c:	fffff097          	auipc	ra,0xfffff
    800017a0:	da2080e7          	jalr	-606(ra) # 8000053e <panic>

00000000800017a4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a4:	c6bd                	beqz	a3,80001812 <copyout+0x6e>
{
    800017a6:	715d                	addi	sp,sp,-80
    800017a8:	e486                	sd	ra,72(sp)
    800017aa:	e0a2                	sd	s0,64(sp)
    800017ac:	fc26                	sd	s1,56(sp)
    800017ae:	f84a                	sd	s2,48(sp)
    800017b0:	f44e                	sd	s3,40(sp)
    800017b2:	f052                	sd	s4,32(sp)
    800017b4:	ec56                	sd	s5,24(sp)
    800017b6:	e85a                	sd	s6,16(sp)
    800017b8:	e45e                	sd	s7,8(sp)
    800017ba:	e062                	sd	s8,0(sp)
    800017bc:	0880                	addi	s0,sp,80
    800017be:	8b2a                	mv	s6,a0
    800017c0:	8c2e                	mv	s8,a1
    800017c2:	8a32                	mv	s4,a2
    800017c4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017c6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017c8:	6a85                	lui	s5,0x1
    800017ca:	a015                	j	800017ee <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017cc:	9562                	add	a0,a0,s8
    800017ce:	0004861b          	sext.w	a2,s1
    800017d2:	85d2                	mv	a1,s4
    800017d4:	41250533          	sub	a0,a0,s2
    800017d8:	fffff097          	auipc	ra,0xfffff
    800017dc:	568080e7          	jalr	1384(ra) # 80000d40 <memmove>

    len -= n;
    800017e0:	409989b3          	sub	s3,s3,s1
    src += n;
    800017e4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017e6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017ea:	02098263          	beqz	s3,8000180e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017ee:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f2:	85ca                	mv	a1,s2
    800017f4:	855a                	mv	a0,s6
    800017f6:	00000097          	auipc	ra,0x0
    800017fa:	9aa080e7          	jalr	-1622(ra) # 800011a0 <walkaddr>
    if(pa0 == 0)
    800017fe:	cd01                	beqz	a0,80001816 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001800:	418904b3          	sub	s1,s2,s8
    80001804:	94d6                	add	s1,s1,s5
    if(n > len)
    80001806:	fc99f3e3          	bgeu	s3,s1,800017cc <copyout+0x28>
    8000180a:	84ce                	mv	s1,s3
    8000180c:	b7c1                	j	800017cc <copyout+0x28>
  }
  return 0;
    8000180e:	4501                	li	a0,0
    80001810:	a021                	j	80001818 <copyout+0x74>
    80001812:	4501                	li	a0,0
}
    80001814:	8082                	ret
      return -1;
    80001816:	557d                	li	a0,-1
}
    80001818:	60a6                	ld	ra,72(sp)
    8000181a:	6406                	ld	s0,64(sp)
    8000181c:	74e2                	ld	s1,56(sp)
    8000181e:	7942                	ld	s2,48(sp)
    80001820:	79a2                	ld	s3,40(sp)
    80001822:	7a02                	ld	s4,32(sp)
    80001824:	6ae2                	ld	s5,24(sp)
    80001826:	6b42                	ld	s6,16(sp)
    80001828:	6ba2                	ld	s7,8(sp)
    8000182a:	6c02                	ld	s8,0(sp)
    8000182c:	6161                	addi	sp,sp,80
    8000182e:	8082                	ret

0000000080001830 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001830:	c6bd                	beqz	a3,8000189e <copyin+0x6e>
{
    80001832:	715d                	addi	sp,sp,-80
    80001834:	e486                	sd	ra,72(sp)
    80001836:	e0a2                	sd	s0,64(sp)
    80001838:	fc26                	sd	s1,56(sp)
    8000183a:	f84a                	sd	s2,48(sp)
    8000183c:	f44e                	sd	s3,40(sp)
    8000183e:	f052                	sd	s4,32(sp)
    80001840:	ec56                	sd	s5,24(sp)
    80001842:	e85a                	sd	s6,16(sp)
    80001844:	e45e                	sd	s7,8(sp)
    80001846:	e062                	sd	s8,0(sp)
    80001848:	0880                	addi	s0,sp,80
    8000184a:	8b2a                	mv	s6,a0
    8000184c:	8a2e                	mv	s4,a1
    8000184e:	8c32                	mv	s8,a2
    80001850:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001852:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001854:	6a85                	lui	s5,0x1
    80001856:	a015                	j	8000187a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001858:	9562                	add	a0,a0,s8
    8000185a:	0004861b          	sext.w	a2,s1
    8000185e:	412505b3          	sub	a1,a0,s2
    80001862:	8552                	mv	a0,s4
    80001864:	fffff097          	auipc	ra,0xfffff
    80001868:	4dc080e7          	jalr	1244(ra) # 80000d40 <memmove>

    len -= n;
    8000186c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001870:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001872:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001876:	02098263          	beqz	s3,8000189a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000187a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000187e:	85ca                	mv	a1,s2
    80001880:	855a                	mv	a0,s6
    80001882:	00000097          	auipc	ra,0x0
    80001886:	91e080e7          	jalr	-1762(ra) # 800011a0 <walkaddr>
    if(pa0 == 0)
    8000188a:	cd01                	beqz	a0,800018a2 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000188c:	418904b3          	sub	s1,s2,s8
    80001890:	94d6                	add	s1,s1,s5
    if(n > len)
    80001892:	fc99f3e3          	bgeu	s3,s1,80001858 <copyin+0x28>
    80001896:	84ce                	mv	s1,s3
    80001898:	b7c1                	j	80001858 <copyin+0x28>
  }
  return 0;
    8000189a:	4501                	li	a0,0
    8000189c:	a021                	j	800018a4 <copyin+0x74>
    8000189e:	4501                	li	a0,0
}
    800018a0:	8082                	ret
      return -1;
    800018a2:	557d                	li	a0,-1
}
    800018a4:	60a6                	ld	ra,72(sp)
    800018a6:	6406                	ld	s0,64(sp)
    800018a8:	74e2                	ld	s1,56(sp)
    800018aa:	7942                	ld	s2,48(sp)
    800018ac:	79a2                	ld	s3,40(sp)
    800018ae:	7a02                	ld	s4,32(sp)
    800018b0:	6ae2                	ld	s5,24(sp)
    800018b2:	6b42                	ld	s6,16(sp)
    800018b4:	6ba2                	ld	s7,8(sp)
    800018b6:	6c02                	ld	s8,0(sp)
    800018b8:	6161                	addi	sp,sp,80
    800018ba:	8082                	ret

00000000800018bc <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018bc:	c6c5                	beqz	a3,80001964 <copyinstr+0xa8>
{
    800018be:	715d                	addi	sp,sp,-80
    800018c0:	e486                	sd	ra,72(sp)
    800018c2:	e0a2                	sd	s0,64(sp)
    800018c4:	fc26                	sd	s1,56(sp)
    800018c6:	f84a                	sd	s2,48(sp)
    800018c8:	f44e                	sd	s3,40(sp)
    800018ca:	f052                	sd	s4,32(sp)
    800018cc:	ec56                	sd	s5,24(sp)
    800018ce:	e85a                	sd	s6,16(sp)
    800018d0:	e45e                	sd	s7,8(sp)
    800018d2:	0880                	addi	s0,sp,80
    800018d4:	8a2a                	mv	s4,a0
    800018d6:	8b2e                	mv	s6,a1
    800018d8:	8bb2                	mv	s7,a2
    800018da:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018dc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018de:	6985                	lui	s3,0x1
    800018e0:	a035                	j	8000190c <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018e2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018e6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018e8:	0017b793          	seqz	a5,a5
    800018ec:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018f0:	60a6                	ld	ra,72(sp)
    800018f2:	6406                	ld	s0,64(sp)
    800018f4:	74e2                	ld	s1,56(sp)
    800018f6:	7942                	ld	s2,48(sp)
    800018f8:	79a2                	ld	s3,40(sp)
    800018fa:	7a02                	ld	s4,32(sp)
    800018fc:	6ae2                	ld	s5,24(sp)
    800018fe:	6b42                	ld	s6,16(sp)
    80001900:	6ba2                	ld	s7,8(sp)
    80001902:	6161                	addi	sp,sp,80
    80001904:	8082                	ret
    srcva = va0 + PGSIZE;
    80001906:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000190a:	c8a9                	beqz	s1,8000195c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000190c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001910:	85ca                	mv	a1,s2
    80001912:	8552                	mv	a0,s4
    80001914:	00000097          	auipc	ra,0x0
    80001918:	88c080e7          	jalr	-1908(ra) # 800011a0 <walkaddr>
    if(pa0 == 0)
    8000191c:	c131                	beqz	a0,80001960 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000191e:	41790833          	sub	a6,s2,s7
    80001922:	984e                	add	a6,a6,s3
    if(n > max)
    80001924:	0104f363          	bgeu	s1,a6,8000192a <copyinstr+0x6e>
    80001928:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000192a:	955e                	add	a0,a0,s7
    8000192c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001930:	fc080be3          	beqz	a6,80001906 <copyinstr+0x4a>
    80001934:	985a                	add	a6,a6,s6
    80001936:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001938:	41650633          	sub	a2,a0,s6
    8000193c:	14fd                	addi	s1,s1,-1
    8000193e:	9b26                	add	s6,s6,s1
    80001940:	00f60733          	add	a4,a2,a5
    80001944:	00074703          	lbu	a4,0(a4)
    80001948:	df49                	beqz	a4,800018e2 <copyinstr+0x26>
        *dst = *p;
    8000194a:	00e78023          	sb	a4,0(a5)
      --max;
    8000194e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001952:	0785                	addi	a5,a5,1
    while(n > 0){
    80001954:	ff0796e3          	bne	a5,a6,80001940 <copyinstr+0x84>
      dst++;
    80001958:	8b42                	mv	s6,a6
    8000195a:	b775                	j	80001906 <copyinstr+0x4a>
    8000195c:	4781                	li	a5,0
    8000195e:	b769                	j	800018e8 <copyinstr+0x2c>
      return -1;
    80001960:	557d                	li	a0,-1
    80001962:	b779                	j	800018f0 <copyinstr+0x34>
  int got_null = 0;
    80001964:	4781                	li	a5,0
  if(got_null){
    80001966:	0017b793          	seqz	a5,a5
    8000196a:	40f00533          	neg	a0,a5
}
    8000196e:	8082                	ret

0000000080001970 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001970:	7139                	addi	sp,sp,-64
    80001972:	fc06                	sd	ra,56(sp)
    80001974:	f822                	sd	s0,48(sp)
    80001976:	f426                	sd	s1,40(sp)
    80001978:	f04a                	sd	s2,32(sp)
    8000197a:	ec4e                	sd	s3,24(sp)
    8000197c:	e852                	sd	s4,16(sp)
    8000197e:	e456                	sd	s5,8(sp)
    80001980:	e05a                	sd	s6,0(sp)
    80001982:	0080                	addi	s0,sp,64
    80001984:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001986:	00010497          	auipc	s1,0x10
    8000198a:	d4a48493          	addi	s1,s1,-694 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000198e:	8b26                	mv	s6,s1
    80001990:	00006a97          	auipc	s5,0x6
    80001994:	670a8a93          	addi	s5,s5,1648 # 80008000 <etext>
    80001998:	04000937          	lui	s2,0x4000
    8000199c:	197d                	addi	s2,s2,-1
    8000199e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a0:	00015a17          	auipc	s4,0x15
    800019a4:	730a0a13          	addi	s4,s4,1840 # 800170d0 <tickslock>
    char *pa = kalloc();
    800019a8:	fffff097          	auipc	ra,0xfffff
    800019ac:	14c080e7          	jalr	332(ra) # 80000af4 <kalloc>
    800019b0:	862a                	mv	a2,a0
    if(pa == 0)
    800019b2:	c131                	beqz	a0,800019f6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019b4:	416485b3          	sub	a1,s1,s6
    800019b8:	858d                	srai	a1,a1,0x3
    800019ba:	000ab783          	ld	a5,0(s5)
    800019be:	02f585b3          	mul	a1,a1,a5
    800019c2:	2585                	addiw	a1,a1,1
    800019c4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019c8:	4719                	li	a4,6
    800019ca:	6685                	lui	a3,0x1
    800019cc:	40b905b3          	sub	a1,s2,a1
    800019d0:	854e                	mv	a0,s3
    800019d2:	00000097          	auipc	ra,0x0
    800019d6:	8b0080e7          	jalr	-1872(ra) # 80001282 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019da:	16848493          	addi	s1,s1,360
    800019de:	fd4495e3          	bne	s1,s4,800019a8 <proc_mapstacks+0x38>
  }
}
    800019e2:	70e2                	ld	ra,56(sp)
    800019e4:	7442                	ld	s0,48(sp)
    800019e6:	74a2                	ld	s1,40(sp)
    800019e8:	7902                	ld	s2,32(sp)
    800019ea:	69e2                	ld	s3,24(sp)
    800019ec:	6a42                	ld	s4,16(sp)
    800019ee:	6aa2                	ld	s5,8(sp)
    800019f0:	6b02                	ld	s6,0(sp)
    800019f2:	6121                	addi	sp,sp,64
    800019f4:	8082                	ret
      panic("kalloc");
    800019f6:	00007517          	auipc	a0,0x7
    800019fa:	82250513          	addi	a0,a0,-2014 # 80008218 <digits+0x1d8>
    800019fe:	fffff097          	auipc	ra,0xfffff
    80001a02:	b40080e7          	jalr	-1216(ra) # 8000053e <panic>

0000000080001a06 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001a06:	7139                	addi	sp,sp,-64
    80001a08:	fc06                	sd	ra,56(sp)
    80001a0a:	f822                	sd	s0,48(sp)
    80001a0c:	f426                	sd	s1,40(sp)
    80001a0e:	f04a                	sd	s2,32(sp)
    80001a10:	ec4e                	sd	s3,24(sp)
    80001a12:	e852                	sd	s4,16(sp)
    80001a14:	e456                	sd	s5,8(sp)
    80001a16:	e05a                	sd	s6,0(sp)
    80001a18:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a1a:	00007597          	auipc	a1,0x7
    80001a1e:	80658593          	addi	a1,a1,-2042 # 80008220 <digits+0x1e0>
    80001a22:	00010517          	auipc	a0,0x10
    80001a26:	87e50513          	addi	a0,a0,-1922 # 800112a0 <pid_lock>
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	12a080e7          	jalr	298(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a32:	00006597          	auipc	a1,0x6
    80001a36:	7f658593          	addi	a1,a1,2038 # 80008228 <digits+0x1e8>
    80001a3a:	00010517          	auipc	a0,0x10
    80001a3e:	87e50513          	addi	a0,a0,-1922 # 800112b8 <wait_lock>
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	112080e7          	jalr	274(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a4a:	00010497          	auipc	s1,0x10
    80001a4e:	c8648493          	addi	s1,s1,-890 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001a52:	00006b17          	auipc	s6,0x6
    80001a56:	7e6b0b13          	addi	s6,s6,2022 # 80008238 <digits+0x1f8>
      p->kstack = KSTACK((int) (p - proc));
    80001a5a:	8aa6                	mv	s5,s1
    80001a5c:	00006a17          	auipc	s4,0x6
    80001a60:	5a4a0a13          	addi	s4,s4,1444 # 80008000 <etext>
    80001a64:	04000937          	lui	s2,0x4000
    80001a68:	197d                	addi	s2,s2,-1
    80001a6a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a6c:	00015997          	auipc	s3,0x15
    80001a70:	66498993          	addi	s3,s3,1636 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a74:	85da                	mv	a1,s6
    80001a76:	8526                	mv	a0,s1
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	0dc080e7          	jalr	220(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a80:	415487b3          	sub	a5,s1,s5
    80001a84:	878d                	srai	a5,a5,0x3
    80001a86:	000a3703          	ld	a4,0(s4)
    80001a8a:	02e787b3          	mul	a5,a5,a4
    80001a8e:	2785                	addiw	a5,a5,1
    80001a90:	00d7979b          	slliw	a5,a5,0xd
    80001a94:	40f907b3          	sub	a5,s2,a5
    80001a98:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a9a:	16848493          	addi	s1,s1,360
    80001a9e:	fd349be3          	bne	s1,s3,80001a74 <procinit+0x6e>
  }
}
    80001aa2:	70e2                	ld	ra,56(sp)
    80001aa4:	7442                	ld	s0,48(sp)
    80001aa6:	74a2                	ld	s1,40(sp)
    80001aa8:	7902                	ld	s2,32(sp)
    80001aaa:	69e2                	ld	s3,24(sp)
    80001aac:	6a42                	ld	s4,16(sp)
    80001aae:	6aa2                	ld	s5,8(sp)
    80001ab0:	6b02                	ld	s6,0(sp)
    80001ab2:	6121                	addi	sp,sp,64
    80001ab4:	8082                	ret

0000000080001ab6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ab6:	1141                	addi	sp,sp,-16
    80001ab8:	e422                	sd	s0,8(sp)
    80001aba:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001abc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001abe:	2501                	sext.w	a0,a0
    80001ac0:	6422                	ld	s0,8(sp)
    80001ac2:	0141                	addi	sp,sp,16
    80001ac4:	8082                	ret

0000000080001ac6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001ac6:	1141                	addi	sp,sp,-16
    80001ac8:	e422                	sd	s0,8(sp)
    80001aca:	0800                	addi	s0,sp,16
    80001acc:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ace:	2781                	sext.w	a5,a5
    80001ad0:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ad2:	0000f517          	auipc	a0,0xf
    80001ad6:	7fe50513          	addi	a0,a0,2046 # 800112d0 <cpus>
    80001ada:	953e                	add	a0,a0,a5
    80001adc:	6422                	ld	s0,8(sp)
    80001ade:	0141                	addi	sp,sp,16
    80001ae0:	8082                	ret

0000000080001ae2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001ae2:	1101                	addi	sp,sp,-32
    80001ae4:	ec06                	sd	ra,24(sp)
    80001ae6:	e822                	sd	s0,16(sp)
    80001ae8:	e426                	sd	s1,8(sp)
    80001aea:	1000                	addi	s0,sp,32
  push_off();
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	0ac080e7          	jalr	172(ra) # 80000b98 <push_off>
    80001af4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001af6:	2781                	sext.w	a5,a5
    80001af8:	079e                	slli	a5,a5,0x7
    80001afa:	0000f717          	auipc	a4,0xf
    80001afe:	7a670713          	addi	a4,a4,1958 # 800112a0 <pid_lock>
    80001b02:	97ba                	add	a5,a5,a4
    80001b04:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	132080e7          	jalr	306(ra) # 80000c38 <pop_off>
  return p;
}
    80001b0e:	8526                	mv	a0,s1
    80001b10:	60e2                	ld	ra,24(sp)
    80001b12:	6442                	ld	s0,16(sp)
    80001b14:	64a2                	ld	s1,8(sp)
    80001b16:	6105                	addi	sp,sp,32
    80001b18:	8082                	ret

0000000080001b1a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b1a:	1141                	addi	sp,sp,-16
    80001b1c:	e406                	sd	ra,8(sp)
    80001b1e:	e022                	sd	s0,0(sp)
    80001b20:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b22:	00000097          	auipc	ra,0x0
    80001b26:	fc0080e7          	jalr	-64(ra) # 80001ae2 <myproc>
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	16e080e7          	jalr	366(ra) # 80000c98 <release>

  if (first) {
    80001b32:	00007797          	auipc	a5,0x7
    80001b36:	d2e7a783          	lw	a5,-722(a5) # 80008860 <first.1696>
    80001b3a:	eb89                	bnez	a5,80001b4c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b3c:	00001097          	auipc	ra,0x1
    80001b40:	d54080e7          	jalr	-684(ra) # 80002890 <usertrapret>
}
    80001b44:	60a2                	ld	ra,8(sp)
    80001b46:	6402                	ld	s0,0(sp)
    80001b48:	0141                	addi	sp,sp,16
    80001b4a:	8082                	ret
    first = 0;
    80001b4c:	00007797          	auipc	a5,0x7
    80001b50:	d007aa23          	sw	zero,-748(a5) # 80008860 <first.1696>
    fsinit(ROOTDEV);
    80001b54:	4505                	li	a0,1
    80001b56:	00002097          	auipc	ra,0x2
    80001b5a:	ac6080e7          	jalr	-1338(ra) # 8000361c <fsinit>
    80001b5e:	bff9                	j	80001b3c <forkret+0x22>

0000000080001b60 <allocpid>:
allocpid() {
    80001b60:	1101                	addi	sp,sp,-32
    80001b62:	ec06                	sd	ra,24(sp)
    80001b64:	e822                	sd	s0,16(sp)
    80001b66:	e426                	sd	s1,8(sp)
    80001b68:	e04a                	sd	s2,0(sp)
    80001b6a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b6c:	0000f917          	auipc	s2,0xf
    80001b70:	73490913          	addi	s2,s2,1844 # 800112a0 <pid_lock>
    80001b74:	854a                	mv	a0,s2
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	06e080e7          	jalr	110(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b7e:	00007797          	auipc	a5,0x7
    80001b82:	ce678793          	addi	a5,a5,-794 # 80008864 <nextpid>
    80001b86:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b88:	0014871b          	addiw	a4,s1,1
    80001b8c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b8e:	854a                	mv	a0,s2
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	108080e7          	jalr	264(ra) # 80000c98 <release>
}
    80001b98:	8526                	mv	a0,s1
    80001b9a:	60e2                	ld	ra,24(sp)
    80001b9c:	6442                	ld	s0,16(sp)
    80001b9e:	64a2                	ld	s1,8(sp)
    80001ba0:	6902                	ld	s2,0(sp)
    80001ba2:	6105                	addi	sp,sp,32
    80001ba4:	8082                	ret

0000000080001ba6 <proc_pagetable>:
{
    80001ba6:	1101                	addi	sp,sp,-32
    80001ba8:	ec06                	sd	ra,24(sp)
    80001baa:	e822                	sd	s0,16(sp)
    80001bac:	e426                	sd	s1,8(sp)
    80001bae:	e04a                	sd	s2,0(sp)
    80001bb0:	1000                	addi	s0,sp,32
    80001bb2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bb4:	00000097          	auipc	ra,0x0
    80001bb8:	8b8080e7          	jalr	-1864(ra) # 8000146c <uvmcreate>
    80001bbc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bbe:	c121                	beqz	a0,80001bfe <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bc0:	4729                	li	a4,10
    80001bc2:	00005697          	auipc	a3,0x5
    80001bc6:	43e68693          	addi	a3,a3,1086 # 80007000 <_trampoline>
    80001bca:	6605                	lui	a2,0x1
    80001bcc:	040005b7          	lui	a1,0x4000
    80001bd0:	15fd                	addi	a1,a1,-1
    80001bd2:	05b2                	slli	a1,a1,0xc
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	60e080e7          	jalr	1550(ra) # 800011e2 <mappages>
    80001bdc:	02054863          	bltz	a0,80001c0c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001be0:	4719                	li	a4,6
    80001be2:	05893683          	ld	a3,88(s2)
    80001be6:	6605                	lui	a2,0x1
    80001be8:	020005b7          	lui	a1,0x2000
    80001bec:	15fd                	addi	a1,a1,-1
    80001bee:	05b6                	slli	a1,a1,0xd
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	5f0080e7          	jalr	1520(ra) # 800011e2 <mappages>
    80001bfa:	02054163          	bltz	a0,80001c1c <proc_pagetable+0x76>
}
    80001bfe:	8526                	mv	a0,s1
    80001c00:	60e2                	ld	ra,24(sp)
    80001c02:	6442                	ld	s0,16(sp)
    80001c04:	64a2                	ld	s1,8(sp)
    80001c06:	6902                	ld	s2,0(sp)
    80001c08:	6105                	addi	sp,sp,32
    80001c0a:	8082                	ret
    uvmfree(pagetable, 0);
    80001c0c:	4581                	li	a1,0
    80001c0e:	8526                	mv	a0,s1
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	a58080e7          	jalr	-1448(ra) # 80001668 <uvmfree>
    return 0;
    80001c18:	4481                	li	s1,0
    80001c1a:	b7d5                	j	80001bfe <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c1c:	4681                	li	a3,0
    80001c1e:	4605                	li	a2,1
    80001c20:	040005b7          	lui	a1,0x4000
    80001c24:	15fd                	addi	a1,a1,-1
    80001c26:	05b2                	slli	a1,a1,0xc
    80001c28:	8526                	mv	a0,s1
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	77e080e7          	jalr	1918(ra) # 800013a8 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c32:	4581                	li	a1,0
    80001c34:	8526                	mv	a0,s1
    80001c36:	00000097          	auipc	ra,0x0
    80001c3a:	a32080e7          	jalr	-1486(ra) # 80001668 <uvmfree>
    return 0;
    80001c3e:	4481                	li	s1,0
    80001c40:	bf7d                	j	80001bfe <proc_pagetable+0x58>

0000000080001c42 <proc_freepagetable>:
{
    80001c42:	1101                	addi	sp,sp,-32
    80001c44:	ec06                	sd	ra,24(sp)
    80001c46:	e822                	sd	s0,16(sp)
    80001c48:	e426                	sd	s1,8(sp)
    80001c4a:	e04a                	sd	s2,0(sp)
    80001c4c:	1000                	addi	s0,sp,32
    80001c4e:	84aa                	mv	s1,a0
    80001c50:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c52:	4681                	li	a3,0
    80001c54:	4605                	li	a2,1
    80001c56:	040005b7          	lui	a1,0x4000
    80001c5a:	15fd                	addi	a1,a1,-1
    80001c5c:	05b2                	slli	a1,a1,0xc
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	74a080e7          	jalr	1866(ra) # 800013a8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c66:	4681                	li	a3,0
    80001c68:	4605                	li	a2,1
    80001c6a:	020005b7          	lui	a1,0x2000
    80001c6e:	15fd                	addi	a1,a1,-1
    80001c70:	05b6                	slli	a1,a1,0xd
    80001c72:	8526                	mv	a0,s1
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	734080e7          	jalr	1844(ra) # 800013a8 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c7c:	85ca                	mv	a1,s2
    80001c7e:	8526                	mv	a0,s1
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	9e8080e7          	jalr	-1560(ra) # 80001668 <uvmfree>
}
    80001c88:	60e2                	ld	ra,24(sp)
    80001c8a:	6442                	ld	s0,16(sp)
    80001c8c:	64a2                	ld	s1,8(sp)
    80001c8e:	6902                	ld	s2,0(sp)
    80001c90:	6105                	addi	sp,sp,32
    80001c92:	8082                	ret

0000000080001c94 <freeproc>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	1000                	addi	s0,sp,32
    80001c9e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ca0:	6d28                	ld	a0,88(a0)
    80001ca2:	c509                	beqz	a0,80001cac <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	d54080e7          	jalr	-684(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001cac:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cb0:	68a8                	ld	a0,80(s1)
    80001cb2:	c511                	beqz	a0,80001cbe <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cb4:	64ac                	ld	a1,72(s1)
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	f8c080e7          	jalr	-116(ra) # 80001c42 <proc_freepagetable>
  p->pagetable = 0;
    80001cbe:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cc2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cc6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cca:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cce:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cd2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001cd6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001cda:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001cde:	0004ac23          	sw	zero,24(s1)
}
    80001ce2:	60e2                	ld	ra,24(sp)
    80001ce4:	6442                	ld	s0,16(sp)
    80001ce6:	64a2                	ld	s1,8(sp)
    80001ce8:	6105                	addi	sp,sp,32
    80001cea:	8082                	ret

0000000080001cec <allocproc>:
{
    80001cec:	1101                	addi	sp,sp,-32
    80001cee:	ec06                	sd	ra,24(sp)
    80001cf0:	e822                	sd	s0,16(sp)
    80001cf2:	e426                	sd	s1,8(sp)
    80001cf4:	e04a                	sd	s2,0(sp)
    80001cf6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf8:	00010497          	auipc	s1,0x10
    80001cfc:	9d848493          	addi	s1,s1,-1576 # 800116d0 <proc>
    80001d00:	00015917          	auipc	s2,0x15
    80001d04:	3d090913          	addi	s2,s2,976 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001d08:	8526                	mv	a0,s1
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	eda080e7          	jalr	-294(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001d12:	4c9c                	lw	a5,24(s1)
    80001d14:	cf81                	beqz	a5,80001d2c <allocproc+0x40>
      release(&p->lock);
    80001d16:	8526                	mv	a0,s1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	f80080e7          	jalr	-128(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d20:	16848493          	addi	s1,s1,360
    80001d24:	ff2492e3          	bne	s1,s2,80001d08 <allocproc+0x1c>
  return 0;
    80001d28:	4481                	li	s1,0
    80001d2a:	a889                	j	80001d7c <allocproc+0x90>
  p->pid = allocpid();
    80001d2c:	00000097          	auipc	ra,0x0
    80001d30:	e34080e7          	jalr	-460(ra) # 80001b60 <allocpid>
    80001d34:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d36:	4785                	li	a5,1
    80001d38:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	dba080e7          	jalr	-582(ra) # 80000af4 <kalloc>
    80001d42:	892a                	mv	s2,a0
    80001d44:	eca8                	sd	a0,88(s1)
    80001d46:	c131                	beqz	a0,80001d8a <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d48:	8526                	mv	a0,s1
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	e5c080e7          	jalr	-420(ra) # 80001ba6 <proc_pagetable>
    80001d52:	892a                	mv	s2,a0
    80001d54:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d56:	c531                	beqz	a0,80001da2 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d58:	07000613          	li	a2,112
    80001d5c:	4581                	li	a1,0
    80001d5e:	06048513          	addi	a0,s1,96
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	f7e080e7          	jalr	-130(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d6a:	00000797          	auipc	a5,0x0
    80001d6e:	db078793          	addi	a5,a5,-592 # 80001b1a <forkret>
    80001d72:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d74:	60bc                	ld	a5,64(s1)
    80001d76:	6705                	lui	a4,0x1
    80001d78:	97ba                	add	a5,a5,a4
    80001d7a:	f4bc                	sd	a5,104(s1)
}
    80001d7c:	8526                	mv	a0,s1
    80001d7e:	60e2                	ld	ra,24(sp)
    80001d80:	6442                	ld	s0,16(sp)
    80001d82:	64a2                	ld	s1,8(sp)
    80001d84:	6902                	ld	s2,0(sp)
    80001d86:	6105                	addi	sp,sp,32
    80001d88:	8082                	ret
    freeproc(p);
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	f08080e7          	jalr	-248(ra) # 80001c94 <freeproc>
    release(&p->lock);
    80001d94:	8526                	mv	a0,s1
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	f02080e7          	jalr	-254(ra) # 80000c98 <release>
    return 0;
    80001d9e:	84ca                	mv	s1,s2
    80001da0:	bff1                	j	80001d7c <allocproc+0x90>
    freeproc(p);
    80001da2:	8526                	mv	a0,s1
    80001da4:	00000097          	auipc	ra,0x0
    80001da8:	ef0080e7          	jalr	-272(ra) # 80001c94 <freeproc>
    release(&p->lock);
    80001dac:	8526                	mv	a0,s1
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	eea080e7          	jalr	-278(ra) # 80000c98 <release>
    return 0;
    80001db6:	84ca                	mv	s1,s2
    80001db8:	b7d1                	j	80001d7c <allocproc+0x90>

0000000080001dba <userinit>:
{
    80001dba:	1101                	addi	sp,sp,-32
    80001dbc:	ec06                	sd	ra,24(sp)
    80001dbe:	e822                	sd	s0,16(sp)
    80001dc0:	e426                	sd	s1,8(sp)
    80001dc2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	f28080e7          	jalr	-216(ra) # 80001cec <allocproc>
    80001dcc:	84aa                	mv	s1,a0
  initproc = p;
    80001dce:	00007797          	auipc	a5,0x7
    80001dd2:	24a7bd23          	sd	a0,602(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dd6:	03400613          	li	a2,52
    80001dda:	00007597          	auipc	a1,0x7
    80001dde:	a9658593          	addi	a1,a1,-1386 # 80008870 <initcode>
    80001de2:	6928                	ld	a0,80(a0)
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	6b6080e7          	jalr	1718(ra) # 8000149a <uvminit>
  p->sz = PGSIZE;
    80001dec:	6785                	lui	a5,0x1
    80001dee:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001df0:	6cb8                	ld	a4,88(s1)
    80001df2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001df6:	6cb8                	ld	a4,88(s1)
    80001df8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dfa:	4641                	li	a2,16
    80001dfc:	00006597          	auipc	a1,0x6
    80001e00:	44458593          	addi	a1,a1,1092 # 80008240 <digits+0x200>
    80001e04:	15848513          	addi	a0,s1,344
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	02a080e7          	jalr	42(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001e10:	00006517          	auipc	a0,0x6
    80001e14:	44050513          	addi	a0,a0,1088 # 80008250 <digits+0x210>
    80001e18:	00002097          	auipc	ra,0x2
    80001e1c:	232080e7          	jalr	562(ra) # 8000404a <namei>
    80001e20:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e24:	478d                	li	a5,3
    80001e26:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e28:	8526                	mv	a0,s1
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	e6e080e7          	jalr	-402(ra) # 80000c98 <release>
}
    80001e32:	60e2                	ld	ra,24(sp)
    80001e34:	6442                	ld	s0,16(sp)
    80001e36:	64a2                	ld	s1,8(sp)
    80001e38:	6105                	addi	sp,sp,32
    80001e3a:	8082                	ret

0000000080001e3c <growproc>:
{
    80001e3c:	1101                	addi	sp,sp,-32
    80001e3e:	ec06                	sd	ra,24(sp)
    80001e40:	e822                	sd	s0,16(sp)
    80001e42:	e426                	sd	s1,8(sp)
    80001e44:	e04a                	sd	s2,0(sp)
    80001e46:	1000                	addi	s0,sp,32
    80001e48:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e4a:	00000097          	auipc	ra,0x0
    80001e4e:	c98080e7          	jalr	-872(ra) # 80001ae2 <myproc>
    80001e52:	892a                	mv	s2,a0
  sz = p->sz;
    80001e54:	652c                	ld	a1,72(a0)
    80001e56:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e5a:	00904f63          	bgtz	s1,80001e78 <growproc+0x3c>
  } else if(n < 0){
    80001e5e:	0204cc63          	bltz	s1,80001e96 <growproc+0x5a>
  p->sz = sz;
    80001e62:	1602                	slli	a2,a2,0x20
    80001e64:	9201                	srli	a2,a2,0x20
    80001e66:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e6a:	4501                	li	a0,0
}
    80001e6c:	60e2                	ld	ra,24(sp)
    80001e6e:	6442                	ld	s0,16(sp)
    80001e70:	64a2                	ld	s1,8(sp)
    80001e72:	6902                	ld	s2,0(sp)
    80001e74:	6105                	addi	sp,sp,32
    80001e76:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e78:	9e25                	addw	a2,a2,s1
    80001e7a:	1602                	slli	a2,a2,0x20
    80001e7c:	9201                	srli	a2,a2,0x20
    80001e7e:	1582                	slli	a1,a1,0x20
    80001e80:	9181                	srli	a1,a1,0x20
    80001e82:	6928                	ld	a0,80(a0)
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	6d0080e7          	jalr	1744(ra) # 80001554 <uvmalloc>
    80001e8c:	0005061b          	sext.w	a2,a0
    80001e90:	fa69                	bnez	a2,80001e62 <growproc+0x26>
      return -1;
    80001e92:	557d                	li	a0,-1
    80001e94:	bfe1                	j	80001e6c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e96:	9e25                	addw	a2,a2,s1
    80001e98:	1602                	slli	a2,a2,0x20
    80001e9a:	9201                	srli	a2,a2,0x20
    80001e9c:	1582                	slli	a1,a1,0x20
    80001e9e:	9181                	srli	a1,a1,0x20
    80001ea0:	6928                	ld	a0,80(a0)
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	66a080e7          	jalr	1642(ra) # 8000150c <uvmdealloc>
    80001eaa:	0005061b          	sext.w	a2,a0
    80001eae:	bf55                	j	80001e62 <growproc+0x26>

0000000080001eb0 <fork>:
{
    80001eb0:	7179                	addi	sp,sp,-48
    80001eb2:	f406                	sd	ra,40(sp)
    80001eb4:	f022                	sd	s0,32(sp)
    80001eb6:	ec26                	sd	s1,24(sp)
    80001eb8:	e84a                	sd	s2,16(sp)
    80001eba:	e44e                	sd	s3,8(sp)
    80001ebc:	e052                	sd	s4,0(sp)
    80001ebe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ec0:	00000097          	auipc	ra,0x0
    80001ec4:	c22080e7          	jalr	-990(ra) # 80001ae2 <myproc>
    80001ec8:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001eca:	00000097          	auipc	ra,0x0
    80001ece:	e22080e7          	jalr	-478(ra) # 80001cec <allocproc>
    80001ed2:	10050b63          	beqz	a0,80001fe8 <fork+0x138>
    80001ed6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ed8:	04893603          	ld	a2,72(s2)
    80001edc:	692c                	ld	a1,80(a0)
    80001ede:	05093503          	ld	a0,80(s2)
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	7be080e7          	jalr	1982(ra) # 800016a0 <uvmcopy>
    80001eea:	04054663          	bltz	a0,80001f36 <fork+0x86>
  np->sz = p->sz;
    80001eee:	04893783          	ld	a5,72(s2)
    80001ef2:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ef6:	05893683          	ld	a3,88(s2)
    80001efa:	87b6                	mv	a5,a3
    80001efc:	0589b703          	ld	a4,88(s3)
    80001f00:	12068693          	addi	a3,a3,288
    80001f04:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f08:	6788                	ld	a0,8(a5)
    80001f0a:	6b8c                	ld	a1,16(a5)
    80001f0c:	6f90                	ld	a2,24(a5)
    80001f0e:	01073023          	sd	a6,0(a4)
    80001f12:	e708                	sd	a0,8(a4)
    80001f14:	eb0c                	sd	a1,16(a4)
    80001f16:	ef10                	sd	a2,24(a4)
    80001f18:	02078793          	addi	a5,a5,32
    80001f1c:	02070713          	addi	a4,a4,32
    80001f20:	fed792e3          	bne	a5,a3,80001f04 <fork+0x54>
  np->trapframe->a0 = 0;
    80001f24:	0589b783          	ld	a5,88(s3)
    80001f28:	0607b823          	sd	zero,112(a5)
    80001f2c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f30:	15000a13          	li	s4,336
    80001f34:	a03d                	j	80001f62 <fork+0xb2>
    freeproc(np);
    80001f36:	854e                	mv	a0,s3
    80001f38:	00000097          	auipc	ra,0x0
    80001f3c:	d5c080e7          	jalr	-676(ra) # 80001c94 <freeproc>
    release(&np->lock);
    80001f40:	854e                	mv	a0,s3
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d56080e7          	jalr	-682(ra) # 80000c98 <release>
    return -1;
    80001f4a:	5a7d                	li	s4,-1
    80001f4c:	a069                	j	80001fd6 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f4e:	00002097          	auipc	ra,0x2
    80001f52:	792080e7          	jalr	1938(ra) # 800046e0 <filedup>
    80001f56:	009987b3          	add	a5,s3,s1
    80001f5a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f5c:	04a1                	addi	s1,s1,8
    80001f5e:	01448763          	beq	s1,s4,80001f6c <fork+0xbc>
    if(p->ofile[i])
    80001f62:	009907b3          	add	a5,s2,s1
    80001f66:	6388                	ld	a0,0(a5)
    80001f68:	f17d                	bnez	a0,80001f4e <fork+0x9e>
    80001f6a:	bfcd                	j	80001f5c <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f6c:	15093503          	ld	a0,336(s2)
    80001f70:	00002097          	auipc	ra,0x2
    80001f74:	8e6080e7          	jalr	-1818(ra) # 80003856 <idup>
    80001f78:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f7c:	4641                	li	a2,16
    80001f7e:	15890593          	addi	a1,s2,344
    80001f82:	15898513          	addi	a0,s3,344
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	eac080e7          	jalr	-340(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f8e:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f92:	854e                	mv	a0,s3
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	d04080e7          	jalr	-764(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f9c:	0000f497          	auipc	s1,0xf
    80001fa0:	31c48493          	addi	s1,s1,796 # 800112b8 <wait_lock>
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	c3e080e7          	jalr	-962(ra) # 80000be4 <acquire>
  np->parent = p;
    80001fae:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	ce4080e7          	jalr	-796(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001fbc:	854e                	mv	a0,s3
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c26080e7          	jalr	-986(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001fc6:	478d                	li	a5,3
    80001fc8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fcc:	854e                	mv	a0,s3
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	cca080e7          	jalr	-822(ra) # 80000c98 <release>
}
    80001fd6:	8552                	mv	a0,s4
    80001fd8:	70a2                	ld	ra,40(sp)
    80001fda:	7402                	ld	s0,32(sp)
    80001fdc:	64e2                	ld	s1,24(sp)
    80001fde:	6942                	ld	s2,16(sp)
    80001fe0:	69a2                	ld	s3,8(sp)
    80001fe2:	6a02                	ld	s4,0(sp)
    80001fe4:	6145                	addi	sp,sp,48
    80001fe6:	8082                	ret
    return -1;
    80001fe8:	5a7d                	li	s4,-1
    80001fea:	b7f5                	j	80001fd6 <fork+0x126>

0000000080001fec <scheduler>:
{
    80001fec:	7139                	addi	sp,sp,-64
    80001fee:	fc06                	sd	ra,56(sp)
    80001ff0:	f822                	sd	s0,48(sp)
    80001ff2:	f426                	sd	s1,40(sp)
    80001ff4:	f04a                	sd	s2,32(sp)
    80001ff6:	ec4e                	sd	s3,24(sp)
    80001ff8:	e852                	sd	s4,16(sp)
    80001ffa:	e456                	sd	s5,8(sp)
    80001ffc:	e05a                	sd	s6,0(sp)
    80001ffe:	0080                	addi	s0,sp,64
    80002000:	8792                	mv	a5,tp
  int id = r_tp();
    80002002:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002004:	00779a93          	slli	s5,a5,0x7
    80002008:	0000f717          	auipc	a4,0xf
    8000200c:	29870713          	addi	a4,a4,664 # 800112a0 <pid_lock>
    80002010:	9756                	add	a4,a4,s5
    80002012:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002016:	0000f717          	auipc	a4,0xf
    8000201a:	2c270713          	addi	a4,a4,706 # 800112d8 <cpus+0x8>
    8000201e:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002020:	498d                	li	s3,3
        p->state = RUNNING;
    80002022:	4b11                	li	s6,4
        c->proc = p;
    80002024:	079e                	slli	a5,a5,0x7
    80002026:	0000fa17          	auipc	s4,0xf
    8000202a:	27aa0a13          	addi	s4,s4,634 # 800112a0 <pid_lock>
    8000202e:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002030:	00015917          	auipc	s2,0x15
    80002034:	0a090913          	addi	s2,s2,160 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002038:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000203c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002040:	10079073          	csrw	sstatus,a5
    80002044:	0000f497          	auipc	s1,0xf
    80002048:	68c48493          	addi	s1,s1,1676 # 800116d0 <proc>
    8000204c:	a03d                	j	8000207a <scheduler+0x8e>
        p->state = RUNNING;
    8000204e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002052:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002056:	06048593          	addi	a1,s1,96
    8000205a:	8556                	mv	a0,s5
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	78a080e7          	jalr	1930(ra) # 800027e6 <swtch>
        c->proc = 0;
    80002064:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80002068:	8526                	mv	a0,s1
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	c2e080e7          	jalr	-978(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002072:	16848493          	addi	s1,s1,360
    80002076:	fd2481e3          	beq	s1,s2,80002038 <scheduler+0x4c>
      acquire(&p->lock);
    8000207a:	8526                	mv	a0,s1
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	b68080e7          	jalr	-1176(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002084:	4c9c                	lw	a5,24(s1)
    80002086:	ff3791e3          	bne	a5,s3,80002068 <scheduler+0x7c>
    8000208a:	b7d1                	j	8000204e <scheduler+0x62>

000000008000208c <sched>:
{
    8000208c:	7179                	addi	sp,sp,-48
    8000208e:	f406                	sd	ra,40(sp)
    80002090:	f022                	sd	s0,32(sp)
    80002092:	ec26                	sd	s1,24(sp)
    80002094:	e84a                	sd	s2,16(sp)
    80002096:	e44e                	sd	s3,8(sp)
    80002098:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	a48080e7          	jalr	-1464(ra) # 80001ae2 <myproc>
    800020a2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	ac6080e7          	jalr	-1338(ra) # 80000b6a <holding>
    800020ac:	c93d                	beqz	a0,80002122 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ae:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020b0:	2781                	sext.w	a5,a5
    800020b2:	079e                	slli	a5,a5,0x7
    800020b4:	0000f717          	auipc	a4,0xf
    800020b8:	1ec70713          	addi	a4,a4,492 # 800112a0 <pid_lock>
    800020bc:	97ba                	add	a5,a5,a4
    800020be:	0a87a703          	lw	a4,168(a5)
    800020c2:	4785                	li	a5,1
    800020c4:	06f71763          	bne	a4,a5,80002132 <sched+0xa6>
  if(p->state == RUNNING)
    800020c8:	4c98                	lw	a4,24(s1)
    800020ca:	4791                	li	a5,4
    800020cc:	06f70b63          	beq	a4,a5,80002142 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020d4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020d6:	efb5                	bnez	a5,80002152 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020da:	0000f917          	auipc	s2,0xf
    800020de:	1c690913          	addi	s2,s2,454 # 800112a0 <pid_lock>
    800020e2:	2781                	sext.w	a5,a5
    800020e4:	079e                	slli	a5,a5,0x7
    800020e6:	97ca                	add	a5,a5,s2
    800020e8:	0ac7a983          	lw	s3,172(a5)
    800020ec:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020ee:	2781                	sext.w	a5,a5
    800020f0:	079e                	slli	a5,a5,0x7
    800020f2:	0000f597          	auipc	a1,0xf
    800020f6:	1e658593          	addi	a1,a1,486 # 800112d8 <cpus+0x8>
    800020fa:	95be                	add	a1,a1,a5
    800020fc:	06048513          	addi	a0,s1,96
    80002100:	00000097          	auipc	ra,0x0
    80002104:	6e6080e7          	jalr	1766(ra) # 800027e6 <swtch>
    80002108:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000210a:	2781                	sext.w	a5,a5
    8000210c:	079e                	slli	a5,a5,0x7
    8000210e:	97ca                	add	a5,a5,s2
    80002110:	0b37a623          	sw	s3,172(a5)
}
    80002114:	70a2                	ld	ra,40(sp)
    80002116:	7402                	ld	s0,32(sp)
    80002118:	64e2                	ld	s1,24(sp)
    8000211a:	6942                	ld	s2,16(sp)
    8000211c:	69a2                	ld	s3,8(sp)
    8000211e:	6145                	addi	sp,sp,48
    80002120:	8082                	ret
    panic("sched p->lock");
    80002122:	00006517          	auipc	a0,0x6
    80002126:	13650513          	addi	a0,a0,310 # 80008258 <digits+0x218>
    8000212a:	ffffe097          	auipc	ra,0xffffe
    8000212e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
    panic("sched locks");
    80002132:	00006517          	auipc	a0,0x6
    80002136:	13650513          	addi	a0,a0,310 # 80008268 <digits+0x228>
    8000213a:	ffffe097          	auipc	ra,0xffffe
    8000213e:	404080e7          	jalr	1028(ra) # 8000053e <panic>
    panic("sched running");
    80002142:	00006517          	auipc	a0,0x6
    80002146:	13650513          	addi	a0,a0,310 # 80008278 <digits+0x238>
    8000214a:	ffffe097          	auipc	ra,0xffffe
    8000214e:	3f4080e7          	jalr	1012(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002152:	00006517          	auipc	a0,0x6
    80002156:	13650513          	addi	a0,a0,310 # 80008288 <digits+0x248>
    8000215a:	ffffe097          	auipc	ra,0xffffe
    8000215e:	3e4080e7          	jalr	996(ra) # 8000053e <panic>

0000000080002162 <yield>:
{
    80002162:	1101                	addi	sp,sp,-32
    80002164:	ec06                	sd	ra,24(sp)
    80002166:	e822                	sd	s0,16(sp)
    80002168:	e426                	sd	s1,8(sp)
    8000216a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000216c:	00000097          	auipc	ra,0x0
    80002170:	976080e7          	jalr	-1674(ra) # 80001ae2 <myproc>
    80002174:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	a6e080e7          	jalr	-1426(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000217e:	478d                	li	a5,3
    80002180:	cc9c                	sw	a5,24(s1)
  sched();
    80002182:	00000097          	auipc	ra,0x0
    80002186:	f0a080e7          	jalr	-246(ra) # 8000208c <sched>
  release(&p->lock);
    8000218a:	8526                	mv	a0,s1
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	b0c080e7          	jalr	-1268(ra) # 80000c98 <release>
}
    80002194:	60e2                	ld	ra,24(sp)
    80002196:	6442                	ld	s0,16(sp)
    80002198:	64a2                	ld	s1,8(sp)
    8000219a:	6105                	addi	sp,sp,32
    8000219c:	8082                	ret

000000008000219e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000219e:	7179                	addi	sp,sp,-48
    800021a0:	f406                	sd	ra,40(sp)
    800021a2:	f022                	sd	s0,32(sp)
    800021a4:	ec26                	sd	s1,24(sp)
    800021a6:	e84a                	sd	s2,16(sp)
    800021a8:	e44e                	sd	s3,8(sp)
    800021aa:	1800                	addi	s0,sp,48
    800021ac:	89aa                	mv	s3,a0
    800021ae:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	932080e7          	jalr	-1742(ra) # 80001ae2 <myproc>
    800021b8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	a2a080e7          	jalr	-1494(ra) # 80000be4 <acquire>
  release(lk);
    800021c2:	854a                	mv	a0,s2
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ad4080e7          	jalr	-1324(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800021cc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021d0:	4789                	li	a5,2
    800021d2:	cc9c                	sw	a5,24(s1)

  sched();
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	eb8080e7          	jalr	-328(ra) # 8000208c <sched>

  // Tidy up.
  p->chan = 0;
    800021dc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021e0:	8526                	mv	a0,s1
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	ab6080e7          	jalr	-1354(ra) # 80000c98 <release>
  acquire(lk);
    800021ea:	854a                	mv	a0,s2
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	9f8080e7          	jalr	-1544(ra) # 80000be4 <acquire>
}
    800021f4:	70a2                	ld	ra,40(sp)
    800021f6:	7402                	ld	s0,32(sp)
    800021f8:	64e2                	ld	s1,24(sp)
    800021fa:	6942                	ld	s2,16(sp)
    800021fc:	69a2                	ld	s3,8(sp)
    800021fe:	6145                	addi	sp,sp,48
    80002200:	8082                	ret

0000000080002202 <pause_system>:
pause_system(int seconds){
    80002202:	710d                	addi	sp,sp,-352
    80002204:	ee86                	sd	ra,344(sp)
    80002206:	eaa2                	sd	s0,336(sp)
    80002208:	e6a6                	sd	s1,328(sp)
    8000220a:	e2ca                	sd	s2,320(sp)
    8000220c:	fe4e                	sd	s3,312(sp)
    8000220e:	fa52                	sd	s4,304(sp)
    80002210:	f656                	sd	s5,296(sp)
    80002212:	f25a                	sd	s6,288(sp)
    80002214:	ee5e                	sd	s7,280(sp)
    80002216:	ea62                	sd	s8,272(sp)
    80002218:	1280                	addi	s0,sp,352
  uint ticks0 = seconds * 1000000; // * 1,000,000?
    8000221a:	000f47b7          	lui	a5,0xf4
    8000221e:	2407879b          	addiw	a5,a5,576
    80002222:	02f507bb          	mulw	a5,a0,a5
    80002226:	eaf42623          	sw	a5,-340(s0)
  if(seconds < 0)
    8000222a:	0c054463          	bltz	a0,800022f2 <pause_system+0xf0>
    8000222e:	0000f917          	auipc	s2,0xf
    80002232:	4a290913          	addi	s2,s2,1186 # 800116d0 <proc>
    80002236:	eb040993          	addi	s3,s0,-336
    8000223a:	00015a97          	auipc	s5,0x15
    8000223e:	e96a8a93          	addi	s5,s5,-362 # 800170d0 <tickslock>
    80002242:	8a4e                	mv	s4,s3
    80002244:	84ca                	mv	s1,s2
    if(proc[i].state == RUNNING)
    80002246:	4b91                	li	s7,4
      proc[i].state = RUNNABLE;
    80002248:	4c0d                	li	s8,3
    8000224a:	a819                	j	80002260 <pause_system+0x5e>
    release(&proc[i].lock);
    8000224c:	855a                	mv	a0,s6
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	a4a080e7          	jalr	-1462(ra) # 80000c98 <release>
  for (int i = 0; i < NPROC; i++)
    80002256:	16848493          	addi	s1,s1,360
    8000225a:	0a11                	addi	s4,s4,4
    8000225c:	03548163          	beq	s1,s5,8000227e <pause_system+0x7c>
    prevState[i] = proc[i].state;
    80002260:	8b26                	mv	s6,s1
    80002262:	4c9c                	lw	a5,24(s1)
    80002264:	00fa2023          	sw	a5,0(s4)
    acquire(&proc[i].lock);
    80002268:	8526                	mv	a0,s1
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	97a080e7          	jalr	-1670(ra) # 80000be4 <acquire>
    if(proc[i].state == RUNNING)
    80002272:	4c9c                	lw	a5,24(s1)
    80002274:	fd779ce3          	bne	a5,s7,8000224c <pause_system+0x4a>
      proc[i].state = RUNNABLE;
    80002278:	0184ac23          	sw	s8,24(s1)
    8000227c:	bfc1                	j	8000224c <pause_system+0x4a>
  acquire(&tickslock);
    8000227e:	00015517          	auipc	a0,0x15
    80002282:	e5250513          	addi	a0,a0,-430 # 800170d0 <tickslock>
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	95e080e7          	jalr	-1698(ra) # 80000be4 <acquire>
  sleep(&ticks0, &tickslock);
    8000228e:	00015597          	auipc	a1,0x15
    80002292:	e4258593          	addi	a1,a1,-446 # 800170d0 <tickslock>
    80002296:	eac40513          	addi	a0,s0,-340
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	f04080e7          	jalr	-252(ra) # 8000219e <sleep>
  release(&tickslock);
    800022a2:	00015517          	auipc	a0,0x15
    800022a6:	e2e50513          	addi	a0,a0,-466 # 800170d0 <tickslock>
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	9ee080e7          	jalr	-1554(ra) # 80000c98 <release>
    acquire(&proc[i].lock);
    800022b2:	854a                	mv	a0,s2
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	930080e7          	jalr	-1744(ra) # 80000be4 <acquire>
    proc[i].state = prevState[i];
    800022bc:	0009a783          	lw	a5,0(s3)
    800022c0:	00f92c23          	sw	a5,24(s2)
    release(&proc[i].lock);
    800022c4:	854a                	mv	a0,s2
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	9d2080e7          	jalr	-1582(ra) # 80000c98 <release>
  for (int i = 0; i < NPROC; i++){
    800022ce:	16890913          	addi	s2,s2,360
    800022d2:	0991                	addi	s3,s3,4
    800022d4:	fd591fe3          	bne	s2,s5,800022b2 <pause_system+0xb0>
  return 0;
    800022d8:	4501                	li	a0,0
}
    800022da:	60f6                	ld	ra,344(sp)
    800022dc:	6456                	ld	s0,336(sp)
    800022de:	64b6                	ld	s1,328(sp)
    800022e0:	6916                	ld	s2,320(sp)
    800022e2:	79f2                	ld	s3,312(sp)
    800022e4:	7a52                	ld	s4,304(sp)
    800022e6:	7ab2                	ld	s5,296(sp)
    800022e8:	7b12                	ld	s6,288(sp)
    800022ea:	6bf2                	ld	s7,280(sp)
    800022ec:	6c52                	ld	s8,272(sp)
    800022ee:	6135                	addi	sp,sp,352
    800022f0:	8082                	ret
    return -1;
    800022f2:	557d                	li	a0,-1
    800022f4:	b7dd                	j	800022da <pause_system+0xd8>

00000000800022f6 <wait>:
{
    800022f6:	715d                	addi	sp,sp,-80
    800022f8:	e486                	sd	ra,72(sp)
    800022fa:	e0a2                	sd	s0,64(sp)
    800022fc:	fc26                	sd	s1,56(sp)
    800022fe:	f84a                	sd	s2,48(sp)
    80002300:	f44e                	sd	s3,40(sp)
    80002302:	f052                	sd	s4,32(sp)
    80002304:	ec56                	sd	s5,24(sp)
    80002306:	e85a                	sd	s6,16(sp)
    80002308:	e45e                	sd	s7,8(sp)
    8000230a:	e062                	sd	s8,0(sp)
    8000230c:	0880                	addi	s0,sp,80
    8000230e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	7d2080e7          	jalr	2002(ra) # 80001ae2 <myproc>
    80002318:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000231a:	0000f517          	auipc	a0,0xf
    8000231e:	f9e50513          	addi	a0,a0,-98 # 800112b8 <wait_lock>
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	8c2080e7          	jalr	-1854(ra) # 80000be4 <acquire>
    havekids = 0;
    8000232a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000232c:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000232e:	00015997          	auipc	s3,0x15
    80002332:	da298993          	addi	s3,s3,-606 # 800170d0 <tickslock>
        havekids = 1;
    80002336:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002338:	0000fc17          	auipc	s8,0xf
    8000233c:	f80c0c13          	addi	s8,s8,-128 # 800112b8 <wait_lock>
    havekids = 0;
    80002340:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002342:	0000f497          	auipc	s1,0xf
    80002346:	38e48493          	addi	s1,s1,910 # 800116d0 <proc>
    8000234a:	a0bd                	j	800023b8 <wait+0xc2>
          pid = np->pid;
    8000234c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002350:	000b0e63          	beqz	s6,8000236c <wait+0x76>
    80002354:	4691                	li	a3,4
    80002356:	02c48613          	addi	a2,s1,44
    8000235a:	85da                	mv	a1,s6
    8000235c:	05093503          	ld	a0,80(s2)
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	444080e7          	jalr	1092(ra) # 800017a4 <copyout>
    80002368:	02054563          	bltz	a0,80002392 <wait+0x9c>
          freeproc(np);
    8000236c:	8526                	mv	a0,s1
    8000236e:	00000097          	auipc	ra,0x0
    80002372:	926080e7          	jalr	-1754(ra) # 80001c94 <freeproc>
          release(&np->lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	920080e7          	jalr	-1760(ra) # 80000c98 <release>
          release(&wait_lock);
    80002380:	0000f517          	auipc	a0,0xf
    80002384:	f3850513          	addi	a0,a0,-200 # 800112b8 <wait_lock>
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	910080e7          	jalr	-1776(ra) # 80000c98 <release>
          return pid;
    80002390:	a09d                	j	800023f6 <wait+0x100>
            release(&np->lock);
    80002392:	8526                	mv	a0,s1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	904080e7          	jalr	-1788(ra) # 80000c98 <release>
            release(&wait_lock);
    8000239c:	0000f517          	auipc	a0,0xf
    800023a0:	f1c50513          	addi	a0,a0,-228 # 800112b8 <wait_lock>
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	8f4080e7          	jalr	-1804(ra) # 80000c98 <release>
            return -1;
    800023ac:	59fd                	li	s3,-1
    800023ae:	a0a1                	j	800023f6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800023b0:	16848493          	addi	s1,s1,360
    800023b4:	03348463          	beq	s1,s3,800023dc <wait+0xe6>
      if(np->parent == p){
    800023b8:	7c9c                	ld	a5,56(s1)
    800023ba:	ff279be3          	bne	a5,s2,800023b0 <wait+0xba>
        acquire(&np->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	824080e7          	jalr	-2012(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800023c8:	4c9c                	lw	a5,24(s1)
    800023ca:	f94781e3          	beq	a5,s4,8000234c <wait+0x56>
        release(&np->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8c8080e7          	jalr	-1848(ra) # 80000c98 <release>
        havekids = 1;
    800023d8:	8756                	mv	a4,s5
    800023da:	bfd9                	j	800023b0 <wait+0xba>
    if(!havekids || p->killed){
    800023dc:	c701                	beqz	a4,800023e4 <wait+0xee>
    800023de:	02892783          	lw	a5,40(s2)
    800023e2:	c79d                	beqz	a5,80002410 <wait+0x11a>
      release(&wait_lock);
    800023e4:	0000f517          	auipc	a0,0xf
    800023e8:	ed450513          	addi	a0,a0,-300 # 800112b8 <wait_lock>
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	8ac080e7          	jalr	-1876(ra) # 80000c98 <release>
      return -1;
    800023f4:	59fd                	li	s3,-1
}
    800023f6:	854e                	mv	a0,s3
    800023f8:	60a6                	ld	ra,72(sp)
    800023fa:	6406                	ld	s0,64(sp)
    800023fc:	74e2                	ld	s1,56(sp)
    800023fe:	7942                	ld	s2,48(sp)
    80002400:	79a2                	ld	s3,40(sp)
    80002402:	7a02                	ld	s4,32(sp)
    80002404:	6ae2                	ld	s5,24(sp)
    80002406:	6b42                	ld	s6,16(sp)
    80002408:	6ba2                	ld	s7,8(sp)
    8000240a:	6c02                	ld	s8,0(sp)
    8000240c:	6161                	addi	sp,sp,80
    8000240e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002410:	85e2                	mv	a1,s8
    80002412:	854a                	mv	a0,s2
    80002414:	00000097          	auipc	ra,0x0
    80002418:	d8a080e7          	jalr	-630(ra) # 8000219e <sleep>
    havekids = 0;
    8000241c:	b715                	j	80002340 <wait+0x4a>

000000008000241e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000241e:	7139                	addi	sp,sp,-64
    80002420:	fc06                	sd	ra,56(sp)
    80002422:	f822                	sd	s0,48(sp)
    80002424:	f426                	sd	s1,40(sp)
    80002426:	f04a                	sd	s2,32(sp)
    80002428:	ec4e                	sd	s3,24(sp)
    8000242a:	e852                	sd	s4,16(sp)
    8000242c:	e456                	sd	s5,8(sp)
    8000242e:	0080                	addi	s0,sp,64
    80002430:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002432:	0000f497          	auipc	s1,0xf
    80002436:	29e48493          	addi	s1,s1,670 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000243a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000243c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000243e:	00015917          	auipc	s2,0x15
    80002442:	c9290913          	addi	s2,s2,-878 # 800170d0 <tickslock>
    80002446:	a821                	j	8000245e <wakeup+0x40>
        p->state = RUNNABLE;
    80002448:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	84a080e7          	jalr	-1974(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002456:	16848493          	addi	s1,s1,360
    8000245a:	03248463          	beq	s1,s2,80002482 <wakeup+0x64>
    if(p != myproc()){
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	684080e7          	jalr	1668(ra) # 80001ae2 <myproc>
    80002466:	fea488e3          	beq	s1,a0,80002456 <wakeup+0x38>
      acquire(&p->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	ffffe097          	auipc	ra,0xffffe
    80002470:	778080e7          	jalr	1912(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002474:	4c9c                	lw	a5,24(s1)
    80002476:	fd379be3          	bne	a5,s3,8000244c <wakeup+0x2e>
    8000247a:	709c                	ld	a5,32(s1)
    8000247c:	fd4798e3          	bne	a5,s4,8000244c <wakeup+0x2e>
    80002480:	b7e1                	j	80002448 <wakeup+0x2a>
    }
  }
}
    80002482:	70e2                	ld	ra,56(sp)
    80002484:	7442                	ld	s0,48(sp)
    80002486:	74a2                	ld	s1,40(sp)
    80002488:	7902                	ld	s2,32(sp)
    8000248a:	69e2                	ld	s3,24(sp)
    8000248c:	6a42                	ld	s4,16(sp)
    8000248e:	6aa2                	ld	s5,8(sp)
    80002490:	6121                	addi	sp,sp,64
    80002492:	8082                	ret

0000000080002494 <reparent>:
{
    80002494:	7179                	addi	sp,sp,-48
    80002496:	f406                	sd	ra,40(sp)
    80002498:	f022                	sd	s0,32(sp)
    8000249a:	ec26                	sd	s1,24(sp)
    8000249c:	e84a                	sd	s2,16(sp)
    8000249e:	e44e                	sd	s3,8(sp)
    800024a0:	e052                	sd	s4,0(sp)
    800024a2:	1800                	addi	s0,sp,48
    800024a4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024a6:	0000f497          	auipc	s1,0xf
    800024aa:	22a48493          	addi	s1,s1,554 # 800116d0 <proc>
      pp->parent = initproc;
    800024ae:	00007a17          	auipc	s4,0x7
    800024b2:	b7aa0a13          	addi	s4,s4,-1158 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024b6:	00015997          	auipc	s3,0x15
    800024ba:	c1a98993          	addi	s3,s3,-998 # 800170d0 <tickslock>
    800024be:	a029                	j	800024c8 <reparent+0x34>
    800024c0:	16848493          	addi	s1,s1,360
    800024c4:	01348d63          	beq	s1,s3,800024de <reparent+0x4a>
    if(pp->parent == p){
    800024c8:	7c9c                	ld	a5,56(s1)
    800024ca:	ff279be3          	bne	a5,s2,800024c0 <reparent+0x2c>
      pp->parent = initproc;
    800024ce:	000a3503          	ld	a0,0(s4)
    800024d2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024d4:	00000097          	auipc	ra,0x0
    800024d8:	f4a080e7          	jalr	-182(ra) # 8000241e <wakeup>
    800024dc:	b7d5                	j	800024c0 <reparent+0x2c>
}
    800024de:	70a2                	ld	ra,40(sp)
    800024e0:	7402                	ld	s0,32(sp)
    800024e2:	64e2                	ld	s1,24(sp)
    800024e4:	6942                	ld	s2,16(sp)
    800024e6:	69a2                	ld	s3,8(sp)
    800024e8:	6a02                	ld	s4,0(sp)
    800024ea:	6145                	addi	sp,sp,48
    800024ec:	8082                	ret

00000000800024ee <exit>:
{
    800024ee:	7179                	addi	sp,sp,-48
    800024f0:	f406                	sd	ra,40(sp)
    800024f2:	f022                	sd	s0,32(sp)
    800024f4:	ec26                	sd	s1,24(sp)
    800024f6:	e84a                	sd	s2,16(sp)
    800024f8:	e44e                	sd	s3,8(sp)
    800024fa:	e052                	sd	s4,0(sp)
    800024fc:	1800                	addi	s0,sp,48
    800024fe:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	5e2080e7          	jalr	1506(ra) # 80001ae2 <myproc>
    80002508:	89aa                	mv	s3,a0
  if(p == initproc)
    8000250a:	00007797          	auipc	a5,0x7
    8000250e:	b1e7b783          	ld	a5,-1250(a5) # 80009028 <initproc>
    80002512:	0d050493          	addi	s1,a0,208
    80002516:	15050913          	addi	s2,a0,336
    8000251a:	02a79363          	bne	a5,a0,80002540 <exit+0x52>
    panic("init exiting");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	d8250513          	addi	a0,a0,-638 # 800082a0 <digits+0x260>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	018080e7          	jalr	24(ra) # 8000053e <panic>
      fileclose(f);
    8000252e:	00002097          	auipc	ra,0x2
    80002532:	204080e7          	jalr	516(ra) # 80004732 <fileclose>
      p->ofile[fd] = 0;
    80002536:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000253a:	04a1                	addi	s1,s1,8
    8000253c:	01248563          	beq	s1,s2,80002546 <exit+0x58>
    if(p->ofile[fd]){
    80002540:	6088                	ld	a0,0(s1)
    80002542:	f575                	bnez	a0,8000252e <exit+0x40>
    80002544:	bfdd                	j	8000253a <exit+0x4c>
  begin_op();
    80002546:	00002097          	auipc	ra,0x2
    8000254a:	d20080e7          	jalr	-736(ra) # 80004266 <begin_op>
  iput(p->cwd);
    8000254e:	1509b503          	ld	a0,336(s3)
    80002552:	00001097          	auipc	ra,0x1
    80002556:	4fc080e7          	jalr	1276(ra) # 80003a4e <iput>
  end_op();
    8000255a:	00002097          	auipc	ra,0x2
    8000255e:	d8c080e7          	jalr	-628(ra) # 800042e6 <end_op>
  p->cwd = 0;
    80002562:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002566:	0000f497          	auipc	s1,0xf
    8000256a:	d5248493          	addi	s1,s1,-686 # 800112b8 <wait_lock>
    8000256e:	8526                	mv	a0,s1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	674080e7          	jalr	1652(ra) # 80000be4 <acquire>
  reparent(p);
    80002578:	854e                	mv	a0,s3
    8000257a:	00000097          	auipc	ra,0x0
    8000257e:	f1a080e7          	jalr	-230(ra) # 80002494 <reparent>
  wakeup(p->parent);
    80002582:	0389b503          	ld	a0,56(s3)
    80002586:	00000097          	auipc	ra,0x0
    8000258a:	e98080e7          	jalr	-360(ra) # 8000241e <wakeup>
  acquire(&p->lock);
    8000258e:	854e                	mv	a0,s3
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	654080e7          	jalr	1620(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002598:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000259c:	4795                	li	a5,5
    8000259e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	6f4080e7          	jalr	1780(ra) # 80000c98 <release>
  sched();
    800025ac:	00000097          	auipc	ra,0x0
    800025b0:	ae0080e7          	jalr	-1312(ra) # 8000208c <sched>
  panic("zombie exit");
    800025b4:	00006517          	auipc	a0,0x6
    800025b8:	cfc50513          	addi	a0,a0,-772 # 800082b0 <digits+0x270>
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	f82080e7          	jalr	-126(ra) # 8000053e <panic>

00000000800025c4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025c4:	7179                	addi	sp,sp,-48
    800025c6:	f406                	sd	ra,40(sp)
    800025c8:	f022                	sd	s0,32(sp)
    800025ca:	ec26                	sd	s1,24(sp)
    800025cc:	e84a                	sd	s2,16(sp)
    800025ce:	e44e                	sd	s3,8(sp)
    800025d0:	1800                	addi	s0,sp,48
    800025d2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025d4:	0000f497          	auipc	s1,0xf
    800025d8:	0fc48493          	addi	s1,s1,252 # 800116d0 <proc>
    800025dc:	00015997          	auipc	s3,0x15
    800025e0:	af498993          	addi	s3,s3,-1292 # 800170d0 <tickslock>
    acquire(&p->lock);
    800025e4:	8526                	mv	a0,s1
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	5fe080e7          	jalr	1534(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800025ee:	589c                	lw	a5,48(s1)
    800025f0:	01278d63          	beq	a5,s2,8000260a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	6a2080e7          	jalr	1698(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025fe:	16848493          	addi	s1,s1,360
    80002602:	ff3491e3          	bne	s1,s3,800025e4 <kill+0x20>
  }
  return -1;
    80002606:	557d                	li	a0,-1
    80002608:	a829                	j	80002622 <kill+0x5e>
      p->killed = 1;
    8000260a:	4785                	li	a5,1
    8000260c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000260e:	4c98                	lw	a4,24(s1)
    80002610:	4789                	li	a5,2
    80002612:	00f70f63          	beq	a4,a5,80002630 <kill+0x6c>
      release(&p->lock);
    80002616:	8526                	mv	a0,s1
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	680080e7          	jalr	1664(ra) # 80000c98 <release>
      return 0;
    80002620:	4501                	li	a0,0
}
    80002622:	70a2                	ld	ra,40(sp)
    80002624:	7402                	ld	s0,32(sp)
    80002626:	64e2                	ld	s1,24(sp)
    80002628:	6942                	ld	s2,16(sp)
    8000262a:	69a2                	ld	s3,8(sp)
    8000262c:	6145                	addi	sp,sp,48
    8000262e:	8082                	ret
        p->state = RUNNABLE;
    80002630:	478d                	li	a5,3
    80002632:	cc9c                	sw	a5,24(s1)
    80002634:	b7cd                	j	80002616 <kill+0x52>

0000000080002636 <kill_system>:
kill_system(void){
    80002636:	7179                	addi	sp,sp,-48
    80002638:	f406                	sd	ra,40(sp)
    8000263a:	f022                	sd	s0,32(sp)
    8000263c:	ec26                	sd	s1,24(sp)
    8000263e:	e84a                	sd	s2,16(sp)
    80002640:	e44e                	sd	s3,8(sp)
    80002642:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++)
    80002644:	0000f497          	auipc	s1,0xf
    80002648:	08c48493          	addi	s1,s1,140 # 800116d0 <proc>
    if(p != initproc && p->pid != 0) // init process and shell?
    8000264c:	00007997          	auipc	s3,0x7
    80002650:	9dc98993          	addi	s3,s3,-1572 # 80009028 <initproc>
  for(p = proc; p < &proc[NPROC]; p++)
    80002654:	00015917          	auipc	s2,0x15
    80002658:	a7c90913          	addi	s2,s2,-1412 # 800170d0 <tickslock>
    8000265c:	a809                	j	8000266e <kill_system+0x38>
      kill(p->pid);
    8000265e:	00000097          	auipc	ra,0x0
    80002662:	f66080e7          	jalr	-154(ra) # 800025c4 <kill>
  for(p = proc; p < &proc[NPROC]; p++)
    80002666:	16848493          	addi	s1,s1,360
    8000266a:	01248963          	beq	s1,s2,8000267c <kill_system+0x46>
    if(p != initproc && p->pid != 0) // init process and shell?
    8000266e:	0009b783          	ld	a5,0(s3)
    80002672:	fe978ae3          	beq	a5,s1,80002666 <kill_system+0x30>
    80002676:	5888                	lw	a0,48(s1)
    80002678:	d57d                	beqz	a0,80002666 <kill_system+0x30>
    8000267a:	b7d5                	j	8000265e <kill_system+0x28>
}
    8000267c:	4501                	li	a0,0
    8000267e:	70a2                	ld	ra,40(sp)
    80002680:	7402                	ld	s0,32(sp)
    80002682:	64e2                	ld	s1,24(sp)
    80002684:	6942                	ld	s2,16(sp)
    80002686:	69a2                	ld	s3,8(sp)
    80002688:	6145                	addi	sp,sp,48
    8000268a:	8082                	ret

000000008000268c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000268c:	7179                	addi	sp,sp,-48
    8000268e:	f406                	sd	ra,40(sp)
    80002690:	f022                	sd	s0,32(sp)
    80002692:	ec26                	sd	s1,24(sp)
    80002694:	e84a                	sd	s2,16(sp)
    80002696:	e44e                	sd	s3,8(sp)
    80002698:	e052                	sd	s4,0(sp)
    8000269a:	1800                	addi	s0,sp,48
    8000269c:	84aa                	mv	s1,a0
    8000269e:	892e                	mv	s2,a1
    800026a0:	89b2                	mv	s3,a2
    800026a2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	43e080e7          	jalr	1086(ra) # 80001ae2 <myproc>
  if(user_dst){
    800026ac:	c08d                	beqz	s1,800026ce <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026ae:	86d2                	mv	a3,s4
    800026b0:	864e                	mv	a2,s3
    800026b2:	85ca                	mv	a1,s2
    800026b4:	6928                	ld	a0,80(a0)
    800026b6:	fffff097          	auipc	ra,0xfffff
    800026ba:	0ee080e7          	jalr	238(ra) # 800017a4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026be:	70a2                	ld	ra,40(sp)
    800026c0:	7402                	ld	s0,32(sp)
    800026c2:	64e2                	ld	s1,24(sp)
    800026c4:	6942                	ld	s2,16(sp)
    800026c6:	69a2                	ld	s3,8(sp)
    800026c8:	6a02                	ld	s4,0(sp)
    800026ca:	6145                	addi	sp,sp,48
    800026cc:	8082                	ret
    memmove((char *)dst, src, len);
    800026ce:	000a061b          	sext.w	a2,s4
    800026d2:	85ce                	mv	a1,s3
    800026d4:	854a                	mv	a0,s2
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	66a080e7          	jalr	1642(ra) # 80000d40 <memmove>
    return 0;
    800026de:	8526                	mv	a0,s1
    800026e0:	bff9                	j	800026be <either_copyout+0x32>

00000000800026e2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026e2:	7179                	addi	sp,sp,-48
    800026e4:	f406                	sd	ra,40(sp)
    800026e6:	f022                	sd	s0,32(sp)
    800026e8:	ec26                	sd	s1,24(sp)
    800026ea:	e84a                	sd	s2,16(sp)
    800026ec:	e44e                	sd	s3,8(sp)
    800026ee:	e052                	sd	s4,0(sp)
    800026f0:	1800                	addi	s0,sp,48
    800026f2:	892a                	mv	s2,a0
    800026f4:	84ae                	mv	s1,a1
    800026f6:	89b2                	mv	s3,a2
    800026f8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026fa:	fffff097          	auipc	ra,0xfffff
    800026fe:	3e8080e7          	jalr	1000(ra) # 80001ae2 <myproc>
  if(user_src){
    80002702:	c08d                	beqz	s1,80002724 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002704:	86d2                	mv	a3,s4
    80002706:	864e                	mv	a2,s3
    80002708:	85ca                	mv	a1,s2
    8000270a:	6928                	ld	a0,80(a0)
    8000270c:	fffff097          	auipc	ra,0xfffff
    80002710:	124080e7          	jalr	292(ra) # 80001830 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002714:	70a2                	ld	ra,40(sp)
    80002716:	7402                	ld	s0,32(sp)
    80002718:	64e2                	ld	s1,24(sp)
    8000271a:	6942                	ld	s2,16(sp)
    8000271c:	69a2                	ld	s3,8(sp)
    8000271e:	6a02                	ld	s4,0(sp)
    80002720:	6145                	addi	sp,sp,48
    80002722:	8082                	ret
    memmove(dst, (char*)src, len);
    80002724:	000a061b          	sext.w	a2,s4
    80002728:	85ce                	mv	a1,s3
    8000272a:	854a                	mv	a0,s2
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	614080e7          	jalr	1556(ra) # 80000d40 <memmove>
    return 0;
    80002734:	8526                	mv	a0,s1
    80002736:	bff9                	j	80002714 <either_copyin+0x32>

0000000080002738 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002738:	715d                	addi	sp,sp,-80
    8000273a:	e486                	sd	ra,72(sp)
    8000273c:	e0a2                	sd	s0,64(sp)
    8000273e:	fc26                	sd	s1,56(sp)
    80002740:	f84a                	sd	s2,48(sp)
    80002742:	f44e                	sd	s3,40(sp)
    80002744:	f052                	sd	s4,32(sp)
    80002746:	ec56                	sd	s5,24(sp)
    80002748:	e85a                	sd	s6,16(sp)
    8000274a:	e45e                	sd	s7,8(sp)
    8000274c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000274e:	00006517          	auipc	a0,0x6
    80002752:	9ba50513          	addi	a0,a0,-1606 # 80008108 <digits+0xc8>
    80002756:	ffffe097          	auipc	ra,0xffffe
    8000275a:	e32080e7          	jalr	-462(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000275e:	0000f497          	auipc	s1,0xf
    80002762:	0ca48493          	addi	s1,s1,202 # 80011828 <proc+0x158>
    80002766:	00015917          	auipc	s2,0x15
    8000276a:	ac290913          	addi	s2,s2,-1342 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000276e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002770:	00006997          	auipc	s3,0x6
    80002774:	b5098993          	addi	s3,s3,-1200 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    80002778:	00006a97          	auipc	s5,0x6
    8000277c:	b50a8a93          	addi	s5,s5,-1200 # 800082c8 <digits+0x288>
    printf("\n");
    80002780:	00006a17          	auipc	s4,0x6
    80002784:	988a0a13          	addi	s4,s4,-1656 # 80008108 <digits+0xc8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002788:	00006b97          	auipc	s7,0x6
    8000278c:	b78b8b93          	addi	s7,s7,-1160 # 80008300 <states.1733>
    80002790:	a00d                	j	800027b2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002792:	ed86a583          	lw	a1,-296(a3)
    80002796:	8556                	mv	a0,s5
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	df0080e7          	jalr	-528(ra) # 80000588 <printf>
    printf("\n");
    800027a0:	8552                	mv	a0,s4
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	de6080e7          	jalr	-538(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027aa:	16848493          	addi	s1,s1,360
    800027ae:	03248163          	beq	s1,s2,800027d0 <procdump+0x98>
    if(p->state == UNUSED)
    800027b2:	86a6                	mv	a3,s1
    800027b4:	ec04a783          	lw	a5,-320(s1)
    800027b8:	dbed                	beqz	a5,800027aa <procdump+0x72>
      state = "???";
    800027ba:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027bc:	fcfb6be3          	bltu	s6,a5,80002792 <procdump+0x5a>
    800027c0:	1782                	slli	a5,a5,0x20
    800027c2:	9381                	srli	a5,a5,0x20
    800027c4:	078e                	slli	a5,a5,0x3
    800027c6:	97de                	add	a5,a5,s7
    800027c8:	6390                	ld	a2,0(a5)
    800027ca:	f661                	bnez	a2,80002792 <procdump+0x5a>
      state = "???";
    800027cc:	864e                	mv	a2,s3
    800027ce:	b7d1                	j	80002792 <procdump+0x5a>
  }
}
    800027d0:	60a6                	ld	ra,72(sp)
    800027d2:	6406                	ld	s0,64(sp)
    800027d4:	74e2                	ld	s1,56(sp)
    800027d6:	7942                	ld	s2,48(sp)
    800027d8:	79a2                	ld	s3,40(sp)
    800027da:	7a02                	ld	s4,32(sp)
    800027dc:	6ae2                	ld	s5,24(sp)
    800027de:	6b42                	ld	s6,16(sp)
    800027e0:	6ba2                	ld	s7,8(sp)
    800027e2:	6161                	addi	sp,sp,80
    800027e4:	8082                	ret

00000000800027e6 <swtch>:
    800027e6:	00153023          	sd	ra,0(a0)
    800027ea:	00253423          	sd	sp,8(a0)
    800027ee:	e900                	sd	s0,16(a0)
    800027f0:	ed04                	sd	s1,24(a0)
    800027f2:	03253023          	sd	s2,32(a0)
    800027f6:	03353423          	sd	s3,40(a0)
    800027fa:	03453823          	sd	s4,48(a0)
    800027fe:	03553c23          	sd	s5,56(a0)
    80002802:	05653023          	sd	s6,64(a0)
    80002806:	05753423          	sd	s7,72(a0)
    8000280a:	05853823          	sd	s8,80(a0)
    8000280e:	05953c23          	sd	s9,88(a0)
    80002812:	07a53023          	sd	s10,96(a0)
    80002816:	07b53423          	sd	s11,104(a0)
    8000281a:	0005b083          	ld	ra,0(a1)
    8000281e:	0085b103          	ld	sp,8(a1)
    80002822:	6980                	ld	s0,16(a1)
    80002824:	6d84                	ld	s1,24(a1)
    80002826:	0205b903          	ld	s2,32(a1)
    8000282a:	0285b983          	ld	s3,40(a1)
    8000282e:	0305ba03          	ld	s4,48(a1)
    80002832:	0385ba83          	ld	s5,56(a1)
    80002836:	0405bb03          	ld	s6,64(a1)
    8000283a:	0485bb83          	ld	s7,72(a1)
    8000283e:	0505bc03          	ld	s8,80(a1)
    80002842:	0585bc83          	ld	s9,88(a1)
    80002846:	0605bd03          	ld	s10,96(a1)
    8000284a:	0685bd83          	ld	s11,104(a1)
    8000284e:	8082                	ret

0000000080002850 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002850:	1141                	addi	sp,sp,-16
    80002852:	e406                	sd	ra,8(sp)
    80002854:	e022                	sd	s0,0(sp)
    80002856:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002858:	00006597          	auipc	a1,0x6
    8000285c:	ad858593          	addi	a1,a1,-1320 # 80008330 <states.1733+0x30>
    80002860:	00015517          	auipc	a0,0x15
    80002864:	87050513          	addi	a0,a0,-1936 # 800170d0 <tickslock>
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	2ec080e7          	jalr	748(ra) # 80000b54 <initlock>
}
    80002870:	60a2                	ld	ra,8(sp)
    80002872:	6402                	ld	s0,0(sp)
    80002874:	0141                	addi	sp,sp,16
    80002876:	8082                	ret

0000000080002878 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002878:	1141                	addi	sp,sp,-16
    8000287a:	e422                	sd	s0,8(sp)
    8000287c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000287e:	00003797          	auipc	a5,0x3
    80002882:	4d278793          	addi	a5,a5,1234 # 80005d50 <kernelvec>
    80002886:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000288a:	6422                	ld	s0,8(sp)
    8000288c:	0141                	addi	sp,sp,16
    8000288e:	8082                	ret

0000000080002890 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002890:	1141                	addi	sp,sp,-16
    80002892:	e406                	sd	ra,8(sp)
    80002894:	e022                	sd	s0,0(sp)
    80002896:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	24a080e7          	jalr	586(ra) # 80001ae2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028a4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028aa:	00004617          	auipc	a2,0x4
    800028ae:	75660613          	addi	a2,a2,1878 # 80007000 <_trampoline>
    800028b2:	00004697          	auipc	a3,0x4
    800028b6:	74e68693          	addi	a3,a3,1870 # 80007000 <_trampoline>
    800028ba:	8e91                	sub	a3,a3,a2
    800028bc:	040007b7          	lui	a5,0x4000
    800028c0:	17fd                	addi	a5,a5,-1
    800028c2:	07b2                	slli	a5,a5,0xc
    800028c4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028c6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028ca:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028cc:	180026f3          	csrr	a3,satp
    800028d0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028d2:	6d38                	ld	a4,88(a0)
    800028d4:	6134                	ld	a3,64(a0)
    800028d6:	6585                	lui	a1,0x1
    800028d8:	96ae                	add	a3,a3,a1
    800028da:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028dc:	6d38                	ld	a4,88(a0)
    800028de:	00000697          	auipc	a3,0x0
    800028e2:	13868693          	addi	a3,a3,312 # 80002a16 <usertrap>
    800028e6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028e8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028ea:	8692                	mv	a3,tp
    800028ec:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ee:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028f2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028f6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028fa:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028fe:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002900:	6f18                	ld	a4,24(a4)
    80002902:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002906:	692c                	ld	a1,80(a0)
    80002908:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000290a:	00004717          	auipc	a4,0x4
    8000290e:	78670713          	addi	a4,a4,1926 # 80007090 <userret>
    80002912:	8f11                	sub	a4,a4,a2
    80002914:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002916:	577d                	li	a4,-1
    80002918:	177e                	slli	a4,a4,0x3f
    8000291a:	8dd9                	or	a1,a1,a4
    8000291c:	02000537          	lui	a0,0x2000
    80002920:	157d                	addi	a0,a0,-1
    80002922:	0536                	slli	a0,a0,0xd
    80002924:	9782                	jalr	a5
}
    80002926:	60a2                	ld	ra,8(sp)
    80002928:	6402                	ld	s0,0(sp)
    8000292a:	0141                	addi	sp,sp,16
    8000292c:	8082                	ret

000000008000292e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000292e:	1101                	addi	sp,sp,-32
    80002930:	ec06                	sd	ra,24(sp)
    80002932:	e822                	sd	s0,16(sp)
    80002934:	e426                	sd	s1,8(sp)
    80002936:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002938:	00014497          	auipc	s1,0x14
    8000293c:	79848493          	addi	s1,s1,1944 # 800170d0 <tickslock>
    80002940:	8526                	mv	a0,s1
    80002942:	ffffe097          	auipc	ra,0xffffe
    80002946:	2a2080e7          	jalr	674(ra) # 80000be4 <acquire>
  ticks++;
    8000294a:	00006517          	auipc	a0,0x6
    8000294e:	6e650513          	addi	a0,a0,1766 # 80009030 <ticks>
    80002952:	411c                	lw	a5,0(a0)
    80002954:	2785                	addiw	a5,a5,1
    80002956:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002958:	00000097          	auipc	ra,0x0
    8000295c:	ac6080e7          	jalr	-1338(ra) # 8000241e <wakeup>
  release(&tickslock);
    80002960:	8526                	mv	a0,s1
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	336080e7          	jalr	822(ra) # 80000c98 <release>
}
    8000296a:	60e2                	ld	ra,24(sp)
    8000296c:	6442                	ld	s0,16(sp)
    8000296e:	64a2                	ld	s1,8(sp)
    80002970:	6105                	addi	sp,sp,32
    80002972:	8082                	ret

0000000080002974 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002974:	1101                	addi	sp,sp,-32
    80002976:	ec06                	sd	ra,24(sp)
    80002978:	e822                	sd	s0,16(sp)
    8000297a:	e426                	sd	s1,8(sp)
    8000297c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000297e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002982:	00074d63          	bltz	a4,8000299c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002986:	57fd                	li	a5,-1
    80002988:	17fe                	slli	a5,a5,0x3f
    8000298a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000298c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000298e:	06f70363          	beq	a4,a5,800029f4 <devintr+0x80>
  }
}
    80002992:	60e2                	ld	ra,24(sp)
    80002994:	6442                	ld	s0,16(sp)
    80002996:	64a2                	ld	s1,8(sp)
    80002998:	6105                	addi	sp,sp,32
    8000299a:	8082                	ret
     (scause & 0xff) == 9){
    8000299c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029a0:	46a5                	li	a3,9
    800029a2:	fed792e3          	bne	a5,a3,80002986 <devintr+0x12>
    int irq = plic_claim();
    800029a6:	00003097          	auipc	ra,0x3
    800029aa:	4b2080e7          	jalr	1202(ra) # 80005e58 <plic_claim>
    800029ae:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029b0:	47a9                	li	a5,10
    800029b2:	02f50763          	beq	a0,a5,800029e0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029b6:	4785                	li	a5,1
    800029b8:	02f50963          	beq	a0,a5,800029ea <devintr+0x76>
    return 1;
    800029bc:	4505                	li	a0,1
    } else if(irq){
    800029be:	d8f1                	beqz	s1,80002992 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029c0:	85a6                	mv	a1,s1
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	97650513          	addi	a0,a0,-1674 # 80008338 <states.1733+0x38>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	bbe080e7          	jalr	-1090(ra) # 80000588 <printf>
      plic_complete(irq);
    800029d2:	8526                	mv	a0,s1
    800029d4:	00003097          	auipc	ra,0x3
    800029d8:	4a8080e7          	jalr	1192(ra) # 80005e7c <plic_complete>
    return 1;
    800029dc:	4505                	li	a0,1
    800029de:	bf55                	j	80002992 <devintr+0x1e>
      uartintr();
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	fc8080e7          	jalr	-56(ra) # 800009a8 <uartintr>
    800029e8:	b7ed                	j	800029d2 <devintr+0x5e>
      virtio_disk_intr();
    800029ea:	00004097          	auipc	ra,0x4
    800029ee:	972080e7          	jalr	-1678(ra) # 8000635c <virtio_disk_intr>
    800029f2:	b7c5                	j	800029d2 <devintr+0x5e>
    if(cpuid() == 0){
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	0c2080e7          	jalr	194(ra) # 80001ab6 <cpuid>
    800029fc:	c901                	beqz	a0,80002a0c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029fe:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a02:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a04:	14479073          	csrw	sip,a5
    return 2;
    80002a08:	4509                	li	a0,2
    80002a0a:	b761                	j	80002992 <devintr+0x1e>
      clockintr();
    80002a0c:	00000097          	auipc	ra,0x0
    80002a10:	f22080e7          	jalr	-222(ra) # 8000292e <clockintr>
    80002a14:	b7ed                	j	800029fe <devintr+0x8a>

0000000080002a16 <usertrap>:
{
    80002a16:	1101                	addi	sp,sp,-32
    80002a18:	ec06                	sd	ra,24(sp)
    80002a1a:	e822                	sd	s0,16(sp)
    80002a1c:	e426                	sd	s1,8(sp)
    80002a1e:	e04a                	sd	s2,0(sp)
    80002a20:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a22:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a26:	1007f793          	andi	a5,a5,256
    80002a2a:	e3ad                	bnez	a5,80002a8c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a2c:	00003797          	auipc	a5,0x3
    80002a30:	32478793          	addi	a5,a5,804 # 80005d50 <kernelvec>
    80002a34:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	0aa080e7          	jalr	170(ra) # 80001ae2 <myproc>
    80002a40:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a42:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a44:	14102773          	csrr	a4,sepc
    80002a48:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a4a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a4e:	47a1                	li	a5,8
    80002a50:	04f71c63          	bne	a4,a5,80002aa8 <usertrap+0x92>
    if(p->killed)
    80002a54:	551c                	lw	a5,40(a0)
    80002a56:	e3b9                	bnez	a5,80002a9c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a58:	6cb8                	ld	a4,88(s1)
    80002a5a:	6f1c                	ld	a5,24(a4)
    80002a5c:	0791                	addi	a5,a5,4
    80002a5e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a64:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a68:	10079073          	csrw	sstatus,a5
    syscall();
    80002a6c:	00000097          	auipc	ra,0x0
    80002a70:	2e0080e7          	jalr	736(ra) # 80002d4c <syscall>
  if(p->killed)
    80002a74:	549c                	lw	a5,40(s1)
    80002a76:	ebc1                	bnez	a5,80002b06 <usertrap+0xf0>
  usertrapret();
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	e18080e7          	jalr	-488(ra) # 80002890 <usertrapret>
}
    80002a80:	60e2                	ld	ra,24(sp)
    80002a82:	6442                	ld	s0,16(sp)
    80002a84:	64a2                	ld	s1,8(sp)
    80002a86:	6902                	ld	s2,0(sp)
    80002a88:	6105                	addi	sp,sp,32
    80002a8a:	8082                	ret
    panic("usertrap: not from user mode");
    80002a8c:	00006517          	auipc	a0,0x6
    80002a90:	8cc50513          	addi	a0,a0,-1844 # 80008358 <states.1733+0x58>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	aaa080e7          	jalr	-1366(ra) # 8000053e <panic>
      exit(-1);
    80002a9c:	557d                	li	a0,-1
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	a50080e7          	jalr	-1456(ra) # 800024ee <exit>
    80002aa6:	bf4d                	j	80002a58 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002aa8:	00000097          	auipc	ra,0x0
    80002aac:	ecc080e7          	jalr	-308(ra) # 80002974 <devintr>
    80002ab0:	892a                	mv	s2,a0
    80002ab2:	c501                	beqz	a0,80002aba <usertrap+0xa4>
  if(p->killed)
    80002ab4:	549c                	lw	a5,40(s1)
    80002ab6:	c3a1                	beqz	a5,80002af6 <usertrap+0xe0>
    80002ab8:	a815                	j	80002aec <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aba:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002abe:	5890                	lw	a2,48(s1)
    80002ac0:	00006517          	auipc	a0,0x6
    80002ac4:	8b850513          	addi	a0,a0,-1864 # 80008378 <states.1733+0x78>
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	ac0080e7          	jalr	-1344(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ad4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ad8:	00006517          	auipc	a0,0x6
    80002adc:	8d050513          	addi	a0,a0,-1840 # 800083a8 <states.1733+0xa8>
    80002ae0:	ffffe097          	auipc	ra,0xffffe
    80002ae4:	aa8080e7          	jalr	-1368(ra) # 80000588 <printf>
    p->killed = 1;
    80002ae8:	4785                	li	a5,1
    80002aea:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002aec:	557d                	li	a0,-1
    80002aee:	00000097          	auipc	ra,0x0
    80002af2:	a00080e7          	jalr	-1536(ra) # 800024ee <exit>
  if(which_dev == 2)
    80002af6:	4789                	li	a5,2
    80002af8:	f8f910e3          	bne	s2,a5,80002a78 <usertrap+0x62>
    yield();
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	666080e7          	jalr	1638(ra) # 80002162 <yield>
    80002b04:	bf95                	j	80002a78 <usertrap+0x62>
  int which_dev = 0;
    80002b06:	4901                	li	s2,0
    80002b08:	b7d5                	j	80002aec <usertrap+0xd6>

0000000080002b0a <kerneltrap>:
{
    80002b0a:	7179                	addi	sp,sp,-48
    80002b0c:	f406                	sd	ra,40(sp)
    80002b0e:	f022                	sd	s0,32(sp)
    80002b10:	ec26                	sd	s1,24(sp)
    80002b12:	e84a                	sd	s2,16(sp)
    80002b14:	e44e                	sd	s3,8(sp)
    80002b16:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b18:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b20:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b24:	1004f793          	andi	a5,s1,256
    80002b28:	cb85                	beqz	a5,80002b58 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b2a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b2e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b30:	ef85                	bnez	a5,80002b68 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b32:	00000097          	auipc	ra,0x0
    80002b36:	e42080e7          	jalr	-446(ra) # 80002974 <devintr>
    80002b3a:	cd1d                	beqz	a0,80002b78 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b3c:	4789                	li	a5,2
    80002b3e:	06f50a63          	beq	a0,a5,80002bb2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b42:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b46:	10049073          	csrw	sstatus,s1
}
    80002b4a:	70a2                	ld	ra,40(sp)
    80002b4c:	7402                	ld	s0,32(sp)
    80002b4e:	64e2                	ld	s1,24(sp)
    80002b50:	6942                	ld	s2,16(sp)
    80002b52:	69a2                	ld	s3,8(sp)
    80002b54:	6145                	addi	sp,sp,48
    80002b56:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b58:	00006517          	auipc	a0,0x6
    80002b5c:	87050513          	addi	a0,a0,-1936 # 800083c8 <states.1733+0xc8>
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	9de080e7          	jalr	-1570(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002b68:	00006517          	auipc	a0,0x6
    80002b6c:	88850513          	addi	a0,a0,-1912 # 800083f0 <states.1733+0xf0>
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	9ce080e7          	jalr	-1586(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002b78:	85ce                	mv	a1,s3
    80002b7a:	00006517          	auipc	a0,0x6
    80002b7e:	89650513          	addi	a0,a0,-1898 # 80008410 <states.1733+0x110>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	a06080e7          	jalr	-1530(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b8a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b8e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b92:	00006517          	auipc	a0,0x6
    80002b96:	88e50513          	addi	a0,a0,-1906 # 80008420 <states.1733+0x120>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	9ee080e7          	jalr	-1554(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ba2:	00006517          	auipc	a0,0x6
    80002ba6:	89650513          	addi	a0,a0,-1898 # 80008438 <states.1733+0x138>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	994080e7          	jalr	-1644(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	f30080e7          	jalr	-208(ra) # 80001ae2 <myproc>
    80002bba:	d541                	beqz	a0,80002b42 <kerneltrap+0x38>
    80002bbc:	fffff097          	auipc	ra,0xfffff
    80002bc0:	f26080e7          	jalr	-218(ra) # 80001ae2 <myproc>
    80002bc4:	4d18                	lw	a4,24(a0)
    80002bc6:	4791                	li	a5,4
    80002bc8:	f6f71de3          	bne	a4,a5,80002b42 <kerneltrap+0x38>
    yield();
    80002bcc:	fffff097          	auipc	ra,0xfffff
    80002bd0:	596080e7          	jalr	1430(ra) # 80002162 <yield>
    80002bd4:	b7bd                	j	80002b42 <kerneltrap+0x38>

0000000080002bd6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bd6:	1101                	addi	sp,sp,-32
    80002bd8:	ec06                	sd	ra,24(sp)
    80002bda:	e822                	sd	s0,16(sp)
    80002bdc:	e426                	sd	s1,8(sp)
    80002bde:	1000                	addi	s0,sp,32
    80002be0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002be2:	fffff097          	auipc	ra,0xfffff
    80002be6:	f00080e7          	jalr	-256(ra) # 80001ae2 <myproc>
  switch (n) {
    80002bea:	4795                	li	a5,5
    80002bec:	0497e163          	bltu	a5,s1,80002c2e <argraw+0x58>
    80002bf0:	048a                	slli	s1,s1,0x2
    80002bf2:	00006717          	auipc	a4,0x6
    80002bf6:	87e70713          	addi	a4,a4,-1922 # 80008470 <states.1733+0x170>
    80002bfa:	94ba                	add	s1,s1,a4
    80002bfc:	409c                	lw	a5,0(s1)
    80002bfe:	97ba                	add	a5,a5,a4
    80002c00:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c02:	6d3c                	ld	a5,88(a0)
    80002c04:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c06:	60e2                	ld	ra,24(sp)
    80002c08:	6442                	ld	s0,16(sp)
    80002c0a:	64a2                	ld	s1,8(sp)
    80002c0c:	6105                	addi	sp,sp,32
    80002c0e:	8082                	ret
    return p->trapframe->a1;
    80002c10:	6d3c                	ld	a5,88(a0)
    80002c12:	7fa8                	ld	a0,120(a5)
    80002c14:	bfcd                	j	80002c06 <argraw+0x30>
    return p->trapframe->a2;
    80002c16:	6d3c                	ld	a5,88(a0)
    80002c18:	63c8                	ld	a0,128(a5)
    80002c1a:	b7f5                	j	80002c06 <argraw+0x30>
    return p->trapframe->a3;
    80002c1c:	6d3c                	ld	a5,88(a0)
    80002c1e:	67c8                	ld	a0,136(a5)
    80002c20:	b7dd                	j	80002c06 <argraw+0x30>
    return p->trapframe->a4;
    80002c22:	6d3c                	ld	a5,88(a0)
    80002c24:	6bc8                	ld	a0,144(a5)
    80002c26:	b7c5                	j	80002c06 <argraw+0x30>
    return p->trapframe->a5;
    80002c28:	6d3c                	ld	a5,88(a0)
    80002c2a:	6fc8                	ld	a0,152(a5)
    80002c2c:	bfe9                	j	80002c06 <argraw+0x30>
  panic("argraw");
    80002c2e:	00006517          	auipc	a0,0x6
    80002c32:	81a50513          	addi	a0,a0,-2022 # 80008448 <states.1733+0x148>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	908080e7          	jalr	-1784(ra) # 8000053e <panic>

0000000080002c3e <fetchaddr>:
{
    80002c3e:	1101                	addi	sp,sp,-32
    80002c40:	ec06                	sd	ra,24(sp)
    80002c42:	e822                	sd	s0,16(sp)
    80002c44:	e426                	sd	s1,8(sp)
    80002c46:	e04a                	sd	s2,0(sp)
    80002c48:	1000                	addi	s0,sp,32
    80002c4a:	84aa                	mv	s1,a0
    80002c4c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	e94080e7          	jalr	-364(ra) # 80001ae2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c56:	653c                	ld	a5,72(a0)
    80002c58:	02f4f863          	bgeu	s1,a5,80002c88 <fetchaddr+0x4a>
    80002c5c:	00848713          	addi	a4,s1,8
    80002c60:	02e7e663          	bltu	a5,a4,80002c8c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c64:	46a1                	li	a3,8
    80002c66:	8626                	mv	a2,s1
    80002c68:	85ca                	mv	a1,s2
    80002c6a:	6928                	ld	a0,80(a0)
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	bc4080e7          	jalr	-1084(ra) # 80001830 <copyin>
    80002c74:	00a03533          	snez	a0,a0
    80002c78:	40a00533          	neg	a0,a0
}
    80002c7c:	60e2                	ld	ra,24(sp)
    80002c7e:	6442                	ld	s0,16(sp)
    80002c80:	64a2                	ld	s1,8(sp)
    80002c82:	6902                	ld	s2,0(sp)
    80002c84:	6105                	addi	sp,sp,32
    80002c86:	8082                	ret
    return -1;
    80002c88:	557d                	li	a0,-1
    80002c8a:	bfcd                	j	80002c7c <fetchaddr+0x3e>
    80002c8c:	557d                	li	a0,-1
    80002c8e:	b7fd                	j	80002c7c <fetchaddr+0x3e>

0000000080002c90 <fetchstr>:
{
    80002c90:	7179                	addi	sp,sp,-48
    80002c92:	f406                	sd	ra,40(sp)
    80002c94:	f022                	sd	s0,32(sp)
    80002c96:	ec26                	sd	s1,24(sp)
    80002c98:	e84a                	sd	s2,16(sp)
    80002c9a:	e44e                	sd	s3,8(sp)
    80002c9c:	1800                	addi	s0,sp,48
    80002c9e:	892a                	mv	s2,a0
    80002ca0:	84ae                	mv	s1,a1
    80002ca2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ca4:	fffff097          	auipc	ra,0xfffff
    80002ca8:	e3e080e7          	jalr	-450(ra) # 80001ae2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cac:	86ce                	mv	a3,s3
    80002cae:	864a                	mv	a2,s2
    80002cb0:	85a6                	mv	a1,s1
    80002cb2:	6928                	ld	a0,80(a0)
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	c08080e7          	jalr	-1016(ra) # 800018bc <copyinstr>
  if(err < 0)
    80002cbc:	00054763          	bltz	a0,80002cca <fetchstr+0x3a>
  return strlen(buf);
    80002cc0:	8526                	mv	a0,s1
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	1a2080e7          	jalr	418(ra) # 80000e64 <strlen>
}
    80002cca:	70a2                	ld	ra,40(sp)
    80002ccc:	7402                	ld	s0,32(sp)
    80002cce:	64e2                	ld	s1,24(sp)
    80002cd0:	6942                	ld	s2,16(sp)
    80002cd2:	69a2                	ld	s3,8(sp)
    80002cd4:	6145                	addi	sp,sp,48
    80002cd6:	8082                	ret

0000000080002cd8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cd8:	1101                	addi	sp,sp,-32
    80002cda:	ec06                	sd	ra,24(sp)
    80002cdc:	e822                	sd	s0,16(sp)
    80002cde:	e426                	sd	s1,8(sp)
    80002ce0:	1000                	addi	s0,sp,32
    80002ce2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce4:	00000097          	auipc	ra,0x0
    80002ce8:	ef2080e7          	jalr	-270(ra) # 80002bd6 <argraw>
    80002cec:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cee:	4501                	li	a0,0
    80002cf0:	60e2                	ld	ra,24(sp)
    80002cf2:	6442                	ld	s0,16(sp)
    80002cf4:	64a2                	ld	s1,8(sp)
    80002cf6:	6105                	addi	sp,sp,32
    80002cf8:	8082                	ret

0000000080002cfa <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cfa:	1101                	addi	sp,sp,-32
    80002cfc:	ec06                	sd	ra,24(sp)
    80002cfe:	e822                	sd	s0,16(sp)
    80002d00:	e426                	sd	s1,8(sp)
    80002d02:	1000                	addi	s0,sp,32
    80002d04:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	ed0080e7          	jalr	-304(ra) # 80002bd6 <argraw>
    80002d0e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d10:	4501                	li	a0,0
    80002d12:	60e2                	ld	ra,24(sp)
    80002d14:	6442                	ld	s0,16(sp)
    80002d16:	64a2                	ld	s1,8(sp)
    80002d18:	6105                	addi	sp,sp,32
    80002d1a:	8082                	ret

0000000080002d1c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d1c:	1101                	addi	sp,sp,-32
    80002d1e:	ec06                	sd	ra,24(sp)
    80002d20:	e822                	sd	s0,16(sp)
    80002d22:	e426                	sd	s1,8(sp)
    80002d24:	e04a                	sd	s2,0(sp)
    80002d26:	1000                	addi	s0,sp,32
    80002d28:	84ae                	mv	s1,a1
    80002d2a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d2c:	00000097          	auipc	ra,0x0
    80002d30:	eaa080e7          	jalr	-342(ra) # 80002bd6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d34:	864a                	mv	a2,s2
    80002d36:	85a6                	mv	a1,s1
    80002d38:	00000097          	auipc	ra,0x0
    80002d3c:	f58080e7          	jalr	-168(ra) # 80002c90 <fetchstr>
}
    80002d40:	60e2                	ld	ra,24(sp)
    80002d42:	6442                	ld	s0,16(sp)
    80002d44:	64a2                	ld	s1,8(sp)
    80002d46:	6902                	ld	s2,0(sp)
    80002d48:	6105                	addi	sp,sp,32
    80002d4a:	8082                	ret

0000000080002d4c <syscall>:
[SYS_killsystem]   sys_killsystem
};

void
syscall(void)
{
    80002d4c:	1101                	addi	sp,sp,-32
    80002d4e:	ec06                	sd	ra,24(sp)
    80002d50:	e822                	sd	s0,16(sp)
    80002d52:	e426                	sd	s1,8(sp)
    80002d54:	e04a                	sd	s2,0(sp)
    80002d56:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	d8a080e7          	jalr	-630(ra) # 80001ae2 <myproc>
    80002d60:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d62:	05853903          	ld	s2,88(a0)
    80002d66:	0a893783          	ld	a5,168(s2)
    80002d6a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d6e:	37fd                	addiw	a5,a5,-1
    80002d70:	4759                	li	a4,22
    80002d72:	00f76f63          	bltu	a4,a5,80002d90 <syscall+0x44>
    80002d76:	00369713          	slli	a4,a3,0x3
    80002d7a:	00005797          	auipc	a5,0x5
    80002d7e:	70e78793          	addi	a5,a5,1806 # 80008488 <syscalls>
    80002d82:	97ba                	add	a5,a5,a4
    80002d84:	639c                	ld	a5,0(a5)
    80002d86:	c789                	beqz	a5,80002d90 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d88:	9782                	jalr	a5
    80002d8a:	06a93823          	sd	a0,112(s2)
    80002d8e:	a839                	j	80002dac <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d90:	15848613          	addi	a2,s1,344
    80002d94:	588c                	lw	a1,48(s1)
    80002d96:	00005517          	auipc	a0,0x5
    80002d9a:	6ba50513          	addi	a0,a0,1722 # 80008450 <states.1733+0x150>
    80002d9e:	ffffd097          	auipc	ra,0xffffd
    80002da2:	7ea080e7          	jalr	2026(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002da6:	6cbc                	ld	a5,88(s1)
    80002da8:	577d                	li	a4,-1
    80002daa:	fbb8                	sd	a4,112(a5)
  }
}
    80002dac:	60e2                	ld	ra,24(sp)
    80002dae:	6442                	ld	s0,16(sp)
    80002db0:	64a2                	ld	s1,8(sp)
    80002db2:	6902                	ld	s2,0(sp)
    80002db4:	6105                	addi	sp,sp,32
    80002db6:	8082                	ret

0000000080002db8 <sys_pause>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_pause(void)
{
    80002db8:	1101                	addi	sp,sp,-32
    80002dba:	ec06                	sd	ra,24(sp)
    80002dbc:	e822                	sd	s0,16(sp)
    80002dbe:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dc0:	fec40593          	addi	a1,s0,-20
    80002dc4:	4501                	li	a0,0
    80002dc6:	00000097          	auipc	ra,0x0
    80002dca:	f12080e7          	jalr	-238(ra) # 80002cd8 <argint>
    80002dce:	87aa                	mv	a5,a0
    return -1;
    80002dd0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002dd2:	0007c863          	bltz	a5,80002de2 <sys_pause+0x2a>
  
  return pause_system(n);
    80002dd6:	fec42503          	lw	a0,-20(s0)
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	428080e7          	jalr	1064(ra) # 80002202 <pause_system>
}
    80002de2:	60e2                	ld	ra,24(sp)
    80002de4:	6442                	ld	s0,16(sp)
    80002de6:	6105                	addi	sp,sp,32
    80002de8:	8082                	ret

0000000080002dea <sys_killsystem>:

uint64
sys_killsystem(void)
{
    80002dea:	1141                	addi	sp,sp,-16
    80002dec:	e406                	sd	ra,8(sp)
    80002dee:	e022                	sd	s0,0(sp)
    80002df0:	0800                	addi	s0,sp,16
  return kill_system();
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	844080e7          	jalr	-1980(ra) # 80002636 <kill_system>
}
    80002dfa:	60a2                	ld	ra,8(sp)
    80002dfc:	6402                	ld	s0,0(sp)
    80002dfe:	0141                	addi	sp,sp,16
    80002e00:	8082                	ret

0000000080002e02 <sys_exit>:


uint64
sys_exit(void)
{
    80002e02:	1101                	addi	sp,sp,-32
    80002e04:	ec06                	sd	ra,24(sp)
    80002e06:	e822                	sd	s0,16(sp)
    80002e08:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e0a:	fec40593          	addi	a1,s0,-20
    80002e0e:	4501                	li	a0,0
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	ec8080e7          	jalr	-312(ra) # 80002cd8 <argint>
    return -1;
    80002e18:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e1a:	00054963          	bltz	a0,80002e2c <sys_exit+0x2a>
  exit(n);
    80002e1e:	fec42503          	lw	a0,-20(s0)
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	6cc080e7          	jalr	1740(ra) # 800024ee <exit>
  return 0;  // not reached
    80002e2a:	4781                	li	a5,0
}
    80002e2c:	853e                	mv	a0,a5
    80002e2e:	60e2                	ld	ra,24(sp)
    80002e30:	6442                	ld	s0,16(sp)
    80002e32:	6105                	addi	sp,sp,32
    80002e34:	8082                	ret

0000000080002e36 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e36:	1141                	addi	sp,sp,-16
    80002e38:	e406                	sd	ra,8(sp)
    80002e3a:	e022                	sd	s0,0(sp)
    80002e3c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	ca4080e7          	jalr	-860(ra) # 80001ae2 <myproc>
}
    80002e46:	5908                	lw	a0,48(a0)
    80002e48:	60a2                	ld	ra,8(sp)
    80002e4a:	6402                	ld	s0,0(sp)
    80002e4c:	0141                	addi	sp,sp,16
    80002e4e:	8082                	ret

0000000080002e50 <sys_fork>:

uint64
sys_fork(void)
{
    80002e50:	1141                	addi	sp,sp,-16
    80002e52:	e406                	sd	ra,8(sp)
    80002e54:	e022                	sd	s0,0(sp)
    80002e56:	0800                	addi	s0,sp,16
  return fork();
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	058080e7          	jalr	88(ra) # 80001eb0 <fork>
}
    80002e60:	60a2                	ld	ra,8(sp)
    80002e62:	6402                	ld	s0,0(sp)
    80002e64:	0141                	addi	sp,sp,16
    80002e66:	8082                	ret

0000000080002e68 <sys_wait>:

uint64
sys_wait(void)
{
    80002e68:	1101                	addi	sp,sp,-32
    80002e6a:	ec06                	sd	ra,24(sp)
    80002e6c:	e822                	sd	s0,16(sp)
    80002e6e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e70:	fe840593          	addi	a1,s0,-24
    80002e74:	4501                	li	a0,0
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	e84080e7          	jalr	-380(ra) # 80002cfa <argaddr>
    80002e7e:	87aa                	mv	a5,a0
    return -1;
    80002e80:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e82:	0007c863          	bltz	a5,80002e92 <sys_wait+0x2a>
  return wait(p);
    80002e86:	fe843503          	ld	a0,-24(s0)
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	46c080e7          	jalr	1132(ra) # 800022f6 <wait>
}
    80002e92:	60e2                	ld	ra,24(sp)
    80002e94:	6442                	ld	s0,16(sp)
    80002e96:	6105                	addi	sp,sp,32
    80002e98:	8082                	ret

0000000080002e9a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e9a:	7179                	addi	sp,sp,-48
    80002e9c:	f406                	sd	ra,40(sp)
    80002e9e:	f022                	sd	s0,32(sp)
    80002ea0:	ec26                	sd	s1,24(sp)
    80002ea2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ea4:	fdc40593          	addi	a1,s0,-36
    80002ea8:	4501                	li	a0,0
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	e2e080e7          	jalr	-466(ra) # 80002cd8 <argint>
    80002eb2:	87aa                	mv	a5,a0
    return -1;
    80002eb4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002eb6:	0207c063          	bltz	a5,80002ed6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002eba:	fffff097          	auipc	ra,0xfffff
    80002ebe:	c28080e7          	jalr	-984(ra) # 80001ae2 <myproc>
    80002ec2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ec4:	fdc42503          	lw	a0,-36(s0)
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	f74080e7          	jalr	-140(ra) # 80001e3c <growproc>
    80002ed0:	00054863          	bltz	a0,80002ee0 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ed4:	8526                	mv	a0,s1
}
    80002ed6:	70a2                	ld	ra,40(sp)
    80002ed8:	7402                	ld	s0,32(sp)
    80002eda:	64e2                	ld	s1,24(sp)
    80002edc:	6145                	addi	sp,sp,48
    80002ede:	8082                	ret
    return -1;
    80002ee0:	557d                	li	a0,-1
    80002ee2:	bfd5                	j	80002ed6 <sys_sbrk+0x3c>

0000000080002ee4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ee4:	7139                	addi	sp,sp,-64
    80002ee6:	fc06                	sd	ra,56(sp)
    80002ee8:	f822                	sd	s0,48(sp)
    80002eea:	f426                	sd	s1,40(sp)
    80002eec:	f04a                	sd	s2,32(sp)
    80002eee:	ec4e                	sd	s3,24(sp)
    80002ef0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ef2:	fcc40593          	addi	a1,s0,-52
    80002ef6:	4501                	li	a0,0
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	de0080e7          	jalr	-544(ra) # 80002cd8 <argint>
    return -1;
    80002f00:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f02:	06054563          	bltz	a0,80002f6c <sys_sleep+0x88>
  acquire(&tickslock);
    80002f06:	00014517          	auipc	a0,0x14
    80002f0a:	1ca50513          	addi	a0,a0,458 # 800170d0 <tickslock>
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	cd6080e7          	jalr	-810(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f16:	00006917          	auipc	s2,0x6
    80002f1a:	11a92903          	lw	s2,282(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f1e:	fcc42783          	lw	a5,-52(s0)
    80002f22:	cf85                	beqz	a5,80002f5a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f24:	00014997          	auipc	s3,0x14
    80002f28:	1ac98993          	addi	s3,s3,428 # 800170d0 <tickslock>
    80002f2c:	00006497          	auipc	s1,0x6
    80002f30:	10448493          	addi	s1,s1,260 # 80009030 <ticks>
    if(myproc()->killed){
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	bae080e7          	jalr	-1106(ra) # 80001ae2 <myproc>
    80002f3c:	551c                	lw	a5,40(a0)
    80002f3e:	ef9d                	bnez	a5,80002f7c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f40:	85ce                	mv	a1,s3
    80002f42:	8526                	mv	a0,s1
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	25a080e7          	jalr	602(ra) # 8000219e <sleep>
  while(ticks - ticks0 < n){
    80002f4c:	409c                	lw	a5,0(s1)
    80002f4e:	412787bb          	subw	a5,a5,s2
    80002f52:	fcc42703          	lw	a4,-52(s0)
    80002f56:	fce7efe3          	bltu	a5,a4,80002f34 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f5a:	00014517          	auipc	a0,0x14
    80002f5e:	17650513          	addi	a0,a0,374 # 800170d0 <tickslock>
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	d36080e7          	jalr	-714(ra) # 80000c98 <release>
  return 0;
    80002f6a:	4781                	li	a5,0
}
    80002f6c:	853e                	mv	a0,a5
    80002f6e:	70e2                	ld	ra,56(sp)
    80002f70:	7442                	ld	s0,48(sp)
    80002f72:	74a2                	ld	s1,40(sp)
    80002f74:	7902                	ld	s2,32(sp)
    80002f76:	69e2                	ld	s3,24(sp)
    80002f78:	6121                	addi	sp,sp,64
    80002f7a:	8082                	ret
      release(&tickslock);
    80002f7c:	00014517          	auipc	a0,0x14
    80002f80:	15450513          	addi	a0,a0,340 # 800170d0 <tickslock>
    80002f84:	ffffe097          	auipc	ra,0xffffe
    80002f88:	d14080e7          	jalr	-748(ra) # 80000c98 <release>
      return -1;
    80002f8c:	57fd                	li	a5,-1
    80002f8e:	bff9                	j	80002f6c <sys_sleep+0x88>

0000000080002f90 <sys_kill>:

uint64
sys_kill(void)
{
    80002f90:	1101                	addi	sp,sp,-32
    80002f92:	ec06                	sd	ra,24(sp)
    80002f94:	e822                	sd	s0,16(sp)
    80002f96:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f98:	fec40593          	addi	a1,s0,-20
    80002f9c:	4501                	li	a0,0
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	d3a080e7          	jalr	-710(ra) # 80002cd8 <argint>
    80002fa6:	87aa                	mv	a5,a0
    return -1;
    80002fa8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002faa:	0007c863          	bltz	a5,80002fba <sys_kill+0x2a>
  return kill(pid);
    80002fae:	fec42503          	lw	a0,-20(s0)
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	612080e7          	jalr	1554(ra) # 800025c4 <kill>
}
    80002fba:	60e2                	ld	ra,24(sp)
    80002fbc:	6442                	ld	s0,16(sp)
    80002fbe:	6105                	addi	sp,sp,32
    80002fc0:	8082                	ret

0000000080002fc2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002fc2:	1101                	addi	sp,sp,-32
    80002fc4:	ec06                	sd	ra,24(sp)
    80002fc6:	e822                	sd	s0,16(sp)
    80002fc8:	e426                	sd	s1,8(sp)
    80002fca:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002fcc:	00014517          	auipc	a0,0x14
    80002fd0:	10450513          	addi	a0,a0,260 # 800170d0 <tickslock>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	c10080e7          	jalr	-1008(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002fdc:	00006497          	auipc	s1,0x6
    80002fe0:	0544a483          	lw	s1,84(s1) # 80009030 <ticks>
  release(&tickslock);
    80002fe4:	00014517          	auipc	a0,0x14
    80002fe8:	0ec50513          	addi	a0,a0,236 # 800170d0 <tickslock>
    80002fec:	ffffe097          	auipc	ra,0xffffe
    80002ff0:	cac080e7          	jalr	-852(ra) # 80000c98 <release>
  return xticks;
}
    80002ff4:	02049513          	slli	a0,s1,0x20
    80002ff8:	9101                	srli	a0,a0,0x20
    80002ffa:	60e2                	ld	ra,24(sp)
    80002ffc:	6442                	ld	s0,16(sp)
    80002ffe:	64a2                	ld	s1,8(sp)
    80003000:	6105                	addi	sp,sp,32
    80003002:	8082                	ret

0000000080003004 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003004:	7179                	addi	sp,sp,-48
    80003006:	f406                	sd	ra,40(sp)
    80003008:	f022                	sd	s0,32(sp)
    8000300a:	ec26                	sd	s1,24(sp)
    8000300c:	e84a                	sd	s2,16(sp)
    8000300e:	e44e                	sd	s3,8(sp)
    80003010:	e052                	sd	s4,0(sp)
    80003012:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003014:	00005597          	auipc	a1,0x5
    80003018:	53458593          	addi	a1,a1,1332 # 80008548 <syscalls+0xc0>
    8000301c:	00014517          	auipc	a0,0x14
    80003020:	0cc50513          	addi	a0,a0,204 # 800170e8 <bcache>
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	b30080e7          	jalr	-1232(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000302c:	0001c797          	auipc	a5,0x1c
    80003030:	0bc78793          	addi	a5,a5,188 # 8001f0e8 <bcache+0x8000>
    80003034:	0001c717          	auipc	a4,0x1c
    80003038:	31c70713          	addi	a4,a4,796 # 8001f350 <bcache+0x8268>
    8000303c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003040:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003044:	00014497          	auipc	s1,0x14
    80003048:	0bc48493          	addi	s1,s1,188 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    8000304c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000304e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003050:	00005a17          	auipc	s4,0x5
    80003054:	500a0a13          	addi	s4,s4,1280 # 80008550 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003058:	2b893783          	ld	a5,696(s2)
    8000305c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000305e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003062:	85d2                	mv	a1,s4
    80003064:	01048513          	addi	a0,s1,16
    80003068:	00001097          	auipc	ra,0x1
    8000306c:	4bc080e7          	jalr	1212(ra) # 80004524 <initsleeplock>
    bcache.head.next->prev = b;
    80003070:	2b893783          	ld	a5,696(s2)
    80003074:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003076:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000307a:	45848493          	addi	s1,s1,1112
    8000307e:	fd349de3          	bne	s1,s3,80003058 <binit+0x54>
  }
}
    80003082:	70a2                	ld	ra,40(sp)
    80003084:	7402                	ld	s0,32(sp)
    80003086:	64e2                	ld	s1,24(sp)
    80003088:	6942                	ld	s2,16(sp)
    8000308a:	69a2                	ld	s3,8(sp)
    8000308c:	6a02                	ld	s4,0(sp)
    8000308e:	6145                	addi	sp,sp,48
    80003090:	8082                	ret

0000000080003092 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003092:	7179                	addi	sp,sp,-48
    80003094:	f406                	sd	ra,40(sp)
    80003096:	f022                	sd	s0,32(sp)
    80003098:	ec26                	sd	s1,24(sp)
    8000309a:	e84a                	sd	s2,16(sp)
    8000309c:	e44e                	sd	s3,8(sp)
    8000309e:	1800                	addi	s0,sp,48
    800030a0:	89aa                	mv	s3,a0
    800030a2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030a4:	00014517          	auipc	a0,0x14
    800030a8:	04450513          	addi	a0,a0,68 # 800170e8 <bcache>
    800030ac:	ffffe097          	auipc	ra,0xffffe
    800030b0:	b38080e7          	jalr	-1224(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030b4:	0001c497          	auipc	s1,0x1c
    800030b8:	2ec4b483          	ld	s1,748(s1) # 8001f3a0 <bcache+0x82b8>
    800030bc:	0001c797          	auipc	a5,0x1c
    800030c0:	29478793          	addi	a5,a5,660 # 8001f350 <bcache+0x8268>
    800030c4:	02f48f63          	beq	s1,a5,80003102 <bread+0x70>
    800030c8:	873e                	mv	a4,a5
    800030ca:	a021                	j	800030d2 <bread+0x40>
    800030cc:	68a4                	ld	s1,80(s1)
    800030ce:	02e48a63          	beq	s1,a4,80003102 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030d2:	449c                	lw	a5,8(s1)
    800030d4:	ff379ce3          	bne	a5,s3,800030cc <bread+0x3a>
    800030d8:	44dc                	lw	a5,12(s1)
    800030da:	ff2799e3          	bne	a5,s2,800030cc <bread+0x3a>
      b->refcnt++;
    800030de:	40bc                	lw	a5,64(s1)
    800030e0:	2785                	addiw	a5,a5,1
    800030e2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030e4:	00014517          	auipc	a0,0x14
    800030e8:	00450513          	addi	a0,a0,4 # 800170e8 <bcache>
    800030ec:	ffffe097          	auipc	ra,0xffffe
    800030f0:	bac080e7          	jalr	-1108(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800030f4:	01048513          	addi	a0,s1,16
    800030f8:	00001097          	auipc	ra,0x1
    800030fc:	466080e7          	jalr	1126(ra) # 8000455e <acquiresleep>
      return b;
    80003100:	a8b9                	j	8000315e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003102:	0001c497          	auipc	s1,0x1c
    80003106:	2964b483          	ld	s1,662(s1) # 8001f398 <bcache+0x82b0>
    8000310a:	0001c797          	auipc	a5,0x1c
    8000310e:	24678793          	addi	a5,a5,582 # 8001f350 <bcache+0x8268>
    80003112:	00f48863          	beq	s1,a5,80003122 <bread+0x90>
    80003116:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003118:	40bc                	lw	a5,64(s1)
    8000311a:	cf81                	beqz	a5,80003132 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000311c:	64a4                	ld	s1,72(s1)
    8000311e:	fee49de3          	bne	s1,a4,80003118 <bread+0x86>
  panic("bget: no buffers");
    80003122:	00005517          	auipc	a0,0x5
    80003126:	43650513          	addi	a0,a0,1078 # 80008558 <syscalls+0xd0>
    8000312a:	ffffd097          	auipc	ra,0xffffd
    8000312e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
      b->dev = dev;
    80003132:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003136:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000313a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000313e:	4785                	li	a5,1
    80003140:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003142:	00014517          	auipc	a0,0x14
    80003146:	fa650513          	addi	a0,a0,-90 # 800170e8 <bcache>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	b4e080e7          	jalr	-1202(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003152:	01048513          	addi	a0,s1,16
    80003156:	00001097          	auipc	ra,0x1
    8000315a:	408080e7          	jalr	1032(ra) # 8000455e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000315e:	409c                	lw	a5,0(s1)
    80003160:	cb89                	beqz	a5,80003172 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003162:	8526                	mv	a0,s1
    80003164:	70a2                	ld	ra,40(sp)
    80003166:	7402                	ld	s0,32(sp)
    80003168:	64e2                	ld	s1,24(sp)
    8000316a:	6942                	ld	s2,16(sp)
    8000316c:	69a2                	ld	s3,8(sp)
    8000316e:	6145                	addi	sp,sp,48
    80003170:	8082                	ret
    virtio_disk_rw(b, 0);
    80003172:	4581                	li	a1,0
    80003174:	8526                	mv	a0,s1
    80003176:	00003097          	auipc	ra,0x3
    8000317a:	f10080e7          	jalr	-240(ra) # 80006086 <virtio_disk_rw>
    b->valid = 1;
    8000317e:	4785                	li	a5,1
    80003180:	c09c                	sw	a5,0(s1)
  return b;
    80003182:	b7c5                	j	80003162 <bread+0xd0>

0000000080003184 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	1000                	addi	s0,sp,32
    8000318e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003190:	0541                	addi	a0,a0,16
    80003192:	00001097          	auipc	ra,0x1
    80003196:	466080e7          	jalr	1126(ra) # 800045f8 <holdingsleep>
    8000319a:	cd01                	beqz	a0,800031b2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000319c:	4585                	li	a1,1
    8000319e:	8526                	mv	a0,s1
    800031a0:	00003097          	auipc	ra,0x3
    800031a4:	ee6080e7          	jalr	-282(ra) # 80006086 <virtio_disk_rw>
}
    800031a8:	60e2                	ld	ra,24(sp)
    800031aa:	6442                	ld	s0,16(sp)
    800031ac:	64a2                	ld	s1,8(sp)
    800031ae:	6105                	addi	sp,sp,32
    800031b0:	8082                	ret
    panic("bwrite");
    800031b2:	00005517          	auipc	a0,0x5
    800031b6:	3be50513          	addi	a0,a0,958 # 80008570 <syscalls+0xe8>
    800031ba:	ffffd097          	auipc	ra,0xffffd
    800031be:	384080e7          	jalr	900(ra) # 8000053e <panic>

00000000800031c2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031c2:	1101                	addi	sp,sp,-32
    800031c4:	ec06                	sd	ra,24(sp)
    800031c6:	e822                	sd	s0,16(sp)
    800031c8:	e426                	sd	s1,8(sp)
    800031ca:	e04a                	sd	s2,0(sp)
    800031cc:	1000                	addi	s0,sp,32
    800031ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031d0:	01050913          	addi	s2,a0,16
    800031d4:	854a                	mv	a0,s2
    800031d6:	00001097          	auipc	ra,0x1
    800031da:	422080e7          	jalr	1058(ra) # 800045f8 <holdingsleep>
    800031de:	c92d                	beqz	a0,80003250 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031e0:	854a                	mv	a0,s2
    800031e2:	00001097          	auipc	ra,0x1
    800031e6:	3d2080e7          	jalr	978(ra) # 800045b4 <releasesleep>

  acquire(&bcache.lock);
    800031ea:	00014517          	auipc	a0,0x14
    800031ee:	efe50513          	addi	a0,a0,-258 # 800170e8 <bcache>
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	9f2080e7          	jalr	-1550(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031fa:	40bc                	lw	a5,64(s1)
    800031fc:	37fd                	addiw	a5,a5,-1
    800031fe:	0007871b          	sext.w	a4,a5
    80003202:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003204:	eb05                	bnez	a4,80003234 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003206:	68bc                	ld	a5,80(s1)
    80003208:	64b8                	ld	a4,72(s1)
    8000320a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000320c:	64bc                	ld	a5,72(s1)
    8000320e:	68b8                	ld	a4,80(s1)
    80003210:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003212:	0001c797          	auipc	a5,0x1c
    80003216:	ed678793          	addi	a5,a5,-298 # 8001f0e8 <bcache+0x8000>
    8000321a:	2b87b703          	ld	a4,696(a5)
    8000321e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003220:	0001c717          	auipc	a4,0x1c
    80003224:	13070713          	addi	a4,a4,304 # 8001f350 <bcache+0x8268>
    80003228:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000322a:	2b87b703          	ld	a4,696(a5)
    8000322e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003230:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003234:	00014517          	auipc	a0,0x14
    80003238:	eb450513          	addi	a0,a0,-332 # 800170e8 <bcache>
    8000323c:	ffffe097          	auipc	ra,0xffffe
    80003240:	a5c080e7          	jalr	-1444(ra) # 80000c98 <release>
}
    80003244:	60e2                	ld	ra,24(sp)
    80003246:	6442                	ld	s0,16(sp)
    80003248:	64a2                	ld	s1,8(sp)
    8000324a:	6902                	ld	s2,0(sp)
    8000324c:	6105                	addi	sp,sp,32
    8000324e:	8082                	ret
    panic("brelse");
    80003250:	00005517          	auipc	a0,0x5
    80003254:	32850513          	addi	a0,a0,808 # 80008578 <syscalls+0xf0>
    80003258:	ffffd097          	auipc	ra,0xffffd
    8000325c:	2e6080e7          	jalr	742(ra) # 8000053e <panic>

0000000080003260 <bpin>:

void
bpin(struct buf *b) {
    80003260:	1101                	addi	sp,sp,-32
    80003262:	ec06                	sd	ra,24(sp)
    80003264:	e822                	sd	s0,16(sp)
    80003266:	e426                	sd	s1,8(sp)
    80003268:	1000                	addi	s0,sp,32
    8000326a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000326c:	00014517          	auipc	a0,0x14
    80003270:	e7c50513          	addi	a0,a0,-388 # 800170e8 <bcache>
    80003274:	ffffe097          	auipc	ra,0xffffe
    80003278:	970080e7          	jalr	-1680(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000327c:	40bc                	lw	a5,64(s1)
    8000327e:	2785                	addiw	a5,a5,1
    80003280:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003282:	00014517          	auipc	a0,0x14
    80003286:	e6650513          	addi	a0,a0,-410 # 800170e8 <bcache>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	a0e080e7          	jalr	-1522(ra) # 80000c98 <release>
}
    80003292:	60e2                	ld	ra,24(sp)
    80003294:	6442                	ld	s0,16(sp)
    80003296:	64a2                	ld	s1,8(sp)
    80003298:	6105                	addi	sp,sp,32
    8000329a:	8082                	ret

000000008000329c <bunpin>:

void
bunpin(struct buf *b) {
    8000329c:	1101                	addi	sp,sp,-32
    8000329e:	ec06                	sd	ra,24(sp)
    800032a0:	e822                	sd	s0,16(sp)
    800032a2:	e426                	sd	s1,8(sp)
    800032a4:	1000                	addi	s0,sp,32
    800032a6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032a8:	00014517          	auipc	a0,0x14
    800032ac:	e4050513          	addi	a0,a0,-448 # 800170e8 <bcache>
    800032b0:	ffffe097          	auipc	ra,0xffffe
    800032b4:	934080e7          	jalr	-1740(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032b8:	40bc                	lw	a5,64(s1)
    800032ba:	37fd                	addiw	a5,a5,-1
    800032bc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032be:	00014517          	auipc	a0,0x14
    800032c2:	e2a50513          	addi	a0,a0,-470 # 800170e8 <bcache>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	9d2080e7          	jalr	-1582(ra) # 80000c98 <release>
}
    800032ce:	60e2                	ld	ra,24(sp)
    800032d0:	6442                	ld	s0,16(sp)
    800032d2:	64a2                	ld	s1,8(sp)
    800032d4:	6105                	addi	sp,sp,32
    800032d6:	8082                	ret

00000000800032d8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032d8:	1101                	addi	sp,sp,-32
    800032da:	ec06                	sd	ra,24(sp)
    800032dc:	e822                	sd	s0,16(sp)
    800032de:	e426                	sd	s1,8(sp)
    800032e0:	e04a                	sd	s2,0(sp)
    800032e2:	1000                	addi	s0,sp,32
    800032e4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032e6:	00d5d59b          	srliw	a1,a1,0xd
    800032ea:	0001c797          	auipc	a5,0x1c
    800032ee:	4da7a783          	lw	a5,1242(a5) # 8001f7c4 <sb+0x1c>
    800032f2:	9dbd                	addw	a1,a1,a5
    800032f4:	00000097          	auipc	ra,0x0
    800032f8:	d9e080e7          	jalr	-610(ra) # 80003092 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032fc:	0074f713          	andi	a4,s1,7
    80003300:	4785                	li	a5,1
    80003302:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003306:	14ce                	slli	s1,s1,0x33
    80003308:	90d9                	srli	s1,s1,0x36
    8000330a:	00950733          	add	a4,a0,s1
    8000330e:	05874703          	lbu	a4,88(a4)
    80003312:	00e7f6b3          	and	a3,a5,a4
    80003316:	c69d                	beqz	a3,80003344 <bfree+0x6c>
    80003318:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000331a:	94aa                	add	s1,s1,a0
    8000331c:	fff7c793          	not	a5,a5
    80003320:	8ff9                	and	a5,a5,a4
    80003322:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003326:	00001097          	auipc	ra,0x1
    8000332a:	118080e7          	jalr	280(ra) # 8000443e <log_write>
  brelse(bp);
    8000332e:	854a                	mv	a0,s2
    80003330:	00000097          	auipc	ra,0x0
    80003334:	e92080e7          	jalr	-366(ra) # 800031c2 <brelse>
}
    80003338:	60e2                	ld	ra,24(sp)
    8000333a:	6442                	ld	s0,16(sp)
    8000333c:	64a2                	ld	s1,8(sp)
    8000333e:	6902                	ld	s2,0(sp)
    80003340:	6105                	addi	sp,sp,32
    80003342:	8082                	ret
    panic("freeing free block");
    80003344:	00005517          	auipc	a0,0x5
    80003348:	23c50513          	addi	a0,a0,572 # 80008580 <syscalls+0xf8>
    8000334c:	ffffd097          	auipc	ra,0xffffd
    80003350:	1f2080e7          	jalr	498(ra) # 8000053e <panic>

0000000080003354 <balloc>:
{
    80003354:	711d                	addi	sp,sp,-96
    80003356:	ec86                	sd	ra,88(sp)
    80003358:	e8a2                	sd	s0,80(sp)
    8000335a:	e4a6                	sd	s1,72(sp)
    8000335c:	e0ca                	sd	s2,64(sp)
    8000335e:	fc4e                	sd	s3,56(sp)
    80003360:	f852                	sd	s4,48(sp)
    80003362:	f456                	sd	s5,40(sp)
    80003364:	f05a                	sd	s6,32(sp)
    80003366:	ec5e                	sd	s7,24(sp)
    80003368:	e862                	sd	s8,16(sp)
    8000336a:	e466                	sd	s9,8(sp)
    8000336c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000336e:	0001c797          	auipc	a5,0x1c
    80003372:	43e7a783          	lw	a5,1086(a5) # 8001f7ac <sb+0x4>
    80003376:	cbd1                	beqz	a5,8000340a <balloc+0xb6>
    80003378:	8baa                	mv	s7,a0
    8000337a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000337c:	0001cb17          	auipc	s6,0x1c
    80003380:	42cb0b13          	addi	s6,s6,1068 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003384:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003386:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003388:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000338a:	6c89                	lui	s9,0x2
    8000338c:	a831                	j	800033a8 <balloc+0x54>
    brelse(bp);
    8000338e:	854a                	mv	a0,s2
    80003390:	00000097          	auipc	ra,0x0
    80003394:	e32080e7          	jalr	-462(ra) # 800031c2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003398:	015c87bb          	addw	a5,s9,s5
    8000339c:	00078a9b          	sext.w	s5,a5
    800033a0:	004b2703          	lw	a4,4(s6)
    800033a4:	06eaf363          	bgeu	s5,a4,8000340a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033a8:	41fad79b          	sraiw	a5,s5,0x1f
    800033ac:	0137d79b          	srliw	a5,a5,0x13
    800033b0:	015787bb          	addw	a5,a5,s5
    800033b4:	40d7d79b          	sraiw	a5,a5,0xd
    800033b8:	01cb2583          	lw	a1,28(s6)
    800033bc:	9dbd                	addw	a1,a1,a5
    800033be:	855e                	mv	a0,s7
    800033c0:	00000097          	auipc	ra,0x0
    800033c4:	cd2080e7          	jalr	-814(ra) # 80003092 <bread>
    800033c8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ca:	004b2503          	lw	a0,4(s6)
    800033ce:	000a849b          	sext.w	s1,s5
    800033d2:	8662                	mv	a2,s8
    800033d4:	faa4fde3          	bgeu	s1,a0,8000338e <balloc+0x3a>
      m = 1 << (bi % 8);
    800033d8:	41f6579b          	sraiw	a5,a2,0x1f
    800033dc:	01d7d69b          	srliw	a3,a5,0x1d
    800033e0:	00c6873b          	addw	a4,a3,a2
    800033e4:	00777793          	andi	a5,a4,7
    800033e8:	9f95                	subw	a5,a5,a3
    800033ea:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033ee:	4037571b          	sraiw	a4,a4,0x3
    800033f2:	00e906b3          	add	a3,s2,a4
    800033f6:	0586c683          	lbu	a3,88(a3)
    800033fa:	00d7f5b3          	and	a1,a5,a3
    800033fe:	cd91                	beqz	a1,8000341a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003400:	2605                	addiw	a2,a2,1
    80003402:	2485                	addiw	s1,s1,1
    80003404:	fd4618e3          	bne	a2,s4,800033d4 <balloc+0x80>
    80003408:	b759                	j	8000338e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000340a:	00005517          	auipc	a0,0x5
    8000340e:	18e50513          	addi	a0,a0,398 # 80008598 <syscalls+0x110>
    80003412:	ffffd097          	auipc	ra,0xffffd
    80003416:	12c080e7          	jalr	300(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000341a:	974a                	add	a4,a4,s2
    8000341c:	8fd5                	or	a5,a5,a3
    8000341e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003422:	854a                	mv	a0,s2
    80003424:	00001097          	auipc	ra,0x1
    80003428:	01a080e7          	jalr	26(ra) # 8000443e <log_write>
        brelse(bp);
    8000342c:	854a                	mv	a0,s2
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	d94080e7          	jalr	-620(ra) # 800031c2 <brelse>
  bp = bread(dev, bno);
    80003436:	85a6                	mv	a1,s1
    80003438:	855e                	mv	a0,s7
    8000343a:	00000097          	auipc	ra,0x0
    8000343e:	c58080e7          	jalr	-936(ra) # 80003092 <bread>
    80003442:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003444:	40000613          	li	a2,1024
    80003448:	4581                	li	a1,0
    8000344a:	05850513          	addi	a0,a0,88
    8000344e:	ffffe097          	auipc	ra,0xffffe
    80003452:	892080e7          	jalr	-1902(ra) # 80000ce0 <memset>
  log_write(bp);
    80003456:	854a                	mv	a0,s2
    80003458:	00001097          	auipc	ra,0x1
    8000345c:	fe6080e7          	jalr	-26(ra) # 8000443e <log_write>
  brelse(bp);
    80003460:	854a                	mv	a0,s2
    80003462:	00000097          	auipc	ra,0x0
    80003466:	d60080e7          	jalr	-672(ra) # 800031c2 <brelse>
}
    8000346a:	8526                	mv	a0,s1
    8000346c:	60e6                	ld	ra,88(sp)
    8000346e:	6446                	ld	s0,80(sp)
    80003470:	64a6                	ld	s1,72(sp)
    80003472:	6906                	ld	s2,64(sp)
    80003474:	79e2                	ld	s3,56(sp)
    80003476:	7a42                	ld	s4,48(sp)
    80003478:	7aa2                	ld	s5,40(sp)
    8000347a:	7b02                	ld	s6,32(sp)
    8000347c:	6be2                	ld	s7,24(sp)
    8000347e:	6c42                	ld	s8,16(sp)
    80003480:	6ca2                	ld	s9,8(sp)
    80003482:	6125                	addi	sp,sp,96
    80003484:	8082                	ret

0000000080003486 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003486:	7179                	addi	sp,sp,-48
    80003488:	f406                	sd	ra,40(sp)
    8000348a:	f022                	sd	s0,32(sp)
    8000348c:	ec26                	sd	s1,24(sp)
    8000348e:	e84a                	sd	s2,16(sp)
    80003490:	e44e                	sd	s3,8(sp)
    80003492:	e052                	sd	s4,0(sp)
    80003494:	1800                	addi	s0,sp,48
    80003496:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003498:	47ad                	li	a5,11
    8000349a:	04b7fe63          	bgeu	a5,a1,800034f6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000349e:	ff45849b          	addiw	s1,a1,-12
    800034a2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034a6:	0ff00793          	li	a5,255
    800034aa:	0ae7e363          	bltu	a5,a4,80003550 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034ae:	08052583          	lw	a1,128(a0)
    800034b2:	c5ad                	beqz	a1,8000351c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034b4:	00092503          	lw	a0,0(s2)
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	bda080e7          	jalr	-1062(ra) # 80003092 <bread>
    800034c0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034c2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034c6:	02049593          	slli	a1,s1,0x20
    800034ca:	9181                	srli	a1,a1,0x20
    800034cc:	058a                	slli	a1,a1,0x2
    800034ce:	00b784b3          	add	s1,a5,a1
    800034d2:	0004a983          	lw	s3,0(s1)
    800034d6:	04098d63          	beqz	s3,80003530 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800034da:	8552                	mv	a0,s4
    800034dc:	00000097          	auipc	ra,0x0
    800034e0:	ce6080e7          	jalr	-794(ra) # 800031c2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034e4:	854e                	mv	a0,s3
    800034e6:	70a2                	ld	ra,40(sp)
    800034e8:	7402                	ld	s0,32(sp)
    800034ea:	64e2                	ld	s1,24(sp)
    800034ec:	6942                	ld	s2,16(sp)
    800034ee:	69a2                	ld	s3,8(sp)
    800034f0:	6a02                	ld	s4,0(sp)
    800034f2:	6145                	addi	sp,sp,48
    800034f4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034f6:	02059493          	slli	s1,a1,0x20
    800034fa:	9081                	srli	s1,s1,0x20
    800034fc:	048a                	slli	s1,s1,0x2
    800034fe:	94aa                	add	s1,s1,a0
    80003500:	0504a983          	lw	s3,80(s1)
    80003504:	fe0990e3          	bnez	s3,800034e4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003508:	4108                	lw	a0,0(a0)
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	e4a080e7          	jalr	-438(ra) # 80003354 <balloc>
    80003512:	0005099b          	sext.w	s3,a0
    80003516:	0534a823          	sw	s3,80(s1)
    8000351a:	b7e9                	j	800034e4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000351c:	4108                	lw	a0,0(a0)
    8000351e:	00000097          	auipc	ra,0x0
    80003522:	e36080e7          	jalr	-458(ra) # 80003354 <balloc>
    80003526:	0005059b          	sext.w	a1,a0
    8000352a:	08b92023          	sw	a1,128(s2)
    8000352e:	b759                	j	800034b4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003530:	00092503          	lw	a0,0(s2)
    80003534:	00000097          	auipc	ra,0x0
    80003538:	e20080e7          	jalr	-480(ra) # 80003354 <balloc>
    8000353c:	0005099b          	sext.w	s3,a0
    80003540:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003544:	8552                	mv	a0,s4
    80003546:	00001097          	auipc	ra,0x1
    8000354a:	ef8080e7          	jalr	-264(ra) # 8000443e <log_write>
    8000354e:	b771                	j	800034da <bmap+0x54>
  panic("bmap: out of range");
    80003550:	00005517          	auipc	a0,0x5
    80003554:	06050513          	addi	a0,a0,96 # 800085b0 <syscalls+0x128>
    80003558:	ffffd097          	auipc	ra,0xffffd
    8000355c:	fe6080e7          	jalr	-26(ra) # 8000053e <panic>

0000000080003560 <iget>:
{
    80003560:	7179                	addi	sp,sp,-48
    80003562:	f406                	sd	ra,40(sp)
    80003564:	f022                	sd	s0,32(sp)
    80003566:	ec26                	sd	s1,24(sp)
    80003568:	e84a                	sd	s2,16(sp)
    8000356a:	e44e                	sd	s3,8(sp)
    8000356c:	e052                	sd	s4,0(sp)
    8000356e:	1800                	addi	s0,sp,48
    80003570:	89aa                	mv	s3,a0
    80003572:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003574:	0001c517          	auipc	a0,0x1c
    80003578:	25450513          	addi	a0,a0,596 # 8001f7c8 <itable>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	668080e7          	jalr	1640(ra) # 80000be4 <acquire>
  empty = 0;
    80003584:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003586:	0001c497          	auipc	s1,0x1c
    8000358a:	25a48493          	addi	s1,s1,602 # 8001f7e0 <itable+0x18>
    8000358e:	0001e697          	auipc	a3,0x1e
    80003592:	ce268693          	addi	a3,a3,-798 # 80021270 <log>
    80003596:	a039                	j	800035a4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003598:	02090b63          	beqz	s2,800035ce <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000359c:	08848493          	addi	s1,s1,136
    800035a0:	02d48a63          	beq	s1,a3,800035d4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035a4:	449c                	lw	a5,8(s1)
    800035a6:	fef059e3          	blez	a5,80003598 <iget+0x38>
    800035aa:	4098                	lw	a4,0(s1)
    800035ac:	ff3716e3          	bne	a4,s3,80003598 <iget+0x38>
    800035b0:	40d8                	lw	a4,4(s1)
    800035b2:	ff4713e3          	bne	a4,s4,80003598 <iget+0x38>
      ip->ref++;
    800035b6:	2785                	addiw	a5,a5,1
    800035b8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035ba:	0001c517          	auipc	a0,0x1c
    800035be:	20e50513          	addi	a0,a0,526 # 8001f7c8 <itable>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	6d6080e7          	jalr	1750(ra) # 80000c98 <release>
      return ip;
    800035ca:	8926                	mv	s2,s1
    800035cc:	a03d                	j	800035fa <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035ce:	f7f9                	bnez	a5,8000359c <iget+0x3c>
    800035d0:	8926                	mv	s2,s1
    800035d2:	b7e9                	j	8000359c <iget+0x3c>
  if(empty == 0)
    800035d4:	02090c63          	beqz	s2,8000360c <iget+0xac>
  ip->dev = dev;
    800035d8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035dc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035e0:	4785                	li	a5,1
    800035e2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035e6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035ea:	0001c517          	auipc	a0,0x1c
    800035ee:	1de50513          	addi	a0,a0,478 # 8001f7c8 <itable>
    800035f2:	ffffd097          	auipc	ra,0xffffd
    800035f6:	6a6080e7          	jalr	1702(ra) # 80000c98 <release>
}
    800035fa:	854a                	mv	a0,s2
    800035fc:	70a2                	ld	ra,40(sp)
    800035fe:	7402                	ld	s0,32(sp)
    80003600:	64e2                	ld	s1,24(sp)
    80003602:	6942                	ld	s2,16(sp)
    80003604:	69a2                	ld	s3,8(sp)
    80003606:	6a02                	ld	s4,0(sp)
    80003608:	6145                	addi	sp,sp,48
    8000360a:	8082                	ret
    panic("iget: no inodes");
    8000360c:	00005517          	auipc	a0,0x5
    80003610:	fbc50513          	addi	a0,a0,-68 # 800085c8 <syscalls+0x140>
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	f2a080e7          	jalr	-214(ra) # 8000053e <panic>

000000008000361c <fsinit>:
fsinit(int dev) {
    8000361c:	7179                	addi	sp,sp,-48
    8000361e:	f406                	sd	ra,40(sp)
    80003620:	f022                	sd	s0,32(sp)
    80003622:	ec26                	sd	s1,24(sp)
    80003624:	e84a                	sd	s2,16(sp)
    80003626:	e44e                	sd	s3,8(sp)
    80003628:	1800                	addi	s0,sp,48
    8000362a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000362c:	4585                	li	a1,1
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	a64080e7          	jalr	-1436(ra) # 80003092 <bread>
    80003636:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003638:	0001c997          	auipc	s3,0x1c
    8000363c:	17098993          	addi	s3,s3,368 # 8001f7a8 <sb>
    80003640:	02000613          	li	a2,32
    80003644:	05850593          	addi	a1,a0,88
    80003648:	854e                	mv	a0,s3
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	6f6080e7          	jalr	1782(ra) # 80000d40 <memmove>
  brelse(bp);
    80003652:	8526                	mv	a0,s1
    80003654:	00000097          	auipc	ra,0x0
    80003658:	b6e080e7          	jalr	-1170(ra) # 800031c2 <brelse>
  if(sb.magic != FSMAGIC)
    8000365c:	0009a703          	lw	a4,0(s3)
    80003660:	102037b7          	lui	a5,0x10203
    80003664:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003668:	02f71263          	bne	a4,a5,8000368c <fsinit+0x70>
  initlog(dev, &sb);
    8000366c:	0001c597          	auipc	a1,0x1c
    80003670:	13c58593          	addi	a1,a1,316 # 8001f7a8 <sb>
    80003674:	854a                	mv	a0,s2
    80003676:	00001097          	auipc	ra,0x1
    8000367a:	b4c080e7          	jalr	-1204(ra) # 800041c2 <initlog>
}
    8000367e:	70a2                	ld	ra,40(sp)
    80003680:	7402                	ld	s0,32(sp)
    80003682:	64e2                	ld	s1,24(sp)
    80003684:	6942                	ld	s2,16(sp)
    80003686:	69a2                	ld	s3,8(sp)
    80003688:	6145                	addi	sp,sp,48
    8000368a:	8082                	ret
    panic("invalid file system");
    8000368c:	00005517          	auipc	a0,0x5
    80003690:	f4c50513          	addi	a0,a0,-180 # 800085d8 <syscalls+0x150>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	eaa080e7          	jalr	-342(ra) # 8000053e <panic>

000000008000369c <iinit>:
{
    8000369c:	7179                	addi	sp,sp,-48
    8000369e:	f406                	sd	ra,40(sp)
    800036a0:	f022                	sd	s0,32(sp)
    800036a2:	ec26                	sd	s1,24(sp)
    800036a4:	e84a                	sd	s2,16(sp)
    800036a6:	e44e                	sd	s3,8(sp)
    800036a8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036aa:	00005597          	auipc	a1,0x5
    800036ae:	f4658593          	addi	a1,a1,-186 # 800085f0 <syscalls+0x168>
    800036b2:	0001c517          	auipc	a0,0x1c
    800036b6:	11650513          	addi	a0,a0,278 # 8001f7c8 <itable>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	49a080e7          	jalr	1178(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036c2:	0001c497          	auipc	s1,0x1c
    800036c6:	12e48493          	addi	s1,s1,302 # 8001f7f0 <itable+0x28>
    800036ca:	0001e997          	auipc	s3,0x1e
    800036ce:	bb698993          	addi	s3,s3,-1098 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036d2:	00005917          	auipc	s2,0x5
    800036d6:	f2690913          	addi	s2,s2,-218 # 800085f8 <syscalls+0x170>
    800036da:	85ca                	mv	a1,s2
    800036dc:	8526                	mv	a0,s1
    800036de:	00001097          	auipc	ra,0x1
    800036e2:	e46080e7          	jalr	-442(ra) # 80004524 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036e6:	08848493          	addi	s1,s1,136
    800036ea:	ff3498e3          	bne	s1,s3,800036da <iinit+0x3e>
}
    800036ee:	70a2                	ld	ra,40(sp)
    800036f0:	7402                	ld	s0,32(sp)
    800036f2:	64e2                	ld	s1,24(sp)
    800036f4:	6942                	ld	s2,16(sp)
    800036f6:	69a2                	ld	s3,8(sp)
    800036f8:	6145                	addi	sp,sp,48
    800036fa:	8082                	ret

00000000800036fc <ialloc>:
{
    800036fc:	715d                	addi	sp,sp,-80
    800036fe:	e486                	sd	ra,72(sp)
    80003700:	e0a2                	sd	s0,64(sp)
    80003702:	fc26                	sd	s1,56(sp)
    80003704:	f84a                	sd	s2,48(sp)
    80003706:	f44e                	sd	s3,40(sp)
    80003708:	f052                	sd	s4,32(sp)
    8000370a:	ec56                	sd	s5,24(sp)
    8000370c:	e85a                	sd	s6,16(sp)
    8000370e:	e45e                	sd	s7,8(sp)
    80003710:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003712:	0001c717          	auipc	a4,0x1c
    80003716:	0a272703          	lw	a4,162(a4) # 8001f7b4 <sb+0xc>
    8000371a:	4785                	li	a5,1
    8000371c:	04e7fa63          	bgeu	a5,a4,80003770 <ialloc+0x74>
    80003720:	8aaa                	mv	s5,a0
    80003722:	8bae                	mv	s7,a1
    80003724:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003726:	0001ca17          	auipc	s4,0x1c
    8000372a:	082a0a13          	addi	s4,s4,130 # 8001f7a8 <sb>
    8000372e:	00048b1b          	sext.w	s6,s1
    80003732:	0044d593          	srli	a1,s1,0x4
    80003736:	018a2783          	lw	a5,24(s4)
    8000373a:	9dbd                	addw	a1,a1,a5
    8000373c:	8556                	mv	a0,s5
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	954080e7          	jalr	-1708(ra) # 80003092 <bread>
    80003746:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003748:	05850993          	addi	s3,a0,88
    8000374c:	00f4f793          	andi	a5,s1,15
    80003750:	079a                	slli	a5,a5,0x6
    80003752:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003754:	00099783          	lh	a5,0(s3)
    80003758:	c785                	beqz	a5,80003780 <ialloc+0x84>
    brelse(bp);
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	a68080e7          	jalr	-1432(ra) # 800031c2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003762:	0485                	addi	s1,s1,1
    80003764:	00ca2703          	lw	a4,12(s4)
    80003768:	0004879b          	sext.w	a5,s1
    8000376c:	fce7e1e3          	bltu	a5,a4,8000372e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003770:	00005517          	auipc	a0,0x5
    80003774:	e9050513          	addi	a0,a0,-368 # 80008600 <syscalls+0x178>
    80003778:	ffffd097          	auipc	ra,0xffffd
    8000377c:	dc6080e7          	jalr	-570(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003780:	04000613          	li	a2,64
    80003784:	4581                	li	a1,0
    80003786:	854e                	mv	a0,s3
    80003788:	ffffd097          	auipc	ra,0xffffd
    8000378c:	558080e7          	jalr	1368(ra) # 80000ce0 <memset>
      dip->type = type;
    80003790:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003794:	854a                	mv	a0,s2
    80003796:	00001097          	auipc	ra,0x1
    8000379a:	ca8080e7          	jalr	-856(ra) # 8000443e <log_write>
      brelse(bp);
    8000379e:	854a                	mv	a0,s2
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	a22080e7          	jalr	-1502(ra) # 800031c2 <brelse>
      return iget(dev, inum);
    800037a8:	85da                	mv	a1,s6
    800037aa:	8556                	mv	a0,s5
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	db4080e7          	jalr	-588(ra) # 80003560 <iget>
}
    800037b4:	60a6                	ld	ra,72(sp)
    800037b6:	6406                	ld	s0,64(sp)
    800037b8:	74e2                	ld	s1,56(sp)
    800037ba:	7942                	ld	s2,48(sp)
    800037bc:	79a2                	ld	s3,40(sp)
    800037be:	7a02                	ld	s4,32(sp)
    800037c0:	6ae2                	ld	s5,24(sp)
    800037c2:	6b42                	ld	s6,16(sp)
    800037c4:	6ba2                	ld	s7,8(sp)
    800037c6:	6161                	addi	sp,sp,80
    800037c8:	8082                	ret

00000000800037ca <iupdate>:
{
    800037ca:	1101                	addi	sp,sp,-32
    800037cc:	ec06                	sd	ra,24(sp)
    800037ce:	e822                	sd	s0,16(sp)
    800037d0:	e426                	sd	s1,8(sp)
    800037d2:	e04a                	sd	s2,0(sp)
    800037d4:	1000                	addi	s0,sp,32
    800037d6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037d8:	415c                	lw	a5,4(a0)
    800037da:	0047d79b          	srliw	a5,a5,0x4
    800037de:	0001c597          	auipc	a1,0x1c
    800037e2:	fe25a583          	lw	a1,-30(a1) # 8001f7c0 <sb+0x18>
    800037e6:	9dbd                	addw	a1,a1,a5
    800037e8:	4108                	lw	a0,0(a0)
    800037ea:	00000097          	auipc	ra,0x0
    800037ee:	8a8080e7          	jalr	-1880(ra) # 80003092 <bread>
    800037f2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037f4:	05850793          	addi	a5,a0,88
    800037f8:	40c8                	lw	a0,4(s1)
    800037fa:	893d                	andi	a0,a0,15
    800037fc:	051a                	slli	a0,a0,0x6
    800037fe:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003800:	04449703          	lh	a4,68(s1)
    80003804:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003808:	04649703          	lh	a4,70(s1)
    8000380c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003810:	04849703          	lh	a4,72(s1)
    80003814:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003818:	04a49703          	lh	a4,74(s1)
    8000381c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003820:	44f8                	lw	a4,76(s1)
    80003822:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003824:	03400613          	li	a2,52
    80003828:	05048593          	addi	a1,s1,80
    8000382c:	0531                	addi	a0,a0,12
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	512080e7          	jalr	1298(ra) # 80000d40 <memmove>
  log_write(bp);
    80003836:	854a                	mv	a0,s2
    80003838:	00001097          	auipc	ra,0x1
    8000383c:	c06080e7          	jalr	-1018(ra) # 8000443e <log_write>
  brelse(bp);
    80003840:	854a                	mv	a0,s2
    80003842:	00000097          	auipc	ra,0x0
    80003846:	980080e7          	jalr	-1664(ra) # 800031c2 <brelse>
}
    8000384a:	60e2                	ld	ra,24(sp)
    8000384c:	6442                	ld	s0,16(sp)
    8000384e:	64a2                	ld	s1,8(sp)
    80003850:	6902                	ld	s2,0(sp)
    80003852:	6105                	addi	sp,sp,32
    80003854:	8082                	ret

0000000080003856 <idup>:
{
    80003856:	1101                	addi	sp,sp,-32
    80003858:	ec06                	sd	ra,24(sp)
    8000385a:	e822                	sd	s0,16(sp)
    8000385c:	e426                	sd	s1,8(sp)
    8000385e:	1000                	addi	s0,sp,32
    80003860:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003862:	0001c517          	auipc	a0,0x1c
    80003866:	f6650513          	addi	a0,a0,-154 # 8001f7c8 <itable>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	37a080e7          	jalr	890(ra) # 80000be4 <acquire>
  ip->ref++;
    80003872:	449c                	lw	a5,8(s1)
    80003874:	2785                	addiw	a5,a5,1
    80003876:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003878:	0001c517          	auipc	a0,0x1c
    8000387c:	f5050513          	addi	a0,a0,-176 # 8001f7c8 <itable>
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	418080e7          	jalr	1048(ra) # 80000c98 <release>
}
    80003888:	8526                	mv	a0,s1
    8000388a:	60e2                	ld	ra,24(sp)
    8000388c:	6442                	ld	s0,16(sp)
    8000388e:	64a2                	ld	s1,8(sp)
    80003890:	6105                	addi	sp,sp,32
    80003892:	8082                	ret

0000000080003894 <ilock>:
{
    80003894:	1101                	addi	sp,sp,-32
    80003896:	ec06                	sd	ra,24(sp)
    80003898:	e822                	sd	s0,16(sp)
    8000389a:	e426                	sd	s1,8(sp)
    8000389c:	e04a                	sd	s2,0(sp)
    8000389e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038a0:	c115                	beqz	a0,800038c4 <ilock+0x30>
    800038a2:	84aa                	mv	s1,a0
    800038a4:	451c                	lw	a5,8(a0)
    800038a6:	00f05f63          	blez	a5,800038c4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038aa:	0541                	addi	a0,a0,16
    800038ac:	00001097          	auipc	ra,0x1
    800038b0:	cb2080e7          	jalr	-846(ra) # 8000455e <acquiresleep>
  if(ip->valid == 0){
    800038b4:	40bc                	lw	a5,64(s1)
    800038b6:	cf99                	beqz	a5,800038d4 <ilock+0x40>
}
    800038b8:	60e2                	ld	ra,24(sp)
    800038ba:	6442                	ld	s0,16(sp)
    800038bc:	64a2                	ld	s1,8(sp)
    800038be:	6902                	ld	s2,0(sp)
    800038c0:	6105                	addi	sp,sp,32
    800038c2:	8082                	ret
    panic("ilock");
    800038c4:	00005517          	auipc	a0,0x5
    800038c8:	d5450513          	addi	a0,a0,-684 # 80008618 <syscalls+0x190>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038d4:	40dc                	lw	a5,4(s1)
    800038d6:	0047d79b          	srliw	a5,a5,0x4
    800038da:	0001c597          	auipc	a1,0x1c
    800038de:	ee65a583          	lw	a1,-282(a1) # 8001f7c0 <sb+0x18>
    800038e2:	9dbd                	addw	a1,a1,a5
    800038e4:	4088                	lw	a0,0(s1)
    800038e6:	fffff097          	auipc	ra,0xfffff
    800038ea:	7ac080e7          	jalr	1964(ra) # 80003092 <bread>
    800038ee:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038f0:	05850593          	addi	a1,a0,88
    800038f4:	40dc                	lw	a5,4(s1)
    800038f6:	8bbd                	andi	a5,a5,15
    800038f8:	079a                	slli	a5,a5,0x6
    800038fa:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038fc:	00059783          	lh	a5,0(a1)
    80003900:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003904:	00259783          	lh	a5,2(a1)
    80003908:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000390c:	00459783          	lh	a5,4(a1)
    80003910:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003914:	00659783          	lh	a5,6(a1)
    80003918:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000391c:	459c                	lw	a5,8(a1)
    8000391e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003920:	03400613          	li	a2,52
    80003924:	05b1                	addi	a1,a1,12
    80003926:	05048513          	addi	a0,s1,80
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	416080e7          	jalr	1046(ra) # 80000d40 <memmove>
    brelse(bp);
    80003932:	854a                	mv	a0,s2
    80003934:	00000097          	auipc	ra,0x0
    80003938:	88e080e7          	jalr	-1906(ra) # 800031c2 <brelse>
    ip->valid = 1;
    8000393c:	4785                	li	a5,1
    8000393e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003940:	04449783          	lh	a5,68(s1)
    80003944:	fbb5                	bnez	a5,800038b8 <ilock+0x24>
      panic("ilock: no type");
    80003946:	00005517          	auipc	a0,0x5
    8000394a:	cda50513          	addi	a0,a0,-806 # 80008620 <syscalls+0x198>
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>

0000000080003956 <iunlock>:
{
    80003956:	1101                	addi	sp,sp,-32
    80003958:	ec06                	sd	ra,24(sp)
    8000395a:	e822                	sd	s0,16(sp)
    8000395c:	e426                	sd	s1,8(sp)
    8000395e:	e04a                	sd	s2,0(sp)
    80003960:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003962:	c905                	beqz	a0,80003992 <iunlock+0x3c>
    80003964:	84aa                	mv	s1,a0
    80003966:	01050913          	addi	s2,a0,16
    8000396a:	854a                	mv	a0,s2
    8000396c:	00001097          	auipc	ra,0x1
    80003970:	c8c080e7          	jalr	-884(ra) # 800045f8 <holdingsleep>
    80003974:	cd19                	beqz	a0,80003992 <iunlock+0x3c>
    80003976:	449c                	lw	a5,8(s1)
    80003978:	00f05d63          	blez	a5,80003992 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000397c:	854a                	mv	a0,s2
    8000397e:	00001097          	auipc	ra,0x1
    80003982:	c36080e7          	jalr	-970(ra) # 800045b4 <releasesleep>
}
    80003986:	60e2                	ld	ra,24(sp)
    80003988:	6442                	ld	s0,16(sp)
    8000398a:	64a2                	ld	s1,8(sp)
    8000398c:	6902                	ld	s2,0(sp)
    8000398e:	6105                	addi	sp,sp,32
    80003990:	8082                	ret
    panic("iunlock");
    80003992:	00005517          	auipc	a0,0x5
    80003996:	c9e50513          	addi	a0,a0,-866 # 80008630 <syscalls+0x1a8>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	ba4080e7          	jalr	-1116(ra) # 8000053e <panic>

00000000800039a2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039a2:	7179                	addi	sp,sp,-48
    800039a4:	f406                	sd	ra,40(sp)
    800039a6:	f022                	sd	s0,32(sp)
    800039a8:	ec26                	sd	s1,24(sp)
    800039aa:	e84a                	sd	s2,16(sp)
    800039ac:	e44e                	sd	s3,8(sp)
    800039ae:	e052                	sd	s4,0(sp)
    800039b0:	1800                	addi	s0,sp,48
    800039b2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039b4:	05050493          	addi	s1,a0,80
    800039b8:	08050913          	addi	s2,a0,128
    800039bc:	a021                	j	800039c4 <itrunc+0x22>
    800039be:	0491                	addi	s1,s1,4
    800039c0:	01248d63          	beq	s1,s2,800039da <itrunc+0x38>
    if(ip->addrs[i]){
    800039c4:	408c                	lw	a1,0(s1)
    800039c6:	dde5                	beqz	a1,800039be <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039c8:	0009a503          	lw	a0,0(s3)
    800039cc:	00000097          	auipc	ra,0x0
    800039d0:	90c080e7          	jalr	-1780(ra) # 800032d8 <bfree>
      ip->addrs[i] = 0;
    800039d4:	0004a023          	sw	zero,0(s1)
    800039d8:	b7dd                	j	800039be <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039da:	0809a583          	lw	a1,128(s3)
    800039de:	e185                	bnez	a1,800039fe <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039e0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039e4:	854e                	mv	a0,s3
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	de4080e7          	jalr	-540(ra) # 800037ca <iupdate>
}
    800039ee:	70a2                	ld	ra,40(sp)
    800039f0:	7402                	ld	s0,32(sp)
    800039f2:	64e2                	ld	s1,24(sp)
    800039f4:	6942                	ld	s2,16(sp)
    800039f6:	69a2                	ld	s3,8(sp)
    800039f8:	6a02                	ld	s4,0(sp)
    800039fa:	6145                	addi	sp,sp,48
    800039fc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039fe:	0009a503          	lw	a0,0(s3)
    80003a02:	fffff097          	auipc	ra,0xfffff
    80003a06:	690080e7          	jalr	1680(ra) # 80003092 <bread>
    80003a0a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a0c:	05850493          	addi	s1,a0,88
    80003a10:	45850913          	addi	s2,a0,1112
    80003a14:	a811                	j	80003a28 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a16:	0009a503          	lw	a0,0(s3)
    80003a1a:	00000097          	auipc	ra,0x0
    80003a1e:	8be080e7          	jalr	-1858(ra) # 800032d8 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a22:	0491                	addi	s1,s1,4
    80003a24:	01248563          	beq	s1,s2,80003a2e <itrunc+0x8c>
      if(a[j])
    80003a28:	408c                	lw	a1,0(s1)
    80003a2a:	dde5                	beqz	a1,80003a22 <itrunc+0x80>
    80003a2c:	b7ed                	j	80003a16 <itrunc+0x74>
    brelse(bp);
    80003a2e:	8552                	mv	a0,s4
    80003a30:	fffff097          	auipc	ra,0xfffff
    80003a34:	792080e7          	jalr	1938(ra) # 800031c2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a38:	0809a583          	lw	a1,128(s3)
    80003a3c:	0009a503          	lw	a0,0(s3)
    80003a40:	00000097          	auipc	ra,0x0
    80003a44:	898080e7          	jalr	-1896(ra) # 800032d8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a48:	0809a023          	sw	zero,128(s3)
    80003a4c:	bf51                	j	800039e0 <itrunc+0x3e>

0000000080003a4e <iput>:
{
    80003a4e:	1101                	addi	sp,sp,-32
    80003a50:	ec06                	sd	ra,24(sp)
    80003a52:	e822                	sd	s0,16(sp)
    80003a54:	e426                	sd	s1,8(sp)
    80003a56:	e04a                	sd	s2,0(sp)
    80003a58:	1000                	addi	s0,sp,32
    80003a5a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a5c:	0001c517          	auipc	a0,0x1c
    80003a60:	d6c50513          	addi	a0,a0,-660 # 8001f7c8 <itable>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	180080e7          	jalr	384(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a6c:	4498                	lw	a4,8(s1)
    80003a6e:	4785                	li	a5,1
    80003a70:	02f70363          	beq	a4,a5,80003a96 <iput+0x48>
  ip->ref--;
    80003a74:	449c                	lw	a5,8(s1)
    80003a76:	37fd                	addiw	a5,a5,-1
    80003a78:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a7a:	0001c517          	auipc	a0,0x1c
    80003a7e:	d4e50513          	addi	a0,a0,-690 # 8001f7c8 <itable>
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	216080e7          	jalr	534(ra) # 80000c98 <release>
}
    80003a8a:	60e2                	ld	ra,24(sp)
    80003a8c:	6442                	ld	s0,16(sp)
    80003a8e:	64a2                	ld	s1,8(sp)
    80003a90:	6902                	ld	s2,0(sp)
    80003a92:	6105                	addi	sp,sp,32
    80003a94:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a96:	40bc                	lw	a5,64(s1)
    80003a98:	dff1                	beqz	a5,80003a74 <iput+0x26>
    80003a9a:	04a49783          	lh	a5,74(s1)
    80003a9e:	fbf9                	bnez	a5,80003a74 <iput+0x26>
    acquiresleep(&ip->lock);
    80003aa0:	01048913          	addi	s2,s1,16
    80003aa4:	854a                	mv	a0,s2
    80003aa6:	00001097          	auipc	ra,0x1
    80003aaa:	ab8080e7          	jalr	-1352(ra) # 8000455e <acquiresleep>
    release(&itable.lock);
    80003aae:	0001c517          	auipc	a0,0x1c
    80003ab2:	d1a50513          	addi	a0,a0,-742 # 8001f7c8 <itable>
    80003ab6:	ffffd097          	auipc	ra,0xffffd
    80003aba:	1e2080e7          	jalr	482(ra) # 80000c98 <release>
    itrunc(ip);
    80003abe:	8526                	mv	a0,s1
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	ee2080e7          	jalr	-286(ra) # 800039a2 <itrunc>
    ip->type = 0;
    80003ac8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003acc:	8526                	mv	a0,s1
    80003ace:	00000097          	auipc	ra,0x0
    80003ad2:	cfc080e7          	jalr	-772(ra) # 800037ca <iupdate>
    ip->valid = 0;
    80003ad6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ada:	854a                	mv	a0,s2
    80003adc:	00001097          	auipc	ra,0x1
    80003ae0:	ad8080e7          	jalr	-1320(ra) # 800045b4 <releasesleep>
    acquire(&itable.lock);
    80003ae4:	0001c517          	auipc	a0,0x1c
    80003ae8:	ce450513          	addi	a0,a0,-796 # 8001f7c8 <itable>
    80003aec:	ffffd097          	auipc	ra,0xffffd
    80003af0:	0f8080e7          	jalr	248(ra) # 80000be4 <acquire>
    80003af4:	b741                	j	80003a74 <iput+0x26>

0000000080003af6 <iunlockput>:
{
    80003af6:	1101                	addi	sp,sp,-32
    80003af8:	ec06                	sd	ra,24(sp)
    80003afa:	e822                	sd	s0,16(sp)
    80003afc:	e426                	sd	s1,8(sp)
    80003afe:	1000                	addi	s0,sp,32
    80003b00:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b02:	00000097          	auipc	ra,0x0
    80003b06:	e54080e7          	jalr	-428(ra) # 80003956 <iunlock>
  iput(ip);
    80003b0a:	8526                	mv	a0,s1
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	f42080e7          	jalr	-190(ra) # 80003a4e <iput>
}
    80003b14:	60e2                	ld	ra,24(sp)
    80003b16:	6442                	ld	s0,16(sp)
    80003b18:	64a2                	ld	s1,8(sp)
    80003b1a:	6105                	addi	sp,sp,32
    80003b1c:	8082                	ret

0000000080003b1e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b1e:	1141                	addi	sp,sp,-16
    80003b20:	e422                	sd	s0,8(sp)
    80003b22:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b24:	411c                	lw	a5,0(a0)
    80003b26:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b28:	415c                	lw	a5,4(a0)
    80003b2a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b2c:	04451783          	lh	a5,68(a0)
    80003b30:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b34:	04a51783          	lh	a5,74(a0)
    80003b38:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b3c:	04c56783          	lwu	a5,76(a0)
    80003b40:	e99c                	sd	a5,16(a1)
}
    80003b42:	6422                	ld	s0,8(sp)
    80003b44:	0141                	addi	sp,sp,16
    80003b46:	8082                	ret

0000000080003b48 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b48:	457c                	lw	a5,76(a0)
    80003b4a:	0ed7e963          	bltu	a5,a3,80003c3c <readi+0xf4>
{
    80003b4e:	7159                	addi	sp,sp,-112
    80003b50:	f486                	sd	ra,104(sp)
    80003b52:	f0a2                	sd	s0,96(sp)
    80003b54:	eca6                	sd	s1,88(sp)
    80003b56:	e8ca                	sd	s2,80(sp)
    80003b58:	e4ce                	sd	s3,72(sp)
    80003b5a:	e0d2                	sd	s4,64(sp)
    80003b5c:	fc56                	sd	s5,56(sp)
    80003b5e:	f85a                	sd	s6,48(sp)
    80003b60:	f45e                	sd	s7,40(sp)
    80003b62:	f062                	sd	s8,32(sp)
    80003b64:	ec66                	sd	s9,24(sp)
    80003b66:	e86a                	sd	s10,16(sp)
    80003b68:	e46e                	sd	s11,8(sp)
    80003b6a:	1880                	addi	s0,sp,112
    80003b6c:	8baa                	mv	s7,a0
    80003b6e:	8c2e                	mv	s8,a1
    80003b70:	8ab2                	mv	s5,a2
    80003b72:	84b6                	mv	s1,a3
    80003b74:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b76:	9f35                	addw	a4,a4,a3
    return 0;
    80003b78:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b7a:	0ad76063          	bltu	a4,a3,80003c1a <readi+0xd2>
  if(off + n > ip->size)
    80003b7e:	00e7f463          	bgeu	a5,a4,80003b86 <readi+0x3e>
    n = ip->size - off;
    80003b82:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b86:	0a0b0963          	beqz	s6,80003c38 <readi+0xf0>
    80003b8a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b8c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b90:	5cfd                	li	s9,-1
    80003b92:	a82d                	j	80003bcc <readi+0x84>
    80003b94:	020a1d93          	slli	s11,s4,0x20
    80003b98:	020ddd93          	srli	s11,s11,0x20
    80003b9c:	05890613          	addi	a2,s2,88
    80003ba0:	86ee                	mv	a3,s11
    80003ba2:	963a                	add	a2,a2,a4
    80003ba4:	85d6                	mv	a1,s5
    80003ba6:	8562                	mv	a0,s8
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	ae4080e7          	jalr	-1308(ra) # 8000268c <either_copyout>
    80003bb0:	05950d63          	beq	a0,s9,80003c0a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bb4:	854a                	mv	a0,s2
    80003bb6:	fffff097          	auipc	ra,0xfffff
    80003bba:	60c080e7          	jalr	1548(ra) # 800031c2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bbe:	013a09bb          	addw	s3,s4,s3
    80003bc2:	009a04bb          	addw	s1,s4,s1
    80003bc6:	9aee                	add	s5,s5,s11
    80003bc8:	0569f763          	bgeu	s3,s6,80003c16 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bcc:	000ba903          	lw	s2,0(s7)
    80003bd0:	00a4d59b          	srliw	a1,s1,0xa
    80003bd4:	855e                	mv	a0,s7
    80003bd6:	00000097          	auipc	ra,0x0
    80003bda:	8b0080e7          	jalr	-1872(ra) # 80003486 <bmap>
    80003bde:	0005059b          	sext.w	a1,a0
    80003be2:	854a                	mv	a0,s2
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	4ae080e7          	jalr	1198(ra) # 80003092 <bread>
    80003bec:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bee:	3ff4f713          	andi	a4,s1,1023
    80003bf2:	40ed07bb          	subw	a5,s10,a4
    80003bf6:	413b06bb          	subw	a3,s6,s3
    80003bfa:	8a3e                	mv	s4,a5
    80003bfc:	2781                	sext.w	a5,a5
    80003bfe:	0006861b          	sext.w	a2,a3
    80003c02:	f8f679e3          	bgeu	a2,a5,80003b94 <readi+0x4c>
    80003c06:	8a36                	mv	s4,a3
    80003c08:	b771                	j	80003b94 <readi+0x4c>
      brelse(bp);
    80003c0a:	854a                	mv	a0,s2
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	5b6080e7          	jalr	1462(ra) # 800031c2 <brelse>
      tot = -1;
    80003c14:	59fd                	li	s3,-1
  }
  return tot;
    80003c16:	0009851b          	sext.w	a0,s3
}
    80003c1a:	70a6                	ld	ra,104(sp)
    80003c1c:	7406                	ld	s0,96(sp)
    80003c1e:	64e6                	ld	s1,88(sp)
    80003c20:	6946                	ld	s2,80(sp)
    80003c22:	69a6                	ld	s3,72(sp)
    80003c24:	6a06                	ld	s4,64(sp)
    80003c26:	7ae2                	ld	s5,56(sp)
    80003c28:	7b42                	ld	s6,48(sp)
    80003c2a:	7ba2                	ld	s7,40(sp)
    80003c2c:	7c02                	ld	s8,32(sp)
    80003c2e:	6ce2                	ld	s9,24(sp)
    80003c30:	6d42                	ld	s10,16(sp)
    80003c32:	6da2                	ld	s11,8(sp)
    80003c34:	6165                	addi	sp,sp,112
    80003c36:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c38:	89da                	mv	s3,s6
    80003c3a:	bff1                	j	80003c16 <readi+0xce>
    return 0;
    80003c3c:	4501                	li	a0,0
}
    80003c3e:	8082                	ret

0000000080003c40 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c40:	457c                	lw	a5,76(a0)
    80003c42:	10d7e863          	bltu	a5,a3,80003d52 <writei+0x112>
{
    80003c46:	7159                	addi	sp,sp,-112
    80003c48:	f486                	sd	ra,104(sp)
    80003c4a:	f0a2                	sd	s0,96(sp)
    80003c4c:	eca6                	sd	s1,88(sp)
    80003c4e:	e8ca                	sd	s2,80(sp)
    80003c50:	e4ce                	sd	s3,72(sp)
    80003c52:	e0d2                	sd	s4,64(sp)
    80003c54:	fc56                	sd	s5,56(sp)
    80003c56:	f85a                	sd	s6,48(sp)
    80003c58:	f45e                	sd	s7,40(sp)
    80003c5a:	f062                	sd	s8,32(sp)
    80003c5c:	ec66                	sd	s9,24(sp)
    80003c5e:	e86a                	sd	s10,16(sp)
    80003c60:	e46e                	sd	s11,8(sp)
    80003c62:	1880                	addi	s0,sp,112
    80003c64:	8b2a                	mv	s6,a0
    80003c66:	8c2e                	mv	s8,a1
    80003c68:	8ab2                	mv	s5,a2
    80003c6a:	8936                	mv	s2,a3
    80003c6c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c6e:	00e687bb          	addw	a5,a3,a4
    80003c72:	0ed7e263          	bltu	a5,a3,80003d56 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c76:	00043737          	lui	a4,0x43
    80003c7a:	0ef76063          	bltu	a4,a5,80003d5a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c7e:	0c0b8863          	beqz	s7,80003d4e <writei+0x10e>
    80003c82:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c84:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c88:	5cfd                	li	s9,-1
    80003c8a:	a091                	j	80003cce <writei+0x8e>
    80003c8c:	02099d93          	slli	s11,s3,0x20
    80003c90:	020ddd93          	srli	s11,s11,0x20
    80003c94:	05848513          	addi	a0,s1,88
    80003c98:	86ee                	mv	a3,s11
    80003c9a:	8656                	mv	a2,s5
    80003c9c:	85e2                	mv	a1,s8
    80003c9e:	953a                	add	a0,a0,a4
    80003ca0:	fffff097          	auipc	ra,0xfffff
    80003ca4:	a42080e7          	jalr	-1470(ra) # 800026e2 <either_copyin>
    80003ca8:	07950263          	beq	a0,s9,80003d0c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cac:	8526                	mv	a0,s1
    80003cae:	00000097          	auipc	ra,0x0
    80003cb2:	790080e7          	jalr	1936(ra) # 8000443e <log_write>
    brelse(bp);
    80003cb6:	8526                	mv	a0,s1
    80003cb8:	fffff097          	auipc	ra,0xfffff
    80003cbc:	50a080e7          	jalr	1290(ra) # 800031c2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cc0:	01498a3b          	addw	s4,s3,s4
    80003cc4:	0129893b          	addw	s2,s3,s2
    80003cc8:	9aee                	add	s5,s5,s11
    80003cca:	057a7663          	bgeu	s4,s7,80003d16 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cce:	000b2483          	lw	s1,0(s6)
    80003cd2:	00a9559b          	srliw	a1,s2,0xa
    80003cd6:	855a                	mv	a0,s6
    80003cd8:	fffff097          	auipc	ra,0xfffff
    80003cdc:	7ae080e7          	jalr	1966(ra) # 80003486 <bmap>
    80003ce0:	0005059b          	sext.w	a1,a0
    80003ce4:	8526                	mv	a0,s1
    80003ce6:	fffff097          	auipc	ra,0xfffff
    80003cea:	3ac080e7          	jalr	940(ra) # 80003092 <bread>
    80003cee:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf0:	3ff97713          	andi	a4,s2,1023
    80003cf4:	40ed07bb          	subw	a5,s10,a4
    80003cf8:	414b86bb          	subw	a3,s7,s4
    80003cfc:	89be                	mv	s3,a5
    80003cfe:	2781                	sext.w	a5,a5
    80003d00:	0006861b          	sext.w	a2,a3
    80003d04:	f8f674e3          	bgeu	a2,a5,80003c8c <writei+0x4c>
    80003d08:	89b6                	mv	s3,a3
    80003d0a:	b749                	j	80003c8c <writei+0x4c>
      brelse(bp);
    80003d0c:	8526                	mv	a0,s1
    80003d0e:	fffff097          	auipc	ra,0xfffff
    80003d12:	4b4080e7          	jalr	1204(ra) # 800031c2 <brelse>
  }

  if(off > ip->size)
    80003d16:	04cb2783          	lw	a5,76(s6)
    80003d1a:	0127f463          	bgeu	a5,s2,80003d22 <writei+0xe2>
    ip->size = off;
    80003d1e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d22:	855a                	mv	a0,s6
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	aa6080e7          	jalr	-1370(ra) # 800037ca <iupdate>

  return tot;
    80003d2c:	000a051b          	sext.w	a0,s4
}
    80003d30:	70a6                	ld	ra,104(sp)
    80003d32:	7406                	ld	s0,96(sp)
    80003d34:	64e6                	ld	s1,88(sp)
    80003d36:	6946                	ld	s2,80(sp)
    80003d38:	69a6                	ld	s3,72(sp)
    80003d3a:	6a06                	ld	s4,64(sp)
    80003d3c:	7ae2                	ld	s5,56(sp)
    80003d3e:	7b42                	ld	s6,48(sp)
    80003d40:	7ba2                	ld	s7,40(sp)
    80003d42:	7c02                	ld	s8,32(sp)
    80003d44:	6ce2                	ld	s9,24(sp)
    80003d46:	6d42                	ld	s10,16(sp)
    80003d48:	6da2                	ld	s11,8(sp)
    80003d4a:	6165                	addi	sp,sp,112
    80003d4c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d4e:	8a5e                	mv	s4,s7
    80003d50:	bfc9                	j	80003d22 <writei+0xe2>
    return -1;
    80003d52:	557d                	li	a0,-1
}
    80003d54:	8082                	ret
    return -1;
    80003d56:	557d                	li	a0,-1
    80003d58:	bfe1                	j	80003d30 <writei+0xf0>
    return -1;
    80003d5a:	557d                	li	a0,-1
    80003d5c:	bfd1                	j	80003d30 <writei+0xf0>

0000000080003d5e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d5e:	1141                	addi	sp,sp,-16
    80003d60:	e406                	sd	ra,8(sp)
    80003d62:	e022                	sd	s0,0(sp)
    80003d64:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d66:	4639                	li	a2,14
    80003d68:	ffffd097          	auipc	ra,0xffffd
    80003d6c:	050080e7          	jalr	80(ra) # 80000db8 <strncmp>
}
    80003d70:	60a2                	ld	ra,8(sp)
    80003d72:	6402                	ld	s0,0(sp)
    80003d74:	0141                	addi	sp,sp,16
    80003d76:	8082                	ret

0000000080003d78 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d78:	7139                	addi	sp,sp,-64
    80003d7a:	fc06                	sd	ra,56(sp)
    80003d7c:	f822                	sd	s0,48(sp)
    80003d7e:	f426                	sd	s1,40(sp)
    80003d80:	f04a                	sd	s2,32(sp)
    80003d82:	ec4e                	sd	s3,24(sp)
    80003d84:	e852                	sd	s4,16(sp)
    80003d86:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d88:	04451703          	lh	a4,68(a0)
    80003d8c:	4785                	li	a5,1
    80003d8e:	00f71a63          	bne	a4,a5,80003da2 <dirlookup+0x2a>
    80003d92:	892a                	mv	s2,a0
    80003d94:	89ae                	mv	s3,a1
    80003d96:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d98:	457c                	lw	a5,76(a0)
    80003d9a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d9c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d9e:	e79d                	bnez	a5,80003dcc <dirlookup+0x54>
    80003da0:	a8a5                	j	80003e18 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003da2:	00005517          	auipc	a0,0x5
    80003da6:	89650513          	addi	a0,a0,-1898 # 80008638 <syscalls+0x1b0>
    80003daa:	ffffc097          	auipc	ra,0xffffc
    80003dae:	794080e7          	jalr	1940(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003db2:	00005517          	auipc	a0,0x5
    80003db6:	89e50513          	addi	a0,a0,-1890 # 80008650 <syscalls+0x1c8>
    80003dba:	ffffc097          	auipc	ra,0xffffc
    80003dbe:	784080e7          	jalr	1924(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc2:	24c1                	addiw	s1,s1,16
    80003dc4:	04c92783          	lw	a5,76(s2)
    80003dc8:	04f4f763          	bgeu	s1,a5,80003e16 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dcc:	4741                	li	a4,16
    80003dce:	86a6                	mv	a3,s1
    80003dd0:	fc040613          	addi	a2,s0,-64
    80003dd4:	4581                	li	a1,0
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	d70080e7          	jalr	-656(ra) # 80003b48 <readi>
    80003de0:	47c1                	li	a5,16
    80003de2:	fcf518e3          	bne	a0,a5,80003db2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003de6:	fc045783          	lhu	a5,-64(s0)
    80003dea:	dfe1                	beqz	a5,80003dc2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dec:	fc240593          	addi	a1,s0,-62
    80003df0:	854e                	mv	a0,s3
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	f6c080e7          	jalr	-148(ra) # 80003d5e <namecmp>
    80003dfa:	f561                	bnez	a0,80003dc2 <dirlookup+0x4a>
      if(poff)
    80003dfc:	000a0463          	beqz	s4,80003e04 <dirlookup+0x8c>
        *poff = off;
    80003e00:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e04:	fc045583          	lhu	a1,-64(s0)
    80003e08:	00092503          	lw	a0,0(s2)
    80003e0c:	fffff097          	auipc	ra,0xfffff
    80003e10:	754080e7          	jalr	1876(ra) # 80003560 <iget>
    80003e14:	a011                	j	80003e18 <dirlookup+0xa0>
  return 0;
    80003e16:	4501                	li	a0,0
}
    80003e18:	70e2                	ld	ra,56(sp)
    80003e1a:	7442                	ld	s0,48(sp)
    80003e1c:	74a2                	ld	s1,40(sp)
    80003e1e:	7902                	ld	s2,32(sp)
    80003e20:	69e2                	ld	s3,24(sp)
    80003e22:	6a42                	ld	s4,16(sp)
    80003e24:	6121                	addi	sp,sp,64
    80003e26:	8082                	ret

0000000080003e28 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e28:	711d                	addi	sp,sp,-96
    80003e2a:	ec86                	sd	ra,88(sp)
    80003e2c:	e8a2                	sd	s0,80(sp)
    80003e2e:	e4a6                	sd	s1,72(sp)
    80003e30:	e0ca                	sd	s2,64(sp)
    80003e32:	fc4e                	sd	s3,56(sp)
    80003e34:	f852                	sd	s4,48(sp)
    80003e36:	f456                	sd	s5,40(sp)
    80003e38:	f05a                	sd	s6,32(sp)
    80003e3a:	ec5e                	sd	s7,24(sp)
    80003e3c:	e862                	sd	s8,16(sp)
    80003e3e:	e466                	sd	s9,8(sp)
    80003e40:	1080                	addi	s0,sp,96
    80003e42:	84aa                	mv	s1,a0
    80003e44:	8b2e                	mv	s6,a1
    80003e46:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e48:	00054703          	lbu	a4,0(a0)
    80003e4c:	02f00793          	li	a5,47
    80003e50:	02f70363          	beq	a4,a5,80003e76 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e54:	ffffe097          	auipc	ra,0xffffe
    80003e58:	c8e080e7          	jalr	-882(ra) # 80001ae2 <myproc>
    80003e5c:	15053503          	ld	a0,336(a0)
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	9f6080e7          	jalr	-1546(ra) # 80003856 <idup>
    80003e68:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e6a:	02f00913          	li	s2,47
  len = path - s;
    80003e6e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e70:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e72:	4c05                	li	s8,1
    80003e74:	a865                	j	80003f2c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e76:	4585                	li	a1,1
    80003e78:	4505                	li	a0,1
    80003e7a:	fffff097          	auipc	ra,0xfffff
    80003e7e:	6e6080e7          	jalr	1766(ra) # 80003560 <iget>
    80003e82:	89aa                	mv	s3,a0
    80003e84:	b7dd                	j	80003e6a <namex+0x42>
      iunlockput(ip);
    80003e86:	854e                	mv	a0,s3
    80003e88:	00000097          	auipc	ra,0x0
    80003e8c:	c6e080e7          	jalr	-914(ra) # 80003af6 <iunlockput>
      return 0;
    80003e90:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e92:	854e                	mv	a0,s3
    80003e94:	60e6                	ld	ra,88(sp)
    80003e96:	6446                	ld	s0,80(sp)
    80003e98:	64a6                	ld	s1,72(sp)
    80003e9a:	6906                	ld	s2,64(sp)
    80003e9c:	79e2                	ld	s3,56(sp)
    80003e9e:	7a42                	ld	s4,48(sp)
    80003ea0:	7aa2                	ld	s5,40(sp)
    80003ea2:	7b02                	ld	s6,32(sp)
    80003ea4:	6be2                	ld	s7,24(sp)
    80003ea6:	6c42                	ld	s8,16(sp)
    80003ea8:	6ca2                	ld	s9,8(sp)
    80003eaa:	6125                	addi	sp,sp,96
    80003eac:	8082                	ret
      iunlock(ip);
    80003eae:	854e                	mv	a0,s3
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	aa6080e7          	jalr	-1370(ra) # 80003956 <iunlock>
      return ip;
    80003eb8:	bfe9                	j	80003e92 <namex+0x6a>
      iunlockput(ip);
    80003eba:	854e                	mv	a0,s3
    80003ebc:	00000097          	auipc	ra,0x0
    80003ec0:	c3a080e7          	jalr	-966(ra) # 80003af6 <iunlockput>
      return 0;
    80003ec4:	89d2                	mv	s3,s4
    80003ec6:	b7f1                	j	80003e92 <namex+0x6a>
  len = path - s;
    80003ec8:	40b48633          	sub	a2,s1,a1
    80003ecc:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ed0:	094cd463          	bge	s9,s4,80003f58 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ed4:	4639                	li	a2,14
    80003ed6:	8556                	mv	a0,s5
    80003ed8:	ffffd097          	auipc	ra,0xffffd
    80003edc:	e68080e7          	jalr	-408(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003ee0:	0004c783          	lbu	a5,0(s1)
    80003ee4:	01279763          	bne	a5,s2,80003ef2 <namex+0xca>
    path++;
    80003ee8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eea:	0004c783          	lbu	a5,0(s1)
    80003eee:	ff278de3          	beq	a5,s2,80003ee8 <namex+0xc0>
    ilock(ip);
    80003ef2:	854e                	mv	a0,s3
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	9a0080e7          	jalr	-1632(ra) # 80003894 <ilock>
    if(ip->type != T_DIR){
    80003efc:	04499783          	lh	a5,68(s3)
    80003f00:	f98793e3          	bne	a5,s8,80003e86 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f04:	000b0563          	beqz	s6,80003f0e <namex+0xe6>
    80003f08:	0004c783          	lbu	a5,0(s1)
    80003f0c:	d3cd                	beqz	a5,80003eae <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f0e:	865e                	mv	a2,s7
    80003f10:	85d6                	mv	a1,s5
    80003f12:	854e                	mv	a0,s3
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	e64080e7          	jalr	-412(ra) # 80003d78 <dirlookup>
    80003f1c:	8a2a                	mv	s4,a0
    80003f1e:	dd51                	beqz	a0,80003eba <namex+0x92>
    iunlockput(ip);
    80003f20:	854e                	mv	a0,s3
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	bd4080e7          	jalr	-1068(ra) # 80003af6 <iunlockput>
    ip = next;
    80003f2a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f2c:	0004c783          	lbu	a5,0(s1)
    80003f30:	05279763          	bne	a5,s2,80003f7e <namex+0x156>
    path++;
    80003f34:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f36:	0004c783          	lbu	a5,0(s1)
    80003f3a:	ff278de3          	beq	a5,s2,80003f34 <namex+0x10c>
  if(*path == 0)
    80003f3e:	c79d                	beqz	a5,80003f6c <namex+0x144>
    path++;
    80003f40:	85a6                	mv	a1,s1
  len = path - s;
    80003f42:	8a5e                	mv	s4,s7
    80003f44:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f46:	01278963          	beq	a5,s2,80003f58 <namex+0x130>
    80003f4a:	dfbd                	beqz	a5,80003ec8 <namex+0xa0>
    path++;
    80003f4c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f4e:	0004c783          	lbu	a5,0(s1)
    80003f52:	ff279ce3          	bne	a5,s2,80003f4a <namex+0x122>
    80003f56:	bf8d                	j	80003ec8 <namex+0xa0>
    memmove(name, s, len);
    80003f58:	2601                	sext.w	a2,a2
    80003f5a:	8556                	mv	a0,s5
    80003f5c:	ffffd097          	auipc	ra,0xffffd
    80003f60:	de4080e7          	jalr	-540(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003f64:	9a56                	add	s4,s4,s5
    80003f66:	000a0023          	sb	zero,0(s4)
    80003f6a:	bf9d                	j	80003ee0 <namex+0xb8>
  if(nameiparent){
    80003f6c:	f20b03e3          	beqz	s6,80003e92 <namex+0x6a>
    iput(ip);
    80003f70:	854e                	mv	a0,s3
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	adc080e7          	jalr	-1316(ra) # 80003a4e <iput>
    return 0;
    80003f7a:	4981                	li	s3,0
    80003f7c:	bf19                	j	80003e92 <namex+0x6a>
  if(*path == 0)
    80003f7e:	d7fd                	beqz	a5,80003f6c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f80:	0004c783          	lbu	a5,0(s1)
    80003f84:	85a6                	mv	a1,s1
    80003f86:	b7d1                	j	80003f4a <namex+0x122>

0000000080003f88 <dirlink>:
{
    80003f88:	7139                	addi	sp,sp,-64
    80003f8a:	fc06                	sd	ra,56(sp)
    80003f8c:	f822                	sd	s0,48(sp)
    80003f8e:	f426                	sd	s1,40(sp)
    80003f90:	f04a                	sd	s2,32(sp)
    80003f92:	ec4e                	sd	s3,24(sp)
    80003f94:	e852                	sd	s4,16(sp)
    80003f96:	0080                	addi	s0,sp,64
    80003f98:	892a                	mv	s2,a0
    80003f9a:	8a2e                	mv	s4,a1
    80003f9c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f9e:	4601                	li	a2,0
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	dd8080e7          	jalr	-552(ra) # 80003d78 <dirlookup>
    80003fa8:	e93d                	bnez	a0,8000401e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003faa:	04c92483          	lw	s1,76(s2)
    80003fae:	c49d                	beqz	s1,80003fdc <dirlink+0x54>
    80003fb0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb2:	4741                	li	a4,16
    80003fb4:	86a6                	mv	a3,s1
    80003fb6:	fc040613          	addi	a2,s0,-64
    80003fba:	4581                	li	a1,0
    80003fbc:	854a                	mv	a0,s2
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	b8a080e7          	jalr	-1142(ra) # 80003b48 <readi>
    80003fc6:	47c1                	li	a5,16
    80003fc8:	06f51163          	bne	a0,a5,8000402a <dirlink+0xa2>
    if(de.inum == 0)
    80003fcc:	fc045783          	lhu	a5,-64(s0)
    80003fd0:	c791                	beqz	a5,80003fdc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fd2:	24c1                	addiw	s1,s1,16
    80003fd4:	04c92783          	lw	a5,76(s2)
    80003fd8:	fcf4ede3          	bltu	s1,a5,80003fb2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fdc:	4639                	li	a2,14
    80003fde:	85d2                	mv	a1,s4
    80003fe0:	fc240513          	addi	a0,s0,-62
    80003fe4:	ffffd097          	auipc	ra,0xffffd
    80003fe8:	e10080e7          	jalr	-496(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003fec:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff0:	4741                	li	a4,16
    80003ff2:	86a6                	mv	a3,s1
    80003ff4:	fc040613          	addi	a2,s0,-64
    80003ff8:	4581                	li	a1,0
    80003ffa:	854a                	mv	a0,s2
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	c44080e7          	jalr	-956(ra) # 80003c40 <writei>
    80004004:	872a                	mv	a4,a0
    80004006:	47c1                	li	a5,16
  return 0;
    80004008:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000400a:	02f71863          	bne	a4,a5,8000403a <dirlink+0xb2>
}
    8000400e:	70e2                	ld	ra,56(sp)
    80004010:	7442                	ld	s0,48(sp)
    80004012:	74a2                	ld	s1,40(sp)
    80004014:	7902                	ld	s2,32(sp)
    80004016:	69e2                	ld	s3,24(sp)
    80004018:	6a42                	ld	s4,16(sp)
    8000401a:	6121                	addi	sp,sp,64
    8000401c:	8082                	ret
    iput(ip);
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	a30080e7          	jalr	-1488(ra) # 80003a4e <iput>
    return -1;
    80004026:	557d                	li	a0,-1
    80004028:	b7dd                	j	8000400e <dirlink+0x86>
      panic("dirlink read");
    8000402a:	00004517          	auipc	a0,0x4
    8000402e:	63650513          	addi	a0,a0,1590 # 80008660 <syscalls+0x1d8>
    80004032:	ffffc097          	auipc	ra,0xffffc
    80004036:	50c080e7          	jalr	1292(ra) # 8000053e <panic>
    panic("dirlink");
    8000403a:	00004517          	auipc	a0,0x4
    8000403e:	73650513          	addi	a0,a0,1846 # 80008770 <syscalls+0x2e8>
    80004042:	ffffc097          	auipc	ra,0xffffc
    80004046:	4fc080e7          	jalr	1276(ra) # 8000053e <panic>

000000008000404a <namei>:

struct inode*
namei(char *path)
{
    8000404a:	1101                	addi	sp,sp,-32
    8000404c:	ec06                	sd	ra,24(sp)
    8000404e:	e822                	sd	s0,16(sp)
    80004050:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004052:	fe040613          	addi	a2,s0,-32
    80004056:	4581                	li	a1,0
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	dd0080e7          	jalr	-560(ra) # 80003e28 <namex>
}
    80004060:	60e2                	ld	ra,24(sp)
    80004062:	6442                	ld	s0,16(sp)
    80004064:	6105                	addi	sp,sp,32
    80004066:	8082                	ret

0000000080004068 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004068:	1141                	addi	sp,sp,-16
    8000406a:	e406                	sd	ra,8(sp)
    8000406c:	e022                	sd	s0,0(sp)
    8000406e:	0800                	addi	s0,sp,16
    80004070:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004072:	4585                	li	a1,1
    80004074:	00000097          	auipc	ra,0x0
    80004078:	db4080e7          	jalr	-588(ra) # 80003e28 <namex>
}
    8000407c:	60a2                	ld	ra,8(sp)
    8000407e:	6402                	ld	s0,0(sp)
    80004080:	0141                	addi	sp,sp,16
    80004082:	8082                	ret

0000000080004084 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004084:	1101                	addi	sp,sp,-32
    80004086:	ec06                	sd	ra,24(sp)
    80004088:	e822                	sd	s0,16(sp)
    8000408a:	e426                	sd	s1,8(sp)
    8000408c:	e04a                	sd	s2,0(sp)
    8000408e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004090:	0001d917          	auipc	s2,0x1d
    80004094:	1e090913          	addi	s2,s2,480 # 80021270 <log>
    80004098:	01892583          	lw	a1,24(s2)
    8000409c:	02892503          	lw	a0,40(s2)
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	ff2080e7          	jalr	-14(ra) # 80003092 <bread>
    800040a8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040aa:	02c92683          	lw	a3,44(s2)
    800040ae:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040b0:	02d05763          	blez	a3,800040de <write_head+0x5a>
    800040b4:	0001d797          	auipc	a5,0x1d
    800040b8:	1ec78793          	addi	a5,a5,492 # 800212a0 <log+0x30>
    800040bc:	05c50713          	addi	a4,a0,92
    800040c0:	36fd                	addiw	a3,a3,-1
    800040c2:	1682                	slli	a3,a3,0x20
    800040c4:	9281                	srli	a3,a3,0x20
    800040c6:	068a                	slli	a3,a3,0x2
    800040c8:	0001d617          	auipc	a2,0x1d
    800040cc:	1dc60613          	addi	a2,a2,476 # 800212a4 <log+0x34>
    800040d0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040d2:	4390                	lw	a2,0(a5)
    800040d4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040d6:	0791                	addi	a5,a5,4
    800040d8:	0711                	addi	a4,a4,4
    800040da:	fed79ce3          	bne	a5,a3,800040d2 <write_head+0x4e>
  }
  bwrite(buf);
    800040de:	8526                	mv	a0,s1
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	0a4080e7          	jalr	164(ra) # 80003184 <bwrite>
  brelse(buf);
    800040e8:	8526                	mv	a0,s1
    800040ea:	fffff097          	auipc	ra,0xfffff
    800040ee:	0d8080e7          	jalr	216(ra) # 800031c2 <brelse>
}
    800040f2:	60e2                	ld	ra,24(sp)
    800040f4:	6442                	ld	s0,16(sp)
    800040f6:	64a2                	ld	s1,8(sp)
    800040f8:	6902                	ld	s2,0(sp)
    800040fa:	6105                	addi	sp,sp,32
    800040fc:	8082                	ret

00000000800040fe <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040fe:	0001d797          	auipc	a5,0x1d
    80004102:	19e7a783          	lw	a5,414(a5) # 8002129c <log+0x2c>
    80004106:	0af05d63          	blez	a5,800041c0 <install_trans+0xc2>
{
    8000410a:	7139                	addi	sp,sp,-64
    8000410c:	fc06                	sd	ra,56(sp)
    8000410e:	f822                	sd	s0,48(sp)
    80004110:	f426                	sd	s1,40(sp)
    80004112:	f04a                	sd	s2,32(sp)
    80004114:	ec4e                	sd	s3,24(sp)
    80004116:	e852                	sd	s4,16(sp)
    80004118:	e456                	sd	s5,8(sp)
    8000411a:	e05a                	sd	s6,0(sp)
    8000411c:	0080                	addi	s0,sp,64
    8000411e:	8b2a                	mv	s6,a0
    80004120:	0001da97          	auipc	s5,0x1d
    80004124:	180a8a93          	addi	s5,s5,384 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004128:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000412a:	0001d997          	auipc	s3,0x1d
    8000412e:	14698993          	addi	s3,s3,326 # 80021270 <log>
    80004132:	a035                	j	8000415e <install_trans+0x60>
      bunpin(dbuf);
    80004134:	8526                	mv	a0,s1
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	166080e7          	jalr	358(ra) # 8000329c <bunpin>
    brelse(lbuf);
    8000413e:	854a                	mv	a0,s2
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	082080e7          	jalr	130(ra) # 800031c2 <brelse>
    brelse(dbuf);
    80004148:	8526                	mv	a0,s1
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	078080e7          	jalr	120(ra) # 800031c2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004152:	2a05                	addiw	s4,s4,1
    80004154:	0a91                	addi	s5,s5,4
    80004156:	02c9a783          	lw	a5,44(s3)
    8000415a:	04fa5963          	bge	s4,a5,800041ac <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000415e:	0189a583          	lw	a1,24(s3)
    80004162:	014585bb          	addw	a1,a1,s4
    80004166:	2585                	addiw	a1,a1,1
    80004168:	0289a503          	lw	a0,40(s3)
    8000416c:	fffff097          	auipc	ra,0xfffff
    80004170:	f26080e7          	jalr	-218(ra) # 80003092 <bread>
    80004174:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004176:	000aa583          	lw	a1,0(s5)
    8000417a:	0289a503          	lw	a0,40(s3)
    8000417e:	fffff097          	auipc	ra,0xfffff
    80004182:	f14080e7          	jalr	-236(ra) # 80003092 <bread>
    80004186:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004188:	40000613          	li	a2,1024
    8000418c:	05890593          	addi	a1,s2,88
    80004190:	05850513          	addi	a0,a0,88
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	bac080e7          	jalr	-1108(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000419c:	8526                	mv	a0,s1
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	fe6080e7          	jalr	-26(ra) # 80003184 <bwrite>
    if(recovering == 0)
    800041a6:	f80b1ce3          	bnez	s6,8000413e <install_trans+0x40>
    800041aa:	b769                	j	80004134 <install_trans+0x36>
}
    800041ac:	70e2                	ld	ra,56(sp)
    800041ae:	7442                	ld	s0,48(sp)
    800041b0:	74a2                	ld	s1,40(sp)
    800041b2:	7902                	ld	s2,32(sp)
    800041b4:	69e2                	ld	s3,24(sp)
    800041b6:	6a42                	ld	s4,16(sp)
    800041b8:	6aa2                	ld	s5,8(sp)
    800041ba:	6b02                	ld	s6,0(sp)
    800041bc:	6121                	addi	sp,sp,64
    800041be:	8082                	ret
    800041c0:	8082                	ret

00000000800041c2 <initlog>:
{
    800041c2:	7179                	addi	sp,sp,-48
    800041c4:	f406                	sd	ra,40(sp)
    800041c6:	f022                	sd	s0,32(sp)
    800041c8:	ec26                	sd	s1,24(sp)
    800041ca:	e84a                	sd	s2,16(sp)
    800041cc:	e44e                	sd	s3,8(sp)
    800041ce:	1800                	addi	s0,sp,48
    800041d0:	892a                	mv	s2,a0
    800041d2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041d4:	0001d497          	auipc	s1,0x1d
    800041d8:	09c48493          	addi	s1,s1,156 # 80021270 <log>
    800041dc:	00004597          	auipc	a1,0x4
    800041e0:	49458593          	addi	a1,a1,1172 # 80008670 <syscalls+0x1e8>
    800041e4:	8526                	mv	a0,s1
    800041e6:	ffffd097          	auipc	ra,0xffffd
    800041ea:	96e080e7          	jalr	-1682(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800041ee:	0149a583          	lw	a1,20(s3)
    800041f2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041f4:	0109a783          	lw	a5,16(s3)
    800041f8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041fa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041fe:	854a                	mv	a0,s2
    80004200:	fffff097          	auipc	ra,0xfffff
    80004204:	e92080e7          	jalr	-366(ra) # 80003092 <bread>
  log.lh.n = lh->n;
    80004208:	4d3c                	lw	a5,88(a0)
    8000420a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000420c:	02f05563          	blez	a5,80004236 <initlog+0x74>
    80004210:	05c50713          	addi	a4,a0,92
    80004214:	0001d697          	auipc	a3,0x1d
    80004218:	08c68693          	addi	a3,a3,140 # 800212a0 <log+0x30>
    8000421c:	37fd                	addiw	a5,a5,-1
    8000421e:	1782                	slli	a5,a5,0x20
    80004220:	9381                	srli	a5,a5,0x20
    80004222:	078a                	slli	a5,a5,0x2
    80004224:	06050613          	addi	a2,a0,96
    80004228:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000422a:	4310                	lw	a2,0(a4)
    8000422c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000422e:	0711                	addi	a4,a4,4
    80004230:	0691                	addi	a3,a3,4
    80004232:	fef71ce3          	bne	a4,a5,8000422a <initlog+0x68>
  brelse(buf);
    80004236:	fffff097          	auipc	ra,0xfffff
    8000423a:	f8c080e7          	jalr	-116(ra) # 800031c2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000423e:	4505                	li	a0,1
    80004240:	00000097          	auipc	ra,0x0
    80004244:	ebe080e7          	jalr	-322(ra) # 800040fe <install_trans>
  log.lh.n = 0;
    80004248:	0001d797          	auipc	a5,0x1d
    8000424c:	0407aa23          	sw	zero,84(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004250:	00000097          	auipc	ra,0x0
    80004254:	e34080e7          	jalr	-460(ra) # 80004084 <write_head>
}
    80004258:	70a2                	ld	ra,40(sp)
    8000425a:	7402                	ld	s0,32(sp)
    8000425c:	64e2                	ld	s1,24(sp)
    8000425e:	6942                	ld	s2,16(sp)
    80004260:	69a2                	ld	s3,8(sp)
    80004262:	6145                	addi	sp,sp,48
    80004264:	8082                	ret

0000000080004266 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004266:	1101                	addi	sp,sp,-32
    80004268:	ec06                	sd	ra,24(sp)
    8000426a:	e822                	sd	s0,16(sp)
    8000426c:	e426                	sd	s1,8(sp)
    8000426e:	e04a                	sd	s2,0(sp)
    80004270:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004272:	0001d517          	auipc	a0,0x1d
    80004276:	ffe50513          	addi	a0,a0,-2 # 80021270 <log>
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	96a080e7          	jalr	-1686(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004282:	0001d497          	auipc	s1,0x1d
    80004286:	fee48493          	addi	s1,s1,-18 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000428a:	4979                	li	s2,30
    8000428c:	a039                	j	8000429a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000428e:	85a6                	mv	a1,s1
    80004290:	8526                	mv	a0,s1
    80004292:	ffffe097          	auipc	ra,0xffffe
    80004296:	f0c080e7          	jalr	-244(ra) # 8000219e <sleep>
    if(log.committing){
    8000429a:	50dc                	lw	a5,36(s1)
    8000429c:	fbed                	bnez	a5,8000428e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000429e:	509c                	lw	a5,32(s1)
    800042a0:	0017871b          	addiw	a4,a5,1
    800042a4:	0007069b          	sext.w	a3,a4
    800042a8:	0027179b          	slliw	a5,a4,0x2
    800042ac:	9fb9                	addw	a5,a5,a4
    800042ae:	0017979b          	slliw	a5,a5,0x1
    800042b2:	54d8                	lw	a4,44(s1)
    800042b4:	9fb9                	addw	a5,a5,a4
    800042b6:	00f95963          	bge	s2,a5,800042c8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042ba:	85a6                	mv	a1,s1
    800042bc:	8526                	mv	a0,s1
    800042be:	ffffe097          	auipc	ra,0xffffe
    800042c2:	ee0080e7          	jalr	-288(ra) # 8000219e <sleep>
    800042c6:	bfd1                	j	8000429a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042c8:	0001d517          	auipc	a0,0x1d
    800042cc:	fa850513          	addi	a0,a0,-88 # 80021270 <log>
    800042d0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	9c6080e7          	jalr	-1594(ra) # 80000c98 <release>
      break;
    }
  }
}
    800042da:	60e2                	ld	ra,24(sp)
    800042dc:	6442                	ld	s0,16(sp)
    800042de:	64a2                	ld	s1,8(sp)
    800042e0:	6902                	ld	s2,0(sp)
    800042e2:	6105                	addi	sp,sp,32
    800042e4:	8082                	ret

00000000800042e6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042e6:	7139                	addi	sp,sp,-64
    800042e8:	fc06                	sd	ra,56(sp)
    800042ea:	f822                	sd	s0,48(sp)
    800042ec:	f426                	sd	s1,40(sp)
    800042ee:	f04a                	sd	s2,32(sp)
    800042f0:	ec4e                	sd	s3,24(sp)
    800042f2:	e852                	sd	s4,16(sp)
    800042f4:	e456                	sd	s5,8(sp)
    800042f6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042f8:	0001d497          	auipc	s1,0x1d
    800042fc:	f7848493          	addi	s1,s1,-136 # 80021270 <log>
    80004300:	8526                	mv	a0,s1
    80004302:	ffffd097          	auipc	ra,0xffffd
    80004306:	8e2080e7          	jalr	-1822(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000430a:	509c                	lw	a5,32(s1)
    8000430c:	37fd                	addiw	a5,a5,-1
    8000430e:	0007891b          	sext.w	s2,a5
    80004312:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004314:	50dc                	lw	a5,36(s1)
    80004316:	efb9                	bnez	a5,80004374 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004318:	06091663          	bnez	s2,80004384 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000431c:	0001d497          	auipc	s1,0x1d
    80004320:	f5448493          	addi	s1,s1,-172 # 80021270 <log>
    80004324:	4785                	li	a5,1
    80004326:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004328:	8526                	mv	a0,s1
    8000432a:	ffffd097          	auipc	ra,0xffffd
    8000432e:	96e080e7          	jalr	-1682(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004332:	54dc                	lw	a5,44(s1)
    80004334:	06f04763          	bgtz	a5,800043a2 <end_op+0xbc>
    acquire(&log.lock);
    80004338:	0001d497          	auipc	s1,0x1d
    8000433c:	f3848493          	addi	s1,s1,-200 # 80021270 <log>
    80004340:	8526                	mv	a0,s1
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	8a2080e7          	jalr	-1886(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000434a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000434e:	8526                	mv	a0,s1
    80004350:	ffffe097          	auipc	ra,0xffffe
    80004354:	0ce080e7          	jalr	206(ra) # 8000241e <wakeup>
    release(&log.lock);
    80004358:	8526                	mv	a0,s1
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	93e080e7          	jalr	-1730(ra) # 80000c98 <release>
}
    80004362:	70e2                	ld	ra,56(sp)
    80004364:	7442                	ld	s0,48(sp)
    80004366:	74a2                	ld	s1,40(sp)
    80004368:	7902                	ld	s2,32(sp)
    8000436a:	69e2                	ld	s3,24(sp)
    8000436c:	6a42                	ld	s4,16(sp)
    8000436e:	6aa2                	ld	s5,8(sp)
    80004370:	6121                	addi	sp,sp,64
    80004372:	8082                	ret
    panic("log.committing");
    80004374:	00004517          	auipc	a0,0x4
    80004378:	30450513          	addi	a0,a0,772 # 80008678 <syscalls+0x1f0>
    8000437c:	ffffc097          	auipc	ra,0xffffc
    80004380:	1c2080e7          	jalr	450(ra) # 8000053e <panic>
    wakeup(&log);
    80004384:	0001d497          	auipc	s1,0x1d
    80004388:	eec48493          	addi	s1,s1,-276 # 80021270 <log>
    8000438c:	8526                	mv	a0,s1
    8000438e:	ffffe097          	auipc	ra,0xffffe
    80004392:	090080e7          	jalr	144(ra) # 8000241e <wakeup>
  release(&log.lock);
    80004396:	8526                	mv	a0,s1
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	900080e7          	jalr	-1792(ra) # 80000c98 <release>
  if(do_commit){
    800043a0:	b7c9                	j	80004362 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a2:	0001da97          	auipc	s5,0x1d
    800043a6:	efea8a93          	addi	s5,s5,-258 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043aa:	0001da17          	auipc	s4,0x1d
    800043ae:	ec6a0a13          	addi	s4,s4,-314 # 80021270 <log>
    800043b2:	018a2583          	lw	a1,24(s4)
    800043b6:	012585bb          	addw	a1,a1,s2
    800043ba:	2585                	addiw	a1,a1,1
    800043bc:	028a2503          	lw	a0,40(s4)
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	cd2080e7          	jalr	-814(ra) # 80003092 <bread>
    800043c8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043ca:	000aa583          	lw	a1,0(s5)
    800043ce:	028a2503          	lw	a0,40(s4)
    800043d2:	fffff097          	auipc	ra,0xfffff
    800043d6:	cc0080e7          	jalr	-832(ra) # 80003092 <bread>
    800043da:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043dc:	40000613          	li	a2,1024
    800043e0:	05850593          	addi	a1,a0,88
    800043e4:	05848513          	addi	a0,s1,88
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	958080e7          	jalr	-1704(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800043f0:	8526                	mv	a0,s1
    800043f2:	fffff097          	auipc	ra,0xfffff
    800043f6:	d92080e7          	jalr	-622(ra) # 80003184 <bwrite>
    brelse(from);
    800043fa:	854e                	mv	a0,s3
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	dc6080e7          	jalr	-570(ra) # 800031c2 <brelse>
    brelse(to);
    80004404:	8526                	mv	a0,s1
    80004406:	fffff097          	auipc	ra,0xfffff
    8000440a:	dbc080e7          	jalr	-580(ra) # 800031c2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000440e:	2905                	addiw	s2,s2,1
    80004410:	0a91                	addi	s5,s5,4
    80004412:	02ca2783          	lw	a5,44(s4)
    80004416:	f8f94ee3          	blt	s2,a5,800043b2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000441a:	00000097          	auipc	ra,0x0
    8000441e:	c6a080e7          	jalr	-918(ra) # 80004084 <write_head>
    install_trans(0); // Now install writes to home locations
    80004422:	4501                	li	a0,0
    80004424:	00000097          	auipc	ra,0x0
    80004428:	cda080e7          	jalr	-806(ra) # 800040fe <install_trans>
    log.lh.n = 0;
    8000442c:	0001d797          	auipc	a5,0x1d
    80004430:	e607a823          	sw	zero,-400(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004434:	00000097          	auipc	ra,0x0
    80004438:	c50080e7          	jalr	-944(ra) # 80004084 <write_head>
    8000443c:	bdf5                	j	80004338 <end_op+0x52>

000000008000443e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000443e:	1101                	addi	sp,sp,-32
    80004440:	ec06                	sd	ra,24(sp)
    80004442:	e822                	sd	s0,16(sp)
    80004444:	e426                	sd	s1,8(sp)
    80004446:	e04a                	sd	s2,0(sp)
    80004448:	1000                	addi	s0,sp,32
    8000444a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000444c:	0001d917          	auipc	s2,0x1d
    80004450:	e2490913          	addi	s2,s2,-476 # 80021270 <log>
    80004454:	854a                	mv	a0,s2
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	78e080e7          	jalr	1934(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000445e:	02c92603          	lw	a2,44(s2)
    80004462:	47f5                	li	a5,29
    80004464:	06c7c563          	blt	a5,a2,800044ce <log_write+0x90>
    80004468:	0001d797          	auipc	a5,0x1d
    8000446c:	e247a783          	lw	a5,-476(a5) # 8002128c <log+0x1c>
    80004470:	37fd                	addiw	a5,a5,-1
    80004472:	04f65e63          	bge	a2,a5,800044ce <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004476:	0001d797          	auipc	a5,0x1d
    8000447a:	e1a7a783          	lw	a5,-486(a5) # 80021290 <log+0x20>
    8000447e:	06f05063          	blez	a5,800044de <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004482:	4781                	li	a5,0
    80004484:	06c05563          	blez	a2,800044ee <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004488:	44cc                	lw	a1,12(s1)
    8000448a:	0001d717          	auipc	a4,0x1d
    8000448e:	e1670713          	addi	a4,a4,-490 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004492:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004494:	4314                	lw	a3,0(a4)
    80004496:	04b68c63          	beq	a3,a1,800044ee <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000449a:	2785                	addiw	a5,a5,1
    8000449c:	0711                	addi	a4,a4,4
    8000449e:	fef61be3          	bne	a2,a5,80004494 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044a2:	0621                	addi	a2,a2,8
    800044a4:	060a                	slli	a2,a2,0x2
    800044a6:	0001d797          	auipc	a5,0x1d
    800044aa:	dca78793          	addi	a5,a5,-566 # 80021270 <log>
    800044ae:	963e                	add	a2,a2,a5
    800044b0:	44dc                	lw	a5,12(s1)
    800044b2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044b4:	8526                	mv	a0,s1
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	daa080e7          	jalr	-598(ra) # 80003260 <bpin>
    log.lh.n++;
    800044be:	0001d717          	auipc	a4,0x1d
    800044c2:	db270713          	addi	a4,a4,-590 # 80021270 <log>
    800044c6:	575c                	lw	a5,44(a4)
    800044c8:	2785                	addiw	a5,a5,1
    800044ca:	d75c                	sw	a5,44(a4)
    800044cc:	a835                	j	80004508 <log_write+0xca>
    panic("too big a transaction");
    800044ce:	00004517          	auipc	a0,0x4
    800044d2:	1ba50513          	addi	a0,a0,442 # 80008688 <syscalls+0x200>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	068080e7          	jalr	104(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800044de:	00004517          	auipc	a0,0x4
    800044e2:	1c250513          	addi	a0,a0,450 # 800086a0 <syscalls+0x218>
    800044e6:	ffffc097          	auipc	ra,0xffffc
    800044ea:	058080e7          	jalr	88(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800044ee:	00878713          	addi	a4,a5,8
    800044f2:	00271693          	slli	a3,a4,0x2
    800044f6:	0001d717          	auipc	a4,0x1d
    800044fa:	d7a70713          	addi	a4,a4,-646 # 80021270 <log>
    800044fe:	9736                	add	a4,a4,a3
    80004500:	44d4                	lw	a3,12(s1)
    80004502:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004504:	faf608e3          	beq	a2,a5,800044b4 <log_write+0x76>
  }
  release(&log.lock);
    80004508:	0001d517          	auipc	a0,0x1d
    8000450c:	d6850513          	addi	a0,a0,-664 # 80021270 <log>
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	788080e7          	jalr	1928(ra) # 80000c98 <release>
}
    80004518:	60e2                	ld	ra,24(sp)
    8000451a:	6442                	ld	s0,16(sp)
    8000451c:	64a2                	ld	s1,8(sp)
    8000451e:	6902                	ld	s2,0(sp)
    80004520:	6105                	addi	sp,sp,32
    80004522:	8082                	ret

0000000080004524 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004524:	1101                	addi	sp,sp,-32
    80004526:	ec06                	sd	ra,24(sp)
    80004528:	e822                	sd	s0,16(sp)
    8000452a:	e426                	sd	s1,8(sp)
    8000452c:	e04a                	sd	s2,0(sp)
    8000452e:	1000                	addi	s0,sp,32
    80004530:	84aa                	mv	s1,a0
    80004532:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004534:	00004597          	auipc	a1,0x4
    80004538:	18c58593          	addi	a1,a1,396 # 800086c0 <syscalls+0x238>
    8000453c:	0521                	addi	a0,a0,8
    8000453e:	ffffc097          	auipc	ra,0xffffc
    80004542:	616080e7          	jalr	1558(ra) # 80000b54 <initlock>
  lk->name = name;
    80004546:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000454a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000454e:	0204a423          	sw	zero,40(s1)
}
    80004552:	60e2                	ld	ra,24(sp)
    80004554:	6442                	ld	s0,16(sp)
    80004556:	64a2                	ld	s1,8(sp)
    80004558:	6902                	ld	s2,0(sp)
    8000455a:	6105                	addi	sp,sp,32
    8000455c:	8082                	ret

000000008000455e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000455e:	1101                	addi	sp,sp,-32
    80004560:	ec06                	sd	ra,24(sp)
    80004562:	e822                	sd	s0,16(sp)
    80004564:	e426                	sd	s1,8(sp)
    80004566:	e04a                	sd	s2,0(sp)
    80004568:	1000                	addi	s0,sp,32
    8000456a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000456c:	00850913          	addi	s2,a0,8
    80004570:	854a                	mv	a0,s2
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	672080e7          	jalr	1650(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000457a:	409c                	lw	a5,0(s1)
    8000457c:	cb89                	beqz	a5,8000458e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000457e:	85ca                	mv	a1,s2
    80004580:	8526                	mv	a0,s1
    80004582:	ffffe097          	auipc	ra,0xffffe
    80004586:	c1c080e7          	jalr	-996(ra) # 8000219e <sleep>
  while (lk->locked) {
    8000458a:	409c                	lw	a5,0(s1)
    8000458c:	fbed                	bnez	a5,8000457e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000458e:	4785                	li	a5,1
    80004590:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004592:	ffffd097          	auipc	ra,0xffffd
    80004596:	550080e7          	jalr	1360(ra) # 80001ae2 <myproc>
    8000459a:	591c                	lw	a5,48(a0)
    8000459c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000459e:	854a                	mv	a0,s2
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	6f8080e7          	jalr	1784(ra) # 80000c98 <release>
}
    800045a8:	60e2                	ld	ra,24(sp)
    800045aa:	6442                	ld	s0,16(sp)
    800045ac:	64a2                	ld	s1,8(sp)
    800045ae:	6902                	ld	s2,0(sp)
    800045b0:	6105                	addi	sp,sp,32
    800045b2:	8082                	ret

00000000800045b4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045b4:	1101                	addi	sp,sp,-32
    800045b6:	ec06                	sd	ra,24(sp)
    800045b8:	e822                	sd	s0,16(sp)
    800045ba:	e426                	sd	s1,8(sp)
    800045bc:	e04a                	sd	s2,0(sp)
    800045be:	1000                	addi	s0,sp,32
    800045c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045c2:	00850913          	addi	s2,a0,8
    800045c6:	854a                	mv	a0,s2
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	61c080e7          	jalr	1564(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800045d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045d4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045d8:	8526                	mv	a0,s1
    800045da:	ffffe097          	auipc	ra,0xffffe
    800045de:	e44080e7          	jalr	-444(ra) # 8000241e <wakeup>
  release(&lk->lk);
    800045e2:	854a                	mv	a0,s2
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	6b4080e7          	jalr	1716(ra) # 80000c98 <release>
}
    800045ec:	60e2                	ld	ra,24(sp)
    800045ee:	6442                	ld	s0,16(sp)
    800045f0:	64a2                	ld	s1,8(sp)
    800045f2:	6902                	ld	s2,0(sp)
    800045f4:	6105                	addi	sp,sp,32
    800045f6:	8082                	ret

00000000800045f8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045f8:	7179                	addi	sp,sp,-48
    800045fa:	f406                	sd	ra,40(sp)
    800045fc:	f022                	sd	s0,32(sp)
    800045fe:	ec26                	sd	s1,24(sp)
    80004600:	e84a                	sd	s2,16(sp)
    80004602:	e44e                	sd	s3,8(sp)
    80004604:	1800                	addi	s0,sp,48
    80004606:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004608:	00850913          	addi	s2,a0,8
    8000460c:	854a                	mv	a0,s2
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	5d6080e7          	jalr	1494(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004616:	409c                	lw	a5,0(s1)
    80004618:	ef99                	bnez	a5,80004636 <holdingsleep+0x3e>
    8000461a:	4481                	li	s1,0
  release(&lk->lk);
    8000461c:	854a                	mv	a0,s2
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	67a080e7          	jalr	1658(ra) # 80000c98 <release>
  return r;
}
    80004626:	8526                	mv	a0,s1
    80004628:	70a2                	ld	ra,40(sp)
    8000462a:	7402                	ld	s0,32(sp)
    8000462c:	64e2                	ld	s1,24(sp)
    8000462e:	6942                	ld	s2,16(sp)
    80004630:	69a2                	ld	s3,8(sp)
    80004632:	6145                	addi	sp,sp,48
    80004634:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004636:	0284a983          	lw	s3,40(s1)
    8000463a:	ffffd097          	auipc	ra,0xffffd
    8000463e:	4a8080e7          	jalr	1192(ra) # 80001ae2 <myproc>
    80004642:	5904                	lw	s1,48(a0)
    80004644:	413484b3          	sub	s1,s1,s3
    80004648:	0014b493          	seqz	s1,s1
    8000464c:	bfc1                	j	8000461c <holdingsleep+0x24>

000000008000464e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000464e:	1141                	addi	sp,sp,-16
    80004650:	e406                	sd	ra,8(sp)
    80004652:	e022                	sd	s0,0(sp)
    80004654:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004656:	00004597          	auipc	a1,0x4
    8000465a:	07a58593          	addi	a1,a1,122 # 800086d0 <syscalls+0x248>
    8000465e:	0001d517          	auipc	a0,0x1d
    80004662:	d5a50513          	addi	a0,a0,-678 # 800213b8 <ftable>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	4ee080e7          	jalr	1262(ra) # 80000b54 <initlock>
}
    8000466e:	60a2                	ld	ra,8(sp)
    80004670:	6402                	ld	s0,0(sp)
    80004672:	0141                	addi	sp,sp,16
    80004674:	8082                	ret

0000000080004676 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004676:	1101                	addi	sp,sp,-32
    80004678:	ec06                	sd	ra,24(sp)
    8000467a:	e822                	sd	s0,16(sp)
    8000467c:	e426                	sd	s1,8(sp)
    8000467e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004680:	0001d517          	auipc	a0,0x1d
    80004684:	d3850513          	addi	a0,a0,-712 # 800213b8 <ftable>
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	55c080e7          	jalr	1372(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004690:	0001d497          	auipc	s1,0x1d
    80004694:	d4048493          	addi	s1,s1,-704 # 800213d0 <ftable+0x18>
    80004698:	0001e717          	auipc	a4,0x1e
    8000469c:	cd870713          	addi	a4,a4,-808 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800046a0:	40dc                	lw	a5,4(s1)
    800046a2:	cf99                	beqz	a5,800046c0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046a4:	02848493          	addi	s1,s1,40
    800046a8:	fee49ce3          	bne	s1,a4,800046a0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046ac:	0001d517          	auipc	a0,0x1d
    800046b0:	d0c50513          	addi	a0,a0,-756 # 800213b8 <ftable>
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	5e4080e7          	jalr	1508(ra) # 80000c98 <release>
  return 0;
    800046bc:	4481                	li	s1,0
    800046be:	a819                	j	800046d4 <filealloc+0x5e>
      f->ref = 1;
    800046c0:	4785                	li	a5,1
    800046c2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046c4:	0001d517          	auipc	a0,0x1d
    800046c8:	cf450513          	addi	a0,a0,-780 # 800213b8 <ftable>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	5cc080e7          	jalr	1484(ra) # 80000c98 <release>
}
    800046d4:	8526                	mv	a0,s1
    800046d6:	60e2                	ld	ra,24(sp)
    800046d8:	6442                	ld	s0,16(sp)
    800046da:	64a2                	ld	s1,8(sp)
    800046dc:	6105                	addi	sp,sp,32
    800046de:	8082                	ret

00000000800046e0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046e0:	1101                	addi	sp,sp,-32
    800046e2:	ec06                	sd	ra,24(sp)
    800046e4:	e822                	sd	s0,16(sp)
    800046e6:	e426                	sd	s1,8(sp)
    800046e8:	1000                	addi	s0,sp,32
    800046ea:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046ec:	0001d517          	auipc	a0,0x1d
    800046f0:	ccc50513          	addi	a0,a0,-820 # 800213b8 <ftable>
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	4f0080e7          	jalr	1264(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800046fc:	40dc                	lw	a5,4(s1)
    800046fe:	02f05263          	blez	a5,80004722 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004702:	2785                	addiw	a5,a5,1
    80004704:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004706:	0001d517          	auipc	a0,0x1d
    8000470a:	cb250513          	addi	a0,a0,-846 # 800213b8 <ftable>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	58a080e7          	jalr	1418(ra) # 80000c98 <release>
  return f;
}
    80004716:	8526                	mv	a0,s1
    80004718:	60e2                	ld	ra,24(sp)
    8000471a:	6442                	ld	s0,16(sp)
    8000471c:	64a2                	ld	s1,8(sp)
    8000471e:	6105                	addi	sp,sp,32
    80004720:	8082                	ret
    panic("filedup");
    80004722:	00004517          	auipc	a0,0x4
    80004726:	fb650513          	addi	a0,a0,-74 # 800086d8 <syscalls+0x250>
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	e14080e7          	jalr	-492(ra) # 8000053e <panic>

0000000080004732 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004732:	7139                	addi	sp,sp,-64
    80004734:	fc06                	sd	ra,56(sp)
    80004736:	f822                	sd	s0,48(sp)
    80004738:	f426                	sd	s1,40(sp)
    8000473a:	f04a                	sd	s2,32(sp)
    8000473c:	ec4e                	sd	s3,24(sp)
    8000473e:	e852                	sd	s4,16(sp)
    80004740:	e456                	sd	s5,8(sp)
    80004742:	0080                	addi	s0,sp,64
    80004744:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004746:	0001d517          	auipc	a0,0x1d
    8000474a:	c7250513          	addi	a0,a0,-910 # 800213b8 <ftable>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	496080e7          	jalr	1174(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004756:	40dc                	lw	a5,4(s1)
    80004758:	06f05163          	blez	a5,800047ba <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000475c:	37fd                	addiw	a5,a5,-1
    8000475e:	0007871b          	sext.w	a4,a5
    80004762:	c0dc                	sw	a5,4(s1)
    80004764:	06e04363          	bgtz	a4,800047ca <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004768:	0004a903          	lw	s2,0(s1)
    8000476c:	0094ca83          	lbu	s5,9(s1)
    80004770:	0104ba03          	ld	s4,16(s1)
    80004774:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004778:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000477c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004780:	0001d517          	auipc	a0,0x1d
    80004784:	c3850513          	addi	a0,a0,-968 # 800213b8 <ftable>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	510080e7          	jalr	1296(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004790:	4785                	li	a5,1
    80004792:	04f90d63          	beq	s2,a5,800047ec <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004796:	3979                	addiw	s2,s2,-2
    80004798:	4785                	li	a5,1
    8000479a:	0527e063          	bltu	a5,s2,800047da <fileclose+0xa8>
    begin_op();
    8000479e:	00000097          	auipc	ra,0x0
    800047a2:	ac8080e7          	jalr	-1336(ra) # 80004266 <begin_op>
    iput(ff.ip);
    800047a6:	854e                	mv	a0,s3
    800047a8:	fffff097          	auipc	ra,0xfffff
    800047ac:	2a6080e7          	jalr	678(ra) # 80003a4e <iput>
    end_op();
    800047b0:	00000097          	auipc	ra,0x0
    800047b4:	b36080e7          	jalr	-1226(ra) # 800042e6 <end_op>
    800047b8:	a00d                	j	800047da <fileclose+0xa8>
    panic("fileclose");
    800047ba:	00004517          	auipc	a0,0x4
    800047be:	f2650513          	addi	a0,a0,-218 # 800086e0 <syscalls+0x258>
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	d7c080e7          	jalr	-644(ra) # 8000053e <panic>
    release(&ftable.lock);
    800047ca:	0001d517          	auipc	a0,0x1d
    800047ce:	bee50513          	addi	a0,a0,-1042 # 800213b8 <ftable>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	4c6080e7          	jalr	1222(ra) # 80000c98 <release>
  }
}
    800047da:	70e2                	ld	ra,56(sp)
    800047dc:	7442                	ld	s0,48(sp)
    800047de:	74a2                	ld	s1,40(sp)
    800047e0:	7902                	ld	s2,32(sp)
    800047e2:	69e2                	ld	s3,24(sp)
    800047e4:	6a42                	ld	s4,16(sp)
    800047e6:	6aa2                	ld	s5,8(sp)
    800047e8:	6121                	addi	sp,sp,64
    800047ea:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047ec:	85d6                	mv	a1,s5
    800047ee:	8552                	mv	a0,s4
    800047f0:	00000097          	auipc	ra,0x0
    800047f4:	34c080e7          	jalr	844(ra) # 80004b3c <pipeclose>
    800047f8:	b7cd                	j	800047da <fileclose+0xa8>

00000000800047fa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047fa:	715d                	addi	sp,sp,-80
    800047fc:	e486                	sd	ra,72(sp)
    800047fe:	e0a2                	sd	s0,64(sp)
    80004800:	fc26                	sd	s1,56(sp)
    80004802:	f84a                	sd	s2,48(sp)
    80004804:	f44e                	sd	s3,40(sp)
    80004806:	0880                	addi	s0,sp,80
    80004808:	84aa                	mv	s1,a0
    8000480a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000480c:	ffffd097          	auipc	ra,0xffffd
    80004810:	2d6080e7          	jalr	726(ra) # 80001ae2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004814:	409c                	lw	a5,0(s1)
    80004816:	37f9                	addiw	a5,a5,-2
    80004818:	4705                	li	a4,1
    8000481a:	04f76763          	bltu	a4,a5,80004868 <filestat+0x6e>
    8000481e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004820:	6c88                	ld	a0,24(s1)
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	072080e7          	jalr	114(ra) # 80003894 <ilock>
    stati(f->ip, &st);
    8000482a:	fb840593          	addi	a1,s0,-72
    8000482e:	6c88                	ld	a0,24(s1)
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	2ee080e7          	jalr	750(ra) # 80003b1e <stati>
    iunlock(f->ip);
    80004838:	6c88                	ld	a0,24(s1)
    8000483a:	fffff097          	auipc	ra,0xfffff
    8000483e:	11c080e7          	jalr	284(ra) # 80003956 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004842:	46e1                	li	a3,24
    80004844:	fb840613          	addi	a2,s0,-72
    80004848:	85ce                	mv	a1,s3
    8000484a:	05093503          	ld	a0,80(s2)
    8000484e:	ffffd097          	auipc	ra,0xffffd
    80004852:	f56080e7          	jalr	-170(ra) # 800017a4 <copyout>
    80004856:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000485a:	60a6                	ld	ra,72(sp)
    8000485c:	6406                	ld	s0,64(sp)
    8000485e:	74e2                	ld	s1,56(sp)
    80004860:	7942                	ld	s2,48(sp)
    80004862:	79a2                	ld	s3,40(sp)
    80004864:	6161                	addi	sp,sp,80
    80004866:	8082                	ret
  return -1;
    80004868:	557d                	li	a0,-1
    8000486a:	bfc5                	j	8000485a <filestat+0x60>

000000008000486c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000486c:	7179                	addi	sp,sp,-48
    8000486e:	f406                	sd	ra,40(sp)
    80004870:	f022                	sd	s0,32(sp)
    80004872:	ec26                	sd	s1,24(sp)
    80004874:	e84a                	sd	s2,16(sp)
    80004876:	e44e                	sd	s3,8(sp)
    80004878:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000487a:	00854783          	lbu	a5,8(a0)
    8000487e:	c3d5                	beqz	a5,80004922 <fileread+0xb6>
    80004880:	84aa                	mv	s1,a0
    80004882:	89ae                	mv	s3,a1
    80004884:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004886:	411c                	lw	a5,0(a0)
    80004888:	4705                	li	a4,1
    8000488a:	04e78963          	beq	a5,a4,800048dc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000488e:	470d                	li	a4,3
    80004890:	04e78d63          	beq	a5,a4,800048ea <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004894:	4709                	li	a4,2
    80004896:	06e79e63          	bne	a5,a4,80004912 <fileread+0xa6>
    ilock(f->ip);
    8000489a:	6d08                	ld	a0,24(a0)
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	ff8080e7          	jalr	-8(ra) # 80003894 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048a4:	874a                	mv	a4,s2
    800048a6:	5094                	lw	a3,32(s1)
    800048a8:	864e                	mv	a2,s3
    800048aa:	4585                	li	a1,1
    800048ac:	6c88                	ld	a0,24(s1)
    800048ae:	fffff097          	auipc	ra,0xfffff
    800048b2:	29a080e7          	jalr	666(ra) # 80003b48 <readi>
    800048b6:	892a                	mv	s2,a0
    800048b8:	00a05563          	blez	a0,800048c2 <fileread+0x56>
      f->off += r;
    800048bc:	509c                	lw	a5,32(s1)
    800048be:	9fa9                	addw	a5,a5,a0
    800048c0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048c2:	6c88                	ld	a0,24(s1)
    800048c4:	fffff097          	auipc	ra,0xfffff
    800048c8:	092080e7          	jalr	146(ra) # 80003956 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048cc:	854a                	mv	a0,s2
    800048ce:	70a2                	ld	ra,40(sp)
    800048d0:	7402                	ld	s0,32(sp)
    800048d2:	64e2                	ld	s1,24(sp)
    800048d4:	6942                	ld	s2,16(sp)
    800048d6:	69a2                	ld	s3,8(sp)
    800048d8:	6145                	addi	sp,sp,48
    800048da:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048dc:	6908                	ld	a0,16(a0)
    800048de:	00000097          	auipc	ra,0x0
    800048e2:	3c8080e7          	jalr	968(ra) # 80004ca6 <piperead>
    800048e6:	892a                	mv	s2,a0
    800048e8:	b7d5                	j	800048cc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048ea:	02451783          	lh	a5,36(a0)
    800048ee:	03079693          	slli	a3,a5,0x30
    800048f2:	92c1                	srli	a3,a3,0x30
    800048f4:	4725                	li	a4,9
    800048f6:	02d76863          	bltu	a4,a3,80004926 <fileread+0xba>
    800048fa:	0792                	slli	a5,a5,0x4
    800048fc:	0001d717          	auipc	a4,0x1d
    80004900:	a1c70713          	addi	a4,a4,-1508 # 80021318 <devsw>
    80004904:	97ba                	add	a5,a5,a4
    80004906:	639c                	ld	a5,0(a5)
    80004908:	c38d                	beqz	a5,8000492a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000490a:	4505                	li	a0,1
    8000490c:	9782                	jalr	a5
    8000490e:	892a                	mv	s2,a0
    80004910:	bf75                	j	800048cc <fileread+0x60>
    panic("fileread");
    80004912:	00004517          	auipc	a0,0x4
    80004916:	dde50513          	addi	a0,a0,-546 # 800086f0 <syscalls+0x268>
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	c24080e7          	jalr	-988(ra) # 8000053e <panic>
    return -1;
    80004922:	597d                	li	s2,-1
    80004924:	b765                	j	800048cc <fileread+0x60>
      return -1;
    80004926:	597d                	li	s2,-1
    80004928:	b755                	j	800048cc <fileread+0x60>
    8000492a:	597d                	li	s2,-1
    8000492c:	b745                	j	800048cc <fileread+0x60>

000000008000492e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000492e:	715d                	addi	sp,sp,-80
    80004930:	e486                	sd	ra,72(sp)
    80004932:	e0a2                	sd	s0,64(sp)
    80004934:	fc26                	sd	s1,56(sp)
    80004936:	f84a                	sd	s2,48(sp)
    80004938:	f44e                	sd	s3,40(sp)
    8000493a:	f052                	sd	s4,32(sp)
    8000493c:	ec56                	sd	s5,24(sp)
    8000493e:	e85a                	sd	s6,16(sp)
    80004940:	e45e                	sd	s7,8(sp)
    80004942:	e062                	sd	s8,0(sp)
    80004944:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004946:	00954783          	lbu	a5,9(a0)
    8000494a:	10078663          	beqz	a5,80004a56 <filewrite+0x128>
    8000494e:	892a                	mv	s2,a0
    80004950:	8aae                	mv	s5,a1
    80004952:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004954:	411c                	lw	a5,0(a0)
    80004956:	4705                	li	a4,1
    80004958:	02e78263          	beq	a5,a4,8000497c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000495c:	470d                	li	a4,3
    8000495e:	02e78663          	beq	a5,a4,8000498a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004962:	4709                	li	a4,2
    80004964:	0ee79163          	bne	a5,a4,80004a46 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004968:	0ac05d63          	blez	a2,80004a22 <filewrite+0xf4>
    int i = 0;
    8000496c:	4981                	li	s3,0
    8000496e:	6b05                	lui	s6,0x1
    80004970:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004974:	6b85                	lui	s7,0x1
    80004976:	c00b8b9b          	addiw	s7,s7,-1024
    8000497a:	a861                	j	80004a12 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000497c:	6908                	ld	a0,16(a0)
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	22e080e7          	jalr	558(ra) # 80004bac <pipewrite>
    80004986:	8a2a                	mv	s4,a0
    80004988:	a045                	j	80004a28 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000498a:	02451783          	lh	a5,36(a0)
    8000498e:	03079693          	slli	a3,a5,0x30
    80004992:	92c1                	srli	a3,a3,0x30
    80004994:	4725                	li	a4,9
    80004996:	0cd76263          	bltu	a4,a3,80004a5a <filewrite+0x12c>
    8000499a:	0792                	slli	a5,a5,0x4
    8000499c:	0001d717          	auipc	a4,0x1d
    800049a0:	97c70713          	addi	a4,a4,-1668 # 80021318 <devsw>
    800049a4:	97ba                	add	a5,a5,a4
    800049a6:	679c                	ld	a5,8(a5)
    800049a8:	cbdd                	beqz	a5,80004a5e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049aa:	4505                	li	a0,1
    800049ac:	9782                	jalr	a5
    800049ae:	8a2a                	mv	s4,a0
    800049b0:	a8a5                	j	80004a28 <filewrite+0xfa>
    800049b2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	8b0080e7          	jalr	-1872(ra) # 80004266 <begin_op>
      ilock(f->ip);
    800049be:	01893503          	ld	a0,24(s2)
    800049c2:	fffff097          	auipc	ra,0xfffff
    800049c6:	ed2080e7          	jalr	-302(ra) # 80003894 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049ca:	8762                	mv	a4,s8
    800049cc:	02092683          	lw	a3,32(s2)
    800049d0:	01598633          	add	a2,s3,s5
    800049d4:	4585                	li	a1,1
    800049d6:	01893503          	ld	a0,24(s2)
    800049da:	fffff097          	auipc	ra,0xfffff
    800049de:	266080e7          	jalr	614(ra) # 80003c40 <writei>
    800049e2:	84aa                	mv	s1,a0
    800049e4:	00a05763          	blez	a0,800049f2 <filewrite+0xc4>
        f->off += r;
    800049e8:	02092783          	lw	a5,32(s2)
    800049ec:	9fa9                	addw	a5,a5,a0
    800049ee:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049f2:	01893503          	ld	a0,24(s2)
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	f60080e7          	jalr	-160(ra) # 80003956 <iunlock>
      end_op();
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	8e8080e7          	jalr	-1816(ra) # 800042e6 <end_op>

      if(r != n1){
    80004a06:	009c1f63          	bne	s8,s1,80004a24 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a0a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a0e:	0149db63          	bge	s3,s4,80004a24 <filewrite+0xf6>
      int n1 = n - i;
    80004a12:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a16:	84be                	mv	s1,a5
    80004a18:	2781                	sext.w	a5,a5
    80004a1a:	f8fb5ce3          	bge	s6,a5,800049b2 <filewrite+0x84>
    80004a1e:	84de                	mv	s1,s7
    80004a20:	bf49                	j	800049b2 <filewrite+0x84>
    int i = 0;
    80004a22:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a24:	013a1f63          	bne	s4,s3,80004a42 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a28:	8552                	mv	a0,s4
    80004a2a:	60a6                	ld	ra,72(sp)
    80004a2c:	6406                	ld	s0,64(sp)
    80004a2e:	74e2                	ld	s1,56(sp)
    80004a30:	7942                	ld	s2,48(sp)
    80004a32:	79a2                	ld	s3,40(sp)
    80004a34:	7a02                	ld	s4,32(sp)
    80004a36:	6ae2                	ld	s5,24(sp)
    80004a38:	6b42                	ld	s6,16(sp)
    80004a3a:	6ba2                	ld	s7,8(sp)
    80004a3c:	6c02                	ld	s8,0(sp)
    80004a3e:	6161                	addi	sp,sp,80
    80004a40:	8082                	ret
    ret = (i == n ? n : -1);
    80004a42:	5a7d                	li	s4,-1
    80004a44:	b7d5                	j	80004a28 <filewrite+0xfa>
    panic("filewrite");
    80004a46:	00004517          	auipc	a0,0x4
    80004a4a:	cba50513          	addi	a0,a0,-838 # 80008700 <syscalls+0x278>
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	af0080e7          	jalr	-1296(ra) # 8000053e <panic>
    return -1;
    80004a56:	5a7d                	li	s4,-1
    80004a58:	bfc1                	j	80004a28 <filewrite+0xfa>
      return -1;
    80004a5a:	5a7d                	li	s4,-1
    80004a5c:	b7f1                	j	80004a28 <filewrite+0xfa>
    80004a5e:	5a7d                	li	s4,-1
    80004a60:	b7e1                	j	80004a28 <filewrite+0xfa>

0000000080004a62 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a62:	7179                	addi	sp,sp,-48
    80004a64:	f406                	sd	ra,40(sp)
    80004a66:	f022                	sd	s0,32(sp)
    80004a68:	ec26                	sd	s1,24(sp)
    80004a6a:	e84a                	sd	s2,16(sp)
    80004a6c:	e44e                	sd	s3,8(sp)
    80004a6e:	e052                	sd	s4,0(sp)
    80004a70:	1800                	addi	s0,sp,48
    80004a72:	84aa                	mv	s1,a0
    80004a74:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a76:	0005b023          	sd	zero,0(a1)
    80004a7a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a7e:	00000097          	auipc	ra,0x0
    80004a82:	bf8080e7          	jalr	-1032(ra) # 80004676 <filealloc>
    80004a86:	e088                	sd	a0,0(s1)
    80004a88:	c551                	beqz	a0,80004b14 <pipealloc+0xb2>
    80004a8a:	00000097          	auipc	ra,0x0
    80004a8e:	bec080e7          	jalr	-1044(ra) # 80004676 <filealloc>
    80004a92:	00aa3023          	sd	a0,0(s4)
    80004a96:	c92d                	beqz	a0,80004b08 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	05c080e7          	jalr	92(ra) # 80000af4 <kalloc>
    80004aa0:	892a                	mv	s2,a0
    80004aa2:	c125                	beqz	a0,80004b02 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004aa4:	4985                	li	s3,1
    80004aa6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004aaa:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004aae:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ab2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ab6:	00004597          	auipc	a1,0x4
    80004aba:	c5a58593          	addi	a1,a1,-934 # 80008710 <syscalls+0x288>
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	096080e7          	jalr	150(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004ac6:	609c                	ld	a5,0(s1)
    80004ac8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004acc:	609c                	ld	a5,0(s1)
    80004ace:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ad2:	609c                	ld	a5,0(s1)
    80004ad4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ad8:	609c                	ld	a5,0(s1)
    80004ada:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ade:	000a3783          	ld	a5,0(s4)
    80004ae2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ae6:	000a3783          	ld	a5,0(s4)
    80004aea:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004aee:	000a3783          	ld	a5,0(s4)
    80004af2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004af6:	000a3783          	ld	a5,0(s4)
    80004afa:	0127b823          	sd	s2,16(a5)
  return 0;
    80004afe:	4501                	li	a0,0
    80004b00:	a025                	j	80004b28 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b02:	6088                	ld	a0,0(s1)
    80004b04:	e501                	bnez	a0,80004b0c <pipealloc+0xaa>
    80004b06:	a039                	j	80004b14 <pipealloc+0xb2>
    80004b08:	6088                	ld	a0,0(s1)
    80004b0a:	c51d                	beqz	a0,80004b38 <pipealloc+0xd6>
    fileclose(*f0);
    80004b0c:	00000097          	auipc	ra,0x0
    80004b10:	c26080e7          	jalr	-986(ra) # 80004732 <fileclose>
  if(*f1)
    80004b14:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b18:	557d                	li	a0,-1
  if(*f1)
    80004b1a:	c799                	beqz	a5,80004b28 <pipealloc+0xc6>
    fileclose(*f1);
    80004b1c:	853e                	mv	a0,a5
    80004b1e:	00000097          	auipc	ra,0x0
    80004b22:	c14080e7          	jalr	-1004(ra) # 80004732 <fileclose>
  return -1;
    80004b26:	557d                	li	a0,-1
}
    80004b28:	70a2                	ld	ra,40(sp)
    80004b2a:	7402                	ld	s0,32(sp)
    80004b2c:	64e2                	ld	s1,24(sp)
    80004b2e:	6942                	ld	s2,16(sp)
    80004b30:	69a2                	ld	s3,8(sp)
    80004b32:	6a02                	ld	s4,0(sp)
    80004b34:	6145                	addi	sp,sp,48
    80004b36:	8082                	ret
  return -1;
    80004b38:	557d                	li	a0,-1
    80004b3a:	b7fd                	j	80004b28 <pipealloc+0xc6>

0000000080004b3c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b3c:	1101                	addi	sp,sp,-32
    80004b3e:	ec06                	sd	ra,24(sp)
    80004b40:	e822                	sd	s0,16(sp)
    80004b42:	e426                	sd	s1,8(sp)
    80004b44:	e04a                	sd	s2,0(sp)
    80004b46:	1000                	addi	s0,sp,32
    80004b48:	84aa                	mv	s1,a0
    80004b4a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	098080e7          	jalr	152(ra) # 80000be4 <acquire>
  if(writable){
    80004b54:	02090d63          	beqz	s2,80004b8e <pipeclose+0x52>
    pi->writeopen = 0;
    80004b58:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b5c:	21848513          	addi	a0,s1,536
    80004b60:	ffffe097          	auipc	ra,0xffffe
    80004b64:	8be080e7          	jalr	-1858(ra) # 8000241e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b68:	2204b783          	ld	a5,544(s1)
    80004b6c:	eb95                	bnez	a5,80004ba0 <pipeclose+0x64>
    release(&pi->lock);
    80004b6e:	8526                	mv	a0,s1
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	128080e7          	jalr	296(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004b78:	8526                	mv	a0,s1
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	e7e080e7          	jalr	-386(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004b82:	60e2                	ld	ra,24(sp)
    80004b84:	6442                	ld	s0,16(sp)
    80004b86:	64a2                	ld	s1,8(sp)
    80004b88:	6902                	ld	s2,0(sp)
    80004b8a:	6105                	addi	sp,sp,32
    80004b8c:	8082                	ret
    pi->readopen = 0;
    80004b8e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b92:	21c48513          	addi	a0,s1,540
    80004b96:	ffffe097          	auipc	ra,0xffffe
    80004b9a:	888080e7          	jalr	-1912(ra) # 8000241e <wakeup>
    80004b9e:	b7e9                	j	80004b68 <pipeclose+0x2c>
    release(&pi->lock);
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	0f6080e7          	jalr	246(ra) # 80000c98 <release>
}
    80004baa:	bfe1                	j	80004b82 <pipeclose+0x46>

0000000080004bac <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bac:	7159                	addi	sp,sp,-112
    80004bae:	f486                	sd	ra,104(sp)
    80004bb0:	f0a2                	sd	s0,96(sp)
    80004bb2:	eca6                	sd	s1,88(sp)
    80004bb4:	e8ca                	sd	s2,80(sp)
    80004bb6:	e4ce                	sd	s3,72(sp)
    80004bb8:	e0d2                	sd	s4,64(sp)
    80004bba:	fc56                	sd	s5,56(sp)
    80004bbc:	f85a                	sd	s6,48(sp)
    80004bbe:	f45e                	sd	s7,40(sp)
    80004bc0:	f062                	sd	s8,32(sp)
    80004bc2:	ec66                	sd	s9,24(sp)
    80004bc4:	1880                	addi	s0,sp,112
    80004bc6:	84aa                	mv	s1,a0
    80004bc8:	8aae                	mv	s5,a1
    80004bca:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bcc:	ffffd097          	auipc	ra,0xffffd
    80004bd0:	f16080e7          	jalr	-234(ra) # 80001ae2 <myproc>
    80004bd4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bd6:	8526                	mv	a0,s1
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
  while(i < n){
    80004be0:	0d405163          	blez	s4,80004ca2 <pipewrite+0xf6>
    80004be4:	8ba6                	mv	s7,s1
  int i = 0;
    80004be6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004be8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bea:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bee:	21c48c13          	addi	s8,s1,540
    80004bf2:	a08d                	j	80004c54 <pipewrite+0xa8>
      release(&pi->lock);
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	0a2080e7          	jalr	162(ra) # 80000c98 <release>
      return -1;
    80004bfe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c00:	854a                	mv	a0,s2
    80004c02:	70a6                	ld	ra,104(sp)
    80004c04:	7406                	ld	s0,96(sp)
    80004c06:	64e6                	ld	s1,88(sp)
    80004c08:	6946                	ld	s2,80(sp)
    80004c0a:	69a6                	ld	s3,72(sp)
    80004c0c:	6a06                	ld	s4,64(sp)
    80004c0e:	7ae2                	ld	s5,56(sp)
    80004c10:	7b42                	ld	s6,48(sp)
    80004c12:	7ba2                	ld	s7,40(sp)
    80004c14:	7c02                	ld	s8,32(sp)
    80004c16:	6ce2                	ld	s9,24(sp)
    80004c18:	6165                	addi	sp,sp,112
    80004c1a:	8082                	ret
      wakeup(&pi->nread);
    80004c1c:	8566                	mv	a0,s9
    80004c1e:	ffffe097          	auipc	ra,0xffffe
    80004c22:	800080e7          	jalr	-2048(ra) # 8000241e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c26:	85de                	mv	a1,s7
    80004c28:	8562                	mv	a0,s8
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	574080e7          	jalr	1396(ra) # 8000219e <sleep>
    80004c32:	a839                	j	80004c50 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c34:	21c4a783          	lw	a5,540(s1)
    80004c38:	0017871b          	addiw	a4,a5,1
    80004c3c:	20e4ae23          	sw	a4,540(s1)
    80004c40:	1ff7f793          	andi	a5,a5,511
    80004c44:	97a6                	add	a5,a5,s1
    80004c46:	f9f44703          	lbu	a4,-97(s0)
    80004c4a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c4e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c50:	03495d63          	bge	s2,s4,80004c8a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004c54:	2204a783          	lw	a5,544(s1)
    80004c58:	dfd1                	beqz	a5,80004bf4 <pipewrite+0x48>
    80004c5a:	0289a783          	lw	a5,40(s3)
    80004c5e:	fbd9                	bnez	a5,80004bf4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c60:	2184a783          	lw	a5,536(s1)
    80004c64:	21c4a703          	lw	a4,540(s1)
    80004c68:	2007879b          	addiw	a5,a5,512
    80004c6c:	faf708e3          	beq	a4,a5,80004c1c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c70:	4685                	li	a3,1
    80004c72:	01590633          	add	a2,s2,s5
    80004c76:	f9f40593          	addi	a1,s0,-97
    80004c7a:	0509b503          	ld	a0,80(s3)
    80004c7e:	ffffd097          	auipc	ra,0xffffd
    80004c82:	bb2080e7          	jalr	-1102(ra) # 80001830 <copyin>
    80004c86:	fb6517e3          	bne	a0,s6,80004c34 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c8a:	21848513          	addi	a0,s1,536
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	790080e7          	jalr	1936(ra) # 8000241e <wakeup>
  release(&pi->lock);
    80004c96:	8526                	mv	a0,s1
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	000080e7          	jalr	ra # 80000c98 <release>
  return i;
    80004ca0:	b785                	j	80004c00 <pipewrite+0x54>
  int i = 0;
    80004ca2:	4901                	li	s2,0
    80004ca4:	b7dd                	j	80004c8a <pipewrite+0xde>

0000000080004ca6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ca6:	715d                	addi	sp,sp,-80
    80004ca8:	e486                	sd	ra,72(sp)
    80004caa:	e0a2                	sd	s0,64(sp)
    80004cac:	fc26                	sd	s1,56(sp)
    80004cae:	f84a                	sd	s2,48(sp)
    80004cb0:	f44e                	sd	s3,40(sp)
    80004cb2:	f052                	sd	s4,32(sp)
    80004cb4:	ec56                	sd	s5,24(sp)
    80004cb6:	e85a                	sd	s6,16(sp)
    80004cb8:	0880                	addi	s0,sp,80
    80004cba:	84aa                	mv	s1,a0
    80004cbc:	892e                	mv	s2,a1
    80004cbe:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	e22080e7          	jalr	-478(ra) # 80001ae2 <myproc>
    80004cc8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cca:	8b26                	mv	s6,s1
    80004ccc:	8526                	mv	a0,s1
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	f16080e7          	jalr	-234(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd6:	2184a703          	lw	a4,536(s1)
    80004cda:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cde:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ce2:	02f71463          	bne	a4,a5,80004d0a <piperead+0x64>
    80004ce6:	2244a783          	lw	a5,548(s1)
    80004cea:	c385                	beqz	a5,80004d0a <piperead+0x64>
    if(pr->killed){
    80004cec:	028a2783          	lw	a5,40(s4)
    80004cf0:	ebc1                	bnez	a5,80004d80 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cf2:	85da                	mv	a1,s6
    80004cf4:	854e                	mv	a0,s3
    80004cf6:	ffffd097          	auipc	ra,0xffffd
    80004cfa:	4a8080e7          	jalr	1192(ra) # 8000219e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cfe:	2184a703          	lw	a4,536(s1)
    80004d02:	21c4a783          	lw	a5,540(s1)
    80004d06:	fef700e3          	beq	a4,a5,80004ce6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d0a:	09505263          	blez	s5,80004d8e <piperead+0xe8>
    80004d0e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d10:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d12:	2184a783          	lw	a5,536(s1)
    80004d16:	21c4a703          	lw	a4,540(s1)
    80004d1a:	02f70d63          	beq	a4,a5,80004d54 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d1e:	0017871b          	addiw	a4,a5,1
    80004d22:	20e4ac23          	sw	a4,536(s1)
    80004d26:	1ff7f793          	andi	a5,a5,511
    80004d2a:	97a6                	add	a5,a5,s1
    80004d2c:	0187c783          	lbu	a5,24(a5)
    80004d30:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d34:	4685                	li	a3,1
    80004d36:	fbf40613          	addi	a2,s0,-65
    80004d3a:	85ca                	mv	a1,s2
    80004d3c:	050a3503          	ld	a0,80(s4)
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	a64080e7          	jalr	-1436(ra) # 800017a4 <copyout>
    80004d48:	01650663          	beq	a0,s6,80004d54 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d4c:	2985                	addiw	s3,s3,1
    80004d4e:	0905                	addi	s2,s2,1
    80004d50:	fd3a91e3          	bne	s5,s3,80004d12 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d54:	21c48513          	addi	a0,s1,540
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	6c6080e7          	jalr	1734(ra) # 8000241e <wakeup>
  release(&pi->lock);
    80004d60:	8526                	mv	a0,s1
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	f36080e7          	jalr	-202(ra) # 80000c98 <release>
  return i;
}
    80004d6a:	854e                	mv	a0,s3
    80004d6c:	60a6                	ld	ra,72(sp)
    80004d6e:	6406                	ld	s0,64(sp)
    80004d70:	74e2                	ld	s1,56(sp)
    80004d72:	7942                	ld	s2,48(sp)
    80004d74:	79a2                	ld	s3,40(sp)
    80004d76:	7a02                	ld	s4,32(sp)
    80004d78:	6ae2                	ld	s5,24(sp)
    80004d7a:	6b42                	ld	s6,16(sp)
    80004d7c:	6161                	addi	sp,sp,80
    80004d7e:	8082                	ret
      release(&pi->lock);
    80004d80:	8526                	mv	a0,s1
    80004d82:	ffffc097          	auipc	ra,0xffffc
    80004d86:	f16080e7          	jalr	-234(ra) # 80000c98 <release>
      return -1;
    80004d8a:	59fd                	li	s3,-1
    80004d8c:	bff9                	j	80004d6a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d8e:	4981                	li	s3,0
    80004d90:	b7d1                	j	80004d54 <piperead+0xae>

0000000080004d92 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d92:	df010113          	addi	sp,sp,-528
    80004d96:	20113423          	sd	ra,520(sp)
    80004d9a:	20813023          	sd	s0,512(sp)
    80004d9e:	ffa6                	sd	s1,504(sp)
    80004da0:	fbca                	sd	s2,496(sp)
    80004da2:	f7ce                	sd	s3,488(sp)
    80004da4:	f3d2                	sd	s4,480(sp)
    80004da6:	efd6                	sd	s5,472(sp)
    80004da8:	ebda                	sd	s6,464(sp)
    80004daa:	e7de                	sd	s7,456(sp)
    80004dac:	e3e2                	sd	s8,448(sp)
    80004dae:	ff66                	sd	s9,440(sp)
    80004db0:	fb6a                	sd	s10,432(sp)
    80004db2:	f76e                	sd	s11,424(sp)
    80004db4:	0c00                	addi	s0,sp,528
    80004db6:	84aa                	mv	s1,a0
    80004db8:	dea43c23          	sd	a0,-520(s0)
    80004dbc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	d22080e7          	jalr	-734(ra) # 80001ae2 <myproc>
    80004dc8:	892a                	mv	s2,a0

  begin_op();
    80004dca:	fffff097          	auipc	ra,0xfffff
    80004dce:	49c080e7          	jalr	1180(ra) # 80004266 <begin_op>

  if((ip = namei(path)) == 0){
    80004dd2:	8526                	mv	a0,s1
    80004dd4:	fffff097          	auipc	ra,0xfffff
    80004dd8:	276080e7          	jalr	630(ra) # 8000404a <namei>
    80004ddc:	c92d                	beqz	a0,80004e4e <exec+0xbc>
    80004dde:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	ab4080e7          	jalr	-1356(ra) # 80003894 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004de8:	04000713          	li	a4,64
    80004dec:	4681                	li	a3,0
    80004dee:	e5040613          	addi	a2,s0,-432
    80004df2:	4581                	li	a1,0
    80004df4:	8526                	mv	a0,s1
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	d52080e7          	jalr	-686(ra) # 80003b48 <readi>
    80004dfe:	04000793          	li	a5,64
    80004e02:	00f51a63          	bne	a0,a5,80004e16 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e06:	e5042703          	lw	a4,-432(s0)
    80004e0a:	464c47b7          	lui	a5,0x464c4
    80004e0e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e12:	04f70463          	beq	a4,a5,80004e5a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e16:	8526                	mv	a0,s1
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	cde080e7          	jalr	-802(ra) # 80003af6 <iunlockput>
    end_op();
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	4c6080e7          	jalr	1222(ra) # 800042e6 <end_op>
  }
  return -1;
    80004e28:	557d                	li	a0,-1
}
    80004e2a:	20813083          	ld	ra,520(sp)
    80004e2e:	20013403          	ld	s0,512(sp)
    80004e32:	74fe                	ld	s1,504(sp)
    80004e34:	795e                	ld	s2,496(sp)
    80004e36:	79be                	ld	s3,488(sp)
    80004e38:	7a1e                	ld	s4,480(sp)
    80004e3a:	6afe                	ld	s5,472(sp)
    80004e3c:	6b5e                	ld	s6,464(sp)
    80004e3e:	6bbe                	ld	s7,456(sp)
    80004e40:	6c1e                	ld	s8,448(sp)
    80004e42:	7cfa                	ld	s9,440(sp)
    80004e44:	7d5a                	ld	s10,432(sp)
    80004e46:	7dba                	ld	s11,424(sp)
    80004e48:	21010113          	addi	sp,sp,528
    80004e4c:	8082                	ret
    end_op();
    80004e4e:	fffff097          	auipc	ra,0xfffff
    80004e52:	498080e7          	jalr	1176(ra) # 800042e6 <end_op>
    return -1;
    80004e56:	557d                	li	a0,-1
    80004e58:	bfc9                	j	80004e2a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e5a:	854a                	mv	a0,s2
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	d4a080e7          	jalr	-694(ra) # 80001ba6 <proc_pagetable>
    80004e64:	8baa                	mv	s7,a0
    80004e66:	d945                	beqz	a0,80004e16 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e68:	e7042983          	lw	s3,-400(s0)
    80004e6c:	e8845783          	lhu	a5,-376(s0)
    80004e70:	c7ad                	beqz	a5,80004eda <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e72:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e74:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004e76:	6c85                	lui	s9,0x1
    80004e78:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e7c:	def43823          	sd	a5,-528(s0)
    80004e80:	a42d                	j	800050aa <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e82:	00004517          	auipc	a0,0x4
    80004e86:	89650513          	addi	a0,a0,-1898 # 80008718 <syscalls+0x290>
    80004e8a:	ffffb097          	auipc	ra,0xffffb
    80004e8e:	6b4080e7          	jalr	1716(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e92:	8756                	mv	a4,s5
    80004e94:	012d86bb          	addw	a3,s11,s2
    80004e98:	4581                	li	a1,0
    80004e9a:	8526                	mv	a0,s1
    80004e9c:	fffff097          	auipc	ra,0xfffff
    80004ea0:	cac080e7          	jalr	-852(ra) # 80003b48 <readi>
    80004ea4:	2501                	sext.w	a0,a0
    80004ea6:	1aaa9963          	bne	s5,a0,80005058 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004eaa:	6785                	lui	a5,0x1
    80004eac:	0127893b          	addw	s2,a5,s2
    80004eb0:	77fd                	lui	a5,0xfffff
    80004eb2:	01478a3b          	addw	s4,a5,s4
    80004eb6:	1f897163          	bgeu	s2,s8,80005098 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004eba:	02091593          	slli	a1,s2,0x20
    80004ebe:	9181                	srli	a1,a1,0x20
    80004ec0:	95ea                	add	a1,a1,s10
    80004ec2:	855e                	mv	a0,s7
    80004ec4:	ffffc097          	auipc	ra,0xffffc
    80004ec8:	2dc080e7          	jalr	732(ra) # 800011a0 <walkaddr>
    80004ecc:	862a                	mv	a2,a0
    if(pa == 0)
    80004ece:	d955                	beqz	a0,80004e82 <exec+0xf0>
      n = PGSIZE;
    80004ed0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ed2:	fd9a70e3          	bgeu	s4,s9,80004e92 <exec+0x100>
      n = sz - i;
    80004ed6:	8ad2                	mv	s5,s4
    80004ed8:	bf6d                	j	80004e92 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eda:	4901                	li	s2,0
  iunlockput(ip);
    80004edc:	8526                	mv	a0,s1
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	c18080e7          	jalr	-1000(ra) # 80003af6 <iunlockput>
  end_op();
    80004ee6:	fffff097          	auipc	ra,0xfffff
    80004eea:	400080e7          	jalr	1024(ra) # 800042e6 <end_op>
  p = myproc();
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	bf4080e7          	jalr	-1036(ra) # 80001ae2 <myproc>
    80004ef6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ef8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004efc:	6785                	lui	a5,0x1
    80004efe:	17fd                	addi	a5,a5,-1
    80004f00:	993e                	add	s2,s2,a5
    80004f02:	757d                	lui	a0,0xfffff
    80004f04:	00a977b3          	and	a5,s2,a0
    80004f08:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f0c:	6609                	lui	a2,0x2
    80004f0e:	963e                	add	a2,a2,a5
    80004f10:	85be                	mv	a1,a5
    80004f12:	855e                	mv	a0,s7
    80004f14:	ffffc097          	auipc	ra,0xffffc
    80004f18:	640080e7          	jalr	1600(ra) # 80001554 <uvmalloc>
    80004f1c:	8b2a                	mv	s6,a0
  ip = 0;
    80004f1e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f20:	12050c63          	beqz	a0,80005058 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f24:	75f9                	lui	a1,0xffffe
    80004f26:	95aa                	add	a1,a1,a0
    80004f28:	855e                	mv	a0,s7
    80004f2a:	ffffd097          	auipc	ra,0xffffd
    80004f2e:	848080e7          	jalr	-1976(ra) # 80001772 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f32:	7c7d                	lui	s8,0xfffff
    80004f34:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f36:	e0043783          	ld	a5,-512(s0)
    80004f3a:	6388                	ld	a0,0(a5)
    80004f3c:	c535                	beqz	a0,80004fa8 <exec+0x216>
    80004f3e:	e9040993          	addi	s3,s0,-368
    80004f42:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f46:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	f1c080e7          	jalr	-228(ra) # 80000e64 <strlen>
    80004f50:	2505                	addiw	a0,a0,1
    80004f52:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f56:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f5a:	13896363          	bltu	s2,s8,80005080 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f5e:	e0043d83          	ld	s11,-512(s0)
    80004f62:	000dba03          	ld	s4,0(s11)
    80004f66:	8552                	mv	a0,s4
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	efc080e7          	jalr	-260(ra) # 80000e64 <strlen>
    80004f70:	0015069b          	addiw	a3,a0,1
    80004f74:	8652                	mv	a2,s4
    80004f76:	85ca                	mv	a1,s2
    80004f78:	855e                	mv	a0,s7
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	82a080e7          	jalr	-2006(ra) # 800017a4 <copyout>
    80004f82:	10054363          	bltz	a0,80005088 <exec+0x2f6>
    ustack[argc] = sp;
    80004f86:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f8a:	0485                	addi	s1,s1,1
    80004f8c:	008d8793          	addi	a5,s11,8
    80004f90:	e0f43023          	sd	a5,-512(s0)
    80004f94:	008db503          	ld	a0,8(s11)
    80004f98:	c911                	beqz	a0,80004fac <exec+0x21a>
    if(argc >= MAXARG)
    80004f9a:	09a1                	addi	s3,s3,8
    80004f9c:	fb3c96e3          	bne	s9,s3,80004f48 <exec+0x1b6>
  sz = sz1;
    80004fa0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa4:	4481                	li	s1,0
    80004fa6:	a84d                	j	80005058 <exec+0x2c6>
  sp = sz;
    80004fa8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004faa:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fac:	00349793          	slli	a5,s1,0x3
    80004fb0:	f9040713          	addi	a4,s0,-112
    80004fb4:	97ba                	add	a5,a5,a4
    80004fb6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004fba:	00148693          	addi	a3,s1,1
    80004fbe:	068e                	slli	a3,a3,0x3
    80004fc0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fc4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fc8:	01897663          	bgeu	s2,s8,80004fd4 <exec+0x242>
  sz = sz1;
    80004fcc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fd0:	4481                	li	s1,0
    80004fd2:	a059                	j	80005058 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fd4:	e9040613          	addi	a2,s0,-368
    80004fd8:	85ca                	mv	a1,s2
    80004fda:	855e                	mv	a0,s7
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	7c8080e7          	jalr	1992(ra) # 800017a4 <copyout>
    80004fe4:	0a054663          	bltz	a0,80005090 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004fe8:	058ab783          	ld	a5,88(s5)
    80004fec:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ff0:	df843783          	ld	a5,-520(s0)
    80004ff4:	0007c703          	lbu	a4,0(a5)
    80004ff8:	cf11                	beqz	a4,80005014 <exec+0x282>
    80004ffa:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ffc:	02f00693          	li	a3,47
    80005000:	a039                	j	8000500e <exec+0x27c>
      last = s+1;
    80005002:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005006:	0785                	addi	a5,a5,1
    80005008:	fff7c703          	lbu	a4,-1(a5)
    8000500c:	c701                	beqz	a4,80005014 <exec+0x282>
    if(*s == '/')
    8000500e:	fed71ce3          	bne	a4,a3,80005006 <exec+0x274>
    80005012:	bfc5                	j	80005002 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005014:	4641                	li	a2,16
    80005016:	df843583          	ld	a1,-520(s0)
    8000501a:	158a8513          	addi	a0,s5,344
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	e14080e7          	jalr	-492(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005026:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000502a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000502e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005032:	058ab783          	ld	a5,88(s5)
    80005036:	e6843703          	ld	a4,-408(s0)
    8000503a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000503c:	058ab783          	ld	a5,88(s5)
    80005040:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005044:	85ea                	mv	a1,s10
    80005046:	ffffd097          	auipc	ra,0xffffd
    8000504a:	bfc080e7          	jalr	-1028(ra) # 80001c42 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000504e:	0004851b          	sext.w	a0,s1
    80005052:	bbe1                	j	80004e2a <exec+0x98>
    80005054:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005058:	e0843583          	ld	a1,-504(s0)
    8000505c:	855e                	mv	a0,s7
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	be4080e7          	jalr	-1052(ra) # 80001c42 <proc_freepagetable>
  if(ip){
    80005066:	da0498e3          	bnez	s1,80004e16 <exec+0x84>
  return -1;
    8000506a:	557d                	li	a0,-1
    8000506c:	bb7d                	j	80004e2a <exec+0x98>
    8000506e:	e1243423          	sd	s2,-504(s0)
    80005072:	b7dd                	j	80005058 <exec+0x2c6>
    80005074:	e1243423          	sd	s2,-504(s0)
    80005078:	b7c5                	j	80005058 <exec+0x2c6>
    8000507a:	e1243423          	sd	s2,-504(s0)
    8000507e:	bfe9                	j	80005058 <exec+0x2c6>
  sz = sz1;
    80005080:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005084:	4481                	li	s1,0
    80005086:	bfc9                	j	80005058 <exec+0x2c6>
  sz = sz1;
    80005088:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000508c:	4481                	li	s1,0
    8000508e:	b7e9                	j	80005058 <exec+0x2c6>
  sz = sz1;
    80005090:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005094:	4481                	li	s1,0
    80005096:	b7c9                	j	80005058 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005098:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000509c:	2b05                	addiw	s6,s6,1
    8000509e:	0389899b          	addiw	s3,s3,56
    800050a2:	e8845783          	lhu	a5,-376(s0)
    800050a6:	e2fb5be3          	bge	s6,a5,80004edc <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050aa:	2981                	sext.w	s3,s3
    800050ac:	03800713          	li	a4,56
    800050b0:	86ce                	mv	a3,s3
    800050b2:	e1840613          	addi	a2,s0,-488
    800050b6:	4581                	li	a1,0
    800050b8:	8526                	mv	a0,s1
    800050ba:	fffff097          	auipc	ra,0xfffff
    800050be:	a8e080e7          	jalr	-1394(ra) # 80003b48 <readi>
    800050c2:	03800793          	li	a5,56
    800050c6:	f8f517e3          	bne	a0,a5,80005054 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050ca:	e1842783          	lw	a5,-488(s0)
    800050ce:	4705                	li	a4,1
    800050d0:	fce796e3          	bne	a5,a4,8000509c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050d4:	e4043603          	ld	a2,-448(s0)
    800050d8:	e3843783          	ld	a5,-456(s0)
    800050dc:	f8f669e3          	bltu	a2,a5,8000506e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050e0:	e2843783          	ld	a5,-472(s0)
    800050e4:	963e                	add	a2,a2,a5
    800050e6:	f8f667e3          	bltu	a2,a5,80005074 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050ea:	85ca                	mv	a1,s2
    800050ec:	855e                	mv	a0,s7
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	466080e7          	jalr	1126(ra) # 80001554 <uvmalloc>
    800050f6:	e0a43423          	sd	a0,-504(s0)
    800050fa:	d141                	beqz	a0,8000507a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800050fc:	e2843d03          	ld	s10,-472(s0)
    80005100:	df043783          	ld	a5,-528(s0)
    80005104:	00fd77b3          	and	a5,s10,a5
    80005108:	fba1                	bnez	a5,80005058 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000510a:	e2042d83          	lw	s11,-480(s0)
    8000510e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005112:	f80c03e3          	beqz	s8,80005098 <exec+0x306>
    80005116:	8a62                	mv	s4,s8
    80005118:	4901                	li	s2,0
    8000511a:	b345                	j	80004eba <exec+0x128>

000000008000511c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000511c:	7179                	addi	sp,sp,-48
    8000511e:	f406                	sd	ra,40(sp)
    80005120:	f022                	sd	s0,32(sp)
    80005122:	ec26                	sd	s1,24(sp)
    80005124:	e84a                	sd	s2,16(sp)
    80005126:	1800                	addi	s0,sp,48
    80005128:	892e                	mv	s2,a1
    8000512a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000512c:	fdc40593          	addi	a1,s0,-36
    80005130:	ffffe097          	auipc	ra,0xffffe
    80005134:	ba8080e7          	jalr	-1112(ra) # 80002cd8 <argint>
    80005138:	04054063          	bltz	a0,80005178 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000513c:	fdc42703          	lw	a4,-36(s0)
    80005140:	47bd                	li	a5,15
    80005142:	02e7ed63          	bltu	a5,a4,8000517c <argfd+0x60>
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	99c080e7          	jalr	-1636(ra) # 80001ae2 <myproc>
    8000514e:	fdc42703          	lw	a4,-36(s0)
    80005152:	01a70793          	addi	a5,a4,26
    80005156:	078e                	slli	a5,a5,0x3
    80005158:	953e                	add	a0,a0,a5
    8000515a:	611c                	ld	a5,0(a0)
    8000515c:	c395                	beqz	a5,80005180 <argfd+0x64>
    return -1;
  if(pfd)
    8000515e:	00090463          	beqz	s2,80005166 <argfd+0x4a>
    *pfd = fd;
    80005162:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005166:	4501                	li	a0,0
  if(pf)
    80005168:	c091                	beqz	s1,8000516c <argfd+0x50>
    *pf = f;
    8000516a:	e09c                	sd	a5,0(s1)
}
    8000516c:	70a2                	ld	ra,40(sp)
    8000516e:	7402                	ld	s0,32(sp)
    80005170:	64e2                	ld	s1,24(sp)
    80005172:	6942                	ld	s2,16(sp)
    80005174:	6145                	addi	sp,sp,48
    80005176:	8082                	ret
    return -1;
    80005178:	557d                	li	a0,-1
    8000517a:	bfcd                	j	8000516c <argfd+0x50>
    return -1;
    8000517c:	557d                	li	a0,-1
    8000517e:	b7fd                	j	8000516c <argfd+0x50>
    80005180:	557d                	li	a0,-1
    80005182:	b7ed                	j	8000516c <argfd+0x50>

0000000080005184 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005184:	1101                	addi	sp,sp,-32
    80005186:	ec06                	sd	ra,24(sp)
    80005188:	e822                	sd	s0,16(sp)
    8000518a:	e426                	sd	s1,8(sp)
    8000518c:	1000                	addi	s0,sp,32
    8000518e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	952080e7          	jalr	-1710(ra) # 80001ae2 <myproc>
    80005198:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000519a:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000519e:	4501                	li	a0,0
    800051a0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051a2:	6398                	ld	a4,0(a5)
    800051a4:	cb19                	beqz	a4,800051ba <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051a6:	2505                	addiw	a0,a0,1
    800051a8:	07a1                	addi	a5,a5,8
    800051aa:	fed51ce3          	bne	a0,a3,800051a2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051ae:	557d                	li	a0,-1
}
    800051b0:	60e2                	ld	ra,24(sp)
    800051b2:	6442                	ld	s0,16(sp)
    800051b4:	64a2                	ld	s1,8(sp)
    800051b6:	6105                	addi	sp,sp,32
    800051b8:	8082                	ret
      p->ofile[fd] = f;
    800051ba:	01a50793          	addi	a5,a0,26
    800051be:	078e                	slli	a5,a5,0x3
    800051c0:	963e                	add	a2,a2,a5
    800051c2:	e204                	sd	s1,0(a2)
      return fd;
    800051c4:	b7f5                	j	800051b0 <fdalloc+0x2c>

00000000800051c6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051c6:	715d                	addi	sp,sp,-80
    800051c8:	e486                	sd	ra,72(sp)
    800051ca:	e0a2                	sd	s0,64(sp)
    800051cc:	fc26                	sd	s1,56(sp)
    800051ce:	f84a                	sd	s2,48(sp)
    800051d0:	f44e                	sd	s3,40(sp)
    800051d2:	f052                	sd	s4,32(sp)
    800051d4:	ec56                	sd	s5,24(sp)
    800051d6:	0880                	addi	s0,sp,80
    800051d8:	89ae                	mv	s3,a1
    800051da:	8ab2                	mv	s5,a2
    800051dc:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051de:	fb040593          	addi	a1,s0,-80
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	e86080e7          	jalr	-378(ra) # 80004068 <nameiparent>
    800051ea:	892a                	mv	s2,a0
    800051ec:	12050f63          	beqz	a0,8000532a <create+0x164>
    return 0;

  ilock(dp);
    800051f0:	ffffe097          	auipc	ra,0xffffe
    800051f4:	6a4080e7          	jalr	1700(ra) # 80003894 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051f8:	4601                	li	a2,0
    800051fa:	fb040593          	addi	a1,s0,-80
    800051fe:	854a                	mv	a0,s2
    80005200:	fffff097          	auipc	ra,0xfffff
    80005204:	b78080e7          	jalr	-1160(ra) # 80003d78 <dirlookup>
    80005208:	84aa                	mv	s1,a0
    8000520a:	c921                	beqz	a0,8000525a <create+0x94>
    iunlockput(dp);
    8000520c:	854a                	mv	a0,s2
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	8e8080e7          	jalr	-1816(ra) # 80003af6 <iunlockput>
    ilock(ip);
    80005216:	8526                	mv	a0,s1
    80005218:	ffffe097          	auipc	ra,0xffffe
    8000521c:	67c080e7          	jalr	1660(ra) # 80003894 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005220:	2981                	sext.w	s3,s3
    80005222:	4789                	li	a5,2
    80005224:	02f99463          	bne	s3,a5,8000524c <create+0x86>
    80005228:	0444d783          	lhu	a5,68(s1)
    8000522c:	37f9                	addiw	a5,a5,-2
    8000522e:	17c2                	slli	a5,a5,0x30
    80005230:	93c1                	srli	a5,a5,0x30
    80005232:	4705                	li	a4,1
    80005234:	00f76c63          	bltu	a4,a5,8000524c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005238:	8526                	mv	a0,s1
    8000523a:	60a6                	ld	ra,72(sp)
    8000523c:	6406                	ld	s0,64(sp)
    8000523e:	74e2                	ld	s1,56(sp)
    80005240:	7942                	ld	s2,48(sp)
    80005242:	79a2                	ld	s3,40(sp)
    80005244:	7a02                	ld	s4,32(sp)
    80005246:	6ae2                	ld	s5,24(sp)
    80005248:	6161                	addi	sp,sp,80
    8000524a:	8082                	ret
    iunlockput(ip);
    8000524c:	8526                	mv	a0,s1
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	8a8080e7          	jalr	-1880(ra) # 80003af6 <iunlockput>
    return 0;
    80005256:	4481                	li	s1,0
    80005258:	b7c5                	j	80005238 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000525a:	85ce                	mv	a1,s3
    8000525c:	00092503          	lw	a0,0(s2)
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	49c080e7          	jalr	1180(ra) # 800036fc <ialloc>
    80005268:	84aa                	mv	s1,a0
    8000526a:	c529                	beqz	a0,800052b4 <create+0xee>
  ilock(ip);
    8000526c:	ffffe097          	auipc	ra,0xffffe
    80005270:	628080e7          	jalr	1576(ra) # 80003894 <ilock>
  ip->major = major;
    80005274:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005278:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000527c:	4785                	li	a5,1
    8000527e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005282:	8526                	mv	a0,s1
    80005284:	ffffe097          	auipc	ra,0xffffe
    80005288:	546080e7          	jalr	1350(ra) # 800037ca <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000528c:	2981                	sext.w	s3,s3
    8000528e:	4785                	li	a5,1
    80005290:	02f98a63          	beq	s3,a5,800052c4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005294:	40d0                	lw	a2,4(s1)
    80005296:	fb040593          	addi	a1,s0,-80
    8000529a:	854a                	mv	a0,s2
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	cec080e7          	jalr	-788(ra) # 80003f88 <dirlink>
    800052a4:	06054b63          	bltz	a0,8000531a <create+0x154>
  iunlockput(dp);
    800052a8:	854a                	mv	a0,s2
    800052aa:	fffff097          	auipc	ra,0xfffff
    800052ae:	84c080e7          	jalr	-1972(ra) # 80003af6 <iunlockput>
  return ip;
    800052b2:	b759                	j	80005238 <create+0x72>
    panic("create: ialloc");
    800052b4:	00003517          	auipc	a0,0x3
    800052b8:	48450513          	addi	a0,a0,1156 # 80008738 <syscalls+0x2b0>
    800052bc:	ffffb097          	auipc	ra,0xffffb
    800052c0:	282080e7          	jalr	642(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800052c4:	04a95783          	lhu	a5,74(s2)
    800052c8:	2785                	addiw	a5,a5,1
    800052ca:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052ce:	854a                	mv	a0,s2
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	4fa080e7          	jalr	1274(ra) # 800037ca <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052d8:	40d0                	lw	a2,4(s1)
    800052da:	00003597          	auipc	a1,0x3
    800052de:	46e58593          	addi	a1,a1,1134 # 80008748 <syscalls+0x2c0>
    800052e2:	8526                	mv	a0,s1
    800052e4:	fffff097          	auipc	ra,0xfffff
    800052e8:	ca4080e7          	jalr	-860(ra) # 80003f88 <dirlink>
    800052ec:	00054f63          	bltz	a0,8000530a <create+0x144>
    800052f0:	00492603          	lw	a2,4(s2)
    800052f4:	00003597          	auipc	a1,0x3
    800052f8:	45c58593          	addi	a1,a1,1116 # 80008750 <syscalls+0x2c8>
    800052fc:	8526                	mv	a0,s1
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	c8a080e7          	jalr	-886(ra) # 80003f88 <dirlink>
    80005306:	f80557e3          	bgez	a0,80005294 <create+0xce>
      panic("create dots");
    8000530a:	00003517          	auipc	a0,0x3
    8000530e:	44e50513          	addi	a0,a0,1102 # 80008758 <syscalls+0x2d0>
    80005312:	ffffb097          	auipc	ra,0xffffb
    80005316:	22c080e7          	jalr	556(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000531a:	00003517          	auipc	a0,0x3
    8000531e:	44e50513          	addi	a0,a0,1102 # 80008768 <syscalls+0x2e0>
    80005322:	ffffb097          	auipc	ra,0xffffb
    80005326:	21c080e7          	jalr	540(ra) # 8000053e <panic>
    return 0;
    8000532a:	84aa                	mv	s1,a0
    8000532c:	b731                	j	80005238 <create+0x72>

000000008000532e <sys_dup>:
{
    8000532e:	7179                	addi	sp,sp,-48
    80005330:	f406                	sd	ra,40(sp)
    80005332:	f022                	sd	s0,32(sp)
    80005334:	ec26                	sd	s1,24(sp)
    80005336:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005338:	fd840613          	addi	a2,s0,-40
    8000533c:	4581                	li	a1,0
    8000533e:	4501                	li	a0,0
    80005340:	00000097          	auipc	ra,0x0
    80005344:	ddc080e7          	jalr	-548(ra) # 8000511c <argfd>
    return -1;
    80005348:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000534a:	02054363          	bltz	a0,80005370 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000534e:	fd843503          	ld	a0,-40(s0)
    80005352:	00000097          	auipc	ra,0x0
    80005356:	e32080e7          	jalr	-462(ra) # 80005184 <fdalloc>
    8000535a:	84aa                	mv	s1,a0
    return -1;
    8000535c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000535e:	00054963          	bltz	a0,80005370 <sys_dup+0x42>
  filedup(f);
    80005362:	fd843503          	ld	a0,-40(s0)
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	37a080e7          	jalr	890(ra) # 800046e0 <filedup>
  return fd;
    8000536e:	87a6                	mv	a5,s1
}
    80005370:	853e                	mv	a0,a5
    80005372:	70a2                	ld	ra,40(sp)
    80005374:	7402                	ld	s0,32(sp)
    80005376:	64e2                	ld	s1,24(sp)
    80005378:	6145                	addi	sp,sp,48
    8000537a:	8082                	ret

000000008000537c <sys_read>:
{
    8000537c:	7179                	addi	sp,sp,-48
    8000537e:	f406                	sd	ra,40(sp)
    80005380:	f022                	sd	s0,32(sp)
    80005382:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005384:	fe840613          	addi	a2,s0,-24
    80005388:	4581                	li	a1,0
    8000538a:	4501                	li	a0,0
    8000538c:	00000097          	auipc	ra,0x0
    80005390:	d90080e7          	jalr	-624(ra) # 8000511c <argfd>
    return -1;
    80005394:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005396:	04054163          	bltz	a0,800053d8 <sys_read+0x5c>
    8000539a:	fe440593          	addi	a1,s0,-28
    8000539e:	4509                	li	a0,2
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	938080e7          	jalr	-1736(ra) # 80002cd8 <argint>
    return -1;
    800053a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053aa:	02054763          	bltz	a0,800053d8 <sys_read+0x5c>
    800053ae:	fd840593          	addi	a1,s0,-40
    800053b2:	4505                	li	a0,1
    800053b4:	ffffe097          	auipc	ra,0xffffe
    800053b8:	946080e7          	jalr	-1722(ra) # 80002cfa <argaddr>
    return -1;
    800053bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053be:	00054d63          	bltz	a0,800053d8 <sys_read+0x5c>
  return fileread(f, p, n);
    800053c2:	fe442603          	lw	a2,-28(s0)
    800053c6:	fd843583          	ld	a1,-40(s0)
    800053ca:	fe843503          	ld	a0,-24(s0)
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	49e080e7          	jalr	1182(ra) # 8000486c <fileread>
    800053d6:	87aa                	mv	a5,a0
}
    800053d8:	853e                	mv	a0,a5
    800053da:	70a2                	ld	ra,40(sp)
    800053dc:	7402                	ld	s0,32(sp)
    800053de:	6145                	addi	sp,sp,48
    800053e0:	8082                	ret

00000000800053e2 <sys_write>:
{
    800053e2:	7179                	addi	sp,sp,-48
    800053e4:	f406                	sd	ra,40(sp)
    800053e6:	f022                	sd	s0,32(sp)
    800053e8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ea:	fe840613          	addi	a2,s0,-24
    800053ee:	4581                	li	a1,0
    800053f0:	4501                	li	a0,0
    800053f2:	00000097          	auipc	ra,0x0
    800053f6:	d2a080e7          	jalr	-726(ra) # 8000511c <argfd>
    return -1;
    800053fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fc:	04054163          	bltz	a0,8000543e <sys_write+0x5c>
    80005400:	fe440593          	addi	a1,s0,-28
    80005404:	4509                	li	a0,2
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	8d2080e7          	jalr	-1838(ra) # 80002cd8 <argint>
    return -1;
    8000540e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005410:	02054763          	bltz	a0,8000543e <sys_write+0x5c>
    80005414:	fd840593          	addi	a1,s0,-40
    80005418:	4505                	li	a0,1
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	8e0080e7          	jalr	-1824(ra) # 80002cfa <argaddr>
    return -1;
    80005422:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005424:	00054d63          	bltz	a0,8000543e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005428:	fe442603          	lw	a2,-28(s0)
    8000542c:	fd843583          	ld	a1,-40(s0)
    80005430:	fe843503          	ld	a0,-24(s0)
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	4fa080e7          	jalr	1274(ra) # 8000492e <filewrite>
    8000543c:	87aa                	mv	a5,a0
}
    8000543e:	853e                	mv	a0,a5
    80005440:	70a2                	ld	ra,40(sp)
    80005442:	7402                	ld	s0,32(sp)
    80005444:	6145                	addi	sp,sp,48
    80005446:	8082                	ret

0000000080005448 <sys_close>:
{
    80005448:	1101                	addi	sp,sp,-32
    8000544a:	ec06                	sd	ra,24(sp)
    8000544c:	e822                	sd	s0,16(sp)
    8000544e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005450:	fe040613          	addi	a2,s0,-32
    80005454:	fec40593          	addi	a1,s0,-20
    80005458:	4501                	li	a0,0
    8000545a:	00000097          	auipc	ra,0x0
    8000545e:	cc2080e7          	jalr	-830(ra) # 8000511c <argfd>
    return -1;
    80005462:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005464:	02054463          	bltz	a0,8000548c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005468:	ffffc097          	auipc	ra,0xffffc
    8000546c:	67a080e7          	jalr	1658(ra) # 80001ae2 <myproc>
    80005470:	fec42783          	lw	a5,-20(s0)
    80005474:	07e9                	addi	a5,a5,26
    80005476:	078e                	slli	a5,a5,0x3
    80005478:	97aa                	add	a5,a5,a0
    8000547a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000547e:	fe043503          	ld	a0,-32(s0)
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	2b0080e7          	jalr	688(ra) # 80004732 <fileclose>
  return 0;
    8000548a:	4781                	li	a5,0
}
    8000548c:	853e                	mv	a0,a5
    8000548e:	60e2                	ld	ra,24(sp)
    80005490:	6442                	ld	s0,16(sp)
    80005492:	6105                	addi	sp,sp,32
    80005494:	8082                	ret

0000000080005496 <sys_fstat>:
{
    80005496:	1101                	addi	sp,sp,-32
    80005498:	ec06                	sd	ra,24(sp)
    8000549a:	e822                	sd	s0,16(sp)
    8000549c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000549e:	fe840613          	addi	a2,s0,-24
    800054a2:	4581                	li	a1,0
    800054a4:	4501                	li	a0,0
    800054a6:	00000097          	auipc	ra,0x0
    800054aa:	c76080e7          	jalr	-906(ra) # 8000511c <argfd>
    return -1;
    800054ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054b0:	02054563          	bltz	a0,800054da <sys_fstat+0x44>
    800054b4:	fe040593          	addi	a1,s0,-32
    800054b8:	4505                	li	a0,1
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	840080e7          	jalr	-1984(ra) # 80002cfa <argaddr>
    return -1;
    800054c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054c4:	00054b63          	bltz	a0,800054da <sys_fstat+0x44>
  return filestat(f, st);
    800054c8:	fe043583          	ld	a1,-32(s0)
    800054cc:	fe843503          	ld	a0,-24(s0)
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	32a080e7          	jalr	810(ra) # 800047fa <filestat>
    800054d8:	87aa                	mv	a5,a0
}
    800054da:	853e                	mv	a0,a5
    800054dc:	60e2                	ld	ra,24(sp)
    800054de:	6442                	ld	s0,16(sp)
    800054e0:	6105                	addi	sp,sp,32
    800054e2:	8082                	ret

00000000800054e4 <sys_link>:
{
    800054e4:	7169                	addi	sp,sp,-304
    800054e6:	f606                	sd	ra,296(sp)
    800054e8:	f222                	sd	s0,288(sp)
    800054ea:	ee26                	sd	s1,280(sp)
    800054ec:	ea4a                	sd	s2,272(sp)
    800054ee:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054f0:	08000613          	li	a2,128
    800054f4:	ed040593          	addi	a1,s0,-304
    800054f8:	4501                	li	a0,0
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	822080e7          	jalr	-2014(ra) # 80002d1c <argstr>
    return -1;
    80005502:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005504:	10054e63          	bltz	a0,80005620 <sys_link+0x13c>
    80005508:	08000613          	li	a2,128
    8000550c:	f5040593          	addi	a1,s0,-176
    80005510:	4505                	li	a0,1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	80a080e7          	jalr	-2038(ra) # 80002d1c <argstr>
    return -1;
    8000551a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000551c:	10054263          	bltz	a0,80005620 <sys_link+0x13c>
  begin_op();
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	d46080e7          	jalr	-698(ra) # 80004266 <begin_op>
  if((ip = namei(old)) == 0){
    80005528:	ed040513          	addi	a0,s0,-304
    8000552c:	fffff097          	auipc	ra,0xfffff
    80005530:	b1e080e7          	jalr	-1250(ra) # 8000404a <namei>
    80005534:	84aa                	mv	s1,a0
    80005536:	c551                	beqz	a0,800055c2 <sys_link+0xde>
  ilock(ip);
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	35c080e7          	jalr	860(ra) # 80003894 <ilock>
  if(ip->type == T_DIR){
    80005540:	04449703          	lh	a4,68(s1)
    80005544:	4785                	li	a5,1
    80005546:	08f70463          	beq	a4,a5,800055ce <sys_link+0xea>
  ip->nlink++;
    8000554a:	04a4d783          	lhu	a5,74(s1)
    8000554e:	2785                	addiw	a5,a5,1
    80005550:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005554:	8526                	mv	a0,s1
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	274080e7          	jalr	628(ra) # 800037ca <iupdate>
  iunlock(ip);
    8000555e:	8526                	mv	a0,s1
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	3f6080e7          	jalr	1014(ra) # 80003956 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005568:	fd040593          	addi	a1,s0,-48
    8000556c:	f5040513          	addi	a0,s0,-176
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	af8080e7          	jalr	-1288(ra) # 80004068 <nameiparent>
    80005578:	892a                	mv	s2,a0
    8000557a:	c935                	beqz	a0,800055ee <sys_link+0x10a>
  ilock(dp);
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	318080e7          	jalr	792(ra) # 80003894 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005584:	00092703          	lw	a4,0(s2)
    80005588:	409c                	lw	a5,0(s1)
    8000558a:	04f71d63          	bne	a4,a5,800055e4 <sys_link+0x100>
    8000558e:	40d0                	lw	a2,4(s1)
    80005590:	fd040593          	addi	a1,s0,-48
    80005594:	854a                	mv	a0,s2
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	9f2080e7          	jalr	-1550(ra) # 80003f88 <dirlink>
    8000559e:	04054363          	bltz	a0,800055e4 <sys_link+0x100>
  iunlockput(dp);
    800055a2:	854a                	mv	a0,s2
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	552080e7          	jalr	1362(ra) # 80003af6 <iunlockput>
  iput(ip);
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	4a0080e7          	jalr	1184(ra) # 80003a4e <iput>
  end_op();
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	d30080e7          	jalr	-720(ra) # 800042e6 <end_op>
  return 0;
    800055be:	4781                	li	a5,0
    800055c0:	a085                	j	80005620 <sys_link+0x13c>
    end_op();
    800055c2:	fffff097          	auipc	ra,0xfffff
    800055c6:	d24080e7          	jalr	-732(ra) # 800042e6 <end_op>
    return -1;
    800055ca:	57fd                	li	a5,-1
    800055cc:	a891                	j	80005620 <sys_link+0x13c>
    iunlockput(ip);
    800055ce:	8526                	mv	a0,s1
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	526080e7          	jalr	1318(ra) # 80003af6 <iunlockput>
    end_op();
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	d0e080e7          	jalr	-754(ra) # 800042e6 <end_op>
    return -1;
    800055e0:	57fd                	li	a5,-1
    800055e2:	a83d                	j	80005620 <sys_link+0x13c>
    iunlockput(dp);
    800055e4:	854a                	mv	a0,s2
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	510080e7          	jalr	1296(ra) # 80003af6 <iunlockput>
  ilock(ip);
    800055ee:	8526                	mv	a0,s1
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	2a4080e7          	jalr	676(ra) # 80003894 <ilock>
  ip->nlink--;
    800055f8:	04a4d783          	lhu	a5,74(s1)
    800055fc:	37fd                	addiw	a5,a5,-1
    800055fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005602:	8526                	mv	a0,s1
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	1c6080e7          	jalr	454(ra) # 800037ca <iupdate>
  iunlockput(ip);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	4e8080e7          	jalr	1256(ra) # 80003af6 <iunlockput>
  end_op();
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	cd0080e7          	jalr	-816(ra) # 800042e6 <end_op>
  return -1;
    8000561e:	57fd                	li	a5,-1
}
    80005620:	853e                	mv	a0,a5
    80005622:	70b2                	ld	ra,296(sp)
    80005624:	7412                	ld	s0,288(sp)
    80005626:	64f2                	ld	s1,280(sp)
    80005628:	6952                	ld	s2,272(sp)
    8000562a:	6155                	addi	sp,sp,304
    8000562c:	8082                	ret

000000008000562e <sys_unlink>:
{
    8000562e:	7151                	addi	sp,sp,-240
    80005630:	f586                	sd	ra,232(sp)
    80005632:	f1a2                	sd	s0,224(sp)
    80005634:	eda6                	sd	s1,216(sp)
    80005636:	e9ca                	sd	s2,208(sp)
    80005638:	e5ce                	sd	s3,200(sp)
    8000563a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000563c:	08000613          	li	a2,128
    80005640:	f3040593          	addi	a1,s0,-208
    80005644:	4501                	li	a0,0
    80005646:	ffffd097          	auipc	ra,0xffffd
    8000564a:	6d6080e7          	jalr	1750(ra) # 80002d1c <argstr>
    8000564e:	18054163          	bltz	a0,800057d0 <sys_unlink+0x1a2>
  begin_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	c14080e7          	jalr	-1004(ra) # 80004266 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000565a:	fb040593          	addi	a1,s0,-80
    8000565e:	f3040513          	addi	a0,s0,-208
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	a06080e7          	jalr	-1530(ra) # 80004068 <nameiparent>
    8000566a:	84aa                	mv	s1,a0
    8000566c:	c979                	beqz	a0,80005742 <sys_unlink+0x114>
  ilock(dp);
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	226080e7          	jalr	550(ra) # 80003894 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005676:	00003597          	auipc	a1,0x3
    8000567a:	0d258593          	addi	a1,a1,210 # 80008748 <syscalls+0x2c0>
    8000567e:	fb040513          	addi	a0,s0,-80
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	6dc080e7          	jalr	1756(ra) # 80003d5e <namecmp>
    8000568a:	14050a63          	beqz	a0,800057de <sys_unlink+0x1b0>
    8000568e:	00003597          	auipc	a1,0x3
    80005692:	0c258593          	addi	a1,a1,194 # 80008750 <syscalls+0x2c8>
    80005696:	fb040513          	addi	a0,s0,-80
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	6c4080e7          	jalr	1732(ra) # 80003d5e <namecmp>
    800056a2:	12050e63          	beqz	a0,800057de <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056a6:	f2c40613          	addi	a2,s0,-212
    800056aa:	fb040593          	addi	a1,s0,-80
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	6c8080e7          	jalr	1736(ra) # 80003d78 <dirlookup>
    800056b8:	892a                	mv	s2,a0
    800056ba:	12050263          	beqz	a0,800057de <sys_unlink+0x1b0>
  ilock(ip);
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	1d6080e7          	jalr	470(ra) # 80003894 <ilock>
  if(ip->nlink < 1)
    800056c6:	04a91783          	lh	a5,74(s2)
    800056ca:	08f05263          	blez	a5,8000574e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056ce:	04491703          	lh	a4,68(s2)
    800056d2:	4785                	li	a5,1
    800056d4:	08f70563          	beq	a4,a5,8000575e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056d8:	4641                	li	a2,16
    800056da:	4581                	li	a1,0
    800056dc:	fc040513          	addi	a0,s0,-64
    800056e0:	ffffb097          	auipc	ra,0xffffb
    800056e4:	600080e7          	jalr	1536(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056e8:	4741                	li	a4,16
    800056ea:	f2c42683          	lw	a3,-212(s0)
    800056ee:	fc040613          	addi	a2,s0,-64
    800056f2:	4581                	li	a1,0
    800056f4:	8526                	mv	a0,s1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	54a080e7          	jalr	1354(ra) # 80003c40 <writei>
    800056fe:	47c1                	li	a5,16
    80005700:	0af51563          	bne	a0,a5,800057aa <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005704:	04491703          	lh	a4,68(s2)
    80005708:	4785                	li	a5,1
    8000570a:	0af70863          	beq	a4,a5,800057ba <sys_unlink+0x18c>
  iunlockput(dp);
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	3e6080e7          	jalr	998(ra) # 80003af6 <iunlockput>
  ip->nlink--;
    80005718:	04a95783          	lhu	a5,74(s2)
    8000571c:	37fd                	addiw	a5,a5,-1
    8000571e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005722:	854a                	mv	a0,s2
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	0a6080e7          	jalr	166(ra) # 800037ca <iupdate>
  iunlockput(ip);
    8000572c:	854a                	mv	a0,s2
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	3c8080e7          	jalr	968(ra) # 80003af6 <iunlockput>
  end_op();
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	bb0080e7          	jalr	-1104(ra) # 800042e6 <end_op>
  return 0;
    8000573e:	4501                	li	a0,0
    80005740:	a84d                	j	800057f2 <sys_unlink+0x1c4>
    end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	ba4080e7          	jalr	-1116(ra) # 800042e6 <end_op>
    return -1;
    8000574a:	557d                	li	a0,-1
    8000574c:	a05d                	j	800057f2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000574e:	00003517          	auipc	a0,0x3
    80005752:	02a50513          	addi	a0,a0,42 # 80008778 <syscalls+0x2f0>
    80005756:	ffffb097          	auipc	ra,0xffffb
    8000575a:	de8080e7          	jalr	-536(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000575e:	04c92703          	lw	a4,76(s2)
    80005762:	02000793          	li	a5,32
    80005766:	f6e7f9e3          	bgeu	a5,a4,800056d8 <sys_unlink+0xaa>
    8000576a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000576e:	4741                	li	a4,16
    80005770:	86ce                	mv	a3,s3
    80005772:	f1840613          	addi	a2,s0,-232
    80005776:	4581                	li	a1,0
    80005778:	854a                	mv	a0,s2
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	3ce080e7          	jalr	974(ra) # 80003b48 <readi>
    80005782:	47c1                	li	a5,16
    80005784:	00f51b63          	bne	a0,a5,8000579a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005788:	f1845783          	lhu	a5,-232(s0)
    8000578c:	e7a1                	bnez	a5,800057d4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000578e:	29c1                	addiw	s3,s3,16
    80005790:	04c92783          	lw	a5,76(s2)
    80005794:	fcf9ede3          	bltu	s3,a5,8000576e <sys_unlink+0x140>
    80005798:	b781                	j	800056d8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000579a:	00003517          	auipc	a0,0x3
    8000579e:	ff650513          	addi	a0,a0,-10 # 80008790 <syscalls+0x308>
    800057a2:	ffffb097          	auipc	ra,0xffffb
    800057a6:	d9c080e7          	jalr	-612(ra) # 8000053e <panic>
    panic("unlink: writei");
    800057aa:	00003517          	auipc	a0,0x3
    800057ae:	ffe50513          	addi	a0,a0,-2 # 800087a8 <syscalls+0x320>
    800057b2:	ffffb097          	auipc	ra,0xffffb
    800057b6:	d8c080e7          	jalr	-628(ra) # 8000053e <panic>
    dp->nlink--;
    800057ba:	04a4d783          	lhu	a5,74(s1)
    800057be:	37fd                	addiw	a5,a5,-1
    800057c0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057c4:	8526                	mv	a0,s1
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	004080e7          	jalr	4(ra) # 800037ca <iupdate>
    800057ce:	b781                	j	8000570e <sys_unlink+0xe0>
    return -1;
    800057d0:	557d                	li	a0,-1
    800057d2:	a005                	j	800057f2 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057d4:	854a                	mv	a0,s2
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	320080e7          	jalr	800(ra) # 80003af6 <iunlockput>
  iunlockput(dp);
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	316080e7          	jalr	790(ra) # 80003af6 <iunlockput>
  end_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	afe080e7          	jalr	-1282(ra) # 800042e6 <end_op>
  return -1;
    800057f0:	557d                	li	a0,-1
}
    800057f2:	70ae                	ld	ra,232(sp)
    800057f4:	740e                	ld	s0,224(sp)
    800057f6:	64ee                	ld	s1,216(sp)
    800057f8:	694e                	ld	s2,208(sp)
    800057fa:	69ae                	ld	s3,200(sp)
    800057fc:	616d                	addi	sp,sp,240
    800057fe:	8082                	ret

0000000080005800 <sys_open>:

uint64
sys_open(void)
{
    80005800:	7131                	addi	sp,sp,-192
    80005802:	fd06                	sd	ra,184(sp)
    80005804:	f922                	sd	s0,176(sp)
    80005806:	f526                	sd	s1,168(sp)
    80005808:	f14a                	sd	s2,160(sp)
    8000580a:	ed4e                	sd	s3,152(sp)
    8000580c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000580e:	08000613          	li	a2,128
    80005812:	f5040593          	addi	a1,s0,-176
    80005816:	4501                	li	a0,0
    80005818:	ffffd097          	auipc	ra,0xffffd
    8000581c:	504080e7          	jalr	1284(ra) # 80002d1c <argstr>
    return -1;
    80005820:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005822:	0c054163          	bltz	a0,800058e4 <sys_open+0xe4>
    80005826:	f4c40593          	addi	a1,s0,-180
    8000582a:	4505                	li	a0,1
    8000582c:	ffffd097          	auipc	ra,0xffffd
    80005830:	4ac080e7          	jalr	1196(ra) # 80002cd8 <argint>
    80005834:	0a054863          	bltz	a0,800058e4 <sys_open+0xe4>

  begin_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	a2e080e7          	jalr	-1490(ra) # 80004266 <begin_op>

  if(omode & O_CREATE){
    80005840:	f4c42783          	lw	a5,-180(s0)
    80005844:	2007f793          	andi	a5,a5,512
    80005848:	cbdd                	beqz	a5,800058fe <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000584a:	4681                	li	a3,0
    8000584c:	4601                	li	a2,0
    8000584e:	4589                	li	a1,2
    80005850:	f5040513          	addi	a0,s0,-176
    80005854:	00000097          	auipc	ra,0x0
    80005858:	972080e7          	jalr	-1678(ra) # 800051c6 <create>
    8000585c:	892a                	mv	s2,a0
    if(ip == 0){
    8000585e:	c959                	beqz	a0,800058f4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005860:	04491703          	lh	a4,68(s2)
    80005864:	478d                	li	a5,3
    80005866:	00f71763          	bne	a4,a5,80005874 <sys_open+0x74>
    8000586a:	04695703          	lhu	a4,70(s2)
    8000586e:	47a5                	li	a5,9
    80005870:	0ce7ec63          	bltu	a5,a4,80005948 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	e02080e7          	jalr	-510(ra) # 80004676 <filealloc>
    8000587c:	89aa                	mv	s3,a0
    8000587e:	10050263          	beqz	a0,80005982 <sys_open+0x182>
    80005882:	00000097          	auipc	ra,0x0
    80005886:	902080e7          	jalr	-1790(ra) # 80005184 <fdalloc>
    8000588a:	84aa                	mv	s1,a0
    8000588c:	0e054663          	bltz	a0,80005978 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005890:	04491703          	lh	a4,68(s2)
    80005894:	478d                	li	a5,3
    80005896:	0cf70463          	beq	a4,a5,8000595e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000589a:	4789                	li	a5,2
    8000589c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058a0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058a4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058a8:	f4c42783          	lw	a5,-180(s0)
    800058ac:	0017c713          	xori	a4,a5,1
    800058b0:	8b05                	andi	a4,a4,1
    800058b2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058b6:	0037f713          	andi	a4,a5,3
    800058ba:	00e03733          	snez	a4,a4
    800058be:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058c2:	4007f793          	andi	a5,a5,1024
    800058c6:	c791                	beqz	a5,800058d2 <sys_open+0xd2>
    800058c8:	04491703          	lh	a4,68(s2)
    800058cc:	4789                	li	a5,2
    800058ce:	08f70f63          	beq	a4,a5,8000596c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	082080e7          	jalr	130(ra) # 80003956 <iunlock>
  end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	a0a080e7          	jalr	-1526(ra) # 800042e6 <end_op>

  return fd;
}
    800058e4:	8526                	mv	a0,s1
    800058e6:	70ea                	ld	ra,184(sp)
    800058e8:	744a                	ld	s0,176(sp)
    800058ea:	74aa                	ld	s1,168(sp)
    800058ec:	790a                	ld	s2,160(sp)
    800058ee:	69ea                	ld	s3,152(sp)
    800058f0:	6129                	addi	sp,sp,192
    800058f2:	8082                	ret
      end_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	9f2080e7          	jalr	-1550(ra) # 800042e6 <end_op>
      return -1;
    800058fc:	b7e5                	j	800058e4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058fe:	f5040513          	addi	a0,s0,-176
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	748080e7          	jalr	1864(ra) # 8000404a <namei>
    8000590a:	892a                	mv	s2,a0
    8000590c:	c905                	beqz	a0,8000593c <sys_open+0x13c>
    ilock(ip);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	f86080e7          	jalr	-122(ra) # 80003894 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005916:	04491703          	lh	a4,68(s2)
    8000591a:	4785                	li	a5,1
    8000591c:	f4f712e3          	bne	a4,a5,80005860 <sys_open+0x60>
    80005920:	f4c42783          	lw	a5,-180(s0)
    80005924:	dba1                	beqz	a5,80005874 <sys_open+0x74>
      iunlockput(ip);
    80005926:	854a                	mv	a0,s2
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	1ce080e7          	jalr	462(ra) # 80003af6 <iunlockput>
      end_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	9b6080e7          	jalr	-1610(ra) # 800042e6 <end_op>
      return -1;
    80005938:	54fd                	li	s1,-1
    8000593a:	b76d                	j	800058e4 <sys_open+0xe4>
      end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	9aa080e7          	jalr	-1622(ra) # 800042e6 <end_op>
      return -1;
    80005944:	54fd                	li	s1,-1
    80005946:	bf79                	j	800058e4 <sys_open+0xe4>
    iunlockput(ip);
    80005948:	854a                	mv	a0,s2
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	1ac080e7          	jalr	428(ra) # 80003af6 <iunlockput>
    end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	994080e7          	jalr	-1644(ra) # 800042e6 <end_op>
    return -1;
    8000595a:	54fd                	li	s1,-1
    8000595c:	b761                	j	800058e4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000595e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005962:	04691783          	lh	a5,70(s2)
    80005966:	02f99223          	sh	a5,36(s3)
    8000596a:	bf2d                	j	800058a4 <sys_open+0xa4>
    itrunc(ip);
    8000596c:	854a                	mv	a0,s2
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	034080e7          	jalr	52(ra) # 800039a2 <itrunc>
    80005976:	bfb1                	j	800058d2 <sys_open+0xd2>
      fileclose(f);
    80005978:	854e                	mv	a0,s3
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	db8080e7          	jalr	-584(ra) # 80004732 <fileclose>
    iunlockput(ip);
    80005982:	854a                	mv	a0,s2
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	172080e7          	jalr	370(ra) # 80003af6 <iunlockput>
    end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	95a080e7          	jalr	-1702(ra) # 800042e6 <end_op>
    return -1;
    80005994:	54fd                	li	s1,-1
    80005996:	b7b9                	j	800058e4 <sys_open+0xe4>

0000000080005998 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005998:	7175                	addi	sp,sp,-144
    8000599a:	e506                	sd	ra,136(sp)
    8000599c:	e122                	sd	s0,128(sp)
    8000599e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	8c6080e7          	jalr	-1850(ra) # 80004266 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059a8:	08000613          	li	a2,128
    800059ac:	f7040593          	addi	a1,s0,-144
    800059b0:	4501                	li	a0,0
    800059b2:	ffffd097          	auipc	ra,0xffffd
    800059b6:	36a080e7          	jalr	874(ra) # 80002d1c <argstr>
    800059ba:	02054963          	bltz	a0,800059ec <sys_mkdir+0x54>
    800059be:	4681                	li	a3,0
    800059c0:	4601                	li	a2,0
    800059c2:	4585                	li	a1,1
    800059c4:	f7040513          	addi	a0,s0,-144
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	7fe080e7          	jalr	2046(ra) # 800051c6 <create>
    800059d0:	cd11                	beqz	a0,800059ec <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	124080e7          	jalr	292(ra) # 80003af6 <iunlockput>
  end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	90c080e7          	jalr	-1780(ra) # 800042e6 <end_op>
  return 0;
    800059e2:	4501                	li	a0,0
}
    800059e4:	60aa                	ld	ra,136(sp)
    800059e6:	640a                	ld	s0,128(sp)
    800059e8:	6149                	addi	sp,sp,144
    800059ea:	8082                	ret
    end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	8fa080e7          	jalr	-1798(ra) # 800042e6 <end_op>
    return -1;
    800059f4:	557d                	li	a0,-1
    800059f6:	b7fd                	j	800059e4 <sys_mkdir+0x4c>

00000000800059f8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059f8:	7135                	addi	sp,sp,-160
    800059fa:	ed06                	sd	ra,152(sp)
    800059fc:	e922                	sd	s0,144(sp)
    800059fe:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	866080e7          	jalr	-1946(ra) # 80004266 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a08:	08000613          	li	a2,128
    80005a0c:	f7040593          	addi	a1,s0,-144
    80005a10:	4501                	li	a0,0
    80005a12:	ffffd097          	auipc	ra,0xffffd
    80005a16:	30a080e7          	jalr	778(ra) # 80002d1c <argstr>
    80005a1a:	04054a63          	bltz	a0,80005a6e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a1e:	f6c40593          	addi	a1,s0,-148
    80005a22:	4505                	li	a0,1
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	2b4080e7          	jalr	692(ra) # 80002cd8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a2c:	04054163          	bltz	a0,80005a6e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a30:	f6840593          	addi	a1,s0,-152
    80005a34:	4509                	li	a0,2
    80005a36:	ffffd097          	auipc	ra,0xffffd
    80005a3a:	2a2080e7          	jalr	674(ra) # 80002cd8 <argint>
     argint(1, &major) < 0 ||
    80005a3e:	02054863          	bltz	a0,80005a6e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a42:	f6841683          	lh	a3,-152(s0)
    80005a46:	f6c41603          	lh	a2,-148(s0)
    80005a4a:	458d                	li	a1,3
    80005a4c:	f7040513          	addi	a0,s0,-144
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	776080e7          	jalr	1910(ra) # 800051c6 <create>
     argint(2, &minor) < 0 ||
    80005a58:	c919                	beqz	a0,80005a6e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	09c080e7          	jalr	156(ra) # 80003af6 <iunlockput>
  end_op();
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	884080e7          	jalr	-1916(ra) # 800042e6 <end_op>
  return 0;
    80005a6a:	4501                	li	a0,0
    80005a6c:	a031                	j	80005a78 <sys_mknod+0x80>
    end_op();
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	878080e7          	jalr	-1928(ra) # 800042e6 <end_op>
    return -1;
    80005a76:	557d                	li	a0,-1
}
    80005a78:	60ea                	ld	ra,152(sp)
    80005a7a:	644a                	ld	s0,144(sp)
    80005a7c:	610d                	addi	sp,sp,160
    80005a7e:	8082                	ret

0000000080005a80 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a80:	7135                	addi	sp,sp,-160
    80005a82:	ed06                	sd	ra,152(sp)
    80005a84:	e922                	sd	s0,144(sp)
    80005a86:	e526                	sd	s1,136(sp)
    80005a88:	e14a                	sd	s2,128(sp)
    80005a8a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a8c:	ffffc097          	auipc	ra,0xffffc
    80005a90:	056080e7          	jalr	86(ra) # 80001ae2 <myproc>
    80005a94:	892a                	mv	s2,a0
  
  begin_op();
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	7d0080e7          	jalr	2000(ra) # 80004266 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a9e:	08000613          	li	a2,128
    80005aa2:	f6040593          	addi	a1,s0,-160
    80005aa6:	4501                	li	a0,0
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	274080e7          	jalr	628(ra) # 80002d1c <argstr>
    80005ab0:	04054b63          	bltz	a0,80005b06 <sys_chdir+0x86>
    80005ab4:	f6040513          	addi	a0,s0,-160
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	592080e7          	jalr	1426(ra) # 8000404a <namei>
    80005ac0:	84aa                	mv	s1,a0
    80005ac2:	c131                	beqz	a0,80005b06 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	dd0080e7          	jalr	-560(ra) # 80003894 <ilock>
  if(ip->type != T_DIR){
    80005acc:	04449703          	lh	a4,68(s1)
    80005ad0:	4785                	li	a5,1
    80005ad2:	04f71063          	bne	a4,a5,80005b12 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ad6:	8526                	mv	a0,s1
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	e7e080e7          	jalr	-386(ra) # 80003956 <iunlock>
  iput(p->cwd);
    80005ae0:	15093503          	ld	a0,336(s2)
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	f6a080e7          	jalr	-150(ra) # 80003a4e <iput>
  end_op();
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	7fa080e7          	jalr	2042(ra) # 800042e6 <end_op>
  p->cwd = ip;
    80005af4:	14993823          	sd	s1,336(s2)
  return 0;
    80005af8:	4501                	li	a0,0
}
    80005afa:	60ea                	ld	ra,152(sp)
    80005afc:	644a                	ld	s0,144(sp)
    80005afe:	64aa                	ld	s1,136(sp)
    80005b00:	690a                	ld	s2,128(sp)
    80005b02:	610d                	addi	sp,sp,160
    80005b04:	8082                	ret
    end_op();
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	7e0080e7          	jalr	2016(ra) # 800042e6 <end_op>
    return -1;
    80005b0e:	557d                	li	a0,-1
    80005b10:	b7ed                	j	80005afa <sys_chdir+0x7a>
    iunlockput(ip);
    80005b12:	8526                	mv	a0,s1
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	fe2080e7          	jalr	-30(ra) # 80003af6 <iunlockput>
    end_op();
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	7ca080e7          	jalr	1994(ra) # 800042e6 <end_op>
    return -1;
    80005b24:	557d                	li	a0,-1
    80005b26:	bfd1                	j	80005afa <sys_chdir+0x7a>

0000000080005b28 <sys_exec>:

uint64
sys_exec(void)
{
    80005b28:	7145                	addi	sp,sp,-464
    80005b2a:	e786                	sd	ra,456(sp)
    80005b2c:	e3a2                	sd	s0,448(sp)
    80005b2e:	ff26                	sd	s1,440(sp)
    80005b30:	fb4a                	sd	s2,432(sp)
    80005b32:	f74e                	sd	s3,424(sp)
    80005b34:	f352                	sd	s4,416(sp)
    80005b36:	ef56                	sd	s5,408(sp)
    80005b38:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b3a:	08000613          	li	a2,128
    80005b3e:	f4040593          	addi	a1,s0,-192
    80005b42:	4501                	li	a0,0
    80005b44:	ffffd097          	auipc	ra,0xffffd
    80005b48:	1d8080e7          	jalr	472(ra) # 80002d1c <argstr>
    return -1;
    80005b4c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b4e:	0c054a63          	bltz	a0,80005c22 <sys_exec+0xfa>
    80005b52:	e3840593          	addi	a1,s0,-456
    80005b56:	4505                	li	a0,1
    80005b58:	ffffd097          	auipc	ra,0xffffd
    80005b5c:	1a2080e7          	jalr	418(ra) # 80002cfa <argaddr>
    80005b60:	0c054163          	bltz	a0,80005c22 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b64:	10000613          	li	a2,256
    80005b68:	4581                	li	a1,0
    80005b6a:	e4040513          	addi	a0,s0,-448
    80005b6e:	ffffb097          	auipc	ra,0xffffb
    80005b72:	172080e7          	jalr	370(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b76:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b7a:	89a6                	mv	s3,s1
    80005b7c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b7e:	02000a13          	li	s4,32
    80005b82:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b86:	00391513          	slli	a0,s2,0x3
    80005b8a:	e3040593          	addi	a1,s0,-464
    80005b8e:	e3843783          	ld	a5,-456(s0)
    80005b92:	953e                	add	a0,a0,a5
    80005b94:	ffffd097          	auipc	ra,0xffffd
    80005b98:	0aa080e7          	jalr	170(ra) # 80002c3e <fetchaddr>
    80005b9c:	02054a63          	bltz	a0,80005bd0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ba0:	e3043783          	ld	a5,-464(s0)
    80005ba4:	c3b9                	beqz	a5,80005bea <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ba6:	ffffb097          	auipc	ra,0xffffb
    80005baa:	f4e080e7          	jalr	-178(ra) # 80000af4 <kalloc>
    80005bae:	85aa                	mv	a1,a0
    80005bb0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bb4:	cd11                	beqz	a0,80005bd0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bb6:	6605                	lui	a2,0x1
    80005bb8:	e3043503          	ld	a0,-464(s0)
    80005bbc:	ffffd097          	auipc	ra,0xffffd
    80005bc0:	0d4080e7          	jalr	212(ra) # 80002c90 <fetchstr>
    80005bc4:	00054663          	bltz	a0,80005bd0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bc8:	0905                	addi	s2,s2,1
    80005bca:	09a1                	addi	s3,s3,8
    80005bcc:	fb491be3          	bne	s2,s4,80005b82 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd0:	10048913          	addi	s2,s1,256
    80005bd4:	6088                	ld	a0,0(s1)
    80005bd6:	c529                	beqz	a0,80005c20 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bd8:	ffffb097          	auipc	ra,0xffffb
    80005bdc:	e20080e7          	jalr	-480(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be0:	04a1                	addi	s1,s1,8
    80005be2:	ff2499e3          	bne	s1,s2,80005bd4 <sys_exec+0xac>
  return -1;
    80005be6:	597d                	li	s2,-1
    80005be8:	a82d                	j	80005c22 <sys_exec+0xfa>
      argv[i] = 0;
    80005bea:	0a8e                	slli	s5,s5,0x3
    80005bec:	fc040793          	addi	a5,s0,-64
    80005bf0:	9abe                	add	s5,s5,a5
    80005bf2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bf6:	e4040593          	addi	a1,s0,-448
    80005bfa:	f4040513          	addi	a0,s0,-192
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	194080e7          	jalr	404(ra) # 80004d92 <exec>
    80005c06:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c08:	10048993          	addi	s3,s1,256
    80005c0c:	6088                	ld	a0,0(s1)
    80005c0e:	c911                	beqz	a0,80005c22 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c10:	ffffb097          	auipc	ra,0xffffb
    80005c14:	de8080e7          	jalr	-536(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c18:	04a1                	addi	s1,s1,8
    80005c1a:	ff3499e3          	bne	s1,s3,80005c0c <sys_exec+0xe4>
    80005c1e:	a011                	j	80005c22 <sys_exec+0xfa>
  return -1;
    80005c20:	597d                	li	s2,-1
}
    80005c22:	854a                	mv	a0,s2
    80005c24:	60be                	ld	ra,456(sp)
    80005c26:	641e                	ld	s0,448(sp)
    80005c28:	74fa                	ld	s1,440(sp)
    80005c2a:	795a                	ld	s2,432(sp)
    80005c2c:	79ba                	ld	s3,424(sp)
    80005c2e:	7a1a                	ld	s4,416(sp)
    80005c30:	6afa                	ld	s5,408(sp)
    80005c32:	6179                	addi	sp,sp,464
    80005c34:	8082                	ret

0000000080005c36 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c36:	7139                	addi	sp,sp,-64
    80005c38:	fc06                	sd	ra,56(sp)
    80005c3a:	f822                	sd	s0,48(sp)
    80005c3c:	f426                	sd	s1,40(sp)
    80005c3e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c40:	ffffc097          	auipc	ra,0xffffc
    80005c44:	ea2080e7          	jalr	-350(ra) # 80001ae2 <myproc>
    80005c48:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c4a:	fd840593          	addi	a1,s0,-40
    80005c4e:	4501                	li	a0,0
    80005c50:	ffffd097          	auipc	ra,0xffffd
    80005c54:	0aa080e7          	jalr	170(ra) # 80002cfa <argaddr>
    return -1;
    80005c58:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c5a:	0e054063          	bltz	a0,80005d3a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c5e:	fc840593          	addi	a1,s0,-56
    80005c62:	fd040513          	addi	a0,s0,-48
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	dfc080e7          	jalr	-516(ra) # 80004a62 <pipealloc>
    return -1;
    80005c6e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c70:	0c054563          	bltz	a0,80005d3a <sys_pipe+0x104>
  fd0 = -1;
    80005c74:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c78:	fd043503          	ld	a0,-48(s0)
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	508080e7          	jalr	1288(ra) # 80005184 <fdalloc>
    80005c84:	fca42223          	sw	a0,-60(s0)
    80005c88:	08054c63          	bltz	a0,80005d20 <sys_pipe+0xea>
    80005c8c:	fc843503          	ld	a0,-56(s0)
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	4f4080e7          	jalr	1268(ra) # 80005184 <fdalloc>
    80005c98:	fca42023          	sw	a0,-64(s0)
    80005c9c:	06054863          	bltz	a0,80005d0c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca0:	4691                	li	a3,4
    80005ca2:	fc440613          	addi	a2,s0,-60
    80005ca6:	fd843583          	ld	a1,-40(s0)
    80005caa:	68a8                	ld	a0,80(s1)
    80005cac:	ffffc097          	auipc	ra,0xffffc
    80005cb0:	af8080e7          	jalr	-1288(ra) # 800017a4 <copyout>
    80005cb4:	02054063          	bltz	a0,80005cd4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cb8:	4691                	li	a3,4
    80005cba:	fc040613          	addi	a2,s0,-64
    80005cbe:	fd843583          	ld	a1,-40(s0)
    80005cc2:	0591                	addi	a1,a1,4
    80005cc4:	68a8                	ld	a0,80(s1)
    80005cc6:	ffffc097          	auipc	ra,0xffffc
    80005cca:	ade080e7          	jalr	-1314(ra) # 800017a4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cce:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cd0:	06055563          	bgez	a0,80005d3a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cd4:	fc442783          	lw	a5,-60(s0)
    80005cd8:	07e9                	addi	a5,a5,26
    80005cda:	078e                	slli	a5,a5,0x3
    80005cdc:	97a6                	add	a5,a5,s1
    80005cde:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ce2:	fc042503          	lw	a0,-64(s0)
    80005ce6:	0569                	addi	a0,a0,26
    80005ce8:	050e                	slli	a0,a0,0x3
    80005cea:	9526                	add	a0,a0,s1
    80005cec:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cf0:	fd043503          	ld	a0,-48(s0)
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	a3e080e7          	jalr	-1474(ra) # 80004732 <fileclose>
    fileclose(wf);
    80005cfc:	fc843503          	ld	a0,-56(s0)
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	a32080e7          	jalr	-1486(ra) # 80004732 <fileclose>
    return -1;
    80005d08:	57fd                	li	a5,-1
    80005d0a:	a805                	j	80005d3a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d0c:	fc442783          	lw	a5,-60(s0)
    80005d10:	0007c863          	bltz	a5,80005d20 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d14:	01a78513          	addi	a0,a5,26
    80005d18:	050e                	slli	a0,a0,0x3
    80005d1a:	9526                	add	a0,a0,s1
    80005d1c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d20:	fd043503          	ld	a0,-48(s0)
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	a0e080e7          	jalr	-1522(ra) # 80004732 <fileclose>
    fileclose(wf);
    80005d2c:	fc843503          	ld	a0,-56(s0)
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	a02080e7          	jalr	-1534(ra) # 80004732 <fileclose>
    return -1;
    80005d38:	57fd                	li	a5,-1
}
    80005d3a:	853e                	mv	a0,a5
    80005d3c:	70e2                	ld	ra,56(sp)
    80005d3e:	7442                	ld	s0,48(sp)
    80005d40:	74a2                	ld	s1,40(sp)
    80005d42:	6121                	addi	sp,sp,64
    80005d44:	8082                	ret
	...

0000000080005d50 <kernelvec>:
    80005d50:	7111                	addi	sp,sp,-256
    80005d52:	e006                	sd	ra,0(sp)
    80005d54:	e40a                	sd	sp,8(sp)
    80005d56:	e80e                	sd	gp,16(sp)
    80005d58:	ec12                	sd	tp,24(sp)
    80005d5a:	f016                	sd	t0,32(sp)
    80005d5c:	f41a                	sd	t1,40(sp)
    80005d5e:	f81e                	sd	t2,48(sp)
    80005d60:	fc22                	sd	s0,56(sp)
    80005d62:	e0a6                	sd	s1,64(sp)
    80005d64:	e4aa                	sd	a0,72(sp)
    80005d66:	e8ae                	sd	a1,80(sp)
    80005d68:	ecb2                	sd	a2,88(sp)
    80005d6a:	f0b6                	sd	a3,96(sp)
    80005d6c:	f4ba                	sd	a4,104(sp)
    80005d6e:	f8be                	sd	a5,112(sp)
    80005d70:	fcc2                	sd	a6,120(sp)
    80005d72:	e146                	sd	a7,128(sp)
    80005d74:	e54a                	sd	s2,136(sp)
    80005d76:	e94e                	sd	s3,144(sp)
    80005d78:	ed52                	sd	s4,152(sp)
    80005d7a:	f156                	sd	s5,160(sp)
    80005d7c:	f55a                	sd	s6,168(sp)
    80005d7e:	f95e                	sd	s7,176(sp)
    80005d80:	fd62                	sd	s8,184(sp)
    80005d82:	e1e6                	sd	s9,192(sp)
    80005d84:	e5ea                	sd	s10,200(sp)
    80005d86:	e9ee                	sd	s11,208(sp)
    80005d88:	edf2                	sd	t3,216(sp)
    80005d8a:	f1f6                	sd	t4,224(sp)
    80005d8c:	f5fa                	sd	t5,232(sp)
    80005d8e:	f9fe                	sd	t6,240(sp)
    80005d90:	d7bfc0ef          	jal	ra,80002b0a <kerneltrap>
    80005d94:	6082                	ld	ra,0(sp)
    80005d96:	6122                	ld	sp,8(sp)
    80005d98:	61c2                	ld	gp,16(sp)
    80005d9a:	7282                	ld	t0,32(sp)
    80005d9c:	7322                	ld	t1,40(sp)
    80005d9e:	73c2                	ld	t2,48(sp)
    80005da0:	7462                	ld	s0,56(sp)
    80005da2:	6486                	ld	s1,64(sp)
    80005da4:	6526                	ld	a0,72(sp)
    80005da6:	65c6                	ld	a1,80(sp)
    80005da8:	6666                	ld	a2,88(sp)
    80005daa:	7686                	ld	a3,96(sp)
    80005dac:	7726                	ld	a4,104(sp)
    80005dae:	77c6                	ld	a5,112(sp)
    80005db0:	7866                	ld	a6,120(sp)
    80005db2:	688a                	ld	a7,128(sp)
    80005db4:	692a                	ld	s2,136(sp)
    80005db6:	69ca                	ld	s3,144(sp)
    80005db8:	6a6a                	ld	s4,152(sp)
    80005dba:	7a8a                	ld	s5,160(sp)
    80005dbc:	7b2a                	ld	s6,168(sp)
    80005dbe:	7bca                	ld	s7,176(sp)
    80005dc0:	7c6a                	ld	s8,184(sp)
    80005dc2:	6c8e                	ld	s9,192(sp)
    80005dc4:	6d2e                	ld	s10,200(sp)
    80005dc6:	6dce                	ld	s11,208(sp)
    80005dc8:	6e6e                	ld	t3,216(sp)
    80005dca:	7e8e                	ld	t4,224(sp)
    80005dcc:	7f2e                	ld	t5,232(sp)
    80005dce:	7fce                	ld	t6,240(sp)
    80005dd0:	6111                	addi	sp,sp,256
    80005dd2:	10200073          	sret
    80005dd6:	00000013          	nop
    80005dda:	00000013          	nop
    80005dde:	0001                	nop

0000000080005de0 <timervec>:
    80005de0:	34051573          	csrrw	a0,mscratch,a0
    80005de4:	e10c                	sd	a1,0(a0)
    80005de6:	e510                	sd	a2,8(a0)
    80005de8:	e914                	sd	a3,16(a0)
    80005dea:	6d0c                	ld	a1,24(a0)
    80005dec:	7110                	ld	a2,32(a0)
    80005dee:	6194                	ld	a3,0(a1)
    80005df0:	96b2                	add	a3,a3,a2
    80005df2:	e194                	sd	a3,0(a1)
    80005df4:	4589                	li	a1,2
    80005df6:	14459073          	csrw	sip,a1
    80005dfa:	6914                	ld	a3,16(a0)
    80005dfc:	6510                	ld	a2,8(a0)
    80005dfe:	610c                	ld	a1,0(a0)
    80005e00:	34051573          	csrrw	a0,mscratch,a0
    80005e04:	30200073          	mret
	...

0000000080005e0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e0a:	1141                	addi	sp,sp,-16
    80005e0c:	e422                	sd	s0,8(sp)
    80005e0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e10:	0c0007b7          	lui	a5,0xc000
    80005e14:	4705                	li	a4,1
    80005e16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e18:	c3d8                	sw	a4,4(a5)
}
    80005e1a:	6422                	ld	s0,8(sp)
    80005e1c:	0141                	addi	sp,sp,16
    80005e1e:	8082                	ret

0000000080005e20 <plicinithart>:

void
plicinithart(void)
{
    80005e20:	1141                	addi	sp,sp,-16
    80005e22:	e406                	sd	ra,8(sp)
    80005e24:	e022                	sd	s0,0(sp)
    80005e26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	c8e080e7          	jalr	-882(ra) # 80001ab6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e30:	0085171b          	slliw	a4,a0,0x8
    80005e34:	0c0027b7          	lui	a5,0xc002
    80005e38:	97ba                	add	a5,a5,a4
    80005e3a:	40200713          	li	a4,1026
    80005e3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e42:	00d5151b          	slliw	a0,a0,0xd
    80005e46:	0c2017b7          	lui	a5,0xc201
    80005e4a:	953e                	add	a0,a0,a5
    80005e4c:	00052023          	sw	zero,0(a0)
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret

0000000080005e58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e58:	1141                	addi	sp,sp,-16
    80005e5a:	e406                	sd	ra,8(sp)
    80005e5c:	e022                	sd	s0,0(sp)
    80005e5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e60:	ffffc097          	auipc	ra,0xffffc
    80005e64:	c56080e7          	jalr	-938(ra) # 80001ab6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e68:	00d5179b          	slliw	a5,a0,0xd
    80005e6c:	0c201537          	lui	a0,0xc201
    80005e70:	953e                	add	a0,a0,a5
  return irq;
}
    80005e72:	4148                	lw	a0,4(a0)
    80005e74:	60a2                	ld	ra,8(sp)
    80005e76:	6402                	ld	s0,0(sp)
    80005e78:	0141                	addi	sp,sp,16
    80005e7a:	8082                	ret

0000000080005e7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e7c:	1101                	addi	sp,sp,-32
    80005e7e:	ec06                	sd	ra,24(sp)
    80005e80:	e822                	sd	s0,16(sp)
    80005e82:	e426                	sd	s1,8(sp)
    80005e84:	1000                	addi	s0,sp,32
    80005e86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	c2e080e7          	jalr	-978(ra) # 80001ab6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e90:	00d5151b          	slliw	a0,a0,0xd
    80005e94:	0c2017b7          	lui	a5,0xc201
    80005e98:	97aa                	add	a5,a5,a0
    80005e9a:	c3c4                	sw	s1,4(a5)
}
    80005e9c:	60e2                	ld	ra,24(sp)
    80005e9e:	6442                	ld	s0,16(sp)
    80005ea0:	64a2                	ld	s1,8(sp)
    80005ea2:	6105                	addi	sp,sp,32
    80005ea4:	8082                	ret

0000000080005ea6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ea6:	1141                	addi	sp,sp,-16
    80005ea8:	e406                	sd	ra,8(sp)
    80005eaa:	e022                	sd	s0,0(sp)
    80005eac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eae:	479d                	li	a5,7
    80005eb0:	06a7c963          	blt	a5,a0,80005f22 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005eb4:	0001d797          	auipc	a5,0x1d
    80005eb8:	14c78793          	addi	a5,a5,332 # 80023000 <disk>
    80005ebc:	00a78733          	add	a4,a5,a0
    80005ec0:	6789                	lui	a5,0x2
    80005ec2:	97ba                	add	a5,a5,a4
    80005ec4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ec8:	e7ad                	bnez	a5,80005f32 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005eca:	00451793          	slli	a5,a0,0x4
    80005ece:	0001f717          	auipc	a4,0x1f
    80005ed2:	13270713          	addi	a4,a4,306 # 80025000 <disk+0x2000>
    80005ed6:	6314                	ld	a3,0(a4)
    80005ed8:	96be                	add	a3,a3,a5
    80005eda:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ede:	6314                	ld	a3,0(a4)
    80005ee0:	96be                	add	a3,a3,a5
    80005ee2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ee6:	6314                	ld	a3,0(a4)
    80005ee8:	96be                	add	a3,a3,a5
    80005eea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005eee:	6318                	ld	a4,0(a4)
    80005ef0:	97ba                	add	a5,a5,a4
    80005ef2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ef6:	0001d797          	auipc	a5,0x1d
    80005efa:	10a78793          	addi	a5,a5,266 # 80023000 <disk>
    80005efe:	97aa                	add	a5,a5,a0
    80005f00:	6509                	lui	a0,0x2
    80005f02:	953e                	add	a0,a0,a5
    80005f04:	4785                	li	a5,1
    80005f06:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f0a:	0001f517          	auipc	a0,0x1f
    80005f0e:	10e50513          	addi	a0,a0,270 # 80025018 <disk+0x2018>
    80005f12:	ffffc097          	auipc	ra,0xffffc
    80005f16:	50c080e7          	jalr	1292(ra) # 8000241e <wakeup>
}
    80005f1a:	60a2                	ld	ra,8(sp)
    80005f1c:	6402                	ld	s0,0(sp)
    80005f1e:	0141                	addi	sp,sp,16
    80005f20:	8082                	ret
    panic("free_desc 1");
    80005f22:	00003517          	auipc	a0,0x3
    80005f26:	89650513          	addi	a0,a0,-1898 # 800087b8 <syscalls+0x330>
    80005f2a:	ffffa097          	auipc	ra,0xffffa
    80005f2e:	614080e7          	jalr	1556(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005f32:	00003517          	auipc	a0,0x3
    80005f36:	89650513          	addi	a0,a0,-1898 # 800087c8 <syscalls+0x340>
    80005f3a:	ffffa097          	auipc	ra,0xffffa
    80005f3e:	604080e7          	jalr	1540(ra) # 8000053e <panic>

0000000080005f42 <virtio_disk_init>:
{
    80005f42:	1101                	addi	sp,sp,-32
    80005f44:	ec06                	sd	ra,24(sp)
    80005f46:	e822                	sd	s0,16(sp)
    80005f48:	e426                	sd	s1,8(sp)
    80005f4a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f4c:	00003597          	auipc	a1,0x3
    80005f50:	88c58593          	addi	a1,a1,-1908 # 800087d8 <syscalls+0x350>
    80005f54:	0001f517          	auipc	a0,0x1f
    80005f58:	1d450513          	addi	a0,a0,468 # 80025128 <disk+0x2128>
    80005f5c:	ffffb097          	auipc	ra,0xffffb
    80005f60:	bf8080e7          	jalr	-1032(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f64:	100017b7          	lui	a5,0x10001
    80005f68:	4398                	lw	a4,0(a5)
    80005f6a:	2701                	sext.w	a4,a4
    80005f6c:	747277b7          	lui	a5,0x74727
    80005f70:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f74:	0ef71163          	bne	a4,a5,80006056 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f78:	100017b7          	lui	a5,0x10001
    80005f7c:	43dc                	lw	a5,4(a5)
    80005f7e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f80:	4705                	li	a4,1
    80005f82:	0ce79a63          	bne	a5,a4,80006056 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f86:	100017b7          	lui	a5,0x10001
    80005f8a:	479c                	lw	a5,8(a5)
    80005f8c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f8e:	4709                	li	a4,2
    80005f90:	0ce79363          	bne	a5,a4,80006056 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f94:	100017b7          	lui	a5,0x10001
    80005f98:	47d8                	lw	a4,12(a5)
    80005f9a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f9c:	554d47b7          	lui	a5,0x554d4
    80005fa0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fa4:	0af71963          	bne	a4,a5,80006056 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa8:	100017b7          	lui	a5,0x10001
    80005fac:	4705                	li	a4,1
    80005fae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb0:	470d                	li	a4,3
    80005fb2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fb4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fb6:	c7ffe737          	lui	a4,0xc7ffe
    80005fba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005fbe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fc0:	2701                	sext.w	a4,a4
    80005fc2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc4:	472d                	li	a4,11
    80005fc6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc8:	473d                	li	a4,15
    80005fca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fcc:	6705                	lui	a4,0x1
    80005fce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fd0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fd4:	5bdc                	lw	a5,52(a5)
    80005fd6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fd8:	c7d9                	beqz	a5,80006066 <virtio_disk_init+0x124>
  if(max < NUM)
    80005fda:	471d                	li	a4,7
    80005fdc:	08f77d63          	bgeu	a4,a5,80006076 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fe0:	100014b7          	lui	s1,0x10001
    80005fe4:	47a1                	li	a5,8
    80005fe6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fe8:	6609                	lui	a2,0x2
    80005fea:	4581                	li	a1,0
    80005fec:	0001d517          	auipc	a0,0x1d
    80005ff0:	01450513          	addi	a0,a0,20 # 80023000 <disk>
    80005ff4:	ffffb097          	auipc	ra,0xffffb
    80005ff8:	cec080e7          	jalr	-788(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ffc:	0001d717          	auipc	a4,0x1d
    80006000:	00470713          	addi	a4,a4,4 # 80023000 <disk>
    80006004:	00c75793          	srli	a5,a4,0xc
    80006008:	2781                	sext.w	a5,a5
    8000600a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000600c:	0001f797          	auipc	a5,0x1f
    80006010:	ff478793          	addi	a5,a5,-12 # 80025000 <disk+0x2000>
    80006014:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006016:	0001d717          	auipc	a4,0x1d
    8000601a:	06a70713          	addi	a4,a4,106 # 80023080 <disk+0x80>
    8000601e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006020:	0001e717          	auipc	a4,0x1e
    80006024:	fe070713          	addi	a4,a4,-32 # 80024000 <disk+0x1000>
    80006028:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000602a:	4705                	li	a4,1
    8000602c:	00e78c23          	sb	a4,24(a5)
    80006030:	00e78ca3          	sb	a4,25(a5)
    80006034:	00e78d23          	sb	a4,26(a5)
    80006038:	00e78da3          	sb	a4,27(a5)
    8000603c:	00e78e23          	sb	a4,28(a5)
    80006040:	00e78ea3          	sb	a4,29(a5)
    80006044:	00e78f23          	sb	a4,30(a5)
    80006048:	00e78fa3          	sb	a4,31(a5)
}
    8000604c:	60e2                	ld	ra,24(sp)
    8000604e:	6442                	ld	s0,16(sp)
    80006050:	64a2                	ld	s1,8(sp)
    80006052:	6105                	addi	sp,sp,32
    80006054:	8082                	ret
    panic("could not find virtio disk");
    80006056:	00002517          	auipc	a0,0x2
    8000605a:	79250513          	addi	a0,a0,1938 # 800087e8 <syscalls+0x360>
    8000605e:	ffffa097          	auipc	ra,0xffffa
    80006062:	4e0080e7          	jalr	1248(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006066:	00002517          	auipc	a0,0x2
    8000606a:	7a250513          	addi	a0,a0,1954 # 80008808 <syscalls+0x380>
    8000606e:	ffffa097          	auipc	ra,0xffffa
    80006072:	4d0080e7          	jalr	1232(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006076:	00002517          	auipc	a0,0x2
    8000607a:	7b250513          	addi	a0,a0,1970 # 80008828 <syscalls+0x3a0>
    8000607e:	ffffa097          	auipc	ra,0xffffa
    80006082:	4c0080e7          	jalr	1216(ra) # 8000053e <panic>

0000000080006086 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006086:	7159                	addi	sp,sp,-112
    80006088:	f486                	sd	ra,104(sp)
    8000608a:	f0a2                	sd	s0,96(sp)
    8000608c:	eca6                	sd	s1,88(sp)
    8000608e:	e8ca                	sd	s2,80(sp)
    80006090:	e4ce                	sd	s3,72(sp)
    80006092:	e0d2                	sd	s4,64(sp)
    80006094:	fc56                	sd	s5,56(sp)
    80006096:	f85a                	sd	s6,48(sp)
    80006098:	f45e                	sd	s7,40(sp)
    8000609a:	f062                	sd	s8,32(sp)
    8000609c:	ec66                	sd	s9,24(sp)
    8000609e:	e86a                	sd	s10,16(sp)
    800060a0:	1880                	addi	s0,sp,112
    800060a2:	892a                	mv	s2,a0
    800060a4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060a6:	00c52c83          	lw	s9,12(a0)
    800060aa:	001c9c9b          	slliw	s9,s9,0x1
    800060ae:	1c82                	slli	s9,s9,0x20
    800060b0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060b4:	0001f517          	auipc	a0,0x1f
    800060b8:	07450513          	addi	a0,a0,116 # 80025128 <disk+0x2128>
    800060bc:	ffffb097          	auipc	ra,0xffffb
    800060c0:	b28080e7          	jalr	-1240(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800060c4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060c6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060c8:	0001db97          	auipc	s7,0x1d
    800060cc:	f38b8b93          	addi	s7,s7,-200 # 80023000 <disk>
    800060d0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060d2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060d4:	8a4e                	mv	s4,s3
    800060d6:	a051                	j	8000615a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060d8:	00fb86b3          	add	a3,s7,a5
    800060dc:	96da                	add	a3,a3,s6
    800060de:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060e2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060e4:	0207c563          	bltz	a5,8000610e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060e8:	2485                	addiw	s1,s1,1
    800060ea:	0711                	addi	a4,a4,4
    800060ec:	25548063          	beq	s1,s5,8000632c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060f0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060f2:	0001f697          	auipc	a3,0x1f
    800060f6:	f2668693          	addi	a3,a3,-218 # 80025018 <disk+0x2018>
    800060fa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060fc:	0006c583          	lbu	a1,0(a3)
    80006100:	fde1                	bnez	a1,800060d8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006102:	2785                	addiw	a5,a5,1
    80006104:	0685                	addi	a3,a3,1
    80006106:	ff879be3          	bne	a5,s8,800060fc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000610a:	57fd                	li	a5,-1
    8000610c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000610e:	02905a63          	blez	s1,80006142 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006112:	f9042503          	lw	a0,-112(s0)
    80006116:	00000097          	auipc	ra,0x0
    8000611a:	d90080e7          	jalr	-624(ra) # 80005ea6 <free_desc>
      for(int j = 0; j < i; j++)
    8000611e:	4785                	li	a5,1
    80006120:	0297d163          	bge	a5,s1,80006142 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006124:	f9442503          	lw	a0,-108(s0)
    80006128:	00000097          	auipc	ra,0x0
    8000612c:	d7e080e7          	jalr	-642(ra) # 80005ea6 <free_desc>
      for(int j = 0; j < i; j++)
    80006130:	4789                	li	a5,2
    80006132:	0097d863          	bge	a5,s1,80006142 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006136:	f9842503          	lw	a0,-104(s0)
    8000613a:	00000097          	auipc	ra,0x0
    8000613e:	d6c080e7          	jalr	-660(ra) # 80005ea6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006142:	0001f597          	auipc	a1,0x1f
    80006146:	fe658593          	addi	a1,a1,-26 # 80025128 <disk+0x2128>
    8000614a:	0001f517          	auipc	a0,0x1f
    8000614e:	ece50513          	addi	a0,a0,-306 # 80025018 <disk+0x2018>
    80006152:	ffffc097          	auipc	ra,0xffffc
    80006156:	04c080e7          	jalr	76(ra) # 8000219e <sleep>
  for(int i = 0; i < 3; i++){
    8000615a:	f9040713          	addi	a4,s0,-112
    8000615e:	84ce                	mv	s1,s3
    80006160:	bf41                	j	800060f0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006162:	20058713          	addi	a4,a1,512
    80006166:	00471693          	slli	a3,a4,0x4
    8000616a:	0001d717          	auipc	a4,0x1d
    8000616e:	e9670713          	addi	a4,a4,-362 # 80023000 <disk>
    80006172:	9736                	add	a4,a4,a3
    80006174:	4685                	li	a3,1
    80006176:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000617a:	20058713          	addi	a4,a1,512
    8000617e:	00471693          	slli	a3,a4,0x4
    80006182:	0001d717          	auipc	a4,0x1d
    80006186:	e7e70713          	addi	a4,a4,-386 # 80023000 <disk>
    8000618a:	9736                	add	a4,a4,a3
    8000618c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006190:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006194:	7679                	lui	a2,0xffffe
    80006196:	963e                	add	a2,a2,a5
    80006198:	0001f697          	auipc	a3,0x1f
    8000619c:	e6868693          	addi	a3,a3,-408 # 80025000 <disk+0x2000>
    800061a0:	6298                	ld	a4,0(a3)
    800061a2:	9732                	add	a4,a4,a2
    800061a4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061a6:	6298                	ld	a4,0(a3)
    800061a8:	9732                	add	a4,a4,a2
    800061aa:	4541                	li	a0,16
    800061ac:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061ae:	6298                	ld	a4,0(a3)
    800061b0:	9732                	add	a4,a4,a2
    800061b2:	4505                	li	a0,1
    800061b4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061b8:	f9442703          	lw	a4,-108(s0)
    800061bc:	6288                	ld	a0,0(a3)
    800061be:	962a                	add	a2,a2,a0
    800061c0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061c4:	0712                	slli	a4,a4,0x4
    800061c6:	6290                	ld	a2,0(a3)
    800061c8:	963a                	add	a2,a2,a4
    800061ca:	05890513          	addi	a0,s2,88
    800061ce:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061d0:	6294                	ld	a3,0(a3)
    800061d2:	96ba                	add	a3,a3,a4
    800061d4:	40000613          	li	a2,1024
    800061d8:	c690                	sw	a2,8(a3)
  if(write)
    800061da:	140d0063          	beqz	s10,8000631a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061de:	0001f697          	auipc	a3,0x1f
    800061e2:	e226b683          	ld	a3,-478(a3) # 80025000 <disk+0x2000>
    800061e6:	96ba                	add	a3,a3,a4
    800061e8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061ec:	0001d817          	auipc	a6,0x1d
    800061f0:	e1480813          	addi	a6,a6,-492 # 80023000 <disk>
    800061f4:	0001f517          	auipc	a0,0x1f
    800061f8:	e0c50513          	addi	a0,a0,-500 # 80025000 <disk+0x2000>
    800061fc:	6114                	ld	a3,0(a0)
    800061fe:	96ba                	add	a3,a3,a4
    80006200:	00c6d603          	lhu	a2,12(a3)
    80006204:	00166613          	ori	a2,a2,1
    80006208:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000620c:	f9842683          	lw	a3,-104(s0)
    80006210:	6110                	ld	a2,0(a0)
    80006212:	9732                	add	a4,a4,a2
    80006214:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006218:	20058613          	addi	a2,a1,512
    8000621c:	0612                	slli	a2,a2,0x4
    8000621e:	9642                	add	a2,a2,a6
    80006220:	577d                	li	a4,-1
    80006222:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006226:	00469713          	slli	a4,a3,0x4
    8000622a:	6114                	ld	a3,0(a0)
    8000622c:	96ba                	add	a3,a3,a4
    8000622e:	03078793          	addi	a5,a5,48
    80006232:	97c2                	add	a5,a5,a6
    80006234:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006236:	611c                	ld	a5,0(a0)
    80006238:	97ba                	add	a5,a5,a4
    8000623a:	4685                	li	a3,1
    8000623c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000623e:	611c                	ld	a5,0(a0)
    80006240:	97ba                	add	a5,a5,a4
    80006242:	4809                	li	a6,2
    80006244:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006248:	611c                	ld	a5,0(a0)
    8000624a:	973e                	add	a4,a4,a5
    8000624c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006250:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006254:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006258:	6518                	ld	a4,8(a0)
    8000625a:	00275783          	lhu	a5,2(a4)
    8000625e:	8b9d                	andi	a5,a5,7
    80006260:	0786                	slli	a5,a5,0x1
    80006262:	97ba                	add	a5,a5,a4
    80006264:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006268:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000626c:	6518                	ld	a4,8(a0)
    8000626e:	00275783          	lhu	a5,2(a4)
    80006272:	2785                	addiw	a5,a5,1
    80006274:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006278:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000627c:	100017b7          	lui	a5,0x10001
    80006280:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006284:	00492703          	lw	a4,4(s2)
    80006288:	4785                	li	a5,1
    8000628a:	02f71163          	bne	a4,a5,800062ac <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000628e:	0001f997          	auipc	s3,0x1f
    80006292:	e9a98993          	addi	s3,s3,-358 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006296:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006298:	85ce                	mv	a1,s3
    8000629a:	854a                	mv	a0,s2
    8000629c:	ffffc097          	auipc	ra,0xffffc
    800062a0:	f02080e7          	jalr	-254(ra) # 8000219e <sleep>
  while(b->disk == 1) {
    800062a4:	00492783          	lw	a5,4(s2)
    800062a8:	fe9788e3          	beq	a5,s1,80006298 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062ac:	f9042903          	lw	s2,-112(s0)
    800062b0:	20090793          	addi	a5,s2,512
    800062b4:	00479713          	slli	a4,a5,0x4
    800062b8:	0001d797          	auipc	a5,0x1d
    800062bc:	d4878793          	addi	a5,a5,-696 # 80023000 <disk>
    800062c0:	97ba                	add	a5,a5,a4
    800062c2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062c6:	0001f997          	auipc	s3,0x1f
    800062ca:	d3a98993          	addi	s3,s3,-710 # 80025000 <disk+0x2000>
    800062ce:	00491713          	slli	a4,s2,0x4
    800062d2:	0009b783          	ld	a5,0(s3)
    800062d6:	97ba                	add	a5,a5,a4
    800062d8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062dc:	854a                	mv	a0,s2
    800062de:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062e2:	00000097          	auipc	ra,0x0
    800062e6:	bc4080e7          	jalr	-1084(ra) # 80005ea6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062ea:	8885                	andi	s1,s1,1
    800062ec:	f0ed                	bnez	s1,800062ce <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062ee:	0001f517          	auipc	a0,0x1f
    800062f2:	e3a50513          	addi	a0,a0,-454 # 80025128 <disk+0x2128>
    800062f6:	ffffb097          	auipc	ra,0xffffb
    800062fa:	9a2080e7          	jalr	-1630(ra) # 80000c98 <release>
}
    800062fe:	70a6                	ld	ra,104(sp)
    80006300:	7406                	ld	s0,96(sp)
    80006302:	64e6                	ld	s1,88(sp)
    80006304:	6946                	ld	s2,80(sp)
    80006306:	69a6                	ld	s3,72(sp)
    80006308:	6a06                	ld	s4,64(sp)
    8000630a:	7ae2                	ld	s5,56(sp)
    8000630c:	7b42                	ld	s6,48(sp)
    8000630e:	7ba2                	ld	s7,40(sp)
    80006310:	7c02                	ld	s8,32(sp)
    80006312:	6ce2                	ld	s9,24(sp)
    80006314:	6d42                	ld	s10,16(sp)
    80006316:	6165                	addi	sp,sp,112
    80006318:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000631a:	0001f697          	auipc	a3,0x1f
    8000631e:	ce66b683          	ld	a3,-794(a3) # 80025000 <disk+0x2000>
    80006322:	96ba                	add	a3,a3,a4
    80006324:	4609                	li	a2,2
    80006326:	00c69623          	sh	a2,12(a3)
    8000632a:	b5c9                	j	800061ec <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000632c:	f9042583          	lw	a1,-112(s0)
    80006330:	20058793          	addi	a5,a1,512
    80006334:	0792                	slli	a5,a5,0x4
    80006336:	0001d517          	auipc	a0,0x1d
    8000633a:	d7250513          	addi	a0,a0,-654 # 800230a8 <disk+0xa8>
    8000633e:	953e                	add	a0,a0,a5
  if(write)
    80006340:	e20d11e3          	bnez	s10,80006162 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006344:	20058713          	addi	a4,a1,512
    80006348:	00471693          	slli	a3,a4,0x4
    8000634c:	0001d717          	auipc	a4,0x1d
    80006350:	cb470713          	addi	a4,a4,-844 # 80023000 <disk>
    80006354:	9736                	add	a4,a4,a3
    80006356:	0a072423          	sw	zero,168(a4)
    8000635a:	b505                	j	8000617a <virtio_disk_rw+0xf4>

000000008000635c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000635c:	1101                	addi	sp,sp,-32
    8000635e:	ec06                	sd	ra,24(sp)
    80006360:	e822                	sd	s0,16(sp)
    80006362:	e426                	sd	s1,8(sp)
    80006364:	e04a                	sd	s2,0(sp)
    80006366:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006368:	0001f517          	auipc	a0,0x1f
    8000636c:	dc050513          	addi	a0,a0,-576 # 80025128 <disk+0x2128>
    80006370:	ffffb097          	auipc	ra,0xffffb
    80006374:	874080e7          	jalr	-1932(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006378:	10001737          	lui	a4,0x10001
    8000637c:	533c                	lw	a5,96(a4)
    8000637e:	8b8d                	andi	a5,a5,3
    80006380:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006382:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006386:	0001f797          	auipc	a5,0x1f
    8000638a:	c7a78793          	addi	a5,a5,-902 # 80025000 <disk+0x2000>
    8000638e:	6b94                	ld	a3,16(a5)
    80006390:	0207d703          	lhu	a4,32(a5)
    80006394:	0026d783          	lhu	a5,2(a3)
    80006398:	06f70163          	beq	a4,a5,800063fa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000639c:	0001d917          	auipc	s2,0x1d
    800063a0:	c6490913          	addi	s2,s2,-924 # 80023000 <disk>
    800063a4:	0001f497          	auipc	s1,0x1f
    800063a8:	c5c48493          	addi	s1,s1,-932 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800063ac:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063b0:	6898                	ld	a4,16(s1)
    800063b2:	0204d783          	lhu	a5,32(s1)
    800063b6:	8b9d                	andi	a5,a5,7
    800063b8:	078e                	slli	a5,a5,0x3
    800063ba:	97ba                	add	a5,a5,a4
    800063bc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063be:	20078713          	addi	a4,a5,512
    800063c2:	0712                	slli	a4,a4,0x4
    800063c4:	974a                	add	a4,a4,s2
    800063c6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063ca:	e731                	bnez	a4,80006416 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063cc:	20078793          	addi	a5,a5,512
    800063d0:	0792                	slli	a5,a5,0x4
    800063d2:	97ca                	add	a5,a5,s2
    800063d4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063d6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063da:	ffffc097          	auipc	ra,0xffffc
    800063de:	044080e7          	jalr	68(ra) # 8000241e <wakeup>

    disk.used_idx += 1;
    800063e2:	0204d783          	lhu	a5,32(s1)
    800063e6:	2785                	addiw	a5,a5,1
    800063e8:	17c2                	slli	a5,a5,0x30
    800063ea:	93c1                	srli	a5,a5,0x30
    800063ec:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063f0:	6898                	ld	a4,16(s1)
    800063f2:	00275703          	lhu	a4,2(a4)
    800063f6:	faf71be3          	bne	a4,a5,800063ac <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063fa:	0001f517          	auipc	a0,0x1f
    800063fe:	d2e50513          	addi	a0,a0,-722 # 80025128 <disk+0x2128>
    80006402:	ffffb097          	auipc	ra,0xffffb
    80006406:	896080e7          	jalr	-1898(ra) # 80000c98 <release>
}
    8000640a:	60e2                	ld	ra,24(sp)
    8000640c:	6442                	ld	s0,16(sp)
    8000640e:	64a2                	ld	s1,8(sp)
    80006410:	6902                	ld	s2,0(sp)
    80006412:	6105                	addi	sp,sp,32
    80006414:	8082                	ret
      panic("virtio_disk_intr status");
    80006416:	00002517          	auipc	a0,0x2
    8000641a:	43250513          	addi	a0,a0,1074 # 80008848 <syscalls+0x3c0>
    8000641e:	ffffa097          	auipc	ra,0xffffa
    80006422:	120080e7          	jalr	288(ra) # 8000053e <panic>
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
