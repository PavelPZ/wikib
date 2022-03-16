import '../flutter_flow/flutter_flow_calendar.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../flutter_flow/flutter_flow_web_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class Page3Widget extends StatefulWidget {
  const Page3Widget({Key key}) : super(key: key);

  @override
  _Page3WidgetState createState() => _Page3WidgetState();
}

class _Page3WidgetState extends State<Page3Widget> {
  DateTimeRange calendarSelectedDay;
  bool checkboxListTileValue;
  bool switchListTileValue;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    calendarSelectedDay = DateTimeRange(
      start: DateTime.now().startOfDay,
      end: DateTime.now().endOfDay,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          FFLocalizations.of(context).getText(
            '84souwlk' /* Page Title */,
          ),
          style: FlutterFlowTheme.of(context).title2.override(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 22,
              ),
        ),
        actions: [],
        centerTitle: false,
        elevation: 2,
      ),
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              FlutterFlowCalendar(
                color: FlutterFlowTheme.of(context).primaryColor,
                weekFormat: false,
                weekStartsMonday: false,
                onChange: (DateTimeRange newSelectedDate) {
                  setState(() => calendarSelectedDay = newSelectedDate);
                },
                titleStyle: TextStyle(),
                dayOfWeekStyle: TextStyle(),
                dateStyle: TextStyle(),
                selectedDateStyle: TextStyle(),
                inactiveDateStyle: TextStyle(),
                locale: FFLocalizations.of(context).languageCode,
              ),
              Theme(
                data: ThemeData(
                  unselectedWidgetColor: Color(0xFF95A1AC),
                ),
                child: CheckboxListTile(
                  value: checkboxListTileValue ??= true,
                  onChanged: (newValue) =>
                      setState(() => checkboxListTileValue = newValue),
                  title: Text(
                    FFLocalizations.of(context).getText(
                      'gcgrj7ak' /* Title */,
                    ),
                    style: FlutterFlowTheme.of(context).title3,
                  ),
                  subtitle: Text(
                    FFLocalizations.of(context).getText(
                      'z18hjx2o' /* Subtitle */,
                    ),
                    style: FlutterFlowTheme.of(context).subtitle2,
                  ),
                  tileColor: Color(0xFFF5F5F5),
                  activeColor: FlutterFlowTheme.of(context).primaryColor,
                  dense: false,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              ),
              SwitchListTile(
                value: switchListTileValue ??= true,
                onChanged: (newValue) =>
                    setState(() => switchListTileValue = newValue),
                title: Text(
                  FFLocalizations.of(context).getText(
                    'vugxphq0' /* Title */,
                  ),
                  style: FlutterFlowTheme.of(context).title3,
                ),
                subtitle: Text(
                  FFLocalizations.of(context).getText(
                    'h9pccnrv' /* Subtitle */,
                  ),
                  style: FlutterFlowTheme.of(context).subtitle2,
                ),
                tileColor: Color(0xFFF5F5F5),
                dense: false,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              FlutterFlowWebView(
                url: 'https://flutter.dev',
                bypass: false,
                verticalScroll: false,
                horizontalScroll: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
