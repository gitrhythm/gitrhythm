title: 画面スクロール用のショートカットキーを入れてみました
slug: added_a_shortcut_key_for_scrolling

本ブログに画面スクロール用のショートカットキーの機能を加えてみました。定義したショートカットーキーは次の5つです。ひょっとしたらむしろ邪魔な機能かも知れませんが試してみてください (´ｰ`)

* I: インデックスページへ遷移します
* J: カーソルを上に移動
* K: カーソルを下に移動
* A: 画面の先頭に移動
* E: 画面の末尾に移動

と、これだけだとあっさりし過ぎなので、実装方法を少し書いておきます。

ショートカットキー用のライブラリとして`shortcut.js`を使用しています。これは[WEBアプリに超絶簡単にJavaScriptのキーボードショートカット機能を実装する「shortcuts.js」](http://phpspot.org/blog/archives/2007/04/webjavascriptsh.html)で知りました。shortcut.jsは[Handling Keyboard Shortcuts in JavaScript](http://www.openjs.com/scripts/events/keyboard_shortcuts/)から入手できます。

ショートカットキーの実装は以下です。まぁ、たったこれだけです。

    jQuery ->
      scroll = (top) -> $(window).scrollTop(top)
      distance = (offset) -> $(window).scrollTop() + offset
    
      shortcut.add('I', -> document.location = '/')
      shortcut.add('A', -> scroll(0))
      shortcut.add('E', -> scroll($('body').height()))
      shortcut.add('J', (-> scroll(distance 25)), type: 'keypress')
      shortcut.add('K', (-> scroll(distance -25)), type: 'keypress')

大した量も多くないので、勉強も兼ねてCoffeeScriptで書いてみました。スクロールは全てjQueryの`scrollTop`を使ってます。上下のカーソル移動は25pixelづつ移動するようにしてみました。`type: 'keypress'`は、shortcut.jsにショートカットをどのイベントで扱うかを指定するオプション。shortcut.jsのデフォルト値は`keydown`になってるんだけど、`keydown`ではFireFoxやOperaでキーを押しっぱなしにしていても一度しかイベントが発火しないので`keypress`を指定してます。画面の先頭・末尾は、最初のうちは

    $('html,body').animate({scrollTop: 0}, 500);

のようにanimateでやってました。animateはスクロールがスムーズで良い感じなんですよね。ただ、animateの場合はSafariやChromeでキーを押しっぱなしにしていると(例えば先頭に移動するのに「A」を押しっぱなし)、何度もanimateの処理が実行されてしまい中々制御が戻ってこないのが不満です。 かと言ってdurationの値(上記例の500)を短くすると、結局見た感じscrollTopを使っているのと変わりがない訳で、今回はanimateの利用は諦めました。<br />
これって例えば「animateの処理中はキー入力を受け付けない」等なんらかの制御で回避可能なのかも知れないけど、今回は慣れないCoffeeScriptとの格闘で疲れてしまったので、その辺の追求はやめときます。

あと、「前のエントリ」「次のエントリ」用のショートカットキーも定義しようかと思ったけど、そもそもこのブログの画面にそのためのリンクが無いので、それも今回は見送ることにします。そこはブログの機能が充実してきたら改めて考えようかと思います。
