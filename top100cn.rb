require 'rubygems'
require 'mechanize'
require 'logger'
require 'cgi'
require 'open-uri'
require 'fileutils'  
require 'hpricot'

def get_cmd(url) 
  url = url.gsub("'", "%27").gsub("(", "%28").gsub(")", "%29")   
  "curl -s  -H 'Referer: #{url}' -H 'Accept-Encoding: gzip,deflate,sdch' -H 'Accept: application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5' -H 'Accept-Language: en-US,en;q=0.8' -H 'Accept-Charset: UTF-8,*;q=0.5' -H 'Host: www.top100.cn' -H 'Connection: keep-alive' '#{url}'"
end

# Mechanize.log = Logger.new(STDOUT)
start_at = Time.now

agent = Mechanize.new
# pp agent.methods.sort.grep(/agent/)
agent.user_agent_alias = 'Mac Safari'

# pp agent.user_agent

# page = agent.get('http://www.top100.cn/packages/info-pkyadycbigeadocbogy.shtml')
page = agent.get(ARGV.first || "http://www.top100.cn/packages/info-pkyadycbigr5docbogy.shtml")

title = page.title.strip
doc = Hpricot(page.content)

title = doc.search("div.fs14").first.inner_text.gsub(/\s*/, "").gsub(">", "_")


puts "Download mp3 of #{title}"

dir = "#{File.expand_path('~')}/Music/#{title}"

puts "Music file will be saved in #{dir}"

FileUtils.mkdir_p(dir)
# puts page.content

doc = doc.search("#songsListDiv ul input[@id=hidValue]")

links = []
doc.each do |link|
  links << link["value"]
end


prepend_url = "http://www.top100.cn/download/download.aspx?Productid="

puts links.size

urls = []

links.each do |link|
  link = "#{prepend_url}#{link[1..-1]}"
  
  page = agent.get(link) 
  
  # puts page.links.inspect
  
  # exit
  link = page.links.last.href  
  
  cmd = get_cmd(link)
  # puts cmd
  # exit
  html = `#{cmd}`
  # puts html
  # exit
  if html =~ /href="(.*?)"/
    urls << $1
  end 
end


step = 5
the_size = urls.size
0.step(the_size, step).each do |i|
  threads = [] 
  start_at = i
  end_at = i + step - 1
  end_at = (the_size - 1) if end_at > (the_size - 1)
  urls[start_at..end_at].each do |url|
    threads << Thread.new do
      puts "Fetching #{url}..."
      uri = URI(url)
      name = CGI.unescape(File.basename(uri.path)) 
      File.open("#{dir}/#{name}", "wb"){|f| f.write open(url).read }  
    end
  end
  threads.map(&:join)
end

puts "Time used: #{Time.now - start_at} seconds"


 




 


