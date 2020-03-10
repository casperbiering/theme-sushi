function fish_prompt
    # Save the last status for later (do this before anything else)
    set -l last_status $status

    # Use a simple prompt on dumb terminals.
    if [ "$TERM" = "dumb" ]
        echo "> "
        return
    end

	set -l symbol "λ "

	if git::is_repo
		set -l branch (git::branch_name ^/dev/null)
		set -l anygit 0

		if git::is_stashed
			echo -n -s (white)"^"(off)
			set anygit 1
		end

		if git::is_dirty
			printf (white)"*"(off)
			set anygit 1
		end

		for remote in (git remote)
			set -l behind_count (echo (command git rev-list $branch..$remote/$branch ^/dev/null | wc -l | tr -d " "))
			set -l ahead_count (echo (command git rev-list $remote/$branch..$branch ^/dev/null | wc -l | tr -d " "))

			if test $ahead_count -ne 0; or test $behind_count -ne 0; and test (git remote | wc -l) -gt 1
				echo -n -s (orange)$remote(off)
				set anygit 1
			end

			if test $ahead_count -ne 0
				echo -n -s (white)"+"$ahead_count(off)
				set anygit 1
			end

			if test $behind_count -ne 0
				echo -n -s (white)"-"$behind_count(off)
				set anygit 1
			end
		end

		if test "$anygit" = 1
			echo -n " "
		end
	end

	if test "$last_status" = 0
		echo -n -s (red)"$symbol"(off)
	else
		echo -n -s (dim)"$symbol"(off)
	end

end
