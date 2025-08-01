return {
  'ahmedkhalf/project.nvim',
  config = function()
    require('project_nvim').setup {
      patterns = {
        -- git
        '.git',
        -- clojure & babashka
        'deps.edn',
        'project.edn',
        'bb.edn',
        -- java
        'pom.xml',
        -- go
        'go.mod',
      },
      silent_chdir = false,
    }
  end,
}
