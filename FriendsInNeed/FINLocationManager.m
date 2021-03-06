//
//  FINLocationManager.m
//  FriendsInNeed
//
//  Created by Milen on 24/11/15.
//  Copyright © 2015 г. Milen. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "FINAnnotation.h"
#import "FINLocationManager.h"
#import "FINDataManager.h"

#define kLastKnownLocation @"LastKnownLocation"

@interface FINLocationManager() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation        *lastSavedLocation;
@property (assign, nonatomic) BOOL              userLocationUpdateRequested;

@end

@implementation FINLocationManager

+ (id)sharedManager
{
    static FINLocationManager *_sharedManager = nil;
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
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [_locationManager requestAlwaysAuthorization];
    
    return self;
}

- (void)updateUserLocation
{
    _userLocationUpdateRequested = YES;
    [_locationManager startUpdatingLocation];
}

- (void)startMonitoringSignificantLocationChanges
{
    [_locationManager startMonitoringSignificantLocationChanges];
}


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *newLocation = locations.lastObject;

    CLLocationDistance distance = DBL_MAX;
    if (_lastSavedLocation)
    {
        distance = [_lastSavedLocation distanceFromLocation:newLocation];
        NSLog(@"Distance travelled: %f", distance);
    }
    
    
    [[FINDataManager sharedManager] getSignalsForNewLocation:newLocation withCompletionHandler:nil];
    

    [self saveLastKnownLocation:newLocation];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        [_mapDelegate updateMapToLocation:newLocation];
    }
    
    if (_userLocationUpdateRequested)
    {
        _userLocationUpdateRequested = NO;
        [manager stopUpdatingLocation];
    }
}

- (void)saveLastKnownLocation:(CLLocation *)location
{
    NSError *error;
    NSData *locationData = [NSKeyedArchiver archivedDataWithRootObject:location requiringSecureCoding:YES error:&error];
    [[NSUserDefaults standardUserDefaults] setObject:locationData forKey:kLastKnownLocation];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    _lastSavedLocation = location;
}

- (CLLocation *)loadLastKnownLocation
{
    CLLocation *lastLocation = nil;
    @try
    {
        NSData *locationData = [[NSUserDefaults standardUserDefaults] objectForKey:kLastKnownLocation];
        NSError *error;
        lastLocation = (CLLocation *)[NSKeyedUnarchiver unarchivedObjectOfClass:CLLocation.class fromData:locationData error:&error];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Couldn't read last location. Exception: %@", exception.description);
    }
    
    return lastLocation;
}

- (CLLocation *)getLastKnownUserLocation
{
    if (_lastSavedLocation == nil)
    {
        _lastSavedLocation = [self loadLastKnownLocation];
    }
    
    return _lastSavedLocation;
}


@end
