//
//  IDCardFrontViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/12/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "IDCardFrontViewController3.h"
#import "VideoService.h"
#import "RectangleService.h"
#import "MotionService.h"
#import "ImageCorrection.h"
#import "UIImage+Extensions.h"

#import <Photos/Photos.h>
#import <Photos/PHAsset.h>
#import <Photos/PHAssetCreationRequest.h>
#import <Photos/PHAssetResource.h>



@interface IDCardFrontViewController3 () <RectangleServiceDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, MotionServiceDelegate,ImageCorrectionDelegate, AVCapturePhotoCaptureDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblStatus;
@property (nonatomic, weak) IBOutlet UIImageView *imgView;

@property (nonatomic, retain) ImageCorrection *imageCorrection;
@property (nonatomic, retain) VideoService *videoService;
@property (nonatomic, retain) RectangleService *rectangleService;

@property (nonatomic, retain) AVCapturePhotoOutput *capturePhotoOutput;

//@property (nonatomic, assign) CMSampleBufferRef latestBuffer;
//@property (nonatomic, retain) CIImage *ciImage;


@property (nonatomic, assign) BOOL photoCaptured;
@property (nonatomic, assign) CGRect boundingBox;


//@property (nonatomic, retain) NSURL *rawURL;
//@property (nonatomic, retain) NSData *compressedData;


@end

@implementation IDCardFrontViewController3

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
    
    
    self.capturePhotoOutput = [[AVCapturePhotoOutput alloc] init];
    
    [self.capturePhotoOutput setHighResolutionCaptureEnabled:YES];
    [self.capturePhotoOutput setLivePhotoCaptureEnabled:NO];
    [self.videoService addOutput:self.capturePhotoOutput];

    AVCaptureConnection *connection = [self.capturePhotoOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoOrientation orientation = self.videoService.captureLayer.connection.videoOrientation;
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
                if (self.photoCaptured)
                {
                    return;
                }
                
                self.photoCaptured = YES;
                
                
                NSArray *fileTypes = [self.capturePhotoOutput availablePhotoFileTypes];
                NSArray *rawFileTypes = [self.capturePhotoOutput availableRawPhotoFileTypes];
                NSArray *codecTypes = [self.capturePhotoOutput availablePhotoCodecTypes];
//                NSArray *pixelTypes = [self.capturePhotoOutput availablePhotoPixelFormatTypes]
                
                NSArray *formats = [self.capturePhotoOutput supportedPhotoPixelFormatTypesForFileType:AVFileTypeTIFF];
                

                AVCapturePhotoSettings *photoSettings;
                
//                NSArray *rawTypes = [self.capturePhotoOutput availableRawPhotoFileTypes];
//                if (rawTypes.count > 0)
//                {
////                    photoSettings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:(OSType)(((NSNumber *)self.capturePhotoOutput.availableRawPhotoPixelFormatTypes[0]).unsignedLongValue) processedFormat:@{AVVideoCodecKey: AVVideoCodecTypeHEVC}];
//
//
//                    photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{}];
//                }
                
                if (formats.count > 0)
                {
                    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
                    
                    photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{key: formats.firstObject}];
                }
                
                [photoSettings setHighResolutionPhotoEnabled:YES];
                [photoSettings setFlashMode:AVCaptureFlashModeOff];
                [photoSettings setAutoStillImageStabilizationEnabled:NO];
                [photoSettings setHighResolutionPhotoEnabled:YES];
                
                self.boundingBox = result.boundingBox;
                [self.capturePhotoOutput capturePhotoWithSettings:photoSettings delegate:self];
                
                
//                [self.videoService stopCamera];
//
//                CGFloat y = result.boundingBox.origin.x * self.ciImage.extent.size.height;
//                CGFloat width = result.boundingBox.size.height * self.ciImage.extent.size.width;
//                CGFloat height = result.boundingBox.size.width * self.ciImage.extent.size.height;
//                CGFloat x = self.ciImage.extent.size.width - (result.boundingBox.origin.y * self.ciImage.extent.size.width) - width;
//
//                CIContext *context = [CIContext contextWithOptions:nil];
//                CGImageRef cgImage = [context createCGImage:self.ciImage fromRect:CGRectMake(x, y, width, height)];
//
//                UIImage *img = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
//
//                CGImageRelease(cgImage);
//                UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
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
//    self.ciImage = [CIImage imageWithCVImageBuffer:buffer];

    [self.rectangleService request:sampleBuffer];
}

#pragma mark AVCapturePhotoOutputDelegate methods



