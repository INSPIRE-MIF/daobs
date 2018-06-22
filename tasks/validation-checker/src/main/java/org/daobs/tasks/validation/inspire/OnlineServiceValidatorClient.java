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

package org.daobs.tasks.validation.inspire;

import static org.daobs.routing.utility.Utility.encodeForJson;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.ByteArrayEntity;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.FileBody;
import org.apache.http.entity.mime.content.StringBody;
import org.apache.http.impl.client.HttpClientBuilder;
import org.springframework.util.Assert;

import java.io.File;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Paths;


/**
 * Simple Java Client for the INSPIRE Geoportal Validator
 * http://inspire-geoportal.ec.europa.eu/validator2/#
 */
public class OnlineServiceValidatorClient {

  String inspireResourceTesterUrl;
  boolean dontGenerateLayerPreviews = true;
  boolean dontGenerateHtmlFiles = true;
  boolean probeNetworkServices = false;
  boolean probeDataResourceLocators = false;
  private double threshold = 100.0;


  OnlineServiceValidatorClient() {
  }

  OnlineServiceValidatorClient(String inspireResourceTesterUrl, double threshold) {
    this.inspireResourceTesterUrl = inspireResourceTesterUrl;
    this.threshold = threshold;
  }

  OnlineServiceValidatorClient(String inspireResourceTesterUrl,
                               double threshold,
                               boolean probeDataResourceLocators,
                               boolean probeNetworkServices) {
    this.inspireResourceTesterUrl = inspireResourceTesterUrl;
    this.threshold = threshold;
    this.probeDataResourceLocators = probeDataResourceLocators;
    this.probeNetworkServices = probeNetworkServices;
  }

  public String getInspireResourceTesterUrl() {
    return inspireResourceTesterUrl;
  }

  public OnlineServiceValidatorClient setInspireResourceTesterUrl(String inspireResourceTesterUrl) {
    this.inspireResourceTesterUrl = inspireResourceTesterUrl;
    return this;
  }

  public boolean isDontGenerateLayerPreviews() {
    return dontGenerateLayerPreviews;
  }

  public void setDontGenerateLayerPreviews(boolean dontGenerateLayerPreviews) {
    this.dontGenerateLayerPreviews = dontGenerateLayerPreviews;
  }

  public double getThreshold() {
    return threshold;
  }

  public void setThreshold(double threshold) {
    this.threshold = threshold;
  }

  public boolean isDontGenerateHtmlFiles() {
    return dontGenerateHtmlFiles;
  }

  public void setDontGenerateHtmlFiles(boolean dontGenerateHtmlFiles) {
    this.dontGenerateHtmlFiles = dontGenerateHtmlFiles;
  }

  public boolean isProbeNetworkServices() {
    return probeNetworkServices;
  }

  public void setProbeNetworkServices(boolean probeNetworkServices) {
    this.probeNetworkServices = probeNetworkServices;
  }

  public boolean isProbeDataResourceLocators() {
    return probeDataResourceLocators;
  }

  public void setProbeDataResourceLocators(boolean probeDataResourceLocators) {
    this.probeDataResourceLocators = probeDataResourceLocators;
  }

  public ValidationReport validate(String resourceDescriptorText)
      throws UnsupportedEncodingException, MalformedURLException {
    return validate(resourceDescriptorText, null);
  }

  public ValidationReport validate(String resourceDescriptorText, boolean zipContent)
      throws UnsupportedEncodingException, MalformedURLException {
    return validate(resourceDescriptorText, null);
  }

  public ValidationReport validate(File resourceDescriptorFile)
      throws UnsupportedEncodingException, MalformedURLException {
    return validate(null, resourceDescriptorFile);
  }

