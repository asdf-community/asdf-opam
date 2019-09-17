<div align="center">
<h1>asdf-opam 📦</h1>
Opam plugin for ASDF version manager
</div>
<hr />

**_This tool supports Opam 2.0.1 later. More earlier versions are not currently
supported._**

## Prerequirements

- Make sure you have the required dependencies installed:
  - A C++ compiler
  - GNU make
  - curl
  - git
  - tar

#### Note

You don't need to install OCaml before install Opam. because `asdf-opam` is
provided as a tool to compile OCaml, then compile and install opam. but, this
tool only installs Opam. so, if you want to install OCaml, use `asdf-ocaml` (or
Opam).

## Installation

```bash
asdf plugin-add opam https://github.com/asdf-ocaml/asdf-opam.git
```

## Usage

Check [asdf](https://github.com/asdf-vm/asdf) readme for instructions on how to
install & manage versions.
