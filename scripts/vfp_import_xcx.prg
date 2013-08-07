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
//   vfp_import_xcx.prg
//
//   Imports Visual FoxPro .?cx files into Lianja
//
////////////////////////////////////////////////////////////////////////////////

lparameter cFile, cOutputFile, cFileType
private cSafety = set("SAFETY", 1)
private nSelect = select()
dimension aNewNames[1], aProtected[1], aMethods[1]
private oNewNames, oProtected[], oClassInfo
oClassInfo = createobject("Empty")
oClassInfo.AddProperty("cClassName", "")
oClassInfo.AddProperty("cBaseClassName", "")
oClassInfo.AddProperty("cParentName", "")
oClassInfo.AddProperty("cObjectName", "")
private cProtected, cForm, cProp, cFirst, cSecond, cAccess, cLine
private i, nMethods, nNewMethods, nRow
private bNewline, bNewUndefined, bFirst
private fp, nRecno, cParentName, cObjectName
private nState
private classlibs[]

bFirst = .T.
cFileType = lower(evl(m.cFileType, justext(m.cFile)))
set exact on

////////////////////////////////////////////////////////////////////////////////
? "Converting Visual FoxPro ." + m.cFileType +" file '&cFile'"
?? "opening '&cFile'"
if used("xcxfile")
	close xcxfile
endif
use "&cFile" alias xcxfile in 0 current noupdate
? " - ok"
?? "creating '&cOutputFile'"
if file(m.cOutputFile)
	set safety off
	erase &cOutputFile
	set safety &cSafety
endif
fp = fcreate(m.cOutputFile)
? " - ok"

// Output the header
fputs(m.fp, replicate("*", 80))
fputs(m.fp, "*")
fputs(m.fp, "* File created by "+version())
fputs(m.fp, "* Converted on " + etos(date()) + " at " + time())
fputs(m.fp, "*")
fputs(m.fp, replicate("*", 80))
fputs(m.fp, "")

////////////////////////////////////////////////////////////////////////////////
// Step 1: Open the class libraries (if any) for scx forms
//
bFirst = .t.
if "scx" = cFileType
	scan
		if xcxfile.platform = "COMMENT"
			loop
		endif
		oClassInfo.cObjectName = trim(xcxfile.objname)
		if len(m.oClassInfo.cObjectName)=0
			loop
		endif
		cClassLib = alltrim(xcxfile.classloc)
		if len(cClassLib)=0
			loop
		endif
		cClassLib = juststem(cClassLib)
		if in_array(cClassLib, classlibs)
			loop
		endif
		classlibs[cClassLib] = cClassLib
		if bFirst
			fprintf(m.fp, repl("//", 40)+"\n")
			bFirst = .f.
		endif
		fprintf(m.fp, 'set classlib to "%s" additive\n', cClassLib)
	endscan
endif

