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
#define kDefaultMapRegion   4000

@interface FINLocationManager() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation        *lastSavedLocation;
@property (strong, nonatomic) CLLocation        *lastSignalCheckLocation;
@property (assign, nonatomic) BOOL              userLocationUpdateRequested;
@property (strong, nonatomic) NSMutableArray    *nearbySignals;

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
    
    _nearbySignals = [NSMutableArray new];
    
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
    
    if (   (_lastSignalCheckLocation == nil)
        || ([_lastSignalCheckLocation distanceFromLocation:newLocation] > 300)
       )
    {
        [self getSignalForLocation:newLocation];
    }
    
    _lastSavedLocation = newLocation;
    [self saveLastKnownLocation:newLocation];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        [self updateMapToLocation:newLocation];
    }
    
    if (_userLocationUpdateRequested)
    {
        _userLocationUpdateRequested = NO;
        [manager stopUpdatingLocation];
    }
}

- (void)updateMapToLocation:(CLLocation *)location
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, kDefaultMapRegion, kDefaultMapRegion);
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
    NSData *locationData = [NSKeyedArchiver archivedDataWithRootObject:location];
    [[NSUserDefaults standardUserDefaults] setObject:locationData forKey:kLastKnownLocation];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (CLLocation *)loadLastKnownLocation
{
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

- (void)getSignalForLocation:(CLLocation *)location
{
    GEO_POINT center;
    center.latitude = location.coordinate.latitude;
    center.longitude = location.coordinate.longitude;
    BackendlessGeoQuery *query = [BackendlessGeoQuery queryWithPoint:center radius:kDefaultMapRegion units:METERS categories:nil];
    query.includeMeta = @YES;
    Responder *responder = [Responder responder:self selResponseHandler:@selector(signalsReceived:) selErrorHandler:@selector(errorHandler:)];
    [backendless.geoService getPoints:query responder:responder];
    
    _lastSignalCheckLocation = location;
}

- (void)signalsReceived:(BackendlessCollection *)response
{
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
            NSLog(@"New signal: %@", [receivedGeoPoint.metadata objectForKey:@"name"]);
        }
        
        [tempNearbySignals addObject:receivedGeoPoint];
    }
    
    _nearbySignals = [NSMutableArray arrayWithArray:tempNearbySignals];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_nearbySignals.count];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        [self updateMapWithNearbySignals];
    }
    else if (newSignals.count > 0)
    {
        NSString *alertBody;
        if (newSignals.count > 1)
        {
            alertBody = @"There are animals near you that need urgent help!";
            
        }
        else
        {
            alertBody = @"There is a hurt animal near you!";
        }
        
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertBody  = alertBody;
        GeoPoint *nearestSignal = _nearbySignals.firstObject;
        localNotification.userInfo = [NSDictionary dictionaryWithObject:nearestSignal.objectId forKey:kNotificationSignalID];
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
}


- (void)errorHandler:(Fault *)fault
{
    NSLog(@"%@", fault.description);
    
    _lastSignalCheckLocation = nil;
}

- (MKPointAnnotation *)annotationFromGeoPoint:(GeoPoint *)geoPoint
{
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.title = [geoPoint.metadata objectForKey:@"name"];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(geoPoint.latitude.doubleValue, geoPoint.longitude.doubleValue);
    annotation.coordinate = coordinate;
    return annotation;
}

- (void)addAnnotationToMapFromGeoPoint:(GeoPoint *)geoPoint
{
    MKPointAnnotation *annotation = [self annotationFromGeoPoint:geoPoint];
    [_mapView addAnnotation:annotation];
    if ([geoPoint.objectId isEqualToString:_focusSignalID])
    {
        [_mapView selectAnnotation:annotation animated:YES];
    }
}

- (void)updateMapWithNearbySignals
{
    [_mapView removeAnnotations:[_mapView annotations]];
    
    for (GeoPoint *geoPoint in _nearbySignals)
    {
        [self addAnnotationToMapFromGeoPoint:geoPoint];
    }
}

- (void)addNewSignal:(GeoPoint *)geoPoint
{
    [_nearbySignals addObject:geoPoint];
    [self addAnnotationToMapFromGeoPoint:geoPoint];
}

- (void)setFocusSignalID:(NSString *)focusSignalID
{
    _focusSignalID = focusSignalID;
    
    BackendlessGeoQuery *query = [BackendlessGeoQuery queryWithCategories:@[@"Restaurants"]];
    query.whereClause = [NSString stringWithFormat:@"objectid='%@'", focusSignalID];
    [query includeMeta:YES];
    [backendless.geoService getPoints:query response:^(BackendlessCollection *collection) {
        NSLog(@"%@", collection.data);
    } error:^(Fault *error) {
        NSLog(@"%@", error.detail);
    }];
}


@end
