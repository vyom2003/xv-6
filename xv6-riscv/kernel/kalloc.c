// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;
struct spinlock lock;
int ref[PGROUNDUP(PHYSTOP)/4096];
void init(){
  initlock(&lock, "init_fault");
  acquire(&lock);
  for(int i=0;i<(PGROUNDUP(PHYSTOP)/4096);++i)
    ref[i]=0;
  release(&lock);
}
void sub(void*pa){
  acquire(&lock);
  if(ref[(uint64)pa/4096]<=0){
    panic("sub");
  }
  ref[(uint64)pa/4096]-=1;
  release(&lock);
}
void add(void*pa){
  acquire(&lock);
  if(ref[(uint64)pa/4096]<0){
    panic("add");
  }
  ref[(uint64)pa/4096]+=1;
  release(&lock);
}
void
kinit()
{
  init();
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    add(p);
     kfree(p);
  }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");
  sub(pa);
  if(ref[(uint64)pa/4096]>0) return;
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r){
     memset((char*)r, 5, PGSIZE); // fill with junk
    add((void*)r);
  } // fill with junk
  return (void*)r;
}
