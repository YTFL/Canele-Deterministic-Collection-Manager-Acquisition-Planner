#!/usr/bin/env bash
# ==============================================================================
# Canelé Quality & Validation Runner (Linux / macOS / Git Bash)
# ==============================================================================
# Runs code formatting check, static analysis, and automated test suite.
# Exit code 0 indicates all checks passed cleanly.
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}${BOLD}==> Starting Canelé Validation Suite...${NC}"

# 1. Dependency check
echo -e "\n${BOLD}[1/3] Checking dependencies...${NC}"
flutter pub get

# 2. Dart formatting
echo -e "\n${BOLD}[2/3] Checking code formatting (dart format)...${NC}"
if ! dart format --output=none --set-exit-if-changed .; then
  echo -e "${RED}Formatting check failed! Please run 'dart format .' to format your code.${NC}"
  exit 1
fi
echo -e "${GREEN}Formatting passed.${NC}"

# 3. Static analysis
echo -e "\n${BOLD}[3/3] Running static analysis (flutter analyze)...${NC}"
if ! flutter analyze --fatal-infos --fatal-warnings; then
  echo -e "${RED}Static analysis found errors or warnings! Please resolve them.${NC}"
  exit 1
fi
echo -e "${GREEN}Static analysis passed.${NC}"

# 4. Automated tests
echo -e "\n${BOLD}[4/4] Running automated test suite (flutter test)...${NC}"
if ! flutter test; then
  echo -e "${RED}One or more tests failed!${NC}"
  exit 1
fi
echo -e "${GREEN}All tests passed successfully!${NC}"

echo -e "\n${GREEN}${BOLD}✓ All Canelé validation checks passed! Ready for PR submission.${NC}\n"
