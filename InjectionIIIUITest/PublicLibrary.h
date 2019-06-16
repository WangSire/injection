//
//  PublicLibrary.h
//  InjectionIIIUITest
//
//  Created by Siri on 2019/6/16.
//  Copyright © 2019年 Siri. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PublicLibrary : NSObject
+ (instancetype)shareManager;
@property (nonatomic ,copy)NSString *name;
@end

NS_ASSUME_NONNULL_END
