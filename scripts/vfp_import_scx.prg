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
//   vfp_import_scx.prg
//
//   Imports Visual FoxPro .scx files into Lianja
//
////////////////////////////////////////////////////////////////////////////////

lparameter cFile, cOutputFile
do (justpath(sys(16))+"vfp_import_xcx.prg") with cFile, cOutputFile, "scx"
