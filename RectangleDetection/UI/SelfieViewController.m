//
//  SelfieViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/24/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "SelfieViewController.h"
#import "ImageCorrection.h"
#import "CaptureVideoService.h"
#import "MotionService.h"
#import "UIImage+Extensions.h"
#import "FaceDetectionService.h"

@interface SelfieViewController () <CaptureVideoServiceDelegate, MotionServiceDelegate, ImageCorrectionDelegate, FaceDetectionServiceDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblStatus;
@property (nonatomic, weak) IBOutlet UIImageView *imgView;

@property (nonatomic, retain) ImageCorrection *imageCorrection;
@property (nonatomic, retain) CaptureVideoService *captureVideoService;
@property (nonatomic, retain) FaceDetectionService *faceDetectionService;

@property (nonatomic, retain) CALayer *overlayLayer;

@end

@implementation SelfieViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageCorrection = [ImageCorrection new];
    [self.imageCorrection setDelegate:self];

    self.captureVideoService = [[CaptureVideoService alloc] initWithImageCorrection:self.imageCorrection withDevicePosition:AVCaptureDevicePositionFront withOptions:kCaptureVideoServiceOptionPhoto | kCaptureVideoServiceOptionOutput];

    [self.captureVideoService setDelegate:self];

    self.faceDetectionService = [FaceDetectionService new];
    [self.faceDetectionService setDelegate:self];


    [self.view.layer addSublayer:self.captureVideoService.captureLayer];

    //    [MotionService.shared setDelegate:self];

    [self.view bringSubviewToFront:self.lblStatus];


    self.overlayLayer = [CALayer new];
    [self.view.layer addSublayer:self.overlayLayer];

}

-(void)dealloc
{
    //    [MotionService.shared stop];
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
    self.overlayLayer.frame = self.view.bounds;
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
}

#pragma mark FaceDetectionServiceDelegate methods
-(void)facesFound:(NSArray<VNFaceObservation *> *)faces
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.overlayLayer.sublayers = nil;
        
        CGSize size = self.view.frame.size;
        
        for(VNFaceObservation *face in faces)
        {
            CGFloat width = size.width * face.boundingBox.size.width;
            CGFloat height = size.height * face.boundingBox.size.height;
            CGFloat y = size.height - (size.height * face.boundingBox.origin.y) - height;
            CGFloat x = size.width - (size.width * face.boundingBox.origin.x) - width;
            
            CGPoint topLeft = CGPointMake(x, y);
            CGPoint topRight = CGPointMake(x + width, y);
            CGPoint bottomLeft = CGPointMake(x, y+height);
            CGPoint bottomRight = CGPointMake(x + width, y+height);
            
            UIBezierPath *path = [[UIBezierPath alloc] init];
            [path moveToPoint:topLeft];
            [path addLineToPoint:topRight];
            [path addLineToPoint:bottomRight];
            [path addLineToPoint:bottomLeft];
            [path addLineToPoint:topLeft];

            CAShapeLayer *layer = [CAShapeLayer layer];
            [layer setPath:path.CGPath];
            [layer setFillRule:kCAFillRuleEvenOdd];
            [layer setFillColor:[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.5].CGColor];

            [self.overlayLayer addSublayer:layer];
        }
    });
    
    
    
}

#pragma mark CaptureVideoServiceDelegate methods

-(void)captureVideoServiceSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self.faceDetectionService request:sampleBuffer];
}

-(void)captureVideoServicePhotoOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo
{
    [self.captureVideoService stopCamera];
    
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:photo.pixelBuffer];
    
//    self.boundingBox = CGRectMake(self.boundingBox.origin.x - .1, self.boundingBox.origin.y - .05, self.boundingBox.size.width + .2, self.boundingBox.size.height + .1);
//
//    CGFloat y = self.boundingBox.origin.x * ciImage.extent.size.height;
//    CGFloat width = self.boundingBox.size.height * ciImage.extent.size.width;
//    CGFloat height = self.boundingBox.size.width * ciImage.extent.size.height;
//    CGFloat x = ciImage.extent.size.width - (self.boundingBox.origin.y * ciImage.extent.size.width) - width;
//
//    ciImage = [ciImage imageByCroppingToRect:CGRectMake(x, y, width, height)];
//
//    NSLog(@"%@", @"hello");

    
    
    
    NSData *jpgData = [[CIContext contextWithOptions:nil] JPEGRepresentationOfImage:ciImage colorSpace:CGColorSpaceCreateDeviceRGB() options:@{(CIImageRepresentationOption)kCGImageDestinationLossyCompressionQuality: [NSNumber numberWithFloat:1.0f]}];
    UIImage *jpgImg = [UIImage imageWithData:jpgData];
    jpgImg = [jpgImg imageRotatedByDegrees:90];
    
    [self.imgView setImage:jpgImg];
    [self.view bringSubviewToFront:self.imgView];
    
    UIImageWriteToSavedPhotosAlbum(jpgImg, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
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
