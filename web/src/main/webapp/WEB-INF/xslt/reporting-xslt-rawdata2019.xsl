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


      <priorityDataset>
        <xsl:value-of select="str[@name = 'tagPriorityDataset']/text() = 'true'"/>
      </priorityDataset>
      <regional>
        <xsl:value-of select="str[@name = 'tagRegional']/text() = 'true'"/>
      </regional>
      <national>
        <xsl:value-of select="str[@name = 'tagNational']/text() = 'true'"/>
      </national>


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

      <priorityDataset>
        <xsl:value-of select="str[@name = 'tagPriorityDataset']/text()"/>
      </priorityDataset>
      <regional>
        <xsl:value-of select="str[@name = 'tagRegional']/text()"/>
      </regional>
      <national>
        <xsl:value-of select="str[@name = 'tagNational']/text()"/>
      </national>

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

    <xsl:for-each select="distinct-values($inspireThemes)">
      <xsl:variable name="theme" select="."/>
      <xsl:variable name="mapping"
                    select="$inspireThemesMap/map[matches($theme, @theme, 'i')]"/>

      <xsl:if test="$mapping/@annex != ''">
        <Themes>
          <xsl:element name="{concat('Annex', $mapping[1]/@annex)}">
            <xsl:value-of select="$mapping/@monitoring"/>
          </xsl:element>
        </Themes>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
