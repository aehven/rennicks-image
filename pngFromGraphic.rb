require "execjs"
require "open-uri"
require "sqlite3"
require "json"
require "ntcipAccess"
require "pngFromNTCIP"
module Test

#####
# get the command line arguments
#####
graphicName = ""
ARGV.each do |arg|
   case arg[0..1]
   when '-g'
      graphicName=arg.partition(':').last
   end
end

######
# get the graphic data
#####
if nil == graphicName
puts "Graphic Name Required"
exit
end
db = SQLite3::Database.open "messages.db"
stm = db.prepare "SELECT GraphicData from graphics WHERE GraphicName = ?;"
stm.bind_param 1, graphicName
rs = stm.execute

graphicString = ""
rs.each do |row|
theGraphic = row
graphicString = theGraphic.to_s
#####
# clean off stuff at the beginning and end
########
graphicString = graphicString[3..-4]
break;
end
#puts graphicString

######
# the message data has double quotes escaped with a backslash
# this is good for passing to the javascript program
# but it does not work in ruby
# so strip off the backslashes
#####
graphicString2 = graphicString.gsub(/\\/,"")
#puts graphicString2

######
# parse the graphic data
######
parsedGraphic = JSON.parse(graphicString2)
graphicBMP = parsedGraphic["previewBitmap"]

#####
# this preview was intended for Javascript
# so replace the javascript Arrow Function with a JSON :
#####
graphicBMPString = graphicBMP.to_s.gsub(/=>/,":")


#####
## produce .png image files
## scaled x 3
#####
#puts graphicBMPString
pfn = PNGFromPreview.new(3, graphicBMPString, graphicName)
pfn.toPNG
end
