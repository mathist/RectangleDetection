//
//  VideoService.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/12/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "VideoService.h"

@interface VideoService()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *captureInput;

@property (nonatomic, weak) ImageCorrection *imageCorrection;

@end

@implementation VideoService

@synthesize captureLayer;


-(instancetype)initWithDevicePosition:(AVCaptureDevicePosition)devicePosition
{
    if (!(self = [super init])) return nil;
    
    [self setupService:devicePosition];
    
    return self;
}


- (instancetype)initWithImageCorrection:(ImageCorrection *)imageCorrection
{
    if (!(self = [super init])) return nil;
    
    self.imageCorrection = imageCorrection;
    [self setupService:AVCaptureDevicePositionBack];
    
    return self;
}

- (instancetype)initWithImageCorrection:(ImageCorrection * _Nullable)imageCorrection withDevicePosition:(AVCaptureDevicePosition)devicePosition
{
    if (!(self = [super init])) return nil;
    
    if(imageCorrection)
        self.imageCorrection = imageCorrection;
    
    [self setupService:devicePosition];
    
    return self;
}

- (instancetype)init
{
    if (!(self = [self initWithImageCorrection:nil withDevicePosition:AVCaptureDevicePositionBack])) return nil;
    
    return self;
}

-(void)setupService:(AVCaptureDevicePosition)devicePosition
{
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    self.captureDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:devicePosition];
    
    NSError *configError;

    if([self.captureDevice lockForConfiguration:&configError])
    {
        if(!configError)
        {
            [self.captureDevice setExposureModeCustomWithDuration:self.captureDevice.activeFormat.maxExposureDuration ISO:AVCaptureISOCurrent completionHandler:nil];
            [self.captureDevice unlockForConfiguration];
        }
    }
    
    if ([self.captureDevice isLowLightBoostSupported])
        [self.captureDevice setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
    
    NSError *error;
    
    self.captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    
    if (error)
    {
        NSLog(@"%@", error.localizedDescription);
        return;
    }
    
    if(self.captureInput && [self.captureSession canAddInput:self.captureInput])
        [self.captureSession addInput:self.captureInput];
    
    self.captureLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    [self.captureLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.sessionQueue = dispatch_queue_create("AVSessionQueue", NULL);
    
    if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] || [self.captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        [self.captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    
    if ([self.captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose] || [self.captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
        [self.captureDevice addObserver:self forKeyPath:@"adjustingExposure" options:NSKeyValueObservingOptionNew context:nil];

    if ([self.captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance] || [self.captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
        [self.captureDevice addObserver:self forKeyPath:@"adjustingWhiteBalance" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)dealloc
{
    NSLog(@"%@", @"VideoService Dealloc");
    
    if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus] || [self.captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
        [self.captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
    
    if ([self.captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose] || [self.captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
        [self.captureDevice removeObserver:self forKeyPath:@"adjustingExposure"];
    
    if ([self.captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance] || [self.captureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
        [self.captureDevice removeObserver:self forKeyPath:@"adjustingWhiteBalance"];

    
    for (AVCaptureInput *ci in self.captureSession.inputs)
        [self.captureSession removeInput:ci];
    
    for (AVCaptureOutput *co in self.captureSession.outputs)
        [self.captureSession removeOutput:co];
    
    self.imageCorrection = nil;
    
    self.captureInput = nil;
    self.captureDevice = nil;
    self.captureSession = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqualToString:@"adjustingFocus"] )
    {
        if(self.imageCorrection && [ [change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ])
            [self.imageCorrection.correctionDictionary setObject:@"Focusing" forKey:kFocusing];
        else
            [self.imageCorrection.correctionDictionary setObject:@"" forKey:kFocusing];
    }
    
//    if( [keyPath isEqualToString:@"adjustingExposure"] )
//    {
//        if(self.imageCorrection && [ [change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ])
//            [self.imageCorrection.correctionDictionary setObject:@"Adjusting Exposure" forKey:kAdjustingExposure];
//        else
//            [self.imageCorrection.correctionDictionary setObject:@"" forKey:kFocusing];
//    }

    if( [keyPath isEqualToString:@"adjustingWhiteBalance"] )
    {
        if(self.imageCorrection && [ [change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ])
            [self.imageCorrection.correctionDictionary setObject:@"Adjusting Color Balance" forKey:kAdjustingColorBalance];
        else
            [self.imageCorrection.correctionDictionary setObject:@"" forKey:kAdjustingColorBalance];
    }

}

-(void)startCamera
{
     [self.captureSession startRunning];
}

-(void)stopCamera
{
     [self.captureSession stopRunning];
}

-(void)addOutput:(AVCaptureOutput *)output
{
    if([self.captureSession canAddOutput:output])
        [self.captureSession addOutput:output];
}


@end
