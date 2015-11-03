// Douglas Hill, November 2015

#import "ViewController.h"
#import "TouchShadowsView.h"

@interface ViewController ()

@property (nonatomic) TouchShadowsView *view;

@end

@implementation ViewController

@dynamic view;

- (void)loadView {
    [self setView:[[TouchShadowsView alloc] init]];
}

@end
