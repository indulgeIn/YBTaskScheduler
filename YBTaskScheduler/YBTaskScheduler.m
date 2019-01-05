//
//  YBTaskScheduler.m
//  YBTaskSchedulerDemo
//
//  Created by 杨波 on 2019/1/3.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "YBTaskScheduler.h"
#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>
#import <pthread.h>
#import "YBTSStack.h"
#import "YBTSQueue.h"
#import "YBTSPriorityQueue.h"
#import "YBTaskScheduler+Internal.h"


static dispatch_queue_t defaultConcurrentQueue() {
#define MAX_QUEUE_COUNT 16
    static int queueCount;
    static dispatch_queue_t queues[MAX_QUEUE_COUNT];
    static dispatch_once_t onceToken;
    static int32_t counter = 0;
    dispatch_once(&onceToken, ^{
        queueCount = (int)[NSProcessInfo processInfo].activeProcessorCount;
        queueCount = queueCount < 8 ? 8 : queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount;
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
            for (NSUInteger i = 0; i < queueCount; i++) {
                dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT+1, 0);
                queues[i] = dispatch_queue_create("com.yb.taskScheduler", attr);
            }
        } else {
            for (NSUInteger i = 0; i < queueCount; i++) {
                queues[i] = dispatch_queue_create("com.yb.taskScheduler", DISPATCH_QUEUE_SERIAL);
                dispatch_set_target_queue(queues[i], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
            }
        }
    });
    uint32_t cur = (uint32_t)OSAtomicIncrement32(&counter);
    return queues[(cur) % queueCount];
#undef MAX_QUEUE_COUNT
}


static NSHashTable *taskSchedulers;

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    for (YBTaskScheduler *scheduler in taskSchedulers.allObjects) {
        [scheduler executeTasks];
    }
}

static void addRunLoopObserver() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        taskSchedulers = [NSHashTable weakObjectsHashTable];
        CFRunLoopObserverRef observer = CFRunLoopObserverCreate(CFAllocatorGetDefault(), kCFRunLoopBeforeWaiting | kCFRunLoopExit, true, 0xFFFFFF, runLoopObserverCallBack, NULL);
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
        CFRelease(observer);
    });
}


static CADisplayLink *displayLink;
static int32_t displayLinkCounter = 0;
static pthread_mutex_t displayLinkLock;

static void addDisplayLink() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        displayLink = [CADisplayLink displayLinkWithTarget:YBTaskScheduler.self selector:@selector(hash)];
        pthread_mutex_init(&displayLinkLock, NULL);
    });
    int32_t counter = OSAtomicIncrement32(&displayLinkCounter);
    if (counter >= 1) {
        pthread_mutex_lock(&displayLinkLock);
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        pthread_mutex_unlock(&displayLinkLock);
    }
}

static void removeDisplayLink() {
    int32_t counter = OSAtomicDecrement32(&displayLinkCounter);
    if (counter <= 0) {
        pthread_mutex_lock(&displayLinkLock);
        if (displayLink) {
            [displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        }
        pthread_mutex_unlock(&displayLinkLock);
    }
}


@implementation YBTaskScheduler {
    id<YBTaskSchedulerStrategyProtocol> _strategy;
}

#pragma mark - life cycle

- (void)dealloc {
    NSLog(@"释放：%@", self);
    removeDisplayLink();
}

- (instancetype)initWithStrategy:(YBTaskSchedulerStrategy)strategy {
    self = [super init];
    if (self) {
        addDisplayLink();
        addRunLoopObserver();
        self.numberOfExecuteEachTime = 1;
        self.maxNumberOfTasks = NSUIntegerMax;
        switch (strategy) {
            case YBTaskSchedulerStrategyLIFO:
                _strategy = [YBTSStack new];
                break;
            case YBTaskSchedulerStrategyFIFO:
                _strategy = [YBTSQueue new];
                break;
            case YBTaskSchedulerStrategyPriority:
                _strategy = [YBTSPriorityQueue new];
                break;
        }
        [taskSchedulers addObject:self];
    }
    return self;
}

+ (instancetype)schedulerWithStrategy:(YBTaskSchedulerStrategy)strategy {
    return [[YBTaskScheduler alloc] initWithStrategy:strategy];
}

#pragma mark - public

- (void)addTask:(YBTaskBlock)task {
    if (!task) return;
    [_strategy ybts_addTask:task priority:YBTaskPriorityDefault];
}

- (void)addTask:(YBTaskBlock)task priority:(YBTaskPriority)priority {
    [_strategy ybts_addTask:task priority:priority];
}

- (void)clearTasks {
    [_strategy ybts_clearTasks];
}

#pragma mark - internal

- (void)executeTasks {
    if (_strategy.ybts_empty) return;
        
    dispatch_block_t taskBlock = ^{
        [self->_strategy ybts_executeTask];
    };
    
    BOOL needSwitchQueue = !self.taskQueue || strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(self.taskQueue)) != 0;
    void(^executeBlock)(void) = needSwitchQueue ? ^{
        dispatch_async(self.taskQueue ?: defaultConcurrentQueue(), taskBlock);
    } : ^{
        taskBlock();
    };
    
    for (NSUInteger i = 0; i < self.numberOfExecuteEachTime; ++i) {
        executeBlock();
    }
}

#pragma mark - getter & setter

- (void)setMaxNumberOfTasks:(NSUInteger)maxNumberOfTasks {
    _maxNumberOfTasks = maxNumberOfTasks;
    _strategy.ybts_maxNumberOfTasks = maxNumberOfTasks;
}

@end
