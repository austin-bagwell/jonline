import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list_2/implicitly_animated_reorderable_list_2.dart';
import 'package:implicitly_animated_reorderable_list_2/transitions.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/authentication.pb.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/models/server_errors.dart';
import 'package:jonline/screens/home_page.dart';
import 'package:jonline/screens/user-data/data_collector.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  UserData? userData;
  List<JonlineAccount> accounts = [];
  AppState get appState => context.findRootAncestorStateOfType<AppState>()!;
  HomePageState get homePage =>
      context.findRootAncestorStateOfType<HomePageState>()!;

  @override
  void initState() {
    super.initState();
    homePage.showSettingsTabListener.addListener(onSettingsTabChanged);
    appState.accounts.addListener(onAccountsChanged);
  }

  @override
  dispose() {
    homePage.showSettingsTabListener.removeListener(onSettingsTabChanged);
    appState.accounts.removeListener(onAccountsChanged);
    super.dispose();
  }

  onSettingsTabChanged() {
    setState(() {});
  }

  onAccountsChanged() async {
    // await Future.delayed(const Duration(seconds: 1));
    print("onAccountsChanged");
    setState(() {
      accounts = appState.accounts.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: ElevatedButton(
                    onPressed: () {
                      context.navigateNamedTo('/login');
                    },
                    child: const Text(
                      'Login/Create Account…',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // const SizedBox(width: 8),
                Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () {
                        appState.updateAccountList();
                      },
                      child: const Icon(Icons.refresh),
                    )),
                // const SizedBox(width: 8),
                Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: const Text('Really delete all accoounts?'),
                            action: SnackBarAction(
                              label:
                                  'Delete all', // or some operation you would like
                              onPressed: () async {
                                await JonlineAccount.updateAccountList([]);
                                appState.updateAccountList();
                              },
                            )));
                      },
                      child: const Icon(Icons.delete_forever),
                    )),
                // const SizedBox(width: 8),
                Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () {
                        if (!homePage.showSettingsTab) {
                          setState(() {
                            homePage.showSettingsTab = true;
                          });
                          Future.delayed(const Duration(milliseconds: 100), () {
                            context.navigateNamedTo('settings/main');
                          });
                        } else {
                          setState(() {
                            homePage.showSettingsTab = false;
                          });
                        }
                      },
                      child: Stack(
                        children: [
                          const Icon(Icons.settings),
                          Transform.translate(
                            offset: const Offset(20, 0),
                            child: Icon(homePage.showSettingsTab
                                ? Icons.close
                                : Icons.arrow_right),
                          ),
                        ],
                      ),
                    )),
                // const SizedBox(width: 8)
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Stack(
                children: [
                  buildList(),
                  AnimatedOpacity(
                    opacity: accounts.isEmpty ? 1.0 : 0.0,
                    duration: animationDuration,
                    child: IgnorePointer(
                      child: Center(
                        child: Text(
                          'No Accounts Created',
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildList() {
    return ImplicitlyAnimatedReorderableList<JonlineAccount>(
      items: accounts,
      areItemsTheSame: (a, b) => a.id == b.id,
      onReorderFinished: (item, from, to, newItems) {
        JonlineAccount.updateAccountList(newItems);
      },
      itemBuilder: (context, animation, account, index) {
        return Reorderable(
          key: ValueKey(account.id),
          builder: (context, dragAnimation, inDrag) => SizeFadeTransition(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: animation,
              child: SizedBox(
                height: 100,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                account.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "User ID: ${account.user_id}",
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text('Server: ${account.server}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    children: [
                                      const Text('Refresh Token: ',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Expanded(
                                        child: Text(account.refreshToken,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 32,
                                    child: TextButton(
                                        style: ButtonStyle(
                                            padding: MaterialStateProperty.all(
                                                const EdgeInsets.all(0))),
                                        // padding: const EdgeInsets.all(0),
                                        onPressed: null, //() {},
                                        child: const Icon(Icons.info)),
                                  ),
                                ),
                                Expanded(
                                  child: SizedBox(
                                    height: 32,
                                    child: TextButton(
                                        style: ButtonStyle(
                                            padding: MaterialStateProperty.all(
                                                const EdgeInsets.all(0))),
                                        // padding: const EdgeInsets.all(0),
                                        onPressed: () async {
                                          await account.updateRefreshToken(
                                              showMessage: showSnackBar);
                                          showSnackBar(
                                              'Refresh token updated.');
                                          await account.updateUserData(
                                              showMessage: showSnackBar);
                                          showSnackBar('User details updated.');
                                          appState.updateAccountList();
                                        },
                                        child: const Icon(Icons.refresh)),
                                  ),
                                ),
                                Expanded(
                                    child: SizedBox(
                                        height: 32,
                                        child: TextButton(
                                            style: ButtonStyle(
                                                padding:
                                                    MaterialStateProperty.all(
                                                        const EdgeInsets.all(
                                                            0))),
                                            // padding: const EdgeInsets.all(0),
                                            onPressed: () {
                                              ScaffoldMessenger.of(context)
                                                  .hideCurrentSnackBar();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          'Really delete ${account.server}/${account.username}?'),
                                                      action: SnackBarAction(
                                                        label:
                                                            'Delete', // or some operation you would like
                                                        onPressed: () async {
                                                          await account
                                                              .delete();
                                                          setState(() {
                                                            appState
                                                                .updateAccountList();
                                                          });
                                                        },
                                                      )));
                                            },
                                            child: const Icon(Icons.delete))))
                              ],
                            )
                          ],
                        ),
                        trailing: Transform.translate(
                          offset: const Offset(0, -13),
                          child: const Handle(
                            delay: Duration(milliseconds: 100),
                            child: Icon(
                              Icons.menu,
                              color: Colors.grey,
                            ),
                          ),
                        )),
                  ),
                ),
              )),
        );
      },
    );
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
