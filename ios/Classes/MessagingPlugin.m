// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "MessagingPlugin.h"
#import <UMPush/UMessage.h>

//#import "Firebase/Firebase.h"

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
//@interface FLTFirebaseMessagingPlugin () <FIRMessagingDelegate>
//@end
#endif

@implementation FLTMessagingPlugin {
  FlutterMethodChannel *_channel;
  NSDictionary *_launchNotification;
  BOOL _resumingFromBackground;
  NSString *pendingAlias;
  NSString *dToken;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"com.yangio.plugin/messaging"
                                  binaryMessenger:[registrar messenger]];
  FLTMessagingPlugin *instance =
      [[FLTMessagingPlugin alloc] initWithChannel:channel];
  [registrar addApplicationDelegate:instance];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
  self = [super init];

  if (self) {
    _channel = channel;
    _resumingFromBackground = NO;
    //if (![FIRApp appNamed:@"__FIRAPP_DEFAULT"]) {
    //  NSLog(@"Configuring the default Firebase app...");
    //  [FIRApp configure];
    //  NSLog(@"Configured the default Firebase app %@.", [FIRApp defaultApp].name);
    //}
    //[FIRMessaging messaging].delegate = self;
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  NSString *method = call.method;
  if ([@"requestNotificationPermissions" isEqualToString:method]) {
    UIUserNotificationType notificationTypes = 0;
    NSDictionary *arguments = call.arguments;
    if ([arguments[@"sound"] boolValue]) {
      notificationTypes |= UIUserNotificationTypeSound;
    }
    if ([arguments[@"alert"] boolValue]) {
      notificationTypes |= UIUserNotificationTypeAlert;
    }
    if ([arguments[@"badge"] boolValue]) {
      notificationTypes |= UIUserNotificationTypeBadge;
    }
    UIUserNotificationSettings *settings =
        [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];

    result(nil);
  } else if ([@"configure" isEqualToString:method]) {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    if (_launchNotification != nil) {
      [_channel invokeMethod:@"onLaunch" arguments:_launchNotification];
    }
    result(nil);
  } else if ([@"setAlias" isEqualToString:method]) {
      if ([call.arguments isKindOfClass:[NSString class]]) {
          NSLog(@"umeng_push_plugin set alias arguments %@", call.arguments);
          
          NSString *alias = (NSString *)call.arguments;
          if (alias != nil) {
              if (dToken != nil) {
                  NSLog(@"umeng_push_plugin set alias alias%@", alias);
                  NSLog(@"umeng_push_plugin set alias deviceToken = %@", dToken);
                  
                  [UMessage setAlias:alias type:@"uid" response:^(id responseObject, NSError *error) {
                      NSLog(@"umeng_push_plugin set alias completed");
                  }];
              } else {
                  pendingAlias = alias;
                  NSLog(@"umeng_push_plugin device token is null,  pendingAlias %@", pendingAlias);
              }
          }
      }

      
      result(nil);
  } else if ([@"removeAlias" isEqualToString:method]) {
      if ([call.arguments isKindOfClass:[NSString class]]) {
          NSString *alias = call.arguments;

          [UMessage removeAlias:alias type:@"uid" response:^(id responseObject, NSError *error) {
              NSLog(@"umeng_push_plugin remove alias completed %@", error);
          }];
      }
      result(nil);
  } else if ([call.method isEqualToString:@"status"]) {
      result([NSNumber numberWithBool:[self isNotificationOn]]);
  } else if ([call.method isEqualToString:@"goSettings"]) {
    [self goToAppSystemSetting];
    result(nil);
  } else if ([call.method isEqualToString:@"clearNativeStack"]) {
    [self popToMain];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void) popToMain {
    UIViewController* viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
  if ([viewController isKindOfClass:[UINavigationController class]]) {
    [((UINavigationController*)viewController) popToRootViewControllerAnimated:NO];
  }
}

- (void)goToAppSystemSetting {
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([application canOpenURL:url]) {
        if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            if (@available(iOS 10.0, *)) {
                [application openURL:url options:@{} completionHandler:nil];
            } else {
                // Fallback on earlier versions
            }

        } else {
            [application openURL:url];
        }
    }
}

