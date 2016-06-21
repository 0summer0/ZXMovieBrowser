//
//  ViewController.m
//  ZXMovieBrowser
//
//  Created by Shawn on 16/6/21.
//  Copyright © 2016年 Shawn. All rights reserved.
//

#import "ViewController.h"
#import "ZXMovieBrowser.h"

#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController () <ZXMovieBrowserDelegate>

@property (nonatomic, strong, readwrite) ZXMovieBrowser *movieBrowser;
@property (nonatomic, strong, readwrite) UILabel *titileLabel;
@property (nonatomic, strong, readwrite) NSMutableArray *movies;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"朝阳剧场";
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    
    [self setupSubviews];
}

- (void)setupSubviews
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"movies" ofType:@"plist"];
    NSArray *dictArray = [NSArray arrayWithContentsOfFile:filePath];
    
    NSMutableArray *movies = [NSMutableArray array];
    for (NSDictionary *dict in dictArray) {
        ZXMovie *movie = [[ZXMovie alloc] init];
        movie.name = dict[@"name"];
        movie.coverUrl = dict[@"coverUrl"];
        [movies addObject:movie];
    }
    self.movies = movies;
    
    ZXMovieBrowser *movieBrowser = [[ZXMovieBrowser alloc] initWithFrame:CGRectMake(0, 200, kScreenWidth, kMovieBrowserHeight) movies:self.movies currentIndex:1];
    movieBrowser.delegate = self;
    [self.view addSubview:movieBrowser];
    self.movieBrowser = movieBrowser;
    
    UILabel *titileLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 330, kScreenWidth, 50)];
    titileLabel.textAlignment = NSTextAlignmentCenter;
    titileLabel.textColor = [UIColor blackColor];
    titileLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:titileLabel];
    self.titileLabel = titileLabel;
}

#pragma mark - ZXMovieBrowserDelegate

- (void)movieBrowser:(ZXMovieBrowser *)movieBrowser didSelectItemAtIndex:(NSInteger)index
{
    NSLog(@"跳转详情页---%@", ((ZXMovie *)self.movies[index]).name);
    
    UIViewController *movieDetailVc = [[UIViewController alloc] init];
    movieDetailVc.view.backgroundColor = [UIColor whiteColor];
    movieDetailVc.title = ((ZXMovie *)self.movies[index]).name;
    [self.navigationController pushViewController:movieDetailVc animated:YES];
}

- (void)movieBrowser:(ZXMovieBrowser *)movieBrowser didChangeItemAtIndex:(NSInteger)index
{
    NSLog(@"index: %ld", index);
    
    self.titileLabel.text = ((ZXMovie *)self.movies[index]).name;
}

static NSInteger _lastIndex = -1;
- (void)movieBrowser:(ZXMovieBrowser *)movieBrowser didEndScrollingAtIndex:(NSInteger)index
{
    if (_lastIndex != index) {
        NSLog(@"刷新---%@", ((ZXMovie *)self.movies[index]).name);
    }
    _lastIndex = index;
}

@end
