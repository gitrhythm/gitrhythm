title: 複数のサービスで1つのコメントテーブルを利用する(3) - 失敗
slug: how_to_use_one_comment_table3

**このエントリは間違ったことは書いてないと思いますが、見当違いな事を書いてました。修正版を[次のエントリ](/blog/2012/01/14/how_to_use_one_comment_table3-2/)としてアップしましたので、そちらを参照下さい m(\_ \_)m**

[前回](/blog/2011/12/21/how_to_use_one_comment_table2/)から大分間が開いてしまったけど、CommentsControllerがcommentableなモデルのクラス名を取得する方法を幾つか試してみた。 結論から言うとこれと言って良いアイデアは出ませんでした orz  
以下試してみたことです。

### resource情報から親コントローラ名を取得出来ないか？
コントローラでparams[:id]とかでURLからidを取得できるんだから、route.rbの定義とURLを突き合わせて色々と情報を取得できるAPIでも無いかしら？と思って調べてみた。 がしかし、そのようなAPIは無いみたい。

paramsメソッドを取っ掛かりとしてコードを追いかけてみると、最終的にrack-mount/route_set.rbに行き着いた。rack-mountが何者なのかいまいち理解出来ていないんだけど、多分こいつがRailsフレームワークを使ったWebアプリの大本である、所謂Rackアプリなんじゃないかと思う。(確証は無いです)

で、その辺りとかparamsの辺りのコードを大雑把に見てみると、rack-mountがparamsで必要になる情報を環境変数にセットして(paramsそのものだったかも？)、コントローラ側ではその環境変数から値を取得してきているような雰囲気。なので何かルーティング用のAPIが用意されている訳では無いっぽい。
じゃ、paramsの値をセットするロジックそのものをごっそりコピってごにょごにょすれば良いんじゃね？とも思ったけど、今の自分にはコードが難解過ぎて早々と諦めました hahaha ^_^;)

### コントローラからコントローラ名をhiddenパラメータでセットする
多分これが一番現実的な方法なんだと思うのだけど、管理者権限でコメントの削除を画面上から出来るようにしたいなぁと思っていて、

    <%= link_to 'delete', [comment.commentable, comment],
             'data-commenttype' => 'controller_name',
             :confirm => 'Are you sure?',                 
             :method => :delete %>

のようにdata-commenttypeにコントローラ名を渡して、それをサーバ側で取得する方法を試してみた。だけど、どうもそれは出来ないみたい。jquery_ujs.jsのhandleMethodメソッドを読んでみると、独自データ属性を指定してそれをサーバに送るようにはなっていない感じ。<br />
じゃそれ用のJavaScriptを書くか削除用のformを付けるかすれば良いんだけど、今のところどちらも気分が乗らないのでそれも諦めた (笑)

ってことで、今まで通りURLの特定の位置からコントローラ名を取得する方法に落ち着きました。 でもこの方法は良いやり方だとは思ってないので、多分最終的にはHTMLにコントローラ名をパラメータで渡す方法に落ち着くんだと思う。

因みにコントローラ名からモデルのインスタンスを生成するには

    'controller_names'.classify.constantize

のようにすると出来る。 classifyは複数形を単数形にして、更にアンダーバーを取り除いてパスカル記法に沿った名前を生成してくれるっぽい。 constantizeはクラス名文字列からクラスのインスタンスを生成してくれる。コントローラ名が`blog_entries`ならclassifyにより`BlogEntry`になり、constantizeでBlogEntryのインスタンスを生成する。
