#!/bin/sh

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running RSpec tests...${NC}"
bundle exec rspec
if [ $? -eq 0 ]; then
  echo -e "${GREEN}RSpec tests passed!${NC}"
else
  echo -e "${RED}RSpec tests failed!${NC}"
  exit 1
fi

echo -e "${YELLOW}Running Rubocop...${NC}"
bin/rubocop
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Rubocop passed!${NC}"
else
  echo -e "${RED}Rubocop failed!${NC}"
  exit 1
fi

echo -e "${YELLOW}Running Steep...${NC}"
bin/steep
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Steep passed!${NC}"
else
  echo -e "${RED}Steep failed!${NC}"
  exit 1
fi
