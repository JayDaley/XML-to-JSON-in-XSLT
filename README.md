<h3>Introduction</h3>

There isn't a single translation for XML to JSON but several, each with different characteristics.  Choosing the right one depends largely on two things, the XML that you want to translate and how you will write code to manipulate the JSON.  If you set certain standards for the XML you will be using then this can simplify the JSON produced and make it easier to manipulate.

This article walks throught the various choices you have in JSON output and provides example XSLT code for the various choices to form a construction kit that you can use to assemble an XSLT that works the way you want it to.  There are some complete examples at the end that bundle together some common choices.

BTW the JSON spec (<a href="http://tools.ietf.org/html/rfc4627">RFC 4627</a>) talks about name/value pairs but I'm going to use the more normal terminology of key/value pairs.

<h3>Design goals</h3>

Given the wide variety of ways to encode XML as JSON, these goals narrow down the choices for this article

<ol>
<li>As much of the XML data structure is preserved as possible, except where you choose to drop ordering.  This implies two fundamental characteristics of all of the translations presented here:
<ul><li>Elements are encapsulated as JSON objects.</li>
<li>The translations are reversible (with the exception of ordering if you decide to drop that). I'm not going to cover how to do the reverse translation as this is focused on XSLT and that can only process XML.</li></ul></li>

<li>The code needs to comply with the XSLT 1.0 spec not the 2.0 spec.  While using 2.0 would be easier, at the time of writing it is basically only supported in one open source processor, Saxon, which limits its usefulness.</li>

<li>Namespaces are transparent, which means that element/attribute names with namespaces have those namespaces preserved, but namespace directives are ignored and do not make it into the JSON.</li>
</ol>

<h3>Modelling the JSON</h3>

There are two obvious different ways in which a developer might manipulate the resultant JSON.  

Style 1 is where the where the developer knows what JSON to expect and will be addressing elements and attributes by name and pulling out the values.  For these the easiest implementation has the element name as a key for an object that contains the entire element contents and attributes like this

```javascript
{ element : { child elements , "$" : text, attributes } }
```

Style 2 is where the element and attribute names are not well known and need to be discovered.  We could use the convention of the translation to allow the developer to quickly discover element, attributes and content or we could using well known keys to guarantee that these parts can be discovered quickly like this

```javascript
{ "e" : element, "c" : { child elements }, "$" : text, "@" : { attributes } }
```

These two styles are not entirely clear cut as we could mix and match some choices between the two, though doing so may not provide any benefits, like these examples

```javascript
{ element : { child elements }, "$" : text, attributes }
{ element : { child elements }, "$" : text, "@" : {attributes} } 
{ element : { child elements, "@" : {attributes}  }, "$" : text}
```

For this article I will concentrate only on style 1 and style 2, but implementing a mixed style should be pretty easy using the code supplied.

To complicate things there are a number of characteristics of your XML, which if you wish to preserve in the JSON will mean the JSON becomes quite different from how it would look otherwise.  These characteristics are
<ul>
<li>Multiple text pieces</li>
<li>Ordering (JSON objects are unordered and libraries generally use hashes to store them thereby almost guaranteeing they will be out of order)</li>
<li>Multiple child elements with the same name</li>
<li>Simple XML (in which case we could simplify the JSON dramatically)</li>
</ul>

<h3>Element names</h3>

The choice here is between element names becoming keys or element names becoming the value of a well known key (like "e").  Here is an example of an element and the two representations:

```xml
<myelement>...</myelement>
```

in style 1 that translates to

```javascript
{ "myelement" : ... }
```

using this XSLT

```xml
<xsl:text>{ "</xsl:text>
<xsl:value-of select="name()"/>
<xsl:text>" :  </xsl:text>
```

in style 2 that translates to

```javascript
{ "e" : "myelement", ... }
```

produced by this XSLT 

```xml
<xsl:text>{ "e" : "</xsl:text>
<xsl:value-of select="name()"/>
<xsl:text>" }</xsl:text>
```

<h3>Empty elements</h3>

