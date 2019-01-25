#!/usr/bin/env bash

# for alias (for bash)
shopt -s expand_aliases

mkdir -p ~/.config/oressh/default/

function help() {
	echo "$0 [hostname]"
	cat <<EOF
e.g.
# don't use python base64 (use base64 comand)
NO_PYTHON_BASE64=1 $0
# for debug
DEBUG=1 $0
EOF
}

function oressh() {
	if [[ $# -lt 1 ]] || [[ $# -gt 1 ]]; then
		help
		exit 1
	fi

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
	local bashrc_filepath=$(find_exist_file "$HOME/.config/oressh/$host/.bashrc" "$HOME/.config/oressh/default/.bashrc")
	debug ".inpurc:[$inputrc_filepath]"
	debug ".vimrc :[$vimrc_filepath]"
	debug ".bashrc:[$bashrc_filepath]"

	# FYI: [How to fix the /dev/fd/63: No such file or directory? – Site Title]( https://jaredsburrows.wordpress.com/2014/06/25/how-to-fix-the-devfd63-no-such-file-or-directory/ )
	# NOTE: This command has side effect
	local enable_process_substitution_cmd='[[ $USER == "root" ]] && [[ ! -e /dev/fd ]] && ln -s /proc/self/fd /dev/fd'
	ssh -t -t $host "$enable_process_substitution_cmd; bash -c '$bash_cmd --rcfile <( echo -e " \
		$({
			# .vimrc
			if [[ -n $vimrc_filepath ]]; then
				echo 'type vim >/dev/null 2>&1 && function vim() { command vim -u '$(cat_base64_fd $vimrc_filepath)' $@ ; }'
				echo 'type vi  >/dev/null 2>&1 && function vi()  { command vim -u '$(cat_base64_fd $vimrc_filepath)' $@ ; }'
			fi
			# .inputrc
			# NOTE: bind -f .inputrc: not load properly using process substitution (maybe read file twice?)
			# maybe bind -f read file twice? (process substitution can be only once)
			if [[ -n $inputrc_filepath ]]; then
				echo 'function _cat_inputrc(){ echo '$(cat_base64 $inputrc_filepath)'; }'
				echo 'function _bind_inputrc(){ local tmpinputrc=$(mktemp); [[ -f $tmpinputrc ]] && _cat_inputrc > $tmpinputrc && bind -f $tmpinputrc; [[ -f $tmpinputrc ]] && echo rm -rf $tmpinputrc; }'
				echo '_bind_inputrc'
			fi
			# .bashrc
			if [[ -n $bashrc_filepath ]]; then
				cat $bashrc_filepath
			fi
		} | local_base64encode) \
		" | $remote_base64decode)'"
}

function cat_base64() {
	[[ $# == 0 ]] && return 1
	echo -n $(cat $1 | local_base64encode)' | '$remote_base64decode
}
function cat_base64_fd() {
	[[ $# == 0 ]] && return 1
	# NOTE: cat wrapper is for avoid below error (maybe python error)
	# close failed in file object destructor: sys.excepthook is missing lost sys.stderr
	echo -n '<(cat <(echo '$(cat_base64 "$@")'))'
}

function debug() {
	[[ -n $DEBUG ]] && echo "[DEBUG] $*"
}

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

oressh $1
