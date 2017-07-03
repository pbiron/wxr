# XML Schema for WordPress Export RSS (WXR) 1.2

An XML Schema 1.1 schema for WXR 1.2.

## Description

This schema is intended to serve primarily as documentation of WXR 1.2.

### Purpose
			
There are 2 primary audiences for this schema:
1. WP Core contributors involved in maintaining the export/import code (i.e., to serve as a check for keeping the exporter/importer in sync when making modifications)
1. plugin authors who want to write their own export/import code.

### Not Purpose
		
This schema is NOT intended to be used for run-time validation during an import.  The primary reason for this is
that the XML parsers that are included in PHP do NOT support XML Schema 1.1 (because they are
all based on libxml, which only supports validation against XML Schema 1.0, which is not expressive
enough to capture the rules of RSS, so validating with a 1.0 schema would be useless, or worse) :-)

## Documentation

HTML browsable documentation generated from this schema is available at
[WXR Schema Documentation](http://sparrowhawkcomputing.com/wxr/1.2/docs/wxr.html).

If I could figure out how to add that documentation as wiki pages here on GitHub I would, but I can't,
so I won't :-)

## Changelog

### 0.2

* Fixed the open content constructs to better capture RSS's extension rules
* Added a number of uniqueness constraints
* Updated sample WXR documents

### 0.1

* Init commit

## Developer Notes

Even though this schema is **not** intended for run-time validation during an import, to test it
out you obviously need to validate WXR documents against it.

In developing this schema, I validated WXR documents using the following XML Schema 1.1 processors:

1. [Saxon EE 9.7.0.15](http://saxonica.com/products/products.xml) (commercial)

**Note:** I have also tried [Xerces2-J 2.11.0](http://xerces.apache.org/#xerces2-j) (open source), but it reports an
error in the schema documents.  I have open a bug report with xerces,
[incorrect flagging of violation of cos-all-limited](https://issues.apache.org/jira/browse/XERCESJ-1680).

You can use any XML Schema processor you'd like. In fact, it would be helpful to test this schema against the widest possible array of schema processors, so if you have access to processors other than those above, by all means, use them.  But be sure that the processor you use implements [XML Schema 1.1](https://www.w3.org/TR/xmlschema11-1).

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

The [sample-wxr-documents](sample-wxr-documents) directory contains some sample WXR 1.2 instances that can be used for you to test this schema out.  For example, `small-export-ns-aware.xml` is a modified version of the `small-export.xml` that is part of the unit-test harness for WP.  The modifications introduce many different namespace prefixes for the WXR namespace.  That document would fail to import with the standard importer (which is not namespace-aware) but imports like a charm with the importer at [WordPress Importer Feature Plugin](https://github.com/pbiron/WordPress-Importer) (which is namespace-aware).

It would be **very** helpful for the development/maintainence of this schema if folks could contribute sample WXR documents to this project.  Just submit a pull request to add them to the [sample-wxr-documents](sample-wxr-documents) directory.

**Note:** if you submit sample WXR documents, be sure they have been properly **ANONYMIZED** (that is, they do **not** contain real author/commenter data nor post content that you do not want to be publicly available).

## Issues

The schema document(s) is sprinkled throughout with `xs:annotation/xs:documentation` elements.
Most are intended to document the element/type they are children of.  However, some
contain `@todo`'s where I know there is still something to do or where there is an open
question about how something should be done.  Many of these `@todo`'s note that I intend
to open trac tickets on a number of topics.

I'd be **very** interested in general feedback from the WP community on this schema **before**
before I open any of those tickets.

If you have comments/suggestions, please open an issue here.  General "discussion" issues
are welcome!