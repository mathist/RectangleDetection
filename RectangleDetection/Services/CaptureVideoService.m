//
//  CaptureVideoService.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/19/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "CaptureVideoService.h"

@interface VideoService()

-(void)setupService:(AVCaptureDevicePosition)devicePosition;

@end

@interface CaptureVideoService() <AVCaptureVideoDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate>

@property (nonatomic, retain) AVCapturePhotoOutput *capturePhotoOutput;

@end


@implementation CaptureVideoService

-(void)setupService:(AVCaptureDevicePosition)devicePosition
{
    [super setupService:devicePosition];
    
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    [captureOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self addOutput:captureOutput];
    
    [captureOutput setAlwaysDiscardsLateVideoFrames:YES];
    [captureOutput setSampleBufferDelegate:self queue:self.sessionQueue];
    
    
    self.capturePhotoOutput = [[AVCapturePhotoOutput alloc] init];
    
    [self.capturePhotoOutput setHighResolutionCaptureEnabled:YES];
    [self.capturePhotoOutput setLivePhotoCaptureEnabled:NO];
    [self addOutput:self.capturePhotoOutput];
    
    AVCaptureConnection *connection = [self.capturePhotoOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoOrientation orientation = self.captureLayer.connection.videoOrientation;
    if(connection != nil)
        [connection setVideoOrientation:orientation];

}

-(void)takePhoto
{
    NSArray *formats = [self.capturePhotoOutput supportedPhotoPixelFormatTypesForFileType:AVFileTypeTIFF];
    
    if (formats.count > 0)
    {
        AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{(NSString *)kCVPixelBufferPixelFormatTypeKey: formats.firstObject}];
        
        [photoSettings setHighResolutionPhotoEnabled:YES];
        [photoSettings setFlashMode:AVCaptureFlashModeOff];
        [photoSettings setAutoStillImageStabilizationEnabled:NO];
        [photoSettings setHighResolutionPhotoEnabled:YES];
        
        [self.capturePhotoOutput capturePhotoWithSettings:photoSettings delegate:self];
    }
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate methods
-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(captureVideoServiceSampleBuffer:)])
        [self.delegate captureVideoServiceSampleBuffer:sampleBuffer];
}

#pragma mark AVCapturePhotoOutputDelegate methods

-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    if(!error && self.delegate && [self.delegate respondsToSelector:@selector(captureVideoServicePhotoOutput:didFinishProcessingPhoto:)])
        [self.delegate captureVideoServicePhotoOutput:output didFinishProcessingPhoto:photo];
}

@end
