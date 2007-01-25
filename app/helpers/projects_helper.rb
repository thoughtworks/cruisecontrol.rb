def format_changeset_log(log)
  log.strip
end

def format_build_log(log)
  convert_new_lines(log.gsub(/(\d+ tests, \d+ assertions, \d+ failures, \d+ errors)/, '<div class="test-results">\1</div>'))
end

def convert_new_lines(value)
  value.gsub(/\n/, "<br/>\n")
end