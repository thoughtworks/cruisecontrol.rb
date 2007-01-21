def format_build_log(log)
  log.gsub(/\n/, "<br/>\n").
      gsub(/(\d+ tests, \d+ assertions, \d+ failures, \d+ errors)/, '<div class="test-results">\1</div>')
end