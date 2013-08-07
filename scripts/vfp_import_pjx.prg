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
//   vfp_import_pjx.prg
//
//   Imports Visual FoxPro .pjx files into a Lianja App
//
////////////////////////////////////////////////////////////////////////////////

lparameter cFile
private cDir = justpath(cFile)
private cAppdir = Lianja.appdir
private nSelect = select()

clear
close pjxfile
? "Importing Visual FoxPro .pjx file '&cFile'"
?? "opening '&cFile'"
use "&cFile" alias pjxfile in 0 current noupdate
? " - ok"

goto top
do while not eof()
	cName = mtos(pjxfile->name)
	wait window "Importing " + cName nowait
	if pjxfile->type = "K"
		cToName = cAppDir + juststem(cName) + ".scp"
		vfp_import_scx(cDir+cName, cToName)
	elseif pjxfile->type = "V"
		cToName = cAppDir + juststem(cName) + ".vcp"
		vfp_import_vcx(cDir+cName, cToName)
	elseif pjxfile->type = "x" or pjxfile->type = "P" or pjxfile->type = "T"
		cFromName = cDir + cName
		cToName = cAppDir + justfname(cName)
		copy file "&cFromName" to "&cToName"
	endif
	skip	
enddo
use
select &nSelect
wait window 'Project import complete' timeout 2

