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


  app.factory('harvesterService',
    ['$http', '$q', 'cfg',
      function ($http, $q, cfg) {
        return {
          getAll: function () {
            return $http.get(cfg.SERVICES.harvesters + '.json');
          },
          run: function (h) {
            var deferred = $q.defer();
            $http.get(cfg.SERVICES.harvesters + '/' + h.uuid).success(function (data) {
              deferred.resolve(data);
            }).error(function (response) {
              deferred.reject(response);
            });
            return deferred.promise;
          },
          add: function (h) {
            var deferred = $q.defer();
            $http.put(cfg.SERVICES.harvester, h).success(function (data) {
              deferred.resolve(data);
            }).error(function (response) {
              deferred.reject(response);
            });
            return deferred.promise;
          },
          remove: function (h) {
            var deferred = $q.defer();
            $http.delete(cfg.SERVICES.harvesters + '/' + h.uuid).success(function (data) {
              deferred.resolve(data);
            }).error(function (response) {
              deferred.reject(response);
            });
            return deferred.promise;
          },
          removeRecords: function (h) {
            var deferred = $q.defer();

            $http.delete(cfg.SERVICES.harvesters + '/' + h.uuid + '/records').then(
              function (data) {
                deferred.resolve('Records deleted.');
              }, function (response) {
                deferred.reject(response);
              });

            return deferred.promise;
          },
          eftValidation: function (h, all) {
            var query = '+harvesterUuid:' + h.uuid + ' +documentType:metadata +resourceType:service';
            if (!all) {
              query = query + ' -etfValidDate:[* TO *]';
            }

            var deferred = $q.defer();
            $http.get(cfg.SERVICES.eftValidation, {params: {fq: query}}).success(function (data) {
              deferred.resolve(data);
            }).error(function (response) {
              deferred.reject(response);
            });
            return deferred.promise;
          },
          serviceLinker: function (h, all) {
            var query = '+harvesterUuid:' + h.uuid + ' +documentType:metadata +resourceType:service';

            var deferred = $q.defer();
            $http.get(cfg.SERVICES.serviceLinker, {params: {fq: query}}).success(function (data) {
              deferred.resolve(data);
            }).error(function (response) {
              deferred.reject(response);
            });
            return deferred.promise;
          },
          inspireValidation: function (h) {
            var query = '+harvesterUuid:' + h.uuid + ' +documentType:metadata';

            var deferred = $q.defer();
            $http.get(cfg.SERVICES.inspireValidation, {params: {fq: query}}).success(function (data) {
              deferred.resolve(data);
            }).error(function (response) {
              deferred.reject(response);
            });
            return deferred.promise;
          },
          inspireValidationNotValidated: function (h) {
            var query = '+harvesterUuid:' + h.uuid + ' +documentType:metadata -completenessIndicator:[* TO *]';

            var deferred = $q.defer();
            $http.get(cfg.SERVICES.inspireValidation, {params: {fq: query}}).success(function (data) {
              deferred.resolve(data);
            }).error(function (response) {
              deferred.reject(response);
            });
            return deferred.promise;
          }
        };
      }]);
}());
