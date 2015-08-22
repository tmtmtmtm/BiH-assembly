#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('a[href*="/sadrzaj/poslanici/p/?id="]').each do |link|
    scrape_person(link.text, URI.join(url, link.attr('href')))
  end
end

def scrape_person(name, url)
  noko = noko_for(url)

  izborna = noko.xpath('//td[contains(.,"Izborna")]/following-sibling::td').first.text.tidy
  unit, entity = izborna.sub('Izborna jedinica ','').split(/\//, 2).map(&:tidy)

  data = { 
    id: url.to_s[/\?id=(\d+)/, 1],
    name: noko.css('h1.poslanikNaziv').text.tidy,
    sort_name: name,
    image: noko.css('dt.slika img/@src').text,
    party: noko.xpath('//td[contains(.,"Stranka")]/following-sibling::td').first.text.tidy,
    faction: noko.xpath('//td[contains(.,"Klub")]/following-sibling::td').first.text.sub('Klub poslanika ','').tidy,
    email: noko.xpath('//td[contains(.,"E-mail")]/following-sibling::td').first.text.tidy,
    area: "#{unit} #{entity}",
    area_id: "ocd-division/country:ba/unit:#{unit.downcase}/entity:#{entity}",
    term: 7,
    source: url.to_s,
  }
  data[:image] = URI.join(url, URI.escape(data[:image])).to_s unless data[:image].to_s.empty?
  puts data[:name]
  ScraperWiki.save_sqlite([:id, :term], data)
end

term = { 
  id: 7,
  name: '2014–',
  start_date: 2014,
  source: 'https://www.parlament.ba/sadrzaj/plenarne_sjednice/Archive.aspx',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

scrape_list('https://www.parlament.ba/sadrzaj/poslanici/p/Archive.aspx?m=3')
