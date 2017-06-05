//
//  WMCalibrator.h
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/4/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMIdentifiedFiducial.h"

@interface WMCalibrator : NSObject

- (instancetype)initWithIdentifiedFiducials:(NSArray<WMIdentifiedFiducial *> *)identifiedFiducials;
@property (nonatomic, strong) NSArray<WMIdentifiedFiducial *> *identifiedFiducials;

@property (nonatomic, assign) Mat cameraMatrix;
- (cv::Point)projectRealWorldPoint:(InputArray)realWorldPoint;

@end
