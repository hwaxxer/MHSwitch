
#import "MHSwitch.h"

#define kMHSwitchDefaultCornerRadius 4

@implementation MHSwitchKnobLayer

- (void)drawInContext:(CGContextRef)context
{
    UIColor *color = self.isHighlighted ? self.highlightedKnobColor : self.knobColor;
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, self.bounds);

    [super drawInContext:context];
}

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;
    [self setNeedsDisplay];
}

@end

@implementation MHSwitchToggleLayer

- (id)initWithOnText:(NSString *)onText
             offText:(NSString *)offText
             onColor:(UIColor *)onColor
            offColor:(UIColor *)offColor
{
    if ((self = [super init]))
    {
        self.onText = onText;
        self.offText = offText;
        self.onColor = onColor;
        self.offColor = offColor;
    }

    return self;
}

- (void)setFont:(UIFont *)font
{
    if (_font != font) {
        _font = font;
        [self setNeedsDisplay];
    }
}

- (void)drawInContext:(CGContextRef)context
{

    CGFloat knobCenter = self.bounds.size.width / 2.0;

    // On
    CGContextSetFillColorWithColor(context, self.onColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, knobCenter, self.bounds.size.height));

    // Off
    CGContextSetFillColorWithColor(context, self.offColor.CGColor);
    CGRect offRect = CGRectMake(knobCenter, 0, self.bounds.size.width - knobCenter, self.bounds.size.height);
    CGContextFillRect(context, offRect);
    CGContextSetStrokeColorWithColor(context, self.offColor.CGColor);
    CGContextStrokeRect(context, offRect);

    // Text
    CGFloat fontSize = floor(MIN(self.bounds.size.height * .7, self.bounds.size.width * 0.4));
    UIFont *font = [UIFont fontWithName:self.font.fontName size:fontSize];
    CGFloat textSpaceWidth = (self.bounds.size.width / 2) - (self.bounds.size.height / 2);

    UIGraphicsPushContext(context);

    CGSize onTextSize = [self.onText sizeWithFont:font];
    CGPoint onTextPoint = CGPointMake((textSpaceWidth - onTextSize.width) / 2.0, floorf((self.bounds.size.height - onTextSize.height) / 2.0));
    [[UIColor colorWithWhite:1.0 alpha:1.0] set];
    [self.onText drawAtPoint:CGPointMake(onTextPoint.x, onTextPoint.y - 1.0) withFont:font];

    CGSize offTextSize = [self.offText sizeWithFont:font];
    CGPoint offTextPoint = CGPointMake(textSpaceWidth + (textSpaceWidth - offTextSize.width) / 2.0 + self.bounds.size.height, floorf((self.bounds.size.height - offTextSize.height) / 2.0));
    [[UIColor colorWithWhite:0.52 alpha:1.0] set];
    [self.offText drawAtPoint:offTextPoint withFont:font];

    UIGraphicsPopContext();

    [super drawInContext:context];
}

@end


@interface MHSwitch ()

@property (nonatomic, readwrite, strong) MHSwitchToggleLayer *toggleLayer;
@property (nonatomic, readwrite, strong) MHSwitchKnobLayer *knobLayer;
@property (nonatomic, readwrite, strong) CALayer *borderLayer;
@property (nonatomic) BOOL ignoreTap;

@end

@implementation MHSwitch

- (id)init
{
    if ((self = [super init])) {
        [self sizeToFit];
        [self setup];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self setup];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self setup];
    }

    return self;
}

