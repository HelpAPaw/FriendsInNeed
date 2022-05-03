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
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <Backendless-Swift.h>
#import "RLMSignal.h"
@import UserNotifications;
@import FirebaseCrashlytics;

#define kMinimumDistanceTravelled   300
#define kSignalPhotosDirectory      @"signal_photos"
#define kCommentPhotosDirectory     @"comment_photos"
#define kIsInTestModeKey            @"kIsInTestModeKey"
#define kSettingRadiusKey           @"kSettingRadiusKey"
#define kSettingRadiusDefault       10
#define kSettingTimeoutKey          @"kSettingTimeoutKey"
#define kSettingTimeoutDefault      7
#define kSettingTypesKey            @"kSettingTypesKey"
#define kMaxSignalTypesPadding      65535
#define kDeviceRegistrationIdKey    @"kDeviceRegistrationIdKey"
#define kDeviceTokenKey             @"kDeviceTokenKey"
#define kPageSize                   100
#define kAppLaunchCounterKey        @"kAppLaunchCounterKey"

#define kField_ObjectId             @"objectId"
#define kField_Author               @"author"
#define kField_AuthorPhone          @"authorPhone"
#define kField_SignalType           @"signalType"
#define kField_Location             @"location"
#define kField_Status               @"status"
#define kField_Title                @"title"
#define kField_Type                 @"type"
#define kField_Created              @"created"
#define kField_SignalRadius         @"signalRadius"
#define kField_SignalTimeout        @"signalTimeout"
#define kField_SignalTypes          @"signalTypes"
#define kField_LastLocation         @"lastLocation"
#define kField_SignalId             @"signalID"
#define kField_Text                 @"text"
#define kField_Type                 @"type"
#define kField_Photo                @"photo"
#define kField_IsDeleted            @"isDeleted"


#define kTable_DeviceRegistration   @"DeviceRegistration"
#define kTable_Comments             @"FINComment"


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
@property (strong, nonatomic) NSArray<NSNumber *> *typesSetting;

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
    
    NSURL *signalTypesUrl = [NSBundle.mainBundle URLForResource:@"SignalTypes" withExtension:@"plist"];
    _signalTypes = [NSArray arrayWithContentsOfURL:signalTypesUrl];
    
    [self loadSettings];
    
    // Setup Backendless
    [Backendless.shared initAppWithApplicationId:BCKNDLSS_APP_ID apiKey:BCKNDLSS_IOS_API_KEY];
    [Backendless.shared.userService setStayLoggedIn:YES];
    [Backendless.shared.userService isValidUserTokenWithResponseHandler:^(BOOL isValidUserToken) {
        if (isValidUserToken == NO)
        {
            [self logoutWithCompletion:^(FINError *error) {
                //Do nothing
            }];
        }
    } errorHandler:^(Fault * _Nonnull fault) {
        //Do nothing
    }];
    
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
        NSMutableDictionary *deviceRegistration = [NSMutableDictionary new];
        [deviceRegistration setValue:deviceRegistrationId forKey:kField_ObjectId];
        [deviceRegistration setValue:[NSNumber numberWithInteger:_radius] forKey:kField_SignalRadius];
        [deviceRegistration setValue:[NSNumber numberWithInteger:_timeout] forKey:kField_SignalTimeout];
        NSNumber *typesNumber = [NSNumber numberWithInteger:[self convertTypesBoolArrayToInt:_typesSetting]];
        [deviceRegistration setValue:typesNumber forKey:kField_SignalTypes];
        if (location != nil) {
            NSString *lastLocation = [self getWktPointWithLongitude:self.lastSavedDeviceLocation.coordinate.longitude
                                                        andLatitude:self.lastSavedDeviceLocation.coordinate.latitude];
            [deviceRegistration setValue:lastLocation forKey:kField_LastLocation];
        }
        
        MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:kTable_DeviceRegistration];
        [dataStore saveWithEntity:deviceRegistration
                    responseHandler:^(NSDictionary *updatedObject) {
            NSLog(@"Object has been updated: %@", updatedObject); }
                       errorHandler:^(Fault *fault) {
            NSLog(@"Server reported an error: %@", fault);
        }];
    }
}

- (NSString *)getWktPointWithLongitude:(double)longitude andLatitude:(double)latitude
{
    return [NSString stringWithFormat:@"Point (%.15f %.15f)", longitude, latitude];
}

- (NSURL *)getPhotoUrlForSignal:(FINSignal *)signal
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://api.backendless.com/%@/%@/files/%@/%@.jpg", BCKNDLSS_APP_ID, BCKNDLSS_REST_API_KEY, kSignalPhotosDirectory, signal.signalId]];
}

