//
//  MapViewController.h
//  BeatRun
//
//  Created by Shinya Hirai on 3/3/14.
//  Copyright (c) 2014 Shinya Hirai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>
@interface MapViewController : UIViewController <CLLocationManagerDelegate,GMSMapViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *mapBackgroundView;
- (IBAction)tapBtn:(id)sender;
@end
