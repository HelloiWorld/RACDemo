//
//  LoginViewController.m
//  RACDemo
//
//  Created by PengZK on 2018/2/4.
//  Copyright © 2018年 PZK. All rights reserved.
//

#import "LoginViewController.h"
#import <UIView+Toast.h>
#import <SVProgressHUD.h>
#import "LoginViewModel.h"
#import "Util.h"
#import "NSString+Util.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UITextField *verifyCodeTextField;
@property (weak, nonatomic) IBOutlet UIButton *enterBtn;
@property (weak, nonatomic) IBOutlet UIButton *countDownBtn;
@property (weak, nonatomic) IBOutlet UIButton *protocolCheckBtn;

@property (nonatomic, strong) LoginViewModel *loginViewModel;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setBtnStatus];
    [self bindViewModel];
}

- (void)setBtnStatus {
    [self.countDownBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.countDownBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
}

#pragma mark - Getter
- (LoginViewModel *)loginViewModel
{
    if (_loginViewModel == nil) {
        _loginViewModel = [[LoginViewModel alloc] init];
    }
    return _loginViewModel;
}

#pragma mark - bind
- (void)bindViewModel{
    @weakify(self);
    
    //手机号
    // 这种写法可以监测因代码修改而导致的文本内容变化
    RAC(self.loginViewModel, phoneNum) = [RACObserve(self.phoneTextField, text) merge:self.phoneTextField.rac_textSignal];
    //验证码
    RAC(self.loginViewModel, verifyCodeNum) = [RACObserve(self.verifyCodeTextField, text) merge:self.verifyCodeTextField.rac_textSignal];
    //用户协议
    [[self.protocolCheckBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        [self.loginViewModel.protocolCheckedCommand execute:nil];
    }];
    // 按我的理解是与上面代码作用基本相同的
//    self.protocolCheckBtn.rac_command = self.loginViewModel.protocolCheckedCommand;
    [RACObserve(self, loginViewModel.isUserProtocolChecked) subscribeNext:^(NSNumber *x) {
        @strongify(self);
        UIImage *image = [x boolValue] ? [UIImage imageNamed: @"同意协议"] : [UIImage imageNamed: @"不同意协议"];
        [self.protocolCheckBtn setImage:image forState:UIControlStateNormal];
    }];
    
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
    
    //设置校验成功/失败状态文字颜色
    RAC(self.phoneTextField, textColor) =
    [self.loginViewModel.validUsernameSignal map:^id(NSNumber *usernameValid){
        return [usernameValid boolValue] ? [UIColor blackColor] : [UIColor redColor];
    }];
    RAC(self.verifyCodeTextField, textColor) =
    [self.loginViewModel.validPasswordSignal map:^id(NSNumber *passwordValid){
        return [passwordValid boolValue] ? [UIColor blackColor] : [UIColor redColor];
    }];
//    RAC(self.enterBtn, enabled) = self.loginViewModel.signUpActiveSignal;
    [self.loginViewModel.signUpActiveSignal subscribeNext:^(NSNumber *x) {
        self.enterBtn.enabled = [x boolValue];
        self.enterBtn.backgroundColor = [x boolValue] ? [UIColor blueColor] : [UIColor grayColor];
    }];

    //点击登录
    [[[[[self.enterBtn rac_signalForControlEvents:UIControlEventTouchUpInside]
        filter:^BOOL(id value) {
            @strongify(self);
            if (self.loginViewModel.isUserProtocolChecked == NO) {
                [self.view makeToast:@"请先阅读并同意用户协议" duration:2.0 position:CSToastPositionCenter];
            }
            return self.loginViewModel.isUserProtocolChecked;
        }] doNext:^(id x) {
            @strongify(self);
            self.enterBtn.enabled = NO;
            [SVProgressHUD show];
        }] flattenMap:^RACStream *(id value) {
            return self.loginViewModel.signInSignal;
        }] subscribeNext:^(NSNumber *signedIn){
            @strongify(self);
            self.enterBtn.enabled = YES;
            [SVProgressHUD dismiss];
            BOOL success = [signedIn boolValue];
            if (success) {
                [SVProgressHUD showSuccessWithStatus:@"登录成功"];
                [self performSegueWithIdentifier:@"loginSuccess" sender:self];
            }
        }];
    //以下写法无法在调用网络前做一些额外的操作
//    self.enterBtn.rac_command = self.loginViewModel.loginCommand;
//    [self.enterBtn.rac_command.executionSignals.switchToLatest subscribeNext:^(NSNumber *signedIn) {
//        @strongify(self);
//        self.enterBtn.enabled = YES;
//        [SVProgressHUD dismiss];
//        BOOL success = [signedIn boolValue];
//        if (success) {
//            [SVProgressHUD showSuccessWithStatus:@"登录成功"];
//            [self performSegueWithIdentifier:@"loginSuccess" sender:self];
//        }
//    }];

    //点击开始倒计时，手机号校验合法才允许点击
    self.countDownBtn.rac_command = self.loginViewModel.sendSMSCodeCommand;
    [[RACObserve(self.loginViewModel, remainTime) filter:^BOOL(NSNumber *value) {
        return [value integerValue] >= 0;
    }] subscribeNext:^(NSNumber *x) {
        NSLog(@"倒计时: %ld", [x integerValue]);
        @strongify(self);
        if ([x integerValue] == 0) {
            [self.countDownBtn setTitle:@"重新发送" forState:UIControlStateNormal];
            [self.countDownBtn setTitle:@"重新发送" forState:UIControlStateDisabled];
//            self.countDownBtn.enabled = YES;
        } else {
            [self.countDownBtn setTitle:[NSString stringWithFormat:@"%ld", [x integerValue]] forState:UIControlStateDisabled];
//            self.countDownBtn.enabled = NO;// 倒计时期间不可点击
        }
    }];
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
