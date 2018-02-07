//
//  NSString+Util.m
//  RACDemo
//
//  Created by PengZK on 2018/2/7.
//  Copyright © 2018年 PZK. All rights reserved.
//

#import "NSString+Util.h"

@implementation NSString (Util)

#define PureDigital_REGEX @"0123456789"
- (NSString*)getPureDigitalString {
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:PureDigital_REGEX] invertedSet];
    NSString *filtered = [[self componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    return filtered;
}

@end