////////////////////////////////////////////////////////////////////////////////
// Step 2: Output the class definitions
for nState=1 to 2
	scan
		if alltrim(xcxfile.platform) = "COMMENT"
			loop
		endif
		oClassInfo.cObjectName = alltrim(xcxfile.objname)
		if len(m.oClassInfo.cObjectName)=0
			loop
		endif
		oClassInfo.cParentName = alltrim(xcxfile.parent)
		oClassInfo.cBaseClassName = alltrim(xcxfile.baseclass)
		oClassInfo.cClassName = alltrim(xcxfile.class)
		if (lower(oClassInfo.cObjectName) == lower(oClassInfo.cClassName))
			loop
		endif
		? "Processing object " + oClassInfo.cObjectName + " class " + oClassInfo.cClassName
		Lianja.showMessage("Processing object " + oClassInfo.cObjectName, 175)
		aProperties = mtoa(xcxfile.properties)
		nMethods = len(xcxfile.methods)
		cProtected = mtos(xcxfile.protected)
		cNewNames = mtos(xcxfile.RESERVED3)
		aProtected = mtoa(xcxfile.protected)
		aNewNames = mtoa(xcxfile.RESERVED3)
		bNewline = .f.
		bNewUndefined = .f.
		cClassName = lower(m.oClassInfo.cObjectName)
		cProcessingClass = cClassName
		cParentName = lower(m.oClassInfo.cParentName)
		cBaseClassName = lower(m.oClassInfo.cBaseClassName)
		if empty(oClassInfo.cParentName)
			if nState = 1
				loop
			endif
			if not bFirst
				fprintf(m.fp, "\n\n")
			endif
			bFirst = .f.
			fprintf(m.fp, repl("//", 40)+"\n")
			fprintf(m.fp, "define class %s as %s\n\n", lower(m.oClassInfo.cObjectName), lower(m.oClassInfo.cClassName))
		else
			if nState = 2
				loop
			endif
			if not bFirst
				fprintf(m.fp, "\n\n")
			endif
			bFirst = .f.
			fprintf(m.fp, repl("//", 40)+"\n")
			if not empty(m.oClassInfo.cBaseClassName) and (lower(m.oClassInfo.cClassName) <> lower(m.oClassInfo.cBaseClassName))
				fprintf(m.fp, "define class %s as %s\n\n", lower(xcxfile.objname)+trim(xcxfile.uniqueid), lower(m.oClassInfo.cClassName))
			else
				if not empty(m.oClassInfo.cBaseClassName)
					fprintf(m.fp, "define class %s as %s\n\n", lower(alltrim(xcxfile.objname)+trim(xcxfile.uniqueid)), lower(m.oClassInfo.cBaseClassName))
				else
					fprintf(m.fp, "define class %s\n\n", lower(alltrim(xcxfile.objname)+trim(xcxfile.uniqueid)))
				endif
			endif
		endif
		
		// Get sub objects
		nRecno = recno()
		skip
		bAdded = .f.
		do while not eof()
			oClassInfo.cBaseClassName = mtos(xcxfile.class)
			oClassInfo.cParentName = mtos(xcxfile.parent)
			oClassInfo.cObjectName = trim(xcxfile.objname)
			oClassInfo.cClassName = trim(xcxfile.objname) + trim(trim(xcxfile.uniqueid))
			cObjectName = trim(xcxfile.objname)
			//cClassName = lower(m.oClassInfo.cObjectName)
			cParentName = lower(m.oClassInfo.cParentName)
			cBaseClassName = lower(m.oClassInfo.cBaseClassName)
			if not empty(m.oClassInfo.cParentName) and ((lower(mtos(xcxfile.parent)) = m.cClassName);
				or (lower(mtos(xcxfile.parent)) = m.cParentName + "." + m.cClassName))
				if not bAdded
					fprintf(m.fp, '\t** Children\n')
				endif
				fprintf(m.fp, '\tadd object %s as %s\n', lower(m.oClassInfo.cObjectName), lower(m.oClassInfo.cClassName))
				? sprintf('add object %s as %s', lower(m.oClassInfo.cObjectName), lower(m.oClassInfo.cClassName))
				bAdded = .t.
			elseif startsWith(lower(cParentName),cProcessingClass+".")
				if not bAdded
					fprintf(m.fp, '\t** Children\n')
				endif
				fprintf(m.fp, '\tadd object %s as %s\n',;
				        substr(cParentName, len(cProcessingClass)+2)+"."+lower(m.oClassInfo.cObjectName),; 
				        lower(m.oClassInfo.cClassName))
				? sprintf('add object %s as %s',;
				        substr(cParentName, len(cProcessingClass)+2)+"."+lower(m.oClassInfo.cObjectName),; 
				        lower(m.oClassInfo.cClassName))
				bAdded = .t.
			endif
			skip
		enddo
		goto &nRecno
		if bAdded
			fprintf(m.fp, '\n')
		endif
		
		// Get Hidden/Protected info
		for lnRun = 1 to Alen(aProtected)
			cProp = Alltrim(aProtected[m.lnRun])
			Do Case
			case empty(m.cProp)
			case Right(m.cProp,1)=="^"
				cProp = Left(m.cProp, Len(m.cProp)-1)
				oProtected[m.cProp] = "Hidden"
			otherwise
				oProtected[m.cProp] = "Protected"
			endcase
		endfor
		
		// Read out New Array/Method/properties into Pointer
		// While we are at it, write out new Array types
		if occurs("^",cNewNames)>0
			// ? "Array-Propeties exist"
			= sectionheader("Array-Properties")
		endif
		
		oNewNames = Createobject("Empty")
		for lnRun = 1 to Alen(aNewNames)
			cFirst = Alltrim(Getwordnum(aNewNames[m.lnRun],1))
			If !Empty(m.cFirst)
				do case
				case  Left(m.cFirst,1)="*"
					cProp = Right(m.cFirst, Len(m.cFirst)-1)
					oNewNames.addproperty(m.cProp, m.lnRun)
					
				case  Left(m.cFirst,1)="^")
					cProp = substr(m.cFirst, 2, at("[",m.cFirst)-2)
					// remove ,0] 
					if endsWith(cProp, ",0]") 
						cProp = substr(cProp, 1, len(cProp)-3) + "]"
					endif
					lcLine = getAccessModifier(m.cProp, "Dimension") + Substr(m.cFirst,2) + Chr(10)
					fprintf(m.fp, "%s", strindent(m.lcLine, 1))
					
				otherwise
					if ascan(aProperties, m.cFirst + " =")=0
						if !empty(aProperties[1])
							dimension aProperties[alen(aProperties)+1]
						endif
						aProperties[alen(aProperties)] = m.cFirst + " = .f."
						bNewUndefined = .t.
					endif
				endcase
			endif
		endfor
		
		if not empty(mtos(xcxfile.properties)) or m.bNewUndefined
			= sectionheader("Properties")
			fprintf(m.fp, "%s", strindent(convertProperties(), 1))
		endif
		if not empty(m.cProtected) and .f.  && was not cleaned IAC
			= sectionheader("Protected")	&& handled now in-line!
			fprintf(m.fp, "%s", strindent(m.cProtected, 1))
		endif
		
		nNewMethods = 0	
		if m.nMethods > 0
			= sectionheader("Methods")
			aMethods = mtoa(xcxfile.methods, .t.)
			for i=1 to alen(aMethods)
				cLine = aMethods[i]
				cFirst = lower(Getwordnum(cLine,1))
				if len(cFirst)> 3 and (at(cFirst, "function")=1 or at(cFirst, "procedure")=1)
					cSecond = Alltrim(Getwordnum(cLine,2))
					cAccess = iif(vartype(oProtected.&cSecond)=="C", oProtected.&cSecond + " ", "")
					nRow = iif(vartype(oNewNames.&cSecond)=="N", oNewNames.&cSecond, 0)
					Do Case
					case m.nRow<0
						Wait Wind "ERROR "	+ m.cSecond + " Again???"
					case m.nRow>0
						oNewNames.&cSecond = -m.nRow
						nNewMethods = m.nNewMethods + 1
					otherwise
						//? "!" + cAccess + cSecond + ":" + cLine
					endcase
				else
					cAccess = ""
				endif
				cLine = cAccess + cLine + chr(10)
				fprintf(m.fp, "%s", strindent(m.cLine, 1))
			endfor
			
			if Occurs("*", cNewnames)>m.nNewMethods
				= sectionheader("Interface-Methods")
			endif
			
			for i=1 to alen(aNewnames)
				cFirst = Alltrim(Getwordnum(aNewNames[i],1))
				If Left(m.cFirst,1)="*"
					cProp = Right(m.cFirst, Len(m.cFirst)-1)
					
					nRow = iif( vartype(oNewNames.&cProp) =="N", oNewNames.&cProp, 0)
					
					If m.nRow>-1
						cAccess = getAccessModifier(m.cProp)
						cLine = m.cAccess + "Procedure " + m.cProp + Chr(10)
						// ? cline
						fprintf(m.fp, "%s", strindent(m.cLine, 1))
					endif
				endif
			endfor
		endif
		fprintf(m.fp, "\nenddefine\n")
	endscan
