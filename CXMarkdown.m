//
//  CXMarkdown.m
//
//  Created by Owatch

#import "CXMarkdown.h"

@implementation CXMarkdown

#pragma mark Helper Methods

/* Returns font adjusted for symbolic trait mask */
+(UIFont *)newFontFromFont:(UIFont *)font Mask:(CTFontSymbolicTraits)mask {
    CTFontRef fontRef = (__bridge CTFontRef)font;
    UIFont *newFont = (UIFont *)CFBridgingRelease(CTFontCreateCopyWithSymbolicTraits(fontRef, [font pointSize], NULL, mask, mask));
    return newFont;
}

/* Returns symbolic trait mask for markdown type */
+(uint32_t)symbolicTraitForMarkdownType:(CXMarkdownType)markdown {
    if (markdown == CXMarkdownTypeItalics){return UIFontDescriptorTraitItalic;}
    if (markdown == CXMarkdownTypeBold){return UIFontDescriptorTraitBold;}
    return 0;
}

/* Returns a character array for a CFMutableAttributedStringRef string */
+(char *)charArrayFromAttributedString:(CFMutableAttributedStringRef *)mutableAttributedString {
    CFStringRef string = CFAttributedStringGetString(*mutableAttributedString);
    CFIndex len = CFStringGetLength(string);
    CFIndex maxsize = CFStringGetMaximumSizeForEncoding(len, kCFStringEncodingUTF8)+1;
    char *buffer = (char *)malloc(maxsize);
    if (CFStringGetCString(string, buffer, maxsize, kCFStringEncodingUTF8)){
        return buffer;
    }
    return NULL;
}

/* Removes formatting characters over a range depending on markdown type. Does not cover hyperlinks */
+(void)removeMarkdownType:(CXMarkdownType)type fromString:(CFMutableAttributedStringRef *)mutableAttributedString range:(CFRange)range {
    CFAttributedStringBeginEditing(*mutableAttributedString);
    
    CFAttributedStringRef replacementString; UInt8 leadingOffset = 0; UInt8 trailingOffset = 0;
    switch (type) {
        case CXMarkdownTypeItalics:
            leadingOffset = 1; trailingOffset = 2;
            break;
        case CXMarkdownTypeBold:
            leadingOffset = 2; trailingOffset = 4;
            break;
            
        case CXMarkdownTypeStrikethrough:
            leadingOffset = 2; trailingOffset = 4;
            break;
            
        case CXMarkdownTypeSuperscript:
            leadingOffset = 1; trailingOffset = 1;
            break;
            
        default:
            break;
    }
    replacementString = CFAttributedStringCreateWithSubstring(kCFAllocatorDefault, *mutableAttributedString, CFRangeMake(range.location + leadingOffset, range.length - trailingOffset));
    CFAttributedStringReplaceAttributedString(*mutableAttributedString, range, replacementString);
    CFRelease(replacementString);
    
    CFAttributedStringEndEditing(*mutableAttributedString);
}

#pragma mark Formatting Methods

/* Replaces range of string with the link title, and adds the URL under the NSLinkAttributeName key to the attributes of the string */
+(void)applyHyperlinkToString:(CFMutableAttributedStringRef *)mutableAttributedString range:(CFRange)range partitionIndex:(UInt32)pindex {
    CFAttributedStringBeginEditing(*mutableAttributedString);
    
    CFAttributedStringRef title = CFAttributedStringCreateWithSubstring(kCFAllocatorDefault, *mutableAttributedString, CFRangeMake(range.location+1, pindex - (range.location+2)));
    CFMutableAttributedStringRef mutableTitle = CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, (pindex - (range.location+2)), title);
    CFAttributedStringRef destination = CFAttributedStringCreateWithSubstring(kCFAllocatorDefault, *mutableAttributedString, CFRangeMake(pindex+1, (range.location + range.length) - (pindex+2)));
    
    /* Set Attributes */
    NSURL *destURL = [NSURL URLWithString:(__bridge NSString*)CFAttributedStringGetString(destination)];
    CFAttributedStringSetAttribute(mutableTitle, CFRangeMake(0, (pindex - (range.location+2))), (__bridge CFStringRef)NSLinkAttributeName, (CFTypeRef)destURL);
    
    /* Replace range with title */
    CFAttributedStringReplaceAttributedString(*mutableAttributedString, range, mutableTitle);
    
    CFAttributedStringEndEditing(*mutableAttributedString);
    CFRelease(title); CFRelease(mutableTitle); CFRelease(destination);
}


