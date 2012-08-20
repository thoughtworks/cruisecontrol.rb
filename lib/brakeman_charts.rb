class BrakemanCharts
  require 'googlecharts'
  require 'csv'

  COLORS = '8a56e2,cf56e2,e256ae,e25668,e28956,e2cf56,aee256,68e256,56e289,56e2cf,56aee2,5668e2'

  def initialize(path)
    @csv_file = path
  end

  def valid?
    File.exist?(@csv_file)
  end

  def warning_chart
    clean_data

    CSV.foreach(@csv_file) do |row|
      if row[0] == "Warning Type"
        @ready = true
        next
      end

      next unless @ready
      next if row[0].nil?
      @labels << "#{row[0]}: #{row[1]}"
      @values << row[1].to_i
    end

    @labels.compact!
    @values.compact!

    Gchart.pie( :size         => '625x350',
                :title        => "BRAKEMAN Warnings",
                :legend       => @labels,
                :labels       => @values,
                :data         => @values,
                :bar_colors   => COLORS)
  end

  def scanned_chart
    clean_data

    CSV.foreach(@csv_file) do |row|
      if row[0] == "Scanned/Reported"
        @ready = true
        next
      end

      next unless @ready
      @labels << [ "#{row[0]}: #{row[1]}" ]
      @values << [ row[1].to_i ]

      @ready = false if row[0] == "Security Warnings"
    end

    @labels.compact!
    @values.compact!

    Gchart.bar( :bar_width_and_spacing  => '40,50,60',
                :size                   => '625x150',
                :title                  => "BRAKEMAN Summary",
                :legend                 => @labels,
                :labels                 => [ Time.now.to_s :long ],
                :data                   => @values,
                :bar_colors             => COLORS,
                :stacked                => false)
  end

private

  def clean_data
    @values = [ ]
    @labels = [ ]
    @ready = false
  end
end
