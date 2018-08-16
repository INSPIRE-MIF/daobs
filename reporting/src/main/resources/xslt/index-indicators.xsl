<?xml version="1.0" encoding="UTF-8"?>

<!--
  ~ Copyright 2014-2016 European Environment Agency
  ~
  ~ Licensed under the EUPL, Version 1.1 or – as soon
  ~ they will be approved by the European Commission -
  ~ subsequent versions of the EUPL (the "Licence");
  ~ You may not use this work except in compliance
  ~ with the Licence.
  ~ You may obtain a copy of the Licence at:
  ~
  ~ https://joinup.ec.europa.eu/community/eupl/og_page/eupl
  ~
  ~ Unless required by applicable law or agreed to in
  ~ writing, software distributed under the Licence is
  ~ distributed on an "AS IS" basis,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
  ~ either express or implied.
  ~ See the Licence for the specific language governing
  ~ permissions and limitations under the Licence.
  -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:monitoring="http://inspire.jrc.ec.europa.eu/monitoringreporting/monitoring"
                xmlns:daobs="http://daobs.org"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                extension-element-prefixes="saxon"
                exclude-result-prefixes="#all"
                version="2.0">

  <xsl:output indent="yes"/>

  <xsl:include href="constant.xsl"/>
  <xsl:include href="metadata-inspire-constant.xsl"/>

  <xsl:param name="yearlyIndicators" select="'false'"/>

  <xsl:variable name="indicatorLabels">
    <indicator id="SDSv_Num">
      Nb of spatial data services
    </indicator>
    <indicator id="NSv_NumDiscServ">
      Nb of discovery services
    </indicator>
    <indicator id="NSv_NumViewServ">
      Nb of view services
    </indicator>
    <indicator id="NSv_NumDownlServ">
      Nb of download services
    </indicator>
    <indicator id="NSv_NumInvkServ">
      Nb of invoke services
    </indicator>
    <indicator id="NSv_NumTransfServ">
      Nb of transformation services
    </indicator>
    <indicator id='MDv11_aI_t1'>
      Nb of spatial data sets for theme Coordinate reference systems that have metadata
    </indicator>
    <indicator id='MDv12_aII_t2'>
      Nb of spatial data sets for theme Elevation that have metadata
    </indicator>
    <indicator id='MDv12_aII_t3'>
      Nb of spatial data sets for theme Land cover that have metadata
    </indicator>
    <indicator id='MDv12_aII_t4'>
      Nb of spatial data sets for theme Orthoimagery that have metadata
    </indicator>
    <indicator id='MDv12_aII_t5'>
      Nb of spatial data sets for theme Geology that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t6'>
      Nb of spatial data sets for theme Statistical units that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t7'>
      Nb of spatial data sets for theme Buildings that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t8'>
      Nb of spatial data sets for theme Soil that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t9'>
      Nb of spatial data sets for theme Land use that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t10'>
      Nb of spatial data sets for theme Human health and safety that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t11'>
      Nb of spatial data sets for theme Utility and governmental services that have metadata
    </indicator>
    <indicator id='MDv11_aI_t12'>
      Nb of spatial data sets for theme Geographical grid systems that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t13'>
      Nb of spatial data sets for theme Environmental monitoring facilities that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t14'>
      Nb of spatial data sets for theme Production and industrial facilities that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t15'>
      Nb of spatial data sets for theme Agricultural and aquaculture facilities that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t16'>
      Nb of spatial data sets for theme Population distribution — demography that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t17'>
      Nb of spatial data sets for theme Area management/restriction/regulation zones and reporting units that have
      metadata
    </indicator>
    <indicator id='MDv13_aIII_t18'>
      Nb of spatial data sets for theme Natural risk zones that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t19'>
      Nb of spatial data sets for theme Atmospheric conditions that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t20'>
      Nb of spatial data sets for theme Meteorological geographical features that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t21'>
      Nb of spatial data sets for theme Oceanographic geographical features that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t22'>
      Nb of spatial data sets for theme Sea regions that have metadata
    </indicator>
    <indicator id='MDv11_aI_t23'>
      Nb of spatial data sets for theme Geographical names that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t24'>
      Nb of spatial data sets for theme Bio-geographical regions that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t25'>
      Nb of spatial data sets for theme Habitats and biotopes that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t26'>
      Nb of spatial data sets for theme Species distribution that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t27'>
      Nb of spatial data sets for theme Energy resources that have metadata
    </indicator>
    <indicator id='MDv13_aIII_t28'>
      Nb of spatial data sets for theme Mineral resources that have metadata
    </indicator>
    <indicator id='MDv11_aI_t29'>
      Nb of spatial data sets for theme Administrative units that have metadata
    </indicator>
    <indicator id='MDv11_aI_t30'>
      Nb of spatial data sets for theme Addresses that have metadata
    </indicator>
    <indicator id='MDv11_aI_t31'>
      Nb of spatial data sets for theme Cadastral parcels that have metadata
    </indicator>
    <indicator id='MDv11_aI_t32'>
      Nb of spatial data sets for theme Transport networks that have metadata
    </indicator>
    <indicator id='MDv11_aI_t33'>
      Nb of spatial data sets for theme Hydrography that have metadata
    </indicator>
    <indicator id='MDv11_aI_t34'>
      Nb of spatial data sets for theme Protected sites that have metadata
    </indicator>
    <indicator id="MDv11Old">
      Nb of spatial data sets for Annex I that have metadata
    </indicator>
    <indicator id="MDv12Old">
      Nb of spatial data sets for Annex II that have metadata
    </indicator>
    <indicator id="MDv13Old">
      Nb of spatial data sets for Annex III that have metadata
    </indicator>
    <indicator id="MDv14">
      Nb of spatial data services that have metadata
    </indicator>
    <indicator id="MDv21Old">
      Nb of spatial data sets for Annex I that have conformant metadata
    </indicator>
    <indicator id="MDv22Old">
      Nb of spatial data sets for Annex II that have conformant metadata
    </indicator>
    <indicator id="MDv23Old">
      Nb of spatial data sets for Annex III that have conformant metadata
    </indicator>
    <indicator id='MDv21_aI_t1'>
      Nb of spatial data sets for theme Coordinate reference systems that have conformant metadata
    </indicator>
    <indicator id='MDv21_aI_t12'>
      Nb of spatial data sets for theme Geographical grid systems that have conformant metadata
    </indicator>
    <indicator id='MDv21_aI_t23'>
      Nb of spatial data sets for theme Geographical names that have conformant metadata
    </indicator>
    <indicator id='MDv21_aI_t29'>
      Nb of spatial data sets for theme Administrative units that have conformant metadata
    </indicator>
    <indicator id='MDv21_aI_t30'>
      Nb of spatial data sets for theme Addresses that have conformant metadata
    </indicator>
    <indicator id='MDv21_aI_t31'>
      Nb of spatial data sets for theme Cadastral parcels that have conformant metadata
    </indicator>
    <indicator id='MDv21_aI_t32'>
      Nb of spatial data sets for theme Transport networks that have conformant metadata
    </indicator>
    <indicator id='MDv21_aI_t33'>
      Nb of spatial data sets for theme Hydrography that have conformant metadata
    </indicator>
    <indicator id='MDv21_aI_t34'>
      Nb of spatial data sets for theme Protected sites that have conformant metadata
    </indicator>
    <indicator id='MDv22_aII_t2'>
      Nb of spatial data sets for theme Elevation that have conformant metadata
    </indicator>
    <indicator id='MDv22_aII_t3'>
      Nb of spatial data sets for theme Land cover that have conformant metadata
    </indicator>
    <indicator id='MDv22_aII_t4'>
      Nb of spatial data sets for theme Orthoimagery that have conformant metadata
    </indicator>
    <indicator id='MDv22_aII_t5'>
      Nb of spatial data sets for theme Geology that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t6'>
      Nb of spatial data sets for theme Statistical units that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t7'>
      Nb of spatial data sets for theme Buildings that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t8'>
      Nb of spatial data sets for theme Soil that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t9'>
      Nb of spatial data sets for theme Land use that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t10'>
      Nb of spatial data sets for theme Human health and safety that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t11'>
      Nb of spatial data sets for theme Utility and governmental services that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t13'>
      Nb of spatial data sets for theme Environmental monitoring facilities that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t14'>
      Nb of spatial data sets for theme Production and industrial facilities that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t15'>
      Nb of spatial data sets for theme Agricultural and aquaculture facilities that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t16'>
      Nb of spatial data sets for theme Population distribution — demography that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t17'>
      Nb of spatial data sets for theme Area management/restriction/regulation zones and reporting units that have
      conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t18'>
      Nb of spatial data sets for theme Natural risk zones that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t19'>
      Nb of spatial data sets for theme Atmospheric conditions that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t20'>
      Nb of spatial data sets for theme Meteorological geographical features that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t21'>
      Nb of spatial data sets for theme Oceanographic geographical features that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t22'>
      Nb of spatial data sets for theme Sea regions that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t24'>
      Nb of spatial data sets for theme Bio-geographical regions that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t25'>
      Nb of spatial data sets for theme Habitats and biotopes that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t26'>
      Nb of spatial data sets for theme Species distribution that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t27'>
      Nb of spatial data sets for theme Energy resources that have conformant metadata
    </indicator>
    <indicator id='MDv23_aIII_t28'>
      Nb of spatial data sets for theme Mineral resources that have conformant metadata
    </indicator>
    <indicator id="MDv24">
      Nb of spatial data services that have conformant metadata
    </indicator>
    <indicator id="DSv21Old">
      Nb of conformant spatial data sets for Annex I that have conformant metadata
    </indicator>
    <indicator id="DSv22Old">
      Nb of conformant spatial data sets for Annex II that have conformant metadata
    </indicator>
    <indicator id="DSv23Old">
      Nb of conformant spatial data sets for Annex III that have conformant metadata
    </indicator>
    <indicator id='DSv21_aI_t1'>
      Nb of conformant spatial data sets for theme Coordinate reference systems that have conformant metadata
    </indicator>
    <indicator id='DSv21_aI_t12'>
      Nb of conformant spatial data sets for theme Geographical grid systems that have conformant metadata
    </indicator>
    <indicator id='DSv21_aI_t23'>
      Nb of conformant spatial data sets for theme Geographical names that have conformant metadata
    </indicator>
    <indicator id='DSv21_aI_t29'>
      Nb of conformant spatial data sets for theme Administrative units that have conformant metadata
    </indicator>
    <indicator id='DSv21_aI_t30'>
      Nb of conformant spatial data sets for theme Addresses that have conformant metadata
    </indicator>
    <indicator id='DSv21_aI_t31'>
      Nb of conformant spatial data sets for theme Cadastral parcels that have conformant metadata
    </indicator>
    <indicator id='DSv21_aI_t32'>
      Nb of conformant spatial data sets for theme Transport networks that have conformant metadata
    </indicator>
    <indicator id='DSv21_aI_t33'>
      Nb of conformant spatial data sets for theme Hydrography that have conformant metadata
    </indicator>
    <indicator id='DSv21_aI_t34'>
      Nb of conformant spatial data sets for theme Protected sites that have conformant metadata
    </indicator>
    <indicator id='DSv22_aII_t2'>
      Nb of conformant spatial data sets for theme Elevation that have conformant metadata
    </indicator>
    <indicator id='DSv22_aII_t3'>
      Nb of conformant spatial data sets for theme Land cover that have conformant metadata
    </indicator>
    <indicator id='DSv22_aII_t4'>
      Nb of conformant spatial data sets for theme Orthoimagery that have conformant metadata
    </indicator>
    <indicator id='DSv22_aII_t5'>
      Nb of conformant spatial data sets for theme Geology that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t6'>
      Nb of conformant spatial data sets for theme Statistical units that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t7'>
      Nb of conformant spatial data sets for theme Buildings that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t8'>
      Nb of conformant spatial data sets for theme Soil that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t9'>
      Nb of conformant spatial data sets for theme Land use that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t10'>
      Nb of conformant spatial data sets for theme Human health and safety that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t11'>
      Nb of conformant spatial data sets for theme Utility and governmental services that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t13'>
      Nb of conformant spatial data sets for theme Environmental monitoring facilities that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t14'>
      Nb of conformant spatial data sets for theme Production and industrial facilities that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t15'>
      Nb of conformant spatial data sets for theme Agricultural and aquaculture facilities that have conformant
      metadata
    </indicator>
    <indicator id='DSv23_aIII_t16'>
      Nb of conformant spatial data sets for theme Population distribution — demography that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t17'>
      Nb of conformant spatial data sets for theme Area management/restriction/regulation zones and reporting units
      that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t18'>
      Nb of conformant spatial data sets for theme Natural risk zones that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t19'>
      Nb of conformant spatial data sets for theme Atmospheric conditions that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t20'>
      Nb of conformant spatial data sets for theme Meteorological geographical features that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t21'>
      Nb of conformant spatial data sets for theme Oceanographic geographical features that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t22'>
      Nb of conformant spatial data sets for theme Sea regions that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t24'>
      Nb of conformant spatial data sets for theme Bio-geographical regions that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t25'>
      Nb of conformant spatial data sets for theme Habitats and biotopes that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t26'>
      Nb of conformant spatial data sets for theme Species distribution that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t27'>
      Nb of conformant spatial data sets for theme Energy resources that have conformant metadata
    </indicator>
    <indicator id='DSv23_aIII_t28'>
      Nb of conformant spatial data sets for theme Mineral resources that have conformant metadata
    </indicator>
    <indicator id="NSv11Old">
      Nb of spatial data sets with metadata for which a discovery service exists (count a dataset once if having many
      INSPIRE themes)
    </indicator>
    <indicator id="NSv12">
      Nb of spatial data services with metadata for which a discovery service exists
    </indicator>
    <indicator id="NSv21Old">
      Nb of spatial data sets for which a view service exists
    </indicator>
    <indicator id='NSv21_aI_t1'>
      Nb of spatial data sets for theme Coordinate reference systems for which a view service exists
    </indicator>
    <indicator id='NSv21_aI_t12'>
      Nb of spatial data sets for theme Geographical grid systems for which a view service exists
    </indicator>
    <indicator id='NSv21_aI_t23'>
      Nb of spatial data sets for theme Geographical names for which a view service exists
    </indicator>
    <indicator id='NSv21_aI_t29'>
      Nb of spatial data sets for theme Administrative units for which a view service exists
    </indicator>
    <indicator id='NSv21_aI_t30'>
      Nb of spatial data sets for theme Addresses for which a view service exists
    </indicator>
    <indicator id='NSv21_aI_t31'>
      Nb of spatial data sets for theme Cadastral parcels for which a view service exists
    </indicator>
    <indicator id='NSv21_aI_t32'>
      Nb of spatial data sets for theme Transport networks for which a view service exists
    </indicator>
    <indicator id='NSv21_aI_t33'>
      Nb of spatial data sets for theme Hydrography for which a view service exists
    </indicator>
    <indicator id='NSv21_aI_t34'>
      Nb of spatial data sets for theme Protected sites for which a view service exists
    </indicator>
    <indicator id='NSv21_aII_t2'>
      Nb of spatial data sets for theme Elevation for which a view service exists
    </indicator>
    <indicator id='NSv21_aII_t3'>
      Nb of spatial data sets for theme Land cover for which a view service exists
    </indicator>
    <indicator id='NSv21_aII_t4'>
      Nb of spatial data sets for theme Orthoimagery for which a view service exists
    </indicator>
    <indicator id='NSv21_aII_t5'>
      Nb of spatial data sets for theme Geology for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t6'>
      Nb of spatial data sets for theme Statistical units for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t7'>
      Nb of spatial data sets for theme Buildings for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t8'>
      Nb of spatial data sets for theme Soil for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t9'>
      Nb of spatial data sets for theme Land use for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t10'>
      Nb of spatial data sets for theme Human health and safety for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t11'>
      Nb of spatial data sets for theme Utility and governmental services for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t13'>
      Nb of spatial data sets for theme Environmental monitoring facilities for which a view service exists
    </indicator>
    za
    <indicator id='NSv21_aIII_t14'>
      Nb of spatial data sets for theme Production and industrial facilities for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t15'>
      Nb of spatial data sets for theme Agricultural and aquaculture facilities for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t16'>
      Nb of spatial data sets for theme Population distribution — demography for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t17'>
      Nb of spatial data sets for theme Area management/restriction/regulation zones and reporting units for which a
      view service exists
    </indicator>
    <indicator id='NSv21_aIII_t18'>
      Nb of spatial data sets for theme Natural risk zones for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t19'>
      Nb of spatial data sets for theme Atmospheric conditions for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t20'>
      Nb of spatial data sets for theme Meteorological geographical features for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t21'>
      Nb of spatial data sets for theme Oceanographic geographical features for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t22'>
      Nb of spatial data sets for theme Sea regions for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t24'>
      Nb of spatial data sets for theme Bio-geographical regions for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t25'>
      Nb of spatial data sets for theme Habitats and biotopes for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t26'>
      Nb of spatial data sets for theme Species distribution for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t27'>
      Nb of spatial data sets for theme Energy resources for which a view service exists
    </indicator>
    <indicator id='NSv21_aIII_t28'>
      Nb of spatial data sets for theme Mineral resources for which a view service exists
    </indicator>
    <indicator id="NSv22Old">
      Nb of spatial data sets for which a download service exists
    </indicator>
    <indicator id='NSv22_aI_t1'>
      Nb of spatial data sets for theme Coordinate reference systems for which a download service exists
    </indicator>
    <indicator id='NSv22_aI_t12'>
      Nb of spatial data sets for theme Geographical grid systems for which a download service exists
    </indicator>
    <indicator id='NSv22_aI_t23'>
      Nb of spatial data sets for theme Geographical names for which a download service exists
    </indicator>
    <indicator id='NSv22_aI_t29'>
      Nb of spatial data sets for theme Administrative units for which a download service exists
    </indicator>
    <indicator id='NSv22_aI_t30'>
      Nb of spatial data sets for theme Addresses for which a download service exists
    </indicator>
    <indicator id='NSv22_aI_t31'>
      Nb of spatial data sets for theme Cadastral parcels for which a download service exists
    </indicator>
    <indicator id='NSv22_aI_t32'>
      Nb of spatial data sets for theme Transport networks for which a download service exists
    </indicator>
    <indicator id='NSv22_aI_t33'>
      Nb of spatial data sets for theme Hydrography for which a download service exists
    </indicator>
    <indicator id='NSv22_aI_t34'>
      Nb of spatial data sets for theme Protected sites for which a download service exists
    </indicator>
    <indicator id='NSv22_aII_t2'>
      Nb of spatial data sets for theme Elevation for which a download service exists
    </indicator>
    <indicator id='NSv22_aII_t3'>
      Nb of spatial data sets for theme Land cover for which a download service exists
    </indicator>
    <indicator id='NSv22_aII_t4'>
      Nb of spatial data sets for theme Orthoimagery for which a download service exists
    </indicator>
    <indicator id='NSv22_aII_t5'>
      Nb of spatial data sets for theme Geology for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t6'>
      Nb of spatial data sets for theme Statistical units for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t7'>
      Nb of spatial data sets for theme Buildings for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t8'>
      Nb of spatial data sets for theme Soil for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t9'>
      Nb of spatial data sets for theme Land use for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t10'>
      Nb of spatial data sets for theme Human health and safety for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t11'>
      Nb of spatial data sets for theme Utility and governmental services for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t13'>
      Nb of spatial data sets for theme Environmental monitoring facilities for which a download service exists
    </indicator>
    za
    <indicator id='NSv22_aIII_t14'>
      Nb of spatial data sets for theme Production and industrial facilities for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t15'>
      Nb of spatial data sets for theme Agricultural and aquaculture facilities for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t16'>
      Nb of spatial data sets for theme Population distribution — demography for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t17'>
      Nb of spatial data sets for theme Area management/restriction/regulation zones and reporting units for which a
      download service exists
    </indicator>
    <indicator id='NSv22_aIII_t18'>
      Nb of spatial data sets for theme Natural risk zones for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t19'>
      Nb of spatial data sets for theme Atmospheric conditions for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t20'>
      Nb of spatial data sets for theme Meteorological geographical features for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t21'>
      Nb of spatial data sets for theme Oceanographic geographical features for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t22'>
      Nb of spatial data sets for theme Sea regions for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t24'>
      Nb of spatial data sets for theme Bio-geographical regions for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t25'>
      Nb of spatial data sets for theme Habitats and biotopes for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t26'>
      Nb of spatial data sets for theme Species distribution for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t27'>
      Nb of spatial data sets for theme Energy resources for which a download service exists
    </indicator>
    <indicator id='NSv22_aIII_t28'>
      Nb of spatial data sets for theme Mineral resources for which a download service exists
    </indicator>
    <indicator id="NSv23Old">
      Nb of spatial data sets for which a view and download service exists
    </indicator>
    <indicator id='NSv23_aI_t1'>
      Nb of spatial data sets for theme Coordinate reference systems for which a download service exists
    </indicator>
    <indicator id='NSv23_aI_t12'>
      Nb of spatial data sets for theme Geographical grid systems for which a download service exists
    </indicator>
    <indicator id='NSv23_aI_t23'>
      Nb of spatial data sets for theme Geographical names for which a download service exists
    </indicator>
    <indicator id='NSv23_aI_t29'>
      Nb of spatial data sets for theme Administrative units for which a download service exists
    </indicator>
    <indicator id='NSv23_aI_t30'>
      Nb of spatial data sets for theme Addresses for which a download service exists
    </indicator>
    <indicator id='NSv23_aI_t31'>
      Nb of spatial data sets for theme Cadastral parcels for which a download service exists
    </indicator>
    <indicator id='NSv23_aI_t32'>
      Nb of spatial data sets for theme Transport networks for which a download service exists
    </indicator>
    <indicator id='NSv23_aI_t33'>
      Nb of spatial data sets for theme Hydrography for which a download service exists
    </indicator>
    <indicator id='NSv23_aI_t34'>
      Nb of spatial data sets for theme Protected sites for which a download service exists
    </indicator>
    <indicator id='NSv23_aII_t2'>
      Nb of spatial data sets for theme Elevation for which a download service exists
    </indicator>
    <indicator id='NSv23_aII_t3'>
      Nb of spatial data sets for theme Land cover for which a download service exists
    </indicator>
    <indicator id='NSv23_aII_t4'>
      Nb of spatial data sets for theme Orthoimagery for which a download service exists
    </indicator>
    <indicator id='NSv23_aII_t5'>
      Nb of spatial data sets for theme Geology for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t6'>
      Nb of spatial data sets for theme Statistical units for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t7'>
      Nb of spatial data sets for theme Buildings for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t8'>
      Nb of spatial data sets for theme Soil for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t9'>
      Nb of spatial data sets for theme Land use for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t10'>
      Nb of spatial data sets for theme Human health and safety for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t11'>
      Nb of spatial data sets for theme Utility and governmental services for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t13'>
      Nb of spatial data sets for theme Environmental monitoring facilities for which a download service exists
    </indicator>
    za
    <indicator id='NSv23_aIII_t14'>
      Nb of spatial data sets for theme Production and industrial facilities for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t15'>
      Nb of spatial data sets for theme Agricultural and aquaculture facilities for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t16'>
      Nb of spatial data sets for theme Population distribution — demography for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t17'>
      Nb of spatial data sets for theme Area management/restriction/regulation zones and reporting units for which a
      download service exists
    </indicator>
    <indicator id='NSv23_aIII_t18'>
      Nb of spatial data sets for theme Natural risk zones for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t19'>
      Nb of spatial data sets for theme Atmospheric conditions for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t20'>
      Nb of spatial data sets for theme Meteorological geographical features for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t21'>
      Nb of spatial data sets for theme Oceanographic geographical features for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t22'>
      Nb of spatial data sets for theme Sea regions for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t24'>
      Nb of spatial data sets for theme Bio-geographical regions for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t25'>
      Nb of spatial data sets for theme Habitats and biotopes for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t26'>
      Nb of spatial data sets for theme Species distribution for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t27'>
      Nb of spatial data sets for theme Energy resources for which a download service exists
    </indicator>
    <indicator id='NSv23_aIII_t28'>
      Nb of spatial data sets for theme Mineral resources for which a download service exists
    </indicator>
    <indicator id="NSv41">
      Nb of conformant discovery network services
    </indicator>
    <indicator id="NSv42">
      Nb of conformant view network services
    </indicator>
    <indicator id="NSv43">
      Nb of conformant download network services
    </indicator>
    <indicator id="NSv44">
      Nb of conformant transformation network services
    </indicator>
    <indicator id="NSv45">
      Nb of conformant discovery invoke services
    </indicator>
    <indicator id="NSv31" default="0">
      Sum of the annual Nb of network service request for all the discovery services
    </indicator>
    <indicator id="NSv32" default="0">
      Sum of the annual Nb of network service request for all the view services
    </indicator>
    <indicator id="NSv33" default="0">
      Sum of the annual Nb of network service request for all the download services
    </indicator>
    <indicator id="NSv34" default="0">
      Sum of the annual Nb of network service request for all the transformation services
    </indicator>
    <indicator id="NSv35" default="0">
      Sum of the annual Nb of network service request for all the invoke services
    </indicator>
    <!-- Use stats component
    http://wiki.apache.org/solr/StatsComponent
    -->
    <indicator id="DSv11_ActArea" default="0">
      Sum of the actual areas of all the spatial data sets of Annex I
    </indicator>
    <indicator id="DSv12_ActArea" default="0">
      Sum of the actual areas of all the spatial data sets of Annex II
    </indicator>
    <indicator id="DSv13_ActArea" default="0">
      Sum of the actual areas of all the spatial data sets of Annex III
    </indicator>
    <indicator id="DSv11_RelArea" default="0.0001">
      Sum of the relevant areas of all the spatial data sets of Annex I
    </indicator>
    <indicator id="DSv12_RelArea" default="0.0001">
      Sum of the relevant areas of all the spatial data sets of Annex II
    </indicator>
    <indicator id="DSv13_RelArea" default="0.0001">
      Sum of the relevant areas of all the spatial data sets of Annex III
    </indicator>
    <indicator id="MDv11">
      Nb of spatial data sets for Annex I that have metadata
    </indicator>
    <indicator id="MDv12">
      Nb of spatial data sets for Annex II that have metadata
    </indicator>
    <indicator id="MDv13">
      Nb of spatial data sets for Annex III that have metadata
    </indicator>
    <indicator id="DSv21">
      Nb of conformant spatial data sets for Annex I that have conformant metadata
    </indicator>
    <indicator id="DSv22">
      Nb of conformant spatial data sets for Annex II that have conformant metadata
    </indicator>
    <indicator id="DSv23">
      Nb of conformant spatial data sets for Annex II that have conformant metadata
    </indicator>
    <indicator id="MDv21">
      Nb of spatial data sets for Annex I that have conformant metadata
    </indicator>
    <indicator id="MDv22">
      Nb of spatial data sets for Annex II that have conformant metadata
    </indicator>
    <indicator id="MDv23">
      Nb of spatial data sets for Annex III that have conformant metadata
    </indicator>
    <indicator id="NSv21">
      Nb of spatial data sets for which a view service exists
    </indicator>
    <indicator id="NSv22">
      Nb of spatial data sets for which a download service exists
    </indicator>
    <indicator id="NSv23">
      Nb of spatial data sets for which a view and download service exists
    </indicator>
    <indicator id="NSv11">
      Nb of spatial data sets with metadata for which a discovery service exists (count a dataset as many time as its INSPIRE themes)
    </indicator>
    <indicator id="DSv_Num1">
      Nb of spatial data sets for Annex I
    </indicator>
    <indicator id="DSv_Num2">
      Nb of spatial data sets for Annex II
    </indicator>
    <indicator id="DSv_Num3">
      Nb of spatial data sets for Annex III
    </indicator>
    <indicator id="DSv_Num">
      Nb of spatial data sets for all Annexes
    </indicator>
    <indicator id="NSv_NumAllServ">
      Nb of all services
    </indicator>
    <indicator id="MDi11">
      %age of spatial data sets for Annex I having metadata
    </indicator>
    <indicator id="MDi12">
      %age of spatial data sets for Annex II having metadata
    </indicator>
    <indicator id="MDi13">
      %age of spatial data sets for Annex II having metadata
    </indicator>
    <indicator id="MDi14">
      %age of spatial services having metadata
    </indicator>
    <indicator id="MDi1">
      %age of spatial data sets or services having metadata
    </indicator>
    <indicator id="MDv1_DS">
      Nb of spatial data sets that have metadata
    </indicator>
    <indicator id="MDv2_DS">
      Nb of spatial data sets for all Annexes that have conformant metadata
    </indicator>
    <indicator id="MDi21">
      %age of spatial data sets for Annex I with conformant metadata
    </indicator>
    <indicator id="MDi22">
      %age of spatial data sets for Annex II with conformant metadata
    </indicator>
    <indicator id="MDi23">
      %age of spatial data sets for Annex III with conformant metadata
    </indicator>
    <indicator id="MDi24">
      %age of spatial data services with conformant metadata
    </indicator>
    <indicator id="MDi2">
      %age of spatial data sets and services with conformant metadata
    </indicator>
    <indicator id="DSv2">
      Nb of conformant spatial data sets with conformant metadata for all Annexes
    </indicator>
    <indicator id="DSi21">
      %age of conformant spatial data sets with conformant metadata for Annex I
    </indicator>
    <indicator id="DSi22">
      %age of conformant spatial data sets with conformant metadata for Annex II
    </indicator>
    <indicator id="DSi23">
      %age of conformant spatial data sets with conformant metadata for Annex III
    </indicator>
    <indicator id="DSi2">
      %age of conformant spatial data sets with conformant metadata for all Annexes
    </indicator>
    <indicator id="NSi11">
      %age of spatial data sets with metadata, for which a discovery service exists
    </indicator>
    <indicator id="NSi12">
      %age of spatial data services with metadata, for which a discovery service exists
    </indicator>
    <indicator id="NSi1">
      %age of spatial data sets and services with metadata, for which a discovery service exists
    </indicator>
    <indicator id="NSi21">
      %age of spatial data sets for which a view service exists
    </indicator>
    <indicator id="NSi22">
      %age of spatial data sets for which a download service exists
    </indicator>
    <indicator id="NSi2">
      %age of spatial data sets for which a view and download service exists
    </indicator>
    <indicator id="DSv1_ActArea">
      Sum of the actual areas of all the spatial data sets of all Annexes
    </indicator>
    <indicator id="DSv1_RelArea">
      Sum of the relevant areas of all the spatial data sets of all Annexes
    </indicator>
    <indicator id="DSi11">
      %age of actual/relative area for spatial data sets for Annex I
    </indicator>
    <indicator id="DSi12">
      %age of actual/relative area for spatial data sets for Annex II
    </indicator>
    <indicator id="DSi13">
      %age of actual/relative area for spatial data sets for Annex III
    </indicator>
    <indicator id="DSi1">
      %age of actual/relative area for all spatial data sets
    </indicator>
    <indicator id="NSv3">
      Sum of the annual Nb of network service request for all services
    </indicator>
    <indicator id="NSv4">
      Nb of all conformant network services
    </indicator>
    <indicator id="NSi31">
      Average Nb of requests per discovery services
    </indicator>
    <indicator id="NSi32">
      Average Nb of requests per view services
    </indicator>
    <indicator id="NSi33">
      Average Nb of requests per download services
    </indicator>
    <indicator id="NSi34">
      Average Nb of requests per transformation services
    </indicator>
    <indicator id="NSi35">
      Average Nb of requests per invoke services
    </indicator>
    <indicator id="NSi3">
      Average Nb of requests per services
    </indicator>
    <indicator id="NSi41">
      %age of conformant discovery services
    </indicator>
    <indicator id="NSi42">
      %age of conformant view services
    </indicator>
    <indicator id="NSi43">
      %age of conformant download services
    </indicator>
    <indicator id="NSi44">
      %age of conformant transformation services
    </indicator>
    <indicator id="NSi45">
      %age of conformant invoke services
    </indicator>
    <indicator id="NSi4">
      %age of conformant services
    </indicator>
  </xsl:variable>

  <xsl:variable name="isDaobsFormat"
                select="count(daobs:reporting) > 0"
                as="xs:boolean"/>

  <!-- Compute ISO date from a INSPIRE date node
    eg. <monitoringDate>
          <day>08</day>
          <month>04</month>
          <year>2016</year>
        </monitoringDate>
    return 2016-04-08T12:00:00
  -->
  <xsl:function name="daobs:get-date" as="xs:string">
    <xsl:param name="dateNode" as="node()"/>
    <xsl:variable name="year"
                  select="$dateNode/year"/>
    <!-- Format date properly. Sometimes month is written