Empty elements are pretty straightforward as their contents can be represented with a null.  Take the following example

```xml
<empty />
```

in style 1 that translates to

```javascript
{ "empty" : null }
```

produced by this XSLT

```xml
<xsl:template match="node()">
    <xsl:text>{ "</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>" : </xsl:text>
    <xsl:if test="count(node()) = 0">
        <xsl:text>null</xsl:text>
    </xsl:if>
    <xsl:text> }</xsl:text>
</xsl:template>
```

in style 2 the simplest thing to do is just omit whatever keys hold the content.  If you insist on identifying empty elements with well known keys then it tranlates to (though you need to choose whether to make null the value for "c" or "$" or both)

```javascript
{ "e" : "empty", "c" : null }
```

produced by this XSLT

```xml
<xsl:template match="node()">
    <xsl:text>{ "e" : "</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>" , "c" : </xsl:text>
    <xsl:if test="count(node()) = 0">
        <xsl:text>null</xsl:text>
    </xsl:if>
    <xsl:text> }</xsl:text>
</xsl:template>
```

<h3>Single child elements</h3>

Child elements become nested objects.  So with this example:

```xml
<outer><inner/></outer>
```

in style 1 that translates to

```javascript
{ "outer" : { "inner" : null } }
```

produced by the following XSLT

```xml
<xsl:template match="node()">
    <xsl:text>{ "</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>" : </xsl:text>
    <xsl:choose>
        <xsl:when test="count(node()) = 0">
            <xsl:text>null</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:apply-templates />
        </xsl:otherwise>
    </xsl:choose>        
    <xsl:text> }</xsl:text>
</xsl:template>
```

in style 2 using the new key of "c" for "child elements" that translates to

```javascript
{ "e" : "outer", "c" : { "e" : "inner", "c" : null } }
```

produced by the following XSLT

```xml
<xsl:template match="node()">
    <xsl:text>{ "e" : "</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>" , "c" : </xsl:text>
    <xsl:choose>
        <xsl:when test="count(node()) = 0">
            <xsl:text>null</xsl:text>
        </xsl:when>
        <xsl:otherwise>
             <xsl:apply-templates />
        </xsl:otherwise>
    </xsl:choose>
    <xsl:text> }</xsl:text>
</xsl:template>
```

<h3>Single text</h3>

XML has two types of text, parsed and unparsed character data, but in XSLT that difference is lost and the data is returned as text, which fits nicely with JSON as that only has the one string type.

In style 1 we could simplify text only nodes by making the text the value of the element name as key.  Take this example

```xml
<textelement>some text</textelement>
```

in style 1 the simplified version translates as

```javascript
{ "textelement" : "some text" }
```

produced by the following XSLT

```xml
<xsl:text>{ "</xsl:text>
<xsl:value-of select="name()"/>
<xsl:text>" :  "</xsl:text>
<xsl:value-of select="."/>
<xsl:text>" }</xsl:text>
```

in style 2 using the well known of "$" translates to

```javascript
{ "e" : "textelement", "$" : "some text" }
```

produced by the following XSLT

```xml
<xsl:text>{ "e" : "</xsl:text>
<xsl:value-of select="name()"/>
<xsl:text>" , "$" : "</xsl:text>
<xsl:value-of select="."/>
<xsl:text>" }</xsl:text>
```

<h3>Multiple text</h3>

