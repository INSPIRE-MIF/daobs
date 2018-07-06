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

  app.config(['$routeProvider', 'cfg',
    function ($routeProvider, cfg) {
      $routeProvider.when('/harvesting', {
        templateUrl: cfg.SERVICES.root +
        'app/components/harvester/harvesterView.html'
      }).when('/harvesting/:section', {
        templateUrl: cfg.SERVICES.root +
        'app/components/harvester/harvesterView.html'
      });
    }]);

  app.controller('HarvesterCtrl', ['$scope', '$routeParams', 'userService',
    function ($scope, $routeParams, userService) {
      var defaultSection = 'manage';

      var privateSections = [
        'monitor'
      ];

      if (privateSections.indexOf($routeParams.section) === -1) {
        $scope.section = $routeParams.section || defaultSection;
      } else {
        var user = userService.getUser();
        if (user && user.authenticated) {
          $scope.section = $routeParams.section;
        } else {
          $scope.section = defaultSection;
        }
      }

      $scope.isActive = function (hash) {
        return location.hash.indexOf("#/" + hash) === 0
          && location.hash.indexOf("#/" + hash + "/") !== 0;
      }
    }]);

  app.controller('HarvesterConfigCtrl', [
    '$scope', '$routeParams', '$translate', '$timeout', '$http', '$location',
    'harvesterService', 'cfg', 'Notification', 'cswService', '$filter', 'userService',
    function ($scope, $routeParams, $translate, $timeout, $http, $location,
              harvesterService, cfg, Notification, cswService, $filter, userService) {
      $scope.harvesterConfig = null;
      $scope.pollingInterval = '10s';
      $scope.adding = false;
      $scope.harvesterTpl = {
        scope: null,
        name: null,
        url: null,
        filter: null,
        folder: null,
        pointOfTruthURLPattern: null,
        serviceMetadata: null,
        nbOfRecordsPerPage: null,
        uuid: null
      };
      $scope.newHarvester = $scope.harvesterTpl;

      $scope.translations = null;
      $translate(['errorRemovingHarvester',
        'errorRemovingHarvesterRecords',
        'harvesterStarted',
        'harvesterDeleted',
        'harvesterSaved',
        'errorGettingRemoteHits',
        'errorAddingHarvester',
        'harvesterRecordsDeleted',
        'errorStartingHarvester',
        'eftValidationStarted',
        'errorStartingEftValidation']).then(function (translations) {
        $scope.translations = translations;
      });

      $scope.statsForScope = {};
      $scope.statsForRemote = {};

      function loadStatsForScope() {
        if ($location.path().indexOf('/harvesting/manage') === 0) {
          var statsField = ['isValid', 'etfIsValid'], statsFieldConfig = [];
          for (var i = 0; i < statsField.length; i++) {
            statsFieldConfig.push(statsField[i] + ": { type : terms, " +
              "field: " + statsField[i] + ", missing: true }");
          }
          $http.post(
            cfg.SERVICES.esdataCore + '/_search?size=0', {
              "query" : {
                "query_string": {
                  "query": "+documentType:metadata"
                }
              },
              "aggs": {
                "top_scope": {
                  "terms":  {
                    "field": "harvesterUuid",
                    "size": "1000"
                  },
                  "aggs" : {
                    "isValid": {
                      "terms": {
                        "field": "isValid"
                      }
                    },
                    "etfIsValid": {
                      "terms": {
                        "field": "etfIsValid"
                      }
                    },
                    "isValidMissing": {
                      "missing" : { "field" : "isValid" }
                    },
                    "isAboveThreshold": {
                      "terms": {
                        "field": "isAboveThreshold"
                      }
                    },
                    "isAboveThresholdMissing": {
                      "missing" : { "field" : "isAboveThreshold" }
                    },
                  }
                }
              }
            }
          ).then(function (r) {
            if (r.data.aggregations.top_scope && r.data.aggregations.top_scope.buckets) {
              var facets = r.data.aggregations.top_scope.buckets;
              for (var i = 0; i < facets.length; i++) {
                $scope.statsForScope[facets[i].key] = {
                  count: facets[i].doc_count,
                  isValid: facets[i].isAboveThreshold
                };
              }
            }
          });
        }
        $timeout(function () {
          loadStatsForScope()
        }, 10000);
      };

      $scope.loading = false;
      function init() {
        $scope.loading = true;
        $scope.statsForScope = {};
        harvesterService.getAll().success(function (list) {
          $scope.loading = false;
          $scope.harvesterConfig = list.harvester;
          if (list.harvester.length > 0) {
            loadStatsForScope();
          }
        });
      }
      $scope.orderByFields = ['name', 'scope', 'url', 'count', 'remoteError'];
      $scope.predicate = 'scope';
      $scope.order = function (predicate, reverse) {
        var isNewPredicate = $scope.predicate === predicate;

        if (predicate === 'count') {
          $scope.predicate = function (h) {
            return $scope.statsForScope[h.uuid] &&
                    $scope.statsForScope[h.uuid].count;
          };
        } else if (predicate === 'remoteError') {
          $scope.predicate = function (h) {
            return $scope.statsForRemote[h.uuid] &&
                    $scope.statsForRemote[h.uuid].error;
          };
        } else {
          $scope.predicate = predicate;
        }
        $scope.reverse = reverse ? reverse : (
          isNewPredicate ? !$scope.reverse : false);
      }

      $scope.getHitsNumber = function (h) {
        if (h) {
          getHitsNumber(h);
        } else {
          // TODO: This could send a huge number of requests.
          // TODO: Improve, eg. turn off regular check
          angular.forEach($scope.harvesterConfig, function (h) {
            getHitsNumber(h);
          });
        }
      };
      function getHitsNumber (h) {
        $scope.statsForRemote[h.uuid] = {};
        cswService.getHitsNumber(h.url, h.filter).then(function (nbHits) {
          $scope.statsForRemote[h.uuid] = {
            count: nbHits,
            when: new Date()
          };
        }, function (response) {
          Notification.error(
            $scope.translations.errorGettingRemoteHits + ' ' +
            (response.error || response.data) +
            ' (' + response.status + ').');
          $scope.statsForRemote[h.uuid] = {
            error: (response.error || response.data) +
                   '(' + response.status + ')',
            when: new Date()
          };
        });
      };

      $scope.startAdding = function() {
        $scope.adding = true;
      }

      $scope.edit = function (h) {
        $scope.adding = true;
        $scope.newHarvester = h;
        $('body').scrollTop(0);
      }

      $scope.add = function () {
        harvesterService.add($scope.newHarvester).then(function (response) {
          $scope.adding = false;
          Notification.success($scope.translations.harvesterSaved);
          init();
          $scope.newHarvester = $scope.harvesterTpl;
        }, function (response) {
          Notification.error(
            $scope.translations.errorAddingHarvester + ' ' +
            response.message);
        });
      };

      $scope.run = function (h) {
        var user = userService.getUser();
        if (!user || !user.authenticated) {
          return;
        }
        harvesterService.run(h).then(function () {
          Notification.success(
            $filter('translate')('harvesterStarted',
                       {name: h.name}));
        }, function (response) {
          Notification.error(
            $scope.translations.errorStartingHarvester + ' ' +
            response);
        });
      };
      $scope.runAll = function () {
        var user = userService.getUser();
        if (!user || !user.authenticated) {
          return;
        }
        angular.forEach($scope.harvesterConfig, function (h) {
          $scope.run(h);
        });
      };

      $scope.remove = function (h, quiet) {
        var user = userService.getUser();
        if (!user || !user.authenticated) {
          return;
        }
        harvesterService.remove(h).then(function (response) {
          Notification.success(
            $filter('translate')('harvesterDeleted',
                                 {name: h.name}));
          if (quiet === true) {
            init();
          }
        }, function (response) {
          Notification.error(
            $scope.translations.errorRemovingHarvester + ' ' +
            response.error.msg);
        });
      };

      $scope.removeAll = function () {
        var user = userService.getUser();
        if (!user || !user.authenticated) {
          return;
        }
        angular.forEach($scope.harvesterConfig, function (h) {
          $scope.remove(h, true);
        });
        init();
      };

      $scope.removeRecords = function (h) {
        harvesterService.removeRecords(h).then(function (response) {
          Notification.success($scope.translations.harvesterRecordsDeleted);
          init();
        }, function (response) {
          console.error(response);
          Notification.error(
            $scope.translations.errorRemovingHarvesterRecords + ' ' +
            response.error.msg);
        })
      };

      $scope.eftValidation = function (h, all) {
        harvesterService.eftValidation(h, all).then(function (response) {
          Notification.success($scope.translations.eftValidationStarted);
          init();
        }, function (response) {
          Notification.error(
            $scope.translations.errorStartingEftValidation + ' ' +
            response.error.msg);
        });
      };
      $scope.serviceLinker = function (h, all) {
        harvesterService.serviceLinker(h, all).then(function (response) {
          Notification.success($scope.translations.serviceLinkerStarted);
          init();
        }, function (response) {
          Notification.error(
            $scope.translations.errorStartingServiceLinker + ' ' +
            response.error.msg);
        });
      };
      $scope.inspireValidation = function (h, all) {
        harvesterService.inspireValidation(h).then(function (response) {
          Notification.success($scope.translations.inspireValidationStarted);
          init();
        }, function (response) {
          Notification.error(
            $scope.translations.errorStartingInspireValidation + ' ' +
            response.error.msg);
        });
      };
      $scope.inspireValidationNotValidated = function (h, all) {
        harvesterService.inspireValidationNotValidated(h).then(function (response) {
          Notification.success($scope.translations.inspireValidationStarted);
          init();
        }, function (response) {
          Notification.error(
            $scope.translations.errorStartingInspireValidation + ' ' +
            response.error.msg);
        });
      };

      init();
    }]);


  app.controller('WorkersMonitorCtrl', [
    '$scope', '$timeout', '$http', '$location', 'cfg',
    function ($scope, $timeout, $http, $location, cfg) {

      function load() {
        if ($location.path().indexOf('/harvesting/monitor') === 0) {
          $http.get(
            cfg.SERVICES.workersStats
          ).then(function (response) {
            $scope.workersStats = response.data;
          });
        }
        $timeout(function () {
          load()
        }, 5000);
      };

      load()
    }]);
}());
