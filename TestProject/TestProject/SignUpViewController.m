//
//  SignUpViewController.m
//  guessme
//
//  Created by Jonathan Xie on 4/1/15.
//  Copyright (c) 2015 Jonathan Xie. All rights reserved.
//


#import "SignUpViewController.h"


#import "RegExCategories.h"

#import "NBPhoneNumberUtil.h"
#import "NBAsYouTypeFormatter.h"


enum {
    PhoneNumberTextFieldTag = 0,
    EmailTextFieldTag,
    PasswordTextFieldTag
};

NSString *const kCountryCode = @"countryCode";
NSString *const kPhoneNumber = @"phoneNumber";


@interface SignUpViewController () <NBAsYouTypeFormatterDelegate>

@property BOOL phoneNumberHasError;
@property BOOL emailHasError;
@property BOOL passwordHasError;
@property UITextField* phoneNumberTextField;
@property UITextField* emailTextField;
@property UITextField* passwordTextField;

@end


@implementation SignUpViewController

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self){
        [self initializeForm];
    }
    return self;
}

- (void) initializeForm {
    
    // Boolean value errors to turn on or off the Sign Up Button
    self.phoneNumberHasError = false;

    
    XLFormDescriptor *form;
    XLFormSectionDescriptor *section;
    XLFormRowDescriptor *row;

    
    // Create form with title: Sign Up
    form = [XLFormDescriptor formDescriptorWithTitle:NSLocalizedString(@"Sign Up", nil)];
    
    section = [XLFormSectionDescriptor formSectionWithTitle:NSLocalizedString(@"Phone", nil)];
    [form addFormSection:section];

    
    NSString *countryDialingCode = @"+86";
    
    // Phone Number
    row = [XLFormRowDescriptor formRowDescriptorWithTag:kPhoneNumber
                                                rowType:XLFormRowDescriptorTypePhone
                                                  title:[NSString stringWithFormat:@"%@", countryDialingCode]];
    [row.cellConfigAtConfigure setObject:NSLocalizedString(@"Phone Number", nil) forKey:@"textField.placeholder"];
    
    [section addFormRow:row];
    
    
    UITableViewCell *phoneNumberCell = [row cellForFormController:self];
    phoneNumberCell.tag = PhoneNumberTextFieldTag;
    
    UITextField *phoneNumberTextField;
    // Find the phone number UITextField
    for (UIView *view in [[[phoneNumberCell subviews] objectAtIndex:0] subviews]) {
        //NSLog(@"View = %@", view);
        if ([view isMemberOfClass:[UITextField class]]) {
            phoneNumberTextField = ((UITextField *)view);
            self.phoneNumberTextField = phoneNumberTextField;
            //NSLog(@"phoneNumberTextField = %@", phoneNumberTextField);
        }
    }
    
    //NSLog(@"TF = %@", phoneNumberTextField);
    
    // Add an action to fire whenever the phone number text value changes
    [phoneNumberTextField addTarget:self
                             action:@selector(phoneNumberTextFieldDidChange:)
                   forControlEvents:UIControlEventEditingChanged];
    
    
    //NSLog(@"Phone Number Cell Tag = %lu", (long)phoneNumberCell.tag);
    
    
    
    
    // All form items have been setup so now set the self.form
    self.form = form;

}

- (void)reloadSignupXLForm {
    [self.tableView reloadData];
}

