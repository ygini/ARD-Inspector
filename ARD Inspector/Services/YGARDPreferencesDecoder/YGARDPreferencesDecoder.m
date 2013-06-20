//
//  YGARDPreferencesDecoder.m
//  ARDInspector
//
//  Created by Yoann Gini on 19/06/13.
//  Copyright (c) 2013 Yoann Gini. All rights reserved.
//

#import "YGARDPreferencesDecoder.h"

#import <CommonCrypto/CommonCrypto.h>

#define ARD_SECRETS_KEY		@"accessCredentials"

@implementation YGARDPreferencesDecoder

+ (NSDictionary*)decodePreferences:(NSDictionary*)preferences withMasterPassword:(NSString*)masterPassword error:(NSError**)outError
{
	NSDictionary *returnValue = nil;
	NSData *encryptedAccessData = [preferences objectForKey:ARD_SECRETS_KEY];
	
	// MD5 DIGEST
	CC_MD5_CTX masterKeyMD5;
	
    CC_MD5_Init(&masterKeyMD5);
	
	NSUInteger md5Length = [masterPassword length]*2;
	
	md5Length += 0xf;
	md5Length &= 0xfffffff0;
	
	unichar *masterKeyCharacters = (unichar*) calloc(1, md5Length);
	[masterPassword getCharacters:masterKeyCharacters];
	
	CC_MD5_Update(&masterKeyMD5, masterKeyCharacters, (CC_LONG)md5Length);
	
	free(masterKeyCharacters);
	
	unsigned char masterKeyDigest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(masterKeyDigest, &masterKeyMD5);
	// !MD5 DIGEST
	
	
	// CCCryptorRef Creation
	CCCryptorRef decryptor = NULL;
	CCCryptorStatus status = 0;
	
	status = CCCryptorCreate(kCCDecrypt,
							 kCCAlgorithmAES128,
							 kCCOptionECBMode,
							 masterKeyDigest,
							 CC_MD5_DIGEST_LENGTH,
							 NULL,
							 &decryptor);
	
	if (kCCSuccess != status) {
		if (outError) {
			*outError = [NSError errorWithDomain:YGARDInspectorErrorDomain
											code:YGARDInspectorErrorCantCreateCCCryptorRef
										userInfo:nil];
		}
		return nil;
	}
	// !CCCryptorRef Creation
	
	// Decrypt data
	NSMutableData *decryptedAccessData = [NSMutableData new];
	
	const void * encryptedPtr = [encryptedAccessData bytes];
    size_t encryptedSize = [encryptedAccessData length];
	
	
	size_t decryptedSize = CCCryptorGetOutputLength(decryptor, encryptedSize, true);
	[decryptedAccessData setLength:decryptedSize];
	uint8_t * decryptedPtr = [decryptedAccessData mutableBytes];
	
    size_t remainingSpace = decryptedSize;
		
	size_t dataOutMoved;
	status = CCCryptorUpdate(decryptor,
							 encryptedPtr,
							 encryptedSize,
							 decryptedPtr,
							 decryptedSize,
							 &dataOutMoved);
	
	if (kCCSuccess != status) {
		if (outError) {
			*outError = [NSError errorWithDomain:YGARDInspectorErrorDomain
											code:YGARDInspectorErrorCantUpdateCCCryptorRef
										userInfo:nil];
		}
		goto cleanup_and_return;
	}
	
    remainingSpace -= dataOutMoved;
	
	status = CCCryptorFinal(decryptor,
							decryptedPtr,
							remainingSpace,
							&dataOutMoved);
	
	if (kCCSuccess != status) {
		if (outError) {
			*outError = [NSError errorWithDomain:YGARDInspectorErrorDomain
											code:YGARDInspectorErrorCantFinalizeCCCryptorRef
										userInfo:nil];
		}
		goto cleanup_and_return;
	}
	
	NSDictionary *decodedSecrets = [NSUnarchiver unarchiveObjectWithData:decryptedAccessData];
	
	// !Decrypt data
	
	if (!decodedSecrets) {
		if (outError) {
			*outError = [NSError errorWithDomain:YGARDInspectorErrorDomain
											code:YGARDInspectorErrorUnreadableArchive
										userInfo:nil];
		}
		goto cleanup_and_return;
	}
	
	NSMutableDictionary *newPreferences = [preferences mutableCopy];
	
	[newPreferences setObject:decodedSecrets
					   forKey:ARD_SECRETS_KEY];
	
	returnValue = [newPreferences autorelease];
	
cleanup_and_return:
	if (decryptor) {
		CCCryptorRelease(decryptor);
	}
	
	[decryptedAccessData release];
	
	return returnValue;
}

@end
