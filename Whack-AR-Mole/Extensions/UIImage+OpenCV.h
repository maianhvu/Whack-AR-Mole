//
//  UIImage+OpenCV.h
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/3/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef __cplusplus
#import <opencv2/core/core.hpp>
using namespace cv;
#endif

@interface UIImage (OpenCV)

- (Mat)cvMatRepresentation;
+ (UIImage *)imageFromCvMat:(Mat &)matrix;

@end
