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


static dispatch_queue_t YBTSDefaultConcurrentQueue() {
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
                dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
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
    
    // queueCount 要么是 2^3，要么是 2^4
    return queues[cur & (queueCount - 1)];
#undef MAX_QUEUE_COUNT
}

static NSHashTable *YBTaskSchedulers(void) {
    static NSHashTable *schedulers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        schedulers = [NSHashTable weakObjectsHashTable];
    });
    return schedulers;
}

static CADisplayLink *YBTSDisplayLink(void) {
    static CADisplayLink *displayLink = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        displayLink = [CADisplayLink displayLinkWithTarget:YBTaskScheduler.self selector:@selector(hash)];
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    });
    return displayLink;
}

static void YBTSRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    BOOL keepActive = NO;
    for (YBTaskScheduler *scheduler in YBTaskSchedulers().allObjects) {
        if (!scheduler.empty) {
            keepActive = YES;
            [scheduler executeTasks];
        }
    }
    if (YBTSDisplayLink().paused == keepActive) {
        YBTSDisplayLink().paused = !keepActive;
    }
}

static void YBTSAddRunLoopObserver() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFRunLoopObserverRef observer = CFRunLoopObserverCreate(CFAllocatorGetDefault(), kCFRunLoopBeforeWaiting | kCFRunLoopExit, true, 0xFFFFFF, YBTSRunLoopObserverCallBack, NULL);
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
        CFRelease(observer);
    });
}


@implementation YBTaskScheduler {
    id<YBTaskSchedulerStrategyProtocol> _strategy;
    NSUInteger _frequencyCounter;
}

#pragma mark - life cycle

- (instancetype)initWithStrategyObject:(id<YBTaskSchedulerStrategyProtocol>)strategyObject {
    self = [super init];
    if (self) {
        YBTSAddRunLoopObserver();
        self.executeNumber = 1;
        self.maxNumberOfTasks = NSUIntegerMax;
        self.executeFrequency = 1;
        _strategy = strategyObject;
        [YBTaskSchedulers() addObject:self];
    }
    return self;
}

- (instancetype)initWithStrategy:(YBTaskSchedulerStrategy)strategy {
    id<YBTaskSchedulerStrategyProtocol> strategyObject;
    switch (strategy) {
        case YBTaskSchedulerStrategyLIFO:
            strategyObject = [YBTSStack new];
            break;
        case YBTaskSchedulerStrategyFIFO:
            strategyObject = [YBTSQueue new];
            break;
        case YBTaskSchedulerStrategyPriority:
            strategyObject = [YBTSPriorityQueue new];
            break;
    }
    return [self initWithStrategyObject:strategyObject];
}

+ (instancetype)schedulerWithStrategy:(YBTaskSchedulerStrategy)strategy {
    return [[YBTaskScheduler alloc] initWithStrategy:strategy];
}

#pragma mark - public

- (void)addTask:(YBTaskBlock)task {
    [self addTask:task priority:YBTaskPriorityDefault];
}

- (void)addTask:(YBTaskBlock)task priority:(YBTaskPriority)priority {
    if (!task) return;
    [_strategy ybts_addTask:task priority:priority];
    YBTSDisplayLink().paused = NO;
}

- (void)clearTasks {
    [_strategy ybts_clearTasks];
}

#pragma mark - internal

- (BOOL)empty {
    return _strategy.ybts_empty;
}

- (void)executeTasks {
    if (_frequencyCounter != self.executeFrequency) {
        ++_frequencyCounter;
        return;
    } else {
        _frequencyCounter = 1;
    }
    if (_strategy.ybts_empty) return;
        
    dispatch_block_t taskBlock = ^{
        [self->_strategy ybts_executeTask];
    };
    
    BOOL needSwitchQueue = !self.taskQueue || strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(self.taskQueue)) != 0;
    void(^executeBlock)(void) = needSwitchQueue ? ^{
        dispatch_async(self.taskQueue ?: YBTSDefaultConcurrentQueue(), taskBlock);
    } : taskBlock;
    
    for (NSUInteger i = 0; i < self.executeNumber; ++i) {
        executeBlock();
    }
}

#pragma mark - setter

- (void)setMaxNumberOfTasks:(NSUInteger)maxNumberOfTasks {
    _maxNumberOfTasks = maxNumberOfTasks;
    if ([_strategy respondsToSelector:@selector(setYbts_maxNumberOfTasks:)]) {
        _strategy.ybts_maxNumberOfTasks = maxNumberOfTasks;
    }
}

- (void)setExecuteFrequency:(NSUInteger)executeFrequency {
    _executeFrequency = executeFrequency;
    _frequencyCounter = executeFrequency;
}

@end
