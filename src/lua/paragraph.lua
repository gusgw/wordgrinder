-- © 2023 David Given.
-- WordGrinder is licensed under the MIT open source license. See the COPYING
-- file in this distribution for the full text.

local table_remove = table.remove
local table_insert = table.insert
local table_concat = table.concat
local Write = wg.write
local WriteStyled = wg.writestyled
local ClearToEOL = wg.cleartoeol
local SetNormal = wg.setnormal
local SetBold = wg.setbold
local SetUnderline = wg.setunderline
local SetReverse = wg.setreverse
local SetDim = wg.setdim
local GetStringWidth = wg.getstringwidth
local GetBytesOfCharacter = wg.getbytesofcharacter
local GetWordText = wg.getwordtext
local BOLD = wg.BOLD
local ITALIC = wg.ITALIC
local UNDERLINE = wg.UNDERLINE
local REVERSE = wg.REVERSE
local BRIGHT = wg.BRIGHT
local DIM = wg.DIM

local Paragraph = {}
Paragraph.__index = Paragraph
_G.Paragraph = Paragraph

type Line = {[number]: string, wn: number}

type Paragraph = {
	[number]: string,
	__iter: (self: Paragraph) -> (any, any, number),

	number: number,
	style: string,
	wrapwidth: number?,
	sentences: {[number]: boolean}?,
	lines: {{[number]: number, wn: number}}?,
	xs: {number}?,

	copy: (self: Paragraph) -> Paragraph,
	touch: (self: Paragraph) -> (),
	wrap: (self: Paragraph, width: number?) -> {Line},
	renderLine: (self: Paragraph, line: Line, x: number, y: number) -> (),
	renderMarkedLine: (self: Paragraph,
		line: Line, x: number, y: number, width: number, pn: number) -> (),
	getLineOfWord: (self: Paragraph, wn: number) -> (number?, number?),
	getIndentOfLine: (self: Paragraph, ln: number) -> number,
	getWordOfLine: (self: Paragraph, ln:number ) -> number,
	getXOffsetOfWord: (self: Paragraph, wn: number) -> number,
	sub: (self: Paragraph, start: number, count: number?) -> {string},
	asString: (self: Paragraph) -> string,
}

function Paragraph.__iter(self: Paragraph)
	local function iter(a: {string}, i: number): (number?, string?)
      i = i + 1
      local v = a[i]
      if v then
        return i, v
      end
	  return nil, nil
    end

	return iter, self, 0
end

