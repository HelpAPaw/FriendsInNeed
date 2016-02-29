//
//  FINAnnotation.m
//  FriendsInNeed
//
//  Created by Milen on 22/02/16.
//  Copyright © 2016 г. Milen. All rights reserved.
//

#import "FINAnnotation.h"
#import "FINDataManager.h"

@implementation FINAnnotation

- (FINAnnotation *)initWithGeoPoint:(GeoPoint *)geoPoint
{
    NSString *title = [geoPoint.metadata objectForKey:kSignalTitleKey];
    if ([title isKindOfClass:[NSString class]])
    {
        self.title = title;
    }
    
//    BackendlessUser *author = [geoPoint.metadata objectForKey:kSignalAuthorKey];
//    if ([author isKindOfClass:[BackendlessUser class]])
//    {
//        self.subtitle = [NSString stringWithFormat:@"Submitted by %@", author.name];
//    }
//    
//    NSString *dateSubmittedString = [geoPoint.metadata objectForKey:kSignalDateSubmittedKey];
//    if ([dateSubmittedString isKindOfClass:[NSString class]])
//    {
//        FINDataManager *dataManager = [FINDataManager sharedManager];
//        NSDate *submitDate = [dataManager.signalDateFormatter dateFromString:dateSubmittedString];
//        if (submitDate)
//        {
//            NSTimeInterval timeInterval = [submitDate timeIntervalSinceNow];
//            NSString *passedTime;
//            
//            if (timeInterval < 60)
//            {
//                passedTime = @"seconds";
//            }
//            else if (timeInterval < 2 * 60)
//            {
//                passedTime = @"a minute";
//            }
//            else if (timeInterval < 60 * 60)
//            {
//                passedTime = [NSString stringWithFormat:@"%d minutes", (int)(fabs(timeInterval) / 60)];
//            }
//            else
//            {
//                passedTime = [NSString stringWithFormat:@"%d hours", (int)(fabs(timeInterval) / 60 * 60)];
//            }
//            
//            self.subtitle = [NSString stringWithFormat:@"%@; %@ ago", self.subtitle, passedTime];
//        }
//    }
    
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(geoPoint.latitude.doubleValue, geoPoint.longitude.doubleValue);
    self.coordinate = coordinate;
    
    self.geoPoint = geoPoint;
    
    return self;
}

- (void)updateAnnotationSubtitle
{
    BackendlessUser *author = [_geoPoint.metadata objectForKey:kSignalAuthorKey];
    if ([author isKindOfClass:[BackendlessUser class]])
    {
        self.subtitle = [NSString stringWithFormat:@"Submitted by %@", author.name];
    }
    
    NSString *dateSubmittedString = [_geoPoint.metadata objectForKey:kSignalDateSubmittedKey];
    if ([dateSubmittedString isKindOfClass:[NSString class]])
    {
        FINDataManager *dataManager = [FINDataManager sharedManager];
        NSDate *submitDate = [dataManager.signalDateFormatter dateFromString:dateSubmittedString];
        if (submitDate)
        {
            NSTimeInterval timeInterval = fabs([submitDate timeIntervalSinceNow]);
            NSString *passedTime;
            
            if (timeInterval < 60)
            {
                passedTime = @"seconds";
            }
            else if (timeInterval < 2 * 60)
            {
                passedTime = @"a minute";
            }
            else if (timeInterval < 60 * 60)
            {
                passedTime = [NSString stringWithFormat:@"%d minutes", (int)(timeInterval / 60)];
            }
            else
            {
                passedTime = [NSString stringWithFormat:@"%d hours", (int)(timeInterval / 60 * 60)];
            }
            
            self.subtitle = [NSString stringWithFormat:@"%@; %@ ago", self.subtitle, passedTime];
        }
    }
}

@end
