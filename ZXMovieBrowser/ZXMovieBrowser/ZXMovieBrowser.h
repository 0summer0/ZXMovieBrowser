//
//  ZXMovieBrowser.h
//  ZXMovieBrowser
//
//  Created by Shawn on 16/6/21.
//  Copyright © 2016年 Shawn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZXMovie.h"

#define kMovieBrowserHeight 125.0

@class ZXMovieBrowser;
@protocol ZXMovieBrowserDelegate <NSObject>

@optional
- (void)movieBrowser:(ZXMovieBrowser *)movieBrowser didSelectItemAtIndex:(NSInteger)index;
- (void)movieBrowser:(ZXMovieBrowser *)movieBrowser didEndScrollingAtIndex:(NSInteger)index;
- (void)movieBrowser:(ZXMovieBrowser *)movieBrowser didChangeItemAtIndex:(NSInteger)index;

@end

@interface ZXMovieBrowser : UIView

@property (nonatomic, assign, readwrite) id<ZXMovieBrowserDelegate> delegate;
@property (nonatomic, assign, readonly)  NSInteger currentIndex;

- (instancetype)initWithFrame:(CGRect)frame movies:(NSArray *)movies;
- (instancetype)initWithFrame:(CGRect)frame movies:(NSArray *)movies currentIndex:(NSInteger)index;
- (void)setCurrentMovieIndex:(NSInteger)index;

@end
