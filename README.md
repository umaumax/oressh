# oressh

* oreore ssh command
  * create oreore environment on remote machine with minimal side effect

## how to use
```
oressh [ssh target host]
```

## settings
```
~/.config/oressh/{default,$host_name,...}/{.bashrc,.inputrc,.vimrc}
```

## NOTE
* This tool can accept only hostname, so if you want to use other args (e.g. -p 10022), use `~/.ssh/config`.
* You can use `ORESSH_HOST` environment variable at `.bashrc`.
* `--rcfile`と`--login`は共存しないため，`shopt login_shell`はfalseとなるので注意
* functionやaliasではsshpassから使用できないため，`oressh`コマンドとして提供
* defaultでpythonを利用して，base64のencodeとdecodeを行う(at both local host and remote host)
  * env `NO_PYTHON_BASE64`に何かしらの値を設定すると`base64`コマンドを利用する
* process substitutionが使用できない環境に限り，`ln -s /proc/self/fd /dev/fd`を実行するが，それ以外では，設定ファイルは作成しない
* hostの接続先によって、設定ファイルを選択する(読み込ませたくないファイルがある場合には，同名のファイルをそのhostに対応する場所に作成する)
  * `~/.config/oressh/default/`: 共通の処理
  * `~/.config/oressh/$host_name/`: each host
  * `~/.config/oressh/$host_name/.local.xxx`: each host (additional load)
* `.inputrc`は`bind -f`によって，2回`open/close`されるので，process substitutionは使用できない
  * `mktemp`で一時ファイルを作成している
  * `strace bind -f ~/.inputrc`とすると確認できる

## TODO
* write help command

## FYI
* [シェル芸で、ローカルにあるbashrcやvimrcをssh接続先で\(ファイルをコピーとかせずに\)利用する \| 俺的備忘録 〜なんかいろいろ〜]( https://orebibou.com/2018/10/%E3%82%B7%E3%82%A7%E3%83%AB%E8%8A%B8%E3%81%A7%E3%80%81%E3%83%AD%E3%83%BC%E3%82%AB%E3%83%AB%E3%81%AB%E3%81%82%E3%82%8Bbashrc%E3%82%84vimrc%E3%82%92ssh%E6%8E%A5%E7%B6%9A%E5%85%88%E3%81%A7%E3%83%95/ )
* [sshrc: ssh時に\.bashrc設定等をssh先に持っていけるコマンド]( https://rcmdnk.com/blog/2018/01/31/computer-bash-zsh-network/ )

* [bashrcの設定の読み込まれる順番 \- それマグで！]( http://takuya-1st.hatenablog.jp/entry/20110102/1293970212 )
* [bashの設定ファイルの読み込みが複雑すぎて混乱する \- ぱせらんメモ]( https://pasela.hatenablog.com/entry/20090209/bash )
