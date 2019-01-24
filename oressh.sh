#!/usr/bin/env bash

# for alias (for bash)
shopt -s expand_aliases

mkdir -p ~/.config/oressh/default/

function cat_if_exist() {
	local filepath=$1
	[[ -f $filepath ]] && cat $filepath && return 0
	return 1
}

function find_exist_file() {
	for filepath in "$@"; do
		[[ -f "$filepath" ]] && echo "$filepath" && return 0
	done
	return 1
}

function oressh() {
	[[ $# -lt 1 ]] && echo "$0 [hostname]" && exit 1
	[[ $# -gt 1 ]] && echo "$0 [hostname]" && exit 1

	local host=$1

	# NOTE: python base64 version
	local remote_base64decode='python -c "import base64; import sys; x = base64.b64decode(sys.stdin.read()); sys.stdout.write(x) if sys.version_info[0] < 3 else sys.stdout.buffer.write(x)"'
	alias local_base64encode='python -c "import base64; import sys; x = base64.b64encode(sys.stdin.read() if sys.version_info[0] < 3 else sys.stdin.buffer.read()); sys.stdout.write(x) if sys.version_info[0] < 3 else sys.stdout.buffer.write(x)"'
	alias local_base64decode="$remote_base64decode"

	if [[ -n $NO_PYTHON_BASE64 ]]; then
		# NOTE: base64 command version
		local remote_base64decode="if [[ \$(uname) == Darwin ]]; then base64 -D; else base64 -d; fi"
		if [[ $(uname) == "Darwin" ]]; then
			alias local_base64encode='base64'
			alias local_base64decode='base64 -D'
		elif [[ $(uname -a) =~ "Ubuntu" ]]; then
			alias local_base64encode='base64 -w 0'
			alias local_base64decode='base64 -d'
		else
			echo 'This os is not supported!'
			return 1
		fi
	fi

	# NOTE: bash-3.2ではなぜか正常な動作とならないので，macの場合には無理やりlocalの方のbashを参照
	# NOTE: sh cannot parse $(() || ()) or [[ ]], and can't use process replace <(), so wrap entire command as bash
	# NOTE: したがって，bashでwrapしている
	# NOTE: 注意点として，shoptからlogin shellではないことになっている
	local bash_cmd='$( ( [ -e /usr/local/bin/bash ] && echo /usr/local/bin/bash ) || ( [ -e /bin/bash ] && echo /bin/bash ) )'

	local inputrc_filepath=$(find_exist_file "$HOME/.config/oressh/$host/.inputrc" "$HOME/.config/oressh/default/.inputrc")
	local vimrc_filepath=$(find_exist_file "$HOME/.config/oressh/$host/.vimrc" "$HOME/.config/oressh/default/.vimrc")

	# FYI: [How to fix the /dev/fd/63: No such file or directory? – Site Title]( https://jaredsburrows.wordpress.com/2014/06/25/how-to-fix-the-devfd63-no-such-file-or-directory/ )
	# NOTE: This command has side effect
	local enable_process_substitution_cmd='[[ $USER == "root" ]] && [[ ! -e /dev/fd ]] && ln -s /proc/self/fd /dev/fd'
	ssh -t -t $host "$enable_process_substitution_cmd; bash -c '$bash_cmd --rcfile <( echo -e " \
		$({
			# .vimrc
			[[ -n $vimrc_filepath ]] && echo 'type vim >/dev/null 2>&1 && function vim() { command vim -u <(echo '$(cat ~/dotfiles/.minimal.vimrc | local_base64encode)' | '$remote_base64decode') $@ ; }'
			[[ -n $vimrc_filepath ]] && echo 'type vi  >/dev/null 2>&1 && function vi()  { command vi -u <(echo '$(cat ~/dotfiles/.minimal.vimrc | local_base64encode)' | '$remote_base64decode') $@ ; }'
			# .inputrc
			# NOTE: cat wrapper is for avoid below error (maybe python error)
			# close failed in file object destructor: sys.excepthook is missing lost sys.stderr
			[[ -n $inputrc_filepath ]] && echo 'bind -f <(cat <(echo '$(cat "$inputrc_filepath" | local_base64encode)' | '$remote_base64decode'))'
			# .bashrc
			cat_if_exist "$HOME/.config/oressh/$host/.bashrc" || cat_if_exist "$HOME/.config/oressh/default/.bashrc"
		} | local_base64encode) \
		" | $remote_base64decode)'"
	# NOTE: ~/.inputrcはprocess substitutionで指定してはならない?最初に設定後にrmする分には問題なさそう
	# bashに入ってから<()で入力する分には問題ない
	# 			cat <(echo 'bind -f ~/github.com/oressh/.inputrc')
	# 			cat <(echo 'bind -f <(echo '$(cat ~/dotfiles/.inputrc | local_base64encode)' | '$remote_base64decode')')
}

oressh $1
