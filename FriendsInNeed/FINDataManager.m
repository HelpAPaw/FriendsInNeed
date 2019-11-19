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
#define kDeviceTokenKey             @"kDeviceTokenKey"
#define kPageSize                   100

#import <SDWebImage/UIImageView+WebCache.h>

typedef NS_ENUM(NSUInteger, SignalUpdate) {
    SignalUpdateNewComment,
    SignalUpdateNewStatus
};


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

- (void)updateDeviceRegistrationWithLocation:(CLLocation *)location
{
    //Apply dampening
    if (   (location != nil)
        && (self.lastSavedDeviceLocation != nil)
        && ([self.lastSavedDeviceLocation distanceFromLocation:location] < kMinimumDistanceTravelled)   )
    {
        //Previously saved device location is too close
        return;
    }
    
    if (location != nil)
    {
        self.lastSavedDeviceLocation = location;
    }
    
    NSString *deviceRegistrationId = [FINDataManager getDeviceRegistrationId];
    if (deviceRegistrationId != nil)
    {
        id<IDataStore> dataStore = [backendless.data ofTable:@"DeviceRegistration"];
        [dataStore findById:deviceRegistrationId
                   response:^(DeviceRegistration *deviceRegistration) {
                       [deviceRegistration setValue:[NSNumber numberWithInteger:[[FINDataManager sharedManager] getRadiusSetting]] forKey:@"signalRadius"];
                       [deviceRegistration setValue:[NSNumber numberWithInteger:[[FINDataManager sharedManager] getTimeoutSetting]] forKey:@"signalTimeout"];
                       [deviceRegistration setValue:[NSNumber numberWithDouble:self.lastSavedDeviceLocation.coordinate.latitude] forKey:@"lastLatitude"];
                       [deviceRegistration setValue:[NSNumber numberWithDouble:self.lastSavedDeviceLocation.coordinate.longitude] forKey:@"lastLongitude"];
                       
                       @try {
                           [dataStore save:deviceRegistration];
                       } @catch (NSException *exception) {
                           NSLog(@"An exception occurred: %@", exception);
                       } @catch (Fault *fault) {
                           NSLog(@"A fault occurred: %@", fault);
                       }
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
                    NSInteger badgeNumber = 0;
                    for (FINSignal *signal in newSignals)
                    {
                        BOOL notificationAlreadyShown = [FINDataManager setNotificationShownForSignalId:signal.signalID];
                        if (notificationAlreadyShown)
                        {
                            continue;
                        }
                        
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
                    }
                    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeNumber];
                    
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
    
    [self updateDeviceRegistrationWithLocation:location];
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

- (void)submitNewSignalWithTitle:(NSString *)title andAuthorPhone:(NSString *)authorPhone forLocation:(CLLocationCoordinate2D)locationCoordinate withPhoto:(UIImage *)photo completion:(void (^)(FINSignal *savedSignal, FINError *error))completion
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    
    GEO_POINT coordinate;
    coordinate.latitude = locationCoordinate.latitude;
    coordinate.longitude = locationCoordinate.longitude;
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSString *submitDate = [NSString stringWithFormat:@"%.3f", timeInterval];
    submitDate = [submitDate stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSDictionary *geoPointMeta = @{kSignalTitleKey:title,
                                   kSignalAuthorKey:currentUser,
                                   kSignalAuthorPhoneKey:authorPhone,
                                   kSignalDateSubmittedKey:submitDate,
                                   kSignalStatusKey:@0};
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
        [self sendPushNotificationsForNewSignal:savedSignal];
        
    } error:^(Fault *fault) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FINError *error = [[FINError alloc] initWithFault:fault];
            completion(nil, error);
        });
    }];
}

