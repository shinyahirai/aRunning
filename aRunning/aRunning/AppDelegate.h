//
//  AppDelegate.h
//  BeatRun
//
//  Created by Shinya Hirai on 2/27/14.
//  Copyright (c) 2014 Shinya Hirai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GoogleMaps.h>
//#import <CoreLocation/CoreLocation.h>
//#import "MapViewController.h"

//@class MapViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic,assign) int ageInt;

@property (nonatomic,retain) CLLocationManager* locationManager;
@property (nonatomic,retain) CLLocation* location;

//@property (nonatomic,retain) MapViewController* mapViewController;

@end
