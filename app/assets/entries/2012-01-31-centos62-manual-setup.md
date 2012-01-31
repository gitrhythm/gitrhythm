title: CentOS 6.2 インストール時に設定した項目を手動で設定してみる
slug: centos62-manual-setup

CentOS 6.2のインストール時に設定した項目に関して、手動で設定する方法を調べた際のメモです。

### デフォルト言語
*/etc/sysconfig/i18n*を開き内容を編集する。

    # 英語(UTF-8)の場合
    LANG="en_US.UTF-8"
    
    # 日本語(UTF-8)の場合
    LANG="ja_JP.UTF-8"

CUI環境でのコンソール(ssh等でログインするターミナルではない)では元々日本語が表示出来ないので、デフォルト言語を日本語にしていてもLANGはen_US.UTF-8になるようだ。ただ、デフォルト言語をde_DE.UTF-8にすると普通にLANGもde_DE.UTF-8になっているので、マルチバイト文字は駄目だけど、少なくともasciiやlatin-1なら問題が無いのだろうと思う(latin-2とかはどうなのだろう？)。 因みにコンソールで日本語を使うには、[こちらの記事](http://rina.jpn.ph/~rance/linux/centos/centos51_after.html)によるとbtermを使うと良いのらしい。

システム全体のデフォルト言語は`/etc/sysconfig/i18n`で設定するが、環境変数LANGでユーザ毎に言語を設定出来る。bashならば`.bashrc`にLANGを記述する。

    export LANG="de_DE.UTF-8"

としてターミナルで`source .bashrc`と叩けば、デフォルト言語が日本語でもユーザの言語はドイツ語になる。また、ここで設定した値はコンソールにも反映されるので、日本語を指定するとコンソールでは文字化けが発生する。<br />
結局、デフォルト言語とrootは`en_US.UTF-8`にしておいて、ユーザ毎に環境変数で言語を設定するのが良いのかな？って気がする。(なんとなく)

### キーボード
*/etc/sysconfig/keyboard*を開き内容を編集する。

    # 英語(USインターナショナル)の設定内容
    KEYTABLE=”us-acentos”
    MODEL=”pc105”
    LAYOUT=”us”
    KEYBOARDTYPE=”pc”
    VARIANT=”intl”
    
    #英語(アメリカ合衆国)の設定内容
    KEYTABLE=”us”
    MODEL=”pc105+inet”
    LAYOUT=”us”
    KEYBOARDTYPE=”pc”

    # 日本語配列
    KEYTABLE="jp106"
    MODEL="jp106"
    LAYOUT="jp"
    KEYBOARDTYPE="pc"

### ネットワーク
ネットワークの設定をするには次のファイルを編集する必要がある。

* */etc/sysconfig/network* - OS全体で共通のネットワーク設定。
* */etc/sysconfig/network-scripts/ifcfg-eth[0-9]* - NIC毎のネットワーク設定。
* */etc/resolv.conf* - DNSサーバのIPを記述するファイル。

ネットワークの設定を何もせずにインストールすると、上記ファイルは次のようになっている。

    ・・・/etc/sysconfig/network・・・
    NETWORKING=yes
    HOSTNAME=centos
    
    ・・・/etc/sysconfig/network-scripts/ifcfg-eth0・・・
    DEVICE="eth0"
    HWADDR="XX:XX:XX:XX:XX:XX"  <- MACアドレス
    NM_CONTROLLED="yes"
    ONBOOT="no"
    
    ・・・・/etc/resolv.confは空・・・

ここに、DHCPクライアントとしてIPアドレスを自動で取得する設定をしていく。<br />
*/etc/sysconfig/network*は特に変更無しで、*/etc/sysconfig/network-scripts/ifcfg-eth0*に必要な情報を追加／編集する。

    DEVICE="eth0"
    HWADDR="XX:XX:XX:XX:XX:XX" <- MACアドレス
    NM_CONTROLLED="no" <- NetworkManagerは使わないのでno似変更
    ONBOOT="yes"       <- noをyesに変更
    ・・・下記を追加・・・
    TYPE=Ethernet
    BOOTPROTO=dhcp
    DEFROUTE=yes
    PEERDNS=yes
    PEERROUTES=yes
    ・・・下記２つはIPv6を使わない前提・・・
    IPV4_FAILURE_FATAL=yes
    IPV6INIT=no

設定項目に関しては[サーバーを前提としたネットワーク設定](http://www.obenri.com/_minset_cent6/netconfig_cent6.html)が詳しい。PEERDNSはDHCPでIP取得時にresolv.confを更新するかどうかのフラグで、[yesで更新する／noで更新しない](http://d.hatena.ne.jp/think-t/20110113/p1)となるらしいが、今はDNSを立てていないのでyesにしておく。PEERROUTESは不明。 この中で必須の項目はDEVICE / ONBOOT / BOOTPROTOの３つ。

*/etc/resolv.conf*はdhcpでIPアドレスを取得する際に自動で設定されるので何もしない。<br />
ifupでネットワークを有効にするか、或いはリブートしてネットワークが有効か確認してみる。

    # ifdown eth0
    # ifup eth0
    # ifconfig eth0

手動でIPを設定するのも試してみようかとも思ったけど、ネットワークは改めてもう少し深く調べてみたいので、またの機会にします。

[サーバーを前提としたネットワーク設定](http://www.obenri.com/_minset_cent6/netconfig_cent6.html) / [Linux技術トレーニング　基本管理コース I](https://www.miraclelinux.com/technet/document/linux/training/1_5_1.html)を参考にしました。

### タイムゾーン
*/etc/localtime*に*/usr/share/zoneinfo*配下のいずれかのファイルを置く。CentOSインストール直後ではファイルをコピーしているが、これだとlocaltimeが実際zoneinfoのどのファイルか確認出来ないので、個人的にはシンボリックリンクにしておいた方が良いと思う。 また、`ls -i`等でinodeを確認すると分かるが`zoneinfo/Japan`と`zoneinfo/Asia/Tokyo`はハードリンクの関係となっている。

    $ sudo rm /etc/localtime
    $ sudo ls -s /usr/share/zoneinfo/Janan /etc/localtime

環境変数TZでユーザごとのタイムゾーンを設定出来る。

    #export TZ="America/New York"  -> ニューヨーク
    export TZ="Asia/Tokyo"         -> 東京

dateコマンドで確認(TZ="Asia/Tokyo"の場合)

    $ date
    2012年 1月31日 火曜日 16時31分40秒 JST

### UTCを使うかどうか
インストール時にチェックボックス「システムクロックでUTCを使用」があるが、これの設定内容は*/etc/adjtime*に反映される。 チェックボックスをチェックすると`UTC`が書きこまれ、外すと`LOCAL`が書き込まれる。 手動で変更する場合は、この「UTC」「LOCAL」を直接変更してリブートする。
