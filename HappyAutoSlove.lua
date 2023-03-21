-- Author      : hpsnk

-- [防脚本检测]请在聊天频道回答以下问题的答案:333+444=? ,剩余回答时间为:300秒，超时会被强制下线，连续多次超时会被封号。

-- local testMsg1 = "|cff3DAEFF[防脚本检测]请在聊天频道回答以下问题的答案:|cffFFD800"
local testMsg1              = "[防脚本检测]请在聊天频道回答以下问题的答案:"
local testMsg2              = "=? ,剩余回答时间为:300秒，超时会被强制下线，连续多次超时会被封号。"

-------------------------------------------------------
LOGGER                      = {}
TARGET_MSG_1                = "防脚本检测"
TARGET_MSG_2                = "请在聊天频道回答以下问题的答案"
TARGET_MSG_3                = "剩余回答时间"
TARGET_MSG_4                = "请在聊天频道回答以下问题的答案:|cffFFD800"

LOG_SIZE                    = 5

HAS_ACTIVE_FLAG             = true;
TRACE_FLAG                  = false;

HappyAutoSloveDataPerCharDB = {}
-------------------------------------------------------

local HAS_frame             = CreateFrame("frame", nil, UIParent)

SLASH_HAS1                  = "/has";
-- SLASH_HAS2                  = "/happyar";
SlashCmdList["HAS"]         = function(msg)
	local cmd, arg = string.split(" ", msg, 2);
	cmd = cmd:lower()

	if cmd == "on" then
		HAS_ACTIVE_FLAG = true;
		HappyAutoSloveDataPerCharDB.active = true;
		print("[HappyAutoSlove]Active=" .. tostring(HAS_ACTIVE_FLAG) .. ".");
	elseif cmd == "off" then
		HAS_ACTIVE_FLAG = false;
		HappyAutoSloveDataPerCharDB.active = false;
		print("[HappyAutoSlove]Active=" .. tostring(HAS_ACTIVE_FLAG) .. ".");
	elseif cmd == "trace" then
		if TRACE_FLAG then
			TRACE_FLAG = false;
			HappyAutoSloveDataPerCharDB.trace = false;
		else
			TRACE_FLAG = true;
			HappyAutoSloveDataPerCharDB.trace = true;
		end
		print("[HappyAutoSlove]Trace=" .. tostring(TRACE_FLAG) .. ".");
	elseif cmd == "log" then
		HAS_dumpLog();
	elseif cmd == "dump" then
		HAS_dumpAllFrame();
	elseif cmd == "" then
		print("/har cmd");
		print("---->on    - 开启自动回答验证功能")
		print("---->off   - 关闭自动回答验证功能")
		print("---->trace - switch trace flag.")
		print("---->log   - dislpay all logs.")
		print("---->dump  - dump all frame.")
		print("[HappyAutoSlove]Active=" .. tostring(HAS_ACTIVE_FLAG) .. ".");
		print("[HappyAutoSlove]Trace =" .. tostring(TRACE_FLAG) .. ".");
	else
		SendChatMessage(testMsg1 .. cmd .. testMsg2);
	end
end

function HAS_EventHandler(self, event, ...)
	LOGGER.trace("receive event= " .. event .. ".");

	if event == "CHAT_MSG_SAY" then
		local msg, sendPlayerName = ...;
		LOGGER.trace("receive SAY message. msg=" .. msg .. ".");
		if HAS_checkTargetMessage(msg) then
			LOGGER.debug("---->check this message from " .. sendPlayerName .. ".");
			HAS_sloveQuestion(msg);
			HAS_saveLog("CHAT_MSG_SAY", sendPlayerName, msg);
		end
	elseif event == "CHAT_MSG_SYSTEM" then
		local msg = ...;
		LOGGER.trace("receive SYSTEM message. msg=" .. msg .. ".");
		if HAS_checkTargetMessage(msg) then
			LOGGER.debug("---->check this message!");
			HAF_closeQuestionFrame();
			HAS_sloveQuestion(msg);
			HAS_saveLog("CHAT_MSG_SYSTEM", "SYSTEM", msg);
		end
	end
end

function LOGGER.debug(msg)
	print("[har][debug]" .. msg);
end

function LOGGER.trace(msg)
	if TRACE_FLAG then
		print("[har][trace]" .. msg);
	end