  private ValidationReport validate(
      String resourceDescriptorText,
      File resourceDescriptorFile) throws MalformedURLException {
    HttpResponse retVal = null;

    HttpClient httpClient = HttpClientBuilder.create()
        // .setRedirectStrategy(new LaxRedirectStrategy())
        .build();

    ValidationReport report = new ValidationReport(threshold);
    HttpPost httpPost = new HttpPost(this.inspireResourceTesterUrl);
    httpPost.addHeader("Accept", "application/xml");

    // See http://inspire-geoportal.ec.europa.eu/validator2/html/usingaswebservice.html
    // To Avoid HTTP status 301, use POST with body
    // "This binding is best suited for machine-to-machine interaction."
    HttpEntity entity = null;
    httpPost.addHeader("Content-type", "text/plain");
    try {
      entity = new ByteArrayEntity(
        resourceDescriptorFile != null
          ? Files.readAllBytes(Paths.get(resourceDescriptorFile.toURI()))
          : resourceDescriptorText.getBytes("UTF-8"));
    } catch (IOException exc) {
      exc.printStackTrace();
    }
    httpPost.setEntity(entity);

    // Old way of calling the service return 201 or 301.
    // 301 would require polling
    //    MultipartEntity reqEntity = new MultipartEntity();
    //
    //    if (resourceDescriptorFile != null) {
    //      FileBody dataFile = new FileBody(resourceDescriptorFile);
    //      reqEntity.addPart("uploadedFile", dataFile);
    //    }
    //
    //    if (resourceDescriptorText != null) {
    //      StringBody stringPart = null;
    //      try {
    //        stringPart = new StringBody(resourceDescriptorText);
    //      } catch (UnsupportedEncodingException exception) {
    //        exception.printStackTrace();
    //      }
    //      reqEntity.addPart("resourceRepresentation", stringPart);
    //    }
    //
    //    httpPost.setEntity(reqEntity);

    try {
      report.start();

      retVal = httpClient.execute(httpPost);
    } catch (ClientProtocolException ex) {
      report.setInfo(ex.getMessage());
    } catch (IOException ex) {
      report.setInfo(ex.getMessage());
    }

    report.gotResponse();

    getResponse(retVal, report);

    report.stop();
    return report;
  }

  private void getResponse(HttpResponse validatorResponse,
                           ValidationReport report) {
    Assert.notNull(report, "Null report not allowed.");
    try {
      //The HTTP response status codes can be:
      //HTTP STATUS CODE 201 (Created)
      // - a validation report is created or just the resource representation if no issues are found
      //HTTP STATUS CODE 400 (Bad Request)
      // - the representation sent was not understood at all
      //HTTP STATUS CODE 500 (Internal server error)
      // - a serious system error has occurred
      int responseStatusCode = validatorResponse.getStatusLine().getStatusCode();
      report.setHttpStatus(responseStatusCode);

      if (responseStatusCode == 201) {
        //URL of the validation report or of the resource
        // metadata if no issues were found
        String resultUrl = validatorResponse.getHeaders("Location")[0].getValue();
        report.setResultUrl(resultUrl);

        if (resultUrl.endsWith("resourceReport")) {
          //Validation issues were found, hence a validation report has been generated
          report.setInfo(String.format(
              "Validation issues were found. A report is available at the following URL: %s",
              resultUrl));
          report.setStatus(false);
        } else {
          //No validation issues were found

          report.setInfo(String.format("No validation issues were found. "
              + "The metadata information extracted is available at the following URL: %s",
              resultUrl));
          report.setStatus(true);
        }

        //XML representation of the validation report
        // or of the resource metadata if no issues were found
        String xml = org.apache.commons.io.IOUtils.toString(
            validatorResponse.getEntity().getContent(), "UTF-8");
        report.setReport(encodeForJson(xml));
      } else {
        report.setInfo(String.format(
            "Exception. HTTP status is %d expected 201.", responseStatusCode
        ));
      }
    } catch (IOException ex) {
      report.setInfo("Exception: " + encodeForJson(ex.getMessage()));
    }
  }
}
