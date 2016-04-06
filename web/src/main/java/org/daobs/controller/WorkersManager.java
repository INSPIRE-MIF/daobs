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

import org.apache.camel.CamelContext;
import org.apache.camel.spi.InflightRepository;
import org.daobs.workers.ContextStore;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

/**
 * Draft camel workers prototype.
 * <p>
 * Another option could be to use JMX and
 * Jolokia REST Api ?
 * https://jolokia.org/reference/html/index.html
 * </p>
 * Created by francois on 20/01/16.
 */
@Controller
public class WorkersManager {

  @Autowired
  ContextStore camelContextStore;

  /**
   * Get inflight exchanges.
   */
  @RequestMapping(value = "/workers",
      produces = {
        MediaType.APPLICATION_XML_VALUE,
        MediaType.APPLICATION_JSON_VALUE,
        MediaType.APPLICATION_XHTML_XML_VALUE
      },
      method = RequestMethod.GET)
  @ResponseBody
  public List<String> getExchangess() {
    ArrayList<String> result = new ArrayList<>();

    for (CamelContext context : camelContextStore.getCamelContexts()) {
      Collection<InflightRepository.InflightExchange> inFlightExchanges =
          context.getInflightRepository().browse();

      for (InflightRepository.InflightExchange ex : inFlightExchanges) {
        // TODO:
        // * Use Unit Of Work
        // * testing
        //            inFlightExchanges.remove(e);
        //            e.getExchange().setProperty(Exchange.ROUTE_STOP, Boolean.TRUE);
        // http://camel.apache.org/uuidgenerator.html could be customized
        // to have workers id set by starter app.
        result.add(String.format("[%s:%s] %s (%dms/%dms) - step %s - Nb of records: %s",
            ex.getExchange().getUnitOfWork().getOriginalInMessage().getHeader("harvesterUuid"),
            ex.getExchange().getUnitOfWork().getOriginalInMessage().getHeader("harvesterTerritory"),
            ex.getExchange().getExchangeId(),
            ex.getElapsed(),
            ex.getDuration(),
            ex.getExchange().getFromRouteId(),
            ex.getExchange().getUnitOfWork()
              .getOriginalInMessage().getHeader("numberOfRecordsMatched")
        ));
      }
    }
    return result;
  }
}
