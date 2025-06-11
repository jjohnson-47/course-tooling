#!/bin/bash
# Architecture compliance validation script
# Must pass for all merges (CI enforcement)

set -e

echo "🔍 Validating Course Deployment System architecture..."

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VIOLATIONS=0

# Helper function to report violations
report_violation() {
    echo -e "${RED}❌ VIOLATION: $1${NC}"
    ((VIOLATIONS++))
}

report_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

report_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Check required environment variables
echo "📋 Checking environment variables..."
if [[ -z "$AGENTIC_ENV_ROOT" ]]; then
    report_violation "AGENTIC_ENV_ROOT not set"
else
    report_success "AGENTIC_ENV_ROOT: $AGENTIC_ENV_ROOT"
fi

if [[ -z "$AGENTIC_STATE_ROOT" ]]; then
    report_violation "AGENTIC_STATE_ROOT not set"
else
    report_success "AGENTIC_STATE_ROOT: $AGENTIC_STATE_ROOT"
fi

if [[ -z "$CDS_ENV_ROOT" ]]; then
    report_violation "CDS_ENV_ROOT not set"
else
    report_success "CDS_ENV_ROOT: $CDS_ENV_ROOT"
fi

if [[ -z "$CDS_STATE_ROOT" ]]; then
    report_violation "CDS_STATE_ROOT not set"
else
    report_success "CDS_STATE_ROOT: $CDS_STATE_ROOT"
fi

# Check directory structure
echo ""
echo "📁 Checking directory structure..."
if [[ -n "$AGENTIC_ENV_ROOT" ]]; then
    if [[ ! -d "$AGENTIC_ENV_ROOT" ]]; then
        report_violation "AGENTIC_ENV_ROOT directory does not exist: $AGENTIC_ENV_ROOT"
    else
        report_success "AGENTIC_ENV_ROOT directory exists"
    fi
    
    if [[ ! -d "$AGENTIC_ENV_ROOT/courses" ]]; then
        report_violation "courses directory does not exist: $AGENTIC_ENV_ROOT/courses"
    else
        report_success "courses directory exists"
    fi
fi

if [[ -n "$AGENTIC_STATE_ROOT" ]]; then
    if [[ ! -d "$AGENTIC_STATE_ROOT" ]]; then
        report_violation "AGENTIC_STATE_ROOT directory does not exist: $AGENTIC_STATE_ROOT"
    else
        report_success "AGENTIC_STATE_ROOT directory exists"
    fi
fi

if [[ -n "$CDS_STATE_ROOT" ]]; then
    if [[ ! -d "$CDS_STATE_ROOT" ]]; then
        report_violation "CDS_STATE_ROOT directory does not exist: $CDS_STATE_ROOT"
    else
        report_success "CDS_STATE_ROOT directory exists"
        
        # Check required subdirectories
        for subdir in "ingestion-cache" "deployment-logs"; do
            if [[ ! -d "$CDS_STATE_ROOT/$subdir" ]]; then
                report_warning "Missing CDS subdirectory: $CDS_STATE_ROOT/$subdir"
            else
                report_success "CDS subdirectory exists: $subdir"
            fi
        done
    fi
fi

# Check for cds_agent
echo ""
echo "🤖 Checking cds_agent daemon..."
if [[ -n "$AGENTIC_ENV_ROOT" ]] && [[ -f "$AGENTIC_ENV_ROOT/agents/cds_agent.py" ]]; then
    report_success "cds_agent.py exists"
    
    # Check if it's executable
    if [[ -x "$AGENTIC_ENV_ROOT/agents/cds_agent.py" ]]; then
        report_success "cds_agent.py is executable"
    else
        report_violation "cds_agent.py is not executable"
    fi
    
    # Check if LaunchAgent is loaded (macOS specific)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if launchctl list | grep -q "com.agentic.cds"; then
            report_success "cds_agent LaunchAgent is loaded"
        else
            report_warning "cds_agent LaunchAgent is not loaded"
        fi
    fi
else
    report_violation "cds_agent.py not found"
fi

# Check for PAT in keychain (macOS specific)
echo ""
echo "🔐 Checking security configuration..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    if security find-generic-password -a "$USER" -s cds_pat >/dev/null 2>&1; then
        report_success "CDS PAT found in keychain"
    else
        report_violation "CDS PAT not found in keychain (service: cds_pat, account: $USER)"
    fi
fi

# Check for literal paths (security violation)
echo ""
echo "🔒 Scanning for literal path violations..."
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if grep -r --exclude-dir=.git --exclude="*.md" --exclude="validate-architecture.sh" "/Users\|/home" "$REPO_ROOT" >/dev/null 2>&1; then
    report_violation "Found literal paths in codebase - use environment variables instead"
    echo "   Run: grep -r --exclude-dir=.git '/Users\|/home' . to locate violations"
else
    report_success "No literal path violations found"
fi

# Check Git configuration
echo ""
echo "📝 Checking Git configuration..."
if git config --get user.name >/dev/null && git config --get user.email >/dev/null; then
    report_success "Git user configuration present"
else
    report_warning "Git user configuration missing"
fi

# Summary
echo ""
echo "📊 Validation Summary"
echo "===================="
if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}🎉 All architecture validation checks passed!${NC}"
    echo "System is ready for Course Deployment System operations."
    exit 0
else
    echo -e "${RED}💥 Found $VIOLATIONS violation(s)${NC}"
    echo "Please fix the violations before proceeding."
    exit 1
fi