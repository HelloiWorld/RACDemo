# 用RAC的思想替换Objc代码

比如objc有这样一段代码，用来限制输入UITextField只允许输入数字，并限制位数

    #pragma mark- UITextfieldDelegate
    #pragma mark - 限制输入位数
    #define NUM @"0123456789"
    - (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    if (textField == self.phoneTextField) {
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
    }
    return YES;
    }
    
 换成rac可以这样写
 
    //限制输入数字和长度
    [self.phoneTextField.rac_textSignal subscribeNext:^(NSString *x) {
        NSLog(@"phone number: %@", x);
        @strongify(self);
        static NSInteger const maxIntegerLength = 11;//最大手机号位数
        if (x.length > maxIntegerLength) {
            x = [x substringToIndex:maxIntegerLength];
        }
        NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:NUM] invertedSet];
        NSString *filtered = [[x componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        self.phoneTextField.text = filtered;
    }];


oc中根据多个条件动态改变按钮的状态是很麻烦的事，常常要使用KVO，而使用rac组合信号可以轻松搞定

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
    
移除oc中的action事件绑定

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
    
倒计时无需再使用`NSTimer`以及`dispatch_source_set_timer`

    //点击开始倒计时，手机号校验合法才允许点击
    self.countDownBtn.rac_command = [[RACCommand alloc] initWithEnabled:validUsernameSignal signalBlock:^RACSignal *(id input) {
        @strongify(self);
        self.remainTime = timeLimit;
        return [self timeSignal];
    }];
    
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
    
