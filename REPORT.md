# Assignment 4 : Enhancing XV-6

# **Operating Systems and Networks, Monsoon 2022**

---

xv6 is a simplified operating system developed at MIT. Its main purpose is to explain the main concepts of the operating system by studying an example kernel. xv6 is a re- implementation of Dennis Ritchie's and Ken Thompson's Unix version 6 (v6). xv6 loosely follows the structure and style of v6, but is implemented for a modern RISC-V multiprocessor using ANSI C.

---

### Team:

1. **Nipun Tulsian (2021101055)**
2. **Vyom Goyal    (2021101099)**

---

## System calls and their Implementation:

---

### System call 1 : trace

Added the system call trace and an accompanying user program strace . The
command will be executed as follows :

strace mask command [args]

strace runs the specified command until it exits.

It intercepts and records the system calls which are called by a process during its
execution and print the following details regarding system call:

1. The process id
2. The name of the system call
3. The decimal value of the arguments
4. The return value of the syscall.

**Implementation:**

1. Added a new variable trace_mask in struct proc in kernel/proc.h and initialised it to 0 in allocproc() in kernel/proc.c and making sure that child process inherits the mask value from parent process.
2. Added a user function strace.c in user and added entry(”trace”) in user/usys.pl
    
    ![Screenshot 2022-10-13 at 12.10.42 AM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-13_at_12.10.42_AM.png)
    
3. Made necessary changes kernel/syscall.c, kernel/syscall.h and changed certain part of syscall() so that system call which we want to trace is traced :
    
    ![Screenshot 2022-10-13 at 12.15.53 AM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-13_at_12.15.53_AM.png)
    
4. Implemented a function sys_trace() in kernel/sysproc.c to set trace_mask value given by user

![Screenshot 2022-10-13 at 12.18.28 AM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-13_at_12.18.28_AM.png)

---

### System Call 2 : sigalarm and sigreturn :

A feature that periodically alerts a process as it uses CPU time

Added a new sigalarm(interval, handler) system call. If an application
calls alarm(n, fn) , then after every n "ticks" of CPU time that the program consumes,
the kernel will cause application function fn to be called. When fn returns, the
application will resume where it left off.

Added another system call sigreturn() , to reset the process state to before the handler was called.

**Implementation:**

1. Added new variables in ticks, ticks_after, alarm in struct proc in kernel/proc.h and initialised them to 0 in allocproc() in kernel/proc.c.
2. Implemented a function sys_sigreturn() and sys_sigalarm() in kernel/sysproc.c
    
    ![Screenshot 2022-10-13 at 1.09.34 AM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-13_at_1.09.34_AM.png)
    
3. Changing values of ticks and ticks_after in usertrap() in kernel/trap.c and changing alarm variable in proc to 0 and reset it to 1 in sigreturn because incase of handler function runs for more time than ticks after which handler should be ran:

![Screenshot 2022-10-13 at 1.27.53 AM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-13_at_1.27.53_AM.png)

---

## **Scheduling Types and implementation**

(By default **Round Robin** is implemented in xv6 with time slice of 1 tick)

---

### 1. FCFS ( First Come First Service ) :

---

A policy that selects the process with the lowest creation time (creation time refers to the tick number when the process was created). The process will run until it no longer needs CPU time.

1. Added a variable intime in struct proc in kernel/proc.h
2. Initialised intime variable to ticks in allocproc() function in  kernel/proc.c 
3. Implemented scheduling functionality in scheduler() function in kernel/proc.c, where the runnable process of lowest intime is selected from all processes.
4.  Used pre-processor directives to declare the alternate scheduling policy in
scheduler() in kernel/proc.c.
5. yield() function in  kerneltrap() and usertrap() functions in kernel/trap.c is disabled to disable timer interrupts thus disabling preemption.

![Screenshot 2022-10-11 at 4.05.34 AM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-11_at_4.05.34_AM.png)

---

### 2. Lottery Based Scheduler (LBS) :

---

A preemptive schedule that assigns a time slice to the process randomly in proportion to the number of tickets it owns. That is the probability that the process runs in a given time slice is proportional to the number of tickets owned by it.

1. Implemented a new system call settickets , which sets the number of tickets of calling process. By default each process should get 1 ticket , calling this routine changes the number of tickets . Also the child process inherits the number of tickets from parent process.
2. Added a new variables tickets in struct proc in kernel/proc.h
3. Initialised tickets to 1 in allocproc() in kernel/proc.c and made a function sys_settickets() in kernel/sysproc.c
4. Declared a global variable totaltickets in kernel/proc.c and initialised it to 0 in initproc() in kernel/proc.c and adding tickets of process when it’s state is changing is to **RUNNABLE** and subtracting it when it’s state is changing to **RUNNING**
5. Implemented scheduling functionality in scheduler() function in kernel/proc.c . We call a rand function which selects a golden ticket between 1 and total tickets of runnable process and from this ticket we choose which process range ticket this ticket belong to.

![Screenshot 2022-10-14 at 4.05.38 PM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-14_at_4.05.38_PM.png)

---

## 3. Priority Based Scheduler (PBS):

