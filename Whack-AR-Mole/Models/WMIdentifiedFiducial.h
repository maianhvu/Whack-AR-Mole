//
//  WMIdentifiedFiducial.h
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/4/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WMFiducial.h"

@interface WMIdentifiedFiducial : NSObject

// Designated initializer
- (instancetype)initWithFiducial:(WMFiducial *)fiducial identifier:(NSUInteger)identifier;
@property (nonatomic, strong, readonly) WMFiducial *fiducial;
@property (nonatomic, assign, readonly) NSUInteger identifier;

- (void)generateMatrixP:(OutputArray)outP;

@end
