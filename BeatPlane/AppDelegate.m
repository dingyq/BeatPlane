//
//  AppDelegate.m
//  BeatPlane
//
//  Created by bigqiang on 15/7/23.
//  Copyright (c) 2015年 barbecue. All rights reserved.
//

#import "AppDelegate.h"
#import "BBQNavigationController.h"
#import "MyBBQViewController.h"
#import "SettingViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
@synthesize window = _window;
@synthesize bbqViewController = _bbqViewController;
@synthesize settingViewController = _settingViewController;
@synthesize tabBarViewController = _tabBarViewController;

#pragma mark - life cycle
-(void) dealloc {
    self.window = nil;
    self.bbqViewController = nil;
    self.settingViewController = nil;
    self.tabBarViewController = nil;
    
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UITabBarController *tmpTabController = [[UITabBarController alloc] init];
    self.tabBarViewController = tmpTabController;
    [tmpTabController release];
    self.tabBarViewController.delegate = self;
    application.statusBarStyle = UIStatusBarStyleLightContent;
    
    self.window.rootViewController = self.tabBarViewController;

//    MyBBQViewController *tmpBbqViewController = [[MyBBQViewController alloc] init];
//    self.bbqViewController = tmpBbqViewController;
//    [tmpBbqViewController release];
//    
//    SettingViewController *tmpSettingViewController = [[SettingViewController alloc] init];
//    self.settingViewController = tmpSettingViewController;
//    [tmpSettingViewController release];
    _tabMap = [[NSMutableDictionary alloc] init];
    [self configTabControllers];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - private methods

- (NSArray*) getTabConfiguration {
    NSArray* conf = nil;
    conf = @[@{@"class":@"MyBBQViewController", @"imageNor":@"home_loty_normal.png", @"imageSelect":@"home_loty_selected.png", @"title":@"烤肉大厅", @"associate":@"bbqViewController"}
             ,@{@"class":@"SettingViewController", @"imageNor":@"home_myloty_normal.png", @"imageSelect":@"home_myloty_selected.png", @"title":@"设置", @"associate":@"settingViewController"}];
    return conf;
}

//配置tab Controller中的每个页面
- (void) configTabControllers {
    NSMutableArray *vcs = [[NSMutableArray alloc] init];
    NSArray *conf = [self getTabConfiguration];
    int idx = 0;
    NSArray* org_vcs = [self.tabBarViewController viewControllers];
    
    for (NSDictionary* dict in conf) {
        NSString* klassName = [dict objectForKey:@"class"];
        NSString* titleName = [dict objectForKey:@"title"];
        NSString* imageName = [dict objectForKey:@"imageNor"];
//        NSString* imageSelName = [dict objectForKey:@"imageSelect"];
        Class klass = NSClassFromString(klassName);
        
        if (klass == NULL) {
            idx = (idx == 0) ? 0 : idx - 1;
            continue;
        }
        
        //先从原来的vcs中获取，看看是否有已经就续的同类vc
        BOOL found = NO;
//        int org_counts = [org_vcs count];
        NSInteger org_counts = [org_vcs count];
        UIViewController* org_vc = nil;
        for (int i = 0; i < org_counts; i++) {
            org_vc = [org_vcs objectAtIndex:i];
            BOOL exg = NO;
            if ([org_vc isKindOfClass:[UINavigationController class]]) {
                org_vc = [[(UINavigationController*)org_vc viewControllers] objectAtIndex:0];
                exg = YES;
            }
            if ([org_vc isKindOfClass:klass]) {
                if(exg) {
                    org_vc = org_vc.navigationController;
                }
                found = YES;
                break;
            }
        }
        
        if (found) { //found
            [vcs addObject:org_vc];
        }else{
            UIViewController* vc = [[klass alloc] init];
            
            //config the vc if the config block exist
//            void (^vc_config_block)(UIViewController* controller) = [dict objectForKey:@"config_block"];
//            if (vc_config_block != nil) {
//                vc_config_block(vc);
//                [vc_config_block release];
//            }
            
            UINavigationController *navigationController = [[BBQNavigationController alloc] initWithRootViewController:vc];
            navigationController.tabBarItem.title = titleName;
            navigationController.tabBarItem.image = [UIImage imageNamed:imageName];
            //            navigationController.tabBarItem.selectedImage = [UIImage imageNamed:imageSelName]; //暂时不用选中态
            [vcs addObject:navigationController];
            [navigationController release];
            [vc release];
            
            NSString* ascName = [dict objectForKey:@"associate"];
            if (ascName != nil) {
                [self setValue:vc forKey:ascName];
            }
        }
        [_tabMap setObject:[NSNumber numberWithInt:idx] forKey:klassName];
        
        idx ++;
    }
    
    self.tabBarViewController.viewControllers = vcs;
}


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.barbecue.BeatPlane" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BeatPlane" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"BeatPlane.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
