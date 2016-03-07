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
    
    _signalDateFormatter = [NSDateFormatter new];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [_signalDateFormatter setLocale:enUSPOSIXLocale];
    [_signalDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [_signalDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    _nearbySignals = [NSMutableArray new];
    
    _lastSignalCheckLocation = [self loadLastSignalCheckLocation];
    
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
    [backendless.geoService getPoints:query response:^(BackendlessCollection *response) {
        NSLog(@"Received %lu signals", (unsigned long)response.data.count);
        
        NSMutableArray *newSignals = [NSMutableArray new];
        NSMutableArray *tempNearbySignals = [NSMutableArray new];
        for (GeoPoint *receivedGeoPoint in response.data)
        {
            if (!receivedGeoPoint)
            {
                continue;
            }
            
            BOOL alreadyPresent = NO;
            for (GeoPoint *oldGeoPoint in _nearbySignals)
            {
                if ([oldGeoPoint.objectId isEqualToString:receivedGeoPoint.objectId])
                {
                    alreadyPresent = YES;
                }
            }
            if (alreadyPresent == NO)
            {
                [newSignals addObject:receivedGeoPoint];
                NSLog(@"New signal: %@", [receivedGeoPoint.metadata objectForKey:kSignalTitleKey]);
            }
            
            [tempNearbySignals addObject:receivedGeoPoint];
        }
        
        _nearbySignals = [NSMutableArray arrayWithArray:tempNearbySignals];
        
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
        {
            [_mapDelegate updateMapWithNearbySignals:_nearbySignals];
        }
        else
        {
            if (newSignals.count > 0)
            {
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_nearbySignals.count];
                
                for (GeoPoint *geoPoint in newSignals)
                {
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertBody  = [geoPoint.metadata objectForKey:kSignalTitleKey];
                    localNotification.userInfo = [NSDictionary dictionaryWithObject:geoPoint.objectId forKey:kNotificationSignalID];
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }
                
                completionHandler(UIBackgroundFetchResultNewData);
            }
            else
            {
                completionHandler(UIBackgroundFetchResultNoData);
            }
        }
        
        [self saveLastSignalCheckLocation:location];
    } error:^(Fault *fault) {
        NSLog(@"%@", fault.description);
        
        _lastSignalCheckLocation = nil;
        
        completionHandler(UIBackgroundFetchResultFailed);
    }];
    
    _lastSignalCheckLocation = location;
}

- (void)getSignalsForNewLocation:(CLLocation *)location
{
    // Do not check if delta distance is below threshold
    if (   (_lastSignalCheckLocation != nil)
        && ([_lastSignalCheckLocation distanceFromLocation:location] < kMinimumDistanceTravelled)   )
    {
        return;
    }
    else
    {
        [self getSignalsForLocation:location withCompletionHandler:nil];
    }
}

- (void)getNewSignalsForLastLocationWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if (_lastSignalCheckLocation != nil)
    {
        [self getSignalsForLocation:_lastSignalCheckLocation withCompletionHandler:completionHandler];
    }
}

- (void)submitNewSignalWithTitle:(NSString *)title forLocation:(CLLocationCoordinate2D)locationCoordinate completion:(void (^)(GeoPoint *savedGeoPoint, Fault *fault))completion
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    
    GEO_POINT coordinate;
    coordinate.latitude = locationCoordinate.latitude;
    coordinate.longitude = locationCoordinate.longitude;
    FINDataManager *dataManager = [FINDataManager sharedManager];
    NSString *submitDate = [dataManager.signalDateFormatter stringFromDate:[NSDate date]];
    NSDictionary *geoPointMeta = @{kSignalTitleKey:title, kSignalAuthorKey:currentUser, kSignalDateSubmittedKey:submitDate};
    GeoPoint *point = [GeoPoint geoPoint:coordinate categories:nil metadata:geoPointMeta];
    
    [backendless.geoService savePoint:point response:^(GeoPoint *returnedGeoPoint) {
        
        [_nearbySignals addObject:returnedGeoPoint];
        completion(returnedGeoPoint, nil);
    } error:^(Fault *fault) {
        
        completion(nil, fault);
    }];
}

@end
