# simonvizzini's dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Replicates my Linux setup on
new machines with one `chezmoi init --apply` (after a small one-time bootstrap
for the age key).

## What's in here

| Path | What it is |
| --- | --- |
| `dot_zshrc`, `dot_zpreztorc`, `dot_zprofile` | Zsh + customized prezto runcoms |
| `dot_p10k.zsh` | Powerlevel10k prompt |
| `dot_gitconfig`, `dot_ansible.cfg` | Git + Ansible |
| `private_dot_config/nvim/` | AstroNvim setup (lazy.nvim auto-bootstraps) |
| `private_dot_config/kitty/` | Kitty terminal config |
| `private_dot_config/lazygit/`, `bat/` | TUI tools |
| `private_dot_config/gh/config.yml` | GitHub CLI config (hosts.yml ignored — token) |
| `private_dot_ssh/config.tmpl` | SSH host aliases, work hosts gated by template var |
| `encrypted_private_dot_config/rclone/rclone.conf.age` | Hetzner remote, age-encrypted |
| `run_once_before_install-system-packages.sh.tmpl` | `pacman -S` deps on Arch |
| `run_once_before_install-prezto.sh.tmpl` | Clones prezto + symlinks runcoms |
| `run_once_after_enable-cronie.sh.tmpl` | Enables `cronie.service` |
| `run_onchange_after_install-crontab.sh.tmpl` | Installs user crontab (rclone bisync) |
| `chezmoi.toml.tmpl` | Sample per-machine config — NOT applied, copy manually |

Explicitly **not** managed: KDE Plasma layout, SSH keys (KeePassXC handles
those), `~/.npmrc`/`~/.yarnrc`, `~/.claude/`/`~/.codex/` configs,
`lazy-lock.json`.

## First-time setup on a new Linux machine

The flow has one manual step (copying the age key) wrapping the `chezmoi`
command. Do it in this order or `chezmoi apply` will fail to decrypt secrets.

### 1. Install chezmoi and age

```bash
# Arch / Manjaro / CachyOS
sudo pacman -S --needed chezmoi age git

# Debian / Ubuntu
sh -c "$(curl -fsLS get.chezmoi.io)"   # chezmoi
sudo apt install age git
```

### 2. Restore the age private key

The age **private key** lives at `~/.config/chezmoi/key.txt` and is **not**
in this repo. On the master machine the key was generated with:

```bash
mkdir -p ~/.config/chezmoi
age-keygen -o ~/.config/chezmoi/key.txt
# The PUBLIC key is printed; it's also in chezmoi.toml.tmpl (committed).
```

I keep the private key as a KeePassXC attachment on a "chezmoi age key"
entry. On a fresh machine: unlock the KeePassXC database, export the
attachment to `~/.config/chezmoi/key.txt`, then `chmod 600` it.

### 3. Create the per-machine chezmoi config

Copy `chezmoi.toml.tmpl` from this repo to `~/.config/chezmoi/chezmoi.toml`,
edit the placeholders:

```toml
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1...the-public-key-from-the-master-machine..."

[data]
    work_machine = false              # true on machines that need work SSH hosts
    keepass_dir = "/home/simon/keepass"
    rclone_remote = "Hetzner:keepass"
```

### 4. Apply

```bash
chezmoi init --apply git@github.com:simonvizzini/dotfiles.git
```

This runs in order:
1. `run_once_before_install-system-packages.sh` — installs pacman deps
2. `run_once_before_install-prezto.sh` — clones prezto, symlinks unmodified runcoms
3. All managed files written to `~` (decrypts `rclone.conf.age` along the way)
4. `run_once_after_enable-cronie.sh` — enables the cron daemon
5. `run_onchange_after_install-crontab.sh` — installs the user crontab

If anything fails partway, the script tells you what — fix and re-run.

### 5. Post-apply manual steps

These can't be automated cleanly per machine:

- **Set zsh as your login shell**: `chsh -s "$(command -v zsh)"`, then log out/in.
- **SSH keys**: see "SSH keys via KeePassXC" below.
- **Nerd Font**: install one your p10k/kitty config references (e.g.
  `ttf-meslo-nerd` on Arch). Re-run `p10k configure` if the prompt looks wrong.
- **First nvim launch**: opens, bootstraps lazy.nvim, installs all AstroNvim
  plugins. Quit and reopen once that finishes.
- **KeePassXC**: unlock the database to start the rclone sync; SSH keys
  populate the agent on unlock too.

## Daily workflow

```bash
chezmoi edit ~/.zshrc           # opens the SOURCE file in $EDITOR
chezmoi diff                    # what would change in ~ on next apply
chezmoi apply -v                # write source → ~
chezmoi add ~/.newfile          # stage a new dotfile into the repo
chezmoi re-add                  # re-stage everything chezmoi already tracks (after editing in ~ directly)
chezmoi cd                      # cd into the source repo (git commands work here)
chezmoi managed                 # list every path chezmoi manages
chezmoi verify                  # exit 0 if source matches destination
```

Typical "I edited a config in `~` and want it in the repo":

```bash
chezmoi re-add                  # restages
chezmoi cd
git diff                        # review
git commit -am "tweak X"
git push
exit                            # leaves the chezmoi cd shell
```

Typical "I want to add a brand-new file":

```bash
chezmoi add ~/.config/something/config.yml
chezmoi cd && git add -A && git commit -m "add something config" && git push && exit
```

## Adding new dotfiles

`chezmoi add` infers the source filename from the destination. Prefixes:

