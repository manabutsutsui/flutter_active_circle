import 'package:flutter/material.dart';

void showTermsOfService(BuildContext context) {
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
- 他のユーザーへの嫌がらせや迷惑行為
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