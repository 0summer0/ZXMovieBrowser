//
//  ZXMovieBrowser.m
//  ZXMovieBrowser
//
//  Created by Shawn on 16/6/21.
//  Copyright © 2016年 Shawn. All rights reserved.
//

#import "ZXMovieBrowser.h"
#import "UIImageView+WebCache.h"

#define kBaseTag 100
#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kItemSpacing 25.0
#define kItemWidth  60.0
#define kItemHeight 85.0
#define kItemSelectedWidth  75.0
#define kItemSelectedHeight 108.0
#define kScrollViewContentOffset (kScreenWidth / 2.0 - (kItemWidth / 2.0 + kItemSpacing))

@interface ZXMovieBrowser () <UIScrollViewDelegate>

@property (nonatomic, assign, readwrite) NSInteger      currentIndex;
@property (nonatomic, strong, readwrite) NSMutableArray *movies;
@property (nonatomic, strong, readwrite) NSMutableArray *items;
@property (nonatomic, assign, readwrite) CGPoint        scrollViewContentOffset;
@property (nonatomic, strong, readwrite) UIScrollView   *scrollView;
@property (nonatomic, strong, readwrite) UIImageView    *backgroundView;

@end

@implementation ZXMovieBrowser

- (instancetype)initWithFrame:(CGRect)frame movies:(NSArray *)movies
{
    self = [super initWithFrame:frame];
    if (self) {
        self.movies = [movies mutableCopy];
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame movies:(NSArray *)movies currentIndex:(NSInteger)index
{
    self = [super initWithFrame:frame];
    if (self) {
        self.movies = [movies mutableCopy];
        [self commonInit];
        [self setCurrentMovieIndex:index];
    }
    
    return self;
}

- (void)setCurrentMovieIndex:(NSInteger)index
{
    if (index >= 0 && index < self.movies.count) {
        self.currentIndex = index;
        CGPoint point = CGPointMake((kItemSpacing + kItemWidth) * index - kScrollViewContentOffset, 0);
        [self.scrollView setContentOffset:point animated:NO];
    }
}

#pragma mark - Setup

- (void)commonInit
{
    _backgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
    _backgroundView.contentMode = UIViewContentModeScaleToFill;
    _backgroundView.backgroundColor = [UIColor grayColor];
    [self addSubview:_backgroundView];
    if (self.movies.count > 0) {
        [_backgroundView sd_setImageWithURL:[NSURL URLWithString:((ZXMovie *)self.movies[0]).coverUrl]];
    }
    
    UIToolbar *blurView = [[UIToolbar alloc] initWithFrame:self.bounds];
    blurView.barStyle = UIBarStyleBlack;
    blurView.translucent = YES;
    [self addSubview:blurView];
    CALayer *extraColorLayer = [CALayer layer];
    extraColorLayer.frame = CGRectMake(0, 0, blurView.frame.size.width, blurView.frame.size.height);
    extraColorLayer.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4].CGColor;
    [blurView.layer addSublayer:extraColorLayer];
    
    [self setupScrollView];
}

- (void)setupScrollView
{
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    [self addSubview:_scrollView];
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    _scrollView.alwaysBounceHorizontal = YES;
    _scrollView.delegate = self;
    _scrollView.contentInset = UIEdgeInsetsMake(0, kScrollViewContentOffset, 0, kScrollViewContentOffset);
    _scrollView.contentSize = CGSizeMake((kItemWidth + kItemSpacing) * self.movies.count + kItemSpacing, kMovieBrowserHeight);
    
    NSInteger i = 0;
    _items = [NSMutableArray array];
    for (ZXMovie *movie in self.movies) {
        UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake((kItemSpacing + kItemWidth) * i + kItemSpacing, kMovieBrowserHeight - kItemHeight, kItemWidth, kItemHeight)];
        [_scrollView addSubview:itemView];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kItemWidth, kItemHeight)];
        imageView.backgroundColor = [UIColor purpleColor];
        imageView.layer.borderWidth = 1.0;
        [imageView sd_setImageWithURL:[NSURL URLWithString:movie.coverUrl]];
        imageView.userInteractionEnabled = YES;
        imageView.tag = i + kBaseTag;
        [itemView addSubview:imageView];
        [self.items addObject:imageView];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
        [imageView addGestureRecognizer:tapGesture];
        
        i++;
    }
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.movies.count != 0) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if ([self.delegate respondsToSelector:@selector(movieBrowser:didChangeItemAtIndex:)]) {
                [self.delegate movieBrowser:self didChangeItemAtIndex:self.currentIndex];
            }
            if ([self.delegate respondsToSelector:@selector(movieBrowser:didEndScrollingAtIndex:)]) {
                [self.delegate movieBrowser:self didEndScrollingAtIndex:self.currentIndex];
            }
        });
        [self adjustSubviews:self.scrollView];
    }
}

