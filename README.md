# Project Memory App

This app manages projects, chats, and reusable project context stored on disk. Projects can include a base context and imported files that are copied into app-managed storage and injected into chat context.

## Project Setup Flow

Use the Project button in the sidebar to open the full-page setup view. The form supports:

- Create mode: name, base context, and imported files, with validation and save feedback.
- Edit mode: update name/context and add/remove imported files.

Imported files are copied into the app’s project storage; removing a file deletes the stored copy.

## Storage Layout

The app stores data under the memory directory shown in Settings. Each project lives under:

- `memory/projects/<projectId>/project.json` for project metadata (name and imported file list)
- `memory/projects/<projectId>/MEMORY.md` for the base context
- `memory/projects/<projectId>/context/` for imported files

Chats are stored under `memory/chats/` as Markdown files.

## Chat Context Assembly

When sending a chat message from a project:

- The base context is injected first (if present).
- Imported file contents are appended in deterministic order.

This makes project-specific references available to the model without requiring manual paste.
