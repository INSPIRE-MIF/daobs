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
      $routeProvider.when('/monitoring', {
        templateUrl: cfg.SERVICES.root +
        'app/components/monitoring/monitoringView.html'
      }).when('/monitoring/:section', {
        templateUrl: cfg.SERVICES.root +
        'app/components/monitoring/monitoringView.html',
        reloadOnSearch: false
      });
    }]);


  /**
   * Controller displaying reports configuration
   * and generating/exporting report.
   *
   * TODO:
   * * submit report
   */
  app.controller('MonitoringCtrl', ['$scope', '$routeParams', 'userService',
    function ($scope, $routeParams, userService) {
      var privateSections = [
        'create',
        'submit'
      ];
      var defaultSection = 'manage';

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


  /**
   * Controller for general information about
   * current monitoring.
   */
  app.controller('MonitoringInfoCtrl', [
    '$scope', '$http', '$timeout', 'cfg', 'monitoringService',
    function ($scope, $http, $timeout, cfg, monitoringService) {
      $scope.listOfMonitoring = null;
      $scope.monitoringFacet = null;
      $scope.monitoringFilter = {_source: {}};

      var init = function () {
        monitoringService.loadMonitoring().then(function (response) {
          $scope.listOfMonitoring = response.monitoring;
          $scope.monitoringFacet = response.facet;
        });
      };

      $scope.setMonitoringFilter = function (field, value) {
        $scope.monitoringFilter._source[field] = value;
      };

      $scope.removeMonitoring = function (m) {
        // TODO: Handle oops
        monitoringService.removeMonitoring(m).then(
          function () {
            $timeout(function () {
              init();
            }, 1000);
          }
        );
      };

      init();
    }]);

  /**
   * Controller for general information about
   * current monitoring.
   */
  app.controller('MonitoringCreateCtrl', [
    '$scope', '$http', '$location', '$translate',
    'cfg', 'Notification', '$anchorScroll',
    function ($scope, $http, $location, $translate,
              cfg, Notification, $anchorScroll) {

      $scope.translations = null;
      $translate(['monitoringSubmitSuccess']).then(function (translations) {
        $scope.translations = translations;
      });
      $scope.report = null;
      $scope.rules = null;
      $scope.overview = false;
      $scope.reportingConfig = null;
      $scope.listOfScope = [];
      $scope.filterCount = null;
      $scope.fq = null;
      $scope.dateTime = null;
      $scope.date = null;
      $scope.scopeId = null;
      $scope.time = null;
      $scope.disableReportConfiguration = cfg.disableReportConfiguration;

      var buildDate = function(n, o) {
        if (o !== n) {
          $scope.dateTime =
            moment($scope.date).format('YYYY-MM-DD') + 'T' +
            moment($scope.time || moment()).format('HH:mm:ss')
        }
      };
      $scope.$watch('date', buildDate);
      $scope.$watch('time', buildDate);
      $scope.$watch('scope', function(n, o) {
        if (o !== n) {
          $scope.scopeId = n.label;
        }
      });

      $scope.facetValues = {};
      var aggs = {
        "scope": {
          "terms":  {
            "field": "scope",
            "size": "100"
          }
        },
        "harvestedDate": {
          "terms":  {
            "field": "harvestedDate",
            "size": "1000",
            "order" : { "_term" : "desc" }
          }
        },
        "resourceType": {
          "terms":  {
            "field": "resourceType",
            "size": "10"
          }
        },
        "isValid": {
          "terms":  {
            "field": "isValid"
          }
        },
        "OrgForResource": {
          "terms":  {
            "field": "OrgForResource",
            "size": "50"
          }
        },
        "Org": {
          "terms":  {
            "field": "Org",
            "size": "50"
          }
        }
      };

      $scope.listOfLanguages = [
        {code: 'bul', label: 'bul'},
        {code: 'cze', label: 'cze'},
        {code: 'dan', label: 'dan'},
        {code: 'dut', label: 'dut'},
        {code: 'eng', label: 'eng'},
        {code: 'est', label: 'est'},
        {code: 'fin', label: 'fin'},
        {code: 'fre', label: 'fre'},
        {code: 'ger', label: 'ger'},
        {code: 'gre', label: 'gre'},
        {code: 'hrv', label: 'hrv'},
        {code: 'hun', label: 'hun'},
        {code: 'ice', label: 'ice'},
        {code: 'gle', label: 'gle'},
        {code: 'ita', label: 'ita'},
        {code: 'lav', label: 'lav'},
        {code: 'lit', label: 'lit'},
        {code: 'mlt', label: 'mlt'},
        {code: 'nor', label: 'nor'},
        {code: 'pol', label: 'pol'},
        {code: 'por', label: 'por'},
        {code: 'rum', label: 'rum'},
        {code: 'slo', label: 'slo'},
        {code: 'slv', label: 'slv'},
        {code: 'spa', label: 'spa'},
        {code: 'swe', label: 'swe'}
      ];

      $scope.setLanguage = function (l) {
        $scope.monitoringLanguage = l.code;
      };

      function guessLanguage(code) {
        // Check if the 2 first letters of a language code
        // match the selected scope
        for (var i = 0; i < $scope.listOfLanguages.length; i++) {
          if ($scope.listOfLanguages[i].code.indexOf(code) === 0) {
            $scope.monitoringLanguage = $scope.listOfLanguages[i].code;
            break;
          }
        }
      };

      function init() {
        //Get list of scope available
        // $http.get(cfg.SERVICES.dataCore +
        //   '?q=' +
        //   'documentType%3Ametadata&' +
        //   'start=0&rows=0&' +
        //   'wt=json&indent=true&' +
        //   'facet=true&facet.sort=index' + facetParam, {cache: true})
        $http.post(
          cfg.SERVICES.esdataCore + '/_search?size=0', {
            "query" : {
              "query_string": {
                "query": "+documentType:metadata"
              }
            },
            "aggs": aggs
          }
        ).success(function (r) {
          $scope.facetValues = {};
          var i = 0, facet = r.aggregations.scope.buckets;

          // The facet response contains an array
          for (var i = 0; i < facet.length; i ++) {
            $scope.listOfScope.push({
              label: facet[i].key,
              count: facet[i].doc_count
            });
          }

          var scopeParam = $location.search().scope,
            filterParam = $location.search().filter;

          if (scopeParam) {
            angular.forEach($scope.listOfScope, function (item) {
              if (item.label === scopeParam) {
                $scope.scope = item;
              }
            });
          }
          if (filterParam) {
            $scope.filter = filterParam;
          }
        });


        // Get the list of monitoring types
        $http.get(cfg.SERVICES.reportingConfig, {cache: false}).success(function (data) {
          $scope.reportingConfig = data.reporting;

          // If reporting param defined in URL
          // check if it's available in the
          // monitoring config and set it.
          var reportingParam = $location.search().reporting;
          if (reportingParam) {
            angular.forEach($scope.reportingConfig, function (item) {
              if (item.id === reportingParam) {
                $scope.reporting = item;
                //return;
              }
            });
          }

          // If not, use the first one from the configuration.
          if (!$scope.reporting) {
            $scope.reporting = $scope.reportingConfig[0];
          }
        });

      };

      function getMatchingRecord() {
        var fq =
          ($scope.filter ? $scope.filter : '') +
          ($scope.scope ? ' +scope:"' + $scope.scope.label + '"' : '');
        $scope.filterCount = null;
        $scope.filterError = null;
        $scope.fq = encodeURIComponent(fq);

        return  $http.post(
          cfg.SERVICES.esdataCore + '/_search?size=0', {
            "query" : {
              "query_string" : {
                "query" : "+documentType:metadata " + fq
              }
            },
            "aggs": aggs
          })
        .success(function (data) {
          $scope.filterCount = data.hits.total;
          $scope.facetValues = data.aggregations;
          $scope.preview();
        }).error(function (response) {
          $scope.filterError = response.error.msg;
        });
      };

      function setReport(data) {
        $scope.report = data;
        $scope.rules = [];
        if (data.indicators.indicator) {
          $scope.rules.push.apply($scope.rules, data.indicators.indicator);
        }
        if (data.variables.variable) {
          $scope.rules.push.apply($scope.rules, data.variables.variable);
        }
      }

      // Add selected facet to the filter
      $scope.addFacet = function (facet, value) {
        $scope.filter = '+' + facet + ':"' + value + '"';

        // Set reporting date to the harvestedDate
        if (facet === 'harvestedDate') {
          var v = moment(value);
          $scope.date = moment(v.utc().format('YYYY-MM-DD')).toDate();
          $scope.time = new Date(v.utc().format('1970-01-01THH:mm:ss'));
        }
      };

      // View report configuration
      $scope.getReportDetails = function () {
        return $http.get(cfg.SERVICES.reports + '/' +
          $scope.reporting.id + '.json').success(function (data) {
          setReport(data);
          $scope.overview = true;
          // Scroll to the element related to the specified $location.hash
          $location.hash('ds-report-results');
          $anchorScroll();
        });

      };

      // Create report type
      $scope.reportTypeName=null;
      $scope.createReportType = function (id) {
        var contentxml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'+
            '<reporting xmlns="http://daobs.org" id="'+ id.replace(/[\s]/g, '_')+'">'+
            '<identification>'+
            '<title xml:lang="en">'+
            id+
            '</title>'+
            '<author>DAOBS Team</author>'+
            '<url></url></identification><variables/><indicators/></reporting>';
        var config = { headers:
          {
            'Content-Type': 'application/xml',
            'Accept': '*/*'
          }
        };
        var data =null;
        return $http.put(cfg.SERVICES.reports + '/' + id + '?specification='+ contentxml, data ,config).then(function successCallback(response) {
              //console.log(response);
              $scope.reportTypeName=null;
              //console.log(cfg.SERVICES);
              init();
              $location.url($location.path() + '?reporting='+id);
          }, function errorCallback(response) {
              console.log(response);
          });
      };

      // Remove report type
      $scope.removeReportType = function () {
        return $http.delete(cfg.SERVICES.reports + '/' +
            $scope.reporting.id).then(function successCallback(response) {
              $scope.report = null;
              init();
              $location.url($location.path());
              $anchorScroll();
            }, function errorCallback(response) {
          });
      }




      // Preview report
      $scope.preview = function () {
        $scope.overview = false;
        $scope.report = null;
        var area = $scope.scope && $scope.scope.label,
          filterParameter =
            ($scope.filter ? '?fq=' + encodeURIComponent($scope.filter) : '?') +
            ($scope.dateTime ? '&date=' + $scope.dateTime : '');
        return $http.get(cfg.SERVICES.reports + '/' +
          $scope.reporting.id +
          (area ? '/' + area : '') +
          '.json' + filterParameter).success(function (data) {
          setReport(data);
        });
      };

      // Delete indicator or variable
      $scope.deleteIndicator = function (elem) {
        if (elem.expression) {
          return $http.delete(cfg.SERVICES.reports + '/' +
            $scope.reporting.id + '/indicators/'+ elem.id).then(function successCallback(response) {
              $scope.getReportDetails();
          }, function errorCallback(response) {
            //console.log(response);
            // called asynchronously if an error occurs
            // or server returns response with an error status.
          });
        }
        if (elem.query) {
          return $http.delete(cfg.SERVICES.reports + '/' +
            $scope.reporting.id + '/variables/'+ elem.id).then(function successCallback(response) {
              $scope.getReportDetails();
            }, function errorCallback(response) {
              //console.log(response);
              // called asynchronously if an error occurs
              // or server returns response with an error status.
          });
        }
      };

      //Edit indicator or variable
      $scope.editIndicator = function (elem) {
        $scope.displayAddRule = true;
        $scope.disabledId = true;
        $scope.elem.id = elem.id;
        $scope.elem.name = elem.name.content;
        $scope.elem.definition = elem.comment;
        if (elem.expression){
          $scope.displayAddIndicator = true;
          $scope.elem.expression = elem.expression;
        }
        if (elem.query){
          $scope.displayAddIndicator = false;
          $scope.elem.query = elem.query.value;
        }
      }

      // Display indicator or variable form
      $scope.elem = {};
      $scope.displayAddRule = false;
      $scope.displayAddIndicator = false;
      $scope.showAddIndicator = function(){
        $scope.elem={};
        $scope.displayAddRule = true;
        $scope.displayAddIndicator = true;
        $scope.disabledId = false;
      };
      $scope.showAddVariable = function(){
        $scope.elem={};
        $scope.displayAddRule = true;
        $scope.displayAddIndicator = false;
        $scope.disabledId = false;
      };

      // Add indicator or variable
      $scope.addRule= function (elem) {
        $scope.name = {};
        $scope.name['content'] = elem.name;
        $scope.name['lang'] = 'en';
        if (elem.expression){
          $scope.indicator = {
            "error": true,
            "format": "string",
            "numberFormat": "string",
            "parameters": {
              "parameter": []
            },
            "status": "string",
            "value": "string"
          };
          var params = elem.expression.match(/([A-Za-z0-9_-]+)/g);
          for (var i = params.length - 1; i >= 0; i--) {
            $scope.indicator.parameters.parameter.push(
              {
              "error": true,
              "id": params[i],
              "status": "set",
              "value": "0"
            });
          }
          $scope.indicator['name'] = $scope.name;
          $scope.indicator['comment'] = elem.definition;
          $scope.indicator['expression'] = elem.expression;
          $scope.indicator['id'] = elem.id;
          $http.put(cfg.SERVICES.reports + '/' +
            $scope.reporting.id + '/indicators', $scope.indicator).then(function (response) {
              $scope.getReportDetails();
              $scope.elem = {};
              $scope.displayAddRule = false;
          });
        }
        if (elem.query){
          $scope.variable = {
            "default": 0,
            "error": true,
            "format": "string",
            "numberFormat": "string",
            "status": "string",
            "value": "string"
          };
          $scope.query = {
            "stats": null,
            "statsField": null,
          };
          $scope.query['value'] = elem.query;
          $scope.variable['id'] = elem.id;
          $scope.variable['comment'] = elem.definition;
          $scope.variable['name'] = $scope.name;
          $scope.variable['query'] = $scope.query;
          $http.put(cfg.SERVICES.reports + '/' +
            $scope.reporting.id + '/variables', $scope.variable).then(function (response) {
              $scope.getReportDetails();
              $scope.elem = {};
              $scope.displayAddRule = false;
          });
        }
      }


      $scope.submit = function (type) {
        $scope.overview = false;
        $scope.report = null;
        var area = $scope.scope && $scope.scope.label,
          filterParameter =
            ($scope.filter ? '?fq=' + encodeURIComponent($scope.filter) : '?') +
            '&scopeId=' + $scope.scopeId +
            ($scope.dateTime ? '&date=' + $scope.dateTime : '');
        return $http.put(cfg.SERVICES.reports +
          (type === 'xml' ? '/' : '/custom/') +
          $scope.reporting.id +
          (area ? '/' + area : '') +
          filterParameter).success(function (data) {
          Notification.success($scope.translations.monitoringSubmitSuccess);
        });
      };

      $scope.$watch('reporting', function () {
        $scope.reporting && $location.search('reporting', $scope.reporting.id);
      });
      // Reset report on scope changes
      $scope.$watch('scope', function (oldValue, newValue) {
        $scope.report = null;
        if (oldValue !== newValue) {
          $scope.scope && $location.search('scope', $scope.scope.label);
          getMatchingRecord();
          guessLanguage(newValue);
        }
      });
      $scope.$watch('filter', function (oldValue, newValue) {
        if (oldValue !== newValue) {
          $scope.filter && $location.search('filter', $scope.filter);
          getMatchingRecord();

        }
      });

      $scope.isfilterErrors = false;
      $scope.isfilterNonNull = false;
      $scope.checkboxFilters = function (indicator) {
        if ($scope.isfilterErrors && $scope.isfilterNonNull &&
          indicator.status != null &&
          parseFloat(indicator.value) != NaN &&
          parseFloat(indicator.value) > 0) {
          return indicator;
        } else if ($scope.isfilterErrors && indicator.status != null) {
          return indicator;
        }
        if ($scope.isfilterNonNull &&
          parseFloat(indicator.value) != NaN &&
          parseFloat(indicator.value) > 0) {
          return indicator;
        } else if (!$scope.isfilterErrors && !$scope.isfilterNonNull) {
          return indicator;
        }
      };
      init();
    }]);


  /**
   * Controller for submit new monitoring.
   */
  app.controller('MonitoringSubmitCtrl', [
    '$scope', '$http', '$translate', 'cfg', 'monitoringService',
    function ($scope, $http, $translate, cfg, monitoringService) {
      $scope.isOfficial = false;
      $scope.withRowData = false;
      $scope.isSubmitting = false;
      $scope.monitoringFiles = [];
      $scope.responseMessages = [];

      var listOfDeffered;

      function addMessage(text, name) {
        $translate(text, {
          filename: name
        }).then(function (translation) {
          $scope.responseMessages.push({
            label: translation,
            success: text === 'monitoringSubmitSuccess'
          });
          $scope.isSubmitting =
            $scope.responseMessages.length !== listOfDeffered.length;
        });
      };

      $scope.uploadMonitoring = function () {
        if ($scope.monitoringFiles.length === 0) {
          return;
        }

        $scope.isSubmitting = true;
        $scope.responseMessages = [];
        listOfDeffered = [];

        listOfDeffered = monitoringService.uploadMonitoring(
          $scope.monitoringFiles,
          $scope.isOfficial,
          $scope.withRowData
        );

        angular.forEach(listOfDeffered, function (item) {
          item.promise.then(function (data) {
            addMessage('monitoringSubmitSuccess', item.file.name);
          }, function (response) {
            addMessage('monitoringSubmitError', item.file.name);
          });
        });
      }
    }]);
}());