/* Replaces range of string with superscripted variant */
+(void)applySuperscriptToString:(CFMutableAttributedStringRef *)mutableAttributedString range:(CFRange)range degree:(UInt32)degree {
    CFAttributedStringBeginEditing(*mutableAttributedString);
    
    /* Set Attribute */
    CFAttributedStringSetAttribute(*mutableAttributedString, range, kCTSuperscriptAttributeName, (CFTypeRef)[NSNumber numberWithInteger:degree]);
    
    CFAttributedStringEndEditing(*mutableAttributedString);
}

/* Replaces range of string with a struck-through variant */
+(void)applyStrikethroughToString:(CFMutableAttributedStringRef *)mutableAttributedString range:(CFRange)range {
    CFAttributedStringBeginEditing(*mutableAttributedString);
    
    /* Set Attribute */
    CFAttributedStringSetAttribute(*mutableAttributedString, range, (__bridge CFStringRef)NSStrikethroughStyleAttributeName, (CFTypeRef)[NSNumber numberWithInt:1]);
    
    CFAttributedStringEndEditing(*mutableAttributedString);
}

/* Replaces range of string with a bolded or italicized variant */
+(void)applyItalicsOrBoldToString:(CFMutableAttributedStringRef *)mutableAttributedString range:(CFRange)range type:(CXMarkdownType)type {
    CFAttributedStringBeginEditing(*mutableAttributedString);
    
    UInt32 i = (UInt32)range.location;
    while (i < (range.location + range.length)){
        CFRange er; CFDictionaryRef attributes = CFAttributedStringGetAttributes(*mutableAttributedString, i, &er);
        UInt32 erLen = (er.location < range.location) ? (UInt32)(er.length - (range.location - er.location)) : (UInt32)er.length;
        erLen = (erLen < (range.length - (i - range.location))) ? erLen : (UInt32)(range.length - (i - range.location));
        
        UIFont *font = CFDictionaryGetValue(attributes, (__bridge CFStringRef)NSFontAttributeName);
        NSNumber *symbolicTrait = CFDictionaryGetValue(attributes, (__bridge CFStringRef)UIFontSymbolicTrait);
        
        font = [self newFontFromFont:font Mask:(CTFontSymbolicTraits)[self symbolicTraitForMarkdownType:type]];
        symbolicTrait = [NSNumber numberWithLongLong:[symbolicTrait longLongValue] | [self symbolicTraitForMarkdownType:type]];
        
        CFAttributedStringSetAttribute(*mutableAttributedString, CFRangeMake(i, erLen), (__bridge CFStringRef)NSFontAttributeName, (CFTypeRef)font);
        CFAttributedStringSetAttribute(*mutableAttributedString, CFRangeMake(i, erLen), (__bridge CFStringRef)UIFontSymbolicTrait, (CFTypeRef)symbolicTrait);
        i += erLen;
    }
    
    CFAttributedStringEndEditing(*mutableAttributedString);
}

#pragma mark Parser

