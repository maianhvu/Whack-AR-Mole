//
//  WMIdentifiedFiducial.m
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/4/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMIdentifiedFiducial.h"
#import "WMFiducial.h"

#ifdef __cplusplus
#include <iostream>
#endif

@implementation WMIdentifiedFiducial

//-----------------------------------------------------------------------------
#pragma mark - Constants
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
#pragma mark - Initialization
//-----------------------------------------------------------------------------
- (instancetype)initWithFiducial:(WMFiducial *)fiducial
                      identifier:(NSUInteger)identifier {

    self = [super init];

    if (self) {
        _fiducial = fiducial;
        _identifier = identifier;
    }

    return self;
}

- (void)generateMatrixP:(OutputArray)outP {
    Mat multipliers = -self.fiducial.uprightVertices.reshape(1, self.fiducial.uprightVertices.rows * 2);
    outP.create(8, 12, CV_64F);

    switch (self.identifier) {
        case 0: {
            double P_S[96] = {
                -210, -80, 170, 1,    0,   0,   0, 0, -210, -80, 170, 1,
                   0,   0,   0, 0, -210, -80, 170, 1, -210, -80, 170, 1,
                 -70, -80, 170, 1,    0,   0,   0, 0,  -70, -80, 170, 1,
                   0,   0,   0, 0,  -70, -80, 170, 1,  -70, -80, 170, 1,
                 -70, -80,  30, 1,    0,   0,   0, 0,  -70, -80,  30, 1,
                   0,   0,   0, 0,  -70, -80,  30, 1,  -70, -80,  30, 1,
                -210, -80,  30, 1,    0,   0,   0, 0, -210, -80,  30, 1,
                   0,   0,   0, 0, -210, -80,  30, 1, -210, -80,  30, 1,
            };

            Mat(8, 12, CV_64F, P_S).copyTo(outP.getMatRef());
        }
            break;
        case 1: {
            double P_T[96] = {
                -210,  30, 0, 1,    0,   0, 0, 0, -210,  30, 0, 1,
                   0,   0, 0, 0, -210,   0, 0, 1, -210,  30, 0, 1,
                 -70,  30, 0, 1,    0,   0, 0, 0,  -70,  30, 0, 1,
                   0,   0, 0, 0,  -70,  30, 0, 1,  -70,  30, 0, 1,
                 -70, 170, 0, 1,    0,   0, 0, 0,  -70, 170, 0, 1,
                   0,   0, 0, 0,  -70, 170, 0, 1,  -70, 170, 0, 1,
                -210, 170, 0, 1,    0,   0, 0, 0, -210, 170, 0, 1,
                   0,   0, 0, 0, -210, 170, 0, 1, -210, 170, 0, 1
            };
            Mat(8, 12, CV_64F, P_T).copyTo(outP.getMatRef());
        }
            break;
        default: break;
    }
    for (int col = 8; col < 12; ++col) {
        multiply(outP.getMatRef().col(col),
                 multipliers,
                 outP.getMatRef().col(col));
    }
}

@end