It is possible to have more that one piece of text inside an XML element, each one of which will be returned independently by XSLT.  If you use a well known key for text values then you can theoretically reuse it multiple times as keys in JSON do not need to unique (see RFC 4627 section 2.2 if you don't believe me), but most JSON libraries will probably not support that so I'm not going to illustrate that option.

Instead the two options to looks at are combine all the text together or representing them individually in a list.

For example, the text in

```xml
<mytext>First part<inner />second part</mytext>
```

can be represented as the text added together into one string

```javascript
"First partsecondpart"
```

produced by the following XSLT

```xml
<xsl:template match="*">
    <xsl:text>, "$" : "</xsl:text>
    <xsl:apply-templates select="text()"/>
    <xsl:text>"</xsl:text>
</xsl:template>
    
<xsl:template match="text()">
    <xsl:value-of select="."/>
</xsl:template>
```

or in a list of the different parts

```javascript
[ "First part", "second part" ]
```

produced by the following XSLT

```xml
<xsl:template match="*">
    <xsl:text>, "$" : [ </xsl:text>
    <xsl:apply-templates select="text()"/>
    <xsl:text> ]</xsl:text>
</xsl:template>
    
<xsl:template match="text()">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>"</xsl:text>
    <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
    </xsl:if>        
</xsl:template>
```

<h3>Multiple numbers, booleans and text</h3>

XML represents everything as text but JSON represents numbers, booleans and text differently.  For example

```javascript
{ "number" : 1, "boolean" : true, "text" : "text" }
```

produced by the following XSLT

```xml
<!--  This is the template for text() referred to in later code -->

<xsl:template match="text()">
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
```

<h3>Multiple child elements - ordered</h3>

The examples above are pretty simplistic and it's unlikely anyone will be translating a document of just single elements inside other elements.  It is much more likely there will be multiple elements (and/or text but we'll come to that later).

Some applications use ordered elements, in which case a JSON list has to be used.  Take the same example as before

```xml
<outer>
    <aa><in1 /></aa>
    <aa><in2 /></aa>
    <bb />
</outer>
```

in style 1 this translates to

```javascript
{ "outer" : [ { "aa" : { "in1" : null } }, { "aa" : { "in2" : null } }, 
{ "bb" : null } ] }
```

produced by this XSLT

```xml
<xsl:template match="*">
    <xsl:text>{ "</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>" : </xsl:text>
    <xsl:variable name="ctr" select="count(node())" />
    <xsl:choose>
        <xsl:when test="$ctr = 0">
            <xsl:text>null</xsl:text>
        </xsl:when>
        <xsl:when test="$ctr = 1">
            <xsl:apply-templates select="*"/>
        </xsl:when>
        <xsl:when test="$ctr > 1">
            <xsl:text>[ </xsl:text>
            <xsl:apply-templates select="*"/>
            <xsl:text> ]</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text> }</xsl:text>
    <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
    </xsl:if>
</xsl:template>
```

in style 2 we also use a list, which translates to

```javascript
{ "e" : "outer", "c" : [ { "e" : "aa", "c" : { "e" : "in1" } }, 
{ "e" : "aa", "c" : { "e" : "in2" } }, 
{ "e" : "bb" } ] }
```

produced by this XSLT

```xml
<xsl:template match="*">
    <xsl:text>{ "e" : "</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>"</xsl:text>
    <xsl:variable name="ctr" select="count(*)" />
    <xsl:choose>
        <xsl:when test="$ctr = 1">
            <xsl:text>, "c" : </xsl:text>
            <xsl:apply-templates select="*"/>
        </xsl:when>
        <xsl:when test="$ctr > 1">
            <xsl:text>, "c" : </xsl:text>
            <xsl:text>[ </xsl:text>
            <xsl:apply-templates select="*" />
            <xsl:text> ]</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text> }</xsl:text>
    <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
    </xsl:if>
</xsl:template>
```

<h3>Multiple child elements, numbers, booleans and text - ordered</h3>

Many business applications of XML that are intended to contain structured data don't mix child elements and text so you may be able to get away without dealing with mixed child elements and text, but if not then the main consideration is whether or not you want the ordering preserved or not.

If the ordering is to be preserved then we create an ordered list of all of the contents.  Take the following ordered example:

<p>First<em>Second</em>3</p>

using element names as keys ends up as something like

```javascript
{ "p" : [ "First ", { "em" : "Second" }, 3 ] }
```

produced by the following XSLT

