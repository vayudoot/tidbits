
Taken from - https://plus.google.com/+MagnusHoff/posts/9gxSUZMJUF2

In an effort to educate the dunces +Knut Arild Erstad and +Jon Packer who apparently never programmed in assembly, I am going to post a step by step instruction on making a snake game in x86-64/amd64 assembly on a modern operating system. Here. As if this were some kind of a blog. I am learning x86-64 assembly as I go, which makes this even more of a blog-like experience.

The modern operating system I chose is OS X 10.6. The same assembly might work directly in BSD and should work with only minor changes in Linux. The build rules will require additional changes :)

The goal is to make an interactive realtime snake game in the terminal. Graphics was a lot easier in the old days when you would just write directly to the video memory, but that is unavailable now and I would rather make this more contemporary than making it more graphical but limit it to Dosbox.

For programming assembly we need an assembler. GCC has got one, but it uses AT&T syntax for no good reason, which is harder to read and write than Intel syntax. Therefore, we choose NASM, which implements Intel syntax. Install the nasm binary somewhere in your PATH. You might already have a /usr/bin/nasm from Xcode which is too old to support x86-64, so be sure not to confuse that one with the one you just installed.

# Step 1: Assemble, link and execute

In this installment, we are implementing the "true" command line utility. It executes and returns 0, indicating success. An equivalent C program is "int main() { return 0; }". Simple, but a good place to start to check that all the tools are working and that everything is in place.

In reality, unlike the overly abstract world of C, the entry to a process does not act exactly as a function call, and the exit is not like a function return. C programs usually get compiled with trampoline functions to make all of this more convenient. We will go straight for calling the "exit" function with 0 as the argument.

Although, before we get to that, we need to supply an entry point to our program and export this symbol to the linker. We do the exporting first, by declaring "global main" at the top of our new file "true.asm". Go ahead, it is safe. Now, immediately below it we write "main:" on a line for itself. "main:" is a label, and referring to this label anywhere will give us its address. This is what the linker needs. (true.asm should now look like this: ) -
```
global main

main:
```

This is actually all we need to assemble and link.

**Assembling (.asm -> .o)**: nasm -f macho64 -o true.o true.asm

"-f macho64" tells NASM to produce an object file of the Mach-O 64bit format. This should be "elf64" for Linux, for example. "nasm -hf" gives you a list of the formats NASM supports.

**Linking (.o -> executable)**: ld -macosx_version_min 10.6 -o true -e main true.o

"-e main" tells the linker that "main" is the label of our entry point, and the linker can find it because we have "global main" in our .asm file.

It should now be possible to execute "./true", and it will probably cause the nondescript error message "Bus error: 10" to appear.

# Step 2: exit(0)

We are not going to call the "exit" function in the C runtime library, but rather the "exit" system call via the OS's syscall functionality. There is some information on this in /usr/include/sys/syscall.h, and in it we can see that "SYS_exit" has identification number 1. Nice.

Thanks to http://thexploit.com/secdev/mac-os-x-64-bit-assembly-system-calls/ I also found out that since "exit" is classified as a Unix call, it gets to have an identifier of [whatever's in syscall.h] + 0x02000000. That is, 0x02000001. Great. We now know how to identify the system call "exit".

We also know that exit takes an argument, the value to return.

According to the ABI (http://www.x86-64.org/documentation/abi.pdf) we should put the syscall number in the register "rax" and the first argument in the register "rdi". Think of registers as (global-ish) variables that you don't get to name. So, in pseudocode, we want something like:
```
    rax := 0x02000001; // Put the ID for SYS_exit into rax
    rdi := 0; // Put the desired exit status value into rdi
    performTheSyscall;
```

This is quite easy to express in assembly:
```
    mov rax, 0x02000001
    mov rdi, 0
    syscall
```

Now, test.asm should look something like [this](lesson01/true.asm)

"syscall" is actually a dedicated assembly instruction that was introduced in the x86-64 instruction set to make calls to the operating system more snappy.

Now you should be able to assemble, link and run this proper implementation and it should act exactly like the "true" built-in in bash.

Exercise for the reader: Modify this to implement "false" ;)

Aside: For your convenience, please use a "Makefile". Maybe [this](lesson01/Makefile) one.

# Step 3: Calling write

We are now ready for "Hello world"! We know how to do a syscall, so let's see (in /usr/include/sys/syscall.h) if we can use one for printing. "SYS_write" (4) looks promising, and in fact it is the POSIX write that has a documented C API we can read with "man 2 write":
```
ssize_t write(int fildes, const void *buf, size_t nbyte);
```

Oh, wow. There's lots of arguments and datatypes and stuff. Again, the ABI tells us to put arguments in sequence in the registers rdi, rsi, rdx, rcx, r8 and r9. And if we need more arguments, we will have to look at the ABI again.

filedes: We want to write to standard out, and its fileno is defined in POSIX as 1. We can verify this information against /usr/include/unistd.h, where STDOUT_FILENO is defined as 1.

buf: We need a string to write. Let's postpone that slightly!

nbyte: This is the count of bytes to write. Let's write 0 of them for now.

