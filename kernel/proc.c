#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

list unusedList;
list zombieList;
list sleepingList;

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;
extern uint64 cas(volatile void*addr,int expected,int newval);

int setcpu(int cpuNum)
{
  myproc()->cpu_num = cpuNum;
  return cpuNum;
}

int getcpu( )
{
  return myproc()->cpu_num;
}


void add_proc_to_list(list* l,int indexInProc){
  // printf("Adding proc %d to \"%s\"\n", indexInProc, l->lock.name);
  // printf("Acquiring \"%s\"\n",l->lock.name);
  acquire(&l->lock);
  //list size = 0
  if(l->first==-1)
  {
    // printf("list \"%s\" is empty\n",l->lock.name);
    // printf("Acquiring proc %d\n",indexInProc);
    acquire(&proc[indexInProc].stateLock);

    struct proc* toAdd=&proc[indexInProc];

    l->first = indexInProc;
    l->last = indexInProc;
    toAdd->next_index_in_list = -1;


    // printf("Releasing \"%s\"\n",l->lock.name);
    release(&l->lock);
    // printf("Releasing proc %d\n",indexInProc);
    release(&proc[indexInProc].stateLock);
    
  }
  else
  {
    // printf("Releasing \"%s\"\n",l->lock.name);
    release(&l->lock);

    // printf("list \"%s\" is not empty\n", l->lock.name);

    // printf("Acquiring the last proc of \"%s\"\n",l->lock.name);
    acquire(&proc[l->last].stateLock);
    // printf("Acquiring proc %d lock\n", indexInProc);
    acquire(&proc[indexInProc].stateLock);

    struct proc* last=&proc[l->last];
    struct proc* toAdd=&proc[indexInProc];

    last->next_index_in_list = indexInProc;
    toAdd->next_index_in_list = -1;
    l->last = toAdd->index_in_proc;

    // printf("Releasing the last proc of \"%s\"\n",l->lock.name);
    release(&last->stateLock);
    // printf("Releasing proc %d lock\n", indexInProc);
    release(&proc[indexInProc].stateLock);
  }
}

void remove_proc_from_list(list* l,int indexInProc){
  // printf("Removing proc %d from \"%s\"\n", indexInProc, l->lock.name);
  int prev=-1;
  int curr=-1;
  int next=-1;

  // printf("Acquiring \"%s\"\n",l->lock.name);
  acquire(&l->lock);

  //list size = 0
  if(l->first==-1)
  {
    // printf("Releasing \"%s\"\n",l->lock.name);
    release(&l->lock);
    panic("trying to delete from an empty list");
  }
  // printf("Releasing \"%s\"\n",l->lock.name);
  release(&l->lock);

  // printf("Acquiring proc %d lock\n", l->first);
  acquire(&proc[l->first].stateLock);  

  if(l->first == l->last)// if the size of list = 1
  {
    if(l->first == indexInProc)//if the only element is the index to remove
    {
      // printf("removing proc %d from list \"%s\" list.size=1 \n",indexInProc,l->lock.name);
      l->first = -1;
      l->last = -1;
      proc[indexInProc].next_index_in_list = -1;
      // printf("Releasing proc %d lock\n", indexInProc);
      release(&proc[indexInProc].stateLock);
      return; 
    }
    else
    {
      panic("The element does't exist in this list");
    }
  }

  else if(l->first == indexInProc)//trying to remove the first var when the size is bigger then 1
  {
    // printf("removing proc %d from list \"%s\", this proc is the first var\n",indexInProc,l->lock.name);
    l->first = proc[indexInProc].next_index_in_list;
    proc[indexInProc].next_index_in_list = -1;
    printf("Releasing proc %d lock\n", l->first);
    release(&proc[indexInProc].stateLock);
  }
  else// the list have at least two elements
  {
    prev = l->first;
    //First is allready acquired
    curr = proc[prev].next_index_in_list;
    printf("Acquiring proc %d lock\n", curr);
    acquire(&proc[curr].stateLock);
    next = proc[curr].next_index_in_list;

    while(indexInProc!=curr){
      // printf("Releasing proc %d lock\n", prev);
      release(&proc[prev].stateLock);
      // printf("Acquiring proc %d lock\n", next);
      acquire(&proc[next].stateLock);

      prev = curr;
      curr = next;
      next = proc[next].next_index_in_list;

      if(curr == -1)
        panic("The element does't exist in this list");
    }
    
    proc[prev].next_index_in_list = next;
    proc[indexInProc].next_index_in_list = -1;

    // printf("Releasing proc %d lock\n", curr);
    release(&proc[curr].stateLock);
    // printf("Releasing proc %d lock\n", prev);
    release(&proc[prev].stateLock);
  }
}

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

void initlists(){
  // printf("Initlists\n");
  unusedList.first=-1;
  unusedList.last=-1;
  initlock(&unusedList.lock,"unused list lock");

  zombieList.first=-1;
  zombieList.last=-1;
  initlock(&zombieList.lock,"zombie list lock");

  sleepingList.first=-1;
  sleepingList.last=-1;
  initlock(&sleepingList.lock,"sleeping list lock");

  for(int i=0;i<NCPU;i++){
    cpus[i].runnable.first=-1;
    cpus[i].runnable.last=-1;

    initlock(&cpus[i].runnable.lock, "cpu lock");
  }

}

