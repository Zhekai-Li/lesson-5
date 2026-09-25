# Problem Set 2 Requirements Audit

Audit date: 2026-09-25

## Deliverables

- [x] Project is in the student's public GitHub repository: `https://github.com/Zhekai-Li/lesson-5`.
- [x] All prescribed architectural layers and files are present.
- [x] `README.md` includes run instructions, a concise architecture explanation, personalization, the demo link, and a workflow trace.
- [x] `demo/demo.mp4` is a 77-second narrated terminal demo showing Browse, Search, and Recommendations.
- [ ] The repository URL must still be entered manually in the class sheet under `Assignment No 2`.

## Required Technical Concepts

| Requirement | Evidence |
|---|---|
| Small Bash programs | `app.sh`, `ui/`, `workflows/`, `books/`, `recommendations/`, and `data/book_database.sh` |
| Modular architecture | UI → workflows → book/recommendation components → data layer → CSV |
| Meaningful pipe | `cat` of three agent outputs into `refine_recommendations.sh` in `workflows/get_recommendations.sh` |
| Parallelization | Three background commands using `&`; PIDs captured from `$!` |
| Synchronization | Named `wait` calls for all three agent PIDs |
| Streaming/progress | Recommendation status is printed to stderr while agents run |
| Gum UI | `ui/main_menu.sh`, `ui/library_screen.sh`, and `ui/recommendations_screen.sh` |
| Search argument/stdin | `books/search_books.sh` supports both interfaces |
| Metadata enrichment | `books/fetch_book_metadata.sh` uses the offline `books/catalog.tsv` |
| Three distinct strategies | History, interests, and discovery scripts emit the same TSV contract |
| Refinement | Excludes owned books, deduplicates, keeps best score, sorts, limits to five |
| Single data boundary | Only `data/book_database.sh` reads or writes `data/books.csv` |
| Personalization | Interdisciplinary shelf and catalog spanning technology, history, psychology, science fiction, and literature |

## Verification Results

| Check | Result |
|---|---|
| `./tests/test.sh` | 23 passed, 0 failed |
| `bash -n` on every `.sh` | Passed |
| All `.sh` entry points executable | Passed |
| Missing-Gum error path | Present in `app.sh` and demo |
| Production CSV access boundary | Passed by automated test |
| Demo isolation | Uses `BOOK_DB_FILE` in a temporary directory |
| Video codec | H.264 |
| Audio codec | AAC |
| Video resolution | 1280×720 |
| Video duration | 77 seconds |
| Video size | Approximately 1.5 MB |
| Visual review | Browse, Search, progress, and final recommendation states are readable |

## Workflow Trace

```text
main_menu.sh
  → get_recommendations.sh
      ├─ recommend_from_history.sh &
      ├─ recommend_from_interests.sh &
      └─ recommend_for_discovery.sh &
      → wait for three PIDs
      → cat three TSV files | refine_recommendations.sh
  → recommendations_screen.sh
```

The final manual submission action is outside the repository: enter `https://github.com/Zhekai-Li/lesson-5` in the class sign-up sheet.
