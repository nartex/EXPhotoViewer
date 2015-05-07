//
//  EXPhotoViewer.h
//  EXPhotoViewerDemo
//
//  Created by Julio Carrettoni on 3/20/14.
//  Modified by Antoine Harlin on 7/05/15.
//

#import <UIKit/UIKit.h>

@interface EXPhotoViewer : UIViewController <UIScrollViewDelegate, UIAppearanceContainer>

/**
 *  The scale to be applied as transformation to the background. IE, a scall of 
 *  0.8 would "shrink" the background making it appear inset from the screen edges.
 */
@property (nonatomic) CGFloat backgroundScale;

/**
 *  The background color of the screen while image is being viewed. Default is black.
 */
@property (nonatomic, strong) UIColor *backgroundColor;

/**
 *  The title label, to be customized after creation
 */
@property (strong, nonatomic) UILabel *titleLabel;

@property (atomic, readonly) BOOL isClosing;


+ (instancetype)showImageFrom:(UIImageView *)imageView title:(NSString *)title;
+ (instancetype)showImageFrom:(UIImageView *)imageView;
+ (instancetype)newViewerFor:(UIImageView *)imageView;

- (void)show;
- (void)close;

@end
