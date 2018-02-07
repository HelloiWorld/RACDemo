//
//  LoginViewModel.m
//  RACDemo
//
//  Created by PengZK on 2018/2/4.
//  Copyright © 2018年 PZK. All rights reserved.
//

#import "LoginViewModel.h"
#import "Util.h"

@interface LoginViewModel ()

@end

@implementation LoginViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self bindModel];
    }
    return self;
}

// 初始化绑定
- (void)initialBind
{
    // 监听账号的属性值改变，把他们聚合成一个信号。
//    _enableLoginSignal = [RACSignal combineLatest:@[RACObserve(self.account, account),RACObserve(self.account, pwd)] reduce:^id(NSString *account,NSString *pwd){
//
//        return @(account.length && pwd.length);
//
//    }];
    
}

// 视图模型绑定
- (void)bindModel
{
    // 给模型的属性绑定信号
    // 只要账号文本框一改变，就会给account赋值
//    RAC(self.account, account) = self.loginView..rac_textSignal;
//    RAC(self.loginViewModel.account, pwd) = _pwdField.rac_textSignal;
//
//    // 绑定登录按钮
//    RAC(self.loginBtn,enabled) = self.loginViewModel.enableLoginSignal;
//
//    // 监听登录按钮点击
//    [[_loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//
//        // 执行登录事件
//        [self.loginViewModel.LoginCommand execute:nil];
//    }];
}

- (RACCommand *)loginCommand {
    return [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        return [[self signInSignal] doNext:^(id x) {
            //执行Next之前，会先执行这个Block
        }];
    }];
}

- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber){
        [self signInWithUsername:self.phoneNum
                        password:self.verifyCodeNum
                        complete:^(NSError *error, id result){
             if (!error) {
                 [subscriber sendNext:result];
                 [subscriber sendCompleted];
             } else {
                 [subscriber sendError:error];
             }
         }];
        return nil;
    }];
}

typedef void (^RWSignInResponse)(NSError *error, id result);

- (void)signInWithUsername:(NSString *)username
                  password:(NSString *)password
                  complete:(RWSignInResponse)completeBlock {
    //调接口，适合放VM里面
    completeBlock(nil, nil);
}

@end
