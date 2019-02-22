angular.module('sensor', [])
.controller('MainCtrl', [
  '$scope','$http',
  function($scope,$http){
    $scope.current_temperature = 'no temperature yet';
    $scope.temperatures = [];
    $scope.violations = [];
    $scope.eci = 'DWTzGk3L7saRezdMWindXq';
    $scope.ip = 'localhost'
    $scope.port = '8080'

    $scope.profile = {
        'name':'Wovyn Sensor',
        'location':'home',
        'number':'+12567634268',
        'min':60,
        'max':90
    }
 
    var home = function(){
        return 'http://'+$scope.ip + ':' + $scope.port;
    };

    var profileURL = home()+'/sky/event/'+$scope.eci+
                    '/webpage/sensor/profile_updated';
    $scope.changeProfile = function() {
      var pURL = profileURL + "?location=" + $scope.loc + 
                              "&name=" + $scope.name;
      return $http.post(pURL).success(function(data){
        $scope.loc = ''
        $scope.name = ''
        $scope.updateProfile()//update profile view variables
      });
    };

    var changeURL = home()+'/sky/event/'+$scope.eci+
                    '/webpage/sensor/threshold_updated';
    $scope.changeThreshold = function() {
      var pURL = changeURL + "?min=" + $scope.low + "&max=" + $scope.high;
      return $http.post(pURL).success(function(data){
        $scope.low=''; //entry fields
        $scope.high='';
        $scope.updateProfile()
      });
    };

    var phoneURL = home()+'/sky/event/'+$scope.eci+
                   '/webpage/sensor/phone_updated';
    $scope.changeNumber = function() {
      var pURL = phoneURL + "?number=" + $scope.number;
      return $http.post(pURL).success(function(data){
        $scope.number=''; //entry field
        $scope.updateProfile()
      });
    };
    
    var gURL = home()+'/sky/cloud/'+$scope.eci+'/temperature_store/temperatures';
    $scope.getTemps = function() {
      return $http.get(gURL).success(function(data){
        angular.copy(data, $scope.temperatures);
        if($scope.temperatures.length > 15){
            $scope.temperatures.length = 15;}
        $scope.current_temperature = data[0]['temperature'];
      });
    };
    var vURL = home()+'/sky/cloud/'+$scope.eci+
               '/temperature_store/threshold_violations';
    $scope.getViolations = function() {
      return $http.get(vURL).success(function(data){
        angular.copy(data, $scope.violations);
        if( $scope.violations.length > 15){
            $scope.violations.length = 15;}
      });
    };

    var sensorURL = home()+'/sky/cloud/'+$scope.eci+'/sensor_profile/getSensor';
    $scope.updateProfile = function() {
      return $http.get(sensorURL).success(function(data){
        angular.copy(data, $scope.profile);
      });
    };
    $scope.updateProfile();

    var updateTemps = function(){
        $scope.getTemps();
        $scope.getViolations();
        setTimeout(updateTemps, 3000);
    }

    updateTemps()
  }
]);
