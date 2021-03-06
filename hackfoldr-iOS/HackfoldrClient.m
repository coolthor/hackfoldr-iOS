//
//  HackfoldrClient.m
//  hackfoldr-iOS
//
//  Created by Superbil on 2014/6/22.
//  Copyright (c) 2014年 org.superbil. All rights reserved.
//

#import "HackfoldrClient.h"

#import "AFCSVParserResponseSerializer.h"
#import "HackfoldrPage.h"

@interface HackfoldrTaskCompletionSource : BFTaskCompletionSource

+ (HackfoldrTaskCompletionSource *)taskCompletionSource;
@property (strong, nonatomic) NSURLSessionTask *connectionTask;

@end

@implementation HackfoldrTaskCompletionSource

+ (HackfoldrTaskCompletionSource *)taskCompletionSource
{
	return [[HackfoldrTaskCompletionSource alloc] init];
}

- (void)dealloc
{
	[self.connectionTask cancel];
	self.connectionTask = nil;
}

- (void)cancel
{
	[self.connectionTask cancel];
	[super cancel];
}

@end

#pragma mark -

@interface HackfoldrClient ()

@end

@implementation HackfoldrClient

+ (instancetype)sharedClient
{
    static dispatch_once_t onceToken;
    static HackfoldrClient *shareClient;
    dispatch_once(&onceToken, ^{
        shareClient = [[HackfoldrClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://ethercalc.org/_/"]];
    });
    return shareClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        AFCSVParserResponseSerializer *serializer = [AFCSVParserResponseSerializer serializer];
        serializer.usedEncoding = NSUTF8StringEncoding;
		self.responseSerializer = serializer;
    }
    return self;
}

- (BFTask *)_taskWithPath:(NSString *)inPath parameters:(NSDictionary *)parameters
{
	HackfoldrTaskCompletionSource *source = [HackfoldrTaskCompletionSource taskCompletionSource];
	source.connectionTask = [self GET:inPath parameters:parameters success:^(NSURLSessionDataTask *task, id csvFieldArray) {
        HackfoldrPage *page = [[HackfoldrPage alloc] initWithFieldArray:csvFieldArray];
        _lastPage = page;
        [source setResult:page];
	} failure:^(NSURLSessionDataTask *task, NSError *error) {
		[source setError:error];
	}];
	return source.task;
}

- (BFTask *)pagaDataAtPath:(NSString *)inPath
{
    return [self _taskWithPath:[NSString stringWithFormat:@"%@/csv", inPath] parameters:nil];
}

@end
