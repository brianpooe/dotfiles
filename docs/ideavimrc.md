# Neovim → IdeaVim Migration Reference

This document maps the Neovim configuration in `.config/nvim/lua/brian/` to
the IdeaVim configuration at `.config/.ideavimrc`.

---

## Required Setup

### 1. Install IdeaVim
Available in every JetBrains IDE under **Settings → Plugins → Marketplace**.
Search for `IdeaVim`.

### 2. Symlink `.ideavimrc`
IdeaVim reads `~/.ideavimrc` by default:

```sh
ln -sf ~/dotfiles/.config/.ideavimrc ~/.ideavimrc
```

### 3. Optional Marketplace plugins
| Plugin | Purpose | Enable with |
|---|---|---|
| `IdeaVim-Which-Key` | Which-key popup for leader mappings | `set which-key` |
| `IdeaVim-EasyMotion` | `s`/`S` jump motions (like `hop.nvim`) | `set easymotion` |

Both are commented out in `.ideavimrc` by default. Uncomment after installing.

---

## Known Constraints

### Use :action syntax, not <Action>()

IdeaVim supports two syntaxes for invoking IDE actions from mappings:

```vim
nnoremap gd <Action>(GotoDeclaration)   " can silently fail
nnoremap gd :action GotoDeclaration<CR> " always works
```

When `<Action>()` fails to parse (version mismatch, parse error earlier in the
file), IdeaVim executes the RHS as literal vim keystrokes. For `GotoDeclaration`
this means `(` moves sentence, `G` goes to last line, `o` opens insert mode,
then `toDeclaration)` gets typed into the buffer. Always use `:action` syntax.

### sethandler must be at the top level
`sethandler` directives tell IdeaVim to intercept a key before the IDE does.
They **must appear at the top of `.ideavimrc`**, outside any `if` block.
Placing them inside `if has('ide')` causes IdeaVim to parse them in the wrong
phase, resulting in the IDE randomly stealing the key mid-session.

```vim
" CORRECT — top level, before any mappings
sethandler <C-h> a:vim
sethandler <C-l> a:vim
```

### No if has('ide') needed in .ideavimrc
`.ideavimrc` is only ever loaded by IdeaVim, never by regular Vim/Neovim.
The `if has('ide')` guard is only needed in a shared `.vimrc`. Using it here
causes `sethandler` and other directives to break.

### Options not supported by IdeaVim
IdeaVim does not implement all Vim options. The IDE controls indentation
settings under **Settings → Editor → Code Style**. These will throw `E518`
and must not appear in `.ideavimrc`:

- `shiftwidth`
- `tabstop`
- `softtabstop`
- `expandtab`
- `smartindent`
- `autoindent`

### Do not map Tab to NextTab
In terminal, `<Tab>` and `<C-i>` are the same keycode. Mapping `<Tab>` in
normal mode breaks jumplist-forward navigation (`<C-i>`) and conflicts with
IDE completion popups. Use `gt` / `gT` instead — IdeaVim supports these
natively for next/previous tab without any mapping.

### which-key requires a separate install
`set which-key` throws `E518: Unknown option` unless the **IdeaVim-Which-Key**
plugin is installed from the Marketplace. It is commented out by default.

---

## Plugin Emulation

IdeaVim ships with emulation for several popular Vim plugins. Enable them with
`set <name>` at the top level of `.ideavimrc`.

| Neovim plugin | IdeaVim equivalent | Status |
|---|---|---|
| `nvim-surround` | `set surround` | enabled |
| `vim-commentary` | `set commentary` | enabled |
| `which-key.nvim` | `set which-key` | commented out — install IdeaVim-Which-Key first |
| `vim-matchit` | `set matchit` | enabled |
| `argtextobj.vim` | `set argtextobj` | enabled |
| highlighted yank | `set highlightedyank` | enabled |
| `nvim-tree` | `set NERDTree` | enabled (see Navigation) |
| `hop.nvim` / sneak | `set easymotion` | commented out — install IdeaVim-EasyMotion first |

---

## What the IDE Replaces Natively

These Neovim plugins have **no IdeaVim equivalent** — the IDE provides the
functionality out of the box without any configuration.

| Neovim plugin | IDE equivalent |
|---|---|
| `nvim-lspconfig` / `mason.nvim` | JetBrains built-in language support |
| `blink-cmp` | JetBrains built-in completion |
| `nvim-treesitter` | JetBrains semantic highlighting |
| `bufferline.nvim` | JetBrains editor tab bar (configure under Settings → Editor → General → Editor Tabs) |
| `lualine.nvim` | JetBrains status bar |
| `lazygit.nvim` | Git tool window (`<leader>lg`) |
| `neotest` | JetBrains test runner (green gutter icons) |
| `nvim-dap` | JetBrains built-in debugger |
| `noice.nvim` | No equivalent — IDE owns all UI chrome |
| `render-markdown` | Markdown preview plugin |
| `nvim-colorizer` | No equivalent |
| `vim-tmux-navigator` | Not applicable |

---

## Navigation: NvimTree / C-h and C-l

In Neovim, `<C-h>` and `<C-l>` navigate between window splits, and NvimTree
is just another split. JetBrains uses a separate **tool window** for the
Project tree, which is not a vim split.

| Key | Neovim behaviour | IdeaVim behaviour |
|---|---|---|
| `<C-h>` | Focus split to the left (NvimTree) | Focus the Project tool window |
| `<C-l>` | Focus split to the right (editor) | `FocusEditor` — moves focus to the editor without opening or closing any panels. Note: this must also be bound natively in **Settings → Keymap** because IdeaVim is inactive when the Project tool window has focus. |
| `<leader>e` | `NvimTreeToggle` | `:NERDTree` (toggle the tree panel) |

