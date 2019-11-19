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
#import <ViewDeck/ViewDeck.h>
#import "Help_A_Paw-Swift.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "FINGlobalConstants.pch"


#define kAddSignalViewYposition 15.0f
#define kAddSignalViewYbounce   10.0f
#define kButtonBlueColor [UIColor colorWithRed:13.0f/255.0f green:95.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
#define kSubmitSignalAnnotationView     @"SubmitSignalAnnotationView"
#define kStandardSignalAnnotationView   @"StandardSignalAnnotationView"


@interface FINMapVC () <MKMapViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIView *addSignalView;
@property (weak, nonatomic) IBOutlet UITextField *signalTitleField;
@property (weak, nonatomic) IBOutlet UITextField *authorPhoneField;
@property (weak, nonatomic) IBOutlet UIButton *btnPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnSendSignal;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sendSignalButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *liSendSignal;

@property (strong, nonatomic) UIBarButtonItem *addBarButton;
@property (strong, nonatomic) UIBarButtonItem *refreshBarButton;
@property (strong, nonatomic) UIBarButtonItem *refreshingBarButton;
@property (assign, nonatomic) BOOL pauseRefreshing;

@property (strong, nonatomic) FINLocationManager *locationManager;
@property (strong, nonatomic) FINDataManager     *dataManager;

@property (assign, nonatomic) BOOL isInSubmitMode;
@property (strong, nonatomic) MKPointAnnotation *submitSignalAnnotation;
@property (weak, nonatomic) MKAnnotationView *submitSignalAnnotationView;
@property (assign, nonatomic) UIImagePickerControllerSourceType photoSource;
@property (strong, nonatomic) UIImage *signalPhoto;
@property (assign, nonatomic) BOOL viewDidAppearOnce;
@property (assign, nonatomic) BOOL userDidChangeZoom;
@property (strong, nonatomic) UITapGestureRecognizer *envSwitchGesture;
@property (strong, nonatomic) CLLocation *lastRefreshCenter;
@property (assign, nonatomic) NSInteger   lastRefreshRadius;

@end

@implementation FINMapVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _viewDidAppearOnce = NO;
    
    _locationManager = [FINLocationManager sharedManager];
    _locationManager.mapDelegate = self;
    
    [_locationManager startMonitoringSignificantLocationChanges];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsChanged:)
                                                 name:kNotificationSettingRadiusChanged
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(settingsChanged:)
                                                 name:kNotificationSettingTimeoutChanged
                                               object:nil];
    
    UIPanGestureRecognizer *dragGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(userDidMoveMap:)];
    [dragGR setDelegate:self];
    [self.mapView addGestureRecognizer:dragGR];
    UIPinchGestureRecognizer *pinchGR = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(userDidMoveMap:)];
    [pinchGR setDelegate:self];
    [self.mapView addGestureRecognizer:pinchGR];
    
    _cancelButton.tintColor = [UIColor redColor];
    _cancelButton.layer.shadowOpacity = 1.0f;
    _cancelButton.layer.shadowColor = [UIColor redColor].CGColor;
    _cancelButton.layer.shadowOffset = CGSizeMake(0, 0);    
    _cancelButton.alpha = 0.0f;
    
    _addSignalView.layer.cornerRadius = 5.0f;
    _addSignalView.layer.shadowOpacity = 1.0f;
    _addSignalView.layer.shadowColor = [UIColor grayColor].CGColor;
    _addSignalView.layer.shadowOffset = CGSizeMake(0, 0);
    
    _btnPhoto.layer.cornerRadius = 5.0f;
    _btnPhoto.clipsToBounds = YES;
    [[_btnPhoto imageView] setContentMode: UIViewContentModeScaleAspectFill];
    
    [_btnSendSignal sizeToFit];
    _sendSignalButtonWidthConstraint.constant = _btnSendSignal.frame.size.width + 10;
    
    _isInSubmitMode = NO;
    
    self.navigationItem.title = @"Help a Paw";
    
    // Create add bar button
    UIImage *addImage = [UIImage imageNamed:@"ic_add"];
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [addButton setFrame:CGRectMake(0, 0, addImage.size.width, addImage.size.height)];
    [addButton setImage:addImage forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(onAddSignalButton:) forControlEvents:UIControlEventTouchUpInside];
    [addButton setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *addBarButton = [[UIBarButtonItem alloc] initWithCustomView:addButton];
    _addBarButton = addBarButton;
    
    // Create refresh bar button
    _refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped:)];
    
    // Create loading bar button
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator setFrame:CGRectMake(0, 0, 30, 30)];
    [activityIndicator startAnimating];
    _refreshingBarButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    
    [self setupReadyMode];
    
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(menuButtonTapped:)];
    self.navigationItem.leftBarButtonItem = menuButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_viewDidAppearOnce == NO)
    {
        _dataManager = [FINDataManager sharedManager];
        _dataManager.mapDelegate = self;
        [self checkForPrivacyPolicyAcceptance];
        [self updateTitle];
        _viewDidAppearOnce = YES;
    }
    
    [self setupEnvironmentSwitching];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_isInSubmitMode == NO)
    {
        [self resizeAddSignalViewForParentViewSize:self.view.frame.size];
        
        // Place view outside visible zone
        CGRect frame = _addSignalView.frame;
        frame.origin.y = - frame.size.height;
        _addSignalView.frame = frame;
        
        [self.view addSubview:_addSignalView];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeEnvironmentSwitching];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Code here will execute before the rotation begins.
    // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        // Place code here to perform animations during the rotation.
        // You can pass nil or leave this block empty if not necessary.
        [self resizeAddSignalViewForParentViewSize:size];
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        // Code here will execute after the rotation has finished.
        // Equivalent to placing it in the deprecated method -[didRotateFromInterfaceOrientation:]
        
    }];
}

