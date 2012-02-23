title: CentOS 6.2 crondとanacronの関係について調べてみた
slug: centos62-crond-and-anacron

CentOS 6.2ではanacronはデーモンとして動作している訳では無くcronから定期的に呼ばれているようです(6.1以前に関しては未確認です)。crondとanacronの関係が良く分からなかったので、cronの起動から順に大まかな処理の流れについて調べてみました。

### 参考

* [cron の設定ガイド](http://www.express.nec.co.jp/linux/distributions/knowledge/system/crond.html)
* [Scientific Linux 6で自宅サーバー構築 番外編その1 Scientific Linux 6のcronについて](http://www.sa-sa-ki.jp/blog/2011/03/scientific-linux-6-1-scientific-linux-6-cron/)
* [http://aikotobaha.blogspot.com/2011/02/rhel6-7cronanacron.html](http://aikotobaha.blogspot.com/2011/02/rhel6-7cronanacron.html) 〜 この記事の図がとても参考になりました

### cronの起動

CentOSをインストールすると、システム起動時にデフォルトでcrondが起動するような設定になっている。chkconfigで確認出来る。

    # chkconfig | grep crond
    crond    0:off 1:off 2:on 3:on 4:on 5:on 6:off
    ・・・ 自動で起動するようにする場合・・・
    # chkconfig crond on
    ・・・crondが起動中かどうかの確認・・・
    # service crond status
    crond (pid  1265) を実行中...

システムが起動されるとスクリプト`/etc/init.d/crond`により`crond`が起動される。 その際スクリプトは`/etc/sysconfig/crond`をsourceコマンドで読み込み、CRONDARGSに記述されているオプションをパラメータとしてcrondに渡している。

### crondが参照するファイル

<dl>
  <dt>/var/spool/cron/[user]</dt>
  <dd>ユーザ毎に生成されるcrontabファイル。<code>crontab -e</code>コマンドによりviが起動し、ユーザのcrontabファイルが開かれて編集することが出来る。</dd>
  <dt>/etc/crontab</dt>
  <dd>システムに関するcrontabファイル。CentOS 5ではここにcron.[daily|weekly|monthly]が記述されていたらしいが、CentOS 6では空となり、/etc/anacrontabに移動した。crontabを直接編集することは推奨されていないらしい。</dd>
  <dt>/etc/cron.d</dt>
  <dd>上記以外のものはこのディレクトリ配下に置く。 <a href="http://homepage1.nifty.com/cra/linux/cron.html">cronの使い方</a>によると<q>この仕組みは、パッケージをインストールする際に、インストーラが、cronの設定まで、可能なように作られたそうです。</q>と書いてある。/var/spool/cronはユーザ毎だし、普通/etc/crontabは直接編集することはしない、と言うことなので、なるほどなぁって思った。</dd>
</dl>

インストール直後は/var/spool/cronディレクトリは空となっており、/etc/crontabファイルも空となっている。 なので、**crondは/etc/cron.dディレクトリのスクリプトのみを実行している**ことになる。

### anacronの起動
システム起動直後の状態では、crondは

* /etc/cron.d/0hourlyのみを1時間に1回実行する
* 0hourlyは`/etc/cron.hourly`ディレクトリ配下のスクリプトを実行する(cron.hourlyには0anacronしか存在していないので、1時間に1回0anacronのみが実行されることになる)
* 0anacronは`anacron -s`を起動する。(manによると-sの意味はシリアライズとのこと)

と言うような処理の流れになっている。つまりCentOS 6.2をインストールした直後では上記のような仕組みで、**crondによりanacronが1時間に1回起動される。**

### anacronが参照するファイル
anacronは`/etc/anacrontab`を参照する。 anacrontabにはcron.[daily|weekly|monthly]を実行するよう指定されており、指定された時間・間隔と/var/spool/anacronディレクトリの各ファイルに記録された時間を比較して、必要なスクリプトを実行する。<br />
要は**下記ディレクトリ配下のスクリプトはanacronが実行する。**

* /etc/cron.daily
* /etc/cron.weekly
* /etc/monthly

因みに、インストール直後の状態ではcron.daily/logrotateファイルのみが存在している。

### 見るべきログ
crond、anacron共に`/var/log/cron`に書かれている。
