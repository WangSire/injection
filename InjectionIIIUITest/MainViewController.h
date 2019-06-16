//
//  MainViewController.h
//  InjectionIIIUITest
//
//  Created by wx on 2019/6/14.
//  Copyright © 2019 Siri. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MainClickDelegate <NSObject>

- (void)back;

@end

@interface MainViewController : UIViewController
@property (nonatomic ,copy) void(^callBack)(void);
@property (nonatomic ,weak) id <MainClickDelegate> delegate;
@property (nonatomic ,copy) NSInteger(^selectBlock)(NSString *str);
@end

NS_ASSUME_NONNULL_END