- (void)resizeAddSignalViewForParentViewSize:(CGSize)parentSize
{
    CGFloat margin = 15.0f;
    
    CGRect frame = _addSignalView.frame;
    frame.size.width = parentSize.width - (2 * margin);
    frame.origin.x = margin;
    _addSignalView.frame = frame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self initMapVC];
}

- (void)settingsChanged:(NSNotification *) notification
{
    [self initMapVC];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark
- (void)initMapVC
{
    [_locationManager updateUserLocation];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}


#pragma mark - FINLocationManagerMapDelegate
- (void)updateMapToLocation:(CLLocation *)location
{
    CLLocationDistance radiusInMeters = [_dataManager getRadiusSetting] * 1000;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location.coordinate, radiusInMeters, radiusInMeters);
    [_mapView setRegion:region animated:YES];
}


#pragma mark
- (void)toggleSubmitMode
{
    CGFloat rotationAngle;
    if (_isInSubmitMode == NO)
    {
        rotationAngle = -3.25f;
        
        // Add a pin to the map to select location of the signal
        _submitSignalAnnotation = [MKPointAnnotation new];
        _submitSignalAnnotation.coordinate = _mapView.centerCoordinate;
        [_mapView addAnnotation:_submitSignalAnnotation];
        
        _signalTitleField.text = @"";
    }
    else
    {
        rotationAngle = 0.0f;
    }
    
    
    [UIView animateWithDuration:0.3f animations:^{
        
       self.cancelButton.transform = CGAffineTransformMakeRotation(rotationAngle*M_PI);
        
        CGRect frame = self.addSignalView.frame;
        if (self.isInSubmitMode)
        {
            frame.origin.y += kAddSignalViewYbounce;
            
            // Fade pin before removal
            self.submitSignalAnnotationView.alpha = 0.0f;
            
           self.cancelButton.alpha = 0.0f;
        }
        else
        {
            frame.origin.y = kAddSignalViewYposition + kAddSignalViewYbounce;
            
           self.cancelButton.alpha = 1.0f;
        }
       self.addSignalView.frame = frame;
        
    } completion:^(BOOL finished) {
        if (finished)
        {
            [UIView animateWithDuration:0.3f animations:^{
                CGRect frame =self.addSignalView.frame;
                if (self.isInSubmitMode)
                {
                    frame.origin.y = - frame.size.height;
                    
                    // Remove pin and annotation
                    [self.mapView removeAnnotation:self.submitSignalAnnotation];
                    self.submitSignalAnnotation = nil;
                    
                    // Reset photo button
                    [self.btnPhoto setImage:[UIImage imageNamed:@"ic_camera"] forState:UIControlStateNormal];
                    self.signalPhoto = nil;
                    
                    [self.signalTitleField resignFirstResponder];
                }
                else
                {
                    frame.origin.y -= kAddSignalViewYbounce;
                }
               self.addSignalView.frame = frame;
            }];
            
           self.isInSubmitMode = !self.isInSubmitMode;
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
        [_signalTitleField resignFirstResponder];
        [self showLoginScreen];
        return;
    }
    
    // Input validation
    BOOL validation = [InputValidator validateGeneralInputFor:@[_signalTitleField] message:NSLocalizedString(@"Please enter a description of the signal.", nil) parent:self];
    if (!validation)
    {
        return;
    }
    
    [self setSendingSignalMode];
    [_dataManager submitNewSignalWithTitle:_signalTitleField.text andAuthorPhone:(NSString *)_authorPhoneField.text forLocation:_submitSignalAnnotation.coordinate withPhoto:_signalPhoto completion:^(FINSignal *savedSignal, FINError *error) {
        
        [self resetSendingSignalMode];
        
        if (savedSignal)
        {
            [self toggleSubmitMode];
            
            // Signal saved but photo was not
            if (error)
            {
                NSMutableString *message = [NSMutableString stringWithFormat:NSLocalizedString(@"Your signal was submitted but the attached photo was not. The problem is:\n%@",nil), error.message];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Thank you!",nil)
                                                                               message:message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * action) {
                                                                          // Add new annotation to map and focus it when OK button is pressed
                                                                          self.focusSignalID = savedSignal.signalID;
                                                                          [self addAnnotationToMapFromSignal:savedSignal];
                                                                      }];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:^{}];
            }
            else
            {
                // Add new annotation to map and focus it when OK button is pressed
                self.focusSignalID = savedSignal.signalID;
                [self addAnnotationToMapFromSignal:savedSignal];
            }
        }
        else
        {
            [self showAlertForError:error];
        }
    }];
    
    [_signalTitleField resignFirstResponder];
}

