
user/_LBStest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "kernel/riscv.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   0:	7139                	addi	sp,sp,-64
   2:	fc06                	sd	ra,56(sp)
   4:	f822                	sd	s0,48(sp)
   6:	f426                	sd	s1,40(sp)
   8:	f04a                	sd	s2,32(sp)
   a:	ec4e                	sd	s3,24(sp)
   c:	e852                	sd	s4,16(sp)
   e:	0080                	addi	s0,sp,64
  10:	84ae                	mv	s1,a1
  int t1 = atoi(argv[1]);
  12:	6588                	ld	a0,8(a1)
  14:	00000097          	auipc	ra,0x0
  18:	2f4080e7          	jalr	756(ra) # 308 <atoi>
  1c:	89aa                	mv	s3,a0
  int t2 = atoi(argv[2]);
  1e:	6888                	ld	a0,16(s1)
  20:	00000097          	auipc	ra,0x0
  24:	2e8080e7          	jalr	744(ra) # 308 <atoi>
  28:	892a                	mv	s2,a0
  int t3 = atoi(argv[3]);
  2a:	6c88                	ld	a0,24(s1)
  2c:	00000097          	auipc	ra,0x0
  30:	2dc080e7          	jalr	732(ra) # 308 <atoi>
  if (t1 < 0 || t2 < 0)
  34:	0409c363          	bltz	s3,7a <main+0x7a>
  38:	8a2a                	mv	s4,a0
  3a:	04094063          	bltz	s2,7a <main+0x7a>
  {
    printf("loda\n");
    exit(1);
  }
  int f = fork();
  3e:	00000097          	auipc	ra,0x0
  42:	3c2080e7          	jalr	962(ra) # 400 <fork>
  46:	84aa                	mv	s1,a0
  if (f == 0)
  48:	ed55                	bnez	a0,104 <main+0x104>
  {
    int p = fork();
  4a:	00000097          	auipc	ra,0x0
  4e:	3b6080e7          	jalr	950(ra) # 400 <fork>
  52:	892a                	mv	s2,a0
    if (p == 0)
  54:	e13d                	bnez	a0,ba <main+0xba>
    {
      settickets(t3);
  56:	8552                	mv	a0,s4
  58:	00000097          	auipc	ra,0x0
  5c:	470080e7          	jalr	1136(ra) # 4c8 <settickets>
      for (int i = 0; i < 1000 * 500000; i++)
      {
        if ((i % 1000000) == 0)
  60:	000f49b7          	lui	s3,0xf4
  64:	2409899b          	addiw	s3,s3,576
        {
          write(2, "2", 1);
  68:	00001a17          	auipc	s4,0x1
  6c:	900a0a13          	addi	s4,s4,-1792 # 968 <malloc+0xfa>
      for (int i = 0; i < 1000 * 500000; i++)
  70:	1dcd64b7          	lui	s1,0x1dcd6
  74:	50048493          	addi	s1,s1,1280 # 1dcd6500 <base+0x1dcd54f0>
  78:	a805                	j	a8 <main+0xa8>
    printf("loda\n");
  7a:	00001517          	auipc	a0,0x1
  7e:	8e650513          	addi	a0,a0,-1818 # 960 <malloc+0xf2>
  82:	00000097          	auipc	ra,0x0
  86:	72e080e7          	jalr	1838(ra) # 7b0 <printf>
    exit(1);
  8a:	4505                	li	a0,1
  8c:	00000097          	auipc	ra,0x0
  90:	37c080e7          	jalr	892(ra) # 408 <exit>
          write(2, "2", 1);
  94:	4605                	li	a2,1
  96:	85d2                	mv	a1,s4
  98:	4509                	li	a0,2
  9a:	00000097          	auipc	ra,0x0
  9e:	38e080e7          	jalr	910(ra) # 428 <write>
      for (int i = 0; i < 1000 * 500000; i++)
  a2:	2905                	addiw	s2,s2,1
  a4:	00990663          	beq	s2,s1,b0 <main+0xb0>
        if ((i % 1000000) == 0)
  a8:	033967bb          	remw	a5,s2,s3
  ac:	fbfd                	bnez	a5,a2 <main+0xa2>
  ae:	b7dd                	j	94 <main+0x94>
        }
      }
      exit(0);
  b0:	4501                	li	a0,0
  b2:	00000097          	auipc	ra,0x0
  b6:	356080e7          	jalr	854(ra) # 408 <exit>
    }
    else
    {
      settickets(t1);
  ba:	854e                	mv	a0,s3
  bc:	00000097          	auipc	ra,0x0
  c0:	40c080e7          	jalr	1036(ra) # 4c8 <settickets>
      for (int i = 0; i < 1000 * 500000; i++)
      {
        if ((i % 1000000) == 0)
  c4:	000f49b7          	lui	s3,0xf4
  c8:	2409899b          	addiw	s3,s3,576
        {
          write(2, "0", 1);
  cc:	00001a17          	auipc	s4,0x1
  d0:	8a4a0a13          	addi	s4,s4,-1884 # 970 <malloc+0x102>
      for (int i = 0; i < 1000 * 500000; i++)
  d4:	1dcd6937          	lui	s2,0x1dcd6
  d8:	50090913          	addi	s2,s2,1280 # 1dcd6500 <base+0x1dcd54f0>
  dc:	a819                	j	f2 <main+0xf2>
          write(2, "0", 1);
  de:	4605                	li	a2,1
  e0:	85d2                	mv	a1,s4
  e2:	4509                	li	a0,2
  e4:	00000097          	auipc	ra,0x0
  e8:	344080e7          	jalr	836(ra) # 428 <write>
      for (int i = 0; i < 1000 * 500000; i++)
  ec:	2485                	addiw	s1,s1,1
  ee:	01248663          	beq	s1,s2,fa <main+0xfa>
        if ((i % 1000000) == 0)
  f2:	0334e7bb          	remw	a5,s1,s3
  f6:	fbfd                	bnez	a5,ec <main+0xec>
  f8:	b7dd                	j	de <main+0xde>
        }
      }
      exit(0);
  fa:	4501                	li	a0,0
  fc:	00000097          	auipc	ra,0x0
 100:	30c080e7          	jalr	780(ra) # 408 <exit>
    }
  }
  else
  {
    settickets(t2);
 104:	854a                	mv	a0,s2
 106:	00000097          	auipc	ra,0x0
 10a:	3c2080e7          	jalr	962(ra) # 4c8 <settickets>
    for (int i = 0; i < 1000 * 500000; i++)
 10e:	4481                	li	s1,0
    {
      if ((i % 1000000) == 0)
 110:	000f49b7          	lui	s3,0xf4
 114:	2409899b          	addiw	s3,s3,576
      {
        write(2, "1", 1);
 118:	00001a17          	auipc	s4,0x1
 11c:	860a0a13          	addi	s4,s4,-1952 # 978 <malloc+0x10a>
    for (int i = 0; i < 1000 * 500000; i++)
 120:	1dcd6937          	lui	s2,0x1dcd6
 124:	50090913          	addi	s2,s2,1280 # 1dcd6500 <base+0x1dcd54f0>
 128:	a819                	j	13e <main+0x13e>
        write(2, "1", 1);
 12a:	4605                	li	a2,1
 12c:	85d2                	mv	a1,s4
 12e:	4509                	li	a0,2
 130:	00000097          	auipc	ra,0x0
 134:	2f8080e7          	jalr	760(ra) # 428 <write>
    for (int i = 0; i < 1000 * 500000; i++)
 138:	2485                	addiw	s1,s1,1
 13a:	01248663          	beq	s1,s2,146 <main+0x146>
      if ((i % 1000000) == 0)
 13e:	0334e7bb          	remw	a5,s1,s3
 142:	fbfd                	bnez	a5,138 <main+0x138>
 144:	b7dd                	j	12a <main+0x12a>
      }
    }
    int stat;
    wait(&stat);
 146:	fcc40513          	addi	a0,s0,-52
 14a:	00000097          	auipc	ra,0x0
 14e:	2c6080e7          	jalr	710(ra) # 410 <wait>
  }
  write(2, "\n", 1);
 152:	4605                	li	a2,1
 154:	00001597          	auipc	a1,0x1
 158:	82c58593          	addi	a1,a1,-2004 # 980 <malloc+0x112>
 15c:	4509                	li	a0,2
 15e:	00000097          	auipc	ra,0x0
 162:	2ca080e7          	jalr	714(ra) # 428 <write>
  return 0;
}
 166:	4501                	li	a0,0
 168:	70e2                	ld	ra,56(sp)
 16a:	7442                	ld	s0,48(sp)
 16c:	74a2                	ld	s1,40(sp)
 16e:	7902                	ld	s2,32(sp)
 170:	69e2                	ld	s3,24(sp)
 172:	6a42                	ld	s4,16(sp)
 174:	6121                	addi	sp,sp,64
 176:	8082                	ret

