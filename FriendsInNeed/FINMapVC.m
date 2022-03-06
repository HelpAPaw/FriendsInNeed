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
#import "FINImagePickerController.h"
#import "FINGlobalConstants.pch"
@import FirebaseCrashlytics;


#define kAddSignalViewYposition 15.0f
#define kAddSignalViewYbounce   10.0f
#define kButtonBlueColor [UIColor colorWithRed:13.0f/255.0f green:95.0f/255.0f blue:255.0f/255.0f alpha:1.0f]
#define kSubmitSignalAnnotationView     @"SubmitSignalAnnotationView"
#define kStandardSignalAnnotationView   @"StandardSignalAnnotationView"


@interface FINMapVC () <MKMapViewDelegate, UIGestureRecognizerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, FINSignalTypesSelectionDelegate, FINImagePickerControllerDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIView *addSignalView;
@property (weak, nonatomic) IBOutlet UITextView *signalTitleTextView;
@property (weak, nonatomic) IBOutlet UITextField *authorPhoneField;
@property (weak, nonatomic) IBOutlet UITextField *signalTypeField;
@property (strong, nonatomic) UIPickerView *signalTypePicker;
@property (weak, nonatomic) IBOutlet UIButton *btnPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnSendSignal;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sendSignalButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *liSendSignal;
@property (weak, nonatomic) IBOutlet UILabel *filterIsActiveLabel;

@property (strong, nonatomic) UIBarButtonItem *addBarButton;
@property (strong, nonatomic) UIBarButtonItem *refreshBarButton;
@property (strong, nonatomic) UIBarButtonItem *refreshingBarButton;
@property (strong, nonatomic) UIBarButtonItem *filterBarButton;
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
@property (strong, nonatomic) NSArray<NSNumber *> *selectedSignalTypes;
@property (strong, nonatomic) UIColor *placeholderColor;
@property (strong, nonatomic) FINImagePickerController *imagePickerController;
@property (strong, nonatomic) NSString *focusedSignalId;

@end

@implementation FINMapVC

- (void)setupAddSignalView {
    _cancelButton.tintColor = [UIColor redColor];
    _cancelButton.layer.shadowOpacity = 1.0f;
    _cancelButton.layer.shadowColor = [UIColor redColor].CGColor;
    _cancelButton.layer.shadowOffset = CGSizeMake(0, 0);
    _cancelButton.alpha = 0.0f;
    
    _signalTitleTextView.layer.cornerRadius = 5.0f;
    _signalTitleTextView.layer.borderWidth = 1.0f;
    _signalTitleTextView.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
    
    _addSignalView.layer.cornerRadius = 5.0f;
    _addSignalView.layer.shadowOpacity = 1.0f;
    _addSignalView.layer.shadowColor = [UIColor grayColor].CGColor;
    _addSignalView.layer.shadowOffset = CGSizeMake(0, 0);
    
    _signalTypePicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    _signalTypePicker.delegate = self;
    _signalTypePicker.dataSource = self;
    _signalTypeField.inputView = _signalTypePicker;
    _signalTypeField.text = _dataManager.signalTypes[0];
    
    UIButton *rightViewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightViewButton setImage:[UIImage imageNamed:@"ic_dropdown"] forState:UIControlStateNormal];
    rightViewButton.imageEdgeInsets = UIEdgeInsetsMake(6, 4, 6, 4);
    [rightViewButton addTarget:self action:@selector(signalTypeDropdownTapped:) forControlEvents:UIControlEventTouchUpInside];
    _signalTypeField.rightView = rightViewButton;
    _signalTypeField.rightViewMode = UITextFieldViewModeAlways;
    
    _btnPhoto.layer.cornerRadius = 5.0f;
    _btnPhoto.clipsToBounds = YES;
    [[_btnPhoto imageView] setContentMode: UIViewContentModeScaleAspectFill];
    
    [_btnSendSignal sizeToFit];
    _sendSignalButtonWidthConstraint.constant = _btnSendSignal.frame.size.width + 10;
    
    _isInSubmitMode = NO;
}

