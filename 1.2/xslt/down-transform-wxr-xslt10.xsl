<?xml version="1.0" encoding="UTF-8" ?>
<!--
	Transform a WXR 1.3-proposed instance into WXR 1.2.
	
	See https://github.com/pbiron/wxr/1.3-proposed and https://github.com/pbiron/wxr/1.2.

	This transform must be:

	1. idempotent (i.e., eat it's own dogfood)
	   that is, transform( WXR 1.3-proposed instance ) == transform( transform( WXR 1.3-proposed instance ) ), etc
	
	I wrote this transform for several reasons:
	
	1. To prove (to myself more than others) that WXR 1.2 instances were roundtrip-able (which is different
			than any of these transforms being idempotent) through WXR 1.3-proposed.  However, note that:
		a. doing the roundtrip does NOT produce instances that have identical Infosets
		b. but, the content that is actually used by the standard importer is preserved,
			so all is well.
	2. In the unlikely event that WXR 1.3-proposed (or something close to it) is accepted into core
			BUT the importer redux is not, this transform can be incorporated into the standard
			importer so that it could handle WXR 1.3-proposed instances
		a. 	Note that, unlike the WXR 1.0, 1.1 and 1.2 to WXR 1.3-proposed transforms, this one is
			NOT guarenteed-streamable.  But that is OK, since the standard importer already has
			the entire WXR instance in-memory anyway.  Hence, I don't plan on writting an XSLT 3.0 nor
			a PHP implementation of this transform.
  -->
<xsl:transform
		xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
		xmlns:wxr='http://wordpress.org/export/'
		xmlns:wp='http://wordpress.org/export/1.2/'
		xmlns:excerpt='http://wordpress.org/export/1.2/excerpt/'
		exclude-result-prefixes='wxr'
		version='1.0'>

	<!--
		Output the results as indented XML :-)
	  -->
	<xsl:output
		method='xml'
		indent='yes'/>

	<!--
		Strip unnecessary whitespace from the source document when generating output
	  -->
	<xsl:strip-space elements='*'/>

	<!--
		$wxr_12_namespaceURI namespaceURI for WXR 1.3-proposed.
	  -->
	<xsl:variable name='wxr_13_namespaceURI' select='"http://wordpress.org/export/"'/>
	<!--
		$wxr_12_namespaceURI namespaceURI for WXR 1.3-proposed.
	  -->
	<xsl:variable name='wxr_12_namespaceURI' select='"http://wordpress.org/export/1.2/"'/>
	<!--
		$wxr_excerpt_namespaceURI namespaceURI
	  -->
	<xsl:variable name='wxr_excerpt_namespaceURI' select='"http://wordpress.org/export/1.2/excerpt/"'/>
	<!--
		$dc_namespaceURI namespaceURI for Dublin Core.
	  -->
	<xsl:variable name='dc_namespaceURI' select='"http://purl.org/dc/elements/1.1/"'/>
	<!--
		$content_namespaceURI namespaceURI for RSS Content Profile.
	  -->
	<xsl:variable name='content_namespaceURI' select='"http://purl.org/rss/1.0/modules/content/"'/>
	
	<!--
		The identity transform (i.e., copy the input to the output)

		Strictly speaking, this isn't the identity transform since it also adds namespace
		decls for WXR 1.2 and WXR:excerpt and strips any extension namespace decls
	  -->
	<xsl:template match='@*|node()'>
		<xsl:copy>
			<!-- copy any attributes and elements -->
			<xsl:apply-templates select='@*|node()'/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match='*' priority='10'>
		<xsl:element name='{name()}' namespace='{namespace-uri()}'>
			<xsl:call-template name='strip_unused_namespace_nodes'/>
			
			<xsl:apply-templates select='@*|node()'/>
		</xsl:element>
	</xsl:template>
	
	<!--
		Add namespace decls for WXR 1.2 and 1.2-excerpt
	  -->
	<xsl:template match='/rss' priority='11'>
		<xsl:choose>
			<xsl:when test='not( @wxr:version )'>
				<xsl:apply-templates select='/rss' mode='already'/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:comment>1.3-proposed to 1.2</xsl:comment>
				<rss xmlns:wp='http://wordpress.org/export/1.2/'>
					
					<xsl:call-template name='strip_unused_namespace_nodes'/>
					
					<xsl:apply-templates select='@*|node()'/>
				</rss>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!--
		Strip unused namespace nodes
		
		While this isn't necessary, it makes the result instances "look" closer to
		what folks who are not fluent in XML Namespaces expect them to be.
	  -->
	<xsl:template name='strip_unused_namespace_nodes'>
		<xsl:copy-of select='namespace::*[. = $wxr_12_namespaceURI or
			. = $wxr_excerpt_namespaceURI or . = $dc_namespaceURI or
			. = $content_namespaceURI]'/>		
	</xsl:template>

	<!--
		Add WXR 1.2 elements at the channel level that are not present in WXR 1.3-proposed
	  -->
	<xsl:template match='/rss/channel' priority='11'>
		<channel>
			<wp:wxr_version>1.2</wp:wxr_version>
			<wp:base_blog_url><xsl:value-of select='/rss/channel/link'/></wp:base_blog_url>
			
			<xsl:if test='not( wxr:site_url )'>
				<wp:base_site_url><xsl:value-of select='/rss/channel/link'/></wp:base_site_url>
			</xsl:if>

			<xsl:apply-templates/>
		</channel>
	</xsl:template>

	<!--
		This is the meat of the transform.
		
		It rewrites some of the WXR element local-names() and puts them into the WXR 1.2 namespace.
	  -->
	<xsl:template match='wxr:*' priority='11'>
		<xsl:variable name='local_name'>
			<xsl:choose>
				<xsl:when test='local-name() = "user"'>
					<xsl:text>author</xsl:text>
				</xsl:when>
				<xsl:when test='local-name() = "site_url"'>
					<xsl:text>base_site_url</xsl:text>
				</xsl:when>
				<xsl:when test='local-name() = "term"'>
					<xsl:choose>
						<xsl:when test='wxr:taxonomy[. = "category"]'>
							<xsl:text>category</xsl:text>
						</xsl:when>
						<xsl:when test='wxr:taxonomy[. = "post_tag"]'>
							<xsl:text>tag</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>term</xsl:text>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test='local-name() = "key" or local-name() = "value"'>
					<xsl:text>meta_</xsl:text>
					<xsl:value-of select='local-name()'/>
				</xsl:when>
				<xsl:when test='parent::*[local-name() = "user"]'>
					<xsl:text>author_</xsl:text>
					<xsl:value-of select='local-name()'/>
				</xsl:when>
				
				<xsl:when test='parent::wxr:term'>
					<xsl:choose>
						<xsl:when test='preceding-sibling::wxr:taxonomy[. = "category"] or
								following-sibling::wxr:taxonomy[. = "category"]'>
							<xsl:choose>
								<xsl:when test='local-name() = "description" or local-name() = "parent"'>
									<xsl:text>category_</xsl:text>
									<xsl:value-of select='local-name()'/>
								</xsl:when>
								<xsl:when test='local-name() = "slug"'>
									<xsl:text>category_nicename</xsl:text>
								</xsl:when>
								<xsl:when test='local-name() = "name"'>
									<xsl:text>cat_name</xsl:text>
								</xsl:when>
								<xsl:when test='local-name() = "id"'>
									<xsl:text>term_id</xsl:text>
								</xsl:when>
								<xsl:when test='local-name() = "meta"'>
									<xsl:text>termmeta</xsl:text>
								</xsl:when>
							</xsl:choose>
						</xsl:when>
						<xsl:when test='preceding-sibling::wxr:taxonomy[. = "post_tag"] or
								following-sibling::wxr:taxonomy[. = "post_tag"]'>
							<xsl:choose>
								<xsl:when test='local-name() = "id"'>
									<xsl:text>term_id</xsl:text>
								</xsl:when>
								<xsl:when test='local-name() = "meta"'>
									<xsl:text>termmeta</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>tag_</xsl:text>
									<xsl:value-of select='local-name()'/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<xsl:text>term_</xsl:text>
							<xsl:value-of select='local-name()'/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test='parent::wxr:comment'>
					<xsl:text>comment_</xsl:text>
					<xsl:value-of select='local-name()'/>
				</xsl:when>
				<xsl:when test='parent::item'>
					<xsl:choose>
						<xsl:when test='local-name() = "id" or local-name() = "name" or
								local-name() = "parent" or local-name() = "type" or
								local-name() = "password" or local-name() = "date" or
								local-name() = "date_gmt"'>
							<xsl:text>post_</xsl:text>
							<xsl:value-of select='local-name()'/>
						</xsl:when>
						<xsl:when test='local-name() = "meta"'>
							<xsl:text>postmeta</xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select='local-name()'/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select='local-name()'/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:element name='wp:{$local_name}'>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>

	<!--
		Rewrite item/description as excerpt:encoded
	  -->
	<xsl:template match='item/description' priority='11'>
		<excerpt:encoded>
			<xsl:apply-templates/>
		</excerpt:encoded>
	</xsl:template>
	
	<!--
		Rewrite item/category/@wxr:slug to item/category/@nicename
		
		Note: while this does NOT conform to the RSS spec, it is what
		WXR 1.2 uses.
	  -->
	<xsl:template match='item/category/@wxr:slug'>
		<xsl:attribute name='nicename'><xsl:value-of select='.'/></xsl:attribute>
	</xsl:template>

	<!--
		Strip /rss/@wxr:version and /rss/@wxr:plugins
	  -->
	<xsl:template match='/rss/attribute::*[namespace-uri() = "http://wordpress.org/export/" and
			( local-name() = "version" or local-name() = "plugins" )]'/>

	<!--
		Strip /rss/channel/docs
		
		According to the RSS spec we don't need to strip this.  But since the
		WXR 1.2 schema is primiarily for documentation purposes and this
		element is not included in channel's content model in that schema
		we strip it so that we can use the WXR 1.2 schema to validate results
		as a way to test this transform.
	  -->
	<xsl:template match='/rss/channel/docs' priority='11'/>
	
	<!--
		Strip wxr:taxonomy from wp:tag and wp:category
	  -->
	<xsl:template match='wxr:taxonomy[. = "post_tag" or . = "category"]' priority='20'/>

	<!--
		Strip any extension elements
		
		Note: Having starts-with( namespace-uri(), "http://wordpress.org/export/") in here helps
		to make this transform idempotent.
		
		Also note: we can't use the variables we declared above here...because XSLT 1.0
		(unlike XSLT 2.0 and 3.0) does not allow variable references in @match :-(
	  -->
	<xsl:template match='*[not( namespace-uri() = "" or
		starts-with( namespace-uri(), "http://wordpress.org/export/" ) or
		namespace-uri() = "http://purl.org/dc/elements/1.1/" or
		namespace-uri() = "http://purl.org/rss/1.0/modules/content/" )]' priority='100'/>

	<!--
		The identity transform (i.e., copy the input to the output)

		If the input instance is NOT a WXR 1.3-proposed, then
		just copy to the result tree.  This template is different from the
		"identity transform" above because it specifies a @mode.
	  -->
	<xsl:template match='node()|@*' mode='already'>
		<xsl:copy>
			<xsl:apply-templates select='node()|@*' mode='already'/>
		</xsl:copy>
	</xsl:template>
</xsl:transform>