0000000000000178 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 178:	1141                	addi	sp,sp,-16
 17a:	e406                	sd	ra,8(sp)
 17c:	e022                	sd	s0,0(sp)
 17e:	0800                	addi	s0,sp,16
  extern int main();
  main();
 180:	00000097          	auipc	ra,0x0
 184:	e80080e7          	jalr	-384(ra) # 0 <main>
  exit(0);
 188:	4501                	li	a0,0
 18a:	00000097          	auipc	ra,0x0
 18e:	27e080e7          	jalr	638(ra) # 408 <exit>

0000000000000192 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 192:	1141                	addi	sp,sp,-16
 194:	e422                	sd	s0,8(sp)
 196:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 198:	87aa                	mv	a5,a0
 19a:	0585                	addi	a1,a1,1
 19c:	0785                	addi	a5,a5,1
 19e:	fff5c703          	lbu	a4,-1(a1)
 1a2:	fee78fa3          	sb	a4,-1(a5)
 1a6:	fb75                	bnez	a4,19a <strcpy+0x8>
    ;
  return os;
}
 1a8:	6422                	ld	s0,8(sp)
 1aa:	0141                	addi	sp,sp,16
 1ac:	8082                	ret

00000000000001ae <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1ae:	1141                	addi	sp,sp,-16
 1b0:	e422                	sd	s0,8(sp)
 1b2:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1b4:	00054783          	lbu	a5,0(a0)
 1b8:	cb91                	beqz	a5,1cc <strcmp+0x1e>
 1ba:	0005c703          	lbu	a4,0(a1)
 1be:	00f71763          	bne	a4,a5,1cc <strcmp+0x1e>
    p++, q++;
 1c2:	0505                	addi	a0,a0,1
 1c4:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1c6:	00054783          	lbu	a5,0(a0)
 1ca:	fbe5                	bnez	a5,1ba <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1cc:	0005c503          	lbu	a0,0(a1)
}
 1d0:	40a7853b          	subw	a0,a5,a0
 1d4:	6422                	ld	s0,8(sp)
 1d6:	0141                	addi	sp,sp,16
 1d8:	8082                	ret

00000000000001da <strlen>:

uint
strlen(const char *s)
{
 1da:	1141                	addi	sp,sp,-16
 1dc:	e422                	sd	s0,8(sp)
 1de:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1e0:	00054783          	lbu	a5,0(a0)
 1e4:	cf91                	beqz	a5,200 <strlen+0x26>
 1e6:	0505                	addi	a0,a0,1
 1e8:	87aa                	mv	a5,a0
 1ea:	4685                	li	a3,1
 1ec:	9e89                	subw	a3,a3,a0
 1ee:	00f6853b          	addw	a0,a3,a5
 1f2:	0785                	addi	a5,a5,1
 1f4:	fff7c703          	lbu	a4,-1(a5)
 1f8:	fb7d                	bnez	a4,1ee <strlen+0x14>
    ;
  return n;
}
 1fa:	6422                	ld	s0,8(sp)
 1fc:	0141                	addi	sp,sp,16
 1fe:	8082                	ret
  for(n = 0; s[n]; n++)
 200:	4501                	li	a0,0
 202:	bfe5                	j	1fa <strlen+0x20>

