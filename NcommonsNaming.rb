require 'open-uri' #ネットに繋げるやべーやつ
require 'nokogiri' #htmlを切り刻むやべーやつ
require 'fileutils' #ファイル操作するやつ

puts <<"EOS"
==================================================================
                【ニコニ・コモンズ素材命名ツール】
==================================================================
[nc{数字}]に一致する部分を持つファイルのファイル名を
コモンズID_素材名.hoge
に書き換えます
------------------------------------------------------------------
EOS

#URLからページを読み込み、オブジェクトの生成
def get_html(url)
    charset = nil
    html = open(url) do |f|
      charset = f.charset #文字種別を取得
      f.read #htmlを読み込んで変数htmlに渡す
    end
    charset = html.scan(/charset="?([^\s"]*)/i).first.join if charset == "iso-8859-1" #文字化け対策
    Nokogiri::HTML.parse(html, nil, charset) #htmlをパース(解析)してオブジェクトを生成
end

#main --コマンドライン引数に該当するファイルをフルパスでD&Dしてる前提
ARGV.each{|fullpass|
    fullpass = fullpass.gsub(/\\/,"/") #ディレクトリの表示が\だと困るから/にする
    Dir.chdir(File.dirname(fullpass)) do #ファイルの存在するディレクトリに移動
        filename = File.basename(fullpass) #現在のファイル名
        next if !filename.match(/nc\d+/) #該当する文字列がない場合次のファイルに
        id = filename.match(/nc\d+/)[0] #コモンズID
        ext = filename.scan(/\.\w+/).last #拡張子
        doc = get_html("http://commons.nicovideo.jp/material/#{id}") #Nokogiriでコモンズの素材ページを切り刻む
        title = doc.xpath('//div[@class="commons_title"]').text #素材タイトル取得、素材が存在しない場合""が返る
        title.gsub!(/【.*?】/,"") if title.gsub(/【.*】/,"") #「【ジャンル】素材名【補足】」みたいな名前が多いので【】で挟まれた部分をタイトルから削除
        title.gsub!(/[\\\/:\*\?"<>\|]/, " ") if title.gsub!(/[\\\/:\*\?"<>\|]/, " ") #ファイル名に使えない文字をスペースで置換
        newfile = "#{id}_#{title}#{ext}" #新しいファイル名
        if title != "" && filename.downcase != newfile.downcase then #素材が存在すること、それと元の名前と書き換えたい名前が同じだとエラーになる
            FileUtils.mv(filename, newfile, {:secure => true})
        end
        puts "#{(id + " "*9)[0,9]}#{(ext + " "*5)[1..5]}#{title != "" ? title : "【NO PAGE】"}" #素材が多いと時間かかって不安になるから進捗代わりに表示しておく
        sleep 1 #一気にやると怒られるから1秒待つ
    end
}

puts <<"EOS" if ARGV.length == 0 #ダブルクリックで起動された時の想定
この実行ファイルに[nc{数字}]を名前に含むファイルを
ドラッグ＆ドロップすることで
コモンズのページから素材名を取得してリネームします
複数のファイルをまとめてD&Dすることも可能です

エラーが発生する場合、短時間にアクセスを行いすぎていることが
原因の場合が考えられます
時間をおいてもう一度動かしてみて下さい

同名のファイルが存在する場合上書きされます
EOS

puts <<"EOS"
==================================================================
処理が終了しました
何かキーを押して下さい
EOS
STDIN.set_encoding("Shift_JIS", "UTF-8").gets.chomp #コマンドライン引数があるとgetsだけだとなんかうまく動かない
