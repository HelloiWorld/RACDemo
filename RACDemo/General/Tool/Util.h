//
//  Util.h
//  RACDemo
//
//  Created by PengZK on 2018/2/6.
//  Copyright © 2018年 PZK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Util : NSObject

/**
 手机号正则校验
 
 @param mobileNum 手机号
 @return YES:合法 NO:不合法
 */
+ (BOOL)isMobileNumberValid:(NSString *)mobileNum;


/**
 4位短信验证码校验
 
 @param smsCode 数字验证码
 @return YES:合法 NO:不合法
 */
+ (BOOL)isSmsCodeValid:(NSString *)smsCode;


/**
 校验该字符是否是纯数字
 
 @param string 字符串
 @return YES:合法 NO:不合法
 */
+ (BOOL)isPureDigitalValid:(NSString*)string;


/**
 是否是允许的文本：只允许输入中文、字母或数字
 
 @param inputText 输入文本
 @return YES:合法 NO:不合法
 */
+ (BOOL)isInputableTextValid:(NSString *)inputText;

@end
