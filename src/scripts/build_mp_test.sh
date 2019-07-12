TARGETDIR=$1

docker pull obolibrary/odkfull
cd $TARGETDIR
git clone https://github.com/obophenotype/mammalian-phenotype-ontology.git
cd mammalian-phenotype-ontology/src/ontology
sh run.sh make test