- (void)setupNavigationBar {
    self.navigationItem.title = @"Help a Paw";
    
    // Create add bar button
    UIImage *addImage = [UIImage imageNamed:@"ic_add"];
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [addButton setFrame:CGRectMake(0, 0, addImage.size.width, addImage.size.height)];
    [addButton setImage:addImage forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(onAddSignalButton:) forControlEvents:UIControlEventTouchUpInside];
    [addButton setShowsTouchWhenHighlighted:YES];
    _addBarButton = [[UIBarButtonItem alloc] initWithCustomView:addButton];
    
    // Create refresh bar button
    _refreshBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonTapped:)];
    
    // Create loading bar button
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator setFrame:CGRectMake(0, 0, 30, 30)];
    [activityIndicator startAnimating];
    _refreshingBarButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    
    // Create filter bar button
    UIImage *filterImage = [UIImage imageNamed:@"ic_filter_list_white_36pt"];
    UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [filterButton setFrame:CGRectMake(0, 0, filterImage.size.width, filterImage.size.height)];
    [filterButton setImage:filterImage forState:UIControlStateNormal];
    [filterButton addTarget:self action:@selector(onFilterButton:) forControlEvents:UIControlEventTouchUpInside];
    [filterButton setShowsTouchWhenHighlighted:YES];
    _filterBarButton = [[UIBarButtonItem alloc] initWithCustomView:filterButton];
    
    [self setupReadyMode];
    
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ic_menu"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(menuButtonTapped:)];
    self.navigationItem.leftBarButtonItem = menuButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _viewDidAppearOnce = NO;
    
    _locationManager = [FINLocationManager sharedManager];
    _locationManager.mapDelegate = self;
    
    [_locationManager startMonitoringSignificantLocationChanges];
    
    _dataManager = [FINDataManager sharedManager];
    _dataManager.mapDelegate = self;
    
    // Initially all signal types are selected
    NSMutableArray *selectedSignalTypes = [NSMutableArray new];
    for (int i = 0; i < _dataManager.signalTypes.count; i++) {
        [selectedSignalTypes addObject:[NSNumber numberWithBool:YES]];
    }
    _selectedSignalTypes = selectedSignalTypes;
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(focusedSignalChanged:)
                                                 name:kNotificationFocusedSignalChanged
                                               object:nil];
    
    UIPanGestureRecognizer *dragGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(userDidMoveMap:)];
    [dragGR setDelegate:self];
    [self.mapView addGestureRecognizer:dragGR];
    UIPinchGestureRecognizer *pinchGR = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(userDidMoveMap:)];
    [pinchGR setDelegate:self];
    [self.mapView addGestureRecognizer:pinchGR];
    
    _filterIsActiveLabel.text = NSLocalizedString(@"filter_is_active", nil);
    _filterIsActiveLabel.layer.cornerRadius = 15.0;
    _filterIsActiveLabel.layer.masksToBounds = YES;
    
    _placeholderColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    
    [self setupAddSignalView];
    
    [self setupNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_viewDidAppearOnce == NO)
    {
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

- (void)settingsChanged:(NSNotification *)notification
{
    [self initMapVC];
}

- (void)focusedSignalChanged:(NSNotification *)notification
{
    // Dismiss any presented view controllers
    [self dismissViewControllerAnimated:YES completion:^{}];
    
    NSDictionary *userInfo = [notification userInfo];
    NSString *signalId = [userInfo objectForKey:kSignalId];
    [self setFocusedSignalId:signalId];
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

#pragma mark - UITextViewDelegate
// UITextView doesn't have a placeholder so we have to fake it, unfortunatelly
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ((textView == _signalTitleTextView) &&
        [textView.textColor isEqual:_placeholderColor] &&
        [textView isFirstResponder]) {
            textView.text = nil;
            textView.textColor = [UIColor darkTextColor];
        }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ((textView == _signalTitleTextView) &&
        ((textView.text == nil) || [textView.text isEqualToString:@""])) {
        [self setPlaceholderInSignalDescriptionTextView];
    }
}

- (void)setPlaceholderInSignalDescriptionTextView
{
    _signalTitleTextView.textColor = _placeholderColor;
    _signalTitleTextView.text = NSLocalizedString(@"signal_description_placeholder", nil);
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
        
        [self setPlaceholderInSignalDescriptionTextView];
        _authorPhoneField.text = [_dataManager getUserPhone];
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
                    
                    [self.signalTitleTextView resignFirstResponder];
                    [self.authorPhoneField resignFirstResponder];
                    [self.signalTypeField resignFirstResponder];
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
    if ([[FINDataManager sharedManager] userIsLogged] == NO)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"registration_required",nil)
                                                                       message:NSLocalizedString(@"only_registered_users_can_submit_signals",nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self showLoginScreen];
                                                              }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction * action) {}];
        [alert addAction:okAction];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:^{}];
        
        return;
    }
    
    [self toggleSubmitMode];
}

