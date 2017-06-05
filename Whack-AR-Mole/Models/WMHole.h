//
//  WMHole.h
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/4/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef __cplusplus
#import <opencv2/core.hpp>
using namespace cv;
#endif

@interface WMHole : NSObject

// Designated initializers
- (instancetype)initWithIndex:(NSUInteger)index;
@property (nonatomic, assign, readonly) NSUInteger index;

- (void)drawInImage:(Mat &)image usingCalibrationMatrix:(const Mat &)calibrationMatrix;

@end