- (FINSignal *)signalFromDictionary:(NSDictionary *)signalDict
{
    FINSignal *parsedSignal = [FINSignal new];
    parsedSignal.signalId = [signalDict objectForKey:kField_ObjectId];
    parsedSignal.title = [signalDict objectForKey:kField_Title];
    NSNumber *typeNumber = [signalDict objectForKey:kField_SignalType];
    parsedSignal.type = typeNumber.integerValue;
    NSNumber *statusNumber = [signalDict objectForKey:kField_Status];
    parsedSignal.status = [statusNumber intValue];
    BLPoint *locationPoint = [signalDict objectForKey:kField_Location];
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = locationPoint.latitude;
    coordinate.longitude = locationPoint.longitude;
    parsedSignal.coordinate = coordinate;
    parsedSignal.authorPhone = [signalDict objectForKey:kField_AuthorPhone];
    BackendlessUser *author = [signalDict objectForKey:kField_Author];
    if ((author != nil) && ([author isKindOfClass:[BackendlessUser class]])) {
        parsedSignal.authorId = author.objectId;
        parsedSignal.authorName = author.name;
    }
    NSNumber *createdTimestampNumber = [signalDict objectForKey:kField_Created];
    parsedSignal.dateCreated = [NSDate dateWithTimeIntervalSince1970:createdTimestampNumber.longValue/1000];
    parsedSignal.photoUrl = [self getPhotoUrlForSignal:parsedSignal];
    
    return parsedSignal;
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
    
    NSString *wktPoint = [self getWktPointWithLongitude:location.coordinate.longitude andLatitude:location.coordinate.latitude];
    NSString *whereClause1 = [NSString stringWithFormat:@"distanceOnSphere(location, '%@') <= %ld", wktPoint, radius * 1000];
    
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24 * self.timeout)];
    NSString *whereClause2 = [NSString stringWithFormat:@"%@ > %lu", kField_Created, (long)([timeoutDate timeIntervalSince1970] * 1000)];
    
    NSString *whereClause3 = [NSString stringWithFormat:@"%@ = %@", kField_IsDeleted, @"FALSE"];
    
    DataQueryBuilder *queryBuilder = [DataQueryBuilder new];
    [queryBuilder setWhereClause:[NSString stringWithFormat:@"(%@) AND (%@) AND (%@)", whereClause1, whereClause2, whereClause3]];
    
    NSLog(@"Get signals for location: %@", location);
    [self getSignalsWithQueryBuilder:queryBuilder
               withCompletionHandler:^(NSArray<NSDictionary<NSString *,id> *> *result, FINError *error) {
        if (error == nil) {
            NSLog(@"Received %lu signals", (unsigned long)result.count);
            
            NSMutableArray *newSignals = [NSMutableArray new];
            NSMutableArray *tempNearbySignals = [NSMutableArray new];
            for (NSDictionary *signalDict in result)
            {
                FINSignal *receivedSignal = [self signalFromDictionary:signalDict];

                // Check if the signal is already present
                BOOL alreadyPresent = NO;
                for (FINSignal *signal in self.nearbySignals)
                {
                    if ([signal.signalId isEqualToString:receivedSignal.signalId])
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

                // Add all received signals to a temp array that will replace newarbySignals when enumeration is finished
                [tempNearbySignals addObject:receivedSignal];
            }

            self.nearbySignals = [NSMutableArray arrayWithArray:tempNearbySignals];

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
                    NSInteger typesSettingInt = [self convertTypesBoolArrayToInt:self.typesSetting];
                    for (FINSignal *signal in newSignals)
                    {
                        BOOL notificationAlreadyShown = [FINDataManager setNotificationShownForSignalId:signal.signalId];
                        if (notificationAlreadyShown)
                        {
                            continue;
                        }

                        // Only show notifications about signals that haven't been solved yet
                        if ((signal.status < FINSignalStatus2) &&
                            ([self shouldNotifyAboutSignalType:signal.type withSettings:typesSettingInt]))
                        {
                            badgeNumber++;

                            // Create local notification and show it
                            UNMutableNotificationContent *notifContent = [UNMutableNotificationContent new];
                            notifContent.body = signal.title;
                            notifContent.sound = [UNNotificationSound defaultSound];
                            notifContent.categoryIdentifier = kNotificationCategoryNewSignal;

                            NSMutableDictionary *userInfo = [NSMutableDictionary new];
                            [userInfo setObject:signal.signalId forKey:kSignalId];
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
        } else {
            CLS_LOG(@"[FIN] Getting signals failed with error: %@", error.message);
            
            self.lastSignalCheckLocation = nil;
            
            if (completionHandler != nil)
            {
                CLS_LOG(@"[FIN] Calling background fetch completion handler: %@", completionHandler);
                completionHandler(UIBackgroundFetchResultFailed);
            }
        }
    }];
}

- (void)getSignalsWithQueryBuilder:(DataQueryBuilder *)queryBuilder withCompletionHandler:(void (^)(NSArray<NSDictionary<NSString *,id> *> *result, FINError *error))completion
{
    queryBuilder.pageSize = kPageSize;
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:[self getSignalsTableName]];
    [dataStore findWithQueryBuilder:queryBuilder
                    responseHandler:^(NSArray<NSDictionary<NSString *,id> *> *result) {
        if (result.count == kPageSize) {
            queryBuilder.offset += kPageSize;
            [self getSignalsWithQueryBuilder:queryBuilder withCompletionHandler:^(NSArray<NSDictionary<NSString *,id> *> *nextPageResult, FINError *error) {
                if (error == nil) {
                    NSMutableArray *combinedResult = [NSMutableArray arrayWithArray:result];
                    [combinedResult addObjectsFromArray:nextPageResult];
                    completion(combinedResult, nil);
                } else {
                    completion(nil, error);
                }
            }];
        } else {
            completion(result, nil);
        }
    }
                       errorHandler:^(Fault *fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(nil, error);
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

- (void)getCountForSignalsWithStatus:(FINSignalStatus)status withCompletionHandler:(void (^)(NSInteger count, FINError *error))completion
{
    DataQueryBuilder *queryBuilder = [DataQueryBuilder new];
    queryBuilder.whereClause = [NSString stringWithFormat:@"%@ = '%lu'", kField_Status, (unsigned long)status];
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:[self getSignalsTableName]];
    [dataStore getObjectCountWithQueryBuilder:queryBuilder
                              responseHandler:^(NSInteger count) {
        completion(count, nil);
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(0, error);
    }];
}

- (void)getTotalSignalCountWithCompletionHandler:(void (^)(NSInteger count, FINError *error))completion
{
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:[self getSignalsTableName]];
    [dataStore getObjectCountWithResponseHandler:^(NSInteger count) {
        completion(count, nil);
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(0, error);
    }];
}

- (void)uploadPhoto:(UIImage *)photo
          forSignal:(FINSignal *)signal
     withCompletion:(void (^)(FINError *error))completion
{
    [self uploadPhoto:photo
         withFilename:[NSString stringWithFormat:@"%@.jpg", signal.signalId]
          inDirectory:kSignalPhotosDirectory
       withCompletion:^(NSString *urlString, FINError *error) {
        if (error == nil) {
            signal.photoUrl = [NSURL URLWithString:urlString];
            completion(nil);
        } else {
            completion(error);
        }
    }];
}

- (void)uploadPhoto:(UIImage *)photo
          forComment:(FINComment *)comment
     withCompletion:(void (^)(FINError *error))completion
{
    [self uploadPhoto:photo
         withFilename:[NSString stringWithFormat:@"%@.jpg", comment.objectId]
          inDirectory:kCommentPhotosDirectory
       withCompletion:^(NSString *urlString, FINError *error) {
        if (error == nil) {
            MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:kTable_Comments];
            NSMutableDictionary *changes = [NSMutableDictionary new];
            [changes setObject:urlString forKey:kField_Photo];
            [changes setObject:comment.objectId forKey:kField_ObjectId];
            [dataStore saveWithEntity:changes
                        responseHandler:^(NSDictionary<NSString *,id> * _Nonnull updatedComment) {
                comment.photoUrl = [NSURL URLWithString:urlString];
                completion(nil);
            } errorHandler:^(Fault * _Nonnull fault) {
                FINError *error = [[FINError alloc] initWithMessage:fault.message];
                completion(error);
            }];
        }
        else {
            completion(error);
        }
    }];
}

- (void)uploadPhoto:(UIImage *)photo
       withFilename:(NSString *)filename
        inDirectory:(NSString *)directory
     withCompletion:(void (^)(NSString *urlString, FINError *error))completion
{
    [Backendless.shared.fileService uploadFileWithFileName:filename
                                                  filePath:directory
                                               fileContent:UIImageJPEGRepresentation(photo, 0.1)
                                                 overwrite:YES
                                           responseHandler:^(BackendlessFile * _Nonnull savedFile) {
        [[SDImageCache sharedImageCache] storeImage:photo forKey:savedFile.fileUrl completion:^{
            completion(savedFile.fileUrl, nil);
        }];
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(nil, error);
    }];
}

- (void)submitNewSignalWithTitle:(NSString *)title
                            type:(NSInteger)type
                  andAuthorPhone:(NSString *)authorPhone
                     forLocation:(CLLocationCoordinate2D)locationCoordinate
                       withPhoto:(UIImage *)photo
                      completion:(void (^)(FINSignal *savedSignal, FINError *error))completion
{
    BackendlessUser *currentUser = Backendless.shared.userService.currentUser;

    NSDictionary *signalData = @{kField_Title:title,
                                 kField_SignalType: [NSNumber numberWithInteger:type],
                                 kField_AuthorPhone:authorPhone,
                                 kField_Location:[self getWktPointWithLongitude:locationCoordinate.longitude andLatitude:locationCoordinate.latitude],
                                   kField_Status:@0};
    
    
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:[self getSignalsTableName]];
    [dataStore saveWithEntity:signalData responseHandler:^(NSDictionary<NSString *,id> * _Nonnull savedSignalDict) {
        
        [dataStore setRelationWithColumnName:kField_Author
                              parentObjectId:savedSignalDict[kField_ObjectId]
                           childrenObjectIds:@[currentUser.objectId]
                             responseHandler:^(NSInteger relations) {
            NSMutableDictionary *relatedSignalDict = [NSMutableDictionary dictionaryWithDictionary:savedSignalDict];
            [relatedSignalDict setObject:currentUser forKey:kField_Author];
            FINSignal *savedSignal = [self signalFromDictionary:relatedSignalDict];
            [self.nearbySignals addObject:savedSignal];

            if (photo)
            {
                [self uploadPhoto:photo forSignal:savedSignal withCompletion:^(FINError *uploadError) {
                    completion(savedSignal, uploadError);
                }];
            }
            else
            {
                completion(savedSignal, nil);
            }

            //Send push notifications to all interested devices in the area
            [self sendPushNotificationsForNewSignal:savedSignal];
        } errorHandler:^(Fault * _Nonnull fault) {
            FINError *error = [[FINError alloc] initWithMessage:fault.message];
            completion(nil, error);
        }];
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(nil, error);
    }];
}

