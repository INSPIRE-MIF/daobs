/**
 * Copyright 2014-2016 European Environment Agency
 * <p>
 * Licensed under the EUPL, Version 1.1 or – as soon
 * they will be approved by the European Commission -
 * subsequent versions of the EUPL (the "Licence");
 * You may not use this work except in compliance
 * with the Licence.
 * You may obtain a copy of the Licence at:
 * <p>
 * https://joinup.ec.europa.eu/community/eupl/og_page/eupl
 * <p>
 * Unless required by applicable law or agreed to in
 * writing, software distributed under the Licence is
 * distributed on an "AS IS" basis,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.
 * See the Licence for the specific language governing
 * permissions and limitations under the Licence.
 */

package org.daobs.controller;

import static org.elasticsearch.common.xcontent.XContentFactory.jsonBuilder;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import io.swagger.annotations.ApiResponse;
import io.swagger.annotations.ApiResponses;
import org.apache.commons.io.FileUtils;
import org.daobs.index.EsClientBean;
import org.daobs.index.EsRequestBean;
import org.daobs.indicator.config.Indicator;
import org.daobs.indicator.config.Reporting;
import org.daobs.indicator.config.Reports;
import org.daobs.indicator.config.Variable;
import org.daobs.util.UnzipUtility;
import org.elasticsearch.ResourceNotFoundException;
import org.elasticsearch.action.bulk.BulkRequestBuilder;
import org.elasticsearch.action.bulk.BulkResponse;
import org.elasticsearch.action.support.WriteRequest;
import org.elasticsearch.common.xcontent.XContentBuilder;
import org.jdom2.Element;
import org.jdom2.transform.JDOMResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationContext;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.stereotype.Controller;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.view.xslt.XsltViewResolver;
import org.w3c.dom.Node;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;

import java.net.URL;
import java.nio.file.Paths;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamSource;



@Api(value = "reports",
    tags = "reports",
    description = "Report operations")
@EnableWebMvc
@Controller
public class ReportingController {
  private Logger logger = Logger.getLogger("org.daobs.reporting");

  @Autowired
  private ApplicationContext appContext;

  private static final int commitInterval = 1000;

  private String indicatorConfigurationDir;

  public String getIndicatorConfigurationDir() {
    return indicatorConfigurationDir;
  }

  @Value("${reporting.dir}")
  public void setIndicatorConfigurationDir(String indicatorConfigurationDir) {
    this.indicatorConfigurationDir = indicatorConfigurationDir;
  }

  public static final String INDICATOR_CONFIGURATION_FILE_PREFIX = "config-";
  private static final String INDICATOR_CONFIGURATION_ID_MATCHER =
      INDICATOR_CONFIGURATION_FILE_PREFIX + "(.*).xml";
  private static final Pattern INDICATOR_CONFIGURATION_ID_PATTERN =
      Pattern.compile(INDICATOR_CONFIGURATION_ID_MATCHER);


  @Value("${reports.dir}")
  private String reportsPath;

  @Value("${es.url}")
  private String esUrl;

  @Value("${es.index.records}")
  private String index;