---

A non-preemptive priority-based schedules that selects the process with the highest priority for execution. In case two or more processes have the same priority, we use the number of times the process has been scheduled to break the tie. If the tie remains, use the start-time of the process to break the tie(processes with lower start times should be scheduled further)

1. Made a new system call set_priority() and added sys_set_priority() function in kernel/sysproc.c which reschedules the processes if priority of processes increases.
2. Added a new user program setpriority.c in user
3. Added variables priority, runtime , waittime, nsched in struct proc in kernel/proc.h
4. Initialised priority to 60 and runtime, waittime, nsched to 0 in allocproc() in kernel/proc.c
5. yield() function in  kerneltrap() and usertrap() functions in kernel/trap.c is disabled to disable timer interrupts thus disabling preemption.
6. Implemented scheduling functionality in scheduler() function in kernel/proc.c, where the runnable process according to algorithm is chose.
7. Used pre-processor directives to declare the alternate scheduling policy in
scheduler() in kernel/proc.c. 

![Screenshot 2022-10-11 at 5.02.02 AM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-11_at_5.02.02_AM.png)

1. To calculate dynamic priority of process in kernel/proc.c

![Screenshot 2022-10-11 at 4.58.34 AM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-11_at_4.58.34_AM.png)

---

## 4. Multilevel Feedback Queue (MLFQ):

---

A simplified preemptive MLFQ scheduler that allows processes to move between different priority queues based on their behaviour and CPU bursts.

- If a process uses too much CPU time, it is pushed to a lower priority queue, leaving I/O bound and interactive processes in the higher priority queues.
- To prevent starvation, aging is implemented.

Implementation:

1. In MLFQ implementation we store new arguments in the struct proc that are queue_level, tick_ctr and last_exec.
- Queue_level argument stores the priority queue number
- tick_ctr is used for storing runtime of the process to be used in preemption
- last_exec is used to calculate wait time used in implementing ageing.
1. Also the argument in_time is used in calculating the position in the queue, that is the process with lower in_time is scheduled first and whenever we upgrade or degrade the queue we again set it to the present value of variable ticks.
2. In the scheduler function we select the process that has min queue level and min in time among all processes with that same queue level.
3. In the timer trap we increment the tick_ctr for the currently running process and check if its time slice has been completed. If so it is preempted by calling the yield function.
4. Also if any process reaches the defined wait_time it is upgraded in the queue and if it has a queue_level less than the running process we preempt.
5. Now to implement the point wherein the process voluntarily relinquishes control of the CPU, we update its in_time in the queue when the process wakes up using the wakeup function.
6. Below is the snippet of code that we implemented in scheduler() in kernel/proc.c
    
    ![Screenshot 2022-10-13 at 1.34.34 AM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-13_at_1.34.34_AM.png)
    
7. Below is snippet of code that we implemented in usertrap() and kerneltrap() in kernel/trap.c  to handle timer interrupt.

![Screenshot 2022-10-13 at 1.37.57 AM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-13_at_1.37.57_AM.png)

---

## Copy - On - Write fork :

In this version of xv6 is using RISCV-39 CPU’s. In these CPU’s the virtual address of the memory location is of 39 bits and rest 25 bits are waste bits. Whenever memory allocation is requested, a memory block of 4096 bytes is allocated to the process and this unit is called a page. This page has a virtual address which is stored in process pagetable in the form of a page table entry. Their are certain flags for each page which denote the permissions that have been granted for the access of that page.

For eg. PTE_V tells us if a page is valid or not, PTE_W tells about write permission etc.

In this specification , when fork is called, it calls the function uvmcopy() of kernel/proc.c to generate the exact copy of parent memory block for child. We change this function so that a copy is not generated and the pages are the pages used by parent are shared. Now to ensure concurrency and prevent faults, we disable writing to this page.

Whenever a write operation is performed on such a page, we detect the trap in kernel/trap.c by using r_scause()==15 which indicates store page fault and create a copy of the page where this process can write by enabling write in new page. The other page remains read only and is deallocated if the number of processes using it become 0. This happens in write_trap function of file kernel/trap.c .

![Screenshot 2022-10-13 at 4.44.46 PM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-13_at_4.44.46_PM.png)

![Screenshot 2022-10-13 at 4.44.17 PM.png](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/Screenshot_2022-10-13_at_4.44.17_PM.png)

---

## Comparison Between different scheduling mechanism

---

| Scheduler | Avg. Running time | Avg. Waiting time |
| --- | --- | --- |
| Round Robin (default) | 13 | 152 |
| FCFS | 25 | 112 |
| LBS | 13 | 145 |
| PBS | 13 | 125 |
| MLFQ | 12 | 150 |

The above running time and scheduling time are calculated by running user/schedulertest.c on 1 CPU.

---

## MLFQ Scheduling Analysis

---

Timeline graphs for processes that are being managed by MLFQ Scheduler with ageing time of 30 ticks.

![MLFQ.jpg](Assignment%204%20Enhancing%20XV-6%201a691e18ee604c84afcf30fd594b7031/MLFQ.jpg)

---