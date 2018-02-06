//
//  OpenCVClass.h
//  AR-Transit
//
//  Created by Robby on 11/18/17.
//  Copyright © 2017 Robby Kraft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVClass : NSObject

-(UIImage*)resize:(CGSize)size uiImage:(UIImage*) image;
-(CGImageRef)resize:(CGSize)newSize cgImage:(CGImageRef) image;

@end
