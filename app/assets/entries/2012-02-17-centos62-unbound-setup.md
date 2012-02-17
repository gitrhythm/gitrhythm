title: CentOS 6.2 Unboundをインストール
slug: centos62-unbound-setup

DNSキャッシュサーバと、LAN内部の名前解決用にUnboundをインストールしてみました。

[Unboundの紹介(PDF)](http://unbound.jp/wp/wp-content/uploads/2011/04/Unbound-osc2011tk-introduction.pdf)によると、OpenSSLについて

> GOSTに対応していない場合（0.9.8以前）はunbound
> のconfigure時に--disable-gostを付ける必要がある。

と書いてある。OpenSSLのバージョンを確認してみると`OpenSSL 1.0.0-fips 29 Mar 2010`となってるから問題ないかな？と思ったんだけど、やっぱり次のようなエラーになる。

    configure: error: No ECC functions found in OpenSSL: please upgrade OpenSSL or rerun with --disable-gost

これじゃマズいってことでOpenSSLも入れようかとも思ったんだけど、既に入っている所に別途インストールするのもなんか嫌な感じがするので、ここでは`--disable-gost`でインストールすることにする。`./configure`でワーニングが出るけど気にしない・・・

### 参考
* [unbound](http://unbound.net/)
* [日本Unboundユーザ会](http://unbound.jp/)
* [Unbound 知ってる？ この先10年を見据えたDNS - 第2回　Unboundの導入（新規導入編）](http://gihyo.jp/admin/feature/01/unbound/0002)

### インデックス

* ldnsのインストール
* expatのインストール
* unboundのインストールと設定
* iptablesの変更
* 動作確認
* 簡易的なコンテンツサーバの設定
* 見るべきログ

### ldnsのインストール

unboundはライブラリとしてldnsを参照するので、最初にldnsをインストールしておく。[Unbound: インストールと設定方法](http://unbound.jp/unbound/howto_setup/)には、

> libldnsライブラリがインストールされていなければ、unboundのソースtarballに含まれているldnsが自動的に使われます。

と書いてあるが、折角なのでldnsは別途インストールすることにした(因みにtarballのldnsを使う場合はスタティックリンクとなるようです)。が、その前にopenssl-develをインストールする。これはコンパイルで必要となるリソースなんでしょう、きっと。

    # yum -y install openssl-devel

次にldnsのインストール。yumにはパッケージが無いのでソースを取ってきてコンパイルする。ソースは[downloads/ldns](http://www.nlnetlabs.nl/downloads/ldns/)にあるので、ここから最新のものを取得する。

    # cd /usr/local/src
    # wget http://www.nlnetlabs.nl/downloads/ldns/ldns-1.6.12.tar.gz
    # tar zxvf ldns-1.6.12.tar.gz
    # cd ldns-1.6.12
    # ./configure --disable-gost
    # make && make install

/usr/local/include/ldnsと/usr/local/libに各種ファイルがインストールされる。`/usr/local/lib`が`/etc/ld.so.conf`に追加されていなければ追加し、ライブラリキャッシュを更新する。

    # echo '/usr/local/lib' >> /etc/ld.so.conf
    # ldconfig
    # ldconfig -p | grep ldns <- 確認
    libldns.so.1 (libc6,x86-64) => /usr/local/lib/libldns.so.1
    libldns.so (libc6,x86-64) => /usr/local/lib/libldns.so


### expatのインストール
unboundのビルドで必要らしいのでexpat-develをインストールする。

    # yum install expat-devel

### unboundのインストールと設定
[http://unbound.net/downloads/](http://unbound.net/downloads/)から最新のソースを取ってきてコンパイルする。

    # cd /usr/local/src
    # wget http://unbound.net/downloads/unbound-1.4.16.tar.gz
    # tar zxvf unbound-1.4.16.tar.gz
    # cd unbound-1.4.16
    # ./configure --with-ldns=/usr/local --disable-gost \
                  --with-conf-file=/var/unbound/unbound.conf
    # make && make install

--with-conf-fileでconfファイルの場所を指定している。unboundは、デフォルトの動作ではunbound.confのある所にchrootするらしいので、この指定により/var/unboundにchrootする。(unbound.confにchrootと言う設定項目があるので、これで指定することも可能かと思われるが試してないです)

ライブラリキャッシュの更新

    # ldconfig
    # ldconfig -p | grep unbound <- 確認
    libunbound.so.2 (libc6,x86-64) => /usr/local/lib/libunbound.so.2
    libunbound.so (libc6,x86-64) => /usr/local/lib/libunbound.so

起動スクリプトの登録。contrib/unbound.initはunboundのパスを/usr/sbinとしているのでsedにより/usr/local/sbinにしている。

    # cp contrib/unbound.init /etc/init.d/unbound
    # sed -i 's_/usr/sbin/unbound_/usr/local/sbin/unbound_' /etc/init.d/unbound
    # chmod 755 /etc/init.d/unbound
    # chkconfig --add unbound
    # chkconfig unbound on

unboundはchrootして/var/unbound/unbound.confを参照するが、編集しやすいように/etcにシンボリックリンクを作成しておく。

    # ln -s /var/unbound/unbound.conf /etc/

unbound用のグループ・ユーザを作成してchrootディレクトリのオーナーを設定する。daemonとして動作するのでシェルはnologinとする。

    # groupadd -r unbound
    # useradd -r -g unbound -d /var/unbound -s /sbin/nologin unbound
    # chown unbound:unbound /var/unbound

デフォルトでは自身のにDNSキャッシュサーバとして利用出来るようになっているらしい。設定ファイルによりLAN内の他のマシンからも利用出来るよう設定する。<br />
interfaceはリッスンするアドレスを指定する。デフォルト値は`127.0.0.1`つまりlocalhost内のみとなってようなので、それを全てのIPアドレスでリッスンするように0.0.0.0を指定している。(複数のアドレスを指定出来るので個別して指定しても構わないはず)<br />
access-controlではアクセス制御を指定する。ここではネットワークアドレス`192.168.0.0/24`に対して接続を許可し、それ以外からの接続は受け付けないようにしている。[unbound.conf(5)](http://unbound.jp/unbound/unbound.conf/)参照。

    vi /etc/unbound.conf
    ・・・以下を追加・・・
    interface: 0.0.0.0
    interface: ::0
    access-control: 192.168.0.0/24 allow

resolv.confの変更。自身のDNSキャッシュサーバを参照するようにする。

    vi /etc/resolv.conf
    nameserver 127.0.0.1 <- 追加

設定の確認。

    # unbound-checkconf
    unbound-checkconf: no errors in /var/unbound/unbound.conf

起動確認。

    # service unbound start
    unbound を起動中:      [  OK  ]

起動すると/var/unbound配下に下記ファイルが作成されるので確認する。

* unbound.pid
* dev/log
* dev/random
* etc/localtime
* etc/resolv.conf

### iptablesの変更

DNS用のポートをiptablesに定義する。`/etc/sysconfig/iptables`に次の行を追加する。

    -A INPUT -m state --state NEW -m tcp -p tcp --dport 53 -j ACCEPT
    -A INPUT -m state --state NEW -m udp -p udp --dport 53 -j ACCEPT
    # service iptables restart

DNSは基本的にUDPだけど[RFC1123](http://jbpe.tripod.com/rfcj/rfc1123.j.sjis.txt)のの6.1.3.2 トランスポートプロトコルには

> DNS サーバは、UDP キュエリをサービスできなければならず (MUST)、TCP キュエリ
をサービスできるべきである (SHOULD)。

と書いてある。TCPフォールバックのためだろうと思うが、「すべきである」と書いてあるのでTPCポートも開けておくことにする。

### 動作確認

別マシンの、drillインストール済みのMacから接続して動作確認してみる。まずはresolv.confの変更。

    $ vi /etc/resolv.conf
    nameserver 192.168.0.5 <- unboundが動作しているマシン

MacPortsでインストールしたdrillで動作確認。(nslookupとかでも良い)

    $ drill www.google.co.jp.
    ;; ->>HEADER<<- opcode: QUERY, rcode: NOERROR, id: 52878
    ;; flags: qr rd ra ; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 0
    ;; QUESTION SECTION:
    ;; www.google.co.jp. IN A
    
    ;; ANSWER SECTION:
    www.google.co.jp. 86400 IN CNAME www-cctld.l.google.com.
    www-cctld.l.google.com. 300 IN A 173.194.38.120
   
    ;; AUTHORITY SECTION:
    
    ;; ADDITIONAL SECTION:
    
    ;; Query time: 614 msec
    ;; SERVER: 192.168.0.5
    ;; WHEN: Fri Feb 17 19:05:43 2012
    ;; MSG SIZE  rcvd: 86

### 簡易的なコンテンツサーバの設定
unboundは簡易DNSコンテンツサーバとしての機能も持っているので、LAN内部でのみ名前解決するような場合は、その機能を使える。例えば、ドメイン名「blog.gitrhythm.net」を自宅サーバで動作させている場合、下記の様な指定をunbound.confに追加することで、内部LANからの名前解決をしてくれる。

    # vi /etc/unbound.conf
    local-data: "blog.gitrhythm.net. A 192.168.0.5" <- 追加
    ・・・・
    # unbound-checkconf
    # service unbound restart

Macから確認。

    # drill blog.gitrhythm.net.

### 見るべきログ

ログはsyslogに吐かれるようになっており、/var/log/messagesに書きこまれている。ログの出力先を変更する場合は[いつか、そのとき、あの場所で。 - Unboundのログ出力方法を変更。](http://kometchtech.blog45.fc2.com/blog-entry-386.html)を参考にすれば良いかと思う。

と言いつつ、まだ自分は試してません。