function CreateParagraph(style: string, ...: ({string}|string)): Paragraph
	if type(style) ~= "string" then
		error("paragraph style is not a string")
	end
	local words = {
		style = style
	}

	for _, t in ipairs({...}) do
		if type(t) == "table" then
			for _, w in ipairs(t) do
				words[#words+1] = w
			end
		elseif type(t) == "string" then
			words[#words+1] = t
		end
	end

	return (setmetatable(words, Paragraph)::any) :: Paragraph
end

function Paragraph.copy(self: Paragraph): Paragraph
	local words: {string} = {}

	for _, w in self do
		words[#words+1] = w
	end

	return CreateParagraph(self.style, words)
end

function Paragraph.touch(self: Paragraph)
	self.lines = nil
	self.wrapwidth = nil
	self.xs = nil
	self.sentences = nil
end

function Paragraph.wrap(self: Paragraph, width: number?): ()
	local sentences = self.sentences
	if (sentences == nil) then
		local issentence = true
		sentences = {}
		assert(sentences)
		for wn, word in self do
			if issentence then
				sentences[wn] = true
				issentence = false
			end

			if word:find("[^%a]$") then
				issentence = true
			end
		end
		sentences[#self] = true
		self.sentences = sentences
	end

	width = width or currentDocument.wrapwidth
	assert(width)
	if (self.wrapwidth ~= width) then
		local lines = {}
		local line = {wn = 1}
		local w = 0
		local xs = {}
		local fullstopspaces = WantFullStopSpaces()
		self.xs = xs

		width = width - self:getIndentOfLine(1)

		for wn, word in ipairs(self) do
			-- get width of word (including space)
			local ww = GetStringWidth(word) + 1

			-- add an extra space if the user asked for it
			if fullstopspaces and word:find("%.$") then
				ww = ww + 1
			end

			xs[wn] = w
			w = w + ww
			if (w >= width) then
				lines[#lines+1] = line
				if #lines == 1 then
					width = width + self:getIndentOfLine(1) - self:getIndentOfLine(2)
				end
				line = {wn = wn}
				w = ww
				xs[wn] = 0
			end

			line[#line+1] = wn
		end

		if (#line > 0) then
			lines[#lines+1] = line
		end

		self.lines = lines
	end

	return self.lines
end

function Paragraph.renderLine(self: Paragraph, line, x: number, y: number): ()
	local cstyle = stylemarkup[self.style] or 0
	local ostyle = 0
	local xs = self.xs

	for _, wn in ipairs(line) do
		local w = self[wn]

		local payload = {
			word = w,
			ostyle = ostyle,
			cstyle = cstyle,
			firstword = assert(self.sentences)[wn]
		}
		FireEvent("DrawWord", payload)

		ostyle = WriteStyled(
			x+assert(xs)[wn], y,
			payload.word,
			payload.ostyle, 0, 0, payload.cstyle)
	end
end

function Paragraph.renderMarkedLine(self: Paragraph, line, x, y, width, pn): ()
	width = width or (ScreenWidth - x)

	local lwn: number = line.wn
	local mp1, mw1, mo1, mp2, mw2, mo2 = currentDocument:getMarks()

	local cstyle = stylemarkup[self.style] or 0
	local ostyle = 0
	for wn, w in ipairs(line) do
		local s, e

		wn = lwn + wn - 1

		if (pn < mp1) or (pn > mp2) then
			s = 0
		elseif (pn > mp1) and (pn < mp2) then
			s = 1
		else
			if (pn == mp1) and (pn == mp2) then
				if (wn == mw1) and (wn == mw2) then
					s = mo1
					e = mo2
				elseif (wn == mw1) then
					s = mo1
				elseif (wn == mw2) then
					s = 1
					e = mo2
				elseif (wn > mw1) and (wn < mw2) then
					s = 1
				end
			elseif (pn == mp1) then
				if (wn > mw1) then
					s = 1
				elseif (wn == mw1) then
					s = mo1
				end
			else
				s = 1
				if (wn > mw2) then
					s = 0
				elseif (wn == mw2) then
					e = mo2
				end
			end
		end

		local payload = {
			word = self[w],
			ostyle = ostyle,
			cstyle = cstyle,
			firstword = assert(self.sentences)[wn]
		}
		FireEvent("DrawWord", payload)

		ostyle = WriteStyled(x+assert(self.xs)[w], y, payload.word,
			payload.ostyle, s, e, payload.cstyle)
	end
end

-- returns: line number, word number in line
function Paragraph.getLineOfWord(self: Paragraph, wn: number): (number?, number?)
	local lines = self:wrap()
	for ln, l in ipairs(lines) do
		if (wn <= #l) then
			return ln, wn
		end

		wn = wn - #l
	end

	return nil, nil
end

-- returns: number of characters
function Paragraph.getIndentOfLine(self: Paragraph, ln: number): number
	local indent
	if (ln == 1) then
		indent = documentStyles[self.style].firstindent
	end
	indent = indent or documentStyles[self.style].indent or 0
	return indent
end

-- returns: word number
function Paragraph.getWordOfLine(self: Paragraph, ln:number ): number
	local lines = self:wrap()
	return lines[ln].wn
end

-- returns: X offset, line number, word number in line
function Paragraph.getXOffsetOfWord(self: Paragraph, wn: number):
		(number, number, number)
	local lines = self:wrap()
	local x = assert(self.xs)[wn]
	local ln, wn = self:getLineOfWord(wn)
	return x, assert(ln), assert(wn)
end

function Paragraph.sub(self: Paragraph, start: number, count: number?): {string}
	if not count then
		count = #self - start + 1
	else
		count = min(count, #self - start + 1)
	end
	assert(count)

	local t = {}
	for i = start, start+count-1 do
		t[#t+1] = self[i]
	end
	return t
end

-- return an unstyled string containing the contents of the paragraph.
function Paragraph.asString(self: Paragraph): string
	local s = {}
	for _, w in self do
		s[#s+1] = GetWordText(w)
	end

	return table_concat(s, " ")
end