- (void)adjustSubviews:(UIScrollView *)scrollView
{
    NSInteger index = (scrollView.contentOffset.x + kScrollViewContentOffset) / (kItemWidth + kItemSpacing);
    index = MIN(self.movies.count - 1, MAX(0, index));
    
    CGFloat scale = (scrollView.contentOffset.x + kScrollViewContentOffset - (kItemWidth + kItemSpacing) * index) / (kItemWidth + kItemSpacing);
    if (self.movies.count > 0) {
        CGFloat height;
        CGFloat width;
        
        if (scale < 0.0) {
            scale = 1 - MIN(1.0, ABS(scale));
            
            UIImageView *leftView = self.items[index];
            leftView.layer.borderColor = [UIColor colorWithWhite:1 alpha:scale].CGColor;
            height = kItemHeight + (kItemSelectedHeight - kItemHeight) * scale;
            width = kItemWidth + (kItemSelectedWidth - kItemWidth) * scale;
            leftView.frame = CGRectMake(-(width - kItemWidth) / 2, -(height - kItemHeight), width, height);
            
            if (index + 1 < self.movies.count) {
                UIImageView *rightView = self.items[index + 1];
                rightView.frame = CGRectMake(0, 0, kItemWidth, kItemHeight);
                rightView.layer.borderColor = [UIColor clearColor].CGColor;
            }
            
        } else if (scale <= 1.0) {
            if (index + 1 >= self.movies.count) {
                
                scale = 1 - MIN(1.0, ABS(scale));
                
                UIImageView *imgView = self.items[self.movies.count - 1];
                imgView.layer.borderColor = [UIColor colorWithWhite:1 alpha:scale].CGColor;
                height = kItemHeight + (kItemSelectedHeight - kItemHeight) * scale;
                width = kItemWidth + (kItemSelectedWidth - kItemWidth) * scale;
                imgView.frame = CGRectMake(-(width - kItemWidth) / 2, -(height - kItemHeight), width, height);
                
            } else {
                CGFloat scaleLeft = 1 - MIN(1.0, ABS(scale));
                UIImageView *leftView = self.items[index];
                leftView.layer.borderColor = [UIColor colorWithWhite:1 alpha:scaleLeft].CGColor;
                height = kItemHeight + (kItemSelectedHeight - kItemHeight) * scaleLeft;
                width = kItemWidth + (kItemSelectedWidth - kItemWidth) * scaleLeft;
                leftView.frame = CGRectMake(-(width - kItemWidth) / 2, -(height - kItemHeight), width, height);
                
                CGFloat scaleRight = MIN(1.0, ABS(scale));
                UIImageView *rightView = self.items[index + 1];
                rightView.layer.borderColor = [UIColor colorWithWhite:1 alpha:scaleRight].CGColor;
                height = kItemHeight + (kItemSelectedHeight - kItemHeight) * scaleRight;
                width = kItemWidth + (kItemSelectedWidth - kItemWidth) * scaleRight;
                rightView.frame = CGRectMake(-(width - kItemWidth) / 2, -(height - kItemHeight), width, height);
            }
        }
        
        for (UIImageView *imgView in self.items) {
            if (imgView.tag != index + kBaseTag && imgView.tag != (index + kBaseTag + 1)) {
                imgView.frame = CGRectMake(0, 0, kItemWidth, kItemHeight);
                imgView.layer.borderColor = [UIColor clearColor].CGColor;
            }
        }
    }
}

#pragma mark - Tap Detection

- (void)tapDetected:(UITapGestureRecognizer *)tapGesture
{
    if (tapGesture.view.tag == self.currentIndex + kBaseTag) {
        if ([self.delegate respondsToSelector:@selector(movieBrowser:didSelectItemAtIndex:)]) {
            [self.delegate movieBrowser:self didSelectItemAtIndex:self.currentIndex];
            return;
        }
    }
    
    CGPoint point = [tapGesture.view.superview convertPoint:tapGesture.view.center toView:self.scrollView];
    point = CGPointMake(point.x - kScrollViewContentOffset - ((kItemWidth / 2 + kItemSpacing)), 0);
    self.scrollViewContentOffset = point;
    
    [self.scrollView setContentOffset:point animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger index = (scrollView.contentOffset.x + kScrollViewContentOffset + (kItemWidth / 2 + kItemSpacing / 2)) / (kItemWidth + kItemSpacing);
    index = MIN(self.movies.count - 1, MAX(0, index));
    
    if (self.currentIndex != index) {
        self.currentIndex = index;
    }
    
    [self adjustSubviews:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    NSInteger index = (targetContentOffset->x + kScrollViewContentOffset + (kItemWidth / 2 + kItemSpacing / 2)) / (kItemWidth + kItemSpacing);
    targetContentOffset->x = (kItemSpacing + kItemWidth) * index - kScrollViewContentOffset;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(movieBrowser:didEndScrollingAtIndex:)]) {
        [self.delegate movieBrowser:self didEndScrollingAtIndex: self.currentIndex];
    }
    
    if (self.currentIndex < self.movies.count) {
        [self.backgroundView sd_setImageWithURL:[NSURL URLWithString:((ZXMovie *)self.movies[self.currentIndex]).coverUrl]];
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.6f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [self.backgroundView.layer addAnimation:transition forKey:nil];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (!CGPointEqualToPoint(self.scrollViewContentOffset, self.scrollView.contentOffset)) {
        [self.scrollView setContentOffset:self.scrollViewContentOffset animated:YES];
    } else {
        if ([self.delegate respondsToSelector:@selector(movieBrowser:didEndScrollingAtIndex:)]) {
            [self.delegate movieBrowser:self didEndScrollingAtIndex:self.currentIndex];
        }
        
        [self.backgroundView sd_setImageWithURL:[NSURL URLWithString:((ZXMovie *)self.movies[self.currentIndex]).coverUrl]];
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.6f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        [self.backgroundView.layer addAnimation:transition forKey:nil];
    }
}

#pragma mark - setters

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    _currentIndex = currentIndex;
    
    if ([self.delegate respondsToSelector:@selector(movieBrowser:didChangeItemAtIndex:)]) {
        [self.delegate movieBrowser:self didChangeItemAtIndex:_currentIndex];
    }
}

@end
