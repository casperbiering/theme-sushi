# Colors
function orange
    set_color -o ee5819
end

function yellow
    set_color -o b58900
end

function red
    set_color -o d30102
end

function cyan
    set_color -o 2aa198
end

function white
    set_color -o fdf6e3
end

function dim
    set_color -o 4f4f4f
end

function off
    set_color -o normal
end

# Git
function git::is_repo
	test -d .git; or command git rev-parse --git-dir >/dev/null ^/dev/null
end

function git::ahead -a ahead behind diverged none
	not git::is_repo; and return

	set -l commit_count (command git rev-list --count --left-right "@{upstream}...HEAD" ^/dev/null)

	switch "$commit_count"
  case ""
	  # no upstream
  case "0"\t"0"
	  test -n "$none"; and echo "$none"; or echo ""
  case "*"\t"0"
	  test -n "$behind"; and echo "$behind"; or echo "-"
  case "0"\t"*"
	  test -n "$ahead"; and echo "$ahead"; or echo "+"
  case "*"
	  test -n "$diverged"; and echo "$diverged"; or echo "±"
	end
end

function git::branch_name
	git::is_repo; and begin
		command git symbolic-ref --short HEAD ^/dev/null;
		or command git show-ref --head -s --abbrev | head -n1 ^/dev/null
	end
end

function git::is_dirty
	git::is_repo; and not command git diff --no-ext-diff --quiet --exit-code
end

function git::is_staged
	git::is_repo; and begin
		not command git diff --cached --no-ext-diff --quiet --exit-code
	end
end

function git::is_stashed
	git::is_repo; and begin
		command git rev-parse --verify --quiet refs/stash >/dev/null
	end
end

function git::is_touched
	git::is_repo; and begin
		test -n (echo (command git status --porcelain))
	end
end

function git::untracked
	git::is_repo; and begin
		command git ls-files --other --exclude-standard
	end
end

# Kubernetes

function k8s::current_context
    command kubectl config current-context
end

function k8s::current_namespace
    command kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}'
end

# Terraform

# Test whether this is a terraform directory by finding .tf files
function terraform::directory
	command find . -name '*.tf' >/dev/null ^/dev/null -maxdepth 0
end

function terraform::workspace
	terraform::directory; and begin
		test -e .terraform/environment
	end
end

function fish_right_prompt
    # Save the last status for later (do this before anything else)
    set -l last_status $status

	if test "$theme_complete_path" = "yes"
		set cwd (prompt_pwd)
	else
		set cwd (basename (prompt_pwd))

		if git::is_repo
			set root_folder (command git rev-parse --show-toplevel ^/dev/null)
			set parent_root_folder (dirname $root_folder)
			set cwd (echo $PWD | sed -e "s|$parent_root_folder/||")
		end
	end

    set -q fish_prompt_pwd_dir_length
    or set -l fish_prompt_pwd_dir_length 4

    if [ $fish_prompt_pwd_dir_length -gt 1 ]
        set cwd (string replace -ar '(^[^/]+|\.?[^/]{'"$fish_prompt_pwd_dir_length"'})[^/]*/' '$1/' "$cwd")
    end

    if [ $last_status -ne 0 ]
		printf (red)$last_status(yellow)" | "(off)
	end

	command -sq kubectl; and k8s::current_context >/dev/null 2>/dev/null; and begin
		set -l k8s_namespace (k8s::current_namespace)
		if test -z "$k8s_namespace"
			printf (dim)(k8s::current_context)(yellow)" | "(off)
		else
			printf (dim)(k8s::current_context)"/$k8s_namespace"(yellow)" | "(off)
		end
	end

	if terraform::workspace
		set terraform_workspace_name (command cat .terraform/environment)
		printf (dim)$terraform_workspace_name(yellow)" | "(off)
	end

	if git::is_repo
		set -l branch (git::branch_name ^/dev/null)
		set -l ref (git show-ref --head --abbrev | awk '{print substr($0,0,7)}' | sed -n 1p)

		if command git symbolic-ref HEAD > /dev/null ^/dev/null
			if git::is_staged
				printf (dim)"$branch"(off)
			else
				printf (dim)"$branch"(off)
			end
		else
			printf (dim)"$ref"(off)
		end

		printf (yellow)" | "(off)
	end

	printf (dim)$cwd(yellow)" | "(off)
	printf (dim)(date +%H:%M:%S)(off)

end
