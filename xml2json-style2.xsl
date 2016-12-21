<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

    <!-- Turn off auto-insertion of <?xml> tag and set indenting on -->
    <xsl:output method="text" encoding="utf-8" indent="yes"/>
    
    <!-- strip whitespace from whitespace-only nodes -->
    <xsl:strip-space elements="*"/>
     
    <!-- handles elements -->
    <xsl:template match="*">
        <!-- element name -->
        <xsl:text>{ "e" : "</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>"</xsl:text>
        <xsl:variable name="ctr" select="count(*)"/>
        <xsl:variable name="actr" select="count(@*)"/>                    
        <xsl:variable name="tctr" select="count(text())"/>
        <!-- there will be contents so start an object -->
        <xsl:if test="$actr > 0">
            <xsl:text>, "@" : { </xsl:text>
            <xsl:apply-templates select="@*"/>
            <xsl:text>}</xsl:text>
        </xsl:if>
        <!-- handle element nodes -->
        <xsl:choose>
            <xsl:when test="$ctr = 1">
                <xsl:text>, "c" : </xsl:text>
                <xsl:apply-templates select="*"/>
            </xsl:when>
            <xsl:when test="$ctr > 1">
                <xsl:text>, "c" : [ </xsl:text>
                <xsl:apply-templates select="*"/>
                <xsl:text> ]</xsl:text>
            </xsl:when>
        </xsl:choose>
        <!-- handle text nodes -->
        <xsl:choose>
            <xsl:when test="$tctr = 1">
                <xsl:text>, "$" : </xsl:text>
                <xsl:apply-templates select="text()" />
            </xsl:when>
            <xsl:when test="$tctr > 1">
                <xsl:text>, "$" : [ </xsl:text>
                <xsl:apply-templates select="text()" />
                <xsl:text> ]</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:text> }</xsl:text>
        <xsl:if test="position() != last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>
    
    <!-- this template handle text nodes -->
    <xsl:template match="text()">
        <xsl:variable name="t" select="." />
        <xsl:choose>
            <!-- test to see if it is a number -->
            <xsl:when test="string(number($t)) != 'NaN'">
                <xsl:value-of select="$t"/>
            </xsl:when>
            <!-- deal with any case booleans -->
            <xsl:when test="translate($t, 'TRUE', 'true') = 'true'">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:when test="translate($t, 'FALSE', 'false') = 'false'">
                <xsl:text>false</xsl:text>
            </xsl:when>
            <!-- must be text -->
            <xsl:otherwise>
                <xsl:text>"</xsl:text>
                <xsl:value-of select="$t"/>
                <xsl:text>"</xsl:text>                
            </xsl:otherwise>
        </xsl:choose>        
        <xsl:if test="position() != last()">
            <xsl:text>, </xsl:text>
        </xsl:if>        
    </xsl:template>
    
    <!-- this template handles attribute nodes -->
    <xsl:template match="@*">
        <!-- attach prefix to attribute names -->
        <xsl:text>"</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>" : </xsl:text>
        <xsl:variable name="t" select="." />
        <xsl:choose>
            <xsl:when test="string(number($t)) != 'NaN'">
                <xsl:value-of select="$t"/>
            </xsl:when>
            <xsl:when test="translate($t, 'TRUE', 'true') = 'true'">
                <xsl:text>true</xsl:text>
            </xsl:when>
            <xsl:when test="translate($t, 'FALSE', 'false') = 'false'">
                <xsl:text>false</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>"</xsl:text>
                <xsl:value-of select="$t"/>
                <xsl:text>"</xsl:text>                
            </xsl:otherwise>
        </xsl:choose>        
        <xsl:if test="position() != last()">
            <xsl:text>, </xsl:text>
        </xsl:if>        
    </xsl:template>
        
</xsl:stylesheet>