0000000000000204 <memset>:

void*
memset(void *dst, int c, uint n)
{
 204:	1141                	addi	sp,sp,-16
 206:	e422                	sd	s0,8(sp)
 208:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 20a:	ce09                	beqz	a2,224 <memset+0x20>
 20c:	87aa                	mv	a5,a0
 20e:	fff6071b          	addiw	a4,a2,-1
 212:	1702                	slli	a4,a4,0x20
 214:	9301                	srli	a4,a4,0x20
 216:	0705                	addi	a4,a4,1
 218:	972a                	add	a4,a4,a0
    cdst[i] = c;
 21a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 21e:	0785                	addi	a5,a5,1
 220:	fee79de3          	bne	a5,a4,21a <memset+0x16>
  }
  return dst;
}
 224:	6422                	ld	s0,8(sp)
 226:	0141                	addi	sp,sp,16
 228:	8082                	ret

000000000000022a <strchr>:

char*
strchr(const char *s, char c)
{
 22a:	1141                	addi	sp,sp,-16
 22c:	e422                	sd	s0,8(sp)
 22e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 230:	00054783          	lbu	a5,0(a0)
 234:	cb99                	beqz	a5,24a <strchr+0x20>
    if(*s == c)
 236:	00f58763          	beq	a1,a5,244 <strchr+0x1a>
  for(; *s; s++)
 23a:	0505                	addi	a0,a0,1
 23c:	00054783          	lbu	a5,0(a0)
 240:	fbfd                	bnez	a5,236 <strchr+0xc>
      return (char*)s;
  return 0;
 242:	4501                	li	a0,0
}
 244:	6422                	ld	s0,8(sp)
 246:	0141                	addi	sp,sp,16
 248:	8082                	ret
  return 0;
 24a:	4501                	li	a0,0
 24c:	bfe5                	j	244 <strchr+0x1a>

000000000000024e <gets>:

