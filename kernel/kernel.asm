
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	ffe70713          	addi	a4,a4,-2 # 80009050 <timer_scratch>
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
    80000068:	0bc78793          	addi	a5,a5,188 # 80006120 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdf7ff>
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
    80000130:	8f2080e7          	jalr	-1806(ra) # 80002a1e <either_copyin>
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
    8000018c:	0000a517          	auipc	a0,0xa
    80000190:	ef450513          	addi	a0,a0,-268 # 8000a080 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	0000a497          	auipc	s1,0xa
    800001a0:	ee448493          	addi	s1,s1,-284 # 8000a080 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	0000a917          	auipc	s2,0xa
    800001aa:	f7290913          	addi	s2,s2,-142 # 8000a118 <cons+0x98>
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
    800001cc:	413c                	lw	a5,64(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	3da080e7          	jalr	986(ra) # 800025ae <sleep>
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
    80000214:	7b8080e7          	jalr	1976(ra) # 800029c8 <either_copyout>
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
    80000224:	0000a517          	auipc	a0,0xa
    80000228:	e5c50513          	addi	a0,a0,-420 # 8000a080 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	0000a517          	auipc	a0,0xa
    8000023e:	e4650513          	addi	a0,a0,-442 # 8000a080 <cons>
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
    80000272:	0000a717          	auipc	a4,0xa
    80000276:	eaf72323          	sw	a5,-346(a4) # 8000a118 <cons+0x98>
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
    800002cc:	0000a517          	auipc	a0,0xa
    800002d0:	db450513          	addi	a0,a0,-588 # 8000a080 <cons>
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
    800002f6:	782080e7          	jalr	1922(ra) # 80002a74 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	0000a517          	auipc	a0,0xa
    800002fe:	d8650513          	addi	a0,a0,-634 # 8000a080 <cons>
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
    8000031e:	0000a717          	auipc	a4,0xa
    80000322:	d6270713          	addi	a4,a4,-670 # 8000a080 <cons>
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
    80000348:	0000a797          	auipc	a5,0xa
    8000034c:	d3878793          	addi	a5,a5,-712 # 8000a080 <cons>
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
    80000376:	0000a797          	auipc	a5,0xa
    8000037a:	da27a783          	lw	a5,-606(a5) # 8000a118 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	0000a717          	auipc	a4,0xa
    8000038e:	cf670713          	addi	a4,a4,-778 # 8000a080 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	0000a497          	auipc	s1,0xa
    8000039e:	ce648493          	addi	s1,s1,-794 # 8000a080 <cons>
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
    800003d6:	0000a717          	auipc	a4,0xa
    800003da:	caa70713          	addi	a4,a4,-854 # 8000a080 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	0000a717          	auipc	a4,0xa
    800003f0:	d2f72a23          	sw	a5,-716(a4) # 8000a120 <cons+0xa0>
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
    80000412:	0000a797          	auipc	a5,0xa
    80000416:	c6e78793          	addi	a5,a5,-914 # 8000a080 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	0000a797          	auipc	a5,0xa
    8000043a:	cec7a323          	sw	a2,-794(a5) # 8000a11c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	0000a517          	auipc	a0,0xa
    80000442:	cda50513          	addi	a0,a0,-806 # 8000a118 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	2f4080e7          	jalr	756(ra) # 8000273a <wakeup>
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
    80000460:	0000a517          	auipc	a0,0xa
    80000464:	c2050513          	addi	a0,a0,-992 # 8000a080 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0001a797          	auipc	a5,0x1a
    8000047c:	02078793          	addi	a5,a5,32 # 8001a498 <devsw>
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
    8000054a:	0000a797          	auipc	a5,0xa
    8000054e:	be07ab23          	sw	zero,-1034(a5) # 8000a140 <pr+0x18>
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
    800005ba:	0000ad97          	auipc	s11,0xa
    800005be:	b86dad83          	lw	s11,-1146(s11) # 8000a140 <pr+0x18>
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
    800005f8:	0000a517          	auipc	a0,0xa
    800005fc:	b3050513          	addi	a0,a0,-1232 # 8000a128 <pr>
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
    8000075c:	0000a517          	auipc	a0,0xa
    80000760:	9cc50513          	addi	a0,a0,-1588 # 8000a128 <pr>
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
    80000778:	0000a497          	auipc	s1,0xa
    8000077c:	9b048493          	addi	s1,s1,-1616 # 8000a128 <pr>
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
    800007d8:	0000a517          	auipc	a0,0xa
    800007dc:	97050513          	addi	a0,a0,-1680 # 8000a148 <uart_tx_lock>
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
    8000086a:	0000aa17          	auipc	s4,0xa
    8000086e:	8dea0a13          	addi	s4,s4,-1826 # 8000a148 <uart_tx_lock>
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
    800008a4:	e9a080e7          	jalr	-358(ra) # 8000273a <wakeup>
    
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
    800008dc:	0000a517          	auipc	a0,0xa
    800008e0:	86c50513          	addi	a0,a0,-1940 # 8000a148 <uart_tx_lock>
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
    80000910:	0000aa17          	auipc	s4,0xa
    80000914:	838a0a13          	addi	s4,s4,-1992 # 8000a148 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	c82080e7          	jalr	-894(ra) # 800025ae <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	0000a497          	auipc	s1,0xa
    80000946:	80648493          	addi	s1,s1,-2042 # 8000a148 <uart_tx_lock>
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
    800009ca:	00009497          	auipc	s1,0x9
    800009ce:	77e48493          	addi	s1,s1,1918 # 8000a148 <uart_tx_lock>
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
    80000a0c:	0001e797          	auipc	a5,0x1e
    80000a10:	5f478793          	addi	a5,a5,1524 # 8001f000 <end>
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
    80000a2c:	00009917          	auipc	s2,0x9
    80000a30:	75490913          	addi	s2,s2,1876 # 8000a180 <kmem>
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
    80000ac8:	00009517          	auipc	a0,0x9
    80000acc:	6b850513          	addi	a0,a0,1720 # 8000a180 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	0001e517          	auipc	a0,0x1e
    80000ae0:	52450513          	addi	a0,a0,1316 # 8001f000 <end>
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
    80000afe:	00009497          	auipc	s1,0x9
    80000b02:	68248493          	addi	s1,s1,1666 # 8000a180 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00009517          	auipc	a0,0x9
    80000b1a:	66a50513          	addi	a0,a0,1642 # 8000a180 <kmem>
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
    80000b42:	00009517          	auipc	a0,0x9
    80000b46:	63e50513          	addi	a0,a0,1598 # 8000a180 <kmem>
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
    80000eac:	010080e7          	jalr	16(ra) # 80001eb8 <fork>
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	008080e7          	jalr	8(ra) # 80001eb8 <fork>
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
    80000efa:	618080e7          	jalr	1560(ra) # 8000250e <pause_system>
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
    80000f3e:	f7e080e7          	jalr	-130(ra) # 80001eb8 <fork>
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	f76080e7          	jalr	-138(ra) # 80001eb8 <fork>
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
    80000f8a:	9f8080e7          	jalr	-1544(ra) # 8000297e <kill_system>
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
    80000ffc:	bbc080e7          	jalr	-1092(ra) # 80002bb4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001000:	00005097          	auipc	ra,0x5
    80001004:	160080e7          	jalr	352(ra) # 80006160 <plicinithart>
  }

  scheduler();  
    80001008:	00001097          	auipc	ra,0x1
    8000100c:	3e4080e7          	jalr	996(ra) # 800023ec <scheduler>
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
    kinit();
    80001050:	00000097          	auipc	ra,0x0
    80001054:	a68080e7          	jalr	-1432(ra) # 80000ab8 <kinit>
    kvminit();
    80001058:	00000097          	auipc	ra,0x0
    8000105c:	322080e7          	jalr	802(ra) # 8000137a <kvminit>
    kvminithart(); 
    80001060:	00000097          	auipc	ra,0x0
    80001064:	068080e7          	jalr	104(ra) # 800010c8 <kvminithart>
    procinit();   
    80001068:	00001097          	auipc	ra,0x1
    8000106c:	990080e7          	jalr	-1648(ra) # 800019f8 <procinit>
    trapinit(); 
    80001070:	00002097          	auipc	ra,0x2
    80001074:	b1c080e7          	jalr	-1252(ra) # 80002b8c <trapinit>
    trapinithart();
    80001078:	00002097          	auipc	ra,0x2
    8000107c:	b3c080e7          	jalr	-1220(ra) # 80002bb4 <trapinithart>
    plicinit(); 
    80001080:	00005097          	auipc	ra,0x5
    80001084:	0ca080e7          	jalr	202(ra) # 8000614a <plicinit>
    plicinithart();
    80001088:	00005097          	auipc	ra,0x5
    8000108c:	0d8080e7          	jalr	216(ra) # 80006160 <plicinithart>
    binit();  
    80001090:	00002097          	auipc	ra,0x2
    80001094:	2b0080e7          	jalr	688(ra) # 80003340 <binit>
    iinit(); 
    80001098:	00003097          	auipc	ra,0x3
    8000109c:	940080e7          	jalr	-1728(ra) # 800039d8 <iinit>
    fileinit();
    800010a0:	00004097          	auipc	ra,0x4
    800010a4:	8ea080e7          	jalr	-1814(ra) # 8000498a <fileinit>
    virtio_disk_init();
    800010a8:	00005097          	auipc	ra,0x5
    800010ac:	1da080e7          	jalr	474(ra) # 80006282 <virtio_disk_init>
    userinit(); 
    800010b0:	00001097          	auipc	ra,0x1
    800010b4:	d08080e7          	jalr	-760(ra) # 80001db8 <userinit>
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
void proc_mapstacks(pagetable_t kpgtbl)
{
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

  for (p = proc; p < &proc[NPROC]; p++)
    80001978:	00009497          	auipc	s1,0x9
    8000197c:	8d848493          	addi	s1,s1,-1832 # 8000a250 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001980:	8b26                	mv	s6,s1
    80001982:	00006a97          	auipc	s5,0x6
    80001986:	67ea8a93          	addi	s5,s5,1662 # 80008000 <etext>
    8000198a:	04000937          	lui	s2,0x4000
    8000198e:	197d                	addi	s2,s2,-1
    80001990:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001992:	0000fa17          	auipc	s4,0xf
    80001996:	8bea0a13          	addi	s4,s4,-1858 # 80010250 <tickslock>
    char *pa = kalloc();
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	15a080e7          	jalr	346(ra) # 80000af4 <kalloc>
    800019a2:	862a                	mv	a2,a0
    if (pa == 0)
    800019a4:	c131                	beqz	a0,800019e8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    800019a6:	416485b3          	sub	a1,s1,s6
    800019aa:	859d                	srai	a1,a1,0x7
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
  for (p = proc; p < &proc[NPROC]; p++)
    800019cc:	18048493          	addi	s1,s1,384
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
void procinit(void)
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
    80001a14:	00008517          	auipc	a0,0x8
    80001a18:	78c50513          	addi	a0,a0,1932 # 8000a1a0 <pid_lock>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	138080e7          	jalr	312(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a24:	00007597          	auipc	a1,0x7
    80001a28:	80458593          	addi	a1,a1,-2044 # 80008228 <digits+0x1e8>
    80001a2c:	00008517          	auipc	a0,0x8
    80001a30:	78c50513          	addi	a0,a0,1932 # 8000a1b8 <wait_lock>
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	120080e7          	jalr	288(ra) # 80000b54 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a3c:	00009497          	auipc	s1,0x9
    80001a40:	81448493          	addi	s1,s1,-2028 # 8000a250 <proc>
  {
    initlock(&p->lock, "proc");
    80001a44:	00006b17          	auipc	s6,0x6
    80001a48:	7f4b0b13          	addi	s6,s6,2036 # 80008238 <digits+0x1f8>
    p->kstack = KSTACK((int)(p - proc));
    80001a4c:	8aa6                	mv	s5,s1
    80001a4e:	00006a17          	auipc	s4,0x6
    80001a52:	5b2a0a13          	addi	s4,s4,1458 # 80008000 <etext>
    80001a56:	04000937          	lui	s2,0x4000
    80001a5a:	197d                	addi	s2,s2,-1
    80001a5c:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a5e:	0000e997          	auipc	s3,0xe
    80001a62:	7f298993          	addi	s3,s3,2034 # 80010250 <tickslock>
    initlock(&p->lock, "proc");
    80001a66:	85da                	mv	a1,s6
    80001a68:	8526                	mv	a0,s1
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	0ea080e7          	jalr	234(ra) # 80000b54 <initlock>
    p->kstack = KSTACK((int)(p - proc));
    80001a72:	415487b3          	sub	a5,s1,s5
    80001a76:	879d                	srai	a5,a5,0x7
    80001a78:	000a3703          	ld	a4,0(s4)
    80001a7c:	02e787b3          	mul	a5,a5,a4
    80001a80:	2785                	addiw	a5,a5,1
    80001a82:	00d7979b          	slliw	a5,a5,0xd
    80001a86:	40f907b3          	sub	a5,s2,a5
    80001a8a:	ecbc                	sd	a5,88(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a8c:	18048493          	addi	s1,s1,384
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
int cpuid()
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
struct cpu *
mycpu(void)
{
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
    80001ac4:	00008517          	auipc	a0,0x8
    80001ac8:	70c50513          	addi	a0,a0,1804 # 8000a1d0 <cpus>
    80001acc:	953e                	add	a0,a0,a5
    80001ace:	6422                	ld	s0,8(sp)
    80001ad0:	0141                	addi	sp,sp,16
    80001ad2:	8082                	ret

0000000080001ad4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
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
    80001aec:	00008717          	auipc	a4,0x8
    80001af0:	6b470713          	addi	a4,a4,1716 # 8000a1a0 <pid_lock>
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
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
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

  if (first)
    80001b24:	00007797          	auipc	a5,0x7
    80001b28:	d4c7a783          	lw	a5,-692(a5) # 80008870 <first.1729>
    80001b2c:	eb89                	bnez	a5,80001b3e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b2e:	00001097          	auipc	ra,0x1
    80001b32:	09e080e7          	jalr	158(ra) # 80002bcc <usertrapret>
}
    80001b36:	60a2                	ld	ra,8(sp)
    80001b38:	6402                	ld	s0,0(sp)
    80001b3a:	0141                	addi	sp,sp,16
    80001b3c:	8082                	ret
    first = 0;
    80001b3e:	00007797          	auipc	a5,0x7
    80001b42:	d207a923          	sw	zero,-718(a5) # 80008870 <first.1729>
    fsinit(ROOTDEV);
    80001b46:	4505                	li	a0,1
    80001b48:	00002097          	auipc	ra,0x2
    80001b4c:	e10080e7          	jalr	-496(ra) # 80003958 <fsinit>
    80001b50:	bff9                	j	80001b2e <forkret+0x22>

0000000080001b52 <allocpid>:
{
    80001b52:	1101                	addi	sp,sp,-32
    80001b54:	ec06                	sd	ra,24(sp)
    80001b56:	e822                	sd	s0,16(sp)
    80001b58:	e426                	sd	s1,8(sp)
    80001b5a:	e04a                	sd	s2,0(sp)
    80001b5c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b5e:	00008917          	auipc	s2,0x8
    80001b62:	64290913          	addi	s2,s2,1602 # 8000a1a0 <pid_lock>
    80001b66:	854a                	mv	a0,s2
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	07c080e7          	jalr	124(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b70:	00007797          	auipc	a5,0x7
    80001b74:	d0478793          	addi	a5,a5,-764 # 80008874 <nextpid>
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
  if (pagetable == 0)
    80001bb0:	c121                	beqz	a0,80001bf0 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
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
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bd2:	4719                	li	a4,6
    80001bd4:	07093683          	ld	a3,112(s2)
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
  if (p->trapframe)
    80001c92:	7928                	ld	a0,112(a0)
    80001c94:	c509                	beqz	a0,80001c9e <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	d62080e7          	jalr	-670(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001c9e:	0604b823          	sd	zero,112(s1)
  if (p->pagetable)
    80001ca2:	74a8                	ld	a0,104(s1)
    80001ca4:	c511                	beqz	a0,80001cb0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ca6:	70ac                	ld	a1,96(s1)
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f8c080e7          	jalr	-116(ra) # 80001c34 <proc_freepagetable>
  p->pagetable = 0;
    80001cb0:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    80001cb4:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001cb8:	0404a423          	sw	zero,72(s1)
  p->parent = 0;
    80001cbc:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80001cc0:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    80001cc4:	0204bc23          	sd	zero,56(s1)
  p->killed = 0;
    80001cc8:	0404a023          	sw	zero,64(s1)
  p->xstate = 0;
    80001ccc:	0404a223          	sw	zero,68(s1)
  p->state = UNUSED;
    80001cd0:	0204a823          	sw	zero,48(s1)
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
  for (p = proc; p < &proc[NPROC]; p++)
    80001cea:	00008497          	auipc	s1,0x8
    80001cee:	56648493          	addi	s1,s1,1382 # 8000a250 <proc>
    80001cf2:	0000e917          	auipc	s2,0xe
    80001cf6:	55e90913          	addi	s2,s2,1374 # 80010250 <tickslock>
    acquire(&p->lock);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	ee8080e7          	jalr	-280(ra) # 80000be4 <acquire>
    if (p->state == UNUSED)
    80001d04:	589c                	lw	a5,48(s1)
    80001d06:	cf81                	beqz	a5,80001d1e <allocproc+0x40>
      release(&p->lock);
    80001d08:	8526                	mv	a0,s1
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	f8e080e7          	jalr	-114(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d12:	18048493          	addi	s1,s1,384
    80001d16:	ff2492e3          	bne	s1,s2,80001cfa <allocproc+0x1c>
  return 0;
    80001d1a:	4481                	li	s1,0
    80001d1c:	a8b9                	j	80001d7a <allocproc+0x9c>
  p->last_runnable_time = 0;
    80001d1e:	0004bc23          	sd	zero,24(s1)
  p->mean_ticks = 0;
    80001d22:	0204b023          	sd	zero,32(s1)
  p->last_ticks = 0;
    80001d26:	0204b423          	sd	zero,40(s1)
  p->pid = allocpid();
    80001d2a:	00000097          	auipc	ra,0x0
    80001d2e:	e28080e7          	jalr	-472(ra) # 80001b52 <allocpid>
    80001d32:	c4a8                	sw	a0,72(s1)
  p->state = USED;
    80001d34:	4785                	li	a5,1
    80001d36:	d89c                	sw	a5,48(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	dbc080e7          	jalr	-580(ra) # 80000af4 <kalloc>
    80001d40:	892a                	mv	s2,a0
    80001d42:	f8a8                	sd	a0,112(s1)
    80001d44:	c131                	beqz	a0,80001d88 <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001d46:	8526                	mv	a0,s1
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	e50080e7          	jalr	-432(ra) # 80001b98 <proc_pagetable>
    80001d50:	892a                	mv	s2,a0
    80001d52:	f4a8                	sd	a0,104(s1)
  if (p->pagetable == 0)
    80001d54:	c531                	beqz	a0,80001da0 <allocproc+0xc2>
  memset(&p->context, 0, sizeof(p->context));
    80001d56:	07000613          	li	a2,112
    80001d5a:	4581                	li	a1,0
    80001d5c:	07848513          	addi	a0,s1,120
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	f80080e7          	jalr	-128(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d68:	00000797          	auipc	a5,0x0
    80001d6c:	da478793          	addi	a5,a5,-604 # 80001b0c <forkret>
    80001d70:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d72:	6cbc                	ld	a5,88(s1)
    80001d74:	6705                	lui	a4,0x1
    80001d76:	97ba                	add	a5,a5,a4
    80001d78:	e0dc                	sd	a5,128(s1)
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
    80001d8e:	efc080e7          	jalr	-260(ra) # 80001c86 <freeproc>
    release(&p->lock);
    80001d92:	8526                	mv	a0,s1
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	f04080e7          	jalr	-252(ra) # 80000c98 <release>
    return 0;
    80001d9c:	84ca                	mv	s1,s2
    80001d9e:	bff1                	j	80001d7a <allocproc+0x9c>
    freeproc(p);
    80001da0:	8526                	mv	a0,s1
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	ee4080e7          	jalr	-284(ra) # 80001c86 <freeproc>
    release(&p->lock);
    80001daa:	8526                	mv	a0,s1
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	eec080e7          	jalr	-276(ra) # 80000c98 <release>
    return 0;
    80001db4:	84ca                	mv	s1,s2
    80001db6:	b7d1                	j	80001d7a <allocproc+0x9c>

0000000080001db8 <userinit>:
{
    80001db8:	1101                	addi	sp,sp,-32
    80001dba:	ec06                	sd	ra,24(sp)
    80001dbc:	e822                	sd	s0,16(sp)
    80001dbe:	e426                	sd	s1,8(sp)
    80001dc0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	f1c080e7          	jalr	-228(ra) # 80001cde <allocproc>
    80001dca:	84aa                	mv	s1,a0
  initproc = p;
    80001dcc:	00007797          	auipc	a5,0x7
    80001dd0:	24a7be23          	sd	a0,604(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dd4:	03400613          	li	a2,52
    80001dd8:	00007597          	auipc	a1,0x7
    80001ddc:	aa858593          	addi	a1,a1,-1368 # 80008880 <initcode>
    80001de0:	7528                	ld	a0,104(a0)
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	6aa080e7          	jalr	1706(ra) # 8000148c <uvminit>
  p->sz = PGSIZE;
    80001dea:	6785                	lui	a5,0x1
    80001dec:	f0bc                	sd	a5,96(s1)
  p->trapframe->epc = 0;     // user program counter
    80001dee:	78b8                	ld	a4,112(s1)
    80001df0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001df4:	78b8                	ld	a4,112(s1)
    80001df6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001df8:	4641                	li	a2,16
    80001dfa:	00006597          	auipc	a1,0x6
    80001dfe:	44658593          	addi	a1,a1,1094 # 80008240 <digits+0x200>
    80001e02:	17048513          	addi	a0,s1,368
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	02c080e7          	jalr	44(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001e0e:	00006517          	auipc	a0,0x6
    80001e12:	44250513          	addi	a0,a0,1090 # 80008250 <digits+0x210>
    80001e16:	00002097          	auipc	ra,0x2
    80001e1a:	570080e7          	jalr	1392(ra) # 80004386 <namei>
    80001e1e:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    80001e22:	478d                	li	a5,3
    80001e24:	d89c                	sw	a5,48(s1)
    p->last_runnable_time=ticks;
    80001e26:	00007797          	auipc	a5,0x7
    80001e2a:	2227e783          	lwu	a5,546(a5) # 80009048 <ticks>
    80001e2e:	ec9c                	sd	a5,24(s1)
  release(&p->lock);
    80001e30:	8526                	mv	a0,s1
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e66080e7          	jalr	-410(ra) # 80000c98 <release>
}
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6105                	addi	sp,sp,32
    80001e42:	8082                	ret

0000000080001e44 <growproc>:
{
    80001e44:	1101                	addi	sp,sp,-32
    80001e46:	ec06                	sd	ra,24(sp)
    80001e48:	e822                	sd	s0,16(sp)
    80001e4a:	e426                	sd	s1,8(sp)
    80001e4c:	e04a                	sd	s2,0(sp)
    80001e4e:	1000                	addi	s0,sp,32
    80001e50:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	c82080e7          	jalr	-894(ra) # 80001ad4 <myproc>
    80001e5a:	892a                	mv	s2,a0
  sz = p->sz;
    80001e5c:	712c                	ld	a1,96(a0)
    80001e5e:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001e62:	00904f63          	bgtz	s1,80001e80 <growproc+0x3c>
  else if (n < 0)
    80001e66:	0204cc63          	bltz	s1,80001e9e <growproc+0x5a>
  p->sz = sz;
    80001e6a:	1602                	slli	a2,a2,0x20
    80001e6c:	9201                	srli	a2,a2,0x20
    80001e6e:	06c93023          	sd	a2,96(s2)
  return 0;
    80001e72:	4501                	li	a0,0
}
    80001e74:	60e2                	ld	ra,24(sp)
    80001e76:	6442                	ld	s0,16(sp)
    80001e78:	64a2                	ld	s1,8(sp)
    80001e7a:	6902                	ld	s2,0(sp)
    80001e7c:	6105                	addi	sp,sp,32
    80001e7e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001e80:	9e25                	addw	a2,a2,s1
    80001e82:	1602                	slli	a2,a2,0x20
    80001e84:	9201                	srli	a2,a2,0x20
    80001e86:	1582                	slli	a1,a1,0x20
    80001e88:	9181                	srli	a1,a1,0x20
    80001e8a:	7528                	ld	a0,104(a0)
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	6ba080e7          	jalr	1722(ra) # 80001546 <uvmalloc>
    80001e94:	0005061b          	sext.w	a2,a0
    80001e98:	fa69                	bnez	a2,80001e6a <growproc+0x26>
      return -1;
    80001e9a:	557d                	li	a0,-1
    80001e9c:	bfe1                	j	80001e74 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e9e:	9e25                	addw	a2,a2,s1
    80001ea0:	1602                	slli	a2,a2,0x20
    80001ea2:	9201                	srli	a2,a2,0x20
    80001ea4:	1582                	slli	a1,a1,0x20
    80001ea6:	9181                	srli	a1,a1,0x20
    80001ea8:	7528                	ld	a0,104(a0)
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	654080e7          	jalr	1620(ra) # 800014fe <uvmdealloc>
    80001eb2:	0005061b          	sext.w	a2,a0
    80001eb6:	bf55                	j	80001e6a <growproc+0x26>

0000000080001eb8 <fork>:
{
    80001eb8:	7179                	addi	sp,sp,-48
    80001eba:	f406                	sd	ra,40(sp)
    80001ebc:	f022                	sd	s0,32(sp)
    80001ebe:	ec26                	sd	s1,24(sp)
    80001ec0:	e84a                	sd	s2,16(sp)
    80001ec2:	e44e                	sd	s3,8(sp)
    80001ec4:	e052                	sd	s4,0(sp)
    80001ec6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	c0c080e7          	jalr	-1012(ra) # 80001ad4 <myproc>
    80001ed0:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	e0c080e7          	jalr	-500(ra) # 80001cde <allocproc>
    80001eda:	12050163          	beqz	a0,80001ffc <fork+0x144>
    80001ede:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ee0:	06093603          	ld	a2,96(s2)
    80001ee4:	752c                	ld	a1,104(a0)
    80001ee6:	06893503          	ld	a0,104(s2)
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	7a8080e7          	jalr	1960(ra) # 80001692 <uvmcopy>
    80001ef2:	04054663          	bltz	a0,80001f3e <fork+0x86>
  np->sz = p->sz;
    80001ef6:	06093783          	ld	a5,96(s2)
    80001efa:	06f9b023          	sd	a5,96(s3)
  *(np->trapframe) = *(p->trapframe);
    80001efe:	07093683          	ld	a3,112(s2)
    80001f02:	87b6                	mv	a5,a3
    80001f04:	0709b703          	ld	a4,112(s3)
    80001f08:	12068693          	addi	a3,a3,288
    80001f0c:	0007b803          	ld	a6,0(a5)
    80001f10:	6788                	ld	a0,8(a5)
    80001f12:	6b8c                	ld	a1,16(a5)
    80001f14:	6f90                	ld	a2,24(a5)
    80001f16:	01073023          	sd	a6,0(a4)
    80001f1a:	e708                	sd	a0,8(a4)
    80001f1c:	eb0c                	sd	a1,16(a4)
    80001f1e:	ef10                	sd	a2,24(a4)
    80001f20:	02078793          	addi	a5,a5,32
    80001f24:	02070713          	addi	a4,a4,32
    80001f28:	fed792e3          	bne	a5,a3,80001f0c <fork+0x54>
  np->trapframe->a0 = 0;
    80001f2c:	0709b783          	ld	a5,112(s3)
    80001f30:	0607b823          	sd	zero,112(a5)
    80001f34:	0e800493          	li	s1,232
  for (i = 0; i < NOFILE; i++)
    80001f38:	16800a13          	li	s4,360
    80001f3c:	a03d                	j	80001f6a <fork+0xb2>
    freeproc(np);
    80001f3e:	854e                	mv	a0,s3
    80001f40:	00000097          	auipc	ra,0x0
    80001f44:	d46080e7          	jalr	-698(ra) # 80001c86 <freeproc>
    release(&np->lock);
    80001f48:	854e                	mv	a0,s3
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	d4e080e7          	jalr	-690(ra) # 80000c98 <release>
    return -1;
    80001f52:	5a7d                	li	s4,-1
    80001f54:	a859                	j	80001fea <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f56:	00003097          	auipc	ra,0x3
    80001f5a:	ac6080e7          	jalr	-1338(ra) # 80004a1c <filedup>
    80001f5e:	009987b3          	add	a5,s3,s1
    80001f62:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001f64:	04a1                	addi	s1,s1,8
    80001f66:	01448763          	beq	s1,s4,80001f74 <fork+0xbc>
    if (p->ofile[i])
    80001f6a:	009907b3          	add	a5,s2,s1
    80001f6e:	6388                	ld	a0,0(a5)
    80001f70:	f17d                	bnez	a0,80001f56 <fork+0x9e>
    80001f72:	bfcd                	j	80001f64 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f74:	16893503          	ld	a0,360(s2)
    80001f78:	00002097          	auipc	ra,0x2
    80001f7c:	c1a080e7          	jalr	-998(ra) # 80003b92 <idup>
    80001f80:	16a9b423          	sd	a0,360(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f84:	4641                	li	a2,16
    80001f86:	17090593          	addi	a1,s2,368
    80001f8a:	17098513          	addi	a0,s3,368
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	ea4080e7          	jalr	-348(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f96:	0489aa03          	lw	s4,72(s3)
  release(&np->lock);
    80001f9a:	854e                	mv	a0,s3
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	cfc080e7          	jalr	-772(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001fa4:	00008497          	auipc	s1,0x8
    80001fa8:	21448493          	addi	s1,s1,532 # 8000a1b8 <wait_lock>
    80001fac:	8526                	mv	a0,s1
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	c36080e7          	jalr	-970(ra) # 80000be4 <acquire>
  np->parent = p;
    80001fb6:	0529b823          	sd	s2,80(s3)
  release(&wait_lock);
    80001fba:	8526                	mv	a0,s1
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	cdc080e7          	jalr	-804(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001fc4:	854e                	mv	a0,s3
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	c1e080e7          	jalr	-994(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001fce:	478d                	li	a5,3
    80001fd0:	02f9a823          	sw	a5,48(s3)
  np->last_runnable_time = ticks;
    80001fd4:	00007797          	auipc	a5,0x7
    80001fd8:	0747e783          	lwu	a5,116(a5) # 80009048 <ticks>
    80001fdc:	00f9bc23          	sd	a5,24(s3)
  release(&np->lock);
    80001fe0:	854e                	mv	a0,s3
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	cb6080e7          	jalr	-842(ra) # 80000c98 <release>
}
    80001fea:	8552                	mv	a0,s4
    80001fec:	70a2                	ld	ra,40(sp)
    80001fee:	7402                	ld	s0,32(sp)
    80001ff0:	64e2                	ld	s1,24(sp)
    80001ff2:	6942                	ld	s2,16(sp)
    80001ff4:	69a2                	ld	s3,8(sp)
    80001ff6:	6a02                	ld	s4,0(sp)
    80001ff8:	6145                	addi	sp,sp,48
    80001ffa:	8082                	ret
    return -1;
    80001ffc:	5a7d                	li	s4,-1
    80001ffe:	b7f5                	j	80001fea <fork+0x132>

0000000080002000 <changeToMean>:
{
    80002000:	1141                	addi	sp,sp,-16
    80002002:	e422                	sd	s0,8(sp)
    80002004:	0800                	addi	s0,sp,16
  return (((exp) + mean * changes) / (changes + 1));
    80002006:	00007797          	auipc	a5,0x7
    8000200a:	0327a783          	lw	a5,50(a5) # 80009038 <changes>
    8000200e:	02b785bb          	mulw	a1,a5,a1
    80002012:	9da9                	addw	a1,a1,a0
    80002014:	0017851b          	addiw	a0,a5,1
}
    80002018:	02a5c53b          	divw	a0,a1,a0
    8000201c:	6422                	ld	s0,8(sp)
    8000201e:	0141                	addi	sp,sp,16
    80002020:	8082                	ret

0000000080002022 <SJFtScheduler>:
{
    80002022:	7159                	addi	sp,sp,-112
    80002024:	f486                	sd	ra,104(sp)
    80002026:	f0a2                	sd	s0,96(sp)
    80002028:	eca6                	sd	s1,88(sp)
    8000202a:	e8ca                	sd	s2,80(sp)
    8000202c:	e4ce                	sd	s3,72(sp)
    8000202e:	e0d2                	sd	s4,64(sp)
    80002030:	fc56                	sd	s5,56(sp)
    80002032:	f85a                	sd	s6,48(sp)
    80002034:	f45e                	sd	s7,40(sp)
    80002036:	f062                	sd	s8,32(sp)
    80002038:	ec66                	sd	s9,24(sp)
    8000203a:	e86a                	sd	s10,16(sp)
    8000203c:	e46e                	sd	s11,8(sp)
    8000203e:	1880                	addi	s0,sp,112
    80002040:	8792                	mv	a5,tp
  int id = r_tp();
    80002042:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002044:	00779c93          	slli	s9,a5,0x7
    80002048:	00008717          	auipc	a4,0x8
    8000204c:	15870713          	addi	a4,a4,344 # 8000a1a0 <pid_lock>
    80002050:	9766                	add	a4,a4,s9
    80002052:	02073823          	sd	zero,48(a4)
    swtch(&c->context, &p->context);
    80002056:	00008717          	auipc	a4,0x8
    8000205a:	18270713          	addi	a4,a4,386 # 8000a1d8 <cpus+0x8>
    8000205e:	9cba                	add	s9,s9,a4
  struct proc *ChoosenOne = proc;
    80002060:	00008b17          	auipc	s6,0x8
    80002064:	1f0b0b13          	addi	s6,s6,496 # 8000a250 <proc>
      if (ticks > nextGoodTicks)
    80002068:	00007917          	auipc	s2,0x7
    8000206c:	fe090913          	addi	s2,s2,-32 # 80009048 <ticks>
    80002070:	00007a17          	auipc	s4,0x7
    80002074:	fc0a0a13          	addi	s4,s4,-64 # 80009030 <nextGoodTicks>
        if (p->state == RUNNABLE)
    80002078:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000207a:	0000e997          	auipc	s3,0xe
    8000207e:	1d698993          	addi	s3,s3,470 # 80010250 <tickslock>
    c->proc = p;
    80002082:	079e                	slli	a5,a5,0x7
    80002084:	00008b97          	auipc	s7,0x8
    80002088:	11cb8b93          	addi	s7,s7,284 # 8000a1a0 <pid_lock>
    8000208c:	9bbe                	add	s7,s7,a5
    changes++;
    8000208e:	00007c17          	auipc	s8,0x7
    80002092:	faac0c13          	addi	s8,s8,-86 # 80009038 <changes>
    80002096:	a231                	j	800021a2 <SJFtScheduler+0x180>
        release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bfe080e7          	jalr	-1026(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800020a2:	18048493          	addi	s1,s1,384
    800020a6:	03348263          	beq	s1,s3,800020ca <SJFtScheduler+0xa8>
      if (ticks > nextGoodTicks)
    800020aa:	00092703          	lw	a4,0(s2)
    800020ae:	000a2783          	lw	a5,0(s4)
    800020b2:	fee7f8e3          	bgeu	a5,a4,800020a2 <SJFtScheduler+0x80>
        acquire(&p->lock);
    800020b6:	8526                	mv	a0,s1
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	b2c080e7          	jalr	-1236(ra) # 80000be4 <acquire>
        if (p->state == RUNNABLE)
    800020c0:	589c                	lw	a5,48(s1)
    800020c2:	fd579be3          	bne	a5,s5,80002098 <SJFtScheduler+0x76>
    800020c6:	8b26                	mv	s6,s1
    800020c8:	bfc1                	j	80002098 <SJFtScheduler+0x76>
    acquire(&p->lock);
    800020ca:	855a                	mv	a0,s6
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	b18080e7          	jalr	-1256(ra) # 80000be4 <acquire>
    p->state = RUNNING;
    800020d4:	4791                	li	a5,4
    800020d6:	02fb2823          	sw	a5,48(s6)
    c->proc = p;
    800020da:	036bb823          	sd	s6,48(s7)
    changes++;
    800020de:	000c2783          	lw	a5,0(s8)
    800020e2:	2785                	addiw	a5,a5,1
    800020e4:	00fc2023          	sw	a5,0(s8)
    sleeping_processes_mean = changeToMean((ticks - p->last_runnable_time), sleeping_processes_mean);
    800020e8:	00092483          	lw	s1,0(s2)
    800020ec:	018b3d03          	ld	s10,24(s6)
    800020f0:	41a48d3b          	subw	s10,s1,s10
    800020f4:	00007d97          	auipc	s11,0x7
    800020f8:	f50d8d93          	addi	s11,s11,-176 # 80009044 <sleeping_processes_mean>
    800020fc:	000da583          	lw	a1,0(s11)
    80002100:	856a                	mv	a0,s10
    80002102:	00000097          	auipc	ra,0x0
    80002106:	efe080e7          	jalr	-258(ra) # 80002000 <changeToMean>
    8000210a:	00ada023          	sw	a0,0(s11)
    running_processes_mean = changeToMean(ticks - p->last_runnable_time, running_processes_mean);
    8000210e:	00007d97          	auipc	s11,0x7
    80002112:	f32d8d93          	addi	s11,s11,-206 # 80009040 <running_processes_mean>
    80002116:	000da583          	lw	a1,0(s11)
    8000211a:	856a                	mv	a0,s10
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	ee4080e7          	jalr	-284(ra) # 80002000 <changeToMean>
    80002124:	00ada023          	sw	a0,0(s11)
    swtch(&c->context, &p->context);
    80002128:	078b0593          	addi	a1,s6,120
    8000212c:	8566                	mv	a0,s9
    8000212e:	00001097          	auipc	ra,0x1
    80002132:	9f4080e7          	jalr	-1548(ra) # 80002b22 <swtch>
    p->last_ticks = ticks - CurrentTick;
    80002136:	00096d83          	lwu	s11,0(s2)
    uint64 CurrentTick = ticks;
    8000213a:	1482                	slli	s1,s1,0x20
    8000213c:	9081                	srli	s1,s1,0x20
    p->last_ticks = ticks - CurrentTick;
    8000213e:	409d8db3          	sub	s11,s11,s1
    80002142:	03bb3423          	sd	s11,40(s6)
    running_time_mean = changeToMean(p->last_ticks, running_time_mean);
    80002146:	000d8d1b          	sext.w	s10,s11
    8000214a:	00007497          	auipc	s1,0x7
    8000214e:	ef248493          	addi	s1,s1,-270 # 8000903c <running_time_mean>
    80002152:	408c                	lw	a1,0(s1)
    80002154:	856a                	mv	a0,s10
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	eaa080e7          	jalr	-342(ra) # 80002000 <changeToMean>
    8000215e:	0005059b          	sext.w	a1,a0
    80002162:	c08c                	sw	a1,0(s1)
    p->mean_ticks = ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    80002164:	00006717          	auipc	a4,0x6
    80002168:	71472703          	lw	a4,1812(a4) # 80008878 <rate>
    8000216c:	47a9                	li	a5,10
    8000216e:	9f99                	subw	a5,a5,a4
    80002170:	020b3683          	ld	a3,32(s6)
    80002174:	02d787b3          	mul	a5,a5,a3
    80002178:	03b70733          	mul	a4,a4,s11
    8000217c:	97ba                	add	a5,a5,a4
    8000217e:	4729                	li	a4,10
    80002180:	02e7d7b3          	divu	a5,a5,a4
    80002184:	02fb3023          	sd	a5,32(s6)
    running_time_mean = changeToMean(p->last_ticks, running_time_mean);
    80002188:	856a                	mv	a0,s10
    8000218a:	00000097          	auipc	ra,0x0
    8000218e:	e76080e7          	jalr	-394(ra) # 80002000 <changeToMean>
    80002192:	c088                	sw	a0,0(s1)
    c->proc = 0;
    80002194:	020bb823          	sd	zero,48(s7)
    release(&p->lock);
    80002198:	855a                	mv	a0,s6
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	afe080e7          	jalr	-1282(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021a2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021a6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021aa:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    800021ae:	00008497          	auipc	s1,0x8
    800021b2:	0a248493          	addi	s1,s1,162 # 8000a250 <proc>
    800021b6:	bdd5                	j	800020aa <SJFtScheduler+0x88>

00000000800021b8 <regulerScheduler>:
{
    800021b8:	711d                	addi	sp,sp,-96
    800021ba:	ec86                	sd	ra,88(sp)
    800021bc:	e8a2                	sd	s0,80(sp)
    800021be:	e4a6                	sd	s1,72(sp)
    800021c0:	e0ca                	sd	s2,64(sp)
    800021c2:	fc4e                	sd	s3,56(sp)
    800021c4:	f852                	sd	s4,48(sp)
    800021c6:	f456                	sd	s5,40(sp)
    800021c8:	f05a                	sd	s6,32(sp)
    800021ca:	ec5e                	sd	s7,24(sp)
    800021cc:	e862                	sd	s8,16(sp)
    800021ce:	e466                	sd	s9,8(sp)
    800021d0:	e06a                	sd	s10,0(sp)
    800021d2:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    800021d4:	8792                	mv	a5,tp
  int id = r_tp();
    800021d6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021d8:	00779c13          	slli	s8,a5,0x7
    800021dc:	00008717          	auipc	a4,0x8
    800021e0:	fc470713          	addi	a4,a4,-60 # 8000a1a0 <pid_lock>
    800021e4:	9762                	add	a4,a4,s8
    800021e6:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    800021ea:	00008717          	auipc	a4,0x8
    800021ee:	fee70713          	addi	a4,a4,-18 # 8000a1d8 <cpus+0x8>
    800021f2:	9c3a                	add	s8,s8,a4
      if (ticks > nextGoodTicks)
    800021f4:	00007917          	auipc	s2,0x7
    800021f8:	e5490913          	addi	s2,s2,-428 # 80009048 <ticks>
          c->proc = p;
    800021fc:	079e                	slli	a5,a5,0x7
    800021fe:	00008b17          	auipc	s6,0x8
    80002202:	fa2b0b13          	addi	s6,s6,-94 # 8000a1a0 <pid_lock>
    80002206:	9b3e                	add	s6,s6,a5
          changes++;
    80002208:	00007b97          	auipc	s7,0x7
    8000220c:	e30b8b93          	addi	s7,s7,-464 # 80009038 <changes>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002210:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002214:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002218:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000221c:	00008497          	auipc	s1,0x8
    80002220:	03448493          	addi	s1,s1,52 # 8000a250 <proc>
      if (ticks > nextGoodTicks)
    80002224:	00007997          	auipc	s3,0x7
    80002228:	e0c98993          	addi	s3,s3,-500 # 80009030 <nextGoodTicks>
          sleeping_processes_mean = changeToMean((ticks - p->last_runnable_time), sleeping_processes_mean);
    8000222c:	00007a97          	auipc	s5,0x7
    80002230:	e18a8a93          	addi	s5,s5,-488 # 80009044 <sleeping_processes_mean>
          running_processes_mean = changeToMean(ticks - p->last_runnable_time, running_processes_mean);
    80002234:	00007a17          	auipc	s4,0x7
    80002238:	e0ca0a13          	addi	s4,s4,-500 # 80009040 <running_processes_mean>
    8000223c:	a869                	j	800022d6 <regulerScheduler+0x11e>
          p->state = RUNNING;
    8000223e:	4791                	li	a5,4
    80002240:	d89c                	sw	a5,48(s1)
          c->proc = p;
    80002242:	029b3823          	sd	s1,48(s6)
          changes++;
    80002246:	000ba783          	lw	a5,0(s7)
    8000224a:	2785                	addiw	a5,a5,1
    8000224c:	00fba023          	sw	a5,0(s7)
          sleeping_processes_mean = changeToMean((ticks - p->last_runnable_time), sleeping_processes_mean);
    80002250:	00092c83          	lw	s9,0(s2)
    80002254:	0184bd03          	ld	s10,24(s1)
    80002258:	41ac8d3b          	subw	s10,s9,s10
    8000225c:	000aa583          	lw	a1,0(s5)
    80002260:	856a                	mv	a0,s10
    80002262:	00000097          	auipc	ra,0x0
    80002266:	d9e080e7          	jalr	-610(ra) # 80002000 <changeToMean>
    8000226a:	00aaa023          	sw	a0,0(s5)
          running_processes_mean = changeToMean(ticks - p->last_runnable_time, running_processes_mean);
    8000226e:	000a2583          	lw	a1,0(s4)
    80002272:	856a                	mv	a0,s10
    80002274:	00000097          	auipc	ra,0x0
    80002278:	d8c080e7          	jalr	-628(ra) # 80002000 <changeToMean>
    8000227c:	00aa2023          	sw	a0,0(s4)
          swtch(&c->context, &p->context);
    80002280:	07848593          	addi	a1,s1,120
    80002284:	8562                	mv	a0,s8
    80002286:	00001097          	auipc	ra,0x1
    8000228a:	89c080e7          	jalr	-1892(ra) # 80002b22 <swtch>
          p->last_ticks = ticks - CurrentTick;
    8000228e:	00096503          	lwu	a0,0(s2)
          uint64 CurrentTick = ticks;
    80002292:	1c82                	slli	s9,s9,0x20
    80002294:	020cdc93          	srli	s9,s9,0x20
          p->last_ticks = ticks - CurrentTick;
    80002298:	41950533          	sub	a0,a0,s9
    8000229c:	f488                	sd	a0,40(s1)
          running_time_mean = changeToMean(p->last_ticks, running_time_mean);
    8000229e:	00007c97          	auipc	s9,0x7
    800022a2:	d9ec8c93          	addi	s9,s9,-610 # 8000903c <running_time_mean>
    800022a6:	000ca583          	lw	a1,0(s9)
    800022aa:	2501                	sext.w	a0,a0
    800022ac:	00000097          	auipc	ra,0x0
    800022b0:	d54080e7          	jalr	-684(ra) # 80002000 <changeToMean>
    800022b4:	00aca023          	sw	a0,0(s9)
          c->proc = 0;
    800022b8:	020b3823          	sd	zero,48(s6)
        release(&p->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	9da080e7          	jalr	-1574(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800022c6:	18048493          	addi	s1,s1,384
    800022ca:	0000e797          	auipc	a5,0xe
    800022ce:	f8678793          	addi	a5,a5,-122 # 80010250 <tickslock>
    800022d2:	f2f48fe3          	beq	s1,a5,80002210 <regulerScheduler+0x58>
      if (ticks > nextGoodTicks)
    800022d6:	00092703          	lw	a4,0(s2)
    800022da:	0009a783          	lw	a5,0(s3)
    800022de:	fee7f4e3          	bgeu	a5,a4,800022c6 <regulerScheduler+0x10e>
        acquire(&p->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	900080e7          	jalr	-1792(ra) # 80000be4 <acquire>
        if (p->state == RUNNABLE)
    800022ec:	5898                	lw	a4,48(s1)
    800022ee:	478d                	li	a5,3
    800022f0:	fcf716e3          	bne	a4,a5,800022bc <regulerScheduler+0x104>
    800022f4:	b7a9                	j	8000223e <regulerScheduler+0x86>

00000000800022f6 <FCFSScheduler>:
{
    800022f6:	711d                	addi	sp,sp,-96
    800022f8:	ec86                	sd	ra,88(sp)
    800022fa:	e8a2                	sd	s0,80(sp)
    800022fc:	e4a6                	sd	s1,72(sp)
    800022fe:	e0ca                	sd	s2,64(sp)
    80002300:	fc4e                	sd	s3,56(sp)
    80002302:	f852                	sd	s4,48(sp)
    80002304:	f456                	sd	s5,40(sp)
    80002306:	f05a                	sd	s6,32(sp)
    80002308:	ec5e                	sd	s7,24(sp)
    8000230a:	e862                	sd	s8,16(sp)
    8000230c:	e466                	sd	s9,8(sp)
    8000230e:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    80002310:	8792                	mv	a5,tp
  int id = r_tp();
    80002312:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002314:	00779c13          	slli	s8,a5,0x7
    80002318:	00008717          	auipc	a4,0x8
    8000231c:	e8870713          	addi	a4,a4,-376 # 8000a1a0 <pid_lock>
    80002320:	9762                	add	a4,a4,s8
    80002322:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &p->context);
    80002326:	00008717          	auipc	a4,0x8
    8000232a:	eb270713          	addi	a4,a4,-334 # 8000a1d8 <cpus+0x8>
    8000232e:	9c3a                	add	s8,s8,a4
  struct proc *ChoosenOne = proc;
    80002330:	00008a17          	auipc	s4,0x8
    80002334:	f20a0a13          	addi	s4,s4,-224 # 8000a250 <proc>
          if (p->state == RUNNABLE)
    80002338:	498d                	li	s3,3
      for (p = proc; p < &proc[NPROC]; p++)
    8000233a:	0000e917          	auipc	s2,0xe
    8000233e:	f1690913          	addi	s2,s2,-234 # 80010250 <tickslock>
          if (ticks>=nextGoodTicks||p->pid<3){
    80002342:	00007b97          	auipc	s7,0x7
    80002346:	d06b8b93          	addi	s7,s7,-762 # 80009048 <ticks>
    8000234a:	00007b17          	auipc	s6,0x7
    8000234e:	ce6b0b13          	addi	s6,s6,-794 # 80009030 <nextGoodTicks>
            p->state = RUNNING;
    80002352:	4c91                	li	s9,4
            c->proc = p;
    80002354:	079e                	slli	a5,a5,0x7
    80002356:	00008a97          	auipc	s5,0x8
    8000235a:	e4aa8a93          	addi	s5,s5,-438 # 8000a1a0 <pid_lock>
    8000235e:	9abe                	add	s5,s5,a5
    80002360:	a89d                	j	800023d6 <FCFSScheduler+0xe0>
          release(&p->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	934080e7          	jalr	-1740(ra) # 80000c98 <release>
      for (p = proc; p < &proc[NPROC]; p++)
    8000236c:	18048493          	addi	s1,s1,384
    80002370:	03248163          	beq	s1,s2,80002392 <FCFSScheduler+0x9c>
          acquire(&p->lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	86e080e7          	jalr	-1938(ra) # 80000be4 <acquire>
          if (p->state == RUNNABLE)
    8000237e:	589c                	lw	a5,48(s1)
    80002380:	ff3791e3          	bne	a5,s3,80002362 <FCFSScheduler+0x6c>
            if ((p->last_runnable_time) < (ChoosenOne->last_runnable_time))
    80002384:	6c98                	ld	a4,24(s1)
    80002386:	018a3783          	ld	a5,24(s4)
    8000238a:	fcf77ce3          	bgeu	a4,a5,80002362 <FCFSScheduler+0x6c>
    8000238e:	8a26                	mv	s4,s1
    80002390:	bfc9                	j	80002362 <FCFSScheduler+0x6c>
          if (ticks>=nextGoodTicks||p->pid<3){
    80002392:	000ba703          	lw	a4,0(s7)
    80002396:	000b2783          	lw	a5,0(s6)
    8000239a:	00f77763          	bgeu	a4,a5,800023a8 <FCFSScheduler+0xb2>
    8000239e:	048a2703          	lw	a4,72(s4)
    800023a2:	4789                	li	a5,2
    800023a4:	02e7c963          	blt	a5,a4,800023d6 <FCFSScheduler+0xe0>
            acquire(&p->lock);
    800023a8:	8552                	mv	a0,s4
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	83a080e7          	jalr	-1990(ra) # 80000be4 <acquire>
            p->state = RUNNING;
    800023b2:	039a2823          	sw	s9,48(s4)
            c->proc = p;
    800023b6:	034ab823          	sd	s4,48(s5)
            swtch(&c->context, &p->context);
    800023ba:	078a0593          	addi	a1,s4,120
    800023be:	8562                	mv	a0,s8
    800023c0:	00000097          	auipc	ra,0x0
    800023c4:	762080e7          	jalr	1890(ra) # 80002b22 <swtch>
            c->proc = 0;
    800023c8:	020ab823          	sd	zero,48(s5)
            release(&p->lock);
    800023cc:	8552                	mv	a0,s4
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8ca080e7          	jalr	-1846(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800023da:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800023de:	10079073          	csrw	sstatus,a5
      for (p = proc; p < &proc[NPROC]; p++)
    800023e2:	00008497          	auipc	s1,0x8
    800023e6:	e6e48493          	addi	s1,s1,-402 # 8000a250 <proc>
    800023ea:	b769                	j	80002374 <FCFSScheduler+0x7e>

00000000800023ec <scheduler>:
{
    800023ec:	1141                	addi	sp,sp,-16
    800023ee:	e406                	sd	ra,8(sp)
    800023f0:	e022                	sd	s0,0(sp)
    800023f2:	0800                	addi	s0,sp,16
    FCFSScheduler();
    800023f4:	00000097          	auipc	ra,0x0
    800023f8:	f02080e7          	jalr	-254(ra) # 800022f6 <FCFSScheduler>

00000000800023fc <sched>:
{
    800023fc:	7179                	addi	sp,sp,-48
    800023fe:	f406                	sd	ra,40(sp)
    80002400:	f022                	sd	s0,32(sp)
    80002402:	ec26                	sd	s1,24(sp)
    80002404:	e84a                	sd	s2,16(sp)
    80002406:	e44e                	sd	s3,8(sp)
    80002408:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	6ca080e7          	jalr	1738(ra) # 80001ad4 <myproc>
    80002412:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	756080e7          	jalr	1878(ra) # 80000b6a <holding>
    8000241c:	c93d                	beqz	a0,80002492 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000241e:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002420:	2781                	sext.w	a5,a5
    80002422:	079e                	slli	a5,a5,0x7
    80002424:	00008717          	auipc	a4,0x8
    80002428:	d7c70713          	addi	a4,a4,-644 # 8000a1a0 <pid_lock>
    8000242c:	97ba                	add	a5,a5,a4
    8000242e:	0a87a703          	lw	a4,168(a5)
    80002432:	4785                	li	a5,1
    80002434:	06f71763          	bne	a4,a5,800024a2 <sched+0xa6>
  if (p->state == RUNNING)
    80002438:	5898                	lw	a4,48(s1)
    8000243a:	4791                	li	a5,4
    8000243c:	06f70b63          	beq	a4,a5,800024b2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002440:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002444:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002446:	efb5                	bnez	a5,800024c2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002448:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000244a:	00008917          	auipc	s2,0x8
    8000244e:	d5690913          	addi	s2,s2,-682 # 8000a1a0 <pid_lock>
    80002452:	2781                	sext.w	a5,a5
    80002454:	079e                	slli	a5,a5,0x7
    80002456:	97ca                	add	a5,a5,s2
    80002458:	0ac7a983          	lw	s3,172(a5)
    8000245c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000245e:	2781                	sext.w	a5,a5
    80002460:	079e                	slli	a5,a5,0x7
    80002462:	00008597          	auipc	a1,0x8
    80002466:	d7658593          	addi	a1,a1,-650 # 8000a1d8 <cpus+0x8>
    8000246a:	95be                	add	a1,a1,a5
    8000246c:	07848513          	addi	a0,s1,120
    80002470:	00000097          	auipc	ra,0x0
    80002474:	6b2080e7          	jalr	1714(ra) # 80002b22 <swtch>
    80002478:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000247a:	2781                	sext.w	a5,a5
    8000247c:	079e                	slli	a5,a5,0x7
    8000247e:	97ca                	add	a5,a5,s2
    80002480:	0b37a623          	sw	s3,172(a5)
}
    80002484:	70a2                	ld	ra,40(sp)
    80002486:	7402                	ld	s0,32(sp)
    80002488:	64e2                	ld	s1,24(sp)
    8000248a:	6942                	ld	s2,16(sp)
    8000248c:	69a2                	ld	s3,8(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret
    panic("sched p->lock");
    80002492:	00006517          	auipc	a0,0x6
    80002496:	dc650513          	addi	a0,a0,-570 # 80008258 <digits+0x218>
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	0a4080e7          	jalr	164(ra) # 8000053e <panic>
    panic("sched locks");
    800024a2:	00006517          	auipc	a0,0x6
    800024a6:	dc650513          	addi	a0,a0,-570 # 80008268 <digits+0x228>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	094080e7          	jalr	148(ra) # 8000053e <panic>
    panic("sched running");
    800024b2:	00006517          	auipc	a0,0x6
    800024b6:	dc650513          	addi	a0,a0,-570 # 80008278 <digits+0x238>
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	084080e7          	jalr	132(ra) # 8000053e <panic>
    panic("sched interruptible");
    800024c2:	00006517          	auipc	a0,0x6
    800024c6:	dc650513          	addi	a0,a0,-570 # 80008288 <digits+0x248>
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	074080e7          	jalr	116(ra) # 8000053e <panic>

00000000800024d2 <yield>:
{
    800024d2:	1101                	addi	sp,sp,-32
    800024d4:	ec06                	sd	ra,24(sp)
    800024d6:	e822                	sd	s0,16(sp)
    800024d8:	e426                	sd	s1,8(sp)
    800024da:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	5f8080e7          	jalr	1528(ra) # 80001ad4 <myproc>
    800024e4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024e6:	ffffe097          	auipc	ra,0xffffe
    800024ea:	6fe080e7          	jalr	1790(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800024ee:	478d                	li	a5,3
    800024f0:	d89c                	sw	a5,48(s1)
  sched();
    800024f2:	00000097          	auipc	ra,0x0
    800024f6:	f0a080e7          	jalr	-246(ra) # 800023fc <sched>
  release(&p->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	79c080e7          	jalr	1948(ra) # 80000c98 <release>
}
    80002504:	60e2                	ld	ra,24(sp)
    80002506:	6442                	ld	s0,16(sp)
    80002508:	64a2                	ld	s1,8(sp)
    8000250a:	6105                	addi	sp,sp,32
    8000250c:	8082                	ret

000000008000250e <pause_system>:
  nextGoodTicks = StartingTicks + 10 * seconds;
    8000250e:	0025179b          	slliw	a5,a0,0x2
    80002512:	9fa9                	addw	a5,a5,a0
    80002514:	0017979b          	slliw	a5,a5,0x1
    80002518:	00007717          	auipc	a4,0x7
    8000251c:	b3072703          	lw	a4,-1232(a4) # 80009048 <ticks>
    80002520:	9fb9                	addw	a5,a5,a4
    80002522:	00007717          	auipc	a4,0x7
    80002526:	b0f72723          	sw	a5,-1266(a4) # 80009030 <nextGoodTicks>
  if (seconds < 0)
    8000252a:	08054063          	bltz	a0,800025aa <pause_system+0x9c>
{
    8000252e:	7139                	addi	sp,sp,-64
    80002530:	fc06                	sd	ra,56(sp)
    80002532:	f822                	sd	s0,48(sp)
    80002534:	f426                	sd	s1,40(sp)
    80002536:	f04a                	sd	s2,32(sp)
    80002538:	ec4e                	sd	s3,24(sp)
    8000253a:	e852                	sd	s4,16(sp)
    8000253c:	e456                	sd	s5,8(sp)
    8000253e:	0080                	addi	s0,sp,64
  for (p = proc; p < &proc[NPROC]; p++)
    80002540:	00008497          	auipc	s1,0x8
    80002544:	d1048493          	addi	s1,s1,-752 # 8000a250 <proc>
    if (p->state == RUNNABLE && p->pid > 2)
    80002548:	498d                	li	s3,3
    8000254a:	4a09                	li	s4,2
      p->last_runnable_time=ticks;
    8000254c:	00007a97          	auipc	s5,0x7
    80002550:	afca8a93          	addi	s5,s5,-1284 # 80009048 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    80002554:	0000e917          	auipc	s2,0xe
    80002558:	cfc90913          	addi	s2,s2,-772 # 80010250 <tickslock>
    8000255c:	a811                	j	80002570 <pause_system+0x62>
    release(&p->lock);
    8000255e:	8526                	mv	a0,s1
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	738080e7          	jalr	1848(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002568:	18048493          	addi	s1,s1,384
    8000256c:	03248163          	beq	s1,s2,8000258e <pause_system+0x80>
    acquire(&p->lock);
    80002570:	8526                	mv	a0,s1
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	672080e7          	jalr	1650(ra) # 80000be4 <acquire>
    if (p->state == RUNNABLE && p->pid > 2)
    8000257a:	589c                	lw	a5,48(s1)
    8000257c:	ff3791e3          	bne	a5,s3,8000255e <pause_system+0x50>
    80002580:	44bc                	lw	a5,72(s1)
    80002582:	fcfa5ee3          	bge	s4,a5,8000255e <pause_system+0x50>
      p->last_runnable_time=ticks;
    80002586:	000ae783          	lwu	a5,0(s5)
    8000258a:	ec9c                	sd	a5,24(s1)
    8000258c:	bfc9                	j	8000255e <pause_system+0x50>
  yield();
    8000258e:	00000097          	auipc	ra,0x0
    80002592:	f44080e7          	jalr	-188(ra) # 800024d2 <yield>
  return 0;
    80002596:	4501                	li	a0,0
}
    80002598:	70e2                	ld	ra,56(sp)
    8000259a:	7442                	ld	s0,48(sp)
    8000259c:	74a2                	ld	s1,40(sp)
    8000259e:	7902                	ld	s2,32(sp)
    800025a0:	69e2                	ld	s3,24(sp)
    800025a2:	6a42                	ld	s4,16(sp)
    800025a4:	6aa2                	ld	s5,8(sp)
    800025a6:	6121                	addi	sp,sp,64
    800025a8:	8082                	ret
    return -1;
    800025aa:	557d                	li	a0,-1
}
    800025ac:	8082                	ret

00000000800025ae <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800025ae:	7179                	addi	sp,sp,-48
    800025b0:	f406                	sd	ra,40(sp)
    800025b2:	f022                	sd	s0,32(sp)
    800025b4:	ec26                	sd	s1,24(sp)
    800025b6:	e84a                	sd	s2,16(sp)
    800025b8:	e44e                	sd	s3,8(sp)
    800025ba:	1800                	addi	s0,sp,48
    800025bc:	89aa                	mv	s3,a0
    800025be:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	514080e7          	jalr	1300(ra) # 80001ad4 <myproc>
    800025c8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	61a080e7          	jalr	1562(ra) # 80000be4 <acquire>
  release(lk);
    800025d2:	854a                	mv	a0,s2
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	6c4080e7          	jalr	1732(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800025dc:	0334bc23          	sd	s3,56(s1)
  p->state = SLEEPING;
    800025e0:	4789                	li	a5,2
    800025e2:	d89c                	sw	a5,48(s1)

  sched();
    800025e4:	00000097          	auipc	ra,0x0
    800025e8:	e18080e7          	jalr	-488(ra) # 800023fc <sched>

  // Tidy up.
  p->chan = 0;
    800025ec:	0204bc23          	sd	zero,56(s1)

  // Reacquire original lock.
  release(&p->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	6a6080e7          	jalr	1702(ra) # 80000c98 <release>
  acquire(lk);
    800025fa:	854a                	mv	a0,s2
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	5e8080e7          	jalr	1512(ra) # 80000be4 <acquire>
}
    80002604:	70a2                	ld	ra,40(sp)
    80002606:	7402                	ld	s0,32(sp)
    80002608:	64e2                	ld	s1,24(sp)
    8000260a:	6942                	ld	s2,16(sp)
    8000260c:	69a2                	ld	s3,8(sp)
    8000260e:	6145                	addi	sp,sp,48
    80002610:	8082                	ret

0000000080002612 <wait>:
{
    80002612:	715d                	addi	sp,sp,-80
    80002614:	e486                	sd	ra,72(sp)
    80002616:	e0a2                	sd	s0,64(sp)
    80002618:	fc26                	sd	s1,56(sp)
    8000261a:	f84a                	sd	s2,48(sp)
    8000261c:	f44e                	sd	s3,40(sp)
    8000261e:	f052                	sd	s4,32(sp)
    80002620:	ec56                	sd	s5,24(sp)
    80002622:	e85a                	sd	s6,16(sp)
    80002624:	e45e                	sd	s7,8(sp)
    80002626:	e062                	sd	s8,0(sp)
    80002628:	0880                	addi	s0,sp,80
    8000262a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	4a8080e7          	jalr	1192(ra) # 80001ad4 <myproc>
    80002634:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002636:	00008517          	auipc	a0,0x8
    8000263a:	b8250513          	addi	a0,a0,-1150 # 8000a1b8 <wait_lock>
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	5a6080e7          	jalr	1446(ra) # 80000be4 <acquire>
    havekids = 0;
    80002646:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002648:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    8000264a:	0000e997          	auipc	s3,0xe
    8000264e:	c0698993          	addi	s3,s3,-1018 # 80010250 <tickslock>
        havekids = 1;
    80002652:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002654:	00008c17          	auipc	s8,0x8
    80002658:	b64c0c13          	addi	s8,s8,-1180 # 8000a1b8 <wait_lock>
    havekids = 0;
    8000265c:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000265e:	00008497          	auipc	s1,0x8
    80002662:	bf248493          	addi	s1,s1,-1038 # 8000a250 <proc>
    80002666:	a0bd                	j	800026d4 <wait+0xc2>
          pid = np->pid;
    80002668:	0484a983          	lw	s3,72(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000266c:	000b0e63          	beqz	s6,80002688 <wait+0x76>
    80002670:	4691                	li	a3,4
    80002672:	04448613          	addi	a2,s1,68
    80002676:	85da                	mv	a1,s6
    80002678:	06893503          	ld	a0,104(s2)
    8000267c:	fffff097          	auipc	ra,0xfffff
    80002680:	11a080e7          	jalr	282(ra) # 80001796 <copyout>
    80002684:	02054563          	bltz	a0,800026ae <wait+0x9c>
          freeproc(np);
    80002688:	8526                	mv	a0,s1
    8000268a:	fffff097          	auipc	ra,0xfffff
    8000268e:	5fc080e7          	jalr	1532(ra) # 80001c86 <freeproc>
          release(&np->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	604080e7          	jalr	1540(ra) # 80000c98 <release>
          release(&wait_lock);
    8000269c:	00008517          	auipc	a0,0x8
    800026a0:	b1c50513          	addi	a0,a0,-1252 # 8000a1b8 <wait_lock>
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	5f4080e7          	jalr	1524(ra) # 80000c98 <release>
          return pid;
    800026ac:	a09d                	j	80002712 <wait+0x100>
            release(&np->lock);
    800026ae:	8526                	mv	a0,s1
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	5e8080e7          	jalr	1512(ra) # 80000c98 <release>
            release(&wait_lock);
    800026b8:	00008517          	auipc	a0,0x8
    800026bc:	b0050513          	addi	a0,a0,-1280 # 8000a1b8 <wait_lock>
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	5d8080e7          	jalr	1496(ra) # 80000c98 <release>
            return -1;
    800026c8:	59fd                	li	s3,-1
    800026ca:	a0a1                	j	80002712 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800026cc:	18048493          	addi	s1,s1,384
    800026d0:	03348463          	beq	s1,s3,800026f8 <wait+0xe6>
      if (np->parent == p)
    800026d4:	68bc                	ld	a5,80(s1)
    800026d6:	ff279be3          	bne	a5,s2,800026cc <wait+0xba>
        acquire(&np->lock);
    800026da:	8526                	mv	a0,s1
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	508080e7          	jalr	1288(ra) # 80000be4 <acquire>
        if (np->state == ZOMBIE)
    800026e4:	589c                	lw	a5,48(s1)
    800026e6:	f94781e3          	beq	a5,s4,80002668 <wait+0x56>
        release(&np->lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	5ac080e7          	jalr	1452(ra) # 80000c98 <release>
        havekids = 1;
    800026f4:	8756                	mv	a4,s5
    800026f6:	bfd9                	j	800026cc <wait+0xba>
    if (!havekids || p->killed)
    800026f8:	c701                	beqz	a4,80002700 <wait+0xee>
    800026fa:	04092783          	lw	a5,64(s2)
    800026fe:	c79d                	beqz	a5,8000272c <wait+0x11a>
      release(&wait_lock);
    80002700:	00008517          	auipc	a0,0x8
    80002704:	ab850513          	addi	a0,a0,-1352 # 8000a1b8 <wait_lock>
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	590080e7          	jalr	1424(ra) # 80000c98 <release>
      return -1;
    80002710:	59fd                	li	s3,-1
}
    80002712:	854e                	mv	a0,s3
    80002714:	60a6                	ld	ra,72(sp)
    80002716:	6406                	ld	s0,64(sp)
    80002718:	74e2                	ld	s1,56(sp)
    8000271a:	7942                	ld	s2,48(sp)
    8000271c:	79a2                	ld	s3,40(sp)
    8000271e:	7a02                	ld	s4,32(sp)
    80002720:	6ae2                	ld	s5,24(sp)
    80002722:	6b42                	ld	s6,16(sp)
    80002724:	6ba2                	ld	s7,8(sp)
    80002726:	6c02                	ld	s8,0(sp)
    80002728:	6161                	addi	sp,sp,80
    8000272a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000272c:	85e2                	mv	a1,s8
    8000272e:	854a                	mv	a0,s2
    80002730:	00000097          	auipc	ra,0x0
    80002734:	e7e080e7          	jalr	-386(ra) # 800025ae <sleep>
    havekids = 0;
    80002738:	b715                	j	8000265c <wait+0x4a>

000000008000273a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000273a:	7139                	addi	sp,sp,-64
    8000273c:	fc06                	sd	ra,56(sp)
    8000273e:	f822                	sd	s0,48(sp)
    80002740:	f426                	sd	s1,40(sp)
    80002742:	f04a                	sd	s2,32(sp)
    80002744:	ec4e                	sd	s3,24(sp)
    80002746:	e852                	sd	s4,16(sp)
    80002748:	e456                	sd	s5,8(sp)
    8000274a:	e05a                	sd	s6,0(sp)
    8000274c:	0080                	addi	s0,sp,64
    8000274e:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002750:	00008497          	auipc	s1,0x8
    80002754:	b0048493          	addi	s1,s1,-1280 # 8000a250 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002758:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000275a:	4b0d                	li	s6,3
        p->last_runnable_time=ticks;
    8000275c:	00007a97          	auipc	s5,0x7
    80002760:	8eca8a93          	addi	s5,s5,-1812 # 80009048 <ticks>
  for (p = proc; p < &proc[NPROC]; p++)
    80002764:	0000e917          	auipc	s2,0xe
    80002768:	aec90913          	addi	s2,s2,-1300 # 80010250 <tickslock>
    8000276c:	a839                	j	8000278a <wakeup+0x50>
        p->state = RUNNABLE;
    8000276e:	0364a823          	sw	s6,48(s1)
        p->last_runnable_time=ticks;
    80002772:	000ae783          	lwu	a5,0(s5)
    80002776:	ec9c                	sd	a5,24(s1)
      }
      release(&p->lock);
    80002778:	8526                	mv	a0,s1
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	51e080e7          	jalr	1310(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002782:	18048493          	addi	s1,s1,384
    80002786:	03248463          	beq	s1,s2,800027ae <wakeup+0x74>
    if (p != myproc())
    8000278a:	fffff097          	auipc	ra,0xfffff
    8000278e:	34a080e7          	jalr	842(ra) # 80001ad4 <myproc>
    80002792:	fea488e3          	beq	s1,a0,80002782 <wakeup+0x48>
      acquire(&p->lock);
    80002796:	8526                	mv	a0,s1
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	44c080e7          	jalr	1100(ra) # 80000be4 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800027a0:	589c                	lw	a5,48(s1)
    800027a2:	fd379be3          	bne	a5,s3,80002778 <wakeup+0x3e>
    800027a6:	7c9c                	ld	a5,56(s1)
    800027a8:	fd4798e3          	bne	a5,s4,80002778 <wakeup+0x3e>
    800027ac:	b7c9                	j	8000276e <wakeup+0x34>
    }
  }
}
    800027ae:	70e2                	ld	ra,56(sp)
    800027b0:	7442                	ld	s0,48(sp)
    800027b2:	74a2                	ld	s1,40(sp)
    800027b4:	7902                	ld	s2,32(sp)
    800027b6:	69e2                	ld	s3,24(sp)
    800027b8:	6a42                	ld	s4,16(sp)
    800027ba:	6aa2                	ld	s5,8(sp)
    800027bc:	6b02                	ld	s6,0(sp)
    800027be:	6121                	addi	sp,sp,64
    800027c0:	8082                	ret

00000000800027c2 <reparent>:
{
    800027c2:	7179                	addi	sp,sp,-48
    800027c4:	f406                	sd	ra,40(sp)
    800027c6:	f022                	sd	s0,32(sp)
    800027c8:	ec26                	sd	s1,24(sp)
    800027ca:	e84a                	sd	s2,16(sp)
    800027cc:	e44e                	sd	s3,8(sp)
    800027ce:	e052                	sd	s4,0(sp)
    800027d0:	1800                	addi	s0,sp,48
    800027d2:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800027d4:	00008497          	auipc	s1,0x8
    800027d8:	a7c48493          	addi	s1,s1,-1412 # 8000a250 <proc>
      pp->parent = initproc;
    800027dc:	00007a17          	auipc	s4,0x7
    800027e0:	84ca0a13          	addi	s4,s4,-1972 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800027e4:	0000e997          	auipc	s3,0xe
    800027e8:	a6c98993          	addi	s3,s3,-1428 # 80010250 <tickslock>
    800027ec:	a029                	j	800027f6 <reparent+0x34>
    800027ee:	18048493          	addi	s1,s1,384
    800027f2:	01348d63          	beq	s1,s3,8000280c <reparent+0x4a>
    if (pp->parent == p)
    800027f6:	68bc                	ld	a5,80(s1)
    800027f8:	ff279be3          	bne	a5,s2,800027ee <reparent+0x2c>
      pp->parent = initproc;
    800027fc:	000a3503          	ld	a0,0(s4)
    80002800:	e8a8                	sd	a0,80(s1)
      wakeup(initproc);
    80002802:	00000097          	auipc	ra,0x0
    80002806:	f38080e7          	jalr	-200(ra) # 8000273a <wakeup>
    8000280a:	b7d5                	j	800027ee <reparent+0x2c>
}
    8000280c:	70a2                	ld	ra,40(sp)
    8000280e:	7402                	ld	s0,32(sp)
    80002810:	64e2                	ld	s1,24(sp)
    80002812:	6942                	ld	s2,16(sp)
    80002814:	69a2                	ld	s3,8(sp)
    80002816:	6a02                	ld	s4,0(sp)
    80002818:	6145                	addi	sp,sp,48
    8000281a:	8082                	ret

000000008000281c <exit>:
{
    8000281c:	7179                	addi	sp,sp,-48
    8000281e:	f406                	sd	ra,40(sp)
    80002820:	f022                	sd	s0,32(sp)
    80002822:	ec26                	sd	s1,24(sp)
    80002824:	e84a                	sd	s2,16(sp)
    80002826:	e44e                	sd	s3,8(sp)
    80002828:	e052                	sd	s4,0(sp)
    8000282a:	1800                	addi	s0,sp,48
    8000282c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000282e:	fffff097          	auipc	ra,0xfffff
    80002832:	2a6080e7          	jalr	678(ra) # 80001ad4 <myproc>
    80002836:	89aa                	mv	s3,a0
  if (p == initproc)
    80002838:	00006797          	auipc	a5,0x6
    8000283c:	7f07b783          	ld	a5,2032(a5) # 80009028 <initproc>
    80002840:	0e850493          	addi	s1,a0,232
    80002844:	16850913          	addi	s2,a0,360
    80002848:	02a79363          	bne	a5,a0,8000286e <exit+0x52>
    panic("init exiting");
    8000284c:	00006517          	auipc	a0,0x6
    80002850:	a5450513          	addi	a0,a0,-1452 # 800082a0 <digits+0x260>
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	cea080e7          	jalr	-790(ra) # 8000053e <panic>
      fileclose(f);
    8000285c:	00002097          	auipc	ra,0x2
    80002860:	212080e7          	jalr	530(ra) # 80004a6e <fileclose>
      p->ofile[fd] = 0;
    80002864:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002868:	04a1                	addi	s1,s1,8
    8000286a:	01248563          	beq	s1,s2,80002874 <exit+0x58>
    if (p->ofile[fd])
    8000286e:	6088                	ld	a0,0(s1)
    80002870:	f575                	bnez	a0,8000285c <exit+0x40>
    80002872:	bfdd                	j	80002868 <exit+0x4c>
  begin_op();
    80002874:	00002097          	auipc	ra,0x2
    80002878:	d2e080e7          	jalr	-722(ra) # 800045a2 <begin_op>
  iput(p->cwd);
    8000287c:	1689b503          	ld	a0,360(s3)
    80002880:	00001097          	auipc	ra,0x1
    80002884:	50a080e7          	jalr	1290(ra) # 80003d8a <iput>
  end_op();
    80002888:	00002097          	auipc	ra,0x2
    8000288c:	d9a080e7          	jalr	-614(ra) # 80004622 <end_op>
  p->cwd = 0;
    80002890:	1609b423          	sd	zero,360(s3)
  acquire(&wait_lock);
    80002894:	00008497          	auipc	s1,0x8
    80002898:	92448493          	addi	s1,s1,-1756 # 8000a1b8 <wait_lock>
    8000289c:	8526                	mv	a0,s1
    8000289e:	ffffe097          	auipc	ra,0xffffe
    800028a2:	346080e7          	jalr	838(ra) # 80000be4 <acquire>
  reparent(p);
    800028a6:	854e                	mv	a0,s3
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	f1a080e7          	jalr	-230(ra) # 800027c2 <reparent>
  wakeup(p->parent);
    800028b0:	0509b503          	ld	a0,80(s3)
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	e86080e7          	jalr	-378(ra) # 8000273a <wakeup>
  acquire(&p->lock);
    800028bc:	854e                	mv	a0,s3
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	326080e7          	jalr	806(ra) # 80000be4 <acquire>
  p->xstate = status;
    800028c6:	0549a223          	sw	s4,68(s3)
  p->state = ZOMBIE;
    800028ca:	4795                	li	a5,5
    800028cc:	02f9a823          	sw	a5,48(s3)
  release(&wait_lock);
    800028d0:	8526                	mv	a0,s1
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	3c6080e7          	jalr	966(ra) # 80000c98 <release>
  sched();
    800028da:	00000097          	auipc	ra,0x0
    800028de:	b22080e7          	jalr	-1246(ra) # 800023fc <sched>
  printf("exit");
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	9ce50513          	addi	a0,a0,-1586 # 800082b0 <digits+0x270>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c9e080e7          	jalr	-866(ra) # 80000588 <printf>
  panic("zombie exit");
    800028f2:	00006517          	auipc	a0,0x6
    800028f6:	9c650513          	addi	a0,a0,-1594 # 800082b8 <digits+0x278>
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	c44080e7          	jalr	-956(ra) # 8000053e <panic>

0000000080002902 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002902:	7179                	addi	sp,sp,-48
    80002904:	f406                	sd	ra,40(sp)
    80002906:	f022                	sd	s0,32(sp)
    80002908:	ec26                	sd	s1,24(sp)
    8000290a:	e84a                	sd	s2,16(sp)
    8000290c:	e44e                	sd	s3,8(sp)
    8000290e:	1800                	addi	s0,sp,48
    80002910:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002912:	00008497          	auipc	s1,0x8
    80002916:	93e48493          	addi	s1,s1,-1730 # 8000a250 <proc>
    8000291a:	0000e997          	auipc	s3,0xe
    8000291e:	93698993          	addi	s3,s3,-1738 # 80010250 <tickslock>
  {
    acquire(&p->lock);
    80002922:	8526                	mv	a0,s1
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	2c0080e7          	jalr	704(ra) # 80000be4 <acquire>
    if (p->pid == pid)
    8000292c:	44bc                	lw	a5,72(s1)
    8000292e:	01278d63          	beq	a5,s2,80002948 <kill+0x46>
        p->last_runnable_time=ticks;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002932:	8526                	mv	a0,s1
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	364080e7          	jalr	868(ra) # 80000c98 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000293c:	18048493          	addi	s1,s1,384
    80002940:	ff3491e3          	bne	s1,s3,80002922 <kill+0x20>
  }
  return -1;
    80002944:	557d                	li	a0,-1
    80002946:	a829                	j	80002960 <kill+0x5e>
      p->killed = 1;
    80002948:	4785                	li	a5,1
    8000294a:	c0bc                	sw	a5,64(s1)
      if (p->state == SLEEPING)
    8000294c:	5898                	lw	a4,48(s1)
    8000294e:	4789                	li	a5,2
    80002950:	00f70f63          	beq	a4,a5,8000296e <kill+0x6c>
      release(&p->lock);
    80002954:	8526                	mv	a0,s1
    80002956:	ffffe097          	auipc	ra,0xffffe
    8000295a:	342080e7          	jalr	834(ra) # 80000c98 <release>
      return 0;
    8000295e:	4501                	li	a0,0
}
    80002960:	70a2                	ld	ra,40(sp)
    80002962:	7402                	ld	s0,32(sp)
    80002964:	64e2                	ld	s1,24(sp)
    80002966:	6942                	ld	s2,16(sp)
    80002968:	69a2                	ld	s3,8(sp)
    8000296a:	6145                	addi	sp,sp,48
    8000296c:	8082                	ret
        p->state = RUNNABLE;
    8000296e:	478d                	li	a5,3
    80002970:	d89c                	sw	a5,48(s1)
        p->last_runnable_time=ticks;
    80002972:	00006797          	auipc	a5,0x6
    80002976:	6d67e783          	lwu	a5,1750(a5) # 80009048 <ticks>
    8000297a:	ec9c                	sd	a5,24(s1)
    8000297c:	bfe1                	j	80002954 <kill+0x52>

000000008000297e <kill_system>:
{
    8000297e:	7179                	addi	sp,sp,-48
    80002980:	f406                	sd	ra,40(sp)
    80002982:	f022                	sd	s0,32(sp)
    80002984:	ec26                	sd	s1,24(sp)
    80002986:	e84a                	sd	s2,16(sp)
    80002988:	e44e                	sd	s3,8(sp)
    8000298a:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    8000298c:	00008497          	auipc	s1,0x8
    80002990:	8c448493          	addi	s1,s1,-1852 # 8000a250 <proc>
    if (p->pid > 2) // init process and shell?
    80002994:	4989                	li	s3,2
  for (p = proc; p < &proc[NPROC]; p++)
    80002996:	0000e917          	auipc	s2,0xe
    8000299a:	8ba90913          	addi	s2,s2,-1862 # 80010250 <tickslock>
    8000299e:	a809                	j	800029b0 <kill_system+0x32>
      kill(p->pid);
    800029a0:	00000097          	auipc	ra,0x0
    800029a4:	f62080e7          	jalr	-158(ra) # 80002902 <kill>
  for (p = proc; p < &proc[NPROC]; p++)
    800029a8:	18048493          	addi	s1,s1,384
    800029ac:	01248663          	beq	s1,s2,800029b8 <kill_system+0x3a>
    if (p->pid > 2) // init process and shell?
    800029b0:	44a8                	lw	a0,72(s1)
    800029b2:	fea9dbe3          	bge	s3,a0,800029a8 <kill_system+0x2a>
    800029b6:	b7ed                	j	800029a0 <kill_system+0x22>
}
    800029b8:	4501                	li	a0,0
    800029ba:	70a2                	ld	ra,40(sp)
    800029bc:	7402                	ld	s0,32(sp)
    800029be:	64e2                	ld	s1,24(sp)
    800029c0:	6942                	ld	s2,16(sp)
    800029c2:	69a2                	ld	s3,8(sp)
    800029c4:	6145                	addi	sp,sp,48
    800029c6:	8082                	ret

00000000800029c8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029c8:	7179                	addi	sp,sp,-48
    800029ca:	f406                	sd	ra,40(sp)
    800029cc:	f022                	sd	s0,32(sp)
    800029ce:	ec26                	sd	s1,24(sp)
    800029d0:	e84a                	sd	s2,16(sp)
    800029d2:	e44e                	sd	s3,8(sp)
    800029d4:	e052                	sd	s4,0(sp)
    800029d6:	1800                	addi	s0,sp,48
    800029d8:	84aa                	mv	s1,a0
    800029da:	892e                	mv	s2,a1
    800029dc:	89b2                	mv	s3,a2
    800029de:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029e0:	fffff097          	auipc	ra,0xfffff
    800029e4:	0f4080e7          	jalr	244(ra) # 80001ad4 <myproc>
  if (user_dst)
    800029e8:	c08d                	beqz	s1,80002a0a <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800029ea:	86d2                	mv	a3,s4
    800029ec:	864e                	mv	a2,s3
    800029ee:	85ca                	mv	a1,s2
    800029f0:	7528                	ld	a0,104(a0)
    800029f2:	fffff097          	auipc	ra,0xfffff
    800029f6:	da4080e7          	jalr	-604(ra) # 80001796 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029fa:	70a2                	ld	ra,40(sp)
    800029fc:	7402                	ld	s0,32(sp)
    800029fe:	64e2                	ld	s1,24(sp)
    80002a00:	6942                	ld	s2,16(sp)
    80002a02:	69a2                	ld	s3,8(sp)
    80002a04:	6a02                	ld	s4,0(sp)
    80002a06:	6145                	addi	sp,sp,48
    80002a08:	8082                	ret
    memmove((char *)dst, src, len);
    80002a0a:	000a061b          	sext.w	a2,s4
    80002a0e:	85ce                	mv	a1,s3
    80002a10:	854a                	mv	a0,s2
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	32e080e7          	jalr	814(ra) # 80000d40 <memmove>
    return 0;
    80002a1a:	8526                	mv	a0,s1
    80002a1c:	bff9                	j	800029fa <either_copyout+0x32>

0000000080002a1e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a1e:	7179                	addi	sp,sp,-48
    80002a20:	f406                	sd	ra,40(sp)
    80002a22:	f022                	sd	s0,32(sp)
    80002a24:	ec26                	sd	s1,24(sp)
    80002a26:	e84a                	sd	s2,16(sp)
    80002a28:	e44e                	sd	s3,8(sp)
    80002a2a:	e052                	sd	s4,0(sp)
    80002a2c:	1800                	addi	s0,sp,48
    80002a2e:	892a                	mv	s2,a0
    80002a30:	84ae                	mv	s1,a1
    80002a32:	89b2                	mv	s3,a2
    80002a34:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	09e080e7          	jalr	158(ra) # 80001ad4 <myproc>
  if (user_src)
    80002a3e:	c08d                	beqz	s1,80002a60 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002a40:	86d2                	mv	a3,s4
    80002a42:	864e                	mv	a2,s3
    80002a44:	85ca                	mv	a1,s2
    80002a46:	7528                	ld	a0,104(a0)
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	dda080e7          	jalr	-550(ra) # 80001822 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002a50:	70a2                	ld	ra,40(sp)
    80002a52:	7402                	ld	s0,32(sp)
    80002a54:	64e2                	ld	s1,24(sp)
    80002a56:	6942                	ld	s2,16(sp)
    80002a58:	69a2                	ld	s3,8(sp)
    80002a5a:	6a02                	ld	s4,0(sp)
    80002a5c:	6145                	addi	sp,sp,48
    80002a5e:	8082                	ret
    memmove(dst, (char *)src, len);
    80002a60:	000a061b          	sext.w	a2,s4
    80002a64:	85ce                	mv	a1,s3
    80002a66:	854a                	mv	a0,s2
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	2d8080e7          	jalr	728(ra) # 80000d40 <memmove>
    return 0;
    80002a70:	8526                	mv	a0,s1
    80002a72:	bff9                	j	80002a50 <either_copyin+0x32>

0000000080002a74 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002a74:	715d                	addi	sp,sp,-80
    80002a76:	e486                	sd	ra,72(sp)
    80002a78:	e0a2                	sd	s0,64(sp)
    80002a7a:	fc26                	sd	s1,56(sp)
    80002a7c:	f84a                	sd	s2,48(sp)
    80002a7e:	f44e                	sd	s3,40(sp)
    80002a80:	f052                	sd	s4,32(sp)
    80002a82:	ec56                	sd	s5,24(sp)
    80002a84:	e85a                	sd	s6,16(sp)
    80002a86:	e45e                	sd	s7,8(sp)
    80002a88:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002a8a:	00005517          	auipc	a0,0x5
    80002a8e:	67e50513          	addi	a0,a0,1662 # 80008108 <digits+0xc8>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	af6080e7          	jalr	-1290(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a9a:	00008497          	auipc	s1,0x8
    80002a9e:	92648493          	addi	s1,s1,-1754 # 8000a3c0 <proc+0x170>
    80002aa2:	0000e917          	auipc	s2,0xe
    80002aa6:	91e90913          	addi	s2,s2,-1762 # 800103c0 <bcache+0x158>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aaa:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002aac:	00006997          	auipc	s3,0x6
    80002ab0:	81c98993          	addi	s3,s3,-2020 # 800082c8 <digits+0x288>
    printf("%d %s %s", p->pid, state, p->name);
    80002ab4:	00006a97          	auipc	s5,0x6
    80002ab8:	81ca8a93          	addi	s5,s5,-2020 # 800082d0 <digits+0x290>
    printf("\n");
    80002abc:	00005a17          	auipc	s4,0x5
    80002ac0:	64ca0a13          	addi	s4,s4,1612 # 80008108 <digits+0xc8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ac4:	00006b97          	auipc	s7,0x6
    80002ac8:	844b8b93          	addi	s7,s7,-1980 # 80008308 <states.1766>
    80002acc:	a00d                	j	80002aee <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002ace:	ed86a583          	lw	a1,-296(a3)
    80002ad2:	8556                	mv	a0,s5
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	ab4080e7          	jalr	-1356(ra) # 80000588 <printf>
    printf("\n");
    80002adc:	8552                	mv	a0,s4
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	aaa080e7          	jalr	-1366(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ae6:	18048493          	addi	s1,s1,384
    80002aea:	03248163          	beq	s1,s2,80002b0c <procdump+0x98>
    if (p->state == UNUSED)
    80002aee:	86a6                	mv	a3,s1
    80002af0:	ec04a783          	lw	a5,-320(s1)
    80002af4:	dbed                	beqz	a5,80002ae6 <procdump+0x72>
      state = "???";
    80002af6:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002af8:	fcfb6be3          	bltu	s6,a5,80002ace <procdump+0x5a>
    80002afc:	1782                	slli	a5,a5,0x20
    80002afe:	9381                	srli	a5,a5,0x20
    80002b00:	078e                	slli	a5,a5,0x3
    80002b02:	97de                	add	a5,a5,s7
    80002b04:	6390                	ld	a2,0(a5)
    80002b06:	f661                	bnez	a2,80002ace <procdump+0x5a>
      state = "???";
    80002b08:	864e                	mv	a2,s3
    80002b0a:	b7d1                	j	80002ace <procdump+0x5a>
  }
}
    80002b0c:	60a6                	ld	ra,72(sp)
    80002b0e:	6406                	ld	s0,64(sp)
    80002b10:	74e2                	ld	s1,56(sp)
    80002b12:	7942                	ld	s2,48(sp)
    80002b14:	79a2                	ld	s3,40(sp)
    80002b16:	7a02                	ld	s4,32(sp)
    80002b18:	6ae2                	ld	s5,24(sp)
    80002b1a:	6b42                	ld	s6,16(sp)
    80002b1c:	6ba2                	ld	s7,8(sp)
    80002b1e:	6161                	addi	sp,sp,80
    80002b20:	8082                	ret

0000000080002b22 <swtch>:
    80002b22:	00153023          	sd	ra,0(a0)
    80002b26:	00253423          	sd	sp,8(a0)
    80002b2a:	e900                	sd	s0,16(a0)
    80002b2c:	ed04                	sd	s1,24(a0)
    80002b2e:	03253023          	sd	s2,32(a0)
    80002b32:	03353423          	sd	s3,40(a0)
    80002b36:	03453823          	sd	s4,48(a0)
    80002b3a:	03553c23          	sd	s5,56(a0)
    80002b3e:	05653023          	sd	s6,64(a0)
    80002b42:	05753423          	sd	s7,72(a0)
    80002b46:	05853823          	sd	s8,80(a0)
    80002b4a:	05953c23          	sd	s9,88(a0)
    80002b4e:	07a53023          	sd	s10,96(a0)
    80002b52:	07b53423          	sd	s11,104(a0)
    80002b56:	0005b083          	ld	ra,0(a1)
    80002b5a:	0085b103          	ld	sp,8(a1)
    80002b5e:	6980                	ld	s0,16(a1)
    80002b60:	6d84                	ld	s1,24(a1)
    80002b62:	0205b903          	ld	s2,32(a1)
    80002b66:	0285b983          	ld	s3,40(a1)
    80002b6a:	0305ba03          	ld	s4,48(a1)
    80002b6e:	0385ba83          	ld	s5,56(a1)
    80002b72:	0405bb03          	ld	s6,64(a1)
    80002b76:	0485bb83          	ld	s7,72(a1)
    80002b7a:	0505bc03          	ld	s8,80(a1)
    80002b7e:	0585bc83          	ld	s9,88(a1)
    80002b82:	0605bd03          	ld	s10,96(a1)
    80002b86:	0685bd83          	ld	s11,104(a1)
    80002b8a:	8082                	ret

0000000080002b8c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b8c:	1141                	addi	sp,sp,-16
    80002b8e:	e406                	sd	ra,8(sp)
    80002b90:	e022                	sd	s0,0(sp)
    80002b92:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b94:	00005597          	auipc	a1,0x5
    80002b98:	7a458593          	addi	a1,a1,1956 # 80008338 <states.1766+0x30>
    80002b9c:	0000d517          	auipc	a0,0xd
    80002ba0:	6b450513          	addi	a0,a0,1716 # 80010250 <tickslock>
    80002ba4:	ffffe097          	auipc	ra,0xffffe
    80002ba8:	fb0080e7          	jalr	-80(ra) # 80000b54 <initlock>
}
    80002bac:	60a2                	ld	ra,8(sp)
    80002bae:	6402                	ld	s0,0(sp)
    80002bb0:	0141                	addi	sp,sp,16
    80002bb2:	8082                	ret

0000000080002bb4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002bb4:	1141                	addi	sp,sp,-16
    80002bb6:	e422                	sd	s0,8(sp)
    80002bb8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bba:	00003797          	auipc	a5,0x3
    80002bbe:	4d678793          	addi	a5,a5,1238 # 80006090 <kernelvec>
    80002bc2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bc6:	6422                	ld	s0,8(sp)
    80002bc8:	0141                	addi	sp,sp,16
    80002bca:	8082                	ret

0000000080002bcc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bcc:	1141                	addi	sp,sp,-16
    80002bce:	e406                	sd	ra,8(sp)
    80002bd0:	e022                	sd	s0,0(sp)
    80002bd2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	f00080e7          	jalr	-256(ra) # 80001ad4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bdc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002be0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002be6:	00004617          	auipc	a2,0x4
    80002bea:	41a60613          	addi	a2,a2,1050 # 80007000 <_trampoline>
    80002bee:	00004697          	auipc	a3,0x4
    80002bf2:	41268693          	addi	a3,a3,1042 # 80007000 <_trampoline>
    80002bf6:	8e91                	sub	a3,a3,a2
    80002bf8:	040007b7          	lui	a5,0x4000
    80002bfc:	17fd                	addi	a5,a5,-1
    80002bfe:	07b2                	slli	a5,a5,0xc
    80002c00:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c02:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c06:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c08:	180026f3          	csrr	a3,satp
    80002c0c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c0e:	7938                	ld	a4,112(a0)
    80002c10:	6d34                	ld	a3,88(a0)
    80002c12:	6585                	lui	a1,0x1
    80002c14:	96ae                	add	a3,a3,a1
    80002c16:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c18:	7938                	ld	a4,112(a0)
    80002c1a:	00000697          	auipc	a3,0x0
    80002c1e:	13868693          	addi	a3,a3,312 # 80002d52 <usertrap>
    80002c22:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c24:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c26:	8692                	mv	a3,tp
    80002c28:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c2a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c2e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c32:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c36:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c3a:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c3c:	6f18                	ld	a4,24(a4)
    80002c3e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c42:	752c                	ld	a1,104(a0)
    80002c44:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c46:	00004717          	auipc	a4,0x4
    80002c4a:	44a70713          	addi	a4,a4,1098 # 80007090 <userret>
    80002c4e:	8f11                	sub	a4,a4,a2
    80002c50:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c52:	577d                	li	a4,-1
    80002c54:	177e                	slli	a4,a4,0x3f
    80002c56:	8dd9                	or	a1,a1,a4
    80002c58:	02000537          	lui	a0,0x2000
    80002c5c:	157d                	addi	a0,a0,-1
    80002c5e:	0536                	slli	a0,a0,0xd
    80002c60:	9782                	jalr	a5
}
    80002c62:	60a2                	ld	ra,8(sp)
    80002c64:	6402                	ld	s0,0(sp)
    80002c66:	0141                	addi	sp,sp,16
    80002c68:	8082                	ret

0000000080002c6a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c6a:	1101                	addi	sp,sp,-32
    80002c6c:	ec06                	sd	ra,24(sp)
    80002c6e:	e822                	sd	s0,16(sp)
    80002c70:	e426                	sd	s1,8(sp)
    80002c72:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c74:	0000d497          	auipc	s1,0xd
    80002c78:	5dc48493          	addi	s1,s1,1500 # 80010250 <tickslock>
    80002c7c:	8526                	mv	a0,s1
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	f66080e7          	jalr	-154(ra) # 80000be4 <acquire>
  ticks++;
    80002c86:	00006517          	auipc	a0,0x6
    80002c8a:	3c250513          	addi	a0,a0,962 # 80009048 <ticks>
    80002c8e:	411c                	lw	a5,0(a0)
    80002c90:	2785                	addiw	a5,a5,1
    80002c92:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	aa6080e7          	jalr	-1370(ra) # 8000273a <wakeup>
  release(&tickslock);
    80002c9c:	8526                	mv	a0,s1
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	ffa080e7          	jalr	-6(ra) # 80000c98 <release>
}
    80002ca6:	60e2                	ld	ra,24(sp)
    80002ca8:	6442                	ld	s0,16(sp)
    80002caa:	64a2                	ld	s1,8(sp)
    80002cac:	6105                	addi	sp,sp,32
    80002cae:	8082                	ret

0000000080002cb0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002cb0:	1101                	addi	sp,sp,-32
    80002cb2:	ec06                	sd	ra,24(sp)
    80002cb4:	e822                	sd	s0,16(sp)
    80002cb6:	e426                	sd	s1,8(sp)
    80002cb8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cba:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002cbe:	00074d63          	bltz	a4,80002cd8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cc2:	57fd                	li	a5,-1
    80002cc4:	17fe                	slli	a5,a5,0x3f
    80002cc6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cc8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cca:	06f70363          	beq	a4,a5,80002d30 <devintr+0x80>
  }
}
    80002cce:	60e2                	ld	ra,24(sp)
    80002cd0:	6442                	ld	s0,16(sp)
    80002cd2:	64a2                	ld	s1,8(sp)
    80002cd4:	6105                	addi	sp,sp,32
    80002cd6:	8082                	ret
     (scause & 0xff) == 9){
    80002cd8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cdc:	46a5                	li	a3,9
    80002cde:	fed792e3          	bne	a5,a3,80002cc2 <devintr+0x12>
    int irq = plic_claim();
    80002ce2:	00003097          	auipc	ra,0x3
    80002ce6:	4b6080e7          	jalr	1206(ra) # 80006198 <plic_claim>
    80002cea:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cec:	47a9                	li	a5,10
    80002cee:	02f50763          	beq	a0,a5,80002d1c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cf2:	4785                	li	a5,1
    80002cf4:	02f50963          	beq	a0,a5,80002d26 <devintr+0x76>
    return 1;
    80002cf8:	4505                	li	a0,1
    } else if(irq){
    80002cfa:	d8f1                	beqz	s1,80002cce <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cfc:	85a6                	mv	a1,s1
    80002cfe:	00005517          	auipc	a0,0x5
    80002d02:	64250513          	addi	a0,a0,1602 # 80008340 <states.1766+0x38>
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	882080e7          	jalr	-1918(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d0e:	8526                	mv	a0,s1
    80002d10:	00003097          	auipc	ra,0x3
    80002d14:	4ac080e7          	jalr	1196(ra) # 800061bc <plic_complete>
    return 1;
    80002d18:	4505                	li	a0,1
    80002d1a:	bf55                	j	80002cce <devintr+0x1e>
      uartintr();
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	c8c080e7          	jalr	-884(ra) # 800009a8 <uartintr>
    80002d24:	b7ed                	j	80002d0e <devintr+0x5e>
      virtio_disk_intr();
    80002d26:	00004097          	auipc	ra,0x4
    80002d2a:	976080e7          	jalr	-1674(ra) # 8000669c <virtio_disk_intr>
    80002d2e:	b7c5                	j	80002d0e <devintr+0x5e>
    if(cpuid() == 0){
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	d78080e7          	jalr	-648(ra) # 80001aa8 <cpuid>
    80002d38:	c901                	beqz	a0,80002d48 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d3a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d3e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d40:	14479073          	csrw	sip,a5
    return 2;
    80002d44:	4509                	li	a0,2
    80002d46:	b761                	j	80002cce <devintr+0x1e>
      clockintr();
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	f22080e7          	jalr	-222(ra) # 80002c6a <clockintr>
    80002d50:	b7ed                	j	80002d3a <devintr+0x8a>

0000000080002d52 <usertrap>:
{
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	e426                	sd	s1,8(sp)
    80002d5a:	e04a                	sd	s2,0(sp)
    80002d5c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d62:	1007f793          	andi	a5,a5,256
    80002d66:	e3ad                	bnez	a5,80002dc8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d68:	00003797          	auipc	a5,0x3
    80002d6c:	32878793          	addi	a5,a5,808 # 80006090 <kernelvec>
    80002d70:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d74:	fffff097          	auipc	ra,0xfffff
    80002d78:	d60080e7          	jalr	-672(ra) # 80001ad4 <myproc>
    80002d7c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d7e:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d80:	14102773          	csrr	a4,sepc
    80002d84:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d86:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d8a:	47a1                	li	a5,8
    80002d8c:	04f71c63          	bne	a4,a5,80002de4 <usertrap+0x92>
    if(p->killed)
    80002d90:	413c                	lw	a5,64(a0)
    80002d92:	e3b9                	bnez	a5,80002dd8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d94:	78b8                	ld	a4,112(s1)
    80002d96:	6f1c                	ld	a5,24(a4)
    80002d98:	0791                	addi	a5,a5,4
    80002d9a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002da0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002da4:	10079073          	csrw	sstatus,a5
    syscall();
    80002da8:	00000097          	auipc	ra,0x0
    80002dac:	2e0080e7          	jalr	736(ra) # 80003088 <syscall>
  if(p->killed)
    80002db0:	40bc                	lw	a5,64(s1)
    80002db2:	ebc1                	bnez	a5,80002e42 <usertrap+0xf0>
  usertrapret();
    80002db4:	00000097          	auipc	ra,0x0
    80002db8:	e18080e7          	jalr	-488(ra) # 80002bcc <usertrapret>
}
    80002dbc:	60e2                	ld	ra,24(sp)
    80002dbe:	6442                	ld	s0,16(sp)
    80002dc0:	64a2                	ld	s1,8(sp)
    80002dc2:	6902                	ld	s2,0(sp)
    80002dc4:	6105                	addi	sp,sp,32
    80002dc6:	8082                	ret
    panic("usertrap: not from user mode");
    80002dc8:	00005517          	auipc	a0,0x5
    80002dcc:	59850513          	addi	a0,a0,1432 # 80008360 <states.1766+0x58>
    80002dd0:	ffffd097          	auipc	ra,0xffffd
    80002dd4:	76e080e7          	jalr	1902(ra) # 8000053e <panic>
      exit(-1);
    80002dd8:	557d                	li	a0,-1
    80002dda:	00000097          	auipc	ra,0x0
    80002dde:	a42080e7          	jalr	-1470(ra) # 8000281c <exit>
    80002de2:	bf4d                	j	80002d94 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	ecc080e7          	jalr	-308(ra) # 80002cb0 <devintr>
    80002dec:	892a                	mv	s2,a0
    80002dee:	c501                	beqz	a0,80002df6 <usertrap+0xa4>
  if(p->killed)
    80002df0:	40bc                	lw	a5,64(s1)
    80002df2:	c3a1                	beqz	a5,80002e32 <usertrap+0xe0>
    80002df4:	a815                	j	80002e28 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002df6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002dfa:	44b0                	lw	a2,72(s1)
    80002dfc:	00005517          	auipc	a0,0x5
    80002e00:	58450513          	addi	a0,a0,1412 # 80008380 <states.1766+0x78>
    80002e04:	ffffd097          	auipc	ra,0xffffd
    80002e08:	784080e7          	jalr	1924(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e0c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e10:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e14:	00005517          	auipc	a0,0x5
    80002e18:	59c50513          	addi	a0,a0,1436 # 800083b0 <states.1766+0xa8>
    80002e1c:	ffffd097          	auipc	ra,0xffffd
    80002e20:	76c080e7          	jalr	1900(ra) # 80000588 <printf>
    p->killed = 1;
    80002e24:	4785                	li	a5,1
    80002e26:	c0bc                	sw	a5,64(s1)
    exit(-1);
    80002e28:	557d                	li	a0,-1
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	9f2080e7          	jalr	-1550(ra) # 8000281c <exit>
  if(which_dev == 2)
    80002e32:	4789                	li	a5,2
    80002e34:	f8f910e3          	bne	s2,a5,80002db4 <usertrap+0x62>
    yield();
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	69a080e7          	jalr	1690(ra) # 800024d2 <yield>
    80002e40:	bf95                	j	80002db4 <usertrap+0x62>
  int which_dev = 0;
    80002e42:	4901                	li	s2,0
    80002e44:	b7d5                	j	80002e28 <usertrap+0xd6>

0000000080002e46 <kerneltrap>:
{
    80002e46:	7179                	addi	sp,sp,-48
    80002e48:	f406                	sd	ra,40(sp)
    80002e4a:	f022                	sd	s0,32(sp)
    80002e4c:	ec26                	sd	s1,24(sp)
    80002e4e:	e84a                	sd	s2,16(sp)
    80002e50:	e44e                	sd	s3,8(sp)
    80002e52:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e54:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e58:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e5c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e60:	1004f793          	andi	a5,s1,256
    80002e64:	cb85                	beqz	a5,80002e94 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e66:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e6a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e6c:	ef85                	bnez	a5,80002ea4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	e42080e7          	jalr	-446(ra) # 80002cb0 <devintr>
    80002e76:	cd1d                	beqz	a0,80002eb4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e78:	4789                	li	a5,2
    80002e7a:	06f50a63          	beq	a0,a5,80002eee <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e7e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e82:	10049073          	csrw	sstatus,s1
}
    80002e86:	70a2                	ld	ra,40(sp)
    80002e88:	7402                	ld	s0,32(sp)
    80002e8a:	64e2                	ld	s1,24(sp)
    80002e8c:	6942                	ld	s2,16(sp)
    80002e8e:	69a2                	ld	s3,8(sp)
    80002e90:	6145                	addi	sp,sp,48
    80002e92:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e94:	00005517          	auipc	a0,0x5
    80002e98:	53c50513          	addi	a0,a0,1340 # 800083d0 <states.1766+0xc8>
    80002e9c:	ffffd097          	auipc	ra,0xffffd
    80002ea0:	6a2080e7          	jalr	1698(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ea4:	00005517          	auipc	a0,0x5
    80002ea8:	55450513          	addi	a0,a0,1364 # 800083f8 <states.1766+0xf0>
    80002eac:	ffffd097          	auipc	ra,0xffffd
    80002eb0:	692080e7          	jalr	1682(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002eb4:	85ce                	mv	a1,s3
    80002eb6:	00005517          	auipc	a0,0x5
    80002eba:	56250513          	addi	a0,a0,1378 # 80008418 <states.1766+0x110>
    80002ebe:	ffffd097          	auipc	ra,0xffffd
    80002ec2:	6ca080e7          	jalr	1738(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eca:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ece:	00005517          	auipc	a0,0x5
    80002ed2:	55a50513          	addi	a0,a0,1370 # 80008428 <states.1766+0x120>
    80002ed6:	ffffd097          	auipc	ra,0xffffd
    80002eda:	6b2080e7          	jalr	1714(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ede:	00005517          	auipc	a0,0x5
    80002ee2:	56250513          	addi	a0,a0,1378 # 80008440 <states.1766+0x138>
    80002ee6:	ffffd097          	auipc	ra,0xffffd
    80002eea:	658080e7          	jalr	1624(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	be6080e7          	jalr	-1050(ra) # 80001ad4 <myproc>
    80002ef6:	d541                	beqz	a0,80002e7e <kerneltrap+0x38>
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	bdc080e7          	jalr	-1060(ra) # 80001ad4 <myproc>
    80002f00:	5918                	lw	a4,48(a0)
    80002f02:	4791                	li	a5,4
    80002f04:	f6f71de3          	bne	a4,a5,80002e7e <kerneltrap+0x38>
    yield();
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	5ca080e7          	jalr	1482(ra) # 800024d2 <yield>
    80002f10:	b7bd                	j	80002e7e <kerneltrap+0x38>

0000000080002f12 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f12:	1101                	addi	sp,sp,-32
    80002f14:	ec06                	sd	ra,24(sp)
    80002f16:	e822                	sd	s0,16(sp)
    80002f18:	e426                	sd	s1,8(sp)
    80002f1a:	1000                	addi	s0,sp,32
    80002f1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	bb6080e7          	jalr	-1098(ra) # 80001ad4 <myproc>
  switch (n) {
    80002f26:	4795                	li	a5,5
    80002f28:	0497e163          	bltu	a5,s1,80002f6a <argraw+0x58>
    80002f2c:	048a                	slli	s1,s1,0x2
    80002f2e:	00005717          	auipc	a4,0x5
    80002f32:	54a70713          	addi	a4,a4,1354 # 80008478 <states.1766+0x170>
    80002f36:	94ba                	add	s1,s1,a4
    80002f38:	409c                	lw	a5,0(s1)
    80002f3a:	97ba                	add	a5,a5,a4
    80002f3c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f3e:	793c                	ld	a5,112(a0)
    80002f40:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f42:	60e2                	ld	ra,24(sp)
    80002f44:	6442                	ld	s0,16(sp)
    80002f46:	64a2                	ld	s1,8(sp)
    80002f48:	6105                	addi	sp,sp,32
    80002f4a:	8082                	ret
    return p->trapframe->a1;
    80002f4c:	793c                	ld	a5,112(a0)
    80002f4e:	7fa8                	ld	a0,120(a5)
    80002f50:	bfcd                	j	80002f42 <argraw+0x30>
    return p->trapframe->a2;
    80002f52:	793c                	ld	a5,112(a0)
    80002f54:	63c8                	ld	a0,128(a5)
    80002f56:	b7f5                	j	80002f42 <argraw+0x30>
    return p->trapframe->a3;
    80002f58:	793c                	ld	a5,112(a0)
    80002f5a:	67c8                	ld	a0,136(a5)
    80002f5c:	b7dd                	j	80002f42 <argraw+0x30>
    return p->trapframe->a4;
    80002f5e:	793c                	ld	a5,112(a0)
    80002f60:	6bc8                	ld	a0,144(a5)
    80002f62:	b7c5                	j	80002f42 <argraw+0x30>
    return p->trapframe->a5;
    80002f64:	793c                	ld	a5,112(a0)
    80002f66:	6fc8                	ld	a0,152(a5)
    80002f68:	bfe9                	j	80002f42 <argraw+0x30>
  panic("argraw");
    80002f6a:	00005517          	auipc	a0,0x5
    80002f6e:	4e650513          	addi	a0,a0,1254 # 80008450 <states.1766+0x148>
    80002f72:	ffffd097          	auipc	ra,0xffffd
    80002f76:	5cc080e7          	jalr	1484(ra) # 8000053e <panic>

0000000080002f7a <fetchaddr>:
{
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	e426                	sd	s1,8(sp)
    80002f82:	e04a                	sd	s2,0(sp)
    80002f84:	1000                	addi	s0,sp,32
    80002f86:	84aa                	mv	s1,a0
    80002f88:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	b4a080e7          	jalr	-1206(ra) # 80001ad4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002f92:	713c                	ld	a5,96(a0)
    80002f94:	02f4f863          	bgeu	s1,a5,80002fc4 <fetchaddr+0x4a>
    80002f98:	00848713          	addi	a4,s1,8
    80002f9c:	02e7e663          	bltu	a5,a4,80002fc8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fa0:	46a1                	li	a3,8
    80002fa2:	8626                	mv	a2,s1
    80002fa4:	85ca                	mv	a1,s2
    80002fa6:	7528                	ld	a0,104(a0)
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	87a080e7          	jalr	-1926(ra) # 80001822 <copyin>
    80002fb0:	00a03533          	snez	a0,a0
    80002fb4:	40a00533          	neg	a0,a0
}
    80002fb8:	60e2                	ld	ra,24(sp)
    80002fba:	6442                	ld	s0,16(sp)
    80002fbc:	64a2                	ld	s1,8(sp)
    80002fbe:	6902                	ld	s2,0(sp)
    80002fc0:	6105                	addi	sp,sp,32
    80002fc2:	8082                	ret
    return -1;
    80002fc4:	557d                	li	a0,-1
    80002fc6:	bfcd                	j	80002fb8 <fetchaddr+0x3e>
    80002fc8:	557d                	li	a0,-1
    80002fca:	b7fd                	j	80002fb8 <fetchaddr+0x3e>

0000000080002fcc <fetchstr>:
{
    80002fcc:	7179                	addi	sp,sp,-48
    80002fce:	f406                	sd	ra,40(sp)
    80002fd0:	f022                	sd	s0,32(sp)
    80002fd2:	ec26                	sd	s1,24(sp)
    80002fd4:	e84a                	sd	s2,16(sp)
    80002fd6:	e44e                	sd	s3,8(sp)
    80002fd8:	1800                	addi	s0,sp,48
    80002fda:	892a                	mv	s2,a0
    80002fdc:	84ae                	mv	s1,a1
    80002fde:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	af4080e7          	jalr	-1292(ra) # 80001ad4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002fe8:	86ce                	mv	a3,s3
    80002fea:	864a                	mv	a2,s2
    80002fec:	85a6                	mv	a1,s1
    80002fee:	7528                	ld	a0,104(a0)
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	8be080e7          	jalr	-1858(ra) # 800018ae <copyinstr>
  if(err < 0)
    80002ff8:	00054763          	bltz	a0,80003006 <fetchstr+0x3a>
  return strlen(buf);
    80002ffc:	8526                	mv	a0,s1
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	e66080e7          	jalr	-410(ra) # 80000e64 <strlen>
}
    80003006:	70a2                	ld	ra,40(sp)
    80003008:	7402                	ld	s0,32(sp)
    8000300a:	64e2                	ld	s1,24(sp)
    8000300c:	6942                	ld	s2,16(sp)
    8000300e:	69a2                	ld	s3,8(sp)
    80003010:	6145                	addi	sp,sp,48
    80003012:	8082                	ret

0000000080003014 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003014:	1101                	addi	sp,sp,-32
    80003016:	ec06                	sd	ra,24(sp)
    80003018:	e822                	sd	s0,16(sp)
    8000301a:	e426                	sd	s1,8(sp)
    8000301c:	1000                	addi	s0,sp,32
    8000301e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003020:	00000097          	auipc	ra,0x0
    80003024:	ef2080e7          	jalr	-270(ra) # 80002f12 <argraw>
    80003028:	c088                	sw	a0,0(s1)
  return 0;
}
    8000302a:	4501                	li	a0,0
    8000302c:	60e2                	ld	ra,24(sp)
    8000302e:	6442                	ld	s0,16(sp)
    80003030:	64a2                	ld	s1,8(sp)
    80003032:	6105                	addi	sp,sp,32
    80003034:	8082                	ret

0000000080003036 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003036:	1101                	addi	sp,sp,-32
    80003038:	ec06                	sd	ra,24(sp)
    8000303a:	e822                	sd	s0,16(sp)
    8000303c:	e426                	sd	s1,8(sp)
    8000303e:	1000                	addi	s0,sp,32
    80003040:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003042:	00000097          	auipc	ra,0x0
    80003046:	ed0080e7          	jalr	-304(ra) # 80002f12 <argraw>
    8000304a:	e088                	sd	a0,0(s1)
  return 0;
}
    8000304c:	4501                	li	a0,0
    8000304e:	60e2                	ld	ra,24(sp)
    80003050:	6442                	ld	s0,16(sp)
    80003052:	64a2                	ld	s1,8(sp)
    80003054:	6105                	addi	sp,sp,32
    80003056:	8082                	ret

0000000080003058 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003058:	1101                	addi	sp,sp,-32
    8000305a:	ec06                	sd	ra,24(sp)
    8000305c:	e822                	sd	s0,16(sp)
    8000305e:	e426                	sd	s1,8(sp)
    80003060:	e04a                	sd	s2,0(sp)
    80003062:	1000                	addi	s0,sp,32
    80003064:	84ae                	mv	s1,a1
    80003066:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003068:	00000097          	auipc	ra,0x0
    8000306c:	eaa080e7          	jalr	-342(ra) # 80002f12 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003070:	864a                	mv	a2,s2
    80003072:	85a6                	mv	a1,s1
    80003074:	00000097          	auipc	ra,0x0
    80003078:	f58080e7          	jalr	-168(ra) # 80002fcc <fetchstr>
}
    8000307c:	60e2                	ld	ra,24(sp)
    8000307e:	6442                	ld	s0,16(sp)
    80003080:	64a2                	ld	s1,8(sp)
    80003082:	6902                	ld	s2,0(sp)
    80003084:	6105                	addi	sp,sp,32
    80003086:	8082                	ret

0000000080003088 <syscall>:
[SYS_kill_system]   sys_kill_system
};

void
syscall(void)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	e04a                	sd	s2,0(sp)
    80003092:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	a40080e7          	jalr	-1472(ra) # 80001ad4 <myproc>
    8000309c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000309e:	07053903          	ld	s2,112(a0)
    800030a2:	0a893783          	ld	a5,168(s2)
    800030a6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030aa:	37fd                	addiw	a5,a5,-1
    800030ac:	4759                	li	a4,22
    800030ae:	00f76f63          	bltu	a4,a5,800030cc <syscall+0x44>
    800030b2:	00369713          	slli	a4,a3,0x3
    800030b6:	00005797          	auipc	a5,0x5
    800030ba:	3da78793          	addi	a5,a5,986 # 80008490 <syscalls>
    800030be:	97ba                	add	a5,a5,a4
    800030c0:	639c                	ld	a5,0(a5)
    800030c2:	c789                	beqz	a5,800030cc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800030c4:	9782                	jalr	a5
    800030c6:	06a93823          	sd	a0,112(s2)
    800030ca:	a839                	j	800030e8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030cc:	17048613          	addi	a2,s1,368
    800030d0:	44ac                	lw	a1,72(s1)
    800030d2:	00005517          	auipc	a0,0x5
    800030d6:	38650513          	addi	a0,a0,902 # 80008458 <states.1766+0x150>
    800030da:	ffffd097          	auipc	ra,0xffffd
    800030de:	4ae080e7          	jalr	1198(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800030e2:	78bc                	ld	a5,112(s1)
    800030e4:	577d                	li	a4,-1
    800030e6:	fbb8                	sd	a4,112(a5)
  }
}
    800030e8:	60e2                	ld	ra,24(sp)
    800030ea:	6442                	ld	s0,16(sp)
    800030ec:	64a2                	ld	s1,8(sp)
    800030ee:	6902                	ld	s2,0(sp)
    800030f0:	6105                	addi	sp,sp,32
    800030f2:	8082                	ret

00000000800030f4 <sys_pause_system>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_pause_system(void)
{
    800030f4:	1101                	addi	sp,sp,-32
    800030f6:	ec06                	sd	ra,24(sp)
    800030f8:	e822                	sd	s0,16(sp)
    800030fa:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800030fc:	fec40593          	addi	a1,s0,-20
    80003100:	4501                	li	a0,0
    80003102:	00000097          	auipc	ra,0x0
    80003106:	f12080e7          	jalr	-238(ra) # 80003014 <argint>
    8000310a:	87aa                	mv	a5,a0
    return -1;
    8000310c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000310e:	0007c863          	bltz	a5,8000311e <sys_pause_system+0x2a>
  
  return pause_system(n);
    80003112:	fec42503          	lw	a0,-20(s0)
    80003116:	fffff097          	auipc	ra,0xfffff
    8000311a:	3f8080e7          	jalr	1016(ra) # 8000250e <pause_system>
}
    8000311e:	60e2                	ld	ra,24(sp)
    80003120:	6442                	ld	s0,16(sp)
    80003122:	6105                	addi	sp,sp,32
    80003124:	8082                	ret

0000000080003126 <sys_kill_system>:

uint64
sys_kill_system(void)
{
    80003126:	1141                	addi	sp,sp,-16
    80003128:	e406                	sd	ra,8(sp)
    8000312a:	e022                	sd	s0,0(sp)
    8000312c:	0800                	addi	s0,sp,16
  return kill_system();
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	850080e7          	jalr	-1968(ra) # 8000297e <kill_system>
}
    80003136:	60a2                	ld	ra,8(sp)
    80003138:	6402                	ld	s0,0(sp)
    8000313a:	0141                	addi	sp,sp,16
    8000313c:	8082                	ret

000000008000313e <sys_exit>:


uint64
sys_exit(void)
{
    8000313e:	1101                	addi	sp,sp,-32
    80003140:	ec06                	sd	ra,24(sp)
    80003142:	e822                	sd	s0,16(sp)
    80003144:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003146:	fec40593          	addi	a1,s0,-20
    8000314a:	4501                	li	a0,0
    8000314c:	00000097          	auipc	ra,0x0
    80003150:	ec8080e7          	jalr	-312(ra) # 80003014 <argint>
    return -1;
    80003154:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003156:	00054963          	bltz	a0,80003168 <sys_exit+0x2a>
  exit(n);
    8000315a:	fec42503          	lw	a0,-20(s0)
    8000315e:	fffff097          	auipc	ra,0xfffff
    80003162:	6be080e7          	jalr	1726(ra) # 8000281c <exit>
  return 0;  // not reached
    80003166:	4781                	li	a5,0
}
    80003168:	853e                	mv	a0,a5
    8000316a:	60e2                	ld	ra,24(sp)
    8000316c:	6442                	ld	s0,16(sp)
    8000316e:	6105                	addi	sp,sp,32
    80003170:	8082                	ret

0000000080003172 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003172:	1141                	addi	sp,sp,-16
    80003174:	e406                	sd	ra,8(sp)
    80003176:	e022                	sd	s0,0(sp)
    80003178:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000317a:	fffff097          	auipc	ra,0xfffff
    8000317e:	95a080e7          	jalr	-1702(ra) # 80001ad4 <myproc>
}
    80003182:	4528                	lw	a0,72(a0)
    80003184:	60a2                	ld	ra,8(sp)
    80003186:	6402                	ld	s0,0(sp)
    80003188:	0141                	addi	sp,sp,16
    8000318a:	8082                	ret

000000008000318c <sys_fork>:

uint64
sys_fork(void)
{
    8000318c:	1141                	addi	sp,sp,-16
    8000318e:	e406                	sd	ra,8(sp)
    80003190:	e022                	sd	s0,0(sp)
    80003192:	0800                	addi	s0,sp,16
  return fork();
    80003194:	fffff097          	auipc	ra,0xfffff
    80003198:	d24080e7          	jalr	-732(ra) # 80001eb8 <fork>
}
    8000319c:	60a2                	ld	ra,8(sp)
    8000319e:	6402                	ld	s0,0(sp)
    800031a0:	0141                	addi	sp,sp,16
    800031a2:	8082                	ret

00000000800031a4 <sys_wait>:

uint64
sys_wait(void)
{
    800031a4:	1101                	addi	sp,sp,-32
    800031a6:	ec06                	sd	ra,24(sp)
    800031a8:	e822                	sd	s0,16(sp)
    800031aa:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800031ac:	fe840593          	addi	a1,s0,-24
    800031b0:	4501                	li	a0,0
    800031b2:	00000097          	auipc	ra,0x0
    800031b6:	e84080e7          	jalr	-380(ra) # 80003036 <argaddr>
    800031ba:	87aa                	mv	a5,a0
    return -1;
    800031bc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800031be:	0007c863          	bltz	a5,800031ce <sys_wait+0x2a>
  return wait(p);
    800031c2:	fe843503          	ld	a0,-24(s0)
    800031c6:	fffff097          	auipc	ra,0xfffff
    800031ca:	44c080e7          	jalr	1100(ra) # 80002612 <wait>
}
    800031ce:	60e2                	ld	ra,24(sp)
    800031d0:	6442                	ld	s0,16(sp)
    800031d2:	6105                	addi	sp,sp,32
    800031d4:	8082                	ret

00000000800031d6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031d6:	7179                	addi	sp,sp,-48
    800031d8:	f406                	sd	ra,40(sp)
    800031da:	f022                	sd	s0,32(sp)
    800031dc:	ec26                	sd	s1,24(sp)
    800031de:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800031e0:	fdc40593          	addi	a1,s0,-36
    800031e4:	4501                	li	a0,0
    800031e6:	00000097          	auipc	ra,0x0
    800031ea:	e2e080e7          	jalr	-466(ra) # 80003014 <argint>
    800031ee:	87aa                	mv	a5,a0
    return -1;
    800031f0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800031f2:	0207c063          	bltz	a5,80003212 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800031f6:	fffff097          	auipc	ra,0xfffff
    800031fa:	8de080e7          	jalr	-1826(ra) # 80001ad4 <myproc>
    800031fe:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    80003200:	fdc42503          	lw	a0,-36(s0)
    80003204:	fffff097          	auipc	ra,0xfffff
    80003208:	c40080e7          	jalr	-960(ra) # 80001e44 <growproc>
    8000320c:	00054863          	bltz	a0,8000321c <sys_sbrk+0x46>
    return -1;
  return addr;
    80003210:	8526                	mv	a0,s1
}
    80003212:	70a2                	ld	ra,40(sp)
    80003214:	7402                	ld	s0,32(sp)
    80003216:	64e2                	ld	s1,24(sp)
    80003218:	6145                	addi	sp,sp,48
    8000321a:	8082                	ret
    return -1;
    8000321c:	557d                	li	a0,-1
    8000321e:	bfd5                	j	80003212 <sys_sbrk+0x3c>

0000000080003220 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003220:	7139                	addi	sp,sp,-64
    80003222:	fc06                	sd	ra,56(sp)
    80003224:	f822                	sd	s0,48(sp)
    80003226:	f426                	sd	s1,40(sp)
    80003228:	f04a                	sd	s2,32(sp)
    8000322a:	ec4e                	sd	s3,24(sp)
    8000322c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000322e:	fcc40593          	addi	a1,s0,-52
    80003232:	4501                	li	a0,0
    80003234:	00000097          	auipc	ra,0x0
    80003238:	de0080e7          	jalr	-544(ra) # 80003014 <argint>
    return -1;
    8000323c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000323e:	06054563          	bltz	a0,800032a8 <sys_sleep+0x88>
  acquire(&tickslock);
    80003242:	0000d517          	auipc	a0,0xd
    80003246:	00e50513          	addi	a0,a0,14 # 80010250 <tickslock>
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	99a080e7          	jalr	-1638(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003252:	00006917          	auipc	s2,0x6
    80003256:	df692903          	lw	s2,-522(s2) # 80009048 <ticks>
  while(ticks - ticks0 < n){
    8000325a:	fcc42783          	lw	a5,-52(s0)
    8000325e:	cf85                	beqz	a5,80003296 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003260:	0000d997          	auipc	s3,0xd
    80003264:	ff098993          	addi	s3,s3,-16 # 80010250 <tickslock>
    80003268:	00006497          	auipc	s1,0x6
    8000326c:	de048493          	addi	s1,s1,-544 # 80009048 <ticks>
    if(myproc()->killed){
    80003270:	fffff097          	auipc	ra,0xfffff
    80003274:	864080e7          	jalr	-1948(ra) # 80001ad4 <myproc>
    80003278:	413c                	lw	a5,64(a0)
    8000327a:	ef9d                	bnez	a5,800032b8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000327c:	85ce                	mv	a1,s3
    8000327e:	8526                	mv	a0,s1
    80003280:	fffff097          	auipc	ra,0xfffff
    80003284:	32e080e7          	jalr	814(ra) # 800025ae <sleep>
  while(ticks - ticks0 < n){
    80003288:	409c                	lw	a5,0(s1)
    8000328a:	412787bb          	subw	a5,a5,s2
    8000328e:	fcc42703          	lw	a4,-52(s0)
    80003292:	fce7efe3          	bltu	a5,a4,80003270 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003296:	0000d517          	auipc	a0,0xd
    8000329a:	fba50513          	addi	a0,a0,-70 # 80010250 <tickslock>
    8000329e:	ffffe097          	auipc	ra,0xffffe
    800032a2:	9fa080e7          	jalr	-1542(ra) # 80000c98 <release>
  return 0;
    800032a6:	4781                	li	a5,0
}
    800032a8:	853e                	mv	a0,a5
    800032aa:	70e2                	ld	ra,56(sp)
    800032ac:	7442                	ld	s0,48(sp)
    800032ae:	74a2                	ld	s1,40(sp)
    800032b0:	7902                	ld	s2,32(sp)
    800032b2:	69e2                	ld	s3,24(sp)
    800032b4:	6121                	addi	sp,sp,64
    800032b6:	8082                	ret
      release(&tickslock);
    800032b8:	0000d517          	auipc	a0,0xd
    800032bc:	f9850513          	addi	a0,a0,-104 # 80010250 <tickslock>
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	9d8080e7          	jalr	-1576(ra) # 80000c98 <release>
      return -1;
    800032c8:	57fd                	li	a5,-1
    800032ca:	bff9                	j	800032a8 <sys_sleep+0x88>

00000000800032cc <sys_kill>:

uint64
sys_kill(void)
{
    800032cc:	1101                	addi	sp,sp,-32
    800032ce:	ec06                	sd	ra,24(sp)
    800032d0:	e822                	sd	s0,16(sp)
    800032d2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800032d4:	fec40593          	addi	a1,s0,-20
    800032d8:	4501                	li	a0,0
    800032da:	00000097          	auipc	ra,0x0
    800032de:	d3a080e7          	jalr	-710(ra) # 80003014 <argint>
    800032e2:	87aa                	mv	a5,a0
    return -1;
    800032e4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800032e6:	0007c863          	bltz	a5,800032f6 <sys_kill+0x2a>
  return kill(pid);
    800032ea:	fec42503          	lw	a0,-20(s0)
    800032ee:	fffff097          	auipc	ra,0xfffff
    800032f2:	614080e7          	jalr	1556(ra) # 80002902 <kill>
}
    800032f6:	60e2                	ld	ra,24(sp)
    800032f8:	6442                	ld	s0,16(sp)
    800032fa:	6105                	addi	sp,sp,32
    800032fc:	8082                	ret

00000000800032fe <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032fe:	1101                	addi	sp,sp,-32
    80003300:	ec06                	sd	ra,24(sp)
    80003302:	e822                	sd	s0,16(sp)
    80003304:	e426                	sd	s1,8(sp)
    80003306:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003308:	0000d517          	auipc	a0,0xd
    8000330c:	f4850513          	addi	a0,a0,-184 # 80010250 <tickslock>
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	8d4080e7          	jalr	-1836(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003318:	00006497          	auipc	s1,0x6
    8000331c:	d304a483          	lw	s1,-720(s1) # 80009048 <ticks>
  release(&tickslock);
    80003320:	0000d517          	auipc	a0,0xd
    80003324:	f3050513          	addi	a0,a0,-208 # 80010250 <tickslock>
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	970080e7          	jalr	-1680(ra) # 80000c98 <release>
  return xticks;
}
    80003330:	02049513          	slli	a0,s1,0x20
    80003334:	9101                	srli	a0,a0,0x20
    80003336:	60e2                	ld	ra,24(sp)
    80003338:	6442                	ld	s0,16(sp)
    8000333a:	64a2                	ld	s1,8(sp)
    8000333c:	6105                	addi	sp,sp,32
    8000333e:	8082                	ret

0000000080003340 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003340:	7179                	addi	sp,sp,-48
    80003342:	f406                	sd	ra,40(sp)
    80003344:	f022                	sd	s0,32(sp)
    80003346:	ec26                	sd	s1,24(sp)
    80003348:	e84a                	sd	s2,16(sp)
    8000334a:	e44e                	sd	s3,8(sp)
    8000334c:	e052                	sd	s4,0(sp)
    8000334e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003350:	00005597          	auipc	a1,0x5
    80003354:	20058593          	addi	a1,a1,512 # 80008550 <syscalls+0xc0>
    80003358:	0000d517          	auipc	a0,0xd
    8000335c:	f1050513          	addi	a0,a0,-240 # 80010268 <bcache>
    80003360:	ffffd097          	auipc	ra,0xffffd
    80003364:	7f4080e7          	jalr	2036(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003368:	00015797          	auipc	a5,0x15
    8000336c:	f0078793          	addi	a5,a5,-256 # 80018268 <bcache+0x8000>
    80003370:	00015717          	auipc	a4,0x15
    80003374:	16070713          	addi	a4,a4,352 # 800184d0 <bcache+0x8268>
    80003378:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000337c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003380:	0000d497          	auipc	s1,0xd
    80003384:	f0048493          	addi	s1,s1,-256 # 80010280 <bcache+0x18>
    b->next = bcache.head.next;
    80003388:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000338a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000338c:	00005a17          	auipc	s4,0x5
    80003390:	1cca0a13          	addi	s4,s4,460 # 80008558 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003394:	2b893783          	ld	a5,696(s2)
    80003398:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000339a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000339e:	85d2                	mv	a1,s4
    800033a0:	01048513          	addi	a0,s1,16
    800033a4:	00001097          	auipc	ra,0x1
    800033a8:	4bc080e7          	jalr	1212(ra) # 80004860 <initsleeplock>
    bcache.head.next->prev = b;
    800033ac:	2b893783          	ld	a5,696(s2)
    800033b0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033b2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033b6:	45848493          	addi	s1,s1,1112
    800033ba:	fd349de3          	bne	s1,s3,80003394 <binit+0x54>
  }
}
    800033be:	70a2                	ld	ra,40(sp)
    800033c0:	7402                	ld	s0,32(sp)
    800033c2:	64e2                	ld	s1,24(sp)
    800033c4:	6942                	ld	s2,16(sp)
    800033c6:	69a2                	ld	s3,8(sp)
    800033c8:	6a02                	ld	s4,0(sp)
    800033ca:	6145                	addi	sp,sp,48
    800033cc:	8082                	ret

00000000800033ce <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033ce:	7179                	addi	sp,sp,-48
    800033d0:	f406                	sd	ra,40(sp)
    800033d2:	f022                	sd	s0,32(sp)
    800033d4:	ec26                	sd	s1,24(sp)
    800033d6:	e84a                	sd	s2,16(sp)
    800033d8:	e44e                	sd	s3,8(sp)
    800033da:	1800                	addi	s0,sp,48
    800033dc:	89aa                	mv	s3,a0
    800033de:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800033e0:	0000d517          	auipc	a0,0xd
    800033e4:	e8850513          	addi	a0,a0,-376 # 80010268 <bcache>
    800033e8:	ffffd097          	auipc	ra,0xffffd
    800033ec:	7fc080e7          	jalr	2044(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033f0:	00015497          	auipc	s1,0x15
    800033f4:	1304b483          	ld	s1,304(s1) # 80018520 <bcache+0x82b8>
    800033f8:	00015797          	auipc	a5,0x15
    800033fc:	0d878793          	addi	a5,a5,216 # 800184d0 <bcache+0x8268>
    80003400:	02f48f63          	beq	s1,a5,8000343e <bread+0x70>
    80003404:	873e                	mv	a4,a5
    80003406:	a021                	j	8000340e <bread+0x40>
    80003408:	68a4                	ld	s1,80(s1)
    8000340a:	02e48a63          	beq	s1,a4,8000343e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000340e:	449c                	lw	a5,8(s1)
    80003410:	ff379ce3          	bne	a5,s3,80003408 <bread+0x3a>
    80003414:	44dc                	lw	a5,12(s1)
    80003416:	ff2799e3          	bne	a5,s2,80003408 <bread+0x3a>
      b->refcnt++;
    8000341a:	40bc                	lw	a5,64(s1)
    8000341c:	2785                	addiw	a5,a5,1
    8000341e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003420:	0000d517          	auipc	a0,0xd
    80003424:	e4850513          	addi	a0,a0,-440 # 80010268 <bcache>
    80003428:	ffffe097          	auipc	ra,0xffffe
    8000342c:	870080e7          	jalr	-1936(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003430:	01048513          	addi	a0,s1,16
    80003434:	00001097          	auipc	ra,0x1
    80003438:	466080e7          	jalr	1126(ra) # 8000489a <acquiresleep>
      return b;
    8000343c:	a8b9                	j	8000349a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000343e:	00015497          	auipc	s1,0x15
    80003442:	0da4b483          	ld	s1,218(s1) # 80018518 <bcache+0x82b0>
    80003446:	00015797          	auipc	a5,0x15
    8000344a:	08a78793          	addi	a5,a5,138 # 800184d0 <bcache+0x8268>
    8000344e:	00f48863          	beq	s1,a5,8000345e <bread+0x90>
    80003452:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003454:	40bc                	lw	a5,64(s1)
    80003456:	cf81                	beqz	a5,8000346e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003458:	64a4                	ld	s1,72(s1)
    8000345a:	fee49de3          	bne	s1,a4,80003454 <bread+0x86>
  panic("bget: no buffers");
    8000345e:	00005517          	auipc	a0,0x5
    80003462:	10250513          	addi	a0,a0,258 # 80008560 <syscalls+0xd0>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	0d8080e7          	jalr	216(ra) # 8000053e <panic>
      b->dev = dev;
    8000346e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003472:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003476:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000347a:	4785                	li	a5,1
    8000347c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000347e:	0000d517          	auipc	a0,0xd
    80003482:	dea50513          	addi	a0,a0,-534 # 80010268 <bcache>
    80003486:	ffffe097          	auipc	ra,0xffffe
    8000348a:	812080e7          	jalr	-2030(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000348e:	01048513          	addi	a0,s1,16
    80003492:	00001097          	auipc	ra,0x1
    80003496:	408080e7          	jalr	1032(ra) # 8000489a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000349a:	409c                	lw	a5,0(s1)
    8000349c:	cb89                	beqz	a5,800034ae <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000349e:	8526                	mv	a0,s1
    800034a0:	70a2                	ld	ra,40(sp)
    800034a2:	7402                	ld	s0,32(sp)
    800034a4:	64e2                	ld	s1,24(sp)
    800034a6:	6942                	ld	s2,16(sp)
    800034a8:	69a2                	ld	s3,8(sp)
    800034aa:	6145                	addi	sp,sp,48
    800034ac:	8082                	ret
    virtio_disk_rw(b, 0);
    800034ae:	4581                	li	a1,0
    800034b0:	8526                	mv	a0,s1
    800034b2:	00003097          	auipc	ra,0x3
    800034b6:	f14080e7          	jalr	-236(ra) # 800063c6 <virtio_disk_rw>
    b->valid = 1;
    800034ba:	4785                	li	a5,1
    800034bc:	c09c                	sw	a5,0(s1)
  return b;
    800034be:	b7c5                	j	8000349e <bread+0xd0>

00000000800034c0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034c0:	1101                	addi	sp,sp,-32
    800034c2:	ec06                	sd	ra,24(sp)
    800034c4:	e822                	sd	s0,16(sp)
    800034c6:	e426                	sd	s1,8(sp)
    800034c8:	1000                	addi	s0,sp,32
    800034ca:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034cc:	0541                	addi	a0,a0,16
    800034ce:	00001097          	auipc	ra,0x1
    800034d2:	466080e7          	jalr	1126(ra) # 80004934 <holdingsleep>
    800034d6:	cd01                	beqz	a0,800034ee <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034d8:	4585                	li	a1,1
    800034da:	8526                	mv	a0,s1
    800034dc:	00003097          	auipc	ra,0x3
    800034e0:	eea080e7          	jalr	-278(ra) # 800063c6 <virtio_disk_rw>
}
    800034e4:	60e2                	ld	ra,24(sp)
    800034e6:	6442                	ld	s0,16(sp)
    800034e8:	64a2                	ld	s1,8(sp)
    800034ea:	6105                	addi	sp,sp,32
    800034ec:	8082                	ret
    panic("bwrite");
    800034ee:	00005517          	auipc	a0,0x5
    800034f2:	08a50513          	addi	a0,a0,138 # 80008578 <syscalls+0xe8>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	048080e7          	jalr	72(ra) # 8000053e <panic>

00000000800034fe <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034fe:	1101                	addi	sp,sp,-32
    80003500:	ec06                	sd	ra,24(sp)
    80003502:	e822                	sd	s0,16(sp)
    80003504:	e426                	sd	s1,8(sp)
    80003506:	e04a                	sd	s2,0(sp)
    80003508:	1000                	addi	s0,sp,32
    8000350a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000350c:	01050913          	addi	s2,a0,16
    80003510:	854a                	mv	a0,s2
    80003512:	00001097          	auipc	ra,0x1
    80003516:	422080e7          	jalr	1058(ra) # 80004934 <holdingsleep>
    8000351a:	c92d                	beqz	a0,8000358c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000351c:	854a                	mv	a0,s2
    8000351e:	00001097          	auipc	ra,0x1
    80003522:	3d2080e7          	jalr	978(ra) # 800048f0 <releasesleep>

  acquire(&bcache.lock);
    80003526:	0000d517          	auipc	a0,0xd
    8000352a:	d4250513          	addi	a0,a0,-702 # 80010268 <bcache>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	6b6080e7          	jalr	1718(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003536:	40bc                	lw	a5,64(s1)
    80003538:	37fd                	addiw	a5,a5,-1
    8000353a:	0007871b          	sext.w	a4,a5
    8000353e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003540:	eb05                	bnez	a4,80003570 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003542:	68bc                	ld	a5,80(s1)
    80003544:	64b8                	ld	a4,72(s1)
    80003546:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003548:	64bc                	ld	a5,72(s1)
    8000354a:	68b8                	ld	a4,80(s1)
    8000354c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000354e:	00015797          	auipc	a5,0x15
    80003552:	d1a78793          	addi	a5,a5,-742 # 80018268 <bcache+0x8000>
    80003556:	2b87b703          	ld	a4,696(a5)
    8000355a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000355c:	00015717          	auipc	a4,0x15
    80003560:	f7470713          	addi	a4,a4,-140 # 800184d0 <bcache+0x8268>
    80003564:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003566:	2b87b703          	ld	a4,696(a5)
    8000356a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000356c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003570:	0000d517          	auipc	a0,0xd
    80003574:	cf850513          	addi	a0,a0,-776 # 80010268 <bcache>
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	720080e7          	jalr	1824(ra) # 80000c98 <release>
}
    80003580:	60e2                	ld	ra,24(sp)
    80003582:	6442                	ld	s0,16(sp)
    80003584:	64a2                	ld	s1,8(sp)
    80003586:	6902                	ld	s2,0(sp)
    80003588:	6105                	addi	sp,sp,32
    8000358a:	8082                	ret
    panic("brelse");
    8000358c:	00005517          	auipc	a0,0x5
    80003590:	ff450513          	addi	a0,a0,-12 # 80008580 <syscalls+0xf0>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	faa080e7          	jalr	-86(ra) # 8000053e <panic>

000000008000359c <bpin>:

void
bpin(struct buf *b) {
    8000359c:	1101                	addi	sp,sp,-32
    8000359e:	ec06                	sd	ra,24(sp)
    800035a0:	e822                	sd	s0,16(sp)
    800035a2:	e426                	sd	s1,8(sp)
    800035a4:	1000                	addi	s0,sp,32
    800035a6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035a8:	0000d517          	auipc	a0,0xd
    800035ac:	cc050513          	addi	a0,a0,-832 # 80010268 <bcache>
    800035b0:	ffffd097          	auipc	ra,0xffffd
    800035b4:	634080e7          	jalr	1588(ra) # 80000be4 <acquire>
  b->refcnt++;
    800035b8:	40bc                	lw	a5,64(s1)
    800035ba:	2785                	addiw	a5,a5,1
    800035bc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035be:	0000d517          	auipc	a0,0xd
    800035c2:	caa50513          	addi	a0,a0,-854 # 80010268 <bcache>
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	6d2080e7          	jalr	1746(ra) # 80000c98 <release>
}
    800035ce:	60e2                	ld	ra,24(sp)
    800035d0:	6442                	ld	s0,16(sp)
    800035d2:	64a2                	ld	s1,8(sp)
    800035d4:	6105                	addi	sp,sp,32
    800035d6:	8082                	ret

00000000800035d8 <bunpin>:

void
bunpin(struct buf *b) {
    800035d8:	1101                	addi	sp,sp,-32
    800035da:	ec06                	sd	ra,24(sp)
    800035dc:	e822                	sd	s0,16(sp)
    800035de:	e426                	sd	s1,8(sp)
    800035e0:	1000                	addi	s0,sp,32
    800035e2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035e4:	0000d517          	auipc	a0,0xd
    800035e8:	c8450513          	addi	a0,a0,-892 # 80010268 <bcache>
    800035ec:	ffffd097          	auipc	ra,0xffffd
    800035f0:	5f8080e7          	jalr	1528(ra) # 80000be4 <acquire>
  b->refcnt--;
    800035f4:	40bc                	lw	a5,64(s1)
    800035f6:	37fd                	addiw	a5,a5,-1
    800035f8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035fa:	0000d517          	auipc	a0,0xd
    800035fe:	c6e50513          	addi	a0,a0,-914 # 80010268 <bcache>
    80003602:	ffffd097          	auipc	ra,0xffffd
    80003606:	696080e7          	jalr	1686(ra) # 80000c98 <release>
}
    8000360a:	60e2                	ld	ra,24(sp)
    8000360c:	6442                	ld	s0,16(sp)
    8000360e:	64a2                	ld	s1,8(sp)
    80003610:	6105                	addi	sp,sp,32
    80003612:	8082                	ret

0000000080003614 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003614:	1101                	addi	sp,sp,-32
    80003616:	ec06                	sd	ra,24(sp)
    80003618:	e822                	sd	s0,16(sp)
    8000361a:	e426                	sd	s1,8(sp)
    8000361c:	e04a                	sd	s2,0(sp)
    8000361e:	1000                	addi	s0,sp,32
    80003620:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003622:	00d5d59b          	srliw	a1,a1,0xd
    80003626:	00015797          	auipc	a5,0x15
    8000362a:	31e7a783          	lw	a5,798(a5) # 80018944 <sb+0x1c>
    8000362e:	9dbd                	addw	a1,a1,a5
    80003630:	00000097          	auipc	ra,0x0
    80003634:	d9e080e7          	jalr	-610(ra) # 800033ce <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003638:	0074f713          	andi	a4,s1,7
    8000363c:	4785                	li	a5,1
    8000363e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003642:	14ce                	slli	s1,s1,0x33
    80003644:	90d9                	srli	s1,s1,0x36
    80003646:	00950733          	add	a4,a0,s1
    8000364a:	05874703          	lbu	a4,88(a4)
    8000364e:	00e7f6b3          	and	a3,a5,a4
    80003652:	c69d                	beqz	a3,80003680 <bfree+0x6c>
    80003654:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003656:	94aa                	add	s1,s1,a0
    80003658:	fff7c793          	not	a5,a5
    8000365c:	8ff9                	and	a5,a5,a4
    8000365e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003662:	00001097          	auipc	ra,0x1
    80003666:	118080e7          	jalr	280(ra) # 8000477a <log_write>
  brelse(bp);
    8000366a:	854a                	mv	a0,s2
    8000366c:	00000097          	auipc	ra,0x0
    80003670:	e92080e7          	jalr	-366(ra) # 800034fe <brelse>
}
    80003674:	60e2                	ld	ra,24(sp)
    80003676:	6442                	ld	s0,16(sp)
    80003678:	64a2                	ld	s1,8(sp)
    8000367a:	6902                	ld	s2,0(sp)
    8000367c:	6105                	addi	sp,sp,32
    8000367e:	8082                	ret
    panic("freeing free block");
    80003680:	00005517          	auipc	a0,0x5
    80003684:	f0850513          	addi	a0,a0,-248 # 80008588 <syscalls+0xf8>
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	eb6080e7          	jalr	-330(ra) # 8000053e <panic>

0000000080003690 <balloc>:
{
    80003690:	711d                	addi	sp,sp,-96
    80003692:	ec86                	sd	ra,88(sp)
    80003694:	e8a2                	sd	s0,80(sp)
    80003696:	e4a6                	sd	s1,72(sp)
    80003698:	e0ca                	sd	s2,64(sp)
    8000369a:	fc4e                	sd	s3,56(sp)
    8000369c:	f852                	sd	s4,48(sp)
    8000369e:	f456                	sd	s5,40(sp)
    800036a0:	f05a                	sd	s6,32(sp)
    800036a2:	ec5e                	sd	s7,24(sp)
    800036a4:	e862                	sd	s8,16(sp)
    800036a6:	e466                	sd	s9,8(sp)
    800036a8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036aa:	00015797          	auipc	a5,0x15
    800036ae:	2827a783          	lw	a5,642(a5) # 8001892c <sb+0x4>
    800036b2:	cbd1                	beqz	a5,80003746 <balloc+0xb6>
    800036b4:	8baa                	mv	s7,a0
    800036b6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036b8:	00015b17          	auipc	s6,0x15
    800036bc:	270b0b13          	addi	s6,s6,624 # 80018928 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036c0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036c2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036c4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036c6:	6c89                	lui	s9,0x2
    800036c8:	a831                	j	800036e4 <balloc+0x54>
    brelse(bp);
    800036ca:	854a                	mv	a0,s2
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	e32080e7          	jalr	-462(ra) # 800034fe <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036d4:	015c87bb          	addw	a5,s9,s5
    800036d8:	00078a9b          	sext.w	s5,a5
    800036dc:	004b2703          	lw	a4,4(s6)
    800036e0:	06eaf363          	bgeu	s5,a4,80003746 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036e4:	41fad79b          	sraiw	a5,s5,0x1f
    800036e8:	0137d79b          	srliw	a5,a5,0x13
    800036ec:	015787bb          	addw	a5,a5,s5
    800036f0:	40d7d79b          	sraiw	a5,a5,0xd
    800036f4:	01cb2583          	lw	a1,28(s6)
    800036f8:	9dbd                	addw	a1,a1,a5
    800036fa:	855e                	mv	a0,s7
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	cd2080e7          	jalr	-814(ra) # 800033ce <bread>
    80003704:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003706:	004b2503          	lw	a0,4(s6)
    8000370a:	000a849b          	sext.w	s1,s5
    8000370e:	8662                	mv	a2,s8
    80003710:	faa4fde3          	bgeu	s1,a0,800036ca <balloc+0x3a>
      m = 1 << (bi % 8);
    80003714:	41f6579b          	sraiw	a5,a2,0x1f
    80003718:	01d7d69b          	srliw	a3,a5,0x1d
    8000371c:	00c6873b          	addw	a4,a3,a2
    80003720:	00777793          	andi	a5,a4,7
    80003724:	9f95                	subw	a5,a5,a3
    80003726:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000372a:	4037571b          	sraiw	a4,a4,0x3
    8000372e:	00e906b3          	add	a3,s2,a4
    80003732:	0586c683          	lbu	a3,88(a3)
    80003736:	00d7f5b3          	and	a1,a5,a3
    8000373a:	cd91                	beqz	a1,80003756 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000373c:	2605                	addiw	a2,a2,1
    8000373e:	2485                	addiw	s1,s1,1
    80003740:	fd4618e3          	bne	a2,s4,80003710 <balloc+0x80>
    80003744:	b759                	j	800036ca <balloc+0x3a>
  panic("balloc: out of blocks");
    80003746:	00005517          	auipc	a0,0x5
    8000374a:	e5a50513          	addi	a0,a0,-422 # 800085a0 <syscalls+0x110>
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	df0080e7          	jalr	-528(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003756:	974a                	add	a4,a4,s2
    80003758:	8fd5                	or	a5,a5,a3
    8000375a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000375e:	854a                	mv	a0,s2
    80003760:	00001097          	auipc	ra,0x1
    80003764:	01a080e7          	jalr	26(ra) # 8000477a <log_write>
        brelse(bp);
    80003768:	854a                	mv	a0,s2
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	d94080e7          	jalr	-620(ra) # 800034fe <brelse>
  bp = bread(dev, bno);
    80003772:	85a6                	mv	a1,s1
    80003774:	855e                	mv	a0,s7
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	c58080e7          	jalr	-936(ra) # 800033ce <bread>
    8000377e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003780:	40000613          	li	a2,1024
    80003784:	4581                	li	a1,0
    80003786:	05850513          	addi	a0,a0,88
    8000378a:	ffffd097          	auipc	ra,0xffffd
    8000378e:	556080e7          	jalr	1366(ra) # 80000ce0 <memset>
  log_write(bp);
    80003792:	854a                	mv	a0,s2
    80003794:	00001097          	auipc	ra,0x1
    80003798:	fe6080e7          	jalr	-26(ra) # 8000477a <log_write>
  brelse(bp);
    8000379c:	854a                	mv	a0,s2
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	d60080e7          	jalr	-672(ra) # 800034fe <brelse>
}
    800037a6:	8526                	mv	a0,s1
    800037a8:	60e6                	ld	ra,88(sp)
    800037aa:	6446                	ld	s0,80(sp)
    800037ac:	64a6                	ld	s1,72(sp)
    800037ae:	6906                	ld	s2,64(sp)
    800037b0:	79e2                	ld	s3,56(sp)
    800037b2:	7a42                	ld	s4,48(sp)
    800037b4:	7aa2                	ld	s5,40(sp)
    800037b6:	7b02                	ld	s6,32(sp)
    800037b8:	6be2                	ld	s7,24(sp)
    800037ba:	6c42                	ld	s8,16(sp)
    800037bc:	6ca2                	ld	s9,8(sp)
    800037be:	6125                	addi	sp,sp,96
    800037c0:	8082                	ret

00000000800037c2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800037c2:	7179                	addi	sp,sp,-48
    800037c4:	f406                	sd	ra,40(sp)
    800037c6:	f022                	sd	s0,32(sp)
    800037c8:	ec26                	sd	s1,24(sp)
    800037ca:	e84a                	sd	s2,16(sp)
    800037cc:	e44e                	sd	s3,8(sp)
    800037ce:	e052                	sd	s4,0(sp)
    800037d0:	1800                	addi	s0,sp,48
    800037d2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037d4:	47ad                	li	a5,11
    800037d6:	04b7fe63          	bgeu	a5,a1,80003832 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800037da:	ff45849b          	addiw	s1,a1,-12
    800037de:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037e2:	0ff00793          	li	a5,255
    800037e6:	0ae7e363          	bltu	a5,a4,8000388c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037ea:	08052583          	lw	a1,128(a0)
    800037ee:	c5ad                	beqz	a1,80003858 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037f0:	00092503          	lw	a0,0(s2)
    800037f4:	00000097          	auipc	ra,0x0
    800037f8:	bda080e7          	jalr	-1062(ra) # 800033ce <bread>
    800037fc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037fe:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003802:	02049593          	slli	a1,s1,0x20
    80003806:	9181                	srli	a1,a1,0x20
    80003808:	058a                	slli	a1,a1,0x2
    8000380a:	00b784b3          	add	s1,a5,a1
    8000380e:	0004a983          	lw	s3,0(s1)
    80003812:	04098d63          	beqz	s3,8000386c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003816:	8552                	mv	a0,s4
    80003818:	00000097          	auipc	ra,0x0
    8000381c:	ce6080e7          	jalr	-794(ra) # 800034fe <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003820:	854e                	mv	a0,s3
    80003822:	70a2                	ld	ra,40(sp)
    80003824:	7402                	ld	s0,32(sp)
    80003826:	64e2                	ld	s1,24(sp)
    80003828:	6942                	ld	s2,16(sp)
    8000382a:	69a2                	ld	s3,8(sp)
    8000382c:	6a02                	ld	s4,0(sp)
    8000382e:	6145                	addi	sp,sp,48
    80003830:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003832:	02059493          	slli	s1,a1,0x20
    80003836:	9081                	srli	s1,s1,0x20
    80003838:	048a                	slli	s1,s1,0x2
    8000383a:	94aa                	add	s1,s1,a0
    8000383c:	0504a983          	lw	s3,80(s1)
    80003840:	fe0990e3          	bnez	s3,80003820 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003844:	4108                	lw	a0,0(a0)
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	e4a080e7          	jalr	-438(ra) # 80003690 <balloc>
    8000384e:	0005099b          	sext.w	s3,a0
    80003852:	0534a823          	sw	s3,80(s1)
    80003856:	b7e9                	j	80003820 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003858:	4108                	lw	a0,0(a0)
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	e36080e7          	jalr	-458(ra) # 80003690 <balloc>
    80003862:	0005059b          	sext.w	a1,a0
    80003866:	08b92023          	sw	a1,128(s2)
    8000386a:	b759                	j	800037f0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000386c:	00092503          	lw	a0,0(s2)
    80003870:	00000097          	auipc	ra,0x0
    80003874:	e20080e7          	jalr	-480(ra) # 80003690 <balloc>
    80003878:	0005099b          	sext.w	s3,a0
    8000387c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003880:	8552                	mv	a0,s4
    80003882:	00001097          	auipc	ra,0x1
    80003886:	ef8080e7          	jalr	-264(ra) # 8000477a <log_write>
    8000388a:	b771                	j	80003816 <bmap+0x54>
  panic("bmap: out of range");
    8000388c:	00005517          	auipc	a0,0x5
    80003890:	d2c50513          	addi	a0,a0,-724 # 800085b8 <syscalls+0x128>
    80003894:	ffffd097          	auipc	ra,0xffffd
    80003898:	caa080e7          	jalr	-854(ra) # 8000053e <panic>

000000008000389c <iget>:
{
    8000389c:	7179                	addi	sp,sp,-48
    8000389e:	f406                	sd	ra,40(sp)
    800038a0:	f022                	sd	s0,32(sp)
    800038a2:	ec26                	sd	s1,24(sp)
    800038a4:	e84a                	sd	s2,16(sp)
    800038a6:	e44e                	sd	s3,8(sp)
    800038a8:	e052                	sd	s4,0(sp)
    800038aa:	1800                	addi	s0,sp,48
    800038ac:	89aa                	mv	s3,a0
    800038ae:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038b0:	00015517          	auipc	a0,0x15
    800038b4:	09850513          	addi	a0,a0,152 # 80018948 <itable>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	32c080e7          	jalr	812(ra) # 80000be4 <acquire>
  empty = 0;
    800038c0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038c2:	00015497          	auipc	s1,0x15
    800038c6:	09e48493          	addi	s1,s1,158 # 80018960 <itable+0x18>
    800038ca:	00017697          	auipc	a3,0x17
    800038ce:	b2668693          	addi	a3,a3,-1242 # 8001a3f0 <log>
    800038d2:	a039                	j	800038e0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038d4:	02090b63          	beqz	s2,8000390a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038d8:	08848493          	addi	s1,s1,136
    800038dc:	02d48a63          	beq	s1,a3,80003910 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038e0:	449c                	lw	a5,8(s1)
    800038e2:	fef059e3          	blez	a5,800038d4 <iget+0x38>
    800038e6:	4098                	lw	a4,0(s1)
    800038e8:	ff3716e3          	bne	a4,s3,800038d4 <iget+0x38>
    800038ec:	40d8                	lw	a4,4(s1)
    800038ee:	ff4713e3          	bne	a4,s4,800038d4 <iget+0x38>
      ip->ref++;
    800038f2:	2785                	addiw	a5,a5,1
    800038f4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038f6:	00015517          	auipc	a0,0x15
    800038fa:	05250513          	addi	a0,a0,82 # 80018948 <itable>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	39a080e7          	jalr	922(ra) # 80000c98 <release>
      return ip;
    80003906:	8926                	mv	s2,s1
    80003908:	a03d                	j	80003936 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000390a:	f7f9                	bnez	a5,800038d8 <iget+0x3c>
    8000390c:	8926                	mv	s2,s1
    8000390e:	b7e9                	j	800038d8 <iget+0x3c>
  if(empty == 0)
    80003910:	02090c63          	beqz	s2,80003948 <iget+0xac>
  ip->dev = dev;
    80003914:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003918:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000391c:	4785                	li	a5,1
    8000391e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003922:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003926:	00015517          	auipc	a0,0x15
    8000392a:	02250513          	addi	a0,a0,34 # 80018948 <itable>
    8000392e:	ffffd097          	auipc	ra,0xffffd
    80003932:	36a080e7          	jalr	874(ra) # 80000c98 <release>
}
    80003936:	854a                	mv	a0,s2
    80003938:	70a2                	ld	ra,40(sp)
    8000393a:	7402                	ld	s0,32(sp)
    8000393c:	64e2                	ld	s1,24(sp)
    8000393e:	6942                	ld	s2,16(sp)
    80003940:	69a2                	ld	s3,8(sp)
    80003942:	6a02                	ld	s4,0(sp)
    80003944:	6145                	addi	sp,sp,48
    80003946:	8082                	ret
    panic("iget: no inodes");
    80003948:	00005517          	auipc	a0,0x5
    8000394c:	c8850513          	addi	a0,a0,-888 # 800085d0 <syscalls+0x140>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	bee080e7          	jalr	-1042(ra) # 8000053e <panic>

0000000080003958 <fsinit>:
fsinit(int dev) {
    80003958:	7179                	addi	sp,sp,-48
    8000395a:	f406                	sd	ra,40(sp)
    8000395c:	f022                	sd	s0,32(sp)
    8000395e:	ec26                	sd	s1,24(sp)
    80003960:	e84a                	sd	s2,16(sp)
    80003962:	e44e                	sd	s3,8(sp)
    80003964:	1800                	addi	s0,sp,48
    80003966:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003968:	4585                	li	a1,1
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	a64080e7          	jalr	-1436(ra) # 800033ce <bread>
    80003972:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003974:	00015997          	auipc	s3,0x15
    80003978:	fb498993          	addi	s3,s3,-76 # 80018928 <sb>
    8000397c:	02000613          	li	a2,32
    80003980:	05850593          	addi	a1,a0,88
    80003984:	854e                	mv	a0,s3
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	3ba080e7          	jalr	954(ra) # 80000d40 <memmove>
  brelse(bp);
    8000398e:	8526                	mv	a0,s1
    80003990:	00000097          	auipc	ra,0x0
    80003994:	b6e080e7          	jalr	-1170(ra) # 800034fe <brelse>
  if(sb.magic != FSMAGIC)
    80003998:	0009a703          	lw	a4,0(s3)
    8000399c:	102037b7          	lui	a5,0x10203
    800039a0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039a4:	02f71263          	bne	a4,a5,800039c8 <fsinit+0x70>
  initlog(dev, &sb);
    800039a8:	00015597          	auipc	a1,0x15
    800039ac:	f8058593          	addi	a1,a1,-128 # 80018928 <sb>
    800039b0:	854a                	mv	a0,s2
    800039b2:	00001097          	auipc	ra,0x1
    800039b6:	b4c080e7          	jalr	-1204(ra) # 800044fe <initlog>
}
    800039ba:	70a2                	ld	ra,40(sp)
    800039bc:	7402                	ld	s0,32(sp)
    800039be:	64e2                	ld	s1,24(sp)
    800039c0:	6942                	ld	s2,16(sp)
    800039c2:	69a2                	ld	s3,8(sp)
    800039c4:	6145                	addi	sp,sp,48
    800039c6:	8082                	ret
    panic("invalid file system");
    800039c8:	00005517          	auipc	a0,0x5
    800039cc:	c1850513          	addi	a0,a0,-1000 # 800085e0 <syscalls+0x150>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	b6e080e7          	jalr	-1170(ra) # 8000053e <panic>

00000000800039d8 <iinit>:
{
    800039d8:	7179                	addi	sp,sp,-48
    800039da:	f406                	sd	ra,40(sp)
    800039dc:	f022                	sd	s0,32(sp)
    800039de:	ec26                	sd	s1,24(sp)
    800039e0:	e84a                	sd	s2,16(sp)
    800039e2:	e44e                	sd	s3,8(sp)
    800039e4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039e6:	00005597          	auipc	a1,0x5
    800039ea:	c1258593          	addi	a1,a1,-1006 # 800085f8 <syscalls+0x168>
    800039ee:	00015517          	auipc	a0,0x15
    800039f2:	f5a50513          	addi	a0,a0,-166 # 80018948 <itable>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	15e080e7          	jalr	350(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039fe:	00015497          	auipc	s1,0x15
    80003a02:	f7248493          	addi	s1,s1,-142 # 80018970 <itable+0x28>
    80003a06:	00017997          	auipc	s3,0x17
    80003a0a:	9fa98993          	addi	s3,s3,-1542 # 8001a400 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a0e:	00005917          	auipc	s2,0x5
    80003a12:	bf290913          	addi	s2,s2,-1038 # 80008600 <syscalls+0x170>
    80003a16:	85ca                	mv	a1,s2
    80003a18:	8526                	mv	a0,s1
    80003a1a:	00001097          	auipc	ra,0x1
    80003a1e:	e46080e7          	jalr	-442(ra) # 80004860 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a22:	08848493          	addi	s1,s1,136
    80003a26:	ff3498e3          	bne	s1,s3,80003a16 <iinit+0x3e>
}
    80003a2a:	70a2                	ld	ra,40(sp)
    80003a2c:	7402                	ld	s0,32(sp)
    80003a2e:	64e2                	ld	s1,24(sp)
    80003a30:	6942                	ld	s2,16(sp)
    80003a32:	69a2                	ld	s3,8(sp)
    80003a34:	6145                	addi	sp,sp,48
    80003a36:	8082                	ret

0000000080003a38 <ialloc>:
{
    80003a38:	715d                	addi	sp,sp,-80
    80003a3a:	e486                	sd	ra,72(sp)
    80003a3c:	e0a2                	sd	s0,64(sp)
    80003a3e:	fc26                	sd	s1,56(sp)
    80003a40:	f84a                	sd	s2,48(sp)
    80003a42:	f44e                	sd	s3,40(sp)
    80003a44:	f052                	sd	s4,32(sp)
    80003a46:	ec56                	sd	s5,24(sp)
    80003a48:	e85a                	sd	s6,16(sp)
    80003a4a:	e45e                	sd	s7,8(sp)
    80003a4c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a4e:	00015717          	auipc	a4,0x15
    80003a52:	ee672703          	lw	a4,-282(a4) # 80018934 <sb+0xc>
    80003a56:	4785                	li	a5,1
    80003a58:	04e7fa63          	bgeu	a5,a4,80003aac <ialloc+0x74>
    80003a5c:	8aaa                	mv	s5,a0
    80003a5e:	8bae                	mv	s7,a1
    80003a60:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a62:	00015a17          	auipc	s4,0x15
    80003a66:	ec6a0a13          	addi	s4,s4,-314 # 80018928 <sb>
    80003a6a:	00048b1b          	sext.w	s6,s1
    80003a6e:	0044d593          	srli	a1,s1,0x4
    80003a72:	018a2783          	lw	a5,24(s4)
    80003a76:	9dbd                	addw	a1,a1,a5
    80003a78:	8556                	mv	a0,s5
    80003a7a:	00000097          	auipc	ra,0x0
    80003a7e:	954080e7          	jalr	-1708(ra) # 800033ce <bread>
    80003a82:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a84:	05850993          	addi	s3,a0,88
    80003a88:	00f4f793          	andi	a5,s1,15
    80003a8c:	079a                	slli	a5,a5,0x6
    80003a8e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a90:	00099783          	lh	a5,0(s3)
    80003a94:	c785                	beqz	a5,80003abc <ialloc+0x84>
    brelse(bp);
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	a68080e7          	jalr	-1432(ra) # 800034fe <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a9e:	0485                	addi	s1,s1,1
    80003aa0:	00ca2703          	lw	a4,12(s4)
    80003aa4:	0004879b          	sext.w	a5,s1
    80003aa8:	fce7e1e3          	bltu	a5,a4,80003a6a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003aac:	00005517          	auipc	a0,0x5
    80003ab0:	b5c50513          	addi	a0,a0,-1188 # 80008608 <syscalls+0x178>
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	a8a080e7          	jalr	-1398(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003abc:	04000613          	li	a2,64
    80003ac0:	4581                	li	a1,0
    80003ac2:	854e                	mv	a0,s3
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	21c080e7          	jalr	540(ra) # 80000ce0 <memset>
      dip->type = type;
    80003acc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ad0:	854a                	mv	a0,s2
    80003ad2:	00001097          	auipc	ra,0x1
    80003ad6:	ca8080e7          	jalr	-856(ra) # 8000477a <log_write>
      brelse(bp);
    80003ada:	854a                	mv	a0,s2
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	a22080e7          	jalr	-1502(ra) # 800034fe <brelse>
      return iget(dev, inum);
    80003ae4:	85da                	mv	a1,s6
    80003ae6:	8556                	mv	a0,s5
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	db4080e7          	jalr	-588(ra) # 8000389c <iget>
}
    80003af0:	60a6                	ld	ra,72(sp)
    80003af2:	6406                	ld	s0,64(sp)
    80003af4:	74e2                	ld	s1,56(sp)
    80003af6:	7942                	ld	s2,48(sp)
    80003af8:	79a2                	ld	s3,40(sp)
    80003afa:	7a02                	ld	s4,32(sp)
    80003afc:	6ae2                	ld	s5,24(sp)
    80003afe:	6b42                	ld	s6,16(sp)
    80003b00:	6ba2                	ld	s7,8(sp)
    80003b02:	6161                	addi	sp,sp,80
    80003b04:	8082                	ret

0000000080003b06 <iupdate>:
{
    80003b06:	1101                	addi	sp,sp,-32
    80003b08:	ec06                	sd	ra,24(sp)
    80003b0a:	e822                	sd	s0,16(sp)
    80003b0c:	e426                	sd	s1,8(sp)
    80003b0e:	e04a                	sd	s2,0(sp)
    80003b10:	1000                	addi	s0,sp,32
    80003b12:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b14:	415c                	lw	a5,4(a0)
    80003b16:	0047d79b          	srliw	a5,a5,0x4
    80003b1a:	00015597          	auipc	a1,0x15
    80003b1e:	e265a583          	lw	a1,-474(a1) # 80018940 <sb+0x18>
    80003b22:	9dbd                	addw	a1,a1,a5
    80003b24:	4108                	lw	a0,0(a0)
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	8a8080e7          	jalr	-1880(ra) # 800033ce <bread>
    80003b2e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b30:	05850793          	addi	a5,a0,88
    80003b34:	40c8                	lw	a0,4(s1)
    80003b36:	893d                	andi	a0,a0,15
    80003b38:	051a                	slli	a0,a0,0x6
    80003b3a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b3c:	04449703          	lh	a4,68(s1)
    80003b40:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b44:	04649703          	lh	a4,70(s1)
    80003b48:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b4c:	04849703          	lh	a4,72(s1)
    80003b50:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b54:	04a49703          	lh	a4,74(s1)
    80003b58:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b5c:	44f8                	lw	a4,76(s1)
    80003b5e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b60:	03400613          	li	a2,52
    80003b64:	05048593          	addi	a1,s1,80
    80003b68:	0531                	addi	a0,a0,12
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	1d6080e7          	jalr	470(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b72:	854a                	mv	a0,s2
    80003b74:	00001097          	auipc	ra,0x1
    80003b78:	c06080e7          	jalr	-1018(ra) # 8000477a <log_write>
  brelse(bp);
    80003b7c:	854a                	mv	a0,s2
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	980080e7          	jalr	-1664(ra) # 800034fe <brelse>
}
    80003b86:	60e2                	ld	ra,24(sp)
    80003b88:	6442                	ld	s0,16(sp)
    80003b8a:	64a2                	ld	s1,8(sp)
    80003b8c:	6902                	ld	s2,0(sp)
    80003b8e:	6105                	addi	sp,sp,32
    80003b90:	8082                	ret

0000000080003b92 <idup>:
{
    80003b92:	1101                	addi	sp,sp,-32
    80003b94:	ec06                	sd	ra,24(sp)
    80003b96:	e822                	sd	s0,16(sp)
    80003b98:	e426                	sd	s1,8(sp)
    80003b9a:	1000                	addi	s0,sp,32
    80003b9c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b9e:	00015517          	auipc	a0,0x15
    80003ba2:	daa50513          	addi	a0,a0,-598 # 80018948 <itable>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	03e080e7          	jalr	62(ra) # 80000be4 <acquire>
  ip->ref++;
    80003bae:	449c                	lw	a5,8(s1)
    80003bb0:	2785                	addiw	a5,a5,1
    80003bb2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bb4:	00015517          	auipc	a0,0x15
    80003bb8:	d9450513          	addi	a0,a0,-620 # 80018948 <itable>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	0dc080e7          	jalr	220(ra) # 80000c98 <release>
}
    80003bc4:	8526                	mv	a0,s1
    80003bc6:	60e2                	ld	ra,24(sp)
    80003bc8:	6442                	ld	s0,16(sp)
    80003bca:	64a2                	ld	s1,8(sp)
    80003bcc:	6105                	addi	sp,sp,32
    80003bce:	8082                	ret

0000000080003bd0 <ilock>:
{
    80003bd0:	1101                	addi	sp,sp,-32
    80003bd2:	ec06                	sd	ra,24(sp)
    80003bd4:	e822                	sd	s0,16(sp)
    80003bd6:	e426                	sd	s1,8(sp)
    80003bd8:	e04a                	sd	s2,0(sp)
    80003bda:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bdc:	c115                	beqz	a0,80003c00 <ilock+0x30>
    80003bde:	84aa                	mv	s1,a0
    80003be0:	451c                	lw	a5,8(a0)
    80003be2:	00f05f63          	blez	a5,80003c00 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003be6:	0541                	addi	a0,a0,16
    80003be8:	00001097          	auipc	ra,0x1
    80003bec:	cb2080e7          	jalr	-846(ra) # 8000489a <acquiresleep>
  if(ip->valid == 0){
    80003bf0:	40bc                	lw	a5,64(s1)
    80003bf2:	cf99                	beqz	a5,80003c10 <ilock+0x40>
}
    80003bf4:	60e2                	ld	ra,24(sp)
    80003bf6:	6442                	ld	s0,16(sp)
    80003bf8:	64a2                	ld	s1,8(sp)
    80003bfa:	6902                	ld	s2,0(sp)
    80003bfc:	6105                	addi	sp,sp,32
    80003bfe:	8082                	ret
    panic("ilock");
    80003c00:	00005517          	auipc	a0,0x5
    80003c04:	a2050513          	addi	a0,a0,-1504 # 80008620 <syscalls+0x190>
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	936080e7          	jalr	-1738(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c10:	40dc                	lw	a5,4(s1)
    80003c12:	0047d79b          	srliw	a5,a5,0x4
    80003c16:	00015597          	auipc	a1,0x15
    80003c1a:	d2a5a583          	lw	a1,-726(a1) # 80018940 <sb+0x18>
    80003c1e:	9dbd                	addw	a1,a1,a5
    80003c20:	4088                	lw	a0,0(s1)
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	7ac080e7          	jalr	1964(ra) # 800033ce <bread>
    80003c2a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c2c:	05850593          	addi	a1,a0,88
    80003c30:	40dc                	lw	a5,4(s1)
    80003c32:	8bbd                	andi	a5,a5,15
    80003c34:	079a                	slli	a5,a5,0x6
    80003c36:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c38:	00059783          	lh	a5,0(a1)
    80003c3c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c40:	00259783          	lh	a5,2(a1)
    80003c44:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c48:	00459783          	lh	a5,4(a1)
    80003c4c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c50:	00659783          	lh	a5,6(a1)
    80003c54:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c58:	459c                	lw	a5,8(a1)
    80003c5a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c5c:	03400613          	li	a2,52
    80003c60:	05b1                	addi	a1,a1,12
    80003c62:	05048513          	addi	a0,s1,80
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	0da080e7          	jalr	218(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c6e:	854a                	mv	a0,s2
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	88e080e7          	jalr	-1906(ra) # 800034fe <brelse>
    ip->valid = 1;
    80003c78:	4785                	li	a5,1
    80003c7a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c7c:	04449783          	lh	a5,68(s1)
    80003c80:	fbb5                	bnez	a5,80003bf4 <ilock+0x24>
      panic("ilock: no type");
    80003c82:	00005517          	auipc	a0,0x5
    80003c86:	9a650513          	addi	a0,a0,-1626 # 80008628 <syscalls+0x198>
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	8b4080e7          	jalr	-1868(ra) # 8000053e <panic>

0000000080003c92 <iunlock>:
{
    80003c92:	1101                	addi	sp,sp,-32
    80003c94:	ec06                	sd	ra,24(sp)
    80003c96:	e822                	sd	s0,16(sp)
    80003c98:	e426                	sd	s1,8(sp)
    80003c9a:	e04a                	sd	s2,0(sp)
    80003c9c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c9e:	c905                	beqz	a0,80003cce <iunlock+0x3c>
    80003ca0:	84aa                	mv	s1,a0
    80003ca2:	01050913          	addi	s2,a0,16
    80003ca6:	854a                	mv	a0,s2
    80003ca8:	00001097          	auipc	ra,0x1
    80003cac:	c8c080e7          	jalr	-884(ra) # 80004934 <holdingsleep>
    80003cb0:	cd19                	beqz	a0,80003cce <iunlock+0x3c>
    80003cb2:	449c                	lw	a5,8(s1)
    80003cb4:	00f05d63          	blez	a5,80003cce <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cb8:	854a                	mv	a0,s2
    80003cba:	00001097          	auipc	ra,0x1
    80003cbe:	c36080e7          	jalr	-970(ra) # 800048f0 <releasesleep>
}
    80003cc2:	60e2                	ld	ra,24(sp)
    80003cc4:	6442                	ld	s0,16(sp)
    80003cc6:	64a2                	ld	s1,8(sp)
    80003cc8:	6902                	ld	s2,0(sp)
    80003cca:	6105                	addi	sp,sp,32
    80003ccc:	8082                	ret
    panic("iunlock");
    80003cce:	00005517          	auipc	a0,0x5
    80003cd2:	96a50513          	addi	a0,a0,-1686 # 80008638 <syscalls+0x1a8>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	868080e7          	jalr	-1944(ra) # 8000053e <panic>

0000000080003cde <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cde:	7179                	addi	sp,sp,-48
    80003ce0:	f406                	sd	ra,40(sp)
    80003ce2:	f022                	sd	s0,32(sp)
    80003ce4:	ec26                	sd	s1,24(sp)
    80003ce6:	e84a                	sd	s2,16(sp)
    80003ce8:	e44e                	sd	s3,8(sp)
    80003cea:	e052                	sd	s4,0(sp)
    80003cec:	1800                	addi	s0,sp,48
    80003cee:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cf0:	05050493          	addi	s1,a0,80
    80003cf4:	08050913          	addi	s2,a0,128
    80003cf8:	a021                	j	80003d00 <itrunc+0x22>
    80003cfa:	0491                	addi	s1,s1,4
    80003cfc:	01248d63          	beq	s1,s2,80003d16 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d00:	408c                	lw	a1,0(s1)
    80003d02:	dde5                	beqz	a1,80003cfa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d04:	0009a503          	lw	a0,0(s3)
    80003d08:	00000097          	auipc	ra,0x0
    80003d0c:	90c080e7          	jalr	-1780(ra) # 80003614 <bfree>
      ip->addrs[i] = 0;
    80003d10:	0004a023          	sw	zero,0(s1)
    80003d14:	b7dd                	j	80003cfa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d16:	0809a583          	lw	a1,128(s3)
    80003d1a:	e185                	bnez	a1,80003d3a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d1c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d20:	854e                	mv	a0,s3
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	de4080e7          	jalr	-540(ra) # 80003b06 <iupdate>
}
    80003d2a:	70a2                	ld	ra,40(sp)
    80003d2c:	7402                	ld	s0,32(sp)
    80003d2e:	64e2                	ld	s1,24(sp)
    80003d30:	6942                	ld	s2,16(sp)
    80003d32:	69a2                	ld	s3,8(sp)
    80003d34:	6a02                	ld	s4,0(sp)
    80003d36:	6145                	addi	sp,sp,48
    80003d38:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d3a:	0009a503          	lw	a0,0(s3)
    80003d3e:	fffff097          	auipc	ra,0xfffff
    80003d42:	690080e7          	jalr	1680(ra) # 800033ce <bread>
    80003d46:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d48:	05850493          	addi	s1,a0,88
    80003d4c:	45850913          	addi	s2,a0,1112
    80003d50:	a811                	j	80003d64 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d52:	0009a503          	lw	a0,0(s3)
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	8be080e7          	jalr	-1858(ra) # 80003614 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d5e:	0491                	addi	s1,s1,4
    80003d60:	01248563          	beq	s1,s2,80003d6a <itrunc+0x8c>
      if(a[j])
    80003d64:	408c                	lw	a1,0(s1)
    80003d66:	dde5                	beqz	a1,80003d5e <itrunc+0x80>
    80003d68:	b7ed                	j	80003d52 <itrunc+0x74>
    brelse(bp);
    80003d6a:	8552                	mv	a0,s4
    80003d6c:	fffff097          	auipc	ra,0xfffff
    80003d70:	792080e7          	jalr	1938(ra) # 800034fe <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d74:	0809a583          	lw	a1,128(s3)
    80003d78:	0009a503          	lw	a0,0(s3)
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	898080e7          	jalr	-1896(ra) # 80003614 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d84:	0809a023          	sw	zero,128(s3)
    80003d88:	bf51                	j	80003d1c <itrunc+0x3e>

0000000080003d8a <iput>:
{
    80003d8a:	1101                	addi	sp,sp,-32
    80003d8c:	ec06                	sd	ra,24(sp)
    80003d8e:	e822                	sd	s0,16(sp)
    80003d90:	e426                	sd	s1,8(sp)
    80003d92:	e04a                	sd	s2,0(sp)
    80003d94:	1000                	addi	s0,sp,32
    80003d96:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d98:	00015517          	auipc	a0,0x15
    80003d9c:	bb050513          	addi	a0,a0,-1104 # 80018948 <itable>
    80003da0:	ffffd097          	auipc	ra,0xffffd
    80003da4:	e44080e7          	jalr	-444(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003da8:	4498                	lw	a4,8(s1)
    80003daa:	4785                	li	a5,1
    80003dac:	02f70363          	beq	a4,a5,80003dd2 <iput+0x48>
  ip->ref--;
    80003db0:	449c                	lw	a5,8(s1)
    80003db2:	37fd                	addiw	a5,a5,-1
    80003db4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003db6:	00015517          	auipc	a0,0x15
    80003dba:	b9250513          	addi	a0,a0,-1134 # 80018948 <itable>
    80003dbe:	ffffd097          	auipc	ra,0xffffd
    80003dc2:	eda080e7          	jalr	-294(ra) # 80000c98 <release>
}
    80003dc6:	60e2                	ld	ra,24(sp)
    80003dc8:	6442                	ld	s0,16(sp)
    80003dca:	64a2                	ld	s1,8(sp)
    80003dcc:	6902                	ld	s2,0(sp)
    80003dce:	6105                	addi	sp,sp,32
    80003dd0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dd2:	40bc                	lw	a5,64(s1)
    80003dd4:	dff1                	beqz	a5,80003db0 <iput+0x26>
    80003dd6:	04a49783          	lh	a5,74(s1)
    80003dda:	fbf9                	bnez	a5,80003db0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ddc:	01048913          	addi	s2,s1,16
    80003de0:	854a                	mv	a0,s2
    80003de2:	00001097          	auipc	ra,0x1
    80003de6:	ab8080e7          	jalr	-1352(ra) # 8000489a <acquiresleep>
    release(&itable.lock);
    80003dea:	00015517          	auipc	a0,0x15
    80003dee:	b5e50513          	addi	a0,a0,-1186 # 80018948 <itable>
    80003df2:	ffffd097          	auipc	ra,0xffffd
    80003df6:	ea6080e7          	jalr	-346(ra) # 80000c98 <release>
    itrunc(ip);
    80003dfa:	8526                	mv	a0,s1
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	ee2080e7          	jalr	-286(ra) # 80003cde <itrunc>
    ip->type = 0;
    80003e04:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e08:	8526                	mv	a0,s1
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	cfc080e7          	jalr	-772(ra) # 80003b06 <iupdate>
    ip->valid = 0;
    80003e12:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e16:	854a                	mv	a0,s2
    80003e18:	00001097          	auipc	ra,0x1
    80003e1c:	ad8080e7          	jalr	-1320(ra) # 800048f0 <releasesleep>
    acquire(&itable.lock);
    80003e20:	00015517          	auipc	a0,0x15
    80003e24:	b2850513          	addi	a0,a0,-1240 # 80018948 <itable>
    80003e28:	ffffd097          	auipc	ra,0xffffd
    80003e2c:	dbc080e7          	jalr	-580(ra) # 80000be4 <acquire>
    80003e30:	b741                	j	80003db0 <iput+0x26>

0000000080003e32 <iunlockput>:
{
    80003e32:	1101                	addi	sp,sp,-32
    80003e34:	ec06                	sd	ra,24(sp)
    80003e36:	e822                	sd	s0,16(sp)
    80003e38:	e426                	sd	s1,8(sp)
    80003e3a:	1000                	addi	s0,sp,32
    80003e3c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	e54080e7          	jalr	-428(ra) # 80003c92 <iunlock>
  iput(ip);
    80003e46:	8526                	mv	a0,s1
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	f42080e7          	jalr	-190(ra) # 80003d8a <iput>
}
    80003e50:	60e2                	ld	ra,24(sp)
    80003e52:	6442                	ld	s0,16(sp)
    80003e54:	64a2                	ld	s1,8(sp)
    80003e56:	6105                	addi	sp,sp,32
    80003e58:	8082                	ret

0000000080003e5a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e5a:	1141                	addi	sp,sp,-16
    80003e5c:	e422                	sd	s0,8(sp)
    80003e5e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e60:	411c                	lw	a5,0(a0)
    80003e62:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e64:	415c                	lw	a5,4(a0)
    80003e66:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e68:	04451783          	lh	a5,68(a0)
    80003e6c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e70:	04a51783          	lh	a5,74(a0)
    80003e74:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e78:	04c56783          	lwu	a5,76(a0)
    80003e7c:	e99c                	sd	a5,16(a1)
}
    80003e7e:	6422                	ld	s0,8(sp)
    80003e80:	0141                	addi	sp,sp,16
    80003e82:	8082                	ret

0000000080003e84 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e84:	457c                	lw	a5,76(a0)
    80003e86:	0ed7e963          	bltu	a5,a3,80003f78 <readi+0xf4>
{
    80003e8a:	7159                	addi	sp,sp,-112
    80003e8c:	f486                	sd	ra,104(sp)
    80003e8e:	f0a2                	sd	s0,96(sp)
    80003e90:	eca6                	sd	s1,88(sp)
    80003e92:	e8ca                	sd	s2,80(sp)
    80003e94:	e4ce                	sd	s3,72(sp)
    80003e96:	e0d2                	sd	s4,64(sp)
    80003e98:	fc56                	sd	s5,56(sp)
    80003e9a:	f85a                	sd	s6,48(sp)
    80003e9c:	f45e                	sd	s7,40(sp)
    80003e9e:	f062                	sd	s8,32(sp)
    80003ea0:	ec66                	sd	s9,24(sp)
    80003ea2:	e86a                	sd	s10,16(sp)
    80003ea4:	e46e                	sd	s11,8(sp)
    80003ea6:	1880                	addi	s0,sp,112
    80003ea8:	8baa                	mv	s7,a0
    80003eaa:	8c2e                	mv	s8,a1
    80003eac:	8ab2                	mv	s5,a2
    80003eae:	84b6                	mv	s1,a3
    80003eb0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003eb2:	9f35                	addw	a4,a4,a3
    return 0;
    80003eb4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003eb6:	0ad76063          	bltu	a4,a3,80003f56 <readi+0xd2>
  if(off + n > ip->size)
    80003eba:	00e7f463          	bgeu	a5,a4,80003ec2 <readi+0x3e>
    n = ip->size - off;
    80003ebe:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ec2:	0a0b0963          	beqz	s6,80003f74 <readi+0xf0>
    80003ec6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ec8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ecc:	5cfd                	li	s9,-1
    80003ece:	a82d                	j	80003f08 <readi+0x84>
    80003ed0:	020a1d93          	slli	s11,s4,0x20
    80003ed4:	020ddd93          	srli	s11,s11,0x20
    80003ed8:	05890613          	addi	a2,s2,88
    80003edc:	86ee                	mv	a3,s11
    80003ede:	963a                	add	a2,a2,a4
    80003ee0:	85d6                	mv	a1,s5
    80003ee2:	8562                	mv	a0,s8
    80003ee4:	fffff097          	auipc	ra,0xfffff
    80003ee8:	ae4080e7          	jalr	-1308(ra) # 800029c8 <either_copyout>
    80003eec:	05950d63          	beq	a0,s9,80003f46 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	60c080e7          	jalr	1548(ra) # 800034fe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003efa:	013a09bb          	addw	s3,s4,s3
    80003efe:	009a04bb          	addw	s1,s4,s1
    80003f02:	9aee                	add	s5,s5,s11
    80003f04:	0569f763          	bgeu	s3,s6,80003f52 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f08:	000ba903          	lw	s2,0(s7)
    80003f0c:	00a4d59b          	srliw	a1,s1,0xa
    80003f10:	855e                	mv	a0,s7
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	8b0080e7          	jalr	-1872(ra) # 800037c2 <bmap>
    80003f1a:	0005059b          	sext.w	a1,a0
    80003f1e:	854a                	mv	a0,s2
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	4ae080e7          	jalr	1198(ra) # 800033ce <bread>
    80003f28:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f2a:	3ff4f713          	andi	a4,s1,1023
    80003f2e:	40ed07bb          	subw	a5,s10,a4
    80003f32:	413b06bb          	subw	a3,s6,s3
    80003f36:	8a3e                	mv	s4,a5
    80003f38:	2781                	sext.w	a5,a5
    80003f3a:	0006861b          	sext.w	a2,a3
    80003f3e:	f8f679e3          	bgeu	a2,a5,80003ed0 <readi+0x4c>
    80003f42:	8a36                	mv	s4,a3
    80003f44:	b771                	j	80003ed0 <readi+0x4c>
      brelse(bp);
    80003f46:	854a                	mv	a0,s2
    80003f48:	fffff097          	auipc	ra,0xfffff
    80003f4c:	5b6080e7          	jalr	1462(ra) # 800034fe <brelse>
      tot = -1;
    80003f50:	59fd                	li	s3,-1
  }
  return tot;
    80003f52:	0009851b          	sext.w	a0,s3
}
    80003f56:	70a6                	ld	ra,104(sp)
    80003f58:	7406                	ld	s0,96(sp)
    80003f5a:	64e6                	ld	s1,88(sp)
    80003f5c:	6946                	ld	s2,80(sp)
    80003f5e:	69a6                	ld	s3,72(sp)
    80003f60:	6a06                	ld	s4,64(sp)
    80003f62:	7ae2                	ld	s5,56(sp)
    80003f64:	7b42                	ld	s6,48(sp)
    80003f66:	7ba2                	ld	s7,40(sp)
    80003f68:	7c02                	ld	s8,32(sp)
    80003f6a:	6ce2                	ld	s9,24(sp)
    80003f6c:	6d42                	ld	s10,16(sp)
    80003f6e:	6da2                	ld	s11,8(sp)
    80003f70:	6165                	addi	sp,sp,112
    80003f72:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f74:	89da                	mv	s3,s6
    80003f76:	bff1                	j	80003f52 <readi+0xce>
    return 0;
    80003f78:	4501                	li	a0,0
}
    80003f7a:	8082                	ret

0000000080003f7c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f7c:	457c                	lw	a5,76(a0)
    80003f7e:	10d7e863          	bltu	a5,a3,8000408e <writei+0x112>
{
    80003f82:	7159                	addi	sp,sp,-112
    80003f84:	f486                	sd	ra,104(sp)
    80003f86:	f0a2                	sd	s0,96(sp)
    80003f88:	eca6                	sd	s1,88(sp)
    80003f8a:	e8ca                	sd	s2,80(sp)
    80003f8c:	e4ce                	sd	s3,72(sp)
    80003f8e:	e0d2                	sd	s4,64(sp)
    80003f90:	fc56                	sd	s5,56(sp)
    80003f92:	f85a                	sd	s6,48(sp)
    80003f94:	f45e                	sd	s7,40(sp)
    80003f96:	f062                	sd	s8,32(sp)
    80003f98:	ec66                	sd	s9,24(sp)
    80003f9a:	e86a                	sd	s10,16(sp)
    80003f9c:	e46e                	sd	s11,8(sp)
    80003f9e:	1880                	addi	s0,sp,112
    80003fa0:	8b2a                	mv	s6,a0
    80003fa2:	8c2e                	mv	s8,a1
    80003fa4:	8ab2                	mv	s5,a2
    80003fa6:	8936                	mv	s2,a3
    80003fa8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003faa:	00e687bb          	addw	a5,a3,a4
    80003fae:	0ed7e263          	bltu	a5,a3,80004092 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fb2:	00043737          	lui	a4,0x43
    80003fb6:	0ef76063          	bltu	a4,a5,80004096 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fba:	0c0b8863          	beqz	s7,8000408a <writei+0x10e>
    80003fbe:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fc0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fc4:	5cfd                	li	s9,-1
    80003fc6:	a091                	j	8000400a <writei+0x8e>
    80003fc8:	02099d93          	slli	s11,s3,0x20
    80003fcc:	020ddd93          	srli	s11,s11,0x20
    80003fd0:	05848513          	addi	a0,s1,88
    80003fd4:	86ee                	mv	a3,s11
    80003fd6:	8656                	mv	a2,s5
    80003fd8:	85e2                	mv	a1,s8
    80003fda:	953a                	add	a0,a0,a4
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	a42080e7          	jalr	-1470(ra) # 80002a1e <either_copyin>
    80003fe4:	07950263          	beq	a0,s9,80004048 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	790080e7          	jalr	1936(ra) # 8000477a <log_write>
    brelse(bp);
    80003ff2:	8526                	mv	a0,s1
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	50a080e7          	jalr	1290(ra) # 800034fe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ffc:	01498a3b          	addw	s4,s3,s4
    80004000:	0129893b          	addw	s2,s3,s2
    80004004:	9aee                	add	s5,s5,s11
    80004006:	057a7663          	bgeu	s4,s7,80004052 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000400a:	000b2483          	lw	s1,0(s6)
    8000400e:	00a9559b          	srliw	a1,s2,0xa
    80004012:	855a                	mv	a0,s6
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	7ae080e7          	jalr	1966(ra) # 800037c2 <bmap>
    8000401c:	0005059b          	sext.w	a1,a0
    80004020:	8526                	mv	a0,s1
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	3ac080e7          	jalr	940(ra) # 800033ce <bread>
    8000402a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000402c:	3ff97713          	andi	a4,s2,1023
    80004030:	40ed07bb          	subw	a5,s10,a4
    80004034:	414b86bb          	subw	a3,s7,s4
    80004038:	89be                	mv	s3,a5
    8000403a:	2781                	sext.w	a5,a5
    8000403c:	0006861b          	sext.w	a2,a3
    80004040:	f8f674e3          	bgeu	a2,a5,80003fc8 <writei+0x4c>
    80004044:	89b6                	mv	s3,a3
    80004046:	b749                	j	80003fc8 <writei+0x4c>
      brelse(bp);
    80004048:	8526                	mv	a0,s1
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	4b4080e7          	jalr	1204(ra) # 800034fe <brelse>
  }

  if(off > ip->size)
    80004052:	04cb2783          	lw	a5,76(s6)
    80004056:	0127f463          	bgeu	a5,s2,8000405e <writei+0xe2>
    ip->size = off;
    8000405a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000405e:	855a                	mv	a0,s6
    80004060:	00000097          	auipc	ra,0x0
    80004064:	aa6080e7          	jalr	-1370(ra) # 80003b06 <iupdate>

  return tot;
    80004068:	000a051b          	sext.w	a0,s4
}
    8000406c:	70a6                	ld	ra,104(sp)
    8000406e:	7406                	ld	s0,96(sp)
    80004070:	64e6                	ld	s1,88(sp)
    80004072:	6946                	ld	s2,80(sp)
    80004074:	69a6                	ld	s3,72(sp)
    80004076:	6a06                	ld	s4,64(sp)
    80004078:	7ae2                	ld	s5,56(sp)
    8000407a:	7b42                	ld	s6,48(sp)
    8000407c:	7ba2                	ld	s7,40(sp)
    8000407e:	7c02                	ld	s8,32(sp)
    80004080:	6ce2                	ld	s9,24(sp)
    80004082:	6d42                	ld	s10,16(sp)
    80004084:	6da2                	ld	s11,8(sp)
    80004086:	6165                	addi	sp,sp,112
    80004088:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000408a:	8a5e                	mv	s4,s7
    8000408c:	bfc9                	j	8000405e <writei+0xe2>
    return -1;
    8000408e:	557d                	li	a0,-1
}
    80004090:	8082                	ret
    return -1;
    80004092:	557d                	li	a0,-1
    80004094:	bfe1                	j	8000406c <writei+0xf0>
    return -1;
    80004096:	557d                	li	a0,-1
    80004098:	bfd1                	j	8000406c <writei+0xf0>

000000008000409a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000409a:	1141                	addi	sp,sp,-16
    8000409c:	e406                	sd	ra,8(sp)
    8000409e:	e022                	sd	s0,0(sp)
    800040a0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040a2:	4639                	li	a2,14
    800040a4:	ffffd097          	auipc	ra,0xffffd
    800040a8:	d14080e7          	jalr	-748(ra) # 80000db8 <strncmp>
}
    800040ac:	60a2                	ld	ra,8(sp)
    800040ae:	6402                	ld	s0,0(sp)
    800040b0:	0141                	addi	sp,sp,16
    800040b2:	8082                	ret

00000000800040b4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040b4:	7139                	addi	sp,sp,-64
    800040b6:	fc06                	sd	ra,56(sp)
    800040b8:	f822                	sd	s0,48(sp)
    800040ba:	f426                	sd	s1,40(sp)
    800040bc:	f04a                	sd	s2,32(sp)
    800040be:	ec4e                	sd	s3,24(sp)
    800040c0:	e852                	sd	s4,16(sp)
    800040c2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040c4:	04451703          	lh	a4,68(a0)
    800040c8:	4785                	li	a5,1
    800040ca:	00f71a63          	bne	a4,a5,800040de <dirlookup+0x2a>
    800040ce:	892a                	mv	s2,a0
    800040d0:	89ae                	mv	s3,a1
    800040d2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040d4:	457c                	lw	a5,76(a0)
    800040d6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040d8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040da:	e79d                	bnez	a5,80004108 <dirlookup+0x54>
    800040dc:	a8a5                	j	80004154 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040de:	00004517          	auipc	a0,0x4
    800040e2:	56250513          	addi	a0,a0,1378 # 80008640 <syscalls+0x1b0>
    800040e6:	ffffc097          	auipc	ra,0xffffc
    800040ea:	458080e7          	jalr	1112(ra) # 8000053e <panic>
      panic("dirlookup read");
    800040ee:	00004517          	auipc	a0,0x4
    800040f2:	56a50513          	addi	a0,a0,1386 # 80008658 <syscalls+0x1c8>
    800040f6:	ffffc097          	auipc	ra,0xffffc
    800040fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040fe:	24c1                	addiw	s1,s1,16
    80004100:	04c92783          	lw	a5,76(s2)
    80004104:	04f4f763          	bgeu	s1,a5,80004152 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004108:	4741                	li	a4,16
    8000410a:	86a6                	mv	a3,s1
    8000410c:	fc040613          	addi	a2,s0,-64
    80004110:	4581                	li	a1,0
    80004112:	854a                	mv	a0,s2
    80004114:	00000097          	auipc	ra,0x0
    80004118:	d70080e7          	jalr	-656(ra) # 80003e84 <readi>
    8000411c:	47c1                	li	a5,16
    8000411e:	fcf518e3          	bne	a0,a5,800040ee <dirlookup+0x3a>
    if(de.inum == 0)
    80004122:	fc045783          	lhu	a5,-64(s0)
    80004126:	dfe1                	beqz	a5,800040fe <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004128:	fc240593          	addi	a1,s0,-62
    8000412c:	854e                	mv	a0,s3
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	f6c080e7          	jalr	-148(ra) # 8000409a <namecmp>
    80004136:	f561                	bnez	a0,800040fe <dirlookup+0x4a>
      if(poff)
    80004138:	000a0463          	beqz	s4,80004140 <dirlookup+0x8c>
        *poff = off;
    8000413c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004140:	fc045583          	lhu	a1,-64(s0)
    80004144:	00092503          	lw	a0,0(s2)
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	754080e7          	jalr	1876(ra) # 8000389c <iget>
    80004150:	a011                	j	80004154 <dirlookup+0xa0>
  return 0;
    80004152:	4501                	li	a0,0
}
    80004154:	70e2                	ld	ra,56(sp)
    80004156:	7442                	ld	s0,48(sp)
    80004158:	74a2                	ld	s1,40(sp)
    8000415a:	7902                	ld	s2,32(sp)
    8000415c:	69e2                	ld	s3,24(sp)
    8000415e:	6a42                	ld	s4,16(sp)
    80004160:	6121                	addi	sp,sp,64
    80004162:	8082                	ret

0000000080004164 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004164:	711d                	addi	sp,sp,-96
    80004166:	ec86                	sd	ra,88(sp)
    80004168:	e8a2                	sd	s0,80(sp)
    8000416a:	e4a6                	sd	s1,72(sp)
    8000416c:	e0ca                	sd	s2,64(sp)
    8000416e:	fc4e                	sd	s3,56(sp)
    80004170:	f852                	sd	s4,48(sp)
    80004172:	f456                	sd	s5,40(sp)
    80004174:	f05a                	sd	s6,32(sp)
    80004176:	ec5e                	sd	s7,24(sp)
    80004178:	e862                	sd	s8,16(sp)
    8000417a:	e466                	sd	s9,8(sp)
    8000417c:	1080                	addi	s0,sp,96
    8000417e:	84aa                	mv	s1,a0
    80004180:	8b2e                	mv	s6,a1
    80004182:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004184:	00054703          	lbu	a4,0(a0)
    80004188:	02f00793          	li	a5,47
    8000418c:	02f70363          	beq	a4,a5,800041b2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004190:	ffffe097          	auipc	ra,0xffffe
    80004194:	944080e7          	jalr	-1724(ra) # 80001ad4 <myproc>
    80004198:	16853503          	ld	a0,360(a0)
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	9f6080e7          	jalr	-1546(ra) # 80003b92 <idup>
    800041a4:	89aa                	mv	s3,a0
  while(*path == '/')
    800041a6:	02f00913          	li	s2,47
  len = path - s;
    800041aa:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800041ac:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041ae:	4c05                	li	s8,1
    800041b0:	a865                	j	80004268 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041b2:	4585                	li	a1,1
    800041b4:	4505                	li	a0,1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	6e6080e7          	jalr	1766(ra) # 8000389c <iget>
    800041be:	89aa                	mv	s3,a0
    800041c0:	b7dd                	j	800041a6 <namex+0x42>
      iunlockput(ip);
    800041c2:	854e                	mv	a0,s3
    800041c4:	00000097          	auipc	ra,0x0
    800041c8:	c6e080e7          	jalr	-914(ra) # 80003e32 <iunlockput>
      return 0;
    800041cc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041ce:	854e                	mv	a0,s3
    800041d0:	60e6                	ld	ra,88(sp)
    800041d2:	6446                	ld	s0,80(sp)
    800041d4:	64a6                	ld	s1,72(sp)
    800041d6:	6906                	ld	s2,64(sp)
    800041d8:	79e2                	ld	s3,56(sp)
    800041da:	7a42                	ld	s4,48(sp)
    800041dc:	7aa2                	ld	s5,40(sp)
    800041de:	7b02                	ld	s6,32(sp)
    800041e0:	6be2                	ld	s7,24(sp)
    800041e2:	6c42                	ld	s8,16(sp)
    800041e4:	6ca2                	ld	s9,8(sp)
    800041e6:	6125                	addi	sp,sp,96
    800041e8:	8082                	ret
      iunlock(ip);
    800041ea:	854e                	mv	a0,s3
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	aa6080e7          	jalr	-1370(ra) # 80003c92 <iunlock>
      return ip;
    800041f4:	bfe9                	j	800041ce <namex+0x6a>
      iunlockput(ip);
    800041f6:	854e                	mv	a0,s3
    800041f8:	00000097          	auipc	ra,0x0
    800041fc:	c3a080e7          	jalr	-966(ra) # 80003e32 <iunlockput>
      return 0;
    80004200:	89d2                	mv	s3,s4
    80004202:	b7f1                	j	800041ce <namex+0x6a>
  len = path - s;
    80004204:	40b48633          	sub	a2,s1,a1
    80004208:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000420c:	094cd463          	bge	s9,s4,80004294 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004210:	4639                	li	a2,14
    80004212:	8556                	mv	a0,s5
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	b2c080e7          	jalr	-1236(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000421c:	0004c783          	lbu	a5,0(s1)
    80004220:	01279763          	bne	a5,s2,8000422e <namex+0xca>
    path++;
    80004224:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004226:	0004c783          	lbu	a5,0(s1)
    8000422a:	ff278de3          	beq	a5,s2,80004224 <namex+0xc0>
    ilock(ip);
    8000422e:	854e                	mv	a0,s3
    80004230:	00000097          	auipc	ra,0x0
    80004234:	9a0080e7          	jalr	-1632(ra) # 80003bd0 <ilock>
    if(ip->type != T_DIR){
    80004238:	04499783          	lh	a5,68(s3)
    8000423c:	f98793e3          	bne	a5,s8,800041c2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004240:	000b0563          	beqz	s6,8000424a <namex+0xe6>
    80004244:	0004c783          	lbu	a5,0(s1)
    80004248:	d3cd                	beqz	a5,800041ea <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000424a:	865e                	mv	a2,s7
    8000424c:	85d6                	mv	a1,s5
    8000424e:	854e                	mv	a0,s3
    80004250:	00000097          	auipc	ra,0x0
    80004254:	e64080e7          	jalr	-412(ra) # 800040b4 <dirlookup>
    80004258:	8a2a                	mv	s4,a0
    8000425a:	dd51                	beqz	a0,800041f6 <namex+0x92>
    iunlockput(ip);
    8000425c:	854e                	mv	a0,s3
    8000425e:	00000097          	auipc	ra,0x0
    80004262:	bd4080e7          	jalr	-1068(ra) # 80003e32 <iunlockput>
    ip = next;
    80004266:	89d2                	mv	s3,s4
  while(*path == '/')
    80004268:	0004c783          	lbu	a5,0(s1)
    8000426c:	05279763          	bne	a5,s2,800042ba <namex+0x156>
    path++;
    80004270:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004272:	0004c783          	lbu	a5,0(s1)
    80004276:	ff278de3          	beq	a5,s2,80004270 <namex+0x10c>
  if(*path == 0)
    8000427a:	c79d                	beqz	a5,800042a8 <namex+0x144>
    path++;
    8000427c:	85a6                	mv	a1,s1
  len = path - s;
    8000427e:	8a5e                	mv	s4,s7
    80004280:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004282:	01278963          	beq	a5,s2,80004294 <namex+0x130>
    80004286:	dfbd                	beqz	a5,80004204 <namex+0xa0>
    path++;
    80004288:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000428a:	0004c783          	lbu	a5,0(s1)
    8000428e:	ff279ce3          	bne	a5,s2,80004286 <namex+0x122>
    80004292:	bf8d                	j	80004204 <namex+0xa0>
    memmove(name, s, len);
    80004294:	2601                	sext.w	a2,a2
    80004296:	8556                	mv	a0,s5
    80004298:	ffffd097          	auipc	ra,0xffffd
    8000429c:	aa8080e7          	jalr	-1368(ra) # 80000d40 <memmove>
    name[len] = 0;
    800042a0:	9a56                	add	s4,s4,s5
    800042a2:	000a0023          	sb	zero,0(s4)
    800042a6:	bf9d                	j	8000421c <namex+0xb8>
  if(nameiparent){
    800042a8:	f20b03e3          	beqz	s6,800041ce <namex+0x6a>
    iput(ip);
    800042ac:	854e                	mv	a0,s3
    800042ae:	00000097          	auipc	ra,0x0
    800042b2:	adc080e7          	jalr	-1316(ra) # 80003d8a <iput>
    return 0;
    800042b6:	4981                	li	s3,0
    800042b8:	bf19                	j	800041ce <namex+0x6a>
  if(*path == 0)
    800042ba:	d7fd                	beqz	a5,800042a8 <namex+0x144>
  while(*path != '/' && *path != 0)
    800042bc:	0004c783          	lbu	a5,0(s1)
    800042c0:	85a6                	mv	a1,s1
    800042c2:	b7d1                	j	80004286 <namex+0x122>

00000000800042c4 <dirlink>:
{
    800042c4:	7139                	addi	sp,sp,-64
    800042c6:	fc06                	sd	ra,56(sp)
    800042c8:	f822                	sd	s0,48(sp)
    800042ca:	f426                	sd	s1,40(sp)
    800042cc:	f04a                	sd	s2,32(sp)
    800042ce:	ec4e                	sd	s3,24(sp)
    800042d0:	e852                	sd	s4,16(sp)
    800042d2:	0080                	addi	s0,sp,64
    800042d4:	892a                	mv	s2,a0
    800042d6:	8a2e                	mv	s4,a1
    800042d8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042da:	4601                	li	a2,0
    800042dc:	00000097          	auipc	ra,0x0
    800042e0:	dd8080e7          	jalr	-552(ra) # 800040b4 <dirlookup>
    800042e4:	e93d                	bnez	a0,8000435a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e6:	04c92483          	lw	s1,76(s2)
    800042ea:	c49d                	beqz	s1,80004318 <dirlink+0x54>
    800042ec:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ee:	4741                	li	a4,16
    800042f0:	86a6                	mv	a3,s1
    800042f2:	fc040613          	addi	a2,s0,-64
    800042f6:	4581                	li	a1,0
    800042f8:	854a                	mv	a0,s2
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	b8a080e7          	jalr	-1142(ra) # 80003e84 <readi>
    80004302:	47c1                	li	a5,16
    80004304:	06f51163          	bne	a0,a5,80004366 <dirlink+0xa2>
    if(de.inum == 0)
    80004308:	fc045783          	lhu	a5,-64(s0)
    8000430c:	c791                	beqz	a5,80004318 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000430e:	24c1                	addiw	s1,s1,16
    80004310:	04c92783          	lw	a5,76(s2)
    80004314:	fcf4ede3          	bltu	s1,a5,800042ee <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004318:	4639                	li	a2,14
    8000431a:	85d2                	mv	a1,s4
    8000431c:	fc240513          	addi	a0,s0,-62
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	ad4080e7          	jalr	-1324(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004328:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000432c:	4741                	li	a4,16
    8000432e:	86a6                	mv	a3,s1
    80004330:	fc040613          	addi	a2,s0,-64
    80004334:	4581                	li	a1,0
    80004336:	854a                	mv	a0,s2
    80004338:	00000097          	auipc	ra,0x0
    8000433c:	c44080e7          	jalr	-956(ra) # 80003f7c <writei>
    80004340:	872a                	mv	a4,a0
    80004342:	47c1                	li	a5,16
  return 0;
    80004344:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004346:	02f71863          	bne	a4,a5,80004376 <dirlink+0xb2>
}
    8000434a:	70e2                	ld	ra,56(sp)
    8000434c:	7442                	ld	s0,48(sp)
    8000434e:	74a2                	ld	s1,40(sp)
    80004350:	7902                	ld	s2,32(sp)
    80004352:	69e2                	ld	s3,24(sp)
    80004354:	6a42                	ld	s4,16(sp)
    80004356:	6121                	addi	sp,sp,64
    80004358:	8082                	ret
    iput(ip);
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	a30080e7          	jalr	-1488(ra) # 80003d8a <iput>
    return -1;
    80004362:	557d                	li	a0,-1
    80004364:	b7dd                	j	8000434a <dirlink+0x86>
      panic("dirlink read");
    80004366:	00004517          	auipc	a0,0x4
    8000436a:	30250513          	addi	a0,a0,770 # 80008668 <syscalls+0x1d8>
    8000436e:	ffffc097          	auipc	ra,0xffffc
    80004372:	1d0080e7          	jalr	464(ra) # 8000053e <panic>
    panic("dirlink");
    80004376:	00004517          	auipc	a0,0x4
    8000437a:	40250513          	addi	a0,a0,1026 # 80008778 <syscalls+0x2e8>
    8000437e:	ffffc097          	auipc	ra,0xffffc
    80004382:	1c0080e7          	jalr	448(ra) # 8000053e <panic>

0000000080004386 <namei>:

struct inode*
namei(char *path)
{
    80004386:	1101                	addi	sp,sp,-32
    80004388:	ec06                	sd	ra,24(sp)
    8000438a:	e822                	sd	s0,16(sp)
    8000438c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000438e:	fe040613          	addi	a2,s0,-32
    80004392:	4581                	li	a1,0
    80004394:	00000097          	auipc	ra,0x0
    80004398:	dd0080e7          	jalr	-560(ra) # 80004164 <namex>
}
    8000439c:	60e2                	ld	ra,24(sp)
    8000439e:	6442                	ld	s0,16(sp)
    800043a0:	6105                	addi	sp,sp,32
    800043a2:	8082                	ret

00000000800043a4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043a4:	1141                	addi	sp,sp,-16
    800043a6:	e406                	sd	ra,8(sp)
    800043a8:	e022                	sd	s0,0(sp)
    800043aa:	0800                	addi	s0,sp,16
    800043ac:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043ae:	4585                	li	a1,1
    800043b0:	00000097          	auipc	ra,0x0
    800043b4:	db4080e7          	jalr	-588(ra) # 80004164 <namex>
}
    800043b8:	60a2                	ld	ra,8(sp)
    800043ba:	6402                	ld	s0,0(sp)
    800043bc:	0141                	addi	sp,sp,16
    800043be:	8082                	ret

00000000800043c0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043c0:	1101                	addi	sp,sp,-32
    800043c2:	ec06                	sd	ra,24(sp)
    800043c4:	e822                	sd	s0,16(sp)
    800043c6:	e426                	sd	s1,8(sp)
    800043c8:	e04a                	sd	s2,0(sp)
    800043ca:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043cc:	00016917          	auipc	s2,0x16
    800043d0:	02490913          	addi	s2,s2,36 # 8001a3f0 <log>
    800043d4:	01892583          	lw	a1,24(s2)
    800043d8:	02892503          	lw	a0,40(s2)
    800043dc:	fffff097          	auipc	ra,0xfffff
    800043e0:	ff2080e7          	jalr	-14(ra) # 800033ce <bread>
    800043e4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043e6:	02c92683          	lw	a3,44(s2)
    800043ea:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043ec:	02d05763          	blez	a3,8000441a <write_head+0x5a>
    800043f0:	00016797          	auipc	a5,0x16
    800043f4:	03078793          	addi	a5,a5,48 # 8001a420 <log+0x30>
    800043f8:	05c50713          	addi	a4,a0,92
    800043fc:	36fd                	addiw	a3,a3,-1
    800043fe:	1682                	slli	a3,a3,0x20
    80004400:	9281                	srli	a3,a3,0x20
    80004402:	068a                	slli	a3,a3,0x2
    80004404:	00016617          	auipc	a2,0x16
    80004408:	02060613          	addi	a2,a2,32 # 8001a424 <log+0x34>
    8000440c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000440e:	4390                	lw	a2,0(a5)
    80004410:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004412:	0791                	addi	a5,a5,4
    80004414:	0711                	addi	a4,a4,4
    80004416:	fed79ce3          	bne	a5,a3,8000440e <write_head+0x4e>
  }
  bwrite(buf);
    8000441a:	8526                	mv	a0,s1
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	0a4080e7          	jalr	164(ra) # 800034c0 <bwrite>
  brelse(buf);
    80004424:	8526                	mv	a0,s1
    80004426:	fffff097          	auipc	ra,0xfffff
    8000442a:	0d8080e7          	jalr	216(ra) # 800034fe <brelse>
}
    8000442e:	60e2                	ld	ra,24(sp)
    80004430:	6442                	ld	s0,16(sp)
    80004432:	64a2                	ld	s1,8(sp)
    80004434:	6902                	ld	s2,0(sp)
    80004436:	6105                	addi	sp,sp,32
    80004438:	8082                	ret

000000008000443a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000443a:	00016797          	auipc	a5,0x16
    8000443e:	fe27a783          	lw	a5,-30(a5) # 8001a41c <log+0x2c>
    80004442:	0af05d63          	blez	a5,800044fc <install_trans+0xc2>
{
    80004446:	7139                	addi	sp,sp,-64
    80004448:	fc06                	sd	ra,56(sp)
    8000444a:	f822                	sd	s0,48(sp)
    8000444c:	f426                	sd	s1,40(sp)
    8000444e:	f04a                	sd	s2,32(sp)
    80004450:	ec4e                	sd	s3,24(sp)
    80004452:	e852                	sd	s4,16(sp)
    80004454:	e456                	sd	s5,8(sp)
    80004456:	e05a                	sd	s6,0(sp)
    80004458:	0080                	addi	s0,sp,64
    8000445a:	8b2a                	mv	s6,a0
    8000445c:	00016a97          	auipc	s5,0x16
    80004460:	fc4a8a93          	addi	s5,s5,-60 # 8001a420 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004464:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004466:	00016997          	auipc	s3,0x16
    8000446a:	f8a98993          	addi	s3,s3,-118 # 8001a3f0 <log>
    8000446e:	a035                	j	8000449a <install_trans+0x60>
      bunpin(dbuf);
    80004470:	8526                	mv	a0,s1
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	166080e7          	jalr	358(ra) # 800035d8 <bunpin>
    brelse(lbuf);
    8000447a:	854a                	mv	a0,s2
    8000447c:	fffff097          	auipc	ra,0xfffff
    80004480:	082080e7          	jalr	130(ra) # 800034fe <brelse>
    brelse(dbuf);
    80004484:	8526                	mv	a0,s1
    80004486:	fffff097          	auipc	ra,0xfffff
    8000448a:	078080e7          	jalr	120(ra) # 800034fe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000448e:	2a05                	addiw	s4,s4,1
    80004490:	0a91                	addi	s5,s5,4
    80004492:	02c9a783          	lw	a5,44(s3)
    80004496:	04fa5963          	bge	s4,a5,800044e8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000449a:	0189a583          	lw	a1,24(s3)
    8000449e:	014585bb          	addw	a1,a1,s4
    800044a2:	2585                	addiw	a1,a1,1
    800044a4:	0289a503          	lw	a0,40(s3)
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	f26080e7          	jalr	-218(ra) # 800033ce <bread>
    800044b0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044b2:	000aa583          	lw	a1,0(s5)
    800044b6:	0289a503          	lw	a0,40(s3)
    800044ba:	fffff097          	auipc	ra,0xfffff
    800044be:	f14080e7          	jalr	-236(ra) # 800033ce <bread>
    800044c2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044c4:	40000613          	li	a2,1024
    800044c8:	05890593          	addi	a1,s2,88
    800044cc:	05850513          	addi	a0,a0,88
    800044d0:	ffffd097          	auipc	ra,0xffffd
    800044d4:	870080e7          	jalr	-1936(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800044d8:	8526                	mv	a0,s1
    800044da:	fffff097          	auipc	ra,0xfffff
    800044de:	fe6080e7          	jalr	-26(ra) # 800034c0 <bwrite>
    if(recovering == 0)
    800044e2:	f80b1ce3          	bnez	s6,8000447a <install_trans+0x40>
    800044e6:	b769                	j	80004470 <install_trans+0x36>
}
    800044e8:	70e2                	ld	ra,56(sp)
    800044ea:	7442                	ld	s0,48(sp)
    800044ec:	74a2                	ld	s1,40(sp)
    800044ee:	7902                	ld	s2,32(sp)
    800044f0:	69e2                	ld	s3,24(sp)
    800044f2:	6a42                	ld	s4,16(sp)
    800044f4:	6aa2                	ld	s5,8(sp)
    800044f6:	6b02                	ld	s6,0(sp)
    800044f8:	6121                	addi	sp,sp,64
    800044fa:	8082                	ret
    800044fc:	8082                	ret

00000000800044fe <initlog>:
{
    800044fe:	7179                	addi	sp,sp,-48
    80004500:	f406                	sd	ra,40(sp)
    80004502:	f022                	sd	s0,32(sp)
    80004504:	ec26                	sd	s1,24(sp)
    80004506:	e84a                	sd	s2,16(sp)
    80004508:	e44e                	sd	s3,8(sp)
    8000450a:	1800                	addi	s0,sp,48
    8000450c:	892a                	mv	s2,a0
    8000450e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004510:	00016497          	auipc	s1,0x16
    80004514:	ee048493          	addi	s1,s1,-288 # 8001a3f0 <log>
    80004518:	00004597          	auipc	a1,0x4
    8000451c:	16058593          	addi	a1,a1,352 # 80008678 <syscalls+0x1e8>
    80004520:	8526                	mv	a0,s1
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	632080e7          	jalr	1586(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000452a:	0149a583          	lw	a1,20(s3)
    8000452e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004530:	0109a783          	lw	a5,16(s3)
    80004534:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004536:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000453a:	854a                	mv	a0,s2
    8000453c:	fffff097          	auipc	ra,0xfffff
    80004540:	e92080e7          	jalr	-366(ra) # 800033ce <bread>
  log.lh.n = lh->n;
    80004544:	4d3c                	lw	a5,88(a0)
    80004546:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004548:	02f05563          	blez	a5,80004572 <initlog+0x74>
    8000454c:	05c50713          	addi	a4,a0,92
    80004550:	00016697          	auipc	a3,0x16
    80004554:	ed068693          	addi	a3,a3,-304 # 8001a420 <log+0x30>
    80004558:	37fd                	addiw	a5,a5,-1
    8000455a:	1782                	slli	a5,a5,0x20
    8000455c:	9381                	srli	a5,a5,0x20
    8000455e:	078a                	slli	a5,a5,0x2
    80004560:	06050613          	addi	a2,a0,96
    80004564:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004566:	4310                	lw	a2,0(a4)
    80004568:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000456a:	0711                	addi	a4,a4,4
    8000456c:	0691                	addi	a3,a3,4
    8000456e:	fef71ce3          	bne	a4,a5,80004566 <initlog+0x68>
  brelse(buf);
    80004572:	fffff097          	auipc	ra,0xfffff
    80004576:	f8c080e7          	jalr	-116(ra) # 800034fe <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000457a:	4505                	li	a0,1
    8000457c:	00000097          	auipc	ra,0x0
    80004580:	ebe080e7          	jalr	-322(ra) # 8000443a <install_trans>
  log.lh.n = 0;
    80004584:	00016797          	auipc	a5,0x16
    80004588:	e807ac23          	sw	zero,-360(a5) # 8001a41c <log+0x2c>
  write_head(); // clear the log
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	e34080e7          	jalr	-460(ra) # 800043c0 <write_head>
}
    80004594:	70a2                	ld	ra,40(sp)
    80004596:	7402                	ld	s0,32(sp)
    80004598:	64e2                	ld	s1,24(sp)
    8000459a:	6942                	ld	s2,16(sp)
    8000459c:	69a2                	ld	s3,8(sp)
    8000459e:	6145                	addi	sp,sp,48
    800045a0:	8082                	ret

00000000800045a2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045a2:	1101                	addi	sp,sp,-32
    800045a4:	ec06                	sd	ra,24(sp)
    800045a6:	e822                	sd	s0,16(sp)
    800045a8:	e426                	sd	s1,8(sp)
    800045aa:	e04a                	sd	s2,0(sp)
    800045ac:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045ae:	00016517          	auipc	a0,0x16
    800045b2:	e4250513          	addi	a0,a0,-446 # 8001a3f0 <log>
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	62e080e7          	jalr	1582(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800045be:	00016497          	auipc	s1,0x16
    800045c2:	e3248493          	addi	s1,s1,-462 # 8001a3f0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045c6:	4979                	li	s2,30
    800045c8:	a039                	j	800045d6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800045ca:	85a6                	mv	a1,s1
    800045cc:	8526                	mv	a0,s1
    800045ce:	ffffe097          	auipc	ra,0xffffe
    800045d2:	fe0080e7          	jalr	-32(ra) # 800025ae <sleep>
    if(log.committing){
    800045d6:	50dc                	lw	a5,36(s1)
    800045d8:	fbed                	bnez	a5,800045ca <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045da:	509c                	lw	a5,32(s1)
    800045dc:	0017871b          	addiw	a4,a5,1
    800045e0:	0007069b          	sext.w	a3,a4
    800045e4:	0027179b          	slliw	a5,a4,0x2
    800045e8:	9fb9                	addw	a5,a5,a4
    800045ea:	0017979b          	slliw	a5,a5,0x1
    800045ee:	54d8                	lw	a4,44(s1)
    800045f0:	9fb9                	addw	a5,a5,a4
    800045f2:	00f95963          	bge	s2,a5,80004604 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045f6:	85a6                	mv	a1,s1
    800045f8:	8526                	mv	a0,s1
    800045fa:	ffffe097          	auipc	ra,0xffffe
    800045fe:	fb4080e7          	jalr	-76(ra) # 800025ae <sleep>
    80004602:	bfd1                	j	800045d6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004604:	00016517          	auipc	a0,0x16
    80004608:	dec50513          	addi	a0,a0,-532 # 8001a3f0 <log>
    8000460c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	68a080e7          	jalr	1674(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004616:	60e2                	ld	ra,24(sp)
    80004618:	6442                	ld	s0,16(sp)
    8000461a:	64a2                	ld	s1,8(sp)
    8000461c:	6902                	ld	s2,0(sp)
    8000461e:	6105                	addi	sp,sp,32
    80004620:	8082                	ret

0000000080004622 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004622:	7139                	addi	sp,sp,-64
    80004624:	fc06                	sd	ra,56(sp)
    80004626:	f822                	sd	s0,48(sp)
    80004628:	f426                	sd	s1,40(sp)
    8000462a:	f04a                	sd	s2,32(sp)
    8000462c:	ec4e                	sd	s3,24(sp)
    8000462e:	e852                	sd	s4,16(sp)
    80004630:	e456                	sd	s5,8(sp)
    80004632:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004634:	00016497          	auipc	s1,0x16
    80004638:	dbc48493          	addi	s1,s1,-580 # 8001a3f0 <log>
    8000463c:	8526                	mv	a0,s1
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	5a6080e7          	jalr	1446(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004646:	509c                	lw	a5,32(s1)
    80004648:	37fd                	addiw	a5,a5,-1
    8000464a:	0007891b          	sext.w	s2,a5
    8000464e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004650:	50dc                	lw	a5,36(s1)
    80004652:	efb9                	bnez	a5,800046b0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004654:	06091663          	bnez	s2,800046c0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004658:	00016497          	auipc	s1,0x16
    8000465c:	d9848493          	addi	s1,s1,-616 # 8001a3f0 <log>
    80004660:	4785                	li	a5,1
    80004662:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004664:	8526                	mv	a0,s1
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	632080e7          	jalr	1586(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000466e:	54dc                	lw	a5,44(s1)
    80004670:	06f04763          	bgtz	a5,800046de <end_op+0xbc>
    acquire(&log.lock);
    80004674:	00016497          	auipc	s1,0x16
    80004678:	d7c48493          	addi	s1,s1,-644 # 8001a3f0 <log>
    8000467c:	8526                	mv	a0,s1
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	566080e7          	jalr	1382(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004686:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000468a:	8526                	mv	a0,s1
    8000468c:	ffffe097          	auipc	ra,0xffffe
    80004690:	0ae080e7          	jalr	174(ra) # 8000273a <wakeup>
    release(&log.lock);
    80004694:	8526                	mv	a0,s1
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	602080e7          	jalr	1538(ra) # 80000c98 <release>
}
    8000469e:	70e2                	ld	ra,56(sp)
    800046a0:	7442                	ld	s0,48(sp)
    800046a2:	74a2                	ld	s1,40(sp)
    800046a4:	7902                	ld	s2,32(sp)
    800046a6:	69e2                	ld	s3,24(sp)
    800046a8:	6a42                	ld	s4,16(sp)
    800046aa:	6aa2                	ld	s5,8(sp)
    800046ac:	6121                	addi	sp,sp,64
    800046ae:	8082                	ret
    panic("log.committing");
    800046b0:	00004517          	auipc	a0,0x4
    800046b4:	fd050513          	addi	a0,a0,-48 # 80008680 <syscalls+0x1f0>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	e86080e7          	jalr	-378(ra) # 8000053e <panic>
    wakeup(&log);
    800046c0:	00016497          	auipc	s1,0x16
    800046c4:	d3048493          	addi	s1,s1,-720 # 8001a3f0 <log>
    800046c8:	8526                	mv	a0,s1
    800046ca:	ffffe097          	auipc	ra,0xffffe
    800046ce:	070080e7          	jalr	112(ra) # 8000273a <wakeup>
  release(&log.lock);
    800046d2:	8526                	mv	a0,s1
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	5c4080e7          	jalr	1476(ra) # 80000c98 <release>
  if(do_commit){
    800046dc:	b7c9                	j	8000469e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046de:	00016a97          	auipc	s5,0x16
    800046e2:	d42a8a93          	addi	s5,s5,-702 # 8001a420 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046e6:	00016a17          	auipc	s4,0x16
    800046ea:	d0aa0a13          	addi	s4,s4,-758 # 8001a3f0 <log>
    800046ee:	018a2583          	lw	a1,24(s4)
    800046f2:	012585bb          	addw	a1,a1,s2
    800046f6:	2585                	addiw	a1,a1,1
    800046f8:	028a2503          	lw	a0,40(s4)
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	cd2080e7          	jalr	-814(ra) # 800033ce <bread>
    80004704:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004706:	000aa583          	lw	a1,0(s5)
    8000470a:	028a2503          	lw	a0,40(s4)
    8000470e:	fffff097          	auipc	ra,0xfffff
    80004712:	cc0080e7          	jalr	-832(ra) # 800033ce <bread>
    80004716:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004718:	40000613          	li	a2,1024
    8000471c:	05850593          	addi	a1,a0,88
    80004720:	05848513          	addi	a0,s1,88
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	61c080e7          	jalr	1564(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000472c:	8526                	mv	a0,s1
    8000472e:	fffff097          	auipc	ra,0xfffff
    80004732:	d92080e7          	jalr	-622(ra) # 800034c0 <bwrite>
    brelse(from);
    80004736:	854e                	mv	a0,s3
    80004738:	fffff097          	auipc	ra,0xfffff
    8000473c:	dc6080e7          	jalr	-570(ra) # 800034fe <brelse>
    brelse(to);
    80004740:	8526                	mv	a0,s1
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	dbc080e7          	jalr	-580(ra) # 800034fe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000474a:	2905                	addiw	s2,s2,1
    8000474c:	0a91                	addi	s5,s5,4
    8000474e:	02ca2783          	lw	a5,44(s4)
    80004752:	f8f94ee3          	blt	s2,a5,800046ee <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004756:	00000097          	auipc	ra,0x0
    8000475a:	c6a080e7          	jalr	-918(ra) # 800043c0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000475e:	4501                	li	a0,0
    80004760:	00000097          	auipc	ra,0x0
    80004764:	cda080e7          	jalr	-806(ra) # 8000443a <install_trans>
    log.lh.n = 0;
    80004768:	00016797          	auipc	a5,0x16
    8000476c:	ca07aa23          	sw	zero,-844(a5) # 8001a41c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004770:	00000097          	auipc	ra,0x0
    80004774:	c50080e7          	jalr	-944(ra) # 800043c0 <write_head>
    80004778:	bdf5                	j	80004674 <end_op+0x52>

000000008000477a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000477a:	1101                	addi	sp,sp,-32
    8000477c:	ec06                	sd	ra,24(sp)
    8000477e:	e822                	sd	s0,16(sp)
    80004780:	e426                	sd	s1,8(sp)
    80004782:	e04a                	sd	s2,0(sp)
    80004784:	1000                	addi	s0,sp,32
    80004786:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004788:	00016917          	auipc	s2,0x16
    8000478c:	c6890913          	addi	s2,s2,-920 # 8001a3f0 <log>
    80004790:	854a                	mv	a0,s2
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	452080e7          	jalr	1106(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000479a:	02c92603          	lw	a2,44(s2)
    8000479e:	47f5                	li	a5,29
    800047a0:	06c7c563          	blt	a5,a2,8000480a <log_write+0x90>
    800047a4:	00016797          	auipc	a5,0x16
    800047a8:	c687a783          	lw	a5,-920(a5) # 8001a40c <log+0x1c>
    800047ac:	37fd                	addiw	a5,a5,-1
    800047ae:	04f65e63          	bge	a2,a5,8000480a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047b2:	00016797          	auipc	a5,0x16
    800047b6:	c5e7a783          	lw	a5,-930(a5) # 8001a410 <log+0x20>
    800047ba:	06f05063          	blez	a5,8000481a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047be:	4781                	li	a5,0
    800047c0:	06c05563          	blez	a2,8000482a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047c4:	44cc                	lw	a1,12(s1)
    800047c6:	00016717          	auipc	a4,0x16
    800047ca:	c5a70713          	addi	a4,a4,-934 # 8001a420 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047ce:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047d0:	4314                	lw	a3,0(a4)
    800047d2:	04b68c63          	beq	a3,a1,8000482a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047d6:	2785                	addiw	a5,a5,1
    800047d8:	0711                	addi	a4,a4,4
    800047da:	fef61be3          	bne	a2,a5,800047d0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047de:	0621                	addi	a2,a2,8
    800047e0:	060a                	slli	a2,a2,0x2
    800047e2:	00016797          	auipc	a5,0x16
    800047e6:	c0e78793          	addi	a5,a5,-1010 # 8001a3f0 <log>
    800047ea:	963e                	add	a2,a2,a5
    800047ec:	44dc                	lw	a5,12(s1)
    800047ee:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047f0:	8526                	mv	a0,s1
    800047f2:	fffff097          	auipc	ra,0xfffff
    800047f6:	daa080e7          	jalr	-598(ra) # 8000359c <bpin>
    log.lh.n++;
    800047fa:	00016717          	auipc	a4,0x16
    800047fe:	bf670713          	addi	a4,a4,-1034 # 8001a3f0 <log>
    80004802:	575c                	lw	a5,44(a4)
    80004804:	2785                	addiw	a5,a5,1
    80004806:	d75c                	sw	a5,44(a4)
    80004808:	a835                	j	80004844 <log_write+0xca>
    panic("too big a transaction");
    8000480a:	00004517          	auipc	a0,0x4
    8000480e:	e8650513          	addi	a0,a0,-378 # 80008690 <syscalls+0x200>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	d2c080e7          	jalr	-724(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000481a:	00004517          	auipc	a0,0x4
    8000481e:	e8e50513          	addi	a0,a0,-370 # 800086a8 <syscalls+0x218>
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	d1c080e7          	jalr	-740(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000482a:	00878713          	addi	a4,a5,8
    8000482e:	00271693          	slli	a3,a4,0x2
    80004832:	00016717          	auipc	a4,0x16
    80004836:	bbe70713          	addi	a4,a4,-1090 # 8001a3f0 <log>
    8000483a:	9736                	add	a4,a4,a3
    8000483c:	44d4                	lw	a3,12(s1)
    8000483e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004840:	faf608e3          	beq	a2,a5,800047f0 <log_write+0x76>
  }
  release(&log.lock);
    80004844:	00016517          	auipc	a0,0x16
    80004848:	bac50513          	addi	a0,a0,-1108 # 8001a3f0 <log>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	44c080e7          	jalr	1100(ra) # 80000c98 <release>
}
    80004854:	60e2                	ld	ra,24(sp)
    80004856:	6442                	ld	s0,16(sp)
    80004858:	64a2                	ld	s1,8(sp)
    8000485a:	6902                	ld	s2,0(sp)
    8000485c:	6105                	addi	sp,sp,32
    8000485e:	8082                	ret

0000000080004860 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004860:	1101                	addi	sp,sp,-32
    80004862:	ec06                	sd	ra,24(sp)
    80004864:	e822                	sd	s0,16(sp)
    80004866:	e426                	sd	s1,8(sp)
    80004868:	e04a                	sd	s2,0(sp)
    8000486a:	1000                	addi	s0,sp,32
    8000486c:	84aa                	mv	s1,a0
    8000486e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004870:	00004597          	auipc	a1,0x4
    80004874:	e5858593          	addi	a1,a1,-424 # 800086c8 <syscalls+0x238>
    80004878:	0521                	addi	a0,a0,8
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	2da080e7          	jalr	730(ra) # 80000b54 <initlock>
  lk->name = name;
    80004882:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004886:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000488a:	0204a423          	sw	zero,40(s1)
}
    8000488e:	60e2                	ld	ra,24(sp)
    80004890:	6442                	ld	s0,16(sp)
    80004892:	64a2                	ld	s1,8(sp)
    80004894:	6902                	ld	s2,0(sp)
    80004896:	6105                	addi	sp,sp,32
    80004898:	8082                	ret

000000008000489a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000489a:	1101                	addi	sp,sp,-32
    8000489c:	ec06                	sd	ra,24(sp)
    8000489e:	e822                	sd	s0,16(sp)
    800048a0:	e426                	sd	s1,8(sp)
    800048a2:	e04a                	sd	s2,0(sp)
    800048a4:	1000                	addi	s0,sp,32
    800048a6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048a8:	00850913          	addi	s2,a0,8
    800048ac:	854a                	mv	a0,s2
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	336080e7          	jalr	822(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800048b6:	409c                	lw	a5,0(s1)
    800048b8:	cb89                	beqz	a5,800048ca <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048ba:	85ca                	mv	a1,s2
    800048bc:	8526                	mv	a0,s1
    800048be:	ffffe097          	auipc	ra,0xffffe
    800048c2:	cf0080e7          	jalr	-784(ra) # 800025ae <sleep>
  while (lk->locked) {
    800048c6:	409c                	lw	a5,0(s1)
    800048c8:	fbed                	bnez	a5,800048ba <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048ca:	4785                	li	a5,1
    800048cc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048ce:	ffffd097          	auipc	ra,0xffffd
    800048d2:	206080e7          	jalr	518(ra) # 80001ad4 <myproc>
    800048d6:	453c                	lw	a5,72(a0)
    800048d8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048da:	854a                	mv	a0,s2
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	3bc080e7          	jalr	956(ra) # 80000c98 <release>
}
    800048e4:	60e2                	ld	ra,24(sp)
    800048e6:	6442                	ld	s0,16(sp)
    800048e8:	64a2                	ld	s1,8(sp)
    800048ea:	6902                	ld	s2,0(sp)
    800048ec:	6105                	addi	sp,sp,32
    800048ee:	8082                	ret

00000000800048f0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048f0:	1101                	addi	sp,sp,-32
    800048f2:	ec06                	sd	ra,24(sp)
    800048f4:	e822                	sd	s0,16(sp)
    800048f6:	e426                	sd	s1,8(sp)
    800048f8:	e04a                	sd	s2,0(sp)
    800048fa:	1000                	addi	s0,sp,32
    800048fc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048fe:	00850913          	addi	s2,a0,8
    80004902:	854a                	mv	a0,s2
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	2e0080e7          	jalr	736(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000490c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004910:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004914:	8526                	mv	a0,s1
    80004916:	ffffe097          	auipc	ra,0xffffe
    8000491a:	e24080e7          	jalr	-476(ra) # 8000273a <wakeup>
  release(&lk->lk);
    8000491e:	854a                	mv	a0,s2
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	378080e7          	jalr	888(ra) # 80000c98 <release>
}
    80004928:	60e2                	ld	ra,24(sp)
    8000492a:	6442                	ld	s0,16(sp)
    8000492c:	64a2                	ld	s1,8(sp)
    8000492e:	6902                	ld	s2,0(sp)
    80004930:	6105                	addi	sp,sp,32
    80004932:	8082                	ret

0000000080004934 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004934:	7179                	addi	sp,sp,-48
    80004936:	f406                	sd	ra,40(sp)
    80004938:	f022                	sd	s0,32(sp)
    8000493a:	ec26                	sd	s1,24(sp)
    8000493c:	e84a                	sd	s2,16(sp)
    8000493e:	e44e                	sd	s3,8(sp)
    80004940:	1800                	addi	s0,sp,48
    80004942:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004944:	00850913          	addi	s2,a0,8
    80004948:	854a                	mv	a0,s2
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	29a080e7          	jalr	666(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004952:	409c                	lw	a5,0(s1)
    80004954:	ef99                	bnez	a5,80004972 <holdingsleep+0x3e>
    80004956:	4481                	li	s1,0
  release(&lk->lk);
    80004958:	854a                	mv	a0,s2
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	33e080e7          	jalr	830(ra) # 80000c98 <release>
  return r;
}
    80004962:	8526                	mv	a0,s1
    80004964:	70a2                	ld	ra,40(sp)
    80004966:	7402                	ld	s0,32(sp)
    80004968:	64e2                	ld	s1,24(sp)
    8000496a:	6942                	ld	s2,16(sp)
    8000496c:	69a2                	ld	s3,8(sp)
    8000496e:	6145                	addi	sp,sp,48
    80004970:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004972:	0284a983          	lw	s3,40(s1)
    80004976:	ffffd097          	auipc	ra,0xffffd
    8000497a:	15e080e7          	jalr	350(ra) # 80001ad4 <myproc>
    8000497e:	4524                	lw	s1,72(a0)
    80004980:	413484b3          	sub	s1,s1,s3
    80004984:	0014b493          	seqz	s1,s1
    80004988:	bfc1                	j	80004958 <holdingsleep+0x24>

000000008000498a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000498a:	1141                	addi	sp,sp,-16
    8000498c:	e406                	sd	ra,8(sp)
    8000498e:	e022                	sd	s0,0(sp)
    80004990:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004992:	00004597          	auipc	a1,0x4
    80004996:	d4658593          	addi	a1,a1,-698 # 800086d8 <syscalls+0x248>
    8000499a:	00016517          	auipc	a0,0x16
    8000499e:	b9e50513          	addi	a0,a0,-1122 # 8001a538 <ftable>
    800049a2:	ffffc097          	auipc	ra,0xffffc
    800049a6:	1b2080e7          	jalr	434(ra) # 80000b54 <initlock>
}
    800049aa:	60a2                	ld	ra,8(sp)
    800049ac:	6402                	ld	s0,0(sp)
    800049ae:	0141                	addi	sp,sp,16
    800049b0:	8082                	ret

00000000800049b2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049b2:	1101                	addi	sp,sp,-32
    800049b4:	ec06                	sd	ra,24(sp)
    800049b6:	e822                	sd	s0,16(sp)
    800049b8:	e426                	sd	s1,8(sp)
    800049ba:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049bc:	00016517          	auipc	a0,0x16
    800049c0:	b7c50513          	addi	a0,a0,-1156 # 8001a538 <ftable>
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	220080e7          	jalr	544(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049cc:	00016497          	auipc	s1,0x16
    800049d0:	b8448493          	addi	s1,s1,-1148 # 8001a550 <ftable+0x18>
    800049d4:	00017717          	auipc	a4,0x17
    800049d8:	b1c70713          	addi	a4,a4,-1252 # 8001b4f0 <ftable+0xfb8>
    if(f->ref == 0){
    800049dc:	40dc                	lw	a5,4(s1)
    800049de:	cf99                	beqz	a5,800049fc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049e0:	02848493          	addi	s1,s1,40
    800049e4:	fee49ce3          	bne	s1,a4,800049dc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049e8:	00016517          	auipc	a0,0x16
    800049ec:	b5050513          	addi	a0,a0,-1200 # 8001a538 <ftable>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	2a8080e7          	jalr	680(ra) # 80000c98 <release>
  return 0;
    800049f8:	4481                	li	s1,0
    800049fa:	a819                	j	80004a10 <filealloc+0x5e>
      f->ref = 1;
    800049fc:	4785                	li	a5,1
    800049fe:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a00:	00016517          	auipc	a0,0x16
    80004a04:	b3850513          	addi	a0,a0,-1224 # 8001a538 <ftable>
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	290080e7          	jalr	656(ra) # 80000c98 <release>
}
    80004a10:	8526                	mv	a0,s1
    80004a12:	60e2                	ld	ra,24(sp)
    80004a14:	6442                	ld	s0,16(sp)
    80004a16:	64a2                	ld	s1,8(sp)
    80004a18:	6105                	addi	sp,sp,32
    80004a1a:	8082                	ret

0000000080004a1c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a1c:	1101                	addi	sp,sp,-32
    80004a1e:	ec06                	sd	ra,24(sp)
    80004a20:	e822                	sd	s0,16(sp)
    80004a22:	e426                	sd	s1,8(sp)
    80004a24:	1000                	addi	s0,sp,32
    80004a26:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a28:	00016517          	auipc	a0,0x16
    80004a2c:	b1050513          	addi	a0,a0,-1264 # 8001a538 <ftable>
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	1b4080e7          	jalr	436(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a38:	40dc                	lw	a5,4(s1)
    80004a3a:	02f05263          	blez	a5,80004a5e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a3e:	2785                	addiw	a5,a5,1
    80004a40:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a42:	00016517          	auipc	a0,0x16
    80004a46:	af650513          	addi	a0,a0,-1290 # 8001a538 <ftable>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
  return f;
}
    80004a52:	8526                	mv	a0,s1
    80004a54:	60e2                	ld	ra,24(sp)
    80004a56:	6442                	ld	s0,16(sp)
    80004a58:	64a2                	ld	s1,8(sp)
    80004a5a:	6105                	addi	sp,sp,32
    80004a5c:	8082                	ret
    panic("filedup");
    80004a5e:	00004517          	auipc	a0,0x4
    80004a62:	c8250513          	addi	a0,a0,-894 # 800086e0 <syscalls+0x250>
    80004a66:	ffffc097          	auipc	ra,0xffffc
    80004a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080004a6e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a6e:	7139                	addi	sp,sp,-64
    80004a70:	fc06                	sd	ra,56(sp)
    80004a72:	f822                	sd	s0,48(sp)
    80004a74:	f426                	sd	s1,40(sp)
    80004a76:	f04a                	sd	s2,32(sp)
    80004a78:	ec4e                	sd	s3,24(sp)
    80004a7a:	e852                	sd	s4,16(sp)
    80004a7c:	e456                	sd	s5,8(sp)
    80004a7e:	0080                	addi	s0,sp,64
    80004a80:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a82:	00016517          	auipc	a0,0x16
    80004a86:	ab650513          	addi	a0,a0,-1354 # 8001a538 <ftable>
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	15a080e7          	jalr	346(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a92:	40dc                	lw	a5,4(s1)
    80004a94:	06f05163          	blez	a5,80004af6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a98:	37fd                	addiw	a5,a5,-1
    80004a9a:	0007871b          	sext.w	a4,a5
    80004a9e:	c0dc                	sw	a5,4(s1)
    80004aa0:	06e04363          	bgtz	a4,80004b06 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004aa4:	0004a903          	lw	s2,0(s1)
    80004aa8:	0094ca83          	lbu	s5,9(s1)
    80004aac:	0104ba03          	ld	s4,16(s1)
    80004ab0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ab4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ab8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004abc:	00016517          	auipc	a0,0x16
    80004ac0:	a7c50513          	addi	a0,a0,-1412 # 8001a538 <ftable>
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	1d4080e7          	jalr	468(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004acc:	4785                	li	a5,1
    80004ace:	04f90d63          	beq	s2,a5,80004b28 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ad2:	3979                	addiw	s2,s2,-2
    80004ad4:	4785                	li	a5,1
    80004ad6:	0527e063          	bltu	a5,s2,80004b16 <fileclose+0xa8>
    begin_op();
    80004ada:	00000097          	auipc	ra,0x0
    80004ade:	ac8080e7          	jalr	-1336(ra) # 800045a2 <begin_op>
    iput(ff.ip);
    80004ae2:	854e                	mv	a0,s3
    80004ae4:	fffff097          	auipc	ra,0xfffff
    80004ae8:	2a6080e7          	jalr	678(ra) # 80003d8a <iput>
    end_op();
    80004aec:	00000097          	auipc	ra,0x0
    80004af0:	b36080e7          	jalr	-1226(ra) # 80004622 <end_op>
    80004af4:	a00d                	j	80004b16 <fileclose+0xa8>
    panic("fileclose");
    80004af6:	00004517          	auipc	a0,0x4
    80004afa:	bf250513          	addi	a0,a0,-1038 # 800086e8 <syscalls+0x258>
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	a40080e7          	jalr	-1472(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b06:	00016517          	auipc	a0,0x16
    80004b0a:	a3250513          	addi	a0,a0,-1486 # 8001a538 <ftable>
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	18a080e7          	jalr	394(ra) # 80000c98 <release>
  }
}
    80004b16:	70e2                	ld	ra,56(sp)
    80004b18:	7442                	ld	s0,48(sp)
    80004b1a:	74a2                	ld	s1,40(sp)
    80004b1c:	7902                	ld	s2,32(sp)
    80004b1e:	69e2                	ld	s3,24(sp)
    80004b20:	6a42                	ld	s4,16(sp)
    80004b22:	6aa2                	ld	s5,8(sp)
    80004b24:	6121                	addi	sp,sp,64
    80004b26:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b28:	85d6                	mv	a1,s5
    80004b2a:	8552                	mv	a0,s4
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	34c080e7          	jalr	844(ra) # 80004e78 <pipeclose>
    80004b34:	b7cd                	j	80004b16 <fileclose+0xa8>

0000000080004b36 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b36:	715d                	addi	sp,sp,-80
    80004b38:	e486                	sd	ra,72(sp)
    80004b3a:	e0a2                	sd	s0,64(sp)
    80004b3c:	fc26                	sd	s1,56(sp)
    80004b3e:	f84a                	sd	s2,48(sp)
    80004b40:	f44e                	sd	s3,40(sp)
    80004b42:	0880                	addi	s0,sp,80
    80004b44:	84aa                	mv	s1,a0
    80004b46:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	f8c080e7          	jalr	-116(ra) # 80001ad4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b50:	409c                	lw	a5,0(s1)
    80004b52:	37f9                	addiw	a5,a5,-2
    80004b54:	4705                	li	a4,1
    80004b56:	04f76763          	bltu	a4,a5,80004ba4 <filestat+0x6e>
    80004b5a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b5c:	6c88                	ld	a0,24(s1)
    80004b5e:	fffff097          	auipc	ra,0xfffff
    80004b62:	072080e7          	jalr	114(ra) # 80003bd0 <ilock>
    stati(f->ip, &st);
    80004b66:	fb840593          	addi	a1,s0,-72
    80004b6a:	6c88                	ld	a0,24(s1)
    80004b6c:	fffff097          	auipc	ra,0xfffff
    80004b70:	2ee080e7          	jalr	750(ra) # 80003e5a <stati>
    iunlock(f->ip);
    80004b74:	6c88                	ld	a0,24(s1)
    80004b76:	fffff097          	auipc	ra,0xfffff
    80004b7a:	11c080e7          	jalr	284(ra) # 80003c92 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b7e:	46e1                	li	a3,24
    80004b80:	fb840613          	addi	a2,s0,-72
    80004b84:	85ce                	mv	a1,s3
    80004b86:	06893503          	ld	a0,104(s2)
    80004b8a:	ffffd097          	auipc	ra,0xffffd
    80004b8e:	c0c080e7          	jalr	-1012(ra) # 80001796 <copyout>
    80004b92:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b96:	60a6                	ld	ra,72(sp)
    80004b98:	6406                	ld	s0,64(sp)
    80004b9a:	74e2                	ld	s1,56(sp)
    80004b9c:	7942                	ld	s2,48(sp)
    80004b9e:	79a2                	ld	s3,40(sp)
    80004ba0:	6161                	addi	sp,sp,80
    80004ba2:	8082                	ret
  return -1;
    80004ba4:	557d                	li	a0,-1
    80004ba6:	bfc5                	j	80004b96 <filestat+0x60>

0000000080004ba8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ba8:	7179                	addi	sp,sp,-48
    80004baa:	f406                	sd	ra,40(sp)
    80004bac:	f022                	sd	s0,32(sp)
    80004bae:	ec26                	sd	s1,24(sp)
    80004bb0:	e84a                	sd	s2,16(sp)
    80004bb2:	e44e                	sd	s3,8(sp)
    80004bb4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bb6:	00854783          	lbu	a5,8(a0)
    80004bba:	c3d5                	beqz	a5,80004c5e <fileread+0xb6>
    80004bbc:	84aa                	mv	s1,a0
    80004bbe:	89ae                	mv	s3,a1
    80004bc0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bc2:	411c                	lw	a5,0(a0)
    80004bc4:	4705                	li	a4,1
    80004bc6:	04e78963          	beq	a5,a4,80004c18 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bca:	470d                	li	a4,3
    80004bcc:	04e78d63          	beq	a5,a4,80004c26 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bd0:	4709                	li	a4,2
    80004bd2:	06e79e63          	bne	a5,a4,80004c4e <fileread+0xa6>
    ilock(f->ip);
    80004bd6:	6d08                	ld	a0,24(a0)
    80004bd8:	fffff097          	auipc	ra,0xfffff
    80004bdc:	ff8080e7          	jalr	-8(ra) # 80003bd0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004be0:	874a                	mv	a4,s2
    80004be2:	5094                	lw	a3,32(s1)
    80004be4:	864e                	mv	a2,s3
    80004be6:	4585                	li	a1,1
    80004be8:	6c88                	ld	a0,24(s1)
    80004bea:	fffff097          	auipc	ra,0xfffff
    80004bee:	29a080e7          	jalr	666(ra) # 80003e84 <readi>
    80004bf2:	892a                	mv	s2,a0
    80004bf4:	00a05563          	blez	a0,80004bfe <fileread+0x56>
      f->off += r;
    80004bf8:	509c                	lw	a5,32(s1)
    80004bfa:	9fa9                	addw	a5,a5,a0
    80004bfc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bfe:	6c88                	ld	a0,24(s1)
    80004c00:	fffff097          	auipc	ra,0xfffff
    80004c04:	092080e7          	jalr	146(ra) # 80003c92 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c08:	854a                	mv	a0,s2
    80004c0a:	70a2                	ld	ra,40(sp)
    80004c0c:	7402                	ld	s0,32(sp)
    80004c0e:	64e2                	ld	s1,24(sp)
    80004c10:	6942                	ld	s2,16(sp)
    80004c12:	69a2                	ld	s3,8(sp)
    80004c14:	6145                	addi	sp,sp,48
    80004c16:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c18:	6908                	ld	a0,16(a0)
    80004c1a:	00000097          	auipc	ra,0x0
    80004c1e:	3c8080e7          	jalr	968(ra) # 80004fe2 <piperead>
    80004c22:	892a                	mv	s2,a0
    80004c24:	b7d5                	j	80004c08 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c26:	02451783          	lh	a5,36(a0)
    80004c2a:	03079693          	slli	a3,a5,0x30
    80004c2e:	92c1                	srli	a3,a3,0x30
    80004c30:	4725                	li	a4,9
    80004c32:	02d76863          	bltu	a4,a3,80004c62 <fileread+0xba>
    80004c36:	0792                	slli	a5,a5,0x4
    80004c38:	00016717          	auipc	a4,0x16
    80004c3c:	86070713          	addi	a4,a4,-1952 # 8001a498 <devsw>
    80004c40:	97ba                	add	a5,a5,a4
    80004c42:	639c                	ld	a5,0(a5)
    80004c44:	c38d                	beqz	a5,80004c66 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c46:	4505                	li	a0,1
    80004c48:	9782                	jalr	a5
    80004c4a:	892a                	mv	s2,a0
    80004c4c:	bf75                	j	80004c08 <fileread+0x60>
    panic("fileread");
    80004c4e:	00004517          	auipc	a0,0x4
    80004c52:	aaa50513          	addi	a0,a0,-1366 # 800086f8 <syscalls+0x268>
    80004c56:	ffffc097          	auipc	ra,0xffffc
    80004c5a:	8e8080e7          	jalr	-1816(ra) # 8000053e <panic>
    return -1;
    80004c5e:	597d                	li	s2,-1
    80004c60:	b765                	j	80004c08 <fileread+0x60>
      return -1;
    80004c62:	597d                	li	s2,-1
    80004c64:	b755                	j	80004c08 <fileread+0x60>
    80004c66:	597d                	li	s2,-1
    80004c68:	b745                	j	80004c08 <fileread+0x60>

0000000080004c6a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c6a:	715d                	addi	sp,sp,-80
    80004c6c:	e486                	sd	ra,72(sp)
    80004c6e:	e0a2                	sd	s0,64(sp)
    80004c70:	fc26                	sd	s1,56(sp)
    80004c72:	f84a                	sd	s2,48(sp)
    80004c74:	f44e                	sd	s3,40(sp)
    80004c76:	f052                	sd	s4,32(sp)
    80004c78:	ec56                	sd	s5,24(sp)
    80004c7a:	e85a                	sd	s6,16(sp)
    80004c7c:	e45e                	sd	s7,8(sp)
    80004c7e:	e062                	sd	s8,0(sp)
    80004c80:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c82:	00954783          	lbu	a5,9(a0)
    80004c86:	10078663          	beqz	a5,80004d92 <filewrite+0x128>
    80004c8a:	892a                	mv	s2,a0
    80004c8c:	8aae                	mv	s5,a1
    80004c8e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c90:	411c                	lw	a5,0(a0)
    80004c92:	4705                	li	a4,1
    80004c94:	02e78263          	beq	a5,a4,80004cb8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c98:	470d                	li	a4,3
    80004c9a:	02e78663          	beq	a5,a4,80004cc6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c9e:	4709                	li	a4,2
    80004ca0:	0ee79163          	bne	a5,a4,80004d82 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ca4:	0ac05d63          	blez	a2,80004d5e <filewrite+0xf4>
    int i = 0;
    80004ca8:	4981                	li	s3,0
    80004caa:	6b05                	lui	s6,0x1
    80004cac:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004cb0:	6b85                	lui	s7,0x1
    80004cb2:	c00b8b9b          	addiw	s7,s7,-1024
    80004cb6:	a861                	j	80004d4e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cb8:	6908                	ld	a0,16(a0)
    80004cba:	00000097          	auipc	ra,0x0
    80004cbe:	22e080e7          	jalr	558(ra) # 80004ee8 <pipewrite>
    80004cc2:	8a2a                	mv	s4,a0
    80004cc4:	a045                	j	80004d64 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cc6:	02451783          	lh	a5,36(a0)
    80004cca:	03079693          	slli	a3,a5,0x30
    80004cce:	92c1                	srli	a3,a3,0x30
    80004cd0:	4725                	li	a4,9
    80004cd2:	0cd76263          	bltu	a4,a3,80004d96 <filewrite+0x12c>
    80004cd6:	0792                	slli	a5,a5,0x4
    80004cd8:	00015717          	auipc	a4,0x15
    80004cdc:	7c070713          	addi	a4,a4,1984 # 8001a498 <devsw>
    80004ce0:	97ba                	add	a5,a5,a4
    80004ce2:	679c                	ld	a5,8(a5)
    80004ce4:	cbdd                	beqz	a5,80004d9a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ce6:	4505                	li	a0,1
    80004ce8:	9782                	jalr	a5
    80004cea:	8a2a                	mv	s4,a0
    80004cec:	a8a5                	j	80004d64 <filewrite+0xfa>
    80004cee:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cf2:	00000097          	auipc	ra,0x0
    80004cf6:	8b0080e7          	jalr	-1872(ra) # 800045a2 <begin_op>
      ilock(f->ip);
    80004cfa:	01893503          	ld	a0,24(s2)
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	ed2080e7          	jalr	-302(ra) # 80003bd0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d06:	8762                	mv	a4,s8
    80004d08:	02092683          	lw	a3,32(s2)
    80004d0c:	01598633          	add	a2,s3,s5
    80004d10:	4585                	li	a1,1
    80004d12:	01893503          	ld	a0,24(s2)
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	266080e7          	jalr	614(ra) # 80003f7c <writei>
    80004d1e:	84aa                	mv	s1,a0
    80004d20:	00a05763          	blez	a0,80004d2e <filewrite+0xc4>
        f->off += r;
    80004d24:	02092783          	lw	a5,32(s2)
    80004d28:	9fa9                	addw	a5,a5,a0
    80004d2a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d2e:	01893503          	ld	a0,24(s2)
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	f60080e7          	jalr	-160(ra) # 80003c92 <iunlock>
      end_op();
    80004d3a:	00000097          	auipc	ra,0x0
    80004d3e:	8e8080e7          	jalr	-1816(ra) # 80004622 <end_op>

      if(r != n1){
    80004d42:	009c1f63          	bne	s8,s1,80004d60 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d46:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d4a:	0149db63          	bge	s3,s4,80004d60 <filewrite+0xf6>
      int n1 = n - i;
    80004d4e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d52:	84be                	mv	s1,a5
    80004d54:	2781                	sext.w	a5,a5
    80004d56:	f8fb5ce3          	bge	s6,a5,80004cee <filewrite+0x84>
    80004d5a:	84de                	mv	s1,s7
    80004d5c:	bf49                	j	80004cee <filewrite+0x84>
    int i = 0;
    80004d5e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d60:	013a1f63          	bne	s4,s3,80004d7e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d64:	8552                	mv	a0,s4
    80004d66:	60a6                	ld	ra,72(sp)
    80004d68:	6406                	ld	s0,64(sp)
    80004d6a:	74e2                	ld	s1,56(sp)
    80004d6c:	7942                	ld	s2,48(sp)
    80004d6e:	79a2                	ld	s3,40(sp)
    80004d70:	7a02                	ld	s4,32(sp)
    80004d72:	6ae2                	ld	s5,24(sp)
    80004d74:	6b42                	ld	s6,16(sp)
    80004d76:	6ba2                	ld	s7,8(sp)
    80004d78:	6c02                	ld	s8,0(sp)
    80004d7a:	6161                	addi	sp,sp,80
    80004d7c:	8082                	ret
    ret = (i == n ? n : -1);
    80004d7e:	5a7d                	li	s4,-1
    80004d80:	b7d5                	j	80004d64 <filewrite+0xfa>
    panic("filewrite");
    80004d82:	00004517          	auipc	a0,0x4
    80004d86:	98650513          	addi	a0,a0,-1658 # 80008708 <syscalls+0x278>
    80004d8a:	ffffb097          	auipc	ra,0xffffb
    80004d8e:	7b4080e7          	jalr	1972(ra) # 8000053e <panic>
    return -1;
    80004d92:	5a7d                	li	s4,-1
    80004d94:	bfc1                	j	80004d64 <filewrite+0xfa>
      return -1;
    80004d96:	5a7d                	li	s4,-1
    80004d98:	b7f1                	j	80004d64 <filewrite+0xfa>
    80004d9a:	5a7d                	li	s4,-1
    80004d9c:	b7e1                	j	80004d64 <filewrite+0xfa>

0000000080004d9e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d9e:	7179                	addi	sp,sp,-48
    80004da0:	f406                	sd	ra,40(sp)
    80004da2:	f022                	sd	s0,32(sp)
    80004da4:	ec26                	sd	s1,24(sp)
    80004da6:	e84a                	sd	s2,16(sp)
    80004da8:	e44e                	sd	s3,8(sp)
    80004daa:	e052                	sd	s4,0(sp)
    80004dac:	1800                	addi	s0,sp,48
    80004dae:	84aa                	mv	s1,a0
    80004db0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004db2:	0005b023          	sd	zero,0(a1)
    80004db6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dba:	00000097          	auipc	ra,0x0
    80004dbe:	bf8080e7          	jalr	-1032(ra) # 800049b2 <filealloc>
    80004dc2:	e088                	sd	a0,0(s1)
    80004dc4:	c551                	beqz	a0,80004e50 <pipealloc+0xb2>
    80004dc6:	00000097          	auipc	ra,0x0
    80004dca:	bec080e7          	jalr	-1044(ra) # 800049b2 <filealloc>
    80004dce:	00aa3023          	sd	a0,0(s4)
    80004dd2:	c92d                	beqz	a0,80004e44 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004dd4:	ffffc097          	auipc	ra,0xffffc
    80004dd8:	d20080e7          	jalr	-736(ra) # 80000af4 <kalloc>
    80004ddc:	892a                	mv	s2,a0
    80004dde:	c125                	beqz	a0,80004e3e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004de0:	4985                	li	s3,1
    80004de2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004de6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004dea:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004dee:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004df2:	00004597          	auipc	a1,0x4
    80004df6:	92658593          	addi	a1,a1,-1754 # 80008718 <syscalls+0x288>
    80004dfa:	ffffc097          	auipc	ra,0xffffc
    80004dfe:	d5a080e7          	jalr	-678(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e02:	609c                	ld	a5,0(s1)
    80004e04:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e08:	609c                	ld	a5,0(s1)
    80004e0a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e0e:	609c                	ld	a5,0(s1)
    80004e10:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e14:	609c                	ld	a5,0(s1)
    80004e16:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e1a:	000a3783          	ld	a5,0(s4)
    80004e1e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e22:	000a3783          	ld	a5,0(s4)
    80004e26:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e2a:	000a3783          	ld	a5,0(s4)
    80004e2e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e32:	000a3783          	ld	a5,0(s4)
    80004e36:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e3a:	4501                	li	a0,0
    80004e3c:	a025                	j	80004e64 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e3e:	6088                	ld	a0,0(s1)
    80004e40:	e501                	bnez	a0,80004e48 <pipealloc+0xaa>
    80004e42:	a039                	j	80004e50 <pipealloc+0xb2>
    80004e44:	6088                	ld	a0,0(s1)
    80004e46:	c51d                	beqz	a0,80004e74 <pipealloc+0xd6>
    fileclose(*f0);
    80004e48:	00000097          	auipc	ra,0x0
    80004e4c:	c26080e7          	jalr	-986(ra) # 80004a6e <fileclose>
  if(*f1)
    80004e50:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e54:	557d                	li	a0,-1
  if(*f1)
    80004e56:	c799                	beqz	a5,80004e64 <pipealloc+0xc6>
    fileclose(*f1);
    80004e58:	853e                	mv	a0,a5
    80004e5a:	00000097          	auipc	ra,0x0
    80004e5e:	c14080e7          	jalr	-1004(ra) # 80004a6e <fileclose>
  return -1;
    80004e62:	557d                	li	a0,-1
}
    80004e64:	70a2                	ld	ra,40(sp)
    80004e66:	7402                	ld	s0,32(sp)
    80004e68:	64e2                	ld	s1,24(sp)
    80004e6a:	6942                	ld	s2,16(sp)
    80004e6c:	69a2                	ld	s3,8(sp)
    80004e6e:	6a02                	ld	s4,0(sp)
    80004e70:	6145                	addi	sp,sp,48
    80004e72:	8082                	ret
  return -1;
    80004e74:	557d                	li	a0,-1
    80004e76:	b7fd                	j	80004e64 <pipealloc+0xc6>

0000000080004e78 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e78:	1101                	addi	sp,sp,-32
    80004e7a:	ec06                	sd	ra,24(sp)
    80004e7c:	e822                	sd	s0,16(sp)
    80004e7e:	e426                	sd	s1,8(sp)
    80004e80:	e04a                	sd	s2,0(sp)
    80004e82:	1000                	addi	s0,sp,32
    80004e84:	84aa                	mv	s1,a0
    80004e86:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	d5c080e7          	jalr	-676(ra) # 80000be4 <acquire>
  if(writable){
    80004e90:	02090d63          	beqz	s2,80004eca <pipeclose+0x52>
    pi->writeopen = 0;
    80004e94:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e98:	21848513          	addi	a0,s1,536
    80004e9c:	ffffe097          	auipc	ra,0xffffe
    80004ea0:	89e080e7          	jalr	-1890(ra) # 8000273a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ea4:	2204b783          	ld	a5,544(s1)
    80004ea8:	eb95                	bnez	a5,80004edc <pipeclose+0x64>
    release(&pi->lock);
    80004eaa:	8526                	mv	a0,s1
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	dec080e7          	jalr	-532(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	b42080e7          	jalr	-1214(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004ebe:	60e2                	ld	ra,24(sp)
    80004ec0:	6442                	ld	s0,16(sp)
    80004ec2:	64a2                	ld	s1,8(sp)
    80004ec4:	6902                	ld	s2,0(sp)
    80004ec6:	6105                	addi	sp,sp,32
    80004ec8:	8082                	ret
    pi->readopen = 0;
    80004eca:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ece:	21c48513          	addi	a0,s1,540
    80004ed2:	ffffe097          	auipc	ra,0xffffe
    80004ed6:	868080e7          	jalr	-1944(ra) # 8000273a <wakeup>
    80004eda:	b7e9                	j	80004ea4 <pipeclose+0x2c>
    release(&pi->lock);
    80004edc:	8526                	mv	a0,s1
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	dba080e7          	jalr	-582(ra) # 80000c98 <release>
}
    80004ee6:	bfe1                	j	80004ebe <pipeclose+0x46>

0000000080004ee8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ee8:	7159                	addi	sp,sp,-112
    80004eea:	f486                	sd	ra,104(sp)
    80004eec:	f0a2                	sd	s0,96(sp)
    80004eee:	eca6                	sd	s1,88(sp)
    80004ef0:	e8ca                	sd	s2,80(sp)
    80004ef2:	e4ce                	sd	s3,72(sp)
    80004ef4:	e0d2                	sd	s4,64(sp)
    80004ef6:	fc56                	sd	s5,56(sp)
    80004ef8:	f85a                	sd	s6,48(sp)
    80004efa:	f45e                	sd	s7,40(sp)
    80004efc:	f062                	sd	s8,32(sp)
    80004efe:	ec66                	sd	s9,24(sp)
    80004f00:	1880                	addi	s0,sp,112
    80004f02:	84aa                	mv	s1,a0
    80004f04:	8aae                	mv	s5,a1
    80004f06:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f08:	ffffd097          	auipc	ra,0xffffd
    80004f0c:	bcc080e7          	jalr	-1076(ra) # 80001ad4 <myproc>
    80004f10:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f12:	8526                	mv	a0,s1
    80004f14:	ffffc097          	auipc	ra,0xffffc
    80004f18:	cd0080e7          	jalr	-816(ra) # 80000be4 <acquire>
  while(i < n){
    80004f1c:	0d405163          	blez	s4,80004fde <pipewrite+0xf6>
    80004f20:	8ba6                	mv	s7,s1
  int i = 0;
    80004f22:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f24:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f26:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f2a:	21c48c13          	addi	s8,s1,540
    80004f2e:	a08d                	j	80004f90 <pipewrite+0xa8>
      release(&pi->lock);
    80004f30:	8526                	mv	a0,s1
    80004f32:	ffffc097          	auipc	ra,0xffffc
    80004f36:	d66080e7          	jalr	-666(ra) # 80000c98 <release>
      return -1;
    80004f3a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f3c:	854a                	mv	a0,s2
    80004f3e:	70a6                	ld	ra,104(sp)
    80004f40:	7406                	ld	s0,96(sp)
    80004f42:	64e6                	ld	s1,88(sp)
    80004f44:	6946                	ld	s2,80(sp)
    80004f46:	69a6                	ld	s3,72(sp)
    80004f48:	6a06                	ld	s4,64(sp)
    80004f4a:	7ae2                	ld	s5,56(sp)
    80004f4c:	7b42                	ld	s6,48(sp)
    80004f4e:	7ba2                	ld	s7,40(sp)
    80004f50:	7c02                	ld	s8,32(sp)
    80004f52:	6ce2                	ld	s9,24(sp)
    80004f54:	6165                	addi	sp,sp,112
    80004f56:	8082                	ret
      wakeup(&pi->nread);
    80004f58:	8566                	mv	a0,s9
    80004f5a:	ffffd097          	auipc	ra,0xffffd
    80004f5e:	7e0080e7          	jalr	2016(ra) # 8000273a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f62:	85de                	mv	a1,s7
    80004f64:	8562                	mv	a0,s8
    80004f66:	ffffd097          	auipc	ra,0xffffd
    80004f6a:	648080e7          	jalr	1608(ra) # 800025ae <sleep>
    80004f6e:	a839                	j	80004f8c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f70:	21c4a783          	lw	a5,540(s1)
    80004f74:	0017871b          	addiw	a4,a5,1
    80004f78:	20e4ae23          	sw	a4,540(s1)
    80004f7c:	1ff7f793          	andi	a5,a5,511
    80004f80:	97a6                	add	a5,a5,s1
    80004f82:	f9f44703          	lbu	a4,-97(s0)
    80004f86:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f8a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f8c:	03495d63          	bge	s2,s4,80004fc6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f90:	2204a783          	lw	a5,544(s1)
    80004f94:	dfd1                	beqz	a5,80004f30 <pipewrite+0x48>
    80004f96:	0409a783          	lw	a5,64(s3)
    80004f9a:	fbd9                	bnez	a5,80004f30 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f9c:	2184a783          	lw	a5,536(s1)
    80004fa0:	21c4a703          	lw	a4,540(s1)
    80004fa4:	2007879b          	addiw	a5,a5,512
    80004fa8:	faf708e3          	beq	a4,a5,80004f58 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fac:	4685                	li	a3,1
    80004fae:	01590633          	add	a2,s2,s5
    80004fb2:	f9f40593          	addi	a1,s0,-97
    80004fb6:	0689b503          	ld	a0,104(s3)
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	868080e7          	jalr	-1944(ra) # 80001822 <copyin>
    80004fc2:	fb6517e3          	bne	a0,s6,80004f70 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004fc6:	21848513          	addi	a0,s1,536
    80004fca:	ffffd097          	auipc	ra,0xffffd
    80004fce:	770080e7          	jalr	1904(ra) # 8000273a <wakeup>
  release(&pi->lock);
    80004fd2:	8526                	mv	a0,s1
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	cc4080e7          	jalr	-828(ra) # 80000c98 <release>
  return i;
    80004fdc:	b785                	j	80004f3c <pipewrite+0x54>
  int i = 0;
    80004fde:	4901                	li	s2,0
    80004fe0:	b7dd                	j	80004fc6 <pipewrite+0xde>

0000000080004fe2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fe2:	715d                	addi	sp,sp,-80
    80004fe4:	e486                	sd	ra,72(sp)
    80004fe6:	e0a2                	sd	s0,64(sp)
    80004fe8:	fc26                	sd	s1,56(sp)
    80004fea:	f84a                	sd	s2,48(sp)
    80004fec:	f44e                	sd	s3,40(sp)
    80004fee:	f052                	sd	s4,32(sp)
    80004ff0:	ec56                	sd	s5,24(sp)
    80004ff2:	e85a                	sd	s6,16(sp)
    80004ff4:	0880                	addi	s0,sp,80
    80004ff6:	84aa                	mv	s1,a0
    80004ff8:	892e                	mv	s2,a1
    80004ffa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ffc:	ffffd097          	auipc	ra,0xffffd
    80005000:	ad8080e7          	jalr	-1320(ra) # 80001ad4 <myproc>
    80005004:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005006:	8b26                	mv	s6,s1
    80005008:	8526                	mv	a0,s1
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	bda080e7          	jalr	-1062(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005012:	2184a703          	lw	a4,536(s1)
    80005016:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000501a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000501e:	02f71463          	bne	a4,a5,80005046 <piperead+0x64>
    80005022:	2244a783          	lw	a5,548(s1)
    80005026:	c385                	beqz	a5,80005046 <piperead+0x64>
    if(pr->killed){
    80005028:	040a2783          	lw	a5,64(s4)
    8000502c:	ebc1                	bnez	a5,800050bc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000502e:	85da                	mv	a1,s6
    80005030:	854e                	mv	a0,s3
    80005032:	ffffd097          	auipc	ra,0xffffd
    80005036:	57c080e7          	jalr	1404(ra) # 800025ae <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000503a:	2184a703          	lw	a4,536(s1)
    8000503e:	21c4a783          	lw	a5,540(s1)
    80005042:	fef700e3          	beq	a4,a5,80005022 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005046:	09505263          	blez	s5,800050ca <piperead+0xe8>
    8000504a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000504c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000504e:	2184a783          	lw	a5,536(s1)
    80005052:	21c4a703          	lw	a4,540(s1)
    80005056:	02f70d63          	beq	a4,a5,80005090 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000505a:	0017871b          	addiw	a4,a5,1
    8000505e:	20e4ac23          	sw	a4,536(s1)
    80005062:	1ff7f793          	andi	a5,a5,511
    80005066:	97a6                	add	a5,a5,s1
    80005068:	0187c783          	lbu	a5,24(a5)
    8000506c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005070:	4685                	li	a3,1
    80005072:	fbf40613          	addi	a2,s0,-65
    80005076:	85ca                	mv	a1,s2
    80005078:	068a3503          	ld	a0,104(s4)
    8000507c:	ffffc097          	auipc	ra,0xffffc
    80005080:	71a080e7          	jalr	1818(ra) # 80001796 <copyout>
    80005084:	01650663          	beq	a0,s6,80005090 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005088:	2985                	addiw	s3,s3,1
    8000508a:	0905                	addi	s2,s2,1
    8000508c:	fd3a91e3          	bne	s5,s3,8000504e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005090:	21c48513          	addi	a0,s1,540
    80005094:	ffffd097          	auipc	ra,0xffffd
    80005098:	6a6080e7          	jalr	1702(ra) # 8000273a <wakeup>
  release(&pi->lock);
    8000509c:	8526                	mv	a0,s1
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	bfa080e7          	jalr	-1030(ra) # 80000c98 <release>
  return i;
}
    800050a6:	854e                	mv	a0,s3
    800050a8:	60a6                	ld	ra,72(sp)
    800050aa:	6406                	ld	s0,64(sp)
    800050ac:	74e2                	ld	s1,56(sp)
    800050ae:	7942                	ld	s2,48(sp)
    800050b0:	79a2                	ld	s3,40(sp)
    800050b2:	7a02                	ld	s4,32(sp)
    800050b4:	6ae2                	ld	s5,24(sp)
    800050b6:	6b42                	ld	s6,16(sp)
    800050b8:	6161                	addi	sp,sp,80
    800050ba:	8082                	ret
      release(&pi->lock);
    800050bc:	8526                	mv	a0,s1
    800050be:	ffffc097          	auipc	ra,0xffffc
    800050c2:	bda080e7          	jalr	-1062(ra) # 80000c98 <release>
      return -1;
    800050c6:	59fd                	li	s3,-1
    800050c8:	bff9                	j	800050a6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ca:	4981                	li	s3,0
    800050cc:	b7d1                	j	80005090 <piperead+0xae>

00000000800050ce <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050ce:	df010113          	addi	sp,sp,-528
    800050d2:	20113423          	sd	ra,520(sp)
    800050d6:	20813023          	sd	s0,512(sp)
    800050da:	ffa6                	sd	s1,504(sp)
    800050dc:	fbca                	sd	s2,496(sp)
    800050de:	f7ce                	sd	s3,488(sp)
    800050e0:	f3d2                	sd	s4,480(sp)
    800050e2:	efd6                	sd	s5,472(sp)
    800050e4:	ebda                	sd	s6,464(sp)
    800050e6:	e7de                	sd	s7,456(sp)
    800050e8:	e3e2                	sd	s8,448(sp)
    800050ea:	ff66                	sd	s9,440(sp)
    800050ec:	fb6a                	sd	s10,432(sp)
    800050ee:	f76e                	sd	s11,424(sp)
    800050f0:	0c00                	addi	s0,sp,528
    800050f2:	84aa                	mv	s1,a0
    800050f4:	dea43c23          	sd	a0,-520(s0)
    800050f8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050fc:	ffffd097          	auipc	ra,0xffffd
    80005100:	9d8080e7          	jalr	-1576(ra) # 80001ad4 <myproc>
    80005104:	892a                	mv	s2,a0

  begin_op();
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	49c080e7          	jalr	1180(ra) # 800045a2 <begin_op>

  if((ip = namei(path)) == 0){
    8000510e:	8526                	mv	a0,s1
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	276080e7          	jalr	630(ra) # 80004386 <namei>
    80005118:	c92d                	beqz	a0,8000518a <exec+0xbc>
    8000511a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000511c:	fffff097          	auipc	ra,0xfffff
    80005120:	ab4080e7          	jalr	-1356(ra) # 80003bd0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005124:	04000713          	li	a4,64
    80005128:	4681                	li	a3,0
    8000512a:	e5040613          	addi	a2,s0,-432
    8000512e:	4581                	li	a1,0
    80005130:	8526                	mv	a0,s1
    80005132:	fffff097          	auipc	ra,0xfffff
    80005136:	d52080e7          	jalr	-686(ra) # 80003e84 <readi>
    8000513a:	04000793          	li	a5,64
    8000513e:	00f51a63          	bne	a0,a5,80005152 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005142:	e5042703          	lw	a4,-432(s0)
    80005146:	464c47b7          	lui	a5,0x464c4
    8000514a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000514e:	04f70463          	beq	a4,a5,80005196 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005152:	8526                	mv	a0,s1
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	cde080e7          	jalr	-802(ra) # 80003e32 <iunlockput>
    end_op();
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	4c6080e7          	jalr	1222(ra) # 80004622 <end_op>
  }
  return -1;
    80005164:	557d                	li	a0,-1
}
    80005166:	20813083          	ld	ra,520(sp)
    8000516a:	20013403          	ld	s0,512(sp)
    8000516e:	74fe                	ld	s1,504(sp)
    80005170:	795e                	ld	s2,496(sp)
    80005172:	79be                	ld	s3,488(sp)
    80005174:	7a1e                	ld	s4,480(sp)
    80005176:	6afe                	ld	s5,472(sp)
    80005178:	6b5e                	ld	s6,464(sp)
    8000517a:	6bbe                	ld	s7,456(sp)
    8000517c:	6c1e                	ld	s8,448(sp)
    8000517e:	7cfa                	ld	s9,440(sp)
    80005180:	7d5a                	ld	s10,432(sp)
    80005182:	7dba                	ld	s11,424(sp)
    80005184:	21010113          	addi	sp,sp,528
    80005188:	8082                	ret
    end_op();
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	498080e7          	jalr	1176(ra) # 80004622 <end_op>
    return -1;
    80005192:	557d                	li	a0,-1
    80005194:	bfc9                	j	80005166 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005196:	854a                	mv	a0,s2
    80005198:	ffffd097          	auipc	ra,0xffffd
    8000519c:	a00080e7          	jalr	-1536(ra) # 80001b98 <proc_pagetable>
    800051a0:	8baa                	mv	s7,a0
    800051a2:	d945                	beqz	a0,80005152 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051a4:	e7042983          	lw	s3,-400(s0)
    800051a8:	e8845783          	lhu	a5,-376(s0)
    800051ac:	c7ad                	beqz	a5,80005216 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051ae:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051b0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800051b2:	6c85                	lui	s9,0x1
    800051b4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051b8:	def43823          	sd	a5,-528(s0)
    800051bc:	a42d                	j	800053e6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051be:	00003517          	auipc	a0,0x3
    800051c2:	56250513          	addi	a0,a0,1378 # 80008720 <syscalls+0x290>
    800051c6:	ffffb097          	auipc	ra,0xffffb
    800051ca:	378080e7          	jalr	888(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051ce:	8756                	mv	a4,s5
    800051d0:	012d86bb          	addw	a3,s11,s2
    800051d4:	4581                	li	a1,0
    800051d6:	8526                	mv	a0,s1
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	cac080e7          	jalr	-852(ra) # 80003e84 <readi>
    800051e0:	2501                	sext.w	a0,a0
    800051e2:	1aaa9963          	bne	s5,a0,80005394 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800051e6:	6785                	lui	a5,0x1
    800051e8:	0127893b          	addw	s2,a5,s2
    800051ec:	77fd                	lui	a5,0xfffff
    800051ee:	01478a3b          	addw	s4,a5,s4
    800051f2:	1f897163          	bgeu	s2,s8,800053d4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051f6:	02091593          	slli	a1,s2,0x20
    800051fa:	9181                	srli	a1,a1,0x20
    800051fc:	95ea                	add	a1,a1,s10
    800051fe:	855e                	mv	a0,s7
    80005200:	ffffc097          	auipc	ra,0xffffc
    80005204:	f92080e7          	jalr	-110(ra) # 80001192 <walkaddr>
    80005208:	862a                	mv	a2,a0
    if(pa == 0)
    8000520a:	d955                	beqz	a0,800051be <exec+0xf0>
      n = PGSIZE;
    8000520c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000520e:	fd9a70e3          	bgeu	s4,s9,800051ce <exec+0x100>
      n = sz - i;
    80005212:	8ad2                	mv	s5,s4
    80005214:	bf6d                	j	800051ce <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005216:	4901                	li	s2,0
  iunlockput(ip);
    80005218:	8526                	mv	a0,s1
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	c18080e7          	jalr	-1000(ra) # 80003e32 <iunlockput>
  end_op();
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	400080e7          	jalr	1024(ra) # 80004622 <end_op>
  p = myproc();
    8000522a:	ffffd097          	auipc	ra,0xffffd
    8000522e:	8aa080e7          	jalr	-1878(ra) # 80001ad4 <myproc>
    80005232:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005234:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    80005238:	6785                	lui	a5,0x1
    8000523a:	17fd                	addi	a5,a5,-1
    8000523c:	993e                	add	s2,s2,a5
    8000523e:	757d                	lui	a0,0xfffff
    80005240:	00a977b3          	and	a5,s2,a0
    80005244:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005248:	6609                	lui	a2,0x2
    8000524a:	963e                	add	a2,a2,a5
    8000524c:	85be                	mv	a1,a5
    8000524e:	855e                	mv	a0,s7
    80005250:	ffffc097          	auipc	ra,0xffffc
    80005254:	2f6080e7          	jalr	758(ra) # 80001546 <uvmalloc>
    80005258:	8b2a                	mv	s6,a0
  ip = 0;
    8000525a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000525c:	12050c63          	beqz	a0,80005394 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005260:	75f9                	lui	a1,0xffffe
    80005262:	95aa                	add	a1,a1,a0
    80005264:	855e                	mv	a0,s7
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	4fe080e7          	jalr	1278(ra) # 80001764 <uvmclear>
  stackbase = sp - PGSIZE;
    8000526e:	7c7d                	lui	s8,0xfffff
    80005270:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005272:	e0043783          	ld	a5,-512(s0)
    80005276:	6388                	ld	a0,0(a5)
    80005278:	c535                	beqz	a0,800052e4 <exec+0x216>
    8000527a:	e9040993          	addi	s3,s0,-368
    8000527e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005282:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005284:	ffffc097          	auipc	ra,0xffffc
    80005288:	be0080e7          	jalr	-1056(ra) # 80000e64 <strlen>
    8000528c:	2505                	addiw	a0,a0,1
    8000528e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005292:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005296:	13896363          	bltu	s2,s8,800053bc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000529a:	e0043d83          	ld	s11,-512(s0)
    8000529e:	000dba03          	ld	s4,0(s11)
    800052a2:	8552                	mv	a0,s4
    800052a4:	ffffc097          	auipc	ra,0xffffc
    800052a8:	bc0080e7          	jalr	-1088(ra) # 80000e64 <strlen>
    800052ac:	0015069b          	addiw	a3,a0,1
    800052b0:	8652                	mv	a2,s4
    800052b2:	85ca                	mv	a1,s2
    800052b4:	855e                	mv	a0,s7
    800052b6:	ffffc097          	auipc	ra,0xffffc
    800052ba:	4e0080e7          	jalr	1248(ra) # 80001796 <copyout>
    800052be:	10054363          	bltz	a0,800053c4 <exec+0x2f6>
    ustack[argc] = sp;
    800052c2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052c6:	0485                	addi	s1,s1,1
    800052c8:	008d8793          	addi	a5,s11,8
    800052cc:	e0f43023          	sd	a5,-512(s0)
    800052d0:	008db503          	ld	a0,8(s11)
    800052d4:	c911                	beqz	a0,800052e8 <exec+0x21a>
    if(argc >= MAXARG)
    800052d6:	09a1                	addi	s3,s3,8
    800052d8:	fb3c96e3          	bne	s9,s3,80005284 <exec+0x1b6>
  sz = sz1;
    800052dc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052e0:	4481                	li	s1,0
    800052e2:	a84d                	j	80005394 <exec+0x2c6>
  sp = sz;
    800052e4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800052e6:	4481                	li	s1,0
  ustack[argc] = 0;
    800052e8:	00349793          	slli	a5,s1,0x3
    800052ec:	f9040713          	addi	a4,s0,-112
    800052f0:	97ba                	add	a5,a5,a4
    800052f2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800052f6:	00148693          	addi	a3,s1,1
    800052fa:	068e                	slli	a3,a3,0x3
    800052fc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005300:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005304:	01897663          	bgeu	s2,s8,80005310 <exec+0x242>
  sz = sz1;
    80005308:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000530c:	4481                	li	s1,0
    8000530e:	a059                	j	80005394 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005310:	e9040613          	addi	a2,s0,-368
    80005314:	85ca                	mv	a1,s2
    80005316:	855e                	mv	a0,s7
    80005318:	ffffc097          	auipc	ra,0xffffc
    8000531c:	47e080e7          	jalr	1150(ra) # 80001796 <copyout>
    80005320:	0a054663          	bltz	a0,800053cc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005324:	070ab783          	ld	a5,112(s5)
    80005328:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000532c:	df843783          	ld	a5,-520(s0)
    80005330:	0007c703          	lbu	a4,0(a5)
    80005334:	cf11                	beqz	a4,80005350 <exec+0x282>
    80005336:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005338:	02f00693          	li	a3,47
    8000533c:	a039                	j	8000534a <exec+0x27c>
      last = s+1;
    8000533e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005342:	0785                	addi	a5,a5,1
    80005344:	fff7c703          	lbu	a4,-1(a5)
    80005348:	c701                	beqz	a4,80005350 <exec+0x282>
    if(*s == '/')
    8000534a:	fed71ce3          	bne	a4,a3,80005342 <exec+0x274>
    8000534e:	bfc5                	j	8000533e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005350:	4641                	li	a2,16
    80005352:	df843583          	ld	a1,-520(s0)
    80005356:	170a8513          	addi	a0,s5,368
    8000535a:	ffffc097          	auipc	ra,0xffffc
    8000535e:	ad8080e7          	jalr	-1320(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005362:	068ab503          	ld	a0,104(s5)
  p->pagetable = pagetable;
    80005366:	077ab423          	sd	s7,104(s5)
  p->sz = sz;
    8000536a:	076ab023          	sd	s6,96(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000536e:	070ab783          	ld	a5,112(s5)
    80005372:	e6843703          	ld	a4,-408(s0)
    80005376:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005378:	070ab783          	ld	a5,112(s5)
    8000537c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005380:	85ea                	mv	a1,s10
    80005382:	ffffd097          	auipc	ra,0xffffd
    80005386:	8b2080e7          	jalr	-1870(ra) # 80001c34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000538a:	0004851b          	sext.w	a0,s1
    8000538e:	bbe1                	j	80005166 <exec+0x98>
    80005390:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005394:	e0843583          	ld	a1,-504(s0)
    80005398:	855e                	mv	a0,s7
    8000539a:	ffffd097          	auipc	ra,0xffffd
    8000539e:	89a080e7          	jalr	-1894(ra) # 80001c34 <proc_freepagetable>
  if(ip){
    800053a2:	da0498e3          	bnez	s1,80005152 <exec+0x84>
  return -1;
    800053a6:	557d                	li	a0,-1
    800053a8:	bb7d                	j	80005166 <exec+0x98>
    800053aa:	e1243423          	sd	s2,-504(s0)
    800053ae:	b7dd                	j	80005394 <exec+0x2c6>
    800053b0:	e1243423          	sd	s2,-504(s0)
    800053b4:	b7c5                	j	80005394 <exec+0x2c6>
    800053b6:	e1243423          	sd	s2,-504(s0)
    800053ba:	bfe9                	j	80005394 <exec+0x2c6>
  sz = sz1;
    800053bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053c0:	4481                	li	s1,0
    800053c2:	bfc9                	j	80005394 <exec+0x2c6>
  sz = sz1;
    800053c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053c8:	4481                	li	s1,0
    800053ca:	b7e9                	j	80005394 <exec+0x2c6>
  sz = sz1;
    800053cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053d0:	4481                	li	s1,0
    800053d2:	b7c9                	j	80005394 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053d4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053d8:	2b05                	addiw	s6,s6,1
    800053da:	0389899b          	addiw	s3,s3,56
    800053de:	e8845783          	lhu	a5,-376(s0)
    800053e2:	e2fb5be3          	bge	s6,a5,80005218 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053e6:	2981                	sext.w	s3,s3
    800053e8:	03800713          	li	a4,56
    800053ec:	86ce                	mv	a3,s3
    800053ee:	e1840613          	addi	a2,s0,-488
    800053f2:	4581                	li	a1,0
    800053f4:	8526                	mv	a0,s1
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	a8e080e7          	jalr	-1394(ra) # 80003e84 <readi>
    800053fe:	03800793          	li	a5,56
    80005402:	f8f517e3          	bne	a0,a5,80005390 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005406:	e1842783          	lw	a5,-488(s0)
    8000540a:	4705                	li	a4,1
    8000540c:	fce796e3          	bne	a5,a4,800053d8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005410:	e4043603          	ld	a2,-448(s0)
    80005414:	e3843783          	ld	a5,-456(s0)
    80005418:	f8f669e3          	bltu	a2,a5,800053aa <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000541c:	e2843783          	ld	a5,-472(s0)
    80005420:	963e                	add	a2,a2,a5
    80005422:	f8f667e3          	bltu	a2,a5,800053b0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005426:	85ca                	mv	a1,s2
    80005428:	855e                	mv	a0,s7
    8000542a:	ffffc097          	auipc	ra,0xffffc
    8000542e:	11c080e7          	jalr	284(ra) # 80001546 <uvmalloc>
    80005432:	e0a43423          	sd	a0,-504(s0)
    80005436:	d141                	beqz	a0,800053b6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005438:	e2843d03          	ld	s10,-472(s0)
    8000543c:	df043783          	ld	a5,-528(s0)
    80005440:	00fd77b3          	and	a5,s10,a5
    80005444:	fba1                	bnez	a5,80005394 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005446:	e2042d83          	lw	s11,-480(s0)
    8000544a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000544e:	f80c03e3          	beqz	s8,800053d4 <exec+0x306>
    80005452:	8a62                	mv	s4,s8
    80005454:	4901                	li	s2,0
    80005456:	b345                	j	800051f6 <exec+0x128>

0000000080005458 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005458:	7179                	addi	sp,sp,-48
    8000545a:	f406                	sd	ra,40(sp)
    8000545c:	f022                	sd	s0,32(sp)
    8000545e:	ec26                	sd	s1,24(sp)
    80005460:	e84a                	sd	s2,16(sp)
    80005462:	1800                	addi	s0,sp,48
    80005464:	892e                	mv	s2,a1
    80005466:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005468:	fdc40593          	addi	a1,s0,-36
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	ba8080e7          	jalr	-1112(ra) # 80003014 <argint>
    80005474:	04054063          	bltz	a0,800054b4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005478:	fdc42703          	lw	a4,-36(s0)
    8000547c:	47bd                	li	a5,15
    8000547e:	02e7ed63          	bltu	a5,a4,800054b8 <argfd+0x60>
    80005482:	ffffc097          	auipc	ra,0xffffc
    80005486:	652080e7          	jalr	1618(ra) # 80001ad4 <myproc>
    8000548a:	fdc42703          	lw	a4,-36(s0)
    8000548e:	01c70793          	addi	a5,a4,28
    80005492:	078e                	slli	a5,a5,0x3
    80005494:	953e                	add	a0,a0,a5
    80005496:	651c                	ld	a5,8(a0)
    80005498:	c395                	beqz	a5,800054bc <argfd+0x64>
    return -1;
  if(pfd)
    8000549a:	00090463          	beqz	s2,800054a2 <argfd+0x4a>
    *pfd = fd;
    8000549e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054a2:	4501                	li	a0,0
  if(pf)
    800054a4:	c091                	beqz	s1,800054a8 <argfd+0x50>
    *pf = f;
    800054a6:	e09c                	sd	a5,0(s1)
}
    800054a8:	70a2                	ld	ra,40(sp)
    800054aa:	7402                	ld	s0,32(sp)
    800054ac:	64e2                	ld	s1,24(sp)
    800054ae:	6942                	ld	s2,16(sp)
    800054b0:	6145                	addi	sp,sp,48
    800054b2:	8082                	ret
    return -1;
    800054b4:	557d                	li	a0,-1
    800054b6:	bfcd                	j	800054a8 <argfd+0x50>
    return -1;
    800054b8:	557d                	li	a0,-1
    800054ba:	b7fd                	j	800054a8 <argfd+0x50>
    800054bc:	557d                	li	a0,-1
    800054be:	b7ed                	j	800054a8 <argfd+0x50>

00000000800054c0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054c0:	1101                	addi	sp,sp,-32
    800054c2:	ec06                	sd	ra,24(sp)
    800054c4:	e822                	sd	s0,16(sp)
    800054c6:	e426                	sd	s1,8(sp)
    800054c8:	1000                	addi	s0,sp,32
    800054ca:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	608080e7          	jalr	1544(ra) # 80001ad4 <myproc>
    800054d4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054d6:	0e850793          	addi	a5,a0,232 # fffffffffffff0e8 <end+0xffffffff7ffe00e8>
    800054da:	4501                	li	a0,0
    800054dc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054de:	6398                	ld	a4,0(a5)
    800054e0:	cb19                	beqz	a4,800054f6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054e2:	2505                	addiw	a0,a0,1
    800054e4:	07a1                	addi	a5,a5,8
    800054e6:	fed51ce3          	bne	a0,a3,800054de <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054ea:	557d                	li	a0,-1
}
    800054ec:	60e2                	ld	ra,24(sp)
    800054ee:	6442                	ld	s0,16(sp)
    800054f0:	64a2                	ld	s1,8(sp)
    800054f2:	6105                	addi	sp,sp,32
    800054f4:	8082                	ret
      p->ofile[fd] = f;
    800054f6:	01c50793          	addi	a5,a0,28
    800054fa:	078e                	slli	a5,a5,0x3
    800054fc:	963e                	add	a2,a2,a5
    800054fe:	e604                	sd	s1,8(a2)
      return fd;
    80005500:	b7f5                	j	800054ec <fdalloc+0x2c>

0000000080005502 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005502:	715d                	addi	sp,sp,-80
    80005504:	e486                	sd	ra,72(sp)
    80005506:	e0a2                	sd	s0,64(sp)
    80005508:	fc26                	sd	s1,56(sp)
    8000550a:	f84a                	sd	s2,48(sp)
    8000550c:	f44e                	sd	s3,40(sp)
    8000550e:	f052                	sd	s4,32(sp)
    80005510:	ec56                	sd	s5,24(sp)
    80005512:	0880                	addi	s0,sp,80
    80005514:	89ae                	mv	s3,a1
    80005516:	8ab2                	mv	s5,a2
    80005518:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000551a:	fb040593          	addi	a1,s0,-80
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	e86080e7          	jalr	-378(ra) # 800043a4 <nameiparent>
    80005526:	892a                	mv	s2,a0
    80005528:	12050f63          	beqz	a0,80005666 <create+0x164>
    return 0;

  ilock(dp);
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	6a4080e7          	jalr	1700(ra) # 80003bd0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005534:	4601                	li	a2,0
    80005536:	fb040593          	addi	a1,s0,-80
    8000553a:	854a                	mv	a0,s2
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	b78080e7          	jalr	-1160(ra) # 800040b4 <dirlookup>
    80005544:	84aa                	mv	s1,a0
    80005546:	c921                	beqz	a0,80005596 <create+0x94>
    iunlockput(dp);
    80005548:	854a                	mv	a0,s2
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	8e8080e7          	jalr	-1816(ra) # 80003e32 <iunlockput>
    ilock(ip);
    80005552:	8526                	mv	a0,s1
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	67c080e7          	jalr	1660(ra) # 80003bd0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000555c:	2981                	sext.w	s3,s3
    8000555e:	4789                	li	a5,2
    80005560:	02f99463          	bne	s3,a5,80005588 <create+0x86>
    80005564:	0444d783          	lhu	a5,68(s1)
    80005568:	37f9                	addiw	a5,a5,-2
    8000556a:	17c2                	slli	a5,a5,0x30
    8000556c:	93c1                	srli	a5,a5,0x30
    8000556e:	4705                	li	a4,1
    80005570:	00f76c63          	bltu	a4,a5,80005588 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005574:	8526                	mv	a0,s1
    80005576:	60a6                	ld	ra,72(sp)
    80005578:	6406                	ld	s0,64(sp)
    8000557a:	74e2                	ld	s1,56(sp)
    8000557c:	7942                	ld	s2,48(sp)
    8000557e:	79a2                	ld	s3,40(sp)
    80005580:	7a02                	ld	s4,32(sp)
    80005582:	6ae2                	ld	s5,24(sp)
    80005584:	6161                	addi	sp,sp,80
    80005586:	8082                	ret
    iunlockput(ip);
    80005588:	8526                	mv	a0,s1
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	8a8080e7          	jalr	-1880(ra) # 80003e32 <iunlockput>
    return 0;
    80005592:	4481                	li	s1,0
    80005594:	b7c5                	j	80005574 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005596:	85ce                	mv	a1,s3
    80005598:	00092503          	lw	a0,0(s2)
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	49c080e7          	jalr	1180(ra) # 80003a38 <ialloc>
    800055a4:	84aa                	mv	s1,a0
    800055a6:	c529                	beqz	a0,800055f0 <create+0xee>
  ilock(ip);
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	628080e7          	jalr	1576(ra) # 80003bd0 <ilock>
  ip->major = major;
    800055b0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055b4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055b8:	4785                	li	a5,1
    800055ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	546080e7          	jalr	1350(ra) # 80003b06 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055c8:	2981                	sext.w	s3,s3
    800055ca:	4785                	li	a5,1
    800055cc:	02f98a63          	beq	s3,a5,80005600 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800055d0:	40d0                	lw	a2,4(s1)
    800055d2:	fb040593          	addi	a1,s0,-80
    800055d6:	854a                	mv	a0,s2
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	cec080e7          	jalr	-788(ra) # 800042c4 <dirlink>
    800055e0:	06054b63          	bltz	a0,80005656 <create+0x154>
  iunlockput(dp);
    800055e4:	854a                	mv	a0,s2
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	84c080e7          	jalr	-1972(ra) # 80003e32 <iunlockput>
  return ip;
    800055ee:	b759                	j	80005574 <create+0x72>
    panic("create: ialloc");
    800055f0:	00003517          	auipc	a0,0x3
    800055f4:	15050513          	addi	a0,a0,336 # 80008740 <syscalls+0x2b0>
    800055f8:	ffffb097          	auipc	ra,0xffffb
    800055fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005600:	04a95783          	lhu	a5,74(s2)
    80005604:	2785                	addiw	a5,a5,1
    80005606:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000560a:	854a                	mv	a0,s2
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	4fa080e7          	jalr	1274(ra) # 80003b06 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005614:	40d0                	lw	a2,4(s1)
    80005616:	00003597          	auipc	a1,0x3
    8000561a:	13a58593          	addi	a1,a1,314 # 80008750 <syscalls+0x2c0>
    8000561e:	8526                	mv	a0,s1
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	ca4080e7          	jalr	-860(ra) # 800042c4 <dirlink>
    80005628:	00054f63          	bltz	a0,80005646 <create+0x144>
    8000562c:	00492603          	lw	a2,4(s2)
    80005630:	00003597          	auipc	a1,0x3
    80005634:	12858593          	addi	a1,a1,296 # 80008758 <syscalls+0x2c8>
    80005638:	8526                	mv	a0,s1
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	c8a080e7          	jalr	-886(ra) # 800042c4 <dirlink>
    80005642:	f80557e3          	bgez	a0,800055d0 <create+0xce>
      panic("create dots");
    80005646:	00003517          	auipc	a0,0x3
    8000564a:	11a50513          	addi	a0,a0,282 # 80008760 <syscalls+0x2d0>
    8000564e:	ffffb097          	auipc	ra,0xffffb
    80005652:	ef0080e7          	jalr	-272(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005656:	00003517          	auipc	a0,0x3
    8000565a:	11a50513          	addi	a0,a0,282 # 80008770 <syscalls+0x2e0>
    8000565e:	ffffb097          	auipc	ra,0xffffb
    80005662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>
    return 0;
    80005666:	84aa                	mv	s1,a0
    80005668:	b731                	j	80005574 <create+0x72>

000000008000566a <sys_dup>:
{
    8000566a:	7179                	addi	sp,sp,-48
    8000566c:	f406                	sd	ra,40(sp)
    8000566e:	f022                	sd	s0,32(sp)
    80005670:	ec26                	sd	s1,24(sp)
    80005672:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005674:	fd840613          	addi	a2,s0,-40
    80005678:	4581                	li	a1,0
    8000567a:	4501                	li	a0,0
    8000567c:	00000097          	auipc	ra,0x0
    80005680:	ddc080e7          	jalr	-548(ra) # 80005458 <argfd>
    return -1;
    80005684:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005686:	02054363          	bltz	a0,800056ac <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000568a:	fd843503          	ld	a0,-40(s0)
    8000568e:	00000097          	auipc	ra,0x0
    80005692:	e32080e7          	jalr	-462(ra) # 800054c0 <fdalloc>
    80005696:	84aa                	mv	s1,a0
    return -1;
    80005698:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000569a:	00054963          	bltz	a0,800056ac <sys_dup+0x42>
  filedup(f);
    8000569e:	fd843503          	ld	a0,-40(s0)
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	37a080e7          	jalr	890(ra) # 80004a1c <filedup>
  return fd;
    800056aa:	87a6                	mv	a5,s1
}
    800056ac:	853e                	mv	a0,a5
    800056ae:	70a2                	ld	ra,40(sp)
    800056b0:	7402                	ld	s0,32(sp)
    800056b2:	64e2                	ld	s1,24(sp)
    800056b4:	6145                	addi	sp,sp,48
    800056b6:	8082                	ret

00000000800056b8 <sys_read>:
{
    800056b8:	7179                	addi	sp,sp,-48
    800056ba:	f406                	sd	ra,40(sp)
    800056bc:	f022                	sd	s0,32(sp)
    800056be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056c0:	fe840613          	addi	a2,s0,-24
    800056c4:	4581                	li	a1,0
    800056c6:	4501                	li	a0,0
    800056c8:	00000097          	auipc	ra,0x0
    800056cc:	d90080e7          	jalr	-624(ra) # 80005458 <argfd>
    return -1;
    800056d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056d2:	04054163          	bltz	a0,80005714 <sys_read+0x5c>
    800056d6:	fe440593          	addi	a1,s0,-28
    800056da:	4509                	li	a0,2
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	938080e7          	jalr	-1736(ra) # 80003014 <argint>
    return -1;
    800056e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e6:	02054763          	bltz	a0,80005714 <sys_read+0x5c>
    800056ea:	fd840593          	addi	a1,s0,-40
    800056ee:	4505                	li	a0,1
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	946080e7          	jalr	-1722(ra) # 80003036 <argaddr>
    return -1;
    800056f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056fa:	00054d63          	bltz	a0,80005714 <sys_read+0x5c>
  return fileread(f, p, n);
    800056fe:	fe442603          	lw	a2,-28(s0)
    80005702:	fd843583          	ld	a1,-40(s0)
    80005706:	fe843503          	ld	a0,-24(s0)
    8000570a:	fffff097          	auipc	ra,0xfffff
    8000570e:	49e080e7          	jalr	1182(ra) # 80004ba8 <fileread>
    80005712:	87aa                	mv	a5,a0
}
    80005714:	853e                	mv	a0,a5
    80005716:	70a2                	ld	ra,40(sp)
    80005718:	7402                	ld	s0,32(sp)
    8000571a:	6145                	addi	sp,sp,48
    8000571c:	8082                	ret

000000008000571e <sys_write>:
{
    8000571e:	7179                	addi	sp,sp,-48
    80005720:	f406                	sd	ra,40(sp)
    80005722:	f022                	sd	s0,32(sp)
    80005724:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005726:	fe840613          	addi	a2,s0,-24
    8000572a:	4581                	li	a1,0
    8000572c:	4501                	li	a0,0
    8000572e:	00000097          	auipc	ra,0x0
    80005732:	d2a080e7          	jalr	-726(ra) # 80005458 <argfd>
    return -1;
    80005736:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005738:	04054163          	bltz	a0,8000577a <sys_write+0x5c>
    8000573c:	fe440593          	addi	a1,s0,-28
    80005740:	4509                	li	a0,2
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	8d2080e7          	jalr	-1838(ra) # 80003014 <argint>
    return -1;
    8000574a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000574c:	02054763          	bltz	a0,8000577a <sys_write+0x5c>
    80005750:	fd840593          	addi	a1,s0,-40
    80005754:	4505                	li	a0,1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	8e0080e7          	jalr	-1824(ra) # 80003036 <argaddr>
    return -1;
    8000575e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005760:	00054d63          	bltz	a0,8000577a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005764:	fe442603          	lw	a2,-28(s0)
    80005768:	fd843583          	ld	a1,-40(s0)
    8000576c:	fe843503          	ld	a0,-24(s0)
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	4fa080e7          	jalr	1274(ra) # 80004c6a <filewrite>
    80005778:	87aa                	mv	a5,a0
}
    8000577a:	853e                	mv	a0,a5
    8000577c:	70a2                	ld	ra,40(sp)
    8000577e:	7402                	ld	s0,32(sp)
    80005780:	6145                	addi	sp,sp,48
    80005782:	8082                	ret

0000000080005784 <sys_close>:
{
    80005784:	1101                	addi	sp,sp,-32
    80005786:	ec06                	sd	ra,24(sp)
    80005788:	e822                	sd	s0,16(sp)
    8000578a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000578c:	fe040613          	addi	a2,s0,-32
    80005790:	fec40593          	addi	a1,s0,-20
    80005794:	4501                	li	a0,0
    80005796:	00000097          	auipc	ra,0x0
    8000579a:	cc2080e7          	jalr	-830(ra) # 80005458 <argfd>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057a0:	02054463          	bltz	a0,800057c8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057a4:	ffffc097          	auipc	ra,0xffffc
    800057a8:	330080e7          	jalr	816(ra) # 80001ad4 <myproc>
    800057ac:	fec42783          	lw	a5,-20(s0)
    800057b0:	07f1                	addi	a5,a5,28
    800057b2:	078e                	slli	a5,a5,0x3
    800057b4:	97aa                	add	a5,a5,a0
    800057b6:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800057ba:	fe043503          	ld	a0,-32(s0)
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	2b0080e7          	jalr	688(ra) # 80004a6e <fileclose>
  return 0;
    800057c6:	4781                	li	a5,0
}
    800057c8:	853e                	mv	a0,a5
    800057ca:	60e2                	ld	ra,24(sp)
    800057cc:	6442                	ld	s0,16(sp)
    800057ce:	6105                	addi	sp,sp,32
    800057d0:	8082                	ret

00000000800057d2 <sys_fstat>:
{
    800057d2:	1101                	addi	sp,sp,-32
    800057d4:	ec06                	sd	ra,24(sp)
    800057d6:	e822                	sd	s0,16(sp)
    800057d8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057da:	fe840613          	addi	a2,s0,-24
    800057de:	4581                	li	a1,0
    800057e0:	4501                	li	a0,0
    800057e2:	00000097          	auipc	ra,0x0
    800057e6:	c76080e7          	jalr	-906(ra) # 80005458 <argfd>
    return -1;
    800057ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057ec:	02054563          	bltz	a0,80005816 <sys_fstat+0x44>
    800057f0:	fe040593          	addi	a1,s0,-32
    800057f4:	4505                	li	a0,1
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	840080e7          	jalr	-1984(ra) # 80003036 <argaddr>
    return -1;
    800057fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005800:	00054b63          	bltz	a0,80005816 <sys_fstat+0x44>
  return filestat(f, st);
    80005804:	fe043583          	ld	a1,-32(s0)
    80005808:	fe843503          	ld	a0,-24(s0)
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	32a080e7          	jalr	810(ra) # 80004b36 <filestat>
    80005814:	87aa                	mv	a5,a0
}
    80005816:	853e                	mv	a0,a5
    80005818:	60e2                	ld	ra,24(sp)
    8000581a:	6442                	ld	s0,16(sp)
    8000581c:	6105                	addi	sp,sp,32
    8000581e:	8082                	ret

0000000080005820 <sys_link>:
{
    80005820:	7169                	addi	sp,sp,-304
    80005822:	f606                	sd	ra,296(sp)
    80005824:	f222                	sd	s0,288(sp)
    80005826:	ee26                	sd	s1,280(sp)
    80005828:	ea4a                	sd	s2,272(sp)
    8000582a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000582c:	08000613          	li	a2,128
    80005830:	ed040593          	addi	a1,s0,-304
    80005834:	4501                	li	a0,0
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	822080e7          	jalr	-2014(ra) # 80003058 <argstr>
    return -1;
    8000583e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005840:	10054e63          	bltz	a0,8000595c <sys_link+0x13c>
    80005844:	08000613          	li	a2,128
    80005848:	f5040593          	addi	a1,s0,-176
    8000584c:	4505                	li	a0,1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	80a080e7          	jalr	-2038(ra) # 80003058 <argstr>
    return -1;
    80005856:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005858:	10054263          	bltz	a0,8000595c <sys_link+0x13c>
  begin_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	d46080e7          	jalr	-698(ra) # 800045a2 <begin_op>
  if((ip = namei(old)) == 0){
    80005864:	ed040513          	addi	a0,s0,-304
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	b1e080e7          	jalr	-1250(ra) # 80004386 <namei>
    80005870:	84aa                	mv	s1,a0
    80005872:	c551                	beqz	a0,800058fe <sys_link+0xde>
  ilock(ip);
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	35c080e7          	jalr	860(ra) # 80003bd0 <ilock>
  if(ip->type == T_DIR){
    8000587c:	04449703          	lh	a4,68(s1)
    80005880:	4785                	li	a5,1
    80005882:	08f70463          	beq	a4,a5,8000590a <sys_link+0xea>
  ip->nlink++;
    80005886:	04a4d783          	lhu	a5,74(s1)
    8000588a:	2785                	addiw	a5,a5,1
    8000588c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005890:	8526                	mv	a0,s1
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	274080e7          	jalr	628(ra) # 80003b06 <iupdate>
  iunlock(ip);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	3f6080e7          	jalr	1014(ra) # 80003c92 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058a4:	fd040593          	addi	a1,s0,-48
    800058a8:	f5040513          	addi	a0,s0,-176
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	af8080e7          	jalr	-1288(ra) # 800043a4 <nameiparent>
    800058b4:	892a                	mv	s2,a0
    800058b6:	c935                	beqz	a0,8000592a <sys_link+0x10a>
  ilock(dp);
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	318080e7          	jalr	792(ra) # 80003bd0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058c0:	00092703          	lw	a4,0(s2)
    800058c4:	409c                	lw	a5,0(s1)
    800058c6:	04f71d63          	bne	a4,a5,80005920 <sys_link+0x100>
    800058ca:	40d0                	lw	a2,4(s1)
    800058cc:	fd040593          	addi	a1,s0,-48
    800058d0:	854a                	mv	a0,s2
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	9f2080e7          	jalr	-1550(ra) # 800042c4 <dirlink>
    800058da:	04054363          	bltz	a0,80005920 <sys_link+0x100>
  iunlockput(dp);
    800058de:	854a                	mv	a0,s2
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	552080e7          	jalr	1362(ra) # 80003e32 <iunlockput>
  iput(ip);
    800058e8:	8526                	mv	a0,s1
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	4a0080e7          	jalr	1184(ra) # 80003d8a <iput>
  end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	d30080e7          	jalr	-720(ra) # 80004622 <end_op>
  return 0;
    800058fa:	4781                	li	a5,0
    800058fc:	a085                	j	8000595c <sys_link+0x13c>
    end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	d24080e7          	jalr	-732(ra) # 80004622 <end_op>
    return -1;
    80005906:	57fd                	li	a5,-1
    80005908:	a891                	j	8000595c <sys_link+0x13c>
    iunlockput(ip);
    8000590a:	8526                	mv	a0,s1
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	526080e7          	jalr	1318(ra) # 80003e32 <iunlockput>
    end_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	d0e080e7          	jalr	-754(ra) # 80004622 <end_op>
    return -1;
    8000591c:	57fd                	li	a5,-1
    8000591e:	a83d                	j	8000595c <sys_link+0x13c>
    iunlockput(dp);
    80005920:	854a                	mv	a0,s2
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	510080e7          	jalr	1296(ra) # 80003e32 <iunlockput>
  ilock(ip);
    8000592a:	8526                	mv	a0,s1
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	2a4080e7          	jalr	676(ra) # 80003bd0 <ilock>
  ip->nlink--;
    80005934:	04a4d783          	lhu	a5,74(s1)
    80005938:	37fd                	addiw	a5,a5,-1
    8000593a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000593e:	8526                	mv	a0,s1
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	1c6080e7          	jalr	454(ra) # 80003b06 <iupdate>
  iunlockput(ip);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	4e8080e7          	jalr	1256(ra) # 80003e32 <iunlockput>
  end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	cd0080e7          	jalr	-816(ra) # 80004622 <end_op>
  return -1;
    8000595a:	57fd                	li	a5,-1
}
    8000595c:	853e                	mv	a0,a5
    8000595e:	70b2                	ld	ra,296(sp)
    80005960:	7412                	ld	s0,288(sp)
    80005962:	64f2                	ld	s1,280(sp)
    80005964:	6952                	ld	s2,272(sp)
    80005966:	6155                	addi	sp,sp,304
    80005968:	8082                	ret

000000008000596a <sys_unlink>:
{
    8000596a:	7151                	addi	sp,sp,-240
    8000596c:	f586                	sd	ra,232(sp)
    8000596e:	f1a2                	sd	s0,224(sp)
    80005970:	eda6                	sd	s1,216(sp)
    80005972:	e9ca                	sd	s2,208(sp)
    80005974:	e5ce                	sd	s3,200(sp)
    80005976:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005978:	08000613          	li	a2,128
    8000597c:	f3040593          	addi	a1,s0,-208
    80005980:	4501                	li	a0,0
    80005982:	ffffd097          	auipc	ra,0xffffd
    80005986:	6d6080e7          	jalr	1750(ra) # 80003058 <argstr>
    8000598a:	18054163          	bltz	a0,80005b0c <sys_unlink+0x1a2>
  begin_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	c14080e7          	jalr	-1004(ra) # 800045a2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005996:	fb040593          	addi	a1,s0,-80
    8000599a:	f3040513          	addi	a0,s0,-208
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	a06080e7          	jalr	-1530(ra) # 800043a4 <nameiparent>
    800059a6:	84aa                	mv	s1,a0
    800059a8:	c979                	beqz	a0,80005a7e <sys_unlink+0x114>
  ilock(dp);
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	226080e7          	jalr	550(ra) # 80003bd0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059b2:	00003597          	auipc	a1,0x3
    800059b6:	d9e58593          	addi	a1,a1,-610 # 80008750 <syscalls+0x2c0>
    800059ba:	fb040513          	addi	a0,s0,-80
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	6dc080e7          	jalr	1756(ra) # 8000409a <namecmp>
    800059c6:	14050a63          	beqz	a0,80005b1a <sys_unlink+0x1b0>
    800059ca:	00003597          	auipc	a1,0x3
    800059ce:	d8e58593          	addi	a1,a1,-626 # 80008758 <syscalls+0x2c8>
    800059d2:	fb040513          	addi	a0,s0,-80
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	6c4080e7          	jalr	1732(ra) # 8000409a <namecmp>
    800059de:	12050e63          	beqz	a0,80005b1a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059e2:	f2c40613          	addi	a2,s0,-212
    800059e6:	fb040593          	addi	a1,s0,-80
    800059ea:	8526                	mv	a0,s1
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	6c8080e7          	jalr	1736(ra) # 800040b4 <dirlookup>
    800059f4:	892a                	mv	s2,a0
    800059f6:	12050263          	beqz	a0,80005b1a <sys_unlink+0x1b0>
  ilock(ip);
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	1d6080e7          	jalr	470(ra) # 80003bd0 <ilock>
  if(ip->nlink < 1)
    80005a02:	04a91783          	lh	a5,74(s2)
    80005a06:	08f05263          	blez	a5,80005a8a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a0a:	04491703          	lh	a4,68(s2)
    80005a0e:	4785                	li	a5,1
    80005a10:	08f70563          	beq	a4,a5,80005a9a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a14:	4641                	li	a2,16
    80005a16:	4581                	li	a1,0
    80005a18:	fc040513          	addi	a0,s0,-64
    80005a1c:	ffffb097          	auipc	ra,0xffffb
    80005a20:	2c4080e7          	jalr	708(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a24:	4741                	li	a4,16
    80005a26:	f2c42683          	lw	a3,-212(s0)
    80005a2a:	fc040613          	addi	a2,s0,-64
    80005a2e:	4581                	li	a1,0
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	54a080e7          	jalr	1354(ra) # 80003f7c <writei>
    80005a3a:	47c1                	li	a5,16
    80005a3c:	0af51563          	bne	a0,a5,80005ae6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a40:	04491703          	lh	a4,68(s2)
    80005a44:	4785                	li	a5,1
    80005a46:	0af70863          	beq	a4,a5,80005af6 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a4a:	8526                	mv	a0,s1
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	3e6080e7          	jalr	998(ra) # 80003e32 <iunlockput>
  ip->nlink--;
    80005a54:	04a95783          	lhu	a5,74(s2)
    80005a58:	37fd                	addiw	a5,a5,-1
    80005a5a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a5e:	854a                	mv	a0,s2
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	0a6080e7          	jalr	166(ra) # 80003b06 <iupdate>
  iunlockput(ip);
    80005a68:	854a                	mv	a0,s2
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	3c8080e7          	jalr	968(ra) # 80003e32 <iunlockput>
  end_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	bb0080e7          	jalr	-1104(ra) # 80004622 <end_op>
  return 0;
    80005a7a:	4501                	li	a0,0
    80005a7c:	a84d                	j	80005b2e <sys_unlink+0x1c4>
    end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	ba4080e7          	jalr	-1116(ra) # 80004622 <end_op>
    return -1;
    80005a86:	557d                	li	a0,-1
    80005a88:	a05d                	j	80005b2e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a8a:	00003517          	auipc	a0,0x3
    80005a8e:	cf650513          	addi	a0,a0,-778 # 80008780 <syscalls+0x2f0>
    80005a92:	ffffb097          	auipc	ra,0xffffb
    80005a96:	aac080e7          	jalr	-1364(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a9a:	04c92703          	lw	a4,76(s2)
    80005a9e:	02000793          	li	a5,32
    80005aa2:	f6e7f9e3          	bgeu	a5,a4,80005a14 <sys_unlink+0xaa>
    80005aa6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aaa:	4741                	li	a4,16
    80005aac:	86ce                	mv	a3,s3
    80005aae:	f1840613          	addi	a2,s0,-232
    80005ab2:	4581                	li	a1,0
    80005ab4:	854a                	mv	a0,s2
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	3ce080e7          	jalr	974(ra) # 80003e84 <readi>
    80005abe:	47c1                	li	a5,16
    80005ac0:	00f51b63          	bne	a0,a5,80005ad6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ac4:	f1845783          	lhu	a5,-232(s0)
    80005ac8:	e7a1                	bnez	a5,80005b10 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aca:	29c1                	addiw	s3,s3,16
    80005acc:	04c92783          	lw	a5,76(s2)
    80005ad0:	fcf9ede3          	bltu	s3,a5,80005aaa <sys_unlink+0x140>
    80005ad4:	b781                	j	80005a14 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ad6:	00003517          	auipc	a0,0x3
    80005ada:	cc250513          	addi	a0,a0,-830 # 80008798 <syscalls+0x308>
    80005ade:	ffffb097          	auipc	ra,0xffffb
    80005ae2:	a60080e7          	jalr	-1440(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005ae6:	00003517          	auipc	a0,0x3
    80005aea:	cca50513          	addi	a0,a0,-822 # 800087b0 <syscalls+0x320>
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	a50080e7          	jalr	-1456(ra) # 8000053e <panic>
    dp->nlink--;
    80005af6:	04a4d783          	lhu	a5,74(s1)
    80005afa:	37fd                	addiw	a5,a5,-1
    80005afc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b00:	8526                	mv	a0,s1
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	004080e7          	jalr	4(ra) # 80003b06 <iupdate>
    80005b0a:	b781                	j	80005a4a <sys_unlink+0xe0>
    return -1;
    80005b0c:	557d                	li	a0,-1
    80005b0e:	a005                	j	80005b2e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b10:	854a                	mv	a0,s2
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	320080e7          	jalr	800(ra) # 80003e32 <iunlockput>
  iunlockput(dp);
    80005b1a:	8526                	mv	a0,s1
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	316080e7          	jalr	790(ra) # 80003e32 <iunlockput>
  end_op();
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	afe080e7          	jalr	-1282(ra) # 80004622 <end_op>
  return -1;
    80005b2c:	557d                	li	a0,-1
}
    80005b2e:	70ae                	ld	ra,232(sp)
    80005b30:	740e                	ld	s0,224(sp)
    80005b32:	64ee                	ld	s1,216(sp)
    80005b34:	694e                	ld	s2,208(sp)
    80005b36:	69ae                	ld	s3,200(sp)
    80005b38:	616d                	addi	sp,sp,240
    80005b3a:	8082                	ret

0000000080005b3c <sys_open>:

uint64
sys_open(void)
{
    80005b3c:	7131                	addi	sp,sp,-192
    80005b3e:	fd06                	sd	ra,184(sp)
    80005b40:	f922                	sd	s0,176(sp)
    80005b42:	f526                	sd	s1,168(sp)
    80005b44:	f14a                	sd	s2,160(sp)
    80005b46:	ed4e                	sd	s3,152(sp)
    80005b48:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b4a:	08000613          	li	a2,128
    80005b4e:	f5040593          	addi	a1,s0,-176
    80005b52:	4501                	li	a0,0
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	504080e7          	jalr	1284(ra) # 80003058 <argstr>
    return -1;
    80005b5c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b5e:	0c054163          	bltz	a0,80005c20 <sys_open+0xe4>
    80005b62:	f4c40593          	addi	a1,s0,-180
    80005b66:	4505                	li	a0,1
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	4ac080e7          	jalr	1196(ra) # 80003014 <argint>
    80005b70:	0a054863          	bltz	a0,80005c20 <sys_open+0xe4>

  begin_op();
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	a2e080e7          	jalr	-1490(ra) # 800045a2 <begin_op>

  if(omode & O_CREATE){
    80005b7c:	f4c42783          	lw	a5,-180(s0)
    80005b80:	2007f793          	andi	a5,a5,512
    80005b84:	cbdd                	beqz	a5,80005c3a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b86:	4681                	li	a3,0
    80005b88:	4601                	li	a2,0
    80005b8a:	4589                	li	a1,2
    80005b8c:	f5040513          	addi	a0,s0,-176
    80005b90:	00000097          	auipc	ra,0x0
    80005b94:	972080e7          	jalr	-1678(ra) # 80005502 <create>
    80005b98:	892a                	mv	s2,a0
    if(ip == 0){
    80005b9a:	c959                	beqz	a0,80005c30 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b9c:	04491703          	lh	a4,68(s2)
    80005ba0:	478d                	li	a5,3
    80005ba2:	00f71763          	bne	a4,a5,80005bb0 <sys_open+0x74>
    80005ba6:	04695703          	lhu	a4,70(s2)
    80005baa:	47a5                	li	a5,9
    80005bac:	0ce7ec63          	bltu	a5,a4,80005c84 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	e02080e7          	jalr	-510(ra) # 800049b2 <filealloc>
    80005bb8:	89aa                	mv	s3,a0
    80005bba:	10050263          	beqz	a0,80005cbe <sys_open+0x182>
    80005bbe:	00000097          	auipc	ra,0x0
    80005bc2:	902080e7          	jalr	-1790(ra) # 800054c0 <fdalloc>
    80005bc6:	84aa                	mv	s1,a0
    80005bc8:	0e054663          	bltz	a0,80005cb4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bcc:	04491703          	lh	a4,68(s2)
    80005bd0:	478d                	li	a5,3
    80005bd2:	0cf70463          	beq	a4,a5,80005c9a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bd6:	4789                	li	a5,2
    80005bd8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005bdc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005be0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005be4:	f4c42783          	lw	a5,-180(s0)
    80005be8:	0017c713          	xori	a4,a5,1
    80005bec:	8b05                	andi	a4,a4,1
    80005bee:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bf2:	0037f713          	andi	a4,a5,3
    80005bf6:	00e03733          	snez	a4,a4
    80005bfa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bfe:	4007f793          	andi	a5,a5,1024
    80005c02:	c791                	beqz	a5,80005c0e <sys_open+0xd2>
    80005c04:	04491703          	lh	a4,68(s2)
    80005c08:	4789                	li	a5,2
    80005c0a:	08f70f63          	beq	a4,a5,80005ca8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c0e:	854a                	mv	a0,s2
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	082080e7          	jalr	130(ra) # 80003c92 <iunlock>
  end_op();
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	a0a080e7          	jalr	-1526(ra) # 80004622 <end_op>

  return fd;
}
    80005c20:	8526                	mv	a0,s1
    80005c22:	70ea                	ld	ra,184(sp)
    80005c24:	744a                	ld	s0,176(sp)
    80005c26:	74aa                	ld	s1,168(sp)
    80005c28:	790a                	ld	s2,160(sp)
    80005c2a:	69ea                	ld	s3,152(sp)
    80005c2c:	6129                	addi	sp,sp,192
    80005c2e:	8082                	ret
      end_op();
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	9f2080e7          	jalr	-1550(ra) # 80004622 <end_op>
      return -1;
    80005c38:	b7e5                	j	80005c20 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c3a:	f5040513          	addi	a0,s0,-176
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	748080e7          	jalr	1864(ra) # 80004386 <namei>
    80005c46:	892a                	mv	s2,a0
    80005c48:	c905                	beqz	a0,80005c78 <sys_open+0x13c>
    ilock(ip);
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	f86080e7          	jalr	-122(ra) # 80003bd0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c52:	04491703          	lh	a4,68(s2)
    80005c56:	4785                	li	a5,1
    80005c58:	f4f712e3          	bne	a4,a5,80005b9c <sys_open+0x60>
    80005c5c:	f4c42783          	lw	a5,-180(s0)
    80005c60:	dba1                	beqz	a5,80005bb0 <sys_open+0x74>
      iunlockput(ip);
    80005c62:	854a                	mv	a0,s2
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	1ce080e7          	jalr	462(ra) # 80003e32 <iunlockput>
      end_op();
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	9b6080e7          	jalr	-1610(ra) # 80004622 <end_op>
      return -1;
    80005c74:	54fd                	li	s1,-1
    80005c76:	b76d                	j	80005c20 <sys_open+0xe4>
      end_op();
    80005c78:	fffff097          	auipc	ra,0xfffff
    80005c7c:	9aa080e7          	jalr	-1622(ra) # 80004622 <end_op>
      return -1;
    80005c80:	54fd                	li	s1,-1
    80005c82:	bf79                	j	80005c20 <sys_open+0xe4>
    iunlockput(ip);
    80005c84:	854a                	mv	a0,s2
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	1ac080e7          	jalr	428(ra) # 80003e32 <iunlockput>
    end_op();
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	994080e7          	jalr	-1644(ra) # 80004622 <end_op>
    return -1;
    80005c96:	54fd                	li	s1,-1
    80005c98:	b761                	j	80005c20 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c9a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c9e:	04691783          	lh	a5,70(s2)
    80005ca2:	02f99223          	sh	a5,36(s3)
    80005ca6:	bf2d                	j	80005be0 <sys_open+0xa4>
    itrunc(ip);
    80005ca8:	854a                	mv	a0,s2
    80005caa:	ffffe097          	auipc	ra,0xffffe
    80005cae:	034080e7          	jalr	52(ra) # 80003cde <itrunc>
    80005cb2:	bfb1                	j	80005c0e <sys_open+0xd2>
      fileclose(f);
    80005cb4:	854e                	mv	a0,s3
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	db8080e7          	jalr	-584(ra) # 80004a6e <fileclose>
    iunlockput(ip);
    80005cbe:	854a                	mv	a0,s2
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	172080e7          	jalr	370(ra) # 80003e32 <iunlockput>
    end_op();
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	95a080e7          	jalr	-1702(ra) # 80004622 <end_op>
    return -1;
    80005cd0:	54fd                	li	s1,-1
    80005cd2:	b7b9                	j	80005c20 <sys_open+0xe4>

0000000080005cd4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cd4:	7175                	addi	sp,sp,-144
    80005cd6:	e506                	sd	ra,136(sp)
    80005cd8:	e122                	sd	s0,128(sp)
    80005cda:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	8c6080e7          	jalr	-1850(ra) # 800045a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ce4:	08000613          	li	a2,128
    80005ce8:	f7040593          	addi	a1,s0,-144
    80005cec:	4501                	li	a0,0
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	36a080e7          	jalr	874(ra) # 80003058 <argstr>
    80005cf6:	02054963          	bltz	a0,80005d28 <sys_mkdir+0x54>
    80005cfa:	4681                	li	a3,0
    80005cfc:	4601                	li	a2,0
    80005cfe:	4585                	li	a1,1
    80005d00:	f7040513          	addi	a0,s0,-144
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	7fe080e7          	jalr	2046(ra) # 80005502 <create>
    80005d0c:	cd11                	beqz	a0,80005d28 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	124080e7          	jalr	292(ra) # 80003e32 <iunlockput>
  end_op();
    80005d16:	fffff097          	auipc	ra,0xfffff
    80005d1a:	90c080e7          	jalr	-1780(ra) # 80004622 <end_op>
  return 0;
    80005d1e:	4501                	li	a0,0
}
    80005d20:	60aa                	ld	ra,136(sp)
    80005d22:	640a                	ld	s0,128(sp)
    80005d24:	6149                	addi	sp,sp,144
    80005d26:	8082                	ret
    end_op();
    80005d28:	fffff097          	auipc	ra,0xfffff
    80005d2c:	8fa080e7          	jalr	-1798(ra) # 80004622 <end_op>
    return -1;
    80005d30:	557d                	li	a0,-1
    80005d32:	b7fd                	j	80005d20 <sys_mkdir+0x4c>

0000000080005d34 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d34:	7135                	addi	sp,sp,-160
    80005d36:	ed06                	sd	ra,152(sp)
    80005d38:	e922                	sd	s0,144(sp)
    80005d3a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	866080e7          	jalr	-1946(ra) # 800045a2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d44:	08000613          	li	a2,128
    80005d48:	f7040593          	addi	a1,s0,-144
    80005d4c:	4501                	li	a0,0
    80005d4e:	ffffd097          	auipc	ra,0xffffd
    80005d52:	30a080e7          	jalr	778(ra) # 80003058 <argstr>
    80005d56:	04054a63          	bltz	a0,80005daa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d5a:	f6c40593          	addi	a1,s0,-148
    80005d5e:	4505                	li	a0,1
    80005d60:	ffffd097          	auipc	ra,0xffffd
    80005d64:	2b4080e7          	jalr	692(ra) # 80003014 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d68:	04054163          	bltz	a0,80005daa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d6c:	f6840593          	addi	a1,s0,-152
    80005d70:	4509                	li	a0,2
    80005d72:	ffffd097          	auipc	ra,0xffffd
    80005d76:	2a2080e7          	jalr	674(ra) # 80003014 <argint>
     argint(1, &major) < 0 ||
    80005d7a:	02054863          	bltz	a0,80005daa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d7e:	f6841683          	lh	a3,-152(s0)
    80005d82:	f6c41603          	lh	a2,-148(s0)
    80005d86:	458d                	li	a1,3
    80005d88:	f7040513          	addi	a0,s0,-144
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	776080e7          	jalr	1910(ra) # 80005502 <create>
     argint(2, &minor) < 0 ||
    80005d94:	c919                	beqz	a0,80005daa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	09c080e7          	jalr	156(ra) # 80003e32 <iunlockput>
  end_op();
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	884080e7          	jalr	-1916(ra) # 80004622 <end_op>
  return 0;
    80005da6:	4501                	li	a0,0
    80005da8:	a031                	j	80005db4 <sys_mknod+0x80>
    end_op();
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	878080e7          	jalr	-1928(ra) # 80004622 <end_op>
    return -1;
    80005db2:	557d                	li	a0,-1
}
    80005db4:	60ea                	ld	ra,152(sp)
    80005db6:	644a                	ld	s0,144(sp)
    80005db8:	610d                	addi	sp,sp,160
    80005dba:	8082                	ret

0000000080005dbc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dbc:	7135                	addi	sp,sp,-160
    80005dbe:	ed06                	sd	ra,152(sp)
    80005dc0:	e922                	sd	s0,144(sp)
    80005dc2:	e526                	sd	s1,136(sp)
    80005dc4:	e14a                	sd	s2,128(sp)
    80005dc6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	d0c080e7          	jalr	-756(ra) # 80001ad4 <myproc>
    80005dd0:	892a                	mv	s2,a0
  
  begin_op();
    80005dd2:	ffffe097          	auipc	ra,0xffffe
    80005dd6:	7d0080e7          	jalr	2000(ra) # 800045a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dda:	08000613          	li	a2,128
    80005dde:	f6040593          	addi	a1,s0,-160
    80005de2:	4501                	li	a0,0
    80005de4:	ffffd097          	auipc	ra,0xffffd
    80005de8:	274080e7          	jalr	628(ra) # 80003058 <argstr>
    80005dec:	04054b63          	bltz	a0,80005e42 <sys_chdir+0x86>
    80005df0:	f6040513          	addi	a0,s0,-160
    80005df4:	ffffe097          	auipc	ra,0xffffe
    80005df8:	592080e7          	jalr	1426(ra) # 80004386 <namei>
    80005dfc:	84aa                	mv	s1,a0
    80005dfe:	c131                	beqz	a0,80005e42 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	dd0080e7          	jalr	-560(ra) # 80003bd0 <ilock>
  if(ip->type != T_DIR){
    80005e08:	04449703          	lh	a4,68(s1)
    80005e0c:	4785                	li	a5,1
    80005e0e:	04f71063          	bne	a4,a5,80005e4e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e12:	8526                	mv	a0,s1
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	e7e080e7          	jalr	-386(ra) # 80003c92 <iunlock>
  iput(p->cwd);
    80005e1c:	16893503          	ld	a0,360(s2)
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	f6a080e7          	jalr	-150(ra) # 80003d8a <iput>
  end_op();
    80005e28:	ffffe097          	auipc	ra,0xffffe
    80005e2c:	7fa080e7          	jalr	2042(ra) # 80004622 <end_op>
  p->cwd = ip;
    80005e30:	16993423          	sd	s1,360(s2)
  return 0;
    80005e34:	4501                	li	a0,0
}
    80005e36:	60ea                	ld	ra,152(sp)
    80005e38:	644a                	ld	s0,144(sp)
    80005e3a:	64aa                	ld	s1,136(sp)
    80005e3c:	690a                	ld	s2,128(sp)
    80005e3e:	610d                	addi	sp,sp,160
    80005e40:	8082                	ret
    end_op();
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	7e0080e7          	jalr	2016(ra) # 80004622 <end_op>
    return -1;
    80005e4a:	557d                	li	a0,-1
    80005e4c:	b7ed                	j	80005e36 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e4e:	8526                	mv	a0,s1
    80005e50:	ffffe097          	auipc	ra,0xffffe
    80005e54:	fe2080e7          	jalr	-30(ra) # 80003e32 <iunlockput>
    end_op();
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	7ca080e7          	jalr	1994(ra) # 80004622 <end_op>
    return -1;
    80005e60:	557d                	li	a0,-1
    80005e62:	bfd1                	j	80005e36 <sys_chdir+0x7a>

0000000080005e64 <sys_exec>:

uint64
sys_exec(void)
{
    80005e64:	7145                	addi	sp,sp,-464
    80005e66:	e786                	sd	ra,456(sp)
    80005e68:	e3a2                	sd	s0,448(sp)
    80005e6a:	ff26                	sd	s1,440(sp)
    80005e6c:	fb4a                	sd	s2,432(sp)
    80005e6e:	f74e                	sd	s3,424(sp)
    80005e70:	f352                	sd	s4,416(sp)
    80005e72:	ef56                	sd	s5,408(sp)
    80005e74:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e76:	08000613          	li	a2,128
    80005e7a:	f4040593          	addi	a1,s0,-192
    80005e7e:	4501                	li	a0,0
    80005e80:	ffffd097          	auipc	ra,0xffffd
    80005e84:	1d8080e7          	jalr	472(ra) # 80003058 <argstr>
    return -1;
    80005e88:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e8a:	0c054a63          	bltz	a0,80005f5e <sys_exec+0xfa>
    80005e8e:	e3840593          	addi	a1,s0,-456
    80005e92:	4505                	li	a0,1
    80005e94:	ffffd097          	auipc	ra,0xffffd
    80005e98:	1a2080e7          	jalr	418(ra) # 80003036 <argaddr>
    80005e9c:	0c054163          	bltz	a0,80005f5e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ea0:	10000613          	li	a2,256
    80005ea4:	4581                	li	a1,0
    80005ea6:	e4040513          	addi	a0,s0,-448
    80005eaa:	ffffb097          	auipc	ra,0xffffb
    80005eae:	e36080e7          	jalr	-458(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005eb2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005eb6:	89a6                	mv	s3,s1
    80005eb8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005eba:	02000a13          	li	s4,32
    80005ebe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ec2:	00391513          	slli	a0,s2,0x3
    80005ec6:	e3040593          	addi	a1,s0,-464
    80005eca:	e3843783          	ld	a5,-456(s0)
    80005ece:	953e                	add	a0,a0,a5
    80005ed0:	ffffd097          	auipc	ra,0xffffd
    80005ed4:	0aa080e7          	jalr	170(ra) # 80002f7a <fetchaddr>
    80005ed8:	02054a63          	bltz	a0,80005f0c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005edc:	e3043783          	ld	a5,-464(s0)
    80005ee0:	c3b9                	beqz	a5,80005f26 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ee2:	ffffb097          	auipc	ra,0xffffb
    80005ee6:	c12080e7          	jalr	-1006(ra) # 80000af4 <kalloc>
    80005eea:	85aa                	mv	a1,a0
    80005eec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ef0:	cd11                	beqz	a0,80005f0c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ef2:	6605                	lui	a2,0x1
    80005ef4:	e3043503          	ld	a0,-464(s0)
    80005ef8:	ffffd097          	auipc	ra,0xffffd
    80005efc:	0d4080e7          	jalr	212(ra) # 80002fcc <fetchstr>
    80005f00:	00054663          	bltz	a0,80005f0c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f04:	0905                	addi	s2,s2,1
    80005f06:	09a1                	addi	s3,s3,8
    80005f08:	fb491be3          	bne	s2,s4,80005ebe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f0c:	10048913          	addi	s2,s1,256
    80005f10:	6088                	ld	a0,0(s1)
    80005f12:	c529                	beqz	a0,80005f5c <sys_exec+0xf8>
    kfree(argv[i]);
    80005f14:	ffffb097          	auipc	ra,0xffffb
    80005f18:	ae4080e7          	jalr	-1308(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f1c:	04a1                	addi	s1,s1,8
    80005f1e:	ff2499e3          	bne	s1,s2,80005f10 <sys_exec+0xac>
  return -1;
    80005f22:	597d                	li	s2,-1
    80005f24:	a82d                	j	80005f5e <sys_exec+0xfa>
      argv[i] = 0;
    80005f26:	0a8e                	slli	s5,s5,0x3
    80005f28:	fc040793          	addi	a5,s0,-64
    80005f2c:	9abe                	add	s5,s5,a5
    80005f2e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f32:	e4040593          	addi	a1,s0,-448
    80005f36:	f4040513          	addi	a0,s0,-192
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	194080e7          	jalr	404(ra) # 800050ce <exec>
    80005f42:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f44:	10048993          	addi	s3,s1,256
    80005f48:	6088                	ld	a0,0(s1)
    80005f4a:	c911                	beqz	a0,80005f5e <sys_exec+0xfa>
    kfree(argv[i]);
    80005f4c:	ffffb097          	auipc	ra,0xffffb
    80005f50:	aac080e7          	jalr	-1364(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f54:	04a1                	addi	s1,s1,8
    80005f56:	ff3499e3          	bne	s1,s3,80005f48 <sys_exec+0xe4>
    80005f5a:	a011                	j	80005f5e <sys_exec+0xfa>
  return -1;
    80005f5c:	597d                	li	s2,-1
}
    80005f5e:	854a                	mv	a0,s2
    80005f60:	60be                	ld	ra,456(sp)
    80005f62:	641e                	ld	s0,448(sp)
    80005f64:	74fa                	ld	s1,440(sp)
    80005f66:	795a                	ld	s2,432(sp)
    80005f68:	79ba                	ld	s3,424(sp)
    80005f6a:	7a1a                	ld	s4,416(sp)
    80005f6c:	6afa                	ld	s5,408(sp)
    80005f6e:	6179                	addi	sp,sp,464
    80005f70:	8082                	ret

0000000080005f72 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f72:	7139                	addi	sp,sp,-64
    80005f74:	fc06                	sd	ra,56(sp)
    80005f76:	f822                	sd	s0,48(sp)
    80005f78:	f426                	sd	s1,40(sp)
    80005f7a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f7c:	ffffc097          	auipc	ra,0xffffc
    80005f80:	b58080e7          	jalr	-1192(ra) # 80001ad4 <myproc>
    80005f84:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f86:	fd840593          	addi	a1,s0,-40
    80005f8a:	4501                	li	a0,0
    80005f8c:	ffffd097          	auipc	ra,0xffffd
    80005f90:	0aa080e7          	jalr	170(ra) # 80003036 <argaddr>
    return -1;
    80005f94:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f96:	0e054063          	bltz	a0,80006076 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f9a:	fc840593          	addi	a1,s0,-56
    80005f9e:	fd040513          	addi	a0,s0,-48
    80005fa2:	fffff097          	auipc	ra,0xfffff
    80005fa6:	dfc080e7          	jalr	-516(ra) # 80004d9e <pipealloc>
    return -1;
    80005faa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fac:	0c054563          	bltz	a0,80006076 <sys_pipe+0x104>
  fd0 = -1;
    80005fb0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fb4:	fd043503          	ld	a0,-48(s0)
    80005fb8:	fffff097          	auipc	ra,0xfffff
    80005fbc:	508080e7          	jalr	1288(ra) # 800054c0 <fdalloc>
    80005fc0:	fca42223          	sw	a0,-60(s0)
    80005fc4:	08054c63          	bltz	a0,8000605c <sys_pipe+0xea>
    80005fc8:	fc843503          	ld	a0,-56(s0)
    80005fcc:	fffff097          	auipc	ra,0xfffff
    80005fd0:	4f4080e7          	jalr	1268(ra) # 800054c0 <fdalloc>
    80005fd4:	fca42023          	sw	a0,-64(s0)
    80005fd8:	06054863          	bltz	a0,80006048 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fdc:	4691                	li	a3,4
    80005fde:	fc440613          	addi	a2,s0,-60
    80005fe2:	fd843583          	ld	a1,-40(s0)
    80005fe6:	74a8                	ld	a0,104(s1)
    80005fe8:	ffffb097          	auipc	ra,0xffffb
    80005fec:	7ae080e7          	jalr	1966(ra) # 80001796 <copyout>
    80005ff0:	02054063          	bltz	a0,80006010 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ff4:	4691                	li	a3,4
    80005ff6:	fc040613          	addi	a2,s0,-64
    80005ffa:	fd843583          	ld	a1,-40(s0)
    80005ffe:	0591                	addi	a1,a1,4
    80006000:	74a8                	ld	a0,104(s1)
    80006002:	ffffb097          	auipc	ra,0xffffb
    80006006:	794080e7          	jalr	1940(ra) # 80001796 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000600a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000600c:	06055563          	bgez	a0,80006076 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006010:	fc442783          	lw	a5,-60(s0)
    80006014:	07f1                	addi	a5,a5,28
    80006016:	078e                	slli	a5,a5,0x3
    80006018:	97a6                	add	a5,a5,s1
    8000601a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    8000601e:	fc042503          	lw	a0,-64(s0)
    80006022:	0571                	addi	a0,a0,28
    80006024:	050e                	slli	a0,a0,0x3
    80006026:	9526                	add	a0,a0,s1
    80006028:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000602c:	fd043503          	ld	a0,-48(s0)
    80006030:	fffff097          	auipc	ra,0xfffff
    80006034:	a3e080e7          	jalr	-1474(ra) # 80004a6e <fileclose>
    fileclose(wf);
    80006038:	fc843503          	ld	a0,-56(s0)
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	a32080e7          	jalr	-1486(ra) # 80004a6e <fileclose>
    return -1;
    80006044:	57fd                	li	a5,-1
    80006046:	a805                	j	80006076 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006048:	fc442783          	lw	a5,-60(s0)
    8000604c:	0007c863          	bltz	a5,8000605c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006050:	01c78513          	addi	a0,a5,28
    80006054:	050e                	slli	a0,a0,0x3
    80006056:	9526                	add	a0,a0,s1
    80006058:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000605c:	fd043503          	ld	a0,-48(s0)
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	a0e080e7          	jalr	-1522(ra) # 80004a6e <fileclose>
    fileclose(wf);
    80006068:	fc843503          	ld	a0,-56(s0)
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	a02080e7          	jalr	-1534(ra) # 80004a6e <fileclose>
    return -1;
    80006074:	57fd                	li	a5,-1
}
    80006076:	853e                	mv	a0,a5
    80006078:	70e2                	ld	ra,56(sp)
    8000607a:	7442                	ld	s0,48(sp)
    8000607c:	74a2                	ld	s1,40(sp)
    8000607e:	6121                	addi	sp,sp,64
    80006080:	8082                	ret
	...

0000000080006090 <kernelvec>:
    80006090:	7111                	addi	sp,sp,-256
    80006092:	e006                	sd	ra,0(sp)
    80006094:	e40a                	sd	sp,8(sp)
    80006096:	e80e                	sd	gp,16(sp)
    80006098:	ec12                	sd	tp,24(sp)
    8000609a:	f016                	sd	t0,32(sp)
    8000609c:	f41a                	sd	t1,40(sp)
    8000609e:	f81e                	sd	t2,48(sp)
    800060a0:	fc22                	sd	s0,56(sp)
    800060a2:	e0a6                	sd	s1,64(sp)
    800060a4:	e4aa                	sd	a0,72(sp)
    800060a6:	e8ae                	sd	a1,80(sp)
    800060a8:	ecb2                	sd	a2,88(sp)
    800060aa:	f0b6                	sd	a3,96(sp)
    800060ac:	f4ba                	sd	a4,104(sp)
    800060ae:	f8be                	sd	a5,112(sp)
    800060b0:	fcc2                	sd	a6,120(sp)
    800060b2:	e146                	sd	a7,128(sp)
    800060b4:	e54a                	sd	s2,136(sp)
    800060b6:	e94e                	sd	s3,144(sp)
    800060b8:	ed52                	sd	s4,152(sp)
    800060ba:	f156                	sd	s5,160(sp)
    800060bc:	f55a                	sd	s6,168(sp)
    800060be:	f95e                	sd	s7,176(sp)
    800060c0:	fd62                	sd	s8,184(sp)
    800060c2:	e1e6                	sd	s9,192(sp)
    800060c4:	e5ea                	sd	s10,200(sp)
    800060c6:	e9ee                	sd	s11,208(sp)
    800060c8:	edf2                	sd	t3,216(sp)
    800060ca:	f1f6                	sd	t4,224(sp)
    800060cc:	f5fa                	sd	t5,232(sp)
    800060ce:	f9fe                	sd	t6,240(sp)
    800060d0:	d77fc0ef          	jal	ra,80002e46 <kerneltrap>
    800060d4:	6082                	ld	ra,0(sp)
    800060d6:	6122                	ld	sp,8(sp)
    800060d8:	61c2                	ld	gp,16(sp)
    800060da:	7282                	ld	t0,32(sp)
    800060dc:	7322                	ld	t1,40(sp)
    800060de:	73c2                	ld	t2,48(sp)
    800060e0:	7462                	ld	s0,56(sp)
    800060e2:	6486                	ld	s1,64(sp)
    800060e4:	6526                	ld	a0,72(sp)
    800060e6:	65c6                	ld	a1,80(sp)
    800060e8:	6666                	ld	a2,88(sp)
    800060ea:	7686                	ld	a3,96(sp)
    800060ec:	7726                	ld	a4,104(sp)
    800060ee:	77c6                	ld	a5,112(sp)
    800060f0:	7866                	ld	a6,120(sp)
    800060f2:	688a                	ld	a7,128(sp)
    800060f4:	692a                	ld	s2,136(sp)
    800060f6:	69ca                	ld	s3,144(sp)
    800060f8:	6a6a                	ld	s4,152(sp)
    800060fa:	7a8a                	ld	s5,160(sp)
    800060fc:	7b2a                	ld	s6,168(sp)
    800060fe:	7bca                	ld	s7,176(sp)
    80006100:	7c6a                	ld	s8,184(sp)
    80006102:	6c8e                	ld	s9,192(sp)
    80006104:	6d2e                	ld	s10,200(sp)
    80006106:	6dce                	ld	s11,208(sp)
    80006108:	6e6e                	ld	t3,216(sp)
    8000610a:	7e8e                	ld	t4,224(sp)
    8000610c:	7f2e                	ld	t5,232(sp)
    8000610e:	7fce                	ld	t6,240(sp)
    80006110:	6111                	addi	sp,sp,256
    80006112:	10200073          	sret
    80006116:	00000013          	nop
    8000611a:	00000013          	nop
    8000611e:	0001                	nop

0000000080006120 <timervec>:
    80006120:	34051573          	csrrw	a0,mscratch,a0
    80006124:	e10c                	sd	a1,0(a0)
    80006126:	e510                	sd	a2,8(a0)
    80006128:	e914                	sd	a3,16(a0)
    8000612a:	6d0c                	ld	a1,24(a0)
    8000612c:	7110                	ld	a2,32(a0)
    8000612e:	6194                	ld	a3,0(a1)
    80006130:	96b2                	add	a3,a3,a2
    80006132:	e194                	sd	a3,0(a1)
    80006134:	4589                	li	a1,2
    80006136:	14459073          	csrw	sip,a1
    8000613a:	6914                	ld	a3,16(a0)
    8000613c:	6510                	ld	a2,8(a0)
    8000613e:	610c                	ld	a1,0(a0)
    80006140:	34051573          	csrrw	a0,mscratch,a0
    80006144:	30200073          	mret
	...

000000008000614a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000614a:	1141                	addi	sp,sp,-16
    8000614c:	e422                	sd	s0,8(sp)
    8000614e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006150:	0c0007b7          	lui	a5,0xc000
    80006154:	4705                	li	a4,1
    80006156:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006158:	c3d8                	sw	a4,4(a5)
}
    8000615a:	6422                	ld	s0,8(sp)
    8000615c:	0141                	addi	sp,sp,16
    8000615e:	8082                	ret

0000000080006160 <plicinithart>:

void
plicinithart(void)
{
    80006160:	1141                	addi	sp,sp,-16
    80006162:	e406                	sd	ra,8(sp)
    80006164:	e022                	sd	s0,0(sp)
    80006166:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006168:	ffffc097          	auipc	ra,0xffffc
    8000616c:	940080e7          	jalr	-1728(ra) # 80001aa8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006170:	0085171b          	slliw	a4,a0,0x8
    80006174:	0c0027b7          	lui	a5,0xc002
    80006178:	97ba                	add	a5,a5,a4
    8000617a:	40200713          	li	a4,1026
    8000617e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006182:	00d5151b          	slliw	a0,a0,0xd
    80006186:	0c2017b7          	lui	a5,0xc201
    8000618a:	953e                	add	a0,a0,a5
    8000618c:	00052023          	sw	zero,0(a0)
}
    80006190:	60a2                	ld	ra,8(sp)
    80006192:	6402                	ld	s0,0(sp)
    80006194:	0141                	addi	sp,sp,16
    80006196:	8082                	ret

0000000080006198 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006198:	1141                	addi	sp,sp,-16
    8000619a:	e406                	sd	ra,8(sp)
    8000619c:	e022                	sd	s0,0(sp)
    8000619e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061a0:	ffffc097          	auipc	ra,0xffffc
    800061a4:	908080e7          	jalr	-1784(ra) # 80001aa8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061a8:	00d5179b          	slliw	a5,a0,0xd
    800061ac:	0c201537          	lui	a0,0xc201
    800061b0:	953e                	add	a0,a0,a5
  return irq;
}
    800061b2:	4148                	lw	a0,4(a0)
    800061b4:	60a2                	ld	ra,8(sp)
    800061b6:	6402                	ld	s0,0(sp)
    800061b8:	0141                	addi	sp,sp,16
    800061ba:	8082                	ret

00000000800061bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061bc:	1101                	addi	sp,sp,-32
    800061be:	ec06                	sd	ra,24(sp)
    800061c0:	e822                	sd	s0,16(sp)
    800061c2:	e426                	sd	s1,8(sp)
    800061c4:	1000                	addi	s0,sp,32
    800061c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061c8:	ffffc097          	auipc	ra,0xffffc
    800061cc:	8e0080e7          	jalr	-1824(ra) # 80001aa8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061d0:	00d5151b          	slliw	a0,a0,0xd
    800061d4:	0c2017b7          	lui	a5,0xc201
    800061d8:	97aa                	add	a5,a5,a0
    800061da:	c3c4                	sw	s1,4(a5)
}
    800061dc:	60e2                	ld	ra,24(sp)
    800061de:	6442                	ld	s0,16(sp)
    800061e0:	64a2                	ld	s1,8(sp)
    800061e2:	6105                	addi	sp,sp,32
    800061e4:	8082                	ret

00000000800061e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061e6:	1141                	addi	sp,sp,-16
    800061e8:	e406                	sd	ra,8(sp)
    800061ea:	e022                	sd	s0,0(sp)
    800061ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061ee:	479d                	li	a5,7
    800061f0:	06a7c963          	blt	a5,a0,80006262 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800061f4:	00016797          	auipc	a5,0x16
    800061f8:	e0c78793          	addi	a5,a5,-500 # 8001c000 <disk>
    800061fc:	00a78733          	add	a4,a5,a0
    80006200:	6789                	lui	a5,0x2
    80006202:	97ba                	add	a5,a5,a4
    80006204:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006208:	e7ad                	bnez	a5,80006272 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000620a:	00451793          	slli	a5,a0,0x4
    8000620e:	00018717          	auipc	a4,0x18
    80006212:	df270713          	addi	a4,a4,-526 # 8001e000 <disk+0x2000>
    80006216:	6314                	ld	a3,0(a4)
    80006218:	96be                	add	a3,a3,a5
    8000621a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000621e:	6314                	ld	a3,0(a4)
    80006220:	96be                	add	a3,a3,a5
    80006222:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006226:	6314                	ld	a3,0(a4)
    80006228:	96be                	add	a3,a3,a5
    8000622a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000622e:	6318                	ld	a4,0(a4)
    80006230:	97ba                	add	a5,a5,a4
    80006232:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006236:	00016797          	auipc	a5,0x16
    8000623a:	dca78793          	addi	a5,a5,-566 # 8001c000 <disk>
    8000623e:	97aa                	add	a5,a5,a0
    80006240:	6509                	lui	a0,0x2
    80006242:	953e                	add	a0,a0,a5
    80006244:	4785                	li	a5,1
    80006246:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000624a:	00018517          	auipc	a0,0x18
    8000624e:	dce50513          	addi	a0,a0,-562 # 8001e018 <disk+0x2018>
    80006252:	ffffc097          	auipc	ra,0xffffc
    80006256:	4e8080e7          	jalr	1256(ra) # 8000273a <wakeup>
}
    8000625a:	60a2                	ld	ra,8(sp)
    8000625c:	6402                	ld	s0,0(sp)
    8000625e:	0141                	addi	sp,sp,16
    80006260:	8082                	ret
    panic("free_desc 1");
    80006262:	00002517          	auipc	a0,0x2
    80006266:	55e50513          	addi	a0,a0,1374 # 800087c0 <syscalls+0x330>
    8000626a:	ffffa097          	auipc	ra,0xffffa
    8000626e:	2d4080e7          	jalr	724(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006272:	00002517          	auipc	a0,0x2
    80006276:	55e50513          	addi	a0,a0,1374 # 800087d0 <syscalls+0x340>
    8000627a:	ffffa097          	auipc	ra,0xffffa
    8000627e:	2c4080e7          	jalr	708(ra) # 8000053e <panic>

0000000080006282 <virtio_disk_init>:
{
    80006282:	1101                	addi	sp,sp,-32
    80006284:	ec06                	sd	ra,24(sp)
    80006286:	e822                	sd	s0,16(sp)
    80006288:	e426                	sd	s1,8(sp)
    8000628a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000628c:	00002597          	auipc	a1,0x2
    80006290:	55458593          	addi	a1,a1,1364 # 800087e0 <syscalls+0x350>
    80006294:	00018517          	auipc	a0,0x18
    80006298:	e9450513          	addi	a0,a0,-364 # 8001e128 <disk+0x2128>
    8000629c:	ffffb097          	auipc	ra,0xffffb
    800062a0:	8b8080e7          	jalr	-1864(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062a4:	100017b7          	lui	a5,0x10001
    800062a8:	4398                	lw	a4,0(a5)
    800062aa:	2701                	sext.w	a4,a4
    800062ac:	747277b7          	lui	a5,0x74727
    800062b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062b4:	0ef71163          	bne	a4,a5,80006396 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062b8:	100017b7          	lui	a5,0x10001
    800062bc:	43dc                	lw	a5,4(a5)
    800062be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062c0:	4705                	li	a4,1
    800062c2:	0ce79a63          	bne	a5,a4,80006396 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062c6:	100017b7          	lui	a5,0x10001
    800062ca:	479c                	lw	a5,8(a5)
    800062cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062ce:	4709                	li	a4,2
    800062d0:	0ce79363          	bne	a5,a4,80006396 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062d4:	100017b7          	lui	a5,0x10001
    800062d8:	47d8                	lw	a4,12(a5)
    800062da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062dc:	554d47b7          	lui	a5,0x554d4
    800062e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062e4:	0af71963          	bne	a4,a5,80006396 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062e8:	100017b7          	lui	a5,0x10001
    800062ec:	4705                	li	a4,1
    800062ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f0:	470d                	li	a4,3
    800062f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062f6:	c7ffe737          	lui	a4,0xc7ffe
    800062fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdf75f>
    800062fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006300:	2701                	sext.w	a4,a4
    80006302:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006304:	472d                	li	a4,11
    80006306:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006308:	473d                	li	a4,15
    8000630a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000630c:	6705                	lui	a4,0x1
    8000630e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006310:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006314:	5bdc                	lw	a5,52(a5)
    80006316:	2781                	sext.w	a5,a5
  if(max == 0)
    80006318:	c7d9                	beqz	a5,800063a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000631a:	471d                	li	a4,7
    8000631c:	08f77d63          	bgeu	a4,a5,800063b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006320:	100014b7          	lui	s1,0x10001
    80006324:	47a1                	li	a5,8
    80006326:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006328:	6609                	lui	a2,0x2
    8000632a:	4581                	li	a1,0
    8000632c:	00016517          	auipc	a0,0x16
    80006330:	cd450513          	addi	a0,a0,-812 # 8001c000 <disk>
    80006334:	ffffb097          	auipc	ra,0xffffb
    80006338:	9ac080e7          	jalr	-1620(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000633c:	00016717          	auipc	a4,0x16
    80006340:	cc470713          	addi	a4,a4,-828 # 8001c000 <disk>
    80006344:	00c75793          	srli	a5,a4,0xc
    80006348:	2781                	sext.w	a5,a5
    8000634a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000634c:	00018797          	auipc	a5,0x18
    80006350:	cb478793          	addi	a5,a5,-844 # 8001e000 <disk+0x2000>
    80006354:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006356:	00016717          	auipc	a4,0x16
    8000635a:	d2a70713          	addi	a4,a4,-726 # 8001c080 <disk+0x80>
    8000635e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006360:	00017717          	auipc	a4,0x17
    80006364:	ca070713          	addi	a4,a4,-864 # 8001d000 <disk+0x1000>
    80006368:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000636a:	4705                	li	a4,1
    8000636c:	00e78c23          	sb	a4,24(a5)
    80006370:	00e78ca3          	sb	a4,25(a5)
    80006374:	00e78d23          	sb	a4,26(a5)
    80006378:	00e78da3          	sb	a4,27(a5)
    8000637c:	00e78e23          	sb	a4,28(a5)
    80006380:	00e78ea3          	sb	a4,29(a5)
    80006384:	00e78f23          	sb	a4,30(a5)
    80006388:	00e78fa3          	sb	a4,31(a5)
}
    8000638c:	60e2                	ld	ra,24(sp)
    8000638e:	6442                	ld	s0,16(sp)
    80006390:	64a2                	ld	s1,8(sp)
    80006392:	6105                	addi	sp,sp,32
    80006394:	8082                	ret
    panic("could not find virtio disk");
    80006396:	00002517          	auipc	a0,0x2
    8000639a:	45a50513          	addi	a0,a0,1114 # 800087f0 <syscalls+0x360>
    8000639e:	ffffa097          	auipc	ra,0xffffa
    800063a2:	1a0080e7          	jalr	416(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063a6:	00002517          	auipc	a0,0x2
    800063aa:	46a50513          	addi	a0,a0,1130 # 80008810 <syscalls+0x380>
    800063ae:	ffffa097          	auipc	ra,0xffffa
    800063b2:	190080e7          	jalr	400(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800063b6:	00002517          	auipc	a0,0x2
    800063ba:	47a50513          	addi	a0,a0,1146 # 80008830 <syscalls+0x3a0>
    800063be:	ffffa097          	auipc	ra,0xffffa
    800063c2:	180080e7          	jalr	384(ra) # 8000053e <panic>

00000000800063c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063c6:	7159                	addi	sp,sp,-112
    800063c8:	f486                	sd	ra,104(sp)
    800063ca:	f0a2                	sd	s0,96(sp)
    800063cc:	eca6                	sd	s1,88(sp)
    800063ce:	e8ca                	sd	s2,80(sp)
    800063d0:	e4ce                	sd	s3,72(sp)
    800063d2:	e0d2                	sd	s4,64(sp)
    800063d4:	fc56                	sd	s5,56(sp)
    800063d6:	f85a                	sd	s6,48(sp)
    800063d8:	f45e                	sd	s7,40(sp)
    800063da:	f062                	sd	s8,32(sp)
    800063dc:	ec66                	sd	s9,24(sp)
    800063de:	e86a                	sd	s10,16(sp)
    800063e0:	1880                	addi	s0,sp,112
    800063e2:	892a                	mv	s2,a0
    800063e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063e6:	00c52c83          	lw	s9,12(a0)
    800063ea:	001c9c9b          	slliw	s9,s9,0x1
    800063ee:	1c82                	slli	s9,s9,0x20
    800063f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063f4:	00018517          	auipc	a0,0x18
    800063f8:	d3450513          	addi	a0,a0,-716 # 8001e128 <disk+0x2128>
    800063fc:	ffffa097          	auipc	ra,0xffffa
    80006400:	7e8080e7          	jalr	2024(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006404:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006406:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006408:	00016b97          	auipc	s7,0x16
    8000640c:	bf8b8b93          	addi	s7,s7,-1032 # 8001c000 <disk>
    80006410:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006412:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006414:	8a4e                	mv	s4,s3
    80006416:	a051                	j	8000649a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006418:	00fb86b3          	add	a3,s7,a5
    8000641c:	96da                	add	a3,a3,s6
    8000641e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006422:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006424:	0207c563          	bltz	a5,8000644e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006428:	2485                	addiw	s1,s1,1
    8000642a:	0711                	addi	a4,a4,4
    8000642c:	25548063          	beq	s1,s5,8000666c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006430:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006432:	00018697          	auipc	a3,0x18
    80006436:	be668693          	addi	a3,a3,-1050 # 8001e018 <disk+0x2018>
    8000643a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000643c:	0006c583          	lbu	a1,0(a3)
    80006440:	fde1                	bnez	a1,80006418 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006442:	2785                	addiw	a5,a5,1
    80006444:	0685                	addi	a3,a3,1
    80006446:	ff879be3          	bne	a5,s8,8000643c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000644a:	57fd                	li	a5,-1
    8000644c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000644e:	02905a63          	blez	s1,80006482 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006452:	f9042503          	lw	a0,-112(s0)
    80006456:	00000097          	auipc	ra,0x0
    8000645a:	d90080e7          	jalr	-624(ra) # 800061e6 <free_desc>
      for(int j = 0; j < i; j++)
    8000645e:	4785                	li	a5,1
    80006460:	0297d163          	bge	a5,s1,80006482 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006464:	f9442503          	lw	a0,-108(s0)
    80006468:	00000097          	auipc	ra,0x0
    8000646c:	d7e080e7          	jalr	-642(ra) # 800061e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006470:	4789                	li	a5,2
    80006472:	0097d863          	bge	a5,s1,80006482 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006476:	f9842503          	lw	a0,-104(s0)
    8000647a:	00000097          	auipc	ra,0x0
    8000647e:	d6c080e7          	jalr	-660(ra) # 800061e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006482:	00018597          	auipc	a1,0x18
    80006486:	ca658593          	addi	a1,a1,-858 # 8001e128 <disk+0x2128>
    8000648a:	00018517          	auipc	a0,0x18
    8000648e:	b8e50513          	addi	a0,a0,-1138 # 8001e018 <disk+0x2018>
    80006492:	ffffc097          	auipc	ra,0xffffc
    80006496:	11c080e7          	jalr	284(ra) # 800025ae <sleep>
  for(int i = 0; i < 3; i++){
    8000649a:	f9040713          	addi	a4,s0,-112
    8000649e:	84ce                	mv	s1,s3
    800064a0:	bf41                	j	80006430 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064a2:	20058713          	addi	a4,a1,512
    800064a6:	00471693          	slli	a3,a4,0x4
    800064aa:	00016717          	auipc	a4,0x16
    800064ae:	b5670713          	addi	a4,a4,-1194 # 8001c000 <disk>
    800064b2:	9736                	add	a4,a4,a3
    800064b4:	4685                	li	a3,1
    800064b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064ba:	20058713          	addi	a4,a1,512
    800064be:	00471693          	slli	a3,a4,0x4
    800064c2:	00016717          	auipc	a4,0x16
    800064c6:	b3e70713          	addi	a4,a4,-1218 # 8001c000 <disk>
    800064ca:	9736                	add	a4,a4,a3
    800064cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064d4:	7679                	lui	a2,0xffffe
    800064d6:	963e                	add	a2,a2,a5
    800064d8:	00018697          	auipc	a3,0x18
    800064dc:	b2868693          	addi	a3,a3,-1240 # 8001e000 <disk+0x2000>
    800064e0:	6298                	ld	a4,0(a3)
    800064e2:	9732                	add	a4,a4,a2
    800064e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064e6:	6298                	ld	a4,0(a3)
    800064e8:	9732                	add	a4,a4,a2
    800064ea:	4541                	li	a0,16
    800064ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064ee:	6298                	ld	a4,0(a3)
    800064f0:	9732                	add	a4,a4,a2
    800064f2:	4505                	li	a0,1
    800064f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800064f8:	f9442703          	lw	a4,-108(s0)
    800064fc:	6288                	ld	a0,0(a3)
    800064fe:	962a                	add	a2,a2,a0
    80006500:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdf00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006504:	0712                	slli	a4,a4,0x4
    80006506:	6290                	ld	a2,0(a3)
    80006508:	963a                	add	a2,a2,a4
    8000650a:	05890513          	addi	a0,s2,88
    8000650e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006510:	6294                	ld	a3,0(a3)
    80006512:	96ba                	add	a3,a3,a4
    80006514:	40000613          	li	a2,1024
    80006518:	c690                	sw	a2,8(a3)
  if(write)
    8000651a:	140d0063          	beqz	s10,8000665a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000651e:	00018697          	auipc	a3,0x18
    80006522:	ae26b683          	ld	a3,-1310(a3) # 8001e000 <disk+0x2000>
    80006526:	96ba                	add	a3,a3,a4
    80006528:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000652c:	00016817          	auipc	a6,0x16
    80006530:	ad480813          	addi	a6,a6,-1324 # 8001c000 <disk>
    80006534:	00018517          	auipc	a0,0x18
    80006538:	acc50513          	addi	a0,a0,-1332 # 8001e000 <disk+0x2000>
    8000653c:	6114                	ld	a3,0(a0)
    8000653e:	96ba                	add	a3,a3,a4
    80006540:	00c6d603          	lhu	a2,12(a3)
    80006544:	00166613          	ori	a2,a2,1
    80006548:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000654c:	f9842683          	lw	a3,-104(s0)
    80006550:	6110                	ld	a2,0(a0)
    80006552:	9732                	add	a4,a4,a2
    80006554:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006558:	20058613          	addi	a2,a1,512
    8000655c:	0612                	slli	a2,a2,0x4
    8000655e:	9642                	add	a2,a2,a6
    80006560:	577d                	li	a4,-1
    80006562:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006566:	00469713          	slli	a4,a3,0x4
    8000656a:	6114                	ld	a3,0(a0)
    8000656c:	96ba                	add	a3,a3,a4
    8000656e:	03078793          	addi	a5,a5,48
    80006572:	97c2                	add	a5,a5,a6
    80006574:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006576:	611c                	ld	a5,0(a0)
    80006578:	97ba                	add	a5,a5,a4
    8000657a:	4685                	li	a3,1
    8000657c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000657e:	611c                	ld	a5,0(a0)
    80006580:	97ba                	add	a5,a5,a4
    80006582:	4809                	li	a6,2
    80006584:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006588:	611c                	ld	a5,0(a0)
    8000658a:	973e                	add	a4,a4,a5
    8000658c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006590:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006594:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006598:	6518                	ld	a4,8(a0)
    8000659a:	00275783          	lhu	a5,2(a4)
    8000659e:	8b9d                	andi	a5,a5,7
    800065a0:	0786                	slli	a5,a5,0x1
    800065a2:	97ba                	add	a5,a5,a4
    800065a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065ac:	6518                	ld	a4,8(a0)
    800065ae:	00275783          	lhu	a5,2(a4)
    800065b2:	2785                	addiw	a5,a5,1
    800065b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065bc:	100017b7          	lui	a5,0x10001
    800065c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065c4:	00492703          	lw	a4,4(s2)
    800065c8:	4785                	li	a5,1
    800065ca:	02f71163          	bne	a4,a5,800065ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065ce:	00018997          	auipc	s3,0x18
    800065d2:	b5a98993          	addi	s3,s3,-1190 # 8001e128 <disk+0x2128>
  while(b->disk == 1) {
    800065d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065d8:	85ce                	mv	a1,s3
    800065da:	854a                	mv	a0,s2
    800065dc:	ffffc097          	auipc	ra,0xffffc
    800065e0:	fd2080e7          	jalr	-46(ra) # 800025ae <sleep>
  while(b->disk == 1) {
    800065e4:	00492783          	lw	a5,4(s2)
    800065e8:	fe9788e3          	beq	a5,s1,800065d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800065ec:	f9042903          	lw	s2,-112(s0)
    800065f0:	20090793          	addi	a5,s2,512
    800065f4:	00479713          	slli	a4,a5,0x4
    800065f8:	00016797          	auipc	a5,0x16
    800065fc:	a0878793          	addi	a5,a5,-1528 # 8001c000 <disk>
    80006600:	97ba                	add	a5,a5,a4
    80006602:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006606:	00018997          	auipc	s3,0x18
    8000660a:	9fa98993          	addi	s3,s3,-1542 # 8001e000 <disk+0x2000>
    8000660e:	00491713          	slli	a4,s2,0x4
    80006612:	0009b783          	ld	a5,0(s3)
    80006616:	97ba                	add	a5,a5,a4
    80006618:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000661c:	854a                	mv	a0,s2
    8000661e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006622:	00000097          	auipc	ra,0x0
    80006626:	bc4080e7          	jalr	-1084(ra) # 800061e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000662a:	8885                	andi	s1,s1,1
    8000662c:	f0ed                	bnez	s1,8000660e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000662e:	00018517          	auipc	a0,0x18
    80006632:	afa50513          	addi	a0,a0,-1286 # 8001e128 <disk+0x2128>
    80006636:	ffffa097          	auipc	ra,0xffffa
    8000663a:	662080e7          	jalr	1634(ra) # 80000c98 <release>
}
    8000663e:	70a6                	ld	ra,104(sp)
    80006640:	7406                	ld	s0,96(sp)
    80006642:	64e6                	ld	s1,88(sp)
    80006644:	6946                	ld	s2,80(sp)
    80006646:	69a6                	ld	s3,72(sp)
    80006648:	6a06                	ld	s4,64(sp)
    8000664a:	7ae2                	ld	s5,56(sp)
    8000664c:	7b42                	ld	s6,48(sp)
    8000664e:	7ba2                	ld	s7,40(sp)
    80006650:	7c02                	ld	s8,32(sp)
    80006652:	6ce2                	ld	s9,24(sp)
    80006654:	6d42                	ld	s10,16(sp)
    80006656:	6165                	addi	sp,sp,112
    80006658:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000665a:	00018697          	auipc	a3,0x18
    8000665e:	9a66b683          	ld	a3,-1626(a3) # 8001e000 <disk+0x2000>
    80006662:	96ba                	add	a3,a3,a4
    80006664:	4609                	li	a2,2
    80006666:	00c69623          	sh	a2,12(a3)
    8000666a:	b5c9                	j	8000652c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000666c:	f9042583          	lw	a1,-112(s0)
    80006670:	20058793          	addi	a5,a1,512
    80006674:	0792                	slli	a5,a5,0x4
    80006676:	00016517          	auipc	a0,0x16
    8000667a:	a3250513          	addi	a0,a0,-1486 # 8001c0a8 <disk+0xa8>
    8000667e:	953e                	add	a0,a0,a5
  if(write)
    80006680:	e20d11e3          	bnez	s10,800064a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006684:	20058713          	addi	a4,a1,512
    80006688:	00471693          	slli	a3,a4,0x4
    8000668c:	00016717          	auipc	a4,0x16
    80006690:	97470713          	addi	a4,a4,-1676 # 8001c000 <disk>
    80006694:	9736                	add	a4,a4,a3
    80006696:	0a072423          	sw	zero,168(a4)
    8000669a:	b505                	j	800064ba <virtio_disk_rw+0xf4>

000000008000669c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000669c:	1101                	addi	sp,sp,-32
    8000669e:	ec06                	sd	ra,24(sp)
    800066a0:	e822                	sd	s0,16(sp)
    800066a2:	e426                	sd	s1,8(sp)
    800066a4:	e04a                	sd	s2,0(sp)
    800066a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066a8:	00018517          	auipc	a0,0x18
    800066ac:	a8050513          	addi	a0,a0,-1408 # 8001e128 <disk+0x2128>
    800066b0:	ffffa097          	auipc	ra,0xffffa
    800066b4:	534080e7          	jalr	1332(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066b8:	10001737          	lui	a4,0x10001
    800066bc:	533c                	lw	a5,96(a4)
    800066be:	8b8d                	andi	a5,a5,3
    800066c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066c6:	00018797          	auipc	a5,0x18
    800066ca:	93a78793          	addi	a5,a5,-1734 # 8001e000 <disk+0x2000>
    800066ce:	6b94                	ld	a3,16(a5)
    800066d0:	0207d703          	lhu	a4,32(a5)
    800066d4:	0026d783          	lhu	a5,2(a3)
    800066d8:	06f70163          	beq	a4,a5,8000673a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066dc:	00016917          	auipc	s2,0x16
    800066e0:	92490913          	addi	s2,s2,-1756 # 8001c000 <disk>
    800066e4:	00018497          	auipc	s1,0x18
    800066e8:	91c48493          	addi	s1,s1,-1764 # 8001e000 <disk+0x2000>
    __sync_synchronize();
    800066ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066f0:	6898                	ld	a4,16(s1)
    800066f2:	0204d783          	lhu	a5,32(s1)
    800066f6:	8b9d                	andi	a5,a5,7
    800066f8:	078e                	slli	a5,a5,0x3
    800066fa:	97ba                	add	a5,a5,a4
    800066fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066fe:	20078713          	addi	a4,a5,512
    80006702:	0712                	slli	a4,a4,0x4
    80006704:	974a                	add	a4,a4,s2
    80006706:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000670a:	e731                	bnez	a4,80006756 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000670c:	20078793          	addi	a5,a5,512
    80006710:	0792                	slli	a5,a5,0x4
    80006712:	97ca                	add	a5,a5,s2
    80006714:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006716:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000671a:	ffffc097          	auipc	ra,0xffffc
    8000671e:	020080e7          	jalr	32(ra) # 8000273a <wakeup>

    disk.used_idx += 1;
    80006722:	0204d783          	lhu	a5,32(s1)
    80006726:	2785                	addiw	a5,a5,1
    80006728:	17c2                	slli	a5,a5,0x30
    8000672a:	93c1                	srli	a5,a5,0x30
    8000672c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006730:	6898                	ld	a4,16(s1)
    80006732:	00275703          	lhu	a4,2(a4)
    80006736:	faf71be3          	bne	a4,a5,800066ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000673a:	00018517          	auipc	a0,0x18
    8000673e:	9ee50513          	addi	a0,a0,-1554 # 8001e128 <disk+0x2128>
    80006742:	ffffa097          	auipc	ra,0xffffa
    80006746:	556080e7          	jalr	1366(ra) # 80000c98 <release>
}
    8000674a:	60e2                	ld	ra,24(sp)
    8000674c:	6442                	ld	s0,16(sp)
    8000674e:	64a2                	ld	s1,8(sp)
    80006750:	6902                	ld	s2,0(sp)
    80006752:	6105                	addi	sp,sp,32
    80006754:	8082                	ret
      panic("virtio_disk_intr status");
    80006756:	00002517          	auipc	a0,0x2
    8000675a:	0fa50513          	addi	a0,a0,250 # 80008850 <syscalls+0x3c0>
    8000675e:	ffffa097          	auipc	ra,0xffffa
    80006762:	de0080e7          	jalr	-544(ra) # 8000053e <panic>
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
