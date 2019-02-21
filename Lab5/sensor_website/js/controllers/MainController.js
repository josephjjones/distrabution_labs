angular.module('sensor', [])
.controller('MainCtrl', [
  '$scope','$http',
  function($scope,$http){
    $scope.temperatures = [];
    $scope.violations = [];
    $scope.eci = 'DWTzGk3L7saRezdMWindXq';
    $scope.ip = 'localhost'
    $scope.port = '8080'
    
    var home = function(){
        return 'http://'+$scope.ip + ':' + $scope.port;
    };


    var changeURL = home()+'/sky/event/'+$scope.eci+'/webpage/configure/thresholds';
    $scope.changeThreshold = function() {
      var pURL = changeURL + "?low=" + $scope.low + "&high=" + $scope.high;
      return $http.post(pURL).success(function(data){
        $scope.getTemps();
        $scope.low=''; //entry fields
        $scope.high='';
      });
    };

    var phoneURL = home()+'/sky/event/'+$scope.eci+'/webpage/configure/phonenumber';
    $scope.changeNumber = function() {
      var pURL = phoneURL + "?number=" + $scope.number;
      return $http.post(pURL).success(function(data){
        $scope.number=''; //entry field
      });
    };
    
    var gURL = home()+'/sky/cloud/'+$scope.eci+'/temperature_store/temperatures';
    $scope.getTemps = function() {
      return $http.get(gURL).success(function(data){
        angular.copy(data, $scope.temperatures);
      });
    }
    $scope.getTemps();
    var vURL = home()+'/sky/cloud/'+$scope.eci+'/temperature_store/threshold_violations';
    $scope.getViolations = function() {
      return $http.get(vURL).success(function(data){
        angular.copy(data, $scope.violations);
      });
    }
    $scope.getViolations();
  }
]);
