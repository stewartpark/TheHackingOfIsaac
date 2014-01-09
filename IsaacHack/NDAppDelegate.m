//
//  NDAppDelegate.m
//  IsaacHack
//
//  Created by Ju-yeong Park on 1/9/14.
//  Copyright (c) 2014 Ju-yeong Park. All rights reserved.
//

#import "NDAppDelegate.h"

@implementation NDAppDelegate {
    bool isOn;
    NSString *pid;
    
}

- (NSString*)runAsCommand: (NSString*) cmd{
    NSPipe* pipe = [NSPipe pipe];
    
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments:@[@"-c", [NSString stringWithFormat:@"%@", cmd]]];
    [task setStandardOutput:pipe];
    
    NSFileHandle* file = [pipe fileHandleForReading];
    [task launch];
    
    return [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
}
- (BOOL)executeWithElevatedPrivileges:(char *)tool andArguments: (char**) args
{
    // Create authorization reference
    OSStatus status;
    AuthorizationRef authorizationRef;
    
    // AuthorizationCreate and pass NULL as the initial
    // AuthorizationRights set so that the AuthorizationRef gets created
    // successfully, and then later call AuthorizationCopyRights to
    // determine or extend the allowable rights.
    // http://developer.apple.com/qa/qa2001/qa1172.html
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
    if (status != errAuthorizationSuccess)
    {
        NSLog(@"Error Creating Initial Authorization: %d", status);
        return NO;
    }
    
    // kAuthorizationRightExecute == "system.privilege.admin"
    AuthorizationItem right = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &right};
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed |
    kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
    
    // Call AuthorizationCopyRights to determine or extend the allowable rights.
    status = AuthorizationCopyRights(authorizationRef, &rights, NULL, flags, NULL);
    if (status != errAuthorizationSuccess)
    {
        NSLog(@"Copy Rights Unsuccessful: %d", status);
        return NO;
    }
    
    FILE *pipe = NULL;
    
    status = AuthorizationExecuteWithPrivileges(authorizationRef, tool, kAuthorizationFlagDefaults, (char**)args, &pipe);
    if (status != errAuthorizationSuccess)
    {
        NSLog(@"Error: %d", status);
        return NO;
    }
    
    // The only way to guarantee that a credential acquired when you
    // request a right is not shared with other authorization instances is
    // to destroy the credential.  To do so, call the AuthorizationFree
    // function with the flag kAuthorizationFlagDestroyRights.
    // http://developer.apple.com/documentation/Security/Conceptual/authorization_concepts/02authconcepts/chapter_2_section_7.html
    status = AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
    return YES;
}

- (IBAction)refresh:(id)sender {
    [self refreshProcessInfo];
}

- (IBAction)clickHack:(id)sender {
    if(!isOn) {
        NSAlert *alert = [NSAlert alertWithMessageText: @"The game is off!"
                                        defaultButton:@"Okay"
                                       alternateButton:nil
                                          otherButton:nil
                            informativeTextWithFormat:@"Turn on the game first!"];
        [alert runModal];
        return;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"binary" ofType:@""];
    char* args[] = {[pid UTF8String], NULL};
    [self executeWithElevatedPrivileges:[path UTF8String] andArguments:args];
    NSAlert *alert = [NSAlert alertWithMessageText: @"Enjoy!"
                                     defaultButton:@"Okay"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"You're now immortal."];
    [alert runModal];
}


- (void) refreshProcessInfo {
    NSString* t = [self runAsCommand:@"ps -eo pid,command | grep mdm_flash_player | grep -v grep -m 1 | awk '{print $1}'"];
    if([t length] > 0) {
        pid =  t;
        isOn = true;
        [self.onOff setTitleWithMnemonic:@"ON"];
        [self.onOff setTextColor:[NSColor greenColor]];
    } else {
        pid = @"";
        isOn = false;
        [self.onOff setTitleWithMnemonic:@"OFF"];
        [self.onOff setTextColor:[NSColor redColor]];
    }
    
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self refreshProcessInfo];
     [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];

}




@end
