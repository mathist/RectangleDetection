//
//  CaptureVideoService.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/19/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "CaptureVideoService.h"

@interface VideoService()

@property (nonatomic, strong) AVCaptureSession *captureSession;

-(void)setupService:(AVCaptureDevicePosition)devicePosition;

@end


@interface CaptureVideoService() <AVCaptureVideoDataOutputSampleBufferDelegate,AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, retain) AVCapturePhotoOutput *capturePhotoOutput;
@property (nonatomic, retain) AVCaptureVideoDataOutput *captureVideoOutput;
@property (nonatomic, retain) AVCaptureMetadataOutput *metaDataCaptureOutput;
@property (nonatomic, assign) CaptureVideoServiceOption options;

@end


@implementation CaptureVideoService


- (instancetype)initWithDevicePosition:(AVCaptureDevicePosition)devicePosition withOptions:(CaptureVideoServiceOption)options
{
    self.options = options;
    
    if (!(self = [super initWithDevicePosition:devicePosition])) return nil;
    
    return self;
}


- (instancetype)initWithImageCorrection:(ImageCorrection *)imageCorrection withOptions:(CaptureVideoServiceOption)options
{
    self.options = options;
    
    if (!(self = [super initWithImageCorrection:imageCorrection])) return nil;

    return self;
}

- (instancetype)initWithImageCorrection:(ImageCorrection * _Nullable)imageCorrection withDevicePosition:(AVCaptureDevicePosition)devicePosition withOptions:(CaptureVideoServiceOption)options
{
    self.options = options;
    
    if (!(self = [super initWithImageCorrection:imageCorrection withDevicePosition:devicePosition])) return nil;

    return self;
}

- (instancetype)initWithOptions:(CaptureVideoServiceOption)options
{
    self.options = options;
    
    if (!(self = [super initWithImageCorrection:nil withDevicePosition:AVCaptureDevicePositionBack])) return nil;
    
    return self;
}

-(void)dealloc
{
    NSLog(@"%@", @"CaptureVideoService Dealloc");
    
    [self.captureSession removeOutput:self.capturePhotoOutput];
    self.capturePhotoOutput = nil;
    
    [self.captureSession removeOutput:self.captureVideoOutput];
    self.captureVideoOutput = nil;

    [self.captureSession removeOutput:self.metaDataCaptureOutput];
    self.metaDataCaptureOutput = nil;
}

-(void)setupService:(AVCaptureDevicePosition)devicePosition
{
    [super setupService:devicePosition];
    
    if (self.options | kCaptureVideoServiceOptionOutput)
    {
        self.captureVideoOutput = [[AVCaptureVideoDataOutput alloc] init];

        [self.captureVideoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        [self addOutput:self.captureVideoOutput];

        [self.captureVideoOutput setAlwaysDiscardsLateVideoFrames:YES];
        [self.captureVideoOutput setSampleBufferDelegate:self queue:self.sessionQueue];
    }
    
    if (self.options | kCaptureVideoServiceOptionPhoto)
    {
        self.capturePhotoOutput = [[AVCapturePhotoOutput alloc] init];

        [self.capturePhotoOutput setHighResolutionCaptureEnabled:YES];
        [self.capturePhotoOutput setLivePhotoCaptureEnabled:NO];
        [self addOutput:self.capturePhotoOutput];

        AVCaptureConnection *connection = [self.capturePhotoOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureVideoOrientation orientation = self.captureLayer.connection.videoOrientation;
        if(connection != nil)
            [connection setVideoOrientation:orientation];
    }

    if (self.options | kCaptureVideoServiceOptionBarcode)
    {
        self.metaDataCaptureOutput = [[AVCaptureMetadataOutput alloc] init];
        [self addOutput:self.metaDataCaptureOutput];

        [self.metaDataCaptureOutput setMetadataObjectsDelegate:self queue:self.sessionQueue];
        [self.metaDataCaptureOutput setMetadataObjectTypes:@[AVMetadataObjectTypePDF417Code]];
    }
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
        
        [self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];

        [self.capturePhotoOutput capturePhotoWithSettings:photoSettings delegate:self];
    }
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate methods
-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
//    NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
//    CFRelease(metadataDict);
//    NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
//    float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
//    
//    NSLog(@"%f", brightnessValue);

    if(self.delegate && [self.delegate respondsToSelector:@selector(captureVideoServiceSampleBuffer:)])
        [self.delegate captureVideoServiceSampleBuffer:sampleBuffer];
}

#pragma mark AVCapturePhotoOutputDelegate methods

-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    if(!error && self.delegate && [self.delegate respondsToSelector:@selector(captureVideoServicePhotoOutput:didFinishProcessingPhoto:)])
        [self.delegate captureVideoServicePhotoOutput:output didFinishProcessingPhoto:photo];
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate methods
-(void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(captureVideoServiceMetaDataOutput:)])
        [self.delegate captureVideoServiceMetaDataOutput:metadataObjects];
}

@end
