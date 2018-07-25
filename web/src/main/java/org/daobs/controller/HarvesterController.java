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

package org.daobs.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.apache.commons.io.FileUtils;
import org.daobs.event.HarvestCswEvent;
import org.daobs.harvester.config.Harvester;
import org.daobs.harvester.config.Harvesters;
import org.daobs.harvester.repository.HarvesterConfigRepository;
import org.daobs.index.EsRequestBean;
import org.daobs.messaging.JmsMessager;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationContext;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import java.util.ArrayList;


/**
 * Created by francois on 21/10/14.
 */
@Api(value = "harvesting",
    tags = "harvesting",
    description = "Harvesting operations")
@Controller
public class HarvesterController {

  @Autowired
  HarvesterConfigRepository harvesterConfigRepository;

  @Value("${reports.dir}")
  private String reportsPath;

  @Value("${es.scrollSize}")
  private int scrollSize;


  @ApiOperation(value = "Get harvesters",
      nickname = "get")
  @RequestMapping(value = "/harvesters",
      produces = {
        MediaType.APPLICATION_XML_VALUE,
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.GET)
  @ResponseBody
  public Harvesters get()
      throws IOException {
    return harvesterConfigRepository.getAll();
  }

  // TODO: Should have one PUT method with one or more harvester in input
  @ApiOperation(value = "Add or update harvester",
      nickname = "add")
  @RequestMapping(value = "/harvester",
      produces = {
        MediaType.APPLICATION_XML_VALUE,
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.PUT)
  @ResponseBody
  public RequestResponse addOrUpdate(@RequestBody Harvester harvester)
      throws Exception {
    harvesterConfigRepository.addOrUpdate(harvester);
    return new RequestResponse("Harvester added", "success");
  }

  /**
   * Load a set of harvesters.
   */
  @ApiOperation(value = "Add or update a set of harvesters",
      nickname = "addAll")
  @RequestMapping(value = "/harvesters",
      produces = {
        MediaType.APPLICATION_XML_VALUE,
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.PUT)
  @ResponseBody
  public RequestResponse addOrUpdateAll(@RequestBody Harvesters harvesters)
      throws Exception {
    for (Harvester harvester : harvesters.getHarvester()) {
      harvesterConfigRepository.addOrUpdate(harvester);
    }
    return new RequestResponse(String.format(
        "%d harvester added", harvesters.getHarvester().size()
      ), "success");
  }

  /**
   * Remove harvester.
   */
  @ApiOperation(value = "Remove harvester",
      nickname = "delete")
  @RequestMapping(value = "/harvesters/{uuid}",
      produces = {
        MediaType.APPLICATION_XML_VALUE,
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.DELETE)
  @ResponseBody
  public RequestResponse remove(
      @PathVariable(value = "uuid") String harvesterUuid
  ) throws Exception {

    removeRecords(harvesterUuid);

    harvesterConfigRepository.remove(harvesterUuid);

    return new RequestResponse("Harvester and its records removed", "success");
  }

  /**
   * Remove harvester records.
   */
  @ApiOperation(value = "Remove harvester records",
      nickname = "deleteHarvesterRecords")
  @RequestMapping(value = "/harvesters/{uuid}/records",
      produces = {
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.DELETE)
  @ResponseBody
  public RequestResponse delete(
      @PathVariable final String uuid) throws Exception {

    removeRecords(uuid);

    return new RequestResponse("Harvester records removed", "success");
  }

  private void removeRecords(@PathVariable String uuid) throws Exception {
    String message = null;
    try {
      String query = String.format(
          "+harvesterUuid:\"%s\" +(documentType:metadata documentType:association)",
          uuid.trim()
      );
      message = EsRequestBean.deleteByQuery("records", query, scrollSize);
    } catch (Exception ex) {
      ex.printStackTrace();
    }

    // Delete the ETF reports
    String harvesterReportsPath = Paths.get(this.reportsPath,
        uuid).toString();

    FileUtils.deleteQuietly(new File(harvesterReportsPath));
  }

  @ApiOperation(value = "Run harvester (deprecated)",
      nickname = "runDeprecated")
  @RequestMapping(value = "/harvesters/{uuid}/deprecated",
      produces = {
        MediaType.APPLICATION_XML_VALUE,
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.GET)
  @ResponseBody
  @Deprecated
  public RequestResponse run(@PathVariable(value = "uuid") String harvesterUuid,
                             @RequestParam(
                               value = "action",
                               required = false) String action
  )
      throws Exception {
    harvesterConfigRepository.start(harvesterUuid);
    return new RequestResponse("Harvester started", "success");
  }

  @Autowired
  private JmsMessager jmsMessager;

  @Autowired
  private ApplicationContext appContext;

  /**
   * Start harvester by sending JMS message.
   */
  @ApiOperation(value = "Run harvester",
      nickname = "run")
  @RequestMapping(value = "/harvesters/{uuid}",
      produces = {
        MediaType.APPLICATION_XML_VALUE,
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.GET)
  @ResponseBody
  public RequestResponse runJms(@PathVariable(value = "uuid") String harvesterUuid)
      throws Exception {
    jmsMessager.sendMessage(
        "harvest-csw",
        new HarvestCswEvent(
            appContext,
            harvesterConfigRepository.findByUuid(harvesterUuid)
        )
    );
    return new RequestResponse("Harvester started", "success");
  }

}
