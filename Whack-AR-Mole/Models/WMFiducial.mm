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
#pragma mark - Constants
//-----------------------------------------------------------------------------
static cv::Size const FIDUCIAL_SIZE = cv::Size(64, 64);

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

- (void)rectify {
    @synchronized (self) {
        if (!_rectifiedImageCalculated) {
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
            
            float target[8] = {0, 0,
                (float) FIDUCIAL_SIZE.width - 1, 0,
                (float) FIDUCIAL_SIZE.width - 1, (float) FIDUCIAL_SIZE.height - 1,
                0, (float) FIDUCIAL_SIZE.height - 1};
            Mat targetVertices(4, 2, CV_32F, target);
            
            Mat M = getPerspectiveTransform(sortedVertices, targetVertices);
            Mat warped;
            warpPerspective(_image, warped, M, FIDUCIAL_SIZE);
            
            int edgeSize = (int) ceil((45.0/140)*FIDUCIAL_SIZE.width);
            Mat leftEdge   = warped.colRange(0, edgeSize);
            Mat rightEdge  = warped.colRange(warped.cols - edgeSize, warped.cols);
            Mat topEdge    = warped.rowRange(0, edgeSize);
            Mat bottomEdge = warped.rowRange(warped.rows - edgeSize, warped.rows);
            double means[4] = {
                mean(leftEdge  )[0],
                mean(rightEdge )[0],
                mean(topEdge   )[0],
                mean(bottomEdge)[0],
            };
            Mat meansMat(1, 4, CV_64F, means);
            int minIdx[2];
            int vertexOffset = 0;
            
            minMaxIdx(meansMat, NULL, NULL, minIdx, NULL);
            switch (minIdx[1]) {
                case 1:
                    flip(warped, _rectifiedImage, -1);
                    vertexOffset = 2;
                    break; 
                case 2:
                    transpose(warped, warped);
                    flip(warped, _rectifiedImage, 0);
                    vertexOffset = 1;
                    break;
                case 3:
                    transpose(warped, warped);
                    flip(warped, _rectifiedImage, 1);
                    vertexOffset = 3;
                    break;
                default:
                    _rectifiedImage = warped;
                    break;
            }
            
            _uprightVertices = Mat(sortedVertices.rows, sortedVertices.cols, CV_64F);
            for (int row = 0; row < _uprightVertices.rows; ++row) {
                sortedVertices.row((row + vertexOffset) % sortedVertices.rows)
                .convertTo(_uprightVertices.row(row), CV_64F);
            }
            
            _rectifiedImageCalculated = YES;
        }
    }
}

- (void)drawVerticesInImage:(Mat &)image {
    if (self.uprightVertices.empty()) {
        return;
    }

    for (int row = 0; row < self.uprightVertices.rows; ++row) {
        double *rowValues = self.uprightVertices.ptr<double>(row);
        cv::Point vertex((int) round(rowValues[0]),
                         (int) round(rowValues[1]));
        circle(image, vertex, 3, Scalar(0, 0, 255), -1);
        string vertexId = std::to_string(row);
        cv::Point org((int) round(rowValues[0]),
                      (int) round(rowValues[1] - 10));
        putText(image, vertexId, org, CV_FONT_HERSHEY_SIMPLEX, 0.75, Scalar(0, 0, 255));
    }
}

@end
