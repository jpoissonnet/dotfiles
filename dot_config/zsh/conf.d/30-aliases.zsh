alias b='bun'
alias p="pnpm"
alias oc='opencode'
alias cat='bat'
alias gbse='git-blame-someone-else'
alias galrbc="git add pnpm-lock.yaml && GIT_EDITOR=true git rebase --continue"
alias partial-clone='git clone --no-checkout --depth=1 --filter=tree:0'
alias prreviews='{ echo -e "PR\tTitle\tReviews\tApprovals"; gh pr list --search "review-requested:@me" --json number,title,author,reviews --jq ".[] | [.number, .title, (.reviews | length), (.reviews | map(select(.state == \"APPROVED\")) | length)] | @tsv"; } | column -t -s $'"'"'\t'"'"''
