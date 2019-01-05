//
//  MainViewController.m
//  YBPerformanceOptimizationDemo
//
//  Created by 杨波 on 2018/12/20.
//  Copyright © 2018 杨波. All rights reserved.
//

#import "MainViewController.h"
#import "PhotoAlbumViewController.h"

@interface MainViewController ()
@end

@implementation MainViewController

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
