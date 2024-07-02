import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:testrecognition/resultscreen.dart'; // Import your ResultScreen class

class TextScanner extends StatefulWidget {
  const TextScanner({Key? key}) : super(key: key);

  @override
  State<TextScanner> createState() => _TextScannerState();
}

class _TextScannerState extends State<TextScanner> with WidgetsBindingObserver {
  bool isPermissionGranted = false;
  late final Future<void> future;
  CameraController? cameraController;
  final textRecognizer = TextRecognizer();
  final picker = ImagePicker();
  File? galleryFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    future = requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopCamera();
    textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        cameraController != null &&
        cameraController!.value.isInitialized) {
      startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Text Recognition Sample'),
              backgroundColor: Colors.green,
            ),
            
            backgroundColor: isPermissionGranted ? Colors.transparent : null,
            body: 
            isPermissionGranted
                ? Column(
                    children: [
                    
                      
                      Expanded(
                        child: Center(
                          child: galleryFile == null
                              ? const Text('No image selected')
                              : Image.file(galleryFile!),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _showPicker(context),
                        child: const Text('Select Image from Gallery'),
                      ),
                      ElevatedButton(
                        onPressed: scanImage,
                        child: const Text('Scan Text'),
                      ),
                    ],
                  )
                : Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: const Text(
                        'Camera Permission Denied',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      isPermissionGranted = status == PermissionStatus.granted;
    });
  }

  void initCameraController(List<CameraDescription> cameras) {
    if (cameraController != null) {
      return;
    }
    CameraDescription? camera;
    for (var a = 0; a < cameras.length; a++) {
      final CameraDescription current = cameras[a];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }
    if (camera != null) {
      cameraSelected(camera);
    }
  }

  Future<void> cameraSelected(CameraDescription camera) async {
    cameraController = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
    );
    await cameraController?.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  void startCamera() {
    if (cameraController != null) {
      cameraSelected(cameraController!.description);
    }
  }

  void stopCamera() {
    cameraController?.dispose();
  }

  void scanImage() async {
    try {
      if (galleryFile != null) {
        // If image is selected from gallery
        InputImage inputImage = InputImage.fromFile(galleryFile!);
        RecognizedText recognisedText = await textRecognizer.processImage(inputImage);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(text: recognisedText.text),
          ),
        );
      } else {
        // If image is captured from camera
        if (!isPermissionGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission denied'),
            ),
          );
          return;
        }

        XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
        if (pickedFile == null) return;

        File file = File(pickedFile.path);
        InputImage inputImage = InputImage.fromFile(file);
        RecognizedText recognisedText = await textRecognizer.processImage(inputImage);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(text: recognisedText.text),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred when scanning text'),
        ),
      );
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future getImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        galleryFile = File(pickedFile.path);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred when selecting image'),
        ),
      );
    }
  }
}



// import 'dart:io';

// import 'package:camera/camera.dart';

// import 'package:flutter/material.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:testrecognition/resultscreen.dart';


// class TextScanner extends StatefulWidget {
//   const TextScanner({Key? key}) : super(key: key);

//   @override
//   State<TextScanner> createState() => _TextScannerState();
// }

// class _TextScannerState extends State<TextScanner> with WidgetsBindingObserver {
//   bool isPermissionGranted = false;
//   late final Future<void> future;

//   //For controlling camera
//   CameraController? cameraController;
//   final textRecogniser = TextRecognizer();

//   @override
//   void initState() {
//     super.initState();
//     //To display camera feed we need to add WidgetsBindingObserver.
//     WidgetsBinding.instance.addObserver(this);
//     future = requestCameraPermission();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     stopCamera();
//     textRecogniser.close();
//     super.dispose();
//   }

//   //It'll check if app is in foreground or background
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (cameraController == null || !cameraController!.value.isInitialized) {
//       return;
//     }
//     if (state == AppLifecycleState.inactive) {
//       stopCamera();
//     } else if (state == AppLifecycleState.resumed &&
//         cameraController != null &&
//         cameraController!.value.isInitialized) {
//       startCamera();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//         future: future,
//         builder: (context, snapshot) {
//           return Stack(
//             children: [
//               //Show camera content behind everything
//               if (isPermissionGranted)
//                 FutureBuilder<List<CameraDescription>>(
//                     future: availableCameras(),
//                     builder: (context, snapshot) {
//                       if (snapshot.hasData) {
//                         initCameraController(snapshot.data!);
//                         return Center(
//                           child: CameraPreview(cameraController!),
//                         );
//                       } else {
//                         return const LinearProgressIndicator();
//                       }
//                     }),
//               Scaffold(
//                 appBar: AppBar(
//                   title: const Text('Text Recognition Sample'),
//                 ),
//                 backgroundColor:
//                     isPermissionGranted ? Colors.transparent : null,
//                 body: isPermissionGranted
//                     ? Column(
//                         children: [
//                           Expanded(child: Container()),
//                           Container(
//                             padding: EdgeInsets.only(bottom: 30),
//                             child: ElevatedButton(
//                                 onPressed: (){
//                                   scanImage();
//                                 },
//                                 child: Text('Scan Text')),
//                           ),
//                         ],
//                       )
//                     : Center(
//                         child: Container(
//                           padding:
//                               const EdgeInsets.only(left: 24.0, right: 24.0),
//                           child: const Text(
//                             'Camera Permission Denied',
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//               ),
//             ],
//           );
//         });
//   }

//   Future<void> requestCameraPermission() async {
//     final status = await Permission.camera.request();
//     isPermissionGranted = status == PermissionStatus.granted;
//   }

//   //It is used to initialise the camera controller
//   //It also check the available camera in your device
//   //It also check if camera controller is initialised or not.
//   void initCameraController(List<CameraDescription> cameras) {
//     if (cameraController != null) {
//       return;
//     }
//     //Select the first ream camera
//     CameraDescription? camera;
//     for (var a = 0; a < cameras.length; a++) {
//       final CameraDescription current = cameras[a];
//       if (current.lensDirection == CameraLensDirection.back) {
//         camera = current;
//         break;
//       }
//     }
//     if (camera != null) {
//       cameraSelected(camera);
//     }
//   }

//   Future<void> cameraSelected(CameraDescription camera) async {
//     cameraController =
//         CameraController(camera, ResolutionPreset.max, enableAudio: false);
//     await cameraController?.initialize();
//     if (!mounted) {
//       return;
//     }
//     setState(() {});
//   }

//   //Start Camera
//   void startCamera() {
//     if (cameraController != null) {
//       cameraSelected(cameraController!.description);
//     }
//   }

//   //Stop Camera
//   void stopCamera() {
//     if (cameraController != null) {
//       cameraController?.dispose();
//     }
//   }

//   //It will take care of scanning text from image
//   Future<void> scanImage() async {
//     if (cameraController == null) {
//       return;
//     }
//     final navigator = Navigator.of(context);
//     try {
//       final pictureFile = await cameraController!.takePicture();
//       final file = File(pictureFile.path);
//       final inputImage = InputImage.fromFile(file);
//       final recognizerText = await textRecogniser.processImage(inputImage);
//       await navigator.push(
//         MaterialPageRoute(
//           builder: (context) => ResultScreen(text: recognizerText.text),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('An error occurred when scanning text'),
//         ),
//       );
//     }
//   }
// }