- (void)setStatus:(FINSignalStatus)status forSignal:(FINSignal *)signal withCurrentComments:(NSArray<FINComment *> *)currentComments completion:(void (^)(FINError *error))completion
{
    GeoPoint *point = [signal geoPoint];
    [point.metadata setObject:[NSString stringWithFormat:@"%lu", (unsigned long)status] forKey:kSignalStatusKey];
    
    [backendless.geoService savePoint:point response:^(GeoPoint *returnedGeoPoint) {
        signal.geoPoint = returnedGeoPoint;
        
        [self sendPushNotificationsForNewStatus:status onSignal:signal withCurrentComments:currentComments];
        
        dispatch_async(dispatch_get_main_queue(), ^{
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

- (NSString *)getUserPhone
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    if (currentUser != nil)
    {
        NSString *phone = [currentUser getProperty:kUserPropertyPhoneNumber];
        return phone;
    }
    
    return @"";
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

// Public method for getting signal comments
- (void)getCommentsForSignal:(FINSignal *)signal completion:(void (^)(NSArray *comments, FINError *error))completion
{
    DataQueryBuilder *queryBuilder = [DataQueryBuilder new];
    [queryBuilder setWhereClause:[NSString stringWithFormat:@"signalID = \'%@\'", signal.signalID]];
    [queryBuilder setSortBy:@[@"created"]];
    [queryBuilder addRelated:@"author"];
    [queryBuilder setPageSize:kPageSize];
    
    [self getCommentsWithQuery:queryBuilder offset:0 response:^(NSArray *comments) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(comments, nil);
        });
    } error:^(FINError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, error);
        });
    }];
}

// Internal method to recursively getting all pages with comments
- (void)getCommentsWithQuery:(DataQueryBuilder *)queryBuilder offset:(int)offset response:(void (^)(NSArray *comments))response error:(void (^)(FINError *error))failure
{
    [queryBuilder setOffset:offset];
    id<IDataStore> commentsStore = [backendless.data of:[FINComment class]];
    [commentsStore find:queryBuilder response:^(NSArray<FINComment *> *comments) {
        if (comments.count == kPageSize)
        {
            [self getCommentsWithQuery:queryBuilder offset:(offset + kPageSize) response:^(NSArray *comments2) {
                response([comments arrayByAddingObjectsFromArray:comments2]);
            } error:^(FINError *error) {
                failure(error);
            }];
        }
        else
        {
            response(comments);
        }
    } error:^(Fault *fault) {
        FINError *err = [[FINError alloc] initWithFault:fault];
        failure(err);
    }];
}

