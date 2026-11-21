#!/bin/bash

# Script to convert Spring Boot application to Quarkus with Spring compatibility libraries
# Based on steps from spring-conversion.md
#
# Usage: ./spring-conversion.sh [output-directory]
#   output-directory: Target directory for the converted application. Supported values:
#     quarkus<N>-spring[<M>]-compatibility Converts springboot<M> into that directory, using quarkus<N>'s config and e2e tests
#                                         (<M> defaults to <N>; default: quarkus3-spring-compatibility)
#     springboot<M>                       Converts springboot<M> in place (see the diff), using quarkus<M>'s config and e2e tests
#   Examples: quarkus3-spring-compatibility, quarkus4-spring4-compatibility, springboot3, springboot4

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
OUTPUT_DIR="${1:-quarkus3-spring-compatibility}"

# Derive the Spring and Quarkus source directories from the output directory name
if [[ "$OUTPUT_DIR" =~ ^quarkus([0-9]+)-spring([0-9]*)-compatibility$ ]]; then
    QUARKUS_DIR="quarkus${BASH_REMATCH[1]}"
    SPRING_DIR="springboot${BASH_REMATCH[2]:-${BASH_REMATCH[1]}}"
    COMPAT_DIR="$OUTPUT_DIR"
elif [[ "$OUTPUT_DIR" =~ ^springboot([0-9]+)$ ]]; then
    QUARKUS_DIR="quarkus${BASH_REMATCH[1]}"
    SPRING_DIR="$OUTPUT_DIR"
    COMPAT_DIR="quarkus${BASH_REMATCH[1]}-spring${BASH_REMATCH[1]}-compatibility"
else
    echo "Error: Unsupported output directory '${OUTPUT_DIR}'. Use quarkus<N>-spring<M>-compatibility or springboot<M>" >&2
    exit 1
fi

echo -e "${GREEN}=== Spring to Quarkus Conversion Script ===${NC}"
echo -e "${YELLOW}Output directory: ${OUTPUT_DIR}${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "spring-conversion.md" ]; then
    echo -e "${RED}Error: Must be run from the project root directory${NC}"
    exit 1
fi

# Check if source directory exists
if [ ! -d "$SPRING_DIR" ]; then
    echo -e "${RED}Error: ${SPRING_DIR} directory not found${NC}"
    exit 1
fi

# Determine source pom location based on output directory
if [ "$OUTPUT_DIR" = "$SPRING_DIR" ]; then
    # If converting in place, we need to preserve the original Spring pom first
    if [ ! -f "${SPRING_DIR}/pom.xml.spring-original" ]; then
        echo -e "${YELLOW}Preserving original Spring pom.xml...${NC}"
        cp "${SPRING_DIR}/pom.xml" "${SPRING_DIR}/pom.xml.spring-original"
        echo -e "${GREEN}✓ Saved original pom.xml${NC}"
        echo ""
    fi
    SOURCE_POM="${COMPAT_DIR}/pom.xml"
else
    SOURCE_POM="${OUTPUT_DIR}/pom.xml"
fi

# Check if source pom exists
if [ ! -f "$SOURCE_POM" ]; then
    echo -e "${RED}Error: Source pom.xml not found at ${SOURCE_POM}${NC}"
    exit 1
fi

# Section 1: Dev Mode Conversion
echo -e "${YELLOW}Step 1: Saving the Quarkus Spring compatibility pom.xml...${NC}"
mkdir -p target
cp "$SOURCE_POM" target/spring-pom.xml
echo -e "${GREEN}✓ Saved pom.xml${NC}"
echo ""

if [ "$OUTPUT_DIR" != "$SPRING_DIR" ]; then
    echo -e "${YELLOW}Step 2: Deleting the compatibility project...${NC}"
    rm -rf "$OUTPUT_DIR"
    echo -e "${GREEN}✓ Deleted ${OUTPUT_DIR}${NC}"
    echo ""

    echo -e "${YELLOW}Step 3: Copying ${SPRING_DIR} to ${OUTPUT_DIR}...${NC}"
    cp -r "$SPRING_DIR" "$OUTPUT_DIR"
    echo -e "${GREEN}✓ Copied ${SPRING_DIR} to ${OUTPUT_DIR}${NC}"
    echo ""
fi

echo -e "${YELLOW}Step 4: Replacing the Spring pom with Quarkus Spring compatibility pom...${NC}"
mv target/spring-pom.xml "${OUTPUT_DIR}/pom.xml"
echo -e "${GREEN}✓ Replaced ${OUTPUT_DIR}/pom.xml${NC}"
echo ""

