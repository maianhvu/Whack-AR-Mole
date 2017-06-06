//
//  WMHandDetector.h
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/5/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef __cplusplus
#import <opencv2/core.hpp>
using namespace cv;
#endif

@interface WMHandDetector : NSObject

// Singleton
+ (instancetype)defaultDetector;

- (void)detectHandInImage:(Mat &)image
    usingCalibratedMatrix:(const Mat &)calibratedMatrix
   toOutputThresholdImage:(OutputArray)thresholdImage;

@end
