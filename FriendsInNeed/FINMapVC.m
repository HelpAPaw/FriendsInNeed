//
//  FINMapVC.m
//  FriendsInNeed
//
//  Created by Milen on 18/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINMapVC.h"
#import <CoreLocation/CoreLocation.h>
#import "FINLoginVC.h"
#import "FINAnnotation.h"

#define kAddSignalViewYposition 15.0f
#define kAddSignalViewYbounce   10.0f
#define kButtonBlueColor [UIColor colorWithRed:13.0f/255.0f green:95.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
#define kSubmitSignalAnnotationView     @"SubmitSignalAnnotationView"
#define kStandardSignalAnnotationView   @"StandardSignalAnnotationView"


@interface FINMapVC () <UIGestureRecognizerDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *addSignalButton;
@property (strong, nonatomic) IBOutlet UIView *addSignalView;
@property (weak, nonatomic) IBOutlet UITextField *signalTitleField;

@property (strong, nonatomic) FINLocationManager *locationManager;
@property (strong, nonatomic) FINDataManager     *dataManager;

@property (assign, nonatomic) BOOL submitMode;
@property (strong, nonatomic) MKPointAnnotation *submitSignalAnnotation;
@property (weak, nonatomic) MKAnnotationView *submitSignalAnnotationView;

@end

@implementation FINMapVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _locationManager = [FINLocationManager sharedManager];
    _locationManager.mapDelegate = self;
    _dataManager = [FINDataManager sharedManager];
    _dataManager.mapDelegate = self;
    
    [_locationManager startMonitoringSignificantLocationChanges];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    _addSignalButton.tintColor = [UIColor redColor];
    _addSignalButton.layer.shadowOpacity = 1.0f;
    _addSignalButton.layer.shadowColor = [UIColor redColor].CGColor;
    _addSignalButton.layer.shadowOffset = CGSizeMake(0, 0);    
    _addSignalButton.alpha = 0.0f;
    
    _addSignalView.layer.cornerRadius = 5.0f;
    _addSignalView.layer.shadowOpacity = 1.0f;
    _addSignalView.layer.shadowColor = [UIColor grayColor].CGColor;
    _addSignalView.layer.shadowOffset = CGSizeMake(0, 0);
    
    _submitMode = NO;
    
    UIPanGestureRecognizer* panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragMap:)];
    [panGR setDelegate:self];
    [_mapView addGestureRecognizer:panGR];
    
    self.navigationItem.title = @"Signals Map";
    
//    NSString *backButtonText = @"Map";
//    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:backButtonText style:UIBarButtonItemStylePlain target:nil action:nil];
//    self.navigationItem.backBarButtonItem = backButton;
    
    UIImage *addImage = [UIImage imageNamed:@"ic_add"];
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [addButton setFrame:CGRectMake(0, 0, addImage.size.width, addImage.size.height)];
    [addButton setImage:addImage forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(onAddSignalButton:) forControlEvents:UIControlEventTouchUpInside];
    [addButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *addBarButton = [[UIBarButtonItem alloc] initWithCustomView:addButton];
    self.navigationItem.rightBarButtonItem = addBarButton;
    
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu"] style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.leftBarButtonItem = menuButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initMapVC];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    CGRect frame = _addSignalView.frame;
    frame.size.width = self.view.frame.size.width - 30.0f;
    frame.origin.x = 15.0f;
    frame.origin.y = - frame.size.height;
    _addSignalView.frame = frame;
    
    [self.view addSubview:_addSignalView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self initMapVC];
}

#pragma mark
- (void)initMapVC
{
    [self updateMapToLastKnownUserLocation];
    
#warning What happens when last location is different from current location? Or current location is unavailable?
    [_dataManager getNewSignalsForLastLocationWithCompletionHandler:nil];
    [_locationManager updateUserLocation];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)updateMapToLastKnownUserLocation
{
    CLLocation *lastKnownUserLocation = [_locationManager getLastKnownUserLocation];
    if (lastKnownUserLocation != nil)
    {
        [self updateMapToLocation:lastKnownUserLocation];
    }
}

#pragma mark - FINLocationManagerMapDelegate
- (void)updateMapToLocation:(CLLocation *)location
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, kDefaultMapRegion, kDefaultMapRegion);
    [_mapView setRegion:region animated:YES];
}


