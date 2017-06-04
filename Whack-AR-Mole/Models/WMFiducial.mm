//
//  WMFiducial.m
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/3/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMFiducial.h"
#ifdef __cplusplus
#import <iostream>
#import <opencv2/imgproc/imgproc.hpp>
#endif

@interface WMFiducial ()

@end

@implementation WMFiducial

//-----------------------------------------------------------------------------
#pragma mark - Initialization
//-----------------------------------------------------------------------------
- (instancetype)initWithSquare:(WMContour *)square {
    self = [super init];

    if (self) {
        _square = square;
    }

    return self;
}

- (Mat)rectifyFromImage:(Mat &)image {
    Mat angles(_square.vertexCount, 1, CV_64F);
    for (int vertex = 0; vertex < _square.vertexCount; ++vertex) {
        Mat vector = _square.centroid - _square.approx.row(vertex);
        angles.at<double>(vertex, 0) = atan2(vector.at<double>(0, 1),
                                             vector.at<double>(0, 0));
        
    }
    vector<int> indexes;
    sortIdx(angles, indexes, SORT_EVERY_COLUMN + SORT_ASCENDING);

    Mat sortedVertices(_square.vertexCount, 2, CV_32F);
    for (int index = 0; index < indexes.size(); ++index) {
        _square.approx.row(index).convertTo(sortedVertices.row(indexes[index]), CV_32F);
    }

    cv::Size fiducialSize = cv::Size(64, 64);
    float target[8] = {0, 0,
                       (float) fiducialSize.width - 1, 0,
                       (float) fiducialSize.width - 1, (float) fiducialSize.height - 1,
                       0, (float) fiducialSize.height - 1};
    Mat targetVertices(4, 2, CV_32F, target);
    
    Mat M = getPerspectiveTransform(sortedVertices, targetVertices);
    Mat rectifiedImage;
    warpPerspective(image, rectifiedImage, M, fiducialSize);
    return rectifiedImage;
}

@end
