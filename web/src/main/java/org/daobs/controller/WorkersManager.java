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
import org.apache.camel.CamelContext;
import org.apache.camel.impl.DefaultShutdownStrategy;
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
import java.util.concurrent.TimeUnit;

/**
 * Draft camel workers prototype.
 * <p>
 * Another option could be to use JMX and
 * Jolokia REST Api ?
 * https://jolokia.org/reference/html/index.html
 * </p>
 * Created by francois on 20/01/16.
 */
@Api(value = "monitoring",
    tags = "monitoring",
    description = "System monitoring operations")
@Controller
public class WorkersManager {

  @Autowired
  ContextStore camelContextStore;

  /**
   * Get inflight exchanges.
   */
  @RequestMapping(value = "/activities",
      produces = {
        MediaType.APPLICATION_XML_VALUE,
        MediaType.APPLICATION_JSON_VALUE,
        MediaType.APPLICATION_XHTML_XML_VALUE
      },
      method = RequestMethod.GET)
  @ResponseBody
  public List<String> getExchanges() {
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
        final long millis = ex.getElapsed();
        String time = String.format("%02d min, %02d sec",
          TimeUnit.MILLISECONDS.toMinutes(millis),
                   TimeUnit.MILLISECONDS.toSeconds(millis) -
                   TimeUnit.MINUTES.toSeconds(TimeUnit.MILLISECONDS.toMinutes(millis))
        );
        final long millisDuration = ex.getDuration();
        String timeDuration = String.format("%02d min, %02d sec",
          TimeUnit.MILLISECONDS.toMinutes(millisDuration),
                   TimeUnit.MILLISECONDS.toSeconds(millisDuration) -
                   TimeUnit.MINUTES.toSeconds(TimeUnit.MILLISECONDS.toMinutes(millisDuration))
        );
        result.add(String.format("%s %s for %s (current: %s/ inflight: %s) - step %s - Nb of records: %s",
            ex.getExchange().getExchangeId(),
            ex.getExchange().getContext().getManagementName(),
            ex.getExchange().getUnitOfWork().getOriginalInMessage().getBody(String.class),
            time,
            timeDuration,
            ex.getExchange().getFromRouteId(),
            ex.getExchange().getUnitOfWork()
              .getOriginalInMessage().getHeader("numberOfRecordsMatched")
        ));
      }
    }
    return result;
  }


  /**
   * Get inflight exchanges.
   */
  @RequestMapping(value = "/reload",
      produces = {
        MediaType.APPLICATION_JSON_VALUE
      },
      method = RequestMethod.GET)
  @ResponseBody
  public List<String> reload() {
    ArrayList<String> result = new ArrayList<>();

    result.add("Reloading context");
    for (CamelContext context : camelContextStore.getCamelContexts()) {
      result.add("Processing context " + context.getName());
      try {
        DefaultShutdownStrategy shutdownStrategy = new DefaultShutdownStrategy();
        shutdownStrategy.setTimeout(5); // Force shutdown in 10sec
        shutdownStrategy.setShutdownNowOnTimeout(true);
        shutdownStrategy.shutdown();
        context.setShutdownStrategy(shutdownStrategy);
        context.stop();
        result.add(String.format("  Context status is %s.", context.getStatus()));
        result.add("  Context stopped");

        try {
          context.start();
          result.add("  Context started.");
        } catch (Exception ex) {
          result.add("  Error during startup: " + ex.getMessage());
          ex.printStackTrace();
        }
      } catch (Exception ex) {
        result.add("  Error during stop: " + ex.getMessage());
        ex.printStackTrace();
      }
    }
    return result;
  }
}
