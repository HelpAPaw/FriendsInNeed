//
//  FINSignalDetailsCommentCell.m
//  FriendsInNeed
//
//  Created by Milen on 16/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignalDetailsCommentCell.h"

@interface FINSignalDetailsCommentCell()

@property (weak, nonatomic) IBOutlet UILabel *lbAuthorLabel;
@property (weak, nonatomic) IBOutlet UILabel *lbCommentLabel;
@property (weak, nonatomic) IBOutlet UIView *vCellContainer;

@end

@implementation FINSignalDetailsCommentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.vCellContainer.layer.cornerRadius = 5.0f;
    self.vCellContainer.layer.borderWidth = 1.0f;
    self.vCellContainer.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    self.vCellContainer.layer.shadowOffset = CGSizeMake(0, 0);
//    self.vCellContainer.layer.shadowOpacity = 0.5;
    self.vCellContainer.layer.shadowColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    self.backgroundColor = [UIColor clearColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setCommentText:(NSString *)text
{
    _lbCommentLabel.text = text;
}

- (void)setAuthor:(NSString *)text
{
    _lbAuthorLabel.text = text;
}

@end
