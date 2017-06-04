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
#import "WMHOGDescriptor.h"
#import <opencv2/imgproc/imgproc.hpp>
#import "UIImage+OpenCV.h"
#endif

@interface WMFiducialClassifier ()

@property (atomic, assign) BOOL finishedPreparing;
@property (nonatomic, strong) WMHOGDescriptor *hogDescriptor;
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
    self.hogDescriptor = [[WMHOGDescriptor alloc] initWithPixelsPerCell:cv::Size(8, 8)
                                                          cellsPerBlock:cv::Size(2, 2)
                                                                  nBins:9];
    UIImage *fiducialsImage = [UIImage imageNamed:@"fiducials"];
    Mat fiducials;
    cvtColor(fiducialsImage.cvMatRepresentation, fiducials, CV_RGBA2GRAY);

    int fiducialSize  = fiducials.size[1];
    int fiducialCount = fiducials.size[0] / fiducialSize;
    for (int index = 0; index < fiducialCount; index++) {
        Mat fiducial = fiducials.rowRange(index * fiducialSize, (index + 1) * fiducialSize);
        Mat features = [self.hogDescriptor computeHOGFeaturesInImage:fiducial];

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
    Mat features = [self.hogDescriptor computeHOGFeaturesInImage:rectified];

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
