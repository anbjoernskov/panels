import 'CoreLibs/ui/gridview.lua'

local gfx <const> = playdate.graphics

local ScreenWidth <const> = playdate.display.getWidth()
local ScreenHeight <const> = playdate.display.getHeight()

local selectionSound = playdate.sound.sampleplayer.new(Panels.Settings.path .. "assets/audio/selection.wav")
local selectionRevSound = playdate.sound.sampleplayer.new(Panels.Settings.path .. "assets/audio/selection-reverse.wav")
local denialSound = playdate.sound.sampleplayer.new(Panels.Settings.path .. "assets/audio/denial.wav")
local confirmSound = playdate.sound.sampleplayer.new(Panels.Settings.path .. "assets/audio/confirm.wav")

local hideSound = playdate.sound.sampleplayer.new(Panels.Settings.path .. "assets/audio/swish-out.wav")
local showSound = playdate.sound.sampleplayer.new(Panels.Settings.path .. "assets/audio/swish-in.wav")

local headerFont = gfx.getSystemFont("bold")
-- local listFont = Panels.Font.get(Panels.Settings.path .. "assets/fonts/Asheville-Narrow-14-Bold")--gfx.getSystemFont()

local listFont = gfx.getSystemFont()

Panels.Menu = {}

-- -------------------------------------------------
-- GENERIC MENU

local menuAnimationDuration <const> = 200

local MenuState = {
	SHOWING = 0,
	OPEN = 1,
	HIDING = 2,
	CLOSED = 3
}

function Panels.Menu.new(height, redrawContent, inputHandlers)
	local menu = {}
	
	menu.animator = nil
	menu.state = MenuState.CLOSED
	menu.isFullScreen = false
	menu.onWillShow = nil
	menu.onDidShow = nil
	menu.onDidHide = nil
	
	local function drawBG(yPos)
		gfx.setColor(Panels.Color.WHITE)
		gfx.fillRoundRect(0, yPos, 400, ScreenHeight + 5, 4)
		
	end
	
	local function drawOutline(yPos)
		gfx.setColor(Panels.Color.BLACK)
		gfx.setLineWidth(2)
		gfx.drawRoundRect(0, yPos, 400, ScreenHeight + 5, 4)
	end
	
	function menu:show()
		if self.state == MenuState.SHOWING or self.state == MenuState.OPEN then
			return
		end
		
		if self.onWillShow then self:onWillShow() end
		Panels.onMenuWillShow(self)
		self.state = MenuState.SHOWING
		playdate.inputHandlers.push(inputHandlers, true)
		self.animator = gfx.animator.new(menuAnimationDuration, 0, 1, playdate.easingFunctions.inOutQuad)

		if Panels.Settings.playMenuSounds then
			if self ~= Panels.mainMenu  then
				showSound:play()
			end
		end
	end
	
	function menu:hide()
		if self.state == MenuState.HIDING or self.state == MenuState.CLOSED then
			return 
		end
		Panels.onMenuWillHide(self)
		self.state = MenuState.HIDING
		playdate.inputHandlers.pop()
		self.animator = gfx.animator.new(menuAnimationDuration, 1, 0, playdate.easingFunctions.inOutQuad)

		if Panels.Settings.playMenuSounds then
			hideSound:play()
		end
	end
	
	function menu:isActive()
		return self.state ~= MenuState.CLOSED 
	end
	
	function menu:updateState()
		if self.animator:ended() then
			if self.state == MenuState.SHOWING then
				self.state = MenuState.OPEN
				Panels.onMenuDidShow(self)
				if self.onDidShow then self:onDidShow() end
			elseif self.state == MenuState.HIDING then
				self.state = MenuState.CLOSED
				Panels.onMenuDidHide(self)
			end
		end
	end
	
	function menu:update()		
		local animatorVal = self.animator:currentValue()
		local yPos = ScreenHeight - animatorVal * height
		
		if yPos < ScreenHeight then
			drawBG(yPos)
			redrawContent(yPos)
			drawOutline(yPos)
		end
		
		self:updateState()
	end
	
	return menu
end


