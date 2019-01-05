//
//  YBTaskScheduler.h
//  YBTaskSchedulerDemo
//
//  Created by 杨波 on 2019/1/3.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YBTaskSchedulerTypedef.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBTaskScheduler : NSObject

- (instancetype)initWithStrategy:(YBTaskSchedulerStrategy)strategy;
+ (instancetype)schedulerWithStrategy:(YBTaskSchedulerStrategy)strategy;

/* 每次循环周期执行的任务数量 */
@property (nonatomic, assign) NSUInteger numberOfExecuteEachTime;

/* 执行任务的线程队列 */
@property (nullable, nonatomic, strong) dispatch_queue_t taskQueue;

/* 最大持有任务数量 */
@property (nonatomic, assign) NSUInteger maxNumberOfTasks;

/**
 添加任务

 @param task 包裹任务的 block
 */
- (void)addTask:(YBTaskBlock)task;

/**
 添加带优先级的任务（仅调度策略为 YBTaskSchedulerStrategyPriority 时有效）

 @param task 包裹任务的 block
 @param priority 优先级
 */
- (void)addTask:(YBTaskBlock)task priority:(YBTaskPriority)priority;;

/**
 清空所有任务
 */
- (void)clearTasks;


- (instancetype)init OBJC_UNAVAILABLE("use '-initWithStrategy:' or '+schedulerWithStrategy:' instead");
+ (instancetype)new OBJC_UNAVAILABLE("use '-initWithStrategy:' or '+schedulerWithStrategy:' instead");

@end

NS_ASSUME_NONNULL_END
