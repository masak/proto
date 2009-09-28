# Proto tab-completion
#
# This assumes you are running proto while in its directory, eg.
# ~/proto$ ./proto <tab>
# ~/proto$ ./proto install <tab>
#
# To install drop this file into /etc/bash_completion.d/
# or add this line to your .bashrc:
# 	source /path/to/proto/tab-completion.sh
# and open a new terminal

_proto ()
{
	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}

	cmds='install update uninstall test showdeps help'
	
	if [[ $COMP_CWORD -eq 1 ]] ; then
		COMPREPLY=( $( compgen -W "$cmds" -- $cur ) )
		return 0
	fi

	if [[ $COMP_CWORD > 1 ]]; then
		COMPREPLY=( $( compgen -W '$( command cat projects.list \
			| grep -i '^[a-z0-9\-]*:$' \
			| sed -e 's/://' )' -- $cur ) )
		return 0
	fi
}

complete -F _proto -o default ./proto
