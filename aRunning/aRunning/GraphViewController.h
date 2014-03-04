//
//  GraphViewController.h
//  aRunning
//
//  Created by Shinya Hirai on 3/4/14.
//  Copyright (c) 2014 Shinya Hirai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
@interface GraphViewController : UIViewController <CPTPlotDataSource,CPTPlotDelegate>

@property(nonatomic, strong) CPTXYGraph *barChart;

@end
