//
//  FINDataManager.m
//  FriendsInNeed
//
//  Created by Milen on 29/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINDataManager.h"
#import "FINLocationManager.h"
#import "FINGlobalConstants.pch"
#import <Crashlytics/Crashlytics.h>
#import <SDWebImage/SDImageCache.h>
#import "RLMSignal.h"

#define kMinimumDistanceTravelled   300
#define kSignalPhotosDirectory      @"signal_photos"
#define kIsInTestModeKey            @"kIsInTestModeKey"
#define kSettingRadiusKey           @"kSettingRadiusKey"
#define kSettingRadiusDefault       10
#define kSettingTimeoutKey          @"kSettingTimeoutKey"
#define kSettingTimeoutDefault      7
#define kDeviceRegistrationIdKey    @"kDeviceRegistrationIdKey"

#import <SDWebImage/UIImageView+WebCache.h>


@interface FINDataManager ()

@property (strong, nonatomic) CLLocation *lastSignalCheckLocation;
@property (strong, nonatomic) CLLocation *lastSavedDeviceLocation;
@property (assign, nonatomic) BOOL        isInTestMode;
@property (assign, nonatomic) NSInteger   radius;
@property (assign, nonatomic) NSInteger   timeout;

@end

@implementation FINDataManager

+ (id)sharedManager
{
    static FINDataManager *_sharedManager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate,
                  ^{
                      _sharedManager = [[self alloc] init];
                  });
    
    return _sharedManager;
}

+ (void)saveDeviceRegistrationId:(NSString *)deviceRegistrationId
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceRegistrationId forKey:kDeviceRegistrationIdKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getDeviceRegistrationId
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kDeviceRegistrationIdKey];
}

+ (BOOL)setNotificationShownForSignalId:(NSString *)signalId
{
    BOOL notificationAlreadyShown = NO;
    RLMSignal *savedSignal;
    RLMResults<RLMSignal *> *savedSignals = [RLMSignal objectsWhere:@"signalId == %@", signalId];
    if (savedSignals.count > 0)
    {
        savedSignal = savedSignals.firstObject;
        if (savedSignal.notificationShown == YES)
        {
            notificationAlreadyShown = YES;
        }
        else
        {
            savedSignal.notificationShown = YES;
        }
    }
    else
    {
        savedSignal = [[RLMSignal alloc] init];
        savedSignal.signalId = signalId;
        savedSignal.notificationShown = YES;
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [realm addObject:savedSignal];
        }];
    }
    
    return notificationAlreadyShown;
}

- (id)init
{
    self = [super init];
    
    _nearbySignals = [NSMutableArray new];
    _isInTestMode = [self loadIsInTestMode];
    
    [self loadSettings];
    
    BOOL isValidUserToken = NO;
    @try {
        isValidUserToken = [backendless.userService isValidUserToken];
        if (isValidUserToken == NO)
        {
            [backendless.userService logout];
        }
    } @catch (NSException *exception) {
        NSLog(@"Crashed with exception %@", exception);
    } @catch (Fault *fault) {
        NSLog(@"Fault: %@", fault);
    }
    
    return self;
}

- (void)saveInCloudNewDeviceLocation:(CLLocation *)location
{
    //Apply dampening
    if (   (self.lastSavedDeviceLocation != nil)
        && ([self.lastSavedDeviceLocation distanceFromLocation:location] < kMinimumDistanceTravelled)   )
    {
        //Previously saved device location is too close
        return;
    }
    
    self.lastSavedDeviceLocation = location;
    
    NSString *deviceRegistrationId = [FINDataManager getDeviceRegistrationId];
    if (deviceRegistrationId != nil)
    {
        id<IDataStore> dataStore = [backendless.data ofTable:@"DeviceRegistration"];
        [dataStore findById:deviceRegistrationId
                   response:^(DeviceRegistration *deviceRegistration) {
                       [deviceRegistration setValue:[NSNumber numberWithInteger:[[FINDataManager sharedManager] getRadiusSetting]] forKey:@"signalRadius"];
                       [deviceRegistration setValue:[NSNumber numberWithInteger:[[FINDataManager sharedManager] getTimeoutSetting]] forKey:@"signalTimeout"];
                       [deviceRegistration setValue:[NSNumber numberWithDouble:location.coordinate.latitude] forKey:@"lastLatitude"];
                       [deviceRegistration setValue:[NSNumber numberWithDouble:location.coordinate.longitude] forKey:@"lastLongitude"];
                       [dataStore save:deviceRegistration];
                   }
                      error:^(Fault *fault) {
                          NSLog(@"Server reported an error: %@", fault);
                      }
         ];
    }
}

