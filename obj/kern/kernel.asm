
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 80 19 10 f0 	movl   $0xf0101980,(%esp)
f0100055:	e8 bc 08 00 00       	call   f0100916 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 ef 06 00 00       	call   f0100776 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 9c 19 10 f0 	movl   $0xf010199c,(%esp)
f0100092:	e8 7f 08 00 00       	call   f0100916 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 b1 13 00 00       	call   f0101476 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 92 04 00 00       	call   f010055c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 19 10 f0 	movl   $0xf01019b7,(%esp)
f01000d9:	e8 38 08 00 00       	call   f0100916 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 8a 06 00 00       	call   f0100780 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 d2 19 10 f0 	movl   $0xf01019d2,(%esp)
f010012c:	e8 e5 07 00 00       	call   f0100916 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 a6 07 00 00       	call   f01008e3 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f0100144:	e8 cd 07 00 00       	call   f0100916 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 2b 06 00 00       	call   f0100780 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ea 19 10 f0 	movl   $0xf01019ea,(%esp)
f0100176:	e8 9b 07 00 00       	call   f0100916 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 59 07 00 00       	call   f01008e3 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 0e 1a 10 f0 	movl   $0xf0101a0e,(%esp)
f0100191:	e8 80 07 00 00       	call   f0100916 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001bc:	a8 01                	test   $0x1,%al
f01001be:	74 06                	je     f01001c6 <serial_proc_data+0x18>
f01001c0:	b2 f8                	mov    $0xf8,%dl
f01001c2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c3:	0f b6 c8             	movzbl %al,%ecx
}
f01001c6:	89 c8                	mov    %ecx,%eax
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 25                	jmp    f01001fa <cons_intr+0x30>
		if (c == 0)
f01001d5:	85 c0                	test   %eax,%eax
f01001d7:	74 21                	je     f01001fa <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	8b 15 44 25 11 f0    	mov    0xf0112544,%edx
f01001df:	88 82 40 23 11 f0    	mov    %al,-0xfeedcc0(%edx)
f01001e5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f2:	0f 44 c2             	cmove  %edx,%eax
f01001f5:	a3 44 25 11 f0       	mov    %eax,0xf0112544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d4                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 c7                	mov    %eax,%edi
f0100212:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100217:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f0100218:	a8 20                	test   $0x20,%al
f010021a:	75 1b                	jne    f0100237 <cons_putc+0x30>
f010021c:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100221:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100226:	e8 75 ff ff ff       	call   f01001a0 <delay>
f010022b:	89 f2                	mov    %esi,%edx
f010022d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010022e:	a8 20                	test   $0x20,%al
f0100230:	75 05                	jne    f0100237 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100232:	83 eb 01             	sub    $0x1,%ebx
f0100235:	75 ef                	jne    f0100226 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f0100237:	89 fa                	mov    %edi,%edx
f0100239:	89 f8                	mov    %edi,%eax
f010023b:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100243:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100244:	b2 79                	mov    $0x79,%dl
f0100246:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100247:	84 c0                	test   %al,%al
f0100249:	78 1b                	js     f0100266 <cons_putc+0x5f>
f010024b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100250:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100255:	e8 46 ff ff ff       	call   f01001a0 <delay>
f010025a:	89 f2                	mov    %esi,%edx
f010025c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010025d:	84 c0                	test   %al,%al
f010025f:	78 05                	js     f0100266 <cons_putc+0x5f>
f0100261:	83 eb 01             	sub    $0x1,%ebx
f0100264:	75 ef                	jne    f0100255 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100266:	ba 78 03 00 00       	mov    $0x378,%edx
f010026b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010026f:	ee                   	out    %al,(%dx)
f0100270:	b2 7a                	mov    $0x7a,%dl
f0100272:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100277:	ee                   	out    %al,(%dx)
f0100278:	b8 08 00 00 00       	mov    $0x8,%eax
f010027d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010027e:	89 fa                	mov    %edi,%edx
f0100280:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100286:	89 f8                	mov    %edi,%eax
f0100288:	80 cc 07             	or     $0x7,%ah
f010028b:	85 d2                	test   %edx,%edx
f010028d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100290:	89 f8                	mov    %edi,%eax
f0100292:	25 ff 00 00 00       	and    $0xff,%eax
f0100297:	83 f8 09             	cmp    $0x9,%eax
f010029a:	74 7c                	je     f0100318 <cons_putc+0x111>
f010029c:	83 f8 09             	cmp    $0x9,%eax
f010029f:	7f 0b                	jg     f01002ac <cons_putc+0xa5>
f01002a1:	83 f8 08             	cmp    $0x8,%eax
f01002a4:	0f 85 a2 00 00 00    	jne    f010034c <cons_putc+0x145>
f01002aa:	eb 16                	jmp    f01002c2 <cons_putc+0xbb>
f01002ac:	83 f8 0a             	cmp    $0xa,%eax
f01002af:	90                   	nop
f01002b0:	74 40                	je     f01002f2 <cons_putc+0xeb>
f01002b2:	83 f8 0d             	cmp    $0xd,%eax
f01002b5:	0f 85 91 00 00 00    	jne    f010034c <cons_putc+0x145>
f01002bb:	90                   	nop
f01002bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01002c0:	eb 38                	jmp    f01002fa <cons_putc+0xf3>
	case '\b':
		if (crt_pos > 0) {
f01002c2:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f01002c9:	66 85 c0             	test   %ax,%ax
f01002cc:	0f 84 e4 00 00 00    	je     f01003b6 <cons_putc+0x1af>
			crt_pos--;
f01002d2:	83 e8 01             	sub    $0x1,%eax
f01002d5:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002db:	0f b7 c0             	movzwl %ax,%eax
f01002de:	66 81 e7 00 ff       	and    $0xff00,%di
f01002e3:	83 cf 20             	or     $0x20,%edi
f01002e6:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f01002ec:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002f0:	eb 77                	jmp    f0100369 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002f2:	66 83 05 54 25 11 f0 	addw   $0x50,0xf0112554
f01002f9:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002fa:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100301:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100307:	c1 e8 16             	shr    $0x16,%eax
f010030a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010030d:	c1 e0 04             	shl    $0x4,%eax
f0100310:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
f0100316:	eb 51                	jmp    f0100369 <cons_putc+0x162>
		break;
	case '\t':
		cons_putc(' ');
f0100318:	b8 20 00 00 00       	mov    $0x20,%eax
f010031d:	e8 e5 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100322:	b8 20 00 00 00       	mov    $0x20,%eax
f0100327:	e8 db fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010032c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100331:	e8 d1 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100336:	b8 20 00 00 00       	mov    $0x20,%eax
f010033b:	e8 c7 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100340:	b8 20 00 00 00       	mov    $0x20,%eax
f0100345:	e8 bd fe ff ff       	call   f0100207 <cons_putc>
f010034a:	eb 1d                	jmp    f0100369 <cons_putc+0x162>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010034c:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100353:	0f b7 c8             	movzwl %ax,%ecx
f0100356:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f010035c:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100360:	83 c0 01             	add    $0x1,%eax
f0100363:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100369:	66 81 3d 54 25 11 f0 	cmpw   $0x7cf,0xf0112554
f0100370:	cf 07 
f0100372:	76 42                	jbe    f01003b6 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100374:	a1 50 25 11 f0       	mov    0xf0112550,%eax
f0100379:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100380:	00 
f0100381:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100387:	89 54 24 04          	mov    %edx,0x4(%esp)
f010038b:	89 04 24             	mov    %eax,(%esp)
f010038e:	e8 3e 11 00 00       	call   f01014d1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100393:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100399:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010039e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a4:	83 c0 01             	add    $0x1,%eax
f01003a7:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003ac:	75 f0                	jne    f010039e <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003ae:	66 83 2d 54 25 11 f0 	subw   $0x50,0xf0112554
f01003b5:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003b6:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01003bc:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003c1:	89 ca                	mov    %ecx,%edx
f01003c3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003c4:	0f b7 35 54 25 11 f0 	movzwl 0xf0112554,%esi
f01003cb:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003ce:	89 f0                	mov    %esi,%eax
f01003d0:	66 c1 e8 08          	shr    $0x8,%ax
f01003d4:	89 da                	mov    %ebx,%edx
f01003d6:	ee                   	out    %al,(%dx)
f01003d7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003dc:	89 ca                	mov    %ecx,%edx
f01003de:	ee                   	out    %al,(%dx)
f01003df:	89 f0                	mov    %esi,%eax
f01003e1:	89 da                	mov    %ebx,%edx
f01003e3:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003e4:	83 c4 2c             	add    $0x2c,%esp
f01003e7:	5b                   	pop    %ebx
f01003e8:	5e                   	pop    %esi
f01003e9:	5f                   	pop    %edi
f01003ea:	5d                   	pop    %ebp
f01003eb:	c3                   	ret    

f01003ec <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003ec:	55                   	push   %ebp
f01003ed:	89 e5                	mov    %esp,%ebp
f01003ef:	53                   	push   %ebx
f01003f0:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f3:	ba 64 00 00 00       	mov    $0x64,%edx
f01003f8:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003f9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003fe:	a8 01                	test   $0x1,%al
f0100400:	0f 84 de 00 00 00    	je     f01004e4 <kbd_proc_data+0xf8>
f0100406:	b2 60                	mov    $0x60,%dl
f0100408:	ec                   	in     (%dx),%al
f0100409:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010040b:	3c e0                	cmp    $0xe0,%al
f010040d:	75 11                	jne    f0100420 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f010040f:	83 0d 48 25 11 f0 40 	orl    $0x40,0xf0112548
		return 0;
f0100416:	bb 00 00 00 00       	mov    $0x0,%ebx
f010041b:	e9 c4 00 00 00       	jmp    f01004e4 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f0100420:	84 c0                	test   %al,%al
f0100422:	79 37                	jns    f010045b <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100424:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f010042a:	89 cb                	mov    %ecx,%ebx
f010042c:	83 e3 40             	and    $0x40,%ebx
f010042f:	83 e0 7f             	and    $0x7f,%eax
f0100432:	85 db                	test   %ebx,%ebx
f0100434:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100437:	0f b6 d2             	movzbl %dl,%edx
f010043a:	0f b6 82 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%eax
f0100441:	83 c8 40             	or     $0x40,%eax
f0100444:	0f b6 c0             	movzbl %al,%eax
f0100447:	f7 d0                	not    %eax
f0100449:	21 c1                	and    %eax,%ecx
f010044b:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
		return 0;
f0100451:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100456:	e9 89 00 00 00       	jmp    f01004e4 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010045b:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f0100461:	f6 c1 40             	test   $0x40,%cl
f0100464:	74 0e                	je     f0100474 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100466:	89 c2                	mov    %eax,%edx
f0100468:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010046b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010046e:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
	}

	shift |= shiftcode[data];
f0100474:	0f b6 d2             	movzbl %dl,%edx
f0100477:	0f b6 82 40 1a 10 f0 	movzbl -0xfefe5c0(%edx),%eax
f010047e:	0b 05 48 25 11 f0    	or     0xf0112548,%eax
	shift ^= togglecode[data];
f0100484:	0f b6 8a 40 1b 10 f0 	movzbl -0xfefe4c0(%edx),%ecx
f010048b:	31 c8                	xor    %ecx,%eax
f010048d:	a3 48 25 11 f0       	mov    %eax,0xf0112548

	c = charcode[shift & (CTL | SHIFT)][data];
