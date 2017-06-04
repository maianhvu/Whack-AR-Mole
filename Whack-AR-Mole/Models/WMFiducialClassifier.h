//
//  WMFiducialClassifier.h
//  Whack-AR-Mole
//
//  Created by Mai Anh Vu on 6/3/17.
//  Copyright © 2017 Mai Anh Vu. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef __cplusplus
#import "WMFiducial.h"
#endif

@interface WMFiducialClassifier : NSObject

// Singleton getter
+ (instancetype)sharedClassifier;

- (NSUInteger)classifyFiducial:(WMFiducial *)fiducial;

@end
