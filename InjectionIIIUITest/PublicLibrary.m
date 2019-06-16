//
//  PublicLibrary.m
//  InjectionIIIUITest
//
//  Created by Siri on 2019/6/16.
//  Copyright © 2019年 Siri. All rights reserved.
//

#import "PublicLibrary.h"

@implementation PublicLibrary

static PublicLibrary *_library;

+ (instancetype)shareManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _library = [[PublicLibrary alloc] init];
    });
    return _library;

}

@end
