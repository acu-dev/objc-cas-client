//
//  CASClientAppDelegate.h
//  CAS Client
//
//  Created by Chris Gibbs on 3/26/09.
//  Copyright Abilene Christian University 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CAS_ClientAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UILabel *authResultMessage;
	UILabel *requestResultMessage;
	UILabel *requestResultBody;
	UILabel *logoutResultMessage;
	BOOL isAuthenticated;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UILabel *authResultMessage;
@property (nonatomic, retain) IBOutlet UILabel *requestResultMessage;
@property (nonatomic, retain) IBOutlet UILabel *requestResultBody;
@property (nonatomic, retain) IBOutlet UILabel *logoutResultMessage;
@property (nonatomic) BOOL isAuthenticated;

- (IBAction) authenticate;
- (IBAction) sendRequest;
- (IBAction) logout;

- (void) authenticationSucceeded;
- (void) authenticationFailed:(NSString *)reason;

@end

