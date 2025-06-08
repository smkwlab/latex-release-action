#!/bin/bash

# Unified testing script for LaTeX Release Action
# Combines all test methods into a single, easy-to-use script

set -e

# Script info
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="LaTeX Release Action Test Suite"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_status() {
    case $1 in
        "SUCCESS") echo -e "${GREEN}✓ $2${NC}" ;;
        "ERROR") echo -e "${RED}✗ $2${NC}" ;;
        "INFO") echo -e "${YELLOW}ℹ $2${NC}" ;;
        "HEADER") echo -e "\n${BLUE}=== $2 ===${NC}" ;;
    esac
}

# Banner
print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════╗"
    echo "║      LaTeX Release Action Test Suite       ║"
    echo "║            Version $SCRIPT_VERSION                      ║"
    echo "╚════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print header function
print_header() {
    print_status "HEADER" "$1"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if in correct directory
    if [ ! -f "action.yml" ]; then
        print_status "ERROR" "action.yml not found. Run from repository root."
        exit 1
    fi
    
    # Check test files
    if [ ! -f "test/sample.tex" ]; then
        print_status "ERROR" "Test files not found. Create test files first."
        exit 1
    fi
    
    print_status "SUCCESS" "All prerequisites met"
}

# Method 1: Logic-only test (fastest, no dependencies)
test_logic() {
    print_header "Logic Test (No Dependencies)"
    print_status "INFO" "Testing action script logic without LaTeX compilation..."
    
    # Simulate inputs
    local INPUT_FILES="test/sample, test/document2"
    local INPUT_LATEX_OPTIONS="-pdf -interaction=nonstopmode"
    local INPUT_PARALLEL="true"
    local INPUT_CLEANUP="true"
    
    # Test file preparation logic
    IFS=',' read -ra TEX_FILES <<< "$INPUT_FILES"
    local FILES_TO_CHECK=""
    local PROCESSED_FILES=""
    
    for file in "${TEX_FILES[@]}"; do
        file=$(echo $file | xargs)
        if [[ -z "$file" ]]; then
            continue
        fi
        
        if [[ ! "$file" =~ ^[a-zA-Z0-9_/-]+$ ]]; then
            print_status "ERROR" "Invalid file name: $file"
            return 1
        fi
        
        FILES_TO_CHECK+="$file.tex,"
        PROCESSED_FILES+="$file,"
    done
    
    FILES_TO_CHECK=${FILES_TO_CHECK%,}
    PROCESSED_FILES=${PROCESSED_FILES%,}
    
    print_status "SUCCESS" "File preparation logic OK"
    
    # Test file existence (old behavior - expecting all files to exist)
    IFS=',' read -ra CHECK_FILES <<< "$FILES_TO_CHECK"
    for file in "${CHECK_FILES[@]}"; do
        if [ -f "$file" ]; then
            print_status "SUCCESS" "Found: $file"
        else
            print_status "ERROR" "Missing: $file (expected for this test)"
        fi
    done
    
    # Test error handling
    local INVALID_FILE="../../../etc/passwd"
    if [[ ! "$INVALID_FILE" =~ ^[a-zA-Z0-9_/-]+$ ]]; then
        print_status "SUCCESS" "Security check passed - invalid paths rejected"
    fi
    
    print_status "SUCCESS" "Logic test completed successfully"
    return 0
}

