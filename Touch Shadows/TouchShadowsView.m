// Douglas Hill, November 2015

#import "TouchShadowsView.h"

@interface TouchShadowsView ()

@property (nonatomic) NSMapTable<UITouch *, CALayer *> *shadows;

@end

@implementation TouchShadowsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self == nil) return nil;

    _shadows = [NSMapTable strongToStrongObjectsMapTable];

    [self setBackgroundColor:[UIColor whiteColor]];
    [self setMultipleTouchEnabled:YES];

    return self;
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self addShadowsForTouches:touches];
    [self updateShadowsForTouches:touches event:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    [self updateShadowsForTouches:touches event:event];
}

- (void)touchesEstimatedPropertiesUpdated:(NSSet *)touches {
    [super touchesEstimatedPropertiesUpdated:touches];
    [self updateShadowsForTouches:touches event:nil];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self removeShadowsForTouches:touches];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self removeShadowsForTouches:touches];
}

#pragma mark - Shadows

- (void)addShadowsForTouches:(NSSet<UITouch *> *)touches {
    for (UITouch *touch in touches) {
        CALayer *const shadow = [CALayer layer];
        [shadow setBackgroundColor:shadowColourForTouch(touch).CGColor];
        [[self layer] addSublayer:shadow];
        [[self shadows] setObject:shadow forKey:touch];
    }
}

- (void)updateShadowsForTouches:(NSSet<UITouch *> *)touches event:(nullable UIEvent *)event {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

    for (UITouch *touch in touches) {
        CALayer *const shadow = [[self shadows] objectForKey:touch];

        UITouch *const bestTouch = [[event predictedTouchesForTouch:touch] lastObject] ?: touch;

        [shadow setOpacity:([bestTouch maximumPossibleForce] > 0) ? [bestTouch force] / [bestTouch maximumPossibleForce] : 0.5];
        [shadow setOpacity:0.6];
        [shadow setPosition:[bestTouch preciseLocationInView:self]];

#define MOCK_STYLUS 0
        BOOL const isStylusTouch = [bestTouch type] == UITouchTypeStylus || MOCK_STYLUS;

        if (isStylusTouch) {
            static CGFloat const stylusThickness = 40;
            static CGFloat const stylusLength = 850;

            CGFloat const azimthAngle = MOCK_STYLUS ? M_PI_4 : [bestTouch azimuthAngleInView:self];
            CGFloat  const altitudeAngle = MOCK_STYLUS ? M_PI_4 : [bestTouch altitudeAngle];

            [shadow setAnchorPoint:CGPointMake(0, 0.5)];
            [shadow setBounds:CGRectMake(0, 0, stylusThickness + stylusLength * cos(altitudeAngle), stylusThickness)];
            [shadow setTransform:CATransform3DMakeRotation(azimthAngle, 0, 0, 1)];
            [shadow setCornerRadius:0.5 * stylusThickness];

            continue;
        }

        [shadow setAnchorPoint:CGPointMake(0.5, 0.5)];

        // Add 20% so it is easier to see under the finger, and have a mimimum so it doesn’t look broken on the simulator.
        CGFloat const radius = MAX(1.2 * [bestTouch majorRadius], 5);
        CGFloat const diameter = 2 * radius;
        [shadow setBounds:CGRectMake(0, 0, diameter, diameter)];
        [shadow setCornerRadius:radius];
    }

    [CATransaction commit];
}

- (void)removeShadowsForTouches:(NSSet<UITouch *> *)touches {
    for (UITouch *touch in touches) {
        CALayer *const shadow = [[self shadows] objectForKey:touch];
        [shadow removeFromSuperlayer];
        [[self shadows] removeObjectForKey:touch];
    }
}

UIColor *shadowColourForTouch(UITouch *touch) {
    switch ([touch type]) {
        case UITouchTypeDirect: return [UIColor colorWithHue:0.6 saturation:1 brightness:0.5 alpha:1];
        case UITouchTypeIndirect: return [UIColor colorWithHue:0 saturation:1 brightness:0.3 alpha:1];
        case UITouchTypeStylus: return [UIColor colorWithHue:0.3 saturation:1 brightness:0.2 alpha:1];
    }
}

@end