echo -e "${YELLOW}Step 5: Deleting SpringBootApplication class (not needed with Quarkus)...${NC}"
# Find and delete the SpringBootApplication file
find "${OUTPUT_DIR}/src/main/java" -name "*Application.java" -type f -delete
echo -e "${GREEN}✓ Deleted SpringBootApplication class${NC}"
echo ""

echo -e "${YELLOW}Step 6: Deleting Spring-only config classes...${NC}"
# The config/ package contains L2CacheConfiguration, GraalVMConfig, and L2CacheRuntimeHints.
# These wire up Caffeine as a JCache provider for Hibernate L2 cache and register
# GraalVM native-image reflection hints — all Spring-specific plumbing.
# Quarkus handles Hibernate L2 cache automatically, so these classes are not needed
# (and won't compile, since the Quarkus pom doesn't include the Caffeine/JCache dependencies).
rm -rf "${OUTPUT_DIR}/src/main/java/org/acme/config"
echo -e "${GREEN}✓ Deleted Spring-only config classes${NC}"
echo ""

echo -e "${YELLOW}Step 7: Removing Spring Boot test infrastructure that Quarkus doesn't need...${NC}"
# quarkus-test-spring lets @SpringBootTest classes run as Quarkus tests, but it doesn't provide
# Spring Boot's Testcontainers wiring (Quarkus Dev Services starts the database instead),
# @Import, or MockMvc. So:
#  - ContainersConfig and TestApplication are Spring Boot Testcontainers plumbing: delete them
#  - the tests' @Import(ContainersConfig.class) is no longer needed: remove it
#  - FruitControllerTests relies on MockMvc, which has no Quarkus equivalent: delete it
#    (the e2e tests cover the REST layer)
rm -f "${OUTPUT_DIR}/src/test/java/org/acme/ContainersConfig.java" \
      "${OUTPUT_DIR}/src/test/java/org/acme/TestApplication.java" \
      "${OUTPUT_DIR}/src/test/java/org/acme/rest/FruitControllerTests.java"
find "${OUTPUT_DIR}/src/test/java" -name "*.java" -exec sed -i.bak \
  -e '/^import org\.acme\.ContainersConfig;$/d' \
  -e '/^import org\.springframework\.context\.annotation\.Import;$/d' \
  -e '/^@Import(ContainersConfig\.class)$/d' \
  {} +
find "${OUTPUT_DIR}/src/test/java" -name "*.java.bak" -delete
echo -e "${GREEN}✓ Removed Spring Boot test infrastructure${NC}"
echo ""

echo -e "${GREEN}=== Dev Mode Conversion Complete ===${NC}"
echo ""
echo -e "${YELLOW}To test in dev mode, run:${NC}"
echo "  cd ${OUTPUT_DIR} && quarkus dev"
echo ""

# Section 2: Prod Mode Configuration
echo -e "${YELLOW}Step 9: Copying Quarkus config for prod mode...${NC}"
cp "./${QUARKUS_DIR}/src/main/resources/application.yml" "${OUTPUT_DIR}/src/main/resources/application.yml"
echo -e "${GREEN}✓ Copied application.yml${NC}"
echo ""

echo -e "${YELLOW}Step 10: Building the application...${NC}"
(cd "${OUTPUT_DIR}" && ./mvnw clean package)
echo -e "${GREEN}✓ Build complete${NC}"
echo ""

echo -e "${YELLOW}Step 11: Reinstating e2e tests from ${QUARKUS_DIR}...${NC}"
mkdir -p "${OUTPUT_DIR}/src/test/java/org/acme/e2e"
cp -r "${QUARKUS_DIR}"/src/test/java/org/acme/e2e/* "${OUTPUT_DIR}/src/test/java/org/acme/e2e/"
echo -e "${GREEN}✓ Copied e2e tests${NC}"
echo ""

echo -e "${GREEN}=== Conversion Complete ===${NC}"
echo ""
echo -e "${YELLOW}To run stress tests:${NC}"
echo "  ./scripts/stress.sh ${OUTPUT_DIR}/target/quarkus-app/quarkus-run.jar"
echo ""
echo -e "${GREEN}Expected result: Throughput should be almost identical to the 'normal' Quarkus app,${NC}"
echo -e "${GREEN}and more than double that of the Quarkus-free Spring app.${NC}"
