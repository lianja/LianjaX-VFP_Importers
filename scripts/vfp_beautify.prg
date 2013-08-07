////////////////////////////////////////////////////////////////////////////////
//
//   Copyright 2013 Lianja Inc.
//
////////////////////////////////////////////////////////////////////////////////
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////
//
//   vfp_beautify.prg
//
//   Beautifies Visual FoxPro source code
//
////////////////////////////////////////////////////////////////////////////////

lparameter cFilename

// Declare local variables
private cDir = justpath(cFilename)
private cName = juststem(cFilename)
private cTempfile = tmpnam()
private cBackupname = cDir + cName + ".bak"
private blockKeywords[]
private infp
private outfp

// Initializes the keyword symbol table
procedure initKeywords()
	blockKeyWordsBuild("proc", "4endproc,4return")
	blockKeyWordsBuild("func", "4endfunc,4return")
	blockKeyWordsBuild("procedure", "4endproc,4return,4procedure,4function")
	blockKeyWordsBuild("function", "4endfunc,4return,4procedure,4function")
	blockKeyWordsBuild("4procedure", "4endproc,4return,4procedure,4function")
	blockKeyWordsBuild("4function", "4endfunc,4return,4procedure,4function")
	blockKeyWordsBuild("define", "?")
	blockKeyWordsBuild("define class", "4enddefine")
	blockKeyWordsBuild("if", "else,4elseif,4endif")
	blockKeyWordsBuild("else", "elseif,4endif")
	blockKeyWordsBuild("elseif", "else,elseif,4endif")
	blockKeyWordsBuild("for", "4endfor,next")
	blockKeyWordsBuild("do", "?")
	blockKeyWordsBuild("do while", "4enddo")
	blockKeyWordsBuild("case", "case,4otherwise,4endcase")
	blockKeyWordsBuild("4otherwise", "case,4endcase")
	blockKeyWordsBuild("scan", "4endscan")
	blockKeyWordsBuild("try", "catch,5endtry")
	blockKeyWordsBuild("with", "4endwith")
endproc

function blockKeyWordsBuild()
	lparameters cKey, cWordlist
	local aKeys[1],lnRun, lcKey,lcKeyList, lcWordList
	lcKeyList = blockKeyWordsListBuild(cKey)
	lcWordList = blockKeyWordsListBuild(cWordlist)
	for lnRun = 1 to alines(aKeys,m.lcKeyList)
		lcKey = aKeys[m.lnRun]
		blockKeyWords[m.lcKey] = m.lcWordList
	next
return

function blockKeyWordsListBuild()
	lparameters cWordlist
	local aWordList[1], lcRet, lcWord, lnWords, lnSpellings
	lcRet = ""
	for lnWords = 1 to alines(aWordList,cWordList,5,",")
		lcWord = aWordList[m.lnWords]
		IF isdigit(left(m.lcWord,1))
			for lnSpellings = val(m.lcWord) to len(m.lcWord)-1
				lcRet = lcRet + "," + substr(m.lcWord,2, m.lnSpellings)
			next
		else
			lcRet = lcRet + "," + m.lcWord
		endif
	next
	lcRet = substr(m.lcRet,2)
	if .F. && developer visualize
		? cWordList
		? m.lcRet
	endif
return m.lcRet

// Procedure that recursively handles beautifying code
procedure beautify(cLine, cStartBlock, cEndBlock, depth)
	private cWord
	private cExpr
	private cEnd
	private nEmpty
	
	do while .T.
		cWord = lower(getWordNum(cLine, 1))
		cExpr = "blockKeywords['" + cWord + "']"
		if len(cEndBlock) > 0
			aStore(cEndBlockArray, cEndBlock)
			if in_array(cWord, cEndBlockArray)
				fputs(outfp, replicate(chr(9), depth-1)+cLine)
				if (cWord = "case" or AT(cWord,"otherwise")=1) and ;
					(cStartBlock = "case" or AT(cStartBlock,"otherwise")=1)
					if not feof(infp)
						cLine = alltrim(fgets(infp))
						loop
					else
						return
					endif
				elseif (cWord = "else" or at(cWord,"elseif")=1) and ;
					(cStartBlock = "if")
					if not feof(infp)
						cLine = alltrim(fgets(infp))
						loop
					else
						return
					endif
				elseif (cWord = "catch") and ;
					(cStartBlock = "try")
					if not feof(infp)
						cLine = alltrim(fgets(infp))
						loop
					else
						return
					endif
				else
					return
				endif
			endif
		endif
		
		fputs(outfp, replicate(chr(9), depth)+cLine)
		
		if type(cExpr) != 'U' and not feof(infp)
			cEnd = &cExpr
			if cEnd = "?"
				cWord = cWord + " " + lower(getWordNum(cLine, 2))
				cExpr = "blockKeywords['" + cWord + "']"
				if type(cExpr) = 'U'
					if not feof(infp)
						cLine = alltrim(fgets(infp))
						loop
					else
						return
					endif
				else
					cEnd = &cExpr
				endif
			endif
			beautify(alltrim(fgets(infp)), cWord, cEnd, depth+1)
		endif
		
		if not feof(infp)
			cLine = alltrim(fgets(infp))
		else
			return
		endif
	enddo
endproc

// Initialization
initKeyWords()

// Backup the file
copy file "&cFilename" to "&cBackupname"

// Open the files
infp = fopen(cFilename)
outfp = fcreate(cTempfile)

// Parse the file
do while not feof(infp)
	beautify(alltrim(fgets(infp)), "", "", 0)
enddo

// Close the files
fclose(infp)
fclose(outfp)

// Copy the formatted file to the old
erase "&cFilename"
copy file "&cTempfile" to "&cFilename"
erase "&cTempfile"





























