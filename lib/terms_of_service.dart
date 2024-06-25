import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  Future<void> _acceptTerms(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedTerms', true);
    if (context.mounted) {
      context.go('/app');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('ActiveCircle',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontFamily: 'Pacifico',
              ))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '''
利用規約

第1条（適用）
本利用規約（以下、「本規約」といいます。）は、ActiveCircle（以下、「本アプリ」といいます。）の利用に関する条件を定めるものです。ユーザーは、本規約に同意した上で、本アプリを利用するものとします。

第2条（禁止事項）
ユーザーは、本アプリの利用にあたり、以下の行為をしてはなりません。
1. 法令または公序良俗に違反する行為
2. 犯罪行為に関連する行為
3. 他のユーザー、第三者、または本アプリの運営者の知的財産権、肖像権、プライバシーその他の権利または利益を侵害する行為
4. 他のユーザー、第三者、または本アプリの運営者に対する誹謗中傷、脅迫、いやがらせ、差別、またはその他の不適切な行為
5. 不正アクセス、コンピュータウイルスの送信、その他の方法で本アプリの運営を妨害する行為
6. その他、本アプリの運営者が不適切と判断する行為

第3条（ユーザーの責任）
ユーザーは、自らの責任において本アプリを利用するものとし、本アプリの利用に関して行った一切の行為およびその結果について一切の責任を負うものとします。

第4条（免責事項）
本アプリの運営者は、本アプリの利用により生じたユーザーの損害について、一切の責任を負わないものとします。ただし、本アプリの運営者に故意または重過失がある場合はこの限りではありません。

第5条（利用停止・解除）
本アプリの運営者は、ユーザーが本規約に違反した場合、事前の通知なく、当該ユーザーに対する本アプリの利用を停止または解除することができるものとします。

第6条（規約の変更）
本アプリの運営者は、必要と判断した場合には、ユーザーに通知することなくいつでも本規約を変更することができるものとします。変更後の規約は、本アプリに掲載された時点から効力を生じるものとします。

第7条（準拠法・裁判管轄）
本規約の解釈にあたっては、日本法を準拠法とします。また、本アプリに関して紛争が生じた場合には、本アプリの運営者の所在地を管轄する裁判所を専属的合意管轄とします。

附則
本規約は2024年6月9日から施行します。
                  ''',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _acceptTerms(context),
              child: const Text('同意する'),
            ),
          ],
        ),
      ),
    );
  }
}
