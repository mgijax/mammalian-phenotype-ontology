Mammalian Phenotype Equivalence Axioms

See:

 * https://code.google.com/p/phenotype-ontologies/wiki/MP

CURRENT WORKFLOW:

Please note we have switched to editing equivalence axioms in Protege
(the OWL will be primary). The core MP will remain in obo with the
primary version at MGI.

 * Edit mp-equivalence-axioms-subq-ubr.owl
 * Do not edit MP terms or external ontology terms - equiv axioms only
 * Have Elk turned on the whole time and sync repeatedly
 * Check Jenkins after commit

PROPOSED WORKFLAW, PHASE 2:

This extends phase 1 to include both the core ontology and equivalence
axioms in OWL edited in Protege. i.e. just like any normal modern
ontology - see for example cl workflow.

 * Edit mp-edit.owl
 * Have Elk turned on the whole time and sync repeatedly
 * Check Jenkins after commit

TODO

Finish eliminating pseudo-anon classes

