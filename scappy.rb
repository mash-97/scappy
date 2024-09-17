require 'async'
require 'nokogiri'
require 'rest-client'
require 'caxlsx'
require 'commander/import'
require_relative 'articles'
require_relative 'xlsx'

URL = ->(**hash){
  base_url_str = "https://www.upwork.com/nx/search/jobs/"
  url_strs = []
  url_strs << "sort=recency"
  url_strs << "page=#{hash[:page_no]}" if hash[:page_no]
  url_strs << "per_page=#{hash[:per_page]}" if hash[:per_page]
  url_strs << "category2_uid=#{hash[:category]}" if hash[:category]
  url_strs << "subcategory2_uid=#{hash[:sub_category]}" if hash[:sub_category]
  [base_url_str, url_strs.join('&')].join('?')
}

def add_to_worksheet(xlsx_obj, sheet_name, articles)
  xlsx_obj.add_worksheet(sheet_name) do |sheet|
    sheet.add_row articles.first.keys().map(&:upcase)
    articles.each do |article|
      sheet.add_row article.values()
    end
  end
end

$__SYNC_TASK_TIMES__ = []
# program starts here
if $0==__FILE__ then
  program :name, 'Scappy'
  program :version, '0.0.1'
  program :description, 'Job scrapping from UpWork'

  command :scrap do |c|
    c.syntax = 'scappy scrap START_PAGE END_PAGE CSV'
    c.summary = 'Scrap jobs between START_PAGE and END_PAGE and write results to the CSV file'
    c.description = 'Scrap jobs like scappy!!!'
    c.example 'Example', 'scappy scrap 1 5 jobs'

    c.option '--start_page PAGE_NO', Integer, 'start page'
    c.option '--end_page PAGE_NO', Integer, 'end page'
    c.option '--per_page NUM', Integer, 'articles per page'
    c.option '--category UIDS', String, 'category UIDS'
    c.option '--output FILENAME', String, 'output filename'
    c.option '--sheet_name SHEETNAME', String, 'worksheet name'

    c.action do |args, options|
      __start_time__ = Time.now
      puts("> Start Time: #{__start_time__}")
      options.default :start_page => '1', :end_page => '1', :per_page => 10, :category => "", :output => "data-#{Time.now.strftime("%y%m%d-%H%M%S")}.xlsx", :sheet_name => 8.times.collect{('a'..'z').to_a.sample}.join()
      sp = options.start_page 
      ep = options.end_page 

      # contains list of articles 
      articles_list = [] 
      XSLX = Xlsx.new(options.output)   # <------------------------------------------- XSLX initialize

      # start page to end page process
      Async do |task|                   # <------------------------------------------- ASYNC tasks
        tasks = (sp.to_i..ep.to_i).collect do |page_no|

          print("\n> At page: #{page_no} => ")
          task.async do
            __sync_task_time_start__ = Time.now
            begin 
              url = URL.call(
                page_no: page_no, 
                per_page: options.per_page, 
                category: options.category.strip.split(',').map(&:strip).first
              )
              print("url: #{url}")
              articles_list << Articles.get_articles(url)
            rescue => e  
              print("##> #{e} =>")
            end
            __sync_task_time_end__ = Time.now
            $__SYNC_TASK_TIMES__ << (__sync_task_time_end__-__sync_task_time_start__)
          end
        end
        puts("\n> Async task creation complete")
        puts("> Now wait")
        tasks.each(&:wait)
      end
      
      articles_list.select{|a|a.size>0}.each_with_index do |articles, page_no|
        puts("> update XSLX with #{articles.size} articles")
        add_to_worksheet(XLSX, options.sheet_name, articles)
      end

      puts("> write to excel: #{options.output}")
      XLSX.write()                                                      # <---------------- XLSX close
      __end_time__ = Time.now
      puts("> Command Execution Time: #{(__end_time__-__start_time__).round(3)} seconds")
      puts("> Sync Time Status: (Total : Avg) => (#{($__SYNC_TASK_TIMES__.sum.round(3))} : #{($__SYNC_TASK_TIMES__.sum/$__SYNC_TASK_TIMES__.size).round(3)}) seconds")
    end
    
  end
end

