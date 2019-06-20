//
//  IDCardBackViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/13/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "IDCardBackViewController.h"
#import "VideoService.h"
#import "RectangleService.h"
#import "MotionService.h"
#import "ImageCorrection.h"

@interface IDCardBackViewController () <RectangleServiceDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate, MotionServiceDelegate,ImageCorrectionDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblStatus;

@property (nonatomic, retain) ImageCorrection *imageCorrection;
@property (nonatomic, retain) VideoService *videoService;
@property (nonatomic, retain) RectangleService *rectangleService;

@property (nonatomic, assign) CMSampleBufferRef latestBuffer;
@property (nonatomic, retain) CIImage *ciImage;

@end

@implementation IDCardBackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageCorrection = [ImageCorrection new];
    [self.imageCorrection setDelegate:self];
    self.videoService = [[VideoService alloc] initWithImageCorrection:self.imageCorrection];
    self.rectangleService = [RectangleService new];
    
    [self.rectangleService setDelegate:self];
    [self.view.layer addSublayer:self.videoService.captureLayer];
    
    AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    [captureOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.videoService addOutput:captureOutput];
    
    [captureOutput setAlwaysDiscardsLateVideoFrames:YES];
    [captureOutput setSampleBufferDelegate:self queue:self.videoService.sessionQueue];
    
    
    AVCaptureMetadataOutput *metaDataCaptureOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.videoService addOutput:metaDataCaptureOutput];

    [metaDataCaptureOutput setMetadataObjectsDelegate:self queue:self.videoService.sessionQueue];
    [metaDataCaptureOutput setMetadataObjectTypes:@[AVMetadataObjectTypePDF417Code]];

    
    [MotionService.shared setDelegate:self];
    
    [self.view bringSubviewToFront:self.lblStatus];
}

-(void)dealloc
{
    [MotionService.shared stop];
    [self.rectangleService setDelegate:nil];
    self.rectangleService = nil;
    self.videoService = nil;
    self.imageCorrection = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.videoService startCamera];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.videoService stopCamera];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.videoService.captureLayer.frame = self.view.bounds;
}

#pragma mark RectangleServiceDelegate methods

- (void)rectanglesFound:(nonnull NSArray<VNRectangleObservation *> *)rectangles
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CGSize size = self.view.frame.size;
        
        for(VNRectangleObservation *result in rectangles)
        {
            CGPoint topLeft = [self.rectangleService convertToUIView:result.topLeft forSize:size];
            CGPoint topRight = [self.rectangleService convertToUIView:result.topRight forSize:size];
            CGPoint bottomRight = [self.rectangleService convertToUIView:result.bottomRight forSize:size];
            CGPoint bottomLeft = [self.rectangleService convertToUIView:result.bottomLeft forSize:size];
            
            CGFloat rectMidY = (topLeft.y + topRight.y + bottomLeft.y + bottomRight.y) / 4;
            CGFloat viewMidY = size.height/2;
            CGFloat sideBorderMargin =  [self.imageCorrection idSettingForKey:kAlignmentMargin];
            
            if(topLeft.x > sideBorderMargin && bottomLeft.x > sideBorderMargin
               && topRight.x < size.width - sideBorderMargin && bottomRight.x < size.width - sideBorderMargin)
                [self.imageCorrection.correctionDictionary setObject:@"Move Closer To ID" forKey:kDeviceTooFar];
            else
                [self.imageCorrection.correctionDictionary setObject:@"" forKey:kDeviceTooFar];
            
            if (rectMidY < viewMidY-sideBorderMargin || rectMidY > viewMidY+sideBorderMargin
                || topLeft.x > sideBorderMargin || bottomLeft.x > sideBorderMargin
                || topRight.x < size.width - sideBorderMargin || bottomRight.x < size.width - sideBorderMargin
                )
                [self.imageCorrection.correctionDictionary setObject:@"Center ID" forKey:kCentered];
            else
                [self.imageCorrection.correctionDictionary setObject:@"" forKey:kCentered];
            
            if (self.imageCorrection.messages.count == 0)
            {
                [self.videoService stopCamera];
                
                CGFloat y = result.boundingBox.origin.x * self.ciImage.extent.size.height;
                CGFloat width = result.boundingBox.size.height * self.ciImage.extent.size.width;
                CGFloat height = result.boundingBox.size.width * self.ciImage.extent.size.height;
                CGFloat x = self.ciImage.extent.size.width - (result.boundingBox.origin.y * self.ciImage.extent.size.width) - width;
                
                CIContext *context = [CIContext contextWithOptions:nil];
                CGImageRef cgImage = [context createCGImage:self.ciImage fromRect:CGRectMake(x, y, width, height)];
                
                UIImage *img = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
                
                CGImageRelease(cgImage);
                UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            }
        }
    });
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
}


#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate methods
-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    self.ciImage = [CIImage imageWithCVImageBuffer:buffer];
    
    [self.rectangleService request:sampleBuffer];
}


#pragma mark AVCaptureMetadataOutputObjectsDelegate
-(void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
//    if(self.isScanned)
//        return;
//
//    if (metadataObjects.count != 1)
//        return;
//
    AVMetadataObject *metadataObject = metadataObjects.firstObject;

    if (metadataObject.type != AVMetadataObjectTypePDF417Code)
        return;

    for(AVMetadataObject *obj in metadataObjects)
    {
//        if(self.isScanned)
//            return;
//
        if([[self.videoService.captureLayer transformedMetadataObjectForMetadataObject:obj] isKindOfClass:[AVMetadataMachineReadableCodeObject class]])
        {
//            self.isScanned = YES;
//
//            self.scanResults =[(AVMetadataMachineReadableCodeObject *)obj stringValue];
            NSLog(@"%@", [(AVMetadataMachineReadableCodeObject *)obj stringValue]);
//
//            NTKDispatchMainAsync(^{
//                NSDictionary *d = [self parseResults:self.scanResults];
//                if (self.delegate && [self.delegate respondsToSelector:@selector(barCodeControllerDidCompleteWithDictionary:)])
//                    [self.delegate barCodeControllerDidCompleteWithDictionary:d];
//            });
        }
    }
    
}




#pragma mark MotionServiceDelegate methods

-(void)currentPitch:(double)pitch currentRoll:(double)roll currentYaw:(double)yaw
{
    if (pitch > [self.imageCorrection idSettingForKey:kPitchMax])
        [self.imageCorrection.correctionDictionary setObject:@"Tilt Down" forKey:kPitchMax];
    else
        [self.imageCorrection.correctionDictionary setObject:@"" forKey:kPitchMax];
    
    if (pitch < [self.imageCorrection idSettingForKey:kPitchMin])
        [self.imageCorrection.correctionDictionary setObject:@"Tilt Up" forKey:kPitchMin];
    else
        [self.imageCorrection.correctionDictionary setObject:@"" forKey:kPitchMin];
    
    if (roll > [self.imageCorrection idSettingForKey:kRollMax])
        [self.imageCorrection.correctionDictionary setObject:@"Tilt Left" forKey:kRollMax];
    else
        [self.imageCorrection.correctionDictionary setObject:@"" forKey:kRollMax];
    
    if (roll < [self.imageCorrection idSettingForKey:kRollMin])
        [self.imageCorrection.correctionDictionary setObject:@"Tilt Right" forKey:kRollMin];
    else
        [self.imageCorrection.correctionDictionary setObject:@"" forKey:kRollMin];
    
}

#pragma mark ImageCorrectionDelegate methods
-(void)correctionDictionaryChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.lblStatus setText:[self.imageCorrection.messages componentsJoinedByString:@"\n"]];
    });
}

@end
