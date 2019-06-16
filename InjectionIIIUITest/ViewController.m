//
//  ViewController.m
//  InjectionIIIUITest
//
//  Created by wx on 2019/6/14.
//  Copyright © 2019 Siri. All rights reserved.
//

#import "ViewController.h"
#import "MainViewController.h"
#import "Masonry/Masonry.h"
#import "PublicLibrary.h"

@interface ViewController () <MainClickDelegate>
@property (nonatomic ,strong) UILabel *titleLabel;
@property (nonatomic ,strong) UIButton *pushButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    self.titleLabel.text = @"测试";
    self.titleLabel.textColor = [UIColor redColor];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    [self.pushButton setTitle:@"push" forState:UIControlStateNormal];
    [self.pushButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(50);
        make.centerX.equalTo(self.titleLabel);
    }];
    
    
}

// 热加载 是调用该函数
- (void)injected {
    NSLog(@"执行：%s",__func__);
    [self viewDidLoad];
}

- (void)pushButtonClick {
    
    MainViewController *main = [[MainViewController alloc] init];
//    main.delegate = self;
    
//    main.callBack = ^{
//        self.view.backgroundColor = [UIColor yellowColor];
//    };
    
//    main.selectBlock = ^NSInteger(NSString * _Nonnull str) {
//        return str.integerValue;
//    };
    [self.navigationController pushViewController:main animated:YES];
    
//    [self.pushButton removeFromSuperview];
//    self.pushButton = nil;
}


-(void)back{
    NSLog(@"收到了。。。");
}

-(UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor redColor];
        [self.view addSubview:_titleLabel];
    }
    return _titleLabel;
}

-(UIButton *)pushButton{
    if (!_pushButton) {
        UIButton *pushButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [pushButton setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
        [pushButton addTarget:self action:@selector(pushButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _pushButton = pushButton;
        [self.view addSubview:pushButton];
    }
    return _pushButton;
}


@end
