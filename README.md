# ContextChat

An AI chat app with special focus on handling projects context. Manage projects with reusable context and chat with AI models using project-specific references.

### Chat

|                Light                 |                Dark                |
| :----------------------------------: | :--------------------------------: |
| ![Home Light](assets/home-light.png) | ![Home Dark](assets/home-dark.png) |

### Settings

|                    Light                     |                    Dark                    |
| :------------------------------------------: | :----------------------------------------: |
| ![Settings Light](assets/settings-light.png) | ![Settings Dark](assets/settings-dark.png) |

## What's Implemented

### Core Features

- **Project Management**: Create, edit, and delete projects with validation and save feedback
- **Project Context**: Store reusable base context instructions for each project
- **File Import**: Import text files (PDFs, docs, code, etc.) directly into base context
- **Image Support**: Import reference images (PNG, JPEG, WebP, GIF) that get attached to chat messages
- **Chat Interface**: Full chat UI with message history and streaming responses
- **Model Selection**: Choose AI models per project with persistence

### AI Integration

- **OpenRouter.ai Support**: Connect to OpenRouter.ai for access to multiple AI models
- **Streaming Responses**: Real-time message streaming with smooth scroll behavior
- **Vision Models**: Automatic image support for vision-capable models with validation
- **System Context Injection**: Project base context and files are injected as system messages

### UI/UX

- **Resizable Sidebar**: Drag to resize the sidebar (20-40% of window width)
- **Keyboard Shortcuts**: Cmd+Enter (macOS) or Ctrl+Enter (Windows/Linux) to send messages
- **Copy Messages**: One-click copy any message to clipboard
- **Settings**: Configure API base URL, API key, and view storage path
- **Auto-scroll**: Smart auto-scroll that pauses when user scrolls up

### Data Storage

- **Filesystem-based**: All data stored locally in app support directory
- **Project Storage**:
  - `memory/projects/<projectId>/project.json` - metadata
  - `memory/projects/<projectId>/MEMORY.md` - base context
  - `memory/projects/<projectId>/context/` - imported files
- **Chat Storage**: `memory/chats/<chatId>.md` - chat messages as Markdown

## Roadmap

### Near-term

- [ ] **Chat History Search**: Search through past conversations
- [ ] **Message Management**: Edit and delete individual messages
- [ ] **Chat Export**: Export chats to Markdown or JSON
- [ ] **Theme Toggle**: Manual switch between light and dark themes
- [ ] **Code Syntax Highlighting**: Better formatting for code blocks

### Medium-term

- [ ] **Multi-Provider Support**: Add support for OpenAI, Anthropic, and local models
- [ ] **Chat Organization**: Folders, tags, or favorites for organizing chats
- [ ] **Message Feedback**: Thumbs up/down for rating responses
- [ ] **Message Regeneration**: Regenerate AI responses with different models
- [ ] **Full-Text Search**: Search across all projects and chat histories

### Future Ideas

- [ ] **Token/Cost Tracking**: Monitor API usage and estimated costs
- [ ] **Chat Templates**: Save and reuse common chat patterns
- [ ] **Project Templates**: Pre-configured project setups for common workflows
- [ ] **Collaboration**: Share projects or chats with team members
- [ ] **Mobile Support**: Responsive layout for mobile/tablet use
- [ ] **Offline Mode**: Cache responses for offline reference

## Project Setup Flow

Use the Project button in the sidebar to open the full-page setup view. The form supports:

- **Create mode**: name, base context, and imported files, with validation and save feedback
- **Edit mode**: update name/context and add/remove imported files

Imported files are copied into the app's project storage; removing a file deletes the stored copy.

## Chat Context Assembly

When sending a chat message from a project:

1. The base context is injected first (if present)
2. Imported text files are appended to the system context
3. Imported images are attached as multipart content to the user message
4. Chat history follows

This makes project-specific references available to the model without requiring manual paste.
