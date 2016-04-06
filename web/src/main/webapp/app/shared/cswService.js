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
  var app = angular.module('csw', []);

  app.factory('cswService', ['$http', '$q', 'cfg',
    function ($http, $q, cfg) {
      return {
        getHitsNumber: function (url, filter) {
          var deferred = $q.defer();
          if (filter) {
            filter = filter.match(/.*(<ogc:Filter.*[\s\S]*<\/ogc:Filter>).*/)[1];
          } else {
            filter = '';
          }
          $http({
            method: 'POST',
            url: cfg.SERVICES.proxy + encodeURI(url.trim()),
            data: '<csw:GetRecords '
                  + 'xmlns:csw="http://www.opengis.net/cat/csw/2.0.2" '
                  + 'service="CSW" '
                  + 'resultType="hits" '
                  + 'outputSchema="http://www.isotc211.org/2005/gmd" '
                  + 'version="2.0.2">'
                  + ' <csw:Query typeNames="csw:Record">'
                  + '  <csw:ElementSetName>brief</csw:ElementSetName>'
                  + filter
                  + ' </csw:Query>'
                  + '</csw:GetRecords>',
            headers: { "Content-Type": 'application/xml' }
          }).then(function (response) {
            var nbHits = response.data.match(/numberOfRecordsMatched="([0-9]*)"/)[1];
            deferred.resolve(nbHits)
          }, function (response) {
            deferred.reject(response);
          });
          return deferred.promise;
        }
      };
    }]);
}());
