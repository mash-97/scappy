require 'axlsx'
require 'rubyXL'

class Xlsx 
  def initialize(file_name)
    @file_name = file_name
    @ap = Axlsx::Package.new
    loadXlsx(file_name)
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
    else
      rubyxl_workbook = RubyXL::Parser.parse(@file_name)
      rubyxl_workbook.worksheets.each do |rx_ws|
        @ap.workbook.add_worksheet(name: rx_ws.sheet_name) do |ap_sheet|
          rx_ws.each_with_index do |rx_row, rx_indx|
            ap_sheet.add_row rx_row.cells.map(&:value)
          end
        end
      end
    end
  end
end