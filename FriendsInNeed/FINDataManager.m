//
//  FINDataManager.m
//  FriendsInNeed
//
//  Created by Milen on 29/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINDataManager.h"

#define kMinimumDistanceTravelled   300

@interface FINDataManager ()

@property (strong, nonatomic) CLLocation        *lastSignalCheckLocation;

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
    
    return self;
}

- (void)getSignalsForLocation:(CLLocation *)location
{
    // Do not check if delta distance is below threshold
    if (   (_lastSignalCheckLocation != nil)
        && ([_lastSignalCheckLocation distanceFromLocation:location] < kMinimumDistanceTravelled)
        )
    {
        return;
    }
    
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
        else if (newSignals.count > 0)
        {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_nearbySignals.count];
            
            GeoPoint *nearestSignal = _nearbySignals.firstObject;
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertBody  = [nearestSignal.metadata objectForKey:kSignalTitleKey];
            localNotification.userInfo = [NSDictionary dictionaryWithObject:nearestSignal.objectId forKey:kNotificationSignalID];
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        }
    } error:^(Fault *fault) {
        NSLog(@"%@", fault.description);
        
        _lastSignalCheckLocation = nil;
    }];
    
    _lastSignalCheckLocation = location;
}

@end
