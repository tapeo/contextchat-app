# ContextChat

ContextChat is a powerful AI interface designed for developers and power users who need project-specific AI assistance. It streamlines your workflow by automatically injecting project context, files, and reusable prompts into your conversations.

### Chat and Settings
| Light | Dark |
| :---: | :---: |
| ![Home Light](assets/home-light.png) | ![Home Dark](assets/home-dark.png) |
| ![Settings Light](assets/settings-light.png) | ![Settings Dark](assets/settings-dark.png) |

---

## 🚀 Key Features

### 📁 Project-Based Context
*   **Reusable Instructions**: Set base system prompts for each project.
*   **File Knowledge**: Import text files (PDF, code, docs) directly into the AI's context.
*   **Model Defaults**: Assign specific AI models to different projects.
*   **Local Storage**: All project data and files stay on your machine.

### 💬 Intelligent Chat
*   **OpenRouter Integration**: Access any model from OpenAI, Anthropic, Google, and more.
*   **Vision Support**: Drag and drop images into vision-capable models.
*   **Real-time Streaming**: Smooth, responsive message delivery.
*   **Context Assembly**: Automatically builds the prompt with project rules + files + history.

### 📝 Prompt Library
*   **Save and Reuse**: Build a library of frequently used prompts.
*   **Variables**: Define variables in prompts for quick customization.
*   **Quick Insert**: Access your library directly from the chat composer.
*   **Pin and Search**: Keep your most important prompts at the top.

### 🛠 UI / UX
*   **Resizable Sidebar**: Flexible layout to suit your screen.
*   **Keyboard First**: Use `Cmd+Enter` (macOS) or `Ctrl+Enter` to send.
*   **Smart Scroll**: Auto-scroll that stays out of your way when you're reading.
*   **Markdown Support**: Full rendering for code blocks and formatting.

---

## ⚙️ How Context Works
When you send a message, ContextChat automatically assembles a rich prompt:
1.  **System Prompt**: Your Project's base context instructions.
2.  **Files**: The content of all text files attached to the project.
3.  **Images**: Any images you've attached to the current message.
4.  **History**: Your previous messages for ongoing conversation flow.

---

## 📂 Data and Privacy
*   **Local-First**: All metadata, project files, and chat histories are stored locally.
*   **Storage Path**: Customizable via settings (`memory/` by default).
*   **Direct API**: Connects directly to OpenRouter using your own API key.

## 🗺 Roadmap
- [ ] **Search**: Full-text search across all chat histories.
- [ ] **Message Editing**: Edit and regenerate AI responses.
- [ ] **Multi-Provider**: Direct support for OpenAI, Anthropic, and Local (Ollama) APIs.
- [ ] **Theme Sync**: Manual toggle for Light/Dark modes.
- [ ] **Export**: Export conversations to Markdown or JSON.

---
Built with Flutter.
