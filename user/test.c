#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"






void example_pause_system(int interval, int pause_seconds, int loop_size) {
    int n_forks = 2;
    for (int i = 0; i < n_forks; i++) {
    	fork();
    }
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0) {
            fprintf(2, "pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == (int)(loop_size / 2)){
            pause_system(pause_seconds);
        }
    }
    fprintf(2, "\n");
}

void example_kill_system(int interval, int loop_size) {
    int n_forks = 2;
    for (int i = 0; i < n_forks; i++) {
    	fork();
    }
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0) {
            fprintf(2, "kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == (int)(loop_size / 2)){
            kill_system();
        }
    }
    fprintf(2, "\n");
}


int main(void){
    //example_kill_system(2, 10);
    example_pause_system(2, 2, 10);

    return 0;
}