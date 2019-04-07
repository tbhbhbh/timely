import 'package:flutter/material.dart';
import 'dart:async' show Future, Timer;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'dart:core';

void main() => runApp(new MyApp());

String formatDateTime(DateTime dateTime) {
  return DateFormat('hh:mm').format(dateTime);
}

class SkyController{
  String animation;

  SkyController({this.animation});
}

SkyController skyController = new SkyController(animation: "idle");
class TimeZone{
  String value; num offset; String text;

  TimeZone({
    this.value,
    this.offset,
    this.text,
  });

  factory TimeZone.fromJson(Map<String, dynamic> parsedJson) {
    return TimeZone(
      value: parsedJson['value'],
      offset: parsedJson['offset'],
      text: parsedJson['text'],
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Digital-7',
        textTheme: TextTheme(
          title: TextStyle(color: Colors.white, fontSize: 52.0),
          body1: TextStyle(color: Colors.black, fontSize: 18.0),
        )
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
  
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Widget> timeZonePickerList = new List<Widget>();
  List<TimeZone> timeZoneList = new List<TimeZone>();
  List data;

  bool shouldShow = true;
  TimeZone timeZone;
  String _timeString;
  bool pressed = false;
  bool _picked = false;

  Future<String> loadTimeZonesAsset() async {
    return await rootBundle.loadString('assets/timezones.json');
  }
  
  Future loadTimeZones() async {
    String jsonString = await loadTimeZonesAsset();
    final timezones = jsonDecode(jsonString);

    timezones.forEach((timezoneJson) {
      TimeZone timezone = new TimeZone.fromJson(timezoneJson);
      timeZoneList.add(timezone);
    });
    setState(() {
      data = timeZoneList;
    });
  }

  @override
  void initState() {
    super.initState();
    loadTimeZones();
  }

  _populateTimeZonePicker() {
    return data.map((timezone) =>
    Center(child: Text(timezone.text, 
    style: Theme.of(context).textTheme.body1,
    textAlign: TextAlign.center))).toList();
  }

  String _handlePicked(TimeZone timezone) {
    Duration diff;

    Duration nowOffset = DateTime.now().timeZoneOffset;
    Duration targetOffset = new Duration(hours: timezone.offset);

    diff = (targetOffset.abs() > nowOffset) ? targetOffset - nowOffset
          : nowOffset - targetOffset;

    DateTime now = DateTime.now().add(diff);
    setState(() {
      skyController.animation = "start";
      _timeString = formatDateTime(now);
    });
    return _timeString;
  }

  void _showTimeZonePicker() {
    showModalBottomSheet(context: context, builder: (context) {
      return Container(
        child: CupertinoPicker(
          onSelectedItemChanged: (index) {
            timeZone = timeZoneList[index];
            setState(() {
              _picked = true;
            });
            },
          itemExtent: 32,
          children: timeZonePickerList,
        )
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    if (data != null) {
      timeZonePickerList = _populateTimeZonePicker();
    }
       return new Container(
         child: Stack(
           children: <Widget>[
              Positioned.fill(
                child: FlareActor(
                  "assets/Timely.flr",
                  animation: skyController.animation,
                  alignment: Alignment.center,
                  fit: BoxFit.contain,
              ) 
              ),
              Container(
                alignment: Alignment.center,
                child: FlatButton(
                    onPressed: () { _showTimeZonePicker(); },
                    child: !_picked ? Clock() : 
                    Text(_handlePicked(timeZone) + '\n in \n' + timeZone.value,
                    style: Theme.of(context).textTheme.title,
                    textAlign: TextAlign.center,),
              ))
          ])
       );
  }
}


class Clock extends StatefulWidget {

  Clock({ Key key} ) : super(key: key);
  
  @override 
  _ClockState createState() => _ClockState();
}

class _ClockState extends State<Clock> with SingleTickerProviderStateMixin {
  String _timeString;
  
  void _getCurrentTime() {
    final String formattedDateTime = formatDateTime(DateTime.now());
    if (this.mounted) {    
      setState(() {
          _timeString = formattedDateTime;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _timeString = formatDateTime(DateTime.now());
    Timer.periodic(Duration(seconds: 1), (Timer t) => _getCurrentTime());
  }

  @override
  Widget build(BuildContext context) {
    return Text(_timeString,
          style: Theme.of(context).textTheme.title,
          textAlign: TextAlign.center,
    );
  }
}