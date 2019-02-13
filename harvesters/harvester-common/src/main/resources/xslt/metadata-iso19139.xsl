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
                xmlns:srv="http://www.isotc211.org/2005/srv"
                xmlns:gmx="http://www.isotc211.org/2005/gmx"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:gn="http://www.fao.org/geonetwork"
                xmlns:daobs="http://daobs.org"
                xmlns:index="java:org.daobs.index.EsRequestBean"
                xmlns:saxon="http://saxon.sf.net/"
                extension-element-prefixes="saxon"
                exclude-result-prefixes="#all"
                version="2.0">

  <xsl:import href="metadata-inspire-constant.xsl"/>
  <xsl:include href="metadata-iso19139-medsea.xsl"/>

  <xsl:template match="gmi:MI_Metadata|gmd:MD_Metadata"
                mode="extract-uuid">
    <xsl:value-of select="gmd:fileIdentifier/gco:CharacterString"/>
  </xsl:template>

  <xsl:template match="gmi:MI_Metadata|gmd:MD_Metadata" mode="index">
    <!-- Main variables for the document -->
    <xsl:variable name="identifier" as="xs:string"
                  select="gmd:fileIdentifier/gco:CharacterString[. != '']"/>


    <xsl:variable name="mainLanguageCode" as="xs:string?"
                  select="gmd:language[1]/gmd:LanguageCode/
                        @codeListValue[normalize-space(.) != '']"/>
    <xsl:variable name="mainLanguage" as="xs:string?"
                  select="if ($mainLanguageCode) then $mainLanguageCode else
                    gmd:language[1]/gco:CharacterString[normalize-space(.) != '']"/>

    <xsl:variable name="otherLanguages" as="attribute()*"
                  select="gmd:locale/gmd:PT_Locale/
                        gmd:languageCode/gmd:LanguageCode/
                          @codeListValue[normalize-space(.) != '']"/>

    <!-- Record is dataset if no hierarchyLevel -->
    <xsl:variable name="isDataset" as="xs:boolean"
                  select="
                      count(gmd:hierarchyLevel[gmd:MD_ScopeCode/@codeListValue='dataset']) > 0 or
                      count(gmd:hierarchyLevel) = 0"/>
    <xsl:variable name="isService" as="xs:boolean"
                  select="
                      count(gmd:hierarchyLevel[gmd:MD_ScopeCode/@codeListValue='service']) > 0"/>

    <xsl:message>#<xsl:value-of select="count(preceding-sibling::gmd:MD_Metadata)"/>. <xsl:value-of select="$identifier"/></xsl:message>

    <!-- Create a first document representing the main record. -->
    <doc>
      <documentType>metadata</documentType>
      <documentStandard>iso19139</documentStandard>

      <!-- Index the metadata document as XML -->
      <document>
        <xsl:variable name="document">
          <xsl:apply-templates select="." mode="copy"/>
        </xsl:variable>
        <xsl:value-of select="saxon:serialize($document, 'default-serialize-mode')"/>
      </document>
      <id>
        <xsl:value-of select="if ($isFile) then concat($scope, '-', $identifier) else $identifier"/>
        <!--<xsl:value-of select="$identifier"/>-->
      </id>
      <metadataIdentifier>
        <xsl:value-of select="$identifier"/>
      </metadataIdentifier>

      <xsl:if test="$pointOfTruthURLPattern != ''">
        <pointOfTruthURL>
          <xsl:value-of
            select="replace($pointOfTruthURLPattern, '\{\{uuid\}\}', $identifier)"/>
        </pointOfTruthURL>
      </xsl:if>

      <xsl:for-each select="gmd:metadataStandardName/gco:CharacterString">
        <standardName>
          <xsl:value-of select="normalize-space(.)"/>
        </standardName>
      </xsl:for-each>

      <!-- Harvester details -->
      <scope>
        <xsl:value-of select="normalize-space($harvester/daobs:scope)"/>
      </scope>
      <harvesterId>
        <xsl:value-of select="normalize-space($harvester/daobs:url)"/>
      </harvesterId>
      <harvesterUuid>
        <xsl:value-of select="normalize-space($harvester/daobs:uuid)"/>
      </harvesterUuid>
      <harvestedDate>
        <xsl:value-of select="if ($harvester/daobs:date)
                              then $harvester/daobs:date
                              else format-dateTime(current-dateTime(), $dateFormat)"/>
      </harvestedDate>


      <isPublishedToAll>
        <xsl:value-of select="gn:info/isPublishedToAll"/>
      </isPublishedToAll>

      <!-- Indexing record information -->
      <!-- # Date -->
      <!-- TODO improve date formatting maybe using Joda parser
      Select first one because some records have 2 dates !
      eg. fr-784237539-bdref20100101-0105

      Remove millisec and timezone until not supported
      eg. 2017-02-08T13:18:03.138+00:02
      -->
      <xsl:for-each select="gmd:dateStamp/*[text() != '' and position() = 1]">
        <xsl:choose>
          <xsl:when test="matches(., '^\d{4}(-\d{2})?(-\d{2})?((T\d{2}(:\d{2})?(:\d{2}(.\d+)?)?)+(\+.*)?)?$')">
            <dateStamp>
              <xsl:variable name="date"
                            select="if (name() = 'gco:Date' and string-length(.) = 4)
                              then concat(., '-01-01T00:00:00')
                              else if (name() = 'gco:Date' and string-length(.) = 7)
                              then concat(., '-01T00:00:00')
                              else if (name() = 'gco:Date' or string-length(.) = 10)
                              then concat(., 'T00:00:00')
                              else if (contains(., '.'))
                              then tokenize(., '\.')[1]
                              else ."/>

              <xsl:value-of select="translate(string(
                                 adjust-dateTime-to-timezone(
                                    xs:dateTime($date),
                                    xs:dayTimeDuration('PT0H'))
                                   ), 'Z', '')"/>
            </dateStamp>
          </xsl:when>
          <xsl:otherwise>
            <!-- Some invalid date in DE, FI. -->
            <xsl:variable name="msg">WARNING: <xsl:value-of select="$identifier"/> / Wrong date time format <xsl:value-of select="."/>. Default to empty.</xsl:variable>
            <xsl:message><xsl:value-of select="$msg"/></xsl:message>
            <error><xsl:value-of select="$msg"/></error>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>


      <!-- # Languages -->
      <mainLanguage>
        <xsl:value-of select="$mainLanguage"/>
      </mainLanguage>

      <xsl:for-each select="$otherLanguages">
        <otherLanguage>
          <xsl:value-of select="."/>
        </otherLanguage>
      </xsl:for-each>


      <!-- # Resource type -->
      <xsl:choose>
        <xsl:when test="$isDataset">
          <resourceType>dataset</resourceType>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="gmd:hierarchyLevel/gmd:MD_ScopeCode/
                              @codeListValue[normalize-space(.) != '']">
            <resourceType>
              <xsl:value-of select="."/>
            </resourceType>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>


      <!-- Indexing metadata contact -->
      <xsl:apply-templates mode="index-contact" select="gmd:contact">
        <xsl:with-param name="fieldSuffix" select="''"/>
      </xsl:apply-templates>

      <!-- Indexing all codelist

      Indexing method is:
      <gmd:accessConstraints>
        <gmd:MD_RestrictionCode codeListValue="otherRestrictions"
        is indexed as
        codelist_accessConstraints:otherRestrictions

        Exclude some useless codelist like
        Contact role, Date type.
      -->
      <xsl:for-each select=".//*[@codeListValue != '' and
                            name() != 'gmd:CI_RoleCode' and
                            name() != 'gmd:CI_DateTypeCode' and
                            name() != 'gmd:LanguageCode'
                            ]">
        <xsl:element name="codelist_{local-name(..)}">
          <xsl:value-of select="@codeListValue"/>
        </xsl:element>
      </xsl:for-each>


      <!-- Indexing resource information
      TODO: Should we support multiple identification in the same record
      eg. nl db60a314-5583-437d-a2ff-1e59cc57704e
      Also avoid error when records contains multiple MD_IdentificationInfo
      or SRV_ServiceIdentification or a mix
      eg. de 8bb5334f-558b-982b-7b12-86ea486540d7
      -->
      <xsl:for-each select="gmd:identificationInfo[1]/*[1]">
        <xsl:for-each select="gmd:citation/gmd:CI_Citation">
          <resourceTitle>
            <xsl:value-of select="gmd:title/gco:CharacterString/text()"/>
          </resourceTitle>
          <resourceAltTitle>
            <xsl:value-of
              select="gmd:alternateTitle/gco:CharacterString/text()"/>
          </resourceAltTitle>

          <xsl:for-each select="gmd:date/gmd:CI_Date[
                                  gmd:date/*/text() != '' and
                                  matches(gmd:date/*/text(), '[0-9]{4}.*')]">
            <xsl:variable name="dateType"
                          select="gmd:dateType[1]/gmd:CI_DateTypeCode/@codeListValue"
                          as="xs:string?"/>
            <xsl:variable name="date"
                          select="string(gmd:date[1]/gco:Date|gmd:date[1]/gco:DateTime)"/>

            <xsl:choose>
              <xsl:when test="matches(., '^\d{4}(-\d{2})?(-\d{2})?((T\d{2}(:\d{2})?(:\d{2}(.\d+)?)?)+(\+.*)?)?$')">
                <xsl:element name="{$dateType}DateForResource">
                  <xsl:value-of select="$date"/>
                </xsl:element>
              </xsl:when>
              <xsl:otherwise>
                <error>WARNING: Date <xsl:value-of select="$dateType"/> with value '<xsl:value-of select="$date"/>' was not a valid date format.</error>
              </xsl:otherwise>
            </xsl:choose>

            <xsl:element name="{$dateType}YearForResource">
              <xsl:value-of select="substring($date, 0, 5)"/>
            </xsl:element>
            <xsl:element name="{$dateType}MonthForResource">
              <xsl:value-of select="substring($date, 0, 8)"/>
            </xsl:element>
          </xsl:for-each>

          <xsl:for-each
            select="gmd:presentationForm/gmd:CI_PresentationFormCode/@codeListValue[. != '']">
            <presentationForm>
              <xsl:value-of select="."/>
            </presentationForm>
          </xsl:for-each>
        </xsl:for-each>

        <resourceAbstract>
          <xsl:value-of select="substring(
                gmd:abstract/gco:CharacterString,
                0, $maxFieldLength)"/>
        </resourceAbstract>


        <!-- Indexing resource contact -->
        <xsl:apply-templates mode="index-contact"
                             select="gmd:pointOfContact">
          <xsl:with-param name="fieldSuffix" select="'ForResource'"/>
        </xsl:apply-templates>

        <xsl:for-each select="gmd:credit/*[. != '']">
          <resourceCredit>
            <xsl:value-of select="."/>
          </resourceCredit>
        </xsl:for-each>


        <xsl:variable name="overviews"
                      select="gmd:graphicOverview/gmd:MD_BrowseGraphic/
                              gmd:fileName/gco:CharacterString[. != '']"/>
        <hasOverview>
          <xsl:value-of select="if (count($overviews) > 0) then 'true' else 'false'"/>
        </hasOverview>

        <xsl:for-each select="$overviews">
          <overviewUrl>
            <xsl:value-of select="."/>
          </overviewUrl>
        </xsl:for-each>

        <xsl:for-each
          select="gmd:language/gco:CharacterString|gmd:language/gmd:LanguageCode/@codeListValue">
          <resourceLanguage>
            <xsl:value-of select="."/>
          </resourceLanguage>
        </xsl:for-each>


        <!-- TODO: create specific INSPIRE template or mode -->
        <!-- INSPIRE themes

        Select the first thesaurus title because some records
        may contains many even if invalid.

        Also get the first title at it may happen that a record
        have more than one.

        Select any thesaurus having the title containing "INSPIRE themes".
        Some records have "GEMET-INSPIRE themes" eg. sk:ee041534-b8f3-4683-b9dd-9544111a0712
        Some other "GEMET - INSPIRE themes"

        Take in account gmd:descriptiveKeywords or srv:keywords
        -->
        <!-- TODO: Some MS may be using a translated version of the thesaurus title -->
        <xsl:variable name="inspireKeywords"
                      select="*/gmd:MD_Keywords[
                      contains(lower-case(
                       gmd:thesaurusName[1]/*/gmd:title[1]/*[1]/text()
                       ), 'gemet') and
                       contains(lower-case(
                       gmd:thesaurusName[1]/*/gmd:title[1]/*[1]/text()
                       ), 'inspire')]
                  /gmd:keyword"/>
        <xsl:for-each
          select="$inspireKeywords">
          <xsl:variable name="position" select="position()"/>
          <xsl:for-each select="gco:CharacterString[. != '']|
                                gmx:Anchor[. != '']">
            <xsl:variable name="inspireTheme" as="xs:string"
                          select="index:analyzeField('synInspireThemes', text())"/>

            <inspireTheme_syn>
              <xsl:value-of select="text()"/>
            </inspireTheme_syn>
            <inspireTheme>
              <xsl:value-of select="lower-case($inspireTheme)"/>
            </inspireTheme>

            <!--
            WARNING: Here we only index the first keyword in order
            to properly compute one INSPIRE annex.
            -->
            <xsl:if test="$position = 1">
              <inspireThemeFirst_syn>
                <xsl:value-of select="text()"/>
              </inspireThemeFirst_syn>
              <inspireThemeFirst>
                <xsl:value-of select="lower-case($inspireTheme)"/>
              </inspireThemeFirst>
              <inspireAnnexForFirstTheme>
                <xsl:value-of
                  select="index:analyzeField('synInspireAnnexes', $inspireTheme)"/>
              </inspireAnnexForFirstTheme>
            </xsl:if>
            <inspireAnnex>
              <xsl:value-of
                select="index:analyzeField('synInspireAnnexes', $inspireTheme)"/>
            </inspireAnnex>
          </xsl:for-each>
        </xsl:for-each>

        <!-- For services, the count does not take into account
        dataset's INSPIRE themes which are transfered to the service
        by service-dataset-task. -->
        <inspireThemeNumber>
          <xsl:value-of
            select="count($inspireKeywords)"/>
        </inspireThemeNumber>

        <hasInspireTheme>
          <xsl:value-of
            select="if (count($inspireKeywords) > 0) then 'true' else 'false'"/>
        </hasInspireTheme>

        <!-- Index all keywords -->
        <xsl:variable name="keywords"
                      select="*/gmd:MD_Keywords/
                                gmd:keyword/gco:CharacterString|
                              */gmd:MD_Keywords/
                                gmd:keyword/gmd:PT_FreeText/gmd:textGroup/
                                  gmd:LocalisedCharacterString"/>

        <tagNumber>
          <xsl:value-of select="count($keywords)"/>
        </tagNumber>

        <xsl:for-each select="$keywords">
          <tag>
            <xsl:value-of select="text()"/>
          </tag>
        </xsl:for-each>

        <xsl:variable name="isOpenData">
          <xsl:for-each select="$keywords">
            <xsl:if test="matches(
                            normalize-unicode(replace(normalize-unicode(
                              lower-case(normalize-space(text())), 'NFKD'), '\p{Mn}', ''), 'NFKC'),
                            $openDataKeywords)">
              <xsl:value-of select="'true'"/>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="normalize-space($isOpenData) != ''">
            <isOpenData>true</isOpenData>
          </xsl:when>
          <xsl:otherwise>
            <isOpenData>false</isOpenData>
          </xsl:otherwise>
        </xsl:choose>

        <!-- Index keywords which are of type place -->
        <xsl:for-each
          select="*/gmd:MD_Keywords/
                          gmd:keyword[gmd:type/gmd:MD_KeywordTypeCode/@codeListValue = 'place']/
                            gco:CharacterString|
                        */gmd:MD_Keywords/
                          gmd:keyword[gmd:type/gmd:MD_KeywordTypeCode/@codeListValue = 'place']/
                            gmd:PT_FreeText/gmd:textGroup/gmd:LocalisedCharacterString">
          <geotag>
            <xsl:value-of select="text()"/>
          </geotag>
        </xsl:for-each>



        <xsl:for-each-group select="*/gmd:MD_Keywords/gmd:thesaurusName/*/
                                        gmd:title/(gco:CharacterString|gmx:Anchor)"
                            group-by=".">
          <thesaurus><xsl:value-of select="."/></thesaurus>
        </xsl:for-each-group>


        <!-- Index all keywords having a specific thesaurus -->
        <xsl:for-each
          select="*/gmd:MD_Keywords[gmd:thesaurusName]/
                            gmd:keyword">

          <xsl:variable name="thesaurusName"
                        select="../gmd:thesaurusName[1]/gmd:CI_Citation/
                                  gmd:title[1]/(gco:CharacterString|gmx:Anchor)"/>

          <xsl:variable name="thesaurusId"
                        select="normalize-space(../gmd:thesaurusName/gmd:CI_Citation/
                                  gmd:identifier[position() = 1]/gmd:MD_Identifier/
                                    gmd:code/(gco:CharacterString|gmx:Anchor)/text())"/>

          <xsl:variable name="key">
            <xsl:choose>
              <xsl:when test="$thesaurusId != ''">
                <xsl:value-of select="$thesaurusId"/>
              </xsl:when>
              <!-- Try to build a thesaurus key based on the name
              by removing space - to be improved. -->
              <xsl:when test="normalize-space($thesaurusName) != ''">
                <!--TODO handle special character to build a valid key usable for field-->
                <xsl:value-of select="replace($thesaurusName, '[^a-zA-Z0-9]', '')"/>
              </xsl:when>
            </xsl:choose>
          </xsl:variable>

          <xsl:if test="normalize-space($key) != ''">
            <!-- Index keyword characterString including multilingual ones
             and element like gmx:Anchor including the href attribute
             which may contains keyword identifier. -->
            <xsl:for-each select="*[normalize-space() != '']|
                                  */@xlink:href[normalize-space() != '']|
                                  gmd:PT_FreeText/gmd:textGroup/gmd:LocalisedCharacterString[normalize-space() != '']">
              <xsl:element name="thesaurus_{replace($key, '[^a-zA-Z0-9]', '')}">
                <xsl:value-of select="normalize-space(.)"/>
              </xsl:element>
            </xsl:for-each>
          </xsl:if>
        </xsl:for-each>


        <xsl:for-each select="gmd:topicCategory/gmd:MD_TopicCategoryCode">
          <topic>
            <xsl:value-of select="."/>
          </topic>
          <!-- TODO: Get translation ? -->
        </xsl:for-each>


        <xsl:for-each select="gmd:spatialResolution/gmd:MD_Resolution">
          <xsl:for-each
            select="gmd:equivalentScale/gmd:MD_RepresentativeFraction/gmd:denominator/gco:Integer[. != '']">
            <resolutionScaleDenominator>
              <xsl:value-of select="."/>
            </resolutionScaleDenominator>
          </xsl:for-each>

          <xsl:for-each select="gmd:distance/gco:Distance[. != '']">
            <resolutionDistance>
              <xsl:value-of select="concat(., ' ', @uom)"/>
            </resolutionDistance>
          </xsl:for-each>
        </xsl:for-each>

        <xsl:for-each
          select="gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode/@codeListValue[. != '']">
          <spatialRepresentationType>
            <xsl:value-of select="."/>
          </spatialRepresentationType>
        </xsl:for-each>


        <xsl:for-each select="gmd:resourceConstraints">
          <xsl:for-each
            select="*/gmd:accessConstraints/gmd:MD_RestrictionCode/@codeListValue[. != '']">
            <accessConstraints>
              <xsl:value-of select="."/>
            </accessConstraints>
          </xsl:for-each>
          <xsl:for-each
            select="*/gmd:otherConstraints/gco:CharacterString[. != '']">
            <otherConstraints>
              <xsl:value-of select="."/>
            </otherConstraints>
          </xsl:for-each>
          <xsl:for-each
            select="*/gmd:classification/gmd:MD_ClassificationCode/@codeListValue[. != '']">
            <constraintClassification>
              <xsl:value-of select="."/>
            </constraintClassification>
          </xsl:for-each>
          <xsl:for-each
            select="*/gmd:useLimitation/gco:CharacterString[. != '']">
            <useLimitation>
              <xsl:value-of select="."/>
            </useLimitation>
          </xsl:for-each>
        </xsl:for-each>


        <xsl:for-each select="*/gmd:EX_Extent">

          <xsl:for-each select="gmd:geographicElement/gmd:EX_GeographicDescription/
            gmd:geographicIdentifier/gmd:MD_Identifier/
            gmd:code/gco:CharacterString[normalize-space(.) != '']">
            <geoTag>
              <xsl:value-of select="."/>
            </geoTag>
          </xsl:for-each>

          <!-- TODO: index bounding polygon -->
          <xsl:variable name="bboxes"
                        select=".//gmd:EX_GeographicBoundingBox[
                                ./gmd:westBoundLongitude/gco:Decimal castable as xs:decimal and
                                ./gmd:eastBoundLongitude/gco:Decimal castable as xs:decimal and
                                ./gmd:northBoundLatitude/gco:Decimal castable as xs:decimal and
                                ./gmd:southBoundLatitude/gco:Decimal castable as xs:decimal
                                ]"/>
          <xsl:for-each select="$bboxes">
            <xsl:variable name="format" select="'#0.000000'"></xsl:variable>

            <xsl:variable name="w"
                          select="format-number(./gmd:westBoundLongitude/gco:Decimal/text(), $format)"/>
            <xsl:variable name="e"
                          select="format-number(./gmd:eastBoundLongitude/gco:Decimal/text(), $format)"/>
            <xsl:variable name="n"
                          select="format-number(./gmd:northBoundLatitude/gco:Decimal/text(), $format)"/>
            <xsl:variable name="s"
                          select="format-number(./gmd:southBoundLatitude/gco:Decimal/text(), $format)"/>

            <!-- Example: ENVELOPE(-10, 20, 15, 10) which is minX, maxX, maxY, minY order
            http://wiki.apache.org/solr/SolrAdaptersForLuceneSpatial4
            https://cwiki.apache.org/confluence/display/solr/Spatial+Search

            bbox field type limited to one. TODO
            <xsl:if test="position() = 1">
              <bbox>
                <xsl:text>ENVELOPE(</xsl:text>
                <xsl:value-of select="$w"/>
                <xsl:text>,</xsl:text>
                <xsl:value-of select="$e"/>
                <xsl:text>,</xsl:text>
                <xsl:value-of select="$n"/>
                <xsl:text>,</xsl:text>
                <xsl:value-of select="$s"/>
                <xsl:text>)</xsl:text>
              </field>
            </xsl:if>
            -->
            <xsl:choose>
              <xsl:when test="-180 &lt;= number($e) and number($e) &lt;= 180 and
                              -180 &lt;= number($w) and number($w) &lt;= 180 and
                              -90 &lt;= number($s) and number($s) &lt;= 90 and
                              -90 &lt;= number($n) and number($n) &lt;= 90">
                <xsl:choose>
                  <xsl:when test="$e = $w and $s = $n">
                    <location><xsl:value-of select="concat($s, ',', $w)"/></location>
                  </xsl:when>
                  <xsl:when
                    test="($e = $w and $s != $n) or ($e != $w and $s = $n)">
                    <!-- Probably an invalid bbox indexing a point only -->
                    <location><xsl:value-of select="concat($s, ',', $w)"/></location>
                  </xsl:when>
                  <xsl:otherwise>

                    <!-- TODO: avoid to build an array of geom.
                    Elastic will fails on this with org.elasticsearch.index.mapper.MapperParsingException: failed to parse [geom]
                    and a multipolygon should be created instead probably.
