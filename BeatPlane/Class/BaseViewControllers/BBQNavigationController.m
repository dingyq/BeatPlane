//
//  BBQNavigationController.m
//  BeatPlane
//
//  Created by bigqiang on 15/7/23.
//  Copyright (c) 2015年 barbecue. All rights reserved.
//

#import "BBQNavigationController.h"

@interface BBQNavigationController ()

@end

@implementation BBQNavigationController

- (void)viewDidLoad
{
    __unsafe_unretained BBQNavigationController *weakSelf = self;
    self.delegate = weakSelf;
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)])
    {
        self.interactivePopGestureRecognizer.delegate = weakSelf;
    }
}

// Hijack the push method to disable the gesture

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)])
        self.interactivePopGestureRecognizer.enabled = NO;
    
    [super pushViewController:viewController animated:animated];
    
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    //动画时对事件接受屏蔽
    if (animated == YES) {
        //        NSLog(@"navigation: %@ c++",self);
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    }
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animate
{
    
    //动画时对事件接受
    if (animate == YES) {
        //        NSLog(@"navigation: %@ c--",self);
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
    // Enable the gesture again once the new controller is shown
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)])
        self.interactivePopGestureRecognizer.enabled = YES;
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if (self.viewControllers.count==1) {
        return NO;
    }
    return YES;
}

@end
