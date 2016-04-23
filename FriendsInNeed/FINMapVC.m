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


@interface FINMapVC () <UIGestureRecognizerDelegate, MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *addSignalButton;
@property (strong, nonatomic) IBOutlet UIView *addSignalView;
@property (weak, nonatomic) IBOutlet UITextField *signalTitleField;
@property (weak, nonatomic) IBOutlet UIButton *btnPhoto;

@property (strong, nonatomic) FINLocationManager *locationManager;
@property (strong, nonatomic) FINDataManager     *dataManager;

@property (assign, nonatomic) BOOL submitMode;
@property (strong, nonatomic) MKPointAnnotation *submitSignalAnnotation;
@property (weak, nonatomic) MKAnnotationView *submitSignalAnnotationView;
@property (assign, nonatomic) UIImagePickerControllerSourceType photoSource;
@property (strong, nonatomic) UIImage *signalPhoto;

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
    
    _btnPhoto.layer.cornerRadius = 5.0f;
    _btnPhoto.clipsToBounds = YES;
    [[_btnPhoto imageView] setContentMode: UIViewContentModeScaleAspectFill];
    
    _submitMode = NO;
    
    UIPanGestureRecognizer* panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragMap:)];
    [panGR setDelegate:self];
    [_mapView addGestureRecognizer:panGR];
    
    self.navigationItem.title = @"Help a Paw";
    
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
    
//    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu"] style:UIBarButtonItemStylePlain target:self action:@selector(showLoginScreen)];
//    self.navigationItem.leftBarButtonItem = menuButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initMapVC];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_submitMode == NO)
    {
        CGRect frame = _addSignalView.frame;
        frame.size.width = self.view.frame.size.width - 30.0f;
        frame.origin.x = 15.0f;
        frame.origin.y = - frame.size.height;
        _addSignalView.frame = frame;
        
        [self.view addSubview:_addSignalView];
    }
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
                    
                    // Reset photo button
                    [_btnPhoto setImage:[UIImage imageNamed:@"ic_camera"] forState:UIControlStateNormal];
                    _signalPhoto = nil;
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
    if ([[FINDataManager sharedManager] userIsLogged] == NO)
    {
        [self showLoginScreen];
        return;
    }
    
    [_dataManager submitNewSignalWithTitle:_signalTitleField.text forLocation:_submitSignalAnnotation.coordinate withPhoto:_signalPhoto completion:^(FINSignal *savedSignal, Fault *fault) {
        if (savedSignal)
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
            [self addAnnotationToMapFromSignal:savedSignal];
            
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

- (IBAction)onAttachPhotoButton:(id)sender
{
    UIAlertController *photoModeAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self setPhotoSourceCamera];
        [self showPhotoPicker];
    }];
    UIAlertAction *chooseExisting = [UIAlertAction actionWithTitle:@"Choose Existing" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self setPhotoSourceSavedPhotos];
        [self showPhotoPicker];
    }];
    [photoModeAlert addAction:takePhoto];
    [photoModeAlert addAction:chooseExisting];
    [self presentViewController:photoModeAlert animated:YES completion:^{}];
}

- (void)setPhotoSourceCamera
{
    _photoSource = UIImagePickerControllerSourceTypeCamera;
}

- (void)setPhotoSourceSavedPhotos
{
    _photoSource = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
}

- (void)showPhotoPicker
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = _photoSource;
    if (_photoSource == UIImagePickerControllerSourceTypeCamera)
    {
        picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        picker.showsCameraControls = YES;
    }
    [self presentViewController:picker animated:YES completion:^ {}];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    _signalPhoto = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    [_btnPhoto setImage:_signalPhoto forState:UIControlStateNormal];
    
    [picker dismissViewControllerAnimated:YES completion:^{}];
}

- (void)showLoginScreen
{
    FINLoginVC *loginVC = [[FINLoginVC alloc] init];
    loginVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:loginVC animated:YES completion:^{}];
    
    [self.tabBarController setSelectedIndex:0];
}

- (void)addAnnotationToMapFromSignal:(FINSignal *)signal
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
            if ([ann.signal.signalID isEqualToString:_focusSignalID])
            {
                [self focusAnnotation:ann];
            }
            
            if ([ann.signal.signalID isEqualToString:signal.signalID] == YES)
            {
                alreadyPresent = YES;
                break;
            }
        }
    }
    
    if (alreadyPresent == NO)
    {
        FINAnnotation *annotation = [[FINAnnotation alloc] initWithSignal:signal];
        [_mapView addAnnotation:annotation];
        
        if ([annotation.signal.signalID isEqualToString:_focusSignalID])
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
    
    [[FINDataManager sharedManager] getSignalWithID:focusSignalID completion:^(FINSignal *signal, Fault *fault) {
        if (signal)
        {
            [self addAnnotationToMapFromSignal:signal];
        }
        else
        {
            NSLog(@"Failed to get signal for ID %@", focusSignalID);
        }
    }];
}

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals
{
    for (FINSignal *signal in nearbySignals)
    {
        [self addAnnotationToMapFromSignal:signal];
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
        FINAnnotation *ann = (FINAnnotation *)annotation;
        
        newAnnotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:kStandardSignalAnnotationView];
        if (newAnnotationView == nil)
        {
            newAnnotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kStandardSignalAnnotationView];
            newAnnotationView.canShowCallout = YES;
            
            // Because this is an iOS app, add the detail disclosure button to display details about the annotation in another view.
            UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
            newAnnotationView.rightCalloutAccessoryView = rightButton;
        }
        else
        {
            newAnnotationView.annotation = annotation;
        }
        
        // Add a default image to the left side of the callout.
        [self setImage:[UIImage imageNamed:@"ic_paw"] forAnnotationView:newAnnotationView];
        
        UIImage *pinImage = [ann.signal createStatusImage];
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
        
        // If there is a signal photo, set ti as the left accessory view
        if (annotation.signal.photo)
        {
            [self setImage:annotation.signal.photo forAnnotationView:view];
        }
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

- (void)setImage:(UIImage *)image forAnnotationView:(MKAnnotationView *)annotationView
{
    UIImageView *signalImageView = [[UIImageView alloc] initWithImage:image];
    CGRect imageFrame = signalImageView.frame;
    imageFrame.size.height = 44.0;
    imageFrame.size.width  = 44.0;
    signalImageView.frame = imageFrame;
    signalImageView.clipsToBounds = YES;
    signalImageView.layer.cornerRadius = 5.0f;
    [signalImageView setContentMode:UIViewContentModeScaleAspectFill];
    annotationView.leftCalloutAccessoryView = signalImageView;
}

- (void)refreshAnnotation:(FINAnnotation *)annotation
{
    [_mapView removeAnnotation:annotation];
    [_mapView addAnnotation:annotation];
}

@end
