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

package org.daobs.harvester;

import static java.nio.charset.StandardCharsets.UTF_8;

import com.google.common.base.Charsets;

import org.apache.camel.Exchange;
import org.apache.camel.ExchangeProperty;
import org.apache.commons.io.IOUtils;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import java.io.IOException;
import java.io.InputStream;
import java.io.StringReader;
import java.io.StringWriter;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;



/**
 * Created by francois on 9/1/14.
 */
public class CswHarvester {
  Logger log = Logger.getLogger("org.daobs.harvester.csw");
  private Map<String, Config> harvesters = new HashMap<String, Config>();
  private String getRecordsTemplate = "";
  private String getRecordsHitsTemplate = "";
  private int maxRecords = 100;

  /**
   * CSW harvester.
   */
  public CswHarvester() {
    String fileName = "csw-get-records.xml";
    try {
      InputStream stream = this.getClass().getResourceAsStream("/" + fileName);
      getRecordsTemplate = IOUtils.toString(stream,
        Charsets.UTF_8);
    } catch (IOException exception) {
      log.warning("Can't find '" + fileName + "'. Error is: " + exception.getMessage());
    }
    String fileNameHits = "csw-get-records-hits.xml";
    try {
      InputStream stream = this.getClass().getResourceAsStream("/" + fileNameHits);
      getRecordsHitsTemplate = IOUtils.toString(stream,
        Charsets.UTF_8);
    } catch (IOException exception) {
      log.warning("Can't find '" + fileName + "'. Error is: " + exception.getMessage());
    }
  }

  public int getMaxRecords() {
    return maxRecords;
  }

  public void setMaxRecords(int maxRecords) {
    this.maxRecords = maxRecords;
  }

  /**
   * Initialize harvester configuration.
   *
   * @param identifier  The harvester url
   * @param filter  The harvester Filter
   * @param nbRecordsPerPage  The number of record per page
   *
   * @return  The harvester configuration
   */
  public Config initialize(@ExchangeProperty("harvesterUrl") String identifier,
                           @ExchangeProperty("harvesterFilter") Document filter,
                           @ExchangeProperty("harvesterNbRecordsPerPage") int nbRecordsPerPage) {

    log.info(String.format("Initializing configuration for %s.", identifier));
    Config config = new Config();
    if (nbRecordsPerPage != -1) {
      config.setMaxRecords(nbRecordsPerPage);
    } else {
      config.setMaxRecords(maxRecords);
    }
    config.setRecordsFilter(filter.getFirstChild());
    harvesters.put(identifier, config);
    return config;
  }


  /**
   * Load a file content as String.
   *
   * @param file The file name to load eg. file:///data/test.xml
   * @return  The file content
   */
  public String loadFile(@ExchangeProperty("harvesterUrl") String file) throws IOException {
    return String.join("",
      Files.readAllLines(
        Paths.get(file.replace("file:", "")),
        UTF_8)).trim()
      // Remove BOM if present (Avoid content not allowed in prolog error)
      .replace("\uFEFF", "");
  }

  private Config getConfig(@ExchangeProperty("harvesterUrl") String identifier) {
    Config config = harvesters.get(identifier);
    if (config == null) {
      config = new Config();
      config.setMaxRecords(maxRecords);
      harvesters.put(identifier, config);

    }
    return config;
  }

  /**
   * Update the config with the number of records matched.
   *
   * @param identifier  The harvester URL
   * @param numberOfRecordsMatched  The number of records that match the filter
   */
  public void setNumberOfRecords(
      @ExchangeProperty("harvesterUrl") String identifier,
      String numberOfRecordsMatched) {
    Config config = getConfig(identifier);
    config.setNumberOfRecordsMatched(Integer.parseInt(numberOfRecordsMatched));

  }

  public List<String> getPages(@ExchangeProperty("harvesterUrl") String identifier) {
    Config config = getConfig(identifier);
    return config.computeNumberOfPages();
  }

  public int getNumberOfPages(@ExchangeProperty("harvesterUrl") String identifier) {
    Config config = getConfig(identifier);
    return config.getPages().size();
  }

