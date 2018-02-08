<?xml version="1.0" encoding="UTF-8"?>
<!--

    Copyright 2014-2016 European Environment Agency

    Licensed under the EUPL, Version 1.1 or – as soon
    they will be approved by the European Commission -
    subsequent versions of the EUPL (the "Licence");
    You may not use this work except in compliance
    with the Licence.
    You may obtain a copy of the Licence at:

    https://joinup.ec.europa.eu/community/eupl/og_page/eupl

    Unless required by applicable law or agreed to in
    writing, software distributed under the Licence is
    distributed on an "AS IS" basis,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
    either express or implied.
    See the Licence for the specific language governing
    permissions and limitations under the Licence.

-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:gmd="http://www.isotc211.org/2005/gmd"
                xmlns:gmi="http://www.isotc211.org/2005/gmi"
                xmlns:gco="http://www.isotc211.org/2005/gco"
                xmlns:mdb="http://standards.iso.org/iso/19115/-3/mdb/1.0"
                xmlns:gn="http://www.fao.org/geonetwork"
                xmlns:csw="http://www.opengis.net/cat/csw/2.0.2"
                xmlns:daobs="http://daobs.org"
                xmlns:saxon="http://saxon.sf.net/"
                extension-element-prefixes="saxon"
                exclude-result-prefixes="#all"
                version="2.0">

  <xsl:output name="default-serialize-mode"
              indent="no"
              omit-xml-declaration="yes"
              encoding="utf-8"
              escape-uri-attributes="yes"/>

  <xsl:param name="indexingIndex" select="'0'"/>

  <!-- Define if operatesOn type should be defined
  by analysis of protocol in all transfers options.
  -->
  <xsl:variable name="operatesOnSetByProtocol" select="false()"/>

  <!-- Define if search for regulation title should be strict or light. -->
  <xsl:variable name="inspireRegulationLaxCheck" select="false()"/>

  <!-- List of keywords to search for to flag a record as opendata.
   Do not put accents or upper case letters here as comparison will not
   take them in account. -->
  <xsl:variable name="openDataKeywords"
                select="'opendata|open data|donnees ouvertes'"/>

  <xsl:variable name="harvester" as="element()?"
                select="/harvestedContent/daobs:harvester"/>

  <xsl:variable name="pointOfTruthURLPattern" as="xs:string?"
                select="normalize-space($harvester/daobs:pointOfTruthURLPattern)"/>

  <xsl:variable name="dateFormat" as="xs:string"
                select="'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]'"/>

  <xsl:variable name="separator" as="xs:string"
                select="'|'"/>

  <!-- To avoid Document contains at least one immense term
  in field="resourceAbstract" (whose UTF8 encoding is longer
  than the max length 32766. -->
  <xsl:variable name="maxFieldLength" select="32000" as="xs:integer"/>


  <!-- When loading CSW response from a local file system. -->
  <xsl:variable name="isFile"
                select="starts-with(normalize-space(/harvestedContent/daobs:harvester/daobs:url), 'file://')"
                as="xs:boolean?"/>

  <xsl:variable name="scope"
                select="/harvestedContent/daobs:harvester/daobs:scope"
                as="xs:string?"/>

  <xsl:include href="fn.xsl"/>
  <xsl:include href="metadata-iso19139.xsl"/>
  <xsl:include href="metadata-iso19115-3.xsl"/>


  <xsl:template match="*"
                mode="extract-uuid"/>

  <xsl:template match="/">
    <!-- Add a document -->
    <add>
      <!-- For any ISO19139 records in the input XML document
      Some records from IS do not have record identifier. Ignore them.
      -->
      <xsl:variable name="records"
                    select="//csw:SearchResults/(gmi:MI_Metadata|gmd:MD_Metadata|mdb:MD_Metadata)"/>

      <!-- Check number of records returned and reported -->
      <xsl:message>## DEBUG: <xsl:value-of select="normalize-space($harvester/daobs:url)"/>.</xsl:message>
      <xsl:message>Page #<xsl:value-of select="$indexingIndex"/>: <xsl:value-of select="count($records)"/> record(s) to index.</xsl:message>


      <!-- Check duplicates
      TODO: Support ISO19115-3 check
      -->
      <xsl:for-each select="$records">
        <xsl:variable name="identifier" as="xs:string">
          <xsl:apply-templates mode="extract-uuid" select="."/>
        </xsl:variable>

        <xsl:variable name="numberOfRecordWithThatUUID"
                      select="count(../*[gmd:fileIdentifier/gco:CharacterString = $identifier])"/>
        <xsl:if test="$numberOfRecordWithThatUUID > 1">
          <xsl:message>WARNING: <xsl:value-of select="$numberOfRecordWithThatUUID"/> record(s) having UUID '<xsl:value-of select="$identifier"/>' in that set.</xsl:message>
        </xsl:if>
      </xsl:for-each>


      <xsl:for-each select="$records">

        <xsl:variable name="identifier" as="xs:string">
          <xsl:apply-templates mode="extract-uuid" select="."/>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="normalize-space($identifier) = ''">
            <xsl:message>WARNING: Record with null UUID found. Document will not be indexed.</xsl:message>
            <xsl:message><xsl:copy-of select="."/></xsl:message>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates mode="index" select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </add>
  </xsl:template>

  <!-- For each record, the main mode 'index' is called,
  then in the document node the mode 'index-extra-fields'
  could be used to index more fields. -->
  <xsl:template mode="index-extra-fields" match="*"/>

  <!-- then after the doc, the 'index-extra-documents' mode
  could be used to create more doc. -->
  <xsl:template mode="index-extra-documents" match="*"/>

  <!-- Do a copy of every nodes and attributes -->
  <xsl:template match="@*|node()" mode="copy">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="copy"/>
    </xsl:copy>
  </xsl:template>

  <!-- Remove geonet:* elements. -->
  <xsl:template match="gn:*"  mode="copy" priority="2"/>

</xsl:stylesheet>
