//
//  WMIdentifiedFiducial.m
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/4/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import "WMIdentifiedFiducial.h"
#import "WMFiducial.h"

@implementation WMIdentifiedFiducial

- (instancetype)initWithFiducial:(WMFiducial *)fiducial
                      identifier:(NSUInteger)identifier {

    self = [super init];

    if (self) {
        _fiducial = fiducial;
        _identifier = identifier;
    }

    return self;
}

- (Mat)P {
    return Mat(); // TODO: Stub
}


@end
