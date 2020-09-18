import 'dart:io';

import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:datn/domain/model/location.dart';
import 'package:datn/domain/model/user.dart';
import 'package:datn/domain/repository/user_repository.dart';
import 'package:datn/env_manager.dart';
import 'package:datn/utils/error.dart';
import 'package:datn/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_disposebag/flutter_disposebag.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_provider/flutter_provider.dart';
import 'package:google_maps_webservice/places.dart' hide Location;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:rxdart/rxdart.dart';

import '../main_page.dart';

class LoginUpdateProfilePage extends StatefulWidget {
  static const routeName = '/login_profile_update';

  @override
  _LoginUpdateProfilePageState createState() => _LoginUpdateProfilePageState();
}

class _LoginUpdateProfilePageState extends State<LoginUpdateProfilePage>
    with SingleTickerProviderStateMixin, DisposeBagMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final formKey = GlobalKey<FormState>();

  AnimationController loginButtonController;
  Animation<double> buttonSqueezeAnimation;
  TextStyle textFieldStyle;

  final addressTextController = TextEditingController();
  final phoneNumberFocusNode = FocusNode();
  final addressFocusNode = FocusNode();

  String fullName;
  String phoneNumber;
  String address;
  DateTime birthday;
  var gender$ = BehaviorSubject.seeded(Gender.MALE);
  Location location;
  var avatarFile$ = BehaviorSubject<File>.seeded(null);
  var isLoading = false;

  final fullNameRegex = RegExp(r"^[\p{L} .'-]+$", unicode: true);
  final phoneNumberRegex = RegExp(
    r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();

    loginButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    buttonSqueezeAnimation = Tween(
      begin: 200.0,
      end: 70.0,
    ).animate(
      CurvedAnimation(
        parent: loginButtonController,
        curve: Interval(
          0.0,
          0.250,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    textFieldStyle ??= Theme.of(context)
        .textTheme
        .subtitle1
        .copyWith(fontSize: 15.0, color: Colors.white);
  }

  @override
  void dispose() {
    loginButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text('Update profile'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              constraints: BoxConstraints.expand(),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/login_update_profile.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.6),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              constraints: BoxConstraints.expand(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    const Color(0xffB881F9).withOpacity(0.58),
                    const Color(0xff545AE9).withOpacity(0.75),
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: [0, 0.68, 1],
                  begin: AlignmentDirectional.topEnd,
                  end: AlignmentDirectional.bottomStart,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: buildAvatar(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: buildFullNameTextField(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: buildPhoneNumber(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: buildAddressTextField(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: buildBirthDayTextField(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: buildGender(),
                      ),
                      const SizedBox(height: 12.0),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: buildSubmitButton(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAvatar() {
    const imageSize = 80.0;

    return InkWell(
      onTap: pickImage,
      child: Container(
        width: imageSize,
        height: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).backgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: Offset(2, 2),
              color: Colors.grey.shade600,
              spreadRadius: 2,
            )
          ],
        ),
        child: ClipOval(
          child: RxStreamBuilder<File>(
              stream: avatarFile$,
              builder: (context, snapshot) {
                final avatarFile = snapshot.data;

                if (avatarFile == null) {
                  return Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: imageSize * 0.7,
                    ),
                  );
                }

                return Image.file(
                  avatarFile,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                );
              }),
        ),
      ),
    );
  }

  Widget buildFullNameTextField() {
    return TextFormField(
      autocorrect: true,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: Icon(
            Icons.person,
            color: Colors.white,
          ),
        ),
        labelText: 'Full name',
        labelStyle: TextStyle(color: Colors.white),
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      keyboardType: TextInputType.name,
      maxLines: 1,
      style: textFieldStyle,
      onChanged: (v) => fullName = v,
      textInputAction: TextInputAction.next,
      autofocus: true,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(phoneNumberFocusNode),
      validator: (v) => fullNameRegex.hasMatch(v) ? null : 'Invalid full name',
    );
  }

  Widget buildPhoneNumber() {
    return TextFormField(
      autocorrect: true,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: Icon(
            Icons.phone,
            color: Colors.white,
          ),
        ),
        labelText: 'Phone number',
        labelStyle: TextStyle(color: Colors.white),
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      keyboardType: TextInputType.phone,
      maxLines: 1,
      style: textFieldStyle,
      onChanged: (v) => phoneNumber = v,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(addressFocusNode),
      focusNode: phoneNumberFocusNode,
      validator: (v) =>
          phoneNumberRegex.hasMatch(v) ? null : 'Invalid phone number',
    );
  }

  Widget buildAddressTextField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: addressTextController,
            autocorrect: true,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: Icon(
                  Icons.label,
                  color: Colors.white,
                ),
              ),
              labelText: 'Address',
              labelStyle: TextStyle(color: Colors.white),
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            keyboardType: TextInputType.streetAddress,
            maxLines: 1,
            style: textFieldStyle,
            onChanged: (v) => address = v,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(),
            focusNode: addressFocusNode,
            validator: (v) => v.isEmpty ? 'Empty address' : null,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          elevation: 2,
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Colors.white,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: IconButton(
              icon: Icon(Icons.location_on, color: Colors.white),
              onPressed: searchLocation,
            ),
          ),
        )
      ],
    );
  }

  Widget buildSubmitButton() {
    return AnimatedBuilder(
      animation: buttonSqueezeAnimation,
      child: MaterialButton(
        onPressed: () {
          FocusScope.of(context).requestFocus(FocusNode());
          onSubmit();
        },
        color: Theme.of(context).backgroundColor,
        child: Text(
          'UPDATE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
        splashColor: Theme.of(context).accentColor,
        elevation: 12,
      ),
      builder: (context, child) {
        final value = buttonSqueezeAnimation.value;

        return Container(
          width: value,
          height: 60.0,
          child: Material(
            elevation: 5.0,
            clipBehavior: Clip.antiAlias,
            shadowColor: Theme.of(context).accentColor,
            borderRadius: BorderRadius.circular(30.0),
            child: value > 75.0
                ? child
                : Center(
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
          ),
        );
      },
    );
  }

  Widget buildBirthDayTextField() {
    return DateTimeField(
      format: intl.DateFormat.yMMMd(),
      readOnly: true,
      onShowPicker: (context, currentValue) {
        return showDatePicker(
          context: context,
          firstDate: DateTime(1900),
          initialDate: currentValue ?? DateTime.now(),
          lastDate: DateTime(2100),
          selectableDayPredicate: (date) => date.isBefore(DateTime.now()),
        );
      },
      validator: (date) {
        if (date == null) {
          return null;
        }
        return date.isAfter(DateTime.now()) ? 'Invalid birthday' : null;
      },
      onChanged: (v) => birthday = v,
      resetIcon: Icon(Icons.delete, color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0),
          child: Icon(
            Icons.date_range,
            color: Colors.white,
          ),
        ),
        labelText: 'Birthday',
        labelStyle: TextStyle(color: Colors.white),
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      style: textFieldStyle,
    );
  }

  void onSubmit() async {
    if (isLoading) {
      return;
    }

    print('>>> Submit');
    print('fullName=$fullName');
    print('phoneNumber=$phoneNumber');
    print('address=$address');
    print('birthday=$birthday');
    print('gender=${gender$.value}');
    print('location=$location');
    print('avatar=${avatarFile$.value}');
    print('<<< Submit');

    final isValid = formKey.currentState?.validate() == true;

    if (!isValid) {
      scaffoldKey.showSnackBar('Invalid information');
      return;
    }

    try {
      isLoading = true;
      loginButtonController
        ..reset()
        ..forward();

      await Provider.of<UserRepository>(context).loginUpdateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        address: address,
        gender: gender$.value,
        location: location,
        birthday: birthday,
        avatarFile: avatarFile$.value,
      );
      scaffoldKey.showSnackBar('Update profile successfully');
      await Navigator.pushNamedAndRemoveUntil(
        context,
        MainPage.routeName,
        (route) => false,
      );
    } catch (e, s) {
      print('loginUpdateProfile $e $s');
      scaffoldKey.showSnackBar('Update profile failed: ${getErrorMessage(e)}');
    } finally {
      isLoading = false;
      loginButtonController.reverse();
    }
  }

  void searchLocation() async {
    try {
      final apiKey = EnvManager().get(EnvKey.PLACES_API_KEY);

      final prediction = await PlacesAutocomplete.show(
        context: context,
        apiKey: apiKey,
        mode: Mode.overlay,
        language: 'vi',
        components: [
          Component(
            Component.country,
            'VN',
          ),
        ],
      );

      if (prediction == null) {
        return;
      }

      final details = (await GoogleMapsPlaces(apiKey: apiKey)
              .getDetailsByPlaceId(prediction.placeId))
          .result;

      address = details.formattedAddress;
      location = Location((b) => b
        ..latitude = details.geometry.location.lat
        ..longitude = details.geometry.location.lng);

      addressTextController.text = address;
    } catch (e, s) {
      print('searchLocation $e $s');
    }
  }

  Widget buildGender() {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Colors.white.withOpacity(0.4),
      ),
      child: RxStreamBuilder<Gender>(
        stream: gender$,
        builder: (context, snapshot) {
          final gender = snapshot.data;

          return Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => gender$.add(Gender.MALE),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Radio<Gender>(
                        value: Gender.MALE,
                        groupValue: gender,
                        onChanged: gender$.add,
                      ),
                      Text('Male', style: textFieldStyle),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => gender$.add(Gender.FEMALE),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Radio<Gender>(
                        value: Gender.FEMALE,
                        groupValue: gender,
                        onChanged: gender$.add,
                      ),
                      Text('Female', style: textFieldStyle),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          );
        },
      ),
    );
  }

  void pickImage() async {
    final path = (await ImagePicker().getImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      maxHeight: 720,
    ))
        .path;
    avatarFile$.add(File(path));
  }
}