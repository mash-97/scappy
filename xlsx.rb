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
    @ap.serialize(@file_name)
  end

  private
  def loadXlsx()
    if not File.exists?(@file_name) then
      @ap.serialize(@file_name)
    end
    begin 
      rxl_wrkbook = RubyXL::Parser.parse(@file_name)
      rxl_wrkbook.worksheets.each do |rx_ws|
        @ap.workbook.add_worksheet(name: rx_ws.sheet_name) do |ap_sheet|
          rx_ws.each_with_index do |rx_row, rx_indx|
            ap_sheet.add_row rx_row.cells.map(&:value)
          end
        end
      end
    rescue => e
      puts("#> load error [rubyXL]: #{e}")
    end
  end
end