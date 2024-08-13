import 'package:flutter/material.dart';
import '../parts/sign_up_with_google.dart';
import '../parts/sign_up_with_apple.dart';
import 'package:flutter/gestures.dart';

class CreateAccount extends StatelessWidget {
  const CreateAccount({super.key});

  void _showTermsOfService(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('利用規約', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text('''
1. 利用規約の同意

本アプリケーション「ActiveCircle」（以下、「本アプリ」）をご利用いただく前に、以下の利用規約をよくお読みください。本アプリをダウンロード、インストール、または使うことにより、ユーザーは本規約に同意したものとみなされます。

2. アカウント登録

本アプリを利用するには、アカウントの作成が必要です。ユーザーは正確かつ最新の情報を提供する責任があります。アカウント情報の管理は厳重に行い、第三者による不正アクセスを防止してください。

3. プライバシーとデータ保護

当社はユーザーのプライバシーを尊重し、個人情報の保護に努めます。収集した情報の取り扱いについては、別途定めるプライバシーポリシーに従います。

4. コンテンツの投稿

ユーザーは本アプリ内で投稿するコンテンツに関して全責任を負うものとします。違法、有害、脅迫的、中傷的、わいせつ、名誉毀損、またはその他の好ましくないコンテンツの投稿は禁止されています。

5. 知的財産権

本アプリおよび関連するすべての知的財産権は当社に帰属します。ユーザーは、個人的、非商業的な目的でのみ本アプリを使用することができます。

6. 禁止事項

以下の行為は厳禁とします：
- 本アプリの不正利用、ハッキング、リバースエンジニアリング
- 他のユーザーへの��がらせや迷惑行為
- 虚偽の情報の提供や、なりすまし行為
- 本アプリの運営を妨害する行為

7. サービスの変更・終了

当社は、事前の通知なく本アプリのサービス内容を変更、または終了する権利を有します。

8. 免責事項

本アプリの利用に関連して生じたいかなる損害についても、当社は責任を負いません。

9. 準拠法と管轄裁判所

本規約の解釈および適用は日本法に準拠するものとし、本アプリに関連する紛争については、東京地方裁判所を第一審の専属的合意管轄裁判所とします。

10. 規約の変更

当社は、必要に応じて本規約を変更する権利を有します。変更後の規約は本アプリ内で公表された時点で効力を生じるものとします。

以上の規約に同意いただける場合のみ、本アプリをご利用ください。
                  '''),
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('プライバシーポリシー', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text('''
プライバシーポリシー

1. はじめに

ActiveCircle（以下、「当アプリ」）は、ユーザーのプライバシーを尊重し、個人情報の保護に努めます。本プライバシーポリシーは、当アプリが収集、使用、共有する個人情報の取り扱いについて説明します。

2. 収集する情報

当アプリは、以下の情報を収集する場合があります：
- アカウント情報（ニックネーム、メールアドレス等）
- プロフィール情報（年齢、好きなスポーツ、実績・経験等）
- 位置情報（オプション）
- デバイス情報
- 利用状況データ

3. 情報の使用目的

収集した情報は、以下の目的で使用されます：
- サービスの提供と改善
- ユーザー体験のパーソナライズ
- コミュニケーション機能の提供
- 広告の表示（該当する場合）
- 法的義務の遵守

4. 情報の共有

当アプリは、以下の場合を除き、ユーザーの個人情報を第三者と共有しません：
- ユーザーの同意がある場合
- 法的要請がある場合
- サービス提供に必要な外部パートナーとの共有（これらのパートナーは当アプリのプライバシーポリシーに準じます）

5. データセキュリティ

当アプリは、ユーザーの個人情報を保護するために適切な技術的・組織的措置を講じています。

6. ユーザーの権利

ユーザーは自身の個人情報に関して、アクセス、訂正、削除、処理の制限を要求する権利を有します。

7. 子どものプライバシー

当アプリは13歳未満の子どもから故意に個人情報を収集しません。

8. プライバシーポリシーの変更

当アプリは、必要に応じて本プライバシーポリシーを変更することがあります。重要な変更がある場合は、アプリ内で通知します。

9. お問い合わせ

本プライバシーポリシーに関するご質問やご懸念がある場合は、以下の連絡先までお問い合わせください：

tsutsui4012@gmail.com

最終更新日: 2024/06/10
                  '''),
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント作成', style: TextStyle(fontWeight: FontWeight.bold),),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SignUpWithGoogle(),
              const SignUpWithApple(),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  children: [
                    const TextSpan(text: ''),
                    TextSpan(
                      text: '利用規約',
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = () => _showTermsOfService(context),
                    ),
                    const TextSpan(text: '及び'),
                    TextSpan(
                      text: 'プライバシーポリシー',
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = () => _showPrivacyPolicy(context),
                    ),
                    const TextSpan(text: 'に同意の上、\nアカウントを作成して下さい。'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}