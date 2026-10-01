# Intersections Library

## Quick Start

Requirements: Bash 3.2 or newer and [Gum](https://github.com/charmbracelet/gum). On macOS, install Gum, clone the repository, and start the interactive app:

```bash
brew install gum
git clone https://github.com/Zhekai-Li/lesson-5.git
cd lesson-5
./app.sh
```

Run all commands from the project root—the directory that contains `app.sh`. For example, when using this project from the `Lesson05` workspace:

```bash
cd /Users/zhekaili/Documents/1125/Lesson05/ps02
./app.sh
```

## Demo Videos — Two Versions

This project includes **two separate demo videos** of the application:

### 1. Zhekai Li's recorded demo

[Watch the demo recorded and explained by Zhekai Li](demo/zhekai-li-recording/Zhekai_demo.mp4)

This is the personal presentation recorded by **Zhekai Li**.

### 2. AI-generated narration demo

[Watch the AI-generated narration demo](demo/ai-generated-narration/demo.mp4)

This version uses AI-generated narration for a 60–90 second terminal walkthrough. Its supporting materials are also included:

- [AI narration script](demo/ai-generated-narration/narration.txt)
- [Automated demo runner](demo/ai-generated-narration/run_demo.sh)

The automated runner uses a temporary database and does not change `data/books.csv`. Run it from the project root with:

```bash
./app.sh --demo
```

## Features

The main menu provides these features:

| Feature | What it does |
|---|---|
| **Browse Library** | View every book currently saved in the library. |
| **Add Book** | Add a title and enrich it with bundled offline metadata. |
| **Search Library** | Search across the saved book fields. |
| **Update Status** | Mark a book as want-to-read, reading, completed, or paused. |
| **Update Rating** | Give a saved book a rating from 1 through 5. |
| **Recommendations** | Combine history, interests, and discovery suggestions. |

All metadata and recommendation data is bundled locally; the app does not need an API key, Codex, or a network connection.

Intersections Library is an offline personal book manager for readers who move between technology, history, psychology, science, and literature. It is built from small Bash programs connected by TSV streams, a single CSV data boundary, and a Gum terminal interface.

Both demos show the Intersections Library experience. The automated AI-narrated walkthrough browses the interdisciplinary starter shelf, searches it, and shows three recommendation strategies running in parallel.

## Architecture

```text
app.sh
  └─ UI (Gum prompts and tables)
      └─ workflows (coordination)
          ├─ books (offline metadata and search)
          ├─ recommendations (three agents and refinement)
          └─ data/book_database.sh
              └─ data/books.csv
```

`data/book_database.sh` is the only application component that reads or writes the CSV. Its query commands emit headerless, seven-column TSV. Writes validate input and replace the file atomically. The optional `BOOK_DB_FILE` environment variable redirects every operation to an isolated database for tests and demos.

The bundled `books/catalog.tsv` contains cross-disciplinary metadata and tags. Known books receive a genre, year, and link; unknown books get clear `Other`, `Unknown`, and `N/A` defaults.

## Commands

```bash
# Library operations
./data/book_database.sh list
./workflows/manage_library.sh add "The Gene" "Siddhartha Mukherjee" want-to-read ""
./workflows/manage_library.sh search psychology
./workflows/manage_library.sh update-status "The Gene" "Siddhartha Mukherjee" reading
./workflows/manage_library.sh update-rating "The Gene" "Siddhartha Mukherjee" 5

# Components accept arguments or stdin
./books/fetch_book_metadata.sh "The Gene" "Siddhartha Mukherjee"
printf 'history\n' | ./books/search_books.sh

# Final TSV is stdout; timing and progress are stderr
./workflows/get_recommendations.sh "technology history psychology literature"
```

The storage schema is:

```text
title,author,genre,year,status,rating,link
```

Statuses are `want-to-read`, `reading`, `completed`, or `paused`; ratings are blank or an integer from 1 through 5. CSV fields may safely contain commas and doubled quotes.

## Recommendation workflow trace

1. `ui/main_menu.sh` captures interest terms and calls `workflows/get_recommendations.sh`.
2. The workflow starts `recommend_from_history.sh`, `recommend_from_interests.sh`, and `recommend_for_discovery.sh` in the background with `&`, records each `$!`, and reports progress to stderr.
3. History scores genres from completed and rated books. Interests matches free-form terms against catalog tags. Discovery prefers genres absent from the current library.
4. The workflow uses `wait` on all three PIDs, reports any named failure, and writes each agent's seven-column TSV to a temporary file.
5. The actual pipeline `cat history interests discovery | refine_recommendations.sh` combines the streams.
6. Refinement excludes books already in the library, deduplicates by title and author, keeps the highest-scored version, sorts descending, and returns at most five rows.
7. `ui/recommendations_screen.sh` receives the final TSV on stdin and renders it with `gum table`.
8. Traps clean up all workflow temporary files on success, failure, or interruption.

## Personalization

The starter shelf reflects an interdisciplinary reading path: *The Left Hand of Darkness*, *The Design of Everyday Things*, *Designing Data-Intensive Applications*, *Pachinko*, and *The Silk Roads*. The catalog connects design with psychology, computing with history, fiction with ethics, and science with society. Edit the shelf through the app and recommendations automatically shift with completed books, ratings, interests, and genres not yet explored.

## Test

First enter the project root, then run the test script:

```bash
cd /Users/zhekaili/Documents/1125/Lesson05/ps02
./tests/test.sh
```

After cloning the GitHub repository elsewhere, replace the first line with the path to that cloned `lesson-5` directory.

The dependency-free Bash suite covers quoted CSV round trips, CRUD validation, atomic updates, offline metadata, both search interfaces, recommendation refinement, concurrent execution, clean stdout/stderr separation, architectural boundaries, and syntax compatibility.

## License

MIT — see [LICENSE](LICENSE).
