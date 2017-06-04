//
//  WMHOGDescriptor.m
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/4/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMHOGDescriptor.h"
#ifdef __cplusplus
#include <iostream>
#endif

// Type Definition
class ParallelGradientCompute : public ParallelLoopBody {
public:
    ParallelGradientCompute(Mat &vert, Mat &horz, Mat &angles, Mat &magnitudes);
    virtual void operator ()(const Range &range) const;
    ParallelGradientCompute &operator=(const ParallelGradientCompute &) {
        return *this;
    };
private:
    Mat &_vert;
    Mat &_horz;
    Mat &_angles;
    Mat &_magnitudes;
};

@interface WMHOGDescriptor ()

@property (nonatomic, assign) Mat centerAngles;

@end

@implementation WMHOGDescriptor

//-----------------------------------------------------------------------------
#pragma mark - Initialization
//-----------------------------------------------------------------------------
- (instancetype)initWithPixelsPerCell:(const cv::Size &)pixelsPerCell
                        cellsPerBlock:(const cv::Size &)cellsPerBlock
                                nBins:(int)nBins {
    self = [super init];

    if (self) {
        _pixelsPerCell = pixelsPerCell;
        _cellsPerBlock = cellsPerBlock;
        _nBins = nBins;

        _centerAngles = Mat(1, nBins + 2, CV_32F);
        for (int i = 0; i < nBins + 2; ++i) {
            _centerAngles.at<float>(0, i) = (((float) i) - 0.5) * 180.0 / nBins;
        }
    }

    return self;
}

//-----------------------------------------------------------------------------
#pragma mark - Description
//-----------------------------------------------------------------------------
- (Mat)computeHOGFeaturesInImage:(const Mat &)image {
    Mat angles = Mat(image.rows, image.cols, CV_32F);
    angles = Scalar(NAN);
    Mat magnitudes = Mat(image.rows, image.cols, CV_32F);
    magnitudes = Scalar(NAN);
    [self computeGradientInImage:image
                    outputAngles:angles.rowRange(1, image.rows - 1).colRange(1, image.cols - 1)
                outputMagnitudes:magnitudes.rowRange(1, image.rows - 1).colRange(1, image.cols - 1)];
    int hstride = self.pixelsPerCell.width * self.cellsPerBlock.width / 2;
    int vstride = self.pixelsPerCell.height * self.cellsPerBlock.height / 2;
    int hblocks = image.rows / hstride;
    int vblocks = image.cols / vstride;
    Mat features(1, hblocks * vblocks * self.cellsPerBlock.width * self.cellsPerBlock.height * self.nBins, CV_32F);
    int featuresColPointer = 0;

    for (int blockRow = 0; blockRow < image.rows; blockRow += vstride) {
        for (int blockCol = 0; blockCol < image.cols; blockCol += hstride) {

            vector<float> blockFeatures;
            for (int cellRow = blockRow; cellRow < blockRow + vstride; cellRow += _pixelsPerCell.height) {
                for (int cellCol = blockCol; cellCol < blockCol + hstride; cellCol += _pixelsPerCell.width) {
                    vector<float> hist = [self generateHistogramForAngles:angles.rowRange(cellRow, cellRow + _pixelsPerCell.height).colRange(cellCol, cellCol + _pixelsPerCell.width)
                                                               magnitudes:magnitudes.rowRange(cellRow, cellRow + _pixelsPerCell.height).colRange(cellCol, cellCol + _pixelsPerCell.width)];
                    blockFeatures.insert(blockFeatures.end(), hist.begin(), hist.end());
                }
            }
            Mat blockFeaturesMat = Mat(blockFeatures, CV_32F).t();
            normalize(blockFeaturesMat, features.colRange(featuresColPointer, featuresColPointer + blockFeaturesMat.cols));
            featuresColPointer += blockFeaturesMat.cols;
        }
    }
    
    return features;
}

