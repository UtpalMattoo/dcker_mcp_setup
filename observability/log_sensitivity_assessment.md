# Log Sensitivity Assessment and Redaction Strategy

**Purpose:** Identify all sensitive data types in collected logs and define mandatory redaction patterns for Alloy pipelines before forwarding to LGTM.

**Status:** STEP 1 of observability implementation — all subsequent steps depend on this assessment.

---

## 1. Log Sources and Sensitivity Levels

### 1.1 VS Code Logs

**Location:** `<VSCODE_LOGS_DIR>` (Windows: typically `%APPDATA%\Code\logs`)

**Contents:**
- Editor initialization events
- Extension activity and performance metrics
- File operations and workspace events
- Command palette usage patterns
- Error traces from editor and extensions

**Sensitive Data Risks:**
- Workspace paths may expose absolute paths and directory structure
- File names in logs may expose project structure
- Extension activity patterns may indicate used tools/services
- **RISK LEVEL: MEDIUM** — contains structure information but limited secrets

**Redaction Strategy:**
- Redact absolute paths (both Windows `C:\...` and UNC paths)
- Replace with `<PATH_REDACTED>`

---

### 1.2 GitHub Copilot Extension Logs

**Location:** `<COPILOT_EXTENSION_LOGS_DIR>` (Windows: typically `%APPDATA%\Code\User\globalStorage\GitHub.copilot\...`)

**Contents:**
- Chat prompts and responses (user questions and AI answers)
- Inline suggestion interactions
- API requests to OpenAI and GitHub Copilot endpoints
- Authentication tokens and session identifiers
- Request/response payloads containing code snippets and user queries

**Sensitive Data Risks:**
- **CRITICAL:** Chat prompts may contain proprietary code, business logic, credentials, API keys, etc.
- **CRITICAL:** API responses may contain sensitive AI-generated code examples
- **HIGH:** OpenAI API keys or authentication tokens
- **HIGH:** GitHub Copilot session tokens
- **MEDIUM:** User's internal knowledge/code patterns exposed in prompts
- **RISK LEVEL: CRITICAL** — most sensitive source; contains user code and secrets

**Redaction Strategy:**
- Redact all API keys and tokens (OpenAI, GitHub, etc.)
- Redact authentication headers and bearer tokens
- Redact or disable entirely in production via `ENABLE_COPILOT_LOGS=false`
- In development: redact patterns only, keep structure for debugging

---

### 1.3 Application Service Logs (main_starter_service and second-service-custom-mcp-work)

**Sources:**
- `main_starter_service`: stdout/stderr from Python service
- `second-service-custom-mcp-work`: stdout/stderr from custom MCP service
- Both captured via Docker compose logging driver

**Contents:**
- Application initialization and startup events
- Request processing logs (may include request bodies/parameters)
- Database/API interactions (queries, responses)
- Error traces and stack traces
- Performance metrics

**Sensitive Data Risks:**
- **MEDIUM:** Database query strings may expose internal schema or business logic
- **MEDIUM:** Request payloads may contain user input or credentials
- **LOW-MEDIUM:** Stack traces may reveal internal architecture
- **RISK LEVEL: MEDIUM** — depends on application logging practices

**Redaction Strategy:**
- Redact database connection strings
- Redact API keys and authentication credentials in connection attempts
- Redact request body contents if logging requests
- Keep exception types and traces for debugging

---

### 1.4 Qdrant Database Logs

**Location:** Qdrant container stdout/stderr

**Contents:**
- Vector database initialization
- Collection operations (create, update, delete)
- Search queries and results summary
- Connection attempts
- Performance metrics and timing

**Sensitive Data Risks:**
- **LOW-MEDIUM:** Query patterns may expose data structure and business logic
- **LOW:** Timing information may be used for side-channel analysis
- **RISK LEVEL: LOW-MEDIUM** — operational visibility needed, limited secret exposure

**Redaction Strategy:**
- Generally safe to log; minimal redaction needed
- Redact any API keys if Qdrant uses them
- Keep query summaries for debugging

---

## 2. Mandatory Redaction Patterns

These regex patterns MUST be applied in Alloy log pipelines before forwarding to Loki.

### 2.1 API Keys and Tokens

```regex
# OpenAI API Keys
pattern: sk-[A-Za-z0-9]{20,}
replace: sk-<REDACTED_OPENAI_KEY>

# GitHub Copilot/GitHub API Tokens
pattern: gh[pousr]{1}_[A-Za-z0-9_]{36,255}
replace: gh_<REDACTED_GITHUB_TOKEN>

# Generic API keys (api_key=, apiKey=, etc.)
pattern: api[_-]?key["\s:=]*([A-Za-z0-9\-._~+/]+=*)
replace: apikey=<REDACTED_API_KEY>
```

### 2.2 Authentication and Bearer Tokens

