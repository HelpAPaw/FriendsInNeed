//
//  FINSignalDetailsCommentCell.h
//  FriendsInNeed
//
//  Created by Milen on 16/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FINSignalDetailsCommentCellProtocol <NSObject>

- (void)setCommentText:(NSString *)text;
- (void)setDate:(NSString *)date;

@end

@interface FINSignalDetailsCommentCell : UITableViewCell <FINSignalDetailsCommentCellProtocol>

- (void)setCommentText:(NSString *)text;
- (void)setAuthor:(NSString *)author;
- (void)setDate:(NSString *)date;

@end
