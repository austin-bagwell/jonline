import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/models/jonline_account.dart';

// import 'package:jonline/db.dart';

class AccountChooser extends StatefulWidget {
  const AccountChooser({
    Key? key,
  }) : super(key: key);

  @override
  AccountChooserState createState() => AccountChooserState();
}

class AccountChooserState extends State<AccountChooser> {
  late AppState appState;
  TextTheme get textTheme => Theme.of(context).textTheme;

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    appState.accounts.addListener(onAccountsChanged);
  }

  @override
  dispose() {
    appState.accounts.removeListener(onAccountsChanged);
    super.dispose();
  }

  onAccountsChanged() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72 * MediaQuery.of(context).textScaleFactor,
      child: TextButton(
        style: ButtonStyle(
            padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
            foregroundColor:
                MaterialStateProperty.all(Colors.white.withAlpha(100)),
            overlayColor:
                MaterialStateProperty.all(Colors.white.withAlpha(100)),
            splashFactory: InkSparkle.splashFactory),
        onPressed: () {
          // HapticFeedback.lightImpact();
          final RenderBox button = context.findRenderObject() as RenderBox;
          final RenderBox? overlay =
              Overlay.of(context)?.context.findRenderObject() as RenderBox?;
          final RelativeRect position = RelativeRect.fromRect(
            Rect.fromPoints(
              button.localToGlobal(Offset.zero, ancestor: overlay),
              button.localToGlobal(button.size.bottomRight(Offset.zero),
                  ancestor: overlay),
            ),
            Offset.zero & (overlay?.size ?? Size.zero),
          );
          showAccountsMenu(context, position);
          // context.router.pop();
        },
        child: Column(
          children: [
            const Expanded(child: SizedBox()),
            Text('${JonlineAccount.selectedServer}/',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.caption),
            Text(JonlineAccount.selectedAccount?.username ?? noOne,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.subtitle2),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}

Future<Object> showAccountsMenu(
    BuildContext context, RelativeRect position) async {
  ThemeData theme = Theme.of(context);
  TextTheme textTheme = theme.textTheme;
  ThemeData darkTheme = theme;
  ThemeData lightTheme = ThemeData.light();
  final accounts = await JonlineAccount.accounts;

  return showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      // color: (musicBackgroundColor.luminance < 0.5
      //         ? subBackgroundColor
      //         : musicBackgroundColor)
      //     .withOpacity(0.95),
      items: [
        PopupMenuItem(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          mouseCursor: SystemMouseCursors.basic,
          value: null,
          enabled: false,
          child: Text(
            'Accounts',
            style: darkTheme.textTheme.titleLarge,
          ),
        ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          mouseCursor: SystemMouseCursors.basic,
          value: null,
          enabled: false,
          child: Column(children: [
            ...accounts.map((a) {
              bool selected = a.id == JonlineAccount.selectedAccount?.id;
              ThemeData theme = selected ? lightTheme : darkTheme;
              TextTheme textTheme = theme.textTheme;
              return Theme(
                data: theme,
                child: Material(
                  // color: backgroundColor,
                  color: selected ? Colors.white : Colors.transparent,
                  child: InkWell(
                      mouseCursor: SystemMouseCursors.basic,
                      onTap: () {
                        Navigator.pop(context);
                        AppState appState =
                            context.findRootAncestorStateOfType<AppState>()!;
                        if (selected) {
                          appState.selectedAccount = null;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Browsing anonymously on ${JonlineAccount.selectedServer}.")),
                          );
                        } else {
                          appState.selectedAccount = a;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Browsing ${a.server} as ${a.username}.")),
                          );
                        }
                        // onSelected(part);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("${a.server}/",
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.caption),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(a.username,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.subtitle1),
                            ),
                          ],
                        ),
                      )),
                ),
              );
            }),
            Material(
              // color: backgroundColor,
              color: Colors.transparent,
              child: InkWell(
                  mouseCursor: SystemMouseCursors.basic,
                  onTap: () {
                    Navigator.pop(context);
                    context.navigateNamedTo('/login');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text("Login/Create Account...",
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.subtitle2),
                            ),
                            const Icon(Icons.arrow_right, color: Colors.white)
                          ],
                        ),
                      ],
                    ),
                  )),
            ),
          ]),
        ),
      ]);
}