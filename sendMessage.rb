require "execjs"
require "open-uri"
require "sqlite3"
require "json"
require "ntcipAccess"
require "pngFromNTCIP"
module Test

class FontNumberList
   def initialize()
   @fontNumberList = []
   end
   def addFontNumber(theFontName, theFontNumber)
      @fontNumberList << FontNameNumber.new(theFontName, theFontNumber)
   end
   def number
      @fontNumberList.number
   end
   def [](key)
      if key.kind_of?(Integer)
         return @fontNumberList[key].number
      else
        for i in 0...@fontNumberList.length
          return @fontNumberList[i].number if (key == @fontNumberList[i].name)
        end
      end
   end
end
class FontNameNumber
   def initialize(theFontName, theFontNumber)
      @name = theFontName
      @number = theFontNumber
   end
   def name
      @name
   end
   def number
      @number
   end
end
class FieldCodeList
   def initialize()
   @fieldCodeList = []
   end
   def addFieldCode(theFieldCode)
      @fieldCodeList << theFieldCode
   end
   def as_json(options={})
        {
            fieldCodeList: @fieldCodeList,
        }
   end
   def list
      @fieldCodeList
   end

   def to_json(*options)
        as_json(*options).to_json(*options)
   end
end
class FieldCode
   def initialize(name, description, length, currentValue)
      @name = name
      @description = description
      @length = length
      @currentValue = currentValue
   end
   def name
      @name
   end
   def value
      @currentValue
   end
   def as_json(options={})
        {
            name: @name,
            description: @description,
            length: @length,
            currentValue: @currentValue,
        }
   end

   def to_json(*options)
        as_json(*options).to_json(*options)
   end
end
FC_DELIM_START = "\u00AB".encode('utf-8')
FC_DELIM_END = "\u00BB".encode('utf-8')
#######
# compile the javascript program
#######
source = open("http://127.0.0.1/r5/drawingObjects.js").read
context = ExecJS.compile(source)

#####
# get the command line arguments
#####
messageName = ""
udpPort = "163"
ipAddress = "127.0.0.1"
communityName = "administrator"
fieldCodeList = ""
messageNumber = 3
graphicStartingIndex = 28
makePNGFile = "no"
ARGV.each do |arg|
   case arg[0..1]
   when '-m'
      messageName=arg.partition(':').last
   when '-n'
      messageNumber=arg.partition(':').last.to_i
   when '-g'
      graphicStartingIndex=arg.partition(':').last.to_i
   when '-a'
      ipAddress = arg.partition(':').last
   when '-p'
      udpPort = arg.partition(':').last
   when '-c'
      communityName = arg.partition(':').last
   when '-f'
      fieldCodeList = arg.partition(':').last
   when '-i'
      makePNGFile = arg.partition(':').last
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
messageString = messageString[3..-4]
break;
end

######
# the message data has double quotes escaped with a backslash
# this is good for passing to the javascript program
# but it does not work in ruby
# so make a copy and strip off the backslashes
#####
messageString2 = messageString.gsub(/\\/,"")
#puts messageString2

######
# parse the message data
######
parsedMessage = JSON.parse(messageString2)
signHeight = parsedMessage["height"]
signWidth = parsedMessage["width"]
onTimes = []
offTimes = []
parsedMessage["pagesExport"].each {|page|
   onTimes << page["onTime"]
   offTimes << page["offTime"]
}


#puts "h "+signHeight.to_s+" w "+signWidth.to_s

######
# get the list of fonts that are used
######
fnnList = FontNumberList.new
fontList = "'{\"fontList\":[";
numFonts = 0
parsedMessage["fontList"].each do |fontName|
puts fontName

   ######
   ## open the font file
   #####
   font = open("http://127.0.0.1/r5/font-"+fontName+".json").read

   #####
   ## grab font name and number for
   ## so we can populate the font tag in a MULTI string
   #####
   parsedFont = JSON.parse(font)
   fnnList.addFontNumber(parsedFont["name"], parsedFont["fontnumber"]);

   #####
   # get ready to pass this font to ExecJS
   #####
   font = font.strip
   fontList += font;
   fontList += ",";
   numFonts += 1
end
if 0 < numFonts
fontList = fontList[0...-1]
end
fontList += "]}'";
puts fontList

######
# get the list of field codes that are used
######

fieldCodeData = fieldCodeList.split(',')
fcList = FieldCodeList.new
parsedMessage["fieldCodeList"].each do |fieldCode|
   stm = db.prepare "SELECT Name, Description, Length, CurrentValue from fieldcodes WHERE Name= ?;"
   stm.bind_param 1, fieldCode
   rs = stm.execute
   row = rs.next

   #######
   # replace field code values with those supplied on the command line
   #######
   fieldCodeData.each do |fc|
      fcName = fc.partition('=').first
      fcValue = fc.partition('=').last
      if 0 == row[0].casecmp(fcName)
         row[3] = fcValue
      end
   end

   fcList.addFieldCode( FieldCode.new(row[0], row[1], row[2], row[3]));
