//
//  WMFiducialClassifier.m
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/3/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMFiducialClassifier.h"
#ifdef __cplusplus
#import <iostream>
#import <opencv2/imgproc.hpp>
#import <opencv2/objdetect.hpp>
#import <opencv2/highgui.hpp>
#import "UIImage+OpenCV.h"
#endif

@interface WMFiducialClassifier ()

@property (atomic, assign) BOOL finishedPreparing;
@property (nonatomic, assign) HOGDescriptor hogDescriptor;
@property (nonatomic, assign) Mat features;

@end

@implementation WMFiducialClassifier

//-----------------------------------------------------------------------------
#pragma mark - Singleton Initializer
//-----------------------------------------------------------------------------
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
        _finishedPreparing = NO;
    }

    return self;
}

+ (instancetype)sharedClassifier {
    static WMFiducialClassifier *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WMFiducialClassifier alloc] initForSingleton];
        [instance prepareTemplateImages];
    });
    return instance;
}

- (void)prepareTemplateImages {
    self.hogDescriptor = HOGDescriptor(cv::Size(64, 64),
                                       cv::Size(16, 16),
                                       cv::Size(8, 8),
                                       cv::Size(8, 8),
                                       9);
    
    NSString *pathToFiducials = [[NSBundle mainBundle] pathForResource:@"fiducials" ofType:@"bmp"];
    string pathString = [pathToFiducials cStringUsingEncoding:NSMacOSRomanStringEncoding];
    Mat fiducials = imread(pathString, 0);
    Mat thresh;
    threshold(fiducials, thresh, 150, 255, THRESH_BINARY);

    int fiducialSize  = fiducials.size[1];
    int fiducialCount = fiducials.size[0] / fiducialSize;
    for (int index = 0; index < fiducialCount; index++) {
        Mat pixelValues = thresh.rowRange(index * fiducialSize, (index + 1) * fiducialSize);
        vector<float> descriptorValues;
        self.hogDescriptor.compute(pixelValues, descriptorValues);
        Mat features = Mat(descriptorValues, CV_32F).reshape(1, 1);
        
        if (index == 0) {
            self.features = Mat(fiducialCount, features.cols, CV_32F);
        }
        features.copyTo(self.features.row(index));
    }
    self.finishedPreparing = YES;
}

//-----------------------------------------------------------------------------
#pragma mark - Classification
//-----------------------------------------------------------------------------
- (NSUInteger)classifyFiducial:(WMFiducial *)fiducial {
    if (!self.finishedPreparing) {
        return NSNotFound;
    }

    Mat rectified = fiducial.rectifiedImage;
    Mat thresh;
    threshold(rectified, thresh, 100, 255, THRESH_BINARY);
    vector<float> descriptorValues;
    self.hogDescriptor.compute(thresh, descriptorValues);
    Mat features = Mat(descriptorValues, CV_32F).reshape(1, 1);

    NSUInteger minIndex = NSNotFound;
    double minDist = DBL_MAX;
    for (int row = 0; row < self.features.size[0]; ++row) {
        double dist = norm(self.features.row(row), features, NORM_L2);
        if (dist < minDist) {
            minDist = dist;
            minIndex = (NSUInteger) row;
        }
    }
    
    return minIndex;
}

@end
