title: CentOS 6.2 タイムゾーンとクロックについて調べてみた
slug: centos62-timezone-clock

[前回](/blog/2012/01/31/centos62-manual-setup/)、手動でタイムゾーンの設定とシステムクロックをUTCにする方法を調べてみましたが、数点疑問点があったので更に調べてみました。

### /etc/sysconfig/clockファイルは何者？
タイムゾーンを設定する方法を調べていると、/etc/localtimeを修正すると共に/etc/sysconfig/clockを修正すると書かれている記事が多い。だけど、色々試してみると、どうもclockファイルはタイムゾーンそのものには影響を与えていないんじゃないか？って気がする。実際clockファイルを削除しても特に動作に支障は無い。(少なくともパッと見支障は無いように思う)

[The Clock Mini-HOWTO - 3.1. clock(8)とhwclock(8)](http://linuxjf.sourceforge.jp/JFdocs/Clock/software.html#AEN158)に以下の記述がある。

> RTC の時間調整用の数値は、/etc/adjtime に保存されて います。Red Hat の場合 etc/sysconfig/clock に スクリプトがあり、そのスクリプトで hwclock のオプション を制御しています。

ところがredhatの[Deployment_Guide - 29.1.6. /etc/sysconfig/clock](http://docs.redhat.com/docs/en-US/Red_Hat_Enterprise_Linux/5/html/Deployment_Guide/ch-sysconfig.html#s2-sysconfig-clock)には

> Note that the ZONE parameter is read by the Time and Date Properties Tool (system-config-date), and manually editing it does not change the system timezone.

のように書いてある。 少なくともCentOS 6.2では、/etc/sysconfig/clockを参照するのはシステムツールのsystem-config-data位で、タイムゾーンそのものには直接影響を与えないのだろうと思う。なので、/etc/localtimeを直接手で書き換えることでタイムゾーンを変更する場合は、/etc/sysconfig/clockは必要無いのだと思う。(と思うけど確証はありません orz)

### クロック設定の挙動について

RHEL6のクロック設定についてはこちらの[とあるSIerの憂鬱 - RHEL6のtickless kernel](http://d.hatena.ne.jp/incarose86/20110802/1312311712)に詳しく書いてある。クロック設定に関する部分を大雑把に要約すると

* 起動時には/etc/rc.d/rc.sysinitで`hwclock --hctosys`を実行してクロックを設定する。その際/etc/sysconfig/clockの値を参照する。
* シャットダウン時には/etc/rc.d/rc0.d/S01haltで`hwclock --systohc`を実行してクロックを保存する。その際/etc/sysconfig/clockの値を参照する。

上記はCentOS 5までらしいのだけど、CentOS 6.2(6.0 / 6.1は確認してません)では少し挙動が異なる。

* 起動時にはカーネルがクロックを設定する。その際/etc/adjtimeの値を参照する。adjtimeファイルが無かった場合のデフォルト値は`local`。
* シャットダウン時には/etc/rc.d/rc0.d/S01haltで`hwclock --systohc`を実行してクロックを保存する。その際/etc/adjtimeの値を参照する。adjtimeファイルが無かった場合のデフォルト値は`local`。

となっているように思う。

### クロックの挙動確認メモ

クロックの挙動を確認した際にやったことをメモっておきます。

タイムゾーンをJapan、「システムクロックにUTCを使う」にチェックを入れてCentOSをインストールしてシステム起動。この時点で/etc/adjtimeの3行目に[UTC]と記述されており、カーネルはUTCとしてRTCを読み込んでいるはず。

ここで`hwclock --debug`コマンドを叩くと

    ハードウェア時計から読込んだ時刻: 2012/02/10 09:00:36
    ハードウェア時計時刻 : 2012/02/10 09:00:36 = 1969 年以来 1328864436 秒
    2012年02月10日 18時00分36秒  -0.672532 秒

のように表示され、時刻が18:00、ハードウェア時刻が09:00となっており、現在の時刻タイムゾーンに従って+09:00されているのが分かる。

ここでシャットダウンすると、`hwclock --systohc`が発行されてUTCとしてシステム時刻をRTCに反映されるが、実験のためにhwclockコマンドを発行しないようhaltを修正する。<br />
/etc/rc.d/init.d/haltを編集して`/sbin/hwclock --systohc`コマンドを発行している行をコメントアウトする。

そして/etc/adjtimeのUTCをLOCALに変更してリブートする。シャットダウン時にシステムクロックをRTCに反映しないようにしてあるので、シャットダウン時にはクロックに関する処理は何もせず、起動時にRTCをUTCでは無くLOCALとしてシステムクロックに設定することになる。

`hwclock --debug`で確認すると

    ハードウェア時計から読込んだ時刻: 2012/02/10 09:15:17
    ハードウェア時計時刻 : 2012/02/10 09:15:17 = 1969 年以来 1328832917 秒
    2012年02月10日 09時15分17秒  -0.504839 秒

となり、システム時刻とハードウェア時計時刻が同じになっており、LOCALとして時刻を読み込んだことが分かる。UTCをLOCALとして読み込んでいるので時刻はズレてます。

ここで/etc/adjtimeを適当にリネームして再起動してみると、LOCALとして時刻を読み込んでいるので、デフォルト値がLOCALであることも分かる。

後は`hwclock --systohc`に`--local`なり`--UTC`を指定してコマンドを叩き、手動でRTCに書きこんだ後にリブートしたりとか、`hwclock --hctosys`に`--local`や`--UTC`で読み込んだりとかしてみたんだけど、だらだら書くと長くなっちゃうし、書く気力が無くなっちゃったのでこの辺で止めときます。 色々試してみて下さい。