f0100492:	89 c1                	mov    %eax,%ecx
f0100494:	83 e1 03             	and    $0x3,%ecx
f0100497:	8b 0c 8d 40 1c 10 f0 	mov    -0xfefe3c0(,%ecx,4),%ecx
f010049e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f01004a2:	a8 08                	test   $0x8,%al
f01004a4:	74 19                	je     f01004bf <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004a6:	8d 53 9f             	lea    -0x61(%ebx),%edx
f01004a9:	83 fa 19             	cmp    $0x19,%edx
f01004ac:	77 05                	ja     f01004b3 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004ae:	83 eb 20             	sub    $0x20,%ebx
f01004b1:	eb 0c                	jmp    f01004bf <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004b3:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f01004b6:	8d 53 20             	lea    0x20(%ebx),%edx
f01004b9:	83 f9 19             	cmp    $0x19,%ecx
f01004bc:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004bf:	f7 d0                	not    %eax
f01004c1:	a8 06                	test   $0x6,%al
f01004c3:	75 1f                	jne    f01004e4 <kbd_proc_data+0xf8>
f01004c5:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004cb:	75 17                	jne    f01004e4 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01004cd:	c7 04 24 04 1a 10 f0 	movl   $0xf0101a04,(%esp)
f01004d4:	e8 3d 04 00 00       	call   f0100916 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d9:	ba 92 00 00 00       	mov    $0x92,%edx
f01004de:	b8 03 00 00 00       	mov    $0x3,%eax
f01004e3:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004e4:	89 d8                	mov    %ebx,%eax
f01004e6:	83 c4 14             	add    $0x14,%esp
f01004e9:	5b                   	pop    %ebx
f01004ea:	5d                   	pop    %ebp
f01004eb:	c3                   	ret    

f01004ec <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004ec:	55                   	push   %ebp
f01004ed:	89 e5                	mov    %esp,%ebp
f01004ef:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004f2:	83 3d 20 23 11 f0 00 	cmpl   $0x0,0xf0112320
f01004f9:	74 0a                	je     f0100505 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004fb:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100500:	e8 c5 fc ff ff       	call   f01001ca <cons_intr>
}
f0100505:	c9                   	leave  
f0100506:	c3                   	ret    

f0100507 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100507:	55                   	push   %ebp
f0100508:	89 e5                	mov    %esp,%ebp
f010050a:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010050d:	b8 ec 03 10 f0       	mov    $0xf01003ec,%eax
f0100512:	e8 b3 fc ff ff       	call   f01001ca <cons_intr>
}
f0100517:	c9                   	leave  
f0100518:	c3                   	ret    

f0100519 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100519:	55                   	push   %ebp
f010051a:	89 e5                	mov    %esp,%ebp
f010051c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051f:	e8 c8 ff ff ff       	call   f01004ec <serial_intr>
	kbd_intr();
f0100524:	e8 de ff ff ff       	call   f0100507 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100529:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f010052f:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100534:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f010053a:	74 1e                	je     f010055a <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010053c:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f0100543:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100546:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100551:	0f 44 d1             	cmove  %ecx,%edx
f0100554:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
		return c;
	}
	return 0;
}
f010055a:	c9                   	leave  
f010055b:	c3                   	ret    

f010055c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055c:	55                   	push   %ebp
f010055d:	89 e5                	mov    %esp,%ebp
f010055f:	57                   	push   %edi
f0100560:	56                   	push   %esi
f0100561:	53                   	push   %ebx
f0100562:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100565:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100573:	5a a5 
	if (*cp != 0xA55A) {
f0100575:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100580:	74 11                	je     f0100593 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100582:	c7 05 4c 25 11 f0 b4 	movl   $0x3b4,0xf011254c
f0100589:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100591:	eb 16                	jmp    f01005a9 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100593:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059a:	c7 05 4c 25 11 f0 d4 	movl   $0x3d4,0xf011254c
f01005a1:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a4:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a9:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01005af:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b4:	89 ca                	mov    %ecx,%edx
f01005b6:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005b7:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ba:	89 da                	mov    %ebx,%edx
f01005bc:	ec                   	in     (%dx),%al
f01005bd:	0f b6 f8             	movzbl %al,%edi
f01005c0:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c8:	89 ca                	mov    %ecx,%edx
f01005ca:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cb:	89 da                	mov    %ebx,%edx
f01005cd:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ce:	89 35 50 25 11 f0    	mov    %esi,0xf0112550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d4:	0f b6 d8             	movzbl %al,%ebx
f01005d7:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005d9:	66 89 3d 54 25 11 f0 	mov    %di,0xf0112554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e0:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	b2 fb                	mov    $0xfb,%dl
f01005ef:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f4:	ee                   	out    %al,(%dx)
f01005f5:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005fa:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ff:	89 ca                	mov    %ecx,%edx
f0100601:	ee                   	out    %al,(%dx)
f0100602:	b2 f9                	mov    $0xf9,%dl
f0100604:	b8 00 00 00 00       	mov    $0x0,%eax
f0100609:	ee                   	out    %al,(%dx)
f010060a:	b2 fb                	mov    $0xfb,%dl
f010060c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100611:	ee                   	out    %al,(%dx)
f0100612:	b2 fc                	mov    $0xfc,%dl
f0100614:	b8 00 00 00 00       	mov    $0x0,%eax
f0100619:	ee                   	out    %al,(%dx)
f010061a:	b2 f9                	mov    $0xf9,%dl
f010061c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100621:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100622:	b2 fd                	mov    $0xfd,%dl
f0100624:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100625:	3c ff                	cmp    $0xff,%al
f0100627:	0f 95 c0             	setne  %al
f010062a:	0f b6 c0             	movzbl %al,%eax
f010062d:	89 c6                	mov    %eax,%esi
f010062f:	a3 20 23 11 f0       	mov    %eax,0xf0112320
f0100634:	89 da                	mov    %ebx,%edx
f0100636:	ec                   	in     (%dx),%al
f0100637:	89 ca                	mov    %ecx,%edx
f0100639:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063a:	85 f6                	test   %esi,%esi
f010063c:	75 0c                	jne    f010064a <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f010063e:	c7 04 24 10 1a 10 f0 	movl   $0xf0101a10,(%esp)
f0100645:	e8 cc 02 00 00       	call   f0100916 <cprintf>
}
f010064a:	83 c4 1c             	add    $0x1c,%esp
f010064d:	5b                   	pop    %ebx
f010064e:	5e                   	pop    %esi
f010064f:	5f                   	pop    %edi
f0100650:	5d                   	pop    %ebp
f0100651:	c3                   	ret    

f0100652 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100652:	55                   	push   %ebp
f0100653:	89 e5                	mov    %esp,%ebp
f0100655:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100658:	8b 45 08             	mov    0x8(%ebp),%eax
f010065b:	e8 a7 fb ff ff       	call   f0100207 <cons_putc>
}
f0100660:	c9                   	leave  
f0100661:	c3                   	ret    

f0100662 <getchar>:

int
getchar(void)
{
f0100662:	55                   	push   %ebp
f0100663:	89 e5                	mov    %esp,%ebp
f0100665:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100668:	e8 ac fe ff ff       	call   f0100519 <cons_getc>
f010066d:	85 c0                	test   %eax,%eax
f010066f:	74 f7                	je     f0100668 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100671:	c9                   	leave  
f0100672:	c3                   	ret    

f0100673 <iscons>:

int
iscons(int fdnum)
{
f0100673:	55                   	push   %ebp
f0100674:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100676:	b8 01 00 00 00       	mov    $0x1,%eax
f010067b:	5d                   	pop    %ebp
f010067c:	c3                   	ret    
f010067d:	00 00                	add    %al,(%eax)
	...

f0100680 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100686:	c7 04 24 50 1c 10 f0 	movl   $0xf0101c50,(%esp)
f010068d:	e8 84 02 00 00       	call   f0100916 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100692:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100699:	00 
f010069a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006a1:	f0 
f01006a2:	c7 04 24 dc 1c 10 f0 	movl   $0xf0101cdc,(%esp)
f01006a9:	e8 68 02 00 00       	call   f0100916 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ae:	c7 44 24 08 75 19 10 	movl   $0x101975,0x8(%esp)
f01006b5:	00 
f01006b6:	c7 44 24 04 75 19 10 	movl   $0xf0101975,0x4(%esp)
f01006bd:	f0 
f01006be:	c7 04 24 00 1d 10 f0 	movl   $0xf0101d00,(%esp)
f01006c5:	e8 4c 02 00 00       	call   f0100916 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006d1:	00 
f01006d2:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006d9:	f0 
f01006da:	c7 04 24 24 1d 10 f0 	movl   $0xf0101d24,(%esp)
f01006e1:	e8 30 02 00 00       	call   f0100916 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e6:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f01006ed:	00 
f01006ee:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f01006f5:	f0 
f01006f6:	c7 04 24 48 1d 10 f0 	movl   $0xf0101d48,(%esp)
f01006fd:	e8 14 02 00 00       	call   f0100916 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100702:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100707:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010070c:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100712:	85 c0                	test   %eax,%eax
f0100714:	0f 48 c2             	cmovs  %edx,%eax
f0100717:	c1 f8 0a             	sar    $0xa,%eax
f010071a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071e:	c7 04 24 6c 1d 10 f0 	movl   $0xf0101d6c,(%esp)
f0100725:	e8 ec 01 00 00       	call   f0100916 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010072a:	b8 00 00 00 00       	mov    $0x0,%eax
f010072f:	c9                   	leave  
f0100730:	c3                   	ret    

f0100731 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100731:	55                   	push   %ebp
f0100732:	89 e5                	mov    %esp,%ebp
f0100734:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100737:	c7 44 24 08 69 1c 10 	movl   $0xf0101c69,0x8(%esp)
f010073e:	f0 
f010073f:	c7 44 24 04 87 1c 10 	movl   $0xf0101c87,0x4(%esp)
f0100746:	f0 
f0100747:	c7 04 24 8c 1c 10 f0 	movl   $0xf0101c8c,(%esp)
f010074e:	e8 c3 01 00 00       	call   f0100916 <cprintf>
f0100753:	c7 44 24 08 98 1d 10 	movl   $0xf0101d98,0x8(%esp)
f010075a:	f0 
f010075b:	c7 44 24 04 95 1c 10 	movl   $0xf0101c95,0x4(%esp)
f0100762:	f0 
f0100763:	c7 04 24 8c 1c 10 f0 	movl   $0xf0101c8c,(%esp)
f010076a:	e8 a7 01 00 00       	call   f0100916 <cprintf>
	return 0;
}
f010076f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100774:	c9                   	leave  
f0100775:	c3                   	ret    

f0100776 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100776:	55                   	push   %ebp
f0100777:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100779:	b8 00 00 00 00       	mov    $0x0,%eax
f010077e:	5d                   	pop    %ebp
f010077f:	c3                   	ret    

f0100780 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100780:	55                   	push   %ebp
f0100781:	89 e5                	mov    %esp,%ebp
f0100783:	57                   	push   %edi
f0100784:	56                   	push   %esi
f0100785:	53                   	push   %ebx
f0100786:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100789:	c7 04 24 c0 1d 10 f0 	movl   $0xf0101dc0,(%esp)
f0100790:	e8 81 01 00 00       	call   f0100916 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100795:	c7 04 24 e4 1d 10 f0 	movl   $0xf0101de4,(%esp)
f010079c:	e8 75 01 00 00       	call   f0100916 <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f01007a1:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01007a4:	c7 04 24 9e 1c 10 f0 	movl   $0xf0101c9e,(%esp)
f01007ab:	e8 40 0a 00 00       	call   f01011f0 <readline>
f01007b0:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007b2:	85 c0                	test   %eax,%eax
f01007b4:	74 ee                	je     f01007a4 <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007b6:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007bd:	be 00 00 00 00       	mov    $0x0,%esi
f01007c2:	eb 06                	jmp    f01007ca <monitor+0x4a>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007c4:	c6 03 00             	movb   $0x0,(%ebx)
f01007c7:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007ca:	0f b6 03             	movzbl (%ebx),%eax
f01007cd:	84 c0                	test   %al,%al
f01007cf:	74 6a                	je     f010083b <monitor+0xbb>
f01007d1:	0f be c0             	movsbl %al,%eax
f01007d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d8:	c7 04 24 a2 1c 10 f0 	movl   $0xf0101ca2,(%esp)
f01007df:	e8 37 0c 00 00       	call   f010141b <strchr>
f01007e4:	85 c0                	test   %eax,%eax
f01007e6:	75 dc                	jne    f01007c4 <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f01007e8:	80 3b 00             	cmpb   $0x0,(%ebx)
f01007eb:	74 4e                	je     f010083b <monitor+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01007ed:	83 fe 0f             	cmp    $0xf,%esi
f01007f0:	75 16                	jne    f0100808 <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01007f2:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01007f9:	00 
f01007fa:	c7 04 24 a7 1c 10 f0 	movl   $0xf0101ca7,(%esp)
f0100801:	e8 10 01 00 00       	call   f0100916 <cprintf>
f0100806:	eb 9c                	jmp    f01007a4 <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f0100808:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010080c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010080f:	0f b6 03             	movzbl (%ebx),%eax
f0100812:	84 c0                	test   %al,%al
f0100814:	75 0c                	jne    f0100822 <monitor+0xa2>
f0100816:	eb b2                	jmp    f01007ca <monitor+0x4a>
			buf++;
f0100818:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010081b:	0f b6 03             	movzbl (%ebx),%eax
f010081e:	84 c0                	test   %al,%al
f0100820:	74 a8                	je     f01007ca <monitor+0x4a>
f0100822:	0f be c0             	movsbl %al,%eax
f0100825:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100829:	c7 04 24 a2 1c 10 f0 	movl   $0xf0101ca2,(%esp)
f0100830:	e8 e6 0b 00 00       	call   f010141b <strchr>
f0100835:	85 c0                	test   %eax,%eax
f0100837:	74 df                	je     f0100818 <monitor+0x98>
f0100839:	eb 8f                	jmp    f01007ca <monitor+0x4a>
			buf++;
	}
	argv[argc] = 0;
