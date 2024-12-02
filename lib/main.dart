
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/distance_notifier.dart';

final distanceProvider=StateNotifierProvider<DistanceNotifier, double>((ref)=>DistanceNotifier(0));
final isOpen=StateProvider<bool>((ref)=>false);

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(ProviderScope(child: MainApp(camera: cameras.last,)));
}
class MainApp extends ConsumerWidget{
  const MainApp({super.key, required this.camera});
  final CameraDescription camera;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    CameraController controller=CameraController(camera, ResolutionPreset.medium);
    final cameraInit=StateProvider((ref)async=>await controller.initialize());

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child:
            SingleChildScrollView(
              child: Column(children: [
                Text('${ref.watch(distanceProvider).toInt()} м.', style: const TextStyle(fontSize: 22),),
                TextButton(onPressed: () async {
                  await ref.watch(distanceProvider.notifier).startWay();
                }, child: const Text('Start')),
                TextButton(onPressed: () {
                  ref.watch(distanceProvider.notifier).stopWay();
                }, child: const Text('Stop')),
                TextButton(onPressed: () {
                  ref.watch(isOpen.notifier).update((state)=>true);
                }, child: const Text('Open camera')),
               ref.watch(isOpen)?FutureBuilder(future: ref.watch(cameraInit), builder: (context, snapshot){
                  if(snapshot.connectionState==ConnectionState.done){
                    return Column(
                      children: [
                        CameraPreview(controller),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(onPressed: ()async{
                              final dir=await getApplicationDocumentsDirectory();
                              Logger().i(dir.path);
                              final img=await controller.takePicture();
                              await img.saveTo('${dir.path}/${img.name}');
                            }, icon: const Icon(Icons.photo_camera)),
                            TextButton(onPressed: (){
                          ref.watch(isOpen.notifier).update((state)=>false);
                          ref.watch(cameraInit.notifier).dispose();
                        }, child: const Text('Close', style: TextStyle(color: Colors.black),))
                          ])
                      ],
                    );
                  }
                  else{
                    return const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(),
                    );
                  }
                }):
               const Divider()
              ],),
            )
        
        
        ),
      ),
    );
  }
}