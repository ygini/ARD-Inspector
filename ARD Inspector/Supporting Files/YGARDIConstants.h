//
//  YGARDIConstants.h
//  ARDInspector
//
//  Created by Yoann Gini on 19/06/13.
//  Copyright (c) 2013 Yoann Gini. All rights reserved.
//

#ifndef ARDInspector_YGARDIConstants_h
#define ARDInspector_YGARDIConstants_h

static NSString * const YGARDInspectorErrorDomain = @"me.gini.ARDInspector";
static NSString * const YGARDInspectorErrorFileTypeKey = @"YGARDInspectorErrorFileTypeKey";

typedef enum {
    YGARDInspectorErrorBadFileType,
	YGARDInspectorErrorNoMasterPassword,
	YGARDInspectorErrorCantCreateCCCryptorRef,
	YGARDInspectorErrorCantUpdateCCCryptorRef,
	YGARDInspectorErrorCantFinalizeCCCryptorRef,
	YGARDInspectorErrorUnreadableArchive,
	YGARDInspectorErrorUnkown
} YGARDInspectorError;

#endif
