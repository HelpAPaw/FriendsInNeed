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

//#define kSectionIndexDetails       0
//#define kSectionIndexStatusHeader  1

enum {
    kSectionIndexDetails,
    kSectionIndexStatusHeader,
    kSectionIndexStatus,
    kSectionIndexCommentsHeader,
    kSectionIndexComments,
    kSectionIndexCount
};

enum {
    kCellIndexStatusSelected,
    kCellIndexStatus0,
    kCellIndexStatus1,
    kCellIndexStatus2,
};


#define kCellIdentifierTitle    @"TitleCell"
#define kCellIdentifierAuthor   @"AuthorCell"
#define kCellIdentifierDate     @"DateCell"

@interface FINSignalDetailsVC () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) GeoPoint *geoPoint;

@property (strong, nonatomic) NSArray *comments;
@property (assign, nonatomic) BOOL statusIsExpanded;
@property (assign, nonatomic) NSUInteger status;

@end

@implementation FINSignalDetailsVC

- (FINSignalDetailsVC *)initWithGeoPoint:(GeoPoint *)geoPoint
{
    self = [self init];
    
    _geoPoint = geoPoint;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    _tableView.contentInset = UIEdgeInsetsMake(_toolbar.frame.size.height, 0.0f, 0.0f, 0.0f);
    [_tableView registerNib:[UINib nibWithNibName:@"FINSignalDetailsCell" bundle:nil] forCellReuseIdentifier:kCellIdentifierDetails];
    [_tableView registerNib:[UINib nibWithNibName:@"FINSignalDetailsCommentCell" bundle:nil] forCellReuseIdentifier:kCellIdentifierComment];
    
    self.navigationItem.title = @"Signals Details";
    
    _toolbar.layer.shadowColor = [UIColor colorWithRed:255.0f/255.0f green:150.0f/255.0f blue:66.0f/255.0f alpha:0.5f].CGColor;
    _toolbar.layer.shadowOpacity = 1.0f;
    _toolbar.layer.shadowOffset = (CGSize){0.0f, 2.0f};
    
    NSString *backButtonText = @"Close";
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:backButtonText style:UIBarButtonItemStylePlain target:self action:@selector(onCloseButton:)];
    self.navigationItem.leftBarButtonItem = backButton;
    
    _comments = @[@"Heading there, will let you know when I arrive.", @"I'm here. The dog can't move, probably has a broken leg. Need a car to transport him to the vet!", @"I'm coming..."];
    
    _statusIsExpanded = NO;
    _status = 0;
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

#pragma mark - TableView data source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kSectionIndexCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 1;
    if ( (section == kSectionIndexStatus) && (_statusIsExpanded) )
    {
        rows = 4;
    }
    else if (section == kSectionIndexComments)
    {
        rows = _comments.count;
    }
    
    return rows;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    NSString *title;
//    switch (section) {
//        case 1:
//            title = @"Status";
//            break;
//            
//        default:
//            title = @"";
//            break;
//    }
//    
//    return title;
//}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    if (section != 1)
//    {
//        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
//        view.backgroundColor = [UIColor greenColor];
//        return view;
//    }
//    
//    UILabel *label = [[UILabel alloc] init];
//    label.textColor = [UIColor grayColor];
//    [label sizeToFit];
//    
////    NSString *labelText = @"";
////    switch (section) {
////        case kTitleIndex:
////            labelText = kTitleLabel;
////            break;
////        case kAuthorIndex:
////            labelText = kAuthorLabel;
////            break;
////        case kDateIndex:
////            labelText = kDateLabel;
////            break;
////            
////        default:
////            break;
////    }
//    
//    label.text = @"Status";
//    
//    CGRect containerFrame = label.frame;
//    containerFrame.size.height += 10;
//    containerFrame.size.width  += 10;
//    UIView *container = [[UIView alloc] initWithFrame:containerFrame];
//    
//    [container addSubview:label];
//    
//    return label;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.section) {
        case kSectionIndexDetails:
        {
            FINSignalDetailsCell *detailsCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierDetails];
            if (!detailsCell)
            {
                detailsCell = [[FINSignalDetailsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierDetails];
                detailsCell.backgroundColor = [UIColor clearColor];
                detailsCell.selectionStyle = UITableViewCellSelectionStyleNone;
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
            switch (indexPath.row) {
                case kCellIndexStatusSelected:
                    if (_statusIsExpanded)
                    {
                        statusCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_dropdown_reversed"]];
                    }
                    else
                    {
                        statusCell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_dropdown"]];
                    }
                    
                    statusImage = [UIImage imageNamed:@"pin_red"];
                    statusString = @"Help needed";
                    break;
                    
                case kCellIndexStatus0:
                    
                    statusImage = [UIImage imageNamed:@"pin_red"];
                    statusString = @"Help needed";
//                    statusCell.indentationLevel = 3;
                    if (_status == (indexPath.row - 1))
                    {
                        statusCell.accessoryType = UITableViewCellAccessoryCheckmark;
                    }
                    else
                    {
                        statusCell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    statusCell.accessoryView = nil;
                    break;
                    
                case kCellIndexStatus1:
                    
                    statusImage = [UIImage imageNamed:@"pin_orange"];
                    statusString = @"Somebody on the way";
                    //                    statusCell.indentationLevel = 3;
                    if (_status == (indexPath.row - 1))
                    {
                        statusCell.accessoryType = UITableViewCellAccessoryCheckmark;
                    }
                    else
                    {
                        statusCell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    statusCell.accessoryView = nil;
                    break;
                    
                case kCellIndexStatus2:
                    
                    statusImage = [UIImage imageNamed:@"pin_green"];
                    statusString = @"Solved";
                    //                    statusCell.indentationLevel = 3;
                    if (_status == (indexPath.row - 1))
                    {
                        statusCell.accessoryType = UITableViewCellAccessoryCheckmark;
                    }
                    else
                    {
                        statusCell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    statusCell.accessoryView = nil;
                    break;
                    
                default:
                    break;
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
            FINSignalDetailsCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierComment];
            if (!commentCell)
            {
                commentCell = [[FINSignalDetailsCommentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierComment];
                commentCell.backgroundColor = [UIColor clearColor];
                commentCell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            NSString *comment;
            NSString *author;
            switch (indexPath.row) {
                case 0:
                    comment = @"Heading there, will let you know when I arrive.";
                    author = @"Milen Marinov";
                    break;
                case 1:
                    comment = @"I'm here. The dog can't move, probably has a broken leg. Need a car to transport him to the vet!";
                    author = @"Milen Marinov";
                    break;
                case 2:
                    comment = @"I'm coming...";
                    author = @"Ivan Petrov";
                    break;
                    
                default:
                    break;
            }
            
            [commentCell setCommentText:_comments[indexPath.row]];
            [commentCell setAuthor:author];
            
            cell = commentCell;
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
            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:_comments[indexPath.row] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17]}];
            CGRect rect = [attributedText boundingRectWithSize:(CGSize){self.view.frame.size.width - (15 * 2), 150} options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
            height = ceilf(rect.size.height) + 55;
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
        if (indexPath.row == kCellIndexStatusSelected)
        {
            _statusIsExpanded = !_statusIsExpanded;
        }
        else
        {
            _status = indexPath.row - 1;
        }
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (IBAction)onCloseButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end
