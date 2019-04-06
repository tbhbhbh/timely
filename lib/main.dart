import 'package:flutter/material.dart';
import 'dart:async' show Future, Timer;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';

void main() => runApp(new MyApp()
);

String formatDateTime(DateTime dateTime) {
  return DateFormat('hh:mm').format(dateTime);
}

class TimeZone{
  String value;
  String abbr;
  num offset;
  bool isdst;
  String text;
  List<dynamic> utc;

  TimeZone({
    this.value,
    this.abbr,
    this.offset,
    this.isdst,
    this.text,
    this.utc
  });

  factory TimeZone.fromJson(Map<String, dynamic> parsedJson) {
    return TimeZone(
      value: parsedJson['value'],
      abbr: parsedJson['abbr'],
      offset: parsedJson['offset'],
      isdst: parsedJson['isdst'],
      text: parsedJson['text'],
      utc: parsedJson['utc']
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
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
  List<TimeZone> timeZoneList = new List<TimeZone>();
  bool shouldShow = true;
  Clock clock;
  Selector selector;
  
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
  }


  @override
  void initState() {
    super.initState();
    clock = Clock(this.callback);
    selector = Selector(this.timeZoneList);
  }

  void callback() {
    setState(() {
      this.shouldShow = !this.shouldShow;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    loadTimeZones();
    return new Scaffold(
      appBar: new AppBar(title: new Text('app'),
      ),
      body: Center(
        child:
        shouldShow ? Clock(this.callback) : Selector(this.timeZoneList),
      ),
      );
  }
}


class Selector extends StatefulWidget {
  Selector( this.timeZoneList, { Key key }) : super(key: key);
  final List<TimeZone> timeZoneList;

  @override
  _SelectorState createState() => _SelectorState();
}

class _SelectorState extends State<Selector> {
  bool pressed = false;
  bool _picked = false;
  String _time;
  String timeZoneAbbr;

  List<Widget> timezonetext = new List<Widget>();

  _showTimePicker() {
    showModalBottomSheet(context: context, builder: (context) {
      return Container(
        width: 200.0,
        height: 200.0,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          onDateTimeChanged: (DateTime newdate) {
              print('time picked: '+ _picked.toString());
            if (_time != newdate.toString()) {
              setState(() {
                _picked = !_picked;
                _time = formatDateTime(newdate);
              });
            }
          },
        ),
      );
    });
  }
  _populateTimeZonePicker() {

    print(this.widget.timeZoneList[0].abbr);
    return this.widget.timeZoneList.map((timezone) =>
    Center(child: Text(timezone.abbr))).toList();
  }

  _showTimeZonePicker() {
    print (timezonetext.length);
    showModalBottomSheet(context: context, builder: (context) {
      return Container(
        child: CupertinoPicker(
          onSelectedItemChanged: (index) {
            timeZoneAbbr = this.widget.timeZoneList[index].abbr;
          },
          itemExtent: 32,
          children: timezonetext
        )
      );
    });
  }
  @override
  Widget build(BuildContext) {
    timezonetext = _populateTimeZonePicker();
    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Expanded(
          flex: 4,
            child: new FlatButton(
              onPressed: _showTimePicker,
              child: !_picked ? Text('Pick your time')
              : Text(_time.toString()),
         ),
          ),
        new Expanded(
          flex: 3,
            child: new FlatButton (
              onPressed: _showTimeZonePicker,
              child: Text('Pick time zone')
            ),
          ),
      ]
      ),
    );
    
  }
}

class Clock extends StatefulWidget {
  final Function callback;

  Clock(this.callback, { Key key} ) : super(key: key);
  
  @override 
  _ClockState createState() => _ClockState();
}

class _ClockState extends State<Clock> with SingleTickerProviderStateMixin {
  String _timeString;
  bool _showTime = true;
  bool shouldShow;


  void _getCurrentTime() {
    final String formattedDateTime = formatDateTime(DateTime.now());
    if (this.mounted && _showTime) {    
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

    return FlatButton(
          child: Text(_timeString),
          onPressed: () {
            this.widget.callback();
          },
    );   
  }
}