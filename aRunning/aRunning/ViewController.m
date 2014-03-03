//
//  ViewController.m
//  BeatRun
//
//  Created by Shinya Hirai on 2/27/14.
//  Copyright (c) 2014 Shinya Hirai. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    // Music Player
    MPMusicPlayerController* _musicPlayer;
    MPMediaItem* _playingItem;
    NSMutableArray* _itemsArray;
    int _nowInt, _hrmax, _warmUp, _basic, _training;
    
    // スライダー and タイマー
    EFCircularSlider* _circularSlider;
    float _duration;
    NSTimer* _seekSliderTimer;
    CGPoint _tBegan, _tEnded;
    UISwipeGestureRecognizer* _swipe;
    
    AppDelegate* _appDelegate;
    
    // Core Location
    CLLocationManager* _locationManager;
    
    // Core Motion
    CMMotionManager* _motionManager;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:168/255.0f green:213/255.0f blue:165/255.0f alpha:1.0f];

    //ミュージックプレイヤー
    _musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
    _musicPlayer.currentPlaybackRate = 1;
//    _musicPlayer.shuffleMode = MPMusicShuffleModeOff;
    _musicPlayer.repeatMode = MPMusicRepeatModeNone;
    
    // 曲が変わった際の通知を取得
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter
     addObserver:self
     selector:@selector(nowPlayingItemDidChangeNotification:)
     name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
     object:_musicPlayer];
    
//    // 再生状態が変わった際の通知を取得
//    [notificationCenter
//     addObserver:self
//     selector:@selector (playbackStateDidChangeNotification:)
//     name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
//     object:_musicPlayer];
    
    // 曲が変わった際にプレイヤから通知を発行するよう設定
    [_musicPlayer beginGeneratingPlaybackNotifications];
    
    // Circle Sliderの設定
    _circularSlider = [[EFCircularSlider alloc] initWithFrame:CGRectMake(45, 45, 230, 230)];
    _circularSlider.unfilledColor = [UIColor colorWithRed:255/255.0f green:255/255.0f blue:255/255.0f alpha:1.0f];
    _circularSlider.filledColor = [UIColor colorWithRed:23/255.0f green:47/255.0f blue:70/255.0f alpha:1.0f];
    _circularSlider.handleType = EFDoubleCircleWithOpenCenter;
    _circularSlider.handleColor = _circularSlider.filledColor;
    _circularSlider.lineWidth = 4;

    [_gradationView addSubview:_circularSlider];
    
    // タッチアップイベント取得によってタイマーとの共存
    // valueChangedでは両方が交互に反応し合ってしまうため応急処置
    [_circularSlider addTarget:self action:@selector(timeDidChange:) forControlEvents:UIControlEventTouchUpInside];
    
    // 各種初期設定
    _itemsArray = [[NSMutableArray alloc] init];
    _songPlayTimeLabel.text = @"0:00";
    _songTitleLabel.text = @"曲が選択されていません";
    _artistLabel.text = @"";
    _bpmLabel.text = @"";
    _locationManager = [[CLLocationManager alloc] init];
    _motionManager = [[CMMotionManager alloc] init];

    
    [UITabBar appearance].barTintColor = [UIColor colorWithRed:168.0f/255.0f green:213.0f/255.0f blue:165.0f/255.0f alpha:1.0f];
    _appDelegate = [[UIApplication sharedApplication] delegate];
    
    
    // 長押し検知で曲のリスト作成
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
                                                      initWithTarget:self
                                                      action:@selector(handleLongPressGesture:)];
    longPressGesture.minimumPressDuration = 1.0f;
    [self.view addGestureRecognizer:longPressGesture];
    
    // グラデーションビューの設定
    float width = _gradationView.frame.size.width, height = _gradationView.frame.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, width, height, 8, 4 * width, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    size_t numOfComponent = 2;
    CGFloat locations[2] = {0.0, 1.0};
    CGFloat components[8] = {
        168.0f/255.0f, 213.0f/255.0f, 165.0f/255.0f, 0.9f,
        255.0f/255.0f, 255.0f/255.0f, 255.0f/255.0f, 0.9f
    };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, numOfComponent);

    // 制作したグラデーション内容で画像を生成する
    CGContextDrawLinearGradient(bitmapContext, gradient, CGPointMake(0, 0), CGPointMake(0, height), 0);
    CGImageRef imageRef = CGBitmapContextCreateImage(bitmapContext);
    UIImage* image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(bitmapContext);
    CGColorSpaceRelease(colorSpace);
    
    // 生成したグラデーション画像を背景に指定する。
    _gradationView.backgroundColor = [UIColor colorWithPatternImage:image];
    
    // 曲が流れていれば情報取得
    [self getCurrentMusicInfoAndView];
    [self startLocationMonitoring];
    [self coreMotion];

    NSLog(@"nowint = %d",_nowInt);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"_appDelegate = %d",_appDelegate.ageInt);
    // Heart Rate maxを年齢から算出
    _hrmax = 210 - _appDelegate.ageInt / 2;
    NSLog(@"hrmax = %d",_hrmax);
    
    // 運動強度が50 ~ 60%の場合
    _warmUp = _hrmax * 0.55;
    NSLog(@"warmUp = %d",_warmUp);
    // 運動強度が60 ~ 70%の場合
    _basic = _hrmax * 0.65;
    NSLog(@"basic = %d",_basic);
    // 運動強度が70 ~ 80%の場合
    _training = _hrmax * 0.75;
    NSLog(@"training = %d",_training);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)getCurrentMusicInfoAndView {
    //現在再生されている曲の情報を取得
    _playingItem = [_musicPlayer nowPlayingItem];
    
    if (_playingItem) {
        
        //音楽が再生されているか確認するためにTypeを取得
        NSInteger mediaType = [[_playingItem valueForProperty:MPMediaItemPropertyMediaType] integerValue];
        
        if (mediaType == MPMediaTypeMusic) {
            // 各種情報取得
            NSString* songTitleString = [_playingItem valueForProperty:MPMediaItemPropertyTitle];
            NSString* artistString = [_playingItem valueForProperty:MPMediaItemPropertyArtist];
            NSString* bpmString = [[_playingItem valueForProperty:MPMediaItemPropertyBeatsPerMinute] stringValue];
            MPMediaItemArtwork* artwork = [_playingItem valueForProperty:MPMediaItemPropertyArtwork];
            
            // 各種表示設定
            _bpmLabel.text = [NSString stringWithFormat:@"BPM:%@",bpmString];
            _songTitleLabel.text = songTitleString;
            _artistLabel.text = artistString;
            // TODO: プレイリスト TextView
            
            // アートワーク設定
            UIImage* artworkImage = [artwork imageWithSize:CGSizeMake(320, 320)];
            _artworkImage.image = artworkImage;
            
            // ミニアートワークの設定
            UIImage* miniArtworkImage = [artwork imageWithSize:CGSizeMake(200, 200)];
            _miniArtworkImage.image = miniArtworkImage;
            _miniArtworkImage.layer.cornerRadius = 100;
            _miniArtworkImage.clipsToBounds = YES;
            
            // 現在流れている曲の長さを取得
            _duration = [[_playingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] intValue];
            
            // スライダーの設定
            _circularSlider.minimumValue = 0.0f;
            _circularSlider.maximumValue = _duration;
            
            _seekSliderTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0f)
                                                     target:self selector:@selector(updateSeekSliderDisplay:)
                                                   userInfo:nil repeats:YES];
            NSLog(@"曲情報取得");
        } else {
            _songTitleLabel.text = @"曲が選択されていません";
        }
    }
}

