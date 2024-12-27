# RiV Mesh UI for desktop OS. Supported Windows, Linux, MacOS.

## Setup

### Windows
```rustup target add x86_64-pc-windows-msvc```

```rustup target add i686-pc-windows-msvc```

```rustup target add aarch64-pc-windows-msvc```

### Linux
```rustup target add aarch64-unknown-linux-gnu```

```rustup target add i686-unknown-linux-gnu```

```rustup target add aarch64-unknown-linux-gnu```

```rustup target add x86_64-pc-windows-gnu```

```rustup target add i686-pc-windows-gnu```

```rustup target add x86_64-apple-darwin```

```rustup target add aarch64-apple-darwin```


### MacOS
```rustup target add x86_64-apple-darwin```

```rustup target add aarch64-apple-darwin```


## Build
Watch source code changes and rebuild app automatically

```cargo tauri dev```

Build your app in release mode, generate bundles and installers

### Windows
```cargo tauri build --target x86_64-pc-windows-msvc```

```cargo tauri build --target i686-pc-windows-msvc```

```cargo tauri build --target aarch64-pc-windows-msvc```

### Linux
```cargo tauri build --target x86_64-unknown-linux-gnu```

```cargo tauri build --target i686-unknown-linux-gnu```

```cargo tauri build --target aarch64-unknown-linux-gnu```

### MacOS
```cargo tauri build --target x86_64-apple-darwin```

```cargo tauri build --target aarch64-apple-darwin```

## Recommended IDE Setup
- [VS Code](https://code.visualstudio.com/) + [Tauri](https://marketplace.visualstudio.com/items?itemName=tauri-apps.tauri-vscode) + [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)