- (void)setup
{
    [self setHidden:YES];

    UIViewAutoresizing mask = self.autoresizingMask;
    if (mask & UIViewAutoresizingFlexibleHeight)
        self.autoresizingMask ^= UIViewAutoresizingFlexibleHeight;

    if (mask & UIViewAutoresizingFlexibleWidth)
        self.autoresizingMask ^= UIViewAutoresizingFlexibleWidth;

    MHSwitchToggleLayer *toggleLayer = [[MHSwitchToggleLayer alloc] initWithOnText:NSLocalizedString(@"on", nil)
                                                                           offText:NSLocalizedString(@"off", nil)
                                                                           onColor:[UIColor colorWithWhite:0.1 alpha:1]
                                                                          offColor:[UIColor colorWithWhite:0.95 alpha:1]];
    self.toggleLayer = toggleLayer;
    toggleLayer.font = [UIFont fontWithName:@"Helvetica" size:0];
    [self.layer addSublayer:toggleLayer];
    [toggleLayer setNeedsDisplay];

    MHSwitchKnobLayer *knobLayer = [MHSwitchKnobLayer layer];
    self.knobLayer = knobLayer;
    knobLayer.knobColor = [UIColor whiteColor];
    knobLayer.highlightedKnobColor = [UIColor colorWithWhite:0.95 alpha:1];
    knobLayer.masksToBounds = YES;
    knobLayer.borderWidth = 1;
    knobLayer.borderColor = [UIColor colorWithWhite:0.7 alpha:1].CGColor;
    [toggleLayer addSublayer:knobLayer];
    [knobLayer setNeedsDisplay];

    toggleLayer.contentsScale = knobLayer.contentsScale = [[UIScreen mainScreen] scale];

    // tap gesture for toggling the switch
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(tapped:)];
    [self addGestureRecognizer:tapGestureRecognizer];

    // pan gesture for moving the switch knob manually
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(toggleDragged:)];
    [self addGestureRecognizer:panGesture];

    [self adjustToggle];

    // Add a border around the outermost white part of the control
    CALayer *borderLayer = [CALayer layer];
    self.borderLayer = borderLayer;
    borderLayer.masksToBounds = YES;
    borderLayer.borderWidth = 1;
    borderLayer.borderColor = [UIColor colorWithWhite:0.7 alpha:1].CGColor;
    [self.layer addSublayer:borderLayer];
    [borderLayer setNeedsDisplay];

    [self setHidden:NO];
    [self setFrame:self.frame];
    [self setCornerRadius:kMHSwitchDefaultCornerRadius];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius != cornerRadius) {
        _cornerRadius = cornerRadius;

        UIBezierPath *clippingPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                                cornerRadius:cornerRadius];

        CAShapeLayer *clippingLayer = [CAShapeLayer layer];
        CGRect clippingLayerFrame = self.bounds;
        clippingLayer.path = clippingPath.CGPath;
        clippingLayerFrame.size.width = CGRectGetMidX(clippingLayer.frame);
        self.layer.mask = clippingLayer;
        [clippingLayer setNeedsDisplay];

        self.knobLayer.cornerRadius = cornerRadius;
        self.borderLayer.cornerRadius = cornerRadius;

        CGRect borderLayerFrame = self.bounds;
        borderLayerFrame.size.width = self.frame.size.width;
        borderLayerFrame.origin.x = self.frame.size.width - cornerRadius;
        CALayer *borderClippingLayer = self.borderLayer.mask;
        [borderClippingLayer setBackgroundColor:[UIColor blackColor].CGColor];
        [borderClippingLayer setFrame:borderLayerFrame];
        [self.borderLayer setFrame:self.bounds];
        [self.borderLayer setMask:borderClippingLayer];
    }
}


#pragma mark -
#pragma mark Setup Frame/Layout


- (void)adjustHandle
{
    // positions the the knob
    self.knobLayer.frame = CGRectMake(self.bounds.size.width - CGRectGetMaxX(self.knobLayer.frame),
                                      0,
                                      self.knobLayer.frame.size.width,
                                      self.knobLayer.frame.size.height);

}

- (void)adjustToggle
{
    CGFloat minToggleX = round(self.knobLayer.frame.size.width - self.frame.size.width);
    CGFloat maxToggleX = 0;

    CGRect frame;
    if (self.on) {
        frame = CGRectMake(maxToggleX,
                           self.toggleLayer.frame.origin.y,
                           self.toggleLayer.frame.size.width,
                           self.toggleLayer.frame.size.height);
    } else {
        frame = CGRectMake(minToggleX,
                           self.toggleLayer.frame.origin.y,
                           self.toggleLayer.frame.size.width,
                           self.toggleLayer.frame.size.height);
    }

    self.toggleLayer.frame = frame;
}


#pragma mark -
#pragma mark - Touches

