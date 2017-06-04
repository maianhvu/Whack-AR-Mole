//
//  WMContour.h
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/3/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#import <opencv2/core/core.hpp>
using namespace std;
using namespace cv;
#endif

@interface WMContour : NSObject

// Designated initializer
- (instancetype)initWithCvContour:(vector<cv::Point>)cvContour;
@property (nonatomic, assign) vector<cv::Point> cvContour;

@property (nonatomic, assign) double area;
@property (nonatomic, assign) Mat approx;
@property (nonatomic, assign) Mat centroid;
@property (nonatomic, assign) int vertexCount;

+ (NSArray<WMContour *> *)findSquaresInImage:(Mat &)image;
+ (vector<vector<cv::Point>>)extractCvContoursFromContours:(NSArray<WMContour *> *)contours;

@end