endfor			

////////////////////////////////////////////////////////////////////////////////
// Step 3: Output the object creation code for scx forms
//
if "scx" = cFileType
	fprintf(m.fp, "\n\n")
	fprintf(m.fp, repl("//", 40)+"\n")
	scan
		if xcxfile.platform = "COMMENT"
			loop
		endif
		
		oClassInfo.cParentName = mtos(xcxfile.parent)
		oClassInfo.cObjectName = trim(xcxfile.objname)
		if len(m.oClassInfo.cObjectName)=0
			loop
		endif	
		
		oClassInfo.cBaseClassName = mtos(xcxfile.baseclass)
		oClassInfo.cClassName = alltrim(xcxfile.class) //+ trim(xcxfile.uniqueid)
		
		if (lower(oClassInfo.cObjectName) == lower(oClassInfo.cClassName))
			loop
		endif
		
		cParentName = oClassInfo.cParentName
		cObjectName = oClassInfo.cObjectName
		if lower(m.oClassInfo.cBaseClassName) = "form"
			fprintf(m.fp, "//LIANJACLASS(%s)\n", lower(m.oClassInfo.cObjectName))
		endif
		if empty(m.oClassInfo.cParentName)
			fprintf(m.fp, '%s = createobject("%s")\n', lower(m.oClassInfo.cObjectName) + lower(trim(xcxfile.uniqueid)), lower(m.oClassInfo.cObjectName))
		endif
		if lower(m.oClassInfo.cBaseClassName) = "form"
			cForm = lower(m.oClassInfo.cObjectName) + lower(xcxfile.uniqueid)
		endif
	endscan
	
	// Make the form visible.
	if not empty(m.cForm)
		fprintf(m.fp, "%s.show" + iif(m.cFileType=="scx", "(1)","") + "\n\n\n", m.cForm)
	endif
endif

////////////////////////////////////////////////////////////////////////////////
// Step 4: Beautify the file
fclose(m.fp)
use
Lianja.showMessage("Beautifying code", 175)
vfp_beautify(m.cOutputFile)
select &nSelect
? "Conversion complete."
Lianja.showMessage("Conversion complete")

