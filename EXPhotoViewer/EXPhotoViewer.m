//
//  EXPhotoViewer.m
//  EXPhotoViewerDemo
//
//  Created by Julio Carrettoni on 3/20/14.
//  Modified by Antoine Harlin on 7/05/15.
//  MIT license

#import "EXPhotoViewer.h"

@interface EXPhotoViewer ()

@property (nonatomic, retain) UIScrollView *zoomeableScrollView;
@property (nonatomic, retain) UIImageView *originalImageView;
@property (nonatomic, retain) UIImageView *theImageView;
@property (nonatomic, retain) UIView* tempViewContainer;
@property (nonatomic, assign) CGRect originalImageRect;
@property (nonatomic, retain) UIViewController* controller;
@property (nonatomic, retain) UIViewController* selfController;
@property (atomic, readwrite) BOOL isClosing;
@property (strong, nonatomic) NSString *titleString;

@end

@implementation EXPhotoViewer

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

+ (instancetype)showImageFrom:(UIImageView *)imageView {
    EXPhotoViewer *viewer = [self newViewerFor:imageView];
    
    [viewer show];
    
    return viewer;
}

+ (instancetype)showImageFrom:(UIImageView *)imageView title:(NSString *)title {
    EXPhotoViewer *viewer = [self newViewerFor:imageView];
    viewer.titleString = title;
    [viewer show];
    
    return viewer;
}

+ (instancetype)newViewerFor:(UIImageView *)imageView {
    EXPhotoViewer *viewer = nil;
    
    if (imageView.image) {
        viewer = [[self alloc] init];
        viewer.originalImageView = imageView;
        viewer.backgroundScale = 1.0;
    }
    
    return viewer;
}

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor clearColor];

    self.theImageView = [[UIImageView alloc]initWithImage:self.originalImageView.image];
    self.zoomeableScrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    [self.zoomeableScrollView addSubview:self.theImageView];
    self.zoomeableScrollView.contentSize = self.theImageView.bounds.size;
    self.zoomeableScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.zoomeableScrollView.minimumZoomScale = 1.0f;
    self.zoomeableScrollView.maximumZoomScale = 8.0f;
    self.zoomeableScrollView.delegate = self;
    [self.view addSubview:self.zoomeableScrollView];
}

-(UIViewController *)rootViewController {
    UIViewController* controller = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    if ([controller presentedViewController]) {
        controller = [controller presentedViewController];
    }
    return controller;
}

- (void)show {
    if (self.controller)
        return;
    
    UIViewController * controller = [self rootViewController];
    
    self.tempViewContainer = [[UIView alloc] initWithFrame:controller.view.bounds];
    self.tempViewContainer.backgroundColor = controller.view.backgroundColor;
    controller.view.backgroundColor = [UIColor blackColor];
    
    for (UIView* subView in controller.view.subviews) {
        [self.tempViewContainer addSubview:subView];
    }
    
    [controller.view addSubview:self.tempViewContainer];
    
    self.controller = controller;
    
    self.view.frame = controller.view.bounds; //CGRectZero;
    self.view.backgroundColor = [UIColor clearColor];
    
    [controller.view addSubview:self.view];
    
    // Create title label
    if (self.titleString) {
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 30, self.view.frame.size.width, 30)];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.titleLabel.text = self.titleString;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.400];
        
        [self.view addSubview:self.titleLabel];
    }
    
    self.theImageView.image = self.originalImageView.image;
    self.originalImageRect = [self.originalImageView convertRect:self.originalImageView.bounds toView:self.view];
    
    self.theImageView.frame = self.originalImageRect;
    
    //listen to the orientation change notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.backgroundColor = (self.backgroundColor) ? self.backgroundColor : [UIColor blackColor];
        self.tempViewContainer.layer.transform = CATransform3DMakeScale(self.backgroundScale, self.backgroundScale, self.backgroundScale);
        self.theImageView.frame = [self centeredOnScreenImage:self.theImageView.image];
    } completion:^(BOOL finished) {
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
        [self.view addGestureRecognizer:tap];
    }];
    
    self.selfController = self; //Stupid ARC I need to do this to avoid being dealloced :P
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];}

- (void)orientationDidChange:(NSNotification *)note {
    self.theImageView.frame = [self centeredOnScreenImage:self.theImageView.image];
    
    CGRect newFrame = [self rootViewController].view.bounds;
    self.tempViewContainer.frame = newFrame;
    self.view.frame = newFrame;
    self.zoomeableScrollView.frame = newFrame;
    [self scrollViewDidEndZooming:self.zoomeableScrollView withView:self.theImageView atScale:1.0];
}

- (void)close {
    if (!self.isClosing) {
        self.isClosing = YES;
        
        CGRect absoluteCGRect = [self.view convertRect:self.theImageView.frame fromView:self.theImageView.superview];
        self.zoomeableScrollView.contentOffset = CGPointZero;
        self.zoomeableScrollView.contentInset = UIEdgeInsetsZero;
        self.theImageView.frame = absoluteCGRect;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.theImageView.frame = self.originalImageRect;
            self.view.backgroundColor = [UIColor clearColor];
            self.tempViewContainer.layer.transform = CATransform3DIdentity;
        }completion:^(BOOL finished) {
            self.originalImageView.image = self.theImageView.image;
            self.controller.view.backgroundColor = self.tempViewContainer.backgroundColor;
            for (UIView* subView in self.tempViewContainer.subviews) {
                [self.controller.view addSubview:subView];
            }
            [self.view removeFromSuperview];
            [self.tempViewContainer removeFromSuperview];
            
            self.isClosing = NO;
        }];
        
        self.selfController = nil;//Ok ARC you can kill me now.
    }
}

- (CGRect)centeredOnScreenImage:(UIImage*) image {
    CGSize imageSize = [self imageSizesizeThatFitsForImage:self.theImageView.image];
    CGPoint imageOrigin = CGPointMake(self.view.frame.size.width/2.0 - imageSize.width/2.0, self.view.frame.size.height/2.0 - imageSize.height/2.0);
    return CGRectMake(imageOrigin.x, imageOrigin.y, imageSize.width, imageSize.height);
}

- (CGSize)imageSizesizeThatFitsForImage:(UIImage*) image {
    if (!image)
        return CGSizeZero;
    
    CGSize imageSize = image.size;
    CGFloat ratio = MIN(self.view.frame.size.width/imageSize.width, self.view.frame.size.height/imageSize.height);
    return CGSizeMake(imageSize.width*ratio, imageSize.height*ratio);
}

#pragma mark - ZOOM
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.theImageView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    float x = 0;
    if (self.theImageView.frame.size.width < self.zoomeableScrollView.frame.size.width) {
        x = (self.zoomeableScrollView.frame.size.width - self.theImageView.frame.size.width) / 2;
    }
    float y = 0;
    if (self.theImageView.frame.size.height < self.zoomeableScrollView.frame.size.height) {
        y = (self.zoomeableScrollView.frame.size.height - self.theImageView.frame.size.height) / 2;
    }
    [UIView animateWithDuration:0.2 animations:^{
        [UIView setAnimationBeginsFromCurrentState:YES];
        self.theImageView.frame = CGRectMake(x, y, self.theImageView.frame.size.width, self.theImageView.frame.size.height);
    }];
    
}

@end
