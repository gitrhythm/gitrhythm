title: CentOS 6.2 インストール後の初期設定
slug: centos62-initial-setup

CentOS 6.2インストール直後の初期設定に関するメモです。

### CapsLockとCtrlを入れ替える
直接コンソールから操作する事は殆ど無いけど、これをしておかないと何気にストレスが溜まるのでやっておく。us.map.gzファイルの内容を書き換えれば良い。keycode 29の`Control`を`Caps_Lock`に、keycode 58の`Control`を`Caps_Lock`にする。

    % su root -
    # cd /lib/kbd/keymaps/i386/qwerty
    # cp us.map.gz us.map.original.gz
    # gzip -d us.map.gz
    # vi us.map
    ・・・ 該当行を編集・・・
    # gzip us.map
    # shutdown -r now

[コンソールで［Ctrl］と［Caps Lock］キーを入れ替えるには](http://www.atmarkit.co.jp/flinux/rensai/linuxtips/227conctlcaps.html)を参考にしました。

### ユーザの追加
rootでログインするのはセキュリティ上好ましくないので、whieelグループの管理者ユーザを作成する。

    % su
    # useradd <ユーザ名> -g wheel
    ・・・vipwで内容確認・・・
    パスワード設定
    # passwd <ユーザ名>
    New password:         <- パスワード入力
    Retype new password:  <- 確認

ユーザを削除する場合は`userdel -r ユーザ名`。-rを付けるとホームディレクトリ、メールスプールも削除してくれる。<small>(メールスプールディレクトリは/var/spool/mail)</small><br />
ユーザ情報を変更する場合は`usermod`を使う。

    ユーザ名を変更する場合
    # usermod -l 新ユーザー名 旧ユーザー名
    グループを変更する場合
    # usermod -g グループ名 ユーザ名

[useradd](http://linuxjm.sourceforge.jp/html/shadow/man8/useradd.8.html)を参考にしました。

### sudoの設定
`visudo`コマンドで`/etc/sudoers`ファイルを開き編集する。 今回はコメントアウトされているwheelの記述を有効にし、単純にwheelグループにすべてのコマンドを許可するようにする。

    $ sudo visudo
    <user> is ot in the sudoers file. ・・・ <- 実行出来ない
    $ su
    # visudo
    %wheel  ALL=(ALL)  ALL  <- コメントを外して有効にする
    # exit                  <- rootから抜ける
    $ sudo visudo           <- 実行可能

[第5回 サービスをセキュアにするための利用制限（3）～管理者権限の制限のためのsuとsudoの基本～](http://www.atmarkit.co.jp/fsecurity/rensai/unix_sec05/unix_sec01.html) / [visudo](http://linuxjm.sourceforge.jp/html/sudo/man8/visudo.8.html) / [sudoers](http://linuxjm.sourceforge.jp/html/sudo/man5/sudoers.5.html)を参考ししました。

### rootになれるユーザをwheelブループユーザに限定する
wheelグループのユーザのみrootになれるようにする。<small>(システム管理ユーザをwheelグループとして作成し、通常のユーザをwheelグループ以外で作成することを前提としている)</small><br />
`/etc/pam.d/su`を開き、下記のコメントを外す。

    $ sudo vi /etc/pam.d/su
    auth  required  pam_wheel.so use_uid  <- コメントを外す

[suコマンドを実行可能なユーザーを限定するには](http://www.atmarkit.co.jp/flinux/rensai/linuxtips/086suwheel.html)を参考にしました。

### 不要なサービスを停止
`/usr/sbin/setup`を起動して「システムのサービス」を選択し(直接サービス画面を表示するなら`/usr/bin/ntsysv`)、不要なサービスのチェックを外す。

運用してみたら「あれ？」と思うことがあるかも知れないけど、今のところ起動しているのは以下。

    $ chkconfig | grep 3:on
    crond      0:off 1:off 2:on 3:on 4:on 5:on 6:off
    ip6tables  0:off 1:off 2:on 3:on 4:on 5:on 6:off
    iptables   0:off 1:off 2:on 3:on 4:on 5:on 6:off
    network    0:off 1:off 2:on 3:on 4:on 5:on 6:off
    postfix    0:off 1:off 2:on 3:on 4:on 5:on 6:off
    rsyslog    0:off 1:off 2:on 3:on 4:on 5:on 6:off
    sshd       0:off 1:off 2:on 3:on 4:on 5:on 6:off
    udev-post  0:off 1:on  2:on 3:on 4:on 5:on 6:off

[不要なデーモンを停止しましょう](http://www.obenri.com/_minset_cent5/daemon_cent5.html)を参考にしました。

### 仮想コンソールの数を調整
これ以降は[CentOS 5.1 インストール後の作業](http://rina.jpn.ph/~rance/linux/centos/centos51_after.html)を参考にしました。

psでmingettyの数を確認してみると6つ起動しているのを確認出来る。6つも必要ないので`/etc/sysconfig/init`の`ACTIVE_CONSOLES`を編集して2つにしておく。

    $ ps -ef | grep tty
    root  1388   1  0 01:56 tty1  00:00:00 /sbin/mingetty /dev/tty1
    root  1390   1  0 01:56 tty2  00:00:00 /sbin/mingetty /dev/tty2
    root  1392   1  0 01:56 tty3  00:00:00 /sbin/mingetty /dev/tty3
    root  1394   1  0 01:56 tty4  00:00:00 /sbin/mingetty /dev/tty4
    root  1396   1  0 01:56 tty5  00:00:00 /sbin/mingetty /dev/tty5
    root  1398   1  0 01:56 tty6  00:00:00 /sbin/mingetty /dev/tty6
    hiro  1427   1403  0 01:57 pts/0    00:00:00 grep tty
    
    $ sudo vi /etc/sysconfig/init
    ACTIVE_CONSOLES=/dev/tty[1-2] <- [1-6]を[1-2]に変更



### デフォルトランレベルの変更
特にこうする必要は無いとは思うけど、Xはインストールしていないので一応ランレベルを変更しておく。 `/etc/inittab`を開き、`initdefault`を5から3に変更する。

    $ sudo vi /etc/inittab
    id:3:initdefault: <- 5を3に変更

### SELinuxの無効化
慣れないとSELinuxは難しいと思うので一旦切っておく。`getnenforce`で状態表示、`setenforce`で一時的に有効・無効を切り替えられる。起動時に設定するためには`/etc/sysconfig/selinux`ファイルを編集してリブートする。

    # getenforce    <- 状態確認
    Enforcing       <- 有効
    # setenforce 0  <- 無効化
    # getenforce
    Permissive      <- 無効
    # setenforce 1  <- 有効化
    #getenforce
    Enforcing

    # vi /etc/sysconfig/selinux
    無効にするにはSELINUXの値を"enforcing"から"disabled"に変更する。
    SELINUX=disabled
