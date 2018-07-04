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

import org.elasticsearch.client.transport.TransportClient;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.common.transport.TransportAddress;
import org.elasticsearch.transport.client.PreBuiltTransportClient;
import org.springframework.beans.factory.InitializingBean;

import java.net.InetAddress;
import java.util.Map;

/**
 * Create a bean providing a connection to ES
 * Created by francois on 30/09/14.
 */
public class EsClientBean implements InitializingBean {

  private static EsClientBean instance;

  private TransportClient client;
  private String serverUrl;
  private String defaultIndex;
  private Map<String, String> indexList;
  private String username;
  private String password;

  private boolean initialized = false;

  public String getServerHost() {
    return esHost;
  }

  public void setServerHost(String serverHost) {
    this.esHost = serverHost;
  }

  public static final String INDEX_CONFIG_FOLDER = "/WEB-INF/index/";

  private String esHost;

  /**
   * Get Solr server.
   * @return Return the bean instance
   */
  public static EsClientBean get() {
    return instance;
  }

  /**
   * The first time this method is called, ping the
   * client to check connection status.
   *
   * @return The index instance.
   */
  public TransportClient getClient() throws Exception {
    return client;
  }

  /**
   * Check if indices exist and create them if not.
   *
   *
   * @param basePath Base location from where loading the index configuration.
   * @return true if all indices built properly.
   */
  public boolean checkIndices(String basePath) {
    if (client != null && !initialized) {

      for (Map.Entry<String, String> e : getIndexList().entrySet()) {
        EsRequestBean.createIndexIfNotExist(
            e.getKey(),
            basePath + INDEX_CONFIG_FOLDER + e.getValue() + ".json");
      }
      initialized = true;
    }
    return initialized;
  }

  /**
   * Connect to the index, ping the client
   * to check connection and set the instance.
   *
   */
  @Override
  public void afterPropertiesSet() throws Exception {
    if (serverUrl != null) {
      Settings settings = Settings.builder()
          .put("client.transport.sniff", false)
          .put("client.transport.ignore_cluster_name", true).build();


      // Set nodes to localhost or docker elasticsearch container
      client = new PreBuiltTransportClient(settings)
          .addTransportAddress(new TransportAddress(
          InetAddress.getByName(esHost), 9300));

      synchronized (EsClientBean.class) {
        instance = this;
      }
    } else {
      throw new Exception(String.format("No index URL defined in %s. "
          + "Check bean configuration.", this.serverUrl));
    }
  }

  /**
   * Return the index URL.
   */
  public String getServerUrl() {
    return serverUrl;
  }

  /**
   * The index URL.
   */
  public EsClientBean setServerUrl(String serverUrl) {
    this.serverUrl = serverUrl;
    return this;
  }

  /**
   * Return index username for credentials.
   */
  public String getUsername() {
    return username;
  }

  /**
   * The index credentials username.
   */
  public EsClientBean setUsername(String username) {
    this.username = username;
    return this;
  }

  /**
   * Return index password for credentials.
   */
  public String getPassword() {
    return password;
  }

  /**
   * The index credentials password.
   */
  public EsClientBean setPassword(String password) {
    this.password = password;
    return this;
  }

  public Map<String, String> getIndexList() {
    return indexList;
  }

  public void setIndexList(Map<String, String> indexList) {
    this.indexList = indexList;
  }

  public String getDefaultIndex() {
    return defaultIndex;
  }

  public void setDefaultIndex(String defaultIndex) {
    this.defaultIndex = defaultIndex;
  }
}