- (void)saveComment:(NSString *)commentText forSigna:(FINSignal *)signal withCurrentComments:(NSArray<FINComment *> *)currentComments completion:(void (^)(FINComment *comment, FINError *error))completion
{
    FINComment *comment = [FINComment new];
    comment.text = commentText;
    comment.author = backendless.userService.currentUser;
    comment.signalID = signal.signalID;
    
    id<IDataStore>commentsStore = [backendless.data of:[FINComment class]];
    [commentsStore save:comment response:^(FINComment *comment) {
        BackendlessUser *author = backendless.userService.currentUser;
        [commentsStore setRelation:@"author" parentObjectId:comment.objectId childObjects:@[author.objectId] response:^(NSNumber *setRelations) {
            comment.author = author;
            
            [self sendPushNotificationsForNewComment:commentText onSignal:signal withCurrentComments:currentComments];
            
            dispatch_async(dispatch_get_main_queue(), ^{
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
    [backendless.messaging unregisterDevice];
    
    _isInTestMode = isInTestMode;
    [self saveIsInTestMode:isInTestMode];
    
    [self registerDeviceToken:[FINDataManager getDeviceToken]];
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

#pragma MARK - Device token registration

+ (void)saveDeviceRegistrationId:(NSString *)deviceRegistrationId
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceRegistrationId forKey:kDeviceRegistrationIdKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)getDeviceRegistrationId
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kDeviceRegistrationIdKey];
}

+ (void)saveDeviceToken:(NSData *)deviceToken
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:kDeviceTokenKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSData *)getDeviceToken
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kDeviceTokenKey];
}

- (void)registerDeviceToken:(NSData *)deviceToken
{
    NSString *currentNotificationChannel = [self getCurrentNotificationChannel];
    [backendless.messaging registerDevice:deviceToken
                                 channels:@[currentNotificationChannel]
                                 response:^(NSString *registeredDeviceId) {
                                     //Get only the objectId part
                                     NSArray *components = [registeredDeviceId componentsSeparatedByString:@":"];
                                     [FINDataManager saveDeviceRegistrationId:components[0]];
                                     [FINDataManager saveDeviceToken:deviceToken];
                                     
                                     [self updateDeviceRegistrationWithLocation:nil];
                                 }
                                    error:^(Fault *fault) {
                                        //Do nothing
                                    }];
}

- (NSString *)getCurrentNotificationChannel
{
    if (_isInTestMode)
    {
        return @"debug";
    }
    else
    {
        return @"default";
    }
}

#pragma MARK - Push notifications

// Public method for sending push notifications for new signal
- (void)sendPushNotificationsForNewSignal:(FINSignal *)signal
{
    DataQueryBuilder *queryBuilder = [DataQueryBuilder new];
    [queryBuilder setRelationsDepth:1];
    [queryBuilder setPageSize:kPageSize];
    //Get all devices within 100km of the signal
    [queryBuilder setWhereClause:[NSString stringWithFormat:@"distance( %@, %@, lastLatitude, lastLongitude ) < signalRadius * 1000", signal.geoPoint.latitude, signal.geoPoint.longitude]];
    
    [self sendPushNotificationsWith:queryBuilder offset:0 forSignal:signal];
}

// Internal method to recursively send notifications to all pages of interested devices
- (void)sendPushNotificationsWith:(DataQueryBuilder *)queryBuilder offset:(int)offset forSignal:(FINSignal *)signal
{
    [queryBuilder setOffset:offset];
    id<IDataStore> dataStore = [backendless.data ofTable:@"DeviceRegistration"];
    [dataStore find:queryBuilder response:^(NSArray *devices) {
        
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
            [publishOptions assignHeaders:@{@"android-ticker-text":NSLocalizedString(@"New signal", nil),
                                            @"android-content-title":signal.title,
                                            @"ios-alert-title":signal.title,
                                            @"ios-badge":@1,
                                            @"ios-sound":@"default",
                                            @"signalId":signal.geoPoint.objectId,
                                            @"ios-category":kNotificationCategoryNewSignal}];
            
            DeliveryOptions *deliveryOptions = [DeliveryOptions new];
            deliveryOptions.pushSinglecast = deviceIds;
            
            [backendless.messaging publish:[self getCurrentNotificationChannel]
                                   message:NSLocalizedString(@"New signal", nil)
                            publishOptions:publishOptions
                           deliveryOptions:deliveryOptions
                                  response:^(MessageStatus *status) {
                NSLog(@"Status: %@", status);
            }
                                     error:^(Fault *fault) {
                NSLog(@"Server reported an error: %@", fault);
            }];
        }
        
        if (devices.count == kPageSize) {
            [self sendPushNotificationsWith:queryBuilder offset:(offset + kPageSize) forSignal:signal];
        }
        
    } error:^(Fault *fault) {
        NSLog(@"Error executing query: %@", fault.message);
    }];
}

// Public methods for sending push notifications for new status and comments
- (void)sendPushNotificationsForNewComment:(NSString *)newComment
                                  onSignal:(FINSignal *)signal
                       withCurrentComments:(NSArray<FINComment *> *)currentComments
{
    [self sendPushNotificationsForUpdatedSignal:signal
                            withCurrentComments:currentComments
                                     updateType:SignalUpdateNewComment
                                      newStatus:0
                                     newComment:newComment];
}

- (void)sendPushNotificationsForNewStatus:(FINSignalStatus)newStatus
                                 onSignal:(FINSignal *)signal
                      withCurrentComments:(NSArray<FINComment *> *)currentComments
{
    [self sendPushNotificationsForUpdatedSignal:signal
                            withCurrentComments:currentComments
                                     updateType:SignalUpdateNewStatus
                                      newStatus:newStatus
                                     newComment:nil];
}

