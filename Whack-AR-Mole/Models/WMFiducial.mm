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

@property (nonatomic, assign, getter=isRectifiedImageCalculated) BOOL rectifiedImageCalculated;

@end

@implementation WMFiducial

@synthesize rectifiedImage = _rectifiedImage;

//-----------------------------------------------------------------------------
#pragma mark - Initialization
//-----------------------------------------------------------------------------
- (instancetype)initWithSquare:(WMContour *)square inImage:(Mat &)image {
    self = [super init];

    if (self) {
        _square = square;
        _image  = image;
        _rectifiedImageCalculated = NO;
    }

    return self;
}

- (Mat)rectifiedImage {
    if (!_rectifiedImageCalculated) {
        @synchronized (self) {
            _rectifiedImageCalculated = YES;
            Mat angles(_square.vertexCount, 1, CV_64F);
            for (int vertex = 0; vertex < _square.vertexCount; ++vertex) {
                Mat vector = _square.centroid - _square.approx.row(vertex);
                angles.at<double>(vertex, 0) = atan2(vector.at<double>(0, 1),
                                                     vector.at<double>(0, 0));
                
            }
            Mat indexes;
            sortIdx(angles, indexes, SORT_EVERY_COLUMN + SORT_ASCENDING);
            
            Mat sortedVertices(_square.vertexCount, 2, CV_32F);
            for (int index = 0; index < indexes.size[0]; ++index) {
                _square.approx.row(index).convertTo(sortedVertices.row(indexes.at<int>(index)), CV_32F);
            }
            
            cv::Size fiducialSize = cv::Size(32, 32);
            float target[8] = {0, 0,
                (float) fiducialSize.width - 1, 0,
                (float) fiducialSize.width - 1, (float) fiducialSize.height - 1,
                0, (float) fiducialSize.height - 1};
            Mat targetVertices(4, 2, CV_32F, target);

            Mat M = getPerspectiveTransform(sortedVertices, targetVertices);
            Mat warped;
            warpPerspective(_image, warped, M, fiducialSize);
            flip(warped, _rectifiedImage, -1);
        }
    }
    return _rectifiedImage;
}

@end
