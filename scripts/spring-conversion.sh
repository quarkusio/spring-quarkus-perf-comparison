#!/bin/bash

# Script to convert Spring Boot application to Quarkus with Spring compatibility libraries
# Based on steps from spring-conversion.md
#
# Usage: ./spring-conversion.sh [output-directory]
#   output-directory: Target directory for the converted application (default: quarkus3-spring-compatibility, but you can use springboot3 to convert in place and see the diff)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
OUTPUT_DIR="${1:-quarkus3-spring-compatibility}"

echo -e "${GREEN}=== Spring to Quarkus Conversion Script ===${NC}"
echo -e "${YELLOW}Output directory: ${OUTPUT_DIR}${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "spring-conversion.md" ]; then
    echo -e "${RED}Error: Must be run from the project root directory${NC}"
    exit 1
fi

# Check if source directory exists
if [ ! -d "springboot3" ]; then
    echo -e "${RED}Error: springboot3 directory not found${NC}"
    exit 1
fi

# Determine source pom location based on output directory
if [ "$OUTPUT_DIR" = "springboot3" ]; then
    # If converting in place, we need to preserve the original Spring pom first
    if [ ! -f "springboot3/pom.xml.spring-original" ]; then
        echo -e "${YELLOW}Preserving original Spring pom.xml...${NC}"
        cp springboot3/pom.xml springboot3/pom.xml.spring-original
        echo -e "${GREEN}✓ Saved original pom.xml${NC}"
        echo ""
    fi
    SOURCE_POM="quarkus3-spring-compatibility/pom.xml"
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

if [ "$OUTPUT_DIR" != "springboot3" ]; then
    echo -e "${YELLOW}Step 2: Deleting the compatibility project...${NC}"
    rm -rf "$OUTPUT_DIR"
    echo -e "${GREEN}✓ Deleted ${OUTPUT_DIR}${NC}"
    echo ""

    echo -e "${YELLOW}Step 3: Copying springboot3 to ${OUTPUT_DIR}...${NC}"
    cp -r springboot3 "$OUTPUT_DIR"
    echo -e "${GREEN}✓ Copied springboot3 to ${OUTPUT_DIR}${NC}"
    echo ""
fi

echo -e "${YELLOW}Step 4: Replacing the Spring pom with Quarkus Spring compatibility pom...${NC}"
mv target/spring-pom.xml "${OUTPUT_DIR}/pom.xml"
echo -e "${GREEN}✓ Replaced ${OUTPUT_DIR}/pom.xml${NC}"
echo ""

echo -e "${YELLOW}Step 5: Deleting tests (hard to convert for now)...${NC}"
rm -rf "${OUTPUT_DIR}/src/test"
echo -e "${GREEN}✓ Deleted tests${NC}"
echo ""

echo -e "${YELLOW}Step 6: Deleting SpringBootApplication class (not needed with Quarkus)...${NC}"
# Find and delete the SpringBootApplication file
find "${OUTPUT_DIR}/src/main/java" -name "*Application.java" -type f -delete
echo -e "${GREEN}✓ Deleted SpringBootApplication class${NC}"
echo ""

echo -e "${GREEN}=== Dev Mode Conversion Complete ===${NC}"
echo ""
echo -e "${YELLOW}To test in dev mode, run:${NC}"
echo "  cd ${OUTPUT_DIR} && quarkus dev"
echo ""

# Section 2: Prod Mode Configuration
echo -e "${YELLOW}Step 7: Copying Quarkus config for prod mode...${NC}"
cp ./quarkus3/src/main/resources/application.yml "${OUTPUT_DIR}/src/main/resources/application.yml"
echo -e "${GREEN}✓ Copied application.yml${NC}"
echo ""

echo -e "${YELLOW}Step 8: Building the application...${NC}"
(cd "${OUTPUT_DIR}" && ./mvnw clean package)
echo -e "${GREEN}✓ Build complete${NC}"
echo ""

echo -e "${GREEN}=== Conversion Complete ===${NC}"
echo ""
echo -e "${YELLOW}To run stress tests:${NC}"
echo "  ./scripts/stress.sh ${OUTPUT_DIR}/target/quarkus-app/quarkus-run.jar"
echo ""
echo -e "${GREEN}Expected result: Throughput should be almost identical to the 'normal' Quarkus app,${NC}"
echo -e "${GREEN}and more than double that of the Quarkus-free Spring app.${NC}"