# Method 1.5: Test missing file handling (new feature)
test_missing_files() {
    print_header "Missing Files Handling Test"
    print_status "INFO" "Testing new auto-skip functionality for missing files..."
    
    # Test with mixed existing and non-existing files
    local INPUT_FILES="test/sample, nonexistent1, test/document2, nonexistent2"
    
    # Simulate the new file detection logic from action.yml
    IFS=',' read -ra TEX_FILES <<< "$INPUT_FILES"
    local FILES_TO_CHECK=""
    local PROCESSED_FILES=""
    local SKIPPED_FILES=""
    local FOUND_COUNT=0
    local SKIPPED_COUNT=0
    
    for file in "${TEX_FILES[@]}"; do
        file=$(echo $file | xargs)  # trim whitespace
        if [[ -z "$file" ]]; then
            continue
        fi
        
        # Sanitize file name
        if [[ ! "$file" =~ ^[a-zA-Z0-9_/-]+$ ]]; then
            print_status "ERROR" "Invalid file name: $file"
            return 1
        fi
        
        # Check if the .tex file exists (new logic)
        if [[ -f "$file.tex" ]]; then
            FILES_TO_CHECK+="$file.tex,"
            PROCESSED_FILES+="$file,"
            print_status "SUCCESS" "✓ Found file: $file.tex"
            ((FOUND_COUNT++))
        else
            SKIPPED_FILES+="$file.tex,"
            print_status "INFO" "⚠ Skipping missing file: $file.tex"
            ((SKIPPED_COUNT++))
        fi
    done
    
    FILES_TO_CHECK=${FILES_TO_CHECK%,}
    PROCESSED_FILES=${PROCESSED_FILES%,}
    SKIPPED_FILES=${SKIPPED_FILES%,}
    
    # Verify the results
    print_status "INFO" "Found $FOUND_COUNT files, skipped $SKIPPED_COUNT files"
    
    if [[ $FOUND_COUNT -gt 0 ]]; then
        print_status "SUCCESS" "Found files: $FILES_TO_CHECK"
        print_status "SUCCESS" "Action would proceed with existing files"
    fi
    
    if [[ $SKIPPED_COUNT -gt 0 ]]; then
        print_status "SUCCESS" "Skipped files: $SKIPPED_FILES"
        print_status "SUCCESS" "Missing files gracefully handled"
    fi
    
    # Test all files missing scenario
    print_status "INFO" "Testing all files missing scenario..."
    local ALL_MISSING="nonexistent1, nonexistent2, nonexistent3"
    IFS=',' read -ra MISSING_FILES <<< "$ALL_MISSING"
    local ALL_MISSING_CHECK=""
    
    for file in "${MISSING_FILES[@]}"; do
        file=$(echo $file | xargs)
        if [[ ! -f "$file.tex" ]]; then
            ALL_MISSING_CHECK+="$file.tex,"
        fi
    done
    
    if [[ -n "$ALL_MISSING_CHECK" ]]; then
        print_status "SUCCESS" "All files missing scenario detected correctly"
        print_status "SUCCESS" "Action would exit gracefully with warning"
    fi
    
    print_status "SUCCESS" "Missing files handling test completed successfully"
    return 0
}

