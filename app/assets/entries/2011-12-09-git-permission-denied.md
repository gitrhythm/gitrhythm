title: githubへのpushでPermission denied (publickey)エラー
slug: git-permission-denied

リポジトリを作成してgithubにpushしようとしたら<q>Permission denied(publickey)</q>エラーが出た時のメモ。

githubへpushしたらこんなエラーが・・・
    % git push -u origin master
    Permission denied (publickey).
    fatal: The remote end hung up unexpectedly

~/.sshを見てみたらキーペアが無い？？？ そう言えばキー名称を変えて新しく作り直そうと思っていてそのままだったのを思い出したので、取り敢えずキーペアを作成してgithubに登録。

    % cd .ssh
    % ssh-keygen -t rsa -C 'your githu mail address'
    % Generating public/private rsa key pair.
    % # 鍵の名前を聞いてくるので入力
    % Enter file in which to save the key (/Users/<user>/.ssh/id_rsa): /Users/<user>/.ssh/<key name>
    % Enter passphrase (empty for no passphrase):  
    % Enter same passphrase again: 

キーペアが出来たのでgithubへ公開鍵を登録。

* [github](https://github.com/)にログイン
* Account Settings > SSH Public Keys > Add another public keyをクリック
* Titleを入力し、Keyに公開鍵の内容をコピー。
* Add keyボタンで登録完了。

で、確認してみる。

    % ssh -T git@github.com
    % Permission denied (publickey).
    % fatal: The remote end hung up unexpectedly

・・・(;´Д`) やっぱりダメだ。

再度作りなおしたり、known_hostsファイルを消したりしたりしたけどやっぱり駄目で、結局github:helpの[SSH issues](http://help.github.com/ssh-issues/)を参考にconfigファイルを作ったら出来ました。

繋がったので、再度pushしたらこれもOKでした。 めでたし (´ｰ`)
