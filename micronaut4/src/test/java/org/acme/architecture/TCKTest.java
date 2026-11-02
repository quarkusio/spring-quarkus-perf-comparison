package org.acme.architecture;

import static com.tngtech.archunit.library.Architectures.layeredArchitecture;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

@AnalyzeClasses(
    packages = "org.acme",
    importOptions = {ImportOption.DoNotIncludeTests.class})
class TCKTest {

  @ArchTest
  static final ArchRule layered_architecture_is_respected =
      layeredArchitecture()
          .consideringAllDependencies()
          .layer("Rest")
          .definedBy("..rest..")
          .layer("Service")
          .definedBy("..service..")
          .layer("Repository")
          .definedBy("..repository..")
          .whereLayer("Rest")
          .mayNotBeAccessedByAnyLayer()
          .whereLayer("Service")
          .mayOnlyBeAccessedByLayers("Rest")
          .whereLayer("Repository")
          .mayOnlyBeAccessedByLayers("Service");

  @ArchTest
  static final ArchRule rest_must_not_access_repository_domain_or_mapping =
      noClasses()
          .that()
          .resideInAPackage("..rest..")
          .should()
          .accessClassesThat()
          .resideInAnyPackage("..repository..", "..domain..", "..mapping..");

  @ArchTest
  static final ArchRule service_must_not_access_rest =
      noClasses()
          .that()
          .resideInAPackage("..service..")
          .should()
          .accessClassesThat()
          .resideInAPackage("..rest..");

  @ArchTest
  static final ArchRule repository_must_not_access_rest_service_dto_or_mapping =
      noClasses()
          .that()
          .resideInAPackage("..repository..")
          .should()
          .accessClassesThat()
          .resideInAnyPackage("..rest..", "..service..", "..dto..", "..mapping..");

  @ArchTest
  static final ArchRule dto_must_not_access_domain_or_other_runtime_layers =
      noClasses()
          .that()
          .resideInAPackage("..dto..")
          .should()
          .accessClassesThat()
          .resideInAnyPackage("..domain..", "..rest..", "..service..", "..repository..", "..mapping..");

  @ArchTest
  static final ArchRule domain_must_not_access_runtime_layers_or_dto =
      noClasses()
          .that()
          .resideInAPackage("..domain..")
          .should()
          .accessClassesThat()
          .resideInAnyPackage("..rest..", "..service..", "..repository..", "..dto..", "..mapping..");

  @ArchTest
  static final ArchRule dto_types_should_be_records =
      classes().that().resideInAPackage("..dto..").should().beRecords();
}