#pragma mark - Core Motion
- (void)coreMotion {
    // インスタンスの生成
//    CMMotionManager *manager = [[CMMotionManager alloc] init];
    
    // dispatch
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    // 現在、加速度センサー無しのデバイスは存在しないが念のための確認
    if (_motionManager.accelerometerAvailable) {
        // センサーの更新間隔の指定
        _motionManager.accelerometerUpdateInterval = 1.0;  // 100Hz
        
        // ハンドラを指定
        CMAccelerometerHandler handler = ^(CMAccelerometerData *data, NSError *error) {
            // 非同期処理
            
            dispatch_async(globalQueue, ^{
                // 同期処理
                dispatch_async(mainQueue, ^{
                    double timestamp = data.timestamp;  // 更新時刻
                    double x = data.acceleration.x;
                    double y = data.acceleration.y;
                    double z = data.acceleration.z;
                    
                    NSLog(@"timestamp = %f\nx = %f\ny = %f\nz = %f",timestamp,x,y,z);
                    // x, y, zの値を必要に応じて、ローパス・ハイパスなどのフィルタを適用する
                });
            });
        };
        
        // センサーの利用開始
        [_motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
        
//        // (不必要になったら)センサーの停止
//        if (manager.accelerometerActive) {
//            [manager stopAccelerometerUpdates];
//        }
    }
}

#pragma mark - Core Location
-(void)startLocationMonitoring
{
	if(_locationManager == nil)
	{
		_locationManager = [[CLLocationManager alloc] init];
	}
	_locationManager.delegate = self;
    
	_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	_locationManager.distanceFilter = 5.0f;
    
	[_locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager
   didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	NSLog(@"%@",newLocation.timestamp);
}

#pragma mark - Touch Event
- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        // 長押しが始まったときに反応する
        [self getCollection];
        [self startMusic];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch* touchBegan = [touches anyObject];
    _tBegan = [ touchBegan locationInView: self.view ];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch* touchEnded = [touches anyObject];
    _tEnded = [ touchEnded locationInView: self.view ];
    NSInteger distanceHorizontal = ABS( _tEnded.x - _tBegan.x );
    NSInteger distanceVertical = ABS( _tEnded.y - _tBegan.y );
    
    NSLog(@"%d", distanceHorizontal);
    NSLog(@"%d",  distanceVertical);
    
    if (distanceHorizontal <= 10 && distanceVertical <= 10) {
        MPMusicPlaybackState state = _musicPlayer.playbackState;
        if (state == MPMusicPlaybackStatePaused) {
            [_musicPlayer play];
        } else if (state == MPMusicPlaybackStatePlaying) {
            [_musicPlayer pause];
        }
    } else if ( distanceHorizontal > distanceVertical ) {
        if ( _tEnded.x > _tBegan.x ) {
            if (distanceHorizontal >= 100) {
                // 左スワイプ
                _circularSlider.currentValue = 0.0f;
                if (_musicPlayer.currentPlaybackTime < 3.0f) {
                    [_musicPlayer skipToPreviousItem];
                } else {
                    [_musicPlayer skipToBeginning];
                }
            }
        } else {
            if (distanceHorizontal >= 100) {
                // 右スワイプ
                _circularSlider.currentValue = 0.0f;
                [_musicPlayer skipToNextItem];
            }
        }
    } else {
        if ( _tEnded.y > _tBegan.y ) {
            if (distanceVertical >= 100) {
                // 下スワイプ
                [self getLowCollection];
                [self startMusic];
            }
        } else {
            if (distanceVertical >= 100) {
                // 上スワイプ
                [self getHighCollection];
                [self startMusic];
            }
        }
    }
}

#pragma mark - Notification
- (void)nowPlayingItemDidChangeNotification:(id)notification {
    NSString* notificationName = [notification name];
    if ([notificationName isEqualToString:MPMusicPlayerControllerNowPlayingItemDidChangeNotification]) {
        [self getCurrentMusicInfoAndView];
    }
}

//- (void)playbackStateDidChangeNotification:(NSNotification *)notification
//{
//	MPMusicPlaybackState state = _musicPlayer.playbackState;
//	if (state == MPMusicPlaybackStatePlaying) {
//        // 曲スタート時
//        NSLog(@"スタート");
//	} else {
//        // 曲エンド時
//        NSLog(@"エンド");
//	}
//}

#pragma mark - Slider
-(void)updateSeekSliderDisplay:(NSTimer*)timer {
    // TODO: 曲再生用のスライダーと時間Label
    int current = _musicPlayer.currentPlaybackTime; //int型に変換して計算
    int minute = current / 60; //現在時間÷６０で「分」の部分。
    int sec = current % 60; //現在時間÷６０の剰余算で「秒」の部分。
    _songPlayTimeLabel.text=[NSString stringWithFormat:@"%d:%02d",minute,sec]; //02で二桁で表示

//    int lastMinute = (current - _duration) / 60; //式を逆にしてマイナスを表示
//    int lastSec = abs((current - _duration) % 60);
//    _songLastTimeLabel.text=[NSString stringWithFormat:@"%d:%02d",lastMinute,lastSec];
    
    _circularSlider.currentValue = _musicPlayer.currentPlaybackTime;
}

-(void)timeDidChange:(EFCircularSlider *)slider {
    _musicPlayer.currentPlaybackTime = _circularSlider.currentValue;
}

#pragma mark - BPM
- (void)getCollection {
    if (_nowInt == 0) {
        // 曲検索用のナンバーを作成
        NSNumber* bpmNum = [NSNumber numberWithInt:_basic];
        
        // 現在使用しているBPM値を保存
        _nowInt = _basic;
        
        // 曲を取得する前に初期化
        _itemsArray = [[NSMutableArray alloc] init];
        
        // Collection用の配列を作成
        for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
            if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                [_itemsArray addObject:item];
            }
        }
        
        for (int i = 1; i < 5; i++) {
            bpmNum = [NSNumber numberWithInt:_basic + i];
            for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
                if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                    [_itemsArray addObject:item];
                }
            }
            bpmNum = [NSNumber numberWithInt:_basic - i];
            for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
                if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                    [_itemsArray addObject:item];
                }
            }
        }
    }
}

