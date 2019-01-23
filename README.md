# oressh

oreore ssh command

## NOTE
* ssh先の環境を汚さずにoreore bashとoreore vimの設定を利用する
* functionやaliasではsshpassから使用できないため，コマンドとして提供
* defaultでpythonを利用して，base64のencodeとdecodeを行う(at both local host and remote host)
  * env `NO_PYTHON_BASE64`に何かしらの値を設定すると`base64`コマンドを利用する

## TODO
* write help command
* READMEの充実
* readline for bash
  * ~/.inputrcの設定も行いたいが，物理的にファイルを配置する必要性がありそうなので，副作用がある
* hostの接続先によって、設定ファイルを選択する
  * `~/.config/oressh/dotfiles/default/.bashrc`: 対応するhost_nameのdirがない場合
  * `~/.config/oressh/dotfiles/common/.bashrc`: 共通の処理
  * `~/.config/oressh/dotfiles/host_name/.bashrc`: each host

### for wgit
```
https://github.com/umaumax/oressh/blob/master/oressh.sh oressh
chmod u+x oressh
```

## Required
* [umaumax/dotfiles]( https://github.com/umaumax/dotfiles )

## FYI
[シェル芸で、ローカルにあるbashrcやvimrcをssh接続先で\(ファイルをコピーとかせずに\)利用する \| 俺的備忘録 〜なんかいろいろ〜]( https://orebibou.com/2018/10/%E3%82%B7%E3%82%A7%E3%83%AB%E8%8A%B8%E3%81%A7%E3%80%81%E3%83%AD%E3%83%BC%E3%82%AB%E3%83%AB%E3%81%AB%E3%81%82%E3%82%8Bbashrc%E3%82%84vimrc%E3%82%92ssh%E6%8E%A5%E7%B6%9A%E5%85%88%E3%81%A7%E3%83%95/ )
