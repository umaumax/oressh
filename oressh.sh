#!/usr/bin/env bash

# for alias (for bash)
shopt -s expand_aliases

function oressh() {
	[[ $# -le 0 ]] && echo "$0 hostname" && exit 1
	local host=$1

	# NOTE: python base64 version
	local remote_base64decode="python -c \"import base64; import sys; sys.stdout.write(base64.b64decode(sys.stdin.read()).decode(\\\"utf-8\\\"))\""
	alias local_base64encode="python -c \"import base64; import sys; sys.stdout.write(base64.b64encode(sys.stdin.read() if sys.version_info[0]<3 else sys.stdin.buffer.read()).decode('utf-8'))\""
	alias local_base64decode="$remote_base64decode"

	# NOTE: base64 command version
	# 	if [[ $(uname) == "Darwin" ]]; then
	# 		alias local_base64encode='base64'
	# 		alias local_base64decode='base64 -D'
	# 	elif [[ $(uname -a) =~ "Ubuntu" ]]; then
	# 		alias local_base64encode='base64 -w 0'
	# 		alias local_base64decode='base64 -d'
	# 	else
	# 		echo 'no support os'
	# 		return 1
	# 	fi
	# 	local remote_base64decode="if [[ \$(uname) == Darwin ]]; then base64 -D; else base64 -d; fi"

	# NOTE: bash-3.2ではなぜか正常な動作とならないので，macの場合には無理やりlocalの方のbashを参照
	# NOTE: sh cannot parse $(() || ()) or [[ ]], and can't use process replace <(), so wrap entire command as bash
	# NOTE: したがって，bashでwrapしている
	# NOTE: 注意点として，shoptからlogin shellではないことになっている
	local bash_cmd='$( ( [ -e /usr/local/bin/bash ] && echo /usr/local/bin/bash ) || ( [ -e /bin/bash ] && echo /bin/bash ) )'
	command ssh -t -t $host "bash -c '$bash_cmd --rcfile <( echo -e " \
		$({
			cat <(echo 'function vim() { command vim -u <(echo '$(cat ~/dotfiles/.minimal.vimrc | local_base64encode)' | '$remote_base64decode') $@ ; }')
			cat ~/dotfiles/.minimal.bashrc
		} | local_base64encode) \
		" | $remote_base64decode)'"
}

oressh $1
