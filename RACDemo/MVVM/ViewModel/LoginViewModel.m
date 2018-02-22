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

@property (nonatomic, copy) NSString *phoneNum;
@property (nonatomic, copy) NSString *verifyCodeNum;
@property (nonatomic, assign) BOOL isUserProtocolChecked;
@property (nonatomic, assign) NSTimeInterval remainTime;

@property (nonatomic, strong) RACSignal *validUsernameSignal;
@property (nonatomic, strong) RACSignal *validPasswordSignal;
@property (nonatomic, strong) RACSignal *signUpActiveSignal;

@property (nonatomic, strong) RACCommand* sendSMSCodeCommand;
@property (nonatomic, strong) RACCommand* protocolCheckedCommand;
@property (nonatomic, strong) RACSignal* signInSignal;

@end

@implementation LoginViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialBind];
        [self initData];
    }
    return self;
}

// 初始化绑定
- (void)initialBind
{
    // 监听账号的属性值改变，把他们聚合成一个信号。
    //设置字符串正则校验
    self.validUsernameSignal =
    [RACObserve(self, phoneNum) map:^id(NSString *text) {
        return @([Util isMobileNumberValid:text]);
    }];
    self.validPasswordSignal =
    [RACObserve(self, verifyCodeNum) map:^id(NSString *text) {
        return @([Util isSmsCodeValid:text]);
    }];
    
    //绑定多个信号，设置登录按钮状态
    self.signUpActiveSignal =
    [RACSignal combineLatest:@[self.validUsernameSignal, self.validPasswordSignal]
                      reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid){
                          return @([usernameValid boolValue] && [passwordValid boolValue]);
                      }];
}

- (void)initData {
    self.remainTime = -1;
}

#pragma mark - Getter
static NSInteger const timeMaxLimit = 10;
-(RACCommand *)sendSMSCodeCommand {
    if (nil == _sendSMSCodeCommand) {
        @weakify(self);
        _sendSMSCodeCommand = [[RACCommand alloc] initWithEnabled:self.validUsernameSignal signalBlock:^RACSignal *(id input) {
            @strongify(self);
            self.remainTime = timeMaxLimit;
            return [self timeSignal];
        }];
    }
    return _sendSMSCodeCommand;
}

#warning 思考：为什么这里的写法不需要startWith立即执行呢？
- (RACSignal *)timeSignal {
    // startWith:[NSDate date]] 如果加上startWith它会立即再执行一次，跳过timeMaxLimit这次的情况
    // startWith:[NSDate date]] deley:1] 也可以让它延时1s，这样也不会有问题
    return [[[[RACSignal interval:1.0f onScheduler:[RACScheduler mainThreadScheduler]] take:timeMaxLimit] doNext:^(NSDate *date) {
        self.remainTime --;
    }] takeUntil:self.rac_willDeallocSignal];
}

- (RACCommand *)protocolCheckedCommand {
    @weakify(self);
    return [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        self.isUserProtocolChecked = !self.isUserProtocolChecked;
        return [RACSignal empty];
    }];
}

//- (RACCommand *)loginCommand {
//    if (nil == _loginCommand) {
//        @weakify(self);
//        _loginCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
//            return [self signInSignal];
//        }];
//    }
//    return _loginCommand;
//}

- (RACSignal *)signInSignal {
    if (!_signInSignal) {
        _signInSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber){
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
    return _signInSignal;
}

#pragma mark - Network
typedef void (^RWSignInResponse)(NSError *error, id result);
- (void)signInWithUsername:(NSString *)username
                  password:(NSString *)password
                  complete:(RWSignInResponse)completeBlock {
    // 模仿网络延迟
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completeBlock(nil, @YES);
    });
}

@end