- (void)getSignalsForLocation:(CLLocation *)location inRadius:(NSInteger)radius overridingDampening:(BOOL)overrideDampening withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // If new location is too close to last one - do not check
    if (   (overrideDampening == NO)
        && (_lastSignalCheckLocation != nil)
        && ([_lastSignalCheckLocation distanceFromLocation:location] < kMinimumDistanceTravelled)
        && (ABS([_lastSignalCheckLocation.timestamp timeIntervalSinceNow]) < 60)   )
    {
        if (completionHandler != nil)
        {
            completionHandler(UIBackgroundFetchResultNoData);
        }
        NSLog(@"Dampen request for location: %@", location);
        return;
    }
    // If new location is above minimum threshold - save it
    _lastSignalCheckLocation = location;
    
    GEO_POINT center;
    center.latitude = location.coordinate.latitude;
    center.longitude = location.coordinate.longitude;
    BackendlessGeoQuery *query = [BackendlessGeoQuery queryWithPoint:center radius:(radius * 1000) units:METERS categories:nil];
    query.includeMeta = @YES;
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24 * self.timeout)];
    query.whereClause = [NSString stringWithFormat:@"dateSubmitted > %lu", (long)([timeoutDate timeIntervalSince1970] * 1000)];
    
    if (_isInTestMode)
    {
        NSMutableArray *cats = [NSMutableArray new];
        [cats addObject:@"Debug"];
        query.categories = cats;
    }
    
    NSLog(@"Get signals for location: %@", location);
    [backendless.geoService getPoints:query response:^(NSArray<GeoPoint *> *receivedGeoPoints) {
        NSLog(@"Received %lu signals", (unsigned long)receivedGeoPoints.count);
        
        NSMutableArray *newSignals = [NSMutableArray new];
        NSMutableArray *tempNearbySignals = [NSMutableArray new];
        for (GeoPoint *receivedGeoPoint in receivedGeoPoints)
        {
            // Is this protection really needed!?
            if (!receivedGeoPoint)
            {
                continue;
            }
            // Convert received GeoPoint to FINSignal
            FINSignal *receivedSignal = [[FINSignal alloc] initWithGeoPoint:receivedGeoPoint];
            
            // Check if the signal is already present
            BOOL alreadyPresent = NO;
            for (FINSignal *signal in self.nearbySignals)
            {
                if ([signal.signalID isEqualToString:receivedSignal.signalID])
                {
                    alreadyPresent = YES;
                    break;
                }
            }
            // If not, then it is new; add it to newSignals array
            if (alreadyPresent == NO)
            {
                [newSignals addObject:receivedSignal];
                NSLog(@"New signal: %@", receivedSignal.title);                
            }
            
            receivedSignal.photoUrl = [self getPhotoUrlForSignal:receivedSignal];
            
            // Add all received signals to a temp array that will replace newarbySignals when enumeration is finished
            [tempNearbySignals addObject:receivedSignal];
        }
        
        self.nearbySignals = [NSMutableArray arrayWithArray:tempNearbySignals];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // If application is currently active show received signals on map
            if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
            {
                [self.mapDelegate updateMapWithNearbySignals:self.nearbySignals];
                if (completionHandler)
                {
                    CLS_LOG(@"[FIN] Calling background fetch completion handler: %@", completionHandler);
                    completionHandler(UIBackgroundFetchResultNewData);
                }
            }
            // If not - show notification(s)
            else
            {
                if (newSignals.count > 0)
                {
                    for (FINSignal *signal in newSignals)
                    {
                        BOOL notificationAlreadyShown = [FINDataManager setNotificationShownForSignalId:signal.signalID];
                        if (notificationAlreadyShown)
                        {
                            continue;
                        }
                        
                        NSInteger badgeNumber = 0;
                        // Only show notifications about signals that haven't been solved yet
                        if (signal.status < FINSignalStatus2)
                        {
                            badgeNumber++;
                            
                            // Create local notification and show it
                            UNMutableNotificationContent *notifContent = [UNMutableNotificationContent new];
                            notifContent.body = signal.title;
                            notifContent.sound = [UNNotificationSound defaultSound];
                            notifContent.categoryIdentifier = kNotificationCategoryNewSignal;
                            
                            NSMutableDictionary *userInfo = [NSMutableDictionary new];
                            [userInfo setObject:signal.signalID forKey:kNotificationSignalId];
                            notifContent.userInfo = userInfo;
                            
                            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString] content:notifContent trigger:nil];
                            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
                        }
                        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeNumber];
                    }
                    
                    if (completionHandler)
                    {
                        CLS_LOG(@"[FIN] Calling background fetch completion handler: %@", completionHandler);
                        completionHandler(UIBackgroundFetchResultNewData);
                    }
                }
                else
                {
                    if (completionHandler)
                    {
                        CLS_LOG(@"[FIN] Calling background fetch completion handler: %@", completionHandler);
                        completionHandler(UIBackgroundFetchResultNoData);
                    }
                }
            }
        });
        
    } error:^(Fault *fault) {
        CLS_LOG(@"[FIN] Getting signals failed with error: %@", fault.description);
        
        self.lastSignalCheckLocation = nil;
        
        if (completionHandler != nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                CLS_LOG(@"[FIN] Calling background fetch completion handler: %@", completionHandler);
                completionHandler(UIBackgroundFetchResultFailed);
            });
        }
    }];
}