using one character or two. Prepend 0 when needed. -->
    <xsl:variable name="month"
                  select="if ($yearlyIndicators = 'true') then '12'
                        else if ($dateNode/month = '00' or $dateNode/month = '0') then '12'
                        else if (string-length($dateNode/month) = 1)
                        then concat('0', $dateNode/month)
                        else if (string-length($dateNode/month) = 2)
                        then $dateNode/month
                        else '12'"/>
    <xsl:variable name="day"
                  select="if ($yearlyIndicators = 'true') then '31'
                        else if ($dateNode/day = '00' or $dateNode/day = '0') then '31'
                        else if (string-length($dateNode/day) = 1)
                        then concat('0', $dateNode/day)
                        else if (string-length($dateNode/day) = 2)
                        then $dateNode/day
                        else '31'"/>
    <xsl:value-of select="concat(
                            $year, '-', $month, '-', $day,
                            'T12:00:00')"/>
  </xsl:function>


  <xsl:variable name="reportingDate"
                select="if ($isDaobsFormat)
                        then xs:dateTime(
                          if (contains(/daobs:reporting/@dateTime, '.'))
                          then substring-before(/daobs:reporting/@dateTime, '.')
                          else /daobs:reporting/@dateTime)
                        else daobs:get-date(/monitoring:Monitoring/documentYear)"/>
  <xsl:variable name="reportingDateSubmission"
                select="if ($isDaobsFormat)
                        then xs:dateTime(
                          if (contains(/daobs:reporting/@dateTime, '.'))
                          then substring-before(/daobs:reporting/@dateTime, '.')
                          else /daobs:reporting/@dateTime)
                        else daobs:get-date(/monitoring:Monitoring/MonitoringMD/monitoringDate)"/>

  <xsl:variable name="reportingYear"
                select="if ($isDaobsFormat)
                        then format-dateTime($reportingDate, '[Y0001]')
                        else /monitoring:Monitoring/documentYear/year"/>

  <xsl:variable name="reportingScope"
                select="if ($isDaobsFormat)
                        then /daobs:reporting/@scopeId
                        else /monitoring:Monitoring/memberState"/>

  <xsl:variable name="reportIdentifier"
                select="if ($isDaobsFormat)
                        then /daobs:reporting/@id
                        else 'inspire'"/>


  <xsl:template match="/">
    <add>
      <!--<xsl:message>
        <xsl:text>Indexing indicators for </xsl:text>
        <xsl:value-of select="$reportingScope"/>
        <xsl:value-of select="concat(' Report: ', $reportIdentifier, ' (', $reportingDate, ') - DAOBS format: ', $isDaobsFormat)"/>
      </xsl:message>-->

      <xsl:apply-templates select="
                //daobs:reporting|
                //daobs:reporting/daobs:variables/daobs:variable|
                //daobs:reporting/daobs:indicators/daobs:indicator|
                //MonitoringMD|//Indicators/*|
                //RowData/SpatialDataService/NetworkService/userRequest|
                //RowData/SpatialDataSet/Coverage/(relevantArea|actualArea)|
                //RowData/SpatialDataService|
                //RowData/SpatialDataSet"/>
    </add>
  </xsl:template>

  <xsl:template match="MonitoringMD|daobs:reporting">
    <doc>
      <id>
        <xsl:value-of
          select="concat('monitoring', $reportIdentifier, $reportingScope, $reportingDate)"/>
      </id>
      <documentType>monitoring</documentType>
      <scope>
        <xsl:value-of select="$reportingScope"/>
      </scope>
      <reportingDateSubmission>
        <xsl:value-of select="$reportingDateSubmission"/>
      </reportingDateSubmission>
      <reportingDate>
        <xsl:value-of select="$reportingDate"/>
      </reportingDate>
      <reportingYear>
        <xsl:value-of select="$reportingYear"/>
      </reportingYear>
      <contact>{
        "org": "<xsl:value-of select="replace(organizationName,
                                        $doubleQuote, $escapedDoubleQuote)"/>",
        "email": "<xsl:value-of select="email"/>"
        }
      </contact>

      <xsl:apply-templates mode="indicatorValue"
                           select="
                daobs:variables/daobs:variable|
                daobs:indicators/daobs:indicator|
                ../Indicators//*[count(*) = 0 and text() != '']"/>
      <isOfficial>true</isOfficial>
    </doc>
  </xsl:template>

  <xsl:template match="Indicators/*">
    <xsl:variable name="indicatorType" select="local-name()"/>
    <xsl:for-each select="descendant::*[count(*) = 0 and text() != '']">
      <xsl:variable name="indicatorIdentifier" select="local-name()"/>
      <doc>
        <id>
          <xsl:value-of
            select="concat('indicator', $reportIdentifier, $indicatorIdentifier,
                $reportingDate, $reportingScope)"/>
        </id>
        <documentType>indicator</documentType>
        <indicatorType>
          <xsl:value-of select="$indicatorType"/>
        </indicatorType>
        <indicatorName>
          <xsl:value-of select="$indicatorIdentifier"/>
        </indicatorName>
        <xsl:variable name="label"
                      select="$indicatorLabels/*[@id = $indicatorIdentifier]/normalize-space(.)"/>
        <xsl:if test="$label != ''">
          <indicatorLabel>
            <xsl:value-of select="$label"/>
          </indicatorLabel>
        </xsl:if>
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
        </reportingDate>
        <reportingYear>
          <xsl:value-of select="$reportingYear"/>
        </reportingYear>
      </doc>
    </xsl:for-each>
  </xsl:template>


  <xsl:template match="daobs:variable|daobs:indicator|
                       *[count(*) = 0 and text() != '']"
                mode="indicatorValue">
    <xsl:variable name="indicatorType"
                  select="local-name()"/>
    <xsl:variable name="indicatorIdentifier"
                  select="if (@id) then @id else local-name()"/>

    <xsl:element name="iv{$indicatorIdentifier}">
      <xsl:value-of select="if (daobs:value) then daobs:value else text()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*"
                mode="indicatorValue"/>

  <xsl:template match="daobs:variable|daobs:indicator">
    <xsl:variable name="indicatorType" select="local-name()"/>
    <xsl:variable name="indicatorIdentifier" select="@id"/>

    <!--<xsl:message>  Indicator <xsl:value-of select="concat($indicatorIdentifier, ': ', daobs:value)"/></xsl:message>-->
    <doc>
      <id>
        <xsl:value-of
          select="concat('indicator', $reportIdentifier, $indicatorIdentifier,
              $reportingDate, $reportingScope)"/>
      </id>
      <documentType>indicator</documentType>
      <indicatorType>
        <xsl:value-of select="$indicatorType"/>
      </indicatorType>
      <indicatorName>
        <xsl:value-of select="$indicatorIdentifier"/>
      </indicatorName>
      <indicatorLabel>
        <xsl:value-of select="daobs:name"/>
      </indicatorLabel>
      <xsl:if test="daobs:value != ''">
        <indicatorValue>
          <xsl:value-of select="daobs:value"/>
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
      </reportingDate>
      <reportingYear>
        <xsl:value-of select="$reportingYear"/>
      </reportingYear>
    </doc>
  </xsl:template>

  <!-- Index row data like metadata records -->
  <xsl:template match="SpatialDataService">
    <doc>
      <xsl:variable name="uuid"
                    select="if (uuid != '') then uuid else 'nouuid'"/>
      <id>
        <xsl:value-of
          select="concat('monitoring',
                        $reportingScope, $reportingDate,
                        $uuid, '-', position())"/>
      </id>
      <metadataIdentifier>
        <xsl:value-of select="$uuid"/>
      </metadataIdentifier>
      <documentType>monitoringMetadata</documentType>
      <resourceType>service</resourceType>
      <scope>
        <xsl:value-of select="$reportingScope"/>
      </scope>
      <reportingDateSubmission>
        <xsl:value-of select="$reportingDateSubmission"/>
      </reportingDateSubmission>
      <reportingDate>
        <xsl:value-of select="$reportingDate"/>
      </reportingDate>
      <reportingYear>
        <xsl:value-of select="$reportingYear"/>
      </reportingYear>
      <resourceTitle>
        <xsl:value-of select="name"/>
      </resourceTitle>
      <custodianOrgForResource>
        <xsl:value-of select="respAuthority"/>
      </custodianOrgForResource>
      <xsl:for-each-group select="Themes/*" group-by="name()">
        <inspireAnnex>
          <xsl:value-of
            select="if (name() = 'AnnexIII') then 'iii' else if (name() = 'AnnexII') then 'ii' else 'i'"/>
        </inspireAnnex>
      </xsl:for-each-group>
      <xsl:for-each select="Themes/*">
        <xsl:variable name="themeKey" select="."/>
        <inspireTheme>
          <xsl:value-of
            select="$inspireThemesMap/map[@monitoring = $themeKey]/@theme"/>
        </inspireTheme>
      </xsl:for-each>


      <isAboveThreshold>
        <xsl:value-of select="MdServiceExistence/mdConformity = 'true'"/>
      </isAboveThreshold>
      <harvesterUuid>
        <xsl:value-of select="MdServiceExistence/discoveryAccessibilityUuid"/>
      </harvesterUuid>
      <linkUrl>
        <xsl:value-of select="NetworkService/URL"/>
      </linkUrl>
      <serviceType>
        <xsl:value-of select="NetworkService/NnServiceType"/>
      </serviceType>
      <inspireConformResource>
        <xsl:value-of select="NetworkService/nnConformity = 'true'"/>
      </inspireConformResource>
    </doc>
  </xsl:template>


  <xsl:template match="SpatialDataSet">
    <doc>
      <xsl:variable name="uuid"
                    select="if (uuid != '') then uuid else 'nouuid'"/>
      <!-- Append position to all uuids to make them unique -->
      <id>
        <xsl:value-of
          select="concat('monitoring',
                        $reportingScope, $reportingDate,
                        $uuid, '-', position())"/>
      </id>
      <metadataIdentifier>
        <xsl:value-of select="$uuid"/>
      </metadataIdentifier>
      <documentType>monitoringMetadata</documentType>
      <resourceType>dataset</resourceType>
      <scope>
        <xsl:value-of select="$reportingScope"/>
      </scope>
      <reportingDateSubmission>
        <xsl:value-of select="$reportingDateSubmission"/>
      </reportingDateSubmission>
      <reportingDate>
        <xsl:value-of select="$reportingDate"/>
      </reportingDate>
      <reportingYear>
        <xsl:value-of select="$reportingYear"/>
      </reportingYear>
      <resourceTitle>
        <xsl:value-of select="name"/>
      </resourceTitle>
      <custodianOrgForResource>
        <xsl:value-of select="respAuthority"/>
      </custodianOrgForResource>
      <xsl:for-each-group select="Themes/*" group-by="name()">
        <inspireAnnex>
          <xsl:value-of
            select="if (name() = 'AnnexIII') then 'iii' else if (name() = 'AnnexII') then 'ii' else 'i'"/>
        </inspireAnnex>
      </xsl:for-each-group>
      <xsl:for-each select="Themes/*">
        <xsl:variable name="themeKey" select="."/>
        <inspireTheme>
          <xsl:value-of
            select="$inspireThemesMap/map[@monitoring = $themeKey]/@theme"/>
        </inspireTheme>
      </xsl:for-each>


      <xsl:for-each
        select="MdDataSetExistence/MdAccessibility/(discovery|view|download|viewDownload)[. = 'true']">
        <recordOperatedByType>
          <xsl:value-of select="name()"/>
        </recordOperatedByType>
      </xsl:for-each>

      <isAboveThreshold>
        <xsl:value-of select="count(MdDataSetExistence/IRConformity) > 0"/>
      </isAboveThreshold>
      <harvesterUuid>
        <xsl:value-of
          select="MdDataSetExistence/MdAccessibility/discoveryUuid"/>
      </harvesterUuid>
      <inspireConformResource>
        <xsl:value-of
          select="MdDataSetExistence/IRConformity/structureCompliance = 'true'"/>
      </inspireConformResource>
    </doc>
  </xsl:template>

</xsl:stylesheet>
