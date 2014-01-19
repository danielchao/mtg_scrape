require 'open-uri'
require 'cgi'

names = []
names_file = File.open('names2.txt', 'r')
names_file.each do |line|
    names.push(line.strip.gsub("'", "\'"))
end

# For non-lands
REGEX  = /<a\shref="(.*)">(.*)<\/a>(?:\n.*){7}<p>(.*),.*\n\s+(.*)\s+/
# For lands
REGEX2 = /a\shref="(.*)">(.*)<\/a>(?:\n.*){7}<p>(.*)()/
# For multi-card results
REGEX3 = /<td><a href="(.*)">(.*)<.*<.*\n.*<td>(.*)<.*\n.*<td>(.*)</

# Grabbing card text
CARD_TEXT_REG = /<p class="ctext">(.*)<\/p>/
# Grabbing Edition/Rarity
CARD_EDITION_REG = /Editions.*<b>(.+\))<\/b>/m



def scrape_cards(names)
    names.each do |name|
        content = curl_content(name)
        # matches format: name, type, cost, uri
        matches = content.scan(REGEX)
        if matches.count == 0 
            matches = content.scan(REGEX2)
        end
        if matches.count == 0
            matches = content.scan(REGEX3)
        end
        if matches.count == 0
            $stderr.puts "could not find " + name
            next
        end
        begin
            entry = []
            entry.push(matches[0][1].gsub(',', '\,')) # escape commas
            entry.push(matches[0][2].scan(/^([^—-]*)/)[0][0].strip) # get type
            if matches[0][3].strip == ''
                entry.push('', '0')
            else
                cost = matches[0][3].scan(/^(.*)\((\d*)\)|(.*)/)[0]
                if cost[2] # matches case with no parentheses
                    entry.push(cost[2].strip) # full mana cost
                else
                    entry.push(cost[0].strip) # full mana cost
                end
                if cost[1] and cost[1] != '' # converted mana cost available
                    entry.push(cost[1]) # converted mana cost
                else
                    entry.push(0) # converted mana cost
                end
            end

            text = content.scan(CARD_TEXT_REG)[0][0]
                .gsub(',', '\,')
                .gsub(/<\/?br?>/, ' ').strip
            edition = content.scan(CARD_EDITION_REG)[0][0]
                .gsub(',', '\,')
            entry.push(text)
            entry.push(edition)
            puts entry.join(',')
        rescue 
            $stderr.puts $!, $@
            $stderr.puts "exception when finding " + name
        end
    end
end

def curl_content(card_name)
    # URI format properly
    content = ''
    card_name.gsub!(' ', '+')
    card_name.gsub!('_', '/')
    card_name.gsub!(/[“”]/, '')
    open(URI.encode("http://magiccards.info/query?q=!#{card_name}")) do |f|
        f.each_line {|line| content << line}
    end
    return content
end

scrape_cards(names)

