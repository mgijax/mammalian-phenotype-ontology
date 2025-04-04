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
		annotate --ontology-iri $(URIBASE)/$@ --version-iri $(ONTBASE)/releases/$(TODAY)/$@ \
		convert -o $@.tmp.owl && mv $@.tmp.owl $@
		
$(ONT).obo: $(ONT)-simple-non-classified.owl
	$(ROBOT) annotate --input $< --ontology-iri $(URIBASE)/$(ONT).owl --version-iri $(ONTBASE)/releases/$(TODAY)/$@ \
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

###############################
###### Japanese version #######

# Most of this is handled by ODK.

$(TRANSLATIONSDIR)/$(ONT)-ja.owl: $(TRANSLATIONSDIR)/mp-ja.babelon.owl $(TRANSLATIONSDIR)/mp-ja.synonyms.owl $(ONT).owl
	mkdir -p $(REPORTDIR)
	$(ROBOT) merge -i $(TRANSLATIONSDIR)/mp-ja.babelon.owl -i $(TRANSLATIONSDIR)/mp-ja.synonyms.owl -i $(ONT).owl -o $(TMPDIR)/$(ONT)-ja-merged.ttl
	update --data=$(TMPDIR)/$(ONT)-ja-merged.ttl --update=../sparql/relegate-updated-labels-to-candidate-status.ru --update=../sparql/rm-original-translation.ru --dump >> $(TMPDIR)/$(ONT)-ja-updated.ttl
	arq --query=../sparql/relegate-updated-labels-to-candidate-status.sparql --data=$(TMPDIR)/$(ONT)-ja-merged.ttl --results=TSV > $(REPORTDIR)/updated-labels-to-candidate-status-ja.tsv
	$(ROBOT) remove -i $(TMPDIR)/$(ONT)-ja-updated.ttl --base-iri $(URIBASE)/MP --axioms external --preserve-structure false --trim false \
	annotate --ontology-iri $(ONTBASE)/$@ $(ANNOTATE_ONTOLOGY_VERSION) --output $@
.PRECIOUS: $(TRANSLATIONSDIR)/$(ONT)-ja.owl