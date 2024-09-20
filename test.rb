require 'rest-client'
require 'nokogiri'
require_relative 'articles'

U = "https://www.upwork.com/nx/search/jobs/?category2_uid=531770282580668422&per_page=10&sort=recency"
UA = [   "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",   "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36",   "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1",   "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:90.0) Gecko/20100101 Firefox/90.0",
"curl/7.68.0" ]

def get()
  ua = UA.sample
  puts("ua: #{ua}")
  r = RestClient.get(U, headers: {'User-Agent' => ua})
  a = Nokogiri::HTML(r.body)
  return r, a, ua
end
