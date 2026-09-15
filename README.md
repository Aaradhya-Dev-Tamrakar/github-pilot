# GitHub Pilot 🧭

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![Ecosystem Module #18](https://img.shields.io/badge/Ecosystem-Module_%2318-6366f1.svg)](https://github.com/Aaradhya-Dev-Tamrakar/brainstorm)
[![Token-Zero Core](https://img.shields.io/badge/Architecture-Token--Zero%20Core-emerald.svg)](AGENTS.md)

**GitHub Pilot** is an autonomous macro-plane profile orchestrator, fleet health auditor, and ecosystem navigator for developers managing multi-account GitHub presences and cross-repository fleets.

While **GitHub Copilot** operates *micro-plane* (inside files and editor buffers), **GitHub Pilot** operates *macro-plane* (across profiles, repositories, CI pipelines, and external developer signals).

---

## ⚡ The "Token-Zero" Philosophy

In modern AI-assisted engineering, conversational LLMs routinely burn tens of thousands of tokens fetching raw GitHub JSON, paginating lists, parsing HTML, and computing git diffs.

GitHub Pilot delegates all mechanical heavy-lifting to **deterministic local Python scripts**:
- **0 Tokens Burned**: Data fetching, caching, API aggregation, DOM scraping, and SVG generation execute locally in milliseconds.
- **Micro-Payload Handoff**: When AI agents (Antigravity, Claude, ChatGPT) request fleet status, GitHub Pilot emits compact, pre-digested summaries (`< 1 KB`), preserving context windows for high-level reasoning.

---

## 🛠️ Architecture

```
github-pilot/
├── pilot/
│   ├── cli.py               # Typer CLI application (audit, profile, digest, scrape, status)
│   ├── config.py            # Multi-account configuration & credentials resolver
│   ├── core/
│   │   ├── auditor.py       # Deterministic repository hygiene & CI health auditor
│   │   ├── profile.py       # Dynamic profile README & SVG stats synthesizer
│   │   └── digest.py        # Conventional commit changelog aggregator
│   └── scraper/
│       ├── engine.py        # Async HTTP/2 scraper engine (httpx + selectolax)
│       └── trending.py      # Zero-auth GitHub trending & topic radar parser
├── tests/                   # Pytest suite
├── sync.ps1                 # Ecosystem-compliant Git synchronization & secret scanner
└── AGENTS.md                # Agent operational protocol & evidence rules
```

---

## 🚀 Quick Start

### 1. Installation
```powershell
# Clone or navigate to the repository
cd F:\Aaradhya-Dev-Tamrakar\github-pilot

# Install dependencies
pip install -e .
# or
pip install -r requirements.txt
```

### 2. Configuration
Copy `.env.example` to `.env` and set your credentials:
```powershell
cp .env.example .env
```

| Variable | Description | Default |
| :--- | :--- | :--- |
| `GITHUB_PRIMARY_USER` | Primary GitHub handle | `Aaradhya-Dev-Tamrakar` |
| `GITHUB_PRIMARY_TOKEN`| Personal Access Token (PAT) with `repo`, `read:user` | (Optional for public endpoints) |
| `GITHUB_SECONDARY_USER` | Secondary GitHub handle | `AaradhyaDT` |
| `GITHUB_SECONDARY_TOKEN`| Secondary PAT | (Optional) |

---

## 💻 CLI Commands

### 1. Telemetry & Account Status
```powershell
pilot status
```
Displays active accounts, token validity, rate-limit status, and local cache health.

### 2. Fleet Health Audit
```powershell
pilot audit
```
Audits repositories across both accounts for missing licenses, broken CI runs, unpopulated descriptions, missing topics, and stale branches.

### 3. Profile README & SVG Synthesis
```powershell
pilot profile --output ./dist/README.md
```
Synthesizes dynamic SVG badges, language breakdowns, and commit velocity graphs into your GitHub profile README.

### 4. Cross-Repo Changelog Digest
```powershell
pilot digest --days 7
```
Scans git commits across your ecosystem branches, grouping them by conventional commit tags (`feat:`, `fix:`, `perf:`).

### 5. Zero-Auth Web Scraper (Trending Radar)
```powershell
pilot scrape trending --topic ai
```
Harvests trending repositories and rising topic tags without burning GitHub API quota.

---

## 🔒 Security & Git Workflow

This repository strictly enforces deterministic Git automation via **`sync.ps1`**:
- **Never run raw `git add/commit/push` directly.**
- Always run `.\sync.ps1` for automatic pre-commit secret scanning, scoped conventional commits, and safe rebase-pushing.

```powershell
.\sync.ps1 -WhatIf    # Preview changes & secret scan
.\sync.ps1 -Test      # Run tests and sync
.\sync.ps1            # Routine conventional sync
```

---

## 📄 License
MIT License. See [LICENSE](LICENSE) for details.
