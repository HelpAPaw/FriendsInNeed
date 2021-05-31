//
//  FINSignalDetailsCommentCell.h
//  FriendsInNeed
//
//  Created by Milen on 16/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FINSignalDetailsVC.h"

#define kCommentPhotoHeight 200.0

@interface FINSignalDetailsCommentCell : UITableViewCell <FINSignalDetailsCommentCellProtocol>

@property (nonatomic, weak) id <FINPhotoDelegate> delegate;

- (void)setCommentText:(NSString *)text;
- (void)setAuthor:(NSString *)author;
- (void)setDate:(NSString *)date;
- (void)setImageUrl:(NSURL *)imageUrl;

@end
