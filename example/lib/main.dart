// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';

import 'package:camera_with_rtmp/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

class CameraExampleHome extends StatefulWidget {
  @override
  _CameraExampleHomeState createState() {
    return _CameraExampleHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  throw ArgumentError('Unknown lens direction');
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class _CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver {
  CameraController? controller;
  String? imagePath;
  String? videoPath;
  String? url;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = false;
  bool useOpenGL = true;
  TextEditingController _textFieldController =
      TextEditingController(text: "rtmp://94.237.49.12/live/arun");

  Timer? _timer;
  List<CameraDescription>? cameras;
  bool enableCamera = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MPPSC'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: Colors.black,
            child: Visibility(
              child: Row(
                children: [
                  Text('00:00:00'),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: Center(
                          child: _cameraPreviewWidget(),
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(
                          color: (controller?.value.isRecordingVideo ?? false)
                              ? (controller?.value.isStreamingVideoRtmp ??
                                      false)
                                  ? Colors.redAccent
                                  : Colors.orangeAccent
                              : controller != null &&
                                      (controller?.value.isStreamingVideoRtmp ??
                                          false)
                                  ? Colors.blueAccent
                                  : Colors.grey,
                          width: 3.0,
                        ),
                      ),
                    ),
                  ),
                  _captureControlRowWidget(),
                  Row(
                    children: [
                      // _toggleAudioWidget(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              // _cameraTogglesRowWidget(),
                              _thumbnailWidget(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _bottomWidget(context),
        ],
      ),
    );
  }

  Widget _bottomWidget(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(20),
      color: Colors.black,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Students available'),
              Text('7/7'),
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                _buildButtons(
                  // Icons.mic,
                  enableAudio ? Icons.mic : Icons.mic_off,
                  enableAudio ? Colors.green[700]! : Colors.red,
                  'Mic',
                  () {
                    setState(() {
                      enableAudio = !enableAudio;
                      // if (controller != null) {
                      //   onNewCameraSelected(controller?.description);
                      // }
                    });
                  },
                ),
                _buildButtons(
                  enableCamera ? Icons.videocam : Icons.videocam_off,
                  enableCamera ? Colors.green[700]! : Colors.red,
                  'Video',
                  () {
                    if (cameras != null || cameras!.isNotEmpty) {
                      var frontCamera;
                      for (final cameraDescription in cameras!) {
                        if (cameraDescription.lensDirection ==
                            CameraLensDirection.front) {
                          frontCamera = cameraDescription;
                        }
                      }

                      if (frontCamera != null) {
                        if (!enableCamera) {
                          enableCamera = true;
                          onNewCameraSelected(frontCamera);
                        } else {
                          enableCamera = false;
                          controller?.dispose();
                          controller = null;
                        }
                        setState(() {});
                      }
                    } else {
                      showInSnackBar('No cameras available');
                    }
                  },
                ),
                _buildButtons(
                  Icons.share,
                  Colors.purple,
                  'Share',
                  () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(
      IconData iconData, Color color, String title, void Function() onPressed) {
    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: onPressed,
            child: CircleAvatar(
              backgroundColor: color,
              radius: 22.5,
              child: Container(
                padding: EdgeInsets.all(8),
                child: Icon(iconData),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$title',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraPreviewWidget() {
    if (controller == null || !(controller?.value.isInitialized ?? false)) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: (controller?.value.aspectRatio ?? 16 / 9),
        child: CameraPreview(controller!),
      );
    }
  }

  /// Toggle recording audio
  Widget _toggleAudioWidget() {
    return Padding(
      padding: const EdgeInsets.only(left: 25),
      child: Row(
        children: <Widget>[
          const Text('Enable Audio:'),
          Switch(
            value: enableAudio,
            onChanged: (bool value) {
              enableAudio = value;
              if (controller != null) {
                onNewCameraSelected(controller?.description);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget() {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            videoController == null && imagePath == null
                ? Container()
                : SizedBox(
                    child: (videoController == null)
                        ? Image.file(File(imagePath!))
                        : Container(
                            child: Center(
                              child: AspectRatio(
                                  aspectRatio:
                                      videoController?.value.size != null
                                          ? videoController!.value.aspectRatio
                                          : 1.0,
                                  child: VideoPlayer(videoController!)),
                            ),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.pink)),
                          ),
                    width: 64.0,
                    height: 64.0,
                  ),
          ],
        ),
      ),
    );
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        // IconButton(
        //   icon: const Icon(Icons.camera_alt),
        //   color: Colors.blue,
        //   onPressed:
        //       controller != null && (controller?.value.isInitialized ?? false)
        //           ? onTakePictureButtonPressed
        //           : null,
        // ),
        // IconButton(
        //   icon: const Icon(Icons.videocam),
        //   color: Colors.blue,
        //   onPressed: controller != null &&
        //           (controller?.value.isInitialized ?? false) &&
        //           !(controller?.value.isRecordingVideo ?? false)
        //       ? onVideoRecordButtonPressed
        //       : null,
        // ),
        IconButton(
          icon: const Icon(Icons.video_call),
          color: Colors.blue,
          onPressed: controller != null &&
                  (controller?.value.isInitialized ?? false) &&
                  !(controller?.value.isStreamingVideoRtmp ?? false)
              ? onVideoStreamingButtonPressed
              : null,
        ),
        IconButton(
          icon: controller != null &&
                  ((controller?.value.isRecordingPaused ?? false) ||
                      (controller?.value.isStreamingPaused ?? false))
              ? Icon(Icons.play_arrow)
              : Icon(Icons.pause),
          color: Colors.blue,
          onPressed: controller != null &&
                  (controller?.value.isInitialized ?? false) &&
                  ((controller?.value.isRecordingVideo ?? false) ||
                      (controller?.value.isStreamingVideoRtmp ?? false))
              ? (controller != null &&
                      ((controller?.value.isRecordingPaused ?? false) ||
                          (controller?.value.isStreamingPaused ?? false))
                  ? onResumeButtonPressed
                  : onPauseButtonPressed)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          color: Colors.red,
          onPressed: controller != null &&
                  (controller?.value.isInitialized ?? false) &&
                  ((controller?.value.isRecordingVideo ?? false) ||
                      (controller?.value.isStreamingVideoRtmp ?? false))
              ? onStopButtonPressed
              : null,
        )
      ],
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras == null || (cameras?.isEmpty ?? true)) {
      return const Text('No camera found');
    } else {
      if (cameras != null) {
        for (CameraDescription cameraDescription in cameras!) {
          toggles.add(
            SizedBox(
              width: 90.0,
              child: RadioListTile<CameraDescription>(
                title:
                    Icon(getCameraLensIcon(cameraDescription.lensDirection!)),
                groupValue: controller?.description,
                value: cameraDescription,
                onChanged: controller != null &&
                        (controller?.value.isRecordingVideo ?? false)
                    ? null
                    : onNewCameraSelected,
              ),
            ),
          );
        }
      }
    }

    return Row(children: toggles);
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription? cameraDescription) async {
    // if (controller != null) {
    //   await controller?.dispose();
    // }

    if (cameraDescription != null) {
      controller = CameraController(
        cameraDescription,
        ResolutionPreset.low,
        enableAudio: enableAudio,
        streamingPreset: ResolutionPreset.low,
        androidUseOpenGL: useOpenGL,
      );

      // If the controller is updated then update the UI.
      controller?.addListener(() {
        if (mounted) setState(() {});
        if ((controller?.value.hasError ?? false)) {
          showInSnackBar(
              'Camera error ${(controller?.value.errorDescription ?? false)}');
          _timer?.cancel();
          Wakelock.disable();
        }
      });

      try {
        await controller?.initialize();
      } on CameraException catch (e) {
        _showCameraException(e);
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((String filePath) {
      if (mounted) {
        setState(() {
          imagePath = filePath;
          videoController?.dispose();
        });
        if (filePath != null) showInSnackBar('Picture saved to $filePath');
      }
    });
  }

  void onVideoRecordButtonPressed() {
    startVideoRecording().then((String filePath) {
      if (mounted) setState(() {});
      if (filePath != null) showInSnackBar('Saving video to $filePath');
      Wakelock.enable();
    }).catchError((e) {
      showInSnackBar('Error: ${e.toString()}');
    });
  }

  void onVideoStreamingButtonPressed() {
    startVideoStreaming().then((String? url) {
      if (mounted) setState(() {});
      if (url != null) showInSnackBar('Streaming video to $url');
      Wakelock.enable();
    }).catchError((e) {
      showInSnackBar('Error: ${e.toString()}');
    });
  }

  void onRecordingAndVideoStreamingButtonPressed() {
    startRecordingAndVideoStreaming().then((String? url) {
      if (mounted) setState(() {});
      if (url != null) showInSnackBar('Recording streaming video to $url');
      Wakelock.enable();
    }).catchError((e) {
      showInSnackBar('Error: ${e.toString()}');
    });
    ;
  }

  void onStopButtonPressed() {
    if ((this.controller?.value.isStreamingVideoRtmp ?? false)) {
      stopVideoStreaming().then((_) {
        if (mounted) setState(() {});
        showInSnackBar('Video streamed to: $url FINISHED');
      }).catchError((e) {
        showInSnackBar('Error: ${e.toString()}');
      });
      ;
    } else {
      stopVideoRecording().then((_) {
        if (mounted) setState(() {});
        showInSnackBar('Video recorded to: $videoPath');
      }).catchError((e) {
        showInSnackBar('Error: ${e.toString()}');
      });
      ;
    }
    Wakelock.disable();
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording paused');
    }).catchError((e) {
      showInSnackBar('Error: ${e.toString()}');
    });
    ;
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording resumed');
    }).catchError((e) {
      showInSnackBar('Error: ${e.toString()}');
    });
    ;
  }

  void onStopStreamingButtonPressed() {
    stopVideoStreaming().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video not streaming to: $url');
    }).catchError((e) {
      showInSnackBar('Error: ${e.toString()}');
    });
    ;
  }

  void onPauseStreamingButtonPressed() {
    pauseVideoStreaming().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video streaming paused');
    }).catchError((e) {
      showInSnackBar('Error: ${e.toString()}');
    });
    ;
  }

  void onResumeStreamingButtonPressed() {
    resumeVideoStreaming().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video streaming resumed');
    }).catchError((e) {
      showInSnackBar('Error: ${e.toString()}');
    });
    ;
  }

  Future<String> startVideoRecording() async {
    if (!(controller?.value.isInitialized ?? false)) {
      showInSnackBar('Error: select a camera first.');
    }

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    if ((controller?.value.isRecordingVideo ?? false)) {
      // A recording is already started, do nothing.
    }

    try {
      videoPath = filePath;
      await controller?.startVideoRecording(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    return filePath;
  }

  Future<void> stopVideoRecording() async {
    if (!(controller?.value.isRecordingVideo ?? false)) {}

    try {
      await controller?.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    await _startVideoPlayer();
  }

  Future<void> pauseVideoRecording() async {
    try {
      if ((controller?.value.isRecordingVideo ?? false)) {
        await controller?.pauseVideoRecording();
      }
      if ((controller?.value.isStreamingVideoRtmp ?? false)) {
        await controller?.pauseVideoStreaming();
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    try {
      if ((controller?.value.isRecordingVideo ?? false)) {
        await controller?.resumeVideoRecording();
      }
      if ((controller?.value.isStreamingVideoRtmp ?? false)) {
        await controller?.resumeVideoStreaming();
      }
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<String?> _getUrl() async {
    // Open up a dialog for the url
    String result = _textFieldController.text;

    return await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Url to Stream to'),
            content: TextField(
              controller: _textFieldController,
              decoration: InputDecoration(hintText: "Url to Stream to"),
              onChanged: (String str) => result = str,
            ),
            actions: <Widget>[
              new TextButton(
                child: new Text(
                    MaterialLocalizations.of(context).cancelButtonLabel),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
                onPressed: () {
                  Navigator.pop(context, result);
                },
              )
            ],
          );
        });
  }

  Future<String?> startRecordingAndVideoStreaming() async {
    if (!(controller?.value.isInitialized ?? false)) {
      showInSnackBar('Error: select a camera first.');
    }

    if ((controller?.value.isStreamingVideoRtmp ?? false) ||
        (controller?.value.isStreamingVideoRtmp ?? false)) {}

    String? myUrl = await _getUrl();
    if (myUrl == null) return null;

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Movies/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.mp4';

    try {
      _timer?.cancel();
      url = myUrl;
      videoPath = filePath;
      await controller?.startVideoRecordingAndStreaming(videoPath!, url!);
      _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
        var stats = await controller?.getStreamStatistics();
        print(stats);
      });
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    return url;
  }

  Future<String?> startVideoStreaming() async {
    if (!(controller?.value.isInitialized ?? false)) {
      showInSnackBar('Error: select a camera first.');
    }

    if ((controller?.value.isStreamingVideoRtmp ?? false)) {}

    // Open up a dialog for the url
    String? myUrl = await _getUrl();
    if (myUrl == null) return null;

    try {
      _timer?.cancel();
      url = myUrl;
      await controller?.startVideoStreaming(url!);
      _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
        var stats = await controller?.getStreamStatistics();
        print(stats);
      });
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    return url;
  }

  Future<void> stopVideoStreaming() async {
    if (!(controller?.value.isStreamingVideoRtmp ?? false)) {}

    try {
      await controller?.stopVideoStreaming();
      _timer?.cancel();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  Future<void> pauseVideoStreaming() async {
    if (!(controller?.value.isStreamingVideoRtmp ?? false)) {}

    try {
      await controller?.pauseVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoStreaming() async {
    if (!(controller?.value.isStreamingVideoRtmp ?? false)) {}

    try {
      await controller?.resumeVideoStreaming();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> _startVideoPlayer() async {
    final VideoPlayerController vcontroller =
        VideoPlayerController.file(File(videoPath!));
    videoPlayerListener = () {
      if (videoController != null && videoController?.value.size != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) setState(() {});
        videoController?.removeListener(videoPlayerListener!);
      }
    };
    vcontroller.addListener(videoPlayerListener!);
    await vcontroller.setLooping(true);
    await vcontroller.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        videoController = vcontroller;
      });
    }
    await vcontroller.play();
  }

  Future<String> takePicture() async {
    if (!(controller?.value.isInitialized ?? false)) {
      showInSnackBar('Error: select a camera first.');
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if ((controller?.value.isTakingPicture ?? false)) {
      // A capture is already pending, do nothing.
    }

    try {
      await controller?.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}