-- -------------------------------------------------
-- MAIN MENU

local mainMenuList = nil
local menuOptions = { "Start Over" }
local mainMenuImage = nil

local function displayMenuImage(val)
	local y = 240 - (val * ScreenHeight)
	mainMenuImage:drawFaded(0, 0, val, gfx.image.kDitherTypeBayer8x8)
end

local function loadMenuImage()
	img, error = gfx.image.new(Panels.Settings.imageFolder .. Panels.Settings.menuImage)
	printError(error, "Error loading main menu image:")
	
	if img == nil then 
		img = gfx.image.new(ScreenWidth, ScreenHeight, Panels.Color.WHITE)
	end
	return img
end

local function redrawMainMenu(yPos)
	mainMenuList:drawInRect(8, yPos + 3, 384, 42)
end
local mainOffset = 0
local function updateMainMenu(gameDidFinish, gameDidStart)
	menuOptions = { "Start Over" }

	if Panels.Settings.useChapterMenu then
		menuOptions[#menuOptions+1] = "Chapters"
	end

	if not gameDidFinish then
		if gameDidStart then
			menuOptions[#menuOptions+1] = "Resume"
		else
			menuOptions[#menuOptions+1] = "Start"
		end
	end

	mainMenuList = playdate.ui.gridview.new(math.floor((ScreenWidth - 16) / #menuOptions) - 8, 32)
	mainMenuList:setNumberOfRows(1)
	mainMenuList:setNumberOfColumns(#menuOptions)
	mainMenuList:setCellPadding(4, 4, 4, 4)
	mainMenuList:setSelection(1, 1, #menuOptions)

	function mainMenuList:drawCell(section, row, column, selected, x, y, width, height)
		local text = menuOptions[column]
		if selected then
			gfx.setColor(gfx.kColorBlack)
			gfx.fillRoundRect(x + mainOffset, y, width , height, 4)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			text = "*" .. text .. "*"
			mainOffset = 0
		else
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		end
		
		gfx.setFont(listFont)
		gfx.drawTextInRect(text, x, y+8, width, height+2, nil, "...", kTextAlignment.center)
	end
end

function createMainMenu(gameDidFinish, gameDidStart)
	mainMenuImage = loadMenuImage()
	updateMainMenu(gameDidFinish, gameDidStart)

	
	
	local inputHandlers = {
		rightButtonUp = function()
			local s, r, column = mainMenuList:getSelection()
			if Panels.Settings.playMenuSounds then 
				if column == #menuOptions then
					denialSound:play()
				else
					selectionSound:play()
				end
			end
			mainOffset = 4
			mainMenuList:selectNextColumn(false)
		end,
		
		leftButtonUp = function()
			local s, r, column = mainMenuList:getSelection()
			if Panels.Settings.playMenuSounds then 
				if column == 1 then
					denialSound:play()
				else
					selectionRevSound:play()
				end
			end
			mainOffset = -4
			mainMenuList:selectPreviousColumn(false)
		end,
		
		AButtonDown = function()
			local s, r, column = mainMenuList:getSelection()
			local label

			if Panels.Settings.playMenuSounds then
				confirmSound:play()
			end

			if column == #menuOptions and not gameDidFinish then  -- Continue
				Panels.mainMenu:hide()
			elseif column == 1 then         -- Start Over
				Panels.onMenuDidStartOver()
			elseif Panels.Settings.useChapterMenu then                           -- Chapters
				Panels.chapterMenu:show()
			end	
		end,
	}
	
	local menu = Panels.Menu.new(45, redrawMainMenu, inputHandlers)
	return menu
end


-- -------------------------------------------------
-- CHAPTER MENU

local chapterList = playdate.ui.gridview.new(0, 32)
local headerImage = nil
local maxUnlockedChapter = 0

local function createSectionsFromData(data)
	sections = {}
	maxUnlockedChapter = 0
	for i, seq in ipairs(data) do
		if (seq.title or Panels.Settings.listUnnamedSequences) 
		and (Panels.unlockedSequences[i] == true or Panels.Settings.listLockedSequences) then
			local title = seq.title or "--"
			if Panels.unlockedSequences[i] == true then 
				title = "*" .. title .. "*" 
				maxUnlockedChapter = maxUnlockedChapter + 1
			end
			sections[#sections + 1] = {title = title, index = i}
		end
	end
end

local function redrawChapterMenu(yPos)
	chapterList:drawInRect(13, yPos +1, 374, 240)
end

local function onChapterMenuWillShow() 
	chapterList:setSelectedRow(1)
	chapterList:selectPreviousRow()
end

local function updateChapterMenu(data)
	createSectionsFromData(data)
	chapterList:setNumberOfRows(#sections)
end

local function isLastUnlockedSequence(index)
	for i = index + 1, #Panels.unlockedSequences, 1 do
	if i > #sections then return true end
		local sectionIndex = sections[i].index
		if Panels.unlockedSequences[sectionIndex] == true then
			return false
		end
	end
	return true
end

local function isFirstUnlockedSequence(index)
	for i = index - 1, 1, -1 do
		local sectionIndex = sections[i].index
		if Panels.unlockedSequences[sectionIndex] == true then
			return false
		end
	end
	return true
end

local function getNextUnlockedSequence(index)
	for i = index + 1, #Panels.unlockedSequences, 1 do
		local sectionIndex = sections[i].index
		if Panels.unlockedSequences[sectionIndex] == true then
			return i
		end
	end
	return nil
end

local function getPreviousUnlockedSequence(index)
	for i = index - 1, 1, -1 do
		local sectionIndex = sections[i].index
		if Panels.unlockedSequences[sectionIndex] == true then
			return i
		end
	end
	return nil
end

local function getRowForSequenceIndex(index)
	for i, sec in ipairs(sections) do
		if sec.index == index then
			return i
		end
	end
	return nil
end

local chapterOffset = 0
local function createChapterMenu(data)
	updateChapterMenu(data)
	
	if Panels.Settings.chapterMenuHeaderImage then
		headerImage = gfx.image.new(Panels.Settings.imageFolder .. Panels.Settings.chapterMenuHeaderImage)
		local w, h = headerImage:getSize()
		chapterList:setSectionHeaderHeight(h + 24)
	else 
		chapterList:setSectionHeaderHeight(48)
	end
	chapterList:setCellPadding(0, 0, 0, 8)
	
	local inputHandlers = {
		downButtonUp = function()
			chapterOffset = 4
			local selectedRow = chapterList:getSelectedRow()
			if not isLastUnlockedSequence(selectedRow) then
				local next = getNextUnlockedSequence(selectedRow)
				chapterList:setSelectedRow(next)
				chapterList:scrollToRow(next)
				if Panels.Settings.playMenuSounds then 
					selectionSound:play()
				end
			else
				if Panels.Settings.playMenuSounds then 
					denialSound:play()
				end
			end
		end,
		
		upButtonUp = function()
			chapterOffset = -4
			local selectedRow = chapterList:getSelectedRow()
			if not isFirstUnlockedSequence(selectedRow) then
				local prev = getPreviousUnlockedSequence(selectedRow)
				chapterList:setSelectedRow(prev)
				chapterList:scrollToRow(prev)
				if Panels.Settings.playMenuSounds then 
					selectionRevSound:play()
				end
			else
				if Panels.Settings.playMenuSounds then 
					denialSound:play()
				end
			end
			
		end,
		
		AButtonDown = function()
			local item = sections[chapterList:getSelectedRow()] 
			Panels.onChapterSelected( item.index )
			Panels.chapterMenu:hide()
			if Panels.mainMenu then Panels.mainMenu:hide() end
			if Panels.Settings.playMenuSounds then
				confirmSound:play()
			end
		end,
		
		BButtonDown = function()
			Panels.chapterMenu:hide()
		end
	}
	
	local menu = Panels.Menu.new(ScreenHeight, redrawChapterMenu, inputHandlers)
	menu.onWillShow = onChapterMenuWillShow
	return menu
end

function chapterList:drawCell(section, row, column, selected, x, y, width, height)
		if selected then
			gfx.setColor(gfx.kColorBlack)
			gfx.fillRoundRect(x, y + chapterOffset, width, height, 4)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			chapterOffset = 0
		else
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		end
		
		gfx.setFont(listFont)
		gfx.drawTextInRect("" .. sections[row].title.. "", x + 16, y+8, width -32, height+2, nil, "...", kTextAlignment.left)
end

function chapterList:drawSectionHeader(section, x, y, width, height)
	if Panels.Settings.chapterMenuHeaderImage then
		headerImage:drawAnchored(x + width / 2, y + 7, 0.5, 0)
	else
		gfx.setColor(gfx.kColorBlack)
		gfx.setFont(headerFont)
		gfx.drawTextInRect("Chapters", x, y+12, width, height, nil, "...", kTextAlignment.center)
		gfx.setLineWidth(1)
		gfx.drawLine(x, y + 20, x + 120, y + 20)
		gfx.drawLine(x + width - 120, y + 20, x + width, y + 20)
	end
end


-- -------------------------------------------------
-- CREDITS MENU

local credits = nil

local function redrawCreditsMenu(yPos)
	credits:redraw(yPos)
end

local function onCreditsMenuWillShow()
	credits.scrollPos = 0
end

local function onCreditsMenuDidShow()
	credits:onDidShow()
end

local function createCreditsMenu()
	credits = Panels.Credits.new()
	
	local inputHandlers = {
		BButtonDown = function()
			Panels.creditsMenu:hide()
		end,
		cranked = function(change)
			credits:cranked(change)
		end,
	}
	
	local menu = Panels.Menu.new(ScreenHeight, redrawCreditsMenu, inputHandlers)
	menu.onWillShow = onCreditsMenuWillShow
	menu.onDidShow = onCreditsMenuDidShow
	return menu
end

-- HINTS MENU

-- make hint box
Panels.HintBox = {}
local hintBox = gfx.image.new(400,240)
local displayHintBox = false

local function updateHintBox(item)
	gfx.pushContext(hintBox)
	gfx.setColor(Panels.Color.WHITE)
	gfx.fillRoundRect(50, 20, 300, 200, 4)
	if item.image then
		gfx.setClipRect(50, 20, 300, 200)
		local hintBoxImage = gfx.image.new(Panels.Settings.imageFolder .. item.image)
		hintBoxImage:drawAnchored(200, 120, 0.5, 0.5)
		gfx.clearClipRect()
	else
		gfx.drawTextInRect(item, 60, 70, 300, 200, nil, "...", kTextAlignment.left)
	end
	gfx.setColor(Panels.Color.BLACK)
	gfx.setLineWidth(2)
	gfx.drawRoundRect(50, 20, 300, 200, 4)
	gfx.popContext()
end

local hintsList = playdate.ui.gridview.new(0, 32)
local sequenceHints = nil
local selectedSequenceHints = {}

local function redrawHintsMenu(yPos)
	hintsList:drawInRect(13, yPos +1, 374, 240)
	if displayHintBox then
		hintBox:drawAnchored(200, 120, 0.5, 0.5)
	end
end

local function onHintsMenuWillShow() 
	hintsList:setSelectedRow(1)
	hintsList:selectPreviousRow()
	if next(selectedSequenceHints) == nil then
		hintsList:setNumberOfRows(1) -- just show the empty message
	else
		hintsList:setNumberOfRows(#selectedSequenceHints)
	end
	displayHintBox = false
end

function updateHintsMenu(selectedSequence)
	selectedSequenceHints = {}
	if sequenceHints ~= nil then
		for i, h in ipairs(sequenceHints[selectedSequence]) do
			table.insert(selectedSequenceHints, h)
		end
	end
end

local function createHintsMenu(sequences)
	hintsList:setSectionHeaderHeight(48)
	hintsList:setCellPadding(0, 0, 0, 8)

	sequenceHints = {}
	for i, seq in ipairs(sequences) do
		if seq.hints then
			sequenceHints[i] = seq.hints
		else
			sequenceHints[i] = {}
		end
	end
	
	local inputHandlers = {
		downButtonUp = function()
			if displayHintBox == false then
				hintsList:selectNextRow(false)
				if Panels.Settings.playMenuSounds then 
					selectionSound:play()
				end
			end
		end,
		
		upButtonUp = function()
			if displayHintBox == false then
				if Panels.Settings.playMenuSounds then 
					if hintsList:getSelectedRow() > 1 then 
						selectionRevSound:play()
					else
						denialSound:play()
					end
				end
				hintsList:selectPreviousRow(false)
			end
		end,
		
		AButtonDown = function()
			local item = selectedSequenceHints[hintsList:getSelectedRow()] 
			if item == nil then
				if Panels.Settings.playMenuSounds then
					denialSound:play()
				end
			else
				-- make a box and display the hint text
				updateHintBox(item)
				displayHintBox = true
				if Panels.Settings.playMenuSounds then
					confirmSound:play()
				end
			end
		end,
		
		BButtonDown = function()
			if displayHintBox == true then
				displayHintBox = false
			else
				Panels.hintsMenu:hide()
			end
		end
	}
	
	local menu = Panels.Menu.new(ScreenHeight, redrawHintsMenu, inputHandlers)
	menu.onWillShow = onHintsMenuWillShow
	return menu
end

function hintsList:drawCell(section, row, column, selected, x, y, width, height)
		if selected then
			gfx.setColor(gfx.kColorBlack)
			gfx.fillRoundRect(x, y + chapterOffset, width, height, 4)
			-- gfx.drawRoundRect(x + 1, y, width - 2, height, 4)
			gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
			chapterOffset = 0
		else
			gfx.setImageDrawMode(gfx.kDrawModeCopy)
		end
		
		gfx.setFont(listFont)
		if next(selectedSequenceHints) ~= nil then
			if selectedSequenceHints[row].image ~= nil then
				gfx.drawTextInRect("Answer", x + 16, y+8, width -32, height+2, nil, "...", kTextAlignment.left)	
			else
				gfx.drawTextInRect("Hint " .. row .. "", x + 16, y+8, width -32, height+2, nil, "...", kTextAlignment.left)
			end
		else
			gfx.drawTextInRect("No hints for this chapter", x + 16, y+8, width -32, height+2, nil, "...", kTextAlignment.left)
		end

end

function hintsList:drawSectionHeader(section, x, y, width, height)
		gfx.setColor(gfx.kColorBlack)
		gfx.setFont(headerFont)
		gfx.drawTextInRect("Hints", x, y+12, width, height, nil, "...", kTextAlignment.center)
		gfx.setLineWidth(1)
		gfx.drawLine(x, y + 20, x + 120, y + 20)
		gfx.drawLine(x + width - 120, y + 20, x + width, y + 20)
end

-- -------------------------------------------------
-- ALL MENUS

function updateMenus()	
	if Panels.mainMenu and Panels.mainMenu:isActive() then 
		local val = Panels.mainMenu.animator:currentValue()
		displayMenuImage(val)	
		Panels.mainMenu:update() 
	end
	
	if Panels.chapterMenu and Panels.chapterMenu:isActive() then
		Panels.chapterMenu:update()
	end
	
	if Panels.creditsMenu:isActive() then 
		Panels.creditsMenu:update()
	end

	if Panels.hintsMenu:isActive() then
		Panels.hintsMenu:update()
	end
end

function createMenus(sequences, gameDidFinish, gameDidStart)
	Panels.mainMenu = createMainMenu(gameDidFinish, gameDidStart)

	if Panels.Settings.useChapterMenu then 
		Panels.chapterMenu = createChapterMenu(sequences)
	end

	Panels.creditsMenu = createCreditsMenu()

	Panels.hintsMenu = createHintsMenu(sequences)
end


function updateMenuData(sequences, gameDidFinish, gameDidStart)
	-- updateMainMenu(gameDidFinish, gameDidStart)
	-- just recreate the damn thing so the inputHandlers have the right state
	Panels.mainMenu = createMainMenu(gameDidFinish, gameDidStart) 
	updateChapterMenu(sequences)
end