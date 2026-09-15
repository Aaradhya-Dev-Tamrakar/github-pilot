from typing import Dict, Any, List
from pathlib import Path
from pilot.core.auditor import FleetAuditSummary

class ProfileSynthesizer:
    def __init__(self, config=None):
        self.config = config

    def generate_svg_radar(self, stats: Dict[str, int]) -> str:
        """Generates a sleek, minimal SVG radar / metric badge."""
        total = sum(stats.values()) or 1
        return f"""<svg width="400" height="120" viewBox="0 0 400 120" xmlns="http://www.w3.org/2000/svg">
  <rect width="100%" height="100%" rx="12" fill="#0f172a"/>
  <text x="20" y="30" fill="#38bdf8" font-family="system-ui, sans-serif" font-weight="bold" font-size="14">ECOSYSTEM TELEMETRY</text>
  <text x="20" y="60" fill="#94a3b8" font-family="system-ui, sans-serif" font-size="12">Active Repos: {stats.get('repos', 0)} | Stars: {stats.get('stars', 0)}</text>
  <text x="20" y="85" fill="#94a3b8" font-family="system-ui, sans-serif" font-size="12">Fleet Health Score: {stats.get('health_score', 0)}%</text>
  <circle cx="350" cy="60" r="30" stroke="#38bdf8" stroke-width="4" fill="none"/>
  <text x="350" y="65" text-anchor="middle" fill="#38bdf8" font-family="system-ui, sans-serif" font-weight="bold" font-size="13">{stats.get('health_score', 0)}%</text>
</svg>"""

    def render_profile_readme(self, summary: FleetAuditSummary) -> str:
        top_repos = sorted(summary.repos, key=lambda r: r.stars, reverse=True)[:5]
        
        repo_rows = []
        for r in top_repos:
            lang_badge = f"`{r.language}`" if r.language else "`N/A`"
            desc = r.description or "No description provided"
            repo_rows.append(f"| **[{r.name}](https://github.com/{r.owner}/{r.name})** | {lang_badge} | ⭐ {r.stars} | {desc} |")
        
        table_content = "\n".join(repo_rows) if repo_rows else "| No repositories indexed | - | - | - |"

        return f"""# Aaradhya Dev Tamrakar 🪐
Architectural AI, Computational R&D & Systems Engineering

[![GitHub Pilot](https://img.shields.io/badge/Orchestrated%20by-GitHub%20Pilot-6366f1.svg)](https://github.com/Aaradhya-Dev-Tamrakar/github-pilot)
[![Fleet Health](https://img.shields.io/badge/Fleet%20Health-{summary.average_health_score}%25-emerald.svg)](#)
[![Total Ecosystem Repos](https://img.shields.io/badge/Fleet%20Repos-{summary.total_repos_scanned}-blue.svg)](#)

---

### ⚡ Fleet Radar & Live Topography

```
Total Repositories Managed : {summary.total_repos_scanned}
Total Community Stars      : ⭐ {summary.total_stars}
Average Fleet Health Score : {summary.average_health_score}%
```

### 🛠️ Featured Tool Ecosystem

| Repository | Tech Stack | Stars | Focus & Superpower |
| :--- | :--- | :--- | :--- |
{table_content}

---
*Auto-synthesized deterministically via [GitHub Pilot](https://github.com/Aaradhya-Dev-Tamrakar/github-pilot) (Token-Zero Core).*
"""