char*
gets(char *buf, int max)
{
 24e:	711d                	addi	sp,sp,-96
 250:	ec86                	sd	ra,88(sp)
 252:	e8a2                	sd	s0,80(sp)
 254:	e4a6                	sd	s1,72(sp)
 256:	e0ca                	sd	s2,64(sp)
 258:	fc4e                	sd	s3,56(sp)
 25a:	f852                	sd	s4,48(sp)
 25c:	f456                	sd	s5,40(sp)
 25e:	f05a                	sd	s6,32(sp)
 260:	ec5e                	sd	s7,24(sp)
 262:	1080                	addi	s0,sp,96
 264:	8baa                	mv	s7,a0
 266:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 268:	892a                	mv	s2,a0
 26a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 26c:	4aa9                	li	s5,10
 26e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 270:	89a6                	mv	s3,s1
 272:	2485                	addiw	s1,s1,1
 274:	0344d863          	bge	s1,s4,2a4 <gets+0x56>
    cc = read(0, &c, 1);
 278:	4605                	li	a2,1
 27a:	faf40593          	addi	a1,s0,-81
 27e:	4501                	li	a0,0
 280:	00000097          	auipc	ra,0x0
 284:	1a0080e7          	jalr	416(ra) # 420 <read>
    if(cc < 1)
 288:	00a05e63          	blez	a0,2a4 <gets+0x56>
    buf[i++] = c;
 28c:	faf44783          	lbu	a5,-81(s0)
 290:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 294:	01578763          	beq	a5,s5,2a2 <gets+0x54>
 298:	0905                	addi	s2,s2,1
 29a:	fd679be3          	bne	a5,s6,270 <gets+0x22>
  for(i=0; i+1 < max; ){
 29e:	89a6                	mv	s3,s1
 2a0:	a011                	j	2a4 <gets+0x56>
 2a2:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2a4:	99de                	add	s3,s3,s7
 2a6:	00098023          	sb	zero,0(s3) # f4000 <base+0xf2ff0>
  return buf;
}
 2aa:	855e                	mv	a0,s7
 2ac:	60e6                	ld	ra,88(sp)
 2ae:	6446                	ld	s0,80(sp)
 2b0:	64a6                	ld	s1,72(sp)
 2b2:	6906                	ld	s2,64(sp)
 2b4:	79e2                	ld	s3,56(sp)
 2b6:	7a42                	ld	s4,48(sp)
 2b8:	7aa2                	ld	s5,40(sp)
 2ba:	7b02                	ld	s6,32(sp)
 2bc:	6be2                	ld	s7,24(sp)
 2be:	6125                	addi	sp,sp,96
 2c0:	8082                	ret

00000000000002c2 <stat>:

int
stat(const char *n, struct stat *st)
{
 2c2:	1101                	addi	sp,sp,-32
 2c4:	ec06                	sd	ra,24(sp)
 2c6:	e822                	sd	s0,16(sp)
 2c8:	e426                	sd	s1,8(sp)
 2ca:	e04a                	sd	s2,0(sp)
 2cc:	1000                	addi	s0,sp,32
 2ce:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2d0:	4581                	li	a1,0
 2d2:	00000097          	auipc	ra,0x0
 2d6:	17e080e7          	jalr	382(ra) # 450 <open>
  if(fd < 0)
 2da:	02054563          	bltz	a0,304 <stat+0x42>
 2de:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2e0:	85ca                	mv	a1,s2
 2e2:	00000097          	auipc	ra,0x0
 2e6:	186080e7          	jalr	390(ra) # 468 <fstat>
 2ea:	892a                	mv	s2,a0
  close(fd);
 2ec:	8526                	mv	a0,s1
 2ee:	00000097          	auipc	ra,0x0
 2f2:	14a080e7          	jalr	330(ra) # 438 <close>
  return r;
}
 2f6:	854a                	mv	a0,s2
 2f8:	60e2                	ld	ra,24(sp)
 2fa:	6442                	ld	s0,16(sp)
 2fc:	64a2                	ld	s1,8(sp)
 2fe:	6902                	ld	s2,0(sp)
 300:	6105                	addi	sp,sp,32
 302:	8082                	ret
    return -1;
 304:	597d                	li	s2,-1
 306:	bfc5                	j	2f6 <stat+0x34>

0000000000000308 <atoi>:

int
atoi(const char *s)
{
 308:	1141                	addi	sp,sp,-16
 30a:	e422                	sd	s0,8(sp)
 30c:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 30e:	00054603          	lbu	a2,0(a0)
 312:	fd06079b          	addiw	a5,a2,-48
 316:	0ff7f793          	andi	a5,a5,255
 31a:	4725                	li	a4,9
 31c:	02f76963          	bltu	a4,a5,34e <atoi+0x46>
 320:	86aa                	mv	a3,a0
  n = 0;
 322:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 324:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 326:	0685                	addi	a3,a3,1
 328:	0025179b          	slliw	a5,a0,0x2
 32c:	9fa9                	addw	a5,a5,a0
 32e:	0017979b          	slliw	a5,a5,0x1
 332:	9fb1                	addw	a5,a5,a2
 334:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 338:	0006c603          	lbu	a2,0(a3)
 33c:	fd06071b          	addiw	a4,a2,-48
 340:	0ff77713          	andi	a4,a4,255
 344:	fee5f1e3          	bgeu	a1,a4,326 <atoi+0x1e>
  return n;
}
 348:	6422                	ld	s0,8(sp)
 34a:	0141                	addi	sp,sp,16
 34c:	8082                	ret
  n = 0;
 34e:	4501                	li	a0,0
 350:	bfe5                	j	348 <atoi+0x40>

0000000000000352 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 352:	1141                	addi	sp,sp,-16
 354:	e422                	sd	s0,8(sp)
 356:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 358:	02b57663          	bgeu	a0,a1,384 <memmove+0x32>
    while(n-- > 0)
 35c:	02c05163          	blez	a2,37e <memmove+0x2c>
 360:	fff6079b          	addiw	a5,a2,-1
 364:	1782                	slli	a5,a5,0x20
 366:	9381                	srli	a5,a5,0x20
 368:	0785                	addi	a5,a5,1
 36a:	97aa                	add	a5,a5,a0
  dst = vdst;
 36c:	872a                	mv	a4,a0
      *dst++ = *src++;
 36e:	0585                	addi	a1,a1,1
 370:	0705                	addi	a4,a4,1
 372:	fff5c683          	lbu	a3,-1(a1)
 376:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 37a:	fee79ae3          	bne	a5,a4,36e <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 37e:	6422                	ld	s0,8(sp)
 380:	0141                	addi	sp,sp,16
 382:	8082                	ret
    dst += n;
 384:	00c50733          	add	a4,a0,a2
    src += n;
 388:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 38a:	fec05ae3          	blez	a2,37e <memmove+0x2c>
 38e:	fff6079b          	addiw	a5,a2,-1
 392:	1782                	slli	a5,a5,0x20
 394:	9381                	srli	a5,a5,0x20
 396:	fff7c793          	not	a5,a5
 39a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 39c:	15fd                	addi	a1,a1,-1
 39e:	177d                	addi	a4,a4,-1
 3a0:	0005c683          	lbu	a3,0(a1)
 3a4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3a8:	fee79ae3          	bne	a5,a4,39c <memmove+0x4a>
 3ac:	bfc9                	j	37e <memmove+0x2c>

00000000000003ae <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3ae:	1141                	addi	sp,sp,-16
 3b0:	e422                	sd	s0,8(sp)
 3b2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3b4:	ca05                	beqz	a2,3e4 <memcmp+0x36>
 3b6:	fff6069b          	addiw	a3,a2,-1
 3ba:	1682                	slli	a3,a3,0x20
 3bc:	9281                	srli	a3,a3,0x20
 3be:	0685                	addi	a3,a3,1
 3c0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3c2:	00054783          	lbu	a5,0(a0)
 3c6:	0005c703          	lbu	a4,0(a1)
 3ca:	00e79863          	bne	a5,a4,3da <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3ce:	0505                	addi	a0,a0,1
    p2++;
 3d0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3d2:	fed518e3          	bne	a0,a3,3c2 <memcmp+0x14>
  }
  return 0;
 3d6:	4501                	li	a0,0
 3d8:	a019                	j	3de <memcmp+0x30>
      return *p1 - *p2;
 3da:	40e7853b          	subw	a0,a5,a4
}
 3de:	6422                	ld	s0,8(sp)
 3e0:	0141                	addi	sp,sp,16
 3e2:	8082                	ret
  return 0;
 3e4:	4501                	li	a0,0
 3e6:	bfe5                	j	3de <memcmp+0x30>

00000000000003e8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3e8:	1141                	addi	sp,sp,-16
 3ea:	e406                	sd	ra,8(sp)
 3ec:	e022                	sd	s0,0(sp)
 3ee:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3f0:	00000097          	auipc	ra,0x0
 3f4:	f62080e7          	jalr	-158(ra) # 352 <memmove>
}
 3f8:	60a2                	ld	ra,8(sp)
 3fa:	6402                	ld	s0,0(sp)
 3fc:	0141                	addi	sp,sp,16
 3fe:	8082                	ret