- (void)getSignalsForNewLocation:(CLLocation *)location withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self getSignalsForLocation:location inRadius:self.radius overridingDampening:NO withCompletionHandler:completionHandler];
    
    [self saveInCloudNewDeviceLocation:location];
}

- (void)getNewSignalsForLastLocationWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    CLLocation *lastKnownUserLocation = [[FINLocationManager sharedManager] getLastKnownUserLocation];
    if (lastKnownUserLocation != nil)
    {
        [self getSignalsForLocation:lastKnownUserLocation inRadius:self.radius overridingDampening:NO withCompletionHandler:completionHandler];
    }
    else
    {
        if (completionHandler != nil)
        {
            CLS_LOG(@"[FIN] Calling background fetch completion handler: %@", completionHandler);
            completionHandler(UIBackgroundFetchResultFailed);
        }
    }
}

- (void)submitNewSignalWithTitle:(NSString *)title forLocation:(CLLocationCoordinate2D)locationCoordinate withPhoto:(UIImage *)photo completion:(void (^)(FINSignal *savedSignal, FINError *error))completion
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    
    GEO_POINT coordinate;
    coordinate.latitude = locationCoordinate.latitude;
    coordinate.longitude = locationCoordinate.longitude;
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSString *submitDate = [NSString stringWithFormat:@"%.3f", timeInterval];
    submitDate = [submitDate stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSDictionary *geoPointMeta = @{kSignalTitleKey:title, kSignalAuthorKey:currentUser, kSignalDateSubmittedKey:submitDate, kSignalStatusKey:@0};
    NSMutableArray *cats = [NSMutableArray new];
    if (_isInTestMode)
    {
        [cats addObject:@"Debug"];
    }
    GeoPoint *point = [GeoPoint geoPoint:coordinate categories:cats metadata:geoPointMeta];
    
    [backendless.geoService savePoint:point response:^(GeoPoint *savedGeoPoint) {
        
        FINSignal *savedSignal = [[FINSignal alloc] initWithGeoPoint:savedGeoPoint];
        [self.nearbySignals addObject:savedSignal];
        
        if (photo)
        {
            NSString *fileName = [NSString stringWithFormat:@"%@/%@.jpg", kSignalPhotosDirectory, savedSignal.signalID];
            [backendless.fileService uploadFile:fileName content:UIImageJPEGRepresentation(photo, 0.1) overwriteIfExist:YES response:^(BackendlessFile *savedFile) {
                savedSignal.photoUrl = [NSURL URLWithString:savedFile.fileURL];
                [[SDImageCache sharedImageCache] storeImage:photo forKey:savedFile.fileURL completion:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(savedSignal, nil);
                    });
                }];
            } error:^(Fault *fault) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    FINError *error = [[FINError alloc] initWithFault:fault];
                    completion(savedSignal, error);
                });
            }];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(savedSignal, nil);
            });
        }
        
        //Send push notifications to all interested devices in the area
        DataQueryBuilder *queryBuilder = [DataQueryBuilder new];
        [queryBuilder setRelationsDepth:1];
        //Get all devices within 100km of the signal
        [queryBuilder setWhereClause:[NSString stringWithFormat:@"distance( %@, %@, lastLatitude, lastLongitude ) < signalRadius * 1000", savedGeoPoint.latitude, savedGeoPoint.longitude]];
        
        id<IDataStore> dataStore = [backendless.data ofTable:@"DeviceRegistration"];
        [dataStore find:queryBuilder response:^(NSArray *devices) {
            NSLog(@"Devices: %@", devices);
            NSMutableArray *deviceIds = [NSMutableArray new];
            for (NSDictionary *device in devices)
            {
                NSString *deviceId = [device objectForKey:@"deviceId"];
                //Skip current device
                if (![backendless.messaging.currentDevice.deviceId isEqualToString:deviceId])
                {
                    [deviceIds addObject:deviceId];
                }
            }
            
            if (deviceIds.count > 0)
            {
                PublishOptions *publishOptions = [PublishOptions new];
                [publishOptions assignHeaders:@{@"ios-alert":title,
                                                @"ios-badge":@1,
                                                @"ios-sound":@"default",
                                                @"signalId":savedGeoPoint.objectId,
                                                @"ios-category":kNotificationCategoryNewSignal}];
                
                DeliveryOptions *deliveryOptions = [DeliveryOptions new];
                deliveryOptions.pushSinglecast = deviceIds;
                
                [backendless.messaging publish:@"default"
                                       message:title
                                publishOptions:publishOptions
                               deliveryOptions:deliveryOptions
                                      response:^(MessageStatus *status) {
                                          NSLog(@"Status: %@", status);
                                      }
                                         error:^(Fault *fault) {
                                             NSLog(@"Server reported an error: %@", fault);
                                         }];
            }
            
        } error:^(Fault *fault) {
            NSLog(@"Error executing query: %@", fault.message);
        }];
        
    } error:^(Fault *fault) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FINError *error = [[FINError alloc] initWithFault:fault];
            completion(nil, error);
        });
    }];
}