- (void)tapped:(UITapGestureRecognizer *)gesture
{
    if (self.ignoreTap) return;

    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self setOn:!self.on animated:YES];
    }
}

- (void)toggleDragged:(UIPanGestureRecognizer *)gesture
{
    CGFloat minToggleX = self.knobLayer.frame.size.width - self.frame.size.width;
    CGFloat maxToggleX = 0;

    if (gesture.state == UIGestureRecognizerStateBegan) {
        // setup by turning off the manual clipping of the toggleLayer and setting up a layer mask.
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        self.knobLayer.highlighted = YES;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:self];

        // disable the animations before moving the layers
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

        // darken the knob
        if (!self.knobLayer.highlighted)
            self.knobLayer.highlighted = YES;

        // move the toggleLayer using the translation of the gesture, keeping it inside the outline.
        CGFloat newX = self.toggleLayer.frame.origin.x + translation.x;
        if (newX <= minToggleX) newX = minToggleX;
        if (newX >= maxToggleX) newX = maxToggleX;
        self.toggleLayer.frame = CGRectMake(newX,
                                            self.toggleLayer.frame.origin.y,
                                            self.toggleLayer.frame.size.width,
                                            self.toggleLayer.frame.size.height);

        [gesture setTranslation:CGPointZero inView:self];
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        // flip the switch to on or off depending on which half it ends at
        CGFloat toggleCenter = CGRectGetMidX(self.toggleLayer.frame);
        [self setOn:(toggleCenter > CGRectGetMidX(self.bounds)) animated:YES];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.ignoreTap) return;

    [super touchesBegan:touches withEvent:event];

    self.knobLayer.highlighted = YES;
    [self sendActionsForControlEvents:UIControlEventTouchDown];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];

    [self sendActionsForControlEvents:UIControlEventTouchUpOutside];
}


#pragma mark Setters/Getters

- (void)setOn:(BOOL)newOn
{
    [self setOn:newOn animated:NO];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated
{
    BOOL previousOn = self.on;
    _on = on;

    if (animated) {
        self.ignoreTap = YES;

        [CATransaction setAnimationDuration:0.014];
        self.knobLayer.highlighted = YES;

        [CATransaction setCompletionBlock:^{
            [CATransaction begin];

            [self adjustToggle];

            self.knobLayer.highlighted = NO;

            [CATransaction setCompletionBlock:^{
                self.ignoreTap = NO;

                // send the action here so it get's sent at the end of the animations
                if (previousOn != self.on) {
                    [self sendActionsForControlEvents:UIControlEventValueChanged];
                }
            }];

            [CATransaction commit];
        }];
    } else {

        [self adjustToggle];
    }
}

- (void)setFrame:(CGRect)aFrame
{
    [super setFrame:aFrame];

    CGFloat knobWidth = roundf(self.bounds.size.width * 0.4);
    self.knobLayer.frame = CGRectMake(0, 0, knobWidth, self.bounds.size.height);
    CGSize toggleSize = CGSizeMake(roundf(self.bounds.size.width * 2 - knobWidth), self.bounds.size.height);

    CGRect toggleLayerFrame = self.toggleLayer.frame;
    toggleLayerFrame.size = toggleSize;

    [self.toggleLayer setFrame:toggleLayerFrame];

    [self adjustToggle];
    [self adjustHandle];
}


#pragma mark -
#pragma mark - Propagation

- (void)setOnText:(NSString *)onText
{
    self.toggleLayer.onText = onText;
}

- (void)setOffText:(NSString *)offText
{
    self.toggleLayer.offText = offText;
}

- (NSString *)onText
{
    return self.toggleLayer.onText;
}

- (NSString *)offText
{
    return self.toggleLayer.offText;
}

- (void)setOnColor:(UIColor *)onColor
{
    self.toggleLayer.onColor = onColor;
}

- (UIColor *)onColor
{
    return self.toggleLayer.onColor;
}

- (void)setOffColor:(UIColor *)offColor
{
    self.toggleLayer.offColor = offColor;
}

- (UIColor *)offColor
{
    return self.toggleLayer.offColor;
}

- (void)setFont:(UIFont *)font
{
    self.toggleLayer.font = font;
}

- (UIFont *)font
{
    return self.toggleLayer.font;
}

@end
