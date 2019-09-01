//
//  TextReadingViewController.m
//  RectangleDetection
//
//  Created by Todd Mathison on 8/30/19.
//  Copyright © 2019 Todd Mathison. All rights reserved.
//

#import "TextReadingViewController.h"
#import "TextReadingService.h"

@interface TextReadingViewController () <TextReadingServiceDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *imgView;
@property (nonatomic, weak) IBOutlet UITextView *txtView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *imgHeight;
@property (nonatomic, strong) UIImage *img;
@property (nonatomic, retain) CALayer *overlayLayer;


@property (nonatomic, retain) TextReadingService *textReadingService;

@end

@implementation TextReadingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textReadingService = [TextReadingService new];
    [self.textReadingService setDelegate:self];
    
    self.overlayLayer = [CALayer new];
    [self.imgView.layer addSublayer:self.overlayLayer];

}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.overlayLayer.frame = self.imgView.bounds;
}

-(IBAction)takePhoto:(UIButton *)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    [self presentViewController:picker animated:YES completion:nil];
}

-(IBAction)readText:(UIButton *)sender
{
    if (self.img)
        [self.textReadingService readText:self.img];
}

#pragma mark TextReadingServiceDelegate methods

- (void)textFound:(nonnull NSArray<VNRecognizedTextObservation *> *)texts API_AVAILABLE(ios(13.0))
{
    NSMutableArray<NSString*> *strings = [NSMutableArray<NSString*> new];
    self.overlayLayer.sublayers = nil;

    if (@available(iOS 13.0, *))
    {
        for (VNRecognizedTextObservation *observation in texts)
        {
            VNRecognizedText *text = [[observation topCandidates:1] firstObject];
            
            if(text)
            {
                [strings addObject:text.string];
            }
            
            CGFloat x = observation.topLeft.x * self.imgView.frame.size.width;
            CGFloat y = (1-observation.topLeft.y) * self.imgView.frame.size.height;
            CGFloat width = (observation.topRight.x - observation.topLeft.x) * self.imgView.frame.size.width;
            CGFloat height = ((1-observation.bottomLeft.y) - (1-observation.topLeft.y)) * self.imgView.frame.size.height;

            UIBezierPath *path = [[UIBezierPath alloc] init];
            [path moveToPoint:CGPointMake(x, y)];
            [path addLineToPoint:CGPointMake(x+width, y)];
            [path addLineToPoint:CGPointMake(x+width, y+height)];
            [path addLineToPoint:CGPointMake(x, y+height)];
            [path addLineToPoint:CGPointMake(x, y)];

            CAShapeLayer *layer = [CAShapeLayer layer];
            [layer setPath:path.CGPath];
            [layer setFillRule:kCAFillRuleEvenOdd];
            [layer setBorderWidth:2.0];
            [layer setStrokeColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0].CGColor];
            [layer setFillColor:nil];

            [self.overlayLayer addSublayer:layer];
        }
    }
    else
    {
        
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.txtView setText: [strings componentsJoinedByString:@"\n"]];
    });
}

#pragma mark UIImagePickerControllerDelegate methods

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (self.presentedViewController)
        [self dismissViewControllerAnimated:true completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    if(info[UIImagePickerControllerEditedImage])
        self.img = info[UIImagePickerControllerEditedImage];
    else if (info[UIImagePickerControllerOriginalImage])
        self.img = info[UIImagePickerControllerOriginalImage];
    
    if(self.img)
    {
        dispatch_async(dispatch_get_main_queue(), ^{

            self.imgView.image = self.img;
            self.imgHeight.constant = (self.img.size.height * self.imgView.frame.size.width) / self.img.size.width;
            
            
//            UIBezierPath *path = [[UIBezierPath alloc] init];
//
//            [path moveToPoint:CGPointMake(10, 10)];
//            [path addLineToPoint:CGPointMake(50, 10)];
//            [path addLineToPoint:CGPointMake(50, 50)];
//            [path addLineToPoint:CGPointMake(10, 50)];
//            [path addLineToPoint:CGPointMake(10, 10)];
//
//
//            CAShapeLayer *layer = [CAShapeLayer layer];
//            [layer setPath:path.CGPath];
//            [layer setFillRule:kCAFillRuleEvenOdd];
//            [layer setBorderWidth:2.0];
//            [layer setStrokeColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0].CGColor];
//            [layer setFillColor:nil];
//
//            [self.overlayLayer addSublayer:layer];
            
        });
        
    }
    
    if (self.presentedViewController)
        [self dismissViewControllerAnimated:true completion:nil];
}

@end