- (IBAction)onAttachPhotoButton:(id)sender
{
    UIAlertController *photoModeAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:NSLocalizedString(@"Take Photo",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self setPhotoSourceCamera];
        [self showPhotoPicker];
    }];
    UIAlertAction *chooseExisting = [UIAlertAction actionWithTitle:NSLocalizedString(@"Choose Existing",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self setPhotoSourceSavedPhotos];
        [self showPhotoPicker];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleCancel handler:nil];
    
    [photoModeAlert addAction:takePhoto];
    [photoModeAlert addAction:chooseExisting];
    [photoModeAlert addAction:cancel];
    
    UIPopoverPresentationController *popPresenter = [photoModeAlert popoverPresentationController];
    popPresenter.sourceView = _btnPhoto;
    popPresenter.sourceRect = _btnPhoto.bounds;
    
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
    if (_photoSource == UIImagePickerControllerSourceTypeCamera)
    {
        UIImageWriteToSavedPhotosAlbum(_signalPhoto, nil, nil, nil);
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{}];
}

- (void)setSendingSignalMode
{
    _btnSendSignal.hidden = YES;
    [_liSendSignal startAnimating];
}

- (void)resetSendingSignalMode
{
    _btnSendSignal.hidden = NO;
    [_liSendSignal stopAnimating];
}

- (void)showLoginScreen
{
    FINLoginVC *loginVC = [[FINLoginVC alloc] init];
    loginVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:loginVC animated:YES completion:^{}];
}

- (void)addAnnotationToMapFromSignal:(FINSignal *)signal
{
    // Unfortunately to refresh annotations we need to remove and add them again
    // Remove old annotation if present
    for (FINAnnotation *ann in _mapView.annotations)
    {
        if ([ann isKindOfClass:[FINAnnotation class]] == NO)
        {
            continue;
        }
        else
        {
            // Only remove not focused annotations
            if (   ([ann.signal.signalID isEqualToString:signal.signalID] == YES)
                && ([_mapView.selectedAnnotations indexOfObject:ann] == NSNotFound)   )
            {
                [_mapView removeAnnotation:ann];
                break;
            }
        }
    }
    
    // Add new annotation
    FINAnnotation *annotation = [[FINAnnotation alloc] initWithSignal:signal];
    [_mapView addAnnotation:annotation];
    
    if ([annotation.signal.signalID isEqualToString:_focusSignalID])
    {
        [self focusAnnotation:annotation andCenterOnMap:YES];
    }
}