- (IBAction)onSendButton:(id)sender
{
    // Delete placeholder before validation
    if ([_signalTitleTextView.textColor isEqual:_placeholderColor]) {
        _signalTitleTextView.text = @"";
    }
    
    // Input validation
    BOOL validation = [InputValidator validateDefaultMinMaxLengthInputFor:@[_signalTitleTextView] message:NSLocalizedString(@"enter_good_description", nil) parent:self];
    if (!validation)
    {
        [_signalTitleTextView becomeFirstResponder];
        return;
    }
    
    CLS_LOG(@"Submitting new signal...");
    
    [self setSendingSignalMode];
    [_dataManager submitNewSignalWithTitle:_signalTitleTextView.text
                                      type:[_signalTypePicker selectedRowInComponent:0]
                            andAuthorPhone:(NSString *)_authorPhoneField.text
                               forLocation:_submitSignalAnnotation.coordinate
                                 withPhoto:_signalPhoto
                                completion:^(FINSignal *savedSignal, FINError *error) {
        
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
                                                                          self.focusedSignalId = savedSignal.signalId;
                                                                          [self addAnnotationToMapFromSignal:savedSignal];
                                                                      }];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:^{}];
            }
            else
            {
                // Add new annotation to map and focus it when OK button is pressed
                self.focusedSignalId = savedSignal.signalId;
                [self addAnnotationToMapFromSignal:savedSignal];
            }
        }
        else
        {
            [self showAlertForError:error];
        }
    }];
    
    [_signalTitleTextView resignFirstResponder];
    [_authorPhoneField resignFirstResponder];
}

- (IBAction)onAttachPhotoButton:(id)sender
{
    _imagePickerController = [[FINImagePickerController alloc] initWithDelegate:self];
    [_imagePickerController showImagePickerFrom:self withSourceView:sender];
}

