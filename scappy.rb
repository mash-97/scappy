require 'nokogiri'
require 'rest-client'
require 'axlsx'
require 'commander/import'
require_relative 'articles'

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
$AP = Axlsx::Package.new

def update_to_excel(articles, page_no)
  $AP.workbook.add_worksheet(name: "PAGE #{page_no}") do |sheet|
    sheet.add_row articles.first.keys().map(&:upcase)
    articles.each do |article|
      sheet.add_row article.values()
    end
  end
end


# program starts here
if $0==__FILE__ then
  puts("Start Time: #{Time.now}")
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

    c.action do |args, options|
      options.default :start_page => '1', :end_page => '1', :per_page => 10, :category => ""
      sp = options.start_page 
      ep = options.end_page 

      (sp.to_i..ep.to_i).each do |page_no|

        print("At page: #{page_no} => ")
        articles = []
        begin 
          url = URL.call(
            page_no: page_no, 
            per_page: options.per_page, 
            category: options.category.strip.split(',').map(&:strip).first
          )
          print("url: #{url} => ")
          Articles.get_articles(url).each do |narticle|
            articles << parse_narticle(narticle)
          end
        rescue => e  
          print("##> #{e} =>")
        ensure 
          puts("#{articles.size} articles")
          update_to_excel(articles, page_no)
        end
      end

      puts("write to excel")
      $AP.serialize('output.xlsx')
    end
  end
  puts("End Time: #{Time.now}")
end

