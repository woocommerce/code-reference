# WooCommerce Code Reference Generator

Generate [WooCommerce Code Reference](https://docs.woocommerce.com/wc-apidocs/index.html).

## Install

```bash
git clone https://github.com/woocommerce/code-reference-generator.git
```

## Usage

```bash
cd code-reference-generator
./generate.sh -s <woocommerce_version>
```

### Options

| Options                    | Description                                                     |
|----------------------------|-----------------------------------------------------------------|
| `-h` or `--help`           | Shows help message                                              |
| `-v` or `--version`        | Shows generator version                                         |
| `-s` or `--source-version` | Version of the source code to release                           |
| `-r` or `--github-repo`    | GitHub repo with username, default to "woocommerce/woocommerce" |

## Changelog

[See changelog for details](https://github.com/woocommerce/code-reference-generator/blob/master/CHANGELOG.md)
