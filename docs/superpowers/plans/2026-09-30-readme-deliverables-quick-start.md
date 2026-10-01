# README Deliverables and Quick Start Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the project immediately runnable from the README and separate the AI-narrated demo from the future Zhekai Li recording.

**Architecture:** Keep the existing application and documentation structure. Move all generated-demo assets into one named directory, add a tracked placeholder directory for Zhekai Li's future recording, and update entry points and documentation so every path remains valid.

**Tech Stack:** Markdown, Bash, Git, MP4/text assets

---

### Task 1: Organize demo deliverables

**Files:**
- Move: `demo/demo.mp4` → `demo/ai-generated-narration/demo.mp4`
- Move: `demo/narration.txt` → `demo/ai-generated-narration/narration.txt`
- Move: `demo/run_demo.sh` → `demo/ai-generated-narration/run_demo.sh`
- Create: `demo/zhekai-li-recording/.gitkeep`

- [x] **Step 1: Create the two deliverable directories**

Create `demo/ai-generated-narration/` and `demo/zhekai-li-recording/`.

- [x] **Step 2: Move the generated narration assets**

Move the MP4, narration script, and demo runner into `demo/ai-generated-narration/` without changing the binary video.

- [x] **Step 3: Track the empty personal-recording directory**

Add an empty `.gitkeep` file so Git preserves `demo/zhekai-li-recording/` until Zhekai Li records the personal explanation.

### Task 2: Repair the demo entry point

**Files:**
- Modify: `app.sh`
- Modify: `demo/ai-generated-narration/run_demo.sh`

- [x] **Step 1: Point `app.sh --demo` to the moved runner**

Change the target to `demo/ai-generated-narration/run_demo.sh`.

- [x] **Step 2: Recalculate the runner's project root**

Because the runner is now nested one directory deeper, resolve the root with `../..` so its data, workflow, and UI paths still work.

- [x] **Step 3: Check Bash syntax**

Run:

```bash
bash -n app.sh demo/ai-generated-narration/run_demo.sh
```

Expected: exit status 0 and no output.

### Task 3: Put usage and deliverables first in the README

**Files:**
- Modify: `README.md`
- Modify: `docs/REQUIREMENTS_AUDIT.md`

- [x] **Step 1: Add a Quick Start section immediately below the title**

Document Gum installation, cloning, launching the interactive app, launching the isolated demo, and the six menu features.

- [x] **Step 2: Add a Deliverables section before the architecture material**

Link the AI-generated video, narration, and runner together; label the empty personal-recording directory with the name **Zhekai Li** and state that the recording is pending.

- [x] **Step 3: Update current documentation paths**

Change the requirements audit to point to `demo/ai-generated-narration/demo.mp4`.

### Task 4: Verify the reorganized project

**Files:**
- Verify: `README.md`
- Verify: `app.sh`
- Verify: `demo/ai-generated-narration/run_demo.sh`
- Test: `tests/test.sh`

- [x] **Step 1: Check links and old path references**

Run:

```bash
rg -n 'demo/(demo\.mp4|narration\.txt|run_demo\.sh)' README.md app.sh docs/REQUIREMENTS_AUDIT.md
```

Expected: no matches.

- [x] **Step 2: Run the automated test suite**

Run:

```bash
./tests/test.sh
```

Expected: all tests pass.

- [x] **Step 3: Confirm the final deliverable tree**

Run:

```bash
find demo -maxdepth 2 -print | sort
```

Expected: the three generated assets are under `demo/ai-generated-narration/`, and `demo/zhekai-li-recording/` contains only `.gitkeep`.