- (void)setStatus:(FINSignalStatus)status forSignal:(FINSignal *)signal withCurrentComments:(NSArray<FINComment *> *)currentComments completion:(void (^)(FINError *error))completion
{
    CLS_LOG(@"Set new status for signal %@", signal.signalId);
    
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:[self getSignalsTableName]];
    NSMutableDictionary *changes = [NSMutableDictionary new];
    [changes setObject:[NSNumber numberWithUnsignedInteger:status] forKey:kField_Status];
    [changes setObject:signal.signalId forKey:kField_ObjectId];
    [dataStore saveWithEntity:changes
        responseHandler:^(NSDictionary<NSString *,id> * _Nonnull updatedSignal) {
            [self sendPushNotificationsForNewStatus:status onSignal:signal withCurrentComments:currentComments];
            signal.status = status;
            completion(nil);
        } errorHandler:^(Fault * _Nonnull fault) {
            FINError *error = [[FINError alloc] initWithMessage:fault.message];
            completion(error);
        }];
}

- (void)deleteSignal:(FINSignal *)signal withCompletion:(void (^)(FINError *error))completion
{
    CLS_LOG(@"Delete signal %@", signal.signalId);
    
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:[self getSignalsTableName]];
    NSMutableDictionary *changes = [NSMutableDictionary new];
    [changes setObject:@YES forKey:kField_IsDeleted];
    [changes setObject:signal.signalId forKey:kField_ObjectId];
    [dataStore saveWithEntity:changes
              responseHandler:^(NSDictionary<NSString *,id> * _Nonnull updatedSignal) {
        [self.nearbySignals removeObject:signal];
        completion(nil);
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(error);
    }];
}

