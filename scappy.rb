require 'bundler/setup'
require 'async'
require 'nokogiri'
require 'rest-client'
require 'caxlsx'
require 'commander/import'
require 'yaml'
require_relative 'articles'
require_relative 'xlsx'
require_relative 'batch-req'

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
    c.option '--batch_size SIZE', Integer, 'batch size'

    c.action do |args, options|
      __start_time__ = Time.now
      puts("> Start Time: #{__start_time__}")
      options.default :batch_size => 10, :start_page => '1', :end_page => '1', :per_page => 10, :category => "", :output => "data-#{Time.now.strftime("%y%m%d-%H%M%S")}.xlsx", :sheet_name => 8.times.collect{('a'..'z').to_a.sample}.join()
      sp = options.start_page 
      ep = options.end_page 

      # contains list of articles 
      articles_list = [] 
      XLSX = Xlsx.new(options.output)   # <------------------------------------------- XLSX initialize

      # collect urls
      urls = (sp.to_i..ep.to_i).collect do |page_no|
        URL.call(
          page_no: page_no, 
          per_page: options.per_page, 
          category: options.category.strip.split(',').map(&:strip).first
        )
      end

      articles_size_url_map = []
      # async batch request
      print("> process batch requests: ")
      batch_request = BatchReq.new(urls, options.batch_size)
      results = batch_request.process do |response|
        articles = nil
        if response.code.to_s == "200" or response.code.to_s == "202" then
          articles = Articles.get_articles(response.body)
          $__SYNC_TASK_TIMES__ << response.duration
          articles_size_url_map << "#{response.request.url.scan(/page=\d+/).first.scan(/\d+/).first.to_i}:#{articles.size}"
          print(".")
        else
          print("#")
        end
        articles
      end
      puts()

      results[:successful_urls].each do |url|
        articles_list << url[:response]
        url[:response] = "OK"
      end

      File.open("scappy-#{Time.now.strftime("%y%m%d-%H%M%S")}.log", 'w') do |f|
        # results = {
        #   successful_urls: results[:successful_urls].collect{|x|x[:url]},
        #   failed_urls: results[:failed_urls].collect{|x|x[:url]}
        # }
        f.write(YAML.dump(results))
      end

      articles_size_map = articles_list.map(&:size)
      puts("> articles_list size map: #{articles_size_url_map} => Total: #{articles_size_map.sum}")
      articles_list = articles_list.select{|a|a.size>0}.flatten
      puts("> update XSLX with #{articles_list.size} articles")
      add_to_worksheet(XLSX, options.sheet_name, articles_list) if articles_list.size>0
      puts("> write to excel: #{options.output}")
      XLSX.write() 
      __end_time__ = Time.now
      puts("> Command Execution Time: #{(__end_time__-__start_time__).round(3)} seconds")
      puts("> Sync Time Status: (Total : Avg) => (#{($__SYNC_TASK_TIMES__.sum.round(3))} : #{($__SYNC_TASK_TIMES__.sum/$__SYNC_TASK_TIMES__.size).round(3)}) seconds")
    end
    
  end
end