////////////////////////////////////////////////////////////////////////////////
function sectionheader(cHeader)
	if m.bNewline
		fprintf(m.fp, "\n")
	endif
	fprintf(m.fp, "\t** " + m.cHeader + "\n")
	bNewline = .t.
return


////////////////////////////////////////////////////////////////////////////////
// Converts VFP syntax on properties
function convertProperties()
	local aLineStr[1], nPos,i, cReturnString, cPropStart, cPropStop, ch, cPropname,cPropvalue
	local pNames[]
	cReturnString = ""
	cAccess = ""
	for m.i=1 to alen(aProperties)
		// trouble with astore if second "=" is in text string"
		nPos = at("=", aProperties[m.i])
		if nPos>0
			cPropname  = alltrim(left(aProperties[m.i], m.nPos-1))
			// ignore duplicate properties
			if in_array(cPropname, pNames) 
				loop
			endif
			// ignore _memberdata
			if lower(cPropname) = "_memberdata" or startsWith(cPropname, "<")
				loop
			endif
			pnames[ lower(cPropname) ] = cPropname
			cPropvalue = alltrim(subst(aProperties[m.i], m.nPos+1))
			// remove brackets around empty strings
			if cPropvalue = '("")'
				cPropvalue = '""'
			endif
			// remove brackets around property values
			if startsWith(cPropvalue, "(") and endsWith(cPropvalue, ")")
				cPropvalue = substr(cPropvalue, 2, len(cPropvalue)-2)
			endif
			if len(m.cPropvalue)=0
				cPropvalue = '""'
			endif
			ch = left(m.cPropvalue, 1)
			cPropValOld = m.cPropValue
			do case
			case Occurs("Color",m.cPropname)>0 and (;
				Inlist(Right(m.cPropname, 9), "BackColor", "ForeColor") or;
				Inlist(m.cPropname,"BorderColor","FillColor","GridLineColor"))				
				cPropStart = " = rgb("
				cPropStop = ")"
			case m.cPropname=="Database"
				// similar cases ??
				cPropStart = " = '"
				cPropStop = "'"
			case m.ch=="(" and Right(m.cPropvalue,1)==")"
				if .f.
					cPropStart = " = "
					cPropStop = ""
				else
					// still signify in vcx was an expression - do we want/need that ?
					cPropStart = " = ("
					cPropStop = ")"
				endif
				cPropvalue = Alltrim( substr( m.cPropvalue,2, len(m.cPropvalue)-2))
			case left(m.cPropvalue,3) = "..\"
				cPropStart = " = '"
				cPropStop = "'"
				m.cPropvalue = basename(m.cPropvalue)
			case isdigit(m.ch) or m.ch $ ["'.{]
				cPropStart = " = "
				cPropStop = ""
			otherwise
				cPropStart = ' = "'
				cPropStop = '"'
			endcase

			if Left(m.cPropvalue,2)=="{^" and Right(m.cPropvalue,1)=="}"
				cPropvalue = bldDateFunc(m.cPropvalue)
			endif
			if !m.cPropName=="Name"
				cAccess = getAccessModifier(m.cPropName)
			endif
			if "new"$m.cPropname and .f. && quick debug switch
				? m.cPropname + "<<:>>" + m.cPropValue + "<<!>>" + m.cPropValOld
			endif
			cReturnString = m.cReturnString + cAccess + m.cPropname + m.cPropStart + m.cPropvalue + m.cPropStop + chr(10)
		endif
	endfor
return m.cReturnString


////////////////////////////////////////////////////////////////////////////////
function getAccessModifier(cName, cDefault)
	local cReturn
	cDefault = Evl(cDefault,"")
	if vartype(m.cDefault)=="L"
		cDefault = "Public"
	endif
	cReturn = iif(vartype(oProtected.&cName)=="C", oProtected.&cName, m.cDefault)
	
	if !empty(cReturn)
		cReturn = m.cReturn + " "
	endif
return m.cReturn


////////////////////////////////////////////////////////////////////////////////
function bldDateFunc(cDateStr)
	local lcDateStr
	lcDateStr = subst(m.cDateStr,3,Len(m.cDateStr)-3)
	lcDateStr = ChrTran(m.lcDateStr,"/",",")
	lcDateStr = ChrTran(m.lcDateStr," ",",")
	lcDateStr = ChrTran(m.lcDateStr,":",",")
	lcDateStr = ChrTran(m.lcDateStr,"-",",")
	lcDateStr = ChrTran(m.lcDateStr,".",",")
	lcDateStr = "Date" + Iif(Len(cDateStr)<14, "(","Time(") + m.lcDateStr + ")"
return m.lcDateStr





