0000000000000400 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 400:	4885                	li	a7,1
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <exit>:
.global exit
exit:
 li a7, SYS_exit
 408:	4889                	li	a7,2
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <wait>:
.global wait
wait:
 li a7, SYS_wait
 410:	488d                	li	a7,3
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 418:	4891                	li	a7,4
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <read>:
.global read
read:
 li a7, SYS_read
 420:	4895                	li	a7,5
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <write>:
.global write
write:
 li a7, SYS_write
 428:	48c1                	li	a7,16
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 430:	48ed                	li	a7,27
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <close>:
.global close
close:
 li a7, SYS_close
 438:	48d5                	li	a7,21
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <kill>:
.global kill
kill:
 li a7, SYS_kill
 440:	4899                	li	a7,6
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <exec>:
.global exec
exec:
 li a7, SYS_exec
 448:	489d                	li	a7,7
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <open>:
.global open
open:
 li a7, SYS_open
 450:	48bd                	li	a7,15
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 458:	48c5                	li	a7,17
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 460:	48c9                	li	a7,18
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 468:	48a1                	li	a7,8
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <link>:
.global link
link:
 li a7, SYS_link
 470:	48cd                	li	a7,19
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 478:	48d1                	li	a7,20
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 480:	48a5                	li	a7,9
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <dup>:
.global dup
dup:
 li a7, SYS_dup
 488:	48a9                	li	a7,10
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 490:	48ad                	li	a7,11
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 498:	48b1                	li	a7,12
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4a0:	48b5                	li	a7,13
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4a8:	48b9                	li	a7,14
 ecall
 4aa:	00000073          	ecall
 ret
 4ae:	8082                	ret

00000000000004b0 <trace>:
.global trace
trace:
 li a7, SYS_trace
 4b0:	48d9                	li	a7,22
 ecall
 4b2:	00000073          	ecall
 ret
 4b6:	8082                	ret

00000000000004b8 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 4b8:	48dd                	li	a7,23
 ecall
 4ba:	00000073          	ecall
 ret
 4be:	8082                	ret

00000000000004c0 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 4c0:	48e1                	li	a7,24
 ecall
 4c2:	00000073          	ecall
 ret
 4c6:	8082                	ret

00000000000004c8 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 4c8:	48e5                	li	a7,25
 ecall
 4ca:	00000073          	ecall
 ret
 4ce:	8082                	ret

00000000000004d0 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 4d0:	48e9                	li	a7,26
 ecall
 4d2:	00000073          	ecall
 ret
 4d6:	8082                	ret

00000000000004d8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4d8:	1101                	addi	sp,sp,-32
 4da:	ec06                	sd	ra,24(sp)
 4dc:	e822                	sd	s0,16(sp)
 4de:	1000                	addi	s0,sp,32
 4e0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4e4:	4605                	li	a2,1
 4e6:	fef40593          	addi	a1,s0,-17
 4ea:	00000097          	auipc	ra,0x0
 4ee:	f3e080e7          	jalr	-194(ra) # 428 <write>
}
 4f2:	60e2                	ld	ra,24(sp)
 4f4:	6442                	ld	s0,16(sp)
 4f6:	6105                	addi	sp,sp,32
 4f8:	8082                	ret

00000000000004fa <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4fa:	7139                	addi	sp,sp,-64
 4fc:	fc06                	sd	ra,56(sp)
 4fe:	f822                	sd	s0,48(sp)
 500:	f426                	sd	s1,40(sp)
 502:	f04a                	sd	s2,32(sp)
 504:	ec4e                	sd	s3,24(sp)
 506:	0080                	addi	s0,sp,64
 508:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 50a:	c299                	beqz	a3,510 <printint+0x16>
 50c:	0805c863          	bltz	a1,59c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 510:	2581                	sext.w	a1,a1
  neg = 0;
 512:	4881                	li	a7,0
 514:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 518:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 51a:	2601                	sext.w	a2,a2
 51c:	00000517          	auipc	a0,0x0
 520:	47450513          	addi	a0,a0,1140 # 990 <digits>
 524:	883a                	mv	a6,a4
 526:	2705                	addiw	a4,a4,1
 528:	02c5f7bb          	remuw	a5,a1,a2
 52c:	1782                	slli	a5,a5,0x20
 52e:	9381                	srli	a5,a5,0x20
 530:	97aa                	add	a5,a5,a0
 532:	0007c783          	lbu	a5,0(a5)
 536:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 53a:	0005879b          	sext.w	a5,a1
 53e:	02c5d5bb          	divuw	a1,a1,a2
 542:	0685                	addi	a3,a3,1
 544:	fec7f0e3          	bgeu	a5,a2,524 <printint+0x2a>
  if(neg)
 548:	00088b63          	beqz	a7,55e <printint+0x64>
    buf[i++] = '-';
 54c:	fd040793          	addi	a5,s0,-48
 550:	973e                	add	a4,a4,a5
 552:	02d00793          	li	a5,45
 556:	fef70823          	sb	a5,-16(a4)
 55a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 55e:	02e05863          	blez	a4,58e <printint+0x94>
 562:	fc040793          	addi	a5,s0,-64
 566:	00e78933          	add	s2,a5,a4
 56a:	fff78993          	addi	s3,a5,-1
 56e:	99ba                	add	s3,s3,a4
 570:	377d                	addiw	a4,a4,-1
 572:	1702                	slli	a4,a4,0x20
 574:	9301                	srli	a4,a4,0x20
 576:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 57a:	fff94583          	lbu	a1,-1(s2)
 57e:	8526                	mv	a0,s1
 580:	00000097          	auipc	ra,0x0
 584:	f58080e7          	jalr	-168(ra) # 4d8 <putc>
  while(--i >= 0)
 588:	197d                	addi	s2,s2,-1
 58a:	ff3918e3          	bne	s2,s3,57a <printint+0x80>
}
 58e:	70e2                	ld	ra,56(sp)
 590:	7442                	ld	s0,48(sp)
 592:	74a2                	ld	s1,40(sp)
 594:	7902                	ld	s2,32(sp)
 596:	69e2                	ld	s3,24(sp)
 598:	6121                	addi	sp,sp,64
 59a:	8082                	ret
    x = -xx;
 59c:	40b005bb          	negw	a1,a1
    neg = 1;
 5a0:	4885                	li	a7,1
    x = -xx;
 5a2:	bf8d                	j	514 <printint+0x1a>

