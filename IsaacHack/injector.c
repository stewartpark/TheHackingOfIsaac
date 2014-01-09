/**
 *  injector.c
 *  Programmed by Ju-yeong Park
 */
#define BINARY_VERSION 1

#include "mach_inject.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <mach/mach_init.h>
#include <mach/mach_vm.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <stdbool.h>

int replaceRemoteProcessMemory(pid_t pid, 
                void *data1, unsigned int size1, // To search
                void *data2, unsigned int size2  // Replacement
            ) {
    int result = 0;
#ifdef __APPLE__
    mach_port_name_t task;
    if(task_for_pid(mach_task_self(), pid, &task) != KERN_SUCCESS) {
        printf("task_for_pid() failed.\n");
        return -1;
    }
    vm_address_t iter;
    
    iter = 0;
    while (1) {
        vm_address_t addr = iter;
        vm_size_t size;
        vm_region_submap_info_data_64_t info;
        mach_msg_type_number_t info_count;
        unsigned int depth;
        kern_return_t kr;
    

        depth = 0;
        info_count = VM_REGION_SUBMAP_INFO_COUNT_64;
        kr = vm_region_recurse_64(task, &addr, &size, &depth, 
                                  (vm_region_info_t)&info, &info_count);
        if (kr) break;

        void *copied;
        mach_msg_type_number_t copied_size = 0;
        if(vm_read(task, addr, size, (vm_offset_t *)&copied, &copied_size) == KERN_SUCCESS) {
            char *ptr1 = (char*)copied;
            char *ptr2 = (char*)data1;
            char *ptr3 = (char*)data2;

            for(int i = 0; i < size-size1; i ++){
                bool isMatched = true;

                for(int j = 0; j < size1; j++){
                    if(*(ptr1+j) != *(ptr2+j) ){
                        isMatched = false;
                        break;
                    }
                }

                if(isMatched) {

                    printf("|  |___ Matched at 0x%llx\n", (long long)ptr1);
                    if(vm_write(task, addr+i, (vm_offset_t)ptr3, size2) != KERN_SUCCESS) {
                        printf("|  |___ Unable to write on the region\n");
                    }
                    result ++;
                }
                ptr1++;
            }
        } else { 
            //printf("|  |___ Unable to read the region\n");
        }
 
        iter = addr + size;
    }
    return result;
#else 
    #warning This platform is not supported.
    return -1;
#endif
}

int main(int argc, char** argv) {
    pid_t pid = atoi(argv[1]); 
    printf("[+] the Binding of Isaac Hack Binary V%d By Ju-yeong Park <interruptz@gmail.com>\n", BINARY_VERSION);
    printf("* this hack provides: Infinite item, Infinite health\n");
    printf("PID: %d\n", pid);

    // the Binding of Isaac hack

    // Infinite health
    int d11 = 0x4f0b0204;
    int d12 = 0x4f470204;
    
    int t1 = replaceRemoteProcessMemory(pid, &d11, sizeof(d11), &d12, sizeof(d12));
    if(t1 > 0) { printf("Successfully patched. (%d).\n", t1); }
    
    // Infinite Item 
    long long d21 = 0x0601da090204000e;
    long long d22 = 0x0701da090204000e;
   
    int t2 = replaceRemoteProcessMemory(pid, &d21, sizeof(d21), &d22, sizeof(d22));      if(t2 > 0) { printf("Successfully patched (%d).\n", t2); }
 
    return 0;

}