`sethandler <C-h> a:vim` and `sethandler <C-l> a:vim` at the top of the file
are what make this reliable. Without them the IDE intercepts these keys
randomly depending on focus state.

For **editor split** navigation (vertical/horizontal splits inside the editor),
`<C-w>h/l/j/k` works natively in IdeaVim. `<C-j>` / `<C-k>` are mapped to
`<C-w>j` / `<C-w>k`.

---

## Keymap Reference

### File & Search  (Telescope → JetBrains)

| Neovim mapping | Telescope picker | IdeaVim action |
|---|---|---|
| `<leader>sf` | `find_files` | `GotoFile` |
| `<leader><leader>` | `buffers` | `Switcher` |
| `<leader>sb` | `buffers` | `Switcher` |
| `<leader>sg` | `live_grep` | `FindInPath` |
| `<leader>so` | `oldfiles` | `RecentFiles` |
| `<leader>sds` | `lsp_document_symbols` | `FileStructurePopup` |
| `<leader>sw` | `grep_string` | `FindUsages` |
| `<leader>sd` | `diagnostics` | `ActivateProblemsViewToolWindow` |
| `<leader>sm` | `marks` | `ShowBookmarks` |
| `<leader>/` | `current_buffer_fuzzy_find` | `Find` (in-file search) |

### LSP  (nvim-lspconfig → IDE actions)

| Neovim mapping | Description | IdeaVim action |
|---|---|---|
| `gd` | Go to definition | `GotoDeclaration` |
| `gD` | Go to declaration | `GotoDeclaration` |
| `gi` | Go to implementation | `GotoImplementation` |
| `gR` | References | `FindUsages` |
| `gt` | Go to type definition | `GotoTypeDeclaration` |
| `K` | Hover documentation | `QuickJavaDoc` |
| `<leader>ca` | Code actions | `ShowIntentionActions` |
| `<leader>rn` | Rename symbol | `RenameElement` |
| `<leader>df` | Line diagnostics | `ShowErrorDescription` |
| `<leader>D` | File diagnostics | `ActivateProblemsViewToolWindow` |
| `[d` | Previous diagnostic | `GotoPreviousError` |
| `]d` | Next diagnostic | `GotoNextError` |

### Buffers & Tabs

| Neovim mapping | Description | IdeaVim / note |
|---|---|---|
| `<Tab>` / `<S-Tab>` | Next/prev buffer | Use `gt` / `gT` — native, no mapping needed |
| `<leader>x` | Close buffer | `CloseContent` |
| `<leader>qt` | Close other buffers | `CloseAllEditorsButActive` |

### Window / Split Management

| Neovim mapping | Description | IdeaVim action |
|---|---|---|
| `<leader>v` | Vertical split | `SplitVertically` |
| `<leader>h` | Horizontal split | `SplitHorizontally` |
| `<leader>xs` | Close split | `Unsplit` |
| `<leader>se` | Toggle split orientation | `ChangeSplitOrientation` |
| `<C-j>` / `<C-k>` | Navigate splits | `<C-w>j` / `<C-w>k` |

### Git  (lazygit + telescope git pickers)

| Neovim mapping | Description | IdeaVim action |
|---|---|---|
| `<leader>lg` | Open git UI | `ActivateVersionControlToolWindow` |
| `<leader>gc` | File history (commits) | `Vcs.ShowTabbedFileHistory` |
| `<leader>gcf` | Blame / annotate | `Annotate` |
| `<leader>gb` | Branches | `Git.Branches` |
| `<leader>gs` | Stash / shelf | `Vcs.Show.Shelf` |

### Angular File Switching

In Neovim, `angular_switch()` in `keymaps.lua` switches between `.ts`,
`.html`, `.scss`, and `.spec.ts` within a component. In JetBrains the
**Angular plugin** provides `GotoRelatedFile` which opens a popup listing all
related files. All four `<leader>o*` mappings point to the same action.

Requires the **Angular and AngularJS** JetBrains plugin to be installed.

| Neovim mapping | Target |
|---|---|
| `<leader>ot` | `.component.ts` |
| `<leader>oh` | `.component.html` |
| `<leader>oc` | `.component.scss` |
| `<leader>os` | `.component.spec.ts` |

### Pure-Vim Mappings (identical behaviour)

| Mapping | Description |
|---|---|
| `<Esc>` | Clear search highlight |
| `<C-d>` / `<C-u>` | Scroll half-page and center |
| `n` / `N` | Find next/prev and center |
| `x` / `dd` | Delete without yanking to register |
| `p` (visual) | Paste without overwriting yank register |
| `<A-j>` / `<A-k>` | Move line/selection up or down |
| `<leader>j` | Replace word under cursor (`*``cgn`) |
| `<leader>y` / `<leader>Y` | Yank to system clipboard |
| `<leader>gh` / `<leader>gl` | Jump to line start / end |
| `<leader>lw` | Toggle line wrap |
| `<leader>+` / `<leader>-` | Increment / decrement number |
| `<leader>st` | Sort selected lines (unique) |
| `<leader>~` | Toggle case of selection |
| `<C-s>` | Save all |

---

## Discovering Action IDs

To find the exact action ID for any IDE action:

1. Open **Help → Find Action** (`Cmd+Shift+A`) and search **Track Action IDs**.
2. Enable it — every action you invoke will print its ID in the status bar.
3. Search available actions from inside IdeaVim:

```vim
:actionlist GotoDeclaration
```
