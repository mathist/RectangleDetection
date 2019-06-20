//
//  IDCardFrontViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/12/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "IDCardFrontViewController.h"
#import "CaptureVideoService.h"
#import "RectangleService.h"
#import "MotionService.h"
#import "ImageCorrection.h"
#import "UIImage+Extensions.h"

@interface IDCardFrontViewController () <RectangleServiceDelegate, CaptureVideoServiceDelegate, MotionServiceDelegate,ImageCorrectionDelegate, AVCapturePhotoCaptureDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblStatus;
@property (nonatomic, weak) IBOutlet UIImageView *imgView;

@property (nonatomic, retain) ImageCorrection *imageCorrection;
@property (nonatomic, retain) CaptureVideoService *captureVideoService;
@property (nonatomic, retain) RectangleService *rectangleService;

@property (nonatomic, retain) AVCapturePhotoOutput *capturePhotoOutput;

@property (nonatomic, assign) BOOL photoCaptured;
@property (nonatomic, assign) CGRect boundingBox;
@end

@implementation IDCardFrontViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageCorrection = [ImageCorrection new];
    [self.imageCorrection setDelegate:self];
    self.captureVideoService = [[CaptureVideoService alloc] initWithImageCorrection:self.imageCorrection];
    [self.captureVideoService setDelegate:self];
    self.rectangleService = [RectangleService new];
    
    [self.rectangleService setDelegate:self];
    [self.view.layer addSublayer:self.captureVideoService.captureLayer];
    


    self.capturePhotoOutput = [[AVCapturePhotoOutput alloc] init];
    
    [self.capturePhotoOutput setHighResolutionCaptureEnabled:YES];
    [self.capturePhotoOutput setLivePhotoCaptureEnabled:NO];
    [self.captureVideoService addOutput:self.capturePhotoOutput];
    
    AVCaptureConnection *connection = [self.capturePhotoOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoOrientation orientation = self.captureVideoService.captureLayer.connection.videoOrientation;
    if(connection != nil)
        [connection setVideoOrientation:orientation];
    
    
    //    [MotionService.shared setDelegate:self];
    
    [self.view bringSubviewToFront:self.lblStatus];
}

-(void)dealloc
{
    [MotionService.shared stop];
    [self.rectangleService setDelegate:nil];
    self.rectangleService = nil;
    self.captureVideoService = nil;
    self.imageCorrection = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.captureVideoService startCamera];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.captureVideoService stopCamera];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.captureVideoService.captureLayer.frame = self.view.bounds;
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
                if (self.photoCaptured)
                {
                    return;
                }
                
                self.photoCaptured = YES;
                
                NSArray *formats = [self.capturePhotoOutput supportedPhotoPixelFormatTypesForFileType:AVFileTypeTIFF];
                
                if (formats.count > 0)
                {
                    AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{(NSString *)kCVPixelBufferPixelFormatTypeKey: formats.firstObject}];
                
                    [photoSettings setHighResolutionPhotoEnabled:YES];
                    [photoSettings setFlashMode:AVCaptureFlashModeOff];
                    [photoSettings setAutoStillImageStabilizationEnabled:NO];
                    [photoSettings setHighResolutionPhotoEnabled:YES];
                    
                    self.boundingBox = result.boundingBox;
                    [self.capturePhotoOutput capturePhotoWithSettings:photoSettings delegate:self];
                }
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

#pragma mark CaptureVideoServiceDelegate methods
-(void)captureVideoServiceSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self.rectangleService request:sampleBuffer];
}

#pragma mark AVCapturePhotoOutputDelegate methods

-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    [self.captureVideoService stopCamera];
    
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:photo.pixelBuffer];

    self.boundingBox = CGRectMake(self.boundingBox.origin.x - .1, self.boundingBox.origin.y - .05, self.boundingBox.size.width + .2, self.boundingBox.size.height + .1);
    
    CGFloat y = self.boundingBox.origin.x * ciImage.extent.size.height;
    CGFloat width = self.boundingBox.size.height * ciImage.extent.size.width;
    CGFloat height = self.boundingBox.size.width * ciImage.extent.size.height;
    CGFloat x = ciImage.extent.size.width - (self.boundingBox.origin.y * ciImage.extent.size.width) - width;
    
    ciImage = [ciImage imageByCroppingToRect:CGRectMake(x, y, width, height)];
    
    NSLog(@"%@", @"hello");
    
    //CIImageRepresentationOption option = kCIImageRepresentationDepthImage
    
    //kCGImageDestinationLossyCompressionQuality
    //kCGImageDestinationImageMaxPixelSize
    
    //  @{(CIImageRepresentationOption)kCGImageDestinationLossyCompressionQuality: 1.0f}
    
    NSData *jpgData = [[CIContext contextWithOptions:nil] JPEGRepresentationOfImage:ciImage colorSpace:CGColorSpaceCreateDeviceRGB() options:@{(CIImageRepresentationOption)kCGImageDestinationLossyCompressionQuality: [NSNumber numberWithFloat:1.0f]}];
    UIImage *jpgImg = [UIImage imageWithData:jpgData];
    jpgImg = [jpgImg imageRotatedByDegrees:90];
    
    
//    NSData *pngData = [[CIContext contextWithOptions:nil] PNGRepresentationOfImage:ciImage format:kCIFormatBGRA8 colorSpace:CGColorSpaceCreateDeviceRGB() options:@{}];
//    UIImage *pngImg = [UIImage imageWithData:pngData scale:1.0];
    
    
    [self.imgView setImage:jpgImg];
    [self.view bringSubviewToFront:self.imgView];
    
    UIImageWriteToSavedPhotosAlbum(jpgImg, nil, nil, nil);
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
