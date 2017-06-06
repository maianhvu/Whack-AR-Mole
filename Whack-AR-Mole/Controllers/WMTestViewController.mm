//
//  WMTestViewController.m
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/4/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMTestViewController.h"
#ifdef __cplusplus
#import <opencv2/core.hpp>
#import <opencv2/imgproc.hpp>
#import "WMFiducialClassifier.h"
#import "WMCalibrator.h"
#import "WMHandDetector.h"
#import "UIImage+OpenCV.h"
#import <iostream>
using namespace std;
using namespace cv;
#endif

@interface WMTestViewController ()

// Outlets
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@end

@implementation WMTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self processTestImage];
}

- (void)processTestImage {
    UIImage *image = [UIImage imageNamed:@"test_image"];
    Mat imageMat = image.cvMatRepresentation;
    Mat gray;
    cvtColor(imageMat, gray, COLOR_RGB2GRAY);
    NSArray<WMContour *> *squares = [WMContour findSquaresInImage:gray];

    NSMutableArray<WMIdentifiedFiducial *> *fiducials = [NSMutableArray array];
    for (WMContour *square in squares) {
        WMFiducial *fiducial = [[WMFiducial alloc] initWithSquare:square inImage:gray];
        [fiducial rectify];
        NSUInteger index = [[WMFiducialClassifier sharedClassifier] classifyFiducial:fiducial];
        WMIdentifiedFiducial *identified = [[WMIdentifiedFiducial alloc] initWithFiducial:fiducial
                                                                               identifier:index];
        [fiducials addObject:identified];
    }

    if (fiducials.count >= 2) {
        WMCalibrator *calibrator = [[WMCalibrator alloc] initWithIdentifiedFiducials:fiducials];

        // Detect hands
        Mat thresh;
        [[WMHandDetector defaultDetector] detectHandInImage:gray
                                      usingCalibratedMatrix:calibrator.cameraMatrix
                                     toOutputThresholdImage:thresh];

        UIImage *threshImage = [UIImage imageFromCvMat:thresh];
        self.imageView.image = threshImage;
    }
}

@end
