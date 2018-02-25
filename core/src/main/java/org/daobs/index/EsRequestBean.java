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

package org.daobs.index;

import com.sun.org.apache.xerces.internal.dom.DocumentImpl;
import org.apache.commons.codec.Charsets;
import org.elasticsearch.action.admin.indices.analyze.AnalyzeRequest;
import org.elasticsearch.action.admin.indices.analyze.AnalyzeResponse;
import org.elasticsearch.action.bulk.BulkRequestBuilder;
import org.elasticsearch.action.bulk.BulkResponse;
import org.elasticsearch.action.delete.DeleteRequest;
import org.elasticsearch.action.fieldstats.FieldStatsResponse;
import org.elasticsearch.action.search.SearchRequestBuilder;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.action.update.UpdateRequestBuilder;
import org.elasticsearch.action.update.UpdateResponse;
import org.elasticsearch.common.unit.TimeValue;
import org.elasticsearch.common.xcontent.NamedXContentRegistry;
import org.elasticsearch.common.xcontent.XContentBuilder;
import org.elasticsearch.common.xcontent.XContentFactory;
import org.elasticsearch.common.xcontent.XContentParser;
import org.elasticsearch.common.xcontent.XContentType;
import org.elasticsearch.index.query.QueryBuilders;
import org.elasticsearch.search.SearchHit;
import org.elasticsearch.search.SearchHits;
import org.springframework.beans.factory.annotation.Value;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.logging.Logger;


/**
 * Utility class to run Solr requests like field analysis.
 * Created by francois on 30/09/14.
 */
public class EsRequestBean {
  @Value("${es.index.records}")
  private String index;

  public String getIndex() {
    return index;
  }

  public void setIndex(String index) {
    this.index = index;
  }

  private Logger logger = Logger.getLogger("org.daobs.index");

  /**
   * Create an index if not existing.
   *
   */
  public static boolean createIndexIfNotExist(String indexName, String mappingFile) {
    EsClientBean client = EsClientBean.get();
    try {
      boolean exists = client.getClient().admin().indices()
          .prepareExists(indexName)
          .execute().actionGet().isExists();

      if (!exists) {
        Logger.getLogger("org.daobs.index").info(
            String.format("Creating index %s", indexName));
        String json = com.google.common.io.Files.toString(new File(mappingFile), Charsets.UTF_8);
        XContentBuilder builder = XContentFactory.jsonBuilder().prettyPrint();
        try (XContentParser p = XContentFactory
            .xContent(XContentType.JSON)
            .createParser(NamedXContentRegistry.EMPTY, json)) {
          builder.copyCurrentStructure(p);
        }
        client.getClient().admin().indices().prepareCreate(indexName)
            .setSource(builder).get();
        return true;
      }
      return exists;
    } catch (Exception ex) {
      ex.printStackTrace();
      return false;
    }
  }

  /**
   * Delete by query.
   *
   *
   */
  public static String deleteByQuery(String index, String query, int scrollSize) throws Exception {
    EsClientBean client = EsClientBean.get();
    SearchResponse scrollResponse = client.getClient()
        .prepareSearch(index)
        .setQuery(QueryBuilders.queryStringQuery(query))
        .setScroll(new TimeValue(60000))
        .setSize(scrollSize)
        .execute().actionGet();

    BulkRequestBuilder brb = client.getClient().prepareBulk();
    while (true) {
      for (SearchHit hit : scrollResponse.getHits()) {
        brb.add(new DeleteRequest(index, hit.getType(), hit.getId()));
      }
      scrollResponse = client.getClient()
          .prepareSearchScroll(scrollResponse.getScrollId())
          .setScroll(new TimeValue(60000))
          .execute().actionGet();
      if (scrollResponse.getHits().getHits().length == 0) {
        break;
      }
    }

    if (brb.numberOfActions() > 0) {
      BulkResponse result = brb.execute().actionGet();
      if (result.hasFailures()) {
        throw new IOException(result.buildFailureMessage());
      } else {
        return String.format(
          "{\"msg\": \"%d records removed.\"}", brb.numberOfActions());
      }
    }
    return String.format("{\"msg\": \"No match found for query '%s'.\"}", query);
  }


