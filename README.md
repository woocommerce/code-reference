# WooCommerce Code Reference Generator

Generate [WooCommerce Code Reference](https://docs.woocommerce.com/wc-apidocs/index.html).

## Install

```bash
git clone https://github.com/woocommerce/code-reference-generator.git
```

## Usage

```bash
cd code-reference-generator
./deploy.sh -s <VERSION>
```

### Options

| Options                                             | Description                                                           |
| --------------------------------------------------- | --------------------------------------------------------------------- |
| `-h` or `--help`                                    | Show help information.                                                |
| `-v` or `--verbose`                                 | Increase verbosity. Useful for debugging.                             |
| `-s <VERSION>` or `--source-version <VERSION>`      | Source version to build and deploy.                                   |
| `-r <GITHUB_REPO>` or `--github-repo <GITHUB_REPO>` | GitHub repo with username, default to \"woocommerce/woocommerce\".    |
| `-e` or `--allow-empty`                             | Allow deployment of an empty directory.                               |
| `-m <MESSAGE>` or `--message <MESSAGE>`             | Specify the message used when committing on the deploy branch.        |
| `-n` or `--no-hash`                                 | Don't append the source commit's hash to the deploy commit's message. |
| `--build-only`                                      | Only build but not push.                                              |
| `--push-only`                                       | Only push but not build.                                              |

## Changelog

[See changelog for details](https://github.com/woocommerce/code-reference-generator/blob/master/CHANGELOG.md)