f010083b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100842:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100843:	85 f6                	test   %esi,%esi
f0100845:	0f 84 59 ff ff ff    	je     f01007a4 <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010084b:	c7 44 24 04 87 1c 10 	movl   $0xf0101c87,0x4(%esp)
f0100852:	f0 
f0100853:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100856:	89 04 24             	mov    %eax,(%esp)
f0100859:	e8 42 0b 00 00       	call   f01013a0 <strcmp>
f010085e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100863:	85 c0                	test   %eax,%eax
f0100865:	74 1c                	je     f0100883 <monitor+0x103>
f0100867:	c7 44 24 04 95 1c 10 	movl   $0xf0101c95,0x4(%esp)
f010086e:	f0 
f010086f:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100872:	89 04 24             	mov    %eax,(%esp)
f0100875:	e8 26 0b 00 00       	call   f01013a0 <strcmp>
f010087a:	85 c0                	test   %eax,%eax
f010087c:	75 28                	jne    f01008a6 <monitor+0x126>
f010087e:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f0100883:	8d 04 12             	lea    (%edx,%edx,1),%eax
f0100886:	01 c2                	add    %eax,%edx
f0100888:	8b 45 08             	mov    0x8(%ebp),%eax
f010088b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010088f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100893:	89 34 24             	mov    %esi,(%esp)
f0100896:	ff 14 95 14 1e 10 f0 	call   *-0xfefe1ec(,%edx,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010089d:	85 c0                	test   %eax,%eax
f010089f:	78 1d                	js     f01008be <monitor+0x13e>
f01008a1:	e9 fe fe ff ff       	jmp    f01007a4 <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008a6:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ad:	c7 04 24 c4 1c 10 f0 	movl   $0xf0101cc4,(%esp)
f01008b4:	e8 5d 00 00 00       	call   f0100916 <cprintf>
f01008b9:	e9 e6 fe ff ff       	jmp    f01007a4 <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008be:	83 c4 5c             	add    $0x5c,%esp
f01008c1:	5b                   	pop    %ebx
f01008c2:	5e                   	pop    %esi
f01008c3:	5f                   	pop    %edi
f01008c4:	5d                   	pop    %ebp
f01008c5:	c3                   	ret    

f01008c6 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01008c6:	55                   	push   %ebp
f01008c7:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01008c9:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01008cc:	5d                   	pop    %ebp
f01008cd:	c3                   	ret    
	...

f01008d0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008d0:	55                   	push   %ebp
f01008d1:	89 e5                	mov    %esp,%ebp
f01008d3:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01008d9:	89 04 24             	mov    %eax,(%esp)
f01008dc:	e8 71 fd ff ff       	call   f0100652 <cputchar>
	*cnt++;
}
f01008e1:	c9                   	leave  
f01008e2:	c3                   	ret    

f01008e3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008e3:	55                   	push   %ebp
f01008e4:	89 e5                	mov    %esp,%ebp
f01008e6:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008e9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008f0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01008f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01008fa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008fe:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100901:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100905:	c7 04 24 d0 08 10 f0 	movl   $0xf01008d0,(%esp)
f010090c:	e8 69 04 00 00       	call   f0100d7a <vprintfmt>
	return cnt;
}
f0100911:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100914:	c9                   	leave  
f0100915:	c3                   	ret    

f0100916 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100916:	55                   	push   %ebp
f0100917:	89 e5                	mov    %esp,%ebp
f0100919:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010091c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010091f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100923:	8b 45 08             	mov    0x8(%ebp),%eax
f0100926:	89 04 24             	mov    %eax,(%esp)
f0100929:	e8 b5 ff ff ff       	call   f01008e3 <vcprintf>
	va_end(ap);

	return cnt;
}
f010092e:	c9                   	leave  
f010092f:	c3                   	ret    

f0100930 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100930:	55                   	push   %ebp
f0100931:	89 e5                	mov    %esp,%ebp
f0100933:	57                   	push   %edi
f0100934:	56                   	push   %esi
f0100935:	53                   	push   %ebx
f0100936:	83 ec 10             	sub    $0x10,%esp
f0100939:	89 c3                	mov    %eax,%ebx
f010093b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f010093e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100941:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100944:	8b 0a                	mov    (%edx),%ecx
f0100946:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100949:	8b 00                	mov    (%eax),%eax
f010094b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010094e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0100955:	eb 77                	jmp    f01009ce <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100957:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010095a:	01 c8                	add    %ecx,%eax
f010095c:	bf 02 00 00 00       	mov    $0x2,%edi
f0100961:	99                   	cltd   
f0100962:	f7 ff                	idiv   %edi
f0100964:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100966:	eb 01                	jmp    f0100969 <stab_binsearch+0x39>
			m--;
f0100968:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100969:	39 ca                	cmp    %ecx,%edx
f010096b:	7c 1d                	jl     f010098a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010096d:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100970:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100975:	39 f7                	cmp    %esi,%edi
f0100977:	75 ef                	jne    f0100968 <stab_binsearch+0x38>
f0100979:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010097c:	6b fa 0c             	imul   $0xc,%edx,%edi
f010097f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100983:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100986:	73 18                	jae    f01009a0 <stab_binsearch+0x70>
f0100988:	eb 05                	jmp    f010098f <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010098a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f010098d:	eb 3f                	jmp    f01009ce <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f010098f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100992:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100994:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100997:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f010099e:	eb 2e                	jmp    f01009ce <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009a0:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f01009a3:	76 15                	jbe    f01009ba <stab_binsearch+0x8a>
			*region_right = m - 1;
f01009a5:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01009a8:	4f                   	dec    %edi
f01009a9:	89 7d f0             	mov    %edi,-0x10(%ebp)
f01009ac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009af:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009b1:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009b8:	eb 14                	jmp    f01009ce <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009ba:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01009bd:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01009c0:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f01009c2:	ff 45 0c             	incl   0xc(%ebp)
f01009c5:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009c7:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f01009ce:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f01009d1:	7e 84                	jle    f0100957 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009d3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01009d7:	75 0d                	jne    f01009e6 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f01009d9:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009dc:	8b 02                	mov    (%edx),%eax
f01009de:	48                   	dec    %eax
f01009df:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009e2:	89 01                	mov    %eax,(%ecx)
f01009e4:	eb 22                	jmp    f0100a08 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009e6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009e9:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009eb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009ee:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009f0:	eb 01                	jmp    f01009f3 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009f2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009f3:	39 c1                	cmp    %eax,%ecx
f01009f5:	7d 0c                	jge    f0100a03 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01009f7:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f01009fa:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f01009ff:	39 f2                	cmp    %esi,%edx
f0100a01:	75 ef                	jne    f01009f2 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a03:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a06:	89 02                	mov    %eax,(%edx)
	}
}
f0100a08:	83 c4 10             	add    $0x10,%esp
f0100a0b:	5b                   	pop    %ebx
f0100a0c:	5e                   	pop    %esi
f0100a0d:	5f                   	pop    %edi
f0100a0e:	5d                   	pop    %ebp
f0100a0f:	c3                   	ret    

f0100a10 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a10:	55                   	push   %ebp
f0100a11:	89 e5                	mov    %esp,%ebp
f0100a13:	83 ec 38             	sub    $0x38,%esp
f0100a16:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100a19:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100a1c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100a1f:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a22:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a25:	c7 03 24 1e 10 f0    	movl   $0xf0101e24,(%ebx)
	info->eip_line = 0;
f0100a2b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a32:	c7 43 08 24 1e 10 f0 	movl   $0xf0101e24,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a39:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a40:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a43:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a4a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a50:	76 12                	jbe    f0100a64 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a52:	b8 ce 74 10 f0       	mov    $0xf01074ce,%eax
f0100a57:	3d 31 5b 10 f0       	cmp    $0xf0105b31,%eax
f0100a5c:	0f 86 9b 01 00 00    	jbe    f0100bfd <debuginfo_eip+0x1ed>
f0100a62:	eb 1c                	jmp    f0100a80 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a64:	c7 44 24 08 2e 1e 10 	movl   $0xf0101e2e,0x8(%esp)
f0100a6b:	f0 
f0100a6c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a73:	00 
f0100a74:	c7 04 24 3b 1e 10 f0 	movl   $0xf0101e3b,(%esp)
f0100a7b:	e8 78 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100a80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a85:	80 3d cd 74 10 f0 00 	cmpb   $0x0,0xf01074cd
f0100a8c:	0f 85 77 01 00 00    	jne    f0100c09 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a92:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a99:	b8 30 5b 10 f0       	mov    $0xf0105b30,%eax
f0100a9e:	2d 5c 20 10 f0       	sub    $0xf010205c,%eax
f0100aa3:	c1 f8 02             	sar    $0x2,%eax
f0100aa6:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100aac:	83 e8 01             	sub    $0x1,%eax
f0100aaf:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ab2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ab6:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100abd:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ac0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ac3:	b8 5c 20 10 f0       	mov    $0xf010205c,%eax
f0100ac8:	e8 63 fe ff ff       	call   f0100930 <stab_binsearch>
	if (lfile == 0)
