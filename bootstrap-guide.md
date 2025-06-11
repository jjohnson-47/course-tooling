# Bootstrap Guide (one-time)

Follow these steps **once** on a fresh machine or VM to initialise the Course Deployment System inside the Agentic Development Environment.

---

## 0. Prerequisites

* macOS 14 or Fedora 40+
* Git ≥ 2.40, GitHub CLI (`brew install gh` or `dnf install gh`)
* Python 3.12 (for future agents)
* A fine-grained PAT (`contents:read`, `actions:read`) stored in Keychain:
  ```bash
  security add-generic-password -a "$USER" -s cds_pat -w "ghp_xxx..."
  ```

---

## 1. Create root directories

```bash
export AGENTIC_ENV_ROOT=$HOME/Agentic/env
export AGENTIC_STATE_ROOT=$HOME/Agentic/state
mkdir -p "$AGENTIC_ENV_ROOT" "$AGENTIC_STATE_ROOT"
```

Add the two exports to your shell profile.

---

## 2. Clone the hub and link directories

```bash
cd "$AGENTIC_ENV_ROOT"
git clone git@github-work:<org>/course-tooling.git
mkdir -p courses
ln -s "$PWD/course-tooling" courses/course-tooling
```

---

## 3. Set CDS environment variables

```bash
export CDS_ENV_ROOT="$AGENTIC_ENV_ROOT/courses"
export CDS_STATE_ROOT="$AGENTIC_STATE_ROOT/cds"
mkdir -p "$CDS_STATE_ROOT"/{ingestion-cache,deployment-logs}
```

---

## 4. Install validation script

```bash
cd course-tooling/scripts
chmod +x validate-architecture.sh
./validate-architecture.sh   # should exit 0
```

(If it fails, fix paths/secrets before proceeding.)

---

## 5. Provision the cds_agent stub

```bash
mkdir -p "$AGENTIC_ENV_ROOT/agents"
cat > "$AGENTIC_ENV_ROOT/agents/cds_agent.py" <<"PY"
#!/usr/bin/env python3
# minimal placeholder – prints heartbeat and exits
print("cds_agent stub installed; replace with full implementation.")
PY
chmod +x "$AGENTIC_ENV_ROOT/agents/cds_agent.py"
```

Create a LaunchAgent plist:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>            <string>com.agentic.cds</string>
  <key>ProgramArguments</key> <array><string>$AGENTIC_ENV_ROOT/agents/cds_agent.py</string></array>
  <key>RunAtLoad</key>        <true/>
  <key>KeepAlive</key>        <true/>
  <key>StandardErrorPath</key><string>$AGENTIC_STATE_ROOT/logs/cds_agent.err</string>
  <key>StandardOutPath</key>  <string>$AGENTIC_STATE_ROOT/logs/cds_agent.out</string>
</dict>
</plist>
```

Place it in `~/Library/LaunchAgents/com.agentic.cds.plist` and run:

```bash
launchctl load -w ~/Library/LaunchAgents/com.agentic.cds.plist
```

---

## 6. Create a pilot course repo pair

```bash
cd "$CDS_ENV_ROOT"
gh repo create demo-src  --private --clone
gh repo create demo-site --public
echo "# Demo course" > demo-src/README.md
cp course-tooling/samples/deploy.yml demo-src/.github/workflows/
cd demo-src && git add . && git commit -m "initial" && git push
```

Verify on GitHub that the **Publish course site** workflow runs and an artifact named `mcp-deployment-log-…` appears.

---

## 7. Run compliance check

```bash
$AGENTIC_ENV_ROOT/course-tooling/scripts/validate-architecture.sh
# Expect: no violations
```

Success means the skeleton is correct; fill in real agents and course content at your pace.

---

## You now have

* Baseline constitution in place
* Directory wall enforced
* Hub cloned and ready
* cds_agent plumbing stubbed

Continue by implementing cds_agent logic, writing lessons, and tagging `course-tooling` as `baseline-v1`.
