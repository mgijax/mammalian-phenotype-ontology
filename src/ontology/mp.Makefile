## Customize Makefile settings for mp
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

qc.owl: $(SRC)
	$(ROBOT) query --use-graphs true -f csv -i $< --query ../sparql/mp_terms.sparql ontologyterms-test.txt && \
	$(ROBOT) remove --input $< --select imports \
		merge  $(patsubst %, -i %, $(OTHER_SRC))  \
		remove --axioms equivalent \
		relax \
		reduce -r ELK \
		filter --select ontology --term-file ontologyterms-test.txt --trim false \
		annotate --ontology-iri $(ONTBASE)/$@ --version-iri $(ONTBASE)/releases/$(TODAY)/$@ --output $@.tmp.owl && mv $@.tmp.owl $@

test_hp_compatible: $(SRC)
	$(ROBOT) merge -i $< -I $(URIBASE)/hp/hp-base.owl reason

test_obo: qc.owl
	$(ROBOT) annotate --input $< --ontology-iri $(URIBASE)/$@ --version-iri $(ONTBASE)/releases/$(TODAY) \
		convert --check false -f obo $(OBO_FORMAT_OPTIONS) -o qc.tmp.obo && grep -v ^owl-axioms qc.tmp.obo > mp.obo && rm qc.tmp.obo

test: sparql_test all_reports test_obo
	$(ROBOT) reason --input $(SRC) --reasoner ELK --output test.owl && rm test.owl && echo "Success"

# We overwrite the .owl release to be, for now, a simple merged version of the editors file.
$(ONT).owl: $(SRC)
	$(ROBOT) merge --input $< \
		annotate --ontology-iri $(URIBASE)/$@ --version-iri $(ONTBASE)/releases/$(TODAY) \
		convert -o $@.tmp.owl && mv $@.tmp.owl $@
		
$(ONT).obo: $(ONT)-simple-non-classified.owl
	$(ROBOT) annotate --input $< --ontology-iri $(URIBASE)/$(ONT).owl --version-iri $(ONTBASE)/releases/$(TODAY) \
	convert --check false -f obo $(OBO_FORMAT_OPTIONS) -o $@.tmp.obo && grep -v ^owl-axioms $@.tmp.obo > $@ && rm $@.tmp.obo

robot_diff_jenkins.txt:
	$(ROBOT) merge -I https://build.berkeleybop.org/job/build-mp-edit/lastSuccessfulBuild/artifact/src/ontology/mp.owl -o mp-down.owl
	$(ROBOT) diff --left mp.owl --right mp-down.owl -o owl_$@
	#$(ROBOT) diff --left mp.obo --right-iri https://build.berkeleybop.org/job/build-mp-edit/lastSuccessfulBuild/artifact/src/ontology/mp.obo -o obo_$@

labels.csv: $(SRC)
	$(ROBOT) query --use-graphs true -f csv -i $(SRC) --query ../sparql/term_table.sparql $@
	
#######################################################
##### Code for removing patternised classes ###########
#######################################################

patternised_classes.txt: .FORCE
	$(ROBOT) query -f csv -i ../patterns/definitions.owl --query ../sparql/mp_terms.sparql $@.tmp
	sed -i 's/http[:][/][/]purl.obolibrary.org[/]obo[/]//g' $@.tmp
	sed -i '/^[^M]/d' $@.tmp
	cat $@.tmp | tr -s '\r\n' '|' > $@
	truncate -s -1 $@ && rm -f $@.tmp


remove_patternised_classes: $(SRC) patternised_classes.txt
	sed -i -r "/^EquivalentClasses[(][<]http[:][/][/]purl.obolibrary.org[/]obo[/]($(shell cat patternised_classes.txt))/d" $(SRC)



#$(ROBOT) remove -i $< -T patternised_classes.txt --axioms equivalent --preserve-structure false -o $(SRC).ofn && mv $(SRC).ofn $(SRC)

#IMPORT_SEED_FILES = $(patsubst %, imports/%_terms_combined.txt, $(IMPORTS))

#	all_imports: $(IMPORT_FILES)
	 
#	@ -253,20 +249,6 @@ imports/%_terms_combined.txt: seed.txt imports/%_terms.txt
# -- Generate Import Modules --
#
# This pattern uses ROBOT to generate an import module

#MIRROR_FILES = $(patsubst %, mirror/%.owl, $(IMPORTS))

#mirror/merged_mirror.owl: $(MIRROR_FILES)
#	@if [ $(MIR) = true ] && [ $(IMP) = true ]; then $(ROBOT) merge $(addprefix -i , $(MIRROR_FILES)) -o $@; fi 

#signature.txt: $(IMPORT_SEED_FILES)
#	cat $^ | grep -v ^# | sort | uniq >  $@

#imports/all_import.owl: mirror/merged_mirror.owl signature.txt
#	$(ROBOT) extract -i $< -T signature.txt --method BOT \
#		annotate --ontology-iri $(ONTBASE)/$@ --version-iri $(ONTBASE)/releases/$(TODAY)/$@ --output $@.tmp.owl && mv $@.tmp.owl $@
#.PRECIOUS: imports/all_import.owl


