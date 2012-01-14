title: 複数のサービスで1つのコメントテーブルを利用する(3)
slug: how_to_use_one_comment_table3-2

えーっと、前のエントリ[複数のサービスで1つのコメントテーブルを利用する(3) - 失敗](blog/2012/01/14/how_to_use_one_comment_table3/)の修正版です ^\_^;) 前のエントリではちょっと見当違いなことをやっていたのを[@\_\_69\_\_](https://twitter.com/#!/__69__)さんの[ツィート](https://twitter.com/#!/__69__/status/158145128639381504)での指摘で気付きました。とりあえず、前のエントリはそのまま残して新たにエントリを追加しました。(<small>@\_\_69\_\_さん、ご指摘有難うございます m(_ _)m</small>)

### やりたかったこと
元々やりたかったことは

1. 複数のサービスがあって、それらで一つのコメントテーブルを共有したい
2. それぞれのサービスでコメントの登録、削除をしたい

でした。

1つ目は前々回のエントリ[複数のサービスで1つのコメントテーブルを利用する(2)](blog/2011/12/21/how_to_use_one_comment_table2/)で実現出来ました。で、2つ目をどうするか？を[前回](blog/2012/01/14/how_to_use_one_comment_table3/)のエントリで書いた訳ですが、そもそもそんな回りくどい事しないでもっとスッキリと実装出来るのでした。

### コメントの追加
サービスの画面でコメントを追加する際に、commentable_typeとcommentable_idをhiddenフィールドにセットしておけばそれで良く、comments_controllerではその2つの情報を元にコメント元のサービスのエントリを特定出来、関連付けてDBに登録することが出来る。

フォーム画面

    <%= form_for([@blog, @blog.comments.build]) do |f| %>
      <p><%= f.hidden_field :commentable_type, :value => @blog.class.name %></p>
      <p><%= f.hidden_field :commentable_id, :value => @blog.id %></p>
      <div class="field">
        <%= f.label :commenter %><br />
        <%= f.text_field :commenter %>
      </div>
      <div class="field">
        <%= f.label :body %><br />
        <%= f.text_area :body, rows: '5' %>
      </div>
      <div class="actions">
        <%= f.submit %>
      </div>
    <% end %>

comments_controller

    def create
      @comment = Comment.new(params[:comment])
      @comment.save
      redirect_to @comment.commentable
    end

`Comment.new`の時点でcommentable_typeとcommentable_idがセットされているのでサービスとの関連付けが出来ている。@comment.commentableでコメントと関連付けされたサービスのインスタンスを取得出来るので、そこ(この例ではblogs/show/<id>)にリダイレクトする。

削除する場合は、単純にcommentのidで検索すれば該当コメントを取得出来るし、やはり@comment.commentableで対象エントリにリダイレクトすれば良い。

    def destroy
      @comment = Comment.find(params[:id])
      @comment.destroy
      redirect_to @comment.commentable
    end

と、頑張って自分でゴリゴリと書かなくても出来ますね。 まだまだ修行が足りません (~_~;)
