//
//  ViewController.m
//  RACDemo
//
//  Created by PengZK on 2017/7/10.
//  Copyright © 2017年 PZK. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>
#import <UIView+Toast.h>
#import "Util.h"
#import "NSString+Util.h"

@interface ViewController ()<UITextFieldDelegate>

#pragma mark- outlet
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UITextField *verifyCodeTextField;
@property (weak, nonatomic) IBOutlet UIButton *enterBtn;
@property (weak, nonatomic) IBOutlet UIButton *countDownBtn;
@property (weak, nonatomic) IBOutlet UIButton *protocolCheckBtn;

@property (nonatomic, assign) __block NSTimeInterval remainTime;
@property (assign, nonatomic) BOOL isUserProtocolChecked;

@end

static NSInteger const timeLimit = 10;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setBtnStatus];
    [self bind];
}

- (void)setBtnStatus {
    [self.countDownBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.countDownBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
}

- (void)bind {
    @weakify(self);
    
    //限制输入数字和长度
    [self.phoneTextField.rac_textSignal subscribeNext:^(NSString *x) {
        NSLog(@"phone number: %@", x);
        @strongify(self);
        static NSInteger const maxIntegerLength = 11;//最大手机号位数
        if (x.length > maxIntegerLength) {
            x = [x substringToIndex:maxIntegerLength];
        }
        self.phoneTextField.text = [x getPureDigitalString];
    }];
    [self.verifyCodeTextField.rac_textSignal subscribeNext:^(NSString *x) {
        NSLog(@"verify code: %@", x);
        @strongify(self);
        static NSInteger const maxIntegerLength = 4;//最大验证码位数
        if (x.length > maxIntegerLength) {
            x = [x substringToIndex:maxIntegerLength];
        }
        self.verifyCodeTextField.text = [x getPureDigitalString];
    }];
    
    //设置字符串正则校验
    RACSignal *validUsernameSignal =
    [self.phoneTextField.rac_textSignal map:^id(NSString *text) {
        return @([Util isMobileNumberValid:text]);
    }];
    RACSignal *validPasswordSignal =
     [self.verifyCodeTextField.rac_textSignal map:^id(NSString *text) {
        return @([Util isSmsCodeValid:text]);
    }];
    
    //设置校验成功/失败状态文字颜色
    RAC(self.phoneTextField, textColor) =
    [validUsernameSignal map:^id(NSNumber *usernameValid){
        return [usernameValid boolValue] ? [UIColor blackColor] : [UIColor redColor];
    }];
    RAC(self.verifyCodeTextField, textColor) =
    [validPasswordSignal map:^id(NSNumber *passwordValid){
        return [passwordValid boolValue] ? [UIColor blackColor] : [UIColor redColor];
    }];
    
    //绑定多个信号，设置登录按钮状态
    RACSignal *signUpActiveSignal =
    [RACSignal combineLatest:@[validUsernameSignal, validPasswordSignal]
                      reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid){
                          return @([usernameValid boolValue] && [passwordValid boolValue]);
                      }];
    [signUpActiveSignal subscribeNext:^(NSNumber*signupActive) {
        @strongify(self);
        self.enterBtn.enabled = [signupActive boolValue];
        self.enterBtn.backgroundColor = [signupActive boolValue] ? [UIColor blueColor] : [UIColor grayColor];
    }];
    
    //点击同意/不同意协议
    [[self.protocolCheckBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        self.isUserProtocolChecked = !self.isUserProtocolChecked;
    }];
    [RACObserve(self, isUserProtocolChecked) subscribeNext:^(NSNumber *x) {
        UIImage *image = [x boolValue] ? [UIImage imageNamed: @"同意协议"] : [UIImage imageNamed: @"不同意协议"];
        [self.protocolCheckBtn setImage:image forState:UIControlStateNormal];
    }];
    
    //点击登录
    [[[[[self.enterBtn rac_signalForControlEvents:UIControlEventTouchUpInside] 
        filter:^BOOL(id value) {
        @strongify(self);
        if (self.isUserProtocolChecked == NO) {
            [self.view makeToast:@"请先阅读并同意用户协议" duration:2.0 position:CSToastPositionCenter];
        }
        return self.isUserProtocolChecked;
    }] doNext:^(id x) {
        @strongify(self);
        self.enterBtn.enabled = NO;
    }] flattenMap:^RACStream *(id value) {
        @strongify(self);
        return [self signInSignal];
    }] subscribeNext:^(NSNumber *signedIn){
        @strongify(self);
        self.enterBtn.enabled = YES;
        BOOL success = [signedIn boolValue];
        if (success) {
            [self performSegueWithIdentifier:@"loginSuccess" sender:self];
        }
    }];
    
    //点击开始倒计时，手机号校验合法才允许点击
    self.countDownBtn.rac_command = [[RACCommand alloc] initWithEnabled:validUsernameSignal signalBlock:^RACSignal *(id input) {
        @strongify(self);
        self.remainTime = timeLimit;
        return [self timeSignal];
    }];
}

- (RACSignal *)timeSignal {
    @weakify(self);
    return [[[[[RACSignal interval:1.0f onScheduler:[RACScheduler mainThreadScheduler]] take:timeLimit] startWith:[NSDate date]] doNext:^(NSDate *date) {
        @strongify(self);
        if (self.remainTime == 0) {
            [self.countDownBtn setTitle:@"重新发送" forState:UIControlStateNormal];
            [self.countDownBtn setTitle:@"重新发送" forState:UIControlStateDisabled];
            self.countDownBtn.enabled = YES;
        } else {
            [self.countDownBtn setTitle:[NSString stringWithFormat:@"%ld", (long)self.remainTime--] forState:UIControlStateDisabled];
            self.countDownBtn.enabled = NO;// 倒计时期间不可点击
        }
    }] takeUntil:self.rac_willDeallocSignal];
}

- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber){
        [self signInWithUsername:self.phoneTextField.text
                        password:self.verifyCodeTextField.text
                        complete:^(BOOL success){
                            [subscriber sendNext:@(success)];
                            [subscriber sendCompleted];
                        }];
        return nil;
    }];
}

typedef void (^RWSignInResponse)(BOOL);
- (void)signInWithUsername:(NSString *)username
                  password:(NSString *)password
                  complete:(RWSignInResponse)completeBlock {
    //调接口
    completeBlock(YES);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_phoneTextField resignFirstResponder];
    [_verifyCodeTextField resignFirstResponder];
}

@end