  /**
   * Query index over HTTP and return node.
   */
  public static Node query(String collection, String[] fields,
                           String query, int rows) throws Exception {
    EsClientBean client = EsClientBean.get();
    // TODO: Use the scroll API for large set
    SearchRequestBuilder srb = client.getClient().prepareSearch(collection)
        .setQuery(QueryBuilders.queryStringQuery(query));

    if (fields != null) {
      srb.setFetchSource(fields, null);
    }

    SearchResponse searchResponse = srb
        .setFrom(0)
        .setSize(rows)
        .execute().actionGet();

    return searchResponseToNode(searchResponse.getHits());
  }

  @Deprecated
  public static Node query(String[] fields, String query, int rows) throws Exception {
    EsClientBean client = EsClientBean.get();
    return query(client.getDefaultIndex(), fields, query, rows);
  }

  /**
   * Query index and return SearchResponse.
   */
  public static SearchResponse search(String collection, String[] fields,
                                     String query, int rows) throws Exception {
    EsClientBean client = EsClientBean.get();
    // TODO: Use the scroll API for large set
    SearchRequestBuilder srb = client.getClient().prepareSearch(collection)
        .setQuery(QueryBuilders.queryStringQuery(query));

    if (fields != null) {
      srb.setFetchSource(fields, null);
    }

    return srb
        .setFrom(0)
        .setSize(rows)
        .execute().actionGet();
  }

  /**
   * Update a document.
   */
  public static UpdateResponse update(String collection,
                                      String id,
                                      XContentBuilder source
                                      ) throws Exception {
    EsClientBean client = EsClientBean.get();
    UpdateRequestBuilder urb = client.getClient().prepareUpdate()
        .setIndex(collection)
        .setType(collection)
        .setId(id)
        .setDoc(source);

    return urb.execute().actionGet();
  }



  /**
   * Convert search response to node.
   *
   */
  public static Node searchResponseToNode(SearchHits hits) {
    Document xmlDoc = new DocumentImpl();
    Element response = xmlDoc.createElement("result");
    List<String> booleanFields = new ArrayList<>();
    booleanFields.add("isAboveThreshold");
    booleanFields.add("inspireConformResource");

    List<String> arrayFields = new ArrayList<>();
    arrayFields.add("inspireTheme");
    arrayFields.add("serviceType");
    arrayFields.add("recordOperatedByType");
    arrayFields.add("recordOperatedByTypeview");
    arrayFields.add("recordOperatedByTypedownload");
    arrayFields.add("link");
    arrayFields.add("linkUrl");
    arrayFields.add("custodianOrgForResource");
    arrayFields.add("ownerOrgForResource");
    arrayFields.add("pointOfContactOrgForResource");
    arrayFields.add("OrgForResource");
    arrayFields.add("inspireConformResource");
    for (SearchHit h : hits.getHits()) {
      Node doc = xmlDoc.createElement("doc");
      Iterator<String> iterator = h.getSource().keySet().iterator();
      while (iterator.hasNext()) {
        String key = iterator.next();
        Object values = h.getSource().get(key);

        boolean isArray = arrayFields.contains(key);
        boolean isBoolean = booleanFields.contains(key);
        Element field = xmlDoc.createElement(isArray ? "arr" : (isBoolean ?  "bool" : "str"));

        field.setAttribute("name", key);
        if (isArray) {
          if (values instanceof ArrayList) {
            Iterator<String> valuesIterator = ((ArrayList<String>) values).iterator();
            while (valuesIterator.hasNext()) {
              Object o = valuesIterator.next();
              if (o instanceof String) {
                Element arrayElement = xmlDoc.createElement(isBoolean ? "bool" : "str");
                arrayElement.setTextContent((String) o);
                field.appendChild(arrayElement);
              } else if (o instanceof ArrayList) {
                ((ArrayList) o).forEach(e -> {
                  Element arrayElement = xmlDoc.createElement(isBoolean ? "bool" : "str");
                  arrayElement.setTextContent((String) e);
                  field.appendChild(arrayElement);
                });
              }
            }
          } else {
            Element arrayElement = xmlDoc.createElement(isBoolean ?  "bool" : "str");
            arrayElement.setTextContent(values.toString());
            field.appendChild(arrayElement);
          }
        } else {
          field.setTextContent(values.toString());
        }
        doc.appendChild(field);
      }
      response.appendChild(doc);
    }
    return response;
  }