f0100acd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100ad0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100ad5:	85 d2                	test   %edx,%edx
f0100ad7:	0f 84 2c 01 00 00    	je     f0100c09 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100add:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100ae0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ae3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ae6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100aea:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100af1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100af4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100af7:	b8 5c 20 10 f0       	mov    $0xf010205c,%eax
f0100afc:	e8 2f fe ff ff       	call   f0100930 <stab_binsearch>

	if (lfun <= rfun) {
f0100b01:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100b04:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b07:	7f 2e                	jg     f0100b37 <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b09:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b0c:	8d 90 5c 20 10 f0    	lea    -0xfefdfa4(%eax),%edx
f0100b12:	8b 80 5c 20 10 f0    	mov    -0xfefdfa4(%eax),%eax
f0100b18:	b9 ce 74 10 f0       	mov    $0xf01074ce,%ecx
f0100b1d:	81 e9 31 5b 10 f0    	sub    $0xf0105b31,%ecx
f0100b23:	39 c8                	cmp    %ecx,%eax
f0100b25:	73 08                	jae    f0100b2f <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b27:	05 31 5b 10 f0       	add    $0xf0105b31,%eax
f0100b2c:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b2f:	8b 42 08             	mov    0x8(%edx),%eax
f0100b32:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b35:	eb 06                	jmp    f0100b3d <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b37:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b3a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b3d:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b44:	00 
f0100b45:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b48:	89 04 24             	mov    %eax,(%esp)
f0100b4b:	e8 ff 08 00 00       	call   f010144f <strfind>
f0100b50:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b53:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b56:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100b59:	39 d7                	cmp    %edx,%edi
f0100b5b:	7c 5f                	jl     f0100bbc <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0100b5d:	89 f8                	mov    %edi,%eax
f0100b5f:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0100b62:	80 b9 60 20 10 f0 84 	cmpb   $0x84,-0xfefdfa0(%ecx)
f0100b69:	75 18                	jne    f0100b83 <debuginfo_eip+0x173>
f0100b6b:	eb 30                	jmp    f0100b9d <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b6d:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b70:	39 fa                	cmp    %edi,%edx
f0100b72:	7f 48                	jg     f0100bbc <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0100b74:	89 f8                	mov    %edi,%eax
f0100b76:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0100b79:	80 3c 8d 60 20 10 f0 	cmpb   $0x84,-0xfefdfa0(,%ecx,4)
f0100b80:	84 
f0100b81:	74 1a                	je     f0100b9d <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b83:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100b86:	8d 04 85 5c 20 10 f0 	lea    -0xfefdfa4(,%eax,4),%eax
f0100b8d:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0100b91:	75 da                	jne    f0100b6d <debuginfo_eip+0x15d>
f0100b93:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b97:	74 d4                	je     f0100b6d <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b99:	39 fa                	cmp    %edi,%edx
f0100b9b:	7f 1f                	jg     f0100bbc <debuginfo_eip+0x1ac>
f0100b9d:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100ba0:	8b 87 5c 20 10 f0    	mov    -0xfefdfa4(%edi),%eax
f0100ba6:	ba ce 74 10 f0       	mov    $0xf01074ce,%edx
f0100bab:	81 ea 31 5b 10 f0    	sub    $0xf0105b31,%edx
f0100bb1:	39 d0                	cmp    %edx,%eax
f0100bb3:	73 07                	jae    f0100bbc <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100bb5:	05 31 5b 10 f0       	add    $0xf0105b31,%eax
f0100bba:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bbc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100bbf:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100bc2:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100bc7:	39 ca                	cmp    %ecx,%edx
f0100bc9:	7d 3e                	jge    f0100c09 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0100bcb:	83 c2 01             	add    $0x1,%edx
f0100bce:	39 d1                	cmp    %edx,%ecx
f0100bd0:	7e 37                	jle    f0100c09 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bd2:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100bd5:	80 be 60 20 10 f0 a0 	cmpb   $0xa0,-0xfefdfa0(%esi)
f0100bdc:	75 2b                	jne    f0100c09 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f0100bde:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100be2:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100be5:	39 d1                	cmp    %edx,%ecx
f0100be7:	7e 1b                	jle    f0100c04 <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100be9:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100bec:	80 3c 85 60 20 10 f0 	cmpb   $0xa0,-0xfefdfa0(,%eax,4)
f0100bf3:	a0 
f0100bf4:	74 e8                	je     f0100bde <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100bf6:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bfb:	eb 0c                	jmp    f0100c09 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bfd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c02:	eb 05                	jmp    f0100c09 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c04:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c09:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100c0c:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100c0f:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100c12:	89 ec                	mov    %ebp,%esp
f0100c14:	5d                   	pop    %ebp
f0100c15:	c3                   	ret    
	...

f0100c20 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c20:	55                   	push   %ebp
f0100c21:	89 e5                	mov    %esp,%ebp
f0100c23:	57                   	push   %edi
f0100c24:	56                   	push   %esi
f0100c25:	53                   	push   %ebx
f0100c26:	83 ec 3c             	sub    $0x3c,%esp
f0100c29:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100c2c:	89 d7                	mov    %edx,%edi
f0100c2e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c31:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100c34:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c37:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c3a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100c3d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c40:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c45:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100c48:	72 11                	jb     f0100c5b <printnum+0x3b>
f0100c4a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c4d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100c50:	76 09                	jbe    f0100c5b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c52:	83 eb 01             	sub    $0x1,%ebx
f0100c55:	85 db                	test   %ebx,%ebx
f0100c57:	7f 51                	jg     f0100caa <printnum+0x8a>
f0100c59:	eb 5e                	jmp    f0100cb9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c5b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100c5f:	83 eb 01             	sub    $0x1,%ebx
f0100c62:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100c66:	8b 45 10             	mov    0x10(%ebp),%eax
f0100c69:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c6d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100c71:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100c75:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100c7c:	00 
f0100c7d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c80:	89 04 24             	mov    %eax,(%esp)
f0100c83:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c86:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c8a:	e8 41 0a 00 00       	call   f01016d0 <__udivdi3>
f0100c8f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100c93:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c97:	89 04 24             	mov    %eax,(%esp)
f0100c9a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c9e:	89 fa                	mov    %edi,%edx
f0100ca0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ca3:	e8 78 ff ff ff       	call   f0100c20 <printnum>
f0100ca8:	eb 0f                	jmp    f0100cb9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100caa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cae:	89 34 24             	mov    %esi,(%esp)
f0100cb1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cb4:	83 eb 01             	sub    $0x1,%ebx
f0100cb7:	75 f1                	jne    f0100caa <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cb9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cbd:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100cc1:	8b 45 10             	mov    0x10(%ebp),%eax
f0100cc4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cc8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100ccf:	00 
f0100cd0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100cd3:	89 04 24             	mov    %eax,(%esp)
f0100cd6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cd9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cdd:	e8 1e 0b 00 00       	call   f0101800 <__umoddi3>
f0100ce2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ce6:	0f be 80 49 1e 10 f0 	movsbl -0xfefe1b7(%eax),%eax
f0100ced:	89 04 24             	mov    %eax,(%esp)
f0100cf0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100cf3:	83 c4 3c             	add    $0x3c,%esp
f0100cf6:	5b                   	pop    %ebx
f0100cf7:	5e                   	pop    %esi
f0100cf8:	5f                   	pop    %edi
f0100cf9:	5d                   	pop    %ebp
f0100cfa:	c3                   	ret    

f0100cfb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100cfb:	55                   	push   %ebp
f0100cfc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100cfe:	83 fa 01             	cmp    $0x1,%edx
f0100d01:	7e 0e                	jle    f0100d11 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100d03:	8b 10                	mov    (%eax),%edx
f0100d05:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100d08:	89 08                	mov    %ecx,(%eax)
f0100d0a:	8b 02                	mov    (%edx),%eax
f0100d0c:	8b 52 04             	mov    0x4(%edx),%edx
f0100d0f:	eb 22                	jmp    f0100d33 <getuint+0x38>
	else if (lflag)
f0100d11:	85 d2                	test   %edx,%edx
f0100d13:	74 10                	je     f0100d25 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d15:	8b 10                	mov    (%eax),%edx
f0100d17:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d1a:	89 08                	mov    %ecx,(%eax)
f0100d1c:	8b 02                	mov    (%edx),%eax
f0100d1e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d23:	eb 0e                	jmp    f0100d33 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d25:	8b 10                	mov    (%eax),%edx
f0100d27:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d2a:	89 08                	mov    %ecx,(%eax)
f0100d2c:	8b 02                	mov    (%edx),%eax
f0100d2e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d33:	5d                   	pop    %ebp
f0100d34:	c3                   	ret    

f0100d35 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d35:	55                   	push   %ebp
f0100d36:	89 e5                	mov    %esp,%ebp
f0100d38:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d3b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d3f:	8b 10                	mov    (%eax),%edx
f0100d41:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d44:	73 0a                	jae    f0100d50 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d46:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100d49:	88 0a                	mov    %cl,(%edx)
f0100d4b:	83 c2 01             	add    $0x1,%edx
f0100d4e:	89 10                	mov    %edx,(%eax)
}
f0100d50:	5d                   	pop    %ebp
f0100d51:	c3                   	ret    

f0100d52 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d52:	55                   	push   %ebp
f0100d53:	89 e5                	mov    %esp,%ebp
f0100d55:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d58:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d5b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d5f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d62:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d66:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d69:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d6d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d70:	89 04 24             	mov    %eax,(%esp)
f0100d73:	e8 02 00 00 00       	call   f0100d7a <vprintfmt>
	va_end(ap);
}
f0100d78:	c9                   	leave  
f0100d79:	c3                   	ret    

f0100d7a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d7a:	55                   	push   %ebp
f0100d7b:	89 e5                	mov    %esp,%ebp
f0100d7d:	57                   	push   %edi
f0100d7e:	56                   	push   %esi
f0100d7f:	53                   	push   %ebx
f0100d80:	83 ec 4c             	sub    $0x4c,%esp
f0100d83:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d86:	8b 75 10             	mov    0x10(%ebp),%esi
f0100d89:	eb 12                	jmp    f0100d9d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d8b:	85 c0                	test   %eax,%eax
f0100d8d:	0f 84 c9 03 00 00    	je     f010115c <vprintfmt+0x3e2>
				return;
			putch(ch, putdat);
