import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../ui/home_screen.dart';

class ImageControllers extends ChangeNotifier {
  late final GenerativeModel model;
  late final ChatSession chat;
  late final ScrollController scrollController;
  final TextEditingController textController = TextEditingController();
  final FocusNode textFieldFocus = FocusNode();

  List<DataModel> list = [];

  StreamSocket streamSocket = StreamSocket();

  bool loading = false;
  XFile? _image;

  XFile? get image => _image;

  Future<void> getImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      ImageCropper cropper = ImageCropper();
      final cropperImage = await cropper.cropImage(
        sourcePath: image.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio4x3,
        ],
      );
      _image = cropperImage != null ? XFile(cropperImage.path) : null;
    }
    notifyListeners();
  }

  String responseBody = '';
  String _apiKey ='AIzaSyCoZBzWXk_89_nom6bkK2wm1qnibq75jBk';
  /*Future<void> sendImage(XFile? imagefile) async {
    if (imagefile == null) return;
    String base64Image = base64Encode(File(imagefile.path).readAsBytesSync());

    String requestBody = json.encode({
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "fileData": {"fileUri": base64Image, "mimeType": "image/jpeg"}
            }
          ]
        },
        {
          "role": "model",
          "parts": [
            {
              "text":
                  "A graceful green sea turtle glides through a vibrant turquoise ocean. The sun filters through the water, illuminating the intricate patterns on its shell."
            }
          ]
        },
        {
          "role": "user",
          "parts": [
            {"text": "INSERT_INPUT_HERE"}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 1,
        "topK": 64,
        "topP": 0.95,
        "maxOutputTokens": 8192,
        "responseMimeType": "text/plain"
      }
    });
    http.Response response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody);
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonBody = json.decode(response.body);
      // responseBody=jsonBody['contents']['parts'][0]['text'];
      print("image send");
      print(response.body);
    } else {
      print("request faile");
    }
  }*/

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  Future<void> sendImageMessage(String message) async {
    try {

        loading = true;


      list.add(
          DataModel(_image!.path.toString(), 'image', message, isMe: true));
      list.add(DataModel(_image!.path.toString(), 'text', message, isMe: true));
      streamSocket.addResponse(list);

      _scrollDown();

      notifyListeners();
      final firstImage = await _image!.readAsBytes();

      final prompt = TextPart(message);

      final imageParts = [
        DataPart('image/jpeg', firstImage),
      ];

      final response = await model.generateContent([
        Content.multi([prompt, ...imageParts])
      ]);

      var text = response.text;

      if (text == null) {
        //  _showError('No response from API.');
        return;
      } else {
        list.add(DataModel('', 'text', text, isMe: false));
        streamSocket.addResponse(list);

        loading = false;
        _scrollDown();
        notifyListeners();
      }
    } catch (e) {
      // _showError(e.toString());

      loading = false;
    } finally {
      textController.clear();
      _image=null;
      notifyListeners();

      loading = false;

      textFieldFocus.requestFocus();
    }
    notifyListeners();
  }

/*Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      // setState(() {
      //   _image = File(pickedFile.path);
      // });
    }

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile!.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
        ),
        IOSUiSettings(
          title: 'Cropper',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    _image = File(croppedFile!.path);
  }*/



 Future<void> sendChatMessage(String message) async {

      loading = true;
      notifyListeners();


    try {
      list.add(DataModel('', 'text', message, isMe: true));
      streamSocket.addResponse(list);

      var response = await chat.sendMessage(
        Content.text(message),
      );

      var text = response.text;

      if (text == null) {
      //  _showError('No response from API.');
        return;
      } else {
        list.add(DataModel('', 'text', text, isMe: false));
        streamSocket.addResponse(list);

          loading = false;
          _scrollDown();
          notifyListeners();

      }
    } catch (e) {
    //  _showError(e.toString());

        loading = false;

    } finally {
      textController.clear();

        loading = false;

      textFieldFocus.requestFocus();
    }
  }

}

/*
*/
