
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@class MHSwitchToggleLayer;
@class MHSwitchKnobLayer;

@interface MHSwitch : UIControl

@property (nonatomic, getter = isOn) BOOL on;

@property (nonatomic, strong) UIFont *font;

@property (nonatomic, copy) NSString *onText, *offText;
@property (nonatomic, strong) UIColor *onColor, *offColor;

@property (nonatomic, readonly, strong) MHSwitchToggleLayer *toggleLayer;
@property (nonatomic, readonly, strong) MHSwitchKnobLayer *knobLayer;
@property (nonatomic, readonly, strong) CALayer *borderLayer;

@property (nonatomic) CGFloat cornerRadius;

- (void)setOn:(BOOL)newOn animated:(BOOL)animated;

@end


@interface MHSwitchKnobLayer : CALayer

@property (nonatomic, getter = isHighlighted) BOOL highlighted;
@property (strong) UIColor *knobColor, *highlightedKnobColor;

@end


@interface MHSwitchToggleLayer : CALayer

@property (nonatomic, strong) UIColor *onColor, *offColor;
@property (nonatomic, strong) NSString *onText, *offText;
@property (nonatomic, strong) UIFont *font;

@end

