//#include <stdio.h>
//#include <stdlib.h>
//#include <sys/types.h>
//#include <sys/ipc.h>
//#include <sys/sem.h>
//#include <unistd.h>
//
//void init_sem(int , int );
//void delete_sem(int );
//void sem_p(int );
//void sem_v(int );
//
//union semun
//{
//    int val;
//    struct semid_ds *buf;
//    unsigned short *array;
//};
//
//void init_sem(int sem_id, int init_value)
//{
//    union semun sem_union;
//
//    sem_union.val = init_value;
//
//    if (semctl(sem_id, 0, SETVAL, sem_union) < 0)
//    {
//        perror("failed to init_sem");
//        exit(-1);
//    }
//
//    return ;
//}
//
//void delete_sem(int sem_id)
//{
//    union semun sem_union;
//
//    if (semctl(sem_id, 0, IPC_RMID, sem_union) < 0)
//    {
//        perror("failed to delete_sem");
//        exit(-1);
//    }
//
//    return ;
//}
//
//void sem_p(int sem_id)
//{
//    struct sembuf sem_b;
//
//    sem_b.sem_num = 0;
//    sem_b.sem_op = -1;
//    sem_b.sem_flg = SEM_UNDO;
//
//    if (semop(sem_id, &sem_b, 1) < 0)
//    {
//        perror("failed to sem_p");
//        exit(-1);
//    }
//
//    return;
//}
//
//void sem_v(int sem_id)
//{
//    struct sembuf sem_b;
//
//    sem_b.sem_num = 0;
//    sem_b.sem_op = 1;
//    sem_b.sem_flg = SEM_UNDO;
//
//    if (semop(sem_id, &sem_b, 1) < 0)
//    {
//        perror("failed to sem_v");
//        exit(-1);
//    }
//
//    return ;
//}

//#include "sem.h"

#include<stdio.h>
#include<stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/sem.h>

union semun
{
    int val;
};

#define  SEM_NUM  2
static int semid = -1;
void sem_init()
{
    semid = semget((key_t)1234,SEM_NUM,IPC_CREAT|IPC_EXCL|0600);//全新创建
    if (semid == -1 )
    {
        semid = semget((key_t)1234,SEM_NUM,0600);
        if ( semid == -1)
        {
            printf("semget err\n");
            return;
        }
    }
    else
    {
        int arr[SEM_NUM] = {1,0};
        for( int i = 0; i < SEM_NUM; i++ )
        {
            union semun a;
            a.val = arr[i];
            if ( semctl(semid,i,SETVAL,a) == -1 )//全新创建成功，就初始化
            {
                printf("semctl err\n");
            }
        }
    }
}
void sem_p(int index)
{
    if ( index < 0 || index >= SEM_NUM )
    {
        return;
    }
    struct sembuf buf;
    buf.sem_num = index;
    buf.sem_op = -1;//p
    buf.sem_flg = SEM_UNDO;
    if ( semop(semid,&buf,1) == -1 )
    {
        printf("sem p err\n");
    }
}
void sem_v(int index)
{
    if ( index < 0 || index >= SEM_NUM )
    {
        return;
    }
    struct sembuf buf;
    buf.sem_num = index;
    buf.sem_op = 1;//v
    buf.sem_flg = SEM_UNDO;
    if ( semop(semid,&buf,1) == -1 )
    {
        printf("sem v err\n");
    }
}
void sem_destroy()
{
    if ( semctl(semid,0,IPC_RMID) == -1 )
    {
        printf("semctl del err\n");
    }
}