#######################################################
##### MP-international edition ########################
#######################################################

LANGUAGES=ja
TRANSLATIONDIR=translations
TRANSLATED_ONTOLOGIES=$(patsubst %, $(TRANSLATIONDIR)/$(ONT)-%.owl, $(LANGUAGES))

.PHONY: prepare_translations
prepare_translations:
	$(MAKE) IMP=false COMP=false PAT=false MIR=false $(TRANSLATED_ONTOLOGIES)


# The Babelon schema required for the translation to RDF
BABELON_SCHEMA=https://raw.githubusercontent.com/monarch-initiative/babelon/main/src/schema/babelon.yaml
$(TRANSLATIONDIR)/babelon.yaml:
	mkdir -p $(TRANSLATIONDIR)
	wget "$(BABELON_SCHEMA)" -O $@

# Synonyms are not usually translated, so they should be provided as a ROBOT template
$(TRANSLATIONDIR)/$(ONT)-%.synonyms.owl: $(TRANSLATIONDIR)/$(ONT)-%.synonyms.tsv
	$(ROBOT) template --template $< --output $@
.PRECIOUS: $(TRANSLATIONDIR)/$(ONT)-%.synonyms.owl

# This is a very hacky goal that should ideally be handled by linkml
# We have to inject annotation property declaration to ensure the converted file is really usable by ROBOT
$(TRANSLATIONDIR)/$(ONT)-profile-%.owl: $(TRANSLATIONDIR)/$(ONT)-%.babelon.tsv $(TRANSLATIONDIR)/babelon.yaml
	linkml-convert -t rdf -s $(TRANSLATIONDIR)/babelon.yaml -C Profile -S translations $< -o $@.tmp
	echo "babelon:source_language a owl:AnnotationProperty ." >> $@.tmp
	echo "babelon:source_value a owl:AnnotationProperty ." >> $@.tmp
	echo "babelon:translation_language a owl:AnnotationProperty ." >> $@.tmp
	echo "babelon:translation_status a owl:AnnotationProperty ." >> $@.tmp
	echo "<http://purl.obolibrary.org/obo/IAO_0000115> a owl:AnnotationProperty ." >> $@.tmp
	sed -i '1s/^/@prefix babelon: <https:\/\/w3id.org\/babelon\/> . \n/' $@.tmp
	$(ROBOT) merge -i $@.tmp query --update ../sparql/tag-source-language.ru --update ../sparql/rm-rdf.ru -o $@	
.PRECIOUS: $(TRANSLATIONDIR)/$(ONT)-profile-%.owl

# This goal creates a Japanese version of the ontology
# And a report that includes which labels have changed (and moves those to "CANDIDATE" status). This also ideally does not belong here (babelon toolkit)
$(TRANSLATIONDIR)/$(ONT)-%.owl: $(TRANSLATIONDIR)/$(ONT)-profile-%.owl $(TRANSLATIONDIR)/$(ONT)-%.synonyms.owl $(ONT).owl
	mkdir -p $(REPORTDIR)
	$(ROBOT) merge -i $(TRANSLATIONDIR)/$(ONT)-profile-$*.owl -i $(TRANSLATIONDIR)/$(ONT)-$*.synonyms.owl -i $(ONT).owl -o $(TMPDIR)/$(ONT)-$*-merged.ttl
	update --data=$(TMPDIR)/$(ONT)-$*-merged.ttl --update=../sparql/relegate-updated-labels-to-candidate-status.ru --update=../sparql/rm-original-translation.ru --dump >> $(TMPDIR)/$(ONT)-$*-updated.ttl
	arq --query=../sparql/relegate-updated-labels-to-candidate-status.sparql --data=$(TMPDIR)/$(ONT)-$*-merged.ttl --results=TSV > $(REPORTDIR)/updated-labels-to-candidate-status-$*.tsv
	$(ROBOT) remove -i $(TMPDIR)/$(ONT)-$*-updated.ttl --base-iri $(URIBASE)/MP --axioms external --preserve-structure false --trim false \
	annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@
.PRECIOUS: $(TRANSLATIONDIR)/$(ONT)-%.owl

# Main release goal for the international edition
$(ONT)-international.owl: $(ONT).owl $(TRANSLATED_ONTOLOGIES)
	$(ROBOT) merge $(patsubst %, -i %, $^) \
		$(SHARED_ROBOT_COMMANDS) annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@.tmp.owl && mv $@.tmp.owl $@

xxx:
	robot merge -i $(TRANSLATIONDIR)/$(ONT)-profile-ja.owl -i $(TRANSLATIONDIR)/$(ONT)-ja.synonyms.owl -i $(ONT).owl \
	remove --base-iri $(URIBASE)/MP --axioms external --preserve-structure false --trim false \
	query --query ../sparql/relegate-updated-labels-to-candidate-status.sparql $(REPORTDIR)/updated-labels-to-candidate-status-ja.tsv \
	query --update ../sparql/relegate-updated-labels-to-candidate-status.ru \
	query --update ../sparql/rm-original-translation.ru \
	annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output test-int.owl

