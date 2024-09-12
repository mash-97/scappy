require 'nokogiri'
require 'rest-client'
require 'axlsx'
require 'commander/import'

URL = ->(page_no, per_page){"https://www.upwork.com/nx/search/jobs/?sort=recency&page=#{page_no}&per_page=#{per_page}"}
$AP = Axlsx::Package.new

def get_nokogorized_page(url)
  headers = {
  'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
  }
  response = RestClient.get(url, headers: headers)
  if response.code==200 then
    return Nokogiri::HTML(response.body)
  end
  # exit(1)
end

def get_narticles(noko_page)
  return noko_page.css('article.job-tile')
end

def parse_JobTileHeader(narticle)
  return narticle.css('h2.job-tile-title').inner_text
end

def parse_JobTileInfoList(narticle)
  job_tile_details = {}
  narticle.css('ul.job-tile-info-list > li').each do |li|
    if li['data-test'] then
      job_tile_details[li['data-test']] = li.inner_text
    else
      job_tile_details[li.inner_text] = li.inner_text
    end
  end
  # return job_tile_details
  return job_tile_details.values()
end

def parse_JobTileDescription(narticle)
  narticle.css('div[class="air3-line-clamp-wrapper clamp mb-3"]').inner_text
end

def parse_JobTileAttributes(narticle)
  narticle.css('div[class="air3-token-container"] > span').collect do |span|
    span.inner_text
  end
end

# narticle => nokogorized article
def parse_narticle(narticle)
  {
    "scrap-timestamp": Time.now.utc.to_s,
    "job-title" => parse_JobTileHeader(narticle),
    "job-info-list" => parse_JobTileInfoList(narticle).join(' -- '),
    "job-description" => parse_JobTileDescription(narticle),
    "job-attributes" => parse_JobTileAttributes(narticle).join(', ')
  }
end

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

    c.action do |args, options|
      options.default :start_page => '1', :end_page => '1', :per_page => 10
      sp = options.start_page 
      ep = options.end_page 
      puts("Starting with options: #{sp}, #{ep}")

      (sp.to_i..ep.to_i).each do |page_no|
        print("At page: #{page_no} => ")
        articles = []
        begin 
          noko_page = get_nokogorized_page(URL.call(page_no, options.per_page))
          narticles = get_narticles(noko_page)
          narticles.each do |narticle|
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
end

