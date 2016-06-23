//
//  FINSignalDetailsVC.m
//  FriendsInNeed
//
//  Created by Milen on 08/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignalDetailsVC.h"
#import "FINDataManager.h"
#import "FINSignalDetailsCell.h"
#import "FINSignalDetailsCommentCell.h"
#import "FINGlobalConstants.pch"
#import "FINComment.h"
#import "FINError.h"

#define kTitleIndex     0
#define kAuthorIndex    1
#define kDateIndex      2

#define kTitleLabel     @"Title"
#define kAuthorLabel    @"Author"
#define kDateLabel      @"Date"

#define kCellIdentifierGeneral    @"GeneralCell"
#define kCellIdentifierDetails    @"DetailsCell"
#define kCellIdentifierStatus     @"StatusCell"
#define kCellIdentifierComment    @"CommentCell"
#define kCellIdentifierLoading    @"LoadingCell"



enum {
    kSectionIndexDetails,
    kSectionIndexStatusHeader,
    kSectionIndexStatus,
    kSectionIndexCommentsHeader,
    kSectionIndexComments,
    kSectionIndexCount
};

enum {
    kCellIndexStatusSelected = 0,
    kCellIndexStatus0 = 0,
    kCellIndexStatus1,
    kCellIndexStatus2,
};


#define kCellIdentifierTitle    @"TitleCell"
#define kCellIdentifierAuthor   @"AuthorCell"
#define kCellIdentifierDate     @"DateCell"

@interface FINSignalDetailsVC () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *addCommentView;
@property (weak, nonatomic) IBOutlet UITextField *addCommentTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addCommentLC;
@property (weak, nonatomic) IBOutlet UIButton *sendCommentButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *sendCommentLoadingIndicator;

@property (strong, nonatomic) FINAnnotation *annotation;
@property (strong, nonatomic) NSMutableArray *comments;
@property (assign, nonatomic) BOOL statusIsExpanded;
@property (assign, nonatomic) NSUInteger status;
@property (assign, nonatomic) CGFloat keyboardHeight;
@property (assign, nonatomic) BOOL keybaordIsShown;
@property (assign, nonatomic) BOOL commentsAreLoaded;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation FINSignalDetailsVC

- (FINSignalDetailsVC *)initWithAnnotation:(FINAnnotation *)annotation
{
    self = [self init];
    
    _annotation = annotation;
    _status = _annotation.signal.status;
    _comments = [NSMutableArray new];
    _commentsAreLoaded = NO;
    
    _dateFormatter = [NSDateFormatter new];
    [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[FINDataManager sharedManager] getCommentsForSignal:_annotation.signal completion:^(NSArray *comments, FINError *error) {
        
        _commentsAreLoaded = YES;
        if (!error)
        {
            [_comments addObjectsFromArray:comments];
            [_tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionIndexComments] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self determineIfAddCommentShadowShouldBeVisible];
        }
        else
        {
#warning error handling
        }
    }];
    
    _tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, _addCommentView.frame.size.height, 0.0f);
    [_tableView registerNib:[UINib nibWithNibName:@"FINSignalDetailsCell" bundle:nil] forCellReuseIdentifier:kCellIdentifierDetails];
    [_tableView registerNib:[UINib nibWithNibName:@"FINSignalDetailsCommentCell" bundle:nil] forCellReuseIdentifier:kCellIdentifierComment];
    
    self.navigationItem.title = @"Signals Details";
    
    _toolbar.layer.shadowColor = [UIColor colorWithRed:255.0f/255.0f green:150.0f/255.0f blue:66.0f/255.0f alpha:0.5f].CGColor;
    _toolbar.layer.shadowOpacity = 1.0f;
    _toolbar.layer.shadowOffset = (CGSize){0.0f, 2.0f};
    
    // Add upper line border on the comment view
    CALayer *upperBorder = [CALayer layer];
    upperBorder.backgroundColor = [[UIColor colorWithWhite:0.8f alpha:1.0f] CGColor];
    upperBorder.frame = CGRectMake(0, 0, CGRectGetWidth(_addCommentView.frame), 0.5f);
    [_addCommentView.layer addSublayer:upperBorder];
    
    _addCommentView.layer.shadowOffset = CGSizeMake(0, -2);
    _addCommentView.layer.shadowColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    
    NSString *backButtonText = @"Close";
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:backButtonText style:UIBarButtonItemStylePlain target:self action:@selector(onCloseButton:)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    _statusIsExpanded = NO;
    
    UITapGestureRecognizer* cGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContainerTap:)];
    cGR.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:cGR];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self determineIfAddCommentShadowShouldBeVisible];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark - Gesture Recognizers