end

function HAS_checkTargetMessage(msg)
	msg = string.upper(msg);
	if (string.find(msg, TARGET_MSG_1) and string.find(msg, TARGET_MSG_2)) then
		return true;
	end
	return false;
end

function HAS_sloveQuestion(msg)
	local posA1, posA2
	if (string.find(msg, TARGET_MSG_4)) then
		posA1, posA2 = string.find(msg, TARGET_MSG_4);
		posA2 = posA2 + 1;
	else
		posA1, posA2 = string.find(msg, TARGET_MSG_2);
		posA2 = posA2 + 2;
	end

	local posB1 = string.find(msg, "=", posA2)

	-- start pos = find + 2 (skip fullspace character and :)
	-- end   pos = find - 1 (skip =)
	local subString = string.sub(msg, posA2, posB1 - 1)
	LOGGER.debug(">" .. subString .. "<");

	local val1, operate, val2 = string.match(subString, "(%d+)([%+%-%*/])(%d+)")

	LOGGER.debug(val1);
	LOGGER.debug(operate);
	LOGGER.debug(val2);

	local numberVal1 = tonumber(val1)
	local numberVal2 = tonumber(val2)

	local numberAnswer
	if operate == "+" then
		numberAnswer = numberVal1 + numberVal2
	elseif operate == "-" then
		numberAnswer = numberVal1 - numberVal2
	elseif operate == "*" then
		numberAnswer = numberVal1 * numberVal2
	elseif operate == "/" then
		numberAnswer = numberVal1 / numberVal2
	end

	LOGGER.debug("=");
	LOGGER.debug(numberAnswer);

	if HAS_ACTIVE_FLAG then
		SendChatMessage(tostring(numberAnswer));
	end
end

function HAS_dumpLog()
	LOGGER.trace("dump logs.")

	local logSize = #HappyAutoSloveDataPerCharDB.log;
	for i = 1, logSize, 1 do
		local log = HappyAutoSloveDataPerCharDB.log[i];
		LOGGER.debug("idx=" ..
			i ..
			", datetime=" ..
			log.datetime .. ", event=" .. log.event .. ", sender=" .. log.sender .. ", text=" .. log.text);
	end
end

function HAS_saveLog(event, sender, msg)
	if HappyAutoSloveDataPerCharDB.log == nil then
		HappyAutoSloveDataPerCharDB.log = {}
	end
	local checkMsg = {};
	checkMsg.datetime = date();
	checkMsg.event = event;
	checkMsg.sender = sender;
	checkMsg.text = msg;

	local logSize = #HappyAutoSloveDataPerCharDB.log;
	if (logSize > LOG_SIZE) then
		for i = 1, LOG_SIZE-1, 1 do
			HappyAutoSloveDataPerCharDB.log[i] = HappyAutoSloveDataPerCharDB.log[i+1];
		end
		HappyAutoSloveDataPerCharDB.log[LOG_SIZE] = checkMsg;
	else
		local idx = logSize + 1
		HappyAutoSloveDataPerCharDB.log[idx] = checkMsg;
	end
end

function HAS_dumpAllFrame()
	for i = 1, STATICPOPUP_NUMDIALOGS do
		local frame = _G["StaticPopup" .. i]

		LOGGER.debug(i);

		local frameName = frame.which;

		if frameName == nil then
			frameName = "null";
			-- LOGGER.debug( frameName .. ", visable:" .. valFrame:IsVisible() );
			LOGGER.debug(frameName .. ", visable:false");
		else
			LOGGER.debug(frameName .. ", visable:" .. frame:IsVisible());
			LOGGER.debug("  close it!");
			StaticPopup_OnClick(frame, 1)
		end
	end
end

function HAF_closeQuestionFrame()
	for i = 1, STATICPOPUP_NUMDIALOGS do
		local frame = _G["StaticPopup" .. i]
		if (frame:IsVisible() and frame.which == "GOSSIP_") then
			StaticPopup_OnClick(frame, 1);
		end
	end
end

-- register event handler
HAS_frame:SetScript("OnEvent", HAS_EventHandler);

HAS_frame:RegisterEvent("CHAT_MSG_SAY");
HAS_frame:RegisterEvent("CHAT_MSG_SYSTEM");

print("HappyAutoSlove Load complete!");
