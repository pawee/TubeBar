# TubeBar

YouTube and YouTube Music in a floating panel you toggle with a hotkey. TubeBar lives in the macOS menu bar. It has no Dock icon and doesn't show up in ⌘-Tab, so a player window never clutters your app switching. Playback keeps going while the panel is hidden.

## Features

- **⌥`** (Option + the key left of 1) shows or hides the panel from anywhere. The hotkey uses the physical key, so it works with any keyboard layout.
- Two tabs, **YouTube** and **YouTube Music**. Both stay loaded, so you can browse videos while music plays.
- **Keep on Top** turns the panel into a floating mini player that follows you across Spaces.
- The panel remembers its size and position. Cookies persist, so you stay signed in.
- Open at Login, from the right-click menu.
- Native AppKit + WebKit. No dependencies, no Electron, about 370 lines of Swift.

## Requirements

- macOS 14 or later
- Xcode or the Command Line Tools (`xcode-select --install`)

## Build

```bash
git clone https://github.com/<you>/TubeBar.git
cd TubeBar
./build.sh
ditto build/TubeBar.app /Applications/TubeBar.app
open /Applications/TubeBar.app
```

The app is ad-hoc signed for local use, so build it yourself rather than downloading a prebuilt copy.

## Usage

| Action | Shortcut |
|---|---|
| Show / hide | ⌥` or click the menu bar icon |
| Menu (tabs, pin, login, quit) | Right-click the menu bar icon |
| YouTube / Music | ⌘1 / ⌘2 |
| Back / Forward / Reload | ⌘[ / ⌘] / ⌘R |
| Keep on Top | ⌘T |
| Hide panel (keeps playing) | ⌘W |

## Disclaimer

TubeBar is an unofficial wrapper around the YouTube website. It is not affiliated with or endorsed by YouTube or Google.

## License

MIT
