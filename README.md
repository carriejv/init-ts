# init-ts

An reasonably minimalist initial Typescript app / library template, because the Typescript ecosystem just has too many config files.

Includes:
* Preconfigured eslint, tsdoc, and build scripts.
* Compiler config targeting Node `>=10` and `ES2018`. Build target can be upgraded to `ES2020` easily if only Node `>=14` is needed.
* Basic Mocha unit testing setup with lcov, html, and text output.
* Github Actions CI for building branches and publishing version tags.
* Package.json and license autofilling script.

## Usage

`bash -c "$(curl -sSL https://raw.githubusercontent.com/carriejv/init-ts/master/init-ts.sh)"`

Alternatively, clone this repo and replace values in `package.json` manually.

## License

This codebase itself is licensed under the [Apache-2.0](https://github.com/carriejv/init-ts/blob/master/LICENSE) License.
