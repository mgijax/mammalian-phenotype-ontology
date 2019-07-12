set path=%1

docker pull obolibrary/odkfull
cd /d %path%
git clone https://github.com/obophenotype/mammalian-phenotype-ontology.git
cd mammalian-phenotype-ontology
git checkout mp-odk
cd src\ontology
sh run.bat make test
