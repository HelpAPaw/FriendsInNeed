//
//  FirstViewController.m
//  FriendsInNeed
//
//  Created by Milen on 21/11/15.
//  Copyright © 2015 г. Milen. All rights reserved.
//

#import "FirstViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "FINLocationManager.h"
#import "Backendless.h"

@interface FirstViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) FINLocationManager *locationManager;

@end

@implementation FirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _locationManager = [FINLocationManager sharedManager];
    [_locationManager setMapView:_mapView];
    [_locationManager startMonitoringSignificantLocationChanges];
    
//    [_locationManager startMonitoringLocation];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(applicationWillEnterForeground:)
//                                                 name:UIApplicationWillEnterForegroundNotification
//                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(applicationDidEnterBackground:)
//                                                 name:UIApplicationDidEnterBackgroundNotification
//                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//- (void)applicationWillEnterForeground:(NSNotification *)notification
//{
//    [_locationManager updateMap];
//}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [_locationManager updateMapToLastKnownLocation];
    [_locationManager updateUserLocation];
}

//- (void)applicationDidEnterBackground:(NSNotification *)notification
//{
//    [_locationManager startMonitoringSignificantLocationChanges];
//}

@end