00000000000005a4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5a4:	7119                	addi	sp,sp,-128
 5a6:	fc86                	sd	ra,120(sp)
 5a8:	f8a2                	sd	s0,112(sp)
 5aa:	f4a6                	sd	s1,104(sp)
 5ac:	f0ca                	sd	s2,96(sp)
 5ae:	ecce                	sd	s3,88(sp)
 5b0:	e8d2                	sd	s4,80(sp)
 5b2:	e4d6                	sd	s5,72(sp)
 5b4:	e0da                	sd	s6,64(sp)
 5b6:	fc5e                	sd	s7,56(sp)
 5b8:	f862                	sd	s8,48(sp)
 5ba:	f466                	sd	s9,40(sp)
 5bc:	f06a                	sd	s10,32(sp)
 5be:	ec6e                	sd	s11,24(sp)
 5c0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5c2:	0005c903          	lbu	s2,0(a1)
 5c6:	18090f63          	beqz	s2,764 <vprintf+0x1c0>
 5ca:	8aaa                	mv	s5,a0
 5cc:	8b32                	mv	s6,a2
 5ce:	00158493          	addi	s1,a1,1
  state = 0;
 5d2:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5d4:	02500a13          	li	s4,37
      if(c == 'd'){
 5d8:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5dc:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5e0:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5e4:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5e8:	00000b97          	auipc	s7,0x0
 5ec:	3a8b8b93          	addi	s7,s7,936 # 990 <digits>
 5f0:	a839                	j	60e <vprintf+0x6a>
        putc(fd, c);
 5f2:	85ca                	mv	a1,s2
 5f4:	8556                	mv	a0,s5
 5f6:	00000097          	auipc	ra,0x0
 5fa:	ee2080e7          	jalr	-286(ra) # 4d8 <putc>
 5fe:	a019                	j	604 <vprintf+0x60>
    } else if(state == '%'){
 600:	01498f63          	beq	s3,s4,61e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 604:	0485                	addi	s1,s1,1
 606:	fff4c903          	lbu	s2,-1(s1)
 60a:	14090d63          	beqz	s2,764 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 60e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 612:	fe0997e3          	bnez	s3,600 <vprintf+0x5c>
      if(c == '%'){
 616:	fd479ee3          	bne	a5,s4,5f2 <vprintf+0x4e>
        state = '%';
 61a:	89be                	mv	s3,a5
 61c:	b7e5                	j	604 <vprintf+0x60>
      if(c == 'd'){
 61e:	05878063          	beq	a5,s8,65e <vprintf+0xba>
      } else if(c == 'l') {
 622:	05978c63          	beq	a5,s9,67a <vprintf+0xd6>
      } else if(c == 'x') {
 626:	07a78863          	beq	a5,s10,696 <vprintf+0xf2>
      } else if(c == 'p') {
 62a:	09b78463          	beq	a5,s11,6b2 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 62e:	07300713          	li	a4,115
 632:	0ce78663          	beq	a5,a4,6fe <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 636:	06300713          	li	a4,99
 63a:	0ee78e63          	beq	a5,a4,736 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 63e:	11478863          	beq	a5,s4,74e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 642:	85d2                	mv	a1,s4
 644:	8556                	mv	a0,s5
 646:	00000097          	auipc	ra,0x0
 64a:	e92080e7          	jalr	-366(ra) # 4d8 <putc>
        putc(fd, c);
 64e:	85ca                	mv	a1,s2
 650:	8556                	mv	a0,s5
 652:	00000097          	auipc	ra,0x0
 656:	e86080e7          	jalr	-378(ra) # 4d8 <putc>
      }
      state = 0;
 65a:	4981                	li	s3,0
 65c:	b765                	j	604 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 65e:	008b0913          	addi	s2,s6,8
 662:	4685                	li	a3,1
 664:	4629                	li	a2,10
 666:	000b2583          	lw	a1,0(s6)
 66a:	8556                	mv	a0,s5
 66c:	00000097          	auipc	ra,0x0
 670:	e8e080e7          	jalr	-370(ra) # 4fa <printint>
 674:	8b4a                	mv	s6,s2
      state = 0;
 676:	4981                	li	s3,0
 678:	b771                	j	604 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 67a:	008b0913          	addi	s2,s6,8
 67e:	4681                	li	a3,0
 680:	4629                	li	a2,10
 682:	000b2583          	lw	a1,0(s6)
 686:	8556                	mv	a0,s5
 688:	00000097          	auipc	ra,0x0
 68c:	e72080e7          	jalr	-398(ra) # 4fa <printint>
 690:	8b4a                	mv	s6,s2
      state = 0;
 692:	4981                	li	s3,0
 694:	bf85                	j	604 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 696:	008b0913          	addi	s2,s6,8
 69a:	4681                	li	a3,0
 69c:	4641                	li	a2,16
 69e:	000b2583          	lw	a1,0(s6)
 6a2:	8556                	mv	a0,s5
 6a4:	00000097          	auipc	ra,0x0
 6a8:	e56080e7          	jalr	-426(ra) # 4fa <printint>
 6ac:	8b4a                	mv	s6,s2
      state = 0;
 6ae:	4981                	li	s3,0
 6b0:	bf91                	j	604 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6b2:	008b0793          	addi	a5,s6,8
 6b6:	f8f43423          	sd	a5,-120(s0)
 6ba:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6be:	03000593          	li	a1,48
 6c2:	8556                	mv	a0,s5
 6c4:	00000097          	auipc	ra,0x0
 6c8:	e14080e7          	jalr	-492(ra) # 4d8 <putc>
  putc(fd, 'x');
 6cc:	85ea                	mv	a1,s10
 6ce:	8556                	mv	a0,s5
 6d0:	00000097          	auipc	ra,0x0
 6d4:	e08080e7          	jalr	-504(ra) # 4d8 <putc>
 6d8:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6da:	03c9d793          	srli	a5,s3,0x3c
 6de:	97de                	add	a5,a5,s7
 6e0:	0007c583          	lbu	a1,0(a5)
 6e4:	8556                	mv	a0,s5
 6e6:	00000097          	auipc	ra,0x0
 6ea:	df2080e7          	jalr	-526(ra) # 4d8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6ee:	0992                	slli	s3,s3,0x4
 6f0:	397d                	addiw	s2,s2,-1
 6f2:	fe0914e3          	bnez	s2,6da <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6f6:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6fa:	4981                	li	s3,0
 6fc:	b721                	j	604 <vprintf+0x60>
        s = va_arg(ap, char*);
 6fe:	008b0993          	addi	s3,s6,8
 702:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 706:	02090163          	beqz	s2,728 <vprintf+0x184>
        while(*s != 0){
 70a:	00094583          	lbu	a1,0(s2)
 70e:	c9a1                	beqz	a1,75e <vprintf+0x1ba>
          putc(fd, *s);
 710:	8556                	mv	a0,s5
 712:	00000097          	auipc	ra,0x0
 716:	dc6080e7          	jalr	-570(ra) # 4d8 <putc>
          s++;
 71a:	0905                	addi	s2,s2,1
        while(*s != 0){
 71c:	00094583          	lbu	a1,0(s2)
 720:	f9e5                	bnez	a1,710 <vprintf+0x16c>
        s = va_arg(ap, char*);
 722:	8b4e                	mv	s6,s3
      state = 0;
 724:	4981                	li	s3,0
 726:	bdf9                	j	604 <vprintf+0x60>
          s = "(null)";
 728:	00000917          	auipc	s2,0x0
 72c:	26090913          	addi	s2,s2,608 # 988 <malloc+0x11a>
        while(*s != 0){
 730:	02800593          	li	a1,40
 734:	bff1                	j	710 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 736:	008b0913          	addi	s2,s6,8
 73a:	000b4583          	lbu	a1,0(s6)
 73e:	8556                	mv	a0,s5
 740:	00000097          	auipc	ra,0x0
 744:	d98080e7          	jalr	-616(ra) # 4d8 <putc>
 748:	8b4a                	mv	s6,s2
      state = 0;
 74a:	4981                	li	s3,0
 74c:	bd65                	j	604 <vprintf+0x60>
        putc(fd, c);
 74e:	85d2                	mv	a1,s4
 750:	8556                	mv	a0,s5
 752:	00000097          	auipc	ra,0x0
 756:	d86080e7          	jalr	-634(ra) # 4d8 <putc>
      state = 0;
 75a:	4981                	li	s3,0
 75c:	b565                	j	604 <vprintf+0x60>
        s = va_arg(ap, char*);
 75e:	8b4e                	mv	s6,s3
      state = 0;
 760:	4981                	li	s3,0
 762:	b54d                	j	604 <vprintf+0x60>
    }
  }
}
 764:	70e6                	ld	ra,120(sp)
 766:	7446                	ld	s0,112(sp)
 768:	74a6                	ld	s1,104(sp)
 76a:	7906                	ld	s2,96(sp)
 76c:	69e6                	ld	s3,88(sp)
 76e:	6a46                	ld	s4,80(sp)
 770:	6aa6                	ld	s5,72(sp)
 772:	6b06                	ld	s6,64(sp)
 774:	7be2                	ld	s7,56(sp)
 776:	7c42                	ld	s8,48(sp)
 778:	7ca2                	ld	s9,40(sp)
 77a:	7d02                	ld	s10,32(sp)
 77c:	6de2                	ld	s11,24(sp)
 77e:	6109                	addi	sp,sp,128
 780:	8082                	ret

0000000000000782 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 782:	715d                	addi	sp,sp,-80
 784:	ec06                	sd	ra,24(sp)
 786:	e822                	sd	s0,16(sp)
 788:	1000                	addi	s0,sp,32
 78a:	e010                	sd	a2,0(s0)
 78c:	e414                	sd	a3,8(s0)
 78e:	e818                	sd	a4,16(s0)
 790:	ec1c                	sd	a5,24(s0)
 792:	03043023          	sd	a6,32(s0)
 796:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 79a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 79e:	8622                	mv	a2,s0
 7a0:	00000097          	auipc	ra,0x0
 7a4:	e04080e7          	jalr	-508(ra) # 5a4 <vprintf>
}
 7a8:	60e2                	ld	ra,24(sp)
 7aa:	6442                	ld	s0,16(sp)
 7ac:	6161                	addi	sp,sp,80
 7ae:	8082                	ret

00000000000007b0 <printf>:

void
printf(const char *fmt, ...)
{
 7b0:	711d                	addi	sp,sp,-96
 7b2:	ec06                	sd	ra,24(sp)
 7b4:	e822                	sd	s0,16(sp)
 7b6:	1000                	addi	s0,sp,32
 7b8:	e40c                	sd	a1,8(s0)
 7ba:	e810                	sd	a2,16(s0)
 7bc:	ec14                	sd	a3,24(s0)
 7be:	f018                	sd	a4,32(s0)
 7c0:	f41c                	sd	a5,40(s0)
 7c2:	03043823          	sd	a6,48(s0)
 7c6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7ca:	00840613          	addi	a2,s0,8
 7ce:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7d2:	85aa                	mv	a1,a0
 7d4:	4505                	li	a0,1
 7d6:	00000097          	auipc	ra,0x0
 7da:	dce080e7          	jalr	-562(ra) # 5a4 <vprintf>
}
 7de:	60e2                	ld	ra,24(sp)
 7e0:	6442                	ld	s0,16(sp)
 7e2:	6125                	addi	sp,sp,96
 7e4:	8082                	ret

00000000000007e6 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7e6:	1141                	addi	sp,sp,-16
 7e8:	e422                	sd	s0,8(sp)
 7ea:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7ec:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7f0:	00001797          	auipc	a5,0x1
 7f4:	8107b783          	ld	a5,-2032(a5) # 1000 <freep>
 7f8:	a805                	j	828 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7fa:	4618                	lw	a4,8(a2)
 7fc:	9db9                	addw	a1,a1,a4
 7fe:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 802:	6398                	ld	a4,0(a5)
 804:	6318                	ld	a4,0(a4)
 806:	fee53823          	sd	a4,-16(a0)
 80a:	a091                	j	84e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 80c:	ff852703          	lw	a4,-8(a0)
 810:	9e39                	addw	a2,a2,a4
 812:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 814:	ff053703          	ld	a4,-16(a0)
 818:	e398                	sd	a4,0(a5)
 81a:	a099                	j	860 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 81c:	6398                	ld	a4,0(a5)
 81e:	00e7e463          	bltu	a5,a4,826 <free+0x40>
 822:	00e6ea63          	bltu	a3,a4,836 <free+0x50>
{
 826:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 828:	fed7fae3          	bgeu	a5,a3,81c <free+0x36>
 82c:	6398                	ld	a4,0(a5)
 82e:	00e6e463          	bltu	a3,a4,836 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 832:	fee7eae3          	bltu	a5,a4,826 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 836:	ff852583          	lw	a1,-8(a0)
 83a:	6390                	ld	a2,0(a5)
 83c:	02059713          	slli	a4,a1,0x20
 840:	9301                	srli	a4,a4,0x20
 842:	0712                	slli	a4,a4,0x4
 844:	9736                	add	a4,a4,a3
 846:	fae60ae3          	beq	a2,a4,7fa <free+0x14>
    bp->s.ptr = p->s.ptr;
 84a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 84e:	4790                	lw	a2,8(a5)
 850:	02061713          	slli	a4,a2,0x20
 854:	9301                	srli	a4,a4,0x20
 856:	0712                	slli	a4,a4,0x4
 858:	973e                	add	a4,a4,a5
 85a:	fae689e3          	beq	a3,a4,80c <free+0x26>
  } else
    p->s.ptr = bp;
 85e:	e394                	sd	a3,0(a5)
  freep = p;
 860:	00000717          	auipc	a4,0x0
 864:	7af73023          	sd	a5,1952(a4) # 1000 <freep>
}
 868:	6422                	ld	s0,8(sp)
 86a:	0141                	addi	sp,sp,16
 86c:	8082                	ret