- (void)getSignalWithID:(NSString *)signalId completion:(void (^)(FINSignal *signal, FINError *error))completion
{
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:[self getSignalsTableName]];
    [dataStore findByIdWithObjectId:signalId
                    responseHandler:^(NSDictionary<NSString *,id> * _Nonnull signalDict) {
        
        FINSignal *signal = [self signalFromDictionary:signalDict];
        completion(signal, nil);
        
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(nil, error);
    }];
}

- (BOOL)userIsLogged
{    
    return Backendless.shared.userService.currentUser != nil;
}

- (BOOL)getUserHasAcceptedPrivacyPolicy
{
    BackendlessUser *currentUser = Backendless.shared.userService.currentUser;
    if (currentUser != nil)
    {
        NSNumber *acceptedPrivacyPolicy = currentUser.properties[kUserPropertyAcceptedPrivacyPolicy];
        return [acceptedPrivacyPolicy boolValue];
    }
    
    return NO;
}

- (void)setUserHasAcceptedPrivacyPolicy:(BOOL)value
{
    BackendlessUser *currentUser = Backendless.shared.userService.currentUser;
    if (currentUser != nil)
    {
        NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:currentUser.properties];
        [properties setObject:[NSNumber numberWithBool:value] forKey:kUserPropertyAcceptedPrivacyPolicy];
        currentUser.properties = properties;
        [Backendless.shared.userService updateWithUser:currentUser responseHandler:^(BackendlessUser * _Nonnull updatedUser) {
            //Do nothing, be happy
            NSLog(@"Successfully saved privacy policy acceptance!");
        } errorHandler:^(Fault * _Nonnull fault) {
            //Do nothing, be sad
            CLS_LOG(@"Could not save privacy policy acception: %@", fault.message);
        }];
    }
}

