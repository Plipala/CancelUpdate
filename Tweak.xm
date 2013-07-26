/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/
static NSBundle *LocalizationBundle;
#define CULocalizedString(key, comment) \
[LocalizationBundle localizedStringForKey:(key) value:@"" table:nil]

@interface SBAlertItem
- (id)alertSheet;
@end

@interface SBDeleteIconAlertItem : SBAlertItem
- (void)buttonDismissed;
- (id)icon;	
@end

@interface SBDownloadingIcon
-(id)realDisplayName;
-(id)applicationBundleID;
-(id)download;
-(id)cancelUpdateAlertBody;
-(id)cancelUpdateAlertCancelTitle;
-(id)cancelUpdateAlertConfirmTitle;
-(id)cancelUpdateAlertTitle;
@end

@interface SBApplicationController
+(id)sharedInstance;
-(id)allApplications;
@end

@interface SBApplication 
@property(copy) NSString* displayIdentifier;
@end

@interface SSDownloadManager
+ (id)softwareDownloadManager;
- (void)cancelDownloads:(id)arg1 completionBlock:(id)arg2;
@end

%hook SBDeleteIconAlertItem

- (void)alertView:(id)arg1 clickedButtonAtIndex:(int)arg2{
	[self buttonDismissed];
	BOOL updating = NO;
	if ([[self icon] isKindOfClass:objc_getClass("SBDownloadingIcon")])
	{
		NSString *identifier = [(SBDownloadingIcon*)[self icon] applicationBundleID];
    	NSArray *apps = [[objc_getClass("SBApplicationController") sharedInstance] allApplications];
    	for (SBApplication *app in apps){
        	if ([[app displayIdentifier] isEqualToString:identifier]) {
            	updating = YES;
            }
        }
	}
	if (updating)
	{
		if (!arg2)
		{
			[[objc_getClass("SSDownloadManager") softwareDownloadManager] cancelDownloads:[NSArray arrayWithObject:[(SBDownloadingIcon*)[self icon] download]] completionBlock:^{}];
		}
	}
	else {
		%orig;
	}
}

- (void)configure:(BOOL)arg1 requirePasscodeForActions:(BOOL)arg2{
	BOOL updating = NO;
	if ([[self icon] isKindOfClass:objc_getClass("SBDownloadingIcon")])
	{
		NSString *identifier = [(SBDownloadingIcon*)[self icon] applicationBundleID];
    	NSArray *apps = [[objc_getClass("SBApplicationController") sharedInstance] allApplications];
    	for (SBApplication *app in apps){
        	if ([[app displayIdentifier] isEqualToString:identifier]) {
            	updating = YES;
            }
        }
	}
	if (updating)
	{
		UIAlertView *alertSheet = [self alertSheet];
		[alertSheet setDelegate:self];
		[alertSheet setTitle:[[self icon] cancelUpdateAlertCancelTitle]];
		[alertSheet setBodyText:[[self icon] cancelUpdateAlertBody]];
		[alertSheet setCancelButtonIndex:[alertSheet addButtonWithTitle:[[self icon] cancelUpdateAlertConfirmTitle]]];
		[alertSheet addButtonWithTitle:[[self icon] cancelUpdateAlertTitle]];
	}
	else {
		%orig;
	}
}


%end

%hook SBDownloadingIcon

%new
-(id)cancelUpdateAlertBody{
	return [NSString stringWithFormat:CULocalizedString(@"CANCELUPDATE_ICON_BODY",nil),[self realDisplayName]];
}

%new
-(id)cancelUpdateAlertCancelTitle{
	return [NSString stringWithFormat:CULocalizedString(@"CANCELUPDATE_ICON_TITLE",nil),[self realDisplayName]];
}

%new
-(id)cancelUpdateAlertConfirmTitle{
	return CULocalizedString(@"CANCELUPDATE_ICON_CONFIRM",nil);
}

%new
-(id)cancelUpdateAlertTitle{
	return CULocalizedString(@"CANCELUPDATE_ICON_CANCEL",nil);
}

%end

%ctor{
	%init;
	LocalizationBundle = [[NSBundle alloc] initWithPath:@"/var/mobile/Library/CancelUpdate/CancelUpdateLanguages.bundle"];
}