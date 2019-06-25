//
//  IDCardBackViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 6/13/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "IDCardBackViewController.h"
#import "CaptureVideoService.h"
#import "RectangleService.h"
#import "MotionService.h"
#import "ImageCorrection.h"
#import "UIImage+Extensions.h"

@interface IDCardBackViewController () <RectangleServiceDelegate, CaptureVideoServiceDelegate, MotionServiceDelegate,ImageCorrectionDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblStatus;

@property (nonatomic, retain) ImageCorrection *imageCorrection;
@property (nonatomic, retain) CaptureVideoService *captureVideoService;
@property (nonatomic, retain) RectangleService *rectangleService;

@property (nonatomic, assign) BOOL photoCaptured;
@property (nonatomic, assign) BOOL barCodeCaptured;
@property (nonatomic, assign) CGRect boundingBox;

@end

@implementation IDCardBackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.barCodeCaptured = YES;

    
    self.imageCorrection = [ImageCorrection new];
    [self.imageCorrection setDelegate:self];
    self.captureVideoService = [[CaptureVideoService alloc] initWithImageCorrection:self.imageCorrection withOptions:kCaptureVideoServiceOptionOutput | kCaptureVideoServiceOptionPhoto | kCaptureVideoServiceOptionBarcode];
    [self.captureVideoService setDelegate:self];
    self.rectangleService = [RectangleService new];
    
    [self.rectangleService setDelegate:self];
    [self.view.layer addSublayer:self.captureVideoService.captureLayer];
    
//    [MotionService.shared setDelegate:self];
    
    [self.view bringSubviewToFront:self.lblStatus];
}

-(void)dealloc
{
//    [MotionService.shared stop];
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
                self.boundingBox = result.boundingBox;
                
                [self.captureVideoService takePhoto];
            }
        }
    });
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo
{
    if(!self.photoCaptured || !self.barCodeCaptured)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
}

#pragma mark CaptureVideoServiceDelegate methods
-(void)captureVideoServiceSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self.rectangleService request:sampleBuffer];
}

