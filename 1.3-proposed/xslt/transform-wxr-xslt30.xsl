<?xml version="1.0" encoding="UTF-8" ?>
<!--
	Transform a WXR 1.0, 1.1 or 1.2 instance into WXR 1.3-proposed.
	
	See https://github.com/pbiron/wxr/1.3-proposed.

	This transform must be:

	1. idempotent (i.e., eat it's own dogfood)
	   that is, transform( WXR 1.0 instance ) == transform( transform( WXR 1.0 instance ) ), etc
	2. be streamable in a compliant XSLT 3.0 processor (of which there are none in a vanilla PHP install)

	This transform is functionally identical to the XSLT 2.0 transform, but is guaranteed-streamable
	according to https://www.w3.org/TR/xslt-30/#dt-guaranteed-streamable.

	This means that both the 1.0 and 2.0 versions are also streamable, but there is no
	way to inform XSLT 1.0 or 2.0 processors of that fact.
  -->
<xsl:transform
		xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
		xmlns:wxr='http://wordpress.org/export/'
		version='3.0'>

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
		Declare this a streamable transform
	  -->
	<xsl:mode streamable='yes'/>

	<!--
		$wxr_version is the version of WXR that we are transforming into
	  -->
	<xsl:variable name='wxr_version' select='1.3'/>
	<!--
		$wxr_base_namespaceURI is the leading string of the WXR 1.0, 1.1 and 1.2 namespace URIs.
	  -->
	<xsl:variable name='wxr_base_namespaceURI' select='"http://wordpress.org/export/"'/>

	<!--
		The identity transform (i.e., copy the input to the output)

		Strictly speaking, this isn't the identity transform since it also adds rss/@wxr:version
		and strips namespace nodes for the old WXR namespaces
	  -->
	<xsl:template match='@*|node()'>
		<xsl:copy copy-namespaces='no'>
			<!-- copy namespace nodes, except those for any of the old WXR namespaces -->
			<xsl:copy-of select='namespace::*[not( starts-with( ., $wxr_base_namespaceURI ) ) ]'/>

			<!-- add rss/@wxr:version -->
			<xsl:if test='not( parent::* ) and local-name() = "rss" and namespace-uri() = ""'>
				<xsl:attribute name='wxr:version'><xsl:value-of select='$wxr_version'/></xsl:attribute>
			</xsl:if>

			<!--
				Note: because of the rules for streamability of union expressions
				(see https://www.w3.org/TR/xslt-30/#streamability-of-union-expressions)
				we have to have separate xsl:apply-templates for attributes and
				other nodes
			  -->
			<!-- copy any attributes -->
			<xsl:apply-templates select='@*'/>

			<!-- copy any child nodes, including non-element nodes -->
			<xsl:apply-templates select='node()'/>
		</xsl:copy>
	</xsl:template>

	<!--
		This is the meat of the transform

		It rewrites some of the WXR element local-names() and puts elements from any of the
		old WXR namespaces into the WXR 1.3 namespace.  For wp:tag and wp:category elements,
		it also adds an appropriate	wxr:taxonomy child.

		@todo check the order of the xsl:when statements below and see if they can
		be simplified
	  -->
	<xsl:template match='*[starts-with( namespace-uri(), $wxr_base_namespaceURI )]'>
		<xsl:choose>
			<xsl:when test='local-name() eq "encoded"'>
				<!-- rewrite excerpt:encoded to the standard RSS description element -->
				<description><xsl:apply-templates/></description>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name='local_name'>
					<xsl:choose>
						<!-- first, start with the simple renames -->
						<xsl:when test='local-name() eq "tag" or local-name() eq "category"'>term</xsl:when>
						<xsl:when test='local-name() eq "author"'>user</xsl:when>
						<xsl:when test='local-name() eq "termmeta" or local-name() = "postmeta" or local-name() = "commentmeta"'>meta</xsl:when>
						<xsl:when test='local-name() eq "category_nicename"'>slug</xsl:when>

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
					<!-- copy any attributes -->
					<xsl:apply-templates select='@*'/>
		
					<!-- copy any child nodes, including non-element nodes -->
					<xsl:apply-templates select='node()'/>
		
					<!-- add the appropriate wxr:taxonomy child for wp:tag and wp:category -->
					<xsl:choose>
						<xsl:when test='local-name() eq "tag"'>
							<wxr:taxonomy>post_tag</wxr:taxonomy>
						</xsl:when>
						<xsl:when test='local-name() eq "category"'>
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
		<xsl:attribute name='wxr:slug' select='.'/>
	</xsl:template>

	<!--
		add @wxr:wp_version to RSS's generator
	  -->
	<xsl:template match='generator'>
		<generator wxr:wp_version='{substring-after( ., "?v=" )}'/>
	</xsl:template>

	<!--
		strip wp:wxr_version (since we using /rss/@wxr:version) and wp:base_blog_url
		(since it is redundant with /rss/channel/link)
	-->
	<xsl:template match='*[starts-with( namespace-uri(), "http://wordpress.org/export/" ) and
		( local-name() eq "wxr_version" or local-name() eq "base_blog_url" )]' priority='100'/>

	<!--
		strip item/description (since are rewriting excerpt:encoded into description).
		the "not( @wxr:version ) predicate is to ensure that this transform is idempotent
		(i.e., we should NOT strip item/description if we're asked to transform a WXR 1.3 instance)
	-->
	<xsl:template match='/rss[not( @wxr:version )]/channel/item/description'/>

	<!--
		strip item/pubDate
	-->
	<xsl:template match='item/pubDate'/>
</xsl:transform>