- (void)focusAnnotation:(FINAnnotation *)annotation andCenterOnMap:(BOOL)moveToCenter
{
    self.pauseRefreshing = YES;
    [_mapView selectAnnotation:annotation animated:YES];
    if (moveToCenter == YES)
    {
        // If user changed zoom - don't reset it; otherwise go with the setting
        MKCoordinateRegion newRegion;
        if (self.userDidChangeZoom)
        {
            newRegion = self.mapView.region;
            newRegion.center = annotation.coordinate;
        }
        else
        {
            CLLocationDistance radiusInMeters = [_dataManager getRadiusSetting] * 1000;
            newRegion = MKCoordinateRegionMakeWithDistance(annotation.coordinate, radiusInMeters, radiusInMeters);
        }
        [_mapView setRegion:newRegion animated:YES];
    }
    self.pauseRefreshing = NO;
    
    _focusSignalID = nil;
}

- (void)setFocusSignalID:(NSString *)focusSignalID
{
    _focusSignalID = focusSignalID;
    
    [[FINDataManager sharedManager] getSignalWithID:focusSignalID completion:^(FINSignal *signal, FINError *error) {
        if (signal)
        {
            [self addAnnotationToMapFromSignal:signal];
        }
        else
        {
            NSLog(@"Failed to get signal for ID %@", focusSignalID);
            [self showAlertForError:error];
        }
    }];
}

- (void)updateMapWithNearbySignals:(NSArray *)nearbySignals
{
    for (FINSignal *signal in nearbySignals)
    {
        [UIView animateWithDuration:0.3 animations:^{
            [self addAnnotationToMapFromSignal:signal];
        }];
    }
}

- (void)removeAllSignalAnnotationsFromMap
{
    NSArray *mapAnnotations = [_mapView annotations];
    NSMutableArray *signalAnnotations = [NSMutableArray new];
    
    // Remove only signal annotations
    for (id annotation in mapAnnotations)
    {
        if ([annotation isKindOfClass:[FINAnnotation class]])
        {
            [signalAnnotations addObject:annotation];
        }
    }
    
    [_mapView removeAnnotations:signalAnnotations];
}

#pragma mark - Drag Gesture Recognizer
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)userDidMoveMap:(UIGestureRecognizer*)gestureRecognizer
{
    [_signalTitleField resignFirstResponder];
    
    if (_isInSubmitMode == YES)
    {
        self.submitSignalAnnotation.coordinate = self.mapView.centerCoordinate;
    }
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]])
        {
            self.userDidChangeZoom = YES;
        }
        
        if (_isInSubmitMode == NO)
        {
            [self refreshOverridingDampening:NO];
        }
    }
}

#pragma mark - Map Delegate
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (_isInSubmitMode == YES)
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.submitSignalAnnotation.coordinate = self.mapView.centerCoordinate;
        }];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id)annotation
{
    // If the annotation is the user location, just return nil so the default annotation view is used
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        return nil;
    }
    else if ([annotation isKindOfClass:[FINAnnotation class]])
    {
        FINAnnotation *ann = (FINAnnotation *)annotation;        
        MKAnnotationView *newAnnotationView = (MKAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:kStandardSignalAnnotationView];
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
        
        return newAnnotationView;
    }
    else if ([annotation isKindOfClass:[MKPointAnnotation class]])
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
        
        _submitSignalAnnotationView = pinAnnotationView;
        return pinAnnotationView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if ([view.reuseIdentifier isEqualToString:kStandardSignalAnnotationView])
    {
        FINAnnotation *annotation = (FINAnnotation *)view.annotation;
        [annotation updateAnnotationSubtitle];
        
        // If there is a signal photo, set it as the left accessory view
        if (annotation.signal.photoUrl)
        {
            [self imageGetterFrom:annotation.signal.photoUrl forAnnotationView:view];
        }
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    FINAnnotation *annotation = (FINAnnotation *)view.annotation;
    FINSignalDetailsVC *signalDetailsVC = [[FINSignalDetailsVC alloc] initWithAnnotation:annotation];
    signalDetailsVC.delegate = self;
    signalDetailsVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:signalDetailsVC];
    navController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:navController animated:YES completion:^{}];
}

//Code dublication with FiNSignalDetailVC
- (void)imageGetterFrom:(NSURL *)url forAnnotationView:(MKAnnotationView *)annotationView{
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager loadImageWithURL:url
                      options:0
                    progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {}
     completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
         if (image && finished)
         {
             printf("%ld", (long)cacheType);
             [self setImage:image forAnnotationView:annotationView];
         }
     }];
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

