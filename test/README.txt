This file describes how to statically examine your changes to vuln while
completing the exercises. It also describes how to dynamically test whether the
code runs and prevents an exploit. TL;DR: try ./test1.sh and ./test2.sh.

###############################################
### Statically examining code transformations

This directory contains a vulnerable program, vuln.c, with a buffer overrun.
The attacker's goal is to use the buffer overrun to overwrite the instruction
pointer and execute the function attacker_target. To build, run

$ make

As you are building a defense and want to see which instructions have been
added by your tool, try the following. This example demonstrates the result
after exercise 1a has been finished, as a diff on the instructions (it will be
red/green colored if you run it in a terminal):

$ ../app/etapp -q vuln vuln.0  # run before any of your changes
$ ../app/etapp -q vuln vuln.alloc  # with your changes
$ ./cmpfunc.sh __libc_start_main vuln.0 vuln.alloc
 <__libc_start_main>:                                            <__libc_start_main>:
                                                              >         e8 fb a6 18 00          callq  4018b3f6 <egalito_allo
        41 55                   push   %r13                             41 55                   push   %r13
        41 54                   push   %r12                             41 54                   push   %r12
        31 c0                   xor    %eax,%eax                        31 c0                   xor    %eax,%eax
...                                                              ...

After exercise 1b has been finished:

$ ../app/etapp -q vuln vuln.alloc  # with your changes
$ ./cmpfunc.sh main vuln.0 vuln.alloc
~/egalito-shadow-stack-app/test$ ./cmpfunc.sh egalito_allocate_shadow_stack vuln.0 vuln.1.alloc
 <egalito_allocate_shadow_stack>:                                <egalito_allocate_shadow_stack>:
        50                      push   %rax                             50                      push   %rax
        51                      push   %rcx                             51                      push   %rcx
        52                      push   %rdx                             52                      push   %rdx
