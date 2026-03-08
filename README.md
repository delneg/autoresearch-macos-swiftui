# autoresearch-macos-swiftui

This fork adds a **native macOS SwiftUI dashboard app** (`AutoResearchApp/`) on top of the [autoresearch-macos](https://github.com/karpathy/autoresearch) project. The app lets you monitor experiments, view live training metrics, and start/stop training runs from a GUI — no terminal required.

## SwiftUI Dashboard App

### What it adds

A native macOS app with:
- **Live dashboard** — real-time training metrics (loss, tok/sec, MFU, progress) via Swift Charts
- **Experiment browser** — sortable table of all runs parsed from `results.tsv`
- **Control panel** — start/stop training and data preparation with one click
- **Log viewer** — scrolling real-time stdout output
- **Settings** — configure project directory and `uv` binary path

### Requirements

- **macOS 14+ (Sonoma)** on Apple Silicon
- **Xcode 16+** (or the Swift 5.10+ toolchain)
- **[uv](https://docs.astral.sh/uv/)** — Python package manager (`curl -LsSf https://astral.sh/uv/install.sh | sh`)
- **[XcodeGen](https://github.com/yonaskolb/XcodeGen)** (optional, only needed to regenerate the `.xcodeproj`) — `brew install xcodegen`

### Running the app

```bash
# Option A: Open in Xcode
open AutoResearchApp/AutoResearchApp.xcodeproj

# Option B: Build and run from the command line
cd AutoResearchApp
swift build && swift run
```

On first launch, click **Prepare Data** to download the dataset and build the tokenizer before starting training.

### Assumptions & defaults

- **Project directory** defaults to `~/autoresearch-macos`. If you cloned the repo elsewhere, update the path in the app's **Settings** (gear icon in the sidebar).
- **`uv` path** is auto-detected from common install locations (`~/.local/bin/uv`, `/opt/homebrew/bin/uv`, `/usr/local/bin/uv`, `~/.cargo/bin/uv`). If auto-detection fails, set the full path manually in Settings.
- The app runs **without App Sandbox** so it can spawn `uv` processes and watch files on disk.

### Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `The file "autoresearch-macos" doesn't exist` | Project directory path is wrong | Open Settings and point it to your cloned repo |
| `env: uv: No such file or directory` | `uv` not found (GUI apps don't inherit shell PATH) | Set the full `uv` path in Settings (e.g. `~/.local/bin/uv`) |
| `tokenizer.pkl not found` | Data not prepared yet | Click **Prepare Data** before starting training |

### Regenerating the Xcode project

If you add or remove source files:

```bash
cd AutoResearchApp
xcodegen generate
```

---

![teaser](progress.png)

*One day, frontier AI research used to be done by meat computers in between eating, sleeping, having other fun, and synchronizing once in a while using sound wave interconnect in the ritual of "group meeting". That era is long gone. Research is now entirely the domain of autonomous swarms of AI agents running across compute cluster megastructures in the skies. The agents claim that we are now in the 10,205th generation of the code base, in any case no one could tell if that's right or wrong as the "code" is now a self-modifying binary that has grown beyond human comprehension. This repo is the story of how it all began. -@karpathy, March 2026*.

The idea: give an AI agent a small but real LLM training setup and let it experiment autonomously overnight. It modifies the code, trains for 5 minutes, checks if the result improved, keeps or discards, and repeats. You wake up in the morning to a log of experiments and (hopefully) a better model. The training code here is a simplified single-GPU implementation of [nanochat](https://github.com/karpathy/nanochat). The core idea is that you're not touching any of the Python files like you normally would as a researcher. Instead, you are programming the `program.md` Markdown files that provide context to the AI agents and set up your autonomous research org. The default `program.md` in this repo is intentionally kept as a bare bones baseline, though it's obvious how one would iterate on it over time to find the "research org code" that achieves the fastest research progress, how you'd add more agents to the mix, etc. A bit more context on this project is here in this [tweet](https://x.com/karpathy/status/2029701092347630069).

## How it works

The repo is deliberately kept small and only really has a three files that matter:

- **`prepare.py`** — fixed constants, one-time data prep (downloads training data, trains a BPE tokenizer), and runtime utilities (dataloader, evaluation). Not modified.
- **`train.py`** — the single file the agent edits. Contains the full GPT model, optimizer (Muon + AdamW), and training loop. Everything is fair game: architecture, hyperparameters, optimizer, batch size, etc. **This file is edited and iterated on by the agent**.
- **`program.md`** — baseline instructions for one agent. Point your agent here and let it go. **This file is edited and iterated on by the human**.

By design, training runs for a **fixed 5-minute time budget** (wall clock, excluding startup/compilation), regardless of the details of your compute. The metric is **val_bpb** (validation bits per byte) — lower is better, and vocab-size-independent so architectural changes are fairly compared.

## Quick start

**Requirements:** Apple Silicon Mac (M1/M2/M3/M4 with Metal/MPS support) or a single NVIDIA GPU, Python 3.10+, [uv](https://docs.astral.sh/uv/).

```bash

# 1. Install uv project manager (if you don't already have it)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. Install dependencies
uv sync

# 3. Download data and train tokenizer (one-time, ~2 min)
uv run prepare.py

# 4. Manually run a single training experiment (~5 min)
uv run train.py
```

If the above commands all work ok, your setup is working and you can go into autonomous research mode.

**Platforms support**. This fork officially supports **macOS (Apple Silicon / MPS)** and CPU environments, while preserving the original NVIDIA GPU support. It removes the hardcoded dependency on FlashAttention-3, falling back to PyTorch's native Scaled Dot Product Attention (SDPA) with manual sliding window causal masking when needed. It also features MPS-specific optimizations (disabling unsupported `torch.compile` paths, lowering memory batch sizes for Metal bounds, and precisely casting optimizer states) allowing you to run autonomous research agents directly on your Mac!

## Running the agent

Simply spin up your Claude/Codex or whatever you want in this repo (and disable all permissions), then you can prompt something like:

```
Hi have a look at program.md and let's kick off a new experiment! let's do the setup first.
```

The `program.md` file is essentially a super lightweight "skill".

## Project structure

```
prepare.py      — constants, data prep + runtime utilities (do not modify)
train.py        — model, optimizer, training loop (agent modifies this)
program.md      — agent instructions
pyproject.toml  — dependencies
```

## Design choices

- **Single file to modify.** The agent only touches `train.py`. This keeps the scope manageable and diffs reviewable.
- **Fixed time budget.** Training always runs for exactly 5 minutes, regardless of your specific platform. This means you can expect approx 12 experiments/hour and approx 100 experiments while you sleep. There are two upsides of this design decision. First, this makes experiments directly comparable regardless of what the agent changes (model size, batch size, architecture, etc). Second, this means that autoresearch will find the most optimal model for your platform in that time budget. The downside is that your runs (and results) become not comparable to other people running on other compute platforms.
- **Self-contained.** No external dependencies beyond PyTorch and a few small packages. No distributed training, no complex configs. One GPU, one file, one metric.

## License

MIT
