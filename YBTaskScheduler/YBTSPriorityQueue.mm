//
//  YBTSPriorityQueue.m
//  YBTaskSchedulerDemo
//
//  Created by 杨波 on 2019/1/3.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBTSPriorityQueue.h"
#import <pthread.h>
#import <queue>
#import <vector>

using namespace std;

typedef pair<YBTaskBlock, NSInteger> YBTSPQTask;

struct YBTSPQCMP {
    bool operator()(YBTSPQTask a, YBTSPQTask b) {
        return a.second < b.second;
    }
};

@implementation YBTSPriorityQueue {
    priority_queue<YBTSPQTask, vector<YBTSPQTask>, YBTSPQCMP> _queue;
    pthread_mutex_t _lock;
}

@synthesize ybts_maxNumberOfTasks = _ybts_maxNumberOfTasks;

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_lock, &attr);
        pthread_mutexattr_destroy(&attr);
    }
    return self;
}

#pragma mark - <YBTaskSchedulerStrategyProtocol>

- (BOOL)ybts_empty {
    return _queue.empty();
}

- (void)ybts_addTask:(YBTaskBlock)task priority:(YBTaskPriority)priority {
    if (!task) return;
    
    pthread_mutex_lock(&_lock);
    _queue.push(make_pair(task, priority));
    pthread_mutex_unlock(&_lock);
}

- (void)ybts_executeTask {
    pthread_mutex_lock(&_lock);
    if (_queue.empty()) {
        pthread_mutex_unlock(&_lock);
        return;
    }
    YBTSPQTask pqTask = (YBTSPQTask)_queue.top();
    YBTaskBlock taskBlock = (YBTaskBlock)pqTask.first;
    _queue.pop();
    pthread_mutex_unlock(&_lock);
    
    taskBlock();
}

- (void)ybts_clearTasks {
    pthread_mutex_lock(&_lock);
    while (!_queue.empty()) {
        _queue.pop();
    }
    pthread_mutex_unlock(&_lock);
}


@end
