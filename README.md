# Intersections Library

Intersections Library is an offline personal book manager for readers who move between technology, history, psychology, science, and literature. It is built from small Bash programs connected by TSV streams, a single CSV data boundary, and a Gum terminal interface.

## Run it

Requirements: Bash 3.2 or newer and [Gum](https://github.com/charmbracelet/gum). On macOS:

```bash
brew install gum
git clone https://github.com/Zhekai-Li/lesson-5.git
cd lesson-5
./app.sh
```

Choose **Browse Library**, **Add Book**, **Search Library**, **Update Status**, **Update Rating**, or **Recommendations**. All metadata and recommendation data is bundled locally; the application does not need an API key, Codex, or a network connection.

For a safe automated walkthrough that uses a temporary database:

```bash
./app.sh --demo
```

## Demo

[Watch the 60–90 second terminal demo](demo/demo.mp4)

The demo browses the interdisciplinary starter shelf, searches it, and shows three recommendation strategies running in parallel. It never changes `data/books.csv`.

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

```bash
./tests/test.sh
```

The dependency-free Bash suite covers quoted CSV round trips, CRUD validation, atomic updates, offline metadata, both search interfaces, recommendation refinement, concurrent execution, clean stdout/stderr separation, architectural boundaries, and syntax compatibility.

## License

MIT — see [LICENSE](LICENSE).
