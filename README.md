# Dotfiles — EC2 terminal → WSL (or any Ubuntu box)

Portable recreation of the Magnet / personal shell stack that lived on the EC2:
Powerlevel10k, Oh My Zsh, Antigen, Oh my tmux, pyenv + virtualenvwrapper `WorkEnv`,
nvm, bun, dotnet, zvm, aws/kubectl/helm, Git Credential Manager, and the review/AWS helpers.

## Quick start (new WSL Ubuntu)

```bash
# 1. Clone this repo
git clone <your-dotfiles-remote> ~/dotfiles
cd ~/dotfiles

# 2. Install everything
./bootstrap.sh

# 3. On the EC2 (before it dies), export secrets + WorkEnv freeze
./bin/export-secrets.sh
# scp secrets/ec2-secrets-*.tgz to the Windows/WSL machine

# 4. On WSL, import
./bin/import-secrets.sh ~/ec2-secrets-XXXX.tgz
./bootstrap.sh python   # reinstall full pip freeze if present

# 5. Clone work repos into ~/work, then re-link review extensions
./link.sh
```

Partial installs:

```bash
./bootstrap.sh apt shell python
./bootstrap.sh --skip-cloud
```

## Layout

```
bootstrap.sh          # orchestrator
link.sh               # symlink configs into $HOME
install/              # one script per toolchain
zsh/zshrc             # entrypoint
zsh/zshrc.d/          # modular fragments (aliases, AWS, python, …)
zsh/p10k.zsh          # your rainbow p10k
tmux/tmux.conf.local  # Oh my tmux local config
git/gitconfig
python/requirements-workenv.txt
bin/export-secrets.sh
bin/import-secrets.sh
bin/export-workenv.sh
```

## Python / “pyenv stuff”

On the EC2 you were actually on **virtualenvwrapper** (`workon WorkEnv`), not a bare pyenv shell.
Bootstrap installs **both**:

1. **pyenv** — pins a real Python (default `3.12.8`, override with `DOTFILES_PYTHON_VERSION`)
2. **virtualenvwrapper** — recreates `WorkEnv` and installs `thefuck` + requirements
3. Optional full freeze via `bin/export-workenv.sh` or the secrets export

## Local toggles (`~/.zshrc.local`)

Noisy EC2 behaviours are **off by default**:

| Variable | Effect |
|----------|--------|
| `DOTFILES_VERBOSE=1` | Colourful startup banners |
| `DOTFILES_START_MYSQL=1` | `docker start/run mysql` on shell open |
| `DOTFILES_SHOW_CLUSTER_STATUS=1` | `kubectl` / `docker ps` splash |
| `DOTFILES_TUNE_INOTIFY=1` | `sudo sysctl` inotify limits every open |
| `DOTFILES_AUTO_WORKON=0` | Don’t auto `workon WorkEnv` |

## Docker on WSL

Do **not** install `docker-ce` inside WSL the way the EC2 did unless you have a reason.
Use **Docker Desktop for Windows** → Settings → Resources → WSL Integration → enable this distro.
Then `docker` / `docker compose` just work from zsh.

## Fonts

Powerlevel10k needs a Nerd Font on the **Windows** side (e.g. MesloLGS NF).
Install the font in Windows, then set it in Windows Terminal and Cursor.

## Secrets

`secrets/` is gitignored aside from `.gitkeep`. Never commit the tarball.
Prefer `GPG_RECIPIENT=you@example.com ./bin/export-secrets.sh`.

## Non-git work extras

`./bin/export-secrets.sh` also builds `work-extras-*.tgz` from `repos/work-extras.txt`.

**Keep (in the tarball):** planning notes, swagger-docs, interview pad, virtualized-dictionary-list,
git summaries, helper scripts, `.cursorrules`, Nubis zip.

**Leave behind (too big / reclonable):** `investigations` (~6G), `test_cases` (~31G),
`WorkEnv`, `bgfx-test`, duplicate `magnet-review-*` checkouts.

**Secrets that lived under work/scripts** (`myPatTokens.json`, `cookie.txt`) go in the
*secrets* archive, not the extras one.

```bash
./bin/export-secrets.sh          # secrets + work-extras
# scp both tarballs

# WSL:
./bin/import-secrets.sh ~/ec2-secrets-XXXX.tgz
./bin/import-work-extras.sh ~/work-extras-XXXX.tgz
```


**Bootstrap alone does not clone repos.** Credentials + a manifest do.

On this EC2 we scanned your trees into `repos/repos.tsv` (28 remotes):
Magnet Azure DevOps, personal GitHub (`personal-github` SSH host), plus optional vendored github deps.

```bash
# Refresh the list from this machine anytime
./bin/export-repos.sh

# On WSL, after secrets + GCM:
ssh-add ~/.ssh/ters_tech
ssh -T git@personal-github                                          # personal
git ls-remote https://dev.azure.com/gauss-dev/Magnet/_git/magnet-review  # Magnet (GCM login once)

./bin/clone-repos.sh            # magnet + personal
./bin/clone-repos.sh --all      # also bgfx-test vendored clones
./bin/clone-repos.sh --group magnet
```

### Will credentials “just work”?

| Host | Mechanism | What you must do once on WSL |
|------|-----------|------------------------------|
| Azure DevOps (`dev.azure.com/gauss-dev/...`) | HTTPS + Git Credential Manager | Import secrets / install GCM, complete browser/device login on first clone |
| Personal GitHub | SSH `Host personal-github` → `ters_tech` key | Import `~/.ssh` (includes config), `ssh-add ~/.ssh/ters_tech` |
| Public GitHub vendored | HTTPS anonymous | Nothing |

It will **not** silently reuse EC2 credential caches unless you imported them. Azure especially wants a fresh GCM login on a new machine.

Feature branches (`RE-*`, etc.) are **not** what we pin in the manifest — clones land on stable defaults (`fury` / `main` / `build/saas`). Your dirty worktrees and WIP branches are still on the EC2 until you push or copy them.

## Migrating off this EC2 checklist

- [ ] `git init` / push this repo to your remote
- [ ] `./bin/export-secrets.sh` (and copy the archive off-box)
- [ ] `./bin/export-repos.sh` (already done; re-run if you add clones)
- [ ] `./bin/export-workenv.sh` if you want the freeze in-repo (optional)
- [ ] Bootstrap on WSL
- [ ] Import secrets; prove SSH + ADO auth
- [ ] `./bin/clone-repos.sh` then `./link.sh`
- [ ] `awssso` once and confirm ECR + kube
- [ ] Kill the EC2 when you’re sure