- (void)onContainerTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        // End editing only if tap was outside of add comment view
        CGPoint tap = [sender locationInView:self.view];
        if (CGRectContainsPoint(_addCommentView.frame, tap) == NO)
        {
            [self.view endEditing:YES];
        }
    }
}

#pragma mark - TableView data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kSectionIndexCount;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self determineIfAddCommentShadowShouldBeVisible];
}

- (void)determineIfAddCommentShadowShouldBeVisible
{
    CGFloat keyboardCompensation;
    if (_keybaordIsShown)
    {
        keyboardCompensation = _keyboardHeight;
    }
    else
    {
        keyboardCompensation = 0.0f;
    }
    
    if ((_tableView.contentOffset.y + _tableView.frame.size.height - _addCommentView.frame.size.height - keyboardCompensation) >= _tableView.contentSize.height)
    {
        _addCommentView.layer.shadowOpacity = 0.0f;
    }
    else
    {
        _addCommentView.layer.shadowOpacity = 1.0f;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 1;
    if ( (section == kSectionIndexStatus) && (_statusIsExpanded) )
    {
        rows = 3;
    }
    else if (section == kSectionIndexComments)
    {
        if (_commentsAreLoaded)
        {
            rows = _comments.count;
        }
        else
        {
            rows = 1;
        }
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.section) {
        case kSectionIndexDetails:
        {
            FINSignalDetailsCell *detailsCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierDetails];
            
            detailsCell.backgroundColor = [UIColor clearColor];
            detailsCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            [detailsCell setTitle:_annotation.signal.title];
            [detailsCell setAuthor:_annotation.signal.authorName];
            [detailsCell setPhoneNumber:_annotation.signal.authorPhone];
            [detailsCell setDate:[_dateFormatter stringFromDate:_annotation.signal.date]];
            if (_annotation.signal.photo)
            {
                [detailsCell setPhoto:_annotation.signal.photo];
            }
            
            
            cell = detailsCell;
            break;
        }
        case kSectionIndexStatusHeader:
        {
            UITableViewCell *statusLabelCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierGeneral];
            if (!statusLabelCell)
            {
                statusLabelCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierGeneral];
                statusLabelCell.backgroundColor = [UIColor clearColor];
                statusLabelCell.selectionStyle = UITableViewCellSelectionStyleNone;
                statusLabelCell.indentationLevel = 0;
                statusLabelCell.textLabel.textColor = [UIColor grayColor];
            }
            
            statusLabelCell.textLabel.text = @"Status";
            
            cell = statusLabelCell;
            break;
        }
        case kSectionIndexStatus:
        {
            UITableViewCell *statusCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierStatus];
            if (!statusCell)
            {
                statusCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierStatus];
                statusCell.backgroundColor = [UIColor clearColor];
                statusCell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            UIImage *statusImage;
            NSString *statusString;
            
            if (_statusIsExpanded == NO)
            {
                statusCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_dropdown"]];
                
                switch (_status) {
                    case 0:
                        statusImage = [UIImage imageNamed:@"pin_red"];
                        statusString = @"Help needed";
                        break;
                    case 1:
                        statusImage = [UIImage imageNamed:@"pin_orange"];
                        statusString = @"Somebody on the way";
                        break;
                    case 2:
                        statusImage = [UIImage imageNamed:@"pin_green"];
                        statusString = @"Solved";
                        break;
                        
                    default:
                        break;
                }
            }
            else
            {
                switch (indexPath.row) {
                    case kCellIndexStatus0:
                        
                        statusImage = [UIImage imageNamed:@"pin_red"];
                        statusString = @"Help needed";
                        break;
                        
                    case kCellIndexStatus1:
                        
                        statusImage = [UIImage imageNamed:@"pin_orange"];
                        statusString = @"Somebody on the way";
                        break;
                        
                    case kCellIndexStatus2:
                        
                        statusImage = [UIImage imageNamed:@"pin_green"];
                        statusString = @"Solved";
                        break;
                        
                    default:
                        break;
                }
                
                if (_status == indexPath.row)
                {
                    statusCell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                else
                {
                    statusCell.accessoryType = UITableViewCellAccessoryNone;
                }
                statusCell.accessoryView = nil;
            }
            
            [statusCell.imageView setImage:statusImage];
            statusCell.textLabel.text = statusString;
            
            cell = statusCell;
            break;
        }
        case kSectionIndexCommentsHeader:
        {
            UITableViewCell *commentsLabelCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierGeneral];
            if (!commentsLabelCell)
            {
                commentsLabelCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierGeneral];
                commentsLabelCell.backgroundColor = [UIColor clearColor];
                commentsLabelCell.selectionStyle = UITableViewCellSelectionStyleNone;
                commentsLabelCell.indentationLevel = 0;
                commentsLabelCell.textLabel.textColor = [UIColor grayColor];
            }
            
            commentsLabelCell.textLabel.text = @"Comments";
            
            cell = commentsLabelCell;
            break;
        }
            
        default:
        {
            if (_commentsAreLoaded)
            {
                FINSignalDetailsCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierComment];
                
                commentCell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                FINComment *comment = _comments[indexPath.row];
                
                [commentCell setCommentText:comment.text];
                [commentCell setAuthor:comment.author.name];
                [commentCell setDate:[_dateFormatter stringFromDate:comment.created]];
                
                cell = commentCell;
            }
            else 
            {
                UITableViewCell *loadingCommentsCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierLoading];
                if (!loadingCommentsCell)
                {
                    loadingCommentsCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierLoading];
                    loadingCommentsCell.backgroundColor = [UIColor clearColor];
                    loadingCommentsCell.selectionStyle = UITableViewCellSelectionStyleNone;
                    
                    // Create a loading indicator
                    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    [activityIndicator startAnimating];
                    // Place it in the center
                    CGRect indicatorFrame = activityIndicator.frame;
                    indicatorFrame.origin.x = (self.view.frame.size.width - indicatorFrame.size.width) / 2;
                    activityIndicator.frame = indicatorFrame;
                    // Add it to the cell
                    [loadingCommentsCell addSubview:activityIndicator];
                }
                
                cell = loadingCommentsCell;
            }
            break;
        }
            
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    float height;
    switch (indexPath.section) {
        case kSectionIndexDetails:
            height = 150.0f;
            break;
        case kSectionIndexStatus:
            height = 55.0f;
            break;
        case kSectionIndexComments:
        {
            if (_commentsAreLoaded)
            {
                FINComment *comment = _comments[indexPath.row];
                NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:comment.text attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17]}];
                CGRect rect = [attributedText boundingRectWithSize:(CGSize){self.view.frame.size.width - (15 * 2), 150} options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
                height = ceilf(rect.size.height) + 55;
            }
            else 
            {
                height = 44.0f;
            }
            break;
        }
            
        default:
            height = 44.0f;
            break;
    }
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kSectionIndexStatus)
    {
        if (_statusIsExpanded)
        {
            if (_status != indexPath.row)
            {
                UITableViewCell *oldStatusCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_status inSection:indexPath.section]];
                oldStatusCell.accessoryType = UITableViewCellAccessoryNone;
                
                _status = indexPath.row;
                UITableViewCell *newStatusCell = [tableView cellForRowAtIndexPath:indexPath];
                newStatusCell.accessoryType = UITableViewCellAccessoryCheckmark;
                
                [[FINDataManager sharedManager] setStatus:_status forSignal:_annotation.signal completion:^(FINError *error) {
                    if (error == nil) {
#warning Error handling
                    }
                }];
            }
            
            _statusIsExpanded = !_statusIsExpanded;
            [self performSelector:@selector(reloadStatusSection) withObject:nil afterDelay:0.1];
        }
        else
        {
            _statusIsExpanded = !_statusIsExpanded;
            [self performSelector:@selector(reloadStatusSection) withObject:nil afterDelay:0.0];
        }
    }
}