- (void)setStatus:(FINSignalStatus)status forSignal:(FINSignal *)signal completion:(void (^)(FINError *error))completion
{
    GeoPoint *point = [signal geoPoint];
    [point.metadata setObject:[NSString stringWithFormat:@"%lu", (unsigned long)status] forKey:kSignalStatusKey];
    
    [backendless.geoService savePoint:point response:^(GeoPoint *returnedGeoPoint) {
        dispatch_async(dispatch_get_main_queue(), ^{
            signal.geoPoint = returnedGeoPoint;
            completion(nil);
        });
    } error:^(Fault *fault) {
        dispatch_async(dispatch_get_main_queue(), ^{            
            FINError *error = [[FINError alloc] initWithFault:fault];
            completion(error);
        });
    }];
}

- (void)getSignalWithID:(NSString *)signalID completion:(void (^)(FINSignal *signal, FINError *error))completion
{
    NSMutableArray *cats = [NSMutableArray new];
    if (_isInTestMode)
    {
        [cats addObject:@"Debug"];
    }
    
    BackendlessGeoQuery *query = [BackendlessGeoQuery queryWithCategories:cats];
    query.whereClause = [NSString stringWithFormat:@"objectid='%@'", signalID];
    [query includeMeta:YES];
    [backendless.geoService getPoints:query response:^(NSArray<GeoPoint *> *geoPoints) {
        
        if (geoPoints.count > 0)
        {
            GeoPoint *geoPoint = (GeoPoint *) geoPoints.firstObject;
            FINSignal *signal = [[FINSignal alloc] initWithGeoPoint:geoPoint];
            signal.photoUrl = [self getPhotoUrlForSignal:signal];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(signal, nil);
            });
        }
    } error:^(Fault *fault) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FINError *error = [[FINError alloc] initWithFault:fault];
            completion(nil, error);
        });
    }];
}

