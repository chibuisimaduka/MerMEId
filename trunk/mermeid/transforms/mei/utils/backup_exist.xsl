<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	       xmlns:e="http://exist.sourceforge.net/NS/exist"
	       version="1.0">

  <xsl:param name="base_uri"  select="'http://kb-cop.kb.dk:8080/exist/rest'"/>
  <xsl:variable name="collection" select="/e:result/e:collection/@name" />

  <xsl:output encoding="UTF-8"
	      method="text"/>

  <xsl:template match="/">#!/bin/sh

if ! [ -d <xsl:value-of select="concat('.',$collection)"/> ]; then
<xsl:value-of select="concat('mkdir -p .',$collection)"/><xsl:text>
fi
</xsl:text>
<xsl:for-each select="//e:resource">
<xsl:sort select="@name"/>
<xsl:value-of 
select="concat('lwp-mirror ',$base_uri,$collection,'/',@name,' .',
		  $collection,'/',@name)"/><xsl:text>
</xsl:text></xsl:for-each>

</xsl:template>



</xsl:transform>


