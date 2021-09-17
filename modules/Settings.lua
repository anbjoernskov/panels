Panels.Settings = {
	-- path settings
	path = "libraries/panels/",
	imageFolder = "images/",
	audioFolder = "audio/",
	
	-- panel settings
	defaultFrame = {gap = 50, margin = 8},
	snapToPanels = true,
	sequenceTransitionDuration = 750,
	defaultFont = nil,
	borderWidth = 2,
	borderRadius = 2,
	
	-- menu settings
	menuImage = "menuImage.png",
	listUnnamedSequences = true,
	listLockedSequences = true,
	chapterMenuHeaderImage = nil,
	useChapterMenu = false,
	showMenuOnLaunch = true,
	skipMenuOnFirstLaunch = true,
}

local function addSlashToFolderName(f)
	if string.sub(f, -1) ~= "/" then
		f = f .. "/"
	end
	return f
end

function validateSettings() 
	local s = Panels.Settings
	s.imageFolder = addSlashToFolderName(s.imageFolder)
	s.audioFolder = addSlashToFolderName(s.audioFolder)
	s.path = addSlashToFolderName(s.path)
end