- (BOOL)userIsLogged
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    
    return (currentUser != nil);
}

- (BOOL)getUserHasAcceptedPrivacyPolicy
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    if (currentUser != nil)
    {
        NSNumber *acceptedPrivacyPolicy = [currentUser getProperty:kUserPropertyAcceptedPrivacyPolicy];
        return [acceptedPrivacyPolicy boolValue];
    }
    
    return NO;
}

- (void)setUserHasAcceptedPrivacyPolicy:(BOOL)value
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    if (currentUser != nil)
    {
        [currentUser setProperty:kUserPropertyAcceptedPrivacyPolicy object:[NSNumber numberWithBool:value]];
        [backendless.userService update:currentUser response:^(BackendlessUser *updatedUser) {
            //Do nothing, be happy
        } error:^(Fault *fault) {
            //Do nothing, be sad
        }];
    }
}

- (NSString *)getUserName
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    
    return currentUser.name;
}

- (NSString *)getUserEmail
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    
    return currentUser.email;
}

- (void)registerUser:(NSString *)name withEmail:(NSString *)email password:(NSString *)password phoneNumber:(NSString *)phoneNumber completion:(void (^)(FINError *error))completion
{
    BackendlessUser *user = [BackendlessUser new];
    user.name = name;
    user.email = email;
    user.password = password;
    [user setProperty:kUserPropertyPhoneNumber object:phoneNumber];
    [user setProperty:kUserPropertyAcceptedPrivacyPolicy object:[NSNumber numberWithBool:YES]];    
    
    [backendless.userService registerUser:user response:^void (BackendlessUser *registeredUser) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
    } error:^void (Fault *fault) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FINError *error = [[FINError alloc] initWithFault:fault];
            completion(error);
        });
    }];
}

- (void)loginWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(FINError *error))completion
{
    [backendless.userService login:email password:password response:^void (BackendlessUser *loggeduser) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUserLoggedIn
                                                                object:nil];
            completion(nil);
        });
    } error:^void (Fault *fault) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FINError *error = [[FINError alloc] initWithFault:fault];
            completion(error);
        });
    }];
}

- (void)logoutWithCompletion:(void (^)(FINError *error))completion
{
    [backendless.userService logout:^void () {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
    } error:^void (Fault *fault) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FINError *error = [[FINError alloc] initWithFault:fault];
            completion(error);
        });
    }];
}

- (NSURL *)getPhotoUrlForSignal:(FINSignal *)signal
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://api.backendless.com/%@/%@/files/%@/%@.jpg", BCKNDLSS_APP_ID, BCKNDLSS_REST_API_KEY, kSignalPhotosDirectory, signal.signalID]];
}

- (void)getCommentsForSignal:(FINSignal *)signal completion:(void (^)(NSArray *comments, FINError *error))completion
{
    DataQueryBuilder *queryBuilder = [DataQueryBuilder new];
    [queryBuilder setWhereClause:[NSString stringWithFormat:@"signalID = \'%@\'", signal.signalID]];
    [queryBuilder setSortBy:@[@"created"]];
    [queryBuilder addRelated:@"author"];
    
    id<IDataStore> commentsStore = [backendless.data of:[FINComment class]];
    [commentsStore find:queryBuilder response:^(NSArray<FINComment *> *comments) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(comments, nil);
        });
    } error:^(Fault *fault) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FINError *error = [[FINError alloc] initWithFault:fault];
            completion(nil, error);
        });
    }];
}

- (void)saveComment:(NSString *)commentText forSigna:(FINSignal *)signal completion:(void (^)(FINComment *comment, FINError *error))completion
{
    FINComment *comment = [FINComment new];
    comment.text = commentText;
    comment.author = backendless.userService.currentUser;
    comment.signalID = signal.signalID;
    
    id<IDataStore>commentsStore = [backendless.data of:[FINComment class]];
    [commentsStore save:comment response:^(FINComment *comment) {
        BackendlessUser *author = backendless.userService.currentUser;
        [commentsStore setRelation:@"author" parentObjectId:comment.objectId childObjects:@[author.objectId] response:^(NSNumber *setRelations) {
            dispatch_async(dispatch_get_main_queue(), ^{
                comment.author = author;
                completion(comment, nil);
            });
        } error:^(Fault *fault) {
            dispatch_async(dispatch_get_main_queue(), ^{
                FINError *error = [[FINError alloc] initWithFault:fault];
                completion(nil, error);
            });
        }];
    } error:^(Fault *fault) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FINError *error = [[FINError alloc] initWithFault:fault];
            completion(nil, error);
        });
    }];
}

