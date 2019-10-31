SET jenkins=https://build.obolibrary.io/job/obofoundry/job/pipeline-mp/job/master/lastSuccessfulBuild/artifact/src/ontology/imports/
powershell -Command "Invoke-WebRequest %jenkins%chebi_import.owl -OutFile imports\chebi_import.owl"
powershell -Command "Invoke-WebRequest %jenkins%cl_import.owl -OutFile imports\cl_import.owl"
powershell -Command "Invoke-WebRequest %jenkins%go_import.owl -OutFile imports\go_import.owl"
powershell -Command "Invoke-WebRequest %jenkins%mpath_import.owl -OutFile imports\mpath_import.owl"
powershell -Command "Invoke-WebRequest %jenkins%nbo_import.owl -OutFile imports\nbo_import.owl"
powershell -Command "Invoke-WebRequest %jenkins%pato_import.owl -OutFile imports\pato_import.owl"
powershell -Command "Invoke-WebRequest %jenkins%pr_import.owl -OutFile imports\pr_import.owl"
powershell -Command "Invoke-WebRequest %jenkins%ro_import.owl -OutFile imports\ro_import.owl"
powershell -Command "Invoke-WebRequest %jenkins%uberon_import.owl -OutFile imports\uberon_import.owl"