import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/models/reals.dart';
import 'package:skyreal/services/dio_service.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:table_calendar/table_calendar.dart';

class MemoriesPage extends StatefulWidget {
  @override
  _MemoriesPageState createState() => _MemoriesPageState();
}

class _MemoriesPageState extends State<MemoriesPage> {
  List<Color> _colorCollection = <Color>[];
  String? _networkStatusMsg;
  @override
  void initState() {
    _initializeEventColor();
    // _checkNetworkStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Memories'),
        ),
        body: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
          if (state is Loading) {
            // Showing the loading indicator while the user is signing in
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is Authenticated) {
            return FutureBuilder(
              future: getDataFromWeb(DioService().getApi(state)),
              builder: (BuildContext context,
                  AsyncSnapshot<List<RealMemory>?> snapshot) {
                print(snapshot.data);
                if (snapshot.data != null) {
                  return SafeArea(
                    child: Container(
                        child: SfCalendar(
                      view: CalendarView.month,
                      // initialDisplayDate: DateTime(2017, 6, 01, 9, 0, 0),
                      initialDisplayDate: DateTime.now(),
                      dataSource: MeetingDataSource(snapshot.data!),
                      monthViewSettings: const MonthViewSettings(
                          appointmentDisplayMode:
                              MonthAppointmentDisplayMode.appointment),

                      onTap: (calendarTapDetails) {
                        print(calendarTapDetails.appointments);
                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Container(
                                  height: 200,
                                  child: CachedNetworkImage(
                                    httpHeaders: {
                                      'Authorization':
                                          'Bearer ${state.authenticatedUser.accessToken}'
                                    },
                                    imageUrl: DioService.serverUrl +
                                        calendarTapDetails
                                            .appointments!.first.backPath +
                                        "?" +
                                        DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                    placeholder: (context, url) =>
                                        CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  ));
                            });
                      },
                      appointmentBuilder:
                          (context, calendarAppointmentDetails) {
                        return Container(
                          decoration: BoxDecoration(
                              color: _colorCollection[
                                  Random().nextInt(_colorCollection.length)],
                              borderRadius: BorderRadius.circular(4)),
                          // width: 100,
                          // height: 100,
                          child: Center(
                            // child: Text(
                            //   calendarAppointmentDetails
                            //       .appointments.first.eventName,
                            //   style: TextStyle(color: Colors.white),
                            // ),
                            child: CachedNetworkImage(
                              httpHeaders: {
                                'Authorization':
                                    'Bearer ${state.authenticatedUser.accessToken}'
                              },
                              imageUrl: DioService.serverUrl +
                                  calendarAppointmentDetails
                                      .appointments.first.frontPath +
                                  "?" +
                                  DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                        );
                      },
                      // appointmentBuilder:
                      //     (context, calendarAppointmentDetails) {
                      //   return Container(
                      //     decoration: BoxDecoration(
                      //         color: _colorCollection[
                      //             Random().nextInt(_colorCollection.length)],
                      //         borderRadius: BorderRadius.circular(4)),
                      //     child: calendarAppointmentDetails
                      //             .appointments.first.isAllDay
                      //         ? Text(
                      //             calendarAppointmentDetails
                      //                 .appointments.first.subject,
                      //             style: TextStyle(
                      //                 color: Colors.white,
                      //                 fontWeight: FontWeight.w600),
                      //           )
                      //         : Column(
                      //             mainAxisAlignment: MainAxisAlignment.center,
                      //             children: <Widget>[
                      //               Text(
                      //                 calendarAppointmentDetails
                      //                     .appointments.first.startTime.hour
                      //                     .toString(),
                      //                 style: TextStyle(
                      //                     color: Colors.white,
                      //                     fontWeight: FontWeight.w600),
                      //               ),
                      //               Text(
                      //                 calendarAppointmentDetails
                      //                     .appointments.first.startTime.minute
                      //                     .toString(),
                      //                 style: TextStyle(
                      //                     color: Colors.white,
                      //                     fontWeight: FontWeight.w600),
                      //               ),
                      //             ],
                      //           ),
                      //   );
                      // },
                    )),
                  );
                } else {
                  return Container(
                    child: Center(
                      child: Text('No data'),
                    ),
                  );
                }
              },
            );
          }
          if (state is UnAuthenticated) {
            return Center(
              child: Text('Unauthenticated'),
            );
          }
          return Container();
        }));
  }

  Future<List<RealMemory>?> getDataFromWeb(Dio dioService) async {
    var response = await dioService.get('reals/own/all');
    try {
      final Random random = new Random();

      if (response.statusCode == 200) {
        var data = response.data;
        if (data['success']) {
          List<RealMemory> meetings = data['data']['reals']
              .map<RealMemory>((real) => RealMemory.fromJson(real))
              .toList();
          return meetings;
        }
      }
      return [];
    } catch (e) {
      print(e);
      return [];
    }
  }

  // void _checkNetworkStatus() {
  //   _internetConnectivity.onConnectivityChanged
  //       .listen((ConnectivityResult result) {
  //     setState(() {
  //       _networkStatusMsg = result.toString();
  //       if (_networkStatusMsg == "ConnectivityResult.mobile") {
  //         _networkStatusMsg =
  //             "You are connected to mobile network, loading calendar data ....";
  //       } else if (_networkStatusMsg == "ConnectivityResult.wifi") {
  //         _networkStatusMsg =
  //             "You are connected to wifi network, loading calendar data ....";
  //       } else {
  //         _networkStatusMsg =
  //             "Internet connection may not be available. Connect to another network";
  void _initializeEventColor() {
    _colorCollection.add(const Color(0xFF0F8644));
    _colorCollection.add(const Color(0xFF8B1FA9));
    _colorCollection.add(const Color(0xFFD20100));
    _colorCollection.add(const Color(0xFFFC571D));
    _colorCollection.add(const Color(0xFF36B37B));
    _colorCollection.add(const Color(0xFF01A1EF));
    _colorCollection.add(const Color(0xFF3D4FB5));
    _colorCollection.add(const Color(0xFFE47C73));
    _colorCollection.add(const Color(0xFF636363));
    _colorCollection.add(const Color(0xFF0A8043));
  }
  //       }
  //     });
  //   });
  // }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<RealMemory> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].createdAt;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].createdAt;
  }

  @override
  String getSubject(int index) {
    return appointments![index].id.toString();
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].allDay;
  }
}

