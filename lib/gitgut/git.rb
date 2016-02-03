module Gitgut
  # Show commits only on this branch
  # git log --no-merges HEAD --not develop --pretty=oneline
  module Git
    def self.missing_commits_count(from, to)
      `git rev-list #{from}..#{to} --count`.to_i
    end
  end
end