![](https://storageapi.fleek.co/fleek-team-bucket/logos/capp.png)

# The CAP (Certified Asset Provenance) Motoko Library

Transaction history & asset provenance for NFT’s & Tokens on the Internet Computer

> CAP is an open internet service providing transaction history & asset provenance for NFT’s & Tokens on the Internet Computer. It solves the huge IC problem that assets don’t have native transaction history, and does so in a scalable, trustless and seamless way so any NFT/Token can integrate with one line of code.

## Guides and Documentation

To start using the CAP Motoko Library to integrate CAP into your Motoko-based NFT/Token, visit our documentation or the examples folder in this repository.

- [CAP Motoko Library Documentation](https://docs.cap.ooo/integrate-cap/motoko-sdk/)
- [CAP Motoko Library Examples](https://github.com/Psychedelic/cap-motoko-library/tree/main/examples)


## 📒 Table of Contents 
- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Add the library to a project](#add-the-library-to-a-project)
- [Cap Motoko library specs](#cap-motoko-library-specs)
- [Release](#release)
- [Examples](/examples)
- [Contribution guideline](#contribution-guideline)
- [Links](#links)

## 🧐 Requirements

  - [DFX cli](https://smartcontracts.org/docs/quickstart/local-quickstart.html)
  - [Vessel Motoko package manager](https://github.com/dfinity/vessel) 

## 👋 Getting started

You're required to have [Vessel Motoko package manager](https://github.com/dfinity/vessel) binary installed and configured in your operating system.

Here's a quick breakdown, but use the original documentation for latest details:

- You understand the basics of `dfx cli`, otherwise take the time to learn [dfx getting started](https://smartcontracts.org/docs/quickstart/local-quickstart.html)

- Download a copy of the [Vessel binary](https://github.com/dfinity/vessel/releases) from the [release page](https://github.com/dfinity/vessel/releases) or build one yourself

- Add the [Vessel binary](https://github.com/dfinity/vessel/releases) location to your [PATH](https://en.wikipedia.org/wiki/PATH_(variable)) (e.g. for macOS one of the quickest ways to achieve this would be to symlink the binary in the /usr/local/bin directory which is included in [PATH](https://en.wikipedia.org/wiki/PATH_(variable)) by default)

- Run [Vessel](https://github.com/dfinity/vessel/releases) init in your project root.

  ```sh
  vessel init
  ```

- Edit `package-set.dhall` to include the [Cap Motoko Library](https://github.com/Psychedelic/cap-motoko-library) as described in [add the library to a project](#add-the-library-to-a-project).

- Include the `vessel sources` command in the `build > packtool` of your `dfx.json`

  ```sh
  ...
  "defaults": {
    "build": {
      "packtool": "vessel sources"
    }
  }
  ...
  ```

- From then on, you can simply run the [dfx build command](https://smartcontracts.org/docs/developers-guide/cli-reference/dfx-build.html) or [dfx deploy](https://smartcontracts.org/docs/developers-guide/cli-reference/dfx-deploy.html)

  ```sh
  dfx build
  ```
  
  ```sh
  dfx deploy <canister>
  ```

## 🤖 Add the library to a project

After you have initialised [Vessel](https://github.com/dfinity/vessel), edit the `package-set.dhall` and include the [Cap Motoko library](https://github.com/Psychedelic/cap-motoko-library) and the version, as available in the releases of [Cap Motoko Library](https://github.com/Psychedelic/cap-motoko-library).

In the example below of our `package-set.dhall`, we are using `v1.0.0`:

```sh
let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.7-20210818/package-set.dhall sha256:c4bd3b9ffaf6b48d21841545306d9f69b57e79ce3b1ac5e1f63b068ca4f89957
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  additions =
      [{ name = "cap-motoko-library"
      , repo = "https://github.com/Psychedelic/cap-motoko-library"
      , version = "v1.0.0"
      , dependencies = [] : List Text
      }] : List Package

in  upstream # additions
```
Make sure you also add the library as a dependency to your `vessel.dhall` file like this:
```sh
{
  dependencies = [ "base", "cap-motoko-library" ],
  compiler = Some "0.6.11"
}
```
We've assumed that you have followed `Vessel` initialisation e.g. the init and the `dfx.json`. 

Here's a breakdown of a project initialised by the [dfx cli](https://smartcontracts.org/docs/developers-guide/cli-reference.html):

1) Create a new Motoko project called `cap-motoko-example` (it's a random name that we selected for our example, you can name it whatever you want)

  ```sh
  dfx new cap-motoko-example
  ```

2) Initialise Vessel

  ```sh
  vessel init
  ```

3) Add the Cap Motoko library to `package-set.dhall`, as described in [Add the library to a project](#add-the-library-to-a-project)

4) Edit `dfx.json` and set `vessel sources` in the `defaults > build > packtool`

  ```sh
  {
    "canisters": {
      "cap-motoko-example": {
        "main": "src/cap-motoko-example/main.mo",
        "type": "motoko"
      },
      "cap-motoko-example_assets": {
        "dependencies": [
          "cap-motoko-example"
        ],
        "frontend": {
          "entrypoint": "src/cap-motoko-example_assets/src/index.html"
        },
        "source": [
          "src/cap-motoko-example_assets/assets",
          "dist/cap-motoko-example_assets/"
        ],
        "type": "assets"
      }
    },
    "defaults": {
      "build": {
        "args": "",
        "packtool": "vessel sources"
      }
    },
    "dfx": "0.8.1",
    "networks": {
      "local": {
        "bind": "127.0.0.1:8000",
        "type": "ephemeral"
      }
    },
    "version": 1
  }
  ```

5) From this point on, vessel will include the required packages for you

 ```sh
  dfx build
  ```

## Cap Motoko library specs

The specifications documents should be generated dynamically to be inline with the source-code. You'll have to clone the repository for [Cap Motoko library](https://github.com/Psychedelic/cap-motoko-library), and execute the doc generator:

```sh
make docs
```

Once completed, a directory `/docs` will be available providing the `html` files you can open on your browser (e.g. the `/docs/index.html`):

```sh
docs
├── Cap.html
├── Cap.md
├── IC.html
├── Root.html
├── Root.md
├── Router.html
├── Router.md
├── Types.html
├── Types.md
├── index.html
└── styles.css
```

## 🚀 Release

**TLDR; Common tag release process, which should be automated shortly by a semanatic release process in the CI**

Create a new tag for the branch commit, you'd like to tag (e.g. for v1.0.0):

```sh
git tag v1.0.0
```

Complete by pushing the tags to remote:

```sh
git push origin --tags
```

## 🙏 Contribution guideline

Create branches from the `main` branch and name it in accordance to **conventional commits** [here](https://www.conventionalcommits.org/en/v1.0.0/), or follow the examples bellow:

```txt
test: 💍 Adding missing tests
feat: 🎸 A new feature
fix: 🐛 A bug fix
chore: 🤖 Build process or auxiliary tool changes
docs: ✏️ Documentation only changes
refactor: 💡 A code change that neither fixes a bug or adds a feature
style: 💄 Markup, white-space, formatting, missing semi-colons...
```

The following example, demonstrates how to branch-out from `main`, creating a `test/a-test-scenario` branch and commit two changes!

```sh
git checkout main

git checkout -b test/a-test-scenario

git commit -m 'test: verified X equals Z when Foobar'

git commit -m 'refactor: input value changes'
```

Here's an example of a refactor of an hypotetical `address-panel`:

```sh
git checkout main

git checkout -b refactor/address-panel

git commit -m 'fix: font-size used in the address description'

git commit -m 'refactor: simplified markup for the address panel'
```

Once you're done with your feat, chore, test, docs, task:

- Push to [remote origin](https://github.com/Psychedelic/cap-explorer.git)
- Create a new PR targeting the base **main branch**, there might be cases where you need to target to a different branch in accordance to your use-case
- Use the naming convention described above, for example PR named `test: some scenario` or `fix: scenario amend x`
- On approval, make sure you have `rebased` to the latest in **main**, fixing any conflicts and preventing any regressions
- Complete by selecting **Squash and Merge**

If you have any questions get in touch!

## 🔗 Links

- Visit [our website](https://cap.ooo)
- Read [our announcement](https://medium.com/@cap_ois/db9bdfe9129f?source=friends_link&sk=924b190ea080ed4e4593fc81396b0a7a)
- Visit [CAP Service repository](https://github.com/Psychedelic/cap)
- Visit [CAP-js repository](https://github.com/Psychedelic/cap-js/) 