+(void)parseString:(CFMutableAttributedStringRef *)mutableAttributedString ofLength:(UInt16)length {
    
    /* Obtain char array */
    char *string = [CXMarkdown charArrayFromAttributedString:mutableAttributedString];
    
    //CFAbsoluteTime a = CFAbsoluteTimeGetCurrent();
    /* Variables */
    /* (NAME)Count : Tracks occurances of token characters */
    /* (NAME)Open : Tracks whether or not the markdown style has been evoked */
    /* (NAME)OpenIndex: Tracks index at which markdown style initally detected */
    /* boundary: Instructs parser to execute actions when asteriskCount has exceeded boundary. Used to prioritize closing italics */
    /* hypPartitionIndex: Stores the index in which a URL is seperated from the title in markdown hyperlink format */
    uint8_t asteriskCount = 0; uint8_t tildaCount = 0; uint8_t caretCount = 0;
    uint8_t boldOpen = 0; uint8_t italOpen = 0; uint8_t tildaOpen = 0; uint8_t caretOpen = 0; uint8_t hypOpen = 0;
    uint16_t boldOpenIndex = 0; uint16_t italOpenIndex = 0; uint16_t tildaOpenIndex = 0; uint16_t caretOpenIndex = 0; uint16_t hypOpenIndex = 0;
    uint8_t boundary = 2; uint16_t hypPartitionIndex = 0;
    
    for (int i = 0; i < length+1; i++){
        
        /* Escape Sequences */
        if (string[i] == '\\'){
            i++; continue;
        }
        
        /* Hyperlink */
        if (hypOpen){
            if (hypPartitionIndex){
                
                if (string[i] == ' '){
                    hypPartitionIndex = 0; hypOpen = 0;
                }
        
                if (string[i] == ')'){
                    if ((hypPartitionIndex > boldOpenIndex) && (hypPartitionIndex > italOpenIndex) && (hypPartitionIndex > tildaOpenIndex) && (hypPartitionIndex > caretOpenIndex)){
                        
                        /* Apply hyperlink attributes, and replace formatting */
                        [CXMarkdown applyHyperlinkToString:mutableAttributedString range:CFRangeMake(hypOpenIndex, (i - hypOpenIndex)+1) partitionIndex:hypPartitionIndex];
                        
                        /* Adjust length and index */
                        length -= (1 + (i - hypPartitionIndex)); i -= (2 + (i - hypPartitionIndex));
    
                        /* Update string */
                        free(string); string = [CXMarkdown charArrayFromAttributedString:mutableAttributedString];
                    }
                    
                    hypPartitionIndex = 0; hypOpen = 0;
                }
            } else {
                if (string[i] == '('){
                    hypPartitionIndex = (string[i-1] == ']' ? i:0);
                }
            }
            
        } else {
            if (string[i] == '['){
                hypOpen = 1; hypOpenIndex = i;
            }
        }
        
        /* Italics & Bold */
        if (string[i] == '*' && asteriskCount < boundary){
            asteriskCount++;
        } else {
            if (asteriskCount){
                if (asteriskCount < 2){
                    if (italOpen){
                        if (string[i-2] != ' '){
                            italOpen = 0; boundary = 2;
                            
                            /* Apply italic attributes */
                            [CXMarkdown applyItalicsOrBoldToString:mutableAttributedString range:CFRangeMake(italOpenIndex, (i - italOpenIndex)) type:CXMarkdownTypeItalics];
                            
                            /* Remove formatting */
                            [CXMarkdown removeMarkdownType:CXMarkdownTypeItalics fromString:mutableAttributedString range:CFRangeMake(italOpenIndex, (i - italOpenIndex))];
                            
                            /* Adjust length and index */
                            length -= 2; i -= 2;
                            
                            /* Update string */
                            free(string); string = [CXMarkdown charArrayFromAttributedString:mutableAttributedString];
                            
                            /* Adjust variables */
                            if (boldOpen && boldOpenIndex > italOpenIndex){boldOpenIndex -= 1;}
                            if (tildaOpen && tildaOpenIndex > italOpenIndex){tildaOpenIndex -= 1;}
                            if (caretOpen && caretOpenIndex > italOpenIndex){caretOpenIndex -= 1;}

                        }
                    } else {
                        if (string[i] != ' '){
                            if (boldOpen){
                                boundary = 1;
                            }
                            italOpen = 1; italOpenIndex = i-1;
                        }
                    }
                    
                    
                } else {
                    if (boldOpen){
                        if (string[i-3] != ' '){
                            boldOpen = 0; boundary = 2;
                            
                            /* Apply bold attributes */
                            [CXMarkdown applyItalicsOrBoldToString:mutableAttributedString range:CFRangeMake(boldOpenIndex, (i - boldOpenIndex)) type:CXMarkdownTypeBold];
                            
                            /* Remove formatting */
                            [CXMarkdown removeMarkdownType:CXMarkdownTypeBold fromString:mutableAttributedString range:CFRangeMake(boldOpenIndex, (i - boldOpenIndex))];
                            
                            /* Adjust length and index */
                            length -= 4; i -= 4;
                            
                            /* Update string */
                            free (string); string = [CXMarkdown charArrayFromAttributedString:mutableAttributedString];
                            
                            /* Adjust variables */
                            if (italOpen && italOpenIndex > boldOpenIndex){italOpenIndex -= 2;}
                            if (tildaOpen && tildaOpenIndex > boldOpenIndex){tildaOpenIndex -= 2;}
                            if (caretOpen && caretOpenIndex > boldOpenIndex){caretOpenIndex -= 2;}

                        }
                    } else {
                        if (string[i] != ' '){
                            if (italOpen){
                                boundary = 2;
                            }
                            boldOpen = 1; boldOpenIndex = i-2;
                        }
                    }
                }
                asteriskCount = 0;
            }
            if (string[i] == '*'){asteriskCount++;}
        }
        
        /* Strikethroughs */
        if (string[i] == '~' && tildaCount < 2){
            tildaCount++;
        } else {
            if (tildaCount){
                if (tildaCount == 2){
                    if (tildaOpen){
                        if (string[i-3] != ' '){
                            tildaOpen = 0;
                            
                            /* Apply strikethrough attributes */
                            [CXMarkdown applyStrikethroughToString:mutableAttributedString range:CFRangeMake(tildaOpenIndex, (i - tildaOpenIndex))];
                            
                            /* Remove formatting */
                            [CXMarkdown removeMarkdownType:CXMarkdownTypeStrikethrough fromString:mutableAttributedString range:CFRangeMake(tildaOpenIndex, (i - tildaOpenIndex))];
                            
                            /* Adjust length and index */
                            length -= 4; i -= 4;
                            
                            /* Update string */
                            free(string); string = [CXMarkdown charArrayFromAttributedString:mutableAttributedString];
                            
                            /* Adjust variables */
                            if (boldOpen && boldOpenIndex > tildaOpenIndex){boldOpenIndex -= 2;}
                            if (italOpen && italOpenIndex > tildaOpenIndex){italOpenIndex -= 2;}
                            if (caretOpen && caretOpenIndex > tildaOpenIndex){caretOpenIndex -= 2;}
                        }
                    } else {
                        if (string[i] != ' '){
                            tildaOpen = 1; tildaOpenIndex = i-2;
                        }
                    }
                }
            }
            tildaCount = 0;
            if (string[i] == '~'){tildaCount++;}
        }
        
        /* Superscript */
        if (string[i] == '^'){
            if (caretOpen){
                
                /* Apply superscript attributes */
                [CXMarkdown applySuperscriptToString:mutableAttributedString range:CFRangeMake(caretOpenIndex, (i - caretOpenIndex)) degree:caretCount];
                
                /* Remove formatting */
                [CXMarkdown removeMarkdownType:CXMarkdownTypeSuperscript fromString:mutableAttributedString range:CFRangeMake(caretOpenIndex, 1)];
                
                /* Adjust length and index */
                length -= 1; i -= 1; 
                
                /* Update string */
                free(string); string = [CXMarkdown charArrayFromAttributedString:mutableAttributedString];
                
                /* Increase degree */
                caretCount++; caretOpenIndex = i;
                
                /* Adjust variables */
                if (italOpen && italOpenIndex > caretOpenIndex){caretOpenIndex -= 1;}
                if (boldOpen && boldOpenIndex > caretOpenIndex){boldOpenIndex -= 1;}
                if (tildaOpen && tildaOpenIndex > caretOpenIndex){tildaOpenIndex -= 1;}
                
            } else { caretOpen = 1; caretCount++; caretOpenIndex = i;}
        } else {
            if (caretCount && (string[i] == ' ' || string[i] == '\0')){
                
                /* Apply superscript attributes */
                [CXMarkdown applySuperscriptToString:mutableAttributedString range:CFRangeMake(caretOpenIndex, (i - caretOpenIndex)) degree:caretCount];
                
                /* Remove formatting */
                [CXMarkdown removeMarkdownType:CXMarkdownTypeSuperscript fromString:mutableAttributedString range:CFRangeMake(caretOpenIndex, 1)];
                
                /* Adjust length and index */
                length -= 1; i -= 1;
                
                /* Update string */
                free(string); string = [CXMarkdown charArrayFromAttributedString:mutableAttributedString];
                
                /* Clear out degree and close superscript tracking */
                caretOpen = 0; caretCount = 0;
                
                /* Adjust variables */
                if (italOpen && italOpenIndex > caretOpenIndex){caretOpenIndex -= 1;}
                if (boldOpen && boldOpenIndex > caretOpenIndex){boldOpenIndex -= 1;}
                if (tildaOpen && tildaOpenIndex > caretOpenIndex){tildaOpenIndex -= 1;}
            }
        }
    }
    
    /* Free allocated memory */
    free(string);
    
    //CFAbsoluteTime b = CFAbsoluteTimeGetCurrent();
    /* printf("Time in Parser: %f\n",b-a); */
}

