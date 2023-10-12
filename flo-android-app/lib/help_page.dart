import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:faker/faker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:flutter_responsive_screen/flutter_responsive_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:recase/recase.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tinycolor/tinycolor.dart';

import 'generated/i18n.dart';
import 'model/alarm.dart';
import 'model/alert.dart';
import 'model/alerts.dart';
import 'model/device.dart';
import 'model/flo.dart';
import 'providers.dart';
import 'themes.dart';
import 'utils.dart';
import 'widgets.dart';


class HelpPage extends StatefulWidget {
  HelpPage({Key key}) : super(key: key);

  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> with SingleTickerProviderStateMixin, AfterLayoutMixin<HelpPage> {

  ScrollController _scrollController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    Future.delayed(Duration.zero, () async {
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationConsumer = Provider.of<CurrentLocationNotifier>(context);
    final location = locationConsumer.value;
    Widget body = CustomScrollView(
      key: widget.key,
      controller: _scrollController,
      slivers: <Widget>[
        SliverAppBar(
          leading: SimpleDrawerButton(icon: SvgPicture.asset('assets/ic_fancy_menu.svg')),
          floating: true,
          title: Text(S.of(context).help_center, textScaleFactor: 1.3,),
          centerTitle: true,
        ),
        SliverPadding(padding: EdgeInsets.symmetric(vertical: 5)),
        SliverList(delegate: SliverChildListDelegate([
          Stack(children: [
            Theme(data: floLightThemeData, child: Builder(builder: (context) => SizedBox(width: double.infinity, child: Card(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 16.0),
              color: Colors.white,
              child: Padding(padding: EdgeInsets.only(left: 40, top: 23, bottom: 23, right: 23), child: Column(children: <Widget>[
                Row(children: <Widget>[
                  Expanded(child: Column(children: <Widget>[
                    Text(S.of(context).water_concierge, style: Theme.of(context).textTheme.title, textScaleFactor: 0.9,),
                    SizedBox(height: 8),
                    Text(S.of(context).live_troubleshooting_support, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.black.withOpacity(0.5)), textScaleFactor: 0.9,),
                  ],
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                  )),
                  (location?.subscription?.isActive ?? false) ? OpenButton(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    onPressed: () {
                      final zendesk = Provider.of<ZendeskNotifier>(context, listen: false).value;
                      zendesk.startChat();
                    },
                  ) : FloActivateButton(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/floprotect');
                    },
                  ),
                ],
                ),
              ],
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
              )),
            )))),
                Padding(
                  padding: EdgeInsets.only(left: 3),
                  child:
            (location?.subscription?.isActive ?? false) ? FloProtectCircleAvatar(
                    radius: 21,
                    padding: EdgeInsets.all(5),
                    color: floSecondaryButtonColor
                ) : FloProtectCircleAvatar(
                    radius: 21,
                    padding: EdgeInsets.all(5),
                ),
                ),
          ],
            alignment: AlignmentDirectional.centerStart,
          ),
          SizedBox(height: 13),
          /*
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child:
              TextFieldButton(child: Text(S.of(context).search_support_articles, style: Theme.of(context).textTheme.subhead.copyWith(color: floBlue.withOpacity(0.5))),
                trailing: Icon(Icons.search, color: floBlue),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                onPressed: () async {
                  await launch(
                    'https://user.meetflo.com/mobile/support/android',
                    option: CustomTabsOption(
                        toolbarColor: Theme.of(context).primaryColor,
                        enableDefaultShare: true,
                        enableUrlBarHiding: true,
                        showPageTitle: true,
                        ////animation: CustomTabsAnimation.slideIn()
                    ),
                  );
                },
              )),
          SizedBox(height: 15),
          */
          Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child:
          TextFieldButton(child: Text(S.of(context).view_support_articles, style: Theme.of(context).textTheme.subhead.copyWith(color: floBlue)),
            trailing: Icon(Icons.arrow_forward_ios, size: 18, color: floBlue),
            onPressed: () async {
            try {
              if (false) {
                /// W/ActivityThread( 2443): handleWindowVisibility: no activity for token android.os.BinderProxy@b343f8b
              final zendesk = Provider.of<ZendeskNotifier>(context, listen: false).value;
              await zendesk.initSupport(
                appId: '0fe78e8f35578950e1bb77cbb2bf4d6603b6bc7503886c00',
                clientId: 'mobile_sdk_client_b85943e42693853258f5',
                url: 'https://meetflo.zendesk.com',
              );
              await zendesk.showHelpCenter();
              } else {
              await launch(
                S.of(context).help_center_url2,
                option: CustomTabsOption(
                    toolbarColor: Theme.of(context).primaryColor,
                    enableDefaultShare: true,
                    enableUrlBarHiding: true,
                    showPageTitle: true,
                ),
              );
              }
            } catch (err) {
              Fimber.e("", ex: err);
            }
            },
          )),
          SizedBox(height: 13),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child:
              TextFieldButton(child: Text(ReCase(S.of(context).contact_us).titleCase, style: Theme.of(context).textTheme.subhead.copyWith(color: floBlue)),
                trailing: Icon(Icons.arrow_forward_ios, size: 18, color: floBlue),
                onPressed: () async {
                  try {
                    // https
                    await launch(
                      "https://support.meetflo.com/hc/en-us/requests/new",
                      option: CustomTabsOption(
                        toolbarColor: Theme.of(context).primaryColor,
                        enableDefaultShare: true,
                        enableUrlBarHiding: true,
                        showPageTitle: true,
                      ),
                    );
                  } catch (err) {
                    Fimber.e("", ex: err);
                  }
                },
              )),
          SizedBox(height: 13),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child:
              TextFieldButton(child: Text(ReCase(S.of(context).view_setup_guides).titleCase, style: Theme.of(context).textTheme.subhead.copyWith(color: floBlue)),
                trailing: Icon(Icons.arrow_forward_ios, size: 18, color: floBlue),
                onPressed: () async {
                  try {
                    // https
                    await launch(
                      "https://support.meetflo.com/hc/en-us/articles/360018822954-Setup-Guide-for-Flo-by-Moen-Device",
                      option: CustomTabsOption(
                        toolbarColor: Theme.of(context).primaryColor,
                        enableDefaultShare: true,
                        enableUrlBarHiding: true,
                        showPageTitle: true,
                      ),
                    );
                  } catch (err) {
                    Fimber.e("", ex: err);
                  }
                },
              )),
        ])),
        SliverPadding(padding: EdgeInsets.symmetric(vertical: 15)),
      ],
    );

    /*
    body = SmartRefresher(
        controller: _refreshController,
        //enableTwoLevel: true,
        onRefresh: () async {
          final locationProvider = Provider.of<CurrentLocationNotifier>(context, listen: false);
          locationProvider.value = locationProvider.value.rebuild((b) => b..dirty = true);
          locationProvider.invalidate();
          //await Future.delayed(Duration(milliseconds: 500));
          //_scrollController.animateTo(_scrollController.position.minScrollExtent, duration: null, curve: null);
          //_refreshController.refreshCompleted();
        },
        child: body
    );
    */

    return Builder(builder: (context) => SafeArea(child: body));
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Fimber.d("");
  }
}

class SimpleSliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  SimpleSliverPersistentHeaderDelegate({
      @required this.minHeight,
      @required this.maxHeight,
      @required this.child,
      }) : super();
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(child: SizedBox.expand(child: child), elevation: shrinkOffset != 0 ? 8 : 0);
  }

  @override
  bool shouldRebuild(SimpleSliverPersistentHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
