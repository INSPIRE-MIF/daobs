/**
 * Copyright 2014-2016 European Environment Agency
 *
 * Licensed under the EUPL, Version 1.1 or – as soon
 * they will be approved by the European Commission -
 * subsequent versions of the EUPL (the "Licence");
 * You may not use this work except in compliance
 * with the Licence.
 * You may obtain a copy of the Licence at:
 *
 * https://joinup.ec.europa.eu/community/eupl/og_page/eupl
 *
 * Unless required by applicable law or agreed to in
 * writing, software distributed under the Licence is
 * distributed on an "AS IS" basis,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.
 * See the Licence for the specific language governing
 * permissions and limitations under the Licence.
 */

package org.daobs.tasks.validation.etf;

import org.apache.camel.Exchange;
import org.apache.commons.lang3.StringEscapeUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.w3c.dom.Document;

import java.io.ByteArrayInputStream;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathFactory;

/**
 * Simple bean to call the ETF validation service.
 *
 * @author Jose García
 */
public class EtfValidatorBean {
  String etfResourceTesterPath;
  String etfResourceTesterHtmlReportsPath;
  String etfResourceTesterHtmlReportsUrl;
  private Log log = LogFactory.getLog(this.getClass());

  public int getTimeout() {
    return timeout;
  }

  public void setTimeout(int timeout) {
    this.timeout = timeout;
  }

  private int timeout = 1;

  public String getEtfResourceTesterPath() {
    return etfResourceTesterPath;
  }

  public void setEtfResourceTesterPath(String etfResourceTesterPath) {
    this.etfResourceTesterPath = etfResourceTesterPath;
  }

  public String getEtfResourceTesterHtmlReportsPath() {
    return etfResourceTesterHtmlReportsPath;
  }

  public void setEtfResourceTesterHtmlReportsPath(String etfResourceTesterHtmlReportsPath) {
    this.etfResourceTesterHtmlReportsPath = etfResourceTesterHtmlReportsPath;
  }

  public String getEtfResourceTesterHtmlReportsUrl() {
    return etfResourceTesterHtmlReportsUrl;
  }

  public void setEtfResourceTesterHtmlReportsUrl(String etfResourceTesterHtmlReportsUrl) {
    this.etfResourceTesterHtmlReportsUrl = etfResourceTesterHtmlReportsUrl;
  }

  /**
   * Get the input message body and validate
   * it against the ETF validation tool.
   * The output body contains the validation report.
   * Headers are propagated.
   */
  public void validateBody(Exchange exchange) {
    String xml = exchange.getIn().getBody(String.class);

    EtfValidationReport report = null;


    try {
      DocumentBuilderFactory factory =
          DocumentBuilderFactory.newInstance();
      DocumentBuilder builder = factory.newDocumentBuilder();

      ByteArrayInputStream input = new ByteArrayInputStream(xml.getBytes(StandardCharsets.UTF_8));
      Document doc = builder.parse(input);

      XPath xpath = XPathFactory.newInstance().newXPath();

      String expression = "/e/harvesterUuid";
      String harvesterUuid =
          (String) xpath.compile(expression).evaluate(doc, XPathConstants.STRING);

      String reportPath = Paths.get(this.etfResourceTesterHtmlReportsPath,
          harvesterUuid).toString();

      String reportUrl =  this.etfResourceTesterHtmlReportsUrl + "/" + harvesterUuid;

      final EtfValidatorClient validatorClient =
          new EtfValidatorClient(this.etfResourceTesterPath, reportPath, reportUrl, timeout);

      expression = "/e//serviceType";
      String serviceType = (String) xpath.compile(expression).evaluate(doc, XPathConstants.STRING);

      expression = "/e//linkUrl";
      String url = (String) xpath.compile(expression).evaluate(doc, XPathConstants.STRING);

      expression = "/e//linkProtocol";
      String declaredProtocol =
          (String) xpath.compile(expression).evaluate(doc, XPathConstants.STRING);


      report = validatorClient.validate(url, ServiceType.fromString(serviceType), declaredProtocol);

    } catch (Exception exception) {
      log.error(exception.getMessage());
    }

    exchange.getOut().setBody(report);
    exchange.getOut().setHeaders(exchange.getIn().getHeaders());
  }
}