#pragma mark Public Methods

/* Returns an NSAttributedString with applied Markdown based upon character attributes */
+(NSAttributedString *)attributedStringFromString:(NSString *)string attributes:(NSDictionary *)fontAttributes {
    
    /* Obtain string length */
    UInt16 len = [string length];
    
    /* Build Attributed String */
    CFStringRef cfString = (__bridge CFStringRef)string;
    CFAttributedStringRef attributedString = CFAttributedStringCreate(kCFAllocatorDefault, cfString, NULL);
    CFMutableAttributedStringRef mutableAttributedString = CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, len, attributedString);
    
    /* Begin Editing */
    CFAttributedStringBeginEditing(mutableAttributedString);
    
    /* Add Font and Symbolic Trait */
    CFAttributedStringSetAttributes(mutableAttributedString, CFRangeMake(0, len), (__bridge CFDictionaryRef)fontAttributes, YES);
    
    /* End Editing */
    CFAttributedStringEndEditing(mutableAttributedString);
    
    /* Parse String & Format */
    [CXMarkdown parseString:&mutableAttributedString ofLength:len];
    
    NSMutableAttributedString *returnString = (__bridge NSMutableAttributedString *)mutableAttributedString;
    
    /* Free Memory */
    CFRelease(cfString);
    CFRelease(attributedString);
    CFRelease(mutableAttributedString);
    
    return returnString;
}

/* Returns an NSAttributedString with applied Markdown */
+(NSAttributedString *)attributedStringFromString:(NSString *)string withFontDescriptor:(UIFontDescriptor *)fontDescriptor {
    
    UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:[[[fontDescriptor fontAttributes]valueForKey:UIFontDescriptorSizeAttribute]floatValue]];
    NSNumber *symbolicTrait = [NSNumber numberWithLongLong:[fontDescriptor symbolicTraits]];
    
    NSDictionary *fontAttributes = [[NSDictionary alloc]initWithObjects:@[font,symbolicTrait] forKeys:@[NSFontAttributeName,UIFontSymbolicTrait]];
    
    return [CXMarkdown attributedStringFromString:string attributes:fontAttributes];
}

/* Returns an NSAttributedString with applied Markdown */
+(NSAttributedString *)attributedStringFromString:(NSString *)string {
    UIFont *defaultFont = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    UIFontDescriptor *defaultDescriptor = [UIFontDescriptor fontDescriptorWithName:[defaultFont fontName] size:[defaultFont pointSize]];
    return [CXMarkdown attributedStringFromString:string withFontDescriptor:defaultDescriptor];
}

@end