#pragma mark - FINImagePickerControllerDelegate
- (void)didPickImage:(UIImage *)image
{
    _signalPhoto = image;
    [_btnPhoto setImage:_signalPhoto forState:UIControlStateNormal];
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
            if (   ([ann.signal.signalId isEqualToString:signal.signalId] == YES)
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
    
    if ([annotation.signal.signalId isEqualToString:_focusedSignalId])
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
    
    _focusedSignalId = nil;
}

- (void)setFocusedSignalId:(NSString *)focusSignalID
{
    _focusedSignalId = focusSignalID;
    
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
        // Only add signal if current filter has its type selected
        if ((signal.type < _selectedSignalTypes.count) &&
            (_selectedSignalTypes[signal.type].boolValue)) {
            [UIView animateWithDuration:0.3 animations:^{
                [self addAnnotationToMapFromSignal:signal];
            }];
        }
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
    [_signalTitleTextView resignFirstResponder];
    [_authorPhoneField resignFirstResponder];
    
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
            
            // Add a details label that shows the status and type
            UILabel *subtitleLabel = [UILabel new];
            subtitleLabel.numberOfLines = 0;
            subtitleLabel.font = [UIFont systemFontOfSize:UIFont.smallSystemFontSize];
            subtitleLabel.textColor = [UIColor grayColor];
            newAnnotationView.detailCalloutAccessoryView = subtitleLabel;
        }
        else
        {
            newAnnotationView.annotation = annotation;
        }
        
        NSString *statusString = [FINSignal localizedStatusString:ann.signal.status];
        statusString = [NSString stringWithFormat:NSLocalizedString(@"Status: %@",nil), statusString];
        NSString *typeString = @"";
        if (ann.signal.type < [FINDataManager sharedManager].signalTypes.count)
        {
            typeString = [FINDataManager sharedManager].signalTypes[ann.signal.type];
            typeString = [NSString stringWithFormat:NSLocalizedString(@"Type: %@", nil), typeString];
        }
        UILabel *subtitleLabel = (UILabel *)newAnnotationView.detailCalloutAccessoryView;
        subtitleLabel.text = [NSString stringWithFormat:@"%@\n%@", statusString, typeString];        
        
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
    
    CLS_LOG(@"Show details for signal %@", annotation.signal.signalId);
    
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
    
    imageFrame.size.height = 50.0;
    imageFrame.size.width  = 50.0;
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

- (void)removeAnnotation:(FINAnnotation *)annotation
{
    MKAnnotationView *view = [self.mapView viewForAnnotation:annotation];

    if (view) {
        [UIView animateWithDuration:0.5 delay:0.0 options:0 animations:^{
            view.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.mapView removeAnnotation:annotation];
            view.alpha = 1.0;   // remember to set alpha back to 1.0 because annotation view can be reused later
        }];
    } else {
        [self.mapView removeAnnotation:annotation];
    }
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

#pragma mark
- (void)signalTypeDropdownTapped:(id)sender
{
    [_signalTypeField becomeFirstResponder];
}

#pragma mark - UIPickerView Data Source
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    if (pickerView == _signalTypePicker) {
        return 1;
    }
    
    return 0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == _signalTypePicker) {
        return _dataManager.signalTypes.count;
    }
    
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == _signalTypePicker) {
        return _dataManager.signalTypes[row];
    }
    
    return @"";
}

#pragma mark - UIPickerView Delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView == _signalTypePicker) {
        _signalTypeField.text = _dataManager.signalTypes[row];
    }
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
    self.navigationItem.rightBarButtonItems = @[_addBarButton, _refreshingBarButton, _filterBarButton];
}

- (void)setupReadyMode
{
    self.navigationItem.rightBarButtonItems = @[_addBarButton, _refreshBarButton, _filterBarButton];
}

#pragma mark - Menu
- (void)menuButtonTapped:(id)sender
{
    [_signalTitleTextView resignFirstResponder];
    [_authorPhoneField resignFirstResponder];
    
    [self.viewDeckController openSide:IIViewDeckSideLeft animated:YES];
}

#pragma mark - Filter
- (void)onFilterButton:(id)sender
{
    FINSignalTypesSelectionTVC *stsTVC = [[FINSignalTypesSelectionTVC alloc] initWith:_selectedSignalTypes and:self];
    [self.navigationController pushViewController:stsTVC animated:YES];
}

- (void)signalTypesSelectionFinishedWith:(NSArray<NSNumber *> *)newTypesSelection
{
    _selectedSignalTypes = newTypesSelection;
    
    // Re-add signals to apply the updated filter
    [self removeAllSignalAnnotationsFromMap];
    [self updateMapWithNearbySignals:_dataManager.nearbySignals];
    
    // Update filter label visibility
    NSInteger count = 0;
    for (NSNumber *typeSetting in _selectedSignalTypes) {
        if (typeSetting.boolValue) {
            count++;
        }
    }
    if (count == _dataManager.signalTypes.count) {
        _filterIsActiveLabel.hidden = YES;
    }
    else {
        _filterIsActiveLabel.hidden = NO;
    }
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
