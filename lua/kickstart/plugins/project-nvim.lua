return {
  'DrKJeff16/project.nvim',
  config = function()
    require('project').setup {
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
    }
  end,
}