This should translate to the following assembly:
```
    mov rax, 0x02000004 ; Again, 0x02000000 added for a "Unix" type call
    mov rdi, 1 ; filedes = 1
    mov rsi, 0xdeadbabe ; Filler value, we postponed the problem of buf
    mov rdx, 0 ; Write zero bytes from this buffer
    syscall
```

Combining with the skeleton "true.asm" you should be able to come up with an "hello.asm" that looks something like [this](lesson02/hello.asm).

When assembled and linked, this should reliably execute without writing anything or failing. Even though we give a bogus pointer value in, it never gets dereferenced since the nbyte argument is 0.

Now we are calling write! Let's give it something to say.

# Step 4: Data section

We need a string constant to write to stdout, and we are going to put one in static storage. We do this by putting in stuff for the assembler and linker that isn't assembly code. First, we partition the file into two sections, one for data and one for code. The one for data is called ".data" and the one for code is called ".text".

Put a line with "section .data" at the top of your file, put in a couple of blank lines and then "section .text" as a header for your code. Everything that's under the "section .data" header, but above the "section .text" header will now be said to be in the data section, while everything underneath the "section .text" header will be said to be in the text section. It should now look like [this]().

In the data section, put a definition for a string. It is going to be data that we specify bytewise, so we are going to use the keyword db:
```
    hello_world db "Hello world!", 0x0a
```

0x0a is the control character for a newline. In C we would have used "\n", which can be mapped to other values depending on the platform. C is much more cross platform compatible than assembly!

Now, we can update the call to write with proper values:
```
    mov rsi, hello_world ; The assembler and/or linker will make sure rsi gets the address of the string above

    mov rdx, 13 ; The string, including the newline, is 13 bytes long
```

The file should now look like this:
```
section .data
hello_world     db      "Hello World!", 0x0a

section .text
global main

main:
    mov rax, 0x02000004     ; SYS_write
    mov rdi, 1              ; filedes = STDOUT_FILENO = 1
    mov rsi, hello_world    ; The address of hello_world string
    mov rdx, 13             ; The size to write
    syscall

    mov rax, 0x02000001     ; SYS_exit
    mov rdi, 0              ; Exit status
    syscall
```

Congratulations! You have implemented "Hello world" in assembly! :)

# Step 5: Disassembly

A big point of knowing assembly is to know exactly what is happening under the hood. However, the "mov rsi, hello_world" instruction above gets lots of interpretation. Let's look closer with otool.

First, look at the data section:
```
    otool -d ./hello
```

The output I get is:
```
    ./hello:
    (__DATA,__data) section
    0000000000002000 48 65 6c 6c 6f 20 57 6f 72 6c 64 21 0a
```

"0000000000002000" is the address where the data section starts, and the bytes from "48" through "0a" is the string we put in, ASCII coded and presented in hex. Nice. This is pretty much exactly what we put in. Notice that there is no label, no information on structure inside the data section.

Next, look at the text/code section:
```
    otool -t ./hello

    ./hello:
    (__TEXT,__text) section
    0000000000001fd9 b8 04 00 00 02 bf 01 00 00 00 48 be 00 20 00 00
    0000000000001fe9 00 00 00 00 ba 0d 00 00 00 0f 05 b8 01 00 00 02
    0000000000001ff9 bf 00 00 00 00 0f 05
```

Oh. That's not very readable. We can get otool to disassemble it for us, but beware, for it uses the ugly AT&T syntax:
```
    otool -tv ./hello

    ./hello:
    (__TEXT,__text) section
    main:
    0000000000001fd9 movl $0x02000004,%eax
    0000000000001fde movl $0x00000001,%edi
    0000000000001fe3 movq $0x0000000000002000,%rsi
    0000000000001fed movl $0x0000000d,%edx
    0000000000001ff2 syscall
    0000000000001ff4 movl $0x02000001,%eax
    0000000000001ff9 movl $0x00000000,%edi
    0000000000001ffe syscall
```

The order of the operands to mov are backwards! Sigh. The big number on the left is just the address of each instruction.

This looks pretty much like what we put it. The most interesting difference is the line where we set rsi. In our source code it is "mov rsi, hello_world", but the result, translated to Intel syntax, is "mov rsi, 0x0000000000002000". This is the address in the data section where our string starts, so this is pretty good news :) This gives an insight into how symbols are dereferenced during assembling and linking.

The second thing we notice is that some of our "r"-s have been turned into "e"-s. This is an optimization nasm put in for us. The registers, as we know, have not always been 64 bits wide, so there is some legacy here. Let's consider rax as an example:

Using rax, you speak of the entire 64 bit register. eax is the low 32 bits. The low 16 bits are called ax and the low 8 bits al. Additionally, bits 8-15 can be accessed directly as ah.

When defining the x86-64 instruction set, AMD realized that requiring you to put 64 bits of data into the text section every time you wanted to set a register would quickly fill up code with lots of worthless 0 bytes, in turn filling up expensive cache lines in the processor with the same. So as a special rule, when setting a 32 bit register, the high 32 bits always get nulled out. So "mov eax, 0x12345678" has the same effect as "mov rax,0x0000000012345678", but the eax one is four bytes smaller than the rax one.

Now we can understand the disassembly from otool, and how it relates to the original source code. Hooray!