  private String buildGetRecordsQuery(Node filter,
                                      boolean forHits,
                                      int startPosition,
                                      int maxRecords) {

    DocumentBuilderFactory domFactory = DocumentBuilderFactory.newInstance();
    domFactory.setNamespaceAware(true); // never forget this!
    try {
      DocumentBuilder builder = domFactory.newDocumentBuilder();
      Document getRecordsRequest = builder.parse(
          new InputSource(
            new StringReader(forHits
              ?
                this.getRecordsHitsTemplate :
                this.getRecordsTemplate)));

      // Append the optional CSW filter to the query element
      if (filter != null && filter.getFirstChild() != null) {
        String cswNamespace = "http://www.opengis.net/cat/csw/2.0.2";
        String ogcNamespace = "http://www.opengis.net/ogc";
        Node children = getRecordsRequest.getDocumentElement()
            .getElementsByTagNameNS(cswNamespace,
              "Query").item(0);
        if (children != null) {
          // <csw:Constraint version="1.1.0">
          // <Filter xmlns="http://www.opengis.net/ogc"/>
          // </csw:Constraint>

          Element constraintElement = getRecordsRequest.createElementNS(cswNamespace, "Constraint");
          constraintElement.setAttribute("version", "1.1.0");

          Node filterNode = getRecordsRequest.importNode(filter, true);
          constraintElement.appendChild(filterNode);
          children.appendChild(constraintElement);
        }
      }

      if (!forHits) {
        // Set the start position and max record
        NamedNodeMap attributes = getRecordsRequest.getFirstChild().getAttributes();
        Node maxRecordsNode = attributes.getNamedItem("maxRecords");
        if (maxRecordsNode != null) {
          maxRecordsNode.setTextContent(maxRecords + "");
        }


        Node startPositionNode = attributes.getNamedItem("startPosition");
        if (startPositionNode != null) {
          startPositionNode.setTextContent(startPosition + "");
        }
      }
      StringWriter sw = new StringWriter();
      TransformerFactory tf = TransformerFactory.newInstance();
      Transformer transformer = tf.newTransformer();
      transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
      transformer.setOutputProperty(OutputKeys.METHOD, "xml");
      transformer.setOutputProperty(OutputKeys.INDENT, "yes");
      transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");

      transformer.transform(
          new DOMSource(getRecordsRequest),
          new StreamResult(sw)
      );
      String response = sw.toString();
      log.info(response);
      return response;
    } catch (ParserConfigurationException exception) {
      exception.printStackTrace();
    } catch (SAXException exception) {
      exception.printStackTrace();
    } catch (IOException exception) {
      exception.printStackTrace();
    } catch (TransformerConfigurationException exception) {
      exception.printStackTrace();
    } catch (TransformerException exception) {
      exception.printStackTrace();
    }
    return null;
  }

  /**
   * Generate the GetRecords hits query.
   * @param identifier  The harvester identifier
   * @param exchange  The Camel exchange
   * @return  The XML query
   */
  public String generateGetRecordsHitsQuery(
      @ExchangeProperty("harvesterUrl") String identifier,
      Exchange exchange) {
    Config config = getConfig(identifier);
    return buildGetRecordsQuery(config.getRecordsFilter(),
      true,
      0,
      0
    );

  }

  /**
   * Generate the GetRecords query.
   * @param identifier  The harvester identifier
   * @param exchange  The Camel exchange
   * @return The XML query
   */
  public synchronized String generateGetRecordsQuery(
      @ExchangeProperty("harvesterUrl") String identifier,
      Exchange exchange) {
    int page = (Integer) exchange.getProperty("CamelSplitIndex");
    Config config = getConfig(identifier);
    return buildGetRecordsQuery(config.getRecordsFilter(),
      false,
      page * config.getMaxRecords() + 1,
      config.getMaxRecords());
  }

  class Config {
    List<String> pages = new ArrayList<String>();
    private int maxRecords = 20;
    private int startPosition = 1;
    private int numberOfRecordsMatched;
    private Node getRecordsFilter;

    public Config() {}

    public int getMaxRecords() {
      return maxRecords;
    }

    public Config setMaxRecords(int maxRecords) {
      this.maxRecords = maxRecords;
      return this;
    }

    public int getStartPosition() {
      return startPosition;
    }

    public Config setStartPosition(int startPosition) {
      this.startPosition = startPosition;
      return this;
    }

    public int getNumberOfPages() {
      return pages.size();
    }

    public List<String> getPages() {
      return pages;
    }

    public List<String> computeNumberOfPages() {
      int numberOfPages = numberOfRecordsMatched / maxRecords;
      int remainingRecords = numberOfRecordsMatched - (numberOfPages * maxRecords);

      int counter;
      for (counter = 0; counter < numberOfPages; counter++) {
        pages.add(counter + "");
      }

      // Add one more page to collect remaining records
      if (remainingRecords > 0) {
        pages.add(counter++ + "");
      }

      log.info("numberOfRecordsMatched " + numberOfRecordsMatched + ".");
      log.info("maxRecords " + maxRecords + ".");
      log.info("numberOfPages " + pages.size() + ".");
      log.info("numberOfRecordsInLastPage " + remainingRecords + ".");
      return pages;
    }

    public Config setNumberOfRecordsMatched(int numberOfRecordsMatched) {
      this.numberOfRecordsMatched = numberOfRecordsMatched;
      return this;
    }


    public Node getRecordsFilter() {
      return this.getRecordsFilter;
    }

    public Config setRecordsFilter(Node getRecordsFilter) {
      this.getRecordsFilter = getRecordsFilter;
      return this;
    }
  }
}
