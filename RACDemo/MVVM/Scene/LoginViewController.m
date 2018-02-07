//
//  LoginViewController.m
//  RACDemo
//
//  Created by PengZK on 2018/2/4.
//  Copyright © 2018年 PZK. All rights reserved.
//

#import "LoginViewController.h"
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
    //手机号
    RAC(self.loginViewModel, phoneNum) = self.phoneTextField.rac_textSignal;
    //验证码
    RAC(self.loginViewModel, verifyCodeNum) = self.verifyCodeTextField.rac_textSignal;
    //用户协议
    RAC(self.loginViewModel, isUserProtocolChecked) = [self.enterBtn rac_signalForControlEvents:UIControlEventTouchUpInside];
    
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
