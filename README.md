# InsertLeftBracket.nvim

It offers objective-c square bracket completion, e.g.
`foo bar` -> `[foo bar]`

## Prerequites

* [Neovim][1]
* Ruby and [Neovim ruby client][2]

## Installation

### Install Prerequites

Install neovim ruby client
```bash
gem install neovim
```

### Install InsertLeftBracket

Use a plugin manager (for example, Neobundle)

```vim
NeoBundle 'haifengkao/InsertLeftBracket.nvim'
```

Or manually check out the repo and put the directory to your vim runtime
path.

## Acknowledgement

The parsing code is ported from [TextMate objective-c bundle][3]

[1]: https://neovim.io
[2]: https://github.com/alexgenco/neovim-ruby
[3]: https://github.com/textmate/objective-c.tmbundle