- (void)sendPushNotificationsForUpdatedSignal:(FINSignal *)signal
                          withCurrentComments:(NSArray<FINComment *> *)currentComments
                                   updateType:(SignalUpdate)signalUpdate
                                    newStatus:(FINSignalStatus)newStatus
                                   newComment:(NSString *)newComment
{
    // Use Set to ensure there are no double entries
    NSMutableSet *interestedUserIds = [NSMutableSet new];
    // Add author of the signal
    [interestedUserIds addObject:signal.authorId];
    // Add all people that posted comments
    for (FINComment *comment in currentComments)
    {
        [interestedUserIds addObject:comment.author.objectId];
    }
    // Remove current user
    [interestedUserIds removeObject:backendless.userService.currentUser.objectId];
    
    // Create a comma separated list
    NSMutableString *userIds = [NSMutableString new];
    for (NSString *string in interestedUserIds)
    {
        // Strings in the WHERE clause array need to be in single quotes
        NSString *quotedString = [NSString stringWithFormat:@"'%@'", string];
        [userIds length] > 0 ? [userIds appendFormat:@",%@", quotedString] : [userIds appendString:quotedString];
    }
    
    // Build query
    NSString *whereClause = [NSString stringWithFormat:@"user.objectid IN (%@)", userIds];
    DataQueryBuilder *queryBuilder = [DataQueryBuilder new];
    [queryBuilder setWhereClause:whereClause];
    [queryBuilder setPageSize:kPageSize];
        
    [self sendPushNotificationsWith:queryBuilder
                             offset:0
                          forSignal:signal
                         updateType:signalUpdate
                          newStatus:newStatus
                         newComment:newComment];
}

// Internal method to recursively send notifications to all pages of interested devices
- (void)sendPushNotificationsWith:(DataQueryBuilder *)queryBuilder
                           offset:(int)offset
                        forSignal:(FINSignal *)signal
                       updateType:(SignalUpdate)signalUpdate
                        newStatus:(FINSignalStatus)newStatus
                       newComment:(NSString *)newComment {
    id<IDataStore> dataStore = [backendless.data ofTable:@"DeviceRegistration"];
    [dataStore find:queryBuilder response:^(NSArray *devices) {
        NSMutableArray *deviceIds = [NSMutableArray new];
        for (NSDictionary *device in devices)
        {
            NSString *deviceId = [device objectForKey:@"deviceId"];
            [deviceIds addObject:deviceId];
        }
        
        if (deviceIds.count > 0)
        {
            NSString *updateType = @"";
            NSString *updateContent = @"";
            if (signalUpdate == SignalUpdateNewComment)
            {
                updateType = NSLocalizedString(@"New comment", nil);
                updateContent = newComment;
            }
            else if (signalUpdate == SignalUpdateNewStatus)
            {
                updateType = NSLocalizedString(@"New status", nil);
                updateContent = [FINSignal localizedStatusString:newStatus];
            }
            
            PublishOptions *publishOptions = [PublishOptions new];
            [publishOptions assignHeaders:@{@"android-ticker-text":updateType,
                                            @"android-content-title":signal.title,
                                            @"android-content-text":updateContent,
                                            @"ios-alert":updateContent,
                                            @"ios-alert-title":updateType,
                                            @"ios-alert-subtitle":signal.title,
                                            @"ios-alert-body":updateContent,
                                            @"ios-badge":@1,
                                            @"ios-sound":@"default",
                                            @"signalId":signal.geoPoint.objectId,
                                            @"ios-category":kNotificationCategoryNewSignal}];
            
            DeliveryOptions *deliveryOptions = [DeliveryOptions new];
            deliveryOptions.pushSinglecast = deviceIds;
            
            [backendless.messaging publish:[self getCurrentNotificationChannel]
                                   message:updateContent
                            publishOptions:publishOptions
                           deliveryOptions:deliveryOptions
                                  response:^(MessageStatus *status) {
                NSLog(@"Status: %@", status);
            }
                                     error:^(Fault *fault) {
                NSLog(@"Server reported an error: %@", fault);
            }];
        }
        
        if (devices.count == kPageSize) {
            [self sendPushNotificationsWith:queryBuilder
                offset:(offset + kPageSize)
             forSignal:signal
            updateType:signalUpdate
             newStatus:newStatus
            newComment:newComment];
        }
        
    } error:^(Fault *fault) {
        NSLog(@"Error executing query: %@", fault.message);
    }];
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