  /**
   * Get list of available reports.
   */
  @ApiOperation(value = "Get list of available reports",
      nickname = "getReports")
  @RequestMapping(value = "/reports",
      produces = {
          MediaType.APPLICATION_XML_VALUE,
          MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.GET)
  @ApiResponses(value = {
      @ApiResponse(code = 200, message = "Return the list of available reports.")
      })
  @ResponseBody
  public Reports getReports(HttpServletRequest request)
      throws IOException {
    File file = new File(indicatorConfigurationDir);
    FilenameFilter filenameFilter = (file1, name) -> {
      if (name.startsWith(INDICATOR_CONFIGURATION_FILE_PREFIX)
          && name.endsWith(".xml")) {
        return true;
      }
      return false;
    };
    File[] paths = file.listFiles(filenameFilter);

    Reports reports = new Reports();
    if (paths != null && paths.length > 0) {
      for (File configFile : paths) {
        Reporting reporting = new Reporting();
        Matcher matcher = INDICATOR_CONFIGURATION_ID_PATTERN.matcher(configFile.getName());
        if (matcher.find()) {
          reporting.setId(matcher.group(1));
        }
        reports.addReporting(reporting);
      }
    }
    return reports;
  }


  /**
   * Get report specification in XML or JSON format.
   */
  @ApiOperation(value = "Get report specification",
      nickname = "getReports")
  @RequestMapping(value = "/reports/{reporting}",
      produces = {
          MediaType.APPLICATION_XML_VALUE,
          MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.GET)
  @ApiResponses(value = {
      @ApiResponse(code = 200, message = "Return a report configuration."),
      @ApiResponse(code = 404, message = "Report not found.")
      })
  @ResponseBody
  public Reporting getSpecification(HttpServletRequest request,
                       @ApiParam(
                         value = "The report type to generate",
                         required = true)
                       @PathVariable(value = "reporting") String reporting,
                       @ApiParam(
                         value = "An optional scope")
                       @RequestParam(
                         value = "scopeId",
                         defaultValue = "",
                         required = false) String scopeId,
                       @ApiParam(
                         value = "An optional filter query to generate report on a subset",
                         required = false)
                       @RequestParam(
                         value = "fq",
                         defaultValue = "",
                         required = false) String fq) throws FileNotFoundException {
    IndicatorCalculatorImpl indicatorCalculator = null;
    indicatorCalculator = generateReporting(request, reporting, scopeId, fq.trim(), true, null);
    return indicatorCalculator.getConfiguration();
  }


  /**
   * Upload a report specification in XML or JSON format.
   */
  @ApiOperation(value = "Upload report specification",
      nickname = "uploadSpecification")
  @RequestMapping(value = "/reports/{reporting}",
      consumes = {
          MediaType.APPLICATION_XML_VALUE,
          MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.POST)
  @ApiResponses(value = {
      @ApiResponse(code = 201, message = "Report configuration added."),
      @ApiResponse(code = 500, message = "Failed to upload report.")
      })
  @ResponseBody
  public ResponseEntity uploadSpecification(HttpServletRequest request,
                       @ApiParam(
                         value = "The report type to generate",
                         required = true)
                       @PathVariable(value = "reporting")
                       String reporting,
                       @ApiParam(value = "The specification to upload")
                       @RequestParam("file")
                       MultipartFile file)
      throws IOException {

    File tmpFile = File.createTempFile("report", ".xml");
    try {
      File reportingConfigFile = new File(indicatorConfigurationDir + reporting + ".xml");

      FileUtils.writeByteArrayToFile(tmpFile, file.getBytes());
      IndicatorCalculatorImpl indicatorCalculator =
          new IndicatorCalculatorImpl(tmpFile);

      FileUtils.copyFile(indicatorCalculator.toFile(), reportingConfigFile);

      return new ResponseEntity<>(HttpStatus.CREATED);
    } catch (Exception ex) {
      throw new IllegalArgumentException(String.format(
        "Failed to upload, load and save report configuration."), ex);
    } finally {
      FileUtils.deleteQuietly(tmpFile);
    }
  }


  /**
   * Add a report specification in XML or JSON format.
   */
  @ApiOperation(value = "Add report specification",
      nickname = "addSpecification")
  @RequestMapping(value = "/reports/{reporting}",
      consumes = {
          MediaType.APPLICATION_XML_VALUE
      },
      method = RequestMethod.PUT)
  @ApiResponses(value = {
      @ApiResponse(code = 201, message = "Report configuration added."),
      @ApiResponse(code = 500, message = "Failed to upload report.")
      })
  @ResponseBody
  public ResponseEntity addSpecification(
      HttpServletRequest request,
      @ApiParam(
        value = "The report type to generate",
        required = true)
      @PathVariable(value = "reporting")
        String reporting,
      @ApiParam(value = "The specification to add as an XML string")
      @RequestParam("specification")
        String specification)
    throws IOException {

    File tmpFile = File.createTempFile("report", ".xml");
    try {
      File reportingConfigFile = new File(indicatorConfigurationDir
          + INDICATOR_CONFIGURATION_FILE_PREFIX + reporting + ".xml");

      FileUtils.writeStringToFile(tmpFile, specification);
      IndicatorCalculatorImpl indicatorCalculator =
          new IndicatorCalculatorImpl(tmpFile);

      FileUtils.copyFile(indicatorCalculator.toFile(), reportingConfigFile);

      return new ResponseEntity<>(HttpStatus.CREATED);
    } catch (Exception ex) {
      throw new IllegalArgumentException(String.format(
        "Failed to upload, load and save report configuration."), ex);
    } finally {
      FileUtils.deleteQuietly(tmpFile);
    }
  }


  /**
   * Add a report specification in XML or JSON format.
   */
  @ApiOperation(value = "Add or update an indicator in a report specification",
      nickname = "addIndicator")
  @RequestMapping(value = "/reports/{reporting}/indicators",
      consumes = {
        MediaType.APPLICATION_XML_VALUE,
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.PUT)
  @ApiResponses(value = {
      @ApiResponse(code = 201, message = "Indicator added or updated."),
      @ApiResponse(code = 500, message = "Failed to add indicator.")
      })
  @ResponseBody
  public ResponseEntity addIndicator(HttpServletRequest request,
                                     @ApiParam(
                                       value = "The report type to generate",
                                       required = true)
                                     @PathVariable(value = "reporting")
                                       String reporting,
                                     @ApiParam(value = "The indicator to add or update")
                                         @RequestBody()
                                     Indicator indicator)
      throws IOException {
    IndicatorCalculatorImpl indicatorCalculator = null;
    try {
      indicatorCalculator = generateReporting(request, reporting, null, null, false, null);

      indicatorCalculator.addIndicator(indicator);

      // Save configuration
      synchronized (this) {
        File reportingConfigFile = new File(indicatorConfigurationDir
            + INDICATOR_CONFIGURATION_FILE_PREFIX + reporting + ".xml");
        FileUtils.copyFile(indicatorCalculator.toFile(), reportingConfigFile);
      }
    } catch (FileNotFoundException exception) {
      throw new ResourceNotFoundException(String.format(
          "Report with identifier '%s' not found.", reporting), exception);
    }
    return new ResponseEntity(HttpStatus.CREATED);
  }


  /**
   * Delete an indicator.
   */
  @ApiOperation(value = "Delete an indicator in a report specification",
      nickname = "delIndicator")
  @RequestMapping(value = "/reports/{reporting}/indicators/{indicatorId}",
      method = RequestMethod.DELETE)
  @ApiResponses(value = {
      @ApiResponse(code = 201, message = "Indicator removed."),
      @ApiResponse(code = 500, message = "Failed to delete indicator.")
      })
  @ResponseBody
  public ResponseEntity delIndicator(HttpServletRequest request,
                                     @ApiParam(
                                       value = "The report type to update",
                                       required = true)
                                     @PathVariable(value = "reporting")
                                       String reporting,
                                     @ApiParam(
                                       value = "The indicator to remove",
                                       required = true)
                                     @PathVariable(value = "indicatorId")
                                       String indicatorId)
      throws IOException, org.daobs.api.exception.ResourceNotFoundException {
    IndicatorCalculatorImpl indicatorCalculator = null;
    try {
      indicatorCalculator = generateReporting(request, reporting, null, null, false, null);

      indicatorCalculator.removeIndicator(indicatorId);

      // Save configuration
      synchronized (this) {
        File reportingConfigFile = new File(indicatorConfigurationDir
            + INDICATOR_CONFIGURATION_FILE_PREFIX + reporting + ".xml");
        FileUtils.copyFile(indicatorCalculator.toFile(), reportingConfigFile);
      }
    } catch (FileNotFoundException exception) {
      throw new ResourceNotFoundException(String.format(
        "Report with identifier '%s' not found.", reporting), exception);
    }
    return new ResponseEntity(HttpStatus.NO_CONTENT);
  }



  /**
   * Add a report specification in XML or JSON format.
   */
  @ApiOperation(value = "Add or update a variable in a report specification",
      nickname = "addVariable")
  @RequestMapping(value = "/reports/{reporting}/variables",
      consumes = {
          MediaType.APPLICATION_XML_VALUE,
          MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.PUT)
  @ApiResponses(value = {
      @ApiResponse(code = 201, message = "Variable added or updated."),
      @ApiResponse(code = 500, message = "Failed to add variable.")
      })
  @ResponseBody
  public ResponseEntity addVariable(HttpServletRequest request,
                                     @ApiParam(
                                       value = "The report type to generate",
                                       required = true)
                                     @PathVariable(value = "reporting")
                                       String reporting,
                                     @ApiParam(value = "The variable to add or update")
                                     @RequestBody()
                                      Variable variable)
      throws IOException {
    IndicatorCalculatorImpl indicatorCalculator = null;
    try {
      indicatorCalculator = generateReporting(request, reporting, null, null, false, null);

      indicatorCalculator.addVariable(variable);

      // Save configuration
      synchronized (this) {
        File reportingConfigFile = new File(indicatorConfigurationDir
            + INDICATOR_CONFIGURATION_FILE_PREFIX + reporting + ".xml");
        FileUtils.copyFile(indicatorCalculator.toFile(), reportingConfigFile);
      }
    } catch (FileNotFoundException exception) {
      throw new ResourceNotFoundException(String.format(
        "Report with identifier '%s' not found.", reporting), exception);
    }
    return new ResponseEntity(HttpStatus.CREATED);
  }


  /**
   * Delete a variable.
   */
  @ApiOperation(value = "Delete a variable in a report specification",
      nickname = "delVariable")
  @RequestMapping(value = "/reports/{reporting}/variables/{variableId}",
      method = RequestMethod.DELETE)
  @ApiResponses(value = {
      @ApiResponse(code = 201, message = "Indicator removed."),
      @ApiResponse(code = 500, message = "Failed to delete variable.")
      })
  @ResponseBody
  public ResponseEntity delVariable(HttpServletRequest request,
                                     @ApiParam(
                                       value = "The report type to update",
                                       required = true)
                                     @PathVariable(value = "reporting")
                                       String reporting,
                                      @ApiParam(
                                       value = "The variable to remove",
                                       required = true)
                                     @PathVariable(value = "variableId")
                                       String variableId)
      throws IOException, org.daobs.api.exception.ResourceNotFoundException {
    IndicatorCalculatorImpl indicatorCalculator = null;
    try {
      indicatorCalculator = generateReporting(request, reporting, null, null, false, null);

      indicatorCalculator.removeVariable(variableId);

      // Save configuration
      synchronized (this) {
        File reportingConfigFile = new File(indicatorConfigurationDir
            + INDICATOR_CONFIGURATION_FILE_PREFIX + reporting + ".xml");
        FileUtils.copyFile(indicatorCalculator.toFile(), reportingConfigFile);
      }
    } catch (FileNotFoundException exception) {
      throw new ResourceNotFoundException(String.format(
        "Report with identifier '%s' not found.", reporting), exception);
    }
    return new ResponseEntity(HttpStatus.NO_CONTENT);
  }


  /**
   * Remove a report specification.
   */
  @ApiOperation(value = "Remove a report specification",
      nickname = "getReports")
  @RequestMapping(value = "/reports/{reporting}",
      method = RequestMethod.DELETE)

  @ResponseBody
  public ResponseEntity removeSpecification(HttpServletRequest request,
                                         @ApiParam(
                                           value = "The report sepecification to remove",
                                           required = true)
                                         @PathVariable(value = "reporting")
                                           String reporting)
      throws IOException {

    try {
      File reportingConfigFile = new File(indicatorConfigurationDir
          + INDICATOR_CONFIGURATION_FILE_PREFIX + reporting + ".xml");
      if (reportingConfigFile.exists()) {
        reportingConfigFile.delete();
      } else {
        return new ResponseEntity<>(HttpStatus.NOT_FOUND);
      }
      return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    } catch (Exception ex) {
      throw ex;
    }
  }


  /**
   * Generate a specific report for a specific area in XML or JSON format.
   *
   * @param fq Filter query to be applied on top of the scope filter
   */
  @ApiOperation(value = "Generate a XML or JSON report",
      nickname = "getReports")
  @RequestMapping(value = "/reports/{reporting}/{scope}",
      produces = {
          MediaType.APPLICATION_XML_VALUE,
          MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.GET)
  @ApiResponses(value = {
      @ApiResponse(code = 200, message = "Return a report for a scope."),
      @ApiResponse(code = 404, message = "Report not found.")
      })
  @ResponseBody
  public Reporting get(HttpServletRequest request,
                       @ApiParam(
                         value = "The report type to generate",
                         required = true)
                       @PathVariable(value = "reporting") String reporting,
                       @ApiParam(
                         value = "A scope",
                         required = true)
                       @PathVariable(value = "scope") String scope,
                       @ApiParam(
                         value = "An optional scope")
                       @RequestParam(
                         value = "scopeId",
                         defaultValue = "",
                         required = false) String scopeId,
                       @ApiParam(
                         value = "An optional date. If not set, default is now.")
                         @RequestParam(
                           value = "date",
                           defaultValue = "",
                           required = false) String date,
                       @ApiParam(
                         value = "An optional filter query to generate report on a subset",
                         required = true)
                       @RequestParam(
                         value = "fq",
                         defaultValue = "",
                         required = false) String fq)
      throws IOException {
    IndicatorCalculatorImpl indicatorCalculator = null;
    try {
      indicatorCalculator = generateReporting(request, reporting, scopeId, "+scope:" + scope
        + (StringUtils.isEmpty(fq) ? "" : " " + fq.trim()), true, date);
    } catch (FileNotFoundException exception) {
      throw new ResourceNotFoundException(String.format(
        "Report with identifier '%s' not found.", reporting), exception);
    }
    return indicatorCalculator.getConfiguration();
  }


  /**
   * Add a report by uploading a file.
   */
  @ApiOperation(value = "Upload a report",
      nickname = "addReport")
  @RequestMapping(
      value = "/reports",
      produces = {
          MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.POST)
  @ResponseBody
  public ResponseEntity<Map<String, String>> add(
      @ApiParam(value = "The file to upload")
      @RequestParam("file")
      MultipartFile file) throws Exception {

    File xmlFile = File.createTempFile("report", ".xml");
    try {
      String filename = file.getOriginalFilename();
      FileUtils.writeByteArrayToFile(xmlFile, file.getBytes());

      Map<String, String> errors = indexIndicators(filename, xmlFile);
      return new ResponseEntity<>(errors, HttpStatus.OK);
    } finally {
      FileUtils.deleteQuietly(xmlFile);
    }
  }


  /**
   * Generate a specific report for a specific area in XML or JSON format.
   *
   * @param fq Filter query to be applied on top of the scope filter
   */
  @ApiOperation(value = "Save a report",
      nickname = "buildAndIndexReport")
  @RequestMapping(value = "/reports/{reporting}/{scope}",
      produces = {
          MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.PUT)
  @ResponseBody
  public ResponseEntity<Map<String, String>> buildAndIndexReport(
       HttpServletRequest request,
       @ApiParam(
         value = "The report type to generate",
         required = true)
       @PathVariable(value = "reporting") String reporting,
       @ApiParam(
         value = "A scope",
         required = true)
       @PathVariable(value = "scope") String scope,
       @ApiParam(
         value = "An optional scope")
       @RequestParam(
         value = "scopeId",
         defaultValue = "",
         required = false) String scopeId,
       @ApiParam(
         value = "An optional filter query to generate report on a subset",
         required = false)
       @RequestParam(
         value = "fq",
         defaultValue = "",
         required = false) String fq,
       @ApiParam(
         value = "An optional date. If not set, default is now.")
       @RequestParam(
         value = "date",
         defaultValue = "",
         required = false) String date)
        throws IOException {
    IndicatorCalculatorImpl indicatorCalculator =
        generateReporting(request, reporting, scopeId, "+scope:" + scope
        + (StringUtils.isEmpty(fq) ? "" : " " + fq.trim()), true, date);

    File xmlFile = indicatorCalculator.toFile();
    try {
      // Index indicators
      Map<String, String> errors = indexIndicators(xmlFile.getName(), xmlFile);
      return new ResponseEntity<>(errors, HttpStatus.CREATED);
    } catch (Exception ex) {
      ex.printStackTrace();
    } finally {
      FileUtils.deleteQuietly(xmlFile);
    }
    return null;
  }


  /**
   * Generate a report.
   *
   * <p>Reporting id is the XSLT to use to build the report
   * based on DAOBS XML format.
   *
   * <p>Raw data concept is specific to INSPIRE reporting and
   * add the record used to the report.
   */
  @ApiOperation(value = "Generate a report",
      nickname = "generateReport")
  @RequestMapping(value = "/reports/custom/{reporting}",
      produces = {
          MediaType.APPLICATION_XML_VALUE
      },
      method = RequestMethod.GET)
  public ModelAndView generateMonitoring(
      HttpServletRequest request,
      @RequestParam Map<String, String> allRequestParams,
      @ApiParam(
        value = "The report type to generate",
        required = true)
      @PathVariable(value = "reporting") String reporting,
      @ApiParam(
        value = "Add raw data section")
      @RequestParam(
        value = "withRowData",
        required = false) Boolean withRowData,
      @ApiParam(
        value = "An optional filter query to generate report on a subset",
        required = false)
      @RequestParam(
        value = "fq",
        defaultValue = "",
        required = false) String fq,
      @ApiParam(
        value = "An optional scope id to uniquely identify the report scope")
      @RequestParam(
        value = "scopeId",
        defaultValue = "",
        required = false) String scopeId,
      @ApiParam(
        value = "An optional date. If not set, default is now.")
      @RequestParam(
        value = "date",
        defaultValue = "",
        required = false) String date,
      @ApiParam(
        value = "Max number of documents to add in the raw data section")
      @RequestParam(
        value = "rows",
        defaultValue = "10000",
        required = false) int rows)
      throws IOException {
    IndicatorCalculatorImpl indicatorCalculator =
        generateReporting(request, reporting, scopeId, fq, true, date);

    ModelAndView model = new ModelAndView("reporting-xslt-" + reporting);
    model.addObject("xmlSource", indicatorCalculator.toSource());

    addRequestParametersToModel(allRequestParams, model);

    addRowDataToModel(withRowData, rows, fq, model);

    return model;
  }


  /**
   * Generate a specific report for a specific area in
   * INSPIRE monitoring reporting format.
   *
   * @param withRowData Include the rowData section in the report.
   * @param rows        Number of rows to return for spatial data sets and services
   *                    Default value is 10000. When the number of records to return
   *                    is too high, error may occurs. Only applies if withRowData
   *                    is true.
   */
  @ApiOperation(value = "Generate a specific report "
      + "for a specific area in INSPIRE monitoring reporting format",
      nickname = "generateINSPIREReport")
  @RequestMapping(value = "/reports/custom/{reporting}/{scope}",
      produces = {
          MediaType.APPLICATION_XML_VALUE
      },
      method = RequestMethod.GET)
  @ResponseBody
  public ModelAndView generateMonitoring(
      HttpServletRequest request,
      @RequestParam Map<String, String> allRequestParams,
      @ApiParam(
        value = "Add raw data section")
      @RequestParam(
        value = "withRowData",
        required = false) Boolean withRowData,
      @ApiParam(
        value = "An optional filter query to generate report on a subset",
        required = false)
      @RequestParam(
        value = "fq",
        defaultValue = "",
        required = false) String fq,
      @ApiParam(
        value = "An optional scope")
      @RequestParam(
        value = "scopeId",
        defaultValue = "",
        required = false) String scopeId,
      @ApiParam(
        value = "An optional date. If not set, default is now.")
      @RequestParam(
        value = "date",
        defaultValue = "",
        required = false) String date,
      @ApiParam(
        value = "Max number of documents to add in the raw data section")
      @RequestParam(
        value = "rows",
        defaultValue = "10000",
        required = false) int rows,
      @ApiParam(
        value = "The report type to generate",
        required = true)
      @PathVariable(value = "reporting") String reporting,
      @ApiParam(
        value = "A scope",
        required = true)
      @PathVariable(value = "scope") String scope)
      throws IOException {
    String filter = fq + " +scope:" + scope;
    IndicatorCalculatorImpl indicatorCalculator =
        generateReporting(request, reporting, scopeId, filter, true, date);


    ModelAndView model = new ModelAndView("reporting-xslt-" + reporting);
    model.addObject("xmlSource", indicatorCalculator.toSource());
    // Add path parameters
    if (scope != null) {
      model.addObject("scope", scope);
    }
    if (filter != null) {
      model.addObject("filter", filter);
    }

    addRequestParametersToModel(allRequestParams, model);

    // TODO: URL encoding should be done when the HTTP request is made
    addRowDataToModel(withRowData, rows, filter, model);

    return model;
  }


  /**
   * Save a specific report for a specific area in
   * INSPIRE monitoring reporting format.
   *
   * @param withRowData Include the rowData section in the report.
   * @param rows        Number of rows to return for spatial data sets and services
   *                    Default value is 10000. When the number of records to return
   *                    is too high, error may occurs. Only applies if withRowData
   */
  @ApiOperation(value = "Save a report "
      + "for a specific area in INSPIRE monitoring reporting format",
      nickname = "saveReport")
  @RequestMapping(value = "/reports/custom/{reporting}/{scope}",
      produces = {
          MediaType.APPLICATION_XML_VALUE
      },
      method = RequestMethod.PUT)
  @ResponseBody
  public ResponseEntity<Map<String, String>> saveMonitoring(
      HttpServletRequest request,
      @RequestParam Map<String, String> allRequestParams,
      @ApiParam(
        value = "Add raw data section")
      @RequestParam(
        value = "withRowData",
        required = false) Boolean withRowData,
      @ApiParam(
        value = "An optional filter query to generate report on a subset",
        required = false)
      @RequestParam(
        value = "fq",
        defaultValue = "",
        required = false) String fq,
      @ApiParam(
        value = "An optional scope")
      @RequestParam(
        value = "scopeId",
        defaultValue = "",
        required = false) String scopeId,
      @ApiParam(
        value = "An optional date. If not set, default is now.")
      @RequestParam(
        value = "date",
        defaultValue = "",
        required = false) String date,
      @ApiParam(
        value = "Max number of documents to add in the raw data section")
      @RequestParam(
        value = "rows",
        defaultValue = "10000",
        required = false) int rows,
      @ApiParam(
        value = "The report type to generate",
        required = true)
      @PathVariable(value = "reporting") String reporting,
      @ApiParam(
        value = "A scope",
        required = true)
      @PathVariable(value = "scope") String scope,
      HttpServletResponse response)
      throws IOException {
    String filter = fq + " +scope:" + scope;
    IndicatorCalculatorImpl indicatorCalculator =
        generateReporting(request, reporting, scopeId, filter, true, date);

    ModelAndView model = new ModelAndView("reporting-xslt-" + reporting);
    model.addObject("xmlSource", indicatorCalculator.toSource());
    // Add path parameters
    if (scope != null) {
      model.addObject("scope", scope);
    }
    if (filter != null) {
      model.addObject("filter", filter);
    }

    addRequestParametersToModel(allRequestParams, model);
    addRowDataToModel(withRowData, rows, filter, model);


    File xmlFile = File.createTempFile("report", ".xml");
    try {
      // Create report
      MockHttpServletResponse mockResp = new MockHttpServletResponse();

      XsltViewResolver view = appContext.getBean(XsltViewResolver.class);
      view.resolveViewName("reporting-xslt-" + reporting, Locale.ENGLISH)
        .render(model.getModel(), request, mockResp);


      // Save report to file
      FileUtils.writeByteArrayToFile(xmlFile, mockResp.getContentAsByteArray());


      // Index indicators
      Map<String, String> errors = indexIndicators(xmlFile.getName(), xmlFile);
      return new ResponseEntity<>(errors, HttpStatus.CREATED);
    } catch (Exception ex) {
      ex.printStackTrace();
    } finally {
      FileUtils.deleteQuietly(xmlFile);
    }
    return null;
  }


  /**
   * Remove one or more reports.
   */
  @ApiOperation(value = "Remove one or more reports",
      nickname = "deleteReport")
  @RequestMapping(
      value = "/reports",
      produces = {
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.DELETE)
  @ResponseBody
  public ResponseEntity<String> delete(
      @ApiParam(
          value = "A query to select report to delete",
          required = true)
      @RequestParam final String query) {
    String message = null;
    try {
      message = EsRequestBean.deleteByQuery("indicators", query, 1000);
      return new ResponseEntity<>(
        message,
        HttpStatus.OK);
    } catch (Exception ex) {
      return new ResponseEntity<>(
        message,
        HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }


  /**
   * Remove all ETF reports.
   */
  @ApiOperation(value = "Remove all ETF reports",
      nickname = "deleteEtfReports")
  @RequestMapping(value = "/reports/etf",
      produces = {
          MediaType.APPLICATION_XML_VALUE,
          MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.DELETE)
  @ResponseBody
  public ResponseEntity<String> deleteEtfReports() throws Exception {

    File reportDirectory = new File(this.reportsPath);
    try {
      if (reportDirectory.isDirectory()) {
        FileUtils.cleanDirectory(reportDirectory);
      }
    } catch (Exception ex) {
      ;
    }

    return new ResponseEntity<>("All ETF reports removed", HttpStatus.OK);
  }

  /**
   * Remove all reports related to a harvester.
   */
  @ApiOperation(value = "Remove reports related to a harvester",
      nickname = "deleteEtfHarvesterReports")
  @RequestMapping(value = "/reports/etf/{uuid}",
      produces = {
          MediaType.APPLICATION_XML_VALUE,
          MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.DELETE)
  @ResponseBody
  public ResponseEntity<String> deleteEtfHarvesterReports(
      @PathVariable(value = "uuid") String harvesterUuid
  ) throws Exception {

    // Delete the ETF reports
    String harvesterReportsPath = Paths.get(this.reportsPath,
        harvesterUuid).toString();

    File reportDirectory = new File(harvesterReportsPath);
    if (reportDirectory.exists()) {
      FileUtils.deleteQuietly(reportDirectory);
      return new ResponseEntity<>("All ETF reports for harvester ("
        + harvesterUuid + ") removed", HttpStatus.OK);
    } else {
      return new ResponseEntity<>("No ETF reports for harvester ("
        + harvesterUuid + ") found", HttpStatus.NOT_FOUND);
    }
  }

  /**
   * Add a ETF reports.
   */
  @ApiOperation(value = "Add ETF reports",
      nickname = "addEtfReports")
  @RequestMapping(
      value = "/reports/etf",
      produces = {
          MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.POST)
  @ResponseBody
  public ResponseEntity<String> addEtfReports(
        @ApiParam(value = "The file to upload")
        @RequestParam("file")
      MultipartFile file) throws Exception {

    File zipFile = File.createTempFile("reports", ".zip");
    FileUtils.writeByteArrayToFile(zipFile, file.getBytes());

    UnzipUtility unzipper = new UnzipUtility();
    unzipper.unzip(zipFile, new File(this.reportsPath));

    return new ResponseEntity<>("", HttpStatus.OK);
  }


  /**
   * Query the index to find matching records for INSPIRE
   * raw data section (ie. SpatialDataSets & Services).
   */
  private void addRowDataToModel(Boolean withRowData, int rows, String fq, ModelAndView model) {
    // Handle defaults for boolean
    if (withRowData == null) {
      withRowData = false;
    }
    model.addObject("withRowData", withRowData);

    // Grab data sets and services to later
    // build the raw data section
    if (withRowData) {
      Node spatialDataSets = null;
      try {
        spatialDataSets = EsRequestBean.query(index,
          SPATIALDATASETS_QUERY_URL,
          fq + " +resourceType:(dataset or series)", rows);
        model.addObject("spatialDataSets", spatialDataSets);
      } catch (Exception ex) {
        ex.printStackTrace();
      }


      Node spatialDataServices = null;
      try {
        spatialDataServices = EsRequestBean.query(index,
          SPATIALDATASERVICE_QUERY_URL,
          fq + " +resourceType:service", rows);
        model.addObject("spatialDataServices", spatialDataServices);
      } catch (Exception ex) {
        ex.printStackTrace();
      }
    }
  }


  /**
   * Add all request parameters to the model.
   */
  private void addRequestParametersToModel(
      Map<String, String> allRequestParams,
      ModelAndView model) {
    // Add all request parameters to the model
    // in order to have them as XSL parameters in the view.
    Iterator iterator = allRequestParams.entrySet().iterator();

    while (iterator.hasNext()) {
      Map.Entry<String, String> parameter = (Map.Entry<String, String>) iterator.next();
      String parameterName = parameter.getKey();
      Object parameterValue = (String) parameter.getValue();
      if (BOOLEAN_PARAMETERS.contains(parameterName)) {
        parameterValue = Boolean.parseBoolean((String) parameterValue);
      }
      model.addObject(parameterName, parameterValue);
    }
  }

  /**
   * From an XML file in DAOBS XML format or INSPIRE format
   * index indicators.
   */
  private Map<String, String> indexIndicators(String filename, File xmlFile) throws Exception {
    Map<String, String> errors = new HashMap();
    final String xslt = "/xslt/index-indicators.xsl";
    InputStream streamSource = this.getClass().getResourceAsStream(xslt);
    Source stylesheet = new StreamSource(streamSource);
    URL url = this.getClass().getResource(xslt);
    // http://stackoverflow.com/questions/3699860/resolving-relative-paths-when-loading-xslt-files
    if (url != null) {
      stylesheet.setSystemId(url.toExternalForm());
    } else {
      // log.warning("WARNING: Error when setSystemId for XSL: "
      // + xslt + ". Check resource location.");
    }

    Element results = simpleTransform(
        xmlFile.getAbsolutePath(),
        stylesheet);

    if (results != null) {
      Iterator iterator = results.getChildren().iterator();
      EsClientBean client = EsClientBean.get();
      BulkRequestBuilder bulkRequestBuilder = client.getClient()
          .prepareBulk();
      BulkResponse response = null;
      int counter = 0;
      while (iterator.hasNext()) {
        Object next = iterator.next();
        try {
          if (next instanceof Element) {
            Element element = (Element) next;
            String json = elementToJson(element);
            String id = getId(element);


            bulkRequestBuilder.add(
                client.getClient().prepareIndex("indicators", "indicators", id).setSource(json)
            );
            counter++;

            if (bulkRequestBuilder.numberOfActions() % commitInterval == 0) {
              response = bulkRequestBuilder.execute().actionGet();
              logger.info(String.format("Importing reporting: %d actions performed. Has errors: %s",
                  counter,
                  response.hasFailures()
              ));
              if (response.hasFailures()) {
                errors.put(counter + "", response.buildFailureMessage());
              }
              bulkRequestBuilder = client.getClient().prepareBulk();
            }
          }
        } catch (Exception ex) {
          ex.printStackTrace();
        }
      }
      if (bulkRequestBuilder.numberOfActions() > 0) {
        bulkRequestBuilder
            .setRefreshPolicy(WriteRequest.RefreshPolicy.IMMEDIATE);
        response = bulkRequestBuilder.execute().actionGet();
        logger.info(String.format("Importing reporting: %d actions performed. Has errors: %s",
            counter,
            response.hasFailures()
        ));
        if (response.hasFailures()) {
          errors.put(counter + "", response.buildFailureMessage());
        }
      }
    } else {
      errors.put("0", String.format(
          "No content to index find in file %s.",
          filename));
    }
    return errors;
  }

  /**
   * Simple XSL transformation. To be Improved.
   */
  public static Element simpleTransform(String sourcePath,
                                        Source stylesheet) {
    TransformerFactory transformerFactory = TransformerFactory.newInstance();
    JDOMResult jdomResult = new JDOMResult();
    try {
      Transformer transformer =
          transformerFactory.newTransformer(stylesheet);

      transformer.transform(new StreamSource(new File(sourcePath)),
          jdomResult);//new StreamResult(new File(resultDir)));
      return jdomResult.getDocument().getRootElement().detach();
    } catch (Exception e1) {
      e1.printStackTrace();
    }
    return null;
  }


  /**
   * Render reporting using XSLT view.
   */
  public IndicatorCalculatorImpl generateReporting(HttpServletRequest request,
                                                   String reporting,
                                                   String scopeId,
                                                   String fq,
                                                   boolean calculate, String date)
      throws ResourceNotFoundException, FileNotFoundException {
    String configurationFilePath =
        indicatorConfigurationDir
        + INDICATOR_CONFIGURATION_FILE_PREFIX
        + reporting + ".xml";
    File configurationFile =
        new File(configurationFilePath);

    if (configurationFile.exists()) {
      IndicatorCalculatorImpl indicatorCalculator =
          new IndicatorCalculatorImpl(configurationFile);

      if (calculate) {
        indicatorCalculator.computeIndicators(scopeId, date, fq);
      }
      // adds the XML source file to the model so the XsltView can detect
      return indicatorCalculator;
    } else {
      throw new ResourceNotFoundException(String.format(
          "Reporting configuration "
            + "'%s' file does not exist for reporting '%s'.",
          configurationFilePath,
          reporting));
    }
  }


  /**
   * Convert Element to JSON.
   */
  public String elementToJson(Element xml) {
    try {
      XContentBuilder xcb = jsonBuilder()
          .startObject();

      List childNodes = xml.getChildren();

      if (childNodes != null) {
        childNodes.forEach(o -> {
          if (o instanceof Element) {
            Element element = (Element) o;
            try {
              xcb.field(
                  element.getAttributeValue("name"),
                  element.getTextNormalize());
            } catch (IOException e1) {
              e1.printStackTrace();
            }
          }
        });
      }
      xcb.endObject();
      return xcb.string();
    } catch (IOException ex) {
      ex.printStackTrace();
    }
    return null;
  }

  /**
   * Get first element with id name attribute.
   */
  public String getId(Element xml) {
    Iterator iterator = xml.getChildren().iterator();
    while (iterator.hasNext()) {
      Object next = iterator.next();

      if (next instanceof Element) {
        Element element = (Element) next;
        if (element.getAttributeValue("name").equals("id")) {
          return element.getTextNormalize();
        }
      }
    }
    return null;
  }


  // TODO: config should move to configuration file
  public static final String[] SPATIALDATASETS_QUERY_URL = new String[]{
      "metadataIdentifier", "resourceTitle", "isAboveThreshold",
      "inspireAnnex", "inspireTheme", "inspireConformResource",
      "recordOperatedByType", "recordOperatedByTypeview", "recordOperatedByTypedownload",
      "OrgForResource", "custodianOrgForResource", "ownerOrgForResource",
      "pointOfContactOrgForResource", "harvesterUuid"
  };

  public static final String[] SPATIALDATASERVICE_QUERY_URL = new String[]{
      "metadataIdentifier", "resourceTitle", "isAboveThreshold",
      "inspireAnnex", "inspireTheme", "inspireConformResource",
      "serviceType", "linkUrl", "link",
      "OrgForResource", "custodianOrgForResource", "ownerOrgForResource",
      "pointOfContactOrgForResource", "harvesterUuid"
  };

  public static final List<String> BOOLEAN_PARAMETERS = new ArrayList<>(
      Arrays.asList("withRowData")
  );
}