- (NSString *)getUserId
{
    return Backendless.shared.userService.currentUser.objectId;
}

- (NSString *)getUserName
{
    return Backendless.shared.userService.currentUser.name;
}

- (NSString *)getUserEmail
{
    return Backendless.shared.userService.currentUser.email;
}

- (NSString *)getUserPhone
{
    BackendlessUser *currentUser = Backendless.shared.userService.currentUser;
    if (currentUser != nil)
    {
        NSString *phone = currentUser.properties[kUserPropertyPhoneNumber];
        if ([phone isKindOfClass:[NSString class]]) {
            return phone;
        }
    }
    
    return @"";
}

- (void)registerUser:(NSString *)name withEmail:(NSString *)email password:(NSString *)password phoneNumber:(NSString *)phoneNumber completion:(void (^)(FINError *error))completion
{
    BackendlessUser *user = [BackendlessUser new];
    user.name = name;
    user.email = email;
    user.password = password;
    NSMutableDictionary *properties = [NSMutableDictionary new];
    [properties setObject:phoneNumber forKey:kUserPropertyPhoneNumber];
    [properties setObject:[NSNumber numberWithBool:YES] forKey:kUserPropertyAcceptedPrivacyPolicy];
    [user setProperties:properties];

    [Backendless.shared.userService registerUserWithUser:user
                                         responseHandler:^(BackendlessUser * _Nonnull registeredUser) {
        completion(nil);
    }
                                            errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(error);
    }];
}

- (void)handleUserLoggedIn:(BackendlessUser *)loggedUser
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUserLoggedIn
                                                        object:nil];
    
    [FIRCrashlytics.crashlytics setUserID:loggedUser.objectId];
}

- (void)loginWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(FINError *error))completion
{
    [Backendless.shared.userService loginWithIdentity:email
                                             password:password
                                      responseHandler:^(BackendlessUser * _Nonnull loggedUser) {
        [self handleUserLoggedIn:loggedUser];
        completion(nil);
        
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(error);
    }];
}

- (void)loginWithFacebookAccessToken:(NSString *)tokenString completion:(void (^)(FINError *error))completion
{
    NSDictionary *fieldsMapping = @{@"email":@"email"};
    [Backendless.shared.userService loginWithOauth2WithProviderCode:@"facebook"
                                                        accessToken:tokenString
                                                      fieldsMapping:fieldsMapping
                                                       stayLoggedIn:YES
                                                    responseHandler:^(BackendlessUser * _Nonnull loggedUser) {
        [self handleUserLoggedIn:loggedUser];
        completion(nil);
        
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(error);
    }];
}

- (void)loginWithGoogleToken:(NSString *)tokenString completion:(void (^)(FINError *error))completion
{
    NSDictionary *fieldsMapping = @{@"email":@"email"};
    [Backendless.shared.userService loginWithOauth2WithProviderCode:@"googleplus"
                                                        accessToken:tokenString
                                                      fieldsMapping:fieldsMapping
                                                       stayLoggedIn:YES
                                                    responseHandler:^(BackendlessUser * _Nonnull loggedUser) {
        [self handleUserLoggedIn:loggedUser];
        completion(nil);
        
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(error);
    }];
}

- (void)loginWithAppleToken:(NSString *)tokenString completion:(void (^)(FINError *error))completion;
{
    [Backendless.shared.customService invokeWithServiceName:@"AppleAuth"
                                                     method:@"login"
                                                 parameters:tokenString
                                            responseHandler:^(BackendlessUser *loggedUser) {
         Backendless.shared.userService.currentUser = loggedUser;
        [self handleUserLoggedIn:loggedUser];
        completion(nil);
        
     }
                                               errorHandler:^(Fault *fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(error);
     }];
}

- (void)logoutWithCompletion:(void (^)(FINError *error))completion
{
    [Backendless.shared.userService logoutWithResponseHandler:^{
        completion(nil);
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(error);
    }];
}

- (void)resetPasswordForEmail:(NSString *)email withCompletion:(void (^)(FINError *error))completion
{
    [Backendless.shared.userService restorePasswordWithIdentity:email
                                                responseHandler:^{
        completion(nil);
    }
                                                   errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(error);
    }];
}

