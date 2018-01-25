//
//  ViewController.m
//  RACDemo
//
//  Created by PengZK on 2017/7/10.
//  Copyright © 2017年 ZTC. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveCocoa.h>

static NSInteger numberLimit = 60;

@interface ViewController ()<UITextFieldDelegate>

#pragma mark- outlet
@property (weak, nonatomic) IBOutlet UITextField *phoneTextFiled;
@property (weak, nonatomic) IBOutlet UITextField *verifyCodeTextFiled;

@property (weak, nonatomic) IBOutlet UIButton *enterBtn;
@property (weak, nonatomic) IBOutlet UIButton *countDownBtn;
@property (weak, nonatomic) IBOutlet UIButton *protocolCheckBtn;
@property (weak, nonatomic) IBOutlet UIButton *protocolDetailBtn;
@property (assign, nonatomic) BOOL isUserProtocolChecked;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self bindViewModel];
}

- (void)bindViewModel {
    RACSignal *validUsernameSignal = [self.phoneTextFiled.rac_textSignal map:^id(NSString *text) {
        return @([self isMobileNumberValid:text]);
    }];
    RACSignal *validPasswordSignal = [self.verifyCodeTextFiled.rac_textSignal map:^id(NSString *text) {
        return @([self isSmsCodeValid:text]);
    }];
    
    RAC(self.phoneTextFiled, textColor) =
    [validUsernameSignal map:^id(NSNumber *usernameValid){
        return[usernameValid boolValue] ? [UIColor blackColor]:[UIColor redColor];
    }];
    RAC(self.verifyCodeTextFiled, textColor) =
    [validPasswordSignal map:^id(NSNumber *passwordValid){
        return[passwordValid boolValue] ? [UIColor blackColor]:[UIColor redColor];
    }];
    
    @weakify(self);
    RACSignal *signUpActiveSignal =
    [RACSignal combineLatest:@[validUsernameSignal, validPasswordSignal]
                      reduce:^id(NSNumber*usernameValid, NSNumber *passwordValid){
                          return @([usernameValid boolValue]&&[passwordValid boolValue]);
                      }];
    [signUpActiveSignal subscribeNext:^(NSNumber*signupActive) {
        @strongify(self);
        self.enterBtn.enabled = [signupActive boolValue];
        self.enterBtn.backgroundColor = [signupActive boolValue] ? [UIColor blueColor]:[UIColor grayColor];
    }];
    
    // 点击登录
    [[[[[self.enterBtn rac_signalForControlEvents:UIControlEventTouchUpInside]
       filter:^BOOL(id value) {
        @strongify(self);
        if (self.isUserProtocolChecked == NO) {
            NSLog(@"请先阅读并同意用户协议");
        }
        return self.isUserProtocolChecked;
    }] doNext:^(id x) {
        @strongify(self);
        self.enterBtn.enabled = NO;
    }] flattenMap:^RACStream *(id value) {
        @strongify(self);
        return[self signInSignal];
    }] subscribeNext:^(NSNumber*signedIn){
        @strongify(self);
        self.enterBtn.enabled = YES;
        BOOL success = [signedIn boolValue];
        if(success){
            NSLog(@"success");
            //跳转
        }
    }];
    
    // 点击开始倒计时
    __block NSInteger number = numberLimit;
    
    RACSignal *timeSignal = [[[[[RACSignal interval:1.0f onScheduler:[RACScheduler mainThreadScheduler]] take:numberLimit] startWith:@(number)] doNext:^(NSDate *date) {
        @strongify(self);
        if (number == 0) {
            [self.countDownBtn setTitle:@"重新发送" forState:UIControlStateNormal];
            [self.countDownBtn setTitle:@"重新发送" forState:UIControlStateDisabled];
            self.countDownBtn.enabled = YES;
        }
        else{
            [self.countDownBtn setTitle:[NSString stringWithFormat:@"%ld", (long)number--] forState:UIControlStateDisabled];
            self.countDownBtn.enabled = NO;// 倒计时期间不可点击
        }
    }] takeUntil:self.rac_willDeallocSignal];
    
    self.countDownBtn.rac_command = [[RACCommand alloc] initWithEnabled:validUsernameSignal signalBlock:^RACSignal *(id input) {
        number = numberLimit;
        return timeSignal;
    }];
    
    // 点击同意/不同意协议
    [[self.protocolCheckBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        @strongify(self);
        self.isUserProtocolChecked = !self.isUserProtocolChecked;
        if (_isUserProtocolChecked == true) {
            UIImage *checkedImg = [UIImage imageNamed: @"同意协议"];
            [_protocolCheckBtn setImage: checkedImg forState: UIControlStateNormal];
        }else{
            UIImage *unCheckImg = [UIImage imageNamed: @"不同意协议"];
            [_protocolCheckBtn setImage: unCheckImg forState: UIControlStateNormal];
        }
    }];
}

- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber){
        [self
         signInWithUsername:self.phoneTextFiled.text
         password:self.verifyCodeTextFiled.text
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
    //调接口，适合放VM里面
    completeBlock(YES);
}


#define MOBILE_NUM_REGEX @"^1(3[0-9]|4[57]|5[0-35-9]|7[0135678]|8[0-9])\\d{8}$"
- (BOOL)isMobileNumberValid:(NSString *)mobileNum{
    if (!mobileNum || [mobileNum isEqualToString: @""]) {
        return NO;
    }
    NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE_NUM_REGEX];
    return [regextest evaluateWithObject: mobileNum];
}

#define SMS_CODE_REGEX @"^\\d{4}$" //4位数字验证码
- (BOOL)isSmsCodeValid:(NSString *)smsCode{
    if (!smsCode || [smsCode isEqualToString: @""]) {
        return NO;
    }
    NSPredicate *regextest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", SMS_CODE_REGEX];
    return [regextest evaluateWithObject: smsCode];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [_phoneTextFiled resignFirstResponder];
    [_verifyCodeTextFiled resignFirstResponder];
}


#pragma mark- uitextfileddelegate
#pragma mark - 限制输入位数
#define NUM @"0123456789"
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (textField == self.phoneTextFiled) {
        NSString * toBeString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if (toBeString.length > 11) {
            textField.text = [textField.text substringToIndex:11];
            return NO;
        }
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:NUM] invertedSet];
        NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        BOOL basicTest = [string isEqualToString:filtered];
        if(!basicTest)
        {
            return NO;
        }
    } else if (textField == self.verifyCodeTextFiled) {
        NSString * toBeString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if (toBeString.length > 4) {
            textField.text = [textField.text substringToIndex:4];
            return NO;
        }
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:NUM] invertedSet];
        NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        BOOL basicTest = [string isEqualToString:filtered];
        if(!basicTest)
        {
            return NO;
        }
    }
    return YES;
}

@end
