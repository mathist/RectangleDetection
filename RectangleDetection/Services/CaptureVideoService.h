//
//  CaptureVideoService.h
//  RectangleDetection
//
//  Created by Todd Mathison on 6/19/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "VideoService.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, CaptureVideoServiceOption)
{
    kCaptureVideoServiceOptionNone = 0
    , kCaptureVideoServiceOptionOutput = 1
    , kCaptureVideoServiceOptionPhoto = 2
    , kCaptureVideoServiceOptionBarcode = 4
};


@protocol CaptureVideoServiceDelegate;

@interface CaptureVideoService : VideoService

@property(nonatomic, weak) id<CaptureVideoServiceDelegate> delegate;

- (instancetype)initWithOptions:(CaptureVideoServiceOption)options;
- (instancetype)initWithImageCorrection:(ImageCorrection *)imageCorrection withOptions:(CaptureVideoServiceOption)options;
- (instancetype)initWithImageCorrection:(ImageCorrection * _Nullable)imageCorrection withDevicePosition:(AVCaptureDevicePosition)devicePosition withOptions:(CaptureVideoServiceOption)options;

-(void)takePhoto;

@end

@protocol CaptureVideoServiceDelegate <NSObject>

@optional
-(void)captureVideoServiceSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)captureVideoServicePhotoOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo;

@end



NS_ASSUME_NONNULL_END
