require 'rest-client'
require 'async'

class WebReqClient
  def initialize(urls, max_batch_size=50)
    @max_batch_size = nil
    @webclient = RestClient
    @urls = urls
  end
  def fetchData()
  end
end
