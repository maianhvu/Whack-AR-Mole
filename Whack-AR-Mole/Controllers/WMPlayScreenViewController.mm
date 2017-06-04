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
@property (nonatomic, weak) IBOutlet UIImageView *miniImageView;


// Properties
@property (nonatomic, strong) CvVideoCamera *camera;

@end

@implementation WMPlayScreenViewController

//-----------------------------------------------------------------------------
#pragma mark - Initialization
//-----------------------------------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [WMFiducialClassifier sharedClassifier];


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
    drawContours(image,
                 [WMContour extractCvContoursFromContours:squares],
                  -1,
                 Scalar(0, 255, 255),
                 2);

    for (WMContour *square in squares) {
        WMFiducial *fiducial = [[WMFiducial alloc] initWithSquare:square inImage:gray];
        if (square == squares.firstObject) {
            Mat fiducialMat;
            cvtColor(fiducial.rectifiedImage, fiducialMat, CV_GRAY2RGBA);
            UIImage *fiducialImage = [UIImage imageFromCvMat:fiducialMat];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.miniImageView.image = fiducialImage;
            });
        }

        NSUInteger index = [[WMFiducialClassifier sharedClassifier] classifyFiducial:fiducial];
        if (index < 8) {
            NSString *letterString = [@"STANFORD" substringWithRange:NSMakeRange(index, 1)];
            string letter([letterString cStringUsingEncoding:NSUTF8StringEncoding]);
            Mat centroid;
            square.centroid.convertTo(centroid, CV_32S);
            putText(image, letter, cv::Point2i(centroid.at<int>(0, 0),
                                               centroid.at<int>(0, 1)),
                    CV_FONT_HERSHEY_SIMPLEX, 1, Scalar(0, 255, 25));

        }
    }
}

@end
