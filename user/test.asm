
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <pause_system_dem>:
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void pause_system_dem(int interval, int pause_seconds, int loop_size) {
   0:	715d                	addi	sp,sp,-80
   2:	e486                	sd	ra,72(sp)
   4:	e0a2                	sd	s0,64(sp)
   6:	fc26                	sd	s1,56(sp)
   8:	f84a                	sd	s2,48(sp)
   a:	f44e                	sd	s3,40(sp)
   c:	f052                	sd	s4,32(sp)
   e:	ec56                	sd	s5,24(sp)
  10:	e85a                	sd	s6,16(sp)
  12:	e45e                	sd	s7,8(sp)
  14:	0880                	addi	s0,sp,80
  16:	8a2a                	mv	s4,a0
  18:	8b2e                	mv	s6,a1
  1a:	8932                	mv	s2,a2
    int pid = getpid();
  1c:	00000097          	auipc	ra,0x0
  20:	520080e7          	jalr	1312(ra) # 53c <getpid>
    for (int i = 0; i < loop_size; i++) {
  24:	05205b63          	blez	s2,7a <pause_system_dem+0x7a>
  28:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  2a:	01f9599b          	srliw	s3,s2,0x1f
  2e:	012989bb          	addw	s3,s3,s2
  32:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  36:	4481                	li	s1,0
            printf("pause system %d/%d completed.\n", i, loop_size);
  38:	00001b97          	auipc	s7,0x1
  3c:	9b8b8b93          	addi	s7,s7,-1608 # 9f0 <malloc+0xe6>
  40:	a031                	j	4c <pause_system_dem+0x4c>
        if (i == loop_size / 2) {
  42:	02998663          	beq	s3,s1,6e <pause_system_dem+0x6e>
    for (int i = 0; i < loop_size; i++) {
  46:	2485                	addiw	s1,s1,1
  48:	02990963          	beq	s2,s1,7a <pause_system_dem+0x7a>
        if (i % interval == 0 && pid == getpid()) {
  4c:	0344e7bb          	remw	a5,s1,s4
  50:	fbed                	bnez	a5,42 <pause_system_dem+0x42>
  52:	00000097          	auipc	ra,0x0
  56:	4ea080e7          	jalr	1258(ra) # 53c <getpid>
  5a:	ff5514e3          	bne	a0,s5,42 <pause_system_dem+0x42>
            printf("pause system %d/%d completed.\n", i, loop_size);
  5e:	864a                	mv	a2,s2
  60:	85a6                	mv	a1,s1
  62:	855e                	mv	a0,s7
  64:	00000097          	auipc	ra,0x0
  68:	7e8080e7          	jalr	2024(ra) # 84c <printf>
  6c:	bfd9                	j	42 <pause_system_dem+0x42>
            pause_system(pause_seconds);
  6e:	855a                	mv	a0,s6
  70:	00000097          	auipc	ra,0x0
  74:	4ec080e7          	jalr	1260(ra) # 55c <pause_system>
  78:	b7f9                	j	46 <pause_system_dem+0x46>
        }
    }
    printf("\n");
  7a:	00001517          	auipc	a0,0x1
  7e:	99650513          	addi	a0,a0,-1642 # a10 <malloc+0x106>
  82:	00000097          	auipc	ra,0x0
  86:	7ca080e7          	jalr	1994(ra) # 84c <printf>
}
  8a:	60a6                	ld	ra,72(sp)
  8c:	6406                	ld	s0,64(sp)
  8e:	74e2                	ld	s1,56(sp)
  90:	7942                	ld	s2,48(sp)
  92:	79a2                	ld	s3,40(sp)
  94:	7a02                	ld	s4,32(sp)
  96:	6ae2                	ld	s5,24(sp)
  98:	6b42                	ld	s6,16(sp)
  9a:	6ba2                	ld	s7,8(sp)
  9c:	6161                	addi	sp,sp,80
  9e:	8082                	ret

00000000000000a0 <kill_system_dem>:

void kill_system_dem(int interval, int loop_size) {
  a0:	7139                	addi	sp,sp,-64
  a2:	fc06                	sd	ra,56(sp)
  a4:	f822                	sd	s0,48(sp)
  a6:	f426                	sd	s1,40(sp)
  a8:	f04a                	sd	s2,32(sp)
  aa:	ec4e                	sd	s3,24(sp)
  ac:	e852                	sd	s4,16(sp)
  ae:	e456                	sd	s5,8(sp)
  b0:	e05a                	sd	s6,0(sp)
  b2:	0080                	addi	s0,sp,64
  b4:	8a2a                	mv	s4,a0
  b6:	892e                	mv	s2,a1
    int pid = getpid();
  b8:	00000097          	auipc	ra,0x0
  bc:	484080e7          	jalr	1156(ra) # 53c <getpid>
    for (int i = 0; i < loop_size; i++) {
  c0:	05205a63          	blez	s2,114 <kill_system_dem+0x74>
  c4:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  c6:	01f9599b          	srliw	s3,s2,0x1f
  ca:	012989bb          	addw	s3,s3,s2
  ce:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  d2:	4481                	li	s1,0
            printf("kill system %d/%d completed.\n", i, loop_size);
  d4:	00001b17          	auipc	s6,0x1
  d8:	944b0b13          	addi	s6,s6,-1724 # a18 <malloc+0x10e>
  dc:	a031                	j	e8 <kill_system_dem+0x48>
        if (i == loop_size / 2) {
  de:	02998663          	beq	s3,s1,10a <kill_system_dem+0x6a>
    for (int i = 0; i < loop_size; i++) {
  e2:	2485                	addiw	s1,s1,1
  e4:	02990863          	beq	s2,s1,114 <kill_system_dem+0x74>
        if (i % interval == 0 && pid == getpid()) {
  e8:	0344e7bb          	remw	a5,s1,s4
  ec:	fbed                	bnez	a5,de <kill_system_dem+0x3e>
  ee:	00000097          	auipc	ra,0x0
  f2:	44e080e7          	jalr	1102(ra) # 53c <getpid>
  f6:	ff5514e3          	bne	a0,s5,de <kill_system_dem+0x3e>
            printf("kill system %d/%d completed.\n", i, loop_size);
  fa:	864a                	mv	a2,s2
  fc:	85a6                	mv	a1,s1
  fe:	855a                	mv	a0,s6
 100:	00000097          	auipc	ra,0x0
 104:	74c080e7          	jalr	1868(ra) # 84c <printf>
 108:	bfd9                	j	de <kill_system_dem+0x3e>
            kill_system();
 10a:	00000097          	auipc	ra,0x0
 10e:	45a080e7          	jalr	1114(ra) # 564 <kill_system>
 112:	bfc1                	j	e2 <kill_system_dem+0x42>
        }
    }
    printf("\n");
 114:	00001517          	auipc	a0,0x1
 118:	8fc50513          	addi	a0,a0,-1796 # a10 <malloc+0x106>
 11c:	00000097          	auipc	ra,0x0
 120:	730080e7          	jalr	1840(ra) # 84c <printf>
}
 124:	70e2                	ld	ra,56(sp)
 126:	7442                	ld	s0,48(sp)
 128:	74a2                	ld	s1,40(sp)
 12a:	7902                	ld	s2,32(sp)
 12c:	69e2                	ld	s3,24(sp)
 12e:	6a42                	ld	s4,16(sp)
 130:	6aa2                	ld	s5,8(sp)
 132:	6b02                	ld	s6,0(sp)
 134:	6121                	addi	sp,sp,64
 136:	8082                	ret

0000000000000138 <env>:

void env(int size, int interval, char* env_name) {
 138:	715d                	addi	sp,sp,-80
 13a:	e486                	sd	ra,72(sp)
 13c:	e0a2                	sd	s0,64(sp)
 13e:	fc26                	sd	s1,56(sp)
 140:	f84a                	sd	s2,48(sp)
 142:	f44e                	sd	s3,40(sp)
 144:	f052                	sd	s4,32(sp)
 146:	ec56                	sd	s5,24(sp)
 148:	e85a                	sd	s6,16(sp)
 14a:	e45e                	sd	s7,8(sp)
 14c:	0880                	addi	s0,sp,80
 14e:	8ab2                	mv	s5,a2
    int result = 1;
    int loop_size = 1000000;
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
 150:	00000097          	auipc	ra,0x0
 154:	364080e7          	jalr	868(ra) # 4b4 <fork>
 158:	00000097          	auipc	ra,0x0
 15c:	35c080e7          	jalr	860(ra) # 4b4 <fork>
 160:	8a2a                	mv	s4,a0
    }
    for (int i = 0; i < loop_size; i++) {
 162:	4481                	li	s1,0
        if (i % (int)(loop_size / 10) == 0) {
 164:	69e1                	lui	s3,0x18
 166:	6a09899b          	addiw	s3,s3,1696
        	if (pid == 0) {
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
        	} else {
        		printf(" ");
 16a:	00001b97          	auipc	s7,0x1
 16e:	8e6b8b93          	addi	s7,s7,-1818 # a50 <malloc+0x146>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 172:	000f4937          	lui	s2,0xf4
 176:	24090913          	addi	s2,s2,576 # f4240 <__global_pointer$+0xf2faf>
 17a:	00001b17          	auipc	s6,0x1
 17e:	8beb0b13          	addi	s6,s6,-1858 # a38 <malloc+0x12e>
 182:	a809                	j	194 <env+0x5c>
        		printf(" ");
 184:	855e                	mv	a0,s7
 186:	00000097          	auipc	ra,0x0
 18a:	6c6080e7          	jalr	1734(ra) # 84c <printf>
    for (int i = 0; i < loop_size; i++) {
 18e:	2485                	addiw	s1,s1,1
 190:	03248063          	beq	s1,s2,1b0 <env+0x78>
        if (i % (int)(loop_size / 10) == 0) {
 194:	0334e7bb          	remw	a5,s1,s3
 198:	fbfd                	bnez	a5,18e <env+0x56>
        	if (pid == 0) {
 19a:	fe0a15e3          	bnez	s4,184 <env+0x4c>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 19e:	86ca                	mv	a3,s2
 1a0:	8626                	mv	a2,s1
 1a2:	85d6                	mv	a1,s5
 1a4:	855a                	mv	a0,s6
 1a6:	00000097          	auipc	ra,0x0
 1aa:	6a6080e7          	jalr	1702(ra) # 84c <printf>
 1ae:	b7c5                	j	18e <env+0x56>
        }
        if (i % interval == 0) {
            result = result * size;
        }
    }
    printf("\n");
 1b0:	00001517          	auipc	a0,0x1
 1b4:	86050513          	addi	a0,a0,-1952 # a10 <malloc+0x106>
 1b8:	00000097          	auipc	ra,0x0
 1bc:	694080e7          	jalr	1684(ra) # 84c <printf>
}
 1c0:	60a6                	ld	ra,72(sp)
 1c2:	6406                	ld	s0,64(sp)
 1c4:	74e2                	ld	s1,56(sp)
 1c6:	7942                	ld	s2,48(sp)
 1c8:	79a2                	ld	s3,40(sp)
 1ca:	7a02                	ld	s4,32(sp)
 1cc:	6ae2                	ld	s5,24(sp)
 1ce:	6b42                	ld	s6,16(sp)
 1d0:	6ba2                	ld	s7,8(sp)
 1d2:	6161                	addi	sp,sp,80
 1d4:	8082                	ret

00000000000001d6 <env_large>:

void env_large() {
 1d6:	1141                	addi	sp,sp,-16
 1d8:	e406                	sd	ra,8(sp)
 1da:	e022                	sd	s0,0(sp)
 1dc:	0800                	addi	s0,sp,16
    env(1000000, 1000000, "env_large");
 1de:	00001617          	auipc	a2,0x1
 1e2:	87a60613          	addi	a2,a2,-1926 # a58 <malloc+0x14e>
 1e6:	000f45b7          	lui	a1,0xf4
 1ea:	24058593          	addi	a1,a1,576 # f4240 <__global_pointer$+0xf2faf>
 1ee:	852e                	mv	a0,a1
 1f0:	00000097          	auipc	ra,0x0
 1f4:	f48080e7          	jalr	-184(ra) # 138 <env>
}
 1f8:	60a2                	ld	ra,8(sp)
 1fa:	6402                	ld	s0,0(sp)
 1fc:	0141                	addi	sp,sp,16
 1fe:	8082                	ret

0000000000000200 <env_freq>:

void env_freq() {
 200:	1141                	addi	sp,sp,-16
 202:	e406                	sd	ra,8(sp)
 204:	e022                	sd	s0,0(sp)
 206:	0800                	addi	s0,sp,16
    env(10, 10, "env_freq");
 208:	00001617          	auipc	a2,0x1
 20c:	86060613          	addi	a2,a2,-1952 # a68 <malloc+0x15e>
 210:	45a9                	li	a1,10
 212:	4529                	li	a0,10
 214:	00000097          	auipc	ra,0x0
 218:	f24080e7          	jalr	-220(ra) # 138 <env>
}
 21c:	60a2                	ld	ra,8(sp)
 21e:	6402                	ld	s0,0(sp)
 220:	0141                	addi	sp,sp,16
 222:	8082                	ret

0000000000000224 <main>:


int
main(int argc, char *argv[])
{
 224:	1141                	addi	sp,sp,-16
 226:	e406                	sd	ra,8(sp)
 228:	e022                	sd	s0,0(sp)
 22a:	0800                	addi	s0,sp,16
    env_large();
 22c:	00000097          	auipc	ra,0x0
 230:	faa080e7          	jalr	-86(ra) # 1d6 <env_large>
    env_freq();
 234:	00000097          	auipc	ra,0x0
 238:	fcc080e7          	jalr	-52(ra) # 200 <env_freq>
    exit(0);
 23c:	4501                	li	a0,0
 23e:	00000097          	auipc	ra,0x0
 242:	27e080e7          	jalr	638(ra) # 4bc <exit>

0000000000000246 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 246:	1141                	addi	sp,sp,-16
 248:	e422                	sd	s0,8(sp)
 24a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 24c:	87aa                	mv	a5,a0
 24e:	0585                	addi	a1,a1,1
 250:	0785                	addi	a5,a5,1
 252:	fff5c703          	lbu	a4,-1(a1)
 256:	fee78fa3          	sb	a4,-1(a5)
 25a:	fb75                	bnez	a4,24e <strcpy+0x8>
    ;
  return os;
}
 25c:	6422                	ld	s0,8(sp)
 25e:	0141                	addi	sp,sp,16
 260:	8082                	ret

0000000000000262 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 262:	1141                	addi	sp,sp,-16
 264:	e422                	sd	s0,8(sp)
 266:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 268:	00054783          	lbu	a5,0(a0)
 26c:	cb91                	beqz	a5,280 <strcmp+0x1e>
 26e:	0005c703          	lbu	a4,0(a1)
 272:	00f71763          	bne	a4,a5,280 <strcmp+0x1e>
    p++, q++;
 276:	0505                	addi	a0,a0,1
 278:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 27a:	00054783          	lbu	a5,0(a0)
 27e:	fbe5                	bnez	a5,26e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 280:	0005c503          	lbu	a0,0(a1)
}
 284:	40a7853b          	subw	a0,a5,a0
 288:	6422                	ld	s0,8(sp)
 28a:	0141                	addi	sp,sp,16
 28c:	8082                	ret

000000000000028e <strlen>:

uint
strlen(const char *s)
{
 28e:	1141                	addi	sp,sp,-16
 290:	e422                	sd	s0,8(sp)
 292:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 294:	00054783          	lbu	a5,0(a0)
 298:	cf91                	beqz	a5,2b4 <strlen+0x26>
 29a:	0505                	addi	a0,a0,1
 29c:	87aa                	mv	a5,a0
 29e:	4685                	li	a3,1
 2a0:	9e89                	subw	a3,a3,a0
 2a2:	00f6853b          	addw	a0,a3,a5
 2a6:	0785                	addi	a5,a5,1
 2a8:	fff7c703          	lbu	a4,-1(a5)
 2ac:	fb7d                	bnez	a4,2a2 <strlen+0x14>
    ;
  return n;
}
 2ae:	6422                	ld	s0,8(sp)
 2b0:	0141                	addi	sp,sp,16
 2b2:	8082                	ret
  for(n = 0; s[n]; n++)
 2b4:	4501                	li	a0,0
 2b6:	bfe5                	j	2ae <strlen+0x20>

00000000000002b8 <memset>:

void*
memset(void *dst, int c, uint n)
{
 2b8:	1141                	addi	sp,sp,-16
 2ba:	e422                	sd	s0,8(sp)
 2bc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2be:	ce09                	beqz	a2,2d8 <memset+0x20>
 2c0:	87aa                	mv	a5,a0
 2c2:	fff6071b          	addiw	a4,a2,-1
 2c6:	1702                	slli	a4,a4,0x20
 2c8:	9301                	srli	a4,a4,0x20
 2ca:	0705                	addi	a4,a4,1
 2cc:	972a                	add	a4,a4,a0
    cdst[i] = c;
 2ce:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2d2:	0785                	addi	a5,a5,1
 2d4:	fee79de3          	bne	a5,a4,2ce <memset+0x16>
  }
  return dst;
}
 2d8:	6422                	ld	s0,8(sp)
 2da:	0141                	addi	sp,sp,16
 2dc:	8082                	ret

00000000000002de <strchr>:

char*
strchr(const char *s, char c)
{
 2de:	1141                	addi	sp,sp,-16
 2e0:	e422                	sd	s0,8(sp)
 2e2:	0800                	addi	s0,sp,16
  for(; *s; s++)
 2e4:	00054783          	lbu	a5,0(a0)
 2e8:	cb99                	beqz	a5,2fe <strchr+0x20>
    if(*s == c)
 2ea:	00f58763          	beq	a1,a5,2f8 <strchr+0x1a>
  for(; *s; s++)
 2ee:	0505                	addi	a0,a0,1
 2f0:	00054783          	lbu	a5,0(a0)
 2f4:	fbfd                	bnez	a5,2ea <strchr+0xc>
      return (char*)s;
  return 0;
 2f6:	4501                	li	a0,0
}
 2f8:	6422                	ld	s0,8(sp)
 2fa:	0141                	addi	sp,sp,16
 2fc:	8082                	ret
  return 0;
 2fe:	4501                	li	a0,0
 300:	bfe5                	j	2f8 <strchr+0x1a>

0000000000000302 <gets>:

char*
gets(char *buf, int max)
{
 302:	711d                	addi	sp,sp,-96
 304:	ec86                	sd	ra,88(sp)
 306:	e8a2                	sd	s0,80(sp)
 308:	e4a6                	sd	s1,72(sp)
 30a:	e0ca                	sd	s2,64(sp)
 30c:	fc4e                	sd	s3,56(sp)
 30e:	f852                	sd	s4,48(sp)
 310:	f456                	sd	s5,40(sp)
 312:	f05a                	sd	s6,32(sp)
 314:	ec5e                	sd	s7,24(sp)
 316:	1080                	addi	s0,sp,96
 318:	8baa                	mv	s7,a0
 31a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 31c:	892a                	mv	s2,a0
 31e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 320:	4aa9                	li	s5,10
 322:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 324:	89a6                	mv	s3,s1
 326:	2485                	addiw	s1,s1,1
 328:	0344d863          	bge	s1,s4,358 <gets+0x56>
    cc = read(0, &c, 1);
 32c:	4605                	li	a2,1
 32e:	faf40593          	addi	a1,s0,-81
 332:	4501                	li	a0,0
 334:	00000097          	auipc	ra,0x0
 338:	1a0080e7          	jalr	416(ra) # 4d4 <read>
    if(cc < 1)
 33c:	00a05e63          	blez	a0,358 <gets+0x56>
    buf[i++] = c;
 340:	faf44783          	lbu	a5,-81(s0)
 344:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 348:	01578763          	beq	a5,s5,356 <gets+0x54>
 34c:	0905                	addi	s2,s2,1
 34e:	fd679be3          	bne	a5,s6,324 <gets+0x22>
  for(i=0; i+1 < max; ){
 352:	89a6                	mv	s3,s1
 354:	a011                	j	358 <gets+0x56>
 356:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 358:	99de                	add	s3,s3,s7
 35a:	00098023          	sb	zero,0(s3) # 18000 <__global_pointer$+0x16d6f>
  return buf;
}
 35e:	855e                	mv	a0,s7
 360:	60e6                	ld	ra,88(sp)
 362:	6446                	ld	s0,80(sp)
 364:	64a6                	ld	s1,72(sp)
 366:	6906                	ld	s2,64(sp)
 368:	79e2                	ld	s3,56(sp)
 36a:	7a42                	ld	s4,48(sp)
 36c:	7aa2                	ld	s5,40(sp)
 36e:	7b02                	ld	s6,32(sp)
 370:	6be2                	ld	s7,24(sp)
 372:	6125                	addi	sp,sp,96
 374:	8082                	ret

0000000000000376 <stat>:

int
stat(const char *n, struct stat *st)
{
 376:	1101                	addi	sp,sp,-32
 378:	ec06                	sd	ra,24(sp)
 37a:	e822                	sd	s0,16(sp)
 37c:	e426                	sd	s1,8(sp)
 37e:	e04a                	sd	s2,0(sp)
 380:	1000                	addi	s0,sp,32
 382:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 384:	4581                	li	a1,0
 386:	00000097          	auipc	ra,0x0
 38a:	176080e7          	jalr	374(ra) # 4fc <open>
  if(fd < 0)
 38e:	02054563          	bltz	a0,3b8 <stat+0x42>
 392:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 394:	85ca                	mv	a1,s2
 396:	00000097          	auipc	ra,0x0
 39a:	17e080e7          	jalr	382(ra) # 514 <fstat>
 39e:	892a                	mv	s2,a0
  close(fd);
 3a0:	8526                	mv	a0,s1
 3a2:	00000097          	auipc	ra,0x0
 3a6:	142080e7          	jalr	322(ra) # 4e4 <close>
  return r;
}
 3aa:	854a                	mv	a0,s2
 3ac:	60e2                	ld	ra,24(sp)
 3ae:	6442                	ld	s0,16(sp)
 3b0:	64a2                	ld	s1,8(sp)
 3b2:	6902                	ld	s2,0(sp)
 3b4:	6105                	addi	sp,sp,32
 3b6:	8082                	ret
    return -1;
 3b8:	597d                	li	s2,-1
 3ba:	bfc5                	j	3aa <stat+0x34>

00000000000003bc <atoi>:

int
atoi(const char *s)
{
 3bc:	1141                	addi	sp,sp,-16
 3be:	e422                	sd	s0,8(sp)
 3c0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3c2:	00054603          	lbu	a2,0(a0)
 3c6:	fd06079b          	addiw	a5,a2,-48
 3ca:	0ff7f793          	andi	a5,a5,255
 3ce:	4725                	li	a4,9
 3d0:	02f76963          	bltu	a4,a5,402 <atoi+0x46>
 3d4:	86aa                	mv	a3,a0
  n = 0;
 3d6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 3d8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 3da:	0685                	addi	a3,a3,1
 3dc:	0025179b          	slliw	a5,a0,0x2
 3e0:	9fa9                	addw	a5,a5,a0
 3e2:	0017979b          	slliw	a5,a5,0x1
 3e6:	9fb1                	addw	a5,a5,a2
 3e8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 3ec:	0006c603          	lbu	a2,0(a3)
 3f0:	fd06071b          	addiw	a4,a2,-48
 3f4:	0ff77713          	andi	a4,a4,255
 3f8:	fee5f1e3          	bgeu	a1,a4,3da <atoi+0x1e>
  return n;
}
 3fc:	6422                	ld	s0,8(sp)
 3fe:	0141                	addi	sp,sp,16
 400:	8082                	ret
  n = 0;
 402:	4501                	li	a0,0
 404:	bfe5                	j	3fc <atoi+0x40>

0000000000000406 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 406:	1141                	addi	sp,sp,-16
 408:	e422                	sd	s0,8(sp)
 40a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 40c:	02b57663          	bgeu	a0,a1,438 <memmove+0x32>
    while(n-- > 0)
 410:	02c05163          	blez	a2,432 <memmove+0x2c>
 414:	fff6079b          	addiw	a5,a2,-1
 418:	1782                	slli	a5,a5,0x20
 41a:	9381                	srli	a5,a5,0x20
 41c:	0785                	addi	a5,a5,1
 41e:	97aa                	add	a5,a5,a0
  dst = vdst;
 420:	872a                	mv	a4,a0
      *dst++ = *src++;
 422:	0585                	addi	a1,a1,1
 424:	0705                	addi	a4,a4,1
 426:	fff5c683          	lbu	a3,-1(a1)
 42a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 42e:	fee79ae3          	bne	a5,a4,422 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 432:	6422                	ld	s0,8(sp)
 434:	0141                	addi	sp,sp,16
 436:	8082                	ret
    dst += n;
 438:	00c50733          	add	a4,a0,a2
    src += n;
 43c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 43e:	fec05ae3          	blez	a2,432 <memmove+0x2c>
 442:	fff6079b          	addiw	a5,a2,-1
 446:	1782                	slli	a5,a5,0x20
 448:	9381                	srli	a5,a5,0x20
 44a:	fff7c793          	not	a5,a5
 44e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 450:	15fd                	addi	a1,a1,-1
 452:	177d                	addi	a4,a4,-1
 454:	0005c683          	lbu	a3,0(a1)
 458:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 45c:	fee79ae3          	bne	a5,a4,450 <memmove+0x4a>
 460:	bfc9                	j	432 <memmove+0x2c>

0000000000000462 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 462:	1141                	addi	sp,sp,-16
 464:	e422                	sd	s0,8(sp)
 466:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 468:	ca05                	beqz	a2,498 <memcmp+0x36>
 46a:	fff6069b          	addiw	a3,a2,-1
 46e:	1682                	slli	a3,a3,0x20
 470:	9281                	srli	a3,a3,0x20
 472:	0685                	addi	a3,a3,1
 474:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 476:	00054783          	lbu	a5,0(a0)
 47a:	0005c703          	lbu	a4,0(a1)
 47e:	00e79863          	bne	a5,a4,48e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 482:	0505                	addi	a0,a0,1
    p2++;
 484:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 486:	fed518e3          	bne	a0,a3,476 <memcmp+0x14>
  }
  return 0;
 48a:	4501                	li	a0,0
 48c:	a019                	j	492 <memcmp+0x30>
      return *p1 - *p2;
 48e:	40e7853b          	subw	a0,a5,a4
}
 492:	6422                	ld	s0,8(sp)
 494:	0141                	addi	sp,sp,16
 496:	8082                	ret
  return 0;
 498:	4501                	li	a0,0
 49a:	bfe5                	j	492 <memcmp+0x30>

000000000000049c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 49c:	1141                	addi	sp,sp,-16
 49e:	e406                	sd	ra,8(sp)
 4a0:	e022                	sd	s0,0(sp)
 4a2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4a4:	00000097          	auipc	ra,0x0
 4a8:	f62080e7          	jalr	-158(ra) # 406 <memmove>
}
 4ac:	60a2                	ld	ra,8(sp)
 4ae:	6402                	ld	s0,0(sp)
 4b0:	0141                	addi	sp,sp,16
 4b2:	8082                	ret

00000000000004b4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4b4:	4885                	li	a7,1
 ecall
 4b6:	00000073          	ecall
 ret
 4ba:	8082                	ret

00000000000004bc <exit>:
.global exit
exit:
 li a7, SYS_exit
 4bc:	4889                	li	a7,2
 ecall
 4be:	00000073          	ecall
 ret
 4c2:	8082                	ret

00000000000004c4 <wait>:
.global wait
wait:
 li a7, SYS_wait
 4c4:	488d                	li	a7,3
 ecall
 4c6:	00000073          	ecall
 ret
 4ca:	8082                	ret

00000000000004cc <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4cc:	4891                	li	a7,4
 ecall
 4ce:	00000073          	ecall
 ret
 4d2:	8082                	ret

00000000000004d4 <read>:
.global read
read:
 li a7, SYS_read
 4d4:	4895                	li	a7,5
 ecall
 4d6:	00000073          	ecall
 ret
 4da:	8082                	ret

00000000000004dc <write>:
.global write
write:
 li a7, SYS_write
 4dc:	48c1                	li	a7,16
 ecall
 4de:	00000073          	ecall
 ret
 4e2:	8082                	ret

00000000000004e4 <close>:
.global close
close:
 li a7, SYS_close
 4e4:	48d5                	li	a7,21
 ecall
 4e6:	00000073          	ecall
 ret
 4ea:	8082                	ret

00000000000004ec <kill>:
.global kill
kill:
 li a7, SYS_kill
 4ec:	4899                	li	a7,6
 ecall
 4ee:	00000073          	ecall
 ret
 4f2:	8082                	ret

00000000000004f4 <exec>:
.global exec
exec:
 li a7, SYS_exec
 4f4:	489d                	li	a7,7
 ecall
 4f6:	00000073          	ecall
 ret
 4fa:	8082                	ret

00000000000004fc <open>:
.global open
open:
 li a7, SYS_open
 4fc:	48bd                	li	a7,15
 ecall
 4fe:	00000073          	ecall
 ret
 502:	8082                	ret

0000000000000504 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 504:	48c5                	li	a7,17
 ecall
 506:	00000073          	ecall
 ret
 50a:	8082                	ret

000000000000050c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 50c:	48c9                	li	a7,18
 ecall
 50e:	00000073          	ecall
 ret
 512:	8082                	ret

0000000000000514 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 514:	48a1                	li	a7,8
 ecall
 516:	00000073          	ecall
 ret
 51a:	8082                	ret

000000000000051c <link>:
.global link
link:
 li a7, SYS_link
 51c:	48cd                	li	a7,19
 ecall
 51e:	00000073          	ecall
 ret
 522:	8082                	ret

0000000000000524 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 524:	48d1                	li	a7,20
 ecall
 526:	00000073          	ecall
 ret
 52a:	8082                	ret

000000000000052c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 52c:	48a5                	li	a7,9
 ecall
 52e:	00000073          	ecall
 ret
 532:	8082                	ret

0000000000000534 <dup>:
.global dup
dup:
 li a7, SYS_dup
 534:	48a9                	li	a7,10
 ecall
 536:	00000073          	ecall
 ret
 53a:	8082                	ret

000000000000053c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 53c:	48ad                	li	a7,11
 ecall
 53e:	00000073          	ecall
 ret
 542:	8082                	ret

0000000000000544 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 544:	48b1                	li	a7,12
 ecall
 546:	00000073          	ecall
 ret
 54a:	8082                	ret

000000000000054c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 54c:	48b5                	li	a7,13
 ecall
 54e:	00000073          	ecall
 ret
 552:	8082                	ret

0000000000000554 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 554:	48b9                	li	a7,14
 ecall
 556:	00000073          	ecall
 ret
 55a:	8082                	ret

000000000000055c <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 55c:	48d9                	li	a7,22
 ecall
 55e:	00000073          	ecall
 ret
 562:	8082                	ret

0000000000000564 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 564:	48dd                	li	a7,23
 ecall
 566:	00000073          	ecall
 ret
 56a:	8082                	ret

000000000000056c <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 56c:	48e1                	li	a7,24
 ecall
 56e:	00000073          	ecall
 ret
 572:	8082                	ret

0000000000000574 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 574:	1101                	addi	sp,sp,-32
 576:	ec06                	sd	ra,24(sp)
 578:	e822                	sd	s0,16(sp)
 57a:	1000                	addi	s0,sp,32
 57c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 580:	4605                	li	a2,1
 582:	fef40593          	addi	a1,s0,-17
 586:	00000097          	auipc	ra,0x0
 58a:	f56080e7          	jalr	-170(ra) # 4dc <write>
}
 58e:	60e2                	ld	ra,24(sp)
 590:	6442                	ld	s0,16(sp)
 592:	6105                	addi	sp,sp,32
 594:	8082                	ret

0000000000000596 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 596:	7139                	addi	sp,sp,-64
 598:	fc06                	sd	ra,56(sp)
 59a:	f822                	sd	s0,48(sp)
 59c:	f426                	sd	s1,40(sp)
 59e:	f04a                	sd	s2,32(sp)
 5a0:	ec4e                	sd	s3,24(sp)
 5a2:	0080                	addi	s0,sp,64
 5a4:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5a6:	c299                	beqz	a3,5ac <printint+0x16>
 5a8:	0805c863          	bltz	a1,638 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5ac:	2581                	sext.w	a1,a1
  neg = 0;
 5ae:	4881                	li	a7,0
 5b0:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5b4:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5b6:	2601                	sext.w	a2,a2
 5b8:	00000517          	auipc	a0,0x0
 5bc:	4c850513          	addi	a0,a0,1224 # a80 <digits>
 5c0:	883a                	mv	a6,a4
 5c2:	2705                	addiw	a4,a4,1
 5c4:	02c5f7bb          	remuw	a5,a1,a2
 5c8:	1782                	slli	a5,a5,0x20
 5ca:	9381                	srli	a5,a5,0x20
 5cc:	97aa                	add	a5,a5,a0
 5ce:	0007c783          	lbu	a5,0(a5)
 5d2:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5d6:	0005879b          	sext.w	a5,a1
 5da:	02c5d5bb          	divuw	a1,a1,a2
 5de:	0685                	addi	a3,a3,1
 5e0:	fec7f0e3          	bgeu	a5,a2,5c0 <printint+0x2a>
  if(neg)
 5e4:	00088b63          	beqz	a7,5fa <printint+0x64>
    buf[i++] = '-';
 5e8:	fd040793          	addi	a5,s0,-48
 5ec:	973e                	add	a4,a4,a5
 5ee:	02d00793          	li	a5,45
 5f2:	fef70823          	sb	a5,-16(a4)
 5f6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 5fa:	02e05863          	blez	a4,62a <printint+0x94>
 5fe:	fc040793          	addi	a5,s0,-64
 602:	00e78933          	add	s2,a5,a4
 606:	fff78993          	addi	s3,a5,-1
 60a:	99ba                	add	s3,s3,a4
 60c:	377d                	addiw	a4,a4,-1
 60e:	1702                	slli	a4,a4,0x20
 610:	9301                	srli	a4,a4,0x20
 612:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 616:	fff94583          	lbu	a1,-1(s2)
 61a:	8526                	mv	a0,s1
 61c:	00000097          	auipc	ra,0x0
 620:	f58080e7          	jalr	-168(ra) # 574 <putc>
  while(--i >= 0)
 624:	197d                	addi	s2,s2,-1
 626:	ff3918e3          	bne	s2,s3,616 <printint+0x80>
}
 62a:	70e2                	ld	ra,56(sp)
 62c:	7442                	ld	s0,48(sp)
 62e:	74a2                	ld	s1,40(sp)
 630:	7902                	ld	s2,32(sp)
 632:	69e2                	ld	s3,24(sp)
 634:	6121                	addi	sp,sp,64
 636:	8082                	ret
    x = -xx;
 638:	40b005bb          	negw	a1,a1
    neg = 1;
 63c:	4885                	li	a7,1
    x = -xx;
 63e:	bf8d                	j	5b0 <printint+0x1a>

0000000000000640 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 640:	7119                	addi	sp,sp,-128
 642:	fc86                	sd	ra,120(sp)
 644:	f8a2                	sd	s0,112(sp)
 646:	f4a6                	sd	s1,104(sp)
 648:	f0ca                	sd	s2,96(sp)
 64a:	ecce                	sd	s3,88(sp)
 64c:	e8d2                	sd	s4,80(sp)
 64e:	e4d6                	sd	s5,72(sp)
 650:	e0da                	sd	s6,64(sp)
 652:	fc5e                	sd	s7,56(sp)
 654:	f862                	sd	s8,48(sp)
 656:	f466                	sd	s9,40(sp)
 658:	f06a                	sd	s10,32(sp)
 65a:	ec6e                	sd	s11,24(sp)
 65c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 65e:	0005c903          	lbu	s2,0(a1)
 662:	18090f63          	beqz	s2,800 <vprintf+0x1c0>
 666:	8aaa                	mv	s5,a0
 668:	8b32                	mv	s6,a2
 66a:	00158493          	addi	s1,a1,1
  state = 0;
 66e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 670:	02500a13          	li	s4,37
      if(c == 'd'){
 674:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 678:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 67c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 680:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 684:	00000b97          	auipc	s7,0x0
 688:	3fcb8b93          	addi	s7,s7,1020 # a80 <digits>
 68c:	a839                	j	6aa <vprintf+0x6a>
        putc(fd, c);
 68e:	85ca                	mv	a1,s2
 690:	8556                	mv	a0,s5
 692:	00000097          	auipc	ra,0x0
 696:	ee2080e7          	jalr	-286(ra) # 574 <putc>
 69a:	a019                	j	6a0 <vprintf+0x60>
    } else if(state == '%'){
 69c:	01498f63          	beq	s3,s4,6ba <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6a0:	0485                	addi	s1,s1,1
 6a2:	fff4c903          	lbu	s2,-1(s1)
 6a6:	14090d63          	beqz	s2,800 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6aa:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6ae:	fe0997e3          	bnez	s3,69c <vprintf+0x5c>
      if(c == '%'){
 6b2:	fd479ee3          	bne	a5,s4,68e <vprintf+0x4e>
        state = '%';
 6b6:	89be                	mv	s3,a5
 6b8:	b7e5                	j	6a0 <vprintf+0x60>
      if(c == 'd'){
 6ba:	05878063          	beq	a5,s8,6fa <vprintf+0xba>
      } else if(c == 'l') {
 6be:	05978c63          	beq	a5,s9,716 <vprintf+0xd6>
      } else if(c == 'x') {
 6c2:	07a78863          	beq	a5,s10,732 <vprintf+0xf2>
      } else if(c == 'p') {
 6c6:	09b78463          	beq	a5,s11,74e <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6ca:	07300713          	li	a4,115
 6ce:	0ce78663          	beq	a5,a4,79a <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6d2:	06300713          	li	a4,99
 6d6:	0ee78e63          	beq	a5,a4,7d2 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6da:	11478863          	beq	a5,s4,7ea <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6de:	85d2                	mv	a1,s4
 6e0:	8556                	mv	a0,s5
 6e2:	00000097          	auipc	ra,0x0
 6e6:	e92080e7          	jalr	-366(ra) # 574 <putc>
        putc(fd, c);
 6ea:	85ca                	mv	a1,s2
 6ec:	8556                	mv	a0,s5
 6ee:	00000097          	auipc	ra,0x0
 6f2:	e86080e7          	jalr	-378(ra) # 574 <putc>
      }
      state = 0;
 6f6:	4981                	li	s3,0
 6f8:	b765                	j	6a0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6fa:	008b0913          	addi	s2,s6,8
 6fe:	4685                	li	a3,1
 700:	4629                	li	a2,10
 702:	000b2583          	lw	a1,0(s6)
 706:	8556                	mv	a0,s5
 708:	00000097          	auipc	ra,0x0
 70c:	e8e080e7          	jalr	-370(ra) # 596 <printint>
 710:	8b4a                	mv	s6,s2
      state = 0;
 712:	4981                	li	s3,0
 714:	b771                	j	6a0 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 716:	008b0913          	addi	s2,s6,8
 71a:	4681                	li	a3,0
 71c:	4629                	li	a2,10
 71e:	000b2583          	lw	a1,0(s6)
 722:	8556                	mv	a0,s5
 724:	00000097          	auipc	ra,0x0
 728:	e72080e7          	jalr	-398(ra) # 596 <printint>
 72c:	8b4a                	mv	s6,s2
      state = 0;
 72e:	4981                	li	s3,0
 730:	bf85                	j	6a0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 732:	008b0913          	addi	s2,s6,8
 736:	4681                	li	a3,0
 738:	4641                	li	a2,16
 73a:	000b2583          	lw	a1,0(s6)
 73e:	8556                	mv	a0,s5
 740:	00000097          	auipc	ra,0x0
 744:	e56080e7          	jalr	-426(ra) # 596 <printint>
 748:	8b4a                	mv	s6,s2
      state = 0;
 74a:	4981                	li	s3,0
 74c:	bf91                	j	6a0 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 74e:	008b0793          	addi	a5,s6,8
 752:	f8f43423          	sd	a5,-120(s0)
 756:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 75a:	03000593          	li	a1,48
 75e:	8556                	mv	a0,s5
 760:	00000097          	auipc	ra,0x0
 764:	e14080e7          	jalr	-492(ra) # 574 <putc>
  putc(fd, 'x');
 768:	85ea                	mv	a1,s10
 76a:	8556                	mv	a0,s5
 76c:	00000097          	auipc	ra,0x0
 770:	e08080e7          	jalr	-504(ra) # 574 <putc>
 774:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 776:	03c9d793          	srli	a5,s3,0x3c
 77a:	97de                	add	a5,a5,s7
 77c:	0007c583          	lbu	a1,0(a5)
 780:	8556                	mv	a0,s5
 782:	00000097          	auipc	ra,0x0
 786:	df2080e7          	jalr	-526(ra) # 574 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 78a:	0992                	slli	s3,s3,0x4
 78c:	397d                	addiw	s2,s2,-1
 78e:	fe0914e3          	bnez	s2,776 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 792:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 796:	4981                	li	s3,0
 798:	b721                	j	6a0 <vprintf+0x60>
        s = va_arg(ap, char*);
 79a:	008b0993          	addi	s3,s6,8
 79e:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7a2:	02090163          	beqz	s2,7c4 <vprintf+0x184>
        while(*s != 0){
 7a6:	00094583          	lbu	a1,0(s2)
 7aa:	c9a1                	beqz	a1,7fa <vprintf+0x1ba>
          putc(fd, *s);
 7ac:	8556                	mv	a0,s5
 7ae:	00000097          	auipc	ra,0x0
 7b2:	dc6080e7          	jalr	-570(ra) # 574 <putc>
          s++;
 7b6:	0905                	addi	s2,s2,1
        while(*s != 0){
 7b8:	00094583          	lbu	a1,0(s2)
 7bc:	f9e5                	bnez	a1,7ac <vprintf+0x16c>
        s = va_arg(ap, char*);
 7be:	8b4e                	mv	s6,s3
      state = 0;
 7c0:	4981                	li	s3,0
 7c2:	bdf9                	j	6a0 <vprintf+0x60>
          s = "(null)";
 7c4:	00000917          	auipc	s2,0x0
 7c8:	2b490913          	addi	s2,s2,692 # a78 <malloc+0x16e>
        while(*s != 0){
 7cc:	02800593          	li	a1,40
 7d0:	bff1                	j	7ac <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7d2:	008b0913          	addi	s2,s6,8
 7d6:	000b4583          	lbu	a1,0(s6)
 7da:	8556                	mv	a0,s5
 7dc:	00000097          	auipc	ra,0x0
 7e0:	d98080e7          	jalr	-616(ra) # 574 <putc>
 7e4:	8b4a                	mv	s6,s2
      state = 0;
 7e6:	4981                	li	s3,0
 7e8:	bd65                	j	6a0 <vprintf+0x60>
        putc(fd, c);
 7ea:	85d2                	mv	a1,s4
 7ec:	8556                	mv	a0,s5
 7ee:	00000097          	auipc	ra,0x0
 7f2:	d86080e7          	jalr	-634(ra) # 574 <putc>
      state = 0;
 7f6:	4981                	li	s3,0
 7f8:	b565                	j	6a0 <vprintf+0x60>
        s = va_arg(ap, char*);
 7fa:	8b4e                	mv	s6,s3
      state = 0;
 7fc:	4981                	li	s3,0
 7fe:	b54d                	j	6a0 <vprintf+0x60>
    }
  }
}
 800:	70e6                	ld	ra,120(sp)
 802:	7446                	ld	s0,112(sp)
 804:	74a6                	ld	s1,104(sp)
 806:	7906                	ld	s2,96(sp)
 808:	69e6                	ld	s3,88(sp)
 80a:	6a46                	ld	s4,80(sp)
 80c:	6aa6                	ld	s5,72(sp)
 80e:	6b06                	ld	s6,64(sp)
 810:	7be2                	ld	s7,56(sp)
 812:	7c42                	ld	s8,48(sp)
 814:	7ca2                	ld	s9,40(sp)
 816:	7d02                	ld	s10,32(sp)
 818:	6de2                	ld	s11,24(sp)
 81a:	6109                	addi	sp,sp,128
 81c:	8082                	ret

000000000000081e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 81e:	715d                	addi	sp,sp,-80
 820:	ec06                	sd	ra,24(sp)
 822:	e822                	sd	s0,16(sp)
 824:	1000                	addi	s0,sp,32
 826:	e010                	sd	a2,0(s0)
 828:	e414                	sd	a3,8(s0)
 82a:	e818                	sd	a4,16(s0)
 82c:	ec1c                	sd	a5,24(s0)
 82e:	03043023          	sd	a6,32(s0)
 832:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 836:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 83a:	8622                	mv	a2,s0
 83c:	00000097          	auipc	ra,0x0
 840:	e04080e7          	jalr	-508(ra) # 640 <vprintf>
}
 844:	60e2                	ld	ra,24(sp)
 846:	6442                	ld	s0,16(sp)
 848:	6161                	addi	sp,sp,80
 84a:	8082                	ret

000000000000084c <printf>:

void
printf(const char *fmt, ...)
{
 84c:	711d                	addi	sp,sp,-96
 84e:	ec06                	sd	ra,24(sp)
 850:	e822                	sd	s0,16(sp)
 852:	1000                	addi	s0,sp,32
 854:	e40c                	sd	a1,8(s0)
 856:	e810                	sd	a2,16(s0)
 858:	ec14                	sd	a3,24(s0)
 85a:	f018                	sd	a4,32(s0)
 85c:	f41c                	sd	a5,40(s0)
 85e:	03043823          	sd	a6,48(s0)
 862:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 866:	00840613          	addi	a2,s0,8
 86a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 86e:	85aa                	mv	a1,a0
 870:	4505                	li	a0,1
 872:	00000097          	auipc	ra,0x0
 876:	dce080e7          	jalr	-562(ra) # 640 <vprintf>
}
 87a:	60e2                	ld	ra,24(sp)
 87c:	6442                	ld	s0,16(sp)
 87e:	6125                	addi	sp,sp,96
 880:	8082                	ret

0000000000000882 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 882:	1141                	addi	sp,sp,-16
 884:	e422                	sd	s0,8(sp)
 886:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 888:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 88c:	00000797          	auipc	a5,0x0
 890:	20c7b783          	ld	a5,524(a5) # a98 <freep>
 894:	a805                	j	8c4 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 896:	4618                	lw	a4,8(a2)
 898:	9db9                	addw	a1,a1,a4
 89a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 89e:	6398                	ld	a4,0(a5)
 8a0:	6318                	ld	a4,0(a4)
 8a2:	fee53823          	sd	a4,-16(a0)
 8a6:	a091                	j	8ea <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8a8:	ff852703          	lw	a4,-8(a0)
 8ac:	9e39                	addw	a2,a2,a4
 8ae:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8b0:	ff053703          	ld	a4,-16(a0)
 8b4:	e398                	sd	a4,0(a5)
 8b6:	a099                	j	8fc <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8b8:	6398                	ld	a4,0(a5)
 8ba:	00e7e463          	bltu	a5,a4,8c2 <free+0x40>
 8be:	00e6ea63          	bltu	a3,a4,8d2 <free+0x50>
{
 8c2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8c4:	fed7fae3          	bgeu	a5,a3,8b8 <free+0x36>
 8c8:	6398                	ld	a4,0(a5)
 8ca:	00e6e463          	bltu	a3,a4,8d2 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8ce:	fee7eae3          	bltu	a5,a4,8c2 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8d2:	ff852583          	lw	a1,-8(a0)
 8d6:	6390                	ld	a2,0(a5)
 8d8:	02059713          	slli	a4,a1,0x20
 8dc:	9301                	srli	a4,a4,0x20
 8de:	0712                	slli	a4,a4,0x4
 8e0:	9736                	add	a4,a4,a3
 8e2:	fae60ae3          	beq	a2,a4,896 <free+0x14>
    bp->s.ptr = p->s.ptr;
 8e6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 8ea:	4790                	lw	a2,8(a5)
 8ec:	02061713          	slli	a4,a2,0x20
 8f0:	9301                	srli	a4,a4,0x20
 8f2:	0712                	slli	a4,a4,0x4
 8f4:	973e                	add	a4,a4,a5
 8f6:	fae689e3          	beq	a3,a4,8a8 <free+0x26>
  } else
    p->s.ptr = bp;
 8fa:	e394                	sd	a3,0(a5)
  freep = p;
 8fc:	00000717          	auipc	a4,0x0
 900:	18f73e23          	sd	a5,412(a4) # a98 <freep>
}
 904:	6422                	ld	s0,8(sp)
 906:	0141                	addi	sp,sp,16
 908:	8082                	ret

000000000000090a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 90a:	7139                	addi	sp,sp,-64
 90c:	fc06                	sd	ra,56(sp)
 90e:	f822                	sd	s0,48(sp)
 910:	f426                	sd	s1,40(sp)
 912:	f04a                	sd	s2,32(sp)
 914:	ec4e                	sd	s3,24(sp)
 916:	e852                	sd	s4,16(sp)
 918:	e456                	sd	s5,8(sp)
 91a:	e05a                	sd	s6,0(sp)
 91c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 91e:	02051493          	slli	s1,a0,0x20
 922:	9081                	srli	s1,s1,0x20
 924:	04bd                	addi	s1,s1,15
 926:	8091                	srli	s1,s1,0x4
 928:	0014899b          	addiw	s3,s1,1
 92c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 92e:	00000517          	auipc	a0,0x0
 932:	16a53503          	ld	a0,362(a0) # a98 <freep>
 936:	c515                	beqz	a0,962 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 938:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 93a:	4798                	lw	a4,8(a5)
 93c:	02977f63          	bgeu	a4,s1,97a <malloc+0x70>
 940:	8a4e                	mv	s4,s3
 942:	0009871b          	sext.w	a4,s3
 946:	6685                	lui	a3,0x1
 948:	00d77363          	bgeu	a4,a3,94e <malloc+0x44>
 94c:	6a05                	lui	s4,0x1
 94e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 952:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 956:	00000917          	auipc	s2,0x0
 95a:	14290913          	addi	s2,s2,322 # a98 <freep>
  if(p == (char*)-1)
 95e:	5afd                	li	s5,-1
 960:	a88d                	j	9d2 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 962:	00000797          	auipc	a5,0x0
 966:	13e78793          	addi	a5,a5,318 # aa0 <base>
 96a:	00000717          	auipc	a4,0x0
 96e:	12f73723          	sd	a5,302(a4) # a98 <freep>
 972:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 974:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 978:	b7e1                	j	940 <malloc+0x36>
      if(p->s.size == nunits)
 97a:	02e48b63          	beq	s1,a4,9b0 <malloc+0xa6>
        p->s.size -= nunits;
 97e:	4137073b          	subw	a4,a4,s3
 982:	c798                	sw	a4,8(a5)
        p += p->s.size;
 984:	1702                	slli	a4,a4,0x20
 986:	9301                	srli	a4,a4,0x20
 988:	0712                	slli	a4,a4,0x4
 98a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 98c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 990:	00000717          	auipc	a4,0x0
 994:	10a73423          	sd	a0,264(a4) # a98 <freep>
      return (void*)(p + 1);
 998:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 99c:	70e2                	ld	ra,56(sp)
 99e:	7442                	ld	s0,48(sp)
 9a0:	74a2                	ld	s1,40(sp)
 9a2:	7902                	ld	s2,32(sp)
 9a4:	69e2                	ld	s3,24(sp)
 9a6:	6a42                	ld	s4,16(sp)
 9a8:	6aa2                	ld	s5,8(sp)
 9aa:	6b02                	ld	s6,0(sp)
 9ac:	6121                	addi	sp,sp,64
 9ae:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9b0:	6398                	ld	a4,0(a5)
 9b2:	e118                	sd	a4,0(a0)
 9b4:	bff1                	j	990 <malloc+0x86>
  hp->s.size = nu;
 9b6:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9ba:	0541                	addi	a0,a0,16
 9bc:	00000097          	auipc	ra,0x0
 9c0:	ec6080e7          	jalr	-314(ra) # 882 <free>
  return freep;
 9c4:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9c8:	d971                	beqz	a0,99c <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9ca:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9cc:	4798                	lw	a4,8(a5)
 9ce:	fa9776e3          	bgeu	a4,s1,97a <malloc+0x70>
    if(p == freep)
 9d2:	00093703          	ld	a4,0(s2)
 9d6:	853e                	mv	a0,a5
 9d8:	fef719e3          	bne	a4,a5,9ca <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 9dc:	8552                	mv	a0,s4
 9de:	00000097          	auipc	ra,0x0
 9e2:	b66080e7          	jalr	-1178(ra) # 544 <sbrk>
  if(p == (char*)-1)
 9e6:	fd5518e3          	bne	a0,s5,9b6 <malloc+0xac>
        return 0;
 9ea:	4501                	li	a0,0
 9ec:	bf45                	j	99c <malloc+0x92>
