//
//  CASClientAppDelegate.m
//  CAS Client
//
//  Created by Chris Gibbs on 3/26/09.
//  Copyright Abilene Christian University 2009. All rights reserved.
//

#import "CAS_ClientAppDelegate.h"
#import "CAS.h"

@implementation CAS_ClientAppDelegate

@synthesize window;
@synthesize authResultMessage;
@synthesize requestResultMessage;
@synthesize requestResultBody;
@synthesize logoutResultMessage;
@synthesize isAuthenticated;

/*
 Show main window
 */
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [window makeKeyAndVisible];
}

/*
 Attempt to authenticate and get a TGT from CAS server. Provide some static
 values for this test. Normally the username & password would come from user
 input and stored somewhere for use later.
 */
- (IBAction) authenticate {
	NSString *username = @"username-here";
	NSString *password = @"password-here";
	NSString *casServer = @"http://host.example.com";
	NSString *casRestletPath = @"/cas/v1/tickets/";
	
	// Authenticate and get TGT
	NSLog(@"Authenticating...");
	[[CAS client] initWithCasServer:casServer
								 restletPath:casRestletPath
									username:username
									password:password
							 authCallbackObj:self
						authCallbackSelector:@selector(authenticationDidFinishWithStatusCode:)];
}

/*
 Callback for CAS authentication. Receives the HTTP status code given
 by CAS server and delegates action off to appropriate method.
 */
- (void) authenticationDidFinishWithStatusCode:(NSNumber *)statusNumber {
	int statusCode = [statusNumber intValue];
	
	NSLog(@"Authentication Results: %i", statusCode);
	
	// Handle authentication success/failures here
	switch (statusCode) {
		case 201:
			[self authenticationSucceeded];
			break;
		case 400:
			[self authenticationFailed:@"Invalid credentials"];
			break;
		case 0:
			[self authenticationFailed:@"No connection available"];
			break;
		default:
			[self authenticationFailed:@"Encountered unknown status code"];
			break;
	}
}

/*
 Do something if the authentication is successful
 */
- (void) authenticationSucceeded {
	NSLog(@"Authentication succeeded!");
	isAuthenticated = YES;
	[authResultMessage setText:@"Authentication succeeded!"];
}

/*
 Do something if the authentication fails
 */
- (void) authenticationFailed:(NSString *)reason {
	NSString *message = [NSString stringWithFormat:@"Authentication failed: %@", reason];	
	NSLog(@"%@", message);
	isAuthenticated = NO;
	[authResultMessage setText:message];
}

/*
 Get data from CAS protected service
 */
- (IBAction) sendRequest {
	if (!isAuthenticated) {
		[requestResultMessage setText:@"Not authenticated - try to authenticate first!"];
		return;
	}
	// Service URL for testing data retrieval
	NSURL *casProtectedService = [NSURL URLWithString:@"http://host.example.com/service-request/"];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:casProtectedService];
	[[CAS client] sendAsyncRequest:request callbackObj:self callbackSelector:@selector(requestDidFinishWithDetails:)];
}

/*
 Callback for async requests. Receives the returned data from the
 connection in a dictionary.
 */
- (void) requestDidFinishWithDetails:(NSMutableDictionary *)connDetails {
	
	// Check for an error
	NSError *error = [connDetails objectForKey:@"error"];
	if (error) {
		// Do something with the error
		NSLog(@"Error found");
		[requestResultMessage setText:@"Error found"];
		return;
	}
	
	// Get the response
	NSURLResponse *response = [connDetails objectForKey:@"response"];
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		
		// Deal with the response status
		int responseCode = [(NSHTTPURLResponse *)response statusCode];
		switch (responseCode) {
			case 200:
				NSLog(@"Request returned successful");
				NSString *responseBody = [[NSString alloc] initWithData:[connDetails objectForKey:@"data"]
															   encoding:NSUTF8StringEncoding];
				// Uncomment the following to log some details
				//NSLog(@"Response Headers: %@", [(NSHTTPURLResponse *)response allHeaderFields]);
				//NSLog(@"Response Body: %@", responseBody);
				[requestResultMessage setText:@"Request successful!"];
				[requestResultBody setText:responseBody];
				break;
			case 404:
				NSLog(@"Error: 404 not found");
				[requestResultMessage setText:@"Error: 404 not found"];
				break;
			default: {
				NSString *msg = [NSString stringWithFormat:@"Don't know what to do with status code: %@", responseCode];
				NSLog(@"%@", msg);
				[requestResultMessage setText:msg];
				break;
			}
		}
	}
}

/*
 Sends a request to the CAS server's logout URI
 */
- (IBAction) logout {
	if (!isAuthenticated) {
		[logoutResultMessage setText:@"Not authenticated - try to authenticate first!"];
		return;
	}
	
	[logoutResultMessage setText:@"This feature is not implemented yet"];
}

/*
 Cleanup
 */
- (void)dealloc {
	[authResultMessage release];
	[requestResultMessage release];
	[requestResultBody release];
	[logoutResultMessage release];
    [window release];
    [super dealloc];
}


@end
