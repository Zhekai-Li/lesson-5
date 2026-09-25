# Demo, Audit, and Learning Guide Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the demo with a readable narrated terminal walkthrough, verify every `ps02.md` requirement, and add a Chinese guide that prepares the student to explain the repository end to end.

**Architecture:** Preserve the application code and its UI → workflows → components → data boundary. Produce the demo from the real isolated `./app.sh --demo` workflow, audit requirements with executable checks, and document the verified code paths rather than duplicating implementation logic.

**Tech Stack:** Bash 3.2, Gum, macOS terminal UI, FFmpeg/ffprobe for the delivery asset, Markdown, Git.

---

### Task 1: Verify the Baseline

**Files:**
- Inspect: `/Users/zhekaili/Documents/1125/Lesson05/docs/ps02.md`
- Test: `tests/test.sh`

- [x] **Step 1: Run the complete test suite**

Run: `./tests/test.sh`

Expected: `1..23`, followed by `# 23 passed, 0 failed`.

- [x] **Step 2: Run syntax and permission checks**

Run: `find . -name '*.sh' -type f -exec bash -n {} \;` and inspect executable bits with `find . -name '*.sh' -type f ! -perm -111`.

Expected: both commands produce no failures.

### Task 2: Rebuild the Narrated Demo

**Files:**
- Modify: `demo/narration.txt`
- Replace: `demo/demo.mp4`
- Verify: `demo/run_demo.sh`

- [x] **Step 1: Use operation-aligned narration**

The narration must explicitly name Browse, Search, and Recommendations while explaining the data flow and must remain short enough for a 60–90 second video.

- [x] **Step 2: Capture the real terminal presentation**

Run `./app.sh --demo` in a large, uncluttered terminal view. Ensure the Browse, Search, progress, and Recommendations states are legible at 1280×720.

- [x] **Step 3: Produce and verify the delivery file**

Encode H.264 video plus AAC narration and replace `demo/demo.mp4`.

Run: `ffprobe -v error -show_entries format=duration,size:stream=codec_name,codec_type,width,height demo/demo.mp4`

Expected: video and audio streams, 1280×720, short duration, and a GitHub-friendly size.

### Task 3: Add the External Repository Learning Guide

**Files:**
- Create: `/Users/zhekaili/Documents/1125/Lesson05/docs/intersections-library-guide/INTERSECTIONS_LIBRARY_GUIDE.md`
- Create: `/Users/zhekaili/Documents/1125/Lesson05/docs/intersections-library-guide/INTERSECTIONS_LIBRARY_GUIDE.pdf`
- Modify: `README.md` to remove the obsolete in-repository guide link

- [x] **Step 1: Explain the assignment-to-code mapping**

Document where Bash modularity, pipes, parallelization, synchronization, streaming/progress, Gum, personalization, and persistence appear in the repository.

- [x] **Step 2: Teach both complete workflows**

Trace Add Book from `ui/main_menu.sh` through metadata and the data layer, and trace Recommendations through the three concurrent agents, `wait`, the refinement pipe, and the UI.

- [x] **Step 3: Add study exercises and oral-defense questions**

Provide a reading order, safe commands, expected observations, and concise answers the student can explain without Codex.

- [x] **Step 4: Keep the repository English-only**

Keep the standalone guide with the course documents, remove the obsolete repository link, and verify that repository text and filenames contain no Chinese characters.

### Task 4: Audit and Publish

**Files:**
- Verify: all required project files and `README.md`
- Create: `docs/REQUIREMENTS_AUDIT.md`

- [x] **Step 1: Record requirement evidence**

Create a compact checklist that cites exact files and commands for every deliverable and technical concept in `ps02.md`.

- [x] **Step 2: Re-run functional and media verification**

Run `./tests/test.sh`, `./app.sh --demo`, shell syntax checks, media inspection, and a static check that only `data/book_database.sh` names `books.csv` within application code.

- [x] **Step 3: Review the final diff**

Run `git diff --check` and `git status --short`. Confirm no database or unrelated user file changed.

- [x] **Step 4: Commit and push the completed deliverables**

Commit the verified video and documentation to `main`, push to `origin`, and confirm the remote commit. Do not edit the class sign-up sheet; report that final manual submission step explicitly.
