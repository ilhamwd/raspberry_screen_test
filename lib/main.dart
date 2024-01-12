import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? dataFromApi;
  String? dataFromMqtt;

  @override
  void initState() {
    super.initState();

    final client = MqttServerClient("127.0.0.1", "gwej");

    client.onConnected = () {
      client.subscribe("random/number", MqttQos.atLeastOnce);
      client.updates!.listen((event) {
        setState(() {
          dataFromMqtt = MqttPublishPayload.bytesToStringAsString(
              (event.first.payload as MqttPublishMessage).payload.message);
          ;
        });
      });
    };

    client.connect();

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        get(Uri.parse("http://localhost/random/number")).then((value) {
          final data = jsonDecode(value.body);
          dataFromApi = data['number'].toString();
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final now = DateTime.now();

    return Scaffold(
        body: Stack(children: [
      Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Row(
              children: [
                Text("API: ${dataFromApi ?? "N/A"}"),
                const Spacer(),
                Text("MQTT: ${dataFromMqtt ?? "N/A"}")
              ],
            ),
          )),
      Column(
        children: [
          const Spacer(),
          Expanded(
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  color: Color.fromARGB(255, random.nextInt(256),
                      random.nextInt(256), random.nextInt(256))))
        ],
      ),
      Center(
          child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Text(
          "${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}:${now.second.toString().padLeft(2, "0")}",
          style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold),
        ),
      ))
    ]));
  }
}
