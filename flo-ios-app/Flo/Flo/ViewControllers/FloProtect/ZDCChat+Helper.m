//
//  ZDCChat+Helper.m
//  Flo
//
//  Created by Nicolás Stefoni on 4/4/18.
//  Copyright © 2018 Flo Technologies. All rights reserved.
//

#import "ZDCChat+Helper.h"
#import "Flo-Swift.h"

@implementation ZDCChat (Helper)

+ (void)setupUI {
    [[[ZDCChat instance] overlay] setEnabled:NO];
    
    [[ZDCLoadingView appearance] setLoadingLabelTextColor:StyleHelper.colors.blue];
    
    [[ZDCLoadingErrorView appearance] setTitleColor:StyleHelper.colors.blue];
    [[ZDCLoadingErrorView appearance] setMessageColor:StyleHelper.colors.blue];
    [[ZDCLoadingErrorView appearance] setButtonTitleColor:[UIColor whiteColor]];
    [[ZDCLoadingErrorView appearance] setButtonBackgroundColor:StyleHelper.colors.blue];
    [[ZDCLoadingErrorView appearance] setButtonImage:nil];
    
    [[ZDCFormCellSingleLine appearance] setTextFrameBorderColor:StyleHelper.colors.blue];
    [[ZDCFormCellSingleLine appearance] setTextFrameBackgroundColor:[UIColor whiteColor]];
    [[ZDCFormCellSingleLine appearance] setTextFrameCornerRadius:@(5.0f)];
    [[ZDCFormCellSingleLine appearance] setTextColor:[UIColor colorWithWhite:0.15f alpha:1.0f]];
    
    [[ZDCFormCellDepartment appearance] setTextFrameBorderColor:StyleHelper.colors.blue];
    [[ZDCFormCellDepartment appearance] setTextFrameBackgroundColor:[UIColor whiteColor]];
    [[ZDCFormCellDepartment appearance] setTextFrameCornerRadius:@(5.0f)];
    [[ZDCFormCellDepartment appearance] setTextColor:[UIColor colorWithWhite:0.15f alpha:1.0f]];
    
    [[ZDCFormCellMessage appearance] setTextFrameBorderColor:StyleHelper.colors.blue];
    [[ZDCFormCellMessage appearance] setTextFrameBackgroundColor:[UIColor whiteColor]];
    [[ZDCFormCellMessage appearance] setTextFrameCornerRadius:@(5.0f)];
    [[ZDCFormCellMessage appearance] setTextColor:[UIColor colorWithWhite:0.15f alpha:1.0f]];
    
    [[ZDCJoinLeaveCell appearance] setTextColor:StyleHelper.colors.blue];
    
    [[ZDCVisitorChatCell appearance] setBubbleBorderColor:StyleHelper.colors.lightBlue];
    [[ZDCVisitorChatCell appearance] setBubbleColor:StyleHelper.colors.blue];
    [[ZDCVisitorChatCell appearance] setBubbleCornerRadius:@(5.0f)];
    [[ZDCVisitorChatCell appearance] setTextAlignment:@(NSTextAlignmentLeft)];
    [[ZDCVisitorChatCell appearance] setTextColor:[UIColor whiteColor]];
    [[ZDCVisitorChatCell appearance] setUnsentTextColor:[UIColor grayColor]];
    
    [[ZDCAgentChatCell appearance] setBubbleBorderColor:[UIColor colorWithWhite:0.90f alpha:1.0f]];
    [[ZDCAgentChatCell appearance] setBubbleColor:[UIColor colorWithWhite:0.95f alpha:1.0f]];
    [[ZDCAgentChatCell appearance] setBubbleCornerRadius:@(5.0f)];
    [[ZDCAgentChatCell appearance] setTextAlignment:@(NSTextAlignmentLeft)];
    [[ZDCAgentChatCell appearance] setTextColor:[UIColor colorWithWhite:0.15f alpha:1.0f]];
    [[ZDCAgentChatCell appearance] setAuthorColor:[UIColor grayColor]];
    
    [[ZDCSystemTriggerCell appearance] setTextColor:StyleHelper.colors.blue];
    
    [[ZDCChatTimedOutCell appearance] setTextColor:StyleHelper.colors.blue];
    
    [[ZDCRatingCell appearance] setTitleColor:StyleHelper.colors.blue];
    
    [[ZDCTextEntryView appearance] setAreaBackgroundColor:[UIColor whiteColor]];
    
    [[ZDCPreChatFormView appearance] setFormBackgroundColor:[UIColor whiteColor]];
    [[ZDCOfflineMessageView appearance] setFormBackgroundColor:[UIColor whiteColor]];
    [[ZDCChatView appearance] setChatBackgroundColor:[UIColor whiteColor]];
    [[ZDCLoadingView appearance] setLoadingBackgroundColor:[UIColor whiteColor]];
    [[ZDCLoadingErrorView appearance] setErrorBackgroundColor:[UIColor whiteColor]];
    [[ZDCChatUI appearance] setChatBackgroundColor:[UIColor whiteColor]];
}

@end