f0100d93:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d97:	89 04 24             	mov    %eax,(%esp)
f0100d9a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d9d:	0f b6 06             	movzbl (%esi),%eax
f0100da0:	83 c6 01             	add    $0x1,%esi
f0100da3:	83 f8 25             	cmp    $0x25,%eax
f0100da6:	75 e3                	jne    f0100d8b <vprintfmt+0x11>
f0100da8:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100dac:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100db3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100db8:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100dbf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100dc4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100dc7:	eb 2b                	jmp    f0100df4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dc9:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100dcc:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100dd0:	eb 22                	jmp    f0100df4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dd2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100dd5:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100dd9:	eb 19                	jmp    f0100df4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ddb:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100dde:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100de5:	eb 0d                	jmp    f0100df4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100de7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ded:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100df4:	0f b6 06             	movzbl (%esi),%eax
f0100df7:	0f b6 d0             	movzbl %al,%edx
f0100dfa:	8d 7e 01             	lea    0x1(%esi),%edi
f0100dfd:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0100e00:	83 e8 23             	sub    $0x23,%eax
f0100e03:	3c 55                	cmp    $0x55,%al
f0100e05:	0f 87 2b 03 00 00    	ja     f0101136 <vprintfmt+0x3bc>
f0100e0b:	0f b6 c0             	movzbl %al,%eax
f0100e0e:	ff 24 85 d8 1e 10 f0 	jmp    *-0xfefe128(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e15:	83 ea 30             	sub    $0x30,%edx
f0100e18:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0100e1b:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100e1f:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e22:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0100e25:	83 fa 09             	cmp    $0x9,%edx
f0100e28:	77 4a                	ja     f0100e74 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e2a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e2d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100e30:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0100e33:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0100e37:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100e3a:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100e3d:	83 fa 09             	cmp    $0x9,%edx
f0100e40:	76 eb                	jbe    f0100e2d <vprintfmt+0xb3>
f0100e42:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e45:	eb 2d                	jmp    f0100e74 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e47:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e4a:	8d 50 04             	lea    0x4(%eax),%edx
f0100e4d:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e50:	8b 00                	mov    (%eax),%eax
f0100e52:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e55:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e58:	eb 1a                	jmp    f0100e74 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e5a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0100e5d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100e61:	79 91                	jns    f0100df4 <vprintfmt+0x7a>
f0100e63:	e9 73 ff ff ff       	jmp    f0100ddb <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e68:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e6b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100e72:	eb 80                	jmp    f0100df4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0100e74:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100e78:	0f 89 76 ff ff ff    	jns    f0100df4 <vprintfmt+0x7a>
f0100e7e:	e9 64 ff ff ff       	jmp    f0100de7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e83:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e86:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e89:	e9 66 ff ff ff       	jmp    f0100df4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e91:	8d 50 04             	lea    0x4(%eax),%edx
f0100e94:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e97:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e9b:	8b 00                	mov    (%eax),%eax
f0100e9d:	89 04 24             	mov    %eax,(%esp)
f0100ea0:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea3:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100ea6:	e9 f2 fe ff ff       	jmp    f0100d9d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100eab:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eae:	8d 50 04             	lea    0x4(%eax),%edx
f0100eb1:	89 55 14             	mov    %edx,0x14(%ebp)
f0100eb4:	8b 00                	mov    (%eax),%eax
f0100eb6:	89 c2                	mov    %eax,%edx
f0100eb8:	c1 fa 1f             	sar    $0x1f,%edx
f0100ebb:	31 d0                	xor    %edx,%eax
f0100ebd:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ebf:	83 f8 06             	cmp    $0x6,%eax
f0100ec2:	7f 0b                	jg     f0100ecf <vprintfmt+0x155>
f0100ec4:	8b 14 85 30 20 10 f0 	mov    -0xfefdfd0(,%eax,4),%edx
f0100ecb:	85 d2                	test   %edx,%edx
f0100ecd:	75 23                	jne    f0100ef2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f0100ecf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ed3:	c7 44 24 08 61 1e 10 	movl   $0xf0101e61,0x8(%esp)
f0100eda:	f0 
f0100edb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100edf:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100ee2:	89 3c 24             	mov    %edi,(%esp)
f0100ee5:	e8 68 fe ff ff       	call   f0100d52 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eea:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100eed:	e9 ab fe ff ff       	jmp    f0100d9d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0100ef2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ef6:	c7 44 24 08 6a 1e 10 	movl   $0xf0101e6a,0x8(%esp)
f0100efd:	f0 
f0100efe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f02:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f05:	89 3c 24             	mov    %edi,(%esp)
f0100f08:	e8 45 fe ff ff       	call   f0100d52 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f0d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100f10:	e9 88 fe ff ff       	jmp    f0100d9d <vprintfmt+0x23>
f0100f15:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f18:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f1b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100f1e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f21:	8d 50 04             	lea    0x4(%eax),%edx
f0100f24:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f27:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100f29:	85 f6                	test   %esi,%esi
f0100f2b:	ba 5a 1e 10 f0       	mov    $0xf0101e5a,%edx
f0100f30:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0100f33:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100f37:	7e 06                	jle    f0100f3f <vprintfmt+0x1c5>
f0100f39:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100f3d:	75 10                	jne    f0100f4f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f3f:	0f be 06             	movsbl (%esi),%eax
f0100f42:	83 c6 01             	add    $0x1,%esi
f0100f45:	85 c0                	test   %eax,%eax
f0100f47:	0f 85 86 00 00 00    	jne    f0100fd3 <vprintfmt+0x259>
f0100f4d:	eb 76                	jmp    f0100fc5 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f4f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100f53:	89 34 24             	mov    %esi,(%esp)
f0100f56:	e8 80 03 00 00       	call   f01012db <strnlen>
f0100f5b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100f5e:	29 c2                	sub    %eax,%edx
f0100f60:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100f63:	85 d2                	test   %edx,%edx
f0100f65:	7e d8                	jle    f0100f3f <vprintfmt+0x1c5>
					putch(padc, putdat);
f0100f67:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0100f6b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100f6e:	89 d6                	mov    %edx,%esi
f0100f70:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0100f73:	89 c7                	mov    %eax,%edi
f0100f75:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f79:	89 3c 24             	mov    %edi,(%esp)
f0100f7c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f7f:	83 ee 01             	sub    $0x1,%esi
f0100f82:	75 f1                	jne    f0100f75 <vprintfmt+0x1fb>
f0100f84:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100f87:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100f8a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0100f8d:	eb b0                	jmp    f0100f3f <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f8f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100f93:	74 18                	je     f0100fad <vprintfmt+0x233>
f0100f95:	8d 50 e0             	lea    -0x20(%eax),%edx
f0100f98:	83 fa 5e             	cmp    $0x5e,%edx
f0100f9b:	76 10                	jbe    f0100fad <vprintfmt+0x233>
					putch('?', putdat);
f0100f9d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fa1:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100fa8:	ff 55 08             	call   *0x8(%ebp)
f0100fab:	eb 0a                	jmp    f0100fb7 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f0100fad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fb1:	89 04 24             	mov    %eax,(%esp)
f0100fb4:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fb7:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0100fbb:	0f be 06             	movsbl (%esi),%eax
f0100fbe:	83 c6 01             	add    $0x1,%esi
f0100fc1:	85 c0                	test   %eax,%eax
f0100fc3:	75 0e                	jne    f0100fd3 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100fc8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100fcc:	7f 16                	jg     f0100fe4 <vprintfmt+0x26a>
f0100fce:	e9 ca fd ff ff       	jmp    f0100d9d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fd3:	85 ff                	test   %edi,%edi
f0100fd5:	78 b8                	js     f0100f8f <vprintfmt+0x215>
f0100fd7:	83 ef 01             	sub    $0x1,%edi
f0100fda:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0100fe0:	79 ad                	jns    f0100f8f <vprintfmt+0x215>
f0100fe2:	eb e1                	jmp    f0100fc5 <vprintfmt+0x24b>
f0100fe4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100fe7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100fea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fee:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100ff5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100ff7:	83 ee 01             	sub    $0x1,%esi
f0100ffa:	75 ee                	jne    f0100fea <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100fff:	e9 99 fd ff ff       	jmp    f0100d9d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101004:	83 f9 01             	cmp    $0x1,%ecx
f0101007:	7e 10                	jle    f0101019 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101009:	8b 45 14             	mov    0x14(%ebp),%eax
f010100c:	8d 50 08             	lea    0x8(%eax),%edx
f010100f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101012:	8b 30                	mov    (%eax),%esi
f0101014:	8b 78 04             	mov    0x4(%eax),%edi
f0101017:	eb 26                	jmp    f010103f <vprintfmt+0x2c5>
	else if (lflag)
f0101019:	85 c9                	test   %ecx,%ecx
f010101b:	74 12                	je     f010102f <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f010101d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101020:	8d 50 04             	lea    0x4(%eax),%edx
f0101023:	89 55 14             	mov    %edx,0x14(%ebp)
f0101026:	8b 30                	mov    (%eax),%esi
f0101028:	89 f7                	mov    %esi,%edi
f010102a:	c1 ff 1f             	sar    $0x1f,%edi
f010102d:	eb 10                	jmp    f010103f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f010102f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101032:	8d 50 04             	lea    0x4(%eax),%edx
f0101035:	89 55 14             	mov    %edx,0x14(%ebp)
f0101038:	8b 30                	mov    (%eax),%esi
f010103a:	89 f7                	mov    %esi,%edi
f010103c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010103f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101044:	85 ff                	test   %edi,%edi
f0101046:	0f 89 ac 00 00 00    	jns    f01010f8 <vprintfmt+0x37e>
				putch('-', putdat);
f010104c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101050:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101057:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010105a:	f7 de                	neg    %esi
f010105c:	83 d7 00             	adc    $0x0,%edi
f010105f:	f7 df                	neg    %edi
			}
			base = 10;
f0101061:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101066:	e9 8d 00 00 00       	jmp    f01010f8 <vprintfmt+0x37e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010106b:	89 ca                	mov    %ecx,%edx
f010106d:	8d 45 14             	lea    0x14(%ebp),%eax
f0101070:	e8 86 fc ff ff       	call   f0100cfb <getuint>
f0101075:	89 c6                	mov    %eax,%esi
f0101077:	89 d7                	mov    %edx,%edi
			base = 10;
f0101079:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010107e:	eb 78                	jmp    f01010f8 <vprintfmt+0x37e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101080:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101084:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010108b:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f010108e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101092:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101099:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f010109c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010a0:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010a7:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010aa:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01010ad:	e9 eb fc ff ff       	jmp    f0100d9d <vprintfmt+0x23>

		// pointer
		case 'p':
			putch('0', putdat);
f01010b2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010b6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01010bd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01010c0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01010cb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d1:	8d 50 04             	lea    0x4(%eax),%edx
f01010d4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010d7:	8b 30                	mov    (%eax),%esi
f01010d9:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01010de:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01010e3:	eb 13                	jmp    f01010f8 <vprintfmt+0x37e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01010e5:	89 ca                	mov    %ecx,%edx
f01010e7:	8d 45 14             	lea    0x14(%ebp),%eax
f01010ea:	e8 0c fc ff ff       	call   f0100cfb <getuint>
f01010ef:	89 c6                	mov    %eax,%esi
f01010f1:	89 d7                	mov    %edx,%edi
			base = 16;
f01010f3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01010f8:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01010fc:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101100:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101103:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101107:	89 44 24 08          	mov    %eax,0x8(%esp)
f010110b:	89 34 24             	mov    %esi,(%esp)
f010110e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101112:	89 da                	mov    %ebx,%edx
f0101114:	8b 45 08             	mov    0x8(%ebp),%eax
f0101117:	e8 04 fb ff ff       	call   f0100c20 <printnum>
			break;
f010111c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010111f:	e9 79 fc ff ff       	jmp    f0100d9d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101124:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101128:	89 14 24             	mov    %edx,(%esp)
f010112b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010112e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101131:	e9 67 fc ff ff       	jmp    f0100d9d <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101136:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010113a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101141:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101144:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101148:	0f 84 4f fc ff ff    	je     f0100d9d <vprintfmt+0x23>
f010114e:	83 ee 01             	sub    $0x1,%esi
f0101151:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101155:	75 f7                	jne    f010114e <vprintfmt+0x3d4>
f0101157:	e9 41 fc ff ff       	jmp    f0100d9d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010115c:	83 c4 4c             	add    $0x4c,%esp
f010115f:	5b                   	pop    %ebx
f0101160:	5e                   	pop    %esi
f0101161:	5f                   	pop    %edi
f0101162:	5d                   	pop    %ebp
f0101163:	c3                   	ret    

f0101164 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101164:	55                   	push   %ebp
f0101165:	89 e5                	mov    %esp,%ebp
f0101167:	83 ec 28             	sub    $0x28,%esp
f010116a:	8b 45 08             	mov    0x8(%ebp),%eax
f010116d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101170:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101173:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101177:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010117a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101181:	85 c0                	test   %eax,%eax
f0101183:	74 30                	je     f01011b5 <vsnprintf+0x51>
f0101185:	85 d2                	test   %edx,%edx
f0101187:	7e 2c                	jle    f01011b5 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101189:	8b 45 14             	mov    0x14(%ebp),%eax
f010118c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101190:	8b 45 10             	mov    0x10(%ebp),%eax
f0101193:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101197:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010119a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010119e:	c7 04 24 35 0d 10 f0 	movl   $0xf0100d35,(%esp)
f01011a5:	e8 d0 fb ff ff       	call   f0100d7a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011ad:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011b3:	eb 05                	jmp    f01011ba <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011b5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011ba:	c9                   	leave  
f01011bb:	c3                   	ret    

f01011bc <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011bc:	55                   	push   %ebp
f01011bd:	89 e5                	mov    %esp,%ebp
f01011bf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011c2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011c9:	8b 45 10             	mov    0x10(%ebp),%eax
f01011cc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011d0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011d7:	8b 45 08             	mov    0x8(%ebp),%eax
f01011da:	89 04 24             	mov    %eax,(%esp)
f01011dd:	e8 82 ff ff ff       	call   f0101164 <vsnprintf>
	va_end(ap);

	return rc;
}
f01011e2:	c9                   	leave  
f01011e3:	c3                   	ret    
	...

f01011f0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01011f0:	55                   	push   %ebp
f01011f1:	89 e5                	mov    %esp,%ebp
f01011f3:	57                   	push   %edi
f01011f4:	56                   	push   %esi
f01011f5:	53                   	push   %ebx
f01011f6:	83 ec 1c             	sub    $0x1c,%esp
f01011f9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01011fc:	85 c0                	test   %eax,%eax
f01011fe:	74 10                	je     f0101210 <readline+0x20>
		cprintf("%s", prompt);
