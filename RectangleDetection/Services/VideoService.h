//
//  VideoService.h
//  RectangleDetection
//
//  Created by Todd Mathison on 6/12/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ImageCorrection.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoService : NSObject

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureLayer;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;

-(instancetype)initWithDevicePosition:(AVCaptureDevicePosition)devicePosition;
-(instancetype)initWithImageCorrection:(ImageCorrection *)imageCorrection;
-(instancetype)initWithImageCorrection:(ImageCorrection * _Nullable)imageCorrection withDevicePosition:(AVCaptureDevicePosition)devicePosition;

-(void)startCamera;
-(void)stopCamera;
-(void)addOutput:(AVCaptureOutput *)output;

@end

NS_ASSUME_NONNULL_END
