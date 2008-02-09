class Subversion::PropgetParser
  def parse(lines)
    directories = {}
    current_dir = nil
    lines.each do |line|
      split = line.split(" - ")
      if split.length > 1
        current_dir = split[0]
        line = split[1]
      end
      split = line.split(" ")
      directories["#{current_dir}/#{split[0]}"] = split.last unless split[0].blank? || split.length > 2
    end
    directories
  end
end