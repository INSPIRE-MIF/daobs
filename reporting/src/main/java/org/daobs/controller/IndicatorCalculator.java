/**
 * Copyright 2014-2016 European Environment Agency <p> Licensed under the EUPL, Version 1.1 or – as
 * soon they will be approved by the European Commission - subsequent versions of the EUPL (the
 * "Licence"); You may not use this work except in compliance with the Licence. You may obtain a
 * copy of the Licence at: <p> https://joinup.ec.europa.eu/community/eupl/og_page/eupl <p> Unless
 * required by applicable law or agreed to in writing, software distributed under the Licence is
 * distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied. See the Licence for the specific language governing permissions and limitations under
 * the Licence.
 */

package org.daobs.controller;

import org.daobs.indicator.config.Reporting;

import java.io.FileNotFoundException;
import java.util.Map;

/**
 * Created by francois on 17/10/14.
 */
public interface IndicatorCalculator {
  /**
   * Load or reload the configuration.
   *
   */
  public IndicatorCalculator loadConfig() throws FileNotFoundException;

  Reporting getConfiguration();

  public Double get(String indicatorName);

  /**
   * Compute indicators.
   *
   */
  public IndicatorCalculator computeIndicators(String... filterQuery);

  Map<String, Double> getResults();
}
