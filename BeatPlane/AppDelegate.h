//
//  AppDelegate.h
//  BeatPlane
//
//  Created by bigqiang on 15/7/23.
//  Copyright (c) 2015年 barbecue. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MyBBQViewController;
@class SettingViewController;


@interface AppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    NSMutableDictionary* _tabMap; //保存VC在哪个tab中
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) MyBBQViewController *bbqViewController;
@property (strong, nonatomic) SettingViewController *settingViewController;
//@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) UITabBarController *tabBarViewController;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

