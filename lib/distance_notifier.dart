
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class DistanceNotifier extends StateNotifier<double>{
  DistanceNotifier(super.state);
  Timer? timer;
  Stream<Position>? streamPosition;
  StreamSubscription<Position>? streamSub;

  Future<GpsServiceStatus> checkPermission() async{
      if(await Geolocator.isLocationServiceEnabled()){
        final permission=await Geolocator.checkPermission();
        if(permission==LocationPermission.denied){
          final permission=await Geolocator.requestPermission();
          if(permission==LocationPermission.denied){
            return GpsServiceStatus.denied;
          }
          else {
            return GpsServiceStatus.allowed;
          }
        }
        return GpsServiceStatus.allowed;
      }
      return GpsServiceStatus.off;
   }

   Future<GpsServiceStatus> startWay() async {
    switch(await checkPermission()){
      case GpsServiceStatus.allowed:
        calcDistance();
      case GpsServiceStatus.off:
        return GpsServiceStatus.off;
      case GpsServiceStatus.denied:
        return GpsServiceStatus.denied;
    }
    return GpsServiceStatus.off;
   }

   calcDistance() async {
     Position? lastPos;
     streamPosition=Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0));
     streamSub=streamPosition!.listen((pos){
       lastPos ??= pos;
          state+=Geolocator.distanceBetween(lastPos!.latitude, lastPos!.longitude, pos.latitude, pos.longitude);
          lastPos=pos;
        });
   }

   stopWay(){
     if(streamSub!=null){
       streamSub!.cancel();
       state=0;
     }
  }
}

enum GpsServiceStatus {
  off, allowed, denied
}