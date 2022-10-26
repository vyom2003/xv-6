#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    if (argc < 3)
    {
        fprintf(2, "strace : strace mask command [args]\n");
        exit(1);
    }
    int mask = atoi(argv[1]);
    trace(mask);
    if (exec(argv[2], &argv[2]) == -1)
    {
        fprintf(2, "exec %s failed\n", argv[2]);
    }
    exit(0);
}