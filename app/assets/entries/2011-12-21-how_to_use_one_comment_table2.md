title: 複数のサービスで1つのコメントテーブルを利用する(2)
slug: how_to_use_one_comment_table2

[前回](/blog/2011/12/20/how_to_use_one_comment_table/)の続きで、コメントテーブルのフィールドをリファクタリングしてみる。

前回はコメントテーブルに`blog_id`と`photo_id`を持っていて、このやり方だとサービスが増減する度にいちいちコメントテーブルに外部キーを追加したり削ったりしないといけないのが嫌なのでした。で、これを外部キーフィールド１つ、サービス名フィールド１にして、この２つをキーとして検索すれば一意にコメントを特定できるんじゃないかと・・・

調べてみるとActiveRecordの[Polymorphic Associations](http://guides.rubyonrails.org/association_basics.html#polymorphic-associations)が利用できそうだと言うことが分かったので試してみる。<small>(実際に参照したのは[ruby/rails/RailsGuidesをゆっくり和訳してみたよ/Active Record Associations](http://wiki.usagee.co.jp/ruby/rails/RailsGuides%E3%82%92%E3%82%86%E3%81%A3%E3%81%8F%E3%82%8A%E5%92%8C%E8%A8%B3%E3%81%97%E3%81%A6%E3%81%BF%E3%81%9F%E3%82%88/Active%20Record%20Associations#t758e640)だけど・・・)</small>

まず、Commentモデルをポリモーフィックなbelongs_to宣言に書き換える。
<script src="https://gist.github.com/1505127.js?file=comment.rb"></script>

BlogモデルとPhotoモデルもcommentをcommentableとして扱うように書き換える。
<script src="https://gist.github.com/1505127.js?file=blog.rb"></script>
<script src="https://gist.github.com/1505127.js?file=photo.rb"></script>

これはCommentモデルからは、BlogもPhotoもcommentableインターフェースとして扱うって感じなんでしょうか・・・。まぁ多分そんな感じかな？と理解しときました。感覚的に名称はcommentableよりもserviceの方が良いかな？って気もするけど、これをインターフェースとして捉えると「コメント可能な何か」ってことでcommentableもありかなって気もするし、先日[@\_\_69\_\_](https://twitter.com/#!/__69__) さんに教えてもらった[act_as_commentable](https://sites.google.com/site/railssiryou/gem/-16-a-commenting-system---part-1-acts_as_commentableno-yi-denamono)でもcommentable使ってるからこれで良いのでしょう。

で、コメントテーブルは`blog_id`、`photo_id`を削除して`commentable_id`,`commentable_type`を追加する。
<script src="https://gist.github.com/1505127.js?file=schema.rb"></script>

Viewで`comment.blog`とか`comment.photo`があれば`comment.commentable`に書き換え、`rake db:reset`して実行。

OK。DBのリファクタリングが旨くいきました。旨く行ったんだけどRailsが何をやってるかいまいちよく分からないので、ログだけでも確認してみる。

`rails c`でコンソール起動
    % rails c
    % ruby-xxx > blog = Blog.find(1)
    SELECT "blogs".* FROM "blogs" WHERE "blogs"."id" = ? LIMIT 1  [["id", 1]] 
    % ruby-xxx > p blog.comments
    % > SELECT "comments".* FROM "comments"
        WHERE "comments"."commentable_id" = 1 AND "comments"."commentable_type" = 'Blog'

Blogから記事を検索して`blog.comments`でコメントを取得しようとすると、commentテーブルへのselectが発行されている。 `Blog.find(1)`で取得したレコードなのでそのIDがcommentable_idに使われ、commentable_typeにはモデルのクラス名が使われているっぽい。 続けてcommentを追加してみる。

    % ruby-xxx > blog.comments.create(commenter: 'ore', body: 'comment body.')
    INSERT INTO "comments" ("body", "commentable_id", "commentable_type", 
        "commenter", "created_at", "updated_at") 
    VALUES (?, ?, ?, ?, ?, ?) [["body", "comment body."], ["commentable_id", 1], 
        ["commentable_type", "Blog"], ["commenter", "ore"], 
        ["created_at", Wed, 21 Dec 2011 09:30:44 UTC +00:00], 
        ["updated_at", Wed, 21 Dec 2011 09:30:44 UTC +00:00]]

この様なSQLが発行されていて、やっぱりidは1、commentable_typeにはモデルのクラス名が使われている。`Comment.create(...)の様に直接Commentモデルからコメントデータをインサートしたなら、idとtype]は自前でセットしないといけないんだろうけど、blogから辿った場合は自動でblogインスタンスの情報を元にidとtypeがセットされるみたい。 勿論Blogモデルから`has_many :comments, :as => :commentable`の宣言を削除するとエラーになる。

こんな感じで、コメントのインサート時にはcommentableなモデルのidとtype(モデルクラス名)が書きこまれ、コメント検索時にはそのidとtypeをキーとして検索されている。

DBのリファクタリングはここまでにして、次回はCommentsControllerがcommentableなモデルのクラス名を取得する部分、要はBlogなのかPhotoなのかを判定する部分を、どうにか出来ないか試してみたい。
