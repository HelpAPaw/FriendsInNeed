//
//  SignalDetailsCell.m
//  FriendsInNeed
//
//  Created by Milen on 14/03/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINSignalDetailsCell.h"

@interface FINSignalDetailsCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imgPhotoView;
@property (weak, nonatomic) IBOutlet UILabel *lbPhotoNumber;
@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbAuthor;
@property (weak, nonatomic) IBOutlet UILabel *lbDate;
@property (weak, nonatomic) IBOutlet UIButton *btnCall;

@end

@implementation FINSignalDetailsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}
@synthesize delegate;

- (void)setDelegate:(id <imageTappableDelegate>)aDelegate {
    if (delegate != aDelegate) {
        delegate = aDelegate;
    }
}

- (id)initWithCoder:(NSCoder*)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        //Changes here after init'ing self
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor clearColor];
    _imgPhotoView.layer.cornerRadius = 5.0f;
//    _imgPhotoView.layer.borderWidth = 0.5f;
//    _imgPhotoView.layer.borderColor = [UIColor blackColor].CGColor;
    
    [_imgPhotoView setContentMode:UIViewContentModeScaleAspectFill];
    
    _lbPhotoNumber.layer.cornerRadius = _lbPhotoNumber.frame.size.height / 2;
    _lbPhotoNumber.layer.borderWidth = 0.5f;
    _lbPhotoNumber.layer.borderColor = [UIColor blackColor].CGColor;
    
    _lbTitle.adjustsFontSizeToFitWidth = YES;
    
    if (_phoneNumber)
    {
        _btnCall.hidden = NO;
    }
    else
    {
        _btnCall.hidden = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTitle:(NSString *)title
{
    _lbTitle.text = title;
}

- (void)setAuthor:(NSString *)author
{
    _lbAuthor.text = [NSString stringWithFormat:@"%@", author];
}

- (void)setDate:(NSString *)date
{
    _lbDate.text = [NSString stringWithFormat:@"%@", date];
}

- (void)setPhoto:(UIImage *)photo
{
    _imgPhotoView.image = photo;
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleSingleTap:)];
    _imgPhotoView.userInteractionEnabled = true ;
    [_imgPhotoView addGestureRecognizer:singleFingerTap];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    [delegate imageTapped:_imgPhotoView.image];
}

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    if (phoneNumber && [phoneNumber isKindOfClass:[NSString class]])
    {
        _phoneNumber = phoneNumber;
        _btnCall.hidden = NO;
    }
    else
    {
        _btnCall.hidden = YES;
    }
}

- (IBAction)onCallButton:(id)sender
{
    NSString *phoneNumber = [@"telprompt://" stringByAppendingString:_phoneNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
}

@end
