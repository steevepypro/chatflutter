import 'package:bubble/bubble.dart';
import 'package:flutter/foundation.dart';
import 'package:morse/db/database-helper.dart';
import 'package:morse/models/mensagem.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatConversationsScreen extends StatefulWidget {
  final String title;
  final WebSocketChannel channel;

  ChatConversationsScreen({Key key, @required this.title, @required this.channel})
      : super(key: key);

  @override
  _ChatConversationsScreenState createState() => _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen> {
  TextEditingController _controller = TextEditingController();

  final TextEditingController textEditingController = new TextEditingController();
  
  ScrollController _sc = new ScrollController();
  int pageIndex = 1;
  bool isLoading = false;
  static int pageSize = 10;
  List<FieldsMensagem> mensagemList = new List();
  FieldsMensagem fieldsMensagem = FieldsMensagem();

  @override
  void initState() {
    this._getMoreData(pageIndex);
    _sc.addListener(() {
      if (_sc.position.pixels == _sc.position.maxScrollExtent) {
        _getMoreData(pageIndex);
      }
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(children: <Widget>[
        Column(
          children: <Widget>[
            chatList(context),
            inputBar(context)
          ],
        ),
      ])
    );
  }

  Widget chatListMsg(BuildContext context) {
    return ListView.builder(
      reverse: true,
      itemCount: mensagemList.length + 1,
      padding: EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (BuildContext context, int index) {

        if (index == mensagemList.length) {
          return _buildProgressIndicator();
        } else {
          return Padding(
            padding: EdgeInsets.only(left:10),
            child: _itemPublicadosBuilder(context, index),
          );
        }
      },
      controller: _sc,
    );
  }


  Widget _buildProgressIndicator() {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Center(
        child: new Opacity(
          opacity: isLoading ? 1.0 : 00,
          child: new CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget chatList(BuildContext context) {
    return Flexible(
      child: StreamBuilder(
        stream: widget.channel.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            
          }
          if (snapshot.hasError) {
            print('Aconteceu algun erro no socket');
          }
          return chatListMsg(context);
          // return Padding(
          //   padding: const EdgeInsets.symmetric(vertical: 24.0),
          //   child: Text(snapshot.hasData ? '${snapshot.data}' : ''),
          // );
        },
      )
    );
  }

  Widget _itemPublicadosBuilder(context, items) {

    double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    double px = 1 / pixelRatio;

    BubbleStyle styleSomebody = BubbleStyle(
      // nip: BubbleNip.leftBottom,
      color: Colors.white,
      elevation: 1 * px,
      radius: Radius.circular(15.0),
      padding: BubbleEdges.all(14),
      margin: BubbleEdges.only(top: 8.0, right: 50.0, left: 10),
      // alignment: Alignment.topLeft,
    );

    BubbleStyle styleMe = BubbleStyle(
      // nip: BubbleNip.rightBottom,
      radius: Radius.circular(15.0),
      color: Theme.of(context).primaryColor,
      elevation: 1 * px,
      padding: BubbleEdges.all(14),
      margin: BubbleEdges.only(top: 8.0, left: 50.0, right: 5),
      // alignment: Alignment.topRight,
    );

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          GestureDetector(
            onTap: () async {
            },
            child: Bubble(
              style: styleMe,
              child: Text('dados ',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                  fontStyle: FontStyle.normal)
              ),
            ),
          ),
        ],
      ),
      margin: EdgeInsets.only(bottom: 0.0),
    );
  }

  Widget inputBar(BuildContext context) {
      return Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 5.0,
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Container(
                  color: Colors.white,
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: 8.0),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: TextField(
                          controller: textEditingController,
                          decoration: InputDecoration(
                            hintText: 'Digite uma mensagem...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                    ],
                  ),
                ),
              )
            ),
            SizedBox(
              width: 10.0,
            ),
            InkWell(
              onTap: () async {
                _sendMessage();
              },
              child: Container(
                decoration: new BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: new BorderRadius.circular(50)),
                padding: EdgeInsets.only(left: 11, right: 8, top: 8, bottom: 11),
                child: Transform.rotate(
                  angle: 12.0,
                  child: Center(child:Icon(Icons.send, color: Colors.white,)),
                ),
              ),
              // child: CircleAvatar(
              //   child: Icon(Icons.send),
              // ),
            ),
            SizedBox(
              width: 5.0,
            ),
          ],
        ),
      );
  }

  void _sendMessage() async {
    DatabaseHelper db = DatabaseHelper.instance;

    if (textEditingController.text.isNotEmpty) {
      fieldsMensagem.menMensagem = textEditingController.text;
      fieldsMensagem.menDatacriacao = '${DateTime.now()}';
      fieldsMensagem.menDest = 1;
      fieldsMensagem.menFrom = 1;
      var result = await db.insertMensagem(fieldsMensagem);
      // if(result != 0){
      //   _getMoreData(1);
      // }
      textEditingController.text = '';
    }
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }

  void _getMoreData(int index) async {

    print(index);
    DatabaseHelper db = DatabaseHelper.instance;
    if (!isLoading) {

      setState(() {
        isLoading = true;
      });

      var mensagemPaginator = await db.getMensagemlist();

      for (var i = 0; i < mensagemPaginator.length; i++) {
        mensagemList.add(mensagemPaginator[i]);
      }

      
      setState(() {
        isLoading = false;
        pageIndex++;
      });
    }
  }
}