+ (NSInteger)getNewStatusCodeFromStatusChangedComment:(NSString *)commentText
{
    NSError *jsonError;
    NSData *objectData = [commentText dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    if (!jsonError)
    {
        NSNumber *newStatusCode = [json objectForKey:@"new"];
        if (newStatusCode != nil)
        {
            return [newStatusCode integerValue];
        }
    }
    
    return 0;
}

- (void)getAllSignalsFromPage:(NSInteger)page withCompletionHandler:(void (^)(NSArray<FINSignal *> *signals, FINError *error))completionHandler
{
    BackendlessGeoQuery *query = [BackendlessGeoQuery queryWithCategories:@[@"Default"]];
    query.includeMeta = @YES;
    query.pageSize = @100;
    query.offset = [NSNumber numberWithInteger:page*100];
    
    NSMutableArray *totalSignals = [NSMutableArray new];
    [backendless.geoService getPoints:query response:^(NSArray<GeoPoint *> *receivedGeoPoints) {
        
        for (GeoPoint *receivedGeoPoint in receivedGeoPoints)
        {
            // Convert received GeoPoint to FINSignal
            FINSignal *receivedSignal = [[FINSignal alloc] initWithGeoPoint:receivedGeoPoint];
            [totalSignals addObject:receivedSignal];
        }
        if (receivedGeoPoints.count == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(totalSignals, nil);
            });
        }
        else {
            [self getAllSignalsFromPage:page+1 withCompletionHandler:^(NSArray<FINSignal *> *signals, FINError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [totalSignals addObjectsFromArray:signals];
                    completionHandler(totalSignals, nil);
                });
            }];
        }
        
    } error:^(Fault *fault) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FINError *error = [[FINError alloc] initWithFault:fault];
            completionHandler(nil, error);
        });
    }];
}

- (void)getAllSignalsWithCompletionHandler:(void (^)(NSArray<FINSignal *> *signals, FINError *error))completionHandler
{
    [self getAllSignalsFromPage:0 withCompletionHandler:^(NSArray<FINSignal *> *signals, FINError *error) {
        completionHandler(signals, error);
    }];
}

#pragma MARK - TEST Mode

- (BOOL)getIsInTestMode
{
    return _isInTestMode;
}

- (void)setIsInTestMode:(BOOL)isInTestMode
{
    _isInTestMode = isInTestMode;
    [self saveIsInTestMode:isInTestMode];
}

- (BOOL)loadIsInTestMode
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kIsInTestModeKey];
}

- (void)saveIsInTestMode:(BOOL)isInTestMode
{
    [[NSUserDefaults standardUserDefaults] setBool:isInTestMode forKey:kIsInTestModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma MARK - Settings

- (void)loadSettings
{
    NSInteger savedRadius = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingRadiusKey];
    _radius = savedRadius != 0 ? savedRadius : kSettingRadiusDefault;
    
    NSInteger savedTimeout = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingTimeoutKey];
    _timeout = savedTimeout != 0 ? savedTimeout : kSettingTimeoutDefault;
}

- (NSInteger)getRadiusSetting
{
    return _radius;
}

- (NSInteger)getTimeoutSetting
{
    return _timeout;
}

- (void)setRadiusSetting:(NSInteger)newRadius
{
    if (newRadius != _radius)
    {
        _radius = newRadius;
        [[NSUserDefaults standardUserDefaults] setInteger:newRadius forKey:kSettingRadiusKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSettingRadiusChanged object:self];
    }
}

- (void)setTimeoutSetting:(NSInteger)newTimeout
{
    if (newTimeout != _timeout)
    {
        _timeout = newTimeout;
        [[NSUserDefaults standardUserDefaults] setInteger:newTimeout forKey:kSettingTimeoutKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSettingTimeoutChanged object:self];
    }
}

@end
