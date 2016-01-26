//
//  FINLocationManager.m
//  FriendsInNeed
//
//  Created by Milen on 24/11/15.
//  Copyright © 2015 г. Milen. All rights reserved.
//

#import "FINLocationManager.h"
#import <CoreLocation/CoreLocation.h>

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
    _locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
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
    
    
    _lastSavedLocation = newLocation;
    [self saveLastKnownLocation:newLocation];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        [self updateMapToLocation:newLocation];
    }
    else
    {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertTitle = @"Ooops! You just changed your location!";
        localNotification.alertBody  = [NSString stringWithFormat:@"You travelled: %f", distance];
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
    

    if (_userLocationUpdateRequested)
    {
        _userLocationUpdateRequested = NO;
        [manager stopUpdatingLocation];
    }
}

- (void)updateMapToLocation:(CLLocation *)location
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, 4000, 4000);
    [_mapView setRegion:region animated:YES];
}

- (void)updateMapToLastKnownLocation
{
    if (_lastSavedLocation == nil)
    {
        _lastSavedLocation = [self loadLastKnownLocation];
    }
    
    [self updateMapToLocation:_lastSavedLocation];
}

- (void)saveLastKnownLocation:(CLLocation *)location
{
//    NSNumber *lat = [NSNumber numberWithDouble:location.coordinate.latitude];
//    NSNumber *lon = [NSNumber numberWithDouble:location.coordinate.longitude];
//    NSDictionary *userLocation=@{@"latitude":lat,@"longitude":lon};
//    
//    [[NSUserDefaults standardUserDefaults] setObject:userLocation forKey:kLastKnownLocation];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSData *locationData = [NSKeyedArchiver archivedDataWithRootObject:location];
    [[NSUserDefaults standardUserDefaults] setObject:locationData forKey:kLastKnownLocation];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (CLLocation *)loadLastKnownLocation
{
//    NSDictionary *userLoc = [[NSUserDefaults standardUserDefaults] objectForKey:kLastKnownLocation];
//    
//    NSNumber *lat = [userLoc objectForKey:@"latitude"];
//    NSNumber *lon = [userLoc objectForKey:@"longitude"];
//    
//    CLLocation *lastLocation = [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lon.doubleValue];
    
    CLLocation *lastLocation = nil;
    @try
    {
        NSData *locationData = [[NSUserDefaults standardUserDefaults] objectForKey:kLastKnownLocation];
        lastLocation = (CLLocation *)[NSKeyedUnarchiver unarchiveObjectWithData:locationData];
    }
    @catch (NSException *exception)
    {
        NSLog(@"Couldn't read last location. Exception: %@", exception.description);
    }
    
    return lastLocation;
}

- (CLLocation *)getLastKnownUserLocation
{
    return _lastSavedLocation;
}


@end