- (void)reloadStatusSection
{
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:kSectionIndexStatus] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (IBAction)onCloseButton:(id)sender
{
    [self.delegate refreshAnnotation:_annotation];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)onAddCommentButton:(id)sender
{
    [_addCommentTextField resignFirstResponder];

    [self setSendingCommentMode];
    [[FINDataManager sharedManager] saveComment:_addCommentTextField.text forSigna:_annotation.signal completion:^(FINComment *comment, FINError *error) {
        
        [self resetSendingCommentMode];
        
        if (!error)
        {
            [_comments addObject:comment];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_comments indexOfObject:comment] inSection:kSectionIndexComments];
            [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            
            _addCommentTextField.text = @"";
        }
        else
        {
#warning show error
        }
    }];
}

- (void)setSendingCommentMode
{
    _sendCommentButton.hidden = YES;
    [_sendCommentLoadingIndicator startAnimating];
}

- (void)resetSendingCommentMode
{
    _sendCommentButton.hidden = NO;
    [_sendCommentLoadingIndicator stopAnimating];
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _addCommentTextField)
    {
        [self onAddCommentButton:_sendCommentButton];
    }
    
    return YES;
}

#pragma mark - Keyboard show/hide management
- (void)keyboardWillShow:(NSNotification *)note
{
    // Get the keyboard height
    CGRect keyboardFrame;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardFrame];
    _keyboardHeight = keyboardFrame.size.height;
    
    // Extend the table view so it can be scrolled all the way
    UIEdgeInsets insets = _tableView.contentInset;
    insets.bottom += _keyboardHeight;
    _tableView.contentInset = insets;
    
    [UIView animateWithDuration:0.3f animations:^{
        
        // Move the comment view above the keyboard
        CGRect frame = _addCommentView.frame;
        frame.origin.y -= _keyboardHeight;
        _addCommentView.frame = frame;
        
        // Modify its bottom constraint, too
        _addCommentLC.constant = _keyboardHeight;
        [_addCommentView setNeedsLayout];
    }];
    
    _keybaordIsShown = YES;
    [self determineIfAddCommentShadowShouldBeVisible];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    // Get the keyboard height
    CGRect keyboardFrame;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardFrame];
    _keyboardHeight = keyboardFrame.size.height;
    
    // Restore original table view insets
    UIEdgeInsets insets = _tableView.contentInset;
    insets.bottom -= _keyboardHeight;
    _tableView.contentInset = insets;
    
    [UIView animateWithDuration:0.3f animations:^{
        
        // Return comment and table views to their original state
        CGRect frame = _addCommentView.frame;
        frame.origin.y += _keyboardHeight;
        _addCommentView.frame = frame;
        
        _addCommentLC.constant = 0.0f;
        [_addCommentView setNeedsLayout];
    }];
    
    _keybaordIsShown = NO;
    [self determineIfAddCommentShadowShouldBeVisible];
}

@end
