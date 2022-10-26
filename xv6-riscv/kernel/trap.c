#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct spinlock tickslock;
uint ticks;
int num = 0;

extern char trampoline[], uservec[], userret[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}
int write_trap(void *va, pagetable_t pagetable)
{

  struct proc *p = myproc();
  if ((uint64)va < MAXVA && ((uint64)va < PGROUNDDOWN(p->trapframe->sp) - PGSIZE || (uint64)va > PGROUNDDOWN(p->trapframe->sp)))
  {
    pte_t *pte;
    uint64 pa;
    uint flags;
    va = (void *)PGROUNDDOWN((uint64)va);
    pte = walk(pagetable, (uint64)va, 0);
    if (pte)
    {
      pa = PTE2PA(*pte);
      if(!pa) return -1;
    }
    else
    {
      return -1;
    }
    flags = PTE_FLAGS(*pte);
    if (flags & PTE_C)
    {
      flags = (flags | PTE_W) ;
      flags &= (~PTE_C);
      char *mem;
      mem = kalloc();
      if (!mem)
        return -1;
      memmove(mem, (void *)pa, PGSIZE);
      *pte = PA2PTE(mem) | flags;
      kfree((void *)pa);
      return 0;
    }
    return 0;
  }
  else
  {
    return -1;
  }
}
//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
void usertrap(void)
{
  int which_dev = 0;

  if ((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint64)kernelvec);

  struct proc *p = myproc();

  // save user program counter.
  p->trapframe->epc = r_sepc();

  if (r_scause() == 8)
  {
    // system call

    if (killed(p))
      exit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->trapframe->epc += 4;

    // an interrupt will change sepc, scause, and sstatus,
    // so enable only now that we're done with those registers.
    intr_on();

    syscall();
  }
  else if ((which_dev = devintr()) != 0)
  {
    // ok
  }
  else if (r_scause() == 15)
  {
    if (r_stval() == 0)
      p->killed = 1;
    else
    {
      int res = write_trap((void *)r_stval(), p->pagetable);
      if (res == -1)
      {
        p->killed = 1;
      }
    }
  }
  else
  {
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    setkilled(p);
  }

  if (killed(p))
    exit(-1);

  // give up the CPU if this is a timer interrupt.
  if (which_dev == 2)
  {
    myproc()->ticks_after++;
    if (myproc()->alarm && myproc()->ticks == myproc()->ticks_after)
    {
      *(myproc()->copy) = *(myproc()->trapframe);
      myproc()->trapframe->epc = myproc()->handler;
      myproc()->ticks_after = 0;
      myproc()->alarm = 0;
    }
#ifdef RR
    yield();
#endif
#ifdef LBS
    yield();
#endif
#ifdef MLFQ
    int flg = 0;
    p->tick_ctr++;
    struct proc *p_sched;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state ==RUNNABLE && ticks - p->last_exec > WAIT_TIME)
      {
        if (p->queue_level > 0)
        {
          p->last_exec = ticks;
          p->in_time = ticks;
          p->queue_level--;
        }
      }
      if (p->state == RUNNABLE && p->queue_level < myproc()->queue_level)
      {
        flg = 1;
      }
      release(&p->lock);
    }
    p_sched = myproc();
    int x = p_sched->queue_level;
    int y = 1;
    while (x--)
      y *= 2;
    if (p_sched->tick_ctr == y)
    {
      p_sched->tick_ctr = 0;
      p_sched->in_time = ticks;
      if (p_sched->queue_level < 4)
        p_sched->queue_level++;
      yield();
    }
    else if (flg == 1)
    {
      p_sched->tick_ctr = 0;
      p_sched->in_time = ticks;
      yield();
    }
#endif
  }
  usertrapret();
}

//
// return to user space
//
void usertrapret(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64))trampoline_userret)(satp);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();

  if ((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if (intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if ((which_dev = devintr()) == 0)
  {
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
  {
#ifdef RR
    yield();
#endif
#ifdef LBS
    yield();
#endif
#ifdef MLFQ
    myproc()->tick_ctr++;
    int flg = 0;
    struct proc *p_sched;
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE && ticks - p->last_exec > WAIT_TIME)
      {
        if (p->queue_level > 0)
        {
          p->last_exec = ticks;
          p->in_time = ticks;
          p->queue_level--;
        }
      }
      if (p->state == RUNNABLE && p->queue_level < myproc()->queue_level)
      {
        flg = 1;
      }
      release(&p->lock);
    }
    p_sched = myproc();
    int x = p_sched->queue_level;
    int y = 1;
    while (x--)
      y *= 2;
    if (p_sched->tick_ctr == y)
    {
      p_sched->tick_ctr = 0;
      p_sched->in_time = ticks;
      if (p_sched->queue_level < 4)
        p_sched->queue_level++;
      yield();
    }
    else if (flg == 1)
    {
      p_sched->tick_ctr = 0;
      p_sched->in_time = ticks;
      yield();
    }
#endif
  }

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
  acquire(&tickslock);
  ticks++;
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->trtime++;
#ifdef PBS
      p->runtime++;
#endif
    }
    if (p->state == SLEEPING)
    {
      p->twtime++;
#ifdef PBS
      p->waittime++;
#endif
    }
    release(&p->lock);
  }
  wakeup(&ticks);
  release(&tickslock);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
      (scause & 0xff) == 9)
  {
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if (irq == UART0_IRQ)
    {
      uartintr();
    }
    else if (irq == VIRTIO0_IRQ)
    {
      virtio_disk_intr();
    }
    else if (irq)
    {
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
  {
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if (cpuid() == 0)
    {
      clockintr();
    }

    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  }
  else
  {
    return 0;
  }
}
