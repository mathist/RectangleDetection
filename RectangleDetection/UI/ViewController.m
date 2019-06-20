//
//  ViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/8/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Vision/Vision.h>

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, weak) IBOutlet UIView *overlay;
@property (nonatomic, weak) IBOutlet UIImageView *imgView;
@property (nonatomic, assign) BOOL readyToSnap;


@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *captureInput;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureLayer;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureOutput;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error;
    
    self.captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    
    if (error)
    {
        NSLog(@"%@", error.localizedDescription);
    }
    
    if (self.captureInput)
    {
        [self.captureSession addInput:self.captureInput];
    }
    
    self.captureLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    [self.captureLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.view.layer addSublayer:self.captureLayer];
    
    self.captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    self.sessionQueue = dispatch_queue_create("AVSessionQueue", NULL);
    
    [self.captureOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    

    [self.captureSession addOutput:self.captureOutput];

    
    [self.captureOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.captureOutput setSampleBufferDelegate:self queue:self.sessionQueue];
    
//    AVCaptureConnection *connection = [self.captureOutput connectionWithMediaType:AVMediaTypeVideo];
//    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    

    [self.view bringSubviewToFront:self.overlay];
}

- (AVCaptureVideoOrientation)interfaceOrientationToVideoOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
            case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
            case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
            case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
            case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        default:
            break;
    }
    return AVCaptureVideoOrientationPortrait;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.captureLayer.frame = self.view.bounds;
    if (self.captureLayer.connection.supportsVideoOrientation) {
        self.captureLayer.connection.videoOrientation = [self interfaceOrientationToVideoOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.captureSession startRunning];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.captureSession stopRunning];
}

-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    VNDetectRectanglesRequest *request = [[VNDetectRectanglesRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error)
    {
        if (error)
        {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
        
        CIImage *ciImage = [CIImage imageWithCVImageBuffer:buffer];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.overlay.layer.sublayers = nil;
        });
        
        NSMutableArray<CAShapeLayer*> *layers = [[NSMutableArray<CAShapeLayer*> alloc] init];

        dispatch_async(dispatch_get_main_queue(), ^{

            for (VNRectangleObservation *result in request.results)
            {
                CGSize size = self.view.frame.size;

                CGPoint topLeft = [self convertToUIView:result.topLeft forSize:size];
                CGPoint topRight = [self convertToUIView:result.topRight forSize:size];
                CGPoint bottomRight = [self convertToUIView:result.bottomRight forSize:size];
                CGPoint bottomLeft = [self convertToUIView:result.bottomLeft forSize:size];

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

                [layers addObject:layer];
                

                CGFloat rectMidY = (topLeft.y + topRight.y + bottomLeft.y + bottomRight.y) / 4;
                CGFloat viewMidY = size.height/2;

                if (topLeft.x < 40 && bottomLeft.x < 40 && topLeft.x > 0 && bottomLeft.x > 0
                    && topRight.x < size.width && bottomRight.x < size.width && topRight.x > size.width-40 && bottomRight.x < size.width-4
 //                   && topLeft.y < 100  //  {{0.093395181000232697, 0.63326859474182129}, {0.86546462029218674, 0.3219677209854126}}
//                    && bottomLeft.y > size.height - 100 //  {{0.021779622882604599, 0.11125495284795761}, {0.96119442954659462, 0.3316781297326088}}
                    && rectMidY > viewMidY-40 && rectMidY < viewMidY+40 //  {{0.084373533725738525, 0.35152605175971985}, {0.86713266372680664, 0.31159922480583191}}

                    )
                {
                    if (self.readyToSnap)
                    {
                        return;
                    }

                    self.readyToSnap = YES;

                    CGFloat y = result.boundingBox.origin.x * ciImage.extent.size.height;
                    CGFloat width = result.boundingBox.size.height * ciImage.extent.size.width;
                    CGFloat height = result.boundingBox.size.width * ciImage.extent.size.height;
                    CGFloat x = ciImage.extent.size.width - (result.boundingBox.origin.y * ciImage.extent.size.width) - width;
                    
                    CIContext *context = [CIContext contextWithOptions:nil];
                    CGImageRef cgImage = [context createCGImage:ciImage fromRect:CGRectMake(x, y, width, height)];

                    UIImage *img = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationRight];

                    CGImageRelease(cgImage);

                    [self.imgView setImage:img];
                    [self.view bringSubviewToFront:self.imgView];

                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);

                    [self.captureSession stopRunning];

                    return;
                }
            
            }
            
            for(CAShapeLayer *layer in layers)
            {
                [self.overlay.layer addSublayer:layer];
            }
            
        });
    }];
    
    request.maximumObservations = 10;
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:buffer orientation:kCGImagePropertyOrientationRight options:@{}];
    
    NSError *error;
    [handler performRequests:@[request] error:&error];
    
    if (error)
    {
        NSLog(@"%@", error.localizedDescription);
    }
    
}


-(CGPoint)convertToUIView:(CGPoint)point forSize:(CGSize)size
{
    CGPoint newPoint = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(size.width, size.height));
    newPoint = CGPointApplyAffineTransform(newPoint, CGAffineTransformMakeTranslation(0, -size.height));
    newPoint = CGPointApplyAffineTransform(newPoint, CGAffineTransformMakeScale(1, -1));
    
    return newPoint;
}







//-(BOOL)imageFrom:(CMSampleBufferRef)sampleBuffer
//{
//    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//
//    if(pixelBuffer == nil)
//    {
//        NSLog(@"%@", @"nil");
//        return NO;
//    }
//
//
//    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
//
////    uint8_t *buf = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
//
//    size_t width = CVPixelBufferGetWidth(pixelBuffer);
//    size_t height = CVPixelBufferGetHeight(pixelBuffer);
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
//    CGColorSpaceRef colorSpacer = CGColorSpaceCreateDeviceRGB();
//
//    CGContextRef context = CGBitmapContextCreate(CVPixelBufferGetBaseAddress(pixelBuffer), width, height, 8, bytesPerRow, colorSpacer, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
//    CGImageRef imgRef = CGBitmapContextCreateImage(context);
//    UIImage *img = [UIImage imageWithCGImage:imgRef scale:1.0 orientation:UIImageOrientationRight];
//
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
//
//    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
//
//    return YES;
//}





//func getImageFromSampleBuffer(sampleBuffer: CMSampleBuffer) ->UIImage? {
//    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//        return nil
//    }
//    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
//    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
//    let width = CVPixelBufferGetWidth(pixelBuffer)
//    let height = CVPixelBufferGetHeight(pixelBuffer)
//    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//    let colorSpace = CGColorSpaceCreateDeviceRGB()

//    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
//    guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
//        return nil
//    }
//    guard let cgImage = context.makeImage() else {
//        return nil
//    }
//    let image = UIImage(cgImage: cgImage, scale: 1, orientation:.right)
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
//    return image
//}

@end
