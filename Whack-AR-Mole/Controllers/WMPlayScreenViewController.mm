//
//  WMPlayScreenViewController.mm
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 5/7/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMPlayScreenViewController.h"
#ifdef __cplusplus
#import "WMContour.h"
#import "WMFiducial.h"
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/features2d/features2d.hpp>
using namespace cv;
using namespace std;
//bool contourComparator(vector<cv::Point> a, vector<cv::Point> b) {
//    return contourArea(a) < contourArea(b);
//};
#endif

@interface WMPlayScreenViewController () <CvVideoCameraDelegate>

// Outlets
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

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
    NSArray<WMContour *> *squares = [WMContour findSquaresInImage:image];
    drawContours(image,
                 [WMContour extractCvContoursFromContours:squares],
                  -1,
                 Scalar(0, 255, 255),
                 2);

    if (squares.count) {
        WMFiducial *firstFiducial = [[WMFiducial alloc] initWithSquare:squares.firstObject];
        Mat rectified = [firstFiducial rectifyFromImage:image];
    }
}

@end
