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

// Type Definition
class ParallelDifferenceThreshold : public ParallelLoopBody {
public:
    ParallelDifferenceThreshold(Mat &image, Mat &thresh, const Scalar &values, double difference);
    virtual void operator ()(const Range &range) const;
    ParallelDifferenceThreshold &operator=(const ParallelDifferenceThreshold &) {
        return *this;
    };
private:
    Mat &_image;
    Mat &_thresh;
    const Scalar &_values;
    double _differenceSquared;
};
string type2str(int type) {
    string r;

    uchar depth = type & CV_MAT_DEPTH_MASK;
    uchar chans = 1 + (type >> CV_CN_SHIFT);

    switch ( depth ) {
        case CV_8U:  r = "8U"; break;
        case CV_8S:  r = "8S"; break;
        case CV_16U: r = "16U"; break;
        case CV_16S: r = "16S"; break;
        case CV_32S: r = "32S"; break;
        case CV_32F: r = "32F"; break;
        case CV_64F: r = "64F"; break;
        default:     r = "User"; break;
    }
    
    r += "C";
    r += (chans+'0');
    
    return r;
}


@interface WMHandDetector ()

@property (nonatomic, assign) Mat boardCorners;

@end

@implementation WMHandDetector

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
    threshold(roi, thresh, 130.0, 255.0, THRESH_BINARY_INV);
    Mat kernel = getStructuringElement(MORPH_RECT, cv::Size(7, 7));
    Mat opening;
    morphologyEx(thresh, opening, MORPH_OPEN, kernel);

    bitwise_and(image, roi, thresholdImage, opening);
//    Scalar skinValue(15, 94, 169);
//    Mat thresh(roi.rows, roi.cols, CV_8UC1, Scalar(0));
//    ParallelDifferenceThreshold diffThresh(roi, thresh, skinValue, 90);
//    parallel_for_(Range(0, roi.rows * roi.cols), diffThresh);

//    bitwise_and(image, image, image, mask);
}

@end

// ParallelGradientCompute loop body
ParallelDifferenceThreshold::ParallelDifferenceThreshold(Mat &image, Mat &thresh, const Scalar &values, double difference) :
_image(image), _thresh(thresh), _values(values), _differenceSquared(difference * difference) { }

void ParallelDifferenceThreshold::operator()(const cv::Range &range) const {
    for (int r = range.start; r < range.end; ++r) {
        int i = r / _image.cols;
        int j = r % _image.cols;
        Vec3b pixelValues = _image.ptr<Vec3b>(i)[j];
        double diff0 = pixelValues[0] - _values[0];
        double diff1 = pixelValues[1] - _values[1];
        double diff2 = pixelValues[2] - _values[2];
        double differenceSquared = (diff0 * diff0 +
                                    diff1 * diff1 +
                                    diff2 * diff2);
        _thresh.ptr<uchar>(i)[j] = differenceSquared < _differenceSquared ? 255 : 0;
    }
}

