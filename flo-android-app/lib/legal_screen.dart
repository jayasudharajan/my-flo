
import 'package:after_layout/after_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:provider/provider.dart';
import 'model/flo.dart';

import 'generated/i18n.dart';
import 'providers.dart';
import 'widgets.dart';

class LegalScreen extends StatefulWidget {
  LegalScreen({Key key}) : super(key: key);

  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> with AfterLayoutMixin<LegalScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("");
    final floConsumer = Provider.of<FloNotifier>(context);
    final flo = floConsumer.value;
    //deviceConsumer.value = deviceConsumer.value.rebuild((b) => b..nickname = b.nickname ?? "Nickname 3/4 Flo Devic...");
    final Function wp = Screen(MediaQuery.of(context).size).wp;
    final Function hp = Screen(MediaQuery.of(context).size).hp;

    final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
    final deviceConsumer = Provider.of<DeviceNotifier>(context);
    final userConsumer = Provider.of<UserNotifier>(context);

    final child = 
      Scaffold(
        appBar: AppBar(
          brightness: Brightness.dark,
          leading: SimpleBackButton(icon: Icon(Icons.arrow_back_ios)),
          elevation: 0.0,
          title: Text(S.of(context).legal_and_policies, style: Theme.of(context).textTheme.title),
          centerTitle: true,
        ),
        resizeToAvoidBottomPadding: true,
        body:
        Stack(children: <Widget>[
            FloGradientBackground(),
        SingleChildScrollView(child: Column(children: <Widget>[
          /*
              Send to Zendesk article link with appopriate localized language (link will change based on set language in app):

              Current English Zendesk Articles: Terms of Service: https://support.meetflo.com/hc/en-us/articles/230089687-Terms-of-Service
              Privacy Statement: https://support.meetflo.com/hc/en-us/articles/230425728-Privacy-Statement
              Limited Warranty: https://support.meetflo.com/hc/en-us/articles/230089707-Limited-Warranty
              End User License Agreement: https://support.meetflo.com/hc/en-us/articles/230425668-End-User-License-Agreement
            */
          SizedBox(height: 16),
          Container(width: double.infinity, height: 1, color: Colors.white.withOpacity(0.2)),
          ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            title: Text(S.of(context).terms_of_services, style: Theme.of(context).textTheme.title),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white),
            onTap: () async {
              await launch(
                'https://support.meetflo.com/hc/en-us/articles/230089687-Terms-of-Service',
                option: CustomTabsOption(
                    toolbarColor: Theme.of(context).primaryColor,
                    enableDefaultShare: true,
                    enableUrlBarHiding: true,
                    showPageTitle: true,
                    //animation: CustomTabsAnimation.slideIn()
                ),
              );
            },
          ),
          Container(width: double.infinity, height: 1, color: Colors.white.withOpacity(0.2)),
          ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            title: Text(S.of(context).privacy_statement, style: Theme.of(context).textTheme.title),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white),
            onTap: () async {
              await launch(
                'https://support.meetflo.com/hc/en-us/articles/230425728-Privacy-Statement',
                option: CustomTabsOption(
                    toolbarColor: Theme.of(context).primaryColor,
                    enableDefaultShare: true,
                    enableUrlBarHiding: true,
                    showPageTitle: true,
                    //animation: CustomTabsAnimation.slideIn()
                ),
              );
            },
          ),
          Container(width: double.infinity, height: 1, color: Colors.white.withOpacity(0.2)),
          ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            title: Text(S.of(context).limited_warranty, style: Theme.of(context).textTheme.title),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white),
            onTap: () async {
              await launch(
                'https://support.meetflo.com/hc/en-us/articles/230089707-Limited-Warranty',
                option: CustomTabsOption(
                    toolbarColor: Theme.of(context).primaryColor,
                    enableDefaultShare: true,
                    enableUrlBarHiding: true,
                    showPageTitle: true,
                    //animation: CustomTabsAnimation.slideIn()
                ),
              );
            },
          ),
          Container(width: double.infinity, height: 1, color: Colors.white.withOpacity(0.2)),
          ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            title: Text(S.of(context).end_user_license_agreement, style: Theme.of(context).textTheme.title),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white),
            onTap: () async {
              await launch(
                'https://support.meetflo.com/hc/en-us/articles/230425668-End-User-License-Agreement',
                option: CustomTabsOption(
                    toolbarColor: Theme.of(context).primaryColor,
                    enableDefaultShare: true,
                    enableUrlBarHiding: true,
                    showPageTitle: true,
                    //animation: CustomTabsAnimation.slideIn()
                ),
              );
            },
          ),
          Container(width: double.infinity, height: 1, color: Colors.white.withOpacity(0.2)),
        ],
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        )
        ),
          ])
      );

    return flo is FloMocked ? Banner(
              message: "          DEMO",
              location: BannerLocation.topEnd,
              child: child) : child;
  }

  @override
  void afterFirstLayout(BuildContext context) {
    // TODO: implement afterFirstLayout
  }
}
