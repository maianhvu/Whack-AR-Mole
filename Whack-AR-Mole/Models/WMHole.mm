//
//  WMHole.m
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/4/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMHole.h"
#ifdef __cplusplus
#include <iostream>
#include <opencv2/imgproc.hpp>
using namespace std;
#endif

@interface WMHole ()

@property (nonatomic, assign, readonly) Mat worldPoints;

@end

@implementation WMHole

//-----------------------------------------------------------------------------
#pragma mark - Designated initializer
//-----------------------------------------------------------------------------
- (instancetype)initWithIndex:(NSUInteger)index {
    self = [super init];

    if (self) {
        _index = index;
        double points[16] = {
            160, 0,
            320, 160,
            160, 320,
            0, 160,
            160*(1-1/sqrt(2)), 160*(1-1/sqrt(2)),
            160*(1+1/sqrt(2)), 160*(1-1/sqrt(2)),
            160*(1-1/sqrt(2)), 160*(1+1/sqrt(2)),
            160*(1+1/sqrt(2)), 160*(1+1/sqrt(2)),
        };
        double xOffset = 410.0 * ((int) index % 3);
        double yOffset = 360.0 * ((int) index / 3);
        _worldPoints = Mat(8, 2, CV_64F, points);
        _worldPoints.col(0) += xOffset;
        _worldPoints.col(1) += yOffset;
        Mat tail;
        hconcat(Mat::zeros(8, 1, CV_64F), Mat::ones(8, 1, CV_64F), tail);
        hconcat(_worldPoints, tail, _worldPoints);
    }

    return self;
}

- (void)drawInImage:(cv::Mat &)image usingCalibrationMatrix:(const cv::Mat &)calibrationMatrix {
    Mat imagePoints = self.worldPoints * calibrationMatrix.t();
    divide(imagePoints.col(0), imagePoints.col(2), imagePoints.col(0));
    divide(imagePoints.col(1), imagePoints.col(2), imagePoints.col(1));
    Mat intPoints;
    imagePoints.colRange(0, 2).convertTo(intPoints, CV_32S);
    RotatedRect rect = fitEllipse(intPoints);
    ellipse(image, rect, Scalar(0, 0, 0, 255), -1);
}


@end
