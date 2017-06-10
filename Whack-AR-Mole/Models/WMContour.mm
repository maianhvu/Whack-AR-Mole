//
//  WMContour.m
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/3/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMContour.h"
#ifdef __cplusplus
#import <opencv2/imgproc/imgproc.hpp>
#endif

@implementation WMContour

//-----------------------------------------------------------------------------
#pragma mark - Initialization
//-----------------------------------------------------------------------------
- (instancetype)initWithCvContour:(vector<cv::Point>)cvContour {
    self = [super init];

    if (self) {
        _cvContour = cvContour;
        _area = contourArea(cvContour);
        double peri = arcLength(cvContour, true);
        vector<cv::Point> approx;
        approxPolyDP(cvContour, approx, 0.02 * peri, true);
        _approx = Mat((int) approx.size(), 2, CV_64F);
        for (int row = 0; row < approx.size(); ++row) {
            _approx.row(row).col(0) = approx[row].x;
            _approx.row(row).col(1) = approx[row].y;
        }
        _centroid = Mat(mean(approx), CV_64F).rowRange(0, 2).t();
        _vertexCount = (int) approx.size();
    }

    return self;
}

+ (NSArray<WMContour *> *)findSquaresInImage:(Mat &)image {
    Mat thresh;
    threshold(image, thresh, 120.0, 255.0, THRESH_BINARY_INV);
    vector<vector<cv::Point>> contours;
    findContours(thresh, contours, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);

    NSMutableArray<WMContour *> *contourArray = [NSMutableArray array];
    for (auto &contour : contours) {
        double area = contourArea(contour);
        if (area < 700 || area > 50000) {
            continue;
        }

        WMContour *c = [[WMContour alloc] initWithCvContour:contour];
        if (c.vertexCount == 4) {
            [contourArray addObject:c];
        }
    }
    return contourArray;
}

+ (vector<vector<cv::Point>>)extractCvContoursFromContours:(NSArray<WMContour *> *)contours {
    vector<vector<cv::Point>> results;
    for (WMContour *contour in contours) {
        results.push_back(contour.cvContour);
    }
    return results;
}

@end
