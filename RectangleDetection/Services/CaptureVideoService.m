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

@interface CaptureVideoService() <AVCaptureVideoDataOutputSampleBufferDelegate>

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
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate methods
-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(captureVideoServiceSampleBuffer:)])
        [self.delegate captureVideoServiceSampleBuffer:sampleBuffer];
}


@end