//-----------------------------------------------------------------------------
#pragma mark - Helper Methods
//-----------------------------------------------------------------------------
- (void)computeGradientInImage:(const Mat &)image
                  outputAngles:(OutputArray)angles
              outputMagnitudes:(OutputArray)magnitudes {
    int height = image.rows;
    int width  = image.cols;
    Mat P2s, P8s, P4s, P6s;
    image.rowRange(0, height - 2).colRange(1, width - 1).convertTo(P2s, CV_32F);
    image.rowRange(2, height)    .colRange(1, width - 1).convertTo(P8s, CV_32F);
    image.rowRange(1, height - 1).colRange(0, width - 2).convertTo(P4s, CV_32F);
    image.rowRange(1, height - 1).colRange(2, width)    .convertTo(P6s, CV_32F);
    Mat vert = P2s - P8s;
    Mat horz = P4s - P6s;
    angles.create(cv::Size(vert.rows, vert.cols), CV_32F);
    magnitudes.create(cv::Size(vert.rows, vert.cols), CV_32F);
    ParallelGradientCompute gradComp(vert, horz, angles.getMatRef(), magnitudes.getMatRef());
    parallel_for_(Range(0, vert.rows * vert.cols), gradComp);
}

- (vector<float>)generateHistogramForAngles:(const Mat &)angles magnitudes:(const Mat &)magnitudes {
    vector<float> histogram(_nBins);

    for (int row = 0; row < angles.rows; ++row) {
        const float *angleRow = angles.ptr<float>(row);
        const float *magRow   = magnitudes.ptr<float>(row);
        for (int col = 0; col < angles.cols; ++col) {
            float angle = angleRow[col];
            float magnitude = magRow[col];

            // Skip NaN values
            if (isnan(angle) || isnan(magnitude)) {
                continue;
            }
            
            Mat absDistMat = abs(angle - _centerAngles);
            const float *absDist = absDistMat.ptr<float>(0);

            int low = 0, high = absDistMat.cols - 1;
            int minIndex, leftIndex, rightIndex;
            while (true) {
                minIndex = (low + high) / 2;
                leftIndex  = (minIndex - 1 + absDistMat.cols) % absDistMat.cols;
                rightIndex = (minIndex + 1) % absDistMat.cols;
                BOOL leftGreater  = absDist[leftIndex] >= absDist[minIndex];
                BOOL rightGreater = absDist[rightIndex] >= absDist[minIndex];
                if (leftGreater && rightGreater) {
                    break;
                } else if (leftGreater) {
                    low = minIndex + 1;
                } else {
                    high = minIndex - 1;
                }
            }

            int minIndex2 = leftIndex;
            if (absDist[rightIndex] < absDist[leftIndex]) {
                minIndex2 = rightIndex;
            }

            histogram[(minIndex - 1 + _nBins) % _nBins]  += magnitude * absDist[minIndex2] * _nBins / 180.0;
            histogram[(minIndex2 - 1 + _nBins) % _nBins] += magnitude * absDist[minIndex]  * _nBins / 180.0;
        }
    }
    return histogram;
}

@end

// ParallelGradientCompute loop body
ParallelGradientCompute::ParallelGradientCompute(Mat &vert, Mat &horz, Mat &angles, Mat &magnitudes):
_vert(vert), _horz(horz), _angles(angles), _magnitudes(magnitudes) { }

void ParallelGradientCompute::operator()(const cv::Range &range) const {
    for (int r = range.start; r < range.end; ++r) {
        int i = r / _vert.cols;
        int j = r % _vert.cols;
        float angle = fmod(fastAtan2(_vert.at<float>(i, j),
                                     _horz.at<float>(i, j)), 180);
        _angles.ptr<float>(i)[j] = angle;
        _magnitudes.ptr<float>(i)[j] = sqrt(pow(_horz.at<float>(i, j), 2) +
                                            pow(_vert.at<float>(i, j), 2));
    }
}