-->
                    <!--<xsl:message>  - pos: <xsl:value-of select="position()"/> </xsl:message>
                    <xsl:if test="position() = 1">
                      <xsl:variable name="geom">
                        <xsl:text>{"type": "polygon",</xsl:text>
                        <xsl:text>"coordinates": [</xsl:text>
                        <xsl:value-of select="concat('[', $w, ',', $s, ']')"/>
                        <xsl:text>,</xsl:text>
                        <xsl:value-of select="concat('[', $e, ',', $s, ']')"/>
                        <xsl:text>,</xsl:text>
                        <xsl:value-of select="concat('[', $e, ',', $n, ']')"/>
                        <xsl:text>,</xsl:text>
                        <xsl:value-of select="concat('[', $w, ',', $n, ']')"/>
                        <xsl:text>,</xsl:text>
                        <xsl:value-of select="concat('[', $w, ',', $s, ']')"/>
                        <xsl:text>]}</xsl:text>
                      </xsl:variable>
                      <xsl:message>geom: <xsl:value-of select="$geom"/> </xsl:message>
                      <geom>
                        <xsl:value-of select="$geom"/>
                      </geom>
                    </xsl:if>-->

                    <location><xsl:value-of select="concat(
                                              (number($s) + number($n)) div 2,
                                              ',',
                                              (number($w) + number($e)) div 2)"/></location>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise></xsl:otherwise>
            </xsl:choose>

            <!--<xsl:value-of select="($e + $w) div 2"/>,<xsl:value-of select="($n + $s) div 2"/></field>-->
          </xsl:for-each>
        </xsl:for-each>


        <!-- Service information -->
        <xsl:for-each select="srv:serviceType/gco:LocalName">
          <serviceType>
            <xsl:value-of select="text()"/>
          </serviceType>
          <xsl:variable name="inspireServiceType" as="xs:string"
                        select="index:analyzeField(
                        'keepInspireServiceTypes', text())"/>
          <xsl:if test="$inspireServiceType != ''">
            <inspireServiceType>
              <xsl:value-of select="lower-case($inspireServiceType)"/>
            </inspireServiceType>
          </xsl:if>
          <xsl:if test="following-sibling::srv:serviceTypeVersion">
            <serviceTypeAndVersion>
              <xsl:value-of select="concat(
                        text(),
                        $separator,
                        following-sibling::srv:serviceTypeVersion/gco:CharacterString/text())"/>
            </serviceTypeAndVersion>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>


      <xsl:for-each select="gmd:referenceSystemInfo/gmd:MD_ReferenceSystem">
        <xsl:for-each select="gmd:referenceSystemIdentifier/gmd:RS_Identifier">
          <xsl:variable name="crs" select="gmd:code/gco:CharacterString"/>

          <xsl:if test="$crs != ''">
            <coordinateSystem>
              <xsl:value-of select="$crs"/>
            </coordinateSystem>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>


      <!-- INSPIRE Conformity -->

      <!-- Conformity for services -->
      <xsl:choose>
        <xsl:when test="$isService">
          <xsl:for-each-group select="gmd:dataQualityInfo/*/gmd:report"
                              group-by="*/gmd:result/*/gmd:specification/gmd:CI_Citation/
        gmd:title/gco:CharacterString">
            <xsl:variable name="title" select="current-grouping-key()"/>
            <xsl:variable name="matchingEUText"
                          select="if ($inspireRegulationLaxCheck)
                                  then daobs:search-in-contains($eu9762009/*, $title)
                                  else daobs:search-in($eu9762009/*, $title)"/>
            <xsl:if test="count($matchingEUText) = 1">
              <xsl:variable name="pass"
                            select="*/gmd:result/*/gmd:pass/gco:Boolean"/>
              <inspireConformResource>
                <xsl:value-of select="$pass"/>
              </inspireConformResource>
            </xsl:if>
          </xsl:for-each-group>
        </xsl:when>
        <xsl:otherwise>
          <!-- Conformity for dataset -->
          <xsl:for-each-group select="gmd:dataQualityInfo/*/gmd:report"
                              group-by="*/gmd:result/*/gmd:specification/gmd:CI_Citation/
        gmd:title/gco:CharacterString">

            <xsl:variable name="title" select="current-grouping-key()"/>
            <xsl:variable name="matchingEUText"
                          select="if ($inspireRegulationLaxCheck)
                                  then daobs:search-in-contains($eu10892010/*, $title)
                                  else daobs:search-in($eu10892010/*, $title)"/>

            <xsl:if test="count($matchingEUText) = 1">
              <xsl:variable name="pass"
                            select="*/gmd:result/*/gmd:pass/gco:Boolean"/>
              <inspireConformResource>
                <xsl:value-of select="$pass"/>
              </inspireConformResource>
            </xsl:if>
          </xsl:for-each-group>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:for-each-group select="gmd:dataQualityInfo/*/gmd:report"
                          group-by="*/gmd:result/*/gmd:specification/
                                      */gmd:title/gco:CharacterString">
        <xsl:variable name="title" select="current-grouping-key()"/>
        <xsl:variable name="pass" select="*/gmd:result/*/gmd:pass/gco:Boolean"/>
        <xsl:if test="$pass">
          <xsl:element name="conformTo_{replace(normalize-space($title), '[^a-zA-Z0-9]', '')}">
            <xsl:value-of select="$pass"/>
          </xsl:element>
        </xsl:if>
      </xsl:for-each-group>


      <xsl:for-each select="gmd:dataQualityInfo/*">

        <xsl:for-each select="gmd:lineage/gmd:LI_Lineage/
                                gmd:statement/gco:CharacterString[. != '']">
          <lineage>
            <xsl:value-of select="."/>
          </lineage>
        </xsl:for-each>


        <!-- Indexing measure value -->
        <xsl:for-each select="gmd:report/*[
                normalize-space(gmd:nameOfMeasure[0]/gco:CharacterString) != '']">
          <xsl:variable name="measureName"
                        select="replace(
                                normalize-space(
                                  gmd:nameOfMeasure[0]/gco:CharacterString), ' ', '-')"/>
          <xsl:for-each select="gmd:result/gmd:DQ_QuantitativeResult/gmd:value">
            <xsl:if test=". != ''">
              <xsl:element name="measure_{replace($measureName, '[^a-zA-Z0-9]', '')}">
                <xsl:value-of select="."/>
              </xsl:element>
            </xsl:if>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>


      <xsl:for-each select="gmd:distributionInfo/*">
        <xsl:for-each
          select="gmd:distributionFormat/*/gmd:name/gco:CharacterString">
          <format>
            <xsl:value-of select="."/>
          </format>
        </xsl:for-each>

        <xsl:for-each select="gmd:transferOptions/*/
                                gmd:onLine/*[gmd:linkage/gmd:URL != '']">

          <xsl:variable name="protocol" select="gmd:protocol/gco:CharacterString/text()"/>

          <linkUrl>
            <xsl:value-of select="gmd:linkage/gmd:URL"/>
          </linkUrl>
          <linkProtocol><xsl:value-of select="$protocol"/></linkProtocol>
          <link>
            <xsl:value-of select="gmd:protocol/*/text()"/>
            <xsl:text>|</xsl:text>
            <xsl:value-of select="gmd:linkage/gmd:URL"/>
            <xsl:text>|</xsl:text>
            <xsl:value-of select="gmd:name/*/text()"/>
            <xsl:text>|</xsl:text>
            <xsl:value-of select="gmd:description/*/text()"/>
          </link>

          <xsl:if test="$operatesOnSetByProtocol and normalize-space($protocol) != ''">
            <xsl:if test="daobs:contains($protocol, 'wms')">
              <recordOperatedByType>view</recordOperatedByType>
            </xsl:if>
            <xsl:if test="daobs:contains($protocol, 'wfs') or
                          daobs:contains($protocol, 'wcs') or
                          daobs:contains($protocol, 'download')">
              <recordOperatedByType>download</recordOperatedByType>
            </xsl:if>
          </xsl:if>
        </xsl:for-each>
      </xsl:for-each>

      <!-- Service/dataset relation. Create document for the association.
      Note: not used for indicators anymore
       This could be used to retrieve :
      {!child of=documentType:metadata}+documentType:metadata +id:9940c446-6fd4-4ab3-a4de-7d0ee028a8d1
      {!child of=documentType:metadata}+documentType:metadata +resourceType:service +serviceType:view
      {!child of=documentType:metadata}+documentType:metadata +resourceType:service +serviceType:download
       -->
      <xsl:for-each
        select="gmd:identificationInfo/srv:SV_ServiceIdentification/srv:operatesOn">
        <xsl:variable name="associationType" select="'operatesOn'"/>
        <xsl:variable name="serviceType"
                      select="../srv:serviceType/gco:LocalName"/>
        <!--<xsl:variable name="relatedTo" select="@uuidref"/>-->
        <xsl:variable name="getRecordByIdId">
          <xsl:if test="@xlink:href != ''">
            <!--<xsl:message>operateOn xlink <xsl:value-of select="@xlink:href"/></xsl:message>-->
            <xsl:choose>
              <!-- Special CY case
              https://taskman.eionet.europa.eu/issues/100677
              -->
              <xsl:when test="contains(@xlink:href, 'eservices.dls.moi.gov.cy/geoportal_inspire/rest/document')">
                <xsl:variable name="remoteRecordUuid"
                              select="document(@xlink:href)//gmd:fileIdentifier/gco:CharacterString"/>
                <!--<xsl:message>operateOn xlink <xsl:value-of select="$remoteRecordUuid"/></xsl:message>-->

                <xsl:value-of select="$remoteRecordUuid"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:analyze-string select="@xlink:href"
                                    regex=".*[i|I][d|D]=([\w\-\.\{{\}}]*).*">
                  <xsl:matching-substring>
                    <xsl:value-of select="regex-group(1)"/>
                  </xsl:matching-substring>
                </xsl:analyze-string>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
        </xsl:variable>

        <xsl:variable name="datasetId">
          <xsl:choose>
            <xsl:when test="$getRecordByIdId != ''">
              <xsl:value-of select="$getRecordByIdId"/>
            </xsl:when>
            <xsl:when test="@uuidref != ''">
              <xsl:value-of select="@uuidref"/>
            </xsl:when>
          </xsl:choose>
        </xsl:variable>

        <xsl:if test="$datasetId != ''">
          <recordOperateOn>
            <xsl:value-of select="$datasetId"/>
          </recordOperateOn>
        </xsl:if>
      </xsl:for-each>

      <!-- Index more fields in this element -->
      <xsl:apply-templates mode="index-extra-fields" select="."/>
    </doc>

    <!-- Index more documents for this element -->
    <xsl:apply-templates mode="index-extra-documents" select="."/>

  </xsl:template>


  <xsl:template mode="index-contact" match="*[gmd:CI_ResponsibleParty]">
    <xsl:param name="fieldSuffix" select="''" as="xs:string"/>

    <!-- Select the first child which should be a CI_ResponsibleParty.
    Some records contains more than one CI_ResponsibleParty which is
    not valid and they will be ignored.
     Same for organisationName eg. de:b86a8604-bf78-480f-a5a8-8edff5586679 -->
    <xsl:variable name="organisationName"
                  select="*[1]/gmd:organisationName[1]/(gco:CharacterString|gmx:Anchor)"
                  as="xs:string*"/>

    <xsl:variable name="role"
                  select="replace(*[1]/gmd:role/*/@codeListValue, '[^a-zA-Z0-9]', '')"
                  as="xs:string?"/>
    <xsl:if test="normalize-space($organisationName) != ''">
      <xsl:element name="Org{$fieldSuffix}">
        <xsl:value-of select="$organisationName"/>
      </xsl:element>
      <xsl:element name="{$role}Org{$fieldSuffix}">
        <xsl:value-of select="$organisationName"/>
      </xsl:element>
    </xsl:if>
    <xsl:element name="contact{$fieldSuffix}">{
      org:"<xsl:value-of
        select="replace($organisationName, '&quot;', '\\&quot;')"/>",
      role:"<xsl:value-of select="$role"/>"
      }
    </xsl:element>
  </xsl:template>
</xsl:stylesheet>