- (void)getLowCollection {
    
    if (_nowInt == _training) {
        
        // 現在使用しているBPM値を保存
        NSNumber* bpmNum = [NSNumber numberWithInt:_basic];
        
        // 現在使用しているBPM値を保存
        _nowInt = _basic;
        
        // 曲を取得する前に初期化
        _itemsArray = [[NSMutableArray alloc] init];
        
        // Collection用の配列を作成
        for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
            if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                [_itemsArray addObject:item];
            }
        }
        
        for (int i = 1; i < 5; i++) {
            bpmNum = [NSNumber numberWithInt:_basic + i];
            for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
                if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                    [_itemsArray addObject:item];
                }
            }
            bpmNum = [NSNumber numberWithInt:_basic - i];
            for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
                if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                    [_itemsArray addObject:item];
                }
            }
        }
    } else if (_nowInt == _basic) {
        
        // 現在使用しているBPM値を保存
        NSNumber* bpmNum = [NSNumber numberWithInt:_warmUp];
        
        // 現在使用しているBPM値を保存
        _nowInt = _warmUp;
        
        // 曲を取得する前に初期化
        _itemsArray = [[NSMutableArray alloc] init];
        
        // Collection用の配列を作成
        for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
            if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                [_itemsArray addObject:item];
            }
        }
        
        for (int i = 1; i < 5; i++) {
            bpmNum = [NSNumber numberWithInt:_warmUp + i];
            for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
                if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                    [_itemsArray addObject:item];
                }
            }
            bpmNum = [NSNumber numberWithInt:_warmUp - i];
            for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
                if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                    [_itemsArray addObject:item];
                }
            }
        }
    } else if (_nowInt == _warmUp) {
        _itemsArray = [[NSMutableArray alloc] init];
    }
}