-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error
{
//    [PHPhotoLibrary.sharedPhotoLibrary performChanges:^
//    {
//        PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
//
//        [request addResourceWithType:PHAssetResourceTypePhoto data:self.compressedData options:nil];
//
//        PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
//        [options setShouldMoveFile:YES];
//
//        [request addResourceWithType:PHAssetResourceTypeAlternatePhoto fileURL:self.rawURL options:options];
//
//    } completionHandler:^(BOOL success, NSError *error)
//    {
//        if (error != nil)
//        {
//            NSLog(@"%@", error.localizedDescription);
//        }
//
//        NSLog(@"%@", @"DONE");
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.navigationController popToRootViewControllerAnimated:YES];
//        });
//
//    }];
}



-(void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error
{
    [self.videoService stopCamera];
    
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:photo.pixelBuffer];
    
    CGFloat y = self.boundingBox.origin.x * ciImage.extent.size.height;
    CGFloat width = self.boundingBox.size.height * ciImage.extent.size.width;
    CGFloat height = self.boundingBox.size.width * ciImage.extent.size.height;
    CGFloat x = ciImage.extent.size.width - (self.boundingBox.origin.y * ciImage.extent.size.width) - width;

    ciImage = [ciImage imageByCroppingToRect:CGRectMake(x, y, width, height)];
    
    NSLog(@"%@", @"hello");
    
    NSData *pngData = [[CIContext contextWithOptions:nil] PNGRepresentationOfImage:ciImage format:kCIFormatBGRA8 colorSpace:CGColorSpaceCreateDeviceRGB() options:@{}];
    
    UIImage *pngImg = [UIImage imageWithData:pngData scale:1.0];

    [self.imgView setImage:pngImg];
    [self.view bringSubviewToFront:self.imgView];
    
    UIImageWriteToSavedPhotosAlbum(pngImg, nil, nil, nil);

    
//    if (error != nil)
//    {
//        NSLog(@"%@", error.localizedDescription);
//    }
//
//    if([photo isRawPhoto])
//    {
//        NSURL *tempURL = NSFileManager.defaultManager.temporaryDirectory;
//        NSString *unique = NSProcessInfo.processInfo.globallyUniqueString;
//        tempURL = [tempURL URLByAppendingPathComponent:unique];
//        tempURL = [tempURL URLByAppendingPathExtension:@"dng"];
//
//        self.rawURL = tempURL;
//        [photo.fileDataRepresentation writeToURL:tempURL atomically:YES];
//    }
//    else
//    {
//        self.compressedData = photo.fileDataRepresentation;
//    }
    

    
//    NSData *data = photo.fileDataRepresentation;
//    UIImage *img = [UIImage imageWithData:data scale:1.0];
//
////    NSData *jpegData = UIImageJPEGRepresentation(img, 1.0);
////    UIImage *jpgImg = [UIImage imageWithData:jpegData scale:1.0];
//
//    NSData *png = UIImagePNGRepresentation(img);
//    UIImage *pngImg = [UIImage imageWithData:png scale:1.0];
//
////    CGFloat y = self.boundingBox.origin.x * pngImg.size.height;
////    CGFloat width = self.boundingBox.size.height * pngImg.size.width;
////    CGFloat height = self.boundingBox.size.width * pngImg.size.height;
////    CGFloat x = pngImg.size.width - (self.boundingBox.origin.y * pngImg.size.width) - width;
//
////    UIImage *cropped = [self croppIngimageByImageName:pngImg toRect:CGRectMake(x,y,width,height)];
//
////    CIImage *ciImage = [pngImg CIImage];
////
////    CIContext *context = [CIContext contextWithOptions:nil];
////    CGImageRef cgImage = [context createCGImage:[pngImg CIImage] fromRect:CGRectMake(x, y, width, height)];
////
////    UIImage *newImage = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
////
////    CGImageRelease(cgImage);
//
//
//    [self.imgView setImage:pngImg];
//    [self.view bringSubviewToFront:self.imgView];
//
//    UIImageWriteToSavedPhotosAlbum(pngImg, nil, nil, nil);
    
    
//    CIImage *ciImage = [CIImage imageWithCVImageBuffer:photo.pixelBuffer];
//
//    CIContext *context = [CIContext contextWithOptions:nil];
//    CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
//
//    UIImage *img = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];
//
//    CGImageRelease(cgImage);
//
//    [self.imgView setImage:img];
//    [self.view bringSubviewToFront:self.imgView];
//
//    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
    
//    [photo CGImageRepresentation];
    
    
//    UIImage *img = [UIImage imageWithCGImage:[photo CGImageRepresentation]];

//    NSData *data = [photo fileDataRepresentation];
//
//    UIImage *img = [UIImage imageWithData:data scale:1.0];
//    CGSize oldSize = img.size;
    
//    [self.imgView setImage:img];
//    [self.view bringSubviewToFront:self.imgView];


//    img = [img imageRotatedByDegrees:90];
//    img = [img imageByScalingToSize:CGSizeMake(oldSize.width, oldSize.height)];
//
//    NSLog(@"Size: %@", NSStringFromCGSize(img.size));
//
//    VNDetectRectanglesRequest *request = [[VNDetectRectanglesRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error)
//      {
//          if (error)
//          {
//              NSLog(@"%@", error.localizedDescription);
//              return;
//          }
//
//          VNRectangleObservation *result = request.results.firstObject;
//
//          if (result != nil)
//          {
//              NSLog(@"Rectangle: %@", NSStringFromCGRect(result.boundingBox));
//
//              CGFloat x = result.boundingBox.origin.x * img.size.width - (img.size.width * .05);
//              CGFloat y = result.boundingBox.origin.y * img.size.height - (img.size.height * .05);
//              CGFloat width = result.boundingBox.size.width * img.size.width + (img.size.width * .1);
//              CGFloat height = result.boundingBox.size.height * img.size.height + (img.size.height * .1);
//
//              UIImage *cropped = [self croppIngimageByImageName:img toRect:CGRectMake(x,y,width,height)];
//
//              [self.imgView setImage:cropped];
//              [self.view bringSubviewToFront:self.imgView];
//
//              UIImageWriteToSavedPhotosAlbum(cropped, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//
//          }
//
//      }];
//
//    request.maximumObservations = 1;
//
//    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:photo.pixelBuffer options:@{};]
//
////    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithData:data options:@{}];
//
//    NSError *err;
//    [handler performRequests:@[request] error:&err];
//
//    if (err)
//    {
//        NSLog(@"%@", err.localizedDescription);
//    }
    
}

