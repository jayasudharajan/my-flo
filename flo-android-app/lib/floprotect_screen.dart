import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:tinycolor/tinycolor.dart';
import 'model/flo.dart';
import 'model/locale.dart' as FloLocale;

import 'generated/i18n.dart';
import 'model/location.dart';
import 'model/unit_system.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'validations.dart';
import 'widgets.dart';

class FloProtectScreen extends StatefulWidget {
  FloProtectScreen({Key key}) : super(key: key);

  State<FloProtectScreen> createState() => _FloProtectScreenState();
}

class _FloProtectScreenState extends State<FloProtectScreen> with AfterLayoutMixin<FloProtectScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    _location = locationProvider.value;
  }

  Location _location;

  @override
  Widget build(BuildContext context) {
    final flo = Provider.of<FloNotifier>(context).value;
    final oauth = Provider.of<OauthTokenNotifier>(context, listen: false).value;
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final location = locationConsumer.value;

    return Scaffold(
          resizeToAvoidBottomPadding: true,
          body: Stack(children: <Widget>[
              FloGradientBackground(),
        SafeArea(child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                brightness: Brightness.dark,
                leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
                title: Text(ReCase(S.of(context).floprotect).titleCase),
                floating: true,
                centerTitle: true,
              ),
              SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20), sliver:
              SliverList(delegate: SliverChildListDelegate(<Widget>[
                    Row(children: [
                      Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(location.displayName , style: Theme.of(context).textTheme.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                              FlatButton(
                                padding: EdgeInsets.symmetric(vertical: 5),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                child: Row(children: <Widget>[
                                  Text((location?.subscription?.isActive ?? false) ? S.of(context).manage_your_account : S.of(context).activate_floprotect, overflow: TextOverflow.ellipsis),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                ),
                                onPressed: () async {
                                  await launch(
                                    (location?.subscription?.isActive ?? false) ? 'https://user.meetflo.com/floprotect?source_id=android&location=${location.id}'
                                    : 'https://user.meetflo.com/floprotect?plan_id=hp_c_5_ft&source_id=android&location=${location.id}',
                                    option: CustomTabsOption(
                                        toolbarColor: Theme.of(context).primaryColor,
                                        enableDefaultShare: true,
                                        enableUrlBarHiding: true,
                                        showPageTitle: true,
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                      ),
                      (location?.subscription?.isActive ?? false) ? FloProtectOn(onPressed: () async {
                        await launch(
                          'https://user.meetflo.com/floprotect?source_id=android&location=${location.id}',
                          option: CustomTabsOption(
                              toolbarColor: Theme.of(context).primaryColor,
                              enableDefaultShare: true,
                              enableUrlBarHiding: true,
                              showPageTitle: true,
                          ),
                        );
                      },) : FloProtectOff(onPressed: () async {
                        await launch(
                          'https://user.meetflo.com/floprotect?plan_id=hp_c_5_ft&source_id=android&location=${location.id}',
                          option: CustomTabsOption(
                              toolbarColor: Theme.of(context).primaryColor,
                              enableDefaultShare: true,
                              enableUrlBarHiding: true,
                              showPageTitle: true,
                          ),
                        );
                      }),
                    ],
                      crossAxisAlignment: CrossAxisAlignment.center,
                    ),
                SizedBox(height: 20,),
                //Icons.insert_chart
                // Icons.poll
                //ic_fixture.svg
                TextFieldButton(leading: Icon(Icons.poll, size: 18, color: floBlue),
                  text: S.of(context).fixture_detection,
                  onPressed: () {
                    // TODO: pushNamedClearTop('/fixtures');
                    Navigator.of(context).popUntil(ModalRoute.withName('/home'));
                    Navigator.of(context).pushNamed('/floprotect');
                    Navigator.of(context).pushNamed('/fixtures');
                    //Navigator.of(context).removeRouteBelow(ModalRoute.withName('/fixtures'));
                  },
                ),
                SizedBox(height: 15),
                TextFieldButton(leading: SvgPicture.asset('assets/ic_doc.svg'),
                    text: "Download ${DateTime.now().year} Letter for Insurance", // FIXME
                  onPressed: () async {
                    await launch(
                      'https://user.meetflo.com/floprotect/insurance-letter?source_id=android&location=${location.id}',
                      option: CustomTabsOption(
                          toolbarColor: Theme.of(context).primaryColor,
                          enableDefaultShare: true,
                          enableUrlBarHiding: true,
                          showPageTitle: true,
                      ),
                    );
                  },
                ),
                SizedBox(height: 15),
                TextFieldButton(leading: SvgPicture.asset('assets/ic_deductible.svg'),
                  text: S.of(context).amount_deductible_guarantee,
                  onPressed: () async {
                    await launch(
                      'https://user.meetflo.com/floprotect/deductible-guarantee?source_id=android&location=${location.id}',
                      option: CustomTabsOption(
                          toolbarColor: Theme.of(context).primaryColor,
                          enableDefaultShare: true,
                          enableUrlBarHiding: true,
                          showPageTitle: true,
                      ),
                    );
                  },
                ),
                SizedBox(height: 15),
                Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
                  margin: EdgeInsets.all(0),
                  color: Colors.white,
                  child: Padding(padding: EdgeInsets.all(25), child: Column(children: <Widget>[
                    Row(children: <Widget>[
                      Expanded(child: Column(children: <Widget>[
                        Text(S.of(context).water_concierge, style: Theme.of(context).textTheme.title, textScaleFactor: 0.9,),
                        SizedBox(height: 8),
                        Text(S.of(context).live_troubleshooting_support, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.black.withOpacity(0.5)), textScaleFactor: 0.9,),
                      ],
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                      )),
                      (location?.subscription?.isActive ?? false) ? OpenChatButton(padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                        onPressed: () {
                          final zendesk = Provider.of<ZendeskNotifier>(context, listen: false).value;
                          zendesk.startChat();
                        },
                      ) : FloActivateButton(),
                    ],
                    ),
                    SizedBox(height: 15),
                    Row(children: <Widget>[
                      (location?.subscription?.isActive ?? false) ? FloProtectActiveCircleAvatar(onPressed: () {}) : FloProtectInactiveCircleAvatar(onPressed: () {}),
                      SizedBox(width: 15),
                      Expanded(child: Container(
                        padding: EdgeInsets.all(10),
                        child: Text(S.of(context).water_concierge_alert_tip(""), style: TextStyle(color: Color(0xFF073F62).withOpacity(0.5))), // FIXME
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Color(0xFF073F62).withOpacity(0.1), offset: Offset(0, 5), blurRadius: 14)
                          ],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.zero,
                            topRight: Radius.circular(16.0),
                            bottomLeft: Radius.circular(16.0),
                            bottomRight: Radius.circular(16.0),
                          ),
                          border: Border.all(color: Color(0xFF073F62).withOpacity(0.1), width: 1),
                        ),
                      )),
                    ],
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                    ),
                  ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                  )),
                )))),
                SizedBox(height: 15),
                TextFieldButton(leading: SvgPicture.asset('assets/ic_floprotect_verified.svg'),
                    text: S.of(context).three_year_extended_warranty,
                    trailing: Container(),
                    onPressed: () async {
                      showDialog(context: context, builder: (context2) =>
                          Theme(data: floLightThemeData, child: Builder(builder: (context) => AlertDialog(
                            title: Text(S.of(context).extended_warranty),
                            content: Text(S.of(context).extended_warranty_explanation),
                            actions: <Widget>[
                              FlatButton(child: Text(S.of(context).got_it), onPressed: () {
                                Navigator.of(context2).pop();
                              },)
                            ],
                          )))
                      );
                    }
                ),
                SizedBox(height: 15),
                  ]),
              )),
              ]),
          )
    ])
    );
  }
}