f0101200:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101204:	c7 04 24 6a 1e 10 f0 	movl   $0xf0101e6a,(%esp)
f010120b:	e8 06 f7 ff ff       	call   f0100916 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101210:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101217:	e8 57 f4 ff ff       	call   f0100673 <iscons>
f010121c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010121e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101223:	e8 3a f4 ff ff       	call   f0100662 <getchar>
f0101228:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010122a:	85 c0                	test   %eax,%eax
f010122c:	79 17                	jns    f0101245 <readline+0x55>
			cprintf("read error: %e\n", c);
f010122e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101232:	c7 04 24 4c 20 10 f0 	movl   $0xf010204c,(%esp)
f0101239:	e8 d8 f6 ff ff       	call   f0100916 <cprintf>
			return NULL;
f010123e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101243:	eb 6d                	jmp    f01012b2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101245:	83 f8 08             	cmp    $0x8,%eax
f0101248:	74 05                	je     f010124f <readline+0x5f>
f010124a:	83 f8 7f             	cmp    $0x7f,%eax
f010124d:	75 19                	jne    f0101268 <readline+0x78>
f010124f:	85 f6                	test   %esi,%esi
f0101251:	7e 15                	jle    f0101268 <readline+0x78>
			if (echoing)
f0101253:	85 ff                	test   %edi,%edi
f0101255:	74 0c                	je     f0101263 <readline+0x73>
				cputchar('\b');
f0101257:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010125e:	e8 ef f3 ff ff       	call   f0100652 <cputchar>
			i--;
f0101263:	83 ee 01             	sub    $0x1,%esi
f0101266:	eb bb                	jmp    f0101223 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101268:	83 fb 1f             	cmp    $0x1f,%ebx
f010126b:	7e 1f                	jle    f010128c <readline+0x9c>
f010126d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101273:	7f 17                	jg     f010128c <readline+0x9c>
			if (echoing)
f0101275:	85 ff                	test   %edi,%edi
f0101277:	74 08                	je     f0101281 <readline+0x91>
				cputchar(c);
f0101279:	89 1c 24             	mov    %ebx,(%esp)
f010127c:	e8 d1 f3 ff ff       	call   f0100652 <cputchar>
			buf[i++] = c;
f0101281:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101287:	83 c6 01             	add    $0x1,%esi
f010128a:	eb 97                	jmp    f0101223 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010128c:	83 fb 0a             	cmp    $0xa,%ebx
f010128f:	74 05                	je     f0101296 <readline+0xa6>
f0101291:	83 fb 0d             	cmp    $0xd,%ebx
f0101294:	75 8d                	jne    f0101223 <readline+0x33>
			if (echoing)
f0101296:	85 ff                	test   %edi,%edi
f0101298:	74 0c                	je     f01012a6 <readline+0xb6>
				cputchar('\n');
f010129a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01012a1:	e8 ac f3 ff ff       	call   f0100652 <cputchar>
			buf[i] = 0;
f01012a6:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f01012ad:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f01012b2:	83 c4 1c             	add    $0x1c,%esp
f01012b5:	5b                   	pop    %ebx
f01012b6:	5e                   	pop    %esi
f01012b7:	5f                   	pop    %edi
f01012b8:	5d                   	pop    %ebp
f01012b9:	c3                   	ret    
f01012ba:	00 00                	add    %al,(%eax)
f01012bc:	00 00                	add    %al,(%eax)
	...

f01012c0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012c0:	55                   	push   %ebp
f01012c1:	89 e5                	mov    %esp,%ebp
f01012c3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01012cb:	80 3a 00             	cmpb   $0x0,(%edx)
f01012ce:	74 09                	je     f01012d9 <strlen+0x19>
		n++;
f01012d0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012d3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012d7:	75 f7                	jne    f01012d0 <strlen+0x10>
		n++;
	return n;
}
f01012d9:	5d                   	pop    %ebp
f01012da:	c3                   	ret    

f01012db <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012db:	55                   	push   %ebp
f01012dc:	89 e5                	mov    %esp,%ebp
f01012de:	53                   	push   %ebx
f01012df:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01012e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01012ea:	85 c9                	test   %ecx,%ecx
f01012ec:	74 1a                	je     f0101308 <strnlen+0x2d>
f01012ee:	80 3b 00             	cmpb   $0x0,(%ebx)
f01012f1:	74 15                	je     f0101308 <strnlen+0x2d>
f01012f3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01012f8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012fa:	39 ca                	cmp    %ecx,%edx
f01012fc:	74 0a                	je     f0101308 <strnlen+0x2d>
f01012fe:	83 c2 01             	add    $0x1,%edx
f0101301:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101306:	75 f0                	jne    f01012f8 <strnlen+0x1d>
		n++;
	return n;
}
f0101308:	5b                   	pop    %ebx
f0101309:	5d                   	pop    %ebp
f010130a:	c3                   	ret    

f010130b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010130b:	55                   	push   %ebp
f010130c:	89 e5                	mov    %esp,%ebp
f010130e:	53                   	push   %ebx
f010130f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101312:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101315:	ba 00 00 00 00       	mov    $0x0,%edx
f010131a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010131e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101321:	83 c2 01             	add    $0x1,%edx
f0101324:	84 c9                	test   %cl,%cl
f0101326:	75 f2                	jne    f010131a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101328:	5b                   	pop    %ebx
f0101329:	5d                   	pop    %ebp
f010132a:	c3                   	ret    

f010132b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010132b:	55                   	push   %ebp
f010132c:	89 e5                	mov    %esp,%ebp
f010132e:	56                   	push   %esi
f010132f:	53                   	push   %ebx
f0101330:	8b 45 08             	mov    0x8(%ebp),%eax
f0101333:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101336:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101339:	85 f6                	test   %esi,%esi
f010133b:	74 18                	je     f0101355 <strncpy+0x2a>
f010133d:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0101342:	0f b6 1a             	movzbl (%edx),%ebx
f0101345:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101348:	80 3a 01             	cmpb   $0x1,(%edx)
f010134b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010134e:	83 c1 01             	add    $0x1,%ecx
f0101351:	39 f1                	cmp    %esi,%ecx
f0101353:	75 ed                	jne    f0101342 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101355:	5b                   	pop    %ebx
f0101356:	5e                   	pop    %esi
f0101357:	5d                   	pop    %ebp
f0101358:	c3                   	ret    

f0101359 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101359:	55                   	push   %ebp
f010135a:	89 e5                	mov    %esp,%ebp
f010135c:	57                   	push   %edi
f010135d:	56                   	push   %esi
f010135e:	53                   	push   %ebx
f010135f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101362:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101365:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101368:	89 f8                	mov    %edi,%eax
f010136a:	85 f6                	test   %esi,%esi
f010136c:	74 2b                	je     f0101399 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010136e:	83 fe 01             	cmp    $0x1,%esi
f0101371:	74 23                	je     f0101396 <strlcpy+0x3d>
f0101373:	0f b6 0b             	movzbl (%ebx),%ecx
f0101376:	84 c9                	test   %cl,%cl
f0101378:	74 1c                	je     f0101396 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010137a:	83 ee 02             	sub    $0x2,%esi
f010137d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101382:	88 08                	mov    %cl,(%eax)
f0101384:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101387:	39 f2                	cmp    %esi,%edx
f0101389:	74 0b                	je     f0101396 <strlcpy+0x3d>
f010138b:	83 c2 01             	add    $0x1,%edx
f010138e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101392:	84 c9                	test   %cl,%cl
f0101394:	75 ec                	jne    f0101382 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0101396:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101399:	29 f8                	sub    %edi,%eax
}
f010139b:	5b                   	pop    %ebx
f010139c:	5e                   	pop    %esi
f010139d:	5f                   	pop    %edi
f010139e:	5d                   	pop    %ebp
f010139f:	c3                   	ret    

f01013a0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013a0:	55                   	push   %ebp
f01013a1:	89 e5                	mov    %esp,%ebp
f01013a3:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013a6:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013a9:	0f b6 01             	movzbl (%ecx),%eax
f01013ac:	84 c0                	test   %al,%al
f01013ae:	74 16                	je     f01013c6 <strcmp+0x26>
f01013b0:	3a 02                	cmp    (%edx),%al
f01013b2:	75 12                	jne    f01013c6 <strcmp+0x26>
		p++, q++;
f01013b4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013b7:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01013bb:	84 c0                	test   %al,%al
f01013bd:	74 07                	je     f01013c6 <strcmp+0x26>
f01013bf:	83 c1 01             	add    $0x1,%ecx
f01013c2:	3a 02                	cmp    (%edx),%al
f01013c4:	74 ee                	je     f01013b4 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013c6:	0f b6 c0             	movzbl %al,%eax
f01013c9:	0f b6 12             	movzbl (%edx),%edx
f01013cc:	29 d0                	sub    %edx,%eax
}
f01013ce:	5d                   	pop    %ebp
f01013cf:	c3                   	ret    

f01013d0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013d0:	55                   	push   %ebp
f01013d1:	89 e5                	mov    %esp,%ebp
f01013d3:	53                   	push   %ebx
f01013d4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013d7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01013da:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01013dd:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013e2:	85 d2                	test   %edx,%edx
f01013e4:	74 28                	je     f010140e <strncmp+0x3e>
f01013e6:	0f b6 01             	movzbl (%ecx),%eax
f01013e9:	84 c0                	test   %al,%al
f01013eb:	74 24                	je     f0101411 <strncmp+0x41>
f01013ed:	3a 03                	cmp    (%ebx),%al
f01013ef:	75 20                	jne    f0101411 <strncmp+0x41>
f01013f1:	83 ea 01             	sub    $0x1,%edx
f01013f4:	74 13                	je     f0101409 <strncmp+0x39>
		n--, p++, q++;
f01013f6:	83 c1 01             	add    $0x1,%ecx
f01013f9:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013fc:	0f b6 01             	movzbl (%ecx),%eax
f01013ff:	84 c0                	test   %al,%al
f0101401:	74 0e                	je     f0101411 <strncmp+0x41>
f0101403:	3a 03                	cmp    (%ebx),%al
f0101405:	74 ea                	je     f01013f1 <strncmp+0x21>
f0101407:	eb 08                	jmp    f0101411 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101409:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010140e:	5b                   	pop    %ebx
f010140f:	5d                   	pop    %ebp
f0101410:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101411:	0f b6 01             	movzbl (%ecx),%eax
f0101414:	0f b6 13             	movzbl (%ebx),%edx
f0101417:	29 d0                	sub    %edx,%eax
f0101419:	eb f3                	jmp    f010140e <strncmp+0x3e>

f010141b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010141b:	55                   	push   %ebp
f010141c:	89 e5                	mov    %esp,%ebp
f010141e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101421:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101425:	0f b6 10             	movzbl (%eax),%edx
f0101428:	84 d2                	test   %dl,%dl
f010142a:	74 1c                	je     f0101448 <strchr+0x2d>
		if (*s == c)
f010142c:	38 ca                	cmp    %cl,%dl
f010142e:	75 09                	jne    f0101439 <strchr+0x1e>
f0101430:	eb 1b                	jmp    f010144d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101432:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101435:	38 ca                	cmp    %cl,%dl
f0101437:	74 14                	je     f010144d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101439:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f010143d:	84 d2                	test   %dl,%dl
f010143f:	75 f1                	jne    f0101432 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0101441:	b8 00 00 00 00       	mov    $0x0,%eax
f0101446:	eb 05                	jmp    f010144d <strchr+0x32>
f0101448:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010144d:	5d                   	pop    %ebp
f010144e:	c3                   	ret    

