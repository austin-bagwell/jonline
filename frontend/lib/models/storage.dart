import 'package:jonline/models/jonline_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _storage;
Future<SharedPreferences> getStorage() async {
  if (_storage == null) {
    print("setting up storage");
    _storage = await SharedPreferences.getInstance();
    if (_storage!.containsKey('selected_account')) {
      JonlineAccount.selectedAccount = (await JonlineAccount.accounts)
          // ignore: unnecessary_cast
          .map((e) => e as JonlineAccount?)
          .firstWhere((a) => a?.id == _storage!.getString('selected_account'),
              orElse: () => null);
    }
  }
  return _storage!;
}