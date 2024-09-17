require 'caxlsx'
require 'rubyXL'

class Xlsx 
  def initialize(file_name)
    @file_name = file_name
    @ap = Axlsx::Package.new
    loadXlsx()
  end
  def add_worksheet(name)
    @ap.workbook.add_worksheet(name: name) do |worksheet|
      yield(worksheet)
    end
  end
  def write()
    puts("i> write current state")
    @ap.serialize(@file_name)
  end

  private
  def loadXlsx()
    if not File.exists?(@file_name) then
      puts("i> file not found")
      @ap.serialize(@file_name)
      puts("i> file created: #{@file_name}")
    end
    puts("i> load with rubyXL")
    begin 
      rxl_wrkbook = RubyXL::Parser.parse(@file_name)
      puts("i> total worksheets to load: #{rxl_wrkbook.worksheets.size}")
      rxl_wrkbook.worksheets.each do |rx_ws|
        @ap.workbook.add_worksheet(name: rx_ws.sheet_name) do |ap_sheet|
          rx_ws.each_with_index do |rx_row, rx_indx|
            ap_sheet.add_row rx_row.cells.map(&:value)
          end
        end
      end
      puts("i> load complete")
      puts("i> total loaded worksheets: #{@ap.workbook.worksheets.size}")
    rescue => e
      puts("#> load error [rubyXL]: #{e}")
    end
  end
end