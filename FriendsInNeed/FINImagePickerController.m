//
//  FINImagePickerController.m
//  Help A Paw
//
//  Created by Milen Marinov on 18.05.21.
//  Copyright © 2021 Milen. All rights reserved.
//

#import "FINImagePickerController.h"

@interface FINImagePickerController() <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, atomic) id <FINImagePickerControllerDelegate> delegate;

@end

@implementation FINImagePickerController

- (instancetype)initWithDelegate:(id <FINImagePickerControllerDelegate>)delegate
{
    self = [super init];
    
    _delegate = delegate;
    
    return self;
}

- (void)showImagePickerFrom:(UIViewController *)presenter withSourceView:(UIView *)sourceView
{
    UIAlertController *photoModeAlert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:NSLocalizedString(@"Take Photo",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self showPhotoPickerFor:UIImagePickerControllerSourceTypeCamera withPresenter:presenter];
    }];
    UIAlertAction *chooseExisting = [UIAlertAction actionWithTitle:NSLocalizedString(@"Choose Existing",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self showPhotoPickerFor:UIImagePickerControllerSourceTypeSavedPhotosAlbum withPresenter:presenter];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleCancel handler:nil];
    
    [photoModeAlert addAction:takePhoto];
    [photoModeAlert addAction:chooseExisting];
    [photoModeAlert addAction:cancel];
    
    UIPopoverPresentationController *popPresenter = [photoModeAlert popoverPresentationController];
    popPresenter.sourceView = sourceView;
    popPresenter.sourceRect = sourceView.bounds;
    
    [presenter presentViewController:photoModeAlert animated:YES completion:^{}];
}

- (void)showPhotoPickerFor:(UIImagePickerControllerSourceType)photoSource withPresenter:(UIViewController *)presenter
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = photoSource;
    if (photoSource == UIImagePickerControllerSourceTypeCamera)
    {
        picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        picker.showsCameraControls = YES;
    }
    [presenter presentViewController:picker animated:YES completion:^ {}];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *pickedPhoto = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        UIImageWriteToSavedPhotosAlbum(pickedPhoto, nil, nil, nil);
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{}];
    [_delegate didPickImage:pickedPhoto];
}

@end