- (void)showAlertForError:(FINError *)error
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Ooops!",nil)
                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"Something went wrong! Server said:\n%@",nil), error.message]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self dismissViewControllerAnimated:YES completion:nil];
                                                          }];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:^{}];
}


#pragma mark - Refresh
- (void)refreshButtonTapped:(id)sender
{
    [self refreshOverridingDampening:YES];
}

- (void)refreshOverridingDampening:(BOOL)overrideDampening
{
    CLLocation *newCenter = [[CLLocation alloc] initWithLatitude:_mapView.centerCoordinate.latitude longitude:_mapView.centerCoordinate.longitude];
    MKCoordinateRegion region = _mapView.region;
    //https://stackoverflow.com/questions/21273269/trying-to-get-the-span-size-in-meters-for-an-ios-mkcoordinatespan
    //get latitude in meters
    CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:(region.center.latitude - region.span.latitudeDelta * 0.5) longitude:region.center.longitude];
    NSInteger latitudeDeltaMeters = [loc1 distanceFromLocation:newCenter];
    //get longitude in meters
    CLLocation *loc3 = [[CLLocation alloc] initWithLatitude:region.center.latitude longitude:(region.center.longitude - region.span.longitudeDelta * 0.5)];
    NSInteger longitudeDeltaMeters = [loc3 distanceFromLocation:newCenter];
    NSInteger maxRadius = MAX(latitudeDeltaMeters, longitudeDeltaMeters);
    
    BOOL shouldRefresh = YES;
    if ((overrideDampening == NO) && (self.lastRefreshCenter != nil))
    {
        NSInteger centerDistance = [newCenter distanceFromLocation:self.lastRefreshCenter];
        if ((centerDistance < 500) && (maxRadius <= self.lastRefreshRadius))
        {
            shouldRefresh = NO;
        }
    }
    
    if (shouldRefresh)
    {
        [self setupRefreshingMode];
        self.lastRefreshCenter = newCenter;
        self.lastRefreshRadius = maxRadius;
        [_dataManager getSignalsForLocation:newCenter inRadius:maxRadius overridingDampening:overrideDampening withCompletionHandler:^(UIBackgroundFetchResult result) {
            [self setupReadyMode];
        }];
    }
}

- (void)setupRefreshingMode
{
    self.navigationItem.rightBarButtonItems = @[_addBarButton, _refreshingBarButton];
}

- (void)setupReadyMode
{
    self.navigationItem.rightBarButtonItems = @[_addBarButton, _refreshBarButton];
}

#pragma mark - Menu
- (void)menuButtonTapped:(id)sender
{
    [_signalTitleField resignFirstResponder];
    
    [self.viewDeckController openSide:IIViewDeckSideLeft animated:YES];
}

#pragma mark - Privacy policy
- (void)checkForPrivacyPolicyAcceptance
{
    if (_dataManager.userIsLogged)
    {
        if (!_dataManager.getUserHasAcceptedPrivacyPolicy)
        {
            // If user hasn't accepted the privacy policy - log them out to force a login which comes only after acceptance of the policy
            [_dataManager logoutWithCompletion:^(FINError *error) {
                //Do nothing
            }];
        }
    }
}

#pragma mark - Environment switching

- (void)updateTitle
{
    NSMutableString *title = [NSMutableString stringWithString:@"Help a Paw"];
    if ([_dataManager getIsInTestMode])
    {
        [title appendString:@" (TEST)"];
    }
    
    self.navigationItem.title = title;
}

- (void)setupEnvironmentSwitching
{
    _envSwitchGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchEnvironment:)];
    _envSwitchGesture.numberOfTapsRequired = 7;
    // This allows controlls in the navigation bar to continue receiving touches
    _envSwitchGesture.cancelsTouchesInView = NO;
    [self.navigationController.navigationBar addGestureRecognizer:_envSwitchGesture];
}

- (void)removeEnvironmentSwitching
{
    [self.navigationController.navigationBar removeGestureRecognizer:_envSwitchGesture];
}

- (void)switchEnvironment:(UITapGestureRecognizer *)gr
{
    [_dataManager setIsInTestMode:![_dataManager getIsInTestMode]];
    [self updateTitle];
    self.lastRefreshCenter = nil;
    self.lastRefreshRadius = 0;
    [self removeAllSignalAnnotationsFromMap];
    [self refreshOverridingDampening:YES];
}

@end
