import '../flutter_flow/flutter_flow_choice_chips.dart';
import '../flutter_flow/flutter_flow_count_controller.dart';
import '../flutter_flow/flutter_flow_credit_card_form.dart';
import '../flutter_flow/flutter_flow_place_picker.dart';
import '../flutter_flow/flutter_flow_radio_button.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../flutter_flow/flutter_flow_widgets.dart';
import '../flutter_flow/place.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Page7Widget extends StatefulWidget {
  const Page7Widget({Key key}) : super(key: key);

  @override
  _Page7WidgetState createState() => _Page7WidgetState();
}

class _Page7WidgetState extends State<Page7Widget> {
  String choiceChipsValue;
  String radioButtonValue;
  double ratingBarValue;
  final creditCardFormKey = GlobalKey<FormState>();
  CreditCardModel creditCardInfo = emptyCreditCard();
  int countControllerValue;
  var placePickerValue = FFPlace();
  double sliderValue;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          FFLocalizations.of(context).getText(
            'm11a5iqh' /* Page Title */,
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
              FlutterFlowRadioButton(
                options: [
                  FFLocalizations.of(context).getText(
                    'gtufrjh5' /* Option 1 */,
                  )
                ],
                onChanged: (value) {
                  setState(() => radioButtonValue = value);
                },
                optionHeight: 25,
                textStyle: FlutterFlowTheme.of(context).bodyText1.override(
                      fontFamily: 'Poppins',
                      color: Colors.black,
                    ),
                buttonPosition: RadioButtonPosition.left,
                direction: Axis.vertical,
                radioButtonColor: Colors.blue,
                inactiveRadioButtonColor: Color(0x8A000000),
                toggleable: false,
                horizontalAlignment: WrapAlignment.start,
                verticalAlignment: WrapCrossAlignment.start,
              ),
              RatingBar.builder(
                onRatingUpdate: (newValue) =>
                    setState(() => ratingBarValue = newValue),
                itemBuilder: (context, index) => Icon(
                  Icons.star_rounded,
                  color: FlutterFlowTheme.of(context).secondaryColor,
                ),
                direction: Axis.horizontal,
                initialRating: ratingBarValue ??= 3,
                unratedColor: Color(0xFF9E9E9E),
                itemCount: 5,
                itemSize: 40,
                glowColor: FlutterFlowTheme.of(context).secondaryColor,
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
                child: FlutterFlowCreditCardForm(
                  formKey: creditCardFormKey,
                  creditCardModel: creditCardInfo,
                  obscureNumber: true,
                  obscureCvv: false,
                  spacing: 10,
                  textStyle: GoogleFonts.getFont(
                    'Roboto',
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                  inputDecoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF9E9E9E),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF9E9E9E),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Container(
                width: 160,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  shape: BoxShape.rectangle,
                  border: Border.all(
                    color: Color(0xFF9E9E9E),
                    width: 1,
                  ),
                ),
                child: FlutterFlowCountController(
                  decrementIconBuilder: (enabled) => FaIcon(
                    FontAwesomeIcons.minus,
                    color: enabled ? Color(0xDD000000) : Color(0xFFEEEEEE),
                    size: 20,
                  ),
                  incrementIconBuilder: (enabled) => FaIcon(
                    FontAwesomeIcons.plus,
                    color: enabled ? Colors.blue : Color(0xFFEEEEEE),
                    size: 20,
                  ),
                  countBuilder: (count) => Text(
                    count.toString(),
                    style: GoogleFonts.getFont(
                      'Roboto',
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  count: countControllerValue ??= 0,
                  updateCount: (count) =>
                      setState(() => countControllerValue = count),
                  stepSize: 1,
                ),
              ),
              FlutterFlowChoiceChips(
                initiallySelected: [choiceChipsValue],
                options: [
                  ChipData(
                      FFLocalizations.of(context).getText(
                        'cllogn5z' /* Option 1 */,
                      ),
                      Icons.train_outlined)
                ],
                onChanged: (val) =>
                    setState(() => choiceChipsValue = val.first),
                selectedChipStyle: ChipStyle(
                  backgroundColor: Color(0xFF323B45),
                  textStyle: FlutterFlowTheme.of(context).bodyText1.override(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                  iconColor: Colors.white,
                  iconSize: 18,
                  elevation: 4,
                ),
                unselectedChipStyle: ChipStyle(
                  backgroundColor: Colors.white,
                  textStyle: FlutterFlowTheme.of(context).bodyText2.override(
                        fontFamily: 'Poppins',
                        color: Color(0xFF323B45),
                      ),
                  iconColor: Color(0xFF323B45),
                  iconSize: 18,
                  elevation: 4,
                ),
                chipSpacing: 20,
                multiselect: false,
              ),
              FlutterFlowPlacePicker(
                iOSGoogleMapsApiKey: '',
                androidGoogleMapsApiKey: '',
                webGoogleMapsApiKey: '',
                onSelect: (place) => setState(() => placePickerValue = place),
                defaultText: FFLocalizations.of(context).getText(
                  's3avr3zp' /* Select Location */,
                ),
                icon: Icon(
                  Icons.place,
                  color: Colors.white,
                  size: 16,
                ),
                buttonOptions: FFButtonOptions(
                  width: 200,
                  height: 40,
                  color: FlutterFlowTheme.of(context).primaryColor,
                  textStyle: FlutterFlowTheme.of(context).subtitle2.override(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                  borderSide: BorderSide(
                    color: Colors.transparent,
                    width: 1,
                  ),
                  borderRadius: 12,
                ),
              ),
              Slider(
                activeColor: FlutterFlowTheme.of(context).primaryColor,
                inactiveColor: Color(0xFF9E9E9E),
                min: 0,
                max: 10,
                value: sliderValue ??= 0,
                onChanged: (newValue) {
                  setState(() => sliderValue = newValue);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
