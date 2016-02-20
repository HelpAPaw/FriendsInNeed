//
//  FINMapVC.m
//  FriendsInNeed
//
//  Created by Milen on 18/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINMapVC.h"
#import <CoreLocation/CoreLocation.h>
#import "FINLocationManager.h"
#import "FINLoginVC.h"

#define kAddSignalViewYposition 30.0f
#define kAddSignalViewYbounce   10.0f
#define kButtonBlueColor [UIColor colorWithRed:13.0f/255.0f green:95.0f/255.0f blue:255.0f/255.0f alpha:1.0f]


@interface FINMapVC () <UIGestureRecognizerDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *addSignalButton;
@property (strong, nonatomic) IBOutlet UIView *addSignalView;
@property (weak, nonatomic) IBOutlet UITextField *signalTitleField;

@property (strong, nonatomic) FINLocationManager *locationManager;

@property (assign, nonatomic) BOOL submitMode;

@end

@implementation FINMapVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _locationManager = [FINLocationManager sharedManager];
    [_locationManager setMapView:_mapView];
    [_locationManager startMonitoringSignificantLocationChanges];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    _addSignalButton.layer.shadowOpacity = 1.0f;
    _addSignalButton.layer.shadowColor = kButtonBlueColor.CGColor;
    _addSignalButton.layer.shadowOffset = CGSizeMake(0, 0);
    
    _addSignalView.layer.cornerRadius = 5.0f;
    _addSignalView.layer.shadowOpacity = 1.0f;
    _addSignalView.layer.shadowColor = [UIColor grayColor].CGColor;
    _addSignalView.layer.shadowOffset = CGSizeMake(0, 0);
    
    _submitMode = NO;
    
    UIPanGestureRecognizer* panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragMap:)];
    [panGR setDelegate:self];
    [_mapView addGestureRecognizer:panGR];
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
    [_locationManager updateMapToLastKnownLocation];
    [_locationManager updateMapWithNearbySignals];
    [_locationManager updateUserLocation];
}

- (void)toggleSubmitMode
{
    CGFloat rotationAngle;
    UIColor *buttonColor;
    if (!_submitMode)
    {
        rotationAngle = -3.25f;
        buttonColor = [UIColor redColor];
    }
    else
    {
        rotationAngle = 0.0f;
        buttonColor = kButtonBlueColor;
    }
    
    
    [UIView animateWithDuration:0.3f animations:^{
        
        _addSignalButton.transform = CGAffineTransformMakeRotation(rotationAngle*M_PI);
        _addSignalButton.tintColor = buttonColor;
        _addSignalButton.layer.shadowColor = buttonColor.CGColor;
        
        CGRect frame = _addSignalView.frame;
        if (_submitMode)
        {
            frame.origin.y += kAddSignalViewYbounce;
        }
        else
        {
            frame.origin.y = kAddSignalViewYposition + kAddSignalViewYbounce;
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
    CLLocation *userLocation = [[FINLocationManager sharedManager] getLastKnownUserLocation];
    
    BackendlessUser *currentUser = backendless.userService.currentUser;
    if (!currentUser)
    {
        [self showLoginScreen];
        return;
    }
    
    Responder *responder = [Responder responder:self selResponseHandler:@selector(geoPointSaved:) selErrorHandler:@selector(errorHandler:)];
    GEO_POINT coordinate;
    coordinate.latitude = userLocation.coordinate.latitude;
    coordinate.longitude = userLocation.coordinate.longitude;
    NSDictionary *geoPointMeta = @{@"name":_signalTitleField.text, @"author":currentUser};
    GeoPoint *point = [GeoPoint geoPoint:coordinate categories:nil metadata:geoPointMeta];
    [backendless.geoService savePoint:point responder:responder];
    
    [_signalTitleField setText:@""];
    [_signalTitleField resignFirstResponder];
}

- (void)showLoginScreen
{
    FINLoginVC *loginVC = [[FINLoginVC alloc] init];
    loginVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:loginVC animated:YES completion:^{}];
    
    [self.tabBarController setSelectedIndex:0];
}


#pragma mark - Backendless callbacks
- (void)geoPointSaved:(GeoPoint *)response
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
    [[FINLocationManager sharedManager] addNewSignal:response];
}

- (void)errorHandler:(Fault *)fault
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
    }
}

#pragma mark - Map Delegate
- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    
}

@end
