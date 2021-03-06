//
//  SFSImageManager.m
//  SpaceFactoryNetworking
//
//  Created by Dalton Claybrook on 12/5/14.
//  Copyright (c) 2014 Space Factory Studios. All rights reserved.
//

#import "SFSImageManager.h"

NSString * const SFSImageManagerErrorDomain = @"SFSImageManagerErrorDomain";

@implementation SFSImageManager

#pragma mark - Initializers

- (instancetype)initWithFileManager:(SFSFileManager *)fileManager
{
    self = [super init];
    if (self)
    {
        _backingFileManager = (fileManager) ?: [[SFSFileManager alloc] init];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _backingFileManager = [[SFSFileManager alloc] init];
    }
    return self;
}

#pragma mark - Public
#pragma mark - Fetch

- (id<SFSTask>)fetchImageAtURL:(NSURL *)url withCompletion:(SFSImageManagerCompletion)block
{
    return [self fetchImageUsingFetchRequest:[SFSFileFetchRequest defaultRequestWithURL:url] withCompletion:block];
}

- (id<SFSTask>)fetchImageUsingFetchRequest:(SFSFileFetchRequest *)request withCompletion:(SFSImageManagerCompletion)block
{
    return [self.backingFileManager fetchFileDataUsingFetchRequest:request withCompletion:[self completionBlockWithImageBlock:block identifier:request.identifier group:request.fileGroup]];
}

#pragma mark - Existing Images

- (UIImage *)existingImageForURL:(NSURL *)url
{
    return [self existingImageForIdentifier:[url absoluteString]];
}

- (UIImage *)existingImageForIdentifier:(NSString *)identifier
{
    NSURL *url = [self.backingFileManager existingFileURLForIdentifier:identifier];
    return [self imageFromFileURL:url error:nil];
}

- (UIImage *)existingImageForIdentifier:(NSString *)identifier inGroup:(NSString *)fileGroup
{
    NSURL *url = [self.backingFileManager existingFileURLForIdentifier:identifier inGroup:fileGroup];
    return [self imageFromFileURL:url error:nil];
}

#pragma mark - Injection

- (void)storeImage:(UIImage *)image usingIdentifier:(NSString *)identifier
{
    [self.backingFileManager storeData:UIImagePNGRepresentation(image) usingIdentifier:identifier];
}

- (void)storeImage:(UIImage *)image usingIdentifier:(NSString *)identifier inGroup:(NSString *)fileGroup
{
    [self.backingFileManager storeData:UIImagePNGRepresentation(image) usingIdentifier:identifier inGroup:fileGroup];
}

- (void)storeImage:(UIImage *)image usingIdentifier:(NSString *)identifier inGroup:(NSString *)fileGroup usingDiskEncryption:(BOOL)encrypt
{
    [self.backingFileManager storeData:UIImagePNGRepresentation(image) usingIdentifier:identifier inGroup:fileGroup usingDiskEncryption:encrypt];
}

#pragma mark - Private

- (SFSFileManagerCompletion)completionBlockWithImageBlock:(SFSImageManagerCompletion)block identifier:(NSString *)identifier group:(NSString *)group
{
    __typeof__(self) __weak weakSelf = self;
    return ^(NSURL *fileURL, NSError *error) {
        
        UIImage *image = nil;
        if (!error)
        {
            image = [weakSelf imageFromFileURL:fileURL error:&error];
            if (error)
            {
                [weakSelf.backingFileManager evictFileForIdentifier:identifier inGroup:group save:YES];
            }
        }
        
        if (block)
        {
            block(image, error);
        }
    };
}

- (UIImage *)imageFromFileURL:(NSURL *)url error:(out NSError *__autoreleasing*)error
{
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[url path]];
    if (!image && error)
    {
        *error = [self invalidImageDataError];
    }
    return image;
}

- (NSError *)invalidImageDataError
{
    return [NSError errorWithDomain:SFSImageManagerErrorDomain code:0 userInfo:@{ NSUnderlyingErrorKey : @"Image could not be created from the data at the specified file or endpoint" }];
}

@end