// Public method for getting signal comments
- (void)getCommentsForSignal:(FINSignal *)signal completion:(void (^)(NSArray *comments, FINError *error))completion
{
    DataQueryBuilder *queryBuilder = [DataQueryBuilder new];
    [queryBuilder setWhereClause:[NSString stringWithFormat:@"signalId = \'%@\'", signal.signalId]];
    [queryBuilder setSortBy:@[kField_Created]];
    [queryBuilder addRelatedWithRelated:kField_Author];
    [queryBuilder setPageSize:kPageSize];
    
    [self getCommentsWithQuery:queryBuilder offset:0 response:^(NSArray *comments) {
        completion(comments, nil);
    } error:^(FINError *error) {
        completion(nil, error);
    }];
}

- (FINComment *)parseComment:(NSDictionary *)commentDict {
    FINComment *comment = [FINComment new];
    comment.text = [commentDict objectForKey:kField_Text];
    comment.type = [commentDict objectForKey:kField_Type];
    comment.objectId = [commentDict objectForKey:kField_ObjectId];
    NSNumber *createdTimestamp = [commentDict objectForKey:kField_Created];;
    comment.created = [NSDate dateWithTimeIntervalSince1970:createdTimestamp.doubleValue/1000];
    comment.signalId = [commentDict objectForKey:kField_SignalId];
    BackendlessUser *author = [commentDict objectForKey:kField_Author];    
    if ((author != nil) && ![author isKindOfClass:NSNull.class]) {
        comment.authorId = author.objectId;
        comment.authorName = author.name;
    }
    NSString *urlString = [commentDict objectForKey:kField_Photo];
    if ((urlString != nil) && ([urlString isKindOfClass:[NSString class]])) {
        comment.photoUrl = [NSURL URLWithString:urlString];
    }
    return comment;
}

// Internal method to recursively getting all pages with comments
- (void)getCommentsWithQuery:(DataQueryBuilder *)queryBuilder offset:(int)offset response:(void (^)(NSArray *comments))response error:(void (^)(FINError *error))failure
{
    [queryBuilder setOffset:offset];
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:kTable_Comments];
    [dataStore findWithQueryBuilder:queryBuilder
                    responseHandler:^(NSArray<NSDictionary<NSString *,id> *> * _Nonnull commentsDicts) {
        NSMutableArray *comments = [NSMutableArray new];
        for (NSDictionary *commentDict in commentsDicts) {
            [comments addObject:[self parseComment:commentDict]];
        }
        
        if (comments.count == kPageSize)
        {
            [self getCommentsWithQuery:queryBuilder offset:(offset + kPageSize) response:^(NSArray *comments2) {
                [comments addObjectsFromArray:comments2];
                response(comments);
            } error:^(FINError *error) {
                failure(error);
            }];
        }
        else
        {
            response(comments);
        }

    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *err = [[FINError alloc] initWithMessage:fault.message];
        failure(err);
    }];
}

