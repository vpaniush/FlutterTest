import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(NotesApp());

class NotesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: HomeScreen(title: 'Notes'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Note extends StatelessWidget {
  final String _title;
  final String _text;
  final String _imagePath;

  Note(this._title, this._text, this._imagePath);

  Note.fromJson(Map<String, dynamic> json)
      : _title = json['title'],
        _text = json['text'],
        _imagePath = json['imagePath'];

  Map<String, dynamic> toJson() => {
        'title': _title,
        'text': _text,
        'imagePath': _imagePath,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.0,
      padding: EdgeInsets.all(10.0),
      margin: EdgeInsets.only(bottom: 10.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Container(
            height: 100.0,
            width: 65.0,
            color: Colors.white,
            child: (_imagePath != null)
                ? Image.file(
                    File(_imagePath),
                    fit: BoxFit.fill,
                  )
                : Center(child: Text('No photo')),
          ),
          Expanded(
            child: Container(
              child: Column(
                children: <Widget>[
                  Text(
                    _title,
                    style:
                        TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Text(
                      _text,
                      style: TextStyle(fontSize: 18.0),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                    alignment: Alignment.topLeft,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _dataList = List<String>();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  _loadNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _dataList = (prefs.getStringList('notes')) ?? List<String>();
    });
  }

  _addNote(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewNoteScreen()),
    );

    setState(() {
      _dataList = (prefs.getStringList('notes')) ?? List<String>();
      if (result != null) _dataList.add(result);
      prefs.setStringList('notes', _dataList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: _dataList.length,
        itemBuilder: (BuildContext context, int index) {
          return Note.fromJson(jsonDecode(_dataList[index]));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNote(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class NewNoteScreen extends StatefulWidget {
  @override
  _NewNoteScreenState createState() => _NewNoteScreenState();
}

class _NewNoteScreenState extends State<NewNoteScreen> {
  final _titleCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  String _imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add new note'),
        actions: [
          FlatButton(
            onPressed: () async {
              _imagePath = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TakePhotoScreen()),
              );
            },
            child: Icon(
              Icons.add_a_photo,
              color: Colors.white,
            ),
          ),
          FlatButton(
            onPressed: () {
              Navigator.pop(
                context,
                jsonEncode(Note(_titleCtrl.text, _textCtrl.text, _imagePath)),
              );
            },
            child: Text(
              'Save',
              style: TextStyle(fontSize: 16),
            ),
            textColor: Colors.white,
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Title',
              ),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.0),
            ),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Text',
                ),
                style: TextStyle(fontSize: 18.0),
                maxLines: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TakePhotoScreen extends StatefulWidget {
  @override
  _TakePhotoScreenState createState() => _TakePhotoScreenState();
}

class _TakePhotoScreenState extends State<TakePhotoScreen> {
  CameraController _cameraCtrl;
  Future<void> _initializeCtrl;

  _initCamCtrl() async {
    var cameras = await availableCameras();
    setState(() {
      _cameraCtrl = CameraController(cameras.first, ResolutionPreset.medium);
      _initializeCtrl = _cameraCtrl.initialize();
    });
  }

  @override
  void initState() {
    super.initState();
    _initCamCtrl();
  }

  @override
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a photo')),
      body: FutureBuilder<void>(
        future: _initializeCtrl,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_cameraCtrl);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: () async {
          await _initializeCtrl;
          final imgPath = join(
            (await getTemporaryDirectory()).path,
            '${DateTime.now()}.png',
          );
          await _cameraCtrl.takePicture(imgPath);
          Navigator.pop(context, imgPath);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
