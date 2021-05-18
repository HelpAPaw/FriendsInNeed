//
//  FINImagePickerController.h
//  FriendsInNeed
//
//  Created by Milen Marinov on 18.05.21.
//  Copyright © 2021 Milen. All rights reserved.
//

#ifndef FINImagePickerController_h
#define FINImagePickerController_h

#import <UIKit/UIKit.h>

@protocol FINImagePickerControllerDelegate <NSObject>

- (void)didPickImage:(UIImage *)image;

@end

@interface FINImagePickerController : NSObject

- (instancetype)initWithDelegate:(id <FINImagePickerControllerDelegate>)delegate;
- (void)showImagePickerFrom:(UIViewController *)presenter withSourceView:(UIView *)sourceView;

@end

#endif /* FINImagePickerController_h */
