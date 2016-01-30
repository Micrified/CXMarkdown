# CXMarkdown
An NSObject subclass that formats and outputs markdown in the form of NSAttributedStrings

The CXMarkdown NSObject subclass allows for NSString instances containing markdown to be rendered as NSAttributedStrings.
It iteratively parses and formats a CFMutableAttributedString before returning it as an NSAttributedString with the markdown translated into font attributes.
CXMarkdown currently only renders:

* Italics: As *such*.
* Bold: As **such**.
* Strikethoughs: As ~~such~~
* Superscript: As<sup>such</sup>
* Hyperlinks: As [such](http://www.github.com/Unisung/CXMarkdown).

CXMarkdown will be extended to support quotes, and code blocks. Please inform me of bugs and other issues if applicable.
Finally, please don't parse strings larger than 2<sup>16</sup> characters in length unless you plan on convering the indexing variables to 32 bit integer types.

**Example:**


    /* Create your NSString instance */
    NSString *myString = @"Hello. This sting uses *italics*, **bold**, ***italics-and-bold***, ~~strikethroughs~~, and even super^scripting and [hyperlinks](http://www.google.com) embedded within markdown.";
    
    /* Create your UIFontDescriptor instance */
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor fontDescriptorWithName:@"Avenir-Book" size:14.0f];
    
    /* Obtain the NSAttributedString instance with rendered markdown */
    NSAttributedString *attributedString = [CXMarkdown attributedStringFromString:myString withFontDescriptor:fontDescriptor];