// initialize the proc table at boot time.
void
procinit(void)
{
  struct proc *p;
  initlists();
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  int index = 0;
  // printf("initializing the proc table\n\n");
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
      p->kstack = KSTACK((int) (p - proc));
      p->cpu_num = 0;
      p->index_in_proc = index;
      // printf("Adding proc %d to the unused list\n", index);
      add_proc_to_list(&unusedList, p->index_in_proc);
      // printf("proc %d was added to unused list\n\n", index);
      index++;
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid() {
  int pid;
  // printf("Acquiring pid lock\n");
  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  // printf("Releasing pid lock\n");
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;
  // printf("Acquiring \"%s\"\n", unusedList.lock.name);
  acquire(&unusedList.lock);
  int firstUnused = unusedList.first;
  if(firstUnused >= 0)
  { 
    // printf("Releasing \"%s\"\n", unusedList.lock.name);
    p = &proc[firstUnused];
    acquire(&p->lock);
    release(&unusedList.lock);
    // printf("Acquiring proc %d lock\n", p->index_in_proc);
    goto found;
  }
  // printf("Releasing \"%s\"\n", unusedList.lock.name);
  release(&unusedList.lock);
  return 0;

found:
  p->pid = allocpid();
  remove_proc_from_list(&unusedList,firstUnused);
  p->state = USED;
  remove_proc_from_list(&unusedList,firstUnused);
  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    freeproc(p);
    // printf("Releasing proc %d lock\n", p->index_in_proc);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  printf("getttin into allocpage table of pron num %d",p->index_in_proc);
  p->pagetable = proc_pagetable(p);
  printf("page table is empty %d",p->pagetable==0);
  if(p->pagetable == 0){
    freeproc(p);
    // printf("Releasing proc %d lock\n", p->index_in_proc);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  // printf("Entering freeproc\n");
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;
  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
  remove_proc_from_list(&zombieList, p->index_in_proc);
  add_proc_to_list(&unusedList, p->index_in_proc);
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0){
    printf("page table is empty of proc num %d",p->index_in_proc);
    return 0;
  }

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe just below TRAMPOLINE, for trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  struct proc *p;
  // printf("Entering userinit\n");

  // printf("Allocating first user process\n");
  p = allocproc();
  // printf("initproc allocated successfully\n");
  initproc = p;
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;
  add_proc_to_list(&cpus[0].runnable, p->index_in_proc);

  release(&p->lock);
  // printf("Exiting userinit\n\n");
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();
  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }
  printf("forking from %d to child num %d",p->index_in_proc,np->index_in_proc);
  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  add_proc_to_list(&cpus[p->cpu_num].runnable, np->index_in_proc);
  release(&np->lock);
 
  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;
  // printf("Entering Reparent\n");
  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();
  // printf("Entring exit function\n");

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  add_proc_to_list(&zombieList, p->index_in_proc);
  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(np = proc; np < &proc[NPROC]; np++){
      if(np->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if(np->state == ZOMBIE){
          // Found one.
          pid = np->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                  sizeof(np->xstate)) < 0) {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || p->killed){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
  // printf("Entered scheduler\n");
  struct proc *p;
  struct cpu *c = mycpu();
  int firstRunnable = -1;
  c->proc = 0;
  for(;;){
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    printf("Acquring \"%s\"\n", c->runnable.lock.name);
    acquire(&c->runnable.lock);
    firstRunnable = c->runnable.first;
    if(firstRunnable >= 0) {
      printf("First runnable is %d\n", firstRunnable);
      p = &proc[firstRunnable];
      acquire(&p->lock);
      printf("Releasing \"%s\"\n", c->runnable.lock.name);
      release(&c->runnable.lock);
      // Switch to chosen process.  It is the process's job
      // to release its lock and then reacquire it
      // before jumping back to us.
      p->state = RUNNING;
      c->proc = p;
      // printf("cpu: %d\n", cpuid());
      remove_proc_from_list(&(c->runnable), p->index_in_proc);
      swtch(&c->context, &p->context);

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
      printf("Releasing proc %d lock\n", p->index_in_proc);
      release(&p->lock);
    }
    else{
      printf("Releasing \"%s\"\n", c->runnable.lock.name);
      release(&c->runnable.lock);
    }
    
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  add_proc_to_list(&cpus[p->cpu_num].runnable, p->index_in_proc);
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  add_proc_to_list(&sleepingList, p->index_in_proc);
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  struct proc *p;
  // printf("Entering wakeup\n");
  for(p = proc; p < &proc[NPROC]; p++) {
    if(p != myproc()){
      // printf("Acquiring proc %d lock\n", p->index_in_proc);
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
        p->state = RUNNABLE;
        remove_proc_from_list(&sleepingList, p->index_in_proc);
        add_proc_to_list(&cpus[0].runnable, p->index_in_proc);
      }
      // printf("Releasing proc %d lock\n", p->index_in_proc);
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}
