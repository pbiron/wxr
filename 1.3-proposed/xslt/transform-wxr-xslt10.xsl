<?xml version="1.0" encoding="UTF-8" ?>
<!--
	Transform a WXR 1.0, 1.1 or 1.2 instance into WXR 1.3-proposed.
	
	See https://github.com/pbiron/wxr/1.3-proposed.

	This transform must be:

	1. idempotent (i.e., eat it's own dogfood)
	   that is, transform( WXR 1.0 instance ) == transform( transform( WXR 1.0 instance ) ), etc
	2. usable with a compliant XSLT 1.0 processor (e.g., the XSLTProcessor class in PHP)
  -->
<xsl:transform
		xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
		xmlns:wxr='http://wordpress.org/export/'
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
		$wxr_version is the version of WXR that we are transforming into
	  -->
	<xsl:variable name='wxr_version' select='1.3'/>
	<!--
		$wxr_base_namespaceURI is the leading string of the WXR 1.0, 1.1 and 1.2 namespace URIs.
		
		Setting this in a variable is less useful in an XSLT 1.0 transform than doing so
		in XSLT 2.0 and 3.0, since XSLT 1.0 does NOT allow variable references in xsl:template/@match,
		but I'm doing so anyway just for consistency with the other versions for this
		transform.
	  -->
	<xsl:variable name='wxr_base_namespaceURI' select='"http://wordpress.org/export/"'/>
	
	<!--
		The identity transform (i.e., copy the input to the output)

		Strictly speaking, this isn't the identity transform since it strips namespace
		nodes for the old WXR namespaces
	-->
	<xsl:template match='@*|node()'>
		<xsl:copy>
			<!-- copy namespace nodes, except those for any of the old WXR namespaces -->
			<xsl:copy-of select='namespace::*[not( starts-with( ., $wxr_base_namespaceURI ) ) ]'/>

			<!-- copy any attribute and child nodes, including non-element nodes -->
			<xsl:apply-templates select='@*|node()'/>
		</xsl:copy>
	</xsl:template>

	<!--
		Part of the identity transform for the /rss element
	  -->
	<xsl:template match='/rss' priority='10'>
		<!--
			create a literal result element for /rss with a namespace decl for WXR
			this is necessary in XSLT 1.0 because the "strip namespace nodes for old WXR namespaces"
			code also strips it for the root node as well :-(
		  -->
		<rss xmlns:wxr='http://wordpress.org/export/'>
			<!-- copy namespace nodes, except those for any of the old WXR namespaces -->
			<xsl:copy-of select='namespace::*[not( starts-with( ., $wxr_base_namespaceURI ) ) ]'/>

			<!-- add rss/@wxr:version -->
			<xsl:attribute name='wxr:version'><xsl:value-of select='$wxr_version'/></xsl:attribute>
			
			<!-- copy any attribute and child nodes, including non-element nodes -->
			<xsl:apply-templates select='@*|node()'/>
		</rss>
	</xsl:template>
	
	<!--
		Part of the indentity transform for elements that are NOT in the old WXR namespaces,
		and strip namespace decls for those old WXR namespaces
	  -->
	<xsl:template match='*[not( starts-with( namespace-uri(), "http://wordpress.org/export/" ) )]'>
		<!-- create a literal result element -->
		<!--
			Note: In all of the XSLT processors I've tested this with, using @name='{local-name()}'
			results in unnecessarily redundant namespace decls; using @name='{name()}' prevents that
		  -->
		<xsl:element name='{name()}' namespace='{namespace-uri()}'>
			<!-- strip namespace decls for the old WXR namespaces -->
			<xsl:copy-of select='namespace::*[not( starts-with( ., $wxr_base_namespaceURI ) ) ]'/>

			<!-- copy any attribute and child nodes, including non-element nodes -->
			<xsl:apply-templates select='@*|node()'/>
		</xsl:element>
	</xsl:template>

	<!--
		This is the meat of the transform

		It rewrites some of the WXR element local-names() and puts elements from any of the
		old WXR namespaces into the WXR 1.3 namespace (stripping namespace decls for the old
		WXR namespaces).  For wp:tag and wp:category elements, it also adds an appropriate
		wxr:taxonomy child.
	  -->
	<xsl:template match='*[starts-with( namespace-uri(), "http://wordpress.org/export/" )]'>
		<xsl:choose>
			<xsl:when test='local-name() = "encoded"'>
				<!-- rewrite excerpt:encoded to the standard RSS description element -->
				<description><xsl:apply-templates/></description>
			</xsl:when>
			<xsl:otherwise>
				<!-- first, rewrite the local-name() -->
				<xsl:variable name='local_name'>
					<xsl:choose>
						<!-- first, start with the simple renames -->
						<xsl:when test='local-name() = "tag" or local-name() = "category"'>term</xsl:when>
						<xsl:when test='local-name() = "author"'>user</xsl:when>
						<xsl:when test='local-name() = "termmeta" or local-name() = "postmeta" or local-name() = "commentmeta"'>meta</xsl:when>
						<xsl:when test='local-name() = "category_nicename"'>slug</xsl:when>
						
						<!-- strip leading string before "_" in SOME local-name()'s -->
						<xsl:when test='starts-with( local-name(), "author_" ) or
							starts-with( local-name(), "post_" ) or
							starts-with( local-name(), "meta_" ) or
							( starts-with( local-name(), "comment_" ) and not( local-name() = "comment_status" ) ) or
							starts-with( local-name(), "base_" ) or
							( parent::*[starts-with( namespace-uri(), $wxr_base_namespaceURI )][
							local-name() = "tag" or local-name() = "category" or local-name() = "term"
							] and contains( local-name(), "_" ) )'>
							<xsl:value-of select='substring-after( local-name(), "_" )'/>
						</xsl:when>
						
						<!-- local-name() is unchanged -->
						<xsl:otherwise>
							<xsl:value-of select='local-name()'/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>

				<!-- now, create the element with the computed local-name() in the WXR 1.3 namespace -->
				<xsl:element name='wxr:{$local_name}'>
					<!-- copy any attribute and child nodes, including non-element nodes -->
					<xsl:apply-templates select='@*|node()'/>
		
					<!-- add the appropriate wxr:taxonomy child for wp:tag and wp:category -->
					<xsl:choose>
						<xsl:when test='local-name() = "tag"'>
							<wxr:taxonomy>post_tag</wxr:taxonomy>
						</xsl:when>
						<xsl:when test='local-name() = "category"'>
							<wxr:taxonomy>category</wxr:taxonomy>
						</xsl:when>
					</xsl:choose>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--
		rewrite category/@nicename into RSS conforming category/@wxr:slug
	-->
	<xsl:template match='category/@nicename'>
		<xsl:attribute name='wxr:slug'><xsl:value-of select='.'/></xsl:attribute>
	</xsl:template>

	<!--
		add @wxr:wp_version to RSS's generator
	  -->
	<xsl:template match='generator' priority='10'>
		<generator wxr:wp_version='{substring-after( ., "?v=" )}'/>
	</xsl:template>
	
	<!--
		strip wp:wxr_version (since we using /rss/@wxr:version) and wp:base_blog_url
		(since it is redundant with /rss/channel/link)
	-->
	<xsl:template match='*[starts-with( namespace-uri(), "http://wordpress.org/export/" ) and
		( local-name() = "wxr_version" or local-name() = "base_blog_url" )]' priority='100'/>
	
	<!--
		strip item/description (since are rewriting excerpt:encoded into description).
		the "not( @wxr:version ) predicate is to ensure that this transform is idempotent
		(i.e., we should NOT strip item/description if we're asked to transform a WXR 1.3 instance)
	-->
	<xsl:template match='/rss[not( @wxr:version )]/channel/item/description' priority='10'/>

	<!--
		strip item/pubDate
	-->
	<xsl:template match='item/pubDate' priority='10'/>
</xsl:transform>