- (void)phoneNumberTextFieldDidChange:(UITextField *) textField {
    
    //NSLog(@"textField = %@", textField);
    
    NSString *phoneNumber = textField.text;

    NSMutableArray *digits = [NSMutableArray array];
    
    [phoneNumber enumerateSubstringsInRange: NSMakeRange(0, [phoneNumber length]) options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock: ^(NSString *inSubstring, NSRange inSubstringRange, NSRange inEnclosingRange, BOOL *outStop) {
                              
                              //NSLog(@"inSubtring = %@   - %@", inSubstring, [inSubstring isMatch:RX(@"^[0-9]$")] ? @"YES" : @"NO");
                              
                              if([inSubstring isMatch:RX(@"^[0-9]$")]) {
                                  //NSLog(@"substring: = %@", inSubstring);
                                  [digits addObject:inSubstring];
                              }
                              
                          }];
    
    
    NSString *countryCode = @"CN";

    NBAsYouTypeFormatter *phoneNumberFormatter = [[NBAsYouTypeFormatter alloc] initWithRegionCode:countryCode];
    [phoneNumberFormatter setDelegate:self];
    
    NSString *formattedNumber = phoneNumber;
    
    NSLog(@"formattedNumber = %@", formattedNumber);
    
    for (NSString *digit in digits) {
        formattedNumber = [phoneNumberFormatter inputDigit:digit];
        //NSLog(@"Formatted Number = %@", formattedNumber);
    }
    
    textField.text = formattedNumber;

    //NSLog(@"%@ = %@", phoneNumber, [digits componentsJoinedByString: @", "]);
    
    
}

- (void)formatter:(NBAsYouTypeFormatter *)formatter
     didFormatted:(BOOL)withResult {
    
    NSLog(@"didFormatted : %@", withResult ? @"YES":@"NO");
    
}

- (void)validatePhoneNumber:(NSString*)phoneNumber {
    
    NSString *countryDialingCode = [self.form formRowWithTag:kPhoneNumber].title;
    NSString *internationalPhoneNumber = [NSString stringWithFormat:@"%@%@", countryDialingCode, phoneNumber];
    
    //NSLog(@"Phone Number Text Field finished editing: %@", internationalPhoneNumber);
    
    NSString *countryCode = [self.form formRowWithTag:kCountryCode].value;
    
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    
    NSError *anError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:internationalPhoneNumber
                                 defaultRegion:countryCode error:&anError];
    
    XLFormSectionDescriptor *phoneSection = [self.form formSectionAtIndex:1];
    
    if (anError == nil) {
        // Should check error
        BOOL isValidNumber = [phoneUtil isValidNumber:myNumber] ? YES: NO;
        
        //NSLog(@"isValidNumber = %@", isValidNumber ? @"YES" : @"NO");
        
        if (isValidNumber) {
            
            [self.form formRowWithTag:kPhoneNumber].value = [phoneUtil format:myNumber
                                                                numberFormat:NBEPhoneNumberFormatNATIONAL
                                                                       error:&anError];
            phoneSection.footerTitle = @"";
            self.phoneNumberHasError = NO;
        } else {
            self.phoneNumberHasError = YES;
            phoneSection.footerTitle = NSLocalizedString(@"Invalid phone number", nil);
            
        }
        
    } else {
        //NSLog(@"Error in validatePhoneNumber: %@", [anError localizedDescription]);
        self.phoneNumberHasError = YES;
        phoneSection.footerTitle = NSLocalizedString(@"Invalid phone number", nil);
    }
    
    // Reload the phone number section to either hide or show the footerTitle text
    [UIView setAnimationsEnabled:NO];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    [UIView setAnimationsEnabled:YES];
    
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    UITableViewCell *cell = (UITableViewCell *) [[textField superview] superview];
    
    //NSLog(@"cell.tag = %lu", (long) cell.tag);

    switch(cell.tag) {

        case PhoneNumberTextFieldTag: {

            [self validatePhoneNumber:textField.text];
            break;
        }
            
         default:
            break;
    }
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    //NSLog(@"In sign up view controller %@", [self storyboard]);

    // Hide all separators since we don't need it, especially at the last row which has a BButton
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        //tableViewHeaderFooterView.textLabel.text = [tableViewHeaderFooterView.textLabel.text capitalizedString];
        
        tableViewHeaderFooterView.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];

        
    }
}


- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {

    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        //tableViewHeaderFooterView.textLabel.text = [tableViewHeaderFooterView.textLabel.text capitalizedString];
        
        // Changing the font and font size puts too much of a margin for the red text so comment out for now
        //tableViewHeaderFooterView.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:13];
        tableViewHeaderFooterView.textLabel.textColor = [UIColor redColor];
        
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
