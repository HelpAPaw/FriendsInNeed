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
    NSLog(@"title's class is %@", [title class]);
    if ([title isKindOfClass:[NSString class]])
    {
        self.title = title;
    }
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(geoPoint.latitude.doubleValue, geoPoint.longitude.doubleValue);
    self.coordinate = coordinate;
    
    self.geoPoint = geoPoint;
    
    return self;
}

@end