000000000000086e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 86e:	7139                	addi	sp,sp,-64
 870:	fc06                	sd	ra,56(sp)
 872:	f822                	sd	s0,48(sp)
 874:	f426                	sd	s1,40(sp)
 876:	f04a                	sd	s2,32(sp)
 878:	ec4e                	sd	s3,24(sp)
 87a:	e852                	sd	s4,16(sp)
 87c:	e456                	sd	s5,8(sp)
 87e:	e05a                	sd	s6,0(sp)
 880:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 882:	02051493          	slli	s1,a0,0x20
 886:	9081                	srli	s1,s1,0x20
 888:	04bd                	addi	s1,s1,15
 88a:	8091                	srli	s1,s1,0x4
 88c:	0014899b          	addiw	s3,s1,1
 890:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 892:	00000517          	auipc	a0,0x0
 896:	76e53503          	ld	a0,1902(a0) # 1000 <freep>
 89a:	c515                	beqz	a0,8c6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 89c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 89e:	4798                	lw	a4,8(a5)
 8a0:	02977f63          	bgeu	a4,s1,8de <malloc+0x70>
 8a4:	8a4e                	mv	s4,s3
 8a6:	0009871b          	sext.w	a4,s3
 8aa:	6685                	lui	a3,0x1
 8ac:	00d77363          	bgeu	a4,a3,8b2 <malloc+0x44>
 8b0:	6a05                	lui	s4,0x1
 8b2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8b6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8ba:	00000917          	auipc	s2,0x0
 8be:	74690913          	addi	s2,s2,1862 # 1000 <freep>
  if(p == (char*)-1)
 8c2:	5afd                	li	s5,-1
 8c4:	a88d                	j	936 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8c6:	00000797          	auipc	a5,0x0
 8ca:	74a78793          	addi	a5,a5,1866 # 1010 <base>
 8ce:	00000717          	auipc	a4,0x0
 8d2:	72f73923          	sd	a5,1842(a4) # 1000 <freep>
 8d6:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8d8:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8dc:	b7e1                	j	8a4 <malloc+0x36>
      if(p->s.size == nunits)
 8de:	02e48b63          	beq	s1,a4,914 <malloc+0xa6>
        p->s.size -= nunits;
 8e2:	4137073b          	subw	a4,a4,s3
 8e6:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8e8:	1702                	slli	a4,a4,0x20
 8ea:	9301                	srli	a4,a4,0x20
 8ec:	0712                	slli	a4,a4,0x4
 8ee:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8f0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8f4:	00000717          	auipc	a4,0x0
 8f8:	70a73623          	sd	a0,1804(a4) # 1000 <freep>
      return (void*)(p + 1);
 8fc:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 900:	70e2                	ld	ra,56(sp)
 902:	7442                	ld	s0,48(sp)
 904:	74a2                	ld	s1,40(sp)
 906:	7902                	ld	s2,32(sp)
 908:	69e2                	ld	s3,24(sp)
 90a:	6a42                	ld	s4,16(sp)
 90c:	6aa2                	ld	s5,8(sp)
 90e:	6b02                	ld	s6,0(sp)
 910:	6121                	addi	sp,sp,64
 912:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 914:	6398                	ld	a4,0(a5)
 916:	e118                	sd	a4,0(a0)
 918:	bff1                	j	8f4 <malloc+0x86>
  hp->s.size = nu;
 91a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 91e:	0541                	addi	a0,a0,16
 920:	00000097          	auipc	ra,0x0
 924:	ec6080e7          	jalr	-314(ra) # 7e6 <free>
  return freep;
 928:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 92c:	d971                	beqz	a0,900 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 92e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 930:	4798                	lw	a4,8(a5)
 932:	fa9776e3          	bgeu	a4,s1,8de <malloc+0x70>
    if(p == freep)
 936:	00093703          	ld	a4,0(s2)
 93a:	853e                	mv	a0,a5
 93c:	fef719e3          	bne	a4,a5,92e <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 940:	8552                	mv	a0,s4
 942:	00000097          	auipc	ra,0x0
 946:	b56080e7          	jalr	-1194(ra) # 498 <sbrk>
  if(p == (char*)-1)
 94a:	fd5518e3          	bne	a0,s5,91a <malloc+0xac>
        return 0;
 94e:	4501                	li	a0,0
 950:	bf45                	j	900 <malloc+0x92>