- (BOOL)isNotificationOn {
    UIUserNotificationSettings *setting = [[UIApplication sharedApplication] currentUserNotificationSettings];
    return  (UIUserNotificationTypeNone == setting.types) ? NO : YES;
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
  if (_resumingFromBackground) {
    [_channel invokeMethod:@"onResume" arguments:userInfo];
  } else {
    [_channel invokeMethod:@"onMessage" arguments:userInfo];
  }
}

#pragma mark - AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (launchOptions != nil) {
    _launchNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    }
    
    UMessageRegisterEntity * entity = [[UMessageRegisterEntity alloc] init];
    entity.types = UMessageAuthorizationOptionBadge|UMessageAuthorizationOptionSound|UMessageAuthorizationOptionAlert;
    #if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    #endif
    [UMessage registerForRemoteNotificationsWithLaunchOptions:launchOptions Entity:entity     completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            NSLog(@"granted ==== 213213");
        }else{
            NSLog(@"delend ==== 213213");
        }
    }];
  return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  _resumingFromBackground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  _resumingFromBackground = NO;
  // Clears push notifications from the notification center, with the
  // side effect of resetting the badge count. We need to clear notifications
  // because otherwise the user could tap notifications in the notification
  // center while the app is in the foreground, and we wouldn't be able to
  // distinguish that case from the case where a message came in and the
  // user dismissed the notification center without tapping anything.
  // TODO(goderbauer): Revisit this behavior once we provide an API for managing
  // the badge number, or if we add support for running Dart in the background.
  // Setting badgeNumber to 0 is a no-op (= notifications will not be cleared)
  // if it is already 0,
  // therefore the next line is setting it to 1 first before clearing it again
  // to remove all
  // notifications.
  application.applicationIconBadgeNumber = 1;
  application.applicationIconBadgeNumber = 0;
}

- (bool)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  [self didReceiveRemoteNotification:userInfo];
  completionHandler(UIBackgroundFetchResultNoData);
  return YES;
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
 // [_channel invokeMethod:@"onToken" arguments:[[FIRInstanceID instanceID] token]];
    NSLog(@"umeng_push_plugin application didRegisterForRemoteNotificationsWithDeviceToken%@", deviceToken);
    dToken = [self stringDevicetoken:deviceToken];
    NSLog(@"umeng_push_plugin device token = %@", dToken);

    [_channel invokeMethod:@"onToken" arguments:dToken];

    if (pendingAlias != nil) {
        NSLog(@"umeng_push_plugin set alias pendingAlias%@", pendingAlias);

        [UMessage setAlias:pendingAlias type:@"uid" response:^(id responseObject, NSError *error) {
            NSLog(@"umeng_push_plugin set pendingAlias completed");
            pendingAlias = nil;
        }];
    }
}

- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
  NSDictionary *settingsDictionary = @{
    @"sound" : [NSNumber numberWithBool:notificationSettings.types & UIUserNotificationTypeSound],
    @"badge" : [NSNumber numberWithBool:notificationSettings.types & UIUserNotificationTypeBadge],
    @"alert" : [NSNumber numberWithBool:notificationSettings.types & UIUserNotificationTypeAlert],
  };
  [_channel invokeMethod:@"onIosSettingsRegistered" arguments:settingsDictionary];
}

- (NSString *)stringDevicetoken:(NSData *)deviceToken {
    NSString *token = [deviceToken description];
    NSString *pushToken = [[[token stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    return pushToken;
}

//- (void)messaging:(nonnull FIRMessaging *)messaging
//    didReceiveRegistrationToken:(nonnull NSString *)fcmToken {
//  [_channel invokeMethod:@"onToken" arguments:fcmToken];
//}

@end
