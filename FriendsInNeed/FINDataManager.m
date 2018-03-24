//
//  FINDataManager.m
//  FriendsInNeed
//
//  Created by Milen on 29/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINDataManager.h"

#define kMinimumDistanceTravelled   300
#define kLastSignalCheckLocation    @"LastSignalCheckLocation"
#define kSignalPhotosDirectory      @"signal_photos"

#import <SDWebImage/UIImageView+WebCache.h>


@interface FINDataManager ()

@property (strong, nonatomic) CLLocation *lastSignalCheckLocation;

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

- (id)init
{
    self = [super init];
    
    _nearbySignals = [NSMutableArray new];
    
    _lastSignalCheckLocation = [self loadLastSignalCheckLocation];
    
    NSNumber *isValidUserToken = @NO;
    @try {
        isValidUserToken = [backendless.userService isValidUserToken];
        if ([isValidUserToken boolValue] == NO)
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

- (void)saveLastSignalCheckLocation:(CLLocation *)location
{
    NSData *locationData = [NSKeyedArchiver archivedDataWithRootObject:location];
    [[NSUserDefaults standardUserDefaults] setObject:locationData forKey:kLastSignalCheckLocation];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    _lastSignalCheckLocation = location;
}

- (CLLocation *)loadLastSignalCheckLocation
{
    CLLocation *lastLocation = nil;
    @try
    {
        NSData *locationData = [[NSUserDefaults standardUserDefaults] objectForKey:kLastSignalCheckLocation];
        lastLocation = (CLLocation *)[NSKeyedUnarchiver unarchiveObjectWithData:locationData];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Couldn't read last location. Exception: %@", exception.description);
    }
    
    return lastLocation;
}

- (void)getSignalsForLocation:(CLLocation *)location withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    GEO_POINT center;
    center.latitude = location.coordinate.latitude;
    center.longitude = location.coordinate.longitude;
    BackendlessGeoQuery *query = [BackendlessGeoQuery queryWithPoint:center radius:kDefaultMapRegion units:METERS categories:nil];
    query.includeMeta = @YES;
    NSDate *threeDaysAgo = [NSDate dateWithTimeIntervalSinceNow:-(60 * 60 * 24 * 3)];
    query.whereClause = [NSString stringWithFormat:@"dateSubmitted > %lu", (long)([threeDaysAgo timeIntervalSince1970]*1000)];
    
#ifdef DEBUG
    NSMutableArray *cats = [NSMutableArray new];
    [cats addObject:@"Debug"];
    query.categories = cats;
#endif
    
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
            for (FINSignal *signal in _nearbySignals)
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
        
        _nearbySignals = [NSMutableArray arrayWithArray:tempNearbySignals];
        
        // If application is currently active show received signals on map
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
        {
            [_mapDelegate updateMapWithNearbySignals:_nearbySignals];
            if (completionHandler)
            {                
                completionHandler(UIBackgroundFetchResultNewData);
            }
        }
        else
        {
            if (newSignals.count > 0)
            {
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_nearbySignals.count];
                
                for (FINSignal *signal in newSignals)
                {
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertBody  = signal.title;
                    localNotification.userInfo = [NSDictionary dictionaryWithObject:signal.signalID forKey:kNotificationSignalID];
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }
                
                if (completionHandler)
                {
                    completionHandler(UIBackgroundFetchResultNewData);
                }
            }
            else
            {
                if (completionHandler)
                {
                    completionHandler(UIBackgroundFetchResultNoData);
                }
            }
        }
        
        [self saveLastSignalCheckLocation:location];
    } error:^(Fault *fault) {
        NSLog(@"%@", fault.description);
        
        _lastSignalCheckLocation = nil;
        
        if (completionHandler != nil)
        {
            completionHandler(UIBackgroundFetchResultFailed);
        }
    }];
    
    _lastSignalCheckLocation = location;
}

- (void)getSignalsForNewLocation:(CLLocation *)location withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // Do not check if delta distance is below threshold
    if (   (_lastSignalCheckLocation != nil)
        && ([_lastSignalCheckLocation distanceFromLocation:location] < kMinimumDistanceTravelled)   )
    {
        return;
    }
    else
    {
        [self getSignalsForLocation:location withCompletionHandler:completionHandler];
    }
}

- (void)getNewSignalsForLastLocationWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if (_lastSignalCheckLocation != nil)
    {
        [self getSignalsForLocation:_lastSignalCheckLocation withCompletionHandler:completionHandler];
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
#ifdef DEBUG
    [cats addObject:@"Debug"];
#endif
    GeoPoint *point = [GeoPoint geoPoint:coordinate categories:cats metadata:geoPointMeta];
    
    [backendless.geoService savePoint:point response:^(GeoPoint *savedGeoPoint) {
        
        FINSignal *savedSignal = [[FINSignal alloc] initWithGeoPoint:savedGeoPoint];
        [_nearbySignals addObject:savedSignal];
        
        if (photo)
        {
            NSString *fileName = [NSString stringWithFormat:@"%@/%@.jpg", kSignalPhotosDirectory, savedSignal.signalID];
            [backendless.fileService saveFile:fileName content:UIImageJPEGRepresentation(photo, 0.1) response:^(BackendlessFile *savedFile) {
                savedSignal.photoUrl = [NSURL URLWithString:savedFile.fileURL];
                [[SDImageCache sharedImageCache] storeImage:photo forKey:savedFile.fileURL completion:^{
                    completion(savedSignal, nil);
                }];
            } error:^(Fault *fault) {
                
                FINError *error = [[FINError alloc] initWithFault:fault];
                completion(savedSignal, error);
            }];
        }
        else
        {
            completion(savedSignal, nil);
        }
        
    } error:^(Fault *fault) {
        
        FINError *error = [[FINError alloc] initWithFault:fault];
        completion(nil, error);
    }];
}

- (void)setStatus:(FINSignalStatus)status forSignal:(FINSignal *)signal completion:(void (^)(FINError *error))completion
{
    GeoPoint *point = [signal geoPoint];
    [point.metadata setObject:[NSString stringWithFormat:@"%lu", (unsigned long)status] forKey:kSignalStatusKey];
    
    [backendless.geoService savePoint:point response:^(GeoPoint *returnedGeoPoint) {
        
        signal.geoPoint = returnedGeoPoint;
        completion(nil);
    } error:^(Fault *fault) {
        
        FINError *error = [[FINError alloc] initWithFault:fault];
        completion(error);
    }];
}

- (void)getSignalWithID:(NSString *)signalID completion:(void (^)(FINSignal *signal, FINError *error))completion
{
    NSMutableArray *cats = [NSMutableArray new];
#ifdef DEBUG
    [cats addObject:@"Debug"];
#endif
    
    BackendlessGeoQuery *query = [BackendlessGeoQuery queryWithCategories:cats];
    query.whereClause = [NSString stringWithFormat:@"objectid='%@'", signalID];
    [query includeMeta:YES];
    [backendless.geoService getPoints:query response:^(NSArray<GeoPoint *> *geoPoints) {
        
        if (geoPoints.count > 0)
        {
            GeoPoint *geoPoint = (GeoPoint *) geoPoints.firstObject;
            FINSignal *signal = [[FINSignal alloc] initWithGeoPoint:geoPoint];
            signal.photoUrl = [self getPhotoUrlForSignal:signal];
            
            completion(signal, nil);
        }
    } error:^(Fault *fault) {
        
        FINError *error = [[FINError alloc] initWithFault:fault];
        completion(nil, error);
    }];
}

- (BOOL)userIsLogged
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    
    return (currentUser != nil);
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

- (void)registerUser:(NSString *)name withEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(FINError *error))completion
{
    BackendlessUser *user = [BackendlessUser new];
    user.name = name;
    user.email = email;
    user.password = password;
    
    //TODO: check if registration works
    [backendless.userService registerUser:user response:^void (BackendlessUser *registeredUser) {
        
        completion(nil);
    } error:^void (Fault *fault) {
        
        FINError *error = [[FINError alloc] initWithFault:fault];
        completion(error);
    }];
}

- (void)loginWithEmail:(NSString *)email andPassword:(NSString *)password completion:(void (^)(FINError *error))completion
{
    [backendless.userService login:email password:password response:^void (BackendlessUser *loggeduser) {
        
        completion(nil);
    } error:^void (Fault *fault) {
        
        FINError *error = [[FINError alloc] initWithFault:fault];
        completion(error);
    }];
}

- (void)logoutWithCompletion:(void (^)(FINError *error))completion
{
    [backendless.userService logout:^void (id idOfSomething) {
        completion(nil);
    } error:^void (Fault *fault) {
        FINError *error = [[FINError alloc] initWithFault:fault];
        completion(error);
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
        completion(comments, nil);
    } error:^(Fault *fault) {
        FINError *error = [[FINError alloc] initWithFault:fault];
        completion(nil, error);
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
            comment.author = author;
            completion(comment, nil);
        } error:^(Fault *fault) {
            FINError *error = [[FINError alloc] initWithFault:fault];
            completion(nil, error);
        }];
    } error:^(Fault *fault) {
        
        FINError *error = [[FINError alloc] initWithFault:fault];
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

@end