#pragma mark
- (void)toggleSubmitMode
{
    CGFloat rotationAngle;
    if (!_submitMode)
    {
        [self updateMapToLastKnownUserLocation];
        
        rotationAngle = -3.25f;
        
        // Add a pin to the map to select location of the signal
        CLLocation *userLocation = [[FINLocationManager sharedManager] getLastKnownUserLocation];
        _submitSignalAnnotation = [MKPointAnnotation new];
        _submitSignalAnnotation.coordinate = userLocation.coordinate;
        [_mapView addAnnotation:_submitSignalAnnotation];
        
        _signalTitleField.text = @"";
    }
    else
    {
        rotationAngle = 0.0f;
    }
    
    
    [UIView animateWithDuration:0.3f animations:^{
        
        _addSignalButton.transform = CGAffineTransformMakeRotation(rotationAngle*M_PI);
        
        CGRect frame = _addSignalView.frame;
        if (_submitMode)
        {
            frame.origin.y += kAddSignalViewYbounce;
            
            // Fade pin before removal
            _submitSignalAnnotationView.alpha = 0.0f;
            
            _addSignalButton.alpha = 0.0f;
        }
        else
        {
            frame.origin.y = kAddSignalViewYposition + kAddSignalViewYbounce;
            
            _addSignalButton.alpha = 1.0f;
        }
        _addSignalView.frame = frame;
        
    } completion:^(BOOL finished) {
        if (finished)
        {
            [UIView animateWithDuration:0.3f animations:^{
                CGRect frame = _addSignalView.frame;
                if (_submitMode)
                {
                    frame.origin.y = - frame.size.height;
                    
                    // Remove pin and annotation
                    [_mapView removeAnnotation:_submitSignalAnnotation];
                    _submitSignalAnnotation = nil;
                }
                else
                {
                    frame.origin.y -= kAddSignalViewYbounce;
                }
                _addSignalView.frame = frame;
            }];
            
            _submitMode = !_submitMode;
        }
    }];
}

- (IBAction)onAddSignalButton:(id)sender
{    
    [self toggleSubmitMode];
}

- (IBAction)onSendButton:(id)sender
{
    BackendlessUser *currentUser = backendless.userService.currentUser;
    if (!currentUser)
    {
        [self showLoginScreen];
        return;
    }
    
    [_dataManager submitNewSignalWithTitle:_signalTitleField.text forLocation:_submitSignalAnnotation.coordinate completion:^(GeoPoint *savedGeoPoint, Fault *fault) {
        if (savedGeoPoint)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Thank you!"
                                                                           message:@"Your signal was submitted."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self toggleSubmitMode];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:^{}];
            [self addAnnotationToMapFromGeoPoint:savedGeoPoint];
            
            [_signalTitleField setText:@""];
        }
        else
        {
            NSLog(@"%@", fault.description);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Ooops!"
                                                                           message:[NSString stringWithFormat:@"Something went wrong! Server said:\n%@", fault.description]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      [self dismissViewControllerAnimated:YES completion:nil];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:^{}];
        }
    }];
    
    
    [_signalTitleField resignFirstResponder];
}

- (void)showLoginScreen
{
    FINLoginVC *loginVC = [[FINLoginVC alloc] init];
    loginVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:loginVC animated:YES completion:^{}];
    
    [self.tabBarController setSelectedIndex:0];
}

- (void)addAnnotationToMapFromGeoPoint:(GeoPoint *)geoPoint
{
    BOOL alreadyPresent = NO;
    for (FINAnnotation *ann in _mapView.annotations)
    {
        if ([ann isKindOfClass:[FINAnnotation class]] == NO)
        {
            continue;
        }
        else
        {
            if ([ann.geoPoint.objectId isEqualToString:_focusSignalID])
            {
                [self focusAnnotation:ann];
            }
            
            if ([ann.geoPoint.objectId isEqualToString:geoPoint.objectId] == YES)
            {
                alreadyPresent = YES;
                break;
            }
        }
    }
    
    if (alreadyPresent == NO)
    {
        FINAnnotation *annotation = [[FINAnnotation alloc] initWithGeoPoint:geoPoint];
        [_mapView addAnnotation:annotation];
        
        if ([annotation.geoPoint.objectId isEqualToString:_focusSignalID])
        {
            [self focusAnnotation:annotation];
        }
    }
}

- (void)focusAnnotation:(FINAnnotation *)annotation
{
    [_mapView selectAnnotation:annotation animated:YES];
    [_mapView setCenterCoordinate:annotation.coordinate animated:YES];
    _focusSignalID = nil;
}

