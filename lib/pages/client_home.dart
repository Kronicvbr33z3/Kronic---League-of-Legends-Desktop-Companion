import 'dart:convert';
import 'package:kronic_desktop_tool/models/session.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import 'package:kronic_desktop_tool/services/client_manager.dart';
import 'package:kronic_desktop_tool/services/league_client_connector.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:kronic_desktop_tool/services/web_socket_helper.dart';
import 'package:kronic_desktop_tool/services/champ_select_helper.dart';

class ClientHome extends StatefulWidget {
  static const routeName = '/client_home';
  @override
  _ClientHomeState createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  Widget home(ClientManager clientManager, WebSocketChannel channel) {
    return StreamBuilder(
        stream: channel.stream,
        builder: (context, snapshot) {
          List<Widget> children;
          if (snapshot.hasError) {
            children = <Widget>[Text("Error has Occurred")];
          } else {
            if (snapshot.hasData) {
              LCUWebSocketResponse response =
                  LCUWebSocketResponse(snapshot.data);

              switch (response.status) {
                // Home Screen
                case 0:
                  {
                    children = <Widget>[Text("Home Screen")];

                  }
                  break;
                // Champion Select Screen
                case 1:
                  {

                    Session session = Session.fromJson(json.decode(snapshot.data)[2]['data']);

                    children = <Widget>[ChampionSelectHelper().champSelect(clientManager, session)];
                  }
                  break;
                default:
                  {
                    children = <Widget>[Text("Default")];
                  }
              }
            } else {
              return Text("Error");
            }
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,

          );
        });
  }

  @override
  Widget build(BuildContext context) {
    ClientManager clientManager = ModalRoute.of(context).settings.arguments;
    final channel = IOWebSocketChannel.connect(
        'wss://127.0.0.1:${clientManager.getPort()}',
        headers: {"Authorization": "Basic ${clientManager.getAuthHeader()}"});
    channel.sink.add('[5, "OnJsonApiEvent_lol-champ-select_v1_session"]');
    return Scaffold(
      appBar: AppBar(
        leading: new Container(),
        title: Text("Home",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(28, 22, 46, 1),
        elevation: 0.0,
      ),
      body: Container(
          constraints: BoxConstraints.expand(),
          color: Color.fromRGBO(28, 22, 46, 1),
          child: home(clientManager, channel)),
      bottomNavigationBar: BottomAppBar(
          color: Color.fromRGBO(28, 22, 46, 1),
          child: Row(
            children: [
              Container(
                height: 50,
              )
            ],
          )),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromRGBO(184, 88, 88, 1),
        child: Icon(Icons.accessible_outlined),
        onPressed: () async {
          var champSelect = await clientManager.champSelect();
          print(clientManager.getAuthHeader());
          if (champSelect) {
            var champId = await clientManager.getCurrentChampId();
            if (champId == -1 || champId == 0) {
              print("Choose Champion");
            } else {
              var runes = await clientManager.getRunes(champId);
              await clientManager.putRunes(runes);
            }
          } else {
            print("Not In Champ Select");
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
