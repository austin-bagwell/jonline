import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/jonline_state.dart';
import 'package:jonline/my_platform.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../models/settings.dart';

class SettingsPage extends StatefulWidget {
  final String tab;
  final String query;

  const SettingsPage({
    Key? key,
    @pathParam required this.tab,
    @queryParam this.query = 'none',
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends JonlineState<SettingsPage>
    with AutoRouteAwareStateMixin<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(
                      top: 16 + mq.padding.top,
                      left: 8.0,
                      right: 8.0,
                      bottom: 8 + mq.padding.bottom),
                  child: Center(
                      child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        Text('App Settings', style: textTheme.titleMedium),
                        Row(
                          children: [
                            Expanded(
                                child: Text('Always Show "Settings" Tab',
                                    style: textTheme.labelLarge)),
                            Switch(
                                activeColor: appState.primaryColor,
                                value: Settings.showSettingsTab,
                                onChanged: (v) {
                                  setState(() => Settings.showSettingsTab = v);
                                  // appState
                                  //   ..updatePosts()
                                  //   ..notifyAccountsListeners();
                                }),
                          ],
                        ),
                        const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Swipe right of "Me" to access "Settings" at any time.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12),
                            )),
                        Row(
                          children: [
                            Expanded(
                                child: Text('Always Show "People" Tab',
                                    style: textTheme.labelLarge)),
                            Switch(
                                activeColor: appState.primaryColor,
                                value: Settings.showPeopleTab,
                                onChanged: (v) {
                                  setState(() => Settings.showPeopleTab = v);
                                  // appState
                                  //   ..updatePosts()
                                  //   ..notifyAccountsListeners();
                                }),
                          ],
                        ),
                        const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Swipe left of "Posts" to access "People" at any time.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12),
                            )),
                        Row(
                          children: [
                            Expanded(
                                child: Text('Always Show "Groups" Tab',
                                    style: textTheme.labelLarge)),
                            Switch(
                                activeColor: appState.primaryColor,
                                value: Settings.showGroupsTab,
                                onChanged: (v) {
                                  setState(() => Settings.showGroupsTab = v);
                                  // appState
                                  //   ..updatePosts()
                                  //   ..notifyAccountsListeners();
                                }),
                          ],
                        ),
                        const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Swipe left of "People" to access "Groups" at any time.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12),
                            )),
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                                    'Automatically Collapse Side Navigation',
                                    style: textTheme.labelLarge)),
                            Switch(
                                activeColor: appState.primaryColor,
                                value: !Settings.keepSideNavExpanded,
                                onChanged: (v) {
                                  setState(
                                      () => Settings.keepSideNavExpanded = !v);
                                  // appState
                                  //   ..updatePosts()
                                  //   ..notifyAccountsListeners();
                                }),
                          ],
                        ),
                        const SizedBox(height: 25),
                        Text('Performance Settings',
                            style: textTheme.titleMedium),
                        Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async => await launchUrl(Uri.parse(
                                  'https://github.com/flutter/flutter/issues/103847')),
                              child: const Text(
                                'The startup sequence seems to improve performance on iOS. The issue it corrects for is described at https://github.com/flutter/flutter/issues/103847',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12),
                              ),
                            )),
                        Row(
                          children: [
                            Expanded(
                                child: Text("Reply Layers to Load",
                                    style: textTheme.labelLarge)),
                            if (MediaQuery.of(context).size.width > 450)
                              Slider(
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  value: Settings.replyLayersToLoad.toDouble(),
                                  onChanged: (v) {
                                    setState(() =>
                                        Settings.replyLayersToLoad = v.toInt());
                                  }),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 16.0),
                                child: Text(
                                  Settings.replyLayersToLoad.toString(),
                                  style: textTheme.labelLarge,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5)
                          ],
                        ),
                        if (MediaQuery.of(context).size.width <= 450)
                          Row(
                            children: [
                              const Expanded(child: SizedBox()),
                              Slider(
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  value: Settings.replyLayersToLoad.toDouble(),
                                  onChanged: (v) {
                                    setState(() =>
                                        Settings.replyLayersToLoad = v.toInt());
                                  }),
                            ],
                          ),
                        const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Higher values mean comments take longer to load.",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12),
                            )),
                        const SizedBox(height: 35),
                        Text('Advanced Settings', style: textTheme.titleMedium),
                        Row(
                          children: [
                            Expanded(
                                child: Text("Prefer Server Previews",
                                    style: textTheme.labelLarge)),
                            Switch(
                                activeColor: appState.primaryColor,
                                value: Settings.preferServerPreviews,
                                onChanged: (v) {
                                  setState(
                                      () => Settings.preferServerPreviews = v);
                                  appState
                                    ..posts.update()
                                    ..notifyAccountsListeners();
                                }),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text("Force Server Previews",
                                    style: textTheme.labelLarge)),
                            Switch(
                                activeColor: appState.primaryColor,
                                value: Settings.forceServerPreviews,
                                onChanged: (v) {
                                  setState(
                                      () => Settings.forceServerPreviews = v);
                                  appState
                                    ..posts.update()
                                    ..notifyAccountsListeners();
                                }),
                          ],
                        ),
                        const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Server previews are useful for browsers due to CORS. There is no reason for browsers to ever use client previews.",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12),
                            )),
                        const SizedBox(height: 4),
                        Row(
                          key: const Key('powerUserModeSetting'),
                          children: [
                            Expanded(
                                child: Text("Power User Mode",
                                    style: textTheme.labelLarge)),
                            Switch(
                                activeColor: appState.primaryColor,
                                value: Settings.powerUserMode,
                                onChanged: (v) {
                                  setState(() => Settings.powerUserMode = v);
                                  appState.notifyAccountsListeners();
                                }),
                          ],
                        ),
                        Row(
                          key: const Key('devModeSetting'),
                          children: [
                            Expanded(
                                child: Text("Developer Mode",
                                    style: textTheme.labelLarge)),
                            Switch(
                                activeColor: appState.primaryColor,
                                value: Settings.developerMode,
                                onChanged: (v) {
                                  setState(() => Settings.developerMode = v);
                                  context
                                      .findRootAncestorStateOfType<AppState>()!
                                      .notifyAccountsListeners();
                                }),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text("Sidebar Top Padding",
                                    style: textTheme.labelLarge)),
                            if (MediaQuery.of(context).size.width > 450)
                              Slider(
                                  min: 0,
                                  max: 100,
                                  divisions: 100,
                                  value: Settings.sidebarTopPadding.toDouble(),
                                  onChanged: (v) {
                                    setState(() =>
                                        Settings.sidebarTopPadding = v.toInt());
                                  }),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 16.0),
                                child: Text(
                                  Settings.sidebarTopPadding.toString(),
                                  style: textTheme.labelLarge,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5)
                          ],
                        ),
                      ],
                    ),
                  )),
                )),
          ),
        ],
      ),
    );
  }

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {
    // print('init tab route from ${previousRoute?.name}');
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    // print('did change tab route from ${previousRoute.name}');
  }
}
