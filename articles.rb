require 'nokogiri'

$CLIENT = RestClient
class Articles
  class << self
    def get_articles(response_body)
      noko_page = Nokogiri::HTML(response_body)
      narticles = get_narticles(noko_page)
      narticles.collect{|narticle| parse_narticle(narticle)}
    end
    

    def get_narticles(noko_page)
      return noko_page.css('article.job-tile')
    end

    def parse_PostedTime(narticle)
      return narticle.css(%{div[class="d-flex flex-column job-tile-header-line-height flex-1 mr-4 mb-3 flex-wrap"]}).css(%{small[class="text-light mb-1"]}).text
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
      narticle.css('div[class="air3-token-container"] > div > button > span').collect do |span|
        span.inner_text
      end
    end

    # narticle => nokogorized article
    def parse_narticle(narticle)
      {
        "scrap-timestamp"=> Time.now.utc.to_s,
        "posted-time" => parse_PostedTime(narticle),
        "job-title" => parse_JobTileHeader(narticle),
        "job-info-list" => parse_JobTileInfoList(narticle).join(' -- '),
        "job-description" => parse_JobTileDescription(narticle),
        "job-attributes" => parse_JobTileAttributes(narticle).join(', ')
      }
    end
  end
end