//
//  WMFiducial.h
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/3/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMContour.h"
#ifdef __cplusplus
#import <opencv2/core/core.hpp>
using namespace std;
using namespace cv;
#endif

@interface WMFiducial : NSObject

// Designated initializer
- (instancetype)initWithSquare:(WMContour *)square;
@property (nonatomic, strong) WMContour *square;

- (Mat)rectifyFromImage:(Mat &)image;

@end
