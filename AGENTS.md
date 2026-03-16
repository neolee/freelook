# FreeLook — Agent Engineering Notes

Reference for AI coding agents working on this codebase. Keep this file concise, prescriptive, and focused on repository-wide rules.

---

## 1. Communication and Documentation

- Communicate with the user in Chinese.
- Write code comments and repository documentation in English unless explicitly requested otherwise.
- Do not use emojis in code comments or documentation.
- Use backticks for code references in Markdown.

---

## 2. Core Stack and Naming

---

## 3. Build and Verification

Run from repo root:

```shell
./scripts/build
```

- Do not pipe or post-process `./scripts/build` output.
- Keep the build free of compiler errors and warnings.
- If tooling returns empty or missing output, stop and ask the user to verify manually.

---

## 4. Localization Rules

---

## 5. Testing Rules

