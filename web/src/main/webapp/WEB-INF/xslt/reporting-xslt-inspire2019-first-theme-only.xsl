<?xml version="1.0"?>
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
                xmlns:daobs="http://daobs.org"
                version="2.0"
                exclude-result-prefixes="#all">

  <xsl:import href="reporting-xslt-rawdata.xsl"/>

  <xsl:output method="xml"
              encoding="UTF-8"
              include-content-type="yes"
              indent="yes"/>

  <!-- Aggregation criteria for searches. Could be null to report
  on all harvested records. Should be a valid member states code. -->
  <xsl:param name="scope" select="''" as="xs:string"/>

  <!-- The filter query used to retrieve document -->
  <xsl:param name="fq" select="''" as="xs:string"/>

  <!-- Override scope -->
  <xsl:param name="scopeId" select="''" as="xs:string"/>

  <xsl:param name="language" select="'eng'" as="xs:string"/>

  <!-- Date of creation of the report. Default current date time. -->
  <xsl:param name="creationDate" select="/daobs:reporting/@dateTime" as="xs:string"/>

  <!-- Date covered by the data used to compute the indicators.  -->
  <xsl:param name="reportingDate" select="/daobs:reporting/@dateTime" as="xs:string"/>

  <!-- TODO: What is the organization. Use user session information ?  -->
  <xsl:param name="organizationName" select="''" as="xs:string"/>
  <xsl:param name="email" select="''" as="xs:string"/>

  <!-- Add the row data section to the report. -->
  <xsl:param name="withRowData" select="true()" as="xs:boolean"/>

  <!-- Data sets report mode define how the dataset should be reported.
  Options are:
  * onlyFirstInspireTheme: if true, only the first INSPIRE theme
   is reported for a dataset
  * asManyDatasetsAsInspireThemes: if true, if a dataset contains
   more than one INSPIRE theme, then the dataset is duplicated
   for each INSPIRE theme.
  -->
  <xsl:param name="datasetMode" select="''" as="xs:string"/>

  <!-- List of datasets for this report. -->
  <xsl:param name="spatialDataSets" as="node()?"/>

  <!-- List of services for this report. -->
  <xsl:param name="spatialDataServices" as="node()?"/>


  <xsl:variable name="dateFormat" as="xs:string"
                select="'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]Z'"/>

  <!-- TODO: Handle timezone -->
  <xsl:variable name="creation"
                select="xs:dateTime($creationDate)"/>
  <xsl:variable name="reporting"
                select="xs:dateTime($reportingDate)"/>

  <xsl:template match="/">
    <ns2:Monitoring
      xmlns:ns2="http://inspire.jrc.ec.europa.eu/monitoringreporting/monitoring"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <xsl:comment>Experimental INSPIRE report with indicators defined for 2019 reporting obligation</xsl:comment>
      <documentYear>
        <day>
          <xsl:value-of select="format-dateTime($creation, '[D01]')"/>
        </day>
        <month>
          <xsl:value-of select="format-dateTime($creation, '[M01]')"/>
        </month>
        <year>
          <xsl:value-of select="format-dateTime($creation, '[Y0001]')"/>
        </year>
      </documentYear>
      <xsl:comment> Filter query: <xsl:value-of select="$fq"/></xsl:comment>
      <memberState>
        <!-- If a scopeId is provided
             use it as a memberState key. This is usefull when
             creating report at local level eg. -->
        <xsl:value-of select="if ($scopeId != '') then $scopeId
                              else upper-case($scope)"/>
      </memberState>
      <MonitoringMD>
        <organizationName>
          <xsl:value-of select="$organizationName"/>
        </organizationName>
        <email>
          <xsl:value-of select="$email"/>
        </email>
        <monitoringDate>
          <day>
            <xsl:value-of select="format-dateTime($reporting, '[D01]')"/>
          </day>
          <month>
            <xsl:value-of select="format-dateTime($reporting, '[M01]')"/>
          </month>
          <year>
            <xsl:value-of select="format-dateTime($reporting, '[Y0001]')"/>
          </year>
        </monitoringDate>
        <language>
          <xsl:value-of select="$language"/>
        </language>
      </MonitoringMD>
      <Indicators>
        <xsl:variable name="indicatorList">
          <id>DSi11</id>
          <id>DSi12</id>
          <id>DSi13</id>
          <id>DSi14</id>
          <id>DSi15</id>
          <id>MDi11</id>
          <id>MDi12</id>
          <id>DSi2</id>
          <id>DSi21</id>
          <id>DSi22</id>
          <id>DSi23</id>
          <id>NSi2</id>
          <id>NSi21</id>
          <id>NSi22</id>
          <id>NSi4</id>
          <id>NSi41</id>
          <id>NSi42</id>
          <id>NSi43</id>
          <id>NSi44</id>
        </xsl:variable>

        <xsl:variable name="root" select="/"/>
        <xsl:for-each select="$indicatorList//id">
          <xsl:variable name="id"
                        select="."/>
          <xsl:element name="{$id}">
            <xsl:value-of select="$root//(daobs:indicator|daobs:variable)[@id= $id]/daobs:value"/>
          </xsl:element>
        </xsl:for-each>
      </Indicators>

      <xsl:if test="$withRowData = true()">
        <!--<xsl:message><xsl:copy-of select="$spatialDataServices"/></xsl:message>-->
        <RowData>
          <xsl:apply-templates mode="SpatialDataServiceFactory"
                               select="$spatialDataServices//doc"/>

          <xsl:choose>
            <xsl:when test="$datasetMode = 'asManyDatasetsAsInspireThemes'">
              <xsl:apply-templates
                mode="SpatialDataSetFactoryForEachInspireTheme"
                select="$spatialDataSets//doc"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates mode="SpatialDataSetFactory"
                                   select="$spatialDataSets//doc"/>
            </xsl:otherwise>
          </xsl:choose>
        </RowData>
      </xsl:if>
    </ns2:Monitoring>
  </xsl:template>
</xsl:stylesheet>
