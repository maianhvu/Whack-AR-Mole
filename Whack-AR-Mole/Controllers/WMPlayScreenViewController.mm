//
//  WMPlayScreenViewController.mm
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 5/7/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMPlayScreenViewController.h"
#ifdef __cplusplus
#import <iostream>
#import "WMFiducialClassifier.h"
#import "WMCalibrator.h"
#import "WMHole.h"
#import "WMHandDetector.h"
#import "UIImage+OpenCV.h"
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/features2d/features2d.hpp>
using namespace cv;
using namespace std;

#endif

@interface WMPlayScreenViewController () <CvVideoCameraDelegate>

// Outlets
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

// Properties
@property (nonatomic, strong) CvVideoCamera *camera;
@property (nonatomic, strong) NSArray<WMHole *> *holes;

@end

@implementation WMPlayScreenViewController

//-----------------------------------------------------------------------------
#pragma mark - Initialization
//-----------------------------------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [WMFiducialClassifier sharedClassifier];

    NSMutableArray<WMHole *> *holes = [NSMutableArray arrayWithCapacity:6];
    for (NSUInteger index = 0; index < 6; ++index) {
        [holes addObject:[[WMHole alloc] initWithIndex:index]];
    }
    self.holes = holes;

    self.camera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
    self.camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.camera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.camera.defaultFPS = 30;
    self.camera.grayscaleMode = NO;
    self.camera.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.camera start];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)processImage:(cv::Mat &)image {
    // Find the contours
    Mat gray;
    cvtColor(image, gray, CV_BGR2GRAY);
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
//        for (WMHole *hole in self.holes) {
//            [hole drawInImage:image usingCalibrationMatrix:calibrator.cameraMatrix];
//        }

        // Detect hands
        Mat thresh;
        [[WMHandDetector defaultDetector] detectHandInImage:image
                                      usingCalibratedMatrix:calibrator.cameraMatrix
                                     toOutputThresholdImage:thresh];
    }
}

@end
