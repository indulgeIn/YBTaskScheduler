//
//  MainViewController.m
//  YBPerformanceOptimizationDemo
//
//  Created by 杨波 on 2018/12/20.
//  Copyright © 2018 杨波. All rights reserved.
//

#import "MainViewController.h"
#import "PhotoAlbumViewController.h"
#import "YBTaskScheduler.h"

@interface MainViewController ()
@end

@implementation MainViewController {
    YBTaskScheduler *_scheduler;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSArray *textArr = @[@"相册"];
    for (int i = 0; i < textArr.count; ++i) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:30];
        [button setTitle:textArr[i] forState:UIControlStateNormal];
        button.bounds = CGRectMake(0, 0, button.intrinsicContentSize.width, button.intrinsicContentSize.height);
        button.center = CGPointMake(self.view.center.x, 120 + i * 40);
        [button addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = i;
        [self.view addSubview:button];
    }
    
    _scheduler = [YBTaskScheduler schedulerWithStrategy:YBTaskSchedulerStrategyPriority];
    _scheduler.taskQueue = dispatch_get_main_queue();
    _scheduler.maxNumberOfTasks = 2;
    
    for (int i = 0; i < 5; ++i) {
        [_scheduler addTask:^{
            usleep(1000 * 1000 * 0.5);
            NSLog(@"任务%d完成", i);
        } priority:YBTaskPriorityHigh];
    }
}

- (void)clickButton:(UIButton *)button {
    switch (button.tag) {
        case 0: {
            PhotoAlbumViewController *vc = [PhotoAlbumViewController new];
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        default:
            break;
    }
}

@end
