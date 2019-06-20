#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const kRollMax = @"kRollMax";
static NSString *const kRollMin = @"kRollMin";
static NSString *const kPitchMax = @"kPitchMax";
static NSString *const kPitchMin = @"kPitchMin";
static NSString *const kYawMax = @"kYawMax";
static NSString *const kYawMin = @"kYawMin";

static NSString *const kDeviceTooFar = @"kDeviceTooFar";
static NSString *const kDeviceTooClose = @"kDeviceTooClose";
static NSString *const kCentered = @"kCentered";

static NSString *const kFocusing = @"kFocusing";
static NSString *const kAdjustingExposure = @"kAdjustingExposure";
static NSString *const kAdjustingColorBalance = @"kAdjustingColorBalance";

static NSString *const kAlignmentMargin = @"kAlignmentMargin";

@protocol ImageCorrectionDelegate;

@interface ImageCorrection : NSObject

@property(nonatomic, weak) id<ImageCorrectionDelegate> delegate;
@property (nonatomic, retain) NSMutableDictionary<NSString*,NSString*> *correctionDictionary;

-(NSDictionary<NSString*,NSNumber*>*)settingsForID;
-(double)idSettingForKey:(NSString *)key;
-(NSArray*)messages;

@end

@protocol ImageCorrectionDelegate <NSObject>

-(void)correctionDictionaryChanged;

@end

NS_ASSUME_NONNULL_END
