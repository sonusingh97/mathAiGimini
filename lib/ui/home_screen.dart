import 'dart:async';
import 'dart:io';

import 'package:aigimini/provider/image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //save it in .env file or define system files
  static const _apiKey = 'AIzaSyCoZBzWXk_89_nom6bkK2wm1qnibq75jBk';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final myModel = Provider.of<ImageControllers>(context, listen: false);

    myModel.scrollController = ScrollController();
    myModel.streamSocket.getResponse;
    myModel.model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
    myModel.chat = myModel.model.startChat();
  }

  @override
  Widget build(BuildContext context) {
    final imageController = context.watch<ImageControllers>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Gemini'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<List<DataModel>>(
            stream: imageController.streamSocket.getResponse,
            initialData: [
              DataModel('No Data Found', 'No Data Found', 'No Data Found')
            ],
            builder: (BuildContext context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              } else {
                if (imageController.list.isEmpty) {
                  return const Expanded(
                      child: Center(
                          child: Text('Greetings!\n How i can help you',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white))));
                }
                return Expanded(
                  child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      controller: imageController.scrollController,
                      itemBuilder: (context, index) {
                        final data = imageController.list[index];
                        return MessageWidget(
                          text: data.prompt,
                          isFromUser: data.isMe,
                          type: data.type,
                          image: data.image,
                        );
                      }),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 25,
              horizontal: 15,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white)
                    ),
                    child: Column(
                      children: [
                        imageController.image != null
                            ? SizedBox(
                          height: 25,
                          width: 50,
                          child: Image.file(
                              height: 20,
                              width: 50,
                              fit: BoxFit.cover,
                              File(imageController.image!.path)),
                        )
                            : const SizedBox(),
                        TextField(
                          autofocus: true,
                          focusNode: imageController.textFieldFocus,
                          /*decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(15),
                            hintText: 'Enter a prompt...',
                          *//*  border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(14),
                              ),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(14),
                              ),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),*//*
                          ),*/
                          controller: imageController.textController,
                          onSubmitted: (String value) {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox.square(
                  dimension: 15,
                ),
                if (!imageController.loading)
                  IconButton(
                    onPressed: () async {
                      if (imageController.textController.text.isEmpty) {
                        _showError('Please enter prompt');
                      } else {
                        if (imageController.image == null) {
                          imageController.sendChatMessage(
                              imageController.textController.text);
                        } else {
                          imageController.sendImageMessage(
                              imageController.textController.text);
                        }
                      }
                    },
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                if (!imageController.loading)
                  IconButton(
                    onPressed: () async {
                      imageController.getImage();
                    },
                    icon: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  const CircularProgressIndicator(),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}

class MessageWidget extends StatelessWidget {
  final String text, type, image;
  final bool isFromUser;

  const MessageWidget({
    super.key,
    required this.text,
    required this.isFromUser,
    required this.type,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: isFromUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
            ),
            margin: const EdgeInsets.only(bottom: 8),
            child: type == 'image'
                ? Image.file(
                    height: 250,
                    width: 250,
                    fit: BoxFit.cover,
                    File(image.toString()))
                : MarkdownBody(
                    selectable: true,
                    data: text,
                  ),
          ),
        ),
      ],
    );
  }
}

class DataModel {
  String prompt, type, image;
  bool isMe;

  DataModel(this.image, this.type, this.prompt, {this.isMe = false});
}

class StreamSocket {
  final _socketResponse = StreamController<List<DataModel>>.broadcast();

  void Function(List<DataModel>) get addResponse => _socketResponse.sink.add;

  Stream<List<DataModel>> get getResponse =>
      _socketResponse.stream.asBroadcastStream();
}