...                                                              ...
        41 54                   push   %r12                             41 54                   push   %r12
        55                      push   %rbp                             55                      push   %rbp
        48 89 e5                mov    %rsp,%rbp                        48 89 e5                mov    %rsp,%rbp
                                                              >         48 83 ec 20             sub    $0x20,%rsp
                                                              >         64 48 8b 04 25 28 00    mov    %fs:0x28,%rax
                                                              >         00 00 
                                                              >         48 89 45 f8             mov    %rax,-0x8(%rbp)
                                                              >         31 c0                   xor    %eax,%eax
                                                              >         c7 45 e4 ef be ad de    movl   $0xdeadbeef,-0x1c(%rbp
                                                              >         48 8d 45 e4             lea    -0x1c(%rbp),%rax
                                                              >         48 25 00 f0 ff ff       and    $0xfffffffffffff000,%r
...                                                              ...

After exercise 2 has been finished:

$ ./cmpfunc.sh main vuln.0 vuln.push
 <main>:                                                         <main>:
        41 53                   push   %r11                             41 53                   push   %r11
                                                              >         4c 8b 5c 24 08          mov    0x8(%rsp),%r11
                                                              >         4c 89 9c 24 08 00 50    mov    %r11,-0xaffff8(%rsp)
                                                              >         ff 
        41 5b                   pop    %r11                             41 5b                   pop    %r11
        55                      push   %rbp                             55                      push   %rbp
        48 89 e5                mov    %rsp,%rbp                        48 89 e5                mov    %rsp,%rbp
        48 83 ec 10             sub    $0x10,%rsp                       48 83 ec 10             sub    $0x10,%rsp
        89 7d fc                mov    %edi,-0x4(%rbp)                  89 7d fc                mov    %edi,-0x4(%rbp)
        48 89 75 f0             mov    %rsi,-0x10(%rbp)                 48 89 75 f0             mov    %rsi,-0x10(%rbp)
        e8 74 ff ff ff          callq  4000018c <read_input>  |         e8 5b ff ff ff          callq  400001de <read_input>
        48 8d 3d 4c 07 00 d0    lea    -0x2ffff8b4(%rip),%rdi |         48 8d 3d e1 06 00 d0    lea    -0x2ffff91f(%rip),%rdi
        e8 24 0a 06 00          callq  40060c48 <_IO_puts>    |         e8 47 24 06 00          callq  400626d6 <_IO_puts>
        b8 00 00 00 00          mov    $0x0,%eax                        b8 00 00 00 00          mov    $0x0,%eax
        c9                      leaveq                                  c9                      leaveq
        9c                      pushfq                                  9c                      pushfq
        41 53                   push   %r11                             41 53                   push   %r11
        41 5b                   pop    %r11                             41 5b                   pop    %r11
        9d                      popfq                                   9d                      popfq
        c3                      retq                                    c3                      retq

After exercise 3 has been finished:

$ ./cmpfunc.sh main vuln.0 vuln.pop
 <main>:                                                         <main>:
...                                         ...
        e8 5b ff ff ff          callq  400001de <read_input>  |         e8 47 ff ff ff          callq  40000278 <read_input>
        48 8d 3d e1 06 00 d0    lea    -0x2ffff91f(%rip),%rdi |         48 8d 3d 33 06 00 d0    lea    -0x2ffff9cd(%rip),%rdi
        e8 41 24 06 00          callq  400626d0 <_IO_puts>    |         e8 cd 54 06 00          callq  4006580a <_IO_puts>
        b8 00 00 00 00          mov    $0x0,%eax                        b8 00 00 00 00          mov    $0x0,%eax
        c9                      leaveq                                  c9                      leaveq
        9c                      pushfq                                  9c                      pushfq
        41 53                   push   %r11                             41 53                   push   %r11
                                                              >         4c 8b 5c 24 10          mov    0x10(%rsp),%r11
                                                              >         4c 39 9c 24 10 00 50    cmp    %r11,-0xaffff0(%rsp)
                                                              >         ff 
                                                              >         0f 85 a7 fc ff ff       jne    40000000 <egalito_shad
        41 5b                   pop    %r11                             41 5b                   pop    %r11
        9d                      popfq                                   9d                      popfq
        c3                      retq                                    c3                      retq

After exercise 4 has been finished (since the function is newly introduced, it
does not exist in the original code):

$ ./cmpfunc.sh egalito_shadowstack_violation vuln.0 vuln.violation
                                                              >  <egalito_shadowstack_violation>:
                                                              >         0f 0b                   ud2    


###############################################
### Dynamically testing code transformations

TL;DR: try ./test1.sh and ./test2.sh.

Let's first consider how you would exploit this program without the address
randomization of ASLR. You can disable ASLR with

$ setarch `uname -m` -R /bin/bash

but a simpler approach is to run programs within gdb, which will disable ASLR.
We can see that, on this system, the target is always at 0x5555555547da. Hence
we can generate an exploit like so. The buffer is 64 bytes, followed by an
8-byte base pointer, followed by the 8-byte return address.

$ perl -e 'print "A"x(64+8) . "\xda\x47\x55\x55\x55\x55\x00\x00"' > vuln.gdb.in
$ gdb -q ./vuln
Reading symbols from ./vuln...(no debugging symbols found)...done.
(gdb) run < vuln.gdb.in
Starting program: /home/egalito/egalito-shadow-stack-app/test/vuln < vuln.gdb.in
buf is at 0x7fffffffe370, target is at 0x5555555547da

buf: [AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAUUUU]
successful exploit! congratulations.
[Inferior 1 (process 12925) exited with code 01]
(gdb) q

You can also use the script vuln.pl, which works for any target address. It
parses the address and generates an exploit at run time.

$ perl vuln.pl ./vuln
spawn child process {./vuln}
child wrote {buf is at 0x7ffe9019bd80, target is at 0x5618f14517da}
exploit is {AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEV}
child process output {}
child process output {buf: [AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEV]}
child process output {successful exploit! congratulations.}
child exited with status 1

This works even on a binary transformed with Egalito. (It also works even if
you add padding, rearrange functions, etc.) Note the different addresses of
attacker_target.

$ ../egalito/app/etelf vuln vuln.m
Transforming file [vuln]
Parsing ELF file...
Performing code generation into [vuln.m]...
$ nm vuln | grep ' T '
0000000000000900 T __libc_csu_fini
0000000000000890 T __libc_csu_init
0000000000000904 T _fini
0000000000000648 T _init
00000000000006d0 T _start
00000000000007da T attacker_target
000000000000085d T main
00000000000007f4 T read_input
$ nm vuln.m | grep ' T '
0000000040000230 T __libc_csu_fini
00000000400001ca T __libc_csu_init
0000000040000232 T _fini
0000000040000000 T _init
0000000040000018 T _start
000000004000011e T attacker_target
000000004000027c T exit@plt
000000004000026c T fflush@plt
000000004000025c T fgets@plt
00000000400001a2 T main
000000004000024c T printf@plt
000000004000023c T puts@plt
0000000040000138 T read_input
$ perl vuln.pl ./vuln.m
spawn child process {./vuln.m}
child wrote {buf is at 0x7fff6c22c2f0, target is at 0x55ed93e3e11e}
exploit is {AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA}
child process output {}
child process output {buf: [AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA]}
child process output {successful exploit! congratulations.}
child exited with status 1

Finally, if you have finished building the shadow stack app, you can use it to
defend vuln.

$ ../app/etapp -q vuln vuln.ss
Parsing file [vuln]
Injecting code from our library
Final parsing results:
    parsed Module module-(executable)
    parsed Module module-libc.so.6
    parsed Module module-../app/libinject.so
Adding shadow stack...
Performing code generation into [vuln.ss]...
$ perl vuln.pl ./vuln.ss
spawn child process {./vuln.ss}
child wrote {buf is at 0x7fff10084530, target is at 0x4000024c}
exploit is {AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAL@}
child died with signal 4

Notice the exit signal 4, SIGILL, because we intentionally executed an ud2
undefined instruction after the stack integrity violation. You can see this by
examining the core dump in gdb:

$ ulimit -c unlimited
$ perl vuln.pl ./vuln.ss
spawn child process {./vuln.ss}
child wrote {buf is at 0x7ffdf95a63e0, target is at 0x4000024c}
exploit is {AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAL@}
child died with signal 4
$ gdb -q vuln.ss core
Reading symbols from vuln.ss...(no debugging symbols found)...done.
[New LWP 12899]
Core was generated by `./vuln.ss'.
Program terminated with signal SIGILL, Illegal instruction.
#0  0x0000000040000000 in egalito_shadowstack_violation ()
(gdb) x/i $rip
=> 0x40000000 <egalito_shadowstack_violation>:  ud2
(gdb) q

Congratulations, that is an indication of a successful defense.
