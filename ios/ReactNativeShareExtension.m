#import <React/RCTRootView.h>
#import <MobileCoreServices/MobileCoreServices.h>

#if __has_include(<React/RCTUtilsUIOverride.h>)
    #import <React/RCTUtilsUIOverride.h>
#endif

#import "ReactNativeShareExtension.h"

NSExtensionContext* extensionContext;

@implementation ReactNativeShareExtension

- (UIView*) shareView
{
    return nil;
}

- (BOOL)isModalInPresentation {
    return true;
}

RCT_EXPORT_MODULE();

- (void)viewDidLoad
{
    [super viewDidLoad];

    extensionContext = self.extensionContext;

    UIView *rootView = [self shareView];
    if (rootView.backgroundColor == nil) {
        rootView.backgroundColor = [[UIColor alloc] initWithRed:1 green:1 blue:1 alpha:0.1];
    }

    #if __has_include(<React/RCTUtilsUIOverride.h>)
        [RCTUtilsUIOverride setPresentedViewController:self];
    #endif

    self.view = rootView;
}

RCT_EXPORT_METHOD(openURL:(NSString *)url)
{
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *openUrl = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if (@available(iOS 10.0, *)) {
        [application openURL:openUrl options:@{} completionHandler: nil];
    }
}

RCT_EXPORT_METHOD(close)
{
    [extensionContext completeRequestReturningItems:nil
                                  completionHandler:nil];
    exit(0);
}

RCT_REMAP_METHOD(data, resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self extractDataFromContext:extensionContext withCallback:^(NSArray* items, NSException* err) {
        resolve(items);
    }];
}

- (void)extractDataFromContext:(NSExtensionContext *)context withCallback:(void(^)(NSArray *items, NSException *exception))callback
{
    __block NSMutableArray *data = [NSMutableArray new];

    NSExtensionItem *item = [context.inputItems firstObject];
    NSArray *attachments = item.attachments;
    __block NSUInteger index = 0;

    [attachments enumerateObjectsUsingBlock:^(NSItemProvider *provider, NSUInteger idx, BOOL *stop)
    {
        [provider.registeredTypeIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop)
        {
            [provider loadItemForTypeIdentifier:identifier options:nil completionHandler:^(id<NSSecureCoding> item, NSError *error)
            {
                index += 1;

                NSString *string;
                NSString *type;

                // is an URL - Can be a path or Web URL
                if ([(NSObject *)item isKindOfClass:[NSURL class]]) {
                    NSURL *url = (NSURL *) item;
                    string = [url absoluteString];
                    type = ([[string pathExtension] isEqualToString:@""]) || [url.scheme containsString:@"http"] ? @"text" : @"media";

                    [data addObject:@{ @"value": string, @"type": type }];
                
                // is a String
                } else if ([(NSObject *)item isKindOfClass:[NSString class]]) {
                    string = (NSString *)item;
                    type = @"text";

                    [data addObject:@{ @"value": string, @"type": type }];

                // is an Image
                } else if ([(NSObject *)item isKindOfClass:[UIImage class]]) {
                    UIImage *sharedImage = (UIImage *)item;
                    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"image.png"];
                    [UIImagePNGRepresentation(sharedImage) writeToFile:path atomically:YES];
                    string = [NSString stringWithFormat:@"%@%@", @"file://", path];
                    type = @"media";

                    [data addObject:@{ @"value": string, @"type": type }];
                }

                if (index == [attachments count]) {
                    callback(data, nil);
                }
            }];

            // We'll only use the first provider
            *stop = YES;
        }];
    }];
}

@end