- (void)saveComment:(NSString *)commentText forSignal:(FINSignal *)signal withCurrentComments:(NSArray<FINComment *> *)currentComments completion:(void (^)(FINComment *comment, FINError *error))completion
{
    CLS_LOG(@"Add new comment for signal %@", signal.signalId);
    
    NSMutableDictionary *commentDict = [NSMutableDictionary new];
    [commentDict setObject:commentText forKey:kField_Text];
    [commentDict setObject:signal.signalId forKey:kField_SignalId];
    
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:kTable_Comments];
    [dataStore saveWithEntity:commentDict
              responseHandler:^(NSDictionary<NSString *,id> * _Nonnull savedCommentDict) {
        
        BackendlessUser *author = Backendless.shared.userService.currentUser;
        [dataStore setRelationWithColumnName:kField_Author
                              parentObjectId:[savedCommentDict objectForKey:kField_ObjectId]
                           childrenObjectIds:@[author.objectId]
                             responseHandler:^(NSInteger relations) {
            NSMutableDictionary *relatedCommentDict = [NSMutableDictionary dictionaryWithDictionary:savedCommentDict];
            [relatedCommentDict setObject:author forKey:kField_Author];
            FINComment *savedComment = [self parseComment:relatedCommentDict];

            [self sendPushNotificationsForNewComment:commentText onSignal:signal withCurrentComments:currentComments];
            
            completion(savedComment, nil);
        } errorHandler:^(Fault * _Nonnull fault) {
            FINError *error = [[FINError alloc] initWithMessage:fault.message];
            completion(nil, error);
        }];
    } errorHandler:^(Fault * _Nonnull fault) {
        FINError *error = [[FINError alloc] initWithMessage:fault.message];
        completion(nil, error);
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

#pragma MARK - TEST Mode

- (BOOL)getIsInTestMode
{
    return _isInTestMode;
}

- (void)setIsInTestMode:(BOOL)isInTestMode
{
    [Backendless.shared.messaging unregisterDeviceWithResponseHandler:^(BOOL isUnregistered) {
        //Do nothing, be happy
    } errorHandler:^(Fault * _Nonnull fault) {
        //DO nothing, be sad
    }];
    
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

#pragma mark - App counter
+ (void)setAppLaunchCounter:(NSInteger)newValue {
    [[NSUserDefaults standardUserDefaults] setInteger:newValue forKey:kAppLaunchCounterKey];
}

+ (NSInteger)getAppLaunchCounter {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kAppLaunchCounterKey];
}

+ (void)incrementAppLaunchCounter {
    NSInteger counter = [self getAppLaunchCounter];
    [self setAppLaunchCounter:++counter];
}

+ (void)resetAppLaunchCounter {
    [self setAppLaunchCounter:0];
}

- (NSString *)getSignalsTableName
{
    if (_isInTestMode)
    {
        return @"SignalsTest";
    }
    else
    {
        return @"Signals";
    }
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
    [Backendless.shared.messaging registerDeviceWithDeviceToken:deviceToken
                                                       channels:@[currentNotificationChannel]
                                                responseHandler:^(NSString * _Nonnull registeredDeviceId) {
        //Get only the objectId part
        NSArray *components = [registeredDeviceId componentsSeparatedByString:@":"];
        [FINDataManager saveDeviceRegistrationId:components[0]];
        [FINDataManager saveDeviceToken:deviceToken];

        [self updateDeviceRegistrationWithLocation:nil];
    } errorHandler:^(Fault * _Nonnull fault) {
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
    //Get all devices within signalRadius of the signal
    NSString *signalLocationAsWKT = [self getWktPointWithLongitude:signal.coordinate.longitude andLatitude:signal.coordinate.latitude];
    [queryBuilder setWhereClause:[NSString stringWithFormat:@"distanceOnSphere( %@, '%@') < signalRadius * 1000", kField_LastLocation, signalLocationAsWKT]];

    [self sendPushNotificationsWith:queryBuilder offset:0 forSignal:signal];
}

// Internal method to recursively send notifications to all pages of interested devices
- (void)sendPushNotificationsWith:(DataQueryBuilder *)queryBuilder offset:(int)offset forSignal:(FINSignal *)signal
{
    [queryBuilder setOffset:offset];
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:kTable_DeviceRegistration];
    [dataStore findWithQueryBuilder:queryBuilder
                    responseHandler:^(NSArray<NSDictionary<NSString *,id> *> * _Nonnull devices) {
        NSMutableArray *deviceIds = [NSMutableArray new];
        for (NSDictionary *device in devices)
        {
            NSString *deviceId = [device objectForKey:@"deviceId"];
            //Skip current device
            if (![Backendless.shared.messaging.currentDevice.deviceId isEqualToString:deviceId])
            {
                NSNumber *signalTypesSetting = [device objectForKey:@"signalTypes"];
                // Notify only users subscribed to this signal type
                if ([self shouldNotifyAboutSignalType:signal.type withSettings:signalTypesSetting.integerValue]) {
                    [deviceIds addObject:deviceId];
                }
            }
        }

        if (deviceIds.count > 0)
        {
            PublishOptions *publishOptions = [PublishOptions new];
            [publishOptions setHeaders:@{@"android-ticker-text":NSLocalizedString(@"New signal", nil),
                                            @"android-content-title":signal.title,
                                            @"ios-alert-title":signal.title,
                                            @"ios-badge":@1,
                                            @"ios-sound":@"default",
                                            @"signalId":signal.signalId,
                                            @"ios-category":kNotificationCategoryNewSignal}];

            DeliveryOptions *deliveryOptions = [DeliveryOptions new];
            deliveryOptions.pushSinglecast = deviceIds;

            [Backendless.shared.messaging publishWithChannelName:[self getCurrentNotificationChannel]
                                                         message:NSLocalizedString(@"New signal", nil)
                                                  publishOptions:publishOptions
                                                 deliveryOptions:deliveryOptions
                                                 responseHandler:^(MessageStatus * _Nonnull status) {
                NSLog(@"Status: %@", status);
            } errorHandler:^(Fault * _Nonnull fault) {
                 NSLog(@"Server reported an error: %@", fault);
            }];
        }

        if (devices.count == kPageSize) {
            [self sendPushNotificationsWith:queryBuilder offset:(offset + kPageSize) forSignal:signal];
        }
    } errorHandler:^(Fault * _Nonnull fault) {
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
    if (signal.authorId != nil) {
        [interestedUserIds addObject:signal.authorId];
    }
    // Add all people that posted comments
    for (FINComment *comment in currentComments)
    {
        if (comment.authorId != nil) {
            [interestedUserIds addObject:comment.authorId];
        }
    }
    // Remove current user
    [interestedUserIds removeObject:Backendless.shared.userService.currentUser.objectId];
    
    if (interestedUserIds.count == 0) {
        return;
    }
    
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
    queryBuilder.offset = offset;
    MapDrivenDataStore *dataStore = [Backendless.shared.data ofTable:kTable_DeviceRegistration];
    [dataStore findWithQueryBuilder:queryBuilder
                    responseHandler:^(NSArray<NSDictionary<NSString *,id> *> * _Nonnull devices) {
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
            [publishOptions setHeaders:@{@"android-ticker-text":updateType,
                                            @"android-content-title":signal.title,
                                            @"android-content-text":updateContent,
                                            @"ios-alert":updateContent,
                                            @"ios-alert-title":updateType,
                                            @"ios-alert-subtitle":signal.title,
                                            @"ios-alert-body":updateContent,
                                            @"ios-badge":@1,
                                            @"ios-sound":@"default",
                                            @"signalId":signal.signalId,
                                            @"ios-category":kNotificationCategoryNewSignal}];

            DeliveryOptions *deliveryOptions = [DeliveryOptions new];
            deliveryOptions.pushSinglecast = deviceIds;

            [Backendless.shared.messaging publishWithChannelName:[self getCurrentNotificationChannel]
                                                         message:updateContent
                                                  publishOptions:publishOptions
                                                 deliveryOptions:deliveryOptions
                                                 responseHandler:^(MessageStatus * _Nonnull status) {
                NSLog(@"Status: %@", status);
            } errorHandler:^(Fault * _Nonnull fault) {
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
    } errorHandler:^(Fault * _Nonnull fault) {
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
    
    NSInteger savedTypesSetting = [[NSUserDefaults standardUserDefaults] integerForKey:kSettingTypesKey];
    savedTypesSetting = savedTypesSetting != 0 ? savedTypesSetting : kMaxSignalTypesPadding;
    _typesSetting = [self convertTypesIntToBoolArray:savedTypesSetting];
}

- (NSInteger)getRadiusSetting
{
    return _radius;
}

- (NSInteger)getTimeoutSetting
{
    return _timeout;
}

- (NSArray<NSNumber *> *)getTypesSetting
{
    return _typesSetting;
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
        // Delete nearby signals so signals that are outside of the new timeout don't remain in cache
        _nearbySignals = [NSMutableArray new];
    }
}

- (void)setTypesSetting:(NSArray<NSNumber *>*)newTypesSetting
{
    if (![_typesSetting isEqualToArray:newTypesSetting]) {
        _typesSetting = newTypesSetting;
        
        NSInteger typesInt = [self convertTypesBoolArrayToInt:_typesSetting];
        [[NSUserDefaults standardUserDefaults] setInteger:typesInt forKey:kSettingTypesKey];
    }    
}

- (NSInteger)convertTypesBoolArrayToInt:(NSArray<NSNumber *>*)boolArray
{
    NSInteger result = 0;
    
    // Put 1 on each position with a positive bool
    for (int i = 0; i < boolArray.count; i++) {
        result |= (boolArray[i].boolValue ? 1 : 0) << i;
    }
    
    // Put 1s on all unused positions so that when new signals are introduced they are automatically subscribed to
    result |= ((kMaxSignalTypesPadding << _signalTypes.count) & kMaxSignalTypesPadding);
    return result;
}

- (NSArray<NSNumber *> *)convertTypesIntToBoolArray:(NSInteger)typesInt
{
    NSMutableArray<NSNumber *> *result = [NSMutableArray new];
    for (int i = 0; i < _signalTypes.count; i++) {
        BOOL typeSetting = ((typesInt >> i) & 1) == 1;
        [result addObject:[NSNumber numberWithBool:typeSetting]];
    }
    
    return result;
}

- (NSString *)getStringForSignalTypesSetting
{
    NSInteger count = 0;
    for (NSNumber *typeSetting in _typesSetting) {
        if (typeSetting.boolValue) {
            count++;
        }
    }
    
    if (count == 0) {
        return NSLocalizedString(@"none_signal_types", nil);
    }
    else if (count == _signalTypes.count) {
        return NSLocalizedString(@"all_signal_types", nil);
    }
    else {
        NSMutableString *result = [NSMutableString new];
        
        for (int i = 0; i < _signalTypes.count; i++) {
            if (_typesSetting[i].boolValue) {
                [result appendFormat:@"%@, ", _signalTypes[i]];
            }
        }
        
        // Remove last comma
        return [result substringWithRange:NSMakeRange(0, result.length - 2)];;
    }
}

- (BOOL)shouldNotifyAboutSignalType:(NSInteger)signalType
                       withSettings:(NSInteger)signalTypeSettings
{
    return ((signalTypeSettings & (1 << signalType)) > 0);
}

- (void)saveSettings
{
    [self updateDeviceRegistrationWithLocation:nil];
}

@end
