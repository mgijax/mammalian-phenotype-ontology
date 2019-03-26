OBO=http://purl.obolibrary.org/obo
RELEASE_URIBASE= $(OBO)/mp/releases/`date +%Y-%m-%d`

# all-subsets mp-inferred.obo mp-base.owl
all: mp.obo mp.owl 

mp.obo: build/mp-simple.obo
	owltools $< --make-subset-by-properties -o -f obo $@.tmp && grep -v ^remark: $@.tmp > $@

mp.owl: build/mp.owl
	cp -p $< $@

subsets:
	mkdir $@

all-subsets: build/mp.owl subsets
	mkdir -p subsets && cp -p build/subsets/* subsets/

catalog-v001.xml: default-catalog.xml
	cp $< $@

mirror-catalog.xml: mp-edit.owl
	owltools $< --sic -d . -c test-catalog-v001.xml

# Note: we currently use no-reasoner for now, until we can trust all inferences
build/mp-simple.obo: mp-edit.owl catalog-v001.xml
	ontology-release-runner --catalog-xml catalog-v001.xml $(OORT_ARGS) --ignoreLock --skip-release-folder --outdir build --simple --allow-overwrite --no-reasoner $<

# TODO: once equivalence have been sorted, remove --allowEquivalencies
mp-inferred.obo: mp-edit.owl
	owltools  --use-catalog $<  --assert-inferred-subclass-axioms --markIsInferred --allowEquivalencies --reasoner-query -r elk MP_0000001 --make-ontology-from-results mp-inferred -o -f obo $@.tmp --reasoner-dispose && grep -v ^owl-axioms $@.tmp > $@

build/mp.owl: build/mp-simple.obo

# Create "base" release file containing MP-asserted axioms, no external axioms, and no inferences.
mp-base.owl: mp-edit.owl catalog-v001.xml
	owltools --use-catalog $< --remove-imports-declarations --set-ontology-id -v $(RELEASE_URIBASE)/$@ $(OBO)/mp/$@ -o -f owl $@.tmp && cp $@.tmp $@ && touch $@ && rm $@.tmp

## TEMPORARY: use this to make a test mp-edit.owl. This target will be
## eliminated when mp-edit.owl becomes the live version
#mp-edit.owl: ../mp.owl mp-equivalence-axioms-subq-ubr.owl
#	owltools --use-catalog $< mp-equivalence-axioms-subq-ubr.owl imports-only.owl  --merge-support-ontologies -o -f ofn $@




# ----------------------------------------
# Module extraction / Imports generation
# ----------------------------------------
#
# We create shared modules for the combined set of phenotype
# ontologies
#
# Uses OWLAPI Module Extraction code
#
# Type 'make imports/X_import.owl' whenever you wish to refresh the import for an ontology X. This is when:
#
#  1. X has changed and we want to include these changes
#  2. We have added onr or more new IRI from X into any of the xp files
#
# You should NOT edit these files directly, changes will be overwritten.
#
# If you want to add something to these, edit the xp obo file and add an axiom with a IRI from X. You don't need to add any information about X.
#
# **Note that imports are shared by all projects**
# this means that any one import will be larger than is strictly required for any one species, but there are advantages to sharing here

# Base URI for local subset imports
##UPHENO = $(OBO)/upheno

# Ontology dependencies. TODO - nbo
IMPORTS = pato uberon chebi pr go doid mpath nbo

# Make this target to regenerate ALL
all_imports: all_imports_owl all_imports_obo
all_imports_owl: $(patsubst %, imports/%_import.owl,$(IMPORTS))
all_imports_obo: $(patsubst %, imports/%_import.obo,$(IMPORTS))

KEEPRELS = BFO:0000050 BFO:0000051 RO:0002202 immediate_transformation_of

# Create an import module using the OWLAPI module extraction code via OWLTools.
# We use the standard catalog, but rewrite the import to X to be a local mirror of ALL of X.
# After extraction, we further reduce the ontology by creating a "mingraph" (removes all annotations except label) and by 

#imports/wbbt_import.owl: wbphenotype/wbphenotype-equivalence-axioms-subq-ubr.owl mirror/wbbt.owl
#	owltools  $(USECAT) --map-ontology-iri $(UPHENO)/wbbt_import.owl mirror/wbbt.owl $< --merge-imports-closure mirror/$*.owl --add-imports-from-support  --extract-module -s $(OBO)/$*.owl -c --remove-axiom-annotations --make-subset-by-properties $(KEEPRELS) --set-ontology-id $(UPHENO)/$@ -o $@


IMPORT_REQUESTS = imports/imports_requests.obo

# GENERIC:
imports/%_import.owl: imports/upheno-preimporter.owl $(IMPORT_REQUESTS) mirror/%.owl mp-edit.owl
	owltools  $(USECAT) --map-ontology-iri $(UPHENO)/$*_import.owl mirror/$*.owl $< --merge-imports-closure mirror/$*.owl --add-imports-from-support  --extract-module -s $(OBO)/$*.owl -c --remove-axiom-annotations --make-subset-by-properties -f $(KEEPRELS) -o $@.tmp && owltools $@.tmp --set-ontology-id $(UPHENO)/$@ -o $@

imports/ro_import.owl: imports/upheno-preimporter.owl $(IMPORT_REQUESTS) mirror/ro.owl mp-edit.owl
	owltools  $(USECAT) --map-ontology-iri $(UPHENO)/ro_import.owl mirror/ro.owl $< --merge-imports-closure mirror/ro.owl --add-imports-from-support  --extract-module -s $(OBO)/ro.owl -c  -o ro.tmp && owltools ro.tmp --set-ontology-id $(UPHENO)/$@ -o $@

imports/fma_import.owl:
	echo "This is manually curated"

# clone remote ontology locally, perfoming some excision of relations and annotations
mirror/%.owl:
	owltools $(OBO)/$*.owl --remove-annotation-assertions -l --remove-dangling-annotations  --make-subset-by-properties -f $(KEEPRELS) --extract-mingraph --set-ontology-id $(OBO)/$*.owl -o $@
# uberon-ext is actually uberon+cl
mirror/uberon-ext.owl: external/uberon/ext.owl
	owltools $(OBO)/uberon/ext.owl --merge-imports-closure -o $@
#mirror/fma-orig.owl: 
#	wget $(OBO)/fma.owl -O $@

## ANNOYING: this needs built periodically to avoid stale imports
mirror/fma.owl:
	owltools mirror/composite-fma.owl --extract-mingraph --set-ontology-id $(OBO)/fma.owl -o $@
mirror/ro.owl:
	wget $(OBO)/ro.owl -O $@
mirror/uberon.owl: mirror/uberon-ext.owl
	owltools $(USECAT) $<  --merge-support-ontologies --merge-imports-closure --make-subset-by-properties -n $(KEEPRELS)  --remove-annotation-assertions -l -s -d --remove-axiom-annotations --remove-dangling-annotations  --set-ontology-id $(OBO)/uberon.owl -o $@
##### need to sort sync issue
#####	owltools $(OBO)/uberon/ext.owl $(OBO)/cl.owl --merge-support-ontologies --remove-annotation-assertions -l --remove-dangling-annotations --make-subset-by-properties $(KEEPRELS) --extract-mingraph --set-ontology-id $(OBO)/uberon.owl -o $@

mirror/wbbt.owl:
	owltools $(OBO)/uberon/basic.owl $(OBO)/cl.owl $(OBO)/wbls.owl $(OBO)/wbbt.owl $(OBO)/uberon/bridge/uberon-bridge-to-wbbt.owl $(OBO)/uberon/bridge/cl-bridge-to-wbbt.owl $(OBO)/ncbitaxon/subsets/taxslim.owl --merge-support-ontologies --remove-annotation-assertions -l --remove-dangling-annotations --make-subset-by-properties $(KEEPRELS)  --set-ontology-id $(OBO)/wbbt.owl -o $@
###	owltools $(OBO)/uberon/ext.owl --remove-annotation-assertions -l --remove-dangling-annotations --make-subset-by-properties $(KEEPRELS) --set-ontology-id $(OBO)/uberon.owl -o $@
###	owltools  $(OBO)/wbls.owl $(OBO)/wbbt.owl --merge-support-ontologies --remove-annotation-assertions -l --remove-dangling-annotations --make-subset-by-properties $(KEEPRELS)  --set-ontology-id $(OBO)/wbbt.owl -o $@
mirror/go.owl: 
	owltools $(OBO)/go/extensions/go-plus.owl $(OBO)/go/extensions/x-metazoan-anatomy.owl    --merge-imports-closure --merge-support-ontologies --remove-annotation-assertions -l --remove-dangling-annotations  --make-subset-by-properties -f $(KEEPRELS) --extract-mingraph --set-ontology-id $(OBO)/go.owl -o $@
mirror/pr.obo:
	wget $(OBO)/pr.obo -O $@.tmp && obo-grep.pl -r 'id: PR:' $@.tmp > $@
mirror/pr.owl: mirror/pr.obo
	owltools $< --remove-dangling --set-ontology-id $(OBO)/pr.owl -o $@
.PRECIOUS: mirror/%.owl

#imports/ro_import.owl: mirror/ro.owl imports/upheno-preimporter.owl
#	owltools  $(USECAT) --map-ontology-iri $(UPHENO)/ro_import.owl mirror/ro.owl imports/upheno-preimporter.owl --merge-imports-closure mirror/ro.owl  --add-imports-from-supports  --extract-module -s $(OBO)/ro.owl -c --extract-mingraph --set-ontology-id $(UPHENO)/$@ -o $@

imports/so_import.owl:
	owltools  $(USECAT) $< $(UPHENO)/data/human-genes.owl $(OBO)/so.owl --add-imports-from-supports --extract-module -s $(OBO)/so.owl -c --extract-mingraph --remove-annotation-assertions -l -d -s --make-subset-by-properties -f // --set-ontology-id $(UPHENO)/$@ -o $@

imports/%_import.obo: imports/%_import.owl
	owltools $< -o -f obo $@

external/uberon/%.owl:
	echo $@

external/mirror/%.owl:
	wget $(OBO)/$*.owl -O $@

# Create a read-only OBO subset with logical defs
mp-edit.obo: mp-edit.owl
	owltools --use-catalog $< --add-obo-shorthand-to-properties -o -f obo --no-check $@
subsets/mp-ldefs.obo: mp-edit.obo
	obo-filter-tags.pl -t intersection_of -t id -t name $< | obo-grep.pl -r intersection_of - | grep -v ^owl-axioms > $@
