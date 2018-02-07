//
//  Util.m
//  RACDemo
//
//  Created by PengZK on 2018/2/6.
//  Copyright © 2018年 PZK. All rights reserved.
//

#import "Util.h"

#define MOBILE_NUM_REGEX @"^1(2[0-9]|3[0-9]|4[57]|5[0-35-9]|7[0135678]|8[0-9])\\d{8}$"
#define SMS_CODE_REGEX @"^\\d{4}$" //4位数字验证码
#define PureDigital_REGEX @"0123456789"
#define InputableTextField_REGEX @"^[a-zA-Z\u4e00-\u9fa5][a-zA-Z0-9\u4e00-\u9fa5]+$"

@implementation Util

+ (BOOL)isMobileNumberValid:(NSString *)mobileNum{
    if (!mobileNum || [mobileNum isEqualToString: @""]) {
        return NO;
    }
    NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE_NUM_REGEX];
    return [regextest evaluateWithObject: mobileNum];
}

+ (BOOL)isSmsCodeValid:(NSString *)smsCode{
    if (!smsCode || [smsCode isEqualToString: @""]) {
        return NO;
    }
    NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", SMS_CODE_REGEX];
    return [regextest evaluateWithObject: smsCode];
}

+ (BOOL)isPureDigitalValid:(NSString*)string{
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:PureDigital_REGEX] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    BOOL basicTest = [string isEqualToString:filtered];
    return basicTest;
}

+ (BOOL)isInputableTextValid:(NSString *)inputText{
    if (!inputText || [inputText isEqualToString: @""]) {
        return NO;
    }
    NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", InputableTextField_REGEX];
    return [regextest evaluateWithObject: inputText];
}

@end