f010144f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010144f:	55                   	push   %ebp
f0101450:	89 e5                	mov    %esp,%ebp
f0101452:	8b 45 08             	mov    0x8(%ebp),%eax
f0101455:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101459:	0f b6 10             	movzbl (%eax),%edx
f010145c:	84 d2                	test   %dl,%dl
f010145e:	74 14                	je     f0101474 <strfind+0x25>
		if (*s == c)
f0101460:	38 ca                	cmp    %cl,%dl
f0101462:	75 06                	jne    f010146a <strfind+0x1b>
f0101464:	eb 0e                	jmp    f0101474 <strfind+0x25>
f0101466:	38 ca                	cmp    %cl,%dl
f0101468:	74 0a                	je     f0101474 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010146a:	83 c0 01             	add    $0x1,%eax
f010146d:	0f b6 10             	movzbl (%eax),%edx
f0101470:	84 d2                	test   %dl,%dl
f0101472:	75 f2                	jne    f0101466 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101474:	5d                   	pop    %ebp
f0101475:	c3                   	ret    

f0101476 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101476:	55                   	push   %ebp
f0101477:	89 e5                	mov    %esp,%ebp
f0101479:	83 ec 0c             	sub    $0xc,%esp
f010147c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010147f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101482:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101485:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101488:	8b 45 0c             	mov    0xc(%ebp),%eax
f010148b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010148e:	85 c9                	test   %ecx,%ecx
f0101490:	74 30                	je     f01014c2 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101492:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101498:	75 25                	jne    f01014bf <memset+0x49>
f010149a:	f6 c1 03             	test   $0x3,%cl
f010149d:	75 20                	jne    f01014bf <memset+0x49>
		c &= 0xFF;
f010149f:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014a2:	89 d3                	mov    %edx,%ebx
f01014a4:	c1 e3 08             	shl    $0x8,%ebx
f01014a7:	89 d6                	mov    %edx,%esi
f01014a9:	c1 e6 18             	shl    $0x18,%esi
f01014ac:	89 d0                	mov    %edx,%eax
f01014ae:	c1 e0 10             	shl    $0x10,%eax
f01014b1:	09 f0                	or     %esi,%eax
f01014b3:	09 d0                	or     %edx,%eax
f01014b5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01014b7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01014ba:	fc                   	cld    
f01014bb:	f3 ab                	rep stos %eax,%es:(%edi)
f01014bd:	eb 03                	jmp    f01014c2 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014bf:	fc                   	cld    
f01014c0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014c2:	89 f8                	mov    %edi,%eax
f01014c4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01014c7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01014ca:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01014cd:	89 ec                	mov    %ebp,%esp
f01014cf:	5d                   	pop    %ebp
f01014d0:	c3                   	ret    

f01014d1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014d1:	55                   	push   %ebp
f01014d2:	89 e5                	mov    %esp,%ebp
f01014d4:	83 ec 08             	sub    $0x8,%esp
f01014d7:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01014da:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01014dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014e3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014e6:	39 c6                	cmp    %eax,%esi
f01014e8:	73 36                	jae    f0101520 <memmove+0x4f>
f01014ea:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014ed:	39 d0                	cmp    %edx,%eax
f01014ef:	73 2f                	jae    f0101520 <memmove+0x4f>
		s += n;
		d += n;
f01014f1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014f4:	f6 c2 03             	test   $0x3,%dl
f01014f7:	75 1b                	jne    f0101514 <memmove+0x43>
f01014f9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014ff:	75 13                	jne    f0101514 <memmove+0x43>
f0101501:	f6 c1 03             	test   $0x3,%cl
f0101504:	75 0e                	jne    f0101514 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101506:	83 ef 04             	sub    $0x4,%edi
f0101509:	8d 72 fc             	lea    -0x4(%edx),%esi
f010150c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010150f:	fd                   	std    
f0101510:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101512:	eb 09                	jmp    f010151d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101514:	83 ef 01             	sub    $0x1,%edi
f0101517:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010151a:	fd                   	std    
f010151b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010151d:	fc                   	cld    
f010151e:	eb 20                	jmp    f0101540 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101520:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101526:	75 13                	jne    f010153b <memmove+0x6a>
f0101528:	a8 03                	test   $0x3,%al
f010152a:	75 0f                	jne    f010153b <memmove+0x6a>
f010152c:	f6 c1 03             	test   $0x3,%cl
f010152f:	75 0a                	jne    f010153b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101531:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101534:	89 c7                	mov    %eax,%edi
f0101536:	fc                   	cld    
f0101537:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101539:	eb 05                	jmp    f0101540 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010153b:	89 c7                	mov    %eax,%edi
f010153d:	fc                   	cld    
f010153e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101540:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101543:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101546:	89 ec                	mov    %ebp,%esp
f0101548:	5d                   	pop    %ebp
f0101549:	c3                   	ret    

f010154a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f010154a:	55                   	push   %ebp
f010154b:	89 e5                	mov    %esp,%ebp
f010154d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101550:	8b 45 10             	mov    0x10(%ebp),%eax
f0101553:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101557:	8b 45 0c             	mov    0xc(%ebp),%eax
f010155a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010155e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101561:	89 04 24             	mov    %eax,(%esp)
f0101564:	e8 68 ff ff ff       	call   f01014d1 <memmove>
}
f0101569:	c9                   	leave  
f010156a:	c3                   	ret    

f010156b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010156b:	55                   	push   %ebp
f010156c:	89 e5                	mov    %esp,%ebp
f010156e:	57                   	push   %edi
f010156f:	56                   	push   %esi
f0101570:	53                   	push   %ebx
f0101571:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101574:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101577:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010157a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010157f:	85 ff                	test   %edi,%edi
f0101581:	74 37                	je     f01015ba <memcmp+0x4f>
		if (*s1 != *s2)
f0101583:	0f b6 03             	movzbl (%ebx),%eax
f0101586:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101589:	83 ef 01             	sub    $0x1,%edi
f010158c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0101591:	38 c8                	cmp    %cl,%al
f0101593:	74 1c                	je     f01015b1 <memcmp+0x46>
f0101595:	eb 10                	jmp    f01015a7 <memcmp+0x3c>
f0101597:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010159c:	83 c2 01             	add    $0x1,%edx
f010159f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01015a3:	38 c8                	cmp    %cl,%al
f01015a5:	74 0a                	je     f01015b1 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01015a7:	0f b6 c0             	movzbl %al,%eax
f01015aa:	0f b6 c9             	movzbl %cl,%ecx
f01015ad:	29 c8                	sub    %ecx,%eax
f01015af:	eb 09                	jmp    f01015ba <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015b1:	39 fa                	cmp    %edi,%edx
f01015b3:	75 e2                	jne    f0101597 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01015b5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015ba:	5b                   	pop    %ebx
f01015bb:	5e                   	pop    %esi
f01015bc:	5f                   	pop    %edi
f01015bd:	5d                   	pop    %ebp
f01015be:	c3                   	ret    

f01015bf <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01015bf:	55                   	push   %ebp
f01015c0:	89 e5                	mov    %esp,%ebp
f01015c2:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01015c5:	89 c2                	mov    %eax,%edx
f01015c7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01015ca:	39 d0                	cmp    %edx,%eax
f01015cc:	73 15                	jae    f01015e3 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f01015ce:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01015d2:	38 08                	cmp    %cl,(%eax)
f01015d4:	75 06                	jne    f01015dc <memfind+0x1d>
f01015d6:	eb 0b                	jmp    f01015e3 <memfind+0x24>
f01015d8:	38 08                	cmp    %cl,(%eax)
f01015da:	74 07                	je     f01015e3 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015dc:	83 c0 01             	add    $0x1,%eax
f01015df:	39 d0                	cmp    %edx,%eax
f01015e1:	75 f5                	jne    f01015d8 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015e3:	5d                   	pop    %ebp
f01015e4:	c3                   	ret    

f01015e5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015e5:	55                   	push   %ebp
f01015e6:	89 e5                	mov    %esp,%ebp
f01015e8:	57                   	push   %edi
f01015e9:	56                   	push   %esi
f01015ea:	53                   	push   %ebx
f01015eb:	8b 55 08             	mov    0x8(%ebp),%edx
f01015ee:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015f1:	0f b6 02             	movzbl (%edx),%eax
f01015f4:	3c 20                	cmp    $0x20,%al
f01015f6:	74 04                	je     f01015fc <strtol+0x17>
f01015f8:	3c 09                	cmp    $0x9,%al
f01015fa:	75 0e                	jne    f010160a <strtol+0x25>
		s++;
f01015fc:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015ff:	0f b6 02             	movzbl (%edx),%eax
f0101602:	3c 20                	cmp    $0x20,%al
f0101604:	74 f6                	je     f01015fc <strtol+0x17>
f0101606:	3c 09                	cmp    $0x9,%al
f0101608:	74 f2                	je     f01015fc <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f010160a:	3c 2b                	cmp    $0x2b,%al
f010160c:	75 0a                	jne    f0101618 <strtol+0x33>
		s++;
f010160e:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101611:	bf 00 00 00 00       	mov    $0x0,%edi
f0101616:	eb 10                	jmp    f0101628 <strtol+0x43>
f0101618:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010161d:	3c 2d                	cmp    $0x2d,%al
f010161f:	75 07                	jne    f0101628 <strtol+0x43>
		s++, neg = 1;
f0101621:	83 c2 01             	add    $0x1,%edx
f0101624:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101628:	85 db                	test   %ebx,%ebx
f010162a:	0f 94 c0             	sete   %al
f010162d:	74 05                	je     f0101634 <strtol+0x4f>
f010162f:	83 fb 10             	cmp    $0x10,%ebx
f0101632:	75 15                	jne    f0101649 <strtol+0x64>
f0101634:	80 3a 30             	cmpb   $0x30,(%edx)
f0101637:	75 10                	jne    f0101649 <strtol+0x64>
f0101639:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010163d:	75 0a                	jne    f0101649 <strtol+0x64>
		s += 2, base = 16;
f010163f:	83 c2 02             	add    $0x2,%edx
f0101642:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101647:	eb 13                	jmp    f010165c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101649:	84 c0                	test   %al,%al
f010164b:	74 0f                	je     f010165c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010164d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101652:	80 3a 30             	cmpb   $0x30,(%edx)
f0101655:	75 05                	jne    f010165c <strtol+0x77>
		s++, base = 8;
f0101657:	83 c2 01             	add    $0x1,%edx
f010165a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010165c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101661:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101663:	0f b6 0a             	movzbl (%edx),%ecx
f0101666:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101669:	80 fb 09             	cmp    $0x9,%bl
f010166c:	77 08                	ja     f0101676 <strtol+0x91>
			dig = *s - '0';
f010166e:	0f be c9             	movsbl %cl,%ecx
f0101671:	83 e9 30             	sub    $0x30,%ecx
f0101674:	eb 1e                	jmp    f0101694 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0101676:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101679:	80 fb 19             	cmp    $0x19,%bl
f010167c:	77 08                	ja     f0101686 <strtol+0xa1>
			dig = *s - 'a' + 10;
f010167e:	0f be c9             	movsbl %cl,%ecx
f0101681:	83 e9 57             	sub    $0x57,%ecx
f0101684:	eb 0e                	jmp    f0101694 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101686:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101689:	80 fb 19             	cmp    $0x19,%bl
f010168c:	77 14                	ja     f01016a2 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010168e:	0f be c9             	movsbl %cl,%ecx
f0101691:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101694:	39 f1                	cmp    %esi,%ecx
f0101696:	7d 0e                	jge    f01016a6 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101698:	83 c2 01             	add    $0x1,%edx
f010169b:	0f af c6             	imul   %esi,%eax
f010169e:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01016a0:	eb c1                	jmp    f0101663 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01016a2:	89 c1                	mov    %eax,%ecx
f01016a4:	eb 02                	jmp    f01016a8 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01016a6:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01016a8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01016ac:	74 05                	je     f01016b3 <strtol+0xce>
		*endptr = (char *) s;
