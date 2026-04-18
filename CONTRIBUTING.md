# Contributing to Tycoon

This is our team SOP. It exists so we don't step on each other's toes, so our Git history stays readable, and so future-us doesn't hate present-us.

If something here stops making sense as the project grows, we update this doc. It's a living agreement, not a monument.

## The golden rules

1. **Never commit directly to `main`.** All work happens on branches and lands through pull requests.
2. **One branch per unit of work.** A unit is something you can describe in a single sentence.
3. **Pull before you start, push when you pause.** Keeps everyone's local copy close to reality.
4. **Small commits, small PRs.** Easier to review, easier to revert, easier to understand later.
5. **Review each other's PRs before merging.** Even a 30-second skim catches half the bugs.

## Branch naming

Use a prefix that describes the type of work:

- `feat/` — new functionality (`feat/card-dealing`, `feat/ai-opponent-easy`)
- `fix/` — bug fixes (`fix/revolution-not-resetting`)
- `refactor/` — code cleanup with no behavior change (`refactor/extract-game-state`)
- `chore/` — tooling, config, dependencies (`chore/update-gitignore`)
- `docs/` — documentation only (`docs/add-rules-spec`)

Keep names short, lowercase, hyphen-separated. Not `feat/Im-adding-the-card-dealing-logic-for-4-players`.

## Commit messages

We use [Conventional Commits](https://www.conventionalcommits.org/). Format:

```
<type>: <short summary in present tense, lowercase, no period>

<optional longer explanation, wrapped at ~72 chars>
```

Types match the branch prefixes: `feat`, `fix`, `refactor`, `chore`, `docs`, plus `test` for test-only changes and `style` for formatting-only changes.

Good:
```
feat: add Card and Rank models
fix: beggar now gives highest cards, not lowest
refactor: extract trick state into its own type
```

Not good:
```
updates
WIP
fixed the thing
asdf
```

The "why" matters more than the "what" in the longer explanation — the diff already shows what changed. If the change is non-obvious, say why you made it.

## The daily loop

```bash
# Start of a new piece of work
git switch main
git pull
git switch -c feat/your-thing

# Work, committing as you hit "this works" moments
git add .
git commit -m "feat: your message"

# When ready to share
git push -u origin feat/your-thing
# Open a PR on GitHub, request review

# After approval, merge via GitHub UI (Squash and merge)
# Delete the branch (GitHub offers a button)

# Back on your machine, sync up
git switch main
git pull
```

## Pull requests

**When you open a PR:**
- Title follows the commit message format (`feat: add card dealing logic`)
- Description explains the *why* and anything non-obvious
- If it's UI work, include a screenshot or screen recording
- Link any related issue (`Closes #12`)
- Request review from the other person
- Keep it under ~400 lines of diff when you can. If it's bigger, consider splitting.

**When you review a PR:**
- Actually read the diff, don't rubber-stamp
- Ask questions in comments if something is unclear — no assumption is too basic
- Use GitHub's "Request changes" if something needs fixing, "Approve" if it's good
- "Nit:" prefix for stylistic suggestions that aren't blockers

**Merging:**
- Use **Squash and merge**. This collapses your branch's commits into a single clean commit on `main`, so `main`'s history stays readable.
- The PR author does the merge (so they can fix issues right up to the click).
- Delete the branch after merge.

## Dividing work

Early on, we split by layer to minimize conflicts:

- **Game engine** (`Packages/TycoonDaifugouKit/` or equivalent) — models, rules, trick resolution, AI. Pure Swift, testable without the simulator.
- **UI** (`App/`) — SwiftUI views, navigation, assets, animations.

We meet at the view model / binding layer. When we're both going to touch that area, we talk first — either in person, a quick message, or a GitHub issue — and decide who owns what so we're not writing the same code twice.

## Merge conflicts

They happen. They're not a disaster.

1. If your PR has a conflict with `main`, **you** resolve it. You have the context for your changes.
2. Update your branch: `git switch main && git pull && git switch your-branch && git merge main`
3. Git will mark conflicting regions with `<<<<<<<`, `=======`, `>>>>>>>`. Open the files, pick what's right, delete the markers.
4. `git add` the resolved files, `git commit`, `git push`.

If it's genuinely hairy, call it out in the PR and we figure it out together.

## What never goes in the repo

- **Secrets**: API keys, passwords, tokens, `.env` files. Once in Git history, they're hard to remove. Put them in `.gitignore` *before* the first commit that would include them.
- **Build artifacts**: `DerivedData/`, `build/`, `.xcuserstate`, `*.xcuserdata/`. The `.gitignore` handles these.
- **Personal Xcode state**: Your breakpoints, window layouts, scheme selections. Not useful to anyone else.
- **Large binaries**: Assets over a few MB — we'll figure out Git LFS if we need it. Don't just commit a 200MB video.

## Things that will bite us if we're not careful

- **Don't rebase branches after pushing them.** Rebasing rewrites history; if the other person has pulled the branch, their copy will diverge in confusing ways. Rule: rebase *before* pushing, merge *after*.
- **`git push --force` is dangerous.** Never on `main`. On your own feature branches, use `git push --force-with-lease` instead — it refuses to clobber commits you haven't seen.
- **Don't `git pull` on top of uncommitted changes.** Commit or stash first.
- **Don't commit generated files.** If Xcode made it, it probably shouldn't be in the repo.

## Useful commands cheat sheet

```bash
# Status & inspection
git status                           # what's changed right now
git diff                             # show unstaged changes
git log --oneline                    # compact history
git log --oneline --graph --all      # history with branch visualization

# Staging & committing
git add .                            # stage everything
git add path/to/file                 # stage one file
git commit -m "feat: message"        # commit staged changes
git commit --amend                   # edit last commit (only before push!)

# Branches
git switch main                      # switch to main
git switch -c feat/name           # create and switch to new branch
git branch -d feat/name           # delete a merged local branch
git branch                           # list local branches

# Syncing
git fetch                            # check what's new on remote (safe)
git pull                             # fetch + merge into current branch
git push                             # push current branch
git push -u origin branch-name       # first push of a new branch

# Oh-no moments
git stash                            # shelve uncommitted changes
git stash pop                        # get them back
git restore path/to/file             # discard unstaged changes to a file
git restore --staged path/to/file    # unstage, keep the changes
git reset --soft HEAD~1              # undo last commit, keep changes staged
git reflog                           # history of where HEAD has been (recovery lifeline)
```

## When in doubt

Ask. A 30-second message to the other person is always cheaper than an hour untangling a merge. This doc is the default; deviation is fine if we both agree.
