//
//  WMCalibrator.m
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/4/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMCalibrator.h"
#ifdef __cplusplus
#include <iostream>
#endif

@implementation WMCalibrator

//-----------------------------------------------------------------------------
#pragma mark - Initialization
//-----------------------------------------------------------------------------
- (instancetype)initWithIdentifiedFiducials:(NSArray<WMIdentifiedFiducial *> *)identifiedFiducials {
    self = [super init];

    if (self) {
        _identifiedFiducials = identifiedFiducials;

        if (identifiedFiducials.count) {
            Mat P(8 * ((int) identifiedFiducials.count), 12, CV_64F);
            for (NSUInteger index = 0; index < identifiedFiducials.count; ++index) {
                WMIdentifiedFiducial *fiducial = identifiedFiducials[index];
                [fiducial generateMatrixP:P.rowRange((int) (index * 8),
                                                     (int) ((index + 1) * 8))];
            }
            Mat w, u, vt;
            SVD::compute(P, w, u, vt, SVD::FULL_UV);
            _cameraMatrix = vt.row(vt.rows - 1).reshape(1, 3);
        } else {
            _cameraMatrix = Mat();
        }
    }

    return self;
}

- (cv::Point)projectRealWorldPoint:(InputArray)realWorldPoint {
    if (self.cameraMatrix.empty()) {
        return cv::Point(0, 0);
    }

    Mat worldPoint = realWorldPoint.getMat();
    if (worldPoint.cols != 1) {
        worldPoint = worldPoint.reshape(1, worldPoint.rows * worldPoint.cols);
    }
    if (worldPoint.rows == 3) {
        vconcat(worldPoint, Mat::ones(1, 1, CV_64F), worldPoint);
    }
    Mat projected = self.cameraMatrix * worldPoint;
    projected /= projected.at<double>(2, 0);
    return cv::Point2i((int) round(projected.at<double>(0, 0)),
                       (int) round(projected.at<double>(1, 0)));
}

@end
