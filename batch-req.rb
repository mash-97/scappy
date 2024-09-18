require 'async'
require 'rest-client'

$__headers__ = {}
$__headers__[:user_agent] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

class BatchReq
  def initialize(urls, batch_size=10, max_timeout=10, max_attempts=3)
    @max_timeout = max_timeout
    @max_attempts = max_attempts
    @batch_size = batch_size
    @webclient = RestClient
    @urls = urls
    @xurls = @urls.collect{|url|
      {
        url: url,
        attempts: 0,
        response_times: [],
        response: nil
      }
    }
  end

  def process(&callback)
    results = {
      failed_urls: [],
      successful_urls: [],
      total_batches: 0,
      batch_history: []
    }
    while not @xurls.empty? do
      batch_size = [@batch_size, @xurls.size].min
      xxurls = batch_size.times.collect{@xurls.shift()}
      attempt_urls = []
      st = Time.now
      Async do
        |task|
        tasks = xxurls.collect do |xurl|
          task.async do
            xurl[:attempts] += 1
            t = Time.now
            response = get(xurl[:url], @max_timeout, &callback)
            xurl[:response_times] << (Time.now-t)

            if response then
              xurl[:response] = response
              results[:successful_urls] << xurl
            elsif xurl[:attempts] < @max_attempts
              attempt_urls << xurl
            else
              results[:failed_urls] << xurl[:url]
            end
          end
        end
        tasks.each(&:wait)
      end
      et = Time.now
      results[:batch_history] << [batch_size, (et-st).round(3)]
      attempt_urls.each{|x|@xurls<<x}
    end
    return results
  end

  private
  def get(url, timeout, &callback)
    response = nil
    begin
      response = RestClient.get(url, headers: $__headers__, timeout: timeout)
    rescue => e  
      puts("#>> RestClient Error: #{e}")
      response = nil
    end
    return response ? yield(response) : nil
  end
end
