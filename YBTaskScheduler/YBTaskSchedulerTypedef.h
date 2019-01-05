//
//  YBTaskSchedulerTypedef.h
//  YBTaskSchedulerDemo
//
//  Created by 杨波 on 2019/1/4.
//  Copyright © 2019 杨波. All rights reserved.
//

#ifndef YBTaskSchedulerTypedef_h
#define YBTaskSchedulerTypedef_h

typedef NS_ENUM(NSInteger, YBTaskSchedulerStrategy) {
    YBTaskSchedulerStrategyLIFO,    //后进先出（后进任务优先级高）
    YBTaskSchedulerStrategyFIFO,    //先进先出（先进任务优先级高）
    YBTaskSchedulerStrategyPriority   //优先级调度（自定义任务的优先级）
};

typedef NSInteger YBTaskPriority;
static const YBTaskPriority YBTaskPriorityHigh = 750;
static const YBTaskPriority YBTaskPriorityDefault = 500;
static const YBTaskPriority YBTaskPriorityLow = 250;

typedef void(^YBTaskBlock)(void);

#endif /* YBTaskSchedulerTypedef_h */
