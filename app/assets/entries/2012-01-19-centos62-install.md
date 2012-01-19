title: CentOS 6.2インストールメモ
slug: centos62-install

MacBook ProにCentOS 6.2をクリーンインストールした際のメモです。

### 参考にした記事
* [はじめての自宅サーバ構築 - Fedora/CentOS](http://kajuhome.com/centos6_inst.shtml)
* [CentOS 6 インストール](http://www11.ocn.ne.jp/~mizuniwa/c6/c601.html)

### 初期画面／言語／キーボードの選択
DVDを挿入してキーボードから「c」を押しながら電源ON。<br />
初期画面(Welcome to CentOS 6.2!)が表示されるので「*Install system with basic video driver*」を選択する。 因みに「Install or upgrade an existing system」を選択すると、インストーラのブート時に

    detecting hardware...
    waiting for hardware to initialize...

の部分で止まってしまい、インストールを続行出来なかった。<br />
VMWare Fusion上にインストールする場合は、逆に「Install or upgrade an existing system」を選択する。「Install system with basic video driver」を選択すると、画面サイズの調整が旨くいっていないらしく、Anacondaの画面下部のボタンが表示されないため操作が出来ない。

言語は*Japanese(日本語)*、キーボードタイプは*英語(アメリカ合衆国)*を選択する。usキーボードの候補として「英語(USインターナショナル)」「英語(アメリカ合衆国)」が出てくるが、**USインターナショナルを選んではいけない。**これを選択するとコンソールで「`」がエコーバックされなくなる。尚、USインターナショナルを選択してインストールしてしまった場合は、インストール後に/etc/sysconfig/keyboardファイルを開き、USインターナショナルの設定であったものをアメリカ合衆国の設定に変更してシステムを再起動することにより設定を変更することが出来る。(<small>[SVX日記 - sshの公開鍵を公開してみる](http://itline.jp/~svx/diary/?date=20050920)の後半部分も参考になる。</small>)

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

設定の反映は、下記のようにserviceコマンドで出来るような記述を幾つか見かけたけど、CentOS 6.2では出来ないっぽい。

    $ su
    # /sbin/service keytable restart
    keytable: unrecognized service

ってことで、keyboardファイルの反映方法は良く分からないけど、再起動せずにキーテーブルを変更するなら、loadkeysコマンドで直接キーマップファイルを読み込むと反映される。

    # loadkeys /lib/kbd/keymaps/i386/qwerty/us.map.gz

### ディスク／ネットワーク／タイムゾーンの設定
インストール先ストレージデバイスは、ローカルのHDにインストールするので*Basic Storage Devices*を選択する。既にLinuxがインストールされている場合、新規かアップグレードかを聞いてくる。今回は*新規インストール*を選択。<br />

以下の手順でネットワークを設定

* ホスト名設定画面で「Configure Network」をクリック
* ネットワーク設定画面が表示されるので、「System eth0」を選択して「編集」をクリック
* 「自動接続する」をチェックする
* 必要ならばIPv4/IPv6セッティング画面で「方式」を手動に変更し、アドレス等必要な情報を入力する

タイムゾーンは*アジア／東京*とし、*システムクロックでUTCを使用*は外しておく。<small>(システムクロックうんぬんは、ぐぐってみると「外した方が楽」みたいな記事を見かけるので外してみたけど、余り良く理解していないので、[第8回 Linux時刻管理の仕組みと設定](http://jibun.atmarkit.co.jp/lskill01/rensai/lpicdrill08/lpicdrill01.html)を読んで理解したい)</small>

インストールタイプは*Create Custom Layout*を選択する。パーティション編集画面が表示されるので、以下の手順でパーティションを作成する。<br />

* 一旦全てのパーティションを削除する
* bootパーティションの作成
  * sdbを選択して「作成」クリック
  * 「標準パーティション」を選択して「作成」クリック
  * マウントポイントに/boot、ファイルシステムタイプにext4、サイズ768、固定容量、「基本パーティションにする」をチェックし「OK」クリック。(**「基本パーティションにする」をチェックするのはbootパーティションのみ。この後作成するswap, /ではチェックしない**)
* swapパーティションの作成
  * 空きを選択して「作成」クリック
  * 「標準パーティション」を選択して「作成」クリック
  *  ファイルシステムタイプにswap、サイズ1024、固定容量として「OK」クリック。
* /パーティション作成
  * swap同様「空き」を選択し「標準パーティション」で「作成」クリック
  * マウントポイントに/、ファイルシステムタイプにext4、「最大許容量まで使用」をチェックして「OK」クリック。

Writing storage configuration to diskダイアログが表示されるので、「Write changes to disk」をクリックする。ブートローダの設定もそのまま(Install boot loader on /dev/sdb1がチェック済み)で「次へ」クリック。

### インストールパッケージの選択

* Minimalを選択して「今すぐカスタマイズ」をチェックし、「次」クリック<small>(「今すぐカスタマイズ」をチェックすると、次画面でインストールするパッケージをカスタマイズ出来る)</small>
* ベースシステムから*ベース*を選択して「追加パッケージ」をクリック
* その中から次をチェックし、それ以外は取り敢えず外しておく。
  * setuptool
  * system-config-firewall-tui
  * system-config-network-tui
  * wget
* 開発から*開発ツール*を選択し、Subversion, CVS, rcsは当面使う予定は無いので外しておく。

### アップデート
再起動後、yumでパッケージをアップデートしておく。

    # yum check-update
    # yum update