  /**
   * Return the number of rows matching the query.
   *
   * @param query The query
   */
  public static Double getNumFound(String collection, String query, String... filterQuery) {
    try {
      EsClientBean client = EsClientBean.get();
      SearchRequestBuilder srb = client.getClient()
          .prepareSearch(collection == null ? client.getDefaultIndex() : collection)
          .setQuery(QueryBuilders.queryStringQuery(query));

      if (filterQuery != null) {
        String filters = "";
        for (String filter : filterQuery) {
          filters = filter + " ";
        }
        srb.setPostFilter(QueryBuilders.queryStringQuery(filters));
      }
      SearchResponse response = srb.setFrom(0)
          .setSize(0)
          .setExplain(true)
          .execute()
          .actionGet();

      return (double) response.getHits().getTotalHits();
    } catch (Exception exception) {
      exception.printStackTrace();
    }
    return null;
  }

  @Deprecated
  public static Double getNumFound(String query, String... filterQuery) {
    EsClientBean client = EsClientBean.get();
    return getNumFound(client.getDefaultIndex(), query, filterQuery);
  }

  /**
   * Get stats for a field.
   */
  public static Double getStats(
      String collection, String query,
      String[] filterQuery, String statsField, String stats) {

    EsClientBean client = EsClientBean.get();
    try {
      FieldStatsResponse response = client.getClient()
          .prepareFieldStats()
          .setFields(statsField)
          .setIndices(collection == null ? client.getDefaultIndex() : collection)
          //        .setQuery(QueryBuilders.queryStringQuery(query))
          //        .setPostFilter(QueryBuilders.simpleQueryStringQuery(filterQuery[0]))
          .execute()
          .actionGet();
      // TODO: Subset to filter - We should probably use aggregates

      // TODO: Return correct stat info
      return (double)response.getAllFieldStats().get(statsField).getMaxValue();
    } catch (Exception ex) {
      ex.printStackTrace();
    }

    //        if ("min".equals(stats)) {
    //          return (Double) fieldStatsInfo.getMin();
    //        } else if ("max".equals(stats)) {
    //          return (Double) fieldStatsInfo.getMax();
    //        } else if ("count".equals(stats)) {
    //          return fieldStatsInfo.getCount().doubleValue();
    //        } else if ("missing".equals(stats)) {
    //          return fieldStatsInfo.getMissing().doubleValue();
    //        } else if ("mean".equals(stats)) {
    //          return (Double) fieldStatsInfo.getMean();
    //        } else if ("sum".equals(stats)) {
    //          return (Double) fieldStatsInfo.getSum();
    //        } else if ("stddev".equals(stats)) {
    //          return fieldStatsInfo.getStddev();
    //        } else if ("countDistinct".equals(stats)) {
    //          return fieldStatsInfo.getCountDistinct().doubleValue();
    //        }
    return null;
  }

  @Deprecated
  public static Double getStats(String query, String[] filterQuery,
                                String statsField, String stats) {
    EsClientBean client = EsClientBean.get();
    return getStats(client.getDefaultIndex(), query, filterQuery, statsField, stats);
  }

  /**
   * Analyze a field and a value against the index
   * or query phase and return the first value generated
   * by the specified filterClass.
   * <p>
   * If an exception occured, the field value is returned.
   *
   * TODO: Logger.
   * </p>
   * @param fieldValue    The field value to analyze
   *
   * @return The analyzed string value if found or the field value if not found.
   */
  public static String analyzeField(String collection,
                             String analyzer,
                             String fieldValue) {

    EsClientBean client = EsClientBean.get();
    AnalyzeRequest request = (new AnalyzeRequest(
        collection == null ? client.getDefaultIndex() : collection)
        .text(fieldValue.replaceAll(",", ""))).analyzer(analyzer);
    try {
      List<AnalyzeResponse.AnalyzeToken> tokens =
          client.getClient()
              .admin().indices()
              .analyze(request)
              .actionGet().getTokens();
      Iterator<AnalyzeResponse.AnalyzeToken> iterator = tokens.iterator();
      while (iterator.hasNext()) {
        AnalyzeResponse.AnalyzeToken token = iterator.next();
        if (token.getType().equals("SYNONYM") || token.getType().equals("word")) {
          return token.getTerm();
        }
      }
    } catch (Exception ex) {
      return fieldValue;
    }

    return null;
  }

  /**
   * Still used in some XSLT.
   */
  @Deprecated
  public static String analyzeField(String fieldName,
                                    String fieldValue) {
    EsClientBean client = EsClientBean.get();
    return analyzeField(client.getDefaultIndex(), fieldName, fieldValue);
  }
}
