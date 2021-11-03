# Neovim DAP Projector
Better project-specific configuration for nvim-dap with basic task execution in the integrated
terminal. Start the dubugger using telescope!

## Why Another Plugin?
Think of it as a simple wrapper for nvim-dap with Run Debug functionality found in many
IDEs.

[![run - debug](https://img.shields.io/badge/&#9654;_|_&#129714;-project-green?style=for-the-badge)]()

Some of the code was coppied from [yabs.nvim](https://github.com/pianocomposer321/yabs.nvim) and
[nvim-dap](https://github.com/mfussenegger/nvim-dap). yabs.nvim is a great plugin, but it has a lot
of functionality that I don't need, and nvim-dap's menues are a bit rough to navigate.

Hopefully that explains it :)

## Installation
#### Requirements
- Neovim verson 0.5+
- Telescope
- nvim-dap

If you are fine with that, install the following plugins with your favourite plugin manager
(example using [packer.nvim](https://github.com/wbthomason/packer.nvim)):
```lua
use 'nvim-lua/plenary.nvim'
use 'nvim-telescope/telescope.nvim'
use 'mfussenegger/nvim-dap'
-- and finally...
use 'kndndrj/nvim-dap-projector'
```

## Getting started
The idea of this plugin is to separate **global** and **local** configurations:
- **Global** configs are the ones defined in the startup file (e.g. `init.lua`)
- **Local** or project configs are defined in the project folder (e.g. `launch.json` or `tasks.json`)

Further more, the configurations are divided into **debug** and **tasks** sections:
- **Debug** configurations are exactly the same as nvim-dap configurations
- **Tasks** configurations are for defining the shell commands.

Ask for help with `:h dap-projector`!

## Configuration
The configurations can be set in `init.lua` under the following table: 
```
require'projector'.configurations.<scope>.<type>.<language-group>
```
Or they can be read from a `.json` file in your project folder. That can be achieved by placing
this in your `init.lua`:
```lua
-- takes an optional argument for path, default is './.vim/projector.json'
require'projector.config_utils'.load_project_configurations()
```
If you want to load existing nvim-dap configurations, add this to `init.lua`:
```lua
require'projector.config_utils'.load_dap_configurations()
```

It is recommended to add the configurations under the `global` table in `init.lua` and use
`projector.json` to specify the `project` (local) configurations.

Examples of the configurations are listed in the [Configuraion Examples](#configuration-examples)
section.

## Usage
The recommended way of using is to **replace** nvim-dap `.continue()` mapping and use the function
provided by this plugin instead (this will replace dap's UI with telescope):
```lua
-- init.lua
vim.api.nvim_set_keymap('n', '<F5>', '<Cmd>lua require"projector".continue("all")<CR>', {noremap=true})
```

Use this mapping to manage currently running "non-debug" tasks (toggle command output windows):
```lua
vim.api.nvim_set_keymap('n', '<leader>dt', '<Cmd>lua require"projector".toggle_output()<CR>', {noremap=true})
```

## Configuration Examples

#### `init.lua`
- Global debug:
```lua
require'projector'.configurations.global.debug.go = {
  {
    type = 'go',
    name = 'Debug File',
    request = 'launch',
    showLog = false,
    program = '${file}',
    dlvToolPath = vim.fn.exepath('dlv'),
  },
}
```

- Global tasks:
```lua
require'projector'.configurations.global.tasks.shell = {
  {
    name = 'Good Morning',
    command = 'echo',
    args = {
      'I',
      'need',
      '$SOMETHING',
    },
    env = {
      SOMETHING = 'coffee'
    },
  },
  -- or
  {
    name = 'Good Morning',
    command = 'echo "I need more sleep"',
    cwd = '${workspaceFolder}',
  },
}
```

- Project-local debug:
```lua
require'projector'.configurations.project.debug.go = {
  -- not recommended to use in init.lua
  -- ...
}
```

- Project-local tasks:
```lua
require'projector'.configurations.project.tasks.shell = {
  -- not recommended to use in init.lua
  -- ...
}
```

#### `projector.json`
- Project-local debug:
```json
{
  "debug": {
    "go": [
      {
        // add the following section to any debug config
        // and run the configuration in non-debug mode
        "projector": {
          "command": "go run ${workspaceFolder}/main.go"
        },
        "type": "go",
        "request": "launch",
        "name": "My Project",
        "program": "${workspaceFolder}/main.go",
        "cwd": "${workspaceFolder}",
        "console": "integratedTerminal",
        "args": [
          "--argument",
          "1234"
        ],
        "env": {
          "SOME_BOOL": "true"
        },
        "dlvToolPath": "/usr/bin/dlv",
        "showLog": false
      }
    ]
  },
// ...
```

- Project-local tasks (still the same file):
```json
  "tasks": {
    "go": [
      {
        "name": "Generate",
        "command": "go generate",
        "args": [
          "${workspaceFolder}/tools.go"
        ]
      }
    ]
  }
}
```

## Contributing
If you have any questions or comments, please don't hesitate to open an issue. If you have a
suggestion, that's even better, open an issue or implement the feature yourself and create a pull
request!

P.S. If you have a suggestion on a cleaner way of implementing telescope (specifically in
`lua/projector.lua`), I would really appretiate it :).
