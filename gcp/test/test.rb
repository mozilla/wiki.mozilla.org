# frozen_string_literal: true

require 'typhoeus'
require 'nokogiri'

BASE_URL_PROD = 'https://wiki.mozilla.org'
BASE_URL_TEST = 'http://localhost:8080/index.php'

INSPECT_ELEMENT = '#content'

TEST_PAGES_COUNT = 1000
TEST_KEYWORDS = ['Warning: ', 'Error: '].freeze

def fetch_page(url)
  response = Typhoeus.get(url, followlocation: true)
  url = response.effective_url
  html = response.response_body
  code = response.response_code

  puts "WARN: #{url} Status code is #{code}" unless code == 200

  [html, url]
end

def parse_html(html)
  parsed_data = Nokogiri::HTML.parse(html)

  parsed_data.css(INSPECT_ELEMENT).inner_text
end

def pages_equal?(prod_page, test_page, keyword)
  prod_has_keyword = prod_page.include?(keyword)
  test_has_keyword = test_page.include?(keyword)

  puts "NOK: #{url} (#{prod_has_keyword})" if prod_has_keyword != test_has_keyword
end

TEST_PAGES_COUNT.times do |i|
  html, url = fetch_page("#{BASE_URL_PROD}/Special:Random")
  prod_page = parse_html(html)

  html, = fetch_page(url.gsub(BASE_URL_PROD, BASE_URL_TEST))
  test_page = parse_html(html)

  print "\r#{i}"

  TEST_KEYWORDS.each do |keyword|
    pages_equal?(prod_page, test_page, keyword)
  end
end
