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
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://inspire.jrc.ec.europa.eu/monitoringreporting/monitoring http://dd.eionet.europa.eu/schemas/inspire-monitoring/monitoring.xsd">
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
        <NnConformityIndicators>
          <NSi41>
            <xsl:value-of select="//daobs:indicator[@id='NSi41']/daobs:value"/>
          </NSi41>
          <NSi42>
            <xsl:value-of select="//daobs:indicator[@id='NSi42']/daobs:value"/>
          </NSi42>
          <NSi43>
            <xsl:value-of select="//daobs:indicator[@id='NSi43']/daobs:value"/>
          </NSi43>
          <NSi44>
            <xsl:value-of select="//daobs:indicator[@id='NSi44']/daobs:value"/>
          </NSi44>
          <NSi45>
            <xsl:value-of select="//daobs:indicator[@id='NSi45']/daobs:value"/>
          </NSi45>
          <NSi4>
            <xsl:value-of select="//daobs:indicator[@id='NSi4']/daobs:value"/>
          </NSi4>
          <NnConformity>
            <NSv41>
              <xsl:value-of select="//daobs:variable[@id='NSv41']/daobs:value"/>
            </NSv41>
            <NSv42>
              <xsl:value-of select="//daobs:variable[@id='NSv42']/daobs:value"/>
            </NSv42>
            <NSv43>
              <xsl:value-of select="//daobs:variable[@id='NSv43']/daobs:value"/>
            </NSv43>
            <NSv44>
              <xsl:value-of select="//daobs:variable[@id='NSv44']/daobs:value"/>
            </NSv44>
            <NSv45>
              <xsl:value-of select="//daobs:variable[@id='NSv45']/daobs:value"/>
            </NSv45>
            <NSv4>
              <xsl:value-of select="//daobs:indicator[@id='NSv4']/daobs:value"/>
            </NSv4>
          </NnConformity>
        </NnConformityIndicators>
        <GeoCoverageIndicators>
          <DSi11>
            <xsl:value-of select="//daobs:indicator[@id='DSi11']/daobs:value"/>
          </DSi11>
          <DSi12>
            <xsl:value-of select="//daobs:indicator[@id='DSi12']/daobs:value"/>
          </DSi12>
          <DSi13>
            <xsl:value-of select="//daobs:indicator[@id='DSi13']/daobs:value"/>
          </DSi13>
          <DSi1>
            <xsl:value-of select="//daobs:indicator[@id='DSi1']/daobs:value"/>
          </DSi1>
          <GeoCoverageSDS>
            <DSv11_ActArea>
              <xsl:value-of
                select="//daobs:indicator[@id='DSv11_ActArea']/daobs:value"/>
            </DSv11_ActArea>
            <DSv12_ActArea>
              <xsl:value-of
                select="//daobs:indicator[@id='DSv12_ActArea']/daobs:value"/>
            </DSv12_ActArea>
            <DSv13_ActArea>
              <xsl:value-of
                select="//daobs:indicator[@id='DSv13_ActArea']/daobs:value"/>
            </DSv13_ActArea>
            <DSv1_ActArea>
              <xsl:value-of
                select="//daobs:indicator[@id='DSv1_ActArea']/daobs:value"/>
            </DSv1_ActArea>
            <DSv11_RelArea>
              <xsl:value-of
                select="//daobs:indicator[@id='DSv11_RelArea']/daobs:value"/>
            </DSv11_RelArea>
            <DSv12_RelArea>
              <xsl:value-of
                select="//daobs:indicator[@id='DSv12_RelArea']/daobs:value"/>
            </DSv12_RelArea>
            <DSv13_RelArea>
              <xsl:value-of
                select="//daobs:indicator[@id='DSv13_RelArea']/daobs:value"/>
            </DSv13_RelArea>
            <DSv1_RelArea>
              <xsl:value-of
                select="//daobs:indicator[@id='DSv1_RelArea']/daobs:value"/>
            </DSv1_RelArea>
          </GeoCoverageSDS>
        </GeoCoverageIndicators>
        <UseNNindicators>
          <NSi31>
            <xsl:value-of select="//daobs:indicator[@id='NSi31']/daobs:value"/>
          </NSi31>
          <NSi32>
            <xsl:value-of select="//daobs:indicator[@id='NSi32']/daobs:value"/>
          </NSi32>
          <NSi33>
            <xsl:value-of select="//daobs:indicator[@id='NSi33']/daobs:value"/>
          </NSi33>
          <NSi34>
            <xsl:value-of select="//daobs:indicator[@id='NSi34']/daobs:value"/>
          </NSi34>
          <NSi35>
            <xsl:value-of select="//daobs:indicator[@id='NSi35']/daobs:value"/>
          </NSi35>
          <NSi3>
            <xsl:value-of select="//daobs:indicator[@id='NSi3']/daobs:value"/>
          </NSi3>
          <UseNN>
            <NSv31>
              <xsl:value-of select="//daobs:variable[@id='NSv31']/daobs:value"/>
            </NSv31>
            <NSv32>
              <xsl:value-of select="//daobs:variable[@id='NSv32']/daobs:value"/>
            </NSv32>
            <NSv33>
              <xsl:value-of select="//daobs:variable[@id='NSv33']/daobs:value"/>
            </NSv33>
            <NSv34>
              <xsl:value-of select="//daobs:variable[@id='NSv34']/daobs:value"/>
            </NSv34>
            <NSv35>
              <xsl:value-of select="//daobs:variable[@id='NSv35']/daobs:value"/>
            </NSv35>
            <NSv3>
              <xsl:value-of select="//daobs:indicator[@id='NSv3']/daobs:value"/>
            </NSv3>
          </UseNN>
        </UseNNindicators>
        <MetadataExistenceIndicators>
          <MDi11>
            <xsl:value-of select="//daobs:indicator[@id='MDi11']/daobs:value"/>
          </MDi11>
          <MDi12>
            <xsl:value-of select="//daobs:indicator[@id='MDi12']/daobs:value"/>
          </MDi12>
          <MDi13>
            <xsl:value-of select="//daobs:indicator[@id='MDi13']/daobs:value"/>
          </MDi13>
          <MDi14>
            <xsl:value-of select="//daobs:indicator[@id='MDi14']/daobs:value"/>
          </MDi14>
          <MDi1>
            <xsl:value-of select="//daobs:indicator[@id='MDi1']/daobs:value"/>
          </MDi1>
          <MetadataExistence>
            <MDv11>
              <xsl:value-of select="//daobs:*[@id='MDv11']/daobs:value"/>
            </MDv11>
            <MDv12>
              <xsl:value-of select="//daobs:*[@id='MDv12']/daobs:value"/>
            </MDv12>
            <MDv13>
              <xsl:value-of select="//daobs:*[@id='MDv13']/daobs:value"/>
            </MDv13>
            <MDv1_DS>
              <xsl:value-of
                select="//daobs:indicator[@id='MDv1_DS']/daobs:value"/>
            </MDv1_DS>
            <MDv14>
              <xsl:value-of select="//daobs:variable[@id='MDv14']/daobs:value"/>
            </MDv14>
          </MetadataExistence>
        </MetadataExistenceIndicators>
        <DiscoveryMetadataIndicators>
          <NSi11>
            <xsl:value-of select="//daobs:indicator[@id='NSi11']/daobs:value"/>
          </NSi11>
          <NSi12>
            <xsl:value-of select="//daobs:indicator[@id='NSi12']/daobs:value"/>
          </NSi12>
          <NSi1>
            <xsl:value-of select="//daobs:indicator[@id='NSi1']/daobs:value"/>
          </NSi1>
          <DiscoveryMetadata>
            <NSv11>
              <xsl:value-of select="//daobs:*[@id='NSv11']/daobs:value"/>
            </NSv11>
            <NSv12>
              <xsl:value-of select="//daobs:variable[@id='NSv12']/daobs:value"/>
            </NSv12>
          </DiscoveryMetadata>
        </DiscoveryMetadataIndicators>
        <ViewDownloadAccessibilityIndicators>
          <NSi21>
            <xsl:value-of select="//daobs:indicator[@id='NSi21']/daobs:value"/>
          </NSi21>
          <NSi22>
            <xsl:value-of select="//daobs:indicator[@id='NSi22']/daobs:value"/>
          </NSi22>
          <NSi2>
            <xsl:value-of select="//daobs:indicator[@id='NSi2']/daobs:value"/>
          </NSi2>
          <ViewDownloadAccessibility>
            <NSv21>
              <xsl:value-of select="//daobs:*[@id='NSv21']/daobs:value"/>
            </NSv21>
            <NSv22>
              <xsl:value-of select="//daobs:*[@id='NSv22']/daobs:value"/>
            </NSv22>
            <NSv23>
              <xsl:value-of select="//daobs:*[@id='NSv23']/daobs:value"/>
            </NSv23>
          </ViewDownloadAccessibility>
        </ViewDownloadAccessibilityIndicators>
        <SpatialDataAndService>
          <DSv_Num1>
            <xsl:value-of select="//daobs:*[@id='DSv_Num1']/daobs:value"/>
          </DSv_Num1>
          <DSv_Num2>
            <xsl:value-of select="//daobs:*[@id='DSv_Num2']/daobs:value"/>
          </DSv_Num2>
          <DSv_Num3>
            <xsl:value-of select="//daobs:*[@id='DSv_Num3']/daobs:value"/>
          </DSv_Num3>
          <DSv_Num>
            <xsl:value-of
              select="//daobs:indicator[@id='DSv_Num']/daobs:value"/>
          </DSv_Num>
          <SDSv_Num>
            <xsl:value-of
              select="//daobs:variable[@id='SDSv_Num']/daobs:value"/>
          </SDSv_Num>
          <NSv_NumDiscServ>
            <xsl:value-of
              select="//daobs:variable[@id='NSv_NumDiscServ']/daobs:value"/>
          </NSv_NumDiscServ>
          <NSv_NumViewServ>
            <xsl:value-of
              select="//daobs:variable[@id='NSv_NumViewServ']/daobs:value"/>
          </NSv_NumViewServ>
          <NSv_NumDownServ>
            <xsl:value-of
              select="//daobs:variable[@id='NSv_NumDownlServ']/daobs:value"/>
          </NSv_NumDownServ>
          <NSv_NumInvkServ>
            <xsl:value-of
              select="//daobs:variable[@id='NSv_NumInvkServ']/daobs:value"/>
          </NSv_NumInvkServ>
          <NSv_NumAllServ>
            <xsl:value-of
              select="//daobs:indicator[@id='NSv_NumAllServ']/daobs:value"/>
          </NSv_NumAllServ>
          <NSv_NumTransfServ>
            <xsl:value-of
              select="//daobs:indicator[@id='NSv_NumTransfServ']/daobs:value"/>
          </NSv_NumTransfServ>
        </SpatialDataAndService>
        <MetadataConformityIndicators>
          <MDi21>
            <xsl:value-of select="//daobs:indicator[@id='MDi21']/daobs:value"/>
          </MDi21>
          <MDi22>
            <xsl:value-of select="//daobs:indicator[@id='MDi22']/daobs:value"/>
          </MDi22>
          <MDi23>
            <xsl:value-of select="//daobs:indicator[@id='MDi23']/daobs:value"/>
          </MDi23>
          <MDi24>
            <xsl:value-of select="//daobs:indicator[@id='MDi24']/daobs:value"/>
          </MDi24>
          <MDi2>
            <xsl:value-of select="//daobs:indicator[@id='MDi2']/daobs:value"/>
          </MDi2>
          <MetadataConformity>
            <MDv21>
              <xsl:value-of select="//daobs:*[@id='MDv21']/daobs:value"/>
            </MDv21>
            <MDv22>
              <xsl:value-of select="//daobs:*[@id='MDv22']/daobs:value"/>
            </MDv22>
            <MDv23>
              <xsl:value-of select="//daobs:*[@id='MDv23']/daobs:value"/>
            </MDv23>
            <MDv2_DS>
              <xsl:value-of
                select="//daobs:indicator[@id='MDv2_DS']/daobs:value"/>
            </MDv2_DS>
            <MDv24>
              <xsl:value-of select="//daobs:variable[@id='MDv24']/daobs:value"/>
            </MDv24>
          </MetadataConformity>
        </MetadataConformityIndicators>
        <SdsConformantIndicators>
          <DSi21>
            <xsl:value-of select="//daobs:indicator[@id='DSi21']/daobs:value"/>
          </DSi21>
          <DSi22>
            <xsl:value-of select="//daobs:indicator[@id='DSi22']/daobs:value"/>
          </DSi22>
          <DSi23>
            <xsl:value-of select="//daobs:indicator[@id='DSi23']/daobs:value"/>
          </DSi23>
          <DSi2>
            <xsl:value-of select="//daobs:indicator[@id='DSi2']/daobs:value"/>
          </DSi2>
          <SdsConformant>
            <DSv21>
              <xsl:value-of select="//daobs:*[@id='DSv21']/daobs:value"/>
            </DSv21>
            <DSv22>
              <xsl:value-of select="//daobs:*[@id='DSv22']/daobs:value"/>
            </DSv22>
            <DSv23>
              <xsl:value-of select="//daobs:*[@id='DSv23']/daobs:value"/>
            </DSv23>
            <DSv2>
              <xsl:value-of select="//daobs:indicator[@id='DSv2']/daobs:value"/>
            </DSv2>
          </SdsConformant>
        </SdsConformantIndicators>
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


  <!-- Convert a Solr document to a spatial data service -->
  <xsl:template mode="SpatialDataServiceFactory"
                match="doc"
                as="node()">
    <SpatialDataService>
      <!-- gmd:identificationInfo[1]/*[1]/gmd:citation/gmd:CI_Citation/gmd:title/gco:CharacterString -->
      <name>
        <xsl:value-of select="str[@name = 'resourceTitle']/text()"/>
      </name>

      <xsl:call-template name="respAuthorityFactory"/>

      <uuid>
        <xsl:value-of select="str[@name = 'metadataIdentifier']/text()"/>
      </uuid>

      <!-- For services, all INSPIRE themes are reported (and that was also the
      case in the excel reporting mode. -->
      <xsl:call-template name="InspireAnnexAndThemeFactory">
        <xsl:with-param name="inspireThemes"
                        select="distinct-values(arr[@name = 'inspireTheme']/str)"/>
      </xsl:call-template>


      <MdServiceExistence>
        <mdConformity>
          <xsl:value-of select="bool[@name = 'isAboveThreshold']"/>
        </mdConformity>

        <!-- The metadata record was harvested using CSW -->
        <discoveryAccessibility>true</discoveryAccessibility>

        <!-- ... the UUID of the CSW service is the one set in the harvester configuration -->
        <discoveryAccessibilityUuid>
          <xsl:value-of select="str[@name = 'harvesterUuid']/text()"/>
        </discoveryAccessibilityUuid>
      </MdServiceExistence>

      <xsl:variable name="serviceType" select="arr[@name = 'serviceType']/str"/>
      <xsl:variable name="inspireConformResource"
                    select="arr[@name = 'inspireConformResource']/bool[1]"/>

      <!-- Based on service type try to identify
      bast match based on protocol .... -->
      <xsl:variable name="links" select="arr[@name = 'link']"/>
      <xsl:variable name="linkBasedOnServiceType">
        <xsl:for-each select="$links/str">
          <xsl:variable name="token"
                        select="tokenize(text(), '\|')"/>
          <xsl:choose>
            <xsl:when
              test="$serviceType = 'view' and contains($token[1], 'WMS')">
              <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when test="$serviceType = 'download' and (
                contains($token[1], 'WFS') or contains($token[1], 'SOS') or contains($token[1], 'WCS'))">
              <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when
              test="$serviceType = 'discovery' and contains($token[1], 'CSW')">
              <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:when
              test="$serviceType = 'transformation' and contains($token[1], 'WPS')">
              <xsl:copy-of select="."/>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </xsl:variable>

      <NetworkService>
        <xsl:comment>By default, directlyAccessible is set to true. Adapt the
          value for restricted access service.
        </xsl:comment>
        <directlyAccessible>true</directlyAccessible>

        <!-- All online resources are taken into account,
        Resource Locator for data sets and dataset series
        - a link to a web with further instructions
        - a link to a service capabilities document
        - a link to the service WSDL document (SOAP Binding)
        - a link to a client application that directly accesses the service
        -->

        <xsl:choose>
          <xsl:when test="normalize-space($linkBasedOnServiceType) != ''">
            <xsl:variable name="link"
                          select="tokenize($linkBasedOnServiceType[1], '\|')"/>
            <xsl:comment>Found best match based on protocol (<xsl:value-of
              select="$link[1]"/>)
              for service type '<xsl:value-of select="$serviceType"/>'.
            </xsl:comment>
            <URL>
              <xsl:value-of select="$link[2]"/>
            </URL>
          </xsl:when>
          <xsl:otherwise>
            <xsl:comment>First link in the service metadata record.
            </xsl:comment>
            <URL>
              <xsl:value-of select="arr[@name = 'linkUrl']/str[1]/text()"/>
            </URL>
          </xsl:otherwise>
        </xsl:choose>

        <!-- -1 indicate unkown. Maybe some methodology
        could be adopted to populate the value in the
        metadata record ? -->
        <userRequest>-1</userRequest>

        <nnConformity>
          <xsl:value-of select="$inspireConformResource"/>
        </nnConformity>

        <NnServiceType>
          <xsl:value-of select="$serviceType"/>
        </NnServiceType>
      </NetworkService>
    </SpatialDataService>
  </xsl:template>


  <xsl:template mode="SpatialDataSetFactory"
                match="doc">
    <SpatialDataSet>
      <name>
        <xsl:value-of select="str[@name = 'resourceTitle']/text()"/>
      </name>

      <xsl:call-template name="respAuthorityFactory"/>

      <uuid>
        <xsl:value-of select="str[@name = 'metadataIdentifier']/text()"/>
      </uuid>

      <!-- For dataset the list of INSPIRE themes could be based
      on the first one only or on all values depending on the datasetMode parameter.
      Many themes are allowed from the schema point of view but the old way of reporting
      based on excel was only allowing one INSPIRE theme.-->
      <xsl:if test="$datasetMode = 'onlyFirstInspireTheme' and
                    count(distinct-values(arr[@name = 'inspireTheme']/str)) > 1">
        <xsl:comment>Only the first INSPIRE theme is reported among all
          (ie. <xsl:value-of
            select="string-join(distinct-values(arr[@name = 'inspireTheme']/str), ', ')"/>).
        </xsl:comment>
      </xsl:if>
      <xsl:call-template name="InspireAnnexAndThemeFactory">
        <xsl:with-param name="inspireThemes"
                        select="if ($datasetMode = 'onlyFirstInspireTheme')
                              then arr[@name = 'inspireTheme']/str[1]
                              else distinct-values(arr[@name = 'inspireTheme']/str)"/>

      </xsl:call-template>

      <xsl:apply-templates mode="SpatialDataSetDetailsFactory" select="."/>
    </SpatialDataSet>
  </xsl:template>


  <!-- Dataset is duplicated as many time as the number of INSPIRE themes -->
  <xsl:template mode="SpatialDataSetFactoryForEachInspireTheme"
                match="doc">
    <xsl:variable name="inspireThemes"
                  select="distinct-values(arr[@name = 'inspireTheme']/str[. != ''])"/>

    <xsl:variable name="inspireThemeNumbers"
                  select="count($inspireThemes)"/>

    <xsl:if test="$inspireThemeNumbers > 1">
      <xsl:comment>This data set contains
        <xsl:value-of select="$inspireThemeNumbers"/> INSPIRE themes (<xsl:value-of select="string-join($inspireThemes, ',')"/>).
        It was duplicated for each themes.
      </xsl:comment>
    </xsl:if>
    <xsl:variable name="document" select="."/>


    <xsl:for-each select="$inspireThemes">
      <SpatialDataSet>
        <name>
          <xsl:value-of select="$document/str[@name = 'resourceTitle']/text()"/>
        </name>

        <xsl:apply-templates mode="respAuthorityFactory"
                             select="$document"/>

        <uuid>
          <xsl:value-of
            select="$document/str[@name = 'metadataIdentifier']/text()"/>
        </uuid>
        
        <xsl:call-template name="InspireAnnexAndThemeFactory">
          <xsl:with-param name="inspireThemes"
                          select="."/>
        </xsl:call-template>

        <xsl:apply-templates mode="SpatialDataSetDetailsFactory"
                             select="$document"/>

      </SpatialDataSet>
    </xsl:for-each>
  </xsl:template>


  <xsl:template mode="SpatialDataSetDetailsFactory" match="doc">
    <!-- Coverage is mandatory but will probably
          be removed in the future. 0 value returned
          by default. -->
    <Coverage>
      <relevantArea>0</relevantArea>
      <actualArea>0</actualArea>
    </Coverage>


    <MdDataSetExistence>
      <!-- This conformity for the metadata -->
      <xsl:if test="bool[@name = 'isAboveThreshold'] = 'true'">
        <IRConformity>
          <!-- This conformity for the resource -->
          <structureCompliance>
            <xsl:value-of select="if (arr[@name = 'inspireConformResource']/bool[1] = 'true')
                                    then 'true' else 'false'"/>
          </structureCompliance>
        </IRConformity>
      </xsl:if>
      <MdAccessibility>
        <!-- Uuids are for each services operating the resource ?
        They could be multiple in some situation ? TODO ? -->

        <xsl:variable name="recordOperatedByType"
                      select="arr[@name = 'recordOperatedByType']"/>

        <!-- The record was harvested -->
        <discovery>true</discovery>
        <!-- ... the UUID of the CSW service is the one set in the harvester configuration -->
        <discoveryUuid>
          <xsl:value-of select="str[@name = 'harvesterUuid']/text()"/>
        </discoveryUuid>

        <!-- Is the data set accessible using a view -->
        <xsl:choose>
          <xsl:when test="count($recordOperatedByType[str = 'view']) > 0">
            <view>true</view>

            <xsl:variable name="nbOfServices"
                          select="count(distinct-values(arr[@name = 'recordOperatedByTypeview']/
                    str))"/>
            <xsl:if test="$nbOfServices > 1">
              <xsl:comment>Note: the data set is available in
                <xsl:value-of select="$nbOfServices"/> view services
                (ie. '<xsl:value-of select="string-join(distinct-values(arr[@name = 'recordOperatedByTypeview']/
                    str), ', ')"/>').
                Only the first one reported.
              </xsl:comment>
            </xsl:if>
            <viewUuid>
              <xsl:value-of select="arr[@name = 'recordOperatedByTypeview']/
                    str[1]/text()"/>
            </viewUuid>
          </xsl:when>
          <xsl:otherwise>
            <view>false</view>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:choose>
          <xsl:when test="count($recordOperatedByType[str = 'download']) > 0">
            <download>true</download>

            <xsl:variable name="nbOfServices"
                          select="count(distinct-values(arr[@name = 'recordOperatedByTypedownload']/
                    str))"/>
            <xsl:if test="$nbOfServices > 1">
              <xsl:comment>Note: the data set is available in
                <xsl:value-of select="$nbOfServices"/> download services
                (ie. '<xsl:value-of select="string-join(distinct-values(arr[@name = 'recordOperatedByTypedownload']/
                    str), ', ')"/>').
                Only the first one reported.
              </xsl:comment>
            </xsl:if>
            <downloadUuid>
              <xsl:value-of select="arr[@name = 'recordOperatedByTypedownload']/
                    str[1]/text()"/>
            </downloadUuid>
          </xsl:when>
          <xsl:otherwise>
            <download>false</download>
          </xsl:otherwise>
        </xsl:choose>


        <viewDownload>
          <xsl:value-of select="if (count($recordOperatedByType[str = 'view']) > 0 and
                                                  count($recordOperatedByType[str = 'download']) > 0)
                                              then true() else false()"/>
        </viewDownload>
      </MdAccessibility>
    </MdDataSetExistence>
  </xsl:template>


  <xsl:template name="respAuthorityFactory"
                mode="respAuthorityFactory" match="doc">
    <!-- OrganisationName of one of the IdentificationInfo/pointOfContact,
           First check if Custodian available, then Owner, then pointOfContact,
           then the first one of the list.
           -->
    <xsl:variable name="custodian"
                  select="arr[@name = 'custodianOrgForResource']/str[1]/text()"/>
    <xsl:variable name="owner"
                  select="arr[@name = 'ownerOrgForResource']/str[1]/text()"/>
    <xsl:variable name="pointOfContact"
                  select="arr[@name = 'pointOfContactOrgForResource']/str[1]/text()"/>
    <xsl:variable name="default"
                  select="arr[@name = 'OrgForResource']/str[1]/text()"/>
    <respAuthority>
      <xsl:value-of select="if ($custodian != '')
        then $custodian
        else if ($owner != '')
        then $owner
        else if ($pointOfContact != '')
        then $pointOfContact
        else $default"/>
    </respAuthority>
  </xsl:template>


  <xsl:variable name="inspireThemesMap">
    <map theme="Coordinate reference systems"
         monitoring="coordinateReferenceSystems" annex="I"/>
    <map theme="Elevation"
         monitoring="elevation" annex="II"/>
    <map theme="Land cover"
         monitoring="landCover" annex="II"/>
    <map theme="Orthoimagery"
         monitoring="orthoimagery" annex="II"/>
    <map theme="Geology"
         monitoring="geology" annex="II"/>
    <map theme="Statistical units"
         monitoring="statisticalUnits" annex="III"/>
    <map theme="Buildings"
         monitoring="buildings" annex="III"/>
    <map theme="Soil"
         monitoring="soil" annex="III"/>
    <map theme="Land use"
         monitoring="landUse" annex="III"/>
    <map theme="Human health and safety"
         monitoring="humanHealthAndSafety" annex="III"/>
    <map theme="Utility and governmental services"
         monitoring="utilityAndGovernmentalServices" annex="III"/>
    <map theme="Geographical grid systems"
         monitoring="geographicalGridSystems" annex="I"/>
    <map theme="Environmental monitoring facilities"
         monitoring="environmentalMonitoringFacilities" annex="III"/>
    <map theme="Production and industrial facilities"
         monitoring="productionAndIndustrialFacilities" annex="III"/>
    <map theme="Agricultural and aquaculture facilities"
         monitoring="agriculturalAndAquacultureFacilities" annex="III"/>
    <!--<map theme="Population distribution — demography"-->
    <map theme="Population distribution.*"
         monitoring="populationDistributionDemography" annex="III"/>
    <map
      theme="Area management/restriction/regulation zones and reporting units"
      monitoring="areaManagementRestrictionRegulationZonesAndReportingUnits"
      annex="III"/>
    <map theme="Natural risk zones"
         monitoring="naturalRiskZones" annex="III"/>
    <map theme="Atmospheric conditions"
         monitoring="atmosphericConditions" annex="III"/>
    <map theme="Meteorological geographical features"
         monitoring="meteorologicalGeographicalFeatures" annex="III"/>
    <map theme="Oceanographic geographical features"
         monitoring="oceanographicGeographicalFeatures" annex="III"/>
    <map theme="Sea regions"
         monitoring="seaRegions" annex="III"/>
    <map theme="Geographical names"
         monitoring="geographicalNames" annex="I"/>
    <map theme="Bio-geographical regions"
         monitoring="bioGeographicalRegions" annex="III"/>
    <map theme="Habitats and biotopes"
         monitoring="habitatsAndBiotopes" annex="III"/>
    <map theme="Species distribution"
         monitoring="speciesDistribution" annex="III"/>
    <map theme="Energy resources"
         monitoring="energyResources" annex="III"/>
    <map theme="Mineral resources"
         monitoring="mineralResources" annex="III"/>
    <map theme="Administrative units"
         monitoring="administrativeUnits" annex="I"/>
    <map theme="Addresses"
         monitoring="addresses" annex="I"/>
    <map theme="Cadastral parcels"
         monitoring="cadastralParcels" annex="I"/>
    <map theme="Transport networks"
         monitoring="transportNetworks" annex="I"/>
    <map theme="Hydrography"
         monitoring="hydrography" annex="I"/>
    <map theme="Protected sites"
         monitoring="protectedSites" annex="I"/>
  </xsl:variable>


  <!-- From the list of INSPIRE themes build the corresponding
  reporting fragment based on the map of themes in english,
  the corresponding monitoring enumeration value and its annex. -->
  <xsl:template name="InspireAnnexAndThemeFactory">
    <!-- INSPIRE theme or themes to be used to build the section. -->
    <xsl:param name="inspireThemes"/>

    <xsl:for-each select="$inspireThemes">
      <xsl:variable name="theme" select="."/>
      <xsl:variable name="mapping"
                    select="$inspireThemesMap/map[matches($theme, @theme, 'i')]"/>

      <xsl:if test="$mapping/@annex != ''">
        <Themes>
          <xsl:element name="{concat('Annex', $mapping/@annex)}">
            <xsl:value-of select="$mapping/@monitoring"/>
          </xsl:element>
        </Themes>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