- (void)setFocusSignalID:(NSString *)focusSignalID
{
    _focusSignalID = focusSignalID;
    
    BackendlessGeoQuery *query = [BackendlessGeoQuery queryWithCategories:nil];
    query.whereClause = [NSString stringWithFormat:@"objectid='%@'", focusSignalID];
    [query includeMeta:YES];
    [backendless.geoService getPoints:query response:^(BackendlessCollection *collection) {
        NSLog(@"%@", collection.data);
        
        if (collection.data.count > 0)
        {
            GeoPoint *geoPoint = (GeoPoint *) collection.data.firstObject;
            [self addAnnotationToMapFromGeoPoint:geoPoint];
        }
    } error:^(Fault *error) {
        NSLog(@"%@", error.detail);
    }];
}

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals
{
    for (GeoPoint *geoPoint in nearbySignals)
    {
        [self addAnnotationToMapFromGeoPoint:geoPoint];
    }
}

#pragma mark - Pan Gesture Recognizer Delegate
// This is needed so that the Pan GR works along with the map's gesture recognizers
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)didDragMap:(UIGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        [_signalTitleField resignFirstResponder];
        
        CLLocation *newCenter = [[CLLocation alloc] initWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
        [_dataManager getSignalsForNewLocation:newCenter];
    }
}

#pragma mark - Map Delegate
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id)annotation
{
    // If the annotation is the user location, just return nil so the default annotation view is used
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        return nil;
    }
    
    MKAnnotationView *newAnnotationView;
    
    if (annotation == _submitSignalAnnotation)
    {
        MKPinAnnotationView *pinAnnotationView = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:kSubmitSignalAnnotationView];
        if (pinAnnotationView == nil)
        {
            pinAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kSubmitSignalAnnotationView];
            pinAnnotationView.pinTintColor = kButtonBlueColor;
            pinAnnotationView.animatesDrop = YES;
            pinAnnotationView.draggable = YES;
            pinAnnotationView.canShowCallout = NO;
        }
        else
        {
            pinAnnotationView.annotation = annotation;
            pinAnnotationView.alpha = 1.0f;
        }
        
        [pinAnnotationView setSelected:YES animated:YES];
        
        newAnnotationView = pinAnnotationView;
        _submitSignalAnnotationView = pinAnnotationView;
    }
    else
    {
        newAnnotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:kStandardSignalAnnotationView];
        if (newAnnotationView == nil)
        {
            newAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kStandardSignalAnnotationView];
            newAnnotationView.canShowCallout = YES;
            
            // Because this is an iOS app, add the detail disclosure button to display details about the annotation in another view.
            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
            newAnnotationView.rightCalloutAccessoryView = rightButton;
            
            // Add a custom image to the left side of the callout.
            UIImageView *signalImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"borislava.JPG"]];
            CGRect imageFrame = signalImage.frame;
            imageFrame.size.height = 44.0;//newAnnotationView.frame.size.height;
            imageFrame.size.width  = 44.0;//newAnnotationView.frame.size.height;
            signalImage.frame = imageFrame;
            signalImage.clipsToBounds = YES;
            signalImage.layer.cornerRadius = 5.0f;
            newAnnotationView.leftCalloutAccessoryView = signalImage;
        }
        else
        {
            newAnnotationView.annotation = annotation;
        }
        
        FINAnnotation *ann = (FINAnnotation *)annotation;
        GeoPoint *geoPoint = ann.geoPoint;
        NSString *status = [geoPoint.metadata objectForKey:@"status"];
        UIImage *pinImage;
        if ([status isEqualToString:@"2"])
        {
            pinImage = [UIImage imageNamed:@"pin_green.png"];
        }
        else if ([status isEqualToString:@"1"])
        {
            pinImage = [UIImage imageNamed:@"pin_orange.png"];
        }
        else
        {
            pinImage = [UIImage imageNamed:@"pin_red.png"];
        }
        
        newAnnotationView.image = pinImage;
        newAnnotationView.centerOffset = CGPointMake(0, -20);
    }
    
    return newAnnotationView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view.reuseIdentifier isEqualToString:kStandardSignalAnnotationView])
    {
        FINAnnotation *annotation = (FINAnnotation *)view.annotation;
        [annotation updateAnnotationSubtitle];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    FINAnnotation *annotation = (FINAnnotation *)view.annotation;
    FINSignalDetailsVC *signalDetailsVC = [[FINSignalDetailsVC alloc] initWithAnnotation:annotation];
    signalDetailsVC.delegate = self;
    signalDetailsVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    
    UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:signalDetailsVC];
    navController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:navController animated:YES completion:^{}];
    
    
//    [self presentViewController:signalDetailsVC animated:YES completion:^{}];
    
//    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
//    self.navigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
//    [self.navigationController pushViewController:signalDetailsVC animated:YES];
}

- (void)refreshAnnotation:(FINAnnotation *)annotation
{
    [_mapView removeAnnotation:annotation];
    [_mapView addAnnotation:annotation];
}

@end
