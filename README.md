# XML Schemas for WordPress Export RSS (WXR)

An XML Schema 1.1 schema for WXR.

## Description

These schemas are intended to serve primarily as documentation of WXR.

Currently, there are schemas for:

1. [WXR 1.2](1.2)
1. a proposal for a new [WXR 1.3](1.3-proposed)

### Purpose
			
There are 2 primary audiences for these schemas:
1. WP Core contributors involved in maintaining the export/import code (i.e., to serve as a check for keeping the exporter/importer in sync when making modifications)
1. plugin authors who want to write their own export/import code.

### Not Purpose
		
These schemas are NOT intended to be used for run-time validation during an import.  The primary reason for this is
that the XML parsers that are included in PHP do NOT support XML Schema 1.1 (because they are
all based on libxml, which only supports validation against XML Schema 1.0, which is not expressive
enough to capture the rules of RSS, so validating with a 1.0 schema would be useless, or worse) :-)

## Documentation

HTML browsable documentation generated from these schemas is available at:

1. [WXR 1.2](http://sparrowhawkcomputing.com/wxr/1.2/docs/wxr.html)
1. [WXR 1.3 Proposed](http://sparrowhawkcomputing.com/wxr/1.3/docs/wxr.html)

If I could figure out how to add that documentation as wiki pages here on GitHub I would, but I can't,
so I won't :-)

## Issues

Theses schema documents are sprinkled throughout with `xs:annotation/xs:documentation` elements.
Most are intended to document the element/type they are children of.  However, some
contain `@todo`'s where I know there is still something to do or where there is an open
question about how something should be done.  Many of these `@todo`'s note that I intend
to open trac tickets on a number of topics.

I'd be **very** interested in general feedback from the WP community on this schema **before**
before I open any of those tickets.

If you have comments/suggestions, please open an issue here.  General "discussion" issues
are welcome!