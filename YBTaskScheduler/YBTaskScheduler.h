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

/**
 初始化方法

 @param strategy 调度策略
 @return instancetype
 */
- (instancetype)initWithStrategy:(YBTaskSchedulerStrategy)strategy;

/**
 快速构造方法

 @param strategy 调度策略
 @return instancetype
 */
+ (instancetype)schedulerWithStrategy:(YBTaskSchedulerStrategy)strategy;

/* 执行任务的线程队列（若不指定，任务会并行执行） */
@property (nullable, nonatomic, strong) dispatch_queue_t taskQueue;

/* 最大持有任务数量（调度策略为 YBTaskSchedulerStrategyPriority 时无效） */
@property (nonatomic, assign) NSUInteger maxNumberOfTasks;

/* 每次执行的任务数量 */
@property (nonatomic, assign) NSUInteger executeNumber;

/* 执行频率（RunLoop 循环 executeFrequency 次执行一次任务） */
@property (nonatomic, assign) NSUInteger executeFrequency;

/**
 添加任务

 @param task 包裹任务的 block
 */
- (void)addTask:(YBTaskBlock)task;

/**
 添加带优先级的任务（优先级仅在调度策略为 YBTaskSchedulerStrategyPriority 时有效）

 @param task 包裹任务的 block
 @param priority 优先级
 */
- (void)addTask:(YBTaskBlock)task priority:(YBTaskPriority)priority;

/**
 清空所有任务
 */
- (void)clearTasks;


- (instancetype)init OBJC_UNAVAILABLE("use '-initWithStrategy:' or '+schedulerWithStrategy:' instead");
+ (instancetype)new OBJC_UNAVAILABLE("use '-initWithStrategy:' or '+schedulerWithStrategy:' instead");

@end

NS_ASSUME_NONNULL_END
