import 'package:flutter/material.dart';

import 'generated/i18n.dart';
import 'themes.dart';
import 'widgets.dart';

class TermsScreen extends StatefulWidget {
  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  @override
  Widget build(BuildContext context) {
    return Theme(
        data: floLightThemeData,
        child:
        Scaffold(
            appBar: AppBar(title: Text(S.of(context).terms_and_conditions,
                style: TextStyle(color: floPrimaryColor)),
                //automaticallyImplyLeading: true,
                leading: Builder(builder: (context) => SimpleBackButton(icon: Icon(Icons.arrow_back_ios))),
                iconTheme: IconThemeData(
                  color: floBlue2,
                ),
                backgroundColor: Colors.transparent,
                elevation: 0.0,
                centerTitle: true
            ),
            body: FutureBuilder(
                future: DefaultAssetBundle.of(context).loadString('assets/terms.html'), builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SingleChildScrollView(
                    child: Padding(
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: Text(
                          snapshot.data,
                          /*
                onLinkTap: (url) {
                  Fimber.d("Opening $url...");
                },
                */
                          /*
                customRender: (node, children) {
                  if (node is dom.Element) {
                    switch (node.localName) {
                      case "custom_tag": // using this, you can handle custom tags in your HTML
                        return Column(children: children);
                    }
                  }
                },
                */
                        ))
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            })
        ));
  }
}

