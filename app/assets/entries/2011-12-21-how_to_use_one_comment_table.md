title: 複数のサービスで1つのコメントテーブルを利用する
slug: how_to_use_one_comment_table

Railsで複数のサービスから1つのコメントテーブルを参照出来ないか？と思って試してみたんだけど、ひとまず1つ目の案が出来たのでメモっておきます。

例えば1つのアプリケーションにブログ機能とFlickrのような写真管理機能があったとして、その両方にコメントを付けることが出来るとする。 ブログ用と写真管理用それぞれにコメントテーブルを用意してあげればそれが一番実装は単純なんだけど、それもなんかなんだなぁって気もするので複数のサービスから1つのコメントテーブルを参照する方法を試してみた。 ブログサービスのモデルがBlog、写真管理サービスのモデルがPhotoとして、コメントテーブルがそれぞれのサービスのidを保持するようにしてみる。

まずはroutes.rbにリソースを定義。
<script src="https://gist.github.com/1502056.js?file=routes.rb"></script>

次にDB。コメントテーブルはblog_idとphoto_idを持つ。
<script src="https://gist.github.com/1502056.js?file=schema.rb"></script>

次にモデル。BlogとPhotoはそれぞれコメントを複数持てる。
<script src="https://gist.github.com/1502056.js?file=blog.rb"></script>
<script src="https://gist.github.com/1502056.js?file=photo.rb"></script>

CommentはBlogとPhotoに関連付けられる。
<script src="https://gist.github.com/1502056.js?file=comment.rb"></script>

Viewではコメント入力欄があって、コメントをポストすると`blogs/<blog_id>/comments/<id>`のようなネストしたURLで`CommentController`に制御が渡ってくる。 `CommentController`ではどのサービスからコメントが投稿されたのかを知らないといけないので、そこはURLパスが`/blogs/...`か`/photos/...`かで判断してモデルを求めることとする。 後はそのモデルに対してコメントを追加する。
<script src="https://gist.github.com/1502056.js?file=comments_controller.rb"></script>

これで複数のサービスから1つのコメントテーブルを参照出来たんだけど、気になる点が2つ。

1. サービスが増えるとコメントテーブルに外部キーフィールドを追加しないといけない
2. URLとコントローラが密結合

1については、1テーブルにつき1外部キーフィールドじゃなくて、サービス名・外部キーフィールドの2つがあればよいんじゃないか？

2については、今回のパターンではサービス名がURLのパスにあることが前提だけど、サブドメインにしたらコードも弄らないといけない。

と言うことで、次回はその辺をどうにかしたいと思っているけど、2についてはどうにもならないかな？って気もしてます。
