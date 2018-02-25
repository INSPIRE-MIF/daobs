/**
 * Copyright 2014-2018 European Environment Agency
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

package org.daobs.tasks;

import static org.elasticsearch.common.xcontent.XContentFactory.jsonBuilder;

import com.google.common.base.Joiner;

import org.apache.camel.Exchange;
import org.apache.camel.Header;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.daobs.index.EsRequestBean;

import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.action.update.UpdateResponse;
import org.elasticsearch.common.xcontent.XContentBuilder;
import org.elasticsearch.search.SearchHit;

import org.springframework.beans.factory.annotation.Value;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;


public class ServiceDatasetAnalyzer {
  private Log log = LogFactory.getLog(this.getClass());

  private static final int ROWS = 10000;

  @Value("${task.service-dataset-indexer.fields}")
  private String serviceSource;

  public String getServiceSource() {
    return serviceSource;
  }

  public void setServiceSource(String serviceSource) {
    this.serviceSource = serviceSource;
  }


  @Value("${es.index.records}")
  private String index;

  public String getIndex() {
    return index;
  }

  public void setIndex(String index) {
    this.index = index;
  }


  private class DatasetsOperatedByTypes {
    public Set<String> serviceTypes = new HashSet<>();
    public Map<String, String> serviceList = new HashMap<String, String>();
  }

  /**
   * Analyze a set of service records.
   *
   */
  public void linkServiceAndDatasets(
      @Header("documentFilter") String documentFilter,
      Exchange exchange) {

    // TODO: improve. Document filter may contain JSON escaped chars
    documentFilter = documentFilter.replace("\\", "");
    Map<String, DatasetsOperatedByTypes> datasetsOperatedByTypes =
        new HashMap<String, DatasetsOperatedByTypes>();

    System.out.println(String.format(
        "Analyzing service/dataset relation for %s ...", documentFilter));

    // Search all matching services
    try {
      String[] fields = new String[]{
          "id", "recordOperateOn", "serviceType", "harvesterId", "inspireTheme"
      };
      String[] dsFields = new String[]{
          "id", "inspireTheme"
      };
      SearchResponse listOfServices =
          EsRequestBean.search(index, fields, documentFilter, ROWS);

      final Iterator<SearchHit> searchHitIterator =
          listOfServices.getHits().iterator();

      System.out.println(String.format(
          "  Found %d service records to analyze.",
          listOfServices.getHits().totalHits));

      while (searchHitIterator.hasNext()) {
        final SearchHit service = searchHitIterator.next();
        final String serviceId = service.getId();

        System.out.println(String.format(
            "  Analyzing service %s.", serviceId));

        // For each datasets associated with the service
        // collect the INSPIRE themes from the datasets
        // and assign them to the service.
        // _source_include=inspire*
        Set<String> allInspireThemes = new HashSet<String>();
        // First add those from the service
        Object serviceInspireTheme = service.getSource().get("inspireTheme");
        if (serviceInspireTheme != null) {
          if (serviceInspireTheme instanceof ArrayList) {
            allInspireThemes.addAll((ArrayList) serviceInspireTheme);
          } else if (serviceInspireTheme instanceof String) {
            allInspireThemes.add((String) serviceInspireTheme);
          }
        }

        System.out.println(String.format(
            "  INSPIRE themes from service %s are %s.",
            serviceId, allInspireThemes.toString()));

        // Then add those from the datasets
        final Object datasetsObj = service.getSource().get("recordOperateOn");
        // No dataset related to that service
        if (datasetsObj == null) {
          System.out.println(String.format(
              "  No dataset associated to service %s. Nothing to do.",
              serviceId));
        } else {

          List<String> datasets = new ArrayList<>();
          if (datasetsObj instanceof String) {
            datasets.add((String) datasetsObj);
          } else if (datasetsObj instanceof ArrayList) {
            datasets.addAll((ArrayList) datasetsObj);
          }
          final String queryDatasets =
              String.format(
                "+metadataIdentifier:(\"%s\")",
                Joiner.on("\" or \"").join(datasets));

          System.out.println(String.format(
              "  Related datasets for %s are %s.",
              serviceId, datasets));

          SearchResponse listOfdatasets =
              EsRequestBean.search(index, dsFields, queryDatasets, ROWS);

          final Iterator<SearchHit> dsHitIterator =
              listOfdatasets.getHits().iterator();

          while (dsHitIterator.hasNext()) {
            final SearchHit dataset = dsHitIterator.next();
            final Object dsInspireThemes = dataset.getSource().get("inspireTheme");
            if (dsInspireThemes != null) {
              if (dsInspireThemes instanceof ArrayList) {
                allInspireThemes.addAll((ArrayList) dsInspireThemes);
              } else if (dsInspireThemes instanceof String) {
                allInspireThemes.add((String) dsInspireThemes);
              }
            }
          }

          System.out.println(String.format(
              "  INSPIRE themes from service %s and all related datasets are %s.",
              serviceId, allInspireThemes.toString()));


          // For each services, check all related datasets
          // registered in the recordOperateOn field
          // in order to indicate for those datasets that
          // they are operated by the service.
          final Object serviceTypes = service.getSource().get("serviceType");
          if (serviceTypes != null) {
            final Iterator<String> datasetIterator = datasets.iterator();
            while (datasetIterator.hasNext()) {
              final String datasetUuid = datasetIterator.next();

              List allServiceTypes = new ArrayList<>();
              if (serviceTypes instanceof String) {
                allServiceTypes.add(serviceTypes);
              } else if (serviceTypes instanceof ArrayList) {
                allServiceTypes = (ArrayList) serviceTypes;
              }
              allServiceTypes.forEach(e -> {
                datasetOperatedBy(
                    datasetsOperatedByTypes,
                    datasetUuid,
                    (String) e,
                    serviceId);
              });
            }
          }


          // Update the service field INSPIRE themes.
          XContentBuilder source = jsonBuilder().startObject()
              .array("inspireTheme", allInspireThemes.toArray())
              .endObject();
          UpdateResponse response = EsRequestBean.update(index, serviceId, source);

          System.out.println(String.format(
              "  Updated service %s INSPIRE theme %s.",
              serviceId, response.toString()));
        }
      }

      // Update all datasets service types once all services have been processed
      Iterator<String> datasetsUuidIterator = datasetsOperatedByTypes.keySet().iterator();
      while (datasetsUuidIterator.hasNext()) {
        String uuid = datasetsUuidIterator.next();

        System.out.println(String.format(
            "  Updating dataset %s with service types %s operated by %s.",
            uuid,
            datasetsOperatedByTypes.get(uuid).serviceTypes.toString(),
            datasetsOperatedByTypes.get(uuid).serviceList.keySet().toString()));

        // Update query
        XContentBuilder source = jsonBuilder().startObject()
            .array(
              "recordOperatedByType",
              datasetsOperatedByTypes.get(uuid).serviceTypes.toArray())
            .array(
              "recordOperatedBy",
              datasetsOperatedByTypes.get(uuid).serviceList.keySet().toArray());
        Set<String> viewService = new HashSet<>();
        Set<String> downloadService = new HashSet<>();
        datasetsOperatedByTypes.get(uuid).serviceList.keySet().forEach(e -> {
          String type = datasetsOperatedByTypes.get(uuid).serviceList.get(e);
          if (type.equals("view")) {
            viewService.add(e);
          } else if (type.equals("download")) {
            downloadService.add(e);
          }
        });
        if (viewService.size() > 0) {
          source.array("recordOperatedByTypeview", viewService);

          System.out.println(String.format(
              "  Dataset %s is operated by view services %s.",
              uuid, viewService.toString()));
        }
        if (downloadService.size() > 0) {
          source.array("recordOperatedByTypedownload", downloadService);

          System.out.println(String.format(
              "  Dataset %s is operated by download services %s.",
              uuid, downloadService.toString()));
        }
        source.endObject();
        try {
          UpdateResponse response = EsRequestBean.update(index, uuid, source);

          System.out.println(String.format(
              "  Updated dataset %s service info. Response %s.",
              uuid, response.toString()));
        } catch (Exception updateException) {
          updateException.printStackTrace();
        }
      }
    } catch (Exception ex) {
      ex.printStackTrace();
    }

    exchange.getOut().setBody(exchange.getIn().getBody());
    exchange.getOut().setHeaders(exchange.getIn().getHeaders());
  }

  /**
   * Add a dataset / service link to the info.
   */
  public void datasetOperatedBy(Map<String, DatasetsOperatedByTypes> info,
                                String datasetUuid,
                                String serviceType,
                                String serviceUuid) {
    DatasetsOperatedByTypes datasetInfo = info.get(datasetUuid);
    if (datasetInfo != null) {
      datasetInfo.serviceTypes.add(serviceType);
      datasetInfo.serviceList.put(serviceUuid, serviceType);
    } else {
      DatasetsOperatedByTypes dsInfo = new DatasetsOperatedByTypes();
      dsInfo.serviceTypes.add(serviceType);
      dsInfo.serviceList.put(serviceUuid, serviceType);
      info.put(datasetUuid, dsInfo);
    }
  }
}
