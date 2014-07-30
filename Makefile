all: mp.obo mp.owl all-subsets mp-inferred.obo

mp.obo: build/mp-simple.obo
	owltools $< --make-subset-by-properties -o -f obo $@.tmp && grep -v ^remark: $@.tmp > $@

mp.owl: build/mp.owl
	cp -p $< $@

subsets:
	mkdir $@

all-subsets: build/mp.owl subsets
	mkdir -p subsets && cp -p build/subsets/* subsets/

# Note: we currently use no-reasoner for now, until we can trust all inferences
build/mp-simple.obo: mp-edit.owl
	ontology-release-runner --catalog-xml catalog-v001.xml $(OORT_ARGS) --ignoreLock --skip-release-folder --outdir build --simple --allow-overwrite --no-reasoner $<

# TODO: once equivalence have been sorted, remove --allowEquivalencies
mp-inferred.obo: mp-edit.owl
	owltools  --use-catalog $<  --assert-inferred-subclass-axioms --markIsInferred --allowEquivalencies --reasoner-query -r elk MP_0000001 --make-ontology-from-results mp-inferred -o -f obo $@.tmp --reasoner-dispose && grep -v ^owl-axioms $@.tmp > $@

build/mp.owl: build/mp-simple.obo

## TEMPORARY: use this to make a test mp-edit.owl. This target will be
## eliminated when mp-edit.owl becomes the live version
#mp-edit.owl: ../mp.owl mp-equivalence-axioms-subq-ubr.owl
#	owltools --use-catalog $< mp-equivalence-axioms-subq-ubr.owl imports-only.owl  --merge-support-ontologies -o -f ofn $@