-(void)captureVideoServicePhotoOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo
{
    [self.captureVideoService stopCamera];
    
    CIImage *ciImage = [CIImage imageWithCVImageBuffer:photo.pixelBuffer];
    
    self.boundingBox = CGRectMake(self.boundingBox.origin.x - .1, self.boundingBox.origin.y - .05, self.boundingBox.size.width + .2, self.boundingBox.size.height + .1);
    
    CGFloat y = self.boundingBox.origin.x * ciImage.extent.size.height;
    CGFloat width = self.boundingBox.size.height * ciImage.extent.size.width;
    CGFloat height = self.boundingBox.size.width * ciImage.extent.size.height;
    CGFloat x = ciImage.extent.size.width - (self.boundingBox.origin.y * ciImage.extent.size.width) - width;
    
    ciImage = [ciImage imageByCroppingToRect:CGRectMake(x, y, width, height)];
    
    NSData *pngData = [[CIContext contextWithOptions:nil] PNGRepresentationOfImage:ciImage format:kCIFormatBGRA8 colorSpace:CGColorSpaceCreateDeviceRGB() options:@{}];
    UIImage *pngImg = [UIImage imageWithData:pngData scale:1.0];
    pngImg = [pngImg imageRotatedByDegrees:90];

    UIImageWriteToSavedPhotosAlbum(pngImg, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

-(void)captureVideoServiceMetaDataOutput:(NSArray<__kindof AVMetadataObject *> *)metaDataObjects
{
    if(self.barCodeCaptured)
        return;
    
    if(metaDataObjects.count != 1)
        return;
    
    AVMetadataObject *metadataObject = metaDataObjects.firstObject;

    if (metadataObject.type != AVMetadataObjectTypePDF417Code)
        return;

    for(AVMetadataObject *obj in metaDataObjects)
    {
        if([[self.captureVideoService.captureLayer transformedMetadataObjectForMetadataObject:obj] isKindOfClass:[AVMetadataMachineReadableCodeObject class]])
        {
            self.barCodeCaptured = YES;
            
            NSString *scanResults =[(AVMetadataMachineReadableCodeObject *)obj stringValue];
            NSLog(@"%@", scanResults);

            NSDictionary *d = [self parseResults:scanResults];

            [self image:nil didFinishSavingWithError:nil contextInfo:nil];
            
//            NTKDispatchMainAsync(^{
//                NSDictionary *d = [self parseResults:self.scanResults];
//                if (self.delegate && [self.delegate respondsToSelector:@selector(barCodeControllerDidCompleteWithDictionary:)])
//                    [self.delegate barCodeControllerDidCompleteWithDictionary:d];
//            });
        }
    }
}


-(NSDictionary<NSString*,NSString*>*)parseResults:(NSString *)string
{
    NSMutableDictionary<NSString*,NSString*> *dict = [[NSMutableDictionary<NSString*,NSString*> alloc] init];
    NSArray<NSString*> *lines = [string componentsSeparatedByString:@"\n"];
    
    NSDictionary<NSString*,NSString*> *prefixes = [self fieldPrefixes];
    
    for (int i = 0;i<lines.count;i++)
    {
        NSString *l = [lines objectAtIndex:i];
        
        l = [l stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if(l.length > 3)
        {
            for(NSString *key in prefixes.allKeys)
            {
                BOOL found = false;
                
                for(NSString *result =  [self findSuffix:key forString:l]; result != nil; result = nil) {
                    [dict setObject:result forKey:[prefixes objectForKey:key]];
                    found = true;
                }
                if (found)
                    continue;
            }
        }
    }
    
    return dict;
}

-(NSString *)findSuffix:(NSString *)prefix forString:(NSString *)string
{
    NSString *result;
    
    if([string hasPrefix:prefix])
        result = [string substringFromIndex:prefix.length];
    
    return result;
}

-(NSDictionary<NSString*,NSString*> *)fieldPrefixes
{
    NSDictionary<NSString*,NSString*> *dict = @{@"DAA" : @"Full Name"
                                                ,@"DAB" : @"Last Name"
                                                ,@"DAB" : @"Last Name"
                                                ,@"DAC" : @"First Name"
                                                ,@"DAC" : @"First Name"
                                                ,@"DAD" : @"Middle Name"
                                                ,@"DAD" : @"Middle Name"
                                                ,@"DAE" : @"Name Suffix"
                                                ,@"DAF" : @"Name Prefix"
                                                ,@"DAG" : @"Mailing Street Address1"
                                                ,@"DAH" : @"Mailing Street Address2"
                                                ,@"DAI" : @"Mailing City"
                                                ,@"DAJ" : @"State"
                                                ,@"DAK" : @"Mailing Postal Code"
                                                ,@"DAL" : @"Residence Street Address1"
                                                ,@"DAM" : @"Residence Street Address2"
                                                ,@"DAN" : @"Residence City"
                                                ,@"DAO" : @"Residence Jurisdiction Code"
                                                ,@"DAP" : @"Mailing Postal Code"
                                                ,@"DAQ" : @"License or ID Number"
                                                ,@"DAR" : @"License Classification Code"
                                                ,@"DAS" : @"License Restriction Code"
                                                ,@"DAT" : @"License Endorsements Code"
                                                ,@"DAU" : @"Height in FT_IN"
                                                ,@"DAV" : @"Height in CM"
                                                ,@"DAW" : @"Weight in LBS"
                                                ,@"DAX" : @"Weight in KG"
                                                ,@"DAY" : @"Eye Color"
                                                ,@"DAZ" : @"Hair Color"
                                                ,@"DBA" : @"License Expiration Date"
                                                ,@"DBB" : @"Date of Birth"
                                                ,@"DBC" : @"Sex"
                                                ,@"DBD" : @"License or ID Document Issue Date"
                                                ,@"DBE" : @"Issue Timestamp"
                                                ,@"DBF" : @"Number of Duplicates"
                                                ,@"DBG" : @"Medical Indicator Codes"
                                                ,@"DBH" : @"Organ Donor"
                                                ,@"DBI" : @"Non-Resident Indicator"
                                                ,@"DBJ" : @"Unique Customer Identifier"
                                                ,@"DBK" : @"Social Security Number"
                                                ,@"DBL" : @"Date Of Birth"
                                                ,@"DBM" : @"Social Security Number"
                                                ,@"DBN" : @"Full Name"
                                                ,@"DBO" : @"Last Name"
                                                ,@"DBO" : @"Last Name"
                                                ,@"DBP" : @"First Name"
                                                ,@"DBP" : @"First Name"
                                                ,@"DBQ" : @"Middle Name"
                                                ,@"DBQ" : @"Middle Name"
                                                ,@"DBR" : @"Suffix"
                                                ,@"DBS" : @"Prefix"
                                                ,@"DCA" : @"Virginia Specific Class"
                                                ,@"DCB" : @"Virginia Specific Restrictions"
                                                ,@"DCD" : @"Virginia Specific Endorsements"
                                                ,@"DCE" : @"Physical Description Weight Range"
                                                ,@"DCF" : @"Document Discriminator"
                                                ,@"DCG" : @"Country territory of issuance"
                                                ,@"DCH" : @"Federal Commercial Vehicle Codes"
                                                ,@"DCI" : @"Place of birth"
                                                ,@"DCJ" : @"Audit information"
                                                ,@"DCK" : @"Inventory Control Number"
                                                ,@"DCL" : @"Race Ethnicity"
                                                ,@"DCM" : @"Standard vehicle classification"
                                                ,@"DCN" : @"Standard endorsement code"
                                                ,@"DCO" : @"Standard restriction code"
                                                ,@"DCP" : @"Jurisdiction specific vehicle classification description"
                                                ,@"DCQ" : @"Jurisdiction-specific"
                                                ,@"DCR" : @"Jurisdiction specific restriction code description"
                                                ,@"DCS" : @"Last Name"
                                                ,@"DCS" : @"Last Name"
                                                ,@"DCT" : @"First Name"
                                                ,@"DCT" : @"First Name"
                                                ,@"DCU" : @"Suffix"
                                                ,@"DDA" : @"Compliance Type"
                                                ,@"DDB" : @"Card Revision Date"
                                                ,@"DDC" : @"HazMat Endorsement Expiry Date"
                                                ,@"DDD" : @"Limited Duration Document Indicator"
                                                ,@"DDE" : @"Family Name Truncation"
                                                ,@"DDF" : @"First Names Truncation"
                                                ,@"DDG" : @"Middle Names Truncation"
                                                ,@"DDH" : @"Under 18 Until"
                                                ,@"DDI" : @"Under 19 Until"
                                                ,@"DDJ" : @"Under 21 Until"
                                                ,@"DDK" : @"Organ Donor Indicator"
                                                ,@"DDL" : @"Veteran Indicator"
                                                ,@"PAA" : @"Permit Classification Code"
                                                ,@"PAB" : @"Permit Expiration Date"
                                                ,@"PAC" : @"Permit Identifier"
                                                ,@"PAD" : @"Permit IssueDate"
                                                ,@"PAE" : @"Permit Restriction Code"
                                                ,@"PAF" : @"Permit Endorsement Code"
                                                ,@"ZVA" : @"Court Restriction Code"};
    
    return dict;
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