end
#####
## generate a JSON string
## escape the embedded quotes
#####
fieldCodeList = fcList.to_json.to_s.gsub(/"/,'\"')
#puts fieldCodeList
#####
# invoke the javascript exportThisMessage function
#####
#puts fontList
bitmapObjectString = context.eval('exportThisMessage("'+messageString+'",'+fontList+',"'+fieldCodeList+'")')
puts bitmapObjectString

bitmapObject = JSON.parse(bitmapObjectString)

graphicType = bitmapObject["graphicType"];

 setter = NTCIPAccess::NTCIPGraphics.new(:port => udpPort, :host=> ipAddress, :community => communityName)
 i = graphicStartingIndex
 pageNumber = 1
 bitmapObject["bitmaps"].each {|bitmap|
   #####
   # don't send graphic if page is text only
   #####
   if false == parsedMessage["pagesExport"][pageNumber-1]["textOnly"]
     result = setter.set_graphic(imageArray: bitmap, graphicIndex: i, graphicName: messageName+"-P"+pageNumber.to_s)
     puts "set result "+result.to_s
   end
   #####
   # bump the graphic index. It will be used when we send the multi string
   #####
   i = i+1
   pageNumber = pageNumber+1
 }

#####
# produce a MULTI string
# to show each of these pages
# include page timing
#####
multiString = ""
needNP = false
i = graphicStartingIndex
numberOfPages = parsedMessage["pagesExport"].length
puts numberOfPages
parsedMessage["pagesExport"].each {|page|
if true == needNP
   multiString << "[np]"
end
needNP = true

onTime = (page["onTime"].to_f*10).to_i
offTime = (page["offTime"].to_f*10).to_i
if(1 < numberOfPages)
multiString << "[pt"+onTime.to_s+"o"+offTime.to_s+"]"
end
if false == page["textOnly"]
  #####
  # not text only, so tell about the graphic
  #####
  multiString << "[g"+i.to_s+"]"
else
  #####
  #  text only, so add the text to the multi string
  #####
  #####
  # don't send trailing blank lines
  #####
   numLines = page["graphicObjectExport"].size;
   (page["graphicObjectExport"].size-1).downto(0) do |index|
     obj = page["graphicObjectExport"][index]
     if "" == obj["text"]
        numLines -= 1
     end
   end
   
   lineNum = 1
   page["graphicObjectExport"].each {|obj|
     if 1 == lineNum
      #####
      # add page and line justification
      #####
      multiString << "[jp"+page["pageJustification"].to_s+"]"
      multiString << "[jl"+page["lineJustification"].to_s+"]"
     end
     if 1 < lineNum && numLines >= lineNum
        #####
        # add new line
        #####
        multiString << "[nl]"
     end

     #####
     # add the font number
     #####
     if numLines >= lineNum
      multiString << "[fo"+fnnList[(obj["fontName"])].to_s+"]"
     end
      #####
      # now add the text
      #####
      text = obj["text"]

      #####
      ## substitute field code values
      #####
      fcList.list.each do |fc|
         text = text.gsub( FC_DELIM_START+fc.name+FC_DELIM_END, fc.value)
      end

     #####
     ## add this to the multi string
     #####
     multiString << text

     lineNum += 1
   }
end
i = i+1
}
puts multiString

setter = NTCIPAccess::NTCIPMessage.new(:port => udpPort, :host=>ipAddress, :community => communityName)
result = setter.set_message(messageMemoryType: ENUM_dmsMessageMemoryType::CHANGEABLE, messageNumber: messageNumber, messageMultiString: multiString, messageOwner: "Doug2")
  case result
  when :noError
    puts "Success"
    puts "multiString " + setter.messageMultiString.to_s
    puts "owner " + setter.messageOwner.to_s
    puts "beacon " + setter.messageBeacon.to_s
    puts "CRC " + setter.messageCRC.to_s
    puts "pixelService " + setter.messagePixelService.to_s
    puts "runTimePriority " + setter.messageRunTimePriority.to_s
    puts "status " + setter.messageStatus.to_s
  when :failure
    puts "Failure"
  else
   puts "result "+result.to_s
  end
  activateResult = setter.activate_message()
  puts "after activate " + activateResult[0].to_s + " " + activateResult[1].to_s + " " + activateResult[2].to_s

puts makePNGFile
if 0 == makePNGFile.casecmp('yes')
puts "2"
bitsPerPixel = 1
if 2 < parsedMessage["allowedColors"].length
bitsPerPixel = 2
end
   #####
   ## produce .png image files
   ## scaled x 3
   #####
pfn = PNGFromNTCIP.new(signWidth, signHeight, bitsPerPixel, 3, bitmapObjectString, messageName)
pfn.toPNG
end
end