- (void)getHighCollection {
    
    if (_nowInt == _warmUp) {
        // 曲検索用のナンバーを作成
        NSNumber* bpmNum = [NSNumber numberWithInt:_basic];
        
        // 現在使用しているBPM値を保存
        _nowInt = _basic;
        
        // 曲を取得する前に初期化
        _itemsArray = [[NSMutableArray alloc] init];
        
        // Collection用の配列を作成
        for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
            if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                [_itemsArray addObject:item];
            }
        }
        
        for (int i = 1; i < 5; i++) {
            bpmNum = [NSNumber numberWithInt:_basic + i];
            for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
                if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                    [_itemsArray addObject:item];
                }
            }
            bpmNum = [NSNumber numberWithInt:_basic - i];
            for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
                if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                    [_itemsArray addObject:item];
                }
            }
        }
    } else if (_nowInt == _basic) {
        // 曲検索用のナンバーを作成
        NSNumber* bpmNum = [NSNumber numberWithInt:_training];
        
        // 現在使用しているBPM値を保存
        _nowInt = _training;
        
        // 曲を取得する前に初期化
        _itemsArray = [[NSMutableArray alloc] init];
        
        // Collection用の配列を作成
        for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
            if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                [_itemsArray addObject:item];
            }
        }
        
        for (int i = 1; i < 15; i++) {
            bpmNum = [NSNumber numberWithInt:_training + i];
            for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
                if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                    [_itemsArray addObject:item];
                }
            }
            bpmNum = [NSNumber numberWithInt:_training - i];
            for (MPMediaItem* item in [[MPMediaQuery songsQuery] items]) {
                if ( [[item valueForProperty:MPMediaItemPropertyBeatsPerMinute] isEqualToNumber: bpmNum]) {
                    [_itemsArray addObject:item];
                }
            }
        }
    } else if (_nowInt == _training) {
        _itemsArray = [[NSMutableArray alloc] init];
    }
}

- (void)startMusic {
//    // デバッグ用
//    for( MPMediaItem* music in _itemsArray) {
//        NSString* songTitle = [music valueForProperty:MPMediaItemPropertyTitle];
//        NSString* songBpm = [[music valueForProperty:MPMediaItemPropertyBeatsPerMinute] stringValue];
//        NSLog(@"%@ %@", songTitle, songBpm);
//    }
    
    // 再生
    if (_itemsArray.count != 0 && _itemsArray) {
        _musicPlayer = [[MPMusicPlayerController alloc] init];
        MPMediaItemCollection* myMediaItemCollection = [[MPMediaItemCollection alloc] initWithItems:_itemsArray];
        [_musicPlayer setQueueWithItemCollection:myMediaItemCollection];
        [_musicPlayer play];
        NSLog(@"_nowInt = %d",_nowInt);
    } else {
        NSLog(@"error");
        NSLog(@"_nowInt e = %d",_nowInt);
    }
}

@end
