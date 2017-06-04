//
//  WMHOGDescriptor.h
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/4/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef __cplusplus
#import <opencv2/core.hpp>
using namespace cv;
using namespace std;
#endif

@interface WMHOGDescriptor : NSObject

// Designated initializer
- (instancetype)initWithPixelsPerCell:(const cv::Size &)pixelsPerCell
                        cellsPerBlock:(const cv::Size &)cellsPerBlock
                                nBins:(int)nBins;
@property (nonatomic, assign, readonly) cv::Size pixelsPerCell;
@property (nonatomic, assign, readonly) cv::Size cellsPerBlock;
@property (nonatomic, assign, readonly) int nBins;

// Description
- (Mat)computeHOGFeaturesInImage:(const Mat &)image;

@end
