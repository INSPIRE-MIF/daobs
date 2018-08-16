/*
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

(function () {
  "use strict";
  var app = angular.module('daobs');


  app.factory('monitoringService',
    ['$http', '$q', 'cfg',
      function ($http, $q, cfg) {
        return {
          loadMonitoring: function () {
            // TODO: Paging needed
            var rows = 10000, deferred = $q.defer();

            // TODO: Move to solrService
            // $http.get(cfg.SERVICES.dataCore +
            //   '?q=documentType%3Amonitoring&' +
            //   'sort=reportingDate+desc,scope+asc&' +
            //   'start=0&rows=' + rows + '&' +
            //   'facet=true&facet.field=reportingYear&facet.field=scope&' +
            //   'wt=json')
            $http.post(
              cfg.SERVICES.esindicatorCore + '/_search?size=' + rows, {
                "query" : {
                  "bool" : {
                    "filter" : {
                      "term" : {"documentType": "monitoring"}
                    }
                  }
                },
                "sort": [
                  {
                    "scope": {
                      "order": "asc"
                    },
                    "reportingDate": {
                      "order": "desc"
                    }
                  }
                ],
                "aggs": {
                  "reportingYear" : {
                    "terms" : {
                      "field" : "reportingYear",
                      "size": "100"
                    }
                  },
                  "scope": {
                    "terms":  {
                      "field": "scope",
                      "size": "100"
                    }
                  },
                  "reportType": {
                    "terms":  {
                      "field": "report",
                      "size": "100"
                    }
                  }
                }
              }
            ).success(function (data) {
              deferred.resolve({
                monitoring: data.hits.hits,
                facet: data.aggregations
              });
            }).error(function (response) {
              deferred.reject(response);
            });

            return deferred.promise;
          },
          /**
           * Upload a monitoring.
           *
           * @param file
           * @param isOfficial Flag the monitoring as an official one
           * @param withRowData Index also row data section
           *  (only applies to INSPIRE monitoring)
           * @returns Array of promise
           */
          uploadMonitoring: function (files, isOfficial, withRowData) {
            var listOfDeffered = [];

            angular.forEach(files, function (file) {
              var deferred = $q.defer();
              var fd = new FormData();
              fd.append('file', file);

              $http.post(cfg.SERVICES.reports, fd, {
                transformRequest: angular.identity,
                headers: {'Content-Type': undefined}
              }).success(function (data) {
                deferred.resolve(data);
              }).error(function (data) {
                deferred.reject(data);
              });

              listOfDeffered.push({file: file, promise: deferred.promise});
            });
            return listOfDeffered;
          },
          /**
           * Remove monitoring and related indicators.
           *
           * @param m MUST contains a reportingDate and scope which
           * is applied as filter. If undefined, all monitoring and
           * indicators are removed.
           *
           * @returns {*}
           */
          removeMonitoring: function (m) {
            // Remove indicator
            var filter = m === undefined ? '' :
              '+reportingDate:"' + m.reportingDate + '" ' +
              '+scope:"' + m.scope + '"',
              indicatorFilter = '+documentType:indicator ' + filter,
              monitoringFilter = '+documentType:monitoring* ' + filter,
              deferred = $q.defer();

            $http.delete(cfg.SERVICES.reports + '?query=' +
                         encodeURIComponent(indicatorFilter)).then(
              function () {
                // Remove monitoring
                $http.delete(cfg.SERVICES.reports + '?query=' +
                             encodeURIComponent(monitoringFilter)).then(
                  function (data) {
                    deferred.resolve('Monitoring deleted.');
                  },
                  function (response) {
                    deferred.reject(response);
                  });
              }
            );

            return deferred.promise;
          }
        };
      }]);
}());