```xml
<xsl:template match="*">
    <xsl:text>{ "</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>" : </xsl:text>
    <xsl:variable name="ctr" select="count(child::*|child::text())"/>
    <xsl:choose>
        <xsl:when test="$ctr = 0">
            <xsl:text>null</xsl:text>
        </xsl:when>
        <xsl:when test="$ctr = 1">
            <xsl:apply-templates />
        </xsl:when>
        <xsl:when test="$ctr > 1">
            <xsl:text>[ </xsl:text>
            <xsl:apply-templates />
            <xsl:text> ]</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text> }</xsl:text>
    <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
    </xsl:if>
</xsl:template>

<!-- assumes the template for text() is present here -->
```

using well known keys is slightly different from the preceding examples because neither "c" nor "$" is correct as a well known key since one list may have both children and text, so we redefine "c" to mean contents when dealing with ordered content.

```javascript
{ "e" : "p", "c" : [ "First", { "e" : "em", "$" : "Second" }, 3 ] }
```

produced by this XSLT

```xml
<xsl:template match="*">
    <xsl:text>{ "e" : "</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>"</xsl:text>
    <xsl:variable name="ctr" select="count(child::*|child::text())"/>
    <xsl:choose>
        <xsl:when test="$ctr = 1">
            <xsl:text>, "c" : </xsl:text>
            <xsl:apply-templates />
        </xsl:when>
        <xsl:when test="$ctr > 1">
            <xsl:text>, "c" : [ </xsl:text>
            <xsl:apply-templates />
            <xsl:text> ]</xsl:text>
        </xsl:when>
    </xsl:choose>
    <xsl:text> }</xsl:text>
    <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
    </xsl:if>
</xsl:template>

<!-- assumes the template for text() is present here -->
```

<h3>Multiple child elements - unordered</h3>

In style 1 encoding this in JSON is not as simple as it seems.  Take the following example

```xml
<outer><aa /><bb /></outer>
```

we can just list the child elements as key value pairs like this

```javascript
{ "outer" : { "aa" : null, "bb" : null } }
```

but that then runs into a problem when there are multiple child elements with the same name.  As mentioned above we could have duplicate keys but that would break most libraries, so an alternative translation is required that uses one element name and list of the contents of each of the element.  Solving this in XSLT is a hard problem that thankfully others have solved as shown in the XSLT below.

So this example

```xml
<outer>
    <aa><in1 /></aa>
    <aa><in2 /></aa>
    <bb />
</outer>
```

translates to

```javascript
{ "outer" :  { "aa" : [ { "in1" : null }, 
{ "in2", null } ], "bb" : null } }
```

produced by this XSLT

NOTE:  The key of <code lang="xml">concat(generate-id(..),'/',name())</code> is chosen because when we search for the key want to only retrieve elements with the same name <em>and</em> the same parent, which is what the <code lang="xml">generate-id(..)</code> provides by uniquely identifying that parent.

```xml
<xsl:key name="names" match="*" use="concat(generate-id(..),'/',name())"/>

<xsl:template match="/">
    <xsl:text>{ </xsl:text>
    <xsl:apply-templates select="*[generate-id(.) = generate-id(key('names', concat(generate-id(..),'/',name()))[1])]">
        <xsl:sort select="name()"/>            
    </xsl:apply-templates>
    <xsl:text> }</xsl:text>
</xsl:template>

<xsl:template match="*">
    <xsl:variable name="kctr" select="count(key('names', concat(generate-id(..),'/',name())))"/>
    <xsl:for-each select="key('names', concat(generate-id(..),'/',name()))">
        <xsl:choose>
            <xsl:when test="($kctr > 1) and (position() = 1)">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>" : [ </xsl:text>
            </xsl:when>
            <xsl:when test="$kctr = 1">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>" : </xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:variable name="ctr" select="count(*)"/>
        <xsl:choose>
            <xsl:when test="$ctr = 0">
                <xsl:text>null</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>{ </xsl:text>
                <xsl:apply-templates select="*[generate-id(.) = generate-id(key('names', concat(generate-id(..),'/',name()))[1])]">
                    <xsl:sort select="name()"/>
                </xsl:apply-templates>
                <xsl:text> }</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$kctr > 1">
            <xsl:choose>
                <xsl:when test="position() = last()">
                    <xsl:text> ]</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>, </xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:for-each>
    <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
    </xsl:if>
</xsl:template>
```

