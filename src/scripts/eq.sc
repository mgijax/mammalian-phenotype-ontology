import $ivy.`net.sourceforge.owlapi:owlapi-distribution:4.5.20`
import $ivy.`org.phenoscape::scowl:1.3.4`
import $ivy.`com.outr::scribe-slf4j:3.6.3`

import org.phenoscape.scowl._
import org.semanticweb.owlapi.apibinding.OWLManager
import org.semanticweb.owlapi.model.IRI
import org.semanticweb.owlapi.model.parameters.Imports
import scala.jdk.CollectionConverters._

@main
def main(inputFile: os.Path, outputFile: os.Path): Unit = {
  val HasPart = ObjectProperty("http://purl.obolibrary.org/obo/BFO_0000051")
  val InheresIn = ObjectProperty("http://purl.obolibrary.org/obo/RO_0000052")
  val manager = OWLManager.createOWLOntologyManager()
  val inputOntology = manager.loadOntology(IRI.create(inputFile.toIO))
  val allAxioms = inputOntology.getAxioms(Imports.INCLUDED).asScala.to(Set)
  // just for example...
  val nnfAxioms = for {
    axiom <- allAxioms
  } yield axiom.getNNF()
  // EQ drilling
  val termsWithEntityAndQuality = for {
    EquivalentClasses(_, classes) <- allAxioms
    named <- classes.find(_.isNamed()).map(_.asOWLClass())
    eqIntersection <- classes.collectFirst {
      case ObjectSomeValuesFrom(HasPart, ObjectIntersectionOf(intersection)) => intersection
    }
    quality <- eqIntersection.find(_.isNamed()).map(_.asOWLClass())
    entity <- eqIntersection.collectFirst {
      case ObjectSomeValuesFrom(InheresIn, entity @ Class(_)) => entity
    }
  } yield (named, entity, quality)
  termsWithEntityAndQuality.foreach(println)
  manager.saveOntology(inputOntology, IRI.create(outputFile.toIO))
}