f01016ae:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01016b1:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01016b3:	89 ca                	mov    %ecx,%edx
f01016b5:	f7 da                	neg    %edx
f01016b7:	85 ff                	test   %edi,%edi
f01016b9:	0f 45 c2             	cmovne %edx,%eax
}
f01016bc:	5b                   	pop    %ebx
f01016bd:	5e                   	pop    %esi
f01016be:	5f                   	pop    %edi
f01016bf:	5d                   	pop    %ebp
f01016c0:	c3                   	ret    
	...

f01016d0 <__udivdi3>:
f01016d0:	83 ec 1c             	sub    $0x1c,%esp
f01016d3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01016d7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f01016db:	8b 44 24 20          	mov    0x20(%esp),%eax
f01016df:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01016e3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01016e7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01016eb:	85 ff                	test   %edi,%edi
f01016ed:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01016f1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01016f5:	89 cd                	mov    %ecx,%ebp
f01016f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016fb:	75 33                	jne    f0101730 <__udivdi3+0x60>
f01016fd:	39 f1                	cmp    %esi,%ecx
f01016ff:	77 57                	ja     f0101758 <__udivdi3+0x88>
f0101701:	85 c9                	test   %ecx,%ecx
f0101703:	75 0b                	jne    f0101710 <__udivdi3+0x40>
f0101705:	b8 01 00 00 00       	mov    $0x1,%eax
f010170a:	31 d2                	xor    %edx,%edx
f010170c:	f7 f1                	div    %ecx
f010170e:	89 c1                	mov    %eax,%ecx
f0101710:	89 f0                	mov    %esi,%eax
f0101712:	31 d2                	xor    %edx,%edx
f0101714:	f7 f1                	div    %ecx
f0101716:	89 c6                	mov    %eax,%esi
f0101718:	8b 44 24 04          	mov    0x4(%esp),%eax
f010171c:	f7 f1                	div    %ecx
f010171e:	89 f2                	mov    %esi,%edx
f0101720:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101724:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101728:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010172c:	83 c4 1c             	add    $0x1c,%esp
f010172f:	c3                   	ret    
f0101730:	31 d2                	xor    %edx,%edx
f0101732:	31 c0                	xor    %eax,%eax
f0101734:	39 f7                	cmp    %esi,%edi
f0101736:	77 e8                	ja     f0101720 <__udivdi3+0x50>
f0101738:	0f bd cf             	bsr    %edi,%ecx
f010173b:	83 f1 1f             	xor    $0x1f,%ecx
f010173e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101742:	75 2c                	jne    f0101770 <__udivdi3+0xa0>
f0101744:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101748:	76 04                	jbe    f010174e <__udivdi3+0x7e>
f010174a:	39 f7                	cmp    %esi,%edi
f010174c:	73 d2                	jae    f0101720 <__udivdi3+0x50>
f010174e:	31 d2                	xor    %edx,%edx
f0101750:	b8 01 00 00 00       	mov    $0x1,%eax
f0101755:	eb c9                	jmp    f0101720 <__udivdi3+0x50>
f0101757:	90                   	nop
f0101758:	89 f2                	mov    %esi,%edx
f010175a:	f7 f1                	div    %ecx
f010175c:	31 d2                	xor    %edx,%edx
f010175e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101762:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101766:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010176a:	83 c4 1c             	add    $0x1c,%esp
f010176d:	c3                   	ret    
f010176e:	66 90                	xchg   %ax,%ax
f0101770:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101775:	b8 20 00 00 00       	mov    $0x20,%eax
f010177a:	89 ea                	mov    %ebp,%edx
f010177c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101780:	d3 e7                	shl    %cl,%edi
f0101782:	89 c1                	mov    %eax,%ecx
f0101784:	d3 ea                	shr    %cl,%edx
f0101786:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010178b:	09 fa                	or     %edi,%edx
f010178d:	89 f7                	mov    %esi,%edi
f010178f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101793:	89 f2                	mov    %esi,%edx
f0101795:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101799:	d3 e5                	shl    %cl,%ebp
f010179b:	89 c1                	mov    %eax,%ecx
f010179d:	d3 ef                	shr    %cl,%edi
f010179f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01017a4:	d3 e2                	shl    %cl,%edx
f01017a6:	89 c1                	mov    %eax,%ecx
f01017a8:	d3 ee                	shr    %cl,%esi
f01017aa:	09 d6                	or     %edx,%esi
f01017ac:	89 fa                	mov    %edi,%edx
f01017ae:	89 f0                	mov    %esi,%eax
f01017b0:	f7 74 24 0c          	divl   0xc(%esp)
f01017b4:	89 d7                	mov    %edx,%edi
f01017b6:	89 c6                	mov    %eax,%esi
f01017b8:	f7 e5                	mul    %ebp
f01017ba:	39 d7                	cmp    %edx,%edi
f01017bc:	72 22                	jb     f01017e0 <__udivdi3+0x110>
f01017be:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01017c2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01017c7:	d3 e5                	shl    %cl,%ebp
f01017c9:	39 c5                	cmp    %eax,%ebp
f01017cb:	73 04                	jae    f01017d1 <__udivdi3+0x101>
f01017cd:	39 d7                	cmp    %edx,%edi
f01017cf:	74 0f                	je     f01017e0 <__udivdi3+0x110>
f01017d1:	89 f0                	mov    %esi,%eax
f01017d3:	31 d2                	xor    %edx,%edx
f01017d5:	e9 46 ff ff ff       	jmp    f0101720 <__udivdi3+0x50>
f01017da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017e0:	8d 46 ff             	lea    -0x1(%esi),%eax
f01017e3:	31 d2                	xor    %edx,%edx
f01017e5:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017e9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017ed:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017f1:	83 c4 1c             	add    $0x1c,%esp
f01017f4:	c3                   	ret    
	...

f0101800 <__umoddi3>:
f0101800:	83 ec 1c             	sub    $0x1c,%esp
f0101803:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101807:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f010180b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010180f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101813:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101817:	8b 74 24 24          	mov    0x24(%esp),%esi
f010181b:	85 ed                	test   %ebp,%ebp
f010181d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101821:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101825:	89 cf                	mov    %ecx,%edi
f0101827:	89 04 24             	mov    %eax,(%esp)
f010182a:	89 f2                	mov    %esi,%edx
f010182c:	75 1a                	jne    f0101848 <__umoddi3+0x48>
f010182e:	39 f1                	cmp    %esi,%ecx
f0101830:	76 4e                	jbe    f0101880 <__umoddi3+0x80>
f0101832:	f7 f1                	div    %ecx
f0101834:	89 d0                	mov    %edx,%eax
f0101836:	31 d2                	xor    %edx,%edx
f0101838:	8b 74 24 10          	mov    0x10(%esp),%esi
f010183c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101840:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101844:	83 c4 1c             	add    $0x1c,%esp
f0101847:	c3                   	ret    
f0101848:	39 f5                	cmp    %esi,%ebp
f010184a:	77 54                	ja     f01018a0 <__umoddi3+0xa0>
f010184c:	0f bd c5             	bsr    %ebp,%eax
f010184f:	83 f0 1f             	xor    $0x1f,%eax
f0101852:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101856:	75 60                	jne    f01018b8 <__umoddi3+0xb8>
f0101858:	3b 0c 24             	cmp    (%esp),%ecx
f010185b:	0f 87 07 01 00 00    	ja     f0101968 <__umoddi3+0x168>
f0101861:	89 f2                	mov    %esi,%edx
f0101863:	8b 34 24             	mov    (%esp),%esi
f0101866:	29 ce                	sub    %ecx,%esi
f0101868:	19 ea                	sbb    %ebp,%edx
f010186a:	89 34 24             	mov    %esi,(%esp)
f010186d:	8b 04 24             	mov    (%esp),%eax
f0101870:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101874:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101878:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010187c:	83 c4 1c             	add    $0x1c,%esp
f010187f:	c3                   	ret    
f0101880:	85 c9                	test   %ecx,%ecx
f0101882:	75 0b                	jne    f010188f <__umoddi3+0x8f>
f0101884:	b8 01 00 00 00       	mov    $0x1,%eax
f0101889:	31 d2                	xor    %edx,%edx
f010188b:	f7 f1                	div    %ecx
f010188d:	89 c1                	mov    %eax,%ecx
f010188f:	89 f0                	mov    %esi,%eax
f0101891:	31 d2                	xor    %edx,%edx
f0101893:	f7 f1                	div    %ecx
f0101895:	8b 04 24             	mov    (%esp),%eax
f0101898:	f7 f1                	div    %ecx
f010189a:	eb 98                	jmp    f0101834 <__umoddi3+0x34>
f010189c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018a0:	89 f2                	mov    %esi,%edx
f01018a2:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018a6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018aa:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018ae:	83 c4 1c             	add    $0x1c,%esp
f01018b1:	c3                   	ret    
f01018b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018b8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018bd:	89 e8                	mov    %ebp,%eax
f01018bf:	bd 20 00 00 00       	mov    $0x20,%ebp
f01018c4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f01018c8:	89 fa                	mov    %edi,%edx
f01018ca:	d3 e0                	shl    %cl,%eax
f01018cc:	89 e9                	mov    %ebp,%ecx
f01018ce:	d3 ea                	shr    %cl,%edx
f01018d0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018d5:	09 c2                	or     %eax,%edx
f01018d7:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018db:	89 14 24             	mov    %edx,(%esp)
f01018de:	89 f2                	mov    %esi,%edx
f01018e0:	d3 e7                	shl    %cl,%edi
f01018e2:	89 e9                	mov    %ebp,%ecx
f01018e4:	d3 ea                	shr    %cl,%edx
f01018e6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018eb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018ef:	d3 e6                	shl    %cl,%esi
f01018f1:	89 e9                	mov    %ebp,%ecx
f01018f3:	d3 e8                	shr    %cl,%eax
f01018f5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018fa:	09 f0                	or     %esi,%eax
f01018fc:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101900:	f7 34 24             	divl   (%esp)
f0101903:	d3 e6                	shl    %cl,%esi
f0101905:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101909:	89 d6                	mov    %edx,%esi
f010190b:	f7 e7                	mul    %edi
f010190d:	39 d6                	cmp    %edx,%esi
f010190f:	89 c1                	mov    %eax,%ecx
f0101911:	89 d7                	mov    %edx,%edi
f0101913:	72 3f                	jb     f0101954 <__umoddi3+0x154>
f0101915:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101919:	72 35                	jb     f0101950 <__umoddi3+0x150>
f010191b:	8b 44 24 08          	mov    0x8(%esp),%eax
f010191f:	29 c8                	sub    %ecx,%eax
f0101921:	19 fe                	sbb    %edi,%esi
f0101923:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101928:	89 f2                	mov    %esi,%edx
f010192a:	d3 e8                	shr    %cl,%eax
f010192c:	89 e9                	mov    %ebp,%ecx
f010192e:	d3 e2                	shl    %cl,%edx
f0101930:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101935:	09 d0                	or     %edx,%eax
f0101937:	89 f2                	mov    %esi,%edx
f0101939:	d3 ea                	shr    %cl,%edx
f010193b:	8b 74 24 10          	mov    0x10(%esp),%esi
f010193f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101943:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101947:	83 c4 1c             	add    $0x1c,%esp
f010194a:	c3                   	ret    
f010194b:	90                   	nop
f010194c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101950:	39 d6                	cmp    %edx,%esi
f0101952:	75 c7                	jne    f010191b <__umoddi3+0x11b>
f0101954:	89 d7                	mov    %edx,%edi
f0101956:	89 c1                	mov    %eax,%ecx
f0101958:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f010195c:	1b 3c 24             	sbb    (%esp),%edi
f010195f:	eb ba                	jmp    f010191b <__umoddi3+0x11b>
f0101961:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101968:	39 f5                	cmp    %esi,%ebp
f010196a:	0f 82 f1 fe ff ff    	jb     f0101861 <__umoddi3+0x61>
f0101970:	e9 f8 fe ff ff       	jmp    f010186d <__umoddi3+0x6d>