In style 2 there's no problem at all with multiple child elements with the name because the element name is within the object, not a key to the object.  However there is another problem, which is that each object must have its own key, so with the same example the following representation is not legal in JSON

```javascript
{ "e" : "outer", "c" : { { "e" : "aa", "c" : { "e" : "in1" } }, 
{ "e" : "aa", "c" : { "e" : "in2" } }, { "e" : "bb" } } }
```

we get around this by using a list to hold the objects, at which point it becomes an ordered list so best use the code shown earlier.

<h3>Multiple child elements, numbers, booleans and text - unordered</h3>

Take the following example if ordering is lost in favour of grouping, then

```xml
<outer>
    <aa>1<i1>in</i1>2</aa>
    <bb />
    <aa><i2 /></aa>
    <bb>false</bb>
    <cc />
</outer>
```

in style 1 this translates to

```javascript
{ "outer" : { "aa" : [ { "i1" : { "$" : "in" }, "$" : [ 1, 2 ] }, 
{ "i2" : null } ], "bb" : [ null, { "$" : false } ], "cc" : null } }
```

produced by this XSLT

```xml
<xsl:key name="names" match="*" use="concat(generate-id(..),'/',name())"/>

<xsl:template match="/">
    <xsl:text>{ </xsl:text>
    <xsl:apply-templates select="*[generate-id(.) = generate-id(key('names', concat(generate-id(..),'/',name()))[1])]">
        <xsl:sort select="name()"/>            
    </xsl:apply-templates>
    <xsl:text> }</xsl:text>
</xsl:template>

<xsl:template match="*">
    <xsl:variable name="kctr" select="count(key('names', concat(generate-id(..),'/',name())))"/>
    <xsl:for-each select="key('names', concat(generate-id(..),'/',name()))">
        <xsl:choose>
            <xsl:when test="($kctr > 1) and (position() = 1)">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>" : [ </xsl:text>
            </xsl:when>
            <xsl:when test="$kctr = 1">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="name()"/>
                <xsl:text>" : </xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:variable name="nctr" select="count(*|text())"/>
        <xsl:choose>
            <xsl:when test="$nctr = 0">
                <xsl:text>null</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>{ </xsl:text>
                <xsl:variable name="ctr" select="count(*)"/>
                <xsl:apply-templates select="*[generate-id(.) = generate-id(key('names', concat(generate-id(..),'/',name()))[1])]">
                    <xsl:sort select="name()"/>
                </xsl:apply-templates>
                <xsl:variable name="tctr" select="count(text())"/>
                <xsl:if test="($ctr > 0) and ($tctr > 0)">
                    <xsl:text>, </xsl:text>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="$tctr = 1">
                        <xsl:text>"$" : </xsl:text>
                        <xsl:apply-templates select="text()"/>
                    </xsl:when>
                    <xsl:when test="$tctr > 1">
                        <xsl:text>"$" : [ </xsl:text>
                        <xsl:apply-templates select="text()"/>
                        <xsl:text> ]</xsl:text>
                    </xsl:when>
                </xsl:choose>
                <xsl:text> }</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$kctr > 1">
            <xsl:choose>
                <xsl:when test="position() = last()">
                    <xsl:text> ]</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>, </xsl:text>
                </xsl:otherwise>
            </xsl:choose>                
        </xsl:if>
    </xsl:for-each>
    <xsl:if test="position() != last()">
        <xsl:text>, </xsl:text>
    </xsl:if>
</xsl:template>

<!-- assumes the template for text() is present here -->
```

In style 2 this is still an ordered list as it has to be (see earlier for an explanation as to why) but we can group together the contents of each element to make the JSON more useful.  The same example translates to

```javascript
{ "e" : "outer", "c" : [ { "e" : "aa", "c" : { "e" : "i1", "$" : "in" }, 
"$" : [ 1, 2 ] }, { "e" : "bb" }, { "e" : "aa", "c" : { "e" : "i2" } }, 
{ "e" : "bb", "$" : false }, { "e" : "cc" } ] }
```

