//
//  MainViewController.m
//  InjectionIIIUITest
//
//  Created by wx on 2019/6/14.
//  Copyright © 2019 Siri. All rights reserved.
//

#import "MainViewController.h"
#import "Masonry/Masonry.h"

@interface MainViewController ()
@property (nonatomic ,strong) UILabel *tipLabel;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tipLabel.text = @"这是个什么👻";
    self.tipLabel.textColor = [UIColor redColor];
    [self.tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
//    [self setupLabelText:@"嗷呜。。。"];
}

-(void)dealloc{
    NSLog(@"MainViewController 释放了");
}

- (void)injected {
    NSLog(@"执行：%s",__func__);
    [self viewDidLoad];
}

-(UILabel *)tipLabel{
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = [UIColor redColor];
        [self.view addSubview:_tipLabel];
    }
    return _tipLabel;
}

- (void)setupLabelText:(NSString *)text {
    self.tipLabel.text = text;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
//    !self.callBack?:self.callBack();
    //    [self.delegate back];

//    if (self.selectBlock) {
//        NSLog(@"收到了: %ld",(long)self.selectBlock(@"测试"));
//    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
