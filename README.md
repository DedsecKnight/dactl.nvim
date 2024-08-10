# Dactl.nvim

## Feature

- Automatically inject code snippet along with all necessary dependencies
- As long as TRD follows KACTL file convention, this plugin should be usable as well.

## Install

- Lazy.nvim

```lua
{
  "DedsecKnight/dactl.nvim",
  config = function()
    require("dactl").setup({
      trd_path = "" -- absolute path of content folder of your KACTL repository goes here (this configuration is required)
    })
  end
}
```

## Example configuration

```lua
{
  "DedsecKnight/dactl.nvim",
  config = function()
    require("dactl").setup({
      trd_path = os.getenv("HOME") .. "/competitive_programming/dactl/content"
    })
  end
}
```

## Usage

- In normal mode, type `DactlImport` and choose the snippet you want to import into your code file. Snippet will be injected into cursor position of active file.