```regex
# Bearer tokens (Authorization: Bearer ...)
pattern: (authorization|auth)["\s:=]*Bearer\s+[A-Za-z0-9\-._~+/]+=*
replace: $1: Bearer <REDACTED_TOKEN>

# Session tokens
pattern: (session|sessionid|session_id)["\s:=]*([A-Za-z0-9\-._~+/]+=*)
replace: $1=<REDACTED_SESSION>
```

### 2.3 Credentials

```regex
# Passwords and secrets
pattern: (password|passwd|pwd)["\s:=]*([^\s"}\]]+)
replace: $1=<REDACTED_PASSWORD>

# Database connection strings (redact password portion)
pattern: (password=|passwd=)([^\s&;]+)
replace: $1<REDACTED_DB_PASSWORD>
```

### 2.4 Paths and Structure Information

```regex
# Windows absolute paths
pattern: [A-Z]:\\(?:[^\s\\]+\\)*[^\s\\]*
replace: <PATH_REDACTED>

# UNC paths
pattern: \\\\[^\s\\]+\\[^\s\\]*
replace: <PATH_REDACTED>
```

### 2.5 Sensitive Services/Endpoints

```regex
# AWS access keys
pattern: AKIA[0-9A-Z]{16}
replace: AKIA<REDACTED_AWS_KEY>

# GCP service account keys
pattern: (type|project_id|private_key)["\s:=]*([^\s"}\]]+)
replace: $1=<REDACTED>
```

---

## 3. Redaction Strategy by Log Source

| Log Source | Redaction Priority | Patterns to Apply | CI Environment |
|------------|-------------------|-------------------|-----------------|
| VS Code | MEDIUM | Paths only | Enable with path redaction |
| Copilot | CRITICAL | All patterns; disable if possible | **DISABLE: `ENABLE_COPILOT_LOGS=false`** |
| app_services | MEDIUM | Credentials, paths, connection strings | Enable with credential redaction |
| Qdrant | LOW | API keys only if used | Enable; minimal redaction |

---

## 4. Environment Flags for CI Portability

Add these environment variables to control log collection:

```bash
# Enable/disable specific log sources (default: true for dev, false for CI)
ENABLE_VSCODE_LOGS=${ENABLE_VSCODE_LOGS:-true}
ENABLE_COPILOT_LOGS=${ENABLE_COPILOT_LOGS:-false}  # Disabled by default for security
ENABLE_SERVICE_LOGS=${ENABLE_SERVICE_LOGS:-true}
ENABLE_QDRANT_LOGS=${ENABLE_QDRANT_LOGS:-true}

# Redaction mode (strict, relaxed, none)
REDACTION_MODE=${REDACTION_MODE:-strict}  # strict = apply all patterns, relaxed = apply critical only
```

---

## 5. Grafana RBAC Requirements

Define access controls for each log type:

| Log Source | User Role | Access Level | Reason |
|------------|-----------|--------------|--------|
| VS Code | Developer | Full | Team debugging |
| Copilot | Admin Only | Restricted | Contains user prompts/responses |
| app_services | Developer | Full | Application debugging |
| Qdrant | Developer | Full | Database operations |

**Grafana Configuration:**
- Create `logs-sensitive` datasource restricted to Admin role
- Create `logs-general` datasource accessible to Developer role
- Copilot logs queried through restricted `logs-sensitive` only
- Separate dashboards for sensitive vs general logs

---

## 6. Implementation Checklist

- [ ] Define redaction patterns in Alloy log pipeline files (`observability/alloy/config/logs-*.river`)
- [ ] Add `loki.process` stages to each log pipeline with pattern replacements
- [ ] Test redaction filters with synthetic logs containing secrets
- [ ] Create validation tests to verify sensitive patterns do NOT appear in Loki
- [ ] Document secret rotation procedures if secrets appear despite redaction
- [ ] Configure Grafana RBAC for sensitive log access
- [ ] Add environment flag support to Alloy compose configuration
- [ ] Update service compose to include feature flags
- [ ] Create CI environment profile with Copilot/VS Code logs disabled

---

## 7. Redaction Testing Strategy

**Before deployment to LGTM:**

1. Emit synthetic logs containing known secrets
2. Verify Alloy redaction stages process them
3. Query Loki and confirm secrets do NOT appear
4. Test each pattern against real log samples
5. Document false-positive redaction cases

**Ongoing:**
- Monitor redaction filter performance (should not impact throughput significantly)
- Review samples of redacted logs monthly
- Update patterns based on new secret formats detected

---

## 8. Secrets Rotation Runbook (If Breach Suspected)

If secrets appear in logs despite redaction:

1. **Immediate:** Rotate compromised secrets in source systems
2. **Within 1 hour:** Update Loki retention to expire old logs (default: 30 days)
3. **Within 1 day:** Review all Grafana access logs for unauthorized queries
4. **Within 1 week:** Implement audit logging for sensitive log queries
5. **Update patterns** and re-test redaction pipeline