produced by this XSLT

```xml
<xsl:template match="*">
    <xsl:text>{ "e" : "</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>"</xsl:text>
    <xsl:variable name="ctr" select="count(*)"/>
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
    <xsl:variable name="tctr" select="count(text())"/>
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

<!-- assumes the template for text() is present here -->
```

<h3>Attributes</h3>

Then there is the issue of attributes.  It seems pretty clear that attributes translate to straight key value pairs in JSON, but there are two further considerations:

The first is whether the attribute names needs prefixing and the second is whether the attributes are the same level as the element or below.  In XML an attribute can have the same name as an element so if they are at the same level there may be a name clash, but careful use of XML can avoid that.

If they are at the same level then using a standard unordered JSON object means that the element name cannot be distinguished from the attribute names unless you know them in advance because there is no guarantee the element name will come first.  This could be got around by enforcing ordering in the JSON but that is too messy for my liking (it means that instead of an element being encapsulated by an object, it is encapsulated by a list inside an object.

Finally, just a note that attributes too can contain numbers, booleans or text and the translation needs to deal with that.

The following example

```xml
<aa at1="1" at2="second" />
```

can have attributes at a lower level with a standard key to find them:

```javascript
{ "e" : "aa", "@" : { "at1" : 1, "at2" : second } }
```

or

```javascript
{ "aa" : null, "@" : { "at1" : 1, "at2" : second } }
```

produced by this XSLT (some code removed for readability)

```xml
<xsl:template match="*">
    <!-- code removed for readability -->
    <xsl:variable name="actr" select="count(@*)"/>
    <xsl:choose>
        <xsl:when test="$actr = 1">
            <xsl:text>, "@" : </xsl:text>
            <xsl:apply-templates select ="@*"/>
        </xsl:when>
        <xsl:when test="$actr > 1">
            <xsl:text>, "@" : [ </xsl:text>
            <xsl:apply-templates select="@*"/>
            <xsl:text> ]</xsl:text>
        </xsl:when>
    </xsl:choose>
    <!-- code removed for readability -->
</xsl:template>

<xsl:template match="@*">
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
```

or at the same level with a prefix to distinguish them

```javascript
{ "e", "aa", "@at1" : 1, "@at2" : "second" }
```

or

```javascript
{ "aa" : null, "@at1" : 1, "@at2" : "second" }
```

produced by this XSLT (some code removed for readability)

```xml
<xsl:template match="*">
    <!-- code removed for readability -->
    <xsl:if test="count(@*) > 0">
        <xsl:text>, </xsl:text>
        <xsl:apply-templates select="@*"/>
    </xsl:if>
    <!-- code removed for readability -->
</xsl:template>

<xsl:template match="@*">
    <xsl:text>"@</xsl:text>
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
```

Changing this to be at the same level with no prefix is a trivial amendment to the above code.

<h3>Unfinished business</h3>

There is one possibly major thing that I have not covered and which is escaping the backslash and double quote characters.

Also, none of this code handle comments nodes, namespace nodes or processing instruction nodes, so you will need to add that yourself if you are after that data.

Finally, depending on what options you choose, some optimisations are possible.  Some common code (such as the number/text/boolean recognition code) can be put into named templates that are then called with parameters.

<h3>Finishing off</h3>

For a start we need to tell the XSLT processor that the output is text not XML, otherwise it will try to be helpful and insert some XML headers it believes are missing.  We could also set it to automatically indent the output.  Both of those are set like this:

```xml
<xsl:output method="text" encoding="utf-8" indent="yes" />
```

Next to tackle is the oddity of XML whitespace.  If we have an XML document that looks like this

```xml
<outer>
    <inner>
    </inner>
</outer>
```

Then the XSLT by default will see three pieces of text each containing just a linefeed (whatever OS you use) unless you do something about it.  The following directive in the XSLT deals with this:

```xml
<xsl:strip-space elements="*" />
```

If you dont want to preserve namespaces and would rather drop the namespace prefix then replace all instances of <code lang="javascript">name()</code> with <code lang="javascript">local-name()</code>

<h3>Putting it all together</h3>

To help you construct a full XSLT here are a couple of full examples.  This is one for style 1 unordered

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

    <!-- Turn off auto-insertion of <?xml> tag and set indenting on -->
    <xsl:output method="text" encoding="utf-8" indent="yes"/>
    
    <!-- strip whitespace from whitespace-only nodes -->
    <xsl:strip-space elements="*"/>
     
    <!-- create a key for every element in the document using its name --> 
    <xsl:key name="names" match="*" use="concat(generate-id(..),'/',name())"/>
    
    <!-- start with the root element -->
    <xsl:template match="/">
        <!-- first element needs brackets around it as template does not do that -->
        <xsl:text>{ </xsl:text>
        <!-- call the template for elements using one unique name at a time -->
        <xsl:apply-templates select="*[generate-id(.) = generate-id(key('names', concat(generate-id(..),'/',name()))[1])]" >
            <xsl:sort select="name()"/>            
        </xsl:apply-templates>
        <xsl:text> }</xsl:text>
    </xsl:template>
    
    <!-- this template handles elements -->
    <xsl:template match="*">
        <!-- count the number of elements with the same name -->
        <xsl:variable name="kctr" select="count(key('names', concat(generate-id(..),'/',name())))"/>
        <!-- iterate through by sets of elements with same name -->
        <xsl:for-each select="key('names', concat(generate-id(..),'/',name()))">
            <!-- deal with the element name and start of multiple element block -->
            <xsl:choose>
                <xsl:when test="($kctr > 1) and (position() = 1)">
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="name()"/>
                    <xsl:text>" : [ </xsl:text>
                </xsl:when>
                <xsl:when test="$kctr = 1">
                    <xsl:text>"</xsl:text>
                    <xsl:value-of select="name()"/>
                    <xsl:text>" : </xsl:text>
                </xsl:when>
            </xsl:choose>
            <!-- count number of elements, text nodes and attribute nodes -->
            <xsl:variable name="nctr" select="count(*|text()|@*)"/>
            <xsl:choose>
                <xsl:when test="$nctr = 0">
                    <!-- no contents at all -->
                    <xsl:text>null</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="ctr" select="count(*)"/>
                    <xsl:variable name="tctr" select="count(text())"/>
                    <xsl:variable name="actr" select="count(@*)"/>                    
                    <!-- there will be contents so start an object -->
                    <xsl:text>{ </xsl:text>
                    <!-- handle attribute nodes -->
                    <xsl:if test="$actr > 0">
                        <xsl:apply-templates select="@*"/>
                        <xsl:if test="($tctr > 0) or ($ctr > 0)">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:if>
                    <!-- call template for child elements one unique name at a time -->
                    <xsl:if test="$ctr > 0">
                        <xsl:apply-templates select="*[generate-id(.) = generate-id(key('names', concat(generate-id(..),'/',name()))[1])]">
                            <xsl:sort select="name()"/>
                        </xsl:apply-templates>
                        <xsl:if test="$tctr > 0">
                            <xsl:text>, </xsl:text>                            
                        </xsl:if>
                    </xsl:if>
                    <!-- handle text nodes -->
                    <xsl:choose>
                        <xsl:when test="$tctr = 1">
                            <xsl:text>"$" : </xsl:text>
                            <xsl:apply-templates select="text()"/>
                        </xsl:when>
                        <xsl:when test="$tctr > 1">
                            <xsl:text>"$" : [ </xsl:text>
                            <xsl:apply-templates select="text()"/>
                            <xsl:text> ]</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:text> }</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            <!-- special processing if we are in multiple element block -->
            <xsl:if test="$kctr > 1">
                <xsl:choose>
                    <xsl:when test="position() = last()">
                        <xsl:text> ]</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>, </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>                
            </xsl:if>
        </xsl:for-each>
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
        <xsl:text>"@</xsl:text>
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
```

and here is one for style 2 unordered

```xml
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
```
