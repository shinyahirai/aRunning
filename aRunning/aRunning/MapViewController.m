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
//    CLLocationManager* _locationManager;
    BOOL _doFollow;
    
    NSMutableArray* _polylineList;  // MapViewに追加しているGMSPolylineオブジェクトを保持
    GMSMutablePath* _targetPath;    // 変更対象のpolylineオブジェクトの座標群を保持
}

@end

// マップで表示する最大のpolyline数
#define MAX_POLYLINE 10
// 1polylineあたりの最大座標軸
#define MAX_COORDINATE_PER_POLYLINE 300

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
    // 初期化
    _doFollow = YES;
    
    // Google Map
    GMSCameraPosition* camera = [GMSCameraPosition cameraWithLatitude:34.75144
                                                            longitude:135.369551
                                                                 zoom:14];
    _gMapView = [GMSMapView mapWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 319) camera:camera];
    _gMapView.delegate = self;
    _gMapView.settings.myLocationButton = YES;
//    _gMapView.trafficEnabled = YES;
    [self.view addSubview:_gMapView];
    
    // 地図の中心位置更新のため、KVOで位置情報更新の監視を行う
    [_gMapView addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew context:NULL];
    
    // マーカーの設置
    GMSMarker *marker = [[GMSMarker alloc] init];
    marker.position = CLLocationCoordinate2DMake(10.328531, 123.903545);
    marker.title = @"La guardia";
    marker.snippet = @"Flat Ⅱ";
    marker.map = _gMapView;
    
//    // 現在地
//    _locationManager = [[CLLocationManager alloc] init];
//    
//    // 位置情報サービスが利用できるかどうかをチェック
//    if ([CLLocationManager locationServicesEnabled]) {
//        _locationManager.delegate = self;
//        // 測位開始
//        [_locationManager startUpdatingLocation];
//    } else {
//        NSLog(@"Location services not available.");
//    }
//    
    // 計測開始をviewDidLoad後に実行
    dispatch_async(dispatch_get_main_queue(), ^{
        _gMapView.myLocationEnabled = YES;
    });
}

#pragma mark - KVO update
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
    
    [self updatePolylines:location]; // 軌跡更新

    if (_doFollow) {
        // 現在地をMapの中心に表示(フォローモード)
        CLLocation* location = [change objectForKey:NSKeyValueChangeNewKey];
        [_gMapView animateToLocation:location.coordinate];
    }
}

#pragma mark - GMSMapViewDelegate
- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
    if (gesture) {
        _doFollow = NO;
    }
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position
{
    // アニメーションでのcameraの位置変更が終わったときに呼ばれるので、ここでmyLocationとマップ中心の座標を比較し、
    // フォローモードにするかどうかを判定する
    if(mapView.myLocation){
        CLLocationDegrees deltaLat = fabs(mapView.myLocation.coordinate.latitude - position.target.latitude);
        CLLocationDegrees deltaLon = fabs(mapView.myLocation.coordinate.longitude - position.target.longitude);
        _doFollow = (deltaLat < 0.000001 && deltaLon < 0.000001);
    }
}

// _targetPathからGMSPolylineオブジェクトを生成する
- (GMSPolyline*)createPolyline:(GMSPath*)path
{
    GMSPolyline* polyline = [GMSPolyline polylineWithPath:path];
    polyline.strokeWidth = 5;
    polyline.strokeColor = [UIColor colorWithRed:0.625 green:0.21875 blue:0.125 alpha:1.0];
    return polyline;
}

// CLLocationを追加して軌跡群を更新する
- (void)updatePolylines:(CLLocation*)location
{
    // 誤差が50mより大きければ軌跡に加えない
    if(location && location.horizontalAccuracy > 50) return;
    
    // 一番後ろのpolylineは再作成するためにMapViewとリストから削除する
    if(_polylineList && _polylineList.count > 0){
        GMSPolyline* lastOne = [_polylineList lastObject];
        lastOne.map = nil; // mapプロパティをnilにすればMapViewから消える
        [_polylineList removeLastObject];
    }
    // 座標をpathに追加して、polylineを作成する
    NSMutableArray* workList = [NSMutableArray array]; // 追加するGMSPolylineを一時的に保持
    [_targetPath addLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    if (_targetPath.count >= MAX_COORDINATE_PER_POLYLINE) {
        // 一つのpolylineに保持可能な座標数に達したので、次のpolylineに切り替える
        [workList addObject:[self createPolyline:_targetPath]]; // pathからpolylineを作成し、一時リストに追加
        _targetPath = [GMSMutablePath path]; // pathを切り替え
        // 直前のPolylineの最後の座標と次の座標をつなぐため、最後の座標をこちらにもセットしておく
        [_targetPath addLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    }
    [workList addObject:[self createPolyline:_targetPath]]; // pathからpolylineを作成し、一時リストに追加
    
    // 新規作成したpolyline群を上限数以内におさめる
    if (workList.count > MAX_POLYLINE) {
        [workList removeObjectsInRange: NSMakeRange(0, workList.count - MAX_POLYLINE)];
    }
    // 新規+既存のpolyline群を上限数以内におさめるために、既存のpolyline群の数を調整する
    if ((_polylineList.count + workList.count) > MAX_POLYLINE) {
        for (int left = _polylineList.count + workList.count - MAX_POLYLINE; left > 0; --left) {
            // 先頭のpolylineをMapViewから切り離し、リストからも削除する
            GMSPolyline* polyline = _polylineList[0];
            polyline.map = nil;
            [_polylineList removeObjectAtIndex:0];
        }
    }
    // 新規polylineをMapViewに追加し、既存リストに加える
    for (GMSPolyline* polyline in workList){
        polyline.map = _gMapView;
    }
    [_polylineList addObjectsFromArray:workList];
}

#pragma mark - Location
//// 位置情報更新時
//- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
//    
//    // マップの中心に現在地を表示
//    [_gMapView animateToLocation : [newLocation coordinate]];
//    
//    //緯度・経度を出力
//    NSLog(@"didUpdateToLocation latitude=%f, longitude=%f",
//            [newLocation coordinate].latitude,
//            [newLocation coordinate].longitude);
//    
//    // 線の描画
//    GMSMutablePath* path = [GMSMutablePath path];
//    [path addCoordinate:CLLocationCoordinate2DMake(10.328531, 123.903545)];
//    [path addCoordinate:CLLocationCoordinate2DMake(10.318531, 123.913545)];
//    [path addCoordinate:CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude)];
//    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
//    polyline.map = _gMapView;
//}

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