- (UIImage *)croppIngimageByImageName:(UIImage *)imageToCrop toRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], rect);

//    UIImage *cropped = [UIImage imageWithCGImage:imageRef];

    UIImage *cropped = [UIImage imageWithCGImage:imageRef scale:imageToCrop.scale orientation:UIImageOrientationRight];

    CGImageRelease(imageRef);

    return cropped;
}

//-(UIImage *)crop:(UIImage *)image toRect:(CGRect)rect
//{
//    rect.origin.x*=image.scale;
//    rect.origin.y*=image.scale;
//    rect.size.width*=image.scale;
//    rect.size.height*=image.scale;
//
//    CGImageRef newCGImage = CGImageCreateWithImageInRect([image CGImage], rect);
//
//    return [UIImage imageWithCGImage:newCGImage scale:image.scale orientation:image.imageOrientation];
//}

//func crop( rect: CGRect) -> UIImage?
//{
//    var rect = rect
//    rect.origin.x*=self.scale
//    rect.origin.y*=self.scale
//    rect.size.width*=self.scale
//    rect.size.height*=self.scale
//
//    if rect.origin.x + rect.size.width > self.size.width
//        || rect.origin.y + rect.size.height > self.size.height
//    {
//        return nil
//    }
//
//    var image: UIImage?
//
//    if let cg = self.cgImage
//        , let imageRef = cg.cropping(to: rect)
//    {
//        image = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
//    }
//
//    return image
//}

//- (UIImage *)croppIngimageByImageName:(UIImage *)imageToCrop toRect:(CGRect)cropZone
//{
//CGImageRef image = [imageToCrop CGImage];
//
//size_t cWidth = cropZone.size.width;
//size_t cHeight = cropZone.size.height;
//size_t bitsPerComponent = CGImageGetBitsPerComponent(image);
//size_t bytesPerRow = CGImageGetBytesPerRow(image) / CGImageGetWidth(image) * cWidth;
//
////Now we build a Context with those dimensions.
//CGContextRef context = CGBitmapContextCreate(nil, cWidth, cHeight, bitsPerComponent, bytesPerRow, CGColorSpaceCreateDeviceRGB(), CGImageGetBitmapInfo(image));
//
//CGContextDrawImage(context, cropZone, image);
//
//CGImageRef result  = CGBitmapContextCreateImage(context);
//UIImage * cropUIImage = [[UIImage alloc] initWithCGImage:tmp];
//
//CGContextRelease(context);
//CGImageRelease(mergeResult);
//NSData * imgData = UIImagePNGRepresentation ( cropUIImage);
//}


//-(UIImage *)croppIngimageByImageName:(UIImage *)imageToCrop toRect:(CGRect)rect
//{
//    UIGraphicsBeginImageContextWithOptions(rect.size, false, imageToCrop.scale);
//    [imageToCrop drawInRect:CGRectMake(rect.origin.x, rect.origin.y, imageToCrop.size.width, imageToCrop.size.height)];
//    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
//    return img;
//}

//UIGraphicsBeginImageContextWithOptions(rect.size, false, self.scale)
//
//self.draw(in: CGRect(x: -rect.origin.x, y: -rect.origin.y, width: self.size.width, height: self.size.height))
//
//let croppedImage = UIGraphicsGetImageFromCurrentImageContext()!
//UIGraphicsEndImageContext()
//
//return croppedImage


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
