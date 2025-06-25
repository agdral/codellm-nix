---

### codellm-nix

Welcome! This is a **personal Nix flake** for [codellm](https://github.com/dvogeldev/codellm-nix), making it easy to install and use the latest from [Abacus.AI](https://abacus.ai/) on **Linux x86_64** systems.

#### What is this?

This repo provides a Nix flake that packages the latest Abacus.AI-powered `codellm` tool for **Linux x86_64**. It’s designed for easy installation and integration into your NixOS system or any Nix-enabled Linux x86_64 environment.

#### Features

- **Latest Abacus.AI**: Always pulls in the most recent Abacus.AI Python package.
- **Nix Flake**: Reproducible, declarative, and easy to use.
- **Linux x86_64 only**: No support for ARM, macOS, Windows, etc.
- **Personal project**: Built for my own use, but you’re welcome to fork and adapt!

#### How to Install

**With Nix flakes enabled:**

1. **Install codellm to your user profile:**
   ```sh
   nix profile install github:dvogeldev/codellm-nix
   ```

2. **Run codellm directly (without installing):**
   ```sh
   nix run github:dvogeldev/codellm-nix
   ```

3. **Add to your NixOS configuration:**
   In your `flake.nix`:
   ```nix
   inputs.codellm-nix.url = "github:dvogeldev/codellm-nix";
   ```
   Then, in your `configuration.nix`:
   ```nix
   environment.systemPackages = with pkgs; [
     codellm-nix.packages.${system}.default
   ];
   ```

#### Requirements

- [Nix](https://nixos.org/download.html) (with flakes enabled)
- Linux x86_64 system

#### No Liability

This is a personal project, provided as-is, with **no warranty or liability whatsoever**. Use at your own risk!

#### Forks & Contributions

Feel free to fork, adapt, or use this as inspiration for your own projects. PRs are welcome, but please note this is maintained on a best-effort basis.

---

**Happy hacking!**

---

