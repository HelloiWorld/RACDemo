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

@property (nonatomic, copy, readonly) NSString *phoneNum;
@property (nonatomic, copy, readonly) NSString *verifyCodeNum;
@property (nonatomic, assign, readonly) BOOL isUserProtocolChecked;
@property (nonatomic, assign, readonly) NSTimeInterval remainTime;

@property (nonatomic, strong, readonly) RACSignal *validUsernameSignal;
@property (nonatomic, strong, readonly) RACSignal *validPasswordSignal;
@property (nonatomic, strong, readonly) RACSignal *signUpActiveSignal;

@property (nonatomic, strong, readonly) RACCommand* sendSMSCodeCommand;
@property (nonatomic, strong, readonly) RACCommand* protocolCheckedCommand;
@property (nonatomic, strong, readonly) RACSignal* signInSignal;

@end
