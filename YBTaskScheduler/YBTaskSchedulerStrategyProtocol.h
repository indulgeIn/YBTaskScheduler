//
//  YBTaskSchedulerStrategyProtocol.h
//  YBTaskSchedulerDemo
//
//  Created by 杨波 on 2019/1/3.
//  Copyright © 2019 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YBTaskSchedulerTypedef.h"

NS_ASSUME_NONNULL_BEGIN

@protocol YBTaskSchedulerStrategyProtocol <NSObject>

@required

- (void)ybts_addTask:(YBTaskBlock)task priority:(YBTaskPriority)priority;

- (void)ybts_executeTask;

- (void)ybts_clearTasks;

- (BOOL)ybts_empty;

@optional

@property (nonatomic, assign) NSUInteger ybts_maxNumberOfTasks;

@end

NS_ASSUME_NONNULL_END
