module Jekyll
  module Filters
    def summarize(str, splitstr = /\s*<div id="extended"/)
      str.split(splitstr)[0]
    end
  end
end
