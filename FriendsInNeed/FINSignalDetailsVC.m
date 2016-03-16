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


#define kCellIdentifierTitle    @"TitleCell"
#define kCellIdentifierAuthor   @"AuthorCell"
#define kCellIdentifierDate     @"DateCell"

@interface FINSignalDetailsVC () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *detailsView;

@property (strong, nonatomic) GeoPoint *geoPoint;

@property (strong, nonatomic) NSArray *comments;

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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4+3;
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
    
    switch (indexPath.row) {
        case 0:
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
        case 1:
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
        case 2:
        {
            UITableViewCell *statusCell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifierStatus];
            if (!statusCell)
            {
                statusCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifierStatus];
                statusCell.backgroundColor = [UIColor clearColor];
//                statusCell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            [statusCell.imageView setImage:[UIImage imageNamed:@"pin_red"]];
            statusCell.textLabel.text = @"Help needed";
            statusCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell = statusCell;
            break;
        }
        case 3:
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
            
            statusLabelCell.textLabel.text = @"Comments";
            
            cell = statusLabelCell;
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
                case 4:
                    comment = @"Heading there, will let you know when I arrive.";
                    author = @"Milen Marinov";
                    break;
                case 5:
                    comment = @"I'm here. The dog can't move, probably has a broken leg. Need a car to transport him to the vet!";
                    author = @"Milen Marinov";
                    break;
                case 6:
                    comment = @"I'm coming...";
                    author = @"Ivan Petrov";
                    break;
                    
                default:
                    break;
            }
            
            [commentCell setCommentText:_comments[indexPath.row - 4]];
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
    switch (indexPath.row) {
        case 0:
            height = 150.0f;
            break;
        case 2:
            height = 55.0f;
            break;
        case 4:
        case 5:
        case 6:
        {
            NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:_comments[indexPath.row - 4] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17]}];
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
    
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (IBAction)onCloseButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end
