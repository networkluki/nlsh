# nlsh

Professional shell scripts for setup, maintenance, and upgrades on Debian/Ubuntu-based systems.

## Purpose
`nlsh` is a practical script collection for common system tasks:
- Installing production APT repository configuration
- Running safe and repeatable upgrade flows
- Keeping shell-based operations simple and auditable

## Repository Structure
- `apt-prod-v1.sh` — Installs/configures APT production repository settings.
- `upg-v1.sh` — Handles upgrade workflow with options and APT integration.
- `nvm/` — NVM-related helper content.

## Quick Start
> Always review a script before running it with sudo/root.

```bash
git clone https://github.com/networkluki/nlsh.git
cd nlsh
chmod +x *.sh
```

Run a script:

```bash
./apt-prod-v1.sh
# or
./upg-v1.sh
```

## Recommended Quality Checks
Syntax checks:

```bash
bash -n apt-prod-v1.sh
bash -n upg-v1.sh
```

Linting (if ShellCheck is installed):

```bash
shellcheck apt-prod-v1.sh upg-v1.sh
```

## Design Principles
- **Safe defaults**: avoid destructive behavior without clear intent.
- **Idempotency**: scripts should be safe to rerun when possible.
- **Readable output**: clear messages for each major step.
- **Minimal dependencies**: works with standard system tools.

## Contributing
1. Open an issue describing your change.
2. Keep changes focused and small.
3. Validate with `bash -n` and `shellcheck` before PR.

## License
Add your preferred license file (for example MIT) to make usage terms explicit.
