import 'package:flutter/material.dart';

void showPrivacyPolicy(BuildContext context) {
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
- カメラで撮影した画像やフォトライブラリから選択した画像

3. 情報の使用目的

収集した情報は、以下の目的で使用されます：
- サービスの提供と改善
- ユーザー体験のパーソナライズ
- コミュニケーション機能の提供
- 広告の表示（該当する場合）
- 法的義務の遵守
- ユーザーが投稿した写真や画像の表示

4. カメラとフォトライブラリの使用

当アプリは、ユーザーがスポーツ活動の写真を投稿するためにカメラとフォトライブラリへのアクセスを要求します。
- カメラ：スポーツ活動の写真を直接撮影し、アプリ内で共有するために使用されます。
- フォトライブラリ：既存の写真をアプリ内で共有するために使用されます。
これらの機能は、ユーザーが明示的に許可した場合にのみ使用されます。

5. 情報の共有

当アプリは、以下の場合を除き、ユーザーの個人情報を第三者と共有しません：
- ユーザーの同意がある場合
- 法的要請がある場合
- サービス提供に必要な外部パートナーとの共有（これらのパートナーは当アプリのプライバシーポリシーに準じます）

6. データセキュリティ

当アプリは、ユーザーの個人情報を保護するために適切な技術的・組織的措置を講じています。

7. ユーザーの権利

ユーザーは自身の個人情報に関して、アクセス、訂正、削除、処理の制限を要求する権利を有します。

8. 子どものプライバシー

当アプリは13歳未満の子どもから故意に個人情報を収集しません。

9. プライバシーポリシーの変更

当アプリは、必要に応じて本プライバシーポリシーを変更することがあります。重要な変更がある場合は、アプリ内で通知します。

10. お問い合わせ

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