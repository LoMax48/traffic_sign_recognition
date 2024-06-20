import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_traffic_signs/pages/settings_page.dart';
import 'package:flutter_vision/flutter_vision.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future? _isLoadedCamera;
  String _message = "";
  late CameraController _cameraController;
  late FlutterVision vision;
  CameraImage? _cameraImage;
  List? _recognitions;
  var stackChildren = <Widget>[];
  var images = <String>[];

  @override
  void initState() {
    vision = FlutterVision();
    _isLoadedCamera = _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    vision.closeYoloModel();
    super.dispose();
  }

  Future<CameraDescription?> _getAvailableCameras() async {
    var cameras = await availableCameras();
    return cameras.firstOrNull;
  }

  Future<void> _initCamera() async {
    await _initModel();
    var cameraDescription = await _getAvailableCameras();
    if (cameraDescription == null) {
      setState(() {
        _message = "Камера недоступна!";
      });
      return;
    }
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
    );
    await _cameraController.initialize();
    _cameraController.startImageStream((image) async {
      setState(() {
        _cameraImage = image;
      });
    });
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        if (_cameraImage == null) {
          return;
        }
        var recognitions = await vision.yoloOnFrame(
          bytesList: _cameraImage!.planes.map((e) => e.bytes).toList(),
          imageHeight: _cameraImage!.height,
          imageWidth: _cameraImage!.width,
          iouThreshold: 0.4,
          confThreshold: 0.4,
          classThreshold: 0.5,
        );
        print(recognitions);
        setState(() {
          _recognitions = recognitions;
        });
      } catch (e) {
        print(e);
      }
    });
  }

  Future<void> _initModel() async {
    try {
      await vision.loadYoloModel(
        modelPath: "assets/model.tflite",
        labels: "assets/labels.txt",
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 1,
        useGpu: false,
      );
    } catch (e) {
      setState(() {
        _message = 'Ошибка загрузки модели!';
      });
    }
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (_recognitions == null || _recognitions!.isEmpty) return [];
    double factorX = screen.width / (_cameraImage?.height ?? 1);
    double factorY = screen.height / (_cameraImage?.width ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return _recognitions!.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Распознование дорожных знаков"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: SafeArea(
        child: _message.isNotEmpty
            ? Center(
                child: Text(
                  _message,
                  style: const TextStyle(fontSize: 24),
                ),
              )
            : FutureBuilder(
                future: _isLoadedCamera,
                builder: (ctx, snapshot) {
                  return snapshot.connectionState == ConnectionState.done
                      ? Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.bottomCenter,
                          children: [
                            AspectRatio(
                              aspectRatio: _cameraController.value.aspectRatio,
                              child: CameraPreview(_cameraController),
                            ),
                            // ...displayBoxesAroundRecognizedObjects(
                            //   MediaQuery.of(context).size,
                            // ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _recognitions != null
                                  ? _recognitions!
                                      .map(
                                        (e) => SvgPicture.asset(
                                          'assets/signs/${e['tag']}.svg',
                                        ),
                                      )
                                      .toList()
                                      .sublist(
                                        0,
                                        min(_recognitions?.length ?? 0, 3),
                                      )
                                  : [],
                            ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator());
                },
              ),
      ),
    );
  }
}
