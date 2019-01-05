//
//  YBTSQueue.m
//  YBTaskSchedulerDemo
//
//  Created by 杨波 on 2019/1/3.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBTSQueue.h"
#import <pthread.h>
#include <deque>

using namespace std;

@implementation YBTSQueue {
    deque<YBTaskBlock> _deque;
    pthread_mutex_t _lock;
}

@synthesize ybts_maxNumberOfTasks = _ybts_maxNumberOfTasks;

#pragma mark - life cycle

- (void)dealloc {
    [self clearTasks];
    pthread_mutex_destroy(&_lock);
}

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

#pragma mark - private

- (void)clearTasks {
    pthread_mutex_lock(&_lock);
    _deque.clear();
    pthread_mutex_unlock(&_lock);
}

#pragma mark - <YBTaskSchedulerStrategyProtocol>

- (BOOL)ybts_empty {
    return _deque.empty();
}

- (void)ybts_addTask:(YBTaskBlock)task priority:(YBTaskPriority)priority {
    if (!task) return;
    
    pthread_mutex_lock(&_lock);
    _deque.push_front(task);
    if (self.ybts_maxNumberOfTasks > 0) {
        while (_deque.size() > self.ybts_maxNumberOfTasks) {
            _deque.pop_front();
        }
    }
    pthread_mutex_unlock(&_lock);
}

- (void)ybts_executeTask {
    pthread_mutex_lock(&_lock);
    if (_deque.empty()) {
        pthread_mutex_unlock(&_lock);
        return;
    }
    YBTaskBlock taskBlock = (YBTaskBlock)_deque.back();
    _deque.pop_back();
    pthread_mutex_unlock(&_lock);
    
    taskBlock();
}

- (void)ybts_clearTasks {
    [self clearTasks];
}

@end
