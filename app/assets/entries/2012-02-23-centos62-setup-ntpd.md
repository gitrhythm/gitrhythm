title: CentOS 6.2 ntpd -qで時刻合わせ
slug: centos62-setup-ntpd

NTPDの設定をした際のメモです。[こちら](http://www.ivoryworks.com/blog/2008/02/72)によると`ntpdate`の場合、時刻のズレが大きい場合に一気に時間を変更してしまうため、場合によっては環境面で不具合が出る可能性があるのらしい。その点`ntpd`はゆっくり時間を修正してくれるとのこと。サーバの時刻合わせはdaemon化せずにcronから`-q`オプションでntpdを定期的に起動する方法を採用することにしました。<small>(`-q`は時刻合わせが終了次第exitする)</small>

### 参考にした記事
* [NTP Home](http://www.ntp.org/)
* [マニュアルページ  — NTPD](http://www.nxmnpg.com/ja/8/ntpd)
* [Stray Penguiin ntpd](http://www.asahi-net.or.jp/~AA4T-NNGK/ntpd.html)
* [NTPDの設定](http://www.aconus.com/~oyaji/ntp/ntp.htm)
* [NTP設定 - とあるSIerの憂鬱](http://d.hatena.ne.jp/incarose86/20110505/1312522379)

### インストール
`ntpd`で検索するとnptdateはヒットするけどnptdはヒットしない。ntpで検索するとヒットした。

    # yum search nptd
    ntpdate.x86_64 : Utility to set the date and time via NTP
    # yum search ntp
    ntp.x86_64 : The NTP daemon and utilities
    ntp-doc.noarch : NTP documentation
    ntp-perl.x86_64 : NTP utilities written in perl
           ・・・
    ・・・ntpをインストール・・・
    # yum -y install ntp
    Downloading Packages:
    (1/2): ntp-4.2.4p8-2.el6.centos.x86_64.rpm         | 444 kB     00:00     
    (2/2): ntpdate-4.2.4p8-2.el6.centos.x86_64.rpm     |  58 kB     00:00  

ntpd以外にツール類もいくつかインストールされる。

### 設定
[こちら](http://wiki.nothing.sh/page/NTP)の「はじめに（まず読もう）」を読むと、特定のntpサーバに負荷が偏って大変みたいなので(今はどうなのかは知りませんけど)、プロパイダのntpサーバを使おうと書いてある。がしかし、うちで利用しているKDDIはntpサーバを公開していないようなので、先の記事のアドバイス通り*ntp.jst.mfeed.ad.jp* / *ntp.nict.jp* / *ntp.ring.gr.jp*を利用することにする。

ちょっと気になったのは、[こちら](http://www.asahi-net.or.jp/~AA4T-NNGK/ntpd.html)の「主設定ファイル /etc/ntp.conf」には以下のように書いてある。

>stratum 1 のサーバは、我々が時間合わせに使ってはいけない。そうした上位階級 NTP サーバは、それ自身で電波時計や原子時計などの基準デバイスを備え、次の階級のサーバから時間合わせのために参照される。下々の有象無象がいちいち参照したら、starum 1 サーバに無用な負荷をかけてしまう。よって、我々が通常使うのは stratum 2 の NTP サーバだ。

ところが[nictのQA](http://www2.nict.go.jp/w/w114/tsp/PubNtp/qa.html#q2-1)によると、nictはstratum 1らしい。じゃnictのntpサーバは駄目なのかな？って気もするけど、[世界最高性能のインターネット用時刻同期サーバによる 日本標準時配信の開始](http://www2.nict.go.jp/pub/whatsnew/press/h18/060612-1/060612-1.html)とのことで一般公開しているようなので、とりあえず気にしないで使うことにする。

`/etc/ntp.conf`を編集してntpサーバを指定する。X.centos.pool.ntp.orgを上記3つのntpサーバに変更する。

    ・・・X.centos.pool.ntp.orgは削除なりコメントアウト・・・
    #server 0.centos.pool.ntp.org
    #server 1.centos.pool.ntp.org
    #server 2.centos.pool.ntp.org
    ・・・下記ntpサーバを追加・・・
    server ntp.jst.mfeed.ad.jp
    server ntp.nict.jp
    server ntp.ring.gr.jp

daemon化せず-qで起動するので、クライアントからのパケットに応じないよう設定し、他のrestrictオプションはコメントアウトする。(これが必要なのかどうかは、ちょっと自信無いです)

    restrict default ignore <- これを追加
    ・・・それ以外はコメントアウト・・・
    #restrict default kod nomodify notrap nopeer noquery
    #restrict -6 default kod nomodify notrap nopeer noquery
    #restrict 127.0.0.1
    #restrict -6 ::1

driftファイルを作成しオーナー／グループをntpにしておく。値は初期値として0を書きこんでおく。ntp.confには既に`driftfile /var/lib/ntp/drift`と記述されているので、このパスに作成することにする。

    # echo -n "0" > /var/lib/ntp/drift
    # chown ntp:ntp /var/lib/ntp/drift

### anacronへの起動設定
anacronから1日に1回起動されるようにする。`/etc/cron.daily`に次のような内容のスクリプトを作成する。ここではファイル名を`timecheck`としている。 加えてhwclockでハードウェアクロックに反映させるようにした。(ntpdに渡すオプションの-xはslewモード、-uはユーザの指定)

    # vi /etc/cron.daily/timecheck
    ・・・以下を追加・・・
    #!/bin/sh
    ntpd -q -x -u ntp:ntp
    hwclock --systohw
    ・・・ viを閉じ、実行権限を付与・・・
    # chmod 755 ntpd

**これを書いている時点ではまだ運用していないので、ntpdの起動頻度が1日に1回で良いのか、或いは1時間に1回とすべきなのか判断出来てないです。**

### iptablesの変更
NTP用のポートをiptablesに定義する。/etc/sysconfig/iptablesに次の行を追加する。

    -A INPUT -m state --state NEW -m udp -p udp --dport 123 -j ACCEPT
    ・・・編集後iptables再起動・・・
    # service iptables restart

#### 見るべきログ
デフォルトではどこにログが吐かれているか不明。 /dev/nullか標準出力のみじゃないかと思うのだけど、なにぶんログを見つけられないので良くわかりません。 ntpd起動時、又は定義ファイルにログファイルのパスを指定出来るので、ntp.confにログファイルのパスを指定しておくことにした。 以下の行をntp.confに追加する。

    logfile /var/log/ntp.log

### おまけ(手動で時刻を設定する)
ちょくちょく忘れるのでメモ。dateコマンドに「月日時分西暦下二桁」。<br />
2012年02月22日 17時05分なら<br />

    # date 0222170512
