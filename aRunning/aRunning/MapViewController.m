//
//  MapViewController.m
//  BeatRun
//
//  Created by Shinya Hirai on 3/3/14.
//  Copyright (c) 2014 Shinya Hirai. All rights reserved.
//

#import "MapViewController.h"

@interface MapViewController () {
    // Google Map
    GMSMapView* _gMapView;
    
    // 現在地
    CLLocationManager* _locationManager;
    BOOL _doFollow;
}

@end

@implementation MapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Google Map
    GMSCameraPosition* camera = [GMSCameraPosition cameraWithLatitude:-33.8683
                                                            longitude:151.2086
                                                                 zoom:14];
    _gMapView = [GMSMapView mapWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 319) camera:camera];
    _gMapView.delegate = self;
    _gMapView.myLocationEnabled = YES;
    _gMapView.settings.myLocationButton = YES;
    _gMapView.settings.compassButton = YES;
    [self.view addSubview:_gMapView];
    
    // マーカーの設置
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(10.328531, 123.903545);
    marker.title = @"La guardia";
    marker.snippet = @"Flat Ⅱ";
    marker.map = _gMapView;
    
    // 現在地
    _locationManager = [[CLLocationManager alloc] init];
    
    // 位置情報サービスが利用できるかどうかをチェック
    if ([CLLocationManager locationServicesEnabled]) {
        _locationManager.delegate = self;
        // 測位開始
        [_locationManager startUpdatingLocation];
    } else {
        NSLog(@"Location services not available.");
    }
}

// 位置情報更新時
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    // マップの中心に現在地を表示
    [_gMapView animateToLocation : [newLocation coordinate]];
    
    //緯度・経度を出力
    NSLog(@"didUpdateToLocation latitude=%f, longitude=%f",
            [newLocation coordinate].latitude,
            [newLocation coordinate].longitude);
    
    // 線の描画
    GMSMutablePath* path = [GMSMutablePath path];
    [path addCoordinate:CLLocationCoordinate2DMake(10.328531, 123.903545)];
    [path addCoordinate:CLLocationCoordinate2DMake(10.318531, 123.913545)];
    [path addCoordinate:CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude)];
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.map = _gMapView;
}

// 測位失敗時や、位置情報の利用をユーザーが「不許可」とした場合などに呼ばれる
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"didFailWithError");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tapBtn:(id)sender {
}

@end
