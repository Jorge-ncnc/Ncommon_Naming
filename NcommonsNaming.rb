require "csv" #csvを扱うためのライブラリ
require 'open-uri' #URLにアクセスするためのライブラリ
require 'nokogiri' #htmlを扱うためのNokogiriライブラリ
require 'fileutils'

puts <<"EOS"
==================================================================
                【ニコニ・コモンズ素材命名ツール】
==================================================================
    [nc{数字}]に一致する部分を持つファイルのファイル名を
    コモンズID_素材名.hoge
    に書き換えます
------------------------------------------------------------------
EOS

#URLからページを読み込み、オブジェクトの作成
def get_html(url)
    charset = nil
    html = open(url) do |f|
      charset = f.charset #文字種別を取得
      f.read #htmlを読み込んで変数htmlに渡す
    end
    #文字化け対策
    if charset == "iso-8859-1"
      charset = html.scan(/charset="?([^\s"]*)/i).first.join
    end
    Nokogiri::HTML.parse(html, nil, charset) #htmlをパース(解析)してオブジェクトを生成
end

#main
ARGV.each{|fullpass|
    fullpass = fullpass.gsub(/\\/,"/")
    Dir.chdir(File.dirname(fullpass)) do
        filename = File.basename(fullpass)
        if !filename.match(/nc\d+/) then next end
        id = filename.match(/nc\d+/)[0]
        ext = filename.scan(/\.\w+/).last
        doc = get_html("http://commons.nicovideo.jp/material/#{id}")
        title = doc.xpath('//div[@class="commons_title"]').text
        title.gsub!(/【.*?】/,"") if title.gsub(/【.*】/,"")
        title.gsub!(/[\\\/:\*\?"<>\|]/, " ") if title.gsub!(/[\\\/:\*\?"<>\|]/, " ")
        newfile = "#{id}_#{title}#{ext}"
        if title != "" && filename.downcase != newfile.downcase then
            FileUtils.mv(filename, newfile, {:secure => true})
        end
        puts "#{(id + " "*9)[0,9]}#{(ext + " "*5)[1..5]}#{title != "" ? title : "【NO PAGE】"}"
        sleep 1
    end
}

puts <<"EOS"
==================================================================
処理が終了しました
何かキーを押して下さい
EOS
STDIN.set_encoding("Shift_JIS", "UTF-8").gets.chomp
