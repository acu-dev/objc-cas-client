#import "CASViewController.h"
#import "CAS.h"

@interface CASViewController ()
@property (nonatomic, getter = isAuthenticated) BOOL authenticated;
@end

@implementation CASViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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
    CASViewController * __weak weakSelf = self;
	[[CAS client] initWithCasServer:casServer
                        restletPath:casRestletPath
                           username:username
                           password:password
                  authCallbackBlock:^(NSNumber *statusCode) {
                      /*
                       Callback for CAS authentication. Receives the HTTP status code given
                       by CAS server and delegates action off to appropriate method.
                       */
                      NSLog(@"Authentication Results: %@", statusCode);

                      // Handle authentication success/failures here
                      switch ([statusCode intValue]) {
                          case 201:
                              [weakSelf authenticationSucceeded];
                              break;
                          case 400:
                              [weakSelf authenticationFailed:@"Invalid credentials"];
                              break;
                          case 0:
                              [weakSelf authenticationFailed:@"No connection available"];
                              break;
                          default:
                              [weakSelf authenticationFailed:@"Encountered unknown status code"];
                              break;
                      }
                  }];
}

/*
 Do something if the authentication is successful
 */
- (void)authenticationSucceeded {
	NSLog(@"Authentication succeeded!");
	self.authenticated = YES;
	[self.authResultMessage setText:@"Authentication succeeded!"];
}

/*
 Do something if the authentication fails
 */
- (void)authenticationFailed:(NSString *)reason {
	NSString *message = [NSString stringWithFormat:@"Authentication failed: %@", reason];
	NSLog(@"%@", message);
	self.authenticated = NO;
	[self.authResultMessage setText:message];
}

/*
 Get data from CAS protected service
 */
- (IBAction)sendRequest {
	if (!self.authenticated) {
		[self.requestResultMessage setText:@"Not authenticated - try to authenticate first!"];
		return;
	}
	// Service URL for testing data retrieval
	NSURL *casProtectedService = [NSURL URLWithString:@"http://host.example.com/service-request/"];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:casProtectedService];
    CASViewController * __weak weakSelf = self;
	[[CAS client] sendAsyncRequest:request authCallbackBlock:^(NSMutableDictionary *connDetails) {

        /*
         Callback for async requests. Receives the returned data from the
         connection in a dictionary.
         */

        // Check for an error
        NSError *error = [connDetails objectForKey:@"error"];
        if (error) {
            // Do something with the error
            NSLog(@"Error found");
            [weakSelf.requestResultMessage setText:@"Error found"];
            return;
        }

        // Get the response
        NSURLResponse *response = [connDetails objectForKey:@"response"];
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {

            // Deal with the response status
            NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
            switch (responseCode) {
                case 200: {
                    NSLog(@"Request returned successful");
                    NSString *responseBody = [[NSString alloc] initWithData:[connDetails objectForKey:@"data"]
                                                                   encoding:NSUTF8StringEncoding];
                    // Uncomment the following to log some details
                    //NSLog(@"Response Headers: %@", [(NSHTTPURLResponse *)response allHeaderFields]);
                    //NSLog(@"Response Body: %@", responseBody);
                    [weakSelf.requestResultMessage setText:@"Request successful!"];
                    [weakSelf.requestResultBody setText:responseBody];
                    break;
                }
                case 404: {
                    NSLog(@"Error: 404 not found");
                    [weakSelf.requestResultMessage setText:@"Error: 404 not found"];
                    break;
                }
                default: {
                    NSString *msg = [NSString stringWithFormat:@"Don't know what to do with status code: %ld", responseCode];
                    NSLog(@"%@", msg);
                    [weakSelf.requestResultMessage setText:msg];
                    break;
                }
            }
        }
    }];
}

/*
 Sends a request to the CAS server's logout URI
 */
- (IBAction)logout {
	if (!self.authenticated) {
		[self.logoutResultMessage setText:@"Not authenticated - try to authenticate first!"];
		return;
	}

	[self.logoutResultMessage setText:@"This feature is not implemented yet"];
}

@end
