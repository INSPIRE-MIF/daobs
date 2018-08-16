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
                xmlns:solr="java:org.daobs.index.SolrRequestBean"
                xmlns:saxon="http://saxon.sf.net/"
                extension-element-prefixes="saxon"
                exclude-result-prefixes="#all"
                version="2.0">


  <xsl:import href="index-indicators.xsl"/>

  <!-- Ancillary information are extra information not
  available in the metadata records that need to be
  added to the reporting. Those information are provided
  by using the monitoring format and indexed as documentType:ai
  and then used to generate the reporting. -->

  <!-- User requests on each service types
   documentType:ai
   indicatorName:userRequestview
   indicatorValue:100
   scope:be
   Dates will be indexed but for the time being no history
   of the ancillary information will be maintained (ie.
   stats will be provided on all ai).-->
  <xsl:template match="RowData/SpatialDataService/NetworkService/userRequest">
    <xsl:variable name="serviceType"
                  select="../NnServiceType/text()"/>
    <xsl:variable name="indicatorIdentifier"
                  select="concat(local-name(), $serviceType, ../../uuid/text())"/>
    <doc>
      <id>
        <xsl:value-of
          select="concat('ai', $indicatorIdentifier,
              $reportingDate, $reportingScope)"/>
      </id>
      <documentType>ai</documentType>
      <indicatorName>
        <xsl:value-of select="$indicatorIdentifier"/>
      </indicatorName>
      <xsl:if test="text() != ''">
        <indicatorValue>
          <xsl:value-of select="text()"/>
        </indicatorValue>
      </xsl:if>
      <scope>
        <xsl:value-of select="$reportingScope"/>
      </scope>
      <reportingDateSubmission>
        <xsl:value-of select="$reportingDateSubmission"/>
      </reportingDateSubmission>
      <reportingDate>
        <xsl:value-of select="$reportingDate"/>
      </field>
      <reportingYear>
        <xsl:value-of select="$documentYear"/>
      </field>
    </doc>
  </xsl:template>


  <!-- Actual / Relevant area-->
  <xsl:template match="RowData/SpatialDataSet/Coverage/*">
    <xsl:variable name="indicatorIdentifier"
                  select="local-name()"/>
    <doc>
      <id>
        <xsl:value-of
          select="concat('ai', $indicatorIdentifier,
              $reportingDate, $reportingScope, ../../uuid/text())"/>
      </field>
      <documentType>ai</field>
      <indicatorName>
        <xsl:value-of select="$indicatorIdentifier"/>
      </field>
      <xsl:if test="text() != ''">
        <indicatorValue>
          <xsl:value-of select="text()"/>
        </field>
      </xsl:if>
      <scope>
        <xsl:value-of select="$reportingScope"/>
      </field>
      <reportingDateSubmission>
        <xsl:value-of select="$reportingDateSubmission"/>
      </field>
      <reportingDate>
        <xsl:value-of select="$reportingDate"/>
      </reportingDate>
      <reportingYear>
        <xsl:value-of select="$documentYear"/>
      </reportingYear>

      <xsl:for-each select="../../Themes/*[text() != '']">
        <xsl:variable name="inspireTheme" as="xs:string"
                      select="solr:analyzeField('analyzeField', text())"/>

        <xsl:if test="$inspireTheme != ''">
          <inspireTheme_syn>
            <xsl:value-of select="text()"/>
          </inspireTheme_syn>
          <inspireTheme>
            <xsl:value-of select="$inspireTheme"/>
          </inspireTheme>

          <xsl:if test="position() = 1">
            <inspireAnnex>
              <xsl:value-of
                select="solr:analyzeField('synInspireAnnexes', $inspireTheme)"/>
            </inspireAnnex>
          </xsl:if>
        </xsl:if>
      </xsl:for-each>
    </doc>
  </xsl:template>
</xsl:stylesheet>
