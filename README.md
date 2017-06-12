# XML Schema for WordPress Export RSS (WXR)

An XML Schema 1.1 schema for WXR.

## Description

This schema is intended to serve primarily as documentation of WXR.

### Purpose
			
There are 2 primary audiences for this schema:
1. WP Core contributors involved in maintaining the export/import code (i.e., to serve as a check for keeping the exporter/importer in sync when making modifications)
1. plugin authors who want to write their own export/import code.

### Not Purpose
		
This schema is NOT intended to be used for run-time validation during an import.  The primary reason for this is
that the XML parsers that are included in PHP do NOT support XML Schema 1.1 (because they are
all based on libxml, which only supports XML Schema 1.0) :-)

## Documentation

HTML browsable documentation generated from this schema is available at
[WXR Schema Documentation](http://sparrowhawkcomputing.com/wxr/1.2/docs/wxr.html).

If I could figure out how to add that documentation as wiki pages here on GitHub I would, but I can't,
so I won't :-)

## Changelog

### 0.1

* Init commit

## Developer Notes

Even though this schema is **not** intended for run-time validation during an import, to test it
out you obviously need to validate WXR documents against it.

In developing this schema, I validated WXR documents using the following XML Schema 1.1 processors:

1. [Xerces2-J 2.11.0](http://xerces.apache.org/#xerces2-j) (open source)
1. [Saxon EE](http://saxonica.com/products/products.xml) (commercial)

You can use any XML Schema processor you'd like. In fact, it would be helpful to test this schema against the widest possible array of schema processors, so you have access to processors other than those above, by all means, use them.  But be sure that the processor you use implements [XML Schema 1.1](https://www.w3.org/TR/xmlschema11-1).

Depending on how you run your tests, it can be useful to add the following to the WXR documents produced by the WP exporter:

```xml
<rss version="2.0"
	xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
	xsi:schemaLocation='http://wordpress.org/export/1.2/ wxr.xsd'
	xsi:noNamespaceSchemaLocation='rss-20.xsd'
   ...
</rss>
```

### Sample WXR Documents

The [sample-wxr-documents](1.2/sample-wxr-documents) directory contains some sample WXR 1.2 instances that can be used for you to test this schema out.  For example, `small-ns-export.xml` is a modified version of the `small-export.xml` that is part of the unit-test harness for WP.  The modifications many different namespace prefixes for the WXR namespace.

If you have WXR documents that you'd like to contribute to this project I would love to have them.  Just submit a pull request to add them to the `sample-wxr-documents` directory.

**Note:** if you submit sample WXR documents, be sure they have been properly **ANONYMIZED** (that is, they do **not** contain real author/commenter data nor post content that you do not want to be publicly available).

## Issues

The schema document(s) is sprinkled throughout with xs:annotation/xs:documentation elements.
Most are intended to document the element/type they are children of.  However, some
contain `@todo`'s where I know there is still something to do or where there is an open
question about how something should be done.  Many of these `@todo`'s note that I intend
to open trac tickets on a number of topics.

I'd be **very** interested in general feedback from the WP community on this schema **before**
before I open any of those tickets.

If you have comments/suggestions, please open an issue here.  General "discussion" issues
are welcome!

To start with, I only created a schema for WXR 1.2.  If the WP community finds this
helpful, I can easily create schemas for WXR 1.0 and 1.1.  If you'd like them, just open an issue requesting such.
