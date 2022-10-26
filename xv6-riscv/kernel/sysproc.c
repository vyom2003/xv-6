#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_trace(void)
{
  int mask;
  argint(0, &mask);

  myproc()->trace_mask = mask;
  return 0;
}

uint64
sys_sigalarm(void)
{
  int arg1;
  uint64 arg2;
  argint(0, &arg1), argaddr(1, &arg2);
  myproc()->alarm = 1, myproc()->ticks = arg1, myproc()->handler = arg2;
  return 0;
}

uint64
sys_sigreturn(void)
{
  struct proc *p = myproc();
  p->alarm = 1;
  p->copy->kernel_satp = p->trapframe->kernel_satp;
  p->copy->kernel_hartid = p->trapframe->kernel_hartid;
  p->copy->kernel_sp = p->trapframe->kernel_sp;
  p->copy->kernel_trap = p->trapframe->kernel_trap;

  *(p->trapframe) = *(p->copy);
  return p->trapframe->a0;
}
#ifdef LBS
uint64
sys_settickets(void)
{
  int arg1;
  argint(0, &arg1);
  totaltickets = totaltickets - myproc()->tickets + arg1;
  myproc()->tickets = arg1;
  return myproc()->trapframe->a0;
}
#endif

uint64
sys_set_priority(void)
{
  int priority, pid, oldpriority = 101;
  argint(0, &priority);
  argint(1, &pid);
  if (priority < 0 || priority > 100)
    return -1;
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      oldpriority = p->priority;
      p->priority = priority;
    }
    release(&p->lock);
  }
  if (priority < oldpriority)
    yield();
  return oldpriority;
}

uint64
sys_waitx(void)
{
  uint64 p, raddr, waddr;
  int rtime, wtime;
  argaddr(0, &p);
  argaddr(1, &raddr);
  argaddr(2, &waddr);
  int ret = waitx(p, &rtime, &wtime);
  struct proc *proc = myproc();
  if (copyout(proc->pagetable, raddr, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  if (copyout(proc->pagetable, waddr, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  return ret;
}