| Prefix | Effect on apply |
| --- | --- |
| `dot_X` | → `~/.X` |
| `private_X` | mode 0600 (file) / 0700 (dir) |
| `executable_X` | mode 0755 |
| `encrypted_X` | decrypted on apply using configured encryption |
| `X.tmpl` | rendered as Go text/template before apply |
| `run_once_<name>.sh` | executed once per content-hash |
| `run_onchange_<name>.sh` | re-runs when the rendered content changes |
| `_before_` / `_after_` | runs before / after file apply step |

Combine freely: `encrypted_private_dot_config/rclone/rclone.conf.age` →
`~/.config/rclone/rclone.conf` (0600, decrypted from age).

To stage an encrypted secret:

```bash
chezmoi add --encrypt ~/.config/some/secret.toml
# Source file is written as encrypted_*.age and decrypted on apply.
```

To template a file based on machine-specific data, rename to `*.tmpl` and
reference `~/.config/chezmoi/chezmoi.toml` `[data]` keys:

```
{{ if .work_machine -}}
...work-only content...
{{- end }}
```

## Per-machine configuration

`~/.config/chezmoi/chezmoi.toml` (gitignored, per-machine):

```toml
encryption = "age"

[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1..."

[data]
    work_machine = true | false
    keepass_dir = "/home/simon/keepass"
    rclone_remote = "Hetzner:keepass"
```

Built-in template vars also available (no config needed):
`.chezmoi.hostname`, `.chezmoi.fqdnHostname`, `.chezmoi.os`,
`.chezmoi.osRelease.id`, `.chezmoi.arch`, `.chezmoi.username`.
See the [chezmoi reference](https://www.chezmoi.io/reference/templates/variables/).

## Prezto: why two runcoms are tracked, not the rest

The local prezto clone at `~/.zprezto/` has edits in `runcoms/zpreztorc`
(9 lines) and `runcoms/zprofile` (1 line) only — no module edits. Chezmoi
manages `~/.zpreztorc` and `~/.zprofile` as real files (overwriting the
symlinks prezto would otherwise create). The other runcoms
(`.zshenv`, `.zlogin`, `.zlogout`) are symlinked back to upstream-pristine
files by `run_once_before_install-prezto.sh`.

If I ever start editing prezto modules, the right move is to fork prezto
(`simonvizzini/prezto`), push the changes, and update the bootstrap script
to clone from the fork. Currently overkill.

## SSH keys via KeePassXC (NOT in chezmoi)

SSH private keys are NEVER in this repo. They ride in the KeePassXC database
and are loaded into `ssh-agent` automatically when the database is unlocked.

Setup on a new machine:

1. **Enable SSH agent integration in KeePassXC**:
   `Tools → Settings → SSH Agent` → tick *Enable SSH Agent integration*.
   Restart KeePassXC.
2. **Make sure ssh-agent is running**:
   ```bash
   systemctl --user status ssh-agent
   # if not running:
   systemctl --user enable --now ssh-agent.service
   ```
   Prezto's `ssh` module sets `SSH_AUTH_SOCK` correctly when started. If not,
   add to `.zshenv`:
   ```sh
   export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
   ```
3. **Per SSH key, create a KeePassXC entry**:
   - *Advanced* tab → *Attachments* → add the private key file (and the
     public key if you want it bundled). If the key has a passphrase, put
     the passphrase in the entry's `Password` field — KeePassXC uses it
     when loading the key.
   - *SSH Agent* tab → tick *Add key to agent when database is opened/unlocked*
     and *Remove key from agent when database is closed/locked*. Select the
     attachment under *Private key*.
4. **Verify**:
   ```bash
   ssh-add -l       # keys listed once database is unlocked
   ssh -T git@github.com
   ```

The KeePassXC database itself is synced to Hetzner via the rclone bisync
crontab entry managed by this repo. That's the whole loop: keys live in
KeePassXC, KeePassXC syncs via rclone, rclone is configured via this repo
(encrypted), the cron entry that drives the sync is also from this repo.

## Things deliberately NOT managed

- **KDE Plasma layout** (`plasma-org.kde.plasma.desktop-appletsrc` etc.) —
  too many machine-specific UUIDs (activity IDs, screen IDs,
  resolution-keyed geometry). Set up per machine.
- **SSH private keys** — KeePassXC handles those (see above).
- **`~/.claude/`, `~/.codex/`, `~/.agents/`** — skills are installed via
  `npx` commands that create symlinks; safer to redo per machine.
- **`~/.npmrc`, `~/.yarnrc`** — usually have auth tokens.
- **`lazy-lock.json`** — each machine gets latest plugins on first nvim launch.
- Caches, browser data, credential dirs (`~/.aws/`, `~/.docker/`, `~/.gnupg/`).

## Troubleshooting

**`chezmoi apply` fails with "age: no identity matched recipient"** —
`~/.config/chezmoi/key.txt` is missing or doesn't match the public key in
`chezmoi.toml`. Restore the private key from KeePassXC.

**`chezmoi diff` shows changes I never made** — `chezmoi re-add` to stage
the current state of `~` into the source repo, then review with `git diff`.

**Force a `run_once_` script to run again** —
`chezmoi state delete-bucket --bucket=scriptState`, then `chezmoi apply`.

**Prezto's symlinks weren't created** — re-run
`chezmoi state delete-bucket --bucket=scriptState && chezmoi apply` to
re-trigger the prezto bootstrap.

**Crontab not installing** — `cronie` not installed or not enabled. Run
`sudo pacman -S cronie && sudo systemctl enable --now cronie.service`,
then `chezmoi apply` again.

**The repo got out of sync between machines** — `chezmoi cd && git pull`
inside the source repo, then `chezmoi apply -v` in `~`.
