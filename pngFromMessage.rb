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
messageName = ""
ARGV.each do |arg|
   case arg[0..1]
   when '-m'
      messageName=arg.partition(':').last
   end
end

######
# get the message data
#####
if nil == messageName
puts "Message Name Required"
exit
end
db = SQLite3::Database.open "messages.db"
stm = db.prepare "SELECT MessageData from messages WHERE Messagename = ?;"
stm.bind_param 1, messageName
rs = stm.execute

messageString = ""
rs.each do |row|
theMessage = row
messageString = theMessage.to_s
#####
# clean off stuff at the beginning and end
########
messageString = messageString[3..-4]
break;
end
#puts messageString

######
# the message data has double quotes escaped with a backslash
# this is good for passing to the javascript program
# but it does not work in ruby
# so strip off the backslashes
#####
messageString2 = messageString.gsub(/\\/,"")
#puts messageString2

######
# parse the message data
######
parsedMessage = JSON.parse(messageString2)
messagePages = parsedMessage["pagesExport"];
imageWidth = parsedMessage["width"];
imageHeight = parsedMessage["height"];

bitmaps = []
messagePages.each do |page|
#####
# this preview was intended for Javascript
# so replace the javascript Arrow Function with a JSON :
#####
#bm = page["previewBitmap"]["bits"].to_s
bm = page["previewBitmap"]["bits"]
#bm = bm.to_s.gsub(/=>/,":")

#####
# images have a border 
# which makes them larger than the sign
#####
imageWidth = page["previewBitmap"]["width"];
imageHeight = page["previewBitmap"]["height"];

bitmaps.push bm
end


#####
## produce .png image files
## scaled x 3
#####
#puts bitmaps.to_s
pfn = SinglePNGFromPreview.new(imageWidth, imageHeight, 3, bitmaps, messageName)
pfn.toPNG
end
