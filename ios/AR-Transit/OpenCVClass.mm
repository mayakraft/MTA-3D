//
//  OpenCVClass.m
//  AR-Transit
//
//  Created by Robby on 11/18/17.
//  Copyright © 2017 Robby Kraft. All rights reserved.
//

#import "OpenCVClass.h"
#import <opencv2/opencv.hpp>

using namespace std;
using namespace cv;

@interface OpenCVClass(){
}
@end

@implementation OpenCVClass

-(UIImage*)resize:(CGSize)newSize uiImage:(UIImage*) image{
	cv::Size size(newSize.width, newSize.height);
	Mat dst;
	Mat src = [self cvMatFromUIImage:image];
	cv::resize(src,dst,size);
	return [self uiImageFromCVMat:dst];
}

-(CGImageRef)resize:(CGSize)newSize cgImage:(CGImageRef) image{
	cv::Size size(newSize.width, newSize.height);
	Mat dst;
	Mat src = [self cvMatFromCGImage:image];
	cv::resize(src,dst,size);
	return [self cgImageFromCVMat:dst];
}

////////////////////////////////
//   UIImage and Mat

- (cv::Mat)cvMatFromUIImage:(UIImage *)image{
	return [self cvMatFromCGImage:image.CGImage];
}
-(UIImage *)uiImageFromCVMat:(cv::Mat)mat{
	CGImageRef cgImage = [self cgImageFromCVMat:mat];
	UIImage *finalImage = [UIImage imageWithCGImage:cgImage];
	CGImageRelease(cgImage);
	return finalImage;
}

////////////////////////////////
//   CGImage and Mat

-(cv::Mat)cvMatFromCGImage:(CGImageRef) image{
	int cols = (int)CGImageGetWidth(image);
	int rows = (int)CGImageGetHeight(image);
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
	cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component: (3 color channels + alpha)
	CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, cols, rows,
													8,                          // Bits per component
													cvMat.step[0],              // Bytes per row
													colorSpace,
													kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little);
	CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image);
	CGContextRelease(contextRef);
	return cvMat;
}

-(CGImageRef) cgImageFromCVMat:(cv::Mat)mat{
	NSData *data = [NSData dataWithBytes:mat.data length:mat.elemSize()*mat.total()];
	CGColorSpaceRef colorSpace;
	if (mat.elemSize() == 1) { colorSpace = CGColorSpaceCreateDeviceGray(); }
	else { colorSpace = CGColorSpaceCreateDeviceRGB(); }
	CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
	CGImageRef imageRef = CGImageCreate(mat.cols, mat.rows,
										8,                                          //bits per component
										8 * mat.elemSize(),                         //bits per pixel
										mat.step[0],                                //bytesPerRow
										colorSpace,
										kCGImageAlphaNoneSkipFirst|kCGBitmapByteOrder32Little,
										provider,                                   //CGDataProviderRef
										NULL,                                       //decode
										false,                                      //should interpolate
										kCGRenderingIntentDefault);                 //intent
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorSpace);
	return imageRef;
}

@end
