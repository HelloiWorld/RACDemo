//
//  LoginViewModel.h
//  RACDemo
//
//  Created by PengZK on 2018/2/4.
//  Copyright © 2018年 PZK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa.h>

@interface LoginViewModel : NSObject

@property (nonatomic, copy) NSString *phoneNum;
@property (nonatomic, copy) NSString *verifyCodeNum;
@property (nonatomic, assign) BOOL isUserProtocolChecked;

- (RACCommand *)loginCommand;

@end
