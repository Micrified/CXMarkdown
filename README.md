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
