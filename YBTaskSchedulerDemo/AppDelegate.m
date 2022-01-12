//
//  AppDelegate.m
//  YBTaskSchedulerDemo
//
//  Created by 杨波 on 2019/1/3.
//  Copyright © 2019 杨波. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "YYFPSLabel.h"

static void configureUINavigationBarAppearance(void)
{
    NSDictionary *titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};
    UIColor *barTintColor = UIColor.whiteColor;
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        appearance.titleTextAttributes = titleTextAttributes;
        appearance.backgroundColor = barTintColor;
        
        [UINavigationBar appearance].standardAppearance = appearance;
        [UINavigationBar appearance].scrollEdgeAppearance = appearance;
    } else {
        [UINavigationBar appearance].titleTextAttributes = titleTextAttributes;
        [UINavigationBar appearance].barTintColor = barTintColor;
    }
    [UINavigationBar appearance].translucent = NO;
}

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    configureUINavigationBarAppearance();
    
    _window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    _window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[MainViewController new]];
    [_window makeKeyAndVisible];
  
//    YYFPSLabel *label = [[YYFPSLabel alloc] initWithFrame:CGRectMake(10, 44 + [UIApplication sharedApplication].statusBarFrame.size.height + 10, 0, 0)];
//    [_window addSubview:label];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