class RealMemory {
  int id;
  String frontPath;
  String backPath;
  DateTime createdAt;
  bool allDay = true;
  Color background;

  RealMemory({
    required this.id,
    required this.frontPath,
    required this.backPath,
    required this.createdAt,
    required this.allDay,
    required this.background,
  });

  factory RealMemory.fromJson(Map<String, dynamic> json) {
    return RealMemory(
      id: json['id'],
      frontPath: json['frontPath'],
      backPath: json['backPath'],
      createdAt: DateTime.parse(json['createdAt']),
      allDay: true,
      background: Colors.red,
    );
  }
}

// class Meeting {
//   Meeting(
//       {required this.eventName,
//       required this.from,
//       required this.to,
//       required this.frontPath,
//       required this.background,
//       this.allDay = false});

//   String eventName;
//   DateTime from;
//   DateTime to;
//   Color background;
//   String frontPath;
//   bool allDay;

//   // From json
//   factory Meeting.fromJson(Map<String, dynamic> json) {
//     return Meeting(
//       eventName: json['id'].toString(),
//       from: DateTime.parse(json['createdAt']),
//       to: DateTime.parse(json['createdAt'])
//           .add(Duration(hours: 1, minutes: 30, seconds: 0)),
//       frontPath: json['frontPath'],
//       //Random background color
//       background: Color((Random().nextDouble() * 0xFFFFFF).toInt()),
//       allDay: false,
//     );
//   }

//   bool isAllDay() => allDay;
// }
