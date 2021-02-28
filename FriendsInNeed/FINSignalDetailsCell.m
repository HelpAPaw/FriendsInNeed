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
@property (weak, nonatomic) IBOutlet UILabel *lbType;
@property (weak, nonatomic) IBOutlet UITextView *tvTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbAuthor;
@property (weak, nonatomic) IBOutlet UILabel *lbDate;
@property (weak, nonatomic) IBOutlet UIButton *btnCall;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *btnCallHeightConstraint;
@property (strong, nonatomic) NSDictionary *italicAttributes;

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
        
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:12.0];
        _italicAttributes = @{NSFontAttributeName: font};
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundColor = [UIColor clearColor];
    _imgPhotoView.layer.cornerRadius = 5.0f;
    
    [_imgPhotoView setContentMode:UIViewContentModeScaleAspectFill];
    
    _lbPhotoNumber.layer.cornerRadius = _lbPhotoNumber.frame.size.height / 2;
    _lbPhotoNumber.layer.borderWidth = 0.5f;
    _lbPhotoNumber.layer.borderColor = [UIColor blackColor].CGColor;
    
    if ((_phoneNumber != nil) && (![_phoneNumber isEqualToString:@""]))
    {
        _btnCall.hidden = NO;
        _btnCallHeightConstraint.constant = 44.0;
    }
    else
    {
        _btnCall.hidden = YES;
        _btnCallHeightConstraint.constant = 0.0;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTitle:(NSString *)title
{
    _tvTitle.text = title;
}

- (void)setType:(NSString *)typeString
{    
    _lbType.text = typeString;
}

- (void)setAuthor:(NSString *)author
{
    NSString *authorString = author != nil ? author : @"";
    _lbAuthor.attributedText = [[NSMutableAttributedString alloc] initWithString:authorString attributes:_italicAttributes];
}

- (void)setDate:(NSString *)date
{
    NSString *dateString = date != nil ? date : @"";
    _lbDate.attributedText = [[NSMutableAttributedString alloc] initWithString:dateString attributes:_italicAttributes];
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
        // Put some space between phone number and icon
        [_btnCall setTitle:[NSString stringWithFormat:@" %@", phoneNumber] forState:UIControlStateNormal];
    }
    else
    {
        _btnCall.hidden = YES;
    }
}

- (IBAction)onCallButton:(id)sender
{
    NSString *phoneNumber = [@"tel://" stringByAppendingString:[_phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber] options:@{} completionHandler:nil];
}

@end