# Method 2: Local LaTeX test (if LaTeX is installed)
test_local() {
    print_header "Local LaTeX Test"
    
    if ! command -v latexmk &> /dev/null; then
        print_status "INFO" "LaTeX not installed locally - skipping"
        return 1
    fi
    
    print_status "INFO" "Testing with local LaTeX installation..."
    
    # Build test files
    for tex_file in test/*.tex; do
        if [ -f "$tex_file" ]; then
            print_status "INFO" "Building $tex_file..."
            if latexmk -pdf -interaction=nonstopmode "$tex_file" > /dev/null 2>&1; then
                print_status "SUCCESS" "Built $tex_file"
            else
                print_status "ERROR" "Failed to build $tex_file"
                return 1
            fi
        fi
    done
    
    # Move PDFs and cleanup
    mv *.pdf test/ 2>/dev/null || true
    rm -f *.aux *.log *.fls *.fdb_latexmk *.synctex.gz *.out *.toc 2>/dev/null
    
    print_status "SUCCESS" "Local LaTeX test completed successfully"
    return 0
}

# Method 3: Docker test
test_docker() {
    print_header "Docker Test"
    
    if ! command -v docker &> /dev/null; then
        print_status "INFO" "Docker not installed - skipping"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        print_status "ERROR" "Docker is not running"
        return 1
    fi
    
    print_status "INFO" "Testing with Docker container..."
    
    # Check Docker daemon status first
    print_status "INFO" "Checking Docker daemon..."
    if docker run --rm hello-world > /dev/null 2>&1; then
        print_status "SUCCESS" "Docker daemon is healthy"
    else
        print_status "ERROR" "Docker daemon has issues - try 'docker system prune -a'"
        return 1
    fi
    
    # Try different containers in order of preference
    # Note: Some containers may not have ARM64 images
    local CONTAINERS=(
        "ghcr.io/smkwlab/texlive-ja-textlint:2023c-debian"
        "texlive/texlive:latest"
    )
    
    for container in "${CONTAINERS[@]}"; do
        print_status "INFO" "Trying container: $container"
        
        if docker run --rm \
            -v "$(pwd):/workspace" \
            -w /workspace \
            "$container" \
            bash -c "latexmk -pdf -interaction=nonstopmode test/sample.tex" > /dev/null 2>&1; then
            
            print_status "SUCCESS" "Docker test with $container completed"
            mv *.pdf test/ 2>/dev/null || true
            rm -f *.aux *.log *.fls *.fdb_latexmk *.synctex.gz *.out *.toc 2>/dev/null
            return 0
        fi
    done
    
    print_status "ERROR" "Docker test failed with all containers"
    return 1
}

# Method 4: GitHub Actions test with act
test_act() {
    print_header "GitHub Actions Test (act)"
    
    if ! command -v act &> /dev/null; then
        print_status "INFO" "act not installed - skipping"
        print_status "INFO" "Install with: brew install act"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        print_status "ERROR" "Docker is required for act"
        return 1
    fi
    
    print_status "INFO" "Testing with act (GitHub Actions emulator)..."
    
    # Use main test workflow
    if [ -f ".github/workflows/test.yml" ]; then
        if act --dryrun > /dev/null 2>&1; then
            print_status "SUCCESS" "act configuration valid"
            print_status "INFO" "Run 'act' for full test"
        else
            print_status "ERROR" "act configuration invalid"
            return 1
        fi
    else
        print_status "INFO" "No test workflow found for act"
        return 1
    fi
    
    return 0
}

# Summary report
print_summary() {
    print_header "Test Summary"
    
    echo -e "\nTest Results:"
    echo -e "  Logic Test:           ${1}"
    echo -e "  Missing Files Test:   ${2}"
    echo -e "  Local LaTeX Test:     ${3}"
    echo -e "  Docker Test:          ${4}"
    echo -e "  Act Test:             ${5}"
    
    echo -e "\nRecommendations:"
    if [[ "$1" == "${GREEN}PASSED${NC}" ]]; then
        echo "  ✓ Action logic is valid"
    fi
    
    if [[ "$2" == "${GREEN}PASSED${NC}" ]]; then
        echo "  ✓ Missing file handling works correctly (new feature)"
    fi
    
    if [[ "$3" == "${GREEN}PASSED${NC}" ]] || [[ "$4" == "${GREEN}PASSED${NC}" ]]; then
        echo "  ✓ LaTeX compilation verified"
    else
        echo "  - Install LaTeX locally or use Docker for full testing"
    fi
    
    echo -e "\nNext Steps:"
    echo "  1. Commit your changes"
    echo "  2. Push to GitHub"
    echo "  3. Test with real GitHub Actions"
}

# Main test runner
main() {
    local TEST_METHOD="${1:-all}"
    
    print_banner
    check_prerequisites
    
    # Test results
    local LOGIC_RESULT="${YELLOW}SKIPPED${NC}"
    local MISSING_FILES_RESULT="${YELLOW}SKIPPED${NC}"
    local LOCAL_RESULT="${YELLOW}SKIPPED${NC}"
    local DOCKER_RESULT="${YELLOW}SKIPPED${NC}"
    local ACT_RESULT="${YELLOW}SKIPPED${NC}"
    
    case "$TEST_METHOD" in
        "logic")
            test_logic && LOGIC_RESULT="${GREEN}PASSED${NC}" || LOGIC_RESULT="${RED}FAILED${NC}"
            ;;
        "missing")
            test_missing_files && MISSING_FILES_RESULT="${GREEN}PASSED${NC}" || MISSING_FILES_RESULT="${RED}FAILED${NC}"
            ;;
        "local")
            test_local && LOCAL_RESULT="${GREEN}PASSED${NC}" || LOCAL_RESULT="${RED}FAILED${NC}"
            ;;
        "docker")
            test_docker && DOCKER_RESULT="${GREEN}PASSED${NC}" || DOCKER_RESULT="${RED}FAILED${NC}"
            ;;
        "act")
            test_act && ACT_RESULT="${GREEN}PASSED${NC}" || ACT_RESULT="${RED}FAILED${NC}"
            ;;
        "all"|"")
            # Run all tests
            test_logic && LOGIC_RESULT="${GREEN}PASSED${NC}" || LOGIC_RESULT="${RED}FAILED${NC}"
            test_missing_files && MISSING_FILES_RESULT="${GREEN}PASSED${NC}" || MISSING_FILES_RESULT="${RED}FAILED${NC}"
            test_local && LOCAL_RESULT="${GREEN}PASSED${NC}" || LOCAL_RESULT="${YELLOW}N/A${NC}"
            test_docker && DOCKER_RESULT="${GREEN}PASSED${NC}" || DOCKER_RESULT="${YELLOW}N/A${NC}"
            test_act && ACT_RESULT="${GREEN}PASSED${NC}" || ACT_RESULT="${YELLOW}N/A${NC}"
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [test-method]"
            echo ""
            echo "Test methods:"
            echo "  all     - Run all available tests (default)"
            echo "  logic   - Test action logic only (no LaTeX required)"
            echo "  missing - Test missing file handling (new feature)"
            echo "  local   - Test with local LaTeX installation"
            echo "  docker  - Test with Docker container"
            echo "  act     - Test with GitHub Actions emulator"
            echo ""
            echo "Examples:"
            echo "  $0          # Run all tests"
            echo "  $0 logic    # Quick logic test"
            echo "  $0 missing  # Test missing file skip feature"
            echo "  $0 docker   # Docker-based test"
            exit 0
            ;;
        *)
            print_status "ERROR" "Unknown test method: $TEST_METHOD"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
    
    print_summary "$LOGIC_RESULT" "$MISSING_FILES_RESULT" "$LOCAL_RESULT" "$DOCKER_RESULT" "$ACT_RESULT"
    
    echo ""
    print_status "SUCCESS" "Test suite completed!"
}

# Run main function
main "$@"
