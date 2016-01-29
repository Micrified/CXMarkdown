/*!
 @header CXMarkdown.h
 
 @brief Contains methods for formatting strings with markdown.
 
 @author Owatch
 @version    0.0.1
 */
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CTFont.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreText/CTStringAttributes.h>

#pragma mark Structures & Definitions
typedef enum {
    CXMarkdownTypeItalics,
    CXMarkdownTypeBold,
    CXMarkdownTypeStrikethrough,
    CXMarkdownTypeSuperscript,
    CXMarkdownTypeHyperlink,
}CXMarkdownType;

@interface CXMarkdown : NSObject

#pragma mark Body Methods

/*!
 @brief Returns an NSAttributedString instance with formatted markdown and font attributes.
 
 @discussion This instance method accepts an NSString instance containing the target string, and an NSDictionary instance containing the associated font attributes to be applied to the string. It outputs the attributed string with both the markdown rendered and the desired font attributes applied.
 
 @param  string * The NSString instance representing the target string.
 
 @param attributes * The NSDictionary instance containing the font attributes.
 
 @return NSAttibutedString * The formatted and rendered NSAttributedString instance.
 */
-(NSAttributedString *)attributedStringFromString:(NSString *)string attributes:(NSDictionary *)fontAttributes;

/*!
 @brief Returns an NSAttributedString instance with formatted markdown and font attributes.
 
 @discussion This instance method accepts an NSString instance containing the target string, and a UIFontDescriptor instance containing some attributes to be applied to the output. Because a UIFontDescriptor uses a different fontAttributes dictionary to that of NSAttributedStrings, only the font and symbolic traits are extracted and applied. The output is the attributed string with the markdown rendered and the font attributes extracted from the fontDescriptor applied.
 
 @param  string * The NSString instance representing the target string.
 
 @param fontDescriptor * The UIFontDescriptor containing the font attributes(!).
 
 @return NSAttibutedString * The formatted and rendered NSAttributedString instance.
 */
-(NSAttributedString *)attributedStringFromString:(NSString *)string withFontDescriptor:(UIFontDescriptor *)fontDescriptor;

/*!
 @brief Returns an NSAttributedString instance with formatted markdown.
 
 @discussion This instance method accepts an NSString instance containing the target string, and outputs a NSAttributedString instance with the markdown rendered, and respective font attributes applied. It uses system font with the system font size in it's output.
 
 @param  string * The NSString instance representing the target string.
 
 
 @return NSAttibutedString * The rendered NSAttributedString instance.
 */
-(NSAttributedString *)attributedStringFromString:(NSString *)string;

@end
