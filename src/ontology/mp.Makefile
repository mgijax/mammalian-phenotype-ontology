## Customize Makefile settings for mp
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile

qc.owl: $(SRC)
	$(ROBOT) remove --input $< --select imports \
		merge  $(patsubst %, -i %, $(OTHER_SRC))  \
		remove --axioms equivalent \
		relax \
		reduce -r ELK \
		filter --select ontology --term-file $(ONTOLOGYTERMS) --trim false \
		annotate --ontology-iri $(ONTBASE)/$@ --version-iri $(ONTBASE)/releases/$(TODAY)/$@ --output $@.tmp.owl && mv $@.tmp.owl $@

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

labels.csv: $(SRC)
	robot query --use-graphs true -f csv -i $(SRC) --query ../sparql/term_table.sparql $@