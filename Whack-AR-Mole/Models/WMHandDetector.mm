//
//  WMHandDetector.m
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/5/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMHandDetector.h"
#ifdef __cplusplus
#include <iostream>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui.hpp>
using namespace std;
#endif

@interface WMHandDetector ()

@property (nonatomic, assign) Mat boardCorners;

@end

@implementation WMHandDetector

//-----------------------------------------------------------------------------
#pragma mark - Constants
//-----------------------------------------------------------------------------
static float const HIT_THRESHOLD = 0.75;

//-----------------------------------------------------------------------------
#pragma mark - Singleton
//-----------------------------------------------------------------------------
/* Singleton implementation */
- (instancetype)init {
    NSString *exceptionReason = [NSString stringWithFormat:@"Singleton class %@ must not be instantiated, use singleton getter",
                                 NSStringFromClass([self class])];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:exceptionReason
                                 userInfo:nil];
    return nil;
}

- (instancetype)initForSingleton {
    self = [super init];

    if (self) {
        // Do additional setup over here
        double boardCornerValues[16] = {
            -35, -35, 0, 1,
            1175, -35, 0, 1,
            1175, 725, 0, 1,
            -35, 725, 0, 1
        };
        Mat(4, 4, CV_64F, boardCornerValues).copyTo(_boardCorners);
    }

    return self;
}

+ (instancetype)defaultDetector {
    static WMHandDetector *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WMHandDetector alloc] initForSingleton];
    });
    return instance;
}

//-----------------------------------------------------------------------------
#pragma mark - Detection
//-----------------------------------------------------------------------------
- (void)detectHandInImage:(Mat &)image
    usingCalibratedMatrix:(const Mat &)calibratedMatrix
   toOutputThresholdImage:(OutputArray)thresholdImage {

    Mat boardVertices = self.boardCorners * calibratedMatrix.t();
    divide(boardVertices.col(0), boardVertices.col(2), boardVertices.col(0));
    divide(boardVertices.col(1), boardVertices.col(2), boardVertices.col(1));
    Mat boardRect;
    boardVertices.colRange(0, 2).convertTo(boardRect, CV_32S);
    std::vector<cv::Point> boardRectPoints;
    for (int row = 0; row < boardRect.rows; ++row) {
        int *rowPtr = boardRect.ptr<int>(row);
        boardRectPoints.push_back(cv::Point(rowPtr[0], rowPtr[1]));
    }
    const cv::Point *points[1] = { &boardRectPoints[0] };
    int numPoints = 4;

    Mat mask(image.rows, image.cols, CV_8UC1, Scalar(0));
    fillPoly(mask, points, &numPoints, 1, Scalar(255));

    Mat roi;
    bitwise_and(image, image, roi, mask);
    Mat thresh;
    threshold(roi, thresh, 130.0, 255.0, THRESH_BINARY);
    Mat kernel = getStructuringElement(MORPH_RECT, cv::Size(7, 7));
    Mat opening;
    morphologyEx(thresh, opening, MORPH_OPEN, kernel);

    bitwise_and(image, roi, thresholdImage, opening);
}

- (NSUInteger)detectHitForHoles:(NSArray<WMHole *> *)holes
             withThresholdImage:(const cv::Mat &)thresholdImage
                   cameraMatrix:(const cv::Mat &)cameraMatrix {

    NSArray<WMHole *> *sortedHoles = [holes sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES]]];
    for (WMHole *hole in sortedHoles) {
        Mat full(thresholdImage.rows, thresholdImage.cols, CV_8UC1, Scalar(0));
        [hole drawInImage:full usingCalibrationMatrix:cameraMatrix color:Scalar(255)];
        Mat occluded;
        bitwise_and(full, full, occluded, thresholdImage);
        Scalar fullSum = sum(full);
        Scalar occludedSum = sum(occluded);
        if (((float) occludedSum[0]) / fullSum[0] < (1 - HIT_THRESHOLD)) {
            return hole.index;
        }
    }

    return NSNotFound;
}

@end

